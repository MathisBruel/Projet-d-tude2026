from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime
from ..database import get_db
from ..models.alert import Alert
from ..utils.auth_utils import jwt_required
from ..services import weather_service

alerts_bp = Blueprint("alerts", __name__)

# Seuils agronomiques par culture (°C, mm/jour)
_THRESHOLDS = {
    "default":         {"frost_c": 0,   "drought_temp": 32, "flood_mm": 50},
    "Wheat":           {"frost_c": -2,  "drought_temp": 30, "flood_mm": 40},
    "Maize":           {"frost_c":  2,  "drought_temp": 35, "flood_mm": 60},
    "Rice, paddy":     {"frost_c":  5,  "drought_temp": 38, "flood_mm": 80},
    "Potatoes":        {"frost_c": -1,  "drought_temp": 28, "flood_mm": 45},
    "Soybeans":        {"frost_c":  0,  "drought_temp": 35, "flood_mm": 55},
    "Sunflower seed":  {"frost_c": -1,  "drought_temp": 36, "flood_mm": 50},
    "Rapeseed":        {"frost_c": -3,  "drought_temp": 28, "flood_mm": 40},
    "Sugar beet":      {"frost_c": -2,  "drought_temp": 30, "flood_mm": 45},
    "Tomatoes":        {"frost_c":  2,  "drought_temp": 35, "flood_mm": 50},
    "Grapes":          {"frost_c": -1,  "drought_temp": 38, "flood_mm": 35},
}


def _thresholds_for(culture_type: str) -> dict:
    return _THRESHOLDS.get(culture_type, _THRESHOLDS["default"])


def _analyse_day(date: str, t_min, t_max, rain, thr: dict) -> list[dict]:
    """Retourne la liste d'alertes pour un jour donné."""
    alerts = []

    if t_min is not None and t_min < thr["frost_c"]:
        alerts.append({
            "date":     date,
            "type":     "FROST",
            "severity": "HIGH",
            "message":  f"Risque de gel — {t_min:.1f}°C prévu. Protégez vos cultures.",
        })

    if t_max is not None and rain is not None:
        if t_max > thr["drought_temp"] and rain < 1.0:
            alerts.append({
                "date":     date,
                "type":     "DROUGHT",
                "severity": "MEDIUM",
                "message":  (
                    f"Stress hydrique — {t_max:.1f}°C sans précipitations. "
                    "Irrigation recommandée."
                ),
            })

    if rain is not None and rain > thr["flood_mm"]:
        alerts.append({
            "date":     date,
            "type":     "FLOOD",
            "severity": "MEDIUM",
            "message":  f"Risque de saturation du sol — {rain:.1f} mm de pluie prévus.",
        })

    return alerts


@alerts_bp.route("/weather", methods=["POST"])
@jwt_required
def weather_alerts():
    """
    Génère des alertes agronomiques à partir des prévisions météo 7 jours.

    Body JSON requis :
        lat          (float) — latitude GPS
        lng          (float) — longitude GPS

    Body JSON optionnel :
        culture_type (str)  — ex: "Wheat". Permet d'affiner les seuils.
        days         (int)  — horizon de prévision (1–14, défaut 7)
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    lat  = data.get("lat")
    lng  = data.get("lng")
    if lat is None or lng is None:
        return jsonify({"error": "lat et lng sont requis"}), 400

    culture_type = data.get("culture_type", "default")
    days         = min(max(int(data.get("days", 7)), 1), 14)

    try:
        forecast = weather_service.get_forecast(lat, lng, days=days)
    except Exception as exc:
        return jsonify({"error": f"Open-Meteo indisponible : {exc}"}), 503

    daily     = forecast.get("daily", {})
    dates     = daily.get("time",                [])
    temps_max = daily.get("temperature_2m_max",  [])
    temps_min = daily.get("temperature_2m_min",  [])
    precip    = daily.get("precipitation_sum",   [])

    thr    = _thresholds_for(culture_type)
    alerts = []

    for i, d in enumerate(dates):
        t_min = temps_min[i] if i < len(temps_min) else None
        t_max = temps_max[i] if i < len(temps_max) else None
        rain  = precip[i]    if i < len(precip)    else None
        alerts.extend(_analyse_day(d, t_min, t_max, rain, thr))

    severity_order = {"HIGH": 0, "MEDIUM": 1, "LOW": 2}
    alerts.sort(key=lambda a: (a["date"], severity_order.get(a["severity"], 9)))

    return jsonify({
        "data": {
            "culture_type":  culture_type,
            "forecast_days": len(dates),
            "alert_count":   len(alerts),
            "alerts":        alerts,
            "thresholds":    thr,
        }
    }), 200


@alerts_bp.route("/scan", methods=["POST"])
@jwt_required
def scan_all_parcels():
    """
    Scanne toutes les parcelles de l'utilisateur, génère des alertes
    météo intelligentes (gel, sécheresse, inondation, canicule, irrigation)
    et les persiste en base MongoDB.

    Retourne le nombre total d'alertes créées.
    """
    db = get_db()
    user_id = ObjectId(request.user_id)
    parcels = list(db.parcels.find({"user_id": user_id}))

    if not parcels:
        return jsonify({"data": {"alerts_created": 0, "message": "Aucune parcelle"}}), 200

    total_created = 0

    for parcel in parcels:
        coords = parcel.get("coordinates", [])
        if coords and isinstance(coords[0], dict):
            lat = coords[0].get("lat", 46.6)
            lng = coords[0].get("lng", 2.3)
        elif coords and isinstance(coords[0], (list, tuple)):
            lat, lng = coords[0][0], coords[0][1]
        else:
            continue

        culture_type = parcel.get("culture_type", "default")
        thr = _thresholds_for(culture_type)

        try:
            forecast = weather_service.get_forecast(lat, lng, days=7)
        except Exception:
            continue

        daily = forecast.get("daily", {})
        dates = daily.get("time", [])
        temps_max = daily.get("temperature_2m_max", [])
        temps_min = daily.get("temperature_2m_min", [])
        precip = daily.get("precipitation_sum", [])

        raw_alerts = []
        for i, d in enumerate(dates):
            t_min = temps_min[i] if i < len(temps_min) else None
            t_max = temps_max[i] if i < len(temps_max) else None
            rain = precip[i] if i < len(precip) else None
            raw_alerts.extend(_analyse_day(d, t_min, t_max, rain, thr))

        # Détection canicule (3 jours consécutifs > 35°C)
        hot_streak = 0
        for i in range(len(temps_max)):
            if temps_max[i] is not None and temps_max[i] > 35:
                hot_streak += 1
                if hot_streak >= 3:
                    raw_alerts.append({
                        "date": dates[i] if i < len(dates) else "",
                        "type": "HEAT_WAVE",
                        "severity": "HIGH",
                        "message": f"Canicule — {hot_streak} jours consécutifs au-dessus de 35°C. Protégez vos cultures et irriguez.",
                    })
                    break
            else:
                hot_streak = 0

        # Détection besoin irrigation (cumul pluie 7j < 5mm et temp moy > 20°C)
        total_rain_7d = sum(r for r in precip[:7] if r is not None)
        avg_temp_7d = sum(t for t in temps_max[:7] if t is not None) / max(len([t for t in temps_max[:7] if t is not None]), 1)
        if total_rain_7d < 5 and avg_temp_7d > 20:
            raw_alerts.append({
                "date": dates[0] if dates else "",
                "type": "IRRIGATION_NEEDED",
                "severity": "MEDIUM",
                "message": f"Irrigation recommandée — seulement {total_rain_7d:.1f}mm de pluie prévus sur 7 jours avec {avg_temp_7d:.0f}°C en moyenne.",
            })

        # Persister les alertes en base
        parcel_id = parcel["_id"]
        for raw in raw_alerts:
            severity_map = {"HIGH": "critical", "MEDIUM": "warning", "LOW": "info"}
            alert = Alert(
                user_id=request.user_id,
                parcel_id=str(parcel_id),
                type_msg=raw["type"].lower(),
                message=f"[{parcel.get('name', '?')}] {raw['message']}",
                severity=severity_map.get(raw["severity"], "info"),
            )
            db.alerts.insert_one(alert.to_mongo())
            total_created += 1

    return jsonify({"data": {"alerts_created": total_created}}), 200


@alerts_bp.route("", methods=["GET"])
@jwt_required
def list_alerts():
    """Liste les alertes persistées de l'utilisateur (non lues en premier)."""
    db = get_db()
    user_id = ObjectId(request.user_id)
    limit = min(int(request.args.get("limit", 30)), 100)
    unread_only = request.args.get("unread") == "true"

    query = {"user_id": user_id}
    if unread_only:
        query["read"] = False

    cursor = db.alerts.find(query, sort=[("read", 1), ("created_at", -1)], limit=limit)

    alerts = []
    for doc in cursor:
        a = Alert.from_mongo(doc)
        alerts.append(a.to_dict())

    unread_count = db.alerts.count_documents({"user_id": user_id, "read": False})

    return jsonify({"data": {"alerts": alerts, "unread_count": unread_count}}), 200


@alerts_bp.route("/<alert_id>/read", methods=["POST"])
@jwt_required
def mark_read(alert_id):
    """Marque une alerte comme lue."""
    db = get_db()
    result = db.alerts.update_one(
        {"_id": ObjectId(alert_id), "user_id": ObjectId(request.user_id)},
        {"$set": {"read": True}},
    )
    if result.matched_count == 0:
        return jsonify({"error": "Alerte non trouvée"}), 404
    return jsonify({"message": "Alerte marquée comme lue"}), 200


@alerts_bp.route("/read-all", methods=["POST"])
@jwt_required
def mark_all_read():
    """Marque toutes les alertes de l'utilisateur comme lues."""
    db = get_db()
    result = db.alerts.update_many(
        {"user_id": ObjectId(request.user_id), "read": False},
        {"$set": {"read": True}},
    )
    return jsonify({"data": {"marked_count": result.modified_count}}), 200

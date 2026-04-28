from flask import Blueprint, request, jsonify
from ..utils.auth_utils import jwt_required
from ..services import weather_service

alerts_bp = Blueprint("alerts", __name__)

# Seuils agronomiques par culture (°C, mm/jour)
# frost_c      : température min en dessous de laquelle il y a risque de gel
# drought_temp : température max à partir de laquelle le stress hydrique est critique
# flood_mm     : cumul journalier qui provoque un risque de saturation/inondation
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

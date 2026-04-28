from bson import ObjectId
from ..data_access.alert_repository import AlertRepository
from ..data_access.parcel_repository import ParcelRepository
from ..entities.alert import Alert
from ..dto.alert_dto import AlertResponse
from ..services import weather_service


# Seuils agronomiques par culture
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
    alerts = []

    if t_min is not None and t_min < thr["frost_c"]:
        alerts.append({
            "date": date, "type": "FROST", "severity": "HIGH",
            "message": f"Risque de gel — {t_min:.1f}°C prévu. Protégez vos cultures.",
        })

    if t_max is not None and rain is not None:
        if t_max > thr["drought_temp"] and rain < 1.0:
            alerts.append({
                "date": date, "type": "DROUGHT", "severity": "MEDIUM",
                "message": f"Stress hydrique — {t_max:.1f}°C sans précipitations. Irrigation recommandée.",
            })

    if rain is not None and rain > thr["flood_mm"]:
        alerts.append({
            "date": date, "type": "FLOOD", "severity": "MEDIUM",
            "message": f"Risque de saturation du sol — {rain:.1f} mm de pluie prévus.",
        })

    return alerts


def generate_weather_alerts(lat, lng, culture_type="default", days=7):
    forecast = weather_service.get_forecast(lat, lng, days=days)

    daily = forecast.get("daily", {})
    dates = daily.get("time", [])
    temps_max = daily.get("temperature_2m_max", [])
    temps_min = daily.get("temperature_2m_min", [])
    precip = daily.get("precipitation_sum", [])

    thr = _thresholds_for(culture_type)
    alerts = []

    for i, d in enumerate(dates):
        t_min = temps_min[i] if i < len(temps_min) else None
        t_max = temps_max[i] if i < len(temps_max) else None
        rain = precip[i] if i < len(precip) else None
        alerts.extend(_analyse_day(d, t_min, t_max, rain, thr))

    severity_order = {"HIGH": 0, "MEDIUM": 1, "LOW": 2}
    alerts.sort(key=lambda a: (a["date"], severity_order.get(a["severity"], 9)))

    return {
        "culture_type": culture_type,
        "forecast_days": len(dates),
        "alert_count": len(alerts),
        "alerts": alerts,
        "thresholds": thr,
    }


def scan_all_parcels(user_id):
    parcels = ParcelRepository.find_by_user_raw(user_id)

    if not parcels:
        return 0

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

        # Canicule
        hot_streak = 0
        for i in range(len(temps_max)):
            if temps_max[i] is not None and temps_max[i] > 35:
                hot_streak += 1
                if hot_streak >= 3:
                    raw_alerts.append({
                        "date": dates[i] if i < len(dates) else "",
                        "type": "HEAT_WAVE", "severity": "HIGH",
                        "message": f"Canicule — {hot_streak} jours consécutifs au-dessus de 35°C. Protégez vos cultures et irriguez.",
                    })
                    break
            else:
                hot_streak = 0

        # Irrigation
        total_rain_7d = sum(r for r in precip[:7] if r is not None)
        avg_temp_7d = sum(t for t in temps_max[:7] if t is not None) / max(len([t for t in temps_max[:7] if t is not None]), 1)
        if total_rain_7d < 5 and avg_temp_7d > 20:
            raw_alerts.append({
                "date": dates[0] if dates else "",
                "type": "IRRIGATION_NEEDED", "severity": "MEDIUM",
                "message": f"Irrigation recommandée — seulement {total_rain_7d:.1f}mm de pluie prévus sur 7 jours avec {avg_temp_7d:.0f}°C en moyenne.",
            })

        # Persister
        parcel_id = parcel["_id"]
        severity_map = {"HIGH": "critical", "MEDIUM": "warning", "LOW": "info"}
        for raw in raw_alerts:
            alert = Alert(
                user_id=str(user_id),
                parcel_id=str(parcel_id),
                type_msg=raw["type"].lower(),
                message=f"[{parcel.get('name', '?')}] {raw['message']}",
                severity=severity_map.get(raw["severity"], "info"),
            )
            AlertRepository.insert(alert)
            total_created += 1

    return total_created


def list_alerts(user_id, limit=30, unread_only=False):
    alerts = AlertRepository.find_by_user(user_id, limit=limit, unread_only=unread_only)
    unread_count = AlertRepository.count_unread(user_id)
    return {
        "alerts": AlertResponse.from_entity_list(alerts),
        "unread_count": unread_count,
    }


def mark_read(alert_id, user_id):
    return AlertRepository.mark_read(alert_id, user_id)


def mark_all_read(user_id):
    return AlertRepository.mark_all_read(user_id)

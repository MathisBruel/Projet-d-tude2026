from flask import Blueprint, request, jsonify
from ..services import weather_service
from ..services.auth_service import jwt_required

weather_bp = Blueprint("weather", __name__, url_prefix="/api/v1/weather")

_WMO_CONDITIONS = {
    0:  "Ciel dégagé",
    1:  "Peu nuageux",
    2:  "Partiellement nuageux",
    3:  "Couvert",
    45: "Brouillard",
    48: "Brouillard givrant",
    51: "Bruine légère",
    53: "Bruine modérée",
    55: "Bruine dense",
    56: "Bruine verglaçante légère",
    57: "Bruine verglaçante dense",
    61: "Pluie légère",
    63: "Pluie modérée",
    65: "Pluie forte",
    66: "Pluie verglaçante légère",
    67: "Pluie verglaçante forte",
    71: "Neige légère",
    73: "Neige modérée",
    75: "Neige forte",
    77: "Granules de neige",
    80: "Averses légères",
    81: "Averses modérées",
    82: "Averses fortes",
    85: "Averses de neige légères",
    86: "Averses de neige fortes",
    95: "Orage",
    96: "Orage avec grêle légère",
    99: "Orage avec grêle forte",
}


def _wmo_to_condition(code: int) -> str:
    return _WMO_CONDITIONS.get(code, "Nuageux")


@weather_bp.route("", methods=["GET"])
@jwt_required
def get_weather():
    try:
        lat = float(request.args["lat"])
        lng = float(request.args["lng"])
    except (KeyError, TypeError, ValueError):
        return jsonify({"error": "Paramètres lat et lng requis (float)"}), 400

    days = min(max(int(request.args.get("days", 7)), 1), 7)

    try:
        raw = weather_service.get_current_and_forecast(lat, lng, days=days)
    except Exception as exc:
        return jsonify({"error": f"Open-Meteo indisponible : {exc}"}), 503

    current = raw.get("current_weather", {})
    daily = raw.get("daily", {})
    hourly = raw.get("hourly", {})

    humidity = None
    humidity_list = hourly.get("relative_humidity_2m", [])
    if humidity_list:
        humidity = humidity_list[0]

    feels_like = None
    feels_list = hourly.get("apparent_temperature", [])
    if feels_list:
        feels_like = round(feels_list[0], 1)

    wmo = int(current.get("weathercode", 0))

    return jsonify({
        "data": {
            "current": {
                "temp_c": round(current.get("temperature", 0), 1),
                "feels_like_c": feels_like,
                "windspeed_kmh": round(current.get("windspeed", 0), 1),
                "humidity_pct": humidity,
                "condition": _wmo_to_condition(wmo),
                "weathercode": wmo,
                "is_day": current.get("is_day", 1),
            },
            "daily": {
                "dates": daily.get("time", []),
                "temp_max": daily.get("temperature_2m_max", []),
                "temp_min": daily.get("temperature_2m_min", []),
                "precipitation_mm": daily.get("precipitation_sum", []),
                "weathercodes": daily.get("weathercode", []),
                "windspeed_max": daily.get("windspeed_10m_max", []),
            },
        }
    }), 200

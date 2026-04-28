"""
Couche d'accès aux APIs météo gratuites Open-Meteo.
Pas de clé API requise.
"""

import requests
from datetime import date, timedelta

_FORECAST_URL    = "https://api.open-meteo.com/v1/forecast"
_HISTORICAL_URL  = "https://archive-api.open-meteo.com/v1/archive"
_TIMEOUT         = 10  # secondes


def get_forecast(lat: float, lng: float, days: int = 7) -> dict:
    """Prévisions journalières sur `days` jours pour une position GPS."""
    params = {
        "latitude":      lat,
        "longitude":     lng,
        "daily": [
            "temperature_2m_max",
            "temperature_2m_min",
            "precipitation_sum",
            "windspeed_10m_max",
        ],
        "forecast_days": days,
        "timezone":      "auto",
    }
    resp = requests.get(_FORECAST_URL, params=params, timeout=_TIMEOUT)
    resp.raise_for_status()
    return resp.json()


def get_recent_weather_averages(lat: float, lng: float, days_back: int = 30) -> dict:
    """
    Calcule la température moyenne et la pluviométrie totale
    sur les `days_back` derniers jours via l'API historique.

    Retourne :
        avg_temp_c            — température moyenne (°C)
        rainfall_mm_30d       — cumul pluie sur la période (mm)
        rainfall_mm_annual_est — estimation annuelle (mm/an)
    """
    end   = date.today() - timedelta(days=1)
    start = end - timedelta(days=days_back - 1)

    params = {
        "latitude":   lat,
        "longitude":  lng,
        "start_date": start.isoformat(),
        "end_date":   end.isoformat(),
        "daily": [
            "temperature_2m_mean",
            "precipitation_sum",
        ],
        "timezone": "auto",
    }
    resp = requests.get(_HISTORICAL_URL, params=params, timeout=_TIMEOUT)
    resp.raise_for_status()
    data = resp.json()

    daily = data.get("daily", {})
    temps = [t for t in daily.get("temperature_2m_mean", []) if t is not None]
    rains = [r for r in daily.get("precipitation_sum",   []) if r is not None]

    avg_temp_c      = round(sum(temps) / len(temps), 2) if temps else 12.0
    rainfall_30d    = round(sum(rains), 2)              if rains else 50.0
    # Extrapolation annuelle simple
    annual_est      = round(rainfall_30d * (365 / days_back), 2)

    return {
        "avg_temp_c":             avg_temp_c,
        "rainfall_mm_30d":        rainfall_30d,
        "rainfall_mm_annual_est": annual_est,
    }

from datetime import datetime
from bson import ObjectId
from ..data_access.parcel_repository import ParcelRepository
from ..data_access.parcel_action_repository import ParcelActionRepository
from ..services import weather_service, gemini_service


def get_tips(user_id, parcel_id):
    parcel = ParcelRepository.find_one_raw(parcel_id, user_id)
    if not parcel:
        return None

    # Coordonnées pour la météo
    coords = parcel.get("coordinates", [])
    if coords and isinstance(coords[0], dict):
        lat = coords[0].get("lat", 46.6)
        lng = coords[0].get("lng", 2.3)
    elif coords and isinstance(coords[0], (list, tuple)):
        lat, lng = coords[0][0], coords[0][1]
    else:
        lat, lng = 46.6, 2.3

    try:
        forecast = weather_service.get_forecast(lat, lng, days=7)
    except Exception:
        forecast = {"daily": {}}

    # Actions récentes
    raw_actions = ParcelActionRepository.find_recent_raw(parcel_id, days=30, limit=10)
    actions = []
    for a in raw_actions:
        actions.append({
            "action_type": a.get("action_type"),
            "date": a["date"].strftime("%Y-%m-%d") if isinstance(a.get("date"), datetime) else str(a.get("date", "")),
            "product_name": a.get("product_name", ""),
            "quantity": a.get("quantity", ""),
            "unit": a.get("unit", ""),
            "notes": a.get("notes", ""),
        })

    parcel_data = {
        "culture_type": parcel.get("culture_type", "inconnu"),
        "soil_type": parcel.get("soil_type", "inconnu"),
        "region": parcel.get("region", "France"),
        "area_ha": parcel.get("area_ha", 0),
    }

    tips = gemini_service.generate_tips(parcel_data, forecast, actions)

    return {
        "parcel_id": parcel_id,
        "parcel_name": parcel.get("name", ""),
        "tips": tips,
        "generated_at": datetime.utcnow().isoformat(),
    }

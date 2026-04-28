from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime, timedelta
from ..database import get_db
from ..services import weather_service, gemini_service
from ..utils.auth_utils import jwt_required

tips_bp = Blueprint("tips", __name__)


@tips_bp.route("/<parcel_id>/tips", methods=["GET"])
@jwt_required
def get_tips(parcel_id):
    """
    Génère des conseils IA personnalisés pour une parcelle.
    Combine données parcelle + météo 7j + actions récentes → Gemini.
    """
    db = get_db()
    user_id = ObjectId(request.user_id)

    parcel = db.parcels.find_one({"_id": ObjectId(parcel_id), "user_id": user_id})
    if not parcel:
        return jsonify({"error": "Parcelle non trouvée"}), 404

    # Coordonnées pour la météo
    coords = parcel.get("coordinates", [])
    if coords and isinstance(coords[0], dict):
        lat = coords[0].get("lat", 46.6)
        lng = coords[0].get("lng", 2.3)
    elif coords and isinstance(coords[0], (list, tuple)):
        lat, lng = coords[0][0], coords[0][1]
    else:
        lat, lng = 46.6, 2.3  # Centre France fallback

    # Récupérer la météo prévisionnelle
    try:
        forecast = weather_service.get_forecast(lat, lng, days=7)
    except Exception:
        forecast = {"daily": {}}

    # Récupérer les actions récentes (30 jours)
    since = datetime.utcnow() - timedelta(days=30)
    actions_cursor = db.parcel_actions.find(
        {"parcel_id": ObjectId(parcel_id), "date": {"$gte": since}},
        sort=[("date", -1)],
        limit=10,
    )
    actions = []
    for a in actions_cursor:
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

    return jsonify({
        "data": {
            "parcel_id": parcel_id,
            "parcel_name": parcel.get("name", ""),
            "tips": tips,
            "generated_at": datetime.utcnow().isoformat(),
        }
    }), 200

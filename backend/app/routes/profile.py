from flask import Blueprint, jsonify, request
from bson import ObjectId
from collections import Counter
from ..database import get_db
from ..utils.auth_utils import jwt_required

profile_bp = Blueprint('profile', __name__, url_prefix='/api/v1/profile')


def _most_common(values):
    filtered = [v for v in values if v]
    if not filtered:
        return None
    return Counter(filtered).most_common(1)[0][0]


@profile_bp.route('', methods=['GET'])
@jwt_required
def get_profile():
    db = get_db()
    user_id = ObjectId(request.user_id)

    user = db.users.find_one({"_id": user_id})
    if not user:
        return jsonify({"error": "Utilisateur non trouve"}), 404

    parcels = list(db.parcels.find({"user_id": user_id}))
    predictions = list(db.predictions.find({"user_id": user_id}))
    unread_alerts = db.alerts.count_documents({"user_id": user_id, "read": False})

    parcels_count = len(parcels)
    total_area_ha = round(sum(p.get('area_ha') or 0 for p in parcels), 1)
    main_crop = _most_common([p.get('culture_type') for p in parcels])
    region = _most_common([p.get('region') for p in parcels])

    predictions_count = len(predictions)
    yields = [p.get('predicted_yield_t_ha') for p in predictions if p.get('predicted_yield_t_ha') is not None]
    avg_yield_t_ha = round(sum(yields) / len(yields), 1) if yields else None

    best_prediction = None
    for prediction in predictions:
        if prediction.get('predicted_yield_t_ha') is None:
            continue
        if not best_prediction or prediction.get('predicted_yield_t_ha') > best_prediction.get('predicted_yield_t_ha'):
            best_prediction = prediction

    best_parcel_name = None
    best_parcel_yield = None
    if best_prediction:
        best_parcel = db.parcels.find_one({"_id": best_prediction.get('parcel_id')})
        best_parcel_name = best_parcel.get('name') if best_parcel else None
        best_parcel_yield = best_prediction.get('predicted_yield_t_ha')

    profile = {
        "id": str(user.get('_id')),
        "email": user.get('email'),
        "role": user.get('role'),
        "first_name": user.get('first_name'),
        "last_name": user.get('last_name'),
        "phone": user.get('phone'),
    }

    stats = {
        "parcels_count": parcels_count,
        "total_area_ha": total_area_ha,
        "main_crop": main_crop,
        "region": region,
        "predictions_count": predictions_count,
        "avg_yield_t_ha": avg_yield_t_ha,
        "best_parcel_name": best_parcel_name,
        "best_parcel_yield_t_ha": best_parcel_yield,
        "notifications_unread": unread_alerts,
    }

    return jsonify({"profile": profile, "stats": stats}), 200

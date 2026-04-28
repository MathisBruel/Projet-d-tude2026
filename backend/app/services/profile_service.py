import os
import uuid
from datetime import datetime
from bson import ObjectId
from collections import Counter
from ..data_access.user_repository import UserRepository
from ..data_access.parcel_repository import ParcelRepository
from ..data_access.prediction_repository import PredictionRepository
from ..data_access.alert_repository import AlertRepository
from ..dto.profile_dto import ProfileResponse


def _most_common(values):
    filtered = [v for v in values if v]
    if not filtered:
        return None
    return Counter(filtered).most_common(1)[0][0]


def get_profile(user_id):
    user = UserRepository.find_by_id_raw(user_id)
    if not user:
        return None

    parcels = ParcelRepository.find_by_user_raw(user_id)
    predictions = PredictionRepository.find_by_user_raw(user_id)
    unread_alerts = AlertRepository.count_unread(user_id)

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
        best_parcel = ParcelRepository.find_by_id(best_prediction.get('parcel_id'))
        best_parcel_name = best_parcel.get('name') if best_parcel else None
        best_parcel_yield = best_prediction.get('predicted_yield_t_ha')

    profile = ProfileResponse.from_user(user)
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

    return {"profile": profile, "stats": stats}


def update_profile(user_id, update_data: dict):
    UserRepository.update(user_id, update_data)
    user = UserRepository.find_by_id_raw(user_id)
    return ProfileResponse.from_user(user)


def upload_avatar(user_id, file):
    allowed_extensions = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
    if '.' not in file.filename or file.filename.rsplit('.', 1)[1].lower() not in allowed_extensions:
        raise ValueError("Format de fichier non autorisé. Utilisez PNG, JPG, JPEG, GIF ou WebP")

    upload_folder = os.path.join(os.path.dirname(__file__), '../../uploads/avatars')
    os.makedirs(upload_folder, exist_ok=True)

    file_ext = file.filename.rsplit('.', 1)[1].lower()
    filename = f"{user_id}_{uuid.uuid4().hex}.{file_ext}"
    filepath = os.path.join(upload_folder, filename)

    file.save(filepath)

    image_url = f"/uploads/avatars/{filename}"
    UserRepository.update(user_id, {"avatar_url": image_url})

    return image_url

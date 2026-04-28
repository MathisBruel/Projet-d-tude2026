from flask import Blueprint, jsonify, request
from bson import ObjectId
from datetime import datetime
from collections import Counter
import os
import uuid
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
        return jsonify({"error": "Utilisateur non trouvé"}), 404

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
        "id":            str(user.get('_id')),
        "email":         user.get('email'),
        "role":          user.get('role'),
        "first_name":    user.get('first_name'),
        "last_name":     user.get('last_name'),
        "phone":         user.get('phone'),
        "location_name": user.get('location_name'),
        "location_lat":  user.get('location_lat'),
        "location_lng":  user.get('location_lng'),
        "avatar_url":    user.get('avatar_url'),
    }

    stats = {
        "parcels_count":          parcels_count,
        "total_area_ha":          total_area_ha,
        "main_crop":              main_crop,
        "region":                 region,
        "predictions_count":      predictions_count,
        "avg_yield_t_ha":         avg_yield_t_ha,
        "best_parcel_name":       best_parcel_name,
        "best_parcel_yield_t_ha": best_parcel_yield,
        "notifications_unread":   unread_alerts,
    }

    return jsonify({"profile": profile, "stats": stats}), 200


@profile_bp.route('', methods=['PUT'])
@jwt_required
def update_profile():
    """
    Met à jour les informations du profil utilisateur.

    Champs acceptés :
        first_name, last_name, phone,
        location_name, location_lat, location_lng
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    db = get_db()
    user_id = ObjectId(request.user_id)

    allowed = ['first_name', 'last_name', 'phone', 'location_name', 'location_lat', 'location_lng']
    update = {k: data[k] for k in allowed if k in data}

    if not update:
        return jsonify({"error": "Aucun champ valide fourni"}), 400

    update['updated_at'] = datetime.utcnow()

    db.users.update_one({"_id": user_id}, {"$set": update})

    user = db.users.find_one({"_id": user_id})
    profile = {
        "id":            str(user.get('_id')),
        "email":         user.get('email'),
        "role":          user.get('role'),
        "first_name":    user.get('first_name'),
        "last_name":     user.get('last_name'),
        "phone":         user.get('phone'),
        "location_name": user.get('location_name'),
        "location_lat":  user.get('location_lat'),
        "location_lng":  user.get('location_lng'),
        "avatar_url":    user.get('avatar_url'),
    }

    return jsonify({"message": "Profil mis à jour", "profile": profile}), 200


@profile_bp.route('/avatar', methods=['POST'])
@jwt_required
def upload_avatar():
    """
    Upload l'image de profil (avatar) de l'utilisateur.
    Accepte les fichiers PNG, JPG, JPEG, GIF.
    """
    if 'file' not in request.files:
        return jsonify({"error": "Aucun fichier fourni"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "Nom de fichier vide"}), 400

    # Vérifier l'extension
    allowed_extensions = {'png', 'jpg', 'jpeg', 'gif'}
    if '.' not in file.filename or file.filename.rsplit('.', 1)[1].lower() not in allowed_extensions:
        return jsonify({"error": "Format de fichier non autorisé. Utilisez PNG, JPG, JPEG ou GIF"}), 400

    try:
        # Créer le dossier uploads s'il n'existe pas
        upload_folder = os.path.join(os.path.dirname(__file__), '../../uploads/avatars')
        os.makedirs(upload_folder, exist_ok=True)

        # Générer un nom de fichier unique
        file_ext = file.filename.rsplit('.', 1)[1].lower()
        user_id = request.user_id
        filename = f"{user_id}_{uuid.uuid4().hex}.{file_ext}"
        filepath = os.path.join(upload_folder, filename)

        # Sauvegarder le fichier
        file.save(filepath)

        # Construire l'URL de l'image
        image_url = f"/uploads/avatars/{filename}"

        # Mettre à jour la base de données avec l'URL de l'avatar
        db = get_db()
        user_id_obj = ObjectId(user_id)
        db.users.update_one(
            {"_id": user_id_obj},
            {"$set": {
                "avatar_url": image_url,
                "updated_at": datetime.utcnow()
            }}
        )

        return jsonify({
            "message": "Avatar mis à jour",
            "avatar_url": image_url
        }), 200

    except Exception as e:
        return jsonify({"error": f"Erreur lors de l'upload: {str(e)}"}), 500

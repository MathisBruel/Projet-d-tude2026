from flask import Blueprint, request, jsonify
from ..dto.profile_dto import UpdateProfileRequest
from ..services import profile_service
from ..services.auth_service import jwt_required

profile_bp = Blueprint('profile', __name__, url_prefix='/api/v1/profile')


@profile_bp.route('', methods=['GET'])
@jwt_required
def get_profile():
    result = profile_service.get_profile(request.user_id)
    if not result:
        return jsonify({"error": "Utilisateur non trouvé"}), 404
    return jsonify(result), 200


@profile_bp.route('', methods=['PUT'])
@jwt_required
def update_profile():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    dto = UpdateProfileRequest(data)
    error = dto.validate()
    if error:
        return jsonify({"error": error}), 400

    profile = profile_service.update_profile(request.user_id, dto.updates)
    return jsonify({"message": "Profil mis à jour", "profile": profile}), 200


@profile_bp.route('/avatar', methods=['POST'])
@jwt_required
def upload_avatar():
    if 'file' not in request.files:
        return jsonify({"error": "Aucun fichier fourni"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "Nom de fichier vide"}), 400

    try:
        image_url = profile_service.upload_avatar(request.user_id, file)
        return jsonify({"message": "Avatar mis à jour", "avatar_url": image_url}), 200
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": f"Erreur lors de l'upload: {str(e)}"}), 500

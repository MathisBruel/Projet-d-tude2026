from flask import Blueprint, request, jsonify
from ..dto.parcel_dto import CreateParcelRequest, UpdateParcelRequest
from ..services import parcel_service
from ..services.auth_service import jwt_required

parcels_bp = Blueprint('parcels', __name__)


@parcels_bp.route('', methods=['GET'])
@jwt_required
def get_parcels():
    data = parcel_service.get_parcels(request.user_id)
    return jsonify({"data": data}), 200


@parcels_bp.route('', methods=['POST'])
@jwt_required
def create_parcel():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    dto = CreateParcelRequest(data)
    error = dto.validate()
    if error:
        return jsonify({"error": error}), 400

    try:
        result = parcel_service.create_parcel(request.user_id, dto)
        return jsonify({"message": "Parcelle créée avec succès", "data": result}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@parcels_bp.route('/<parcel_id>', methods=['GET'])
@jwt_required
def get_parcel(parcel_id):
    try:
        result = parcel_service.get_parcel(parcel_id, request.user_id)
        if not result:
            return jsonify({"error": "Parcelle non trouvée"}), 404
        return jsonify({"data": result}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@parcels_bp.route('/<parcel_id>', methods=['PUT'])
@jwt_required
def update_parcel(parcel_id):
    data = request.get_json()
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    dto = UpdateParcelRequest(data)
    try:
        result = parcel_service.update_parcel(parcel_id, request.user_id, dto)
        if not result:
            return jsonify({"error": "Parcelle non trouvée"}), 404
        return jsonify({"message": "Parcelle mise à jour avec succès", "data": result}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@parcels_bp.route('/<parcel_id>', methods=['DELETE'])
@jwt_required
def delete_parcel(parcel_id):
    try:
        deleted = parcel_service.delete_parcel(parcel_id, request.user_id)
        if deleted == 0:
            return jsonify({"error": "Parcelle non trouvée"}), 404
        return jsonify({"message": "Parcelle supprimée avec succès"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

from flask import Blueprint, request, jsonify
from ..dto.parcel_action_dto import CreateActionRequest
from ..services import parcel_action_service
from ..services.auth_service import jwt_required

parcel_actions_bp = Blueprint("parcel_actions", __name__)


@parcel_actions_bp.route("/<parcel_id>/actions", methods=["POST"])
@jwt_required
def create_action(parcel_id):
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    dto = CreateActionRequest(data)
    error = dto.validate()
    if error:
        return jsonify({"error": error}), 400

    result = parcel_action_service.create_action(request.user_id, parcel_id, dto)
    if not result:
        return jsonify({"error": "Parcelle non trouvée"}), 404

    return jsonify({"message": "Action enregistrée", "data": result}), 201


@parcel_actions_bp.route("/<parcel_id>/actions", methods=["GET"])
@jwt_required
def list_actions(parcel_id):
    limit = min(int(request.args.get("limit", 50)), 200)
    days = int(request.args.get("days", 90))

    result = parcel_action_service.list_actions(request.user_id, parcel_id, days=days, limit=limit)
    if result is None:
        return jsonify({"error": "Parcelle non trouvée"}), 404

    return jsonify({"data": {"actions": result, "count": len(result)}}), 200


@parcel_actions_bp.route("/<parcel_id>/actions/<action_id>", methods=["DELETE"])
@jwt_required
def delete_action(parcel_id, action_id):
    deleted = parcel_action_service.delete_action(action_id, parcel_id, request.user_id)
    if deleted == 0:
        return jsonify({"error": "Action non trouvée"}), 404
    return jsonify({"message": "Action supprimée"}), 200

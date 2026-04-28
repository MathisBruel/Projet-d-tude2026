from flask import Blueprint, request, jsonify
from ..services import tips_service
from ..services.auth_service import jwt_required

tips_bp = Blueprint("tips", __name__)


@tips_bp.route("/<parcel_id>/tips", methods=["GET"])
@jwt_required
def get_tips(parcel_id):
    result = tips_service.get_tips(request.user_id, parcel_id)
    if not result:
        return jsonify({"error": "Parcelle non trouvée"}), 404
    return jsonify({"data": result}), 200

from flask import Blueprint, jsonify, request
from ..services.auth_service import jwt_required

health_bp = Blueprint('health', __name__)


@health_bp.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "backend"})


@health_bp.route('/api/v1/health/protected', methods=['GET'])
@jwt_required
def protected_health_check():
    return jsonify({
        "status": "healthy",
        "service": "backend",
        "auth": "success",
        "user_id": getattr(request, 'user_id', None)
    })

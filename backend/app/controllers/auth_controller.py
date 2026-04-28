from flask import Blueprint, request, jsonify
from ..dto.auth_dto import RegisterRequest, LoginRequest
from ..services import auth_service

auth_bp = Blueprint('auth', __name__, url_prefix='/api/v1/auth')


@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    dto = RegisterRequest(data)
    error = dto.validate()
    if error:
        return jsonify({"error": error}), 400

    try:
        result = auth_service.register(dto)
        return jsonify(result), 201
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    dto = LoginRequest(data)
    error = dto.validate()
    if error:
        return jsonify({"error": error}), 400

    try:
        result = auth_service.login(dto)
        return jsonify(result), 200
    except ValueError as e:
        return jsonify({"error": str(e)}), 401

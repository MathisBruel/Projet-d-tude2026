import jwt
import bcrypt
from datetime import datetime, timedelta
from functools import wraps
from flask import request, jsonify, current_app
from ..data_access.user_repository import UserRepository
from ..entities.user import User
from ..dto.auth_dto import RegisterRequest, LoginRequest, AuthResponse
from bson import ObjectId


def hash_password(password):
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')


def check_password(password, hashed_password):
    return bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8'))


def generate_token(user_id):
    payload = {
        "sub": str(user_id),
        "iat": datetime.utcnow(),
        "exp": datetime.utcnow() + timedelta(hours=current_app.config['JWT_EXP_HOURS'])
    }
    return jwt.encode(payload, current_app.config['JWT_SECRET'], algorithm="HS256")


def jwt_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]

        if not token:
            return jsonify({"error": "Token manquant"}), 401

        try:
            payload = jwt.decode(token, current_app.config['JWT_SECRET'], algorithms=["HS256"])
            user_id = payload['sub']
            user = UserRepository.find_by_id(user_id)
            if not user:
                return jsonify({"error": "Utilisateur non trouvé"}), 401
            request.user_id = user_id
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Token expiré"}), 401
        except jwt.InvalidTokenError:
            return jsonify({"error": "Token invalide"}), 401

        return f(*args, **kwargs)
    return decorated


def register(dto: RegisterRequest):
    existing = UserRepository.find_by_email(dto.email)
    if existing:
        raise ValueError("Cet email est déjà utilisé")

    hashed_pw = hash_password(dto.password)
    new_user = User(
        email=dto.email,
        password_hash=hashed_pw,
        role=dto.role,
        first_name=dto.first_name,
        last_name=dto.last_name,
        phone=dto.phone,
    )

    inserted_id = UserRepository.insert(new_user)
    new_user._id = inserted_id
    token = generate_token(new_user._id)

    return AuthResponse.success("Utilisateur créé avec succès", token, new_user)


def login(dto: LoginRequest):
    user_data = UserRepository.find_by_email(dto.email)
    if not user_data or not check_password(dto.password, user_data['password_hash']):
        raise ValueError("Identifiants invalides")

    user = User.from_mongo(user_data)
    token = generate_token(user._id)

    return AuthResponse.success("Connexion réussie", token, user)

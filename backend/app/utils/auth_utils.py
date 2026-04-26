import jwt
import bcrypt
from datetime import datetime, timedelta
from functools import wraps
from flask import request, jsonify, current_app
from ..database import get_db
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
            db = get_db()
            user = db.users.find_one({"_id": ObjectId(user_id)})
            if not user:
                return jsonify({"error": "Utilisateur non trouvé"}), 401
            # On ajoute l'id de l'utilisateur à la requête pour un usage ultérieur
            request.user_id = user_id
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Token expiré"}), 401
        except jwt.InvalidTokenError:
            return jsonify({"error": "Token invalide"}), 401
        
        return f(*args, **kwargs)
    
    return decorated

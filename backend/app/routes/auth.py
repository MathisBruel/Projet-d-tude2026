from flask import Blueprint, request, jsonify
from ..database import get_db
from ..models.user import User
from ..utils.auth_utils import hash_password, check_password, generate_token

auth_bp = Blueprint('auth', __name__, url_prefix='/api/v1/auth')

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({"error": "Email et mot de passe requis"}), 400
    
    db = get_db()
    
    # Vérifier si l'utilisateur existe déjà
    if db.users.find_one({"email": data['email']}):
        return jsonify({"error": "Cet email est déjà utilisé"}), 400
    
    try:
        hashed_pw = hash_password(data['password'])
        
        new_user = User(
            email=data['email'],
            password_hash=hashed_pw,
            role=data.get('role', 'farmer'),
            first_name=data.get('first_name'),
            last_name=data.get('last_name'),
            phone=data.get('phone')
        )
        
        result = db.users.insert_one(new_user.to_mongo())
        new_user._id = result.inserted_id
        
        # Générer le token pour l'auto-login
        token = generate_token(new_user._id)
        
        return jsonify({
            "message": "Utilisateur créé avec succès",
            "token": token,
            "user": new_user.to_dict()
        }), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({"error": "Email et mot de passe requis"}), 400
    
    db = get_db()
    user_data = db.users.find_one({"email": data['email']})
    
    if not user_data or not check_password(data['password'], user_data['password_hash']):
        return jsonify({"error": "Identifiants invalides"}), 401
    
    user = User.from_mongo(user_data)
    token = generate_token(user._id)
    
    return jsonify({
        "message": "Connexion réussie",
        "token": token,
        "user": user.to_dict()
    }), 200

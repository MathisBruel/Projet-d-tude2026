from datetime import datetime


class RegisterRequest:
    def __init__(self, data: dict):
        self.email = data.get('email')
        self.password = data.get('password')
        self.role = data.get('role', 'farmer')
        self.first_name = data.get('first_name')
        self.last_name = data.get('last_name')
        self.phone = data.get('phone')

    def validate(self):
        if not self.email or not self.password:
            return "Email et mot de passe requis"
        return None


class LoginRequest:
    def __init__(self, data: dict):
        self.email = data.get('email')
        self.password = data.get('password')

    def validate(self):
        if not self.email or not self.password:
            return "Email et mot de passe requis"
        return None


class AuthResponse:
    @staticmethod
    def success(message, token, user):
        return {
            "message": message,
            "token": token,
            "user": UserResponse.from_entity(user)
        }


class UserResponse:
    @staticmethod
    def from_entity(user):
        return {
            "_id": str(user._id) if user._id else None,
            "email": user.email,
            "role": user.role,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "phone": user.phone,
            "location_name": user.location_name,
            "location_lat": user.location_lat,
            "location_lng": user.location_lng,
            "avatar_url": user.avatar_url,
            "created_at": user.created_at.isoformat() if isinstance(user.created_at, datetime) else user.created_at,
            "updated_at": user.updated_at.isoformat() if isinstance(user.updated_at, datetime) else user.updated_at,
        }

from datetime import datetime
from bson import ObjectId


class User:
    def __init__(self, email, password_hash, role='farmer', first_name=None, last_name=None, phone=None,
                 location_name=None, location_lat=None, location_lng=None, avatar_url=None,
                 _id=None, created_at=None, updated_at=None):
        self._id = ObjectId(_id) if _id else None
        self.email = email
        self.password_hash = password_hash
        self.role = role
        self.first_name = first_name
        self.last_name = last_name
        self.phone = phone
        self.location_name = location_name
        self.location_lat = location_lat
        self.location_lng = location_lng
        self.avatar_url = avatar_url
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = updated_at or datetime.utcnow()

    def to_mongo(self):
        data = {
            "email": self.email,
            "password_hash": self.password_hash,
            "role": self.role,
            "first_name": self.first_name,
            "last_name": self.last_name,
            "phone": self.phone,
            "location_name": self.location_name,
            "location_lat": self.location_lat,
            "location_lng": self.location_lng,
            "avatar_url": self.avatar_url,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
        }
        if self._id:
            data["_id"] = self._id
        return data

    @staticmethod
    def from_mongo(data):
        if not data:
            return None
        return User(
            email=data.get('email'),
            password_hash=data.get('password_hash'),
            role=data.get('role'),
            first_name=data.get('first_name'),
            last_name=data.get('last_name'),
            phone=data.get('phone'),
            location_name=data.get('location_name'),
            location_lat=data.get('location_lat'),
            location_lng=data.get('location_lng'),
            avatar_url=data.get('avatar_url'),
            _id=data.get('_id'),
            created_at=data.get('created_at'),
            updated_at=data.get('updated_at'),
        )

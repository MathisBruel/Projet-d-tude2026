from bson import ObjectId
from datetime import datetime
from ..database import get_db
from ..entities.user import User


class UserRepository:
    @staticmethod
    def _collection():
        return get_db().users

    @classmethod
    def find_by_id(cls, user_id) -> User | None:
        data = cls._collection().find_one({"_id": ObjectId(user_id)})
        return User.from_mongo(data)

    @classmethod
    def find_by_id_raw(cls, user_id) -> dict | None:
        return cls._collection().find_one({"_id": ObjectId(user_id)})

    @classmethod
    def find_by_email(cls, email: str) -> dict | None:
        return cls._collection().find_one({"email": email})

    @classmethod
    def insert(cls, user: User) -> ObjectId:
        result = cls._collection().insert_one(user.to_mongo())
        return result.inserted_id

    @classmethod
    def update(cls, user_id, update_data: dict):
        update_data['updated_at'] = datetime.utcnow()
        cls._collection().update_one(
            {"_id": ObjectId(user_id)},
            {"$set": update_data}
        )

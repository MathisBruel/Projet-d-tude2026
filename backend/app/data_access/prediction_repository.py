from bson import ObjectId
from ..database import get_db


class PredictionRepository:
    @staticmethod
    def _collection():
        return get_db().predictions

    @classmethod
    def insert(cls, doc: dict) -> ObjectId:
        result = cls._collection().insert_one(doc)
        return result.inserted_id

    @classmethod
    def find_by_user(cls, user_id, limit=20) -> list[dict]:
        cursor = cls._collection().find(
            {"user_id": ObjectId(user_id)},
            sort=[("created_at", -1)],
            limit=limit,
        )
        return list(cursor)

    @classmethod
    def find_by_user_raw(cls, user_id) -> list[dict]:
        return list(cls._collection().find({"user_id": ObjectId(user_id)}))

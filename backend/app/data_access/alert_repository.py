from bson import ObjectId
from ..database import get_db
from ..entities.alert import Alert


class AlertRepository:
    @staticmethod
    def _collection():
        return get_db().alerts

    @classmethod
    def insert(cls, alert: Alert) -> ObjectId:
        result = cls._collection().insert_one(alert.to_mongo())
        return result.inserted_id

    @classmethod
    def find_by_user(cls, user_id, limit=30, unread_only=False) -> list[Alert]:
        query = {"user_id": ObjectId(user_id)}
        if unread_only:
            query["read"] = False
        cursor = cls._collection().find(
            query,
            sort=[("read", 1), ("created_at", -1)],
            limit=limit,
        )
        return [Alert.from_mongo(doc) for doc in cursor]

    @classmethod
    def count_unread(cls, user_id) -> int:
        return cls._collection().count_documents({
            "user_id": ObjectId(user_id),
            "read": False
        })

    @classmethod
    def mark_read(cls, alert_id, user_id) -> int:
        result = cls._collection().update_one(
            {"_id": ObjectId(alert_id), "user_id": ObjectId(user_id)},
            {"$set": {"read": True}},
        )
        return result.matched_count

    @classmethod
    def mark_all_read(cls, user_id) -> int:
        result = cls._collection().update_many(
            {"user_id": ObjectId(user_id), "read": False},
            {"$set": {"read": True}},
        )
        return result.modified_count

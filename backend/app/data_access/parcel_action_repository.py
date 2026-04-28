from bson import ObjectId
from datetime import datetime, timedelta
from ..database import get_db
from ..entities.parcel_action import ParcelAction


class ParcelActionRepository:
    @staticmethod
    def _collection():
        return get_db().parcel_actions

    @classmethod
    def insert(cls, action: ParcelAction) -> ObjectId:
        result = cls._collection().insert_one(action.to_mongo())
        return result.inserted_id

    @classmethod
    def find_by_parcel(cls, parcel_id, days=90, limit=50) -> list[ParcelAction]:
        since = datetime.utcnow() - timedelta(days=days)
        cursor = cls._collection().find(
            {"parcel_id": ObjectId(parcel_id), "date": {"$gte": since}},
            sort=[("date", -1)],
            limit=limit,
        )
        return [ParcelAction.from_mongo(doc) for doc in cursor]

    @classmethod
    def find_recent_raw(cls, parcel_id, days=30, limit=5) -> list[dict]:
        since = datetime.utcnow() - timedelta(days=days)
        cursor = cls._collection().find(
            {"parcel_id": ObjectId(parcel_id), "date": {"$gte": since}},
            sort=[("date", -1)],
            limit=limit,
        )
        return list(cursor)

    @classmethod
    def delete(cls, action_id, parcel_id, user_id) -> int:
        result = cls._collection().delete_one({
            "_id": ObjectId(action_id),
            "parcel_id": ObjectId(parcel_id),
            "user_id": ObjectId(user_id),
        })
        return result.deleted_count

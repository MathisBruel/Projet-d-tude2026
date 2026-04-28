from bson import ObjectId
from datetime import datetime
from ..database import get_db
from ..entities.parcel import Parcel


class ParcelRepository:
    @staticmethod
    def _collection():
        return get_db().parcels

    @classmethod
    def find_by_user(cls, user_id) -> list[Parcel]:
        docs = list(cls._collection().find({"user_id": ObjectId(user_id)}))
        return [Parcel.from_mongo(d) for d in docs]

    @classmethod
    def find_by_user_raw(cls, user_id) -> list[dict]:
        return list(cls._collection().find({"user_id": ObjectId(user_id)}))

    @classmethod
    def find_one(cls, parcel_id, user_id) -> Parcel | None:
        data = cls._collection().find_one({
            "_id": ObjectId(parcel_id),
            "user_id": ObjectId(user_id)
        })
        return Parcel.from_mongo(data)

    @classmethod
    def find_one_raw(cls, parcel_id, user_id) -> dict | None:
        return cls._collection().find_one({
            "_id": ObjectId(parcel_id),
            "user_id": ObjectId(user_id)
        })

    @classmethod
    def find_by_id(cls, parcel_id) -> dict | None:
        return cls._collection().find_one({"_id": ObjectId(parcel_id)})

    @classmethod
    def insert(cls, parcel: Parcel) -> ObjectId:
        result = cls._collection().insert_one(parcel.to_mongo())
        return result.inserted_id

    @classmethod
    def update(cls, parcel_id, update_data: dict):
        update_data['updated_at'] = datetime.utcnow()
        cls._collection().update_one(
            {"_id": ObjectId(parcel_id)},
            {"$set": update_data}
        )

    @classmethod
    def delete(cls, parcel_id, user_id) -> int:
        result = cls._collection().delete_one({
            "_id": ObjectId(parcel_id),
            "user_id": ObjectId(user_id)
        })
        return result.deleted_count

    @classmethod
    def find_first_with_region(cls, user_id) -> dict | None:
        return cls._collection().find_one({
            "user_id": ObjectId(user_id),
            "region": {"$ne": None}
        })

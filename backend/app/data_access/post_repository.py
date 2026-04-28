from bson import ObjectId
from datetime import datetime
from ..database import get_db
from ..entities.post import Post


class PostRepository:
    @staticmethod
    def _collection():
        return get_db().posts

    @classmethod
    def find_paginated(cls, query: dict, page: int, limit: int) -> tuple[list[dict], int]:
        skip = (page - 1) * limit
        total = cls._collection().count_documents(query)
        docs = list(
            cls._collection().find(query)
            .sort("created_at", -1)
            .skip(skip)
            .limit(limit)
        )
        return docs, total

    @classmethod
    def find_by_id(cls, post_id) -> dict | None:
        return cls._collection().find_one({"_id": ObjectId(post_id)})

    @classmethod
    def insert(cls, post: Post) -> ObjectId:
        result = cls._collection().insert_one(post.to_mongo())
        return result.inserted_id

    @classmethod
    def add_reply(cls, post_id, reply_mongo: dict) -> int:
        result = cls._collection().update_one(
            {"_id": ObjectId(post_id)},
            {
                "$push": {"replies": reply_mongo},
                "$set": {"updated_at": datetime.utcnow()}
            },
        )
        return result.matched_count

    @classmethod
    def toggle_like(cls, post_id, user_id_str: str, is_liked: bool):
        if is_liked:
            cls._collection().update_one(
                {"_id": ObjectId(post_id)},
                {
                    "$pull": {"liked_by": user_id_str},
                    "$inc": {"likes_count": -1},
                    "$set": {"updated_at": datetime.utcnow()},
                },
            )
        else:
            cls._collection().update_one(
                {"_id": ObjectId(post_id)},
                {
                    "$addToSet": {"liked_by": user_id_str},
                    "$inc": {"likes_count": 1},
                    "$set": {"updated_at": datetime.utcnow()},
                },
            )

    @classmethod
    def fix_negative_likes(cls, post_id):
        post = cls.find_by_id(post_id)
        if post and post.get('likes_count', 0) < 0:
            cls._collection().update_one(
                {"_id": ObjectId(post_id)},
                {"$set": {"likes_count": 0}},
            )

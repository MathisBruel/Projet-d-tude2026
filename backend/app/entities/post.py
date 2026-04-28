from datetime import datetime
from bson import ObjectId


class Reply:
    def __init__(self, user_id, content, created_at=None):
        self.user_id = ObjectId(user_id) if user_id else None
        self.content = content
        self.created_at = created_at or datetime.utcnow()

    def to_mongo(self):
        return {
            "user_id": self.user_id,
            "content": self.content,
            "created_at": self.created_at
        }


class Post:
    def __init__(self, user_id, title, content, tags=None, replies=None,
                 likes_count=0, liked_by=None, image_url=None,
                 _id=None, created_at=None, updated_at=None):
        self._id = ObjectId(_id) if _id else None
        self.user_id = ObjectId(user_id) if user_id else None
        self.title = title
        self.content = content
        self.tags = tags or []
        self.replies = replies or []
        self.likes_count = likes_count
        self.liked_by = liked_by or []
        self.image_url = image_url
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = updated_at or datetime.utcnow()

    def to_mongo(self):
        data = {
            "user_id": self.user_id,
            "title": self.title,
            "content": self.content,
            "tags": self.tags,
            "likes_count": self.likes_count,
            "liked_by": self.liked_by,
            "image_url": self.image_url,
            "replies": [
                {
                    "user_id": r.user_id,
                    "content": r.content,
                    "created_at": r.created_at
                } for r in self.replies
            ],
            "created_at": self.created_at,
            "updated_at": self.updated_at
        }
        if self._id:
            data["_id"] = self._id
        return data

    @staticmethod
    def from_mongo(data):
        if not data:
            return None
        replies_raw = data.get('replies', [])
        replies = [Reply(r.get('user_id'), r.get('content'), r.get('created_at')) for r in replies_raw]
        return Post(
            user_id=data.get('user_id'),
            title=data.get('title'),
            content=data.get('content'),
            tags=data.get('tags'),
            replies=replies,
            likes_count=data.get('likes_count', 0),
            liked_by=data.get('liked_by', []),
            image_url=data.get('image_url'),
            _id=data.get('_id'),
            created_at=data.get('created_at'),
            updated_at=data.get('updated_at')
        )

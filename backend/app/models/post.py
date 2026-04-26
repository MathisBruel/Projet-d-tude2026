from datetime import datetime
from bson import ObjectId

class Reply:
    def __init__(self, user_id, content, created_at=None):
        self.user_id = ObjectId(user_id) if user_id else None
        self.content = content
        self.created_at = created_at or datetime.utcnow()

    def to_dict(self):
        return {
            "user_id": str(self.user_id) if self.user_id else None,
            "content": self.content,
            "created_at": self.created_at.isoformat() if isinstance(self.created_at, datetime) else self.created_at
        }

class Post:
    def __init__(self, user_id, title, content, tags=None, replies=None, _id=None, created_at=None, updated_at=None):
        self._id = ObjectId(_id) if _id else None
        self.user_id = ObjectId(user_id) if user_id else None
        self.title = title
        self.content = content
        self.tags = tags or []
        self.replies = replies or [] # List of Reply objects
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = updated_at or datetime.utcnow()

    def to_dict(self):
        return {
            "_id": str(self._id) if self._id else None,
            "user_id": str(self.user_id) if self.user_id else None,
            "title": self.title,
            "content": self.content,
            "tags": self.tags,
            "replies": [r.to_dict() if hasattr(r, 'to_dict') else r for r in self.replies],
            "created_at": self.created_at.isoformat() if isinstance(self.created_at, datetime) else self.created_at,
            "updated_at": self.updated_at.isoformat() if isinstance(self.updated_at, datetime) else self.updated_at
        }

    def to_mongo(self):
        data = {
            "user_id": self.user_id,
            "title": self.title,
            "content": self.content,
            "tags": self.tags,
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
            _id=data.get('_id'),
            created_at=data.get('created_at'),
            updated_at=data.get('updated_at')
        )

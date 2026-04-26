from datetime import datetime
from bson import ObjectId

class Alert:
    def __init__(self, user_id, parcel_id, type_msg, message, severity='info', read=False, _id=None, created_at=None):
        self._id = ObjectId(_id) if _id else None
        self.user_id = ObjectId(user_id) if user_id else None
        self.parcel_id = ObjectId(parcel_id) if parcel_id else None
        self.type = type_msg # weather | disease_risk | harvest | system
        self.message = message
        self.severity = severity # info | warning | critical
        self.read = read
        self.created_at = created_at or datetime.utcnow()

    def to_dict(self):
        return {
            "_id": str(self._id) if self._id else None,
            "user_id": str(self.user_id) if self.user_id else None,
            "parcel_id": str(self.parcel_id) if self.parcel_id else None,
            "type": self.type,
            "message": self.message,
            "severity": self.severity,
            "read": self.read,
            "created_at": self.created_at.isoformat() if isinstance(self.created_at, datetime) else self.created_at
        }

    def to_mongo(self):
        data = {
            "user_id": self.user_id,
            "parcel_id": self.parcel_id,
            "type": self.type,
            "message": self.message,
            "severity": self.severity,
            "read": self.read,
            "created_at": self.created_at
        }
        if self._id:
            data["_id"] = self._id
        return data

    @staticmethod
    def from_mongo(data):
        if not data:
            return None
        return Alert(
            user_id=data.get('user_id'),
            parcel_id=data.get('parcel_id'),
            type_msg=data.get('type'),
            message=data.get('message'),
            severity=data.get('severity'),
            read=data.get('read', False),
            _id=data.get('_id'),
            created_at=data.get('created_at')
        )

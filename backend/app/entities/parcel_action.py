from datetime import datetime
from bson import ObjectId


ACTION_TYPES = ["fertilizer", "pesticide", "irrigation", "harvest", "seeding", "tillage", "other"]


class ParcelAction:
    def __init__(self, user_id, parcel_id, action_type, date=None,
                 product_name=None, quantity=None, unit=None, notes=None,
                 _id=None, created_at=None):
        self._id = ObjectId(_id) if _id else None
        self.user_id = ObjectId(user_id) if user_id else None
        self.parcel_id = ObjectId(parcel_id) if parcel_id else None
        self.action_type = action_type
        self.date = date or datetime.utcnow()
        self.product_name = product_name
        self.quantity = quantity
        self.unit = unit
        self.notes = notes
        self.created_at = created_at or datetime.utcnow()

    def to_mongo(self):
        data = {
            "user_id": self.user_id,
            "parcel_id": self.parcel_id,
            "action_type": self.action_type,
            "date": self.date,
            "product_name": self.product_name,
            "quantity": self.quantity,
            "unit": self.unit,
            "notes": self.notes,
            "created_at": self.created_at,
        }
        if self._id:
            data["_id"] = self._id
        return data

    @staticmethod
    def from_mongo(data):
        if not data:
            return None
        return ParcelAction(
            user_id=data.get("user_id"),
            parcel_id=data.get("parcel_id"),
            action_type=data.get("action_type"),
            date=data.get("date"),
            product_name=data.get("product_name"),
            quantity=data.get("quantity"),
            unit=data.get("unit"),
            notes=data.get("notes"),
            _id=data.get("_id"),
            created_at=data.get("created_at"),
        )

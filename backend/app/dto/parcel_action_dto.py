from datetime import datetime
from ..entities.parcel_action import ACTION_TYPES


class CreateActionRequest:
    def __init__(self, data: dict):
        self.action_type = data.get('action_type')
        self.product_name = data.get('product_name')
        self.quantity = data.get('quantity')
        self.unit = data.get('unit')
        self.notes = data.get('notes')
        self.date_str = data.get('date')

    def validate(self):
        if not self.action_type or self.action_type not in ACTION_TYPES:
            return f"action_type requis parmi {ACTION_TYPES}"
        return None

    def parse_date(self):
        if self.date_str:
            try:
                return datetime.fromisoformat(self.date_str.replace("Z", "+00:00"))
            except ValueError:
                pass
        return datetime.utcnow()


class ParcelActionResponse:
    @staticmethod
    def from_entity(action):
        return {
            "_id": str(action._id) if action._id else None,
            "user_id": str(action.user_id) if action.user_id else None,
            "parcel_id": str(action.parcel_id) if action.parcel_id else None,
            "action_type": action.action_type,
            "date": action.date.isoformat() if isinstance(action.date, datetime) else action.date,
            "product_name": action.product_name,
            "quantity": action.quantity,
            "unit": action.unit,
            "notes": action.notes,
            "created_at": action.created_at.isoformat() if isinstance(action.created_at, datetime) else action.created_at,
        }

    @staticmethod
    def from_entity_list(actions):
        return [ParcelActionResponse.from_entity(a) for a in actions]

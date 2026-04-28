from datetime import datetime


class WeatherAlertRequest:
    def __init__(self, data: dict):
        self.lat = data.get('lat')
        self.lng = data.get('lng')
        self.culture_type = data.get('culture_type', 'default')
        self.days = min(max(int(data.get('days', 7)), 1), 14)

    def validate(self):
        if self.lat is None or self.lng is None:
            return "lat et lng sont requis"
        return None


class AlertResponse:
    @staticmethod
    def from_entity(alert):
        return {
            "_id": str(alert._id) if alert._id else None,
            "user_id": str(alert.user_id) if alert.user_id else None,
            "parcel_id": str(alert.parcel_id) if alert.parcel_id else None,
            "type": alert.type,
            "message": alert.message,
            "severity": alert.severity,
            "read": alert.read,
            "created_at": alert.created_at.isoformat() if isinstance(alert.created_at, datetime) else alert.created_at,
        }

    @staticmethod
    def from_entity_list(alerts):
        return [AlertResponse.from_entity(a) for a in alerts]

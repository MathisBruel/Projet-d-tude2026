from datetime import datetime
from bson import ObjectId

class Parcel:
    def __init__(self, user_id, name, culture_type=None, area_ha=None, coordinates=None, center=None, soil_type=None, region=None, _id=None, created_at=None, updated_at=None):
        self._id = ObjectId(_id) if _id else None
        self.user_id = ObjectId(user_id) if user_id else None
        self.name = name
        self.culture_type = culture_type
        self.area_ha = area_ha
        self.coordinates = coordinates or [] # GeoJSON Polygon coordinates or list of points
        self.center = center or {"type": "Point", "coordinates": [0, 0]} # {type: "Point", coordinates: [lng, lat]}
        self.soil_type = soil_type
        self.region = region
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = updated_at or datetime.utcnow()

    def to_dict(self):
        return {
            "_id": str(self._id) if self._id else None,
            "user_id": str(self.user_id) if self.user_id else None,
            "name": self.name,
            "culture_type": self.culture_type,
            "area_ha": self.area_ha,
            "coordinates": self.coordinates,
            "center": self.center,
            "soil_type": self.soil_type,
            "region": self.region,
            "created_at": self.created_at.isoformat() if isinstance(self.created_at, datetime) else self.created_at,
            "updated_at": self.updated_at.isoformat() if isinstance(self.updated_at, datetime) else self.updated_at
        }

    def to_mongo(self):
        data = {
            "user_id": self.user_id,
            "name": self.name,
            "culture_type": self.culture_type,
            "area_ha": self.area_ha,
            "coordinates": self.coordinates,
            "center": self.center,
            "soil_type": self.soil_type,
            "region": self.region,
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
        return Parcel(
            user_id=data.get('user_id'),
            name=data.get('name'),
            culture_type=data.get('culture_type'),
            area_ha=data.get('area_ha'),
            coordinates=data.get('coordinates'),
            center=data.get('center'),
            soil_type=data.get('soil_type'),
            region=data.get('region'),
            _id=data.get('_id'),
            created_at=data.get('created_at'),
            updated_at=data.get('updated_at')
        )

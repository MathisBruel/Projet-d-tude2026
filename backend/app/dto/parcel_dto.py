from datetime import datetime


class CreateParcelRequest:
    def __init__(self, data: dict):
        self.name = data.get('name')
        self.culture_type = data.get('culture_type')
        self.coordinates = data.get('coordinates', [])
        self.soil_type = data.get('soil_type')
        self.region = data.get('region')

    def validate(self):
        if not self.name:
            return "Le nom de la parcelle est requis"
        if not self.coordinates:
            return "Les coordonnées sont requises"
        return None


class UpdateParcelRequest:
    def __init__(self, data: dict):
        self.name = data.get('name')
        self.culture_type = data.get('culture_type')
        self.coordinates = data.get('coordinates')
        self.soil_type = data.get('soil_type')
        self.region = data.get('region')

    def to_update_dict(self):
        update = {}
        if self.name is not None:
            update['name'] = self.name
        if self.culture_type is not None:
            update['culture_type'] = self.culture_type
        if self.soil_type is not None:
            update['soil_type'] = self.soil_type
        if self.region is not None:
            update['region'] = self.region
        if self.coordinates is not None:
            update['coordinates'] = self.coordinates
        return update


class ParcelResponse:
    @staticmethod
    def from_entity(parcel):
        return {
            "_id": str(parcel._id) if parcel._id else None,
            "user_id": str(parcel.user_id) if parcel.user_id else None,
            "name": parcel.name,
            "culture_type": parcel.culture_type,
            "area_ha": parcel.area_ha,
            "coordinates": parcel.coordinates,
            "center": parcel.center,
            "soil_type": parcel.soil_type,
            "region": parcel.region,
            "created_at": parcel.created_at.isoformat() if isinstance(parcel.created_at, datetime) else parcel.created_at,
            "updated_at": parcel.updated_at.isoformat() if isinstance(parcel.updated_at, datetime) else parcel.updated_at,
        }

    @staticmethod
    def from_entity_list(parcels):
        return [ParcelResponse.from_entity(p) for p in parcels]

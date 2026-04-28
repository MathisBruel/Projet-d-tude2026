import math
from datetime import datetime
from bson import ObjectId
from ..data_access.parcel_repository import ParcelRepository
from ..entities.parcel import Parcel
from ..dto.parcel_dto import CreateParcelRequest, UpdateParcelRequest, ParcelResponse


def calculate_area_ha(coordinates):
    if not coordinates or len(coordinates) < 3:
        return 0.0

    points = []
    for coord in coordinates:
        if isinstance(coord, dict):
            points.append((coord.get('lat'), coord.get('lng')))
        elif isinstance(coord, (list, tuple)):
            points.append((coord[0], coord[1]))

    if len(points) < 3:
        return 0.0

    area = 0.0
    n = len(points)
    for i in range(n):
        j = (i + 1) % n
        area += points[i][1] * points[j][0]
        area -= points[j][1] * points[i][0]
    area = abs(area) / 2.0

    avg_lat = sum(p[0] for p in points) / n
    lat_km_per_degree = 111.0
    lng_km_per_degree = 111.0 * abs(math.cos(math.radians(avg_lat)))

    sq_km = area * lat_km_per_degree * lng_km_per_degree
    hectares = sq_km * 100
    return round(hectares, 2)


def get_parcels(user_id):
    parcels = ParcelRepository.find_by_user(user_id)
    return ParcelResponse.from_entity_list(parcels)


def create_parcel(user_id, dto: CreateParcelRequest):
    area_ha = calculate_area_ha(dto.coordinates)

    new_parcel = Parcel(
        user_id=ObjectId(user_id),
        name=dto.name,
        culture_type=dto.culture_type,
        area_ha=area_ha,
        coordinates=dto.coordinates,
        soil_type=dto.soil_type,
        region=dto.region,
    )

    inserted_id = ParcelRepository.insert(new_parcel)
    new_parcel._id = inserted_id
    return ParcelResponse.from_entity(new_parcel)


def get_parcel(parcel_id, user_id):
    parcel = ParcelRepository.find_one(parcel_id, user_id)
    if not parcel:
        return None
    return ParcelResponse.from_entity(parcel)


def update_parcel(parcel_id, user_id, dto: UpdateParcelRequest):
    existing = ParcelRepository.find_one(parcel_id, user_id)
    if not existing:
        return None

    update_data = dto.to_update_dict()
    if 'coordinates' in update_data:
        update_data['area_ha'] = calculate_area_ha(update_data['coordinates'])

    ParcelRepository.update(parcel_id, update_data)

    updated = ParcelRepository.find_one(parcel_id, user_id)
    return ParcelResponse.from_entity(updated)


def delete_parcel(parcel_id, user_id):
    return ParcelRepository.delete(parcel_id, user_id)

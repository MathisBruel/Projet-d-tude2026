from bson import ObjectId
from ..data_access.parcel_action_repository import ParcelActionRepository
from ..data_access.parcel_repository import ParcelRepository
from ..entities.parcel_action import ParcelAction
from ..dto.parcel_action_dto import CreateActionRequest, ParcelActionResponse


def create_action(user_id, parcel_id, dto: CreateActionRequest):
    parcel = ParcelRepository.find_one_raw(parcel_id, user_id)
    if not parcel:
        return None

    action = ParcelAction(
        user_id=user_id,
        parcel_id=parcel_id,
        action_type=dto.action_type,
        date=dto.parse_date(),
        product_name=dto.product_name,
        quantity=dto.quantity,
        unit=dto.unit,
        notes=dto.notes,
    )

    inserted_id = ParcelActionRepository.insert(action)
    action._id = inserted_id
    return ParcelActionResponse.from_entity(action)


def list_actions(user_id, parcel_id, days=90, limit=50):
    parcel = ParcelRepository.find_one_raw(parcel_id, user_id)
    if not parcel:
        return None

    actions = ParcelActionRepository.find_by_parcel(parcel_id, days=days, limit=limit)
    return ParcelActionResponse.from_entity_list(actions)


def delete_action(action_id, parcel_id, user_id):
    return ParcelActionRepository.delete(action_id, parcel_id, user_id)

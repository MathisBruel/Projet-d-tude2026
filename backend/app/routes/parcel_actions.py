from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime, timedelta
from ..database import get_db
from ..models.parcel_action import ParcelAction, ACTION_TYPES
from ..utils.auth_utils import jwt_required

parcel_actions_bp = Blueprint("parcel_actions", __name__)


@parcel_actions_bp.route("/<parcel_id>/actions", methods=["POST"])
@jwt_required
def create_action(parcel_id):
    """
    Enregistre une action agricole sur une parcelle.

    Body JSON requis :
        action_type (str) — fertilizer | pesticide | irrigation | harvest | seeding | tillage | other

    Body JSON optionnel :
        product_name (str)  — ex: "Ammonitrate 33.5%"
        quantity     (float) — quantité appliquée
        unit         (str)   — kg, L, mm, unités...
        date         (str)   — ISO 8601, défaut = maintenant
        notes        (str)   — observations libres
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    action_type = data.get("action_type")
    if not action_type or action_type not in ACTION_TYPES:
        return jsonify({"error": f"action_type requis parmi {ACTION_TYPES}"}), 400

    db = get_db()
    user_id = ObjectId(request.user_id)

    # Vérifier que la parcelle appartient à l'utilisateur
    parcel = db.parcels.find_one({"_id": ObjectId(parcel_id), "user_id": user_id})
    if not parcel:
        return jsonify({"error": "Parcelle non trouvée"}), 404

    action_date = datetime.utcnow()
    if data.get("date"):
        try:
            action_date = datetime.fromisoformat(data["date"].replace("Z", "+00:00"))
        except ValueError:
            pass

    action = ParcelAction(
        user_id=request.user_id,
        parcel_id=parcel_id,
        action_type=action_type,
        date=action_date,
        product_name=data.get("product_name"),
        quantity=data.get("quantity"),
        unit=data.get("unit"),
        notes=data.get("notes"),
    )

    result = db.parcel_actions.insert_one(action.to_mongo())

    action._id = result.inserted_id
    return jsonify({"message": "Action enregistrée", "data": action.to_dict()}), 201


@parcel_actions_bp.route("/<parcel_id>/actions", methods=["GET"])
@jwt_required
def list_actions(parcel_id):
    """Liste les actions d'une parcelle (les plus récentes en premier)."""
    db = get_db()
    user_id = ObjectId(request.user_id)

    parcel = db.parcels.find_one({"_id": ObjectId(parcel_id), "user_id": user_id})
    if not parcel:
        return jsonify({"error": "Parcelle non trouvée"}), 404

    limit = min(int(request.args.get("limit", 50)), 200)
    days = int(request.args.get("days", 90))

    since = datetime.utcnow() - timedelta(days=days)

    cursor = db.parcel_actions.find(
        {"parcel_id": ObjectId(parcel_id), "date": {"$gte": since}},
        sort=[("date", -1)],
        limit=limit,
    )

    actions = [ParcelAction.from_mongo(doc).to_dict() for doc in cursor]
    return jsonify({"data": {"actions": actions, "count": len(actions)}}), 200


@parcel_actions_bp.route("/<parcel_id>/actions/<action_id>", methods=["DELETE"])
@jwt_required
def delete_action(parcel_id, action_id):
    """Supprime une action."""
    db = get_db()
    user_id = ObjectId(request.user_id)

    result = db.parcel_actions.delete_one({
        "_id": ObjectId(action_id),
        "parcel_id": ObjectId(parcel_id),
        "user_id": user_id,
    })

    if result.deleted_count == 0:
        return jsonify({"error": "Action non trouvée"}), 404

    return jsonify({"message": "Action supprimée"}), 200

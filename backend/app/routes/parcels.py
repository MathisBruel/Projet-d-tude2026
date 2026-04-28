from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime
from ..database import get_db
from ..models.parcel import Parcel
from ..utils.auth_utils import jwt_required

parcels_bp = Blueprint('parcels', __name__)

def calculate_area_ha(coordinates):
    """
    Calcule l'aire d'un polygone en hectares using the Shoelace formula.
    Assume coordinates are [[lat, lng], ...] and approximates in hectares.
    """
    if not coordinates or len(coordinates) < 3:
        return 0.0

    # Convert to (lat, lng) tuples if they're dicts
    points = []
    for coord in coordinates:
        if isinstance(coord, dict):
            points.append((coord.get('lat'), coord.get('lng')))
        elif isinstance(coord, (list, tuple)):
            points.append((coord[0], coord[1]))
        else:
            continue

    if len(points) < 3:
        return 0.0

    # Shoelace formula in degrees, then approximate to hectares
    area = 0.0
    n = len(points)
    for i in range(n):
        j = (i + 1) % n
        area += points[i][1] * points[j][0]
        area -= points[j][1] * points[i][0]

    area = abs(area) / 2.0

    # Approximate hectares: 1 degree lat ≈ 111 km, 1 degree lng varies with latitude
    # Rough approximation: 1 sq degree ≈ 12000 sq km ≈ 1.2M hectares
    # For small parcels in France (lat ~47), use simpler approximation
    avg_lat = sum(p[0] for p in points) / n
    lat_km_per_degree = 111.0
    lng_km_per_degree = 111.0 * abs(__import__('math').cos(__import__('math').radians(avg_lat)))

    sq_km = area * lat_km_per_degree * lng_km_per_degree
    hectares = sq_km * 100  # 1 sq km = 100 ha

    return round(hectares, 2)


@parcels_bp.route('', methods=['GET'])
@jwt_required
def get_parcels():
    """Récupère toutes les parcelles de l'utilisateur connecté"""
    db = get_db()
    user_id = ObjectId(request.user_id)

    parcels_data = list(db.parcels.find({"user_id": user_id}))
    parcels = [Parcel.from_mongo(p).to_dict() for p in parcels_data]

    return jsonify({"data": parcels}), 200


@parcels_bp.route('', methods=['POST'])
@jwt_required
def create_parcel():
    """Crée une nouvelle parcelle"""
    data = request.get_json()
    db = get_db()

    if not data or not data.get('name'):
        return jsonify({"error": "Le nom de la parcelle est requis"}), 400

    if not data.get('coordinates'):
        return jsonify({"error": "Les coordonnées sont requises"}), 400

    try:
        coordinates = data.get('coordinates', [])
        area_ha = calculate_area_ha(coordinates)

        new_parcel = Parcel(
            user_id=ObjectId(request.user_id),
            name=data['name'],
            culture_type=data.get('culture_type'),
            area_ha=area_ha,
            coordinates=coordinates,
            soil_type=data.get('soil_type'),
            region=data.get('region')
        )

        result = db.parcels.insert_one(new_parcel.to_mongo())
        new_parcel._id = result.inserted_id

        return jsonify({
            "message": "Parcelle créée avec succès",
            "data": new_parcel.to_dict()
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@parcels_bp.route('/<parcel_id>', methods=['GET'])
@jwt_required
def get_parcel(parcel_id):
    """Récupère les détails d'une parcelle (vérification d'ownership)"""
    db = get_db()
    user_id = ObjectId(request.user_id)

    try:
        parcel_data = db.parcels.find_one({
            "_id": ObjectId(parcel_id),
            "user_id": user_id
        })

        if not parcel_data:
            return jsonify({"error": "Parcelle non trouvée"}), 404

        parcel = Parcel.from_mongo(parcel_data)
        return jsonify({"data": parcel.to_dict()}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 400


@parcels_bp.route('/<parcel_id>', methods=['PUT'])
@jwt_required
def update_parcel(parcel_id):
    """Modifie une parcelle existante"""
    db = get_db()
    user_id = ObjectId(request.user_id)
    data = request.get_json()

    try:
        parcel_data = db.parcels.find_one({
            "_id": ObjectId(parcel_id),
            "user_id": user_id
        })

        if not parcel_data:
            return jsonify({"error": "Parcelle non trouvée"}), 404

        # Mettre à jour les champs autorisés
        update_data = {}
        if 'name' in data:
            update_data['name'] = data['name']
        if 'culture_type' in data:
            update_data['culture_type'] = data['culture_type']
        if 'soil_type' in data:
            update_data['soil_type'] = data['soil_type']
        if 'region' in data:
            update_data['region'] = data['region']
        if 'coordinates' in data:
            update_data['coordinates'] = data['coordinates']
            # Recalculer l'aire si les coordonnées changent
            update_data['area_ha'] = calculate_area_ha(data['coordinates'])

        update_data['updated_at'] = datetime.utcnow()

        db.parcels.update_one(
            {"_id": ObjectId(parcel_id)},
            {"$set": update_data}
        )

        # Récupérer la parcelle mise à jour
        updated_data = db.parcels.find_one({"_id": ObjectId(parcel_id)})
        parcel = Parcel.from_mongo(updated_data)

        return jsonify({
            "message": "Parcelle mise à jour avec succès",
            "data": parcel.to_dict()
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 400


@parcels_bp.route('/<parcel_id>', methods=['DELETE'])
@jwt_required
def delete_parcel(parcel_id):
    """Supprime une parcelle"""
    db = get_db()
    user_id = ObjectId(request.user_id)

    try:
        result = db.parcels.delete_one({
            "_id": ObjectId(parcel_id),
            "user_id": user_id
        })

        if result.deleted_count == 0:
            return jsonify({"error": "Parcelle non trouvée"}), 404

        return jsonify({"message": "Parcelle supprimée avec succès"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 400

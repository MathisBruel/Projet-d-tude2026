import os
from pymongo import MongoClient, ASCENDING, GEOSPHERE
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

MONGO_URI = os.getenv('MONGO_URI', 'mongodb://localhost:27017/agrisense')
DB_NAME = MONGO_URI.split('/')[-1].split('?')[0] or 'agrisense'

client = MongoClient(MONGO_URI)
db = client[DB_NAME]

def setup_users():
    collection_name = "users"
    validator = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["email", "password_hash", "role", "created_at"],
            "properties": {
                "email": {
                    "bsonType": "string",
                    "description": "doit être un string et est requis"
                },
                "password_hash": {
                    "bsonType": "string",
                    "description": "doit être un string et est requis"
                },
                "role": {
                    "enum": ["farmer", "agronomist", "admin"],
                    "description": "doit être l'un des rôles définis"
                },
                "first_name": {"bsonType": "string"},
                "last_name": {"bsonType": "string"},
                "phone": {"bsonType": "string"},
                "created_at": {"bsonType": "date"},
                "updated_at": {"bsonType": "date"}
            }
        }
    }
    
    if collection_name not in db.list_collection_names():
        db.create_collection(collection_name, validator=validator)
    else:
        db.command("collMod", collection_name, validator=validator)
    
    db[collection_name].create_index([("email", ASCENDING)], unique=True)
    db[collection_name].create_index([("role", ASCENDING)])
    print(f"Collection {collection_name} configurée.")

def setup_parcels():
    collection_name = "parcels"
    validator = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["user_id", "name", "created_at"],
            "properties": {
                "user_id": {"bsonType": "objectId"},
                "name": {"bsonType": "string"},
                "culture_type": {"bsonType": "string"},
                "area_ha": {"bsonType": "double"},
                "location": {
                    "bsonType": "object",
                    "required": ["type", "coordinates"],
                    "properties": {
                        "type": {"enum": ["Point", "Polygon"]},
                        "coordinates": {"bsonType": "array"}
                    }
                },
                "center": {
                    "bsonType": "object",
                    "required": ["type", "coordinates"],
                    "properties": {
                        "type": {"enum": ["Point"]},
                        "coordinates": {"bsonType": "array"}
                    }
                },
                "soil_type": {"bsonType": "string"},
                "region": {"bsonType": "string"},
                "created_at": {"bsonType": "date"},
                "updated_at": {"bsonType": "date"}
            }
        }
    }
    
    if collection_name not in db.list_collection_names():
        db.create_collection(collection_name, validator=validator)
    else:
        db.command("collMod", collection_name, validator=validator)
    
    db[collection_name].create_index([("user_id", ASCENDING)])
    db[collection_name].create_index([("center", GEOSPHERE)])
    db[collection_name].create_index([("culture_type", ASCENDING)])
    print(f"Collection {collection_name} configurée.")

def setup_predictions():
    collection_name = "predictions"
    validator = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["parcel_id", "user_id", "requested_at"],
            "properties": {
                "parcel_id": {"bsonType": "objectId"},
                "user_id": {"bsonType": "objectId"},
                "requested_at": {"bsonType": "date"},
                "weather_temp_avg": {"bsonType": "double"},
                "weather_precip_mm": {"bsonType": "double"},
                "predicted_yield_t_ha": {"bsonType": "double"},
                "confidence_pct": {"bsonType": "int"},
                "recommendations": {
                    "bsonType": "array",
                    "items": {"bsonType": "string"}
                }
            }
        }
    }
    
    if collection_name not in db.list_collection_names():
        db.create_collection(collection_name, validator=validator)
    else:
        db.command("collMod", collection_name, validator=validator)
    
    db[collection_name].create_index([("parcel_id", ASCENDING), ("requested_at", ASCENDING)])
    db[collection_name].create_index([("user_id", ASCENDING)])
    # Index TTL : expiration après 365 jours
    db[collection_name].create_index([("requested_at", ASCENDING)], expireAfterSeconds=365*24*60*60)
    print(f"Collection {collection_name} configurée.")

def setup_alerts():
    collection_name = "alerts"
    validator = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["user_id", "parcel_id", "type", "severity", "created_at"],
            "properties": {
                "user_id": {"bsonType": "objectId"},
                "parcel_id": {"bsonType": "objectId"},
                "type": {"enum": ["weather", "disease_risk", "harvest", "system"]},
                "severity": {"enum": ["info", "warning", "critical"]},
                "message": {"bsonType": "string"},
                "read": {"bsonType": "bool"},
                "created_at": {"bsonType": "date"}
            }
        }
    }
    
    if collection_name not in db.list_collection_names():
        db.create_collection(collection_name, validator=validator)
    else:
        db.command("collMod", collection_name, validator=validator)
    
    db[collection_name].create_index([("user_id", ASCENDING)])
    db[collection_name].create_index([("parcel_id", ASCENDING)])
    db[collection_name].create_index([("created_at", ASCENDING)])
    print(f"Collection {collection_name} configurée.")

def setup_forum():
    collection_name = "posts"
    validator = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["user_id", "title", "created_at"],
            "properties": {
                "user_id": {"bsonType": "objectId"},
                "title": {"bsonType": "string"},
                "content": {"bsonType": "string"},
                "tags": {
                    "bsonType": "array",
                    "items": {"bsonType": "string"}
                },
                "replies": {
                    "bsonType": "array",
                    "items": {
                        "bsonType": "object",
                        "required": ["user_id", "content", "created_at"],
                        "properties": {
                            "user_id": {"bsonType": "objectId"},
                            "content": {"bsonType": "string"},
                            "created_at": {"bsonType": "date"}
                        }
                    }
                },
                "created_at": {"bsonType": "date"},
                "updated_at": {"bsonType": "date"}
            }
        }
    }
    
    if collection_name not in db.list_collection_names():
        db.create_collection(collection_name, validator=validator)
    else:
        db.command("collMod", collection_name, validator=validator)
    
    db[collection_name].create_index([("user_id", ASCENDING)])
    db[collection_name].create_index([("created_at", ASCENDING)])
    db[collection_name].create_index([("tags", ASCENDING)])
    print(f"Collection {collection_name} configurée.")

if __name__ == "__main__":
    print(f"Initialisation de la base de données : {DB_NAME}")
    setup_users()
    setup_parcels()
    setup_predictions()
    setup_alerts()
    setup_forum()
    print("Migration terminée avec succès.")

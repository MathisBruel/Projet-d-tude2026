from pymongo import ASCENDING, GEOSPHERE
import click
from flask.cli import with_appcontext
from .database import get_db

def setup_collection(db, name, validator):
    if name not in db.list_collection_names():
        db.create_collection(name, validator=validator)
    else:
        db.command("collMod", name, validator=validator)

def run_migrations():
    db = get_db()
    
    # Validation Schémas
    users_schema = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["email", "password_hash", "role", "created_at"],
            "properties": {
                "email": {"bsonType": "string"},
                "password_hash": {"bsonType": "string"},
                "role": {"enum": ["farmer", "agronomist", "admin"]},
                "created_at": {"bsonType": "date"}
            }
        }
    }
    
    setup_collection(db, "users", users_schema)
    db.users.create_index([("email", ASCENDING)], unique=True)
    
    parcels_schema = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["user_id", "name", "created_at"],
            "properties": {
                "user_id": {"bsonType": "objectId"},
                "name": {"bsonType": "string"},
                "center": {"bsonType": "object"}
            }
        }
    }
    
    setup_collection(db, "parcels", parcels_schema)
    db.parcels.create_index([("center", GEOSPHERE)])
    
    setup_collection(db, "predictions", {"$jsonSchema": {"bsonType": "object", "required": ["requested_at"]}})
    db.predictions.create_index([("requested_at", ASCENDING)], expireAfterSeconds=365*24*60*60)
    
    setup_collection(db, "posts", {"$jsonSchema": {"bsonType": "object", "required": ["user_id", "title"]}})
    
    return True

@click.command('init-db')
@with_appcontext
def init_db_command():
    """Initialise la base de données (Validation + Index)."""
    if run_migrations():
        click.echo('Base de données initialisée avec succès.')
    else:
        click.echo('Erreur lors de l\'initialisation.')

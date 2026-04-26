from pymongo import MongoClient
from flask import current_app, g

def get_db():
    if 'db' not in g:
        client = MongoClient(current_app.config['MONGO_URI'])
        db_name = current_app.config['MONGO_URI'].split('/')[-1].split('?')[0] or 'agrisense'
        g.db = client[db_name]
    return g.db

def close_db(e=None):
    db = g.pop('db', None)
    if db is not None:
        db.client.close()

from flask import Flask
from flask_cors import CORS
from .config import Config
from .database import close_db
from .commands import init_db_command


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    CORS(app)

    from .routes.health import health_bp
    from .routes.auth import auth_bp
    from .routes.parcels import parcels_bp
    app.register_blueprint(health_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(parcels_bp, url_prefix='/api/v1/parcels')

    app.teardown_appcontext(close_db)
    app.cli.add_command(init_db_command)

    return app

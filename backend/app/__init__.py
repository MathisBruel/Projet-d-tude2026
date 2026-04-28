from flask import Flask, send_from_directory
import os
from flask_cors import CORS
from .config import Config
from .database import close_db
from .commands import init_db_command


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    app.config['UPLOAD_FOLDER'] = os.path.join(app.root_path, '..', 'uploads')
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    CORS(app)

    from .controllers.health_controller import health_bp
    from .controllers.auth_controller import auth_bp
    from .controllers.parcel_controller import parcels_bp
    from .controllers.community_controller import community_bp
    from .controllers.profile_controller import profile_bp
    from .controllers.prediction_controller import predictions_bp
    from .controllers.alert_controller import alerts_bp
    from .controllers.weather_controller import weather_bp
    from .controllers.parcel_action_controller import parcel_actions_bp
    from .controllers.tips_controller import tips_bp

    app.register_blueprint(health_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(parcels_bp, url_prefix='/api/v1/parcels')
    app.register_blueprint(community_bp)
    app.register_blueprint(profile_bp)
    app.register_blueprint(predictions_bp, url_prefix='/api/v1/predictions')
    app.register_blueprint(alerts_bp, url_prefix='/api/v1/alerts')
    app.register_blueprint(weather_bp)
    app.register_blueprint(parcel_actions_bp, url_prefix='/api/v1/parcels')
    app.register_blueprint(tips_bp, url_prefix='/api/v1/parcels')

    app.teardown_appcontext(close_db)
    app.cli.add_command(init_db_command)

    @app.route('/uploads/<path:filename>')
    def serve_upload(filename):
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

    return app

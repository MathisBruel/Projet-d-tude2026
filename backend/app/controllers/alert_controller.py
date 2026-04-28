from flask import Blueprint, request, jsonify
from ..dto.alert_dto import WeatherAlertRequest
from ..services import alert_service
from ..services.auth_service import jwt_required

alerts_bp = Blueprint("alerts", __name__)


@alerts_bp.route("/weather", methods=["POST"])
@jwt_required
def weather_alerts():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    dto = WeatherAlertRequest(data)
    error = dto.validate()
    if error:
        return jsonify({"error": error}), 400

    try:
        result = alert_service.generate_weather_alerts(dto.lat, dto.lng, dto.culture_type, dto.days)
        return jsonify({"data": result}), 200
    except Exception as exc:
        return jsonify({"error": f"Open-Meteo indisponible : {exc}"}), 503


@alerts_bp.route("/scan", methods=["POST"])
@jwt_required
def scan_all_parcels():
    total = alert_service.scan_all_parcels(request.user_id)
    return jsonify({"data": {"alerts_created": total}}), 200


@alerts_bp.route("", methods=["GET"])
@jwt_required
def list_alerts():
    limit = min(int(request.args.get("limit", 30)), 100)
    unread_only = request.args.get("unread") == "true"
    result = alert_service.list_alerts(request.user_id, limit=limit, unread_only=unread_only)
    return jsonify({"data": result}), 200


@alerts_bp.route("/<alert_id>/read", methods=["POST"])
@jwt_required
def mark_read(alert_id):
    matched = alert_service.mark_read(alert_id, request.user_id)
    if matched == 0:
        return jsonify({"error": "Alerte non trouvée"}), 404
    return jsonify({"message": "Alerte marquée comme lue"}), 200


@alerts_bp.route("/read-all", methods=["POST"])
@jwt_required
def mark_all_read():
    count = alert_service.mark_all_read(request.user_id)
    return jsonify({"data": {"marked_count": count}}), 200

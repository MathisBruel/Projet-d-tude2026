from flask import Blueprint, request, jsonify
from ..dto.prediction_dto import PredictRequest
from ..services import prediction_service
from ..services.auth_service import jwt_required

predictions_bp = Blueprint("predictions", __name__)


@predictions_bp.route("/predict", methods=["POST"])
@jwt_required
def predict():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    dto = PredictRequest(data)
    error = dto.validate()
    if error:
        return jsonify({"error": error}), 400

    try:
        result = prediction_service.predict(request.user_id, dto)
        return jsonify({"data": result}), 200
    except RuntimeError as e:
        return jsonify({"error": str(e)}), 503
    except Exception as e:
        return jsonify({"error": f"Erreur modèle ML : {e}"}), 500


@predictions_bp.route("/history", methods=["GET"])
@jwt_required
def history():
    limit = min(int(request.args.get("limit", 20)), 100)
    items = prediction_service.get_history(request.user_id, limit=limit)
    return jsonify({"data": {"predictions": items, "count": len(items)}}), 200


@predictions_bp.route("/crops", methods=["GET"])
def list_crops():
    try:
        crops = prediction_service.list_crops()
        return jsonify({"data": {"crops": crops}}), 200
    except RuntimeError as e:
        return jsonify({"error": str(e)}), 503

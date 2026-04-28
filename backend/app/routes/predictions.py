from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime
from ..database import get_db
from ..utils.auth_utils import jwt_required
from ..services import weather_service, ml_service

predictions_bp = Blueprint("predictions", __name__)


@predictions_bp.route("/predict", methods=["POST"])
@jwt_required
def predict():
    """
    Prédit le rendement d'une parcelle.

    Body JSON requis :
        lat          (float)  — latitude GPS
        lng          (float)  — longitude GPS
        culture_type (str)    — ex: "Wheat", "Maize", "Potatoes"

    Body JSON optionnel :
        parcel_id         (str)   — id MongoDB de la parcelle
        pesticides_tonnes (float) — si absent, valeur moyenne mondiale utilisée
        rainfall_mm       (float) — fallback si Open-Meteo échoue
        avg_temp_c        (float) — fallback si Open-Meteo échoue
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    lat          = data.get("lat")
    lng          = data.get("lng")
    culture_type = data.get("culture_type")

    if lat is None or lng is None or not culture_type:
        return jsonify({"error": "lat, lng et culture_type sont requis"}), 400

    if not ml_service.is_model_ready():
        return jsonify({"error": "Modèle ML non disponible — lance ml/train.py d'abord"}), 503

    # ── Enrichissement météo via Open-Meteo ──────────────────────────────────
    try:
        weather      = weather_service.get_recent_weather_averages(lat, lng)
        rainfall_mm  = weather["rainfall_mm_annual_est"]
        avg_temp_c   = weather["avg_temp_c"]
        weather_src  = "open-meteo"
    except Exception:
        # Fallback sur les valeurs fournies dans le payload ou des defaults
        rainfall_mm  = data.get("rainfall_mm", 600.0)
        avg_temp_c   = data.get("avg_temp_c", 12.0)
        weather_src  = "payload_fallback"

    pesticides = data.get("pesticides_tonnes", 50_000.0)

    # ── Prédiction ML ────────────────────────────────────────────────────────
    try:
        result = ml_service.predict_yield(culture_type, rainfall_mm, avg_temp_c, pesticides)

    except Exception as ml_err:
        # ── FALLBACK GEMINI ──────────────────────────────────────────────────
        # Si le modèle ML échoue, décommenter les lignes ci-dessous
        # et supprimer le return d'erreur.
        #
        # from ..services import gemini_service
        # try:
        #     result = gemini_service.predict_yield(culture_type, rainfall_mm, avg_temp_c)
        # except Exception as gem_err:
        #     return jsonify({"error": f"ML et Gemini ont échoué: {gem_err}"}), 500
        # ────────────────────────────────────────────────────────────────────
        return jsonify({"error": f"Erreur modèle ML : {ml_err}"}), 500

    # ── Persistance MongoDB ──────────────────────────────────────────────────
    db  = get_db()
    doc = {
        "user_id":             ObjectId(request.user_id),
        "parcel_id":           ObjectId(data["parcel_id"]) if data.get("parcel_id") else None,
        "date":                datetime.utcnow(),
        "weather_data": {
            "source":          weather_src,
            "avg_temp_c":      avg_temp_c,
            "rainfall_mm":     rainfall_mm,
        },
        "predicted_yield_t_ha": result["predicted_yield_t_ha"],
        "confidence_pct":       result["confidence_pct"],
        "model":                result["model"],
        "created_at":           datetime.utcnow(),
    }
    inserted = db.predictions.insert_one(doc)

    return jsonify({
        "data": {
            **result,
            "prediction_id": str(inserted.inserted_id),
            "weather_source": weather_src,
            "weather_input": {
                "avg_temp_c":  avg_temp_c,
                "rainfall_mm": rainfall_mm,
            },
        }
    }), 200


@predictions_bp.route("/history", methods=["GET"])
@jwt_required
def history():
    """Récupère l'historique des prédictions de l'utilisateur connecté."""
    db     = get_db()
    limit  = min(int(request.args.get("limit", 20)), 100)
    cursor = db.predictions.find(
        {"user_id": ObjectId(request.user_id)},
        sort=[("created_at", -1)],
        limit=limit,
    )

    items = []
    for doc in cursor:
        doc["_id"]      = str(doc["_id"])
        doc["user_id"]  = str(doc["user_id"])
        if doc.get("parcel_id"):
            doc["parcel_id"] = str(doc["parcel_id"])
        if isinstance(doc.get("date"), datetime):
            doc["date"] = doc["date"].isoformat()
        if isinstance(doc.get("created_at"), datetime):
            doc["created_at"] = doc["created_at"].isoformat()
        items.append(doc)

    return jsonify({"data": {"predictions": items, "count": len(items)}}), 200


@predictions_bp.route("/crops", methods=["GET"])
def list_crops():
    """Liste les cultures supportées par le modèle ML."""
    if not ml_service.is_model_ready():
        return jsonify({"error": "Modèle non disponible"}), 503
    return jsonify({"data": {"crops": ml_service.get_known_crops()}}), 200

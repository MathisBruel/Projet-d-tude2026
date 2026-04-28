from datetime import datetime
from bson import ObjectId
from ..data_access.prediction_repository import PredictionRepository
from ..data_access.parcel_action_repository import ParcelActionRepository
from ..services import weather_service, ml_service, gemini_service
from ..dto.prediction_dto import PredictRequest, PredictionResponse


def predict(user_id, dto: PredictRequest):
    if not ml_service.is_model_ready():
        raise RuntimeError("Modèle ML non disponible — lance ml/train.py d'abord")

    # Enrichissement météo
    try:
        weather = weather_service.get_recent_weather_averages(dto.lat, dto.lng)
        rainfall_mm = weather["rainfall_mm_annual_est"]
        avg_temp_c = weather["avg_temp_c"]
        weather_src = "open-meteo"
    except Exception:
        rainfall_mm = dto.rainfall_mm
        avg_temp_c = dto.avg_temp_c
        weather_src = "payload_fallback"

    # Prédiction ML
    result = ml_service.predict_yield(dto.culture_type, rainfall_mm, avg_temp_c, dto.pesticides_tonnes)

    # Actions récentes pour Gemini
    recent_actions = []
    if dto.parcel_id:
        raw_actions = ParcelActionRepository.find_recent_raw(dto.parcel_id, days=30, limit=5)
        for a in raw_actions:
            recent_actions.append({
                "action_type": a.get("action_type", ""),
                "product_name": a.get("product_name", ""),
                "quantity": a.get("quantity", ""),
                "unit": a.get("unit", ""),
            })

    # Commentaire Gemini
    gemini_comment = ""
    try:
        gemini_comment = gemini_service.generate_prediction_commentary(
            culture_type=dto.culture_type,
            predicted_yield=result["predicted_yield_t_ha"],
            confidence=result["confidence_pct"],
            weather={"avg_temp_c": avg_temp_c, "rainfall_mm": rainfall_mm},
            actions=recent_actions,
        )
    except Exception:
        pass

    # Persistance
    now = datetime.utcnow()
    doc = {
        "user_id": ObjectId(user_id),
        "parcel_id": ObjectId(dto.parcel_id) if dto.parcel_id else None,
        "culture_type": dto.culture_type,
        "date": now,
        "requested_at": now,
        "weather_data": {
            "source": weather_src,
            "avg_temp_c": avg_temp_c,
            "rainfall_mm": rainfall_mm,
        },
        "predicted_yield_t_ha": result["predicted_yield_t_ha"],
        "confidence_pct": result["confidence_pct"],
        "model": result["model"],
        "gemini_comment": gemini_comment,
        "created_at": now,
    }
    inserted_id = PredictionRepository.insert(doc)

    return PredictionResponse.from_result(result, inserted_id, weather_src, avg_temp_c, rainfall_mm, gemini_comment)


def get_history(user_id, limit=20):
    docs = PredictionRepository.find_by_user(user_id, limit=limit)
    return [PredictionResponse.history_item(doc) for doc in docs]


def list_crops():
    if not ml_service.is_model_ready():
        raise RuntimeError("Modèle non disponible")
    return ml_service.get_known_crops()

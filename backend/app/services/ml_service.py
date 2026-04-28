"""
Service de prédiction ML.
Charge le modèle une seule fois (lazy singleton) pour éviter de relire
le fichier à chaque requête.
"""

import os
import logging
import pandas as pd
import joblib

logger = logging.getLogger(__name__)

_ML_DIR    = os.path.join(os.path.dirname(__file__), "..", "..", "ml")
MODEL_PATH = os.path.join(_ML_DIR, "model.pkl")
CROPS_PATH = os.path.join(_ML_DIR, "known_crops.pkl")

_pipeline    = None
_known_crops = None


def _load():
    global _pipeline, _known_crops
    if _pipeline is not None:
        return

    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(
            f"Modèle introuvable : {MODEL_PATH}\n"
            "Lance d'abord : python ml/train.py"
        )

    _pipeline    = joblib.load(MODEL_PATH)
    _known_crops = joblib.load(CROPS_PATH) if os.path.exists(CROPS_PATH) else []
    logger.info("Modèle ML chargé (%d cultures connues)", len(_known_crops))


def predict_yield(
    culture_type: str,
    rainfall_mm: float,
    avg_temp_c: float,
    pesticides_tonnes: float = 50_000.0,
) -> dict:
    """
    Prédit le rendement (t/ha) pour une culture et des conditions météo données.

    Paramètres
    ----------
    culture_type       : nom de la culture (doit correspondre aux valeurs du dataset)
    rainfall_mm        : pluviométrie annuelle estimée (mm)
    avg_temp_c         : température moyenne (°C)
    pesticides_tonnes  : quantité de pesticides (tonnes, valeur monde par défaut)

    Retourne un dict {predicted_yield_t_ha, confidence_pct, model, culture_type}
    """
    _load()

    input_df = pd.DataFrame([{
        "culture_type":      culture_type,
        "rainfall_mm":       float(rainfall_mm),
        "avg_temp_c":        float(avg_temp_c),
        "pesticides_tonnes": float(pesticides_tonnes),
    }])

    raw = float(_pipeline.predict(input_df)[0])
    yield_t_ha = max(0.0, round(raw, 3))

    # Confiance : plus basse si la culture n'est pas dans l'ensemble d'entraînement
    confidence = 82 if culture_type in _known_crops else 55

    return {
        "predicted_yield_t_ha": yield_t_ha,
        "confidence_pct":       confidence,
        "model":                "xgboost_v1",
        "culture_type":         culture_type,
    }


def get_known_crops() -> list[str]:
    _load()
    return list(_known_crops)


def is_model_ready() -> bool:
    return os.path.exists(MODEL_PATH)

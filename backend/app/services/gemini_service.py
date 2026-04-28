"""
Service Gemini — génération de conseils agronomiques et commentaires IA.
Utilise le SDK google-generativeai pour appeler Google AI Studio.
"""

import logging
from flask import current_app
import google.generativeai as genai

logger = logging.getLogger(__name__)

_model = None


def _get_model():
    global _model
    if _model is None:
        api_key = current_app.config.get("GEMINI_KEY") or ""
        if not api_key:
            raise RuntimeError("GEMINI_API_KEY non configurée")
        genai.configure(api_key=api_key)
        _model = genai.GenerativeModel("gemini-2.5-flash")
    return _model


def generate_tips(parcel: dict, weather_forecast: dict, actions: list) -> list[dict]:
    """
    Génère 3-5 conseils agronomiques pour une parcelle.

    Retourne une liste de dicts {title, content, priority}
    priority: "high" | "medium" | "low"
    """
    culture = parcel.get("culture_type", "inconnu")
    soil = parcel.get("soil_type", "inconnu")
    region = parcel.get("region", "France")
    area = parcel.get("area_ha", 0)

    # Résumer la météo prévue
    daily = weather_forecast.get("daily", {})
    dates = daily.get("time", [])
    temps_max = daily.get("temperature_2m_max", [])
    temps_min = daily.get("temperature_2m_min", [])
    precip = daily.get("precipitation_sum", [])

    weather_summary = ""
    for i, d in enumerate(dates[:7]):
        tmax = temps_max[i] if i < len(temps_max) else "?"
        tmin = temps_min[i] if i < len(temps_min) else "?"
        rain = precip[i] if i < len(precip) else "?"
        weather_summary += f"  {d}: {tmin}-{tmax}°C, pluie {rain}mm\n"

    # Résumer les actions récentes
    actions_summary = "Aucune action enregistrée."
    if actions:
        lines = []
        for a in actions[:10]:
            lines.append(
                f"  - {a.get('date','?')}: {a.get('action_type','?')} "
                f"— {a.get('product_name','')} {a.get('quantity','')}{a.get('unit','')}"
                f" {a.get('notes','')}"
            )
        actions_summary = "\n".join(lines)

    prompt = f"""Tu es un agronome expert français. Donne exactement 5 conseils pratiques
et personnalisés pour cette parcelle agricole. Sois concis et actionnable.

PARCELLE:
- Culture: {culture}
- Sol: {soil}
- Région: {region}
- Surface: {area} ha

METEO PREVUE (7 jours):
{weather_summary}

ACTIONS RECENTES DE L'AGRICULTEUR:
{actions_summary}

Réponds UNIQUEMENT en JSON valide, sous la forme d'une liste:
[
  {{"title": "titre court", "content": "conseil détaillé en 1-2 phrases", "priority": "high|medium|low"}},
  ...
]

Priorise: high = action urgente liée à la météo, medium = optimisation rendement, low = conseil général.
Ne mets rien avant ou après le JSON."""

    try:
        model = _get_model()
        response = model.generate_content(prompt)
        text = response.text.strip()
        # Nettoyer les balises markdown si présentes
        if text.startswith("```"):
            text = text.split("\n", 1)[1] if "\n" in text else text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        import json
        tips = json.loads(text)
        if isinstance(tips, list):
            return tips[:5]
        return []
    except Exception as e:
        logger.error("Gemini tips error: %s", e)
        return [{"title": "Service IA temporairement indisponible",
                 "content": str(e), "priority": "low"}]


def generate_prediction_commentary(
    culture_type: str,
    predicted_yield: float,
    confidence: int,
    weather: dict,
    actions: list,
) -> str:
    """
    Génère un commentaire narratif pour accompagner une prédiction ML.
    """
    actions_text = "Aucune."
    if actions:
        actions_text = ", ".join(
            f"{a.get('action_type','')} ({a.get('product_name','')}, {a.get('quantity','')}{a.get('unit','')})"
            for a in actions[:5]
        )

    prompt = f"""Tu es un agronome expert. Commente brièvement cette prédiction de rendement.

Culture: {culture_type}
Rendement prédit: {predicted_yield} t/ha
Confiance: {confidence}%
Température moyenne: {weather.get('avg_temp_c', '?')}°C
Pluviométrie estimée: {weather.get('rainfall_mm', '?')} mm/an
Actions récentes: {actions_text}

Donne un commentaire de 2-3 phrases maximum:
- Explique si le rendement est bon/moyen/faible pour cette culture
- Donne un conseil d'action immédiate si pertinent
- Mentionne l'impact des conditions météo

Réponds directement en texte, sans formatage markdown."""

    try:
        model = _get_model()
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception as e:
        logger.error("Gemini commentary error: %s", e)
        return ""

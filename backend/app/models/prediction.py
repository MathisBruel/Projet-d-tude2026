from datetime import datetime
from bson import ObjectId

class Prediction:
    def __init__(self, parcel_id, user_id, weather_data=None, predicted_yield=None, confidence=None, recommendations=None, gemini_io=None, _id=None, requested_at=None):
        self._id = ObjectId(_id) if _id else None
        self.parcel_id = ObjectId(parcel_id) if parcel_id else None
        self.user_id = ObjectId(user_id) if user_id else None
        self.requested_at = requested_at or datetime.utcnow()
        
        # Données météo au moment de la demande
        self.weather_data = weather_data or {
            "temp_avg": 0.0,
            "precip_mm": 0.0,
            "humidity_pct": 0.0,
            "sunshine_h": 0.0,
            "radiation_kwh_m2": 0.0
        }
        
        # Résultats de l'IA
        self.predicted_yield_t_ha = predicted_yield
        self.confidence_pct = confidence
        self.recommendations = recommendations or []
        
        # Traces Gemini
        self.gemini_io = gemini_io or {
            "prompt": "",
            "response": ""
        }

    def to_dict(self):
        return {
            "_id": str(self._id) if self._id else None,
            "parcel_id": str(self.parcel_id) if self.parcel_id else None,
            "user_id": str(self.user_id) if self.user_id else None,
            "requested_at": self.requested_at.isoformat() if isinstance(self.requested_at, datetime) else self.requested_at,
            "weather_data": self.weather_data,
            "predicted_yield_t_ha": self.predicted_yield_t_ha,
            "confidence_pct": self.confidence_pct,
            "recommendations": self.recommendations,
            "gemini_io": self.gemini_io
        }

    def to_mongo(self):
        data = {
            "parcel_id": self.parcel_id,
            "user_id": self.user_id,
            "requested_at": self.requested_at,
            "weather_temp_avg": self.weather_data.get("temp_avg"),
            "weather_precip_mm": self.weather_data.get("precip_mm"),
            "weather_humidity_pct": self.weather_data.get("humidity_pct"),
            "weather_sunshine_h": self.weather_data.get("sunshine_h"),
            "soil_radiation_kwh_m2": self.weather_data.get("radiation_kwh_m2"),
            "predicted_yield_t_ha": self.predicted_yield_t_ha,
            "confidence_pct": self.confidence_pct,
            "recommendations": self.recommendations,
            "gemini_prompt": self.gemini_io.get("prompt"),
            "gemini_response": self.gemini_io.get("response")
        }
        if self._id:
            data["_id"] = self._id
        return data

    @staticmethod
    def from_mongo(data):
        if not data:
            return None
        return Prediction(
            parcel_id=data.get('parcel_id'),
            user_id=data.get('user_id'),
            weather_data={
                "temp_avg": data.get('weather_temp_avg'),
                "precip_mm": data.get('weather_precip_mm'),
                "humidity_pct": data.get('weather_humidity_pct'),
                "sunshine_h": data.get('weather_sunshine_h'),
                "radiation_kwh_m2": data.get('soil_radiation_kwh_m2')
            },
            predicted_yield=data.get('predicted_yield_t_ha'),
            confidence=data.get('confidence_pct'),
            recommendations=data.get('recommendations'),
            gemini_io={
                "prompt": data.get('gemini_prompt'),
                "response": data.get('gemini_response')
            },
            _id=data.get('_id'),
            requested_at=data.get('requested_at')
        )

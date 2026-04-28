from datetime import datetime


class PredictRequest:
    def __init__(self, data: dict):
        self.lat = data.get('lat')
        self.lng = data.get('lng')
        self.culture_type = data.get('culture_type')
        self.parcel_id = data.get('parcel_id')
        self.pesticides_tonnes = data.get('pesticides_tonnes', 50_000.0)
        self.rainfall_mm = data.get('rainfall_mm', 600.0)
        self.avg_temp_c = data.get('avg_temp_c', 12.0)

    def validate(self):
        if self.lat is None or self.lng is None or not self.culture_type:
            return "lat, lng et culture_type sont requis"
        return None


class PredictionResponse:
    @staticmethod
    def from_result(result, prediction_id, weather_src, avg_temp_c, rainfall_mm, gemini_comment):
        return {
            **result,
            "prediction_id": str(prediction_id),
            "weather_source": weather_src,
            "weather_input": {
                "avg_temp_c": avg_temp_c,
                "rainfall_mm": rainfall_mm,
            },
            "gemini_comment": gemini_comment,
        }

    @staticmethod
    def history_item(doc):
        doc["_id"] = str(doc["_id"])
        doc["user_id"] = str(doc["user_id"])
        if doc.get("parcel_id"):
            doc["parcel_id"] = str(doc["parcel_id"])
        if isinstance(doc.get("date"), datetime):
            doc["date"] = doc["date"].isoformat()
        if isinstance(doc.get("created_at"), datetime):
            doc["created_at"] = doc["created_at"].isoformat()
        return doc

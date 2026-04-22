import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    MONGO_URI    = os.getenv('MONGO_URI', 'mongodb://localhost:27017/agrisense')
    JWT_SECRET   = os.getenv('JWT_SECRET', 'dev_secret')
    GEMINI_KEY   = os.getenv('GEMINI_API_KEY', '')
    MAPS_KEY     = os.getenv('GOOGLE_MAPS_API_KEY', '')
    JWT_EXP_HOURS = 24

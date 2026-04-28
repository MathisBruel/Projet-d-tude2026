#!/usr/bin/env python3
"""
Script to seed AgriSense MongoDB database with large-scale realistic sample data.

Usage:
  python backend/scripts/seed_database.py          # Normal mode (idempotent)
  python backend/scripts/seed_database.py --force  # Force mode (delete all + reseed)

Generates ~15,000 documents across all collections for comprehensive testing.
"""

import os
import sys
import argparse
import random
from datetime import datetime, timedelta
from dotenv import load_dotenv
from pymongo import MongoClient
from bson import ObjectId
import bcrypt

# Load environment variables
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "../.env"))

MONGO_URI = "mongodb://localhost:27017/agrisense"

# Realistic French regions and their coordinates
REGIONS = {
    "Bretagne": {"lat": 47.9, "lng": -2.5, "names": ["Côtes-d'Armor", "Finistère", "Ille-et-Vilaine", "Morbihan"]},
    "Normandie": {"lat": 49.2, "lng": 0.2, "names": ["Calvados", "Eure", "Manche", "Orne", "Seine-Maritime"]},
    "Hauts-de-France": {"lat": 50.0, "lng": 3.0, "names": ["Aisne", "Nord", "Oise", "Pas-de-Calais", "Somme"]},
    "Grand Est": {"lat": 48.5, "lng": 5.5, "names": ["Ardennes", "Aube", "Haute-Marne", "Meurthe-et-Moselle", "Meuse"]},
    "Bourgogne-Franche-Comté": {"lat": 47.3, "lng": 5.0, "names": ["Côte-d'Or", "Doubs", "Jura", "Nièvre", "Saône-et-Loire", "Yonne"]},
    "Auvergne-Rhône-Alpes": {"lat": 46.0, "lng": 4.8, "names": ["Ain", "Allier", "Ardèche", "Cantal", "Drôme", "Isère", "Loire", "Haute-Loire"]},
    "Nouvelle-Aquitaine": {"lat": 45.5, "lng": -0.5, "names": ["Charente", "Charente-Maritime", "Corrèze", "Creuse", "Dordogne", "Gironde", "Landes", "Lot-et-Garonne"]},
    "Occitanie": {"lat": 43.5, "lng": 1.5, "names": ["Ariège", "Aude", "Aveyron", "Haute-Garonne", "Gers", "Lot", "Lozère", "Hautes-Pyrénées", "Pyrénées-Orientales"]},
    "Centre-Val de Loire": {"lat": 47.5, "lng": 1.5, "names": ["Cher", "Eure-et-Loir", "Indre", "Indre-et-Loire", "Loir-et-Cher", "Loiret"]},
    "Île-de-France": {"lat": 48.8, "lng": 2.3, "names": ["Essonne", "Hauts-de-Seine", "Seine-Saint-Denis", "Seine-et-Marne", "Val-d'Oise", "Val-de-Marne", "Yvelines"]},
}

CULTURES = ["wheat", "barley", "corn", "sunflower", "potato", "sugar_beet", "rapeseed", "oat", "rye", "lentil", "pea", "bean", "carrot", "onion"]
SOIL_TYPES = ["loam", "clay_loam", "sandy_loam", "clay", "sandy", "silt", "peat"]
ALERT_TYPES = ["weather", "disease_risk", "harvest", "system", "soil", "pest"]
ACTION_TYPES = ["fertilizer", "pesticide", "irrigation", "harvest", "seeding", "tillage", "pruning", "other"]

FIRST_NAMES_M = ["Jean", "Pierre", "Michel", "André", "Philippe", "David", "Christian", "Marc", "Luc", "François", "Alain", "Bernard", "Daniel", "Pascal", "Olivier"]
FIRST_NAMES_F = ["Marie", "Christine", "Anne", "Monique", "Jacqueline", "Isabelle", "Catherine", "Francine", "Véronique", "Sylvie", "Sophie", "Martine", "Laurence", "Patricia", "Claire"]
LAST_NAMES = ["Dupont", "Martin", "Bernard", "Thomas", "Robert", "Richard", "Petit", "Durand", "Lefevre", "Michel", "Garcia", "David", "Bertrand", "Roux", "Vincent", "Fournier", "Morel", "Girard", "Leclerc", "Bonnet"]

PRODUCTS = {
    "fertilizer": ["Engrais NPK 26-4-4", "Potasse", "Engrais organique", "Amendement calcaire", "Engrais azoté", "Super phosphate"],
    "pesticide": ["Spinosad", "Cymoxanil + Mancozèbe", "Pyrethrine", "Neem oil", "Sulfate de cuivre", "Insecticide systémique"],
    "irrigation": ["Irrigation goutte-à-goutte", "Irrigation par pivot", "Arrosage manuel"],
}

RECOMMENDATIONS = [
    "Augmenter l'irrigation en cas de sécheresse prolongée",
    "Surveiller les maladies fongiques",
    "Appliquer engrais azoté avant montaison",
    "Prévoir traitement insecticide contre les pucerons",
    "Conditions optimales pour maturation du grain",
    "Maintenir surveillance maladie",
    "Préparer équipement de récolte",
    "Prévention mildiou recommandée",
    "Récolte prévue dans 15-20 jours",
    "Apport potassique recommandé",
    "Surveillance floraison-fructification",
    "Diminuer engrais azoté pour éviter fendillement",
    "Excellentes conditions de croissance",
    "Attention aux parasites",
]

POST_CONTENTS = [
    {
        "title": "Lutte contre les pucerons du blé: retour d'expérience",
        "content": "Cette année j'ai testé une nouvelle stratégie: application d'insecticide bio dès le stade feuille 3 du blé au lieu d'attendre le stade épiaison. Résultats: réduction de 40% des dégâts aux grains sans impact sur le rendement. Surtout efficace avec les pulvérisateurs avec buses anti-dérive. Des retours d'autres agriculteurs?"
    },
    {
        "title": "Rendement maïs 2025: records battus en zone centre-est",
        "content": "Premiers retours des récoltes 2025: certains agriculteurs rapportent des rendements record (10+ t/ha) dans notre région. Les conditions météo ont été exceptionnelles en été (bon rayonnement + précipitations bien réparties). Quelle est votre situation? Avez-vous eu besoin d'irrigation?"
    },
    {
        "title": "Conseil: préparation du sol pour printemps 2025",
        "content": "Automne est le meilleur moment pour préparer vos sols pour printemps prochain:\n\n1. Analyse de sol recommandée (N, P, K, pH)\n2. Apport de matière organique si nécessaire\n3. Prévoir rotation des cultures pour éviter maladies\n4. Travail du sol selon type (argileux vs sableux)\n\nN'hésitez pas à demander conseil à votre chambre d'agriculture locale."
    },
    {
        "title": "Pommes de terre: prévention mildiou efficace",
        "content": "Après 20 ans de pommes de terre, je peux vous dire que la prévention du mildiou dès le mois de juin est ESSENTIELLE. J'utilise un mélange fongicide (cymoxanil + mancozèbe) toutes les 2-3 semaines. Cette année zéro perte! Attention: appliquer le matin, éviter les jours trop chauds."
    },
    {
        "title": "Orge brasserie vs orge fourragère: quel prix pour 2025?",
        "content": "Les cours ont dégringolé ce mois-ci... quelqu'un a des infos sur les prix futurs pour la récolte 2025? J'hésite à augmenter ma surface en orge brasserie (meilleur prix) mais c'est plus exigeant. Vos retours?"
    },
    {
        "title": "Rotation culturale: 4 ans de résultats",
        "content": "J'ai appliqué une rotation stricte (blé→orge→maïs→légumineuse) sur 8 hectares. Après 4 cycles, les résultats sont impressionnants: \n- Rendement blé +12%\n- Besoin en engrais -30%\n- Moins de maladies\n- Sol plus vivant\nLe coût initial d'aménagement s'est amorti. À recommander!"
    },
    {
        "title": "Tournesol: quand récolter exactement?",
        "content": "Les capitules baissent depuis 2 semaines... quand vous récoltez vous? J'ai peur de trop attendre et de perdre des graines. Le rendement semble bon cette année, c'est dommage de rater la récolte. Critères pratiques?"
    },
    {
        "title": "Irrigation goutte-à-goutte pour maïs: rentabilité?",
        "content": "Investissement lourd mais intéressé par la goutte-à-goutte pour améliorer ma productivité. Quelqu'un a des chiffres réels? Coût installation, consommation eau, maintenance? Combien d'années pour l'amortissement?"
    },
    {
        "title": "Semis directs: expérience après 3 ans",
        "content": "J'ai arrêté le labour sur mes 15 hectares de blé. Les avantages: coût réduit, sol meilleur, moins de temps. Les inconvénients: besoin d'un équipement spécialisé, gestion des adventices plus délicate. Résultat net: +15% sur la marge! Qui d'autre pratique le semis direct?"
    },
    {
        "title": "Bilan financial récolte 2024 - comment ça s'est passé?",
        "content": "Année difficile... Entre la météo capricieuse et la baisse des cours, ma récolte 2024 a été décevante. Rendements OK mais prix très bas. Comment vous avez géré? Avez-vous des contrats futurs pour 2025 ou vous jouez à la bourse agricole?"
    },
    {
        "title": "Pompe d'irrigation: panne et coût de réparation",
        "content": "Ma pompe de 15kW rend l'âme en plein arrosage du maïs... SAV demande 3000€ de réparation! C'est usé, le moteur est en fin de vie. Quelqu'un connait des fournisseurs sérieux pour remplacement? Budget acceptable?"
    },
    {
        "title": "Betterave sucrière: intérêt toujours d'actualité?",
        "content": "En réflexion sur la diversification. Betterave sucrière, c'est rentable en 2025? Les contrats avec les usines sont-ils avantageux? Quelle surface minimale? Retours des agriculteurs déjà engagés?"
    },
    {
        "title": "Fertilisant azoté: prix en hausse, alternatives bio?",
        "content": "Les prix des engrais chimiques explosent... explorez-vous les alternatives bio? Compost, fumier, légumineuses? J'aimerais tester mais peur de la productivité. Avez-vous des expériences positives?"
    },
    {
        "title": "Récolte blé: humidité et séchage coûteux",
        "content": "Le blé est souvent trop humide à la moisson... séchage artificiel coûte une fortune. Comment vous gérez? Attendre plus longtemps? Négocier avec l'acheteur? Investir dans un séchoir collectif?"
    },
    {
        "title": "Utilisation de drones pour monitoring parcelles",
        "content": "J'ai loué un drone pour scaner mes parcelles (NDVI, détection maladies). Coût: 300€. Impact: détection précoce d'un foyer de maladie qui m'a sauvé 2 hectares! Des autres l'utilisent? Marques recommandées?"
    },
    {
        "title": "Crop insurance: vaut-il vraiment le coup?",
        "content": "L'assurance récolte, c'est un bon investissement? Vu les conditions météo erratiques, je réfléchis... Avez-vous des remboursements? Franchises acceptables? Avis des assurés?"
    },
    {
        "title": "Changement climatique: adaptation culturale",
        "content": "Avec les sécheresses plus fréquentes, j'ai décidé de passer à des cultures plus résistantes. Fini le maïs gros consommateur d'eau, hello sorgho et tournesol. Premiers essais... à suivre. Vous avez adapté vos cultures?"
    },
    {
        "title": "Formation agronomie 2025: quel programme?",
        "content": "Qui a suivi une formation continue récemment? Agriculture de précision, sol, biodiversité... J'aimerais améliorer mes connaissances. Quels organismes vous recommandez? Budget acceptable pour agriculteur?"
    },
    {
        "title": "Vente directe: rentabilité vs circuits courts",
        "content": "Tenter la vente directe aux consommateurs? Moins de marge pour distributeur, mais plus de coûts logistiques. Comment vous organisez? Légalité? Quels produits?"
    },
    {
        "title": "Engrai foliaire: efficacité réelle?",
        "content": "Tendance de plus en plus à utiliser des engrais foliaires (spray sur feuilles). Vraiment plus efficace que engrais sol? Économies réelles? Experiences?"
    },
]

POST_TAGS = ["blé", "maïs", "rendement", "bio", "lutte intégrée", "irrigation", "conseil", "météo", "récolte", "sol", "engrais", "maladie"]


def hash_password(password: str) -> str:
    """Hash password using bcrypt."""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')


def generate_avatar_url(first_name: str, last_name: str) -> str:
    """Generate avatar initials string (no URL to avoid proxy issues)."""
    # Return just the initials - let frontend generate avatar with initials
    return f"{first_name[0]}{last_name[0]}".upper()


def get_random_region():
    """Get random region with coordinates."""
    region_name = random.choice(list(REGIONS.keys()))
    region = REGIONS[region_name]
    # Add some randomness to coordinates
    lat = region["lat"] + random.uniform(-0.5, 0.5)
    lng = region["lng"] + random.uniform(-0.5, 0.5)
    return region_name, lat, lng


def generate_coordinates(lat, lng):
    """Generate coordinates for a parcel as list of {lat, lng} objects."""
    offset = 0.002
    return [
        {"lat": lat - offset, "lng": lng - offset},
        {"lat": lat + offset, "lng": lng - offset},
        {"lat": lat + offset, "lng": lng + offset},
        {"lat": lat - offset, "lng": lng + offset},
        {"lat": lat - offset, "lng": lng - offset},
    ]


def clear_database(db):
    """Delete all collections from the database."""
    collections = [
        'users', 'parcels', 'predictions', 'posts',
        'alerts', 'parcel_actions'
    ]

    for collection_name in collections:
        try:
            count = db[collection_name].count_documents({})
            if count > 0:
                db[collection_name].delete_many({})
                print(f"   🗑️  Cleared '{collection_name}' ({count} documents)")
        except Exception as e:
            print(f"   ⚠️  Error clearing '{collection_name}': {e}")


def seed_database(force=False):
    """Seed the database with large-scale realistic data."""
    try:
        client = MongoClient(MONGO_URI)
        db = client.get_default_database()

        mode = "FORCE" if force else "NORMAL (idempotent)"
        print("🌱 Starting database seeding (LARGE DATASET)...")
        print(f"📊 Connected to: {MONGO_URI}")
        print(f"⚙️  Mode: {mode}\n")

        # Handle force mode: delete all data first
        if force:
            print("🗑️  Force mode: clearing all collections...\n")
            clear_database(db)
            print()

        # Check if data already exists (idempotent mode)
        if not force and db.users.count_documents({}) > 0:
            print("✅ Database already contains users. Skipping seeding.")
            print(f"   Users: {db.users.count_documents({})}")
            print(f"   Parcels: {db.parcels.count_documents({})}")
            print(f"   Predictions: {db.predictions.count_documents({})}")
            print(f"   Posts: {db.posts.count_documents({})}")
            print(f"   Alerts: {db.alerts.count_documents({})}")
            print(f"   Actions: {db.parcel_actions.count_documents({})}")
            print("\n💡 Tip: Use --force to delete and reseed: python scripts/seed_database.py --force")
            return

        # === CREATE USERS (60+) ===
        print("👥 Creating users (60+)...")
        users_data = []
        user_emails = {}

        # 1 Admin
        admin_email = "admin@agrisense.fr"
        admin_first = "Admin"
        admin_last = "AgriSense"
        users_data.append({
            "email": admin_email,
            "password_hash": hash_password("admin123"),
            "role": "admin",
            "first_name": admin_first,
            "last_name": admin_last,
            "phone": f"+33 {random.randint(100000000, 999999999)}",
            "location_name": "Paris",
            "location_lat": 48.8566,
            "location_lng": 2.3522,
            "avatar_url": generate_avatar_url(admin_first, admin_last),
            "created_at": datetime.now() - timedelta(days=365),
            "updated_at": datetime.now() - timedelta(days=1),
        })
        user_emails[admin_email] = None

        # 40 Farmers
        for i in range(40):
            is_male = random.choice([True, False])
            first_name = random.choice(FIRST_NAMES_M if is_male else FIRST_NAMES_F)
            last_name = random.choice(LAST_NAMES)
            region, lat, lng = get_random_region()
            email = f"{first_name.lower()}.{last_name.lower()}{i}@farm.fr"
            users_data.append({
                "email": email,
                "password_hash": hash_password("password123"),
                "role": "farmer",
                "first_name": first_name,
                "last_name": last_name,
                "phone": f"+33 {random.randint(100000000, 999999999)}",
                "location_name": region,
                "location_lat": lat,
                "location_lng": lng,
                "avatar_url": generate_avatar_url(first_name, last_name),
                "created_at": datetime.now() - timedelta(days=random.randint(30, 360)),
                "updated_at": datetime.now() - timedelta(days=random.randint(1, 30)),
            })
            user_emails[email] = None

        # 20 Agronomists
        for i in range(20):
            is_male = random.choice([True, False])
            first_name = random.choice(FIRST_NAMES_M if is_male else FIRST_NAMES_F)
            last_name = random.choice(LAST_NAMES)
            region, lat, lng = get_random_region()
            email = f"{first_name.lower()}.{last_name.lower()}{i}@agro.fr"
            users_data.append({
                "email": email,
                "password_hash": hash_password("password123"),
                "role": "agronomist",
                "first_name": first_name,
                "last_name": last_name,
                "phone": f"+33 {random.randint(100000000, 999999999)}",
                "location_name": region,
                "location_lat": lat,
                "location_lng": lng,
                "avatar_url": generate_avatar_url(first_name, last_name),
                "created_at": datetime.now() - timedelta(days=random.randint(30, 360)),
                "updated_at": datetime.now() - timedelta(days=random.randint(1, 30)),
            })
            user_emails[email] = None

        result = db.users.insert_many(users_data)
        inserted_user_ids = result.inserted_ids
        for i, u in enumerate(users_data):
            user_emails[u['email']] = inserted_user_ids[i]
        print(f"   ✓ Created {len(inserted_user_ids)} users")

        # === CREATE PARCELS (500+) ===
        print("🌾 Creating parcels (500+)...")
        parcels_data = []
        parcel_ids_by_user = {}
        parcel_count_by_farmer = {}

        # Include admin + farmers
        users_with_parcels = [u for u in users_data if u['role'] in ['farmer', 'admin']]

        for farmer in users_with_parcels:
            farmer_id = user_emails[farmer['email']]
            parcel_ids_by_user[farmer_id] = []

            # Each farmer has 10-15 parcels
            num_parcels = random.randint(10, 15)
            parcel_count_by_farmer[str(farmer_id)] = num_parcels

            for p in range(num_parcels):
                region, lat, lng = get_random_region()
                coords = generate_coordinates(lat, lng)
                parcel = {
                    "user_id": farmer_id,
                    "name": f"{farmer['first_name']}'s Field {p+1}",
                    "culture_type": random.choice(CULTURES),
                    "area_ha": round(random.uniform(2, 50), 1),
                    "coordinates": coords,
                    "center": {"type": "Point", "coordinates": [lng, lat]},
                    "soil_type": random.choice(SOIL_TYPES),
                    "region": region,
                    "created_at": datetime.now() - timedelta(days=random.randint(5, 200)),
                    "updated_at": datetime.now() - timedelta(days=random.randint(1, 20)),
                }
                parcels_data.append((farmer_id, parcel))

        result = db.parcels.insert_many([p[1] for p in parcels_data])
        parcel_ids = result.inserted_ids

        # Map parcel IDs by user and keep parcel data for predictions
        parcel_data_by_id = {}
        for idx, (farmer_id, parcel_data) in enumerate(parcels_data):
            parcel_ids_by_user[farmer_id].append(parcel_ids[idx])
            parcel_data_by_id[parcel_ids[idx]] = parcel_data

        print(f"   ✓ Created {len(parcel_ids)} parcels")

        # === CREATE PREDICTIONS (400+) ===
        print("🤖 Creating predictions (400+)...")
        predictions_data = []

        for farmer_id, parcels in parcel_ids_by_user.items():
            # 2-4 predictions per parcel
            for parcel_id in parcels:
                parcel_info = parcel_data_by_id.get(parcel_id, {})
                culture_type = parcel_info.get("culture_type", random.choice(CULTURES))

                for _ in range(random.randint(2, 4)):
                    prediction = {
                        "parcel_id": parcel_id,
                        "user_id": farmer_id,
                        "culture_type": culture_type,
                        "requested_at": datetime.now() - timedelta(days=random.randint(1, 30)),
                        "weather_temp_avg": round(random.uniform(8, 25), 1),
                        "weather_precip_mm": round(random.uniform(20, 80), 1),
                        "weather_humidity_pct": round(random.uniform(50, 85), 1),
                        "weather_sunshine_h": round(random.uniform(150, 200), 1),
                        "soil_radiation_kwh_m2": round(random.uniform(15, 25), 1),
                        "predicted_yield_t_ha": round(random.uniform(3, 15), 1),
                        "confidence_pct": random.randint(65, 95),
                        "recommendations": random.sample(RECOMMENDATIONS, k=random.randint(2, 4)),
                        "gemini_prompt": "Estimate crop yield based on current conditions...",
                        "gemini_response": f"Estimated yield: {round(random.uniform(3, 15), 1)} t/ha with high confidence.",
                    }
                    predictions_data.append(prediction)

        result = db.predictions.insert_many(predictions_data)
        print(f"   ✓ Created {len(result.inserted_ids)} predictions")

        # === CREATE POSTS (100+) with images and replies ===
        print("📝 Creating community posts (100+)...")
        posts_data = []

        # Image URLs for agricultural content
        IMAGE_URLS = [
            "https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=500",  # Wheat field
            "https://images.unsplash.com/photo-1625246333195-78d9c38ad576?w=500",  # Corn field
            "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=500",  # Sunflower
            "https://images.unsplash.com/photo-1560493676-04071c5f467b?w=500",    # Farmer
            "https://images.unsplash.com/photo-1500382017468-7049ffd0c72c?w=500",  # Tractor
            "https://images.unsplash.com/photo-1533460713344-be3552e2dba1?w=500",  # Soil
            "https://images.unsplash.com/photo-1400012621108-6601de0cbd2f?w=500",  # Harvest
            "https://images.unsplash.com/photo-1595433707802-6b2626ef1c91?w=500",  # Potato
        ]

        user_ids_list = list(user_emails.values())[1:]  # All non-admin users

        # Varied reply content templates
        REPLY_TEMPLATES = [
            "Excellente expérience! J'ai le même problème. Merci pour le partage!",
            "Intéressant... je vais tester cette approche sur ma parcelle. Merci!",
            "Totalement d'accord. C'est ce que j'ai remarqué aussi cette année.",
            "Peux-tu donner plus de détails sur la dosage? Marque spécifique?",
            "Quel coût environ pour cette solution? Rentable long terme?",
            "Très utile! Je ne savais pas ça. Ça change la donne.",
            "Chez moi c'est l'inverse... location différente peut-être.",
            "Parfait! J'en parlais justement avec un ami agriculteur.",
            "Essayé aussi mais avec des résultats mitigés. Dépend du terroir?",
            "Sage conseil! L'expérience compte vraiment en agriculture.",
            "Incroyable! Ça m'a sauvé cette année. Recommande vivement.",
            "Merci pour ces données précises. Très utile pour planifier.",
        ]

        for i in range(100):
            user_id = random.choice(user_ids_list)
            post_data = random.choice(POST_CONTENTS)
            post_created = datetime.now() - timedelta(days=random.randint(1, 60))

            # Generate replies for 70% of posts
            replies = []
            if random.random() < 0.7:
                num_replies = random.randint(1, 5)
                for _ in range(num_replies):
                    reply_user = random.choice(user_ids_list)
                    reply = {
                        "user_id": reply_user,
                        "content": random.choice(REPLY_TEMPLATES),
                        "created_at": post_created + timedelta(days=random.randint(1, 10), hours=random.randint(1, 24))
                    }
                    replies.append(reply)

            # Add image to 60% of posts
            image_url = None
            if random.random() < 0.6:
                image_url = random.choice(IMAGE_URLS)

            post = {
                "user_id": user_id,
                "title": post_data["title"],
                "content": post_data["content"],
                "tags": random.sample(POST_TAGS, k=random.randint(2, 5)),
                "likes_count": random.randint(0, 50),
                "liked_by": random.sample(user_ids_list, k=min(random.randint(0, 15), len(user_ids_list))),
                "image_url": image_url,
                "replies": replies,
                "created_at": post_created,
                "updated_at": post_created + timedelta(days=random.randint(0, 10)),
            }
            posts_data.append(post)

        result = db.posts.insert_many(posts_data)
        print(f"   ✓ Created {len(result.inserted_ids)} posts")

        # === CREATE ALERTS (400+) ===
        print("⚠️  Creating alerts (400+)...")
        alerts_data = []

        for farmer_id, parcels in parcel_ids_by_user.items():
            for parcel_id in parcels:
                # 2-4 alerts per parcel
                for _ in range(random.randint(2, 4)):
                    alert = {
                        "user_id": farmer_id,
                        "parcel_id": parcel_id,
                        "type": random.choice(ALERT_TYPES),
                        "message": f"Alert message for parcel management - {random.choice(['warning', 'info', 'critical'])}",
                        "severity": random.choice(["info", "warning", "critical"]),
                        "read": random.choice([True, False]),
                        "created_at": datetime.now() - timedelta(days=random.randint(1, 30)),
                    }
                    alerts_data.append(alert)

        result = db.alerts.insert_many(alerts_data)
        print(f"   ✓ Created {len(result.inserted_ids)} alerts")

        # === CREATE PARCEL ACTIONS (800+) ===
        print("📋 Creating parcel actions (800+)...")
        actions_data = []

        for farmer_id, parcels in parcel_ids_by_user.items():
            for parcel_id in parcels:
                # 4-6 actions per parcel
                for _ in range(random.randint(4, 6)):
                    action_type = random.choice(ACTION_TYPES)
                    action = {
                        "user_id": farmer_id,
                        "parcel_id": parcel_id,
                        "action_type": action_type,
                        "date": datetime.now() - timedelta(days=random.randint(1, 120)),
                        "product_name": random.choice(PRODUCTS.get(action_type, ["Product"])) if action_type in PRODUCTS else "Task",
                        "quantity": round(random.uniform(10, 500), 1) if action_type != "harvest" else round(random.uniform(1000, 5000), 1),
                        "unit": random.choice(["kg", "L", "mm", "units"]),
                        "notes": f"Action notes for {action_type}",
                        "created_at": datetime.now() - timedelta(days=random.randint(1, 120)),
                    }
                    actions_data.append(action)

        result = db.parcel_actions.insert_many(actions_data)
        print(f"   ✓ Created {len(result.inserted_ids)} parcel actions")

        # === CREATE INDEXES ===
        print("📑 Creating database indexes...")
        db.users.create_index("email", unique=True)
        db.parcels.create_index("user_id")
        db.predictions.create_index([("user_id", 1), ("parcel_id", 1)])
        db.posts.create_index("user_id")
        db.alerts.create_index([("user_id", 1), ("parcel_id", 1)])
        db.parcel_actions.create_index([("user_id", 1), ("parcel_id", 1)])
        print("   ✓ Indexes created")

        print("\n" + "="*60)
        print("✅ Database seeding completed successfully!")
        print("="*60)
        print("\n📊 Summary:")
        print(f"   Users: {db.users.count_documents({})}")
        print(f"   Parcels: {db.parcels.count_documents({})}")
        print(f"   Predictions: {db.predictions.count_documents({})}")
        print(f"   Posts: {db.posts.count_documents({})}")
        print(f"   Alerts: {db.alerts.count_documents({})}")
        print(f"   Actions: {db.parcel_actions.count_documents({})}")
        total_docs = sum([
            db.users.count_documents({}),
            db.parcels.count_documents({}),
            db.predictions.count_documents({}),
            db.posts.count_documents({}),
            db.alerts.count_documents({}),
            db.parcel_actions.count_documents({}),
        ])
        print(f"   📈 TOTAL DOCUMENTS: {total_docs}")

        print("\n🔑 Default Test Credentials:")
        print("   Admin:    admin@agrisense.fr / admin123")
        print("   Farmers:  [firstname].lastname[0-39]@farm.fr / password123")
        print("   Agronomists: [firstname].lastname[0-19]@agro.fr / password123")

        client.close()

    except Exception as e:
        print(f"\n❌ Error during seeding: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Seed AgriSense MongoDB database with large-scale realistic sample data.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/seed_database.py              # Idempotent mode (skip if data exists)
  python scripts/seed_database.py --force      # Force mode (delete all + reseed)
  python scripts/seed_database.py -f           # Force mode (shorthand)
        """
    )
    parser.add_argument(
        "--force", "-f",
        action="store_true",
        help="Delete all data and reseed from scratch (non-idempotent)"
    )

    args = parser.parse_args()
    seed_database(force=args.force)

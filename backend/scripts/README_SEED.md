# 🌱 Script de Seeding AgriSense

Guide pour exécuter le script de remplissage de la base de données MongoDB.

## 📋 Prérequis

- **Python 3.8+** installé
- **MongoDB** en cours d'exécution (Docker ou local)
- **Dépendances Python** installées : `pip install -r requirements.txt`

## 🚀 Utilisation

### 1️⃣ Mode Normal (Idempotent)

```bash
python backend/scripts/seed_database.py
```

**Comportement :**
- ✅ Vérifie si la base contient déjà des données
- ✅ Si vide → remplit la base complètement
- ✅ Si déjà remplie → n'ajoute rien (sûr, non destructif)

### 2️⃣ Mode Force (Réinitialisation complète)

```bash
python backend/scripts/seed_database.py --force
```

**Comportement :**
- 🗑️ Supprime **TOUTES** les données
- 🌱 Remplit avec un nouveau jeu complet

⚠️ **Attention :** Utilisez `--force` uniquement si vous êtes sûr !

## 📊 Données Générées

Le script crée automatiquement :

| Type | Quantité | Description |
|------|----------|-------------|
| **Utilisateurs** | 61 | 1 admin + 40 fermiers + 20 agronomes |
| **Parcelles** | 500+ | 10-15 parcelles par fermier + admin |
| **Prédictions** | 1500+ | 2-4 prédictions par parcelle |
| **Posts** | 100+ | Publications communautaires avec réponses |
| **Alertes** | 1000+ | Alertes météo et agronomiques |
| **Actions** | 500+ | Actions sur les parcelles |

## 👥 Utilisateurs par Défaut

Après seeding, vous pouvez vous connecter avec :

### Admin
```
Email: admin@agrisense.fr
Mot de passe: admin123
Rôle: admin
Parcelles: 10-15 champs
```

### Fermiers (exemples)
```
Email: jean.dupont0@farm.fr
Mot de passe: password123
Rôle: farmer
Parcelles: 10-15 champs chacun
```

### Agronomes (exemples)
```
Email: marie.martin0@agro.fr
Mot de passe: password123
Rôle: agronomist
```

## 🔧 Configuration MongoDB

Le script utilise automatiquement :

```
MONGO_URI = mongodb://localhost:27017/agrisense
```

**Pour modifier :** Éditez le fichier `.env` :

```bash
# backend/.env
MONGO_URI=mongodb://localhost:27017/agrisense
```

## 📍 Avec Docker Compose

Démarrez tout le stack avec :

```bash
docker compose -f docker-compose.dev.yml up -d
```

Puis seedez depuis votre machine hôte :

```bash
python backend/scripts/seed_database.py --force
```

## ✅ Vérification

Pour vérifier que le seeding a réussi :

```bash
# Depuis MongoDB Atlas ou local
db.users.count()           # Doit montrer 61
db.parcels.count()         # Doit montrer ~500
db.predictions.count()     # Doit montrer ~1500
db.posts.count()           # Doit montrer ~100
```

## 🐛 Dépannage

### Erreur : "Connection refused"
```
❌ MongoClient Error: Connection refused
```
→ Vérifiez que MongoDB est en cours d'exécution
→ Vérifiez la URI dans `.env`

### Erreur : "Database already contains users"
→ Utilisez `--force` pour réinitialiser complètement

### Erreur : "ModuleNotFoundError"
```bash
pip install -r backend/requirements.txt
```

## 📝 Structure des Données

### Users
- `email` : Identifiant unique
- `password_hash` : Hash bcrypt
- `role` : "admin", "farmer", ou "agronomist"
- `location_lat/lng` : Coordonnées géographiques

### Parcels
- `user_id` : ID du propriétaire (fermier ou admin)
- `name` : Nom du champ
- `culture_type` : Blé, maïs, tournesol, etc.
- `area_ha` : Surface en hectares
- `coordinates` : Polygone GeoJSON
- `soil_type` : Type de sol

### Predictions
- `parcel_id` : ID de la parcelle
- `culture_type` : Culture prédite
- `predicted_yield_t_ha` : Rendement estimé (t/ha)
- `confidence_pct` : Confiance en %
- `gemini_response` : Commentaire IA

## 💡 Tips

- **Mode développement :** Utilisez `--force` pour repartir de zéro
- **Tests d'API :** Les données incluent tout ce nécessaire pour tester
- **Démo :** 61 utilisateurs × 10+ parcelles = beaucoup de données pour démontrer

---

**Dernière mise à jour :** 28/04/2026

# AgriSense Database Seeding

## Overview
Ce script génère et insère automatiquement des **données réalistes** et **cohérentes** dans la base MongoDB du projet AgriSense.

## Données Générées

### 👥 Utilisateurs (6)
- **1 Admin** : gestion système
- **3 Fermiers** : utilisateurs principaux avec parcelles
- **2 Agronomes** : consultants

Tous les utilisateurs ont des profils réalistes avec :
- Localisation en France (régions différentes)
- Numéro de téléphone
- Dates de création variées

### 🌾 Parcelles (5)
- **2 parcelles** pour Jean Dupont (Bretagne) : Blé, Orge
- **2 parcelles** pour Marie Martin (Bourgogne) : Maïs, Tournesol
- **1 parcelle** pour Pierre Bernard (Rhône-Alpes) : Pommes de terre

Chaque parcelle inclut :
- Localisation GPS précise (GeoJSON)
- Type de culture
- Surface en hectares
- Type de sol
- Région

### 🤖 Prédictions IA (4)
Résultats réalistes d'appels à l'API Gemini :
- Rendement prédit (t/ha)
- Niveau de confiance (%)
- Données météorologiques complètes
- Recommandations actionables

### 📝 Posts Communautaires (3)
Articles sur :
- Lutte contre les pucerons (avec discussions)
- Rendement maïs 2025
- Conseils préparation sol

Chaque post inclut replies, likes, tags.

### ⚠️  Alertes (4)
Types variés :
- Alerte météo (orage)
- Risque maladie (mildiou)
- Notif récolte
- Alertes lues/non lues

### 📋 Actions de Parcelle (8)
Historique d'opérations agricoles :
- Fertilisation
- Traitement pesticide
- Semis
- Irrigation
- Dates échelonnées réalistes

---

## Installation & Utilisation

### 1️⃣ Prérequis
```bash
# Assurez-vous que les dépendances sont installées
cd backend
pip install -r requirements.txt
```

> **Note** : le script nécessite `bcrypt` (pour hasher les mots de passe). Si absent :
> ```bash
> pip install bcrypt
> ```

### 2️⃣ Configuration (.env)
Créez un fichier `.env` à la racine du dossier `backend/` :

```env
FLASK_APP=wsgi.py
FLASK_ENV=development
FLASK_DEBUG=1

MONGO_URI=mongodb://localhost:27017/agrisense
# OU pour Atlas : mongodb+srv://user:pass@cluster.mongodb.net/agrisense

JWT_SECRET=change_this_secret_in_production
GEMINI_API_KEY=your_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

### 3️⃣ Lancer le script

#### Mode Normal (Idempotent - défaut)
```bash
# Depuis la racine du projet
python backend/scripts/seed_database.py

# Ou depuis le dossier backend
cd backend
python scripts/seed_database.py
```

**Comportement :**
- ✅ Si données existent → skip (zéro duplication)
- ✅ Si base vide → populate
- ✅ Sûr de relancer plusieurs fois

#### Mode Force (Delete + Reseed)
```bash
# Depuis la racine du projet
python backend/scripts/seed_database.py --force

# Shorthand
python backend/scripts/seed_database.py -f

# Ou depuis le dossier backend
cd backend
python scripts/seed_database.py --force
```

**Comportement :**
- 🗑️ Supprime TOUTES les données des collections
- 📝 Repopule avec données fraîches
- ⚠️ À utiliser avec prudence en production

### 4️⃣ Résultat
```
🌱 Starting database seeding...
📊 Connected to: mongodb://localhost:27017/agrisense

👥 Creating users...
   ✓ Created 6 users
🌾 Creating parcels...
   ✓ Created 5 parcels
🤖 Creating predictions...
   ✓ Created 4 predictions
📝 Creating community posts...
   ✓ Created 3 posts
⚠️  Creating alerts...
   ✓ Created 4 alerts
📋 Creating parcel actions...
   ✓ Created 8 parcel actions
📑 Creating database indexes...
   ✓ Indexes created

==================================================
✅ Database seeding completed successfully!
==================================================

📊 Summary:
   Users: 6
   Parcels: 5
   Predictions: 4
   Posts: 3
   Alerts: 4
   Actions: 8

🔑 Default Test Credentials:
   Admin:    admin@agrisense.fr / admin123
   Farmer 1: jean.dupont@farm.fr / password123
   Farmer 2: marie.martin@farm.fr / password123
   Farmer 3: pierre.bernard@farm.fr / password123
   Agro 1:   christine.rousseau@agro.fr / password123
   Agro 2:   luc.moreau@agro.fr / password123
```

---

## 🔄 Deux Modes de Fonctionnement

### Mode Idempotent (défaut) - Sûr
```bash
python scripts/seed_database.py
```

| Exécution | Comportement |
|-----------|------------|
| 1ère | Crée toutes les données |
| 2ème | Détecte les données, **skip** |
| 3ème+ | Idem : **aucune duplication** |

✅ **Recommandé** pour docker-compose et développement normal

### Mode Force - Remise à Zéro
```bash
python scripts/seed_database.py --force
```

| Exécution | Comportement |
|-----------|------------|
| 1ère | Supprime tout, crée nouvelles données |
| 2ème | Supprime tout, crée nouvelles données |
| 3ème+ | Idem : **reset complet à chaque fois** |

⚠️ **À utiliser** quand vous voulez repartir de zéro

### Comparaison

| Aspect | Mode Normal | Mode Force |
|--------|------------|-----------|
| Skip si données existent | ✅ Oui | ❌ Non |
| Risque duplication | ✅ Non | ✅ Non |
| Supprime données anciennes | ❌ Non | ✅ Oui |
| Vitesse | ⚡ Plus rapide (skip) | 🔄 Toujours refait tout |
| Sûreté | 🟢 Très sûr | 🟡 Prudence requise |
| Cas d'usage | Dev normal, CI/CD | Reset complet, tests |

---

## 🔁 Raccourcis Pratiques

```bash
# Reseed complètement
python scripts/seed_database.py --force

# Idem (shorthand -f)
python scripts/seed_database.py -f

# Voir l'aide
python scripts/seed_database.py --help
```

---

## 🧹 Réinitialiser la base (alternative)

Si vous préférez supprimer manuellement avant de seeder :

```bash
# MongoDB local
mongo
> use agrisense
> db.dropDatabase()

# Ou MongoDB Atlas
mongosh "mongodb+srv://..."
> use agrisense
> db.dropDatabase()
```

Puis relancer le script en mode normal :
```bash
python scripts/seed_database.py
```

---

## Structure des données

Toutes les données respectent les schémas définis dans `backend/app/models/` :
- ✅ User
- ✅ Parcel
- ✅ Prediction
- ✅ Post
- ✅ Alert
- ✅ ParcelAction

Les timestamps et ObjectIDs sont automatiquement gérés.

---

## Utilisation dans docker-compose

Pour automatiser le seeding au démarrage, vous pouvez ajouter dans `docker-compose.yml` :

```yaml
services:
  backend:
    build: ./backend
    command: sh -c "python scripts/seed_database.py && flask run --host=0.0.0.0"
    # ...
```

Le script s'exécutera avant le serveur Flask et sortira proprement si les données existent déjà.

---

## Questions / Modifications

- **Ajouter plus de données ?** → Modifiez les listes `users_data`, `parcels_data`, etc.
- **Changer les régions ?** → Mettez à jour `location_*` et `coordinates`
- **Ajouter de nouvelles cultures ?** → Ajoutez dans les `culture_type`
- **Modifier les prédictions ?** → Changez `predicted_yield` et `recommendations`

Le script est commenté et facilement extensible. 🌱

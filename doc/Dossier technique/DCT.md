# DCT — Document de Contexte Technique
## Stack, Architecture Logicielle
## AgriSense — Projet d'études Bachelor 2

**Date** : 2026-04-27 | **Version** : 1.0

---

## 🏗️ Architecture applicative

```
Flutter App (Android + iOS)
  ├─ Screens (Login, Dashboard, Map, Prediction, Community)
  ├─ Providers (State: Auth, Parcels, Predictions)
  └─ Data Layer (Repositories, Services, Models)
       ↓ HTTP REST (JWT in headers)
Flask API (Python)
  ├─ Routes (auth, parcels, predictions, community, admin)
  ├─ Services (Gemini, Weather, Auth)
  ├─ Models (User, Parcel, Prediction, Post)
  └─ Middlewares (JWT, CORS, error normalization)
       ↓ TLS Connection Pool
MongoDB Atlas
  ├─ users, parcels, predictions, posts, alerts
  └─ Indexes: user_id, parcel_id, created_at, geo

External APIs
  ├─ Open-Meteo (weather data)
  ├─ NASA POWER (soil data)
  ├─ Gemini API (AI predictions)
  └─ Google Maps (geocoding)
```

---

## 📱 Frontend — Flutter (Dart)

### Architecture

**Pattern** : MVVM + Repository (clean code)

**Structure** :
```
lib/
├── main.dart
├── core/
│   ├── theme/          (Material Design 3, couleurs)
│   ├── router/         (GoRouter, routes)
│   └── constants/      (API URLs, strings)
├── data/
│   ├── models/         (User, Parcel, Prediction, Post)
│   ├── repositories/   (HTTP calls via HttpClientService)
│   └── services/       (HTTP, SecureStorage, Location)
└── presentation/
    ├── screens/        (Login, Dashboard, Map, Prediction, Community, Admin)
    └── widgets/        (Reusable: cards, buttons, markers)
```

### Dépendances clés

| Package | Rôle |
|---|---|
| **http** | REST API calls |
| **provider** | State management |
| **go_router** | Navigation / routing |
| **google_maps_flutter** | Map display |
| **flutter_secure_storage** | JWT token storage |
| **geolocator** | GPS location |
| **google_sign_in** | Google auth (optional) |
| **json_serializable** | JSON ↔ Dart objects |

### Patterns

**State Management** : Provider + ChangeNotifier

**HTTP Client** : Centralisé (JWT token auto-injected)

**Navigation** : GoRouter (named routes)

**Secure Storage** : FlutterSecureStorage (token protection)

**Theme** : Material Design 3, couleurs agricoles (verts, terreux)

---

## 🔧 Backend — Python Flask

### Architecture

**Pattern** : Modulaire (routes, services, models, middlewares)

**Structure** :
```
backend/
├── app/
│   ├── __init__.py         (Flask app, CORS, blueprints)
│   ├── config.py           (Env vars)
│   ├── routes/
│   │   ├── auth.py         (register, login, refresh, logout)
│   │   ├── parcels.py      (CRUD parcels)
│   │   ├── predictions.py  (trigger IA, list, get)
│   │   ├── community.py    (posts, replies)
│   │   ├── admin.py        (user management)
│   │   └── health.py       (healthcheck)
│   ├── services/
│   │   ├── gemini_service.py     (Gemini API)
│   │   ├── weather_service.py    (Open-Meteo + NASA)
│   │   └── auth_service.py       (JWT, bcrypt)
│   ├── models/
│   │   ├── user.py, parcel.py, prediction.py, post.py
│   │   └── Couche abstraction MongoDB
│   └── middlewares/
│       ├── jwt_middleware.py      (@jwt_required decorator)
│       ├── cors_middleware.py     (CORS headers)
│       └── error_handler.py       (Normalize {status, data, error})
├── requirements.txt        (Flask, PyJWT, pymongo, bcrypt, etc.)
└── run.py                 (Entry point)
```

### Framework

**Flask 3.x** : Léger, flexible, équipe Python.

**Routes** : RESTful, `/api/v1/...` namespace.

**Réponses** : Normalisées `{status, data, error, timestamp}`.

### Dépendances clés

| Package | Rôle |
|---|---|
| **Flask** | Framework |
| **Flask-CORS** | CORS support |
| **PyJWT** | JWT tokens |
| **pymongo** | MongoDB driver |
| **bcrypt** | Password hashing |
| **python-dotenv** | Env vars |
| **google-generativeai** | Gemini API SDK |
| **requests** | HTTP calls (weather, maps) |

### Patterns

**Middler REST** : GET, POST, PUT, DELETE sur resources.

**Authentification** : JWT token en `Authorization: Bearer <token>`.

**Validation** : Marshmallow schemas.

**Error Handling** : Custom exception classes + error handler middleware.

**Logging** : Structured logs (JSON format).

---

## 🗄️ Base de données — MongoDB (self-hosted sur Azure)

### Configuration

**Déploiement** : MongoDB sur VM Azure Standard_B2s (Ubuntu 22.04)

**Connexion** :
- **URI** : `mongodb://username:password@mongodb-vm-ip:27017/agrisense`
- **Port** : 27017 (réseau privé, pas exposé internet)
- **Authentication** : SCRAM-SHA-256
- **Network** : Container Apps → MongoDB via private subnet

### Collections (5)

| Collection | Champs clés | Rôle |
|---|---|---|
| **users** | email, password_hash, role, created_at | Authentification |
| **parcels** | user_id, name, coordinates (geo), area_ha, culture_type | Parcelles agricoles |
| **predictions** | parcel_id, user_id, weather_data, soil_data, predicted_yield_t_ha, confidence_pct, gemini_response, created_at | Prédictions IA |
| **posts** | user_id, title, content, replies[], created_at | Forum communautaire |
| **alerts** | user_id, parcel_id, type, message, read, created_at (TTL 30j) | Notifications |

### Indexes

- **users.email** : unique
- **parcels.user_id** : query optimization
- **parcels.coordinates** : geo queries (2dsphere)
- **predictions.user_id + created_at** : recent predictions
- **posts.created_at** : recent first
- **alerts.created_at** : TTL 30 jours (auto-delete)

### Requêtes typiques

| Cas d'usage | Query |
|---|---|
| Fetch user parcels | find({user_id: X}).sort({created_at: -1}) |
| Parcelles proches | find({coordinates: {$near: {$geometry: {type: Point, coords: [lat, lng]}}}}) |
| Récentes prédictions | find({user_id: X}).sort({created_at: -1}).limit(10) |
| Forum posts paginated | find({}).sort({created_at: -1}).skip(0).limit(20) |

---

## 🔗 Flux métier clés

### 1️⃣ Authentification

```
Flutter Login → POST /api/v1/auth/login {email, password}
   ↓
Flask : verify_password (bcrypt) + create_jwt
   ↓
Response : {token, user_id, role}
   ↓
Flutter : SecureStorage.saveToken()
   ↓
Futures requests : Bearer <token>
```

### 2️⃣ Gestion parcelles

```
Flutter : GET /api/v1/parcels (with JWT header)
   ↓
Flask : extract user_id from JWT
   ↓
MongoDB : find({user_id: X})
   ↓
Response : [parcel1, parcel2, ...]
   ↓
Flutter : render markers on Google Maps
```

### 3️⃣ Prédiction IA

```
Flutter : POST /api/v1/predictions {parcel_id}
   ↓
Flask Prediction Service :
  1. Fetch parcel (MongoDB)
  2. Fetch weather (Open-Meteo)
  3. Fetch soil (NASA POWER)
  4. Call Gemini API (prompt with context)
  5. Save prediction (MongoDB)
   ↓
Response : {yield, confidence_pct, advice, alerts}
   ↓
Flutter : render result (graph + recommendations)
```

### 4️⃣ Communauté

```
Flutter : GET /api/v1/posts
   ↓
Flask : MongoDB find all posts (paginated)
   ↓
Response : [{post_id, title, author, reply_count}, ...]
   ↓
User → Click post → GET /api/v1/posts/{id}
   ↓
Response : {post, replies[]}
   ↓
User → Reply → POST /api/v1/posts/{id}/replies {content}
   ↓
Flask : MongoDB insert reply in post.replies array
```

---

## 🔌 Intégrations APIs externes

### Open-Meteo (Weather)

**Endpoint** : `https://api.open-meteo.com/v1/forecast`

**Rôle** : Données météo (température, pluie, ensoleillement)

**Gratuit** : Oui (sans API key)

**Usage** : WeatherService.fetch_weather(lat, lng)

### NASA POWER (Soil)

**Endpoint** : `https://power.larc.nasa.gov/api/v1/grid`

**Rôle** : Données sol, rayonnement

**Gratuit** : Oui (sans API key)

**Usage** : WeatherService.fetch_soil_data(lat, lng)

### Gemini API (AI)

**Service** : Google AI Studio

**Rôle** : Prédiction rendement + conseils agricoles

**Pricing** : Gratuit (free tier)

**Usage** : GeminiService.predict_yield(parcel, weather_data, soil_data)

**Prompt engineering** : Context agricole (culture, région, météo, sol)

### Google Maps API

**Service** : Flutter plugin `google_maps_flutter`

**Rôle** : Visualisation parcelles, géocodage

**Pricing** : Free tier ($200/mois suffisant)

**Usage** : MapScreen affiche markers, user clicks → prédiction détail

---

## ✅ Qualité & Bonnes pratiques

### Validation

**Frontend** : Email regex, password length min, empty checks

**Backend** : Marshmallow schemas, type validation, length constraints

### Tests

**Unit tests** : Services (auth, weather, gemini)

**Integration tests** : API endpoints (login, predictions, CRUD)

**Test framework** : pytest (backend), flutter_test (frontend)

### Conventions

| Domaine | Convention | Exemple |
|---|---|---|
| Backend vars | snake_case | `fetch_parcels()`, `user_id` |
| Frontend vars | camelCase | `fetchParcels()`, `userId` |
| Routes | kebab-case | `/api/v1/user-parcels` |
| DB fields | snake_case | `created_at`, `predicted_yield_t_ha` |
| Widgets | PascalCase | `ParcelsCard`, `PredictionResult` |
| Commits | `type: message` | `feat: add prediction`, `fix: JWT refresh` |

### Comments

**Oui** : WHY non-obvious
- Calcul empirique (ex: nitrogen estimation)
- Workaround pour bug spécifique

**Non** : WHAT obvious
- Incrementing variables
- Simple loops

---

## 📊 Modèles métier

### User
- `email` : unique identifier
- `password_hash` : bcrypt
- `role` : farmer, agronomist, admin
- Permissions : farmer → own data only, admin → all

### Parcel
- `user_id` : owner
- `coordinates` : [lat, lng] polygon
- `culture_type` : blé, maïs, orge, ...
- `area_ha` : surface hectares

### Prediction
- `parcel_id`, `user_id` : links
- `weather_data` : {temp_avg, rainfall, sunshine}
- `soil_data` : {pH, moisture, nitrogen}
- `predicted_yield_t_ha` : output Gemini
- `confidence_pct` : reliability %
- `gemini_response` : {yield, advice[], alerts[]}

### Post
- `user_id` : author
- `title`, `content` : forum post
- `replies[]` : array de replies (user_id, content, created_at)

---

## 📖 Ressources connexes

- **ADR** : Décisions architecturales (pourquoi Flutter, MongoDB, etc.)
- **DAT** : Infrastructure Azure, déploiement, sécurité
- **Diagramme** : `dct_architecture.puml`

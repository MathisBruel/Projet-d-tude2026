# AgriSense — Projet d'études Bachelor 2 | Sup de Vinci 2025-26

## Contexte
Application mobile de **prédiction de rendements agricoles** commandée (fictive) par la Chambre d'Agriculture.
Projet noté : soutenance orale 15 min le **jeudi matin**, production sur **3 jours (lun–mer)**.

## Équipe
| Membre | Rôle | Niveau |
|---|---|---|
| **Mathis BRUEL** | Chef de projet, lead dev infra/cloud | Expert (Azure, Docker, Flask, intégration APIs IA) |
| **Henry TURCAS** | Dev frontend Flutter | Moyen |
| **Antoine SIMONS** | Dev backend Flask + MongoDB | Moyen |

## Stack technique
| Couche | Technologie | Notes |
|---|---|---|
| Mobile | **Flutter** (Dart) | Cross-platform Android + iOS |
| Backend | **Python Flask** | REST API, port 5000 |
| Base de données | **MongoDB** (Atlas) | NoSQL, schéma documenté en MCD/MLD |
| Cloud | **Azure** (Container Apps) | Déploiement Docker |
| Containerisation | **Docker + Docker Compose** | K8s exclu (complexité, 1 seul maîtrise) |
| IA | **Gemini API** (Google AI Studio) | Gratuit via compte Google, SDK Python |
| Carte | **Google Maps API** | SDK Flutter : `google_maps_flutter` |
| Données météo/sol | **Open-Meteo API** + **NASA POWER API** | Gratuites, sans clé pour Open-Meteo |

## Architecture haut niveau
```
[Flutter App]
      │ HTTPS/REST
      ▼
[Flask API — Docker — Azure Container Apps]
      │                        │
      ▼                        ▼
[MongoDB Atlas]         [Gemini API]
      │
      ▼
[Open-Meteo API / NASA POWER API]   ← "capteurs IoT" via vraies données publiques
```

## Structure du dépôt
```
agrisense/
├── CLAUDE.md
├── docker-compose.yml
├── .gitignore
├── doc/                        ← diagrammes PlantUML (source de vérité architecture)
│   ├── architecture_composants.puml
│   ├── architecture_reseau.puml
│   ├── modele_donnees.puml
│   ├── cas_utilisation.puml
│   ├── sequence_auth.puml
│   ├── sequence_prediction_ia.puml
│   ├── sequence_carte.puml
│   ├── deploiement.puml
│   └── backlog_moscou.puml
├── backend/                    ← Flask REST API
│   ├── app/
│   │   ├── __init__.py
│   │   ├── config.py
│   │   ├── routes/
│   │   │   ├── auth.py
│   │   │   ├── parcels.py
│   │   │   ├── predictions.py
│   │   │   ├── community.py
│   │   │   └── admin.py
│   │   ├── models/
│   │   │   ├── user.py
│   │   │   ├── parcel.py
│   │   │   ├── prediction.py
│   │   │   └── post.py
│   │   ├── services/
│   │   │   ├── gemini_service.py
│   │   │   ├── weather_service.py
│   │   │   └── auth_service.py
│   │   └── middlewares/
│   │       └── jwt_middleware.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .env.example
└── frontend/                   ← Flutter app
    ├── lib/
    │   ├── main.dart
    │   ├── core/
    │   │   ├── theme/
    │   │   ├── router/
    │   │   └── constants/
    │   ├── data/
    │   │   ├── models/
    │   │   ├── repositories/
    │   │   └── services/        ← appels HTTP vers Flask
    │   └── presentation/
    │       ├── screens/
    │       │   ├── auth/
    │       │   ├── dashboard/
    │       │   ├── map/
    │       │   ├── prediction/
    │       │   ├── community/
    │       │   └── admin/
    │       └── widgets/
    ├── pubspec.yaml
    └── Dockerfile
```

## Périmètre fonctionnel (MoSCoW)
| Priorité | Fonctionnalité |
|---|---|
| Must | Auth (login / register / JWT) |
| Must | Tableau de bord — données météo/sol en temps réel par parcelle |
| Must | Module prédiction IA via Gemini — rendement estimé + conseils |
| Must | Carte Google Maps — visualisation et gestion des parcelles |
| Should | Back-office admin — gestion utilisateurs + parcelles |
| Could | Espace communautaire — forum/messagerie entre agriculteurs |
| Won't | Capteurs IoT physiques, modèles ML custom |

## Modèles de données MongoDB (collections)
- **users** : `_id, email, password_hash, role (farmer|agronomist|admin), created_at`
- **parcels** : `_id, user_id, name, coordinates[{lat,lng}], area_ha, culture_type, created_at`
- **predictions** : `_id, parcel_id, user_id, date, weather_data{}, soil_data{}, predicted_yield_t_ha, confidence_pct, gemini_response, created_at`
- **posts** : `_id, user_id, title, content, created_at, replies[{user_id, content, created_at}]`
- **alerts** : `_id, user_id, parcel_id, type, message, read, created_at`

## Variables d'environnement (backend .env)
```
MONGO_URI=mongodb+srv://...
GEMINI_API_KEY=...
GOOGLE_MAPS_API_KEY=...
JWT_SECRET=...
FLASK_ENV=production
```

## Commandes utiles
```bash
# Dev local
docker compose up --build

# Backend seul
cd backend && pip install -r requirements.txt && flask run

# Frontend seul
cd frontend && flutter run

# Build Docker backend
docker build -t agrisense-backend ./backend

# Deploy Azure (Container Apps)
az containerapp up --name agrisense-api --resource-group agrisense-rg \
  --image agrisense-backend --target-port 5000 --ingress external
```

## APIs externes utilisées
| API | Usage | Auth |
|---|---|---|
| [Open-Meteo](https://open-meteo.com/) | Météo temps réel + historique | Aucune |
| [NASA POWER](https://power.larc.nasa.gov/api/) | Données sol + rayonnement | Aucune |
| [Gemini API](https://ai.google.dev/) | Prédiction rendement + conseils | API Key Google AI Studio |
| [Google Maps](https://developers.google.com/maps) | Carte interactive + géocodage | API Key Google Cloud |

## Critères de notation (rappel)
| Critère | Points |
|---|---|
| Démonstration technique (démo live) | 30/100 |
| Analyse besoin / problématique | 15/100 |
| Réponse au cahier des charges | 15/100 |
| Planification Trello (MoSCoW + jalons) | 10/100 |
| Qualité supports visuels | 10/100 |
| Posture et communication | 10/100 |
| Fiche projet | 5/100 |
| Organisation Agile (backlog, user stories) | 3/100 |
| Outils collaboratifs utilisés | 2/100 |

> **Priorité absolue** : ce qui sera visible lors de la démo live (30 pts). Ne pas sur-ingénier ce qui ne sera pas montré.

## Conventions de code
- Backend : snake_case, routes RESTful (`/api/v1/...`), réponses JSON normalisées `{data, error, status}`
- Frontend : camelCase, architecture feature-first, `_repository.dart` pour les appels HTTP
- Git : branches `feature/nom`, commits en français ou anglais, PR systématiques
- Pas de commentaires évidents dans le code — nommer clairement les fonctions

# DAT — Document d'Architecture Technique
## Infrastructure, Déploiement, Sécurité
## AgriSense — Projet d'études Bachelor 2

**Date** : 2026-04-27 | **Version** : 1.0

---

## 🏗️ Architecture infrastructure

```
Internet (HTTPS)
    ↓
Azure Container Apps (agrisense-api)
  ├─ Replicas: 2-5 (auto-scaling)
  ├─ Port: 5000 (internal) → 443 (HTTPS ingress)
  └─ Health check: GET /api/v1/health
    ↓
├─ MongoDB VM (Standard_B2s)
│   ├─ Ubuntu 22.04 LTS
│   ├─ Port 27017 (private, Container Apps only)
│   ├─ Collections: users, parcels, predictions, posts, alerts
│   ├─ Backup: Daily snapshots + mongodump
│   └─ Replication: Standalone (Replica Set future)
│
├─ Azure Key Vault (Secrets)
│   ├─ MONGO_URI
│   ├─ GEMINI_API_KEY
│   ├─ GOOGLE_MAPS_API_KEY
│   └─ JWT_SECRET
│
└─ External APIs (via Container Apps)
    ├─ Open-Meteo (weather)
    ├─ NASA POWER (soil)
    ├─ Gemini API (AI)
    └─ Google Maps (geocoding)
```

---

## ☁️ Infrastructure Azure

### Ressources principales

| Ressource | Type | Rôle | Région |
|---|---|---|---|
| **agrisense-rg** | Resource Group | Conteneur logique | West Europe |
| **agrisense-api** | Container Apps | Déploiement Flask | West Europe |
| **agrisense-db-vm** | Virtual Machine | MongoDB server | West Europe |
| **agrisense-db-disk** | Managed Disk | MongoDB data storage | West Europe |
| **agrisense-kv** | Key Vault | Secrets (env vars) | West Europe |
| **agrisense-log** | Log Analytics | Logs centralisés | West Europe |
| **agrisense-acr** | Container Registry | Docker images | West Europe |

### Azure Container Apps

**Choix** : Déploiement serverless, pas de VM.

**Config** :
- **Image** : Python Flask 3.11, port 5000
- **Replicas** : Min 2, Max 5 (auto-scaling CPU > 70%)
- **Ingress** : External HTTPS (TLS auto)
- **Health** : GET `/api/v1/health` (readiness + liveness)
- **Timeout** : 60s (pour Gemini API)

**Avantages** :
- ✅ Zéro infra ops (pas de VMs, pas de K8s)
- ✅ Auto-scaling automatique
- ✅ TLS certificate auto-renouvelé
- ✅ Logs directs dans Azure Monitor
- ✅ Rolling deployments (0-downtime)

---

## 📦 Conteneurisation

### Docker

**Images** :
- `agrisense-backend:latest` (Flask API)
- `agrisense-backend:v1.0.0` (tagged release)

**Fichiers** :
- `backend/Dockerfile` : Flask app
- `docker-compose.yml` : Dev local

**Optimisations** :
- Image slim (~150 MB)
- Health check intégré
- Non-root user (sécurité)

### Docker Compose (dev local)

**Services** :
- **mongodb** : Port 27017
- **backend** : Port 5000 (Flask)
- **frontend** : Port 8080 (Flutter)

**Commande** : `docker compose up --build`

---

## 🚀 Déploiement & CI/CD

### GitHub Actions Pipeline

**Trigger** : `git push main`

**Steps** :
1. Build Docker image
2. Push to Azure Container Registry (ACR)
3. Deploy to Container Apps (rolling update)
4. Health check

**Stratégie** : Rolling update (0-downtime)

### Environnements

| Env | Branch | Auto-deploy |
|---|---|---|
| Dev | `feature/*` | Local docker-compose |
| Staging | `develop` | Automatic |
| Prod | `main` | Manual approval |

---

## 🔒 Sécurité

### HTTPS/TLS
- ✅ Obligatoire tous endpoints
- ✅ TLS 1.2+ (Azure enforces)
- ✅ Certificate auto-renouvelé
- ✅ HSTS header activé

### Authentification
- **JWT** : Stateless, signature HS256, expiration 24h
- **Roles** : farmer, agronomist, admin
- **Passwords** : Bcrypt hash

### Secrets Management
- **Azure Key Vault** : Centralisé
- **Managed Identity** : Zéro clés locales
- **Audit logs** : Tous accès tracés

**Secrets** :
- `MONGO_URI`
- `GEMINI_API_KEY`
- `GOOGLE_MAPS_API_KEY`
- `JWT_SECRET`

### Sécurité applicative
- **Validation** : Toutes entrées validées
- **Rate limiting** : Auth (5/min), predictions (50/min)
- **CORS** : Origins restrictif
- **Logs** : Sans secrets, 90j retention

---

## 🗄️ Base de données — MongoDB (self-hosted sur Azure)

### Infrastructure MongoDB

**Déploiement** : VM Azure Standard_B2s (2 vCPU, 4 GB RAM)

**Système d'exploitation** : Ubuntu 22.04 LTS

**Stockage** : 
- OS disk : 30 GB (managed disk)
- Data disk : 100+ GB (MongoDB data + backups)

**Configuration** :
- **Port** : 27017 (interne, pas exposé internet)
- **Authentication** : username/password (SCRAM-SHA-256)
- **Replication** : Standalone (OK pour démo), Replica Set possible après

### Collections

| Collection | Données | Indexes clés |
|---|---|---|
| **users** | Email, password, role | email (unique) |
| **parcels** | Nom, coords, surface | user_id, coordinates (geo) |
| **predictions** | Yield, confidence, IA response | parcel_id, created_at |
| **posts** | Forum posts + replies | user_id, created_at |
| **alerts** | Notifications (TTL 30j) | user_id, read |

### Sécurité DB
- ✅ Firewall Azure : Container Apps IPs only
- ✅ Authentication : Username/password
- ✅ Network : Private (pas exposé internet)
- ✅ TLS optionnel (self-signed cert possible)

### Maintenance & Backup

**Backups** :
- Snapshots Azure (VM-level) : quotidien
- Dump MongoDB : `mongodump` (scripted)
- Retention : 7 jours
- Stored : Azure Blob Storage

**Monitoring** :
- CPU, memory via Azure Monitor
- MongoDB logs : `/var/log/mongodb/mongod.log`
- Query stats : `db.currentOp()`, slow query logs

**Upgrade** : Manuel (stop → upgrade → restart)

---

## 📊 Observabilité & Monitoring

### Azure Monitor
- **Collecte** : HTTP requests, exceptions, CPU, memory
- **Logs** : Centralisés, queryable (KQL)
- **Retention** : 90 jours
- **Export** : CSV possible

### Alertes

| Métrique | Seuil | Action |
|---|---|---|
| HTTP 5xx | > 5/min | Alert Slack |
| Latency p99 | > 5s | Investigation |
| CPU | > 80% | Auto-scale |
| Memory | > 85% | Alert |

### Dashboard
- Requests timeline
- Error rates
- Latency histogram
- Resource utilization

---

## 💰 Coûts estimés (mensuel)

| Service | Coût |
|---|---|
| Container Apps (2-5 replicas) | 20-40€ |
| MongoDB VM (Standard_B2s) | 30-40€ |
| Storage (100 GB disk) | 5€ |
| Log Analytics | 5€ |
| Key Vault | 1€ |
| **Total** | **61-91€** |

**Note** : Azure Student credit suffit pour démo. Optimisation possible via Spot VMs (50% réduction).

---

## ✅ Checklist pré-déploiement

- [ ] Secrets dans Key Vault (pas en code)
- [ ] HTTPS + TLS 1.2+ activé
- [ ] Health check testé
- [ ] Logs structurés
- [ ] Rate limiting configuré
- [ ] CORS restrictions
- [ ] DB backup testé
- [ ] CI/CD workflow passant
- [ ] Monitoring alertes actives
- [ ] Doc déploiement à jour

---

## 🔄 Disaster Recovery

| Scénario | RTO | Stratégie |
|---|---|---|
| Container crash | < 1 min | Auto-restart + replicas |
| Code bug | < 5 min | Rollback image |
| DB data loss | < 30 min | Snapshot restore |
| API quota exceeded | Manual | Cache + queue |

---

## 📖 Ressources connexes

- **ADR** : Justification des décisions architecturales
- **DCT** : Stack logiciel et architecture applications
- **Diagramme** : `dat_architecture.puml`

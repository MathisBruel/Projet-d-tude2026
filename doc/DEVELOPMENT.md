# Développement Local — AgriSense

## 🚀 Quick Start (Docker)

### Démarrer l'environnement de dev
```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up
```

Cela va :
- ✅ Build le backend depuis `./backend`
- ✅ Compiler le Dockerfile localement (pas d'image externe)
- ✅ Monter les volumes pour hot-reload
- ✅ Démarrer MongoDB en parallèle
- ✅ Exposer le backend sur `localhost:5000`

### Accéder à l'API
```bash
curl http://localhost:5000/health
```

---

## 📁 Structure Fichiers Dev

```
Projet-Etudes-2026/
├── docker-compose.yml           ← Production (ghcr.io images)
├── docker-compose.dev.yml       ← Development (local builds)
├── backend/
│   ├── Dockerfile               ← Build backend
│   ├── app/
│   ├── requirements.txt
│   └── .env                     ← Needs MONGO_URI, etc.
├── frontend/
│   ├── lib/
│   └── pubspec.yaml
└── docker/
    └── (optional Docker configs)
```

---

## 🔧 Configuration Dev

### 1️⃣ Backend `.env`
```bash
nano backend/.env
```

Contenu minimal pour dev :
```env
MONGO_URI=mongodb://mongodb:27017/agrisense
GEMINI_API_KEY=your_test_key_or_skip
GOOGLE_MAPS_API_KEY=your_test_key_or_skip
JWT_SECRET=dev_secret_123
FLASK_ENV=development
FLASK_DEBUG=1
```

### 2️⃣ Démarrer

```bash
# Avec Docker (recommandé)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up

# Sans Docker (local Python + MongoDB)
cd backend
pip install -r requirements.txt
flask run
```

---

## 💻 Workflows Dev

### Avec Docker

**Backend changes** :
```bash
# 1. Edit backend code
# 2. Changes reload automatically (FLASK_DEBUG=1)
# 3. Check http://localhost:5000

# View logs
docker compose logs -f backend
```

**MongoDB** :
```bash
# Access MongoDB CLI
docker compose exec mongodb mongosh agrisense

# or via Docker
mongo mongodb://localhost:27017/agrisense
```

**Rebuild** (if dependencies change) :
```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

**Reset** (clean slate) :
```bash
docker compose down -v
docker compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### Sans Docker

**Backend local**:
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

pip install -r requirements.txt
export MONGO_URI=mongodb://localhost:27017/agrisense
flask run
```

**MongoDB local** (requires install):
```bash
mongod
```

**Frontend local**:
```bash
cd frontend
flutter pub get
flutter run  # Pick your target (web/android/ios)
```

---

## 🐍 Backend Development

### Install new package
```bash
# With Docker
docker compose exec backend pip install package_name

# Without Docker
cd backend
pip install package_name
pip freeze > requirements.txt  # Update requirements
```

### Run tests
```bash
# With Docker
docker compose exec backend pytest

# Without Docker
cd backend
pytest
```

### Linting
```bash
# With Docker
docker compose exec backend pylint app/

# Without Docker
cd backend
pylint app/
```

### Debug Flask
```python
# In your Python code
from flask import current_app
current_app.logger.info("Debug message")

# View in logs
docker compose logs -f backend
```

---

## 📱 Frontend Development

### Setup Flutter
```bash
# Install Flutter SDK
# See: https://flutter.dev/docs/get-started/install

flutter --version
flutter pub get

# Run on device/emulator
flutter run
```

### Flutter web (optional)
```bash
flutter run -d web --web-port 3000
# Visit http://localhost:3000
```

---

## 🔌 API Endpoints (Dev)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Health check |
| `/api/v1/auth/register` | POST | Register user |
| `/api/v1/auth/login` | POST | Login |
| `/api/v1/parcels` | GET | List user's parcels |
| `/api/v1/predictions` | POST | Create prediction |

### Example API call
```bash
curl -X POST http://localhost:5000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123"}'
```

---

## 🐛 Troubleshooting Dev

| Problem | Solution |
|---------|----------|
| Port 5000 in use | `lsof -i :5000` → `kill PID` or use different port |
| MongoDB connection fail | Check `MONGO_URI` in `.env` |
| Hot reload not working | Add file to `.dockerignore` or restart container |
| Requirements not updated | Rebuild: `docker compose up --build` |
| Permission denied on mount | Check file ownership: `sudo chown -R $USER backend/` |

---

## 📊 Compose Files

### `docker-compose.yml` (Production)
- Images: `ghcr.io/*` (pulled from registry)
- No volumes (immutable)
- No FLASK_DEBUG
- Port 5001 (consistent with prod)

### `docker-compose.dev.yml` (Development)
- Builds: local Dockerfile
- Volumes: source code mounted
- FLASK_DEBUG=1 (hot reload)
- Port 5000 (Flask default)

### Combined usage
```bash
# Dev mode (uses .dev overrides)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up

# Prod mode (just main file)
docker compose -f docker-compose.yml up
```

---

## 💡 Tips

✅ **Use Docker for consistency** with deployment
✅ **Use local for speed** if already have deps installed
✅ **Hot reload enabled** — changes reflect immediately
✅ **Rebuild on requirements.txt change** — `docker compose up --build`
✅ **Clean volumes** to reset database — `docker compose down -v`

---

## 🔗 References

- [Flask Debug Mode](https://flask.palletsprojects.com/en/latest/server/#the-built-in-server)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Flask Development](https://flask.palletsprojects.com/en/latest/development/)
- [Flutter Development](https://flutter.dev/docs/get-started/editor)

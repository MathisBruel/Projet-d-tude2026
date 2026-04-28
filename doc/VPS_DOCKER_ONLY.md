# VPS Configuration — Docker-Only (No Code)

## 📋 Architecture

Le VPS **n'héberge que les conteneurs Docker**, pas le code source.

```
GitHub Repository (Code)
    ↓
GitHub Actions
├─ Compile Docker images
├─ Push to ghcr.io
└─ Déploie sur VPS

VPS (Containers only)
├─ docker-compose.yml (management)
├─ .env (variables d'environnement)
├─ /data (MongoDB volume)
└─ Containers:
   ├─ backend (from ghcr.io)
   ├─ frontend (from ghcr.io)
   └─ mongodb (local)
```

---

## 🚀 Avantages

✅ VPS léger (pas de repo, pas de buildtools)
✅ Images à jour = images du dernière build CI
✅ Déploiement rapide (juste docker pull)
✅ Facile de rollback (pas de git revert complexe)
✅ Scaling simple (juste docker compose up)

---

## 📦 Fichiers sur le VPS

```
/opt/agrisense/
├── docker-compose.yml          ← Pushé via SCP par GitHub Actions
├── .env                        ← Configuration manuelle
├── .gitkeep                    ← (vide, juste tracker)
└── data/                       ← Persistance MongoDB
    └── db/
```

**Aucun fichier source** — tout vient du Docker Registry.

---

## ⚙️ Configuration initiale du VPS

### 1. Lancer le script de setup
```bash
cd /tmp
curl -o vps-setup.sh https://raw.githubusercontent.com/mathisbruel/Projet-Etudes-2026/main/scripts/vps-setup.sh
sudo bash vps-setup.sh
```

### 2. Créer le `docker-compose.yml` sur le VPS
```bash
# Copier depuis le repo (ou créer manuellement)
cat > /opt/agrisense/docker-compose.yml << 'EOF'
services:
  backend:
    image: ghcr.io/mathisbruel/projet-etudes-2026-backend:latest
    ports:
      - "5001:5000"
    env_file:
      - ./backend/.env
    restart: unless-stopped
    depends_on:
      - mongodb

  mongodb:
    image: mongo:latest
    container_name: mongodb
    ports:
      - "27017:27017"
    volumes:
      - ./data:/data/db
    restart: unless-stopped
EOF
```

### 3. Créer le `.env`
```bash
mkdir -p /opt/agrisense/backend
nano /opt/agrisense/backend/.env
```

Contenu `.env` :
```env
MONGO_URI=mongodb://mongodb:27017/agrisense
GEMINI_API_KEY=your_key_here
GOOGLE_MAPS_API_KEY=your_key_here
JWT_SECRET=your_secret_here
FLASK_ENV=production
```

### 4. Authentifier Docker
```bash
docker login ghcr.io
# Username: ton_github_username
# Password: Personal Access Token (Settings → Developer settings → Personal access tokens)
```

### 5. Déploiement manuel (test)
```bash
cd /opt/agrisense
docker compose pull
docker compose up -d
docker compose logs -f backend
```

---

## 🔄 Workflow CD (automatique)

À chaque push sur `main` :

```
1. GitHub Actions CI
   ├─ Build images
   └─ Push to ghcr.io

2. GitHub Actions CD
   ├─ SCP docker-compose.yml → VPS
   ├─ SSH sur VPS :
   │  ├─ docker login ghcr.io
   │  ├─ docker compose pull
   │  └─ docker compose up -d
   └─ Health check

3. VPS
   ├─ Télécharge les nouvelles images
   ├─ Redémarre les containers
   └─ ✅ Live!
```

---

## 🔐 Secrets GitHub

| Secret | Description |
|--------|-------------|
| `VPS_HOST` | IP ou domaine VPS |
| `VPS_USER` | Utilisateur SSH |
| `VPS_SSH_KEY` | Clé privée SSH |
| `VPS_SSH_PORT` | Port SSH (défaut 22) |
| `VPS_DEPLOY_PATH` | `/opt/agrisense` |
| `GITHUB_TOKEN` | Auto-généré (pour docker login) |

---

## 🔄 Mise à jour du code

### Workflow normal
```bash
# Sur ta machine locale
git commit -am "feat: nouvelle fonctionnalité"
git push origin main

# ⏳ GitHub Actions :
#   1. Compile les images
#   2. Push à ghcr.io
#   3. Déploie sur VPS

# ✅ Le VPS récupère les nouvelles images
```

### Test avant de déployer
```bash
# Développer sur une branche develop
git push origin develop

# CI s'exécute (valide la qualité)
# CD n'exécute pas (seulement sur main)

# Merger sur main quand validé
git checkout main
git merge develop
git push origin main

# CD se déclenche → déploiement
```

---

## 🔧 Opérations courantes

### Voir les containers en cours
```bash
cd /opt/agrisense
docker compose ps
```

### Voir les logs
```bash
docker compose logs -f backend
docker compose logs -f mongodb
```

### Redémarrer un container
```bash
docker compose restart backend
```

### Full reset
```bash
cd /opt/agrisense
docker compose down
docker compose pull
docker compose up -d
```

### Vérifier la santé de l'API
```bash
curl http://localhost:5001/health
```

---

## 🆘 Troubleshooting

### ❌ "No such file or directory: docker-compose.yml"
**Cause** : Le fichier n'a pas été copié
**Solution** :
```bash
# Copier manuellement depuis le repo
git clone https://github.com/mathisbruel/Projet-Etudes-2026.git
cp Projet-Etudes-2026/docker-compose.yml /opt/agrisense/
```

### ❌ "denied: permission_denied"
**Cause** : Docker pas authentifié auprès de ghcr.io
**Solution** :
```bash
docker login ghcr.io
docker compose pull
```

### ❌ "Containers keep restarting"
**Cause** : `.env` manquant ou invalide
**Solution** :
```bash
docker compose logs backend
# Vérifier les variables d'environnement
```

### ❌ "Connection refused" sur MongoDB
**Cause** : MongoDB ne démarre pas
**Solution** :
```bash
# Vérifier les volumes
docker compose logs mongodb
ls -la /opt/agrisense/data/

# Recréer si nécessaire
docker compose down -v
docker compose up -d
```

---

## 💾 Sauvegardes

### MongoDB data
```bash
# Backupper les données
docker exec mongodb mongodump --out /backup

# ou via le volume
tar -czf mongo-backup.tar.gz /opt/agrisense/data/
```

### Configuration
```bash
# Sauvegarder .env
cp /opt/agrisense/backend/.env /backups/.env.backup
```

---

## 📊 Monitoring

### Santé générale
```bash
cd /opt/agrisense
docker compose ps
docker system df
```

### Logs en temps réel
```bash
docker compose logs -f
```

### Utilisation des ressources
```bash
docker stats
```

---

## 🛡️ Sécurité

✅ **À faire**
- [ ] Firewall configuré (UFW)
- [ ] Mot de passe SSH fort
- [ ] 2FA sur GitHub
- [ ] Personal Access Token avec permissions minimales
- [ ] `.env` bien protégé (600 permissions)

❌ **À ne pas faire**
- Ne pas commiter `.env`
- Ne pas exposer les secrets dans les logs
- Ne pas utiliser root pour docker

---

## 🎯 Checklist Déploiement Initial

- [ ] Script `vps-setup.sh` exécuté
- [ ] Docker et Docker Compose installés
- [ ] `/opt/agrisense/` créé
- [ ] `docker-compose.yml` copié sur VPS
- [ ] `backend/.env` configuré avec vraies clés
- [ ] `docker login ghcr.io` exécuté
- [ ] Secrets GitHub configurés (VPS_HOST, VPS_USER, VPS_SSH_KEY, VPS_DEPLOY_PATH)
- [ ] `docker compose pull` exécuté
- [ ] `docker compose up -d` exécuté
- [ ] `curl http://localhost:5001/health` répond

---

## 💡 Tips

**Test du workflow CD manuellement** :
```
GitHub UI → Actions → CD - Deploy to VPS → Run workflow
```

**Rollback rapide** :
```bash
# Pull l'ancienne version
docker pull ghcr.io/mathisbruel/projet-etudes-2026-backend:sha-<old_commit>
# Éditer docker-compose.yml pour utiliser ce tag
docker compose up -d
```

**Monitoring du déploiement** :
```
GitHub UI → Actions → [Latest Run] → deploy → Script output
```

---

## 📚 Ressources

- [Docker Compose Docs](https://docs.docker.com/compose/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [appleboy/scp-action](https://github.com/appleboy/scp-action)

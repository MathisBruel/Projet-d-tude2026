# Déploiement AgriSense — VPS Deployment

## 📋 Pourquoi pas de Cloud (Azure) ?

### Problème d'Azure Student
- **Compte étudiant bloqué par régions** : Restrictions géographiques strict
- **Aucune création possible** : VM, Container Apps, bases de données — tout refusé
- **Limitation critique** : Compte 100% inutilisable pour le déploiement
- **Temps perdu** : Temps de projet écoulé, impossible d'attendre approbation Microsoft

### Solution adoptée
✅ **Déploiement sur VPS personnel** à disposition
✅ **CI/CD via GitHub Actions** (gratuit, pas de contrainte)
✅ **Docker Compose** pour orchestration (léger, suffisant)

---

## 🚀 Architecture Déploiement

```
GitHub Push (main)
    ↓
GitHub Actions CI
├─ Build backend Docker → ghcr.io
├─ Lint code
└─ ✅ PASSED
    ↓
GitHub Actions CD
├─ SSH → VPS
├─ docker compose pull
└─ docker compose up -d
    ↓
✅ Live on VPS:5001
```

---

## ⚙️ Configuration du VPS

### Prérequis VPS
```bash
# Installer Docker + Compose
curl -fsSL https://get.docker.com | sh
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Répertoires
```
/opt/agrisense/
├── docker-compose.yml         ← Poussé par GitHub Actions
├── backend/
│   └── .env                   ← À configurer manuellement
└── data/
    └── (MongoDB volumes)
```

### Configuration VPS (.env)
```bash
mkdir -p /opt/agrisense/backend
nano /opt/agrisense/backend/.env
```

Contenu `.env` :
```env
MONGO_URI=mongodb://mongodb:27017/agrisense
GEMINI_API_KEY=AIzaSy...
GOOGLE_MAPS_API_KEY=AIzaSy...
JWT_SECRET=secret_complexe_ici
FLASK_ENV=production
```

---

## 🔐 Secrets GitHub

Configurer dans : **Settings → Secrets and variables → Actions**

| Secret | Valeur |
|--------|--------|
| `VPS_HOST` | IP ou domaine VPS |
| `VPS_USER` | Utilisateur SSH (ubuntu, root, etc.) |
| `VPS_SSH_KEY` | Clé privée SSH |
| `VPS_SSH_PORT` | 22 (ou custom) |
| `VPS_DEPLOY_PATH` | /opt/agrisense |

### Générer clé SSH
```bash
ssh-keygen -t ed25519 -f ~/.ssh/agrisense_deploy -N ""

# Copier clé publique sur VPS
ssh-copy-id -i ~/.ssh/agrisense_deploy.pub user@vps_ip

# Copier clé privée → secret VPS_SSH_KEY
cat ~/.ssh/agrisense_deploy
```

---

## 📤 Déploiement

### Automatique (push main)
```bash
git push origin main
# → CI compile images
# → CD déploie sur VPS
```

### Manuel
```
GitHub UI → Actions → CD - Deploy to VPS → Run workflow
```

---

## 📋 Opérations VPS

### Voir les containers
```bash
cd /opt/agrisense
docker compose ps
```

### Logs
```bash
docker compose logs -f backend
docker compose logs -f mongodb
```

### Redémarrer
```bash
docker compose restart backend
```

### Full reset
```bash
docker compose down
docker compose pull
docker compose up -d
```

### Health check
```bash
curl http://localhost:5001/health
```

---

## 🔍 Troubleshooting

| Problème | Solution |
|----------|----------|
| Image not found | CI n'a pas compilé → vérifier GitHub Actions |
| Permission denied | `sudo chown -R user:user /opt/agrisense` |
| Container restart loop | Vérifier `.env` manquant/invalide → `docker logs` |
| MongoDB connection fail | `docker compose logs mongodb` |

---

## 📚 Documentation Détaillée

- **[VPS_DEPLOYMENT_QUICKSTART.md](VPS_DEPLOYMENT_QUICKSTART.md)** — Quick start 5 min
- **[CI-CD-WORKFLOW.md](CI-CD-WORKFLOW.md)** — Architecture CI/CD complète

---

## ✅ Checklist Déploiement

- [ ] Docker installé sur VPS
- [ ] Répertoire `/opt/agrisense` créé
- [ ] `backend/.env` configuré avec vraies clés
- [ ] Secrets GitHub configurés (VPS_HOST, VPS_USER, VPS_SSH_KEY, etc.)
- [ ] Clé SSH fonctionnelle (test SSH manuel)
- [ ] `docker compose pull` marche localement
- [ ] Premier push sur main → CI compile → CD déploie

---

## 🎯 Résumé

```
Azure Student = Bloqué ❌
VPS Perso + GitHub Actions = Opérationnel ✅
```

Simple, rapide, sans dépendance cloud problématique.

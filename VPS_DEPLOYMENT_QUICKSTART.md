# 🚀 VPS Deployment — Quick Start

## ℹ️ Important
**Le VPS n'héberge QUE les containers Docker** — Pas de code source, pas de git repo.
Les images sont pull depuis GitHub Container Registry à chaque déploiement.

## TL;DR (5 min setup)

### Sur ton VPS (une seule fois)
```bash
# 1. Lancer le setup (installe Docker)
curl -o /tmp/vps-setup.sh https://raw.githubusercontent.com/mathisbruel/Projet-Etudes-2026/main/scripts/vps-setup.sh
sudo bash /tmp/vps-setup.sh

# 2. Créer le docker-compose.yml
mkdir -p /opt/agrisense
# Copier depuis repo ou créer manuellement (voir doc/VPS_DOCKER_ONLY.md)

# 3. Configurer les variables d'environnement
mkdir -p /opt/agrisense/backend
nano /opt/agrisense/backend/.env

# 4. Authentifier Docker pour ghcr.io
docker login ghcr.io
# Username: ton_username_github
# Password: Personal Access Token (Settings → Developer settings → Tokens)

# 5. Test manuel
cd /opt/agrisense
docker compose pull
docker compose up -d
```

### Sur GitHub (une seule fois)
Aller à : **https://github.com/mathisbruel/Projet-Etudes-2026/settings/secrets/actions**

Créer ces secrets :

| Secret | Valeur | Exemple |
|--------|--------|---------|
| `VPS_HOST` | IP ou domaine du VPS | `192.168.1.100` ou `monvps.com` |
| `VPS_USER` | Utilisateur SSH | `ubuntu` |
| `VPS_SSH_PORT` | Port SSH (optionnel) | `22` |
| `VPS_SSH_KEY` | Contenu de ta clé privée SSH | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `VPS_DEPLOY_PATH` | Chemin de déploiement | `/opt/agrisense` |

**Comment générer la clé SSH** :
```bash
# Sur ta machine locale
ssh-keygen -t ed25519 -f ~/.ssh/agrisense_deploy -N ""
cat ~/.ssh/agrisense_deploy.pub  # → Ajouter au VPS ~/.ssh/authorized_keys
cat ~/.ssh/agrisense_deploy      # → Copier dans le secret VPS_SSH_KEY
```

---

## ✅ Déploiement automatique

Dès que tu fais un `git push origin main`, deux workflows s'exécutent :

### 1️⃣ CI (Build & Test)
1. ✅ Compile l'image Docker du backend
2. ✅ Compile l'image Docker du frontend
3. ✅ Lint du code (pylint, flutter analyze)
4. ✅ Push vers GitHub Container Registry
5. ⏳ Attendre validation avant CD

### 2️⃣ CD (Deploy to VPS)
6. ✅ **Déploie automatiquement sur ton VPS via SSH**
7. ✅ Health check du backend
8. ✅ Confirmation du déploiement

## 🔍 Vérifier que ça marche

```bash
# Sur VPS
docker ps
docker compose logs -f backend

# Teste l'API
curl http://localhost:5001/health
```

---

## 📚 Documentation

- **[doc/VPS_DOCKER_ONLY.md](doc/VPS_DOCKER_ONLY.md)** — VPS Docker-only (architecture, setup détails)
- **[doc/CI-CD-WORKFLOW.md](doc/CI-CD-WORKFLOW.md)** — Architecture CI/CD (comprendre les workflows)
- **[doc/vps-deployment.md](doc/vps-deployment.md)** — Setup complet avec git repo (legacy, non utilisé)

## 🆘 Support rapide

| Problème | Cause | Solution |
|----------|-------|----------|
| "Permission denied (publickey)" | Clé SSH invalide | Vérifier `~/.ssh/authorized_keys` sur VPS |
| "docker: command not found" | Docker pas installé | Relancer `sudo bash scripts/vps-setup.sh` |
| Containers "Restarting" | .env manquant/invalide | `docker compose logs backend` |
| "denied: permission_denied" | GitHub token invalide | `docker login ghcr.io` sur VPS |

---

## 🔄 Workflow CI/CD

```
Ta machine locale          GitHub                       VPS
       │                      │                         │
       │  git push main       │                         │
       ├─────────────────────>│                         │
       │                      │ ┌─ CI Workflow ─┐       │
       │                      │ │ • Build backend      │
       │                      │ │ • Build frontend     │
       │                      │ │ • Lint code          │
       │                      │ │ • Push to ghcr.io    │
       │                      │ └──────────────┘       │
       │                      │    ↓ (if success)     │
       │                      │ ┌─ CD Workflow ─┐      │
       │                      │ │ • SSH → VPS   │      │
       │                      │ │ • git pull    │      │
       │                      │ │ • docker pull │      │
       │                      ├─────────────────────>  │
       │                      │                 docker up
       │                      │                 health check
       │                      │                         │
       │<─────────────────────┼─────────────────────────┤
       │      ✅ Done!        │     ✅ Live             │
```

### Workflows
- **CI** (`.github/workflows/ci.yml`) : Build, test, push images
- **CD** (`.github/workflows/cd.yml`) : Deploy sur VPS après CI success

---

## 🛡️ Sécurité

⚠️ **IMPORTANT**
- Ne **jamais** commiter `.env` ou les clés privées
- Utiliser des Personal Access Tokens avec permissions **minimales**
- Rotationner les secrets tous les 6 mois
- Vérifier les logs GitHub Actions pour les fuites

---

## 💡 Tips

- **Test manuel du workflow** : GitHub UI → Actions → Deploy to VPS → Run workflow
- **Logs temps réel** : `docker compose logs -f backend` sur VPS
- **Rollback rapide** : `git revert <commit_id>` + push (redéploiement auto)
- **Logs GitHub Actions** : https://github.com/mathisbruel/Projet-Etudes-2026/actions

---

*Besoin d'aide ?* Voir [doc/vps-deployment.md](doc/vps-deployment.md)

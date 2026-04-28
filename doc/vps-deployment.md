# Déploiement AgriSense sur VPS — Guide Complet

## Architecture
```
GitHub Push (main)
    ↓
GitHub Actions Workflow (.github/workflows/deploy.yml)
    ├─ Build backend → Push to ghcr.io
    ├─ Build frontend → Push to ghcr.io
    └─ SSH Deploy → VPS
         ↓
    VPS (~opt/agrisense)
        ├─ git pull origin main
        ├─ docker compose pull
        └─ docker compose up -d
```

## Prérequis

### Sur ton VPS
- Ubuntu 20.04+ ou Debian 11+
- SSH activé
- Au minimum 2GB RAM disponible
- Port 5001 disponible (backend Flask)
- Port 27017 disponible (MongoDB, optionnel si distant)

### Sur GitHub
- Accès aux **Settings → Secrets and variables → Actions** du repo

---

## Étape 1 : Configuration du VPS

### 1.1 Cloner le repo et lancer le setup script
```bash
# En tant qu'utilisateur normal (avec sudo disponible)
cd /tmp
git clone https://github.com/mathisbruel/Projet-Etudes-2026.git
cd Projet-Etudes-2026
sudo bash scripts/vps-setup.sh
```

Ce script installe :
- Docker + Docker Compose
- Crée le répertoire de déploiement (`/opt/agrisense` par défaut)
- Configure Git pour les pulls automatiques

### 1.2 Configurer les variables d'environnement
```bash
nano /opt/agrisense/backend/.env
```

Remplir :
```env
MONGO_URI=mongodb://mongodb:27017/agrisense
GEMINI_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
GOOGLE_MAPS_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
JWT_SECRET=votre_secret_jwt_complexe_ici
FLASK_ENV=production
```

### 1.3 Configurer Docker pour GitHub Container Registry
```bash
# Générer un Personal Access Token sur GitHub
# Settings → Developer settings → Personal access tokens → Tokens (classic)
# Sélectionner les permissions: repo, write:packages, read:packages

# Sur le VPS, authentifier Docker:
docker login ghcr.io
# Username: ton_username_github
# Password: ton_personal_access_token
```

---

## Étape 2 : Configurer les Secrets GitHub

Aller sur : **https://github.com/mathisbruel/Projet-Etudes-2026/settings/secrets/actions**

### Secrets à créer

#### `VPS_HOST`
Adresse IP ou domaine de ton VPS
```
exemple.com
ou
192.168.1.100
```

#### `VPS_USER`
Nom d'utilisateur SSH (généralement `root` ou `ubuntu`, `debian`, etc.)
```
ubuntu
```

#### `VPS_SSH_PORT` (optionnel, défaut = 22)
Port SSH si différent du 22
```
22
```

#### `VPS_SSH_KEY`
Clé SSH privée pour accès au VPS

##### Générer une clé SSH (si tu n'en as pas) :
```bash
# Sur ta machine locale
ssh-keygen -t ed25519 -C "agrisense-deploy" -f ~/.ssh/agrisense_deploy -N ""

# Afficher la clé publique
cat ~/.ssh/agrisense_deploy.pub
```

##### Ajouter la clé publique au VPS :
```bash
# Sur le VPS (en tant que l'utilisateur SSH)
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Ajouter la clé publique au fichier authorized_keys
echo "ssh-ed25519 AAAA... votre_clé_publique" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

##### Copier la clé privée vers GitHub Secret :
```bash
# Sur ta machine locale
cat ~/.ssh/agrisense_deploy
# Copier le contenu complet (y compris BEGIN/END) et le coller dans le secret VPS_SSH_KEY
```

#### `VPS_DEPLOY_PATH`
Chemin où sont les fichiers deployés
```
/opt/agrisense
```

---

## Étape 3 : Lancer le premier déploiement

### Option A : Manual trigger (test)
1. Aller sur : https://github.com/mathisbruel/Projet-Etudes-2026/actions
2. Sélectionner le workflow **"Deploy to VPS"**
3. Cliquer sur **"Run workflow"** → **"Run workflow"**

### Option B : Automatic (push sur main)
```bash
# Sur ta machine locale
git add .
git commit -m "chore: configure VPS deployment"
git push origin main

# Le workflow se déclenche automatiquement
```

### Vérifier le déploiement
Dans GitHub Actions, tu dois voir :
- ✅ **build-backend** (5-10 min)
- ✅ **build-frontend** (10-15 min)
- ✅ **deploy** (1-2 min)

Sur le VPS :
```bash
# Vérifier les containers
docker ps

# Vérifier les logs
docker compose logs -f backend

# Vérifier que le backend répond
curl http://localhost:5001/health
```

---

## Dépannage

### ❌ Erreur : "Permission denied (publickey)"
**Cause** : Clé SSH mal configurée
**Solution** :
```bash
# Vérifier la clé sur VPS
cat ~/.ssh/authorized_keys

# Vérifier les permissions
ls -la ~/.ssh/
# authorized_keys doit avoir 600
# ~/.ssh/ doit avoir 700
```

### ❌ Erreur : "docker: command not found"
**Cause** : Docker pas installé
**Solution** : Relancer le script de setup avec sudo

### ❌ Les containers restent "Restarting"
**Cause** : Variable d'environnement .env manquante/invalide
**Solution** :
```bash
docker compose logs backend
# Vérifier MONGO_URI, GEMINI_API_KEY, etc.
```

### ❌ "denied: permission_denied"
**Cause** : GitHub Token pas correctement authentifié
**Solution** :
```bash
# Sur VPS, se reconnecter à ghcr.io
docker login ghcr.io
docker compose pull
docker compose up -d
```

---

## Maintenance

### Mettre à jour le code
```bash
# Sur ta machine locale
git commit -am "feat: nouvelle fonctionnalité"
git push origin main

# Le workflow se déclenche automatiquement
# Les containers redémarrent avec les nouvelles images
```

### Vérifier les logs en temps réel
```bash
# Sur VPS
cd /opt/agrisense
docker compose logs -f backend

# Ou spécifique
docker logs -f agrisense-backend
```

### Redémarrer manuellement
```bash
# Sur VPS
cd /opt/agrisense
docker compose down
docker compose up -d
```

### Purger les anciennes images
```bash
# Sur VPS
docker image prune -a
```

---

## Variables d'environnement VPS (.env)

| Variable | Exemple | Récupération |
|---|---|---|
| `MONGO_URI` | `mongodb://mongodb:27017/agrisense` | Défaut local |
| `GEMINI_API_KEY` | `AIzaSy...` | https://ai.google.dev/ |
| `GOOGLE_MAPS_API_KEY` | `AIzaSy...` | Google Cloud Console |
| `JWT_SECRET` | `super_secret_complexe_123` | Générer aléatoire |
| `FLASK_ENV` | `production` | Défaut |

---

## Sécurité

✅ **À faire** :
- [ ] Changer le mot de passe SSH
- [ ] Configurer un firewall (UFW)
- [ ] Activer 2FA GitHub
- [ ] Utiliser des clés SSH sans passphrase **seulement pour déploiement**
- [ ] Stocker les secrets .env en dehors du git
- [ ] Rotationner les API keys régulièrement

❌ **À ne jamais faire** :
- Ne pas commiter les fichiers `.env` ou clés privées
- Ne pas exposer les secrets dans les logs
- Ne pas utiliser root comme utilisateur SSH de déploiement

---

## Troubleshooting rapide

```bash
# Status général
docker compose ps
docker compose logs

# Redémarrer un service
docker compose restart backend

# Full reset (ATTENTION!)
docker compose down -v
docker compose up -d
```

---

## Support

Logs GitHub Actions : https://github.com/mathisbruel/Projet-Etudes-2026/actions

Pour déboguer le workflow, activer le debug logging :
```bash
# Ajouter en secret GitHub
ACTIONS_STEP_DEBUG=true
```

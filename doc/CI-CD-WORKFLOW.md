# CI/CD Workflow — Architecture

## 📋 Vue d'ensemble

Le pipeline CI/CD est séparé en **deux workflows indépendants** pour une meilleure traçabilité et contrôle :

```
Push Code (main/develop)
    ↓
┌─────────────────────────────────┐
│  CI - Build & Test              │  (.github/workflows/ci.yml)
│  ✓ Build Backend Docker         │
│  ✓ Build Frontend Docker        │
│  ✓ Lint Backend (pylint)        │
│  ✓ Lint Frontend (flutter)      │
│  ✓ Push to ghcr.io              │
└─────────────────────────────────┘
    ↓ (only main branch)
┌─────────────────────────────────┐
│  CD - Deploy to VPS             │  (.github/workflows/cd.yml)
│  ✓ Pull latest code             │
│  ✓ Pull Docker images           │
│  ✓ docker compose up -d         │
│  ✓ Health check                 │
└─────────────────────────────────┘
    ↓
✅ Live on VPS
```

---

## 🔄 Workflow CI — Build & Test

**Fichier** : `.github/workflows/ci.yml`

### ✨ Déclencheurs
- ✅ Push sur `main` ou `develop`
- ✅ Pull Request vers `main` ou `develop`
- ✅ Trigger manuel (Actions → Run workflow)

### 📦 Jobs

#### 1️⃣ **build-backend**
```yaml
Build backend Docker image
├─ Checkout code
├─ Setup Docker Buildx
├─ Login to ghcr.io
├─ Extract metadata (tags, labels)
├─ Build & Push image
└─ Cache layers for speed
```

- **Push vers ghcr.io** : Seulement sur push (pas PR)
- **Tags générés** :
  - `latest` (si main)
  - `develop` (si develop)
  - `sha-<commit_short>` (toujours)

#### 2️⃣ **build-frontend**
```yaml
Build frontend Docker image (Flutter APK builder)
├─ Checkout code
├─ Setup Docker Buildx
├─ Login to ghcr.io
├─ Extract metadata
├─ Build & Push image
└─ Cache layers
```

#### 3️⃣ **lint-backend**
```yaml
Static code analysis
├─ Checkout code
├─ Setup Python 3.11
├─ Install requirements + pylint
├─ Run pylint on app/ directory
└─ Report (non-blocking)
```

#### 4️⃣ **lint-frontend**
```yaml
Flutter code quality
├─ Checkout code
├─ Setup Flutter stable
├─ Get dependencies
├─ Run flutter analyze
└─ Report (non-blocking)
```

#### 5️⃣ **summary**
```yaml
Pipeline status summary
├─ Check all jobs passed
└─ Report overall status
```

### 📊 Résultat CI
- ✅ Images Docker pushées vers `ghcr.io`
- ✅ Code linted (rapports optionnels)
- ✅ Prêt pour déploiement

---

## 🚀 Workflow CD — Deploy to VPS

**Fichier** : `.github/workflows/cd.yml`

### ✨ Déclencheurs
- ✅ Push sur `main` (après CI success)
- ✅ Workflow CI réussi sur `main`
- ✅ Trigger manuel (Actions → Run workflow)

### ⚙️ Conditions
- ✋ **Ne s'exécute QUE sur la branche `main`**
- ✋ **Attend que la CI soit passée** (si triggered par CI)

### 📦 Jobs

#### 1️⃣ **check-ci** (optionnel)
```yaml
Vérifier que la CI est passée
└─ Fail si workflow_run.conclusion != success
```
Note : Seulement si déclenché par le workflow CI

#### 2️⃣ **deploy** (principal)
```yaml
SSH vers le VPS et déployer
├─ Checkout code
├─ Login to ghcr.io (avec GITHUB_TOKEN)
├─ SSH sur VPS :
│  ├─ cd /opt/agrisense
│  ├─ git fetch + git reset --hard origin/main
│  ├─ docker login ghcr.io
│  ├─ docker compose pull (télécharge les images)
│  ├─ docker compose up -d (démarre les containers)
│  ├─ sleep 5 (attendre le démarrage)
│  ├─ curl http://localhost:5001/health (health check)
│  ├─ docker compose ps (affiche les containers)
│  └─ docker logout
├─ Rapport de succès
└─ Logs sur failure
```

### 🔐 Secrets requis
```
VPS_HOST        : IP ou domaine du VPS
VPS_USER        : Utilisateur SSH (ubuntu, root, etc.)
VPS_SSH_KEY     : Clé privée SSH
VPS_SSH_PORT    : Port SSH (optionnel, défaut: 22)
VPS_DEPLOY_PATH : /opt/agrisense
```

### 📋 Script d'exécution SSH
Le script SSH (inlining dans `appleboy/ssh-action`) :
1. Change le répertoire de travail
2. Pull le dernier code de `main`
3. Authentifie Docker auprès de ghcr.io
4. Télécharge les nouvelles images
5. Redémarre les containers
6. Health check sur le backend
7. Affiche les containers en cours

---

## 🔄 Flux complet (Exemple)

```
1. Push code sur main
   └─> git push origin main

2. GitHub déclenche le workflow CI
   └─> .github/workflows/ci.yml

3. CI : build-backend
   └─> Construit app backend, push ghcr.io/mathisbruel/.../backend:main

4. CI : build-frontend
   └─> Construit app frontend, push ghcr.io/mathisbruel/.../frontend:main

5. CI : lint-backend & lint-frontend
   └─> Analyse statique

6. CI : summary
   └─> Reporte les résultats

7. GitHub déclenche le workflow CD (si CI success)
   └─> .github/workflows/cd.yml

8. CD : deploy
   └─> SSH sur VPS:
       ├─ git pull origin main
       ├─ docker compose pull
       ├─ docker compose up -d
       └─ Health check

9. ✅ Application live sur VPS!
```

---

## 🎯 Avantages de la séparation CI/CD

| Aspect | Bénéfice |
|--------|----------|
| **Traçabilité** | Voir clairement quand le build s'est passé, quand le déploiement a eu lieu |
| **Réutilisabilité** | CI s'exécute sur tous les branches (développement) |
| **Contrôle** | CD n'exécute que sur `main` (prod) |
| **Déploiement manuel** | Possibilité de redéployer sans rebuild via `workflow_dispatch` |
| **Parallelisation** | Les build backends et frontends se font en parallèle |
| **Debugging** | Plus facile d'identifier où le problème a eu lieu |

---

## 📊 Statuts & Actions GitHub

### Voir les workflows
```
GitHub UI:
  Repository → Actions → Workflows
```

### Voir les détails d'une exécution
```
Actions → [Workflow name] → [Run ID]
```

### Logs de chaque job
```
Actions → [Run] → [Job] → Logs détaillés
```

---

## 🆘 Troubleshooting

### ❌ "CI passed but CD didn't run"
**Cause** : CD n'est déclenché que sur `main`
**Solution** : S'assurer que le push était sur `main`, pas `develop`

### ❌ "Docker login failed in CD"
**Cause** : `GITHUB_TOKEN` expiré ou secret invalide
**Solution** : Les tokens GitHub expirent automatiquement, mais le GITHUB_TOKEN est auto-généré

### ❌ "Health check failed (HTTP 000)"
**Cause** : Backend ne démarre pas
**Solution** :
```bash
# Sur VPS
docker compose logs backend
docker compose logs mongodb
```

### ❌ "git reset --hard failed"
**Cause** : Clé SSH invalide ou utilisateur sans permissions
**Solution** : Vérifier `VPS_SSH_KEY` et `VPS_USER`

---

## 🔧 Modifier les workflows

### Ajouter un test
```yaml
# Dans ci.yml, ajouter un job
test-backend:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    - run: pip install -r backend/requirements.txt
    - run: pytest backend/tests/
```

### Ajouter une notification
```yaml
# À la fin de cd.yml
- name: Notify on Slack
  if: always()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
```

### Ajouter un déploiement staging
```yaml
# Nouveau workflow: cd-staging.yml
on:
  push:
    branches: [develop]
# Déploier sur VPS_STAGING_HOST au lieu de VPS_HOST
```

---

## 📈 Monitoring

### Logs en temps réel
```bash
# Sur VPS
cd /opt/agrisense
docker compose logs -f backend
```

### Actions du repo
```
https://github.com/mathisbruel/Projet-Etudes-2026/actions
```

### Health de l'API
```bash
curl http://vps.example.com:5001/health
```

---

## 🛡️ Sécurité

✅ **Bonnes pratiques**
- [ ] Secrets GitHub utilisés pour auth sensible
- [ ] Pas de secrets en clair dans le code
- [ ] `GITHUB_TOKEN` auto-généré par GitHub (sûr)
- [ ] Clé SSH dédiée au déploiement
- [ ] CD limité à `main` (production)

❌ **À éviter**
- Ne pas exposer VPS_SSH_KEY en public
- Ne pas commiter les `.env`
- Ne pas utiliser le même token pour tout

---

## 💡 Tips

**Redéployer sans attendre le push** :
```
GitHub UI → Actions → CD - Deploy to VPS → Run workflow
```

**Voir les détails du déploiement** :
```
Actions → [Run ID] → deploy → Script output
```

**Rollback rapide** :
```bash
git revert <commit_id>
git push origin main
# CD redéploie automatiquement
```

**Tester localement** :
```bash
docker compose pull
docker compose up -d
```

---

## 📚 Ressources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [appleboy/ssh-action](https://github.com/appleboy/ssh-action)
- [Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

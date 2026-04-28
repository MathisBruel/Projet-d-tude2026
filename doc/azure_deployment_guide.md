# Guide de déploiement Azure VPS — AgriSense v2

> Déployer l'application Flask sur un VPS avec Docker, en utilisant Azure Container Registry pour stocker les images

---

## 1. Créer et configurer le groupe de ressources

### Étapes
1. Aller sur **[portal.azure.com](https://portal.azure.com)**
2. Cliquer sur **+ Créer une ressource**
3. Rechercher **« Groupe de ressources »**
4. Cliquer sur **Créer**
5. Remplir le formulaire:
   - **Abonnement** : sélectionner votre abonnement Azure
   - **Nom du groupe** : `agrisense-rg`
   - **Région** : `France Central` (ou `East US` si Fr indisponible)
6. Cliquer sur **Vérifier + créer** → **Créer**

✅ Le groupe de ressources est créé.

---

## 2. Créer un registre de conteneurs (Azure Container Registry)

### Étapes
1. Aller sur **Portail Azure** → **+ Créer une ressource**
2. Rechercher **« Registre de conteneurs »**
3. Cliquer sur **Créer**
4. Remplir le formulaire:
   - **Abonnement** : même abonnement que le groupe de ressources
   - **Groupe de ressources** : sélectionner `agrisense-rg`
   - **Nom du registre** : `agrisenseregistry` (doit être unique et en minuscules)
   - **Localisation** : même région que le groupe
   - **Plan tarifaire** : `Basic` (suffisant pour ce projet)
   - **Accès administrateur** : cocher **Activer**
5. Cliquer sur **Vérifier + créer** → **Créer**

✅ Le registre est créé.

### Récupérer les identifiants de connexion
1. Aller à votre registre fraîchement créé
2. Aller dans le menu gauche → **Clés d'accès**
3. Copier:
   - **Serveur de connexion** : ex. `agrisenseregistry.azurecr.io`
   - **Nom d'utilisateur**
   - **Mot de passe** (cliquer sur l'œil pour voir)

💾 **Garder ces infos pour le push Docker local et pour le VPS.**

---

## 3. Uploader l'image Docker au registre

### Prérequis
- Docker Desktop installé localement
- Image Docker construite et prête (`docker build`)

### Étapes
1. Sur votre machine locale, ouvrir **Terminal / PowerShell / Bash**
2. Se connecter à Azure Container Registry:
   ```bash
   docker login agrisenseregistry.azurecr.io
   ```
   - Entrer le **nom d'utilisateur** et **mot de passe** récupérés ci-dessus

3. Tagger l'image Docker:
   ```bash
   docker tag agrisense-backend agrisenseregistry.azurecr.io/agrisense-backend:latest
   ```

4. Pusher l'image:
   ```bash
   docker push agrisenseregistry.azurecr.io/agrisense-backend:latest
   ```

✅ L'image Docker est maintenant disponible dans votre registre Azure.

### Vérifier le push via le portail
1. Aller à **Registre de conteneurs** → **agrisenseregistry**
2. Menu gauche → **Référentiels**
3. Vérifier que `agrisense-backend` apparaît avec le tag `latest`

---

## 4. Louer/configurer un VPS

### Choix du VPS
Vous pouvez utiliser n'importe quel fournisseur (OVH, Linode, DigitalOcean, Hetzner, etc.).

**Configuration recommandée:**
- **OS**: Ubuntu 22.04 LTS (ou plus récent)
- **CPU**: 2 cœurs minimum
- **RAM**: 2-4 GB minimum
- **Stockage**: 20-30 GB SSD minimum
- **IP publique**: Requise

### Prérequis avant de continuer
- Avoir accès SSH au VPS (clé privée + IP publique)
- Être capable de se connecter: `ssh root@votre-ip-vps`

---

## 5. Installer Docker sur le VPS

### Étapes
1. Se connecter au VPS via SSH:
   ```bash
   ssh root@votre-ip-vps
   ```

2. Mettre à jour les paquets:
   ```bash
   apt update && apt upgrade -y
   ```

3. Installer Docker (et Docker Compose):
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   ```

4. Vérifier l'installation:
   ```bash
   docker --version
   docker compose --version
   ```

✅ Docker est maintenant installé sur le VPS.

---

## 6. Configurer les identifiants ACR sur le VPS

### Créer un fichier `.env` sur le VPS

1. Sur le VPS, créer un répertoire de travail:
   ```bash
   mkdir -p /root/agrisense
   cd /root/agrisense
   ```

2. Créer un fichier `.env` avec les secrets:
   ```bash
   cat > /root/agrisense/.env << 'EOF'
   MONGO_URI=mongodb+srv://utilisateur:motdepasse@cluster.mongodb.net/agrisense
   GEMINI_API_KEY=votre-clé-gemini
   GOOGLE_MAPS_API_KEY=votre-clé-google-maps
   JWT_SECRET=votre-secret-jwt-aléatoire
   FLASK_ENV=production
   EOF
   ```

3. Restreindre les permissions:
   ```bash
   chmod 600 /root/agrisense/.env
   ```

💾 **Les secrets sont maintenant sécurisés sur le VPS.**

---

## 7. Se connecter à Azure Container Registry depuis le VPS

### Étapes
1. Sur le VPS, se connecter à ACR:
   ```bash
   docker login agrisenseregistry.azurecr.io
   ```
   - Entrer le **nom d'utilisateur** et **mot de passe** récupérés à l'étape 2

2. Vérifier la connexion:
   ```bash
   docker pull agrisenseregistry.azurecr.io/agrisense-backend:latest
   ```

✅ L'image Docker est maintenant téléchargée sur le VPS.

---

## 8. Lancer le conteneur Docker sur le VPS

### Option A: Via Docker Compose (recommandé)

1. Sur le VPS, créer un fichier `docker-compose.yml`:
   ```bash
   cat > /root/agrisense/docker-compose.yml << 'EOF'
   version: '3.8'
   services:
     agrisense-api:
       image: agrisenseregistry.azurecr.io/agrisense-backend:latest
       container_name: agrisense-api
       restart: always
       ports:
         - "5000:5000"
       env_file:
         - .env
       networks:
         - agrisense-network
   networks:
     agrisense-network:
       driver: bridge
   EOF
   ```

2. Lancer le conteneur:
   ```bash
   cd /root/agrisense
   docker compose up -d
   ```

3. Vérifier que le conteneur fonctionne:
   ```bash
   docker ps
   docker logs agrisense-api
   ```

✅ L'API fonctionne maintenant sur `http://votre-ip-vps:5000`

### Option B: Via ligne de commande Docker

Si vous préférez une commande unique:
```bash
docker run -d \
  --name agrisense-api \
  --restart always \
  --env-file /root/agrisense/.env \
  -p 5000:5000 \
  agrisenseregistry.azurecr.io/agrisense-backend:latest
```

---

## 9. Assurer la persistance du conteneur (systemd service)

### Créer un service systemd pour Docker Compose

1. Créer un fichier service:
   ```bash
   sudo tee /etc/systemd/system/agrisense.service > /dev/null << 'EOF'
   [Unit]
   Description=AgriSense API with Docker Compose
   After=docker.service
   Requires=docker.service

   [Service]
   Type=oneshot
   RemainAfterExit=yes
   WorkingDirectory=/root/agrisense
   ExecStart=/usr/local/bin/docker compose up -d
   ExecStop=/usr/local/bin/docker compose down
   Restart=on-failure
   RestartSec=10

   [Install]
   WantedBy=multi-user.target
   EOF
   ```

2. Activer et démarrer le service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable agrisense.service
   sudo systemctl start agrisense.service
   ```

3. Vérifier le statut:
   ```bash
   sudo systemctl status agrisense.service
   ```

✅ Le conteneur redémarrera automatiquement après un reboot du VPS.

---

## 10. Ouvrir les ports firewall

### Si vous avez un firewall (UFW)

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 5000/tcp  # Flask API
sudo ufw enable
```

### Vérifier l'accès depuis l'extérieur

1. Ouvrir un navigateur
2. Aller à: `http://votre-ip-vps:5000/api/v1/health`
3. Vous devez voir une réponse JSON (ex. `{"status": "ok"}`)

✅ L'API est accessible depuis l'extérieur.

---

## 11. Configurer un domaine (optionnel)

### Si vous avez un domaine enregistré
1. Pointer le domaine vers votre IP VPS (via votre registrar DNS)
2. Attendre la propagation DNS (15 min à 48 h)
3. Accéder via: `http://votre-domaine.com:5000`

### Configurer HTTPS (Certbot + Nginx)

Pour sécuriser avec HTTPS, vous pouvez installer un reverse proxy Nginx:

```bash
# Installer Nginx
sudo apt install nginx -y

# Installer Certbot
sudo apt install certbot python3-certbot-nginx -y

# Configurer le certificat SSL
sudo certbot certonly --standalone -d votre-domaine.com
```

Puis créer une configuration Nginx pour proxy vers le conteneur Docker (au-delà du périmètre de ce guide).

---

## 12. Mettre à jour l'`API_URL` dans Flutter

### Fichier à modifier
`frontend/lib/core/config/app_config.dart`

### Changement
```dart
// Avant
const String API_URL = "http://localhost:5000";

// Après (remplacer votre-ip-vps par l'IP réelle)
const String API_URL = "http://votre-ip-vps:5000";

// OU si vous avez un domaine
const String API_URL = "http://votre-domaine.com:5000";

// OU si vous avez HTTPS
const String API_URL = "https://votre-domaine.com";
```

✅ Recompiler l'app Flutter et tester.

---

## 13. Mettre à jour l'image Docker (itérations futures)

### Si vous modifiez le code backend
1. Localement: `docker build -t agrisenseregistry.azurecr.io/agrisense-backend:v2 ./backend`
2. Localement: `docker push agrisenseregistry.azurecr.io/agrisense-backend:v2`
3. **Sur le VPS:**
   ```bash
   cd /root/agrisense
   # Modifier le tag dans docker-compose.yml
   sed -i 's/:latest/:v2/g' docker-compose.yml
   docker compose pull
   docker compose up -d
   ```

4. Vérifier les logs:
   ```bash
   docker logs agrisense-api
   ```

⏳ Attendre 30 secondes que le conteneur redémarre.

---

## ✅ Checklist résumée

- [ ] Groupe de ressources créé (`agrisense-rg`)
- [ ] Azure Container Registry créé (`agrisenseregistry`)
- [ ] Identifiants ACR récupérés
- [ ] Image Docker pushée vers ACR
- [ ] VPS loué et configuré (Ubuntu 22.04+)
- [ ] Docker installé sur le VPS
- [ ] Fichier `.env` créé sur le VPS avec tous les secrets
- [ ] Docker login réussi sur le VPS
- [ ] Conteneur lancé (docker compose ou docker run)
- [ ] Firewall ouvert pour le port 5000
- [ ] Test HTTP réussi (health check)
- [ ] Service systemd configuré (pour persistance)
- [ ] `API_URL` mis à jour dans Flutter (IP VPS ou domaine)
- [ ] App Flutter recompilée et testée
- [ ] Logs vérifiés sans erreurs (`docker logs agrisense-api`)

---

## 🆘 Troubleshooting

| Problème | Solution |
|---|---|
| **"Cannot connect to Docker daemon"** | Vérifier que Docker est installé: `docker --version`. Si problème de permissions, utiliser `sudo docker` ou ajouter l'utilisateur au groupe docker: `sudo usermod -aG docker $USER` |
| **"Unable to find image"** | Vérifier que `docker login` a réussi. Vérifier le nom complet: `agrisenseregistry.azurecr.io/agrisense-backend:latest` |
| **"Connection refused" sur port 5000** | Vérifier que le conteneur tourne: `docker ps`. Vérifier les logs: `docker logs agrisense-api`. Vérifier le firewall: `sudo ufw status` |
| **Application crash au démarrage** | Consulter les logs: `docker logs agrisense-api`. Vérifier que les variables d'environnement dans `.env` sont correctes |
| **MongoDB connection timeout** | Vérifier que MongoDB Atlas accepte les connexions depuis l'IP du VPS (IP whitelist dans Atlas) |
| **Erreur 401 Unauthorized sur les routes API** | Vérifier que `JWT_SECRET` dans `.env` est correct et identique à celui utilisé en développement |
| **API répond mais Flutter ne se connecte** | Vérifier CORS dans Flask (`flask-cors`). Vérifier que `API_URL` n'a pas de trailing `/`. Vérifier que le domaine/IP est accessible depuis l'appareil |
| **Le conteneur s'arrête après chaque reboot du VPS** | Vérifier le service systemd: `sudo systemctl status agrisense.service`. Activer la persistance: `docker compose up -d --restart-policy always` |

---

## 📝 Notes importantes

1. **Variables d'environnement sécurisées**: Ne jamais commiter le fichier `.env` dans Git. Ajouter `.env` à `.gitignore`.
2. **Authentification ACR**: Les identifiants ACR doivent être gardés secrets. Ne pas les mettre dans le code.
3. **Monitoring**: Installer des outils comme Portainer ou Watchtower pour gérer les conteneurs à distance (optionnel).
4. **Backups**: Configurer régulièrement des backups de la base MongoDB (Atlas offre une rétention automatique).
5. **Logs**: Accéder aux logs via `docker logs agrisense-api -f` pour un suivi en temps réel.

---

**Prochaines étapes:** Une fois en production, envisager un CI/CD automatisé via GitHub Actions pour redeployer automatiquement à chaque push sur `main` (script qui build, pousse vers ACR, et redémarre le conteneur sur le VPS via SSH).

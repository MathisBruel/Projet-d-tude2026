# Guide de déploiement Azure — AgriSense

> Déployer l'application Flask sur Azure Container Apps via l'interface web (portail.azure.com)

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

✅ Le groupe de ressources est créé. Vous pouvez y créer d'autres ressources maintenant.

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

✅ Le registre est créé. Vous pourrez y pusher vos images Docker.

### Récupérer les identifiants de connexion
1. Aller à votre registre fraîchement créé
2. Aller dans le menu gauche → **Clés d'accès**
3. Copier:
   - **Serveur de connexion** : ex. `agrisenseregistry.azurecr.io`
   - **Nom d'utilisateur**
   - **Mot de passe** (cliquer sur l'œil pour voir)

💾 Garder ces infos pour le push Docker local.

---

## 3. Uploader l'image Docker au registre

### Prérequis
- Docker Desktop installé localement
- Image Docker construite et prête (`docker build`)

### Étapes
1. Sur votre machine locale, ouvrir **Terminal / PowerShell / Bash**
2. Se connecter à Azure Container Registry:
   ```
   docker login agrisenseregistry.azurecr.io
   ```
   - Entrer le **nom d'utilisateur** et **mot de passe** récupérés ci-dessus

3. Tagger l'image Docker:
   ```
   docker tag agrisense-backend agrisenseregistry.azurecr.io/agrisense-backend:latest
   ```

4. Pusher l'image:
   ```
   docker push agrisenseregistry.azurecr.io/agrisense-backend:latest
   ```

✅ L'image Docker est maintenant disponible dans votre registre Azure.

### Vérifier le push via le portail
1. Aller à **Registre de conteneurs** → **agrisenseregistry**
2. Menu gauche → **Référentiels**
3. Vérifier que `agrisense-backend` apparaît avec le tag `latest`

---

## 4. Créer un coffre de clés (Azure Key Vault) — **Optionnel mais recommandé**

### Étapes
1. **Portail Azure** → **+ Créer une ressource**
2. Rechercher **« Coffre de clés »** (Key Vault)
3. Cliquer sur **Créer**
4. Remplir le formulaire:
   - **Abonnement** : même abonnement
   - **Groupe de ressources** : `agrisense-rg`
   - **Nom du coffre** : `agrisense-kv`
   - **Localisation** : même région
   - **Plan tarifaire** : `Standard`
5. Cliquer sur **Vérifier + créer** → **Créer**

✅ Coffre créé. Passez à l'étape 5 pour ajouter les secrets.

---

## 5. Ajouter les variables d'environnement (secrets)

### Secrets à créer
- `MONGO_URI` : `mongodb+srv://...`
- `GEMINI_API_KEY` : clé d'API Google AI Studio
- `GOOGLE_MAPS_API_KEY` : clé d'API Google Cloud
- `JWT_SECRET` : une chaîne aléatoire sécurisée (ex. UUID ou résultat d'OpenSSL)
- `FLASK_ENV` : `production`

### Option A: Via Azure Key Vault (recommandé)

1. Aller à votre **Key Vault** → **agrisense-kv**
2. Menu gauche → **Secrets**
3. Cliquer sur **+ Générer/Importer** (pour chaque secret)
4. Remplir:
   - **Nom** : ex. `mongo-uri`
   - **Valeur** : ex. `mongodb+srv://...`
5. Cliquer sur **Créer**

Répéter pour chaque secret (MONGO_URI, GEMINI_API_KEY, GOOGLE_MAPS_API_KEY, JWT_SECRET).

✅ Les secrets sont maintenant stockés en toute sécurité dans le coffre.

### Option B: Passer directement aux Container Apps (plus simple)
Vous pouvez aussi ajouter les variables lors de la création des Container Apps (étape 6). Moins sécurisé mais valide pour un projet d'études.

---

## 6. Créer et déployer l'application sur Container Apps

### Étapes
1. **Portail Azure** → **+ Créer une ressource**
2. Rechercher **« Container Apps »**
3. Cliquer sur **Créer**

#### **Onglet "Informations de base"**
- **Abonnement** : même abonnement
- **Groupe de ressources** : `agrisense-rg`
- **Nom de l'application conteneur** : `agrisense-api`
- **Plan d'hébergement** : `Consommation (serveurs sans état)`
- **Localisation** : même région

Cliquer sur **Suivant : Registre de conteneurs >**

#### **Onglet "Registre de conteneurs"**
- **Source d'image** : sélectionner **Azure Container Registry**
- **Registre** : `agrisenseregistry`
- **Image** : `agrisense-backend`
- **Balise d'image** : `latest`

Cliquer sur **Suivant : Authentification >**

#### **Onglet "Authentification"**
- **Authentification du registre** : cocher **Oui** (pour puller depuis ACR)
- L'authentification se fait automatiquement

Cliquer sur **Suivant : Ingress >**

#### **Onglet "Ingress"**
- **Entrée** : cocher **Activer**
- **Mode Ingress** : sélectionner **Externe** (accès public)
- **Port cible** : `5000` (port Flask)
- **Protocole** : `HTTP`

Cliquer sur **Suivant : Variables d'environnement >**

#### **Onglet "Variables d'environnement"**

Ajouter les variables en cliquant sur **+ Ajouter**:

| Nom | Valeur | Type |
|---|---|---|
| `MONGO_URI` | `mongodb+srv://...` | Texte brut |
| `GEMINI_API_KEY` | `...` | **Secret** (cocher "Secret") |
| `GOOGLE_MAPS_API_KEY` | `...` | **Secret** |
| `JWT_SECRET` | `...` | **Secret** |
| `FLASK_ENV` | `production` | Texte brut |

**OU** si vous avez créé un Key Vault:
- Utiliser le type **Référence du coffre de clés** au lieu de passer les valeurs directement
- Sélectionner le coffre `agrisense-kv` et le nom du secret

Cliquer sur **Vérifier + créer**

#### **Onglet "Résumé"**
- Vérifier que tout est correct
- Cliquer sur **Créer**

⏳ Attendre 2-5 minutes que l'application soit déployée.

✅ **Vous verrez "Déploiement réussi"** quand c'est prêt.

---

## 7. Récupérer l'URL de l'application

### Étapes
1. Aller à votre **Container App** → **agrisense-api**
2. Dans le panneau **Vue d'ensemble** (Essentials)
3. Copier **l'URL d'application** (ex. `https://agrisense-api.xxx.azurecontainerapps.io`)

💾 Cette URL sera utilisée comme `API_URL` dans Flutter

---

## 8. Vérifier que l'API répond

### Via navigateur
1. Ouvrir un navigateur
2. Aller à: `https://agrisense-api.xxx.azurecontainerapps.io/api/v1/health`
3. Vous devez voir une réponse JSON (ex. `{"status": "ok"}`)

### Via Postman ou cURL
```
GET https://agrisense-api.xxx.azurecontainerapps.io/api/v1/health
```

✅ Si vous voyez une réponse, l'API fonctionne!

---

## 9. Consulter les logs de l'application

### Étapes
1. Aller à votre **Container App** → **agrisense-api**
2. Menu gauche → **Flux de console**
3. Vous verrez les logs en temps réel de votre Flask

**En cas d'erreur:**
- Vérifier que les variables d'environnement sont correctes
- Vérifier que MongoDB Atlas est accessible depuis Azure
- Vérifier que les clés d'API (Gemini, Google Maps) sont valides

---

## 10. Mettre à jour le `API_URL` dans Flutter

### Fichier à modifier
`frontend/lib/core/config/app_config.dart`

### Changement
```dart
// Avant
const String API_URL = "http://localhost:5000";

// Après
const String API_URL = "https://agrisense-api.xxx.azurecontainerapps.io";
```

Remplacer `xxx.azurecontainerapps.io` par le domaine réel.

✅ Recompiler l'app Flutter et tester.

---

## 11. Mettre à jour l'image Docker (itérations futures)

### Si vous modifiez le code backend
1. Localement: `docker build -t agrisenseregistry.azurecr.io/agrisense-backend:v2 ./backend`
2. Localement: `docker push agrisenseregistry.azurecr.io/agrisense-backend:v2`
3. **Portail Azure** → **Container App** → **agrisense-api**
4. Menu → **Conteneurs** → Éditer l'image
5. Changer la **Balise d'image** de `latest` à `v2`
6. Cliquer sur **Sauvegarder**

⏳ Attendre le redéploiement (1-2 min).

---

## ✅ Checklist résumée

- [ ] Groupe de ressources créé (`agrisense-rg`)
- [ ] Azure Container Registry créé (`agrisenseregistry`)
- [ ] Identifiants ACR récupérés
- [ ] Image Docker pushée vers ACR
- [ ] Azure Key Vault créé (optionnel)
- [ ] Secrets ajoutés (MONGO_URI, API keys, JWT_SECRET)
- [ ] Container App créée et déployée
- [ ] URL de l'API récupérée
- [ ] Test HTTP réussi (health check)
- [ ] Logs vérifiés sans erreurs
- [ ] `API_URL` mis à jour dans Flutter
- [ ] App Flutter recompilée et testée

---

## 🆘 Troubleshooting

| Problème | Solution |
|---|---|
| **"Image not found"** dans Container Apps | Vérifier que le nom complet de l'image est correct: `agrisenseregistry.azurecr.io/agrisense-backend:latest` |
| **Application crash au démarrage** | Vérifier les logs (Flux de console) → problème de config MongoDB ou variables d'environnement |
| **MongoDB connection timeout** | Vérifier que MongoDB Atlas accepte les connexions depuis Azure (IP whitelist) |
| **Erreur 401 Unauthorized sur les routes API** | Vérifier que JWT_SECRET est correct et consistant |
| **API répond mais Flutter ne se connecte** | Vérifier CORS dans Flask, vérifier que `API_URL` dans Flutter n'a pas de trailing `/` |

---

**Prochaines étapes :** Une fois en production, envisager un CI/CD automatisé via GitHub Actions pour redeployer à chaque push sur `main`.

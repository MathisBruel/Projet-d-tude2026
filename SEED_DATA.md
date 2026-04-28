# 🌱 Seeding AgriSense Database

Ce projet inclut un script de seeding **automatisé** pour peupler MongoDB avec des données réalistes.

## Quick Start

### 1. Assurez-vous que MongoDB tourne
```bash
# Local MongoDB
mongod

# OU via Docker Compose
docker compose up mongo  # si configuré
```

### 2. Lancez le script de seeding

#### Mode Normal (recommandé)
```bash
cd backend
python scripts/seed_database.py
```
✅ Idempotent - skip si données existent
✅ Sûr de relancer plusieurs fois

#### Mode Force (Reset complet)
```bash
python scripts/seed_database.py --force
# ou shorthand
python scripts/seed_database.py -f
```
🗑️ Supprime TOUTES les données
🔄 Repopule de zéro

**C'est tout !** ✨

Le script va :
- ✅ Se connecter à MongoDB (via `MONGO_URI` du `.env`)
- ✅ Vérifier si des données existent déjà (mode normal)
- ✅ Créer 6 utilisateurs + 5 parcelles + 4 prédictions + 3 posts + 4 alertes + 8 actions
- ✅ Créer les indexes pour performance
- ✅ Afficher les credentials de test

---

## 📋 Données Générées

| Entité | Quantité | Description |
|--------|----------|-------------|
| **Utilisateurs** | 6 | 1 admin, 3 fermiers, 2 agronomes (France) |
| **Parcelles** | 5 | Blé, Orge, Maïs, Tournesol, Pommes de terre |
| **Prédictions** | 4 | Rendements + recommandations IA réalistes |
| **Posts** | 3 | Articles communautaires avec commentaires |
| **Alertes** | 4 | Météo, maladie, récolte, système |
| **Actions** | 8 | Fertilisation, traitement, semis, irrigation |

---

## 🔐 Credentials de Test

Après seeding, vous pouvez vous connecter avec :

```
Email                         | Mot de passe | Rôle
------------------------------|--------------|----------
admin@agrisense.fr            | admin123     | admin
jean.dupont@farm.fr           | password123  | farmer
marie.martin@farm.fr          | password123  | farmer
pierre.bernard@farm.fr        | password123  | farmer
christine.rousseau@agro.fr    | password123  | agronomist
luc.moreau@agro.fr            | password123  | agronomist
```

---

## 📝 Détails Techniques

Voir [backend/scripts/README.md](backend/scripts/README.md) pour :
- Configuration `.env` détaillée
- Structure des données
- Idempotence et réinitialisation
- Intégration docker-compose

---

## 🚀 Utilisation en Development

### Après clonage du repo :
```bash
# 1. Installer dépendances
cd backend
pip install -r requirements.txt

# 2. Créer .env (copier de .env.example et ajuster)
cp .env.example .env

# 3. Démarrer MongoDB
docker compose up mongo &

# 4. Seeder la base
python scripts/seed_database.py

# 5. Lancer le serveur
flask run
```

### Ou avec Docker Compose :
```bash
# Docker compose va auto-seeder au premier démarrage
docker compose up --build
```

---

## ✨ Bonus : Données Réalistes

Les données sont **théoriquement possibles** :
- 🗺️ Localisations réelles en France (coordonnées GPS exactes)
- 🌾 Types de cultures et rotations cohérents
- 📊 Rendements réalistes selon culture et région
- 💬 Posts et discussions agricoles authentiques
- ⚙️ Actions datées de façon logique (semis → traitement → récolte)

Idéal pour la démo et les tests ! 🎯

# 🌿 AgriSense — L'IA au service de la terre

[![Maintenance](https://img.shields.io/badge/Maintenu%3F-oui-green.svg)](https://github.com/MathisBruel/Projet-d-tude2026)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Stack](https://img.shields.io/badge/Stack-Flutter%20%7C%20Flask%20%7C%20MongoDB-blue.svg)]()

**AgriSense** est une solution mobile innovante d'aide à la décision pour l'agriculture de précision. En combinant l'intelligence artificielle générative et l'analyse de données environnementales en temps réel, nous redonnons le pouvoir aux agriculteurs sur leurs rendements.

---

## 👤 Notre Persona : Jean-Pierre, l'agriculteur moderne

Pour concevoir AgriSense, nous nous sommes mis à la place de ceux qui font la terre.

> ### "Je veux savoir si ma récolte sera à la hauteur, avant qu'il ne soit trop tard."
>
> **Jean-Pierre**, 45 ans, gère une exploitation céréalière de 150 hectares. 
> *   **Ses défis :** Le changement climatique rend ses prévisions habituelles obsolètes. Il n'a pas le budget pour installer des sondes connectées (IoT) sur chaque parcelle.
> *   **Ses besoins :** Une application simple qui lui donne une estimation de rendement fiable et des conseils d'expert sans qu'il ait besoin d'être data-scientist.
> *   **La solution AgriSense :** Il dessine sa parcelle sur la carte, AgriSense récupère automatiquement la météo et l'historique du sol, et Gemini IA lui délivre son diagnostic.

### 📋 User Stories

Pour répondre aux besoins de Jean-Pierre, nous avons défini les parcours suivants :

*   **Prédiction de rendement** : *"En tant qu'agriculteur, je veux générer une prédiction de rendement basée sur ma localisation et mon type de culture afin d'anticiper ma production annuelle."*
*   **Gestion spatiale** : *"En tant qu'exploitant, je veux dessiner les contours de ma parcelle sur une carte interactive afin de centraliser mes données géographiques."*
*   **Aide à la décision** : *"En tant qu'utilisateur, je veux recevoir des conseils agronomiques générés par l'IA en fonction de la météo actuelle afin d'optimiser mes interventions (semis, arrosage)."*
*   **Suivi environnemental** : *"En tant que céréalier, je veux consulter l'historique de rayonnement solaire de ma parcelle afin de comprendre l'influence du climat sur ma récolte."*

---

## ✨ Fonctionnalités Clés

*   **🧠 Prédiction intelligente (IA)** : Intégration de **Google Gemini** pour analyser les paramètres complexes et prédire le rendement à l'hectare.
*   **📍 Cartographie interactive** : Dessinez vos parcelles directement sur **Google Maps** pour un suivi géolocalisé précis.
*   **🌤️ Capteurs Virtuels** : Accès instantané aux données de température, précipitations et rayonnement solaire via **Open-Meteo** et **NASA POWER**.
*   **📊 Tableau de bord** : Visualisation claire de l'état de santé de chaque culture et alertes en cas de conditions défavorables.
*   **🤝 Communauté** : Espace d'échange entre pairs pour partager des observations et des bonnes pratiques.

---

## 🌐 Sources de Données & APIs

AgriSense agrège des données provenant de sources fiables pour alimenter son moteur d'IA :

| API | Rôle | Source |
| :--- | :--- | :--- |
| **Open-Meteo** | Météo temps réel et historique climatique | [open-meteo.com](https://open-meteo.com/) |
| **NASA POWER** | Rayonnement solaire, humidité et température du sol | [nasa.gov](https://power.larc.nasa.gov/) |
| **Gemini Pro** | Analyse multivariée et génération de conseils agronomiques | [google.ai](https://ai.google.dev/) |
| **Google Maps** | Rendu cartographique et manipulation des polygones | [google.com](https://developers.google.com/maps) |

---

## 🛠️ Stack Technique

AgriSense repose sur une architecture robuste et moderne :

| Composant | Technologie |
| :--- | :--- |
| **Mobile** | **Flutter** (Dart) — Pour une expérience fluide sur Android & iOS |
| **Backend** | **Python Flask** — API REST performante et flexible |
| **IA** | **Gemini API** — Le cerveau de nos prédictions |
| **Base de données** | **MongoDB Atlas** — Stockage NoSQL pour la flexibilité des données parcelles |
| **Cloud / Infra** | **Azure & Docker** — Déploiement scalable via Container Apps |

---

## 🚀 Démarrage Rapide

### Pré-requis
*   Docker & Docker Compose
*   Une clé API Gemini (Google AI Studio)
*   Une clé API Google Maps

### Installation (via Docker)
1.  Clonez le dépôt :
    ```bash
    git clone https://github.com/MathisBruel/Projet-d-tude2026.git
    cd Projet-d-tude2026
    ```
2.  Configurez les variables d'environnement dans `backend/.env`.
3.  Lancez l'ensemble de la stack :
    ```bash
    docker-compose up --build
    ```

---

## 👥 L'Équipe AgriSense

Projet réalisé dans le cadre du **Bachelor 2 à Sup de Vinci (2025-2026)** par :

*   **Mathis BRUEL** : Chef de projet, Lead Dev Infra & Cloud
*   **Henry TURCAS** : Développeur Frontend Flutter
*   **Antoine SIMONS** : Développeur Backend Flask & MongoDB

---

## 📜 Licence
Distribué sous la licence MIT. Voir `LICENSE` pour plus d'informations.

---
*AgriSense — Cultiver demain, avec l'intelligence d'aujourd'hui.*

# NOTE DE CADRAGE PROJET : AgriSense

**Titre du projet :** AgriSense — Plateforme de prédiction de rendements agricoles par IA  
**Date :** 27/04/2026  
**Rédigé par :** Mathis BRUEL (Chef de projet)

---

## 1. CONTEXTE / PROBLÈME (QQOQCP)

| Axe | Description |
| :--- | :--- |
| **Qui** | Les agriculteurs (ex: céréaliers) et conseillers de la Chambre d'Agriculture. |
| **Quoi** | Difficulté à prévoir les rendements agricoles face à l'instabilité climatique et au coût élevé des capteurs IoT physiques. |
| **Où** | Exploitations agricoles françaises (parcelles géolocalisées). |
| **Quand** | Phase de production sur 3 jours (Lundi-Mercredi), soutenance le Jeudi matin. |
| **Comment** | Application mobile Flutter connectée à un backend Flask, utilisant l'IA (Gemini) et des données environnementales (Open-Meteo, NASA). |
| **Pourquoi** | Améliorer la rentabilité des exploitations et sécuriser les prises de décisions agronomiques via une solution "Software-only". |

---

## 2. OBJECTIFS SMART

*   **Objectif 1 (Technique) :** Déployer une infrastructure Cloud (Azure) fonctionnelle et scalable supportant l'application d'ici Mercredi soir.
*   **Objectif 2 (Produit) :** Livrer un module de prédiction capable de traiter 4 variables climatiques pour estimer un rendement avec un score de confiance d'ici Mardi soir.
*   **Objectif 3 (Démo) :** Présenter une application mobile sans bug critique lors de la démonstration "live" du Jeudi matin (100% du périmètre "Must" validé).

---

## 3. PÉRIMÈTRE

*   **Dans le projet :**
    *   Authentification sécurisée (JWT).
    *   Tableau de bord météo/sol en temps réel.
    *   Gestion cartographique des parcelles (dessin de polygones).
    *   Moteur de prédiction IA (Gemini).
*   **Hors projet :**
    *   Maintenance de capteurs IoT physiques sur le terrain.
    *   Développement de modèles de Machine Learning "from scratch".
    *   Version Web responsive (Focus Mobile uniquement).

---

## 4. PARTIES PRENANTES

| Rôle | Nom | Responsabilités |
| :--- | :--- | :--- |
| **Chef de Projet / Lead Infra** | Mathis BRUEL | Architecture Cloud, Docker, intégration IA, pilotage agile. |
| **Dev Frontend Flutter** | Henry TURCAS | UI/UX mobile, intégration Google Maps. |
| **Dev Backend / DB** | Antoine SIMONS | API REST Flask, modélisation MongoDB, services météo, logique client. |

---

## 5. RESSOURCES PRÉVISIONNELLES

*   **Budget (Estimation Production) :** ~2 800€ à 3 500€ / an (soit env. 250€ - 300€ / mois TTC).
    *   **Hébergement Azure :** ~50€/mois (Container Apps en mode production).
    *   **Base de données :** ~60€/mois (MongoDB Atlas M10 - Instance dédiée).
    *   **APIs IA (Gemini Pro) :** ~80€/mois (Consommation Pay-as-you-go).
    *   **Google Maps :** ~60€/mois (Au-delà du quota gratuit pour le rendu et le géocodage).
*   **Durée :** 3 jours de sprint intensif (Phase MVP).
*   **Équipe projet :** 3 personnes à temps plein.

---

## 6. RISQUES MAJEURS ET ACTIONS PRÉVENTIVES

| Risque | Probabilité | Impact | Action préventive |
| :--- | :--- | :--- | :--- |
| **Indisponibilité API Tierces** (NASA/Gemini) | Moyenne | Élevé | Implémenter des données de repli (fallback) ou un cache local. |
| **Complexité Google Maps Flutter** | Moyenne | Moyen | Utiliser une librairie stable et isoler le module de dessin. |
| **Retard sur le déploiement Azure** | Faible | Élevé | Anticiper le build Docker dès le premier jour (Lundi). |

---

## 7. PROCHAINES ÉTAPES

1.  **Lundi :** Initialisation technique (Git, Docker) et mise en place de l'authentification.
2.  **Mardi :** Développement du cœur de métier (Services météo, IA et Cartographie).
3.  **Mercredi :** Finalisation de l'UI, déploiement sur Azure et tests de bout en bout.
4.  **Jeudi Matin :** Soutenance orale et démonstration live.

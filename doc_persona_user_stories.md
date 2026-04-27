# 👤 Personas & 📋 User Stories — AgriSense

Ce document définit les utilisateurs cibles de la solution AgriSense ainsi que les fonctionnalités attendues sous forme de récits utilisateurs (User Stories).

---

## 1. Persona Principal : Jean-Pierre

**"L'agriculteur traditionnel qui veut passer au numérique sans se ruiner."**

### 🖼️ Profil
*   **Âge :** 45 ans
*   **Localisation :** Beauce, France
*   **Métier :** Céréalier (Blé, Colza, Maïs) sur une exploitation de 150 hectares.
*   **Famille :** Marié, 2 enfants. Exploitation transmise de père en fils.

### 🎯 Objectifs & Motivations
*   **Sécuriser ses revenus :** Savoir à l'avance si sa récolte sera bonne pour négocier ses contrats de vente.
*   **Optimiser ses ressources :** Ne pas arroser ou traiter si ce n'est pas nécessaire.
*   **Modernisation accessible :** Il veut des outils modernes mais refuse d'investir des dizaines de milliers d'euros dans des capteurs connectés (IoT) fragiles et coûteux.

### 😫 Frustrations & Pain Points
*   **Imprévisibilité climatique :** Les saisons ne ressemblent plus à celles de son père ; ses repères habituels sont faussés.
*   **Surcharge administrative :** Il passe déjà trop de temps sur son ordinateur, il veut une solution mobile utilisable directement sur le terrain.
*   **Complexité technique :** Il déteste les logiciels qui demandent une formation de 3 jours.

### 📱 Aisance Numérique
*   **Niveau :** Intermédiaire.
*   Utilise quotidiennement son smartphone pour la météo et les cours du blé, mais se sent vite perdu face à des interfaces trop denses ou trop "data-scientist".

---

## 2. User Stories (Backlog Produit)

Les User Stories sont classées selon la méthode MoSCoW pour prioriser le développement du MVP.

### 🟢 MUST HAVE (Indispensable pour la démo)

| ID | En tant que... | Je veux... | Afin de... | Critères d'acceptation |
| :--- | :--- | :--- | :--- | :--- |
| **US.1** | Jean-Pierre | Créer un compte et me connecter sécurisé | Protéger mes données d'exploitation. | JWT fonctionnel, hashage mot de passe. |
| **US.2** | Jean-Pierre | Dessiner ma parcelle sur une carte | Que l'application sache exactement où se trouvent mes cultures. | Polygone interactif sur Google Maps. |
| **US.3** | Jean-Pierre | Consulter la météo locale en temps réel | Savoir si je peux sortir le tracteur aujourd'hui. | Données Open-Meteo affichées sur le Dashboard. |
| **US.4** | Jean-Pierre | Lancer une prédiction de rendement par IA | Obtenir une estimation en tonnes/hectare avant la récolte. | Appel Gemini API avec retour structuré. |

### 🔵 SHOULD HAVE (Forte valeur ajoutée)

| ID | En tant que... | Je veux... | Afin de... | Critères d'acceptation |
| :--- | :--- | :--- | :--- | :--- |
| **US.5** | Jean-Pierre | Voir l'historique de mes prédictions | Comparer l'évolution de mes estimations au fil du temps. | Liste des prédictions passées stockée en DB. |
| **US.6** | Jean-Pierre | Recevoir des conseils agronomiques | Savoir quelle action corrective entreprendre en cas de stress hydrique. | Texte explicatif généré par Gemini joint à la prédiction. |
| **US.7** | Jean-Pierre | Visualiser l'état du sol (NASA POWER) | Comprendre si mes terres sont assez riches en humidité. | Affichage des indices d'humidité du sol. |

### 🟡 COULD HAVE (Bonus / Futur)

| ID | En tant que... | Je veux... | Afin de... | Critères d'acceptation |
| :--- | :--- | :--- | :--- | :--- |
| **US.8** | Jean-Pierre | Partager mes observations sur un forum | Alerter mes voisins en cas d'invasion de nuisibles ou de maladie. | Système de posts et réponses. |
| **US.9** | Jean-Pierre | Exporter un rapport PDF | Le transmettre à mon banquier ou à ma coopérative. | Génération de fichier PDF téléchargeable. |

---

## 3. Parcours Utilisateur Type (User Journey)

1.  **Installation** : Jean-Pierre télécharge AgriSense et crée son compte en 2 minutes.
2.  **Configuration** : Il se rend au bord de son champ de **blé**, ouvre la carte et trace le contour de sa parcelle.
3.  **Consultation** : Le matin au café, il consulte son Dashboard qui lui indique un rayonnement solaire optimal pour les 3 prochains jours.
4.  **Action** : Il demande une prédiction pour sa parcelle. L'IA lui répond : *"Rendement estimé à **7.5t/ha de blé**. Attention : légère baisse d'humidité du sol prévue, surveillez l'irrigation d'ici vendredi."*
5.  **Décision** : Jean-Pierre programme son arrosage, rassuré par les données.

---

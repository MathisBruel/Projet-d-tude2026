# ADR — Architecture Decision Record
## AgriSense — Projet d'études Bachelor 2

**Date** : 2026-04-27 | **Version** : 1.0

---

## 📋 Résumé des décisions clés

| # | Décision | Choix | Justification |
|---|---|---|---|
| **001** | **Infra cloud** | Azure Container Apps | Serverless, auto-scaling, HTTPS natif. K8s rejeté (complexité) |
| **002** | **Conteneurisation** | Docker + Compose | Dev-prod parity, portabilité |
| **003** | **Backend API** | Python Flask | Légèreté, rapidité dev, équipe Python |
| **004** | **Authentification** | JWT stateless | Scalabilité mobile, pas de session store |
| **005** | **Base données** | MongoDB self-hosted (Azure VM) | Flexibilité schéma, contrôle total, coûts maîtrisés |
| **006** | **IA prédictions** | Google Gemini API | Gratuit (AI Studio), performance < 5s, intégration simple |
| **007** | **Données météo/sol** | Open-Meteo + NASA POWER | APIs gratuites, couverture globale, "capteurs IoT" virtuels |
| **008** | **Frontend mobile** | Flutter (Dart) | Cross-platform Android + iOS, ecosystème mature, équipe Flutter disponible |
| **009** | **Cartes** | Google Maps API | Plugin officiel Flutter, UX native, tier gratuit suffisant |
| **010** | **Branching Git** | Feature branches + PR | Timeboxé (3 jours), code review simple, main stable |
| **011** | **Sécurité** | HTTPS + JWT + Rate Limit | Standard industry, scalable |
| **012** | **Monitoring** | Azure Monitor | Natif Azure, gratuit, logs centralisés |

---

## 🎯 Principes de conception

### Time-to-market vs perfection
**Priorité absolue** : démo live fonctionnelle (30 pts notation). Infrastructure simple, pas de Kubernetes, pas de micro-services complexity.

### Une seule personne expertise infra
**Mathis** maîtrise : Azure, Docker, Flask, APIs. → **Zero-ops** (Container Apps gère tout).

### Tech stack gratuit/free-tier
- **MongoDB** : free-tier 512 MB
- **Gemini API** : $200/mois crédit Google
- **Open-Meteo** : 100% gratuit
- **Azure Student** : crédit $100/an
- **Total mensuel** : ~50€ pour démo

### Équipe avec niveaux mixtes
- Henry (Flutter) : moyen
- Antoine (Flask) : moyen  
→ Patterns simples, conventions claires, documentation

---

## 🚀 Trade-offs documentés

### Infrastructure
- ✅ **Container Apps** : serverless, simple deployment
- ❌ **Versus K8s** : coûterait 2-3 jours ops, Mathis seul, trop complex pour 3j
- ❌ **Versus VMs** : gestion manuelle, pas scalable

### Database
- ✅ **MongoDB** : schéma flexible (predictions peut évoluer)
- ❌ **Versus PostgreSQL** : surcoûts ops, schéma rigid
- ❌ **Versus Firebase** : vendor lock-in, plus cher

### IA
- ✅ **Gemini API** : gratuit, prompt engineering simple
- ❌ **Versus OpenAI** : payant, plus cher
- ❌ **Versus custom ML** : coûterait 10+ jours, dataset training nécessaire

### Frontend
- ✅ **Flutter** : une codebase Android + iOS
- ❌ **Versus React Native** : JS bridge overhead
- ❌ **Versus natif** : double travail Android/iOS

---

## 📌 Contraintes du projet

| Contrainte | Impact | Décision |
|---|---|---|
| **3 jours production** | Pas de complexité infra | Container Apps simple |
| **Soutenance 15 min** | Démo live critique | Code stable, tests avant démo |
| **1 lead infra (Mathis)** | Pas de K8s/multi-cloud | Azure seul, serverless |
| **Équipe junior/moyen** | Patterns clairs, docs | Flask + Flutter standards |
| **Budget proche zéro** | Gratuit/free-tier | Open APIs, no vendor lock |

---

## ✅ Validation des choix

Chaque décision a été validée contre :
1. **Faisabilité** : réaliste avec l'équipe et timeboxe
2. **Coûts** : free-tier ou < 100€/mois
3. **Démo** : visible et testable en direct
4. **Scalabilité** : peut supporter 100+ utilisateurs
5. **Sécurité** : HTTPS, JWT, secrets gérés

---

## 📖 Lectures connexes

- **DAT** : Détails infra, déploiement, sécurité
- **DCT** : Stack logiciel, architecture apps
- **Diagrammes** : `dat_architecture.puml`, `dct_architecture.puml`

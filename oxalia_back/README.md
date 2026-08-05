# OXALIA Backend

[![Python](https://img.shields.io/badge/python-3.11%2B-blue)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.139-009688)](https://fastapi.tiangolo.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-async-336791)](https://www.postgresql.org/)
[![Tests](https://img.shields.io/badge/tests-pytest-0A9EDC)](https://docs.pytest.org/)
[![License](https://img.shields.io/badge/license-Proprietary-lightgrey)]()

API backend de la **OXALIA Mobile Inference Platform** : authentification sécurisée, ingestion d'images médicales et orchestration de l'inférence par un modèle d'intelligence artificielle interchangeable (OXALIA 2D).

---

## Sommaire

- [Aperçu](#aperçu)
- [Stack technique](#stack-technique)
- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Migrations de base de données](#migrations-de-base-de-données)
- [Lancement](#lancement)
- [Tests](#tests)
- [Référence API](#référence-api)
- [Sécurité](#sécurité)
- [Conventions de code](#conventions-de-code)
- [Dépannage](#dépannage)
- [Roadmap](#roadmap)

---

## Aperçu

Ce service expose une API REST consommée par l'application mobile OXALIA. Il gère :

| Domaine                 | Responsabilité                                                                              |
| ----------------------- | ------------------------------------------------------------------------------------------- |
| **Authentification**    | Inscription, connexion, rotation de tokens JWT, contrôle d'accès par rôle (RBAC)            |
| **Gestion des examens** | Réception et validation d'images médicales, stockage sécurisé                               |
| **Inférence IA**        | Orchestration asynchrone de l'analyse d'image via un contrat `ModelAdapter` interchangeable |

Le modèle d'IA final (OXALIA 2D) n'est pas encore intégré : un adaptateur placeholder (`StubModelAdapter`) simule le comportement attendu, permettant de livrer et valider toute l'infrastructure indépendamment de l'avancement du volet recherche IA.

## Stack technique

| Composant                | Technologie                              |
| ------------------------ | ---------------------------------------- |
| Framework API            | FastAPI (async)                          |
| Base de données          | PostgreSQL                               |
| ORM                      | SQLAlchemy 2.0 (async) + asyncpg         |
| Migrations               | Alembic                                  |
| Authentification         | JWT (access + refresh tokens révocables) |
| Hachage de mots de passe | bcrypt                                   |
| Validation de données    | Pydantic v2 / pydantic-settings          |
| Tests                    | pytest, pytest-asyncio, httpx            |
| Documentation API        | OpenAPI 3 / Swagger UI                   |

## Architecture

Architecture en couches (_layered architecture_), avec un flux de dépendance strict à sens unique :

```
Router  →  Service  →  Repository  →  Model (ORM)
  │           │             │
  │           │             └── Accès base de données (requêtes SQLAlchemy)
  │           └── Logique métier, validations, orchestration
  └── Contrat HTTP, DI (auth, sessions), sérialisation
```

```
app/
├── core/            # Sécurité (JWT, bcrypt), dépendances FastAPI (auth, RBAC), contrat ModelAdapter
├── models/          # Entités ORM : User, RefreshToken, Exam, InferenceResult
├── schemas/         # Contrats Pydantic (DTO d'entrée/sortie API)
├── repositories/     # Couche d'accès aux données
├── services/         # Logique métier (auth_service, image_service, inference_orchestrator)
├── routers/          # Endpoints HTTP (auth, exams)
├── config.py         # Configuration typée (variables d'environnement)
├── database.py       # Engine et sessions SQLAlchemy async
└── main.py           # Point d'entrée de l'application FastAPI
```

**Principe directeur** : chaque couche n'est couplée qu'à la couche immédiatement inférieure. Les routers ignorent SQLAlchemy, les services ignorent HTTP. Cela garantit la testabilité et la capacité à faire évoluer une couche sans effet de bord sur les autres — notamment le remplacement futur du modèle IA.

## Prérequis

- Python ≥ 3.11
- PostgreSQL ≥ 14 (une instance dev, une instance de test dédiée)
- `pip` et `venv`

## Installation

```bash
cd oxalia_back
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # macOS / Linux

pip install -r requirements.txt
```

## Configuration

Créer un fichier `.env` à la racine de `oxalia_back/` :

```env
# Base de données
DATABASE_URL=postgresql+asyncpg://<user>:<password>@localhost:5432/oxalia

# Authentification
JWT_SECRET_KEY=<clé secrète forte, générée aléatoirement>
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_MINUTES=10080

# Application
PROJECT_NAME=OXALIA Mobile Inference Platform
ENVIRONMENT=development

# Upload d'images
UPLOAD_DIR=uploads
MAX_UPLOAD_SIZE_MB=10
ALLOWED_CONTENT_TYPES=image/jpeg,image/png
```

> **Sécurité** : `JWT_SECRET_KEY` ne doit jamais être commité. Utiliser un gestionnaire de secrets (Vault, AWS Secrets Manager, GitHub Actions Secrets) en environnement de production.

Toutes les variables sont validées au démarrage via `pydantic-settings` (`app/config.py`) — l'application refuse de démarrer si une variable requise est manquante ou invalide.

## Migrations de base de données

Gérées avec Alembic, connecté au moteur async de l'application (`alembic/env.py`).

```bash
# Appliquer toutes les migrations en attente
alembic upgrade head

# Générer une nouvelle migration après modification d'un modèle ORM
alembic revision --autogenerate -m "add exam status column"

# Revenir en arrière d'une révision
alembic downgrade -1
```

## Lancement

```bash
uvicorn app.main:app --reload
```

| Ressource    | URL                                  |
| ------------ | ------------------------------------ |
| API          | `http://localhost:8000`              |
| Swagger UI   | `http://localhost:8000/docs`         |
| ReDoc        | `http://localhost:8000/redoc`        |
| OpenAPI JSON | `http://localhost:8000/openapi.json` |

## Tests

Une base PostgreSQL dédiée (`oxalia_test`) est requise, distincte de la base de développement.

```bash
pytest                      # suite complète
pytest tests/unit           # tests unitaires uniquement (sans I/O réseau/DB)
pytest tests/integration    # tests d'intégration (DB + client HTTP in-memory)
pytest -v                   # sortie détaillée
```

### Stratégie de test

| Type        | Emplacement          | Portée                                                                                            |
| ----------- | -------------------- | ------------------------------------------------------------------------------------------------- |
| Unitaire    | `tests/unit/`        | Fonctions pures : sécurité (hash, JWT), validation d'upload                                       |
| Intégration | `tests/integration/` | Flux complets via `httpx.AsyncClient` contre l'app FastAPI en mémoire, avec vraie base de données |

Chaque test s'exécute dans une **transaction isolée avec savepoints** : les commits applicatifs sont conservés pendant le test mais annulés (`rollback`) à la fin, garantissant qu'aucun test ne pollue l'état des suivants.

## Référence API

### Authentification — `/auth`

| Méthode | Endpoint            | Description                              | Auth          |
| ------- | ------------------- | ---------------------------------------- | ------------- |
| `POST`  | `/auth/register`    | Créer un compte                          | —             |
| `POST`  | `/auth/login`       | Obtenir une paire de tokens              | —             |
| `POST`  | `/auth/refresh`     | Renouveler l'access token                | Refresh token |
| `POST`  | `/auth/logout`      | Révoquer le refresh token                | Bearer        |
| `GET`   | `/auth/me`          | Profil de l'utilisateur courant          | Bearer        |
| `GET`   | `/auth/admin-check` | Démonstration RBAC (rôle `admin` requis) | Bearer + rôle |

### Examens — `/exams`

| Méthode | Endpoint                  | Description                                                      | Auth   |
| ------- | ------------------------- | ---------------------------------------------------------------- | ------ |
| `POST`  | `/exams/upload`           | Upload d'image + déclenchement de l'inférence en arrière-plan    | Bearer |
| `GET`   | `/exams/{exam_id}`        | Statut de l'examen (`pending`/`processing`/`completed`/`failed`) | Bearer |
| `GET`   | `/exams/{exam_id}/result` | Résultat structuré de l'inférence                                | Bearer |

Spécification complète et testable interactivement via Swagger UI (`/docs`).

## Sécurité

- **Mots de passe** : hachés avec bcrypt, jamais stockés ni journalisés en clair
- **Tokens** : access tokens JWT courte durée ; refresh tokens longue durée, hashés en base et révocables individuellement (déconnexion effective, pas seulement côté client)
- **Upload de fichiers** :
  - Validation de la taille (rejet des fichiers vides et surdimensionnés)
  - Validation du type MIME déclaré par le client
  - **Vérification des magic bytes réels** du fichier, pour empêcher qu'un fichier arbitraire soit accepté en falsifiant son `Content-Type`
- **Autorisation** : RBAC appliqué via la dépendance `require_role`, isolation stricte des ressources par propriétaire (`owner_id`)

## Conventions de code

- Architecture en couches strictement respectée : pas d'accès direct à la base depuis un router, pas de dépendance FastAPI dans un repository
- Schémas Pydantic distincts pour l'entrée (`*Create`, `*Request`) et la sortie (`*Out`) — aucune donnée sensible (hash de mot de passe, etc.) n'est jamais sérialisée
- Le contrat `ModelAdapter` (`app/core/model_adapter.py`) est la seule interface autorisée pour brancher un modèle d'IA — aucune logique métier ne doit dépendre directement d'une implémentation concrète

## Dépannage

| Symptôme                                      | Cause probable                      | Solution                                                                          |
| --------------------------------------------- | ----------------------------------- | --------------------------------------------------------------------------------- |
| `ModuleNotFoundError: No module named 'app'`  | Tests lancés hors du bon répertoire | Lancer `pytest` depuis `oxalia_back/`, ou vérifier `pythonpath` dans `pytest.ini` |
| `ValidationError` au démarrage sur `Settings` | Variable d'environnement manquante  | Vérifier que `.env` contient toutes les clés requises                             |
| `password authentication failed`              | Identifiants PostgreSQL incorrects  | Vérifier `DATABASE_URL` dans `.env`                                               |
| Bouton "Authorize" absent dans Swagger        | Aucun endpoint protégé référencé    | S'assurer qu'au moins une route dépend de `get_current_user`                      |

## Roadmap

- [ ] Intégration du modèle OXALIA 2D en remplacement de `StubModelAdapter`
- [ ] Conteneurisation (Docker) et déploiement Kubernetes
- [ ] Pipeline CI/CD complet (lint, tests, build, déploiement)
- [ ] Observabilité (logs structurés, métriques, tracing)

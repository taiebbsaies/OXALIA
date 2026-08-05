# OXALIA — Mobile Inference Platform

Production-oriented platform for **AI-assisted chest X-ray analysis**. Clinicians capture or import an image from a Flutter mobile app; a FastAPI backend validates the upload, runs asynchronous inference through a **swappable model adapter**, and returns structured findings. The current AI slot is a stub (`StubModelAdapter`) so the full product can ship and be tested before OXALIA 2D is plugged in.

```
OXALIA/
├── oxalia_back/     # FastAPI + PostgreSQL API
├── oxalia_front/    # Flutter (Android / iOS) client
└── .github/         # CI (backend + frontend + Docker build)
```

---

## What we built

| Area | Backend | Frontend |
| --- | --- | --- |
| **Auth** | Register / login, JWT access + revocable refresh tokens, RBAC | Login / register screens, secure token storage, session restore, route guards |
| **Theme** | — | Light / dark / system (`AppPalette` + Profile toggle) |
| **Navigation** | — | Intro Lottie → auth → shell (Home / History / Profile) with Obsidian nav bar |
| **Capture** | Image validation (size, MIME, magic bytes), disk storage | Camera / gallery, native compress (`flutter_image_compress`), HEIC→JPEG, EXIF strip |
| **Inference** | Background task, status machine, stub model with findings | Auto pipeline after pick, upload retry + progress, polling, scanner + result UI |
| **History & Home** | List exams, stats aggregates, serve stored image | Stats cards, 3 recent analyses, full history, detail + PDF report |
| **CI** | pytest, ruff, pip-audit, Docker build | `flutter analyze` + `flutter test` |

---

## Architecture (end-to-end)

```mermaid
flowchart LR
  App[Flutter app] -->|JWT + multipart| API[FastAPI]
  API --> DB[(PostgreSQL)]
  API --> Disk[uploads/]
  API -->|BackgroundTasks| Orch[Inference orchestrator]
  Orch --> Adapter[ModelAdapter / Stub]
  Adapter --> Orch
  Orch --> DB
  App -->|poll status + result| API
```

**Backend layers:** Router → Service → Repository → ORM  
**Frontend layers:** View → ViewModel (Provider) → Repository → Service (Dio)

The AI contract is a single interface (`ModelAdapter`). Replacing the stub with the real OXALIA 2D model does not require changing routers or the mobile client contract.

---

## Stack

| Layer | Technologies |
| --- | --- |
| API | Python 3.11+, FastAPI, SQLAlchemy 2 (async), Alembic, Pydantic v2, PyJWT, bcrypt |
| DB | PostgreSQL 16 |
| Mobile | Flutter, Provider, GoRouter, Dio, `image_picker`, `flutter_image_compress`, Lottie, `pdf` / `printing` |
| Ops | Docker Compose, GitHub Actions |

---

## Quick start

### 1. Backend

**Option A — Docker Compose** (API + Postgres):

```bash
cd oxalia_back
docker compose up --build
```

**Option B — Local:**

```bash
cd oxalia_back
python -m venv venv
# Windows: venv\Scripts\activate
# macOS/Linux: source venv/bin/activate
pip install -r requirements.txt
```

Create `oxalia_back/.env` (never commit secrets):

```env
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/oxalia
JWT_SECRET_KEY=<strong-random-secret>
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_MINUTES=10080
PROJECT_NAME=OXALIA Mobile Inference Platform API
ENVIRONMENT=development
UPLOAD_DIR=uploads
MAX_UPLOAD_SIZE_MB=10
ALLOWED_CONTENT_TYPES=image/jpeg,image/png
```

Start Postgres, then:

```bash
alembic upgrade head
uvicorn app.main:app --reload
```

| Resource | URL |
| --- | --- |
| API | http://localhost:8000 |
| Swagger | http://localhost:8000/docs |
| Health | http://localhost:8000/health |

Tests (dedicated DB `oxalia_test` recommended):

```bash
pytest -q
ruff check app tests
ruff format --check app tests
```

### 2. Frontend

```bash
cd oxalia_front
flutter pub get
```

Create `oxalia_front/.env` (bundled as an asset):

```env
# Android emulator → host machine
API_BASE_URL=http://10.0.2.2:8000
# iOS simulator
# API_BASE_URL=http://127.0.0.1:8000
# Physical device → your PC LAN IP
# API_BASE_URL=http://192.168.x.x:8000
```

iOS already declares camera / photo library usage in `Info.plist`.

```bash
flutter run
flutter analyze
flutter test
```

---

## API surface (summary)

### Auth — `/auth`

| Method | Path | Description |
| --- | --- | --- |
| `POST` | `/auth/register` | Create account |
| `POST` | `/auth/login` | Access + refresh tokens |
| `POST` | `/auth/refresh` | Rotate access token |
| `POST` | `/auth/logout` | Revoke refresh token |
| `GET` | `/auth/me` | Current user |

### Exams — `/exams` (Bearer)

| Method | Path | Description |
| --- | --- | --- |
| `POST` | `/exams/upload` | Upload image → schedule inference |
| `GET` | `/exams` | List current user’s exams (paginated) |
| `GET` | `/exams/stats` | Totals + per-status + model version usage |
| `GET` | `/exams/{id}` | Exam status |
| `GET` | `/exams/{id}/result` | Findings JSON (when completed) |
| `GET` | `/exams/{id}/image` | Stored image bytes |

Exam status: `pending` → `processing` → `completed` | `failed`.

---

## Mobile product flow

1. **Intro** — Lottie intro once per launch while session is validated  
2. **Auth** — Register / sign in  
3. **Home** — Activity stats, New Analysis CTA, 3 recent exams  
4. **New Analysis** — Scanner UI → gallery/camera → client preprocess → upload (retry + fluid progress) → poll → result card  
5. **Result** — Top prediction, confidence, color-coded findings, download PDF report  
6. **History** — Full list → same detail / result UI  
7. **Profile** — Theme (system / light / dark), logout  

---

## Security highlights

- Passwords hashed with bcrypt  
- Short-lived JWT access tokens; refresh tokens hashed and revocable server-side  
- Uploads checked for empty/oversized files, declared MIME, and **real magic bytes**  
- Exams and images scoped strictly to `owner_id`  

---

## Project docs

- Backend detail: [oxalia_back/README.md](oxalia_back/README.md)  
- Frontend: Flutter project under `oxalia_front/` (this root README is the app overview)  
- Interactive API: `/docs` when the server is running  

---

## Roadmap

- [ ] Swap `StubModelAdapter` for the real OXALIA 2D / TorchXRayVision adapter  
- [ ] Push / local notifications when long-running inference completes  
- [ ] Patient records linked to exams  
- [ ] Production secrets, observability, and hardened deployment  

---

## License

Proprietary — OXALIA team.

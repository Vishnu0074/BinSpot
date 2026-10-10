# BinSpot Django API

The Django REST API lives in this directory and is the single source of truth for authentication and bin data. Firebase has been removed from the Flutter client.

## Local setup

```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
copy .env.example .env  # Windows PowerShell; then edit if needed
# macOS/Linux: cp .env.example .env
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

Health check: `GET /api/health/`

## API endpoints

- `POST /api/auth/register/` with `email` and `password`
- `POST /api/auth/login/` with `email` and `password`; returns a token
- `GET /api/auth/me/` with `Authorization: Token <token>`
- `POST /api/auth/logout/` with token
- `GET /api/bins/` (public list)
- `POST /api/bins/` (authenticated create)
- `GET /api/bins/<id>/` (public details)
- `PATCH /api/bins/<id>/` and `DELETE /api/bins/<id>/` (owner or admin only)
- `POST /api/bins/<id>/upvote/`

The Flutter default points at `http://10.0.2.2:8000/api` for the Android emulator. Override it with `--dart-define=API_BASE_URL=https://your-host/api` for a hosted API. For a physical device, use the development computer's LAN IP; for production, use HTTPS.

Before deploying, set `DJANGO_SECRET_KEY`, `DJANGO_DEBUG=false`, `DJANGO_ALLOWED_HOSTS`, and `DATABASE_URL` as environment variables. Never use the sample key in production. The old repository's committed SQLite database and Python bytecode were intentionally not copied. Migrations create a clean database; existing Firebase accounts and Firestore bins are not automatically migrated.

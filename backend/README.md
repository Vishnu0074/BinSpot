# BinSpot Django API

The Django REST API lives in this directory and is the app's single source of truth for authentication and bin data. Firebase has been removed from the Flutter client.

## Local setup

```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # edit DJANGO_SECRET_KEY and allowed hosts
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

Health check: `GET /api/health/`

## Endpoints

- `POST /api/auth/register/` with `email`, `password`
- `POST /api/auth/login/` with `username` (email) and `password`; response includes a DRF token
- `GET /api/auth/me/` with `Authorization: Token <token>`
- `POST /api/auth/logout/` with token
- `GET /api/bins/`, `POST /api/bins/`
- `GET /api/bins/<id>/`, `PATCH /api/bins/<id>/`, `DELETE /api/bins/<id>/`
- `POST /api/bins/<id>/upvote/`

The development default in Flutter points at `http://10.0.2.2:8000/api` for the Android emulator. Override with `--dart-define=API_BASE_URL=https://your-host/api` for a hosted API. For physical devices use the development machine's LAN IP; for production use HTTPS.

Set `DJANGO_SECRET_KEY`, `DJANGO_DEBUG=false`, `DJANGO_ALLOWED_HOSTS`, and `DATABASE_URL` as host environment variables. Never deploy with the example key. The committed SQLite database was intentionally not copied; migrations create a clean database. Existing Firebase accounts/data are not automatically migrated.

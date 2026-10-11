# BinSpot Django API

Django REST API for BinSpot. Firebase is not used.

## Local setup
```bash
cd backend
python -m venv .venv
# Windows PowerShell: .venv\Scripts\Activate.ps1
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

## Endpoints
- `GET /api/health/`
- `POST /api/auth/register/`, `POST /api/auth/login/`, `GET /api/auth/me/`, `POST /api/auth/logout/`
- `GET /api/bins/?lat=9.26&lng=76.77&radius_km=5&limit=20` returns the nearest 20 bins in a 5 km radius. Use `limit=100` to reveal more.
- `POST /api/bins/` requires a token; fields include latitude, longitude, type, description and access_level (`public`, `limited`, `private`; default `public`).
- `GET /api/bins/<id>/`, `PATCH /api/bins/<id>/`, `DELETE /api/bins/<id>/`
- `POST /api/bins/<id>/upvote/`
- `GET /api/contributors/top/` returns the top 10 contributors and nature-themed titles.

## Render deployment
Set root directory to `backend` in Render (or prefix commands with `cd backend &&`), build command `pip install -r requirements.txt`, and start command `python manage.py migrate && python manage.py collectstatic --noinput && gunicorn binspot_backend.wsgi:application --bind 0.0.0.0:$PORT`.
Set `DJANGO_SECRET_KEY` to a strong secret, `DJANGO_DEBUG=false`, `DJANGO_ALLOWED_HOSTS` to the Render hostname, and `DATABASE_URL` to a persistent PostgreSQL database. Existing Firebase data is not migrated automatically.

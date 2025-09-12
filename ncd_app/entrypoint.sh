#!/usr/bin/env sh
set -e

# Apply migrations
python manage.py migrate --noinput

# Collect static (if you later configure STATIC_ROOT)
# python manage.py collectstatic --noinput

# Start Gunicorn
exec gunicorn ncd_app.wsgi:application \
  --bind 0.0.0.0:8000 \
  --workers 3 \
  --threads 2 \
  --timeout 60



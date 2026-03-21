#!/bin/sh
set -e
# Build image
docker build -t fhck-backend .

# Host port (default 8000). Override with HOST_PORT env var: HOST_PORT=8080 ./run.sh
HOST_PORT=${HOST_PORT:-8000}

# Run container: применить миграции и запустить dev сервер на 0.0.0.0:8000
docker run --rm \
  -p ${HOST_PORT}:8000 \
  --env-file entry_point/.env \
  --name fhck-backend \
  fhck-backend \
  sh -c "python entry_point/manage.py migrate --noinput && python entry_point/manage.py runserver 0.0.0.0:8000"

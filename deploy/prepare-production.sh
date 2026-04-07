#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Falta .env en la raíz del proyecto." >&2
  exit 1
fi

echo ">> composer install --no-dev --optimize-autoloader"
composer install --no-dev --optimize-autoloader --no-interaction

if command -v npm >/dev/null 2>&1; then
  if [[ -f package-lock.json ]] || [[ -f npm-shrinkwrap.json ]]; then
    echo ">> npm ci && npm run production"
    npm ci
  else
    echo ">> npm install && npm run production (no hay package-lock.json)"
    npm install
  fi
  npm run production
else
  echo ">> npm no encontrado; omite compilación de assets (ejecuta npm run production en otro entorno)." >&2
fi

echo ">> artisan optimize (sin route:cache: este proyecto usa rutas con closures)"
php artisan config:cache
php artisan view:cache

echo "Listo. Sube el proyecto al servidor excluyendo node_modules y archivos de desarrollo según deploy/namecheap.txt"

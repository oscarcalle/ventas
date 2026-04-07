#!/usr/bin/env bash
# Genera un ZIP listo para subir a Namecheap (sin node_modules, sin .env, con vendor de producción).
# Uso:
#   ./deploy/package-for-namecheap.sh
#   USE_DOCKER=1 ./deploy/package-for-namecheap.sh   # si composer/npm solo existen en Docker
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M)"
ARCHIVE_NAME="ventas-namecheap-${STAMP}.zip"
TMP="$(mktemp -d)"
DEST="${TMP}/ventas"

cd "$ROOT"

# Composer necesita PHP. Si no hay PHP en el host, usar el contenedor (igual que USE_DOCKER=1).
if [[ "${USE_DOCKER:-}" == "1" ]]; then
  COMPOSER_IN_DOCKER=1
elif [[ "${USE_DOCKER:-}" == "0" ]]; then
  COMPOSER_IN_DOCKER=0
elif command -v php >/dev/null 2>&1; then
  COMPOSER_IN_DOCKER=0
else
  echo ">> PHP no está en PATH; usando composer dentro del contenedor Docker."
  COMPOSER_IN_DOCKER=1
fi

if [[ "$COMPOSER_IN_DOCKER" == "1" ]]; then
  if ! docker compose exec -T app php -v >/dev/null 2>&1; then
    echo "No se pudo ejecutar PHP en Docker. Levanta el stack: docker compose up -d" >&2
    exit 1
  fi
fi

run_composer() {
  if [[ "$COMPOSER_IN_DOCKER" == "1" ]]; then
    docker compose exec -T app composer "$@"
  else
    composer "$@"
  fi
}

run_npm() {
  npm "$@"
}

echo ">> composer install --no-dev (producción)"
# --ignore-platform-reqs: el lock suele venir de PHP 7.x; lcobucci/jwt 3.x y similares no declaran PHP 8 aunque en producción funcione.
run_composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs

if [[ "${SKIP_NPM:-}" != "1" ]]; then
  if [[ -f package.json ]]; then
    if [[ -f package-lock.json ]] || [[ -f npm-shrinkwrap.json ]]; then
      echo ">> npm ci && npm run production"
      run_npm ci
    else
      echo ">> No hay package-lock.json; usando npm install && npm run production"
      echo ">> (Opcional: ejecuta una vez «npm install» y sube package-lock.json al repo para builds reproducibles.)"
      run_npm install
    fi
    run_npm run production
  fi
else
  echo ">> SKIP_NPM=1: no se compilaron assets; asegúrate de haber ejecutado antes: npm run production"
fi

echo ">> Copiando proyecto a carpeta temporal (excluye basura vía rsync)..."
mkdir -p "$DEST"
rsync -a \
  --exclude-from="${ROOT}/deploy/rsync-exclude.txt" \
  "${ROOT}/" "${DEST}/"

OUT="${ROOT}/deploy/${ARCHIVE_NAME}"
rm -f "$OUT"
(
  cd "$TMP"
  zip -r -q "$OUT" ventas
)
rm -rf "$TMP"

BYTES="$(stat -c%s "$OUT" 2>/dev/null || stat -f%z "$OUT")"
echo ">> Listo: ${OUT} ($(numfmt --to=iec-i --suffix=B "$BYTES" 2>/dev/null || echo "${BYTES} bytes"))"
echo ">> Sube el ZIP, descomprime en el hosting, crea .env en el servidor (datos de tu BD Namecheap), document root = public/"

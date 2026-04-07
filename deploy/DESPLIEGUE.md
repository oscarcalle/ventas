# Flujo local → producción (resumen)

## 1. Desarrollo en local (Docker)

```bash
cp .env.example .env
docker compose up -d --build
docker compose exec app composer install
docker compose exec app php artisan key:generate
docker compose exec app chmod -R ug+rwx storage bootstrap/cache
```

- Abre **http://localhost:8080** (MySQL del `.env` apunta al servicio `mysql` del compose).
- Cambios en **PHP/Laravel**: se reflejan al vuelo (carpeta montada).
- Cambios en **Vue/SCSS** (`resources/`): en tu PC, `npm install` y `npm run dev` (o `npm run production` para probar el build final).

---

## 2. Antes de subir a producción

En tu máquina (con Node instalado; Composer puede ir por Docker si no tienes PHP):

```bash
./deploy/package-for-namecheap.sh
```

Esto:

- Ejecuta `composer install --no-dev` (usa Docker si no hay `php` en el PATH).
- Instala dependencias npm y ejecuta `npm run production`.
- Genera un ZIP en **`deploy/ventas-namecheap-FECHA-HORA.zip`**.

Alternativas:

- Sin recompilar JS: `SKIP_NPM=1 ./deploy/package-for-namecheap.sh` (solo si ya compilaste antes).
- Solo detalles de hosting: ver `deploy/namecheap.txt`.

---

## 3. En el servidor (Namecheap / cPanel)

1. **Document root** del dominio apuntando a la carpeta **`public`** del proyecto (no subir solo `public`; la raíz del sitio debe ser `.../tu-proyecto/public`).
2. Sube y descomprime el ZIP (o sube por FTP los archivos cambiados si prefieres actualizar solo parte).
3. **` .env`**: en el servidor, con `APP_URL=https://tudominio.com`, datos reales de MySQL y `APP_DEBUG=false`. No subas `.env` al repositorio.
4. Si tienes **SSH**: permisos en `storage/` y `bootstrap/cache/`, `php artisan storage:link`, migraciones si aplica (`php artisan migrate --force`), `php artisan config:cache` y `php artisan view:cache`. **No** uses `php artisan route:cache` en este proyecto.
5. **SSL** (Let’s Encrypt) activo para HTTPS.

---

## 4. Tras el primer despliegue

- Asistente web: **`/setup`** (una vez).
- Usuario por defecto tras el seed del instalador: **`admin@example.com`** / **`123456`** — cámbialo en producción.

---

## 5. Ciclo habitual “modifiqué código → subo otra vez”

1. Local: pruebas + `npm run production` si tocaste front.
2. Genera el ZIP con `./deploy/package-for-namecheap.sh` **o** sube solo los archivos que cambiaron (sin `node_modules`).
3. En el servidor: si cambió solo código PHP, a veces basta subir archivos y `php artisan config:clear` / `config:cache`; si hubo migraciones, `php artisan migrate --force`.

---

*Más detalle Docker: `deploy/local-docker.txt`. Detalle hosting: `deploy/namecheap.txt`.*

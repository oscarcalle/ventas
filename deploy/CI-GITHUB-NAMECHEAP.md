# Despliegue automático con GitHub → Namecheap (Stellar)

Es posible: cada `git push` a una rama (p. ej. `main`) puede disparar un **GitHub Action** que actualice el hosting. Namecheap no tiene integración nativa con GitHub; el “pegamento” es el workflow.

**Este repositorio** (`.github/workflows/deploy.yml`) usa **SSH + rsync**: en GitHub Actions se ejecutan `composer` y `npm run production`, y el resultado se sincroniza al servidor con `rsync` (sin `--delete`, para no borrar ficheros que solo existan en el servidor, p. ej. subidas). Después se conecta por SSH y ejecuta `artisan migrate`, `config:cache` y `view:cache`.

Secrets necesarios: `SSH_HOST`, `SSH_USER`, `SSH_PATH`, `SSH_PRIVATE_KEY`; opcionales `SSH_PORT` (a menudo **21098** en Stellar) y `SSH_PHP` si el comando `php` del servidor no es el correcto.

## Qué necesitas

| Requisito | Para qué sirve |
|-----------|----------------|
| Repositorio en **GitHub** | Donde subes el código y se ejecutan los Actions |
| **SSH** en el hosting (ideal) | Clonar o `git pull` en el servidor y ejecutar `composer` / `artisan` |
| O bien **FTP/SFTP** | Subir archivos sin SSH (más limitado) |
| **Secrets** en GitHub | Contraseña FTP, o clave SSH privada — nunca en el código |

**Stellar:** comprueba en cPanel si tienes **“Terminal” / SSH Access**. Sin SSH, usa despliegue por **SFTP/FTP** desde el Action.

---

## Opción A — SSH + `git pull` (recomendada si tienes SSH)

1. En el servidor (por SSH), una sola vez:
   - Clona el repo en una carpeta **fuera** de `public_html` o usa la ruta donde ya tienes el proyecto, p. ej. `~/factura.liversoft.com`.
   - El **document root** en cPanel debe seguir apuntando a `.../public` (como ya configuraste).

2. En GitHub → **Settings → Secrets and variables → Actions**, crea secretos, por ejemplo:
   - `SSH_HOST` — ej. `server123.hosting.com` o la IP que te dé Namecheap  
   - `SSH_USER` — usuario SSH de cPanel  
   - `SSH_PRIVATE_KEY` — clave privada (la pública va en `~/.ssh/authorized_keys` del servidor)

3. Añade un workflow `.github/workflows/deploy.yml` que:
   - Se dispare en `push` a `main`
   - Se conecte por SSH y ejecute algo como:
     ```bash
     cd ~/ruta/al/proyecto && git pull origin main && composer install --no-dev --optimize-autoloader --no-interaction && php artisan migrate --force && php artisan config:cache && php artisan view:cache
     ```
   - **No** ejecutes `npm` en el servidor si no está instalado: compila assets **en el Action** antes (`npm ci && npm run production`) y sube `public/js` y `public/css`, o hazlo en local y sube el ZIP como hasta ahora.

4. **Rama protegida:** solo `main` despliega; las ramas de feature hacen PR.

**Nota:** Si el proyecto en el servidor no es un clon de Git sino archivos subidos por FTP, conviene **reemplazarlo una vez** por un `git clone` del repo para poder hacer `git pull` limpio.

---

## Opción B — Sin SSH: despliegue por SFTP/FTP

1. Crea un usuario FTP/SFTP en cPanel con acceso a la carpeta del proyecto (o solo a lo que deba actualizarse).

2. En GitHub Secrets guarda `FTP_SERVER`, `FTP_USERNAME`, `FTP_PASSWORD` (y puerto si aplica).

3. Usa una acción como [SamKirkland/FTP-Deploy-Action](https://github.com/SamKirkland/FTP-Deploy-Action) o similar para subir el contenido del repo **excluyendo** `.git`, `node_modules`, `.env`, etc.

4. Limitación: en el servidor **no** ejecutas `composer` ni `artisan` automáticamente salvo que:
   - tengas otro job que use SSH solo para eso, o  
   - ejecutes migraciones/artisan **a mano** tras cada despliegue, o  
   - uses un script PHP expuesto con token (menos recomendable por seguridad).

---

## Opción C — Solo “aviso” al servidor (webhook + script)

Algunos montan un script PHP muy acotado en el servidor que, con un **token secreto** en la URL, ejecuta `git pull` vía `exec` (si el hosting lo permite). GitHub envía un **webhook** al hacer push. Es frágil en seguridad y depende de que el hosting permita `exec` y git; no es lo primero que recomendaría en Stellar.

---

## Resumen práctico

| Situación | Qué hacer |
|-----------|-----------|
| Tienes **SSH** | Workflow con `git pull` + `composer` + `artisan`; assets compilados en el Action o en el repo (commit de `public` compilado — debatible) o build en CI y subida de `public/build` o equivalente. |
| **No** tienes SSH | FTP-Deploy desde Actions; `composer`/`artisan` manual o SSH puntual. |
| **Base de datos** | No cambia: sigue siendo la misma MySQL en cPanel; solo actualizas código. |

---

## Seguridad

- Nunca pongas contraseñas en el YAML del workflow; usa **Secrets**.
- La clave SSH de despliegue debe ser **solo para deploy**, no tu clave personal.
- `.env` **no** debe estar en Git; en el servidor se mantiene a mano.

Si más adelante quieres un **ejemplo concreto** de `deploy.yml` para tu caso (solo SSH o solo FTP), indica si tu Stellar tiene **SSH activo** o no.

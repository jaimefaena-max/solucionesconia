#!/usr/bin/env bash
# ==============================================================================
# deploy.sh — Despliegue de solucionesconia.cl en un VPS (Ubuntu/Debian)
#
# Uso (como root o con sudo, desde la raíz del repositorio clonado):
#   sudo bash deploy.sh
#
# El script es idempotente: puedes ejecutarlo las veces que quieras.
# ==============================================================================
# -E: el trap ERR de la sección 4 (rollback del vhost) se hereda en funciones y
# subshells; sin él, un fallo dentro de una función abortaría SIN restaurar.
set -Eeuo pipefail

# ------------------------------------------------------------------------------
# Variables — ajusta el correo antes de ejecutar si es necesario
# ------------------------------------------------------------------------------
DOMAIN="solucionesconia.cl"
WWW_DOMAIN="www.solucionesconia.cl"
WEB_ROOT="/var/www/${DOMAIN}"
NGINX_SITE="/etc/nginx/sites-available/${DOMAIN}"
CERTBOT_EMAIL="jaime.faena@gmail.com"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Desplegando ${DOMAIN} desde ${REPO_DIR}"

# ------------------------------------------------------------------------------
# 1. Instalar Nginx y Certbot si no están
# ------------------------------------------------------------------------------
if ! command -v nginx >/dev/null 2>&1; then
  echo "==> Instalando Nginx..."
  apt-get update -y
  apt-get install -y nginx
else
  echo "==> Nginx ya está instalado."
fi

if ! command -v certbot >/dev/null 2>&1; then
  echo "==> Instalando Certbot..."
  apt-get install -y certbot python3-certbot-nginx
else
  echo "==> Certbot ya está instalado."
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "==> Instalando rsync..."
  apt-get install -y rsync
else
  echo "==> rsync ya está instalado."
fi

# ------------------------------------------------------------------------------
# 2. Compilar el CSS de Tailwind ANTES de copiar
# ------------------------------------------------------------------------------
# Desde la migración de Tailwind CDN a build local, index.html enlaza
# /dist/style.css. Ese fichero NO está en git (dist/ va en .gitignore), así que
# hay que generarlo aquí; sin este paso el sitio se serviría SIN estilos.
# `npm ci` (no `install`) respeta package-lock.json al pie de la letra → build
# reproducible. `set -euo pipefail` (cabecera) aborta el deploy si el build falla,
# antes de tocar el web root: nunca se publica un dist a medias.
echo "==> Compilando CSS (Tailwind build local)..."
if ! command -v npm >/dev/null 2>&1; then
  echo "ERROR: npm no está instalado en este host; no se puede compilar el CSS." >&2
  exit 1
fi
( cd "${REPO_DIR}" && npm ci && npm run build )
echo "==> CSS compilado en ${REPO_DIR}/dist/style.css"

# ------------------------------------------------------------------------------
# 2.1. Copiar el sitio al web root
# ------------------------------------------------------------------------------
echo "==> Copiando archivos a ${WEB_ROOT}..."
mkdir -p "${WEB_ROOT}"
rsync -av --delete \
  --exclude '.git' \
  --exclude '.claude' \
  --exclude '.gitignore' \
  --exclude '.gitattributes' \
  --exclude 'deploy.sh' \
  --exclude 'README.md' \
  --exclude '.env' \
  --exclude '.env.*' \
  --exclude 'node_modules' \
  --exclude 'package.json' \
  --exclude 'package-lock.json' \
  --exclude 'tailwind.config.js' \
  --exclude 'src/input.css' \
  "${REPO_DIR}/" "${WEB_ROOT}/"


# ------------------------------------------------------------------------------
# 2.1. Cargar variables de entorno sensibles y proteger las credenciales
# ------------------------------------------------------------------------------
# index.html usa el placeholder $VITE_LINKEDIN_PARTNER_ID. El valor REAL se
# inyecta en tiempo de despliegue desde ${REPO_DIR}/.env (archivo NO versionado:
# está en .gitignore y solo existe en el servidor). Así el código fuente queda
# libre de credenciales.
if [ -f "${REPO_DIR}/.env" ]; then
  echo "==> Cargando variables de entorno desde ${REPO_DIR}/.env..."
  set -a
  # shellcheck disable=SC1091
  source "${REPO_DIR}/.env"
  set +a
else
  echo "ERROR: no existe ${REPO_DIR}/.env; VITE_LINKEDIN_PARTNER_ID es obligatorio." >&2
  echo "       Crea el .env en el servidor con la variable definida y reintenta." >&2
  echo "       Se ABORTA el deploy (fail-fast): no se publica con la telemetría B2B inerte." >&2
  exit 1
fi

echo "==> Inyectando VITE_LINKEDIN_PARTNER_ID en index.html..."
sed -i "s/\$VITE_LINKEDIN_PARTNER_ID/${VITE_LINKEDIN_PARTNER_ID:?Error: VITE_LINKEDIN_PARTNER_ID no está definido; se aborta el deploy}/g" "${WEB_ROOT}/index.html"

# ------------------------------------------------------------------------------
# 3. Permisos correctos
# ------------------------------------------------------------------------------

echo "==> Ajustando permisos (root:root, solo lectura para Nginx)..."
chown -R root:root "${WEB_ROOT}"
find "${WEB_ROOT}" -type d -exec chmod 755 {} \;
find "${WEB_ROOT}" -type f -exec chmod 644 {} \;

# ------------------------------------------------------------------------------
# 4. Virtual Host de Nginx
# ------------------------------------------------------------------------------
# 🔴 INCIDENTE 2026-09-22 (solucionesconia.cl con 526 en Cloudflare). Este
# bloque REESCRIBE el vhost solo con el server de :80; el de :443 lo vuelve a
# instalar Certbot en la sección 5. Entre ambas, la 4b verificaba el portal con
# sondas HTTPS en loopback: sin bloque 443 propio, las sondas caían en el primer
# server 443 del host (admin., con Basic Auth) → 401, /api/admin proxied y CSP
# ajena → `--post` fallaba → `set -e` abortaba ANTES de Certbot → el dominio
# quedaba sin 443 (certificado ajeno para Cloudflare = 526) hasta intervención
# manual. Tres correcciones, todas aquí:
#   1. Backup del vhost ANTES de pisarlo (Protocolo Golden Standard) y trap ERR
#      que lo RESTAURA y recarga si cualquier paso posterior falla: un deploy
#      abortado ya no puede dejar el sitio peor que como lo encontró.
#   2. No se recarga nginx hasta que Certbot haya reinstalado el 443: el nginx
#      en ejecución sigue sirviendo la configuración anterior mientras tanto.
#   3. `--post` corre DESPUÉS de Certbot (sección 5b), cuando el 443 existe.
BACKUP_NGINX_DIR="/root/backups-nginx"
mkdir -p "${BACKUP_NGINX_DIR}"
VHOST_BACKUP=""
if [ -f "${NGINX_SITE}" ]; then
  VHOST_BACKUP="${BACKUP_NGINX_DIR}/${DOMAIN}.$(date +%Y%m%d-%H%M%S).pre-deploy"
  cp -a "${NGINX_SITE}" "${VHOST_BACKUP}"
  echo "==> Backup del vhost anterior en ${VHOST_BACKUP}"
fi
rollback_vhost() {
  local rc=$?
  trap - ERR
  echo "!! Deploy abortado (rc=${rc}) después de reescribir el vhost." >&2
  if [ -n "${VHOST_BACKUP}" ] && [ -f "${VHOST_BACKUP}" ]; then
    cp -a "${VHOST_BACKUP}" "${NGINX_SITE}"
    if nginx -t >/dev/null 2>&1; then
      systemctl reload nginx
      echo "!! Vhost anterior RESTAURADO desde ${VHOST_BACKUP} y nginx recargado: el sitio sigue como antes del deploy." >&2
    else
      echo "!! El vhost restaurado NO pasa nginx -t; nginx NO se ha recargado. Revisar a mano: ${NGINX_SITE}" >&2
    fi
  else
    echo "!! No había vhost previo que restaurar (primer despliegue)." >&2
  fi
  exit "${rc}"
}
trap rollback_vhost ERR

echo "==> Configurando virtual host de Nginx..."
cat > "${NGINX_SITE}" <<NGINXCONF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} ${WWW_DOMAIN};

    root ${WEB_ROOT};
    index index.html;
    server_tokens off;

    # Dotfiles: .env, .git, .htpasswd, .DS_Store, etc. El lookahead exceptua
    # /.well-known/ — certbot la necesita para el reto HTTP-01 de renovacion.
    # Va ARRIBA a proposito: nginx evalua los location regex en orden de fichero
    # y este debe ganarle al de estaticos (un /.oculto.css caeria ahi si no).
    location ~ /\.(?!well-known).* {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Compresión
    gzip on;
    gzip_types text/plain text/css application/javascript image/svg+xml application/json;
    gzip_min_length 256;

    # Seguridad (heredados por locations sin add_header propio)
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
    # CSP (Fase 4 · I8): fija los orígenes que la landing realmente usa —
    # el widget Vendedor IA (admin.solucionesconia.cl), lucide (unpkg), Google
    # Fonts y el Insight Tag de LinkedIn. Bloquea cualquier otro script/conexión
    # y el framing de terceros.
    # ENDURECIDO al migrar Tailwind a build local: se retiran de script-src el
    # origen https://cdn.tailwindcss.com Y 'unsafe-eval' (que solo hacía falta
    # para el JIT del CDN de Tailwind). Pendiente aún: sustituir 'unsafe-inline'
    # por nonces en los scripts inline (LinkedIn Insight Tag).
    # Cloudflare Web Analytics: el beacon se sirve desde static.cloudflareinsights.com
    # (script-src) y reporta RUM a cloudflareinsights.com (connect-src). Ambos
    # hosts se listan para que la CSP no bloquee ni la carga ni el envío.
    # Cal.com (agendamiento B2B): app.cal.com sirve el iframe del calendario
    # (frame-src), su script de embed (script-src) y su API (connect-src).
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://unpkg.com https://snap.licdn.com https://admin.solucionesconia.cl https://static.cloudflareinsights.com https://cal.com https://app.cal.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https://admin.solucionesconia.cl https://px.ads.linkedin.com https://static.cloudflareinsights.com https://cloudflareinsights.com https://cal.com https://app.cal.com; frame-src https://admin.solucionesconia.cl https://cal.com https://app.cal.com; frame-ancestors 'self'; base-uri 'self'; object-src 'none'" always;

    # Cache agresivo para estáticos. Los headers de seguridad se repiten
    # a propósito: un location con add_header propio NO hereda los del server.
    location ~* \.(css|js|png|jpg|jpeg|webp|svg|ico|woff2?)\$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
        add_header X-Content-Type-Options "nosniff" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        try_files \$uri =404;
    }

    # ── HTML: SIEMPRE revalidar contra el servidor ─────────────────────────
    # 🔴 EL BUG QUE ESTO ARREGLA. index.html se servía SIN cabecera
    # Cache-Control. Sin ella —y sin Expires— el navegador aplica CACHÉ
    # HEURÍSTICA: guarda el documento en torno al 10 % del tiempo transcurrido
    # desde su Last-Modified. Resultado: clientes viendo durante horas una
    # landing anterior, con el header viejo (CTA + avatar del Vendedor IA) que
    # se purgó el 2026-08-17, y el launcher de Sofía anclado al <header> en vez
    # de flotando abajo a la derecha.
    #
    # ⚠️ LAS META http-equiv DEL HTML NO SIRVEN PARA ESTO. index.html declara
    # <meta http-equiv="Cache-Control" content="no-cache, no-store, ...">, pero
    # los navegadores IGNORAN esa meta al decidir la caché HTTP: solo honran
    # unas pocas pragma (Content-Type, Refresh, CSP...). La landing "creía" ser
    # no-cacheable y en realidad sí lo era. La única vía es esta cabecera.
    #
    # \`no-cache\` (no \`no-store\`) es deliberado: permite conservar la copia y
    # (acentos graves ESCAPADOS: este heredoc no va entre comillas y bash
    # ejecutaba \`no-cache\` como comando — "no-cache: command not found").
    # revalidarla con If-None-Match/If-Modified-Since, así que lo normal es un
    # 304 barato en lugar de reenviar el documento entero. Los estáticos con
    # hash siguen con su caché agresiva de 30 días (location de arriba).
    # ⚠️ Los SEIS headers de seguridad se repiten AQUÍ obligatoriamente: al
    # declarar un add_header propio, este location DEJA DE HEREDAR los del
    # server (nginx reemplaza, no fusiona). Omitir uno solo —en particular la
    # CSP— convertiría este arreglo de caché en una regresión de seguridad
    # sobre el documento HTML, que es justo donde más importa. Cualquier cambio
    # en el bloque del server debe replicarse aquí.
    # ── Portal VIP de clientes (Fase 5 · 2026-08-25) ─────────────────────────
    # 🔴 ESTA LÍNEA ARREGLA UNA VULNERABILIDAD REAL DE ESTE SCRIPT.
    #
    # La sección 4 hace \`cat > \${NGINX_SITE}\`: REESCRIBE el server block entero.
    # Entre el 25-ago y este cambio, el portal del cliente se activaba con un
    # \`include\` añadido A MANO al fichero, así que CUALQUIER ejecución de este
    # script lo borraba y dejaba el portal sin servir — sin aviso, y sin que el
    # despliegue fallara. Una publicación rutinaria de la landing tumbaba el
    # acceso de un cliente que paga.
    #
    # Al vivir el include DENTRO de la plantilla, el vhost regenerado ya lo trae
    # y el despliegue vuelve a ser idempotente.
    #
    # Si el snippet no existe, nginx aborta con "open() failed". Se usa la forma
    # tolerante con comodín: un directorio vacío no rompe el arranque, que es lo
    # que permite desplegar la landing en un servidor donde el portal aún no se
    # ha aprovisionado.
    include /etc/nginx/snippets/vip-portal*.conf;

    location / {
        add_header Cache-Control "no-cache, must-revalidate" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://unpkg.com https://snap.licdn.com https://admin.solucionesconia.cl https://static.cloudflareinsights.com https://cal.com https://app.cal.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https://admin.solucionesconia.cl https://px.ads.linkedin.com https://static.cloudflareinsights.com https://cloudflareinsights.com https://cal.com https://app.cal.com; frame-src https://admin.solucionesconia.cl https://cal.com https://app.cal.com; frame-ancestors 'self'; base-uri 'self'; object-src 'none'" always;
        try_files \$uri \$uri/ =404;
    }
}
NGINXCONF

ln -sf "${NGINX_SITE}" "/etc/nginx/sites-enabled/${DOMAIN}"

# Desactivar el sitio default si sigue activo
if [ -e /etc/nginx/sites-enabled/default ]; then
  rm -f /etc/nginx/sites-enabled/default
fi

# ------------------------------------------------------------------------------
# 4b. Snippet del Portal VIP (2026-09-13): versionado, renderizado y VERIFICADO
# ------------------------------------------------------------------------------
# Hasta hoy /etc/nginx/snippets/vip-portal.conf vivía solo en el VPS, editado a
# mano. El 13-sep faltaba `location ^~ /api/vip/` y el portal del cliente
# mostraba «No pudimos cargar tu estado de cuenta» (404 de nginx). Ahora la
# fuente de verdad es nginx/vip-portal.conf.plantilla en este repo: se renderiza
# sustituyendo los dos secretos de borde desde el .env del orquestador (nunca
# se versionan) y se instala con 640 root:root. Las reglas son de PREFIJO
# (/vip/, /api/vip/): cubren cualquier inquilino, presente o futuro, sin tocar
# nginx por cliente.
#
# Y antes de recargar, verificar-portal.sh --pre comprueba que el snippet
# expone lo que el portal necesita; si no, se ABORTA sin recargar y nginx sigue
# con la versión anterior. Las sondas --post van en la sección 5b, DESPUÉS de
# que Certbot reinstale el bloque 443 (ver el incidente descrito en la 4).
SNIPPET_DEST="/etc/nginx/snippets/vip-portal.conf"
ORQ_ENV="/opt/zasa-orchestrator/.env"
if [ -f "${REPO_DIR}/nginx/vip-portal.conf.plantilla" ]; then
  if [ ! -f "${ORQ_ENV}" ]; then
    echo "!! ${ORQ_ENV} no existe: no se puede renderizar el snippet del portal (se conserva el actual)" >&2
  else
    leer_env() { grep -E "^$1=" "${ORQ_ENV}" | head -1 | cut -d= -f2- | tr -d '"' | tr -d '\r\n'; }
    TOK="$(leer_env API_SECRET_TOKEN)"; EDGE="$(leer_env EDGE_SECRET)"
    if [ -z "${TOK}" ] || [ -z "${EDGE}" ]; then
      echo "!! API_SECRET_TOKEN o EDGE_SECRET vacíos en ${ORQ_ENV}: no se renderiza el snippet (se conserva el actual)" >&2
    else
      mkdir -p /etc/nginx/snippets /root/backups-nginx
      [ -f "${SNIPPET_DEST}" ] && cp -a "${SNIPPET_DEST}" "/root/backups-nginx/vip-portal.conf.$(date +%Y%m%d-%H%M%S)"
      TMP_SNIP="$(mktemp /etc/nginx/snippets/.vip-portal.XXXXXX)"
      # Sustitución literal (no regex) con awk: los secretos pueden llevar cualquier carácter.
      awk -v tok="${TOK}" -v edge="${EDGE}" '{ gsub(/__API_SECRET_TOKEN__/, tok); gsub(/__EDGE_SECRET__/, edge); print }' \
        "${REPO_DIR}/nginx/vip-portal.conf.plantilla" > "${TMP_SNIP}"
      chown root:root "${TMP_SNIP}"; chmod 640 "${TMP_SNIP}"
      mv -f "${TMP_SNIP}" "${SNIPPET_DEST}"
      unset TOK EDGE
      echo "==> Snippet del portal renderizado en ${SNIPPET_DEST} (640 root:root)"
    fi
  fi
fi

echo "==> Verificando el portal ANTES de recargar (linter de infraestructura)..."
bash "${REPO_DIR}/nginx/verificar-portal.sh" --pre

# Solo validación: la recarga la hace Certbot (sección 5) con el 443 ya
# reinstalado, y la sección 5b la repite de forma idempotente. Recargar aquí
# publicaría un vhost sin 443 (es lo que dejó el sitio en 526 el 2026-09-22).
echo "==> Validando la configuración de Nginx (sin recargar todavía)..."
nginx -t
systemctl enable nginx

# ------------------------------------------------------------------------------
# 5. SSL con Certbot (Let's Encrypt)
# ------------------------------------------------------------------------------
# --keep-until-expiring hace la operación idempotente: si el certificado ya
# existe y es válido lo reutiliza, y re-instala el bloque SSL en el vhost
# (necesario porque la sección 4 reescribe el archivo y borra el bloque 443).
# Si Certbot falla, el trap ERR de la sección 4 restaura el vhost anterior.
echo "==> Configurando SSL con Certbot..."
issue_cert() {
  certbot --nginx "$@" \
    --email "${CERTBOT_EMAIL}" \
    --agree-tos --no-eff-email \
    --redirect --non-interactive \
    --keep-until-expiring --expand
}

if ! issue_cert -d "${DOMAIN}" -d "${WWW_DOMAIN}"; then
  echo "==> AVISO: validación con ${WWW_DOMAIN} falló (¿falta su registro DNS?)."
  echo "==> Reintentando solo con ${DOMAIN} para no dejar el sitio sin HTTPS..."
  issue_cert -d "${DOMAIN}"
fi

# ------------------------------------------------------------------------------
# 5b. Recarga definitiva y sondas del portal (con el 443 ya instalado)
# ------------------------------------------------------------------------------
# Certbot ya recargó nginx al instalar el bloque SSL; esta recarga es
# idempotente y deja constancia explícita. Las sondas --post exigen que exista
# un server 443 para el dominio (si no, fallan nombrando la causa en vez de
# caer en el server por defecto), y cualquier fallo aquí dispara el rollback
# al vhost anterior: el sitio nunca se queda a medias.
echo "==> Validando y recargando Nginx (vhost completo: 80 + 443)..."
nginx -t
systemctl reload nginx
sleep 2
echo "==> Verificando el portal DESPUÉS de recargar (sondas en loopback)..."
bash "${REPO_DIR}/nginx/verificar-portal.sh" --post

# A partir de aquí ya no se toca nginx: un fallo en el firewall o en la purga
# de Cloudflare no debe revertir un vhost que acaba de verificarse en verde.
trap - ERR
echo "==> Vhost verificado; backup previo conservado en ${VHOST_BACKUP:-<ninguno>}"

# ------------------------------------------------------------------------------
# 6. Firewall (UFW): permitir SSH y Nginx, denegar el resto
# ------------------------------------------------------------------------------
if command -v ufw >/dev/null 2>&1; then
  echo "==> Configurando firewall (UFW)..."
  ufw allow OpenSSH >/dev/null
  ufw allow 'Nginx Full' >/dev/null
  ufw --force enable
  ufw status verbose
else
  echo "==> UFW no está disponible; omitiendo configuración de firewall."
fi

# ------------------------------------------------------------------------------
# 7. Purga de caché de Cloudflare (Edge)
# ------------------------------------------------------------------------------
# El Edge cachea los estáticos (main.js, style.css) con TTL de 30 días; sin purga,
# los visitantes ven assets viejos tras cada deploy. Aquí se purga TODO el zone.
#
# ZERO TRUST: el Zone ID y el Token NUNCA se hardcodean — se leen del entorno
# (${REPO_DIR}/.env, cargado arriba). Guardas ${VAR:-} porque `set -u` abortaría
# ante una variable no definida. Si faltan, se omite la purga con aviso: no se
# aborta un despliegue que ya fue exitoso (nginx recargado).
if [ -n "${CLOUDFLARE_ZONE_ID:-}" ] && [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
  echo "==> Purgando caché de Cloudflare..."
  cf_http=$(curl -s -o /tmp/cf_purge.json -w '%{http_code}' -X POST \
    "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/purge_cache" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{"purge_everything":true}') || cf_http="000"

  if [ "${cf_http}" = "200" ]; then
    echo "==> ✅ Caché de Cloudflare purgada correctamente (HTTP 200)."
  else
    echo "==> ⚠️  Purga de Cloudflare FALLÓ (HTTP ${cf_http}). Verifica CLOUDFLARE_ZONE_ID / CLOUDFLARE_API_TOKEN." >&2
    cat /tmp/cf_purge.json 2>/dev/null >&2 || true
  fi
else
  echo "==> Purga de Cloudflare omitida: CLOUDFLARE_ZONE_ID / CLOUDFLARE_API_TOKEN no definidos en .env."
fi

echo ""
echo "=============================================================="
echo "  ✅ Despliegue completo: https://${DOMAIN}"
echo "=============================================================="

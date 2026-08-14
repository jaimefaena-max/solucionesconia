#!/usr/bin/env bash
# ==============================================================================
# deploy.sh — Despliegue de solucionesconia.cl en un VPS (Ubuntu/Debian)
#
# Uso (como root o con sudo, desde la raíz del repositorio clonado):
#   sudo bash deploy.sh
#
# El script es idempotente: puedes ejecutarlo las veces que quieras.
# ==============================================================================
set -euo pipefail

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
  echo "==> ADVERTENCIA: no existe ${REPO_DIR}/.env."
  echo "==> La telemetría B2B (LinkedIn) quedará desactivada (placeholder vacío)."
fi

echo "==> Inyectando VITE_LINKEDIN_PARTNER_ID en index.html..."
sed -i "s/\$VITE_LINKEDIN_PARTNER_ID/${VITE_LINKEDIN_PARTNER_ID:-}/g" "${WEB_ROOT}/index.html"

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
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://unpkg.com https://snap.licdn.com https://admin.solucionesconia.cl; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https://admin.solucionesconia.cl https://px.ads.linkedin.com; frame-src https://admin.solucionesconia.cl; frame-ancestors 'self'; base-uri 'self'; object-src 'none'" always;

    # Cache agresivo para estáticos. Los headers de seguridad se repiten
    # a propósito: un location con add_header propio NO hereda los del server.
    location ~* \.(css|js|png|jpg|jpeg|webp|svg|ico|woff2?)\$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
        add_header X-Content-Type-Options "nosniff" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        try_files \$uri =404;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINXCONF

ln -sf "${NGINX_SITE}" "/etc/nginx/sites-enabled/${DOMAIN}"

# Desactivar el sitio default si sigue activo
if [ -e /etc/nginx/sites-enabled/default ]; then
  rm -f /etc/nginx/sites-enabled/default
fi

echo "==> Validando y recargando Nginx..."
nginx -t
systemctl enable nginx
systemctl reload nginx

# ------------------------------------------------------------------------------
# 5. SSL con Certbot (Let's Encrypt)
# ------------------------------------------------------------------------------
# --keep-until-expiring hace la operación idempotente: si el certificado ya
# existe y es válido lo reutiliza, y re-instala el bloque SSL en el vhost
# (necesario porque la sección 4 reescribe el archivo y borra el bloque 443).
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

echo ""
echo "=============================================================="
echo "  ✅ Despliegue completo: https://${DOMAIN}"
echo "=============================================================="

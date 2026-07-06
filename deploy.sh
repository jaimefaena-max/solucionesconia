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
# 2. Copiar el sitio al web root
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
  "${REPO_DIR}/" "${WEB_ROOT}/"

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

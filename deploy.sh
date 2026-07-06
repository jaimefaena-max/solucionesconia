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
echo "==> Ajustando permisos..."
chown -R www-data:www-data "${WEB_ROOT}"
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

    # Compresión
    gzip on;
    gzip_types text/plain text/css application/javascript image/svg+xml;
    gzip_min_length 256;

    # Cache agresivo para estáticos (CSS/JS/imágenes)
    location ~* \.(css|js|png|jpg|jpeg|webp|svg|ico|woff2?)\$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
        try_files \$uri =404;
    }

    # Seguridad básica
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

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
if [ -d "/etc/letsencrypt/live/${DOMAIN}" ]; then
  echo "==> Certificado SSL ya existe. Verificando renovación..."
  certbot renew --dry-run || true
else
  echo "==> Emitiendo certificado SSL..."
  certbot --nginx \
    -d "${DOMAIN}" -d "${WWW_DOMAIN}" \
    --email "${CERTBOT_EMAIL}" \
    --agree-tos --no-eff-email \
    --redirect --non-interactive
fi

echo ""
echo "=============================================================="
echo "  ✅ Despliegue completo: https://${DOMAIN}"
echo "=============================================================="

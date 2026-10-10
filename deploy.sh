#!/usr/bin/env bash
# ==============================================================================
# deploy.sh — Publica los ficheros de solucionesconia.cl en el web root del VPS
#
# Uso (como root, desde el clon /opt/solucionesconia):
#   sudo bash deploy.sh                      # publica
#   sudo bash deploy.sh --simular            # enseña qué cambiaría y no toca nada
#   sudo bash deploy.sh --permitir-borrado   # publica aunque haya que borrar
#                                            # ficheros del web root
#
# ALCANCE (refactor 2026-10-10): este script SOLO publica ficheros. No instala
# paquetes, no toca ufw, no reescribe el vhost, no renderiza el snippet del
# Portal VIP, no lanza Certbot ni recarga nginx. Antes hacía todo eso y era
# destructivo:
#   · `ufw allow 'Nginx Full'` reabría 80/443 a todo internet, saltándose el
#     cierre solo-Cloudflare (la desviación del 22-sep; recerrado el 09-oct).
#   · No hacía `git pull`: con el clon atrasado, su `rsync --delete` borraba del
#     web root lo que faltara en el clon (el 09-oct se habría llevado /acceso).
#   · Regeneraba /etc/nginx/snippets/vip-portal.conf desde la plantilla de este
#     repo (13 location, 640) y pisaba el snippet vivo que instala
#     `instalar-plantillas.sh` de zasa-orchestrator (16 location, AUTHZ_VIP, 600).
# El vhost de solucionesconia.cl ya no lo gestiona ningún script: un cambio en
# él (CSP, cabeceras) va a mano con respaldo previo + `nginx -t` (Protocolo
# Golden Standard). La plantilla anterior sigue en git: `git show 0827a4c:deploy.sh`.
# ==============================================================================
set -Eeuo pipefail

DOMAIN="solucionesconia.cl"
WWW_DOMAIN="www.solucionesconia.cl"
WEB_ROOT="/var/www/${DOMAIN}"
RAMA="main"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="/root/backups-solucionesconia/$(date +%Y%m%d-%H%M%S)"

# Lista BLANCA de lo que se publica (antes era lista negra, y acababan en el web
# root docs/, nginx/ y diseño_premium.md, servidos con 200). Si index.html
# empieza a enlazar otra carpeta, añadirla aquí.
PUBLICAR=(index.html acceso assets dist src)
NO_PUBLICAR=(src/input.css .gitkeep)

SIMULAR=0
PERMITIR_BORRADO=0

# Todo el cuerpo va dentro de main(): bash lee un script por trozos mientras lo
# ejecuta, y el `git pull` de abajo puede reescribir este mismo fichero. Una
# función se parsea entera antes de correr, así que el pull no la corrompe.
main() {
  for arg in "$@"; do
    case "${arg}" in
      --simular) SIMULAR=1 ;;
      --permitir-borrado) PERMITIR_BORRADO=1 ;;
      *) echo "uso: $0 [--simular] [--permitir-borrado]" >&2; exit 2 ;;
    esac
  done

  [ "$(id -u)" -eq 0 ] || { echo "ERROR: ejecutar como root." >&2; exit 1; }
  for cmd in git rsync npm curl sha256sum; do
    command -v "${cmd}" >/dev/null 2>&1 || { echo "ERROR: falta ${cmd}; este script no instala paquetes." >&2; exit 1; }
  done

  echo "==> Publicando ${DOMAIN} desde ${REPO_DIR}"

  # ----------------------------------------------------------------------------
  # 1. Traer el código: el clon tiene que estar EXACTAMENTE en origin/main
  # ----------------------------------------------------------------------------
  git -C "${REPO_DIR}" fetch --quiet origin "${RAMA}"
  if ! git -C "${REPO_DIR}" diff --quiet || ! git -C "${REPO_DIR}" diff --cached --quiet; then
    echo "ERROR: el clon tiene cambios rastreados sin commitear; en el VPS no se edita código." >&2
    git -C "${REPO_DIR}" status --short --untracked-files=no >&2
    exit 1
  fi
  if [ "${SIMULAR}" -eq 0 ]; then
    git -C "${REPO_DIR}" merge --ff-only --quiet "origin/${RAMA}" \
      || { echo "ERROR: el clon divergió de origin/${RAMA}; no se publica." >&2; exit 1; }
  fi
  local head origen
  head="$(git -C "${REPO_DIR}" rev-parse HEAD)"
  origen="$(git -C "${REPO_DIR}" rev-parse "origin/${RAMA}")"
  if [ "${head}" != "${origen}" ]; then
    if [ "${SIMULAR}" -eq 1 ]; then
      echo "!! Simulación sobre ${head:0:7}, pero origin/${RAMA} va en ${origen:0:7}: la publicación real traería ese commit." >&2
    else
      echo "ERROR: HEAD ${head:0:7} != origin/${RAMA} ${origen:0:7}." >&2; exit 1
    fi
  fi
  echo "==> Código en ${head:0:7}"

  # ----------------------------------------------------------------------------
  # 2. Compilar el CSS de Tailwind (dist/ no está en git)
  # ----------------------------------------------------------------------------
  # `npm ci` respeta package-lock.json → build reproducible. Si falla, set -e
  # aborta antes de tocar el web root.
  echo "==> Compilando CSS (Tailwind)..."
  ( cd "${REPO_DIR}" && npm ci --no-audit --no-fund && npm run build )

  # ----------------------------------------------------------------------------
  # 3. Montar la versión publicable en un directorio de staging
  # ----------------------------------------------------------------------------
  # Se inyecta el ID de LinkedIn y se fijan permisos AQUÍ, no en el web root:
  # así nginx nunca sirve un index.html con el placeholder sin sustituir.
  local stage
  stage="$(mktemp -d /tmp/solucionesconia-stage.XXXXXX)"
  trap 'rm -rf "${stage}"' EXIT

  local excluir=()
  for x in "${NO_PUBLICAR[@]}"; do excluir+=(--exclude "${x}"); done
  for p in "${PUBLICAR[@]}"; do
    [ -e "${REPO_DIR}/${p}" ] || { echo "ERROR: falta ${p} en el clon." >&2; exit 1; }
  done
  ( cd "${REPO_DIR}" && rsync -a --relative "${excluir[@]}" "${PUBLICAR[@]}" "${stage}/" )

  # index.html lleva el placeholder $VITE_LINKEDIN_PARTNER_ID; el valor real
  # vive solo en ${REPO_DIR}/.env (no versionado). Sin él se aborta.
  [ -f "${REPO_DIR}/.env" ] || { echo "ERROR: falta ${REPO_DIR}/.env (VITE_LINKEDIN_PARTNER_ID)." >&2; exit 1; }
  set -a
  # shellcheck disable=SC1091
  source "${REPO_DIR}/.env"
  set +a
  sed -i "s/\$VITE_LINKEDIN_PARTNER_ID/${VITE_LINKEDIN_PARTNER_ID:?VITE_LINKEDIN_PARTNER_ID no definido}/g" "${stage}/index.html"

  chown -R root:root "${stage}"
  find "${stage}" -type d -exec chmod 755 {} +
  find "${stage}" -type f -exec chmod 644 {} +

  # ----------------------------------------------------------------------------
  # 4. Qué cambia: guarda contra borrados
  # ----------------------------------------------------------------------------
  local plan borrados
  plan="$(rsync -aicn --delete "${stage}/" "${WEB_ROOT}/")"
  borrados="$(printf '%s\n' "${plan}" | grep '^\*deleting' || true)"
  echo "==> Cambios previstos en ${WEB_ROOT}:"
  printf '%s\n' "${plan}" | grep -E '^(<f|\*deleting|cd)' || echo "    (ninguno)"

  if [ "${SIMULAR}" -eq 1 ]; then
    echo "==> Simulación: no se ha tocado nada."; return 0
  fi
  if [ -n "${borrados}" ] && [ "${PERMITIR_BORRADO}" -eq 0 ]; then
    echo "ERROR: la publicación BORRARÍA ficheros del web root (lista arriba)." >&2
    echo "       Si es lo esperado, repetir con --permitir-borrado." >&2
    exit 3
  fi

  # ----------------------------------------------------------------------------
  # 5. Respaldo del web root y publicación
  # ----------------------------------------------------------------------------
  mkdir -p "${BACKUP_DIR}"; chmod 700 "${BACKUP_DIR}"
  tar -C "$(dirname "${WEB_ROOT}")" -czf "${BACKUP_DIR}/webroot.tgz" "$(basename "${WEB_ROOT}")"
  echo "==> Respaldo del web root en ${BACKUP_DIR}/webroot.tgz"

  # --delay-updates deja cada fichero nuevo en un temporal y los coloca todos
  # al final: la ventana con versiones mezcladas es mínima.
  local cambios
  cambios="$(rsync -aic --delete --delay-updates "${stage}/" "${WEB_ROOT}/")"

  # ----------------------------------------------------------------------------
  # 6. Verificación en loopback (el origen solo acepta tráfico de Cloudflare)
  # ----------------------------------------------------------------------------
  local esperado servido ruta codigo
  esperado="$(sha256sum < "${stage}/index.html" | cut -c1-64)"
  servido="$(curl -sk -H "Host: ${DOMAIN}" https://127.0.0.1/ | sha256sum | cut -c1-64)"
  if [ "${esperado}" != "${servido}" ]; then
    echo "ERROR: nginx no sirve el index.html recién publicado." >&2
    echo "       Rollback: rm -rf ${WEB_ROOT} && tar -C $(dirname "${WEB_ROOT}") -xzf ${BACKUP_DIR}/webroot.tgz" >&2
    exit 1
  fi
  for ruta in / /acceso/ /dist/style.css /src/main.js; do
    codigo="$(curl -sk -o /dev/null -w '%{http_code}' -H "Host: ${DOMAIN}" "https://127.0.0.1${ruta}")"
    [ "${codigo}" = "200" ] || { echo "ERROR: ${ruta} → ${codigo} en loopback. Rollback: ver arriba (${BACKUP_DIR})." >&2; exit 1; }
  done
  echo "==> Loopback OK: index.html servido = publicado; /, /acceso/, CSS y JS en 200"

  # ----------------------------------------------------------------------------
  # 7. Purga de Cloudflare SOLO de los ficheros cambiados
  # ----------------------------------------------------------------------------
  # Antes era `purge_everything`, que vacía la caché de toda la zona, incluidos
  # admin. y vip. Credenciales solo desde .env (nunca en código ni en argv).
  purgar_cloudflare "${cambios}"

  echo ""
  echo "=============================================================="
  echo "  ✅ Publicado ${head:0:7} en https://${DOMAIN}"
  echo "=============================================================="
}

purgar_cloudflare() {
  if [ -z "${CLOUDFLARE_ZONE_ID:-}" ] || [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
    echo "==> Purga omitida: CLOUDFLARE_ZONE_ID / CLOUDFLARE_API_TOKEN no definidos en .env."
    return 0
  fi
  local urls=() ruta host
  while IFS= read -r ruta; do
    [ -n "${ruta}" ] || continue
    if ! [[ "${ruta}" =~ ^[A-Za-z0-9._/-]+$ ]]; then
      echo "!! ${ruta}: nombre fuera de [A-Za-z0-9._/-], purgarlo a mano si estaba cacheado." >&2
      continue
    fi
    for host in "${DOMAIN}" "${WWW_DOMAIN}"; do
      urls+=("https://${host}/${ruta}")
      case "${ruta}" in
        index.html) urls+=("https://${host}/") ;;
        */index.html) urls+=("https://${host}/${ruta%index.html}") ;;
      esac
    done
  done < <(printf '%s\n' "$1" | sed -nE 's/^(<f[^ ]*|\*deleting) +//p' | grep -v '/$' || true)

  if [ "${#urls[@]}" -eq 0 ]; then
    echo "==> Purga omitida: ningún fichero cambió."; return 0
  fi
  # La API admite como mucho 30 URL por llamada.
  local i lote cuerpo http fallos=0
  for ((i = 0; i < ${#urls[@]}; i += 30)); do
    lote=("${urls[@]:i:30}")
    cuerpo="$(printf '"%s",' "${lote[@]}")"
    cuerpo="{\"files\":[${cuerpo%,}]}"
    http="$(curl -s -o /dev/null -w '%{http_code}' -X POST \
      "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/purge_cache" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H "Content-Type: application/json" \
      --data "${cuerpo}")" || http="000"
    [ "${http}" = "200" ] || fallos=$((fallos + 1))
  done
  if [ "${fallos}" -eq 0 ]; then
    echo "==> ✅ Cloudflare: purgadas ${#urls[@]} URL."
  else
    echo "==> ⚠️  Cloudflare: ${fallos} lote(s) de purga fallaron; el sitio ya está publicado, purgar a mano." >&2
  fi
}

main "$@"
exit

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
# WEB_ROOT y BACKUP_DIR admiten sobreescritura por entorno solo para poder
# probar revertir() contra directorios temporales; en el VPS no se definen.
WEB_ROOT="${WEB_ROOT:-/var/www/${DOMAIN}}"
RAMA="main"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_FILE="${LOCK_FILE:-/var/lock/solucionesconia-deploy.lock}"
BACKUP_DIR="${BACKUP_DIR:-/root/backups-solucionesconia/$(date +%Y%m%d-%H%M%S)}"

# Lista BLANCA de lo que se publica (antes era lista negra, y acababan en el web
# root docs/, nginx/ y diseño_premium.md, servidos con 200). Si index.html
# empieza a enlazar otra carpeta, añadirla aquí.
PUBLICAR=(index.html acceso assets dist src)
NO_PUBLICAR=(src/input.css .gitkeep)

SIMULAR=0
PERMITIR_BORRADO=0
STAGE=""
# 1 mientras el web root está a medio publicar (desde el respaldo hasta que la
# verificación en loopback pasa): solo en esa ventana un fallo dispara revertir().
EN_VENTANA=0

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
  for cmd in git rsync npm curl sha256sum flock; do
    command -v "${cmd}" >/dev/null 2>&1 || { echo "ERROR: falta ${cmd}; este script no instala paquetes." >&2; exit 1; }
  done

  # Un solo deploy a la vez (también la simulación: ambos corren `npm ci` y el
  # build en el mismo clon). El descriptor 9 queda abierto hasta que el proceso
  # termina, y con él el lock; no se libera a mano.
  exec 9>"${LOCK_FILE}"
  flock -n 9 || { echo "ERROR: ya hay otro deploy en curso (lock ${LOCK_FILE})." >&2; exit 1; }

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
  # Global, no local: el trap EXIT se ejecuta cuando main() ya ha terminado.
  STAGE="$(mktemp -d /tmp/solucionesconia-stage.XXXXXX)"
  trap 'rm -rf "${STAGE:-}"' EXIT

  local excluir=()
  for x in "${NO_PUBLICAR[@]}"; do excluir+=(--exclude "${x}"); done
  for p in "${PUBLICAR[@]}"; do
    [ -e "${REPO_DIR}/${p}" ] || { echo "ERROR: falta ${p} en el clon." >&2; exit 1; }
  done
  ( cd "${REPO_DIR}" && rsync -a --relative "${excluir[@]}" "${PUBLICAR[@]}" "${STAGE}/" )

  # index.html lleva el placeholder $VITE_LINKEDIN_PARTNER_ID; el valor real
  # vive solo en ${REPO_DIR}/.env (no versionado). Sin él se aborta.
  [ -f "${REPO_DIR}/.env" ] || { echo "ERROR: falta ${REPO_DIR}/.env (VITE_LINKEDIN_PARTNER_ID)." >&2; exit 1; }
  # El .env NO se hace `source`: este script corre como root y un .env con
  # `$(…)` o backticks se ejecutaría con sus privilegios. Se leen solo las tres
  # claves esperadas, como texto, y se validan por formato antes de usarlas.
  VITE_LINKEDIN_PARTNER_ID="$(leer_env VITE_LINKEDIN_PARTNER_ID)"
  CLOUDFLARE_ZONE_ID="$(leer_env CLOUDFLARE_ZONE_ID)"
  CLOUDFLARE_API_TOKEN="$(leer_env CLOUDFLARE_API_TOKEN)"
  [[ "${VITE_LINKEDIN_PARTNER_ID}" =~ ^[0-9]+$ ]]     || { echo "ERROR: VITE_LINKEDIN_PARTNER_ID ausente o no numérico en ${REPO_DIR}/.env." >&2; exit 1; }
  [[ -z "${CLOUDFLARE_ZONE_ID}" || "${CLOUDFLARE_ZONE_ID}" =~ ^[0-9A-Fa-f]+$ ]]     || { echo "ERROR: CLOUDFLARE_ZONE_ID con formato inválido (se espera hexadecimal)." >&2; exit 1; }
  [[ -z "${CLOUDFLARE_API_TOKEN}" || "${CLOUDFLARE_API_TOKEN}" =~ ^[A-Za-z0-9_-]+$ ]]     || { echo "ERROR: CLOUDFLARE_API_TOKEN con formato inválido (se espera [A-Za-z0-9_-])." >&2; exit 1; }
  sed -i "s/\$VITE_LINKEDIN_PARTNER_ID/${VITE_LINKEDIN_PARTNER_ID}/g" "${STAGE}/index.html"

  # Cache busting: nginx sirve CSS y JS con max-age=2592000 (30 días) y la
  # purga de Cloudflare no alcanza la caché del navegador. La versión es el
  # hash del contenido, no el commit: solo cambia cuando cambia el fichero.
  local v_css v_js
  v_css="$(sha256sum < "${STAGE}/dist/style.css" | cut -c1-10)"
  v_js="$(sha256sum < "${STAGE}/src/main.js" | cut -c1-10)"
  sed -i -e "s/\$CSS_VERSION/${v_css}/g" -e "s/\$JS_VERSION/${v_js}/g" "${STAGE}/index.html"
  if grep -qE '\$(CSS|JS)_VERSION' "${STAGE}/index.html"; then
    echo "ERROR: index.html conserva un placeholder de versión sin sustituir." >&2; exit 1
  fi
  echo "==> Versiones de assets: style.css?v=${v_css} · main.js?v=${v_js}"

  chown -R root:root "${STAGE}"
  find "${STAGE}" -type d -exec chmod 755 {} +
  find "${STAGE}" -type f -exec chmod 644 {} +

  # ----------------------------------------------------------------------------
  # 4. Qué cambia: guarda contra borrados
  # ----------------------------------------------------------------------------
  local plan borrados
  plan="$(rsync -aicn --delete "${STAGE}/" "${WEB_ROOT}/")"
  borrados="$(printf '%s\n' "${plan}" | grep '^\*deleting' || true)"
  echo "==> Cambios previstos en ${WEB_ROOT}:"
  printf '%s\n' "${plan}" | grep -E '^([<>]f|\*deleting|cd)' || echo "    (ninguno)"

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

  # Desde aquí el web root puede quedar a medias: cualquier fallo (explícito o
  # por set -e, vía el trap ERR) lo devuelve al respaldo con revertir().
  EN_VENTANA=1
  trap 'al_fallar' ERR
  trap 'al_interrumpir' INT TERM

  # --delay-updates deja cada fichero nuevo en un temporal y los coloca todos
  # al final: la ventana con versiones mezcladas es mínima.
  local cambios
  cambios="$(rsync -aic --delete --delay-updates "${STAGE}/" "${WEB_ROOT}/")"

  # ----------------------------------------------------------------------------
  # 6. Verificación en loopback (el origen solo acepta tráfico de Cloudflare)
  # ----------------------------------------------------------------------------
  local esperado servido ruta codigo
  esperado="$(sha256sum < "${STAGE}/index.html" | cut -c1-64)"
  # --max-time: un nginx colgado no puede dejar el script esperando con el web
  # root recién publicado; un curl fallido cuenta como "no sirve lo publicado".
  servido="$(curl -sk --max-time 10 -H "Host: ${DOMAIN}" https://127.0.0.1/ | sha256sum | cut -c1-64)" || servido="curl-fallido"
  if [ "${esperado}" != "${servido}" ]; then
    echo "ERROR: nginx no sirve el index.html recién publicado." >&2
    revertir; exit 1
  fi
  for ruta in / /acceso/ /dist/style.css /src/main.js; do
    codigo="$(curl -sk --max-time 10 -o /dev/null -w '%{http_code}' -H "Host: ${DOMAIN}" "https://127.0.0.1${ruta}")" || codigo="000"
    [ "${codigo}" = "200" ] || { echo "ERROR: ${ruta} → ${codigo} en loopback." >&2; revertir; exit 1; }
  done
  # Publicación verificada: se cierra la ventana (la purga de Cloudflare ya no
  # debe revertir nada) y se desarman los traps.
  EN_VENTANA=0
  trap - ERR INT TERM
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

# Lee UNA clave de ${REPO_DIR}/.env como texto (última aparición, sin comillas
# envolventes ni CR). Nunca evalúa el fichero ni imprime nada por stderr.
leer_env() {
  local linea
  linea="$(grep -E "^[[:space:]]*(export[[:space:]]+)?$1=" "${REPO_DIR}/.env" | tail -n1)" || true
  linea="${linea#*=}"
  linea="${linea%$'\r'}"
  linea="${linea#\"}"; linea="${linea%\"}"
  linea="${linea#\'}"; linea="${linea%\'}"
  printf '%s' "${linea}"
}

# Devuelve el web root al estado del respaldo hecho justo antes de publicar.
# Antes el rollback era solo un texto impreso, y su receta (`rm -rf` + `tar`)
# dejaba el sitio VACÍO si el tar fallaba. Ahora el tar se extrae primero a un
# temporal y el web root solo se toca (rsync --delete) si el respaldo es legible
# y contiene el directorio esperado; el web root nunca se borra de entrada.
revertir() {
  # EN_VENTANA=0 neutraliza los traps (al_fallar/al_interrumpir ya no actúan);
  # no se hace `trap -` aquí porque revertir() también corre dentro de un trap.
  EN_VENTANA=0
  local nombre tmp rc=0
  nombre="$(basename "${WEB_ROOT}")"
  echo "!! REVIRTIENDO ${WEB_ROOT} desde ${BACKUP_DIR}/webroot.tgz" >&2
  if [ ! -s "${BACKUP_DIR}/webroot.tgz" ]; then
    echo "!! No hay respaldo legible en ${BACKUP_DIR}; el web root NO se ha tocado." >&2
    return 1
  fi
  tmp="$(mktemp -d /tmp/solucionesconia-revert.XXXXXX)" || return 1
  if tar -xzf "${BACKUP_DIR}/webroot.tgz" -C "${tmp}" && [ -d "${tmp}/${nombre}" ]; then
    rsync -a --delete "${tmp}/${nombre}/" "${WEB_ROOT}/" || rc=1
  else
    echo "!! El respaldo no se pudo extraer; el web root NO se ha tocado." >&2
    rc=1
  fi
  rm -rf "${tmp}"
  if [ "${rc}" -eq 0 ]; then
    echo "!! Web root restaurado desde el respaldo. Revisar qué falló antes de reintentar." >&2
  else
    echo "!! FALLÓ la reversión; restaurar a mano: ${BACKUP_DIR}/webroot.tgz" >&2
  fi
  return "${rc}"
}

# Trap ERR: solo actúa dentro de la ventana de publicación y solo en el shell
# principal. Con `set -E` las subshells de `$(…)` heredan el trap; sin la guarda
# de BASHPID, un fallo dentro de `$(rsync …)` revertiría dos veces (una en la
# subshell, cuyo cambio de EN_VENTANA se pierde, y otra en el padre).
al_fallar() {
  RC_FALLO=$?
  [ "${BASHPID}" = "$$" ] || return "${RC_FALLO}"
  if [ "${EN_VENTANA}" -eq 1 ]; then
    echo "ERROR: fallo durante la publicación (código ${RC_FALLO})." >&2
    revertir || true
  fi
  return "${RC_FALLO}"
}

al_interrumpir() {
  if [ "${BASHPID}" = "$$" ] && [ "${EN_VENTANA}" -eq 1 ]; then
    echo "ERROR: interrumpido durante la publicación." >&2
    revertir || true
  fi
  exit 130
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
  done < <(printf '%s\n' "$1" | sed -nE 's/^([<>]f[^ ]*|\*deleting) +//p' | grep -v '/$' || true)

  if [ "${#urls[@]}" -eq 0 ]; then
    echo "==> Purga omitida: ningún fichero cambió."; return 0
  fi
  # La API admite como mucho 30 URL por llamada.
  local i lote cuerpo http fallos=0
  for ((i = 0; i < ${#urls[@]}; i += 30)); do
    lote=("${urls[@]:i:30}")
    cuerpo="$(printf '"%s",' "${lote[@]}")"
    cuerpo="{\"files\":[${cuerpo%,}]}"
    # El token va por stdin (`-K -` lee la configuración de curl del here-string),
    # no en argv: un `-H "Authorization: Bearer …"` sería visible para cualquier
    # usuario en `ps` / /proc/<pid>/cmdline mientras dura la llamada.
    http="$(curl -s --max-time 20 -o /dev/null -w '%{http_code}' -X POST -K - \
      "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/purge_cache" \
      -H "Content-Type: application/json" \
      --data "${cuerpo}" \
      <<<"header = \"Authorization: Bearer ${CLOUDFLARE_API_TOKEN}\"")" || http="000"
    [ "${http}" = "200" ] || fallos=$((fallos + 1))
  done
  if [ "${fallos}" -eq 0 ]; then
    echo "==> ✅ Cloudflare: purgadas ${#urls[@]} URL."
  else
    echo "==> ⚠️  Cloudflare: ${fallos} lote(s) de purga fallaron; el sitio ya está publicado, purgar a mano." >&2
  fi
}

# Con `source deploy.sh` (pruebas) solo se definen las funciones; ejecutado
# directamente, publica y sale sin leer nada más del fichero.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
  exit
fi

#!/usr/bin/env bash
# verificar-portal.sh — linter de infraestructura del Portal VIP (nginx).
#
# Tres modos, todos idempotentes y sin secretos en la salida:
#   --plantilla  EN LOCAL/CI, sin nginx: comprueba la plantilla versionada
#                (nginx/vip-portal.conf.plantilla) — rutas, placeholders que SÍ
#                deben existir, y las invariantes de seguridad de abajo. Es lo
#                que corre `npm test` en este repo.
#   --pre        ANTES de recargar nginx, en el VPS: lo mismo sobre el snippet
#                renderizado (ya sin placeholders), más que el vhost lo incluye,
#                permisos y `nginx -t`. Si algo falla, el despliegue ABORTA sin
#                recargar: nginx sigue sirviendo la versión anterior.
#   --post       DESPUÉS de recargar: sondea en loopback, con el Host del portal,
#                que las rutas llegan al orquestador (401/302, nunca 404 de
#                nginx) para CUALQUIER inquilino, y que la CSP que sale por el
#                borde es EXACTAMENTE la que emite el orquestador.
#
# Invariantes de seguridad (2026-09-22, auditoría Zero Trust, hallazgo A1):
#   · el fichero no concede 'unsafe-inline' ni 'unsafe-eval' en ningún sitio;
#   · no oculta (`proxy_hide_header`) ni declara (`add_header`) la CSP: la
#     única fuente es src/core/http/csp.ts del orquestador, que llega por proxy;
#   · los tres locations que proxyan al orquestador inyectan X-Edge-Proof
#     (/api/vip/ es obligatorio: sin él, toda credencial de cabecera es 403).
#
# Origen: incidente 2026-09-13 «No pudimos cargar tu estado de cuenta» —
# /api/vip/ no estaba proxied en solucionesconia.cl y nginx respondía 404.
set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLANTILLA="${PLANTILLA:-$AQUI/vip-portal.conf.plantilla}"
SNIPPET="${SNIPPET:-/etc/nginx/snippets/vip-portal.conf}"
VHOST="${VHOST:-/etc/nginx/sites-available/solucionesconia.cl}"
DOMINIO="${DOMINIO:-solucionesconia.cl}"
# Orquestador en loopback: mismo valor que `set $orquestador` en la plantilla.
UPSTREAM="${UPSTREAM:-http://127.0.0.1:3001}"
MODO="${1:---pre}"
fallos=0
ok()   { printf '  OK    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; fallos=$((fallos+1)); }

# Líneas de directivas: descarta comentarios (que sí pueden nombrar lo prohibido).
sin_comentarios() { grep -vE '^[[:space:]]*#' "$1"; }

# Extrae el cuerpo de un `location ^~ <prefijo> { … }` (el fichero no anida
# bloques dentro de los locations, así que la primera `}` a nivel de sangría cierra).
bloque_location() { # $1 fichero, $2 prefijo (p. ej. /api/vip/)
  local esc="${2//\//\\/}"
  sed -n "/^[[:space:]]*location \^~ ${esc} {/,/^[[:space:]]*}/p" "$1"
}

# Comprobaciones comunes a la plantilla (con placeholders) y al snippet (renderizado).
checks_fichero() { # $1 fichero, $2 etiqueta
  local f="$1" et="$2"
  [[ -f "$f" ]] && ok "$et existe" || { fail "$et ausente: $f"; return; }
  for loc in '/vip/' '/api/vip/' '/api/auth/' '/clientes/assets/'; do
    if grep -qE "^\s*location \^~ ${loc//\//\\/} \{" "$f"; then ok "location ^~ $loc presente"; else fail "falta location ^~ $loc"; fi
  done
  if grep -qE 'proxy_pass http://\$orquestador\$request_uri;' "$f"; then ok "proxy_pass al orquestador (\$orquestador = loopback)"; else fail "proxy_pass no apunta a \$orquestador"; fi

  # ── Invariantes de seguridad ─────────────────────────────────────────────
  # Solo directivas: los comentarios pueden (y deben) nombrar lo que se prohíbe.
  if sin_comentarios "$f" | grep -qE "unsafe-(inline|eval)"; then
    fail "concede 'unsafe-inline'/'unsafe-eval' (línea $(grep -nE "^[^#]*unsafe-(inline|eval)" "$f" | head -1 | cut -d: -f1)): la CSP del portal es la de csp.ts"
  else ok "sin 'unsafe-inline' ni 'unsafe-eval'"; fi
  if grep -qiE '^\s*proxy_hide_header\s+Content-Security-Policy' "$f"; then
    fail "oculta la CSP del orquestador (proxy_hide_header Content-Security-Policy)"
  else ok "no oculta la CSP del orquestador"; fi
  if grep -qiE '^\s*add_header\s+Content-Security-Policy' "$f"; then
    fail "declara una CSP propia: habría DOS políticas (la de csp.ts y esta)"
  else ok "no declara una CSP propia (fuente única: csp.ts)"; fi
  for loc in '/api/vip/' '/api/auth/' '/vip/'; do
    if bloque_location "$f" "$loc" | grep -qE '^\s*proxy_set_header\s+X-Edge-Proof\s+"[^"]+";'; then
      ok "$loc inyecta X-Edge-Proof"
    else
      fail "$loc NO inyecta X-Edge-Proof$( [[ "$loc" == "/api/vip/" ]] && printf ' (obligatorio: el orquestador responde 403 a toda credencial sin prueba de borde)')"
    fi
  done
}

case "$MODO" in
  --plantilla)
    echo "== verificar-portal --plantilla · $PLANTILLA"
    checks_fichero "$PLANTILLA" "plantilla"
    # En la plantilla los placeholders DEBEN estar: deploy.sh los sustituye al renderizar.
    for ph in __EDGE_SECRET__ __API_SECRET_TOKEN__; do
      if grep -q "$ph" "$PLANTILLA" 2>/dev/null; then ok "placeholder $ph presente (lo renderiza deploy.sh)"; else fail "falta el placeholder $ph"; fi
    done
    if bloque_location "$PLANTILLA" '/api/vip/' | grep -q '__EDGE_SECRET__'; then ok "/api/vip/ usa el placeholder __EDGE_SECRET__ (no un valor fijo)"; else fail "/api/vip/ no usa __EDGE_SECRET__"; fi
    # Un secreto real nunca debe estar en la plantilla versionada.
    # Toda cabecera de credencial debe llevar un placeholder __X__; cualquier otra cosa es un secreto pegado.
    if sin_comentarios "$PLANTILLA" | grep -E '^\s*proxy_set_header\s+(X-Edge-Proof|Authorization)\s+"[^"]+"' | grep -qvE '__[A-Z_]+__'; then fail "hay un valor literal donde debería ir un placeholder"; else ok "sin valores literales en las cabeceras de credencial (solo placeholders)"; fi
    ;;
  --pre)
    echo "== verificar-portal --pre · $SNIPPET"
    checks_fichero "$SNIPPET" "snippet"
    if grep -qE '__[A-Z_]+__' "$SNIPPET" 2>/dev/null; then fail "quedan placeholders sin sustituir: $(grep -oE '__[A-Z_]+__' "$SNIPPET" | sort -u | tr '\n' ' ')"; else ok "sin placeholders sin sustituir"; fi
    if grep -qE 'include /etc/nginx/snippets/vip-portal\*?\.conf;' "$VHOST" 2>/dev/null; then ok "el vhost $DOMINIO incluye el snippet"; else fail "el vhost $VHOST NO incluye el snippet"; fi
    if [[ "$(stat -c '%a' "$SNIPPET" 2>/dev/null)" == "640" || "$(stat -c '%a' "$SNIPPET" 2>/dev/null)" == "600" ]]; then ok "permisos del snippet 640/600"; else fail "permisos del snippet: $(stat -c '%a' "$SNIPPET" 2>/dev/null) (esperado 640)"; fi
    if nginx -t >/dev/null 2>&1; then ok "nginx -t: sintaxis OK"; else fail "nginx -t FALLA: $(nginx -t 2>&1 | grep -E 'emerg|error' | head -1)"; fi
    ;;
  --post)
    echo "== verificar-portal --post · sondas en loopback con Host: $DOMINIO (cualquier inquilino)"
    sonda() { curl -sk -o /dev/null -w '%{http_code}' --max-time 8 -H "Host: $DOMINIO" "$@"; }
    # Cabecera CSP (una línea por aparición, valor normalizado) de una URL.
    csp_de() { curl -sk -D - -o /dev/null --max-time 8 "$@" | tr -d '\r' | grep -iE '^content-security-policy:' | sed -E 's/^[^:]+:[[:space:]]*//'; }
    for t in forte-spa inquilino-futuro-$(date +%s); do
      c=$(sonda "https://127.0.0.1/vip/$t/");                          [[ "$c" =~ ^(302|401|403)$ ]] && ok "/vip/$t/ → $c (orquestador; sin sesión)" || fail "/vip/$t/ → $c (esperado 302/401/403; 404 = nginx no proxya)"
      c=$(sonda "https://127.0.0.1/api/vip/$t/facturacion");           [[ "$c" == "401" ]] && ok "/api/vip/$t/facturacion → 401 (guard de sesión)" || fail "/api/vip/$t/facturacion → $c (esperado 401)"
      c=$(sonda "https://127.0.0.1/api/vip/$t/novedades");             [[ "$c" == "401" ]] && ok "/api/vip/$t/novedades → 401" || fail "/api/vip/$t/novedades → $c (esperado 401)"
      c=$(sonda -X POST -H 'Content-Type: application/json' -d '{"cobroId":1}' "https://127.0.0.1/api/vip/$t/facturacion/intent"); [[ "$c" == "401" ]] && ok "/api/vip/$t/facturacion/intent (POST) → 401" || fail "/api/vip/$t/facturacion/intent → $c (esperado 401)"
    done
    c=$(sonda "https://127.0.0.1/api/auth/client-logout" -X POST);     [[ "$c" =~ ^(200|204|401|405)$ ]] && ok "/api/auth/ proxied ($c)" || fail "/api/auth/client-logout → $c (esperado 200/204/401/405)"
    c=$(sonda "https://127.0.0.1/clientes/assets/ds-v2/tokens.css");   [[ "$c" == "200" ]] && ok "/clientes/assets/ (CSS del portal) → 200" || fail "/clientes/assets/ds-v2/tokens.css → $c (esperado 200)"
    c=$(sonda "https://127.0.0.1/api/admin/cobros");                    [[ "$c" == "404" ]] && ok "/api/admin/ NO expuesto en el dominio del portal (404)" || fail "/api/admin/cobros → $c (esperado 404: este dominio no debe proxyar /api/admin)"
    c=$(sonda "https://127.0.0.1/");                                     [[ "$c" == "200" ]] && ok "landing / → 200" || fail "landing / → $c"

    # ── CSP: la del orquestador, entera y sin manipular ──────────────────────
    ruta="/vip/inquilino-csp-$(date +%s)/"
    csp_borde="$(csp_de -H "Host: $DOMINIO" "https://127.0.0.1$ruta" || true)"
    csp_origen="$(csp_de -H "Host: $DOMINIO" "$UPSTREAM$ruta" || true)"
    n_borde=$(printf '%s' "$csp_borde" | grep -c . || true)
    if [[ "$n_borde" == "1" ]]; then ok "/vip/ responde con UNA cabecera Content-Security-Policy"; else fail "/vip/ responde con $n_borde cabeceras CSP (esperado exactamente 1)"; fi
    if [[ -n "$csp_borde" ]] && ! printf '%s' "$csp_borde" | grep -qE "unsafe-(inline|eval)"; then ok "la CSP servida no concede 'unsafe-inline' ni 'unsafe-eval'"; else fail "la CSP servida concede 'unsafe-*' o está vacía"; fi
    if printf '%s' "$csp_borde" | grep -qE "script-src 'self'(;|$)"; then ok "script-src 'self' estricto en la CSP servida"; else fail "script-src no es 'self' a secas en la CSP servida"; fi
    if [[ -n "$csp_origen" && "$csp_borde" == "$csp_origen" ]]; then ok "la CSP del borde es IDÉNTICA a la del orquestador ($UPSTREAM): sin ocultar ni duplicar"; else fail "la CSP del borde difiere de la del orquestador (¿proxy_hide_header o add_header residual?)"; fi
    ;;
  *)
    echo "uso: $0 --plantilla | --pre | --post" >&2; exit 2 ;;
esac

if [[ $fallos -gt 0 ]]; then echo "✖ verificar-portal $MODO: $fallos fallo(s)"; exit 1; fi
echo "✔ verificar-portal $MODO: todo correcto"

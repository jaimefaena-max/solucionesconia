#!/usr/bin/env bash
# verificar-portal.sh — linter de infraestructura del Portal VIP (nginx).
#
# Dos modos, ambos idempotentes y sin secretos en la salida:
#   --pre   ANTES de recargar nginx: comprueba que el snippet renderizado expone
#           las rutas que el portal necesita (/vip/, /api/vip/, /api/auth/,
#           /clientes/assets/), que no quedan placeholders sin sustituir, que
#           el vhost lo incluye y que `nginx -t` pasa. Si algo falla, el
#           despliegue ABORTA sin recargar: nginx sigue sirviendo la versión
#           anterior.
#   --post  DESPUÉS de recargar: sondea en loopback, con el Host del portal,
#           que las rutas llegan al orquestador (401/302, nunca 404 de nginx),
#           para CUALQUIER inquilino (las reglas son de prefijo: cubren los
#           actuales y los futuros sin tocar nginx).
#
# Origen: incidente 2026-09-13 «No pudimos cargar tu estado de cuenta» —
# /api/vip/ no estaba proxied en solucionesconia.cl y nginx respondía 404.
set -euo pipefail

SNIPPET="${SNIPPET:-/etc/nginx/snippets/vip-portal.conf}"
VHOST="${VHOST:-/etc/nginx/sites-available/solucionesconia.cl}"
DOMINIO="${DOMINIO:-solucionesconia.cl}"
MODO="${1:---pre}"
fallos=0
ok()   { printf '  OK    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; fallos=$((fallos+1)); }

if [[ "$MODO" == "--pre" ]]; then
  echo "== verificar-portal --pre · $SNIPPET"
  [[ -f "$SNIPPET" ]] && ok "snippet existe" || fail "snippet ausente: $SNIPPET"
  for loc in '/vip/' '/api/vip/' '/api/auth/' '/clientes/assets/'; do
    if grep -qE "^\s*location \^~ ${loc//\//\\/} \{" "$SNIPPET" 2>/dev/null; then ok "location ^~ $loc presente"; else fail "falta location ^~ $loc (el portal daría 404 en esa ruta)"; fi
  done
  if grep -qE '__[A-Z_]+__' "$SNIPPET" 2>/dev/null; then fail "quedan placeholders sin sustituir: $(grep -oE '__[A-Z_]+__' "$SNIPPET" | sort -u | tr '\n' ' ')"; else ok "sin placeholders sin sustituir"; fi
  if grep -qE 'proxy_pass http://\$orquestador\$request_uri;' "$SNIPPET" 2>/dev/null; then ok "proxy_pass al orquestador (\$orquestador = loopback :3001)"; else fail "proxy_pass al orquestador no encontrado"; fi
  if grep -qE 'include /etc/nginx/snippets/vip-portal\*?\.conf;' "$VHOST" 2>/dev/null; then ok "el vhost $DOMINIO incluye el snippet"; else fail "el vhost $DOMINIO NO incluye el snippet"; fi
  if [[ "$(stat -c '%a' "$SNIPPET" 2>/dev/null)" == "640" || "$(stat -c '%a' "$SNIPPET" 2>/dev/null)" == "600" ]]; then ok "permisos del snippet $(stat -c '%a %U:%G' "$SNIPPET") (lleva secretos de borde)"; else fail "permisos del snippet $(stat -c '%a' "$SNIPPET" 2>/dev/null): debe ser 640 root:root (lleva secretos de borde)"; fi
  if nginx -t >/dev/null 2>&1; then ok "nginx -t: sintaxis OK"; else fail "nginx -t FALLA: $(nginx -t 2>&1 | grep -E 'emerg|error' | head -1)"; fi
else
  echo "== verificar-portal --post · sondas en loopback con Host: $DOMINIO (cualquier inquilino)"
  sonda() { curl -sk -o /dev/null -w '%{http_code}' --max-time 8 -H "Host: $DOMINIO" "$@"; }
  for t in forte-spa inquilino-futuro-$(date +%s); do
    c=$(sonda "https://127.0.0.1/vip/$t/");                          [[ "$c" =~ ^(302|401|403)$ ]] && ok "/vip/$t/ → $c (orquestador; sin sesión redirige/deniega)" || fail "/vip/$t/ → $c (esperado 302/401/403; 404 = nginx no proxya)"
    c=$(sonda "https://127.0.0.1/api/vip/$t/facturacion");           [[ "$c" == "401" ]] && ok "/api/vip/$t/facturacion → 401 (guard de sesión)" || fail "/api/vip/$t/facturacion → $c (esperado 401; 404 = nginx no proxya)"
    c=$(sonda "https://127.0.0.1/api/vip/$t/novedades");             [[ "$c" == "401" ]] && ok "/api/vip/$t/novedades → 401" || fail "/api/vip/$t/novedades → $c"
    c=$(sonda -X POST -H 'Content-Type: application/json' -d '{"cobroId":1}' "https://127.0.0.1/api/vip/$t/facturacion/intent"); [[ "$c" == "401" ]] && ok "/api/vip/$t/facturacion/intent → 401" || fail "intent → $c"
  done
  c=$(sonda "https://127.0.0.1/api/auth/client-logout" -X POST);     [[ "$c" =~ ^(200|204|401|405)$ ]] && ok "/api/auth/ proxied ($c)" || fail "/api/auth/client-logout → $c"
  c=$(sonda "https://127.0.0.1/clientes/assets/ds-v2/tokens.css");   [[ "$c" == "200" ]] && ok "/clientes/assets/ (CSS del portal) → 200" || fail "/clientes/assets/ds-v2/tokens.css → $c"
  c=$(sonda "https://127.0.0.1/api/admin/cobros");                    [[ "$c" == "404" ]] && ok "/api/admin/ NO expuesto en el dominio del portal (404)" || fail "/api/admin/cobros → $c (¡no debe estar proxied aquí!)"
  c=$(sonda "https://127.0.0.1/");                                     [[ "$c" == "200" ]] && ok "landing / → 200" || fail "landing / → $c"
fi

if [[ $fallos -gt 0 ]]; then echo "✖ verificar-portal $MODO: $fallos fallo(s)"; exit 1; fi
echo "✔ verificar-portal $MODO: todo correcto"

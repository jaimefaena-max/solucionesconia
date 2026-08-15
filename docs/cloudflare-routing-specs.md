# Especificaciones de enrutamiento en Cloudflare — API del Vendedor IA

**Destino:** dashboard de Cloudflare de la zona `solucionesconia.cl`.
**Ámbito:** hostname `admin.solucionesconia.cl` (backend del Vendedor IA).
**Estado:** pendiente de aplicación en el panel de Cloudflare (no versionable en código).

---

## 1. Contexto — por qué existe este documento

El chat del Vendedor IA (widget en `solucionesconia.cl`) hace POST a
`https://admin.solucionesconia.cl/api/sales-agent/chat`. En producción falla con
`TypeError: Failed to fetch` y el widget muestra *"No pude conectar con Sofía"*.

La auditoría de enrutamiento **aisló cada capa** y descartó todo lo que no era el
problema:

| Capa | Prueba directa (aislada) | Resultado |
|---|---|---|
| DO App Platform (Fastify) | URL `zasa-orchestrator-58qq4.ondigitalocean.app` | ✅ `OPTIONS` → 204 + CORS correcto; `/health` → `{"commit":"b55a672"}` |
| nginx del VPS (`159.223.213.237`) | por IP, bypass Cloudflare | ✅ `OPTIONS` → 204 + CORS correcto; proxya `/api/sales-agent/` a DO con Bearer |
| App Spec (`.do/app.yaml`) | revisión | ✅ un solo servicio, sin componente estático ni solapamiento de rutas |
| **Cloudflare** (público) | `admin.solucionesconia.cl` | ❌ `OPTIONS` → 405; `POST` → 400 XML; `/health` → HTML del SPA |

**Diagnóstico:** el backend (DO), el proxy (nginx VPS) y el App Spec están
**correctos**. El quiebre lo introduce **Cloudflare**, que enruta bien `/widget/*`
al VPS pero **desvía `/api/*` y `/health` a un origen estático incorrecto**
(SPA / DO Spaces), saltándose el nginx del VPS que contiene el CORS y el Bearer.

```
Browser → Cloudflare (admin.solucionesconia.cl)
            ├─ /widget/*         → VPS nginx (159.223.213.237)   ✅ correcto
            └─ /api/*, /health   → host estático (SPA / Spaces)  ❌ INCORRECTO
                                    debería ir → VPS nginx → DO Fastify
```

Evidencia por path (vía Cloudflare):

```
/widget/vendedor-ia.js     → 200 text/javascript     (llega al VPS)
/health                    → 200 text/html (SPA)      (NO llega al VPS)
/api/sales-agent/chat      → 200 text/html (SPA)      (NO llega al VPS)
POST /api/sales-agent/chat → 400 XML "Couldn't route the request"  (DO Spaces)
```

---

## 2. Directivas de configuración obligatorias (dashboard de Cloudflare)

### 2.1. DNS

- El registro de **`admin.solucionesconia.cl`** (tipo A o CNAME) debe apuntar
  **exclusivamente a la IP del VPS: `159.223.213.237`**, en modo **Proxied**
  (nube naranja).
- Eliminar cualquier registro/alias que resuelva `admin` (o subrutas) hacia
  DigitalOcean App Platform o DO Spaces.
- Resultado esperado: **todo** el tráfico de `admin.solucionesconia.cl` entra por
  el nginx del VPS, que ya decide qué proxyear a DO y qué servir localmente.

### 2.2. Reglas de Origen / Page Rules / Configuration Rules

- **Revisar y ELIMINAR** cualquier regla que reescriba el **Origin** o haga
  *forwarding* de `/api/*`, `/api/sales-agent/*` o `/health` hacia:
  - `*.ondigitalocean.app` (App Platform directo), o
  - un bucket/endpoint de **DO Spaces** (el error `Couldn't route the request`
    en formato XML es la firma de Spaces).
- **Todo el tráfico debe caer al VPS** (`159.223.213.237`). El nginx del VPS ya
  tiene los bloques `location /api/sales-agent/` y `location /` que proxyean a
  `zasa-orchestrator-58qq4.ondigitalocean.app` con el Bearer y el CORS correctos.
- Si existe una regla legítima para `/widget/*`, dejarla — esa ruta ya funciona.

### 2.3. WAF / Seguridad

- Validar que **ninguna Managed Rule ni Custom Rule del WAF bloquee el método
  `OPTIONS`** (preflight CORS) en `/api/*`. El síntoma `OPTIONS → 405` con
  `Server: cloudflare` es compatible con un bloqueo de método en el edge.
- Asegurar que el **preflight `OPTIONS` no sea challenged** (Managed Challenge /
  JS Challenge): un challenge sobre el preflight lo convierte en fallo de CORS.
- No cachear respuestas de `/api/*` ni `/health` (deben ser siempre dinámicas).

---

## 3. Verificación post-cambio (criterio de aceptación)

Tras aplicar la configuración, estos comandos deben pasar:

```bash
# 1) Preflight vía Cloudflare debe devolver 204 + ACAO de la landing:
curl -s -D - -o /dev/null -X OPTIONS \
  -H "Origin: https://solucionesconia.cl" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  https://admin.solucionesconia.cl/api/sales-agent/chat
#   Esperado: HTTP/2 204 · access-control-allow-origin: https://solucionesconia.cl

# 2) /health vía Cloudflare debe devolver el JSON con el commit (NO el SPA):
curl -s https://admin.solucionesconia.cl/health
#   Esperado: {"status":"ok","service":"ZASA-Orchestrator","commit":"..."}
```

- [ ] `OPTIONS /api/sales-agent/chat` (vía Cloudflare) → **204** con `ACAO: https://solucionesconia.cl`.
- [ ] `/health` (vía Cloudflare) → **JSON** con `commit`, no HTML del SPA.
- [ ] End-to-end: enviar "hola" desde el widget en `solucionesconia.cl` → responde "Sofía".

---

## 4. Lo que NO es el problema (para no perder tiempo)

- ❌ **No** es el código CORS de `zasa-orchestrator/src/server.ts` — ya corregido
  y desplegado (`b55a672`); la app responde 204 correcto en su URL directa.
- ❌ **No** es el `.do/app.yaml` — un solo servicio, sin componente estático ni
  solapamiento de rutas. **No tocar el App Spec** (aplicarlo a ciegas puede
  tumbar producción por fail-closed si faltan secretos).
- ❌ **No** es el nginx del VPS — su vhost proxya `/api/sales-agent/` a DO con el
  CORS y el Bearer correctos (verificado por IP directa).
- ✅ **Es** el enrutamiento de Cloudflare para `admin.solucionesconia.cl`.

# DESIGN.md — Design System v2 · Web Pública `solucionesconia.cl`

> Fuente única de verdad del lenguaje visual de la landing pública de la agencia.
> **Alcance:** solo la web pública (`index.html` + `/acceso`). El "DS v2" del
> Portal VIP/Cockpit (orquestador) es independiente y NO se gobierna aquí.
> **Estado:** documentación + auditoría. No toca producción (la landing se
> despliega a mano por SSH con `deploy.sh`).
> **Fecha:** 2026-10-21.

---

## 0. Stack real (verificado, no asumido)

| Capa | Qué es | Dónde |
|---|---|---|
| Framework CSS | **Tailwind v3.4.19** (CLI, build local con purga) | `tailwind.config.js`, `src/input.css` → `dist/style.css` |
| Build | `npm run build` = `tailwindcss -i src/input.css -o dist/style.css --minify` | `package.json` |
| Componentes | Capa propia `.sc-*` (botones, tarjetas, modal) | `src/input.css` |
| Layout | **Estilos inline** con hex hardcodeado (respaldo anti-caché del CDN difunto) | `index.html` |
| Tipografía | **Inter** variable con eje `opsz` (14..32), `font-optical-sizing:auto` | `<link>` Google Fonts + `input.css` |
| JS | Vanilla, sin deps: `IntersectionObserver` (`data-reveal`), parallax (`data-parallax`), modal Cal.com | `src/main.js` |
| `/acceso` | Pantalla login, **mono JetBrains**, YA usa `:root` con variables | `acceso/acceso.css` |

> ⚠️ **Corrección al brief:** la landing **sí** usa Tailwind (no es "HTML/CSS/JS
> nativo sin framework"). Lo nativo es el JS y la *mayoría* del styling, que va
> inline. Tailwind aporta utilidades de layout del header y los tokens de marca.

### Deuda técnica raíz (el problema que este DS v2 resuelve)
- **Cero tokens en la home.** Los colores viven como hex crudo repetido decenas
  de veces en `style=""` inline (`#06B6D4` aparece ~30×, `#0F172A`, `rgba(248,250,252,.xx)` en todas sus opacidades…). Cambiar un color = buscar y reemplazar a mano.
- **Dos sistemas de variables divergentes:** `acceso.css` ya define `:root{--accent…}`; la home no. No comparten fuente.
- `tailwind.config.js` define `primary/accent/base/dark` pero **casi no se usan** (el marcado es inline, no clases).
- Hover de botones necesita `!important` porque el inline gana especificidad.

---

## 1. Tokens globales — Dark Mode B2B

Objetivo DS v2: **una sola declaración `:root`** (en `src/input.css`) que sustituya
el hex inline. Nombres alineados con los que ya existen en `acceso.css`.

### 1.1 Color — Fondos
| Token | Valor | Uso actual |
|---|---|---|
| `--bg` | `#0F172A` | fondo base (body, hero, CTA final) |
| `--bg-raise` | `#101B36` | sección elevada (agentes, comparativa) |
| `--bg-grad-agentes` | `linear-gradient(180deg,#0F172A,#101B36)` | transición de sección |

### 1.2 Color — Superficies glassmorphism
| Token | Valor | Uso |
|---|---|---|
| `--glass` | `rgba(255,255,255,.045)` | tarjeta `/acceso` |
| `--glass-card` | `linear-gradient(160deg,rgba(255,255,255,.07),rgba(255,255,255,.025))` | `.sc-card` |
| `--glass-header` | `rgba(15,23,42,.62)` | header fijo (con `backdrop-filter:blur(14px)`) |
| `--stroke` | `rgba(255,255,255,.08)` | borde estándar de tarjeta |
| `--stroke-soft` | `rgba(255,255,255,.06)` | borde footer / divisores |
| `--stroke-strong` | `rgba(255,255,255,.18)` | borde botón ghost |
| `--blur-card` | `18px` · `--blur-header` `14px` · `--blur-glass` `22px` | radios de desenfoque |

### 1.3 Color — Acentos de IA
| Token | Valor | Uso |
|---|---|---|
| `--accent` | `#06B6D4` | **primario** — cian CTA, puntos pulsantes, bordes activos |
| `--accent-hover` | `#22D3EE` | hover del CTA primario |
| `--accent-light` | `#67E8F9` | texto de énfasis en titular, links de tarjeta |
| `--accent-faint` | `#A5F3FC` | micro-copy de métrica en tarjeta |
| `--accent-ink` | `#04202B` | texto sobre fondo cian (contraste AA) |
| `--primary` | `#1E3A8A` | azul institucional (glows, degradados de fondo) |
| `--primary-dark` | `#152C66` | — |

### 1.4 Color — Texto (escala de opacidad sobre `--bg`)
| Token | Valor | Uso |
|---|---|---|
| `--ink` | `#F8FAFC` | texto principal / titulares |
| `--ink-80` | `rgba(248,250,252,.86)` | frase de cierre destacada |
| `--ink-76` | `rgba(248,250,252,.76)` | subtítulo hero |
| `--ink-66` | `rgba(248,250,252,.66)` | cuerpo de párrafos |
| `--ink-50` | `rgba(248,250,252,.50)` | texto "Sin IA", micro-pruebas |
| `--ink-42` | `rgba(248,250,252,.42)` | footer |
| `--ink-28` | `rgba(248,250,252,.28)` | placeholders |

> **Regla:** no inventar más escalones de opacidad. Estos 7 cubren todo el sitio.

### 1.5 Estados / feedback
| Token | Valor | Uso |
|---|---|---|
| `--error` | `#FDA4AF` | aviso de error en `/acceso` |
| `--focus` | `#67E8F9` | `outline` de `:focus-visible` (12:1 sobre `--bg`) |

### 1.6 Sombras
| Token | Valor |
|---|---|
| `--shadow-card` | `0 20px 60px rgba(4,12,28,.5)` |
| `--shadow-card-hover` | `0 24px 70px rgba(4,12,28,.6), 0 0 40px rgba(6,182,212,.12)` |
| `--shadow-cta` | `0 0 0 1px rgba(255,255,255,.14) inset, 0 14px 44px rgba(6,182,212,.36)` |
| `--shadow-modal` | `0 30px 80px rgba(4,12,28,.7), 0 0 60px rgba(6,182,212,.12)` |
| `--glow-cyan` | `0 0 10px rgba(6,182,212,.8)` (viñetas "Con IA") |

---

## 2. Tipografía

- **Familia:** `"Inter", system-ui, sans-serif`. Mono (`/acceso`): `"JetBrains Mono", ui-monospace, …` → token `--mono`.
- **Eje óptico:** `opsz 14..32`, `font-optical-sizing:auto` (Display en titulares, Text en cuerpo).
- **Escala fluida** (ya en uso, formalizar como tokens):

| Token | `clamp()` | Rol |
|---|---|---|
| `--fs-display` | `clamp(44px,7.4vw,86px)` | H1 hero |
| `--fs-h2` | `clamp(32px,4.6vw,54px)` | títulos de sección |
| `--fs-h2-cta` | `clamp(34px,5.4vw,64px)` | H2 del cierre (weight 800) |
| `--fs-h3` | `22px` | título de tarjeta |
| `--fs-lead` | `clamp(17px,2vw,21px)` | subtítulo hero |
| `--fs-body` | `16px` / `clamp(16px,1.8vw,19px)` | cuerpo |
| `--fs-sm` | `14px` · `--fs-xs` `13px` | micro-copy, etiquetas |

- **Pesos:** 400 (cuerpo), 500 (micro-prueba), 600 (ghost/links), 700 (titulares/CTA), 800 (H2 cierre).
- **Tracking:** titulares `letter-spacing:-.03em`/`-.035em`; etiquetas uppercase `+.1em`/`.14em`.
- **Balance:** `text-wrap:balance` en titulares, `text-wrap:pretty` en párrafos.

---

## 3. Espaciado, radios, layout

### 3.1 Ritmo vertical (padding de sección, fluido)
| Token | Valor |
|---|---|
| `--section-y` | `clamp(88px,12vw,148px)` |
| `--section-y-cta` | `clamp(96px,13vw,168px)` |
| `--section-x` | `clamp(20px,5vw,72px)` |
| `--hero-pad` | `clamp(96px,14vh,140px) … clamp(56px,9vh,96px)` |

### 3.2 Contenedores
- Ancho máx. contenido: `1280px` (home) · `1160px` (comparativa) · `780px` (CTA) · `420px` (`/acceso`).
- Hero alto: `min-height:100vh; 100svh` (fallback + `svh` para móvil).

### 3.3 Radios
| Token | Valor | Uso |
|---|---|---|
| `--r-pill` | `999px` | botones, badges |
| `--r-card` | `22px` | tarjetas |
| `--r-modal` | `20px` | modal / tarjeta login |
| `--r-icon` | `13px` | caja de icono de tarjeta |
| `--r-input` | `12px` | inputs |

### 3.4 Grid de servicios
`repeat(auto-fit, minmax(min(100%,420px),1fr))`, `gap:clamp(18px,2.2vw,26px)` → 2×2 en desktop, 1 col en móvil. **Mantener** este patrón auto-fit (no media queries).

---

## 4. Micro-interacciones (ya implementadas · conservar)

| Nombre | Detalle |
|---|---|
| `[data-reveal]` | `opacity 0→1` + `translateY(20px)→0`, `0.9s cubic-bezier(.22,.61,.36,1)`; `.is-in` vía `IntersectionObserver` (threshold .12). Escalonado **por sección** (90ms × índice). |
| Parallax hero | `data-parallax="0.18"`, `translate3d` en `rAF` sobre scroll. |
| `pulseDot` | punto cian, `2.4–2.6s ease-in-out infinite` (escala + opacidad). |
| Hover botón | `transform` + color/sombra, 160–200ms; **requiere `!important`** por el inline. |
| `:active` | `scale(0.97)`. |
| `:focus-visible` | `outline 2px --focus`, offset 3px. |
| Modal | entrada `translateY(16px) scale(.98)→none`, 0.35s; backdrop blur 6px. |
| **A11y** | `@media (prefers-reduced-motion:reduce)` anula reveal, parallax, `pulseDot` y active. **Invariante: todo movimiento nuevo debe respetarlo.** |

---

## 5. Componentes a refactorizar (inventario de la auditoría)

Prioridad: **1 = mayor impacto / mayor deuda**.

| # | Componente | Estado | Refactor propuesto |
|---|---|---|---|
| 1 | **Tokens globales** | hex inline repetido, sin `:root` en la home | Declarar `:root` en `src/input.css` con §1; migrar inline → `var(--…)`. Unificar con `acceso.css`. |
| 2 | **Tarjetas de servicio** (`.sc-card`, ×4) | glass OK, pero 40+ líneas de estilo inline idénticas duplicadas por tarjeta | Mover todo el estilo de reposo a `.sc-card` en `input.css`; dejar el `<article>` sin `style`. |
| 3 | **CTAs a Sofía** (`.sc-btn-primary/ghost`) | reposo inline + hover con `!important` | Pasar reposo a clase; elimina la guerra de especificidad y los `!important`. |
| 4 | **Hero** | `100svh`, degradados y grano inline | Extraer capas (`--hero-overlay`, grano) a clases; tokenizar degradado. |
| 5 | **Header** | layout Tailwind + inline redundante (fallback anti-caché ya innecesario) | Consolidar en clase; retirar duplicación `class` + `style` ahora que no hay CDN. |
| 6 | **Sección Antes/Después** | viñetas y glows con hex inline | Tokenizar `--glow-cyan`, `--ink-50`; clase `.sc-compare-item`. |
| 7 | **Footer** | inline simple | Clase `.sc-footer`; usa `--ink-42`, `--stroke-soft`. |
| 8 | **Badge "Automatización…"** (pill hero) | inline | Clase `.sc-badge` con `--accent` faint. |
| 9 | **Modal Cal.com** | ya en `input.css` (`.sc-modal*`) ✅ | Solo tokenizar colores/sombras. |
| 10 | **`/acceso`** | ya tokenizado ✅ | Alinear nombres de variables con §1 (ya ~90% coincidentes). |

### Fuera de alcance (no tocar)
- Widget de Sofía (`vendedor-ia-v17.js`): vive aislado en Shadow DOM, repo `admin_solucionesconia`.
- Scripts de autodestrucción de SW y anulación de caché en `<head>` (invariantes de operación).
- `<script>` del widget como último hijo de `<body>` (invariante documentado).

---

## 6. Principios DS v2

1. **Un color se define una vez.** Todo valor nuevo entra como token en `:root`; nada de hex en `style=""`.
2. **Reposo en clase, no inline.** El inline fue respaldo del CDN de Tailwind, ya retirado: dejó de tener razón de ser.
3. **Fluido por `clamp()`, no por breakpoints.** Coherente con el pipeline de purga (una clase nueva no existe hasta el siguiente build).
4. **Movimiento con freno.** Nada se mueve si el usuario pidió `reduce`.
5. **El CTA primario manda.** Un solo cian dominante por vista; lo demás es ghost.
6. **Regla de oro:** ninguna publicación nombra la razón social del cliente, su RUT ni su domicilio (filtro B16).

---
titulo: Página de presentación de la app Desabolladura Premium en solucionesconia.cl/desabolladura/
fecha: 2026-11-25
repo: Workspace_Agencia/Agencia_Solucionesconia (repo GitHub `solucionesconia`)
tamano: normal
estado: implementado (local, sin commit)
version_plano: 4
sha: (se rellena al implementar)
linear: (se crea al cierre de sesión)
---

# Página de presentación de Desabolladura Premium

## 1. Problema y para quién

Hoy la tarjeta «Desabolladura Premium» de la sección Demos (`index.html:651-685`) lleva con el botón «Ir»
directo a `https://taller.solucionesconia.cl/`, que es la propia app de demostración. El dueño de un taller
de desabolladura y pintura que llega desde la landing, un correo o un reel cae dentro de un producto con la
marca «Taller Demo», sin la marca de la agencia, sin explicación del problema que resuelve, sin cómo se
contrata y con un CTA principal («Probar la demo») que lo manda a la pantalla de inicio de sesión.

Falta una página de venta con la marca Soluciones con IA que cuente qué hace la app, para quién, cómo
funciona y qué sigue, con dos salidas: **probar la demo** y **conversar con nosotros**.

## 2. Criterios de aceptación

- [ ] C1 — Hecho cuando `desabolladura/index.html` existe y, servido en local, responde 200 en `/desabolladura/` con `document.title` = «Desabolladura Premium — App para talleres de desabolladura y pintura | Soluciones con IA».
- [ ] C2 — Hecho cuando la página tiene exactamente ocho `<section>`, con estos `id` y en este orden: `inicio`, `te-suena`, `como-funciona`, `tres-miradas`, `funciones`, `a-medida`, `preguntas`, `cierre`.
- [ ] C3 — Hecho cuando en una ventana de **1280×552** la portada muestra sin hacer scroll el titular, el subtítulo y los dos botones («Probar la demo» y «Conversar con Sofía»), y ningún elemento visible queda cortado a la derecha (prueba de §9).
- [ ] C4 — Hecho cuando en **360×740**, **375×812**, **768×1024** y **1024×768** ningún elemento visible queda cortado a la derecha, y en 360 y 375 los dos botones de la portada se ven sin hacer scroll.
- [ ] C5 — Hecho cuando: (a) todo enlace a `https://taller.solucionesconia.cl/` tiene `target="_blank"`, `rel="noopener"` y un `aria-label` que termina en «(se abre en otra pestaña)»; (b) todo botón «Conversar con Sofía» lleva `data-open-sofia` y `href="mailto:contacto@solucionesconia.cl?subject=Quiero%20saber%20m%C3%A1s%20de%20Desabolladura%20Premium"`; (c) con el widget cargado, el clic en «Conversar con Sofía» abre el panel del chat (lo expone `window.SolucionesconiaVendedorIA.open()`); y con el widget ausente (simulado en la consola con `window.SolucionesconiaVendedorIA = undefined` antes del clic), el mismo clic abre el modal de Cal.com (`#scheduler-modal` sin `hidden`).
- [ ] C6 — Hecho cuando la tarjeta de la sección Demos de `index.html` enlaza a `/desabolladura/` en la misma pestaña (botón «Conocer la app») y tiene un enlace secundario «o pruébala directo» a `https://taller.solucionesconia.cl/` (pestaña nueva, ≥ 3rem de alto), y el resto de `index.html` no cambia respecto del estado previo a esta tarea.
- [ ] C7 — Hecho cuando la página **no envía ningún evento** al embudo anónimo de la landing: con `data-embudo="no"` en el `<body>`, `src/main.js` no hace ninguna petición a `/api/sales-agent/evento` (ni `visita`, ni `cta_clic`, ni los hitos del chat). En `/` el comportamiento no cambia (la petición `visita` sale).
- [ ] C8 — Hecho cuando `deploy.sh`: (a) publica `desabolladura` (en `PUBLICAR`); (b) sustituye `$CSS_VERSION` y `$JS_VERSION` en todos los `*.html` del staging que los contengan, sin abortar cuando un `.html` no los tiene; (c) aborta si queda algún marcador en cualquier `*.html`; (d) verifica por loopback que el sha de lo servido en `/desabolladura/` coincide con el del staging. Se comprueba con `bash -n` y con la prueba en seco de §9, ejecutada bajo `set -Eeuo pipefail`. **No se ejecuta en el VPS en esta tarea.**
- [ ] C9 — Hecho cuando `tailwind.config.js` incluye `./desabolladura/**/*.html`; tras `npm run build`, `dist/style.css` contiene la regla de `!scroll-mt-[calc(var(--sc-barra,4.75rem)+1rem)]` (`grep -F '\!scroll-mt-\[calc'`); y el ancla no queda bajo la cabecera: en ventanas de 1280×552 y 1920×1080, tras pulsar «Funciones» y «Preguntas» en el menú y esperar el fin del desplazamiento, el `<h2>` de la sección empieza por debajo del borde inferior de la cabecera (`h2.getBoundingClientRect().top >= document.querySelector('.sc-header').getBoundingClientRect().bottom`).
- [ ] C10 — Hecho cuando las capturas viven en `assets/desabolladura/` con nombre fechado (`-20261125`), en WebP; cada variante 1x pesa ≤ 150 KB y cada 2x ≤ 300 KB; todas las `<img>` llevan `width`, `height` y `alt`; solo la imagen del tablero de la portada lleva `fetchpriority="high"` y el resto `loading="lazy"`; y `og-20261125.jpg` mide 1200×630. Cada captura se revisa a ojo: el auto 3D se ve dibujado (no negro ni vacío) donde corresponde.
- [ ] C11 — Hecho cuando la consola del navegador local no muestra errores de la página (se excluyen los de las llamadas del widget a la API de `admin.solucionesconia.cl`: el bundle carga desde localhost, pero la API rechaza ese origen por diseño) y la página solo pide recursos a `'self'`, `admin.solucionesconia.cl` y `cal.com`.
- [ ] C12 — Hecho cuando `grep -iE 'minimarket|78\.079|godoy|riesgo cero|no pagas|gratis|gratuit' desabolladura/index.html` no devuelve nada, y cada función que se anuncia está en la tabla de §4.4.
- [ ] C13 — Hecho cuando `sitemap.xml` incluye `https://www.solucionesconia.cl/desabolladura/` y sigue siendo XML válido.
- [ ] C14 — Hecho cuando **nada** se publica: sin commit, sin `git push`, sin `deploy.sh` en el VPS. Los cambios quedan en el árbol de trabajo local para que el dueño los revise.

## 3. Alcance

- **Entra:** la página nueva, sus imágenes, el enlace desde la tarjeta Demos, el ajuste de `deploy.sh`, `tailwind.config.js`, `src/main.js` (guardia del embudo) y `sitemap.xml`.
- **No entra:**
  - La app (`Workspace_Agencia/desabolladura`): no se toca. Su portada `Landing.tsx` sigue igual.
  - Precios y promesas comerciales: no hay precio aprobado. La página no muestra montos ni frases como «riesgo cero», «no pagas nada» o «gratis» (las de la portada de la agencia están en revisión aparte, SOL-209).
  - Testimonios o logos de clientes: no hay talleres clientes. No se inventan.
  - Video: el Video D de talleres no está aprobado para la web; no se incrusta.
  - Medir la página nueva en el embudo: la lista cerrada del orquestador no admite eventos nuevos (`zasa-orchestrator/src/services/embudoLandingService.ts:55-56`); se hará en otra tarea si se quiere.
  - El prompt de Sofía: no se cambia. Desde esta página, Sofía responde como en la portada.
  - El título interno del iframe de Cal.com en `src/main.js:138` («diagnóstico gratuito»): no se toca aquí.
  - Publicar (commit, push, `deploy.sh`): lo decide el dueño después de revisar.

## 4. Diseño técnico

### 4.1 Ficheros

| Ruta | Nuevo / cambia | Qué cambia | Por qué |
|---|---|---|---|
| `desabolladura/index.html` | nuevo | La página completa (§4.2, §4.3). Mismo `<head>` base que `index.html:4-159` (autodestrucción de SW, metas anti-caché, precarga de Inter, `/dist/style.css?v=$CSS_VERSION`, `<noscript>` de `data-reveal`, `preconnect` a `admin.`), sin el JSON-LD de la portada, con metas propias (§4.2). Sprite de iconos, cabecera, 8 secciones, pie, modal de Cal.com, `/src/main.js?v=$JS_VERSION` y el script del widget de Sofía como último hijo del `<body>`. `<body … data-embudo="no">` | Página de venta con la marca de la agencia |
| `assets/desabolladura/tablero-20261125-960.webp` y `…-1920.webp` | nuevo | Recorte del tablero del administrador (§4.5) | Portada y «tres miradas» |
| `assets/desabolladura/trabajador-20261125-960.webp` y `…-1920.webp` | nuevo | Recorte de la orden vista por el trabajador, con el auto 3D y las tareas | «Tres miradas» |
| `assets/desabolladura/cliente-20261125-390.webp` y `…-780.webp` | nuevo | Portal del cliente en celular (390×844 CSS) | Teléfono en portada y «tres miradas» |
| `assets/desabolladura/cobranza-20261125-960.webp` y `…-1920.webp` | nuevo | Recorte de la cobranza a compañías | «Funciones» |
| `assets/desabolladura/og-20261125.jpg` | nuevo | 1200×630 | Vista previa al compartir |
| `index.html` | cambia | Solo el bloque del botón de la tarjeta, `index.html:668-673` (§4.6). Nada más | La tarjeta lleva a la presentación y deja el atajo a la demo |
| `src/main.js` | cambia | Al principio de `contar` (línea 15): `if (document.body.dataset.embudo === "no") return;`. Así ninguna llamada envía nada en esa página: `visita` (línea 30), `cta_clic` (34-36) y los hitos del chat (41-46) | La página no descuadra el embudo de la portada |
| `tailwind.config.js` | cambia | `content: ["./index.html", "./desabolladura/**/*.html", "./src/**/*.js"]` | Tailwind purga las clases que no ve |
| `deploy.sh` | cambia | §4.7 | Publicar la carpeta, versionar su CSS/JS y verificarla |
| `sitemap.xml` | cambia | Nueva `<url>`: `https://www.solucionesconia.cl/desabolladura/`, `monthly`, prioridad `0.8` | Indexación |
| `docs/specs/2026-11-25-pagina-desabolladura.md` | nuevo | Este plano | Flujo de ingeniería |

En `desabolladura/` solo existe `index.html`: `PUBLICAR` copia la carpeta entera, así que no se deja ahí ningún otro fichero.

### 4.2 Estructura de la página

**Metas:** `<html lang="es-CL">`; título de C1; `description` = «App para talleres de desabolladura y pintura: recepción con fotos, avance por pieza en 3D, repuestos, avisos al cliente y cobranza a compañías. Prueba la demo con datos de ejemplo.»; `robots` `index, follow`; canónica `https://www.solucionesconia.cl/desabolladura/`; Open Graph (`og:type` website, `og:locale` es_CL, `og:title`, `og:description`, `og:url` = canónica, `og:site_name` Soluciones con IA, `og:image` = `https://www.solucionesconia.cl/assets/desabolladura/og-20261125.jpg`, 1200×630) y `twitter:card` `summary_large_image`. `og:title` y `twitter:title` = el título de C1; `og:description` y `twitter:description` = la `description` de arriba. `author` = «Soluciones con IA». Sin `keywords`. No se copia ninguna meta de texto de `index.html`.

**Secciones con `sc-escala`:** desde `#te-suena` hasta `#cierre` y el `<footer>`, igual que las secciones de la portada de la agencia (`index.html:652`, `:747`). `#inicio` no la lleva.

**Secciones:** ocho `<section>`, cada una con su `id`, en el orden de C2. No hay más `<section>` (la cabecera es `<header>`, el pie `<footer>` y el modal un `<div>`). Las siete primeras llevan la clase `!scroll-mt-[calc(var(--sc-barra,4.75rem)+1rem)]` para que el ancla no quede bajo la cabecera fluida (que llega a 7.5rem, `src/input.css:364`). Lleva el modificador `!` (Tailwind emite `!important`) porque la regla global `section[id] { scroll-margin-top: 5.5rem }` de `src/input.css:67-69` va después de las utilidades y tiene más especificidad (0,1,1 frente a 0,1,0): sin `!` la utilidad no se aplicaría. La regla global no se toca.

**Relleno de la portada:** `<section id="inicio">` lleva las mismas utilidades que la portada de la agencia (`index.html:236`): `relative flex items-center overflow-hidden pb-16 pt-[6.25rem] sm:pt-28 lg:pb-24`, sin `min-h-[100svh]` (la portada de esta página no ocupa toda la pantalla). Debajo de 1024 px el relleno superior lo dan `pt-[6.25rem] sm:pt-28`; desde 1024 px lo sustituye `#inicio { padding-top: calc(var(--sc-barra) + 2rem) }` de `src/input.css:369` (y `+ 1rem` en pantallas bajas, `:385`), que gana por especificidad.

**Reutilizado de `src/input.css`:** `sc-header`, `sc-header__barra`, `sc-marca`, `sc-marca__icono`, `sc-marca__nombre`, `sc-marca__ia`, `sc-btn-primary`, `sc-btn-ghost`, `sc-card`, `sc-escala`, `sc-modal*`, `sc-hero-titulo`, `sc-hero-col` y `data-reveal`. El `id="inicio"` es a propósito: hereda de `src/input.css:363-371` el relleno superior bajo la cabecera fluida y el tamaño de `.sc-hero-titulo`, y de `:384-386` el ajuste de pantallas bajas (`#inicio { padding-top… }` y `#inicio .sc-hero-col { gap: 1rem }`). **No** se usan `sc-garantia*`, `sc-foto-caja`, `sc-hero-confianza` ni `sc-hero-cta` (son de la portada de la agencia y sus reglas `#inicio …` no aplican). No se añade CSS a `src/input.css`.

**Sin `data-reveal` en la portada (`#inicio`):** etiqueta, titular, subtítulo, botones, línea pequeña e imágenes aparecen sin animación. `src/main.js` añade `.is-in` en `DOMContentLoaded`, que espera al widget (`defer`, cross-origin): con `admin.` lento la portada quedaría invisible. Desde `#te-suena` hacia abajo sí se usa `data-reveal`, nunca dentro de un `<details>`.

**Cabecera** (basada en `index.html:199-231`; no se cuelga nada del widget en ella, invariante de `index.html:189-194`):
- Marca (`sc-marca`) que enlaza a `/`, `aria-label` «Soluciones con IA — Inicio».
- Menú `hidden lg:flex`: «Cómo funciona» (`#como-funciona`), «Funciones» (`#funciones`), «Preguntas» (`#preguntas`).
- Derecha: ghost «Volver al inicio» (`/`), clases `hidden md:inline-flex`; primario «Probar la demo» (pestaña nueva), clases `hidden sm:inline-flex`. **Debajo de 640 px la cabecera muestra solo la marca** (la portada tiene sus propios botones justo debajo). Así nada se corta a 360 o 375 px.

**Portada (`#inicio`), maquetación:** rejilla `lg:grid-cols-12`; texto en `lg:col-span-5`, imagen en `lg:col-span-7`, para que la captura se vea más grande y legible. En celular la imagen va debajo de la línea pequeña y solo con la ventana (el teléfono va `hidden lg:block`).

**Marcos de las capturas:** ventana de navegador (barra superior con tres puntos y el texto «taller.solucionesconia.cl») para las capturas de escritorio, y marco de teléfono redondeado para la del cliente. Solo utilidades de Tailwind.

**Imágenes responsive:** las de escritorio con `srcset="…-960.webp 960w, …-1920.webp 1920w"` y `sizes="(min-width:1024px) 55vw, 100vw"`; la del cliente con `srcset="…-390.webp 390w, …-780.webp 780w"` y `sizes` según su ancho en pantalla. Solo `<img>` del tablero en la portada: `fetchpriority="high"`, sin `loading="lazy"`. El resto, `loading="lazy"` (incluido el teléfono de la portada, que en celular está oculto y así no se descarga).

**Accesibilidad:**
- Botones y enlaces de acción con `min-h-[3rem]`; el enlace de texto «o pruébala directo» de la tarjeta también (`inline-flex min-h-[3rem] items-center`).
- Preguntas frecuentes con `<details>`/`<summary>` (funcionan sin JavaScript). Cada `<summary>`: `flex min-h-[3rem] cursor-pointer items-center justify-between`, anillo de foco `focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-accent-light`, y un indicador «+» que rota a «×» con `group-open:rotate-45` (el `<details>` lleva `group`). Se oculta el marcador nativo con `list-none [&::-webkit-details-marker]:hidden`.
- Enlaces de texto con anillo de foco: las mismas utilidades `focus-visible:*`.
- `alt` descriptivo en cada captura, que diga que son datos de ejemplo.

### 4.3 Contenido, en orden

1. **Portada (`#inicio`)**
   - Etiqueta: «App para talleres de desabolladura y pintura».
   - H1 (`sc-hero-titulo`): «Cada auto de tu taller, a la vista: **de la recepción al cobro**».
   - Subtítulo: «Recepción con fotos, avance por pieza en 3D, repuestos, avisos al cliente y cobranza a compañías de seguros, en una sola app.»
   - Botones: primario «Probar la demo» y ghost «Conversar con Sofía» (C5).
   - Línea pequeña: «Demo con datos ficticios · Sin registro · Funciona en el navegador».
   - Imagen: ventana con el tablero; desde `lg`, el teléfono con el portal del cliente superpuesto abajo a la izquierda.
2. **¿Te suena? (`#te-suena`)** — H2 «¿Te suena?». Cuatro tarjetas (`sc-card`) con el problema y, debajo, «Con la app:» y la respuesta:
   - «El cliente llama tres veces al día para saber cómo va su auto.» → «Lo ve él mismo, en 3D, con su patente y un código.»
   - «El repuesto que nadie pidió frena la entrega.» → «Cambiar una pieza crea el pedido del repuesto y frena la etapa hasta que llega.»
   - «Lo que aparece al desarmar se arregla sin que nadie lo apruebe.» → «El trabajo adicional vuelve a pedir la aprobación del cliente antes de seguir.»
   - «La compañía paga tarde y se te pasa cobrar.» → «Cobranza ordenada por urgencia, con el plazo de 30 días de cada factura a la vista.»
3. **Cómo funciona (`#como-funciona`)** — H2 «Cómo funciona». Cuatro pasos numerados:
   1. **Recepción**: foto del padrón o datos a mano, acta con los daños que ya traía y los objetos de valor con foto.
   2. **Presupuesto**: el cliente lo aprueba desde su celular.
   3. **Reparación**: el trabajador marca el avance por pieza y el tablero se mueve solo.
   4. **Entrega y cobro**: el aviso al cliente se escribe solo y el cobro separa deducible y compañía.
4. **Una app, tres miradas (`#tres-miradas`)** — H2 «Una app, tres miradas». Tres bloques con su captura:
   - **El trabajador** (trabajador): «Toca la pieza dañada en el auto 3D, marca su avance y sube fotos. Botones grandes y claros. No ve precios.»
   - **El administrador** (tablero): «Ve el taller completo y las alertas del día, fija cada monto y controla repuestos, costos y cobros.»
   - **El cliente** (cliente, en teléfono): «Entra con su patente y un código. Ve el avance, las fotos y aprueba su presupuesto.»
5. **Funciones (`#funciones`)** — H2 «Lo que antes dependía de la memoria, ahora queda registrado». Ocho tarjetas (título + una línea) y la captura de cobranza en ventana:
   Tablero que se mueve solo · Alertas del día · Repuestos automáticos · Fotos antes y después · Trabajos adicionales con aprobación · Avisos por WhatsApp listos para enviar · Cobranza a compañías · Costo por hora y reportes.
6. **Hecha a la medida de tu taller (`#a-medida`)** — H2 «Hecha a la medida de tu taller». «La adaptamos a tu forma de trabajar: tus etapas, las compañías con las que trabajas, tu logo y tus colores. Cada taller con sus datos separados.» Botón ghost «Conversar con Sofía».
7. **Preguntas frecuentes (`#preguntas`)** — H2 «Preguntas frecuentes». Seis `<details>`:
   - ¿Tengo que instalar algo? → «No. Funciona en el navegador del computador, la tablet o el celular.»
   - ¿Sirve si trabajo con compañías de seguros y con particulares? → «Sí. Separa lo que paga la compañía y el deducible del cliente, y lleva el plazo de cada factura.»
   - ¿Mis trabajadores ven los precios? → «No. Solo el administrador ve montos y valores.»
   - ¿Puedo usar mi logo y mis colores? → «Sí. Cada taller entra con su logo, su color y sus datos separados.»
   - ¿Qué pasa con lo que escribo en la demo? → «La demo usa datos ficticios y guarda todo solo en tu navegador. No ingreses datos reales.»
   - ¿Cuánto cuesta? → «Depende del tamaño de tu taller y de lo que haya que adaptar. Cuéntanos cómo trabajas y te armamos una propuesta.»
8. **Cierre (`#cierre`)** — H2 «Pruébala ahora, con datos de ejemplo», texto «Entra como administrador, trabajador o cliente. No necesitas registrarte.», botones «Probar la demo» y «Conversar con Sofía».
9. **Pie** — estructura de `index.html:747-787` con tres cambios: (a) el párrafo bajo el logo pasa a «Consultoría e implementación de automatización con IA para empresas en Chile.» (sin «riesgo cero»); (b) los enlaces a secciones de la portada pasan a absolutos (`/#servicios`, `/#como-trabajamos`, `/#antes-y-despues`); (c) en «Servicios» se suma «Desabolladura Premium» (`/desabolladura/`) como último elemento de la lista.
10. **Modal de Cal.com** — el de `index.html:789-797`, igual. Es el respaldo de `data-open-sofia` cuando el widget no cargó: `src/main.js:126-188` solo engancha los botones si existen `#scheduler-modal` y `#scheduler-frame`.

Ningún enlace de la página lleva `data-cta` (C7 ya lo garantiza; se omite para no dejar atributos sin efecto).

### 4.4 Funciones anunciadas y evidencia en la demo

| Lo que dice la página | Dónde está en `Workspace_Agencia/desabolladura` |
|---|---|
| Foto del padrón o datos a mano | `README.md` («ingresa el vehículo con foto del padrón o a mano»), `src/lib/padron.ts` |
| Acta con daños previos y objetos de valor con foto | commit `ee022e1` «acta de recepción con daños preexistentes y objetos de valor con foto» |
| Avance por pieza en 3D | `src/components/PiezaPicker.tsx`, `src/three/Viewer3D.tsx`; captura del trabajador |
| Tablero que se mueve solo, alertas del día | `src/pages/Landing.tsx:112-113`; captura del tablero («Para hoy») |
| Repuestos automáticos que frenan la etapa | `src/pages/Landing.tsx:114` |
| Fotos antes y después | `src/pages/Landing.tsx:115` |
| Trabajos adicionales con aprobación | `src/pages/Landing.tsx:116`, `src/lib/adicionales.ts` |
| Avisos por WhatsApp listos para enviar | `src/pages/Landing.tsx:117` |
| Cobro con deducible y compañía | `src/pages/Landing.tsx:194`; captura de cobranza («Deducibles por cobrar») |
| Facturas a compañías a 30 días, cobranza por urgencia | `src/pages/Landing.tsx:43`, `src/pages/Cobranza.tsx`; captura de cobranza |
| Costo por hora y reportes | `src/lib/costos.ts`, `src/lib/rentabilidad.ts`, ruta `admin/reportes` (`src/main.tsx:93`) |
| El trabajador no ve precios | `README.md` («No ve precios») |
| Portal del cliente con patente y código, aprueba presupuesto | `README.md`, `src/pages/Cliente.tsx`; captura del cliente («Tu presupuesto») |
| Logo, color y datos separados por taller | `src/pages/Landing.tsx:45`, `:218-219` |

### 4.5 Imágenes: cómo se obtienen

1. Capturas de la demo pública `https://taller.solucionesconia.cl/` (datos ficticios de la semilla vigente) con Chrome sin interfaz: `puppeteer-core` de `C:/Proyectos/tools/piper-ef/ef-demo/node_modules/puppeteer-core` y el ejecutable `C:/Proyectos/tools/piper-ef/ef-demo/node_modules/.remotion/chrome-headless-shell/win64/chrome-headless-shell-win64/chrome-headless-shell.exe` (los mismos que usa `tools/solucionesconia-video/scripts/grabar-demo.mjs`), con `--use-angle=swiftshader --enable-unsafe-swiftshader` para que WebGL dibuje el 3D sin GPU. El script vive fuera del repo (es una herramienta de una vez).
2. Escritorio: ventana 1280×800 con `deviceScaleFactor: 2`. Administrador (botón «Demo Administrador» de `#/entrar`): `#/admin` y `#/admin/cobranza`. Trabajador (botón «Demo Trabajador»): en `#/maestro`, la primera orden de la lista (en la semilla vigente, Nissan Qashqai DEMA-81, orden 1050), esperando 7 s a que cargue el 3D.
3. Celular: 390×844 con `deviceScaleFactor: 2`, `#/cliente/RIO4H7`.
4. Recorte (zona útil, para que el texto se lea en la columna de la portada): de las capturas de escritorio, el rectángulo superior izquierdo de 960×600 CSS (1920×1200 px reales). Variantes: 1920 px (2x) y 960 px (1x).
5. Conversión: `ffmpeg -c:v libwebp -preset text -quality 78`. Si una variante supera su tope (C10), se baja la calidad de 5 en 5 hasta 60; si aun así no entra, se reduce el recorte.
6. `og-20261125.jpg`: del tablero a 2x, recorte 2400×1260 desde arriba a la izquierda escalado a 1200×630, `-q:v 3`.
7. Las capturas muestran la franja «Demostración con datos ficticios» de la app: se deja a propósito.

### 4.6 Bloque de la tarjeta en `index.html`

Hoy (`index.html:668-673`): un `<a href="https://taller.solucionesconia.cl/" target="_blank" rel="noopener" data-cta="demo-desabolladura" aria-label="Ir a la demo de Desabolladura Premium (se abre en otra pestaña)" class="sc-btn-primary …">Ir <svg…#i-arrow/></a>` dentro de `<div class="mt-8 border-t border-white/[.06] pt-6">`.

Queda: el mismo `<div>`, ahora `flex flex-wrap items-center gap-x-5 gap-y-2`, con:
- `<a href="/desabolladura/" data-cta="demo-desabolladura" aria-label="Conocer la app Desabolladura Premium" class="(las mismas clases del botón actual)">Conocer la app <svg…#i-arrow/></a>` (se conserva `data-cta` tal cual estaba; el orquestador lo rechaza hoy porque no está en su lista cerrada, y eso no cambia).
- `<a href="https://taller.solucionesconia.cl/" target="_blank" rel="noopener" aria-label="Probar la demo de Desabolladura Premium (se abre en otra pestaña)" class="inline-flex min-h-[3rem] items-center text-sm font-semibold text-accent-light underline-offset-4 hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-accent-light">o pruébala directo</a>`.

### 4.7 Cambios en `deploy.sh`

(a) Línea 41: `PUBLICAR=(index.html robots.txt sitemap.xml acceso assets dist src privacidad desabolladura)`.

(b) Líneas 144-149 (versiones de CSS/JS): `v_css` y `v_js` se calculan igual. La sustitución pasa de `"${STAGE}/index.html"` a cada fichero de esta lista:
```bash
local con_marcador=()
mapfile -t con_marcador < <(grep -rlE '\$(CSS|JS)_VERSION' --include='*.html' "${STAGE}" || true)
[ "${#con_marcador[@]}" -gt 0 ] || { echo "ERROR: ningún .html con marcador de versión." >&2; exit 1; }
for f in "${con_marcador[@]}"; do
  sed -i -e "s/\$CSS_VERSION/${v_css}/g" -e "s/\$JS_VERSION/${v_js}/g" "${f}"
done
if grep -rqE '\$(CSS|JS)_VERSION' --include='*.html' "${STAGE}"; then
  echo "ERROR: queda un placeholder de versión sin sustituir." >&2; exit 1
fi
```
`grep -rl` sin coincidencias devuelve 1; el `|| true` dentro de la sustitución de proceso evita que `set -e`/`pipefail` aborte. `acceso/index.html` y `privacidad/index.html` no tienen marcador y no se tocan.

(c) Verificación por loopback: justo después del bloque de las líneas 196-203 (sha de `/`), se añade el mismo bloque para la página nueva:
```bash
  esperado="$(sha256sum < "${STAGE}/desabolladura/index.html" | cut -c1-64)"
  servido="$(curl -sk --max-time 10 -H "Host: ${DOMAIN}" https://127.0.0.1/desabolladura/ | sha256sum | cut -c1-64)" || servido="curl-fallido"
  if [ "${esperado}" != "${servido}" ]; then
    echo "ERROR: nginx no sirve el desabolladura/index.html recién publicado." >&2
    revertir; exit 1
  fi
```
La lista de rutas en 200 (línea 204) no cambia. El mensaje de la línea 212 pasa a «==> Loopback OK: index.html y desabolladura/ servidos = publicados; /, /acceso/, CSS y JS en 200».

## 5. Alternativas consideradas

| Alternativa | Por qué no |
|---|---|
| Convertir la portada de la app (`desabolladura/src/pages/Landing.tsx`) en la página de venta | Mezcla venta y demo bajo la marca «Taller Demo», y choca con el plano de producción de la app (`desabolladura/docs/specs/2026-11-11-produccion-fase1.md` §4.1): en producción la raíz `/` no muestra `Landing.tsx` |
| Solo cambiar el texto de la tarjeta Demos | No da al dueño del taller la explicación ni el camino de contacto |
| Página en otro dominio o en Cloudflare Pages | Otro despliegue que mantener; la landing ya tiene CSP, fuentes, widget y despliegue probado |
| Contar las visitas de la página con un evento nuevo del embudo | Exige cambiar la lista cerrada del orquestador (otro repo y otro despliegue) |
| Apagar solo `visita` y dejar los hitos del chat | Infla la tasa chat/visita de la portada; los revisores lo marcaron. Se apaga todo |

## 6. Ruta a producción

- **Push a `main`** del repo `solucionesconia`: **no despliega** (no hay CI).
- Producción solo cambia cuando alguien corre en el VPS `cd /opt/solucionesconia && bash deploy.sh --simular` y luego `bash deploy.sh` (`CLAUDE.md` del workspace, «Despliegue de la landing»). `deploy.sh` compila Tailwind en el VPS.
- **Antes de publicar (lista para el dueño):** (0) pasar los cambios a una rama desde `origin/main` (el árbol local está en `feat/politica-v7`, ver «Verificación»); (1) recorrer en `https://taller.solucionesconia.cl/` cada función de §4.4 y confirmar que sigue ahí; (2) revisar el diff completo de `index.html` (incluye cambios ajenos de SOL-209 en las líneas 486 y 489); (3) `deploy.sh --simular`; (4) tras publicar: `curl -sk -H 'Host: solucionesconia.cl' https://127.0.0.1/desabolladura/ | head -c 300` en el VPS, abrir la página en el celular, pulsar «Conversar con Sofía» y comprobar que abre el chat real.
- **En esta tarea no se hace ni commit ni push ni despliegue** (C14).

## 7. Seguridad y datos

- Mutaciones sin GET: la página no tiene endpoints ni formularios. N/A.
- Rate limit: N/A (estática). El widget de Sofía usa sus endpoints actuales con sus cotas.
- Datos personales: la página no pide ni guarda datos. El chat de Sofía es el mismo de la portada y está cubierto por la política de privacidad vigente (`privacidad/index.html`). La página no envía eventos al embudo (C7).
- CSP vigente de `solucionesconia.cl` (cabecera leída el 2026-11-25 con `curl -sI https://solucionesconia.cl/`): `script-src 'self' 'unsafe-inline' … https://admin.solucionesconia.cl …; style-src 'self' 'unsafe-inline' …; img-src 'self' data: https:; frame-src https://admin.solucionesconia.cl https://cal.com https://app.cal.com`. La página usa solo `'self'`, `admin.solucionesconia.cl` y `cal.com`. Cumple sin tocar nginx.
- Capturas: solo datos ficticios de la semilla (patentes «DEMA-…», RUT inválidos, «Compañía Demo …»).
- Regla de oro: sin razón social, RUT ni domicilio (C12).
- Secretos: ninguno.

## 8. Riesgos y rollback

| Riesgo | Mitigación |
|---|---|
| El cambio de `deploy.sh` rompe la publicación de la portada | Cambios acotados (§4.7); `bash -n`; prueba en seco bajo `set -Eeuo pipefail` con un `.html` sin marcador; el primer uso real es con `--simular` |
| La verificación de `/desabolladura/` pasa en falso si nginx devuelve la portada para rutas que no existen | Se compara el sha del fichero publicado, no solo el código 200 (§4.7 c) |
| Un fallo en `/desabolladura/` revierte toda la publicación | Es el comportamiento buscado: no se deja el web root a medias |
| `index.html` tiene cambios ajenos sin commit (líneas 486 y 489, SOL-209) | Se edita solo el bloque de §4.6; el criterio C6 lo comprueba con el diff |
| La portada invisible si el widget tarda | Sin `data-reveal` en `#inicio` (§4.2) |
| Capturas ilegibles o con el 3D en negro | Recorte de la zona útil a 2x y revisión a ojo (C10) |
| Imágenes viejas en caché del navegador (nginx: `max-age=2592000` en `/assets/`) | Nombres fechados (`-20261125`); una captura nueva lleva otra fecha |

**Rollback antes de publicar** (sin tocar los cambios ajenos de `index.html`): (1) devolver el bloque de §4.6 a su texto original con el editor, copiándolo de `git show HEAD:index.html` (líneas 668-673); (2) `git checkout -- src/main.js tailwind.config.js deploy.sh sitemap.xml`; (3) borrar `desabolladura/` y `assets/desabolladura/`. **No** usar `git checkout -- index.html`.
**Después de publicar:** `deploy.sh` respalda el web root en `/root/backups-solucionesconia/<fecha>/webroot.tgz`; se revierte el commit y se corre `deploy.sh --permitir-borrado`.

## 9. Plan de pruebas

Prueba de «cortado a la derecha» (C3, C4), en la consola del navegador:
```js
[...document.querySelectorAll('body *')].filter(e => { const r = e.getBoundingClientRect(); const s = getComputedStyle(e); return r.width > 0 && r.height > 0 && s.visibility !== 'hidden' && !e.closest('[aria-hidden="true"]') && r.right > innerWidth + 0.5; }).map(e => e.tagName + '.' + e.className)
```
Debe devolver `[]`.

| Criterio | Prueba |
|---|---|
| C1 | `npx -y serve . -l 5500` (configuración `static-site` de `.claude/launch.json`); abrir `http://localhost:5500/desabolladura/` y leer `document.title` |
| C2 | `[...document.querySelectorAll('section')].map(s => s.id)` = la lista de C2 |
| C3 | Navegador a 1280×552: captura de la portada sin scroll; prueba de «cortado a la derecha» |
| C4 | Navegador a 360×740, 375×812, 768×1024 y 1024×768: prueba de «cortado a la derecha»; en 360 y 375, captura sin scroll con los dos botones. Además, a 1280×960 (escala 1,2 de `src/input.css:454-456`): captura de la portada |
| C5 | (a)(b) `document.querySelectorAll('a[href^="https://taller."]')` y `a[data-open-sofia]` con sus atributos; (c) primero, con el widget cargado (`typeof window.SolucionesconiaVendedorIA?.open === 'function'`), clic en «Conversar con Sofía» → captura con el panel del chat abierto; después, recargar, ejecutar `window.SolucionesconiaVendedorIA = undefined` en la consola, clic en el mismo botón → `document.getElementById('scheduler-modal').hidden === false` |
| C6 | `git diff index.html`: solo el bloque de la tarjeta además de los cambios previos de las líneas 486 y 489 |
| C7 | Registro de red del navegador local: en `/desabolladura/` (carga, clic en botones, apertura del modal) ninguna petición a `/api/sales-agent/evento`; en `/` sí sale la de `visita` |
| C8 | (a) `grep -nE '^PUBLICAR=\(.*desabolladura' deploy.sh` devuelve la línea 41; (d) `grep -n 'https://127.0.0.1/desabolladura/' deploy.sh` y `grep -n 'STAGE}/desabolladura/index.html' deploy.sh` devuelven el bloque de §4.7 (c), situado antes del bucle `for ruta in` (comparar números de línea); `git diff deploy.sh` contiene solo los cambios de §4.7; `bash -n deploy.sh`; (b)(c) prueba en seco: script temporal con `set -Eeuo pipefail` que copia `index.html`, `desabolladura/index.html`, `acceso/index.html` y `privacidad/index.html` a un directorio temporal, ejecuta el bloque de §4.7 (b) dentro de una función (el bloque usa `local`) con `STAGE` apuntando al directorio temporal y `v_css=abc`, `v_js=def`, y comprueba con `grep` que no queda ningún marcador y que `acceso/` y `privacidad/` no cambiaron (`cmp`) |
| C9 | `npm run build`; `grep -F '\!scroll-mt-\[calc' dist/style.css`; navegador a 1280×552 y a 1920×1080: clic en «Funciones» del menú, esperar 1,5 s, evaluar `document.querySelector('#funciones h2').getBoundingClientRect().top >= document.querySelector('.sc-header').getBoundingClientRect().bottom` → `true`; lo mismo con «Preguntas» y `#preguntas h2` |
| C10 | `ls -la assets/desabolladura/`; `ffprobe` de `og-20261125.jpg`; revisar cada imagen a ojo; atributos de las `<img>` con `document.querySelectorAll('img')` |
| C11 | Consola del navegador local, solo errores; lista de recursos con `performance.getEntriesByType('resource').map(r => new URL(r.name).host)` |
| C12 | El `grep` de C12; revisión de la tabla §4.4 |
| C13 | `grep desabolladura sitemap.xml` y `node -e` con un parseo XML (o `python -c "import xml.dom.minidom,sys; xml.dom.minidom.parse('sitemap.xml')"`) |
| C14 | `git status` (cambios sin commit) y `git log origin/main..HEAD` vacío |

## Registro de revisión (Peces)

| Ronda | Pez | Severidad | Hallazgo (§) | Respuesta: aceptado / rechazado y por qué |
|---|---|---|---|---|
| 1 | Comprensión | — | §4.1 decía «7 secciones» y C2 pedía 8 | Aceptado: §4.2 y C2 fijan 8; C2 se prueba con la lista de `id` |
| 1 | Comprensión | — | No se decía si se conserva `data-cta` en la tarjeta | Aceptado: §4.6 lo conserva en el enlace principal; la página nueva no usa `data-cta` |
| 1 | Comprensión | — | `subject` del mailto sin fijar | Aceptado: C5 (b) lo fija |
| 1 | Comprensión | — | URL de `og:image` y canónica sin fijar | Aceptado: §4.2 «Metas», absolutas con `www` |
| 1 | Comprensión | — | `.sc-hero-col` heredada pero no listada | Aceptado: se añade a la lista de §4.2 |
| 1 | Comprensión | — | «La primera orden de `#/maestro`» ambigua | Aceptado: §4.5 paso 2 nombra la orden de la semilla vigente |
| 1 | Comprensión | — | Bloque de `deploy.sh` en 144-149, no 143-149 | Aceptado: §4.7 (b) |
| 1 | Comprensión | — | Rollback con `git checkout -- index.html` borraría cambios ajenos | Aceptado: §8 lo prohíbe y da el procedimiento |
| 1 | Comprensión | — | `grep -c` cuenta líneas | Aceptado: C2 se prueba en el navegador con la lista de `id` |
| 1 | Ana | IMPORTANTE | §4.3.9: el pie copiado trae «con un modelo de riesgo cero» (`index.html:754`) | Aceptado: §4.3.9 (a) cambia el párrafo; C12 suma `riesgo cero|no pagas|gratis|gratuit` |
| 1 | Ana | IMPORTANTE | §4.1 `deploy.sh`: verificar solo el 200 de `/desabolladura/` puede pasar en falso | Aceptado: §4.7 (c) compara el sha |
| 1 | Ana | IMPORTANTE | §4.5: el 3D puede salir negro en Chrome sin GPU; C10 no lo mira | Aceptado: flags de swiftshader en §4.5 paso 1 (probados el 2026-11-25: el auto se dibuja) y revisión a ojo en C10 |
| 1 | Ana | IMPORTANTE | §7/C7: los hitos del chat sin visitas descuadran el embudo | Aceptado: la guardia va en `contar` y apaga todo (§4.1 `src/main.js`, C7) |
| 1 | Ana | IMPORTANTE | §4.3/C5: nada prueba que «Conversar con Sofía» abra algo | Aceptado: C5 (c) prueba el modal en local; §6 deja la prueba del chat real para después de publicar (desde localhost el widget no responde). §3: el prompt de Sofía no cambia |
| 1 | Ana | MENOR | `grep -o 'id=…'` también devuelve ids del sprite | Aceptado: C2 usa `querySelectorAll('section')` |
| 1 | Ana | MENOR | Faltan viewports: escala 1,2, tablet, `<details>` con `data-reveal`, sitemap válido | Aceptado: C4 suma 360, 768, 1024 y 1280×960; §4.2 prohíbe `data-reveal` dentro de `<details>`; C13 valida el XML. La escala 1,4 (≥1800×1150) no se prueba: no hay pantalla de ese alto en el navegador de pruebas; queda anotado |
| 1 | Ana | MENOR | El bucle nuevo puede abortar con `set -e` si un `.html` no tiene marcador | Aceptado: §4.7 (b) con `|| true` en la sustitución de proceso; C8 lo prueba bajo `set -Eeuo pipefail` |
| 1 | Ana | MENOR | §8 rollback peligroso con `index.html` | Aceptado (ver Comprensión) |
| 1 | Ana | MENOR | §4.4 no se re-verifica en la demo viva antes de publicar | Aceptado: §6, lista para el dueño, paso (1) |
| 1 | Ramón | BLOQUEANTE | §4.2/C4: en 375 px la cabecera se corta (marca 194,6 px + botón 157 px) y `scrollWidth` no lo detecta por `overflow-x:hidden` (`src/input.css:55`) | Aceptado: debajo de 640 px la cabecera muestra solo la marca (§4.2 «Cabecera»); C3/C4 usan la prueba de «cortado a la derecha» de §9 y suman 360 px |
| 1 | Ramón | IMPORTANTE | `data-reveal` en la portada la deja invisible si el widget tarda (`DOMContentLoaded` espera al `defer`) | Aceptado: sin `data-reveal` en `#inicio` (§4.2) |
| 1 | Ramón | IMPORTANTE | Imágenes sin `srcset`, `fetchpriority` ambiguo, teléfono oculto que igual descarga | Aceptado: §4.2 «Imágenes responsive»; solo el tablero lleva `fetchpriority`; el teléfono `loading="lazy"` |
| 1 | Ramón | IMPORTANTE | Capturas de 1440×900 ilegibles en una columna de 471 px | Aceptado: captura a 1280×800 2x y recorte de 960×600 CSS (§4.5); imagen en `lg:col-span-7` (§4.2) |
| 1 | Ramón | MENOR | `og.jpg` sin calidad fija y WebP sin preset | Aceptado: `-q:v 3` y `-preset text` (§4.5) |
| 1 | Ramón | MENOR | Imágenes sin versión con caché de 30 días | Aceptado: nombres fechados (§4.1, C10) |
| 1 | Ramón | MENOR | AA: aviso de pestaña nueva, tamaño del enlace secundario y de `<summary>`, foco visible | Aceptado: C5 (a), §4.2 «Accesibilidad», §4.6 |
| 1 | Ramón | MENOR | Anclas bajo la cabecera fluida (barra hasta 7.5rem, `scroll-margin-top` 5.5rem) | Aceptado: utilidad `scroll-mt-[calc(var(--sc-barra,4.75rem)+1rem)]` por sección (§4.2) |
| 1 | Ramón | MENOR | C9 con `grep` de clases arbitrarias da falso negativo | Aceptado: C9 nombra la clase y usa la forma escapada |
| 1 | Ramón | MENOR | Embudo descuadrado por los hitos del chat | Aceptado (ver Ana) |
| 1 | Ramón | — | No se verificó si nginx redirige `/desabolladura` sin barra | Aceptado como prueba posterior a publicar: §6 paso (4). Todos los enlaces de la página y de la tarjeta usan `/desabolladura/` con barra |

| 2 | Go/No-Go | NO-GO | C5(c): en local el widget sí carga (bundle con `access-control-allow-origin: *`) y abre el chat, no el modal; C11 y §6 se contradecían | Aceptado: C5(c) prueba los dos caminos (chat con widget; modal con `window.SolucionesconiaVendedorIA = undefined`); C11 aclara que el bundle carga y la API rechaza localhost |
| 2 | Go/No-Go | NO-GO | §4.2/C9: `section[id]` (0,1,1) gana a la utilidad `scroll-mt-…` (0,1,0) | Aceptado: `!scroll-mt-…` (important) y C9 mide el valor efectivo con `getComputedStyle` |
| 2 | Go/No-Go | NO-GO | C8 (a) y (d) sin prueba ejecutable | Aceptado: §9 C8 suma `grep` de `PUBLICAR`, del bloque de loopback y revisión del diff; §4.7 (c) da el bloque exacto |
| 2 | Go/No-Go | MENOR | §4.2: sin relleno superior de la portada bajo 1024 px | Aceptado: §4.2 «Relleno de la portada» copia `pt-[6.25rem] sm:pt-28` de `index.html:236` |

| 3 | Go/No-Go | NO-GO | C9 no comprobable: rem = 18 px a 1920, `--sc-barra` sin resolver, cabecera compacta al bajar, `zoom` de `sc-escala` | Aceptado: C9 pasa a una prueba de comportamiento (el `<h2>` queda bajo la cabecera tras el clic en el menú), independiente de rem, zoom y estado de la cabecera |
| 3 | Go/No-Go | MENOR | Prueba en seco de C8: el bloque usa `local` | Aceptado: §9 C8 lo ejecuta dentro de una función con `STAGE`, `v_css` y `v_js` definidos |
| 3 | Go/No-Go | MENOR | Metas OG/Twitter sin texto | Aceptado: §4.2 «Metas» las fija |
| 3 | Go/No-Go | MENOR | Ruta de `chrome-headless-shell` | Aceptado: §4.5 paso 1 da la ruta completa |
| 3 | Go/No-Go | MENOR | Posición de «Desabolladura Premium» en el pie; qué secciones llevan `sc-escala` | Aceptado: §4.3.9 (c) y §4.2 «Secciones con `sc-escala`» |

Tras dos rondas de Go/No-Go con NO-GO, el flujo pide llevar la decisión al dueño (no se lanza un tercer Go/No-Go sin su OK). El único punto abierto era una prueba (C9), no el diseño; queda corregido en v4.

## Desvíos durante la implementación

- **Titular más corto:** «Cada auto, a la vista: de la recepción al cobro» (en vez de «Cada auto de tu taller, a la vista: …»), para que titular, subtítulo y botones quepan en 1280×552 con la columna de texto de 5/12.
- **Capturas sin recorte (pedido del dueño tras revisar, 25-nov 17:02):** los recortes de 960×600 CSS dejaban la app cortada a la derecha. Todas las capturas de escritorio pasan a ser la **pantalla completa** de la app a 1440×900 CSS (2x), escaladas a 1920×1200 y 960×600: `tablero` (portada), `trabajador`, `ordenes` y `cobranza`.
- **Imagen nueva `ordenes-20261125-{960,1920}.webp`** (pantalla «Órdenes»): la usa el bloque «El administrador» de `#tres-miradas` para no repetir la imagen de la portada. Coincide con el texto («fija cada monto»).
- **Teléfono de la portada** abajo a la **derecha** de la ventana (`-right-3`), no a la izquierda: a la izquierda se montaba sobre la columna de texto en 1280×960.
- **Textos menores añadidos:** etiqueta y frase de entrada en cada sección (p. ej. «El día a día del taller» / «Lo que se pierde entre la libreta, el WhatsApp y la memoria de cada uno.»), un subtítulo `<h3>` en cada bloque de `#tres-miradas` y una línea por tarjeta en `#funciones`. Ninguno anuncia funciones fuera de §4.4.
- **El recorte del tablero (portada y `og`) no muestra la franja «Demostración con datos ficticios»** de la app (§4.5.7): el `alt` de la imagen y la línea pequeña de la portada lo dicen. La tarjeta «Toyota Corolla» usa la foto de la semilla de la demo, creada con Gemini (commit `8e70e13` de `desabolladura`), no una foto ajena.
- **Modal:** `aria-label` «Agenda una conversación» (en la portada dice «Agenda tu auditoría»).
- **Logo de la cabecera sin `loading="lazy"`:** está en la primera pantalla; C10 se entiende para las capturas.
- **Retoques:** `aria-current="page"` en el enlace del pie, `og:image:width/height`, «lo revisa y lo aprueba» en el paso 2.
- **Efecto en `/`:** `dist/style.css` suma las clases de la página nueva y cambia su hash, así que el CSS de la portada también se vuelve a descargar una vez. Las reglas `#inicio` de pantallas altas (`src/input.css:414-445`) también se aplican aquí (solo el `gap` de `.sc-hero-col`).
- **Herramienta local:** se creó `C:\Proyectos\.claude\launch.json` (configuración `landing-solucionesconia`) para la vista previa; el `launch.json` del repo no lo lee el panel de vista previa del escritorio.

## Verificación (2026-11-25, local, sin publicar)

| Criterio | Evidencia | Estado |
|---|---|---|
| C1 | `document.title` correcto en `http://localhost:5500/desabolladura/` | ✅ |
| C2 | `section` ids: inicio, te-suena, como-funciona, tres-miradas, funciones, a-medida, preguntas, cierre | ✅ |
| C3 | 1280×552: titular termina en y=266, botones en y=438 (alto 552); prueba de cortados `[]` | ✅ |
| C4 | Cortados `[]` en 360×740, 375×812, 768×1024, 1024×768, 1280×960 y 1920×1080; botones en y=453/523 (360 y 375) | ✅ |
| C5 | 3 enlaces a la demo con `_blank`, `noopener` y aviso de pestaña; 3 «Conversar con Sofía» con el `mailto` fijado; clic con widget → chat abierto (captura); con `SolucionesconiaVendedorIA = undefined` → modal visible con iframe | ✅ |
| C6 | Tarjeta: «Conocer la app» → `/desabolladura/` (misma pestaña), «o pruébala directo» → demo (`_blank`, 48 px de alto) | ✅ |
| C7 | `/desabolladura/`: 0 peticiones a `sales-agent/evento` (carga, clics, modal); `/`: 1 (visita) | ✅ |
| C8 | `bash -n` OK; `PUBLICAR` en línea 41; bloque de sha en líneas 215-220, antes del `for ruta` (221); prueba en seco bajo `set -Eeuo pipefail` OK (marcadores sustituidos en las dos páginas; `acceso/` y `privacidad/` intactos) | ✅ (no ejecutado en el VPS) |
| C9 | `\!scroll-mt-\[calc` presente en `dist/style.css`; clic en menú → h2 bajo la cabecera en 1280×552 (220/188 vs 77) y 1920×1080 (330/287 vs 86) | ✅ |
| C10 | WebP 1x ≤ 48 KB, 2x ≤ 116 KB; `og-20261125.jpg` 1200×630; solo el tablero con `fetchpriority="high"`; 3D dibujado en todas las capturas (revisión a ojo) | ✅ |
| C11 | Recursos solo de `localhost` y `admin.solucionesconia.cl`; en `/desabolladura/` sin errores propios (el error CORS de `sales-agent/evento` es de la visita a `/`) | ✅ |
| C12 | `grep` de razón social, RUT, domicilio, «riesgo cero», «no pagas», «gratis», «gratuit»: 0 | ✅ |
| C13 | `sitemap.xml` con la URL y XML válido (`xml.dom.minidom`) | ✅ |
| C14 | Sin commit ni push ni `deploy.sh` | ✅ |

**Rama (hallazgo del Pez verificador):** el árbol de trabajo está en `feat/politica-v7`, una rama ya fusionada a `main` por squash (`22634ef`), no en `main`. `deploy.sh` exige `HEAD = origin/main`. Para publicar: crear una rama desde `origin/main`, llevar allí solo los ficheros de este plano (staging por ruta) y fusionar a `main`. C14 se cumple (no hay commits nuevos), pero la prueba `git log origin/main..HEAD` no aplica en esta rama.

No verificado: escala 1,4 (≥1800×1150), el chat real de Sofía en producción y `/desabolladura` sin barra detrás de nginx (quedan en §6, paso 4, tras publicar).

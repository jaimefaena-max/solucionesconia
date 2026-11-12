---
titulo: Escala fluida de la cabecera y de la portada en escritorio (1024–2560 px)
fecha: 2026-11-12
repo: Workspace_Agencia/Agencia_Solucionesconia (GitHub: solucionesconia)
tamano: normal
estado: implementado
version: 3 (tras la prueba real de Jaime: pantallas bajas)
sha: <se rellena al implementar>
linear: <por crear en P-SOL-3>
---

# Escala fluida de la cabecera y de la portada en escritorio

## 1. Problema y para quién

Los visitantes de escritorio con el notebook más común (pantalla 1920×1080 con la escala de Windows al
150 %, o 1366×768 al 100 %) ven la landing con un área útil de unos **1280–1366 × 650 px CSS** con el zoom
de Chrome al 100 %. En ese tamaño la cabecera mide 120 px, el título de la portada ocupa 4 líneas de 72 px,
dos enlaces del menú se parten en dos líneas y el botón principal «Agendar auditoría» queda **debajo del
borde de la pantalla**. La composición solo se ve equilibrada en pantallas de 2560×1300 o más, porque los
tamaños crecen por saltos fijos (`@media (min-width: 1280px)`) en vez de crecer con la pantalla.
Además, entre 1024 y 1099 px la página se desplaza 12–27 px en horizontal: el único elemento visible que
desborda es el correo del pie (`index.html:768`); los otros dos que miden más que la ventana son brillos
decorativos `pointer-events-none` recortados por su sección.

Medición real del estado actual (servidor local, Chrome, zoom 100 %, script de §9). «CTA» = fondo del
botón «Agendar auditoría» de la portada; ✗ = fuera de la ventana.

| Ventana CSS | Título (px · líneas) | Barra | Nombre de marca | Ícono | Enlaces partidos | CTA | Desplazamiento horizontal |
|---|---|---|---|---|---|---|---|
| 1024×650 | 64 · 5 | 108 | 32 | 80 | 2 | 869 ✗ | 27 px |
| 1099×650 | 64 · 5 | 108 | 32 | 80 | 2 | 869 ✗ | 12 px |
| 1279×650 | 64 · 4 | 108 | 32 | 80 | 0 | 776 ✗ | 0 |
| 1280×650 | 72 · 4 | 120 | 42 | 101 | 2 | 834 ✗ | 0 |
| 1366×650 | 73,2 · 4 | 122 | 42,7 | — | 0 | 848 ✗ | 0 |
| 1536×730 | 75,6 · 4 | 126 | 44,1 | — | 0 | 875 ✗ | 0 |
| 1920×950 | 81 · 3 | 135 | 47,25 | — | 0 | 797 ✓ | 0 |
| 2560×1300 | 90 · 2 | 150 | 52,5 | 126 | 0 | 1067 ✓ | 0 |
| 768×1024 | 56 · 3 | 96 | 30 | 72 | (menú oculto) | 652 ✓ | 0 |
| 390×780 | 34 · 4 | 76 | 17 | — | (menú oculto) | 545 ✓ | 0 |

La fila 2560×1300 es la **referencia visual aprobada**: la composición que debe conservarse,
proporcionalmente, en todos los anchos de escritorio.

**Altura real (ronda 2).** Jaime probó la v2 en su notebook al 100 % y el CTA seguía fuera de la pantalla.
La v2 suponía 650 px de alto, pero Chrome con la barra de marcadores, en 1920×1080 al 150 %, deja
**1280×552** (medido en su captura: 828 px físicos ÷ 1,5). A 1280×552 con la v2: margen superior 108,
etiqueta 34, título 95, garantía 210, CTA de 518 a 574 (fuera), fila de confianza hasta 645 y foto de solo
184 px, porque su regla (`calc(100svh - 23rem)`) descuenta la barra vieja de 7,5 rem.

## 2. Criterios de aceptación

Todas las medidas con el script de §9, en Chrome, zoom 100 %, página recién cargada y sin desplazar.
«CTA visible» = `bottom` del enlace de la portada (`#inicio`) cuyo texto contiene «Agendar» ≤ alto de la
ventana. «Enlace partido» = enlace visible de `nav[aria-label="Principal"]` cuya altura supera 1,9 veces su
tamaño de letra. «Sin desplazamiento horizontal» = tras `scrollTo(200, 0)`, `scrollX` es 0.
**Matriz de escritorio**: 1024×650, 1024×768, 1099×650, 1100×650, 1180×820, 1279×650, 1280×650, 1366×650,
1535×730, 1536×730, 1920×950 y 2560×1300.

- [ ] C1 — En **toda la matriz de escritorio**: 0 enlaces partidos, la barra no desborda
      (`.sc-header__barra`: `scrollWidth ≤ clientWidth`) y sin desplazamiento horizontal.
- [ ] C2 — En **toda la matriz de escritorio**: título ≤ 3 líneas y CTA visible.
- [ ] C3 — A **2560×1300** (referencia) no hay regresión: título 90 ± 3 px, barra 150 ± 5 px, nombre de
      marca 52,5 ± 2 px, ícono 126 ± 4 px y CTA ≤ 1070.
- [ ] C4 — A **768×1024** y **390×780** (sin menú de escritorio) el título, la barra, el nombre de marca,
      el ícono y el CTA son idénticos a §1, y sin desplazamiento horizontal.
- [ ] C5 — Barra compacta: a **1920×950** y **2560×1300**, tras `scrollTo(0, 400)` y 600 ms, la barra tiene
      `is-compacto` y su altura es **menor** que sin desplazar; a **1280×650**, tiene `is-compacto` y 0
      enlaces partidos (ahí la altura normal ya está en el mínimo, igual a la compacta: §4.3).
- [ ] C6 — `npm run build` termina sin error. (`npm test` solo valida la plantilla de nginx; se corre para
      descartar roturas, no prueba este cambio.)
- [ ] C7 — Jaime aprueba el resultado en **su propio Chrome al 100 %** (1280×552) y las capturas antes/después
      a 1024×768, 1920×950 y 2560×1300. Hasta entonces **no se publica** (ver §6).
- [ ] C8 — **Matriz de pantallas bajas** (1024×552, 1100×552, 1280×552, 1366×600 y 1536×714): CTA visible,
      0 enlaces partidos y sin desplazamiento horizontal. Además, en 1280×552, 1366×600 y 1536×714, la fila
      de confianza (`.sc-hero-confianza`) y la tarjeta de la foto terminan dentro de la ventana. En
      1024–1279 × 552 la fila de confianza puede quedar hasta 8 px por debajo (medido: 556 de 552); se
      acepta porque el CTA es lo que debe verse.
- [ ] C9 — Con ≤ 620 px de alto (y ≥ 1024 de ancho) el párrafo `.sc-garantia__texto` está oculto; con
      más de 620 px, visible.

## 3. Alcance

- Entra:
  - Cabecera desde 1024 px: alto de la barra, ícono y nombre de la marca y letra del menú, fluidos.
  - Menú: los enlaces no se parten (`white-space: nowrap`); «Antes y después» se oculta entre 1024 y
    1279 px.
  - Portada desde 1024 px: tamaño del título `h1` y margen superior de `#inicio`, ambos fluidos. El margen
    queda atado al alto de la barra.
  - Correo del pie: puede cortarse para no desbordar.
  - Cambio **intencional** en tablets apaisadas (1024×768, 1180×820): entran en el tramo de escritorio y
    reciben la cabecera y el título nuevos (están en la matriz y en C7).
  - **Pantallas bajas** (≥ 1024 de ancho y ≤ 700 de alto): margen superior, espacio entre bloques,
    garantía (relleno, título y párrafo) y alto de la foto más ajustados. Con ≤ 620 de alto el párrafo
    de la garantía se oculta y queda su sello y su frase, igual que ya ocurre en celular
    (`hidden sm:block`).
  - La regla de alto de la foto para ≥ 1280 × ≤ 799 descuenta la barra fluida en vez de 23 rem fijos.
- No entra:
  - Por debajo de 1024 px: nada cambia (C4).
  - Textos, colores, imágenes, orden de secciones.
  - Escalado de las secciones inferiores (`.sc-escala`, `--sc-escala`) y los tramos de la portada para
    pantallas altas (`@media (min-width: 1280px) and (min-height: 960px)` y `1800px / 1150px`).
  - El tamaño base de letra (`html { font-size: clamp(16px, calc(0.3125vw + 12px), 20px) }`).
  - Pruebas automatizadas con Playwright (el repo no tiene infraestructura de pruebas; §5).
  - Publicar en producción (requiere C7 y un `deploy.sh` manual, §6).

## 4. Diseño técnico

### 4.1 Ficheros

| Ruta | Nuevo / cambia | Qué cambia | Por qué |
|---|---|---|---|
| `src/input.css` | cambia | Se sustituyen los bloques `@media (min-width: 1024px)` y `@media (min-width: 1280px)` que fijan `.sc-header__barra`, `.sc-marca__icono` y `.sc-marca__nombre` (hoy líneas 358–371, comentario «Marca +40 % en escritorio…») por el bloque de §4.2, y se añade la regla `.sc-nav`. Justo **después** de la regla existente `@media (min-width: 1280px) and (max-height: 799px)` de `#inicio .sc-foto-caja` (cuyo `calc(100svh - 23rem)` pasa a `calc(100svh - var(--sc-barra) - 13rem)`) se añaden los bloques de pantallas bajas de §4.2. | Tamaños que crecen con la pantalla y una portada que cabe en notebooks de poca altura. |
| `index.html` | cambia | (a) `<section id="inicio">` (hoy línea 263): se quitan `lg:pt-32` y `xl:pt-[9.5rem]`; el margen superior desde 1024 px lo pone §4.2. (b) `<nav aria-label="Principal">` (hoy línea 238): se quitan `text-sm` y `min-[1280px]:text-[1.05rem]`; se añaden `sc-nav` y `whitespace-nowrap`. (c) Enlace `href="#antes-y-despues"` del menú (hoy línea 241): se añaden `hidden xl:inline`. (d) `<h1>` de la portada (hoy línea 282): se quitan `lg:text-[4rem]` y `xl:text-[4.5rem]`; se añade `sc-hero-titulo`. (e) Pie, lista «Contacto», línea 768: al `<li>` se añade `min-w-0` y al `<a href="mailto:contacto@solucionesconia.cl" …>` se añaden `min-w-0` y `[overflow-wrap:anywhere]`. | Menú sin cortes, portada que cabe y fin del desplazamiento horizontal. |
| `docs/specs/2026-11-12-escala-fluida-escritorio.md` | nuevo | Este plano. | Flujo de ingeniería. |

`dist/style.css` **no** se versiona (está en `.gitignore`); se regenera con `npm run build`.

### 4.2 Reglas CSS exactas

Los factores se derivan de la referencia 2560×1300 (§1): `factor_vw = medida_px / 2560 × 100` y
`factor_vh = medida_px / 1300 × 100`, redondeados (p. ej. título: 90 / 2560 × 100 ≈ 3,5 vw y
90 / 1300 × 100 ≈ 6,9 vh). Cada tamaño toma el menor de los dos, así que se limita por la dimensión que
antes se agota (en notebooks, el alto). El máximo en `rem` es el valor actual a ≥ 1280 px, que a 2560 px
(raíz 20 px) da exactamente la referencia; el mínimo protege la legibilidad.

```css
/* Cabecera y portada fluidas en escritorio: crecen con ancho y alto en la proporción de 2560×1300. */
@media (min-width: 1024px) {
  :root { --sc-barra: clamp(4.75rem, min(5.9vw, 11.5vh), 7.5rem); }
  .sc-header__barra { height: var(--sc-barra); }
  .sc-marca__icono  { height: clamp(3.25rem, min(4.9vw, 9.7vh), 6.3rem); }
  .sc-marca__nombre { font-size: clamp(1.5rem, min(2.05vw, 4.05vh), 2.625rem); }
  /* La cabecera es fixed: el contenido de la portada empieza bajo la barra + 2 rem. */
  #inicio { padding-top: calc(var(--sc-barra) + 2rem); }
  #inicio .sc-hero-titulo { font-size: clamp(2.75rem, min(3.5vw, 6.9vh), 4.5rem); }
}

/* Menú: solo se ve desde 1024 px (`hidden lg:flex`), así que no necesita media query. */
.sc-nav { font-size: clamp(0.9375rem, 0.82vw, 1.3125rem); }
```

Pantallas bajas (van después de la regla de la foto, para ganarle por orden donde coinciden):

```css
/* Pantallas bajas de escritorio: 1920×1080 al 150 % con barra de marcadores deja ≈ 1280×552. */
@media (min-width: 1024px) and (max-height: 700px) {
  #inicio { padding-top: calc(var(--sc-barra) + 1rem); }
  #inicio .sc-hero-col { gap: 1rem; }
  #inicio .sc-garantia { padding: 1rem; }
  #inicio .sc-garantia__titulo { font-size: 1.125rem; }
  #inicio .sc-garantia__texto { margin-top: 0.375rem; font-size: 0.875rem; line-height: 1.45; }
  #inicio .sc-foto-caja { aspect-ratio: auto; height: min(64svh, calc(100svh - var(--sc-barra) - 13rem)); }
}

/* Aún más bajas: queda el sello y la frase de la garantía; el párrafo se oculta, como en celular. */
@media (min-width: 1024px) and (max-height: 620px) {
  #inicio .sc-garantia__texto { display: none; }
}
```

Especificidad de estos bloques: `#inicio …` (id + clase) gana a las utilidades del marcado
(`gap-5 sm:gap-6` en `.sc-hero-col`, `lg:p-5` en `.sc-garantia`, `lg:text-xl` en el título,
`hidden sm:block lg:text-[0.9375rem]` en el párrafo, `aspect-[4/5] min-[1100px]:aspect-auto
min-[1100px]:h-[…]` en la foto). `#inicio { padding-top }` coincide en especificidad con la regla del
bloque ≥ 1024 y gana por ir después. Los tramos de pantallas altas (`min-height: 960px` y `1150px`) no se
solapan con `max-height: 700px`.

Comprobación del margen superior: a 2560×1300, `149,5 + 2 × 20 = 189,5` px frente a los 190 actuales
(`xl:pt-[9.5rem]`), sin regresión.

Valores **medidos** con estas reglas (simulación en vivo de §9, inyectando las reglas en la página):

| Ventana | Raíz | Título (px · líneas) | Barra | CTA |
|---|---|---|---|---|
| 1024×650 | 16 | 44 · 3 | 76 | 646 ✓ |
| 1024×768 | 16 | 44 · 3 | 76 | 646 ✓ |
| 1099×650 | 16 | 44 · 3 | 76 | 646 ✓ |
| 1100×650 | 16 | 44 · 3 | 76 | 622 ✓ |
| 1180×820 | 16 | 44 · 3 | 76 | 637 ✓ |
| 1279×650 | 16 | 44,8 · 3 | 76 | 624 ✓ |
| 1280×650 | 16 | 44,8 · 3 | 76 | 624 ✓ |
| 1366×650 | 16,27 | 44,9 · 2 | 77 | 584 ✓ |
| 1535×730 / 1536×730 | 16,8 | 50,4 · 2 | 84 | 615 ✓ |
| 1920×950 | 18 | 65,5 · 2 | 109 | 719 ✓ |
| 2560×1300 | 20 | 89,6 · 2 | 150 | 1066 ✓ |
| 768×1024 y 390×780 | — | sin cambios respecto de §1 | | |

En toda la matriz: 0 enlaces partidos, barra sin desborde y `scrollX` = 0. La raíz es la de
`html { font-size: clamp(16px, calc(0.3125vw + 12px), 20px) }` (`src/input.css:40`).

Especificidad:
- Las reglas de barra compacta existentes (`.sc-header.is-compacto .sc-header__barra`, `…__icono`,
  `…__nombre`, dentro de `@media (min-width: 640px)`, `src/input.css:332–334`) tienen más especificidad que
  las nuevas y siguen mandando al desplazar: 4,75 rem / 3,25 rem / 1,5 rem.
- `#inicio` (id) gana a `pt-[6.25rem]` y `sm:pt-28`, que siguen rigiendo por debajo de 1024 px.
- `#inicio .sc-hero-titulo` (id + clase) gana a `text-[2.125rem]` y `sm:text-[3.5rem]` del `h1`, que
  Tailwind emite al final de la hoja. Es el recurso que ya usa el fichero con `#inicio .sc-garantia__titulo`.
- `.sc-nav` no compite con ninguna utilidad de tamaño de letra, porque se quitan `text-sm` y
  `min-[1280px]:text-[1.05rem]` del `<nav>`.
- Las transiciones existentes de `height` y `font-size` interpolan entre valores calculados, sea cual sea
  la expresión (`clamp()` y `var()` incluidos); C5 lo comprueba.

Valores **medidos** de la v3 en pantallas bajas (simulación en vivo; «conf» = fondo de la fila de
confianza, «tarjeta» = fondo de la tarjeta de la foto):

| Ventana | Título | CTA | conf | Foto (alto) | tarjeta | Párrafo |
|---|---|---|---|---|---|---|
| 1280×552 | 44 · 2 | 445 ✓ | 508 ✓ | 268 (antes 184) | 482 ✓ | oculto |
| 1366×600 | 44,7 · 2 | 453 ✓ | 517 ✓ | 311 | 509 ✓ | oculto |
| 1536×714 | 49,3 · 2 | 610 ✓ | 655 ✓ | 413 | 642 ✓ | visible |
| 1024×552 | 44 · 3 | 493 ✓ | 556 (4 px fuera) | 268 | 506 ✓ | oculto |
| 1100×552 | 44 · 3 | 493 ✓ | 556 (4 px fuera) | 268 | 506 ✓ | oculto |
| 1280×650 | 44,8 · 3 | 562 ✓ | 625 ✓ | 366 | 589 ✓ | visible |
| 1024×650 | 44 · 3 | 580 ✓ | 643 ✓ | 366 | 598 ✓ | visible |

Con más de 700 px de alto la v3 no cambia nada respecto de la v2 (1536×730, 1920×950, 2560×1300 y tablets
medidos de nuevo: mismos valores, salvo la foto a ≥ 1280 × ≤ 799, que ahora descuenta la barra fluida).

### 4.3 Flujo

1. El visitante abre la página; el navegador calcula `vw` y `vh` de su ventana.
2. Desde 1024 px de ancho, la barra, la marca y el título toman el menor de dos valores, uno proporcional
   al ancho y otro al alto, acotado por un mínimo legible y por el máximo actual. El contenido de la
   portada empieza 2 rem bajo la barra.
3. El menú usa `white-space: nowrap`. Entre 1024 y 1279 px muestra 2 enlaces («Cómo trabajamos»,
   «Servicios»); desde 1280 px, 3; desde 1536 px, 4 (igual que hoy). El orden no cambia. «Antes y
   después» sigue en la página (`#antes-y-despues`) y en el pie (`index.html:760`).
4. La letra del menú queda en su mínimo (15 px) hasta ~1830 px de ancho y crece desde ahí hasta 21 px a
   2560 px.
5. Al desplazar, la clase `is-compacto` reduce la barra a sus tamaños compactos. Entre 1024 y ~1290 px
   (con alto de 650) la barra normal ya está en su mínimo, igual al compacto: ahí solo cambia el fondo.
   Efecto esperado.
6. Por debajo de 1024 px nada cambia.

## 5. Alternativas consideradas

| Alternativa | Por qué no |
|---|---|
| Bajar los valores fijos de los saltos en 1280 px | Arregla 1280 y vuelve a desajustar 1920 y 2560; es el mismo problema con otros números. |
| `zoom` o `transform: scale()` de toda la portada según el ancho | Afecta la nitidez del texto, el foco y las medidas de JavaScript; hace del escalado un caso especial. |
| Fluido solo por ancho (`vw`), sin `vh` | En notebooks de 650 px de alto el título seguiría empujando el CTA (1366×650: 47,8 px por ancho frente a 44,9 por alto). |
| Plano v1: barra y título fluidos sin tocar el margen superior de `#inicio` | Medido: el CTA queda en 668 px a 1280×650 y 666 a 1024×650, fuera de la ventana. |
| Compactar la garantía y los espacios de la portada en pantallas bajas | Innecesario: con el margen atado a la barra, el CTA entra en toda la matriz. Más superficie de cambio. |
| Ocultar el botón «Portal Clientes» de la barra entre 1024 y 1279 px | Es el acceso de clientes activos; un enlace de navegación interna pesa menos. |
| Fila de confianza en una sola línea en pantallas bajas | No cabe: los 3 textos en letra monoespaciada suman ≈ 680 px y la columna mide ≈ 560 a 1280 px (medido). |
| Escalar toda la portada en proporción, como el zoom al 67 % | El párrafo de la garantía bajaría a ≈ 12 px a 1280×552: ilegible. |
| Mantener el párrafo de la garantía visible siempre | A 1280×552 la fila de confianza termina en 575, fuera de la ventana (medido). |
| Pruebas Playwright con la matriz | El repo no tiene infraestructura de pruebas; añadir dependencia y CI excede este cambio. El script de §9 es repetible a mano. |

## 6. Ruta a producción

- **Sin CI**: este repo no tiene `.github/workflows/`. Un push a `main` **no publica nada**.
- Publicar = `deploy.sh` a mano en el VPS (`ssh -i ~/.ssh/elrincon_deploy root@89.117.50.242`,
  `cd /opt/solucionesconia`, primero `bash deploy.sh --simular`, luego `bash deploy.sh`). El script compila
  el CSS (`npm ci` + `npm run build`), publica la lista blanca, respalda el web root, verifica por loopback
  y purga en Cloudflare solo las URL cambiadas.
- Este plano termina en local; el despliegue se hace solo tras C7.

## 7. Seguridad y datos

- Mutaciones sin GET: no aplica (solo CSS y marcado; ningún endpoint).
- Rate limit: no aplica.
- Datos personales / salud: ninguno.
- Secretos: ninguno. La clase arbitraria `[overflow-wrap:anywhere]` se compila a `dist/style.css`; no se
  añaden estilos en línea (la CSP no cambia).

## 8. Riesgos y rollback

| Riesgo | Mitigación |
|---|---|
| Unidades `vh` en navegadores móviles cambian con la barra de direcciones | Solo se usan desde 1024 px de ancho; C4 comprueba que celular y tablet vertical no cambian. |
| Accesibilidad: un tamaño en `vw`/`vh` no crece con el zoom «solo texto» (Firefox o del sistema) | Con el zoom normal del navegador el ancho CSS baja y, por debajo de 1024 px, rigen las reglas actuales en `rem`; los mínimos en `rem` crecen con la letra base. El zoom «solo texto» queda acotado al mínimo en `rem`: compromiso aceptado. |
| Margen estrecho del CTA a 1024×650 (646 de 650) | Medido en la simulación; si en la verificación real falla, bajar el `+ 2rem` del margen a `+ 1.5rem` (8 px más de holgura) y anotarlo en Desvíos. |
| Desbordar la barra en algún ancho entre 1024 y 1535 | C1 mide los bordes de cada tramo: 1024, 1099/1100 (cambia el relleno lateral), 1279/1280 (vuelve el 3.er enlace) y 1535/1536 (vuelve «Portal Clientes» al menú). |
| Ocultar el párrafo de la garantía con `display: none` (≤ 620 de alto) lo quita también del árbol de accesibilidad | La promesa sigue en el título de la garantía; es el mismo criterio que ya usa el celular (`hidden sm:block`); con más alto, o con zoom, reaparece. |
| Que la barra compacta deje de notarse | C5 lo exige en 1920 y 2560; en el tramo mínimo es efecto esperado (§4.3). |

Rollback: `git revert <sha>` y, si ya se publicó, `bash deploy.sh` de nuevo; o restaurar
`/root/backups-solucionesconia/<fecha>/webroot.tgz`, que `deploy.sh` crea antes de publicar.
Sha de partida: `1dea391`.

## 9. Plan de pruebas

Servidor local: `npm run build` y `python -m http.server 8099 --bind 127.0.0.1` en la raíz del repo; abrir
`http://127.0.0.1:8099/` en Chrome con la ventana emulada en cada tamaño y ejecutar en la consola:

```js
await new Promise(r => setTimeout(r, 700)); scrollTo(0, 0);
(() => {
  const h1 = document.querySelector('#inicio h1'), cs = getComputedStyle(h1);
  const nav = [...document.querySelectorAll('nav[aria-label="Principal"] a')].filter(a => a.offsetParent);
  const cta = [...document.querySelectorAll('#inicio a')].find(a => /Agendar/.test(a.textContent));
  const barra = document.querySelector('.sc-header__barra');
  scrollTo(200, 0); const sx = scrollX; scrollTo(0, 0);
  return {
    ventana: innerWidth + 'x' + innerHeight,
    titulo: cs.fontSize, lineas: Math.round(h1.getBoundingClientRect().height / parseFloat(cs.lineHeight)),
    barra: Math.round(barra.getBoundingClientRect().height), barraDesborda: barra.scrollWidth > barra.clientWidth,
    nombre: getComputedStyle(document.querySelector('.sc-marca__nombre')).fontSize,
    icono: Math.round(document.querySelector('.sc-marca__icono').getBoundingClientRect().height),
    partidos: nav.filter(a => a.getBoundingClientRect().height > parseFloat(getComputedStyle(a).fontSize) * 1.9).length,
    ctaFondo: Math.round(cta.getBoundingClientRect().bottom), ctaVisible: cta.getBoundingClientRect().bottom <= innerHeight,
    scrollX: sx,
  };
})()
```

Causa del desplazamiento horizontal (antes y después, a 1024×650):
`[...document.querySelectorAll('body *')].filter(e => e.getBoundingClientRect().right > innerWidth + 1).map(e => e.tagName + '.' + [...e.classList].join('.'))`.
Antes: el enlace del correo del pie y dos brillos `pointer-events-none`; después: solo los brillos, que
no producen desplazamiento (`scrollX` = 0).

Barra compacta (C5): `scrollTo(0, 400)`, esperar 600 ms y leer
`document.querySelector('.sc-header').classList.contains('is-compacto')`, la altura de `.sc-header__barra`
y `partidos`.

| Criterio | Prueba |
|---|---|
| C1, C2 | Script en los 12 tamaños de la matriz de escritorio. |
| C3 | Script a 2560×1300. |
| C4 | Script a 768×1024 y 390×780; comparar con §1. |
| C5 | Prueba de barra compacta a 1920×950, 2560×1300 y 1280×650. |
| C6 | `npm run build` y `npm test` en la raíz del repo. |
| C7 | Jaime abre `http://127.0.0.1:8099/` en su Chrome al 100 % (Ctrl + 0) y aprueba; capturas a 1024×768, 1920×950 y 2560×1300. |
| C8 | Script en 1024×552, 1100×552, 1280×552, 1366×600 y 1536×714, más el fondo de `#inicio .sc-hero-confianza` y de la tarjeta de la foto (abuelo de `.sc-foto-caja`). |
| C9 | `getComputedStyle(document.querySelector('#inicio .sc-garantia__texto')).display` a 1280×552 (`none`) y a 1280×650 (`block`). |

## Registro de revisión (Peces)

| Ronda | Pez | Severidad | Hallazgo (§) | Respuesta: aceptado / rechazado y por qué |
|---|---|---|---|---|
| 1 | Comprensión (Haiku) | — | §4.2 no daba la fórmula de los factores | Aceptado: fórmula y ejemplo en §4.2. |
| 1 | Comprensión (Haiku) | — | §4.1/§3: no se valida `.sc-foto-caja` | Aceptado: medido; §4.2 lo documenta. |
| 1 | Comprensión (Haiku) | — | §4.3: qué pasa con el enlace oculto | Aceptado: §4.3 (orden, sección y pie). |
| 1 | Comprensión (Haiku) | — | §4.2: transiciones con `clamp()` | Aceptado: §4.2; C5 lo prueba. |
| 1 | Comprensión (Haiku) | — | §6: no se verifica que `deploy.sh` compile | Rechazado: `deploy.sh` hace `npm ci` + `npm run build` («Compilar el CSS de Tailwind») y publicar queda fuera del plano. |
| 1 | Ramón | BLOQUEANTE | §2 C1/C2: el `padding-top` fijo de `#inicio` deja el CTA fuera a 1280 y 1366 | Aceptado: medido (v1 deja el CTA en 668 a 1280×650). v2 ata el margen a la barra (`--sc-barra` + 2 rem): CTA visible en toda la matriz (§4.2). |
| 1 | Ana | BLOQUEANTE | §4.2/§2: el plano no demostraba que el CTA quedara visible | Aceptado: v2 trae la medición de los 12 tamaños (§4.2). |
| 1 | Ana | BLOQUEANTE | §3 vs C1–C2: garantía y espacios fuera de alcance empujan el CTA | Rechazado con evidencia: con el margen atado a la barra el CTA entra en toda la matriz sin tocar esos bloques (§4.2, §5). |
| 1 | Ramón | IMPORTANTE | §3/C6: las tablets apaisadas ≥ 1024 sí cambian | Aceptado: §3 lo declara intencional; 1024×768 y 1180×820 en la matriz y 1024×768 en C7. |
| 1 | Ramón | IMPORTANTE | C9: capturas solo en 1280 y 2560 | Aceptado: C7 añade 1024×768 y 1920×950. |
| 1 | Ramón + Ana | IMPORTANTE | §8/C3: el peor caso del menú no es 1024; faltan 1099/1100, 1279 y 1535 | Aceptado: matriz ampliada (§2) y medida (§4.2): 0 partidos y sin desborde. |
| 1 | Ramón | IMPORTANTE | C8: `npm test` no prueba el cambio; faltan pruebas automatizadas | Aceptado en parte: C6 aclara el alcance de `npm test`. Playwright rechazado (§5). |
| 1 | Ramón + Ana | IMPORTANTE | §4.2: la tabla suponía raíz 16 px hasta 1280 y omitía la raíz real | Aceptado: la tabla trae ahora valores medidos y la raíz de cada ancho. |
| 1 | Ana | IMPORTANTE | §4.1(d): la causa del desborde no estaba demostrada y el enlace era ambiguo | Aceptado: §1 cita la medición y la línea 768; §4.1(e) añade `min-w-0` al `<li>`; §9 incluye la prueba de causa. |
| 1 | Ana | IMPORTANTE | C7: la prueba de la barra compacta era vacua a 1280 | Aceptado: C5 exige altura menor en 1920 y 2560; a 1280 solo `is-compacto` y 0 partidos. |
| 1 | Ana | IMPORTANTE | §4.2: `.sc-foto-caja` puede fijar el alto de la fila | Aceptado: medido; el fondo de la foto queda dentro de la ventana en toda la matriz (§4.2). |
| 1 | Ramón | MENOR | §4.2: la letra del menú es fluida solo desde ~1830 px | Aceptado: §4.3 punto 4. |
| 1 | Ramón | MENOR | §4.2/C7: compacta = normal en el tramo mínimo | Aceptado: §4.3 punto 5. |
| 1 | Ramón | MENOR | §4.1(d): causa del desborde sin aislar | Aceptado: §9. |
| 1 | Ana | MENOR | §4.1(b): «Antes y después» oculto sin alternativa | Aceptado: §4.3 cita el pie (`index.html:760`; Ana citó la 759, que es «Cómo trabajamos»). |
| 1 | Ana | MENOR | §9: faltan 1099, 1100 y 1279 | Aceptado: en la matriz. |
| 1 | Ana | MENOR | §8: zoom «solo texto» | Aceptado: §8 lo declara como compromiso. |
| 2 | Jaime (prueba real en su Chrome al 100 %) | BLOQUEANTE | §1/§2: con la barra de marcadores el alto real es 552, no 650; el CTA queda fuera y la foto se ve recortada | Aceptado: §1 lo documenta; v3 añade el tramo de pantallas bajas (§4.2), C8 y C9. Ana ya había propuesto compactar la garantía en pantallas bajas (ronda 1); se rechazó con la medición a 650, que era el supuesto equivocado. |

## Desvíos durante la implementación

- Ninguno de diseño: las reglas de §4.2 se aplicaron tal cual.
- Al verificar, Chrome sirvió el `dist/style.css` viejo desde su caché (la URL lleva `?v=$CSS_VERSION`
  literal en local). Se forzó con `fetch(href, {cache: 'reload'})`. En producción no ocurre: `deploy.sh`
  sustituye `$CSS_VERSION` por el sha del CSS.

## Verificación (2026-11-12, local, código real, sin commit)

| Criterio | Evidencia | Estado |
|---|---|---|
| C1 | 12 tamaños de la matriz: 0 enlaces partidos, barra sin desborde, `scrollX` 0 | ✓ |
| C2 | 12 tamaños: título ≤ 3 líneas; CTA visible (peor caso 1024×650: 646 de 650) | ✓ |
| C3 | 2560×1300: título 89,6 · barra 150 · nombre 52,5 · ícono 125 · CTA 1066 | ✓ |
| C4 | 768×1024: 56/3 · 96 · 30 · 72 · 652; 390×780: 34/4 · 76 · 17 · 545 (idénticos a §1) | ✓ |
| C5 | CSS compacto con `is-compacto` puesta a mano: 1920×950 barra 109→86, 2560×1300 150→95, 1280×650 76→76 (previsto), 0 partidos | ✓ en CSS · el disparo por IntersectionObserver no se pudo ver: el panel del navegador de prueba estaba oculto y Chrome no ejecuta el observador; ese JavaScript no cambia en este diff |
| C6 | `npm run build` OK. `npm test`: 1 fallo **previo y ajeno** («declara una CSP propia», plantilla de nginx; el test solo lee `nginx/`) | ✓ build · test con fallo preexistente |
| C7 | v2 vista por Jaime al 100 %: rechazada (CTA fuera a 1280×552) → v3. v3 revisada por Jaime en su Chrome al 100 % y **aprobada** («Bien, publícalo», 2026-11-12) | ✓ |
| Causa del desborde | Después, a 1024×650, solo los 2 brillos `pointer-events-none` superan el ancho; el correo ya no | ✓ |

### Verificación v3 (código real)

| Criterio | Evidencia | Estado |
|---|---|---|
| C8 | 1280×552: CTA 447 · conf 510 · tarjeta 483 · foto 268. 1366×600: 454 · 518 · 511. 1536×714: 611 · 657 · 644. 1024×552 y 1100×552: CTA 495 ✓, conf 558 (6 px fuera, dentro de los 8 aceptados), tarjeta 507 ✓. En todas: 0 partidos, `scrollX` 0 | ✓ |
| C9 | `.sc-garantia__texto`: `none` a 1280×552, 1366×600, 1024×552 y 1100×552; `block` a 1280×650, 1536×714 y más altas | ✓ |
| C1–C4 sin regresión | 1279/1280×650: CTA 564; 1024×650: 582; 1024×768: 646; 1536×730: 615; 1920×950: 719; 2560×1300: título 89,6 · barra 150 · CTA 1066; 768×1024 y 390×780 idénticos a §1 | ✓ |

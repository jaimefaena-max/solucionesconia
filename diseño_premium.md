# Diseño Premium — Landing World-Class · Soluciones con IA

> Documento de dirección creativa para regenerar la landing de `solucionesconia.cl`
> con un estándar visual World-Class. Contiene: (1) el **Prompt Maestro One-Shot**
> para Claude Design, (2) la **estructura y copy** sección a sección, y (3) los
> **prompts de generación de assets** (Midjourney / Sora / Kling).
>
> Paleta de marca (heredada del build actual): `#1E3A8A` azul institucional ·
> `#06B6D4` cian tecnológico · `#0F172A` fondo dark · `#F8FAFC` blanco hueso.
> Tipografía: **Inter**.

---

## 1. Prompt Maestro (One-Shot) para Claude Design

Copiar y pegar íntegro. Está redactado para una sola pasada de generación.

```
Diseña una landing page de una sola página, World-Class, para "Soluciones con IA",
una agencia chilena de automatización con inteligencia artificial para Pymes B2B.
El objetivo emocional es PAZ MENTAL Y CONTROL: el dueño de una Pyme deja de estar
atrapado en la operación y recupera su tiempo.

── IDENTIDAD VISUAL ──────────────────────────────────────────────────────────
· Dark mode premium. Fondo base #0F172A con degradados sutiles hacia #1E3A8A.
· Acentos en cian eléctrico #06B6D4 y azul institucional #1E3A8A. Usar el cian
  SOLO para lo que importa (CTAs, datos vivos, líneas de energía); no saturar.
· Estética glassmorphism corporativo: tarjetas de cristal translúcido con
  blur de fondo, bordes de 1px a baja opacidad (rgba(255,255,255,0.08)),
  sombras suaves con glow cian muy tenue.
· Minimalismo institucional: mucho aire, jerarquía tipográfica fuerte con Inter
  (títulos 600-800, cuerpo 400-500), nada de recargado ni degradados chillones.
· Micro-detalle premium: grano/ruido sutil sobre los fondos, no planos.

── MOVIMIENTO (estilo Apple / scroll-driven) ─────────────────────────────────
· Animaciones activadas por scroll (scroll-driven): los elementos entran con
  fundido + desplazamiento vertical corto (16-24px) y un easing suave.
· Parallax discreto en el fondo del hero (la capa de fondo se mueve más lento
  que el contenido).
· Las tarjetas de agentes se revelan escalonadas (stagger) al entrar en viewport.
· La comparativa "sin IA vs con IA" se ensambla con una transición al hacer scroll.
· TODO respeta `prefers-reduced-motion`: si está activo, sin movimiento, solo
  fundidos mínimos o estado final directo. La accesibilidad manda.

── ESTRUCTURA Y COPY (respetar textos literalmente) ──────────────────────────

[HERO] — fondo: imagen/video sutil (ver §3), oscurecido con overlay para legibilidad.
  Kicker:      "Automatización con IA para Pymes"
  Titular:     "Tu negocio, funcionando solo."
  Subtítulo:   "Recupera tu tiempo. Nosotros automatizamos ventas, atención y
                gestión con agentes de IA que trabajan por ti, 24/7."
  CTA primario:   "Agenda tu diagnóstico"  (botón cian con glow)
  CTA secundario: "Ver cómo funciona"       (botón fantasma, borde translúcido)
  Micro-prueba:  "Sin permanencia · Implementación en semanas, no meses"

[AGENTES] — cards de cristal animadas, grid 3 columnas (1 en móvil).
  Título de sección: "Un equipo de IA para cada frente"
  Bajada:            "Cada agente se ocupa de una parte del trabajo pesado."
  · Card 1 — "Vendedor 24/7":   "Responde, califica y agenda mientras duermes."
  · Card 2 — "Atención sin espera": "Cada cliente atendido al instante, sin colas."
  · Card 3 — "Gestión al día":  "Cobros, recordatorios y reportes, en piloto automático."
  (Cada card: icono lineal cian, título, una frase, y una línea de dato viva
   —ej. "Tiempo de respuesta: <30s"— que sugiera un sistema real operando.)

[SIN IA vs CON IA] — comparativa a dos columnas, ensamblada al scroll.
  Título: "Tu negocio, antes y después"
  Columna izquierda "SIN IA" (apagada, gris, tensa):
    · "Respondes mensajes a medianoche"
    · "Se pierden clientes que nadie atendió"
    · "El día se va en tareas repetitivas"
  Columna derecha "CON IA" (viva, cian, en calma):
    · "Tus agentes responden solos, al instante"
    · "Ningún cliente queda sin respuesta"
    · "Tú decides; el sistema ejecuta"
  Cierre de sección: "La diferencia no es trabajar más. Es dejar de cargar con todo."

[CTA FINAL] — bloque centrado, fondo con glow cian ascendente.
  Titular:   "Menos carga para ti. Más negocio funcionando."
  Subtítulo: "Agenda un diagnóstico gratuito y te mostramos exactamente qué se
              puede automatizar en tu Pyme."
  CTA:       "Quiero mi diagnóstico"   (botón cian con glow, grande)
  Reaseguro: "Conversación de 30 minutos. Cero compromiso."

── REGLAS TÉCNICAS ───────────────────────────────────────────────────────────
· Responsive impecable: mobile-first, sin scroll horizontal, tap-targets ≥44px.
· Contraste AA mínimo sobre el dark; el texto sobre imágenes siempre con overlay.
· Rendimiento: imágenes optimizadas, animaciones con transform/opacity (GPU),
  nada que bloquee el hilo principal.
· Un solo CTA repetido (agendar diagnóstico): no dispersar la conversión.
· Tono B2B chileno, cercano y profesional. Frases cortas. Cero jerga técnica.
```

---

## 2. Notas de copywriting (voz de marca)

- **Beneficio antes que función.** No "chatbots con NLP", sino "responde solo".
- **El enemigo es la carga, no la competencia.** El mensaje central es aliviar,
  no impresionar. "Menos carga para ti" / "Tu equipo 24/7".
- **Frases de 4-8 palabras** en titulares. El cuerpo, máximo dos líneas.
- **Un solo CTA** en toda la página: *Agenda tu diagnóstico*. La repetición sin
  variación reduce la fricción de decisión.
- **Prueba tranquila, no urgencia falsa.** Nada de "¡solo hoy!". Reaseguros de
  bajo riesgo: "sin permanencia", "cero compromiso", "30 minutos".

---

## 3. Prompts de generación de assets (fondo del Hero)

Concepto compartido: **un CEO/dueña o dueño de empresa en calma**, en un entorno
corporativo minimalista y de lujo (NO playa, NO vacaciones), mientras interfaces
holográficas sutiles procesan datos a su alrededor. Transmite **control sereno**,
no ostentación. El asset va de FONDO, así que debe tener zonas oscuras y
despejadas donde caiga el texto del hero.

### Prompt A — Imagen fija (Midjourney / imagen de fondo)

```
A calm, confident business owner (early 40s, smart-casual, neutral styling)
standing relaxed in a minimalist luxury office at dusk, hands in pockets, soft
half-smile of quiet control. Floor-to-ceiling windows, dark moody interior in
deep navy (#0F172A) and charcoal tones. Subtle translucent holographic UI panels
float in the mid-air around them — thin glassmorphic cards, faint cyan (#06B6D4)
data lines and gentle glowing charts — softly out of focus, elegant, NOT busy.
Cinematic lighting, single soft key light, deep shadows on the left third for
text overlay space. Premium corporate, editorial, restrained. Volumetric haze,
fine film grain. Shot on 35mm, shallow depth of field.
--ar 16:9 --style raw --stylize 250 --quality 2
Negative: beach, vacation, tropical, cluttered UI, neon overload, cartoon,
text, logos, oversaturation, busy background.
```

### Prompt B — Video de fondo (Sora / Kling · loop sutil)

```
Cinematic slow push-in, 8 seconds, seamless loop. A composed business owner sits
calmly at a minimalist glass desk in a dark luxury office, softly lit at blue
hour. Around them, translucent holographic dashboards drift and breathe — thin
glass panels with faint cyan (#06B6D4) lines, numbers and charts updating gently,
as if an intelligent system is quietly working on its own. The person barely
moves: relaxed posture, a slow calm breath, eyes steady — a sense of effortless
control. Deep navy (#0F172A) palette, volumetric light, soft particles in the
air, shallow depth of field. Camera drifts forward almost imperceptibly.
Mood: serene, premium, in-control. Left side of frame kept darker and emptier
for text overlay.
Negative / avoid: fast motion, flashing, neon clutter, beach or vacation,
crowds, on-screen text, logo, glitch effects, oversaturated colors.
Loop: first and last frame match for a seamless background loop.
```

**Notas de dirección de arte para los assets:**
- Ambos deben dejar el **tercio izquierdo más oscuro y vacío**: ahí va el titular.
- El cian es **acento**, no protagonista: pocas líneas, mucho respiro.
- Nada de rostros mirando a cámara con intensidad: la emoción es **calma**, no pose.
- Para el video: transición imperceptible y loop perfecto (primer=último frame),
  porque irá en bucle detrás del hero sin que se note el corte.

---

## 4. Cómo aterrizarlo en el build actual

- La landing ya está migrada a **Tailwind build local** (v3, `npm run build` →
  `dist/style.css`). Los tokens de marca viven en `tailwind.config.js`
  (`primary`, `accent`, `boxShadow.glow`), listos para reutilizar.
- Para el dark premium habría que **invertir el modo** de la landing actual (hoy
  clara, `#F8FAFC`) a base `#0F172A` — es un cambio de identidad, no un retoque.
- Las `scroll-driven animations` se pueden hacer con CSS puro
  (`animation-timeline: view()`) o con una librería de animación; decidir según
  el soporte de navegadores objetivo.
- El asset de fondo (imagen o video) va en `assets/`, con overlay oscuro para
  garantizar contraste AA del titular.

*Documento de dirección creativa — no altera el sitio en producción. Es el brief
para la próxima iteración visual.*

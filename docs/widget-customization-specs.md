# Especificaciones de estilo y avatar — Widget Vendedor IA

**Destino:** repositorio del agente (`zasa-orchestrator`) — bundle `vendedor-ia.js`
servido desde `admin.solucionesconia.cl/widget/`.
**Origen del requerimiento:** equipo de negocio de Soluciones con IA.
**Estado:** pendiente de implementación en el repo del agente.

---

## 1. Contexto técnico (por qué este documento existe)

El widget se inyecta en la landing (`solucionesconia.cl`) con una sola etiqueta:

```html
<script defer src="https://admin.solucionesconia.cl/widget/vendedor-ia.js"></script>
```

El componente se renderiza dentro de un **Shadow DOM aislado** cuyo estilo raíz es
`:host { all: initial }`. Consecuencias verificadas empíricamente:

- **La CSS de la landing NO cruza el shadow boundary.** Una regla global agresiva
  (`* { outline: red } button { background: lime }`) inyectada desde el documento
  padre no tuvo ningún efecto sobre el launcher del widget.
- **El bundle no expone configuración visual** por atributos `data-*` ni lee
  `currentScript` (no hay knobs de avatar, posición, tema ni estado online).
- **El avatar actual no es una imagen**, sino una inicial ("S") dibujada por CSS.

Por lo tanto, **estos cambios NO son implementables desde el repositorio de la
landing**: deben aplicarse en el código fuente del widget (`zasa-orchestrator`),
dentro del Shadow DOM. Este documento versiona el requerimiento para ese equipo.

---

## 2. Requerimientos de diseño

### 2.1. Avatar flotante con imagen de perfil profesional

- Reemplazar la inicial "S" actual por un avatar **circular** con imagen.
- Perfil solicitado por negocio: **mujer chilena, ~30 años, imagen profesional**,
  coherente con "Sofía, Asistente comercial".
- Formato sugerido: `<img>` (o `background-image`) circular, `object-fit: cover`,
  con `alt` descriptivo para accesibilidad.

> **Nota de responsabilidad (revisar antes de producir el asset):** definir la
> demografía de una persona (nacionalidad, género, edad) para representar a un
> asistente implica un asset que **no debe presentarse como una persona real que
> no existe**. Recomendación: usar una **ilustración de avatar** o una **foto con
> licencia comercial y consentimiento explícito** del modelo. Evitar imágenes que
> sugieran una identidad falsa o induzcan a error al visitante. La decisión final
> del asset y su fuente es del equipo de negocio; queda documentada aquí para
> trazabilidad.

### 2.2. Posicionamiento persistente (sticky / fixed)

El launcher debe permanecer fijo en pantalla durante el scroll:

```css
position: fixed;
bottom: 24px;
right: 24px;
z-index: 9999;
```

- Persistencia total en scroll (no anclado al flujo del documento).
- `z-index: 9999` para quedar sobre el contenido de la landing.
- Considerar `safe-area-inset` en móviles con notch (opcional, recomendado).

### 2.3. Indicador de estado "online" (LED verde intermitente)

Punto LED sobre el avatar, esquina superior derecha, con pulso de animación.
Equivalente Tailwind solicitado:

```
absolute top-0 right-0 w-3 h-3 bg-emerald-500 rounded-full border-2 border-slate-900 animate-pulse
```

Equivalente en CSS puro (para aplicar dentro del Shadow DOM):

```css
.online-led {
  position: absolute;
  top: 0;
  right: 0;
  width: 12px;   /* w-3  */
  height: 12px;  /* h-3  */
  background: #10B981;        /* bg-emerald-500   */
  border-radius: 9999px;     /* rounded-full     */
  border: 2px solid #0F172A; /* border-2 slate-900 */
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50%      { opacity: 0.5; }
}
```

- El posicionamiento `absolute` es relativo al contenedor del avatar (que debe
  tener `position: relative`).
- Estado idealmente **reactivo** a la conectividad real del agente (online/offline),
  no un pulso puramente decorativo, si el backend expone ese estado.

---

## 3. Mejora de arquitectura recomendada (opcional)

Para evitar recompilar el bundle ante cada ajuste visual, exponer los valores como
atributos `data-*` leídos por el widget desde su `<script>` en la landing:

```html
<script defer
  src="https://admin.solucionesconia.cl/widget/vendedor-ia.js"
  data-avatar-src="https://.../sofia.webp"
  data-accent="#06B6D4"
  data-position="bottom-right"></script>
```

Esto permitiría a la landing personalizar sin tocar el repo del agente. Hoy el
bundle **no** lee estos atributos; sería una mejora de su API pública.

---

## 4. Checklist de aceptación (para el PR en `zasa-orchestrator`)

- [ ] Avatar circular con imagen (asset con licencia/consentimiento verificado).
- [ ] Launcher `fixed` en `bottom:24px / right:24px / z-index:9999`, persistente en scroll.
- [ ] LED verde con `animate-pulse` sobre el avatar.
- [ ] Verificado en móvil (sin desbordes; safe-area si aplica).
- [ ] Sin regresión en la carga del widget en `solucionesconia.cl`.

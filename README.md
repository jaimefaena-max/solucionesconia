# Soluciones con IA

Repositorio maestro de **Soluciones con IA** — agencia de automatización B2B para Pymes chilenas.

**Sitio:** [solucionesconia.cl](https://www.solucionesconia.cl)

## Propuesta de valor

Adaptamos inteligencia artificial (asistentes virtuales, automatización de procesos e integraciones)
a la realidad operativa de las Pymes en Chile, priorizando simplicidad, cercanía y resultados medibles
por sobre la complejidad técnica.

## Estructura del proyecto

```
├── index.html        # Landing page principal (HTML5 semántico + SEO)
├── src/
│   ├── config.js      # Configuración del tema de Tailwind CSS (CDN)
│   ├── styles.css     # Estilos personalizados complementarios
│   └── main.js        # Interactividad del sitio (menú, etc.)
├── assets/            # Imágenes, logos y recursos gráficos
└── .gitignore
```

## Stack técnico

- **HTML5** semántico
- **Tailwind CSS** vía CDN (sin build step, iteración ágil de diseño)
- **JavaScript** vanilla para interactividad ligera

## Desarrollo local

Al no requerir build step, basta con abrir `index.html` en el navegador o servirlo con
cualquier servidor estático (por ejemplo `npx serve .` o la extensión Live Server).

## Estado

Landing page en construcción — próxima etapa: inyección de diseño visual definitivo y contenidos
finales por sección.

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

## Despliegue en producción (VPS con Nginx + SSL)

Requisitos: VPS Ubuntu/Debian con acceso root, y los registros DNS **A** de
`solucionesconia.cl` y `www.solucionesconia.cl` apuntando a la IP del servidor
(necesario para que Certbot emita el certificado).

### Pasos

```bash
# 1. Conéctate al VPS
ssh root@TU_IP_DEL_VPS

# 2. Instala git si no está y clona el repositorio
apt-get update && apt-get install -y git rsync
git clone <URL_DEL_REPO> /opt/solucionesconia
cd /opt/solucionesconia

# 3. Ejecuta el script de despliegue (todo en uno)
sudo bash deploy.sh
```

Eso es todo. El script se encarga de:

1. Instalar **Nginx** y **Certbot** (solo si faltan).
2. Copiar el sitio a `/var/www/solucionesconia.cl` (excluyendo `.git`, `deploy.sh` y este README).
3. Ajustar permisos endurecidos (`root:root`, directorios 755, archivos 644 — Nginx solo lee).
4. Crear y activar el virtual host con gzip, cache de estáticos y headers de seguridad
   (HSTS, nosniff, X-Frame-Options, Referrer-Policy, Permissions-Policy).
5. Emitir el certificado **SSL de Let's Encrypt** con redirección automática HTTP → HTTPS.
6. Configurar el firewall **UFW** (permite solo SSH y Nginx).

### Actualizar el sitio (deploys posteriores)

```bash
ssh root@TU_IP_DEL_VPS
cd /opt/solucionesconia && git pull && sudo bash deploy.sh
```

El script es idempotente: detecta lo que ya está instalado/configurado y solo
sincroniza los archivos nuevos. La renovación del SSL queda automática vía el
timer de Certbot.

## Estado

Producción — auditoría de seguridad aplicada (headers, permisos endurecidos, firewall).
Todos los assets referenciados existen (`assets/favicon.svg`, `assets/og-image.jpg`).

Mejoras futuras planificadas: precompilar Tailwind CSS (eliminar CDN runtime),
iconos Lucide como SVG inline, compresión de `og-image.jpg`, `robots.txt` + `sitemap.xml`.

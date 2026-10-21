/** @type {import('tailwindcss').Config} */
// Tokens del Design System v2 de la web pública (ver DESIGN.md §1).
// Rediseño enterprise 2026-10-21: el marcado de index.html pasa de estilos
// inline a clases, así que los tokens viven aquí y no repetidos en el HTML.
// `content` sigue igual: Tailwind purga y solo emite las clases que aparecen en
// estos ficheros. /acceso carga dist/style.css pero NO se escanea: sus estilos
// van en acceso/acceso.css.
module.exports = {
  content: ["./index.html", "./src/**/*.js"],
  theme: {
    extend: {
      colors: {
        // Fondos (de más claro a más profundo se lee el orden de las capas).
        night: {
          DEFAULT: "#0F172A", // fondo base
          raise: "#101B36", // sección elevada
          deep: "#0A1122", // banda oscura (comparativa, footer)
          card: "#141C30", // superficie de tarjeta opaca
          high: "#1C2540", // chip sobre imagen
        },
        // Acento de IA: cian. `accent-ink` es el texto sobre fondo cian.
        accent: {
          DEFAULT: "#06B6D4",
          hover: "#22D3EE",
          light: "#67E8F9",
          faint: "#A5F3FC",
          ink: "#04202B",
        },
        // Azul institucional: solo para glows y degradados de fondo.
        brand: {
          DEFAULT: "#1E3A8A",
          dark: "#152C66",
        },
        // Texto. Las opacidades se piden con modificador: text-ink/65.
        ink: "#F8FAFC",
        danger: "#FDA4AF",
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "ui-monospace", "SFMono-Regular", "Menlo", "monospace"],
      },
      boxShadow: {
        glow: "0 10px 40px -8px rgba(6, 182, 212, 0.45)",
        "glow-lg": "0 20px 50px -12px rgba(6, 182, 212, 0.55)",
        card: "0 20px 60px rgba(4, 12, 28, 0.5)",
        "card-hover": "0 24px 70px rgba(4, 12, 28, 0.6), 0 0 40px rgba(6, 182, 212, 0.12)",
        cta: "0 0 0 1px rgba(255, 255, 255, 0.14) inset, 0 14px 44px rgba(6, 182, 212, 0.36)",
        "cta-lg": "0 0 0 1px rgba(255, 255, 255, 0.16) inset, 0 18px 60px rgba(6, 182, 212, 0.42)",
      },
      keyframes: {
        pulseGlow: {
          "0%, 100%": { opacity: "1", transform: "scale(1)", boxShadow: "0 0 0 0 rgba(6,182,212,.7)" },
          "50%": { opacity: ".8", transform: "scale(1.08)", boxShadow: "0 0 0 6px rgba(6,182,212,0)" },
        },
      },
      animation: {
        "pulse-glow": "pulseGlow 2s ease-in-out infinite",
      },
    },
  },
  plugins: [],
};

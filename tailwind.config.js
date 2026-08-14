/** @type {import('tailwindcss').Config} */
// Tokens de marca migrados desde src/config.js (el que consumía el CDN).
// Idénticos 1:1 para que el build local produzca EXACTAMENTE las mismas clases
// que ya servía el JIT del navegador: cero regresión visual.
module.exports = {
  // `content` reemplaza al escaneo en vivo del CDN: Tailwind purga y solo emite
  // las clases que realmente aparecen en estos ficheros. index.html es donde
  // vive todo el marcado; src/**/*.js por si main.js/config.js añaden clases.
  content: ["./index.html", "./src/**/*.js"],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "#1E3A8A", // Azul profesional: solidez y confianza institucional
          dark: "#152C66",
        },
        accent: {
          DEFAULT: "#06B6D4", // Cian eléctrico: inteligencia y tecnología
          dark: "#0891B2",
        },
        base: "#F8FAFC", // Blanco hueso premium: fondo limpio y despejado
        dark: "#0F172A",
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
      },
      boxShadow: {
        glow: "0 10px 40px -8px rgba(6, 182, 212, 0.45)",
        "glow-lg": "0 20px 50px -12px rgba(6, 182, 212, 0.55)",
      },
    },
  },
  plugins: [],
};

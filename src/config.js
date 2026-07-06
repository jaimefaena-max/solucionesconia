// Configuración de Tailwind CSS (vía CDN) para Soluciones con IA
tailwind.config = {
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
};

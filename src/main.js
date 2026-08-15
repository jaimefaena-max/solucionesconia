// Lógica de interacción del sitio Soluciones con IA.
// Portado a JS vanilla desde el componente del diseño (DCLogic): animaciones de
// entrada por IntersectionObserver + parallax del hero. Sin dependencias.
document.addEventListener("DOMContentLoaded", () => {
  const prefersReducedMotion = window.matchMedia(
    "(prefers-reduced-motion: reduce)"
  ).matches;

  // ── Reveal on scroll ──────────────────────────────────────────────────────
  const revealables = Array.from(document.querySelectorAll("[data-reveal]"));

  if (prefersReducedMotion) {
    // Sin animación: mostrar todo de inmediato.
    revealables.forEach((el) => el.classList.add("is-in"));
  } else if (revealables.length) {
    // Escalona la entrada en grupos de 4 para que no aparezcan todos a la vez.
    revealables.forEach((el, i) => {
      el.style.transitionDelay = `${(i % 4) * 90}ms`;
    });

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-in");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -8% 0px" }
    );

    revealables.forEach((el) => observer.observe(el));
  }

  // ── Parallax del fondo del hero ───────────────────────────────────────────
  const layers = Array.from(document.querySelectorAll("[data-parallax]"));

  if (!prefersReducedMotion && layers.length) {
    let rafId = null;

    const onScroll = () => {
      if (rafId) return;
      rafId = requestAnimationFrame(() => {
        rafId = null;
        const y = window.scrollY;
        layers.forEach((layer) => {
          const rate = parseFloat(layer.dataset.parallax);
          layer.style.transform = `translate3d(0, ${(y * rate).toFixed(1)}px, 0)`;
        });
      });
    };

    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
  }
});

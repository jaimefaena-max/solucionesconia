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

  // ── Modal de agendamiento (Cal.com) ────────────────────────────────────────
  const modal = document.getElementById("scheduler-modal");
  const frameHost = document.getElementById("scheduler-frame");

  if (modal && frameHost) {
    const SCHEDULER_URL = "https://cal.com/solucionesconia/diagnostico?theme=dark";
    let iframeLoaded = false;
    let lastFocus = null;

    const openModal = (trigger) => {
      lastFocus = trigger || document.activeElement;

      // Lazy-load: el iframe se inyecta SOLO en la primera apertura.
      if (!iframeLoaded) {
        const iframe = document.createElement("iframe");
        iframe.src = SCHEDULER_URL;
        iframe.title = "Agenda tu diagnóstico gratuito con Soluciones con IA";
        iframe.loading = "lazy";
        iframe.allow = "camera; microphone; fullscreen";
        frameHost.appendChild(iframe);
        iframeLoaded = true;
      }

      modal.hidden = false;
      modal.setAttribute("aria-hidden", "false");
      document.body.style.overflow = "hidden"; // bloquea scroll de fondo
      // Fuerza reflow para que la transición de entrada dispare.
      void modal.offsetWidth;
      modal.classList.add("is-open");

      const closeBtn = modal.querySelector(".sc-modal__close");
      if (closeBtn) closeBtn.focus();
    };

    const closeModal = () => {
      modal.classList.remove("is-open");
      modal.setAttribute("aria-hidden", "true");
      document.body.style.overflow = "";

      const finish = () => {
        modal.hidden = true;
        modal.removeEventListener("transitionend", finish);
      };
      // Espera a que termine la animación de salida antes de ocultar.
      const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      if (reduce) finish();
      else modal.addEventListener("transitionend", finish);

      if (lastFocus && typeof lastFocus.focus === "function") lastFocus.focus();
    };

    // Abrir: intercepta los CTA con data-open-scheduler (mailto queda de fallback).
    document.querySelectorAll("[data-open-scheduler]").forEach((el) => {
      el.addEventListener("click", (e) => {
        e.preventDefault();
        openModal(el);
      });
    });

    // Cerrar: botón X y backdrop (elementos con data-close-scheduler).
    modal.querySelectorAll("[data-close-scheduler]").forEach((el) => {
      el.addEventListener("click", closeModal);
    });

    // Cerrar con ESC.
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && modal.classList.contains("is-open")) {
        closeModal();
      }
    });
  }
});

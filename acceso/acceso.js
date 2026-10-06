// acceso.js — lógica de la pantalla de acceso del Portal VIP. Extraído del <script> en línea
// de acceso/index.html (2026-10-06) para que /acceso funcione con una CSP sin 'unsafe-inline'.
(function () {
  'use strict';

  var form = document.getElementById('formulario');
  var aviso = document.getElementById('aviso');
  var boton = document.getElementById('enviar');
  var campoEmail = document.getElementById('email');
  var campoPass = document.getElementById('password');

  /**
   * Mismo formato que exige el backend para un tenantId (kebab-case).
   *
   * 🔒 NO es cosmético: sin esta validación, `location.assign('/vip/' + t + '/')`
   * con un valor como `//sitio-atacante.cl` produciría una URL
   * PROTOCOLO-RELATIVA y el navegador saldría del dominio. Es la forma
   * clásica de open redirect. Hoy el valor viene de nuestro propio backend,
   * pero una redirección se construye asumiendo que el dato puede ser hostil.
   */
  var RE_TENANT = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

  function mostrarError(texto) {
    aviso.textContent = texto;
    aviso.classList.add('visible');
  }

  function limpiarError() {
    aviso.textContent = '';
    aviso.classList.remove('visible');
  }

  function ocupado(si) {
    boton.disabled = si;
    boton.textContent = si ? 'Verificando…' : 'Entrar';
  }

  // Al corregir lo escrito, el error de antes deja de ser cierto.
  campoEmail.addEventListener('input', limpiarError);
  campoPass.addEventListener('input', limpiarError);

  form.addEventListener('submit', function (evento) {
    evento.preventDefault();
    if (boton.disabled) return;   // corta el doble envío por doble clic

    var email = campoEmail.value.trim();
    var password = campoPass.value;

    if (!email || !password) {
      mostrarError('Completa tu correo y tu contraseña.');
      return;
    }

    limpiarError();
    ocupado(true);

    fetch('/api/auth/client-login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      // La sesión llega como cookie HttpOnly: el navegador la guarda y la
      // reenvía solo. Este script NUNCA la ve ni la almacena — no hay
      // localStorage ni sessionStorage en toda la página, a propósito.
      credentials: 'same-origin',
      cache: 'no-store',
      body: JSON.stringify({ email: email, password: password })
    })
      .then(function (respuesta) {
        if (respuesta.status === 429) {
          // Se distingue A PROPÓSITO del 401. Decirle «credenciales
          // inválidas» a alguien que en realidad está limitado por
          // intentos lo empuja a seguir probando y a agotar la ventana.
          // El límite es observable de todos modos: no filtra nada.
          ocupado(false);
          mostrarError('Demasiados intentos. Espera unos minutos antes de volver a probar.');
          return null;
        }
        if (!respuesta.ok) {
          ocupado(false);
          // Mensaje único para 400, 401 y 500: la pantalla no revela si el
          // correo existe. El backend ya responde igual para todos.
          mostrarError('Credenciales inválidas. Revisa tu correo y contraseña.');
          campoPass.value = '';
          campoPass.focus();
          return null;
        }
        return respuesta.json();
      })
      .then(function (datos) {
        if (!datos) return;

        var destino = '/vip/forte-spa/';
        if (datos.tenantId && RE_TENANT.test(datos.tenantId)) {
          // Enrutado por inquilino: la misma pantalla sirve a cualquier
          // cliente sin tocar este archivo. El literal de arriba queda solo
          // como red de seguridad si la respuesta viniera sin tenantId.
          destino = '/vip/' + datos.tenantId + '/';
        }
        // `replace` y no `assign`: al pulsar «atrás» desde el portal el
        // usuario no debe volver a caer en el formulario de login.
        window.location.replace(destino);
      })
      .catch(function () {
        ocupado(false);
        // Fallo de red o servidor caído: es un problema distinto de una
        // credencial mala, y decirlo evita que el cliente crea que su
        // contraseña dejó de funcionar.
        mostrarError('No pudimos conectar con el servidor. Inténtalo de nuevo en unos segundos.');
      });
  });
})();

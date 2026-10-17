// Small touches only. The page reads fine without this file.
(function () {
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // The opening clip: no autoplay for people who asked for less motion.
  var video = document.getElementById('opening');
  if (video && reduce) {
    video.removeAttribute('autoplay');
    video.pause();
    video.controls = true;
  }

  // The pup hops again when poked.
  var pup = document.querySelector('.pup');
  if (pup && !reduce) {
    pup.addEventListener('click', function () {
      pup.classList.remove('again');
      void pup.offsetWidth; // restart the animation
      pup.classList.add('again');
    });
  }

  // The tag demo: picking a tag shows the first line the app suggests.
  var tags = Array.prototype.slice.call(document.querySelectorAll('.tag'));
  var card = document.querySelector('.first-line');
  var occasion = document.getElementById('fl-occasion');
  var text = document.getElementById('fl-text');

  function pick(tag) {
    tags.forEach(function (t) {
      var on = t === tag;
      t.setAttribute('aria-checked', on ? 'true' : 'false');
      t.tabIndex = on ? 0 : -1;
    });
    occasion.textContent = tag.getAttribute('data-o');
    text.textContent = tag.getAttribute('data-line') + '…';
    if (!reduce) {
      card.classList.remove('swap');
      void card.offsetWidth;
      card.classList.add('swap');
    }
  }

  // Someone sent you one: accept the whole link or just the code, and only
  // ever open it here, on this site.
  var form = document.getElementById('open-form');
  if (form) {
    var input = document.getElementById('code');
    var error = document.getElementById('code-error');
    var CODE = /^[A-Za-z0-9_-]{16,64}$/;

    function codeFrom(raw) {
      var text = raw.trim();
      var at = text.lastIndexOf('/receive/');
      if (at !== -1) text = text.slice(at + 9);
      text = text.split(/[?#\/\s]/)[0];
      return CODE.test(text) ? text : null;
    }

    function showError(message) {
      error.textContent = message;
      error.hidden = !message;
      input.setAttribute('aria-invalid', message ? 'true' : 'false');
    }

    input.addEventListener('input', function () { showError(''); });
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      if (!input.value.trim()) {
        showError('Paste the link or code first.');
        input.focus();
        return;
      }
      var code = codeFrom(input.value);
      if (!code) {
        showError('That doesn\u2019t look like a Keepsake link or code. Check you copied all of it.');
        input.focus();
        return;
      }
      window.location.assign('app/receive/' + encodeURIComponent(code));
    });
  }

  tags.forEach(function (tag, i) {
    tag.tabIndex = tag.getAttribute('aria-checked') === 'true' ? 0 : -1;
    tag.addEventListener('click', function () { pick(tag); });
    // Arrow keys move between tags, like any radio group.
    tag.addEventListener('keydown', function (e) {
      var d = e.key === 'ArrowRight' || e.key === 'ArrowDown' ? 1
        : e.key === 'ArrowLeft' || e.key === 'ArrowUp' ? -1 : 0;
      if (!d) return;
      e.preventDefault();
      var next = tags[(i + d + tags.length) % tags.length];
      pick(next);
      next.focus();
    });
  });
})();

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

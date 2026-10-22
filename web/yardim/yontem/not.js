// CNK-FarmaStatR method notes: TR/EN switch (?lang=en). No network request.
(function () {
  var q = new URLSearchParams(location.search), lang = q.get('lang') === 'en' ? 'en' : 'tr';
  var b = document.getElementById('lang');
  function apply() {
    document.documentElement.lang = lang;
    document.querySelectorAll('section.not').forEach(function (s) { s.hidden = s.dataset.lang !== lang; });
    b.textContent = lang === 'tr' ? 'English' : 'Türkçe';
    var h = document.querySelector('section.not[data-lang="' + lang + '"] h1');
    if (h) document.title = 'CNK-FarmaStatR · ' + h.textContent;
  }
  b.addEventListener('click', function () {
    lang = lang === 'tr' ? 'en' : 'tr';
    var u = new URL(location.href); u.searchParams.set('lang', lang); history.replaceState(null, '', u);
    apply();
  });
  apply();
  window.__not = { ready: true };
})();

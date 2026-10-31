{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load();

if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker.register('sw.js').catch(function (error) {
      console.warn('Cache offline non disponibile:', error);
    });
  });
}

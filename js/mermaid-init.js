(function () {
  function initMermaid() {
    if (window.mermaid) {
      window.mermaid.initialize({ startOnLoad: true });
      try { window.mermaid.init(); } catch (e) { /* ignore */ }
    }
  }
  document.addEventListener('DOMContentLoaded', initMermaid);
  if (window.document$) {
    window.document$.subscribe(initMermaid);
  }
})();
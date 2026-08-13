/* Tela de valor com teclado próprio.
   O display é uma <div>, não um <input>: assim o teclado do iOS nunca abre —
   que é o motivo desta tela existir (ver docs/superpowers/specs/2026-08-12-tela-valor-teclado-design.md).

   Roda no browser (window.TECLADO) e nos testes em Node (module.exports).
   A lógica de dígitos é pura e fica separada da camada de tela. */
(function(root){
  'use strict';

  /* R$ 99.999.999,99 — acima disso a tecla é ignorada em vez de truncar,
     pra nunca mudar o número do usuário em silêncio. */
  const TETO = 9999999999;

  /* ---------- lógica pura (centavos como inteiro) ---------- */

  /* tecla: '0'..'9' | '00' | 'del'. Dígitos entram pela direita, estilo maquininha. */
  function aplicarTecla(centavos, tecla){
    const c = Math.max(0, Math.floor(centavos) || 0);
    if(tecla === 'del') return Math.floor(c / 10);
    if(tecla === '00'){
      const n = c * 100;
      return n > TETO ? c : n;
    }
    if(!/^[0-9]$/.test(tecla)) return c;
    const n = c * 10 + Number(tecla);
    return n > TETO ? c : n;
  }

  function fmtCentavos(centavos){
    const c = Math.max(0, Math.floor(centavos) || 0);
    const int = Math.floor(c / 100);
    const cent = String(c % 100).padStart(2, '0');
    return int.toLocaleString('pt-BR') + ',' + cent;
  }

  function centavosParaReais(centavos){
    return (Math.floor(centavos) || 0) / 100;
  }

  /* toFixed antes do round porque 8.7*100 dá 869.9999... em ponto flutuante */
  function reaisParaCentavos(reais){
    const n = Number(reais);
    if(!isFinite(n) || n <= 0) return 0;
    return Math.min(TETO, Math.round(parseFloat((n * 100).toFixed(4))));
  }

  const api = { TETO, aplicarTecla, fmtCentavos, centavosParaReais, reaisParaCentavos };

  /* ---------- camada de tela (só no browser) ---------- */

  if(typeof document !== 'undefined'){
    const TECLAS = ['7','8','9','4','5','6','1','2','3','00','0','del'];
    const SVG_X = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>';
    const SVG_DEL = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20 5H9L3 12l6 7h11a1 1 0 0 0 1-1V6a1 1 0 0 0-1-1z"/><path d="M15 9.5l-4 5M11 9.5l4 5"/></svg>';

    let tela = null, num = null, ok = null;
    let centavos = 0, onConfirm = null, onCancel = null;

    function pintar(){
      num.textContent = fmtCentavos(centavos);
      ok.disabled = centavos <= 0;
    }

    function montar(){
      tela = document.createElement('div');
      tela.className = 'valor-tela';
      tela.innerHTML = `
        <div class="valor-top">
          <button type="button" class="valor-x" aria-label="Cancelar lançamento">${SVG_X}</button>
          <span class="valor-titulo">Valor do gasto</span>
        </div>
        <div class="valor-display"><b>R$</b><span class="valor-num">0,00</span></div>
        <div class="valor-keys">
          ${TECLAS.map(k => k === 'del'
            ? `<button type="button" class="valor-key valor-key-del" data-k="del" aria-label="Apagar">${SVG_DEL}</button>`
            : `<button type="button" class="valor-key" data-k="${k}">${k}</button>`).join('')}
        </div>
        <button type="button" class="btn primary valor-ok">Avançar</button>`;
      document.body.appendChild(tela);

      num = tela.querySelector('.valor-num');
      ok = tela.querySelector('.valor-ok');

      tela.querySelector('.valor-keys').onclick = e => {
        const b = e.target.closest('.valor-key');
        if(!b) return;
        centavos = aplicarTecla(centavos, b.dataset.k);
        pintar();
      };
      tela.querySelector('.valor-x').onclick = cancelar;
      ok.onclick = confirmar;
    }

    /* pega o handler ANTES de fechar, porque fechar() zera os dois */
    function confirmar(){
      if(centavos <= 0) return;
      const valor = centavosParaReais(centavos), cb = onConfirm;
      fechar();
      if(cb) cb(valor);
    }
    function cancelar(){
      const cb = onCancel;
      fechar();
      if(cb) cb();
    }

    /* capture + stopPropagation: quando o teclado está por cima do sheet, o Esc
       tem que fechar só o teclado, não o sheet que está atrás. */
    function onKey(e){
      if(!tela || tela.classList.contains('hidden')) return;
      if(e.key === 'Escape'){ e.stopPropagation(); cancelar(); return; }
      if(e.key === 'Enter'){ e.stopPropagation(); confirmar(); return; }
      const k = e.key === 'Backspace' ? 'del' : e.key;
      if(/^([0-9]|del)$/.test(k)){
        e.stopPropagation();
        centavos = aplicarTecla(centavos, k);
        pintar();
      }
    }
    document.addEventListener('keydown', onKey, true);

    function fechar(){
      tela.classList.add('hidden');
      document.body.classList.remove('teclado-open');
      onConfirm = onCancel = null;
    }

    api.abrir = function({ valorInicial = 0, onConfirm: conf, onCancel: canc } = {}){
      if(!tela) montar();
      centavos = reaisParaCentavos(valorInicial);
      onConfirm = conf; onCancel = canc;
      tela.classList.remove('hidden');
      document.body.classList.add('teclado-open');
      pintar();
    };
  }

  if(typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.TECLADO = api;
})(this);

/* Ícones SVG de linha (estilo Lucide) embutidos — sem CDN, funciona offline.
   Browser: globais ICON() e ICONES + auto-substituição de [data-ico].
   Node (testes): module.exports. */
'use strict';
(function(root){
  const ICONES = {
    guindaste:  '<path d="M3 21h18M6 21V4m0 0H3m3 0h13m-3 0v6"/><circle cx="16" cy="12" r="2"/>',
    predio:     '<path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18"/><path d="M2 22h20"/><path d="M10 6h1M13 6h1M10 10h1M13 10h1M10 14h1M13 14h1"/>',
    casa:       '<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/>',
    check:      '<path d="m4 12 5 5L20 7"/>',
    balanca:    '<path d="M12 3v18M7 21h10"/><path d="m5 7 7-2 7 2"/><path d="M5 7l-2.5 6a3 3 0 0 0 5 0L5 7Z"/><path d="M19 7l-2.5 6a3 3 0 0 0 5 0L19 7Z"/>',
    engrenagem: '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
    sair:       '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5M21 12H9"/>',
    moedas:     '<circle cx="8" cy="8" r="6"/><path d="M18.09 10.37A6 6 0 1 1 10.34 18"/><path d="M7 6h1v4"/><path d="m16.71 13.88.7.71-2.82 2.82"/>',
    notas:      '<rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/><path d="M6 12h.01M18 12h.01"/>',
    banco:      '<path d="M3 21h18M4 18h16M6 18v-7M10 18v-7M14 18v-7M18 18v-7M3 8l9-5 9 5H3Z"/>',
    alvo:       '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
    acordo:     '<path d="m11 17 2 2a1.5 1.5 0 0 0 2.12-2.12"/><path d="m14 14 2.5 2.5a1.5 1.5 0 0 0 2.12-2.12L13.5 9.27a3 3 0 0 0-4.24 0L8 10.5"/><path d="m21 12 1-1-6.5-6.5-2 2"/><path d="M3 11l-1 1 6.5 6.5 1.5-1.5"/><path d="M2 10 8.5 3.5 10.5 5.5"/>',
    setaCima:   '<path d="M12 19V5m-6 6 6-6 6 6"/>',
    setaBaixo:  '<path d="M12 5v14m-6-6 6 6 6-6"/>',
    calculadora:'<rect x="4" y="2" width="16" height="20" rx="2"/><path d="M8 6h8M8 11h.01M12 11h.01M16 11h.01M8 15h.01M12 15h.01M16 15h.01M8 19h.01M12 19h.01M16 19h.01"/>',
    mapa:       '<path d="M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2Z"/><path d="M9 4v14M15 6v14"/>',
    regua:      '<path d="M21 8 16 3 3 16l5 5L21 8Z"/><path d="m10 9 1 1M13 6l1 1M7 12l1 1"/>',
    pa:         '<path d="M12 3v9M10 3h4"/><path d="M8 12h8l-1 5a3 3 0 0 1-6 0z"/>',
    tijolos:    '<rect x="3" y="8" width="18" height="12" rx="1"/><path d="M3 14h18M9 8v6M15 8v6M6 14v6M12 14v6M18 14v6"/>',
    raio:       '<path d="M13 2 4 14h6l-1 8 9-12h-6l1-8Z"/>',
    gota:       '<path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11Z"/>',
    porta:      '<path d="M4 21h16M6 21V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v16"/><circle cx="15" cy="12" r="1"/>',
    camadas:    '<path d="m12 3 9 5-9 5-9-5 9-5Z"/><path d="m3 13 9 5 9-5"/>',
    rolo:       '<rect x="3" y="4" width="14" height="5" rx="1"/><path d="M17 6h3a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1h-8v3"/><rect x="10" y="14" width="4" height="7" rx="1"/>',
    arvore:     '<path d="m12 3 5 7h-3l4 6H6l4-6H7l5-7Z"/><path d="M12 16v5"/>',
    capacete:   '<path d="M2 18a1 1 0 0 0 1 1h18a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1H3a1 1 0 0 0-1 1Z"/><path d="M10 10V5a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v5"/><path d="M4 15v-3a6 6 0 0 1 6-6"/><path d="M14 6a6 6 0 0 1 6 6v3"/>',
    caixa:      '<path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5M12 22V12"/>',
    etiqueta:   '<path d="M2 12V4a2 2 0 0 1 2-2h8l10 10-10 10L2 12Z"/><circle cx="7" cy="7" r="1"/>',
    cartao:     '<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20"/>',
    lapis:      '<path d="M17 3a2.85 2.85 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/>',
    documento:  '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v5h6"/>',
    impressora: '<path d="M6 9V2h12v7"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/>',
    voltar:     '<path d="M9 14 4 9l5-5"/><path d="M4 9h10a6 6 0 0 1 0 12h-3"/>',
    recibo:     '<path d="M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1Z"/><path d="M8 7h8M8 11h8M8 15h5"/>',
    calendario: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>',
    alerta:     '<path d="m10.3 3.7-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.7-3l-8-14a2 2 0 0 0-3.4 0Z"/><path d="M12 9v4M12 17h.01"/>',
    instalar:   '<rect x="6" y="2" width="12" height="20" rx="2"/><path d="M12 7v6m-3-3 3 3 3-3"/>',
    olho:       '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
    olhoFechado:'<path d="M2 12s3.5-7 10-7c2 0 3.8.7 5.3 1.6M22 12s-3.5 7-10 7c-2 0-3.8-.7-5.3-1.6"/><path d="m3 3 18 18"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
  };

  function ICON(nome, cls){
    const p = ICONES[nome] || ICONES.etiqueta;
    return `<svg class="ico${cls ? ' '+cls : ''}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${p}</svg>`;
  }

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ICON, ICONES };
  } else {
    root.ICON = ICON; root.ICONES = ICONES;
    const aplica = () => document.querySelectorAll('[data-ico]').forEach(e => { e.innerHTML = ICON(e.dataset.ico); });
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', aplica);
    else aplica();
  }
})(typeof self !== 'undefined' ? self : this);

/* Registro e atualização do PWA. */
'use strict';
if('serviceWorker' in navigator){
  const jaControlado = !!navigator.serviceWorker.controller;
  let recarregou = false;
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if(jaControlado && !recarregou){
      recarregou = true;
      location.reload();
    }
  });
  window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(err => {
    if(window.OBRA_DIAG) window.OBRA_DIAG.registra('pwa', err.message, err.stack);
    else console.error('[custta] pwa', err);
    if(typeof toast === 'function') toast('Não foi possível preparar o uso offline. Abra novamente com internet.', 'erro');
  }));
}

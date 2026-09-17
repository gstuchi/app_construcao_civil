/* Registro e atualização do PWA. */
'use strict';
/* No app nativo os arquivos vêm do próprio binário; SW só atrapalharia a atualização. */
if('serviceWorker' in navigator && !window.OBRA_NATIVO?.ehNativo()){
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

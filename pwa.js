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
  window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
}

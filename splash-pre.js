/* Remove o splash antes da pintura quando já apareceu nesta sessão.
   No app nativo quem cobre a abertura é o splash do iOS. */
'use strict';
if(sessionStorage.getItem('splashVista') || window.OBRA_NATIVO?.ehNativo()) document.getElementById('splash')?.remove();

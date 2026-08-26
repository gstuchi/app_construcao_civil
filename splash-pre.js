/* Remove o splash antes da pintura quando já apareceu nesta sessão. */
'use strict';
if(sessionStorage.getItem('splashVista')) document.getElementById('splash')?.remove();

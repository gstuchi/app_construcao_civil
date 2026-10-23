/* Aplica tema salvo antes da pintura — evita flash do tema errado. */
'use strict';
try{
  const claro = localStorage.getItem('mo_tema') === 'claro';
  if(claro){
    document.documentElement.setAttribute('data-theme', 'light');
    const meta = document.querySelector('meta[name="theme-color"]');
    if(meta) meta.content = '#EDF5F1';
  }
  // A pele azul saiu em 21/10/2026: quem a tinha escolhido volta ao esmeralda.
  localStorage.removeItem('mo_skin');
}catch(err){
  // app.js ainda não carregou: entrega o erro ao diagnóstico quando ele iniciar.
  window.OBRA_ERROS_INICIAIS = [{ origem:'tema', msg:err.message, stack:err.stack }];
  console.error('[custta] tema', err);
}

/* Aplica tema salvo antes da pintura — evita flash do tema errado. */
'use strict';
try{
  const claro = localStorage.getItem('mo_tema') === 'claro';
  const azul = localStorage.getItem('mo_skin') === 'azul';
  if(claro) document.documentElement.setAttribute('data-theme', 'light');
  if(azul) document.documentElement.setAttribute('data-skin', 'azul');
  if(claro || azul){
    const meta = document.querySelector('meta[name="theme-color"]');
    if(meta) meta.content = claro ? (azul ? '#eef2f9' : '#EDF5F1') : '#070c18';
  }
}catch(err){}

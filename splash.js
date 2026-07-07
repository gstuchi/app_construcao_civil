/* Splash de abertura — roda uma vez por sessão (recarregar não repete).
   A barra de progresso é amarrada ao boot real: os últimos 8% só andam
   quando o CLOUD.ready responde (Firebase sabe quem é o usuário), com
   teto de 8s pra nunca prender o usuário se a nuvem falhar. */
'use strict';
(function(){
  const splash = document.getElementById('splash');
  if(!splash) return; // já removida pelo script inline (sessão repetida)

  const reduz = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const bar = document.getElementById('spBar');
  const pct = document.getElementById('spPct');
  const status = document.getElementById('spStatus');

  const ETAPAS = [
    { ate:18,  msg:'Preparando o app…' },
    { ate:44,  msg:'Conectando à nuvem…' },
    { ate:70,  msg:'Carregando suas obras…' },
    { ate:92,  msg:'Quase pronto…' },
    { ate:100, msg:'Bem-vindo!' },
  ];

  let cloudPronto = false;
  const marcar = ()=>{ cloudPronto = true; };
  if(window.CLOUD) CLOUD.ready.then(marcar);
  else window.addEventListener('cloud-pronto', ()=>CLOUD.ready.then(marcar), {once:true});
  setTimeout(marcar, 8000); // teto: primeira visita offline não pode travar aqui

  const inicio = performance.now();
  const MIN = reduz ? 500 : 3600; // deixa a animação respirar antes de fechar

  function sair(){
    sessionStorage.setItem('splashVista','1');
    splash.classList.add('sp-out');
    splash.addEventListener('transitionend', ()=>splash.remove(), {once:true});
    setTimeout(()=>splash.remove(), 1200); // garantia se transitionend não vier
  }

  let n = 0, etapa = 0;
  function tick(){
    // segura em "Quase pronto…" até a nuvem responder e a animação terminar
    if(n >= 92 && !(cloudPronto && performance.now()-inicio >= MIN)){
      setTimeout(tick, 120); return;
    }
    n++;
    pct.textContent = n + '%';
    bar.style.transform = 'scaleX(' + (n/100) + ')';
    const alvo = ETAPAS[etapa];
    if(n >= alvo.ate){
      status.textContent = alvo.msg;
      etapa++;
      if(etapa < ETAPAS.length) setTimeout(tick, reduz ? 0 : 140);
      else setTimeout(sair, reduz ? 150 : 500);
    } else setTimeout(tick, reduz ? 4 : 18);
  }
  setTimeout(tick, reduz ? 100 : 1500); // entra junto com a barra (fade .sp-load)
}());

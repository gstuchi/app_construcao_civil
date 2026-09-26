/* Gestos de iPhone: arrastar a linha para apagar, puxar o sheet para fechar e
   voltar arrastando da borda. Lógica pura exportada para testes; a ligação ao
   DOM é por delegação, sem tocar nos renderizadores do app.js. */
'use strict';
(function(root){
  const LARGURA_APAGAR = 80;
  const ARRASTO_MAXIMO = 120; // a linha passa um pouco do botão, como no iOS

  /* Só decide depois de 10px; horizontal precisa predominar (diagonal é rolagem). */
  function eixo(dx, dy){
    const ax = Math.abs(dx), ay = Math.abs(dy);
    if(ax < 10 && ay < 10) return null;
    return ax > ay * 1.2 ? 'h' : 'v';
  }
  /* dx: posição final da linha (negativa = aberta para a esquerda); vx em px/ms. */
  function fimArrastoLinha(dx, vx){
    if(vx < -0.5) return 'abrir';
    if(vx > 0.5) return 'fechar';
    return -dx > LARGURA_APAGAR / 2 ? 'abrir' : 'fechar';
  }
  function fimArrastoSheet(dy, vy){
    return dy > 120 || (vy > 0.8 && dy > 30) ? 'fechar' : 'voltar';
  }
  /* No WKWebView o UIKit pode iniciar o próprio rubber-band nos primeiros ~10px, antes de eixo()
     decidir o eixo — e o touchmove seguinte às vezes já vem não-cancelable. Por isso o listener do
     sheet trava a rolagem nativa também nesse instante inicial: puxão para baixo e predominante. */
  function bloqueiaPuxada(dx, dy){
    return dy > 0 && Math.abs(dy) >= Math.abs(dx);
  }
  function fimArrastoBorda(dx, vx, largura){
    return dx > largura * 0.35 || (vx > 0.5 && dx > 40) ? 'voltar' : 'cancelar';
  }
  /* No Safari comum a borda esquerda é o "voltar" do navegador: só no app e no PWA instalado. */
  function bordaAtiva(x, classes){
    return x <= 24 && (classes.contains('nativo') || classes.contains('standalone'));
  }
  /* Com um campo em foco (usuário digitando), puxar do meio do sheet descartaria o
     formulário: aí só vale pela alça, os 32px de cima. */
  const ALCA_SHEET = 32;
  function podePuxarSheet({ scrollTop, focoEmCampo, yNoSheet }){
    if(scrollTop > 0) return false;
    return !focoEmCampo || yNoSheet <= ALCA_SHEET;
  }
  /* O voltar da borda só vale com a tela livre: nada por cima dela (sheet, diálogo,
     teclado de valor, login) e o botão de voltar à vista, não coberto. */
  function podeVoltarBorda({ sheetAberto, dialogoAberto, tecladoAberto, bloqueado, temVoltar, voltarCoberto }){
    return !sheetAberto && !dialogoAberto && !tecladoAberto && !bloqueado && !!temVoltar && !voltarCoberto;
  }

  let ligado = false;
  function iniciar(win){
    if(ligado || !win || !win.document) return;
    ligado = true;
    const doc = win.document, html = doc.documentElement;
    function registra(err){
      try{ win.OBRA_DIAG?.registra('gestos', (err && err.message) || String(err), err && err.stack); }
      catch(e){ /* diagnóstico nunca derruba o app */ }
    }
    const vibrar = () => { try{ win.OBRA_NATIVO?.vibrar?.(); }catch(err){ registra(err); } };
    const agora = () => win.performance.now();
    const semMovimento = () => !!win.matchMedia?.('(prefers-reduced-motion: reduce)').matches;

    try{
      const sheet = doc.getElementById('sheet'), backdrop = doc.getElementById('backdrop');
      const sheetAberto = () => !!(backdrop && backdrop.classList.contains('show'));

      let toque = null;   // dedo acompanhado: início, última e penúltima amostra
      let linha = null;   // { li, aberta, noBotao, movendo, vibrou }
      let puxada = null;  // { ativa }
      let borda = null;   // { tela, ativa }
      let aberta = null, topoAberta = 0; // linha que ficou aberta e onde ela estava
      let engolir = null; // toque que só fechou a linha aberta não vira clique
      const vistos = new WeakSet(); // o touchmove passa pelo #sheet e depois pelo document

      const acharToque = (lista, id) => {
        for(let i = 0; i < lista.length; i++) if(lista[i].identifier === id) return lista[i];
        return null;
      };
      /* px/ms entre os dois últimos touchmove; dedo parado antes de soltar não conta como rapidez */
      function velocidade(k){
        const dt = toque.t - toque.pt;
        if(dt <= 0 || agora() - toque.t > 100) return 0;
        return (k === 'x' ? toque.x - toque.px : toque.y - toque.py) / dt;
      }
      function alvoVoltar(){
        const nav = doc.querySelector('#navVoltar:not([hidden])');
        if(nav) return nav;
        const b = doc.querySelector('section.view.active .back');
        return b && b.getClientRects().length ? b : null;
      }
      /* Algum overlay (teclado de valor, toast, o que vier) está por cima do voltar?
         Fora da viewport (rolou para longe) não conta como coberto. */
      function coberto(el){
        const r = el.getBoundingClientRect(), x = r.left + r.width / 2, y = r.top + r.height / 2;
        if(x < 0 || y < 0 || x >= win.innerWidth || y >= win.innerHeight) return false;
        const topo = doc.elementFromPoint(x, y);
        return !!topo && !el.contains(topo);
      }

      /* ---- linha ---- */
      function abrirLinha(li){
        if(aberta && aberta !== li) fecharLinha(aberta);
        li.classList.remove('arrastando');
        li.classList.add('aberta');
        li.style.setProperty('--dx', -LARGURA_APAGAR + 'px');
        aberta = li; topoAberta = li.getBoundingClientRect().top;
      }
      function fecharLinha(li){
        li.classList.remove('aberta', 'arrastando');
        li.style.setProperty('--dx', '0px');
        if(aberta === li) aberta = null;
      }
      function moverLinha(dx){
        const l = linha, li = l.li;
        if(!l.movendo){
          l.movendo = true;
          if(!li.querySelector(':scope > .acao-apagar')){
            // o "×" continua no DOM para VoiceOver e teclado; este botão é só do gesto
            const b = doc.createElement('button');
            b.type = 'button'; b.className = 'acao-apagar'; b.textContent = 'Apagar';
            b.tabIndex = -1; b.setAttribute('aria-hidden', 'true');
            li.appendChild(b);
          }
          li.classList.add('swipe', 'arrastando');
        }
        const pos = Math.min(0, Math.max(-ARRASTO_MAXIMO, dx + (l.aberta ? -LARGURA_APAGAR : 0)));
        li.style.setProperty('--dx', pos + 'px');
        if(!l.vibrou && !l.aberta && pos <= -LARGURA_APAGAR / 2){ l.vibrou = true; vibrar(); }
        return pos;
      }
      function soltarLinha(cancelado){
        const l = linha; linha = null;
        if(!l) return;
        if(!l.movendo){
          // toque sem arrasto na linha aberta, fora do "Apagar": só fecha, como no iOS
          if(!cancelado && l.aberta && !l.noBotao){ fecharLinha(l.li); engolir = { li:l.li, ate:agora() + 400 }; }
          return;
        }
        const pos = Math.min(0, Math.max(-ARRASTO_MAXIMO, toque.x - toque.x0 + (l.aberta ? -LARGURA_APAGAR : 0)));
        const decisao = cancelado ? (l.aberta ? 'abrir' : 'fechar') : fimArrastoLinha(pos, velocidade('x'));
        if(decisao === 'abrir') abrirLinha(l.li); else fecharLinha(l.li);
      }

      /* ---- sheet ---- */
      function fecharSheet(){
        const conteudo = sheet.firstChild;
        const fim = () => {
          // se outro sheet abriu nesse meio-tempo, não é ele que o gesto fecha
          try{ if(sheetAberto() && sheet.firstChild === conteudo) win.closeSheet(); }
          finally{ sheet.style.removeProperty('--dy'); }
        };
        if(semMovimento()){ fim(); return; }
        sheet.style.setProperty('--dy', sheet.offsetHeight + 'px'); // termina de descer
        win.setTimeout(() => { try{ fim(); }catch(err){ registra(err); } }, 200);
      }
      function soltarSheet(cancelado){
        const p = puxada; puxada = null;
        if(!p || !p.ativa) return;
        sheet.classList.remove('arrastando');
        const dy = Math.max(0, toque.y - toque.y0);
        if(!cancelado && sheetAberto() && fimArrastoSheet(dy, velocidade('y')) === 'fechar'){
          vibrar();
          fecharSheet();
        }else sheet.style.removeProperty('--dy'); // volta com a transição do CSS
      }

      /* ---- borda ---- */
      function limparTela(el){
        el.classList.remove('arrastando-borda', 'soltando-borda');
        el.style.removeProperty('--dx-tela');
      }
      /* .titulo-grande mora fora de section.view (fica antes dela no markup): sem estar dentro
         da tela, não herda o --dx-tela dela, então recebe as mesmas classes/variável à parte. */
      function elementosBorda(b){ return b.titulo ? [b.tela, b.titulo] : [b.tela]; }
      function soltarBorda(cancelado){
        const b = borda; borda = null;
        if(!b || !b.ativa) return;
        const els = elementosBorda(b);
        const dx = Math.max(0, toque.x - toque.x0);
        const alvo = !cancelado && fimArrastoBorda(dx, velocidade('x'), win.innerWidth) === 'voltar' ? alvoVoltar() : null;
        if(alvo || semMovimento()){ els.forEach(limparTela); if(alvo) alvo.click(); return; }
        // anima de volta; o transform some no fim (fora do arrasto ele prenderia os position:fixed)
        for(const el of els){
          el.classList.remove('arrastando-borda');
          el.classList.add('soltando-borda');
          el.style.setProperty('--dx-tela', '0px');
        }
        win.setTimeout(() => { if(!borda || borda.tela !== b.tela) els.forEach(limparTela); }, 260);
      }

      function soltarTudo(cancelado){
        try{
          if(toque){ soltarLinha(cancelado); soltarSheet(cancelado); soltarBorda(cancelado); }
        }finally{
          toque = null; linha = null; puxada = null; borda = null;
        }
      }

      function inicio(e){
        if(e.touches.length !== 1){ soltarTudo(true); return; }
        if(toque) soltarTudo(true);
        const t = e.touches[0], alvo = e.target, t0 = agora();
        toque = { id:t.identifier, x0:t.clientX, y0:t.clientY, x:t.clientX, y:t.clientY, t:t0, px:t.clientX, py:t.clientY, pt:t0, eixo:null };
        const li = alvo && alvo.closest ? alvo.closest('li') : null;
        if(aberta && aberta !== li) fecharLinha(aberta); // tocar fora fecha a que estava aberta
        if(li && li.querySelector(':scope > .li-del'))
          linha = { li, aberta:li.classList.contains('aberta'), noBotao:!!alvo.closest('.acao-apagar'), movendo:false, vibrou:false };
        if(sheet && sheetAberto() && sheet.contains(alvo)){
          const foco = doc.activeElement;
          const focoEmCampo = !!(foco && sheet.contains(foco) && foco.matches('input,select,textarea,[contenteditable]'));
          if(podePuxarSheet({ scrollTop:sheet.scrollTop, focoEmCampo, yNoSheet:t.clientY - sheet.getBoundingClientRect().top }))
            puxada = { ativa:false };
        }
        if(bordaAtiva(t.clientX, html.classList)){
          const tela = doc.querySelector('section.view.active'), voltar = alvoVoltar();
          if(tela && podeVoltarBorda({ sheetAberto:sheetAberto(), dialogoAberto:!!doc.querySelector('dialog[open]'),
            tecladoAberto:doc.body.classList.contains('teclado-open'), bloqueado:doc.body.classList.contains('locked'),
            temVoltar:!!voltar, voltarCoberto:!!voltar && coberto(voltar) }))
            borda = { tela, titulo:doc.querySelector('.titulo-grande'), ativa:false };
        }
      }
      function movimento(e){
        if(!toque || vistos.has(e)) return;
        vistos.add(e);
        if(e.touches.length !== 1){ soltarTudo(true); return; }
        const t = acharToque(e.touches, toque.id);
        if(!t) return;
        toque.px = toque.x; toque.py = toque.y; toque.pt = toque.t;
        toque.x = t.clientX; toque.y = t.clientY; toque.t = agora();
        const dx = toque.x - toque.x0, dy = toque.y - toque.y0;
        if(!toque.eixo){
          toque.eixo = eixo(dx, dy);
          if(!toque.eixo) return;
          if(toque.eixo === 'v'){
            linha = null; borda = null;             // começou vertical: é rolagem
            if(puxada && dy <= 0) puxada = null;    // subindo: o sheet rola
          }else{
            puxada = null;
            if(borda && dx > 0) linha = null; else borda = null;
            if(linha && !linha.aberta && dx > 0) linha = null; // linha fechada não abre para a direita
          }
        }
        if(linha) moverLinha(dx);
        if(borda){
          const els = elementosBorda(borda);
          if(!borda.ativa){
            borda.ativa = true;
            for(const el of els){ el.classList.remove('soltando-borda'); el.classList.add('arrastando-borda'); }
          }
          const px = Math.max(0, dx) + 'px';
          for(const el of els) el.style.setProperty('--dx-tela', px);
        }
        if(puxada){
          if(!puxada.ativa){ puxada.ativa = true; sheet.classList.add('arrastando'); }
          sheet.style.setProperty('--dy', Math.max(0, dy) + 'px');
        }
      }
      function fim(e){
        if(!toque || !acharToque(e.changedTouches, toque.id)) return;
        soltarTudo(e.type === 'touchcancel');
      }
      const seguro = fn => e => {
        try{ fn(e); }
        catch(err){ registra(err); try{ soltarTudo(true); }catch(e2){ registra(e2); } }
      };

      const passivo = { passive:true };
      doc.addEventListener('touchstart', seguro(inicio), passivo);
      doc.addEventListener('touchmove', seguro(movimento), passivo);
      doc.addEventListener('touchend', seguro(fim), passivo);
      doc.addEventListener('touchcancel', seguro(fim), passivo);
      /* único ouvinte não passivo: só segura a rolagem enquanto o sheet está sendo puxado (ou,
         nos ~10px antes do eixo decidir, quando já dá para saber que vai puxar: ver bloqueiaPuxada) */
      if(sheet) sheet.addEventListener('touchmove', seguro(e => {
        movimento(e);
        if(!puxada || !e.cancelable) return;
        const dx = toque ? toque.x - toque.x0 : 0, dy = toque ? toque.y - toque.y0 : 0;
        if(puxada.ativa || bloqueiaPuxada(dx, dy)) e.preventDefault();
      }), { passive:false });

      // rolar (a página ou o sheet) fecha a linha aberta; tremida de poucos px não conta
      doc.addEventListener('scroll', seguro(() => {
        if(!aberta || (linha && linha.li === aberta)) return;
        if(!aberta.isConnected){ aberta = null; return; }
        if(Math.abs(aberta.getBoundingClientRect().top - topoAberta) > 8) fecharLinha(aberta);
      }), { capture:true, passive:true });

      doc.addEventListener('click', seguro(e => {
        const alvo = e.target && e.target.closest ? e.target : null;
        if(!alvo) return;
        if(engolir){
          const eng = engolir; engolir = null;
          if(agora() <= eng.ate && eng.li.contains(alvo)){ e.preventDefault(); e.stopPropagation(); return; }
        }
        const apagar = alvo.closest('.acao-apagar');
        if(apagar){
          const li = apagar.closest('li');
          e.stopPropagation();
          fecharLinha(li);
          // mesmo caminho do "×": diálogo de confirmação e fluxo de parcelas de sempre
          const del = li.querySelector(':scope > .li-del');
          if(del) del.click();
          return;
        }
        const aba = alvo.closest('button[data-tab]');
        if(aba && !aba.classList.contains('on')) vibrar(); // captura: roda antes do app.js trocar a aba
      }), true);
    }catch(err){ registra(err); }
  }

  const api = { eixo, fimArrastoLinha, fimArrastoSheet, fimArrastoBorda, bordaAtiva, podePuxarSheet, podeVoltarBorda, bloqueiaPuxada, LARGURA_APAGAR };
  if(typeof module !== 'undefined') module.exports = api;
  if(root && root.document){ api.iniciar = win => iniciar(win); root.OBRA_GESTOS = api; api.iniciar(root); }
})(typeof window !== 'undefined' ? window : null);

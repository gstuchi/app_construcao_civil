/* Retratos da pill de sincronização nos 8 combos (tema × cor × viewport) e contraste
   WCAG do texto — a pill tem fundo de vidro translúcido, então varia com a cor do skin
   (esmeralda/azul) além do tema. Precisa do servidor de tests/browser/servidor.cjs no ar.
   Uso: NODE_PATH=<cache do npx com playwright> node tests/browser/contraste.cjs [pasta] */
const { chromium } = require('playwright');
const SAIDA = process.argv[2] || '.';

const FAKE = () => {
  window.__estado = 'ocioso';
  window.__emite = (estado, code, origem) => { window.__estado = estado;
    window.dispatchEvent(new CustomEvent('cloud-estado', { detail: { estado, code: code||null, tentativa:0, origem: origem||'escrita' } })); };
  window.CLOUD = { ready: Promise.resolve(), user: () => ({ uid:'t' }), onAuth(cb){ cb({ uid:'t' }); },
    estado: () => window.__estado, watchDados(){ return () => {}; },
    saveDados(){ return new Promise(()=>{}); }, tentarDeNovo(){ return Promise.resolve(); },
    logout(){ return Promise.resolve(); }, savePushSub(){ return Promise.resolve(); }, removePushSub(){ return Promise.resolve(); } };
};

/* contraste WCAG do texto da pill contra o fundo dela */
const contraste = (a, b) => {
  const lum = c => { const [r,g,bb] = c.map(v => { v/=255; return v<=0.03928 ? v/12.92 : Math.pow((v+0.055)/1.055, 2.4); });
    return 0.2126*r + 0.7152*g + 0.0722*bb; };
  const [l1, l2] = [lum(a), lum(b)].sort((x,y)=>y-x);
  return (l1 + 0.05) / (l2 + 0.05);
};
const rgb = s => s.match(/\d+/g).slice(0,3).map(Number);
/* mesma leitura de cor, com o alfa (rgba) junto — pra compor o fundo de verdade quando ele é translúcido */
const rgba = s => { const m = s.match(/[\d.]+/g).map(Number); return [m[0], m[1], m[2], m[3]===undefined ? 1 : m[3]]; };
const misturar = (fg, fundoOpaco) => { const a = fg[3];
  return [0,1,2].map(i => fg[i]*a + fundoOpaco[i]*(1-a)); };
const hex = h => { h = h.trim().replace('#', ''); return [0, 2, 4].map(i => parseInt(h.slice(i, i + 2), 16)); };
/* WCAG: texto grande (>=24px, ou negrito >=18.66px) pede só 3:1; o resto, 4,5:1 */
const minimoContraste = (fontSizePx, fontWeight) => {
  const negrito = Number(fontWeight) >= 700;
  return (fontSizePx >= 24 || (negrito && fontSizePx >= 18.66)) ? 3 : 4.5;
};

(async () => {
  const browser = await chromium.launch();
  let falhas = 0;
  for(const tema of ['escuro', 'claro']){
    for(const skin of ['esmeralda', 'azul']){
      for(const [nome, vp] of [['mobile', { width:414, height:896 }], ['desktop', { width:1440, height:900 }]]){
        const page = await browser.newPage({ viewport: vp });
        await page.addInitScript(() => sessionStorage.setItem('splashVista','1'));
        await page.addInitScript(FAKE);
        await page.addInitScript(t => localStorage.setItem('mo_tema', t), tema);
        if(skin === 'azul') await page.addInitScript(() => localStorage.setItem('mo_skin', 'azul'));
        await page.route('**/cloud.js', r => r.fulfill({ contentType:'text/javascript', body:'' }));
        await page.goto('http://localhost:8123/index.html');
        await page.evaluate(() => { document.getElementById('auth').classList.add('hidden');
          document.body.classList.remove('locked'); db = normaliza({ obras: [] }); renderAll(); });
        /* a pílula agora tem fundo de vidro translúcido: compor sobre o --bg do body antes de medir */
        const corBody = rgba(await page.evaluate(() => getComputedStyle(document.body).backgroundColor));

        for(const estado of ['salvando', 'offline', 'erro']){
          await page.evaluate(e => window.__emite(e, 'permission-denied'), estado);
          await page.waitForTimeout(120);
          const m = await page.evaluate(() => {
            const p = document.getElementById('syncPill'), cs = getComputedStyle(p);
            const r = p.getBoundingClientRect();
            let fundo = cs.backgroundColor, no = p;
            while(/rgba\(0, 0, 0, 0\)|transparent/.test(fundo) && no.parentElement){ no = no.parentElement; fundo = getComputedStyle(no).backgroundColor; }
            return { cor: cs.color, fundo, visivel: r.width > 0 && r.height > 0 && cs.visibility === 'visible', texto: p.textContent.trim() };
          });
          const f = rgba(m.fundo);
          const c = contraste(rgb(m.cor), f[3] < 1 ? misturar(f, corBody) : f.slice(0,3));
          const ok = m.visivel && c >= 4.5;
          if(!ok) falhas++;
          console.log(`${ok?'ok   ':'FALHA'} - ${tema}/${skin}/${nome}/${estado}: contraste ${c.toFixed(2)} · "${m.texto}" · ${m.cor} sobre ${m.fundo}`);
        }
        await page.evaluate(() => window.__emite('erro', 'permission-denied'));
        await page.screenshot({ path: `${SAIDA}/pill-${tema}-${skin}-${nome}.png`, clip: { x:0, y:0, width: vp.width, height: 120 } });
        await page.close();
      }
    }
  }
  /* contraste dos 4 combos tema×skin a 390x844 (achados da revisão final): primário, tingido,
     tingido destrutivo e a aba ativa da nav.tabs — esta com fundo translúcido (--barra), então
     entra composta sobre o --bg do body antes de medir. */
  for(const tema of ['escuro', 'claro']){
    for(const skin of ['esmeralda', 'azul']){
      const page = await browser.newPage({ viewport: { width:390, height:844 } });
      await page.addInitScript(() => sessionStorage.setItem('splashVista','1'));
      await page.addInitScript(FAKE);
      await page.addInitScript(t => localStorage.setItem('mo_tema', t), tema);
      if(skin === 'azul') await page.addInitScript(() => localStorage.setItem('mo_skin', 'azul'));
      await page.route('**/cloud.js', r => r.fulfill({ contentType:'text/javascript', body:'' }));
      await page.goto('http://localhost:8123/index.html');
      await page.evaluate(() => { document.getElementById('auth').classList.add('hidden');
        document.body.classList.remove('locked'); db = normaliza({ obras: [] }); renderAll();
        showView('ajustes'); renderAjustes(); });

      const corBase = rgba(await page.evaluate(() => getComputedStyle(document.body).backgroundColor));
      const alvos = [
        ['#ajAddTopico', '.btn.primary'],
        ['#ajJson', '.btn.ghost'],
        ['#ajApagar', 'ghost destrutivo'],
      ];
      const dados = await page.evaluate(sels => sels.map(([s]) => {
        const el = document.querySelector(s);
        if(!el) return null;
        const cs = getComputedStyle(el);
        // mesmo helper do laço da pill: sobe até achar o fundo de verdade (botão/label não têm bg próprio)
        let fundo = cs.backgroundColor, no = el;
        while(/rgba\(0, 0, 0, 0\)|transparent/.test(fundo) && no.parentElement){ no = no.parentElement; fundo = getComputedStyle(no).backgroundColor; }
        return { cor: cs.color, fundo, fontSize: parseFloat(cs.fontSize), fontWeight: cs.fontWeight };
      }), alvos);

      for(let i = 0; i < alvos.length; i++){
        const [sel, nome] = alvos[i], d = dados[i];
        if(!d){ falhas++; console.log(`FALHA - 390x844/${tema}/${skin}/${nome}: elemento "${sel}" não encontrado`); continue; }
        const fg = rgba(d.cor);
        const fundo = rgba(d.fundo)[3] < 1 ? misturar(rgba(d.fundo), corBase) : rgba(d.fundo).slice(0,3);
        const c = contraste(fg.slice(0,3), fundo);
        const minimo = minimoContraste(d.fontSize, d.fontWeight);
        const ok = c >= minimo;
        if(!ok) falhas++;
        console.log(`${ok?'ok   ':'FALHA'} - 390x844/${tema}/${skin}/${nome}: contraste ${c.toFixed(2)} (min ${minimo}) · ${d.cor} sobre ${d.fundo}`);
      }

      /* cápsula de abas (Liquid Glass): o rótulo inativo fica sobre o --vidro, translúcido, que
         passa por cima do fundo do app, dos grupos e do card de saldo (pior caso); a aba ativa
         fica sobre a lente opaca (--brand-soft). */
      const abas = await page.evaluate(() => {
        const raiz = getComputedStyle(document.documentElement);
        return {
          vidro: getComputedStyle(document.querySelector('nav.tabs')).backgroundColor,
          inativa: getComputedStyle(document.querySelector('nav.tabs button:not(.on)')).color,
          ativa: getComputedStyle(document.querySelector('nav.tabs button.on')).color,
          lente: raiz.getPropertyValue('--brand-soft'),
          luz: raiz.getPropertyValue('--vidro-luz'),
          fundos: ['--bg', '--surface-solid', '--saldo-a', '--saldo-b'].map(v => [v, raiz.getPropertyValue(v)]),
        };
      });
      // o brightness() do filtro (--vidro-luz) age sobre o que passa por baixo, antes do preenchimento
      const luz = parseFloat(abas.luz) || 1;
      const sob = cor => hex(cor).map(v => Math.min(255, v * luz));
      for(const [nomeFundo, cor] of abas.fundos){
        const c = contraste(rgba(abas.inativa).slice(0, 3), misturar(rgba(abas.vidro), sob(cor)));
        const ok = c >= 4.5; if(!ok) falhas++;
        console.log(`${ok?'ok   ':'FALHA'} - 390x844/${tema}/${skin}/aba inativa sobre ${nomeFundo}: contraste ${c.toFixed(2)} (min 4.5)`);
      }
      const cAtiva = contraste(rgba(abas.ativa).slice(0, 3), hex(abas.lente));
      if(cAtiva < 4.5) falhas++;
      console.log(`${cAtiva >= 4.5 ? 'ok   ' : 'FALHA'} - 390x844/${tema}/${skin}/aba ativa sobre a lente: contraste ${cAtiva.toFixed(2)} (min 4.5)`);

      await page.close();
    }
  }

  await browser.close();
  console.log(falhas ? `\n${falhas} FALHA(S)` : '\nTodos os combos legíveis');
  process.exit(falhas ? 1 : 0);
})();

/* Retratos da pill de sincronização nos 4 combos (tema × viewport) e contraste
   WCAG do texto. Precisa do servidor de tests/browser/servidor.cjs no ar.
   Uso: NODE_PATH=<cache do npx com playwright> node tests/browser/contraste.cjs [pasta] */
const { chromium } = require('playwright');
const SAIDA = process.argv[2] || '.';

const FAKE = () => {
  window.__estado = 'ocioso';
  const sessao = Object.freeze({ uid:'t', geracao:1 });
  window.__emite = (estado, code, origem) => { window.__estado = estado;
    window.dispatchEvent(new CustomEvent('cloud-estado', { detail: { estado, code: code||null, tentativa:0, origem: origem||'escrita' } })); };
  window.CLOUD = { ready: Promise.resolve(), user: () => ({ uid:'t' }), sessao: () => sessao,
    sessaoAtiva: candidata => candidata === sessao, onAuth(cb){ cb({ uid:'t' }); },
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

(async () => {
  const browser = await chromium.launch();
  let falhas = 0;
  for(const tema of ['escuro', 'claro']){
    for(const [nome, vp] of [['mobile', { width:414, height:896 }], ['desktop', { width:1440, height:900 }]]){
      const page = await browser.newPage({ viewport: vp });
      await page.addInitScript(() => sessionStorage.setItem('splashVista','1'));
      await page.addInitScript(FAKE);
      await page.addInitScript(t => localStorage.setItem('mo_tema', t), tema);
      await page.route('**/cloud.js', r => r.fulfill({ contentType:'text/javascript', body:'' }));
      await page.goto('http://localhost:8123/index.html');
      await page.evaluate(() => { document.getElementById('auth').classList.add('hidden');
        document.body.classList.remove('locked'); db = normaliza({ obras: [] }); renderAll(); });

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
        const c = contraste(rgb(m.cor), rgb(m.fundo));
        const ok = m.visivel && c >= 4.5;
        if(!ok) falhas++;
        console.log(`${ok?'ok   ':'FALHA'} - ${tema}/${nome}/${estado}: contraste ${c.toFixed(2)} · "${m.texto}" · ${m.cor} sobre ${m.fundo}`);
      }
      await page.evaluate(() => window.__emite('erro', 'permission-denied'));
      await page.screenshot({ path: `${SAIDA}/pill-${tema}-${nome}.png`, clip: { x:0, y:0, width: vp.width, height: 120 } });
      await page.close();
    }
  }
  await browser.close();
  console.log(falhas ? `\n${falhas} FALHA(S)` : '\nTodos os combos legíveis');
  process.exit(falhas ? 1 : 0);
})();

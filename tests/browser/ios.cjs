/* Ponta a ponta: o app parece e se comporta como um app iOS no celular.
   Contexto 390x844 com toque real (hasTouch/isMobile), window.CLOUD e window.Capacitor
   falsos (padrão de nativo.cjs). Gestos de arrastar são toque sintético de verdade
   (new Touch + new TouchEvent), não eventos fabricados de alto nível.
   Rode com node tests/browser/servidor.cjs no ar. */
const assert = require('node:assert/strict');
const path = require('node:path');
const os = require('node:os');
const { chromium } = require('playwright');

const TOPICOS_TESTE = ['fundacao','ferragem','estrutura','alvenaria','telhado','eletrica',
  'hidraulica','revest','pintura','acabamento','matextra','maoobra'];
const gastos = TOPICOS_TESTE.map((topico, i) => ({
  id: 'g' + i,
  valor: 500 + i * 137.45,
  topico,
  descricao: 'Item ' + (i + 1),
  data: `2026-${String((i % 12) + 1).padStart(2, '0')}-10`,
  pagamento: i % 3 === 0 ? 'cartao' : 'pix',
}));
const OBRAS = { config: { taxaMensal: 1, topicosCustom: [] },
  obras: [{ id:'o1', nome:'Casa Azul', fase:'construcao', dataInicio:'2026-01-01',
    areaM2:80, valorEstimadoVenda:500000, gastos }] };

async function abrir(browser, { nativo = false, viewport = { width:390, height:844 }, isMobile = true, hasTouch = true } = {}){
  const ctx = await browser.newContext({
    viewport, isMobile, hasTouch, deviceScaleFactor:3,
    serviceWorkers:'allow',
  });
  await ctx.route('**/cloud.js', r => r.fulfill({ contentType:'text/javascript', body:'' }));
  if(nativo){
    // no aparelho a CSP vem da <meta> do www/ (já libera produção); o servidor de teste serve a CSP web,
    // que bloqueia o fetch de versao.json — sem isso o app registra uma violação de CSP inofensiva.
    await ctx.route('http://localhost:8123/', async r => {
      const resp = await r.fetch(); const h = resp.headers();
      h['content-security-policy'] = h['content-security-policy'].replace("connect-src 'self'", "connect-src 'self' https://app-construcao-civil.vercel.app");
      await r.fulfill({ response:resp, headers:h });
    });
  }
  await ctx.route('https://**/*', r => r.abort());
  await ctx.addInitScript(([nativo, obras]) => {
    sessionStorage.setItem('splashVista', '1');
    window.errosPagina = [];
    addEventListener('error', e => errosPagina.push(e.message));
    addEventListener('securitypolicyviolation', e => errosPagina.push('csp:' + e.violatedDirective));
    window.CLOUD = { user:()=>({ uid:'teste', email:'t@t.com', emailVerificado:true }), onAuth:cb=>cb({ uid:'teste' }),
      watchDados:cb=>{ setTimeout(()=>cb(JSON.parse(JSON.stringify(obras)), { fromCache:false, pendingWrites:false, localDirty:false })); return ()=>{}; },
      saveDados:()=>Promise.resolve(), estado:()=>'ocioso', ready:Promise.resolve(), tentarDeNovo:()=>Promise.resolve(),
      savePushSub:()=>Promise.resolve(), removePushSub:()=>Promise.resolve() };
    if(!nativo) return;
    const plugin = nome => new Proxy({}, { get:(_, metodo) => {
      if(metodo === 'then') return undefined;
      if(metodo === 'addListener') return () => Promise.resolve({ remove(){} });
      return async () => undefined;
    } });
    const nomes = ['App','Share','Filesystem','Haptics','StatusBar','SplashScreen','FirebaseMessaging'];
    window.Capacitor = { isNativePlatform:()=>true, getPlatform:()=>'ios', Plugins:Object.fromEntries(nomes.map(n => [n, plugin(n)])) };
  }, [nativo, OBRAS]);
  const page = await ctx.newPage();
  await page.goto('http://localhost:8123');
  await page.waitForFunction(() => typeof db !== 'undefined' && db.obras.length === 1);
  return { ctx, page };
}

/* Sintetiza um toque de verdade (Touch/TouchEvent), não um evento de alto nível.
   Roda dentro da página via locator.evaluate: "el" é o alvo, "pontos" a trilha do dedo. */
async function gesto(el, pontos){
  const id = 1;
  const disparar = (tipo, p) => {
    const t = new Touch({ identifier:id, target:el, clientX:p.x, clientY:p.y });
    const lista = (tipo === 'touchend' || tipo === 'touchcancel') ? [] : [t];
    el.dispatchEvent(new TouchEvent(tipo, { touches:lista, targetTouches:lista, changedTouches:[t], bubbles:true, cancelable:true }));
  };
  disparar('touchstart', pontos[0]);
  for(let i = 1; i < pontos.length; i++){
    await new Promise(r => setTimeout(r, 16));
    disparar('touchmove', pontos[i]);
  }
  await new Promise(r => setTimeout(r, 16));
  disparar('touchend', pontos[pontos.length - 1]);
}

/* Todo input/select/textarea visível com fonte >=16px (zoom automático do iOS) e
   documento sem transbordo lateral (scrollWidth === largura da tela, 390). */
async function checarTela(page, nome){
  const { ruins, scrollWidth } = await page.evaluate(() => {
    const els = [...document.querySelectorAll('input,select,textarea')].filter(e => e.getClientRects().length > 0);
    const ruins = els.filter(e => parseFloat(getComputedStyle(e).fontSize) < 16)
      .map(e => e.id || e.name || e.className || e.tagName);
    return { ruins, scrollWidth: document.documentElement.scrollWidth };
  });
  assert.deepEqual(ruins, [], `fonte < 16px em "${nome}": ${ruins.join(', ')}`);
  assert.equal(scrollWidth, 390, `scrollWidth != 390 em "${nome}" (veio ${scrollWidth})`);
}

(async () => {
  const browser = await chromium.launch();
  try{
    /* ---- nativo: telas, barras, globo e gestos ---- */
    {
      const { ctx, page } = await abrir(browser, { nativo:true });

      assert.equal(await page.evaluate(() => document.documentElement.classList.contains('nativo')), true,
        'html.nativo precisa estar marcado no app nativo');

      /* 1+2: fonte >=16px e sem transbordo em cada tela */
      await page.evaluate(() => { showView('inicio'); renderAll(); });
      await checarTela(page, 'inicio');
      await page.evaluate(() => openObra('o1'));
      await checarTela(page, 'obra aberta');
      await page.evaluate(() => { showView('simula'); renderSimula(); });
      await checarTela(page, 'simula');
      await page.evaluate(() => { showView('ajustes'); renderAjustes(); });
      await checarTela(page, 'ajustes');

      /* sheet de novo gasto aberto pelo FAB: volta pra obra (só lá o FAB aparece) */
      await page.evaluate(() => openObra('o1'));
      await page.locator('#fab').click();
      await page.locator('.valor-key[data-k="5"]').click();
      await page.locator('.valor-ok').click();
      await page.waitForSelector('#backdrop.show');
      await checarTela(page, 'sheet de novo gasto (FAB)');
      await page.locator('#cCancel').click();
      await page.locator('#backdrop').waitFor({ state:'hidden' });

      /* 4: título grande colapsa ao rolar até o fim, volta ao subir */
      await page.evaluate(() => window.scrollTo(0, 100000));
      await page.waitForFunction(() => document.querySelector('header.top').classList.contains('colapsada'));
      assert.equal((await page.locator('#navTitulo').textContent()).trim(), 'Casa Azul',
        'título pequeno mostra o nome da obra quando a barra colapsa');
      await page.evaluate(() => window.scrollTo(0, 0));
      await page.waitForFunction(() => !document.querySelector('header.top').classList.contains('colapsada'));

      /* capturas: escuro (padrão) e claro, obra aberta com a lista de gastos */
      await page.screenshot({ path: path.join(os.tmpdir(), 'custta-ios-obra-escuro.png') });
      await page.evaluate(() => aplicaTema(true));
      await page.waitForTimeout(150);
      await page.screenshot({ path: path.join(os.tmpdir(), 'custta-ios-obra-claro.png') });
      await page.evaluate(() => aplicaTema(false));
      await page.waitForTimeout(150);

      /* 5: globo pausa no scroll, retoma ~600ms depois */
      await page.evaluate(() => window.dispatchEvent(new Event('scroll')));
      assert.equal(await page.evaluate(() => __globeEstado().rodando), false, 'globo deve pausar logo após o scroll');
      await page.waitForTimeout(600);
      assert.equal(await page.evaluate(() => __globeEstado().rodando), true, 'globo deve retomar ~400ms depois de parado');

      /* 6: arrastar para apagar (toque sintético de verdade) */
      const linha1 = page.locator('.gasto-row').first();
      const box1 = await linha1.boundingBox();
      const y1 = box1.y + box1.height / 2;
      await linha1.evaluate(gesto, [{ x:300, y:y1 }, { x:270, y:y1 }, { x:240, y:y1 }, { x:210, y:y1 }, { x:180, y:y1 }]);
      assert.equal(await linha1.evaluate(el => el.classList.contains('aberta')), true, 'linha deve ficar aberta após o arrasto');
      assert.equal(await linha1.locator('.acao-apagar').isVisible(), true, 'botão "Apagar" deve aparecer');

      await linha1.locator('.acao-apagar').click();
      const dlg = page.locator('dialog.confirma-dialog');
      await dlg.waitFor({ state:'visible' });
      assert.equal((await dlg.locator('.confirma-msg').textContent()).trim(), 'Excluir este gasto?');
      const antes = await page.evaluate(() => obraById('o1').gastos.length);
      await dlg.locator('[data-acao=confirmar]').click();
      await page.waitForFunction(n => obraById('o1').gastos.length === n - 1, antes);

      /* abre outra linha e rola de verdade (não dispara evento sintético): deve fechar */
      const linha2 = page.locator('.gasto-row').first();
      const box2 = await linha2.boundingBox();
      const y2 = box2.y + box2.height / 2;
      await linha2.evaluate(gesto, [{ x:300, y:y2 }, { x:270, y:y2 }, { x:240, y:y2 }, { x:210, y:y2 }, { x:180, y:y2 }]);
      assert.equal(await page.locator('li.aberta').count(), 1, 'deve haver uma linha aberta antes de rolar');
      await page.evaluate(() => window.scrollBy(0, 200));
      await page.waitForFunction(() => document.querySelectorAll('li.aberta').length === 0, null, { timeout:2000 });
      await page.evaluate(() => window.scrollTo(0, 0));

      /* 7: puxar o sheet pela alça fecha (arrasto real, não o topo de um campo focado) */
      await page.locator('#fab').click();
      await page.locator('.valor-key[data-k="5"]').click();
      await page.locator('.valor-ok').click();
      await page.waitForSelector('#backdrop.show');
      const sheetBox = await page.locator('#sheet').boundingBox();
      const sx = sheetBox.x + sheetBox.width / 2, sy0 = sheetBox.y + 10; // dentro dos 32px da alça
      await page.locator('#sheet').evaluate(gesto, [{ x:sx, y:sy0 }, { x:sx, y:sy0 + 50 }, { x:sx, y:sy0 + 100 }, { x:sx, y:sy0 + 150 }, { x:sx, y:sy0 + 200 }]);
      await page.waitForFunction(() => !document.getElementById('backdrop').classList.contains('show'), null, { timeout:2000 });

      /* 8: voltar arrastando da borda esquerda (nativo) */
      assert.equal(await page.evaluate(() => document.querySelector('section.view.active').id), 'v-obra');
      await page.evaluate(() => window.scrollTo(0, 0));
      const secao = page.locator('section.view.active');
      await secao.evaluate(gesto, [{ x:5, y:400 }, { x:65, y:400 }, { x:125, y:400 }, { x:185, y:400 }, { x:250, y:400 }]);
      await page.waitForFunction(() => document.querySelector('section.view.active').id === 'v-inicio',
        null, { timeout:2000 });

      /* 9: sem erro de página nem violação de CSP */
      assert.deepEqual(await page.evaluate(() => errosPagina), []);

      await ctx.close();
    }

    /* ---- web comum (sem nativo/standalone): a borda é o "voltar" do navegador, o app não intercepta ---- */
    {
      const { ctx, page } = await abrir(browser, { nativo:false });
      await page.evaluate(() => openObra('o1'));
      assert.equal(await page.evaluate(() => document.querySelector('section.view.active').id), 'v-obra');
      const secao = page.locator('section.view.active');
      await secao.evaluate(gesto, [{ x:5, y:400 }, { x:65, y:400 }, { x:125, y:400 }, { x:185, y:400 }, { x:250, y:400 }]);
      await page.waitForTimeout(300);
      assert.equal(await page.evaluate(() => document.querySelector('section.view.active').id), 'v-obra',
        'sem nativo/standalone o gesto de borda não deve voltar a tela (é o "voltar" do navegador)');
      assert.deepEqual(await page.evaluate(() => errosPagina), []);
      await ctx.close();
    }

    /* ---- desktop (>=900px): nada do chrome de celular vaza, texto da lista continua selecionável ---- */
    {
      const { ctx, page } = await abrir(browser, { viewport: { width:1280, height:800 }, isMobile:false, hasTouch:false });
      const r = await page.evaluate(() => {
        const li = document.querySelector('ul.list li');
        return {
          selecionavel: li && getComputedStyle(li).userSelect !== 'none',
          tituloGrandeVisivel: getComputedStyle(document.getElementById('tituloGrande')).display !== 'none',
          navVoltarVisivel: getComputedStyle(document.getElementById('navVoltar')).display !== 'none',
          sideVisivel: getComputedStyle(document.querySelector('.side')).display !== 'none',
          scrollWidth: document.documentElement.scrollWidth,
        };
      });
      assert.equal(r.selecionavel, true, 'no desktop, o texto de ul.list li deve continuar selecionável');
      assert.equal(r.tituloGrandeVisivel, false, '#tituloGrande é só do celular; não deve aparecer no desktop');
      assert.equal(r.navVoltarVisivel, false, '#navVoltar é só do celular; não deve aparecer no desktop');
      assert.equal(r.sideVisivel, true, 'aside.side (nav do desktop) deve estar visível');
      assert.equal(r.scrollWidth, 1280, `scrollWidth != 1280 no desktop (veio ${r.scrollWidth})`);
      await ctx.close();
    }

    console.log('ok - ios');
  }finally{ await browser.close(); }
})().catch(err => { console.error(err); process.exitCode = 1; });

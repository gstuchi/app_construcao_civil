/* Título do login escrito à mão (.logo-escrito): começa só com a tela de entrada à vista,
   depois da abertura; termina igual ao logo parado (nenhum pedaço de letra fica de fora);
   recomeça quando a pessoa sai da conta; não anima com "reduzir movimento"; e no app do
   iPhone vibra uma vez, no carimbo do ponto. Sem contas nem rede: CLOUD é stub. */
const assert = require('node:assert/strict');
const { chromium } = require('playwright');

const URL = 'http://localhost:8123';

async function abrir(browser, { nativo = false, abertura = false, reduzir = false } = {}){
  const ctx = await browser.newContext({ serviceWorkers:'block', viewport:{ width:393, height:852 }, deviceScaleFactor:2,
    reducedMotion: reduzir ? 'reduce' : 'no-preference' });
  await ctx.route('**/cloud.js', r => r.fulfill({ contentType:'text/javascript', body:'' }));
  await ctx.route('https://**/*', r => r.abort());
  await ctx.addInitScript(([nativo, abertura]) => {
    if(!abertura) sessionStorage.setItem('splashVista', '1');
    window.errosPagina = [];
    addEventListener('error', e => errosPagina.push(e.message));
    addEventListener('securitypolicyviolation', e => errosPagina.push('csp:' + e.violatedDirective));
    window.CLOUD = { user:()=>null, onAuth:cb => { window.__auth = cb; cb(null); }, estado:()=>'ocioso', ready:Promise.resolve() };
    if(!nativo) return;
    window.chamadasNativas = [];
    const plugin = nome => new Proxy({}, { get:(_, metodo) => {
      if(metodo === 'then') return undefined;
      if(metodo === 'addListener') return () => Promise.resolve({ remove(){} });
      return async a => { chamadasNativas.push([nome, metodo, a]); };
    } });
    const nomes = ['App','Share','Filesystem','Haptics','StatusBar','SplashScreen','FirebaseMessaging'];
    window.Capacitor = { isNativePlatform:()=>true, getPlatform:()=>'ios', Plugins:Object.fromEntries(nomes.map(n => [n, plugin(n)])) };
  }, [nativo, abertura]);
  const page = await ctx.newPage();
  await page.goto(URL);
  await page.waitForSelector('#fLogin', { state:'visible' });
  return { ctx, page };
}

const rodando = page => page.evaluate(() =>
  document.querySelector('.logo-escrito').getAnimations({ subtree:true }).filter(a => a.playState === 'running').length);
const terminar = page => page.evaluate(() =>
  Promise.all(document.querySelector('.logo-escrito').getAnimations({ subtree:true }).map(a => a.finished)));

(async()=>{
  const browser = await chromium.launch();
  try{
    { // sem abertura: escreve logo ao abrir, e o fim é o logo parado
      const { ctx, page } = await abrir(browser);
      assert.equal(await page.getByRole('img', { name:'custta.' }).count(), 1, 'o título continua sendo lido como "custta."');
      assert.ok(await rodando(page) >= 9, 'a escrita começa com a tela de entrada à vista');
      await terminar(page);
      const animado = await page.locator('.logo-escrito').screenshot();
      await page.evaluate(() => document.querySelector('.logo-escrito').classList.remove('escrevendo'));
      const parado = await page.locator('.logo-escrito').screenshot();
      assert.ok(animado.equals(parado), 'o fim da escrita é idêntico ao logo parado');

      // sair da conta: a tela de entrada volta e a escrita recomeça
      await page.evaluate(() => window.__auth({ uid:'u' }));
      await page.waitForSelector('#auth', { state:'hidden' });
      await page.evaluate(() => window.__auth(null));
      await page.waitForSelector('#fLogin', { state:'visible' });
      assert.ok(await rodando(page) >= 9, 'a escrita recomeça quando a tela de entrada volta');
      assert.deepEqual(await page.evaluate(() => errosPagina), [], 'nenhum erro nem violação de CSP');
      await ctx.close();
      console.log('ok - escreve com a tela de entrada à vista, termina igual ao logo parado e recomeça ao sair');
    }
    { // com abertura: espera ela sair
      const { ctx, page } = await abrir(browser, { abertura:true });
      assert.equal(await page.locator('#splash').count(), 1, 'a abertura está na tela');
      assert.equal(await rodando(page), 0, 'não escreve escondido atrás da abertura');
      await page.waitForSelector('#splash', { state:'detached', timeout:12000 });
      await page.waitForFunction(() => document.querySelector('.logo-escrito').getAnimations({ subtree:true })
        .some(a => a.playState === 'running'), null, { timeout:3000 });
      await ctx.close();
      console.log('ok - na primeira abertura, a escrita espera a abertura sair');
    }
    { // reduzir movimento: logo pronto, sem animação nem vibração
      const { ctx, page } = await abrir(browser, { reduzir:true, nativo:true });
      assert.equal(await rodando(page), 0, 'com "reduzir movimento" o logo aparece pronto');
      await page.waitForTimeout(3500);
      assert.equal(await page.evaluate(() => chamadasNativas.filter(c => c[0] === 'Haptics').length), 0, 'sem vibração');
      await ctx.close();
      console.log('ok - com "reduzir movimento" o logo aparece pronto, sem vibrar');
    }
    { // app do iPhone: uma vibração leve no carimbo do ponto
      const { ctx, page } = await abrir(browser, { nativo:true });
      await terminar(page);
      await page.waitForTimeout(400);
      const vibracoes = await page.evaluate(() => chamadasNativas.filter(c => c[0] === 'Haptics'));
      assert.deepEqual(vibracoes, [['Haptics', 'impact', { style:'LIGHT' }]], 'uma vibração leve no carimbo');
      await ctx.close();
      console.log('ok - no app, uma vibração leve quando o ponto carimba');
    }
  }finally{ await browser.close(); }
})().catch(err => { console.error(err); process.exit(1); });

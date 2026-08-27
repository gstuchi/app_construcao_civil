/* Dirige o app real no Chromium e exercita a pill de sincronização, os toasts e
   o anel de diagnóstico. O Firebase é trocado por um CLOUD controlável: o alvo
   aqui é o comportamento da TELA. A fila de escrita em si tem teste próprio,
   sem browser, em tests/fila.test.mjs.

   Precisa do servidor de tests/browser/servidor.cjs no ar.
   Uso: NODE_PATH=<cache do npx com playwright> node tests/browser/sync.cjs [png] */
const { chromium } = require('playwright');

const FAKE_CLOUD = () => {
  window.__espera = [];        // {resolve,reject} da escrita em voo
  window.__estado = 'ocioso';
  const emite = (estado, code, origem) => {
    window.__estado = estado;
    window.dispatchEvent(new CustomEvent('cloud-estado', { detail: { estado, code: code || null, tentativa: 0, origem: origem || 'escrita' } }));
  };
  window.__emite = emite;
  window.CLOUD = {
    ready: Promise.resolve(),
    user: () => ({ uid: 'teste', email: 'teste@exemplo.com' }),
    onAuth(cb){ window.__authCb = cb; cb({ uid: 'teste', email: 'teste@exemplo.com' }); },
    estado: () => window.__estado,
    temPendencia: () => window.__espera.length > 0,
    watchDados(){ return () => {}; },
    saveDados(){
      emite('salvando');
      const p = new Promise((resolve, reject) => window.__espera.push({ resolve, reject }));
      p.catch(()=>{});
      return p;
    },
    tentarDeNovo(){ emite('salvando'); return Promise.resolve(); },
    logout(){ return Promise.resolve(); },
    savePushSub(){ return Promise.resolve(); },
    removePushSub(){ return Promise.resolve(); },
  };
};

const pill = async page => page.evaluate(() => {
  const p = document.getElementById('syncPill');
  return { escondida: p.classList.contains('hidden'), erro: p.classList.contains('erro'), texto: p.textContent.trim() };
});
const toasts = async page => page.$$eval('#toastWrap .toast', ns => ns.map(n => n.textContent.trim()));

let falhas = 0;
function checa(nome, ok, detalhe){
  console.log((ok ? 'ok   - ' : 'FALHA- ') + nome + (ok ? '' : '  <<< ' + JSON.stringify(detalhe)));
  if(!ok) falhas++;
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 414, height: 896 } });
  page.on('pageerror', e => console.log('  [erro de página]', e.message));

  await page.addInitScript(() => sessionStorage.setItem('splashVista', '1'));
  await page.addInitScript(FAKE_CLOUD);
  // o cloud.js real é módulo e carrega DEPOIS dos scripts clássicos: sem bloquear,
  // ele substitui o duplê pelo Firebase de verdade e a tela trava sem login
  await page.route('**/cloud.js', r => r.fulfill({ contentType: 'text/javascript', body: '' }));
  await page.goto('http://localhost:8123/index.html');
  await page.evaluate(() => {
    document.getElementById('auth').classList.add('hidden');
    document.body.classList.remove('locked');
    db = normaliza({ obras: [{ id: 'o1', nome: 'Casa Alphaville', fase: 'construcao',
      dataInicio: '2026-01-10', gastos: [{ id: 'g1', valor: 5000, topico: 'estrutura',
      descricao: 'Ferro', data: '2026-02-01', pagamento: 'pix' }] }] });
    renderAll();
  });

  checa('pill começa escondida', (await pill(page)).escondida, await pill(page));

  /* 1. Escrita que não responde (offline): aviso de "salvo no aparelho" em 600ms */
  await page.evaluate(() => { salvarComAviso('Gasto lançado com sucesso'); });
  let p = await pill(page);
  checa('pill mostra "Salvando…" durante a escrita', !p.escondida && /Salvando/.test(p.texto), p);
  await page.waitForTimeout(900);
  let t = await toasts(page);
  checa('sem resposta do servidor, avisa que salvou no aparelho',
    t.some(x => /Salvo no aparelho/.test(x)) && !t.some(x => /sucesso/.test(x)), t);

  /* 2. Servidor confirma: aí sim "sucesso" */
  await page.evaluate(() => window.__espera.splice(0).forEach(f => f.resolve()));
  await page.evaluate(() => window.__emite('ocioso'));
  await page.waitForTimeout(200);
  checa('pill some quando o servidor confirma', (await pill(page)).escondida, await pill(page));

  await page.evaluate(() => { document.getElementById('toastWrap').innerHTML = ''; });
  await page.evaluate(() => { salvarComAviso('Gasto lançado com sucesso'); setTimeout(()=>window.__espera.splice(0).forEach(f=>f.resolve()), 50); });
  await page.waitForTimeout(400);
  t = await toasts(page);
  checa('com servidor rápido, mostra sucesso e não mostra o aviso local',
    t.some(x => /sucesso/.test(x)) && !t.some(x => /Salvo no aparelho/.test(x)), t);

  /* 3. Falha terminal: pill de erro, clicável, não some sozinha */
  await page.evaluate(() => window.__emite('erro', 'permission-denied'));
  await page.waitForTimeout(100);
  p = await pill(page);
  checa('falha terminal mostra pill de erro', !p.escondida && p.erro && /Não salvou/.test(p.texto), p);
  await page.waitForTimeout(2500);
  checa('pill de erro NÃO some sozinha', !(await pill(page)).escondida, await pill(page));
  await page.click('#syncPill');
  await page.waitForTimeout(200);
  checa('clicar na pill de erro dispara nova tentativa', !(await pill(page)).erro, await pill(page));

  /* 4. Sem conexão */
  await page.evaluate(() => window.__emite('offline'));
  await page.waitForTimeout(100);
  p = await pill(page);
  checa('pill mostra "Sem conexão"', !p.escondida && /Sem conexão/.test(p.texto), p);

  /* 5. Erro de leitura vira aviso visível */
  await page.evaluate(() => { document.getElementById('toastWrap').innerHTML = ''; });
  await page.evaluate(() => { window.__ultimo = 0; });
  await page.waitForTimeout(31000); // a janela anti-spam do toast é de 30s
  await page.evaluate(() => window.__emite('erro', 'permission-denied', 'leitura'));
  await page.waitForTimeout(300);
  t = await toasts(page);
  checa('erro de leitura avisa o usuário', t.some(x => /ler seus dados/.test(x)), t);

  /* 6. Anel de diagnóstico registra erro inesperado */
  await page.evaluate(() => { setTimeout(() => { throw new Error('explosao de teste'); }, 0); });
  await page.waitForTimeout(300);
  const diag = await page.evaluate(() => window.OBRA_DIAG.erros().map(e => e.msg));
  checa('erro inesperado entra no anel de diagnóstico', diag.some(m => /explosao de teste/.test(m)), diag);

  /* 7. Desktop: a pill não quebra o cabeçalho */
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.evaluate(() => window.__emite('salvando'));
  await page.waitForTimeout(200);
  const caixa = await page.evaluate(() => {
    const r = document.getElementById('syncPill').getBoundingClientRect();
    return { largura: r.width, altura: r.height, dentro: r.right <= window.innerWidth };
  });
  checa('pill cabe no cabeçalho do desktop', caixa.largura > 60 && caixa.altura > 20 && caixa.dentro, caixa);
  await page.screenshot({ path: process.argv[2] || 'pill-desktop.png' });

  await browser.close();
  console.log(falhas ? `\n${falhas} FALHA(S)` : '\nTudo passou');
  process.exit(falhas ? 1 : 0);
})();

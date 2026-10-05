/* Mensagens do login quando o Firebase recusa: cada formulário mostra o texto do
   mapa (tests/cadastro.test.cjs) para a tela certa — o bloqueio da conta só ensina
   a redefinir a senha no login. Sem contas ou serviços externos: CLOUD é stub e o
   código do erro vem de window.__erro. */
const assert=require('node:assert/strict');
const {chromium}=require('playwright');

const BLOQUEIO_LOGIN='Muitas tentativas. Espere alguns minutos ou redefina a senha em "Esqueci minha senha".';
const MUITAS='Muitas tentativas. Espere um pouco.';
const COTA="auth/quota-exceeded-for-quota-metric-'queries'";

(async()=>{
  const browser=await chromium.launch();
  try{
    const ctx=await browser.newContext({serviceWorkers:'block'});
    await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
    await ctx.route('https://**/*',r=>r.abort());
    await ctx.addInitScript(()=>{
      sessionStorage.setItem('splashVista','1');
      const recusa=()=>Promise.reject(Object.assign(new Error('recusado'),{code:window.__erro}));
      window.CLOUD={user:()=>null,onAuth:cb=>cb(null),estado:()=>'ocioso',
        login:recusa,resetSenha:recusa,signup:recusa};
    });
    const page=await ctx.newPage();
    const errosPagina=[];
    page.on('pageerror',e=>errosPagina.push(e.message));
    await page.goto('http://localhost:8123');
    await page.waitForSelector('#fLogin',{state:'visible'});

    const espera=async(sel,texto,passo)=>{
      try{ await page.waitForFunction(([s,t])=>document.querySelector(s).textContent===t,[sel,texto],{timeout:3000}); }
      catch{ assert.equal(await page.textContent(sel),texto,passo); }
    };
    const erro=c=>page.evaluate(x=>{window.__erro=x;},c);

    await page.fill('#lEmail','ana@example.com');
    await page.fill('#lSenha','Obra2026x');
    await erro('auth/too-many-requests');
    await page.click('#fLogin button[type=submit]');
    await espera('#lMsg',BLOQUEIO_LOGIN,'login bloqueado');
    await erro(COTA);
    await page.click('#fLogin button[type=submit]');
    await espera('#lMsg',MUITAS,'login com cota estourada');

    await erro('auth/too-many-requests');
    await page.click('#lEsqueci');
    await espera('#lMsg',MUITAS,'esqueci a senha com muitas tentativas não manda redefinir a senha');

    await page.click('#authTabs button[data-k="cad"]');
    await page.fill('#cNome','Ana');
    await page.fill('#cEmail','ana@example.com');
    await page.fill('#cSenha','Obra2026x');
    await page.fill('#cSenha2','Obra2026x');
    await page.selectOption('#cOrigem','instagram');
    await erro('auth/too-many-requests');
    await page.click('#fCad button[type=submit]');
    await espera('#cMsg',MUITAS,'cadastro com muitas tentativas');

    assert.deepEqual(errosPagina,[],'erro de JavaScript na página');
    console.log('ok - login, esqueci a senha e cadastro mostram a mensagem certa para bloqueio e cota');
  }finally{ await browser.close(); }
})().catch(e=>{console.error(e);process.exitCode=1;});

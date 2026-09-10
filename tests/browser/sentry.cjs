/* SDK real, transporte interceptado: valida conteúdo efetivo do envelope. */
const assert=require('node:assert/strict');
const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch();
 try{
  const ctx=await browser.newContext({serviceWorkers:'block'});
  const bodies=[];
  await ctx.route('**/sentry-config.js',r=>r.fulfill({contentType:'text/javascript',body:"window.CUSTTA_SENTRY_CONFIG={dsn:'https://abc@o0.ingest.sentry.io/1',environment:'test',release:'custta@39'};"}));
  await ctx.route('https://o0.ingest.sentry.io/**',r=>{bodies.push(r.request().postData());return r.fulfill({status:200,body:'{}',headers:{'access-control-allow-origin':'*'}});});
  // Autoriza só coletor fictício no servidor de teste; produção usa origem do DSN real.
  await ctx.route('http://localhost:8123/',async r=>{
   const response=await r.fetch();const headers=response.headers();
   headers['content-security-policy']=headers['content-security-policy'].replace("connect-src 'self'","connect-src 'self' https://o0.ingest.sentry.io");
   await r.fulfill({response,headers});
  });
  const page=await ctx.newPage();
  await page.addInitScript(()=>{window.__csp=[];addEventListener('securitypolicyviolation',e=>__csp.push(e.blockedURI));});
  await page.goto('http://localhost:8123');await page.waitForFunction(()=>window.OBRA_DIAG && window.CUSTTA_MONITOR?.active());
  await page.evaluate(()=>{
   const e=new TypeError('SECRET email@example.com obra R$900 token=private');
   e.stack='TypeError: SECRET\n    at privateName ('+location.origin+'/app.js?token=private:100:5)';
   window.dispatchEvent(new ErrorEvent('error',{message:e.message,error:e}));
  });
  await page.evaluate(()=>CUSTTA_MONITOR.flush());
  assert.equal(bodies.length,1);
  const event=JSON.parse(bodies[0].split('\n')[2]);
  assert.equal(event.exception.values[0].type,'TypeError');
  assert.equal(event.exception.values[0].stacktrace.frames[0].lineno,100);
  assert.equal(event.exception.values[0].stacktrace.frames[0].filename,'http://localhost:8123/app.js');
  assert.doesNotMatch(bodies[0],/SECRET|email@example|R\$900|private|token=|user_agent|breadcrumbs/);
  assert.equal(event.request,undefined);assert.deepEqual(event.user,{ip_address:'0.0.0.0'});
  const scrubbed=await page.evaluate(()=>CUSTTA_MONITOR.sanitize({user:{email:'SECRET'},request:{url:'SECRET'},extra:{obras:'SECRET'},breadcrumbs:[{message:'SECRET'}],contexts:{trace:{data:'SECRET'}},tags:{origem:'SECRET'},exception:{values:[{type:'SECRET',value:'SECRET',stacktrace:{frames:[{filename:'https://evil.example/SECRET.js',vars:{SECRET:1}},{filename:location.origin+'/app.js?SECRET#SECRET',function:'SECRET',context_line:'SECRET',lineno:12,colno:3}]}}]}}));
  assert.doesNotMatch(JSON.stringify(scrubbed),/SECRET/);
  assert.equal(scrubbed.exception.values[0].stacktrace.frames.length,1);
  await page.evaluate(()=>{
   Promise.reject(new Error('SECRET promise'));
   OBRA_DIAG.registra('pwa','SECRET pwa','Error: SECRET\n at worker ('+location.origin+'/pwa.js:7:3)');
  });
  await page.waitForFunction(()=>OBRA_DIAG.erros().some(e=>e.origem==='promise'));
  await page.evaluate(()=>CUSTTA_MONITOR.flush());
  assert.equal(bodies.length,3);
  await page.evaluate(()=>{
   for(let n=0;n<50;n++) CUSTTA_MONITOR.capture('pwa','SECRET','Error\n at f ('+location.origin+'/pwa.js:7:3)');
  });
  await page.evaluate(()=>CUSTTA_MONITOR.flush());assert.equal(bodies.length,3,'duplicatas limitadas');
  await ctx.route('https://o0.ingest.sentry.io/**',r=>r.abort());
  await page.evaluate(()=>CUSTTA_MONITOR.capture('tema','offline','Error'));
  await page.evaluate(()=>CUSTTA_MONITOR.flush());
  assert.ok(await page.evaluate(()=>typeof renderAll==='function'));
  await ctx.unroute('https://o0.ingest.sentry.io/**');
  await ctx.route('https://o0.ingest.sentry.io/**',r=>{bodies.push(r.request().postData());return r.fulfill({status:200,body:'{}',headers:{'access-control-allow-origin':'*'}});});
  await page.evaluate(()=>{for(let n=0;n<40;n++) CUSTTA_MONITOR.capture('pwa','Error','Error\n at f ('+location.origin+'/pwa.js:'+(100+n)+':3)');});
  await page.evaluate(()=>CUSTTA_MONITOR.flush());assert.equal(bodies.length,19,'limite por página inclui tentativa com rede indisponível');
  assert.deepEqual(await page.evaluate(()=>__csp),[]);
  await ctx.setOffline(true);
  await page.evaluate(()=>CUSTTA_MONITOR.capture('tema','offline','Error'));
  await page.evaluate(()=>CUSTTA_MONITOR.flush());
  assert.ok(await page.evaluate(()=>typeof renderAll==='function'));
  await ctx.close();
  const clean=await browser.newContext({serviceWorkers:'block'});const p=await clean.newPage();
  await clean.route('**/sentry-config.js',r=>r.fulfill({contentType:'text/javascript',body:'window.CUSTTA_SENTRY_CONFIG={dsn:""};'}));
  await p.goto('http://localhost:8123');await p.waitForFunction(()=>window.CUSTTA_MONITOR);
  assert.equal(await p.evaluate(()=>CUSTTA_MONITOR.active()),false,'sem DSN, envio desligado');
  await clean.close();
  console.log('ok - Sentry real: exceção, promise, diagnóstico, sanitização, deduplicação, CSP, offline e ausência de DSN');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});

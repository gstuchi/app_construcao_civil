/* Verificação manual explícita: envia somente dois erros sintéticos ao projeto configurado. */
const assert=require('node:assert/strict');
const {chromium}=require('playwright');
const fs=require('node:fs');
(async()=>{
 if(!process.argv.includes('--send-real')) throw Error('Use --send-real para enviar eventos sintéticos ao Sentry real');
 const browser=await chromium.launch();
 try{
  const ctx=await browser.newContext({serviceWorkers:'block'});
  await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
  await ctx.route('**/sentry-config.js',r=>r.fulfill({contentType:'text/javascript',body:fs.readFileSync('sentry-config.js','utf8').replace("environment:'production'","environment:'smoke-test'")}));
  const page=await ctx.newPage(),results=[];
  page.on('requestfailed',r=>console.log('Falha de transporte:',r.failure()?.errorText));
  page.on('response',async response=>{
   if(response.url().includes('/envelope/')) results.push({status:response.status(),id:JSON.parse(response.request().postData().split('\n')[0]).event_id});
  });
  await page.goto('http://localhost:8123');await page.waitForFunction(()=>window.CUSTTA_MONITOR?.active());
  await page.evaluate(()=>{
   setTimeout(()=>{throw new TypeError('Custta synthetic smoke test');},0);
   Promise.reject(new ReferenceError('Custta synthetic promise test'));
  });
  await page.waitForFunction(()=>OBRA_DIAG.erros().length>=2);
  assert.equal(await page.evaluate(()=>CusttaSentrySDK.flush(15000)),true);
  assert.equal(results.length,2);assert.ok(results.every(r=>r.status===200));
  console.log(JSON.stringify(results));
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});

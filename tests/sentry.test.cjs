const {test}=require('node:test');
const assert=require('node:assert/strict');
const vm=require('node:vm');
const fs=require('node:fs');
const script=fs.readFileSync('sentry.js','utf8');
function boot(sdk,dsn='https://abc@o0.ingest.sentry.io/1'){
 const root={location:{origin:'https://custta.example'},CUSTTA_SENTRY_CONFIG:{dsn},CusttaSentrySDK:sdk,addEventListener(){}};
 vm.runInNewContext(script,{window:root,URL,Set,Map,Date,Promise});return root.CUSTTA_MONITOR;
}
test('SDK ausente ou init falhando nunca impede boot',()=>{
 for(const sdk of [undefined,{init(){throw Error('rede');}}]){
  const monitor=boot(sdk);assert.equal(monitor.active(),false);assert.doesNotThrow(()=>monitor.capture('window','Error',''));
 }
});
test('DSN externo inválido não inicializa SDK',()=>{
 let calls=0;const monitor=boot({init(){calls++;}},'https://key@evil.example/1');
 assert.equal(calls,0);assert.equal(monitor.active(),false);
});
test('sanitização descarta campos livres e aceita somente arquivos do app',()=>{
 const m=boot(undefined);
 const event=m.sanitize({exception:{values:[{type:'SEGREDO',value:'SEGREDO',stacktrace:{frames:[
  {filename:'https://custta.example/SEGREDO.js'},
  {filename:'https://custta.example/app.js?SEGREDO',lineno:'SEGREDO',colno:4,function:'SEGREDO',vars:{SEGREDO:1}}
 ]}}]},user:{id:'SEGREDO'},request:{url:'SEGREDO'},tags:{origem:'SEGREDO'},extra:{SEGREDO:1}});
 assert.doesNotMatch(JSON.stringify(event),/SEGREDO/);
 assert.equal(event.exception.values[0].stacktrace.frames.length,1);
 assert.equal(event.exception.values[0].stacktrace.frames[0].colno,4);
});

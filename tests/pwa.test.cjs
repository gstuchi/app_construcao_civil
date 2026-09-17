'use strict';
const assert = require('assert');
const { readFileSync } = require('fs');
const { join } = require('path');

const raiz = join(__dirname, '..');
const sw = readFileSync(join(raiz, 'sw.js'), 'utf8');
const app = readFileSync(join(raiz, 'app.js'), 'utf8');
const html = readFileSync(join(raiz, 'index.html'), 'utf8');
const manifest = JSON.parse(readFileSync(join(raiz, 'manifest.json'), 'utf8'));
for(const arquivo of JSON.parse(readFileSync(join(raiz,'vendor/firebase/assets.json'),'utf8'))){
  assert.ok(sw.includes(`'${arquivo}'`), `módulo Firebase fora do precache: ${arquivo}`);
  const modulo=readFileSync(join(raiz,arquivo),'utf8');
  assert.ok(!/from\s*["']https:\/\//.test(modulo), `import externo em ${arquivo}`);
}

for(const icon of manifest.icons || []){
  assert.ok(sw.includes(`'./${icon.src}'`), `ícone do manifesto fora do precache: ${icon.src}`);
}
assert.ok(/if\s*\(\s*!res\.ok\s*\)\s*return res/.test(sw), 'service worker pode substituir cache bom por resposta 4xx/5xx');
assert.ok(html.includes('id="notifAtivar"') && html.includes('id="notifDepois"'), 'convite de notificações precisa permitir ativar ou adiar');
assert.ok(app.includes("$('#notifAtivar').onclick") && app.includes('OBRA_PUSH.ativar()'), 'permissão deve partir do clique explícito do usuário');
assert.ok(sw.includes("'./push.js'") && sw.includes("'./nativo.js'"), 'push.js e nativo.js no precache');
const {runInNewContext}=require('node:vm');
const trecho=app.slice(app.indexOf('const notifInvite='),app.indexOf("window.addEventListener('cloud-conta'"));
const memoria=new Map(), elementos=new Map();
const $=id=>{
  if(!elementos.has(id)) elementos.set(id,{classList:{add(){},remove(){}},disabled:false});
  return elementos.get(id);
};
let exibicoes=0;
$('#notifInvite').classList.remove=()=>exibicoes++;
const contexto={$,Set,OBRA_PUSH:{suportado:()=>true,permissao:async()=>'default',inscrito:async()=>null,ativar:async()=>false},
  localStorage:{getItem:k=>memoria.get(k)??null,setItem:(k,v)=>memoria.set(k,v)},
  registraErro:()=>{},toast:()=>{}};
runInNewContext(trecho,contexto);
(async()=>{
  await contexto.atualizarConviteNotif({uid:'ana'});
  assert.equal(exibicoes,1);
  $('#notifDepois').onclick();
  await contexto.atualizarConviteNotif({uid:'ana'});
  assert.equal(exibicoes,1,'recusa não pode repetir convite');
  memoria.set('custta-notif-convite-legado','1');
  await contexto.atualizarConviteNotif({uid:'legado'});
  assert.equal(exibicoes,1,'recusa antiga também deve ser respeitada');
  await contexto.atualizarConviteNotif({uid:'bento'});
  assert.equal(exibicoes,2,'outra conta recebe seu próprio convite');
  await $('#notifAtivar').onclick();
  await contexto.atualizarConviteNotif({uid:'bento'});
  assert.equal(exibicoes,2,'resposta ao pedido do sistema encerra convite');
})().catch(err=>{console.error(err);process.exitCode=1;});

console.log('ok - precache contém ícones e ignora respostas HTTP com erro');

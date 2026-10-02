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
assert.ok(/pathname\.startsWith\('\/__\/'\)\)\s*return/.test(sw), 'service worker não pode interceptar o handler do login (/__/)');
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

/* Abertura do PWA instalado no iPhone: cada apple-touch-startup-image existe no
   tamanho exato do aparelho (o iOS ignora imagem de tamanho errado e mostra branco)
   e é a gerada por scripts/imagens-ios.mjs, não a antiga que dizia "Custo". */
{
  const antigas = new Set(['27befa11b789fc0de0bc4005a559878f3c9301004be327d44c5ba0e11c7c8e79',
    'ad3677c6b2b5a559c540559b923446a317a2e77afe762c402161e755e542d9a3', 'e884e4c445e19f7885a023bebaa02e310a9c02cf9c0851b4d5ca039fe083be66',
    '47753e531f6f73509868ef2783ed03fb0d502413c680c5db5e84dfe9bfea9c90', 'a0b1317351b387b01907c903f7ee08c5ca9e0fca7d9aa72295f7f817c8762a44']);
  const links = [...html.matchAll(/<link rel="apple-touch-startup-image" href="([^"]+)" media="\(device-width:(\d+)px\) and \(device-height:(\d+)px\) and \(-webkit-device-pixel-ratio:(\d)\)">/g)];
  assert.equal(links.length, 5, 'cinco aberturas de PWA no index.html');
  for(const [, arquivo, largura, altura, escala] of links){
    const png = readFileSync(join(raiz, arquivo));
    assert.equal(png.readUInt32BE(16), largura * escala, `${arquivo}: largura`);
    assert.equal(png.readUInt32BE(20), altura * escala, `${arquivo}: altura`);
    assert.ok(!antigas.has(require('crypto').createHash('sha256').update(png).digest('hex')), `${arquivo} ainda é a abertura antiga`);
  }
  console.log('ok - aberturas do PWA no tamanho de cada aparelho, geradas pelo script');
}

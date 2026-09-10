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
assert.ok(app.includes("$('#notifAtivar').onclick") && app.includes('ativaPush()'), 'permissão deve partir do clique explícito do usuário');
assert.ok(app.includes('NOTIF_ADIAR_MS') && app.includes('chaveConviteNotif'), 'adiamento do convite deve ser persistido por conta');

console.log('ok - precache contém ícones e ignora respostas HTTP com erro');

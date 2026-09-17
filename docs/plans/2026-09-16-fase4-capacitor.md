# Fase 4 — Capacitor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preparar o Custta para virar app iOS com Capacitor sem quebrar o PWA: projeto `ios/` versionado, condicionais de WKWebView, push FCM ponta a ponta, adições nativas, restauração de estado e aviso de versão.

**Architecture:** Um script clássico `nativo.js` (`OBRA_NATIVO`) é o único ponto que toca `window.Capacitor`; na web tudo cai no comportamento atual. Push sai de `app.js` para `push.js` (`OBRA_PUSH`) com implementação web (VAPID) e nativa (FCM). `scripts/build-www.mjs` copia os arquivos servidos para `www/` e injeta uma CSP por `<meta>`. O servidor de notificações ganha envio FCM e uma rota Vercel Cron inerte.

**Tech Stack:** Vanilla JS sem build, Capacitor 8 (devDependencies), Firebase JS 12.18 (vendor), firebase-admin 14, web-push, node:test, Playwright 1.63, agent-browser 0.38.

**Spec:** `docs/specs/2026-09-16-fase4-capacitor-design.md`

## Global Constraints

- Repo: `/Users/giovanistuchi/Documents/app_construcao_civil`, branch `feat/fase4`.
- Antes de qualquer comando: `export PATH=~/.local/opt/node/bin:~/.local/opt/jdk21/Contents/Home/bin:$PATH JAVA_HOME=~/.local/opt/jdk21/Contents/Home`.
- Código, comentários, identificadores, UI e mensagens de commit em português. Commit: `feat: `/`fix: `/`docs: `/`test: `/`refactor: `, minúsculas, **sem acento no assunto**.
- Commit com autor único `Giovani Stuchi <stuchigiovani@gmail.com>` (já em `git config` local). **Sem trailer `Co-Authored-By`.** Implementadores só commitam; **não dão push** (o controlador faz).
- Um commit por tarefa (feature de usuário). Nunca juntar tarefas.
- Web sem build e sem dependência de runtime no browser. Nada de `<style>`, `style="..."` em HTML/template, `onclick=` em HTML (CSP `style-src-attr 'none'`, `script-src 'self'`). `el.style.x = ...` via JS é permitido.
- Cor só por custom property existente em `styles.css`.
- Texto do usuário (nome de obra, tópico) entra no DOM só via `textContent` ou `escapeHtml`.
- Arquivo JS/CSS novo na raiz: adicionar em `ASSETS` do `sw.js` **e** incrementar `CACHE` (`obras-vNN`).
- Novo teste unitário entra na lista `test:unit` do `package.json`. Nova suíte de browser entra em `tests/browser/rodar.cjs`.
- Bundle ID provisório `com.gstuchi.custta`. Domínio de produção `https://app-construcao-civil.vercel.app`.
- Sem Xcode: validação iOS vai até `npx cap sync ios`.
- Verificação de cada tarefa: `npm run test:unit` verde; quando a tarefa tocar rules ou browser, também `npm run test:rules` / `npm run test:browser`.

## File Map

| Arquivo | Responsabilidade | Tarefa |
| --- | --- | --- |
| `nativo.js` (novo) | ponte única com Capacitor | 1 |
| `capacitor.config.json`, `scripts/build-www.mjs`, `ios/`, `.vercelignore` (novos) | esqueleto nativo | 2 |
| `pwa.js`, `index.html`, `cloud.js`, `app.js` | condicionais nativo/web | 3 |
| `ui-confirm.js`, `app.js`, `auth.js`, `styles.css` | `OBRA_CONFIRM` no lugar de confirm/alert | 4 |
| `share.js`, `app.js` | share sheet nativo, Compartilhar no lugar de Imprimir | 5 |
| `push.js` (novo), `app.js` | push extraído (web) | 6 |
| `push.js`, `cloud.js`, `sw.js`, `app.js`, `ios/App/App/AppDelegate.swift` | push nativo FCM + abrir obra | 7 |
| `notificacoes/resumo.js`, `notificacoes/enviar.js` (novo), `notificacoes/envia.js` | envio web + FCM | 8 |
| `api/push-diario.js` (novo), `vercel.json`, `package.json`, `notificacoes/README.md` | Vercel Cron inerte | 9 |
| `app.js`, `splash-pre.js`, `splash.js` | haptics, status bar, splash, segundo plano | 10 |
| `app.js` | restauração `{tab, obraAberta}` | 11 |
| `versao.json` (novo), `calc.js`, `app.js`, `index.html`, `scripts/build-www.mjs`, `vercel.json` | aviso de versão | 12 |
| `docs/sdks-fase4.md` (novo), `privacidade.html` | SDKs congelados + política | 13 |
| `docs/plans/2026-09-16-fase4-checklist-aparelho.md`, `CLAUDE.md`, `README.md` | validação e documentação | 14 |

---

### Task 1: Adaptador `nativo.js`

**Files:**
- Create: `nativo.js`
- Create: `tests/nativo.test.cjs`
- Modify: `index.html` (depois de `<script src="tema.js"></script>`, linha 20)
- Modify: `sw.js` (`CACHE` e `ASSETS`)
- Modify: `package.json` (`test:unit`)

**Interfaces:**
- Produces: `window.OBRA_NATIVO = { ehNativo(): boolean, plugin(nome): object|null, compartilharArquivo({nome, texto, tipo, titulo}): Promise<null|true>, vibrar(): Promise, barraStatus(claro: boolean): Promise, esconderSplash(): Promise, aoSegundoPlano(fn): void }`; `require('./nativo.js').criar(win)` devolve o mesmo objeto para um `win` falso.
- `compartilharArquivo` devolve `null` quando não é nativo ou faltam plugins (chamador segue caminho web), `true` quando compartilhou ou o usuário cancelou, e **lança** em falha real (chamador mostra toast).

- [ ] **Step 1: Write the failing test** — `tests/nativo.test.cjs`

```js
'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { criar } = require('../nativo.js');

function janelaNativa(extra = {}){
  const chamadas = [], erros = [];
  const plugin = (nome, impl = {}) => new Proxy(impl, { get:(alvo, metodo)=>
    metodo in alvo ? alvo[metodo] : async(...args)=>{ chamadas.push([nome, metodo, ...args]); return {}; } });
  const win = {
    Capacitor:{ isNativePlatform:()=>true, Plugins:{
      Haptics:plugin('Haptics'), StatusBar:plugin('StatusBar'), SplashScreen:plugin('SplashScreen'),
      Share:plugin('Share'),
      Filesystem:plugin('Filesystem', { writeFile:async(a)=>{ chamadas.push(['Filesystem','writeFile',a]); return { uri:'file:///cache/'+a.path }; } }),
      App:plugin('App', { addListener:(ev, fn)=>{ chamadas.push(['App','addListener',ev]); win.__appState = fn; } }),
      ...extra,
    } },
    OBRA_DIAG:{ registra:(...a)=>erros.push(a) },
  };
  return { win, chamadas, erros };
}

test('web: tudo neutro e sem erro', async()=>{
  const n = criar({});
  assert.equal(n.ehNativo(), false);
  assert.equal(n.plugin('Share'), null);
  assert.equal(await n.compartilharArquivo({ nome:'a.csv', texto:'x', tipo:'text/csv', titulo:'t' }), null);
  assert.equal(await n.vibrar(), null);
  assert.equal(await n.barraStatus(true), null);
  assert.equal(await n.esconderSplash(), null);
  n.aoSegundoPlano(()=>{ throw new Error('não deveria'); });
  assert.equal(criar(null).ehNativo(), false);
});

test('nativo: plugins recebem argumentos certos', async()=>{
  const { win, chamadas } = janelaNativa();
  const n = criar(win);
  assert.equal(n.ehNativo(), true);
  await n.vibrar();
  await n.barraStatus(true);
  await n.barraStatus(false);
  await n.esconderSplash();
  assert.deepEqual(chamadas, [
    ['Haptics','impact',{ style:'LIGHT' }],
    ['StatusBar','setStyle',{ style:'LIGHT' }],
    ['StatusBar','setStyle',{ style:'DARK' }],
    ['SplashScreen','hide',undefined],
  ]);
});

test('nativo: compartilhar grava no cache e abre share sheet', async()=>{
  const { win, chamadas } = janelaNativa();
  const r = await criar(win).compartilharArquivo({ nome:'custta.csv', texto:'a;b', tipo:'text/csv', titulo:'Dados do Custta' });
  assert.equal(r, true);
  assert.deepEqual(chamadas, [
    ['Filesystem','writeFile',{ path:'custta.csv', data:'a;b', directory:'CACHE', encoding:'utf8', recursive:true }],
    ['Share','share',{ title:'Dados do Custta', files:['file:///cache/custta.csv'] }],
  ]);
});

test('nativo: cancelar share não é erro; falha real lança e registra', async()=>{
  const cancela = janelaNativa({ Share:{ share:async()=>{ throw new Error('Share canceled'); } } });
  assert.equal(await criar(cancela.win).compartilharArquivo({ nome:'a', texto:'', tipo:'', titulo:'' }), true);
  const falha = janelaNativa({ Share:{ share:async()=>{ throw new Error('disco cheio'); } } });
  await assert.rejects(criar(falha.win).compartilharArquivo({ nome:'a', texto:'', tipo:'', titulo:'' }), /disco cheio/);
  assert.equal(falha.erros[0][0], 'nativo-share');
});

test('nativo: erro de plugin não propaga', async()=>{
  const { win, erros } = janelaNativa({ Haptics:{ impact:async()=>{ throw new Error('sem motor'); } } });
  assert.equal(await criar(win).vibrar(), null);
  assert.equal(erros[0][0], 'nativo-haptics');
});

test('nativo: segundo plano chama só ao ficar inativo', ()=>{
  const { win } = janelaNativa();
  let n = 0;
  criar(win).aoSegundoPlano(()=>n++);
  win.__appState({ isActive:true });
  win.__appState({ isActive:false });
  assert.equal(n, 1);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/nativo.test.cjs`
Expected: FAIL com `Cannot find module '../nativo.js'`

- [ ] **Step 3: Write implementation** — `nativo.js`

```js
/* Ponte única com o Capacitor. Na web tudo é neutro e quem chama segue o
   caminho de sempre; nenhum outro arquivo deve tocar window.Capacitor. */
'use strict';
(function(root){
  function criar(win){
    const cap = () => win && win.Capacitor;
    function ehNativo(){
      try{ return !!(cap() && cap().isNativePlatform && cap().isNativePlatform()); }
      catch(e){ return false; }
    }
    const plugin = nome => ehNativo() ? ((cap().Plugins && cap().Plugins[nome]) || null) : null;
    function registra(origem, err){
      try{ win.OBRA_DIAG?.registra('nativo-' + origem, (err && err.message) || String(err), err && err.stack); }
      catch(e){ /* diagnóstico nunca derruba o app */ }
    }
    async function chama(nome, metodo, args, origem){
      const p = plugin(nome);
      if(!p) return null;
      try{ const r = await p[metodo](args); return r === undefined ? true : r; }
      catch(err){ registra(origem, err); return null; }
    }
    async function compartilharArquivo({ nome, texto, tipo, titulo }){
      const fs = plugin('Filesystem'), share = plugin('Share');
      if(!fs || !share) return null;
      try{
        const { uri } = await fs.writeFile({ path:nome, data:texto, directory:'CACHE', encoding:'utf8', recursive:true });
        await share.share({ title:titulo, files:[uri] });
        return true;
      }catch(err){
        if(/cancel/i.test((err && err.message) || '')) return true; // fechou o share sheet
        registra('share', err);
        throw err;
      }
    }
    function aoSegundoPlano(fn){
      const app = plugin('App');
      if(!app) return;
      try{ app.addListener('appStateChange', estado => { if(estado && !estado.isActive) fn(); }); }
      catch(err){ registra('app', err); }
    }
    return {
      ehNativo, plugin, compartilharArquivo, aoSegundoPlano,
      vibrar: () => chama('Haptics', 'impact', { style:'LIGHT' }, 'haptics'),
      // DARK = texto claro, para fundo escuro
      barraStatus: claro => chama('StatusBar', 'setStyle', { style: claro ? 'LIGHT' : 'DARK' }, 'statusbar'),
      esconderSplash: () => chama('SplashScreen', 'hide', undefined, 'splash'),
    };
  }
  if(typeof module !== 'undefined') module.exports = { criar };
  if(root) root.OBRA_NATIVO = criar(root);
})(typeof window !== 'undefined' ? window : null);
```

Note: `tipo` fica na assinatura para o chamador documentar o formato; o plugin Share não precisa dele.

- [ ] **Step 4: Carregar no app e no precache**

`index.html`, logo depois de `<script src="tema.js"></script>`:

```html
<script src="nativo.js"></script>
```

`sw.js`: `const CACHE = 'obras-v47';` e acrescentar `'./nativo.js'` ao array `ASSETS` (depois de `'./tema.js'`).

`package.json` `test:unit`: acrescentar ` tests/nativo.test.cjs` ao fim da lista.

- [ ] **Step 5: Run tests**

Run: `node --test tests/nativo.test.cjs && npm run test:unit`
Expected: PASS (6 testes novos, suíte inteira verde)

- [ ] **Step 6: Commit**

```bash
git add nativo.js tests/nativo.test.cjs index.html sw.js package.json
git commit -m "feat: adicionar ponte nativa unica para o capacitor"
```

---

### Task 2: Esqueleto Capacitor + `build-www`

**Files:**
- Modify: `package.json` (devDependencies, scripts)
- Create: `capacitor.config.json`
- Create: `scripts/build-www.mjs`
- Create: `tests/build-www.test.mjs`, `tests/capacitor.test.cjs`
- Create: `ios/` (gerado por `npx cap add ios`)
- Create: `.vercelignore`

**Interfaces:**
- Produces: `import { construir, cspNativa, PRODUCAO } from './scripts/build-www.mjs'`; `construir({ raiz, destino }): Promise<string[]>` (lista relativa copiada); `cspNativa(csp: string): string`. Scripts `npm run build:www`, `npm run cap:sync`. A Task 12 acrescenta `versao` a `construir`.

- [ ] **Step 1: Instalar Capacitor**

```bash
npm i -D @capacitor/core@^8 @capacitor/cli@^8 @capacitor/ios@^8 @capacitor/app@^8 @capacitor/share@^8 @capacitor/filesystem@^8 @capacitor/haptics@^8 @capacitor/status-bar@^8 @capacitor/splash-screen@^8 @capacitor-firebase/messaging@^8
```

Se algum plugin não tiver linha 8, use a última versão cujo `peerDependencies['@capacitor/core']` aceite 8 (`npm view <pkg> peerDependencies`).

- [ ] **Step 2: Write the failing tests**

`tests/build-www.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, access } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { construir, cspNativa, PRODUCAO } from '../scripts/build-www.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');

test('copia arquivos servidos e injeta CSP nativa', async()=>{
  const destino = await mkdtemp(join(tmpdir(), 'custta-www-'));
  const lista = await construir({ raiz, destino });
  for(const a of ['index.html','app.js','nativo.js','vendor/firebase/firebase-app.js','fontes/hanken-grotesk-800.woff2'])
    assert.ok(lista.includes(a), 'faltou ' + a);
  assert.ok(!lista.some(a => a.startsWith('tests/') || a.startsWith('docs/')));
  const html = await readFile(join(destino, 'index.html'), 'utf8');
  const meta = html.match(/<meta http-equiv="Content-Security-Policy" content="([^"]+)">/);
  assert.ok(meta, 'meta CSP ausente');
  assert.ok(!meta[1].includes('unsafe-inline'));
  assert.ok(!meta[1].includes('frame-ancestors'));
  assert.ok(!meta[1].includes('upgrade-insecure-requests'));
  assert.match(meta[1], new RegExp("connect-src 'self' [^;]*" + PRODUCAO.replace(/\./g, '\\.')));
  await access(join(destino, 'app.js'));
});

test('cspNativa remove diretivas que meta não aceita', ()=>{
  assert.equal(cspNativa("default-src 'none'; frame-ancestors 'none'; connect-src 'self'; upgrade-insecure-requests"),
    `default-src 'none'; connect-src 'self' ${PRODUCAO}`);
});

test('arquivo listado ausente falha', async()=>{
  const falsa = await mkdtemp(join(tmpdir(), 'custta-raiz-'));
  await writeFile(join(falsa, 'sw.js'), "const ASSETS = ['./', './index.html', './falta.js'];");
  await writeFile(join(falsa, 'styles.css'), '');
  await writeFile(join(falsa, 'index.html'), '<meta charset="utf-8">');
  await writeFile(join(falsa, 'vercel.json'), JSON.stringify({ headers:[{ source:'/(.*)', headers:[{ key:'Content-Security-Policy', value:"default-src 'none'" }] }] }));
  await assert.rejects(construir({ raiz:falsa, destino:join(falsa, 'www') }), /falta\.js/);
});
```

`tests/capacitor.test.cjs`:

```js
'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const raiz = join(__dirname, '..');
const ler = p => readFileSync(join(raiz, p), 'utf8');

test('config do Capacitor aponta para www e bundle provisório', ()=>{
  const c = JSON.parse(ler('capacitor.config.json'));
  assert.equal(c.appId, 'com.gstuchi.custta');
  assert.equal(c.appName, 'Custta');
  assert.equal(c.webDir, 'www');
  assert.equal(c.plugins.SplashScreen.launchAutoHide, false);
});

test('Info.plist: isento de criptografia, só retrato, push em segundo plano', ()=>{
  const plist = ler('ios/App/App/Info.plist');
  assert.match(plist, /<key>ITSAppUsesNonExemptEncryption<\/key>\s*<false\/>/);
  const orient = plist.match(/<key>UISupportedInterfaceOrientations<\/key>\s*<array>([\s\S]*?)<\/array>/)[1];
  assert.deepEqual([...orient.matchAll(/<string>([^<]+)<\/string>/g)].map(m=>m[1]), ['UIInterfaceOrientationPortrait']);
  assert.ok(!plist.includes('UISupportedInterfaceOrientations~ipad'));
  assert.match(plist, /<key>UIBackgroundModes<\/key>\s*<array>\s*<string>remote-notification<\/string>/);
});

test('projeto Xcode só para iPhone', ()=>{
  const pbx = ler('ios/App/App.xcodeproj/project.pbxproj');
  assert.ok(pbx.includes('TARGETED_DEVICE_FAMILY = 1;'));
  assert.ok(!pbx.includes('TARGETED_DEVICE_FAMILY = "1,2";'));
});
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `node --test tests/build-www.test.mjs tests/capacitor.test.cjs`
Expected: FAIL (`Cannot find module .../build-www.mjs`, `ENOENT capacitor.config.json`)

- [ ] **Step 4: Write `scripts/build-www.mjs`**

```js
/* Copia o app web para www/ (webDir do Capacitor). Não é bundler: os arquivos
   saem como estão. A lista vem do precache do sw.js, que já é a fonte de verdade
   do que o app precisa para abrir offline. */
import { readFile, writeFile, mkdir, rm, cp, access } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const PRODUCAO = 'https://app-construcao-civil.vercel.app';

/* <meta> não aceita frame-ancestors, report-uri, sandbox nem upgrade-insecure-requests.
   Produção entra em connect-src para o aviso de versão do app nativo. */
export function cspNativa(csp){
  return csp.split(';').map(d => d.trim()).filter(Boolean)
    .filter(d => !/^(frame-ancestors|upgrade-insecure-requests|report-uri|sandbox)\b/.test(d))
    .map(d => d.startsWith('connect-src') ? `${d} ${PRODUCAO}` : d)
    .join('; ');
}

export async function construir({ raiz, destino }){
  const sw = await readFile(join(raiz, 'sw.js'), 'utf8');
  const bloco = sw.match(/const ASSETS = (\[[^\]]*\]);/);
  if(!bloco) throw new Error('ASSETS não encontrado em sw.js');
  const assets = JSON.parse(bloco[1].replace(/'/g, '"')).filter(a => a !== './');
  const css = await readFile(join(raiz, 'styles.css'), 'utf8');
  const doCss = [...css.matchAll(/url\(\s*['"]?([^'")]+)['"]?\s*\)/g)].map(m => m[1])
    .filter(u => !/^(data:|https?:|#)/.test(u));
  const arquivos = [...new Set([...assets, ...doCss].map(a => a.replace(/^\.\//, '')))];
  for(const a of arquivos){
    try{ await access(join(raiz, a)); }
    catch{ throw new Error('arquivo listado não existe: ' + a); }
  }
  await rm(destino, { recursive:true, force:true });
  for(const a of arquivos){
    await mkdir(dirname(join(destino, a)), { recursive:true });
    await cp(join(raiz, a), join(destino, a));
  }
  const vercel = JSON.parse(await readFile(join(raiz, 'vercel.json'), 'utf8'));
  const header = vercel.headers[0].headers.find(h => h.key === 'Content-Security-Policy');
  const indice = join(destino, 'index.html');
  const html = await readFile(indice, 'utf8');
  const marca = '<meta charset="utf-8">';
  if(!html.includes(marca)) throw new Error('index.html sem <meta charset="utf-8">');
  await writeFile(indice, html.replace(marca,
    `${marca}\n<meta http-equiv="Content-Security-Policy" content="${cspNativa(header.value)}">`));
  return arquivos;
}

if(process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)){
  const raiz = resolve(dirname(fileURLToPath(import.meta.url)), '..');
  const lista = await construir({ raiz, destino: join(raiz, 'www') });
  console.log(`www/ pronto com ${lista.length} arquivos`);
}
```

- [ ] **Step 5: Config e scripts**

`capacitor.config.json`:

```json
{
  "appId": "com.gstuchi.custta",
  "appName": "Custta",
  "webDir": "www",
  "backgroundColor": "#04100C",
  "ios": { "contentInset": "never" },
  "plugins": {
    "SplashScreen": { "launchAutoHide": false, "backgroundColor": "#04100C", "showSpinner": false },
    "FirebaseMessaging": { "presentationOptions": ["badge", "sound", "alert"] }
  }
}
```

`package.json` `scripts`: acrescentar

```json
"build:www": "node scripts/build-www.mjs",
"cap:sync": "npm run build:www && cap sync ios"
```

e ao fim de `test:unit`: ` tests/build-www.test.mjs tests/capacitor.test.cjs`.

`.vercelignore` (novo):

```
ios/
www/
```

- [ ] **Step 6: Gerar o projeto iOS**

```bash
npm run build:www
npx cap add ios
```

Se `cap add ios` exigir CocoaPods/Xcode e falhar, rode `npx cap add ios --packagemanager SPM` (Capacitor 8 usa SPM por padrão; não depende de CocoaPods). Aceite avisos sobre `xcodebuild` ausente desde que `ios/App/App/Info.plist` e `ios/App/App.xcodeproj/project.pbxproj` existam.

- [ ] **Step 7: Ajustar Info.plist e pbxproj**

```bash
P=ios/App/App/Info.plist
/usr/libexec/PlistBuddy -c "Add :ITSAppUsesNonExemptEncryption bool false" $P 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :ITSAppUsesNonExemptEncryption false" $P
/usr/libexec/PlistBuddy -c "Delete :UISupportedInterfaceOrientations" $P
/usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations array" -c "Add :UISupportedInterfaceOrientations:0 string UIInterfaceOrientationPortrait" $P
/usr/libexec/PlistBuddy -c "Delete :UISupportedInterfaceOrientations~ipad" $P 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Delete :UIBackgroundModes" $P 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" -c "Add :UIBackgroundModes:0 string remote-notification" $P
plutil -convert xml1 $P
sed -i '' 's/TARGETED_DEVICE_FAMILY = "1,2";/TARGETED_DEVICE_FAMILY = 1;/g' ios/App/App.xcodeproj/project.pbxproj
grep -q 'TARGETED_DEVICE_FAMILY = 1;' ios/App/App.xcodeproj/project.pbxproj || sed -i '' 's/\(PRODUCT_BUNDLE_IDENTIFIER = com.gstuchi.custta;\)/\1\n\t\t\t\tTARGETED_DEVICE_FAMILY = 1;/g' ios/App/App.xcodeproj/project.pbxproj
```

- [ ] **Step 8: Run tests + sync**

Run: `node --test tests/build-www.test.mjs tests/capacitor.test.cjs && npm run test:unit && npm run cap:sync`
Expected: PASS; `cap sync` termina sem erro (aviso de Xcode ausente é aceitável).

- [ ] **Step 9: Commit** (confira `git status`: `www/` e `node_modules/` não aparecem; `ios/App/App/public/` fica ignorado pelo `.gitignore` gerado dentro de `ios/`, confirme com `git check-ignore ios/App/App/public`)

```bash
git add package.json package-lock.json capacitor.config.json scripts/build-www.mjs tests/build-www.test.mjs tests/capacitor.test.cjs ios .vercelignore
git commit -m "feat: criar projeto ios com capacitor e copia do app para www"
```

---

### Task 3: Condicionais nativo/web + suíte `nativo.cjs`

**Files:**
- Modify: `index.html:5` (viewport)
- Modify: `pwa.js`
- Modify: `app.js` (`beforeinstallprompt`, nota de notificação em `renderAjustes`)
- Modify: `cloud.js:12,55` (tab manager)
- Modify: `tests/helpers/firebase-stub.mjs`
- Create: `tests/cloud-nativo.test.mjs`
- Create: `tests/browser/nativo.cjs`
- Modify: `tests/browser/rodar.cjs`, `package.json`

**Interfaces:**
- Consumes: `OBRA_NATIVO.ehNativo()` (Task 1).
- Produces: `tests/browser/nativo.cjs` exporta nada; contém `abrir(browser, { nativo })` interno e é estendido nas Tasks 4, 5, 7, 10, 11, 12 acrescentando blocos antes de `console.log('ok - nativo')`. Na página, `window.chamadasNativas: Array<[plugin, metodo, ...args]>` e `window.ouvintesNativos: Record<'Plugin:evento', fn>`.

- [ ] **Step 1: Write failing unit test** — `tests/cloud-nativo.test.mjs`

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { register, createRequire } from 'node:module';
register('./helpers/loader-firebase.mjs', import.meta.url);
const require = createRequire(import.meta.url);
const { __ctrl:ctrl } = await import('./helpers/firebase-stub.mjs');

async function carregar(nativo){
  const event = new EventTarget();
  globalThis.window = { addEventListener:event.addEventListener.bind(event), dispatchEvent:event.dispatchEvent.bind(event),
    OBRA_CALC:require('../calc.js'), location:{ reload(){} }, OBRA_NATIVO:{ ehNativo:()=>nativo } };
  globalThis.CustomEvent = globalThis.CustomEvent || Event;
  Object.defineProperty(globalThis, 'navigator', { value:{ onLine:true }, configurable:true });
  ctrl.tabManager = null;
  await import('../cloud.js?nativo=' + nativo + Math.random());
  return ctrl.tabManager;
}

test('nativo usa aba única; web mantém várias abas', async()=>{
  assert.equal(await carregar(true), 'single');
  assert.equal(await carregar(false), 'multiple');
});
```

No stub `tests/helpers/firebase-stub.mjs`, trocar a linha de `persistentMultipleTabManager` por:

```js
export function persistentMultipleTabManager(){ __ctrl.tabManager = 'multiple'; return {}; }
export function persistentSingleTabManager(){ __ctrl.tabManager = 'single'; return {}; }
```

- [ ] **Step 2: Run to verify it fails**

Run: `node --test tests/cloud-nativo.test.mjs`
Expected: FAIL (`'multiple' !== 'single'`)

- [ ] **Step 3: Implement cloud.js**

Import (linha 12): `initializeFirestore, persistentLocalCache, persistentMultipleTabManager, persistentSingleTabManager,`

Linhas 54-56:

```js
/* WKWebView não tem abas: o gerenciador multi-aba só acrescenta coordenação inútil
   e depende de APIs que o iOS pode suspender em segundo plano. */
const nativo = !!window.OBRA_NATIVO?.ehNativo();
const db = initializeFirestore(app, {
  localCache: persistentLocalCache({ tabManager: nativo ? persistentSingleTabManager({}) : persistentMultipleTabManager() }),
});
```

(`persistentSingleTabManager` já é exportado por `vendor/firebase/firebase-firestore.js`; confirme com `grep -c persistentSingleTabManager vendor/firebase/firebase-firestore.js` → ≥1. Não re-vendorize.)

- [ ] **Step 4: Run** `node --test tests/cloud-nativo.test.mjs tests/conta.test.mjs tests/fila.test.mjs` → PASS. Acrescente ` tests/cloud-nativo.test.mjs` ao `test:unit`.

- [ ] **Step 5: Write failing browser suite** — `tests/browser/nativo.cjs`

```js
/* App como se estivesse no WKWebView: window.Capacitor falso registra chamadas.
   Dados sintéticos, sem rede. Rode com node tests/browser/servidor.cjs no ar. */
const assert = require('node:assert/strict');
const { chromium } = require('playwright');

const OBRAS = { config:{ taxaMensal:1, topicosCustom:[{ id:'c_x', nm:'<img src=x onerror=alert(1)>', ic:'etiqueta' }] },
  obras:[{ id:'o1', nome:'Casa Azul', fase:'construcao', dataInicio:'2026-01-01', areaM2:80,
    gastos:[{ id:'g1', valor:150, topico:'c_x', descricao:'Cimento', data:'2026-02-01', pagamento:'pix' }] }] };

async function abrir(browser, { nativo, viewport = { width:390, height:844 }, antes }){
  const ctx = await browser.newContext({ viewport, serviceWorkers:'allow' });
  await ctx.route('**/cloud.js', r => r.fulfill({ contentType:'text/javascript', body:'' }));
  await ctx.route('https://**/*', r => r.abort());
  await ctx.addInitScript(([nativo, obras]) => {
    sessionStorage.setItem('splashVista', '1');
    window.errosPagina = [];
    addEventListener('error', e => errosPagina.push(e.message));
    addEventListener('securitypolicyviolation', e => errosPagina.push('csp:' + e.violatedDirective));
    window.CLOUD = { user:()=>({ uid:'teste', email:'t@t.com', emailVerificado:true }), onAuth:cb=>cb({ uid:'teste' }),
      watchDados:cb=>{ setTimeout(()=>cb(JSON.parse(JSON.stringify(obras)), { fromCache:false, pendingWrites:false, localDirty:false })); return ()=>{}; },
      saveDados:()=>Promise.resolve(), estado:()=>'ocioso', ready:Promise.resolve(), tentarDeNovo:()=>{ window.flushes = (window.flushes||0)+1; return Promise.resolve(); },
      savePushSub:()=>Promise.resolve(), removePushSub:()=>Promise.resolve(),
      savePushToken:(k,v)=>{ window.tokenSalvo=[k,v]; return Promise.resolve(); }, removePushToken:k=>{ window.tokenRemovido=k; return Promise.resolve(); } };
    if(!nativo) return;
    window.chamadasNativas = []; window.ouvintesNativos = {};
    const respostas = {
      'Filesystem.writeFile': a => ({ uri:'file:///cache/' + a.path }),
      'FirebaseMessaging.requestPermissions': () => ({ receive:'granted' }),
      'FirebaseMessaging.checkPermissions': () => ({ receive:'prompt' }),
      'FirebaseMessaging.getToken': () => ({ token:'tok-teste' }),
    };
    const plugin = nome => new Proxy({}, { get:(_, metodo) => {
      if(metodo === 'then') return undefined;
      if(metodo === 'addListener') return (ev, fn) => { chamadasNativas.push([nome, 'addListener', ev]); ouvintesNativos[nome + ':' + ev] = fn; return Promise.resolve({ remove(){} }); };
      return async a => { chamadasNativas.push([nome, metodo, a]); const f = respostas[nome + '.' + metodo]; return f ? f(a) : undefined; };
    } });
    const nomes = ['App','Share','Filesystem','Haptics','StatusBar','SplashScreen','FirebaseMessaging'];
    window.Capacitor = { isNativePlatform:()=>true, getPlatform:()=>'ios', Plugins:Object.fromEntries(nomes.map(n => [n, plugin(n)])) };
  }, [nativo, OBRAS]);
  if(antes) await antes(ctx);
  const page = await ctx.newPage();
  await page.goto('http://localhost:8123');
  await page.waitForFunction(() => typeof db !== 'undefined' && db.obras.length === 1);
  return { ctx, page };
}

(async()=>{
  const browser = await chromium.launch();
  try{
    /* ---- Task 3: condicionais ---- */
    {
      const { ctx, page } = await abrir(browser, { nativo:true });
      await page.waitForTimeout(800);
      assert.equal(await page.evaluate(async()=> (await navigator.serviceWorker.getRegistrations()).length), 0, 'nativo não registra SW');
      const viewport = await page.getAttribute('meta[name=viewport]', 'content');
      assert.ok(!/user-scalable|maximum-scale/.test(viewport), 'zoom precisa ficar liberado: ' + viewport);
      await page.evaluate(()=>window.dispatchEvent(new Event('beforeinstallprompt')));
      assert.equal(await page.locator('#installHint').isHidden(), true, 'nativo não oferece instalar PWA');
      await page.evaluate(()=>{ showView('ajustes'); renderAjustes(); });
      assert.ok(!/Safari|Tela de Início/.test(await page.locator('#ajNotifNota').textContent()), 'nativo não menciona Safari');
      assert.deepEqual(await page.evaluate(()=>errosPagina), []);
      await ctx.close();
    }
    {
      const { ctx, page } = await abrir(browser, { nativo:false });
      await page.waitForFunction(async()=> (await navigator.serviceWorker.getRegistrations()).length === 1, null, { timeout:5000 });
      await ctx.close();
    }
    console.log('ok - nativo');
  }finally{ await browser.close(); }
})().catch(err => { console.error(err); process.exitCode = 1; });
```

Em `tests/browser/rodar.cjs`, depois de `await run('tests/browser/cartao.cjs');`: `await run('tests/browser/nativo.cjs');`

- [ ] **Step 6: Run to verify it fails**

Run: `node tests/browser/servidor.cjs & sleep 1; node tests/browser/nativo.cjs; kill %1`
Expected: FAIL em `nativo não registra SW` ou `zoom precisa ficar liberado`.

- [ ] **Step 7: Implement**

`index.html:5`:

```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```

`pwa.js` linha 3:

```js
/* No app nativo os arquivos vêm do próprio binário; SW só atrapalharia a atualização. */
if('serviceWorker' in navigator && !window.OBRA_NATIVO?.ehNativo()){
```

`app.js` — `beforeinstallprompt`:

```js
window.addEventListener('beforeinstallprompt',e=>{ e.preventDefault(); if(OBRA_NATIVO.ehNativo()) return; deferredPrompt=e; $('#installHint').classList.remove('hidden'); });
```

`app.js` — em `renderAjustes`, dentro de `if(!pushSuportado()){`, trocar a atribuição de `$('#ajNotifNota').textContent` por:

```js
      $('#ajNotifNota').textContent = OBRA_NATIVO.ehNativo()
        ? 'Notificações indisponíveis neste aparelho no momento.'
        : 'Pra receber notificações no iPhone: abra no Safari, '
          + 'toque em Compartilhar e "Adicionar à Tela de Início". Depois abra o app pelo '
          + 'ícone novo e ative aqui. Precisa de iOS 16.4 ou mais novo.';
```

- [ ] **Step 8: Run all**

Run: `node tests/browser/servidor.cjs & sleep 1; node tests/browser/nativo.cjs; node tests/browser/mobile.cjs; kill %1; npm run test:unit`
Expected: `ok - nativo`, mobile verde, unit verde.

- [ ] **Step 9: Commit**

```bash
git add index.html pwa.js app.js cloud.js tests/helpers/firebase-stub.mjs tests/cloud-nativo.test.mjs tests/browser/nativo.cjs tests/browser/rodar.cjs package.json
git commit -m "feat: liberar zoom e desligar recursos de pwa no app nativo"
```

---

### Task 4: Diálogos no lugar de `confirm()`/`alert()`

**Files:**
- Modify: `ui-confirm.js` (acrescentar `OBRA_CONFIRM`)
- Modify: `styles.css` (depois de `.conta-dialog::backdrop`, ~linha 600)
- Modify: `app.js` (linhas ~395, ~655, ~740, ~1469-1470)
- Modify: `auth.js:23`
- Modify: `tests/browser/sync.cjs:151`
- Create: `tests/dialogos.test.cjs`
- Modify: `tests/browser/nativo.cjs`, `package.json`

**Interfaces:**
- Produces: `window.OBRA_CONFIRM = { perguntar(msg: string, { confirmar = 'Confirmar', cancelar = 'Cancelar' } = {}): Promise<boolean>, avisar(msg: string): Promise<void> }`. DOM: `dialog.confirma-dialog` com `p.confirma-msg`, `button.btn.ghost[data-acao=cancelar]` e `button.btn.primary[data-acao=confirmar]`.

- [ ] **Step 1: Write failing static test** — `tests/dialogos.test.cjs`

```js
'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');

test('app.js e auth.js não usam confirm/alert nativos (somem no WKWebView)', ()=>{
  for(const nome of ['app.js', 'auth.js']){
    const fonte = readFileSync(join(__dirname, '..', nome), 'utf8').replace(/\/\*[\s\S]*?\*\/|\/\/.*$/gm, '');
    assert.doesNotMatch(fonte, /(^|[^.\w])(confirm|alert)\s*\(/m, nome);
  }
});
```

Acrescente ` tests/dialogos.test.cjs` ao `test:unit`.

- [ ] **Step 2: Run** `node --test tests/dialogos.test.cjs` → FAIL (`app.js`).

- [ ] **Step 3: Implement `OBRA_CONFIRM`** — em `ui-confirm.js`, antes de `window.OBRA_CONTA = { abrir };`:

```js
  /* confirm()/alert() viram no-op silencioso no WKWebView sem WKUIDelegate.
     Mensagem entra por textContent: nome de obra e tópico são texto do usuário. */
  function dialogoSimples(msg, { confirmar, cancelar }){
    return new Promise(resolve=>{
      const d = document.createElement('dialog');
      d.className = 'conta-dialog confirma-dialog';
      const p = document.createElement('p'); p.className = 'confirma-msg'; p.textContent = msg;
      const acoes = document.createElement('div'); acoes.className = 'sheet-actions';
      const botao = (texto, classe, acao)=>{
        const b = document.createElement('button'); b.type = 'button'; b.className = classe;
        b.dataset.acao = acao; b.textContent = texto; acoes.append(b); return b;
      };
      const bCancelar = cancelar ? botao(cancelar, 'btn ghost', 'cancelar') : null;
      const bConfirmar = botao(confirmar, 'btn primary', 'confirmar');
      let resposta = false;
      d.append(p, acoes);
      d.addEventListener('close', ()=>{ d.remove(); resolve(resposta); }, { once:true });
      if(bCancelar) bCancelar.onclick = ()=>d.close();
      bConfirmar.onclick = ()=>{ resposta = true; d.close(); };
      document.body.append(d); d.showModal();
      (bCancelar || bConfirmar).focus(); // ação destrutiva nunca é o foco inicial
    });
  }
  window.OBRA_CONFIRM = {
    perguntar: (msg, { confirmar = 'Confirmar', cancelar = 'Cancelar' } = {}) => dialogoSimples(msg, { confirmar, cancelar }),
    avisar: msg => dialogoSimples(msg, { confirmar:'Entendi', cancelar:null }).then(()=>{}),
  };
```

`styles.css`, depois da regra `.conta-dialog::backdrop`:

```css
  .confirma-dialog .confirma-msg{margin:0 0 18px;font-size:16px;line-height:1.45;overflow-wrap:anywhere}
```

- [ ] **Step 4: Replace call sites**

`app.js` `#oDesfazer`:

```js
  on('#oDesfazer',     async()=>{ if(await OBRA_CONFIRM.perguntar('Desfazer a venda? A obra volta pra “Pronta”.', { confirmar:'Desfazer venda' })){ const oo=obraById(o.id); if(!oo) return; delete oo.venda; oo.fase='pronta'; save(); renderAll(); } });
```

`app.js` exclusão de gasto simples (`del.onclick` em `gastoRow`): tornar o handler `async` e trocar o bloco:

```js
  del.onclick = async()=>{
    const oo = obraById(o.id); if(!oo) return;
    if(!g.grupoId){
      // exclusão simples usa diálogo curto, não abre folha: nada a fechar, só voltar
      if(await OBRA_CONFIRM.perguntar('Excluir este gasto?', { confirmar:'Excluir' })){
        const atual = obraById(o.id); if(!atual) return;
        atual.gastos = atual.gastos.filter(x=>x.id!==g.id); save(); renderAll();
        if(voltar) voltar();
      }
      return;
    }
```

`app.js` `#cDel` (apagar obra):

```js
  $('#cDel').onclick = async()=>{
    const n = o.gastos.length;
    if(await OBRA_CONFIRM.perguntar(`Apagar “${o.nome}”?` + (n?` Os ${n} lançamento(s) dela serão perdidos.`:''), { confirmar:'Apagar obra' })){
      db.obras = db.obras.filter(x=>x.id!==o.id);
      obraAberta = null;
      save(); closeSheet(); showView('inicio'); renderAll();
    }
  };
```

`app.js` remover tópico:

```js
    del.onclick = async()=>{
      const emUso = db.obras.some(o=>o.gastos.some(g=>g.topico===t.id));
      if(emUso){ await OBRA_CONFIRM.avisar('Este tópico tem gastos lançados. Mova ou apague os gastos antes.'); return; }
      if(await OBRA_CONFIRM.perguntar(`Remover o tópico “${t.nm}”?`, { confirmar:'Remover' })){
        db.config.topicosCustom = db.config.topicosCustom.filter(x=>x.id!==t.id);
        save(); renderAll();
      }
    };
```

`auth.js:23`:

```js
    if(!(await OBRA_CONFIRM.perguntar('Sair da conta?', { confirmar:'Sair' }))) return;
```

`tests/browser/sync.cjs:151-152` — trocar `page.once('dialog', d=>d.accept());` + clique por:

```js
  await page.locator('#btnSairSide').click();
  await page.locator('dialog.confirma-dialog [data-acao=confirmar]').click();
```

(remova o `await page.locator('#btnSairSide').click();` que vinha logo depois do `page.once`, para não clicar duas vezes).

- [ ] **Step 5: Browser test** — em `tests/browser/nativo.cjs`, antes de `console.log('ok - nativo')`:

```js
    /* ---- Task 4: diálogos ---- */
    {
      const { ctx, page } = await abrir(browser, { nativo:true });
      await page.evaluate(()=>{ showView('ajustes'); renderAjustes(); });
      await page.locator('#ajTopicos .li-del').first().click();
      const dlg = page.locator('dialog.confirma-dialog');
      assert.equal(await dlg.locator('.confirma-msg').textContent(), 'Este tópico tem gastos lançados. Mova ou apague os gastos antes.');
      await dlg.locator('[data-acao=confirmar]').click();
      await page.evaluate(()=>openObra('o1'));
      await page.locator('#v-obra .li-del').first().click();
      await dlg.locator('[data-acao=cancelar]').click();
      assert.equal(await page.evaluate(()=>obraById('o1').gastos.length), 1, 'cancelar mantém gasto');
      await page.locator('#v-obra .li-del').first().click();
      await dlg.locator('[data-acao=confirmar]').click();
      assert.equal(await page.evaluate(()=>obraById('o1').gastos.length), 0, 'confirmar exclui');
      await page.evaluate(()=>{ db.obras[0].gastos=[]; showView('ajustes'); renderAjustes(); });
      await page.locator('#ajTopicos .li-del').first().click();
      assert.equal(await dlg.locator('.confirma-msg').textContent(), 'Remover o tópico “<img src=x onerror=alert(1)>”?', 'nome aparece literal');
      await dlg.locator('[data-acao=confirmar]').click();
      assert.equal(await page.evaluate(()=>db.config.topicosCustom.length), 0);
      assert.deepEqual(await page.evaluate(()=>errosPagina), []);
      await ctx.close();
    }
```

Se o seletor `#v-obra .li-del` não achar o botão (lista de gastos pode viver em outra view), rode `grep -n "gastoRow(" app.js` e use o container onde `renderObra` insere as linhas.

- [ ] **Step 6: Run** `npm run test:unit` e `npm run test:browser` → verdes.

- [ ] **Step 7: Commit**

```bash
git add ui-confirm.js styles.css app.js auth.js tests/dialogos.test.cjs tests/browser/sync.cjs tests/browser/nativo.cjs package.json
git commit -m "feat: trocar confirm e alert por dialogos do proprio app"
```

---

### Task 5: Compartilhar pelo share sheet nativo

**Files:**
- Modify: `share.js` (`exportar`)
- Modify: `app.js` (`#grafPrint` ~1039, `#relPrint` ~1182)
- Modify: `tests/share.test.cjs`, `tests/browser/nativo.cjs`

**Interfaces:**
- Consumes: `OBRA_NATIVO.compartilharArquivo` (Task 1).
- Produces: `OBRA_SHARE.exportar(dados, formato, raiz = window)`; `ligarImprimir(botao: HTMLButtonElement)` em `app.js`.

- [ ] **Step 1: Failing unit test** — acrescentar em `tests/share.test.cjs`:

```js
const { exportar } = require('../share.js');
test('no nativo exporta pelo share sheet e não cai no download web', async()=>{
  const pedidos = [];
  const raiz = { OBRA_NATIVO:{ ehNativo:()=>true, compartilharArquivo:async a=>{ pedidos.push(a); return true; } } };
  await exportar(dados, 'csv', raiz);
  assert.equal(pedidos.length, 1);
  assert.match(pedidos[0].nome, /^custta-\d{4}-\d{2}-\d{2}\.csv$/);
  assert.equal(pedidos[0].tipo, 'text/csv;charset=utf-8');
  assert.equal(pedidos[0].titulo, 'Dados do Custta');
  assert.ok(pedidos[0].texto.includes('Mão de obra'));
});
```

- [ ] **Step 2: Run** `node --test tests/share.test.cjs` → FAIL (`pedidos.length` 0 / `File is not defined` não deve ocorrer porque o ramo nativo retorna antes).

- [ ] **Step 3: Implement** — `share.js` `exportar`:

```js
  async function exportar(dados, formato, raiz = root){
    if(!['json','csv'].includes(formato)) throw new Error('Formato não suportado.');
    const texto = formato === 'json' ? json(dados) : csv(dados);
    const nome = 'custta-' + new Date().toISOString().slice(0,10) + '.' + formato;
    const tipo = formato === 'json' ? 'application/json' : 'text/csv;charset=utf-8';
    const nativo = raiz && raiz.OBRA_NATIVO;
    if(nativo && nativo.ehNativo()){
      const r = await nativo.compartilharArquivo({ nome, texto, tipo, titulo:'Dados do Custta' });
      if(r) return;
    }
    const arquivo = new File([texto], nome, { type:tipo });
    if(navigator.canShare?.({ files:[arquivo] })){
      await navigator.share({ files:[arquivo], title:'Dados do Custta' });
      return;
    }
    const url = URL.createObjectURL(arquivo);
    const a = document.createElement('a'); a.href = url; a.download = nome;
    document.body.append(a); a.click(); a.remove();
    setTimeout(()=>URL.revokeObjectURL(url), 60000);
  }
```

Atualize o comentário do topo: `/* Exportação: share sheet nativo no app iOS; Web Share ou download na web. */`

`app.js` — acima de `renderGraficos` (nível de módulo):

```js
/* window.print() falha calado no WKWebView: no app o botão compartilha a planilha. */
function ligarImprimir(botao){
  if(!OBRA_NATIVO.ehNativo()){ botao.onclick = ()=>window.print(); return; }
  botao.innerHTML = `${ICON('documento')} Compartilhar planilha`;
  botao.onclick = async()=>{
    try{ await OBRA_SHARE.exportar(db, 'csv'); }
    catch(err){ toast('Não foi possível compartilhar. Tente novamente.', 'erro'); }
  };
}
```

Trocar `$('#grafPrint').onclick = ()=>window.print();` por `ligarImprimir($('#grafPrint'));` e `$('#relPrint').onclick = ()=>window.print();` por `ligarImprimir($('#relPrint'));`.

- [ ] **Step 4: Browser test** — em `nativo.cjs`, novo bloco antes do `console.log`:

```js
    /* ---- Task 5: compartilhar ---- */
    {
      const { ctx, page } = await abrir(browser, { nativo:true });
      await page.evaluate(()=>{ openObra('o1'); showView('relatorio'); renderRelatorio(); });
      assert.match(await page.locator('#relPrint').textContent(), /Compartilhar planilha/);
      await page.locator('#relPrint').click();
      await page.waitForFunction(()=>chamadasNativas.some(c=>c[0]==='Share'));
      const share = await page.evaluate(()=>chamadasNativas.find(c=>c[0]==='Share'));
      assert.match(share[2].files[0], /^file:\/\/\/cache\/custta-.*\.csv$/);
      await page.evaluate(()=>{ showView('graficos'); renderGraficos(); });
      assert.match(await page.locator('#grafPrint').textContent(), /Compartilhar planilha/);
      await ctx.close();
      const web = await abrir(browser, { nativo:false });
      await web.page.evaluate(()=>{ openObra('o1'); showView('relatorio'); renderRelatorio(); });
      assert.match(await web.page.locator('#relPrint').textContent(), /Imprimir/);
      await web.ctx.close();
    }
```

- [ ] **Step 5: Run** `npm run test:unit` e a suíte `nativo.cjs` (servidor no ar) → verdes.

- [ ] **Step 6: Commit**

```bash
git add share.js app.js tests/share.test.cjs tests/browser/nativo.cjs
git commit -m "feat: compartilhar planilha pelo share sheet no app nativo"
```

---

### Task 6: Extrair push para `push.js` (web, sem mudança de comportamento)

**Files:**
- Create: `push.js`
- Create: `tests/push.test.cjs`
- Modify: `app.js` (remover bloco de push ~1282-1330; convite e Ajustes passam a usar `OBRA_PUSH`)
- Modify: `index.html` (script), `sw.js` (ASSETS, CACHE v48), `tests/pwa.test.cjs`, `package.json`

**Interfaces:**
- Produces: `window.OBRA_PUSH = { suportado(): boolean, permissao(): Promise<'default'|'granted'|'denied'>, inscrito(): Promise<boolean>, ativar(): Promise<boolean>, desativar(): Promise<void>, desativa(): Promise<void>, aoAbrirNotificacao(fn: (obraId: string|null) => void): void }`; `require('./push.js')` → `{ criar(win), hashEndpoint, b64ToU8, VAPID_PUBLICA }`.
- Na Task 6 `aoAbrirNotificacao` da web é no-op; a Task 7 implementa.

- [ ] **Step 1: Failing test** — `tests/push.test.cjs`

```js
'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { criar, hashEndpoint } = require('../push.js');

function janelaWeb({ permissao = 'granted', falhaSalvar = false } = {}){
  const log = [];
  let sub = null;
  const pushManager = {
    getSubscription: async()=>sub,
    subscribe: async opcoes=>{ log.push(['subscribe', opcoes.userVisibleOnly]);
      sub = { endpoint:'https://fcm.googleapis.com/fcm/send/abc', toJSON:()=>({ endpoint:'https://fcm.googleapis.com/fcm/send/abc', keys:{ p256dh:'p', auth:'a' } }),
        unsubscribe: async()=>{ log.push(['unsubscribe']); sub = null; } };
      return sub; },
  };
  const win = {
    PushManager:function(){}, Notification:{ permission:'default', requestPermission: async()=>{ win.Notification.permission = permissao; return permissao; } },
    navigator:{ serviceWorker:{ getRegistration: async()=>({ active:{}, pushManager }), addEventListener(){} } },
    location:{ hash:'', pathname:'/', search:'' }, history:{ replaceState(){} },
    CLOUD:{ savePushSub: async(k, v)=>{ log.push(['save', k, v.endpoint]); if(falhaSalvar) throw new Error('rede'); },
            removePushSub: async k=>log.push(['remove', k]) },
    OBRA_DIAG:{ registra(){} },
  };
  return { win, log };
}

test('web: ativar inscreve e grava com chave do endpoint', async()=>{
  const { win, log } = janelaWeb();
  const push = criar(win);
  assert.equal(push.suportado(), true);
  assert.equal(await push.permissao(), 'default');
  assert.equal(await push.ativar(), true);
  assert.equal(await push.inscrito(), true);
  assert.deepEqual(log, [['subscribe', true], ['save', hashEndpoint('https://fcm.googleapis.com/fcm/send/abc'), 'https://fcm.googleapis.com/fcm/send/abc']]);
});

test('web: permissão negada não inscreve', async()=>{
  const { win, log } = janelaWeb({ permissao:'denied' });
  assert.equal(await criar(win).ativar(), false);
  assert.deepEqual(log, []);
});

test('web: falha ao gravar desfaz inscrição e propaga', async()=>{
  const { win, log } = janelaWeb({ falhaSalvar:true });
  await assert.rejects(criar(win).ativar(), /rede/);
  assert.deepEqual(log.at(-1), ['unsubscribe']);
});

test('web: desativar remove inscrição local e remota', async()=>{
  const { win, log } = janelaWeb();
  const push = criar(win);
  await push.ativar(); log.length = 0;
  await push.desativa();
  assert.deepEqual(log, [['unsubscribe'], ['remove', hashEndpoint('https://fcm.googleapis.com/fcm/send/abc')]]);
  assert.equal(await push.inscrito(), false);
});

test('sem suporte: desativa resolve sem tocar em nada', async()=>{
  const push = criar({ navigator:{}, location:{ hash:'' } });
  assert.equal(push.suportado(), false);
  await push.desativa();
});
```

- [ ] **Step 2: Run** `node --test tests/push.test.cjs` → FAIL (módulo ausente).

- [ ] **Step 3: Implement `push.js`**

```js
/* Notificações por aparelho. Web: Web Push (VAPID) pelo service worker.
   app.js e auth.js só conhecem esta interface. */
'use strict';
(function(root){
  const VAPID_PUBLICA = 'BEZVfZrOAgzNMnSS4Hpt-PKwchrfEaW5igUoXdZILQqBWdeC9D2RTp_-JfrTagRU4eK2FM0zC3U0GXYS2LUwiyk';

  function b64ToU8(b64){
    const pad = '='.repeat((4 - b64.length % 4) % 4);
    const raw = atob((b64 + pad).replace(/-/g, '+').replace(/_/g, '/'));
    return Uint8Array.from(raw, c => c.charCodeAt(0));
  }
  /* hash curto do endpoint/token — vira nome de campo no Firestore (sem . nem /) */
  function hashEndpoint(s){
    let h = 5381;
    for(let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) >>> 0;
    return h.toString(36);
  }

  function criarWeb(win){
    const nav = win.navigator || {};
    const suportado = () => 'serviceWorker' in nav && 'PushManager' in win && 'Notification' in win;
    async function atual(){
      const reg = await nav.serviceWorker.getRegistration();
      return reg?.pushManager ? reg.pushManager.getSubscription() : null;
    }
    async function ativar(){
      const perm = await win.Notification.requestPermission();
      if(perm !== 'granted') return false;
      const reg = await nav.serviceWorker.getRegistration();
      if(!reg?.active) throw new Error('Aguarde a preparação do aplicativo e tente novamente.');
      const sub = await reg.pushManager.subscribe({ userVisibleOnly:true, applicationServerKey:b64ToU8(VAPID_PUBLICA) });
      const j = sub.toJSON();
      try{
        await win.CLOUD.savePushSub(hashEndpoint(sub.endpoint), { endpoint:j.endpoint, keys:j.keys, criado:new Date().toISOString() });
      }catch(err){
        await sub.unsubscribe().catch(e => win.OBRA_DIAG?.registra('push-limpeza', e.message, e.stack));
        throw err;
      }
      return true;
    }
    async function desativar(){
      const sub = await atual();
      if(!sub) return;
      const chave = hashEndpoint(sub.endpoint);
      await sub.unsubscribe();
      await win.CLOUD.removePushSub(chave);
    }
    return {
      suportado,
      permissao: async() => win.Notification.permission,
      inscrito: async() => !!(await atual()),
      ativar, desativar,
      /* auth.js chama isto antes do logout — a inscrição precisa morrer junto com a sessão. */
      desativa: () => suportado() ? desativar() : Promise.resolve(),
      aoAbrirNotificacao(){},
    };
  }

  function criar(win){ return criarWeb(win); }

  if(typeof module !== 'undefined') module.exports = { criar, hashEndpoint, b64ToU8, VAPID_PUBLICA };
  if(root) root.OBRA_PUSH = criar(root);
})(typeof window !== 'undefined' ? window : null);
```

- [ ] **Step 4: Rewire `app.js`**

Apagar de `app.js`: `VAPID_PUBLICA`, `pushSuportado`, `b64ToU8`, `hashEndpoint`, `pushAtual`, `ativaPush`, `desativaPush` e a linha `window.OBRA_PUSH = {...}`. Manter `NOTIF_NOTA_PADRAO`.

Convite:

```js
async function atualizarConviteNotif(user){
  esconderConviteNotif();
  conviteNotifUid=user?.uid||null;
  if(!user || !OBRA_PUSH.suportado()) return;
  try{
    if(await OBRA_PUSH.permissao()!=='default') return;
    if(await OBRA_PUSH.inscrito()) return;
    if(convitesRespondidos.has(user.uid) || localStorage.getItem(chaveConviteNotif(user.uid))!==null) return;
    if(conviteNotifUid===user.uid) notifInvite.classList.remove('hidden');
  }catch(err){ registraErro('push-convite',err.message,err.stack); }
}
```

`#notifAtivar`: `const ok=await OBRA_PUSH.ativar();`

Ajustes (`tgN`): `if(!OBRA_PUSH.suportado()){ ... }` (mantém o texto da Task 3) e no `else`:

```js
      Promise.all([OBRA_PUSH.inscrito(), OBRA_PUSH.permissao()]).then(([inscrito, perm]) => {
        const on = inscrito && perm === 'granted';
        tgN.classList.toggle('on', on);
        tgN.setAttribute('aria-checked', String(on));
      });
      tgN.onclick = async () => {
        const nota = $('#ajNotifNota');
        nota.textContent = NOTIF_NOTA_PADRAO;
        try{
          if(await OBRA_PUSH.inscrito()){
            await OBRA_PUSH.desativar();
          }else{
            const ok = await OBRA_PUSH.ativar();
            if(!ok) nota.textContent = OBRA_NATIVO.ehNativo()
              ? 'Permissão negada. Libere em Ajustes do iPhone › Custta › Notificações e tente de novo.'
              : 'Permissão negada. Libere as notificações nas configurações do navegador e tente de novo.';
          }
        }catch(err){
          nota.textContent = 'Não deu pra ativar agora. Tente de novo.';
        }
        renderAjustes();
      };
```

`index.html`: `<script defer src="push.js"></script>` logo antes de `<script defer src="app.js"></script>`.
`sw.js`: `CACHE = 'obras-v48'`, `'./push.js'` em `ASSETS` depois de `'./app.js'`.
`package.json`: ` tests/push.test.cjs` no `test:unit`.

`tests/pwa.test.cjs`: trocar a asserção e o contexto:

```js
assert.ok(app.includes("$('#notifAtivar').onclick") && app.includes('OBRA_PUSH.ativar()'), 'permissão deve partir do clique explícito do usuário');
```

```js
const contexto={$,Set,OBRA_PUSH:{suportado:()=>true,permissao:async()=>'default',inscrito:async()=>null,ativar:async()=>false},
  localStorage:{getItem:k=>memoria.get(k)??null,setItem:(k,v)=>memoria.set(k,v)},
  registraErro:()=>{},toast:()=>{}};
```

e acrescentar `assert.ok(sw.includes("'./push.js'") && sw.includes("'./nativo.js'"), 'push.js e nativo.js no precache');`.

- [ ] **Step 5: Run** `npm run test:unit` e `npm run test:browser` → verdes (a `fase2.cjs`/`persistencia.cjs` cobrem logout com `OBRA_PUSH.desativa`).

- [ ] **Step 6: Commit**

```bash
git add push.js tests/push.test.cjs app.js index.html sw.js tests/pwa.test.cjs package.json
git commit -m "refactor: extrair notificacoes push para push.js"
```

---

### Task 7: Push nativo (FCM) e abrir a obra pela notificação

**Files:**
- Modify: `push.js` (implementação nativa, `aoAbrirNotificacao` web)
- Modify: `cloud.js` (`savePushToken`, `removePushToken`)
- Modify: `sw.js` (payload `obraId`)
- Modify: `app.js` (`bootCloud`, abertura pendente)
- Modify: `ios/App/App/AppDelegate.swift`
- Modify: `tests/push.test.cjs`, `tests/rules.test.mjs`, `tests/browser/nativo.cjs`
- Create: `tests/push-cloud.test.mjs`

**Interfaces:**
- Consumes: `OBRA_NATIVO.plugin('FirebaseMessaging')`; `CLOUD.savePushToken(chave, {token, plataforma, criado})`, `CLOUD.removePushToken(chave)`.
- Produces: `app.js` globais `dadosCarregados: boolean` e `depoisDoPrimeiroSnapshot()` (chamada a cada snapshot aplicado; a Task 11 acrescenta a restauração nela). `localStorage['custta-push-token']` guarda a chave do token neste aparelho.

- [ ] **Step 1: Failing tests**

Acrescentar em `tests/push.test.cjs`:

```js
function janelaNativa({ receive = 'granted', falhaSalvar = false } = {}){
  const log = [], memoria = new Map(), ouvintes = {};
  const fcm = {
    checkPermissions: async()=>({ receive:'prompt' }),
    requestPermissions: async()=>({ receive }),
    getToken: async()=>({ token:'tok-1' }),
    deleteToken: async()=>log.push(['deleteToken']),
    addListener: (ev, fn)=>{ ouvintes[ev] = fn; },
  };
  const win = {
    navigator:{}, location:{ hash:'' },
    OBRA_NATIVO:{ ehNativo:()=>true, plugin:n => n === 'FirebaseMessaging' ? fcm : null },
    localStorage:{ getItem:k=>memoria.get(k) ?? null, setItem:(k,v)=>memoria.set(k,v), removeItem:k=>memoria.delete(k) },
    CLOUD:{ savePushToken: async(k, v)=>{ log.push(['save', k, v.token, v.plataforma]); if(falhaSalvar) throw new Error('rede'); },
            removePushToken: async k=>log.push(['remove', k]) },
    OBRA_DIAG:{ registra(){} },
  };
  return { win, log, ouvintes };
}

test('nativo: ativar pede permissão, grava token e lembra a chave', async()=>{
  const { win, log } = janelaNativa();
  const push = criar(win);
  assert.equal(push.suportado(), true);
  assert.equal(await push.permissao(), 'default');
  assert.equal(await push.ativar(), true);
  assert.equal(await push.inscrito(), true);
  assert.deepEqual(log, [['save', hashEndpoint('tok-1'), 'tok-1', 'ios']]);
  await push.desativa();
  assert.deepEqual(log.slice(1), [['deleteToken'], ['remove', hashEndpoint('tok-1')]]);
  assert.equal(await push.inscrito(), false);
});

test('nativo: negado não grava; falha ao gravar apaga token', async()=>{
  const negado = janelaNativa({ receive:'denied' });
  assert.equal(await criar(negado.win).ativar(), false);
  assert.deepEqual(negado.log, []);
  const falha = janelaNativa({ falhaSalvar:true });
  await assert.rejects(criar(falha.win).ativar(), /rede/);
  assert.deepEqual(falha.log.at(-1), ['deleteToken']);
});

test('nativo: toque na notificação entrega obraId', ()=>{
  const { win, ouvintes } = janelaNativa();
  const recebidos = [];
  criar(win).aoAbrirNotificacao(id => recebidos.push(id));
  ouvintes.notificationActionPerformed({ notification:{ data:{ obraId:'o1' } } });
  ouvintes.notificationActionPerformed({ notification:{ data:{} } });
  assert.deepEqual(recebidos, ['o1', null]);
});

test('web: hash #obra= abre uma vez e mensagem do SW também', ()=>{
  const ouvintes = {}, trocas = [];
  const win = { navigator:{ serviceWorker:{ addEventListener:(ev, fn)=>{ ouvintes[ev] = fn; } } },
    location:{ hash:'#obra=abc123', pathname:'/', search:'' }, history:{ replaceState:(...a)=>trocas.push(a) } };
  const recebidos = [];
  criar(win).aoAbrirNotificacao(id => recebidos.push(id));
  ouvintes.message({ data:{ tipo:'abrir-obra', obraId:'xyz' } });
  ouvintes.message({ data:{ tipo:'outra' } });
  assert.deepEqual(recebidos, ['abc123', 'xyz']);
  assert.equal(trocas.length, 1);
});
```

`tests/push-cloud.test.mjs`:

```js
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { register, createRequire } from 'node:module';
register('./helpers/loader-firebase.mjs', import.meta.url);
const require = createRequire(import.meta.url);
const { __ctrl:ctrl } = await import('./helpers/firebase-stub.mjs');
let cloud;
beforeEach(async()=>{
  const event = new EventTarget();
  globalThis.window = { addEventListener:event.addEventListener.bind(event), dispatchEvent:event.dispatchEvent.bind(event),
    OBRA_CALC:require('../calc.js'), location:{ reload(){} } };
  globalThis.CustomEvent = globalThis.CustomEvent || Event;
  Object.defineProperty(globalThis, 'navigator', { value:{ onLine:true }, configurable:true });
  ctrl.setDocChamadas = []; ctrl.respostas = [];
  await import('../cloud.js?push=' + Math.random()); cloud = window.CLOUD; await cloud.ready;
});
test('token FCM grava e remove em push/{uid}.tokens com merge', async()=>{
  await cloud.savePushToken('k1', { token:'t', plataforma:'ios', criado:'2026-09-16' });
  await cloud.removePushToken('k1');
  assert.deepEqual(ctrl.setDocChamadas.map(c=>[c.ref.path, c.dados]), [
    ['push/u-teste', { tokens:{ k1:{ token:'t', plataforma:'ios', criado:'2026-09-16' } } }],
    ['push/u-teste', { tokens:{ k1:'@del' } }],
  ]);
});
```

`tests/rules.test.mjs`, no `describe('push/{uid}...')`:

```js
  test('mais de 10 tokens FCM é rejeitado', async () => {
    const tokens = {};
    for (let i = 0; i < 11; i++) tokens['t' + i] = { token: 'tok-' + i, plataforma: 'ios' };
    await assertFails(setDoc(doc(comoAna(), 'push', ANA.uid), { tokens }, { merge: true }));
  });
```

Acrescente ` tests/push-cloud.test.mjs` ao `test:unit`.

- [ ] **Step 2: Run** `node --test tests/push.test.cjs tests/push-cloud.test.mjs` → FAIL.

- [ ] **Step 3: Implement `push.js`**

Em `criarWeb`, trocar `aoAbrirNotificacao(){}` por:

```js
      /* Clique na notificação: app fechado abre ./#obra=<id>; aberto recebe postMessage do SW. */
      aoAbrirNotificacao(fn){
        const m = /^#obra=([\w-]+)$/.exec((win.location && win.location.hash) || '');
        if(m){
          win.history.replaceState(null, '', win.location.pathname + win.location.search);
          fn(m[1]);
        }
        nav.serviceWorker?.addEventListener('message', e => {
          if(e.data && e.data.tipo === 'abrir-obra') fn(e.data.obraId || null);
        });
      },
```

Novo `criarNativo` e `criar`:

```js
  /* App iOS: FCM pelo @capacitor-firebase/messaging. O token vai para push/{uid}.tokens;
     a chave fica neste aparelho para o logout conseguir apagar só o próprio token. */
  const CHAVE_TOKEN = 'custta-push-token';
  function criarNativo(win){
    const fcm = () => win.OBRA_NATIVO.plugin('FirebaseMessaging');
    const lerChave = () => { try{ return win.localStorage.getItem(CHAVE_TOKEN); }catch(e){ return null; } };
    async function permissao(){
      const { receive } = await fcm().checkPermissions();
      return receive === 'granted' ? 'granted' : receive === 'denied' ? 'denied' : 'default';
    }
    async function ativar(){
      const { receive } = await fcm().requestPermissions();
      if(receive !== 'granted') return false;
      const { token } = await fcm().getToken();
      const chave = hashEndpoint(token);
      try{
        await win.CLOUD.savePushToken(chave, { token, plataforma:'ios', criado:new Date().toISOString() });
      }catch(err){
        await fcm().deleteToken().catch(e => win.OBRA_DIAG?.registra('push-limpeza', e.message, e.stack));
        throw err;
      }
      try{ win.localStorage.setItem(CHAVE_TOKEN, chave); }catch(e){ win.OBRA_DIAG?.registra('push-token', e.message); }
      return true;
    }
    async function desativar(){
      const chave = lerChave();
      if(!chave) return;
      await fcm().deleteToken();
      await win.CLOUD.removePushToken(chave);
      try{ win.localStorage.removeItem(CHAVE_TOKEN); }catch(e){ /* sem storage não há o que limpar */ }
    }
    return {
      suportado: () => !!fcm(),
      permissao,
      inscrito: async() => !!lerChave(),
      ativar, desativar,
      desativa: () => fcm() ? desativar() : Promise.resolve(),
      aoAbrirNotificacao(fn){
        fcm()?.addListener('notificationActionPerformed', ev => fn(ev?.notification?.data?.obraId || null));
      },
    };
  }

  function criar(win){
    return win && win.OBRA_NATIVO && win.OBRA_NATIVO.ehNativo() ? criarNativo(win) : criarWeb(win);
  }
```

Atualize o comentário do topo: `Web: Web Push (VAPID) pelo service worker. App iOS: FCM.`

- [ ] **Step 4: `cloud.js`** — depois de `removePushSub`:

```js
  /* Token FCM do app iOS. Mesmo documento, campo separado: web e nativo convivem. */
  savePushToken(chave, dados){
    if(!currentUser) return Promise.resolve();
    return setDoc(doc(db, 'push', currentUser.uid), { tokens: { [chave]: dados } }, { merge: true });
  },
  removePushToken(chave){
    if(!currentUser) return Promise.resolve();
    return setDoc(doc(db, 'push', currentUser.uid), { tokens: { [chave]: deleteField() } }, { merge: true });
  },
```

- [ ] **Step 5: `sw.js`** — push e clique:

```js
/* Push: o cron diário manda { titulo, corpo, obraId? } via Web Push. */
self.addEventListener('push', e => {
  let d = {};
  try{ d = e.data.json(); }catch(err){}
  e.waitUntil(self.registration.showNotification(d.titulo || 'Custta', {
    body: d.corpo || '',
    icon: './icon-192.png',
    badge: './icon-192.png',
    data: { obraId: typeof d.obraId === 'string' ? d.obraId : null },
  }));
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  const obraId = e.notification.data && e.notification.data.obraId;
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(ws => {
      for(const w of ws){
        if('focus' in w){
          if(obraId) w.postMessage({ tipo: 'abrir-obra', obraId });
          return w.focus();
        }
      }
      return clients.openWindow(obraId ? './#obra=' + encodeURIComponent(obraId) : './');
    })
  );
});
```

Incremente `CACHE` para `obras-v49`.

- [ ] **Step 6: `app.js`** — antes de `function bootCloud(){`:

```js
/* Aberturas que dependem dos dados reais (toque em notificação, restauração de estado)
   só acontecem depois do primeiro snapshot — antes disso db está vazio. */
let dadosCarregados = false;
let obraDaNotificacao; // undefined = nada pendente; null = abrir Início
function depoisDoPrimeiroSnapshot(){
  if(!dadosCarregados) return;
  if(obraDaNotificacao !== undefined){
    const id = obraDaNotificacao; obraDaNotificacao = undefined;
    if(id && obraById(id)) openObra(id);
    else { obraAberta = null; showView('inicio'); renderAll(); }
  }
}
OBRA_PUSH.aoAbrirNotificacao(id => { obraDaNotificacao = id; depoisDoPrimeiroSnapshot(); });
```

Em `bootCloud`, no ramo `if(!user){`, acrescentar `dadosCarregados = false;` no começo. Trocar o callback de `watchDados` por:

```js
    unwatch = CLOUD.watchDados((blob, meta)=>{
      if(meta.localDirty) return; // preserva edições desta sessão; restaura cache após reabrir
      const novo = normaliza(blob);
      // conteúdo igual: não troca os objetos (Firestore devolve chaves em ordem diferente)
      if(canon(novo) !== canon(db)){
        db = novo;
        if(obraAberta && !novo.obras.some(o=>o.id===obraAberta)){ obraAberta=null; showView('inicio'); }
        renderAll();
      }
      dadosCarregados = true;
      depoisDoPrimeiroSnapshot();
    });
```

- [ ] **Step 7: `ios/App/App/AppDelegate.swift`** — confirme primeiro que o plugin configura o Firebase sozinho:

Run: `grep -rn "FirebaseApp.configure" node_modules/@capacitor-firebase/messaging/ios`
Expected: ao menos uma ocorrência. Se **não** houver, acrescente `import FirebaseCore` e `FirebaseApp.configure()` no `didFinishLaunchingWithOptions` antes do `return true` — e só então.

Dentro da classe `AppDelegate`, acrescentar os dois métodos que o plugin exige:

```swift
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationCenter.default.post(name: .capacitorDidRegisterForRemoteNotifications, object: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(name: .capacitorDidFailToRegisterForRemoteNotifications, object: error)
    }
```

- [ ] **Step 8: Browser test** — em `nativo.cjs`:

```js
    /* ---- Task 7: push nativo ---- */
    {
      const { ctx, page } = await abrir(browser, { nativo:true });
      await page.evaluate(()=>{ showView('ajustes'); renderAjustes(); });
      await page.locator('#ajNotif').click();
      await page.waitForFunction(()=>window.tokenSalvo);
      assert.equal(await page.evaluate(()=>tokenSalvo[1].token), 'tok-teste');
      await page.evaluate(()=>ouvintesNativos['FirebaseMessaging:notificationActionPerformed']({ notification:{ data:{ obraId:'o1' } } }));
      await page.waitForFunction(()=>obraAberta === 'o1');
      assert.equal(await page.locator('#v-obra').isVisible(), true);
      await ctx.close();
    }
```

- [ ] **Step 9: Run** `npm run test:unit`, `npm run test:rules`, `npm run test:browser`, `npm run cap:sync` → verdes.

- [ ] **Step 10: Commit**

```bash
git add push.js cloud.js sw.js app.js ios/App/App/AppDelegate.swift tests/push.test.cjs tests/push-cloud.test.mjs tests/rules.test.mjs tests/browser/nativo.cjs package.json
git commit -m "feat: receber notificacoes fcm no app nativo e abrir a obra certa"
```

---

### Task 8: Envio FCM no servidor de notificações

**Files:**
- Modify: `notificacoes/resumo.js` (`obraId`)
- Create: `notificacoes/enviar.js`
- Modify: `notificacoes/envia.js` (CLI fino)
- Modify: `tests/resumo.test.cjs`
- Create: `tests/enviar.test.cjs`
- Modify: `package.json`

**Interfaces:**
- Produces: `require('./notificacoes/enviar.js').enviaTodos({ db, webpush, messaging, FieldPath, FieldValue, periodo, agora, log }) : Promise<{ enviados: number, removidos: number }>`. `db` segue a API Admin (`collection().get()`, `doc().get()`, `ref.update(FieldPath, FieldValue.delete())`). `log` = `{ info(msg), warn(msg), error(msg) }`. Consumido pela Task 9.

- [ ] **Step 1: Failing tests**

Acrescentar em `tests/resumo.test.cjs` antes do fim:

```js
t('obraId só quando exatamente uma obra gera o resumo', () => {
  const uma = { obras: [ { id:'o1', nome:'A', fase:'construcao', gastos: [] }, { id:'o2', nome:'B', fase:'vendida', gastos: [] } ] };
  assert.strictEqual(montaResumo(uma, '2026-07-10', 'noite').obraId, 'o1');
  const duas = { obras: [ { id:'o1', fase:'construcao', gastos: [] }, { id:'o2', fase:'construcao', gastos: [] } ] };
  assert.strictEqual('obraId' in montaResumo(duas, '2026-07-10', 'noite'), false);
  const afazer = { obras: [ { id:'o1', fase:'pronta', afazeres:[{ feito:false }], gastos: [] }, { id:'o2', fase:'pronta', gastos: [] } ] };
  assert.strictEqual(montaResumo(afazer, '2026-07-10', 'manha').obraId, 'o1');
});
```

`tests/enviar.test.cjs`:

```js
'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { enviaTodos } = require('../notificacoes/enviar.js');

const FieldPath = function(...partes){ this.partes = partes; };
const FieldValue = { delete:()=>'@del' };
const silencioso = { info(){}, warn(){}, error(){} };

function banco(pushDocs, dados){
  const removidos = [];
  return { removidos, db:{
    collection:()=>({ get:async()=>({ size:pushDocs.length, docs:pushDocs.map(([id, d])=>({ id, data:()=>d,
      ref:{ update:async(fp, v)=>removidos.push([id, ...fp.partes, v]) } })) }) }),
    doc:caminho=>({ get:async()=>({ data:()=>caminho.startsWith('dados/') ? dados : { tz:'America/Sao_Paulo' } }) }),
  } };
}
const DADOS = { obras:[{ id:'o1', nome:'Casa', fase:'construcao', gastos:[] }] };

test('envia por web push e FCM com obraId e remove tokens mortos', async()=>{
  const { db, removidos } = banco([['ana', {
    subs:{ s1:{ endpoint:'https://fcm.googleapis.com/fcm/send/x', keys:{} } },
    tokens:{ t1:{ token:'vivo' }, t2:{ token:'morto' }, t3:'formato-antigo' },
  }]], DADOS);
  const web = [], fcm = [];
  const r = await enviaTodos({ db, FieldPath, FieldValue, periodo:'noite', agora:new Date('2026-07-10T21:00:00Z'), log:silencioso,
    webpush:{ sendNotification:async(sub, payload)=>web.push([sub.endpoint, JSON.parse(payload)]) },
    messaging:{ send:async msg=>{ if(msg.token === 'morto') throw Object.assign(new Error('x'), { code:'messaging/registration-token-not-registered' }); fcm.push(msg); } },
  });
  assert.equal(web[0][1].obraId, 'o1');
  assert.deepEqual(fcm.map(m=>m.token), ['vivo', 'formato-antigo']);
  assert.deepEqual(fcm[0].notification, { title:'Custta', body:'Lançou os gastos de hoje?' });
  assert.deepEqual(fcm[0].data, { obraId:'o1' });
  assert.equal(fcm[0].apns.payload.aps.sound, 'default');
  assert.deepEqual(removidos, [['ana', 'tokens', 't2', '@del']]);
  assert.deepEqual(r, { enviados:3, removidos:1 });
});

test('falha transitória não remove token nem derruba os outros', async()=>{
  const { db, removidos } = banco([['ana', { tokens:{ a:{ token:'1' }, b:{ token:'2' } } }]], DADOS);
  const enviados = [];
  await enviaTodos({ db, FieldPath, FieldValue, periodo:'noite', agora:new Date('2026-07-10T21:00:00Z'), log:silencioso, webpush:{},
    messaging:{ send:async m=>{ if(m.token === '1') throw Object.assign(new Error('x'), { code:'messaging/internal-error' }); enviados.push(m.token); } } });
  assert.deepEqual(enviados, ['2']);
  assert.deepEqual(removidos, []);
});

test('sem subs nem tokens não lê dados', async()=>{
  let leu = false;
  const db = { collection:()=>({ get:async()=>({ size:1, docs:[{ id:'x', data:()=>({}), ref:{} }] }) }), doc:()=>{ leu = true; } };
  await enviaTodos({ db, FieldPath, FieldValue, periodo:'noite', agora:new Date(), log:silencioso, webpush:{}, messaging:{} });
  assert.equal(leu, false);
});
```

Acrescente ` tests/enviar.test.cjs` ao `test:unit`.

- [ ] **Step 2: Run** `node --test tests/enviar.test.cjs && node tests/resumo.test.cjs` → FAIL.

- [ ] **Step 3: `resumo.js`** — rastrear quais obras contribuem:

```js
function montaResumo(dados, hojeISO, periodo){
  if(!dados || !Array.isArray(dados.obras) || !dados.obras.length) return null;
  const obras = dados.obras.filter(o => o && typeof o === 'object');
  const linhas = [];
  const origem = new Set(); // obras que geraram alguma linha — uma só vira atalho no toque

  // afazeres não riscados, somando todas as obras (campo é opcional por obra)
  const pend = obras.reduce((s, o) => {
    const afazeres = Array.isArray(o.afazeres) ? o.afazeres : [];
    const n = afazeres.filter(a => a && typeof a === 'object' && !a.feito).length;
    if(n) origem.add(o.id);
    return s + n;
  }, 0);
  if(pend > 0) linhas.push(pend === 1 ? '1 afazer pendente' : pend + ' afazeres pendentes');

  // parcelas: só dia 1 — gastos com data dentro do mês corrente ainda não vencidos
  if(hojeISO.slice(8) === '01'){
    const mes = hojeISO.slice(0, 7);
    let qtd = 0, total = 0;
    for(const o of obras) for(const g of (Array.isArray(o.gastos) ? o.gastos : [])){
      if(g && typeof g.data === 'string' && g.data.slice(0, 7) === mes && g.data >= hojeISO){
        qtd++; total += Number(g.valor) || 0; origem.add(o.id);
      }
    }
    if(qtd > 0) linhas.push((qtd === 1 ? '1 parcela vence' : qtd + ' parcelas vencem')
      + ' este mês (' + BRL.format(total) + ')');
  }

  // lembrete de lançar: só à noite, com obra em andamento e nada lançado hoje
  if(periodo !== 'manha'){
    const emObra = obras.filter(o => o.fase === 'construcao');
    const lancouHoje = obras.some(o => (Array.isArray(o.gastos) ? o.gastos : [])
      .some(g => g && g.data === hojeISO));
    if(emObra.length && !lancouHoje){
      linhas.push('Lançou os gastos de hoje?');
      emObra.forEach(o => origem.add(o.id));
    }
  }

  if(!linhas.length) return null;
  const resumo = { titulo: 'Custta', corpo: linhas.join('\n') };
  const [unica] = origem;
  if(origem.size === 1 && typeof unica === 'string') resumo.obraId = unica;
  return resumo;
}
```

- [ ] **Step 4: `notificacoes/enviar.js`**

```js
'use strict';
/* Resumo diário para todos os aparelhos: Web Push (subs) e FCM (tokens do app iOS).
   Dependências injetadas: roda igual no GitHub Actions, na Vercel e nos testes.
   Inscrição/token morto é removido; falha num aparelho não derruba o resto. */
const { montaResumo, endpointPushValido } = require('./resumo.js');
const { hojeNoFuso } = require('./fuso.js');

const TOKEN_MORTO = new Set(['messaging/registration-token-not-registered', 'messaging/invalid-registration-token', 'messaging/invalid-argument']);

async function enviaTodos({ db, webpush, messaging, FieldPath, FieldValue, periodo, agora, log }){
  const r = { enviados: 0, removidos: 0 };
  const remove = async(pdoc, campo, chave, motivo) => {
    await pdoc.ref.update(new FieldPath(campo, chave), FieldValue.delete());
    r.removidos++;
    log.warn(pdoc.id + '/' + chave + ': ' + motivo + ', removido');
  };
  const pushDocs = await db.collection('push').get();
  log.info(pushDocs.size + ' usuario(s) com push; hoje = ' + hojeNoFuso(null, agora) + '; periodo = ' + periodo);

  for(const pdoc of pushDocs.docs){
    const uid = pdoc.id;
    const doc = pdoc.data() || {};
    const subs = doc.subs || {}, tokens = doc.tokens || {};
    if(!Object.keys(subs).length && !Object.keys(tokens).length) continue;

    const snap = await db.doc('dados/' + uid).get();
    const perfil = await db.doc('perfis/' + uid).get();
    const resumo = montaResumo(snap.data(), hojeNoFuso(perfil.data()?.tz, agora), periodo);
    if(!resumo){ log.info(uid + ': nada a dizer'); continue; }

    const payload = JSON.stringify(resumo);
    for(const [k, s] of Object.entries(subs)){
      if(!s || !endpointPushValido(s.endpoint)){ await remove(pdoc, 'subs', k, 'endpoint inválido'); continue; }
      try{
        await webpush.sendNotification({ endpoint: s.endpoint, keys: s.keys }, payload);
        r.enviados++; log.info(uid + '/' + k + ': enviado');
      }catch(err){
        if(err.statusCode === 404 || err.statusCode === 410) await remove(pdoc, 'subs', k, 'inscricao morta');
        else log.error(uid + '/' + k + ': falha ' + (err.statusCode || err.message));
      }
    }

    for(const [k, t] of Object.entries(tokens)){
      const token = typeof t === 'string' ? t : t && t.token;
      if(!token){ await remove(pdoc, 'tokens', k, 'token inválido'); continue; }
      try{
        await messaging.send({
          token,
          notification: { title: resumo.titulo, body: resumo.corpo },
          data: resumo.obraId ? { obraId: resumo.obraId } : {},
          apns: { payload: { aps: { sound: 'default' } } },
        });
        r.enviados++; log.info(uid + '/' + k + ': enviado (fcm)');
      }catch(err){
        if(TOKEN_MORTO.has(err.code)) await remove(pdoc, 'tokens', k, 'token morto');
        else log.error(uid + '/' + k + ': falha fcm ' + (err.code || err.message));
      }
    }
  }
  return r;
}

module.exports = { enviaTodos };
```

`notificacoes/envia.js` (substituir inteiro):

```js
'use strict';
/* CLI do cron (GitHub Actions, 9h e 18h de Brasília). A lógica vive em enviar.js.
   PERIODO ('manha'|'noite') vem do workflow e muda o conteúdo da mensagem. */
const admin = require('firebase-admin');
const webpush = require('web-push');
const { enviaTodos } = require('./enviar.js');

admin.initializeApp({ credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)) });
webpush.setVapidDetails(process.env.VAPID_SUBJECT, process.env.VAPID_PUBLIC, process.env.VAPID_PRIVATE);

// qualquer valor inesperado cai em 'noite', que é o resumo completo
const periodo = process.env.PERIODO === 'manha' ? 'manha' : 'noite';

enviaTodos({
  db: admin.firestore(), webpush, messaging: admin.messaging(),
  FieldPath: admin.firestore.FieldPath, FieldValue: admin.firestore.FieldValue,
  periodo, agora: new Date(),
  log: { info: m => console.log(m), warn: m => console.warn(m), error: m => console.error(m) },
}).then(r => { console.log(JSON.stringify(r)); process.exit(0); })
  .catch(err => { console.error(err); process.exit(1); });
```

- [ ] **Step 5: Run** `npm run test:unit` → verde. Rode também `node -e "require('./notificacoes/enviar.js')"` → sem erro.

- [ ] **Step 6: Commit**

```bash
git add notificacoes/resumo.js notificacoes/enviar.js notificacoes/envia.js tests/resumo.test.cjs tests/enviar.test.cjs package.json
git commit -m "feat: enviar resumo diario por fcm e indicar a obra da notificacao"
```

---

### Task 9: Rota Vercel Cron (inerte até configurar)

**Files:**
- Create: `api/push-diario.js`
- Create: `tests/cron.test.cjs`
- Modify: `vercel.json` (`crons`)
- Modify: `package.json` (`dependencies` do servidor, `test:unit`)
- Modify: `notificacoes/README.md`

**Interfaces:**
- Consumes: `enviaTodos` (Task 8).
- Produces: `module.exports = criarHandler(deps?)` default handler; `module.exports.criarHandler(carregar: () => ({ enviaTodos, deps }))`.

- [ ] **Step 1: Failing test** — `tests/cron.test.cjs`

```js
'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { criarHandler } = require('../api/push-diario.js');

function resposta(){
  const r = { status:0, corpo:null };
  r.res = { status(c){ r.status = c; return this; }, json(b){ r.corpo = b; return this; } };
  return r;
}
const carregar = chamadas => () => ({ enviaTodos: async a => { chamadas.push(a.periodo); return { enviados:2, removidos:0 }; }, deps:{} });

test('sem CRON_SECRET configurado responde 503 e não envia', async()=>{
  const chamadas = [], r = resposta();
  await criarHandler(carregar(chamadas), {})({ headers:{}, query:{} }, r.res);
  assert.equal(r.status, 503); assert.deepEqual(chamadas, []);
});

test('segredo errado responde 401', async()=>{
  const chamadas = [], r = resposta();
  await criarHandler(carregar(chamadas), { CRON_SECRET:'s3' })({ headers:{ authorization:'Bearer outro' }, query:{} }, r.res);
  assert.equal(r.status, 401); assert.deepEqual(chamadas, []);
});

test('segredo certo envia com período da query', async()=>{
  const chamadas = [], r = resposta();
  await criarHandler(carregar(chamadas), { CRON_SECRET:'s3' })({ headers:{ authorization:'Bearer s3' }, query:{ periodo:'manha' } }, r.res);
  assert.equal(r.status, 200); assert.deepEqual(chamadas, ['manha']); assert.deepEqual(r.corpo, { enviados:2, removidos:0 });
  const r2 = resposta();
  await criarHandler(carregar(chamadas), { CRON_SECRET:'s3' })({ headers:{ authorization:'Bearer s3' }, query:{ periodo:'xyz' } }, r2.res);
  assert.equal(chamadas.at(-1), 'noite');
});

test('vercel.json agenda 9h e 18h de Brasília na rota', ()=>{
  const v = require('../vercel.json');
  assert.deepEqual(v.crons, [
    { path:'/api/push-diario?periodo=manha', schedule:'0 12 * * *' },
    { path:'/api/push-diario?periodo=noite', schedule:'0 21 * * *' },
  ]);
});
```

Acrescente ` tests/cron.test.cjs` ao `test:unit`.

- [ ] **Step 2: Run** `node --test tests/cron.test.cjs` → FAIL.

- [ ] **Step 3: `api/push-diario.js`**

```js
'use strict';
/* Vercel Cron do resumo diário. Inerte até existir CRON_SECRET na Vercel:
   enquanto isso o GitHub Actions continua sendo o único disparo (ver notificacoes/README.md). */
const { timingSafeEqual } = require('node:crypto');

function carregarPadrao(){
  const admin = require('firebase-admin');
  const webpush = require('web-push');
  const { enviaTodos } = require('../notificacoes/enviar.js');
  if(!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)) });
  webpush.setVapidDetails(process.env.VAPID_SUBJECT, process.env.VAPID_PUBLIC, process.env.VAPID_PRIVATE);
  return { enviaTodos, deps: {
    db: admin.firestore(), webpush, messaging: admin.messaging(),
    FieldPath: admin.firestore.FieldPath, FieldValue: admin.firestore.FieldValue,
  } };
}

function segredoConfere(recebido, esperado){
  const a = Buffer.from(String(recebido || '')), b = Buffer.from('Bearer ' + esperado);
  return a.length === b.length && timingSafeEqual(a, b);
}

function criarHandler(carregar = carregarPadrao, env = process.env){
  return async function handler(req, res){
    if(!env.CRON_SECRET) return res.status(503).json({ erro: 'cron desativado' });
    if(!segredoConfere(req.headers.authorization, env.CRON_SECRET)) return res.status(401).json({ erro: 'nao autorizado' });
    const periodo = req.query && req.query.periodo === 'manha' ? 'manha' : 'noite';
    try{
      const { enviaTodos, deps } = carregar();
      const r = await enviaTodos({ ...deps, periodo, agora: new Date(), log: console });
      return res.status(200).json(r);
    }catch(err){
      console.error(err);
      return res.status(500).json({ erro: 'falha no envio' });
    }
  };
}

module.exports = criarHandler();
module.exports.criarHandler = criarHandler;
```

`console` tem `info/warn/error`, então serve como `log`.

- [ ] **Step 4: `vercel.json`** — acrescentar no objeto raiz, depois de `headers`:

```json
  "crons": [
    { "path": "/api/push-diario?periodo=manha", "schedule": "0 12 * * *" },
    { "path": "/api/push-diario?periodo=noite", "schedule": "0 21 * * *" }
  ]
```

`package.json` — a função da Vercel resolve módulos a partir da raiz; acrescentar:

```json
  "dependencies": {
    "firebase-admin": "^14.3.0",
    "web-push": "^3.6.7"
  },
```

(São dependências do servidor, nunca carregadas pelo browser.) Rode `npm install` para atualizar o lock. Atualize a `description` do `package.json`: `"Custta: aplicação estática sem build no deploy; npm mantém SDK local, testes, Capacitor e a função de cron do servidor."`

- [ ] **Step 5: README** — acrescentar ao fim de `notificacoes/README.md`:

```markdown
## Trocar para Vercel Cron (opcional, recomendado antes do lançamento)

O GitHub desativa cron após 60 dias sem atividade no repositório. A rota
`api/push-diario.js` e os `crons` do `vercel.json` já existem, mas respondem
503 enquanto `CRON_SECRET` não estiver configurado — nada é enviado em dobro.

1. Vercel → projeto → Settings → Environment Variables (Production):
   `CRON_SECRET` (valor aleatório longo), `FIREBASE_SERVICE_ACCOUNT`,
   `VAPID_PUBLIC`, `VAPID_PRIVATE`, `VAPID_SUBJECT` — mesmos valores dos secrets do GitHub.
2. **No mesmo deploy**, remover o bloco `schedule:` de `.github/workflows/push-diario.yml`
   (manter `workflow_dispatch` para teste manual) e ajustar `tests/workflow.test.cjs`.
3. Fazer o deploy. Vercel → Cron Jobs → "Run" em `/api/push-diario?periodo=noite`
   e conferir o log (`{"enviados":N,"removidos":M}`).
4. Para o app iOS, subir a chave APNs `.p8` em Firebase → Configurações do projeto →
   Cloud Messaging → Apple app configuration.
```

- [ ] **Step 6: Run** `npm run test:unit` → verde.

- [ ] **Step 7: Commit**

```bash
git add api/push-diario.js tests/cron.test.cjs vercel.json package.json package-lock.json notificacoes/README.md
git commit -m "feat: preparar cron de notificacoes na vercel desativado por padrao"
```

---

### Task 10: Haptics, status bar, splash nativo e flush em segundo plano

**Files:**
- Modify: `app.js` (`salvarComAviso` do gasto, `aplicaTema`, `aplicaSkin`, fim do arquivo)
- Modify: `splash-pre.js`, `splash.js`
- Modify: `tests/browser/nativo.cjs`

**Interfaces:**
- Consumes: `OBRA_NATIVO.vibrar/barraStatus/esconderSplash/aoSegundoPlano` (Task 1); `CLOUD.tentarDeNovo()` (existente); `CLOUD.ready` (existente).

- [ ] **Step 1: Failing browser test** — em `nativo.cjs`:

```js
    /* ---- Task 10: adições nativas ---- */
    {
      // sem splashVista: prova que o splash web some mesmo na primeira abertura
      const antes = ctx => ctx.addInitScript(()=>sessionStorage.removeItem('splashVista'));
      const { ctx, page } = await abrir(browser, { nativo:true, antes });
      const chamou = (p, m) => page.evaluate(([p, m]) => chamadasNativas.filter(c => c[0] === p && c[1] === m), [p, m]);
      await page.waitForFunction(()=>chamadasNativas.some(c=>c[0]==='SplashScreen' && c[1]==='hide'));
      assert.deepEqual((await chamou('StatusBar', 'setStyle')).at(-1)[2], { style:'DARK' }, 'tema escuro padrão → texto claro');
      await page.evaluate(()=>aplicaTema(true));
      assert.deepEqual((await chamou('StatusBar', 'setStyle')).at(-1)[2], { style:'LIGHT' });
      await page.evaluate(()=>{ openObra('o1'); formGasto('o1', null, 50); });
      await page.locator('#fDesc').fill('Areia');
      await page.locator('#cSave').click();
      await page.waitForFunction(()=>chamadasNativas.some(c=>c[0]==='Haptics'));
      await page.evaluate(()=>ouvintesNativos['App:appStateChange']({ isActive:false }));
      assert.equal(await page.evaluate(()=>window.flushes), 1);
      assert.equal(await page.locator('#splash').count(), 0, 'splash web não aparece no nativo');
      await ctx.close();
    }
```

Init scripts rodam na ordem de registro; o do `antes` roda depois do harness e remove o `splashVista`.

- [ ] **Step 2: Run** suíte → FAIL em `SplashScreen hide`.

- [ ] **Step 3: Implement**

`splash-pre.js`:

```js
/* Remove o splash antes da pintura quando já apareceu nesta sessão.
   No app nativo quem cobre a abertura é o splash do iOS. */
'use strict';
if(sessionStorage.getItem('splashVista') || window.OBRA_NATIVO?.ehNativo()) document.getElementById('splash')?.remove();
```

`splash.js`: nenhuma mudança necessária (sai cedo com `if(!splash) return;`). Confirme lendo o arquivo.

`app.js` — em `aplicaTema` e `aplicaSkin`, logo antes de `renderAll();`: `OBRA_NATIVO.barraStatus(temaClaro());`

`app.js` — gasto: na linha `salvarComAviso(isEdit ? 'Gasto atualizado' : 'Gasto lançado com sucesso');` trocar por:

```js
    salvarComAviso(isEdit ? 'Gasto atualizado' : 'Gasto lançado com sucesso')
      .then(()=>OBRA_NATIVO.vibrar(), ()=>{}); // vibra só com o servidor confirmando
```

`app.js` — fim do arquivo, antes de `renderAll(); // primeiro paint`:

```js
/* ---------- app nativo: barra de status, splash e segundo plano ---------- */
if(OBRA_NATIVO.ehNativo()){
  OBRA_NATIVO.barraStatus(temaClaro());
  const esconder = ()=>OBRA_NATIVO.esconderSplash();
  if(window.CLOUD) CLOUD.ready.then(esconder, esconder);
  else window.addEventListener('cloud-pronto', ()=>CLOUD.ready.then(esconder, esconder), { once:true });
  setTimeout(esconder, 8000); // teto: primeira abertura sem rede não pode prender no splash
  // iOS pode matar o app em segundo plano: entrega ao SDK o que estiver pendente
  OBRA_NATIVO.aoSegundoPlano(()=>{ if(window.CLOUD) CLOUD.tentarDeNovo().catch(()=>{}); });
}
```

(`CLOUD.tentarDeNovo()` já devolve promise com `catch` interno; o `.catch` extra é defesa.)

- [ ] **Step 4: Run** `npm run test:unit` e `npm run test:browser` → verdes.

- [ ] **Step 5: Commit**

```bash
git add app.js splash-pre.js tests/browser/nativo.cjs
git commit -m "feat: integrar vibracao, barra de status e splash nativos"
```

---

### Task 11: Restaurar tela e obra ao reabrir

**Files:**
- Modify: `app.js` (`showView`, `openObra`, `depoisDoPrimeiroSnapshot`, ramo sem usuário de `bootCloud`)
- Modify: `tests/browser/nativo.cjs`

**Interfaces:**
- Consumes: `dadosCarregados`, `depoisDoPrimeiroSnapshot()` (Task 7).
- Produces: `localStorage['custta-estado'] = JSON {tab: string, obraAberta: string|null}`.

- [ ] **Step 1: Failing browser test** — em `nativo.cjs`:

```js
    /* ---- Task 11: restauração ---- */
    {
      const { ctx, page } = await abrir(browser, { nativo:true });
      await page.evaluate(()=>{ openObra('o1'); showView('relatorio'); renderRelatorio(); });
      await page.reload();
      await page.waitForFunction(()=>typeof db !== 'undefined' && db.obras.length === 1);
      await page.waitForFunction(()=>obraAberta === 'o1' && tab === 'relatorio');
      await page.evaluate(()=>localStorage.setItem('custta-estado', JSON.stringify({ tab:'obra', obraAberta:'sumiu' })));
      await page.reload();
      await page.waitForFunction(()=>typeof db !== 'undefined' && db.obras.length === 1);
      await page.waitForTimeout(300);
      assert.equal(await page.evaluate(()=>tab), 'inicio', 'obra apagada volta ao início');
      await ctx.close();
    }
```

- [ ] **Step 2: Run** → FAIL (timeout em `obraAberta === 'o1'`).

- [ ] **Step 3: Implement** — em `app.js`, perto de `showView`:

```js
/* iOS mata o app em segundo plano e o WKWebView recarrega do zero: lembra onde
   o usuário estava. Preferência por aparelho, não é dado de obra. */
const ESTADO_KEY = 'custta-estado';
let estadoRestaurado = false;
function lembraEstado(){
  if(!estadoRestaurado) return; // antes de restaurar, o boot não pode sobrescrever o salvo
  try{ localStorage.setItem(ESTADO_KEY, JSON.stringify({ tab, obraAberta })); }
  catch(e){ registraErro('estado', e && e.message); }
}
function restauraEstado(){
  if(estadoRestaurado) return;
  estadoRestaurado = true;
  let salvo = null;
  try{ salvo = JSON.parse(localStorage.getItem(ESTADO_KEY) || 'null'); }catch(e){ salvo = null; }
  if(!salvo || typeof salvo.tab !== 'string' || !document.getElementById('v-' + salvo.tab)) return;
  if(salvo.obraAberta && obraById(salvo.obraAberta)){
    openObra(salvo.obraAberta);
    if(salvo.tab === 'relatorio'){ showView('relatorio'); renderRelatorio(); }
    else if(salvo.tab === 'graficos'){ showView('graficos'); renderGraficos(); }
  }else if(!['obra', 'relatorio', 'graficos'].includes(salvo.tab)){
    showView(salvo.tab); renderAll();
  }else{
    showView('inicio'); renderAll();
  }
}
```

Em `showView(v)`, última linha antes do `}`: `lembraEstado();`
Em `openObra`, nada extra (chama `showView`).

Em `depoisDoPrimeiroSnapshot`, trocar por:

```js
function depoisDoPrimeiroSnapshot(){
  if(!dadosCarregados) return;
  if(obraDaNotificacao !== undefined){
    estadoRestaurado = true; // notificação vence a restauração
    const id = obraDaNotificacao; obraDaNotificacao = undefined;
    if(id && obraById(id)) openObra(id);
    else { obraAberta = null; showView('inicio'); renderAll(); }
    return;
  }
  restauraEstado();
}
```

Em `bootCloud`, no ramo `if(!user){`: acrescentar `try{ localStorage.removeItem(ESTADO_KEY); }catch(e){}` e `estadoRestaurado = false;` **antes** de `showView('inicio')` (o `showView` não grava porque `estadoRestaurado` é falso).

Confirme com `grep -n "renderRelatorio\|renderGraficos" app.js` que as views `v-relatorio` e `v-graficos` dependem de `obraAberta` (sim: são abertas a partir da obra).

- [ ] **Step 4: Run** `npm run test:browser` → verde (inclui `mobile.cjs`, `fase2.cjs` que fazem logout/login).

- [ ] **Step 5: Commit**

```bash
git add app.js tests/browser/nativo.cjs
git commit -m "feat: reabrir o app na mesma tela e obra"
```

---

### Task 12: Aviso de versão nova da loja

**Files:**
- Create: `versao.json`
- Modify: `calc.js` (`versaoMaior`), `tests/calc.test.cjs`
- Modify: `scripts/build-www.mjs` (grava `versao-app.js`, inclui script), `tests/build-www.test.mjs`
- Modify: `index.html` (banner em Ajustes), `styles.css`, `app.js`
- Modify: `vercel.json` (CORS de `/versao.json`), `tests/headers.test.cjs`
- Modify: `tests/browser/nativo.cjs`

**Interfaces:**
- Produces: `OBRA_CALC.versaoMaior(a: string, b: string): boolean` (true se `a` > `b`, semver `x.y.z`, entradas inválidas → false). `construir({ raiz, destino })` passa a gravar `www/versao-app.js` com `window.APP_VERSAO="<versao de versao.json>";` e inserir `<script src="versao-app.js"></script>` antes de `<script src="nativo.js"></script>`.

- [ ] **Step 1: Failing tests**

`tests/calc.test.cjs` — acrescentar no mesmo estilo do arquivo (confira o helper usado no topo com `sed -n 1,15p tests/calc.test.cjs` e siga-o):

```js
t('versaoMaior compara semver numérico e ignora inválidos', () => {
  assert.strictEqual(C.versaoMaior('1.0.10', '1.0.9'), true);
  assert.strictEqual(C.versaoMaior('1.2.0', '1.10.0'), false);
  assert.strictEqual(C.versaoMaior('2.0.0', '2.0.0'), false);
  assert.strictEqual(C.versaoMaior('abc', '1.0.0'), false);
  assert.strictEqual(C.versaoMaior('1.0.0', undefined), false);
});
```

(Troque `t`/`C` pelos nomes que o arquivo já usa para registrar teste e para o módulo `calc.js`.)

`tests/build-www.test.mjs` — no primeiro teste, depois do `await access(...)`:

```js
  const versao = JSON.parse(await readFile(join(raiz, 'versao.json'), 'utf8')).versao;
  assert.equal(await readFile(join(destino, 'versao-app.js'), 'utf8'), `window.APP_VERSAO=${JSON.stringify(versao)};\n`);
  assert.ok(html.indexOf('<script src="versao-app.js"></script>') < html.indexOf('<script src="nativo.js"></script>'));
```

No teste "arquivo listado ausente", grave também `await writeFile(join(falsa, 'versao.json'), '{"versao":"1.0.0"}');`.

`tests/headers.test.cjs` — no fim, antes do `console.log`:

```js
const versaoHeaders = vercel.headers.find(h => h.source === '/versao.json');
assert.ok(versaoHeaders, 'versao.json precisa de CORS para o app nativo');
assert.deepStrictEqual(versaoHeaders.headers.find(h => h.key === 'Access-Control-Allow-Origin'), { key:'Access-Control-Allow-Origin', value:'capacitor://localhost' });
```

- [ ] **Step 2: Run** `npm run test:unit` → FAIL nos três.

- [ ] **Step 3: Implement**

`versao.json`:

```json
{
  "versao": "1.0.0",
  "loja": ""
}
```

`calc.js` — junto das outras funções puras, e exportar em `module.exports`/`OBRA_CALC` do mesmo jeito que as demais:

```js
/* "1.0.10" > "1.0.9". Qualquer coisa fora de x.y.z não dispara aviso. */
function versaoMaior(a, b){
  const partes = v => typeof v === 'string' && /^\d+\.\d+\.\d+$/.test(v) ? v.split('.').map(Number) : null;
  const x = partes(a), y = partes(b);
  if(!x || !y) return false;
  for(let i = 0; i < 3; i++) if(x[i] !== y[i]) return x[i] > y[i];
  return false;
}
```

`scripts/build-www.mjs` — em `construir`, antes do `return arquivos;`, substituir a gravação do `index.html` por:

```js
  const { versao } = JSON.parse(await readFile(join(raiz, 'versao.json'), 'utf8'));
  await writeFile(join(destino, 'versao-app.js'), `window.APP_VERSAO=${JSON.stringify(versao)};\n`);
  const nativoTag = '<script src="nativo.js"></script>';
  if(!html.includes(nativoTag)) throw new Error('index.html sem ' + nativoTag);
  await writeFile(indice, html
    .replace(marca, `${marca}\n<meta http-equiv="Content-Security-Policy" content="${cspNativa(header.value)}">`)
    .replace(nativoTag, `<script src="versao-app.js"></script>\n${nativoTag}`));
```

`vercel.json` — acrescentar ao array `headers` (depois do bloco `/(.*)`):

```json
    {
      "source": "/versao.json",
      "headers": [
        { "key": "Access-Control-Allow-Origin", "value": "capacitor://localhost" },
        { "key": "Cache-Control", "value": "no-cache" }
      ]
    }
```

`index.html` — em Ajustes, logo acima do bloco do e-mail da conta (localize com `grep -n 'id="ajEmail"' index.html` e insira antes do cartão que o contém):

```html
<div id="ajVersao" class="versao-aviso hidden" role="status">
  <span>Nova versão do Custta disponível.</span>
  <a id="ajVersaoLoja" class="btn primary" href="#">Atualizar</a>
  <button id="ajVersaoFechar" class="btn ghost" type="button">Agora não</button>
</div>
```

`styles.css` — perto de `.notif-invite-actions`:

```css
  .versao-aviso{display:flex;flex-wrap:wrap;align-items:center;gap:10px;padding:14px;margin:0 0 14px;border-radius:14px;background:var(--surface-2)}
  .versao-aviso span{flex:1 1 100%;font-weight:650}
  .versao-aviso .btn{flex:1;text-align:center;text-decoration:none}
```

`app.js` — fim do bloco nativo da Task 10 (dentro do `if(OBRA_NATIVO.ehNativo()){`):

```js
  /* Atualização só pela App Store: avisa quando a produção declara versão maior. */
  const VERSAO_DISPENSADA = 'custta-versao-dispensada';
  fetch('https://app-construcao-civil.vercel.app/versao.json', { cache:'no-store' })
    .then(r => r.ok ? r.json() : null)
    .then(v => {
      if(!v || !v.loja || !/^itms-apps:\/\//.test(v.loja)) return;
      if(!OBRA_CALC.versaoMaior(v.versao, window.APP_VERSAO)) return;
      let dispensada = null; try{ dispensada = localStorage.getItem(VERSAO_DISPENSADA); }catch(e){}
      if(dispensada === v.versao) return;
      $('#ajVersaoLoja').href = v.loja;
      $('#ajVersao').classList.remove('hidden');
      $('#ajVersaoFechar').onclick = ()=>{
        try{ localStorage.setItem(VERSAO_DISPENSADA, v.versao); }catch(e){}
        $('#ajVersao').classList.add('hidden');
      };
    })
    .catch(()=>{}); // offline: sem aviso, sem erro
```

- [ ] **Step 4: Browser test** — em `nativo.cjs`:

```js
    /* ---- Task 12: aviso de versão ---- */
    {
      const antes = async ctx => {
        await ctx.addInitScript(()=>{ window.APP_VERSAO = '1.0.0'; });
        // no aparelho a CSP vem da <meta> do www/, que libera produção; o servidor de teste serve a CSP web
        await ctx.route('http://localhost:8123/', async r => {
          const resp = await r.fetch(); const h = resp.headers();
          h['content-security-policy'] = h['content-security-policy'].replace("connect-src 'self'", "connect-src 'self' https://app-construcao-civil.vercel.app");
          await r.fulfill({ response:resp, headers:h });
        });
        await ctx.route('https://app-construcao-civil.vercel.app/versao.json', r => r.fulfill({ contentType:'application/json',
          headers:{ 'access-control-allow-origin':'*' }, body:JSON.stringify({ versao:'1.1.0', loja:'itms-apps://apps.apple.com/app/id123' }) }));
      };
      const { ctx, page } = await abrir(browser, { nativo:true, antes });
      await page.evaluate(()=>{ showView('ajustes'); renderAjustes(); });
      await page.waitForSelector('#ajVersao:not(.hidden)');
      assert.equal(await page.getAttribute('#ajVersaoLoja', 'href'), 'itms-apps://apps.apple.com/app/id123');
      await page.click('#ajVersaoFechar');
      await page.reload();
      await page.waitForFunction(()=>typeof db !== 'undefined' && db.obras.length === 1);
      await page.waitForTimeout(500);
      assert.equal(await page.locator('#ajVersao').isHidden(), true, 'dispensado não volta');
      await ctx.close();
    }
```

Rotas registradas por último têm prioridade no Playwright: as de `antes` vencem o abort genérico do harness.

- [ ] **Step 5: Run** `npm run test:unit`, `npm run test:browser`, `npm run cap:sync` → verdes; `grep APP_VERSAO www/versao-app.js` mostra `1.0.0`.

- [ ] **Step 6: Commit**

```bash
git add versao.json calc.js tests/calc.test.cjs scripts/build-www.mjs tests/build-www.test.mjs index.html styles.css app.js vercel.json tests/headers.test.cjs tests/browser/nativo.cjs
git commit -m "feat: avisar quando houver versao nova do app na loja"
```

---

### Task 13: SDKs congelados e política de privacidade

**Files:**
- Create: `docs/sdks-fase4.md`
- Modify: `privacidade.html`
- Create: `tests/privacidade.test.cjs`, Modify: `package.json`

**Interfaces:** nenhuma de código.

- [ ] **Step 1: Failing test** — `tests/privacidade.test.cjs`

```js
'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const ler = p => readFileSync(join(__dirname, '..', p), 'utf8');

test('política cita token de dispositivo do FCM e lista de SDKs bate com package.json', ()=>{
  const politica = ler('privacidade.html');
  assert.match(politica, /Firebase Cloud Messaging/);
  assert.match(politica, /token/i);
  const sdks = ler('docs/sdks-fase4.md');
  const pkg = JSON.parse(ler('package.json'));
  for(const nome of Object.keys(pkg.devDependencies).filter(n => n.startsWith('@capacitor')))
    assert.ok(sdks.includes(nome), 'SDK sem registro: ' + nome);
  assert.match(sdks, /@sentry\/browser/);
  assert.match(sdks, /firebase 12\.18\.0/);
});
```

Acrescente ao `test:unit`. Run → FAIL.

- [ ] **Step 2: `docs/sdks-fase4.md`** — gere a tabela a partir das versões instaladas (`npm ls --depth=0 | grep -E "capacitor|firebase|sentry"`) e escreva:

```markdown
# SDKs congelados — Fase 4

Data: 2026-09-16. Base da política de privacidade e dos App Privacy labels da Fase 5.
Mudou algo aqui? Revisar `privacidade.html` e os labels **antes** de publicar.

| SDK | Versão | Onde roda | Dados que coleta ou transmite | Finalidade |
| --- | --- | --- | --- | --- |
| firebase 12.18.0 (Auth) | 12.18.0 | web + iOS (JS) | e-mail, uid, token de sessão | conta |
| firebase 12.18.0 (Firestore) | 12.18.0 | web + iOS (JS) | obras, gastos, afazeres, fuso horário | funcionalidade |
| @sentry/browser | 10.74.0 | web + iOS (JS) | diagnóstico sanitizado (sem mensagem livre, conta ou dado de obra) | diagnóstico |
| @capacitor-firebase/messaging | <versão> | iOS (nativo) | token de dispositivo FCM/APNs | notificações |
| @capacitor/core, @capacitor/cli, @capacitor/ios | <versão> | iOS | nenhum dado próprio | ponte nativa |
| @capacitor/app | <versão> | iOS | nenhum | estado do app |
| @capacitor/share, @capacitor/filesystem | <versão> | iOS | arquivo exportado, só no aparelho | exportação |
| @capacitor/haptics, @capacitor/status-bar, @capacitor/splash-screen | <versão> | iOS | nenhum | interface |
| web-push, firebase-admin | <versão> | servidor (cron) | lê push/{uid}, dados/{uid}, perfis/{uid}.tz | resumo diário |
```

Substitua cada `<versão>` pela versão real da saída do `npm ls` (não deixe `<versão>` no arquivo).

- [ ] **Step 3: `privacidade.html`** — na seção que descreve notificações (localize com `grep -n -i "notifica" privacidade.html`), acrescentar um parágrafo no mesmo formato de marcação das vizinhas:

```html
<p>No aplicativo para iPhone, as notificações usam o Firebase Cloud Messaging (Google) e a Apple Push Notification service. Para isso guardamos um token de dispositivo, que identifica o aparelho apenas para entregar o resumo diário. O token é apagado quando você desliga as notificações, sai da conta ou apaga a conta.</p>
```

Atualize a data de "última atualização" da página, se existir, para 16 de setembro de 2026.

- [ ] **Step 4: Run** `npm run test:unit` → verde.

- [ ] **Step 5: Commit**

```bash
git add docs/sdks-fase4.md privacidade.html tests/privacidade.test.cjs package.json
git commit -m "docs: congelar sdks da fase 4 e citar token de notificacao na politica"
```

---

### Task 14: Validação final, checklist de aparelho e documentação

**Files:**
- Create: `docs/plans/2026-09-16-fase4-checklist-aparelho.md`
- Modify: `CLAUDE.md`, `README.md`, `docs/planejamento-app-store.md` (status da Fase 4)

- [ ] **Step 1: Suítes completas**

Run: `npm run test:unit && npm run test:rules && npm run test:browser && npm run cap:sync`
Expected: tudo verde. Qualquer falha: corrigir na tarefa de origem com commit `fix: ...` próprio.

- [ ] **Step 2: Validação com agent-browser (web e nativo simulado)**

```bash
node tests/browser/servidor.cjs & SERV=$!
agent-browser open http://localhost:8123 && agent-browser set viewport 390 844
agent-browser eval "document.querySelector('meta[name=viewport]').content"
agent-browser screenshot /tmp/custta-web-390.png
agent-browser set viewport 1280 800 && agent-browser screenshot /tmp/custta-web-1280.png
agent-browser console
agent-browser close
kill $SERV
```

Critérios: viewport sem `user-scalable`; tela de login renderiza nos dois tamanhos; `console` sem `securitypolicyviolation` nem erro. Para o modo nativo simulado e fluxos logados, a cobertura automatizada é `tests/browser/nativo.cjs` (o agent-browser não injeta `window.Capacitor` antes do carregamento); registre isso no checklist. Rode `agent-browser --help` se algum subcomando divergir e ajuste o nome (ex.: `set viewport` vs `viewport`).

Abra as screenshots com a ferramenta Read e confira visualmente.

- [ ] **Step 3: Checklist de aparelho** — `docs/plans/2026-09-16-fase4-checklist-aparelho.md`:

```markdown
# Fase 4 — o que só valida com Apple, Xcode e iPhone

Código pronto em `feat/fase4`. Itens abaixo dependem de matrícula Apple, Xcode ou aparelho.

## Antes do primeiro build
- [ ] Matricular no Apple Developer Program; trocar `com.gstuchi.custta` pelo bundle ID reservado em `capacitor.config.json` e rodar `npm run cap:sync`.
- [ ] Firebase → adicionar app iOS com o bundle ID → baixar `GoogleService-Info.plist` → arrastar para `ios/App/App/` no Xcode (target App). Sem ele o app fecha ao abrir.
- [ ] Gerar chave APNs `.p8` e subir em Firebase → Cloud Messaging → Apple app configuration.
- [ ] Xcode → Signing & Capabilities: Team, "Push Notifications" e "Background Modes › Remote notifications".
- [ ] Preencher `versao.json` → `loja` com `itms-apps://apps.apple.com/app/id<ID>` depois de criar o app no App Store Connect.

## No iPhone (TestFlight)
- [ ] Instalar, logar, matar o app, reabrir: continua logado e na mesma tela/obra.
- [ ] Modo avião na primeira abertura após instalar: app abre e lista obras do cache.
- [ ] Lançar gasto: vibra ao confirmar; teclado numérico e folhas não ficam atrás do teclado do iOS (gambiarra `visualViewport`).
- [ ] Pinch-zoom funciona.
- [ ] Excluir gasto, apagar obra, remover tópico, sair: diálogo aparece (nada some calado).
- [ ] Relatório → "Compartilhar planilha" abre o share sheet.
- [ ] Tema claro/escuro troca a cor do texto da barra de status.
- [ ] Ativar notificações → token aparece em `push/{uid}.tokens` no console.
- [ ] GitHub Actions → push-diario → Run workflow: notificação chega com o app fechado e abre a obra certa quando o resumo é de uma obra só.
- [ ] Apagar conta pelo app: `dados`, `perfis`, `push` somem no console.
- [ ] Deixar uma semana sem abrir e reabrir: sessão persiste (se não, plano B: `@capacitor-firebase/authentication`).

## Validado nesta máquina (2026-09-16)
- Testes unitários, rules (emulador) e browser (Playwright, incluindo `tests/browser/nativo.cjs` com Capacitor simulado).
- agent-browser: web em 390×844 e 1280×800, sem violação de CSP.
- `npm run cap:sync` concluído (sem Xcode instalado: nenhum build nativo).
```

- [ ] **Step 4: Docs do projeto**

`CLAUDE.md`, seção Comandos, acrescentar:

```markdown
npm run build:www        # copia o app para www/ com CSP em <meta> (webDir do Capacitor)
npm run cap:sync         # build:www + cap sync ios
```

Tabela de Arquitetura, acrescentar linhas:

```markdown
| [nativo.js](nativo.js) | `OBRA_NATIVO` + `module.exports` | único ponto que toca `window.Capacitor`; no browser tudo é neutro |
| [push.js](push.js) | `OBRA_PUSH` + `module.exports` | notificações: Web Push na web, FCM no app iOS |
```

Nova subseção depois de "Notificações push":

```markdown
### App iOS (Capacitor)

`ios/` é versionado; `www/` é gerado. Condicione comportamento nativo só via `OBRA_NATIVO.ehNativo()`. `confirm()`/`alert()` são proibidos (somem no WKWebView) — use `OBRA_CONFIRM`. Arquivo novo na raiz entra em `sw.js` `ASSETS`, que também alimenta `build-www`. Pendências de aparelho: `docs/plans/2026-09-16-fase4-checklist-aparelho.md`.
```

`README.md`: parágrafo curto "Fase 4" com o mesmo resumo e link para o checklist.

`docs/planejamento-app-store.md`, logo abaixo de `## Fase 4 — Empacotamento com Capacitor`:

```markdown
**Código concluído em 2026-09-16** na branch `feat/fase4` (spec e plano em `docs/`). Build, TestFlight e push real dependem da matrícula Apple — ver [checklist de aparelho](superpowers/plans/2026-09-16-fase4-checklist-aparelho.md).
```

- [ ] **Step 5: Run** `npm run test:unit` → verde.

- [ ] **Step 6: Commit**

```bash
git add docs/plans/2026-09-16-fase4-checklist-aparelho.md CLAUDE.md README.md docs/planejamento-app-store.md
git commit -m "docs: registrar validacao da fase 4 e checklist de aparelho"
```

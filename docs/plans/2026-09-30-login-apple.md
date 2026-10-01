# Login com Apple — plano de implementação

> **Para agentes:** SUB-SKILL OBRIGATÓRIA: use superpowers:subagent-driven-development (recomendado) ou superpowers:executing-plans para executar tarefa por tarefa. Os passos usam checkbox (`- [ ]`).

**Objetivo:** botão "Continuar com a Apple" no app iOS, no site e no PWA, com "Falta pouco" sem pedir nome e revogação do token ao apagar a conta.

**Arquitetura:** o SDK JavaScript do Firebase continua dono da sessão. Na web, `OAuthProvider('apple.com')` por popup/redirect (mesmo caminho do Google). No app, o plugin `@capawesome/capacitor-apple-sign-in` (via `OBRA_NATIVO.entrarApple`) devolve `idToken` + `authorizationCode`, e `cloud.js` entra com `signInWithCredential`. Apagar conta só Apple reautentica pela Apple e revoga (SDK na web, REST `accounts:revokeToken` com `tokenType: CODE` no app).

**Stack:** JS vanilla sem build (scripts globais + `cloud.js` módulo), Firebase JS 12.18.0 vendorizado, Capacitor 8 (SPM), Playwright + emuladores do Firebase, `node --test`.

**Spec:** `docs/specs/2026-09-30-login-apple-design.md` (ler antes de começar qualquer tarefa).

## Restrições globais

- Código, comentários, identificadores e textos de UI em **português**, no estilo do arquivo em volta (comentário `/* */` curto explicando o porquê).
- CSP estrita: nada de `<style>`, `style="..."`, `onclick=` no HTML. SVG inline com atributo `fill` é permitido.
- Não hardcode cor fora de custom properties no `styles.css` (quatro combos tema×skin).
- `confirm()`/`alert()` proibidos.
- Não mexer em `firestore.rules` (o formato do estado não muda).
- **Não commitar.** O controlador faz os commits (autor único Giovani Stuchi, sem `Co-Authored-By`). Ao terminar, liste os arquivos que mudou.
- Tarefas paralelas dividem o mesmo diretório: **só edite os arquivos da sua tarefa** e rode **só os testes da sua tarefa** (`node --test tests/<arquivo>`), não `npm run test:unit` inteiro.
- Não escrever senha, chave ou credencial em lugar nenhum (o repositório é público). A `apiKey` do Firebase em `cloud.js` é pública por design.
- Os comandos `node`, `npm`, `npx` estão em `~/.local/opt/node/bin` (já no PATH do shell).
- Textos exatos da UI:
  - botão: `Continuar com a Apple`; carregando: `Abrindo a Apple…`
  - "Falta pouco" de conta Apple: `Só falta contar como você conheceu o Custta.`
  - diálogo de apagar conta Apple: `Para confirmar, você vai entrar com a Apple de novo.` e `Confirme sua conta Apple na janela que abriu.`
- Interfaces combinadas entre tarefas:
  - `OBRA_NATIVO.entrarApple({ rawNonce }) → Promise<{ idToken, authorizationCode, user, email, givenName, familyName, realUserStatus } | null>`; `null` fora do app; desistência rejeita com `{ code: 'auth/user-cancelled' }`.
  - `OBRA_CADASTRO.mensagemErroSocial(code, provedor)` com `provedor` = `'apple.com'` | `'google.com'`; `OBRA_CADASTRO.normalizaPerfil(dados, { nomeOpcional: true })`.
  - `CLOUD.entrarApple(): Promise<void>`; `CLOUD.perfilPendente()` vale para `google.com` e `apple.com`.
  - Evento `cloud-social-erro` com `detail: { code, provedor }` (substitui `cloud-google-erro`).

## Foco de revisão

Casos que a spec implica e que mais podem morder quem usa o app; cada um tem teste na tarefa dona:

1. **Apple não manda nome** (segundo login depois de apagar a conta, ou pessoa apagou o nome na tela da Apple) → o "Falta pouco" continua só com "como conheceu" e grava o perfil sem `nome` (Tarefa 1, Tarefa 6).
2. **Pessoa fecha a tela da Apple** → nenhum erro na tela, botões voltam a funcionar, continua travado no login (Tarefa 2, Tarefa 6).
3. **Revogação na Apple falha** (rede, 4xx/5xx, emulador) → a conta é apagada mesmo assim e a falha fica no diagnóstico (Tarefa 4, Tarefa 6).
4. **Conta com senha e Apple, ou Google e Apple** → com senha, confirma pela senha e não abre a Apple; sem senha, Apple tem prioridade sobre Google (Tarefa 4).
5. **WKWebView sem `crypto.subtle`** → o SHA-256 do nonce cai na implementação pura e bate com o `crypto` do Node (Tarefa 2).

## Ondas de execução

- **Onda 1 (paralelo):** Tarefas 1, 2, 3 e 7, com arquivos disjuntos.
- **Onda 2 (paralelo):** Tarefas 4 e 5, com arquivos disjuntos. Dependem de 1 e 2 commitadas.
- **Onda 3:** Tarefa 6 (suítes de navegador), que depende de tudo.
- **Fechamento (controlador):** suíte completa, agent-browser na prévia da Vercel, PR, CI, TestFlight.

---

### Tarefa 1: mensagens de erro por provedor e nome opcional no perfil

**Arquivos:**
- Modificar: `cadastro.js` (bloco `normalizaPerfil`, `nomeDoGoogle`, `ERROS_GOOGLE`/`mensagemErroGoogle`, `api`)
- Teste: `tests/cadastro.test.cjs`

**Interfaces:**
- Produz: `mensagemErroSocial(code, provedor) → string` ('' = desistência); `mensagemErroGoogle(code)` continua existindo (atalho para `'google.com'`); `normalizaPerfil(d, opcoes)` com `opcoes.nomeOpcional`.

- [ ] **Passo 1: escrever os testes que falham.** Em `tests/cadastro.test.cjs`, trocar a linha do `account-exists` do teste `mensagemErroGoogle: desistência é silenciosa...` por:

```js
  assert.equal(C.mensagemErroGoogle('auth/account-exists-with-different-credential'),'Este e-mail já tem conta no Custta. Entre do jeito que você usou da primeira vez.');
```

e acrescentar no fim do arquivo:

```js
test('mensagemErroSocial: Apple com artigo, Google como antes',()=>{
  const A=c=>C.mensagemErroSocial(c,'apple.com');
  for(const c of ['auth/popup-closed-by-user','auth/cancelled-popup-request','auth/user-cancelled']) assert.equal(A(c),'');
  assert.equal(A('auth/unauthorized-domain'),'Login com a Apple indisponível neste endereço. Use custta.com.br.');
  assert.equal(A('auth/operation-not-allowed'),'Login com a Apple ainda não está disponível. Use e-mail e senha.');
  assert.equal(A('auth/operation-not-supported-in-this-environment'),'Seu navegador bloqueou o login com a Apple. Use e-mail e senha.');
  assert.equal(A('auth/web-storage-unsupported'),'Seu navegador bloqueou o login com a Apple. Use e-mail e senha.');
  assert.equal(A('auth/account-exists-with-different-credential'),'Este e-mail já tem conta no Custta. Entre do jeito que você usou da primeira vez.');
  assert.equal(A('auth/network-request-failed'),'Sem internet. Conecte pra entrar.');
  assert.equal(A('auth/too-many-requests'),'Muitas tentativas. Espere um pouco.');
  assert.equal(A('auth/qualquer'),'Não deu certo entrar com a Apple. Tente de novo.');
  assert.equal(A('toString'),'Não deu certo entrar com a Apple. Tente de novo.');
  assert.equal(A(undefined),'Não deu certo entrar com a Apple. Tente de novo.');
  assert.equal(C.mensagemErroSocial('auth/qualquer','toString'),'Não deu certo entrar com o Google. Tente de novo.','provedor desconhecido cai no Google');
  assert.equal(C.mensagemErroSocial('auth/operation-not-allowed','google.com'),'Login com Google ainda não está disponível. Use e-mail e senha.');
  for(const c of ['auth/unauthorized-domain','auth/web-storage-unsupported','auth/qualquer'])
    assert.equal(C.mensagemErroSocial(c,'google.com'),C.mensagemErroGoogle(c));
});
test('normalizaPerfil com nomeOpcional: nome da Apple entra; ausente ou inválido fica de fora',()=>{
  const opc={nomeOpcional:true};
  assert.deepEqual(C.normalizaPerfil({nome:'Bia',sobrenome:'Lima',origem:'instagram'},opc).perfil,{nome:'Bia',sobrenome:'Lima',origem:'instagram'});
  assert.deepEqual(C.normalizaPerfil({nome:'',sobrenome:'',origem:'instagram'},opc).perfil,{origem:'instagram'});
  assert.deepEqual(C.normalizaPerfil({origem:'google'},opc).perfil,{origem:'google'});
  assert.deepEqual(C.normalizaPerfil({nome:'J',origem:'google'},opc).perfil,{origem:'google'},'nome de 1 letra não trava quem não vê o campo');
  const semOrigem=C.normalizaPerfil({nome:''},opc);
  assert.equal(semOrigem.ok,false); assert.equal(semOrigem.campo,'origem');
  assert.equal(C.normalizaPerfil({nome:'',origem:'instagram'}).campo,'nome','sem a opção o nome continua obrigatório');
});
```

- [ ] **Passo 2: rodar e ver falhar.** `node --test tests/cadastro.test.cjs` → FAIL (`mensagemErroSocial is not a function` e texto do account-exists).

- [ ] **Passo 3: implementar em `cadastro.js`.** Substituir o bloco de `SEM_GOOGLE` até o fim de `mensagemErroGoogle` por:

```js
  /* Como cada provedor aparece nas frases: "Login com a Apple", "entrar com o Google". */
  const PROVEDORES = Object.freeze({
    'google.com': Object.freeze({ curto:'com Google', longo:'com o Google' }),
    'apple.com':  Object.freeze({ curto:'com a Apple', longo:'com a Apple' }),
  });
  /* '' = a pessoa desistiu (fechou o popup ou a tela da Apple): não é erro pra mostrar. */
  const DESISTIU = new Set(['auth/popup-closed-by-user','auth/cancelled-popup-request','auth/user-cancelled']);
  function mensagemErroSocial(code, provedor){
    const p = Object.hasOwn(PROVEDORES, provedor) ? PROVEDORES[provedor] : PROVEDORES['google.com'];
    if(DESISTIU.has(code)) return '';
    switch(code){
      case 'auth/account-exists-with-different-credential': return 'Este e-mail já tem conta no Custta. Entre do jeito que você usou da primeira vez.';
      case 'auth/unauthorized-domain': return `Login ${p.curto} indisponível neste endereço. Use custta.com.br.`;
      case 'auth/operation-not-allowed': return `Login ${p.curto} ainda não está disponível. Use e-mail e senha.`;
      case 'auth/operation-not-supported-in-this-environment':
      case 'auth/web-storage-unsupported': return `Seu navegador bloqueou o login ${p.curto}. Use e-mail e senha.`;
      case 'auth/network-request-failed': return 'Sem internet. Conecte pra entrar.';
      case 'auth/too-many-requests': return 'Muitas tentativas. Espere um pouco.';
      default: return `Não deu certo entrar ${p.longo}. Tente de novo.`;
    }
  }
  const mensagemErroGoogle = code => mensagemErroSocial(code, 'google.com');
```

Em `normalizaPerfil`, trocar a assinatura e as duas primeiras linhas do corpo:

```js
  /* nomeOpcional: conta Apple. O nome vem da Apple e a tela não o pede de novo (a
     revisão da Apple reprova); nome ausente ou fora das regras fica de fora do perfil. */
  function normalizaPerfil(d, opcoes){
    const o = d && typeof d === 'object' ? d : {};
    let base = normalizaNome(o);
    if(!base.ok && opcoes && opcoes.nomeOpcional) base = {ok:true, perfil:{}};
    if(!base.ok) return base;
```

Atualizar o comentário de `nomeDoGoogle` para "Nome de exibição (Google ou Apple) → nome + sobrenome" e a `api`:

```js
  const api = {REGRAS_SENHA, validaSenha, ORIGENS, LIMITES_PERFIL, normalizaPerfil, normalizaNome, nomeDoGoogle, mensagemErroSocial, mensagemErroGoogle};
```

- [ ] **Passo 4: rodar e ver passar.** `node --test tests/cadastro.test.cjs` → todos PASS.

- [ ] **Passo 5: entregar.** Arquivos: `cadastro.js`, `tests/cadastro.test.cjs`. Commit sugerido: `feat: mensagens de login por provedor e perfil sem nome para conta Apple`.

---

### Tarefa 2: `OBRA_NATIVO.entrarApple` com SHA-256 do nonce

**Arquivos:**
- Modificar: `nativo.js`
- Teste: `tests/nativo.test.cjs`

**Interfaces:**
- Produz: `OBRA_NATIVO.entrarApple({ rawNonce })` (ver Restrições globais); `module.exports = { criar, sha256Puro }`.

- [ ] **Passo 1: escrever os testes que falham.** Em `tests/nativo.test.cjs`, trocar o require do topo por:

```js
const { criar, sha256Puro } = require('../nativo.js');
const { createHash, webcrypto } = require('node:crypto');
```

e acrescentar no fim:

```js
test('sha256Puro bate com o crypto do Node (vários blocos e UTF-8)', ()=>{
  const entradas = ['', 'abc', 'a'.repeat(55), 'a'.repeat(56), 'a'.repeat(64), 'a'.repeat(200), 'ção 🍎', '0f'.repeat(32)];
  for(const e of entradas) assert.equal(sha256Puro(e), createHash('sha256').update(e, 'utf8').digest('hex'), JSON.stringify(e));
});

test('entrarApple: fora do app devolve null', async()=>{
  assert.equal(await criar({}).entrarApple({ rawNonce:'x' }), null);
});

test('entrarApple: pede e-mail e nome e manda o SHA-256 do nonce, com e sem crypto.subtle', async()=>{
  const pedidos = [];
  const resposta = { idToken:'id', authorizationCode:'cod', givenName:'Bia', familyName:'Lima' };
  for(const cripto of [undefined, webcrypto]){
    const { win } = janelaNativa({ AppleSignIn:{ signIn:async a=>{ pedidos.push(a); return resposta; } } });
    if(cripto) win.crypto = cripto;
    assert.deepEqual(await criar(win).entrarApple({ rawNonce:'abc' }), resposta);
  }
  const esperado = createHash('sha256').update('abc').digest('hex');
  assert.deepEqual(pedidos, [
    { scopes:['EMAIL','FULL_NAME'], nonce:esperado },
    { scopes:['EMAIL','FULL_NAME'], nonce:esperado },
  ]);
});

test('entrarApple: desistência vira auth/user-cancelled sem registrar erro', async()=>{
  for(const code of ['SIGN_IN_CANCELED', '1001', 1001]){
    const { win, erros } = janelaNativa({ AppleSignIn:{ signIn:async()=>{ throw Object.assign(new Error('Sign in was canceled.'), { code }); } } });
    await assert.rejects(criar(win).entrarApple({ rawNonce:'n' }), { code:'auth/user-cancelled' });
    assert.deepEqual(erros, []);
  }
});

test('entrarApple: outra falha sobe e fica no diagnóstico', async()=>{
  const { win, erros } = janelaNativa({ AppleSignIn:{ signIn:async()=>{ throw Object.assign(new Error('falhou'), { code:'1000' }); } } });
  await assert.rejects(criar(win).entrarApple({ rawNonce:'n' }), { message:'falhou' });
  assert.equal(erros.length, 1);
  assert.equal(erros[0][0], 'nativo-apple');
});
```

- [ ] **Passo 2: rodar e ver falhar.** `node --test tests/nativo.test.cjs` → FAIL (`sha256Puro is not a function`).

- [ ] **Passo 3: implementar em `nativo.js`.** Antes de `function criar(win){`, dentro do IIFE:

```js
  /* SHA-256 em hex, sem depender de crypto.subtle (só existe em contexto seguro;
     o WKWebView do Capacitor deveria ser, mas o login não pode depender disso). */
  const K = [0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2];
  const hex = bytes => Array.from(bytes, b => b.toString(16).padStart(2, '0')).join('');
  function sha256Puro(texto){
    const bytes = Array.from(new TextEncoder().encode(String(texto)));
    const bits = bytes.length * 8;
    bytes.push(0x80);
    while(bytes.length % 64 !== 56) bytes.push(0);
    bytes.push(0, 0, 0, 0, (bits >>> 24) & 255, (bits >>> 16) & 255, (bits >>> 8) & 255, bits & 255);
    const H = [0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19];
    const w = new Array(64);
    const rotr = (x, n) => (x >>> n) | (x << (32 - n));
    for(let i = 0; i < bytes.length; i += 64){
      for(let t = 0; t < 16; t++) w[t] = (bytes[i+4*t] << 24) | (bytes[i+4*t+1] << 16) | (bytes[i+4*t+2] << 8) | bytes[i+4*t+3];
      for(let t = 16; t < 64; t++){
        const s0 = rotr(w[t-15], 7) ^ rotr(w[t-15], 18) ^ (w[t-15] >>> 3);
        const s1 = rotr(w[t-2], 17) ^ rotr(w[t-2], 19) ^ (w[t-2] >>> 10);
        w[t] = (w[t-16] + s0 + w[t-7] + s1) | 0;
      }
      let [a, b, c, d, e, f, g, h] = H;
      for(let t = 0; t < 64; t++){
        const t1 = (h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + K[t] + w[t]) | 0;
        const t2 = ((rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c))) | 0;
        h = g; g = f; f = e; e = (d + t1) | 0; d = c; c = b; b = a; a = (t1 + t2) | 0;
      }
      H[0] = (H[0] + a) | 0; H[1] = (H[1] + b) | 0; H[2] = (H[2] + c) | 0; H[3] = (H[3] + d) | 0;
      H[4] = (H[4] + e) | 0; H[5] = (H[5] + f) | 0; H[6] = (H[6] + g) | 0; H[7] = (H[7] + h) | 0;
    }
    return H.map(x => (x >>> 0).toString(16).padStart(8, '0')).join('');
  }
```

Dentro de `criar(win)`, depois de `compartilharArquivo`:

```js
    async function sha256Hex(texto){
      const subtle = win && win.crypto && win.crypto.subtle;
      if(subtle){
        try{ return hex(new Uint8Array(await subtle.digest('SHA-256', new TextEncoder().encode(String(texto))))); }
        catch(e){ /* cai na implementação pura */ }
      }
      return sha256Puro(texto);
    }
    /* Sign in with Apple nativo. A Apple assina o SHA-256 do nonce; o Firebase
       confere com o nonce cru, que fica com quem chamou. Diferente de `chama`,
       propaga o erro: quem entra precisa separar desistência de falha. */
    async function entrarApple({ rawNonce } = {}){
      const p = plugin('AppleSignIn');
      if(!p) return null;
      try{ return await p.signIn({ scopes:['EMAIL', 'FULL_NAME'], nonce: await sha256Hex(rawNonce) }); }
      catch(err){
        const code = err && err.code;
        if(code === 'SIGN_IN_CANCELED' || String(code) === '1001')
          throw Object.assign(new Error('Login com a Apple cancelado.'), { code:'auth/user-cancelled' });
        registra('apple', err);
        throw err;
      }
    }
```

No `return {` de `criar`, acrescentar `entrarApple,` na primeira linha (`ehNativo, plugin, compartilharArquivo, aoSegundoPlano, marcarAmbiente, entrarApple,`). No fim do arquivo: `if(typeof module !== 'undefined') module.exports = { criar, sha256Puro };`.

- [ ] **Passo 4: rodar e ver passar.** `node --test tests/nativo.test.cjs` → todos PASS.

- [ ] **Passo 5: entregar.** Arquivos: `nativo.js`, `tests/nativo.test.cjs`. Commit sugerido: `feat: ponte nativa do Sign in with Apple com nonce em SHA-256`.

---

### Tarefa 3: plugin nativo e entitlement do Sign in with Apple

**Arquivos:**
- Modificar: `package.json`, `package-lock.json` (via npm), `ios/App/CapApp-SPM/Package.swift` (via `cap sync`), `ios/App/App/App.entitlements`
- Teste: `tests/capacitor.test.cjs`

**Interfaces:**
- Produz: plugin JS `AppleSignIn` disponível em `window.Capacitor.Plugins` no app (consumido pela Tarefa 2 por nome).

- [ ] **Passo 1: escrever o teste que falha.** Acrescentar em `tests/capacitor.test.cjs`:

```js
test('Sign in with Apple: entitlement e plugin nativo no pacote SPM', ()=>{
  const ent = ler('ios/App/App/App.entitlements');
  assert.match(ent, /<key>com\.apple\.developer\.applesignin<\/key>\s*<array>\s*<string>Default<\/string>\s*<\/array>/);
  assert.match(ent, /<key>aps-environment<\/key>/, 'push continua');
  const pkg = JSON.parse(ler('package.json'));
  assert.ok(pkg.devDependencies['@capawesome/capacitor-apple-sign-in'], 'plugin no package.json');
  const spm = ler('ios/App/CapApp-SPM/Package.swift');
  assert.match(spm, /\.package\(name: "CapawesomeCapacitorAppleSignIn", path: "\.\.\/\.\.\/\.\.\/node_modules\/@capawesome\/capacitor-apple-sign-in"\)/);
  assert.match(spm, /\.product\(name: "CapawesomeCapacitorAppleSignIn", package: "CapawesomeCapacitorAppleSignIn"\)/);
});
```

- [ ] **Passo 2: rodar e ver falhar.** `node --test tests/capacitor.test.cjs` → FAIL no teste novo.

- [ ] **Passo 3: instalar e sincronizar.**

```bash
npm install --save-dev @capawesome/capacitor-apple-sign-in@0.1.4
npm run cap:sync
git status --short
```

Esperado no `git status`: só `package.json`, `package-lock.json` e `ios/App/CapApp-SPM/Package.swift` (a pasta `www/` e `ios/App/App/public` são ignoradas). O `cap sync` roda sem Xcode (esta máquina só tem Command Line Tools); aviso sobre `xcodebuild` é esperado, erro não. A CI confere que o `cap sync` não muda nada versionado, então o `Package.swift` **tem** de vir do `cap sync`, não de edição à mão.

- [ ] **Passo 4: entitlement.** Em `ios/App/App/App.entitlements`, dentro do `<dict>`, depois do `aps-environment`:

```xml
	<key>com.apple.developer.applesignin</key>
	<array>
		<string>Default</string>
	</array>
```

- [ ] **Passo 5: rodar e ver passar.** `node --test tests/capacitor.test.cjs` → todos PASS.

- [ ] **Passo 6: entregar.** Arquivos: `package.json`, `package-lock.json`, `ios/App/CapApp-SPM/Package.swift`, `ios/App/App/App.entitlements`, `tests/capacitor.test.cjs`. Commit sugerido: `feat: plugin nativo e entitlement do Sign in with Apple`. Observação para o controlador: o perfil "Custta App Store" já foi refeito com a capability (id `ZF2VYUKKK4`) e o secret `PERFIL_APP_STORE` atualizado em 30/09, então o build do TestFlight deste PR deve assinar.

---

### Tarefa 4: `cloud.js` — entrar, reautenticar e revogar com Apple

**Arquivos:**
- Modificar: `cloud.js`, `tests/helpers/firebase-stub.mjs`, `tests/google-cloud.test.mjs` (evento renomeado), `package.json` (só a lista `test:unit`)
- Criar: `tests/apple-cloud.test.mjs`

**Interfaces:**
- Consome: `window.OBRA_NATIVO.entrarApple({ rawNonce })` (Tarefa 2), `window.OBRA_DIAG.registra(origem, mensagem, stack)`.
- Produz: `CLOUD.entrarApple()`, `perfilPendente` com Apple, evento `cloud-social-erro` `{ code, provedor }`, `apagarConta` revogando Apple.

**Atenção:** as suítes de navegador reescrevem `cloud.js` com `.replace` nos trechos `'sendPasswordResetEmail, signOut,'`, `'deleteField, waitForPendingWrites,'`, `'const auth = getAuth(app);'` e `'const CHAVE_LIMPEZA'`. Esses trechos precisam continuar existindo exatamente assim.

- [ ] **Passo 1: estender o duplê do Firebase** (`tests/helpers/firebase-stub.mjs`). No `__ctrl`, acrescentar:

```js
  credenciais: [],        // credenciais passadas a signInWithCredential/reauthenticateWithCredential
  revogados: [],          // tokens passados a revokeAccessToken
  perfisAtualizados: [],  // argumentos de updateProfile
  popups: [],             // provedores passados a signInWithPopup/reauthenticateWithPopup
  resultadoLogin: null,   // o que signInWithCredential devolve
  resultadoPopup: null,   // o que signInWithPopup/reauthenticateWithPopup devolvem
```

Trocar as funções existentes e acrescentar as novas:

```js
export function reauthenticateWithCredential(_u, cred){
  __ctrl.credenciais.push(cred);
  return passo(cred && cred.providerId === 'apple.com' ? 'reauthApple' : 'reauth');
}
export class GoogleAuthProvider{ constructor(){ this.providerId = 'google.com'; } setCustomParameters(p){ this.parametros = p; } }
export class OAuthProvider{
  constructor(providerId){ this.providerId = providerId; this.escopos = []; }
  addScope(s){ this.escopos.push(s); return this; }
  setCustomParameters(p){ this.parametros = p; return this; }
  credential({ idToken, rawNonce }){ return { providerId:this.providerId, idToken, rawNonce }; }
  static credentialFromResult(r){ return (r && r.credencial) || null; }
}
export function signInWithPopup(_a, provedor){ __ctrl.popups.push(provedor); return passo('popup').then(()=>__ctrl.resultadoPopup); }
export function reauthenticateWithPopup(_u, provedor){ __ctrl.popups.push(provedor); return passo('reauthPopup').then(()=>__ctrl.resultadoPopup); }
export function signInWithCredential(_a, cred){ __ctrl.credenciais.push(cred); return passo('credencial').then(()=>__ctrl.resultadoLogin); }
export function revokeAccessToken(_a, token){ __ctrl.revogados.push(token); return passo('revogar'); }
export function updateProfile(_u, dados){ __ctrl.perfisAtualizados.push(dados); return passo('updateProfile'); }
```

- [ ] **Passo 2: escrever os testes que falham.** Criar `tests/apple-cloud.test.mjs`:

```js
import { test, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { register, createRequire } from 'node:module';
register('./helpers/loader-firebase.mjs', import.meta.url);
const require=createRequire(import.meta.url);
const { __ctrl:ctrl }=await import('./helpers/firebase-stub.mjs');
let cloud, eventos, diag, pedidos, nativo, chamadasFetch;
const tique=()=>new Promise(r=>setTimeout(r,0));
async function carregar(){ await import('../cloud.js?apple='+Math.random()); cloud=window.CLOUD; await cloud.ready; }
async function entraComo(providerIds){
  await ctrl.authCb({ uid:'u-teste', email:'bia@privaterelay.appleid.com', emailVerified:true, displayName:null,
    providerData:providerIds.map(providerId=>({providerId})) });
  await tique();
}
/* OBRA_NATIVO falso: ehNativo liga o caminho do app iOS no cloud.js (lido na importação). */
async function preparar({ ehNativo=false }={}){
  const event=new EventTarget(); eventos=[]; diag=[]; pedidos=[]; chamadasFetch=[];
  nativo={ ehNativo:()=>ehNativo, falha:null,
    resposta:{ idToken:'id-apple', authorizationCode:'codigo-apple', givenName:'Bia', familyName:'Lima' },
    entrarApple:async a=>{ pedidos.push(a); if(nativo.falha) throw nativo.falha; return nativo.resposta; } };
  globalThis.window={ addEventListener:event.addEventListener.bind(event),
    dispatchEvent:e=>{ eventos.push(e); return event.dispatchEvent(e); },
    OBRA_CALC:require('../calc.js'), OBRA_CADASTRO:require('../cadastro.js'), OBRA_NATIVO:nativo,
    OBRA_DIAG:{ registra:(...a)=>diag.push(a) },
    location:{ reload:()=>ctrl.passos.push('reload') } };
  globalThis.CustomEvent=globalThis.CustomEvent || Event;
  Object.defineProperty(globalThis,'navigator',{value:{onLine:true},configurable:true});
  globalThis.fetch=async(url,init)=>{ chamadasFetch.push({url,init}); return { ok:true, status:200 }; };
  Object.assign(ctrl,{ passos:[], falhas:{}, respostas:[], pendentesSDK:Promise.resolve(), perfil:null, perfilCache:null,
    setDocChamadas:[], credenciais:[], revogados:[], perfisAtualizados:[], popups:[], resultadoLogin:null, resultadoPopup:null });
  await carregar();
}
function sessaoFalsa(inicial={}){
  const m=new Map(Object.entries(inicial));
  globalThis.sessionStorage={ getItem:k=>m.has(k)?m.get(k):null, setItem:(k,v)=>m.set(k,String(v)), removeItem:k=>m.delete(k) };
  return m;
}
beforeEach(()=>preparar());
afterEach(()=>{ delete globalThis.matchMedia; delete globalThis.sessionStorage; });

test('web: entrarApple abre popup da Apple pedindo e-mail e nome em pt_BR',async()=>{
  await cloud.entrarApple();
  assert.deepEqual(ctrl.passos,['popup']);
  const p=ctrl.popups[0];
  assert.equal(p.providerId,'apple.com');
  assert.deepEqual(p.escopos,['email','name']);
  assert.deepEqual(p.parametros,{locale:'pt_BR'});
});
test('web: PWA instalado usa redirect e lembra que foi a Apple',async()=>{
  const sessao=sessaoFalsa(); globalThis.matchMedia=q=>({matches:q==='(display-mode: standalone)'});
  await cloud.entrarApple();
  assert.deepEqual(ctrl.passos,['redirect']);
  assert.equal(sessao.get('custta-redirect'),'apple.com');
});
test('web: popup bloqueado cai no redirect; desistência sobe',async()=>{
  sessaoFalsa();
  ctrl.falhas.popup={code:'auth/popup-blocked'};
  await cloud.entrarApple();
  assert.deepEqual(ctrl.passos,['popup','redirect']);
  ctrl.passos=[]; ctrl.falhas.popup={code:'auth/popup-closed-by-user'};
  await assert.rejects(cloud.entrarApple(),{code:'auth/popup-closed-by-user'});
});
test('volta do redirect com erro avisa o provedor certo e esquece a marca',async()=>{
  const sessao=sessaoFalsa({'custta-redirect':'apple.com'});
  ctrl.falhas.redirectResult={code:'auth/account-exists-with-different-credential'};
  await carregar(); await tique();
  const ev=eventos.find(e=>e.type==='cloud-social-erro');
  assert.deepEqual(ev.detail,{code:'auth/account-exists-with-different-credential',provedor:'apple.com'});
  assert.equal(sessao.has('custta-redirect'),false);
  eventos=[]; await carregar(); await tique();
  assert.equal(eventos.find(e=>e.type==='cloud-social-erro').detail.provedor,'google.com','sem marca é Google');
});
test('web: nome que só veio na resposta da Apple vai pro displayName',async()=>{
  ctrl.resultadoPopup={ user:{uid:'u-teste',displayName:null}, _tokenResponse:{providerId:'apple.com',firstName:'Bia',lastName:'Lima'} };
  await cloud.entrarApple();
  assert.deepEqual(ctrl.perfisAtualizados,[{displayName:'Bia Lima'}]);
  ctrl.perfisAtualizados=[];
  ctrl.resultadoPopup={ user:{uid:'u-teste',displayName:'Já Tem'}, _tokenResponse:{providerId:'apple.com',firstName:'Bia'} };
  await cloud.entrarApple();
  assert.deepEqual(ctrl.perfisAtualizados,[],'não sobrescreve nome existente');
});
test('nativo: plugin da Apple + signInWithCredential com o nonce cru',async()=>{
  await preparar({ehNativo:true});
  ctrl.resultadoLogin={ user:{uid:'u-teste',displayName:null} };
  await cloud.entrarApple(); await cloud.entrarApple();
  assert.ok(!ctrl.passos.includes('popup'));
  assert.match(pedidos[0].rawNonce,/^[0-9a-f]{64}$/);
  assert.notEqual(pedidos[0].rawNonce,pedidos[1].rawNonce,'nonce novo a cada login');
  assert.deepEqual(ctrl.credenciais[0],{providerId:'apple.com',idToken:'id-apple',rawNonce:pedidos[0].rawNonce});
  assert.deepEqual(ctrl.perfisAtualizados[0],{displayName:'Bia Lima'});
});
test('nativo: desistência sobe sem tentar entrar',async()=>{
  await preparar({ehNativo:true});
  nativo.falha={code:'auth/user-cancelled'};
  await assert.rejects(cloud.entrarApple(),{code:'auth/user-cancelled'});
  assert.deepEqual(ctrl.credenciais,[]);
});
test('nativo: Apple sem idToken é erro, não login',async()=>{
  await preparar({ehNativo:true});
  nativo.resposta={idToken:'',authorizationCode:'x'};
  await assert.rejects(cloud.entrarApple(),{code:'auth/invalid-credential'});
  assert.deepEqual(ctrl.credenciais,[]);
});
test('falha ao gravar o nome não derruba o login',async()=>{
  await preparar({ehNativo:true});
  ctrl.resultadoLogin={ user:{uid:'u-teste',displayName:null} };
  ctrl.falhas.updateProfile={code:'auth/network-request-failed'};
  await cloud.entrarApple();
  assert.ok(ctrl.passos.includes('credencial'));
});
test('perfilPendente vale para conta Apple',async()=>{
  await entraComo(['apple.com']);
  assert.equal(await cloud.perfilPendente(),true);
  ctrl.perfil={origem:'instagram'};
  assert.equal(await cloud.perfilPendente(),false);
});
test('web: apagar conta só Apple reautentica pela Apple, revoga o access token e apaga',async()=>{
  await entraComo(['apple.com']); ctrl.passos=[];
  ctrl.resultadoPopup={ credencial:{accessToken:'tok-apple'} };
  await cloud.apagarConta('','APAGAR');
  assert.equal(ctrl.passos[0],'reauthPopup');
  assert.equal(ctrl.popups.at(-1).providerId,'apple.com');
  assert.deepEqual(ctrl.revogados,['tok-apple']);
  const i=n=>ctrl.passos.indexOf(n);
  assert.ok(i('commit')<i('revogar') && i('revogar')<i('deleteUser'),'revoga depois de apagar os dados e antes do usuário: '+ctrl.passos);
});
test('app: apagar conta só Apple reautentica pelo plugin e revoga o código pela API',async()=>{
  await preparar({ehNativo:true});
  await entraComo(['apple.com']); ctrl.passos=[];
  await cloud.apagarConta('','APAGAR');
  assert.equal(ctrl.passos[0],'reauthApple');
  assert.equal(chamadasFetch.length,1);
  const {url,init}=chamadasFetch[0];
  assert.ok(url.startsWith('https://identitytoolkit.googleapis.com/v2/accounts:revokeToken?key='),url);
  assert.equal(init.method,'POST');
  assert.deepEqual(JSON.parse(init.body),{providerId:'apple.com',tokenType:'CODE',token:'codigo-apple',idToken:'token-teste'});
  assert.ok(ctrl.passos.includes('deleteUser'));
});
test('revogação que falha não impede apagar a conta e fica no diagnóstico',async()=>{
  await entraComo(['apple.com']); ctrl.passos=[];
  ctrl.resultadoPopup={ credencial:{accessToken:'tok-apple'} };
  ctrl.falhas.revogar={code:'auth/internal-error',message:'falhou'};
  await cloud.apagarConta('','APAGAR');
  assert.ok(ctrl.passos.includes('deleteUser'));
  assert.equal(diag[0][0],'apple-revogar');

  await preparar({ehNativo:true});
  globalThis.fetch=async()=>({ok:false,status:400});
  await entraComo(['apple.com']); ctrl.passos=[];
  await cloud.apagarConta('','APAGAR');
  assert.ok(ctrl.passos.includes('deleteUser'));
  assert.equal(diag[0][0],'apple-revogar');
});
test('conta com senha (mesmo com Apple) confirma pela senha e não revoga',async()=>{
  await entraComo(['password','apple.com']); ctrl.passos=[];
  await cloud.apagarConta('senha','APAGAR');
  assert.ok(ctrl.passos.includes('reauth'));
  for(const p of ['reauthPopup','reauthApple','revogar']) assert.ok(!ctrl.passos.includes(p),p);
});
test('conta Google + Apple sem senha confirma pela Apple',async()=>{
  await entraComo(['google.com','apple.com']);
  ctrl.resultadoPopup={ credencial:{accessToken:'tok'} };
  await cloud.apagarConta('','APAGAR');
  assert.equal(ctrl.popups.at(-1).providerId,'apple.com');
});
test('trocarSenha continua reautenticando por senha',async()=>{
  await entraComo(['password']); ctrl.passos=[];
  await cloud.trocarSenha('Velha2026x','Nova2026xy');
  assert.deepEqual(ctrl.passos.filter(p=>['reauth','senha'].includes(p)),['reauth','senha']);
});
```

Em `tests/google-cloud.test.mjs`, trocar o teste `falha na volta do redirect vira evento cloud-google-erro` por:

```js
test('falha na volta do redirect vira evento cloud-social-erro do Google',async()=>{
  ctrl.falhas.redirectResult={code:'auth/account-exists-with-different-credential'};
  await carregar(); await tique();
  const ev=eventos.find(e=>e.type==='cloud-social-erro');
  assert.ok(ev); assert.deepEqual(ev.detail,{code:'auth/account-exists-with-different-credential',provedor:'google.com'});
});
```

Em `package.json`, acrescentar `tests/apple-cloud.test.mjs` logo depois de `tests/google-cloud.test.mjs` no script `test:unit`.

- [ ] **Passo 3: rodar e ver falhar.** `node --test tests/apple-cloud.test.mjs tests/google-cloud.test.mjs` → FAIL (`cloud.entrarApple is not a function`, evento).

- [ ] **Passo 4: implementar em `cloud.js`.**

(a) Import do auth — acrescentar uma linha depois de `GoogleAuthProvider, ... reauthenticateWithPopup,`:

```js
  OAuthProvider, signInWithCredential, revokeAccessToken, updateProfile,
```

(b) Trocar o bloco do `getRedirectResult` (logo depois de `const auth = getAuth(app);`) por:

```js
/* Qual botão mandou para o redirect: o erro na volta diz "Apple" ou "Google". */
const CHAVE_REDIRECT = 'custta-redirect';
function lembraRedirect(provedor){ try{ sessionStorage.setItem(CHAVE_REDIRECT, provedor); }catch{} }
function provedorDoRedirect(){
  try{
    const p = sessionStorage.getItem(CHAVE_REDIRECT);
    sessionStorage.removeItem(CHAVE_REDIRECT);
    return p === 'apple.com' ? 'apple.com' : 'google.com';
  }catch{ return 'google.com'; }
}
/* Volta do signInWithRedirect (PWA instalado / popup bloqueado). O usuário
   chega pelo onAuthStateChanged; aqui interessa o erro, pra tela de login, e o
   nome que a Apple manda só no primeiro login. */
getRedirectResult(auth).then(r=>{ provedorDoRedirect(); return guardaNomeApple(r); }, err=>{
  window.dispatchEvent(new CustomEvent('cloud-social-erro', { detail:{ code:(err && err.code) || 'desconhecido', provedor:provedorDoRedirect() } }));
});
```

(c) Depois de `function provedorGoogle(){...}`:

```js
function provedorApple(){
  const p = new OAuthProvider('apple.com');
  p.addScope('email'); p.addScope('name');
  p.setCustomParameters({ locale:'pt_BR' });
  return p;
}
/* Nonce do login nativo: 32 bytes aleatórios em hex. A Apple assina o SHA-256
   dele (nativo.js) e o Firebase confere com este valor cru. */
function nonceAleatorio(){
  const b = new Uint8Array(32); crypto.getRandomValues(b);
  return Array.from(b, x=>x.toString(16).padStart(2,'0')).join('');
}
async function credencialAppleNativa(){
  const rawNonce = nonceAleatorio();
  const r = await window.OBRA_NATIVO.entrarApple({ rawNonce });
  if(!r || !r.idToken) throw Object.assign(new Error('A Apple não devolveu a credencial.'), { code:'auth/invalid-credential' });
  return {
    credencial: new OAuthProvider('apple.com').credential({ idToken:r.idToken, rawNonce }),
    codigo: r.authorizationCode || '',
    nome: [r.givenName, r.familyName].filter(Boolean).join(' ').trim(),
  };
}
/* A Apple só manda o nome no primeiro login. No displayName ele chega ao "Falta
   pouco" (nomeExibicao) sem a tela pedir de novo. Melhor esforço: falhar aqui
   não desfaz o login. Na abertura (volta do redirect) currentUser pode ainda não
   existir; o try cobre. */
async function gravaNome(u, nome){
  if(!u || u.displayName || !nome) return;
  try{
    await updateProfile(u, { displayName:nome });
    if(currentUser && currentUser.uid === u.uid) currentUser.nomeExibicao = nome;
  }catch{}
}
/* Web: o Firebase costuma guardar o nome sozinho; quando não guarda, ele vem só
   na resposta desta vez (firstName/lastName). */
function guardaNomeApple(resultado){
  const r = resultado && resultado._tokenResponse;
  if(!r || r.providerId !== 'apple.com') return;
  return gravaNome(resultado.user, [r.firstName, r.lastName].filter(Boolean).join(' ').trim());
}
```

(d) Trocar `async function reautenticar(senha){...}` por:

```js
/* Conta sem senha confirma no provedor dela; com Google e Apple, Apple primeiro
   (é o que funciona também no app). Devolve a prova da Apple pra revogação. */
function provedorDaConta(){
  if(currentUser?.temSenha !== false) return 'password';
  return currentUser.provedores.includes('apple.com') ? 'apple.com' : 'google.com';
}
async function reautenticar(senha){
  const u = usuarioOnline();
  const provedor = provedorDaConta();
  let prova = null;
  if(provedor === 'apple.com'){
    if(nativo){
      const { credencial, codigo } = await credencialAppleNativa();
      await reauthenticateWithCredential(u, credencial);
      prova = { codigo };
    }else{
      const r = await reauthenticateWithPopup(u, provedorApple());
      prova = { accessToken: OAuthProvider.credentialFromResult(r)?.accessToken || '' };
    }
  }
  else if(provedor === 'google.com') await reauthenticateWithPopup(u, provedorGoogle());
  else await reauthenticateWithCredential(u, EmailAuthProvider.credential(u.email, senha));
  if(auth.currentUser?.uid !== u.uid) throw Object.assign(new Error('Sessão alterada.'), { code:'cancelled' });
  return { u, prova };
}
/* A Apple exige revogar o token ao apagar a conta (Guideline 5.1.1(v)). Na web o
   popup devolve access token, que o SDK revoga; no app a Apple devolve
   authorizationCode, que só o endpoint REST aceita (tokenType CODE, o mesmo pedido
   do SDK nativo do Firebase). Falha aqui não segura a exclusão: fica no diagnóstico. */
async function revogarApple(u, prova){
  if(!prova) return;
  try{
    if(prova.accessToken){ await revokeAccessToken(auth, prova.accessToken); return; }
    if(!prova.codigo) throw new Error('Apple sem token para revogar');
    const resp = await fetch('https://identitytoolkit.googleapis.com/v2/accounts:revokeToken?key=' + firebaseConfig.apiKey, {
      method:'POST', headers:{ 'Content-Type':'application/json' },
      body: JSON.stringify({ providerId:'apple.com', tokenType:'CODE', token:prova.codigo, idToken: await getIdToken(u) }),
    });
    if(!resp.ok) throw new Error('revokeToken HTTP ' + resp.status);
  }catch(err){
    try{ window.OBRA_DIAG?.registra('apple-revogar', (err && err.message) || String(err), err && err.stack); }catch{}
  }
}
```

(e) Em `entrarGoogle`, marcar o redirect antes de cada `signInWithRedirect`:

```js
    if(pwaInstalado()){ lembraRedirect('google.com'); return signInWithRedirect(auth, provedorGoogle()); }
    try{ await signInWithPopup(auth, provedorGoogle()); }
    catch(err){
      if(err?.code === 'auth/popup-blocked'){ lembraRedirect('google.com'); return signInWithRedirect(auth, provedorGoogle()); }
      throw err;
    }
```

(f) Logo depois de `entrarGoogle`, dentro de `window.CLOUD`:

```js
  async entrarApple(){
    if(cacheBloqueado) throw Object.assign(new Error('Limpe os dados locais antes de entrar.'), { code:'cache' });
    auth.languageCode = 'pt-BR';
    if(nativo){
      const { credencial, nome } = await credencialAppleNativa();
      const r = await signInWithCredential(auth, credencial);
      await gravaNome(r?.user, nome);
      return;
    }
    if(pwaInstalado()){ lembraRedirect('apple.com'); return signInWithRedirect(auth, provedorApple()); }
    try{ await guardaNomeApple(await signInWithPopup(auth, provedorApple())); }
    catch(err){
      if(err?.code === 'auth/popup-blocked'){ lembraRedirect('apple.com'); return signInWithRedirect(auth, provedorApple()); }
      throw err;
    }
  },
```

(g) `perfilPendente`: comentário passa a dizer "Só conta Google ou Apple" e a guarda vira

```js
    if(!u || !currentUser?.provedores.some(p=>p === 'google.com' || p === 'apple.com')) return false;
```

(h) `trocarSenha`: `const { u } = await reautenticar(atual);`

(i) `apagarConta`: trocar o trecho do `soGoogle` e o `deleteUser` por:

```js
      /* Conta sem senha (Google ou Apple): a confirmação precisa sair ainda no
         gesto do usuário. Depois dos awaits da trava entre abas o Safari bloqueia
         o popup. reautenticar confere o uid, e o corpo da trava confere de novo
         antes do batch. */
      const semSenha = currentUser?.temSenha === false;
      let prova = null;
      if(semSenha){ ({ prova } = await reautenticar()); opcoes?.aoConfirmar?.(); }
      return await contaExclusiva(async()=>{
        if(!semSenha) await reautenticar(senha);
```

e, no fim do corpo da trava:

```js
        marcaCache(true);
        await revogarApple(u, prova);
        try{ await deleteUser(u); }catch(err){ marcaCache(false); throw err; }
```

- [ ] **Passo 5: rodar e ver passar.** `node --test tests/apple-cloud.test.mjs tests/google-cloud.test.mjs tests/fila.test.mjs tests/conta.test.mjs tests/cloud-nativo.test.mjs tests/push-cloud.test.mjs tests/sync.test.cjs` → todos PASS (as outras suítes do `cloud.js` provam que o duplê estendido não quebrou nada).

- [ ] **Passo 6: entregar.** Arquivos: `cloud.js`, `tests/helpers/firebase-stub.mjs`, `tests/apple-cloud.test.mjs`, `tests/google-cloud.test.mjs`, `package.json`. Commit sugerido: `feat: login, reautenticação e revogação com Apple no cloud.js`.

---

### Tarefa 5: tela de login, "Falta pouco" e diálogo de conta

**Arquivos:**
- Modificar: `index.html` (bloco `#authGoogle`, form `#fPerfil`), `styles.css` (tokens de tema e `.auth-google`/`.btn.google`), `auth.js`, `ui-confirm.js`, `sw.js` (`CACHE`)
- Teste: `tests/dialogos.test.cjs`

**Interfaces:**
- Consome: `CLOUD.entrarApple()`, `CLOUD.entrarGoogle()`, `CLOUD.user().provedores/nomeExibicao`, evento `cloud-social-erro`, `OBRA_CADASTRO.mensagemErroSocial`, `normalizaPerfil(..., {nomeOpcional})`, `nomeDoGoogle`.
- Produz (para a Tarefa 6): `#authSocial`, `#btnApple`, `#btnAppleTexto`, `#btnGoogle` (esconde sozinho no nativo), `#pNomes` (nome + sobrenome do "Falta pouco"), `#pTexto`.

- [ ] **Passo 1: escrever o teste que falha.** Em `tests/dialogos.test.cjs`:

```js
test('login com Apple: botão acima do Google, bloco social e "Falta pouco" sem nome', ()=>{
  const html = readFileSync(join(__dirname, '..', 'index.html'), 'utf8');
  const social = html.match(/<div id="authSocial" class="auth-social">([\s\S]*?)<\/div>\s*<form id="fLogin"/);
  assert.ok(social, 'bloco #authSocial antes do formulário de login');
  assert.ok(social[1].indexOf('id="btnApple"') < social[1].indexOf('id="btnGoogle"'), 'Apple antes do Google (HIG)');
  assert.match(social[1], /<svg[^>]*aria-hidden="true"[\s\S]*?fill="currentColor"/);
  assert.match(social[1], /<span id="btnAppleTexto">Continuar com a Apple<\/span>/);
  assert.doesNotMatch(html, /id="authGoogle"/);
  assert.match(html, /<div id="pNomes">[\s\S]*id="pNome"[\s\S]*id="pSobrenome"[\s\S]*?<\/div><\/div>/);
  assert.match(html, /<p class="auth-perfil-texto" id="pTexto">/);
  const auth = readFileSync(join(__dirname, '..', 'auth.js'), 'utf8');
  assert.match(auth, /CLOUD\.entrarApple\(\)/);
  assert.match(auth, /cloud-social-erro/);
  assert.match(auth, /nomeOpcional/);
  const ui = readFileSync(join(__dirname, '..', 'ui-confirm.js'), 'utf8');
  assert.match(ui, /provedores\?\.includes\('apple\.com'\)/);
});
```

- [ ] **Passo 2: rodar e ver falhar.** `node --test tests/dialogos.test.cjs` → FAIL.

- [ ] **Passo 3: `index.html`.** Trocar o bloco `<div id="authGoogle" class="auth-google">...</div>` por:

```html
          <div id="authSocial" class="auth-social">
            <button type="button" class="btn apple" id="btnApple"><svg viewBox="0 0 814 1000" width="16" height="19" aria-hidden="true" focusable="false"><path fill="currentColor" d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z"/></svg><span id="btnAppleTexto">Continuar com a Apple</span></button>
            <button type="button" class="btn google" id="btnGoogle"><img src="google-g.svg" alt="" width="18" height="18"><span id="btnGoogleTexto">Continuar com Google</span></button>
            <div class="auth-ou" aria-hidden="true"><span>ou</span></div>
          </div>
```

No `#fPerfil`: dar `id="pTexto"` ao `<p class="auth-perfil-texto">` e envolver os dois campos de nome:

```html
            <div id="pNomes">
            <div class="field"><label for="pNome">Nome</label>
              <input id="pNome" type="text" autocomplete="given-name" autocapitalize="words" maxlength="60" placeholder="Seu nome"></div>
            <div class="field"><label for="pSobrenome">Sobrenome <span class="opcional">(opcional)</span></label>
              <input id="pSobrenome" type="text" autocomplete="family-name" autocapitalize="words" maxlength="80" placeholder="Seu sobrenome"></div></div>
```

- [ ] **Passo 4: `styles.css`.** No bloco `:root{` do topo (tema escuro, padrão) acrescentar `--apple-fundo:#fff;--apple-texto:#000;`; no primeiro `html[data-theme="light"]{` acrescentar `--apple-fundo:#000;--apple-texto:#fff;` (as cores são da Apple, iguais nas duas skins). Trocar `.auth-google{margin-bottom:6px}` por:

```css
  .auth-social{margin-bottom:6px;display:flex;flex-direction:column;gap:10px}
  /* Botão da Apple pelas regras dela (HIG): sólido, branco no escuro e preto no claro,
     nunca menor que o do Google. Sem vidro: a Apple exige as cores dela. */
  .btn.apple{width:100%;display:flex;align-items:center;justify-content:center;gap:8px;
    background:var(--apple-fundo);color:var(--apple-texto);border:1px solid var(--apple-fundo)}
  .btn.apple svg{flex:none;margin-top:-2px}
```

e remover o `margin` de cima do separador dentro do bloco (`.auth-social .auth-ou{margin-top:4px}`), pra o `gap` não somar com os 14px.

- [ ] **Passo 5: `auth.js`.**

1. `let jaLogou = false, checagem = 0, erroGoogle = '';` → `erroSocial`; renomear todas as ocorrências de `erroGoogle` para `erroSocial` e os comentários de "Google" para "login social" onde falam do erro.
2. Em `aoTrocarUsuario`: `if(u.provedores?.some(p=>p === 'google.com' || p === 'apple.com') && await CLOUD.perfilPendente()){`; comentário do bloco: "Conta Google ou Apple entra sem perfil".
3. Antes de `mostrarPerfil`:

```js
  /* Conta Apple: o nome vem da Apple e a revisão reprova pedir de novo. */
  const contaApple = u => !!u?.provedores?.includes('apple.com');
```

e em `mostrarPerfil`: trocar `$('#authGoogle')` por `$('#authSocial')` e, depois de mostrar `#fPerfil`:

```js
    const apple = contaApple(u);
    $('#pNomes').classList.toggle('hidden', apple);
    $('#pTexto').textContent = apple ? 'Só falta contar como você conheceu o Custta.' : 'Confirme seu nome e conte como conheceu o Custta.';
```

4. Em `mostrarAba`: trocar a linha do `#authGoogle` por

```js
    $('#authSocial').classList.remove('hidden');
    $('#btnGoogle').classList.toggle('hidden', !!window.OBRA_NATIVO?.ehNativo());
```

5. Trocar o bloco `/* ---------- Google ---------- */` inteiro (botão + listener `cloud-google-erro`) por:

```js
  /* ---------- Apple e Google ---------- */
  function ligaSocial({ botao, texto, rotulo, abrindo, entrar, provedor }){
    const btn = $(botao), t = $(texto);
    btn.onclick = async()=>{
      const msg = $('#fCad').classList.contains('hidden') ? $('#lMsg') : $('#cMsg');
      msg.textContent = ''; erroSocial = '';
      // Um login por vez: o outro botão também trava até este voltar.
      const botoes = [...document.querySelectorAll('#authSocial .btn')];
      botoes.forEach(b=>{ b.disabled = true; }); t.textContent = abrindo;
      try{ await entrar(); }
      catch(err){ msg.textContent = err?.code === 'cache' ? 'Limpe os dados locais antes de entrar.' : OBRA_CADASTRO.mensagemErroSocial(err?.code, provedor); }
      finally{ botoes.forEach(b=>{ b.disabled = false; }); t.textContent = rotulo; }
    };
  }
  ligaSocial({ botao:'#btnApple', texto:'#btnAppleTexto', rotulo:'Continuar com a Apple', abrindo:'Abrindo a Apple…', entrar:()=>CLOUD.entrarApple(), provedor:'apple.com' });
  ligaSocial({ botao:'#btnGoogle', texto:'#btnGoogleTexto', rotulo:'Continuar com Google', abrindo:'Abrindo o Google…', entrar:()=>CLOUD.entrarGoogle(), provedor:'google.com' });
  /* Erro na volta do redirect. Pode chegar antes do onAuth(null), que limpa
     #lMsg: guarda pra reescrever depois. */
  window.addEventListener('cloud-social-erro', e=>{
    erroSocial = OBRA_CADASTRO.mensagemErroSocial(e.detail?.code, e.detail?.provedor);
    $('#lMsg').textContent = erroSocial;
  });
```

6. No submit do `#fPerfil`, trocar a montagem de `r` por:

```js
    const apple = contaApple(CLOUD.user());
    const nomes = apple ? OBRA_CADASTRO.nomeDoGoogle(CLOUD.user()?.nomeExibicao)
      : { nome:$('#pNome').value, sobrenome:$('#pSobrenome').value };
    const r = OBRA_CADASTRO.normalizaPerfil({ ...nomes, origem:$('#pOrigem').value, origemDetalhe:$('#pDetalhe').value }, { nomeOpcional:apple });
```

Comentário do bloco: "Falta pouco (conta Google ou Apple sem perfil)".

- [ ] **Passo 6: `ui-confirm.js`.** Antes de `function mensagem(err){`:

```js
  /* Conta sem senha confirma pela Apple ou pelo Google (Apple primeiro, como no cloud.js). */
  function provedorSemSenha(){
    return CLOUD.user()?.provedores?.includes('apple.com')
      ? { nome:'Apple', com:'com a Apple', da:'da Apple' }
      : { nome:'Google', com:'com o Google', da:'do Google' };
  }
```

Em `mensagem(err)`, trocar as três linhas do Google por:

```js
    const p = provedorSemSenha();
    if(['auth/popup-closed-by-user','auth/cancelled-popup-request','auth/user-cancelled'].includes(err.code)) return `Confirmação ${p.com} cancelada.`;
    if(err.code === 'auth/popup-blocked') return `O navegador bloqueou a janela ${p.da}. Permita pop-ups e tente de novo.`;
    if(err.code === 'auth/user-mismatch') return `Entre com a mesma conta ${p.nome} desta conta.`;
```

No diálogo de apagar: `' Para confirmar, você vai entrar com o Google de novo.'` → `` ' Para confirmar, você vai entrar ' + provedorSemSenha().com + ' de novo.' ``; e em `executar`, `'Confirme sua conta Google na janela que abriu.'` → `` `Confirme sua conta ${provedorSemSenha().nome} na janela que abriu.` ``, com o comentário "Conta sem senha: a confirmação (Google ou Apple) abre primeiro; só depois dela a conta é apagada."

- [ ] **Passo 7: `sw.js`.** `const CACHE = 'obras-v57';` → `'obras-v58'` (HTML, CSS e JS do login mudaram; aparelho instalado precisa do retrato novo offline).

- [ ] **Passo 8: rodar e ver passar.** `node --test tests/dialogos.test.cjs tests/cadastro.test.cjs tests/vidro.test.cjs tests/xss.test.cjs tests/headers.test.cjs tests/pwa.test.cjs tests/icons.test.cjs` → todos PASS.

- [ ] **Passo 9: conferir o visual.** Subir `node tests/browser/servidor.cjs` em segundo plano e fotografar a tela de login com Playwright (script descartável em `$CLAUDE_JOB_DIR/tmp`, com `sessionStorage.splashVista='1'` por `addInitScript` e `cloud.js` trocado por vazio via `route`, como em `tests/browser/nativo.cjs`), em 390×844 nos quatro combos (`localStorage` `mo_tema` = `escuro`/`claro`, `mo_skin` = `esmeralda`/`azul`, definidos por `addInitScript` antes do carregamento). Conferir no PNG: logo da Apple reconhecível e centralizado com o texto, botão branco no escuro e preto no claro, mesma altura do Google, Apple acima do Google, separador "ou" com respiro. Ajustar e fotografar de novo se algo estiver torto. Não abrir `localhost:8123` com `cloud.js` real (fala com a produção).

- [ ] **Passo 10: entregar.** Arquivos: `index.html`, `styles.css`, `auth.js`, `ui-confirm.js`, `sw.js`, `tests/dialogos.test.cjs`. Commit sugerido: `feat: botão Continuar com a Apple e Falta pouco sem pedir nome`.

---

### Tarefa 6: suíte de navegador do login com Apple

**Arquivos:**
- Criar: `tests/browser/apple.cjs`
- Modificar: `tests/browser/google.cjs` (passos 9 e 10), `tests/browser/rodar.cjs`

**Interfaces:**
- Consome tudo das Tarefas 1–5 (seletores listados na Tarefa 5, evento `cloud-social-erro`).

- [ ] **Passo 1: ajustar `google.cjs`.** No passo 9, disparar `new CustomEvent('cloud-social-erro',{detail:{code:'auth/account-exists-with-different-credential',provedor:'google.com'}})` e esperar `'Este e-mail já tem conta no Custta. Entre do jeito que você usou da primeira vez.'`. No passo 10 (nativo), trocar as duas conferências de `#authGoogle` por `#btnGoogle` invisível **e** `#btnApple` visível, nas duas abas; log `ok - no app nativo o Google fica escondido e a Apple aparece`.

- [ ] **Passo 2: criar `tests/browser/apple.cjs`.** Mesmo esqueleto do `google.cjs` (cabeçalho, `BASE` em 127.0.0.1, `cloudEmulado`, `abrirPopup`, `escolherConta`, `travado`, `sair`, `novoContexto`, `abrirApp`, `leDoc`, violações de CSP e erros de página — copiar essas funções de `google.cjs` sem mudar). Diferenças:

```js
async function entrarApplePeloEmulador(page, email, nome){
  const popup=await abrirPopup(page, ()=>page.locator('#btnApple').click());
  await popup.locator('#add-account-button').click();
  await popup.locator('#email-input').fill(email);
  if(nome) await popup.locator('#display-name-input').fill(nome);
  await popup.locator('#sign-in').click();
}
/* Revogação: na web o SDK chama o emulador; no app o cloud.js chama a produção.
   As duas passam por aqui e nunca saem da máquina. */
async function interceptaRevogacao(context, status=200){
  const pedidos=[];
  await context.route(/accounts:revokeToken/, async r=>{
    pedidos.push(r.request().postDataJSON());
    await r.fulfill({status, contentType:'application/json', headers:{'access-control-allow-origin':'*'}, body:status===200?'{}':'{"error":{"code":500,"message":"INTERNAL"}}'});
  });
  return pedidos;
}
/* App nativo: CSP da <meta> do www/ (libera a checagem de versão) e plugin AppleSignIn
   falso. O id_token em JSON é aceito pelo Auth emulator sem assinatura. */
async function contextoNativo(novoContexto){
  const ctx=await novoContexto();
  await ctx.route(BASE+'/',async r=>{
    const resp=await r.fetch(); const h=resp.headers();
    h['content-security-policy']=h['content-security-policy'].replace("connect-src 'self'","connect-src 'self' https://app-construcao-civil.vercel.app");
    await r.fulfill({response:resp,headers:h});
  });
  await ctx.route('https://app-construcao-civil.vercel.app/versao.json',r=>r.fulfill({contentType:'application/json',headers:{'access-control-allow-origin':'*'},body:fs.readFileSync(path.join(ROOT,'versao.json'),'utf8')}));
  await ctx.addInitScript(()=>{
    window.__pedidosApple=[]; window.__respostaApple=null;
    window.Capacitor={ isNativePlatform:()=>true, getPlatform:()=>'ios', Plugins:{
      AppleSignIn:{ signIn:async a=>{ window.__pedidosApple.push(a); const r=window.__respostaApple; if(r && r.erro) throw Object.assign(new Error(r.erro.message),{code:r.erro.code}); return r; } } } };
  });
  return ctx;
}
const idTokenFalso=(sub,email)=>JSON.stringify({sub,email,email_verified:true});
```

Casos, em ordem, cada um com `console.log('ok - ...')`:

1. **Web, botões:** nas abas Entrar e Criar conta, `#btnApple` e `#btnGoogle` visíveis; `boundingBox().y` do Apple menor que o do Google; altura do Apple ≥ 44 e igual à do Google (±1px); `#fPerfil` escondido.
2. **Web, primeiro login Apple:** `entrarApplePeloEmulador(page,'bia@privaterelay.appleid.com','Beatriz Lima')` → `#fPerfil` visível, `#pNomes` **escondido**, `#pTexto` = `Só falta contar como você conheceu o Custta.`, `CLOUD.user().provedores` = `['apple.com']`, ainda travado.
3. **Web, completar:** `selectOption('#pOrigem','instagram')` → submit → destrava → `perfis/{uid}` com `nome:'Beatriz'`, `sobrenome:'Lima'`, `origem:'instagram'`, `email:'bia@privaterelay.appleid.com'`, `tz` e `criado`.
4. **Web, Ajustes:** `#ajSenha` e `#avisoEmail` escondidos.
5. **Web, segundo login:** `sair` → clicar `#btnApple` → `escolherConta(popup,'bia@privaterelay.appleid.com')` → destrava direto, mesmo uid, sem `#fPerfil`.
6. **Web, apagar conta Apple:** `const revogacoes=await interceptaRevogacao(context)`; Ajustes → `#ajApagar` → sem `#contaSenha` → `APAGAR` → popup abre e `#contaMensagem` = `Confirme sua conta Apple na janela que abriu.` → `escolherConta` → travado e sem usuário → `#fLogin` visível (espera de até 20s, como no `google.cjs`) → `dados`, `perfis` e `push` do uid não existem → `revogacoes.length === 1`, `revogacoes[0].providerId === 'apple.com'`, `revogacoes[0].tokenType === 'ACCESS_TOKEN'`, `revogacoes[0].token` não vazio.
7. **Web, Apple sem nome + revogação falhando:** contexto novo com `interceptaRevogacao(ctx, 500)`; `entrarApplePeloEmulador(page,'sem.nome@privaterelay.appleid.com')` (sem nome) → `#pNomes` escondido → origem `youtube` → destrava → `perfis/{uid}` **sem** a chave `nome` e com `origem:'youtube'` → apagar conta → conta apagada mesmo com 500 (documentos somem, tela de login volta).
8. **App, desistência:** `contextoNativo` → `window.__respostaApple={erro:{code:'SIGN_IN_CANCELED',message:'Sign in was canceled.'}}` → clicar `#btnApple` → esperar `#btnApple` habilitado de novo → `#lMsg` vazio, ainda travado; `#btnGoogle` invisível e `#btnApple` visível.
9. **App, primeiro login:** `window.__respostaApple={idToken:idTokenFalso('apple-caio','caio@privaterelay.appleid.com'),authorizationCode:'codigo-caio',givenName:'Caio',familyName:'Prado'}` → clicar `#btnApple` → `#fPerfil` com `#pNomes` escondido → último pedido com `scopes` `['EMAIL','FULL_NAME']` e `nonce` casando `/^[0-9a-f]{64}$/` → origem `google` → destrava → `perfis/{uid}` com `nome:'Caio'`, `sobrenome:'Prado'`.
10. **App, apagar conta:** `const rev=await interceptaRevogacao(ctxNativo)`; mesma `__respostaApple` (mesmo `sub`) → Ajustes → apagar → `APAGAR` → enviar → travado e sem usuário → documentos somem → `rev[0]` com `providerId:'apple.com'`, `tokenType:'CODE'`, `token:'codigo-caio'` e `idToken` não vazio → o nonce do segundo pedido difere do primeiro.
11. `assert.deepEqual(violacoes,[])` e `assert.deepEqual(errosPagina,[])`.

- [ ] **Passo 3: registrar no orquestrador.** Em `tests/browser/rodar.cjs`, depois de `await run('tests/browser/google.cjs');`, acrescentar `await run('tests/browser/apple.cjs');`.

- [ ] **Passo 4: rodar.** Primeiro as duas suítes, com servidor e emuladores:

```bash
npx firebase emulators:exec --config firebase.test.json --project demo-custta-phase2 --only firestore,auth "node tests/browser/servidor.cjs & sleep 2; node tests/browser/google.cjs && node tests/browser/apple.cjs; kill %1"
```

Esperado: todos os `ok - ...` e saída 0. Depois a suíte completa: `npm run test:browser` → saída 0. (Java está em `~/.local`; se o emulador não subir, conferir `java -version`.)

- [ ] **Passo 5: entregar.** Arquivos: `tests/browser/apple.cjs`, `tests/browser/google.cjs`, `tests/browser/rodar.cjs`. Commit sugerido: `test: login com Apple no navegador, na web e no app simulado`.

---

### Tarefa 7: política de privacidade, SDKs, metadados da loja e documentação

**Arquivos:**
- Modificar: `privacidade.html`, `tests/privacidade.test.cjs`, `docs/sdks-fase4.md`, `docs/app-store-metadados.md`, `CLAUDE.md`, `docs/specs/2026-09-30-login-apple-design.md`

- [ ] **Passo 1: testes que falham.** Em `tests/privacidade.test.cjs`: no primeiro teste, o filtro de SDKs passa a `n => n.startsWith('@capacitor') || n.startsWith('@capawesome')`; a data esperada de `Versão vigente` vira `30 de setembro de 2026`; e acrescentar:

```js
test('política explica o login com Apple, o e-mail de retransmissão e a revogação', ()=>{
  const politica = ler('privacidade.html');
  assert.match(politica, /conta Apple/);
  assert.match(politica, /privaterelay\.appleid\.com/);
  assert.match(politica, /desfaça a ligação com o Custta/);
});
```

- [ ] **Passo 2: rodar e ver falhar.** `node --test tests/privacidade.test.cjs` → FAIL.

- [ ] **Passo 3: `privacidade.html`.** Atualizar `Versão vigente` para `30 de setembro de 2026.` e, logo depois do parágrafo que cita **Google Firebase** e **Vercel**, acrescentar:

```html
  <p>Você pode entrar com e-mail e senha, com sua conta Google ou com sua conta Apple. Ao entrar com a Apple, recebemos da Apple um identificador da conta, o e-mail — que pode ser um endereço de retransmissão terminado em <strong>@privaterelay.appleid.com</strong>, se você escolher ocultar seu e-mail — e, no primeiro acesso, o nome que você autorizar. Ao apagar a conta, também pedimos à Apple que desfaça a ligação com o Custta.</p>
```

- [ ] **Passo 4: `docs/sdks-fase4.md`.** Linha nova na tabela, depois de `@capacitor-firebase/messaging`:

```markdown
| @capawesome/capacitor-apple-sign-in | 0.1.4 | iOS (nativo) | token de identidade e código de autorização da Apple; nome e e-mail no 1º login (repassados ao Firebase Auth) | conta |
```

- [ ] **Passo 5: `docs/app-store-metadados.md`.** Ler o arquivo. Nas notas de revisão (em inglês), acrescentar uma frase: `Sign in with Apple is offered on the login screen. The demo account below uses email and password.` Na seção de App Privacy, registrar que o login com Apple não cria tipo de dado novo (Name e Email Address já declarados, vinculados à identidade, finalidade App Functionality).

- [ ] **Passo 6: `CLAUDE.md`.** Na seção "App iOS (Capacitor)", acrescentar: `Login com Apple: no app, plugin @capawesome/capacitor-apple-sign-in via OBRA_NATIVO.entrarApple (nonce em SHA-256) + signInWithCredential; na web, OAuthProvider('apple.com') por popup/redirect. Conta só Apple reautentica pela Apple e apagarConta revoga o token (spec docs/specs/2026-09-30-login-apple-design.md). Services ID da web: br.com.custta.web.` No parágrafo da CSP, "existem só para o login com Google da web" vira "existem só para o login social da web (Google e Apple)".

- [ ] **Passo 7: corrigir o spec.** Em `docs/specs/2026-09-30-login-apple-design.md`: o item "Logo em SVG inline pelo `icons.js`..." vira "Logo em SVG inline no `index.html` (`fill="currentColor"`), porque os ícones do `icons.js` são de traço e o logo da Apple é preenchido"; tirar a linha `icons.js` da tabela de arquivos; acrescentar `docs/sdks-fase4.md` e `tests/privacidade.test.cjs`.

- [ ] **Passo 8: rodar e ver passar.** `node --test tests/privacidade.test.cjs tests/docs.test.mjs` → PASS.

- [ ] **Passo 9: entregar.** Arquivos: os seis acima. Commit sugerido: `docs: política, SDKs e metadados com o login com Apple`.

---

## Fechamento (controlador)

1. `npm run test:unit` e `npm run test:rules` (rules não mudaram; confirma) → verdes.
2. `npm run test:browser` → verde.
3. Revisão final da branch inteira (subagente revisor).
4. Push da `feat/login-apple` (autor único Giovani, sem `Co-Authored-By`), PR com descrição em prosa.
5. `gh pr checks` até a CI e o `ios-build` ficarem verdes; o `ios-testflight` roda sozinho (o PR mexe nas entitlements) e precisa assinar com o perfil novo.
6. agent-browser na prévia da Vercel: tela de login em iPhone 16 Pro (escuro/claro, esmeralda/azul) e desktop 1440; clique no Apple mostra `Login com a Apple indisponível neste endereço. Use custta.com.br.` (domínio da prévia não autorizado — esperado).
7. Atualizar a nota do Custta no Obsidian (estado + histórico) e a nota da Fase 5.
8. Entregar ao Giovani: link da prévia conferido, build do TestFlight, roteiro de teste no iPhone (app) e em custta.com.br (web, depois do merge).

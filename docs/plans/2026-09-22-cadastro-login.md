# Cadastro completo — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cadastro com regras de senha visíveis, nome/sobrenome e "como conheceu", gravados em `perfis/{uid}` e exibidos/editáveis em Ajustes.

**Architecture:** Regras puras num módulo novo `cadastro.js` (UMD, padrão de `dados.js`), consumido por `auth.js`, `ui-confirm.js` e `cloud.js`. `cloud.js` grava/lê o perfil; `firestore.rules` valida os campos novos. Sem build, sem dependência nova de runtime.

**Tech Stack:** Vanilla JS, Firebase Auth + Firestore (SDK vendorizado em `vendor/firebase/`), `node:test`, `@firebase/rules-unit-testing`, Playwright, emuladores Firebase.

**Spec:** `docs/plans/2026-09-22-cadastro-login-design.md`

## Global Constraints

- Código, identificadores, comentários e UI em **português** (PT-BR).
- CSP estrita: nada de `style="..."`, `<style>`, `onclick=` ou script inline no HTML. Estilo só em `styles.css`.
- Nenhuma dependência nova de runtime no browser; nada de bundler.
- Senha: ≥ 8, ≥ 1 letra, ≥ 1 número, ≤ 128, diferente do e-mail, fora da lista de senhas óbvias.
- Nome obrigatório 2–60 (cliente) / 1–60 (rules); sobrenome opcional ≤ 80; `origemDetalhe` ≤ 80.
- Origens: `instagram`, `indicacao`, `google`, `tiktok`, `youtube`, `outro` — nesta ordem.
- Login **não** muda: senha antiga de 6 caracteres continua entrando.
- Todo arquivo JS novo entra no `ASSETS` de `sw.js` (o `build:www` copia a partir dele).
- Commits com o autor configurado (Giovani Stuchi), **sem** linha `Co-Authored-By`.
- PATH para ferramentas: `export PATH="$HOME/.local/bin:$HOME/.local/opt/node/bin:$HOME/.local/opt/jdk21/Contents/Home/bin:$PWD/node_modules/.bin:$PATH"`.

## Review Focus

1. Espaços em volta de nome/e-mail ("  Ana  ") — gravar sem espaço sobrando; nome só de espaços conta como vazio. → Task 1 (`normalizaPerfil` teste de trim).
2. Senha com acento/emoji ou só letras maiúsculas ("ÇÃOSENHA1") — letra acentuada conta como letra. → Task 1 (teste de letra unicode).
3. Trocar a origem de "Indicação" para "Instagram" depois de digitar quem indicou — o detalhe não pode ir junto. → Task 1 (detalhe descartado) + Task 5 (campo some).
4. Usuário antigo sem nome/perfil incompleto abrindo Ajustes — não quebra, mostra "Adicionar nome". → Task 6 (teste de browser com perfil sem nome).
5. Deploy de rules fora de ordem — rules novas precisam aceitar o perfil antigo `{email, criado, tz}`. → Task 2 (teste de compatibilidade).

---

## Paralelismo

- **Onda 1 (paralelo):** Task 1, Task 2, Task 3 — arquivos disjuntos.
- **Onda 2:** Task 4 (depende de 1).
- **Onda 3:** Task 5, depois Task 6 (ambas mexem em `index.html` e `styles.css` — sequenciais).
- **Onda 4:** Task 7 (depende de tudo).

---

### Task 1: Módulo `cadastro.js` (regras puras)

**Files:**
- Create: `cadastro.js`
- Create: `tests/cadastro.test.cjs`
- Modify: `package.json` (script `test:unit`: acrescentar `tests/cadastro.test.cjs` logo após `tests/dados.test.cjs`)
- Modify: `sw.js:4` (acrescentar `'./cadastro.js'` ao array `ASSETS`, logo após `'./dados.js'`)
- Modify: `index.html` (acrescentar `<script defer src="cadastro.js"></script>` **antes** de `<script defer src="auth.js"></script>`)

**Interfaces:**
- Produces: `window.OBRA_CADASTRO` / `module.exports` = `{ REGRAS_SENHA, validaSenha(senha, email) → {ok, regras:[{id,texto,ok}], erro}, ORIGENS, LIMITES_PERFIL, normalizaPerfil({nome,sobrenome,origem,origemDetalhe}) → {ok, erro, campo, perfil}, normalizaNome({nome,sobrenome}) → {ok, erro, campo, perfil} }`. `campo` é o id lógico do primeiro campo inválido: `'nome' | 'sobrenome' | 'origem' | 'origemDetalhe'`.

- [ ] **Step 1: Write the failing test** — `tests/cadastro.test.cjs`:

```js
const {test}=require('node:test');
const assert=require('node:assert/strict');
const C=require('../cadastro.js');

test('senha válida passa em todas as regras',()=>{
  const r=C.validaSenha('Obra2026x','ana@exemplo.com');
  assert.equal(r.ok,true); assert.equal(r.erro,'');
  assert.ok(r.regras.every(x=>x.ok));
  assert.deepEqual(r.regras.map(x=>x.id),['tamanho','letra','numero','email','comum']);
});
test('cada regra falha sozinha com mensagem própria',()=>{
  assert.equal(C.validaSenha('Ab1','').erro,'Use pelo menos 8 caracteres.');
  assert.equal(C.validaSenha('12345678901','').erro,'Inclua pelo menos uma letra.');
  assert.equal(C.validaSenha('abcdefghij','').erro,'Inclua pelo menos um número.');
  assert.equal(C.validaSenha('ana@exemplo.com1','ana@exemplo.com1').erro,'A senha não pode ser igual ao e-mail.');
  assert.equal(C.validaSenha('senha123','').erro,'Essa senha é muito comum. Escolha outra.');
  assert.equal(C.validaSenha('x'.repeat(120)+'1'.repeat(9),'').erro,'Use no máximo 128 caracteres.');
});
test('igualdade com e-mail e lista comum ignoram maiúsculas e espaços',()=>{
  assert.equal(C.validaSenha(' ANA@exemplo.com1 ','ana@exemplo.com1').ok,false);
  assert.equal(C.validaSenha('SENHA123','').ok,false);
  assert.equal(C.validaSenha('12345678a','').ok,false);
});
test('letra acentuada conta como letra',()=>{
  assert.equal(C.validaSenha('ÇÃOÉÊÍ12','').ok,true);
});
test('valores não-string não quebram',()=>{
  assert.equal(C.validaSenha(undefined,null).ok,false);
  assert.equal(C.validaSenha(12345678,undefined).ok,false);
});
test('origens na ordem combinada; só indicação e outro têm detalhe',()=>{
  assert.deepEqual(C.ORIGENS.map(o=>o.id),['instagram','indicacao','google','tiktok','youtube','outro']);
  assert.deepEqual(C.ORIGENS.filter(o=>o.detalhe).map(o=>o.id),['indicacao','outro']);
});
test('perfil normaliza espaços e omite vazios',()=>{
  const r=C.normalizaPerfil({nome:'  Ana   Maria ',sobrenome:'   ',origem:'instagram',origemDetalhe:'x'});
  assert.equal(r.ok,true);
  assert.deepEqual(r.perfil,{nome:'Ana Maria',origem:'instagram'});
});
test('detalhe só vai junto de origem que aceita',()=>{
  assert.deepEqual(C.normalizaPerfil({nome:'Ana',origem:'indicacao',origemDetalhe:'  Seu  João '}).perfil,
    {nome:'Ana',origem:'indicacao',origemDetalhe:'Seu João'});
  assert.deepEqual(C.normalizaPerfil({nome:'Ana',sobrenome:'Lima',origem:'google',origemDetalhe:'Seu João'}).perfil,
    {nome:'Ana',sobrenome:'Lima',origem:'google'});
});
test('erros de perfil apontam o campo',()=>{
  assert.deepEqual(pick(C.normalizaPerfil({nome:' ',origem:'instagram'})),{ok:false,campo:'nome',erro:'Digite seu nome.'});
  assert.deepEqual(pick(C.normalizaPerfil({nome:'A',origem:'instagram'})),{ok:false,campo:'nome',erro:'O nome precisa de pelo menos 2 letras.'});
  assert.deepEqual(pick(C.normalizaPerfil({nome:'A'.repeat(61),origem:'instagram'})),{ok:false,campo:'nome',erro:'Use no máximo 60 caracteres no nome.'});
  assert.deepEqual(pick(C.normalizaPerfil({nome:'Ana',sobrenome:'L'.repeat(81),origem:'instagram'})),{ok:false,campo:'sobrenome',erro:'Use no máximo 80 caracteres no sobrenome.'});
  assert.deepEqual(pick(C.normalizaPerfil({nome:'Ana',origem:''})),{ok:false,campo:'origem',erro:'Conte como conheceu o Custta.'});
  assert.deepEqual(pick(C.normalizaPerfil({nome:'Ana',origem:'orkut'})),{ok:false,campo:'origem',erro:'Conte como conheceu o Custta.'});
  assert.deepEqual(pick(C.normalizaPerfil({nome:'Ana',origem:'outro',origemDetalhe:'x'.repeat(81)})),{ok:false,campo:'origemDetalhe',erro:'Use no máximo 80 caracteres.'});
  function pick(r){ return {ok:r.ok,campo:r.campo,erro:r.erro}; }
});
test('normalizaNome valida só nome e sobrenome',()=>{
  assert.deepEqual(C.normalizaNome({nome:' Ana ',sobrenome:' Lima '}).perfil,{nome:'Ana',sobrenome:'Lima'});
  assert.deepEqual(C.normalizaNome({nome:'Ana',sobrenome:''}).perfil,{nome:'Ana'});
  assert.equal(C.normalizaNome({nome:''}).campo,'nome');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/cadastro.test.cjs`
Expected: FAIL — `Cannot find module '../cadastro.js'`

- [ ] **Step 3: Write implementation** — `cadastro.js`:

```js
/* Regras do cadastro: senha, nome e "como conheceu".
   Puro, sem DOM — usado por auth.js, ui-confirm.js e cloud.js, e testado em node.
   As firestore.rules repetem os limites de tamanho e a lista de origens: mudou aqui, muda lá. */
(function(root){
  'use strict';
  const LIMITES_PERFIL = Object.freeze({nome:60, sobrenome:80, origemDetalhe:80});
  const ORIGENS = Object.freeze([
    {id:'instagram', nome:'Instagram'},
    {id:'indicacao', nome:'Indicação de alguém', detalhe:'Quem indicou? (opcional)'},
    {id:'google',    nome:'Pesquisa no Google'},
    {id:'tiktok',    nome:'TikTok'},
    {id:'youtube',   nome:'YouTube'},
    {id:'outro',     nome:'Outro', detalhe:'Onde? (opcional)'},
  ]);
  /* Lista curta de propósito: pega o óbvio que passaria nas outras regras. */
  const COMUNS = new Set(['senha123','senha1234','12345678a','123456789a','a12345678','abc12345','abcd1234',
    'qwerty123','password1','password123','custta123','obra1234','mudar123','brasil123','admin123']);
  const REGRAS_SENHA = Object.freeze([
    {id:'tamanho', texto:'8 caracteres ou mais'},
    {id:'letra',   texto:'Uma letra'},
    {id:'numero',  texto:'Um número'},
    {id:'email',   texto:'Diferente do e-mail'},
    {id:'comum',   texto:'Não é uma senha óbvia'},
  ]);
  const ERROS_SENHA = {tamanho:'Use pelo menos 8 caracteres.', letra:'Inclua pelo menos uma letra.',
    numero:'Inclua pelo menos um número.', email:'A senha não pode ser igual ao e-mail.',
    comum:'Essa senha é muito comum. Escolha outra.'};
  const str = v => typeof v === 'string' ? v : '';
  const limpa = v => str(v).trim().replace(/\s+/g,' ');

  function validaSenha(senha, email){
    const s = str(senha), chave = s.trim().toLowerCase(), e = str(email).trim().toLowerCase();
    const passa = {
      tamanho: s.length >= 8,
      letra:   /\p{L}/u.test(s),
      numero:  /\d/.test(s),
      email:   !(e && chave === e),
      comum:   !COMUNS.has(chave),
    };
    const regras = REGRAS_SENHA.map(r=>({...r, ok:passa[r.id]}));
    const falha = regras.find(r=>!r.ok);
    if(falha) return {ok:false, regras, erro:ERROS_SENHA[falha.id]};
    if(s.length > 128) return {ok:false, regras, erro:'Use no máximo 128 caracteres.'};
    return {ok:true, regras, erro:''};
  }

  const falhou = (campo, erro) => ({ok:false, campo, erro, perfil:null});
  function normalizaNome(d){
    const o = d && typeof d === 'object' ? d : {};
    const nome = limpa(o.nome), sobrenome = limpa(o.sobrenome);
    if(!nome) return falhou('nome','Digite seu nome.');
    if(nome.length < 2) return falhou('nome','O nome precisa de pelo menos 2 letras.');
    if(nome.length > LIMITES_PERFIL.nome) return falhou('nome','Use no máximo 60 caracteres no nome.');
    if(sobrenome.length > LIMITES_PERFIL.sobrenome) return falhou('sobrenome','Use no máximo 80 caracteres no sobrenome.');
    const perfil = {nome};
    if(sobrenome) perfil.sobrenome = sobrenome;
    return {ok:true, campo:'', erro:'', perfil};
  }
  function normalizaPerfil(d){
    const o = d && typeof d === 'object' ? d : {};
    const base = normalizaNome(o);
    if(!base.ok) return base;
    const origem = ORIGENS.find(x=>x.id === o.origem);
    if(!origem) return falhou('origem','Conte como conheceu o Custta.');
    const perfil = {...base.perfil, origem:origem.id};
    if(origem.detalhe){
      const detalhe = limpa(o.origemDetalhe);
      if(detalhe.length > LIMITES_PERFIL.origemDetalhe) return falhou('origemDetalhe','Use no máximo 80 caracteres.');
      if(detalhe) perfil.origemDetalhe = detalhe;
    }
    return {ok:true, campo:'', erro:'', perfil};
  }

  const api = {REGRAS_SENHA, validaSenha, ORIGENS, LIMITES_PERFIL, normalizaPerfil, normalizaNome};
  if(typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.OBRA_CADASTRO = api;
})(typeof window !== 'undefined' ? window : globalThis);
```

Note: a regra de 128 é checada depois das outras de propósito — o checklist mostra as 5 regras visíveis; o teto é raro e só vira mensagem.

- [ ] **Step 4: Register the file** — `sw.js` ASSETS (+ `'./cadastro.js'` após `'./dados.js'`), `index.html` (`<script defer src="cadastro.js"></script>` antes de `auth.js`), `package.json` `test:unit` (+ `tests/cadastro.test.cjs` após `tests/dados.test.cjs`).

- [ ] **Step 5: Run tests**

Run: `node --test tests/cadastro.test.cjs && npm run test:unit`
Expected: PASS (inclui `pwa.test.cjs` e `build-www.test.mjs`, que conferem ASSETS × index).

- [ ] **Step 6: Commit**

```bash
git add cadastro.js tests/cadastro.test.cjs sw.js index.html package.json
git commit -m "feat: regras de senha e perfil do cadastro em cadastro.js"
```

---

### Task 2: `firestore.rules` aceita nome, sobrenome e origem

**Files:**
- Modify: `firestore.rules` (bloco `match /perfis/{uid}`)
- Modify: `tests/rules.test.mjs` (novo `describe` após `'perfis/{uid} — CPF e plano'`)

**Interfaces:**
- Consumes: lista de origens e limites da Global Constraints (não importa `cadastro.js`: rules não importam JS).
- Produces: perfil aceita chaves `nome`, `sobrenome`, `origem`, `origemDetalhe` no create; `nome`, `sobrenome` no update.

- [ ] **Step 1: Write the failing tests** — em `tests/rules.test.mjs`, após o describe existente de perfis:

```js
describe('perfis/{uid} — nome e origem', () => {
  const base = { email: ANA.email, criado: '2026-09-22T00:00:00.000Z', tz: 'America/Sao_Paulo' };

  test('perfil antigo, sem campos novos, continua aceito', async () => {
    await assertSucceeds(setDoc(doc(comoAna(), 'perfis', ANA.uid), base));
  });

  test('cadastro completo é aceito', async () => {
    await assertSucceeds(setDoc(doc(comoAna(), 'perfis', ANA.uid), {
      ...base, nome: 'Ana', sobrenome: 'Lima', origem: 'indicacao', origemDetalhe: 'Seu João',
    }));
  });

  for (const origem of ['instagram', 'indicacao', 'google', 'tiktok', 'youtube', 'outro']) {
    test(`origem ${origem} é aceita`, async () => {
      await assertSucceeds(setDoc(doc(comoAna(), 'perfis', ANA.uid), { ...base, nome: 'Ana', origem }));
    });
  }

  test('origem fora da lista é rejeitada', async () => {
    await assertFails(setDoc(doc(comoAna(), 'perfis', ANA.uid), { ...base, nome: 'Ana', origem: 'orkut' }));
  });

  test('nome vazio, longo ou com tipo errado é rejeitado', async () => {
    for (const nome of ['', 'A'.repeat(61), 42, { x: 1 }])
      await assertFails(setDoc(doc(comoAna(), 'perfis', ANA.uid), { ...base, nome }));
  });

  test('sobrenome e detalhe acima de 80 são rejeitados', async () => {
    await assertFails(setDoc(doc(comoAna(), 'perfis', ANA.uid), { ...base, nome: 'Ana', sobrenome: 'L'.repeat(81) }));
    await assertFails(setDoc(doc(comoAna(), 'perfis', ANA.uid), { ...base, nome: 'Ana', origem: 'outro', origemDetalhe: 'x'.repeat(81) }));
  });

  test('chave desconhecida continua rejeitada', async () => {
    await assertFails(setDoc(doc(comoAna(), 'perfis', ANA.uid), { ...base, nome: 'Ana', telefone: '11999999999' }));
  });

  test('cliente edita nome e sobrenome depois', async () => {
    await semeia(db => setDoc(doc(db, 'perfis', ANA.uid), base));
    await assertSucceeds(updateDoc(doc(comoAna(), 'perfis', ANA.uid), { nome: 'Ana', sobrenome: 'Lima' }));
  });

  test('cliente NÃO muda a origem depois do cadastro', async () => {
    await semeia(db => setDoc(doc(db, 'perfis', ANA.uid), { ...base, nome: 'Ana', origem: 'google' }));
    await assertFails(updateDoc(doc(comoAna(), 'perfis', ANA.uid), { origem: 'instagram' }));
    await assertFails(updateDoc(doc(comoAna(), 'perfis', ANA.uid), { origemDetalhe: 'x' }));
  });
});
```

- [ ] **Step 2: Run to verify it fails**

Run: `npm run test:rules`
Expected: FAIL — "cadastro completo é aceito" e "cliente edita nome" falham (hasOnly atual).

- [ ] **Step 3: Implement** — em `firestore.rules`, trocar o bloco `perfis`:

```
    /* perfis/{uid} — e-mail, fuso, nome e como a pessoa conheceu o Custta.
       'cpf' é rejeitado estruturalmente: hasOnly não o inclui.
       'plano' é DELIBERADAMENTE não-gravável pelo cliente — só o Admin SDK escreve.
       'origem' é gravada uma vez no cadastro; o cliente não a altera depois.
       Limites e lista de origens espelham cadastro.js: mudou lá, muda aqui. */
    match /perfis/{uid} {
      allow get:    if meu(uid);
      allow list:   if false;
      allow create: if meu(uid)
                    && request.resource.data.keys().hasOnly(
                         ['email', 'criado', 'tz', 'nome', 'sobrenome', 'origem', 'origemDetalhe'])
                    && perfilClienteOk();
      allow update: if meu(uid)
                    && resource != null
                    && request.resource.data.diff(resource.data)
                         .affectedKeys().hasOnly(['email', 'tz', 'nome', 'sobrenome'])
                    && perfilClienteOk();
      allow delete: if meu(uid);

      function textoAte(d, campo, max) {
        return !(campo in d) || (d[campo] is string && d[campo].size() <= max);
      }

      function perfilClienteOk() {
        let d = request.resource.data;
        return d.email is string
            && d.email == request.auth.token.email
            && d.email.size() <= 320
            && d.criado is string
            && d.criado.size() <= 40
            && (!('tz' in d) || (d.tz is string && d.tz.size() <= 64))
            && (!('nome' in d) || (d.nome is string && d.nome.size() >= 1 && d.nome.size() <= 60))
            && textoAte(d, 'sobrenome', 80)
            && (!('origem' in d) || d.origem in ['instagram', 'indicacao', 'google', 'tiktok', 'youtube', 'outro'])
            && textoAte(d, 'origemDetalhe', 80);
      }
    }
```

- [ ] **Step 4: Run tests**

Run: `npm run test:rules`
Expected: PASS — todos, inclusive os antigos de CPF/plano/tz.

- [ ] **Step 5: Commit**

```bash
git add firestore.rules tests/rules.test.mjs
git commit -m "feat(rules): perfil aceita nome, sobrenome e origem do cadastro"
```

---

### Task 3: Política de privacidade cita os dados novos

**Files:**
- Modify: `privacidade.html` (lista de dados coletados, ~linha 20; linha "Versão vigente")
- Modify: `tests/privacidade.test.cjs`

- [ ] **Step 1: Write the failing test** — em `tests/privacidade.test.cjs`, trocar `17 de setembro de 2026` por `22 de setembro de 2026` no teste existente e acrescentar:

```js
test('política lista nome e como a pessoa conheceu o Custta, com finalidade', ()=>{
  const politica = ler('privacidade.html');
  assert.match(politica, /nome e, se informado, sobrenome/);
  assert.match(politica, /como conheceu o Custta/);
  assert.match(politica, /entender por quais canais o Custta é conhecido/);
});
```

- [ ] **Step 2: Run to verify it fails**

Run: `node --test tests/privacidade.test.cjs`
Expected: FAIL (data e textos novos ausentes).

- [ ] **Step 3: Implement** — em `privacidade.html`, logo após `<li>endereço de e-mail usado para criar e acessar a conta;</li>`, acrescentar:

```html
    <li>nome e, se informado, sobrenome, para identificar a conta dentro do aplicativo;</li>
    <li>como conheceu o Custta (por exemplo Instagram ou indicação, com o nome de quem indicou quando informado), para entender por quais canais o Custta é conhecido;</li>
```

E trocar `<strong>Versão vigente:</strong> 17 de setembro de 2026.` por `<strong>Versão vigente:</strong> 22 de setembro de 2026.`

- [ ] **Step 4: Run tests**

Run: `node --test tests/privacidade.test.cjs`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add privacidade.html tests/privacidade.test.cjs
git commit -m "docs(privacidade): declarar nome e origem coletados no cadastro"
```

---

### Task 4: `cloud.js` grava, lê e edita o perfil; troca de senha usa a regra nova

**Files:**
- Modify: `cloud.js` (imports ~linha 11-15; `signup` ~262-270; `trocarSenha` ~287-291; novos `lerPerfil`, `salvarNome` no objeto `window.CLOUD`)
- Modify: `tests/helpers/firebase-stub.mjs` (exportar `getDoc`, `updateDoc`)
- Modify: `tests/conta.test.mjs`

**Interfaces:**
- Consumes: `window.OBRA_CADASTRO.validaSenha(senha, email)` (Task 1).
- Produces:
  - `CLOUD.signup(email, senha, perfil = {})` → grava `perfis/{uid}` = `{email, criado, tz, ...perfil}`.
  - `CLOUD.lerPerfil()` → `Promise<{nome?:string, sobrenome?:string} | null>`; nunca rejeita.
  - `CLOUD.salvarNome(nome, sobrenome)` → `Promise<void>`; sobrenome vazio remove o campo.
  - `CLOUD.trocarSenha(atual, nova)` rejeita `{code:'auth/weak-password', message:<erro da regra>}` sem reautenticar.

- [ ] **Step 1: Extend the stub** — em `tests/helpers/firebase-stub.mjs`, adicionar ao `__ctrl` o campo `perfil: null` e as funções:

```js
export function getDoc(ref){
  __ctrl.passos.push('get:'+ref.path);
  if(__ctrl.falhas.get) return Promise.reject(__ctrl.falhas.get);
  const dados = __ctrl.perfil;
  return Promise.resolve({ exists:()=>dados!==null, data:()=>dados });
}
export function updateDoc(ref, dados){
  __ctrl.passos.push('update:'+ref.path);
  __ctrl.updateDocChamadas = [...(__ctrl.updateDocChamadas||[]), { ref, dados }];
  return __ctrl.falhas.update ? Promise.reject(__ctrl.falhas.update) : Promise.resolve();
}
```

- [ ] **Step 2: Write the failing tests** — em `tests/conta.test.mjs`: no `beforeEach`, acrescentar `OBRA_CADASTRO:require('../cadastro.js'),` ao objeto `globalThis.window`, e `ctrl.perfil=null; ctrl.updateDocChamadas=[];` ao reset. Trocar o teste `'troca de senha exige reautenticação e rejeita senha curta'` por:

```js
test('troca de senha aplica a regra nova antes de reautenticar',async()=>{
  await assert.rejects(cloud.trocarSenha('atual','123'),{code:'auth/weak-password',message:'Use pelo menos 8 caracteres.'});
  await assert.rejects(cloud.trocarSenha('atual','abcdefghij'),{code:'auth/weak-password',message:'Inclua pelo menos um número.'});
  assert.deepEqual(ctrl.passos,[]);
  await cloud.trocarSenha('atual','Nova-segura1');
  assert.deepEqual(ctrl.passos,['reauth','senha']);
});
test('cadastro grava perfil com nome e origem junto do e-mail e fuso',async()=>{
  ctrl.setDocChamadas=[];
  await cloud.signup('ana@exemplo.com','Obra2026x',{nome:'Ana',origem:'instagram'});
  const perfil=ctrl.setDocChamadas.find(c=>c.ref.path==='perfis/u-teste');
  assert.equal(perfil.dados.nome,'Ana'); assert.equal(perfil.dados.origem,'instagram');
  assert.ok(perfil.dados.tz); assert.ok(perfil.dados.criado);
});
test('lerPerfil devolve nome e sobrenome, e null quando falta ou falha',async()=>{
  ctrl.perfil={email:'x',nome:'Ana',sobrenome:'Lima',origem:'google'};
  assert.deepEqual(await cloud.lerPerfil(),{nome:'Ana',sobrenome:'Lima'});
  ctrl.perfil=null; assert.equal(await cloud.lerPerfil(),null);
  ctrl.falhas.get={code:'unavailable'}; assert.equal(await cloud.lerPerfil(),null);
});
test('salvarNome atualiza e remove sobrenome vazio',async()=>{
  await cloud.salvarNome('Ana','Lima');
  await cloud.salvarNome('Ana','');
  assert.deepEqual(ctrl.updateDocChamadas.map(c=>c.dados),[{nome:'Ana',sobrenome:'Lima'},{nome:'Ana',sobrenome:'@del'}]);
});
```

- [ ] **Step 3: Run to verify it fails**

Run: `node --test tests/conta.test.mjs`
Expected: FAIL — `lerPerfil is not a function` e regra de 8.

- [ ] **Step 4: Implement** — em `cloud.js`:

1. Import de firestore: acrescentar `getDoc, updateDoc,` à lista (ex.: após `doc, setDoc,`).
2. Substituir o comentário + `signup`:

```js
  /* perfis/{uid} guarda só o mínimo. Nada de CPF: o app nunca leu de volta,
     e dado pessoal que não se usa é só responsabilidade sob a LGPD.
     O perfil (nome, sobrenome, origem) chega já normalizado por OBRA_CADASTRO;
     as rules são a fronteira e rejeitam qualquer chave fora da lista. */
  async signup(email, senha, perfil = {}){
    if(cacheBloqueado) throw Object.assign(new Error('Limpe os dados locais antes de entrar.'), { code:'cache' });
    const cred = await createUserWithEmailAndPassword(auth, email, senha);
    await setDoc(doc(db, 'perfis', cred.user.uid),
      { email:cred.user.email ?? email, criado: new Date().toISOString(), tz:Intl.DateTimeFormat().resolvedOptions().timeZone || 'America/Sao_Paulo', ...perfil });
  },
  async lerPerfil(){
    const u = auth.currentUser;
    if(!u) return null;
    try{
      const snap = await getDoc(doc(db, 'perfis', u.uid));
      if(!snap.exists()) return null;
      const { nome, sobrenome } = snap.data();
      const r = {};
      if(typeof nome === 'string' && nome) r.nome = nome;
      if(typeof sobrenome === 'string' && sobrenome) r.sobrenome = sobrenome;
      return r;
    }catch{ return null; }
  },
  async salvarNome(nome, sobrenome){
    const u = auth.currentUser;
    if(!u) throw Object.assign(new Error('Entre na conta.'), { code:'offline' });
    await updateDoc(doc(db, 'perfis', u.uid), { nome, sobrenome: sobrenome ? sobrenome : deleteField() });
  },
```

   (O stub de `createUserWithEmailAndPassword` devolve `user` sem e-mail — daí o `?? email`.)

3. Substituir a primeira linha de `trocarSenha`:

```js
  async trocarSenha(atual, nova){
    const regra = window.OBRA_CADASTRO.validaSenha(nova, auth.currentUser?.email);
    if(!regra.ok) throw Object.assign(new Error(regra.erro), { code:'auth/weak-password' });
    const u = await reautenticar(atual);
    await updatePassword(u, nova);
  },
```

- [ ] **Step 5: Run tests**

Run: `node --test tests/conta.test.mjs && npm run test:unit`
Expected: PASS (atenção a `fila.test.mjs`, `push-cloud.test.mjs`, `cloud-nativo.test.mjs`, que também importam `cloud.js` com o stub — o import novo precisa existir no stub, feito no Step 1).

- [ ] **Step 6: Commit**

```bash
git add cloud.js tests/helpers/firebase-stub.mjs tests/conta.test.mjs
git commit -m "feat(cloud): gravar e editar nome do perfil; troca de senha com regra nova"
```

---

### Task 5: Formulário de cadastro novo (`index.html` + `auth.js` + `styles.css`)

**Files:**
- Modify: `index.html` (`<form id="fCad">`, linhas ~91-101)
- Modify: `auth.js` (tabs/limpeza em `locked`, `msgErro`, handler de `#fCad`; novo checklist)
- Modify: `styles.css` (classes novas no fim do bloco de auth / `.field`)

**Interfaces:**
- Consumes: `OBRA_CADASTRO.validaSenha`, `OBRA_CADASTRO.normalizaPerfil`, `OBRA_CADASTRO.ORIGENS` (Task 1); `CLOUD.signup(email, senha, perfil)` (Task 4).
- Produces: IDs usados pelos testes de browser (Task 7): `#cNome`, `#cSobrenome`, `#cEmail`, `#cSenha`, `#cSenha2`, `#cRegras` (com `li[data-regra="<id>"]` e classe `ok`), `#cOrigem`, `#cDetalheWrap` (classe `hidden` quando escondido), `#cDetalheLabel`, `#cDetalhe`, `#cMsg`. Também exporta `window.OBRA_CHECKLIST = { montar(ul), atualizar(ul, senha, email) }` para Task 6.

- [ ] **Step 1: Markup** — substituir o `<form id="fCad">…</form>` inteiro por:

```html
          <form id="fCad" class="hidden" novalidate>
            <div class="field"><label for="cNome">Nome</label>
              <input id="cNome" type="text" autocomplete="given-name" autocapitalize="words" maxlength="60" placeholder="Seu nome"></div>
            <div class="field"><label for="cSobrenome">Sobrenome <span class="opcional">(opcional)</span></label>
              <input id="cSobrenome" type="text" autocomplete="family-name" autocapitalize="words" maxlength="80" placeholder="Seu sobrenome"></div>
            <div class="field"><label for="cEmail">E-mail</label>
              <input id="cEmail" type="email" autocomplete="email" placeholder="voce@email.com"></div>
            <div class="field"><label for="cSenha">Senha</label>
              <div class="pw-wrap">
                <input id="cSenha" type="password" autocomplete="new-password" maxlength="128" aria-describedby="cRegras"
                  passwordrules="minlength: 8; required: digit; required: lower, upper;" placeholder="Crie uma senha">
                <button type="button" class="pw-eye" data-eye="cSenha" data-ico="olho" aria-label="Mostrar senha"></button>
              </div>
              <ul class="senha-regras" id="cRegras" aria-live="polite"></ul></div>
            <div class="field"><label for="cSenha2">Confirmar senha</label>
              <div class="pw-wrap">
                <input id="cSenha2" type="password" autocomplete="new-password" maxlength="128" placeholder="Repita a senha">
                <button type="button" class="pw-eye" data-eye="cSenha2" data-ico="olho" aria-label="Mostrar senha"></button>
              </div></div>
            <div class="field"><label for="cOrigem">Como conheceu o Custta?</label>
              <select id="cOrigem"><option value="">Escolha uma opção</option></select></div>
            <div class="field hidden" id="cDetalheWrap"><label for="cDetalhe" id="cDetalheLabel"></label>
              <input id="cDetalhe" type="text" maxlength="80" autocapitalize="words"></div>
            <div class="auth-msg" id="cMsg" role="alert"></div>
            <button class="layout-19 btn primary" type="submit">Criar conta</button>
          </form>
```

- [ ] **Step 2: CSS** — em `styles.css`, logo após a regra `.field input:focus,.field select:focus{...}` (linha ~266):

```css
  .field .opcional{color:var(--faint);font-weight:400}
  .field input[aria-invalid="true"],.field select[aria-invalid="true"]{border-color:var(--amber)}
  .senha-regras{list-style:none;padding:0;margin:8px 2px 0;display:grid;grid-template-columns:1fr 1fr;gap:4px 12px;font-size:13px;color:var(--muted)}
  .senha-regras li{display:flex;align-items:center;gap:6px;min-height:20px}
  .senha-regras li::before{content:"";width:14px;height:14px;flex:none;border-radius:50%;border:1.5px solid var(--line-strong)}
  .senha-regras li.ok{color:var(--text)}
  .senha-regras li.ok::before{border-color:var(--brand);background:var(--brand) url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Cpath d='M4 8.5l2.5 2.5L12 5.5' fill='none' stroke='%2304100C' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E") center/12px no-repeat}
  @media (max-width:360px){.senha-regras{grid-template-columns:1fr}}
```

Verificar: `vercel.json` CSP tem `img-src` que aceite `data:`. Se não aceitar, trocar o `::before` do `.ok` por um `content:"✓"` centralizado (sem `url()`), mantendo cor `var(--btn-ink)` sobre `var(--brand)`.

- [ ] **Step 3: `auth.js` — checklist reutilizável, origens, validação**

Após a seção "olho de mostrar senha", acrescentar:

```js
  /* ---------- checklist de senha (também usado no Trocar senha, via OBRA_CHECKLIST) ---------- */
  const CHECKLIST = {
    montar(ul){
      ul.innerHTML = OBRA_CADASTRO.REGRAS_SENHA
        .map(r=>`<li data-regra="${r.id}">${r.texto}</li>`).join('');
    },
    atualizar(ul, senha, email){
      const {regras} = OBRA_CADASTRO.validaSenha(senha, email);
      for(const r of regras) ul.querySelector(`[data-regra="${r.id}"]`)?.classList.toggle('ok', r.ok);
    },
  };
  window.OBRA_CHECKLIST = CHECKLIST;
  const regrasCad = $('#cRegras');
  CHECKLIST.montar(regrasCad);
  const atualizaRegras = ()=>CHECKLIST.atualizar(regrasCad, $('#cSenha').value, $('#cEmail').value);
  $('#cSenha').addEventListener('input', atualizaRegras);
  $('#cEmail').addEventListener('input', atualizaRegras);

  /* ---------- como conheceu ---------- */
  const selOrigem = $('#cOrigem');
  for(const o of OBRA_CADASTRO.ORIGENS){
    const op = document.createElement('option'); op.value = o.id; op.textContent = o.nome; selOrigem.append(op);
  }
  function mostraDetalhe(){
    const o = OBRA_CADASTRO.ORIGENS.find(x=>x.id===selOrigem.value);
    $('#cDetalheWrap').classList.toggle('hidden', !o?.detalhe);
    $('#cDetalheLabel').textContent = o?.detalhe || '';
    if(!o?.detalhe) $('#cDetalhe').value = '';
  }
  selOrigem.addEventListener('change', mostraDetalhe);
```

Em `locked(on)`, no ramo `if(on){...}`, limpar também `$('#cSenha2').value=''` e chamar `atualizaRegras()` — como `locked` roda antes da definição, mover a limpeza para uma função `limpaSenhas()` declarada com `function` (hoisting) no fim do arquivo:

```js
  function limpaSenhas(){
    for(const id of ['lSenha','cSenha','cSenha2']) document.getElementById(id).value='';
    const ul=document.getElementById('cRegras'); if(ul && ul.children.length) CHECKLIST.atualizar(ul,'','');
  }
```

e em `locked`: `if(on){ mostrarAba('login'); limpaSenhas(); }`. (`CHECKLIST` é `const` e só é lido quando `ul.children.length` > 0, o que só acontece depois de `montar` — sem TDZ na primeira chamada.)

Em `msgErro`: `if(c.includes('weak-password')) return 'Senha fraca: use 8 caracteres ou mais, com letra e número.';`

Substituir o handler de `#fCad` por:

```js
  /* ---------- cadastro ---------- */
  const CAMPO_ID = {nome:'cNome', sobrenome:'cSobrenome', origem:'cOrigem', origemDetalhe:'cDetalhe'};
  function marca(id, msg){
    const msgEl=$('#cMsg'); msgEl.textContent=msg;
    const el=document.getElementById(id); el.setAttribute('aria-invalid','true'); el.focus();
  }
  $('#fCad').addEventListener('input', e=>e.target.removeAttribute?.('aria-invalid'));
  $('#fCad').addEventListener('change', e=>e.target.removeAttribute?.('aria-invalid'));
  $('#fCad').addEventListener('submit',async e=>{
    e.preventDefault();
    const msg=$('#cMsg'); msg.textContent='';
    const perfil = OBRA_CADASTRO.normalizaPerfil({
      nome:$('#cNome').value, sobrenome:$('#cSobrenome').value,
      origem:$('#cOrigem').value, origemDetalhe:$('#cDetalhe').value,
    });
    const email=$('#cEmail').value.trim(), senha=$('#cSenha').value, senha2=$('#cSenha2').value;
    if(!perfil.ok && (perfil.campo==='nome' || perfil.campo==='sobrenome')) return marca(CAMPO_ID[perfil.campo], perfil.erro);
    if(!/^\S+@\S+\.\S+$/.test(email)) return marca('cEmail','E-mail inválido.');
    const regra = OBRA_CADASTRO.validaSenha(senha, email);
    if(!regra.ok) return marca('cSenha', regra.erro);
    if(senha2 !== senha) return marca('cSenha2','As senhas não são iguais.');
    if(!perfil.ok) return marca(CAMPO_ID[perfil.campo], perfil.erro);
    await comLoading(e.target.querySelector('button[type=submit]'), 'Criando conta…', async()=>{
      try{ await CLOUD.signup(email, senha, perfil.perfil); }
      catch(err){ msg.textContent=msgErro(err); }
    });
  });
```

(Ordem de validação = ordem visual: nome → sobrenome → e-mail → senha → confirmação → origem → detalhe.)

- [ ] **Step 4: Unit + CSP check**

Run: `npm run test:unit`
Expected: PASS (`headers.test.cjs`/`xss.test.cjs` checam ausência de inline).

- [ ] **Step 5: Smoke manual rápido** — `node tests/browser/servidor.cjs &` e abrir `http://localhost:8123` com `agent-browser` (viewport 390×844): aba "Criar conta" mostra os campos na ordem, checklist marca ao digitar `Obra2026x`, "Indicação" mostra "Quem indicou?". Encerrar o servidor.

- [ ] **Step 6: Commit**

```bash
git add index.html auth.js styles.css
git commit -m "feat(auth): cadastro com nome, origem, confirmação e checklist de senha"
```

---

### Task 6: Ajustes mostra/edita o nome; Trocar senha com confirmação e checklist

**Files:**
- Modify: `index.html` (painel "Conta" em Ajustes, ~linha 256-257)
- Modify: `app.js` (`renderAjustes`, ~linha 1365)
- Modify: `ui-confirm.js` (`mensagem`, `abrir`)
- Modify: `styles.css` (se precisar: `.conta-nome`)

**Interfaces:**
- Consumes: `CLOUD.lerPerfil()`, `CLOUD.salvarNome(nome, sobrenome)` (Task 4); `OBRA_CADASTRO.normalizaNome`, `OBRA_CADASTRO.validaSenha` (Task 1); `window.OBRA_CHECKLIST` (Task 5).
- Produces: `#ajNome` (texto do nome), `#ajNomeEditar` (botão: "Editar nome" ou "Adicionar nome"); dialog `abrir('nome')` com `#contaNome`, `#contaSobrenome`, `#contaEnviar`, `#contaMensagem`; dialog de senha com `#contaSenha` (atual), `#contaConfirmacao` (nova), `#contaNova2` (repetir), `#contaRegras`. Evento `window` `'perfil-alterado'` disparado após salvar o nome.

- [ ] **Step 1: Markup** — no painel Conta de `index.html`, trocar `<p id="ajEmail" class="muted-note"></p>` por:

```html
      <p id="ajNome" class="conta-nome hidden"></p>
      <p id="ajEmail" class="muted-note"></p>
```

e, dentro de `<div class="sheet-actions">` do painel Conta, acrescentar como **primeiro** botão:

```html
        <button class="btn ghost" id="ajNomeEditar">Adicionar nome</button>
```

CSS em `styles.css` (perto de `.muted-note`): `.conta-nome{font-size:18px;font-weight:650;margin:0 0 2px}`

- [ ] **Step 2: `app.js`** — em `renderAjustes`, após `$('#ajEmail').textContent = …`:

```js
  $('#ajNomeEditar').onclick = ()=>OBRA_CONTA.abrir('nome', perfilAjustes.dados);
  carregaPerfilAjustes(conta);
```

e, logo antes de `function renderAjustes(){` (a `const perfilAjustes` vai **no topo do `app.js`**, junto das outras variáveis de estado, para não cair em TDZ se `renderAjustes` rodar cedo; as funções podem ficar aqui):

```js
/* Nome vem de perfis/{uid}; lido uma vez por conta e relido quando o dialog salva. */
const perfilAjustes = { uid:null, dados:null };
function pintaNome(){
  const d = perfilAjustes.dados, nome = [d?.nome, d?.sobrenome].filter(Boolean).join(' ');
  $('#ajNome').textContent = nome;
  $('#ajNome').classList.toggle('hidden', !nome);
  $('#ajNomeEditar').textContent = nome ? 'Editar nome' : 'Adicionar nome';
}
async function carregaPerfilAjustes(conta, forcar){
  if(!conta){ perfilAjustes.uid=null; perfilAjustes.dados=null; pintaNome(); return; }
  if(perfilAjustes.uid === conta.uid && !forcar){ pintaNome(); return; }
  perfilAjustes.uid = conta.uid;
  const dados = await window.CLOUD.lerPerfil();
  if(perfilAjustes.uid !== conta.uid) return; // trocou de conta no meio
  perfilAjustes.dados = dados; pintaNome();
}
window.addEventListener('perfil-alterado', ()=>carregaPerfilAjustes(window.CLOUD?.user(), true));
```

- [ ] **Step 3: `ui-confirm.js`**

Em `mensagem(err)`: trocar a linha de `weak-password` por
`if(err.code === 'auth/weak-password') return err.message || 'Senha fraca: use 8 caracteres ou mais, com letra e número.';`

Trocar a assinatura `function abrir(tipo){` por `function abrir(tipo, dados){` e, logo após `if(aberto) return;`, desviar o tipo nome:

```js
    if(tipo === 'nome') return abrirNome(dados);
```

No template do dialog de senha, substituir o segundo `.field` (o de `contaConfirmacao`) quando **não** for `apagar` por nova senha + checklist + repetir. Concretamente, trocar a linha do segundo field por:

```js
      ${apagar
        ? `<div class="field"><label for="contaConfirmacao">Digite APAGAR para confirmar</label>
             <input id="contaConfirmacao" type="text" autocomplete="off" required></div>`
        : `<div class="field"><label for="contaConfirmacao">Nova senha</label>
             <input id="contaConfirmacao" type="password" autocomplete="new-password" maxlength="128" required aria-describedby="contaRegras"
               passwordrules="minlength: 8; required: digit; required: lower, upper;">
             <ul class="senha-regras" id="contaRegras" aria-live="polite"></ul></div>
           <div class="field"><label for="contaNova2">Repetir nova senha</label>
             <input id="contaNova2" type="password" autocomplete="new-password" maxlength="128" required></div>`}
```

Depois de `dialogo.showModal();` (e antes do `focus`), ligar o checklist:

```js
    if(!apagar){
      const ul = dialogo.querySelector('#contaRegras'), nova = dialogo.querySelector('#contaConfirmacao');
      OBRA_CHECKLIST.montar(ul);
      nova.addEventListener('input', ()=>OBRA_CHECKLIST.atualizar(ul, nova.value, CLOUD.user()?.email));
    }
```

No `onsubmit`, após a checagem de `APAGAR`, acrescentar:

```js
      if(!apagar){
        const regra = OBRA_CADASTRO.validaSenha(confirmacao.value, CLOUD.user()?.email);
        if(!regra.ok){ msg.textContent = regra.erro; return; }
        if(dialogo.querySelector('#contaNova2').value !== confirmacao.value){ msg.textContent = 'As senhas novas não são iguais.'; return; }
      }
```

e, onde limpa os campos (`senha.value = ''; if(!apagar) confirmacao.value = '';`), limpar também `#contaNova2` quando `!apagar`.

Nova função no mesmo IIFE, antes de `function mostrarCache(){`:

```js
  function abrirNome(dados){
    const dialogo = document.createElement('dialog');
    dialogo.className = 'conta-dialog';
    dialogo.setAttribute('aria-labelledby','contaTitulo');
    dialogo.innerHTML = `<form>
      <h2 id="contaTitulo">Seu nome</h2>
      <div class="field"><label for="contaNome">Nome</label><input id="contaNome" type="text" autocomplete="given-name" maxlength="60" required></div>
      <div class="field"><label for="contaSobrenome">Sobrenome <span class="opcional">(opcional)</span></label><input id="contaSobrenome" type="text" autocomplete="family-name" maxlength="80"></div>
      <p id="contaMensagem" role="status" aria-live="polite"></p>
      <div class="sheet-actions"><button type="button" class="btn ghost" id="contaCancelar">Cancelar</button>
      <button type="submit" class="btn" id="contaEnviar">Salvar</button></div>
    </form>`;
    dialogo.querySelector('#contaNome').value = dados?.nome || '';
    dialogo.querySelector('#contaSobrenome').value = dados?.sobrenome || '';
    let trabalhando = false;
    function fechar(){ dialogo.close(); dialogo.remove(); aberto = null; }
    aberto = { fechar };
    document.body.append(dialogo); dialogo.showModal();
    dialogo.querySelector('#contaNome').focus();
    dialogo.addEventListener('cancel', e=>{ if(trabalhando) e.preventDefault(); });
    dialogo.addEventListener('close', ()=>{ dialogo.remove(); aberto = null; });
    dialogo.querySelector('#contaCancelar').onclick = fechar;
    dialogo.querySelector('form').onsubmit = async e=>{
      e.preventDefault(); if(trabalhando) return;
      const msg = dialogo.querySelector('#contaMensagem');
      const r = OBRA_CADASTRO.normalizaNome({ nome:dialogo.querySelector('#contaNome').value, sobrenome:dialogo.querySelector('#contaSobrenome').value });
      if(!r.ok){ msg.textContent = r.erro; dialogo.querySelector(r.campo==='nome'?'#contaNome':'#contaSobrenome').focus(); return; }
      trabalhando = true;
      dialogo.querySelectorAll('input,button').forEach(el=>el.disabled=true);
      msg.textContent = 'Salvando…';
      try{
        await CLOUD.salvarNome(r.perfil.nome, r.perfil.sobrenome || '');
        fechar(); toast('Nome salvo.');
        window.dispatchEvent(new Event('perfil-alterado'));
      }catch(err){ msg.textContent = mensagem(err); }
      finally{ trabalhando = false; dialogo.querySelectorAll('input,button').forEach(el=>el.disabled=false); }
    };
  }
```

- [ ] **Step 4: Atualizar a suíte de browser existente** — `tests/browser/fase2.cjs`, nos dois pontos que preenchem `#contaConfirmacao` com `'Nova-local-456!'`, acrescentar logo depois `await page.locator('#contaNova2').fill('Nova-local-456!');`.

- [ ] **Step 5: Run**

Run: `npm run test:unit`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add index.html app.js ui-confirm.js styles.css tests/browser/fase2.cjs
git commit -m "feat(ajustes): mostrar e editar nome; trocar senha com confirmação e checklist"
```

---

### Task 7: Suíte de browser do cadastro + validação com agent-browser

**Files:**
- Create: `tests/browser/cadastro.cjs`
- Modify: `tests/browser/rodar.cjs` (rodar `tests/browser/cadastro.cjs` logo após `fase2.cjs`)

**Interfaces:**
- Consumes: todos os IDs das Tasks 5 e 6; `perfis/{uid}` no emulador.

- [ ] **Step 1: Write the suite** — `tests/browser/cadastro.cjs` (mesmo cabeçalho/infra de `fase2.cjs`: rota do `cloud.js` apontando para emuladores, `serviceWorkers:'block'`, `splashVista`, registro de violação de CSP):

```js
/* Cadastro completo pela UI, Auth e Firestore reais nos emuladores locais.
   firebase emulators:exec --config firebase.test.json --project demo-custta-phase2
     --only firestore,auth "node tests/browser/cadastro.cjs" */
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('playwright');
const {initializeTestEnvironment}=require('@firebase/rules-unit-testing');
const {doc,getDoc,setDoc}=require('firebase/firestore');
const PROJECT='demo-custta-phase2';
const ROOT=path.resolve(__dirname,'../..');
const cloudEmulado=()=>fs.readFileSync(path.join(ROOT,'cloud.js'),'utf8')
  .replace("projectId: 'app-construcao-civil'",`projectId: '${PROJECT}'`)
  .replace('sendPasswordResetEmail, signOut,','sendPasswordResetEmail, signOut, connectAuthEmulator,')
  .replace('deleteField, waitForPendingWrites,','deleteField, waitForPendingWrites, connectFirestoreEmulator,')
  .replace('const auth = getAuth(app);',"const auth = getAuth(app); connectAuthEmulator(auth,'http://127.0.0.1:9099',{disableWarnings:true});")
  .replace('const CHAVE_LIMPEZA',"connectFirestoreEmulator(db,'127.0.0.1',8080);\nconst CHAVE_LIMPEZA");
(async()=>{
  const env=await initializeTestEnvironment({projectId:PROJECT,firestore:{host:'127.0.0.1',port:8080,rules:fs.readFileSync(path.join(ROOT,'firestore.rules'),'utf8')}});
  const browser=await chromium.launch();
  try{
    const context=await browser.newContext({serviceWorkers:'block',viewport:{width:390,height:844}});
    const violacoes=[];
    await context.exposeBinding('__registraCSP',(_s,info)=>violacoes.push(info));
    await context.addInitScript(()=>addEventListener('securitypolicyviolation',e=>window.__registraCSP(e.violatedDirective+': '+e.blockedURI)));
    const source=cloudEmulado();
    await context.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:source}));
    await context.addInitScript(()=>sessionStorage.setItem('splashVista','1'));
    const page=await context.newPage(); page.setDefaultTimeout(15000);
    const errosPagina=[]; page.on('pageerror',err=>errosPagina.push(err.message));
    await page.goto('http://localhost:8123'); await page.waitForFunction(()=>window.CLOUD);
    await page.locator('#authTabs button[data-k="cad"]').click();

    // checklist reage ao digitar
    const ok=()=>page.$$eval('#cRegras li.ok',l=>l.map(x=>x.dataset.regra));
    await page.locator('#cSenha').fill('abc');
    assert.deepEqual(await ok(),['letra','email','comum']);
    await page.locator('#cSenha').fill('Obra2026x');
    assert.deepEqual(await ok(),['tamanho','letra','numero','email','comum']);
    console.log('ok - checklist marca cada regra ao digitar');

    // ordem de validação: nome primeiro
    await page.locator('#fCad button[type=submit]').click();
    assert.equal(await page.textContent('#cMsg'),'Digite seu nome.');
    assert.equal(await page.evaluate(()=>document.activeElement.id),'cNome');
    await page.locator('#cNome').fill('  Ana  ');
    await page.locator('#cEmail').fill('cadastro@example.com');
    await page.locator('#cSenha').fill('senha123');
    await page.locator('#fCad button[type=submit]').click();
    assert.equal(await page.textContent('#cMsg'),'Essa senha é muito comum. Escolha outra.');
    await page.locator('#cSenha').fill('Obra2026x'); await page.locator('#cSenha2').fill('Obra2026y');
    await page.locator('#fCad button[type=submit]').click();
    assert.equal(await page.textContent('#cMsg'),'As senhas não são iguais.');
    await page.locator('#cSenha2').fill('Obra2026x');
    await page.locator('#fCad button[type=submit]').click();
    assert.equal(await page.textContent('#cMsg'),'Conte como conheceu o Custta.');
    console.log('ok - senha óbvia, confirmação diferente e origem vazia bloqueiam');

    // detalhe aparece só para indicação/outro e some ao trocar
    assert.equal(await page.locator('#cDetalheWrap').isVisible(),false);
    await page.selectOption('#cOrigem','indicacao');
    assert.equal(await page.textContent('#cDetalheLabel'),'Quem indicou? (opcional)');
    await page.locator('#cDetalhe').fill('Seu João');
    await page.selectOption('#cOrigem','instagram');
    assert.equal(await page.locator('#cDetalheWrap').isVisible(),false);
    await page.selectOption('#cOrigem','indicacao');
    assert.equal(await page.inputValue('#cDetalhe'),'');
    await page.locator('#cDetalhe').fill('Seu João');
    console.log('ok - detalhe da origem aparece, some e não vaza ao trocar');

    await page.locator('#fCad button[type=submit]').click();
    await page.waitForFunction(()=>CLOUD.user());
    const uid=await page.evaluate(()=>CLOUD.user().uid);
    const perfil=await env.withSecurityRulesDisabled(async ctx=>(await getDoc(doc(ctx.firestore(),'perfis',uid))).data());
    assert.equal(perfil.nome,'Ana'); assert.equal(perfil.sobrenome,undefined);
    assert.equal(perfil.origem,'indicacao'); assert.equal(perfil.origemDetalhe,'Seu João');
    assert.equal(perfil.email,'cadastro@example.com'); assert.ok(perfil.tz);
    console.log('ok - cadastro grava nome, origem e detalhe no perfil');

    // Ajustes mostra e edita o nome
    await page.evaluate(()=>showView('ajustes'));
    await page.waitForFunction(()=>document.getElementById('ajNome').textContent==='Ana');
    assert.equal(await page.textContent('#ajNomeEditar'),'Editar nome');
    await page.locator('#ajNomeEditar').click();
    assert.equal(await page.inputValue('#contaNome'),'Ana');
    await page.locator('#contaSobrenome').fill('Lima'); await page.locator('#contaEnviar').click();
    await page.waitForSelector('.conta-dialog',{state:'detached'});
    await page.waitForFunction(()=>document.getElementById('ajNome').textContent==='Ana Lima');
    const depois=await env.withSecurityRulesDisabled(async ctx=>(await getDoc(doc(ctx.firestore(),'perfis',uid))).data());
    assert.equal(depois.sobrenome,'Lima'); assert.equal(depois.origem,'indicacao');
    console.log('ok - Ajustes mostra o nome e a edição persiste');

    // troca de senha: checklist e repetição
    await page.locator('#ajSenha').click();
    await page.locator('#contaSenha').fill('Obra2026x');
    await page.locator('#contaConfirmacao').fill('curta1');
    await page.locator('#contaNova2').fill('curta1');
    await page.locator('#contaEnviar').click();
    assert.equal(await page.textContent('#contaMensagem'),'Use pelo menos 8 caracteres.');
    await page.locator('#contaConfirmacao').fill('Nova2026x'); await page.locator('#contaNova2').fill('Nova2026y');
    await page.locator('#contaEnviar').click();
    assert.equal(await page.textContent('#contaMensagem'),'As senhas novas não são iguais.');
    await page.locator('#contaNova2').fill('Nova2026x'); await page.locator('#contaEnviar').click();
    await page.waitForSelector('.conta-dialog',{state:'detached'});
    console.log('ok - trocar senha exige regra nova e repetição igual');

    // usuário antigo sem nome: Ajustes não quebra e oferece "Adicionar nome"
    await env.withSecurityRulesDisabled(ctx=>setDoc(doc(ctx.firestore(),'perfis',uid),{email:'cadastro@example.com',criado:'2026-01-01T00:00:00.000Z'}));
    await page.reload(); await page.waitForFunction(()=>CLOUD.user());
    await page.evaluate(()=>showView('ajustes'));
    await page.waitForFunction(()=>document.getElementById('ajNomeEditar').textContent==='Adicionar nome');
    assert.equal(await page.locator('#ajNome').isVisible(),false);
    console.log('ok - perfil antigo sem nome oferece "Adicionar nome"');

    assert.deepEqual(violacoes,[]); assert.deepEqual(errosPagina,[]);
    console.log('ok - nenhuma violação de CSP nem erro de página');
  }finally{ await browser.close(); await env.cleanup(); }
})().catch(e=>{console.error(e);process.exitCode=1;});
```

- [ ] **Step 2: Register** — em `tests/browser/rodar.cjs`, após `await run('tests/browser/fase2.cjs');` acrescentar `await run('tests/browser/cadastro.cjs');`.

- [ ] **Step 3: Run full suites**

Run: `npm test && npm run test:browser`
Expected: PASS em tudo (unit, rules, browser — incluindo `fase1`, `fase2` que usam `CLOUD.signup` com 2 argumentos).

- [ ] **Step 4: Validação manual com agent-browser** — subir emuladores + servidor (`firebase emulators:start --config firebase.test.json --project demo-custta-phase2 --only firestore,auth` e `CUSTTA_EMULADORES=1 node tests/browser/servidor.cjs`), abrir `http://localhost:8123` com `agent-browser` e, em 390×844 e 1280×800, dark e claro: capturar a aba "Criar conta" vazia, com checklist parcial, com erro, e Ajustes com nome. Conferir: sem corte de texto, alvos ≥ 44px, contraste do checklist legível, o efeito 3D do card não esconde o botão "Criar conta". Salvar capturas fora do repo.

- [ ] **Step 5: Commit**

```bash
git add tests/browser/cadastro.cjs tests/browser/rodar.cjs
git commit -m "test(browser): cadastro completo, edição de nome e troca de senha"
```

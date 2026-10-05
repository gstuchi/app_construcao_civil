# Blindagem do banco — Plano de implementação

> **Para quem executa:** SUB-SKILL OBRIGATÓRIA — use `superpowers:subagent-driven-development` para implementar tarefa a tarefa. Os passos usam checkbox (`- [ ]`).

**Goal:** Provar, no emulador e de fora na produção, que o Firestore do Custta não deixa um usuário ler, gravar ou apagar dado de outro, nem gravar campo ou formato proibido — e deixar essa prova repetível depois de cada publicação de regras.

**Architecture:** A segurança do banco mora em `firestore.rules`. Duas camadas de prova: (1) casos novos em `tests/rules.test.mjs` para os atalhos que ainda não tinham teste (consulta de grupo, subcoleção, id parecido, apagar/ler dado alheio); (2) uma **sonda** (`scripts/sonda-banco.mjs`) que, só com a `apiKey` pública, cria duas contas descartáveis `@example.com` na produção, tenta os ataques pela API REST do Firestore, exige controle positivo (o dono consegue o que é dele) para não dar falso verde, e apaga tudo no fim. A configuração da produção (publicar regras, proteção contra exclusão) é feita pelo `firebase` CLI, fora do código.

**Tech Stack:** Node 22+ (`fetch` nativo), `node:test`, `@firebase/rules-unit-testing` + emulador (Java 21), APIs REST públicas do Firebase Auth (Identity Toolkit, caminho de cliente com `?key=`) e do Firestore.

**Spec:** sem doc separado — auditoria de escopo fechado aprovada em conversa (02/10 a 05/10). Escopo final decidido em 05/10: restauração de usuário **fora** deste plano (fica com a restauração oficial do Firebase quando houver Blaze); PITR/backups dependem da decisão Spark × Blaze do Giovani.

## Global Constraints

- Repositório **público**: nenhuma senha, token ou chave privada em arquivo versionado. A única credencial permitida é a `apiKey` pública do `cloud.js` (lida de lá, não copiada).
- A sonda só usa o caminho de **cliente** (contas comuns com `idToken`); nada de credencial de administrador.
- Contas da sonda: e-mail `sonda-<papel>-<timestamp>-<aleatório>@example.com`, senha aleatória gerada na hora, nunca impressa nem gravada.
- A sonda só roda com `--producao` explícito; sem a flag, sai com código 2 sem tocar a rede.
- Saída da sonda: nunca imprime senha nem `idToken`.
- Código, comentários, identificadores e commits em **português**; commits com autor `Giovani Stuchi <stuchigiovani@gmail.com>`, **sem** `Co-Authored-By` e sem rodapé; título conventional com acento.
- Nenhum pacote novo (Node 22 tem `fetch`). Nenhum arquivo novo na raiz do app.
- Testes novos de unidade entram na lista explícita do `test:unit` no `package.json`.

## Review Focus

1. **Falso verde:** ler documento alheio que **não existe** com regra quebrada dá 404, não 200. → Os alvos de leitura do Bento precisam existir, e ataque de leitura só passa com **403 exato** (teste "404 onde se espera 403 reprova").
2. **Sem rede / token ruim:** tudo falha e parece "bloqueado". → Controles positivos (dono lê e grava o próprio) precisam passar, senão a sonda reprova (teste próprio).
3. **Limpeza falha no meio:** conta órfã em produção. → Limpeza em `finally`, roda mesmo se um ataque lançar; confirma pelo `accounts:lookup` que a conta sumiu; se sobrar, imprime os uids e sai com 1 (teste próprio).
4. **Segredo no terminal:** senha ou `idToken` no log. → Teste que captura a saída e procura os valores.
5. **Ataque que "passa" com 200 vazio** (consulta liberada que não acha nada). → Classificação só pelo status: qualquer 2xx em ataque = reprovado (teste próprio).

---

### Task 1: Casos de injeção nas regras (emulador)

**Files:**
- Modify: `tests/rules.test.mjs` (import + novo `describe` no fim)

- [ ] **Step 1: Acrescentar ao import de `firebase/firestore`** os nomes `collectionGroup, query, where, documentId` (manter os que já existem).

- [ ] **Step 2: Acrescentar no fim do arquivo:**

```js
describe('atalhos para dado alheio — injeção de caminho e de consulta', () => {
  test('consulta de grupo de coleções em dados é negada', async () => {
    await semeia(db => setDoc(doc(db, 'dados', BENTO.uid), blobOk()));
    await assertFails(getDocs(collectionGroup(comoAna(), 'dados')));
  });

  test('deslogado não faz consulta de grupo em perfis', async () => {
    await assertFails(getDocs(collectionGroup(deslogado(), 'perfis')));
  });

  test('consulta filtrando pelo próprio id também é negada (list é sempre não)', async () => {
    await semeia(db => setDoc(doc(db, 'dados', ANA.uid), blobOk()));
    await assertFails(getDocs(query(collection(comoAna(), 'dados'), where(documentId(), '==', ANA.uid))));
  });

  test('subcoleção dentro do próprio documento é negada', async () => {
    await assertFails(setDoc(doc(comoAna(), 'dados', ANA.uid, 'extra', 'x'), { x: 1 }));
    await assertFails(getDoc(doc(comoAna(), 'dados', ANA.uid, 'extra', 'x')));
  });

  test('id parecido com o uid não vale como dono', async () => {
    for (const id of ['ana ', 'Ana', 'ana​']) {
      await assertFails(setDoc(doc(comoAna(), 'dados', id), blobOk()));
    }
  });

  test('Ana não lê o push do Bento', async () => {
    await semeia(db => setDoc(doc(db, 'push', BENTO.uid), { tokens: {} }));
    await assertFails(getDoc(doc(comoAna(), 'push', BENTO.uid)));
  });

  test('Ana não apaga dados, perfil nem push do Bento', async () => {
    await semeia(async db => {
      await setDoc(doc(db, 'dados', BENTO.uid), blobOk());
      await setDoc(doc(db, 'perfis', BENTO.uid), { email: BENTO.email, criado: '2026-10-05T00:00:00.000Z' });
      await setDoc(doc(db, 'push', BENTO.uid), { tokens: {} });
    });
    for (const colecao of ['dados', 'perfis', 'push']) {
      await assertFails(deleteDoc(doc(comoAna(), colecao, BENTO.uid)));
    }
  });

  test('tokens que não é mapa é rejeitado', async () => {
    await assertFails(setDoc(doc(comoAna(), 'push', ANA.uid), { tokens: 'nada disso' }));
  });

  test('Ana não cria o perfil do Bento nem usando o próprio e-mail', async () => {
    await assertFails(setDoc(doc(comoAna(), 'perfis', BENTO.uid), {
      email: ANA.email, criado: '2026-10-05T00:00:00.000Z',
    }));
  });
});
```

- [ ] **Step 3: Rodar** — `export PATH="$HOME/.local/bin:$HOME/.local/opt/jdk21/Contents/Home/bin:$PATH"; npm run test:rules`. Esperado: PASS, 52 + 9 = 61. (São testes de caracterização: as regras atuais já barram tudo. Se algum **falhar**, é furo real — pare e reporte, não mexa nas regras.)

- [ ] **Step 4: Provar que os testes medem algo (mutação).** Em `firestore.rules`, troque temporariamente o bloco final `allow read, write: if false;` por `if true;` → rode `npm run test:rules` → **precisam falhar** pelo menos "consulta de grupo..." e "subcoleção...". Depois troque em `match /dados/{uid}` o `allow delete: if meu(uid);` por `allow delete: if request.auth != null;` → "Ana não apaga dados..." **precisa falhar**. Volte o arquivo com `git checkout firestore.rules` e rode de novo (61 PASS). Registre no relatório quais testes falharam em cada mutação.

- [ ] **Step 5: Commit** (só o arquivo de teste):

```bash
git add tests/rules.test.mjs
git commit -m "test: regras barram consulta de grupo, subcoleção e dado alheio"
```

---

### Task 2: Sonda de ataque ao banco (`scripts/sonda-banco.mjs`)

**Files:**
- Create: `scripts/sonda-banco.mjs`
- Create: `tests/sonda-banco.test.mjs`
- Modify: `package.json` — script `"sonda:banco": "node scripts/sonda-banco.mjs --producao"` e `tests/sonda-banco.test.mjs` no fim da lista do `test:unit`.

**Interfaces (exportadas por `scripts/sonda-banco.mjs`):**
- `lerConfig(textoCloudJs) → { apiKey, projeto }` — regex em `apiKey: '...'` e `projectId: '...'`; lança se faltar.
- `classifica(esperado, resultado) → { ok, detalhe }` — `esperado` é `'sucesso'` ou um array de status aceitos (ex.: `[403]`); `resultado` é `{ status }` ou `{ erroRede: 'msg' }`. Regras: `'sucesso'` só passa com 2xx; ataque passa só se `status` está no array; qualquer 2xx em ataque reprova; erro de rede só passa se o array contém `'rede'`.
- `rodaSonda({ fetch, apiKey, projeto, log, aleatorio = () => crypto.randomBytes(6).toString('hex') }) → Promise<{ ok, linhas, sobras }>` — `linhas`: `[{ nome, ok, detalhe }]`; `sobras`: uids que não foi possível confirmar apagados.
- CLI: `node scripts/sonda-banco.mjs --producao` lê `cloud.js` da raiz do repo, roda, imprime a tabela e sai com 0 (tudo ok e sem sobras), 1 (falha) ou 2 (sem `--producao`, sem tocar a rede).

**Comportamento de `rodaSonda` (nesta ordem):**
1. Cria Ana e Bento: `POST https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=<apiKey>` com `{ email, password, returnSecureToken: true }` → `{ idToken, localId }`. Senha = `crypto.randomBytes(18).toString('base64url')`.
2. **Controles positivos** (esperado `'sucesso'`), via Firestore REST `https://firestore.googleapis.com/v1/projects/<projeto>/databases/(default)/documents/...` com `Authorization: Bearer <idToken>`:
   - Ana grava `dados/<ana>` (blob válido) → `PATCH`; Ana lê `dados/<ana>` → `GET`; Ana cria `perfis/<ana>` com `{ email, criado, tz: 'America/Sao_Paulo', nome: 'Sonda', origem: 'outro' }`.
   - Bento grava `dados/<bento>`, `perfis/<bento>` e `push/<bento>` = `{ tokens: {} }` (sem endpoint, para o cron ignorar). Bento lê `dados/<bento>` e guarda o `updateTime`.
3. **Ataques** (esperado `[403]` salvo indicação):
   - Sem login: GET `dados/<ana>`, `perfis/<ana>`; GET da coleção `dados` (listar); PATCH `dados/<ana>`; `:runQuery` com `{ structuredQuery: { from: [{ collectionId: 'dados', allDescendants: true }] } }`.
   - Ana contra Bento: GET `dados/<bento>`, `perfis/<bento>`, `push/<bento>`; PATCH `dados/<bento>`; DELETE `dados/<bento>`; PATCH `push/<bento>` com `{ tokens: {} }`; GET das coleções `dados` e `perfis`; `:runQuery` de grupo em `dados`; `:runQuery` em `dados` com `where __name__ == <doc do Bento>`.
   - Ana no próprio documento, campo/formato proibido: PATCH `perfis/<ana>?updateMask.fieldPaths=plano` com `plano: 'pro'`; idem `avisosOrcamento`, `cpf`, `origem` (mudar para `'google'`) e `email` (outro e-mail); PATCH `dados/<ana>` com chave extra `admin`, com `taxaMensal: 999`, com `obras` como mapa; PATCH `push/<ana>` com 11 `subs`; PATCH em `qualquer/<ana>`; PATCH em `dados/<ana>/extra/x`.
   - Caminho estranho (esperado `[400, 403, 404]`): GET `dados/..%2Fperfis%2F<bento>`; GET `dados/__<bento>__`.
   - Outros bancos (esperado `[400, 401, 403, 404, 423, 'rede']`): GET `https://<projeto>-default-rtdb.firebaseio.com/.json`; GET `https://firebasestorage.googleapis.com/v0/b/<projeto>.firebasestorage.app/o`.
4. **Integridade:** Bento lê `dados/<bento>` de novo; `updateTime` igual ao do passo 2 → ok; diferente → reprova ("dado da vítima mudou").
5. **Limpeza (`finally`, sempre):** cada conta apaga os próprios `dados`, `perfis`, `push` (DELETE com o próprio token) e depois a si mesma (`POST .../v1/accounts:delete?key=<apiKey>` com `{ idToken }`). Confirma com `POST .../v1/accounts:lookup?key=<apiKey>` com `{ idToken }`: resposta de erro (ou sem `users`) = apagada; senão entra em `sobras`. Erros na limpeza não interrompem a limpeza das outras contas.

Blob válido usado nos controles: campos Firestore `{ obras: { arrayValue: {} }, config: { mapValue: { fields: { taxaMensal: { integerValue: '1' }, topicosCustom: { arrayValue: {} } } } } }`. Escreva um helper interno `valor(js)` que converte JS → valor Firestore (null, boolean, inteiro → `integerValue` string, não inteiro → `doubleValue`, string, array → `arrayValue.values`, objeto → `mapValue.fields`) para montar os corpos dos ataques.

Cada requisição usa `AbortSignal.timeout(15000)`. `log` recebe só linhas da tabela (`✔ nome (403)` / `✗ nome (200 — devia ser 403)`) e o resumo final; nunca senha/token.

- [ ] **Step 1: Escrever os testes que falham** (`tests/sonda-banco.test.mjs`). Monte um **Firebase falso** em memória dentro do teste: um `fetch(url, init)` que responde `signUp` (devolve `idToken: 'tok-<n>'`, `localId: 'uid-<n>'`), `accounts:delete`/`lookup`, e o Firestore REST aplicando a regra simplificada "o token só alcança documentos `dados|perfis|push/<seu uid>`; listar e `runQuery` dão 403; sem token dá 403; caminho com `..` ou `__` dá 400; RTDB/Storage dão 404". Guarde `updateTime` por documento. Casos:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { lerConfig, classifica, rodaSonda } from '../scripts/sonda-banco.mjs';
// ... firebaseFalso(opcoes) definido aqui: devolve { fetch, contas, chamadas }

test('lerConfig acha apiKey e projeto no cloud.js real', () => {
  const c = lerConfig(readFileSync(new URL('../cloud.js', import.meta.url), 'utf8'));
  assert.match(c.apiKey, /^AIza[\w-]{20,}$/);
  assert.equal(c.projeto, 'app-construcao-civil');
});

test('classifica: 2xx em ataque reprova, 403 esperado passa, 404 onde se espera 403 reprova', () => {
  assert.equal(classifica([403], { status: 403 }).ok, true);
  assert.equal(classifica([403], { status: 200 }).ok, false);
  assert.equal(classifica([403], { status: 404 }).ok, false);
  assert.equal(classifica('sucesso', { status: 200 }).ok, true);
  assert.equal(classifica('sucesso', { status: 403 }).ok, false);
  assert.equal(classifica([404, 'rede'], { erroRede: 'ENOTFOUND' }).ok, true);
  assert.equal(classifica([403], { erroRede: 'ENOTFOUND' }).ok, false);
});

test('banco fechado: tudo ok, sem sobras', async () => {
  const f = firebaseFalso();
  const r = await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {} });
  assert.equal(r.ok, true, JSON.stringify(r.linhas.filter(l => !l.ok)));
  assert.deepEqual(r.sobras, []);
  assert.ok(r.linhas.length >= 30);
});

test('regra quebrada (Ana lê dados do Bento) reprova', async () => {
  const f = firebaseFalso({ vazar: { metodo: 'GET', caminho: /dados\/uid-2$/ } });
  const r = await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {} });
  assert.equal(r.ok, false);
});

test('controle positivo falhando reprova (sem falso verde)', async () => {
  const f = firebaseFalso({ negarDono: true });
  const r = await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {} });
  assert.equal(r.ok, false);
});

test('limpeza roda mesmo se um ataque estoura a rede', async () => {
  const f = firebaseFalso({ estourarEm: /runQuery/ });
  await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {} }).catch(() => {});
  assert.equal(f.contas.size, 0, 'conta descartável ficou para trás');
});

test('conta que não some vira sobra e reprova', async () => {
  const f = firebaseFalso({ naoApagar: true });
  const r = await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {} });
  assert.equal(r.ok, false);
  assert.equal(r.sobras.length, 2);
});

test('saída nunca mostra senha nem token', async () => {
  const f = firebaseFalso();
  const saida = [];
  await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: l => saida.push(l) });
  const texto = saida.join('\n');
  for (const segredo of [...f.senhas, ...f.tokens]) assert.ok(!texto.includes(segredo), 'vazou segredo na saída');
});

test('dado da vítima alterado reprova', async () => {
  const f = firebaseFalso({ mexerNoBento: true }); // muda updateTime de dados/uid-2 entre as leituras
  const r = await rodaSonda({ fetch: f.fetch, apiKey: 'k', projeto: 'p', log: () => {} });
  assert.equal(r.ok, false);
});
```

  Também: um teste de CLI sem `--producao` (`spawnSync(process.execPath, ['scripts/sonda-banco.mjs'])`) espera status 2 e nenhuma chamada de rede (o processo não tem como chamar: basta conferir o código de saída e a mensagem de uso).

- [ ] **Step 2: Rodar e ver falhar** — `node --test tests/sonda-banco.test.mjs` → FAIL (módulo não existe).

- [ ] **Step 3: Implementar `scripts/sonda-banco.mjs`** conforme as interfaces e o comportamento acima. Cabeçalho em comentário explicando: o que a sonda prova, que usa só a `apiKey` pública e contas descartáveis, que roda contra a produção e apaga tudo, e quando rodar (depois de `npm run rules:deploy`). CLI no fim: `if (import.meta.url === pathToFileURL(process.argv[1]).href) principal()`.

- [ ] **Step 4: Rodar e ver passar** — `node --test tests/sonda-banco.test.mjs`.

- [ ] **Step 5: package.json** — script `sonda:banco` e teste no `test:unit`. Rodar `npm run test:unit` inteiro (273 + novos, 0 falhas).

- [ ] **Step 6: Commit**

```bash
git add scripts/sonda-banco.mjs tests/sonda-banco.test.mjs package.json
git commit -m "feat: sonda de ataque contra o banco em produção"
```

(Não rode a sonda contra a produção nesta tarefa — o controlador roda depois.)

---

### Task 3: Documentação

**Files:**
- Modify: `CLAUDE.md` — seção "Fronteira de segurança": no parágrafo "Ao mudar o formato do estado: ...", acrescentar ao fim da sequência `` `npm run sonda:banco` ``; e um parágrafo curto: o que a sonda faz (2 contas `@example.com` na produção, ~35 verificações com controle positivo, apaga tudo; código 0 = banco fechado, 1 = algo passou ou sobrou conta — os uids aparecem na saída para apagar no console do Auth).
- Modify: `AGENTS.md` — item 3 de "O que quebra produção se for ignorado": acrescentar `` `npm run sonda:banco` `` depois do `rules:deploy`.

- [ ] **Step 1:** Editar os dois arquivos como acima (português, mesmo tom do arquivo).
- [ ] **Step 2:** `npm run test:unit` (o `tests/docs.test.mjs` confere links e caminhos) — PASS.
- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md AGENTS.md
git commit -m "docs: sonda do banco depois de publicar as regras"
```

---

## Depois das tarefas (controlador, com autorização do Giovani)

1. `npm run rules:deploy` (sincroniza o comentário de 26/09; lógica igual).
2. `npx firebase firestore:databases:update "(default)" --delete-protection ENABLED --project app-construcao-civil` e conferir com `firestore:databases:get`.
3. `npm run sonda:banco` na produção — esperado: tudo ✔, 0 sobras, código 0.
4. Se o Giovani decidir **Blaze**: `--point-in-time-recovery ENABLED` no mesmo `databases:update`, e `firestore:backups:schedules:create` diário (retenção 7 dias) e semanal (14 semanas); conferir com `databases:get` e `backups:schedules:list`.
5. PR com prévia da Vercel conferida (o app não muda; a prévia só confirma que segue de pé), relatório no Obsidian, memória.

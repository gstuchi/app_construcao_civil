# Núcleo de cálculo em Swift (etapa 1A do app nativo) — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> Neste time: o Forja implementa uma tarefa por vez, o Lupa revisa cada uma antes da próxima. Ninguém faz commit, push ou PR sem o Orquestrador pedir; quando pedir, valem os comandos de commit de cada tarefa.

**Goal:** Reescrever em Swift todas as regras puras do site (`calc.js`, `dados.js` e a chave do token do `push.js`) num pacote local `app-ios/CusttaNucleo`, travado contra o site por vetores de teste gerados do próprio código JavaScript.

**Architecture:** O site ganha um gerador (`scripts/vetores-calc.mjs`) que roda as funções de verdade sobre casos fixos e grava `tests/vetores/calc.json`; um teste do site garante que o arquivo está em dia com o código. O pacote Swift lê o mesmo arquivo nos testes. O núcleo modela o documento `dados/{uid}` como uma árvore JSON (`ValorJSON`) e os tipos (`Estado`, `Obra`, `Gasto`…) leem e escrevem por cima dela, então campo desconhecido nunca some. Onde o Swift faz diferente do JavaScript (número em texto, `toFixed`, `Math.round`, `Intl`, `JSON.stringify`, datas em hora local) o núcleo traz a primitiva do JavaScript reescrita e conferida contra o próprio JavaScript.

**Tech Stack:** Node 22 (`node:test`), Swift 6.2 (tools-version 6.2, modo Swift 6), Swift Testing, Foundation e CryptoKit, `swift test` no macOS 26 com o Xcode 26.6 fixo (CI) e no Mac local (Xcode 27). Nenhuma dependência nova, nem npm nem Swift.

**Spec:** `docs/specs/2026-10-06-app-nativo-design.md` (seções "Três camadas", "Dados e sincronização", "Testes e validação" 1 a 3 e "Achados no site"). Inventário de apoio, com arquivo e linha: `docs/plans/2026-10-06-app-nativo-inventario.md`.

**Validação deste plano:** o código Swift, o gerador e os testes abaixo foram montados e rodados pelo Prumo num rascunho fora do repositório, contra o `calc.js`, o `dados.js` e o `push.js` desta branch, e depois extraídos do texto deste plano e do da Parte B para uma cópia limpa do worktree e rodados juntos: o gerador produz 52 grupos e 513 casos; os 66 testes do núcleo desta parte passam com Swift 6.4 (Xcode 27), assim como o `npm run test:unit`. As primitivas de número foram conferidas contra o Node em 4.042 valores sorteados (toString, toFixed com 0, 1 e 2 casas, Math.round e Intl pt-BR), sem nenhuma diferença. A primeira compilação com o Xcode 26.6 da CI acontece no PR 3 aberto como rascunho (decisão "Xcode da CI").

## Global Constraints

- **Padrão profissional (regra do Giovani, 06/10):** "Quero tudo o mais profissional possível; se precisar de referência, me diga que a gente procura junto." Faltou referência para uma decisão de código, teste ou texto: ninguém improvisa; a falta vai ao Orquestrador, que procura com o Giovani.
- Dinheiro bate no centavo: `|swift − js| < 0,005`. Valores contínuos (taxa, TIR, meses de obra, percentuais) com tolerância relativa de 1e-9. Texto, booleano e inteiro são exatos.
- "Hoje" sempre entra como argumento; nenhuma função do núcleo lê o relógio, exceto `agoraEmMilissegundos()` e o padrão de `gerarId`.
- Fuso fixo `America/Sao_Paulo`: o gerador força `TZ=America/Sao_Paulo`; o job de CI exporta o mesmo `TZ`; os testes Swift passam o fuso explícito a `dataLocalISO`.
- Identificadores, comentários, mensagens de teste e commits em português (`obra`, `gasto`, `topico`, `fase`, `corrigido`). Nome em inglês do site vira português no Swift: `money` → `moeda`, `moneyShort` → `moedaCurta`, `moneyCurto` → `moedaCurtaSemZero`, `parseNum` → `lerNumero`, `canon` → `canonico`, `hashEndpoint` → `chaveDoToken`, `uid()` → `gerarId`. O comentário de cada função diz de qual função do site ela é porte.
- Pacote local `app-ios/CusttaNucleo/`, `// swift-tools-version: 6.2`, `platforms: [.iOS(.v26), .macOS(.v26)]`, sem dependência externa. Roda com `swift test --package-path app-ios/CusttaNucleo`.
- `app-ios/` entra no `.vercelignore`; `tests/vercel.test.cjs` confere.
- Nenhuma chave nova no blob; `firestore.rules` não muda.
- Nenhum pacote npm novo. Teste novo do site entra na lista do `test:unit` do `package.json`, arquivo por arquivo.
- Workflow novo segue as guardas de `tests/workflow.test.cjs`: action presa por SHA de 40 caracteres, `permissions:` com `contents: read`, sem `pull_request_target`/`workflow_run`/`issue_comment`, e `${{ }}` dentro de `run:` só com `github.run_number`, `github.run_attempt` ou `secrets.*`.
- Mudou arquivo da raiz que o app web usa (`calc.js`, `app.js`): incrementar `CACHE` em `sw.js` (hoje `obras-v63`), como manda o cabeçalho do próprio `sw.js`.
- Commits: um por mudança lógica, assunto `tipo: descrição` em minúsculas com acento, corpo em prosa quando não é trivial, autor Giovani Stuchi, **sem linha de coautoria**. Branch + PR, nunca direto na `main`. Um worktree por entrega em `.claude/worktrees/<nome>`, criado da `origin/main` (a pasta principal do projeto está atrasada): cada linha da tabela "Como entregar" é uma tarefa do Orquestrador, com branch, worktree e PR próprios.
- Os escapes de caractere nos trechos de código deste plano usam a forma `\u{a0}` (vale em JavaScript e em Swift). Copie exatamente: a forma de quatro dígitos sem chaves vira o caractere invisível quando passa por algumas ferramentas.

## Decisões

| Ponto | Decisão | Por quê |
| --- | --- | --- |
| Número inteiro × decimal do Firestore | Todo número é `Double` no núcleo. Ao gravar, número inteiro com `|n| ≤ 2^53 − 1` (e que não é −0) vai como `Int64`; o resto como `Double` (`ValorJSON.paraFoundation`). | É exatamente o que o SDK JavaScript faz (`isSafeInteger` → `integerValue`). O documento gravado pelo app fica idêntico ao que o site gravaria; o JavaScript não distingue os dois na leitura. |
| `tamanhoBlob` | Igualdade exata de bytes com o site, não 1% de folga. | O núcleo já precisa de um JSON idêntico ao `JSON.stringify` para o `canon` (comparação canônica) e, na etapa 5, para o JSON da exportação (spec, "Formatos fixos": byte a byte). A ordem das chaves não muda a contagem de bytes, então o tamanho sai exato. Com folga de 1%, perto de 900.000 bytes o site e o app discordariam em até 9 mil bytes sobre o que cabe. |
| `Math.round` × `rounded()` | `arredondarJS(_:)`: piso e sobe se a fração for ≥ 0,5 (meio vai para +infinito). | `rounded()` leva o meio para longe do zero (−2,5 → −3; o JavaScript dá −2) e `floor(x + 0,5)` erra em 0,49999999999999994. |
| `toFixed` × `String(format:)` | `toFixedJS(_:_:)` com aritmética exata em `UInt128` sobre o valor binário; empate exato vai para o maior. | `String(format: "%.1f", 8.25)` dá "8.2" (empate para o par); o JavaScript dá "8.3". O `moneyShort` do site usa `toFixed`. |
| `Intl` pt-BR × `NumberFormatter` | `moeda(_:)` própria: dígitos mais curtos do `Double`, meio para longe do zero, milhar com ponto, vírgula decimal e U+00A0 depois de "R$". Sem `NumberFormatter`. | Reproduz o ICU do Intl (que arredonda 999,995 para "R$ 1.000,00" e 1,005 para "R$ 1,01"); o `NumberFormatter` arredonda para o par por padrão e o dado de localidade do iOS pode mudar entre versões. Conferido em 4.042 valores. |
| `Date` em hora local × `Calendar` | Conta de calendário pura (dia absoluto, algoritmo days_from_civil) para `diasEntre`, `aPagar`, `addMesesClampado` e séries; só `dataLocalISO` usa `Calendar` com fuso explícito. | `Math.round` sobre a diferença de meias-noites locais dá sempre o número de dias de calendário, com ou sem horário de verão; a conta pura dá o mesmo em qualquer fuso do aparelho. Conferido em 3.000 pares de datas de 1900 a 2100. |
| `JSON.stringify` | `canonico(_:)`: número como o `Number::toString` do ECMAScript (a partir de `description`, que já é o mais curto), texto com os escapes do `JSON.stringify`, chaves na ordem do `canon` (índices de array primeiro, em ordem numérica, depois ordem UTF-16). | Mesmo texto do `canon` do site, byte a byte (1.500 blobs sorteados conferidos), e base para o tamanho exato. |
| `localeCompare` | Comparação por unidade UTF-16 (`menorJS`). | O site usa `localeCompare` só em datas, ids em base 36 e ids de tópico, onde dá a mesma ordem. Id exótico (maiúscula, "_" no meio de dígitos) pode desempatar diferente, sem efeito em total nenhum. |
| `money`, `moneyShort`, `moneyCurto`, `fmtMeses`, `canon` e o limite de aviso de 700 mil bytes | Saem do `app.js` e vão para o `calc.js` (refatoração sem mudança de comportamento, PR com os vetores); o 700.000 vira `AVISO_BLOB`. | O spec pede os vetores "a partir do calc.js e do dados.js"; essas funções puras moravam no `app.js`, que não carrega no Node. A lista de obras da etapa 1B mostra `moneyShort` e `fmtMeses`; sem isso não haveria como travar o formato. O limite de aviso vem pelo mesmo motivo: a sincronização da etapa 1B avisa no mesmo ponto que o site, sem copiar o número à mão. |
| Achado do `aPagar` | Confirmado e corrigido: o limite usa `toISOString` (UTC). | Em Brasília (UTC−3) a meia-noite local cai no mesmo dia em UTC e o erro não aparece; a leste de Greenwich (Lisboa no verão, Tóquio) o 30º dia some. Teste com `TZ=Asia/Tokyo` falha hoje e passa com a correção. |
| Xcode da CI | `DEVELOPER_DIR` fixo no Xcode 26.6 do runner `macos-26` (o padrão de hoje, agora travado), e o PR 3 aberto como rascunho logo depois da Tarefa 4. | O plano foi validado com o Xcode 27.0 (Swift 6.4) e o runner estável não tem Xcode 27: um Swift anterior pode recusar o que o 6.4 aceita, e com o PR aberto cedo isso aparece na primeira tarefa, não na última. Sem a trava, o padrão do runner muda sem aviso. A imagem `xcode-27` do GitHub, ainda em prévia, tem o mesmo Xcode 27.0 (27A266a) da validação: é o plano B se o 26.6 recusar algo que não valha contornar. |
| NaN e infinito | Ficam fora dos vetores: JSON não os representa e o gerador recusa essas saídas por construção. Diferença assumida: data inválida em `diasEntre`, `corrigido` e `mesesDeObra` dá NaN no JavaScript e 0 ou o próprio valor no Swift. Os ramos de infinito e NaN da exibição (`moeda`, `moedaCurta`, `fmtMeses`) têm teste direto. | A normalização descarta gasto com data inválida antes de qualquer conta (`dados.normaliza`), então nenhum número mostrado passa por esses ramos. |
| Parcelamento Price | `expm1` e `log1p` da libm, na mesma fórmula do `calc.js`; não é bit a bit igual ao V8. | Em 2.772 amostras, 289 prestações diferem em 1 ulp (o `pow` da correção não diferiu em nenhuma). Vira 1 centavo só se o produto cair a 1 ulp de um meio centavo; os vetores conferem os casos do site no centavo. |
| Divergências raras assumidas | `dataLocalISO` antes do ano 1000 (o Swift completa o ano com zeros e, antes de 1582, usa o calendário juliano do `Calendar`; o JavaScript não completa e é gregoriano sempre) e `semAcento` com sigma grego no fim da palavra (o JavaScript dá ς, o Swift dá σ). | `dataLocalISO` só recebe o instante de agora; o sigma não aparece em texto em português e a busca do app compara os dois lados com a mesma função. |

## Review Focus

As cinco entradas que o spec implica e que mais podem morder, cada uma com teste na tarefa dona:

1. **Aparelho fora de Brasília** (pessoa viajando, ou o fuso do simulador): o dia de hoje e os 30 dias do "a pagar" têm de bater com o calendário local. Testes: `aPagar` em `Asia/Tokyo` e `Europe/Lisbon` (Tarefa 1) e `diaDependeDoFusoDoAparelho` (Tarefa 7).
2. **Meio centavo exato** nos valores mostrados (8.250 → "R$ 8,3 mil", 999,995 → "R$ 1.000,00", 1,005 → "R$ 1,01"): o arredondamento do Swift não pode discordar do site. Testes: grupos `js.toFixed`, `js.round` (Tarefa 5) e `calc.money`, `calc.moneyShort` (Tarefa 15).
3. **Dado antigo ou feito à mão no banco** (taxa "1,5" em texto, número em texto, ano 0050, data 30/02, parcela quebrada, tópico com emoji no limite de 80): a normalização tem de fazer exatamente o que o `dados.js` faz. Testes: grupo `dados.normaliza` com 45 casos, incluindo "id de tópico conta unidades UTF-16" (Tarefa 8).
4. **Campo que só o site conhece** em qualquer nível (topo, obra, gasto, parcela, venda, afazer, orçamento, tópico próprio): ler e gravar de volta não pode apagar. Testes: `estadoLeEEscreveSemPerderNada` e `gravarCampoConhecidoMantemODesconhecido` (Tarefa 9).
5. **Blob no limite de 900.000 bytes**, com acento, emoji e escape: o app e o site têm de concordar no byte sobre o que cabe. Testes: grupos `calc.tamanhoBlob` e `calc.blobCabe` com blob de exatamente 900.000 e 900.001 bytes (Tarefa 6).

## Fora desta etapa

- Item 2 de "Testes e validação" do spec (formato gravado conferido contra as `firestore.rules` no emulador): entra na Parte B (Tarefas 6, 7 e 13), onde existe gravação.
- Os outros dois achados do site (spec, "Achados no site"), cada um em PR próprio no site antes de a regra entrar no app: o CSV que exporta o id do tópico padrão, antes da etapa 5 (quando a exportação entra nos vetores); o limite de 300 obras sem aviso na tela, antes da etapa 2 (quando o app passa a criar obra).
- Exportação JSON e CSV no núcleo (spec, "Três camadas"): etapa 5.

## Como entregar

Três PRs, nesta ordem. Cada um em worktree próprio criado da `origin/main` atualizada (o seguinte só depois do anterior entrar na `main`):

| PR | Branch e worktree | Tarefas | Estimativa (dias de trabalho do time) |
| --- | --- | --- | --- |
| 1 | `fix/a-pagar-hora-local` em `.claude/worktrees/a-pagar-hora-local` | 1 | 0,5 |
| 2 | `test/vetores-calc` em `.claude/worktrees/vetores-calc` | 2 e 3 | 1 a 1,5 |
| 3 | `feat/nucleo-swift` em `.claude/worktrees/nucleo-swift` | 4 a 18 | 4 a 5 |

A estimativa conta implementação, revisão do Lupa e correções, com o código já escrito e validado neste plano. Fica fora dela o tempo do Giovani: conferir a prévia da Vercel dos PRs 1 e 2 (uns 10 minutos cada) e aprovar os três PRs.

```bash
# na raiz do repositório principal; de dentro de um worktree, a linha abaixo sobe até ela
cd "$(git rev-parse --path-format=absolute --git-common-dir)/.."
git fetch origin
git worktree add .claude/worktrees/a-pagar-hora-local -b fix/a-pagar-hora-local origin/main
cd .claude/worktrees/a-pagar-hora-local && npm ci
```

Todos os comandos das tarefas rodam na raiz do worktree.

**Na entrega de cada PR:** descrição em prosa (contexto, o que muda, decisão técnica), o link da prévia da Vercel conferido e o "como testar". Os PRs 1 e 2 mexem em `calc.js`, `app.js` e `sw.js`: na prévia, entrar na conta de teste e conferir que lista de obras, saldo, "a pagar", gráficos e simulador mostram os mesmos números da produção. O PR 3 não muda nada que vai para a Vercel (`app-ios/` está no `.vercelignore`); a prévia só confirma que o site continua igual.

**PR 3 aberto cedo:** o Orquestrador abre o PR 3 como rascunho logo depois dos commits da Tarefa 4, para o job `nucleo` compilar com o Xcode da CI desde a primeira tarefa (decisão "Xcode da CI"); cada tarefa seguinte empurra e a CI roda de novo.

## Mapa de arquivos

| Arquivo | Responsabilidade |
| --- | --- |
| `calc.js` (modificar) | limite do `aPagar` em hora local; recebe `money`, `moneyShort`, `moneyCurto`, `fmtMeses`, `canon` e a constante `AVISO_BLOB` |
| `app.js` (modificar) | passa a usar as cinco funções e o `AVISO_BLOB` do `OBRA_CALC` |
| `sw.js` (modificar) | `CACHE` incrementado nos PRs 1 e 2 |
| `tests/calc.test.cjs` (modificar) | testes do `aPagar` por fuso e das funções que vieram do `app.js` |
| `scripts/vetores-calc.mjs` (criar) | gerador dos vetores |
| `tests/vetores/calc.json` (gerado e versionado) | casos de entrada e saída |
| `tests/vetores.test.mjs` (criar) | arquivo em dia com o código; toda exportação coberta |
| `.vercelignore`, `.gitignore`, `package.json`, `CLAUDE.md` (modificar) | `app-ios/` fora do deploy; saída do SwiftPM fora do git; scripts `vetores` (PR 2) e `test:nucleo` (PR 3); instrução dos vetores |
| `.github/workflows/app-ios.yml` (criar) e `tests/workflow.test.cjs` (modificar) | job `nucleo` com `swift test` no Xcode 26.6 e suas guardas |
| `app-ios/CusttaNucleo/Package.swift` | pacote |
| `Sources/CusttaNucleo/ValorJSON.swift` | árvore JSON do documento e Codable |
| `Sources/CusttaNucleo/NumeroJS.swift` | primitivas do JavaScript: `numeroJS`, `arredondarJS`, `toFixedJS`, `aparadoJS`, `numeroDeTextoJS`, verdade e `Number()` de valor |
| `Sources/CusttaNucleo/SerializadorJS.swift` | `canonico`, `mesmoConteudo`, `tamanhoBlob`, `blobCabe`, `menorJS` |
| `Sources/CusttaNucleo/ValorJSON+Foundation.swift` | ponte com NSNumber/NSArray/NSDictionary (o que o Firestore usa) |
| `Sources/CusttaNucleo/Datas.swift` | datas do `calc.js` |
| `Sources/CusttaNucleo/Normalizacao.swift` | porte do `dados.js` |
| `Sources/CusttaNucleo/Modelo.swift` e `Topicos.swift` | `Estado`, `Obra`, `Gasto`, `Afazer`, `Configuracao`, `TopicoProprio`, tópicos padrão |
| `Sources/CusttaNucleo/Correcao.swift`, `Tir.swift`, `Series.swift`, `Listas.swift`, `Parcelas.swift`, `Moeda.swift`, `Orcamento.swift`, `Fila.swift`, `Versao.swift`, `Miudezas.swift` | um grupo de funções do `calc.js` (e do `push.js`/`app.js`) cada |
| `Tests/CusttaNucleoTests/Vetores.swift` | leitura dos vetores e comparações com tolerância |
| `Tests/CusttaNucleoTests/*Tests.swift` | um arquivo por grupo, mais `CoberturaTests` |

---

### Task 1: Limite do "a pagar" em hora local (site)

**Files:**
- Modify: `calc.js:196-199` (função `aPagar`)
- Modify: `sw.js:3` (`CACHE`)
- Test: `tests/calc.test.cjs` (novo teste logo depois de `t('aPagar: janela de 30 dias', …)`)

**Interfaces:**
- Consumes: `dataLocalISO(data)` já existente em `calc.js:42`.
- Produces: `aPagar(obras, hojeISO, dias = 30)` com o mesmo retorno `{ total, qtd, itens }`; o limite passa a ser o dia de calendário `hoje + dias` no fuso do aparelho.

- [ ] **Step 1: Escrever o teste que falha**

Em `tests/calc.test.cjs`, logo depois do bloco `t('aPagar: janela de 30 dias', () => { … });`:

```js
t('aPagar: o 30º dia entra em qualquer fuso (limite em hora local, não em UTC)', () => {
  const tzAnterior = process.env.TZ;
  const obras = [{ dataInicio:'2026-07-01', gastos:[{ valor:100, data:'2026-08-05' }] }]; // hoje + 30
  try{
    for(const tz of ['Asia/Tokyo', 'Europe/Lisbon', 'America/Sao_Paulo']){
      process.env.TZ = tz;
      assert.strictEqual(C.aPagar(obras, '2026-07-06').qtd, 1, `${tz}: o 30º dia precisa entrar`);
    }
  }finally{
    if(tzAnterior === undefined) delete process.env.TZ;
    else process.env.TZ = tzAnterior;
  }
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node tests/calc.test.cjs`
Expected: FAIL com `AssertionError … Asia/Tokyo: o 30º dia precisa entrar` (`0 !== 1`). Em Brasília o erro não aparece: a meia-noite local (UTC−3) cai no mesmo dia em UTC.

- [ ] **Step 3: Corrigir**

Em `calc.js`, dentro de `aPagar`, troque a linha do limite:

```js
    const limISO = fim.toISOString().slice(0, 10);
```

por:

```js
    const limISO = dataLocalISO(fim); // hora local, como o resto: toISOString puxava o limite para o dia anterior a leste de Greenwich
```

Em `sw.js`, incremente o número do cache (hoje `const CACHE = 'obras-v63';` vira `const CACHE = 'obras-v64';`; se a `main` já estiver em outro número, some 1 ao que estiver lá).

- [ ] **Step 4: Rodar e ver passar**

Run: `node tests/calc.test.cjs && npm run test:unit`
Expected: `OK: N testes` no primeiro e todos os arquivos verdes no segundo.

- [ ] **Step 5: Commit**

```bash
git add calc.js tests/calc.test.cjs sw.js
git commit -m "fix: a pagar em 30 dias conta o limite em hora local" -m "O limite do aPagar vinha de toISOString, em UTC, enquanto o resto do calc.js trabalha em hora local. Em Brasília a meia-noite local cai no mesmo dia em UTC e nada mudava; a leste de Greenwich o 30º dia saía da lista. O limite agora usa dataLocalISO, e o teste passa por Tóquio, Lisboa e Brasília. É o primeiro dos achados do inventário do app nativo: corrigido antes de entrar nos vetores, para as duas cópias nascerem iguais."
```

---

### Task 2: Formatação de moeda, meses e canon no calc.js (site)

**Files:**
- Modify: `calc.js` (bloco novo antes de `const api = …` e a lista do `api`)
- Modify: `app.js:34-39` (limite de aviso no `save()`), `app.js:65-74` e `app.js:141-151` (definições que saem)
- Modify: `sw.js:3` (`CACHE`)
- Test: `tests/calc.test.cjs` (novos testes no fim, antes do `console.log`)

**Interfaces:**
- Consumes: nada novo.
- Produces: `OBRA_CALC.money(n) → string`, `OBRA_CALC.moneyShort(n) → string`, `OBRA_CALC.moneyCurto(n) → string`, `OBRA_CALC.fmtMeses(m) → string`, `OBRA_CALC.canon(x) → string` e `OBRA_CALC.AVISO_BLOB` (700000, o limite de aviso do `save()`), com o comportamento exato de hoje no `app.js`. A Tarefa 3 gera vetores deles.

- [ ] **Step 1: Escrever os testes que falham**

No fim de `tests/calc.test.cjs`, antes de `console.log(\`OK: ${n} testes\`);`:

```js
t('money, moneyShort e moneyCurto moram no calc.js, iguais aos que o app mostra', () => {
  assert.strictEqual(C.money(1234.5), 'R$\u{a0}1.234,50');
  assert.strictEqual(C.money(null), 'R$\u{a0}0,00');
  assert.strictEqual(C.moneyShort(8250), 'R$ 8,3 mil');
  assert.strictEqual(C.moneyShort(2.5e6), 'R$ 2,50 mi');
  assert.strictEqual(C.moneyShort(-500), '-R$\u{a0}500,00');
  assert.strictEqual(C.moneyCurto(8000), 'R$ 8 mil');
  assert.strictEqual(C.moneyCurto(1e6), 'R$ 1 mi');
});

t('fmtMeses: começando, 1 mês, N meses', () => {
  assert.strictEqual(C.fmtMeses(0.5), 'começando');
  assert.strictEqual(C.fmtMeses(1.4), '1 mês');
  assert.strictEqual(C.fmtMeses(1.5), '2 meses');
});

t('canon: chaves em ordem para comparar estados', () => {
  assert.strictEqual(C.canon({ b: 1, a: [{ d: 1, c: 2 }] }), '{"a":[{"c":2,"d":1}],"b":1}');
});

t('limite de aviso do blob mora no calc.js, abaixo do limite de gravação', () => {
  assert.strictEqual(C.AVISO_BLOB, 700000);
  assert.ok(C.AVISO_BLOB < C.LIMITE_BLOB);
});

t('app.js usa a formatação e o limite de aviso do calc.js, sem cópia própria', () => {
  const app = require('fs').readFileSync(require('path').join(__dirname, '..', 'app.js'), 'utf8');
  assert.match(app, /const \{ money, moneyShort, moneyCurto, fmtMeses, canon \} = OBRA_CALC;/);
  assert.doesNotMatch(app, /const BRL = new Intl\.NumberFormat|function canon\(|function fmtMeses\(/);
  assert.match(app, /OBRA_CALC\.AVISO_BLOB/);
  assert.doesNotMatch(app, /700000/);
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node tests/calc.test.cjs`
Expected: FAIL com `TypeError: C.money is not a function`.

- [ ] **Step 3: Mover as funções**

Em `calc.js`, logo depois de `  const LIMITE_BLOB = 900000;`, acrescente:

```js
  /* A partir daqui o save() do app.js avisa que os dados estão perto do limite. */
  const AVISO_BLOB = 700000;
```

No mesmo arquivo, logo antes de `  const api = { DIAS_MES, …`, acrescente:

```js
  /* ---- exibição: moeda, meses e comparação de estados ----
     Moravam no app.js. Vieram para cá por serem puras: o app nativo confere a
     cópia dele contra estas pelos vetores (scripts/vetores-calc.mjs). */
  const BRL = new Intl.NumberFormat('pt-BR', { style:'currency', currency:'BRL' });
  const money = n => BRL.format(n || 0);
  const moneyShort = n => {
    const a = Math.abs(n), s = n < 0 ? '-' : '';
    if(a >= 1e6)  return s + 'R$ ' + (a / 1e6).toFixed(a >= 1e7 ? 1 : 2).replace('.', ',') + ' mi';
    if(a >= 1000) return s + 'R$ ' + (a / 1000).toFixed(a >= 10000 ? 0 : 1).replace('.', ',') + ' mil';
    return money(n);
  };
  /* "R$ 8,0 mil" → "R$ 8 mil": nas frases do orçamento o ",0" só ocupa espaço */
  const moneyCurto = n => moneyShort(n).replace(/,0+ (mil|mi)$/, ' $1');
  function fmtMeses(m){
    if(m < 1) return 'começando';
    const r = Math.round(m);
    return r + (r === 1 ? ' mês' : ' meses');
  }
  /* stringify com chaves ordenadas — compara estados sem depender da ordem do Firestore */
  function canon(x){
    return JSON.stringify(x, (k, v) => v && typeof v === 'object' && !Array.isArray(v)
      ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
  }

```

e, na lista do `api`, troque `LIMITE_BLOB, tamanhoBlob` por `LIMITE_BLOB, AVISO_BLOB, tamanhoBlob` e, no fim, `TOPICOS, orcamentoObra };` por `TOPICOS, orcamentoObra, money, moneyShort, moneyCurto, fmtMeses, canon };`.

Em `app.js`, dentro de `save()`, troque as duas ocorrências de `700000` (`app.js:35` e `app.js:39`) por `OBRA_CALC.AVISO_BLOB`.

Em `app.js`, troque o trecho de `app.js:65-74`:

```js
const BRL = new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'});
const money = n => BRL.format(n||0);
const moneyShort = n => {
  const a = Math.abs(n), s = n<0 ? '-' : '';
  if(a>=1e6)  return s+'R$ '+(a/1e6).toFixed(a>=1e7?1:2).replace('.',',')+' mi';
  if(a>=1000) return s+'R$ '+(a/1000).toFixed(a>=10000?0:1).replace('.',',')+' mil';
  return money(n);
};
/* "R$ 8,0 mil" → "R$ 8 mil": nas frases do orçamento o ",0" só ocupa espaço */
const moneyCurto = n => moneyShort(n).replace(/,0+ (mil|mi)$/, ' $1');
```

por:

```js
/* Moeda, meses e canon moram no calc.js (puros; o app nativo confere a cópia dele pelos vetores). */
const { money, moneyShort, moneyCurto, fmtMeses, canon } = OBRA_CALC;
```

e apague as duas funções de `app.js:141-151` (as linhas `const obraById = …` e o comentário dela ficam):

```js
function fmtMeses(m){
  if(m < 1) return 'começando';
  const r = Math.round(m);
  return r + (r===1 ? ' mês' : ' meses');
}
```

```js
/* stringify com chaves ordenadas — comparar estados independente da ordem do Firestore */
function canon(x){
  return JSON.stringify(x, (k,v)=> v && typeof v==='object' && !Array.isArray(v)
    ? Object.keys(v).sort().reduce((a,c)=>{ a[c]=v[c]; return a; },{}) : v);
}
```

Em `sw.js`, some 1 ao número do `CACHE` que estiver em `sw.js:3` (o `app.js` novo depende do `calc.js` novo; o cache novo guarda os dois juntos).

- [ ] **Step 4: Rodar e ver passar**

Run: `node tests/calc.test.cjs && npm run test:unit && npm run test:browser`
Expected: tudo verde. O `test:browser` (emuladores e Playwright, precisa de Java 21) prova que as telas continuam formatando igual; a CI roda os três.

- [ ] **Step 5: Commit**

```bash
git add calc.js app.js sw.js tests/calc.test.cjs
git commit -m "refactor: moeda, meses, canon e limite de aviso do app.js no calc.js" -m "money, moneyShort, moneyCurto, fmtMeses e canon são puras e moravam no app.js, que não carrega no Node. O app nativo precisa conferir a cópia dele dessas funções pelos vetores gerados do calc.js; sem a mudança, o formato do dinheiro na lista de obras não teria trava. O limite de 700 mil bytes do aviso de dados perto do fim vira AVISO_BLOB pelo mesmo motivo. O app.js passa a usar os do OBRA_CALC e o comportamento é o mesmo."
```

---

### Task 3: Vetores compartilhados (site)

**Files:**
- Create: `scripts/vetores-calc.mjs`
- Create (gerado): `tests/vetores/calc.json`
- Create: `tests/vetores.test.mjs`
- Modify: `package.json` (script `vetores`; `tests/vetores.test.mjs` na lista do `test:unit`)
- Modify: `CLAUDE.md` (seção "Comandos")

**Interfaces:**
- Consumes: `calc.js` (todas as exportações, inclusive as da Tarefa 2), `dados.js` (`normaliza`, `LIMITES`), `push.js` (`hashEndpoint`).
- Produces: `tests/vetores/calc.json` no formato `{ "formato": 1, "fuso": "America/Sao_Paulo", "gerador": "scripts/vetores-calc.mjs", "grupos": { "<modulo>.<funcao>": [ { "caso": string, "args": [...], "saida": ... } ] } }`. Casos de blob grande trazem `"gerar": { "base", "campo", "letra", "vezes" }` e `"tamanho"` no lugar de `args`. Grupos: `calc.<cada exportação>`, `dados.normaliza`, `dados.LIMITES`, `push.hashEndpoint`, `id.base36` e `js.numeroParaTexto`, `js.textoParaNumero`, `js.toFixed`, `js.round`, `js.stringify`, `js.trim` (primitivas do JavaScript que as regras usam). As Tarefas 4 a 18 leem este arquivo.

- [ ] **Step 1: Escrever o teste do site que falha**

Crie `tests/vetores.test.mjs`:

```js
/* Os vetores compartilhados (tests/vetores/calc.json) têm de estar em dia com o calc.js, o
   dados.js e o push.js: o app nativo confere a cópia dele das regras contra este arquivo
   (app-ios/CusttaNucleo). Falhou aqui? Rode `npm run vetores` e faça commit do arquivo junto
   com a mudança da regra; o workflow app-ios roda o lado Swift. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);
const arquivo = readFileSync(path.join(RAIZ, 'tests/vetores/calc.json'), 'utf8');
const vetores = JSON.parse(arquivo);

test('o arquivo de vetores está em dia com o código do site', () => {
  const r = spawnSync(process.execPath, ['scripts/vetores-calc.mjs', '--imprimir'],
    { cwd: RAIZ, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  assert.equal(r.status, 0, r.stderr);
  assert.ok(r.stdout === arquivo, 'tests/vetores/calc.json desatualizado: rode npm run vetores e faça commit do arquivo');
});

test('toda função e constante exportada do calc.js tem vetor', () => {
  const faltam = Object.keys(require('../calc.js')).filter(k => !vetores.grupos[`calc.${k}`]);
  assert.deepEqual(faltam, []);
});

test('toda exportação do dados.js tem vetor; do push.js, a chave do token', () => {
  const faltam = Object.keys(require('../dados.js')).filter(k => !vetores.grupos[`dados.${k}`]);
  assert.deepEqual(faltam, []);
  // O resto do push.js é Web Push do navegador (criar, b64ToU8, VAPID_PUBLICA); o app nativo usa o FCM
  // na etapa 5 e só precisa gravar o token na mesma chave.
  assert.ok(vetores.grupos['push.hashEndpoint']?.length, 'push.hashEndpoint');
});

test('vetores determinísticos: fuso fixo e nenhum grupo vazio', () => {
  assert.equal(vetores.formato, 1);
  assert.equal(vetores.fuso, 'America/Sao_Paulo');
  for(const [g, casos] of Object.entries(vetores.grupos)) assert.ok(casos.length > 0, g);
});
```

Em `package.json`, acrescente `tests/vetores.test.mjs` ao fim da lista do `test:unit` (depois de `tests/sonda-banco.test.mjs`) e o script:

```json
    "vetores": "node scripts/vetores-calc.mjs",
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test tests/vetores.test.mjs`
Expected: FAIL com `ENOENT: no such file or directory, open '…/tests/vetores/calc.json'`.

- [ ] **Step 3: Escrever o gerador e gerar o arquivo**

Crie `scripts/vetores-calc.mjs`:

```js
/* Vetores de teste compartilhados entre o site e o app nativo (docs/specs/2026-10-06-app-nativo-design.md,
   "Testes e validação"). Roda as funções de verdade do calc.js, do dados.js e do push.js sobre casos
   fixos e grava entrada e saída em tests/vetores/calc.json. O teste do site (tests/vetores.test.mjs)
   confere que o arquivo está em dia com o código; o núcleo Swift (app-ios/CusttaNucleo) lê o mesmo
   arquivo. Se as duas cópias das regras divergirem, um dos lados falha.

   Determinístico: "hoje" vem sempre do caso e o fuso é America/Sao_Paulo (sem TZ certo, o script se
   executa de novo com ele). Os ids e as datas dos casos são os que o site gera (base 36 e AAAA-MM-DD):
   para eles o localeCompare do calc.js dá a mesma ordem em qualquer língua.

   Uso: npm run vetores                              grava tests/vetores/calc.json
        node scripts/vetores-calc.mjs --imprimir     só imprime (o teste do site usa) */
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const FUSO = 'America/Sao_Paulo';
if(process.env.TZ !== FUSO){
  const r = spawnSync(process.execPath, process.argv.slice(1), { stdio: 'inherit', env: { ...process.env, TZ: FUSO } });
  process.exit(r.status ?? 1);
}
if(Intl.DateTimeFormat().resolvedOptions().timeZone !== FUSO) throw new Error(`fuso ${FUSO} não pegou`);

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);
const C = require('../calc.js');
const D = require('../dados.js');
const P = require('../push.js');

/* ---------- registro dos casos ---------- */
const grupos = {};
function semNaoFinito(v, onde){
  if(typeof v === 'number' && !Number.isFinite(v)) throw new Error(`${onde}: saída com ${v} não cabe em JSON`);
  if(v && typeof v === 'object') for(const x of Object.values(v)) semNaoFinito(x, onde);
}
/* Chama fn com uma cópia dos argumentos (nenhuma função pode alterar o caso gravado). */
function caso(grupo, nome, args, fn){
  const saida = fn(...structuredClone(args));
  semNaoFinito(saida, `${grupo} / ${nome}`);
  (grupos[grupo] ||= []).push({ caso: nome, args, saida: saida === undefined ? null : saida });
}
const calc = nome => (nomeCaso, ...args) => caso(`calc.${nome}`, nomeCaso, args, C[nome]);
const constante = (grupo, valor) => { grupos[grupo] = [{ caso: 'valor', args: [], saida: valor }]; };

/* ---------- obras de exemplo, normalizadas como o app as vê ---------- */
const HOJE = '2026-10-06';
const BLOB = D.normaliza({
  obras: [
    { id: 'o1', nome: 'Casa Alphaville', dataInicio: '2025-03-10', fase: 'construcao',
      valorEstimadoVenda: 1250000, areaM2: 210,
      orcamento: { modo: 'topicos', topicos: { fundacao: 90000, estrutura: 250000, c_mgf1abcd: 1000 } },
      gastos: [
        { id: 'g01', valor: 98000, topico: 'fundacao', descricao: 'Sapatas e baldrame', data: '2025-03-20', pagamento: 'pix' },
        { id: 'g02', valor: 231000, topico: 'estrutura', descricao: 'Laje do térreo', data: '2025-06-02', pagamento: 'pix' },
        { id: 'g03', valor: 12000.5, topico: 'hidraulica', descricao: 'Tubos e conexões', data: '2025-08-15', pagamento: 'pix' },
        { id: 'g04', valor: 3000, topico: 'pintura', descricao: 'Tinta acrílica', data: '2025-08-15', pagamento: 'pix' },
        { id: 'g05a', grupoId: 'gr1', parcela: { n: 1, de: 3 }, valor: 1033.34, topico: 'eletrica', descricao: 'Fios', data: '2026-09-25', pagamento: 'cartao',
          jurosCartao: { taxaMensal: 0, valorCompra: 3100, nParcelas: 3, totalCompra: 3100, jurosCompra: 0 } },
        { id: 'g05b', grupoId: 'gr1', parcela: { n: 2, de: 3 }, valor: 1033.33, topico: 'eletrica', descricao: 'Fios', data: '2026-10-25', pagamento: 'cartao',
          jurosCartao: { taxaMensal: 0, valorCompra: 3100, nParcelas: 3, totalCompra: 3100, jurosCompra: 0 } },
        { id: 'g05c', grupoId: 'gr1', parcela: { n: 3, de: 3 }, valor: 1033.33, topico: 'eletrica', descricao: 'Fios', data: '2026-11-25', pagamento: 'cartao',
          jurosCartao: { taxaMensal: 0, valorCompra: 3100, nParcelas: 3, totalCompra: 3100, jurosCompra: 0 } },
      ],
      afazeres: [{ id: 'a1', texto: 'Comprar tinta', feito: false }, { id: 'a2', texto: 'Pagar pedreiro', feito: true }] },
    { id: 'o2', nome: 'Sobrado Centro', dataInicio: '2024-01-15', fase: 'vendida',
      venda: { valor: 980000, data: '2025-02-10' }, valorEstimadoVenda: 950000, areaM2: 180,
      orcamento: { modo: 'total', total: 700000 },
      gastos: [
        { id: 'h01', valor: 150000, topico: 'terreno', descricao: 'Terreno', data: '2024-01-15', pagamento: 'pix' },
        { id: 'h02', valor: 320000.75, topico: 'alvenaria', descricao: 'Blocos e mão de obra', data: '2024-05-31', pagamento: 'pix' },
        { id: 'h03', valor: 85000, topico: 'acabamento', descricao: 'Porcelanato', data: '2024-12-01', pagamento: 'cartao' },
        { id: 'h04', valor: 4500, topico: 'outros', descricao: 'Limpeza depois da venda', data: '2025-03-01', pagamento: 'pix' },
      ] },
    { id: 'o3', nome: 'Terreno novo', dataInicio: '2026-10-01', fase: 'construcao', gastos: [] },
    { id: 'o4', nome: 'Pronta Jardins', dataInicio: '2025-11-01', fase: 'pronta', valorEstimadoVenda: 610000, areaM2: 95.5,
      orcamento: { modo: 'total', total: 400000 },
      gastos: [
        { id: 'j01', valor: 200000, topico: 'estrutura', descricao: 'Estrutura', data: '2026-01-31', pagamento: 'pix' },
        { id: 'j02', valor: 165000, topico: 'maoobra', descricao: 'Equipe', data: '2026-02-28', pagamento: 'pix' },
        { id: 'j03', valor: 7000, topico: 'c_mgf1abcd', descricao: 'Automação da garagem', data: '2026-03-31', pagamento: 'pix' },
      ] },
  ],
  config: { taxaMensal: 1, topicosCustom: [{ id: 'c_mgf1abcd', nm: 'Automação', ic: 'etiqueta' }] },
});
const [O1, O2, O3, O4] = BLOB.obras;
const TOPICOS_MAPA = Object.fromEntries([...C.TOPICOS, ...BLOB.config.topicosCustom].map(t => [t.id, t]));

/* ---------- constantes ---------- */
constante('calc.DIAS_MES', C.DIAS_MES);
constante('calc.LIMITE_BLOB', C.LIMITE_BLOB);
constante('calc.AVISO_BLOB', C.AVISO_BLOB);
constante('calc.TOPICOS', C.TOPICOS);

/* ---------- fila de escrita ---------- */
const tamanho = calc('tamanhoBlob');
tamanho('blob vazio', D.normaliza(null));
tamanho('blob de exemplo', BLOB);
tamanho('acentos, emoji e escapes', { a: 'ção 😀🏗️', b: 'aspas "x" e barra \\', c: 'linha\nnova\ttab\u0001', d: [1, 0.1, 1e21, -1e-7, true, null] });
tamanho('chaves numéricas e unicode', { '10': 1, '2': 2, 'é': 3, '😀': [{}], '': '' });
const cabe = calc('blobCabe');
cabe('blob de exemplo cabe', BLOB);
/* Blobs grandes não vão inteiros no arquivo: o caso diz como montar (texto de N letras "a"
   no campo `preenchimento`) e o tamanho que dá; os dois lados montam igual. */
for(const alvo of [C.LIMITE_BLOB, C.LIMITE_BLOB + 1]){
  const base = { obras: [], config: { taxaMensal: 1, topicosCustom: [] }, preenchimento: '' };
  const vezes = alvo - C.tamanhoBlob(base);
  const blob = { ...base, preenchimento: 'a'.repeat(vezes) };
  if(C.tamanhoBlob(blob) !== alvo) throw new Error('blob grande com tamanho errado');
  (grupos['calc.blobCabe'] ||= []).push({ caso: `${alvo} bytes`, gerar: { base, campo: 'preenchimento', letra: 'a', vezes }, tamanho: alvo, saida: C.blobCabe(blob) });
}
const terminal = calc('erroEhTerminal');
for(const code of ['permission-denied', 'unauthenticated', 'invalid-argument', 'not-found', 'failed-precondition', 'unimplemented', 'out-of-range'])
  terminal(code, { code });
terminal('prefixo e sublinhado', { code: 'firestore/PERMISSION_DENIED' });
terminal('maiúsculas', { code: 'Unauthenticated' });
terminal('rede caiu', { code: 'unavailable' });
terminal('prazo', { code: 'deadline-exceeded' });
terminal('sem code', {});
terminal('code vazio', { code: '' });
terminal('code numérico', { code: 7 });
terminal('erro nulo', null);
const backoff = calc('proximoBackoff');
for(const n of [0, 1, 2, 3, 4, 5, 6, 30, -1, 2.7, '3', null, 'abc']) backoff(`tentativa ${JSON.stringify(n)}`, n);

/* ---------- datas ---------- */
const local = 'calc.dataLocalISO';
for(const [nome, ms] of [
  ['22h30 em Brasília ainda é o dia anterior em UTC', Date.UTC(2026, 7, 26, 1, 30)],
  ['meia-noite em Brasília', Date.UTC(2026, 7, 26, 3, 0)],
  ['um milissegundo antes da meia-noite', Date.UTC(2026, 7, 26, 2, 59, 59, 999)],
  ['horário de verão antigo (2018)', Date.UTC(2018, 10, 4, 2, 30)],
  ['época', 0],
]) (grupos[local] ||= []).push({ caso: nome, args: [ms], saida: C.dataLocalISO(new Date(ms)) });
const valida = calc('dataISOValida');
for(const s of ['2026-02-28', '2026-02-29', '2026-02-30', '2028-02-29', '2100-02-29', '2000-02-29', '2026-04-31',
  '2026-13-01', '2026-00-10', '2026-1-01', '20260101', '0050-01-01', '0099-12-31', '0100-01-01', '9999-12-31', '', 'abcd-ef-gh'])
  valida(JSON.stringify(s), s);
valida('nulo', null);
const igualOuDepois = calc('dataIgualOuDepois');
igualOuDepois('depois', '2026-03-01', '2026-01-01');
igualOuDepois('igual', '2026-01-01', '2026-01-01');
igualOuDepois('antes', '2025-12-31', '2026-01-01');
igualOuDepois('data inválida (30/02)', '2026-02-30', '2026-01-01');
igualOuDepois('mínimo inválido', '2026-03-01', '2026-02-30');
const dias = calc('diasEntre');
dias('mesmo dia', '2026-07-04', '2026-07-04');
dias('um dia', '2026-07-04', '2026-07-05');
dias('nunca negativo', '2026-07-05', '2026-07-04');
dias('virada de ano', '2025-12-31', '2026-01-01');
dias('ano bissexto', '2028-02-01', '2028-03-01');
dias('início do horário de verão antigo', '2018-11-03', '2018-11-05');
dias('fim do horário de verão antigo', '2019-02-16', '2019-02-18');
dias('seis meses (exemplo do spec)', '2026-07-04', '2027-01-04');
const meses = calc('addMesesClampado');
meses('31/01 + 1 mês', '2026-01-31', 1);
meses('31/01 + 1 mês em ano bissexto', '2028-01-31', 1);
meses('31/01 + 13 meses', '2026-01-31', 13);
meses('30/11 + 3 meses', '2026-11-30', 3);
meses('zero meses', '2026-05-15', 0);
meses('virada de ano', '2026-12-15', 1);
meses('36 meses', '2026-02-28', 36);

/* ---------- correção e lucro ---------- */
const corr = calc('corrigido');
corr('mesmo dia', 10000, '2026-07-04', '2026-07-04', 1);
corr('taxa zero', 10000, '2026-07-04', '2027-07-04', 0);
corr('30 dias a 1%', 10000, '2026-07-04', '2026-08-03', 1);
corr('seis meses (exemplo do spec)', 10000, '2026-07-04', '2027-01-04', 1);
corr('gasto depois do fim conta pelo valor', 5000, '2026-08-01', '2026-07-01', 1.5);
corr('taxa máxima', 1234.56, '2020-01-01', '2026-10-06', 20);
const bruto = calc('totalBruto');
for(const o of BLOB.obras) bruto(o.nome, o);
const totalCorr = calc('totalCorrigido');
for(const o of BLOB.obras) for(const taxa of [1, 0.85, 20]) totalCorr(`${o.nome} a ${taxa}%`, o, taxa, HOJE);
totalCorr('vendida corrige até a venda, mesmo com outro hoje', O2, 1, '2030-01-01');
const lucro = calc('lucroVenda');
for(const o of BLOB.obras) lucro(o.nome, o, 1);
lucro('gasto depois da venda entra pelo valor', O2, 2);
const mesesObra = calc('mesesDeObra');
for(const o of BLOB.obras) mesesObra(o.nome, o, HOJE);
mesesObra('vendida para na venda', O2, '2030-01-01');
const m2 = calc('precoPorM2');
m2('normal', 3000000, 300);
m2('área decimal', 610000, 95.5);
m2('sem área', 500000, null);
m2('área zero', 500000, 0);
m2('valor zero', 0, 100);
m2('valor negativo', -10, 100);

/* ---------- TIR e simulador ---------- */
const tir = calc('tirMensal');
tir('obra com gastos espalhados', O1.gastos, 1250000, HOJE);
tir('vendida, gasto depois da venda conta como pago nela', O2.gastos, O2.venda.valor, O2.venda.data);
tir('daqui a 12 meses', O4.gastos, 610000, '2027-10-06');
tir('venda abaixo do custo (TIR negativa)', O4.gastos, 300000, HOJE);
tir('sem venda', O1.gastos, 0, HOJE);
tir('sem gastos', [], 100000, HOJE);
tir('nenhum mês passou', [{ id: 'x', valor: 1000, data: HOJE }], 2000, HOJE);
tir('sem raiz: venda menor que gasto feito no próprio dia', [{ id: 'x', valor: 1000, data: '2026-01-01' }, { id: 'y', valor: 5000, data: HOJE }], 3000, HOJE);
tir('sem raiz: venda absurda passa de 1000% ao mês', [{ id: 'x', valor: 1, data: '2026-01-01' }], 1e15, HOJE);
const acima = calc('rendimentoAcima');
acima('TIR acima do banco', 2.5, 1);
acima('TIR abaixo do banco', 0.4, 1);
acima('sem TIR', null, 1);
const resumo = calc('resumoVenda');
resumo('lucro', 1250000, 1000000);
resumo('prejuízo', 800000, 1000000);
resumo('venda zero', 0, 1000);
resumo('custo zero', 1000, 0);

/* ---------- séries dos gráficos ---------- */
const evo = calc('serieEvolucao');
for(const o of BLOB.obras) evo(o.nome, o, 1, HOJE);
evo('mais de 24 meses guarda só os últimos 24', { ...O2, venda: null, fase: 'construcao' }, 1, '2026-10-06');
evo('taxa alta', O4, 20, HOJE);
const mensal = calc('serieMensal');
for(const o of BLOB.obras) mensal(o.nome, o.gastos);
mensal('meses vazios no meio viram zero', [{ id: 'a', valor: 1, data: '2025-01-10' }, { id: 'b', valor: 2, data: '2025-04-02' }, { id: 'c', valor: 3, data: '2025-04-30' }]);
mensal('mais de 24 meses', [{ id: 'a', valor: 1, data: '2022-01-10' }, { id: 'b', valor: 2, data: '2025-04-02' }]);
mensal('ano 0050: o mês sai sem zeros e a série vai até a guarda de 600', [{ id: 'a', valor: 1, data: '0050-01-10' }, { id: 'b', valor: 2, data: '0050-03-02' }]);
const agregada = calc('serieEvolucaoAgregada');
agregada('todas as obras', BLOB.obras, 1, HOJE);
agregada('sem gastos', [O3], 1, HOJE);

/* ---------- a pagar, recentes e filtro ---------- */
const apagar = calc('aPagar');
apagar('janela de 30 dias', BLOB.obras, HOJE, 30);
apagar('padrão de 30 dias', BLOB.obras, HOJE);
apagar('limite exato no 30º dia', [{ id: 'z', gastos: [{ id: 'z1', valor: 100, data: '2026-08-05' }, { id: 'z2', valor: 200, data: '2026-08-06' }] }], '2026-07-06', 30);
apagar('mesmo dia não entra', [{ id: 'z', gastos: [{ id: 'z1', valor: 100, data: '2026-07-06' }] }], '2026-07-06', 30);
apagar('empate de data mantém a ordem das obras', [
  { id: 'p', gastos: [{ id: 'p1', valor: 1, data: '2026-07-10' }] },
  { id: 'q', gastos: [{ id: 'q1', valor: 2, data: '2026-07-10' }, { id: 'q2', valor: 3, data: '2026-07-08' }] }], '2026-07-06', 30);
const recentes = calc('gastosRecentes');
recentes('cinco mais recentes', BLOB.obras, 5);
recentes('padrão', BLOB.obras);
recentes('n negativo conta do fim, como o slice', BLOB.obras, -2);
recentes('desempate pelo id', [{ id: 'a', nome: 'A', gastos: [{ id: 'g1', valor: 1, data: '2026-01-02' }, { id: 'g3', valor: 3, data: '2026-01-02' }] },
  { id: 'b', nome: 'B', gastos: [{ id: 'g2', valor: 2, data: '2026-01-02' }] }], 2);
const acento = calc('semAcento');
for(const s of ['Mão de Obra', 'ÇÃO', 'pintura', '', 'Encanamento Hidráulico', 'Ünïcödé']) acento(JSON.stringify(s), s);
acento('nulo', null);
const filtra = calc('filtraGastos');
filtra('sem filtro', O1.gastos, TOPICOS_MAPA, null);
filtra('texto na descrição sem acento', O1.gastos, TOPICOS_MAPA, { texto: 'conexoes' });
filtra('texto no nome do tópico', O1.gastos, TOPICOS_MAPA, { texto: 'eletri' });
filtra('mês', O1.gastos, TOPICOS_MAPA, { mes: '2025-08' });
filtra('texto e mês', O1.gastos, TOPICOS_MAPA, { texto: 'tinta', mes: '2025-08' });
filtra('tópico próprio pelo nome', O4.gastos, TOPICOS_MAPA, { texto: 'automacao' });
filtra('tópico apagado busca pelo id', [{ id: 'k', valor: 1, topico: 'c_sumiu', descricao: '', data: '2026-01-01' }], TOPICOS_MAPA, { texto: 'c_sum' });
filtra('nada encontrado', O1.gastos, TOPICOS_MAPA, { texto: 'xyz' });

/* ---------- parcelas ---------- */
const parcelas = calc('gerarParcelas');
parcelas('resto de centavo na última', 100, 3, '2026-01-15');
parcelas('31/01 clampa em cada mês', 100, 3, '2026-01-31');
parcelas('uma parcela', 99.99, 1, '2026-05-10');
parcelas('mais parcelas que centavos', 0.02, 3, '2026-01-01');
parcelas('tantas parcelas quanto centavos', 0.03, 3, '2026-01-01');
parcelas('valor zero', 0, 2, '2026-01-01');
parcelas('n não inteiro', 100, 2.5, '2026-01-01');
parcelas('arredonda o total para centavos', 10.005, 2, '2026-01-01');
const cartao = calc('parcelamentoCartao');
cartao('sem juros', 1000, 3, 0, '2026-01-15');
cartao('com juros, última absorve o resto', 1000, 3, 2.5, '2026-01-15');
cartao('36x a 4,99%', 5432.1, 36, 4.99, '2026-01-31');
cartao('à vista no cartão', 250.5, 1, 3, '2026-02-10');
cartao('mais de 36 parcelas', 1000, 37, 0, '2026-01-15');
cartao('taxa acima de 100', 1000, 3, 101, '2026-01-15');
cartao('taxa negativa', 1000, 3, -1, '2026-01-15');
cartao('data inválida (30/02)', 1000, 3, 0, '2026-02-30');
cartao('valor zero', 0, 3, 0, '2026-01-15');
cartao('n não inteiro', 1000, 2.5, 0, '2026-01-15');

/* ---------- moeda: máscara, leitura e exibição ---------- */
const TEXTOS = ['', '0', '00', '007', '1.234', '1.234,56', '1,5', '1.5', '12.345', '1.2345', '-1.234', '1,2,3', '..5', '.5', '5.',
  '-', '-.5', '1-2', 'R$ 1.234,56', '  12 ', '1.234.567', '0,05', ',5', '12,', '1.000.000,00', '1e5', '99999999,999', 'abc', '1.234.5'];
const digitado = calc('fmtDigitado');
for(const t of TEXTOS) digitado(JSON.stringify(t), t);
digitado('número', 1234.5);
digitado('nulo', null);
const completo = calc('fmtCompleto');
for(const t of TEXTOS) completo(JSON.stringify(t), t);
const campo = calc('numParaCampo');
for(const n of [0, 1, 1234.5, 0.1 + 0.2, 99999999.99, 12.345, 100, 1e-7]) campo(String(n), n);
campo('nulo', null);
campo('texto vazio', '');
const ler = calc('parseNum');
for(const t of TEXTOS) ler(JSON.stringify(t), t);
ler('número passa direto', 12.5);
ler('nulo', null);
const money = calc('money');
for(const n of [0, 1, 1234.5, -1234.5, 0.125, 1.005, 2.675, 999.995, -0.001, 1234567.891, 99999999.99, 1e21]) money(String(n), n);
money('nulo', null);
const curto = calc('moneyShort');
for(const n of [0, 999.99, 1000, 1005, 8250, 9999, 10000, 12500, 999999, 1e6, 2.5e6, 9999999, 1e7, 10250000, 12350000, -1500, -500, 123456789])
  curto(String(n), n);
const semZero = calc('moneyCurto');
for(const n of [8000, 8500, 1e6, 1.5e6, 12e6, 500, 10000]) semZero(String(n), n);
const fmtMeses = calc('fmtMeses');
for(const m of [0, 0.99, 1, 1.4, 1.5, 2, 2.5, 12.7]) fmtMeses(String(m), m);

/* ---------- orçamento previsto × real ---------- */
const orc = calc('orcamentoObra');
for(const o of BLOB.obras) orc(o.nome, o);
const comOrcamento = (orcamento, gastos) => ({ ...O3, orcamento, gastos });
const g = (topico, valor, id = topico) => ({ id, valor, topico, descricao: '', data: '2026-01-01', pagamento: 'pix' });
orc('por tópico: passou, perto e sem gasto; fora separado', comOrcamento({ modo: 'topicos', topicos: { fundacao: 90000, estrutura: 250000, c_apagado: 1000 } },
  [g('fundacao', 98000), g('estrutura', 231000), g('hidraulica', 12000), g('pintura', 3000)]));
orc('meio centavo acima ainda não passou', comOrcamento({ modo: 'total', total: 1000 }, [g('pintura', 1000.004)]));
orc('mais de meio centavo passou', comOrcamento({ modo: 'total', total: 1000 }, [g('pintura', 1000.006)]));
orc('89,5% arredonda para perto', comOrcamento({ modo: 'total', total: 1000 }, [g('pintura', 895)]));
orc('empate de razão desempata pelo id', comOrcamento({ modo: 'topicos', topicos: { pintura: 100, eletrica: 200 } }, [g('pintura', 50), g('eletrica', 100)]));
orc('dois tópicos fora com o mesmo gasto desempatam pelo id', comOrcamento({ modo: 'topicos', topicos: { fundacao: 1000 } }, [g('fundacao', 500), g('pintura', 300), g('eletrica', 300)]));
orc('sem orçamento', O3);
orc('previsto zero some', comOrcamento({ modo: 'total', total: 0 }, []));

/* ---------- versão ---------- */
const versao = calc('versaoMaior');
versao('patch numérico', '1.0.10', '1.0.9');
versao('minor numérico', '1.2.0', '1.10.0');
versao('igual', '2.0.0', '2.0.0');
versao('maior major', '2.0.0', '1.99.99');
versao('inválida', 'abc', '1.0.0');
versao('sem a segunda', '1.0.0');
versao('dois números só', '1.0', '0.9.9');

/* ---------- comparação canônica ---------- */
const canon = calc('canon');
canon('chaves fora de ordem e aninhadas', { b: 1, a: [{ d: 1, c: 2 }], c: { z: null, y: true } });
canon('chaves numéricas vêm antes, em ordem numérica', { b: 1, '10': 2, '2': 3, a: 4, '01': 5, '-1': 6 });
canon('blob de exemplo', BLOB);
canon('unicode e escapes', { 'é': 'ção', 'a': 'aspas "x"', '😀': '\u0001\n' });

/* ---------- dados.js ---------- */
constante('dados.LIMITES', D.LIMITES);
const n = (nome, entrada) => caso('dados.normaliza', nome, [entrada], D.normaliza);
n('raiz nula', null);
n('raiz lista', []);
n('raiz texto', 'x');
n('blob vazio', {});
n('blob de exemplo já normalizado não muda', BLOB);
n('campo desconhecido em todo nível é preservado', {
  extra: { a: 1 },
  obras: [{ id: 'o', nome: 'Obra', dataInicio: '2026-01-01', fase: 'pronta', campoDoSite: [1, 2],
    venda: null, orcamento: { modo: 'total', total: 10, nota: 'x' },
    gastos: [{ id: 'g', valor: 1, topico: 'pintura', descricao: 'd', data: '2026-01-02', pagamento: 'pix', anexo: { url: 'u' },
      grupoId: 'gr', parcela: { n: 1, de: 2, extra: true } }],
    afazeres: [{ id: 'a', texto: 't', feito: true, prazo: '2026-02-01' }] }],
  config: { taxaMensal: 1, topicosCustom: [{ id: 'c_x', nm: 'X', ic: 'raio', cor: 'azul' }], futura: 1 },
});
n('taxa em texto com vírgula vira 1', { config: { taxaMensal: '1,5' } });
n('taxa em texto com ponto vale', { config: { taxaMensal: '1.5' } });
n('taxa hexadecimal em texto vale (Number do JavaScript)', { config: { taxaMensal: '0x2' } });
n('taxa com espaços vale', { config: { taxaMensal: ' 2 ' } });
n('taxa acima de 20 vira 1', { config: { taxaMensal: 25 } });
n('taxa zero vira 1', { config: { taxaMensal: 0 } });
n('taxa negativa vira 1', { config: { taxaMensal: -1 } });
n('taxa 20 vale', { config: { taxaMensal: 20 } });
n('taxa vazia vira 1', { config: { taxaMensal: '  ' } });
const obraCom = (campos, gastos = []) => ({ obras: [{ id: 'o', nome: 'Obra', dataInicio: '2026-01-01', gastos, ...campos }] });
n('obra vendida sem venda volta para construção', obraCom({ fase: 'vendida' }));
n('obra vendida com venda de data inválida volta para construção', obraCom({ fase: 'vendida', venda: { valor: 10, data: '2026-02-30' } }));
n('obra vendida com venda negativa volta para construção', obraCom({ fase: 'vendida', venda: { valor: -1, data: '2026-03-01' } }));
n('venda em texto vira número', obraCom({ fase: 'vendida', venda: { valor: '980000', data: '2026-03-01', obs: 'x' } }));
n('fase desconhecida vira construção', obraCom({ fase: 'demolida' }));
n('obra com data inválida (30/02) some', obraCom({ dataInicio: '2026-02-30' }));
n('obra sem id some', { obras: [{ nome: 'Sem id', dataInicio: '2026-01-01' }] });
n('ano 0050 vale para o dados.js', obraCom({ dataInicio: '0050-01-01' }));
n('id e nome numéricos viram texto', { obras: [{ id: 123, nome: 42, dataInicio: '2026-01-01' }, { id: 1.5, dataInicio: '2026-01-01' }] });
n('nome vazio vira "Obra sem nome"', obraCom({ nome: '' }));
n('estimado e área inválidos viram nulo', obraCom({ valorEstimadoVenda: -5, areaM2: 'abc' }));
n('estimado e área em texto viram número', obraCom({ valorEstimadoVenda: '500000', areaM2: '120.5' }));
n('itens que não são objeto saem da lista', { obras: [1, null, 'x', [], { id: 'o', dataInicio: '2026-01-01' }] });
n('obras que não é lista vira lista vazia', { obras: { id: 'o' } });
const gastoCom = campos => obraCom({}, [{ id: 'g', valor: 10, data: '2026-01-02', ...campos }]);
n('gasto com data 30/02 some', gastoCom({ data: '2026-02-30' }));
n('gasto sem id some', obraCom({}, [{ valor: 10, data: '2026-01-02' }]));
n('gasto negativo some', gastoCom({ valor: -5 }));
n('gasto zero fica', gastoCom({ valor: 0 }));
n('gasto em texto com ponto vira número', gastoCom({ valor: '1500.5' }));
n('gasto em texto com vírgula some', gastoCom({ valor: '1.234,56' }));
n('tópico e pagamento vazios ganham padrão', gastoCom({ topico: '', pagamento: '' }));
n('parcela inválida perde grupo e parcela', obraCom({}, [
  { id: 'g1', valor: 1, data: '2026-01-02', grupoId: 'gr', parcela: { n: 0, de: 3 } },
  { id: 'g2', valor: 1, data: '2026-01-02', grupoId: 'gr', parcela: { n: 3, de: 2 } },
  { id: 'g3', valor: 1, data: '2026-01-02', grupoId: 'gr', parcela: { n: 1.5, de: 3 } },
  { id: 'g4', valor: 1, data: '2026-01-02', grupoId: 'gr', parcela: 'x' },
  { id: 'g5', valor: 1, data: '2026-01-02', grupoId: 'gr' }]));
n('parcela válida sem grupo ganha grupo vazio', gastoCom({ parcela: { n: '2', de: '3' } }));
n('afazer: feito só com true exato; sem id some', obraCom({ afazeres: [
  { id: 'a1', texto: 'x', feito: 'true' }, { id: 'a2', texto: 5, feito: true }, { texto: 'sem id' }, { id: 'a3' }] }));
n('tópico próprio sem nome some; ícone vazio vira etiqueta', { config: { topicosCustom: [
  { id: 'c_a', nm: 'A', ic: '' }, { id: 'c_b', nm: '' }, { nm: 'Sem id' }, { id: 'c_c', nm: 'C' }] } });
n('orçamento por tópico descarta inválidos', obraCom({ orcamento: { modo: 'topicos', total: 9, topicos: {
  pintura: 1000, eletrica: '500', terreno: 0, hidraulica: -1, '  ': 10, ['x'.repeat(81)]: 10, ['y'.repeat(80)]: 7 } } }));
const cemMais = Object.fromEntries(Array.from({ length: 101 }, (_, i) => [`t${String(i).padStart(3, '0')}`, i + 1]));
n('orçamento por tópico guarda só os 100 primeiros', obraCom({ orcamento: { modo: 'topicos', topicos: cemMais } }));
n('id de tópico conta unidades UTF-16, como o length', obraCom({ orcamento: { modo: 'topicos', topicos: { ['😀'.repeat(40)]: 10, ['😀'.repeat(41)]: 20 } } }));
n('orçamento por tópico vazio some', obraCom({ orcamento: { modo: 'topicos', topicos: { pintura: 0 } } }));
n('orçamento total em texto', obraCom({ orcamento: { modo: 'total', total: '5000', topicos: { a: 1 } } }));
n('orçamento de modo desconhecido vira total', obraCom({ orcamento: { modo: 'xyz', total: 300 } }));
n('orçamento total zero some', obraCom({ orcamento: { modo: 'total', total: 0 } }));
n('orçamento que não é objeto some', obraCom({ orcamento: 'muito' }));

/* ---------- push.js e id ---------- */
for(const t of ['', 'a', 'abc', 'fcm-token:APA91bHun4MxP5egoKMwt2KZFBaFUH-1RYqx', 'https://fcm.googleapis.com/fcm/send/eXyZ', 'ç😀', 'x'.repeat(300)])
  caso('push.hashEndpoint', JSON.stringify(t.length > 40 ? t.slice(0, 40) + '…' : t), [t], P.hashEndpoint);
/* uid() do app.js: milissegundos em base 36 mais 4 letras aleatórias. Só o prefixo é fixo. */
for(const ms of [0, 35, 36, 1759750000000, 1700000000123, 4102444800000])
  caso('id.base36', String(ms), [ms], x => x.toString(36));

/* ---------- primitivas do JavaScript que as regras usam ---------- */
for(const x of [0, 1, -1, 0.1, 0.30000000000000004, 1e21, 1e-7, 1e-6, 123456789012345680000, 5e-324, 1.7976931348623157e308,
  100, 1500.5, 2 ** 53, 1 / 3, -1e-7, 12345.6789, 1e16, 1.5e300])
  caso('js.numeroParaTexto', String(x), [x], v => String(v));
for(const s of ['  12 ', '0x10', '0X1f', '1,5', '1e3', '1E-2', '.5', '5.', '+5', '-5', '-0x10', 'Infinity', '1_0', '0b11', '0o7',
  ' \u{a0}12\u{2028}', '\u{feff}3', '12abc', '', '   ', '0x', '1e', '.', '00012', '1.2.3', '0b2', '\t\n7\r', '1 2'])
  caso('js.textoParaNumero', JSON.stringify(s), [s], v => { const x = Number(v); return Number.isFinite(x) ? x : null; });
for(const [x, casas] of [[8.25, 1], [1.005, 2], [2.5, 0], [0.5, 0], [10.25, 1], [12.35, 1], [1.45, 1], [999.95, 1], [0.05, 1], [1.25, 1], [1234.5678, 2], [0, 2]])
  caso('js.toFixed', `${x}.toFixed(${casas})`, [x, casas], (v, c) => v.toFixed(c));
for(const x of [0.5, 1.5, 2.5, -0.5, -1.5, -2.5, 0.49999999999999994, 1e16 + 1, -0.4])
  caso('js.round', String(x), [x], v => Math.round(v) + 0); // + 0 tira o −0, que o JSON já não guarda
for(const v of ['', 'simples', 'aspas "x"', 'barra \\', 'linha\nnova', 'tab\tx', '\u0000\u0001\u001f', 'ção', '😀🏗️', '\u{2028}\u{2029}', '/', '\u007f',
  [1, 'a', null, true, 0.5]])
  caso('js.stringify', JSON.stringify(v), [v], x => JSON.stringify(x));
for(const s of [' a ', '\u{a0}a\u{a0}', '\u{feff}a\u{2028}', '\u{3000}a\u{205f}', 'a b', ''])
  caso('js.trim', JSON.stringify(s), [s], x => x.trim());

/* ---------- saída ---------- */
const vetores = { formato: 1, fuso: FUSO, gerador: 'scripts/vetores-calc.mjs', grupos };
const texto = JSON.stringify(vetores, null, 2) + '\n';
if(process.argv.includes('--imprimir')) process.stdout.write(texto);
else{
  writeFileSync(path.join(RAIZ, 'tests', 'vetores', 'calc.json'), texto);
  console.log(`tests/vetores/calc.json: ${Object.keys(grupos).length} grupos, ${Object.values(grupos).reduce((s, l) => s + l.length, 0)} casos`);
}
```

Gere o arquivo:

```bash
mkdir -p tests/vetores && npm run vetores
```

Expected: `tests/vetores/calc.json: 52 grupos, 513 casos`.

Em `CLAUDE.md`, na seção "Comandos", depois da linha do `npm run sonda:banco`, acrescente ao bloco:

```bash
npm run vetores          # regera tests/vetores/calc.json (casos de calc.js, dados.js e push.js que o app nativo confere)
```

e, logo abaixo do bloco, o parágrafo:

```markdown
**Vetores compartilhados.** O app nativo (`app-ios/`) reescreve em Swift as regras de `calc.js`, `dados.js` e a chave do token do `push.js`, e as confere contra `tests/vetores/calc.json`, gerado do código do site por `scripts/vetores-calc.mjs`. Mudou uma regra (ou exportou função nova) nesses arquivos: rode `npm run vetores` e faça commit do arquivo junto; `tests/vetores.test.mjs` falha enquanto ele estiver defasado, e o workflow `app-ios` mostra se o lado Swift precisa da mesma mudança.
```

- [ ] **Step 4: Rodar e ver passar**

Run: `node --test tests/vetores.test.mjs && npm run test:unit`
Expected: 4 testes verdes no primeiro; todos os arquivos verdes no segundo (o `docs.test.mjs` confere os links do `CLAUDE.md`).

- [ ] **Step 5: Commit**

```bash
git add scripts/vetores-calc.mjs tests/vetores/calc.json tests/vetores.test.mjs package.json CLAUDE.md
git commit -m "test: vetores compartilhados entre o site e o app nativo" -m "O gerador roda as funções de verdade do calc.js, do dados.js e do push.js sobre casos fixos (bordas do inventário: 30/02, 31/01 + 1 mês, gasto depois da venda, TIR sem raiz, resto de centavo, taxa em texto com vírgula, vendida sem venda, campo desconhecido) e grava entrada e saída em tests/vetores/calc.json. O teste do site falha se o arquivo ficar defasado do código ou se uma exportação do calc.js ficar sem vetor. O núcleo Swift do app nativo lê o mesmo arquivo; assim as duas cópias das regras não divergem sem um dos lados quebrar."
```

---

### Task 4: Pacote Swift, leitura dos vetores e job de CI

**Files:**
- Create: `app-ios/CusttaNucleo/Package.swift`
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/ValorJSON.swift`
- Create: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Vetores.swift`
- Create: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/VetoresTests.swift`
- Create: `.github/workflows/app-ios.yml`
- Modify: `.vercelignore`, `.gitignore`, `tests/workflow.test.cjs`, `package.json` (script `test:nucleo`), `CLAUDE.md` (linha do `test:nucleo`)

**Interfaces:**
- Consumes: `tests/vetores/calc.json` (Tarefa 3).
- Produces:
  - `public enum ValorJSON: Equatable, Hashable, Sendable, Codable { case nulo, booleano(Bool), numero(Double), texto(String), lista([ValorJSON]), objeto([String: ValorJSON]) }` com `comoTexto: String?`, `comoNumero: Double?`, `comoBooleano: Bool?`, `comoLista: [ValorJSON]?`, `comoObjeto: [String: ValorJSON]?`.
  - Nos testes: `struct CasoVetor { caso: String; args: [ValorJSON]; saida: ValorJSON; gerar: Gerar?; tamanho: Int?; func arg(_ i: Int) -> ValorJSON? }`, `Vetores.todos`, `Vetores.casos(_ grupo: String) -> [CasoVetor]`, `enum Tolerancia { case exata, dinheiro, continua }`, `func confere(_ obtido: ValorJSON, _ esperado: ValorJSON, _ tolerancia: Tolerancia, _ onde: String)`, `func opcional(_ n: Double?) -> ValorJSON`, e em `ValorJSON`: `numero: Double`, `textoOuNil: String?`, `numeroOuNil: Double?`.

- [ ] **Step 1: Escrever o pacote e o teste que falha**

Antes de qualquer `swift test`, acrescente ao `.gitignore`, depois do bloco do Capacitor (a saída do SwiftPM não pode entrar nem no `git add -N` da guarda da Vercel, no Step 2):

```gitignore
# Swift Package Manager e Xcode do app nativo (app-ios/)
app-ios/**/.build/
app-ios/**/.swiftpm/
app-ios/build/
app-ios/**/xcuserdata/
```

No `package.json`, acrescente o script:

```json
    "test:nucleo": "swift test --package-path app-ios/CusttaNucleo",
```

e, no `CLAUDE.md`, logo depois da linha do `npm run vetores` no bloco de "Comandos":

```bash
npm run test:nucleo      # swift test do núcleo do app nativo (app-ios/CusttaNucleo), só no Mac
```

`app-ios/CusttaNucleo/Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

/* Núcleo do Custta nativo: cálculo, modelo, normalização e sincronização, sem tela e sem
   Firebase. Roda com `swift test` no Mac; o app (app-ios/Custta.xcodeproj) o usa como pacote local. */
let package = Package(
    name: "CusttaNucleo",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "CusttaNucleo", targets: ["CusttaNucleo"])],
    targets: [
        .target(name: "CusttaNucleo"),
        .testTarget(name: "CusttaNucleoTests", dependencies: ["CusttaNucleo"]),
    ]
)
```

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Vetores.swift`:

```swift
import Foundation
import Testing
@testable import CusttaNucleo

/* Leitura de tests/vetores/calc.json (gerado do site por scripts/vetores-calc.mjs) e as
   comparações que os testes usam. Dinheiro bate no centavo; valor contínuo (taxa, TIR, meses)
   com tolerância relativa de 1e-9; texto, booleano e inteiro, exatos. */

struct CasoVetor: Decodable, Sendable {
    let caso: String
    let args: [ValorJSON]
    let saida: ValorJSON
    let gerar: Gerar?
    let tamanho: Int?

    struct Gerar: Decodable, Sendable {
        let base: ValorJSON
        let campo: String
        let letra: String
        let vezes: Int
    }

    enum CodingKeys: String, CodingKey { case caso, args, saida, gerar, tamanho }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        caso = try c.decode(String.self, forKey: .caso)
        args = try c.decodeIfPresent([ValorJSON].self, forKey: .args) ?? []
        saida = try c.decode(ValorJSON.self, forKey: .saida)
        gerar = try c.decodeIfPresent(Gerar.self, forKey: .gerar)
        tamanho = try c.decodeIfPresent(Int.self, forKey: .tamanho)
    }

    /// Argumento i; nil quando o caso chamou a função com menos argumentos (o undefined do JavaScript).
    func arg(_ i: Int) -> ValorJSON? { i < args.count ? args[i] : nil }
}

struct Vetores: Decodable, Sendable {
    let formato: Int
    let fuso: String
    let grupos: [String: [CasoVetor]]

    /// app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ → raiz do repositório → tests/vetores/calc.json
    static let arquivo: URL = {
        var u = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { u.deleteLastPathComponent() }
        return u.appending(path: "tests/vetores/calc.json")
    }()

    static let todos: Vetores = {
        do { return try JSONDecoder().decode(Vetores.self, from: Data(contentsOf: arquivo)) }
        catch { fatalError("não li \(arquivo.path): \(error)") }
    }()

    static func casos(_ grupo: String) -> [CasoVetor] {
        let l = todos.grupos[grupo] ?? []
        if l.isEmpty { Issue.record("grupo \(grupo) sem casos em tests/vetores/calc.json") }
        return l
    }
}

enum Tolerancia { case exata, dinheiro, continua }

func confere(_ obtido: ValorJSON, _ esperado: ValorJSON, _ tolerancia: Tolerancia, _ onde: String,
             sourceLocation: SourceLocation = #_sourceLocation) {
    switch (obtido, esperado) {
    case let (.numero(a), .numero(b)):
        let ok: Bool = switch tolerancia {
        case .exata: a == b
        case .dinheiro: abs(a - b) < 0.005
        case .continua: a == b || abs(a - b) <= max(1e-9 * max(abs(a), abs(b)), 1e-12)   // piso: perto de zero o relativo não fecha
        }
        #expect(ok, "\(onde): obtido \(a), esperado \(b)", sourceLocation: sourceLocation)
    case let (.lista(a), .lista(b)):
        #expect(a.count == b.count, "\(onde): \(a.count) itens, esperado \(b.count)", sourceLocation: sourceLocation)
        for (i, (x, y)) in zip(a, b).enumerated() { confere(x, y, tolerancia, "\(onde)[\(i)]", sourceLocation: sourceLocation) }
    case let (.objeto(a), .objeto(b)):
        #expect(Set(a.keys) == Set(b.keys), "\(onde): chaves \(a.keys.sorted()), esperado \(b.keys.sorted())", sourceLocation: sourceLocation)
        for (k, y) in b { if let x = a[k] { confere(x, y, tolerancia, "\(onde).\(k)", sourceLocation: sourceLocation) } }
    default:
        #expect(obtido == esperado, "\(onde): obtido \(obtido), esperado \(esperado)", sourceLocation: sourceLocation)
    }
}

/// Número opcional do Swift na forma do JavaScript (null quando nil).
func opcional(_ n: Double?) -> ValorJSON { n.map(ValorJSON.numero) ?? .nulo }

extension ValorJSON {
    var numero: Double { comoNumero ?? .nan }
    var textoOuNil: String? { comoTexto }
    var numeroOuNil: Double? { comoNumero }
}
```

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/VetoresTests.swift`:

```swift
import Foundation
import Testing
@testable import CusttaNucleo

struct VetoresTests {
    @Test func arquivoDoSiteLidoPeloNucleo() {
        #expect(Vetores.todos.formato == 1)
        #expect(Vetores.todos.fuso == "America/Sao_Paulo")
        #expect(Vetores.casos("calc.DIAS_MES").first?.saida == .numero(30.44))
    }

    @Test func valorJSONLeOQueOJavaScriptEscreve() throws {
        let texto = #"{"a":[1,2.5,"x",true,null,{"b":{}}],"c":-0.001}"#
        let v = try JSONDecoder().decode(ValorJSON.self, from: Data(texto.utf8))
        #expect(v == .objeto(["a": .lista([.numero(1), .numero(2.5), .texto("x"), .booleano(true), .nulo, .objeto(["b": .objeto([:])])]),
                              "c": .numero(-0.001)]))
        #expect(v.comoObjeto?["a"]?.comoLista?.count == 6)
        #expect(ValorJSON.texto("x").comoNumero == nil)
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo`
Expected: FAIL com `target 'CusttaNucleo' referenced in product 'CusttaNucleo' is empty` (o alvo ainda não tem nenhuma fonte).

Run também: `node tests/vercel.test.cjs`
Expected: FAIL com `app-ios/CusttaNucleo/Package.swift iria para produção…` só depois do `git add` do Step 5; antes disso o arquivo não está versionado. Para ver a guarda agora: `git add -N app-ios && node tests/vercel.test.cjs` (o `-N` marca a intenção sem preparar o conteúdo) e depois `git reset app-ios`.

- [ ] **Step 3: Escrever o ValorJSON, o `.vercelignore` e o job de CI**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/ValorJSON.swift`:

```swift
import Foundation

/// Valor do documento `dados/{uid}` como o JavaScript o vê. O modelo lê e escreve por cima
/// desta árvore, então campo que o app não conhece volta intacto para o banco.
/// Número é sempre `Double`, como no JavaScript: inteiro e decimal vindos do Firestore viram o mesmo caso.
public enum ValorJSON: Equatable, Hashable, Sendable {
    case nulo
    case booleano(Bool)
    case numero(Double)
    case texto(String)
    case lista([ValorJSON])
    case objeto([String: ValorJSON])
}

public extension ValorJSON {
    var comoTexto: String? { if case .texto(let s) = self { return s }; return nil }
    var comoNumero: Double? { if case .numero(let n) = self { return n }; return nil }
    var comoBooleano: Bool? { if case .booleano(let b) = self { return b }; return nil }
    var comoLista: [ValorJSON]? { if case .lista(let l) = self { return l }; return nil }
    var comoObjeto: [String: ValorJSON]? { if case .objeto(let o) = self { return o }; return nil }
}

extension ValorJSON: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .nulo }
        else if let b = try? c.decode(Bool.self) { self = .booleano(b) }
        else if let n = try? c.decode(Double.self) { self = .numero(n) }
        else if let s = try? c.decode(String.self) { self = .texto(s) }
        else if let l = try? c.decode([ValorJSON].self) { self = .lista(l) }
        else { self = .objeto(try c.decode([String: ValorJSON].self)) }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .nulo: try c.encodeNil()
        case .booleano(let b): try c.encode(b)
        case .numero(let n): try c.encode(n)
        case .texto(let s): try c.encode(s)
        case .lista(let l): try c.encode(l)
        case .objeto(let o): try c.encode(o)
        }
    }
}
```

Em `.vercelignore`, depois da linha `www/`, acrescente `app-ios/`.

`.github/workflows/app-ios.yml`:

```yaml
name: app-ios
# App nativo em SwiftUI (app-ios/). O job nucleo roda o swift test do pacote CusttaNucleo, que confere
# as regras reescritas em Swift contra os vetores gerados do site (tests/vetores/calc.json): por isso
# também dispara quando calc.js, dados.js, push.js ou o gerador mudam.
#
# Por que macos-26 fixo, e não macos-latest: o pacote pede Swift 6.2 (Xcode 26); trocar de imagem
# tem de ser decisão, não surpresa no meio de um PR. Pelo mesmo motivo o Xcode é fixo (DEVELOPER_DIR):
# o padrão do runner muda sem aviso.
on:
  pull_request:
    paths:
      - 'app-ios/**'
      - 'calc.js'
      - 'dados.js'
      - 'push.js'
      - 'scripts/vetores-calc.mjs'
      - 'tests/vetores/**'
      - '.github/workflows/app-ios.yml'
  workflow_dispatch:

permissions:
  contents: read

env:
  DEVELOPER_DIR: /Applications/Xcode_26.6.app/Contents/Developer

concurrency:
  group: app-ios-${{ github.ref }}
  cancel-in-progress: true

jobs:
  nucleo:
    runs-on: macos-26
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      # Fica no log: o runner troca de Xcode com o tempo e é a primeira coisa a conferir
      # quando um teste que passava começa a quebrar sozinho.
      - name: Versão do Xcode e do Swift
        run: |
          xcodebuild -version
          swift --version

      - name: Núcleo contra os vetores do site
        env:
          TZ: America/Sao_Paulo
        run: swift test --package-path app-ios/CusttaNucleo
```

Em `tests/workflow.test.cjs`, antes do `console.log` final:

```js
/* App nativo (app-ios/): o núcleo roda swift test contra os vetores do site num macOS fixo. */
const appIos = readFileSync(join(dir, 'app-ios.yml'), 'utf8');
assert.match(appIos, /runs-on:\s*macos-26/, 'o app nativo precisa do runner macOS 26 (Xcode 26)');
assert.match(appIos, /swift test --package-path app-ios\/CusttaNucleo/, 'sem o swift test do núcleo');
assert.match(appIos, /TZ:\s*America\/Sao_Paulo/, 'os testes do núcleo rodam no fuso dos vetores');
assert.match(appIos, /DEVELOPER_DIR:\s*\/Applications\/Xcode_26\.6\.app\/Contents\/Developer/, 'o Xcode da CI é fixo: o padrão do runner muda sem aviso');
for(const caminho of ['app-ios/**', 'calc.js', 'dados.js', 'push.js', 'scripts/vetores-calc.mjs', 'tests/vetores/**'])
  assert.ok(appIos.includes(`- '${caminho}'`), `app-ios.yml não dispara quando ${caminho} muda`);
assert.ok(!/^on:\n(?:.*\n)*?\s{2}push:/m.test(appIos), 'o app nativo não roda em todo push');
assert.match(appIos, /workflow_dispatch:/, 'o app nativo precisa do botão manual');
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo && git add -N app-ios .github/workflows/app-ios.yml && node tests/vercel.test.cjs && node tests/workflow.test.cjs && git reset app-ios .github/workflows/app-ios.yml`
Expected: `Test run with 2 tests … passed`; `ok - deploy leva só o app…`; `ok - Actions com SHA imutável…`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo .vercelignore .gitignore package.json CLAUDE.md
git commit -m "feat: pacote do núcleo do app nativo lendo os vetores do site" -m "Pacote Swift local em app-ios/CusttaNucleo (iOS 26, roda com swift test no Mac, npm run test:nucleo) com a árvore JSON do documento e a leitura de tests/vetores/calc.json nos testes. app-ios/ sai do deploy da Vercel e a saída do SwiftPM fica fora do git."
git add .github/workflows/app-ios.yml tests/workflow.test.cjs
git commit -m "ci: núcleo do app nativo contra os vetores do site" -m "O workflow app-ios roda o swift test num macOS 26 com o Xcode 26.6 fixo sempre que o núcleo, as regras do site ou os vetores mudam. A guarda do workflow.test.cjs confere runner, Xcode, fuso e os caminhos que disparam."
```

Depois dos dois commits, o Orquestrador empurra e abre o PR 3 como rascunho (decisão "Xcode da CI"): a partir daqui cada tarefa empurra e o job `nucleo` confere o Swift no Xcode da CI.

---

### Task 5: Primitivas do JavaScript

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/NumeroJS.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PrimitivasJSTests.swift`

**Interfaces:**
- Consumes: `ValorJSON` (Tarefa 4).
- Produces:
  - `func digitosMaisCurtos(_ x: Double) -> (digitos: String, n: Int)` (interno)
  - `public func numeroJS(_ x: Double) -> String` — `String(numero)` do JavaScript
  - `public func arredondarJS(_ x: Double) -> Double` — `Math.round`
  - `public func toFixedJS(_ x: Double, _ casas: Int) -> String` — `toFixed`
  - `func ehEspacoJS(_ u: Unicode.Scalar) -> Bool`, `func ehDigito(_ u: Unicode.Scalar) -> Bool` (internos)
  - `public func aparadoJS(_ s: String) -> String` — `trim`
  - `public func numeroDeTextoJS(_ texto: String) -> Double` — `Number(texto)`
  - `func parseFloatJS(_ s: String) -> Double?` (interno)
  - `public func verdadeiroJS(_ v: ValorJSON?) -> Bool` — `if (v)`
  - `public func paraNumeroJS(_ v: ValorJSON?) -> Double` — `Number(v)`

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PrimitivasJSTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/* As primitivas do JavaScript que o site usa, conferidas contra o próprio JavaScript (grupos js.*). */
struct PrimitivasJSTests {
    @Test func numeroParaTexto() {
        for c in Vetores.casos("js.numeroParaTexto") {
            #expect(numeroJS(c.args[0].numero) == c.saida.comoTexto, "\(c.caso)")
        }
        #expect(numeroJS(-0.0) == "0")
        #expect(numeroJS(.nan) == "NaN")
    }

    @Test func textoParaNumero() {
        for c in Vetores.casos("js.textoParaNumero") {
            let n = numeroDeTextoJS(c.args[0].comoTexto!)
            confere(n.isFinite ? .numero(n) : .nulo, c.saida, .exata, c.caso)
        }
    }

    @Test func toFixed() {
        for c in Vetores.casos("js.toFixed") {
            #expect(toFixedJS(c.args[0].numero, Int(c.args[1].numero)) == c.saida.comoTexto, "\(c.caso)")
        }
    }

    @Test func mathRound() {
        for c in Vetores.casos("js.round") {
            confere(.numero(arredondarJS(c.args[0].numero)), c.saida, .exata, c.caso)
        }
    }

    @Test func trim() {
        for c in Vetores.casos("js.trim") {
            #expect(aparadoJS(c.args[0].comoTexto!) == c.saida.comoTexto, "\(c.caso)")
        }
    }

    @Test func verdadeiroComoNoJavaScript() {
        #expect(!verdadeiroJS(nil))
        #expect(!verdadeiroJS(.nulo))
        #expect(!verdadeiroJS(.numero(0)))
        #expect(!verdadeiroJS(.numero(.nan)))
        #expect(!verdadeiroJS(.texto("")))
        #expect(!verdadeiroJS(.booleano(false)))
        #expect(verdadeiroJS(.numero(-1)))
        #expect(verdadeiroJS(.texto("0")))
        #expect(verdadeiroJS(.lista([])))
        #expect(verdadeiroJS(.objeto([:])))
    }

    @Test func numeroDeValorComoNoJavaScript() {
        #expect(paraNumeroJS(nil).isNaN)
        #expect(paraNumeroJS(.nulo) == 0)
        #expect(paraNumeroJS(.booleano(true)) == 1)
        #expect(paraNumeroJS(.texto(" 3 ")) == 3)
        #expect(paraNumeroJS(.texto("abc")).isNaN)
    }

    /// Saídas do Number() do Node para as mesmas listas.
    @Test func numeroDeListaComoNoJavaScript() {
        #expect(paraNumeroJS(.lista([])) == 0)
        #expect(paraNumeroJS(.lista([.numero(7)])) == 7)
        #expect(paraNumeroJS(.lista([.texto(" 8 ")])) == 8)
        #expect(paraNumeroJS(.lista([.lista([.numero(9)])])) == 9)
        #expect(paraNumeroJS(.lista([.nulo])) == 0)
        #expect(paraNumeroJS(.lista([.numero(1), .numero(2)])).isNaN)
        #expect(paraNumeroJS(.lista([.booleano(true)])).isNaN)
        #expect(paraNumeroJS(.objeto([:])).isNaN)
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter PrimitivasJSTests`
Expected: FAIL na compilação: `cannot find 'numeroJS' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/NumeroJS.swift`:

```swift
import Foundation

/* Primitivas do JavaScript que as regras do site usam e que o Swift faz diferente.
   Cada uma é conferida contra o próprio JavaScript pelos grupos `js.*` dos vetores. */

/// Dígitos decimais mais curtos que voltam ao mesmo Double e o expoente `n` do ECMAScript
/// (x = 0.d1d2…dk × 10^n, d1 ≠ 0). Vêm de `description`, que já é a representação mais
/// curta e, no empate, a mais próxima: a mesma escolha do JavaScript.
func digitosMaisCurtos(_ x: Double) -> (digitos: String, n: Int) {
    let s = x.description                     // "1500.0", "0.1", "1e-07", "1.25e+20"
    var mantissa = Substring(s)
    var expoente = 0
    if let e = s.firstIndex(where: { $0 == "e" || $0 == "E" }) {
        mantissa = s[..<e]
        expoente = Int(s[s.index(after: e)...])!
    }
    var inteiro = mantissa
    var fracao: Substring = ""
    if let p = mantissa.firstIndex(of: ".") {
        inteiro = mantissa[..<p]
        fracao = mantissa[mantissa.index(after: p)...]
    }
    var digitos = String(inteiro) + String(fracao)
    var n = inteiro.count + expoente
    while digitos.count > 1, digitos.first == "0" { digitos.removeFirst(); n -= 1 }
    while digitos.count > 1, digitos.last == "0" { digitos.removeLast() }
    return (digitos, n)
}

/// `String(numero)` do JavaScript (Number::toString do ECMAScript).
public func numeroJS(_ x: Double) -> String {
    if x.isNaN { return "NaN" }
    if x == 0 { return "0" }
    if x.isInfinite { return x < 0 ? "-Infinity" : "Infinity" }
    if x < 0 { return "-" + numeroJS(-x) }
    let (d, n) = digitosMaisCurtos(x)
    let k = d.count
    if k <= n && n <= 21 { return d + String(repeating: "0", count: n - k) }
    if 0 < n && n <= 21 {
        let i = d.index(d.startIndex, offsetBy: n)
        return String(d[..<i]) + "." + String(d[i...])
    }
    if -6 < n && n <= 0 { return "0." + String(repeating: "0", count: -n) + d }
    let e = n - 1
    let resto = d.dropFirst()
    return String(d.prefix(1)) + (resto.isEmpty ? "" : "." + resto) + "e" + (e < 0 ? "-" : "+") + String(abs(e))
}

/// `Math.round` do JavaScript: o meio vai para +infinito (o `rounded()` do Swift leva para longe do zero).
public func arredondarJS(_ x: Double) -> Double {
    let piso = x.rounded(.down)
    return x - piso >= 0.5 ? piso + 1 : piso
}

/// `numero.toFixed(casas)` do JavaScript para casas de 0 a 2, as que o site usa: arredonda pelo valor
/// binário exato e, no empate exato, fica com o maior (8.25 → "8.3", 1.005 → "1.00"). Com mais casas,
/// valor grande estouraria os 128 bits da conta.
public func toFixedJS(_ x: Double, _ casas: Int) -> String {
    precondition((0...2).contains(casas), "toFixedJS: casas de 0 a 2")
    if x.isNaN { return "NaN" }
    if abs(x) >= 1e21 { return numeroJS(x) }
    let negativo = x < 0
    let v = abs(x)
    var potencia: UInt128 = 1
    for _ in 0..<casas { potencia *= 10 }
    var n: UInt128 = 0
    if v != 0 && v.isNormal {
        let m = UInt128((UInt64(1) << 52) | v.significandBitPattern)   // v = m × 2^e, exato
        let e = Int(v.exponent) - 52
        let produto = m * potencia
        if e >= 0 {
            n = produto << UInt128(e)
        } else if -e < 120 {
            let k = UInt128(-e)
            let q = produto >> k
            let resto = produto - (q << k)
            n = resto << 1 >= (UInt128(1) << k) ? q + 1 : q
        }
    }
    var texto = String(n)
    if casas > 0 {
        if texto.count <= casas { texto = String(repeating: "0", count: casas + 1 - texto.count) + texto }
        texto.insert(".", at: texto.index(texto.endIndex, offsetBy: -casas))
    }
    return (negativo ? "-" : "") + texto
}

/// Espaço para o JavaScript (`trim`, `\s`): WhiteSpace e LineTerminator do ECMAScript.
func ehEspacoJS(_ u: Unicode.Scalar) -> Bool {
    switch u.value {
    case 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x20, 0xA0, 0x1680, 0x2000...0x200A,
         0x2028, 0x2029, 0x202F, 0x205F, 0x3000, 0xFEFF: return true
    default: return false
    }
}

/// Dígito para o `\d` do JavaScript: só 0 a 9 do ASCII.
func ehDigito(_ u: Unicode.Scalar) -> Bool { (0x30...0x39).contains(u.value) }

/// `texto.trim()` do JavaScript.
public func aparadoJS(_ s: String) -> String {
    let u = Array(s.unicodeScalars)
    guard let ini = u.firstIndex(where: { !ehEspacoJS($0) }) else { return "" }
    let fim = u.lastIndex(where: { !ehEspacoJS($0) })!
    var r = String.UnicodeScalarView()
    r.append(contentsOf: u[ini...fim])
    return String(r)
}

/// `Number(texto)` do JavaScript: vazio (depois do trim) vale 0; aceita hexadecimal, octal e
/// binário sem sinal, decimal com expoente e "Infinity"; o resto vale NaN.
public func numeroDeTextoJS(_ texto: String) -> Double {
    let t = Array(aparadoJS(texto).unicodeScalars)
    if t.isEmpty { return 0 }
    if t.count > 2, t[0] == "0" {
        let base: Int? = switch t[1] { case "x", "X": 16; case "o", "O": 8; case "b", "B": 2; default: nil }
        if let base {
            var valor = 0.0
            for u in t[2...] {
                guard let d = Int(String(u), radix: base) else { return .nan }
                valor = valor * Double(base) + Double(d)
            }
            return valor
        }
    }
    var i = 0
    var negativo = false
    if t[i] == "+" || t[i] == "-" { negativo = t[i] == "-"; i += 1 }
    if Array(t[i...]) == Array("Infinity".unicodeScalars) { return negativo ? -.infinity : .infinity }
    var inteiros = "", fracao = ""
    while i < t.count, ehDigito(t[i]) { inteiros.unicodeScalars.append(t[i]); i += 1 }
    if i < t.count, t[i] == "." {
        i += 1
        while i < t.count, ehDigito(t[i]) { fracao.unicodeScalars.append(t[i]); i += 1 }
    }
    if inteiros.isEmpty && fracao.isEmpty { return .nan }
    var expoente = ""
    if i < t.count, t[i] == "e" || t[i] == "E" {
        i += 1
        if i < t.count, t[i] == "+" || t[i] == "-" { expoente.unicodeScalars.append(t[i]); i += 1 }
        var digitos = 0
        while i < t.count, ehDigito(t[i]) { expoente.unicodeScalars.append(t[i]); i += 1; digitos += 1 }
        if digitos == 0 { return .nan }
    }
    if i != t.count { return .nan }
    let literal = (negativo ? "-" : "") + (inteiros.isEmpty ? "0" : inteiros) + "." + (fracao.isEmpty ? "0" : fracao)
        + (expoente.isEmpty ? "" : "e" + expoente)
    return Double(literal) ?? .nan
}

/// `parseFloat` do JavaScript sobre o que sobra no parseNum (dígitos, ponto e sinal): lê o maior
/// prefixo decimal; sem dígito nenhum devolve nil (o NaN do JavaScript).
func parseFloatJS(_ s: String) -> Double? {
    let t = Array(s.unicodeScalars)
    var i = 0
    var sinal = ""
    if i < t.count, t[i] == "-" || t[i] == "+" { sinal.unicodeScalars.append(t[i]); i += 1 }
    var inteiros = "", fracao = ""
    while i < t.count, ehDigito(t[i]) { inteiros.unicodeScalars.append(t[i]); i += 1 }
    if i < t.count, t[i] == "." {
        i += 1
        while i < t.count, ehDigito(t[i]) { fracao.unicodeScalars.append(t[i]); i += 1 }
    }
    if inteiros.isEmpty && fracao.isEmpty { return nil }
    return Double(sinal + (inteiros.isEmpty ? "0" : inteiros) + (fracao.isEmpty ? "" : "." + fracao))
}

/// Valor "verdadeiro" do JavaScript (`if (v)`). `nil` faz papel de `undefined`.
public func verdadeiroJS(_ v: ValorJSON?) -> Bool {
    switch v {
    case nil, .nulo?: return false
    case .booleano(let b)?: return b
    case .numero(let n)?: return n != 0 && !n.isNaN
    case .texto(let s)?: return !s.isEmpty
    case .lista?, .objeto?: return true
    }
}

/// `Number(v)` do JavaScript para os tipos que chegam do documento. Lista passa pelo texto, como o
/// ToPrimitive do JavaScript: `Number([])` é 0, `Number([7])` é 7, `Number([1, 2])` é NaN.
public func paraNumeroJS(_ v: ValorJSON?) -> Double {
    switch v {
    case nil: return .nan
    case .nulo?: return 0
    case .booleano(let b)?: return b ? 1 : 0
    case .numero(let n)?: return n
    case .texto(let s)?: return numeroDeTextoJS(s)
    case .lista(let l)?: return numeroDeTextoJS(textoDeListaJS(l))
    case .objeto?: return .nan
    }
}

/// `String(lista)` do JavaScript (`join(",")`): null vira "", objeto vira "[object Object]".
func textoDeListaJS(_ l: [ValorJSON]) -> String {
    l.map { v -> String in
        switch v {
        case .nulo: return ""
        case .booleano(let b): return b ? "true" : "false"
        case .numero(let n): return numeroJS(n)
        case .texto(let s): return s
        case .lista(let sub): return textoDeListaJS(sub)
        case .objeto: return "[object Object]"
        }
    }.joined(separator: ",")
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter PrimitivasJSTests`
Expected: `Test run with 8 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: primitivas do JavaScript no núcleo do app nativo" -m "String(numero), Math.round, toFixed, trim e Number(texto) do JavaScript reescritos em Swift e conferidos contra o próprio JavaScript pelos vetores. O Swift arredonda e formata diferente (o meio do rounded vai para longe do zero, o String(format:) empata para o par), e as regras do site dependem desses detalhes."
```

---

### Task 6: JSON igual ao do site, tamanho do blob e ponte com o Foundation

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/SerializadorJS.swift`
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/ValorJSON+Foundation.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SerializadorTests.swift`

**Interfaces:**
- Consumes: `numeroJS` (Tarefa 5), `ValorJSON`.
- Produces:
  - `public let limiteBlob = 900_000` e `public let avisoBlob = 700_000`
  - `public func menorJS(_ a: String, _ b: String) -> Bool` — `<` e `sort()` do JavaScript (UTF-16)
  - `func ordemCanonica(_ chaves: [String]) -> [String]` (interno)
  - `public func canonico(_ v: ValorJSON) -> String` — `canon()`
  - `public func mesmoConteudo(_ a: ValorJSON, _ b: ValorJSON) -> Bool`
  - `public func tamanhoBlob(_ v: ValorJSON) -> Int`
  - `public func blobCabe(_ v: ValorJSON) -> Bool`
  - `extension ValorJSON { public init?(foundation valor: Any); public var paraFoundation: Any }`

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SerializadorTests.swift`:

```swift
import Foundation
import Testing
@testable import CusttaNucleo

struct SerializadorTests {
    @Test func canonIgualAoDoSite() {
        for c in Vetores.casos("calc.canon") {
            #expect(canonico(c.args[0]) == c.saida.comoTexto, "\(c.caso)")
        }
    }

    @Test func stringifyDePrimitivasIgualAoDoSite() {
        for c in Vetores.casos("js.stringify") {
            #expect(canonico(c.args[0]) == c.saida.comoTexto, "\(c.caso)")
        }
    }

    @Test func tamanhoDoBlobIgualAoDoSite() {
        for c in Vetores.casos("calc.tamanhoBlob") {
            #expect(Double(tamanhoBlob(c.args[0])) == c.saida.comoNumero, "\(c.caso)")
        }
    }

    @Test func limiteDoBlob() {
        #expect(Double(limiteBlob) == Vetores.casos("calc.LIMITE_BLOB").first?.saida.comoNumero)
        #expect(Double(avisoBlob) == Vetores.casos("calc.AVISO_BLOB").first?.saida.comoNumero)
        for c in Vetores.casos("calc.blobCabe") {
            var blob = c.args.first ?? .nulo
            if let g = c.gerar {
                var base = g.base.comoObjeto!
                base[g.campo] = .texto(String(repeating: g.letra, count: g.vezes))
                blob = .objeto(base)
                #expect(tamanhoBlob(blob) == c.tamanho, "\(c.caso): tamanho montado")
            }
            #expect(blobCabe(blob) == c.saida.comoBooleano, "\(c.caso)")
        }
    }

    @Test func mesmoConteudoIgnoraOrdemEIgualaNumeroInteiroEDecimal() {
        #expect(mesmoConteudo(.objeto(["a": .numero(1), "b": .lista([])]), .objeto(["b": .lista([]), "a": .numero(1.0)])))
        #expect(!mesmoConteudo(.objeto(["a": .numero(1)]), .objeto(["a": .texto("1")])))
    }

    @Test func pontesComOFoundation() throws {
        let foundation: [String: Any] = ["inteiro": NSNumber(value: Int64(1500)), "decimal": NSNumber(value: 1500.5),
                                         "verdade": NSNumber(value: true), "texto": "ção", "nulo": NSNull(),
                                         "lista": [NSNumber(value: 1), "x"], "objeto": ["a": NSNumber(value: false)]]
        let v = try #require(ValorJSON(foundation: foundation))
        #expect(v == .objeto(["inteiro": .numero(1500), "decimal": .numero(1500.5), "verdade": .booleano(true), "texto": .texto("ção"),
                              "nulo": .nulo, "lista": .lista([.numero(1), .texto("x")]), "objeto": .objeto(["a": .booleano(false)])]))
        #expect(ValorJSON(foundation: Date()) == nil, "tipo que o JSON não tem fica para quem chama")
        #expect(ValorJSON(foundation: ["obras": [["quando": Date()]]]) == nil,
                "dentro do blob também: virar null apagaria o dado na próxima gravação, que reescreve o documento inteiro")
        #expect(ValorJSON(foundation: [NSNumber(value: 1), Data()]) == nil)

        let volta = try #require(ValorJSON.objeto(["i": .numero(1500), "d": .numero(1500.5), "grande": .numero(9_007_199_254_740_992),
                                                   "menosZero": .numero(-0.0), "b": .booleano(true)]).paraFoundation as? [String: Any])
        #expect(volta["i"] as? Int64 == 1500, "inteiro seguro vai como inteiro, como o SDK JavaScript grava")
        #expect(volta["d"] as? Double == 1500.5)
        #expect(volta["grande"] as? Double == 9_007_199_254_740_992, "acima de 2^53 − 1 vai como decimal")
        #expect((volta["menosZero"] as? Double)?.sign == .minus)
        #expect(volta["b"] as? Bool == true)
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter SerializadorTests`
Expected: FAIL na compilação: `cannot find 'canonico' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/SerializadorJS.swift`:

```swift
import Foundation

/* JSON igual ao JSON.stringify do site, byte a byte, e a forma canônica do canon() do calc.js.
   Os tamanhos de blob batem exatamente com o do site porque a ordem das chaves não muda a
   contagem de bytes; o resto (número, escape de texto) segue o JavaScript. */

/// Limite de bytes do blob em JSON (UTF-8), o mesmo LIMITE_BLOB do calc.js.
public let limiteBlob = 900_000

/// A partir daqui o app avisa que os dados estão perto do limite: o AVISO_BLOB do calc.js.
public let avisoBlob = 700_000

/// Chave que o JavaScript trata como índice de array: vem antes das outras, em ordem numérica.
func indiceDeArray(_ chave: String) -> UInt32? {
    guard !chave.isEmpty, chave.utf8.allSatisfy({ (0x30...0x39).contains($0) }) else { return nil }
    if chave.utf8.count > 1 && chave.utf8.first == 0x30 { return nil }
    guard chave.utf8.count <= 10, let v = UInt64(chave), v < 4_294_967_295 else { return nil }
    return UInt32(v)
}

/// Comparação de texto do `<` e do `sort()` do JavaScript: unidade UTF-16 por unidade.
public func menorJS(_ a: String, _ b: String) -> Bool { a.utf16.lexicographicallyPrecedes(b.utf16) }

/// Ordem das chaves no canon(): índices de array em ordem numérica, depois o resto pela ordem do JavaScript.
func ordemCanonica(_ chaves: [String]) -> [String] {
    var indices: [(UInt32, String)] = []
    var outras: [String] = []
    for c in chaves { if let i = indiceDeArray(c) { indices.append((i, c)) } else { outras.append(c) } }
    indices.sort { $0.0 < $1.0 }
    outras.sort(by: menorJS)
    return indices.map(\.1) + outras
}

func escreverTextoJSON(_ s: String, em r: inout String) {
    r += "\""
    for u in s.unicodeScalars {
        switch u.value {
        case 0x22: r += "\\\""
        case 0x5C: r += "\\\\"
        case 0x08: r += "\\b"
        case 0x0C: r += "\\f"
        case 0x0A: r += "\\n"
        case 0x0D: r += "\\r"
        case 0x09: r += "\\t"
        case 0x00..<0x20:
            let hex = String(u.value, radix: 16)
            r += "\\u" + String(repeating: "0", count: 4 - hex.count) + hex
        default: r.unicodeScalars.append(u)
        }
    }
    r += "\""
}

func escrever(_ v: ValorJSON, em r: inout String) {
    switch v {
    case .nulo: r += "null"
    case .booleano(let b): r += b ? "true" : "false"
    case .numero(let n): r += n.isFinite ? numeroJS(n) : "null"
    case .texto(let s): escreverTextoJSON(s, em: &r)
    case .lista(let l):
        r += "["
        for (i, x) in l.enumerated() { if i > 0 { r += "," }; escrever(x, em: &r) }
        r += "]"
    case .objeto(let o):
        r += "{"
        for (i, k) in ordemCanonica(Array(o.keys)).enumerated() {
            if i > 0 { r += "," }
            escreverTextoJSON(k, em: &r)
            r += ":"
            escrever(o[k]!, em: &r)
        }
        r += "}"
    }
}

/// `canon()` do calc.js: JSON com as chaves em ordem canônica.
public func canonico(_ v: ValorJSON) -> String {
    var r = ""
    escrever(v, em: &r)
    return r
}

/// Mesmo conteúdo para o site (canon igual): o eco do snapshot usa isto, como o app.js.
public func mesmoConteudo(_ a: ValorJSON, _ b: ValorJSON) -> Bool { canonico(a) == canonico(b) }

/// `tamanhoBlob` do calc.js: bytes UTF-8 do JSON.
public func tamanhoBlob(_ v: ValorJSON) -> Int { canonico(v).utf8.count }

/// `blobCabe` do calc.js.
public func blobCabe(_ v: ValorJSON) -> Bool { tamanhoBlob(v) <= limiteBlob }
```

`app-ios/CusttaNucleo/Sources/CusttaNucleo/ValorJSON+Foundation.swift`:

```swift
import Foundation

/* Ponte com os tipos do Foundation que o SDK do Firestore usa (NSNumber, NSString, NSArray,
   NSDictionary, NSNull). Fica no núcleo porque não depende do Firebase e decide a regra de
   número: o Firestore devolve inteiro ou decimal conforme o JavaScript gravou; aqui os dois
   viram Double, e na volta o inteiro seguro vira Int64, como o SDK JavaScript grava. */

public extension ValorJSON {
    /// nil se o valor, ou qualquer coisa dentro dele, for de um tipo que o JSON não tem (data do
    /// Firestore, referência, bytes): virar null perderia o dado na próxima gravação, que reescreve o
    /// documento inteiro. Quem chama decide o que fazer (a etapa 1B recusa ler e não grava).
    init?(foundation valor: Any) {
        switch valor {
        case is NSNull:
            self = .nulo
        case let n as NSNumber:
            if CFGetTypeID(n) == CFBooleanGetTypeID() { self = .booleano(n.boolValue) }
            else { self = .numero(n.doubleValue) }
        case let s as String:
            self = .texto(s)
        case let l as [Any]:
            var r: [ValorJSON] = []
            r.reserveCapacity(l.count)
            for x in l {
                guard let v = ValorJSON(foundation: x) else { return nil }
                r.append(v)
            }
            self = .lista(r)
        case let o as [String: Any]:
            var r: [String: ValorJSON] = [:]
            for (k, v) in o {
                guard let x = ValorJSON(foundation: v) else { return nil }
                r[k] = x
            }
            self = .objeto(r)
        default:
            return nil
        }
    }

    /// Para gravar no Firestore: inteiro seguro (|n| ≤ 2^53 − 1, sem −0) vira Int64, como o SDK
    /// JavaScript faz; o resto vai como Double.
    var paraFoundation: Any {
        switch self {
        case .nulo: return NSNull()
        case .booleano(let b): return b
        case .numero(let n):
            if n.rounded(.towardZero) == n, abs(n) <= 9_007_199_254_740_991, !(n == 0 && n.sign == .minus) { return Int64(n) }
            return n
        case .texto(let s): return s
        case .lista(let l): return l.map(\.paraFoundation)
        case .objeto(let o): return o.mapValues(\.paraFoundation)
        }
    }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter SerializadorTests`
Expected: `Test run with 6 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: JSON e tamanho do blob iguais aos do site no núcleo" -m "O núcleo escreve o mesmo texto do canon() e do JSON.stringify do site (número, escape e ordem de chave do JavaScript), e o tamanho do blob sai exato, sem folga: perto dos 900 mil bytes o app e o site concordam no byte sobre o que cabe. A ponte com o Foundation decide inteiro e decimal: tudo vira Double na leitura e o inteiro seguro volta como Int64, que é o que o SDK JavaScript grava."
```

---

### Task 7: Datas

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Datas.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DatasTests.swift`

**Interfaces:**
- Consumes: `menorJS` (Tarefa 6).
- Produces:
  - Internos: `componentesISO(_:) -> (ano: Int, mes: Int, dia: Int)?`, `bissexto(_:)`, `diasNoMes(ano:mes:) -> Int`, `diaAbsoluto(ano:mes:dia:) -> Int`, `dataDeDiaAbsoluto(_:) -> (ano: Int, mes: Int, dia: Int)`, `doisDigitos(_:) -> String`, `isoDe(ano:mes:dia:) -> String`, `somarDias(_ iso: String, _ dias: Int) -> String`
  - `public func dataLocalISO(_ instante: Date, fuso: TimeZone) -> String`
  - `public func dataISOValida(_ iso: String?) -> Bool`
  - `public func dataIgualOuDepois(_ data: String?, _ minimo: String?) -> Bool`
  - `public func diasEntre(_ de: String, _ ate: String) -> Int`
  - `public func addMesesClampado(_ dataISO: String, _ meses: Int) -> String`

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DatasTests.swift`:

```swift
import Foundation
import Testing
@testable import CusttaNucleo

struct DatasTests {
    let saoPaulo = TimeZone(identifier: "America/Sao_Paulo")!

    @Test func dataLocalNoFusoDeBrasilia() {
        #expect(Vetores.todos.fuso == "America/Sao_Paulo")
        for c in Vetores.casos("calc.dataLocalISO") {
            let instante = Date(timeIntervalSince1970: c.args[0].numero / 1000)
            #expect(dataLocalISO(instante, fuso: saoPaulo) == c.saida.comoTexto, "\(c.caso)")
        }
    }

    @Test func diaDependeDoFusoDoAparelho() {
        let instante = Date(timeIntervalSince1970: 1_787_707_800)     // 2026-08-26 01:30 UTC
        #expect(dataLocalISO(instante, fuso: saoPaulo) == "2026-08-25")
        #expect(dataLocalISO(instante, fuso: TimeZone(identifier: "Asia/Tokyo")!) == "2026-08-26")
    }

    @Test func dataValida() {
        for c in Vetores.casos("calc.dataISOValida") {
            #expect(dataISOValida(c.arg(0)?.textoOuNil) == c.saida.comoBooleano, "\(c.caso)")
        }
    }

    @Test func igualOuDepois() {
        for c in Vetores.casos("calc.dataIgualOuDepois") {
            #expect(dataIgualOuDepois(c.arg(0)?.textoOuNil, c.arg(1)?.textoOuNil) == c.saida.comoBooleano, "\(c.caso)")
        }
    }

    @Test func diasEntreDatas() {
        for c in Vetores.casos("calc.diasEntre") {
            #expect(Double(diasEntre(c.args[0].comoTexto!, c.args[1].comoTexto!)) == c.saida.comoNumero, "\(c.caso)")
        }
    }

    @Test func somaMesesComClamp() {
        for c in Vetores.casos("calc.addMesesClampado") {
            #expect(addMesesClampado(c.args[0].comoTexto!, Int(c.args[1].numero)) == c.saida.comoTexto, "\(c.caso)")
        }
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter DatasTests`
Expected: FAIL na compilação: `cannot find 'dataLocalISO' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Datas.swift`:

```swift
import Foundation

/* Datas AAAA-MM-DD como no calc.js. O site faz conta em hora local; aqui a conta é de
   calendário (dia absoluto), que dá o mesmo resultado em qualquer fuso e sem horário de verão.
   Só dataLocalISO depende de fuso, e recebe o fuso explícito. Entradas são datas válidas: o
   estado normalizado não deixa passar outra coisa (dataISOValida existe para checar). */

func componentesISO(_ iso: String) -> (ano: Int, mes: Int, dia: Int)? {
    let u = Array(iso.utf8)
    guard u.count == 10, u[4] == 0x2D, u[7] == 0x2D else { return nil }
    for i in [0, 1, 2, 3, 5, 6, 8, 9] where !(0x30...0x39).contains(u[i]) { return nil }
    func numero(_ r: Range<Int>) -> Int { r.reduce(0) { $0 * 10 + Int(u[$1] - 0x30) } }
    return (numero(0..<4), numero(5..<7), numero(8..<10))
}

func bissexto(_ ano: Int) -> Bool { ano % 4 == 0 && (ano % 100 != 0 || ano % 400 == 0) }

func diasNoMes(ano: Int, mes: Int) -> Int {
    switch mes {
    case 2: return bissexto(ano) ? 29 : 28
    case 4, 6, 9, 11: return 30
    default: return 31
    }
}

/// Dias desde 1970-01-01 no calendário gregoriano proléptico (algoritmo days_from_civil).
func diaAbsoluto(ano: Int, mes: Int, dia: Int) -> Int {
    let y = mes <= 2 ? ano - 1 : ano
    let era = (y >= 0 ? y : y - 399) / 400
    let anoDaEra = y - era * 400
    let diaDoAno = (153 * ((mes + 9) % 12) + 2) / 5 + dia - 1
    let diaDaEra = anoDaEra * 365 + anoDaEra / 4 - anoDaEra / 100 + diaDoAno
    return era * 146097 + diaDaEra - 719468
}

/// O inverso de diaAbsoluto (algoritmo civil_from_days).
func dataDeDiaAbsoluto(_ dias: Int) -> (ano: Int, mes: Int, dia: Int) {
    let z = dias + 719468
    let era = (z >= 0 ? z : z - 146096) / 146097
    let diaDaEra = z - era * 146097
    let anoDaEra = (diaDaEra - diaDaEra / 1460 + diaDaEra / 36524 - diaDaEra / 146096) / 365
    let diaDoAno = diaDaEra - (365 * anoDaEra + anoDaEra / 4 - anoDaEra / 100)
    let mp = (5 * diaDoAno + 2) / 153
    let dia = diaDoAno - (153 * mp + 2) / 5 + 1
    let mes = mp < 10 ? mp + 3 : mp - 9
    return (anoDaEra + era * 400 + (mes <= 2 ? 1 : 0), mes, dia)
}

func doisDigitos(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }

/// AAAA-MM-DD, com o ano em quatro dígitos.
func isoDe(ano: Int, mes: Int, dia: Int) -> String {
    let a = String(ano)
    return String(repeating: "0", count: max(0, 4 - a.count)) + a + "-" + doisDigitos(mes) + "-" + doisDigitos(dia)
}

func somarDias(_ iso: String, _ dias: Int) -> String {
    guard let c = componentesISO(iso) else { return iso }
    let d = dataDeDiaAbsoluto(diaAbsoluto(ano: c.ano, mes: c.mes, dia: c.dia) + dias)
    return isoDe(ano: d.ano, mes: d.mes, dia: d.dia)
}

/// `dataLocalISO` do calc.js: o dia do instante no fuso dado (não o dia em UTC).
public func dataLocalISO(_ instante: Date, fuso: TimeZone) -> String {
    var calendario = Calendar(identifier: .gregorian)
    calendario.timeZone = fuso
    let c = calendario.dateComponents([.year, .month, .day], from: instante)
    return isoDe(ano: c.year!, mes: c.month!, dia: c.day!)
}

/// `dataISOValida` do calc.js. Anos 0000 a 0099 não valem: o Date.UTC do JavaScript lê esses anos como 1900 + ano.
public func dataISOValida(_ iso: String?) -> Bool {
    guard let iso, let c = componentesISO(iso) else { return false }
    return c.ano >= 100 && (1...12).contains(c.mes) && (1...diasNoMes(ano: c.ano, mes: c.mes)).contains(c.dia)
}

/// `dataIgualOuDepois` do calc.js.
public func dataIgualOuDepois(_ data: String?, _ minimo: String?) -> Bool {
    guard let data, let minimo, dataISOValida(data), dataISOValida(minimo) else { return false }
    return !menorJS(data, minimo)
}

/// `diasEntre` do calc.js: dias de calendário, nunca negativo.
public func diasEntre(_ de: String, _ ate: String) -> Int {
    guard let a = componentesISO(de), let b = componentesISO(ate) else { return 0 }
    return max(0, diaAbsoluto(ano: b.ano, mes: b.mes, dia: b.dia) - diaAbsoluto(ano: a.ano, mes: a.mes, dia: a.dia))
}

/// `addMesesClampado` do calc.js (meses ≥ 0): dia que não existe vira o último do mês (31/01 + 1 = 28 ou 29/02).
/// Como no JavaScript, o ano sai sem completar com zeros.
public func addMesesClampado(_ dataISO: String, _ meses: Int) -> String {
    guard let c = componentesISO(dataISO) else { return dataISO }
    let total = (c.mes - 1) + meses
    let ano = c.ano + Int((Double(total) / 12).rounded(.down))
    let mes = total % 12
    let dia = min(c.dia, diasNoMes(ano: ano, mes: mes + 1))
    return "\(ano)-" + doisDigitos(mes + 1) + "-" + doisDigitos(dia)
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter DatasTests`
Expected: `Test run with 6 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: datas do calc.js no núcleo" -m "diasEntre, addMesesClampado e a soma de dias viram conta de calendário pura, que dá o mesmo que o Math.round sobre meias-noites locais do site em qualquer fuso e com horário de verão. dataLocalISO recebe o fuso explícito. dataISOValida recusa os anos 0000 a 0099, como o Date.UTC do JavaScript."
```

---

### Task 8: Normalização do dados.js

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Normalizacao.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/NormalizacaoTests.swift`

**Interfaces:**
- Consumes: `ValorJSON`, `numeroJS`, `aparadoJS`, `numeroDeTextoJS`, `verdadeiroJS` (Tarefa 5), `ordemCanonica`, `canonico` (Tarefa 6), `componentesISO`, `diasNoMes` (Tarefa 7).
- Produces:
  - `public enum Limites { static let nome = 120, descricao = 500, topico = 80, afazer = 500 }`
  - `public func normaliza(_ d: ValorJSON?) -> ValorJSON`
  - Internos usados depois: `textoDoDocumento(_:) -> String`, `numeroDoDocumento(_:) -> Double?`, `positivoDoDocumento(_:) -> Double?`, `dataDoDocumentoValida(_:) -> Bool`, `ehInteiroJS(_:) -> Bool`

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/NormalizacaoTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

struct NormalizacaoTests {
    @Test func normalizaComoODadosJs() {
        for c in Vetores.casos("dados.normaliza") {
            #expect(canonico(normaliza(c.args[0])) == canonico(c.saida), "\(c.caso)")
        }
    }

    @Test func limitesDeTexto() {
        let l = Vetores.casos("dados.LIMITES")[0].saida.comoObjeto!
        #expect(Double(Limites.nome) == l["nome"]?.comoNumero)
        #expect(Double(Limites.descricao) == l["descricao"]?.comoNumero)
        #expect(Double(Limites.topico) == l["topico"]?.comoNumero)
        #expect(Double(Limites.afazer) == l["afazer"]?.comoNumero)
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter NormalizacaoTests`
Expected: FAIL na compilação: `cannot find 'normaliza' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Normalizacao.swift`:

```swift
import Foundation

/* Porte do dados.js: o que o app faz ao carregar o documento. Campo desconhecido é preservado;
   entrada inválida não chega à tela. Cada regra tem caso nos vetores (grupo dados.normaliza). */

/// Limites de texto da edição (LIMITES do dados.js). Contam unidades UTF-16, como o `length` do JavaScript.
public enum Limites {
    public static let nome = 120
    public static let descricao = 500
    public static let topico = 80
    public static let afazer = 500
}

let maximoDeTopicosNoOrcamento = 100

private func objeto(_ v: ValorJSON?) -> [String: ValorJSON]? { v?.comoObjeto }

/// `texto()` do dados.js: texto passa, número finito vira texto como no JavaScript, o resto vira "".
func textoDoDocumento(_ v: ValorJSON?) -> String {
    switch v {
    case .texto(let s)?: return s
    case .numero(let n)? where n.isFinite: return numeroJS(n)
    default: return ""
    }
}

/// `numero()` do dados.js: número finito, ou texto não vazio que o Number() lê como finito.
func numeroDoDocumento(_ v: ValorJSON?) -> Double? {
    switch v {
    case .numero(let n)?: return n.isFinite ? n : nil
    case .texto(let s)?:
        guard !aparadoJS(s).isEmpty else { return nil }
        let n = numeroDeTextoJS(s)
        return n.isFinite ? n : nil
    default: return nil
    }
}

/// `positivo()` do dados.js: número maior ou igual a zero.
func positivoDoDocumento(_ v: ValorJSON?) -> Double? {
    guard let n = numeroDoDocumento(v), n >= 0 else { return nil }
    return n
}

/// `data()` do dados.js: AAAA-MM-DD que existe no calendário (o ano 0000 vale aqui, ao contrário de dataISOValida).
func dataDoDocumentoValida(_ v: ValorJSON?) -> Bool {
    guard let s = v?.comoTexto, let c = componentesISO(s) else { return false }
    return (1...12).contains(c.mes) && (1...diasNoMes(ano: c.ano, mes: c.mes)).contains(c.dia)
}

func ehInteiroJS(_ n: Double) -> Bool { n.isFinite && n.rounded(.towardZero) == n }

private func lista(_ v: ValorJSON?, _ f: ([String: ValorJSON]) -> ValorJSON?) -> [ValorJSON] {
    guard let l = v?.comoLista else { return [] }
    return l.compactMap { item in item.comoObjeto.flatMap(f) }
}

private func orcamento(_ v: ValorJSON?) -> ValorJSON? {
    guard var o = objeto(v) else { return nil }
    func maior(_ x: ValorJSON?) -> Double? {
        guard let n = numeroDoDocumento(x), n > 0 else { return nil }
        return n
    }
    if o["modo"] == .texto("topicos") {
        let origem = objeto(o["topicos"]) ?? [:]
        var topicos: [String: ValorJSON] = [:]
        /* O JavaScript percorre na ordem de inserção; o Firestore do iOS não guarda ordem. Os
           vetores e qualquer orçamento feito pela tela (no máximo 71 tópicos) não dependem disso. */
        for id in ordemCanonica(Array(origem.keys)) {
            if topicos.count >= maximoDeTopicosNoOrcamento { break }
            if !aparadoJS(id).isEmpty, id.utf16.count <= Limites.topico, let valor = maior(origem[id]) {
                topicos[id] = .numero(valor)
            }
        }
        if topicos.isEmpty { return nil }
        o["modo"] = .texto("topicos")
        o["topicos"] = .objeto(topicos)
        o["total"] = nil
        return .objeto(o)
    }
    guard let total = maior(o["total"]) else { return nil }
    o["modo"] = .texto("total")
    o["total"] = .numero(total)
    o["topicos"] = nil
    return .objeto(o)
}

private func gasto(_ g: [String: ValorJSON]) -> ValorJSON? {
    let id = textoDoDocumento(g["id"])
    guard !id.isEmpty, dataDoDocumentoValida(g["data"]), let valor = positivoDoDocumento(g["valor"]) else { return nil }
    var r = g
    r["id"] = .texto(id)
    r["valor"] = .numero(valor)
    let topico = textoDoDocumento(g["topico"])
    r["topico"] = .texto(topico.isEmpty ? "outros" : topico)
    r["descricao"] = .texto(textoDoDocumento(g["descricao"]))
    let pagamento = textoDoDocumento(g["pagamento"])
    r["pagamento"] = .texto(pagamento.isEmpty ? "pix" : pagamento)
    if verdadeiroJS(g["grupoId"]) || verdadeiroJS(g["parcela"]) {
        if var p = objeto(g["parcela"]), let n = numeroDoDocumento(p["n"]), let de = numeroDoDocumento(p["de"]),
           ehInteiroJS(n), ehInteiroJS(de), n > 0, de >= n {
            r["grupoId"] = .texto(textoDoDocumento(g["grupoId"]))
            p["n"] = .numero(n)
            p["de"] = .numero(de)
            r["parcela"] = .objeto(p)
        } else {
            r["grupoId"] = nil
            r["parcela"] = nil
        }
    }
    return .objeto(r)
}

private func afazer(_ a: [String: ValorJSON]) -> ValorJSON? {
    let id = textoDoDocumento(a["id"])
    guard !id.isEmpty else { return nil }
    var r = a
    r["id"] = .texto(id)
    r["texto"] = .texto(textoDoDocumento(a["texto"]))
    r["feito"] = .booleano(a["feito"] == .booleano(true))
    return .objeto(r)
}

private func obra(_ o: [String: ValorJSON]) -> ValorJSON? {
    let id = textoDoDocumento(o["id"])
    guard !id.isEmpty, dataDoDocumentoValida(o["dataInicio"]) else { return nil }
    var venda = ValorJSON.nulo
    if var v = objeto(o["venda"]), dataDoDocumentoValida(v["data"]), let valor = positivoDoDocumento(v["valor"]) {
        v["valor"] = .numero(valor)
        venda = .objeto(v)
    }
    var r = o
    r["id"] = .texto(id)
    let nome = textoDoDocumento(o["nome"])
    r["nome"] = .texto(nome.isEmpty ? "Obra sem nome" : nome)
    var fase = "construcao"
    if let f = o["fase"]?.comoTexto, ["construcao", "pronta", "vendida"].contains(f), f != "vendida" || venda != .nulo { fase = f }
    r["fase"] = .texto(fase)
    r["venda"] = venda
    r["valorEstimadoVenda"] = positivoDoDocumento(o["valorEstimadoVenda"]).map(ValorJSON.numero) ?? .nulo
    r["areaM2"] = positivoDoDocumento(o["areaM2"]).map(ValorJSON.numero) ?? .nulo
    r["gastos"] = .lista(lista(o["gastos"], gasto))
    r["afazeres"] = .lista(lista(o["afazeres"], afazer))
    r["orcamento"] = orcamento(o["orcamento"])
    return .objeto(r)
}

private func topicoProprio(_ t: [String: ValorJSON]) -> ValorJSON? {
    let id = textoDoDocumento(t["id"]), nm = textoDoDocumento(t["nm"])
    guard !id.isEmpty, !nm.isEmpty else { return nil }
    var r = t
    r["id"] = .texto(id)
    r["nm"] = .texto(nm)
    let ic = textoDoDocumento(t["ic"])
    r["ic"] = .texto(ic.isEmpty ? "etiqueta" : ic)
    return .objeto(r)
}

/// `normaliza()` do dados.js.
public func normaliza(_ d: ValorJSON?) -> ValorJSON {
    var r = objeto(d) ?? [:]
    var config = objeto(r["config"]) ?? [:]
    r["obras"] = .lista(lista(r["obras"], obra))
    let taxa = numeroDoDocumento(config["taxaMensal"])
    config["taxaMensal"] = .numero(taxa.map { $0 > 0 && $0 <= 20 ? $0 : 1 } ?? 1)
    config["topicosCustom"] = .lista(lista(config["topicosCustom"], topicoProprio))
    r["config"] = .objeto(config)
    return .objeto(r)
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter NormalizacaoTests`
Expected: `Test run with 2 tests … passed` (os 45 casos de `dados.normaliza` dentro do primeiro).

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: normalização do dados.js no núcleo" -m "As mesmas regras do dados.js ao carregar o documento: taxa fora de (0, 20] vira 1, gasto sem id ou com data inválida some, vendida sem venda volta para construção, número em texto passa pelo Number() do JavaScript e campo desconhecido fica. O resultado é comparado com o do site pelo canon em 45 casos, inclusive id de tópico contado em unidades UTF-16."
```

---

### Task 9: Modelo por cima da árvore original

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Modelo.swift`
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Topicos.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ModeloTests.swift`

**Interfaces:**
- Consumes: `ValorJSON`, `normaliza` (Tarefa 8), `canonico` (Tarefa 6).
- Produces:
  - `public enum Fase: String, Sendable, CaseIterable { case construcao, pronta, vendida }`
  - `public struct Venda { valor: Double; data: String }`, `public struct Parcela { n: Int; de: Int }`
  - `public struct Gasto { var campos: [String: ValorJSON]; init(campos:); var id, topico, descricao, data, pagamento: String; var valor: Double; var grupoId: String?; var parcela: Parcela? }`
  - `public struct Afazer { var campos; var id: String; var texto: String; var feito: Bool }`
  - `public struct Obra { var campos; var gastos: [Gasto]; var afazeres: [Afazer]; init(arvore: [String: ValorJSON]); var arvore: [String: ValorJSON]; var id, nome, dataInicio: String; var fase: Fase; var venda: Venda?; var valorEstimadoVenda: Double?; var areaM2: Double?; var orcamento: ValorJSON? }`
  - `public struct TopicoProprio { var campos; var id: String; var nome: String /* nm */; var icone: String /* ic */ }`
  - `public struct Configuracao { var campos; var topicosProprios: [TopicoProprio]; init(arvore:); var arvore; var taxaMensal: Double }`
  - `public struct Estado { var campos; var obras: [Obra]; var config: Configuracao; init(normalizado: ValorJSON); static func de(_ bruto: ValorJSON?) -> Estado; static var vazio: Estado; var arvore: ValorJSON }`
  - `public struct Topico: Hashable { let id, nome, icone: String }`, `public let topicosPadrao: [Topico]`, `public func mapaDeTopicos(_ proprios: [TopicoProprio]) -> [String: Topico]`
  - Nos testes (usados pelas Tarefas 10 a 16): `extension ValorJSON { var obra: Obra; var obras: [Obra]; var gastos: [Gasto] }`

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ModeloTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/// Argumentos dos vetores → tipos do núcleo (os testes das tarefas seguintes usam).
extension ValorJSON {
    var obra: Obra { Obra(arvore: comoObjeto ?? [:]) }
    var obras: [Obra] { (comoLista ?? []).map(\.obra) }
    var gastos: [Gasto] { (comoLista ?? []).compactMap { $0.comoObjeto.map(Gasto.init(campos:)) } }
}

struct ModeloTests {
    @Test func estadoLeEEscreveSemPerderNada() {
        for c in Vetores.casos("dados.normaliza") {
            let normalizado = normaliza(c.args[0])
            #expect(canonico(Estado(normalizado: normalizado).arvore) == canonico(normalizado), "\(c.caso)")
        }
    }

    @Test func gravarCampoConhecidoMantemODesconhecido() {
        var estado = Estado.de(.objeto(["obras": .lista([.objeto([
            "id": .texto("o"), "nome": .texto("Obra"), "dataInicio": .texto("2026-01-01"), "campoDoSite": .texto("fica"),
            "venda": .objeto(["valor": .numero(10), "data": .texto("2026-02-01"), "obs": .texto("fica")]),
            "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(1), "data": .texto("2026-01-02"),
                                       "grupoId": .texto("gr"), "parcela": .objeto(["n": .numero(1), "de": .numero(2), "x": .booleano(true)]),
                                       "anexo": .texto("fica")])])])])]))
        estado.obras[0].nome = "Obra nova"
        estado.obras[0].venda = Venda(valor: 20, data: "2026-03-01")
        estado.obras[0].gastos[0].valor = 2
        estado.obras[0].gastos[0].parcela = Parcela(n: 2, de: 2)
        estado.config.taxaMensal = 1.5
        let obra = estado.arvore.comoObjeto!["obras"]!.comoLista![0].comoObjeto!
        #expect(obra["campoDoSite"] == .texto("fica"))
        #expect(obra["nome"] == .texto("Obra nova"))
        #expect(obra["venda"] == .objeto(["valor": .numero(20), "data": .texto("2026-03-01"), "obs": .texto("fica")]))
        let gasto = obra["gastos"]!.comoLista![0].comoObjeto!
        #expect(gasto["anexo"] == .texto("fica"))
        #expect(gasto["parcela"] == .objeto(["n": .numero(2), "de": .numero(2), "x": .booleano(true)]))
        #expect(estado.arvore.comoObjeto!["config"]!.comoObjeto!["taxaMensal"] == .numero(1.5))
    }

    @Test func vendaNulaGravaNull() {
        var obra = Estado.de(.objeto(["obras": .lista([.objeto(["id": .texto("o"), "dataInicio": .texto("2026-01-01")])])])).obras[0]
        obra.venda = nil
        #expect(obra.arvore["venda"] == .nulo)
        #expect(obra.fase == .construcao)
    }

    @Test func estadoVazioEOBlobVazioDoSite() {
        #expect(canonico(Estado.vazio.arvore) == #"{"config":{"taxaMensal":1,"topicosCustom":[]},"obras":[]}"#)
    }

    @Test func topicosPadraoIguaisAoSite() {
        let esperado = Vetores.casos("calc.TOPICOS")[0].saida.comoLista!.map { t -> Topico in
            let o = t.comoObjeto!
            return Topico(id: o["id"]!.comoTexto!, nome: o["nm"]!.comoTexto!, icone: o["ic"]!.comoTexto!)
        }
        #expect(topicosPadrao == esperado)
    }

    @Test func mapaDeTopicosPoeOProprioPorCima() {
        let mapa = mapaDeTopicos([TopicoProprio(campos: ["id": .texto("c_x"), "nm": .texto("Automação"), "ic": .texto("etiqueta")]),
                                  TopicoProprio(campos: ["id": .texto("pintura"), "nm": .texto("Pintura fina"), "ic": .texto("rolo")])])
        #expect(mapa["c_x"]?.nome == "Automação")
        #expect(mapa["pintura"]?.nome == "Pintura fina")
        #expect(mapa["terreno"]?.nome == "Terreno")
    }

    @Test func grupoIdVazioContaComoSemGrupo() {
        #expect(Gasto(campos: ["grupoId": .texto("")]).grupoId == nil)
        #expect(Gasto(campos: ["grupoId": .texto("gr1")]).grupoId == "gr1")
        #expect(Gasto(campos: [:]).grupoId == nil)
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter ModeloTests`
Expected: FAIL na compilação: `cannot find type 'Obra' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Modelo.swift`:

```swift
import Foundation

/* Tipos do estado do Custta, escritos por cima da árvore original do documento. Cada tipo
   guarda os campos como vieram (`campos`) e lê ou grava neles: campo desconhecido não some.
   Os inicializadores esperam a árvore já normalizada (normaliza(_:)), que sempre traz
   `gastos` e `afazeres` nas obras e `topicosCustom` na configuração. */

public enum Fase: String, Sendable, CaseIterable {
    case construcao, pronta, vendida
}

public struct Venda: Equatable, Sendable {
    public var valor: Double
    public var data: String
    public init(valor: Double, data: String) { self.valor = valor; self.data = data }
}

public struct Parcela: Equatable, Sendable {
    public var n: Int
    public var de: Int
    public init(n: Int, de: Int) { self.n = n; self.de = de }
}

public struct Gasto: Equatable, Sendable {
    public var campos: [String: ValorJSON]
    public init(campos: [String: ValorJSON]) { self.campos = campos }

    public var id: String {
        get { campos["id"]?.comoTexto ?? "" }
        set { campos["id"] = .texto(newValue) }
    }
    public var valor: Double {
        get { campos["valor"]?.comoNumero ?? 0 }
        set { campos["valor"] = .numero(newValue) }
    }
    public var topico: String {
        get { campos["topico"]?.comoTexto ?? "" }
        set { campos["topico"] = .texto(newValue) }
    }
    public var descricao: String {
        get { campos["descricao"]?.comoTexto ?? "" }
        set { campos["descricao"] = .texto(newValue) }
    }
    public var data: String {
        get { campos["data"]?.comoTexto ?? "" }
        set { campos["data"] = .texto(newValue) }
    }
    /// "pix" ou "cartao" no que o site grava; texto livre se vier outra coisa.
    public var pagamento: String {
        get { campos["pagamento"]?.comoTexto ?? "" }
        set { campos["pagamento"] = .texto(newValue) }
    }
    /// Compra parcelada: o mesmo grupoId nos irmãos. Texto vazio conta como sem grupo, como no
    /// JavaScript (o dados.js pode gravar `grupoId: ''` e o site trata como falso).
    public var grupoId: String? {
        get { campos["grupoId"]?.comoTexto.flatMap { $0.isEmpty ? nil : $0 } }
        set { campos["grupoId"] = newValue.map(ValorJSON.texto) }
    }
    /// Escrever mantém os campos desconhecidos de dentro da parcela.
    public var parcela: Parcela? {
        get {
            guard let p = campos["parcela"]?.comoObjeto, let n = p["n"]?.comoNumero, let de = p["de"]?.comoNumero,
                  let ni = Int(exactly: n), let dei = Int(exactly: de) else { return nil }
            return Parcela(n: ni, de: dei)
        }
        set {
            guard let nova = newValue else { campos["parcela"] = nil; return }
            var p = campos["parcela"]?.comoObjeto ?? [:]
            p["n"] = .numero(Double(nova.n))
            p["de"] = .numero(Double(nova.de))
            campos["parcela"] = .objeto(p)
        }
    }
}

public struct Afazer: Equatable, Sendable {
    public var campos: [String: ValorJSON]
    public init(campos: [String: ValorJSON]) { self.campos = campos }

    public var id: String {
        get { campos["id"]?.comoTexto ?? "" }
        set { campos["id"] = .texto(newValue) }
    }
    public var texto: String {
        get { campos["texto"]?.comoTexto ?? "" }
        set { campos["texto"] = .texto(newValue) }
    }
    public var feito: Bool {
        get { campos["feito"]?.comoBooleano ?? false }
        set { campos["feito"] = .booleano(newValue) }
    }
}

public struct Obra: Equatable, Sendable {
    /// Campos da obra menos `gastos` e `afazeres`, que moram nas listas tipadas.
    public var campos: [String: ValorJSON]
    public var gastos: [Gasto]
    public var afazeres: [Afazer]

    public init(arvore: [String: ValorJSON]) {
        var c = arvore
        gastos = (c.removeValue(forKey: "gastos")?.comoLista ?? []).compactMap { $0.comoObjeto.map(Gasto.init(campos:)) }
        afazeres = (c.removeValue(forKey: "afazeres")?.comoLista ?? []).compactMap { $0.comoObjeto.map(Afazer.init(campos:)) }
        campos = c
    }

    /// A obra inteira de volta, para gravar.
    public var arvore: [String: ValorJSON] {
        var c = campos
        c["gastos"] = .lista(gastos.map { .objeto($0.campos) })
        c["afazeres"] = .lista(afazeres.map { .objeto($0.campos) })
        return c
    }

    public var id: String {
        get { campos["id"]?.comoTexto ?? "" }
        set { campos["id"] = .texto(newValue) }
    }
    public var nome: String {
        get { campos["nome"]?.comoTexto ?? "" }
        set { campos["nome"] = .texto(newValue) }
    }
    public var dataInicio: String {
        get { campos["dataInicio"]?.comoTexto ?? "" }
        set { campos["dataInicio"] = .texto(newValue) }
    }
    public var fase: Fase {
        get { campos["fase"]?.comoTexto.flatMap(Fase.init(rawValue:)) ?? .construcao }
        set { campos["fase"] = .texto(newValue.rawValue) }
    }
    /// Escrever mantém os campos desconhecidos de dentro da venda; nil grava `venda: null`, como o site.
    public var venda: Venda? {
        get {
            guard let v = campos["venda"]?.comoObjeto, let valor = v["valor"]?.comoNumero, let data = v["data"]?.comoTexto else { return nil }
            return Venda(valor: valor, data: data)
        }
        set {
            guard let nova = newValue else { campos["venda"] = .nulo; return }
            var v = campos["venda"]?.comoObjeto ?? [:]
            v["valor"] = .numero(nova.valor)
            v["data"] = .texto(nova.data)
            campos["venda"] = .objeto(v)
        }
    }
    public var valorEstimadoVenda: Double? {
        get { campos["valorEstimadoVenda"]?.comoNumero }
        set { campos["valorEstimadoVenda"] = newValue.map(ValorJSON.numero) ?? .nulo }
    }
    public var areaM2: Double? {
        get { campos["areaM2"]?.comoNumero }
        set { campos["areaM2"] = newValue.map(ValorJSON.numero) ?? .nulo }
    }
    /// O orçamento como está no documento; quem lê é orcamentoObra(_:).
    public var orcamento: ValorJSON? {
        get { campos["orcamento"] }
        set { campos["orcamento"] = newValue }
    }
}

public struct TopicoProprio: Equatable, Sendable {
    public var campos: [String: ValorJSON]
    public init(campos: [String: ValorJSON]) { self.campos = campos }

    public var id: String {
        get { campos["id"]?.comoTexto ?? "" }
        set { campos["id"] = .texto(newValue) }
    }
    /// Campo `nm` do documento.
    public var nome: String {
        get { campos["nm"]?.comoTexto ?? "" }
        set { campos["nm"] = .texto(newValue) }
    }
    /// Campo `ic` do documento.
    public var icone: String {
        get { campos["ic"]?.comoTexto ?? "" }
        set { campos["ic"] = .texto(newValue) }
    }
}

public struct Configuracao: Equatable, Sendable {
    /// Campos da configuração menos `topicosCustom`.
    public var campos: [String: ValorJSON]
    public var topicosProprios: [TopicoProprio]

    public init(arvore: [String: ValorJSON]) {
        var c = arvore
        topicosProprios = (c.removeValue(forKey: "topicosCustom")?.comoLista ?? []).compactMap { $0.comoObjeto.map(TopicoProprio.init(campos:)) }
        campos = c
    }

    public var arvore: [String: ValorJSON] {
        var c = campos
        c["topicosCustom"] = .lista(topicosProprios.map { .objeto($0.campos) })
        return c
    }

    public var taxaMensal: Double {
        get { campos["taxaMensal"]?.comoNumero ?? 1 }
        set { campos["taxaMensal"] = .numero(newValue) }
    }
}

/// O documento `dados/{uid}` inteiro, normalizado: o `db` do site.
public struct Estado: Equatable, Sendable {
    /// Chaves de topo menos `obras` e `config`.
    public var campos: [String: ValorJSON]
    public var obras: [Obra]
    public var config: Configuracao

    /// Espera a saída de normaliza(_:).
    public init(normalizado: ValorJSON) {
        var c = normalizado.comoObjeto ?? [:]
        obras = (c.removeValue(forKey: "obras")?.comoLista ?? []).compactMap { $0.comoObjeto.map(Obra.init(arvore:)) }
        config = Configuracao(arvore: c.removeValue(forKey: "config")?.comoObjeto ?? [:])
        campos = c
    }

    /// Normaliza o que veio do banco (ou nada) e monta o estado.
    public static func de(_ bruto: ValorJSON?) -> Estado { Estado(normalizado: normaliza(bruto)) }

    /// `{obras: [], config: {taxaMensal: 1, topicosCustom: []}}`, o blob vazio do site.
    public static var vazio: Estado { .de(nil) }

    /// O documento inteiro de volta, para gravar.
    public var arvore: ValorJSON {
        var c = campos
        c["obras"] = .lista(obras.map { .objeto($0.arvore) })
        c["config"] = .objeto(config.arvore)
        return .objeto(c)
    }
}
```

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Topicos.swift`:

```swift
/// Tópico de gasto com o nome e o ícone que a tela mostra (campos `id`, `nm` e `ic` do site).
public struct Topico: Equatable, Hashable, Sendable {
    public let id: String
    public let nome: String
    public let icone: String
    public init(id: String, nome: String, icone: String) { self.id = id; self.nome = nome; self.icone = icone }
}

/// Os 21 tópicos fixos, na ordem do TOPICOS do calc.js.
public let topicosPadrao: [Topico] = [
    Topico(id: "terreno", nome: "Terreno", icone: "mapa"),
    Topico(id: "projeto", nome: "Documentação", icone: "documento"),
    Topico(id: "matbasicos", nome: "Materiais básicos", icone: "tijolos"),
    Topico(id: "fundacao", nome: "Fundação", icone: "pa"),
    Topico(id: "ferragem", nome: "Ferragem", icone: "vergalhao"),
    Topico(id: "estrutura", nome: "Estrutura", icone: "guindaste"),
    Topico(id: "alvenaria", nome: "Alvenaria", icone: "tijolos"),
    Topico(id: "telhado", nome: "Telhado", icone: "casa"),
    Topico(id: "eletrica", nome: "Elétrica", icone: "raio"),
    Topico(id: "hidraulica", nome: "Encanamento", icone: "gota"),
    Topico(id: "esquadrias", nome: "Esq. de alumínio", icone: "porta"),
    Topico(id: "revest", nome: "Cerâmica", icone: "ladrilho"),
    Topico(id: "pintura", nome: "Pintura", icone: "rolo"),
    Topico(id: "acabamento", nome: "Acabamento", icone: "rolo"),
    Topico(id: "piscina", nome: "Piscina", icone: "piscina"),
    Topico(id: "paisagismo", nome: "Jardim", icone: "arvore"),
    Topico(id: "maoobra", nome: "Mão de obra", icone: "capacete"),
    Topico(id: "aluguelmaq", nome: "Aluguel de máquina", icone: "engrenagem"),
    Topico(id: "matextra", nome: "Materiais extra", icone: "caixa"),
    Topico(id: "extras", nome: "Extras", icone: "mais"),
    Topico(id: "outros", nome: "Outros", icone: "caixa"),
]

/// O TOP_MAP do app.js: padrões e próprios por id; o próprio vence o padrão de mesmo id.
public func mapaDeTopicos(_ proprios: [TopicoProprio]) -> [String: Topico] {
    var mapa: [String: Topico] = [:]
    for t in topicosPadrao { mapa[t.id] = t }
    for t in proprios { mapa[t.id] = Topico(id: t.id, nome: t.nome, icone: t.icone) }
    return mapa
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter ModeloTests`
Expected: `Test run with 7 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: modelo do estado por cima da árvore do documento" -m "Estado, obra, gasto, parcela, venda, afazer, configuração e tópicos leem e gravam nos campos que vieram do banco, então campo que só o site conhece volta intacto. O teste lê e grava de volta os 45 blobs da normalização e confere pelo canon que nada mudou."
```

---

### Task 10: Correção pelo banco e lucro

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Correcao.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CorrecaoTests.swift`

**Interfaces:**
- Consumes: `Obra`, `Gasto` (Tarefa 9), `diasEntre` (Tarefa 7).
- Produces: `public let diasMes = 30.44`; `public func corrigido(_ valor: Double, de: String, ate: String, taxa: Double) -> Double`; `public func fimCorrecao(_ obra: Obra, hoje: String) -> String`; `public func totalBruto(_ obra: Obra) -> Double`; `public func totalCorrigido(_ obra: Obra, taxa: Double, hoje: String) -> Double`; `public struct LucroVenda { let bruto: Double; let vsBanco: Double }`; `public func lucroVenda(_ obra: Obra, taxa: Double) -> LucroVenda?`; `public func mesesDeObra(_ obra: Obra, hoje: String) -> Double`; `public func precoPorM2(_ valor: Double?, _ area: Double?) -> Double?`.

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CorrecaoTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

extension LucroVenda { var json: ValorJSON { .objeto(["bruto": .numero(bruto), "vsBanco": .numero(vsBanco)]) } }

struct CorrecaoTests {
    @Test func diasPorMes() {
        #expect(diasMes == Vetores.casos("calc.DIAS_MES")[0].saida.comoNumero)
    }

    @Test func corrigidoPeloBanco() {
        for c in Vetores.casos("calc.corrigido") {
            let v = corrigido(c.args[0].numero, de: c.args[1].comoTexto!, ate: c.args[2].comoTexto!, taxa: c.args[3].numero)
            confere(.numero(v), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func totais() {
        for c in Vetores.casos("calc.totalBruto") { confere(.numero(totalBruto(c.args[0].obra)), c.saida, .dinheiro, c.caso) }
        for c in Vetores.casos("calc.totalCorrigido") {
            confere(.numero(totalCorrigido(c.args[0].obra, taxa: c.args[1].numero, hoje: c.args[2].comoTexto!)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func lucroNaVenda() {
        for c in Vetores.casos("calc.lucroVenda") {
            confere(lucroVenda(c.args[0].obra, taxa: c.args[1].numero)?.json ?? .nulo, c.saida, .dinheiro, c.caso)
        }
    }

    @Test func mesesDeObraAteHojeOuAVenda() {
        for c in Vetores.casos("calc.mesesDeObra") {
            confere(.numero(mesesDeObra(c.args[0].obra, hoje: c.args[1].comoTexto!)), c.saida, .continua, c.caso)
        }
    }

    @Test func precoPorMetroQuadrado() {
        for c in Vetores.casos("calc.precoPorM2") {
            confere(opcional(precoPorM2(c.args[0].numeroOuNil, c.args[1].numeroOuNil)), c.saida, .dinheiro, c.caso)
        }
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter CorrecaoTests`
Expected: FAIL na compilação: `cannot find type 'LucroVenda' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Correcao.swift`:

```swift
import Foundation

/* Correção pelo banco e lucro, como no calc.js. A ordem das operações é a mesma do JavaScript; com
   pow, o resultado em ponto flutuante sai igual ao do V8 (conferido). Não vale para expm1 e log1p
   (Parcelas.swift), que podem diferir em 1 ulp. */

/// DIAS_MES do calc.js: meses de 30,44 dias.
public let diasMes = 30.44

/// `corrigido` do calc.js: juros compostos diários de `de` até `ate` (gasto depois de `ate` fica pelo valor).
public func corrigido(_ valor: Double, de: String, ate: String, taxa: Double) -> Double {
    valor * pow(1 + taxa / 100, Double(diasEntre(de, ate)) / diasMes)
}

/// `fimCorrecao` do calc.js: a data da venda, ou hoje.
public func fimCorrecao(_ obra: Obra, hoje: String) -> String {
    if let data = obra.venda?.data, !data.isEmpty { return data }
    return hoje
}

/// `totalBruto` do calc.js (inclui parcelas a vencer).
public func totalBruto(_ obra: Obra) -> Double {
    obra.gastos.reduce(0) { $0 + $1.valor }
}

/// `totalCorrigido` do calc.js.
public func totalCorrigido(_ obra: Obra, taxa: Double, hoje: String) -> Double {
    let fim = fimCorrecao(obra, hoje: hoje)
    return obra.gastos.reduce(0) { $0 + corrigido($1.valor, de: $1.data, ate: fim, taxa: taxa) }
}

public struct LucroVenda: Equatable, Sendable {
    public let bruto: Double
    public let vsBanco: Double
}

/// `lucroVenda` do calc.js: o corrigido vai até a data da venda.
public func lucroVenda(_ obra: Obra, taxa: Double) -> LucroVenda? {
    guard let venda = obra.venda else { return nil }
    return LucroVenda(bruto: venda.valor - totalBruto(obra),
                      vsBanco: venda.valor - totalCorrigido(obra, taxa: taxa, hoje: venda.data))
}

/// `mesesDeObra` do calc.js.
public func mesesDeObra(_ obra: Obra, hoje: String) -> Double {
    Double(diasEntre(obra.dataInicio, fimCorrecao(obra, hoje: hoje))) / diasMes
}

/// `precoPorM2` do calc.js.
public func precoPorM2(_ valor: Double?, _ area: Double?) -> Double? {
    guard let valor, let area, valor > 0, area > 0 else { return nil }
    return valor / area
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter CorrecaoTests`
Expected: `Test run with 6 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: correção pelo banco e lucro no núcleo" -m "corrigido, totais, lucro na venda, meses de obra e preço por metro quadrado, com a mesma ordem de operações do calc.js. Os vetores cobrem gasto depois da venda (entra pelo valor) e a obra vendida, cujo corrigido para na data da venda."
```

---

### Task 11: TIR e simulador

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Tir.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TirTests.swift`

**Interfaces:**
- Consumes: `Gasto`, `diasEntre`, `diasMes`.
- Produces: `public func tirMensal(_ gastos: [Gasto], venda: Double, alvo: String) -> Double?`; `public func rendimentoAcima(_ tir: Double?, taxa: Double) -> Double?`; `public struct ResumoVenda { let lucro, pctCusto, pctVenda: Double? }`; `public func resumoVenda(_ venda: Double, custo: Double) -> ResumoVenda`.

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TirTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

extension ResumoVenda {
    var json: ValorJSON { .objeto(["lucro": opcional(lucro), "pctCusto": opcional(pctCusto), "pctVenda": opcional(pctVenda)]) }
}

struct TirTests {
    @Test func tirMensalPorBissecao() {
        for c in Vetores.casos("calc.tirMensal") {
            confere(opcional(tirMensal(c.args[0].gastos, venda: c.args[1].numero, alvo: c.args[2].comoTexto!)), c.saida, .continua, c.caso)
        }
    }

    @Test func rendimentoAcimaDoBanco() {
        for c in Vetores.casos("calc.rendimentoAcima") {
            confere(opcional(rendimentoAcima(c.args[0].numeroOuNil, taxa: c.args[1].numero)), c.saida, .continua, c.caso)
        }
    }

    @Test func resumoDaVenda() {
        for c in Vetores.casos("calc.resumoVenda") {
            confere(resumoVenda(c.args[0].numero, custo: c.args[1].numero).json, c.saida, .continua, c.caso)
        }
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter TirTests`
Expected: FAIL na compilação: `cannot find type 'ResumoVenda' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Tir.swift`:

```swift
import Foundation

/// `tirMensal` do calc.js, em % ao mês: bisseção de 100 passos entre −99% e +1000%.
/// nil sem venda, sem gastos, sem tempo passado ou com a raiz fora do intervalo.
/// Gasto depois do alvo conta como pago nele (diasEntre não fica negativo).
public func tirMensal(_ gastos: [Gasto], venda: Double, alvo: String) -> Double? {
    guard venda > 0, !gastos.isEmpty else { return nil }
    let fluxos = gastos.map { (valor: $0.valor, meses: Double(diasEntre($0.data, alvo)) / diasMes) }
    guard fluxos.contains(where: { $0.meses > 0 }) else { return nil }
    func saldo(_ r: Double) -> Double { venda - fluxos.reduce(0) { $0 + $1.valor * pow(1 + r, $1.meses) } }
    var baixo = -0.99, alto = 10.0
    if saldo(baixo) < 0 || saldo(alto) > 0 { return nil }
    for _ in 0..<100 {
        let meio = (baixo + alto) / 2
        if saldo(meio) > 0 { baixo = meio } else { alto = meio }
    }
    return (baixo + alto) / 2 * 100
}

/// `rendimentoAcima` do calc.js: quanto a TIR rende ao mês acima do banco, composto.
public func rendimentoAcima(_ tir: Double?, taxa: Double) -> Double? {
    guard let tir else { return nil }
    return ((1 + tir / 100) / (1 + taxa / 100) - 1) * 100
}

public struct ResumoVenda: Equatable, Sendable {
    public let lucro: Double?
    public let pctCusto: Double?
    public let pctVenda: Double?
}

/// `resumoVenda` do calc.js: lucro, % sobre o custo e % sobre a venda numa base de custo.
public func resumoVenda(_ venda: Double, custo: Double) -> ResumoVenda {
    if venda <= 0 || custo <= 0 { return ResumoVenda(lucro: nil, pctCusto: nil, pctVenda: nil) }
    return ResumoVenda(lucro: venda - custo, pctCusto: (venda / custo - 1) * 100, pctVenda: (venda - custo) / venda * 100)
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter TirTests`
Expected: `Test run with 3 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: TIR e conta do simulador no núcleo" -m "TIR mensal por bisseção, rendimento acima do banco e resumo da venda como no calc.js. Os vetores cobrem os quatro jeitos de não ter TIR (sem venda, sem gastos, nenhum mês passado, raiz fora de −99% a +1000%) e o gasto feito depois da data-alvo."
```

---

### Task 12: Séries dos gráficos

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Series.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SeriesTests.swift`

**Interfaces:**
- Consumes: `Obra`, `Gasto`, `fimCorrecao`, `corrigido`, `menorJS`, `doisDigitos`, `diasNoMes`.
- Produces: `public struct PontoEvolucao { let mes: String; let bruto: Double; let corrigido: Double }`; `public struct PontoMensal { let mes: String; let total: Double }`; `func ordenadoEstavel<T>(_ itens: [T], _ antes: (T, T) -> Bool) -> [T]` (interno, usado nas Tarefas 13 e na etapa 1B); `public func serieEvolucao(_ obra: Obra, taxa: Double, hoje: String) -> [PontoEvolucao]`; `public func serieMensal(_ gastos: [Gasto]) -> [PontoMensal]`; `public func serieEvolucaoAgregada(_ obras: [Obra], taxa: Double, hoje: String) -> [PontoEvolucao]`.

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SeriesTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

extension PontoEvolucao { var json: ValorJSON { .objeto(["mes": .texto(mes), "bruto": .numero(bruto), "corrigido": .numero(corrigido)]) } }
extension PontoMensal { var json: ValorJSON { .objeto(["mes": .texto(mes), "total": .numero(total)]) } }

struct SeriesTests {
    @Test func evolucao() {
        for c in Vetores.casos("calc.serieEvolucao") {
            let s = serieEvolucao(c.args[0].obra, taxa: c.args[1].numero, hoje: c.args[2].comoTexto!)
            confere(.lista(s.map(\.json)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func mensal() {
        for c in Vetores.casos("calc.serieMensal") {
            confere(.lista(serieMensal(c.args[0].gastos).map(\.json)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func agregada() {
        for c in Vetores.casos("calc.serieEvolucaoAgregada") {
            let s = serieEvolucaoAgregada(c.args[0].obras, taxa: c.args[1].numero, hoje: c.args[2].comoTexto!)
            confere(.lista(s.map(\.json)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func ordemEstavelNoEmpate() {
        let pares = [(1, "a"), (0, "b"), (1, "c"), (0, "d")]
        #expect(ordenadoEstavel(pares) { $0.0 < $1.0 }.map(\.1) == ["b", "d", "a", "c"])
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter SeriesTests`
Expected: FAIL na compilação: `cannot find type 'PontoEvolucao' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Series.swift`:

```swift
import Foundation

public struct PontoEvolucao: Equatable, Sendable {
    public let mes: String
    public let bruto: Double
    public let corrigido: Double
}

public struct PontoMensal: Equatable, Sendable {
    public let mes: String
    public let total: Double
}

/// Ordenação que mantém a ordem original no empate, como o sort do JavaScript.
func ordenadoEstavel<T>(_ itens: [T], _ antes: (T, T) -> Bool) -> [T] {
    itens.enumerated().sorted { a, b in
        if antes(a.element, b.element) { return true }
        if antes(b.element, a.element) { return false }
        return a.offset < b.offset
    }.map(\.element)
}

/// Chave de mês do calc.js: o ano como número, sem completar com zeros.
private func chaveMes(_ ano: Int, _ mes: Int) -> String { "\(ano)-" + doisDigitos(mes) }

private func anoMes(_ chave: String) -> (Int, Int) {
    (Int(chave.prefix(4)) ?? 0, Int(chave.dropFirst(5).prefix(2)) ?? 0)
}

/// `serieEvolucao` do calc.js: um ponto por mês do 1º gasto até o fim da correção, cortando no
/// último dia de cada mês; os últimos 24.
public func serieEvolucao(_ obra: Obra, taxa: Double, hoje: String) -> [PontoEvolucao] {
    if obra.gastos.isEmpty { return [] }
    let fim = fimCorrecao(obra, hoje: hoje)
    let gs = ordenadoEstavel(obra.gastos) { menorJS($0.data, $1.data) }
    let ini = String(gs[0].data.prefix(7))
    let fimMes = String(fim.prefix(7))
    let ultimo = menorJS(ini, fimMes) ? fimMes : ini
    var meses: [String] = []
    var (y, m) = anoMes(ini)
    for _ in 0..<600 {
        let chave = chaveMes(y, m)
        meses.append(chave)
        if chave == ultimo { break }
        m += 1
        if m > 12 { m = 1; y += 1 }
    }
    let pontos = meses.map { mes -> PontoEvolucao in
        let (ano, numeroMes) = anoMes(mes)
        var corte = mes + "-" + doisDigitos(diasNoMes(ano: ano, mes: numeroMes))
        if menorJS(fim, corte) { corte = fim }
        let ate = gs.filter { !menorJS(corte, $0.data) }
        return PontoEvolucao(mes: mes,
                             bruto: ate.reduce(0) { $0 + $1.valor },
                             corrigido: ate.reduce(0) { $0 + corrigido($1.valor, de: $1.data, ate: corte, taxa: taxa) })
    }
    return Array(pontos.suffix(24))
}

/// `serieMensal` do calc.js: bruto por mês, meses vazios em zero, os últimos 24.
public func serieMensal(_ gastos: [Gasto]) -> [PontoMensal] {
    if gastos.isEmpty { return [] }
    var por: [String: Double] = [:]
    for g in gastos {
        let k = String(g.data.prefix(7))
        por[k] = (por[k] ?? 0) + g.valor
    }
    let chaves = por.keys.sorted(by: menorJS)
    let fim = chaves[chaves.count - 1]
    var saida: [PontoMensal] = []
    var (y, m) = anoMes(chaves[0])
    for _ in 0..<600 {
        let chave = chaveMes(y, m)
        saida.append(PontoMensal(mes: chave, total: por[chave] ?? 0))
        if chave == fim { break }
        m += 1
        if m > 12 { m = 1; y += 1 }
    }
    return Array(saida.suffix(24))
}

/// `serieEvolucaoAgregada` do calc.js: soma das obras por mês; vendida fica congelada.
public func serieEvolucaoAgregada(_ obras: [Obra], taxa: Double, hoje: String) -> [PontoEvolucao] {
    let series = obras.map { serieEvolucao($0, taxa: taxa, hoje: hoje) }.filter { !$0.isEmpty }
    if series.isEmpty { return [] }
    let meses = Set(series.flatMap { $0.map(\.mes) }).sorted(by: menorJS)
    let pontos = meses.map { mes -> PontoEvolucao in
        var bruto = 0.0, corr = 0.0
        for s in series {
            var p: PontoEvolucao?
            for q in s { if !menorJS(mes, q.mes) { p = q } else { break } }
            if let p { bruto += p.bruto; corr += p.corrigido }
        }
        return PontoEvolucao(mes: mes, bruto: bruto, corrigido: corr)
    }
    return Array(pontos.suffix(24))
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter SeriesTests`
Expected: `Test run with 4 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: séries dos gráficos no núcleo" -m "Evolução bruto × corrigido, gasto por mês e a série agregada das obras, como no calc.js, com corte no último dia do mês e janela dos últimos 24. A ordenação mantém a ordem original no empate, como o sort do JavaScript, para a soma em ponto flutuante sair na mesma ordem."
```

---

### Task 13: A pagar, recentes e filtro dos lançamentos

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift`

**Interfaces:**
- Consumes: `Obra`, `Gasto`, `Topico`, `somarDias` (Tarefa 7), `ordenadoEstavel` (Tarefa 12), `menorJS`.
- Produces: `public struct ItemAPagar { let obraId: String; let gasto: Gasto }`; `public struct APagar { let total: Double; let qtd: Int; let itens: [ItemAPagar] }`; `public func aPagar(_ obras: [Obra], hoje: String, dias: Int = 30) -> APagar`; `public struct GastoRecente { let obraId, obraNome: String; let gasto: Gasto }`; `public func gastosRecentes(_ obras: [Obra], n: Int = 5) -> [GastoRecente]`; `public func semAcento(_ s: String?) -> String`; `public struct FiltroGastos { var texto: String?; var mes: String? }`; `public func filtraGastos(_ gastos: [Gasto], topicos: [String: Topico], filtro: FiltroGastos?) -> [Gasto]`.

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

extension APagar {
    var json: ValorJSON {
        .objeto(["total": .numero(total), "qtd": .numero(Double(qtd)),
                 "itens": .lista(itens.map { .objeto(["obraId": .texto($0.obraId), "gasto": .objeto($0.gasto.campos)]) })])
    }
}
extension GastoRecente {
    var json: ValorJSON { .objeto(["obraId": .texto(obraId), "obraNome": .texto(obraNome), "gasto": .objeto(gasto.campos)]) }
}

struct ListasTests {
    @Test func aPagarEmTrintaDias() {
        for c in Vetores.casos("calc.aPagar") {
            let r = c.args.count > 2
                ? aPagar(c.args[0].obras, hoje: c.args[1].comoTexto!, dias: Int(c.args[2].numero))
                : aPagar(c.args[0].obras, hoje: c.args[1].comoTexto!)
            confere(r.json, c.saida, .dinheiro, c.caso)
        }
    }

    @Test func recentes() {
        for c in Vetores.casos("calc.gastosRecentes") {
            let r = c.args.count > 1 ? gastosRecentes(c.args[0].obras, n: Int(c.args[1].numero)) : gastosRecentes(c.args[0].obras)
            confere(.lista(r.map(\.json)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func textoSemAcento() {
        for c in Vetores.casos("calc.semAcento") {
            #expect(semAcento(c.arg(0)?.textoOuNil) == c.saida.comoTexto, "\(c.caso)")
        }
    }

    @Test func filtroDosLancamentos() {
        for c in Vetores.casos("calc.filtraGastos") {
            let topicos = (c.args[1].comoObjeto ?? [:]).mapValues { t in
                Topico(id: t.comoObjeto!["id"]!.comoTexto!, nome: t.comoObjeto!["nm"]!.comoTexto!, icone: t.comoObjeto!["ic"]!.comoTexto!)
            }
            let f = c.args[2].comoObjeto.map { FiltroGastos(texto: $0["texto"]?.comoTexto, mes: $0["mes"]?.comoTexto) }
            let r = filtraGastos(c.args[0].gastos, topicos: topicos, filtro: f)
            confere(.lista(r.map { .objeto($0.campos) }), c.saida, .exata, c.caso)
        }
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter ListasTests`
Expected: FAIL na compilação: `cannot find type 'APagar' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift`:

```swift
import Foundation

public struct ItemAPagar: Equatable, Sendable {
    public let obraId: String
    public let gasto: Gasto
}

public struct APagar: Equatable, Sendable {
    public let total: Double
    public let qtd: Int
    public let itens: [ItemAPagar]
}

/// `aPagar` do calc.js: gastos com data depois de hoje e até hoje + `dias`, por data.
public func aPagar(_ obras: [Obra], hoje: String, dias: Int = 30) -> APagar {
    let limite = somarDias(hoje, dias)
    var total = 0.0, qtd = 0
    var itens: [ItemAPagar] = []
    for o in obras {
        for g in o.gastos where menorJS(hoje, g.data) && !menorJS(limite, g.data) {
            total += g.valor
            qtd += 1
            itens.append(ItemAPagar(obraId: o.id, gasto: g))
        }
    }
    return APagar(total: total, qtd: qtd, itens: ordenadoEstavel(itens) { menorJS($0.gasto.data, $1.gasto.data) })
}

public struct GastoRecente: Equatable, Sendable {
    public let obraId: String
    public let obraNome: String
    public let gasto: Gasto
}

/// `gastosRecentes` do calc.js: os n mais recentes de todas as obras, por data e depois id, decrescente.
/// O site compara com localeCompare; para datas e ids em base 36 dá a mesma ordem que a comparação de código.
public func gastosRecentes(_ obras: [Obra], n: Int = 5) -> [GastoRecente] {
    let todos = obras.flatMap { o in o.gastos.map { GastoRecente(obraId: o.id, obraNome: o.nome, gasto: $0) } }
    let ordenados = ordenadoEstavel(todos) { menorJS($1.gasto.data + $1.gasto.id, $0.gasto.data + $0.gasto.id) }
    // slice(0, n) do JavaScript: n negativo conta do fim.
    let fim = n >= 0 ? min(n, ordenados.count) : max(ordenados.count + n, 0)
    return Array(ordenados[..<fim])
}

/// `semAcento` do calc.js: minúsculas, sem os acentos combinantes (U+0300 a U+036F).
public func semAcento(_ s: String?) -> String {
    let decomposto = (s ?? "").lowercased().decomposedStringWithCanonicalMapping
    var r = String.UnicodeScalarView()
    r.append(contentsOf: decomposto.unicodeScalars.filter { !(0x300...0x36F).contains($0.value) })
    return String(r)
}

/// O `includes` do JavaScript: contém a sequência de caracteres (escalares Unicode).
func contem(_ texto: String, _ trecho: String) -> Bool {
    if trecho.isEmpty { return true }
    let a = Array(texto.unicodeScalars), b = Array(trecho.unicodeScalars)
    guard b.count <= a.count else { return false }
    for i in 0...(a.count - b.count) where a[i] == b[0] && Array(a[i..<(i + b.count)]) == b { return true }
    return false
}

public struct FiltroGastos: Equatable, Sendable {
    public var texto: String?
    public var mes: String?
    public init(texto: String? = nil, mes: String? = nil) { self.texto = texto; self.mes = mes }
}

/// `filtraGastos` do calc.js: texto na descrição ou no nome do tópico (sem acento) e mês AAAA-MM, em E.
public func filtraGastos(_ gastos: [Gasto], topicos: [String: Topico], filtro: FiltroGastos?) -> [Gasto] {
    let texto = semAcento(filtro?.texto)
    let mes = filtro?.mes ?? ""
    return gastos.filter { g in
        if !mes.isEmpty && String(g.data.prefix(7)) != mes { return false }
        if texto.isEmpty { return true }
        return contem(semAcento(g.descricao), texto) || contem(semAcento(topicos[g.topico]?.nome ?? g.topico), texto)
    }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter ListasTests`
Expected: `Test run with 4 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: a pagar, recentes e filtro dos lançamentos no núcleo" -m "O a pagar conta 30 dias de calendário a partir de amanhã, como o site depois da correção do limite; recentes ordena por data e id; o filtro procura sem acento na descrição ou no nome do tópico e combina com o mês. Os vetores cobrem o 30º dia exato, o empate de data e o tópico próprio apagado."
```

---

### Task 14: Parcelas e parcelamento Price

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Parcelas.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ParcelasTests.swift`

**Interfaces:**
- Consumes: `arredondarJS` (Tarefa 5), `addMesesClampado`, `dataISOValida` (Tarefa 7).
- Produces: `public struct ParcelaGerada { let valor: Double; let data: String }`; `public func gerarParcelas(_ total: Double, _ n: Int, _ dataISO: String) -> [ParcelaGerada]`; `public struct Parcelamento { let valorCompra, taxaMensal: Double; let nParcelas: Int; let totalCompra, jurosCompra: Double; let parcelas: [ParcelaGerada] }`; `public func parcelamentoCartao(_ valor: Double, _ n: Int, _ taxaMensal: Double, _ dataISO: String) -> Parcelamento?`.

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ParcelasTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

extension ParcelaGerada { var json: ValorJSON { .objeto(["valor": .numero(valor), "data": .texto(data)]) } }
extension Parcelamento {
    var json: ValorJSON {
        .objeto(["valorCompra": .numero(valorCompra), "taxaMensal": .numero(taxaMensal), "nParcelas": .numero(Double(nParcelas)),
                 "totalCompra": .numero(totalCompra), "jurosCompra": .numero(jurosCompra), "parcelas": .lista(parcelas.map(\.json))])
    }
}

struct ParcelasTests {
    @Test func parcelasComRestoNaUltima() {
        for c in Vetores.casos("calc.gerarParcelas") {
            guard let n = Int(exactly: c.args[1].numero) else {
                #expect(c.saida == .lista([]), "\(c.caso): n não inteiro dá lista vazia no site")
                continue
            }
            confere(.lista(gerarParcelas(c.args[0].numero, n, c.args[2].comoTexto!).map(\.json)), c.saida, .dinheiro, c.caso)
        }
    }

    @Test func parcelamentoPrice() {
        for c in Vetores.casos("calc.parcelamentoCartao") {
            guard let n = Int(exactly: c.args[1].numero) else {
                #expect(c.saida == .nulo, "\(c.caso): n não inteiro dá null no site")
                continue
            }
            let r = parcelamentoCartao(c.args[0].numero, n, c.args[2].numero, c.args[3].comoTexto!)
            confere(r?.json ?? .nulo, c.saida, .dinheiro, c.caso)
        }
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter ParcelasTests`
Expected: FAIL na compilação: `cannot find type 'ParcelaGerada' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Parcelas.swift`:

```swift
import Foundation

public struct ParcelaGerada: Equatable, Sendable {
    public let valor: Double
    public let data: String
}

/// `gerarParcelas` do calc.js: divide em centavos; o resto do arredondamento fica na última.
/// Vazio se o total não tem centavo positivo ou se há mais parcelas que centavos.
public func gerarParcelas(_ total: Double, _ n: Int, _ dataISO: String) -> [ParcelaGerada] {
    let centavos = arredondarJS(total * 100)
    guard centavos.isFinite, centavos > 0, n >= 1, Double(n) <= centavos else { return [] }
    let base = (centavos / Double(n)).rounded(.down)
    return (0..<n).map { i in
        ParcelaGerada(valor: (i == n - 1 ? centavos - base * Double(n - 1) : base) / 100,
                      data: addMesesClampado(dataISO, i))
    }
}

public struct Parcelamento: Equatable, Sendable {
    public let valorCompra: Double
    public let taxaMensal: Double
    public let nParcelas: Int
    public let totalCompra: Double
    public let jurosCompra: Double
    public let parcelas: [ParcelaGerada]
}

/// `parcelamentoCartao` do calc.js: prestação Price com primeiro vencimento em dataISO,
/// total arredondado ao centavo e parcelas iguais (a última absorve o resto).
public func parcelamentoCartao(_ valor: Double, _ n: Int, _ taxaMensal: Double, _ dataISO: String) -> Parcelamento? {
    guard valor.isFinite, valor > 0, (1...36).contains(n), taxaMensal.isFinite, taxaMensal >= 0, taxaMensal <= 100,
          dataISOValida(dataISO) else { return nil }
    let base = arredondarJS(valor * 100) / 100
    let i = taxaMensal / 100
    // expm1 e log1p, na fórmula do calc.js. A libm e o V8 podem diferir em 1 ulp aqui (decisão "Parcelamento Price").
    let prestacao = i == 0 ? base / Double(n) : base * i / (-expm1(-Double(n) * log1p(i)))
    let total = arredondarJS(prestacao * Double(n) * 100) / 100
    let centavos = arredondarJS(total * 100)
    guard centavos.isFinite, abs(centavos) <= 9_007_199_254_740_991 else { return nil }
    let parcelas = gerarParcelas(total, n, dataISO)
    if parcelas.isEmpty { return nil }
    return Parcelamento(valorCompra: base, taxaMensal: taxaMensal, nParcelas: n, totalCompra: total,
                        jurosCompra: arredondarJS((total - base) * 100) / 100, parcelas: parcelas)
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter ParcelasTests`
Expected: `Test run with 2 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: parcelas e parcelamento Price no núcleo" -m "gerarParcelas conta em centavos e deixa o resto na última; o parcelamento do cartão usa a prestação Price com expm1 e log1p, como o calc.js. Os vetores cobrem resto de centavo, 31/01 clampando em cada mês, mais parcelas que centavos, 36x com juros e as entradas recusadas."
```

---

### Task 15: Moeda: máscara, leitura e exibição

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Moeda.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MoedaTests.swift`

**Interfaces:**
- Consumes: `digitosMaisCurtos`, `numeroJS`, `toFixedJS`, `arredondarJS`, `aparadoJS`, `ehDigito`, `parseFloatJS` (Tarefa 5).
- Produces: `public func fmtDigitado(_ entrada: String?) -> String`; `public func fmtCompleto(_ entrada: String?) -> String`; `public func numParaCampo(_ n: Double?) -> String`; `public func lerNumero(_ texto: String?) -> Double`; `public func lerNumero(_ numero: Double) -> Double`; `public func moeda(_ valor: Double?) -> String`; `public func moedaCurta(_ n: Double) -> String`; `public func moedaCurtaSemZero(_ n: Double) -> String`; `public func fmtMeses(_ m: Double) -> String`; `func agruparMilhar(_ digitos: String) -> String` (interno).

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MoedaTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/// Entrada de texto como o JavaScript a recebe: número vira texto do JavaScript, nulo vira nil.
private func textoDeEntrada(_ v: ValorJSON?) -> String? {
    switch v {
    case .numero(let n)?: return numeroJS(n)
    case .texto(let s)?: return s
    default: return nil
    }
}

struct MoedaTests {
    @Test func mascaraAoDigitar() {
        for c in Vetores.casos("calc.fmtDigitado") { #expect(fmtDigitado(textoDeEntrada(c.arg(0))) == c.saida.comoTexto, "\(c.caso)") }
    }

    @Test func mascaraCompleta() {
        for c in Vetores.casos("calc.fmtCompleto") { #expect(fmtCompleto(textoDeEntrada(c.arg(0))) == c.saida.comoTexto, "\(c.caso)") }
    }

    @Test func numeroParaCampo() {
        for c in Vetores.casos("calc.numParaCampo") {
            let n: Double? = c.arg(0)?.comoNumero          // nulo e texto vazio dão "" no site
            #expect(numParaCampo(n) == c.saida.comoTexto, "\(c.caso)")
        }
    }

    @Test func leituraDoCampo() {
        for c in Vetores.casos("calc.parseNum") {
            let lido = c.arg(0)?.comoNumero.map { lerNumero($0) } ?? lerNumero(c.arg(0)?.comoTexto)
            confere(.numero(lido), c.saida, .exata, c.caso)
        }
    }

    @Test func moedaPorExtenso() {
        for c in Vetores.casos("calc.money") { #expect(moeda(c.arg(0)?.comoNumero) == c.saida.comoTexto, "\(c.caso)") }
        #expect(moeda(1234.5).contains("\u{00A0}"), "espaço não separável depois de R$, como o Intl do site")
    }

    @Test func moedaCurtaComoOSite() {
        for c in Vetores.casos("calc.moneyShort") { #expect(moedaCurta(c.args[0].numero) == c.saida.comoTexto, "\(c.caso)") }
        for c in Vetores.casos("calc.moneyCurto") { #expect(moedaCurtaSemZero(c.args[0].numero) == c.saida.comoTexto, "\(c.caso)") }
    }

    @Test func mesesDeObraPorExtenso() {
        for c in Vetores.casos("calc.fmtMeses") { #expect(fmtMeses(c.args[0].numero) == c.saida.comoTexto, "\(c.caso)") }
    }

    /// JSON não leva infinito nem NaN, então estes ficam fora dos vetores; as saídas são as do Node.
    @Test func infinitoENaNComoOSite() {
        #expect(moeda(.infinity) == "R$\u{a0}∞")
        #expect(moeda(-.infinity) == "-R$\u{a0}∞")
        #expect(moeda(.nan) == "R$\u{a0}0,00")
        #expect(moedaCurta(.infinity) == "R$ Infinity mi")
        #expect(fmtMeses(.infinity) == "Infinity meses")
        #expect(fmtMeses(.nan) == "NaN meses")
        #expect(lerNumero(.infinity) == 0)
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter MoedaTests`
Expected: FAIL na compilação: `cannot find 'fmtDigitado' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Moeda.swift`:

```swift
import Foundation

/* Dinheiro como o site: máscara dos campos (fmtDigitado, fmtCompleto, numParaCampo, parseNum
   do calc.js) e exibição (money, moneyShort e moneyCurto). Não usa NumberFormatter: o ICU do
   aparelho pode mudar entre versões do iOS, e o espaço depois de "R$" tem de ser o U+00A0 do site. */

/// Agrupa dígitos de milhar com ponto ("1234567" → "1.234.567").
func agruparMilhar(_ digitos: String) -> String {
    var r = ""
    for (i, c) in digitos.enumerated() {
        if i > 0 && (digitos.count - i) % 3 == 0 { r.append(".") }
        r.append(c)
    }
    return r
}

/// `fmtDigitado` do calc.js: só dígitos e uma vírgula, milhar com ponto, até 2 centavos.
public func fmtDigitado(_ entrada: String?) -> String {
    let v = Array((entrada ?? "").unicodeScalars.filter { ehDigito($0) || $0 == "," })
    let virgula = v.firstIndex(of: ",")
    var inteiro = String(String.UnicodeScalarView(virgula.map { Array(v[..<$0]) } ?? v))
    while inteiro.count > 1, inteiro.first == "0" { inteiro.removeFirst() }
    let centavos: String? = virgula.map { i in String(String.UnicodeScalarView(v[(i + 1)...].filter { $0 != "," }.prefix(2))) }
    if inteiro.isEmpty && centavos == nil { return "" }
    let agrupado = agruparMilhar(inteiro.isEmpty ? "0" : inteiro)
    return centavos.map { agrupado + "," + $0 } ?? agrupado
}

/// `fmtCompleto` do calc.js: completa os centavos ("2.000" → "2.000,00").
public func fmtCompleto(_ entrada: String?) -> String {
    let v = fmtDigitado(entrada)
    if v.isEmpty { return "" }
    let partes = v.split(separator: ",", omittingEmptySubsequences: false)
    let centavos = partes.count > 1 ? String(partes[1]) : ""
    return String(partes[0]) + "," + String((centavos + "00").prefix(2))
}

/// `numParaCampo` do calc.js: número salvo → texto do campo.
public func numParaCampo(_ n: Double?) -> String {
    guard let n else { return "" }
    var s = numeroJS(n)
    if let p = s.firstIndex(of: ".") { s.replaceSubrange(p...p, with: ",") }
    return fmtCompleto(s)
}

/// `parseNum` do calc.js para texto: com vírgula, pontos são milhar; sem vírgula, só some o
/// ponto seguido de exatamente três dígitos e depois ponto ou fim ("1.5" continua 1,5).
public func lerNumero(_ texto: String?) -> Double {
    var u = Array(aparadoJS(texto ?? "").unicodeScalars.filter { ehDigito($0) || $0 == "," || $0 == "." || $0 == "-" })
    if u.contains(",") {
        u.removeAll { $0 == "." }
        if let i = u.firstIndex(of: ",") { u[i] = "." }
    } else {
        var saida: [Unicode.Scalar] = []
        for (i, c) in u.enumerated() {
            if c == "." && i + 3 < u.count && u[(i + 1)...(i + 3)].allSatisfy(ehDigito) && (i + 4 == u.count || u[i + 4] == ".") { continue }
            saida.append(c)
        }
        u = saida
    }
    guard let n = parseFloatJS(String(String.UnicodeScalarView(u))), n.isFinite else { return 0 }
    return n
}

/// `parseNum` do calc.js para número: finito passa, o resto vira 0.
public func lerNumero(_ numero: Double) -> Double { numero.isFinite ? numero : 0 }

/// `money` do site (Intl pt-BR, BRL): "R$ 1.234,56" com U+00A0 depois de "R$". Arredonda o meio
/// para longe do zero sobre os dígitos mais curtos, como o ICU; NaN e zero viram "R$ 0,00".
public func moeda(_ valor: Double?) -> String {
    let x = valor ?? 0
    let v = (x.isNaN || x == 0) ? 0 : x
    let sinal = v < 0 ? "-" : ""
    if v.isInfinite { return sinal + "R$\u{00A0}∞" }
    var inteiro = "0", centavos = "00"
    if v != 0 {
        let (d, n) = digitosMaisCurtos(abs(v))
        var parteInteira: String, fracao: String
        if n <= 0 { parteInteira = "0"; fracao = String(repeating: "0", count: -n) + d }
        else if n >= d.count { parteInteira = d + String(repeating: "0", count: n - d.count); fracao = "" }
        else { let i = d.index(d.startIndex, offsetBy: n); parteInteira = String(d[..<i]); fracao = String(d[i...]) }
        var duas = Array((fracao + "00").prefix(2))
        var digitosInteiros = Array(parteInteira)
        var sobe = fracao.count > 2 && fracao[fracao.index(fracao.startIndex, offsetBy: 2)] >= "5"
        var i = 1
        while sobe && i >= 0 {
            if duas[i] == "9" { duas[i] = "0"; i -= 1 } else { duas[i] = Character(String(duas[i].wholeNumberValue! + 1)); sobe = false }
        }
        var j = digitosInteiros.count - 1
        while sobe && j >= 0 {
            if digitosInteiros[j] == "9" { digitosInteiros[j] = "0"; j -= 1 } else { digitosInteiros[j] = Character(String(digitosInteiros[j].wholeNumberValue! + 1)); sobe = false }
        }
        if sobe { digitosInteiros.insert("1", at: 0) }
        inteiro = String(digitosInteiros)
        centavos = String(duas)
    }
    return sinal + "R$\u{00A0}" + agruparMilhar(inteiro) + "," + centavos
}

/// `moneyShort` do site: "R$ 1,23 mi" e "R$ 8,5 mil" (espaço comum), abaixo de mil cai em moeda(_:).
public func moedaCurta(_ n: Double) -> String {
    let a = abs(n)
    let s = n < 0 ? "-" : ""
    func comVirgula(_ t: String) -> String {
        guard let p = t.firstIndex(of: ".") else { return t }
        var r = t
        r.replaceSubrange(p...p, with: ",")
        return r
    }
    if a >= 1e6 { return s + "R$ " + comVirgula(toFixedJS(a / 1e6, a >= 1e7 ? 1 : 2)) + " mi" }
    if a >= 1000 { return s + "R$ " + comVirgula(toFixedJS(a / 1000, a >= 10000 ? 0 : 1)) + " mil" }
    return moeda(n)
}

/// `moneyCurto` do site: tira o ",0" de "R$ 8,0 mil" e o ",00" de "R$ 1,00 mi".
public func moedaCurtaSemZero(_ n: Double) -> String {
    let s = moedaCurta(n)
    for sufixo in [" mil", " mi"] where s.hasSuffix(sufixo) {
        let base = s.dropLast(sufixo.count)
        if let virgula = base.lastIndex(of: ",") {
            let depois = base[base.index(after: virgula)...]
            if !depois.isEmpty && depois.allSatisfy({ $0 == "0" }) { return String(base[..<virgula]) + sufixo }
        }
        return s
    }
    return s
}

/// `fmtMeses` do site: "começando" abaixo de 1 mês, "1 mês", "N meses".
public func fmtMeses(_ m: Double) -> String {
    if m < 1 { return "começando" }
    let r = arredondarJS(m)
    return numeroJS(r) + (r == 1 ? " mês" : " meses")
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter MoedaTests`
Expected: `Test run with 8 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: máscara e exibição de dinheiro do site no núcleo" -m "A máscara dos campos (fmtDigitado, fmtCompleto, numParaCampo e parseNum) e a exibição (money, moneyShort e moneyCurto) saem iguais às do site, inclusive nos empates de meio centavo e no espaço não separável depois de R$. Sem NumberFormatter: o arredondamento dele empata para o par e o dado de localidade do iOS pode mudar."
```

---

### Task 16: Orçamento previsto × real

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift`

**Interfaces:**
- Consumes: `Obra`, `totalBruto` (Tarefa 10), `arredondarJS`, `menorJS`.
- Produces: `public enum NivelOrcamento: String { case ok, perto, passou }`; `public let limiarPerto = 90.0`; `public struct ItemOrcamento { let id: String?; let previsto, gasto, pct, sobra: Double; let nivel: NivelOrcamento }`; `public struct ForaOrcamento { let id: String; let gasto: Double }`; `public struct ResumoOrcamento { let modo: String; let geral: ItemOrcamento; let topicos: [ItemOrcamento]; let fora: [ForaOrcamento]; let foraTotal: Double }`; `public func orcamentoObra(_ obra: Obra) -> ResumoOrcamento?`. A etapa 1B usa `geral.pct`, `geral.nivel` e `geral.sobra` na lista de obras.

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

extension ItemOrcamento {
    var campos: [String: ValorJSON] {
        ["previsto": .numero(previsto), "gasto": .numero(gasto), "pct": .numero(pct), "sobra": .numero(sobra), "nivel": .texto(nivel.rawValue)]
    }
}
extension ResumoOrcamento {
    /// Mesma forma do retorno do orcamentoObra do site.
    var json: ValorJSON {
        var r = geral.campos
        r["modo"] = .texto(modo)
        r["topicos"] = .lista(topicos.map { t in var c = t.campos; c["id"] = .texto(t.id ?? ""); return .objeto(c) })
        r["fora"] = .lista(fora.map { .objeto(["id": .texto($0.id), "gasto": .numero($0.gasto)]) })
        r["foraTotal"] = .numero(foraTotal)
        return .objeto(r)
    }
}

struct OrcamentoTests {
    @Test func previstoVersusReal() {
        for c in Vetores.casos("calc.orcamentoObra") {
            confere(orcamentoObra(c.args[0].obra)?.json ?? .nulo, c.saida, .dinheiro, c.caso)
        }
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter OrcamentoTests`
Expected: FAIL na compilação: `cannot find type 'ItemOrcamento' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift`:

```swift
import Foundation

/* Orçamento previsto × real, como o orcamentoObra do calc.js. Base sempre bruta (inclui parcelas
   a vencer). O pct arredondado é o que a tela mostra e decide o nível, então cor e número não discordam. */

public enum NivelOrcamento: String, Sendable {
    case ok, perto, passou
}

/// LIMIAR_PERTO do calc.js: a partir de 90% do previsto o nível é "perto".
public let limiarPerto = 90.0

public struct ItemOrcamento: Equatable, Sendable {
    /// Tópico, no modo por tópico; nil no resumo e no modo total.
    public let id: String?
    public let previsto: Double
    public let gasto: Double
    /// Inteiro (Math.round do JavaScript), guardado como Double.
    public let pct: Double
    public let sobra: Double
    public let nivel: NivelOrcamento
}

public struct ForaOrcamento: Equatable, Sendable {
    public let id: String
    public let gasto: Double
}

public struct ResumoOrcamento: Equatable, Sendable {
    /// "total" ou "topicos".
    public let modo: String
    public let geral: ItemOrcamento
    public let topicos: [ItemOrcamento]
    public let fora: [ForaOrcamento]
    public let foraTotal: Double
}

func itemOrcamento(_ id: String?, gasto: Double, previsto: Double) -> ItemOrcamento {
    let pct = arredondarJS(gasto / previsto * 100)
    let nivel: NivelOrcamento = gasto - previsto > 0.005 ? .passou : pct >= limiarPerto ? .perto : .ok
    return ItemOrcamento(id: id, previsto: previsto, gasto: gasto, pct: pct, sobra: previsto - gasto, nivel: nivel)
}

private func positivoFinito(_ v: ValorJSON?) -> Double? {
    guard let n = v?.comoNumero, n.isFinite, n > 0 else { return nil }
    return n
}

/// `orcamentoObra` do calc.js; nil sem orçamento válido.
public func orcamentoObra(_ obra: Obra) -> ResumoOrcamento? {
    guard let orc = obra.orcamento?.comoObjeto else { return nil }
    if orc["modo"] == .texto("topicos") {
        let previstos = orc["topicos"]?.comoObjeto ?? [:]
        let ids = previstos.keys.filter { positivoFinito(previstos[$0]) != nil }
        if ids.isEmpty { return nil }
        var porTopico: [String: Double] = [:]
        for g in obra.gastos { porTopico[g.topico] = (porTopico[g.topico] ?? 0) + g.valor }
        let topicos = ids.map { itemOrcamento($0, gasto: porTopico[$0] ?? 0, previsto: positivoFinito(previstos[$0])!) }
            .sorted { a, b in
                let d = b.gasto / b.previsto - a.gasto / a.previsto
                if d != 0 && !d.isNaN { return d < 0 }
                return menorJS(a.id!, b.id!)
            }
        let fora = porTopico.keys.filter { !ids.contains($0) && porTopico[$0]! > 0 }
            .map { ForaOrcamento(id: $0, gasto: porTopico[$0]!) }
            .sorted { a, b in a.gasto != b.gasto ? a.gasto > b.gasto : menorJS(a.id, b.id) }
        let previsto = topicos.reduce(0) { $0 + $1.previsto }
        let gasto = topicos.reduce(0) { $0 + $1.gasto }
        return ResumoOrcamento(modo: "topicos", geral: itemOrcamento(nil, gasto: gasto, previsto: previsto),
                               topicos: topicos, fora: fora, foraTotal: fora.reduce(0) { $0 + $1.gasto })
    }
    guard let total = positivoFinito(orc["total"]) else { return nil }
    return ResumoOrcamento(modo: "total", geral: itemOrcamento(nil, gasto: totalBruto(obra), previsto: total),
                           topicos: [], fora: [], foraTotal: 0)
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter OrcamentoTests`
Expected: `Test run with 1 test … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: orçamento previsto × real no núcleo" -m "Modo total e por tópico, com o pct arredondado decidindo o nível (ok, perto a partir de 90%, passou com mais de meio centavo acima), tópicos pela razão gasto/previsto e o que ficou fora do orçamento, como o orcamentoObra do calc.js."
```

---

### Task 17: Regras da fila de escrita e da versão

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Fila.swift`
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Versao.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FilaTests.swift`

**Interfaces:**
- Consumes: `numeroJS`, `verdadeiroJS`, `paraNumeroJS`, `ehDigito` (Tarefa 5).
- Produces: `public func erroEhTerminal(codigo: String?) -> Bool`; `public func proximoBackoff(_ tentativa: Double) -> Int` (milissegundos); `public func versaoMaior(_ a: String?, _ b: String?) -> Bool`. O Sincronizador da etapa 1B usa os dois primeiros.

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FilaTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

struct FilaTests {
    @Test func erroTerminal() {
        for c in Vetores.casos("calc.erroEhTerminal") {
            var codigo: String?
            if let o = c.arg(0)?.comoObjeto, verdadeiroJS(o["code"]) {
                switch o["code"]! {
                case .texto(let s): codigo = s
                case .numero(let n): codigo = numeroJS(n)
                default: codigo = nil
                }
            }
            #expect(erroEhTerminal(codigo: codigo) == c.saida.comoBooleano, "\(c.caso)")
        }
    }

    @Test func backoff() {
        for c in Vetores.casos("calc.proximoBackoff") {
            #expect(Double(proximoBackoff(paraNumeroJS(c.arg(0)))) == c.saida.comoNumero, "\(c.caso)")
        }
    }

    @Test func versao() {
        for c in Vetores.casos("calc.versaoMaior") {
            #expect(versaoMaior(c.arg(0)?.textoOuNil, c.arg(1)?.textoOuNil) == c.saida.comoBooleano, "\(c.caso)")
        }
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter FilaTests`
Expected: FAIL na compilação: `cannot find 'erroEhTerminal' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Fila.swift`:

```swift
import Foundation

/* Regras puras da fila de escrita, como no calc.js. */

private let codigosTerminais: Set<String> = ["permission-denied", "unauthenticated", "invalid-argument",
    "not-found", "failed-precondition", "unimplemented", "out-of-range"]

/// `erroEhTerminal` do calc.js: erro que não melhora tentando de novo. Aceita "firestore/PERMISSION_DENIED";
/// erro sem código é falha de transporte e conta como transitório.
public func erroEhTerminal(codigo: String?) -> Bool {
    guard let codigo else { return false }
    let normal = codigo.lowercased().replacingOccurrences(of: "_", with: "-")
        .split(separator: "/", omittingEmptySubsequences: false).last.map(String.init) ?? ""
    return codigosTerminais.contains(normal)
}

/// `proximoBackoff` do calc.js, em milissegundos: 1 s, 2 s, 4 s, 8 s, 16 s e trava em 30 s.
public func proximoBackoff(_ tentativa: Double) -> Int {
    let n = max(0, (tentativa.isNaN ? 0 : tentativa).rounded(.down))
    return Int(min(30_000, 1000 * pow(2, n)))
}
```

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Versao.swift`:

```swift
/// `versaoMaior` do calc.js: "1.0.10" > "1.0.9"; o que não for x.y.z não dispara aviso.
public func versaoMaior(_ a: String?, _ b: String?) -> Bool {
    func partes(_ v: String?) -> [Double]? {
        guard let v else { return nil }
        let p = v.split(separator: ".", omittingEmptySubsequences: false)
        guard p.count == 3, p.allSatisfy({ !$0.isEmpty && $0.unicodeScalars.allSatisfy(ehDigito) }) else { return nil }
        return p.map { Double($0)! }
    }
    guard let x = partes(a), let y = partes(b) else { return false }
    for i in 0..<3 where x[i] != y[i] { return x[i] > y[i] }
    return false
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter FilaTests`
Expected: `Test run with 3 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: regras da fila de escrita e da versão no núcleo" -m "Erro terminal com os mesmos códigos e a mesma normalização do calc.js (prefixo, sublinhado, maiúscula), backoff de 1 s a 30 s e a comparação de versão x.y.z. A sincronização da etapa 1B usa as duas primeiras."
```

---

### Task 18: Chave do token, gerador de id e cobertura total

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Miudezas.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MiudezasTests.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CoberturaTests.swift`

**Interfaces:**
- Consumes: todos os grupos dos vetores.
- Produces: `public func chaveDoToken(_ token: String) -> String` (djb2 em base 36); `public func agoraEmMilissegundos() -> Int64`; `public func gerarId(agoraMs: Int64 = agoraEmMilissegundos(), sorteio: (Int) -> Int = { Int.random(in: 0..<$0) }) -> String`; `CoberturaTests.gruposLidosNosTestes() -> Set<String>` (lê os próprios arquivos de teste: grupo novo, inclusive os do cadastro da etapa 1B, entra sem mexer aqui).

- [ ] **Step 1: Escrever os testes que falham**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MiudezasTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

struct MiudezasTests {
    @Test func chaveDoTokenIgualAoPushJs() {
        for c in Vetores.casos("push.hashEndpoint") { #expect(chaveDoToken(c.args[0].comoTexto!) == c.saida.comoTexto, "\(c.caso)") }
    }

    @Test func prefixoDoIdEmBase36() {
        for c in Vetores.casos("id.base36") {
            let id = gerarId(agoraMs: Int64(c.args[0].numero), sorteio: { _ in 0 })
            #expect(id == c.saida.comoTexto! + "0000", "\(c.caso)")
        }
    }

    @Test func idTemQuatroCaracteresAleatorios() {
        let base36 = Set("0123456789abcdefghijklmnopqrstuvwxyz")
        let id = gerarId(agoraMs: 1_759_750_000_000, sorteio: { _ in 35 })
        #expect(id.hasSuffix("zzzz"))
        #expect(id.allSatisfy(base36.contains))
        // O sorteio padrão só pelo formato: dois ids no mesmo milissegundo podem coincidir (36^4 finais),
        // então a unicidade se confere com milissegundos diferentes, como acontece no app.
        let padrao = gerarId()
        #expect(padrao.count > 4 && padrao.allSatisfy(base36.contains))
        #expect(Set((0..<200).map { gerarId(agoraMs: 1_759_750_000_000 + Int64($0)) }).count == 200)
    }
}
```

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CoberturaTests.swift`:

```swift
import Foundation
import Testing
@testable import CusttaNucleo

/* Todo grupo dos vetores precisa de um teste que leia os casos dele. Em vez de uma lista escrita à
   mão, a cobertura lê os próprios arquivos de teste desta pasta: grupo novo no gerador do site sem
   nenhuma leitura no núcleo faz este falhar (o site ganhou regra que o app ainda não tem). */
struct CoberturaTests {
    static func gruposLidosNosTestes() throws -> Set<String> {
        let pasta = URL(filePath: #filePath).deletingLastPathComponent()
        let leitura = /casos\("([^"]+)"\)/
        var grupos: Set<String> = []
        for arquivo in try FileManager.default.contentsOfDirectory(at: pasta, includingPropertiesForKeys: nil)
        where arquivo.pathExtension == "swift" {
            for m in try String(contentsOf: arquivo, encoding: .utf8).matches(of: leitura) { grupos.insert(String(m.1)) }
        }
        return grupos
    }

    @Test func todoGrupoTemTeste() throws {
        let lidos = try Self.gruposLidosNosTestes()
        let semTeste = Set(Vetores.todos.grupos.keys).subtracting(lidos).sorted()
        #expect(semTeste.isEmpty, "grupos sem teste no núcleo: \(semTeste)")
        let sumiram = lidos.subtracting(Vetores.todos.grupos.keys).sorted()
        #expect(sumiram.isEmpty, "testes que leem grupos que o gerador não produz mais: \(sumiram)")
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter "MiudezasTests|CoberturaTests"`
Expected: FAIL na compilação: `cannot find 'chaveDoToken' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Miudezas.swift`:

```swift
import Foundation

/// `hashEndpoint` do push.js: djb2 sobre as unidades UTF-16 do token, em 32 bits sem sinal, base 36.
/// É a chave do token em `push/{uid}.tokens`.
public func chaveDoToken(_ token: String) -> String {
    var h: UInt32 = 5381
    for c in token.utf16 { h = (h &<< 5) &+ h &+ UInt32(c) }
    return String(h, radix: 36)
}

private let base36: [Character] = Array("0123456789abcdefghijklmnopqrstuvwxyz")

/// Milissegundos desde 1970, inteiros, como o Date.now() do JavaScript.
public func agoraEmMilissegundos() -> Int64 { Int64((Date().timeIntervalSince1970 * 1000).rounded(.down)) }

/// `uid()` do app.js: milissegundos em base 36 mais 4 caracteres aleatórios de base 36.
public func gerarId(agoraMs: Int64 = agoraEmMilissegundos(), sorteio: (Int) -> Int = { Int.random(in: 0..<$0) }) -> String {
    String(agoraMs, radix: 36) + String((0..<4).map { _ in base36[sorteio(36)] })
}
```

- [ ] **Step 4: Rodar o pacote inteiro**

Run: `swift test --package-path app-ios/CusttaNucleo && npm run test:unit`
Expected: `Test run with 66 tests in 16 suites passed` (o número exato pode variar se um teste for dividido; nenhum pode falhar) e o `test:unit` verde.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: chave do token, gerador de id e cobertura total do núcleo" -m "A chave do token de push é o mesmo djb2 em base 36 do push.js, e o id segue o uid() do app.js (milissegundos em base 36 mais 4 aleatórios). O teste de cobertura lê os próprios arquivos de teste e falha se o gerador do site ganhar um grupo que nenhum teste do núcleo lê: regra nova no site não passa calada para o app."
```

Depois do último commit, o Orquestrador tira o PR 3 (`feat/nucleo-swift`) de rascunho e confere que o job `nucleo` do workflow `app-ios` ficou verde.

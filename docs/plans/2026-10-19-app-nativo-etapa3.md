# Dentro da obra (etapa 3 do app nativo) — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> Neste time: o Forja implementa uma tarefa por vez, o Lupa revisa cada uma antes da próxima; nas tarefas de tela, o Verniz confere o simulador lado a lado com o mockup aprovado. Ninguém faz commit, push ou PR sem o Orquestrador pedir; quando pedir, valem os comandos de commit de cada tarefa.

**Goal:** O app nativo passa a mostrar e gravar o que mora dentro da obra: o orçamento previsto × real (a linha na obra, a tela e a folha), o detalhe do tópico, a folha "A pagar" com a edição que volta à folha de origem, a busca e o filtro por mês e os afazeres, com as regras do site conferidas pelos vetores, num PR do site e nos PRs do app da seção "PRs do app", cada um com um build no TestFlight na conta de sempre.

**Architecture:** As dez regras que hoje só existem no `app.js` sobem antes para o `calc.js` e o `dados.js` (PR 0), com a cópia em Swift no `CusttaNucleo` conferida pelos vetores no mesmo commit; o filtro de mês preso é consertado no site e no app pela mesma regra. O núcleo ganha as mutações do orçamento e dos afazeres e as regras novas do app, com teste próprio; o app grava pelo `gravar` da etapa 2, que já recusa o `nao-carregado`. As telas novas, a forma da volta à folha de origem e a das teclas encaixadas saíram do conselho de 19/10 e estão em "Decisões do conselho", antes do PR 1.

**Tech Stack:** SwiftUI no iOS 26 (Swift 6 estrito; Xcode 26.6 na CI), Swift Testing, XCTest e XCUITest, pacote `CusttaNucleo`; Node (`node:test`) e Playwright para o site; emuladores do Firebase para a conferência cruzada.

**Spec:** [`docs/specs/2026-10-18-app-nativo-etapa3-design.md`](../specs/2026-10-18-app-nativo-etapa3-design.md). Inventário do site, com arquivo e linha conferidos na main `33ba862`: [`2026-10-18-app-nativo-etapa3-inventario.md`](2026-10-18-app-nativo-etapa3-inventario.md). Mockup aprovado: `~/Documents/custta-mockups/nativo/etapa3/` (abrir no Chrome; o `LEIA-ME.md` resume as duas partes). O conselho de 19/10 está em "Decisões do conselho" e na nota "Conselho — dentro da obra (etapa 3)" do Maestri.

**Como este plano foi escrito.** O código das tarefas saiu de protótipos feitos no scratch e fatiados num commit por tarefa; o texto de cada tarefa foi gerado das fatias (arquivo novo inteiro, alteração em diff, arquivos gerados só pelo comando) e conferido aplicando o plano numa cópia limpa da `origin/main` (`012c392`): a árvore de cada tarefa sai igual, byte a byte, à da fatia. No PR 0, cada fatia foi conferida sozinha: os testes da tarefa sobre o commit anterior (o "ver falhar" deste texto é a saída real), a tarefa inteira (`node scripts/vetores-calc.mjs`, `npm run test:unit`, `swift test` do núcleo e as suítes de browser que ela toca), mutação nas cópias em Swift (79 de 79 mortas pelos vetores) e na cola do `app.js` (47 de 47 pelas suítes de browser; o teste do filtro de mês, duas vezes) e, no fim, o `npm run test:browser` inteiro, com os emuladores. Como os PRs do app foram provados está no começo da seção de cada um.

## Global Constraints

- iOS 26.0 mínimo, iPhone. Nada que só exista no SDK do iOS 27: a CI compila com o Xcode 26.6 (Swift 6.3.3); o Mac do time tem o 27 e não tem o runtime do 26 (o que só o iOS 26 prova, a CI prova).
- Swift 6 com concorrência estrita e nenhum aviso de compilador novo.
- Nenhuma dependência nova, no app ou no site; nada de runtime novo no browser; CSP do site intacta.
- Português no código, nos identificadores, nos comentários e na interface.
- Cores só por tokens (`scripts/cores-app-ios.mjs`, conferido por `tests/app-ios.test.cjs`); ícones do `icons.js` pelo `scripts/icones-app-ios.mjs`; SF Symbols só onde a etapa 2 já usa e onde a tarefa disser.
- Nunca vidro dentro de vidro: vidro só nos cartões, pílulas e navegação da tela; dentro da folha, tudo sólido (a folha já é o vidro).
- Formato do estado sem chave nova; `firestore.rules` não muda nesta etapa.
- O app grava exatamente o que o site gravaria com as mesmas respostas: regra nova em `calc.js`/`dados.js` entra nos vetores com leitor no núcleo no mesmo commit, e cada mutação passa pela conferência cruzada, conferida passo a passo, não só no fim.
- Textos: os do site, menos os que o mockup aprovado mudou (o spec lista; as divergências de texto do plano estão em "Decisões").
- Reduzir movimento respeitado em toda animação (`tests/app-ios.test.cjs`); `lineLimit`/`minimumScaleFactor` só nos componentes da lista fixa da guarda.
- O PR do site só muda arquivos que já existem (mais a suíte nova `tests/browser/dentro-da-obra.cjs`), e sobe o `CACHE` do `sw.js` uma vez, no fim (o comentário do topo pede).
- Commits: autor só `Giovani Stuchi <stuchigiovani@gmail.com>`, sem `Co-Authored-By` e sem rodapé; título conventional em português com acento; corpo em prosa; um commit por tarefa; branch e PR, nunca direto na `main`.
- O app grava na conta de sempre (aprovado pelo Giovani em 18/10); os itens do checklist que tiram dado usam uma obra de teste criada no app e apagada no fim.
- Um simulador por agente (`CUSTTA_SIMULADOR=<udid>`): `D9F432D6` é do Forja; os testes de tela rodam com `-collect-test-diagnostics never`. Sem variável, o app de Debug fala com o Firebase de produção: os testes de tela passam pelo `abrirApp` (falsos) ou pelos emuladores.

## Decisões

Do Giovani, em 18/10 ("sim nas três") e 21/10 (a pele azul), e do protótipo do PR 0. As decisões dos PRs do app, inclusive as do conselho de 19/10, estão em "Decisões do conselho", antes do PR 1.

| Decisão | Escolha | Por quê |
| --- | --- | --- |
| A décima regra | O subtítulo da folha do A pagar ("{N} vencimento(s) · a partir de amanhã") entra no PR 0 (Tarefa 9) | Aprovada pelo Giovani em 18/10; o texto não estava no núcleo e é obrigatório no mockup |
| Os três alinhamentos do site com o app | Entram no PR 0: o orçamento que guarda o que a folha não mostra (Tarefa 3), o afazer marcado ou desmarcado no começo da lista (Tarefa 5) e a busca aparada (Tarefa 7) | Aprovados em 18/10: uma regra só para os dois, nos vetores |
| Conta | Os builds da etapa 3 gravam na conta de sempre | Aprovado em 18/10; obra de teste para os itens do checklist que tiram dado |
| Onde a busca é aparada | Dentro do `filtraGastos`, depois do `semAcento`, e não num `trim()` da cola, como o spec descrevia | Uma regra só, nos vetores; o campo continua mostrando o que a pessoa digitou |
| Teto de 100 tópicos na gravação do orçamento | O `orcamentoGravado` não corta | O corte da leitura escolhe pela ordem de inserção, que o Firestore do app não guarda; só se passa de 100 com mais de 29 tópicos fora da folha, que Ajustes não deixa existir |
| Afazer apagado em outro aparelho | Apagar de novo não grava nada | Antes, gravava o mesmo documento outra vez; a lista se redesenha igual |
| O texto "N gasto(s) · P% da obra" do resumo do tópico | Fica no `app.js`; o app escreve o dele, com teste próprio | O resumo (os números) é a regra; uma 11ª regra só de texto não foi pedida |
| Mês escolhido sem gasto | Entra na lista de meses com zero, no site e no app | O conserto do achado 1: o filtro que vale nunca some do seletor |
| A pele azul | Sai do site e do app (#81): o Custta fica só com a esmeralda, no claro e no escuro. Os PRs do app nascem sem o azul, com testes, laudos, auditorias e cenas nos dois temas | Decisão do Giovani em 21/10, mesclada antes do PR 1 do app; as fatias do PR 1 foram refeitas sobre a main com ela |

## Como entregar

- Cada PR nasce num worktree novo a partir da `origin/main` atualizada. PR 0: branch `feat/regras-de-dentro-da-obra-nos-vetores`, título `feat: regras de dentro da obra nos vetores e filtro de mês que não some`.
- Uma tarefa por vez: o Forja segue os passos e faz o commit da tarefa; o Lupa revisa (o diff, os testes da tarefa e mutação nas linhas que ela escreve) antes da próxima. Achado menor vai para o fim do PR, num commit só.
- No fim do PR do site: `npm test` e `npm run test:browser` verdes, push, PR em rascunho, a prévia da Vercel conferida contra a produção (o "Ponto de controle" do fim da seção) e o PR pronto para o Giovani; merge só com o pedido dele.
- Os PRs do app seguem a mesma forma, com os portões descritos no começo da seção de cada um, um build no TestFlight depois do merge (só com o OK do Giovani) e o checklist do aparelho.

## Mapa de arquivos do PR 0

- `calc.js`: textos, peças e total da folha do orçamento (Tarefas 1, 2 e 4); ordem e contador dos afazeres (5); meses do filtro (6); contador dos lançamentos e a busca aparada no `filtraGastos` (7); resumo do tópico (8); subtítulo do A pagar (9).
- `dados.js`: o que a folha do orçamento grava (3); adicionar, marcar e apagar afazer (5).
- `app.js`: a cola de cada tarefa, que passa a chamar as regras pelo `OBRA_CALC` e pelo `OBRA_DADOS`.
- `sw.js`: o `CACHE` (10).
- `scripts/vetores-calc.mjs` e `tests/vetores/calc.json` (gerado): os casos de cada regra.
- Núcleo: `Orcamento.swift` (1, 2 e 4), `Formularios.swift` (3), `Afazeres.swift` (novo, 5), `Listas.swift` (6, 7 e 9), `Correcao.swift` (8), com os leitores em `OrcamentoTests.swift`, `FormulariosTests.swift`, `AfazeresTests.swift` (novo), `ListasTests.swift` e `CorrecaoTests.swift`.
- Browser: `tests/browser/orcamento.cjs` (1 a 4 e 8), `tests/browser/dentro-da-obra.cjs` (nova, 5 a 7 e 9, posta no `rodar.cjs`), `tests/browser/mobile.cjs` (9).

## PR 0 (site): as regras de dentro da obra nos vetores e o filtro de mês que não some

Um PR só do site, em dez commits, na forma do PR 0 da etapa 2. Tira do `app.js` o que o app nativo precisa copiar de dentro da obra: os textos e as peças do orçamento, o que a folha do orçamento grava e o total dela (Tarefas 1 a 4), os afazeres (Tarefa 5), os meses do filtro, o contador dos lançamentos e a busca (Tarefas 6 e 7), o resumo da folha do tópico (Tarefa 8) e o subtítulo da folha do A pagar (Tarefa 9). Cada regra entra nos vetores com a cópia e o leitor em Swift no mesmo commit, porque o núcleo barra grupo de vetor sem leitor. O comportamento do site não muda (as suítes de browser continuam verdes), salvo o que o Giovani aprovou em 18/10: o conserto do filtro de mês preso (Tarefa 6) e os três alinhamentos com o app, que são o orçamento que guarda o que a folha não mostra (Tarefa 3), o afazer marcado ou desmarcado no começo da lista (Tarefa 5) e a busca aparada (Tarefa 7). Uma subida só do `CACHE`, no fim (Tarefa 10). Os vetores vão de 81 grupos e 872 casos para 100 grupos e 1003 casos; o `swift test` do núcleo, de 190 para 209 testes.

Para rodar uma suíte de browser sozinha, suba antes o servidor do site (`node tests/browser/servidor.cjs &`, na porta 8123) e pare-o no fim; as suítes desta seção usam dados sintéticos e não precisam dos emuladores.

### Task 1: Textos do orçamento e largura da barra no calc.js

A pílula de cada nível, a frase do tópico, o rodapé do cartão e a linha "gasto / previsto" saem do `app.js` sem mudar o que o site mostra. A frase do "perto" usa o limiar de meio centavo na sobra ("Faltam {X} — {pct}%" acima dele, "Chegou ao previsto — {pct}%" abaixo); a largura da barra para em 100% no "passou". O `semCifrao` sai do `app.js` (só a linha do tópico usava) e vira interno do `calc.js`. A cópia em Swift usa o `moedaCurtaSemZero` da etapa 2: o caso "Faltam R$ 8 mil" separa o curto com e sem o ",0".

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/orcamento.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `orcamentoObra`, `money`, `moneyCurto` do `calc.js`; no núcleo, `ItemOrcamento`, `NivelOrcamento`, `moeda`, `moedaCurtaSemZero` e `numeroJS` (já existem).
- Produces: `OBRA_CALC.ORC_PILULA` (`{ok, perto, passou}` → texto), `larguraBarraOrc(pct)`, `fraseTopicoOrc(t)` (`{texto, alerta}` ou `null`), `rodapeOrc(orc)` (`{usado, rotulo, valor}`) e `linhaTopicoOrc(t)` (`{gasto, previsto}`). Em Swift: `NivelOrcamento.pilula`, `larguraBarraOrc(_:)`, `FraseDoOrcamento` e `fraseTopicoOrc(_:)`, `RodapeDoOrcamento` e `rodapeOrc(_:)`, `LinhaDoTopicoOrc` e `linhaTopicoOrc(_:)`.

- [ ] **Step 1: Escrever os vetores, os leitores em Swift e as guardas do browser**

As duas asserções novas do `orcamento.cjs` (a linha "R$ 98 mil / 90 mil" da Fundação e a barra a 100% no Sobrado, que passou) não mudam de resultado com a tarefa: existem para prender a cola do `app.js` que ela reescreve.

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift
@@ -17,6 +17,14 @@ extension ResumoOrcamento {
         return .objeto(r)
     }
 }
+extension ValorJSON {
+    /// Um item do orcamentoObra do site ({previsto, gasto, pct, sobra, nivel}, com id no modo por tópico).
+    var itemOrcamento: ItemOrcamento {
+        let o = comoObjeto ?? [:]
+        return ItemOrcamento(id: o["id"]?.comoTexto, previsto: o["previsto"]!.numero, gasto: o["gasto"]!.numero, pct: o["pct"]!.numero,
+                             sobra: o["sobra"]!.numero, nivel: NivelOrcamento(rawValue: o["nivel"]!.comoTexto!)!)
+    }
+}
 
 struct OrcamentoTests {
     @Test func previstoVersusReal() {
@@ -24,4 +32,36 @@ struct OrcamentoTests {
             confere(orcamentoObra(c.args[0].obra)?.json ?? .nulo, c.saida, .dinheiro, c.caso)
         }
     }
+
+    @Test func pilulaPorNivel() {
+        let pilulas = [NivelOrcamento.ok, .perto, .passou].map { ($0.rawValue, ValorJSON.texto($0.pilula)) }
+        confere(.objeto(Dictionary(uniqueKeysWithValues: pilulas)), Vetores.casos("calc.ORC_PILULA")[0].saida, .exata, "pílulas")
+    }
+
+    @Test func barraDe0a100() {
+        for c in Vetores.casos("calc.larguraBarraOrc") {
+            confere(.numero(larguraBarraOrc(c.args[0].numero)), c.saida, .exata, c.caso)
+        }
+    }
+
+    @Test func fraseDoTopico() {
+        for c in Vetores.casos("calc.fraseTopicoOrc") {
+            let f = fraseTopicoOrc(c.args[0].itemOrcamento)
+            confere(f.map { .objeto(["texto": .texto($0.texto), "alerta": .booleano($0.alerta)]) } ?? .nulo, c.saida, .exata, c.caso)
+        }
+    }
+
+    @Test func rodapeDoCartao() {
+        for c in Vetores.casos("calc.rodapeOrc") {
+            let r = rodapeOrc(c.args[0].itemOrcamento)
+            confere(.objeto(["usado": .texto(r.usado), "rotulo": .texto(r.rotulo), "valor": .texto(r.valor)]), c.saida, .exata, c.caso)
+        }
+    }
+
+    @Test func linhaDoTopico() {
+        for c in Vetores.casos("calc.linhaTopicoOrc") {
+            let l = linhaTopicoOrc(c.args[0].itemOrcamento)
+            confere(.objeto(["gasto": .texto(l.gasto), "previsto": .texto(l.previsto)]), c.saida, .exata, c.caso)
+        }
+    }
 }
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -423,6 +423,35 @@ orc('empate de razão desempata pelo id', comOrcamento({ modo: 'topicos', topico
 orc('dois tópicos fora com o mesmo gasto desempatam pelo id', comOrcamento({ modo: 'topicos', topicos: { fundacao: 1000 } }, [g('fundacao', 500), g('pintura', 300), g('eletrica', 300)]));
 orc('sem orçamento', O3);
 orc('previsto zero some', comOrcamento({ modo: 'total', total: 0 }, []));
+/* Os textos do cartão e da lista por tópico (app.js orcamentoHtml), sobre itens do próprio orcamentoObra. Valores de
+   mil para cima separam o moneyCurto do money; o meio centavo da sobra fica dos dois lados. */
+const itemOrc = (gasto, previsto) => { const { modo, topicos, fora, foraTotal, ...item } = C.orcamentoObra(comOrcamento({ modo: 'total', total: previsto }, [g('pintura', gasto)])); return item; };
+constante('calc.ORC_PILULA', C.ORC_PILULA);
+const largura = calc('larguraBarraOrc');
+for(const p of [-5, 0, 55, 100, 104, 250]) largura(String(p), p);
+const frase = calc('fraseTopicoOrc');
+frase('passou: R$ 8 mil do previsto', itemOrc(98000, 90000));
+frase('passou na casa do milhão', itemOrc(3.5e6, 1e6));
+frase('passou por menos de mil', itemOrc(1000.75, 1000));
+frase('perto: faltam R$ 19 mil', itemOrc(231000, 250000));
+frase('perto: faltam menos de mil', itemOrc(9000.01, 10000));
+frase('perto: faltam R$ 8 mil, sem o ",0"', itemOrc(92000, 100000));
+frase('sobra de mais de meio centavo: faltam', itemOrc(999.994, 1000));
+frase('sobra de meio centavo: chegou', itemOrc(999.996, 1000));
+frase('exatamente no previsto: chegou', itemOrc(1000, 1000));
+frase('meio centavo acima: chegou, não passou', itemOrc(1000.004, 1000));
+frase('dentro do previsto: sem frase', itemOrc(500, 1000));
+const rodape = calc('rodapeOrc');
+rodape('dentro: sobra', itemOrc(612000, 800000));
+rodape('passou: o valor sem sinal', itemOrc(1048000, 1008000));
+rodape('meio centavo acima ainda sobra', itemOrc(1000.004, 1000));
+rodape('sem gasto', itemOrc(0, 1000));
+const linhaOrc = calc('linhaTopicoOrc');
+linhaOrc('mil e mil', itemOrc(98000, 90000));
+linhaOrc('sem gasto e mil redondo', itemOrc(0, 1000));
+linhaOrc('previsto abaixo de mil perde o R$ com espaço duro', itemOrc(12000.5, 500));
+linhaOrc('milhões', itemOrc(1234567, 2500000));
+linhaOrc('um milhão redondo', itemOrc(8500, 1e6));
 
 /* ---------- versão ---------- */
 const versao = calc('versaoMaior');
```

Em `tests/browser/orcamento.cjs`:

```diff
--- a/tests/browser/orcamento.cjs
+++ b/tests/browser/orcamento.cjs
@@ -64,6 +64,7 @@ async function abrir(browser,{tema='escuro',skin='esmeralda',width=393}={}){
     assert.deepEqual(nomes,['Fundação','Terreno','Estrutura','Elétrica','Acabamento','Fora do orçamento']);
     const item=nome=>page.locator('.orc-topicos .orc-item').filter({has:page.locator('.orc-nome',{hasText:nome})});
     assert.equal((await item('Fundação').locator('.orc-frase').textContent()).trim(),'Passou R$ 8 mil do previsto');
+    assert.equal((await item('Fundação').locator('.orc-val').textContent()).trim(),'R$ 98 mil / 90 mil');
     assert.equal(await item('Fundação').locator('.orc-frase.alerta').count(),1);
     assert.equal(await item('Fundação').locator('.orc-barra.alerta').count(),1);
     assert.equal((await item('Estrutura').locator('.orc-frase').textContent()).trim(),'Faltam R$ 19 mil — 92%');
@@ -82,6 +83,7 @@ async function abrir(browser,{tema='escuro',skin='esmeralda',width=393}={}){
     // Obra com orçamento total estourado
     await page.evaluate(()=>openObra('b'));
     assert.equal((await page.locator('#oOrc .orc-pill').textContent()).trim(),'passou do previsto');
+    assert.equal(await page.locator('#oOrc .orc-barra i').evaluate(i=>i.style.width),'100%','no passou a barra para no previsto');
     assert.match((await page.locator('#oOrc .orc-rodape').textContent()).replace(/\s+/g,' '),/104% usado passou R\$\s40\.000,00/);
     assert.equal(await page.locator('.orc-topicos').count(),0);
 
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | grep -m3 error:
```
Expected: o gerador para com `TypeError: fn is not a function` (o `calc.js` ainda não exporta `larguraBarraOrc`); o núcleo não compila, com `error: value of type 'NivelOrcamento' has no member 'pilula'` e `error: cannot find 'larguraBarraOrc' in scope`.

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift
@@ -73,3 +73,68 @@ public func orcamentoObra(_ obra: Obra) -> ResumoOrcamento? {
     return ResumoOrcamento(modo: "total", geral: itemOrcamento(nil, gasto: totalBruto(obra), previsto: total),
                            topicos: [], fora: [], foraTotal: 0)
 }
+
+/* Os textos do cartão e da lista por tópico, como o calc.js os escreve (moravam no app.js orcamentoHtml). */
+
+public extension NivelOrcamento {
+    /// `ORC_PILULA` do calc.js: a pílula do cartão.
+    var pilula: String {
+        switch self {
+        case .ok: return "dentro do previsto"
+        case .perto: return "perto do limite"
+        case .passou: return "passou do previsto"
+        }
+    }
+}
+
+/// `larguraBarraOrc` do calc.js: a barra em %, de 0 a 100 (no "passou", ela para no previsto).
+public func larguraBarraOrc(_ pct: Double) -> Double { max(0, min(100, pct)) }
+
+public struct FraseDoOrcamento: Equatable, Sendable {
+    public let texto: String
+    /// No "passou": a frase vai na cor do alerta.
+    public let alerta: Bool
+}
+
+/// `fraseTopicoOrc` do calc.js: quanto passou, quanto falta ou que chegou (meio centavo de sobra já é "chegou"); nada
+/// no "dentro do previsto".
+public func fraseTopicoOrc(_ t: ItemOrcamento) -> FraseDoOrcamento? {
+    switch t.nivel {
+    case .passou: return FraseDoOrcamento(texto: "Passou \(moedaCurtaSemZero(-t.sobra)) do previsto", alerta: true)
+    case .perto:
+        let pct = numeroJS(t.pct)
+        let texto = t.sobra > 0.005 ? "Faltam \(moedaCurtaSemZero(t.sobra)) — \(pct)%" : "Chegou ao previsto — \(pct)%"
+        return FraseDoOrcamento(texto: texto, alerta: false)
+    case .ok: return nil
+    }
+}
+
+public struct RodapeDoOrcamento: Equatable, Sendable {
+    /// "{pct}%", antes do "usado".
+    public let usado: String
+    /// "sobra" ou "passou".
+    public let rotulo: String
+    /// O valor sem sinal.
+    public let valor: String
+}
+
+/// `rodapeOrc` do calc.js: "{pct}% usado" e "sobra" ou "passou" com o valor sem sinal.
+public func rodapeOrc(_ r: ItemOrcamento) -> RodapeDoOrcamento {
+    RodapeDoOrcamento(usado: "\(numeroJS(r.pct))%", rotulo: r.nivel == .passou ? "passou" : "sobra", valor: moeda(abs(r.sobra)))
+}
+
+public struct LinhaDoTopicoOrc: Equatable, Sendable {
+    public let gasto: String
+    /// Sem o "R$".
+    public let previsto: String
+}
+
+/// `linhaTopicoOrc` do calc.js: "{gasto} / {previsto}", o previsto sem o "R$" (com o espaço comum ou o duro do `money`).
+public func linhaTopicoOrc(_ t: ItemOrcamento) -> LinhaDoTopicoOrc {
+    var previsto = moedaCurtaSemZero(t.previsto)
+    for prefixo in ["R$ ", "R$\u{00A0}"] where previsto.hasPrefix(prefixo) {
+        previsto.removeFirst(prefixo.count)
+        break
+    }
+    return LinhaDoTopicoOrc(gasto: moedaCurtaSemZero(t.gasto), previsto: previsto)
+}
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -64,7 +64,6 @@ const taxa = () => db.config.taxaMensal;
 /* ---------- helpers ---------- */
 /* Moeda, meses e canon moram no calc.js (puros; o app nativo confere a cópia dele pelos vetores). */
 const { money, moneyShort, moneyCurto, fmtMeses, canon } = OBRA_CALC;
-const semCifrao = s => s.replace(/^R\$\s/, '');
 const MESAB = ['jan','fev','mar','abr','mai','jun','jul','ago','set','out','nov','dez'];
 const todayISO = () => OBRA_CALC.dataLocalISO();
 const fmtData = iso => { const [y,m,d] = iso.split('-'); return escapeHtml(`${d}/${m}/${y.slice(2)}`); };
@@ -271,39 +270,39 @@ function drawComp(arr, hoje){
 
 /* ===== ORÇAMENTO previsto × real =====
    Um número por vez: o card mostra gasto de previsto, barra e sobra; o detalhe
-   fica na lista por tópico. Verde-marca abaixo de 90%, âmbar daí pra cima. */
-const ORC_PILL = { ok:'dentro do previsto', perto:'perto do limite', passou:'passou do previsto' };
+   fica na lista por tópico. Verde-marca abaixo de 90%, âmbar daí pra cima.
+   Os textos e a largura da barra vêm do calc.js (o app nativo usa os mesmos). */
 function barraOrcHtml(pct, nivel, extra){
-  return `<div class="orc-barra${extra ? ' ' + extra : ''}${nivel === 'ok' ? '' : ' alerta'}" aria-hidden="true"><i data-pct="${Math.max(0, Math.min(100, pct))}"></i></div>`;
+  return `<div class="orc-barra${extra ? ' ' + extra : ''}${nivel === 'ok' ? '' : ' alerta'}" aria-hidden="true"><i data-pct="${OBRA_CALC.larguraBarraOrc(pct)}"></i></div>`;
 }
 /* largura via CSSOM: a CSP proíbe atributo style no HTML */
 function pintaBarrasOrc(escopo){
   escopo.querySelectorAll('.orc-barra i[data-pct]').forEach(i => { i.style.width = i.dataset.pct + '%'; });
 }
-function fraseTopicoOrc(t){
-  if(t.nivel === 'passou') return `<div class="orc-frase alerta">Passou ${moneyCurto(-t.sobra)} do previsto</div>`;
-  if(t.nivel === 'perto') return `<div class="orc-frase">${t.sobra > 0.005 ? `Faltam ${moneyCurto(t.sobra)} — ${t.pct}%` : `Chegou ao previsto — ${t.pct}%`}</div>`;
-  return '';
+function fraseTopicoHtml(t){
+  const f = OBRA_CALC.fraseTopicoOrc(t);
+  return f ? `<div class="orc-frase${f.alerta ? ' alerta' : ''}">${f.texto}</div>` : '';
 }
 function orcamentoHtml(o, orc){
-  const passou = orc.nivel === 'passou';
+  const rodape = OBRA_CALC.rodapeOrc(orc);
   const card = `
     <div class="panel orc-card" id="oOrc">
       <div class="orc-topo"><span class="orc-rotulo">Orçamento</span>
-        <span class="orc-pill${orc.nivel === 'ok' ? '' : ' alerta'}">${ORC_PILL[orc.nivel]}</span></div>
+        <span class="orc-pill${orc.nivel === 'ok' ? '' : ' alerta'}">${OBRA_CALC.ORC_PILULA[orc.nivel]}</span></div>
       <div class="orc-num">${money(orc.gasto)} <small>de ${money(orc.previsto)}</small></div>
       ${barraOrcHtml(orc.pct, orc.nivel)}
-      <div class="orc-rodape"><span><b>${orc.pct}%</b> usado</span>
-        <span>${passou ? 'passou' : 'sobra'} <b>${money(Math.abs(orc.sobra))}</b></span></div>
+      <div class="orc-rodape"><span><b>${rodape.usado}</b> usado</span>
+        <span>${rodape.rotulo} <b>${rodape.valor}</b></span></div>
     </div>`;
   let lista = '';
   if(orc.modo === 'topicos'){
     const comGasto = new Set(o.gastos.map(g => g.topico));
     const linhas = orc.topicos.map(t => {
+      const valores = OBRA_CALC.linhaTopicoOrc(t);
       const miolo = `
         <div class="orc-linha"><span class="orc-nome">${escapeHtml(nomeTopico(t.id))}</span>
-          <span class="orc-val"><b>${moneyCurto(t.gasto)}</b> / ${semCifrao(moneyCurto(t.previsto))}</span></div>
-        ${barraOrcHtml(t.pct, t.nivel, 'fina')}${fraseTopicoOrc(t)}`;
+          <span class="orc-val"><b>${valores.gasto}</b> / ${valores.previsto}</span></div>
+        ${barraOrcHtml(t.pct, t.nivel, 'fina')}${fraseTopicoHtml(t)}`;
       // tópico com gasto vira botão de verdade (semântica de lista/botão corretas pra leitor de tela)
       return comGasto.has(t.id)
         ? `<li class="orc-item"><button type="button" class="orc-item-conteudo" data-top="${escapeHtml(t.id)}">${miolo}</button></li>`
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -456,13 +456,32 @@
     const r = Math.round(m);
     return r + (r === 1 ? ' mês' : ' meses');
   }
+  /* ---- textos do orçamento (app.js orcamentoHtml): moravam no app.js; o app nativo confere a cópia pelos vetores ---- */
+  const ORC_PILULA = Object.freeze({ ok:'dentro do previsto', perto:'perto do limite', passou:'passou do previsto' });
+  /* Largura da barra em %: no "passou" ela para no previsto. */
+  const larguraBarraOrc = pct => Math.max(0, Math.min(100, pct));
+  /* Frase do tópico: quanto passou, quanto falta ou que chegou (meio centavo de sobra já é "chegou"); nada no "dentro". */
+  function fraseTopicoOrc(t){
+    if(t.nivel === 'passou') return { texto: `Passou ${moneyCurto(-t.sobra)} do previsto`, alerta: true };
+    if(t.nivel === 'perto') return { texto: t.sobra > 0.005 ? `Faltam ${moneyCurto(t.sobra)} — ${t.pct}%` : `Chegou ao previsto — ${t.pct}%`, alerta: false };
+    return null;
+  }
+  /* Rodapé do cartão: "{pct}% usado" e "sobra" ou "passou" com o valor sem sinal. */
+  function rodapeOrc(orc){
+    return { usado: `${orc.pct}%`, rotulo: orc.nivel === 'passou' ? 'passou' : 'sobra', valor: money(Math.abs(orc.sobra)) };
+  }
+  /* Linha do tópico: "{gasto} / {previsto}", o previsto sem o "R$". */
+  const semCifrao = s => s.replace(/^R\$\s/, '');
+  function linhaTopicoOrc(t){
+    return { gasto: moneyCurto(t.gasto), previsto: semCifrao(moneyCurto(t.previsto)) };
+  }
   /* stringify com chaves ordenadas — compara estados sem depender da ordem do Firestore */
   function canon(x){
     return JSON.stringify(x, (k, v) => v && typeof v === 'object' && !Array.isArray(v)
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -2
node tests/browser/orcamento.cjs && node tests/browser/xss.cjs && node tests/browser/mobile.cjs
```
Expected: `ℹ pass 385` e `ℹ fail 0`; `✔ Test run with 195 tests in 34 suites passed` (5 novos em `OrcamentoTests`); as três suítes de browser terminam sem erro.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift \
  app.js \
  calc.js \
  scripts/vetores-calc.mjs \
  tests/browser/orcamento.cjs \
  tests/vetores/calc.json
git commit -m "feat: textos do orçamento e largura da barra no calc.js" -m "A pílula de cada nível, a frase do tópico (quanto passou, quanto falta, com o limiar de meio centavo na sobra, ou que chegou), o rodapé do cartão e a linha \"gasto / previsto\" saem do app.js para o calc.js sem mudar o que o site mostra, e entram nos vetores junto com a largura da barra, que para em 100% no passou. O app nativo copia os textos e os confere pelos mesmos casos."
```

### Task 2: Peças do orçamento na obra pelo calc.js

Quando a obra mostra o cartão do orçamento, a lista por tópico e o "Definir orçamento", e quais tópicos previstos abrem a folha do tópico, vira uma regra do `calc.js`, sem mudar o site: o cartão só com orçamento válido, o "Por tópico" só no modo por tópico, o "Definir" só sem orçamento e fora da vendida, e o tópico previsto tocável só com algum gasto (mesmo de valor zero), na ordem da lista. O `orcamentoHtml` do `app.js` ganha as peças como terceiro argumento.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/orcamento.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `orcamentoObra`.
- Produces: `OBRA_CALC.pecasOrcamento(obra)` → `{cartao, porTopico, definir, tocaveis}`. Em Swift: `PecasDoOrcamento` e `pecasOrcamento(_:)`.

- [ ] **Step 1: Escrever os vetores, os leitores em Swift e as guardas do browser**

As duas guardas novas do `orcamento.cjs` (a vendida sem orçamento não oferece "Definir"; o tópico previsto sem gasto não tem toque) passam antes também: prendem a cola.

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift
@@ -64,4 +64,12 @@ struct OrcamentoTests {
             confere(.objeto(["gasto": .texto(l.gasto), "previsto": .texto(l.previsto)]), c.saida, .exata, c.caso)
         }
     }
+
+    @Test func pecasQueAObraMostra() {
+        for c in Vetores.casos("calc.pecasOrcamento") {
+            let p = pecasOrcamento(c.args[0].obra)
+            confere(.objeto(["cartao": .booleano(p.cartao), "porTopico": .booleano(p.porTopico), "definir": .booleano(p.definir),
+                             "tocaveis": .lista(p.tocaveis.map(ValorJSON.texto))]), c.saida, .exata, c.caso)
+        }
+    }
 }
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -452,6 +452,15 @@ linhaOrc('sem gasto e mil redondo', itemOrc(0, 1000));
 linhaOrc('previsto abaixo de mil perde o R$ com espaço duro', itemOrc(12000.5, 500));
 linhaOrc('milhões', itemOrc(1234567, 2500000));
 linhaOrc('um milhão redondo', itemOrc(8500, 1e6));
+/* Quais peças do orçamento a obra mostra (app.js renderObra e orcamentoHtml). */
+const pecas = calc('pecasOrcamento');
+pecas('sem orçamento, em construção', O3);
+pecas('sem orçamento, pronta', { ...O4, orcamento: undefined });
+pecas('sem orçamento, vendida: sem o Definir', { ...O2, orcamento: undefined });
+pecas('total na vendida', O2);
+pecas('por tópico: só os previstos com gasto abrem, na ordem da lista', O1);
+pecas('gasto de valor zero ainda abre', comOrcamento({ modo: 'topicos', topicos: { pintura: 1000, eletrica: 500 } }, [g('pintura', 0)]));
+pecas('orçamento inválido conta como sem', comOrcamento({ modo: 'total', total: 0 }, [g('pintura', 10)]));
 
 /* ---------- versão ---------- */
 const versao = calc('versaoMaior');
```

Em `tests/browser/orcamento.cjs`:

```diff
--- a/tests/browser/orcamento.cjs
+++ b/tests/browser/orcamento.cjs
@@ -91,6 +91,15 @@ async function abrir(browser,{tema='escuro',skin='esmeralda',width=393}={}){
     await page.evaluate(()=>openObra('c'));
     assert.equal(await page.locator('#oOrc').count(),0);
     assert.equal(await page.locator('#oOrcDefinir').count(),1);
+    // Vendida sem orçamento não oferece "Definir orçamento"
+    await page.evaluate(()=>{const c=obraById('c');c.fase='vendida';c.venda={valor:1000000,data:'2026-03-01'};openObra('c');});
+    assert.equal(await page.locator('#oOrcDefinir').count(),0);
+    // Por tópico: só o previsto com gasto abre a folha do tópico; o sem gasto fica na lista, sem toque
+    await page.evaluate(()=>{const c=obraById('c');c.fase='construcao';delete c.venda;c.orcamento={modo:'topicos',topicos:{terreno:900000,pintura:5000}};openObra('c');});
+    assert.equal(await page.locator('.orc-item-conteudo[data-top="terreno"]').count(),1);
+    assert.equal(await page.locator('.orc-item-conteudo[data-top="pintura"]').count(),0);
+    assert.equal(await page.locator('.orc-topicos .orc-item',{hasText:'Pintura'}).count(),1);
+    await page.evaluate(()=>{delete obraById('c').orcamento;openObra('c');});
 
     // Folha: definir só o total numa obra sem orçamento
     await page.locator('#oOrcDefinir').click();
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | grep -m3 error:
```
Expected: `TypeError: fn is not a function`; `error: cannot find 'pecasOrcamento' in scope`.

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift
@@ -138,3 +138,22 @@ public func linhaTopicoOrc(_ t: ItemOrcamento) -> LinhaDoTopicoOrc {
     }
     return LinhaDoTopicoOrc(gasto: moedaCurtaSemZero(t.gasto), previsto: previsto)
 }
+
+public struct PecasDoOrcamento: Equatable, Sendable {
+    /// O cartão (e o lápis que edita), com orçamento válido.
+    public let cartao: Bool
+    /// A lista "Por tópico", só no modo por tópico.
+    public let porTopico: Bool
+    /// "Definir orçamento", sem orçamento e fora da vendida.
+    public let definir: Bool
+    /// Os tópicos previstos que abrem o detalhe (os que têm gasto, até de valor zero), na ordem da lista.
+    public let tocaveis: [String]
+}
+
+/// `pecasOrcamento` do calc.js: quais peças do orçamento a obra mostra.
+public func pecasOrcamento(_ obra: Obra) -> PecasDoOrcamento {
+    let orc = orcamentoObra(obra)
+    let comGasto = Set(obra.gastos.map(\.topico))
+    return PecasDoOrcamento(cartao: orc != nil, porTopico: orc?.modo == "topicos", definir: orc == nil && obra.fase != .vendida,
+                            tocaveis: (orc?.topicos ?? []).compactMap(\.id).filter { comGasto.contains($0) })
+}
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -283,7 +283,7 @@ function fraseTopicoHtml(t){
   const f = OBRA_CALC.fraseTopicoOrc(t);
   return f ? `<div class="orc-frase${f.alerta ? ' alerta' : ''}">${f.texto}</div>` : '';
 }
-function orcamentoHtml(o, orc){
+function orcamentoHtml(o, orc, pecas){
   const rodape = OBRA_CALC.rodapeOrc(orc);
   const card = `
     <div class="panel orc-card" id="oOrc">
@@ -295,8 +295,7 @@ function orcamentoHtml(o, orc){
         <span>${rodape.rotulo} <b>${rodape.valor}</b></span></div>
     </div>`;
   let lista = '';
-  if(orc.modo === 'topicos'){
-    const comGasto = new Set(o.gastos.map(g => g.topico));
+  if(pecas.porTopico){
     const linhas = orc.topicos.map(t => {
       const valores = OBRA_CALC.linhaTopicoOrc(t);
       const miolo = `
@@ -304,7 +303,7 @@ function orcamentoHtml(o, orc){
           <span class="orc-val"><b>${valores.gasto}</b> / ${valores.previsto}</span></div>
         ${barraOrcHtml(t.pct, t.nivel, 'fina')}${fraseTopicoHtml(t)}`;
       // tópico com gasto vira botão de verdade (semântica de lista/botão corretas pra leitor de tela)
-      return comGasto.has(t.id)
+      return pecas.tocaveis.includes(t.id)
         ? `<li class="orc-item"><button type="button" class="orc-item-conteudo" data-top="${escapeHtml(t.id)}">${miolo}</button></li>`
         : `<li class="orc-item"><div class="orc-item-conteudo">${miolo}</div></li>`;
     }).join('');
@@ -328,6 +327,7 @@ function renderObra(){
   const corr  = OBRA_CALC.totalCorrigido(o, taxa(), hoje);
   const lucro = OBRA_CALC.lucroVenda(o, taxa());
   const orc = OBRA_CALC.orcamentoObra(o);
+  const pecasOrc = OBRA_CALC.pecasOrcamento(o);
 
   let head = `
     <div class="panel obra-head">
@@ -394,7 +394,7 @@ function renderObra(){
     <button class="btn primary" id="oVender">${ICON('acordo')} Registrar venda</button>
     <button class="btn ghost" id="oVoltarConstr">${ICON('voltar')} Voltar pra construção</button>`;
   if(o.fase==='vendida') acoes += `<button class="btn ghost" id="oDesfazer">${ICON('voltar')} Desfazer venda</button>`;
-  if(!orc && o.fase !== 'vendida') acoes += `<button class="btn ghost" id="oOrcDefinir">${ICON('alvo')} Definir orçamento</button>`;
+  if(pecasOrc.definir) acoes += `<button class="btn ghost" id="oOrcDefinir">${ICON('alvo')} Definir orçamento</button>`;
   if(o.gastos.length) acoes += `
     <button class="btn ghost" id="oGraf">${ICON('calculadora')} Ver gráficos</button>
     <button class="btn ghost" id="oRel">${ICON('documento')} Relatório</button>`;
@@ -441,7 +441,7 @@ function renderObra(){
       <ul class="list" id="oGastos"></ul>
     </div>`;
 
-  $('#obraBody').innerHTML = head + (orc ? orcamentoHtml(o, orc) : '') + resumo + acoes + afazeres + graficos + lanc;
+  $('#obraBody').innerHTML = head + (pecasOrc.cartao ? orcamentoHtml(o, orc, pecasOrc) : '') + resumo + acoes + afazeres + graficos + lanc;
   fitNums($('#obraBody'));
   pintaBarrasOrc($('#obraBody'));
 
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -475,13 +475,22 @@
   function linhaTopicoOrc(t){
     return { gasto: moneyCurto(t.gasto), previsto: semCifrao(moneyCurto(t.previsto)) };
   }
+  /* Peças do orçamento na obra: o cartão (e o "Editar") com orçamento válido; a lista "Por tópico" só no modo por tópico;
+     "Definir orçamento" sem orçamento e fora da vendida; e os tópicos previstos que abrem a folha do tópico, os que têm gasto
+     (qualquer gasto, até de valor zero), na ordem da lista. */
+  function pecasOrcamento(obra){
+    const orc = orcamentoObra(obra);
+    const comGasto = new Set((Array.isArray(obra.gastos) ? obra.gastos : []).map(g => g.topico));
+    return { cartao: !!orc, porTopico: !!orc && orc.modo === 'topicos', definir: !orc && obra.fase !== 'vendida',
+      tocaveis: orc ? orc.topicos.filter(t => comGasto.has(t.id)).map(t => t.id) : [] };
+  }
   /* stringify com chaves ordenadas — compara estados sem depender da ordem do Firestore */
   function canon(x){
     return JSON.stringify(x, (k, v) => v && typeof v === 'object' && !Array.isArray(v)
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, pecasOrcamento, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -2
node tests/browser/orcamento.cjs && node tests/browser/xss.cjs
```
Expected: `ℹ pass 385` e `ℹ fail 0`; `✔ Test run with 196 tests in 34 suites passed`; as duas suítes terminam sem erro.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift \
  app.js \
  calc.js \
  scripts/vetores-calc.mjs \
  tests/browser/orcamento.cjs \
  tests/vetores/calc.json
git commit -m "feat: peças do orçamento na obra pelo calc.js" -m "Quando a obra mostra o cartão do orçamento, a lista por tópico e o \"Definir orçamento\", e quais tópicos previstos abrem a folha do tópico, passa a ser uma regra do calc.js com vetores, sem mudar o site. O app nativo decide as mesmas peças pela cópia em Swift."
```

### Task 3: O que a folha do orçamento grava, no dados.js, guardando o que ela não mostra

O "Salvar" da folha do orçamento sai do `app.js` para o `dados.js`: só o modo ativo; no total, `total > 0` grava `{modo: 'total', total}`; por tópico, só os valores maiores que zero; nada a gravar tira o orçamento (a chave some). Com o alinhamento aprovado (achado 7), o site deixa de perder o que a folha não mostra: os campos desconhecidos dentro de `orcamento` e o previsto de um tópico sem linha na folha ficam, e vale o orçamento do momento do "Salvar", não o da abertura da folha. A gravação não corta em 100 tópicos (o `MAX_TOPICOS_ORC` da leitura): o corte da leitura escolhe pela ordem de inserção, que o Firestore do app não guarda, e só se passa de 100 com mais de 29 tópicos fora da folha, que Ajustes não deixa existir (tópico com previsto não se apaga); o comentário do `dados.js` registra isso.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift`
- Modify: `app.js`
- Modify: `dados.js`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/orcamento.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `objeto` (interno do `dados.js`); `parseNum` na cola.
- Produces: `OBRA_DADOS.orcamentoGravado(antigo, modo, total, valores)` → objeto ou `null`. Em Swift: `orcamentoGravado(_:modo:total:valores:) -> ValorJSON?`, em `Formularios.swift`, com as outras regras do `dados.js`. O `aplica` do `formOrcamento` passa a receber uma função do orçamento do momento: o "Salvar" relê a obra no toque e chama `orcamentoGravado` com todas as linhas da folha; o "Tirar" passa `() => null`.

- [ ] **Step 1: Escrever os vetores, os leitores em Swift e o teste do browser**

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift
@@ -117,6 +117,14 @@ struct FormulariosDaObraTests {
             confere(r?.json ?? .nulo, c.saida, .exata, c.caso)
         }
     }
+
+    @Test func orcamentoGravadoComoOSiteGrava() {
+        for c in Vetores.casos("dados.orcamentoGravado") {
+            let valores = (c.args[3].comoObjeto ?? [:]).mapValues(\.numero)
+            let r = orcamentoGravado(c.arg(0), modo: c.args[1].comoTexto!, total: c.args[2].numero, valores: valores)
+            confere(r ?? .nulo, c.saida, .exata, c.caso)
+        }
+    }
 }
 
 struct ResumoEAssinaturaTests {
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -648,6 +648,29 @@ venda('depois de hoje', 1500000, '2026-10-07');
 venda('data vazia', 1500000, '');
 venda('data inválida', 1500000, '2026-02-30');
 
+/* O "Salvar" da folha do orçamento (app.js formOrcamento): só o modo ativo, e o que a folha não mostra fica. FOLHA são as linhas da
+   folha, vazias; o antigo é o orçamento da obra no momento do Salvar. */
+const gravado = (nome, ...args) => caso('dados.orcamentoGravado', nome, args, D.orcamentoGravado);
+const FOLHA = { terreno: 0, fundacao: 0, estrutura: 0, pintura: 0, c_portao: 0 };
+gravado('só o total, sem orçamento antes', undefined, 'total', 500000, FOLHA);
+gravado('total zero tira', { modo: 'total', total: 1000 }, 'total', 0, FOLHA);
+gravado('total negativo tira', { modo: 'total', total: 1000 }, 'total', -5, FOLHA);
+gravado('total ilegível tira', { modo: 'total', total: 1000 }, 'total', NaN, FOLHA);
+gravado('total guarda o campo desconhecido e larga os tópicos', { modo: 'topicos', topicos: { fundacao: 90000, c_apagado: 1000 }, nota: 'do site', versao: 2 },
+  'total', 1250000.5, FOLHA);
+gravado('total ignora os valores da folha', undefined, 'total', 1000, { ...FOLHA, terreno: 5 });
+gravado('por tópico: só os valores acima de zero', undefined, 'topicos', 0,
+  { ...FOLHA, terreno: 180000, fundacao: 100000, estrutura: -3, c_portao: 5000.5, pintura: NaN });
+gravado('por tópico ignora o total', undefined, 'topicos', 999, { ...FOLHA, terreno: 5 });
+gravado('por tópico tudo vazio tira, mesmo com tópico fora da folha', { modo: 'topicos', topicos: { c_apagado: 1000 } }, 'topicos', 0, FOLHA);
+gravado('por tópico guarda o tópico fora da folha e o campo desconhecido', { modo: 'topicos', topicos: { fundacao: 90000, c_apagado: 1000 }, nota: 'do site' },
+  'topicos', 0, { ...FOLHA, fundacao: 95000 });
+gravado('tópico da folha zerado não volta do antigo', { modo: 'topicos', topicos: { fundacao: 90000, estrutura: 250000 } }, 'topicos', 0, { ...FOLHA, estrutura: 250000 });
+gravado('do total para por tópico: o total sai, o desconhecido fica', { modo: 'total', total: 700000, nota: 'x' }, 'topicos', 0, { ...FOLHA, terreno: 1000 });
+gravado('antigo que não é objeto conta como sem orçamento', 'lixo', 'topicos', 0, { ...FOLHA, pintura: 3000 });
+gravado('antigo lista conta como sem orçamento', [1, 2], 'total', 10, FOLHA);
+gravado('tópicos do antigo que não são objeto não entram', { modo: 'topicos', topicos: [5] }, 'topicos', 0, { ...FOLHA, pintura: 3000 });
+
 /* ---------- push.js e id ---------- */
 for(const t of ['', 'a', 'abc', 'fcm-token:APA91bHun4MxP5egoKMwt2KZFBaFUH-1RYqx', 'https://fcm.googleapis.com/fcm/send/eXyZ', 'ç😀', 'x'.repeat(300)])
   caso('push.hashEndpoint', JSON.stringify(t.length > 40 ? t.slice(0, 40) + '…' : t), [t], P.hashEndpoint);
```

Em `tests/browser/orcamento.cjs`:

```diff
--- a/tests/browser/orcamento.cjs
+++ b/tests/browser/orcamento.cjs
@@ -153,6 +153,22 @@ async function abrir(browser,{tema='escuro',skin='esmeralda',width=393}={}){
     await page.waitForFunction(()=>!('orcamento' in obraById('b')));
     assert.equal(await page.locator('#oOrc').count(),0);
 
+    // O que a folha não mostra fica (achado 7): o campo desconhecido e o previsto de tópico sem linha na folha
+    await page.evaluate(()=>{obraById('a').orcamento={modo:'topicos',topicos:{fundacao:90000,c_apagado:1000},nota:'do site'};openObra('a');});
+    await page.locator('#oOrcEditar').click();
+    await page.locator('#orcTopWrap input[data-top="fundacao"]').fill('95000');
+    // com a folha aberta, outro aparelho troca o documento: vale o orçamento do momento do Salvar
+    await page.evaluate(()=>{db=normaliza(JSON.parse(JSON.stringify(db)));obraById('a').orcamento.nota='do outro aparelho';});
+    await page.locator('#cSave').click();
+    assert.deepEqual(await page.evaluate(()=>obraById('a').orcamento),
+      {modo:'topicos',topicos:{fundacao:95000,c_apagado:1000},nota:'do outro aparelho'});
+    // no "Só o total" o desconhecido fica e os tópicos saem
+    await page.locator('#oOrcEditar').click();
+    await page.locator('#sheet .seg button',{hasText:'Só o total'}).click();
+    await page.locator('#orcTotal').fill('500000');
+    await page.locator('#cSave').click();
+    assert.deepEqual(await page.evaluate(()=>obraById('a').orcamento),{nota:'do outro aparelho',modo:'total',total:500000});
+
     // Nova obra com orçamento total
     await page.evaluate(()=>formNovaObra());
     await page.locator('#fNome').fill('Casa Nova');
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | grep -m3 error:
node tests/browser/orcamento.cjs
```
Expected: `TypeError: fn is not a function` (o `dados.js` ainda não exporta `orcamentoGravado`); `error: cannot find 'orcamentoGravado' in scope`; o browser para com `AssertionError [ERR_ASSERTION]: Expected values to be strictly deep-equal:` e, no diff, `-   nota: 'do outro aparelho',` e `-     c_apagado: 1000,` (o site de hoje perde os dois no "Salvar").

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift
@@ -161,6 +161,28 @@ public func obraEditada(_ obra: [String: ValorJSON], _ campos: CamposDaObra) ->
     return o
 }
 
+/// `orcamentoGravado` do dados.js: o "Salvar" da folha do orçamento, só o modo ativo. `antigo` é o orçamento da obra no momento do
+/// Salvar; `valores`, o valor lido de cada linha da folha (todos os tópicos da lista). No total, só maior que zero; por tópico, só os
+/// valores maiores que zero. O que a folha não mostra fica: os campos desconhecidos do orçamento e, por tópico, o previsto de tópico
+/// sem linha na folha. nil: nada a gravar, e a chave sai da obra.
+public func orcamentoGravado(_ antigo: ValorJSON?, modo: String, total: Double, valores: [String: Double]) -> ValorJSON? {
+    var orcamento = antigo?.comoObjeto ?? [:]
+    let antes = orcamento["topicos"]?.comoObjeto ?? [:]
+    for chave in ["modo", "total", "topicos"] { orcamento[chave] = nil }
+    if modo == "total" {
+        guard total > 0 else { return nil }
+        orcamento["modo"] = .texto("total")
+        orcamento["total"] = .numero(total)
+        return .objeto(orcamento)
+    }
+    var topicos = valores.filter { $0.value > 0 }.mapValues(ValorJSON.numero)
+    if topicos.isEmpty { return nil }
+    for (id, valor) in antes where valores[id] == nil { topicos[id] = valor }
+    orcamento["modo"] = .texto("topicos")
+    orcamento["topicos"] = .objeto(topicos)
+    return .objeto(orcamento)
+}
+
 /// `conferirVenda` do dados.js: valor maior que zero e data entre o início da obra e hoje.
 public func conferirVenda(valor: Double, data: String, dataInicio: String, hoje: String) -> ErroDeFormulario? {
     if valor <= 0 { return ErroDeFormulario(campo: "valor") }
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -1689,7 +1689,8 @@ backdrop.onclick = e=>{ if(e.target===backdrop) closeSheet(); };
 document.addEventListener('keydown', e=>{ if(e.key==='Escape' && backdrop.classList.contains('show')) closeSheet(); });
 
 /* Folha do orçamento: só o total, ou valor por tópico (fixos e próprios).
-   Grava só o modo ativo; salvar tudo vazio tira o orçamento da obra. */
+   O que o Salvar grava vem do dados.js (orcamentoGravado): só o modo ativo, o que a folha
+   não mostra fica, e salvar tudo vazio tira o orçamento da obra. */
 function formOrcamento(obraId){
   const o = obraById(obraId);
   if(!o) return;
@@ -1743,25 +1744,22 @@ function formOrcamento(obraId){
   entradas.forEach(i => { maskMoney(i); i.addEventListener('input', pintaSoma); });
   aplicaModo(modo);
   pintaSoma();
-  const aplica = novo => {
+  // relê a obra no toque: um snapshot com a folha aberta troca os objetos do db
+  const aplica = gravar => {
     const oo = obraById(obraId);
-    if(oo){ if(novo) oo.orcamento = novo; else delete oo.orcamento; save(); }
+    if(oo){ const novo = gravar(oo.orcamento); if(novo) oo.orcamento = novo; else delete oo.orcamento; save(); }
     closeSheet(); renderAll();
   };
   $('#cCancel').onclick = closeSheet;
   $('#cSave').onclick = () => {
-    if(modo === 'total'){
-      const total = parseNum($('#orcTotal').value);
-      aplica(total > 0 ? { modo:'total', total } : null);
-      return;
-    }
-    const tops = {};
-    entradas.forEach(i => { const v = parseNum(i.value); if(v > 0) tops[i.dataset.top] = v; });
-    aplica(Object.keys(tops).length ? { modo:'topicos', topicos:tops } : null);
+    const total = parseNum($('#orcTotal').value);
+    const valores = {};
+    entradas.forEach(i => { valores[i.dataset.top] = parseNum(i.value); });
+    aplica(antigo => OBRA_DADOS.orcamentoGravado(antigo, modo, total, valores));
   };
   const tirar = $('#orcTirar');
   if(tirar) tirar.onclick = async () => {
-    if(await OBRA_CONFIRM.perguntar('Tirar o orçamento desta obra? Os gastos continuam como estão.', { confirmar:'Tirar orçamento' })) aplica(null);
+    if(await OBRA_CONFIRM.perguntar('Tirar o orçamento desta obra? Os gastos continuam como estão.', { confirmar:'Tirar orçamento' })) aplica(() => null);
   };
 }
 
```

Em `dados.js`:

```diff
--- a/dados.js
+++ b/dados.js
@@ -144,7 +144,24 @@
       return {erro:'data', mensagem:'Data da venda precisa ficar entre o início da obra e hoje'};
     return null;
   }
-  const api={normaliza,LIMITES,conferirGasto,gastosLancados,gastoEditado,LIMITE_OBRAS,avisoLimiteDeObras,conferirObra,obraNova,obraEditada,conferirVenda};
+  /* ---- o que a folha do orçamento grava (app.js formOrcamento) ----
+     "Salvar", só o modo ativo. antigo: o orçamento da obra no momento do Salvar (não o da abertura da folha); modo: 'total' ou
+     'topicos'; total: o total lido pelo parseNum; valores: {idDoTópico: valor lido} de todas as linhas da folha. No total, só
+     maior que zero; por tópico, só os valores maiores que zero. O que a folha não mostra fica: os campos desconhecidos do orçamento
+     e, por tópico, o previsto de tópico sem linha na folha (tópico próprio apagado). Nada a gravar: null, e a chave sai da obra.
+     Não corta em 100 tópicos como a leitura: o corte escolhe pela ordem de inserção, que o Firestore do app não guarda. */
+  function orcamentoGravado(antigo, modo, total, valores){
+    const resto = {};
+    if(objeto(antigo)) for(const [k, v] of Object.entries(antigo)) if(!['modo', 'total', 'topicos'].includes(k)) resto[k] = v;
+    if(modo === 'total') return total > 0 ? {...resto, modo:'total', total} : null;
+    const topicos = {};
+    for(const [id, v] of Object.entries(valores)) if(v > 0) topicos[id] = v;
+    if(!Object.keys(topicos).length) return null;
+    const antes = objeto(antigo) && objeto(antigo.topicos) ? antigo.topicos : {};
+    for(const [id, v] of Object.entries(antes)) if(!Object.prototype.hasOwnProperty.call(valores, id)) topicos[id] = v;
+    return {...resto, modo:'topicos', topicos};
+  }
+  const api={normaliza,LIMITES,conferirGasto,gastosLancados,gastoEditado,LIMITE_OBRAS,avisoLimiteDeObras,conferirObra,obraNova,obraEditada,conferirVenda,orcamentoGravado};
   if(typeof module !== 'undefined' && module.exports) module.exports=api;
   else root.OBRA_DADOS=api;
 })(typeof window !== 'undefined' ? window : globalThis);
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -2
node tests/browser/orcamento.cjs && node tests/browser/xss.cjs
```
Expected: `ℹ pass 385` e `ℹ fail 0`; `✔ Test run with 197 tests in 34 suites passed`; as duas suítes terminam sem erro.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift \
  app.js \
  dados.js \
  scripts/vetores-calc.mjs \
  tests/browser/orcamento.cjs \
  tests/vetores/calc.json
git commit -m "feat: o que a folha do orçamento grava, no dados.js, guardando o que ela não mostra" -m "O \"Salvar\" da folha do orçamento sai do app.js para o dados.js e entra nos vetores: só o modo ativo, o total maior que zero ou os valores por tópico maiores que zero, e nada a gravar tira o orçamento. O site deixa de perder o que a folha não mostra: os campos desconhecidos dentro do orçamento e o previsto de um tópico que não tem linha na folha ficam, e vale o orçamento do momento do Salvar, não o da abertura da folha. O app nativo grava o mesmo pela cópia em Swift."
```

### Task 4: Total ao vivo e total preenchido da folha do orçamento no calc.js

A soma ao vivo dos tópicos, que conta só o que é positivo em cada linha (`Math.max(0, …)`), e o total que a folha preenche com essa soma ao trocar para "Só o total" com o campo vazio saem do `app.js`, sem mudar o site. Os valores chegam na ordem da folha, já lidos pelo `parseNum` (nunca `NaN`; o `max` do Swift e o `Math.max` só divergem no `NaN`), e o campo vazio é o texto `""`. O `aplicaModo` passa a atribuir o total preenchido sempre que entra no total: o campo com texto volta igual, sem evento.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/orcamento.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `numParaCampo` (no `calc.js` e no núcleo).
- Produces: `OBRA_CALC.somaTopicosOrc(numeros)` e `totalPreenchidoOrc(campo, numeros)`. Em Swift: `somaTopicosOrc(_:)` e `totalPreenchidoOrc(_:_:)`.

- [ ] **Step 1: Escrever os vetores, os leitores em Swift e as guardas do browser**

Os dois passos novos do `orcamento.cjs` prendem a cola: o total já preenchido do Sobrado não muda ao voltar para "Só o total", e a troca vem depois de mudar a Fundação para 200.000, esperando "815.000,50".

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift
@@ -65,6 +65,18 @@ struct OrcamentoTests {
         }
     }
 
+    @Test func totalAoVivoDaFolha() {
+        for c in Vetores.casos("calc.somaTopicosOrc") {
+            confere(.numero(somaTopicosOrc((c.args[0].comoLista ?? []).map(\.numero))), c.saida, .exata, c.caso)
+        }
+    }
+
+    @Test func totalPreenchidoAoTrocarDeModo() {
+        for c in Vetores.casos("calc.totalPreenchidoOrc") {
+            confere(.texto(totalPreenchidoOrc(c.args[0].comoTexto!, (c.args[1].comoLista ?? []).map(\.numero))), c.saida, .exata, c.caso)
+        }
+    }
+
     @Test func pecasQueAObraMostra() {
         for c in Vetores.casos("calc.pecasOrcamento") {
             let p = pecasOrcamento(c.args[0].obra)
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -461,6 +461,20 @@ pecas('total na vendida', O2);
 pecas('por tópico: só os previstos com gasto abrem, na ordem da lista', O1);
 pecas('gasto de valor zero ainda abre', comOrcamento({ modo: 'topicos', topicos: { pintura: 1000, eletrica: 500 } }, [g('pintura', 0)]));
 pecas('orçamento inválido conta como sem', comOrcamento({ modo: 'total', total: 0 }, [g('pintura', 10)]));
+/* A folha do orçamento: o total ao vivo e o total preenchido ao trocar para "Só o total" (valores lidos pelo parseNum, nunca NaN). */
+const soma = calc('somaTopicosOrc');
+soma('folha vazia', []);
+soma('soma na ordem da folha', [180000, 100000, 250000, 180000, 5000.5]);
+soma('negativo e zero não contam', [-3, 100, 0]);
+soma('negativo grande não desconta', [1e6, -1e6]);
+soma('centavos em ponto flutuante', [0.1, 0.2]);
+const preenchido = calc('totalPreenchidoOrc');
+preenchido('campo vazio ganha a soma', '', [90000, 0, 5000.5]);
+preenchido('campo vazio e folha vazia', '', []);
+preenchido('soma só de negativos não preenche', '', [-5]);
+preenchido('soma abaixo de meio centavo ainda preenche', '', [0.004]);
+preenchido('campo com valor fica', '1.008.000,00', [5000]);
+preenchido('campo com zero digitado fica', '0', [5000]);
 
 /* ---------- versão ---------- */
 const versao = calc('versaoMaior');
```

Em `tests/browser/orcamento.cjs`:

```diff
--- a/tests/browser/orcamento.cjs
+++ b/tests/browser/orcamento.cjs
@@ -136,15 +136,25 @@ async function abrir(browser,{tema='escuro',skin='esmeralda',width=393}={}){
 
     // Trocar pra "Só o total" e salvar vazio tira o orçamento
     await page.locator('#oOrcEditar').click();
+    await campo('fundacao').fill('200000');
     await page.locator('#sheet .seg button',{hasText:'Só o total'}).click();
     assert.equal(await page.locator('#orcTotal').isVisible(),true);
-    // trocar de modo não pode apagar o previsto por tópico sem o construtor ver o número
-    assert.equal(await page.locator('#orcTotal').inputValue(),'715.000,50');
+    // trocar de modo não pode apagar o previsto por tópico sem o construtor ver o número: a soma da hora da troca
+    assert.equal(await page.locator('#orcTotal').inputValue(),'815.000,50');
     await page.locator('#orcTotal').fill('');
     await page.locator('#cSave').click();
     assert.equal(await page.evaluate(()=>'orcamento' in obraById('a')),false);
     assert.equal(await page.locator('#oOrcDefinir').count(),1);
 
+    // Total já preenchido não muda ao voltar para "Só o total"
+    await page.evaluate(()=>openObra('b'));
+    await page.locator('#oOrcEditar').click();
+    await page.locator('#sheet .seg button',{hasText:'Por tópico'}).click();
+    await page.locator('#orcTopWrap input[data-top="fundacao"]').fill('5000');
+    await page.locator('#sheet .seg button',{hasText:'Só o total'}).click();
+    assert.equal(await page.locator('#orcTotal').inputValue(),'1.008.000,00');
+    await page.evaluate(()=>closeSheet());
+
     // Tirar orçamento pede confirmação
     await page.evaluate(()=>openObra('b'));
     await page.locator('#oOrcEditar').click();
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | grep -m3 error:
```
Expected: `TypeError: fn is not a function`; `error: cannot find 'somaTopicosOrc' in scope`. O browser não muda de resultado.

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift
@@ -157,3 +157,14 @@ public func pecasOrcamento(_ obra: Obra) -> PecasDoOrcamento {
     return PecasDoOrcamento(cartao: orc != nil, porTopico: orc?.modo == "topicos", definir: orc == nil && obra.fase != .vendida,
                             tocaveis: (orc?.topicos ?? []).compactMap(\.id).filter { comGasto.contains($0) })
 }
+
+/// `somaTopicosOrc` do calc.js: o total ao vivo da folha soma só o que é positivo em cada linha, na ordem da folha.
+public func somaTopicosOrc(_ numeros: [Double]) -> Double { numeros.reduce(0) { $0 + max(0, $1) } }
+
+/// `totalPreenchidoOrc` do calc.js: trocar para "Só o total" com o campo vazio preenche com a soma dos tópicos, se ela passar de
+/// zero (o previsto por tópico não some sem o número à vista); campo com texto fica como está.
+public func totalPreenchidoOrc(_ campo: String, _ numeros: [Double]) -> String {
+    if !campo.isEmpty { return campo }
+    let soma = somaTopicosOrc(numeros)
+    return soma > 0 ? numParaCampo(soma) : ""
+}
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -1719,9 +1719,9 @@ function formOrcamento(obraId){
       <button class="btn primary" id="cSave">Salvar</button>
     </div>`);
   const entradas = [...sheet.querySelectorAll('#orcTopWrap input[data-top]')];
-  const somaTopicos = () => entradas.reduce((s, i) => s + Math.max(0, parseNum(i.value)), 0);
+  const numerosDaFolha = () => entradas.map(i => parseNum(i.value));
   const pintaSoma = () => {
-    $('#orcSoma').textContent = money(somaTopicos());
+    $('#orcSoma').textContent = money(OBRA_CALC.somaTopicosOrc(numerosDaFolha()));
   };
   const aplicaModo = m => {
     modo = m;
@@ -1732,12 +1732,8 @@ function formOrcamento(obraId){
     });
     $('#orcTotalWrap').classList.toggle('hidden', m !== 'total');
     $('#orcTopWrap').classList.toggle('hidden', m !== 'topicos');
-    // trocar pra "só o total" com o campo vazio não pode apagar o previsto por tópico
-    // sem o construtor ver o número: pré-preenche com a soma atual (salvar ainda grava só o modo ativo).
-    if(m === 'total' && !$('#orcTotal').value){
-      const soma = somaTopicos();
-      if(soma > 0) $('#orcTotal').value = OBRA_CALC.numParaCampo(soma);
-    }
+    // "só o total" com o campo vazio ganha a soma dos tópicos (salvar ainda grava só o modo ativo)
+    if(m === 'total') $('#orcTotal').value = OBRA_CALC.totalPreenchidoOrc($('#orcTotal').value, numerosDaFolha());
   };
   sheet.querySelectorAll('.seg button').forEach(b => { b.onclick = () => aplicaModo(b.dataset.modo); });
   maskMoney('#orcTotal');
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -475,6 +475,15 @@
   function linhaTopicoOrc(t){
     return { gasto: moneyCurto(t.gasto), previsto: semCifrao(moneyCurto(t.previsto)) };
   }
+  /* Folha do orçamento: o total ao vivo soma só o que é positivo em cada linha (numeros: o valor lido de cada linha, na ordem
+     da folha). Trocar para "Só o total" com o campo vazio preenche com essa soma, se ela passar de zero: o previsto por tópico
+     não some sem o número à vista. campo: o texto do total; devolve o texto que o campo fica. */
+  const somaTopicosOrc = numeros => numeros.reduce((s, v) => s + Math.max(0, v), 0);
+  function totalPreenchidoOrc(campo, numeros){
+    if(campo) return campo;
+    const soma = somaTopicosOrc(numeros);
+    return soma > 0 ? numParaCampo(soma) : '';
+  }
   /* Peças do orçamento na obra: o cartão (e o "Editar") com orçamento válido; a lista "Por tópico" só no modo por tópico;
      "Definir orçamento" sem orçamento e fora da vendida; e os tópicos previstos que abrem a folha do tópico, os que têm gasto
      (qualquer gasto, até de valor zero), na ordem da lista. */
@@ -490,7 +499,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, pecasOrcamento, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -2
node tests/browser/orcamento.cjs && node tests/browser/xss.cjs
```
Expected: `ℹ pass 385` e `ℹ fail 0`; `✔ Test run with 199 tests in 34 suites passed`; as duas suítes terminam sem erro.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/OrcamentoTests.swift \
  app.js \
  calc.js \
  scripts/vetores-calc.mjs \
  tests/browser/orcamento.cjs \
  tests/vetores/calc.json
git commit -m "feat: total ao vivo e total preenchido da folha do orçamento no calc.js" -m "A soma ao vivo dos tópicos, que conta só o que é positivo em cada linha, e o total que a folha preenche com essa soma ao trocar para \"Só o total\" com o campo vazio saem do app.js para o calc.js, sem mudar o site, e entram nos vetores. O app nativo soma e preenche igual pela cópia em Swift."
```

### Task 5: Afazeres no dados.js e no calc.js, com o marcado no começo da lista

Adicionar, marcar, desmarcar e apagar afazer saem do `app.js` para o `dados.js`; a ordem da lista (pendentes e depois feitos, cada grupo na ordem do array) e o contador de pendentes, para o `calc.js`. Com o alinhamento aprovado (achado 4), marcar e desmarcar levam o afazer ao começo do array: o recém-marcado aparece no alto dos feitos e o desmarcado volta ao alto dos pendentes, no site e no app. Feito é só o `true`, como o `Afazer.feito` do núcleo (a leitura normalizada já deixa assim). Apagar um afazer que já sumiu (apagado em outro aparelho) não grava mais o mesmo documento de novo; a lista se redesenha igual. A cópia em Swift conta o limite de 500 em unidades UTF-16, como o `length` do JavaScript (o caso dos 250 emojis e uma letra). A suíte nova de browser confere o que vai para a nuvem a cada passo e entra no `rodar.cjs` depois do `orcamento.cjs`.

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Afazeres.swift`
- Test (criar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/AfazeresTests.swift`
- Test (criar): `tests/browser/dentro-da-obra.cjs`
- Modify: `app.js`
- Modify: `calc.js`
- Modify: `dados.js`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/rodar.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `LIMITES.afazer`; no núcleo, `Afazer` (`Modelo.swift`), `aparadoJS` e `Limites.afazer`.
- Produces: `OBRA_DADOS.conferirAfazer(texto)` (`{texto}`, `{erro: 'vazio'}` ou `{erro: 'afazer', mensagem: 'Use até 500 caracteres.'}`), `afazeresComNovo(lista, texto, id)`, `afazeresAlternado(lista, id)` e `afazeresSem(lista, id)` (lista nova ou `null` quando o id sumiu); `OBRA_CALC.afazeresEmOrdem(lista)` e `contadorDeAfazeres(lista)`. Em Swift: `ConferenciaDoAfazer` (`.ok(String)`, `.vazio`, `.longo(mensagem:)`), `conferirAfazer(_:)`, `afazeresComNovo(_:texto:id:)`, `afazeresAlternado(_:id:)`, `afazeresSem(_:id:)`, `afazeresEmOrdem(_:)` e `contadorDeAfazeres(_:)`.

- [ ] **Step 1: Escrever os vetores, os leitores em Swift e a suíte de browser**

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/AfazeresTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

extension ValorJSON {
    /// Uma lista de afazeres dos vetores (ausente conta como vazia, como no site).
    var afazeres: [Afazer] { (comoLista ?? []).compactMap { $0.comoObjeto.map(Afazer.init(campos:)) } }
}

func jsonDosAfazeres(_ l: [Afazer]?) -> ValorJSON { l.map { .lista($0.map { .objeto($0.campos) }) } ?? .nulo }

struct AfazeresTests {
    @Test func conferirComoOSite() {
        for c in Vetores.casos("dados.conferirAfazer") {
            let r: ValorJSON = switch conferirAfazer(c.args[0].comoTexto!) {
            case .ok(let texto): .objeto(["texto": .texto(texto)])
            case .vazio: .objeto(["erro": .texto("vazio")])
            case .longo(let mensagem): .objeto(["erro": .texto("afazer"), "mensagem": .texto(mensagem)])
            }
            confere(r, c.saida, .exata, c.caso)
        }
    }

    @Test func novoNoComeco() {
        for c in Vetores.casos("dados.afazeresComNovo") {
            confere(jsonDosAfazeres(afazeresComNovo(c.args[0].afazeres, texto: c.args[1].comoTexto!, id: c.args[2].comoTexto!)), c.saida, .exata, c.caso)
        }
    }

    @Test func marcarEDesmarcarLevamAoComeco() {
        for c in Vetores.casos("dados.afazeresAlternado") {
            confere(jsonDosAfazeres(afazeresAlternado(c.args[0].afazeres, id: c.args[1].comoTexto!)), c.saida, .exata, c.caso)
        }
    }

    @Test func apagarSemPerguntar() {
        for c in Vetores.casos("dados.afazeresSem") {
            confere(jsonDosAfazeres(afazeresSem(c.args[0].afazeres, id: c.args[1].comoTexto!)), c.saida, .exata, c.caso)
        }
    }

    @Test func pendentesAntesDosFeitos() {
        for c in Vetores.casos("calc.afazeresEmOrdem") {
            confere(jsonDosAfazeres(afazeresEmOrdem(c.arg(0)?.afazeres ?? [])), c.saida, .exata, c.caso)
        }
    }

    @Test func contadorDosPendentes() {
        for c in Vetores.casos("calc.contadorDeAfazeres") {
            confere(.texto(contadorDeAfazeres(c.arg(0)?.afazeres ?? [])), c.saida, .exata, c.caso)
        }
    }
}
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -685,6 +685,58 @@ gravado('antigo que não é objeto conta como sem orçamento', 'lixo', 'topicos'
 gravado('antigo lista conta como sem orçamento', [1, 2], 'total', 10, FOLHA);
 gravado('tópicos do antigo que não são objeto não entram', { modo: 'topicos', topicos: [5] }, 'topicos', 0, { ...FOLHA, pintura: 3000 });
 
+/* Afazeres (app.js addAfazer, renderAfazeres e afazerRow): o que adicionar, marcar, desmarcar e apagar gravam, a ordem da
+   lista e o contador. As listas passam pela leitura normalizada, como o app as vê. */
+const afazeresLidos = afazeres => D.normaliza({ obras: [{ id: 'x', dataInicio: '2026-01-01', afazeres }] }).obras[0].afazeres;
+const AFZ = afazeresLidos([
+  { id: 'a1', texto: 'Comprar tinta', feito: false },
+  { id: 'a2', texto: 'Pagar pedreiro', feito: true },
+  { id: 'a3', texto: 'Ligar eletricista', feito: false, prioridade: 'alta' },
+  { id: 'a4', texto: 'Medir janelas', feito: true },
+]);
+const AFZ_REPETIDO = afazeresLidos([{ id: 'x', texto: 'Um', feito: false }, { id: 'x', texto: 'Dois', feito: true }, { id: 'y', texto: 'Três', feito: false }]);
+const conferirAfz = (nome, texto) => caso('dados.conferirAfazer', nome, [texto], D.conferirAfazer);
+conferirAfz('texto comum', 'Comprar tinta');
+conferirAfz('aparado, com o espaço do meio', '  Pagar  o pedreiro  ');
+conferirAfz('vazio', '');
+conferirAfz('só espaços', '   ');
+conferirAfz('espaço duro, quebra e tab', '\u00a0\n\t');
+conferirAfz('BOM nas pontas sai', '\ufeffabc\ufeff');
+conferirAfz('espaço de largura zero fica', '\u200b');
+conferirAfz('500 letras', 'a'.repeat(500));
+conferirAfz('501 letras', 'a'.repeat(501));
+conferirAfz('500 depois de aparar', ' ' + 'a'.repeat(500) + ' ');
+conferirAfz('250 emojis são 500 unidades', '😀'.repeat(250));
+conferirAfz('250 emojis e uma letra', '😀'.repeat(250) + 'a');
+const comNovo = (nome, ...args) => caso('dados.afazeresComNovo', nome, args, D.afazeresComNovo);
+comNovo('no começo da lista, pendente', AFZ, 'Comprar areia', 'n1');
+comNovo('lista vazia', [], 'Primeiro', 'n1');
+comNovo('obra sem a chave afazeres', undefined, 'Primeiro', 'n1');
+const alternado = (nome, ...args) => caso('dados.afazeresAlternado', nome, args, D.afazeresAlternado);
+alternado('marcar o do meio leva ao começo, com o campo desconhecido', AFZ, 'a3');
+alternado('desmarcar o último leva ao começo', AFZ, 'a4');
+alternado('marcar o primeiro', AFZ, 'a1');
+alternado('id que sumiu', AFZ, 'zz');
+alternado('obra sem a chave afazeres', undefined, 'a1');
+alternado('id repetido troca o primeiro', AFZ_REPETIDO, 'x');
+const sem = (nome, ...args) => caso('dados.afazeresSem', nome, args, D.afazeresSem);
+sem('apagar o do meio', AFZ, 'a2');
+sem('id que sumiu', AFZ, 'zz');
+sem('id repetido sai todo', AFZ_REPETIDO, 'x');
+sem('obra sem a chave afazeres', undefined, 'a1');
+const ordemAfz = calc('afazeresEmOrdem');
+ordemAfz('pendentes e depois feitos, cada grupo na ordem da lista', AFZ);
+ordemAfz('o recém-marcado fica no alto dos feitos', D.afazeresAlternado(AFZ, 'a3'));
+ordemAfz('o desmarcado volta ao alto dos pendentes', D.afazeresAlternado(AFZ, 'a4'));
+ordemAfz('lista vazia', []);
+ordemAfz('obra sem a chave afazeres', undefined);
+const contadorAfz = calc('contadorDeAfazeres');
+contadorAfz('dois pendentes', AFZ);
+contadorAfz('um pendente', D.afazeresAlternado(AFZ, 'a1'));
+contadorAfz('tudo feito', AFZ.map(a => ({ ...a, feito: true })));
+contadorAfz('lista vazia', []);
+contadorAfz('obra sem a chave afazeres', undefined);
+
 /* ---------- push.js e id ---------- */
 for(const t of ['', 'a', 'abc', 'fcm-token:APA91bHun4MxP5egoKMwt2KZFBaFUH-1RYqx', 'https://fcm.googleapis.com/fcm/send/eXyZ', 'ç😀', 'x'.repeat(300)])
   caso('push.hashEndpoint', JSON.stringify(t.length > 40 ? t.slice(0, 40) + '…' : t), [t], P.hashEndpoint);
```

Criar `tests/browser/dentro-da-obra.cjs`:

```js
/* Dentro da obra com dados sintéticos: afazeres (o que grava, a ordem e o contador). Sem contas nem rede.
   Precisa de `node tests/browser/servidor.cjs` no ar (porta 8123). O duplê do CLOUD guarda cada blob gravado em `salvos`:
   o teste confere o que foi para a nuvem, não só o `db` da página. */
const assert=require('node:assert/strict');
const {chromium}=require('playwright');

const OBRA={id:'o',nome:'Casa Alphaville',dataInicio:'2026-01-10',gastos:[],
  afazeres:[{id:'a1',texto:'Comprar tinta',feito:false},{id:'a2',texto:'Pagar pedreiro',feito:true},
    {id:'a3',texto:'Ligar eletricista',feito:false,prioridade:'alta'}]};

(async()=>{
  const browser=await chromium.launch();
  try{
    const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:393,height:852}});
    await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
    await ctx.route('https://**/*',r=>r.abort());
    await ctx.addInitScript(()=>{
      sessionStorage.setItem('splashVista','1');window.errosObra=[];window.salvos=[];
      addEventListener('error',e=>errosObra.push(e.message));
      addEventListener('securitypolicyviolation',e=>errosObra.push(e.violatedDirective));
      window.CLOUD={user:()=>({uid:'teste'}),onAuth:cb=>cb({uid:'teste'}),watchDados:()=>()=>{},
        saveDados:d=>{salvos.push(JSON.parse(JSON.stringify(d)));return Promise.resolve();},estado:()=>'ocioso'};
    });
    const page=await ctx.newPage();
    await page.goto('http://localhost:8123');
    await page.evaluate(obra=>{document.getElementById('auth')?.classList.add('hidden');document.body.classList.remove('locked');
      db=normaliza({obras:[obra],config:{taxaMensal:1,topicosCustom:[]}});
      dadosCarregados=true;renderAll();openObra('o');},OBRA);

    const textos=()=>page.locator('#oAfazeres li .li-main .t').allTextContents();
    const linha=texto=>page.locator('#oAfazeres li').filter({has:page.locator('.li-main .t',{hasText:texto})});
    const contador=async()=>(await page.locator('#afzCount').textContent()).trim();
    const salvo=()=>page.evaluate(()=>salvos.length?salvos.at(-1).obras[0].afazeres:null);
    const nuvemIgualAoDb=async()=>assert.deepEqual(await salvo(),await page.evaluate(()=>obraById('o').afazeres));

    // Pendentes antes dos feitos, cada grupo na ordem da lista
    assert.deepEqual(await textos(),['Comprar tinta','Ligar eletricista','Pagar pedreiro']);
    assert.equal(await contador(),'(2 pendentes)');

    // Adicionar: o texto aparado entra no começo, pendente; o campo limpa e fica com o foco
    await page.locator('#afzInput').fill('  Comprar areia  ');
    await page.locator('#afzAdd').click();
    const novo=await page.evaluate(()=>obraById('o').afazeres[0]);
    assert.equal(novo.texto,'Comprar areia');
    assert.equal(novo.feito,false);
    assert.equal(await page.locator('#afzInput').inputValue(),'');
    assert.equal(await page.evaluate(()=>document.activeElement.id),'afzInput');
    assert.equal(await contador(),'(3 pendentes)');
    await nuvemIgualAoDb();
    // Só espaços, pelo Enter: nada muda e nada grava
    const gravacoes=await page.evaluate(()=>salvos.length);
    await page.locator('#afzInput').fill('   ');
    await page.locator('#afzInput').press('Enter');
    assert.equal(await page.evaluate(()=>obraById('o').afazeres.length),4);
    assert.equal(await page.evaluate(()=>salvos.length),gravacoes);
    assert.equal(await page.locator('.toast').count(),0,'campo vazio não avisa');

    // Marcar pelo círculo: vai para o alto dos feitos, com o campo desconhecido
    await linha('Ligar eletricista').locator('.afz-check').click();
    assert.deepEqual(await textos(),['Comprar areia','Comprar tinta','Ligar eletricista','Pagar pedreiro']);
    assert.deepEqual(await page.evaluate(()=>obraById('o').afazeres[0]),{id:'a3',texto:'Ligar eletricista',feito:true,prioridade:'alta'});
    assert.equal(await contador(),'(2 pendentes)');
    await nuvemIgualAoDb();
    // Desmarcar pelo texto: volta ao alto dos pendentes
    await linha('Pagar pedreiro').locator('.li-main').click();
    assert.deepEqual(await textos(),['Pagar pedreiro','Comprar areia','Comprar tinta','Ligar eletricista']);
    assert.equal(await contador(),'(3 pendentes)');
    await nuvemIgualAoDb();

    // Afazer apagado em outro aparelho com a lista na tela: tocar na linha velha não grava nada
    await page.evaluate(()=>{db=normaliza(JSON.parse(JSON.stringify(db)));const o=obraById('o');o.afazeres=o.afazeres.filter(a=>a.id!=='a1');});
    const antes=await page.evaluate(()=>salvos.length);
    await linha('Comprar tinta').locator('.afz-check').click();
    assert.equal(await page.evaluate(()=>salvos.length),antes);
    assert.equal(await page.evaluate(()=>obraById('o').afazeres.some(a=>a.id==='a1')),false);
    await linha('Comprar tinta').locator('.li-del').click();
    assert.equal(await page.evaluate(()=>salvos.length),antes);
    assert.equal(await page.evaluate(()=>obraById('o').afazeres.length),3);
    assert.deepEqual(await textos(),['Pagar pedreiro','Comprar areia','Ligar eletricista']);

    // Apagar sem perguntar
    await linha('Comprar areia').locator('.li-del').click();
    assert.deepEqual(await textos(),['Pagar pedreiro','Ligar eletricista']);
    assert.equal(await page.locator('dialog[open]').count(),0);
    await nuvemIgualAoDb();
    await linha('Pagar pedreiro').locator('.li-del').click();
    await linha('Ligar eletricista').locator('.li-del').click();
    assert.equal(await contador(),'');
    assert.match(await page.locator('#oAfazeres').textContent(),/Nenhum afazer\.\s*Anote o que falta na obra\./);
    assert.deepEqual(await salvo(),[]);

    assert.deepEqual(await page.evaluate(()=>errosObra),[]);
    await ctx.close();
    console.log('ok - dentro da obra: afazeres');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
```

Em `tests/browser/rodar.cjs`:

```diff
--- a/tests/browser/rodar.cjs
+++ b/tests/browser/rodar.cjs
@@ -21,6 +21,7 @@ const run=(file,args=[])=>new Promise((resolve,reject)=>{
     await run('tests/browser/login.cjs');
     await run('tests/browser/escrita.cjs');
     await run('tests/browser/orcamento.cjs');
+    await run('tests/browser/dentro-da-obra.cjs');
     await run('tests/browser/ios.cjs');
     await run('tests/browser/vidro.cjs');
     await run('tests/browser/contraste.cjs',[os.tmpdir()]);
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | grep -m3 error:
node tests/browser/dentro-da-obra.cjs
```
Expected: `TypeError: fn is not a function`; `error: cannot find 'conferirAfazer' in scope`; o browser para com `AssertionError [ERR_ASSERTION]: Expected values to be strictly deep-equal:` no passo "Marcar pelo círculo", com `+ 'Pagar pedreiro'` antes de `'Ligar eletricista'` (o site de hoje deixa o recém-marcado depois do feito mais antigo).

- [ ] **Step 3: Implementar**

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/Afazeres.swift`:

```swift
import Foundation

/* Os afazeres como o site os grava e mostra: adicionar, marcar, desmarcar e apagar (dados.js), a ordem da lista e o contador
   (calc.js). Marcar e desmarcar levam o afazer ao começo da lista: mostrada em pendentes e depois feitos, cada grupo na ordem
   da lista, o recém-marcado fica no alto dos feitos e o desmarcado volta ao alto dos pendentes. Campos que o app não conhece
   ficam em cada afazer. Cada regra tem caso nos vetores. */

public enum ConferenciaDoAfazer: Equatable, Sendable {
    /// O texto aparado, pronto para gravar.
    case ok(String)
    /// Nada a fazer (o campo fica com o foco).
    case vazio
    case longo(mensagem: String)
}

/// `conferirAfazer` do dados.js: o texto aparado; vazio não faz nada; até 500 unidades UTF-16.
public func conferirAfazer(_ texto: String) -> ConferenciaDoAfazer {
    let t = aparadoJS(texto)
    if t.isEmpty { return .vazio }
    if t.utf16.count > Limites.afazer { return .longo(mensagem: "Use até \(Limites.afazer) caracteres.") }
    return .ok(t)
}

/// `afazeresComNovo` do dados.js: o novo no começo da lista, pendente (texto já conferido).
public func afazeresComNovo(_ lista: [Afazer], texto: String, id: String) -> [Afazer] {
    [Afazer(campos: ["id": .texto(id), "texto": .texto(texto), "feito": .booleano(false)])] + lista
}

/// `afazeresAlternado` do dados.js: o feito trocado e o afazer no começo da lista; nil se o id sumiu.
public func afazeresAlternado(_ lista: [Afazer], id: String) -> [Afazer]? {
    guard let i = lista.firstIndex(where: { $0.id == id }) else { return nil }
    var resto = lista
    var afazer = resto.remove(at: i)
    afazer.feito.toggle()
    return [afazer] + resto
}

/// `afazeresSem` do dados.js: sem o afazer (todos com o id); nil se o id sumiu.
public func afazeresSem(_ lista: [Afazer], id: String) -> [Afazer]? {
    guard lista.contains(where: { $0.id == id }) else { return nil }
    return lista.filter { $0.id != id }
}

/// `afazeresEmOrdem` do calc.js: pendentes e depois feitos, cada grupo na ordem da lista.
public func afazeresEmOrdem(_ lista: [Afazer]) -> [Afazer] { lista.filter { !$0.feito } + lista.filter(\.feito) }

/// `contadorDeAfazeres` do calc.js: "(N pendente)", "(N pendentes)" ou nada.
public func contadorDeAfazeres(_ lista: [Afazer]) -> String {
    let n = lista.filter { !$0.feito }.count
    return n == 0 ? "" : "(\(n) pendente\(n > 1 ? "s" : ""))"
}
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -454,11 +454,11 @@ function renderObra(){
 
   renderAfazeres(o);
   const addAfazer = ()=>{
-    const inp = $('#afzInput'); const txt = inp.value.trim();
-    if(!txt){ inp.focus(); return; }
-    if(!textoValido(txt, 'afazer', inp)) return;
+    const inp = $('#afzInput'); const c = OBRA_DADOS.conferirAfazer(inp.value);
+    if(c.erro === 'vazio'){ inp.focus(); return; }
+    if(c.erro){ toast(c.mensagem, 'erro'); inp.focus(); return; }
     const oo = obraById(obraAberta); if(!oo) return;
-    (oo.afazeres || (oo.afazeres = [])).unshift({ id:uid(), texto:txt, feito:false });
+    oo.afazeres = OBRA_DADOS.afazeresComNovo(oo.afazeres, c.texto, uid());
     save(); inp.value = ''; renderAfazeres(oo); inp.focus();
   };
   $('#afzAdd').onclick = addAfazer;
@@ -486,20 +486,19 @@ function renderObra(){
 function renderAfazeres(o){
   const list = $('#oAfazeres'); if(!list) return;
   const items = o.afazeres || [];
-  const pend = items.filter(a=>!a.feito);
-  const done = items.filter(a=>a.feito);
-  $('#afzCount').textContent = pend.length ? `(${pend.length} pendente${pend.length>1?'s':''})` : '';
+  $('#afzCount').textContent = OBRA_CALC.contadorDeAfazeres(items);
   list.innerHTML = '';
   if(!items.length){ list.innerHTML = emptyBlock(ICON('check'),'Nenhum afazer.<br>Anote o que falta na obra.'); return; }
-  [...pend, ...done].forEach(a=>list.appendChild(afazerRow(o, a)));
+  OBRA_CALC.afazeresEmOrdem(items).forEach(a=>list.appendChild(afazerRow(o, a)));
 }
 
 function afazerRow(o, a){
   const li = el('li', a.feito ? 'afz-done' : '');
+  // marcar e desmarcar levam o afazer ao começo da lista (dados.js afazeresAlternado)
   const toggle = ()=>{
     const oo = obraById(o.id); if(!oo) return;
-    const aa = (oo.afazeres||[]).find(x=>x.id===a.id); if(!aa) return;
-    aa.feito = !aa.feito; save(); renderAfazeres(oo);
+    const nova = OBRA_DADOS.afazeresAlternado(oo.afazeres, a.id); if(!nova) return;
+    oo.afazeres = nova; save(); renderAfazeres(oo);
   };
   const check = el('button','afz-check', ICON('check'));
   check.setAttribute('aria-label', a.feito ? 'Desmarcar afazer' : 'Marcar feito');
@@ -511,7 +510,9 @@ function afazerRow(o, a){
   del.setAttribute('aria-label','Apagar afazer');
   del.onclick = ()=>{
     const oo = obraById(o.id); if(!oo) return;
-    oo.afazeres = (oo.afazeres||[]).filter(x=>x.id!==a.id); save(); renderAfazeres(oo);
+    const nova = OBRA_DADOS.afazeresSem(oo.afazeres, a.id);
+    if(nova){ oo.afazeres = nova; save(); }
+    renderAfazeres(oo);
   };
   li.append(check, main, del);
   return li;
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -484,6 +484,13 @@
     const soma = somaTopicosOrc(numeros);
     return soma > 0 ? numParaCampo(soma) : '';
   }
+  /* Afazeres na tela (app.js renderAfazeres): pendentes e depois feitos, cada grupo na ordem da lista; o contador dos pendentes.
+     Feito é só o true (a leitura normalizada já o deixa assim). */
+  const afazeresEmOrdem = lista => { const l = Array.isArray(lista) ? lista : []; return [...l.filter(a => a.feito !== true), ...l.filter(a => a.feito === true)]; };
+  function contadorDeAfazeres(lista){
+    const n = (Array.isArray(lista) ? lista : []).filter(a => a.feito !== true).length;
+    return n ? `(${n} pendente${n > 1 ? 's' : ''})` : '';
+  }
   /* Peças do orçamento na obra: o cartão (e o "Editar") com orçamento válido; a lista "Por tópico" só no modo por tópico;
      "Definir orçamento" sem orçamento e fora da vendida; e os tópicos previstos que abrem a folha do tópico, os que têm gasto
      (qualquer gasto, até de valor zero), na ordem da lista. */
@@ -499,7 +506,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Em `dados.js`:

```diff
--- a/dados.js
+++ b/dados.js
@@ -161,7 +161,32 @@
     for(const [id, v] of Object.entries(antes)) if(!Object.prototype.hasOwnProperty.call(valores, id)) topicos[id] = v;
     return {...resto, modo:'topicos', topicos};
   }
-  const api={normaliza,LIMITES,conferirGasto,gastosLancados,gastoEditado,LIMITE_OBRAS,avisoLimiteDeObras,conferirObra,obraNova,obraEditada,conferirVenda,orcamentoGravado};
+  /* ---- afazeres (app.js addAfazer e afazerRow) ----
+     "Adicionar": o texto aparado; vazio não faz nada; até LIMITES.afazer unidades. O novo entra no começo da lista, pendente.
+     Marcar e desmarcar trocam o feito e levam o afazer ao começo: com a lista mostrada em pendentes e depois feitos, cada grupo
+     na ordem da lista (calc.js afazeresEmOrdem), o recém-marcado fica no alto dos feitos e o desmarcado volta ao alto dos
+     pendentes. Apagar não pergunta. Os campos desconhecidos de cada afazer ficam. Lista ausente conta como vazia; id que sumiu
+     (apagado em outro aparelho) devolve null: nada a gravar. */
+  function conferirAfazer(texto){
+    const t = texto.trim();
+    if(!t) return {erro:'vazio'};
+    if(t.length>LIMITES.afazer) return {erro:'afazer', mensagem:`Use até ${LIMITES.afazer} caracteres.`};
+    return {texto:t};
+  }
+  const afazeresDaLista = l => Array.isArray(l) ? l : [];
+  function afazeresComNovo(lista, texto, id){
+    return [{id, texto, feito:false}, ...afazeresDaLista(lista)];
+  }
+  function afazeresAlternado(lista, id){
+    const l = afazeresDaLista(lista), i = l.findIndex(a => a.id === id);
+    if(i < 0) return null;
+    return [{...l[i], feito:l[i].feito !== true}, ...l.slice(0, i), ...l.slice(i + 1)];
+  }
+  function afazeresSem(lista, id){
+    const l = afazeresDaLista(lista);
+    return l.some(a => a.id === id) ? l.filter(a => a.id !== id) : null;
+  }
+  const api={normaliza,LIMITES,conferirGasto,gastosLancados,gastoEditado,LIMITE_OBRAS,avisoLimiteDeObras,conferirObra,obraNova,obraEditada,conferirVenda,orcamentoGravado,conferirAfazer,afazeresComNovo,afazeresAlternado,afazeresSem};
   if(typeof module !== 'undefined' && module.exports) module.exports=api;
   else root.OBRA_DADOS=api;
 })(typeof window !== 'undefined' ? window : globalThis);
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -2
node tests/browser/dentro-da-obra.cjs && node tests/browser/xss.cjs
```
Expected: `ℹ pass 385` e `ℹ fail 0`; `✔ Test run with 205 tests in 35 suites passed` (a suíte nova `AfazeresTests`, com 6 testes); `ok - dentro da obra: afazeres` e o `xss.cjs` sem erro.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Afazeres.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/AfazeresTests.swift \
  app.js \
  calc.js \
  dados.js \
  scripts/vetores-calc.mjs \
  tests/browser/dentro-da-obra.cjs \
  tests/browser/rodar.cjs \
  tests/vetores/calc.json
git commit -m "feat: afazeres no dados.js e no calc.js, com o marcado no começo da lista" -m "Adicionar, marcar, desmarcar e apagar afazer saem do app.js para o dados.js, e a ordem da lista e o contador de pendentes vão para o calc.js, todos nos vetores. Marcar e desmarcar passam a levar o afazer ao começo da lista: o recém-marcado aparece no alto dos feitos e o desmarcado volta ao alto dos pendentes, no site e no app nativo, que copia as regras em Swift. A suíte nova de browser confere o que vai para a nuvem a cada passo."
```

### Task 6: Mês escolhido no filtro não some quando sai o último gasto dele

O conserto do achado 1. Hoje, com um mês escolhido no filtro dos lançamentos, apagar o último gasto dele (ou mudar a data para outro mês) tira o mês do `<select>`, que passa a mostrar "Todos os meses" enquanto a lista continua filtrada por ele, com "Nada encontrado com esse filtro." e o contador "0/N". A lista de meses sai do `app.js` para o `calc.js`, com quantos gastos cada mês tem (o menu do app mostra; o site ignora), e passa a incluir o mês escolhido mesmo sem gasto: o `<select>` continua mostrando o filtro que vale, e a pessoa pode tirá-lo. O rótulo "out/26" do `<select>` fica no `app.js`. A suíte `dentro-da-obra.cjs` ganha uma segunda obra (`OBRA_FILTRO`, três gastos em fevereiro e março de 2026) e anda o caminho do defeito.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/dentro-da-obra.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Produces: `OBRA_CALC.mesesDoFiltro(gastos, escolhido)` → `[{mes, qtd}]`, do mais novo ao mais antigo, com os futuros; o escolhido entra com zero se não tem gasto, e vazio ou ausente não entra. Em Swift: `MesDoFiltro` e `mesesDoFiltro(_:escolhido:)`.

- [ ] **Step 1: Escrever os vetores, os leitores em Swift e o caminho do defeito no browser**

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift
@@ -34,6 +34,13 @@ struct ListasTests {
         }
     }
 
+    @Test func mesesDoFiltroComOEscolhido() {
+        for c in Vetores.casos("calc.mesesDoFiltro") {
+            let r = mesesDoFiltro(c.args[0].gastos, escolhido: c.arg(1)?.comoTexto ?? "")
+            confere(.lista(r.map { .objeto(["mes": .texto($0.mes), "qtd": .numero(Double($0.qtd))]) }), c.saida, .exata, c.caso)
+        }
+    }
+
     @Test func filtroDosLancamentos() {
         for c in Vetores.casos("calc.filtraGastos") {
             let topicos = (c.args[1].comoObjeto ?? [:]).mapValues { t in
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -268,6 +268,16 @@ filtra('texto e mês', O1.gastos, TOPICOS_MAPA, { texto: 'tinta', mes: '2025-08'
 filtra('tópico próprio pelo nome', O4.gastos, TOPICOS_MAPA, { texto: 'automacao' });
 filtra('tópico apagado busca pelo id', [{ id: 'k', valor: 1, topico: 'c_sumiu', descricao: '', data: '2026-01-01' }], TOPICOS_MAPA, { texto: 'c_sum' });
 filtra('nada encontrado', O1.gastos, TOPICOS_MAPA, { texto: 'xyz' });
+/* Os meses do filtro (app.js renderObra), com quantos gastos cada um tem. O mês escolhido nunca some da lista. */
+const mesesFiltro = calc('mesesDoFiltro');
+mesesFiltro('do mais novo ao mais antigo, com os futuros', O1.gastos, '');
+mesesFiltro('mês escolhido com gasto não se repete', O1.gastos, '2025-08');
+mesesFiltro('mês escolhido sem gasto entra com zero, no meio', O1.gastos, '2026-01');
+mesesFiltro('mês escolhido sem gasto, o mais novo', O1.gastos, '2027-01');
+mesesFiltro('mês escolhido sem gasto, o mais antigo', O1.gastos, '2024-12');
+mesesFiltro('sem gasto e sem mês', [], '');
+mesesFiltro('sem gasto, com o mês escolhido', [], '2026-03');
+mesesFiltro('sem o argumento do mês', O1.gastos);
 
 /* ---------- descrição do gasto: sugestões e repetido ---------- */
 const normDesc = calc('normalizaDescricao');
```

Em `tests/browser/dentro-da-obra.cjs`:

```diff
--- a/tests/browser/dentro-da-obra.cjs
+++ b/tests/browser/dentro-da-obra.cjs
@@ -1,4 +1,4 @@
-/* Dentro da obra com dados sintéticos: afazeres (o que grava, a ordem e o contador). Sem contas nem rede.
+/* Dentro da obra com dados sintéticos: afazeres (o que grava, a ordem e o contador) e o filtro dos lançamentos. Sem contas nem rede.
    Precisa de `node tests/browser/servidor.cjs` no ar (porta 8123). O duplê do CLOUD guarda cada blob gravado em `salvos`:
    o teste confere o que foi para a nuvem, não só o `db` da página. */
 const assert=require('node:assert/strict');
@@ -7,6 +7,10 @@ const {chromium}=require('playwright');
 const OBRA={id:'o',nome:'Casa Alphaville',dataInicio:'2026-01-10',gastos:[],
   afazeres:[{id:'a1',texto:'Comprar tinta',feito:false},{id:'a2',texto:'Pagar pedreiro',feito:true},
     {id:'a3',texto:'Ligar eletricista',feito:false,prioridade:'alta'}]};
+const OBRA_FILTRO={id:'f',nome:'Sobrado Centro',dataInicio:'2026-01-10',afazeres:[],gastos:[
+  {id:'g1',valor:1200,topico:'pintura',descricao:'Tinta acrílica',data:'2026-03-05',pagamento:'pix'},
+  {id:'g2',valor:5400,topico:'eletrica',descricao:'Fios e disjuntores',data:'2026-02-10',pagamento:'pix'},
+  {id:'g3',valor:800,topico:'eletrica',descricao:'Tomadas',data:'2026-02-20',pagamento:'pix'}]};
 
 (async()=>{
   const browser=await chromium.launch();
@@ -23,14 +27,14 @@ const OBRA={id:'o',nome:'Casa Alphaville',dataInicio:'2026-01-10',gastos:[],
     });
     const page=await ctx.newPage();
     await page.goto('http://localhost:8123');
-    await page.evaluate(obra=>{document.getElementById('auth')?.classList.add('hidden');document.body.classList.remove('locked');
-      db=normaliza({obras:[obra],config:{taxaMensal:1,topicosCustom:[]}});
-      dadosCarregados=true;renderAll();openObra('o');},OBRA);
+    await page.evaluate(obras=>{document.getElementById('auth')?.classList.add('hidden');document.body.classList.remove('locked');
+      db=normaliza({obras,config:{taxaMensal:1,topicosCustom:[]}});
+      dadosCarregados=true;renderAll();openObra('o');},[OBRA,OBRA_FILTRO]);
 
     const textos=()=>page.locator('#oAfazeres li .li-main .t').allTextContents();
     const linha=texto=>page.locator('#oAfazeres li').filter({has:page.locator('.li-main .t',{hasText:texto})});
     const contador=async()=>(await page.locator('#afzCount').textContent()).trim();
-    const salvo=()=>page.evaluate(()=>salvos.length?salvos.at(-1).obras[0].afazeres:null);
+    const salvo=()=>page.evaluate(()=>salvos.length?salvos.at(-1).obras.find(o=>o.id==='o').afazeres:null);
     const nuvemIgualAoDb=async()=>assert.deepEqual(await salvo(),await page.evaluate(()=>obraById('o').afazeres));
 
     // Pendentes antes dos feitos, cada grupo na ordem da lista
@@ -89,8 +93,28 @@ const OBRA={id:'o',nome:'Casa Alphaville',dataInicio:'2026-01-10',gastos:[],
     assert.match(await page.locator('#oAfazeres').textContent(),/Nenhum afazer\.\s*Anote o que falta na obra\./);
     assert.deepEqual(await salvo(),[]);
 
+    // Filtro de mês: o mês escolhido não some do <select> quando sai o último gasto dele (achado 1)
+    await page.evaluate(()=>openObra('f'));
+    const meses=()=>page.locator('#fMes option').evaluateAll(os=>os.map(o=>[o.value,o.textContent]));
+    const lancamentos=async()=>(await page.locator('#lanCount').textContent()).trim();
+    assert.deepEqual(await meses(),[['','Todos os meses'],['2026-03','mar/26'],['2026-02','fev/26']]);
+    await page.locator('#fMes').selectOption('2026-03');
+    assert.equal(await lancamentos(),'1/3');
+    await page.locator('#oGastos li').filter({hasText:'Tinta acrílica'}).locator('.li-del').click();
+    await page.locator('dialog[open] button',{hasText:'Excluir'}).click();
+    await page.waitForFunction(()=>obraById('f').gastos.length===2);
+    assert.equal(await page.locator('#fMes').inputValue(),'2026-03','o mês que filtra continua à vista');
+    assert.deepEqual(await meses(),[['','Todos os meses'],['2026-03','mar/26'],['2026-02','fev/26']]);
+    assert.equal(await lancamentos(),'0/2');
+    assert.match(await page.locator('#oGastos').textContent(),/Nada encontrado com esse filtro\./);
+    // tirar o mês: ele sai da lista, que fica só com os meses que têm gasto
+    await page.locator('#fMes').selectOption('');
+    assert.equal(await lancamentos(),'2');
+    await page.evaluate(()=>renderAll());
+    assert.deepEqual(await meses(),[['','Todos os meses'],['2026-02','fev/26']]);
+
     assert.deepEqual(await page.evaluate(()=>errosObra),[]);
     await ctx.close();
-    console.log('ok - dentro da obra: afazeres');
+    console.log('ok - dentro da obra: afazeres e filtro de mês');
   }finally{await browser.close();}
 })().catch(e=>{console.error(e);process.exitCode=1;});
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | grep -m3 error:
node tests/browser/dentro-da-obra.cjs
```
Expected: `TypeError: fn is not a function`; `error: cannot find 'mesesDoFiltro' in scope`; o browser para com `AssertionError [ERR_ASSERTION]: o mês que filtra continua à vista` e `'' !== '2026-03'`: o `<select>` voltou a "Todos os meses" com o filtro ainda valendo.

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift
@@ -60,6 +60,21 @@ func contem(_ texto: String, _ trecho: String) -> Bool {
     return false
 }
 
+public struct MesDoFiltro: Equatable, Sendable {
+    /// AAAA-MM.
+    public let mes: String
+    public let qtd: Int
+}
+
+/// `mesesDoFiltro` do calc.js: os meses com gasto, do mais novo ao mais antigo (com os futuros), e quantos gastos cada um tem.
+/// O mês escolhido entra mesmo sem gasto (com zero): o filtro que continua valendo nunca some da lista.
+public func mesesDoFiltro(_ gastos: [Gasto], escolhido: String) -> [MesDoFiltro] {
+    var qtd: [String: Int] = [:]
+    for g in gastos { qtd[String(g.data.prefix(7)), default: 0] += 1 }
+    if !escolhido.isEmpty && qtd[escolhido] == nil { qtd[escolhido] = 0 }
+    return qtd.keys.sorted { menorJS($1, $0) }.map { MesDoFiltro(mes: $0, qtd: qtd[$0]!) }
+}
+
 public struct FiltroGastos: Equatable, Sendable {
     public var texto: String?
     public var mes: String?
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -426,7 +426,8 @@ function renderObra(){
     ${evoChartHtml(o)}
     ${mesChartHtml(o)}`;
 
-  const mesesComGasto = [...new Set(o.gastos.map(g=>g.data.slice(0,7)))].sort().reverse();
+  // o mês escolhido fica na lista mesmo sem gasto: o filtro que vale nunca some do <select>
+  const mesesDoFiltro = OBRA_CALC.mesesDoFiltro(o.gastos, filtroMes);
   // no celular a busca divide a linha com o mês: a dica curta do iOS cabe inteira (a longa era cortada)
   const dicaBusca = matchMedia('(max-width:899px)').matches ? 'Buscar' : 'Pesquisar gasto ou tópico';
   const lanc = `
@@ -435,7 +436,7 @@ function renderObra(){
         <label class="busca"><span class="busca-ic" aria-hidden="true">${ICON('lupa')}</span>
           <input id="fBusca" placeholder="${dicaBusca}" aria-label="Pesquisar gasto ou tópico" autocomplete="off" value="${escapeHtml(filtroTexto)}"></label>
         <select id="fMes"><option value="">Todos os meses</option>
-          ${mesesComGasto.map(m=>`<option value="${escapeHtml(m)}"${m===filtroMes?' selected':''}>${MESAB[+m.slice(5)-1]}/${escapeHtml(m.slice(2,4))}</option>`).join('')}
+          ${mesesDoFiltro.map(({mes:m})=>`<option value="${escapeHtml(m)}"${m===filtroMes?' selected':''}>${MESAB[+m.slice(5)-1]}/${escapeHtml(m.slice(2,4))}</option>`).join('')}
         </select>
       </div>
       <ul class="list" id="oGastos"></ul>
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -237,6 +237,16 @@
     });
   }
 
+  /* Meses do filtro dos lançamentos: os que têm gasto, do mais novo ao mais antigo (com os futuros), e quantos gastos cada um
+     tem. O mês escolhido entra mesmo sem gasto (com zero): apagar o último gasto dele, ou mudar a data, não esconde o filtro que
+     continua valendo. */
+  function mesesDoFiltro(gastos, escolhido){
+    const qtd = Object.create(null);
+    (Array.isArray(gastos) ? gastos : []).forEach(g => { const m = g.data.slice(0, 7); qtd[m] = (qtd[m] || 0) + 1; });
+    if(escolhido && !(escolhido in qtd)) qtd[escolhido] = 0;
+    return Object.keys(qtd).sort().reverse().map(mes => ({ mes, qtd: qtd[mes] }));
+  }
+
   /* ---- descrição do gasto: sugestões e repetido (formulário do gasto) ---- */
   /* Descrição comparável: sem acento, em minúsculas, aparada e com os espaços do meio juntados. */
   function normalizaDescricao(s){
@@ -506,7 +516,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -2
node tests/browser/dentro-da-obra.cjs && node tests/browser/xss.cjs && node tests/browser/mobile.cjs
```
Expected: `ℹ pass 385` e `ℹ fail 0`; `✔ Test run with 206 tests in 35 suites passed`; `ok - dentro da obra: afazeres e filtro de mês` e as outras duas sem erro.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift \
  app.js \
  calc.js \
  scripts/vetores-calc.mjs \
  tests/browser/dentro-da-obra.cjs \
  tests/vetores/calc.json
git commit -m "fix: mês escolhido no filtro não some quando sai o último gasto dele" -m "Com um mês escolhido no filtro dos lançamentos, apagar o último gasto dele (ou mudar a data para outro mês) tirava o mês do seletor, que passava a mostrar \"Todos os meses\" enquanto a lista continuava filtrada por ele, com \"Nada encontrado com esse filtro.\" e o contador em zero. A lista de meses sai do app.js para o calc.js, com quantos gastos cada mês tem, e passa a incluir o mês escolhido mesmo sem gasto: o seletor continua mostrando o filtro que vale, e a pessoa pode tirá-lo. O app nativo usa a mesma regra no menu do mês."
```

### Task 7: Contador dos lançamentos no calc.js e busca com o texto aparado

O contador da pílula "Lançamentos" (nada sem gasto, o total, ou "achados/total" com busca ou mês) sai do `app.js` para o `calc.js`. Com o alinhamento aprovado (achado 16), a busca apara o texto: um espaço no começo ou no fim já não esconde o gasto, e uma busca só de espaços não filtra. O aparar mora dentro do `filtraGastos`, depois do `semAcento` (um acento solto antes do espaço sai antes de aparar), e não num `trim()` da cola, como o spec descrevia: fica uma regra só, nos vetores, e o campo da busca continua mostrando o que a pessoa digitou. O `renderGastosFiltrados` monta o filtro uma vez e passa para os dois.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/dentro-da-obra.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Produces: `OBRA_CALC.contadorLancamentos(total, achados, filtro)` → `''`, `'N'` ou `'achados/total'` (filtrando é texto sem acento e aparado não vazio, ou mês). Em Swift: `contadorLancamentos(total:achados:filtro:)`. Muda: `filtraGastos`, no `calc.js` e no `Listas.swift`.

- [ ] **Step 1: Escrever os vetores, os leitores em Swift e o passo da busca no browser**

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift
@@ -41,6 +41,13 @@ struct ListasTests {
         }
     }
 
+    @Test func contadorDaPilula() {
+        for c in Vetores.casos("calc.contadorLancamentos") {
+            let f = c.args[2].comoObjeto.map { FiltroGastos(texto: $0["texto"]?.comoTexto, mes: $0["mes"]?.comoTexto) }
+            confere(.texto(contadorLancamentos(total: Int(c.args[0].numero), achados: Int(c.args[1].numero), filtro: f)), c.saida, .exata, c.caso)
+        }
+    }
+
     @Test func filtroDosLancamentos() {
         for c in Vetores.casos("calc.filtraGastos") {
             let topicos = (c.args[1].comoObjeto ?? [:]).mapValues { t in
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -268,6 +268,24 @@ filtra('texto e mês', O1.gastos, TOPICOS_MAPA, { texto: 'tinta', mes: '2025-08'
 filtra('tópico próprio pelo nome', O4.gastos, TOPICOS_MAPA, { texto: 'automacao' });
 filtra('tópico apagado busca pelo id', [{ id: 'k', valor: 1, topico: 'c_sumiu', descricao: '', data: '2026-01-01' }], TOPICOS_MAPA, { texto: 'c_sum' });
 filtra('nada encontrado', O1.gastos, TOPICOS_MAPA, { texto: 'xyz' });
+filtra('texto aparado', O1.gastos, TOPICOS_MAPA, { texto: '  tinta  ' });
+filtra('tab e quebra nas pontas', O1.gastos, TOPICOS_MAPA, { texto: '\ttinta\n' });
+filtra('só espaços não filtra', O1.gastos, TOPICOS_MAPA, { texto: '   ' });
+filtra('espaço duplo no meio não vira um', O1.gastos, TOPICOS_MAPA, { texto: 'e  c' });
+filtra('acento solto antes do espaço sai antes de aparar', [{ id: 'k1', valor: 1, topico: 'outros', descricao: 'Conexões', data: '2026-01-01' }],
+  TOPICOS_MAPA, { texto: '\u0301 conexoes' });
+/* O contador da pílula "Lançamentos" (app.js renderGastosFiltrados). */
+const contadorLanc = calc('contadorLancamentos');
+contadorLanc('sem gasto', 0, 0, null);
+contadorLanc('sem gasto, com busca', 0, 0, { texto: 'tinta' });
+contadorLanc('sem filtro: o total', 7, 7, null);
+contadorLanc('sem filtro vale o total, nunca os achados', 7, 5, null);
+contadorLanc('com busca: achados/total', 7, 1, { texto: 'tinta', mes: '' });
+contadorLanc('busca só de espaços não filtra', 7, 7, { texto: '   ', mes: '' });
+contadorLanc('só o mês', 7, 0, { texto: '', mes: '2025-08' });
+contadorLanc('busca e mês', 7, 2, { texto: 'tinta', mes: '2025-08' });
+contadorLanc('busca só de acento solto não filtra', 7, 7, { texto: '\u0301' });
+contadorLanc('milhares sem ponto', 1234, 1000, { texto: 'a' });
 /* Os meses do filtro (app.js renderObra), com quantos gastos cada um tem. O mês escolhido nunca some da lista. */
 const mesesFiltro = calc('mesesDoFiltro');
 mesesFiltro('do mais novo ao mais antigo, com os futuros', O1.gastos, '');
```

Em `tests/browser/dentro-da-obra.cjs`:

```diff
--- a/tests/browser/dentro-da-obra.cjs
+++ b/tests/browser/dentro-da-obra.cjs
@@ -1,4 +1,5 @@
-/* Dentro da obra com dados sintéticos: afazeres (o que grava, a ordem e o contador) e o filtro dos lançamentos. Sem contas nem rede.
+/* Dentro da obra com dados sintéticos: afazeres (o que grava, a ordem e o contador), o filtro de mês e a busca dos lançamentos.
+   Sem contas nem rede.
    Precisa de `node tests/browser/servidor.cjs` no ar (porta 8123). O duplê do CLOUD guarda cada blob gravado em `salvos`:
    o teste confere o que foi para a nuvem, não só o `db` da página. */
 const assert=require('node:assert/strict');
@@ -113,8 +114,18 @@ const OBRA_FILTRO={id:'f',nome:'Sobrado Centro',dataInicio:'2026-01-10',afazeres
     await page.evaluate(()=>renderAll());
     assert.deepEqual(await meses(),[['','Todos os meses'],['2026-02','fev/26']]);
 
+    // Busca aparada (achado 16): espaço nas pontas não esconde o gasto, e busca só de espaços não filtra
+    const linhasDaLista=()=>page.locator('#oGastos li.gasto-row').count();
+    await page.locator('#fBusca').fill('  tomadas  ');
+    assert.equal(await lancamentos(),'1/2');
+    assert.equal(await linhasDaLista(),1);
+    await page.locator('#fBusca').fill('   ');
+    assert.equal(await lancamentos(),'2');
+    assert.equal(await linhasDaLista(),2);
+    await page.locator('#fBusca').fill('');
+
     assert.deepEqual(await page.evaluate(()=>errosObra),[]);
     await ctx.close();
-    console.log('ok - dentro da obra: afazeres e filtro de mês');
+    console.log('ok - dentro da obra: afazeres, filtro de mês e busca');
   }finally{await browser.close();}
 })().catch(e=>{console.error(e);process.exitCode=1;});
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | grep -m3 error:
node tests/browser/dentro-da-obra.cjs
```
Expected: `TypeError: fn is not a function` (`contadorLancamentos`); `error: cannot find 'contadorLancamentos' in scope`; o browser para com `AssertionError [ERR_ASSERTION]: Expected values to be strictly equal:` e `'0/2' !== '1/2'` (a busca "  tomadas  " não acha nada no site de hoje).

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift
@@ -60,6 +60,13 @@ func contem(_ texto: String, _ trecho: String) -> Bool {
     return false
 }
 
+/// `contadorLancamentos` do calc.js: nada sem gasto; o total; ou "achados/total" com busca ou mês (busca só de espaços não filtra).
+public func contadorLancamentos(total: Int, achados: Int, filtro: FiltroGastos?) -> String {
+    if total == 0 { return "" }
+    let filtrando = !aparadoJS(semAcento(filtro?.texto)).isEmpty || !(filtro?.mes ?? "").isEmpty
+    return filtrando ? "\(achados)/\(total)" : "\(total)"
+}
+
 public struct MesDoFiltro: Equatable, Sendable {
     /// AAAA-MM.
     public let mes: String
@@ -81,9 +88,9 @@ public struct FiltroGastos: Equatable, Sendable {
     public init(texto: String? = nil, mes: String? = nil) { self.texto = texto; self.mes = mes }
 }
 
-/// `filtraGastos` do calc.js: texto na descrição ou no nome do tópico (sem acento) e mês AAAA-MM, em E.
+/// `filtraGastos` do calc.js: texto aparado na descrição ou no nome do tópico (sem acento) e mês AAAA-MM, em E.
 public func filtraGastos(_ gastos: [Gasto], topicos: [String: Topico], filtro: FiltroGastos?) -> [Gasto] {
-    let texto = semAcento(filtro?.texto)
+    let texto = aparadoJS(semAcento(filtro?.texto))
     let mes = filtro?.mes ?? ""
     return gastos.filter { g in
         if !mes.isEmpty && String(g.data.prefix(7)) != mes { return false }
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -708,9 +708,9 @@ function bindMesChart(o, suf = ''){
 function renderGastosFiltrados(o){
   if(!o) return;
   const list = $('#oGastos');
-  const filtrados = OBRA_CALC.filtraGastos(o.gastos, TOP_MAP(), { texto: filtroTexto, mes: filtroMes });
-  const filtrando = !!(filtroTexto || filtroMes);
-  $('#lanCount').textContent = o.gastos.length ? (filtrando ? `${filtrados.length}/${o.gastos.length}` : o.gastos.length) : '';
+  const filtro = { texto: filtroTexto, mes: filtroMes };
+  const filtrados = OBRA_CALC.filtraGastos(o.gastos, TOP_MAP(), filtro);
+  $('#lanCount').textContent = OBRA_CALC.contadorLancamentos(o.gastos.length, filtrados.length, filtro);
   list.innerHTML = '';
   if(!o.gastos.length){ list.innerHTML = emptyBlock(ICON('recibo'),'Nenhum gasto lançado.<br>Toque no + pra lançar o primeiro.'); return; }
   if(!filtrados.length){ list.innerHTML = emptyBlock(ICON('recibo'),'Nada encontrado com esse filtro.'); return; }
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -220,13 +220,13 @@
     return (valor > 0 && areaM2 > 0) ? valor / areaM2 : null;
   }
 
-  /* Busca dos lançamentos: texto (descrição OU nome do tópico, sem acento)
+  /* Busca dos lançamentos: texto aparado (descrição OU nome do tópico, sem acento)
      e/ou mês ('2026-06'). Filtros combinam em E. */
   function semAcento(s){
     return (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
   }
   function filtraGastos(gastos, topicosMap, f){
-    const texto = semAcento(f && f.texto);
+    const texto = semAcento(f && f.texto).trim();
     const mes = (f && f.mes) || '';
     return gastos.filter(g => {
       if(mes && g.data.slice(0, 7) !== mes) return false;
@@ -237,6 +237,12 @@
     });
   }
 
+  /* Contador da pílula "Lançamentos": nada sem gasto; o total; ou "achados/total" com busca ou mês (busca só de espaços não filtra). */
+  function contadorLancamentos(total, achados, filtro){
+    if(!total) return '';
+    const filtrando = semAcento(filtro && filtro.texto).trim() || (filtro && filtro.mes);
+    return filtrando ? `${achados}/${total}` : String(total);
+  }
   /* Meses do filtro dos lançamentos: os que têm gasto, do mais novo ao mais antigo (com os futuros), e quantos gastos cada um
      tem. O mês escolhido entra mesmo sem gasto (com zero): apagar o último gasto dele, ou mudar a data, não esconde o filtro que
      continua valendo. */
@@ -516,7 +522,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -2
node tests/browser/dentro-da-obra.cjs && node tests/browser/xss.cjs && node tests/browser/mobile.cjs
```
Expected: `ℹ pass 385` e `ℹ fail 0`; `✔ Test run with 207 tests in 35 suites passed`; `ok - dentro da obra: afazeres, filtro de mês e busca` e as outras duas sem erro.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift \
  app.js \
  calc.js \
  scripts/vetores-calc.mjs \
  tests/browser/dentro-da-obra.cjs \
  tests/vetores/calc.json
git commit -m "feat: contador dos lançamentos no calc.js e busca com o texto aparado" -m "O contador da pílula \"Lançamentos\" (nada sem gasto, o total ou achados/total com busca ou mês) sai do app.js para o calc.js e entra nos vetores. A busca passa a aparar o texto antes de filtrar: um espaço no começo ou no fim já não esconde o gasto, e uma busca só de espaços não filtra. O app nativo busca e conta igual pela cópia em Swift."
```

### Task 8: Resumo da folha do tópico no calc.js

O resumo da folha do tópico (quantos gastos, o bruto com as parcelas a vencer, o corrigido até a venda ou hoje e o "% da obra" com o arredondamento da legenda do donut) sai do `app.js` para o `calc.js`, que já tinha o fim da correção que o `app.js` copiava à mão. O texto "N gasto(s) · P% da obra" fica no `app.js`: o app escreve o dele, com teste próprio. De carona, o comentário trocado (achado 9) volta para cima do `sheetTopico`, e o `sheetAPagar` ganha o seu. O caso de 1 gasto em 8 (12,5% → 13) prende o arredondamento.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Correcao.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CorrecaoTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/orcamento.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `fimCorrecao` (interno), `totalBruto` e `corrigido`; no núcleo, `fimCorrecao`, `totalBruto`, `corrigido` e `arredondarJS`.
- Produces: `OBRA_CALC.resumoTopico(obra, topicoId, hojeISO, taxaMensal)` → `{qtd, bruto, corrigido, pct}`. Em Swift: `ResumoDoTopico` e `resumoTopico(_:topico:hoje:taxaMensal:)`, em `Correcao.swift`, com o `totalCorrigido`.

- [ ] **Step 1: Escrever os vetores, os leitores em Swift e as guardas do browser**

As três asserções novas do `orcamento.cjs` no resumo da Fundação ("1 gasto · 16% da obra", "R$ 98.000,00" e o corrigido calculado na página) passam antes também: prendem a cola.

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CorrecaoTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CorrecaoTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CorrecaoTests.swift
@@ -22,6 +22,14 @@ struct CorrecaoTests {
         }
     }
 
+    @Test func resumoDoTopico() {
+        for c in Vetores.casos("calc.resumoTopico") {
+            let r = resumoTopico(c.args[0].obra, topico: c.args[1].comoTexto!, hoje: c.args[2].comoTexto!, taxaMensal: c.args[3].numero)
+            confere(.objeto(["qtd": .numero(Double(r.qtd)), "bruto": .numero(r.bruto), "corrigido": .numero(r.corrigido), "pct": .numero(r.pct)]),
+                    c.saida, .dinheiro, c.caso)
+        }
+    }
+
     @Test func lucroNaVenda() {
         for c in Vetores.casos("calc.lucroVenda") {
             confere(lucroVenda(c.args[0].obra, taxa: c.args[1].numero)?.json ?? .nulo, c.saida, .dinheiro, c.caso)
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -186,6 +186,18 @@ for(const o of BLOB.obras) bruto(o.nome, o);
 const totalCorr = calc('totalCorrigido');
 for(const o of BLOB.obras) for(const taxa of [1, 0.85, 20]) totalCorr(`${o.nome} a ${taxa}%`, o, taxa, HOJE);
 totalCorr('vendida corrige até a venda, mesmo com outro hoje', O2, 1, '2030-01-01');
+/* O resumo da folha do tópico (app.js sheetTopico). */
+const resumoTop = calc('resumoTopico');
+resumoTop('parcelas a vencer contam no bruto', O1, 'eletrica', HOJE, 1);
+resumoTop('um gasto só', O1, 'fundacao', HOJE, 1);
+resumoTop('vendida corrige até a venda', O2, 'alvenaria', '2030-01-01', 1);
+resumoTop('tópico sem gasto', O1, 'telhado', HOJE, 1);
+resumoTop('obra sem gasto', O3, 'pintura', HOJE, 1);
+resumoTop('taxa zero: corrigido igual ao bruto', O1, 'estrutura', HOJE, 0);
+resumoTop('tópico próprio', O4, 'c_mgf1abcd', HOJE, 1);
+resumoTop('meio ponto arredonda para cima, como o donut', { id: 'r', dataInicio: '2026-01-01', gastos: [
+  { id: 'r1', valor: 1, topico: 'pintura', descricao: '', data: '2026-01-01', pagamento: 'pix' },
+  { id: 'r2', valor: 7, topico: 'eletrica', descricao: '', data: '2026-01-01', pagamento: 'pix' }] }, 'pintura', HOJE, 1);
 const lucro = calc('lucroVenda');
 for(const o of BLOB.obras) lucro(o.nome, o, 1);
 lucro('gasto depois da venda entra pelo valor', O2, 2);
```

Em `tests/browser/orcamento.cjs`:

```diff
--- a/tests/browser/orcamento.cjs
+++ b/tests/browser/orcamento.cjs
@@ -78,6 +78,11 @@ async function abrir(browser,{tema='escuro',skin='esmeralda',width=393}={}){
     // tocar no tópico abre a folha do tópico que já existe
     await item('Fundação').click();
     assert.match(await page.locator('#sheet').textContent(),/Fundação/);
+    // o resumo do tópico: bruto, corrigido até hoje e o % da obra arredondado (98 mil de 624 mil = 15,7%)
+    assert.equal((await page.locator('#sheet .top-resumo .sub').textContent()).trim(),'1 gasto · 16% da obra');
+    assert.equal((await page.locator('#sheet .top-resumo b').textContent()).replace(/\s/g,' '),'R$ 98.000,00');
+    assert.equal(await page.locator('#sheet .top-resumo .corr').textContent(),
+      await page.evaluate(()=>`corrigido: ${OBRA_CALC.money(OBRA_CALC.corrigido(98000,'2026-03-01',OBRA_CALC.dataLocalISO(),1))}`));
     await page.evaluate(()=>closeSheet());
 
     // Obra com orçamento total estourado
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | grep -m3 error:
```
Expected: `TypeError: fn is not a function`; `error: cannot find 'resumoTopico' in scope`.

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Correcao.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Correcao.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Correcao.swift
@@ -29,6 +29,26 @@ public func totalCorrigido(_ obra: Obra, taxa: Double, hoje: String) -> Double {
     return obra.gastos.reduce(0) { $0 + corrigido($1.valor, de: $1.data, ate: fim, taxa: taxa) }
 }
 
+public struct ResumoDoTopico: Equatable, Sendable {
+    public let qtd: Int
+    /// Com as parcelas a vencer.
+    public let bruto: Double
+    /// Até a venda ou hoje.
+    public let corrigido: Double
+    /// Inteiro (o arredondamento da legenda do donut), guardado como Double; 0 na obra sem gasto.
+    public let pct: Double
+}
+
+/// `resumoTopico` do calc.js: o resumo da folha do tópico.
+public func resumoTopico(_ obra: Obra, topico: String, hoje: String, taxaMensal: Double) -> ResumoDoTopico {
+    let gs = obra.gastos.filter { $0.topico == topico }
+    let fim = fimCorrecao(obra, hoje: hoje)
+    let bruto = gs.reduce(0) { $0 + $1.valor }
+    let total = totalBruto(obra)
+    return ResumoDoTopico(qtd: gs.count, bruto: bruto, corrigido: gs.reduce(0) { $0 + corrigido($1.valor, de: $1.data, ate: fim, taxa: taxaMensal) },
+                          pct: total > 0 ? arredondarJS(bruto / total * 100) : 0)
+}
+
 public struct LucroVenda: Equatable, Sendable {
     public let bruto: Double
     public let vsBanco: Double
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -1107,8 +1107,8 @@ function renderGraficos(){
   ligarImprimir($('#grafPrint'));
 }
 
-/* Folha com só os gastos de um tópico — o "de onde saiu esse pedaço do donut".
-   Só leitura sobre db; editar/excluir sai daqui pelo próprio gastoRow. */
+/* Folha do "A pagar": os vencimentos dos próximos 30 dias (calc.js aPagar). Editar e
+   excluir saem daqui pelo próprio gastoRow e voltam para ela. */
 function sheetAPagar(obraId){
   const o = obraById(obraId);
   if(!o){ closeSheet(); return; }
@@ -1123,6 +1123,8 @@ function sheetAPagar(obraId){
   $('#aPagarFechar').onclick = closeSheet;
 }
 
+/* Folha com só os gastos de um tópico — o "de onde saiu esse pedaço do donut".
+   Só leitura sobre db; editar/excluir sai daqui pelo próprio gastoRow. */
 function sheetTopico(obraId, topicoId){
   const o = obraById(obraId);
   if(!o) return;
@@ -1130,21 +1132,15 @@ function sheetTopico(obraId, topicoId){
   if(!gs.length){ closeSheet(); return; } // último gasto do tópico foi excluído
 
   const t = TOP_MAP()[topicoId] || {nm:topicoId, ic:'etiqueta'};
-  const hoje = todayISO();
-  const fim = (o.venda && o.venda.data) || hoje;
-  const tx = taxa();
-  const bruto = gs.reduce((s,g)=>s+g.valor, 0);
-  const corr  = gs.reduce((s,g)=>s+OBRA_CALC.corrigido(g.valor, g.data, fim, tx), 0);
-  const totalObra = OBRA_CALC.totalBruto(o);
-  // mesmo arredondamento da legenda do donut, senão o número muda ao abrir
-  const pct = totalObra > 0 ? Math.round(bruto/totalObra*100) : 0;
+  // o % usa o arredondamento da legenda do donut, senão o número muda ao abrir
+  const r = OBRA_CALC.resumoTopico(o, topicoId, todayISO(), taxa());
 
   openSheet(`
     <div class="top-head">${ICON(t.ic)}<h3>${escapeHtml(t.nm)}</h3></div>
     <div class="top-resumo">
-      <div class="sub">${gs.length} gasto${gs.length>1?'s':''} · ${pct}% da obra</div>
-      <b>${money(bruto)}</b>
-      <div class="corr">corrigido: ${money(corr)}</div>
+      <div class="sub">${r.qtd} gasto${r.qtd>1?'s':''} · ${r.pct}% da obra</div>
+      <b>${money(r.bruto)}</b>
+      <div class="corr">corrigido: ${money(r.corrigido)}</div>
     </div>
     <ul class="list" id="topGastos"></ul>
     <div class="sheet-actions"><button class="btn ghost" id="topFechar">Fechar</button></div>`);
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -77,6 +77,16 @@
     const fim = fimCorrecao(obra, hojeISO);
     return obra.gastos.reduce((s, g) => s + corrigido(g.valor, g.data, fim, taxaPct), 0);
   }
+  /* Resumo da folha do tópico: quantos gastos, o bruto (com as parcelas a vencer), o corrigido até a venda ou hoje e o "% da
+     obra" com o arredondamento da legenda do donut (0 na obra sem gasto). */
+  function resumoTopico(obra, topicoId, hojeISO, taxaPct){
+    const gs = obra.gastos.filter(g => g.topico === topicoId);
+    const fim = fimCorrecao(obra, hojeISO);
+    const bruto = gs.reduce((s, g) => s + g.valor, 0);
+    const total = totalBruto(obra);
+    return { qtd: gs.length, bruto, corrigido: gs.reduce((s, g) => s + corrigido(g.valor, g.data, fim, taxaPct), 0),
+      pct: total > 0 ? Math.round(bruto / total * 100) : 0 };
+  }
   function lucroVenda(obra, taxaPct){
     if(!obra.venda) return null;
     return {
@@ -522,7 +532,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -2
node tests/browser/orcamento.cjs && node tests/browser/xss.cjs
```
Expected: `ℹ pass 385` e `ℹ fail 0`; `✔ Test run with 208 tests in 35 suites passed`; as duas suítes terminam sem erro.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Correcao.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CorrecaoTests.swift \
  app.js \
  calc.js \
  scripts/vetores-calc.mjs \
  tests/browser/orcamento.cjs \
  tests/vetores/calc.json
git commit -m "feat: resumo da folha do tópico no calc.js" -m "O resumo da folha do tópico (quantos gastos, o bruto com as parcelas a vencer, o corrigido até a venda ou hoje e o \"% da obra\" com o arredondamento do donut) sai do app.js para o calc.js, que já tinha o fim da correção que o app.js copiava à mão, e entra nos vetores. O comentário da folha do tópico, que estava em cima da folha do A pagar, volta para o lugar. O app nativo resume igual pela cópia em Swift."
```

### Task 9: Subtítulo da folha do A pagar no calc.js

O "{N} vencimentos · a partir de amanhã" da folha do A pagar, com o singular no um e o plural no zero, sai do `app.js` para o `calc.js`, sem mudar o site (a décima regra, aprovada em 18/10). A etiqueta do indicador no app (`ObraNaTela.swift`, "nada em 30 dias" no zero) não muda.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/dentro-da-obra.cjs`
- Test (alterar): `tests/browser/mobile.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Produces: `OBRA_CALC.textoVencimentos(qtd)`. Em Swift: `textoVencimentos(_:)`.

- [ ] **Step 1: Escrever os vetores, os leitores em Swift e as guardas do browser**

As duas asserções de browser (o "1 vencimento" do `mobile.cjs` e, no `dentro-da-obra.cjs`, o A pagar vazio com "0 vencimentos" e "Nenhum gasto previsto para esse período.") passam antes também.

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift
@@ -21,6 +21,12 @@ struct ListasTests {
         }
     }
 
+    @Test func subtituloDaFolhaDoAPagar() {
+        for c in Vetores.casos("calc.textoVencimentos") {
+            confere(.texto(textoVencimentos(Int(c.args[0].numero))), c.saida, .exata, c.caso)
+        }
+    }
+
     @Test func recentes() {
         for c in Vetores.casos("calc.gastosRecentes") {
             let r = c.args.count > 1 ? gastosRecentes(c.args[0].obras, n: Int(c.args[1].numero)) : gastosRecentes(c.args[0].obras)
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -262,6 +262,8 @@ apagar('mesmo dia não entra', [{ id: 'z', gastos: [{ id: 'z1', valor: 100, data
 apagar('empate de data mantém a ordem das obras', [
   { id: 'p', gastos: [{ id: 'p1', valor: 1, data: '2026-07-10' }] },
   { id: 'q', gastos: [{ id: 'q1', valor: 2, data: '2026-07-10' }, { id: 'q2', valor: 3, data: '2026-07-08' }] }], '2026-07-06', 30);
+const vencimentos = calc('textoVencimentos');
+for(const n of [0, 1, 2, 31, 1000]) vencimentos(String(n), n);
 const recentes = calc('gastosRecentes');
 recentes('cinco mais recentes', BLOB.obras, 5);
 recentes('padrão', BLOB.obras);
```

Em `tests/browser/dentro-da-obra.cjs`:

```diff
--- a/tests/browser/dentro-da-obra.cjs
+++ b/tests/browser/dentro-da-obra.cjs
@@ -1,5 +1,5 @@
-/* Dentro da obra com dados sintéticos: afazeres (o que grava, a ordem e o contador), o filtro de mês e a busca dos lançamentos.
-   Sem contas nem rede.
+/* Dentro da obra com dados sintéticos: afazeres (o que grava, a ordem e o contador), o filtro de mês e a busca dos lançamentos,
+   e o A pagar vazio. Sem contas nem rede.
    Precisa de `node tests/browser/servidor.cjs` no ar (porta 8123). O duplê do CLOUD guarda cada blob gravado em `salvos`:
    o teste confere o que foi para a nuvem, não só o `db` da página. */
 const assert=require('node:assert/strict');
@@ -124,8 +124,14 @@ const OBRA_FILTRO={id:'f',nome:'Sobrado Centro',dataInicio:'2026-01-10',afazeres
     assert.equal(await linhasDaLista(),2);
     await page.locator('#fBusca').fill('');
 
+    // A pagar vazio: abre com "0 vencimentos" e a frase do site
+    await page.locator('#oAPagar').click();
+    assert.equal((await page.locator('#sheet .top-resumo .sub').textContent()).trim(),'0 vencimentos · a partir de amanhã');
+    assert.match(await page.locator('#sheet').textContent(),/Nenhum gasto previsto para esse período\./);
+    await page.locator('#aPagarFechar').click();
+
     assert.deepEqual(await page.evaluate(()=>errosObra),[]);
     await ctx.close();
-    console.log('ok - dentro da obra: afazeres, filtro de mês e busca');
+    console.log('ok - dentro da obra: afazeres, filtro de mês, busca e A pagar vazio');
   }finally{await browser.close();}
 })().catch(e=>{console.error(e);process.exitCode=1;});
```

Em `tests/browser/mobile.cjs`:

```diff
--- a/tests/browser/mobile.cjs
+++ b/tests/browser/mobile.cjs
@@ -29,6 +29,7 @@ const {chromium}=require('playwright');
     });
     await page.locator('#oAPagar').click();
     assert.equal(await page.locator('#aPagarGastos .gasto-row').count(),1);
+    assert.equal((await page.locator('#sheet .top-resumo .sub').textContent()).trim(),'1 vencimento · a partir de amanhã');
     await page.locator('#aPagarGastos .li-main').click();
     await page.locator('#fDesc').fill('Cimento editado');
     await page.locator('#cSave').click();
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | grep -m3 error:
```
Expected: `TypeError: fn is not a function`; `error: cannot find 'textoVencimentos' in scope`.

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift
@@ -26,6 +26,9 @@ public func aPagar(_ obras: [Obra], hoje: String, dias: Int = 30) -> APagar {
     return APagar(total: total, qtd: qtd, itens: ordenadoEstavel(itens) { menorJS($0.gasto.data, $1.gasto.data) })
 }
 
+/// `textoVencimentos` do calc.js: o subtítulo da folha do "A pagar" ("0 vencimentos" também: a folha abre vazia).
+public func textoVencimentos(_ qtd: Int) -> String { "\(qtd) vencimento\(qtd == 1 ? "" : "s") · a partir de amanhã" }
+
 public struct GastoRecente: Equatable, Sendable {
     public let obraId: String
     public let obraNome: String
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -1115,7 +1115,7 @@ function sheetAPagar(obraId){
   const venc = OBRA_CALC.aPagar([o], todayISO());
   openSheet(`<h3>A pagar · próximos 30 dias</h3>
     <div class="top-resumo"><b>${money(venc.total)}</b>
-      <div class="sub">${venc.qtd} vencimento${venc.qtd===1?'':'s'} · a partir de amanhã</div></div>
+      <div class="sub">${OBRA_CALC.textoVencimentos(venc.qtd)}</div></div>
     <ul class="list" id="aPagarGastos"></ul>
     ${venc.qtd?'': '<p class="muted-note">Nenhum gasto previsto para esse período.</p>'}
     <div class="sheet-actions"><button class="btn ghost" id="aPagarFechar">Fechar</button></div>`);
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -218,6 +218,9 @@
     return { total, qtd, itens };
   }
 
+  /* Subtítulo da folha do "A pagar" (zero também: a folha abre vazia). */
+  const textoVencimentos = qtd => `${qtd} vencimento${qtd === 1 ? '' : 's'} · a partir de amanhã`;
+
   /* Últimos n gastos de todas as obras (data desc, desempate por id). */
   function gastosRecentes(obras, n = 5){
     return obras
@@ -532,7 +535,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -2
node tests/browser/dentro-da-obra.cjs && node tests/browser/mobile.cjs && node tests/browser/xss.cjs
```
Expected: `ℹ pass 385` e `ℹ fail 0`; `✔ Test run with 209 tests in 35 suites passed`; as três suítes terminam sem erro.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Listas.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ListasTests.swift \
  app.js \
  calc.js \
  scripts/vetores-calc.mjs \
  tests/browser/dentro-da-obra.cjs \
  tests/browser/mobile.cjs \
  tests/vetores/calc.json
git commit -m "feat: subtítulo da folha do A pagar no calc.js" -m "O \"{N} vencimentos · a partir de amanhã\" da folha do A pagar, com o singular no um e o plural no zero, sai do app.js para o calc.js, sem mudar o site, e entra nos vetores. O app nativo escreve o mesmo subtítulo pela cópia em Swift; a etiqueta do indicador continua a dele (\"nada em 30 dias\" no zero)."
```

### Task 10: Nova versão do cache offline

**Files:**
- Modify: `sw.js`

- [ ] **Step 1: Subir o `CACHE`**

Nenhum arquivo novo na raiz: o `ASSETS` não muda.

Em `sw.js`:

```diff
--- a/sw.js
+++ b/sw.js
@@ -1,6 +1,6 @@
 /* Service worker — network-first. Online sempre pega a versão nova; o cache
    é só o retrato pra funcionar offline. Bump CACHE ao mudar arquivos. */
-const CACHE = 'obras-v68';
+const CACHE = 'obras-v69';
 const ASSETS = ['./vendor/sentry/sentry.js', './sentry-config.js', './sentry.js', './vendor/firebase/firebase-app.js', './vendor/firebase/firebase-auth.js', './vendor/firebase/firebase-firestore.js', './vendor/firebase/shared-VONABDH2.js', './styles.css', './privacidade.css', './dados.js', './cadastro.js', './', './index.html', './app.js', './gestos.js', './push.js', './share.js', './ui-confirm.js', './privacidade.html', './auth.js', './globe.js', './calc.js', './cloud.js', './icons.js', './splash.js', './splash-pre.js', './teclado.js', './tema.js', './nativo.js', './pwa.js', './manifest.json', './apple-touch-icon.png', './icon-192.png', './icon-512.png', './favicon.svg', './google-g.svg', './fontes/hanken-grotesk-800.woff2'];
 
 self.addEventListener('install', e => {
```

- [ ] **Step 2: Ver passar e conferir o PR inteiro**

Run:
```bash
npm run test:unit 2>&1 | tail -4
npm run test:browser 2>&1 | grep -c '^not ok'
```
Expected: `ℹ pass 385` e `ℹ fail 0`; `0` linhas `not ok` na rodada inteira de browser, com os emuladores (a suíte nova `dentro-da-obra.cjs` inclusive).

- [ ] **Step 3: Commit**

```bash
git add sw.js
git commit -m "chore: nova versão do cache offline para as regras de dentro da obra" -m "O app.js, o calc.js e o dados.js mudaram: aparelhos com o site instalado baixam a versão nova em vez de continuar com a guardada."
```

**Ponto de controle do PR 0:** na prévia da Vercel, numa obra com orçamento por tópico, ver o cartão, a lista com "Passou…", "Faltam…" e "Chegou…" e a linha "gasto / previsto"; editar o orçamento de uma obra cujo documento tem um campo desconhecido dentro de `orcamento` e ver que ele fica; trocar para "Só o total" e ver a soma preenchida; marcar e desmarcar afazeres (o recém-marcado no alto dos feitos, o desmarcado no alto dos pendentes); escolher um mês no filtro e apagar o último gasto dele (o mês continua no seletor, com "0/N"); buscar com espaço nas pontas; abrir o A pagar vazio. O Forja começa o PR 1 quando este PR entra em revisão.

---

## PRs do app

Cada PR do app nasce num worktree novo a partir da `origin/main` atualizada, entrega um bloco inteiro da etapa gravando de verdade e gera um build no TestFlight depois do merge, só com o OK do Giovani. As tarefas têm a forma das da etapa 2: os testes primeiro, o "ver falhar" com a saída real, a implementação, o "ver passar" e o commit. O código saiu dos protótipos, fatiado num commit por tarefa sobre a `origin/main` de 21/10 (`9eda0ab`: o PR 0, com os menores da revisão, e o Custta só com a pele esmeralda) e conferido fatia a fatia: o "ver falhar" de cada uma (os testes dela sobre o commit anterior), Node, núcleo e compilação sem aviso; no fim de cada PR, os testes de tela, o laudo, as auditorias e a conferência cruzada.

O núcleo de cada PR entra no começo dele e só com o que as telas daquele PR usam: no PR 1, o orçamento; no PR 2, o A pagar e o detalhe do tópico; no PR 3, os afazeres e a busca (decisão 3: uma mutação nova por build).

Os comandos rodam na raiz do worktree, cada agente no seu simulador:

```bash
export CUSTTA_SIMULADOR=<udid do seu simulador>          # nunca o de outro agente
DESTINO=$(node scripts/simulador-ios.mjs)
XB=(-project app-ios/Custta.xcodeproj -scheme Custta -destination "$DESTINO"
    -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile)
# compilar uma vez por mudança e rodar só o que interessa
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | tail -5
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:<alvo> 2>&1 | tail -5
# núcleo
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter <suíte> 2>&1 | tail -3
```


## Decisões do conselho

Conselho de 19 e 20/10: três subagentes Opus novos, sem o contexto do planejador, cada um com uma lente (desempenho e bateria; acessibilidade e legibilidade; fidelidade ao mockup, à HIG e ao spec), propostas às cegas, crítica cruzada sem saber quem fez qual, o Prumo como presidente. Antes, dois protótipos de medida no simulador (iOS 27): as três formas da volta à folha de origem e as duas formas das teclas encaixadas, com 71 linhas. As três propostas escolheram o mesmo caminho nas decisões 1 e 2; o presidente ficou com a mais completa em cada uma (a de fidelidade, primeira nas três críticas da decisão 1 e em duas da decisão 2) e absorveu as correções das outras; na decisão 3, com a de desempenho (primeira em duas críticas, segunda na outra). A nota "Conselho — dentro da obra (etapa 3)" do Maestri guarda as propostas, as críticas e os rankings.

| Decisão | Escolha | Descartadas | Por quê |
| --- | --- | --- | --- |
| Volta à folha de origem | A edição como passo empurrado no `NavigationStack` da própria folha de origem (A pagar e tópico), com o `PassoDosDetalhes` da etapa 2 e a saída dele injetada (`SaidaDaEdicao`: `.folha`, a de hoje, intocada; `.origem`, que volta e acende ou apaga na origem) | Segunda `.sheet` sobre a de origem; troca do `Folhas.Qual` guardando a origem (como o site); `List` com `.swipeActions` dentro da folha | Medido: só o passo empurrado faz o "puxar fecha tudo e pergunta" (a segunda folha desce sozinha, e fechar as duas sai em dois tempos, com a origem à vista por 150–300 ms; a troca reabre a origem no puxar, o caminho que o Giovani não escolheu) e volta na mesma rolagem com a linha acesa (645,3 → 645,3 pt), sem a obra nua de 0,2–0,3 s da troca. A `List` funciona na folha sólida, mas troca o botão e o grupo pelos do sistema, diferentes do quadro aprovado e da lista da obra |
| Teclas encaixadas na folha do orçamento | Teclas próprias no rodapé da folha, num `safeAreaInset`, com a linha ativa como estado da folha: a `GradeDeTeclas` sai do `TecladoDeValor` e serve também ao `TecladoEncaixado` novo | Um campo por tópico com o teclado próprio como `inputView` do UIKit | Medido: no iOS 27 o sistema põe o painel de vidro dele em volta do `inputView` (vidro sobre a folha), a barra do `inputAccessoryView` fica transparente e cai sobre a linha na maior letra, e o campo tocado fica sob o teclado; as teclas próprias são o quadro aprovado e abrem mais leves (155 × 214 ms até o primeiro quadro; 55 × 61 MB) |
| Corte e ordem dos PRs | O do spec: PR 1 orçamento, PR 2 detalhe do tópico e A pagar com a volta, PR 3 busca e afazeres; uma mutação nova por build; cada PR com as suas telas nos quatro combos (dois desde 21/10, sem a pele azul) e na maior letra; o job de leitura da etapa 3 já no PR 1 | A volta primeiro, nascendo no A pagar; a parte 1 e a parte 2 em dois PRs do app | A volta primeiro juntaria a parte 1 inteira (teclas, primeira mutação, tela de 100 tópicos, detalhe e a folha que desce) num build só, e a volta seria provada em dois PRs; o ganho dela, o iOS 26 cedo, sai mais barato pela prova do protótipo na CI. Dois PRs do app poriam as teclas, a volta e a primeira mutação no mesmo build |

**Críticas que pesaram.**
- Contra a proposta de desempenho: o último gasto do tópico mandado "à obra" animaria e poria o foco numa tela coberta (a `ObraView` consome todo `PedidoDeApagar` da obra, `ObraView.swift:105`, e fica sob a tela Orçamento); as teclas a 75 pt e o nome à vista na maior letra divergiam do quadro (64 pt e nome escondido).
- Contra a de acessibilidade: deixar a borda com mudança para "se o aparelho repetir" levaria ao build um defeito já medido (o arrasto pela borda virou toque em "Apagar gasto"); o visor na barra e o "9 de 71" são peças que o mockup não tem.
- Contra a de fidelidade: o foco do VoiceOver cobria só o "Salvar" e o "apagar" (faltavam a linha que sai da lista, o chevron e o Z sem salvar, o A pagar que fica vazio), o "Não salvou" não esperava outro alerta sair, e com ‹ › como ações da linha o foco tem de seguir a linha ativa; o grupo inteiro montado e a trava lida no body da pilha refariam a origem a cada tecla.
- Achado da crítica que nenhuma proposta tinha: a linha editada que muda de lugar na origem (manter a rolagem se ela continua à vista; se não, rolar o mínimo até ela).

**Exceções ao mockup, por recomendação, 19/10**, aprovadas pelo Giovani em 21/10 ("faça o recomendado"):

| Exceção | Por quê |
| --- | --- |
| Com mudança, a borda esquerda do passo empurrado pergunta como o chevron (`BordaQuePergunta`) | Medido: com o voltar do sistema à vista, a borda descarta a mudança calada; com o voltar escondido, ela não faz nada e o arrasto vira toque no botão de baixo. É a regra do mockup: nada se perde sem perguntar |
| O "Não salvou na nuvem" aparece dentro da folha de origem, quando nenhum outro alerta está à vista | Medido: a folha de origem fica aberta depois do "Salvar", e o alerta da raiz esperava ela fechar, com a linha acesa como se tivesse salvo |
| No "Só o total", na maior letra, a faixa das teclas mostra uma barra com só o "Pronto" | O quadro não tem barra nesse modo e tira o "Salvar" com as teclas abertas: no "Definir orçamento" na maior letra não haveria como salvar nem fechar as teclas |
| O anúncio "O gasto saiu desta lista." (só para o VoiceOver) | Quando o "Salvar" tira a linha da origem (data depois dos 30 dias, outro tópico), o foco vai para a vizinha e a pessoa precisa saber por quê |
| Dígitos e apagar pelo teclado físico na folha do orçamento (`onKeyPress`) | Sem campo de texto, o teclado físico não digitaria; não muda nada na tela. O apagar é provado por guarda Node e por um ⌫ de verdade, pelo teclado do Mac no simulador: o `typeKey` do XCUITest não entrega o apagar ao app |

**O âmbar sobre o vidro no escuro** (achado do laudo do PR 1, Tarefa 14): `#FFD98A`, decidido pelo Giovani em 21/10; a regra do laudo continua (4,5:1 para toda palavra). Descartada: aceitar 3:1 para texto grande na maior letra, o que mudaria a regra.

## PR 1 (app): o orçamento

A parte 1 do mockup sem o detalhe do tópico, gravando de verdade: a linha do orçamento nos indicadores da obra, com os três níveis e o aviso dos tópicos; a tela Orçamento; a folha "Orçamento da obra" com as teclas encaixadas, para definir, editar, trocar de modo e tirar; a obra vendida; o âmbar sobre o vidro e a decisão 6; o job de leitura da etapa 3 na CI; a conferência cruzada do orçamento; e o checklist do aparelho. É a primeira mutação nova da etapa. As linhas de tópico da tela Orçamento ficam sem chevron e sem toque até o PR 2, como o + da etapa 2 chegou um PR depois da tela da obra.

O "A vencer" na maior letra (spec: a correção do mockup da etapa 2 "se o app tiver o defeito") não ganha tarefa, porque o app já empilha: o cabeçalho (`LinhaDoAVencer`, `PecasDaObra.swift`) é um `ViewThatFits` (título e valor lado a lado; senão, um em cima do outro), o valor é o `ValorEmDinheiro` (uma linha, encolhe até a metade) e o resumo quebra. O protótipo conferiu com testes temporários: no 18 Pro em AX5, na vitrine, 361,7 × 303,3 pt com "A vencer" numa linha, o valor encolhido na de baixo e a auditoria `.textClipped` sem achado; a 375 pt, com R$ 99.999.999,99, empilha nas duas larguras de iPhone. O checklist (Tarefa 21) repete a conferência no aparelho.

### Task 11: Orçamento nas mutações do núcleo

O "Salvar" e o "Tirar orçamento" da folha viram mutações do `Estado`, como as da etapa 2: partem do estado do momento (o que outro aparelho mudou dentro do orçamento com a folha aberta fica), devolvem `nil` quando a obra sumiu e não mexem no que o app não conhece. O orçamento gravado é o `orcamentoGravado` do PR 0 (Tarefa 3); o `nil` dele tira a chave, como o `delete` do site, e o "Tirar" também. Os testes operam nas pontas (a primeira e a última obra de três) e conferem a árvore inteira, para pegar a obra errada e a chave que vaza; os afazeres do estado de teste provam que o orçamento não mexe neles.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MutacoesTests.swift`

**Interfaces:**
- Consumes: `orcamentoGravado(_:modo:total:valores:)` (PR 0), `indiceDaObra` e `Obra.orcamento`.
- Produces: `Estado.salvandoOrcamento(modo:total:valores:naObra:)` e `Estado.tirandoOrcamento(daObra:)`, os dois `-> Estado?`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MutacoesTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MutacoesTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MutacoesTests.swift
@@ -138,3 +138,80 @@ struct RegrasDaFolhaBordasTests {
                 == "terreno")
     }
 }
+
+/* As da etapa 3 (o orçamento). Cada uma opera nas pontas (a primeira e a última obra de três) e confere a árvore
+   inteira: a da obra mudada menos a chave da ação e a das outras obras, para pegar a obra errada e a chave que vaza. */
+struct MutacoesDaEtapa3Tests {
+    func estado() -> Estado {
+        Estado.de(.objeto(["obras": .lista([
+            .objeto(["id": .texto("o1"), "nome": .texto("Casa"), "dataInicio": .texto("2026-01-01"), "campoDoSite": .numero(7),
+                     "orcamento": .objeto(["modo": .texto("topicos"), "notaDoSite": .texto("fica"),
+                                           "topicos": .objeto(["pintura": .numero(100), "c_apagado": .numero(50)])]),
+                     "afazeres": .lista([
+                        .objeto(["id": .texto("p1"), "texto": .texto("Comprar tinta"), "feito": .booleano(false), "marca": .texto("fica")]),
+                        .objeto(["id": .texto("p2"), "texto": .texto("Ligar pro pedreiro"), "feito": .booleano(false)]),
+                        .objeto(["id": .texto("f1"), "texto": .texto("Pagar o gesso"), "feito": .booleano(true)]),
+                     ]),
+                     "gastos": .lista([
+                        .objeto(["id": .texto("a"), "valor": .numero(10), "topico": .texto("pintura"), "descricao": .texto("Tinta"),
+                                 "data": .texto("2026-02-01"), "pagamento": .texto("pix")]),
+                     ])]),
+            .objeto(["id": .texto("o2"), "nome": .texto("Sobrado"), "dataInicio": .texto("2026-01-01"),
+                     "orcamento": .objeto(["modo": .texto("total"), "total": .numero(1000)]),
+                     "afazeres": .lista([.objeto(["id": .texto("x"), "texto": .texto("Outro"), "feito": .booleano(false)])]),
+                     "gastos": .lista([])]),
+            .objeto(["id": .texto("o3"), "nome": .texto("Terreno"), "dataInicio": .texto("2026-01-01"),
+                     "orcamento": .objeto(["modo": .texto("total"), "total": .numero(2000), "extra": .booleano(true)]),
+                     "afazeres": .lista([.objeto(["id": .texto("q1"), "texto": .texto("Murar"), "feito": .booleano(true)])]),
+                     "gastos": .lista([])]),
+        ]), "config": .objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([])]), "chaveDoTopo": .texto("fica")]))
+    }
+
+    /// O que não pode mudar: a árvore da obra `i` sem a chave da ação, as das outras obras inteiras, a configuração e as
+    /// chaves de topo.
+    func resto(_ e: Estado, obra i: Int, sem chave: String) -> [ValorJSON] {
+        e.obras.enumerated().map { j, o in
+            var a = o.arvore
+            if j == i { a[chave] = nil }
+            return .objeto(a)
+        } + [.objeto(e.config.arvore), .objeto(e.campos)]
+    }
+
+    @Test func salvarPorTopicoGuardaOQueAFolhaNaoMostra() throws {
+        let antes = estado()
+        let e = try #require(antes.salvandoOrcamento(modo: "topicos", total: 900, valores: ["pintura": 250, "eletrica": 80, "terreno": 0],
+                                                     naObra: "o1"))
+        #expect(e.obras[0].orcamento == .objeto(["modo": .texto("topicos"), "notaDoSite": .texto("fica"),
+                                                 "topicos": .objeto(["pintura": .numero(250), "eletrica": .numero(80), "c_apagado": .numero(50)])]))
+        #expect(resto(e, obra: 0, sem: "orcamento") == resto(antes, obra: 0, sem: "orcamento"))
+    }
+
+    @Test func salvarPorTotalNaUltimaObraPartindoDoOrcamentoDoMomento() throws {
+        // Outro aparelho mudou o orçamento com a folha aberta: o "Salvar" parte do que está no estado agora.
+        var agora = estado()
+        agora.obras[2].orcamento = .objeto(["modo": .texto("total"), "total": .numero(2000), "extra": .booleano(false), "novo": .numero(1)])
+        let e = try #require(agora.salvandoOrcamento(modo: "total", total: 3500.5, valores: ["pintura": 9], naObra: "o3"))
+        #expect(e.obras[2].orcamento == .objeto(["modo": .texto("total"), "total": .numero(3500.5), "extra": .booleano(false),
+                                                 "novo": .numero(1)]))
+        #expect(resto(e, obra: 2, sem: "orcamento") == resto(agora, obra: 2, sem: "orcamento"))
+    }
+
+    @Test func salvarTudoVazioETirarSoltamAChave() throws {
+        let antes = estado()
+        for (e, caso) in [(antes.salvandoOrcamento(modo: "topicos", total: 900, valores: ["pintura": 0], naObra: "o1"), "por tópico vazio"),
+                          (antes.salvandoOrcamento(modo: "total", total: 0, valores: ["pintura": 10], naObra: "o1"), "total vazio"),
+                          (antes.tirandoOrcamento(daObra: "o1"), "tirar")] {
+            let depois = try #require(e, "\(caso)")
+            #expect(depois.obras[0].arvore["orcamento"] == nil, "a chave sai (o delete do site), nunca null: \(caso)")
+            #expect(resto(depois, obra: 0, sem: "orcamento") == resto(antes, obra: 0, sem: "orcamento"), "\(caso)")
+        }
+        let ultima = try #require(antes.tirandoOrcamento(daObra: "o3"))
+        #expect(ultima.obras[2].arvore["orcamento"] == nil)
+        #expect(resto(ultima, obra: 2, sem: "orcamento") == resto(antes, obra: 2, sem: "orcamento"))
+    }
+
+    @Test func orcamentoDeObraQueSumiuNaoGrava() {
+        #expect(estado().salvandoOrcamento(modo: "total", total: 10, valores: [:], naObra: "sumiu") == nil)
+        #expect(estado().tirandoOrcamento(daObra: "sumiu") == nil)
+    }
+}
```

- [ ] **Step 2: Ver falhar**

Run: `TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter MutacoesDaEtapa3Tests 2>&1 | grep error: | sort -u | head -6`
Expected: não compila: `value of type 'Estado' has no member 'salvandoOrcamento'` e `value of type 'Estado' has no member 'tirandoOrcamento'`; o resto são erros em cascata da inferência dos literais (`type 'Any' has no member 'numero'`).

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift
@@ -102,3 +102,24 @@ public func parcelasDaCompra(_ gasto: Gasto, naObra obra: Obra) -> Int {
     guard let grupo = gasto.grupoId else { return 1 }
     return obra.gastos.filter { $0.grupoId == grupo }.count
 }
+
+/* As da etapa 3 (app.js formOrcamento): o "Salvar" e o "Tirar orçamento" da folha do orçamento, pela regra do
+   dados.js. Também partem do estado do momento: o que outro aparelho mudou dentro do orçamento com a tela aberta fica. */
+public extension Estado {
+    /// "Salvar" da folha do orçamento: o `orcamentoGravado` sobre o orçamento que está no estado agora; o nil dele tira a
+    /// chave, como o `delete` do site.
+    func salvandoOrcamento(modo: String, total: Double, valores: [String: Double], naObra obraId: String) -> Estado? {
+        guard let i = indiceDaObra(obraId) else { return nil }
+        var e = self
+        e.obras[i].orcamento = orcamentoGravado(obras[i].orcamento, modo: modo, total: total, valores: valores)
+        return e
+    }
+
+    /// "Tirar orçamento": a chave sai.
+    func tirandoOrcamento(daObra obraId: String) -> Estado? {
+        guard let i = indiceDaObra(obraId) else { return nil }
+        var e = self
+        e.obras[i].orcamento = nil
+        return e
+    }
+}
```

- [ ] **Step 4: Ver passar**

Run: `TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -2`
Expected: `✔ Test run with 213 tests in 36 suites passed` (os 4 de `MutacoesDaEtapa3Tests`).

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MutacoesTests.swift
git commit -m "feat: orçamento nas mutações do núcleo" -m "O núcleo ganha as mutações do orçamento da etapa 3: salvar e tirar o orçamento da obra. Como as da etapa 2, partem do estado do momento, devolvem nil quando a obra sumiu e não mexem no que o app não conhece; o orçamento gravado sai da regra do dados.js."
```

### Task 12: Regras das telas do orçamento no núcleo

O que o mockup aprovado acrescenta ao site no orçamento é texto e agrupamento e entra no núcleo com teste próprio (`DentroDaObraTests`); os números saem das regras com vetor (`orcamentoObra` e o `resumoTopico` do PR 0). Na linha dos indicadores: o pior aviso dos tópicos ("2 tópicos passaram do previsto"; sem nenhum, "N perto do limite"), o que está fora ("R$ 30 mil fora do orçamento") e o "80% usado de …". No cartão da tela Orçamento: o título, o "de R$ … previstos em N tópicos" (o cartão por tópico soma só os tópicos previstos e não fecha com o Total gasto, achado 10) e a frase do que está fora. No modo total, o "Gasto por tópico", com o bruto e o "% da obra" do resumo do tópico (o mesmo número que o detalhe mostra no PR 2), na ordem da legenda do donut do site: do maior bruto para o menor e, no empate, o tópico que aparece primeiro nos gastos (o `byTop` nasce na ordem dos gastos e o sort do JavaScript é estável). E a contagem "N de M tópicos com valor" da folha. Uma concordância difere do mockup, que sempre diz "tópicos": "previstos em 1 tópico".

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift`
- Test (criar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift`

**Interfaces:**
- Consumes: `ResumoOrcamento`, `ItemOrcamento`, `moeda`, `moedaCurtaSemZero`, `numeroJS` e `ordenadoEstavel` (já existem); do PR 0, `resumoTopico`.
- Produces: `avisoDosTopicos(_:)`, `foraNaLinha(_:)`, `usadoDoPrevisto(_:)`, `tituloDoCartao(_:)`, `previstoDoCartao(_:)`, `fraseDoForaNoCartao(_:)`, `GastoDoTopico` e `gastoPorTopico(_:hoje:taxaMensal:)`, `textoDaParteDaObra(_:)`, `dicaDoModoTotal` e `topicosComValor(_:de:)`.

- [ ] **Step 1: Escrever os testes**

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/* As regras da etapa 3 que o site não tem (mockup aprovado em 18/10): o aviso dos tópicos e o que está fora, o cartão da
   tela Orçamento e o gasto por tópico no modo total. Valores de mil para cima, para separar moeda de moedaCurta. */
struct DentroDaObraTests {
    static let hoje = "2026-10-12"

    func gasto(_ id: String, _ data: String, _ valor: Double, topico: String = "matbasicos") -> ValorJSON {
        .objeto(["id": .texto(id), "valor": .numero(valor), "topico": .texto(topico), "descricao": .texto(""), "data": .texto(data),
                 "pagamento": .texto("pix")])
    }

    func obra(_ gastos: [ValorJSON], orcamento: ValorJSON? = nil, extra: [String: ValorJSON] = [:]) -> Obra {
        var o: [String: ValorJSON] = ["id": .texto("o1"), "nome": .texto("Casa Alphaville"), "dataInicio": .texto("2025-08-12"),
                                      "fase": .texto("construcao"), "gastos": .lista(gastos)]
        if let orcamento { o["orcamento"] = orcamento }
        o.merge(extra) { _, novo in novo }
        return Estado.de(.objeto(["obras": .lista([.objeto(o)])])).obras[0]
    }

    func porTopico(_ previstos: [String: Double]) -> ValorJSON {
        .objeto(["modo": .texto("topicos"), "topicos": .objeto(previstos.mapValues(ValorJSON.numero))])
    }

    func resumo(_ previstos: [String: Double], _ gastos: [(String, Double)]) throws -> ResumoOrcamento {
        try #require(orcamentoObra(obra(gastos.enumerated().map { gasto("g\($0.offset)", "2026-10-01", $0.element.1, topico: $0.element.0) },
                                        orcamento: porTopico(previstos))))
    }

    @Test func avisoDosTopicosNaLinhaDoOrcamento() throws {
        let dois = try resumo(["estrutura": 100_000, "fundacao": 50_000, "pintura": 20_000, "eletrica": 10_000],
                              [("estrutura", 120_000), ("fundacao", 52_000), ("pintura", 18_500), ("eletrica", 1_000), ("projeto", 29_780.5)])
        #expect(avisoDosTopicos(dois) == "2 tópicos passaram do previsto", "o pior aviso: o perto da pintura não aparece")
        #expect(try avisoDosTopicos(resumo(["pintura": 20_000, "eletrica": 10_000], [("pintura", 25_000), ("eletrica", 9_500)]))
                == "1 tópico passou do previsto")
        #expect(try avisoDosTopicos(resumo(["pintura": 20_000, "eletrica": 10_000, "estrutura": 5_000],
                                           [("pintura", 18_500), ("eletrica", 9_500), ("estrutura", 4_600)])) == "3 tópicos perto do limite")
        #expect(try avisoDosTopicos(resumo(["pintura": 20_000, "eletrica": 10_000], [("pintura", 18_500), ("eletrica", 1_000)]))
                == "1 tópico perto do limite")
        #expect(try avisoDosTopicos(resumo(["pintura": 20_000], [("pintura", 1_000)])) == nil)
        let total = try #require(orcamentoObra(obra([gasto("a", "2026-10-01", 900_000)],
                                                    orcamento: .objeto(["modo": .texto("total"), "total": .numero(400_000)]))))
        #expect(avisoDosTopicos(total) == nil && foraNaLinha(total) == nil && fraseDoForaNoCartao(total) == nil)
    }

    @Test func oQueEstaForaNaLinhaENoCartao() throws {
        let r = try resumo(["estrutura": 100_000, "fundacao": 50_000, "pintura": 20_000, "eletrica": 10_000],
                           [("estrutura", 120_000), ("fundacao", 52_000), ("pintura", 18_500), ("eletrica", 1_000), ("projeto", 29_780.5)])
        #expect(foraNaLinha(r) == "R$ 30 mil fora do orçamento")
        #expect(try foraNaLinha(resumo(["pintura": 20_000], [("pintura", 1_000), ("projeto", 8_000)])) == "R$ 8 mil fora do orçamento",
                "o moneyCurto do site, sem o \",0\"")
        #expect(try foraNaLinha(resumo(["pintura": 20_000], [("pintura", 1_000)])) == nil)
        #expect(fraseDoForaNoCartao(r) == "Os R$\u{00A0}29.780,50 fora do orçamento não entram nesta conta.")
        #expect(try fraseDoForaNoCartao(resumo(["pintura": 20_000], [("pintura", 1_000)])) == nil)
        #expect(usadoDoPrevisto(r.geral) == "106% usado de R$\u{00A0}180.000,00")
    }

    @Test func cartaoDaTelaOrcamento() throws {
        let r = try resumo(["estrutura": 100_000, "fundacao": 50_000, "pintura": 20_000, "eletrica": 10_000], [("estrutura", 1_000)])
        #expect(tituloDoCartao(r) == "Orçamento por tópico")
        #expect(previstoDoCartao(r) == "de R$\u{00A0}180.000,00 previstos em 4 tópicos")
        #expect(try previstoDoCartao(resumo(["pintura": 5_000], [("pintura", 1_000), ("projeto", 2_000)]))
                == "de R$\u{00A0}5.000,00 previstos em 1 tópico", "o tópico fora não conta")
        let total = try #require(orcamentoObra(obra([gasto("a", "2026-10-01", 1_000)],
                                                    orcamento: .objeto(["modo": .texto("total"), "total": .numero(400_000)]))))
        #expect(tituloDoCartao(total) == "Orçamento total" && previstoDoCartao(total) == "de R$\u{00A0}400.000,00")
    }

    @Test func gastoPorTopicoNoModoTotal() {
        let o = obra([gasto("e1", "2026-09-01", 3_000, topico: "estrutura"), gasto("x1", "2026-09-02", 1_500, topico: "c_apagado"),
                      gasto("f1", "2026-09-03", 3_000, topico: "fundacao"), gasto("l1", "2026-09-04", 2_000, topico: "eletrica"),
                      gasto("l2", "2026-12-04", 2_500, topico: "eletrica")])
        let linhas = gastoPorTopico(o, hoje: Self.hoje, taxaMensal: 1)
        #expect(linhas.map(\.id) == ["eletrica", "estrutura", "fundacao", "c_apagado"], "do maior para o menor; no empate, a ordem dos gastos")
        #expect(linhas.map(\.bruto) == [4_500, 3_000, 3_000, 1_500], "o bruto, com o gasto futuro")
        #expect(linhas.map(\.pct) == [38, 25, 25, 13], "o Math.round do site: 37,5 vai a 38")
        #expect(textoDaParteDaObra(linhas[0].pct) == "38% da obra")
        #expect(gastoPorTopico(obra([]), hoje: Self.hoje, taxaMensal: 1).isEmpty)
        #expect(dicaDoModoTotal == "Para comparar tópico a tópico, toque no lápis e escolha \"Por tópico\".")
    }

    @Test func gastoPorTopicoNoEmpateSegueAOrdemDosGastos() {
        // A legenda do donut do site: o byTop nasce na ordem dos gastos e o sort do JavaScript é estável, então no empate do
        // bruto vem o tópico que aparece primeiro na lista (fundação, pintura, estrutura): não o de id menor nem o de id maior,
        // nem o do último gasto, nem o da data. A elétrica tem o mesmo "% da obra" arredondado, mas bruto menor: vai depois.
        let o = obra([gasto("l1", "2026-09-28", 1_990, topico: "eletrica"), gasto("f1", "2026-09-03", 2_000, topico: "fundacao"),
                      gasto("p1", "2026-09-20", 1_000, topico: "pintura"), gasto("e1", "2026-09-01", 2_000, topico: "estrutura"),
                      gasto("p2", "2026-09-25", 1_000, topico: "pintura"), gasto("a1", "2026-09-02", 2_500, topico: "acabamento")])
        let linhas = gastoPorTopico(o, hoje: Self.hoje, taxaMensal: 1)
        #expect(linhas.map(\.id) == ["acabamento", "fundacao", "pintura", "estrutura", "eletrica"])
        #expect(linhas.map(\.bruto) == [2_500, 2_000, 2_000, 2_000, 1_990])
        #expect(linhas.map(\.pct) == [24, 19, 19, 19, 19], "o empate é do bruto, não do % arredondado")
    }

    @Test func topicosComValorNaFolha() {
        #expect(topicosComValor(["terreno": 10, "projeto": 0, "pintura": 5, "eletrica": -3], de: 23) == "2 de 23 tópicos com valor")
        #expect(topicosComValor([:], de: 21) == "0 de 21 tópicos com valor")
    }
}
```

- [ ] **Step 2: Ver falhar**

Run: `TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter DentroDaObraTests 2>&1 | grep error: | sort -u | head -8`
Expected: não compila, um erro por uso: `cannot find 'avisoDosTopicos' in scope`, `cannot find 'foraNaLinha' in scope`, `cannot find 'previstoDoCartao' in scope`, `cannot find 'fraseDoForaNoCartao' in scope`, `cannot find 'gastoPorTopico' in scope` e os outros nomes da tarefa.

- [ ] **Step 3: Implementar**

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift`:

```swift
import Foundation

/* Regras das telas da etapa 3 (dentro da obra) que o site não tem: o mockup aprovado em 18/10 as acrescenta ao que vem do
   app.js. Os números saem das regras com vetor (orcamentoObra, resumoTopico); o que está aqui é
   texto e agrupamento, com teste próprio (DentroDaObraTests). */

/* ---------- orçamento: a linha nos indicadores e o cartão da tela Orçamento ---------- */

/// O pior aviso dos tópicos, embaixo da linha do orçamento (modo por tópico): "2 tópicos passaram do previsto" ou, sem
/// nenhum, "N perto do limite"; nil quando todos estão dentro.
public func avisoDosTopicos(_ r: ResumoOrcamento) -> String? {
    let passaram = r.topicos.filter { $0.nivel == .passou }.count
    let perto = r.topicos.filter { $0.nivel == .perto }.count
    if passaram > 0 { return "\(passaram) tópico\(passaram > 1 ? "s passaram" : " passou") do previsto" }
    if perto > 0 { return "\(perto) tópico\(perto > 1 ? "s" : "") perto do limite" }
    return nil
}

/// "R$ 30 mil fora do orçamento", na linha, quando há gasto em tópico sem previsto (modo por tópico).
public func foraNaLinha(_ r: ResumoOrcamento) -> String? {
    guard r.modo == "topicos", r.foraTotal > 0 else { return nil }
    return moedaCurtaSemZero(r.foraTotal) + " fora do orçamento"
}

/// "80% usado de R$ 1.019.847,85", embaixo da barra da linha.
public func usadoDoPrevisto(_ geral: ItemOrcamento) -> String {
    "\(numeroJS(geral.pct))% usado de \(moeda(geral.previsto))"
}

/// "Orçamento por tópico" ou "Orçamento total", no alto do cartão.
public func tituloDoCartao(_ r: ResumoOrcamento) -> String {
    r.modo == "topicos" ? "Orçamento por tópico" : "Orçamento total"
}

/// "de R$ 1.019.847,85 previstos em 14 tópicos" (no modo total, só o "de R$ …" do site): o cartão por tópico soma só os
/// tópicos previstos e não fecha com o Total gasto (achado 10).
public func previstoDoCartao(_ r: ResumoOrcamento) -> String {
    let de = "de \(moeda(r.geral.previsto))"
    guard r.modo == "topicos" else { return de }
    let n = r.topicos.count
    return de + " previstos em \(n) tópico\(n == 1 ? "" : "s")"
}

/// "Os R$ 29.780,50 fora do orçamento não entram nesta conta.", no fim do cartão por tópico com gasto fora.
public func fraseDoForaNoCartao(_ r: ResumoOrcamento) -> String? {
    guard r.modo == "topicos", r.foraTotal > 0 else { return nil }
    return "Os \(moeda(r.foraTotal)) fora do orçamento não entram nesta conta."
}

/// Um tópico do "Gasto por tópico" da tela Orçamento no modo total.
public struct GastoDoTopico: Equatable, Sendable, Identifiable {
    public let id: String
    public let bruto: Double
    /// O "% da obra" do resumo do tópico (o arredondamento do donut).
    public let pct: Double
}

/// O "Gasto por tópico" do modo total: cada tópico com gasto, com o bruto e o "% da obra" do resumo do tópico, para o número
/// ser o mesmo que o detalhe mostra ao abrir. A ordem é a da legenda do donut do site (renderObra do app.js,
/// `Object.entries(byTop).sort((a,b)=>b[1]-a[1])`): do maior bruto para o menor e, no empate, o tópico que aparece primeiro
/// nos gastos, porque o byTop nasce na ordem dos gastos e o sort do JavaScript é estável.
public func gastoPorTopico(_ obra: Obra, hoje: String, taxaMensal: Double) -> [GastoDoTopico] {
    var ids: [String] = []
    for g in obra.gastos where !ids.contains(g.topico) { ids.append(g.topico) }
    let linhas = ids.map { id in
        let r = resumoTopico(obra, topico: id, hoje: hoje, taxaMensal: taxaMensal)
        return GastoDoTopico(id: id, bruto: r.bruto, pct: r.pct)
    }
    return ordenadoEstavel(linhas) { $0.bruto > $1.bruto }
}

/// "38% da obra".
public func textoDaParteDaObra(_ pct: Double) -> String { "\(numeroJS(pct))% da obra" }

/// A dica do fim da tela Orçamento no modo total.
public let dicaDoModoTotal = "Para comparar tópico a tópico, toque no lápis e escolha \"Por tópico\"."

/// "N de M tópicos com valor", na linha do total da folha por tópico.
public func topicosComValor(_ valores: [String: Double], de total: Int) -> String {
    "\(valores.values.filter { $0 > 0 }.count) de \(total) tópicos com valor"
}
```

- [ ] **Step 4: Ver passar**

Run: `TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -2`
Expected: `✔ Test run with 219 tests in 37 suites passed` (os 6 de `DentroDaObraTests`).

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift
git commit -m "feat: regras das telas do orçamento no núcleo" -m "As regras que o mockup aprovado da etapa 3 acrescenta ao site para o orçamento entram no núcleo com teste próprio: o aviso dos tópicos e o que está fora na linha do orçamento, o cartão da tela Orçamento, o gasto por tópico no modo total e a conta dos tópicos com valor da folha. Os números saem das regras com vetor."
```

### Task 13: Orçamento pelo gravar do app

As duas mutações passam pelo mesmo `gravar` da etapa 2, sem método novo no `ModeloApp`: o caminho já é genérico e recusa `nao-carregado` no `Sincronizador.aplicar`. Os testes provam que a tela vê a mudança na hora, que cada uma sobe o documento inteiro, que a chave do orçamento sai em vez de virar `null` e que nada sobe quando a obra sumiu ou quando o app ainda não viu os dados da conta.

**Files:**
- Test (alterar): `app-ios/CusttaTests/GravacaoDoAppTests.swift`

**Interfaces:**
- Consumes: `ModeloApp.gravar(_:)`, `salvandoOrcamento` e `tirandoOrcamento` (Tarefa 11).
- Produces: nada.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaTests/GravacaoDoAppTests.swift`:

```diff
--- a/app-ios/CusttaTests/GravacaoDoAppTests.swift
+++ b/app-ios/CusttaTests/GravacaoDoAppTests.swift
@@ -51,6 +51,37 @@ struct GravacaoDoAppTests {
         #expect(transporte.gravacoes == 0)
     }
 
+    /// Orçamento (etapa 3) pelo mesmo `gravar`: a tela vê na hora, cada mudança sobe o documento inteiro, a chave do
+    /// orçamento sai em vez de virar null, e nada sobe quando a obra sumiu.
+    @Test func orcamentoGravaPeloMesmoCaminho() async {
+        let (m, transporte, _) = montar()
+        await ate { m.sincronizador.dadosCarregados }
+        #expect(m.gravar { $0.salvandoOrcamento(modo: "topicos", total: 0, valores: ["fundacao": 120_000, "estrutura": 0], naObra: "o1") }
+                == .gravou)
+        #expect(m.sincronizador.estado.obras[0].orcamento
+                == .objeto(["modo": .texto("topicos"), "topicos": .objeto(["fundacao": .numero(120_000)])]))
+        #expect(m.gravar { $0.tirandoOrcamento(daObra: "o1") } == .gravou)
+        let obra = m.sincronizador.estado.obras[0].arvore
+        #expect(obra["orcamento"] == nil)
+        #expect(m.sincronizador.estado.obras[1].orcamento == .objeto(["modo": .texto("total"), "total": .numero(500_000)]), "a outra obra fica")
+        #expect(transporte.gravacoes == 2)
+        #expect(m.gravar { $0.salvandoOrcamento(modo: "total", total: 10, valores: [:], naObra: "nao-existe") } == .sumiu)
+        #expect(transporte.gravacoes == 2)
+    }
+
+    @Test func orcamentoAntesDeVerOsDadosNaoGrava() async {
+        let (m, transporte, _) = montar(semRede: true, dados: nil)
+        await ate { m.fase.ehPrincipal }
+        let estado = m.sincronizador.estado
+        let id: (Estado) -> String = { $0.obras.first?.id ?? "" }
+        let mudancas: [(Estado) -> Estado?] = [
+            { $0.salvandoOrcamento(modo: "total", total: 10, valores: [:], naObra: id($0)) ?? $0 },
+            { $0.tirandoOrcamento(daObra: id($0)) ?? $0 },
+        ]
+        for mudanca in mudancas { #expect(m.gravar(mudanca) == .naoCarregado) }
+        #expect(m.sincronizador.estado == estado && transporte.gravacoes == 0)
+    }
+
     /// Toque duplo no "Confirmar venda": o segundo toque chega com a obra já vendida, e a regra do núcleo não vende de novo.
     /// Sobe uma gravação só, também depois de o servidor confirmar a primeira (uma segunda subiria logo atrás dela).
     @Test func vendaConfirmadaDuasVezesGravaUmaVez() async {
```

- [ ] **Step 2: Ver passar**

É integração sobre a Tarefa 11: passa de primeira (sem ela, não compila: `value of type 'Estado' has no member 'salvandoOrcamento'`).

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | tail -5
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/GravacaoDoAppTests 2>&1 | tail -5
```
Expected: `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 18 tests in 1 suite passed` (16 e os 2 novos).

- [ ] **Step 3: Commit**

```bash
git add app-ios/CusttaTests/GravacaoDoAppTests.swift
git commit -m "test: orçamento pelo gravar do app" -m "As duas mutações do orçamento passam pelo mesmo gravar da etapa 2: a tela vê a mudança na hora, cada uma sobe o documento inteiro, a chave do orçamento sai em vez de virar null e nada sobe quando a obra sumiu ou quando o app ainda não viu os dados da conta."
```

### Task 14: Âmbar sobre o vidro e o secundário do Transparente no Fosco escuro

O catálogo de cores ganha o `AlertaNoVidro`, o âmbar de texto sobre o vidro do conteúdo (o aviso dos tópicos na linha do orçamento e o "Passou … do previsto" da tela Orçamento): no claro, `#6F4705`, porque o Alerta do site ficava entre 3,79 e 4,15:1 sobre a aurora clara; no escuro, `#FFD98A`. **O âmbar do escuro não é o do mockup** (que previa o Alerta do site, `#E0A83A` e `#FBBF24`): o laudo das telas do orçamento (Tarefa 19) achou o "Passou R$ 6,2 mil do previsto" a 3,12:1 no alto da tela Orçamento rolada, na maior letra, no escuro esmeralda, onde a aurora no pior momento clareia o vidro; para 4,5 ali o texto precisa de luminância ≥ 0,69 (`#FFD98A`: 0,727). É o mesmo ajuste do `NegativoNoVidro` da etapa 2. Decidido pelo Giovani em 21/10: a cor muda e a regra do laudo continua (4,5:1 para toda palavra); a alternativa descartada era aceitar 3:1 para texto grande na maior letra.

A decisão 6 (o secundário do Fosco escuro) fica no catálogo: o escuro do `SecundarioFosco` passa a ser o do Transparente (`#D6E8E0`); o claro não muda. O `VidroTokens.secundario` é lido sem esquema de cor em mais de 40 lugares e é o único leitor do `SecundarioFosco`, então a troca não mexe em quem o lê; a guarda prende as duas cores juntas. Hoje o Fosco aparece nas telas de entrar, criar conta e falta pouco, cujo secundário no escuro fica mais forte.

**Files:**
- Modify: `app-ios/Custta/Identidade/Paleta.swift`
- Modify: `app-ios/Custta/Identidade/Vidro.swift`
- Modify: `scripts/cores-app-ios.mjs`
- Test (alterar): `app-ios/CusttaTests/CoresTests.swift`
- Test (alterar): `tests/app-ios.test.cjs`
- Gerado: `app-ios/Custta/Assets.xcassets/` (`node scripts/cores-app-ios.mjs`)

**Interfaces:**
- Consumes: nada novo.
- Produces: `Token.alertaNoVidro`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaTests/CoresTests.swift`:

```diff
--- a/app-ios/CusttaTests/CoresTests.swift
+++ b/app-ios/CusttaTests/CoresTests.swift
@@ -25,6 +25,24 @@ struct CoresTests {
         }
     }
 
+    /// "#RRGGBB" da cor do catálogo no esquema dado.
+    private func hex(_ token: Token, _ estilo: UIUserInterfaceStyle) -> String {
+        guard let cor = UIColor(named: Paleta.nome(token, .esmeralda), in: .main, compatibleWith: nil)?
+            .resolvedColor(with: UITraitCollection(userInterfaceStyle: estilo)) else { return "" }
+        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
+        cor.getRed(&r, green: &g, blue: &b, alpha: &a)
+        return String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
+    }
+
+    /// O âmbar de texto sobre o vidro do conteúdo (etapa 3, o --amber-v do mockup): no claro, #6F4705; no escuro, #FFD98A.
+    /// E a decisão 6: no Fosco escuro, o secundário é o do Transparente; no claro, o do Fosco fica.
+    @Test func ambarSobreOVidroESecundarioDoFoscoNoEscuro() {
+        #expect(hex(.alertaNoVidro, .light) == "#6F4705")
+        #expect(hex(.alertaNoVidro, .dark) == "#FFD98A")
+        #expect(hex(.secundarioFosco, .dark) == hex(.secundarioTransparente, .dark))
+        #expect(hex(.secundarioFosco, .light) != hex(.secundarioTransparente, .light))
+    }
+
     @Test func aparenciaPadraoEscuraTransparente() {
         #expect(Aparencia.esquema("qualquer") == .dark)
         #expect(Aparencia.esquema("claro") == .light)
```

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -156,6 +156,16 @@ test('catálogo de cores em dia com scripts/cores-app-ios.mjs e com os tokens da
     // topo no Pro Max (faixa que o laudo deixa de fora, porque ali o texto é borrado); no escuro, o próprio Alerta.
     const alerta = bloco.match(/\bAlerta: \['(#\w+)', '#\w+'\]/)[1];
     assert.match(bloco, new RegExp(`\\bAlertaEtiqueta: \\['${alerta}', '#7A5410'\\]`), `AlertaEtiqueta da pele ${pele}`);
+    // O texto âmbar sobre o vidro do conteúdo (etapa 3, o --amber-v do mockup): no claro, #6F4705 (o Alerta do site dava
+    // 3,79–4,15:1 sobre a aurora clara); no escuro, #FFD98A (o Alerta ficava em 3,12:1 no alto da tela Orçamento rolada, na
+    // maior letra).
+    assert.match(bloco, /\bAlertaNoVidro: \['#FFD98A', '#6F4705'\]/, `AlertaNoVidro da pele ${pele}`);
+    // Decisão 6 da etapa 3: no Fosco escuro, o texto secundário é o do Transparente (o do Fosco ficava abaixo de 4,5:1 em
+    // dois pontos claros da aurora); no claro, o do Fosco fica.
+    const secundario = nome => bloco.match(new RegExp(`\\b${nome}: \\['(#\\w+)', '(#\\w+)'\\]`)).slice(1);
+    const [foscoEscuro, foscoClaro] = secundario('SecundarioFosco'), [transparenteEscuro, transparenteClaro] = secundario('SecundarioTransparente');
+    assert.equal(foscoEscuro, transparenteEscuro, `SecundarioFosco no escuro da pele ${pele}: o do Transparente`);
+    assert.notEqual(foscoClaro, transparenteClaro, `SecundarioFosco no claro da pele ${pele}: o do Fosco`);
   }
   const pecas = ler('app-ios/Custta/Telas/PecasDaObra.swift');
   assert.match(pecas.slice(pecas.indexOf('struct LinhaFina')), /^[^}]*paleta\.cor\(\.linhaNoVidro\)/, 'a linha fina sobre o vidro usa o LinhaNoVidro');
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | grep -m2 -E "AssertionError|ℹ fail"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -m2 error:
```
Expected: reprova `✖ catálogo de cores em dia com scripts/cores-app-ios.mjs e com os tokens da Paleta`, com `AssertionError [ERR_ASSERTION]: AlertaNoVidro da pele Esmeralda`; o `CusttaTests` não compila: `error: type 'Token' has no member 'alertaNoVidro'`. Com o token e o `SecundarioFosco` antigo no catálogo, o `CoresTests` reprova: `Expectation failed: hex(.secundarioFosco, .dark) == hex(.secundarioTransparente, .dark)` (`"#B8D4C7"` × `"#D6E8E0"`).

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Identidade/Paleta.swift`:

```diff
--- a/app-ios/Custta/Identidade/Paleta.swift
+++ b/app-ios/Custta/Identidade/Paleta.swift
@@ -67,6 +67,9 @@ enum Token: String, CaseIterable, Sendable {
     /// O lucro e o prejuízo da obra vendida sobre o vidro (o Positivo e o Negativo não fechavam 4,5:1 com a aurora atrás).
     case positivoNoVidro = "PositivoNoVidro"
     case negativoNoVidro = "NegativoNoVidro"
+    /// O texto âmbar sobre o vidro do conteúdo (etapa 3): o aviso dos tópicos na linha do orçamento e o "Passou … do
+    /// previsto". No claro, mais escuro que o Alerta, que não fechava 4,5:1 sobre a aurora clara.
+    case alertaNoVidro = "AlertaNoVidro"
     /// A folha do sistema (etapa 2): o fundo, os grupos sólidos dentro dela e a linha fina entre as linhas de um grupo.
     case folha = "Folha"
     case linhaDaFolha = "LinhaDaFolha"
```

Em `app-ios/Custta/Identidade/Vidro.swift`:

```diff
--- a/app-ios/Custta/Identidade/Vidro.swift
+++ b/app-ios/Custta/Identidade/Vidro.swift
@@ -95,7 +95,8 @@ struct VidroTokens: Equatable, Sendable {
 
     /// Texto secundário sobre a superfície (o --muted do site não fecha 4,5:1 sobre o vidro). Com Aumentar contraste, o do
     /// Transparente, mais forte que o do Fosco: sobre o mesmo fundo, o do Fosco dava 24% menos contraste, e ligar a opção
-    /// baixava a leitura (conselho de 13/10).
+    /// baixava a leitura (conselho de 13/10). No Fosco escuro, o SecundarioFosco já é o do Transparente (decisão 6 da etapa
+    /// 3, no catálogo: o do Fosco ficava em 4,24:1 sob o cartão do Orçamento); no claro, o do Fosco.
     var secundario: Token {
         if contorno && nivel != .solido { return .secundarioTransparente }
         switch nivel {
```

Em `scripts/cores-app-ios.mjs`:

```diff
--- a/scripts/cores-app-ios.mjs
+++ b/scripts/cores-app-ios.mjs
@@ -46,7 +46,9 @@ export const CORES = {
     CampoBorda: ['#1B3D33', '#C6DCD1'],
     FantasmaFundo: ['#0A3F30', '#D6F0E7'],          // botão secundário ("Reenviar link", "Sair da conta")
     FantasmaTexto: ['#8FE8D5', '#096453'],
-    SecundarioFosco: ['#B8D4C7', '#3B574B'],        // texto secundário sobre o Fosco (entrada e opção)
+    // Texto secundário sobre o Fosco (entrada e opção). No escuro, o do Transparente (decisão 6 da etapa 3: o #B8D4C7 ficava
+    // em 4,24:1 e 4,47:1 em dois pontos claros da aurora); no claro, o do Fosco.
+    SecundarioFosco: ['#D6E8E0', '#3B574B'],
     SecundarioTransparente: ['#D6E8E0', '#2B463B'], // sobre o Transparente corrigido
     SecundarioSolido: ['#9DBDAF', '#4D685C'],       // sobre a superfície sólida
     LinkNoVidro: ['#8FE8D5', '#075243'],            // link e aba ativa sobre o vidro
@@ -78,6 +80,12 @@ export const CORES = {
     // com o #FFC4CE, a nota da venda ficava em 4,25:1 onde a aurora é mais clara (T35); com ele, 4,68 (pior pixel 4,61).
     PositivoNoVidro: ['#8CF0BC', '#084A27'],
     NegativoNoVidro: ['#FFD2D9', '#8A1538'],
+    // O texto âmbar sobre o vidro do conteúdo (etapa 3, o --amber-v do mockup: o aviso dos tópicos na linha do orçamento e o
+    // "Passou … do previsto"): no claro, #6F4705 (o Alerta do site dava 3,79–4,15:1 sobre a aurora clara; este, 5,21–5,71:1).
+    // No escuro, um âmbar claro: o Alerta do site (#E0A83A) ficava em 3,12:1 (pior pixel 2,98) no alto da tela Orçamento
+    // rolada, na maior letra, onde a aurora clareia o vidro (laudo da etapa 3); este, 4,9 ali. Não é o AlertaEtiqueta, que vai
+    // sobre o fundo âmbar das etiquetas.
+    AlertaNoVidro: ['#FFD98A', '#6F4705'],
     // Etapa 2 (~/Documents/custta-mockups/nativo/etapa2/parte2.html e parte3.html, aprovados em 13/10): a folha do
     // sistema e o que vai dentro dela, o arrastar para apagar e a linha que acabou de entrar.
     Folha: ['#0A1E18E6', '#F4F9F6F0'],              // --folha: fundo da folha (presentationBackground)
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/cores-app-ios.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | tail -8 | grep -E "ℹ (pass|fail)"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | tail -5
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests 2>&1 | tail -3
```
Expected: `ℹ pass 46`, `ℹ fail 0`; sem aviso; `✔ Test run with 122 tests in 21 suites passed`. O laudo das telas de entrada no escuro (`LeituraNoVidroUITests/testLeituraNosDoisTemas` e `…/testLeituraNaMaiorLetraEComAumentarContraste`) segue com 0 palavra abaixo de 4,5: só as cinco palavras secundárias da entrada no escuro mudam, para cima (de 7,61–9,46 para 9,44–11,74).

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Assets.xcassets/Esmeralda/AlertaNoVidro.colorset/Contents.json \
  app-ios/Custta/Assets.xcassets/Esmeralda/SecundarioFosco.colorset/Contents.json \
  app-ios/Custta/Identidade/Paleta.swift \
  app-ios/Custta/Identidade/Vidro.swift \
  app-ios/CusttaTests/CoresTests.swift \
  scripts/cores-app-ios.mjs \
  tests/app-ios.test.cjs
git commit -m "feat: âmbar sobre o vidro e o secundário do Transparente no Fosco escuro" -m "O catálogo de cores ganha o AlertaNoVidro, o âmbar de texto sobre o vidro do conteúdo do mockup aprovado da etapa 3 (o aviso dos tópicos na linha do orçamento e o \"Passou … do previsto\" da tela Orçamento): no claro, #6F4705, porque o Alerta do site ficava entre 3,79 e 4,15:1 sobre a aurora clara; no escuro, um âmbar claro, #FFD98A, porque o Alerta do site, que o mockup previa, ficava em 3,12:1 no alto da tela Orçamento rolada na maior letra, onde a aurora clareia o vidro. E, pela decisão 6 da parte 2, o texto secundário do Fosco escuro passa a ser o do Transparente: o do Fosco ficava abaixo de 4,5:1 em dois pontos claros da aurora. A troca é no catálogo, sem mexer em quem lê o VidroTokens.secundario, e no claro nada muda. Hoje o Fosco aparece nas telas de entrar, criar conta e falta pouco, cujo secundário no escuro fica mais forte."
```

### Task 15: Linha do orçamento nos indicadores da obra

A linha do orçamento é a primeira do grupo dos indicadores, depois da `LinhaFina`: o chip do nível (verde dentro, âmbar perto e passou), a barra com listras no excesso, o "80% usado de …" e, por tópico, o pior aviso dos tópicos e o que está fora. Vem sem seta e sem toque: a tela que ela abre nasce na Tarefa 16, e o "Definir orçamento", que abre a folha, na 18. Na letra grande, o dinheiro de dentro das frases ("80% usado de R$ 1.019.847,85", "Passou R$ 6,2 mil do previsto") vai para a própria linha (`FraseComDinheiro`), como o `ValorEmDinheiro` dos indicadores, para encolher em vez de quebrar no meio do número. Os dados de exemplo ganham a vitrine do orçamento, com os previstos do mockup e datas relativas a hoje: os percentuais do mockup saem iguais em qualquer dia (teste parametrizado por três datas). O ícone `alerta` (o triângulo do site) entra no catálogo.

**Files:**
- Create: `app-ios/Custta/Falsos/VitrineDoOrcamento.swift`
- Create: `app-ios/Custta/Telas/PecasDoOrcamento.swift`
- Test (criar): `app-ios/CusttaTests/OrcamentoTests.swift`
- Test (criar): `app-ios/CusttaUITests/OrcamentoUITests.swift`
- Modify: `app-ios/Custta/Falsos/MontarFalso.swift`
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Modify: `app-ios/Custta/Telas/PecasDaObra.swift`
- Modify: `scripts/icones-app-ios.mjs`
- Test (alterar): `app-ios/CusttaTests/DadosDeExemploTests.swift`
- Gerado: `app-ios/Custta/Assets.xcassets/Icones/` (`node scripts/icones-app-ios.mjs`)

**Interfaces:**
- Consumes: `orcamentoObra`, `ResumoOrcamento`, `ItemOrcamento`, `NivelOrcamento.pilula`, `larguraBarraOrc`, `rodapeOrc`, `avisoDosTopicos`, `foraNaLinha` e `moeda` (núcleo); `Token.alertaNoVidro` (Tarefa 14); `EtiquetaDoIndicador`, `ValorEmDinheiro` e `LinhaFina`.
- Produces: `LinhaDoOrcamento(resumo:)` (identificador `indicadorOrcamento`, um elemento só no VoiceOver), `BarraDoOrcamento(item:fina:)` (a `fina` serve às linhas dos tópicos na Tarefa 16), `FraseComDinheiro`, `AvisoDoOrcamento`, `corDoNivel`, `DadosDeExemplo.vitrineDoOrcamento(_:hoje:)` com `previstosDoMockup` e `limiteDeTopicosProprios`, e os `CUSTTA_DADOS` `porTopico`, `perto`, `passou`, `semOrcamento` e `muitosTopicos`.

- [ ] **Step 1: Escrever os testes**

Três testes de unidade medem o que os de tela não veem: a cor do chip e da barra em cada nível e o dinheiro na própria linha na letra grande (`chipVerdeDentroEAmbarPertoEPassou`, `barraNasCoresDoNivel`, `dinheiroDaFraseNaPropriaLinhaNaLetraGrande`).

Em `app-ios/CusttaTests/DadosDeExemploTests.swift`:

```diff
--- a/app-ios/CusttaTests/DadosDeExemploTests.swift
+++ b/app-ios/CusttaTests/DadosDeExemploTests.swift
@@ -3,7 +3,8 @@ import Testing
 @testable import Custta
 import CusttaNucleo
 
-/* A vitrine mostra os números do mockup aprovado em qualquer dia (as datas são contadas de hoje). */
+/* A vitrine mostra os números do mockup aprovado em qualquer dia (as datas são contadas de hoje), também com os orçamentos
+   da etapa 3. */
 struct DadosDeExemploTests {
     static let dias = ["2026-01-31", "2026-03-01", "2026-10-08", "2026-12-31", "2027-02-28", "2028-02-29"]
 
@@ -34,4 +35,31 @@ struct DadosDeExemploTests {
         #expect(lista.aVencer?.quantidade == 13 && lista.aVencer?.total == 65_500)
         #expect(orcamentoObra(obras[1]) == nil && orcamentoObra(obras[2]) == nil)
     }
+
+    /// Os orçamentos da etapa 3 sobre a vitrine mostram os números do mockup aprovado (parte1.html) em qualquer dia.
+    @Test(arguments: dias)
+    func orcamentosDoMockupDaEtapa3(_ dia: String) throws {
+        var calendario = Calendar(identifier: .gregorian)
+        calendario.timeZone = .current
+        let partes = dia.split(separator: "-").map { Int($0)! }
+        let hoje = try #require(calendario.date(from: DateComponents(year: partes[0], month: partes[1], day: partes[2], hour: 12)))
+        func casa(_ variante: String) -> Obra { Estado.de(DadosDeExemplo.vitrineDoOrcamento(variante, hoje: hoje)).obras[0] }
+        let r = try #require(orcamentoObra(casa("porTopico")))
+        #expect(moeda(r.geral.gasto) == "R$\u{a0}812.536,95" && moeda(r.geral.previsto) == "R$\u{a0}1.019.847,85" && r.geral.pct == 80)
+        #expect(r.topicos.map { $0.id ?? "" } == ["estrutura", "fundacao", "terreno", "revest", "telhado", "ferragem", "eletrica",
+                                                   "esquadrias", "matbasicos", "hidraulica", "alvenaria", "maoobra", "acabamento", "paisagismo"])
+        #expect(avisoDosTopicos(r) == "2 tópicos passaram do previsto" && foraNaLinha(r) == "R$ 30 mil fora do orçamento")
+        #expect(r.fora.map(\.id) == ["projeto", "pintura"] && moeda(r.foraTotal) == "R$\u{a0}29.780,50")
+        let porTopico = Estado.de(DadosDeExemplo.vitrineDoOrcamento("porTopico", hoje: hoje))
+        #expect(topicosDoFormulario(porTopico.config.topicosProprios).count == 22, "os 21 fixos e o Gesso e drywall")
+        let vendida = try #require(orcamentoObra(porTopico.obras[2]), "a vendida com orçamento total")
+        #expect(vendida.geral.pct == 98 && vendida.geral.nivel == .perto && moeda(vendida.geral.sobra) == "R$\u{a0}24.000,00")
+        for (variante, pct, nivel) in [("perto", 92.0, NivelOrcamento.perto), ("passou", 105, .passou)] {
+            let o = try #require(orcamentoObra(casa(variante)))
+            #expect(o.geral.pct == pct && o.geral.nivel == nivel, "\(variante)")
+        }
+        #expect(orcamentoObra(casa("semOrcamento")) == nil && pecasOrcamento(casa("semOrcamento")).definir)
+        let muitos = Estado.de(DadosDeExemplo.vitrineDoOrcamento("muitosTopicos", hoje: hoje))
+        #expect(topicosDoFormulario(muitos.config.topicosProprios).count == 71, "os 21 fixos e os 50 próprios do limite das rules")
+    }
 }
```

Criar `app-ios/CusttaTests/OrcamentoTests.swift`:

```swift
import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* As peças do orçamento na tela da obra (etapa 3, PR 1) que o print não prova sozinho: a barra dos três níveis (no "passou",
   a parte cheia para no previsto e o excesso começa depois da fresta), a frase com o dinheiro na mesma conta do núcleo e
   o aviso dos tópicos no âmbar sobre o vidro, medido por pixel no esquema da tela. */
@MainActor
struct OrcamentoTests {
    private func item(_ gasto: Double, de previsto: Double) -> ItemOrcamento {
        let estado = Estado.de(.objeto(["obras": .lista([.objeto([
            "id": .texto("o"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
            "orcamento": .objeto(["modo": .texto("total"), "total": .numero(previsto)]),
            "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(gasto), "topico": .texto("outros"), "descricao": .texto(""),
                                       "data": .texto("2026-02-01"), "pagamento": .texto("pix")])]),
        ])])]))
        return orcamentoObra(estado.obras[0])!.geral
    }

    @Test func barraDentroEPertoEnchemAtePctLimitadoA100() {
        let dentro = GeometriaDaBarra(item(700, de: 1000), largura: 300), perto = GeometriaDaBarra(item(920, de: 1000), largura: 300)
        #expect(dentro.cheia == 210 && dentro.listras == nil)
        #expect(perto.cheia == 276 && perto.listras == nil)
        let chegou = GeometriaDaBarra(item(1000.004, de: 1000), largura: 300)
        #expect(chegou.cheia == 300 && chegou.listras == nil, "meio centavo acima ainda é chegou: a barra cheia, sem listras")
        #expect(GeometriaDaBarra(item(333.4, de: 1000), largura: 300).cheia == 99, "pelo pct arredondado do site (33%), não pela conta exata")
    }

    /// No "passou", a parte cheia é o previsto dentro do gasto (800 de 1.000: 80% da barra), e o excesso listrado vai da
    /// fresta de 2 pt ao fim; pelo pct (100%), a barra encheria inteira e o excesso não apareceria.
    @Test func barraDoPassouParaNoPrevistoComFrestaEListras() {
        let g = GeometriaDaBarra(item(1000, de: 800), largura: 300)
        #expect(g.cheia == 240)
        #expect(g.listras == 242...300)
    }

    /// A frase "{pct}% usado de {previsto}" da linha, partida para o dinheiro ir para a própria linha na letra grande, é a
    /// mesma do núcleo.
    @Test func fraseDoUsadoEADoNucleo() {
        for i in [item(700, de: 1000), item(842_317.45, de: 800_000), item(812_536.95, de: 1_019_847.85)] {
            let p = partesDoUsado(i)
            #expect("\(p.antes) \(p.valor)" == usadoDoPrevisto(i))
        }
    }

    @Test func chipVerdeDentroEAmbarPertoEPassou() {
        #expect(corDoNivel(.ok) == .positivo)
        #expect(corDoNivel(.perto) == .alerta && corDoNivel(.passou) == .alerta)
    }

    /// Os pixels da barra (100 × 8 pt, escala 1, no escuro esmeralda): dentro do previsto, o degradê começa na Marca; perto e
    /// passou, o âmbar; no "passou", o fim é listrado (âmbar e âmbar a 38% alternados) e a fresta mostra o trilho.
    @Test func barraNasCoresDoNivel() throws {
        func pixels(_ i: ItemOrcamento) throws -> (Int) -> [Int] {
            let r = ImageRenderer(content: BarraDoOrcamento(item: i).frame(width: 100)
                .environment(\.paleta, Paleta()).environment(\.colorScheme, .dark))
            r.scale = 1
            let imagem = try #require(r.cgImage)
            let (w, h) = (imagem.width, imagem.height)
            var rgba = [UInt8](repeating: 0, count: w * h * 4)
            rgba.withUnsafeMutableBytes { bytes in
                CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                    .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
            }
            let meio = h / 2, copia = rgba
            return { x in (0..<4).map { Int(copia[(meio * w + x) * 4 + $0]) } }
        }
        let perto = { (a: [Int], b: [Int]) in zip(a, b).allSatisfy { abs($0 - $1) <= 3 } }
        let dentro = try pixels(item(700, de: 1000))
        #expect(perto(dentro(4), [0x14, 0xB3, 0x9A, 0xFF]), "o degradê começa na Marca: \(dentro(4))")
        #expect(dentro(90)[3] < 0x40, "depois dos 70%, só o trilho (o texto a 14%): \(dentro(90))")
        #expect(perto(try pixels(item(920, de: 1000))(50), [0xE0, 0xA8, 0x3A, 0xFF]), "perto: o âmbar")
        let passou = try pixels(item(1000, de: 800))
        #expect(perto(passou(50), [0xE0, 0xA8, 0x3A, 0xFF]), "passou: o âmbar até o previsto")
        #expect(passou(81)[3] < 0x40, "a fresta de 2 pt mostra o trilho: \(passou(81))")
        let listras = (83..<99).map { passou($0)[3] }
        #expect(listras.contains { $0 == 0xFF } && listras.contains { $0 < 0xC0 }, "o excesso listrado alterna: \(listras)")
    }

    /// Na letra grande, o dinheiro da frase vai para a própria linha: em 1000 pt, onde a frase caberia numa linha, ela ocupa
    /// duas; no tamanho padrão, uma.
    @Test func dinheiroDaFraseNaPropriaLinhaNaLetraGrande() {
        func altura(_ t: DynamicTypeSize) -> CGFloat {
            UIHostingController(rootView: FraseComDinheiro(antes: "80% usado de", valor: "R$\u{a0}1.019.847,85", cor: .texto)
                .dynamicTypeSize(t).environment(\.displayScale, 1))
                .sizeThatFits(in: CGSize(width: 1000, height: CGFloat.infinity)).height
        }
        let linha = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)).lineHeight
        #expect(altura(.accessibility5) > 1.8 * linha, "duas linhas: \(altura(.accessibility5)) com a linha de \(linha)")
        #expect(altura(.large) < 30, "uma linha: \(altura(.large))")
    }

    /// A cor mais comum entre os pixels opacos do desenho (o texto, sem a borda suavizada).
    private func corDoTexto(_ esquema: ColorScheme) throws -> [UInt8] {
        let r = ImageRenderer(content: AvisoDoOrcamento(texto: "2 tópicos passaram do previsto")
            .environment(\.paleta, Paleta()).environment(\.colorScheme, esquema))
        r.scale = 3
        let imagem = try #require(r.cgImage)
        let (w, h) = (imagem.width, imagem.height)
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        rgba.withUnsafeMutableBytes { bytes in
            CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        let opacos = stride(from: 0, to: rgba.count, by: 4).filter { rgba[$0 + 3] == 255 }.map { Array(rgba[$0..<$0 + 3]) }
        return Dictionary(grouping: opacos, by: { $0 }).max { $0.value.count < $1.value.count }?.key ?? []
    }

    /// O aviso dos tópicos no âmbar sobre o vidro: #6F4705 no claro (o Alerta do site, #8A5A06, não fechava 4,5:1 sobre a
    /// aurora clara) e #FFD98A no escuro.
    @Test func avisoDosTopicosNoAmbarSobreOVidro() throws {
        #expect(try corDoTexto(.light) == [0x6F, 0x47, 0x05])
        #expect(try corDoTexto(.dark) == [0xFF, 0xD9, 0x8A])
    }
}
```

Criar `app-ios/CusttaUITests/OrcamentoUITests.swift`:

```swift
import XCTest

/* O orçamento (etapa 3, PR 1), com a vitrine e os orçamentos do mockup aprovado (VitrineDoOrcamento.swift): a linha nos
   indicadores, logo abaixo do Total gasto, nos três níveis do site, por total e por tópico, com o aviso dos tópicos e o que
   está fora; sem orçamento, nenhuma linha; a obra vendida com orçamento mostra a linha, como o site. */
@MainActor
final class OrcamentoUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// A linha da Casa Alphaville com o orçamento dado: o rótulo de acessibilidade junta os textos dela.
    private func linha(_ dados: String, obra: String = "v1") -> (XCUIApplication, String) {
        let app = abrirApp(conta: "senha", dados: dados, abrir: "obra:\(obra)")
        let linha = app.elemento("indicadorOrcamento")
        XCTAssertTrue(linha.waitForExistence(timeout: 10), "\(dados): a linha do orçamento")
        return (app, linha.label)
    }

    func testLinhaPorTotalNosTresNiveis() {
        let casos = [
            ("vitrine", ["Orçamento", "dentro do previsto", "sobra", "R$\u{a0}357.682,55", "70% usado de R$\u{a0}1.200.000,00"]),
            ("perto", ["perto do limite", "sobra", "R$\u{a0}77.682,55", "92% usado de R$\u{a0}920.000,00"]),
            ("passou", ["passou do previsto", "passou, R$\u{a0}42.317,45", "105% usado de R$\u{a0}800.000,00"]),
        ]
        for (dados, textos) in casos {
            let (app, rotulo) = linha(dados)
            for texto in textos { XCTAssertTrue(rotulo.contains(texto), "\(dados): \"\(texto)\" em \"\(rotulo)\"") }
            XCTAssertFalse(rotulo.contains("tópico"), "\(dados): por total, sem o aviso dos tópicos: \(rotulo)")
            app.terminate()
        }
    }

    func testLinhaPorTopicoComOAvisoEOQueEstaFora() {
        let (_, rotulo) = linha("porTopico")
        for texto in ["dentro do previsto", "R$\u{a0}207.310,90", "80% usado de R$\u{a0}1.019.847,85", "2 tópicos passaram do previsto",
                      "R$ 30 mil fora do orçamento"] {
            XCTAssertTrue(rotulo.contains(texto), "\"\(texto)\" em \"\(rotulo)\"")
        }
    }

    /// A primeira linha do grupo dos indicadores: logo abaixo do Total gasto, que não sai do lugar, e antes do Corrigido.
    func testALinhaVemLogoAbaixoDoTotalGasto() {
        let (app, _) = linha("porTopico")
        let total = app.elemento("indicadorTotal").frame, orcamento = app.elemento("indicadorOrcamento").frame
        let corrigido = app.elemento("indicadorCorrigido").frame
        // O grupo começa 10 pt abaixo do Total gasto e o texto da linha, 13 abaixo do alto do grupo (o quadro de acessibilidade
        // da linha começa no texto).
        XCTAssertEqual(orcamento.minY - total.maxY, 10 + 13, accuracy: 1, "a primeira linha do grupo, logo abaixo do Total gasto")
        XCTAssertLessThanOrEqual(orcamento.maxY, corrigido.minY, "antes do Corrigido")
        XCTAssertEqual(orcamento.minX, corrigido.minX, accuracy: 0.5, "no mesmo grupo")
    }

    func testSemOrcamentoNenhumaLinha() {
        let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("indicadorCorrigido").waitForExistence(timeout: 10))
        XCTAssertFalse(app.elemento("indicadorOrcamento").exists)
    }

    /// Como no site: a obra vendida com orçamento continua mostrando como ele fechou.
    func testVendidaComOrcamentoMostraALinha() {
        let (_, rotulo) = linha("porTopico", obra: "v3")
        XCTAssertTrue(rotulo.contains("perto do limite") && rotulo.contains("98% usado de R$\u{a0}1.000.000,00"), rotulo)
    }
}
```

- [ ] **Step 2: Ver falhar**

Run: `xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep error: | sort -u | head -8`
Expected: o `CusttaTests` não compila: `cannot find 'GeometriaDaBarra' in scope`, `type 'DadosDeExemplo' has no member 'vitrineDoOrcamento'`, `cannot find 'corDoNivel' in scope`, `cannot find 'partesDoUsado' in scope` e `cannot find 'BarraDoOrcamento' in scope` (o resto é cascata da inferência). Só com o `OrcamentoUITests` no lugar, 4 dos 5 reprovam com `XCTAssertTrue failed - <dados>: a linha do orçamento` (o `semOrcamento`, negativo, passa).

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Falsos/MontarFalso.swift`:

```diff
--- a/app-ios/Custta/Falsos/MontarFalso.swift
+++ b/app-ios/Custta/Falsos/MontarFalso.swift
@@ -7,7 +7,8 @@ import CusttaNucleo
    CUSTTA_CONTA   conta inicial da ContaFalsa (nenhuma, senha, senha-nao-confirmada, apple-sem-perfil,
                   google-sem-perfil, google-perfil-concorrente)
    CUSTTA_DADOS   vitrine (padrão: as obras do mockup) | exemplo (as dos testes) | vazio | limite (as 300 obras do teto) |
-                  prejuizo (a vitrine com a vendida no prejuízo)
+                  prejuizo (a vitrine com a vendida no prejuízo) | porTopico, perto, passou, semOrcamento, muitosTopicos (os
+                  orçamentos do mockup da etapa 3 sobre a vitrine: VitrineDoOrcamento.swift)
    CUSTTA_REDE    offline (abre "em modo avião": dados do cache e indicador "Sem conexão")
    CUSTTA_LEITURA erro (a escuta falha com permission-denied) | formato (documento que o app não lê) | nunca (a escuta
                   não responde: "Carregando suas obras…")
@@ -36,6 +37,7 @@ extension Composicao {
         case "exemplo": DadosDeExemplo.blob
         case "limite": DadosDeExemplo.noTeto()
         case "prejuizo": DadosDeExemplo.vitrineComPrejuizo()
+        case let v? where ["porTopico", "perto", "passou", "semOrcamento", "muitosTopicos"].contains(v): DadosDeExemplo.vitrineDoOrcamento(v)
         default: DadosDeExemplo.vitrine()
         }
         // CUSTTA_APAGAR_REMOTO=<obra>/<gasto>@<segundos>: outro aparelho apaga um gasto com o app aberto; sem o gasto
```

Criar `app-ios/Custta/Falsos/VitrineDoOrcamento.swift`:

```swift
#if DEBUG
import Foundation
import CusttaNucleo

/* Os orçamentos do mockup aprovado da etapa 3 (parte1.html, de 18/10/2026) sobre a vitrine: a Casa Alphaville com os 46
   lançamentos e o orçamento em cada situação dos quadros, para a tela mostrar os números do mockup em qualquer dia.
   CUSTTA_DADOS (MontarFalso):
   porTopico      o orçamento por tópico em 14 tópicos (R$ 1.019.847,85 previstos, 80% usado, Estrutura e Fundação
                  passaram, três perto, Documentação e Pintura fora), um tópico próprio ("Gesso e drywall", 22 linhas na
                  folha) e a Casa Tamboré 4, vendida, com o orçamento total de R$ 1.000.000,00
   perto, passou  o total de R$ 920.000,00 (92%) e de R$ 800.000,00 (105%)
   semOrcamento   a Casa Alphaville sem orçamento ("Definir orçamento")
   muitosTopicos  o porTopico com 50 tópicos próprios, o limite das rules: 71 linhas na folha
   Na vitrine de sempre, o total de R$ 1.200.000,00 (70%, dentro do previsto). */
extension DadosDeExemplo {
    /// Os previstos por tópico do mockup.
    static let previstosDoMockup: [String: Double] = [
        "terreno": 319_847.85, "estrutura": 85_000, "revest": 80_000, "maoobra": 150_000, "fundacao": 60_000, "telhado": 50_000,
        "ferragem": 45_000, "esquadrias": 40_000, "matbasicos": 40_000, "eletrica": 30_000, "hidraulica": 25_000,
        "alvenaria": 20_000, "acabamento": 60_000, "paisagismo": 15_000,
    ]

    static func vitrineDoOrcamento(_ variante: String, hoje: Date = .now) -> ValorJSON {
        let base = vitrine(hoje: hoje)
        guard case .objeto(var raiz) = base, case .lista(var obras) = raiz["obras"], obras.count == 3,
              case .objeto(var casa) = obras[0], case .objeto(var tambore) = obras[2],
              case .objeto(var config) = raiz["config"] else { return base }
        func total(_ valor: Double) -> ValorJSON { .objeto(["modo": .texto("total"), "total": .numero(valor)]) }
        switch variante {
        case "perto": casa["orcamento"] = total(920_000)
        case "passou": casa["orcamento"] = total(800_000)
        case "semOrcamento": casa["orcamento"] = nil
        default:
            casa["orcamento"] = .objeto(["modo": .texto("topicos"), "topicos": .objeto(previstosDoMockup.mapValues(ValorJSON.numero))])
            tambore["orcamento"] = total(1_000_000)
            let proprios = [("c_gesso", "Gesso e drywall")]
                + (variante == "muitosTopicos" ? (2...limiteDeTopicosProprios).map { ("c_proprio\($0)", "Tópico próprio \($0)") } : [])
            config["topicosCustom"] = .lista(proprios.map { .objeto(["id": .texto($0.0), "nm": .texto($0.1), "ic": .texto("etiqueta")]) })
        }
        obras[0] = .objeto(casa)
        obras[2] = .objeto(tambore)
        raiz["obras"] = .lista(obras)
        raiz["config"] = .objeto(config)
        return .objeto(raiz)
    }

    /// O limite de tópicos próprios das rules (`topicosCustom.size() <= 50`).
    static let limiteDeTopicosProprios = 50
}
#endif
```

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -70,7 +70,7 @@ struct ObraView: View {
                 LazyVStack(alignment: .leading, spacing: 10) {
                     TituloDaObra(nome: obra.nome)
                     PilulaDaFase(obra: obra, hoje: hoje)
-                    IndicadoresDaObraView(indicadores: indicadoresDaObra(obra, taxa: taxa, hoje: hoje))
+                    IndicadoresDaObraView(indicadores: indicadoresDaObra(obra, taxa: taxa, hoje: hoje), orcamento: orcamentoObra(obra))
                     AcoesDaFaseView(fase: obra.fase) { agir($0, obra: obra) }
                         .padding(.top, 2)
                         .padding(.bottom, 14)
```

Em `app-ios/Custta/Telas/PecasDaObra.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDaObra.swift
+++ b/app-ios/Custta/Telas/PecasDaObra.swift
@@ -74,10 +74,12 @@ struct EtiquetaDoIndicador: View {
     }
 }
 
-/// Os indicadores na opção A do mockup: o total gasto em destaque e um cartão com Corrigido, A pagar (a folha e a seta são
-/// da etapa 3) e Venda. Os textos e as contas são os do site (indicadoresDaObra).
+/// Os indicadores na opção A do mockup: o total gasto em destaque e um cartão com o orçamento (etapa 3, a primeira linha,
+/// só com orçamento), Corrigido, A pagar (a folha e a seta são da etapa 3) e Venda. Os textos e as contas são os do site
+/// (indicadoresDaObra, orcamentoObra).
 struct IndicadoresDaObraView: View {
     let indicadores: IndicadoresDaObra
+    var orcamento: ResumoOrcamento? = nil
     @Environment(\.paleta) private var paleta
     @Environment(\.vidro) private var vidro
 
@@ -88,6 +90,10 @@ struct IndicadoresDaObraView: View {
         VStack(spacing: 10) {
             heroi
             VStack(spacing: 0) {
+                if let orcamento {
+                    LinhaDoOrcamento(resumo: orcamento)
+                    LinhaFina().padding(.leading, 18)
+                }
                 linha(rotulo: "Corrigido pelo banco", etiqueta: nil, valor: indicadores.corrigido, nota: indicadores.notaDoCorrigido,
                       identificador: "indicadorCorrigido")
                 LinhaFina().padding(.leading, 18)
```

Criar `app-ios/Custta/Telas/PecasDoOrcamento.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* As peças do orçamento na tela da obra (mockup aprovado da etapa 3, parte 1, opção A): a linha do orçamento, primeira do
   grupo dos indicadores, logo abaixo do Total gasto; a barra dos três níveis do site; o aviso dos tópicos. Perto e passou em
   âmbar, nunca vermelho; no "passou", a barra para no previsto, com uma fresta, e o excesso vem listrado: a diferença está
   na forma, não só na cor. Medidas do mockup: recuo 18 (16 à direita), o chip como os dos indicadores, "sobra" e "passou"
   em subheadline semibold no secundário, o valor em title2 bold, a barra de 8 com 9 acima e 7 abaixo. Os textos e as contas
   são os do site (orcamentoObra, rodapeOrc) e os das regras novas do app (avisoDosTopicos, foraNaLinha). */

/// Onde a barra do orçamento enche e onde ficam as listras do excesso, em pontos (larguraBarraOrc do site; no "passou", a
/// parte cheia é o previsto dentro do gasto e o excesso vem depois da fresta).
struct GeometriaDaBarra: Equatable {
    /// A parte cheia, a partir da esquerda.
    let cheia: CGFloat
    /// O excesso listrado, do fim da fresta ao fim da barra; nil fora do "passou".
    let listras: ClosedRange<CGFloat>?

    /// A fresta entre o previsto e o excesso.
    static let fresta: CGFloat = 2

    init(_ item: ItemOrcamento, largura: CGFloat) {
        if item.nivel == .passou, item.gasto > 0 {
            let previsto = largura * CGFloat(item.previsto) / CGFloat(item.gasto)
            cheia = previsto
            listras = min(previsto + Self.fresta, largura)...largura
        } else {
            cheia = largura * CGFloat(larguraBarraOrc(item.pct)) / 100
            listras = nil
        }
    }
}

/// A barra do orçamento: o trilho no texto a 14%; dentro do previsto, o degradê da marca; perto e passou, o âmbar; no
/// "passou", o excesso listrado a 45° (3 de âmbar e 3 de âmbar a 38%). 8 pt (6 nas linhas dos tópicos, `fina`), 12 na
/// letra grande. Figura, fora do VoiceOver: a linha diz o nível em texto.
struct BarraDoOrcamento: View {
    let item: ItemOrcamento
    var fina = false
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let altura: CGFloat = tamanho.isAccessibilitySize ? 12 : fina ? 6 : 8
        GeometryReader { geo in
            let g = GeometriaDaBarra(item, largura: geo.size.width)
            ZStack(alignment: .leading) {
                Capsule().fill(paleta.cor(.texto).opacity(0.14))
                if g.cheia > 0 {
                    Capsule()
                        .fill(item.nivel == .ok ? AnyShapeStyle(LinearGradient(colors: [paleta.cor(.marca), paleta.cor(.destaque)],
                                                                                 startPoint: .leading, endPoint: .trailing))
                                                : AnyShapeStyle(paleta.cor(.alerta)))
                        .frame(width: g.cheia)
                }
                if let l = g.listras, l.upperBound > l.lowerBound {
                    ListrasDoExcesso(cor: paleta.cor(.alerta))
                        .frame(width: l.upperBound - l.lowerBound)
                        .clipShape(UnevenRoundedRectangle(bottomTrailingRadius: altura / 2, topTrailingRadius: altura / 2))
                        .offset(x: l.lowerBound)
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: altura)
        .accessibilityHidden(true)
    }
}

/// O excesso do "passou": listras "/" de 3 pt a cada 6 pt (medidos de través), em âmbar sobre o âmbar a 38%.
private struct ListrasDoExcesso: View {
    let cor: Color

    var body: some View {
        Canvas { contexto, tamanho in
            contexto.fill(Path(CGRect(origin: .zero, size: tamanho)), with: .color(cor.opacity(0.38)))
            // A 45°, os 3 e os 6 pt de través valem 3√2 e 6√2 na horizontal.
            let largura = 3 * CGFloat(2).squareRoot(), passo = 6 * CGFloat(2).squareRoot(), h = tamanho.height
            var listras = Path()
            var x = -h
            while x < tamanho.width {
                listras.move(to: CGPoint(x: x, y: h))
                listras.addLine(to: CGPoint(x: x + largura, y: h))
                listras.addLine(to: CGPoint(x: x + largura + h, y: 0))
                listras.addLine(to: CGPoint(x: x + h, y: 0))
                listras.closeSubpath()
                x += passo
            }
            contexto.fill(listras, with: .color(cor))
        }
    }
}

/// "{pct}% usado de" e o previsto: o `usadoDoPrevisto` do núcleo partido, para o dinheiro ir para a própria linha na letra
/// grande.
func partesDoUsado(_ geral: ItemOrcamento) -> (antes: String, valor: String) {
    ("\(rodapeOrc(geral).usado) usado de", moeda(geral.previsto))
}

/// Uma frase com dinheiro dentro ("80% usado de R$ 1.019.847,85"): numa linha só no tamanho padrão; na letra grande, o
/// dinheiro vai para a própria linha e encolhe para caber (mockup, `.din`), em vez de partir no meio.
struct FraseComDinheiro: View {
    let antes: String
    let valor: String
    var depois = ""
    var fonte: Font = .subheadline
    let cor: Token
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        if tamanho.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 0) {
                if !antes.isEmpty { Text(antes).font(fonte).foregroundStyle(paleta.cor(cor)) }
                ValorEmDinheiro(texto: valor, fonte: fonte, cor: cor)
                if !depois.isEmpty { Text(depois).font(fonte).foregroundStyle(paleta.cor(cor)) }
            }
        } else {
            Text([antes, valor, depois].filter { !$0.isEmpty }.joined(separator: " "))
                .font(fonte)
                .foregroundStyle(paleta.cor(cor))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// O aviso dos tópicos ("2 tópicos passaram do previsto"): o triângulo do site e o texto em semibold, no âmbar sobre o
/// vidro. O triângulo cresce com a letra (16 pt no tamanho padrão; 0,8 da letra nos tamanhos de acessibilidade, mockup).
struct AvisoDoOrcamento: View {
    let texto: String
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho
    @ScaledMetric(relativeTo: .subheadline) private var letra: CGFloat = 15

    var body: some View {
        let lado = tamanho.isAccessibilitySize ? letra * 0.8 : letra * 16 / 15
        HStack(alignment: .top, spacing: 6) {
            Image(decorative: "Icones/alerta")
                .resizable()
                .frame(width: lado, height: lado)
                .padding(.top, tamanho.isAccessibilitySize ? letra * 0.15 : 2)
            Text(texto)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(paleta.cor(.alertaNoVidro))
    }
}

/// A linha do orçamento nos indicadores: "Orçamento" e o nível do site, quanto sobra (ou passou), a barra, "{pct}% usado de
/// {previsto}" e, por tópico, o pior aviso dos tópicos e o que está fora. Um elemento só para o VoiceOver, como as outras
/// linhas dos indicadores.
struct LinhaDoOrcamento: View {
    let resumo: ResumoOrcamento
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let geral = resumo.geral
        let rodape = rodapeOrc(geral)
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) { rotulo; Spacer(minLength: 8); etiqueta(geral.nivel) }
                VStack(alignment: .leading, spacing: 6) { rotulo; etiqueta(geral.nivel) }
            }
            // "sobra R$ …" numa linha; na letra grande, um em cima do outro (mockup).
            let layout = tamanho.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
                                                     : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 7))
            layout {
                Text(rodape.rotulo).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(vidro.secundario))
                ValorEmDinheiro(texto: rodape.valor, fonte: .title2.weight(.bold))
            }
            .padding(.top, 2)
            BarraDoOrcamento(item: geral)
                .padding(.top, 9)
                .padding(.bottom, 7)
            let usado = partesDoUsado(geral)
            FraseComDinheiro(antes: usado.antes, valor: usado.valor, cor: vidro.secundario)
            if let aviso = avisoDosTopicos(resumo) { AvisoDoOrcamento(texto: aviso).padding(.top, 4) }
            if let fora = foraNaLinha(resumo) {
                Text(fora).font(.subheadline).foregroundStyle(paleta.cor(vidro.secundario)).fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 13, leading: 18, bottom: 13, trailing: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("indicadorOrcamento")
    }

    private var rotulo: some View {
        Text("Orçamento").font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func etiqueta(_ nivel: NivelOrcamento) -> some View {
        EtiquetaDoIndicador(texto: nivel.pilula, cor: corDoNivel(nivel))
    }
}

/// O chip do nível do orçamento: verde dentro do previsto; âmbar perto e passou, nunca vermelho.
func corDoNivel(_ nivel: NivelOrcamento) -> EtiquetaDoIndicador.Cor { nivel == .ok ? .positivo : .alerta }
```

Em `scripts/icones-app-ios.mjs`:

```diff
--- a/scripts/icones-app-ios.mjs
+++ b/scripts/icones-app-ios.mjs
@@ -16,10 +16,11 @@ const PASTA = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../app
 
 /** Ícones que as telas usam: abas, fases da obra, sair, olho da senha e a seta da dica; na etapa 2, os dos 21 tópicos
     (TOPICOS do calc.js) e o "etiqueta" dos tópicos próprios, o calendário do "A vencer", o cartão do pagamento, o lápis
-    de editar, o acordo da venda, o voltar das fases e as notas da obra sem gastos. */
+    de editar, o acordo da venda, o voltar das fases e as notas da obra sem gastos; na etapa 3, o triângulo do aviso dos tópicos
+    na linha do orçamento. */
 export const USADOS = ['predio', 'engrenagem', 'sair', 'guindaste', 'casa', 'check', 'olho', 'olhoFechado', 'setaBaixo',
   'mapa', 'documento', 'tijolos', 'pa', 'vergalhao', 'raio', 'gota', 'porta', 'ladrilho', 'rolo', 'piscina', 'arvore', 'capacete',
-  'caixa', 'mais', 'etiqueta', 'calendario', 'cartao', 'lapis', 'acordo', 'voltar', 'notas'];
+  'caixa', 'mais', 'etiqueta', 'calendario', 'cartao', 'lapis', 'acordo', 'voltar', 'notas', 'alerta'];
 
 const info = { author: 'xcode', version: 1 };
 
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/icones-app-ios.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | tail -5
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/OrcamentoUITests -only-testing:CusttaTests/OrcamentoTests -only-testing:CusttaTests/DadosDeExemploTests 2>&1 | grep -E "Test run with|Executed|TEST EXECUTE" | tail -4
```
Expected: sem aviso; `OrcamentoUITests` 5 de 5 (o quadro de acessibilidade da linha começa no texto, 13 pt abaixo do topo do grupo); `OrcamentoTests` 7 de 7; `** TEST EXECUTE SUCCEEDED **`. Na regressão da obra, `CusttaTests` dá `✔ Test run with 127 tests in 22 suites passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Assets.xcassets/Icones/alerta.imageset/Contents.json \
  app-ios/Custta/Assets.xcassets/Icones/alerta.imageset/alerta.svg \
  app-ios/Custta/Falsos/MontarFalso.swift \
  app-ios/Custta/Falsos/VitrineDoOrcamento.swift \
  app-ios/Custta/Telas/ObraView.swift \
  app-ios/Custta/Telas/PecasDaObra.swift \
  app-ios/Custta/Telas/PecasDoOrcamento.swift \
  app-ios/CusttaTests/DadosDeExemploTests.swift \
  app-ios/CusttaTests/OrcamentoTests.swift \
  app-ios/CusttaUITests/OrcamentoUITests.swift \
  scripts/icones-app-ios.mjs
git commit -m "feat: linha do orçamento nos indicadores da obra" -m "Com orçamento, por total ou por tópico, a obra mostra o orçamento na primeira linha do grupo dos indicadores, logo abaixo do Total gasto, como na opção A do mockup aprovado da etapa 3: o nível do site (dentro do previsto, perto do limite ou passou do previsto), quanto sobra ou passou, a barra e quanto já foi usado do previsto; por tópico, também o pior aviso dos tópicos e o que está fora do orçamento. Perto e passou vêm em âmbar, nunca em vermelho, e no passou a barra para no previsto, com uma fresta, e o excesso vem listrado: a diferença está na forma, não só na cor. Na letra grande, o dinheiro de dentro das frases vai para a própria linha e encolhe para caber. A obra vendida com orçamento continua mostrando como ele fechou, como no site. A linha ainda não abre nada; a tela Orçamento chega no commit seguinte. Os serviços falsos ganham os orçamentos dos quadros do mockup sobre a vitrine (por tópico, perto, passou, sem orçamento e com os 71 tópicos da folha), com os números do mockup em qualquer dia."
```

### Task 16: Tela Orçamento da obra

O toque na linha do orçamento abre a tela Orçamento no caminho da obra (`RotaDeObras.orcamento`): o cartão (título, "de R$ … previstos em N tópicos" e a frase do que está fora), o "Por tópico" com a barra fina de cada tópico, os tópicos fora do orçamento e, no modo total, o "Gasto por tópico" com o "% da obra" e a dica do fim. A linha inteira vira o botão, com a seta e o rótulo de voz "Orçamento". O título pequeno que entra na barra ao rolar virou modificador (`tituloPequenoAoRolar`), usado pela obra e pela tela Orçamento; só esmaece, sem movimento. O valor "R$ 91 mil / 85 mil" não quebra (o `white-space: nowrap` do `.ot` do mockup) e fica no meio da altura do nome; a linha fora do orçamento, no meio da altura do ícone. A dica do modo total fala do lápis, que chega na Tarefa 18. Sem a obra (apagada em outro aparelho), a tela Orçamento e a obra saem do caminho; sem o orçamento, só a tela Orçamento. O destaque do gasto salvo só rola a obra quando ela está no topo do caminho, e o + da tela Orçamento lança na obra dela. As linhas de tópico ficam sem chevron e sem toque até o PR 2 (decisão 3: melhor faltar a peça do que uma seta que não abre nada).

**Files:**
- Create: `app-ios/Custta/Telas/OrcamentoView.swift`
- Create: `app-ios/Custta/Telas/PecasDaTelaOrcamento.swift`
- Test (criar): `app-ios/CusttaTests/TelaOrcamentoTests.swift`
- Modify: `app-ios/Custta/Identidade/Componentes.swift`
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Modify: `app-ios/Custta/Telas/ObrasView.swift`
- Modify: `app-ios/Custta/Telas/PecasDaObra.swift`
- Modify: `app-ios/Custta/Telas/PecasDoOrcamento.swift`
- Modify: `app-ios/Custta/Telas/PrincipalView.swift`
- Test (alterar): `app-ios/CusttaUITests/OrcamentoUITests.swift`
- Test (alterar): `tests/app-ios.test.cjs`

**Interfaces:**
- Consumes: `tituloDoCartao`, `previstoDoCartao`, `fraseDoForaNoCartao`, `gastoPorTopico`/`GastoDoTopico`, `textoDaParteDaObra`, `dicaDoModoTotal`, `linhaTopicoOrc`, `fraseTopicoOrc`, `moedaCurtaSemZero` e `mapaDeTopicos` (núcleo); `LinhaDoOrcamento`, `BarraDoOrcamento(fina:)`, `FraseComDinheiro` e `corDoNivel` (Tarefa 15).
- Produces: `RotaDeObras.orcamento(String)` e `RotaDeObras.obraId`, `OrcamentoView(id:caminho:)`, `PilulaDaLista` (de que a `PilulaDeLancamentos` vira um caso), `TituloDaObra(identificador:)`, `View.tituloPequenoAoRolar(_:)`, `RolagemFixaDoTeste` (o gancho `-custta.rolagem`, agora da obra e da tela Orçamento) e `CUSTTA_ABRIR=orcamento:<id>`; identificadores `tituloDoOrcamento`, `cartaoDoOrcamento`, `porTopico`, `topicoOrc-<id>`, `foraDoOrcamento`, `foraOrc-<id>`, `gastoPorTopico`, `gastoTopico-<id>` e `dicaDoModoTotal`.

- [ ] **Step 1: Escrever os testes**

Criar `app-ios/CusttaTests/TelaOrcamentoTests.swift`:

```swift
import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* As linhas e as frases da tela Orçamento (etapa 3, PR 1), montadas das regras do núcleo: o nome do tópico (o id, com o
   ícone etiqueta, quando o app não conhece o tópico, como no site), o gasto e o previsto do site, a frase do nível (a do
   "passou" em âmbar), o valor da linha, que não quebra, e as frases do cartão partidas em volta do dinheiro, iguais às do
   núcleo. */
struct TelaOrcamentoTests {
    private func obra(_ orcamento: ValorJSON, gastos: [(String, Double)]) -> Obra {
        Obra(arvore: ["id": .texto("o"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
                      "orcamento": orcamento,
                      "gastos": .lista(gastos.enumerated().map { i, g in
                          .objeto(["id": .texto("g\(i)"), "valor": .numero(g.1), "topico": .texto(g.0), "descricao": .texto(""),
                                   "data": .texto("2026-02-01"), "pagamento": .texto("pix")])
                      })])
    }

    private let porTopico: ValorJSON = .objeto(["modo": .texto("topicos"),
                                                "topicos": .objeto(["estrutura": .numero(85_000), "revest": .numero(80_000),
                                                                    "c_apagado": .numero(7_000), "pintura": .numero(10_000)])])

    @Test func porTopicoComAsFrasesDoSiteEOTopicoDesconhecidoPeloId() throws {
        let o = obra(porTopico, gastos: [("estrutura", 91_200), ("revest", 76_700), ("pintura", 1_000), ("projeto", 22_880.5)])
        let r = try #require(orcamentoObra(o))
        let linhas = linhasPorTopico(r, topicos: mapaDeTopicos([]))
        #expect(linhas.map(\.id) == ["estrutura", "revest", "pintura", "c_apagado"], "a ordem do site: quem gastou mais do previsto primeiro")
        #expect(linhas[0] == LinhaDeTopicoDoOrcamento(id: "estrutura", nome: "Estrutura", icone: "guindaste", gasto: "R$ 91 mil",
                                                       previsto: "85 mil", item: r.topicos[0], frase: "Passou R$ 6,2 mil do previsto",
                                                       fraseEmAlerta: true))
        #expect(linhas[1].frase == "Faltam R$ 3,3 mil — 96%" && !linhas[1].fraseEmAlerta)
        #expect(linhas[2].frase == nil, "dentro do previsto, sem frase")
        // O tópico que o app não conhece aparece pelo id, com o ícone etiqueta; sem gasto, "R$ 0,00" (abaixo de mil, a moeda
        // inteira, com o espaço fixo do site).
        #expect(linhas[3].nome == "c_apagado")
        #expect(linhas[3].icone == "etiqueta")
        #expect(linhas[3].gasto == "R$\u{a0}0,00")
        let fora = linhasForaDoOrcamento(r, topicos: mapaDeTopicos([]))
        #expect(fora == [LinhaDeTopicoDoOrcamento(id: "projeto", nome: "Documentação", icone: "documento", gasto: "R$ 23 mil",
                                                   previsto: nil, item: nil, frase: nil)])
    }

    @Test func gastoPorTopicoComAParteDaObra() {
        let o = obra(.objeto(["modo": .texto("total"), "total": .numero(1_000_000)]),
                     gastos: [("terreno", 319_847.85), ("revest", 76_700), ("c_meu", 2_000)])
        let proprio = TopicoProprio(campos: ["id": .texto("c_meu"), "nm": .texto("Gesso"), "ic": .texto("etiqueta")])
        let linhas = linhasDoGastoPorTopico(gastoPorTopico(o, hoje: "2026-10-20", taxaMensal: 1), topicos: mapaDeTopicos([proprio]))
        #expect(linhas.map(\.nome) == ["Terreno", "Cerâmica", "Gesso"])
        #expect(linhas.map(\.gasto) == ["R$ 320 mil", "R$ 77 mil", "R$ 2 mil"])
        #expect(linhas.map(\.frase) == ["80% da obra", "19% da obra", "1% da obra"])
        #expect(linhas.allSatisfy { $0.previsto == nil && $0.item == nil && !$0.fraseEmAlerta })
    }

    /// As frases do cartão, partidas em volta do dinheiro (na letra grande ele vai para a própria linha), são as do núcleo.
    @Test func frasesDoCartaoIguaisAsDoNucleo() throws {
        let casos = [obra(porTopico, gastos: [("estrutura", 91_200), ("projeto", 22_880.5)]),
                     obra(.objeto(["modo": .texto("topicos"), "topicos": .objeto(["estrutura": .numero(85_000)])]), gastos: []),
                     obra(.objeto(["modo": .texto("total"), "total": .numero(1_200_000)]), gastos: [("terreno", 10)])]
        for o in casos {
            let r = try #require(orcamentoObra(o))
            let p = partesDoPrevisto(r)
            #expect([p.antes, p.valor, p.depois].filter { !$0.isEmpty }.joined(separator: " ") == previstoDoCartao(r))
            let f = partesDoFora(r)
            #expect(f.map { "\($0.antes) \($0.valor) \($0.depois)" } == fraseDoForaNoCartao(r))
        }
    }

    /// O valor da linha não quebra: o nome quebra antes (o `white-space: nowrap` do mockup). Na letra grande, na própria
    /// linha, quebra se precisar.
    @MainActor @Test func valorDaLinhaNaoQuebra() {
        func altura(_ largura: CGFloat, _ letra: DynamicTypeSize) -> CGFloat {
            UIHostingController(rootView: ValorDoTopicoNoOrcamento(gasto: "R$ 320 mil", previsto: "320 mil").dynamicTypeSize(letra)
                .environment(\.displayScale, 1))
                .sizeThatFits(in: CGSize(width: largura, height: CGFloat.infinity)).height
        }
        #expect(altura(60, .large) == altura(1000, .large), "numa linha só, mesmo sem largura")
        #expect(altura(60, .accessibility5) > altura(1000, .accessibility5), "na letra grande, quebra")
    }

    /// A frase do "passou" no âmbar sobre o vidro (#6F4705 no claro, #FFD98A no escuro); as outras, fora do âmbar.
    @MainActor @Test func fraseDoPassouNoAmbarSobreOVidro() throws {
        func cor(_ alerta: Bool, _ esquema: ColorScheme) throws -> [UInt8] {
            let r = ImageRenderer(content: FraseDoTopicoNoOrcamento(texto: "Passou R$ 6,2 mil do previsto", alerta: alerta)
                .environment(\.paleta, Paleta(pele: .esmeralda)).environment(\.colorScheme, esquema))
            r.scale = 3
            let imagem = try #require(r.cgImage)
            let (w, h) = (imagem.width, imagem.height)
            var rgba = [UInt8](repeating: 0, count: w * h * 4)
            rgba.withUnsafeMutableBytes { bytes in
                CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                    .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
            }
            let opacos = stride(from: 0, to: rgba.count, by: 4).filter { rgba[$0 + 3] == 255 }.map { Array(rgba[$0..<$0 + 3]) }
            return Dictionary(grouping: opacos, by: { $0 }).max { $0.value.count < $1.value.count }?.key ?? []
        }
        #expect(try cor(true, .light) == [0x6F, 0x47, 0x05])
        #expect(try cor(true, .dark) == [0xFF, 0xD9, 0x8A])
        #expect(try cor(false, .light) != [0x6F, 0x47, 0x05] && cor(false, .dark) != [0xFF, 0xD9, 0x8A], "a frase que não é do passou")
    }
}
```

Em `app-ios/CusttaUITests/OrcamentoUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/OrcamentoUITests.swift
+++ b/app-ios/CusttaUITests/OrcamentoUITests.swift
@@ -1,8 +1,10 @@
 import XCTest
+import notify
 
 /* O orçamento (etapa 3, PR 1), com a vitrine e os orçamentos do mockup aprovado (VitrineDoOrcamento.swift): a linha nos
    indicadores, logo abaixo do Total gasto, nos três níveis do site, por total e por tópico, com o aviso dos tópicos e o que
-   está fora; sem orçamento, nenhuma linha; a obra vendida com orçamento mostra a linha, como o site. */
+   está fora; sem orçamento, nenhuma linha; a obra vendida com orçamento mostra a linha, como o site. A linha abre a tela
+   Orçamento: o cartão, o "Por tópico" com as frases do site e o que está fora; no modo total, o gasto por tópico e a dica. */
 @MainActor
 final class OrcamentoUITests: XCTestCase {
     override func setUp() { continueAfterFailure = false }
@@ -42,11 +44,11 @@ final class OrcamentoUITests: XCTestCase {
         let (app, _) = linha("porTopico")
         let total = app.elemento("indicadorTotal").frame, orcamento = app.elemento("indicadorOrcamento").frame
         let corrigido = app.elemento("indicadorCorrigido").frame
-        // O grupo começa 10 pt abaixo do Total gasto e o texto da linha, 13 abaixo do alto do grupo (o quadro de acessibilidade
-        // da linha começa no texto).
-        XCTAssertEqual(orcamento.minY - total.maxY, 10 + 13, accuracy: 1, "a primeira linha do grupo, logo abaixo do Total gasto")
+        // O grupo começa 10 pt abaixo do Total gasto, e a linha inteira é o botão que abre a tela Orçamento: o quadro dela começa
+        // no alto e na borda do grupo, 18 pt antes do texto do Corrigido (o quadro de uma linha sem toque começa no texto).
+        XCTAssertEqual(orcamento.minY - total.maxY, 10, accuracy: 1, "a primeira linha do grupo, logo abaixo do Total gasto")
         XCTAssertLessThanOrEqual(orcamento.maxY, corrigido.minY, "antes do Corrigido")
-        XCTAssertEqual(orcamento.minX, corrigido.minX, accuracy: 0.5, "no mesmo grupo")
+        XCTAssertEqual(orcamento.minX + 18, corrigido.minX, accuracy: 0.5, "no mesmo grupo")
     }
 
     func testSemOrcamentoNenhumaLinha() {
@@ -61,3 +63,112 @@ final class OrcamentoUITests: XCTestCase {
         XCTAssertTrue(rotulo.contains("perto do limite") && rotulo.contains("98% usado de R$\u{a0}1.000.000,00"), rotulo)
     }
 }
+
+
+extension OrcamentoUITests {
+    /// A linha abre a tela Orçamento (push do sistema, no caminho de Obras), que volta pelo círculo e pela borda.
+    func testLinhaAbreATelaOrcamentoQueVoltaPeloCirculoEPelaBorda() {
+        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "obra:v1")
+        let linha = app.elemento("indicadorOrcamento")
+        XCTAssertTrue(linha.waitForExistence(timeout: 10))
+        linha.tap()
+        let titulo = app.elemento("tituloDoOrcamento")
+        XCTAssertTrue(titulo.waitForExistence(timeout: 5), "a tela Orçamento abriu")
+        XCTAssertEqual(titulo.label, "Orçamento")
+        app.navigationBars.buttons.firstMatch.tap()
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "o círculo volta para a obra")
+        linha.tap()
+        XCTAssertTrue(titulo.waitForExistence(timeout: 5))
+        app.voltarPelaBorda()
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "a borda volta para a obra")
+    }
+
+    /// O cartão do site com o que o mockup acrescenta: os tópicos previstos e a frase do que está fora (achado 10).
+    func testCartaoPorTopico() {
+        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1")
+        let cartao = app.elemento("cartaoDoOrcamento")
+        XCTAssertTrue(cartao.waitForExistence(timeout: 10))
+        for texto in ["Orçamento por tópico", "dentro do previsto", "R$\u{a0}812.536,95", "de R$\u{a0}1.019.847,85 previstos em 14 tópicos",
+                      "80% usado", "sobra", "R$\u{a0}207.310,90", "Os R$\u{a0}29.780,50 fora do orçamento não entram nesta conta."] {
+            XCTAssertTrue(cartao.label.contains(texto), "\"\(texto)\" em \"\(cartao.label)\"")
+        }
+        XCTAssertTrue(app.elemento("porTopico").label.contains("14"), app.elemento("porTopico").label)
+    }
+
+    /// "Por tópico" com as frases do site, na ordem do site (quem gastou mais do previsto primeiro), e uma linha por tópico
+    /// fora do orçamento. Neste PR as linhas não abrem nada: nenhuma é botão.
+    func testPorTopicoComAsFrasesDoSiteEOsTopicosFora() {
+        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1")
+        XCTAssertTrue(app.elemento("cartaoDoOrcamento").waitForExistence(timeout: 10))
+        let casos = [
+            ("estrutura", ["Estrutura", "R$ 91 mil", "/ 85 mil", "Passou R$ 6,2 mil do previsto"]),
+            ("fundacao", ["Fundação", "R$ 64 mil", "/ 60 mil", "Passou R$ 4,2 mil do previsto"]),
+            ("terreno", ["Terreno", "R$ 320 mil", "/ 320 mil", "Chegou ao previsto — 100%"]),
+            ("revest", ["Cerâmica", "R$ 77 mil", "/ 80 mil", "Faltam R$ 3,3 mil — 96%"]),
+        ]
+        var anterior: CGFloat = 0
+        for (id, textos) in casos {
+            let linha = app.elemento("topicoOrc-\(id)")
+            app.rolarAte(linha)
+            for texto in textos { XCTAssertTrue(linha.label.contains(texto), "\(id): \"\(texto)\" em \"\(linha.label)\"") }
+            XCTAssertGreaterThan(linha.frame.minY, anterior, "\(id) na ordem do site")
+            anterior = linha.frame.minY
+            XCTAssertFalse(app.buttons["topicoOrc-\(id)"].exists, "\(id): neste PR a linha não abre o detalhe")
+        }
+        let acabamento = app.elemento("topicoOrc-acabamento")
+        app.rolarAte(acabamento)
+        XCTAssertTrue(acabamento.label.contains("R$\u{a0}0,00") && acabamento.label.contains("/ 60 mil"), acabamento.label)
+        XCTAssertFalse(acabamento.label.contains("Faltam"), "dentro do previsto, sem frase")
+        let fora = app.elemento("foraDoOrcamento")
+        app.rolarAte(app.elemento("foraOrc-pintura"))
+        XCTAssertTrue(fora.label.contains("Fora do orçamento") && fora.label.contains("R$\u{a0}29.780,50"), fora.label)
+        XCTAssertTrue(app.staticTexts["Tópico sem valor não entra na comparação."].exists)
+        for (id, nome, gasto) in [("projeto", "Documentação", "R$ 23 mil"), ("pintura", "Pintura", "R$ 6,9 mil")] {
+            let linha = app.elemento("foraOrc-\(id)")
+            XCTAssertTrue(linha.label.contains(nome) && linha.label.contains(gasto), linha.label)
+            XCTAssertFalse(app.buttons["foraOrc-\(id)"].exists, "\(id): neste PR a linha não abre o detalhe")
+        }
+        XCTAssertLessThan(app.elemento("foraOrc-projeto").frame.minY, app.elemento("foraOrc-pintura").frame.minY, "do maior gasto ao menor")
+    }
+
+    /// No modo total não há "Por tópico": o "Gasto por tópico" (bruto e % da obra) e, no fim, a dica do lápis.
+    func testModoTotalComOGastoPorTopicoEADica() {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "orcamento:v1")
+        let cartao = app.elemento("cartaoDoOrcamento")
+        XCTAssertTrue(cartao.waitForExistence(timeout: 10))
+        XCTAssertTrue(cartao.label.contains("Orçamento total") && cartao.label.contains("de R$\u{a0}1.200.000,00"), cartao.label)
+        XCTAssertFalse(cartao.label.contains("previstos em"), "no modo total, só o \"de R$ …\" do site")
+        XCTAssertFalse(app.elemento("porTopico").exists)
+        XCTAssertTrue(app.elemento("gastoPorTopico").label.contains("14"), app.elemento("gastoPorTopico").label)
+        let terreno = app.elemento("gastoTopico-terreno"), estrutura = app.elemento("gastoTopico-estrutura")
+        XCTAssertTrue(terreno.label.contains("Terreno") && terreno.label.contains("R$ 320 mil") && terreno.label.contains("38% da obra"),
+                      terreno.label)
+        XCTAssertLessThan(terreno.frame.minY, estrutura.frame.minY, "do maior bruto para o menor")
+        XCTAssertFalse(app.buttons["gastoTopico-terreno"].exists, "neste PR a linha não abre o detalhe")
+        let dica = app.elemento("dicaDoModoTotal")
+        app.rolarAte(dica)
+        XCTAssertEqual(dica.label, "Para comparar tópico a tópico, toque no lápis e escolha \"Por tópico\".")
+    }
+
+    /// A obra apagada em outro aparelho com a tela Orçamento aberta: a tela Orçamento e a obra saem, e volta a lista de Obras.
+    func testTelaOrcamentoVoltaParaObrasQuandoOutroAparelhoApagaAObra() {
+        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", extra: ["CUSTTA_APAGAR_REMOTO": "v1@0"])
+        XCTAssertTrue(app.elemento("cartaoDoOrcamento").waitForExistence(timeout: 10))
+        notify_post("br.com.custta.falso.apagarRemoto")
+        XCTAssertTrue(app.elemento("tituloDoOrcamento").waitForNonExistence(timeout: 10), "a tela Orçamento saiu")
+        XCTAssertTrue(app.elemento("obra-v2").waitForExistence(timeout: 5), "de volta à lista de Obras")
+        XCTAssertFalse(app.elemento("tituloDaObra").exists, "sem a obra apagada no caminho")
+        XCTAssertFalse(app.elemento("obra-v1").exists)
+    }
+
+    /// Dentro da tela Orçamento, o + lança gasto na obra dela.
+    func testMaisNaTelaOrcamentoLancaGastoNaObra() {
+        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1")
+        XCTAssertTrue(app.elemento("cartaoDoOrcamento").waitForExistence(timeout: 10))
+        let mais = app.buttons["botaoMais"]
+        XCTAssertEqual(mais.label, "Lançar gasto")
+        mais.tap()
+        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
+        XCTAssertTrue(app.elemento("tituloDaFolha").label.hasPrefix("Valor do gasto"), "a folha do gasto novo, da obra do orçamento")
+    }
+}
```

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -494,6 +494,14 @@ test('teclado de valor: ordem do telefone, teto do núcleo, "zero zero", o valor
   assert.match(t, /\.accessibilityElement\(children: \.ignore\)\n\s*\.accessibilityLabel\("Valor"\)/, 'o visor é um elemento só');
 });
 
+test('tela Orçamento: o gasto lançado pelo + dela não rola a obra por baixo', () => {
+  // Nenhum teste de tela vê isso: a obra por baixo da tela Orçamento não está à vista, e o foco do VoiceOver não chega ao
+  // XCUITest. Sem a condição, a lista escondida rolaria até o gasto novo e o foco do VoiceOver iria para uma linha fora da tela.
+  const t = ler('app-ios/Custta/Telas/ObraView.swift');
+  assert.match(t, /\.onChange\(of: folhas\.destaque\) \{ _, d in if let d, caminho\.last == \.obra\(obra\.id\) \{ mostrar\(d/,
+    'a obra só mostra o gasto salvo quando está no topo do caminho');
+});
+
 test('ações da fase: gravação recusada avisa, como o apagar e as folhas', () => {
   // Nenhum teste de tela recusa a gravação no mudar: sem o alerta, a ação recusada não faria nada ao toque.
   const t = ler('app-ios/Custta/Telas/ObraView.swift');
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | grep -E "^✖|AssertionError" | head -3
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep error: | sort -u | head -10
```
Expected: reprova `✖ tela Orçamento: o gasto lançado pelo + dela não rola a obra por baixo`, com `AssertionError [ERR_ASSERTION]: a obra só mostra o gasto salvo quando está no topo do caminho`; o `CusttaTests` não compila: `cannot find 'linhasPorTopico' in scope`, `cannot find 'LinhaDeTopicoDoOrcamento' in scope`, `cannot find 'linhasForaDoOrcamento' in scope`, `cannot find 'linhasDoGastoPorTopico' in scope`, `cannot find 'partesDoPrevisto' in scope`, `cannot find 'partesDoFora' in scope`, `cannot find 'ValorDoTopicoNoOrcamento' in scope` e `cannot find 'FraseDoTopicoNoOrcamento' in scope` (o resto é cascata da inferência). Só com os testes de tela no lugar, os novos reprovam (`XCTAssertTrue failed - a tela Orçamento abriu`; o `CUSTTA_ABRIR=orcamento:` ainda não existe).

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Identidade/Componentes.swift`:

```diff
--- a/app-ios/Custta/Identidade/Componentes.swift
+++ b/app-ios/Custta/Identidade/Componentes.swift
@@ -377,6 +377,34 @@ extension View {
     func bordaDeRolagem(abas: Bool) -> some View { modifier(BordaDeRolagem(abas: abas)) }
 }
 
+#if DEBUG
+/// Laudo de leitura e conferência visual: a tela parada numa rolagem dada (`-custta.rolagem`, em pt; o mesmo gancho de
+/// Obras). No iOS 26, quando a tela abre já com os dados (sem o carregando), a lista às vezes volta sozinha ao topo uns 2 s
+/// depois de rolada: o laudo comparou um print rolado com outro no topo (CenaNaoDeterministica na CI, em 15/10 e 17/10). Até
+/// alguém arrastar, a rolagem que sai da pedida volta.
+struct RolagemFixaDoTeste: ViewModifier {
+    @AppStorage("custta.rolagem") private var rolagemFixa = -1.0
+    @State private var posicao = ScrollPosition(edge: .top)
+    /// A rolagem fixa foi pedida e ninguém arrastou a lista depois: o gancho a segura.
+    @State private var segurando = false
+
+    func body(content: Content) -> some View {
+        content
+            .scrollPosition($posicao)
+            .task {
+                guard rolagemFixa >= 0 else { return }
+                try? await Task.sleep(for: .milliseconds(300))
+                posicao.scrollTo(y: rolagemFixa)
+                segurando = true
+            }
+            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, y in
+                if segurando, abs(y - rolagemFixa) > 0.5 { posicao.scrollTo(y: rolagemFixa) }
+            }
+            .onScrollPhaseChange { _, fase in if fase == .interacting { segurando = false } }
+    }
+}
+#endif
+
 extension View {
     /// Símbolo que não é texto (as setas). O laudo de leitura mede palavras: o apagador de texto apagava também o traço
     /// fino do símbolo, que virava uma "palavra" de nota errada. Em Debug, com `-custta.semSimbolos`, o símbolo some dos
```

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -31,13 +31,8 @@ struct ObraView: View {
     /// ela se refaz, e não a tela inteira (lista, indicadores e cartões).
     @State private var barra = BarraDaObra()
     #if DEBUG
-    /// Laudo de leitura e conferência visual: a tela parada numa rolagem dada, em pt (o mesmo gancho de Obras).
-    @AppStorage("custta.rolagem") private var rolagemFixa = -1.0
     /// Laudo e conferência visual: a linha que abre mostrando "Apagar" (`-custta.linhaAberta g027`).
     @AppStorage("custta.linhaAberta") private var linhaDeTeste = ""
-    @State private var posicao = ScrollPosition(edge: .top)
-    /// A rolagem fixa foi pedida e ninguém arrastou a lista depois: o gancho a segura.
-    @State private var segurandoARolagem = false
     #endif
 
     var body: some View {
@@ -70,7 +65,8 @@ struct ObraView: View {
                 LazyVStack(alignment: .leading, spacing: 10) {
                     TituloDaObra(nome: obra.nome)
                     PilulaDaFase(obra: obra, hoje: hoje)
-                    IndicadoresDaObraView(indicadores: indicadoresDaObra(obra, taxa: taxa, hoje: hoje), orcamento: orcamentoObra(obra))
+                    IndicadoresDaObraView(indicadores: indicadoresDaObra(obra, taxa: taxa, hoje: hoje), orcamento: orcamentoObra(obra),
+                                          rotaDoOrcamento: .orcamento(obra.id))
                     AcoesDaFaseView(fase: obra.fase) { agir($0, obra: obra) }
                         .padding(.top, 2)
                         .padding(.bottom, 14)
@@ -97,7 +93,8 @@ struct ObraView: View {
                 .contentShape(.rect)
                 .onTapGesture { if linhaAberta != nil { fecharLinha() } }
             }
-            .onChange(of: folhas.destaque) { _, d in if let d { mostrar(d, lista: lista, leitor: leitor) } }
+            // Só com a obra à vista: o gasto lançado pelo + da tela Orçamento não rola nem leva o foco aqui, por baixo dela.
+            .onChange(of: folhas.destaque) { _, d in if let d, caminho.last == .obra(obra.id) { mostrar(d, lista: lista, leitor: leitor) } }
         }
         .scrollIndicators(.hidden)
         .onScrollPhaseChange { _, fase in if fase != .idle, linhaAberta != nil { fecharLinha() } }
@@ -120,26 +117,10 @@ struct ObraView: View {
                 .tint(paleta.cor(.texto))
         }
         .pausaOFundo(enquanto: desfazendo)
-        // O título pequeno entra na barra quando o grande sai de baixo dela (como o título grande do sistema).
-        .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 44 } action: { _, saiu in
-            withAnimation(.easeOut(duration: 0.2)) { barra.tituloVisivel = saiu }
-        }
+        .tituloPequenoAoRolar(barra)
         #if DEBUG
-        .scrollPosition($posicao)
-        .task {
-            if !linhaDeTeste.isEmpty { linhaAberta = linhaDeTeste }
-            guard rolagemFixa >= 0 else { return }
-            try? await Task.sleep(for: .milliseconds(300))
-            posicao.scrollTo(y: rolagemFixa)
-            segurandoARolagem = true
-        }
-        // No iOS 26, quando a obra abre já com os dados (sem o carregando), a lista às vezes volta sozinha ao topo uns 2 s
-        // depois de rolada: o laudo comparou um print rolado com outro no topo (CenaNaoDeterministica na CI, em 15/10 e
-        // 17/10). Até alguém arrastar, a rolagem que sai da pedida volta.
-        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, y in
-            if segurandoARolagem, abs(y - rolagemFixa) > 0.5 { posicao.scrollTo(y: rolagemFixa) }
-        }
-        .onScrollPhaseChange { _, fase in if fase == .interacting { segurandoARolagem = false } }
+        .task { if !linhaDeTeste.isEmpty { linhaAberta = linhaDeTeste } }
+        .modifier(RolagemFixaDoTeste())
         #endif
         .pausaOFundoAoRolar()
         .bordaDeRolagem(abas: true)
@@ -280,6 +261,16 @@ final class BarraDaObra {
     var tituloVisivel = false
 }
 
+extension View {
+    /// O título pequeno entra na barra quando o grande sai de baixo dela, como o título grande do sistema (a obra e a tela
+    /// Orçamento). Só esmaece, sem movimento: fica igual com Reduzir movimento.
+    func tituloPequenoAoRolar(_ barra: BarraDaObra) -> some View {
+        onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 44 } action: { _, saiu in
+            withAnimation(.easeOut(duration: 0.2)) { barra.tituloVisivel = saiu }
+        }
+    }
+}
+
 /// O título pequeno só existe depois que o grande sai de baixo da barra, e sai enquanto a pílula de sincronização aparece
 /// (na barra não cabem os dois com o voltar e o lápis). Fora disso, nem fica invisível na árvore; vazio, a barra
 /// mostraria o título do sistema (branco) por cima do título grande.
```

Em `app-ios/Custta/Telas/ObrasView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObrasView.swift
+++ b/app-ios/Custta/Telas/ObrasView.swift
@@ -4,6 +4,15 @@ import CusttaNucleo
 /// Para onde se vai dentro de Obras (o caminho do NavigationStack, que mora no PrincipalView).
 enum RotaDeObras: Hashable, Sendable {
     case obra(String)
+    /// A tela Orçamento da obra (etapa 3), empurrada pela linha do orçamento.
+    case orcamento(String)
+
+    /// A obra da tela: a própria, ou a dona do orçamento.
+    var obraId: String {
+        switch self {
+        case .obra(let id), .orcamento(let id): return id
+        }
+    }
 }
 
 /* Obras: aviso de e-mail não confirmado, "N obras", um cartão de vidro por obra (fase, meses, orçamento e total
@@ -80,6 +89,7 @@ struct ObrasView: View {
             .navigationDestination(for: RotaDeObras.self) { rota in
                 switch rota {
                 case .obra(let id): ObraView(id: id, caminho: $caminho)
+                case .orcamento(let id): OrcamentoView(id: id, caminho: $caminho)
                 }
             }
         }
```

Criar `app-ios/Custta/Telas/OrcamentoView.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* A tela Orçamento (mockup aprovado da etapa 3, parte 1, seção 3): empurrada pela linha do orçamento da obra, no caminho de
   Obras, com o título grande. O cartão do site, com "previstos em N tópicos" e a frase do que está fora (no modo por tópico,
   o cartão soma só os tópicos previstos e não fecha com o Total gasto: achado 10); o "Por tópico" com as frases do site, na
   ordem do site, e uma linha por tópico fora do orçamento (no site, uma linha só, com os nomes: achado 11); no modo total, o
   "Gasto por tópico" (bruto e % da obra, na ordem da legenda do donut) e a dica do lápis. As linhas dos tópicos ainda não
   abrem nada: o detalhe do tópico chega no PR 2, e até lá elas ficam sem seta e sem toque (conselho de 19/10, decisão 3).
   Sem a obra (apagada em outro aparelho) ou sem o orçamento (tirado), a tela volta. */
struct OrcamentoView: View {
    let id: String
    @Binding var caminho: [RotaDeObras]
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @State private var barra = BarraDaObra()

    var body: some View {
        let estado = modelo.sincronizador.estado
        let obra = estado.obras.first { $0.id == id }
        if let obra, let resumo = orcamentoObra(obra) {
            conteudo(obra, resumo, estado: estado)
        } else if !modelo.sincronizador.dadosCarregados {
            ProgressView()                               // aberta antes de os dados chegarem
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Sem orçamento, volta para a obra; sem a obra, para Obras.
            Color.clear.onAppear { caminho.removeAll { $0 == .orcamento(id) || (obra == nil && $0 == .obra(id)) } }
        }
    }

    private func conteudo(_ obra: Obra, _ r: ResumoOrcamento, estado: Estado) -> some View {
        let topicos = mapaDeTopicos(estado.config.topicosProprios)
        let gastos = r.modo == "topicos" ? [] : gastoPorTopico(obra, hoje: dataLocalISO(.now, fuso: .current), taxaMensal: estado.config.taxaMensal)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                TituloDaObra(nome: "Orçamento", identificador: "tituloDoOrcamento")
                CartaoDoOrcamento(resumo: r)
                    .padding(.top, 8)
                if r.modo == "topicos" {
                    PilulaDaLista(titulo: "Por tópico", quantidade: r.topicos.count, identificador: "porTopico")
                        .padding(.top, 14)
                    CartaoDaLista {
                        ForEach(Array(linhasPorTopico(r, topicos: topicos).enumerated()), id: \.element.id) { i, linha in
                            if i > 0 { LinhaFina().padding(.leading, 67) }
                            LinhaDeTopicoNoOrcamento(linha: linha, identificador: "topicoOrc-\(linha.id)")
                        }
                    }
                    if !r.fora.isEmpty {
                        CartaoDaLista {
                            CabecalhoDoForaDoOrcamento(total: r.foraTotal)
                            Text("Tópico sem valor não entra na comparação.")
                                .font(.footnote)
                                .foregroundStyle(paleta.cor(vidro.secundario))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(EdgeInsets(top: 0, leading: 18, bottom: 4, trailing: 18))
                            ForEach(Array(linhasForaDoOrcamento(r, topicos: topicos).enumerated()), id: \.element.id) { i, linha in
                                if i > 0 { LinhaFina().padding(.leading, 67) }
                                LinhaDeTopicoNoOrcamento(linha: linha, identificador: "foraOrc-\(linha.id)")
                            }
                        }
                    }
                } else {
                    PilulaDaLista(titulo: "Gasto por tópico", quantidade: gastos.count, identificador: "gastoPorTopico")
                        .padding(.top, 14)
                    CartaoDaLista {
                        ForEach(Array(linhasDoGastoPorTopico(gastos, topicos: topicos).enumerated()), id: \.element.id) { i, linha in
                            if i > 0 { LinhaFina().padding(.leading, 67) }
                            LinhaDeTopicoNoOrcamento(linha: linha, identificador: "gastoTopico-\(linha.id)")
                        }
                    }
                    DicaDoModoTotal()
                }
            }
            .padding(.horizontal, 20)
            // O fim da lista à vista acima da cápsula de abas, como na tela da obra.
            .padding(.bottom, 98)
        }
        .scrollIndicators(.hidden)
        .tituloPequenoAoRolar(barra)
        #if DEBUG
        .modifier(RolagemFixaDoTeste())
        #endif
        .pausaOFundoAoRolar()
        .bordaDeRolagem(abas: true)
        .containerBackground(.clear, for: .navigation)
        .navigationTitle("Orçamento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: "Orçamento") }
            ToolbarItem(placement: .topBarTrailing) { IndicadorDeSincronizacao() }
                .sharedBackgroundVisibility(.hidden)
        }
    }
}
```

Em `app-ios/Custta/Telas/PecasDaObra.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDaObra.swift
+++ b/app-ios/Custta/Telas/PecasDaObra.swift
@@ -11,6 +11,7 @@ import CusttaNucleo
 /// rolagem e a pílula da fase 8 pt abaixo (2 a menos que o espaço da pilha).
 struct TituloDaObra: View {
     let nome: String
+    var identificador = "tituloDaObra"
     @Environment(\.paleta) private var paleta
 
     var body: some View {
@@ -18,7 +19,7 @@ struct TituloDaObra: View {
             .font(.largeTitle.weight(.bold))
             .foregroundStyle(paleta.cor(.texto))
             .accessibilityAddTraits(.isHeader)
-            .accessibilityIdentifier("tituloDaObra")    // antes do halo: com ele, o quadro do VoiceOver ia até a borda do halo
+            .accessibilityIdentifier(identificador)    // antes do halo: com ele, o quadro do VoiceOver ia até a borda do halo
             .frame(maxWidth: .infinity, alignment: .leading)
             .background { HaloDoTitulo(grande: false, opacidade: HaloDoTitulo.naObra, noClaro: HaloDoTitulo.naObraNoClaro) }
             .padding(EdgeInsets(top: -6, leading: 0, bottom: -2, trailing: 0))
@@ -80,6 +81,8 @@ struct EtiquetaDoIndicador: View {
 struct IndicadoresDaObraView: View {
     let indicadores: IndicadoresDaObra
     var orcamento: ResumoOrcamento? = nil
+    /// Para onde a linha do orçamento leva (a tela Orçamento da obra).
+    var rotaDoOrcamento: RotaDeObras? = nil
     @Environment(\.paleta) private var paleta
     @Environment(\.vidro) private var vidro
 
@@ -91,7 +94,14 @@ struct IndicadoresDaObraView: View {
             heroi
             VStack(spacing: 0) {
                 if let orcamento {
-                    LinhaDoOrcamento(resumo: orcamento)
+                    if let rotaDoOrcamento {
+                        NavigationLink(value: rotaDoOrcamento) { LinhaDoOrcamento(resumo: orcamento, comSeta: true) }
+                            .buttonStyle(.plain)
+                            // O Controle por Voz chama pelo nome da linha ("Tocar Orçamento"), não pelo rótulo inteiro.
+                            .accessibilityInputLabels(["Orçamento"])
+                    } else {
+                        LinhaDoOrcamento(resumo: orcamento)
+                    }
                     LinhaFina().padding(.leading, 18)
                 }
                 linha(rotulo: "Corrigido pelo banco", etiqueta: nil, valor: indicadores.corrigido, nota: indicadores.notaDoCorrigido,
@@ -181,12 +191,22 @@ struct IndicadoresDaObraView: View {
 /// "Lançamentos 46": a pílula de vidro antes da lista, nas medidas do mockup (subheadline, o número em peso médio).
 struct PilulaDeLancamentos: View {
     let quantidade: Int
+
+    var body: some View { PilulaDaLista(titulo: "Lançamentos", quantidade: quantidade, identificador: "lancamentos") }
+}
+
+/// A pílula de vidro antes de uma lista ("Lançamentos 46"; na tela Orçamento, "Por tópico 14" e "Gasto por tópico 14"): o
+/// título em subheadline semibold e o número em peso médio, no secundário.
+struct PilulaDaLista: View {
+    let titulo: String
+    let quantidade: Int
+    let identificador: String
     @Environment(\.paleta) private var paleta
     @Environment(\.vidro) private var vidro
 
     var body: some View {
         HStack(spacing: 4) {                             // um espaço de texto, como no mockup
-            Text("Lançamentos").font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
+            Text(titulo).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
             Text("\(quantidade)").font(.subheadline.weight(.medium)).foregroundStyle(paleta.cor(vidro.secundario))
         }
         .padding(.horizontal, 14)
@@ -194,7 +214,7 @@ struct PilulaDeLancamentos: View {
         .superficie(.conteudo, em: .capsule)
         .accessibilityElement(children: .combine)
         .accessibilityAddTraits(.isHeader)
-        .accessibilityIdentifier("lancamentos")
+        .accessibilityIdentifier(identificador)
     }
 }
 
```

Criar `app-ios/Custta/Telas/PecasDaTelaOrcamento.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* As peças da tela Orçamento (mockup aprovado da etapa 3, parte 1, seção 3, e "Medidas"): o cartão no estilo do herói
   (16/18 de recuo, raio 24), as linhas dos tópicos com o ícone de 38, o nome em body semibold, o valor em subheadline e a
   frase em footnote, o cabeçalho do que está fora e a dica do modo total. Textos do site (rodapeOrc, linhaTopicoOrc,
   fraseTopicoOrc) e das regras novas do app (tituloDoCartao, previstoDoCartao, fraseDoForaNoCartao, gastoPorTopico). */

/// O que uma linha de tópico da tela Orçamento mostra.
struct LinhaDeTopicoDoOrcamento: Identifiable, Equatable {
    let id: String
    let nome: String
    let icone: String
    /// O gasto, em destaque ("R$ 91 mil").
    let gasto: String
    /// O previsto, sem o "R$", no "Por tópico" ("85 mil"); nil fora dele.
    let previsto: String?
    /// A barra, no "Por tópico".
    let item: ItemOrcamento?
    /// A frase do site ("Passou R$ 6,2 mil do previsto") ou, no gasto por tópico, "38% da obra".
    let frase: String?
    /// A frase do "passou", no âmbar.
    var fraseEmAlerta = false
}

/// O tópico pelo id; o que o app não conhece (tópico próprio apagado) aparece pelo id, com o ícone etiqueta, como no site.
private func topico(_ id: String, _ topicos: [String: Topico]) -> Topico {
    topicos[id] ?? Topico(id: id, nome: id, icone: "etiqueta")
}

/// O "Por tópico": os previstos, na ordem do site (quem gastou mais do previsto primeiro).
func linhasPorTopico(_ r: ResumoOrcamento, topicos: [String: Topico]) -> [LinhaDeTopicoDoOrcamento] {
    r.topicos.map { t in
        let id = t.id ?? "", nome = topico(id, topicos), linha = linhaTopicoOrc(t), frase = fraseTopicoOrc(t)
        return LinhaDeTopicoDoOrcamento(id: id, nome: nome.nome, icone: nome.icone, gasto: linha.gasto, previsto: linha.previsto,
                                        item: t, frase: frase?.texto, fraseEmAlerta: frase?.alerta ?? false)
    }
}

/// Uma linha por tópico fora do orçamento (gasto sem previsto), do maior gasto para o menor.
func linhasForaDoOrcamento(_ r: ResumoOrcamento, topicos: [String: Topico]) -> [LinhaDeTopicoDoOrcamento] {
    r.fora.map { f in
        let t = topico(f.id, topicos)
        return LinhaDeTopicoDoOrcamento(id: f.id, nome: t.nome, icone: t.icone, gasto: moedaCurtaSemZero(f.gasto), previsto: nil,
                                        item: nil, frase: nil)
    }
}

/// O "Gasto por tópico" do modo total: o bruto e o "% da obra" de cada tópico com gasto.
func linhasDoGastoPorTopico(_ gastos: [GastoDoTopico], topicos: [String: Topico]) -> [LinhaDeTopicoDoOrcamento] {
    gastos.map { g in
        let t = topico(g.id, topicos)
        return LinhaDeTopicoDoOrcamento(id: g.id, nome: t.nome, icone: t.icone, gasto: moedaCurtaSemZero(g.bruto), previsto: nil,
                                        item: nil, frase: textoDaParteDaObra(g.pct))
    }
}

/// O "de R$ … previstos em N tópicos" do cartão partido em volta do dinheiro (previstoDoCartao do núcleo), para ele ir para a
/// própria linha na letra grande.
func partesDoPrevisto(_ r: ResumoOrcamento) -> (antes: String, valor: String, depois: String) {
    let n = r.topicos.count
    return ("de", moeda(r.geral.previsto), r.modo == "topicos" ? "previstos em \(n) tópico\(n == 1 ? "" : "s")" : "")
}

/// "Os R$ … fora do orçamento não entram nesta conta." partido em volta do dinheiro (fraseDoForaNoCartao do núcleo).
func partesDoFora(_ r: ResumoOrcamento) -> (antes: String, valor: String, depois: String)? {
    guard fraseDoForaNoCartao(r) != nil else { return nil }
    return ("Os", moeda(r.foraTotal), "fora do orçamento não entram nesta conta.")
}

/// O cartão da tela Orçamento: o título do modo e o nível, o gasto, "de {previsto} previstos em N tópicos", a barra,
/// "{pct}% usado" e quanto sobra (ou passou) e, por tópico com gasto fora, a frase de que ele não entra na conta.
struct CartaoDoOrcamento: View {
    let resumo: ResumoOrcamento
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let geral = resumo.geral, rodape = rodapeOrc(geral), previsto = partesDoPrevisto(resumo)
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) { titulo; Spacer(minLength: 8); etiqueta }
                VStack(alignment: .leading, spacing: 6) { titulo; etiqueta }
            }
            ValorEmDinheiro(texto: moeda(geral.gasto), fonte: .title.weight(.bold))
                .padding(.top, 4)
            FraseComDinheiro(antes: previsto.antes, valor: previsto.valor, depois: previsto.depois, cor: vidro.secundario)
            BarraDoOrcamento(item: geral)
                .padding(.top, 12)
                .padding(.bottom, 8)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) { usado(rodape.usado); Spacer(minLength: 12); sobra(rodape) }
                VStack(alignment: .leading, spacing: 2) { usado(rodape.usado); sobra(rodape) }
            }
            if let fora = partesDoFora(resumo) {
                LinhaFina().padding(.top, 10)
                FraseComDinheiro(antes: fora.antes, valor: fora.valor, depois: fora.depois, cor: vidro.secundario)
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("cartaoDoOrcamento")
    }

    private var titulo: some View {
        Text(tituloDoCartao(resumo)).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var etiqueta: some View {
        EtiquetaDoIndicador(texto: resumo.geral.nivel.pilula, cor: corDoNivel(resumo.geral.nivel))
    }

    /// "80% usado", o número em negrito na cor do texto.
    private func usado(_ pct: String) -> some View {
        Text("\(Text(pct).fontWeight(.semibold).foregroundStyle(paleta.cor(.texto))) usado")
            .font(.subheadline)
            .foregroundStyle(paleta.cor(vidro.secundario))
    }

    /// "sobra R$ 207.310,90", o valor em negrito na cor do texto; na letra grande, o valor na própria linha, encolhendo.
    private func sobra(_ rodape: RodapeDoOrcamento) -> some View {
        let layout = tamanho.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
                                                 : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 4))
        return layout {
            Text(rodape.rotulo).font(.subheadline).foregroundStyle(paleta.cor(vidro.secundario))
            ValorEmDinheiro(texto: rodape.valor, fonte: .subheadline.weight(.semibold))
        }
    }
}

/// Uma linha de tópico da tela Orçamento: o ícone, o nome, o gasto (e "/ previsto"), a barra fina e a frase. O valor não
/// quebra; o nome quebra antes, com o valor no meio da altura dele (o `.ot` do mockup). A linha fora do orçamento, só com o
/// nome e o gasto, fica no meio da altura do ícone. Na letra grande, sem o ícone, cada informação numa linha. A coluna da
/// seta fica reservada e vazia: neste PR a linha não abre nada (o detalhe do tópico chega no PR 2). Um elemento só para o
/// VoiceOver, sem traço de botão.
struct LinhaDeTopicoNoOrcamento: View {
    let linha: LinhaDeTopicoDoOrcamento
    let identificador: String
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        HStack(alignment: linha.item == nil && linha.frase == nil ? .center : .top, spacing: 11) {
            if !grande {
                Image(decorative: iconeDoCatalogo(linha.icone))
                    .resizable().frame(width: 20, height: 20)
                    .foregroundStyle(paleta.cor(.marca))
                    .frame(width: 38, height: 38)
                    .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 11))
                    .padding(.top, 1)
            }
            VStack(alignment: .leading, spacing: 5) {
                if grande {
                    nome
                    valor
                } else {
                    HStack(spacing: 11) {
                        nome.frame(maxWidth: .infinity, alignment: .leading)
                        valor
                    }
                }
                if let item = linha.item { BarraDoOrcamento(item: item, fina: true) }
                if let frase = linha.frase { FraseDoTopicoNoOrcamento(texto: frase, alerta: linha.fraseEmAlerta) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // A coluna da seta (14 pt; 22 na letra grande), vazia até o detalhe do tópico chegar.
            Color.clear.frame(width: grande ? 22 : 14, height: 1)
        }
        .padding(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identificador)
    }

    private var nome: some View {
        Text(linha.nome).font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var valor: some View { ValorDoTopicoNoOrcamento(gasto: linha.gasto, previsto: linha.previsto) }
}

/// A frase do site embaixo da barra ("Faltam R$ 3,3 mil — 96%"; no modo total, "38% da obra"), no secundário; a do
/// "passou", em semibold, no âmbar sobre o vidro.
struct FraseDoTopicoNoOrcamento: View {
    let texto: String
    let alerta: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        Text(texto)
            .font(.footnote.weight(alerta ? .semibold : .regular))
            .foregroundStyle(paleta.cor(alerta ? .alertaNoVidro : vidro.secundario))
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// "R$ 91 mil / 85 mil": o gasto em negrito na cor do texto e "/ previsto" no secundário. Não quebra (o `white-space: nowrap`
/// do mockup); na letra grande, na própria linha, quebra se precisar.
struct ValorDoTopicoNoOrcamento: View {
    let gasto: String
    let previsto: String?
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let negrito = Text(gasto).fontWeight(.semibold).foregroundStyle(paleta.cor(.texto))
        let texto = previsto.map { Text("\(negrito) \(Text("/ \($0)").foregroundStyle(paleta.cor(vidro.secundario)))") } ?? negrito
        return texto.font(.subheadline).fixedSize(horizontal: !tamanho.isAccessibilitySize, vertical: true)
    }
}

/// "Fora do orçamento" e o total, no cabeçalho do grupo, como o cabeçalho de um mês.
struct CabecalhoDoForaDoOrcamento: View {
    let total: Double
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack { titulo; Spacer(minLength: 8); valor }
            VStack(alignment: .leading, spacing: 2) { titulo; valor }
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(paleta.cor(vidro.secundario))
        .padding(EdgeInsets(top: 12, leading: 18, bottom: 2, trailing: 18))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("foraDoOrcamento")
    }

    private var titulo: some View { Text("Fora do orçamento") }
    private var valor: some View { ValorEmDinheiro(texto: moeda(total), fonte: .footnote.weight(.semibold), cor: vidro.secundario) }
}

/// A dica do fim da tela no modo total, numa pílula de vidro.
struct DicaDoModoTotal: View {
    @Environment(\.paleta) private var paleta

    var body: some View {
        Text(dicaDoModoTotal)
            .font(.footnote)
            .foregroundStyle(paleta.cor(.texto))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .superficie(.conteudo, em: .rect(cornerRadius: 14))
            .padding(.horizontal, 14)
            .padding(.top, 2)
            .accessibilityIdentifier("dicaDoModoTotal")
    }
}
```

Em `app-ios/Custta/Telas/PecasDoOrcamento.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDoOrcamento.swift
+++ b/app-ios/Custta/Telas/PecasDoOrcamento.swift
@@ -148,10 +148,11 @@ struct AvisoDoOrcamento: View {
 }
 
 /// A linha do orçamento nos indicadores: "Orçamento" e o nível do site, quanto sobra (ou passou), a barra, "{pct}% usado de
-/// {previsto}" e, por tópico, o pior aviso dos tópicos e o que está fora. Um elemento só para o VoiceOver, como as outras
-/// linhas dos indicadores.
+/// {previsto}" e, por tópico, o pior aviso dos tópicos e o que está fora; com a seta, ela abre a tela Orçamento (a linha
+/// inteira é o botão). Um elemento só para o VoiceOver, como as outras linhas dos indicadores.
 struct LinhaDoOrcamento: View {
     let resumo: ResumoOrcamento
+    var comSeta = false
     @Environment(\.paleta) private var paleta
     @Environment(\.vidro) private var vidro
     @Environment(\.dynamicTypeSize) private var tamanho
@@ -159,6 +160,23 @@ struct LinhaDoOrcamento: View {
     var body: some View {
         let geral = resumo.geral
         let rodape = rodapeOrc(geral)
+        HStack(spacing: 4) {
+            conteudo(geral, rodape)
+            if comSeta {
+                Image(systemName: "chevron.right")
+                    .font(.body.weight(.semibold))
+                    .foregroundStyle(paleta.cor(vidro.secundario))
+                    .accessibilityHidden(true)
+                    .foraDoLaudo()
+            }
+        }
+        .padding(EdgeInsets(top: 13, leading: 18, bottom: 13, trailing: 16))
+        .contentShape(.rect)
+        .accessibilityElement(children: .combine)
+        .accessibilityIdentifier("indicadorOrcamento")
+    }
+
+    private func conteudo(_ geral: ItemOrcamento, _ rodape: RodapeDoOrcamento) -> some View {
         VStack(alignment: .leading, spacing: 0) {
             ViewThatFits(in: .horizontal) {
                 HStack(alignment: .firstTextBaseline) { rotulo; Spacer(minLength: 8); etiqueta(geral.nivel) }
@@ -183,9 +201,6 @@ struct LinhaDoOrcamento: View {
             }
         }
         .frame(maxWidth: .infinity, alignment: .leading)
-        .padding(EdgeInsets(top: 13, leading: 18, bottom: 13, trailing: 16))
-        .accessibilityElement(children: .combine)
-        .accessibilityIdentifier("indicadorOrcamento")
     }
 
     private var rotulo: some View {
```

Em `app-ios/Custta/Telas/PrincipalView.swift`:

```diff
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -76,7 +76,7 @@ extension PrincipalView {
     private var acaoDoMais: AcaoDoMais? {
         guard aba == .obras else { return nil }
         let obras = modelo.sincronizador.estado.obras
-        guard case .obra(let id)? = caminhoDeObras.last else { return AcaoDoMais(rotulo: "Nova obra", acao: pedirNovaObra) }
+        guard let id = caminhoDeObras.last?.obraId else { return AcaoDoMais(rotulo: "Nova obra", acao: pedirNovaObra) }
         guard let obra = obras.first(where: { $0.id == id }) else { return nil }
         if obra.fase != .vendida { return AcaoDoMais(rotulo: "Lançar gasto") { folhas.aberta = .novoGasto(obraId: id) } }
         if obrasAbertas(obras).isEmpty { return AcaoDoMais(rotulo: "Nova obra", acao: pedirNovaObra) }
@@ -140,20 +140,24 @@ extension PrincipalView {
             case "novoGasto": folhas.aberta = .novoGasto(obraId: id)
             default: break
             }
-        } else if let passo, case .obra(let obraId)? = caminhoDeObras.last {
+        } else if let passo, let obraId = caminhoDeObras.last?.obraId {
             folhas.aberta = passo.hasPrefix("editar:") ? .editarGasto(obraId: obraId, gastoId: String(passo.dropFirst(7)))
                                                        : .novoGasto(obraId: obraId)
         }
     }
     #endif
 
-    /// O caminho com que Obras abre: vazio; em Debug, `CUSTTA_ABRIR=obra:<id>` abre a obra direto (testes de tela, laudo
-    /// de leitura e conferência visual).
+    /// O caminho com que Obras abre: vazio; em Debug, `CUSTTA_ABRIR=obra:<id>` abre a obra direto e
+    /// `CUSTTA_ABRIR=orcamento:<id>`, a tela Orçamento dela (testes de tela, laudo de leitura e conferência visual).
     static var caminhoInicial: [RotaDeObras] {
         #if DEBUG
         if let abrir = ProcessInfo.processInfo.environment["CUSTTA_ABRIR"], abrir.hasPrefix("obra:") {
             return [.obra(String(abrir.dropFirst(5)))]
         }
+        if let abrir = ProcessInfo.processInfo.environment["CUSTTA_ABRIR"], abrir.hasPrefix("orcamento:") {
+            let id = String(abrir.dropFirst(10))
+            return [.obra(id), .orcamento(id)]
+        }
         #endif
         return []
     }
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | tail -8 | grep -E "ℹ (pass|fail)"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | tail -5
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/OrcamentoUITests -only-testing:CusttaTests/TelaOrcamentoTests 2>&1 | grep -E "Test run with|Executed|TEST EXECUTE" | tail -4
```
Expected: `ℹ pass 47`, `ℹ fail 0`; sem aviso; os 11 de `OrcamentoUITests` passam (a linha abre a tela e volta, o cartão, o por tópico e o fora, o modo total e a dica, a obra apagada em outro aparelho, o + que lança na obra da tela); `TelaOrcamentoTests` 5 de 5.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Identidade/Componentes.swift \
  app-ios/Custta/Telas/ObraView.swift \
  app-ios/Custta/Telas/ObrasView.swift \
  app-ios/Custta/Telas/OrcamentoView.swift \
  app-ios/Custta/Telas/PecasDaObra.swift \
  app-ios/Custta/Telas/PecasDaTelaOrcamento.swift \
  app-ios/Custta/Telas/PecasDoOrcamento.swift \
  app-ios/Custta/Telas/PrincipalView.swift \
  app-ios/CusttaTests/TelaOrcamentoTests.swift \
  app-ios/CusttaUITests/OrcamentoUITests.swift \
  tests/app-ios.test.cjs
git commit -m "feat: tela Orçamento da obra" -m "A linha do orçamento ganha a seta das linhas tocáveis e abre a tela Orçamento, empurrada no caminho de Obras como a obra, com o título grande e a volta pelo círculo e pela borda. No alto vem o cartão do site (quanto já foi usado, sobra ou passou), com o que o mockup aprovado da etapa 3 acrescenta: no modo por tópico, \"previstos em N tópicos\" e a frase do que está fora, porque ali o cartão soma só os tópicos previstos e não fecha com o Total gasto. Depois, o \"Por tópico\" com as frases do site, na ordem do site, e uma linha por tópico fora do orçamento; no modo total, o \"Gasto por tópico\" (bruto e parte da obra) e, no fim, a dica do lápis. As linhas de tópico ainda não abrem nada e vêm sem seta: o detalhe do tópico chega no PR seguinte. O + da tela lança gasto na obra dela, e o destaque do gasto salvo só rola a lista da obra quando ela está à vista. O gancho de rolagem fixa dos testes vira um modificador, usado pela obra e pela tela Orçamento, e a pílula \"Lançamentos\" vira a pílula das listas."
```

### Task 17: Teclas encaixadas embaixo da folha

As teclas que a folha do orçamento usa (decisão 2 do conselho): o `TecladoEncaixado`, no rodapé da folha, com a barra das teclas (‹ › entre as linhas, o nome da linha ativa, "Pronto") e o "Salvar" da faixa. A grade de teclas sai do `TecladoDeValor` da etapa 2 para uma `GradeDeTeclas` com a tabela de tamanhos (`TamanhoDasTeclas`: `.padrao`, o de sempre, e `.encaixado`, 64 pt de teto), que os dois teclados usam; o teclado da etapa 2 não muda. A `BarraDasTeclas` entra na lista fixa do `lineLimit` da guarda.

**Files:**
- Create: `app-ios/Custta/Identidade/TecladoEncaixado.swift`
- Test (criar): `app-ios/CusttaTests/TecladoEncaixadoTests.swift`
- Modify: `app-ios/Custta/Identidade/TecladoDeValor.swift`
- Test (alterar): `tests/app-ios.test.cjs`

**Interfaces:**
- Consumes: `aplicarTecla`, `fmtCentavos` e `TeclaDeValor` (núcleo); `BotaoDaFolha` e `SeparadorDaFolha`.
- Produces: `GradeDeTeclas(centavos:tamanho:)`, `TamanhoDasTeclas` (`.padrao`, `.encaixado`), `TecladoEncaixado(centavos:nome:anterior:proximo:pronto:salvarHabilitado:salvar:)` (Tarefa 18) e `TeclaDoValor(tecla:tamanho:tocar:)`; identificadores `tecladoEncaixado`, `barraDasTeclas-anterior`, `barraDasTeclas-proximo`, `barraDasTeclas-nome`, `barraDasTeclas-pronto` e `salvarOrcamento`.

- [ ] **Step 1: Escrever os testes**

Criar `app-ios/CusttaTests/TecladoEncaixadoTests.swift`:

```swift
import Testing
import SwiftUI
@testable import Custta

/* As teclas encaixadas nas medidas do mockup (`.kv`): a faixa tem a mesma altura em 402 e em 375 pt, também com Texto em
   negrito; na letra grande as teclas param em 64 pt, a barra fica com 56 e o "Salvar" sai. Medidas num UIHostingController,
   em escala 1 (sem simulador de 375 pt). */
@MainActor
struct TecladoEncaixadoTests {
    private struct Faixa: View {
        let nome: String?
        @State private var centavos = 0
        var body: some View {
            TecladoEncaixado(centavos: $centavos, nome: nome, anterior: {}, proximo: {}, pronto: {}, salvarHabilitado: true, salvar: {})
        }
    }

    private func altura(_ nome: String?, largura: CGFloat, _ tamanho: DynamicTypeSize, negrito: Bool = false) -> CGFloat {
        UIHostingController(rootView: Faixa(nome: nome).dynamicTypeSize(tamanho).environment(\.legibilityWeight, negrito ? .bold : .regular)
            .environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: largura, height: CGFloat.infinity)).height
    }

    /// Padrão: 6 + a barra de 44 + 6 + as teclas (4 de 50 e 3 vãos de 8) + 12 + o "Salvar" de 56 = 348. Sem as setas ("Só o
    /// total"), sem a barra: 298. Na letra grande: 6 + a barra de 56 + 6 + as teclas (4 de 64 e 3 vãos de 8) = 348, sem o
    /// "Salvar"; e a barra aparece também no "Só o total", com o "Pronto".
    @Test(arguments: [CGFloat(402), 375]) func alturasDoMockup(largura: CGFloat) {
        #expect(altura("Elétrica · 9 de 71", largura: largura, .large) == 348)
        #expect(altura(nil, largura: largura, .large) == 298)
        #expect(altura("Elétrica · 9 de 71", largura: largura, .accessibility5) == 348)
        #expect(altura(nil, largura: largura, .accessibility5) == 348)
        #expect(altura("Elétrica · 9 de 71", largura: largura, .large, negrito: true) == 348)
        #expect(altura("Elétrica · 9 de 71", largura: largura, .accessibility5, negrito: true) == 348)
        #expect(altura("Esquadrias de alumínio com vidro temperado · 71 de 71", largura: largura, .large) == 348,
                "o nome comprido corta numa linha, sem crescer a barra")
    }

    /// A grade nos dois tamanhos: a do TecladoDeValor não muda (62 pt e 10 de vão; 72 na letra grande) e a encaixada tem 50 e
    /// 8 (64 na letra grande). As teclas param no AX2: na AX5, a mesma altura da AX2.
    @Test func gradeNosDoisTamanhos() {
        func altura(_ tamanho: TamanhoDasTeclas, _ letra: DynamicTypeSize) -> CGFloat {
            UIHostingController(rootView: GradeDeTeclas(centavos: .constant(0), tamanho: tamanho).dynamicTypeSize(letra)
                .environment(\.displayScale, 1))
                .sizeThatFits(in: CGSize(width: 402, height: CGFloat.infinity)).height
        }
        #expect(altura(.padrao, .large) == CGFloat(4 * 62 + 3 * 10))
        #expect(altura(.padrao, .accessibility5) == CGFloat(4 * 72 + 3 * 10))
        #expect(altura(.encaixado, .large) == CGFloat(4 * 50 + 3 * 8))
        #expect(altura(.encaixado, .accessibility2) == CGFloat(4 * 64 + 3 * 8))
        #expect(altura(.encaixado, .accessibility5) == CGFloat(4 * 64 + 3 * 8))
    }
}
```

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -458,9 +458,10 @@ test('texto cresce com a letra: lineLimit e minimumScaleFactor só no botão do
   // obra): com o nome da obra preso numa linha, ela passa na maior letra. Ficam numa linha, por decisão, o botão
   // do Google (letra travada, fora da auditoria de tipo dinâmico), o indicador de sincronização da barra, o
   // dinheiro (ValorEmDinheiro e o visor do teclado de valor, mockup da etapa 2: encolhe para caber em vez de quebrar)
-  // e os títulos da barra, o pequeno da obra e o da folha (cortam como o do sistema, em vez de empurrar os botões).
+  // e os títulos da barra, o pequeno da obra e o da folha, e o nome da linha na barra das teclas encaixadas (cortam como o do
+  // sistema, em vez de empurrar os botões).
   const fixos = new Set(['BotaoGoogle', 'IndicadorDeSincronizacao', 'ValorEmDinheiro', 'VisorDoValor', 'TituloPequenoDaBarra',
-    'TituloDaFolha']);
+    'TituloDaFolha', 'BarraDasTeclas']);
   for(const f of arquivosSwift('app-ios/Custta')){
     const t = ler(f);
     for(const m of t.matchAll(/\.(lineLimit|minimumScaleFactor)\(/g)){
@@ -490,7 +491,11 @@ test('teclado de valor: ordem do telefone, teto do núcleo, "zero zero", o valor
   assert.match(tocar, /let novo = aplicarTecla\(centavos, tecla\)\n\s*guard novo != centavos else \{ return \}\n\s*centavos = novo\n/, 'o teto e a tecla ignorada vêm do núcleo');
   assert.match(tocar, /AccessibilityNotification\.Announcement\(fmtCentavos\(novo\)\)\.post\(\)/, 'o VoiceOver ouve o valor novo a cada tecla');
   assert.match(t, /case \.duploZero: "zero zero"/);
-  assert.match(t, /TeclaDoValor\(tecla: tecla\) \{ tocar\(tecla\) \}\n\s*\.dynamicTypeSize\(\.\.\.DynamicTypeSize\.accessibility2\)/, 'as teclas param no AX2');
+  assert.match(t, /TeclaDoValor\(tecla: tecla, tamanho: tamanho\) \{ tocar\(tecla\) \}\n\s*\.dynamicTypeSize\(\.\.\.DynamicTypeSize\.accessibility2\)/, 'as teclas param no AX2');
+  // As teclas encaixadas da folha do orçamento (etapa 3) são a mesma grade: a ordem, o teto e o anúncio valem nos dois.
+  assert.match(t, /GradeDeTeclas\(centavos: \$centavos, tamanho: \.padrao\)/, 'o TecladoDeValor usa a grade');
+  assert.match(ler('app-ios/Custta/Identidade/TecladoEncaixado.swift'), /GradeDeTeclas\(centavos: \$centavos, tamanho: \.encaixado\)/,
+    'as teclas encaixadas usam a mesma grade');
   assert.match(t, /\.accessibilityElement\(children: \.ignore\)\n\s*\.accessibilityLabel\("Valor"\)/, 'o visor é um elemento só');
 });
 
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | grep -m1 AssertionError
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep error: | sort -u | head -3
```
Expected: reprova `✖ teclado de valor: ordem do telefone, teto do núcleo, "zero zero", o valor falado a cada tecla e teclas até o AX2`, com `AssertionError [ERR_ASSERTION]: as teclas param no AX2`; o `CusttaTests` não compila: `cannot find 'TecladoEncaixado' in scope`, `cannot find 'GradeDeTeclas' in scope`, `cannot find type 'TamanhoDasTeclas' in scope`.

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Identidade/TecladoDeValor.swift`:

```diff
--- a/app-ios/Custta/Identidade/TecladoDeValor.swift
+++ b/app-ios/Custta/Identidade/TecladoDeValor.swift
@@ -3,22 +3,15 @@ import CusttaNucleo
 
 /* O teclado de valor (teclado.js, mockup da etapa 2, parte 2): centavos entram pela direita, "00" e apagar, teto de
    R$ 99.999.999,99 (a tecla que passaria do teto é ignorada). As teclas vêm na ordem do telefone, 1 2 3 em cima
-   (sugestão aprovada; o site usa a da calculadora). Serve ao gasto, à venda, ao valor estimado e ao orçamento: quem usa
-   dá o rótulo do botão ("Avançar", "Pronto") e o que fazer com o valor. O botão fica desabilitado no zero, como no site;
-   nos valores opcionais da obra (valor estimado e orçamento), zero vale: é como apagar o valor. */
+   (sugestão aprovada; o site usa a da calculadora). Serve ao gasto, à venda e ao valor estimado e ao orçamento da obra
+   nova: quem usa dá o rótulo do botão ("Avançar", "Pronto") e o que fazer com o valor. O botão fica desabilitado no zero,
+   como no site; nos valores opcionais da obra (valor estimado e orçamento), zero vale: é como apagar o valor. As teclas
+   são a GradeDeTeclas, a mesma das teclas encaixadas da folha do orçamento (etapa 3). */
 struct TecladoDeValor: View {
     @Binding var centavos: Int
     let acao: String
     var permiteZero = false
     let confirmar: () -> Void
-    @Environment(\.paleta) private var paleta
-
-    private static let linhas: [[TeclaDeValor]] = [
-        [.digito(1), .digito(2), .digito(3)],
-        [.digito(4), .digito(5), .digito(6)],
-        [.digito(7), .digito(8), .digito(9)],
-        [.duploZero, .digito(0), .apagar],
-    ]
 
     var body: some View {
         VStack(spacing: 0) {
@@ -26,18 +19,7 @@ struct TecladoDeValor: View {
             VisorDoValor(centavos: centavos)
             Spacer(minLength: 12)
             Spacer(minLength: 0)
-            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
-                ForEach(Self.linhas.indices, id: \.self) { i in
-                    GridRow {
-                        ForEach(Self.linhas[i], id: \.nome) { tecla in
-                            // A letra das teclas cresce até o AX2 (mockup): o limite fica por fora, para a medida de dentro
-                            // (@ScaledMetric) já ler o tamanho limitado.
-                            TeclaDoValor(tecla: tecla) { tocar(tecla) }
-                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
-                        }
-                    }
-                }
-            }
+            GradeDeTeclas(centavos: $centavos, tamanho: .padrao)
             Button(acao, action: confirmar)
                 .buttonStyle(BotaoDaFolha())
                 .disabled(centavos == 0 && !permiteZero)
@@ -47,12 +29,57 @@ struct TecladoDeValor: View {
         .padding(.horizontal, 20)
         .padding(.bottom, 0)
     }
+}
+
+/// O tamanho das teclas: o do TecladoDeValor, que ocupa a folha, e o das teclas encaixadas embaixo da folha do orçamento
+/// (mockup da etapa 3, `.kv`). As duas crescem com a letra até o AX2.
+enum TamanhoDasTeclas: Sendable {
+    /// Teclas de 62 pt (até 72 na letra grande), raio 20, 10 de vão, letra de 30.
+    case padrao
+    /// Teclas de 50 pt (até 64 na letra grande), raio 17, 8 de vão, letra de 27.
+    case encaixado
+
+    var altura: CGFloat { self == .padrao ? 62 : 50 }
+    var alturaMaxima: CGFloat { self == .padrao ? 72 : 64 }
+    var raio: CGFloat { self == .padrao ? 20 : 17 }
+    var vao: CGFloat { self == .padrao ? 10 : 8 }
+    var letra: CGFloat { self == .padrao ? 30 : 27 }
+    var simbolo: CGFloat { self == .padrao ? 26 : 24 }
+}
+
+/// As doze teclas do teclado de valor e o que cada uma faz com os centavos: a regra do núcleo (o teto e a tecla ignorada) e
+/// o valor novo falado pelo VoiceOver a cada tecla. Serve ao TecladoDeValor e ao TecladoEncaixado.
+struct GradeDeTeclas: View {
+    @Binding var centavos: Int
+    let tamanho: TamanhoDasTeclas
+
+    static let linhas: [[TeclaDeValor]] = [
+        [.digito(1), .digito(2), .digito(3)],
+        [.digito(4), .digito(5), .digito(6)],
+        [.digito(7), .digito(8), .digito(9)],
+        [.duploZero, .digito(0), .apagar],
+    ]
+
+    var body: some View {
+        Grid(horizontalSpacing: tamanho.vao, verticalSpacing: tamanho.vao) {
+            ForEach(Self.linhas.indices, id: \.self) { i in
+                GridRow {
+                    ForEach(Self.linhas[i], id: \.nome) { tecla in
+                        // A letra das teclas cresce até o AX2 (mockup): o limite fica por fora, para a medida de dentro
+                        // (@ScaledMetric) já ler o tamanho limitado.
+                        TeclaDoValor(tecla: tecla, tamanho: tamanho) { tocar(tecla) }
+                            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
+                    }
+                }
+            }
+        }
+    }
 
     private func tocar(_ tecla: TeclaDeValor) {
         let novo = aplicarTecla(centavos, tecla)
         guard novo != centavos else { return }
         centavos = novo
-        // VoiceOver: o visor é um elemento só; a cada tecla, o valor novo é falado.
+        // VoiceOver: o valor (o visor ou a linha) é um elemento só; a cada tecla, o valor novo é falado.
         AccessibilityNotification.Announcement(fmtCentavos(novo)).post()
     }
 }
@@ -85,16 +112,27 @@ struct VisorDoValor: View {
     }
 }
 
-/// Uma tecla: 62 pt de altura, raio 20, na cor Tecla; encolhe e acende no toque. A letra (30) e a altura crescem com o
-/// tamanho de letra, como o .title; quem usa limita no AX2 (mockup). Com a letra fixa, o limite não faria nada. A altura
-/// para em 72, a do mockup na AX5: as quatro fileiras cabem com o visor e o botão.
+/// Uma tecla: 62 pt de altura, raio 20, na cor Tecla (encaixada, 50 e raio 17); encolhe e acende no toque. A letra (30;
+/// encaixada, 27) e a altura crescem com o tamanho de letra, como o .title; quem usa limita no AX2 (mockup). Com a letra
+/// fixa, o limite não faria nada. A altura para em 72 (encaixada, 64), a do mockup na AX5: as quatro fileiras cabem com o
+/// visor e o botão (encaixada, com a barra e um pedaço da lista à vista).
 struct TeclaDoValor: View {
     let tecla: TeclaDeValor
+    let tamanho: TamanhoDasTeclas
     let tocar: () -> Void
     @Environment(\.paleta) private var paleta
-    @ScaledMetric(relativeTo: .title) private var letra: CGFloat = 30
-    @ScaledMetric(relativeTo: .title) private var simbolo: CGFloat = 26
-    @ScaledMetric(relativeTo: .title) private var altura: CGFloat = 62
+    @ScaledMetric private var letra: CGFloat
+    @ScaledMetric private var simbolo: CGFloat
+    @ScaledMetric private var altura: CGFloat
+
+    init(tecla: TeclaDeValor, tamanho: TamanhoDasTeclas = .padrao, tocar: @escaping () -> Void) {
+        self.tecla = tecla
+        self.tamanho = tamanho
+        self.tocar = tocar
+        _letra = ScaledMetric(wrappedValue: tamanho.letra, relativeTo: .title)
+        _simbolo = ScaledMetric(wrappedValue: tamanho.simbolo, relativeTo: .title)
+        _altura = ScaledMetric(wrappedValue: tamanho.altura, relativeTo: .title)
+    }
 
     var body: some View {
         Button(action: tocar) {
@@ -106,9 +144,9 @@ struct TeclaDoValor: View {
                 }
             }
             .font(.system(size: letra, weight: .medium))
-            .frame(maxWidth: .infinity, minHeight: min(altura, 72))
+            .frame(maxWidth: .infinity, minHeight: min(altura, tamanho.alturaMaxima))
         }
-        .buttonStyle(EstiloDaTecla())
+        .buttonStyle(EstiloDaTecla(raio: tamanho.raio))
         .accessibilityLabel(rotulo)
         .accessibilityIdentifier("tecla-\(tecla.nome)")
     }
@@ -123,13 +161,14 @@ struct TeclaDoValor: View {
 }
 
 private struct EstiloDaTecla: ButtonStyle {
+    let raio: CGFloat
     @Environment(\.paleta) private var paleta
     @Environment(\.opcoes) private var opcoes
 
     func makeBody(configuration: Configuration) -> some View {
         configuration.label
             .foregroundStyle(paleta.cor(.texto))
-            .background(paleta.cor(configuration.isPressed ? .teclaTocada : .tecla), in: .rect(cornerRadius: 20, style: .continuous))
+            .background(paleta.cor(configuration.isPressed ? .teclaTocada : .tecla), in: .rect(cornerRadius: raio, style: .continuous))
             .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.96 : 1)
             .animation(configuration.isPressed ? .easeOut(duration: 0.1) : .spring(duration: 0.3), value: configuration.isPressed)
     }
```

Criar `app-ios/Custta/Identidade/TecladoEncaixado.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* As teclas encaixadas embaixo da folha do orçamento (mockup aprovado da etapa 3, parte 1, `.kv`; conselho de 19/10, decisão
   2): uma faixa sólida da Folha, com a linha fina em cima, com a barra (‹ › para a linha anterior e a seguinte, o nome da linha
   e "Pronto"), as teclas do teclado de valor (50 pt, 8 de vão, a mesma GradeDeTeclas do TecladoDeValor) e o "Salvar" de 56
   embaixo. Na letra de acessibilidade, as teclas param em 64 pt, o nome sai da barra e o "Salvar" sai enquanto as teclas estão
   abertas ("Pronto" fecha e ele volta). Sem as setas ("Só o total"), a barra só aparece na letra de acessibilidade, com o
   "Pronto": sem ela não sobraria nem o "Salvar" nem o "Pronto" (furo do mockup, levado ao Giovani). */
struct TecladoEncaixado: View {
    @Binding var centavos: Int
    /// "Elétrica · 9 de 71", com as setas ("Por tópico"); nil sem elas ("Só o total").
    let nome: String?
    let anterior: () -> Void
    let proximo: () -> Void
    let pronto: () -> Void
    let salvarHabilitado: Bool
    let salvar: () -> Void
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        VStack(spacing: 0) {
            if nome != nil || grande {
                // A letra da barra para no xxxLarge (lida aqui fora: dentro do limite, nunca é de acessibilidade).
                BarraDasTeclas(nome: grande ? nil : nome, setas: nome != nil, grande: grande, anterior: anterior, proximo: proximo,
                               pronto: pronto)
                    .padding(.bottom, 6)
            }
            GradeDeTeclas(centavos: $centavos, tamanho: .encaixado)
            if !grande {
                Button("Salvar", action: salvar)
                    .buttonStyle(BotaoDaFolha())
                    .disabled(!salvarHabilitado)
                    .accessibilityIdentifier("salvarOrcamento")
                    .padding(.top, 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 0)
        .background {
            paleta.cor(.folha).ignoresSafeArea(edges: .bottom).accessibilityHidden(true)
        }
        .overlay(alignment: .top) { SeparadorDaFolha(recuo: 0) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tecladoEncaixado")
    }
}

/// A barra das teclas encaixadas: ‹ › de 44 × 38 no fundo das teclas (o toque de 44 × 44), o nome da linha ativa, numa linha
/// só, e "Pronto" na cor do link. A letra para no xxxLarge, como o título da folha, com o Visualizador de Conteúdo Grande nas
/// quatro peças; na letra de acessibilidade, a barra tem 56 pt e não mostra o nome (mockup). As setas são desenho, de 16 pt
/// (não letra): a letra fixa delas aparecia na auditoria de tipo dinâmico como texto sem elemento.
struct BarraDasTeclas: View {
    let nome: String?
    let setas: Bool
    let grande: Bool
    let anterior: () -> Void
    let proximo: () -> Void
    let pronto: () -> Void
    @Environment(\.paleta) private var paleta

    var body: some View {
        HStack(spacing: 8) {
            if setas {
                seta("chevron.left", "Tópico anterior", "barraDasTeclas-anterior", anterior)
                seta("chevron.right", "Próximo tópico", "barraDasTeclas-proximo", proximo)
            }
            if let nome {
                Text(nome)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(paleta.cor(.secundarioTransparente))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .accessibilityShowsLargeContentViewer()
                    .accessibilityIdentifier("barraDasTeclas-nome")
            } else {
                Spacer(minLength: 0)
            }
            Button(action: pronto) {
                Text("Pronto")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(paleta.cor(.linkNoVidro))
                    .padding(.horizontal, 6)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityShowsLargeContentViewer()
            .accessibilityIdentifier("barraDasTeclas-pronto")
        }
        .frame(minHeight: grande ? 56 : 44)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func seta(_ simbolo: String, _ rotulo: String, _ identificador: String, _ acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            Image(systemName: simbolo)
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .frame(width: 16, height: 16)
                .foregroundStyle(paleta.cor(.texto))
                .frame(width: 44, height: 38)
                .background(paleta.cor(.tecla), in: .capsule)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(rotulo)
        .accessibilityShowsLargeContentViewer { Label(rotulo, systemImage: simbolo) }
        .accessibilityIdentifier(identificador)
    }
}
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | tail -8 | grep -E "ℹ (pass|fail)"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | tail -5
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/TecladoEncaixadoTests -only-testing:CusttaUITests/GastoUITests -only-testing:CusttaUITests/FasesUITests -only-testing:CusttaUITests/FolhaDaObraUITests -only-testing:CusttaUITests/EstadosUITests -only-testing:CusttaUITests/AuditoriaUITests/testFolhaDoGastoNoMaiorTamanho 2>&1 | grep -E "Test run with|Executed|TEST EXECUTE" | tail -4
```
Expected: `ℹ pass 47`, `ℹ fail 0`; sem aviso; `TecladoEncaixadoTests` 2 de 2 (um com duas larguras); as suítes da etapa 2 que usam o teclado de valor (o gasto, a venda, o valor estimado da obra e a vendida) e a auditoria da folha do gasto passam: a grade nova não mudou o teclado de sempre.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Identidade/TecladoDeValor.swift \
  app-ios/Custta/Identidade/TecladoEncaixado.swift \
  app-ios/CusttaTests/TecladoEncaixadoTests.swift \
  tests/app-ios.test.cjs
git commit -m "feat: teclas encaixadas embaixo da folha" -m "As doze teclas do teclado de valor saem do TecladoDeValor para a GradeDeTeclas, com a regra de sempre (o teto e a tecla ignorada vêm do núcleo, e o VoiceOver ouve o valor novo a cada tecla), e servem também ao TecladoEncaixado, as teclas encaixadas embaixo da folha do orçamento do mockup aprovado da etapa 3: uma faixa sólida com a barra (‹ › para a linha anterior e a seguinte, o nome da linha e \"Pronto\"), as teclas de 50 pt com 8 de vão e o \"Salvar\" de 56. A faixa tem a mesma altura em 402 e em 375 pt, também com Texto em negrito. Na letra de acessibilidade, as teclas param em 64 pt, a barra fica com 56, sem o nome, e o \"Salvar\" sai enquanto as teclas estão abertas; sem as setas (\"Só o total\"), a barra só aparece na letra de acessibilidade, com o \"Pronto\", para não sobrar uma faixa sem saída. O TecladoDeValor não muda: as mesmas teclas de 62 pt (72 na letra grande) e 10 de vão."
```

### Task 18: Folha do orçamento da obra

A obra sem orçamento ganha "Definir orçamento" nas ações da fase (fora da vendida, como no site), e a tela Orçamento ganha o lápis na barra; os dois abrem a folha "Orçamento da obra". Ela abre no modo salvo; no "Definir", em "Só o total", com as teclas já abertas e o "Salvar" apagado até ter valor. Por tópico, vêm os 21 tópicos fixos e depois os próprios, uma linha cada, com o total ao vivo: tocar numa linha abre as teclas encaixadas nela, ‹ › andam pelas linhas, "Pronto" fecha, e a linha ativa fica sempre inteira entre o alto da lista e as teclas, também quando a letra muda. Trocar para "Só o total" com o total vazio preenche com a soma dos tópicos e diz isso. Trocar de modo não grava; o "Salvar" grava o modo ativo pelo núcleo (Tarefa 11), guardando o que a folha não mostra. "Tirar orçamento" e o "Salvar" com tudo vazio fazem a pergunta do site; ao tirar, a tela Orçamento volta para a obra antes de a folha descer. A gravação recusada (`.naoCarregado`) avisa dentro da folha, e o toque duplo no "Salvar" ou no "Tirar" grava uma vez.

- **Desvio da decisão 2, com o porquê.** A decisão manda a âncora no meio da faixa calculada, nunca `.center`, porque no protótipo de medida as teclas ficavam por cima da lista. Aqui o alto (segmentado e total) e a faixa das teclas moram fora da `ScrollView`, num `VStack`: a área da rolagem é a própria faixa, e o `.center` dela é o meio da faixa, sem conta à parte; as linhas também não passam por baixo das teclas, e a folha é translúcida. A varredura do › nas 71 linhas (padrão e maior letra) prova a linha inteira à vista em cada passo, também ao abrir. Na letra de acessibilidade, o alto vira o primeiro filho da lista e o "Salvar" sai enquanto as teclas estão abertas, como manda a decisão.
- **Textos novos**, no padrão das folhas da etapa 2 (não estão no site nem no mockup): "Você mudou este orçamento." / "Descartar alterações" (editar) e "Você já preencheu este orçamento." / "Descartar orçamento" (definir), com "Continuar editando"; e "O orçamento continua aqui; nada foi salvo ainda." (antes de ver os dados).
- **Exceções ao mockup, por recomendação (19/10), aprovadas pelo Giovani em 21/10:** a barra só com o "Pronto" no "Só o total" na maior letra, e os dígitos e o apagar pelo teclado físico (`onKeyPress` na linha ativa). O teste de tela digita pelo teclado físico; o apagar não, porque o `typeKey` do XCUITest não entrega nenhum apagar ao app (nem `XCUIKeyboardKey.delete`, nem `"\u{8}"`, nem `.forwardDelete`), enquanto um ⌫ de verdade, pelo teclado do Mac no simulador, chega como `.delete` e apaga; a ligação do apagar fica presa por guarda Node.
- **O setter do segmentado é um fecho literal.** `Binding(get: { rascunho.modo }, set: { trocarModo($0) })`, e não `set: trocarModo`: com a referência ao método, o Swift 6.3.3 da CI (Xcode 26.6) cai ao gerar o thunk `@isolated(any)` do setter na compilação Release (`llvm::report_fatal_error`, "While emitting IR SIL function … reabstraction thunk helper … RascunhoDoOrcamento.Modo"); o Swift 6.4 do Mac compila as duas formas, e só a CI acha.
- **A linha ativa na troca de letra.** Ao trocar o tamanho da letra com as teclas abertas, as linhas mudam de altura e a rolagem ficava onde estava, com a linha ativa fora da vista (a auditoria de tipo dinâmico achou: ela começa na letra pequena); o `onChange(of: tamanho)` a devolve ao meio da faixa.
- **A lista segura a linha ativa no meio.** Na lista preguiçosa, as linhas que ela ainda não criou têm altura estimada: o `scrollTo` pode parar longe, e a lista ainda anda quando as linhas de verdade chegam. No iOS 26, na maior letra, a folha aberta com as teclas na Elétrica deixava a linha fora da vista (CI, run 39693700450: os dois prints do laudo pararam em lugares diferentes). A folha mede o meio da linha ativa (só ela, no espaço da rolagem) e, a cada mudança da rolagem ou da linha, confere onde ela ficou e rola de novo, sem animar, até 6 vezes; quem rola a lista (o dedo, o VoiceOver) leva a rolagem, e a folha para de segurar. O Mac (iOS 27) não reproduz: lá, a prova é por mutação (com o primeiro `scrollTo` três linhas abaixo, o teste novo passa com a conferência e, sem ela, a Elétrica fica a −276 pt); no iOS 26, a CI.

**Files:**
- Create: `app-ios/Custta/Telas/FolhaDoOrcamento.swift`
- Test (criar): `app-ios/CusttaTests/FolhaDoOrcamentoTests.swift`
- Test (criar): `app-ios/CusttaUITests/FolhaDoOrcamentoUITests.swift`
- Modify: `app-ios/Custta/Estado/Folhas.swift`
- Modify: `app-ios/Custta/Identidade/PecasDaFolha.swift`
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Modify: `app-ios/Custta/Telas/OrcamentoView.swift`
- Modify: `app-ios/Custta/Telas/PecasDaObra.swift`
- Modify: `app-ios/Custta/Telas/PrincipalView.swift`
- Modify: `scripts/icones-app-ios.mjs`
- Test (alterar): `tests/app-ios.test.cjs`
- Gerado: `app-ios/Custta/Assets.xcassets/Icones/` (`node scripts/icones-app-ios.mjs`)

**Interfaces:**
- Consumes: `topicosDoFormulario`, `topicosPadrao`, `orcamentoObra`, `orcamentoGravado`, `pecasOrcamento`, `somaTopicosOrc`, `totalPreenchidoOrc`, `topicosComValor`, `numParaCampo`, `lerNumero`, `reaisParaCentavos`, `centavosParaReais`, `aplicarTecla`, `fmtCentavos`, `moeda`, `Estado.salvandoOrcamento(modo:total:valores:naObra:)` e `Estado.tirandoOrcamento(daObra:)` (núcleo); `TecladoEncaixado` (Tarefa 17); `OrcamentoView` (Tarefa 16).
- Produces: `RascunhoDoOrcamento(obra:topicos:)`, com `trocarModo`, `definir`, `centavos`, `vizinho`, `nome` e `gravacao` (a conferência cruzada usa, Tarefa 20); `Folhas.Qual.orcamento(obraId:)` e `Navegacao.sairDoOrcamento(_:)`; `AcoesDaFaseView(definirOrcamento:)`, `BotaoDeEditarObra(rotulo:identificador:)` e o `SegmentadoDaFolha` com ícone opcional e `larguraToda`; `CUSTTA_FOLHA=orcamento:<id>` e `-custta.folha` = `total`, `topicos`, `teclas:<tópico>|total` (Tarefa 19); identificadores `definirOrcamento`, `editarOrcamento`, `modoDoOrcamento-<modo>`, `totalDoOrcamento`, `listaDoOrcamento`, `linhaOrc-<id>`, `linhaOrcamentoTotal`, `notaDaSoma`, `tirarOrcamento` e `salvarOrcamento`.

- [ ] **Step 1: Escrever os testes**

Os testes de tela da folha moram numa `extension OrcamentoUITests` (o `-only-testing` é pela classe `OrcamentoUITests`).

Criar `app-ios/CusttaTests/FolhaDoOrcamentoTests.swift`:

```swift
import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* O rascunho da folha do orçamento (etapa 3, PR 1): o que ele lê do orçamento ao abrir (como o formOrcamento do site), a
   soma que preenche o total ao trocar de modo, quando o "Salvar" fica apagado e o que ele entrega para gravar. */
@MainActor
struct FolhaDoOrcamentoTests {
    private func obra(_ orcamento: ValorJSON?) -> Obra {
        var arvore: [String: ValorJSON] = ["id": .texto("o"), "nome": .texto("Casa"), "fase": .texto("construcao"),
                                           "dataInicio": .texto("2026-01-01"), "gastos": .lista([])]
        if let orcamento { arvore["orcamento"] = orcamento }
        return Obra(arvore: arvore)
    }

    private let proprio = TopicoProprio(campos: ["id": .texto("c_gesso"), "nm": .texto("Gesso"), "ic": .texto("etiqueta")])
    private var linhas: [Topico] { topicosDoFormulario([proprio]) }

    @Test func semOrcamentoAbreNoTotalVazioComOSalvarApagado() {
        let r = RascunhoDoOrcamento(obra: obra(nil), topicos: linhas)
        #expect(!r.tinhaOrcamento && r.modo == .total && r.total == 0 && r.valores.isEmpty)
        #expect(r.vazio && !r.salvarHabilitado && !r.temOQuePerder)
        r.total = 120_000_000
        #expect(r.salvarHabilitado && r.temOQuePerder)
        r.trocarModo(.topicos)
        #expect(r.vazio && !r.salvarHabilitado, "por tópico, sem nenhum tópico com valor")
        r.definir(.topico("terreno"), 5_000)
        #expect(r.salvarHabilitado)
        r.definir(.topico("terreno"), 0)
        #expect(r.valores.isEmpty, "a linha zerada fica sem valor")
    }

    /// Como o site: abre no modo salvo, o total só no modo total e os tópicos só no por tópico; o tópico que a folha não
    /// mostra (próprio apagado) fica fora das linhas, para o núcleo guardá-lo.
    @Test func abreNoModoSalvoComOsValoresDele() {
        let porTopico = obra(.objeto(["modo": .texto("topicos"), "total": .numero(9),
                                      "topicos": .objeto(["terreno": .numero(319_847.85), "c_gesso": .numero(1_000), "c_apagado": .numero(7_000)])]))
        let r = RascunhoDoOrcamento(obra: porTopico, topicos: linhas)
        #expect(r.tinhaOrcamento && r.modo == .topicos && r.total == 0)
        #expect(r.valores == ["terreno": 31_984_785, "c_gesso": 100_000])
        #expect(r.comValor == "2 de 22 tópicos com valor" && moeda(r.soma) == "R$\u{a0}320.847,85")
        let total = RascunhoDoOrcamento(obra: obra(.objeto(["modo": .texto("total"), "total": .numero(1_200_000),
                                                            "topicos": .objeto(["terreno": .numero(5)])])), topicos: linhas)
        #expect(total.modo == .total && total.total == 120_000_000 && total.valores.isEmpty)
        total.definir(.total, 0)
        #expect(total.vazio && total.salvarHabilitado, "com orçamento antes, salvar vazio vale (pergunta e tira)")
    }

    /// Trocar para "Só o total" com o total vazio preenche com a soma dos tópicos e diz isso; com o total já preenchido, ou
    /// com a soma zero, nada muda. Trocar de modo é mudança: fechar pergunta.
    @Test func trocarParaOTotalPreencheComASoma() {
        let r = RascunhoDoOrcamento(obra: obra(.objeto(["modo": .texto("topicos"),
                                                        "topicos": .objeto(["terreno": .numero(319_847.85), "estrutura": .numero(85_000)])])),
                                    topicos: linhas)
        r.trocarModo(.total)
        #expect(r.modo == .total && r.total == 40_484_785 && r.nota == "Preenchido com a soma dos tópicos.")
        #expect(r.temOQuePerder)
        r.trocarModo(.topicos)
        #expect(r.nota == nil)
        r.total = 100
        r.trocarModo(.total)
        #expect(r.total == 100 && r.nota == nil, "o total preenchido fica como está")
        let vazio = RascunhoDoOrcamento(obra: obra(nil), topicos: linhas)
        vazio.trocarModo(.topicos)
        #expect(vazio.temOQuePerder, "só trocar de modo já é mudança")
        vazio.trocarModo(.total)
        #expect(vazio.total == 0 && vazio.nota == nil, "sem soma, nada a preencher")
        #expect(!vazio.temOQuePerder, "de volta ao modo de antes, nada mudou")
    }

    /// O que vai para o salvandoOrcamento: o modo ativo, o total em reais e um valor por linha da folha, a vazia com 0.
    @Test func gravacaoComUmValorPorLinha() {
        let r = RascunhoDoOrcamento(obra: obra(nil), topicos: linhas)
        r.trocarModo(.topicos)
        r.definir(.topico("c_gesso"), 123_456)
        let g = r.gravacao
        #expect(g.modo == "topicos" && g.total == 0)
        #expect(g.valores.count == 22 && g.valores["c_gesso"] == 1_234.56 && g.valores["terreno"] == 0)
    }

    /// ‹ › andam na ordem da folha (os 21 fixos e depois os próprios) e param nas pontas; o nome da barra conta a linha.
    @Test func setasENomeNaOrdemDaFolha() {
        let r = RascunhoDoOrcamento(obra: obra(nil), topicos: linhas)
        #expect(r.vizinho(.topico("terreno"), passo: -1) == nil, "na primeira, ‹ não faz nada")
        #expect(r.vizinho(.topico("terreno"), passo: 1) == .topico("projeto"))
        #expect(r.vizinho(.topico("outros"), passo: 1) == .topico("c_gesso"), "depois dos fixos, os próprios")
        #expect(r.vizinho(.topico("c_gesso"), passo: 1) == nil, "na última, › não faz nada")
        #expect(r.vizinho(.total, passo: 1) == nil)
        #expect(r.nome(.topico("eletrica")) == "Elétrica · 9 de 22" && r.nome(.total) == nil)
    }
}
```

Criar `app-ios/CusttaUITests/FolhaDoOrcamentoUITests.swift`:

```swift
import XCTest
import notify

/* A folha "Orçamento da obra" (etapa 3, PR 1): definir por total e por tópico (com ‹ › e "Pronto"), trocar de modo com o
   total vazio, salvar vazio, tirar e o caminho de volta para a obra, o teto do teclado, a folha na maior letra e a rolagem até
   a linha ativa nas 71 linhas. Com a vitrine e os orçamentos do mockup (VitrineDoOrcamento.swift). */
private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

extension OrcamentoUITests {
    /// A Casa Alphaville sem orçamento: "Definir orçamento" nas ações da fase abre a folha. Na maior letra, as ações ficam longe
    /// do alto e a lista preguiçosa só monta o botão perto da vista: rola antes de procurar.
    private func definir(_ app: XCUIApplication) {
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        let definir = app.buttons["definirOrcamento"]
        app.rolarAte(definir)
        XCTAssertTrue(definir.exists)
        definir.tap()
        XCTAssertTrue(app.elemento("tituloDaFolha").waitForExistence(timeout: 5))
    }

    private func digitar(_ app: XCUIApplication, _ teclas: String) {
        for t in teclas { app.buttons["tecla-\(t)"].tap() }
    }

    /// A tela Orçamento da obra e o lápis dela.
    private func editarPeloLapis(_ app: XCUIApplication) {
        let lapis = app.buttons["editarOrcamento"]
        XCTAssertTrue(lapis.waitForExistence(timeout: 10))
        lapis.tap()
        XCTAssertTrue(app.elemento("tituloDaFolha").waitForExistence(timeout: 5))
    }

    /// Sem orçamento, "Definir orçamento" aparece na obra em construção e na pronta; na vendida, não (achado 5, como o site).
    func testDefinirOrcamentoForaDaVendida() {
        // A ação da fase de cada obra, montada junto com o "Definir" (o mesmo grupo): à vista ela, o "Definir" também estaria.
        for (obra, acao, aparece) in [("v1", "acao-marcarPronta", true), ("v2", "acao-registrarVenda", true), ("v3", "acao-desfazerVenda", false)] {
            let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:\(obra)")
            XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
            app.rolarAte(app.buttons[acao])
            XCTAssertTrue(app.buttons[acao].exists, obra)
            XCTAssertEqual(app.buttons["definirOrcamento"].exists, aparece, obra)
            app.terminate()
        }
    }

    /// "Definir": "Só o total", com as teclas já abertas, sem a barra, o "Salvar" apagado até ter valor e sem "Tirar
    /// orçamento"; salvar mostra a linha na obra, e o "Definir" sai das ações.
    func testDefinirPorTotal() {
        let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1")
        definir(app)
        XCTAssertTrue(app.buttons["modoDoOrcamento-Só o total"].isSelected)
        XCTAssertTrue(app.buttons["tecla-1"].exists, "as teclas já abertas")
        XCTAssertFalse(app.buttons["barraDasTeclas-pronto"].exists, "no \"Só o total\", sem a barra")
        XCTAssertFalse(app.buttons["tirarOrcamento"].exists, "sem orçamento, nada a tirar")
        let salvar = app.buttons["salvarOrcamento"]
        XCTAssertFalse(salvar.isEnabled, "o \"Salvar\" apagado até ter valor")
        digitar(app, "120000000")
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}1.200.000,00")
        XCTAssertTrue(salvar.isEnabled)
        salvar.tap()
        XCTAssertTrue(salvar.waitForNonExistence(timeout: 5), "a folha desce")
        let linha = app.elemento("indicadorOrcamento")
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        XCTAssertTrue(linha.label.contains("70% usado de R$\u{a0}1.200.000,00"), linha.label)
        XCTAssertFalse(app.buttons["definirOrcamento"].exists, "com orçamento, o \"Definir\" sai")
    }

    /// Por tópico: tocar numa linha abre as teclas nela; ‹ › andam pelas linhas sem fechar as teclas; "Pronto" fecha; o
    /// total ao vivo e o que vai para a obra.
    func testDefinirPorTopicoComAsSetas() {
        let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1")
        definir(app)
        app.buttons["modoDoOrcamento-Por tópico"].tap()
        XCTAssertFalse(app.buttons["tecla-1"].exists, "trocar de modo fecha as teclas")
        XCTAssertFalse(app.buttons["salvarOrcamento"].isEnabled, "sem orçamento e nada com valor")
        app.elemento("linhaOrc-terreno").tap()
        let nome = app.staticTexts["barraDasTeclas-nome"]
        XCTAssertTrue(nome.waitForExistence(timeout: 5))
        XCTAssertEqual(nome.label, "Terreno · 1 de 21")
        digitar(app, "32000000")
        app.buttons["barraDasTeclas-proximo"].tap()
        XCTAssertEqual(nome.label, "Documentação · 2 de 21")
        digitar(app, "1000000")
        app.buttons["barraDasTeclas-anterior"].tap()
        XCTAssertEqual(nome.label, "Terreno · 1 de 21")
        app.buttons["barraDasTeclas-anterior"].tap()
        XCTAssertEqual(nome.label, "Terreno · 1 de 21", "na primeira linha, ‹ não faz nada")
        XCTAssertEqual(app.elemento("linhaOrc-projeto").value as? String, "R$\u{a0}10.000,00")
        let total = app.elemento("totalDoOrcamento").label
        XCTAssertTrue(total.contains("R$\u{a0}330.000,00") && total.contains("2 de 21 tópicos com valor"), total)
        app.buttons["barraDasTeclas-pronto"].tap()
        XCTAssertFalse(app.buttons["tecla-1"].exists, "\"Pronto\" fecha as teclas")
        app.buttons["salvarOrcamento"].tap()
        let linha = app.elemento("indicadorOrcamento")
        XCTAssertTrue(linha.waitForExistence(timeout: 5))
        XCTAssertTrue(linha.label.contains("passou do previsto") && linha.label.contains("1 tópico passou do previsto"), linha.label)
    }

    /// Trocar para "Só o total" com o total vazio preenche com a soma dos tópicos (a frase em âmbar diz isso); trocar não
    /// grava: fechar pergunta, e descartar deixa o orçamento por tópico como estava.
    func testTrocarParaSoOTotalPreencheComASomaENaoGrava() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1")
        editarPeloLapis(app)
        XCTAssertTrue(app.buttons["modoDoOrcamento-Por tópico"].isSelected, "abre no modo salvo")
        app.buttons["modoDoOrcamento-Só o total"].tap()
        XCTAssertTrue(app.staticTexts["Preenchido com a soma dos tópicos."].waitForExistence(timeout: 5))
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}1.019.847,85")
        XCTAssertTrue(app.staticTexts["Comparado com o Total gasto (bruto), com as parcelas a vencer."].exists)
        app.buttons["fecharFolha"].tap()
        let alerta = app.alerts["Você mudou este orçamento."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Descartar alterações"].tap()
        XCTAssertTrue(app.elemento("cartaoDoOrcamento").waitForExistence(timeout: 5))
        XCTAssertTrue(app.elemento("cartaoDoOrcamento").label.contains("Orçamento por tópico"), "nada foi gravado")
    }

    /// "Tirar orçamento" pergunta com o texto do site; tirar leva a tela Orçamento de volta para a obra, sem a linha e com o
    /// "Definir" de volta.
    func testTirarOrcamentoPerguntaEVoltaParaAObra() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1")
        editarPeloLapis(app)
        let tirar = app.buttons["tirarOrcamento"]
        app.rolarAte(tirar)
        tirar.tap()
        let alerta = app.alerts["Tirar o orçamento desta obra?"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["Os gastos continuam como estão."].exists)
        alerta.buttons["Cancelar"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 5))
        tirar.tap()
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Tirar orçamento"].tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "a tela Orçamento voltou para a obra")
        XCTAssertFalse(app.elemento("tituloDoOrcamento").exists)
        XCTAssertFalse(app.elemento("indicadorOrcamento").exists, "a linha sumiu da obra")
        XCTAssertTrue(app.buttons["definirOrcamento"].waitForExistence(timeout: 5))
    }

    /// Salvar com tudo vazio faz a mesma pergunta do "Tirar orçamento" (no site, tira sem perguntar).
    func testSalvarVazioPerguntaComoTirar() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "orcamento:v1")
        editarPeloLapis(app)
        app.elemento("linhaOrcamentoTotal").tap()
        for _ in 0..<9 { app.buttons["tecla-del"].tap() }
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}0,00")
        let salvar = app.buttons["salvarOrcamento"]
        XCTAssertTrue(salvar.isEnabled, "com orçamento antes, salvar vazio vale")
        salvar.tap()
        let alerta = app.alerts["Tirar o orçamento desta obra?"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Tirar orçamento"].tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5))
        XCTAssertFalse(app.elemento("indicadorOrcamento").exists)
    }

    /// O teto do teclado do app (R$ 99.999.999,99): a tecla que passaria dele é ignorada (o site não tem teto, achado 12).
    func testTetoDoTeclado() {
        let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1")
        definir(app)
        digitar(app, "99999999990")
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}99.999.999,99")
        app.buttons["tecla-00"].tap()
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}99.999.999,99")
    }

    /// Na maior letra: com as teclas abertas, o "Salvar" sai, a barra fica sem o nome e "Pronto" fecha (o "Salvar" volta); no
    /// "Só o total", a barra aparece com o "Pronto" (sem ela, não sobraria nem "Salvar" nem "Pronto").
    func testNaMaiorLetraOSalvarSaiComAsTeclas() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", argumentos: maiorLetra)
        editarPeloLapis(app)
        let linha = app.elemento("linhaOrc-terreno")
        app.rolarAte(linha)
        linha.tap()
        let pronto = app.buttons["barraDasTeclas-pronto"]
        XCTAssertTrue(pronto.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["salvarOrcamento"].exists, "com as teclas abertas, o \"Salvar\" sai")
        XCTAssertFalse(app.staticTexts["barraDasTeclas-nome"].exists, "na maior letra, sem o nome na barra")
        XCTAssertEqual(app.buttons["tecla-1"].frame.height, 64, accuracy: 0.5, "as teclas param em 64 pt")
        pronto.tap()
        XCTAssertTrue(app.buttons["salvarOrcamento"].waitForExistence(timeout: 5), "\"Pronto\" fecha e o \"Salvar\" volta")
        app.terminate()
        let sem = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1", argumentos: maiorLetra)
        definir(sem)
        XCTAssertTrue(sem.buttons["barraDasTeclas-pronto"].waitForExistence(timeout: 5), "no \"Só o total\", o \"Pronto\"")
        XCTAssertFalse(sem.buttons["barraDasTeclas-proximo"].exists, "sem as setas")
        sem.buttons["barraDasTeclas-pronto"].tap()
        XCTAssertTrue(sem.buttons["salvarOrcamento"].waitForExistence(timeout: 5))
    }

    /// Antes de ver os dados, o "Salvar" avisa com o texto do site dentro da folha, que continua aberta com o que foi digitado.
    func testSalvarAntesDeVerOsDadosAvisaENaoFecha() {
        let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1", argumentos: ["-custta.recusarGravacao", "nao-carregado"])
        definir(app)
        digitar(app, "100000")
        app.buttons["salvarOrcamento"].tap()
        let alerta = app.alerts.firstMatch
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["O orçamento continua aqui; nada foi salvo ainda."].exists)
        alerta.buttons["OK"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}1.000,00", "a folha continua, com o valor")
    }

    /// A obra apagada em outro aparelho com a folha aberta: não há onde gravar; a folha desce e, sem a obra, volta a lista de
    /// Obras.
    func testFolhaFechaQuandoOutroAparelhoApagaAObra() {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1",
                           extra: ["CUSTTA_APAGAR_REMOTO": "v1@0"])
        XCTAssertTrue(app.elemento("tituloDaFolha").waitForExistence(timeout: 10))
        notify_post("br.com.custta.falso.apagarRemoto")
        XCTAssertTrue(app.elemento("tituloDaFolha").waitForNonExistence(timeout: 10), "a folha desceu")
        XCTAssertTrue(app.elemento("obra-v2").waitForExistence(timeout: 5), "de volta à lista de Obras")
    }

    /// Teclado físico: com as teclas abertas, os dígitos entram na linha ativa. O apagar fica com a guarda Node da folha: o
    /// `typeKey` do XCTest não entrega nenhum apagar (⌫, ⌦ nem U+0008) a uma view que não é campo de texto, e o `typeText`
    /// exige um campo com o foco; o ⌫ de um teclado de verdade (o HID do teclado do Mac no simulador) chega como `.delete` e
    /// apaga (registro do PR 1, tarefa 6, 21/10).
    func testTecladoFisicoDigitaNaLinhaAtiva() {
        let app = abrirApp(conta: "senha", dados: "semOrcamento", abrir: "obra:v1")
        definir(app)
        for tecla in ["1", "2", "5"] { app.typeKey(tecla, modifierFlags: []) }
        XCTAssertEqual(app.elemento("linhaOrcamentoTotal").value as? String, "R$\u{a0}1,25")
    }

    /// Com as teclas fechadas, tocar numa linha de baixo abre as teclas e leva a linha para o meio da faixa à vista: ao abrir,
    /// a lista encolhe, e a rolagem espera a altura nova.
    func testTocarUmaLinhaDeBaixoAbreAsTeclasComElaNoMeio() throws { try tocarUmaLinhaDeBaixo(reduzirMovimento: true) }

    /// O mesmo sem Reduzir movimento, o caminho de quem não liga a opção: com a rolagem animada, a linha também termina no meio
    /// da faixa.
    func testTocarUmaLinhaDeBaixoComAnimacaoAbreAsTeclasComElaNoMeio() throws { try tocarUmaLinhaDeBaixo(reduzirMovimento: false) }

    private func tocarUmaLinhaDeBaixo(reduzirMovimento: Bool) throws {
        let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1",
                           argumentos: ["-custta.folha", "topicos"] + (reduzirMovimento ? ["-custta.reduzirMovimento", "YES"] : []))
        XCTAssertTrue(app.elemento("linhaOrc-terreno").waitForExistence(timeout: 10))
        let lista = app.elemento("listaDoOrcamento")
        // A última linha inteira à vista antes de as teclas abrirem: depois, ela ficaria embaixo delas.
        let ids = ["terreno", "projeto", "matbasicos", "fundacao", "ferragem", "estrutura", "alvenaria", "telhado", "eletrica", "hidraulica"]
        let alvo = try XCTUnwrap(ids.last { app.elemento("linhaOrc-\($0)").exists && app.elemento("linhaOrc-\($0)").frame.maxY < lista.frame.maxY - 1 })
        let linha = app.elemento("linhaOrc-\(alvo)")
        linha.tap()
        let teclas = app.elemento("tecladoEncaixado")
        XCTAssertTrue(teclas.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)
        XCTAssertGreaterThanOrEqual(linha.frame.minY, lista.frame.minY - 0.5, alvo)
        XCTAssertLessThanOrEqual(linha.frame.maxY, teclas.frame.minY + 0.5, "\(alvo): inteira acima das teclas")
        XCTAssertEqual(linha.frame.midY, (lista.frame.minY + teclas.frame.minY) / 2, accuracy: 2, "\(alvo): no meio da faixa")
    }

    /// Na maior letra, a folha aberta com as teclas numa linha longe do alto (a Elétrica, a 9ª) a mostra no meio da faixa à
    /// vista, entre a barra da folha e as teclas (2 pt de tolerância, a das outras rolagens), com e sem Reduzir movimento. Na
    /// lista preguiçosa, as linhas que ela ainda não criou têm altura estimada: no iOS 26, o primeiro `scrollTo` deixava a
    /// Elétrica fora da vista, e a folha agora confere onde ela ficou e rola de novo. Depois, quem rola a lista não é puxado de
    /// volta.
    func testNaMaiorLetraAFolhaAbreComALinhaAtivaNoMeio() {
        for reduzir in [true, false] {
            let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1",
                               argumentos: maiorLetra + ["-custta.folha", "teclas:eletrica"]
                                   + (reduzir ? ["-custta.reduzirMovimento", "YES"] : []))
            let modo = reduzir ? "com Reduzir movimento" : "com animação"
            XCTAssertTrue(app.buttons["barraDasTeclas-pronto"].waitForExistence(timeout: 10), modo)
            Thread.sleep(forTimeInterval: 1)
            let linha = app.elemento("linhaOrc-eletrica"), lista = app.elemento("listaDoOrcamento")
            let teclas = app.elemento("tecladoEncaixado")
            let barra = app.navigationBars.containing(.any, identifier: "tituloDaFolha").firstMatch
            let faixa = (max(lista.frame.minY, barra.frame.maxY), teclas.frame.minY), meio = (faixa.0 + faixa.1) / 2
            XCTAssertTrue(linha.exists, "\(modo): a Elétrica na lista")
            XCTAssertGreaterThanOrEqual(linha.frame.minY, faixa.0 - 0.5, "\(modo): abaixo da barra")
            XCTAssertLessThanOrEqual(linha.frame.maxY, faixa.1 + 0.5, "\(modo): acima das teclas")
            XCTAssertEqual(linha.frame.midY, meio, accuracy: 2, "\(modo): no meio da faixa")
            // Rolada para o alto, a lista fica onde o dedo a deixou: a Elétrica longe do meio ou fora da lista preguiçosa.
            lista.swipeDown()
            Thread.sleep(forTimeInterval: 1.5)
            XCTAssertTrue(!linha.exists || abs(linha.frame.midY - meio) > 40, "\(modo): a lista não volta para a Elétrica")
            app.terminate()
        }
    }

    /// A linha ativa fica inteira à vista entre o alto da lista e as teclas a cada ›, nas 71 linhas (os 21 fixos e os 50
    /// próprios, o limite das rules), também ao abrir; longe das pontas da lista, no meio da faixa (decisão 2).
    private func varrer(letraGrande: Bool) {
        let app = abrirApp(conta: "senha", dados: "muitosTopicos", abrir: "orcamento:v1", folha: "orcamento:v1",
                           argumentos: ["-custta.folha", "teclas:terreno", "-custta.reduzirMovimento", "YES"] + (letraGrande ? maiorLetra : []))
        let proximo = app.buttons["barraDasTeclas-proximo"]
        XCTAssertTrue(proximo.waitForExistence(timeout: 10))
        let teclas = app.elemento("tecladoEncaixado"), lista = app.elemento("listaDoOrcamento")
        // Na maior letra o alto da folha rola com a lista, que passa por baixo da barra da folha: a faixa à vista começa onde a
        // barra acaba. A barra da folha, e não a da tela Orçamento atrás dela (a primeira da árvore).
        let barra = app.navigationBars.containing(.any, identifier: "tituloDaFolha").firstMatch
        var fora: [String] = []
        var indice = 0
        func conferir(_ id: String) {
            defer { indice += 1 }
            let linha = app.elemento("linhaOrc-\(id)")
            guard linha.exists else { fora.append("\(id) sem linha"); return }
            let f = linha.frame, faixa = (max(lista.frame.minY, barra.frame.maxY), teclas.frame.minY)
            if f.minY < faixa.0 - 0.5 || f.maxY > faixa.1 + 0.5 {
                fora.append("\(id) [\(Int(f.minY))–\(Int(f.maxY))] na faixa [\(Int(faixa.0))–\(Int(faixa.1))]")
            } else if (5..<66).contains(indice), abs(f.midY - (faixa.0 + faixa.1) / 2) > 2 {
                // Longe das pontas (onde a lista não rola mais), a linha fica no meio da faixa.
                fora.append("\(id) com o meio em \(Int(f.midY)), longe do meio da faixa (\(Int((faixa.0 + faixa.1) / 2)))")
            }
        }
        conferir("terreno")
        let ids = ["projeto", "matbasicos", "fundacao", "ferragem", "estrutura", "alvenaria", "telhado", "eletrica", "hidraulica",
                   "esquadrias", "revest", "pintura", "acabamento", "piscina", "paisagismo", "maoobra", "aluguelmaq", "matextra",
                   "extras", "outros", "c_gesso"] + (2...50).map { "c_proprio\($0)" }
        for id in ids {
            proximo.tap()
            conferir(id)
        }
        XCTAssertTrue(fora.isEmpty, "linha ativa fora da faixa:\n" + fora.joined(separator: "\n"))
    }

    func testVarreduraDoProximoNas71Linhas() { varrer(letraGrande: false) }
    func testVarreduraDoProximoNas71LinhasNaMaiorLetra() { varrer(letraGrande: true) }
}
```

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -545,6 +545,37 @@ test('folha da obra e apagar obra: gravação recusada avisa, como as outras fol
   assert.match(apagar, /if resultado == \.naoCarregado \{ avisoDoMais = \.naoCarregado\(modelo\.mensagemDeNaoCarregado\) \}/);
 });
 
+test('folha do orçamento: gravação recusada avisa, e tirar o orçamento leva a tela Orçamento de volta antes de a folha descer', () => {
+  // A recusa de antes de ver os dados avisa dentro da folha, como nas outras. Tirar (pelo botão ou pelo "Salvar" vazio) volta
+  // a tela Orçamento para a obra com a folha ainda em cima, e a folha desce no turno seguinte: no mesmo turno, a navegação
+  // levaria junto a descida da folha (o achado da T34 com o gasto lançado de dentro de uma vendida). O "Tirar orçamento"
+  // confirmado não grava duas vezes.
+  const t = ler('app-ios/Custta/Telas/FolhaDoOrcamento.swift');
+  assert.equal(t.match(/case \.naoCarregado: naoCarregado = true/g)?.length, 1, 'antes de ver os dados, o alerta do site');
+  assert.match(t, /folhas\.navegar\(\.sairDoOrcamento\(rascunho\.obraId\)\)\n\s*Task \{ @MainActor in folhas\.fechar\(\) \}/,
+    'a tela Orçamento volta e, no turno seguinte, a folha desce');
+  assert.match(t.slice(t.indexOf('private func tirar() {')), /^private func tirar\(\) \{\n\s*guard folhas\.aberta != nil else \{ return \}\n/,
+    'a guarda do toque duplo também no tirar');
+  // Com Reduzir movimento, a lista vai até a linha ativa sem animar e o cursor fica parado (nenhum teste de tela vê a
+  // animação: o XCUITest espera a rolagem acabar).
+  assert.match(t, /if opcoes\.reduzirMovimento \{ leitor\.scrollTo\(campo, anchor: \.center\) \}\n\s*else \{ withAnimation/,
+    'a rolagem até a linha ativa sem animação com Reduzir movimento');
+  assert.match(t, /if opcoes\.reduzirMovimento \{\n\s*barra\(visivel: true\)/, 'o cursor parado com Reduzir movimento');
+});
+
+test('folha do orçamento: o teclado físico apaga como a tecla da tela, e a linha ativa volta ao meio quando a letra muda', () => {
+  // O ⌫ de um teclado de verdade chega à folha como .delete (U+0008) e o ⌦ como .deleteForward: os dois são a tecla de apagar
+  // da tela. Nenhum teste de tela prova isso: o typeKey do XCTest não entrega o apagar a uma view que não é campo de texto
+  // (os dígitos ele entrega, e o testTecladoFisicoDigitaNaLinhaAtiva os confere). Com a letra trocada e as teclas abertas,
+  // as linhas mudam de altura e a rolagem fica onde estava: sem voltar ao meio, a linha ativa sumia da vista (e, na auditoria
+  // de tipo dinâmico, os achados saíam sem elemento).
+  const t = ler('app-ios/Custta/Telas/FolhaDoOrcamento.swift');
+  assert.match(t, /\.onKeyPress\(keys: \[\.delete, \.deleteForward\], phases: \.down\) \{ _ in\n\s*tocar\(\.apagar, em: campo\)/,
+    'o apagar do teclado físico vai para a tecla de apagar');
+  assert.match(t, /\.onChange\(of: tamanho\) \{ if let ativo \{ rolar\(ate: ativo, leitor\) \} \}/,
+    'a linha ativa volta ao meio quando a letra muda');
+});
+
 test('folhas que gravam: o segundo toque de um toque duplo não grava de novo', () => {
   // A folha leva uns 0,4 s descendo depois de gravar, e o segundo toque de um toque duplo ainda chega no botão: sem a
   // guarda, o gasto entrava duas vezes (T22) e a obra nova também, com outro id. Os testes de tela do toque duplo falham
@@ -553,6 +584,7 @@ test('folhas que gravam: o segundo toque de um toque duplo não grava de novo',
     'app-ios/Custta/Telas/FolhaDoGasto.swift': 'private func salvar() {',
     'app-ios/Custta/Telas/FolhaDaVenda.swift': 'private func confirmar(inicio: String, hoje: String) {',
     'app-ios/Custta/Telas/FolhaDaObra.swift': 'private func salvar() {',
+    'app-ios/Custta/Telas/FolhaDoOrcamento.swift': 'private func salvar() {',
   };
   for(const [f, assinatura] of Object.entries(acoes)){
     const t = ler(f);
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | grep -E "^✖" | sort -u
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep error: | sort -u | head -3
```
Expected: reprovam `✖ folha do orçamento: gravação recusada avisa, e tirar o orçamento leva a tela Orçamento de volta antes de a folha descer`, `✖ folha do orçamento: o teclado físico apaga como a tecla da tela, e a linha ativa volta ao meio quando a letra muda` e `✖ folhas que gravam: o segundo toque de um toque duplo não grava de novo`; o `CusttaTests` não compila: `cannot find 'RascunhoDoOrcamento' in scope` (o resto é cascata da inferência). Só com os testes de tela no lugar, os da folha reprovam com `XCTAssertTrue failed` (sem "Definir", sem lápis, sem teclas).

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Estado/Folhas.swift`:

```diff
--- a/app-ios/Custta/Estado/Folhas.swift
+++ b/app-ios/Custta/Estado/Folhas.swift
@@ -15,6 +15,8 @@ final class Folhas {
         case novaObra
         case editarObra(obraId: String)
         case venda(obraId: String)
+        /// "Orçamento da obra" (etapa 3): o "Definir orçamento" da obra e o lápis da tela Orçamento.
+        case orcamento(obraId: String)
 
         var id: Self { self }
     }
@@ -45,6 +47,8 @@ final class Folhas {
         case trocar(String)
         /// Volta à lista e só então apaga a obra, para a linha sair com a animação à vista.
         case apagar(String)
+        /// O orçamento saiu (tirado na folha): a tela Orçamento, por trás da folha, volta para a obra.
+        case sairDoOrcamento(String)
     }
 
     struct PedidoDeNavegacao: Equatable {
```

Em `app-ios/Custta/Identidade/PecasDaFolha.swift`:

```diff
--- a/app-ios/Custta/Identidade/PecasDaFolha.swift
+++ b/app-ios/Custta/Identidade/PecasDaFolha.swift
@@ -221,13 +221,15 @@ struct TituloDaFolha: View {
     }
 }
 
-/// O segmentado de duas opções da folha (Pix | Cartão): o trilho em cápsula e a opção escolhida sólida. Opções de 36 pt,
-/// no mínimo 86 de largura, ícone e palavra; na letra grande, uma em cima da outra. VoiceOver lê cada opção como botão,
-/// com "1 de 2" e "selecionado", como a cápsula de abas.
+/// O segmentado de duas opções da folha (Pix | Cartão; "Só o total" | "Por tópico"): o trilho em cápsula e a opção escolhida
+/// sólida. Opções de 36 pt, no mínimo 86 de largura, ícone (se houver) e palavra; com `larguraToda`, as opções dividem a
+/// largura; na letra grande, uma em cima da outra. VoiceOver lê cada opção como botão, com "1 de 2" e "selecionado", como a
+/// cápsula de abas.
 struct SegmentadoDaFolha<Opcao: Hashable>: View {
-    let opcoes: [(valor: Opcao, rotulo: String, icone: String)]
+    let opcoes: [(valor: Opcao, rotulo: String, icone: String?)]
     @Binding var escolhida: Opcao
     var identificador: String
+    var larguraToda = false
     @Environment(\.paleta) private var paleta
     @Environment(\.dynamicTypeSize) private var tamanho
     @Environment(\.opcoes) private var opcoesDoAparelho
@@ -243,14 +245,14 @@ struct SegmentadoDaFolha<Opcao: Hashable>: View {
                     else { withAnimation(.spring(duration: 0.3, bounce: 0)) { escolhida = opcao.valor } }
                 } label: {
                     HStack(spacing: 6) {
-                        Image(decorative: opcao.icone).resizable().frame(width: 15, height: 15)
+                        if let icone = opcao.icone { Image(decorative: icone).resizable().frame(width: 15, height: 15) }
                         Text(opcao.rotulo).font(.subheadline.weight(ativa ? .semibold : .medium))
                     }
                     .fixedSize()
                     .foregroundStyle(paleta.cor(.texto))
                     .padding(.horizontal, 12)
                     .frame(minWidth: 86, minHeight: 36)
-                    .frame(maxWidth: tamanho.isAccessibilitySize ? .infinity : nil)
+                    .frame(maxWidth: tamanho.isAccessibilitySize || larguraToda ? .infinity : nil)
                     .background {
                         if ativa {
                             // A sombra do mockup (0 1px 3px): no claro, é ela que separa o branco do trilho.
```

Criar `app-ios/Custta/Telas/FolhaDoOrcamento.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* A folha "Orçamento da obra" (mockup aprovado da etapa 3, parte 1, seção 4; formOrcamento do site; conselho de 19/10,
   decisão 2). Abre no modo salvo; sem orçamento (o "Definir orçamento" das ações da fase), em "Só o total", com as teclas já
   abertas e o "Salvar" apagado até ter valor. O segmentado e o total ficam no alto, fora da lista (na letra de
   acessibilidade, rolam com ela). Por tópico: os 21 fixos e depois os próprios, uma linha cada, e o total ao vivo; trocar
   para "Só o total" com o total vazio preenche com a soma dos tópicos. O valor de cada linha entra nas teclas encaixadas
   embaixo da folha: a linha ativa acende, ‹ › andam pelas linhas e "Pronto" fecha. Trocar de modo não grava; o "Salvar"
   grava só o modo ativo (a regra 4 do site, pelo núcleo, guardando o que a folha não mostra). "Tirar orçamento" e o
   "Salvar" com tudo vazio fazem a pergunta do site, tiram o orçamento e levam a tela Orçamento de volta para a obra. */

/// A linha da folha que recebe as teclas.
enum CampoDoOrcamento: Hashable {
    case total
    case topico(String)
}

/// O formulário enquanto a folha está aberta: montado ao abrir, do orçamento da obra naquele momento (uma mudança vinda de
/// outro aparelho não o refaz), em centavos, como o teclado de valor.
@MainActor @Observable
final class RascunhoDoOrcamento {
    enum Modo: String { case total, topicos }

    let obraId: String
    /// As linhas da folha, na ordem do site: os 21 fixos e depois os próprios.
    let topicos: [Topico]
    /// A obra tinha orçamento quando a folha abriu: há o que tirar, e o "Salvar" com tudo vazio pergunta antes.
    let tinhaOrcamento: Bool
    private(set) var modo: Modo
    var total: Int
    /// O valor de cada linha; a linha sem valor fica de fora.
    var valores: [String: Int]
    /// "Preenchido com a soma dos tópicos.", depois de trocar para "Só o total" com o total vazio.
    private(set) var nota: String? = nil
    /// O formulário como abriu, para saber se algo mudou.
    private let inicial: [String]

    init(obra: Obra, topicos: [Topico]) {
        let orcamento = obra.orcamento?.comoObjeto
        // Como o site: abre no modo salvo; o total só no modo total e os tópicos só no modo por tópico.
        let modo: Modo = orcamento?["modo"] == .texto("topicos") ? .topicos : .total
        let total = modo == .total ? reaisParaCentavos(orcamento?["total"]?.comoNumero ?? 0) : 0
        let previstos = modo == .topicos ? orcamento?["topicos"]?.comoObjeto ?? [:] : [:]
        let valores = Dictionary(uniqueKeysWithValues: topicos.compactMap { t -> (String, Int)? in
            guard let reais = previstos[t.id]?.comoNumero else { return nil }
            let centavos = reaisParaCentavos(reais)
            return centavos > 0 ? (t.id, centavos) : nil
        })
        obraId = obra.id
        self.topicos = topicos
        tinhaOrcamento = orcamentoObra(obra) != nil
        self.modo = modo
        self.total = total
        self.valores = valores
        inicial = Self.foto(modo, total, valores, topicos)
    }

    /// Fechar pergunta antes quando algo mudou desde que a folha abriu (trocar de modo também).
    var temOQuePerder: Bool { Self.foto(modo, total, valores, topicos) != inicial }

    private static func foto(_ modo: Modo, _ total: Int, _ valores: [String: Int], _ topicos: [Topico]) -> [String] {
        [modo.rawValue, String(total)] + topicos.map { String(valores[$0.id] ?? 0) }
    }

    /// Nada no modo ativo.
    var vazio: Bool { modo == .total ? total == 0 : !valores.values.contains { $0 > 0 } }

    /// Sem orçamento antes, o "Salvar" fica apagado enquanto tudo está vazio; com orçamento, salvar vazio pergunta e tira.
    var salvarHabilitado: Bool { tinhaOrcamento || !vazio }

    /// Os valores das linhas em reais, na ordem da folha (vazia = 0).
    private var numeros: [Double] { topicos.map { centavosParaReais(valores[$0.id] ?? 0) } }

    /// O total ao vivo do modo por tópico (`somaTopicosOrc` do site).
    var soma: Double { somaTopicosOrc(numeros) }

    /// "14 de 22 tópicos com valor".
    var comValor: String {
        topicosComValor(Dictionary(uniqueKeysWithValues: topicos.map { ($0.id, centavosParaReais(valores[$0.id] ?? 0)) }), de: topicos.count)
    }

    /// Troca o modo sem gravar. Para "Só o total" com o total vazio, a soma dos tópicos preenche o total
    /// (`totalPreenchidoOrc` do site), com a frase que diz isso.
    func trocarModo(_ novo: Modo) {
        guard novo != modo else { return }
        modo = novo
        nota = nil
        guard novo == .total else { return }
        let campo = total == 0 ? "" : numParaCampo(centavosParaReais(total))
        let preenchido = totalPreenchidoOrc(campo, numeros)
        if campo.isEmpty, !preenchido.isEmpty {
            total = reaisParaCentavos(lerNumero(preenchido))
            nota = "Preenchido com a soma dos tópicos."
        }
    }

    /// O que o "Salvar" grava (`orcamentoGravado` pelo `salvandoOrcamento` do núcleo): o modo ativo, o total em reais e um
    /// valor por linha da folha, a vazia com 0 (é ela que separa o tópico zerado aqui, que sai, do que a folha não mostra,
    /// que fica).
    var gravacao: (modo: String, total: Double, valores: [String: Double]) {
        (modo.rawValue, centavosParaReais(total),
         Dictionary(uniqueKeysWithValues: topicos.map { ($0.id, centavosParaReais(valores[$0.id] ?? 0)) }))
    }

    /// A linha ativa nas teclas: o valor dela, que muda a cada tecla.
    func centavos(_ campo: CampoDoOrcamento) -> Int {
        switch campo {
        case .total: return total
        case .topico(let id): return valores[id] ?? 0
        }
    }

    func definir(_ campo: CampoDoOrcamento, _ centavos: Int) {
        switch campo {
        case .total: total = centavos
        case .topico(let id): valores[id] = centavos > 0 ? centavos : nil
        }
    }

    /// A linha antes ou depois na ordem da folha (‹ ›); nas pontas, nil (as setas não fazem nada, como no mockup).
    func vizinho(_ campo: CampoDoOrcamento, passo: Int) -> CampoDoOrcamento? {
        guard case .topico(let id) = campo, let i = topicos.firstIndex(where: { $0.id == id }), topicos.indices.contains(i + passo) else {
            return nil
        }
        return .topico(topicos[i + passo].id)
    }

    /// "Elétrica · 9 de 71", na barra das teclas; nil no total.
    func nome(_ campo: CampoDoOrcamento) -> String? {
        guard case .topico(let id) = campo, let i = topicos.firstIndex(where: { $0.id == id }) else { return nil }
        return "\(topicos[i].nome) · \(i + 1) de \(topicos.count)"
    }
}

struct FolhaDoOrcamento: View {
    let obraId: String
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @State private var rascunho: RascunhoDoOrcamento?
    @State private var ativoAoAbrir: CampoDoOrcamento?

    var body: some View {
        Group {
            if let rascunho {
                FolhaDoOrcamentoAberta(rascunho: rascunho, ativoAoAbrir: ativoAoAbrir)
            } else {
                Color.clear
            }
        }
        .onAppear(perform: montar)
        // A obra sumiu (apagada em outro aparelho) com a folha aberta: não há onde gravar; a folha fecha.
        .onChange(of: existe) { _, agora in if !agora { folhas.fechar() } }
    }

    private var existe: Bool { modelo.sincronizador.estado.obras.contains { $0.id == obraId } }

    private func montar() {
        guard rascunho == nil else { return }
        let estado = modelo.sincronizador.estado
        guard let obra = estado.obras.first(where: { $0.id == obraId }) else { folhas.fechar(); return }
        let r = RascunhoDoOrcamento(obra: obra, topicos: topicosDoFormulario(estado.config.topicosProprios))
        // "Definir orçamento": as teclas já abertas no total.
        ativoAoAbrir = r.tinhaOrcamento ? nil : .total
        #if DEBUG
        abrirNoPassoDeTeste(r)
        #endif
        rascunho = r
    }

    #if DEBUG
    /// Testes de tela, laudo e conferência visual (`-custta.folha`, com `CUSTTA_FOLHA=orcamento:<obra>`): `total` troca para
    /// "Só o total" (com a soma, se vazio), `topicos` para "Por tópico", `teclas:<tópico>` (ou `teclas:total`) abre as teclas
    /// na linha.
    private func abrirNoPassoDeTeste(_ r: RascunhoDoOrcamento) {
        guard let passo = UserDefaults.standard.string(forKey: "custta.folha") else { return }
        if passo == "total" { r.trocarModo(.total) }
        if passo == "topicos" { r.trocarModo(.topicos) }
        if passo.hasPrefix("teclas:") {
            let alvo = String(passo.dropFirst(7))
            if alvo != "total" { r.trocarModo(.topicos) }
            ativoAoAbrir = alvo == "total" ? .total : .topico(alvo)
        }
    }
    #endif
}

private struct FolhaDoOrcamentoAberta: View {
    @Bindable var rascunho: RascunhoDoOrcamento
    @State private var ativo: CampoDoOrcamento?
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas

    init(rascunho: RascunhoDoOrcamento, ativoAoAbrir: CampoDoOrcamento?) {
        self.rascunho = rascunho
        _ativo = State(initialValue: ativoAoAbrir)
    }

    private var nomeDaObra: String { modelo.sincronizador.estado.obras.first { $0.id == rascunho.obraId }?.nome ?? "" }

    var body: some View {
        NavigationStack {
            CorpoDaFolhaDoOrcamento(rascunho: rascunho, ativo: $ativo)
                .passoDaFolha("Orçamento da obra", subtitulo: nomeDaObra, fechar: .esquerda, raiz: true)
        }
        .folhaDoApp(perguntar: rascunho.temOQuePerder,
                    pergunta: rascunho.tinhaOrcamento ? "Você mudou este orçamento." : "Você já preencheu este orçamento.",
                    descartar: rascunho.tinhaOrcamento ? "Descartar alterações" : "Descartar orçamento") {
            folhas.fechar()
        }
    }
}

/// A rolagem até a linha ativa: guardada fora do estado observado, para a geometria mudar sem refazer a folha.
@MainActor
private final class MedidasDaFolhaDoOrcamento {
    /// A linha que espera a lista encolher para rolar até ela: ao tocar numa linha, a faixa das teclas ainda não tem altura.
    var pendente: CampoDoOrcamento?
    /// A linha que a lista segura no meio da faixa à vista até alguém rolar. Na lista preguiçosa, as linhas que ela ainda não
    /// criou têm altura estimada: o `scrollTo` pode parar longe e, quando as linhas de verdade chegam, a lista ainda anda (no
    /// iOS 26, na maior letra, a folha aberta com as teclas deixava a Elétrica fora da vista). A cada mudança da rolagem ou da
    /// linha, a folha confere onde ela ficou e, fora do lugar, rola de novo.
    var alvo: CampoDoOrcamento?
    /// Quantas vezes a conferência já rolou até o alvo (no máximo 6), e se há uma conferência marcada.
    var tentativas = 0
    var marcada = false
    /// A rolagem animada que a própria folha pediu, até parar: enquanto anda, nada se confere; outra animação (a do VoiceOver)
    /// é de quem rolou.
    var animando = false
    /// O meio da linha ativa no espaço da rolagem (só ela é medida) e a geometria da rolagem.
    var meio: (campo: CampoDoOrcamento, y: CGFloat)?
    var geometria: ScrollGeometry?

    init(alvo: CampoDoOrcamento?) { self.alvo = alvo }
}

private struct CorpoDaFolhaDoOrcamento: View {
    @Bindable var rascunho: RascunhoDoOrcamento
    @Binding var ativo: CampoDoOrcamento?
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Environment(\.dynamicTypeSize) private var tamanho
    @Environment(\.pedirParaFechar) private var pedirParaFechar
    @AccessibilityFocusState private var foco: CampoDoOrcamento?
    @FocusState private var tecladoFisico: Bool
    @State private var medidas: MedidasDaFolhaDoOrcamento
    @State private var tirando = false
    @State private var naoCarregado = false

    init(rascunho: RascunhoDoOrcamento, ativo: Binding<CampoDoOrcamento?>) {
        self.rascunho = rascunho
        _ativo = ativo
        // Aberta já com as teclas ("Definir orçamento"): a lista segura a linha ativa no meio desde a primeira medida.
        _medidas = State(initialValue: MedidasDaFolhaDoOrcamento(alvo: ativo.wrappedValue))
    }

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        VStack(spacing: 0) {
            if !grande { cabecalho }
            ScrollViewReader { leitor in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if grande { cabecalho }
                        if rascunho.modo == .topicos { linhasDosTopicos(leitor) } else { linhaDoTotal(leitor) }
                        if rascunho.tinhaOrcamento {
                            GrupoDaFolha {
                                // A linha inteira do grupo recebe o toque (o .f-lin.destr do mockup), não só o texto.
                                Button { tirando = true } label: {
                                    Text("Tirar orçamento")
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 11)
                                        .frame(maxWidth: .infinity, minHeight: 52)
                                        .contentShape(.rect)
                                }
                                .foregroundStyle(paleta.cor(.negativo))
                                .accessibilityIdentifier("tirarOrcamento")
                            }
                            .padding(.top, 28)
                        }
                    }
                    .padding(.top, grande ? 4 : 8)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .accessibilityIdentifier("listaDoOrcamento")
                // As teclas acabaram de abrir (a lista encolheu): agora a linha ativa vai para o meio da faixa à vista.
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { _ in
                    guard let pendente = medidas.pendente, ativo == pendente else { return }
                    medidas.pendente = nil
                    rolar(ate: pendente, leitor)
                }
                // A cada mudança da rolagem (as linhas que a lista preguiçosa cria, a faixa que muda), a linha que a lista segura
                // é conferida.
                .onScrollGeometryChange(for: ScrollGeometry.self) { $0 } action: { _, geometria in
                    medidas.geometria = geometria
                    conferir(leitor)
                }
                // Quem rola a lista (o dedo, o VoiceOver) leva a rolagem: a folha para de segurar a linha e não puxa ninguém de
                // volta. A rolagem animada da própria folha é conferida quando para.
                .onScrollPhaseChange { _, fase in
                    switch fase {
                    case .idle:
                        if medidas.animando {
                            medidas.animando = false
                            conferir(leitor)
                        }
                    case .animating:
                        if !medidas.animando { medidas.alvo = nil }
                    default:
                        medidas.alvo = nil
                    }
                }
                // A letra mudou com as teclas abertas (pela Central de Controle, por exemplo): as linhas mudam de altura e a rolagem
                // fica onde estava, com a linha ativa longe da vista; ela volta ao meio da faixa.
                .onChange(of: tamanho) { if let ativo { rolar(ate: ativo, leitor) } }
                .onChange(of: ativo) { antes, agora in
                    guard let agora else {
                        medidas.alvo = nil
                        return
                    }
                    foco = agora
                    anunciar(agora)
                    // Com as teclas já abertas (‹ ›), a lista não muda de altura: rola já.
                    if antes != nil { rolar(ate: agora, leitor) }
                }
            }
            if let campo = ativo {
                TecladoEncaixado(centavos: Binding(get: { rascunho.centavos(campo) }, set: { rascunho.definir(campo, $0) }),
                                 nome: rascunho.nome(campo),
                                 anterior: { ativo = rascunho.vizinho(campo, passo: -1) ?? campo },
                                 proximo: { ativo = rascunho.vizinho(campo, passo: 1) ?? campo },
                                 pronto: { ativo = nil },
                                 salvarHabilitado: rascunho.salvarHabilitado,
                                 salvar: salvar)
                    .focusable()
                    .focused($tecladoFisico)
                    .focusEffectDisabled()
                    .onAppear { tecladoFisico = true }
                    // Teclado físico: os dígitos e o apagar entram na linha ativa, como as teclas da tela.
                    .onKeyPress(characters: .decimalDigits, phases: .down) { tecla in
                        guard let d = tecla.characters.first?.wholeNumberValue else { return .ignored }
                        tocar(.digito(d), em: campo)
                        return .handled
                    }
                    // O apagar do teclado físico (o ⌫ chega como .delete, U+0008) e o apagar para a frente (⌦) tiram o último dígito,
                    // como a tecla da tela (não há cursor no valor).
                    .onKeyPress(keys: [.delete, .deleteForward], phases: .down) { _ in
                        tocar(.apagar, em: campo)
                        return .handled
                    }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if ativo == nil {
                // O identificador no próprio botão (o fundo desce até a borda; ver a folha do gasto).
                Button("Salvar", action: salvar)
                    .buttonStyle(BotaoDaFolha())
                    .disabled(!rascunho.salvarHabilitado)
                    .accessibilityIdentifier("salvarOrcamento")
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 0)
                    // O degradê da folha atrás do botão, como nas outras folhas (o .f-pe do mockup).
                    .background {
                        LinearGradient(stops: [.init(color: paleta.cor(.folha), location: 0.62), .init(color: paleta.cor(.folha).opacity(0), location: 1)],
                                       startPoint: .bottom, endPoint: .top)
                            .ignoresSafeArea()
                            .accessibilityHidden(true)
                    }
            }
        }
        // Escapar (Z com dois dedos): com as teclas abertas, fecha as teclas; sem elas, fecha a folha (pedindo antes).
        .accessibilityAction(.escape) { if ativo != nil { ativo = nil } else { pedirParaFechar() } }
        .background {
            Color.clear
                .alert("Tirar o orçamento desta obra?", isPresented: $tirando) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Tirar orçamento", role: .destructive, action: tirar)
                } message: {
                    Text("Os gastos continuam como estão.")
                }
                .tint(paleta.cor(.texto))
        }
        .background {
            Color.clear
                .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("O orçamento continua aqui; nada foi salvo ainda.")
                }
                .tint(paleta.cor(.texto))
        }
        .pausaOFundo(enquanto: tirando || naoCarregado)
    }

    // MARK: - O alto: o segmentado e o total

    private var cabecalho: some View {
        VStack(spacing: 12) {
            SegmentadoDaFolha(opcoes: [(RascunhoDoOrcamento.Modo.total, "Só o total", nil), (.topicos, "Por tópico", nil)],
                              escolhida: Binding(get: { rascunho.modo }, set: { trocarModo($0) }), identificador: "modoDoOrcamento",
                              larguraToda: true)
            if rascunho.modo == .topicos { TotalAoVivo(soma: rascunho.soma, comValor: rascunho.comValor) }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, tamanho.isAccessibilitySize ? 16 : 0)
    }

    private func trocarModo(_ modo: RascunhoDoOrcamento.Modo) {
        ativo = nil
        rascunho.trocarModo(modo)
        if let nota = rascunho.nota { AccessibilityNotification.Announcement(nota).post() }
    }

    // MARK: - As linhas

    /// Os tópicos, filhos diretos da lista preguiçosa (até 71 linhas): cada uma desenha o seu pedaço do grupo, e uma tecla
    /// refaz só a linha ativa (as outras são iguais à vez anterior).
    @ViewBuilder private func linhasDosTopicos(_ leitor: ScrollViewProxy) -> some View {
        let ultimo = rascunho.topicos.count - 1
        ForEach(Array(rascunho.topicos.enumerated()), id: \.element.id) { i, t in
            let campo = CampoDoOrcamento.topico(t.id)
            LinhaDoTopicoNaFolha(topico: t, centavos: rascunho.valores[t.id] ?? 0, ativa: ativo == campo,
                                 proprio: !topicosPadrao.contains { $0.id == t.id }, primeira: i == 0, ultima: i == ultimo)
                .equatable()
                .background { if ativo == campo { medida(campo, leitor) } }
                .onTapGesture { abrir(campo) }
                .accessibilityAction { abrir(campo) }
                .accessibilityActions {
                    if ativo == campo {
                        Button("Tópico anterior") { ativo = rascunho.vizinho(campo, passo: -1) ?? campo }
                        Button("Próximo tópico") { ativo = rascunho.vizinho(campo, passo: 1) ?? campo }
                        Button("Pronto") { ativo = nil }
                    }
                }
                .accessibilityFocused($foco, equals: campo)
                .id(campo)
        }
        NotaDaFolha(texto: "Tópico sem valor não entra na comparação.").padding(.top, 8)
    }

    /// "Orçamento total", a linha de 60 pt do valor, e as frases do modo.
    @ViewBuilder private func linhaDoTotal(_ leitor: ScrollViewProxy) -> some View {
        GrupoDaFolha {
            LinhaDoTotalNaFolha(centavos: rascunho.total, ativa: ativo == .total)
                .onTapGesture { abrir(.total) }
                .accessibilityAction { abrir(.total) }
                .accessibilityActions { if ativo == .total { Button("Pronto") { ativo = nil } } }
                .accessibilityFocused($foco, equals: .total)
        }
        .background { if ativo == .total { medida(.total, leitor) } }
        .id(CampoDoOrcamento.total)
        VStack(spacing: 8) {
            if let nota = rascunho.nota { NotaDaFolha(texto: nota, cor: .alerta, identificador: "notaDaSoma") }
            NotaDaFolha(texto: "Comparado com o Total gasto (bruto), com as parcelas a vencer.")
        }
        .padding(.top, 8)
    }

    // MARK: - As teclas

    /// Abre as teclas na linha (ou troca a linha). Ao abrir, a lista ainda não encolheu: a rolagem espera a nova altura.
    private func abrir(_ campo: CampoDoOrcamento) {
        if ativo == nil { medidas.pendente = campo }
        ativo = campo
    }

    private func tocar(_ tecla: TeclaDeValor, em campo: CampoDoOrcamento) {
        let antes = rascunho.centavos(campo), novo = aplicarTecla(antes, tecla)
        guard novo != antes else { return }
        rascunho.definir(campo, novo)
        AccessibilityNotification.Announcement(fmtCentavos(novo)).post()
    }

    /// "Elétrica, 9 de 71, R$ 30.000,00" a cada troca de linha.
    private func anunciar(_ campo: CampoDoOrcamento) {
        let valor = rascunho.centavos(campo)
        let nome = rascunho.nome(campo)?.replacingOccurrences(of: " · ", with: ", ") ?? "Orçamento total"
        AccessibilityNotification.Announcement("\(nome), \(valor > 0 ? moeda(centavosParaReais(valor)) : "sem valor")").post()
    }

    /// Põe a linha ativa no meio da faixa à vista e a segura ali até alguém rolar. A lista fica entre o alto (o segmentado e o
    /// total, ou a barra) e as teclas, que moram fora dela: o meio da rolagem é o meio da faixa (no protótipo de 19/10, com as
    /// teclas por cima da lista, a âncora mínima deixava a linha embaixo delas e o meio da rolagem errava na letra grande). Já
    /// no lugar, não rola (uma animação que não anda não avisaria que parou).
    private func rolar(ate campo: CampoDoOrcamento, _ leitor: ScrollViewProxy) {
        medidas.alvo = campo
        medidas.tentativas = 0
        guard !estaNoLugar(campo) else { return }
        medidas.animando = !opcoes.reduzirMovimento
        if opcoes.reduzirMovimento { leitor.scrollTo(campo, anchor: .center) }
        else { withAnimation(.easeOut(duration: 0.25)) { leitor.scrollTo(campo, anchor: .center) } }
    }

    /// Confere a linha que a lista segura: fora do lugar, rola de novo até ela, sem animar (até 6 vezes). A rolagem e a linha
    /// avisam em separado, e uma mudança só (a folha subindo, as teclas abrindo) dá vários avisos: a conferência fica para a
    /// vez seguinte da fila principal, com as medidas da mudança inteira.
    private func conferir(_ leitor: ScrollViewProxy) {
        guard medidas.alvo != nil, !medidas.marcada else { return }
        medidas.marcada = true
        Task { @MainActor in
            medidas.marcada = false
            guard let alvo = medidas.alvo, alvo == ativo, !medidas.animando, let g = medidas.geometria, g.containerSize.height > 0,
                  !estaNoLugar(alvo), medidas.tentativas < 6 else { return }
            medidas.tentativas += 1
            leitor.scrollTo(alvo, anchor: .center)
        }
    }

    /// A linha está onde o `scrollTo` a põe: com o meio no meio da faixa à vista, que é a moldura da rolagem (na letra grande,
    /// o que a lista tem por baixo da barra da folha fica fora dela, na margem de cima), ou, nas pontas da lista, o mais perto
    /// dele que a rolagem chega.
    private func estaNoLugar(_ campo: CampoDoOrcamento) -> Bool {
        guard let meio = medidas.meio, meio.campo == campo, let g = medidas.geometria else { return false }
        let centro = g.containerSize.height / 2, rolado = g.contentOffset.y + g.contentInsets.top
        return abs(meio.y - centro) <= 1 || (meio.y < centro && rolado <= 0.5)
            || (meio.y > centro && rolado >= g.contentSize.height - g.containerSize.height - 0.5)
    }

    /// Mede o meio da linha ativa no espaço da rolagem: é por ele que a conferência sabe onde a linha ficou.
    private func medida(_ campo: CampoDoOrcamento, _ leitor: ScrollViewProxy) -> some View {
        Color.clear
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .scrollView).midY } action: { y in
                medidas.meio = (campo, y)
                conferir(leitor)
            }
            .onDisappear { if medidas.meio?.campo == campo { medidas.meio = nil } }
    }

    // MARK: - Gravar

    private func salvar() {
        // A folha já está descendo (o primeiro toque gravou): o segundo toque de um toque duplo não grava de novo.
        guard folhas.aberta != nil else { return }
        let g = rascunho.gravacao
        guard let obra = modelo.sincronizador.estado.obras.first(where: { $0.id == rascunho.obraId }) else { folhas.fechar(); return }
        // Tudo vazio tira o orçamento: a mesma pergunta do "Tirar orçamento" (no site, tira sem perguntar; achado 6).
        if orcamentoGravado(obra.orcamento, modo: g.modo, total: g.total, valores: g.valores) == nil { tirando = true; return }
        gravar { $0.salvandoOrcamento(modo: g.modo, total: g.total, valores: g.valores, naObra: rascunho.obraId) }
    }

    private func tirar() {
        guard folhas.aberta != nil else { return }
        gravar(tirou: true) { $0.tirandoOrcamento(daObra: rascunho.obraId) }
    }

    private func gravar(tirou: Bool = false, _ mudanca: (Estado) -> Estado?) {
        switch modelo.gravar(mudanca) {
        case .gravou where tirou:
            // Sem orçamento, a tela Orçamento (por trás da folha) volta para a obra, e a folha desce no turno seguinte, com a
            // animação dela: no mesmo turno, a navegação levaria junto a descida da folha.
            folhas.navegar(.sairDoOrcamento(rascunho.obraId))
            Task { @MainActor in folhas.fechar() }
        case .gravou, .sumiu, .semConta: folhas.fechar()
        case .naoCarregado: naoCarregado = true
        }
    }
}

/// O total ao vivo do modo por tópico, preso no alto com o segmentado: "Total", a soma e "N de M tópicos com valor".
private struct TotalAoVivo: View {
    let soma: Double
    let comValor: String
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let layout = tamanho.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                                                 : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        layout {
            Text("Total").font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.secundarioTransparente))
            if !tamanho.isAccessibilitySize { Spacer(minLength: 0) }
            VStack(alignment: tamanho.isAccessibilitySize ? .leading : .trailing, spacing: 0) {
                ValorEmDinheiro(texto: moeda(soma), fonte: .title3.weight(.bold))
                Text(comValor).font(.footnote).foregroundStyle(paleta.cor(.secundarioTransparente))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(paleta.cor(.linhaDaFolha), in: .rect(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
        .accessibilityIdentifier("totalDoOrcamento")
    }
}

/// Uma linha de tópico da folha: o ícone, o nome (com "próprio" nos tópicos próprios) e o valor, ou "sem valor"; a ativa
/// acende, com o valor na cor do link e o cursor. Desenha o seu pedaço do grupo (os cantos de cima na primeira, os de baixo
/// na última, e a linha fina recuada em cima das outras), para ser filha direta da lista preguiçosa. Na letra grande, sem o
/// ícone e com o valor embaixo do nome. Para o VoiceOver, um botão: o nome e o valor.
struct LinhaDoTopicoNaFolha: View, Equatable {
    let topico: Topico
    let centavos: Int
    let ativa: Bool
    let proprio: Bool
    let primeira: Bool
    let ultima: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    nonisolated static func == (a: Self, b: Self) -> Bool {
        a.topico == b.topico && a.centavos == b.centavos && a.ativa == b.ativa && a.proprio == b.proprio
            && a.primeira == b.primeira && a.ultima == b.ultima
    }

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        let forma = UnevenRoundedRectangle(topLeadingRadius: primeira ? 24 : 0, bottomLeadingRadius: ultima ? 24 : 0,
                                           bottomTrailingRadius: ultima ? 24 : 0, topTrailingRadius: primeira ? 24 : 0,
                                           style: .continuous)
        let layout = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2)) : AnyLayout(HStackLayout(spacing: 12))
        layout {
            if !grande { IconeDoTopico(icone: topico.icone) }
            nome
            if !grande { Spacer(minLength: 8) }
            ValorDaLinhaDoOrcamento(centavos: centavos, ativa: ativa)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .background {
            ZStack {
                forma.fill(paleta.cor(.linhaDaFolha))
                if ativa { forma.fill(paleta.cor(.aceso)) }
            }
            .accessibilityHidden(true)
        }
        .overlay(alignment: .top) { if !primeira { SeparadorDaFolha(recuo: grande ? 16 : 60) } }
        .contentShape(.rect)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(topico.nome + (proprio ? ", próprio" : ""))
        .accessibilityValue(centavos > 0 ? moeda(centavosParaReais(centavos)) : "sem valor")
        .accessibilityAddTraits(ativa ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("linhaOrc-\(topico.id)")
    }

    /// O nome e, no tópico próprio, a etiqueta "próprio" (o `.proprio` do mockup: 12 pt semibold no secundário, na cápsula do
    /// trilho do segmentado).
    private var nome: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(topico.nome).foregroundStyle(paleta.cor(.texto)).fixedSize(horizontal: false, vertical: true)
            if proprio {
                Text("próprio")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(paleta.cor(.secundarioTransparente))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 1)
                    .background(paleta.cor(.segmentadoFundo), in: .capsule)
            }
        }
    }
}

/// O valor de uma linha da folha: "R$ 30.000,00" (na ativa, na cor do link e com o cursor) ou "sem valor".
private struct ValorDaLinhaDoOrcamento: View {
    let centavos: Int
    let ativa: Bool
    @Environment(\.paleta) private var paleta

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            if centavos > 0 || ativa {
                ValorEmDinheiro(texto: moeda(centavosParaReais(centavos)), fonte: .body.weight(ativa ? .semibold : .regular),
                                cor: ativa ? .linkNoVidro : .texto)
            } else {
                Text("sem valor").foregroundStyle(paleta.cor(.secundarioTransparente))
            }
            if ativa { CursorDaLinha() }
        }
    }
}

/// "Orçamento total" e o valor, a linha de 60 pt do modo "Só o total" (a do valor do gasto): o rótulo no secundário, "R$" e
/// o valor em title2 bold; ativa, na cor do link e com o cursor.
private struct LinhaDoTotalNaFolha: View {
    let centavos: Int
    let ativa: Bool
    @Environment(\.paleta) private var paleta

    var body: some View {
        LinhaDaFolhaComRotulo(rotulo: "Orçamento total", altura: 60) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                ValorEmDinheiro(texto: fmtCentavos(centavos), fonte: .title2.weight(.bold), cor: ativa ? .linkNoVidro : .texto,
                                prefixo: .callout.weight(.semibold))
                if ativa { CursorDaLinha() }
            }
        }
        .background(ativa ? paleta.cor(.aceso) : .clear)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Orçamento total")
        .accessibilityValue(moeda(centavosParaReais(centavos)))
        .accessibilityAddTraits(ativa ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("linhaOrcamentoTotal")
    }
}

/// O cursor da linha ativa: 2 pt na cor do link, da altura da letra, piscando a 2 Hz (pelo relógio, sem animação); parado
/// com Reduzir movimento.
private struct CursorDaLinha: View {
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @ScaledMetric(relativeTo: .body) private var altura: CGFloat = 20

    var body: some View {
        Group {
            if opcoes.reduzirMovimento {
                barra(visivel: true)
            } else {
                TimelineView(.periodic(from: .now, by: 0.5)) { contexto in
                    barra(visivel: Int(contexto.date.timeIntervalSinceReferenceDate * 2) % 2 == 0)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func barra(visivel: Bool) -> some View {
        RoundedRectangle(cornerRadius: 1).fill(paleta.cor(.linkNoVidro)).frame(width: 2, height: altura).opacity(visivel ? 1 : 0)
            .alignmentGuide(.firstTextBaseline) { $0.height * 0.8 }
    }
}
```

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -67,7 +67,10 @@ struct ObraView: View {
                     PilulaDaFase(obra: obra, hoje: hoje)
                     IndicadoresDaObraView(indicadores: indicadoresDaObra(obra, taxa: taxa, hoje: hoje), orcamento: orcamentoObra(obra),
                                           rotaDoOrcamento: .orcamento(obra.id))
-                    AcoesDaFaseView(fase: obra.fase) { agir($0, obra: obra) }
+                    AcoesDaFaseView(fase: obra.fase,
+                                    definirOrcamento: pecasOrcamento(obra).definir ? { folhas.aberta = .orcamento(obraId: obra.id) } : nil) {
+                        agir($0, obra: obra)
+                    }
                         .padding(.top, 2)
                         .padding(.bottom, 14)
                     PilulaDeLancamentos(quantidade: obra.gastos.count)
```

Em `app-ios/Custta/Telas/OrcamentoView.swift`:

```diff
--- a/app-ios/Custta/Telas/OrcamentoView.swift
+++ b/app-ios/Custta/Telas/OrcamentoView.swift
@@ -2,16 +2,18 @@ import SwiftUI
 import CusttaNucleo
 
 /* A tela Orçamento (mockup aprovado da etapa 3, parte 1, seção 3): empurrada pela linha do orçamento da obra, no caminho de
-   Obras, com o título grande. O cartão do site, com "previstos em N tópicos" e a frase do que está fora (no modo por tópico,
-   o cartão soma só os tópicos previstos e não fecha com o Total gasto: achado 10); o "Por tópico" com as frases do site, na
-   ordem do site, e uma linha por tópico fora do orçamento (no site, uma linha só, com os nomes: achado 11); no modo total, o
-   "Gasto por tópico" (bruto e % da obra, na ordem da legenda do donut) e a dica do lápis. As linhas dos tópicos ainda não
+   Obras, com o título grande e o lápis na barra (o mesmo círculo da obra), que abre a folha do orçamento. O cartão do site,
+   com "previstos em N tópicos" e a frase do que está fora (no modo por tópico, o cartão soma só os tópicos previstos e não
+   fecha com o Total gasto: achado 10); o "Por tópico" com as frases do site, na ordem do site, e uma linha por tópico fora
+   do orçamento (no site, uma linha só, com os nomes: achado 11); no modo total, o "Gasto por tópico" (bruto e % da obra, na
+   ordem da legenda do donut) e a dica do lápis. As linhas dos tópicos ainda não
    abrem nada: o detalhe do tópico chega no PR 2, e até lá elas ficam sem seta e sem toque (conselho de 19/10, decisão 3).
    Sem a obra (apagada em outro aparelho) ou sem o orçamento (tirado), a tela volta. */
 struct OrcamentoView: View {
     let id: String
     @Binding var caminho: [RotaDeObras]
     @Environment(ModeloApp.self) private var modelo
+    @Environment(Folhas.self) private var folhas
     @Environment(\.paleta) private var paleta
     @Environment(\.vidro) private var vidro
     @State private var barra = BarraDaObra()
@@ -91,6 +93,10 @@ struct OrcamentoView: View {
             ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: "Orçamento") }
             ToolbarItem(placement: .topBarTrailing) { IndicadorDeSincronizacao() }
                 .sharedBackgroundVisibility(.hidden)
+            ToolbarItem(placement: .topBarTrailing) {
+                BotaoDeEditarObra(rotulo: "Editar orçamento", identificador: "editarOrcamento") { folhas.aberta = .orcamento(obraId: id) }
+            }
+                .sharedBackgroundVisibility(.hidden)
         }
     }
 }
```

Em `app-ios/Custta/Telas/PecasDaObra.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDaObra.swift
+++ b/app-ios/Custta/Telas/PecasDaObra.swift
@@ -432,9 +432,11 @@ struct CartaoDaLista<Conteudo: View>: View {
 
 /// As ações da fase, logo abaixo dos indicadores (mockup da etapa 2, parte 3): o próximo passo numa pílula sólida da marca
 /// ("Marcar como pronta", "Registrar venda"); voltar numa pílula de vidro ("Voltar pra construção", "Desfazer venda").
-/// Pílulas de 52 pt que crescem com a letra, 10 entre elas, ícone de 20 e o texto em .body semibold.
+/// Pílulas de 52 pt que crescem com a letra, 10 entre elas, ícone de 20 e o texto em .body semibold. Sem orçamento e fora da
+/// vendida (o `pecasOrcamento` do site), "Definir orçamento" vem depois delas, em vidro (mockup da etapa 3).
 struct AcoesDaFaseView: View {
     let fase: Fase
+    var definirOrcamento: (() -> Void)? = nil
     let agir: (AcaoDaFase) -> Void
     @ScaledMetric(relativeTo: .body) private var icone: CGFloat = 20
 
@@ -451,6 +453,17 @@ struct AcoesDaFaseView: View {
                 .buttonStyle(PilulaDaAcao(principal: acao.principal))
                 .accessibilityIdentifier("acao-\(acao.rawValue)")
             }
+            if let definirOrcamento {
+                Button(action: definirOrcamento) {
+                    Label {
+                        Text("Definir orçamento").multilineTextAlignment(.center)
+                    } icon: {
+                        Image(decorative: "Icones/alvo").resizable().frame(width: min(icone, 34), height: min(icone, 34))
+                    }
+                }
+                .buttonStyle(PilulaDaAcao(principal: false))
+                .accessibilityIdentifier("definirOrcamento")
+            }
         }
     }
 }
@@ -482,8 +495,11 @@ struct PilulaDaAcao: ButtonStyle {
     }
 }
 
-/// O lápis da barra da obra: círculo de vidro com o ícone do site, como o sair do topo; abre "Editar obra".
+/// O lápis da barra da obra: círculo de vidro com o ícone do site, como o sair do topo; abre "Editar obra" (na tela
+/// Orçamento, "Editar orçamento").
 struct BotaoDeEditarObra: View {
+    var rotulo = "Editar obra"
+    var identificador = "editarObra"
     let editar: () -> Void
     @Environment(\.paleta) private var paleta
 
@@ -497,7 +513,7 @@ struct BotaoDeEditarObra: View {
                 .superficie(.navegacao, em: .circle)
         }
         .buttonStyle(.plain)
-        .accessibilityLabel("Editar obra")
-        .accessibilityIdentifier("editarObra")
+        .accessibilityLabel(rotulo)
+        .accessibilityIdentifier(identificador)
     }
 }
```

Em `app-ios/Custta/Telas/PrincipalView.swift`:

```diff
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -43,6 +43,7 @@ struct PrincipalView: View {
                 case .novaObra: FolhaDaObra(obraId: nil)
                 case .editarObra(let obraId): FolhaDaObra(obraId: obraId)
                 case .venda(let obraId): FolhaDaVenda(obraId: obraId)
+                case .orcamento(let obraId): FolhaDoOrcamento(obraId: obraId)
                 }
             }
             .environment(folhas)
@@ -102,6 +103,8 @@ extension PrincipalView {
             var semAnimacao = Transaction()
             semAnimacao.disablesAnimations = true
             withTransaction(semAnimacao) { caminhoDeObras = [.obra(id)] }
+        case .sairDoOrcamento(let id):
+            caminhoDeObras.removeAll { $0 == .orcamento(id) }
         case .apagar(let id):
             caminhoDeObras.removeAll()
             // Depois do voltar do sistema, a linha sai da lista com a animação do apagar gasto.
@@ -120,7 +123,7 @@ extension PrincipalView {
 
     #if DEBUG
     /// Testes de tela, laudo e conferência visual: `CUSTTA_FOLHA` abre uma folha quando os dados chegam (`novaObra`,
-    /// `editarObra:<id>`, `venda:<id>`, `gastoDeVendida:<id>`, `novoGasto:<id>`). Sem ele, com `CUSTTA_ABRIR=obra:<id>`,
+    /// `editarObra:<id>`, `venda:<id>`, `gastoDeVendida:<id>`, `novoGasto:<id>`, `orcamento:<id>`). Sem ele, com `CUSTTA_ABRIR=obra:<id>`,
     /// `-custta.folha <passo>` abre a folha do gasto novo já no passo (valor, detalhes, cartao, topicos, repetido) e
     /// `-custta.folha editar:<gasto>`, a edição.
     private func abrirFolhaDoGancho() async {
@@ -138,6 +141,7 @@ extension PrincipalView {
             case "venda": folhas.aberta = .venda(obraId: id)
             case "gastoDeVendida": folhas.aberta = .gastoDeVendida(vendidaId: id)
             case "novoGasto": folhas.aberta = .novoGasto(obraId: id)
+            case "orcamento": folhas.aberta = .orcamento(obraId: id)
             default: break
             }
         } else if let passo, let obraId = caminhoDeObras.last?.obraId {
```

Em `scripts/icones-app-ios.mjs`:

```diff
--- a/scripts/icones-app-ios.mjs
+++ b/scripts/icones-app-ios.mjs
@@ -17,10 +17,10 @@ const PASTA = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../app
 /** Ícones que as telas usam: abas, fases da obra, sair, olho da senha e a seta da dica; na etapa 2, os dos 21 tópicos
     (TOPICOS do calc.js) e o "etiqueta" dos tópicos próprios, o calendário do "A vencer", o cartão do pagamento, o lápis
     de editar, o acordo da venda, o voltar das fases e as notas da obra sem gastos; na etapa 3, o triângulo do aviso dos tópicos
-    na linha do orçamento. */
+    na linha do orçamento e o alvo do "Definir orçamento". */
 export const USADOS = ['predio', 'engrenagem', 'sair', 'guindaste', 'casa', 'check', 'olho', 'olhoFechado', 'setaBaixo',
   'mapa', 'documento', 'tijolos', 'pa', 'vergalhao', 'raio', 'gota', 'porta', 'ladrilho', 'rolo', 'piscina', 'arvore', 'capacete',
-  'caixa', 'mais', 'etiqueta', 'calendario', 'cartao', 'lapis', 'acordo', 'voltar', 'notas', 'alerta'];
+  'caixa', 'mais', 'etiqueta', 'calendario', 'cartao', 'lapis', 'acordo', 'voltar', 'notas', 'alerta', 'alvo'];
 
 const info = { author: 'xcode', version: 1 };
 
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/icones-app-ios.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | tail -8 | grep -E "ℹ (pass|fail)"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | tail -5
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/OrcamentoUITests -only-testing:CusttaTests 2>&1 | grep -E "Test run with|Executed|TEST EXECUTE" | tail -4
```
Expected: `ℹ pass 49`, `ℹ fail 0`; sem aviso; `OrcamentoUITests` 27 de 27 (os 11 da tela e os 16 da folha); `✔ Test run with 142 tests in 25 suites passed`; `** TEST EXECUTE SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Assets.xcassets/Icones/alvo.imageset/Contents.json \
  app-ios/Custta/Assets.xcassets/Icones/alvo.imageset/alvo.svg \
  app-ios/Custta/Estado/Folhas.swift \
  app-ios/Custta/Identidade/PecasDaFolha.swift \
  app-ios/Custta/Telas/FolhaDoOrcamento.swift \
  app-ios/Custta/Telas/ObraView.swift \
  app-ios/Custta/Telas/OrcamentoView.swift \
  app-ios/Custta/Telas/PecasDaObra.swift \
  app-ios/Custta/Telas/PrincipalView.swift \
  app-ios/CusttaTests/FolhaDoOrcamentoTests.swift \
  app-ios/CusttaUITests/FolhaDoOrcamentoUITests.swift \
  scripts/icones-app-ios.mjs \
  tests/app-ios.test.cjs
git commit -m "feat: folha do orçamento da obra" -m "A obra sem orçamento ganha \"Definir orçamento\" nas ações da fase (fora da vendida, como no site), e a tela Orçamento ganha o lápis na barra; os dois abrem a folha \"Orçamento da obra\" do mockup aprovado da etapa 3. Ela abre no modo salvo; no \"Definir\", em \"Só o total\", com as teclas já abertas e o \"Salvar\" apagado até ter valor. Por tópico, vêm os 21 tópicos fixos e depois os próprios, uma linha cada, com o total ao vivo: tocar numa linha abre as teclas encaixadas nela, ‹ › andam pelas linhas, \"Pronto\" fecha, e a linha ativa fica sempre inteira entre o alto da lista e as teclas, também quando a letra muda. A folha confere onde a linha ativa ficou e, fora do meio da faixa, rola de novo até ela, até alguém rolar a lista: na letra de acessibilidade, a lista preguiçosa estima a altura das linhas que ainda não criou, e no iOS 26 a folha aberta com as teclas numa linha longe do alto a deixava fora da vista. Trocar para \"Só o total\" com o total vazio preenche com a soma dos tópicos e diz isso. Trocar de modo não grava; o \"Salvar\" grava o modo ativo pelo núcleo, guardando o que a folha não mostra. \"Tirar orçamento\" e o \"Salvar\" com tudo vazio fazem a pergunta do site; ao tirar, a tela Orçamento volta para a obra antes de a folha descer. Na letra de acessibilidade, o segmentado e o total rolam com a lista e o \"Salvar\" sai enquanto as teclas estão abertas. O VoiceOver ouve a linha a cada troca e tem as ações da linha ativa, e o teclado físico digita na linha ativa."
```

### Task 19: Leituras e auditorias do orçamento num job próprio

O job `laudo-etapa3` nasce no PR 1 (decisão 3: sem esperar um job passar de ~50 min), num simulador próprio, em paralelo com os outros: as leituras sobre o vidro e as auditorias de acessibilidade das telas do orçamento, com a varredura curta, o artefato quando reprova e teto de 60 min. Nos dois temas, a linha na obra, a tela Orçamento no alto, rolada e no modo total, e a folha com as teclas encaixadas, por tópico e no "Definir"; na maior letra, as mesmas telas, e com Aumentar contraste, a tela Orçamento. O `laudo` e o `auditoria` pulam essas quatro, e a guarda dos jobs passa a contar o job novo. Nas leituras e auditorias dos PRs 2 e 3, as cenas da etapa entram nele. Os testes de tela da etapa também ganham job próprio, o `app-etapa3`: o preparo do `app`, sem o build Release e sem o "resolver de novo", com teto de 60 min. Com o `OrcamentoUITests` (20,8 min na CI), o `app` chegou a 74,6 dos 75 min (run 39693700450) e, com o PR 2 por cima, foi cortado no teto (run 39710458060). O `app` pula a suíte e fica em ~53 min. Numa VM lenta levou 67 (run 39799242127), e o teto dele passa a 90. O `app-etapa3` fica em ~32. A guarda cobra que cada suíte de tela pulada no `app` rode em outro job, e num só. Nos dois jobs, o resultado sobe também quando o job é cortado no teto. Nos PRs 2 e 3, as suítes de tela da etapa entram no `app-etapa3`.

- **As cenas da etapa 2 mudam de lugar.** A linha do orçamento da vitrine (modo total, dentro do previsto) tem 118 pt, e tudo o que vem depois dos indicadores desceu isso: a 640 pt, as cenas "obra, lista", "obra com Aumentar contraste" e "obra, linha aberta" (e a auditoria da linha aberta) mostravam outro pedaço da tela; a 758, o mesmo pedaço da etapa 2.
- **O que fica fora das auditorias.** A barra das teclas encaixadas fica fora da de tipo dinâmico, como o título da folha (para no xxxLarge, com o Visualizador de Conteúdo Grande); o que a lista tem embaixo das teclas fica fora da de contraste, porque a faixa o esconde. Com a folha aberta, a de contraste mede a partir da barra da folha (a que contém `tituloDaFolha`), e não da primeira barra da árvore, que é a da tela por trás dela: os itens da barra da folha entram, e o que fica logo abaixo dela também, porque a folha não tem a borda de rolagem das telas.
- **O fim do modo total é ponto cego da auditoria de tipo dinâmico.** Ela começa na letra pequena: na cena rolada perto do fim da lista longa (a 3000 pt), a lista encolhe para cima da rolagem e a tela fica vazia, com e sem o gancho de rolagem (os achados vêm sem elemento, e os prints deles são a tela vazia). A cena fica a 2200 (o gasto por tópico, com as mesmas linhas do fim), e a dica, a única peça que só o fim tem, ganha guarda Node: cresce com a letra e quebra linha, sem altura fixa.
- **Os ajustes que a regressão e o Pro Max pediram.** (1) O que a lista da folha do orçamento tem acima do topo dela fica fora da de contraste: no Pro Max, com a faixa mais alta, linhas roladas para cima ficavam entre a barra e o total, atrás do cabeçalho. (2) A folga entre os dois prints do laudo passa de 1 px para 1 pt: a barra do cartão da tela Orçamento na maior letra, no Pro Max, virava "palavra" (dois valores que encolhem em cima). O teste do medidor da etapa 2 vai junto (`testBordaQueMudaAteUmPontoNaoMudaACena`, antes `…UmPixel…`): na escala 3, até 3 px é a mesma cena; com 4, a cena mudou (a CI do iOS 26 achou o teste velho). (3) A varredura da obra (`testLeituraDaObraRolando`) desce 118 pt (318…1618; a curta da CI, 518/1018), como as cenas da lista: a 640 e a 1200 a borda cortava uma palavra. (4) A tela Orçamento rolada na maior letra fica a 1637 pt: a 1500, no Pro Max, a barra da Estrutura ficava 6 pt abaixo da borda, sob o texto borrado pelo véu; a 1637 a borda cai no vão entre a Estrutura e a Fundação nos dois iPhones, e de 1615 a 1660 nenhum pixel muda longe das letras. (5) Na cena "obra com orçamento por tópico, na maior letra", o triângulo do aviso fica fora do laudo (`foraDoLaudo("iconeDoAviso")`, ligado por `-custta.foraDoLaudo`, só em Debug): o print sem texto o desenha 0,26 px mais baixo e a diferença virava "palavra" a 1,33; as palavras da linha seguem medidas. Desenhar os dois prints pelo mesmo `TextRenderer` resolveria a classe inteira, mas mexe no laudo de todas as cenas: fica como ideia, fora deste PR.
- **O total ao vivo na auditoria do iOS 26.** Na fronteira da letra de acessibilidade o total da folha muda de lugar (nela, rola dentro da lista; abaixo, fica fixo em cima). No iOS 26, a auditoria de tipo dinâmico acha "partially unsupported" e "Text clipped" em "Total", na soma e em "N de M tópicos com valor", com o print da CI mostrando os três grandes e inteiros (o segmentado, que muda de lugar junto, tem identificador em cada botão e passa; o cartão da tela Orçamento, com a mesma soma encolhida, também). Ficam fora só ali: no iOS 26, na letra de acessibilidade, pelo identificador de cada texto (`totalDoOrcamento-rotulo`, `-soma` e `-comValor`). O VoiceOver segue lendo o total num elemento só, com o mesmo rótulo. O quadro do total não serve: no iOS 26 a letra vai e volta em volta de cada auditoria (a padrão enquanto o `auditar` lê os quadros, a AX5 dentro dela), e na auditoria de depois do swipe os três vinham fora do quadro lido antes (run 39710458060). A prova no lugar é o `OrcamentoUITests.testNaMaiorLetraOTotalCresceSemCortar`: acha os três pelo identificador nas duas letras, os três crescem mais de 1,5× em relação à letra padrão, a soma aparece inteira e nada corta.
- **A volta pela borda no iOS 26.** Na CI do iOS 26, o arrasto sintetizado da borda às vezes não volta. Reprovou uma vez na tela Orçamento (run 39710458060) e uma vez na edição dentro da folha do A pagar (PR 2, run 39799242127), sempre na segunda entrada na tela: voltar pelo botão, entrar de novo, arrastar. A linha do tempo é a mesma das rodadas em que passa, e não há código do app no caminho; a borda do Orçamento passou 6 vezes no run seguinte. O `voltarPelaBorda(saindo:)` dá uma segunda tentativa só lá: se o que sai continua à vista 2 s depois, anexa o print, escreve "borda | 2ª tentativa (iOS 26)" no log e arrasta de novo, uma vez. No iOS 27, o teste segue estrito.
- **O que o laudo achou na primeira rodada:** o âmbar do escuro a 3,12 (Tarefa 14), uma palavra cortada pelo véu do topo (4,41; a cena foi para 606 pt), as linhas escondidas embaixo das teclas na de contraste (agora fora) e prints que mudavam longe das letras nas cenas da folha na maior letra (texto borrado pela barra da folha; cenas roladas).

**Files:**
- Test (criar): `app-ios/CusttaTests/OrcamentoEm375Tests.swift`
- Modify: `.github/workflows/app-ios.yml`
- Modify: `app-ios/Custta/Identidade/Componentes.swift`
- Modify: `app-ios/Custta/Telas/FolhaDoOrcamento.swift`
- Modify: `app-ios/Custta/Telas/PecasDoOrcamento.swift`
- Test (alterar): `app-ios/CusttaUITests/Abrir.swift`
- Test (alterar): `app-ios/CusttaUITests/AuditoriaUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/FolhaDoOrcamentoUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/LaudoDeContraste.swift`
- Test (alterar): `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/OrcamentoUITests.swift`
- Test (alterar): `tests/app-ios.test.cjs`
- Test (alterar): `tests/workflow.test.cjs`

**Interfaces:**
- Consumes: as telas e os identificadores das Tarefas 15 a 18; `-custta.rolagem` na tela Orçamento (Tarefa 16) e `-custta.folha` (Tarefa 18).
- Produces: os jobs `laudo-etapa3` e `app-etapa3`; os identificadores dos três textos do total (`totalDoOrcamento-rotulo`, `-soma` e `-comValor`); `View.foraDoLaudo(_:)` com nome (a exceção de uma cena, só em Debug); `LeituraNoVidroUITests/testLeituraDoOrcamento` e `…/testLeituraDoOrcamentoNaMaiorLetra`, `AuditoriaUITests/testOrcamentoNoMaiorTamanho` e `…/testContrasteDoOrcamentoNosDoisTemas`.

- [ ] **Step 1: Escrever os testes**

Criar `app-ios/CusttaTests/OrcamentoEm375Tests.swift`:

```swift
import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* O orçamento num iPhone de 375 pt (etapa 3, PR 1), na maior letra, com e sem Texto em negrito: nenhuma peça passa da
   largura. O laudo e as auditorias rodam no 18 Pro (402) e no Pro Max (440); 375 só aqui, num UIHostingController em escala
   1, com a largura de cada peça na tela (375 menos os 20 de cada lado; na folha, a linha já traz o recuo dela). */
@MainActor
struct OrcamentoEm375Tests {
    private let porTopico = Estado.de(DadosDeExemplo.vitrineDoOrcamento("porTopico"))

    private func largura<V: View>(_ view: V, _ disponivel: CGFloat, negrito: Bool) -> CGFloat {
        UIHostingController(rootView: view.dynamicTypeSize(.accessibility5)
            .environment(\.legibilityWeight, negrito ? .bold : .regular).environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: disponivel, height: CGFloat.infinity)).width
    }

    @Test(arguments: [false, true]) func telaDaObraEOrcamentoCabemEm375(negrito: Bool) throws {
        let casa = try #require(porTopico.obras.first { $0.id == "v1" })
        let resumo = try #require(orcamentoObra(casa))
        #expect(largura(LinhaDoOrcamento(resumo: resumo, comSeta: true), 335, negrito: negrito) <= 335, "a linha do orçamento")
        #expect(largura(CartaoDoOrcamento(resumo: resumo), 335, negrito: negrito) <= 335, "o cartão")
        let topicos = mapaDeTopicos(porTopico.config.topicosProprios)
        for linha in linhasPorTopico(resumo, topicos: topicos) + linhasForaDoOrcamento(resumo, topicos: topicos) {
            #expect(largura(LinhaDeTopicoNoOrcamento(linha: linha, identificador: linha.id), 335, negrito: negrito) <= 335, "\(linha.nome)")
        }
    }

    /// Na folha, o maior valor do teclado e o nome mais comprido dos tópicos fixos.
    @Test(arguments: [false, true]) func linhasDaFolhaCabemEm375(negrito: Bool) throws {
        let topico = try #require(topicosPadrao.max { $0.nome.count < $1.nome.count })
        let linha = LinhaDoTopicoNaFolha(topico: topico, centavos: tetoDoTeclado, ativa: true, proprio: false, primeira: true, ultima: true)
        #expect(largura(linha, 375, negrito: negrito) <= 375, "\(topico.nome)")
        let proprio = Topico(id: "c_x", nome: String(repeating: "Gesso e drywall ", count: 3), icone: "etiqueta")
        #expect(largura(LinhaDoTopicoNaFolha(topico: proprio, centavos: tetoDoTeclado, ativa: false, proprio: true, primeira: false,
                                              ultima: false), 375, negrito: negrito) <= 375, "o tópico próprio comprido")
        #expect(largura(TecladoEncaixado(centavos: .constant(tetoDoTeclado), nome: "\(topico.nome) · 21 de 71", anterior: {},
                                         proximo: {}, pronto: {}, salvarHabilitado: true, salvar: {}), 375, negrito: negrito) <= 375)
    }
}
```

Em `app-ios/CusttaUITests/Abrir.swift`:

```diff
--- a/app-ios/CusttaUITests/Abrir.swift
+++ b/app-ios/CusttaUITests/Abrir.swift
@@ -41,10 +41,25 @@ extension XCUIApplication {
         }
     }
 
-    /// Volta pelo gesto da borda esquerda, como o polegar (o XCUITest não tem "voltar" do sistema).
-    func voltarPelaBorda() {
+    /// Volta pelo gesto da borda esquerda, como o polegar (o XCUITest não tem "voltar" do sistema). No iOS 26 da CI, o arrasto
+    /// sintetizado às vezes não volta depois de voltar pelo botão e entrar de novo, sem alerta e com o voltar à vista (runs
+    /// 39710458060 e 39799242127). Lá, se `saindo` não some em 2 s, ele se repete uma vez, com um print e uma linha no log;
+    /// no iOS 27 nada muda.
+    func voltarPelaBorda(saindo: XCUIElement? = nil) {
         let borda = coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
-        borda.press(forDuration: 0.05, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)))
+        let fim = coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
+        borda.press(forDuration: 0.05, thenDragTo: fim)
+        let ios27 = OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 0)
+        guard let saindo, !ProcessInfo.processInfo.isOperatingSystemAtLeast(ios27), !saindo.waitForNonExistence(timeout: 2) else {
+            return
+        }
+        let tentativa = "borda | 2ª tentativa (iOS 26)"
+        let foto = XCTAttachment(screenshot: screenshot())
+        foto.name = tentativa
+        foto.lifetime = .keepAlways
+        XCTContext.runActivity(named: tentativa) { $0.add(foto) }
+        Swift.print(tentativa)
+        borda.press(forDuration: 0.05, thenDragTo: fim)
     }
 
     /// Toca nas duas pontas da linha de um botão (x = 30 e a largura da tela − 30, na altura do meio dele), longe do
```

Em `app-ios/CusttaUITests/AuditoriaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -32,26 +32,52 @@ final class AuditoriaUITests: XCTestCase {
         let folha = app.elemento("tituloDaFolha").exists
         let abas = folha ? [] : ["aba-obras", "aba-ajustes", "botaoMais"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
         let fundoDaTela = abas.isEmpty ? app.frame.maxY : min(abas.map(\.minY).min()!, app.frame.maxY - borda)
-        let barra = app.navigationBars.firstMatch
-        let topoDoConteudo = barra.exists ? max(barra.frame.maxY, borda) : 0
+        // Com a folha aberta, a barra é a da folha, e não a da tela por trás dela (a primeira da árvore); e a folha não tem a
+        // borda de rolagem das telas: o conteúdo dela começa onde a barra acaba.
+        let barra = folha ? app.navigationBars.containing(.any, identifier: "tituloDaFolha").firstMatch : app.navigationBars.firstMatch
+        let topoDoConteudo = barra.exists ? (folha ? barra.frame.maxY : max(barra.frame.maxY, borda)) : 0
         let daBarra = barra.exists ? barra.descendants(matching: .any).allElementsBoundByIndex.map(\.frame) : []
+        // Com as teclas encaixadas abertas (folha do orçamento), a lista termina onde a faixa delas começa: o que a lista tem
+        // embaixo da faixa está escondido (montado pela lista preguiçosa, mas fora da vista). As teclas e a barra entram.
+        let teclas = app.elemento("tecladoEncaixado")
+        let topoDasTeclas = teclas.exists ? teclas.frame.minY : .infinity
+        let dasTeclas = teclas.exists ? teclas.descendants(matching: .any).allElementsBoundByIndex.map(\.frame) : []
+        // E começa embaixo do cabeçalho fixo da folha (o segmentado e o total): o que a lista tem em cima dele foi rolado para
+        // fora da vista. No 18 Pro essas linhas ficam sob a barra; no Pro Max, com a faixa mais alta, entre a barra e o total.
+        let lista = app.elemento("listaDoOrcamento")
+        let topoDaLista = lista.exists ? lista.frame.minY : -.infinity
+        let daLista = lista.exists ? lista.descendants(matching: .any).allElementsBoundByIndex.map(\.frame) : []
+        // O total ao vivo da folha do orçamento ("Total", a soma e "N de M tópicos com valor") muda de lugar na fronteira da
+        // letra de acessibilidade: nela, rola dentro da lista; abaixo dela, fica fixo em cima da lista. No iOS 26, a auditoria
+        // acha "partially unsupported" e "Text clipped" nos três, com o print da CI mostrando os três grandes e inteiros. Lá,
+        // a letra vai e volta em cada auditoria: a padrão enquanto este auditar lê os quadros, a AX5 dentro dela. O quadro do
+        // total lido aqui não é onde ela acha os textos (run 39710458060, depois do swipe): a exceção é pelo identificador
+        // de cada texto, como as outras. Só ali, só na letra de acessibilidade e só no iOS 26; a prova de que crescem e não
+        // cortam é o OrcamentoUITests.testNaMaiorLetraOTotalCresceSemCortar.
+        let totalMudaDeLugar = app.launchArguments.contains { $0.hasPrefix("UICTContentSizeCategoryAccessibility") }
+            && !ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 0))
         try app.performAccessibilityAudit(for: tipos) { achado in
             guard let elemento = achado.element else {
                 Swift.print("auditoria | \(achado.compactDescription) | sem elemento | reprova")
                 return false
             }
             let fora: Bool
+            let noTotal = totalMudaDeLugar && elemento.identifier.hasPrefix("totalDoOrcamento-")
             switch achado.auditType {
+            case .dynamicType where noTotal && achado.compactDescription.contains("partially"), .textClipped where noTotal:
+                fora = true
             case .dynamicType:
                 // Os títulos das barras param perto de 22 pt, como os do sistema (mockup da etapa 2), com o Visualizador de
                 // Conteúdo Grande: o pequeno da obra e o das folhas (na maior letra o nome da obra sai da barra da folha e
                 // fica no valor do título, para o VoiceOver). Pelo identificador, e não pela barra inteira: o que passa por
                 // baixo dela continua na auditoria de tipo dinâmico. Na folha do gasto, as teclas e o "Apagar" do arrastar
-                // param no AX2, e o visor do valor (64 pt) já é maior que o texto na maior letra e encolhe para caber.
+                // param no AX2, e o visor do valor (64 pt) já é maior que o texto na maior letra e encolhe para caber. Na
+                // folha do orçamento (etapa 3), a barra das teclas encaixadas para no xxxLarge, como o título da folha.
                 let centro = CGPoint(x: elemento.frame.midX, y: elemento.frame.midY)
                 fora = elemento.label == "Continuar com o Google" || elemento.identifier == "tituloPequenoDaBarra"
                     || elemento.identifier.hasPrefix("tituloDaFolha") || elemento.identifier.hasPrefix("visorDoValor")
                     || elemento.identifier.hasPrefix("tecla-") || elemento.identifier.hasPrefix("apagar-")
+                    || elemento.identifier.hasPrefix("barraDasTeclas-")
                     || abas.contains { $0.contains(centro) }
             case .contrast:
                 if elemento.identifier.hasPrefix("aba-") { fora = false }   // o rótulo da própria cápsula
@@ -61,7 +87,9 @@ final class AuditoriaUITests: XCTestCase {
                 else if elemento.label == "—" { fora = true }
                 else {
                     let sobABarra = elemento.frame.minY < topoDoConteudo && !daBarra.contains(elemento.frame)
-                    fora = sobABarra || elemento.frame.maxY > fundoDaTela
+                    let sobAsTeclas = elemento.frame.maxY > topoDasTeclas + 0.5 && !dasTeclas.contains(elemento.frame)
+                    let acimaDaLista = elemento.frame.minY < topoDaLista - 0.5 && daLista.contains(elemento.frame)
+                    fora = sobABarra || sobAsTeclas || acimaDaLista || elemento.frame.maxY > fundoDaTela
                 }
             default:
                 fora = false
@@ -138,6 +166,7 @@ final class AuditoriaUITests: XCTestCase {
     }
 
     /// A folha do gasto (valor e cartão) e a linha aberta com o "Apagar", no escuro e no claro, com superfícies sólidas.
+    /// A linha aberta em 758 pt (640 até a etapa 2, antes da linha do orçamento da vitrine, de 118 pt).
     @MainActor func testContrasteDaFolhaNosDoisTemas() throws {
         for tema in temas {
             let combo = ["-custta.tema", tema] + solido + parado
@@ -148,7 +177,7 @@ final class AuditoriaUITests: XCTestCase {
                 app.terminate()
             }
             let lista = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1",
-                                 argumentos: combo + ["-custta.rolagem", "640", "-custta.linhaAberta", "g027"])
+                                 argumentos: combo + ["-custta.rolagem", "758", "-custta.linhaAberta", "g027"])
             XCTAssertTrue(lista.buttons["apagar-g027"].waitForExistence(timeout: 10))
             try auditar(lista, [.contrast])
             lista.terminate()
@@ -342,3 +371,63 @@ final class AuditoriaUITests: XCTestCase {
         }
     }
 }
+
+extension AuditoriaUITests {
+    /// O orçamento (etapa 3, PR 1) na maior letra: a linha na obra, a tela Orçamento no alto e rolada (o cartão e os primeiros
+    /// tópicos; os tópicos a 3000 pt; no modo total, o gasto por tópico a 2200 pt) e a folha, com as teclas fechadas e abertas,
+    /// por tópico e no "Definir". A tela Orçamento sem o meio (1500 pt): ali, enquanto a auditoria trocava o tamanho da letra,
+    /// saíam achados sem elemento (como a vendida a 800 pt da etapa 2). E sem o fim do modo total (a 3000 pt e mais): a
+    /// auditoria diminui a letra, a lista longa encolhe para cima da rolagem e a tela fica vazia, com o gancho da rolagem fixa ou
+    /// sem ele, e os achados saem sem elemento (ponto cego, 21/10); o que só o fim tem, a dica, tem guarda Node. Roda no job
+    /// laudo-etapa3.
+    @MainActor func testOrcamentoNoMaiorTamanho() throws {
+        var app: XCUIApplication
+        for (dados, abrir, rolagem, espera) in [("porTopico", "obra:v1", 700, "editarObra"), ("porTopico", "orcamento:v1", 0, "editarOrcamento"),
+                                                ("porTopico", "orcamento:v1", 3000, "editarOrcamento"),
+                                                ("vitrine", "orcamento:v1", 2200, "editarOrcamento")] {
+            app = abrirApp(conta: "senha", dados: dados, abrir: abrir, argumentos: maiorLetra + parado + ["-custta.rolagem", "\(rolagem)"])
+            XCTAssertTrue(app.buttons[espera].waitForExistence(timeout: 10), "\(abrir) em \(rolagem)")
+            Thread.sleep(forTimeInterval: 1.5)
+            try auditar(app, tiposDeAuditoria)
+            app.terminate()
+        }
+        for (dados, abrir, passo, espera) in [("porTopico", "orcamento:v1", "topicos", "linhaOrc-terreno"),
+                                              ("porTopico", "orcamento:v1", "teclas:eletrica", "barraDasTeclas-pronto"),
+                                              ("semOrcamento", "obra:v1", "", "tecla-1")] {
+            app = abrirApp(conta: "senha", dados: dados, abrir: abrir, folha: "orcamento:v1",
+                           argumentos: maiorLetra + parado + (passo.isEmpty ? [] : ["-custta.folha", passo]))
+            XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), passo)
+            Thread.sleep(forTimeInterval: 1)
+            try auditar(app, tiposDeAuditoria)
+            if passo == "topicos" {
+                app.swipeUp()
+                Thread.sleep(forTimeInterval: 1.5)
+                try auditar(app, tiposDeAuditoria)
+            }
+            app.terminate()
+        }
+    }
+
+    /// As mesmas telas no escuro e no claro, com superfícies sólidas.
+    @MainActor func testContrasteDoOrcamentoNosDoisTemas() throws {
+        for tema in temas {
+            let combo = ["-custta.tema", tema] + solido + parado
+            var app = abrirApp(conta: "senha", dados: "porTopico", abrir: "obra:v1", argumentos: combo)
+            XCTAssertTrue(app.elemento("indicadorOrcamento").waitForExistence(timeout: 10))
+            try auditar(app, [.contrast])
+            app.terminate()
+            app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", argumentos: combo)
+            XCTAssertTrue(app.elemento("cartaoDoOrcamento").waitForExistence(timeout: 10))
+            try auditar(app, [.contrast])
+            rolar(app)
+            try auditar(app, [.contrast])
+            app.terminate()
+            app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1",
+                           argumentos: combo + ["-custta.folha", "teclas:eletrica"])
+            XCTAssertTrue(app.elemento("barraDasTeclas-nome").waitForExistence(timeout: 10))
+            Thread.sleep(forTimeInterval: 1)
+            try auditar(app, [.contrast])
+            app.terminate()
+        }
+    }
+}
```

Em `app-ios/CusttaUITests/FolhaDoOrcamentoUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/FolhaDoOrcamentoUITests.swift
+++ b/app-ios/CusttaUITests/FolhaDoOrcamentoUITests.swift
@@ -1,4 +1,5 @@
 import XCTest
+import UIKit
 import notify
 
 /* A folha "Orçamento da obra" (etapa 3, PR 1): definir por total e por tópico (com ‹ › e "Pronto"), trocar de modo com o
@@ -278,6 +279,64 @@ extension OrcamentoUITests {
         }
     }
 
+    /// Na maior letra, o total ao vivo da folha (o "Total", a soma e "N de M tópicos com valor") cresce e nada nele corta. No
+    /// iOS 26, as auditorias de tipo dinâmico e de texto cortado acusam esses três textos (que mudam de lugar: dentro da lista
+    /// na letra de acessibilidade, fixos em cima dela abaixo disso), e a AuditoriaUITests os deixa de fora pelo identificador:
+    /// esta é a prova no lugar dela, e acha cada texto pelo mesmo identificador, nas duas letras.
+    /// Cada texto fica mais alto que na letra padrão (a soma, que encolhe para caber na largura, também); a soma tem a
+    /// proporção da letra padrão (inteira, sem "…": cortada, ela ficaria mais estreita para a altura); os três ficam um
+    /// embaixo do outro, dentro do cartão, cada um com a largura e a altura que o texto pede na fonte da maior letra.
+    func testNaMaiorLetraOTotalCresceSemCortar() throws {
+        let rotulo = "Total", soma = "R$\u{a0}1.019.847,85", comValor = "14 de 22 tópicos com valor"
+        let porIdentificador = ["totalDoOrcamento-rotulo": rotulo, "totalDoOrcamento-soma": soma, "totalDoOrcamento-comValor": comValor]
+        func medir(_ argumentos: [String]) throws -> (cartao: CGRect, textos: [String: CGRect]) {
+            let letra = argumentos.isEmpty ? "padrão" : "maior letra"
+            let app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1",
+                               argumentos: ["-custta.folha", "topicos"] + argumentos)
+            defer { app.terminate() }
+            let total = app.elemento("totalDoOrcamento")
+            XCTAssertTrue(total.waitForExistence(timeout: 10))
+            Thread.sleep(forTimeInterval: 1)
+            var textos: [String: CGRect] = [:]
+            for (id, texto) in porIdentificador {
+                let elemento = total.staticTexts.matching(identifier: id).firstMatch
+                XCTAssertTrue(elemento.exists, "\(id) na letra \(letra)")
+                guard elemento.exists else { continue }
+                XCTAssertEqual(elemento.identifier, id, "\(id) na letra \(letra)")
+                XCTAssertEqual(elemento.label, texto, "\(id) na letra \(letra)")
+                textos[texto] = elemento.frame
+            }
+            Swift.print("total | \(letra) | \(total.frame) | \(total.label) | \(textos)")
+            return (total.frame, textos)
+        }
+        let padrao = try medir([]), grande = try medir(maiorLetra)
+        for nome in [rotulo, soma, comValor] {
+            let antes = try XCTUnwrap(padrao.textos[nome], "\(nome) na letra padrão")
+            let depois = try XCTUnwrap(grande.textos[nome], "\(nome) na maior letra")
+            XCTAssertGreaterThan(depois.height, antes.height * 1.5, "\(nome): cresce com a letra")
+            XCTAssertTrue(grande.cartao.insetBy(dx: -0.5, dy: -0.5).contains(depois), "\(nome): dentro do cartão")
+        }
+        let r = try XCTUnwrap(grande.textos[rotulo]), s = try XCTUnwrap(grande.textos[soma]), c = try XCTUnwrap(grande.textos[comValor])
+        XCTAssertLessThanOrEqual(r.maxY, s.minY + 0.5, "a soma embaixo do \"Total\"")
+        XCTAssertLessThanOrEqual(s.maxY, c.minY + 0.5, "\"N de M tópicos com valor\" embaixo da soma")
+        let somaPadrao = try XCTUnwrap(padrao.textos[soma])
+        XCTAssertGreaterThanOrEqual(s.width / s.height, somaPadrao.width / somaPadrao.height * 0.97, "a soma inteira")
+        // O "Total" numa linha e a frase em quantas linhas pedir, na fonte da maior letra e na largura de cada um.
+        let ax5 = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
+        func precisa(_ texto: String, _ estilo: UIFont.TextStyle, _ peso: UIFont.Weight, largura: CGFloat) -> CGSize {
+            let descritor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: estilo, compatibleWith: ax5)
+                .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: peso]])
+            return (texto as NSString).boundingRect(with: CGSize(width: largura, height: .greatestFiniteMagnitude),
+                                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
+                                                     attributes: [.font: UIFont(descriptor: descritor, size: 0)], context: nil).size
+        }
+        let pedeORotulo = precisa(rotulo, .subheadline, .semibold, largura: .greatestFiniteMagnitude)
+        XCTAssertGreaterThanOrEqual(r.width, pedeORotulo.width - 2, "o \"Total\" inteiro")
+        XCTAssertGreaterThanOrEqual(r.height, pedeORotulo.height - 2, "o \"Total\" inteiro")
+        XCTAssertGreaterThanOrEqual(c.height, precisa(comValor, .footnote, .regular, largura: c.width).height - 2,
+                                    "\"N de M tópicos com valor\" com todas as linhas")
+    }
+
     /// A linha ativa fica inteira à vista entre o alto da lista e as teclas a cada ›, nas 71 linhas (os 21 fixos e os 50
     /// próprios, o limite das rules), também ao abrir; longe das pontas da lista, no meio da faixa (decisão 2).
     private func varrer(letraGrande: Bool) {
```

Em `app-ios/CusttaUITests/LaudoDeContraste.swift`:

```diff
--- a/app-ios/CusttaUITests/LaudoDeContraste.swift
+++ b/app-ios/CusttaUITests/LaudoDeContraste.swift
@@ -93,10 +93,12 @@ enum LaudoDeContraste {
         }
         for i in 0..<min(w * h, Int((topo * escala).rounded(.up)) * w) { dentro[i] = false }
 
-        // A maior diferença de canal entre os dois prints, pixel a pixel, contra o mesmo pixel do print sem texto ou o
-        // de cima ou o de baixo dele, o que bater mais. Na maior letra, o valor que encolhe para caber (ValorEmDinheiro)
-        // mede 1/3 pt a mais ou a menos com o texto apagado, e o que vem embaixo dele muda 1 px: sem a folga, as bordas
-        // viravam letra (nota 1,00) ou "cena que mudou" (a obra pronta no Pro Max, T35).
+        // A maior diferença de canal entre os dois prints, pixel a pixel, contra o mesmo pixel do print sem texto ou um
+        // dos de cima ou de baixo dele, até 1 pt, o que bater mais. Na maior letra, o valor que encolhe para caber
+        // (ValorEmDinheiro) mede 1/3 pt a mais ou a menos com o texto apagado, e o que vem embaixo dele muda 1 px por valor:
+        // sem a folga, as bordas viravam letra (nota 1,00) ou "cena que mudou" (a obra pronta no Pro Max, T35). Com mais
+        // de um valor em cima, 1 px não basta: a tela Orçamento e a obra com orçamento, na maior letra no Pro Max.
+        let folga = max(1, Int(escala.rounded()))
         func diferencaEntre(_ i: Int, _ j: Int) -> Int {
             let k = i * 4, m = j * 4
             return max(abs(Int(a[k]) - Int(b[m])), abs(Int(a[k + 1]) - Int(b[m + 1])), abs(Int(a[k + 2]) - Int(b[m + 2])))
@@ -105,8 +107,11 @@ enum LaudoDeContraste {
         var letra = [Bool](repeating: false, count: w * h)
         for i in 0..<(w * h) where dentro[i] {
             var d = diferencaEntre(i, i)
-            if d > ruido, i >= w { d = min(d, diferencaEntre(i, i - w)) }
-            if d > ruido, i < w * (h - 1) { d = min(d, diferencaEntre(i, i + w)) }
+            for k in 1...folga {
+                guard d > ruido else { break }
+                if i >= k * w { d = min(d, diferencaEntre(i, i - k * w)) }
+                if i < w * (h - k) { d = min(d, diferencaEntre(i, i + k * w)) }
+            }
             diferenca[i] = UInt8(d)
             letra[i] = d > limiarDaLetra
         }
```

Em `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -5,8 +5,9 @@ import UIKit
    Xcode não lê fundo de vidro, então ela audita as cores com superfícies sólidas (AuditoriaUITests) e este
    laudo mede o que aparece na tela: cada cena em dois prints, um normal e um com o texto apagado, com o
    fundo parado no pior caso (aurora no pior ponto da deriva inteira, globo no ângulo de partida, logo
-   pronto). Portão: 4,5:1 no pior ponto de cada palavra, em qualquer tamanho de letra; só o exemplo da
-   descrição do gasto, informativo no mockup, fica de fora (exemploDaDescricao). Cada cena deixa no
+   pronto). Portão: 4,5:1 no pior ponto de cada palavra, em qualquer tamanho de letra; fica de fora só o que
+   a tabela de exceções diz (excecoes): o exemplo da descrição do gasto, informativo no mockup
+   (exemploDaDescricao), e, numa cena, o triângulo do aviso do orçamento. Cada cena deixa no
    resultado o print anotado (verde passa, vermelho não) e a tabela, para o Lupa e o Giovani verem sem
    abrir o simulador. As 15 cenas passam com o escurecimento sob o vidro e o globo mais fundo no escuro
    (decisão do Giovani em 09/10). Na CI (iOS 26) o laudo também é portão: o simulador de lá desenha o
@@ -47,9 +48,21 @@ final class LeituraNoVidroUITests: XCTestCase {
         var rolada = false
     }
 
+    /// A tabela de exceções do laudo: a cena e a figura que sai dos dois prints dela (`foraDoLaudo(_:)` no app, com
+    /// `-custta.foraDoLaudo`; no print anotado da cena ela não aparece). Fora da tabela, só o exemplo da descrição do gasto,
+    /// em toda cena em que aparece (`exemploDaDescricao`).
+    /// - "obra com orçamento por tópico, na maior letra": o triângulo do aviso dos tópicos. É uma Image ao lado do texto, e o
+    ///   texto apagado não a tira: ela fica nos dois prints, mas no Pro Max o print sem texto a desenha 0,26 px mais baixo
+    ///   (os valores que encolhem em cima dela medem uma fração de ponto diferente sem o texto) e as bordas, reamostradas,
+    ///   mudam até 204: viram "letra" com o próprio triângulo de fundo (1,33:1). Nenhuma folga inteira casa (a melhor é
+    ///   0 px). Só o ícone sai: a frase do aviso, na mesma cor (alertaNoVidro), segue medida nesta cena, nas outras e no
+    ///   18 Pro (decisão do Prumo, 21/10).
+    private static let excecoes = ["obra com orçamento por tópico, na maior letra": "iconeDoAviso"]
+
     @MainActor private func fotografar(_ cena: Cena, textoApagado: Bool) -> (XCUIScreenshot, [CGRect], CGFloat, [CGRect]) {
+        let excecao = Self.excecoes[cena.nome].map { ["-custta.foraDoLaudo", $0] } ?? []
         let app = abrirApp(conta: cena.conta, dados: cena.dados, abrir: cena.abrir, folha: cena.folha,
-                           argumentos: cena.argumentos + (textoApagado ? ["-custta.textoApagado", cena.escopo] : []))
+                           argumentos: cena.argumentos + excecao + (textoApagado ? ["-custta.textoApagado", cena.escopo] : []))
         XCTAssertTrue(app.elemento(cena.espera).waitForExistence(timeout: 10), "\(cena.nome): a tela não abriu")
         if let aba = cena.aba {
             app.abrirAba(aba)
@@ -317,7 +330,8 @@ extension LeituraNoVidroUITests {
 
     /// A tela da obra (etapa 2): o topo (título, fase, indicadores) e a lista rolada (o "A vencer" e os cartões dos meses),
     /// no escuro e no claro; mais a maior letra e o Aumentar contraste, no escuro esmeralda. A vendida fica no
-    /// testLeituraDaObraVendida (lucro e prejuízo).
+    /// testLeituraDaObraVendida (lucro e prejuízo). A lista em 758 pt: a 640 até a etapa 2, e a linha do orçamento da
+    /// vitrine (118 pt, etapa 3) empurrou tudo o que vem depois dos indicadores.
     @MainActor func testLeituraDaObra() {
         var cenas: [Cena] = []
         for tema in temas {
@@ -325,7 +339,7 @@ extension LeituraNoVidroUITests {
             cenas += [
                 Cena(nome: "obra, topo, \(tema)", conta: "senha", argumentos: combo, espera: "tituloDaObra", escopo: "tudo",
                      dados: "vitrine", abrir: "obra:v1"),
-                Cena(nome: "obra, lista, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "640"],
+                Cena(nome: "obra, lista, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "758"],
                      espera: "aVencer", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
             ]
         }
@@ -333,7 +347,7 @@ extension LeituraNoVidroUITests {
         cenas += [
             Cena(nome: "obra na maior letra", conta: "senha", argumentos: escuro + maiorLetra, espera: "tituloDaObra", escopo: "tudo",
                  dados: "vitrine", abrir: "obra:v1"),
-            Cena(nome: "obra com Aumentar contraste", conta: "senha", argumentos: escuro + ["-custta.aumentarContraste", "YES", "-custta.rolagem", "640"],
+            Cena(nome: "obra com Aumentar contraste", conta: "senha", argumentos: escuro + ["-custta.aumentarContraste", "YES", "-custta.rolagem", "758"],
                  espera: "aVencer", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
         ]
         cobrar(cenas)
@@ -343,7 +357,9 @@ extension LeituraNoVidroUITests {
     /// ponto de um cabeçalho de mês ou de uma linha de baixo pode estar fora do quadro de 640 pt. No Mac, seis rolagens; na
     /// CI, duas.
     @MainActor func testLeituraDaObraRolando() {
-        let rolagens = ProcessInfo.processInfo.environment["CUSTTA_VARREDURA"] == "curta" ? [400, 900] : [200, 400, 640, 900, 1200, 1500]
+        // 118 pt abaixo das da etapa 2 (200 a 1500), a altura da linha do orçamento da vitrine: o mesmo pedaço da tela de
+        // antes, sem palavra cortada pela borda (a 640 e a 1200, o pedaço de baixo de uma palavra ficava em 4,04 a 4,36).
+        let rolagens = ProcessInfo.processInfo.environment["CUSTTA_VARREDURA"] == "curta" ? [518, 1018] : [318, 518, 758, 1018, 1318, 1618]
         var cenas: [Cena] = []
         for contraste in [false, true] {
             for y in rolagens {
@@ -377,7 +393,7 @@ extension LeituraNoVidroUITests {
                 folha("folha, parcela, \(tema)", "editar:g031", combo, espera: "avisoParcela"),
                 folha("folha, repetido, \(tema)", "repetido", combo, espera: "avisoRepetido"),
                 Cena(nome: "obra, linha aberta, \(tema)", conta: "senha",
-                     argumentos: combo + ["-custta.rolagem", "640", "-custta.linhaAberta", "g027"], espera: "apagar-g027",
+                     argumentos: combo + ["-custta.rolagem", "758", "-custta.linhaAberta", "g027"], espera: "apagar-g027",
                      escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
             ]
         }
@@ -484,6 +500,68 @@ extension LeituraNoVidroUITests {
     }
 }
 
+extension LeituraNoVidroUITests {
+    /// O orçamento (etapa 3, PR 1), no escuro e no claro: a linha do orçamento por tópico na obra (o aviso dos tópicos no
+    /// âmbar sobre o vidro), a tela Orçamento no alto e rolada (as frases do "Por tópico" e o que está fora) e no modo total
+    /// (o gasto por tópico e a dica), e a folha com as teclas encaixadas, por tópico e no "Definir orçamento". Roda no job
+    /// laudo-etapa3.
+    @MainActor func testLeituraDoOrcamento() {
+        var cenas: [Cena] = []
+        for tema in temas {
+            let combo = ["-custta.tema", tema] + piorMomento
+            cenas += [
+                Cena(nome: "obra com orçamento por tópico, \(tema)", conta: "senha", argumentos: combo,
+                     espera: "indicadorOrcamento", escopo: "tudo", dados: "porTopico", abrir: "obra:v1"),
+                Cena(nome: "tela Orçamento, topo, \(tema)", conta: "senha", argumentos: combo,
+                     espera: "cartaoDoOrcamento", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1"),
+                // Espera o título pequeno da barra: rolada, a lista já soltou o título grande da árvore.
+                Cena(nome: "tela Orçamento, rolada, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "700"],
+                     espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", rolada: true),
+                // 8 pt antes do fim: no fim, a borda de cima cortava o "5% da obra" do Telhado (o laudo mede a parte de baixo
+                // de uma palavra que entra no véu); aqui ela fica entre o nome do Telhado e o percentual, e a dica ainda aparece.
+                Cena(nome: "tela Orçamento, só o total, fim, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "606"],
+                     espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "vitrine", abrir: "orcamento:v1", rolada: true),
+                Cena(nome: "folha do orçamento, por tópico, digitando, \(tema)", conta: "senha",
+                     argumentos: combo + ["-custta.folha", "teclas:eletrica"], espera: "barraDasTeclas-nome", escopo: "tudo",
+                     dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1"),
+                Cena(nome: "folha do orçamento, definir, \(tema)", conta: "senha", argumentos: combo, espera: "tecla-1",
+                     escopo: "tudo", dados: "semOrcamento", abrir: "obra:v1", folha: "orcamento:v1"),
+            ]
+        }
+        cobrar(cenas)
+    }
+
+    /// O orçamento na maior letra (o dinheiro das frases na própria linha, o chip que quebra, as teclas no tamanho do AX2) e
+    /// com Aumentar contraste, no escuro esmeralda.
+    @MainActor func testLeituraDoOrcamentoNaMaiorLetra() {
+        let escuro = ["-custta.tema", "escuro"] + piorMomento
+        let grande = escuro + maiorLetra, contraste = escuro + ["-custta.aumentarContraste", "YES"]
+        cobrar([
+            // O triângulo do aviso sai dos dois prints desta cena (a tabela de exceções, `excecoes`); a frase dele fica.
+            Cena(nome: "obra com orçamento por tópico, na maior letra", conta: "senha", argumentos: grande + ["-custta.rolagem", "700"],
+                 espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "porTopico", abrir: "obra:v1", rolada: true),
+            Cena(nome: "tela Orçamento, topo, na maior letra", conta: "senha", argumentos: grande, espera: "cartaoDoOrcamento",
+                 escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1"),
+            // A 1637 pt, nos dois iPhones, a borda de cima fica no vão entre a Estrutura e a Fundação, sem texto nem barra logo
+            // abaixo dela, sob o véu: no 18 Pro (a largura da CI), o nome da Fundação começa 11 pt abaixo; no Pro Max, só o fio
+            // entre as linhas (3 pt) e o nome, a 28. A 1500, no Pro Max, a barra da Estrutura ficava 6 pt abaixo da borda, com o
+            // texto borrado pelo véu logo acima, e o alto dela mudava entre os dois prints (1837 px longe das letras:
+            // CenaNaoDeterministica). De 1615 a 1660, nos dois, nenhum pixel muda longe das letras.
+            Cena(nome: "tela Orçamento, rolada, na maior letra", conta: "senha", argumentos: grande + ["-custta.rolagem", "1637"],
+                 espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", rolada: true),
+            // Na maior letra, a linha ativa no meio da faixa leva o alto da lista (o segmentado) para baixo da barra da folha,
+            // que borra o que passa por ela: as cenas da folha com as teclas são roladas.
+            Cena(nome: "folha do orçamento, por tópico, digitando, na maior letra", conta: "senha",
+                 argumentos: grande + ["-custta.folha", "teclas:eletrica"], espera: "barraDasTeclas-pronto", escopo: "tudo",
+                 dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1", rolada: true),
+            Cena(nome: "folha do orçamento, definir, na maior letra", conta: "senha", argumentos: grande, espera: "tecla-1",
+                 escopo: "tudo", dados: "semOrcamento", abrir: "obra:v1", folha: "orcamento:v1", rolada: true),
+            Cena(nome: "tela Orçamento com Aumentar contraste", conta: "senha", argumentos: contraste, espera: "cartaoDoOrcamento",
+                 escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1"),
+        ])
+    }
+}
+
 /* O medidor com imagens sintéticas: sem abrir o app. */
 final class LaudoDeContrasteTests: XCTestCase {
     private func retrato(_ largura: Int, _ altura: Int, fundo: (UInt8, UInt8, UInt8),
@@ -553,19 +631,23 @@ final class LaudoDeContrasteTests: XCTestCase {
         }
     }
 
-    /// O que muda 1 px entre os prints longe das letras (o valor que encolhe na maior letra empurra o que vem embaixo)
-    /// é a mesma cena: o separador não muda a cena e a borda forte não vira palavra. Com 2 px, a cena mudou.
-    func testBordaQueMudaUmPixelNaoMudaACena() throws {
+    /// O que muda até 1 pt entre os prints longe das letras (o valor que encolhe na maior letra empurra o que vem embaixo
+    /// 1 px, e na tela Orçamento há mais de um valor em cima) é a mesma cena: o separador não muda a cena e a borda forte
+    /// não vira palavra. Na escala 3, a folga é de 3 px; com 4 px, a cena mudou.
+    func testBordaQueMudaAteUmPontoNaoMudaACena() throws {
         let separador: (UInt8, UInt8, UInt8) = (0x26, 0x40, 0x38), borda: (UInt8, UInt8, UInt8) = (0x80, 0x90, 0x88)
         func retratos(_ desce: CGFloat, _ cor: (UInt8, UInt8, UInt8)) -> (Retrato, Retrato) {
             (retrato(200, 120, fundo: fundo, pintar: letras.map { ($0, branco) } + [(CGRect(x: 100, y: 100, width: 90, height: 1), cor)]),
              retrato(200, 120, fundo: fundo, pintar: [(CGRect(x: 100, y: 100 + desce, width: 90, height: 1), cor)]))
         }
-        for cor in [separador, borda] {
-            let (normal, semTexto) = retratos(1, cor)
-            XCTAssertEqual(try LaudoDeContraste.medir(normal: normal, semTexto: semTexto, escala: 3).count, 1, "só as três letras")
+        for desce in 1...3 {
+            for cor in [separador, borda] {
+                let (normal, semTexto) = retratos(CGFloat(desce), cor)
+                XCTAssertEqual(try LaudoDeContraste.medir(normal: normal, semTexto: semTexto, escala: 3).count, 1,
+                               "\(desce) px: só as três letras")
+            }
         }
-        let (normal, semTexto) = retratos(2, separador)
+        let (normal, semTexto) = retratos(4, separador)
         XCTAssertThrowsError(try LaudoDeContraste.medir(normal: normal, semTexto: semTexto, escala: 3)) { erro in
             XCTAssertTrue(erro is LaudoDeContraste.CenaNaoDeterministica)
         }
```

Em `app-ios/CusttaUITests/OrcamentoUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/OrcamentoUITests.swift
+++ b/app-ios/CusttaUITests/OrcamentoUITests.swift
@@ -79,7 +79,7 @@ extension OrcamentoUITests {
         XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "o círculo volta para a obra")
         linha.tap()
         XCTAssertTrue(titulo.waitForExistence(timeout: 5))
-        app.voltarPelaBorda()
+        app.voltarPelaBorda(saindo: titulo)
         XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "a borda volta para a obra")
     }
 
```

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -479,6 +479,20 @@ test('texto cresce com a letra: lineLimit e minimumScaleFactor só no botão do
                'o ValorEmDinheiro numa linha, encolhendo até a metade');
 });
 
+test('dica do fim do modo total: cresce com a letra e quebra linha, sem altura fixa', () => {
+  // A auditoria não vê o fim da tela Orçamento no modo total na maior letra: ela diminui a letra, a lista longa encolhe para
+  // cima da rolagem e a tela fica vazia (achados sem elemento; a cena dela fica a 2200 pt). As linhas do fim são as mesmas
+  // da cena; só a dica não aparece em outro lugar. Que ela não corta, garante o código: letra do sistema, nenhum limite de
+  // linhas (guarda acima), quebra para baixo e nenhuma altura fixa.
+  const t = ler('app-ios/Custta/Telas/PecasDaTelaOrcamento.swift');
+  const inicio = t.indexOf('struct DicaDoModoTotal');
+  assert.ok(inicio >= 0, 'a DicaDoModoTotal');
+  const dica = t.slice(inicio, t.indexOf('\n}\n', inicio));
+  assert.match(dica, /Text\(dicaDoModoTotal\)\n\s*\.font\(\.footnote\)/, 'a dica na letra do sistema, que cresce');
+  assert.match(dica, /\.fixedSize\(horizontal: false, vertical: true\)/, 'a dica quebra linha e cresce para baixo');
+  assert.doesNotMatch(dica, /\.frame\([^)]*height|\.lineLimit|minimumScaleFactor/, 'sem altura fixa nem limite de linhas');
+});
+
 test('teclado de valor: ordem do telefone, teto do núcleo, "zero zero", o valor falado a cada tecla e teclas até o AX2', () => {
   // Nenhum teste de tela vê isso: eles tocam as teclas pelo identificador (a ordem não aparece), nenhum digita além do
   // teto, o anúncio do VoiceOver não chega ao XCUITest e a auditoria não mede o limite de tamanho das teclas.
```

Em `tests/workflow.test.cjs`:

```diff
--- a/tests/workflow.test.cjs
+++ b/tests/workflow.test.cjs
@@ -228,49 +228,76 @@ assert.ok(!/^on:\n(?:.*\n)*?\s{2}push:/m.test(appIos), 'o app nativo não roda e
 assert.match(appIos, /workflow_dispatch:/, 'o app nativo precisa do botão manual');
 assert.match(appIos, /resolver_de_novo:/, 'sem o botão de resolver os pacotes Swift do app nativo de novo');
 assert.match(appIosSemComentario, /- name: Resolver os pacotes Swift de novo\n\s+if: inputs\.resolver_de_novo\n/, 'o passo de resolver de novo só roda no botão (if: inputs.resolver_de_novo)');
-assert.equal((appIosSemComentario.match(/CODE_SIGNING_ALLOWED=NO/g) || []).length, 5, 'build, testes, os dois laudos e auditoria sem assinatura');
+assert.equal((appIosSemComentario.match(/CODE_SIGNING_ALLOWED=NO/g) || []).length, 7, 'build, testes, os testes da etapa 3, os três laudos e auditoria sem assinatura');
 assert.match(appIosSemComentario, /-project app-ios\/Custta\.xcodeproj[\s\S]*-configuration Release[\s\S]*CODE_SIGNING_ALLOWED=NO/, 'o app compila em Release sem assinatura');
 assert.match(appIosSemComentario, /xcodebuild test[\s\S]*-destination "\$DESTINO"/, 'os testes rodam no simulador escolhido pelo script');
-assert.equal((appIosSemComentario.match(/-onlyUsePackageVersionsFromResolvedFile/g) || []).length, 5, 'build, testes, os dois laudos e auditoria com os pacotes travados');
-// O laudo de leitura e as auditorias moram nos jobs laudo, laudo-parte3 e auditoria, em paralelo: o app pula os dois. O
-// laudo roda a leitura; o laudo-parte3 (as leituras da parte 3 da etapa 2) e o auditoria rodam as leituras que o laudo
-// pula, e o auditoria também as auditorias, menos as da parte 3, que rodam no laudo-parte3, para cada job caber no teto
-// com folga.
+assert.equal((appIosSemComentario.match(/-onlyUsePackageVersionsFromResolvedFile/g) || []).length, 7, 'build, testes, os testes da etapa 3, os três laudos e auditoria com os pacotes travados');
+// O laudo de leitura e as auditorias moram nos jobs laudo, laudo-parte3, laudo-etapa3 e auditoria, em paralelo: o app pula
+// os dois. O laudo roda a leitura; o laudo-parte3 (as leituras da parte 3 da etapa 2), o laudo-etapa3 (as da etapa 3) e o
+// auditoria rodam as leituras que o laudo pula, e o auditoria também as auditorias, menos as da parte 3 e as da etapa 3,
+// que rodam no laudo-parte3 e no laudo-etapa3, para cada job caber no teto com folga.
 // Cada job vai do nome até o próximo job (as linhas de comentário já saíram).
 const jobAppIos = nome => (appIosSemComentario.match(new RegExp(`\\n  ${nome}:\\n(?:(?!\\n  \\S)[\\s\\S])*`)) || [''])[0];
 const jobApp = jobAppIos('app'), jobLaudo = jobAppIos('laudo'), jobParte3 = jobAppIos('laudo-parte3'), jobAuditoria = jobAppIos('auditoria');
+const jobEtapa3 = jobAppIos('laudo-etapa3'), jobAppEtapa3 = jobAppIos('app-etapa3');
 assert.match(jobApp, /-skip-testing:CusttaUITests\/LeituraNoVidroUITests[\s\S]*-skip-testing:CusttaUITests\/AuditoriaUITests/,
   'o job app pula o laudo e as auditorias');
 assert.match(jobLaudo, /-only-testing:CusttaUITests\/LeituraNoVidroUITests \\\n/, 'o job laudo roda o laudo de leitura');
 assert.ok(!/AuditoriaUITests/.test(jobLaudo), 'as auditorias rodam no auditoria e no laudo-parte3, não no laudo');
 assert.match(jobAuditoria, /-only-testing:CusttaUITests\/AuditoriaUITests \\\n/, 'o job auditoria roda as auditorias');
-assert.ok(!/-only-testing:CusttaUITests\/LeituraNoVidroUITests \\\n/.test(jobAuditoria + jobParte3), 'o laudo-parte3 e o auditoria rodam só as leituras que o laudo pula');
+assert.ok(!/-only-testing:CusttaUITests\/LeituraNoVidroUITests \\\n/.test(jobAuditoria + jobParte3 + jobEtapa3), 'o laudo-parte3, o laudo-etapa3 e o auditoria rodam só as leituras que o laudo pula');
+assert.match(jobEtapa3, /-only-testing:CusttaUITests\/LeituraNoVidroUITests\/\w+ \\\n/, 'o job laudo-etapa3 roda as leituras da etapa 3');
 assert.match(jobParte3, /-only-testing:CusttaUITests\/LeituraNoVidroUITests\/\w+ \\\n/, 'o job laudo-parte3 roda as leituras da parte 3');
-// Nenhuma leitura se perde nem roda duas vezes: a que o laudo pula roda no laudo-parte3 ou no auditoria, e só nele.
+// Nenhuma leitura se perde nem roda duas vezes: a que o laudo pula roda no laudo-parte3, no laudo-etapa3 ou no auditoria, e
+// só nele.
 const leiturasDe = (job, opcao) => [...job.matchAll(new RegExp(`-${opcao}-testing:CusttaUITests/LeituraNoVidroUITests/(\\w+)`, 'g'))].map(m => m[1]).sort();
 const puladasNoLaudo = leiturasDe(jobLaudo, 'skip');
-assert.deepStrictEqual([...leiturasDe(jobParte3, 'only'), ...leiturasDe(jobAuditoria, 'only')].sort(), puladasNoLaudo,
-  'a leitura que o laudo pula roda num dos outros dois, uma vez só, e eles só rodam essas');
+assert.deepStrictEqual([...leiturasDe(jobParte3, 'only'), ...leiturasDe(jobEtapa3, 'only'), ...leiturasDe(jobAuditoria, 'only')].sort(), puladasNoLaudo,
+  'a leitura que o laudo pula roda num dos outros três, uma vez só, e eles só rodam essas');
 const leituraNoVidro = readFileSync(join(__dirname, '..', 'app-ios', 'CusttaUITests', 'LeituraNoVidroUITests.swift'), 'utf8');
 for(const metodo of puladasNoLaudo)
   assert.match(leituraNoVidro, new RegExp(`func ${metodo}\\(`), `o app-ios.yml divide ${metodo}, que não existe mais no LeituraNoVidroUITests`);
-// As auditorias da parte 3 rodam no laudo-parte3: a que o auditoria pula roda lá, uma vez só, e só ela.
+// As auditorias da parte 3 e as da etapa 3 rodam no laudo-parte3 e no laudo-etapa3: a que o auditoria pula roda num deles,
+// uma vez só, e só ela.
 const auditoriasDe = (job, opcao) => [...job.matchAll(new RegExp(`-${opcao}-testing:CusttaUITests/AuditoriaUITests/(\\w+)`, 'g'))].map(m => m[1]).sort();
 const puladasNoAuditoria = auditoriasDe(jobAuditoria, 'skip');
-assert.deepStrictEqual(auditoriasDe(jobParte3, 'only'), puladasNoAuditoria, 'a auditoria que o auditoria pula roda no laudo-parte3, e só ela');
-assert.ok(!/-only-testing:CusttaUITests\/AuditoriaUITests \\\n/.test(jobParte3), 'o laudo-parte3 roda só as auditorias que o auditoria pula');
+assert.deepStrictEqual([...auditoriasDe(jobParte3, 'only'), ...auditoriasDe(jobEtapa3, 'only')].sort(), puladasNoAuditoria,
+  'a auditoria que o auditoria pula roda no laudo-parte3 ou no laudo-etapa3, uma vez só, e só ela');
+assert.ok(!/-only-testing:CusttaUITests\/AuditoriaUITests \\\n/.test(jobParte3 + jobEtapa3), 'o laudo-parte3 e o laudo-etapa3 rodam só as auditorias que o auditoria pula');
 const auditoria = readFileSync(join(__dirname, '..', 'app-ios', 'CusttaUITests', 'AuditoriaUITests.swift'), 'utf8');
 for(const metodo of puladasNoAuditoria)
   assert.match(auditoria, new RegExp(`func ${metodo}\\(`), `o app-ios.yml divide ${metodo}, que não existe mais no AuditoriaUITests`);
-for(const [nome, job] of [['laudo', jobLaudo], ['laudo-parte3', jobParte3], ['auditoria', jobAuditoria]]){
+for(const [nome, job] of [['laudo', jobLaudo], ['laudo-parte3', jobParte3], ['laudo-etapa3', jobEtapa3], ['auditoria', jobAuditoria]]){
   assert.match(job, /\n    runs-on: macos-26\n/, `o job ${nome} roda no macOS 26 fixo`);
   assert.match(job, /\n\s+TEST_RUNNER_CUSTTA_VARREDURA: curta\n/, `o job ${nome} usa a varredura curta (a lista sob a cápsula só em 0, 20, 40 e 260 pt)`);
   assert.match(job, new RegExp(`-resultBundlePath "\\$RUNNER_TEMP/${nome}\\.xcresult"[\\s\\S]*if: failure\\(\\)[\\s\\S]*path: \\$\\{\\{ runner\\.temp \\}\\}/${nome}\\.xcresult`),
     `o job ${nome} guarda o próprio resultado quando reprova`);
 }
-assert.ok(!/\n    (?:needs|if):/.test(jobApp + jobLaudo + jobParte3 + jobAuditoria), 'o app, os laudos e o auditoria rodam em todo PR e em paralelo: nenhum tem if nem espera outro job');
-assert.ok(!/continue-on-error/.test(jobApp + jobLaudo + jobParte3 + jobAuditoria), 'o app, os laudos e o auditoria são portão: nenhum passa com falha (continue-on-error)');
-for(const job of ['nucleo', 'app', 'laudo', 'laudo-parte3', 'auditoria'])
+// Os testes de tela da etapa 3 rodam no app-etapa3, em paralelo com o app, que passou do teto de 75 min com eles. Cada suíte
+// de tela que o app pula (inteira) roda noutro job, uma vez só: as leituras e as auditorias nos laudos e no auditoria (teste
+// por teste, acima), e as outras, inteiras, no app-etapa3, que só roda o que o app pula. Pega a suíte que sai do app e não
+// entra em nenhum job, e a que entra no app-etapa3 sem sair do app (roda nos dois).
+const suitesInteiras = (job, opcao) => [...job.matchAll(new RegExp(`-${opcao}-testing:CusttaUITests/(\\w+)(?![\\w/])`, 'g'))].map(m => m[1]);
+const suitesQueRodam = job => [...job.matchAll(/-only-testing:CusttaUITests\/(\w+)/g)].map(m => m[1]);
+assert.ok(!/-skip-testing:CusttaUITests\/\w+\//.test(jobApp), 'o app pula suítes de tela inteiras');
+assert.ok(!/-(?:only|skip)-testing:CusttaUITests\/\w+\//.test(jobAppEtapa3), 'o app-etapa3 roda suítes de tela inteiras');
+assert.ok(suitesInteiras(jobAppEtapa3, 'only').length > 0, 'o app-etapa3 roda só as suítes da etapa 3 (sem -only-testing, rodaria todas)');
+const puladasNoApp = suitesInteiras(jobApp, 'skip');
+const nosLaudos = [...new Set([jobLaudo, jobParte3, jobEtapa3, jobAuditoria].flatMap(suitesQueRodam))];
+assert.deepStrictEqual([...nosLaudos, ...suitesInteiras(jobAppEtapa3, 'only')].sort(), [...puladasNoApp].sort(),
+  'a suíte de tela que o app pula roda nos laudos, no auditoria ou no app-etapa3, uma vez só, e o app-etapa3 roda só o que o app pula');
+const telas = readdirSync(join(__dirname, '..', 'app-ios', 'CusttaUITests')).filter(f => f.endsWith('.swift'))
+  .map(f => readFileSync(join(__dirname, '..', 'app-ios', 'CusttaUITests', f), 'utf8')).join('\n');
+for(const suite of puladasNoApp)
+  assert.match(telas, new RegExp(`\\bclass ${suite}\\b`), `o app-ios.yml divide ${suite}, que não existe no CusttaUITests`);
+assert.match(jobAppEtapa3, /\n    runs-on: macos-26\n/, 'o job app-etapa3 roda no macOS 26 fixo');
+// O resultado sobe também quando o job é cancelado: o run 39710458060 foi cortado no teto e ficou sem xcresult.
+for(const [nome, job, resultado] of [['app', jobApp, 'testes'], ['app-etapa3', jobAppEtapa3, 'testes-etapa3']])
+  assert.match(job, new RegExp(`-resultBundlePath "\\$RUNNER_TEMP/${resultado}\\.xcresult"[\\s\\S]*\\n\\s+if: failure\\(\\) \\|\\| cancelled\\(\\)\\n[\\s\\S]*path: \\$\\{\\{ runner\\.temp \\}\\}/${resultado}\\.xcresult`),
+    `o job ${nome} guarda o próprio resultado quando reprova e quando é cortado no teto`);
+assert.ok(!/\n    (?:needs|if):/.test(jobApp + jobAppEtapa3 + jobLaudo + jobParte3 + jobEtapa3 + jobAuditoria), 'o app, o app-etapa3, os laudos e o auditoria rodam em todo PR e em paralelo: nenhum tem if nem espera outro job');
+assert.ok(!/continue-on-error/.test(jobApp + jobAppEtapa3 + jobLaudo + jobParte3 + jobEtapa3 + jobAuditoria), 'o app, o app-etapa3, os laudos e o auditoria são portão: nenhum passa com falha (continue-on-error)');
+for(const job of ['nucleo', 'app', 'app-etapa3', 'laudo', 'laudo-parte3', 'laudo-etapa3', 'auditoria'])
   assert.match(jobAppIos(job), /\n    timeout-minutes: \d+\n/, `o job ${job} do app nativo precisa de timeout-minutes (sem ele, um job travado só cai em 6 h)`);
 const appIosTf = readFileSync(join(dir, 'app-ios-testflight.yml'), 'utf8');
 const appIosTfSemComentario = appIosTf.split('\n').filter(l => !/^\s*#/.test(l)).join('\n');
```

- [ ] **Step 2: Ver falhar**

Run: `node --test tests/workflow.test.cjs 2>&1 | grep -m1 AssertionError`
Expected: `AssertionError [ERR_ASSERTION]: build, testes, os testes da etapa 3, os três laudos e auditoria sem assinatura` (5 em vez de 7). As cenas e o teste de 375 pt são medidas novas, sem vermelho contra a Tarefa 18; a força delas está no próprio laudo.

- [ ] **Step 3: Implementar**

Em `.github/workflows/app-ios.yml`:

```diff
--- a/.github/workflows/app-ios.yml
+++ b/.github/workflows/app-ios.yml
@@ -5,9 +5,12 @@ name: app-ios
 #   dados.js, push.js, cadastro.js ou o gerador mudam;
 # - app: compila o app em Release sem assinatura (o caminho do TestFlight) e roda os testes de
 #   unidade e de tela no simulador com os serviços falsos;
-# - laudo, laudo-parte3 e auditoria: o laudo de leitura sobre o vidro e as auditorias de acessibilidade, cada
-#   um num simulador próprio, em paralelo com o app (o app com os dois passava dos 65 min com as telas da etapa 2,
-#   os dois num job só chegavam a 75 min com a folha do gasto, e a parte 3 da etapa 2 levava o laudo ao teto).
+# - app-etapa3: os testes de tela da etapa 3, num simulador próprio, em paralelo com o app (com eles, o app passou do
+#   teto de 75 min);
+# - laudo, laudo-parte3, laudo-etapa3 e auditoria: o laudo de leitura sobre o vidro e as auditorias de acessibilidade,
+#   cada um num simulador próprio, em paralelo com o app (o app com os dois passava dos 65 min com as telas da etapa 2,
+#   os dois num job só chegavam a 75 min com a folha do gasto, a parte 3 da etapa 2 levava o laudo ao teto, e as telas da
+#   etapa 3 moram no laudo-etapa3 desde a primeira).
 # Os testes contra os emuladores do Firebase e a conferência cruzada com o site rodam no Mac
 # (npm run test:app-ios:emuladores e npm run test:app-ios:cruzado): precisam de Java, dos
 # emuladores e da assinatura de simulador para o keychain do Firebase Auth.
@@ -66,8 +69,10 @@ jobs:
 
   app:
     runs-on: macos-26
-    # Sem o laudo e as auditorias (jobs laudo e auditoria), o job fica perto de 30 min; o teto é o de 12/10, com folga para a VM lenta.
-    timeout-minutes: 75
+    # Sem o laudo e as auditorias (jobs laudo, laudo-parte3, laudo-etapa3 e auditoria) e sem os testes de tela da etapa 3
+    # (job app-etapa3): ~41 min de testes + ~11 de preparo ≈ 53 min numa VM normal. Numa lenta, 67 min, com 48,9 de testes
+    # de tela (run 39799242127): o teto de 75 deixava 8 min de folga, e passa a 90.
+    timeout-minutes: 90
     steps:
       - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
       - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
@@ -112,7 +117,8 @@ jobs:
             build
 
       # Testes com os serviços falsos (nada de rede): unidade e tela. Os que dependem dos emuladores pulam
-      # sozinhos aqui; o laudo de leitura e as auditorias de acessibilidade rodam nos jobs laudo e auditoria.
+      # sozinhos aqui; o laudo de leitura e as auditorias de acessibilidade rodam nos jobs laudo e auditoria, e os
+      # testes de tela da etapa 3, no app-etapa3.
       - name: Testes de unidade e de tela no simulador
         run: |
           set -o pipefail
@@ -129,17 +135,62 @@ jobs:
             -resultBundlePath "$RUNNER_TEMP/testes.xcresult" \
             -skip-testing:CusttaUITests/LeituraNoVidroUITests \
             -skip-testing:CusttaUITests/AuditoriaUITests \
+            -skip-testing:CusttaUITests/OrcamentoUITests \
             CODE_SIGNING_ALLOWED=NO
 
-      # Unidade ou tela reprovadas: o resultado dos testes fica 7 dias no artefato.
-      - name: Resultado dos testes quando reprovam
-        if: failure()
+      # Unidade ou tela reprovadas: o resultado dos testes fica 7 dias no artefato. Também quando o job é cancelado: o run
+      # 39710458060 foi cortado no teto e ficou sem xcresult.
+      - name: Resultado dos testes quando reprovam ou o job é cortado
+        if: failure() || cancelled()
         uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
         with:
           name: testes-app-ios
           path: ${{ runner.temp }}/testes.xcresult
           retention-days: 7
 
+  app-etapa3:
+    runs-on: macos-26
+    # Os testes de tela da etapa 3, com o preparo do app, sem o build Release e sem o "resolver de novo": com eles, o app
+    # passou do teto de 75 min (runs 39693700450 e 39710458060). No PR 1, o OrcamentoUITests: 20,8 min de testes + ~11 de
+    # preparo ≈ 32 min. Como no laudo-etapa3, cada PR da etapa anota aqui o tempo do job, e ele se divide se passar de ~50.
+    timeout-minutes: 60
+    steps:
+      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
+      - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
+        with:
+          node-version: 22
+
+      - name: Versão do Xcode
+        run: xcodebuild -version
+
+      # Os mesmos serviços falsos do job app, que pula estas suítes.
+      - name: Testes de tela da etapa 3 no simulador
+        run: |
+          set -o pipefail
+          DESTINO="$(node scripts/simulador-ios.mjs)"
+          echo "Simulador: $DESTINO"
+          xcodebuild test \
+            -project app-ios/Custta.xcodeproj \
+            -scheme Custta \
+            -destination "$DESTINO" \
+            -derivedDataPath app-ios/build \
+            -skipMacroValidation \
+            -skipPackagePluginValidation \
+            -onlyUsePackageVersionsFromResolvedFile \
+            -resultBundlePath "$RUNNER_TEMP/testes-etapa3.xcresult" \
+            -only-testing:CusttaUITests/OrcamentoUITests \
+            CODE_SIGNING_ALLOWED=NO
+
+      # Tela reprovada: o resultado dos testes fica 7 dias no artefato. Também quando o job é cancelado: o run 39710458060
+      # foi cortado no teto e ficou sem xcresult.
+      - name: Resultado dos testes da etapa 3 quando reprovam ou o job é cortado
+        if: failure() || cancelled()
+        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
+        with:
+          name: testes-etapa3-app-ios
+          path: ${{ runner.temp }}/testes-etapa3.xcresult
+          retention-days: 7
+
   laudo:
     runs-on: macos-26
     # Leitura e auditorias em dois jobs que levam o mesmo tempo. Num job só (c1bc06a, 15/10): leitura 2089 s, auditorias
@@ -184,6 +235,8 @@ jobs:
             -skip-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaObraVendida \
             -skip-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaParte3NaMaiorLetra \
             -skip-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDoAlertaDeNaoSalvou \
+            -skip-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDoOrcamento \
+            -skip-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDoOrcamentoNaMaiorLetra \
             CODE_SIGNING_ALLOWED=NO
 
       # Laudo reprovado: o resultado e os prints anotados ficam 7 dias no artefato (o log só traz as notas).
@@ -244,10 +297,57 @@ jobs:
           path: ${{ runner.temp }}/laudo-parte3.xcresult
           retention-days: 7
 
+  laudo-etapa3:
+    runs-on: macos-26
+    # As leituras e as auditorias das telas da etapa 3 do app nativo (conselho de 19/10, decisão 3: o job nasce com elas, sem
+    # esperar um job passar de ~50 min). No PR 1, o orçamento: a linha na obra, a tela Orçamento e a folha com as teclas
+    # encaixadas, no escuro, no claro e na maior letra. Cada PR da etapa anota aqui o tempo do job.
+    timeout-minutes: 60
+    steps:
+      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
+      - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
+        with:
+          node-version: 22
+
+      - name: Versão do Xcode
+        run: xcodebuild -version
+
+      # A mesma varredura curta do job laudo: uma leitura troca de job sem mudar o que mede.
+      - name: Laudo de leitura e auditorias da etapa 3 no simulador
+        env:
+          TEST_RUNNER_CUSTTA_VARREDURA: curta
+        run: |
+          set -o pipefail
+          DESTINO="$(node scripts/simulador-ios.mjs)"
+          echo "Simulador: $DESTINO"
+          xcodebuild test \
+            -project app-ios/Custta.xcodeproj \
+            -scheme Custta \
+            -destination "$DESTINO" \
+            -derivedDataPath app-ios/build \
+            -skipMacroValidation \
+            -skipPackagePluginValidation \
+            -onlyUsePackageVersionsFromResolvedFile \
+            -resultBundlePath "$RUNNER_TEMP/laudo-etapa3.xcresult" \
+            -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDoOrcamento \
+            -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDoOrcamentoNaMaiorLetra \
+            -only-testing:CusttaUITests/AuditoriaUITests/testOrcamentoNoMaiorTamanho \
+            -only-testing:CusttaUITests/AuditoriaUITests/testContrasteDoOrcamentoNosDoisTemas \
+            CODE_SIGNING_ALLOWED=NO
+
+      # Laudo reprovado: o resultado e os prints anotados ficam 7 dias no artefato (o log só traz as notas).
+      - name: Resultado do laudo da etapa 3 quando reprova
+        if: failure()
+        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
+        with:
+          name: laudo-etapa3-app-ios
+          path: ${{ runner.temp }}/laudo-etapa3.xcresult
+          retention-days: 7
+
   auditoria:
     runs-on: macos-26
-    # As auditorias de acessibilidade (as da parte 3 rodam no laudo-parte3) e a leitura da folha do gasto; a conta do
-    # tempo está no job laudo.
+    # As auditorias de acessibilidade (as da parte 3 rodam no laudo-parte3, e as da etapa 3, no laudo-etapa3) e a leitura
+    # da folha do gasto; a conta do tempo está no job laudo.
     timeout-minutes: 60
     steps:
       - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
@@ -278,6 +378,8 @@ jobs:
             -only-testing:CusttaUITests/AuditoriaUITests \
             -skip-testing:CusttaUITests/AuditoriaUITests/testParte3NoMaiorTamanho \
             -skip-testing:CusttaUITests/AuditoriaUITests/testContrasteDaParte3NosDoisTemas \
+            -skip-testing:CusttaUITests/AuditoriaUITests/testOrcamentoNoMaiorTamanho \
+            -skip-testing:CusttaUITests/AuditoriaUITests/testContrasteDoOrcamentoNosDoisTemas \
             -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaFolhaDoGasto \
             CODE_SIGNING_ALLOWED=NO
 
```

Em `app-ios/Custta/Identidade/Componentes.swift`:

```diff
--- a/app-ios/Custta/Identidade/Componentes.swift
+++ b/app-ios/Custta/Identidade/Componentes.swift
@@ -409,17 +409,23 @@ extension View {
     /// Símbolo que não é texto (as setas). O laudo de leitura mede palavras: o apagador de texto apagava também o traço
     /// fino do símbolo, que virava uma "palavra" de nota errada. Em Debug, com `-custta.semSimbolos`, o símbolo some dos
     /// dois prints; o contraste dele (3:1, de figura) fica com a auditoria do Xcode, com superfícies sólidas.
-    func foraDoLaudo() -> some View { modifier(ForaDoLaudo()) }
+    func foraDoLaudo() -> some View { modifier(ForaDoLaudo(excecao: nil)) }
+
+    /// Figura que uma cena só do laudo deixa de fora (a tabela de exceções da LeituraNoVidroUITests, com o porquê). Em
+    /// Debug, com `-custta.foraDoLaudo <nome>`, ela some dos dois prints daquela cena; nas outras, fica nos dois.
+    func foraDoLaudo(_ excecao: String) -> some View { modifier(ForaDoLaudo(excecao: excecao)) }
 }
 
 private struct ForaDoLaudo: ViewModifier {
+    let excecao: String?
     #if DEBUG
     @AppStorage("custta.semSimbolos") private var semSimbolos = false
+    @AppStorage("custta.foraDoLaudo") private var foraNestaCena = ""
     #endif
 
     func body(content: Content) -> some View {
         #if DEBUG
-        content.opacity(semSimbolos ? 0 : 1)
+        content.opacity((excecao.map { $0 == foraNestaCena } ?? semSimbolos) ? 0 : 1)
         #else
         content
         #endif
```

Em `app-ios/Custta/Telas/FolhaDoOrcamento.swift`:

```diff
--- a/app-ios/Custta/Telas/FolhaDoOrcamento.swift
+++ b/app-ios/Custta/Telas/FolhaDoOrcamento.swift
@@ -573,13 +573,18 @@ private struct TotalAoVivo: View {
     var body: some View {
         let layout = tamanho.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                                                  : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
+        // Os identificadores vão também em cada texto: o VoiceOver lê o total como um elemento só, mas a auditoria do Xcode
+        // olha cada texto (e a exceção dela no iOS 26 é por identificador).
         layout {
             Text("Total").font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.secundarioTransparente))
+                .accessibilityIdentifier("totalDoOrcamento-rotulo")
             if !tamanho.isAccessibilitySize { Spacer(minLength: 0) }
             VStack(alignment: tamanho.isAccessibilitySize ? .leading : .trailing, spacing: 0) {
                 ValorEmDinheiro(texto: moeda(soma), fonte: .title3.weight(.bold))
+                    .accessibilityIdentifier("totalDoOrcamento-soma")
                 Text(comValor).font(.footnote).foregroundStyle(paleta.cor(.secundarioTransparente))
                     .fixedSize(horizontal: false, vertical: true)
+                    .accessibilityIdentifier("totalDoOrcamento-comValor")
             }
         }
         .padding(.horizontal, 16)
```

Em `app-ios/Custta/Telas/PecasDoOrcamento.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDoOrcamento.swift
+++ b/app-ios/Custta/Telas/PecasDoOrcamento.swift
@@ -139,6 +139,7 @@ struct AvisoDoOrcamento: View {
                 .resizable()
                 .frame(width: lado, height: lado)
                 .padding(.top, tamanho.isAccessibilitySize ? letra * 0.15 : 2)
+                .foraDoLaudo("iconeDoAviso")
             Text(texto)
                 .font(.subheadline.weight(.semibold))
                 .fixedSize(horizontal: false, vertical: true)
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node --test tests/app-ios.test.cjs tests/workflow.test.cjs 2>&1 | tail -8 | grep -E "ℹ (pass|fail)"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | tail -5
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDoOrcamento -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDoOrcamentoNaMaiorLetra -only-testing:CusttaUITests/AuditoriaUITests/testOrcamentoNoMaiorTamanho -only-testing:CusttaUITests/AuditoriaUITests/testContrasteDoOrcamentoNosDoisTemas -only-testing:CusttaTests/OrcamentoEm375Tests -only-testing:CusttaUITests/LaudoDeContrasteTests -only-testing:CusttaUITests/OrcamentoUITests/testNaMaiorLetraOTotalCresceSemCortar 2>&1 | grep -E "Test run with|Executed|TEST EXECUTE" | tail -4
```
Expected: `ℹ pass 51`, `ℹ fail 0`; sem aviso; `testLeituraDoOrcamento` com 12 cenas e 0 palavra abaixo de 4,5 (pior 4,56, o chip verde do claro), `testLeituraDoOrcamentoNaMaiorLetra` com 6 cenas (pior 5,28), as duas auditorias sem reprova (fora, os de sempre: a cápsula, os títulos das barras e o "Pronto"; no iOS 26, também os três textos do total ao vivo na maior letra); `OrcamentoEm375Tests` 2 de 2; `LaudoDeContrasteTests` 5 de 5; o `testNaMaiorLetraOTotalCresceSemCortar` passa; `** TEST EXECUTE SUCCEEDED **`. No Pro Max, as mesmas quatro (ver o ponto de controle).

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/app-ios.yml \
  app-ios/Custta/Identidade/Componentes.swift \
  app-ios/Custta/Telas/FolhaDoOrcamento.swift \
  app-ios/Custta/Telas/PecasDoOrcamento.swift \
  app-ios/CusttaTests/OrcamentoEm375Tests.swift \
  app-ios/CusttaUITests/Abrir.swift \
  app-ios/CusttaUITests/AuditoriaUITests.swift \
  app-ios/CusttaUITests/FolhaDoOrcamentoUITests.swift \
  app-ios/CusttaUITests/LaudoDeContraste.swift \
  app-ios/CusttaUITests/LeituraNoVidroUITests.swift \
  app-ios/CusttaUITests/OrcamentoUITests.swift \
  tests/app-ios.test.cjs \
  tests/workflow.test.cjs
git commit -m "ci: leituras e auditorias do orçamento num job próprio" -m "O app nativo ganha o job laudo-etapa3, que nasce no PR 1 da etapa 3 (decisão 3 do conselho, sem esperar um job passar de ~50 min): as leituras sobre o vidro e as auditorias de acessibilidade das telas do orçamento, num simulador próprio, em paralelo com os outros. No escuro e no claro, a linha na obra, a tela Orçamento no alto, rolada e no modo total, e a folha com as teclas encaixadas, por tópico e no \"Definir\"; na maior letra, as mesmas telas, e com Aumentar contraste, a tela Orçamento. O laudo e o auditoria pulam essas leituras e auditorias, e a guarda dos jobs passa a contar o job novo. Os testes de tela do orçamento (o OrcamentoUITests) saem do job app e rodam no job novo app-etapa3, em paralelo, com o mesmo preparo e sem o build Release: com eles, o app passava do teto de 75 min, e só eles levavam 20,8 min. Sem eles, o app leva ~53 min numa VM normal e chegou a 67 numa lenta (run 39799242127): o teto dele passa a 90. Nos dois jobs, o resultado dos testes sobe também quando o job é cancelado, para um corte no teto deixar o xcresult, e a guarda dos jobs confere que cada suíte de tela que o app pula roda em outro job, uma vez só. No iOS 26 da CI, o arrasto sintetizado da borda às vezes não volta depois de voltar pelo botão e entrar de novo (a tela Orçamento, no run 39710458060): lá, se o que a tela leva embora não some em 2 s, o arrasto se repete uma vez, com um print e uma linha no log; no iOS 27, o teste segue estrito. A barra das teclas encaixadas fica fora da auditoria de tipo dinâmico, como o título da folha (para no xxxLarge, com o Visualizador de Conteúdo Grande), e o que a lista tem embaixo das teclas ou em cima do cabeçalho fixo da folha (o segmentado e o total) fica fora da de contraste, porque está fora da vista (no Pro Max, com a faixa mais alta, as linhas roladas para cima ficam entre a barra e o total). No iOS 26, na letra de acessibilidade, as auditorias de tipo dinâmico e de texto cortado deixam de fora o total ao vivo da folha (o \"Total\", a soma e \"N de M tópicos com valor\"), pelo identificador que cada um dos três textos ganha: ele muda de lugar na fronteira dessa letra (nela, rola com a lista; abaixo dela, fica fixo em cima da lista), e lá a auditoria acusa os três grandes e inteiros. Pelo quadro do total não dava: no iOS 26, a letra vai à padrão enquanto o teste lê os quadros e volta à AX5 dentro da auditoria. O VoiceOver continua lendo o total como um elemento só, com o mesmo rótulo. No lugar, um teste de tela acha os três pelo mesmo identificador, nas duas letras, e mostra que, na maior letra, eles crescem, a soma aparece inteira e nada corta. Com a folha aberta, a de contraste mede a partir da barra da folha, e não da primeira barra da árvore, que é a da tela por trás dela: os itens da barra da folha entram, e o que fica logo abaixo dela também, porque a folha não tem a borda de rolagem das telas. No modo total, a auditoria na maior letra fica no meio do gasto por tópico, e não no fim: ali, enquanto ela diminui a letra, a lista longa encolhe para cima da rolagem e a tela fica vazia, e os achados saem sem elemento; a dica, que só o fim tem, ganha uma guarda de código (cresce com a letra, quebra linha e não tem altura fixa). As cenas da lista da obra da etapa 2 descem de 640 para 758 pt, e a varredura da obra rolando, de 200…1500 para 318…1618, a altura da linha do orçamento da vitrine, para medir o mesmo pedaço da tela de antes (a 640 e a 1200, a borda cortava uma palavra). O laudo casa cada pixel com os de até 1 pt em cima e embaixo no print sem texto, e não só 1 px: com mais de um valor que encolhe em cima, como na tela Orçamento na maior letra no Pro Max, o que vem embaixo muda mais de 1 px com o texto apagado. O teste do medidor cobra o limite novo: até 1 pt é a mesma cena; 1 px além, outra. Na maior letra, a tela Orçamento rolada passa de 1500 para 1637 pt, com a borda de cima no vão entre dois tópicos nos dois iPhones: a 1500, no Pro Max, a barra de um tópico ficava logo abaixo da borda, com texto borrado pelo véu em cima, e o alto dela mudava entre os dois prints. A tabela de exceções do laudo ganha uma entrada, só para a obra com orçamento na maior letra e só para o triângulo do aviso: no Pro Max, o print sem texto desenha o triângulo uma fração de pixel mais baixo, e as bordas dele viravam letra com ele mesmo de fundo; a frase do aviso continua medida. Para isso, o foraDoLaudo do app ganha um nome que uma cena liga, só em Debug. Num iPhone de 375 pt, que nenhum simulador do laudo tem, um teste de unidade confere que nenhuma peça do orçamento passa da largura na maior letra, com e sem negrito."
```

### Task 20: Conferência cruzada do orçamento

A conferência cruzada com o site ganha o roteiro do orçamento, seguido pelo app como a folha grava (o `RascunhoDoOrcamento`, com o modo e as linhas de cada passo, e o "Tirar orçamento"): 1) c3, sem orçamento, define por total (80 mil); 2) c3 passa para por tópico (fundação e elétrica com centavos); 3) c2, a vendida do site, por tópico com `c_apagado` (fora da lista da folha) e `notaDoSite`, é editada (estrutura, outros; o acabamento zerado sai); 4) c2 troca para o total (os tópicos saem, o campo fica); 5) c3 tira; 6) c2 salva vazio (tira). Cada passo é conferido no documento logo depois de o servidor confirmar (`POST /app/orcamento/<n>`), contra o que o site gravaria com as respostas até ali: o fim tira os dois orçamentos, e um roteiro que só comparasse o fim deixaria passar a regra quebrada no meio (a lição da Tarefa 36 da etapa 2).

- **Cada passo parte do documento relido.** É como a pessoa abre a folha depois de chegar o eco da gravação anterior: no app, o eco sem nada pendente passa pelo `Sincronizador.recebeu`, que normaliza (`venda` null e `afazeres` [] nas obras criadas no app e na da venda desfeita) e troca o estado; no site, o `bootCloud` faz o mesmo (só ignora com `localDirty`, normaliza pelo `dados.js` e troca o `db` quando o `canon` muda). Por isso o modelo do site normaliza de novo antes de cada passo do orçamento, e o `CruzadoTests` espera o estado relido (teto de 10 s) antes de seguir. O documento dos roteiros do gasto e da obra, gravados em seguida e sem leitura no meio, fica guardado antes do orçamento (o pedido 0), e é nele que se confere que o app não grava o que a leitura acrescenta.
- A obra do site traz um tópico fora da lista da folha e um campo que só o site conhece no orçamento; o app guarda os dois enquanto o modo for por tópico, e o campo também no total, como o site.
- A conferência roda só no Mac (emuladores e Java), antes de cada envio ao TestFlight.

**Files:**
- Test (alterar): `app-ios/CusttaTests/CruzadoTests.swift`
- Test (alterar): `tests/app-ios/cruzado.mjs`

**Interfaces:**
- Consumes: `RascunhoDoOrcamento` (Tarefa 18), `Estado.salvandoOrcamento` e `Estado.tirandoOrcamento` (Tarefa 11), `topicosDoFormulario` e `reaisParaCentavos` (núcleo); `D.orcamentoGravado` (o `dados.js` do PR 0).
- Produces: nada para as outras tarefas.

- [ ] **Step 1: Escrever o roteiro**

Em `app-ios/CusttaTests/CruzadoTests.swift`:

```diff
--- a/app-ios/CusttaTests/CruzadoTests.swift
+++ b/app-ios/CusttaTests/CruzadoTests.swift
@@ -7,10 +7,11 @@ import CusttaNucleo
 /* Metade app da conferência cruzada (tests/app-ios/cruzado.mjs): entra na conta que o "site" criou, carrega o
    documento e segue os roteiros do site pelas mesmas regras das telas: o dos gastos (lançar no Pix e no cartão
    parcelado, editar um gasto e uma parcela, apagar um gasto e a compra toda) e o da obra (criar, editar, marcar como
-   pronta, vender, desfazer a venda e apagar). O núcleo confere e monta cada mudança, o estado muda pelas mutações e
-   cada passo grava pelo Sincronizador, como um toque em "Salvar", "Confirmar venda" ou "Apagar". Os ids vêm do
-   roteiro, para o site montar o mesmo resultado. O roteiro confere depois, com o SDK JavaScript, que o documento é o
-   que o site gravaria com as mesmas respostas e que nada do site se perdeu. */
+   pronta, vender, desfazer a venda e apagar) e o do orçamento (as respostas da folha pelo rascunho dela, salvar e tirar). O
+   núcleo confere e monta cada mudança, o estado muda pelas mutações e cada passo grava pelo Sincronizador, como um toque
+   em "Salvar", "Confirmar venda" ou "Apagar". Os ids vêm do roteiro, para o site montar o mesmo resultado. O roteiro
+   confere depois, com o SDK JavaScript, que o documento é o que o site gravaria com as mesmas respostas e que nada do site
+   se perdeu; no orçamento, antes e a cada passo, pelo auxiliar do roteiro. */
 @MainActor
 @Suite(.enabled(if: ProcessInfo.processInfo.environment["CUSTTA_CRUZADO"] == "1"))
 struct CruzadoTests {
@@ -79,9 +80,43 @@ struct CruzadoTests {
             ultima = try s.aplicar(try #require(novo, "o passo \(acao) da obra achou o que mudar"))
         }
         try await #require(ultima).confirmada()
+        // Os roteiros do gasto e da obra gravaram em seguida, sem leitura no meio: o roteiro guarda esse documento (o passo 0).
+        try await pedirConferencia(0)
+        // O orçamento (etapa 3): cada passo como a folha grava (o rascunho dela, montado do orçamento do momento, com o modo e as
+        // linhas do passo), e o roteiro confere o documento logo depois de o servidor confirmar. A pessoa abre a folha depois de
+        // chegar o eco da gravação anterior: o estado já é o documento relido, que a leitura normaliza como a do site.
+        let roteiroDoOrcamento = try JSONDecoder().decode(ValorJSON.self, from: Data(try #require(ambiente["CUSTTA_ROTEIRO_ORCAMENTO"]).utf8))
+        for (i, passo) in try #require(roteiroDoOrcamento.comoLista).enumerated() {
+            for _ in 0..<200 where !mesmoConteudo(normaliza(s.estado.arvore), s.estado.arvore) { try await Task.sleep(for: .milliseconds(50)) }
+            try #require(mesmoConteudo(normaliza(s.estado.arvore), s.estado.arvore), "o eco da gravação antes do passo \(i + 1) do orçamento não chegou")
+            let p = try #require(passo.comoObjeto)
+            let obraId = try #require(p["obra"]?.comoTexto)
+            let obra = try #require(s.estado.obras.first { $0.id == obraId }, "a obra \(obraId) do roteiro")
+            let novo: Estado?
+            if p["acao"]?.comoTexto == "tirar" {
+                novo = s.estado.tirandoOrcamento(daObra: obraId)
+            } else {
+                let r = RascunhoDoOrcamento(obra: obra, topicos: topicosDoFormulario(s.estado.config.topicosProprios))
+                r.trocarModo(p["modo"]?.comoTexto == "topicos" ? .topicos : .total)
+                r.total = reaisParaCentavos(p["total"]?.comoNumero ?? 0)
+                for t in r.topicos { r.definir(.topico(t.id), reaisParaCentavos(p["valores"]?.comoObjeto?[t.id]?.comoNumero ?? 0)) }
+                let g = r.gravacao
+                novo = s.estado.salvandoOrcamento(modo: g.modo, total: g.total, valores: g.valores, naObra: obraId)
+            }
+            try await s.aplicar(try #require(novo, "o passo \(i + 1) do orçamento achou a obra")).confirmada()
+            try await pedirConferencia(i + 1)
+        }
         s.parar()
     }
 
+    /// Pede ao roteiro que confira o documento do momento: o do passo n do orçamento, ou o de antes dele (0).
+    private func pedirConferencia(_ n: Int) async throws {
+        var pedido = URLRequest(url: try #require(URL(string: "http://127.0.0.1:8124/app/orcamento/\(n)")))
+        pedido.httpMethod = "POST"
+        let (corpo, resposta) = try await URLSession.shared.data(for: pedido)
+        #expect((resposta as? HTTPURLResponse)?.statusCode == 200, "\(String(decoding: corpo, as: UTF8.self))")
+    }
+
     private func camposDoRoteiro(_ passo: [String: ValorJSON]) throws -> CamposDaObra {
         let c = try #require(passo["campos"]?.comoObjeto)
         return CamposDaObra(nome: try #require(c["nome"]?.comoTexto), dataInicio: c["dataInicio"]?.comoTexto ?? "",
```

Em `tests/app-ios/cruzado.mjs`:

```diff
--- a/tests/app-ios/cruzado.mjs
+++ b/tests/app-ios/cruzado.mjs
@@ -10,11 +10,16 @@
      3. o teste pede a v2 (POST no auxiliar abaixo) e espera ver os números novos sozinhos;
      4. CruzadoTests segue os roteiros abaixo pelas regras das telas do app: o dos gastos (lançar no Pix e no
         cartão parcelado com juros, editar um gasto do site e uma parcela, apagar um gasto da obra vendida e a
-        compra toda) e o da obra (criar três, editar, marcar como pronta, vender, desfazer a venda da obra vendida
-        do site e apagar a terceira criada), gravando cada passo pelo Sincronizador;
+        compra toda), o da obra (criar três, editar, marcar como pronta, vender, desfazer a venda da obra vendida
+        do site e apagar a terceira criada) e o do orçamento (definir por total, passar para por tópico, editar
+        por tópico guardando o tópico fora da lista e o campo que só o site conhece, trocar para o total, tirar e
+        salvar vazio), gravando cada passo pelo Sincronizador; antes do orçamento e a cada passo dele, pede a este
+        roteiro (POST no auxiliar) que confira o documento daquele momento contra o que o site gravaria até ali, e
+        cada passo do orçamento parte do documento relido, como a pessoa abre a folha depois do eco da gravação;
      5. este roteiro confere que o documento final foi gravado pelo app (o _atualizado avançou), que é
         exatamente o que o site gravaria com as mesmas respostas (dados.js, com os mesmos ids), sem perder os
-        campos que só o site conhece nem pôr o que a leitura acrescentaria, e que o site soma o resultado.
+        campos que só o site conhece nem pôr o que a leitura acrescentaria (no documento antes do orçamento,
+        gravado sem leitura no meio), e que o site soma o resultado.
    Teste pulado não passa: sem o pedido de mudança ou sem a gravação do app, o roteiro falha. */
 import assert from 'node:assert/strict';
 import { createServer } from 'node:http';
@@ -52,8 +57,10 @@ const v1 = {
     { id: 'c1', nome: 'Casa do teste cruzado', dataInicio: '2026-01-10', fase: 'construcao', campoSoDoSite: { versao: 7 },
       valorEstimadoVenda: 600000, orcamento: { modo: 'total', total: 50000 },
       gastos: [{ id: 'x1', valor: 12345.67, topico: 'fundacao', descricao: 'Sapatas', data: '2026-02-01', pagamento: 'pix', notaSoDoSite: 'fica' }] },
+    /* O orçamento por tópico com um tópico fora da lista da folha (um tópico próprio apagado) e um campo que só o site
+       conhece: o app guarda os dois, e o site de antes do PR 0 da etapa 3 perdia (achado 7). */
     { id: 'c2', nome: 'Sobrado vendido', dataInicio: '2025-03-01', fase: 'vendida', venda: { valor: 480000, data: '2025-12-20' },
-      orcamento: { modo: 'topicos', topicos: { estrutura: 100000, acabamento: 50000 } },
+      orcamento: { modo: 'topicos', topicos: { estrutura: 100000, acabamento: 50000, c_apagado: 7000 }, notaDoSite: 'fica' },
       gastos: [
         { id: 'y1', valor: 120000, topico: 'estrutura', descricao: 'Laje', data: '2025-04-10', pagamento: 'pix' },
         { id: 'y2', valor: 61000.5, topico: 'acabamento', descricao: 'Porcelanato', data: '2025-09-02', pagamento: 'pix' },
@@ -95,9 +102,27 @@ const roteiroDaObra = [
   { acao: 'desfazer', obra: 'c2' },
   { acao: 'apagarObra', obra: 'appo3' },
 ];
-/** O que o site gravaria com as mesmas respostas: as regras do dados.js e os filtros do apagar do app.js. */
-function comoOSite(blob){
-  const db = D.normaliza(structuredClone(blob));
+/* O roteiro do orçamento (etapa 3): o que a pessoa responde na folha "Orçamento da obra" (o modo e as linhas com valor; a
+   linha que não está aqui vai vazia) e o "Tirar orçamento". A obra c3 começa sem orçamento; a c2, por tópico, com o tópico
+   fora da lista e o campo do site. Cada passo é conferido no documento: a c2 termina sem orçamento, e o que o passo 3 e o
+   4 guardaram só a conferência deles prova (um roteiro que só compara o fim deixaria passar a regra quebrada no meio). */
+const roteiroDoOrcamento = [
+  { acao: 'salvar', obra: 'c3', modo: 'total', total: 80000 },
+  { acao: 'salvar', obra: 'c3', modo: 'topicos', valores: { fundacao: 30000, eletrica: 5000.5 } },
+  { acao: 'salvar', obra: 'c2', modo: 'topicos', valores: { estrutura: 110000, outros: 3000 } },
+  { acao: 'salvar', obra: 'c2', modo: 'total', total: 120000 },
+  { acao: 'tirar', obra: 'c3' },
+  { acao: 'salvar', obra: 'c2', modo: 'total', total: 0 },
+];
+/** As linhas da folha do orçamento do site (o topicos() do app.js): os fixos e depois os próprios, cada uma com o valor dado
+    ou vazia (0), como o "Salvar" lê. */
+const valoresDaFolha = (db, dados = {}) => Object.fromEntries([...C.TOPICOS.map(t => t.id), ...db.config.topicosCustom.map(t => t.id)]
+  .map(id => [id, dados[id] || 0]));
+
+/** O que o site gravaria com as mesmas respostas: as regras do dados.js e os filtros do apagar do app.js; do roteiro do
+    orçamento, os `passosDoOrcamento` primeiros, cada um a partir do documento relido. */
+function comoOSite(blob, passosDoOrcamento = roteiroDoOrcamento.length){
+  let db = D.normaliza(structuredClone(blob));
   const fila = [...ids], novoId = () => fila.shift();
   for(const p of roteiro){
     const o = db.obras.find(x => x.id === p.obra);
@@ -119,6 +144,16 @@ function comoOSite(blob){
     else if(p.acao === 'desfazer'){ delete o.venda; o.fase = 'pronta'; }
     else db.obras = db.obras.filter(x => x.id !== p.obra);
   }
+  /* O orçamento: o formOrcamento do app.js (orcamentoGravado do dados.js; vazio tira a chave) e o "Tirar orçamento". Cada passo
+     parte do documento relido: a pessoa abre a folha depois de chegar o eco da gravação anterior, e o site troca o db pelo
+     documento normalizado (bootCloud do app.js), como o app (Sincronizador.recebeu) e como um outro aparelho o lê; a leitura
+     põe afazeres e venda null nas obras que não têm (as criadas no app, a da venda desfeita). */
+  for(const p of roteiroDoOrcamento.slice(0, passosDoOrcamento)){
+    db = D.normaliza(db);
+    const o = db.obras.find(x => x.id === p.obra);
+    const novo = p.acao === 'tirar' ? null : D.orcamentoGravado(o.orcamento, p.modo, p.total || 0, valoresDaFolha(db, p.valores));
+    if(novo) o.orcamento = novo; else delete o.orcamento;
+  }
   return db;
 }
 
@@ -134,15 +169,41 @@ const esperado = blob => D.normaliza(blob).obras.map(o => ({ id: o.id, nome: o.n
 await gravarComoOSite(v1);
 
 let siteMudou = false;
+/* Depois de cada passo do orçamento, o app pede a conferência do documento daquele momento: 200 quando é o que o site gravaria
+   com as respostas até ali, 409 com as duas versões da obra quando não é. Antes do primeiro (o passo 0), pede que este roteiro
+   guarde o documento dos roteiros do gasto e da obra, gravados em seguida, sem leitura no meio: é nele que se confere que o app
+   não grava o que a leitura acrescenta. */
+const conferidos = [];
+let antesDoOrcamento;
 const auxiliar = createServer(async (req, res) => {
   if(req.method === 'POST' && req.url === '/site/mudar'){ await gravarComoOSite(v2); siteMudou = true; res.end('ok'); return; }
+  const passo = /^\/app\/orcamento\/(\d+)$/.exec(req.url);
+  if(req.method === 'POST' && passo){
+    const n = Number(passo[1]);
+    const doc = (await getDocFromServer(documento)).data();
+    delete doc._atualizado;
+    if(n === 0){ conferidos.push(n); antesDoOrcamento = doc; res.end('ok'); return; }
+    const doSite = comoOSite(v2, n);
+    const obra = roteiroDoOrcamento[n - 1].obra;
+    const igual = C.canon(doc) === C.canon(doSite);
+    conferidos.push(n);
+    if(!igual){
+      res.statusCode = 409;
+      const daObra = d => JSON.stringify(d.obras.find(o => o.id === obra)?.orcamento ?? null);
+      res.end(`passo ${n} (${obra}): o app gravou ${daObra(doc)}, o site gravaria ${daObra(doSite)}`);
+      return;
+    }
+    res.end('ok');
+    return;
+  }
   res.statusCode = 404; res.end();
 });
 await new Promise(r => auxiliar.listen(8124, '127.0.0.1', r));
 
 const env = { CUSTTA_CRUZADO: '1', CUSTTA_EMULADORES: '1', CUSTTA_EMAIL: email, CUSTTA_SENHA: senha,
   CUSTTA_ESPERADO_V1: JSON.stringify(esperado(v1)), CUSTTA_ESPERADO_V2: JSON.stringify(esperado(v2)),
-  CUSTTA_ROTEIRO: JSON.stringify(roteiro), CUSTTA_IDS: ids.join(','), CUSTTA_ROTEIRO_OBRA: JSON.stringify(roteiroDaObra), CUSTTA_HOJE: HOJE };
+  CUSTTA_ROTEIRO: JSON.stringify(roteiro), CUSTTA_IDS: ids.join(','), CUSTTA_ROTEIRO_OBRA: JSON.stringify(roteiroDaObra), CUSTTA_HOJE: HOJE,
+  CUSTTA_ROTEIRO_ORCAMENTO: JSON.stringify(roteiroDoOrcamento) };
 let antesDoApp;
 try{
   await testarNoSimulador(['CusttaUITests/CruzadoUITests'], env);
@@ -150,11 +211,13 @@ try{
   antesDoApp = (await getDocFromServer(documento)).data()._atualizado;
   await testarNoSimulador(['CusttaTests/CruzadoTests'], env);
 }finally{ auxiliar.close(); }
+assert.deepEqual(conferidos, [0, ...roteiroDoOrcamento.map((_, i) => i + 1)], 'o app pediu a conferência do documento antes do orçamento e de cada passo dele, na ordem');
 
 const final = (await getDocFromServer(documento)).data();
 assert.ok(final._atualizado instanceof Timestamp, 'a gravação do app leva _atualizado do servidor');
 assert.ok(final._atualizado.toMillis() > antesDoApp.toMillis(), 'o documento não foi regravado depois do teste do app: ele foi pulado ou não gravou');
 delete final._atualizado;
+assert.equal(C.canon(antesDoOrcamento), C.canon(comoOSite(v2, 0)), 'os roteiros do gasto e da obra gravaram o que o site gravaria com as mesmas respostas, sem tirar nem pôr nada');
 const v3 = comoOSite(v2);
 assert.equal(C.canon(final), C.canon(v3), 'o app gravou o que o site gravaria com as mesmas respostas, sem tirar nem pôr nada');
 const porId = id => final.obras.find(o => o.id === id);
@@ -175,7 +238,8 @@ assert.deepEqual(compraDoApp[0].jurosCartao, { taxaMensal: 2.5, valorCompra: 300
   'as condições da compra, iguais nas parcelas');
 assert.equal(C.money(C.totalBruto(D.normaliza(final).obras.find(o => o.id === 'c1'))), C.money(12000 + 40000 + 999.99 + cartao.totalCompra), 'o site soma o que o app gravou');
 // A obra (etapa 2, parte 3).
-assert.ok(!('afazeres' in criada) && !('venda' in criada), 'a obra criada no app vai como o obraNova do site: sem afazeres e sem venda (a leitura acrescenta)');
+const antes = id => antesDoOrcamento.obras.find(o => o.id === id);
+assert.ok(!('afazeres' in antes('appo1')) && !('venda' in antes('appo1')), 'a obra criada no app vai como o obraNova do site: sem afazeres e sem venda (a leitura acrescenta)');
 assert.equal(criada.areaM2, 3.125, 'a área com três casas chega inteira');
 assert.deepEqual(criada.orcamento, { modo: 'total', total: 120000 }, 'o orçamento total da obra nova');
 assert.equal(criada.valorEstimadoVenda, 350000);
@@ -189,7 +253,9 @@ assert.deepEqual(c1.orcamento, { modo: 'total', total: 50000 }, 'editar a obra n
 assert.equal(c1.fase, 'vendida');
 assert.deepEqual(c1.venda, { valor: 650000, data: '2026-04-01' }, 'a venda como o site grava');
 assert.equal(c2.fase, 'pronta');
-assert.ok(!('venda' in c2), 'desfazer a venda tira a chave, como o delete do site');
+assert.ok(!('venda' in antes('c2')), 'desfazer a venda tira a chave, como o delete do site');
+// O orçamento (etapa 3): o fim do roteiro tira os dois (o que cada passo gravou, a conferência dele provou).
+assert.ok(!('orcamento' in c2) && !('orcamento' in c3), 'tirar e salvar vazio tiram a chave, como o delete do site');
 await terminate(db);
-console.log('ok - site e app na mesma conta: totais e orçamentos iguais, mudança do site chegou ao app, e os roteiros do gasto e da obra gravaram o que o site gravaria, sem perder nada');
+console.log('ok - site e app na mesma conta: totais e orçamentos iguais, mudança do site chegou ao app, e os roteiros do gasto, da obra e do orçamento gravaram o que o site gravaria, passo a passo no orçamento, sem perder nada');
 process.exit(0);
```

- [ ] **Step 2: Ver falhar**

Com o `cruzado.mjs` novo e o `CruzadoTests.swift` de antes (o app ainda não pede a conferência de cada passo):

Run: `CUSTTA_SIMULADOR=<udid> npm run test:app-ios:cruzado 2>&1 | grep -m1 AssertionError`
Expected: `AssertionError [ERR_ASSERTION]: o app pediu a conferência de cada passo do orçamento, na ordem`.

- [ ] **Step 3: Ver passar**

Run: `CUSTTA_SIMULADOR=<udid> npm run test:app-ios:cruzado 2>&1 | grep -E "passed|^ok|not ok" | tail -4`
Expected: `CruzadoUITests` passa; `✔ Test appSegueOsRoteirosDoSite() passed`; `ok - site e app na mesma conta: … passo a passo no orçamento, sem perder nada`. Com a gravação sem as linhas vazias (o acabamento zerado que não sai), reprova só o passo 3: `passo 3 (c2): o app gravou {…"acabamento":50000…}, o site gravaria {…}`.

- [ ] **Step 4: Commit**

```bash
git add app-ios/CusttaTests/CruzadoTests.swift \
  tests/app-ios/cruzado.mjs
git commit -m "test: conferência cruzada do orçamento" -m "A conferência cruzada com o site ganha o roteiro do orçamento, seguido pelo app como a folha grava (o rascunho dela, com o modo e as linhas de cada passo, e o \"Tirar orçamento\"): definir por total, passar para por tópico, editar por tópico a obra vendida do site, trocar para o total, tirar e salvar vazio. Cada passo é conferido no documento logo depois de o servidor confirmar, contra o que o site gravaria com as respostas até ali: um roteiro que só comparasse o fim deixaria passar a regra quebrada no meio, porque o fim tira os dois orçamentos. Cada passo parte do documento relido, como a pessoa abre a folha depois de chegar o eco da gravação anterior: o app e o site trocam o estado pelo documento normalizado, que põe afazeres e venda null nas obras criadas no app e na da venda desfeita. Por isso o documento dos roteiros do gasto e da obra, gravados em seguida e sem leitura no meio, fica guardado antes do orçamento, e é nele que se confere que o app não grava o que a leitura acrescenta. A obra do site traz um tópico fora da lista da folha e um campo que só o site conhece no orçamento; o app guarda os dois enquanto o modo for por tópico, e o campo também no total, como o site."
```

### Task 21: Checklist do aparelho da etapa 3

O checklist que o Giovani roda no iPhone a cada build da etapa 3, na conta de sempre, no estilo do da etapa 2: antes do primeiro build, a cópia dos dados e o PR 0 do site no ar; e os itens do PR 1. Na obra, o "Definir orçamento" e a linha nos três níveis; a tela Orçamento, com o cartão, o "Por tópico", o que está fora e o modo total; a folha, com as teclas encaixadas, a troca de modo, o tirar e o salvar vazio, o teto, o toque duplo, o modo avião e a mudança vinda do site com a folha aberta; a rolagem até a linha sem Reduzir movimento, que só o aparelho prova no iOS 26; a maior letra; o "A vencer" que empilha; e a acessibilidade de cada tela, com VoiceOver, Controle por Voz e Controle Assistivo, mais o âmbar sobre o vidro e o secundário mais claro das telas de entrada no escuro. Os PRs 2 e 3 completam o mesmo arquivo.

**Files:**
- Create: `docs/plans/2026-10-19-app-nativo-etapa3-checklist-aparelho.md`

- [ ] **Step 1: Escrever o checklist**

Criar `docs/plans/2026-10-19-app-nativo-etapa3-checklist-aparelho.md`:

```markdown
# App nativo, etapa 3: checklist no iPhone

O Giovani roda no iPhone, pelo TestFlight, a cada build da etapa 3 (um por PR do app), **na conta de sempre**. Cada item que falhar vira tarefa para o Forja, com o passo, o que apareceu e uma captura de tela. Os itens de um PR continuam valendo nos builds seguintes.

## Antes do primeiro build

O app grava na conta de sempre desde o fim da etapa 2, e cada gravação regrava o documento inteiro da conta, o orçamento também.

- [ ] No site: Ajustes → Seus dados → Exportar dados completos. Guarde o arquivo (`custta-AAAA-MM-DD.json`) fora do repositório, como cópia de segurança.
- [ ] O PR 0 do site já está publicado (o site e o app com as mesmas regras do orçamento): no site, numa obra com orçamento por tópico, abra a folha do orçamento e salve sem mudar nada; ela continua igual.

## PR 1: o orçamento

**Na tela da obra**

- [ ] Numa obra sem orçamento, em construção ou pronta: "Definir orçamento" aparece depois das ações da fase, numa pílula de vidro. Numa obra vendida sem orçamento, não aparece (como no site).
- [ ] "Definir orçamento": a folha "Orçamento da obra" abre em "Só o total", com as teclas já abertas embaixo, o "Salvar" apagado até ter valor e sem "Tirar orçamento". Digite um total e salve: a folha desce e a linha do orçamento aparece logo abaixo do Total gasto, com o nível ("dentro do previsto", "perto do limite" ou "passou do previsto"), quanto sobra ou passou, a barra e "N% usado de R$ …". No site, o mesmo orçamento.
- [ ] Os três níveis: mude o total pelo lápis da tela Orçamento até o uso passar de 90% e depois de 100%. Perto e passou vêm em âmbar, nunca em vermelho; no "passou", a barra para no previsto, com uma fresta, e o excesso vem listrado.
- [ ] Com orçamento por tópico: a linha traz o pior aviso dos tópicos ("N tópicos passaram do previsto" ou "N perto do limite") em âmbar, com o triângulo, e o que está fora do orçamento.
- [ ] Obra vendida com orçamento: a linha continua, como o orçamento fechou; o lápis da tela Orçamento edita e tira (como no site).

**A tela Orçamento**

- [ ] Toque na linha do orçamento: a tela Orçamento abre, com o título grande e o lápis na barra. Volte pelo círculo do topo e, de novo, arrastando da borda esquerda.
- [ ] O cartão: "Orçamento por tópico" ou "Orçamento total", o nível, o gasto, "de R$ … previstos em N tópicos" (no modo por tópico), a barra, "N% usado" e quanto sobra ou passou. Com gasto fora do orçamento, a frase "Os R$ … fora do orçamento não entram nesta conta.". Os números são os do site.
- [ ] "Por tópico": os tópicos na ordem do site (quem passou do previsto primeiro), cada um com o gasto, "/ previsto", a barra fina e a frase do site ("Passou R$ 6,2 mil do previsto", "Faltam R$ 3,3 mil — 96%", "Chegou ao previsto — 100%"); o "Passou…" em âmbar. Um nome comprido quebra, e o valor fica numa linha só.
- [ ] "Fora do orçamento": o total, "Tópico sem valor não entra na comparação." e uma linha por tópico fora, do maior gasto para o menor.
- [ ] No modo total: "Gasto por tópico" (o bruto e a parte da obra de cada tópico) e, no fim, "Para comparar tópico a tópico, toque no lápis e escolha "Por tópico"."
- [ ] Neste build, as linhas de tópico não têm seta e não abrem nada: o detalhe do tópico chega no PR 2.
- [ ] O + na tela Orçamento lança gasto na obra dela; ao salvar, a tela Orçamento mostra os números novos e continua aberta.
- [ ] Apague a obra no site com a tela Orçamento aberta no iPhone: o app volta para a lista de Obras.

**A folha "Orçamento da obra"**

- [ ] Pelo lápis da tela Orçamento, a folha abre no modo salvo. "Por tópico" mostra os 21 tópicos fixos e depois os seus, e o total ao vivo ("R$ … · N de M tópicos com valor").
- [ ] Toque numa linha: as teclas abrem embaixo da folha, com a barra "‹ › Elétrica · 9 de N Pronto"; a linha acende, com o cursor piscando. ‹ e › andam pelas linhas sem fechar as teclas e, nas pontas, não fazem nada; "Pronto" fecha.
- [ ] Sem Reduzir movimento, com as teclas fechadas, toque numa linha de baixo (Hidráulica): as teclas abrem e a linha desliza uma vez até o meio, entre o alto da lista e as teclas, inteira, sem pulo e sem passar por baixo delas; com Reduzir movimento, ela já aparece no meio, sem deslizar.
- [ ] A cada ›, até o último tópico, a linha ativa aparece inteira entre o alto da lista e as teclas.
- [ ] Teto: depois de R$ 99.999.999,99, a tecla é ignorada (o site não tem teto).
- [ ] Com o total vazio, troque para "Só o total": ele vem com a soma dos tópicos e a frase "Preenchido com a soma dos tópicos.". Trocar de modo não grava: feche pelo × e aparece "Você mudou este orçamento." ("Descartar alterações" / "Continuar editando"). No "Definir", fechar depois de digitar pergunta "Você já preencheu este orçamento." ("Descartar orçamento"). Puxar a folha para baixo pergunta igual.
- [ ] No modo total, o rodapé diz "Comparado com o Total gasto (bruto), com as parcelas a vencer."
- [ ] "Tirar orçamento" pergunta "Tirar o orçamento desta obra?" / "Os gastos continuam como estão."; "Cancelar" não muda nada; "Tirar orçamento" tira: a folha desce já na obra (a tela Orçamento voltou por trás), a linha some e "Definir orçamento" volta. No site também.
- [ ] Apague todos os valores e toque em "Salvar": a mesma pergunta do "Tirar orçamento" (no site, tira sem perguntar).
- [ ] Toque duas vezes seguidas, rápido, no "Salvar": o orçamento grava uma vez (no site, igual).
- [ ] Modo avião com os dados já vistos: defina um orçamento; a pílula mostra "Sem conexão"; ao voltar a internet, o site mostra o orçamento.
- [ ] Modo avião logo depois de instalar (antes de o app ver os dados): o "Salvar" avisa dentro da folha, com "O orçamento continua aqui; nada foi salvo ainda.", e a folha não fecha.
- [ ] Com a folha aberta no iPhone, mude o orçamento no site: a folha não muda; ao salvar, vale o que está na folha. O que a folha não mostra (um tópico próprio apagado com valor no orçamento) continua no site.
- [ ] Teclado físico (se tiver um teclado Bluetooth): com as teclas abertas, os dígitos e o apagar entram na linha ativa.

**Texto Maior no máximo** (Ajustes do iPhone → Acessibilidade → Tela e Tamanho do Texto → Texto Maior)

- [ ] Na linha do orçamento e na tela Orçamento, o dinheiro de dentro das frases vai para a própria linha e encolhe para caber; o chip do nível quebra em duas linhas; nos tópicos, cada informação fica numa linha, sem o ícone.
- [ ] Na folha, o segmentado e o total rolam com a lista; as teclas param de crescer num ponto; com as teclas abertas, o "Salvar" sai e a barra fica sem o nome; "Pronto" fecha e o "Salvar" volta. No "Só o total", a barra aparece só com o "Pronto".
- [ ] O cabeçalho do "A vencer" empilha título, valor e linha de baixo, e o valor encolhe para caber (a correção do mockup da etapa 2, que o app já fazia).

**Acessibilidade**

- [ ] VoiceOver, na obra: a linha do orçamento é um elemento só, que lê o nível, quanto sobra ou passou, quanto foi usado e o aviso dos tópicos; dois toques abrem a tela Orçamento.
- [ ] VoiceOver, na tela Orçamento: o cartão e cada linha de tópico são lidos inteiros, um elemento cada, sem "botão" nas linhas de tópico.
- [ ] VoiceOver, na folha: dois toques numa linha abrem as teclas nela; ouve-se "Elétrica, 9 de N, R$ …" e o foco vai para a linha ativa. No rotor da linha ativa, as ações "Tópico anterior", "Próximo tópico" e "Pronto". Cada tecla fala o valor novo. Diga o que o VoiceOver fala a cada tecla e a cada troca de tópico, e se alguma coisa sobra ou falta.
- [ ] VoiceOver, gesto de escape (Z com dois dedos): com as teclas abertas, fecha as teclas; sem elas, faz o mesmo que o ×. Ao trocar para "Só o total" com o total vazio, ouve-se "Preenchido com a soma dos tópicos.".
- [ ] Controle por Voz ("Mostrar nomes"): na obra, "Tocar Definir orçamento" abre a folha e "Tocar Orçamento" abre a tela Orçamento; nela, "Tocar Editar orçamento" abre a folha; na folha, o nome de cada linha de tópico abre as teclas nela, e "Tocar Próximo tópico", "Tocar Tópico anterior", "Tocar Pronto" e "Tocar Salvar" funcionam.
- [ ] Controle Assistivo (varredura por item): na folha, a varredura passa pelas linhas, pela barra (‹, ›, Pronto), pelas teclas e pelo "Salvar"; dá para definir um orçamento por tópico e salvar só pela varredura.
- [ ] No escuro e no claro, o aviso dos tópicos e o "Passou … do previsto" em âmbar se leem sobre o vidro (no claro, um âmbar mais escuro, `#6F4705`).
- [ ] Nas telas de entrar e criar conta, no escuro: o texto secundário ficou um pouco mais claro (a decisão 6 da parte 2). Diga se incomoda.
```

- [ ] **Step 2: Ver passar**

Run: `node --test tests/docs.test.mjs 2>&1 | tail -8 | grep -E "ℹ (pass|fail)"`
Expected: `ℹ pass 7`, `ℹ fail 0`.

- [ ] **Step 3: Commit**

```bash
git add docs/plans/2026-10-19-app-nativo-etapa3-checklist-aparelho.md
git commit -m "docs: checklist do aparelho da etapa 3 do app nativo" -m "O checklist que o Giovani roda no iPhone a cada build da etapa 3, na conta de sempre, no estilo do da etapa 2: antes do primeiro build, a cópia dos dados e o PR 0 do site no ar; e os itens do PR 1, o orçamento. Na obra, o \"Definir orçamento\" e a linha nos três níveis; a tela Orçamento, com o cartão, o \"Por tópico\", o que está fora e o modo total; a folha, com as teclas encaixadas, a troca de modo, o tirar e o salvar vazio, o teto, o toque duplo, o modo avião e a mudança vinda do site com a folha aberta; a maior letra; e a acessibilidade de cada tela, com VoiceOver, Controle por Voz e Controle Assistivo, mais o âmbar sobre o vidro, no escuro e no claro, e o secundário mais claro das telas de entrada no escuro."
```

**Ponto de controle do PR 1:** CI verde (`nucleo`, `app`, `app-etapa3`, `laudo`, `laudo-parte3`, `laudo-etapa3` e `auditoria`; no fim do PR, o núcleo com 219 testes, o `CusttaTests` com 144 em 26 suítes e o `OrcamentoUITests` com 28); no Mac, `npm run test:app-ios:emuladores` e `npm run test:app-ios:cruzado` verdes, e as leituras e auditorias do orçamento também no Pro Max; o Verniz confere as telas novas lado a lado com o mockup (parte 1, seções 1 a 3), nos dois temas e na maior letra. Depois do merge, o Orquestrador dispara o `app-ios-testflight` com o OK do Giovani, e o Giovani faz a parte "PR 1" do checklist na conta de sempre. Na CI do iOS 26, antes das correções (run 39693700450), passaram a cena da tela Orçamento a 2200 pt na maior letra, a linha ativa que volta ao meio na troca de letra, os itens da barra da folha na auditoria de contraste e a rolagem da folha sem Reduzir movimento; reprovaram o teste do medidor da etapa 2 e o total ao vivo na auditoria (Tarefa 19) e a linha ativa ao abrir a folha na maior letra (Tarefa 18), corrigidos nelas. Na segunda rodada (run 39710458060, com o PR 2 por cima), as duas leituras do orçamento passaram. Três coisas reprovaram: a exceção do total pelo quadro, na auditoria de depois do swipe; o `app`, cortado no teto; e uma vez a borda da tela Orçamento. A exceção passou a ser pelo identificador, nasceu o `app-etapa3` e a borda ganhou a segunda tentativa no iOS 26 (Tarefa 19), tudo verde no run 39813469497. Só o iOS 26 prova, e o Mac não tem: a conferência da linha ativa na lista preguiçosa, a exceção do total e a segunda tentativa da borda, que só rodam lá. O âmbar do escuro e as cinco exceções ao mockup foram decididos pelo Giovani em 21/10 (Decisões do conselho).

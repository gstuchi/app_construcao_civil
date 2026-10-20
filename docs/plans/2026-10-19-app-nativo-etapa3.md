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

Do Giovani, em 18/10 ("sim nas três"), e do protótipo do PR 0. As decisões dos PRs do app, inclusive as do conselho de 19/10, estão em "Decisões do conselho", antes do PR 1.

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

Em preparação: as seções dos PRs do app entram aqui, depois das decisões do conselho de 19/10.

# Análise (etapa 4 do app nativo), marco 2 — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.
>
> Neste time, o Forja implementa uma tarefa por vez e a Lupa revisa cada uma antes da próxima. Nas tarefas de tela, o Verniz confere o simulador lado a lado com o mockup aprovado. Ninguém faz commit, push ou PR sem o Orquestrador pedir.

**Goal:** Entregar o marco 2 da etapa 4, que termina num build no TestFlight com o OK do Giovani. São três PRs:
- **4a:** a aba "Vale a pena?", o simulador do site na identidade nova, com a cápsula de três abas;
- **2a:** os Gráficos, com a tela e o anel dos tópicos;
- **2b:** a evolução e o gasto por mês, e a porta da obra para os Gráficos. Fecha o marco.

Este documento traz o **4a inteiro**, tarefa por tarefa, com o código provado. O 2a e o 2b vêm em tabela (seção "Depois do 4a"); as tarefas deles com código entram neste plano quando as fatias de cada um estiverem provadas.

**Architecture:** O que a tela mostra sai do `CusttaNucleo` (`simulacaoNaTela`), com teste próprio. Os campos moram no `PrincipalView`, para durarem enquanto o app está aberto (**desvio do spec**, que os põe na aba: só a aba escolhida fica montada, e na aba eles se perderiam a cada troca; tarefa 4. Daqui em diante, mexer nos campos toca um arquivo compartilhado e leva o PR ao nível `tudo`); a tela da aba e as peças dela moram em `Custta/Analise/`. As teclas do preço entram na área segura de baixo da tela da aba, e o `PrincipalView` só tira a cápsula enquanto elas estão abertas. Os testes da análise moram nas pastas `Analise` de `CusttaTests` e de `CusttaUITests`: é por elas que o filtro de portões da CI sabe o que é "tela nova".

**Tech Stack:** SwiftUI no iOS 26 (Swift 6 estrito; Xcode 26.6 na CI), Swift Testing, XCTest e XCUITest, e o pacote `CusttaNucleo`. Na CI, Node (`node:test`) para o filtro de portões.

**Spec:** [`docs/specs/2026-10-29-app-nativo-etapa4-design.md`](../specs/2026-10-29-app-nativo-etapa4-design.md), seções "Vale a pena?", "PRs" e "Portões por superfície". Mockup aprovado: `~/Documents/custta-mockups/nativo/etapa4/` (parte 2). Checklist do aparelho: [`2026-10-29-app-nativo-etapa4-checklist-aparelho.md`](2026-10-29-app-nativo-etapa4-checklist-aparelho.md).

## Como este plano foi feito

Cada tarefa do 4a é um commit num clone, sobre a `main` em `acedc24`, com teste, mutação e rodada no simulador antes de virar tarefa. O texto abaixo é gerado desses commits: a mensagem, os arquivos e o diff são os deles. A linha **Prova** de cada tarefa diz o que rodou e o que não foi provado. O Mac tem os simuladores do iOS 27 e do iOS 26.5; a CI roda o iOS 26.

O histórico fica como foi feito: a tarefa 8 põe as auditorias da aba no `AuditoriaUITests` e a 3 põe as cenas no `LeituraNoVidroUITests`; a 11 as leva para as pastas `Analise`. Quem refaz o 4a do zero pode escrevê-las direto lá. Do mesmo jeito, a mensagem da tarefa 14 diz que o laudo das marcas da faixa ficou de fora; a 18 o traz, com a zona recortada, e a 20 o aperta. E a tarefa 9 trata o apagar como as outras teclas (o teste `oZeroEOApagarNaPrimeiraTeclaNaoMudamNada`); a 19 o faz limpar o campo e renomeia o teste: quem refaz pode escrever direto a regra da 19.

O PR #126 aplica estas tarefas, com quatro diferenças:
- o conserto do trilho (tarefa 10 aqui) entrou lá antes das teclas (tarefa 9);
- lá há um commit a mais, `de3a3c7 test: menores da revisão do "Vale a pena?"` (a taxa de 1,5% no `SimulacaoNaTelaTests` e o `abrirAAba` pelo gancho no `ValeAPenaUITests`), que não está aqui;
- as rolagens das cenas da maior letra no Pro Max, que o Forja acerta num commit próprio lá;
- as tarefas 18 a 22 (a zona recortada, o apagar, o laudo das marcas pela forma, a fala do campo limpo e a cena da venda abaixo do banco) chegam lá pelos patches do Prumo.

## Decisões

**Do Giovani** (24/11/2026, repassadas pelo Orquestrador):

| # | Decisão |
|---|---|
| 3 | O marco 2 segue só com o mockup aprovado, sem esperar as referências 1, 2, 6 e 8 do spec. |
| 4 | O preparo dos testes (abas numa lista só, gancho da aba inicial) vai dentro do 4a, e não num PR próprio. |
| 6 | Na sonda do contraste das marcas, cor ou placa só se decide se ela reprovar, com o Croqui. |
| 7 | O campo do preço: as teclas abrem com o valor à vista, o primeiro dígito o substitui, e o OK sem digitar deixa como estava. |
| 6, depois da sonda | As marcas da faixa reprovaram (1,90:1 no escuro e 2,96:1 no claro). Das saídas do Croqui, a (c): a zona recortada em volta das marcas, sem cor nem token novo ("vai de c nas marcas"). |
| 7, o apagar | Com o valor à vista, o apagar como primeira tecla limpa o campo ("apagar limpa o campo"). O 0 e o 00 como primeira tecla ficam como estão: ele não decidiu. |

O 2c fica como o spec escreve: só se as fatias do 2b passarem de ~1.000 linhas.

**Do Prumo, pequenas** (o Giovani pode mudar):

| Decisão | Por quê |
|---|---|
| As teclas do preço são as do app (centavos pela direita, com "00"), e não a vírgula do mockup | É a entrada de valor do app inteiro. |
| As teclas são uma peça nova sobre a `GradeDeTeclas`, sem mexer no `TecladoEncaixado` | Ele está amarrado à folha do orçamento. |
| O que cada tecla faz com o preço fica no núcleo (`PrecoNasTeclas.tocar`), e a `GradeDeTeclas` ganha uma regra opcional de quem a usa | O apagar que limpa não muda o valor (0 continua 0), e a grade só avisava quando o valor mudava. Sem a regra, o teclado de valor fica igual (a guarda Node confere o trecho dele). |
| As teclas entram na área segura da tela da aba, e não na barra do `PrincipalView` | A barra dele não entra na área segura da rolagem: na letra máxima, a linha do preço ficava atrás das teclas. |
| O painel das teclas sai sem a sombra de cima do mockup | O app não tem token de sombra de painel, e a guarda barra cor solta. |
| Os meses começam em 0 | É o campo do site; o 6 do mockup é ilustração. |
| No botão do workflow, o nível dos portões é escolhido (`tudo` por padrão) | Deixa provar os níveis `telas` e `nucleo` sem esperar o primeiro PR que dependa deles. |
| O filtro ignora o arquivo que não dispara o `app-ios.yml` | Sem isso, o checklist ou o plano no mesmo PR levaria toda tela nova ao nível `tudo`. |
| Um PR de núcleo com análise cai no nível `telas` | Leitura do spec ("só mexe em `Custta/Analise/` e nos testes dela"; o nível `telas` já inclui o `nucleo`). |

Nenhuma decisão deste plano passou pelo conselho: nenhuma muda a cara do app, a ordem dos PRs ou a arquitetura além do que o spec fixa.

## Pendências

1. **0 e 00 como primeira tecla não fazem nada** quando há valor à vista (a digitação parte do zero). O Giovani decidiu só o apagar; o 0 e o 00 ficam como estão, sem regra nova, até ele decidir.
2. **O toque no OK das teclas se perdeu uma vez no iOS 26.5 do Mac** (`testContrasteDoValeAPenaNosDoisTemas`, a cápsula não voltou em 5 s; 1 queda em 1 rodada). Parece o toque perdido da VM lenta; se repetir, a auditoria toca de novo enquanto as teclas estiverem à vista, como o `escolherObraDepoisDasTeclas`.
3. **Obras e Ajustes usam 24 pt de folga embaixo**, a mesma que escondia a última linha do "Vale a pena?" (tarefa 13). O Verniz confirmou na `main` (`f6f0fef`): a última linha fica 26 pt atrás da cápsula, porque a rolagem só desconta a área do aparelho; a cápsula entra por `safeAreaBar` com `ignoresSafeArea(.bottom)` por fora (`PrincipalView`). Recomendação do Prumo: o conserto na raiz, num PR de fix próprio depois do 4a (ou em paralelo), que tira também o 98 da tarefa 13; não se conserta no 4a.
4. **As diferenças para o mockup**, medidas pelo Verniz: o tracejado do empate (5 e 4 pt, 7 traços; no mockup, ~5,5 e 5, com 6: lá é um `border-left: 2px dashed`, sem medida escrita); o título na letra máxima quebra depois de "vale"; o − e o + usam a `Placa`; a seta da obra na letra máxima; o sair no canto da aba. E as das teclas: "00" no lugar da vírgula, letra do sistema, sem a sombra, o valor à vista com o cursor.
5. **O que este plano não prova:** o laudo inteiro comparado palavra por palavra com o da `main` (a cápsula mudou em toda tela); o Pro Max (as rolagens das cenas novas foram medidas só no 18 Pro; o Forja mediu as da maior letra passando do ponto lá, de 25 a 83 pt, e as acerta num commit próprio no #126); o filtro de portões rodando na CI (os níveis `telas` e `nucleo` só rodam no botão ou no primeiro PR que não mexa em arquivo compartilhado).
6. **As sondas S1, S2 e S4** (o arrasto nos meses, os toques no anel e o contraste das marcas dos gráficos na CI) dependem de código do 2a e do 2b, que ainda não existe. A S3 (as teclas e a lista "Obra" na VM do iOS 26) foi disparada num ramo `proto/` e não chegou a pegar máquina; o `ValeAPenaUITests` roda no iOS 26 pelo próprio #126.

7. **Os menores da revisão das tarefas 18 a 20** estão fechados: a fala do campo limpo (tarefa 21), a cena com a venda abaixo do banco (tarefa 22) e as mutações do custo e do empate no laudo pela forma (Prova da tarefa 20).

## PR 4a: "Vale a pena?"

**Risco único:** a terceira aba, que muda a cápsula de todas as telas. **Portões:** tudo, com a comparação do laudo inteiro. **Escondido na `main`:** nada (a aba entra completa).

### Global Constraints

As do marco 1 valem aqui, e estas o 4a toca:
- **Swift 6 estrito**, sem nenhum aviso de compilador novo; nada que só exista no SDK do iOS 27.
- **Cores só por token** (`scripts/cores-app-ios.mjs`, conferido por `tests/app-ios.test.cjs`); `lineLimit` e `minimumScaleFactor` só nos componentes da lista fixa da guarda.
- **Nenhuma dependência nova.** O formato do blob, as `firestore.rules`, os arquivos do site e o `sw.js` (`CACHE`) não mudam. Fora do app, o 4a só mexe no `package.json` (o `test:unit` ganha o `portoes-app-ios.test.mjs`), no `app-ios.yml`, nos testes Node e no checklist.
- **Ganchos só no Debug:** o `CUSTTA_ABRIR=aba:<nome>` (tarefa 3), o `-custta.simMeses` e a rolagem fixa das cenas (tarefa 14) e o `-custta.simPreco` (tarefa 22) não podem chegar ao Release (ponto de controle, abaixo).
- **Commits:** autor só `Giovani Stuchi <stuchigiovani@gmail.com>`, sem `Co-Authored-By` e sem rodapé; título conventional em português com acento, corpo em prosa, um commit por tarefa.
- **Simuladores:** um por agente (`CUSTTA_SIMULADOR=<udid>`), testes de tela com `-collect-test-diagnostics never`, e nunca compilar no `DerivedData` de uma rodada em curso.

### Como rodar

Na raiz do worktree, cada agente no seu simulador:

```bash
export CUSTTA_SIMULADOR=<udid do seu simulador>          # nunca o de outro agente
DESTINO=$(node scripts/simulador-ios.mjs)
XB=(-project app-ios/Custta.xcodeproj -scheme Custta -destination "$DESTINO"
    -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile)
# núcleo
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -3
# Node (inclui o filtro de portões)
npm run test:unit 2>&1 | tail -8
# app: compilar uma vez por mudança e rodar só o que a tarefa diz
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | tail -5
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:<alvo> 2>&1 | tail -5
```

Os alvos da análise: `CusttaTests` (a pasta `Analise` vai junto), `CusttaUITests/ValeAPenaUITests`, `CusttaUITests/AnaliseUITests`, `CusttaUITests/LeituraDaAnaliseUITests` e `CusttaUITests/AuditoriaDaAnaliseUITests`. Quando a tarefa muda a cápsula ou a máquina do laudo (tarefas 3, 4 e 11), também `AuditoriaUITests`, `LeituraNoVidroUITests` e `AjustesUITests`. Cada tarefa de tela roda no iOS 27 e no iOS 26.5.

### Ponto de controle do fim do PR

1. **Os testes:** núcleo, `npm run test:unit` e os alvos acima, verdes no 18 Pro (iOS 27) e no iOS 26.5.
2. **O laudo inteiro no Pro Max**, comparado palavra por palavra com o da `main` (a cápsula muda em toda tela).
3. **O `nm -a` do Release:** os ganchos do Debug não chegam a ele.
   ```bash
   xcodebuild build -project app-ios/Custta.xcodeproj -scheme Custta -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | tail -1
   PROD=$(xcodebuild "${XB[@]}" -showBuildSettings 2>/dev/null | awk -F' = ' '/^ *BUILD_DIR = /{print $2; exit}')
   for s in doGancho rolagemFixaSoComOArgumento marcasApagadas RaizView; do echo "$s release=$(nm -a "$PROD/Release-iphonesimulator/Custta.app/Custta" | grep -c $s) debug=$(nm -a "$PROD/Debug-iphonesimulator/Custta.app/Custta.debug.dylib" | grep -c $s)"; done
   ```
   Expected (medido no clone, na tarefa 20): `doGancho release=0 debug=2`, `rolagemFixaSoComOArgumento release=0 debug=224`, `marcasApagadas release=0 debug=60` e o controle `RaizView release=90 debug=400`. O `-custta.simMeses` e o `-custta.simPreco` são chaves de texto dentro do `#if DEBUG` do `simuladorInicial`, sem símbolo próprio: conferem-se lendo o código.
4. **A CI no nível `tudo`:** o 4a mexe no `app-ios.yml`, então o filtro dá `tudo` e rodam todos os jobs. O tempo do job `app` vai no texto do PR.

### Tarefa 1: faixa do "Vale a pena?" no núcleo

**Commit das fatias:** `25e6591` · **Mensagem:** `feat: faixa do "Vale a pena?" no núcleo`

O "Vale a pena?" do app mostra onde a venda cai entre o custo e o ponto em que ela empata com o banco, numa faixa que o site não tem. A regra é só do app e mora no núcleo, com teste próprio: a escala começa 3% abaixo do menor entre o custo e a venda e termina 3% acima do maior entre o empate e a venda, como no mockup aprovado, para nenhuma marca encostar na borda. Junto vêm os rótulos da legenda, a pílula ("acima do banco" ou "abaixo do banco") e a frase que o VoiceOver lê na faixa.

**Prova:** `swift test` do núcleo: 5 testes novos; 6 mutações pegas.

**Arquivos:**

```
 .../Sources/CusttaNucleo/Simulador.swift           | 46 +++++++++++++++
 .../CusttaNucleoTests/FaixaDoSimuladorTests.swift  | 65 ++++++++++++++++++++++
 2 files changed, 111 insertions(+)
```

**Mudança:**

```diff
diff --git a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
index 836ab9b..0fffeed 100644
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
@@ -122,3 +122,49 @@ public func textosSimulador(_ conta: ContaDoSimulador, taxa: Double, area: Doubl
     return TextosDoSimulador(veredito: conta.vale ? "Vale a pena" : "Rende menos que o banco",
                              taxa: conta.tir.map { virgula($0, 2) + "% ao mês" } ?? "—", detalhes: detalhes, tabela: tabela)
 }
+
+/* A faixa "Onde a sua venda cai" (regra nova do app, sem vetor do site: o site não tem a faixa). Vem do mockup aprovado da
+   etapa 4 (parte2.js, `telaSimula`): a escala começa 3% abaixo do menor entre o custo e a venda e termina 3% acima do maior
+   entre o empate e a venda, para nenhuma marca encostar na borda. O empate é o custo corrigido até a venda: vendendo por
+   esse valor, a obra rendeu o mesmo que o banco. */
+
+/// Cada marca da faixa, na ordem da legenda.
+public enum MarcaDaFaixa: String, Sendable, CaseIterable {
+    case custo, empate, venda
+}
+
+public struct LinhaDaFaixa: Equatable, Sendable {
+    public let marca: MarcaDaFaixa
+    /// "custo (bruto)", "empata com o banco" ou "sua venda".
+    public let rotulo: String
+    /// O valor inteiro, como "R$ 842.317,45".
+    public let valor: String
+    /// Onde a marca cai na faixa, de 0 (a borda esquerda) a 1.
+    public let fracao: Double
+}
+
+public struct FaixaDoSimulador: Equatable, Sendable {
+    /// Custo, empate e venda, nesta ordem.
+    public let linhas: [LinhaDaFaixa]
+    /// A venda passa do empate: a zona hachurada, do empate até o fim da faixa, é "acima do banco".
+    public let acima: Bool
+    /// "acima do banco" ou "abaixo do banco".
+    public let pilula: String
+    /// O que o VoiceOver lê na faixa, num elemento só.
+    public let falado: String
+}
+
+/// A faixa de uma conta do simulador.
+public func faixaSimulador(_ conta: ContaDoSimulador) -> FaixaDoSimulador {
+    let inicio = min(conta.bruto, conta.venda) * 0.97
+    let fim = max(conta.corrigido, conta.venda) * 1.03
+    func fracao(_ valor: Double) -> Double { fim > inicio ? (valor - inicio) / (fim - inicio) : 0 }
+    func linha(_ marca: MarcaDaFaixa, _ rotulo: String, _ valor: Double) -> LinhaDaFaixa {
+        LinhaDaFaixa(marca: marca, rotulo: rotulo, valor: moeda(valor), fracao: fracao(valor))
+    }
+    return FaixaDoSimulador(
+        linhas: [linha(.custo, "custo (bruto)", conta.bruto), linha(.empate, "empata com o banco", conta.corrigido),
+                 linha(.venda, "sua venda", conta.venda)],
+        acima: conta.vale, pilula: conta.vale ? "acima do banco" : "abaixo do banco",
+        falado: "Custo \(moeda(conta.bruto)), empata com o banco em \(moeda(conta.corrigido)), sua venda \(moeda(conta.venda))")
+}
diff --git a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FaixaDoSimuladorTests.swift b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FaixaDoSimuladorTests.swift
new file mode 100644
index 0000000..62e1080
--- /dev/null
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FaixaDoSimuladorTests.swift
@@ -0,0 +1,65 @@
+import Testing
+@testable import CusttaNucleo
+
+/* A faixa "Onde a sua venda cai" do "Vale a pena?" é regra só do app (o site não tem a faixa): os números vêm da conta do
+   mockup aprovado da etapa 4 (parte2.js, `telaSimula`) e das bordas dela. O empate ilustrativo é 901.820,11. */
+struct FaixaDoSimuladorTests {
+    private func conta(venda: Double, bruto: Double = 842_317.45, corrigido: Double = 901_820.11) -> ContaDoSimulador {
+        ContaDoSimulador(venda: venda, meses: 6, alvo: "2027-04-12", bruto: bruto, corrigido: corrigido, novaDemais: false,
+                         tir: 3.52, acima: 2.5, vale: venda > corrigido, multiplicador: 3.5)
+    }
+
+    private func perto(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 1e-9 }
+
+    @Test func vendaAcimaDoBancoCaiNaZonaDepoisDoEmpate() {
+        let f = faixaSimulador(conta(venda: 1_450_000))
+        #expect(f.linhas.map(\.marca) == [.custo, .empate, .venda])
+        #expect(f.linhas.map(\.rotulo) == ["custo (bruto)", "empata com o banco", "sua venda"])
+        #expect(f.linhas.map(\.valor) == ["R$\u{00A0}842.317,45", "R$\u{00A0}901.820,11", "R$\u{00A0}1.450.000,00"])
+        // A escala vai de 3% abaixo do custo a 3% acima da venda: nenhuma marca encosta na borda.
+        #expect(perto(f.linhas[0].fracao, 0.037355970201))
+        #expect(perto(f.linhas[1].fracao, 0.125318831623))
+        #expect(perto(f.linhas[2].fracao, 0.935693892141))
+        #expect(f.acima)
+        #expect(f.pilula == "acima do banco")
+        #expect(f.falado == "Custo R$\u{00A0}842.317,45, empata com o banco em R$\u{00A0}901.820,11, sua venda R$\u{00A0}1.450.000,00")
+    }
+
+    @Test func vendaAbaixoDoBancoFicaAntesDoEmpate() {
+        // Acima do custo e abaixo do empate: dá lucro e rende menos que o banco. A escala termina no empate.
+        let f = faixaSimulador(conta(venda: 880_000))
+        #expect(perto(f.linhas[0].fracao, 0.225970218971))
+        #expect(perto(f.linhas[1].fracao, 0.758066881163))
+        #expect(perto(f.linhas[2].fracao, 0.562942701846))
+        #expect(!f.acima)
+        #expect(f.pilula == "abaixo do banco")
+    }
+
+    @Test func vendaAbaixoDoCustoPuxaOComecoDaEscala() {
+        // Prejuízo: a escala começa 3% abaixo da venda, e a venda fica à esquerda do custo.
+        let f = faixaSimulador(conta(venda: 700_000))
+        #expect(perto(f.linhas[2].fracao, 0.084042117438))
+        #expect(perto(f.linhas[0].fracao, 0.653597348220))
+        #expect(perto(f.linhas[1].fracao, 0.891727326296))
+        #expect(!f.acima)
+    }
+
+    @Test func vendaIgualAoEmpateNaoEstaAcima() {
+        // O veredito do site é venda > corrigido: no empate exato, "abaixo do banco", com as duas marcas no mesmo ponto.
+        let f = faixaSimulador(conta(venda: 901_820.11))
+        #expect(!f.acima)
+        #expect(f.pilula == "abaixo do banco")
+        #expect(f.linhas[1].fracao == f.linhas[2].fracao)
+    }
+
+    @Test func asMarcasFicamDentroDaFaixaENaOrdemDoCusto() {
+        for venda in [1.0, 500.0, 842_317.45, 901_820.11, 2_000_000, 99_999_999.99] {
+            for (bruto, corrigido) in [(0.01, 0.01), (842_317.45, 901_820.11), (99_999_999.99, 150_000_000.0)] {
+                let f = faixaSimulador(conta(venda: venda, bruto: bruto, corrigido: corrigido))
+                for l in f.linhas { #expect(l.fracao > 0 && l.fracao < 1, "\(l.marca) em \(l.fracao), venda \(venda), custo \(bruto)") }
+                #expect(f.linhas[0].fracao <= f.linhas[1].fracao, "o custo nunca passa do empate")
+                #expect(f.acima == (f.linhas[2].fracao > f.linhas[1].fracao))
+            }
+        }
+    }
+}
```

### Tarefa 2: campos do "Vale a pena?" e o que a tela mostra, no núcleo

**Commit das fatias:** `e9438cd` · **Mensagem:** `feat: campos do "Vale a pena?" e o que a tela mostra, no núcleo`

A aba "Vale a pena?" guarda três campos enquanto o app está aberto: a obra, o preço e os meses. O comportamento é o do site e não cabia nos vetores, porque lá ele mora no campo do HTML: enquanto a pessoa não digitou, o preço acompanha a venda estimada da obra escolhida; depois de digitar, vale o digitado, mesmo trocando de obra; o campo apagado fica vazio; os meses começam em 0 e andam de 0 a 120. O núcleo devolve tudo o que a tela mostra de uma vez: as obras da lista, a escolhida (que cai na primeira quando deixa de ser elegível), o preço do campo, os limites do − e do +, a conta, os textos e a faixa.

**Prova:** `swift test` do núcleo: 8 testes novos (núcleo com 294 em 46 suítes); 8 mutações pegas.

**Arquivos:**

```
 .../Sources/CusttaNucleo/Simulador.swift           |  50 +++++++++
 .../CusttaNucleoTests/SimulacaoNaTelaTests.swift   | 115 +++++++++++++++++++++
 2 files changed, 165 insertions(+)
```

**Mudança:**

```diff
diff --git a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
index 0fffeed..938b353 100644
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
@@ -168,3 +168,53 @@ public func faixaSimulador(_ conta: ContaDoSimulador) -> FaixaDoSimulador {
         acima: conta.vale, pilula: conta.vale ? "acima do banco" : "abaixo do banco",
         falado: "Custo \(moeda(conta.bruto)), empata com o banco em \(moeda(conta.corrigido)), sua venda \(moeda(conta.venda))")
 }
+
+/* Os campos do "Vale a pena?" e o que a tela mostra com eles. Moram na aba enquanto o app está aberto (spec da etapa 4,
+   "Dados e estado"), e o comportamento é o do site (app.js, `simulaCompute`): enquanto a pessoa não digitou, o preço
+   acompanha a venda estimada da obra escolhida; depois de digitar, vale o digitado, mesmo trocando de obra; os meses
+   começam em 0, como o campo do site, e andam de 0 a 120. */
+public struct CamposDoSimulador: Equatable, Sendable {
+    /// A obra escolhida na lista; nil até a pessoa escolher, e aí vale a primeira elegível.
+    public var obraId: String?
+    /// O preço digitado, em reais; nil enquanto a pessoa não digitou. Zero é o campo apagado.
+    public var precoDigitado: Double?
+    /// Daqui a quantos meses vende.
+    public private(set) var meses = 0
+
+    public init() {}
+
+    /// O − e o + dos meses, presos entre 0 e `mesesSimulador`.
+    public mutating func andarMeses(_ passo: Int) {
+        meses = min(mesesSimulador, max(0, meses + passo))
+    }
+}
+
+/// O que a tela do "Vale a pena?" mostra.
+public struct SimulacaoNaTela: Equatable, Sendable {
+    /// As obras da lista "Obra", na ordem do documento; vazia, a tela diz "— crie uma obra com gastos —".
+    public let elegiveis: [Obra]
+    /// A obra da conta: a escolhida enquanto elegível; senão, a primeira.
+    public let obra: Obra?
+    /// O preço do campo: o digitado ou, sem digitar, a venda estimada da obra; nil é o campo vazio.
+    public let preco: Double?
+    public let meses: Int
+    /// O − e o + nos limites.
+    public let podeMenos: Bool
+    public let podeMais: Bool
+    /// nil sem obra ou sem preço: a tela diz "Digite o preço de venda pra ver a conta."
+    public let conta: ContaDoSimulador?
+    public let textos: TextosDoSimulador?
+    public let faixa: FaixaDoSimulador?
+}
+
+/// A tela do "Vale a pena?" para os campos de agora.
+public func simulacaoNaTela(_ campos: CamposDoSimulador, obras: [Obra], hoje: String, taxa: Double) -> SimulacaoNaTela {
+    let lista = obrasSimulador(obras, escolhida: campos.obraId)
+    let obra = lista.elegiveis.first { $0.id == lista.escolhida }
+    // O campo apagado (zero) fica vazio: não volta para a estimada, como o campo já tocado do site.
+    let preco = (campos.precoDigitado ?? obra.flatMap(precoInicialSimulador)).flatMap { $0 > 0 ? $0 : nil }
+    let conta = obra.flatMap { o in preco.flatMap { contaSimulador(o, venda: $0, meses: campos.meses, hoje: hoje, taxa: taxa) } }
+    return SimulacaoNaTela(elegiveis: lista.elegiveis, obra: obra, preco: preco, meses: campos.meses, podeMenos: campos.meses > 0,
+                           podeMais: campos.meses < mesesSimulador, conta: conta,
+                           textos: conta.map { textosSimulador($0, taxa: taxa, area: obra?.areaM2) }, faixa: conta.map(faixaSimulador))
+}
diff --git a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimulacaoNaTelaTests.swift b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimulacaoNaTelaTests.swift
new file mode 100644
index 0000000..f22456a
--- /dev/null
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimulacaoNaTelaTests.swift
@@ -0,0 +1,115 @@
+import Testing
+@testable import CusttaNucleo
+
+/* Os campos do "Vale a pena?" e o que a tela mostra: regra do site (app.js, simulaCompute) fora dos vetores, porque lá ela
+   mora no campo do HTML (o `touched` do preço e o valor inicial dos meses). */
+struct SimulacaoNaTelaTests {
+    private let hoje = "2026-10-12"
+
+    private func obra(_ id: String, estimada: Double? = nil, area: Double? = nil, fase: String = "construcao",
+                      gastos: [(String, Double)] = [("2026-01-15", 100_000), ("2026-03-02", 50_000)]) -> Obra {
+        var arvore: [String: ValorJSON] = [
+            "id": .texto(id), "nome": .texto("Obra \(id)"), "fase": .texto(fase), "dataInicio": .texto("2026-01-10"),
+            "gastos": .lista(gastos.enumerated().map { i, g in .objeto(["id": .texto("\(id)-g\(i)"), "valor": .numero(g.1), "data": .texto(g.0)]) }),
+        ]
+        if let estimada { arvore["valorEstimadoVenda"] = .numero(estimada) }
+        if let area { arvore["areaM2"] = .numero(area) }
+        return Obra(arvore: arvore)
+    }
+
+    private func tela(_ campos: CamposDoSimulador, _ obras: [Obra]) -> SimulacaoNaTela {
+        simulacaoNaTela(campos, obras: obras, hoje: hoje, taxa: 1)
+    }
+
+    @Test func semObraElegivelNaoHaContaNemPreco() {
+        let vendida = obra("v", estimada: 300_000, fase: "vendida"), vazia = obra("z", estimada: 300_000, gastos: [])
+        for obras in [[], [vendida, vazia]] {
+            let t = tela(CamposDoSimulador(), obras)
+            #expect(t.elegiveis.isEmpty)
+            #expect(t.obra == nil)
+            #expect(t.preco == nil)
+            #expect(t.conta == nil && t.textos == nil && t.faixa == nil)
+        }
+    }
+
+    @Test func semDigitarOPrecoAcompanhaAVendaEstimadaDaObraEscolhida() {
+        let a = obra("a", estimada: 300_000, area: 120), b = obra("b", estimada: 180_000)
+        var campos = CamposDoSimulador()
+        var t = tela(campos, [a, b])
+        #expect(t.elegiveis.map(\.id) == ["a", "b"])
+        #expect(t.obra?.id == "a", "sem escolha, vale a primeira elegível")
+        #expect(t.preco == 300_000)
+        #expect(t.conta?.venda == 300_000)
+        // Trocar de obra sem ter digitado troca o preço (no site de antes do PR 0 a segunda herdava o da primeira).
+        campos.obraId = "b"
+        t = tela(campos, [a, b])
+        #expect(t.obra?.id == "b")
+        #expect(t.preco == 180_000)
+        #expect(t.conta?.venda == 180_000)
+    }
+
+    @Test func semEstimadaOCampoFicaVazioEATelaPedeOPreco() {
+        for semPreco in [obra("a"), obra("a", estimada: 0)] {
+            let t = tela(CamposDoSimulador(), [semPreco])
+            #expect(t.obra?.id == "a")
+            #expect(t.preco == nil)
+            #expect(t.conta == nil && t.textos == nil && t.faixa == nil)
+        }
+    }
+
+    @Test func depoisDeDigitarValeODigitadoMesmoTrocandoDeObra() {
+        let a = obra("a", estimada: 300_000), b = obra("b", estimada: 180_000)
+        var campos = CamposDoSimulador()
+        campos.precoDigitado = 250_000
+        #expect(tela(campos, [a, b]).preco == 250_000)
+        campos.obraId = "b"
+        let t = tela(campos, [a, b])
+        #expect(t.preco == 250_000)
+        #expect(t.conta?.venda == 250_000)
+    }
+
+    @Test func campoApagadoNaoVoltaParaAEstimada() {
+        var campos = CamposDoSimulador()
+        campos.precoDigitado = 0
+        let t = tela(campos, [obra("a", estimada: 300_000)])
+        #expect(t.preco == nil)
+        #expect(t.conta == nil)
+    }
+
+    @Test func aEscolhidaQueDeixaDeSerElegivelCaiNaPrimeira() {
+        var campos = CamposDoSimulador()
+        campos.obraId = "b"
+        let a = obra("a", estimada: 300_000)
+        #expect(tela(campos, [a, obra("b", estimada: 180_000)]).obra?.id == "b")
+        #expect(tela(campos, [a, obra("b", estimada: 180_000, fase: "vendida")]).obra?.id == "a")
+        #expect(tela(campos, [a]).obra?.id == "a", "a obra apagada em outro aparelho")
+    }
+
+    @Test func osMesesComecamEmZeroEAndamDeZeroACentoEVinte() {
+        var campos = CamposDoSimulador()
+        #expect(campos.meses == 0)
+        campos.andarMeses(-1)
+        #expect(campos.meses == 0)
+        var t = tela(campos, [obra("a", estimada: 300_000)])
+        #expect(!t.podeMenos && t.podeMais)
+        #expect(t.conta?.meses == 0)
+        campos.andarMeses(1)
+        t = tela(campos, [obra("a", estimada: 300_000)])
+        #expect(t.meses == 1 && t.podeMenos && t.podeMais)
+        #expect(t.conta?.meses == 1)
+        campos.andarMeses(500)
+        t = tela(campos, [obra("a", estimada: 300_000)])
+        #expect(t.meses == 120 && t.podeMenos && !t.podeMais)
+        #expect(t.conta?.alvo == "2036-10-12")
+    }
+
+    @Test func osTextosEAFaixaSaoOsDaContaComAAreaDaObra() throws {
+        let a = obra("a", estimada: 300_000, area: 120)
+        let t = tela(CamposDoSimulador(), [a])
+        let conta = try #require(t.conta)
+        #expect(conta == contaSimulador(a, venda: 300_000, meses: 0, hoje: hoje, taxa: 1))
+        #expect(t.textos == textosSimulador(conta, taxa: 1, area: 120))
+        #expect(t.textos?.tabela.last?.rotulo == "Preço por m² (120 m²)")
+        #expect(t.faixa == faixaSimulador(conta))
+    }
+}
```

### Tarefa 3: abas da cápsula numa lista só e gancho da aba inicial

**Commit das fatias:** `7dca612` · **Mensagem:** `test: abas da cápsula numa lista só e gancho da aba inicial`

A terceira aba chega no próximo commit, e três lugares supunham duas. O título e o ícone da aba saíam de um ternário, que daria "Ajustes" e a engrenagem a uma aba nova sem o compilador avisar: passam a um switch sem default. O laudo de leitura e a auditoria repetiam à mão os identificadores das abas: agora perguntam a cápsula ao app, que é todo botão com o identificador começando por "aba-". E a cena do laudo só chegava a Ajustes pelo toque: o app ganha, só em Debug, o gancho CUSTTA_ABRIR=aba:<nome>, e a cena abre por ele.

**Prova:** 2 testes de unidade e 7 de tela (4 da cápsula, 2 auditorias de Ajustes, `testLeituraEmAjustes` pelo gancho), iOS 27; 3 mutações pegas.

**Arquivos:**

```
 app-ios/Custta/Identidade/CapsulaDeAbas.swift     | 15 ++++++++++++--
 app-ios/Custta/Telas/PrincipalView.swift          | 20 +++++++++++++++++-
 app-ios/CusttaTests/CapsulaDeAbasTests.swift      | 25 +++++++++++++++++++++++
 app-ios/CusttaUITests/Abrir.swift                 |  7 +++++++
 app-ios/CusttaUITests/AjustesUITests.swift        | 11 ++++++++++
 app-ios/CusttaUITests/AuditoriaUITests.swift      |  2 +-
 app-ios/CusttaUITests/LeituraNoVidroUITests.swift | 14 ++++---------
 7 files changed, 80 insertions(+), 14 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Identidade/CapsulaDeAbas.swift b/app-ios/Custta/Identidade/CapsulaDeAbas.swift
index 65dcf8f..7ff77aa 100644
--- a/app-ios/Custta/Identidade/CapsulaDeAbas.swift
+++ b/app-ios/Custta/Identidade/CapsulaDeAbas.swift
@@ -20,8 +20,19 @@ enum Aba: String, CaseIterable, Identifiable, Sendable {
     case ajustes
 
     var id: String { rawValue }
-    var titulo: String { self == .obras ? "Obras" : "Ajustes" }
-    var icone: String { self == .obras ? "Icones/predio" : "Icones/engrenagem" }
+    // Em `switch`, sem `default`: uma aba nova não compila sem o título e o ícone dela.
+    var titulo: String {
+        switch self {
+        case .obras: return "Obras"
+        case .ajustes: return "Ajustes"
+        }
+    }
+    var icone: String {
+        switch self {
+        case .obras: return "Icones/predio"
+        case .ajustes: return "Icones/engrenagem"
+        }
+    }
 }
 
 struct CapsulaDeAbas: View {
diff --git a/app-ios/Custta/Telas/PrincipalView.swift b/app-ios/Custta/Telas/PrincipalView.swift
index d80e7ba..ddc3660 100644
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -8,7 +8,7 @@ import CusttaNucleo
    continuaria na árvore do VoiceOver pela barra de navegação. Por isso o caminho dentro de Obras mora aqui:
    quem vai a Ajustes e volta encontra a obra que tinha aberto. */
 struct PrincipalView: View {
-    @State private var aba = Aba.obras
+    @State private var aba = PrincipalView.abaInicial
     @State private var caminhoDeObras = PrincipalView.caminhoInicial
     @State private var folhas = Folhas()
     /// O + da lista avisou em vez de abrir "Nova obra": o teto de obras ou os dados ainda não vistos.
@@ -180,6 +180,24 @@ extension PrincipalView {
     }
     #endif
 
+    /// A aba em que o app abre: Obras. Em Debug, `CUSTTA_ABRIR=aba:<nome>` abre noutra (`aba:ajustes`), para os testes de
+    /// tela, o laudo de leitura e a conferência visual chegarem a uma aba sem tocar na cápsula.
+    static var abaInicial: Aba {
+        #if DEBUG
+        return aba(doGancho: ProcessInfo.processInfo.environment["CUSTTA_ABRIR"])
+        #else
+        return .obras
+        #endif
+    }
+
+    #if DEBUG
+    /// A aba do gancho de abertura: `aba:<nome>`; com qualquer outro gancho, ou sem ele, Obras.
+    static func aba(doGancho abrir: String?) -> Aba {
+        guard let abrir, abrir.hasPrefix("aba:") else { return .obras }
+        return Aba(rawValue: String(abrir.dropFirst(4))) ?? .obras
+    }
+    #endif
+
     /// O caminho com que Obras abre: vazio; em Debug, `CUSTTA_ABRIR=obra:<id>` abre a obra direto,
     /// `CUSTTA_ABRIR=orcamento:<id>`, a tela Orçamento dela (testes de tela, laudo de leitura e conferência visual), e
     /// `afazeres:<id>`, `graficos:<id>` e `relatorio:<id>`, a obra, com a tela empurrada depois.
diff --git a/app-ios/CusttaTests/CapsulaDeAbasTests.swift b/app-ios/CusttaTests/CapsulaDeAbasTests.swift
new file mode 100644
index 0000000..69b7611
--- /dev/null
+++ b/app-ios/CusttaTests/CapsulaDeAbasTests.swift
@@ -0,0 +1,25 @@
+import Testing
+import UIKit
+@testable import Custta
+
+/* As abas da cápsula: cada uma com o título e o ícone dela, e a aba em que o app abre (Obras; em Debug, a do gancho
+   `CUSTTA_ABRIR=aba:<nome>`, que leva o laudo e a auditoria a uma aba sem tocar na cápsula). */
+@MainActor
+struct CapsulaDeAbasTests {
+    @Test func cadaAbaTemOTituloEOIconeDela() {
+        #expect(Aba.allCases.map(\.titulo) == ["Obras", "Ajustes"])
+        #expect(Aba.allCases.map(\.icone) == ["Icones/predio", "Icones/engrenagem"])
+        for aba in Aba.allCases {
+            #expect(UIImage(named: aba.icone) != nil, "o ícone de \(aba.rawValue) está no catálogo")
+        }
+    }
+
+    @Test func oGanchoEscolheAAbaESoEle() {
+        #expect(PrincipalView.aba(doGancho: "aba:ajustes") == .ajustes)
+        #expect(PrincipalView.aba(doGancho: "aba:obras") == .obras)
+        // Sem gancho, com o gancho de outra tela ou com uma aba que não existe, o app abre em Obras.
+        for outro in [nil, "", "aba:", "aba:nada", "obra:v1", "ajustes", "graficos:v1"] {
+            #expect(PrincipalView.aba(doGancho: outro) == .obras, "\(outro ?? "nil")")
+        }
+    }
+}
diff --git a/app-ios/CusttaUITests/Abrir.swift b/app-ios/CusttaUITests/Abrir.swift
index 16b0063..4dc40a0 100644
--- a/app-ios/CusttaUITests/Abrir.swift
+++ b/app-ios/CusttaUITests/Abrir.swift
@@ -84,6 +84,13 @@ extension XCUIApplication {
         }
     }
 
+    /// Os botões da cápsula de abas, quantos forem: cada aba é um botão com o identificador `aba-<nome>`. Quem precisa do
+    /// lugar da cápsula (o laudo de leitura, a auditoria) pergunta aqui, e uma aba nova não fica de fora de uma lista
+    /// escrita à mão.
+    var abasDaCapsula: [XCUIElement] {
+        buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'aba-'")).allElementsBoundByIndex
+    }
+
     /// Troca de aba pela cápsula de abas (aba-obras, aba-ajustes).
     func abrirAba(_ aba: String) {
         let botao = buttons["aba-\(aba)"]
diff --git a/app-ios/CusttaUITests/AjustesUITests.swift b/app-ios/CusttaUITests/AjustesUITests.swift
index 22593c6..e5eebd4 100644
--- a/app-ios/CusttaUITests/AjustesUITests.swift
+++ b/app-ios/CusttaUITests/AjustesUITests.swift
@@ -67,6 +67,17 @@ final class AjustesUITests: XCTestCase {
         XCTAssertTrue(app.elemento("obra-o1").waitForExistence(timeout: 5))
     }
 
+    /// `CUSTTA_ABRIR=aba:ajustes` abre o app já em Ajustes, sem toque na cápsula: é por onde o laudo e a auditoria chegam a
+    /// uma aba. A cápsula inteira sai de `abasDaCapsula`, na ordem das abas.
+    @MainActor func testOGanchoAbreOAppNaAba() {
+        let app = abrirApp(conta: "senha", abrir: "aba:ajustes")
+        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 10), "abriu em Ajustes")
+        XCTAssertTrue(app.buttons["aba-ajustes"].isSelected)
+        XCTAssertFalse(app.buttons["aba-obras"].isSelected)
+        XCTAssertFalse(app.buttons["botaoMais"].exists, "em Ajustes não há o +")
+        XCTAssertEqual(app.abasDaCapsula.map(\.identifier), ["aba-obras", "aba-ajustes"])
+    }
+
     /// A cápsula fica 22 pt acima da borda, como a barra de abas do sistema (mockup aprovado), nas duas abas.
     /// Ela tem 4 pt de margem em volta das abas.
     @MainActor func testCapsulaFica22PontosAcimaDaBorda() {
diff --git a/app-ios/CusttaUITests/AuditoriaUITests.swift b/app-ios/CusttaUITests/AuditoriaUITests.swift
index 295211d..018f464 100644
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -32,7 +32,7 @@ final class AuditoriaUITests: XCTestCase {
                                     corteSemElemento: Bool = false) throws {
         // Com a folha aberta, a cápsula fica atrás dela: nada da folha é cortado pela regra da cápsula.
         let folha = app.elemento("tituloDaFolha").exists
-        let abas = folha ? [] : ["aba-obras", "aba-ajustes", "botaoMais"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
+        let abas = folha ? [] : (app.abasDaCapsula + [app.buttons["botaoMais"]]).filter(\.exists).map(\.frame)
         let fundoDaTela = abas.isEmpty ? app.frame.maxY : min(abas.map(\.minY).min()!, app.frame.maxY - borda)
         // Com a folha aberta, a barra é a da folha, e não a da tela por trás dela (a primeira da árvore); e a folha não tem a
         // borda de rolagem das telas: o conteúdo dela começa onde a barra acaba.
diff --git a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
index 1daecb6..11e7d30 100644
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -38,9 +38,7 @@ final class LeituraNoVidroUITests: XCTestCase {
         /// "tudo" mede o conteúdo (da cápsula de abas para baixo fica de fora); "navegacao" mede só os rótulos
         /// da cápsula, com o conteúdo que passa por baixo dela intacto nos dois prints.
         let escopo: String
-        /// Aba aberta pela cápsula antes do print (Ajustes não tem gancho de abertura).
-        var aba: String? = nil
-        /// Dados dos falsos e tela aberta pelo gancho (`obra:v1`, a obra do mockup na vitrine).
+        /// Dados dos falsos e tela aberta pelo gancho (`obra:v1`, a obra do mockup na vitrine; `aba:ajustes`, a aba).
         var dados = "exemplo"
         var abrir: String? = nil
         /// Folha aberta pelo gancho quando os dados chegam (`novaObra`, `venda:v2`; etapa 2, parte 3).
@@ -76,15 +74,11 @@ final class LeituraNoVidroUITests: XCTestCase {
         // Até 30 s: na VM do iOS 26, a thread principal para de 3 a 8 s na abertura, e a cena rolada só fica pronta depois da
         // rolagem fixa (do "abriu" à frase do fim do A pagar, de 9 a 34 s no run 40590390423; no Mac, ~2 s).
         XCTAssertTrue(app.elemento(cena.espera).waitForExistence(timeout: 30), "\(cena.nome): a tela não abriu")
-        if let aba = cena.aba {
-            app.abrirAba(aba)
-            XCTAssertTrue(app.elemento("sair").waitForExistence(timeout: 10), "\(cena.nome): Ajustes não abriu")
-        }
         cena.toques?(app)
         Thread.sleep(forTimeInterval: 2)                           // o vidro e a rolagem assentam
         conferirAssunto(cena, app)
         let foto = XCUIScreen.main.screenshot()
-        let abas = ["aba-obras", "aba-ajustes"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
+        let abas = app.abasDaCapsula.map(\.frame)
         let largura = app.frame.width
         let informativo = exemploDaDescricao(app, cena)
         // Todos os voltar: com a folha aberta, o da tela de baixo e o da folha. O da tela de baixo cai no cabeçalho da folha
@@ -267,8 +261,8 @@ final class LeituraNoVidroUITests: XCTestCase {
                   ("na maior letra", escuro + maiorLetra, false),
                   ("na maior letra, rolada", escuro + maiorLetra + ["-custta.rolagem", "2000"], true)]
         cobrar(cenas.map { nome, argumentos, rolada in
-            Cena(nome: "ajustes, \(nome)", conta: "senha", argumentos: argumentos, espera: "aba-ajustes", escopo: "tudo",
-                 aba: "ajustes", rolada: rolada, assunto: rolada ? ["nomeConta"] : [])
+            Cena(nome: "ajustes, \(nome)", conta: "senha", argumentos: argumentos, espera: "sair", escopo: "tudo",
+                 abrir: "aba:ajustes", rolada: rolada, assunto: rolada ? ["nomeConta"] : [])
         })
     }
 }
```

### Tarefa 4: aba "Vale a pena?" na cápsula, com o título e os campos

**Commit das fatias:** `6b52f76` · **Mensagem:** `feat: aba "Vale a pena?" na cápsula, com o título e os campos`

A cápsula passa a ter três abas, com o "Vale a pena?" no meio e o ícone da balança do site, e o + some nela, como em Ajustes. A tela nasce com o título em mono e o bloco dos campos: a obra num Menu do sistema com as elegíveis, o preço que acompanha a venda estimada da obra e os meses com o − e o +, de 0 a 120, e a nota do site. Os campos moram no PrincipalView, porque só a aba escolhida fica montada e eles têm de durar enquanto o app está aberto. O que a conta diz (veredito, faixa e tabela) e as teclas do preço chegam nos próximos commits.

**Prova:** Vermelho visto antes do código; 2 de unidade e 9 de tela, iOS 27 e 26.5; 4 mutações pegas; prints conferidos com o mockup (padrão e letra máxima).

**Arquivos:**

```
 app-ios/Custta/Analise/ValeAPenaView.swift         | 195 +++++++++++++++++++++
 .../Icones/balanca.imageset/Contents.json          |  16 ++
 .../Icones/balanca.imageset/balanca.svg            |   1 +
 app-ios/Custta/Identidade/Blocos.swift             |   5 +-
 app-ios/Custta/Identidade/CapsulaDeAbas.swift      |   8 +-
 app-ios/Custta/Telas/ObraView.swift                |   2 +-
 app-ios/Custta/Telas/PrincipalView.swift           |   8 +-
 app-ios/CusttaTests/CapsulaDeAbasTests.swift       |   6 +-
 app-ios/CusttaUITests/AjustesUITests.swift         |   4 +-
 app-ios/CusttaUITests/ValeAPenaUITests.swift       |  94 ++++++++++
 scripts/icones-app-ios.mjs                         |   4 +-
 11 files changed, 331 insertions(+), 12 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Analise/ValeAPenaView.swift b/app-ios/Custta/Analise/ValeAPenaView.swift
new file mode 100644
index 0000000..78501ec
--- /dev/null
+++ b/app-ios/Custta/Analise/ValeAPenaView.swift
@@ -0,0 +1,195 @@
+import SwiftUI
+import CusttaNucleo
+
+/* A aba "Vale a pena?" (etapa 4, PR 4a; mockup aprovado, parte 2, `telaSimula`): o simulador do site na identidade nova. O
+   título solto em mono e o bloco dos campos (a obra, o preço e os meses, com a nota do site); o que a conta diz chega nos
+   próximos commits. Os campos moram no PrincipalView, e não aqui: só a aba escolhida fica montada, e eles têm de durar
+   enquanto o app está aberto (spec, "Dados e estado"). O que a tela mostra sai inteiro do núcleo (`simulacaoNaTela`), com
+   as obras e a taxa de agora: uma mudança vinda de outro aparelho redesenha a aba na hora. */
+struct ValeAPenaView: View {
+    @Binding var campos: CamposDoSimulador
+    @Environment(ModeloApp.self) private var modelo
+    @State private var confirmarSaida = false
+    @State private var barra = BarraDaObra()
+
+    var body: some View {
+        let estado = modelo.sincronizador.estado
+        let tela = simulacaoNaTela(campos, obras: estado.obras, hoje: dataLocalISO(.now, fuso: .current),
+                                   taxa: estado.config.taxaMensal)
+        NavigationStack {
+            ScrollView {
+                VStack(alignment: .leading, spacing: Grade.entreBlocos) {
+                    TituloMono(texto: "Será que vale a pena?", identificador: "tituloValeAPena")
+                        .padding(.bottom, 2)
+                    CamposDoValeAPena(campos: $campos, tela: tela)
+                }
+                .padding(.horizontal, Grade.externa)
+                .padding(.bottom, 24)
+            }
+            .scrollIndicators(.hidden)
+            .tituloPequenoAoRolar(barra)
+            .background { LeitorDaLetra(barra: barra) }
+            .pausaOFundoAoRolar()
+            .bordaDeRolagem(abas: true)
+            .containerBackground(.clear, for: .navigation)
+            .navigationTitle("Vale a pena?")
+            .navigationBarTitleDisplayMode(.inline)
+            .toolbar {
+                ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: "Vale a pena?", mono: true) }
+                BarraDoApp(confirmarSaida: $confirmarSaida)
+            }
+            .confirmaSaida($confirmarSaida)
+        }
+    }
+}
+
+/// O bloco dos campos: a obra, o preço e os meses, uma linha cada (o rótulo à esquerda e o valor à direita; na letra de
+/// acessibilidade, um embaixo do outro, como o mockup), e a nota do site. Para o VoiceOver, cada linha é o controle dela,
+/// com o rótulo da linha e o valor: o texto do rótulo sai da leitura, para não ser lido duas vezes.
+struct CamposDoValeAPena: View {
+    @Binding var campos: CamposDoSimulador
+    let tela: SimulacaoNaTela
+    @Environment(\.paleta) private var paleta
+    @Environment(\.vidro) private var vidro
+    @Environment(\.dynamicTypeSize) private var tamanho
+
+    var body: some View {
+        BlocoDeVidro(recuoVertical: 4) {
+            LinhaDoCampo(rotulo: "Obra") { obra }
+            LinhaFina()
+            LinhaDoCampo(rotulo: "Se eu vender por") { preco }
+            LinhaFina()
+            LinhaDoCampo(rotulo: "Daqui a (meses)") { passo }
+            LinhaFina()
+            Text("A conta considera que não haverá mais gastos até a venda. Mude o preço e os meses pra comparar cenários: vender mais barato agora × esperar mais.")
+                .font(.subheadline)
+                .foregroundStyle(paleta.cor(vidro.secundario))
+                .fixedSize(horizontal: false, vertical: true)
+                .padding(.top, 10)
+                .padding(.bottom, 12)
+                .accessibilityIdentifier("simNota")
+        }
+    }
+
+    /// A obra: um Menu do sistema com as elegíveis, na ordem do documento, e a marca na escolhida; sem nenhuma, a frase do
+    /// site no lugar.
+    @ViewBuilder private var obra: some View {
+        if let escolhida = tela.obra {
+            Menu {
+                Picker("Obra", selection: Binding(get: { escolhida.id }, set: { campos.obraId = $0 })) {
+                    ForEach(tela.elegiveis, id: \.id) { Text($0.nome).tag($0.id) }
+                }
+            } label: {
+                HStack(spacing: 6) {
+                    Text(escolhida.nome)
+                        .font(.body)
+                        .multilineTextAlignment(tamanho.isAccessibilitySize ? .leading : .trailing)
+                        .fixedSize(horizontal: false, vertical: true)
+                    Image(systemName: "chevron.down").font(.footnote.weight(.semibold)).accessibilityHidden(true)
+                }
+                .foregroundStyle(paleta.cor(vidro.secundario))
+                .frame(minHeight: 44)
+                .contentShape(.rect)
+            }
+            .accessibilityLabel("Obra")
+            .accessibilityValue(escolhida.nome)
+            .accessibilityIdentifier("simObra")
+        } else {
+            Text("— crie uma obra com gastos —")
+                .font(.body)
+                .foregroundStyle(paleta.cor(vidro.secundario))
+                .fixedSize(horizontal: false, vertical: true)
+                .accessibilityIdentifier("simSemObra")
+        }
+    }
+
+    /// O preço: o digitado ou, sem digitar, a venda estimada da obra; vazio, "R$ 0,00" apagado, como o campo do site.
+    private var preco: some View {
+        Group {
+            if let valor = tela.preco {
+                ValorEmDinheiro(moeda(valor), mono: .linha)
+            } else {
+                ValorEmDinheiro(moeda(0), mono: .linha, cor: vidro.secundario)
+            }
+        }
+        .accessibilityElement(children: .ignore)
+        .accessibilityLabel("Se eu vender por")
+        .accessibilityValue(tela.preco.map { moeda($0) } ?? "sem preço")
+        .accessibilityIdentifier("simPreco")
+    }
+
+    /// Os meses: − e + redondos de 44 pt (72 na letra de acessibilidade), que param em 0 e em 120, e o número em mono no meio.
+    private var passo: some View {
+        let grande = tamanho.isAccessibilitySize
+        let numero = crescendoComALetra(de: 17, ate: 34, corpo: corpoDoTexto(tamanho))
+        return HStack(spacing: 6) {
+            BotaoDoPasso(simbolo: "minus", rotulo: "Um mês a menos", identificador: "simMenos", lado: grande ? 72 : 44) {
+                campos.andarMeses(-1)
+            }
+            .disabled(!tela.podeMenos)
+            Text("\(tela.meses)")
+                .font(.system(size: numero, weight: .semibold, design: .monospaced))
+                .foregroundStyle(paleta.cor(.texto))
+                .frame(minWidth: 74)
+                .accessibilityLabel("Daqui a")
+                .accessibilityValue(tela.meses == 1 ? "1 mês" : "\(tela.meses) meses")
+                .accessibilityIdentifier("simMeses")
+            BotaoDoPasso(simbolo: "plus", rotulo: "Um mês a mais", identificador: "simMais", lado: grande ? 72 : 44) {
+                campos.andarMeses(1)
+            }
+            .disabled(!tela.podeMais)
+        }
+    }
+}
+
+/// Uma linha do bloco dos campos: 56 pt no mínimo, o rótulo no corpo do texto e o valor à direita; na letra de
+/// acessibilidade, o valor embaixo do rótulo.
+private struct LinhaDoCampo<Valor: View>: View {
+    let rotulo: String
+    @ViewBuilder let valor: Valor
+    @Environment(\.paleta) private var paleta
+    @Environment(\.dynamicTypeSize) private var tamanho
+
+    var body: some View {
+        let grande = tamanho.isAccessibilitySize
+        let layout = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
+        layout {
+            Text(rotulo)
+                .font(.body)
+                .foregroundStyle(paleta.cor(.texto))
+                .fixedSize(horizontal: false, vertical: true)
+                .frame(maxWidth: grande ? nil : .infinity, alignment: .leading)
+                .accessibilityHidden(true)
+            valor
+        }
+        .padding(.vertical, 6)
+        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
+    }
+}
+
+/// O − e o + dos meses: um círculo chapado na Placa (não é vidro: está dentro do bloco de vidro), com o símbolo no texto;
+/// desabilitado, a 40%.
+private struct BotaoDoPasso: View {
+    let simbolo: String
+    let rotulo: String
+    let identificador: String
+    let lado: CGFloat
+    let acao: () -> Void
+    @Environment(\.paleta) private var paleta
+    @Environment(\.isEnabled) private var habilitado
+
+    var body: some View {
+        Button(action: acao) {
+            Image(systemName: simbolo)
+                .font(.system(size: lado * 0.45, weight: .medium))
+                .foregroundStyle(paleta.cor(.texto))
+                .frame(width: lado, height: lado)
+                .background(paleta.cor(.placa), in: .circle)
+                .contentShape(.circle)
+                .opacity(habilitado ? 1 : 0.4)
+        }
+        .buttonStyle(.plain)
+        .accessibilityLabel(rotulo)
+        .accessibilityIdentifier(identificador)
+    }
+}
diff --git a/app-ios/Custta/Assets.xcassets/Icones/balanca.imageset/Contents.json b/app-ios/Custta/Assets.xcassets/Icones/balanca.imageset/Contents.json
new file mode 100644
index 0000000..1dea07a
--- /dev/null
+++ b/app-ios/Custta/Assets.xcassets/Icones/balanca.imageset/Contents.json
@@ -0,0 +1,16 @@
+{
+  "images": [
+    {
+      "filename": "balanca.svg",
+      "idiom": "universal"
+    }
+  ],
+  "info": {
+    "author": "xcode",
+    "version": 1
+  },
+  "properties": {
+    "preserves-vector-representation": true,
+    "template-rendering-intent": "template"
+  }
+}
diff --git a/app-ios/Custta/Assets.xcassets/Icones/balanca.imageset/balanca.svg b/app-ios/Custta/Assets.xcassets/Icones/balanca.imageset/balanca.svg
new file mode 100644
index 0000000..b77a001
--- /dev/null
+++ b/app-ios/Custta/Assets.xcassets/Icones/balanca.imageset/balanca.svg
@@ -0,0 +1 @@
+<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v18M7 21h10"/><path d="m5 7 7-2 7 2"/><path d="M5 7l-2.5 6a3 3 0 0 0 5 0L5 7Z"/><path d="M19 7l-2.5 6a3 3 0 0 0 5 0L19 7Z"/></svg>
diff --git a/app-ios/Custta/Identidade/Blocos.swift b/app-ios/Custta/Identidade/Blocos.swift
index d5d71d8..c354e84 100644
--- a/app-ios/Custta/Identidade/Blocos.swift
+++ b/app-ios/Custta/Identidade/Blocos.swift
@@ -29,12 +29,15 @@ extension EnvironmentValues {
 /// Um assunto por bloco, no vidro do conteúdo, com os cantos e o recuo da grade. Ocupa a largura toda; a borda de 16 pt é
 /// da coluna da tela.
 struct BlocoDeVidro<Conteudo: View>: View {
+    /// O recuo de cima e de baixo, quando não é o da grade: o bloco de linhas (os campos do "Vale a pena?") usa 4 pt,
+    /// porque cada linha já traz a altura dela.
+    var recuoVertical: CGFloat? = nil
     @ViewBuilder let conteudo: Conteudo
     @Environment(\.dynamicTypeSize) private var tamanho
 
     var body: some View {
         VStack(alignment: .leading, spacing: 0) { conteudo }
-            .padding(.vertical, Grade.recuoVertical(tamanho))
+            .padding(.vertical, recuoVertical ?? Grade.recuoVertical(tamanho))
             .padding(.horizontal, Grade.recuo)
             .frame(maxWidth: .infinity, alignment: .leading)
             .superficie(.conteudo, em: .rect(cornerRadius: Grade.raioDoBloco(tamanho)))
diff --git a/app-ios/Custta/Identidade/CapsulaDeAbas.swift b/app-ios/Custta/Identidade/CapsulaDeAbas.swift
index 7ff77aa..c8ebdd2 100644
--- a/app-ios/Custta/Identidade/CapsulaDeAbas.swift
+++ b/app-ios/Custta/Identidade/CapsulaDeAbas.swift
@@ -5,9 +5,10 @@ import SwiftUI
    segmentado da entrada (decisão do Giovani em 10/10): o rótulo da aba escolhida fica no contraste dos
    dois tokens com qualquer coisa passando por baixo; na lente de vidro, a lista rolada derrubava o "Obras"
    para 3,8:1 no escuro. O que a barra do sistema dava de graça vem à mão: VoiceOver lê o nome,
-   "1 de 2" e "selecionada", alvo de 44 pt e o Visualizador de Conteúdo Grande no lugar de crescer com a
+   "1 de 3" e "selecionada", alvo de 44 pt e o Visualizador de Conteúdo Grande no lugar de crescer com a
    letra. O + volta na etapa 2, ao lado da cápsula e na Tinta (mockup): lança gasto na obra; some onde não há o que
-   criar (Ajustes), como o do site, e a cápsula ocupa a largura toda. */
+   criar ("Vale a pena?" e Ajustes), como o do site, e a cápsula ocupa a largura toda. A terceira aba, "Vale a pena?",
+   chega na etapa 4 (PR 4a), no meio, como no site. */
 
 /// O + ao lado da cápsula: o rótulo para o VoiceOver ("Lançar gasto") e o que ele faz.
 struct AcaoDoMais {
@@ -17,6 +18,7 @@ struct AcaoDoMais {
 
 enum Aba: String, CaseIterable, Identifiable, Sendable {
     case obras
+    case valeAPena
     case ajustes
 
     var id: String { rawValue }
@@ -24,12 +26,14 @@ enum Aba: String, CaseIterable, Identifiable, Sendable {
     var titulo: String {
         switch self {
         case .obras: return "Obras"
+        case .valeAPena: return "Vale a pena?"
         case .ajustes: return "Ajustes"
         }
     }
     var icone: String {
         switch self {
         case .obras: return "Icones/predio"
+        case .valeAPena: return "Icones/balanca"
         case .ajustes: return "Icones/engrenagem"
         }
     }
diff --git a/app-ios/Custta/Telas/ObraView.swift b/app-ios/Custta/Telas/ObraView.swift
index c669eef..d811a9c 100644
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -442,7 +442,7 @@ final class BarraDaObra {
 }
 
 /// Lê a letra da tela fora da barra e a guarda na BarraDaObra: só o título pequeno se refaz quando ela muda.
-private struct LeitorDaLetra: View {
+struct LeitorDaLetra: View {
     let barra: BarraDaObra
     @Environment(\.dynamicTypeSize) private var letra
 
diff --git a/app-ios/Custta/Telas/PrincipalView.swift b/app-ios/Custta/Telas/PrincipalView.swift
index ddc3660..845422d 100644
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -1,7 +1,7 @@
 import SwiftUI
 import CusttaNucleo
 
-/* O app por dentro: as abas (Obras e Ajustes; "Vale a pena?" chega na etapa 4) com a cápsula de abas
+/* O app por dentro: as abas (Obras, "Vale a pena?" e Ajustes) com a cápsula de abas
    própria, e a barra de cada tela com a sincronização e o sair do topo, em vidro, como no site. Sair pede
    confirmação pelo alerta do sistema (decisão do Giovani). Só a aba escolhida fica montada: o TabView do
    sistema pinta um fundo opaco por trás das abas no iOS 26 (esconderia a aurora), e uma aba só escondida
@@ -10,6 +10,9 @@ import CusttaNucleo
 struct PrincipalView: View {
     @State private var aba = PrincipalView.abaInicial
     @State private var caminhoDeObras = PrincipalView.caminhoInicial
+    /// Os campos do "Vale a pena?": moram aqui, e não na tela da aba, que sai da árvore quando a pessoa troca de aba. Assim
+    /// duram enquanto o app está aberto (spec da etapa 4, "Dados e estado").
+    @State private var simulador = CamposDoSimulador()
     @State private var folhas = Folhas()
     /// O + da lista avisou em vez de abrir "Nova obra": o teto de obras ou os dados ainda não vistos.
     @State private var avisoDoMais: AvisoDoMais?
@@ -21,6 +24,7 @@ struct PrincipalView: View {
         Group {
             switch aba {
             case .obras: ObrasView(caminho: $caminhoDeObras)
+            case .valeAPena: ValeAPenaView(campos: $simulador)
             case .ajustes: AjustesView()
             }
         }
@@ -76,7 +80,7 @@ struct PrincipalView: View {
 extension PrincipalView {
     /// O + da cápsula, como o do site: na lista, "Nova obra"; dentro de uma obra (e no orçamento e nos afazeres dela), lança
     /// gasto nela. Obra vendida não recebe gasto novo: o + abre a folha do gasto com a linha "Obra", para escolher entre as
-    /// abertas; sem nenhuma aberta, cria obra. Em Ajustes, some.
+    /// abertas; sem nenhuma aberta, cria obra. No "Vale a pena?" e em Ajustes, some.
     private var acaoDoMais: AcaoDoMais? {
         guard aba == .obras else { return nil }
         let obras = modelo.sincronizador.estado.obras
diff --git a/app-ios/CusttaTests/CapsulaDeAbasTests.swift b/app-ios/CusttaTests/CapsulaDeAbasTests.swift
index 69b7611..72e775b 100644
--- a/app-ios/CusttaTests/CapsulaDeAbasTests.swift
+++ b/app-ios/CusttaTests/CapsulaDeAbasTests.swift
@@ -7,8 +7,9 @@ import UIKit
 @MainActor
 struct CapsulaDeAbasTests {
     @Test func cadaAbaTemOTituloEOIconeDela() {
-        #expect(Aba.allCases.map(\.titulo) == ["Obras", "Ajustes"])
-        #expect(Aba.allCases.map(\.icone) == ["Icones/predio", "Icones/engrenagem"])
+        #expect(Aba.allCases.map(\.rawValue) == ["obras", "valeAPena", "ajustes"], "a ordem da cápsula")
+        #expect(Aba.allCases.map(\.titulo) == ["Obras", "Vale a pena?", "Ajustes"])
+        #expect(Aba.allCases.map(\.icone) == ["Icones/predio", "Icones/balanca", "Icones/engrenagem"])
         for aba in Aba.allCases {
             #expect(UIImage(named: aba.icone) != nil, "o ícone de \(aba.rawValue) está no catálogo")
         }
@@ -17,6 +18,7 @@ struct CapsulaDeAbasTests {
     @Test func oGanchoEscolheAAbaESoEle() {
         #expect(PrincipalView.aba(doGancho: "aba:ajustes") == .ajustes)
         #expect(PrincipalView.aba(doGancho: "aba:obras") == .obras)
+        #expect(PrincipalView.aba(doGancho: "aba:valeAPena").rawValue == "valeAPena")
         // Sem gancho, com o gancho de outra tela ou com uma aba que não existe, o app abre em Obras.
         for outro in [nil, "", "aba:", "aba:nada", "obra:v1", "ajustes", "graficos:v1"] {
             #expect(PrincipalView.aba(doGancho: outro) == .obras, "\(outro ?? "nil")")
diff --git a/app-ios/CusttaUITests/AjustesUITests.swift b/app-ios/CusttaUITests/AjustesUITests.swift
index e5eebd4..ea47204 100644
--- a/app-ios/CusttaUITests/AjustesUITests.swift
+++ b/app-ios/CusttaUITests/AjustesUITests.swift
@@ -58,7 +58,7 @@ final class AjustesUITests: XCTestCase {
         XCTAssertTrue(obras.waitForExistence(timeout: 10))
         XCTAssertTrue(obras.isSelected)
         XCTAssertEqual(obras.label, "Obras")
-        XCTAssertEqual(ajustes.value as? String, "2 de 2")
+        XCTAssertEqual(ajustes.value as? String, "3 de 3")
         ajustes.tap()
         XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
         XCTAssertTrue(ajustes.isSelected)
@@ -75,7 +75,7 @@ final class AjustesUITests: XCTestCase {
         XCTAssertTrue(app.buttons["aba-ajustes"].isSelected)
         XCTAssertFalse(app.buttons["aba-obras"].isSelected)
         XCTAssertFalse(app.buttons["botaoMais"].exists, "em Ajustes não há o +")
-        XCTAssertEqual(app.abasDaCapsula.map(\.identifier), ["aba-obras", "aba-ajustes"])
+        XCTAssertEqual(app.abasDaCapsula.map(\.identifier), ["aba-obras", "aba-valeAPena", "aba-ajustes"])
     }
 
     /// A cápsula fica 22 pt acima da borda, como a barra de abas do sistema (mockup aprovado), nas duas abas.
diff --git a/app-ios/CusttaUITests/ValeAPenaUITests.swift b/app-ios/CusttaUITests/ValeAPenaUITests.swift
new file mode 100644
index 0000000..a36bb5d
--- /dev/null
+++ b/app-ios/CusttaUITests/ValeAPenaUITests.swift
@@ -0,0 +1,94 @@
+import XCTest
+
+/* A aba "Vale a pena?" (etapa 4, PR 4a), com os falsos da análise (`dados: "analise"`): as obras elegíveis são as não
+   vendidas com gastos, na ordem do documento (Casa Alphaville, com venda estimada de R$ 1.450.000,00; Sobrado Granja Viana,
+   sem estimada; …). */
+final class ValeAPenaUITests: XCTestCase {
+    override func setUp() { continueAfterFailure = false }
+
+    @MainActor private func abrirAAba(_ extra: [String: String] = [:]) -> XCUIApplication {
+        let app = abrirApp(conta: "senha", dados: "analise", extra: extra)
+        app.abrirAba("valeAPena")
+        XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10), "a aba abriu")
+        return app
+    }
+
+    /// A aba fica no meio da cápsula, e o + some nela, como em Ajustes e como no site. Os campos nascem com a primeira obra
+    /// elegível, o preço na venda estimada dela e os meses em 0, com o − desabilitado.
+    @MainActor func testAAbaAbreComOsCamposESemOMais() {
+        let app = abrirAAba()
+        let aba = app.buttons["aba-valeAPena"]
+        XCTAssertTrue(aba.isSelected)
+        XCTAssertEqual(aba.label, "Vale a pena?")
+        XCTAssertEqual(aba.value as? String, "2 de 3")
+        XCTAssertTrue(app.buttons["botaoMais"].waitForNonExistence(timeout: 3), "o + some nessa aba")
+        XCTAssertEqual(app.elemento("tituloValeAPena").label, "Será que vale a pena?")
+        XCTAssertEqual(app.buttons["simObra"].value as? String, "Casa Alphaville")
+        XCTAssertEqual(app.elemento("simPreco").value as? String, "R$\u{00A0}1.450.000,00")
+        XCTAssertEqual(app.elemento("simMeses").value as? String, "0 meses")
+        XCTAssertFalse(app.buttons["simMenos"].isEnabled, "em 0, o − não anda")
+        XCTAssertTrue(app.buttons["simMais"].isEnabled)
+    }
+
+    /// O + e o − andam os meses de um em um, e o texto falado acompanha ("1 mês", "2 meses").
+    @MainActor func testOsMesesAndamDeUmEmUm() {
+        let app = abrirAAba()
+        let meses = app.elemento("simMeses"), mais = app.buttons["simMais"], menos = app.buttons["simMenos"]
+        mais.tap()
+        XCTAssertEqual(meses.value as? String, "1 mês")
+        XCTAssertTrue(menos.isEnabled)
+        mais.tap()
+        XCTAssertEqual(meses.value as? String, "2 meses")
+        menos.tap()
+        menos.tap()
+        XCTAssertEqual(meses.value as? String, "0 meses")
+        XCTAssertFalse(menos.isEnabled)
+    }
+
+    /// Sem ter digitado, trocar de obra troca o preço: o Sobrado não tem venda estimada, e o campo fica vazio; de volta à
+    /// Casa, a estimada dela.
+    @MainActor func testTrocarDeObraTrocaOPrecoEnquantoNaoDigitou() {
+        let app = abrirAAba()
+        let obra = app.buttons["simObra"], preco = app.elemento("simPreco")
+        obra.tap()
+        let sobrado = app.buttons["Sobrado Granja Viana"]
+        XCTAssertTrue(sobrado.waitForExistence(timeout: 5), "a lista das obras elegíveis")
+        XCTAssertFalse(app.buttons["Casa Tamboré 4"].exists, "a vendida fica fora da lista")
+        XCTAssertFalse(app.buttons["Casa Cotia"].exists, "a obra sem gastos também")
+        sobrado.tap()
+        XCTAssertTrue(obra.waitForExistence(timeout: 5))
+        XCTAssertEqual(obra.value as? String, "Sobrado Granja Viana")
+        XCTAssertEqual(preco.value as? String, "sem preço")
+        obra.tap()
+        let casa = app.buttons["Casa Alphaville"].firstMatch
+        XCTAssertTrue(casa.waitForExistence(timeout: 5))
+        casa.tap()
+        XCTAssertEqual(obra.value as? String, "Casa Alphaville")
+        XCTAssertEqual(preco.value as? String, "R$\u{00A0}1.450.000,00")
+    }
+
+    /// Os campos moram no app, não na tela da aba: ir a Ajustes e voltar não zera a obra nem os meses.
+    @MainActor func testOsCamposFicamAoTrocarDeAba() {
+        let app = abrirAAba()
+        app.buttons["simMais"].tap()
+        app.buttons["simMais"].tap()
+        app.buttons["simObra"].tap()
+        let sobrado = app.buttons["Sobrado Granja Viana"]
+        XCTAssertTrue(sobrado.waitForExistence(timeout: 5))
+        sobrado.tap()
+        app.abrirAba("ajustes")
+        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
+        app.abrirAba("valeAPena")
+        XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 5))
+        XCTAssertEqual(app.buttons["simObra"].value as? String, "Sobrado Granja Viana")
+        XCTAssertEqual(app.elemento("simMeses").value as? String, "2 meses")
+    }
+
+    /// Sem nenhuma obra elegível, a linha da obra diz o que fazer, como no site, e não há lista para abrir.
+    @MainActor func testSemObraElegivelALinhaDizOQueFazer() {
+        let app = abrirApp(conta: "senha", dados: "vazio", abrir: "aba:valeAPena")
+        XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
+        XCTAssertEqual(app.elemento("simSemObra").label, "— crie uma obra com gastos —")
+        XCTAssertFalse(app.buttons["simObra"].exists)
+    }
+}
diff --git a/scripts/icones-app-ios.mjs b/scripts/icones-app-ios.mjs
index 0a77db2..b1103a1 100644
--- a/scripts/icones-app-ios.mjs
+++ b/scripts/icones-app-ios.mjs
@@ -17,10 +17,10 @@ const PASTA = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../app
 /** Ícones que as telas usam: abas, fases da obra, sair, olho da senha e a seta da dica; na etapa 2, os dos 21 tópicos
     (TOPICOS do calc.js) e o "etiqueta" dos tópicos próprios, o calendário do "A vencer", o cartão do pagamento, o lápis
     de editar, o acordo da venda, o voltar das fases e as notas da obra sem gastos; na etapa 3, o triângulo do aviso dos tópicos
-    na linha do orçamento, o alvo do "Definir orçamento" e a lupa da busca. */
+    na linha do orçamento, o alvo do "Definir orçamento" e a lupa da busca; na etapa 4, a balança da aba "Vale a pena?". */
 export const USADOS = ['predio', 'engrenagem', 'sair', 'guindaste', 'casa', 'check', 'olho', 'olhoFechado', 'setaBaixo',
   'mapa', 'documento', 'tijolos', 'pa', 'vergalhao', 'raio', 'gota', 'porta', 'ladrilho', 'rolo', 'piscina', 'arvore', 'capacete',
-  'caixa', 'mais', 'etiqueta', 'calendario', 'cartao', 'lapis', 'acordo', 'voltar', 'notas', 'alerta', 'alvo', 'lupa'];
+  'caixa', 'mais', 'etiqueta', 'calendario', 'cartao', 'lapis', 'acordo', 'voltar', 'notas', 'alerta', 'alvo', 'lupa', 'balanca'];
 
 const info = { author: 'xcode', version: 1 };
 
```

### Tarefa 5: veredito do "Vale a pena?" no bloco sólido

**Commit das fatias:** `60c12a0` · **Mensagem:** `feat: veredito do "Vale a pena?" no bloco sólido`

Com a obra e o preço, a aba mostra o veredito no bloco sólido da identidade nova: verde com "Vale a pena" ou âmbar com "Rende menos que o banco", a taxa ao mês com o número em mono grande e as frases do site. Os textos são os do site (textosSimulador); o núcleo só os arruma para o bloco: a taxa partida em número e unidade e os detalhes em linhas, em vez de juntos por " · ". Para o VoiceOver, o bloco é um elemento só, com a frase inteira. Sem preço, a frase do site ("Digite o preço de venda pra ver a conta.") toma o lugar do veredito; sem obra elegível, ficam só os campos.

**Prova:** Núcleo com 298 testes, vermelho por asserção com esqueleto, 5 mutações; 6 de tela, iOS 27 e 26.5, 3 mutações (vermelho na tela por mutação depois do verde); print conferido.

**Arquivos:**

```
 app-ios/Custta/Analise/ValeAPenaView.swift         | 53 +++++++++++++++++++++-
 .../Sources/CusttaNucleo/Simulador.swift           | 36 +++++++++++++++
 .../CusttaNucleoTests/SimulacaoNaTelaTests.swift   |  3 +-
 .../CusttaNucleoTests/VereditoNaTelaTests.swift    | 53 ++++++++++++++++++++++
 app-ios/CusttaUITests/ValeAPenaUITests.swift       | 23 ++++++++++
 5 files changed, 165 insertions(+), 3 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Analise/ValeAPenaView.swift b/app-ios/Custta/Analise/ValeAPenaView.swift
index 78501ec..4d4b9af 100644
--- a/app-ios/Custta/Analise/ValeAPenaView.swift
+++ b/app-ios/Custta/Analise/ValeAPenaView.swift
@@ -2,8 +2,8 @@ import SwiftUI
 import CusttaNucleo
 
 /* A aba "Vale a pena?" (etapa 4, PR 4a; mockup aprovado, parte 2, `telaSimula`): o simulador do site na identidade nova. O
-   título solto em mono e o bloco dos campos (a obra, o preço e os meses, com a nota do site); o que a conta diz chega nos
-   próximos commits. Os campos moram no PrincipalView, e não aqui: só a aba escolhida fica montada, e eles têm de durar
+   título solto em mono, o bloco dos campos (a obra, o preço e os meses, com a nota do site) e o veredito no bloco sólido;
+   a faixa e a tabela chegam nos próximos commits. Os campos moram no PrincipalView, e não aqui: só a aba escolhida fica montada, e eles têm de durar
    enquanto o app está aberto (spec, "Dados e estado"). O que a tela mostra sai inteiro do núcleo (`simulacaoNaTela`), com
    as obras e a taxa de agora: uma mudança vinda de outro aparelho redesenha a aba na hora. */
 struct ValeAPenaView: View {
@@ -22,6 +22,12 @@ struct ValeAPenaView: View {
                     TituloMono(texto: "Será que vale a pena?", identificador: "tituloValeAPena")
                         .padding(.bottom, 2)
                     CamposDoValeAPena(campos: $campos, tela: tela)
+                    // Sem obra elegível, só os campos, como no site. Com obra e sem preço, a frase do site no lugar da conta.
+                    if let veredito = tela.veredito {
+                        VereditoDoValeAPena(veredito: veredito)
+                    } else if tela.obra != nil {
+                        SemPrecoDoValeAPena()
+                    }
                 }
                 .padding(.horizontal, Grade.externa)
                 .padding(.bottom, 24)
@@ -142,6 +148,49 @@ struct CamposDoValeAPena: View {
     }
 }
 
+/// O veredito, o bloco sólido da aba: verde com "Vale a pena" ou âmbar com "Rende menos que o banco", a taxa ao mês com o
+/// número em mono grande (40 pt; 56 na letra máxima) e a unidade na metade, e as linhas do site embaixo. A taxa quebra em
+/// vez de encolher. Para o VoiceOver, o bloco é um elemento só, com a frase inteira.
+struct VereditoDoValeAPena: View {
+    let veredito: VereditoNaTela
+    @Environment(\.dynamicTypeSize) private var tamanho
+    @ScaledMetric(relativeTo: .subheadline) private var icone: CGFloat = 18
+
+    var body: some View {
+        let numero = crescendoComALetra(de: 40, ate: 56, corpo: corpoDoTexto(tamanho))
+        BlocoSolido(cor: veredito.vale ? .verde : .ambar) {
+            HStack(spacing: 6) {
+                Image(decorative: veredito.vale ? "Icones/check" : "Icones/alerta").resizable().frame(width: icone, height: icone)
+                RotuloDoBloco(texto: veredito.titulo)
+            }
+            Text("\(Text(veredito.numero).font(.system(size: numero, weight: .semibold, design: .monospaced)).tracking(-0.035 * numero))\(Text(veredito.unidade ?? "").font(.system(size: numero / 2, weight: .bold, design: .monospaced)))")
+                .fixedSize(horizontal: false, vertical: true)
+                .padding(.top, 4)
+                .padding(.bottom, 2)
+            ForEach(veredito.linhas, id: \.self) { NotaDoBloco(texto: $0) }
+        }
+        .accessibilityElement(children: .ignore)
+        .accessibilityLabel(veredito.falado)
+        .accessibilityIdentifier("simVeredito")
+    }
+}
+
+/// Com obra e sem preço: a frase do site, num bloco de vidro.
+struct SemPrecoDoValeAPena: View {
+    @Environment(\.paleta) private var paleta
+    @Environment(\.vidro) private var vidro
+
+    var body: some View {
+        BlocoDeVidro {
+            Text("Digite o preço de venda pra ver a conta.")
+                .font(.subheadline)
+                .foregroundStyle(paleta.cor(vidro.secundario))
+                .fixedSize(horizontal: false, vertical: true)
+                .accessibilityIdentifier("simSemPreco")
+        }
+    }
+}
+
 /// Uma linha do bloco dos campos: 56 pt no mínimo, o rótulo no corpo do texto e o valor à direita; na letra de
 /// acessibilidade, o valor embaixo do rótulo.
 private struct LinhaDoCampo<Valor: View>: View {
diff --git a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
index 938b353..e56fc1e 100644
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
@@ -169,6 +169,40 @@ public func faixaSimulador(_ conta: ContaDoSimulador) -> FaixaDoSimulador {
         falado: "Custo \(moeda(conta.bruto)), empata com o banco em \(moeda(conta.corrigido)), sua venda \(moeda(conta.venda))")
 }
 
+/* O veredito no app (mockup da etapa 4, parte2.js, `telaSimula`): os textos são os do site (`textosSimulador`), arrumados
+   para o bloco sólido. A taxa vem partida em número e unidade, porque o número é o protagonista do bloco; e os detalhes,
+   que o site junta com " · ", vêm em linhas: quando vende, o banco com o "rende N× o banco" e, na obra com menos de 1 mês,
+   o aviso numa linha só dele. */
+public struct VereditoNaTela: Equatable, Sendable {
+    /// A venda passa do custo corrigido: o bloco é o verde; senão, o âmbar.
+    public let vale: Bool
+    /// "Vale a pena" ou "Rende menos que o banco".
+    public let titulo: String
+    /// "3,52", ou "—" na obra com menos de 1 mês.
+    public let numero: String
+    /// "% ao mês"; nil sem taxa.
+    public let unidade: String?
+    public let linhas: [String]
+    /// O bloco inteiro para o VoiceOver, num elemento só.
+    public let falado: String
+}
+
+public func vereditoNaTela(_ conta: ContaDoSimulador, taxa: Double) -> VereditoNaTela {
+    let site = textosSimulador(conta, taxa: taxa, area: nil)
+    // "3,52% ao mês" vira "3,52" e "% ao mês"; o "—" da obra com menos de 1 mês fica inteiro, sem unidade.
+    let corte = site.taxa.firstIndex(of: "%")
+    let numero = corte.map { String(site.taxa[..<$0]) } ?? site.taxa
+    let unidade = corte.map { String(site.taxa[$0...]) }
+    // Os detalhes do site, na ordem: quando vende, o banco, o "rende N× o banco" (só quando rende) e o aviso da obra nova.
+    var detalhes = site.detalhes
+    let aviso = conta.novaDemais ? detalhes.popLast() : nil
+    let doBanco = detalhes.dropFirst().joined(separator: " · ")
+    let linhas = Array(detalhes.prefix(1)) + (doBanco.isEmpty ? [] : [doBanco]) + (aviso.map { [$0] } ?? [])
+    return VereditoNaTela(vale: conta.vale, titulo: site.veredito, numero: numero, unidade: unidade, linhas: linhas,
+                          falado: ([site.veredito, unidade == nil ? "sem taxa ao mês" : site.taxa] + site.detalhes)
+                              .joined(separator: ", "))
+}
+
 /* Os campos do "Vale a pena?" e o que a tela mostra com eles. Moram na aba enquanto o app está aberto (spec da etapa 4,
    "Dados e estado"), e o comportamento é o do site (app.js, `simulaCompute`): enquanto a pessoa não digitou, o preço
    acompanha a venda estimada da obra escolhida; depois de digitar, vale o digitado, mesmo trocando de obra; os meses
@@ -203,6 +237,7 @@ public struct SimulacaoNaTela: Equatable, Sendable {
     public let podeMais: Bool
     /// nil sem obra ou sem preço: a tela diz "Digite o preço de venda pra ver a conta."
     public let conta: ContaDoSimulador?
+    public let veredito: VereditoNaTela?
     public let textos: TextosDoSimulador?
     public let faixa: FaixaDoSimulador?
 }
@@ -216,5 +251,6 @@ public func simulacaoNaTela(_ campos: CamposDoSimulador, obras: [Obra], hoje: St
     let conta = obra.flatMap { o in preco.flatMap { contaSimulador(o, venda: $0, meses: campos.meses, hoje: hoje, taxa: taxa) } }
     return SimulacaoNaTela(elegiveis: lista.elegiveis, obra: obra, preco: preco, meses: campos.meses, podeMenos: campos.meses > 0,
                            podeMais: campos.meses < mesesSimulador, conta: conta,
+                           veredito: conta.map { vereditoNaTela($0, taxa: taxa) },
                            textos: conta.map { textosSimulador($0, taxa: taxa, area: obra?.areaM2) }, faixa: conta.map(faixaSimulador))
 }
diff --git a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimulacaoNaTelaTests.swift b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimulacaoNaTelaTests.swift
index f22456a..ccfe541 100644
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimulacaoNaTelaTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimulacaoNaTelaTests.swift
@@ -28,7 +28,7 @@ struct SimulacaoNaTelaTests {
             #expect(t.elegiveis.isEmpty)
             #expect(t.obra == nil)
             #expect(t.preco == nil)
-            #expect(t.conta == nil && t.textos == nil && t.faixa == nil)
+            #expect(t.conta == nil && t.veredito == nil && t.textos == nil && t.faixa == nil)
         }
     }
 
@@ -111,5 +111,6 @@ struct SimulacaoNaTelaTests {
         #expect(t.textos == textosSimulador(conta, taxa: 1, area: 120))
         #expect(t.textos?.tabela.last?.rotulo == "Preço por m² (120 m²)")
         #expect(t.faixa == faixaSimulador(conta))
+        #expect(t.veredito == vereditoNaTela(conta, taxa: 1))
     }
 }
diff --git a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/VereditoNaTelaTests.swift b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/VereditoNaTelaTests.swift
new file mode 100644
index 0000000..40284b1
--- /dev/null
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/VereditoNaTelaTests.swift
@@ -0,0 +1,53 @@
+import Testing
+@testable import CusttaNucleo
+
+/* O bloco do veredito do "Vale a pena?" no app (mockup da etapa 4, parte2.js, `telaSimula`): os mesmos textos do site
+   (`textosSimulador`), arrumados em linhas em vez de juntos por " · ", com a taxa partida em número e unidade. */
+struct VereditoNaTelaTests {
+    private func conta(venda: Double = 1_450_000, meses: Int = 6, corrigido: Double = 901_820.11, novaDemais: Bool = false,
+                       tir: Double? = 3.52, multiplicador: Double = 3.52) -> ContaDoSimulador {
+        ContaDoSimulador(venda: venda, meses: meses, alvo: "2027-04-12", bruto: 842_317.45, corrigido: corrigido,
+                         novaDemais: novaDemais, tir: tir, acima: tir.map { $0 - 1 }, vale: venda > corrigido,
+                         multiplicador: multiplicador)
+    }
+
+    @Test func valeAPenaComATaxaEmNumeroEUnidade() {
+        let v = vereditoNaTela(conta(), taxa: 1)
+        #expect(v.vale)
+        #expect(v.titulo == "Vale a pena")
+        #expect(v.numero == "3,52")
+        #expect(v.unidade == "% ao mês")
+        #expect(v.linhas == ["vendendo daqui a 6 meses", "banco paga 1% · rende 3,5× o banco"])
+        #expect(v.falado == "Vale a pena, 3,52% ao mês, vendendo daqui a 6 meses, banco paga 1%, rende 3,5× o banco")
+    }
+
+    @Test func rendeMenosQueOBancoNaoDizQuantasVezes() {
+        // Abaixo do banco, o multiplicador fica abaixo de 1 e o site não o mostra.
+        let v = vereditoNaTela(conta(venda: 880_000, meses: 1, tir: 0.41, multiplicador: 0.41), taxa: 1)
+        #expect(!v.vale)
+        #expect(v.titulo == "Rende menos que o banco")
+        #expect(v.numero == "0,41")
+        #expect(v.linhas == ["vendendo daqui a 1 mês", "banco paga 1%"])
+        #expect(v.falado == "Rende menos que o banco, 0,41% ao mês, vendendo daqui a 1 mês, banco paga 1%")
+    }
+
+    @Test func obraComMenosDeUmMesFicaSemTaxaEComOAviso() {
+        let v = vereditoNaTela(conta(meses: 0, novaDemais: true, tir: nil, multiplicador: 0), taxa: 1.5)
+        #expect(v.vale, "o veredito sai pelo preço contra o custo corrigido, como no site")
+        #expect(v.numero == "—")
+        #expect(v.unidade == nil)
+        #expect(v.linhas == ["vendendo hoje", "banco paga 1,5%", "obra com menos de 1 mês — % ao mês ainda não diz muito"])
+        #expect(v.falado == "Vale a pena, sem taxa ao mês, vendendo hoje, banco paga 1,5%, obra com menos de 1 mês — % ao mês ainda não diz muito")
+    }
+
+    @Test func osTextosSaoOsDoSite() {
+        // As linhas são os `detalhes` do site, na mesma ordem: nenhuma frase a mais nem a menos.
+        for c in [conta(), conta(venda: 880_000, tir: 0.41, multiplicador: 0.41), conta(novaDemais: true, tir: nil, multiplicador: 0)] {
+            let site = textosSimulador(c, taxa: 1, area: nil)
+            let v = vereditoNaTela(c, taxa: 1)
+            #expect(v.titulo == site.veredito)
+            #expect(v.linhas.flatMap { $0.components(separatedBy: " · ") } == site.detalhes)
+            #expect(v.numero + (v.unidade ?? "") == site.taxa)
+        }
+    }
+}
diff --git a/app-ios/CusttaUITests/ValeAPenaUITests.swift b/app-ios/CusttaUITests/ValeAPenaUITests.swift
index a36bb5d..c2c179a 100644
--- a/app-ios/CusttaUITests/ValeAPenaUITests.swift
+++ b/app-ios/CusttaUITests/ValeAPenaUITests.swift
@@ -84,11 +84,34 @@ final class ValeAPenaUITests: XCTestCase {
         XCTAssertEqual(app.elemento("simMeses").value as? String, "2 meses")
     }
 
+    /// Com a obra e o preço, o veredito aparece no bloco sólido, num elemento só para o VoiceOver, e acompanha os meses.
+    /// Sem preço (o Sobrado não tem venda estimada), a frase do site toma o lugar dele.
+    @MainActor func testOVereditoAcompanhaOsCampos() {
+        let app = abrirAAba()
+        let veredito = app.elemento("simVeredito")
+        XCTAssertTrue(veredito.waitForExistence(timeout: 5), "a Casa Alphaville tem venda estimada: a conta já aparece")
+        XCTAssertTrue(veredito.label.hasPrefix("Vale a pena, "), veredito.label)
+        XCTAssertTrue(veredito.label.contains("% ao mês, vendendo hoje, banco paga 1%"), veredito.label)
+        XCTAssertFalse(app.elemento("simSemPreco").exists)
+        app.buttons["simMais"].tap()
+        XCTAssertTrue(veredito.label.contains(", vendendo daqui a 1 mês, "), veredito.label)
+        app.buttons["simObra"].tap()
+        let sobrado = app.buttons["Sobrado Granja Viana"]
+        XCTAssertTrue(sobrado.waitForExistence(timeout: 5))
+        sobrado.tap()
+        let semPreco = app.elemento("simSemPreco")
+        XCTAssertTrue(semPreco.waitForExistence(timeout: 5))
+        XCTAssertEqual(semPreco.label, "Digite o preço de venda pra ver a conta.")
+        XCTAssertFalse(veredito.exists, "sem preço não há veredito")
+    }
+
     /// Sem nenhuma obra elegível, a linha da obra diz o que fazer, como no site, e não há lista para abrir.
     @MainActor func testSemObraElegivelALinhaDizOQueFazer() {
         let app = abrirApp(conta: "senha", dados: "vazio", abrir: "aba:valeAPena")
         XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
         XCTAssertEqual(app.elemento("simSemObra").label, "— crie uma obra com gastos —")
         XCTAssertFalse(app.buttons["simObra"].exists)
+        XCTAssertFalse(app.elemento("simVeredito").exists, "sem obra, só os campos")
+        XCTAssertFalse(app.elemento("simSemPreco").exists)
     }
 }
```

### Tarefa 6: faixa "Onde a sua venda cai" no "Vale a pena?"

**Commit das fatias:** `8ba8314` · **Mensagem:** `feat: faixa "Onde a sua venda cai" no "Vale a pena?"`

Embaixo do veredito, a aba desenha onde a venda cai: o trilho, a zona hachurada do empate com o banco até o fim, o custo numa barra, o empate num tracejado e a venda numa barra com um ponto em cima. A pílula diz de que lado a venda caiu, e os três valores vêm numa lista embaixo, cada um com o marcador dele, como o mockup aprovado: sobre a faixa eles se atropelam quando a venda cai perto do empate. As posições vêm do núcleo, como fração da largura, e o desenho é só de formas, que somem no modo de marcas apagadas do laudo. Para o VoiceOver, a faixa é uma imagem com a frase dos três valores.

**Prova:** 2 de unidade e 7 de tela, iOS 27 e 26.5; 3 mutações pegas; print conferido.

**Arquivos:**

```
 app-ios/Custta/Analise/ValeAPenaView.swift      | 148 +++++++++++++++++++++++-
 app-ios/CusttaTests/FaixaDoValeAPenaTests.swift |  33 ++++++
 app-ios/CusttaUITests/ValeAPenaUITests.swift    |  26 +++++
 3 files changed, 205 insertions(+), 2 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Analise/ValeAPenaView.swift b/app-ios/Custta/Analise/ValeAPenaView.swift
index 4d4b9af..4586fab 100644
--- a/app-ios/Custta/Analise/ValeAPenaView.swift
+++ b/app-ios/Custta/Analise/ValeAPenaView.swift
@@ -2,8 +2,8 @@ import SwiftUI
 import CusttaNucleo
 
 /* A aba "Vale a pena?" (etapa 4, PR 4a; mockup aprovado, parte 2, `telaSimula`): o simulador do site na identidade nova. O
-   título solto em mono, o bloco dos campos (a obra, o preço e os meses, com a nota do site) e o veredito no bloco sólido;
-   a faixa e a tabela chegam nos próximos commits. Os campos moram no PrincipalView, e não aqui: só a aba escolhida fica montada, e eles têm de durar
+   título solto em mono, o bloco dos campos (a obra, o preço e os meses, com a nota do site), o veredito no bloco sólido e a
+   faixa "Onde a sua venda cai"; a tabela chega no próximo commit. Os campos moram no PrincipalView, e não aqui: só a aba escolhida fica montada, e eles têm de durar
    enquanto o app está aberto (spec, "Dados e estado"). O que a tela mostra sai inteiro do núcleo (`simulacaoNaTela`), com
    as obras e a taxa de agora: uma mudança vinda de outro aparelho redesenha a aba na hora. */
 struct ValeAPenaView: View {
@@ -25,6 +25,7 @@ struct ValeAPenaView: View {
                     // Sem obra elegível, só os campos, como no site. Com obra e sem preço, a frase do site no lugar da conta.
                     if let veredito = tela.veredito {
                         VereditoDoValeAPena(veredito: veredito)
+                        if let faixa = tela.faixa { FaixaDoValeAPena(faixa: faixa) }
                     } else if tela.obra != nil {
                         SemPrecoDoValeAPena()
                     }
@@ -175,6 +176,149 @@ struct VereditoDoValeAPena: View {
     }
 }
 
+/// A faixa "Onde a sua venda cai" (mockup da etapa 4, parte2.css:84-99; regra no núcleo, `faixaSimulador`): o trilho, a
+/// zona hachurada do empate até o fim ("acima do banco"), o custo numa barra, o empate num tracejado e a venda numa barra
+/// com um ponto em cima; a pílula diz de que lado a venda caiu, e os três valores vêm numa lista embaixo, cada um com o
+/// marcador dele (decisão 6 da parte 2: sobre a faixa eles se atropelam). Para o VoiceOver, a faixa é uma imagem com a
+/// frase dos três valores, e cada linha da lista, o rótulo com o valor.
+struct FaixaDoValeAPena: View {
+    let faixa: FaixaDoSimulador
+    @Environment(\.paleta) private var paleta
+    @Environment(\.dynamicTypeSize) private var tamanho
+
+    var body: some View {
+        let grande = tamanho.isAccessibilitySize
+        let cabecalho = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 10))
+        BlocoDeVidro {
+            cabecalho {
+                Text("Onde a sua venda cai")
+                    .font(.body.weight(.semibold))
+                    .foregroundStyle(paleta.cor(.texto))
+                    .fixedSize(horizontal: false, vertical: true)
+                    .frame(maxWidth: grande ? nil : .infinity, alignment: .leading)
+                    .accessibilityAddTraits(.isHeader)
+                EtiquetaDoIndicador(texto: faixa.pilula, cor: faixa.acima ? .positivo : .alerta)
+                    .accessibilityIdentifier("simPilula")
+            }
+            // 20 pt acima e 10 abaixo (mockup); as marcas passam 8 pt da faixa, e o ponto da venda, 15.
+            DesenhoDaFaixa(faixa: faixa)
+                .frame(height: DesenhoDaFaixa.altura)
+                .padding(.top, 20)
+                .padding(.bottom, 10)
+                .accessibilityElement(children: .ignore)
+                .accessibilityLabel(faixa.falado)
+                .accessibilityAddTraits(.isImage)
+                .accessibilityIdentifier("simFaixa")
+            VStack(alignment: .leading, spacing: 2) {
+                ForEach(faixa.linhas, id: \.marca) { LinhaDaLegendaDaFaixa(linha: $0) }
+            }
+            .padding(.top, 6)
+        }
+    }
+}
+
+/// O desenho da faixa, em formas (sem texto): cada marca no x que o núcleo deu, como fração da largura.
+struct DesenhoDaFaixa: View {
+    static let altura: CGFloat = 46
+    let faixa: FaixaDoSimulador
+    @Environment(\.paleta) private var paleta
+    #if DEBUG
+    @Environment(\.marcasApagadas) private var apagadas
+    #endif
+
+    /// O x de cada marca numa faixa da largura dada.
+    static func posicoes(_ faixa: FaixaDoSimulador, largura: CGFloat) -> [MarcaDaFaixa: CGFloat] {
+        Dictionary(uniqueKeysWithValues: faixa.linhas.map { ($0.marca, largura * CGFloat($0.fracao)) })
+    }
+
+    var body: some View {
+        GeometryReader { geo in
+            let largura = geo.size.width, altura = geo.size.height
+            let x = Self.posicoes(faixa, largura: largura)
+            let custo = x[.custo] ?? 0, empate = x[.empate] ?? 0, venda = x[.venda] ?? 0
+            let tinta = paleta.cor(.texto)
+            let zona = UnevenRoundedRectangle(bottomTrailingRadius: 12, topTrailingRadius: 12)
+            ZStack(alignment: .topLeading) {
+                // O trilho: o texto a 14%, como o da barra do orçamento.
+                RoundedRectangle(cornerRadius: 12).fill(tinta.opacity(0.14))
+                Group {
+                    // A zona "acima do banco": do empate até o fim, hachurada, com o contorno no destaque.
+                    zona.fill(paleta.cor(.positivoFundo))
+                        .overlay { Hachura(traco: 2, passo: 6).fill(paleta.cor(.destaque).opacity(0.55)).clipShape(zona) }
+                        .overlay { zona.strokeBorder(paleta.cor(.destaque), lineWidth: 1.5) }
+                        .frame(width: max(0, largura - empate), height: altura)
+                        .offset(x: empate)
+                    // O custo: uma barra de 3 pt, 6 acima e 6 abaixo da faixa.
+                    RoundedRectangle(cornerRadius: 2).fill(tinta).frame(width: 3, height: altura + 12).offset(x: custo, y: -6)
+                    // O empate com o banco: o tracejado.
+                    Path { p in
+                        p.move(to: CGPoint(x: empate + 1, y: -6))
+                        p.addLine(to: CGPoint(x: empate + 1, y: altura + 6))
+                    }
+                    .stroke(tinta, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
+                    // A venda: a barra de 4 pt, 8 acima e 8 abaixo, com o ponto de 12 pt em cima.
+                    RoundedRectangle(cornerRadius: 2).fill(tinta).frame(width: 4, height: altura + 16).offset(x: venda - 2, y: -8)
+                    Circle().fill(tinta).frame(width: 12, height: 12).offset(x: venda - 6, y: -15)
+                }
+                .opacity(marcasSomem ? 0 : 1)
+            }
+        }
+    }
+
+    private var marcasSomem: Bool {
+        #if DEBUG
+        return apagadas
+        #else
+        return false
+        #endif
+    }
+}
+
+/// Uma linha da lista embaixo da faixa: o marcador da marca, o rótulo e o valor em mono; na letra de acessibilidade, o
+/// valor embaixo do rótulo.
+private struct LinhaDaLegendaDaFaixa: View {
+    let linha: LinhaDaFaixa
+    @Environment(\.paleta) private var paleta
+    @Environment(\.vidro) private var vidro
+    @Environment(\.dynamicTypeSize) private var tamanho
+
+    var body: some View {
+        let grande = tamanho.isAccessibilitySize
+        let layout = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2)) : AnyLayout(HStackLayout(spacing: 10))
+        layout {
+            HStack(spacing: 10) {
+                marcador.frame(width: 18, height: 18)
+                Text(linha.rotulo)
+                    .font(.subheadline)
+                    .foregroundStyle(paleta.cor(vidro.secundario))
+                    .fixedSize(horizontal: false, vertical: true)
+            }
+            .frame(maxWidth: grande ? nil : .infinity, alignment: .leading)
+            ValorEmDinheiro(linha.valor, mono: .miudo)
+        }
+        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
+        .padding(.vertical, grande ? 8 : 0)
+        .accessibilityElement(children: .ignore)
+        .accessibilityLabel(linha.rotulo)
+        .accessibilityValue(linha.valor)
+        .accessibilityIdentifier("simFaixa-\(linha.marca.rawValue)")
+    }
+
+    @ViewBuilder private var marcador: some View {
+        let tinta = paleta.cor(.texto)
+        switch linha.marca {
+        case .custo: RoundedRectangle(cornerRadius: 2).fill(tinta).frame(width: 3, height: 18)
+        case .empate:
+            Path { p in
+                p.move(to: CGPoint(x: 9, y: 0))
+                p.addLine(to: CGPoint(x: 9, y: 18))
+            }
+            .stroke(tinta, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
+        case .venda: Circle().fill(tinta).frame(width: 12, height: 12)
+        }
+    }
+}
+
 /// Com obra e sem preço: a frase do site, num bloco de vidro.
 struct SemPrecoDoValeAPena: View {
     @Environment(\.paleta) private var paleta
diff --git a/app-ios/CusttaTests/FaixaDoValeAPenaTests.swift b/app-ios/CusttaTests/FaixaDoValeAPenaTests.swift
new file mode 100644
index 0000000..3920384
--- /dev/null
+++ b/app-ios/CusttaTests/FaixaDoValeAPenaTests.swift
@@ -0,0 +1,33 @@
+import Testing
+import SwiftUI
+import CusttaNucleo
+@testable import Custta
+
+/* O desenho da faixa "Onde a sua venda cai": cada marca no x que o núcleo deu, como fração da largura. A conta sai de uma
+   obra com um gasto só de R$ 1.000.000,00, pela regra do núcleo (`contaSimulador` e `faixaSimulador`). */
+@MainActor
+struct FaixaDoValeAPenaTests {
+    private func faixa(venda: Double, gastoEm data: String = "2026-10-12") throws -> FaixaDoSimulador {
+        let obra = Obra(arvore: ["id": .texto("o"), "nome": .texto("Obra"), "dataInicio": .texto(data),
+                                 "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(1_000_000), "data": .texto(data)])])])
+        return faixaSimulador(try #require(contaSimulador(obra, venda: venda, meses: 0, hoje: "2026-10-12", taxa: 1)))
+    }
+
+    @Test func cadaMarcaNoXDaFracaoDela() throws {
+        // Gasto de hoje: o empate é o próprio custo. A escala vai de 970 mil a 2,06 milhões.
+        let x = DesenhoDaFaixa.posicoes(try faixa(venda: 2_000_000), largura: 300)
+        #expect(abs((x[.custo] ?? -1) - 8.2568807339) < 1e-6)
+        #expect(abs((x[.empate] ?? -1) - 8.2568807339) < 1e-6)
+        #expect(abs((x[.venda] ?? -1) - 283.4862385321) < 1e-6)
+    }
+
+    @Test func aVendaAbaixoDoBancoFicaAEsquerdaDoEmpate() throws {
+        // Gasto de um ano atrás: corrigido a 1% ao mês, o empate passa de R$ 1,12 milhão, e a venda de R$ 1,05 milhão fica
+        // entre o custo e ele, fora da zona hachurada, que vai do empate ao fim.
+        let f = try faixa(venda: 1_050_000, gastoEm: "2025-10-12")
+        let x = DesenhoDaFaixa.posicoes(f, largura: 300)
+        #expect(!f.acima)
+        #expect((x[.custo] ?? 0) < (x[.venda] ?? 0))
+        #expect((x[.venda] ?? 0) < (x[.empate] ?? 0))
+    }
+}
diff --git a/app-ios/CusttaUITests/ValeAPenaUITests.swift b/app-ios/CusttaUITests/ValeAPenaUITests.swift
index c2c179a..ec73022 100644
--- a/app-ios/CusttaUITests/ValeAPenaUITests.swift
+++ b/app-ios/CusttaUITests/ValeAPenaUITests.swift
@@ -105,6 +105,32 @@ final class ValeAPenaUITests: XCTestCase {
         XCTAssertFalse(veredito.exists, "sem preço não há veredito")
     }
 
+    /// A faixa "Onde a sua venda cai": uma imagem com a frase dos três valores para o VoiceOver, a pílula do lado em que a
+    /// venda caiu e a lista com o custo, o empate e a venda. A Casa Alphaville custou R$ 842.317,45 e tem a venda estimada em
+    /// R$ 1.450.000,00: cai acima do banco. Sem preço, a faixa some com o veredito.
+    @MainActor func testAFaixaMostraOndeAVendaCai() {
+        let app = abrirAAba()
+        let faixa = app.elemento("simFaixa")
+        XCTAssertTrue(faixa.waitForExistence(timeout: 5))
+        XCTAssertTrue(faixa.label.hasPrefix("Custo R$\u{00A0}842.317,45, empata com o banco em R$\u{00A0}"), faixa.label)
+        XCTAssertTrue(faixa.label.hasSuffix(", sua venda R$\u{00A0}1.450.000,00"), faixa.label)
+        XCTAssertEqual(app.elemento("simPilula").label, "acima do banco")
+        XCTAssertEqual(app.elemento("simFaixa-custo").label, "custo (bruto)")
+        XCTAssertEqual(app.elemento("simFaixa-custo").value as? String, "R$\u{00A0}842.317,45")
+        XCTAssertEqual(app.elemento("simFaixa-empate").label, "empata com o banco")
+        XCTAssertEqual(app.elemento("simFaixa-venda").value as? String, "R$\u{00A0}1.450.000,00")
+        // As três linhas ficam embaixo da faixa, na ordem do custo, do empate e da venda.
+        let linhas = ["custo", "empate", "venda"].map { app.elemento("simFaixa-\($0)").frame.minY }
+        XCTAssertEqual(linhas, linhas.sorted())
+        XCTAssertGreaterThan(linhas[0], faixa.frame.maxY)
+        app.buttons["simObra"].tap()
+        let sobrado = app.buttons["Sobrado Granja Viana"]
+        XCTAssertTrue(sobrado.waitForExistence(timeout: 5))
+        sobrado.tap()
+        XCTAssertTrue(app.elemento("simSemPreco").waitForExistence(timeout: 5))
+        XCTAssertFalse(faixa.exists, "sem preço não há faixa")
+    }
+
     /// Sem nenhuma obra elegível, a linha da obra diz o que fazer, como no site, e não há lista para abrir.
     @MainActor func testSemObraElegivelALinhaDizOQueFazer() {
         let app = abrirApp(conta: "senha", dados: "vazio", abrir: "aba:valeAPena")
```

### Tarefa 7: tabela "Relatório da simulação" no "Vale a pena?"

**Commit das fatias:** `f2bbf80` · **Mensagem:** `feat: tabela "Relatório da simulação" no "Vale a pena?"`

A aba ganha a tabela do site, pelo bruto e pelo corrigido: custo até a venda, venda, lucro, as duas porcentagens, o rendimento ao mês e, na obra com área, o preço por metro quadrado. As linhas e os textos vêm do núcleo (textosSimulador). O desenho é o do mockup aprovado: em pares, com o rótulo em cima e os dois valores embaixo, e na letra de acessibilidade um valor por linha, com o nome da coluna em cima. O que é negativo vai em âmbar, nunca em vermelho. Para o VoiceOver, cada linha é um elemento com os dois valores.

**Prova:** 2 de unidade e 8 de tela; 3 mutações pegas; prints conferidos (padrão e letra máxima, rolada).

**Arquivos:**

```
 app-ios/Custta/Analise/ValeAPenaView.swift       | 82 +++++++++++++++++++++++-
 app-ios/CusttaTests/TabelaDoValeAPenaTests.swift | 21 ++++++
 app-ios/CusttaUITests/ValeAPenaUITests.swift     | 18 ++++++
 3 files changed, 119 insertions(+), 2 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Analise/ValeAPenaView.swift b/app-ios/Custta/Analise/ValeAPenaView.swift
index 4586fab..ee49ef5 100644
--- a/app-ios/Custta/Analise/ValeAPenaView.swift
+++ b/app-ios/Custta/Analise/ValeAPenaView.swift
@@ -2,8 +2,8 @@ import SwiftUI
 import CusttaNucleo
 
 /* A aba "Vale a pena?" (etapa 4, PR 4a; mockup aprovado, parte 2, `telaSimula`): o simulador do site na identidade nova. O
-   título solto em mono, o bloco dos campos (a obra, o preço e os meses, com a nota do site), o veredito no bloco sólido e a
-   faixa "Onde a sua venda cai"; a tabela chega no próximo commit. Os campos moram no PrincipalView, e não aqui: só a aba escolhida fica montada, e eles têm de durar
+   título solto em mono, o bloco dos campos (a obra, o preço e os meses, com a nota do site), o veredito no bloco sólido, a
+   faixa "Onde a sua venda cai" e a tabela do site, pelo bruto e pelo corrigido. Os campos moram no PrincipalView, e não aqui: só a aba escolhida fica montada, e eles têm de durar
    enquanto o app está aberto (spec, "Dados e estado"). O que a tela mostra sai inteiro do núcleo (`simulacaoNaTela`), com
    as obras e a taxa de agora: uma mudança vinda de outro aparelho redesenha a aba na hora. */
 struct ValeAPenaView: View {
@@ -26,6 +26,7 @@ struct ValeAPenaView: View {
                     if let veredito = tela.veredito {
                         VereditoDoValeAPena(veredito: veredito)
                         if let faixa = tela.faixa { FaixaDoValeAPena(faixa: faixa) }
+                        if let textos = tela.textos { TabelaDoValeAPena(linhas: textos.tabela) }
                     } else if tela.obra != nil {
                         SemPrecoDoValeAPena()
                     }
@@ -319,6 +320,83 @@ private struct LinhaDaLegendaDaFaixa: View {
     }
 }
 
+/// A tabela do site, "Relatório da simulação" (mockup da etapa 4, parte2.css:100-107; decisão 7 da parte 2): em pares, com
+/// o rótulo em cima e os dois valores embaixo, "Pelo bruto" e "Pelo corrigido"; na letra de acessibilidade, um valor por
+/// linha, cada um com o nome da coluna em cima. O lucro vai em negrito. O que é negativo vai em âmbar, nunca em vermelho
+/// (nota do quadro `sim-abaixo-baixo`). Para o VoiceOver, cada linha é um elemento, com os dois valores.
+struct TabelaDoValeAPena: View {
+    static let colunas = ["Pelo bruto", "Pelo corrigido"]
+    let linhas: [LinhaDaSimulacao]
+    @Environment(\.paleta) private var paleta
+    @Environment(\.vidro) private var vidro
+    @Environment(\.dynamicTypeSize) private var tamanho
+
+    /// A cor de um valor pelo sinal: positivo no verde dos números, negativo no âmbar, sem sinal no texto.
+    static func cor(_ sinal: SinalDaSimulacao?) -> Token {
+        switch sinal {
+        case .positivo: return .positivoNoVidro
+        case .negativo: return .alertaNoVidro
+        case nil: return .texto
+        }
+    }
+
+    var body: some View {
+        let grande = tamanho.isAccessibilitySize
+        BlocoDeVidro {
+            Text("Relatório da simulação")
+                .font(.body.weight(.semibold))
+                .foregroundStyle(paleta.cor(.texto))
+                .fixedSize(horizontal: false, vertical: true)
+                .accessibilityAddTraits(.isHeader)
+                .padding(.bottom, 8)
+            if !grande {
+                HStack(spacing: 12) {
+                    ForEach(Self.colunas, id: \.self) { coluna in
+                        Text(coluna)
+                            .font(.footnote.weight(.semibold))
+                            .foregroundStyle(paleta.cor(vidro.secundario))
+                            .frame(maxWidth: .infinity, alignment: .leading)
+                    }
+                }
+                .padding(.bottom, 6)
+                .accessibilityHidden(true)
+                LinhaFina()
+            }
+            ForEach(Array(linhas.enumerated()), id: \.offset) { indice, linha in
+                VStack(alignment: .leading, spacing: 0) {
+                    Text(linha.rotulo)
+                        .font(.subheadline)
+                        .foregroundStyle(paleta.cor(vidro.secundario))
+                        .fixedSize(horizontal: false, vertical: true)
+                        .padding(.top, 9)
+                    let par = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6)) : AnyLayout(HStackLayout(spacing: 12))
+                    par {
+                        valor(linha.bruto, linha.sinalBruto, coluna: grande ? Self.colunas[0] : nil, forte: linha.destaque)
+                        valor(linha.corrigido, linha.sinalCorrigido, coluna: grande ? Self.colunas[1] : nil, forte: linha.destaque)
+                    }
+                    .padding(.top, 2)
+                    .padding(.bottom, 8)
+                    if indice < linhas.count - 1 { LinhaFina() }
+                }
+                .accessibilityElement(children: .ignore)
+                .accessibilityLabel(linha.rotulo)
+                .accessibilityValue("\(Self.colunas[0]) \(linha.bruto), \(Self.colunas[1].lowercased()) \(linha.corrigido)")
+                .accessibilityIdentifier("simTabela-\(indice)")
+            }
+        }
+    }
+
+    private func valor(_ texto: String, _ sinal: SinalDaSimulacao?, coluna: String?, forte: Bool) -> some View {
+        VStack(alignment: .leading, spacing: 0) {
+            if let coluna {
+                Text(coluna).font(.footnote.weight(.medium)).foregroundStyle(paleta.cor(vidro.secundario))
+            }
+            ValorEmDinheiro(texto, mono: .miudo, cor: Self.cor(sinal)).fontWeight(forte ? .bold : nil)
+        }
+        .frame(maxWidth: .infinity, alignment: .leading)
+    }
+}
+
 /// Com obra e sem preço: a frase do site, num bloco de vidro.
 struct SemPrecoDoValeAPena: View {
     @Environment(\.paleta) private var paleta
diff --git a/app-ios/CusttaTests/TabelaDoValeAPenaTests.swift b/app-ios/CusttaTests/TabelaDoValeAPenaTests.swift
new file mode 100644
index 0000000..6d761de
--- /dev/null
+++ b/app-ios/CusttaTests/TabelaDoValeAPenaTests.swift
@@ -0,0 +1,21 @@
+import Testing
+import CusttaNucleo
+@testable import Custta
+
+/* A tabela do "Vale a pena?": a cor de cada valor sai do sinal que o núcleo deu. Negativo é âmbar, nunca vermelho (mockup
+   da etapa 4, nota do quadro `sim-abaixo-baixo`). */
+@MainActor
+struct TabelaDoValeAPenaTests {
+    @Test func negativoVaiEmAmbarNuncaEmVermelho() {
+        #expect(TabelaDoValeAPena.cor(.negativo) == .alertaNoVidro)
+        #expect(TabelaDoValeAPena.cor(.positivo) == .positivoNoVidro)
+        #expect(TabelaDoValeAPena.cor(nil) == .texto)
+        for sinal in [SinalDaSimulacao.positivo, .negativo] {
+            #expect(![Token.negativo, .negativoNoVidro, .erroNoVidro].contains(TabelaDoValeAPena.cor(sinal)))
+        }
+    }
+
+    @Test func asColunasSaoAsDoSite() {
+        #expect(TabelaDoValeAPena.colunas == ["Pelo bruto", "Pelo corrigido"])
+    }
+}
diff --git a/app-ios/CusttaUITests/ValeAPenaUITests.swift b/app-ios/CusttaUITests/ValeAPenaUITests.swift
index ec73022..0fb6911 100644
--- a/app-ios/CusttaUITests/ValeAPenaUITests.swift
+++ b/app-ios/CusttaUITests/ValeAPenaUITests.swift
@@ -131,6 +131,24 @@ final class ValeAPenaUITests: XCTestCase {
         XCTAssertFalse(faixa.exists, "sem preço não há faixa")
     }
 
+    /// A tabela do site, "Relatório da simulação": sete linhas na Casa Alphaville (a última é o preço por m², porque ela tem
+    /// área), cada uma um elemento com os dois valores, pelo bruto e pelo corrigido. Sem preço, a tabela some.
+    @MainActor func testATabelaDaSimulacao() {
+        let app = abrirAAba()
+        let custo = app.elemento("simTabela-0")
+        app.rolarAte(custo)
+        XCTAssertEqual(custo.label, "Custo até a venda")
+        XCTAssertTrue((custo.value as? String ?? "").hasPrefix("Pelo bruto R$\u{00A0}842.317,45, pelo corrigido R$\u{00A0}"), "\(String(describing: custo.value))")
+        XCTAssertEqual(app.elemento("simTabela-1").label, "Venda")
+        XCTAssertEqual(app.elemento("simTabela-1").value as? String, "Pelo bruto R$\u{00A0}1.450.000,00, pelo corrigido R$\u{00A0}1.450.000,00")
+        XCTAssertEqual(app.elemento("simTabela-2").label, "Lucro")
+        XCTAssertTrue((app.elemento("simTabela-2").value as? String ?? "").hasPrefix("Pelo bruto R$\u{00A0}607.682,55, "))
+        XCTAssertEqual((3...6).map { app.elemento("simTabela-\($0)").label },
+                       ["% sobre o custo", "% sobre a venda", "Rendimento ao mês", "Preço por m² (300 m²)"])
+        XCTAssertEqual(app.elemento("simTabela-6").value as? String, "Pelo bruto R$\u{00A0}4.833,33, pelo corrigido R$\u{00A0}4.833,33")
+        XCTAssertFalse(app.elemento("simTabela-7").exists, "sete linhas")
+    }
+
     /// Sem nenhuma obra elegível, a linha da obra diz o que fazer, como no site, e não há lista para abrir.
     @MainActor func testSemObraElegivelALinhaDizOQueFazer() {
         let app = abrirApp(conta: "senha", dados: "vazio", abrir: "aba:valeAPena")
```

### Tarefa 8: auditoria do "Vale a pena?" na maior letra e no contraste

**Commit das fatias:** `081d180` · **Mensagem:** `test: auditoria do "Vale a pena?" na maior letra e no contraste`

A aba nova entra nas auditorias de acessibilidade, como Ajustes: na maior letra, com a conta inteira à vista e rolada até o fim (também com Aumentar contraste e com Reduzir transparência), e no contraste com as superfícies sólidas, nos dois temas. A Casa Alphaville dos falsos da análise tem venda estimada, então os campos, o veredito, a faixa e a tabela aparecem sem digitar nada.

**Prova:** `testValeAPenaNoMaiorTamanho` e `testContrasteDoValeAPenaNosDoisTemas` verdes no iOS 27 (243 s) e no 26.5 (264 s). **Sem mutação:** não está provado que a auditoria pega um defeito plantado nesta tela.

**Arquivos:**

```
 app-ios/CusttaUITests/AuditoriaUITests.swift | 31 ++++++++++++++++++++++++++++
 1 file changed, 31 insertions(+)
```

**Mudança:**

```diff
diff --git a/app-ios/CusttaUITests/AuditoriaUITests.swift b/app-ios/CusttaUITests/AuditoriaUITests.swift
index 018f464..6ee96b4 100644
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -258,6 +258,37 @@ final class AuditoriaUITests: XCTestCase {
         }
     }
 
+    /// O "Vale a pena?" na maior letra, com a conta inteira (a Casa Alphaville tem venda estimada): os campos um embaixo do
+    /// outro, o veredito, a faixa com a lista e a tabela com um valor por linha, rolada até o fim; também com "Aumentar
+    /// contraste" e com "Reduzir transparência".
+    @MainActor func testValeAPenaNoMaiorTamanho() throws {
+        for opcao in [[], ["-custta.aumentarContraste", "YES"], solido] {
+            let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena", argumentos: maiorLetra + parado + opcao)
+            XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
+            try auditar(app, tiposDeAuditoria)
+            for _ in 0..<6 {
+                rolar(app)
+                try auditar(app, tiposDeAuditoria)
+            }
+            app.terminate()
+        }
+    }
+
+    /// O "Vale a pena?" com superfícies sólidas, no escuro e no claro: os campos, o veredito no sólido, a faixa e a tabela.
+    @MainActor func testContrasteDoValeAPenaNosDoisTemas() throws {
+        for tema in temas {
+            let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
+                               argumentos: ["-custta.tema", tema] + solido + parado)
+            XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
+            try auditar(app, [.contrast])
+            for _ in 0..<2 {
+                rolar(app)
+                try auditar(app, [.contrast])
+            }
+            app.terminate()
+        }
+    }
+
     /// O falta pouco das contas Apple e Google, que nenhuma outra auditoria abre na maior letra.
     @MainActor func testFaltaPoucoNoMaiorTamanho() throws {
         for conta in ["apple-sem-perfil", "google-sem-perfil"] {
```

### Tarefa 9: teclas do preço no "Vale a pena?", no lugar da cápsula

**Commit das fatias:** `4303532` · **Mensagem:** `feat: teclas do preço no "Vale a pena?", no lugar da cápsula`

O toque em "Se eu vender por" abre as teclas de valor do app no lugar da cápsula de abas, como no mockup aprovado (parte 2, sim-teclado): a barra com "Preço de venda" e "OK" e a grade de teclas da etapa 3, num campo só. As teclas entram na área segura de baixo da tela da aba, e não na barra do PrincipalView: a barra dele não entra na área segura da rolagem, e na letra máxima a linha do preço ficava atrás das teclas. O PrincipalView só tira a cápsula enquanto elas estão abertas.

O que a digitação faz com o campo segue a decisão do Giovani de 24/11, que o mockup não desenha: as teclas abrem com o valor à vista, a primeira tecla o substitui e o OK sem digitar deixa os campos como estavam, com o preço ainda acompanhando a venda estimada. A regra mora no núcleo (PrecoNasTeclas), e a conta da tela acompanha cada tecla, como no site.

**Prova:** Núcleo: 6 testes do `PrecoNasTeclas`, 4 mutações pegas. Tela: a suíte da aba no iOS 27 e no 26.5; a linha do preço acima das teclas na letra máxima com 3 mutações pegas.

**Arquivos:**

```
 app-ios/Custta/Analise/TeclasDoPreco.swift         |  65 ++++++++++++++
 app-ios/Custta/Analise/ValeAPenaView.swift         | 100 +++++++++++++--------
 app-ios/Custta/Telas/PrincipalView.swift           |  14 ++-
 .../Sources/CusttaNucleo/Simulador.swift           |  22 +++++
 .../CusttaNucleoTests/PrecoNasTeclasTests.swift    |  97 ++++++++++++++++++++
 app-ios/CusttaUITests/ValeAPenaUITests.swift       |  74 +++++++++++++++
 6 files changed, 334 insertions(+), 38 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Analise/TeclasDoPreco.swift b/app-ios/Custta/Analise/TeclasDoPreco.swift
new file mode 100644
index 0000000..c42dc0d
--- /dev/null
+++ b/app-ios/Custta/Analise/TeclasDoPreco.swift
@@ -0,0 +1,65 @@
+import SwiftUI
+import CusttaNucleo
+
+/* As teclas do preço do "Vale a pena?" (etapa 4, PR 4a; mockup aprovado, parte 2, `sim-teclado`): tomam o lugar da cápsula de
+   abas enquanto a pessoa digita o "Se eu vender por". Uma faixa da Folha com os cantos de cima redondos, a barra ("Preço de
+   venda" e "OK") e as teclas do teclado de valor da etapa 3 (a GradeDeTeclas encaixada: os centavos entram pela direita, com
+   "00" e apagar), num campo só, sem ‹ ›. O que a digitação faz com o campo é do núcleo (`PrecoNasTeclas`, decisão do Giovani
+   de 24/11): o valor fica à vista, a primeira tecla o substitui e o OK sem digitar deixa tudo como estava. A conta da tela
+   acompanha cada tecla, como no site. Entram na área segura de baixo da tela da aba (`safeAreaInset`), como o "Salvar" das
+   folhas: é por ela que a rolagem sabe onde as teclas começam. */
+struct TeclasDoPreco: View {
+    @Binding var campos: CamposDoSimulador
+    let ok: () -> Void
+    @State private var preco = PrecoNasTeclas()
+    @Environment(\.paleta) private var paleta
+    @Environment(\.opcoes) private var opcoes
+
+    var body: some View {
+        VStack(spacing: 0) {
+            // A letra da barra para no xxxLarge, como a das teclas encaixadas da etapa 3, com o Visualizador de Conteúdo Grande.
+            HStack(spacing: 8) {
+                Text("Preço de venda")
+                    .font(.subheadline.weight(.medium))
+                    .foregroundStyle(paleta.cor(.secundarioTransparente))
+                    .fixedSize(horizontal: false, vertical: true)
+                    .frame(maxWidth: .infinity, alignment: .leading)
+                    .accessibilityShowsLargeContentViewer()
+                    .accessibilityIdentifier("teclasDoPreco-titulo")
+                Button(action: ok) {
+                    Text("OK")
+                        .font(.body.weight(.semibold))
+                        .foregroundStyle(paleta.cor(.destaqueTexto))
+                        .padding(.horizontal, 6)
+                        .frame(minWidth: 44, minHeight: 44)
+                        .contentShape(.rect)
+                }
+                .buttonStyle(.plain)
+                .accessibilityShowsLargeContentViewer()
+                .accessibilityIdentifier("teclasDoPreco-ok")
+            }
+            .padding(.horizontal, 8)
+            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
+            GradeDeTeclas(centavos: Binding(get: { preco.centavos }, set: { campos.precoDigitado = preco.digitar($0) }),
+                          tamanho: .encaixado)
+        }
+        .padding(.horizontal, 12)
+        .padding(.top, 4)
+        // Embaixo, a área segura do aparelho (34 pt; no mockup, 30): o fundo desce até a borda da tela.
+        .padding(.bottom, 0)
+        .background { fundo.ignoresSafeArea(edges: .bottom).accessibilityHidden(true) }
+        .accessibilityElement(children: .contain)
+        // O gesto de sair do VoiceOver (o Z) fecha as teclas, como o "OK". Só existe com elas abertas: não engole o de mais ninguém.
+        .accessibilityAction(.escape, ok)
+        .accessibilityIdentifier("teclasDoPreco")
+    }
+
+    /// A Folha, como a das folhas do app: a cor do token sobre o desfoque do que rola atrás; com "Reduzir transparência",
+    /// opaca, sobre o Fundo. Sem a sombra de cima do mockup (preto a 35%): o app não tem token de sombra de painel, e cor
+    /// solta não entra.
+    @ViewBuilder private var fundo: some View {
+        let forma = UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
+        if opcoes.reduzirTransparencia { forma.fill(paleta.cor(.folha)).background(paleta.cor(.fundo), in: forma) }
+        else { forma.fill(paleta.cor(.folha)).background(.ultraThinMaterial, in: forma) }
+    }
+}
diff --git a/app-ios/Custta/Analise/ValeAPenaView.swift b/app-ios/Custta/Analise/ValeAPenaView.swift
index ee49ef5..0fe1f45 100644
--- a/app-ios/Custta/Analise/ValeAPenaView.swift
+++ b/app-ios/Custta/Analise/ValeAPenaView.swift
@@ -5,9 +5,14 @@ import CusttaNucleo
    título solto em mono, o bloco dos campos (a obra, o preço e os meses, com a nota do site), o veredito no bloco sólido, a
    faixa "Onde a sua venda cai" e a tabela do site, pelo bruto e pelo corrigido. Os campos moram no PrincipalView, e não aqui: só a aba escolhida fica montada, e eles têm de durar
    enquanto o app está aberto (spec, "Dados e estado"). O que a tela mostra sai inteiro do núcleo (`simulacaoNaTela`), com
-   as obras e a taxa de agora: uma mudança vinda de outro aparelho redesenha a aba na hora. */
+   as obras e a taxa de agora: uma mudança vinda de outro aparelho redesenha a aba na hora. O toque no preço abre as teclas
+   (`TeclasDoPreco`) no lugar da cápsula de abas. As teclas são desta tela, na área segura da rolagem, para a linha do preço
+   subir acima delas; a cápsula é do PrincipalView, que a tira enquanto o `teclasAbertas` vale: daí ele vir de lá. */
 struct ValeAPenaView: View {
+    /// A linha do preço na rolagem: com as teclas abertas, ela fica à vista acima delas.
+    static let linhaDoPreco = "simLinhaDoPreco"
     @Binding var campos: CamposDoSimulador
+    @Binding var teclasAbertas: Bool
     @Environment(ModeloApp.self) private var modelo
     @State private var confirmarSaida = false
     @State private var barra = BarraDaObra()
@@ -17,36 +22,47 @@ struct ValeAPenaView: View {
         let tela = simulacaoNaTela(campos, obras: estado.obras, hoje: dataLocalISO(.now, fuso: .current),
                                    taxa: estado.config.taxaMensal)
         NavigationStack {
-            ScrollView {
-                VStack(alignment: .leading, spacing: Grade.entreBlocos) {
-                    TituloMono(texto: "Será que vale a pena?", identificador: "tituloValeAPena")
-                        .padding(.bottom, 2)
-                    CamposDoValeAPena(campos: $campos, tela: tela)
-                    // Sem obra elegível, só os campos, como no site. Com obra e sem preço, a frase do site no lugar da conta.
-                    if let veredito = tela.veredito {
-                        VereditoDoValeAPena(veredito: veredito)
-                        if let faixa = tela.faixa { FaixaDoValeAPena(faixa: faixa) }
-                        if let textos = tela.textos { TabelaDoValeAPena(linhas: textos.tabela) }
-                    } else if tela.obra != nil {
-                        SemPrecoDoValeAPena()
+            ScrollViewReader { leitor in
+                ScrollView {
+                    VStack(alignment: .leading, spacing: Grade.entreBlocos) {
+                        TituloMono(texto: "Será que vale a pena?", identificador: "tituloValeAPena")
+                            .padding(.bottom, 2)
+                        CamposDoValeAPena(campos: $campos, tela: tela, teclasAbertas: $teclasAbertas)
+                        // Sem obra elegível, só os campos, como no site. Com obra e sem preço, a frase do site no lugar da conta.
+                        if let veredito = tela.veredito {
+                            VereditoDoValeAPena(veredito: veredito)
+                            if let faixa = tela.faixa { FaixaDoValeAPena(faixa: faixa) }
+                            if let textos = tela.textos { TabelaDoValeAPena(linhas: textos.tabela) }
+                        } else if tela.obra != nil {
+                            SemPrecoDoValeAPena()
+                        }
                     }
+                    .padding(.horizontal, Grade.externa)
+                    .padding(.bottom, 24)
                 }
-                .padding(.horizontal, Grade.externa)
-                .padding(.bottom, 24)
-            }
-            .scrollIndicators(.hidden)
-            .tituloPequenoAoRolar(barra)
-            .background { LeitorDaLetra(barra: barra) }
-            .pausaOFundoAoRolar()
-            .bordaDeRolagem(abas: true)
-            .containerBackground(.clear, for: .navigation)
-            .navigationTitle("Vale a pena?")
-            .navigationBarTitleDisplayMode(.inline)
-            .toolbar {
-                ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: "Vale a pena?", mono: true) }
-                BarraDoApp(confirmarSaida: $confirmarSaida)
+                .scrollIndicators(.hidden)
+                // Quando as teclas entram, a área de baixo da rolagem cresce: a linha do preço sobe só o que falta para ficar à
+                // vista acima delas (na letra máxima ela nasce mais embaixo). O gatilho é a medida, e não um tempo.
+                .onScrollGeometryChange(for: CGFloat.self) { $0.contentInsets.bottom } action: { antes, depois in
+                    if teclasAbertas, depois > antes { leitor.scrollTo(Self.linhaDoPreco) }
+                }
+                .tituloPequenoAoRolar(barra)
+                .background { LeitorDaLetra(barra: barra) }
+                .pausaOFundoAoRolar()
+                .bordaDeRolagem(abas: true)
+                // Por fora da borda de rolagem, que fica atrás das teclas. Os 8 pt são o respiro entre a linha do preço e elas.
+                .safeAreaInset(edge: .bottom, spacing: 8) {
+                    if teclasAbertas { TeclasDoPreco(campos: $campos) { teclasAbertas = false } }
+                }
+                .containerBackground(.clear, for: .navigation)
+                .navigationTitle("Vale a pena?")
+                .navigationBarTitleDisplayMode(.inline)
+                .toolbar {
+                    ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: "Vale a pena?", mono: true) }
+                    BarraDoApp(confirmarSaida: $confirmarSaida)
+                }
+                .confirmaSaida($confirmarSaida)
             }
-            .confirmaSaida($confirmarSaida)
         }
     }
 }
@@ -57,6 +73,7 @@ struct ValeAPenaView: View {
 struct CamposDoValeAPena: View {
     @Binding var campos: CamposDoSimulador
     let tela: SimulacaoNaTela
+    @Binding var teclasAbertas: Bool
     @Environment(\.paleta) private var paleta
     @Environment(\.vidro) private var vidro
     @Environment(\.dynamicTypeSize) private var tamanho
@@ -65,7 +82,7 @@ struct CamposDoValeAPena: View {
         BlocoDeVidro(recuoVertical: 4) {
             LinhaDoCampo(rotulo: "Obra") { obra }
             LinhaFina()
-            LinhaDoCampo(rotulo: "Se eu vender por") { preco }
+            preco.id(ValeAPenaView.linhaDoPreco)
             LinhaFina()
             LinhaDoCampo(rotulo: "Daqui a (meses)") { passo }
             LinhaFina()
@@ -111,18 +128,31 @@ struct CamposDoValeAPena: View {
         }
     }
 
-    /// O preço: o digitado ou, sem digitar, a venda estimada da obra; vazio, "R$ 0,00" apagado, como o campo do site.
+    /// O preço: o digitado ou, sem digitar, a venda estimada da obra; vazio, "R$ 0,00" apagado, como o campo do site. A linha
+    /// inteira é o botão que abre as teclas; com elas abertas, o cursor do mockup vem depois do valor (vazio, só o cursor).
     private var preco: some View {
-        Group {
-            if let valor = tela.preco {
-                ValorEmDinheiro(moeda(valor), mono: .linha)
-            } else {
-                ValorEmDinheiro(moeda(0), mono: .linha, cor: vidro.secundario)
+        Button { teclasAbertas = true } label: {
+            LinhaDoCampo(rotulo: "Se eu vender por") {
+                HStack(spacing: 3) {
+                    if let valor = tela.preco {
+                        ValorEmDinheiro(moeda(valor), mono: .linha)
+                    } else if !teclasAbertas {
+                        ValorEmDinheiro(moeda(0), mono: .linha, cor: vidro.secundario)
+                    }
+                    if teclasAbertas {
+                        RoundedRectangle(cornerRadius: 1)
+                            .fill(paleta.cor(.destaque))
+                            .frame(width: 2, height: 1.1 * crescendoComALetra(de: 17, ate: 34, corpo: corpoDoTexto(tamanho)))
+                    }
+                }
             }
+            .contentShape(.rect)
         }
+        .buttonStyle(.plain)
         .accessibilityElement(children: .ignore)
         .accessibilityLabel("Se eu vender por")
         .accessibilityValue(tela.preco.map { moeda($0) } ?? "sem preço")
+        .accessibilityAddTraits(.isButton)
         .accessibilityIdentifier("simPreco")
     }
 
diff --git a/app-ios/Custta/Telas/PrincipalView.swift b/app-ios/Custta/Telas/PrincipalView.swift
index 845422d..0d67f78 100644
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -13,6 +13,8 @@ struct PrincipalView: View {
     /// Os campos do "Vale a pena?": moram aqui, e não na tela da aba, que sai da árvore quando a pessoa troca de aba. Assim
     /// duram enquanto o app está aberto (spec da etapa 4, "Dados e estado").
     @State private var simulador = CamposDoSimulador()
+    /// As teclas do preço do "Vale a pena?" estão abertas, e a cápsula de abas sai (mockup da etapa 4, `sim-teclado`).
+    @State private var teclasDoPreco = false
     @State private var folhas = Folhas()
     /// O + da lista avisou em vez de abrir "Nova obra": o teto de obras ou os dados ainda não vistos.
     @State private var avisoDoMais: AvisoDoMais?
@@ -24,13 +26,18 @@ struct PrincipalView: View {
         Group {
             switch aba {
             case .obras: ObrasView(caminho: $caminhoDeObras)
-            case .valeAPena: ValeAPenaView(campos: $simulador)
+            case .valeAPena: ValeAPenaView(campos: $simulador, teclasAbertas: $teclasDoPreco)
             case .ajustes: AjustesView()
             }
         }
         .environment(folhas)
         // Barra própria: o que rola por baixo dela passa pela borda suave de cada tela (BordaDeRolagem).
-        .safeAreaBar(edge: .bottom, spacing: 0) { CapsulaDeAbas(escolhida: $aba, mais: acaoDoMais) }
+        .safeAreaBar(edge: .bottom, spacing: 0) {
+            // As teclas do preço tomam o lugar da cápsula; elas são da tela da aba, que as põe na área segura da rolagem.
+            if !(aba == .valeAPena && teclasDoPreco) { CapsulaDeAbas(escolhida: $aba, mais: acaoDoMais) }
+        }
+        // Fora do "Vale a pena?" não há teclas do preço: quem volta a ela encontra a cápsula.
+        .onChange(of: aba) { teclasDoPreco = false }
         .sheet(item: $folhas.aberta, onDismiss: folhas.fechou) { qual in
             Group {
                 switch qual {
@@ -72,7 +79,8 @@ struct PrincipalView: View {
         #endif
         // A cápsula se mede da borda da tela, como a barra de abas do sistema, e não acompanha o teclado: ao
         // entrar com ele aberto, o teclado da entrada ainda está fechando quando esta tela aparece, e a barra
-        // nascia em cima dele, no meio da tela, e saltava. As telas das abas não têm campo de texto.
+        // nascia em cima dele, no meio da tela, e saltava. Nas telas das abas, o teclado do sistema só aparece na busca da
+        // obra; o preço do "Vale a pena?" usa as teclas do app, e não ele.
         .ignoresSafeArea(edges: .bottom)
     }
 }
diff --git a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
index e56fc1e..c44270b 100644
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
@@ -223,6 +223,28 @@ public struct CamposDoSimulador: Equatable, Sendable {
     }
 }
 
+/* O preço nas teclas do "Vale a pena?" (decisão do Giovani de 24/11/2026; o mockup só desenha as teclas com o campo vazio).
+   As teclas abrem com o valor do campo à vista; a primeira tecla o substitui: a digitação parte do zero, e não do valor que
+   estava, que quase sempre é a venda estimada (com os centavos entrando pela direita, um dígito a mais faria de
+   R$ 1.450.000,00 R$ 14.500.000,0X). O OK sem digitar deixa os campos como estavam, com o preço ainda acompanhando a venda
+   estimada da obra: enquanto a pessoa não digita, nada é gravado nos campos. Vale enquanto as teclas estão abertas; ao abrir
+   de novo, começa outro. */
+public struct PrecoNasTeclas: Equatable, Sendable {
+    /// Os centavos digitados desde que as teclas abriram: zero até a primeira tecla, e é dele que ela parte.
+    public private(set) var centavos = 0
+    /// A pessoa já digitou desde que as teclas abriram.
+    public private(set) var digitou = false
+
+    public init() {}
+
+    /// As teclas mudaram o valor: guarda os centavos e devolve o preço, em reais, para o campo. Zero é o campo apagado.
+    public mutating func digitar(_ centavos: Int) -> Double {
+        self.centavos = max(0, centavos)
+        digitou = true
+        return centavosParaReais(self.centavos)
+    }
+}
+
 /// O que a tela do "Vale a pena?" mostra.
 public struct SimulacaoNaTela: Equatable, Sendable {
     /// As obras da lista "Obra", na ordem do documento; vazia, a tela diz "— crie uma obra com gastos —".
diff --git a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PrecoNasTeclasTests.swift b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PrecoNasTeclasTests.swift
new file mode 100644
index 0000000..6712088
--- /dev/null
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PrecoNasTeclasTests.swift
@@ -0,0 +1,97 @@
+import Testing
+@testable import CusttaNucleo
+
+/* O preço nas teclas do "Vale a pena?" (decisão do Giovani de 24/11/2026): as teclas abrem com o valor do campo à vista, a
+   primeira tecla o substitui e o OK sem digitar deixa os campos como estavam. Cada teste toca as teclas como a grade do app
+   faz: aplica a regra do teclado aos centavos das teclas e só entrega o valor quando ele muda. */
+struct PrecoNasTeclasTests {
+    private let hoje = "2026-10-12"
+
+    private func obra(_ id: String, estimada: Double? = nil) -> Obra {
+        var arvore: [String: ValorJSON] = [
+            "id": .texto(id), "nome": .texto("Obra \(id)"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-10"),
+            "gastos": .lista([.objeto(["id": .texto("\(id)-g"), "valor": .numero(100_000), "data": .texto("2026-01-15")])]),
+        ]
+        if let estimada { arvore["valorEstimadoVenda"] = .numero(estimada) }
+        return Obra(arvore: arvore)
+    }
+
+    private func precoNaTela(_ campos: CamposDoSimulador, _ obras: [Obra]) -> Double? {
+        simulacaoNaTela(campos, obras: obras, hoje: hoje, taxa: 1).preco
+    }
+
+    /// Uma tecla, como a `GradeDeTeclas`: a regra do teclado sobre os centavos das teclas, e o campo só muda se o valor mudou.
+    private func tocar(_ tecla: TeclaDeValor, _ teclas: inout PrecoNasTeclas, _ campos: inout CamposDoSimulador) {
+        let novo = aplicarTecla(teclas.centavos, tecla)
+        guard novo != teclas.centavos else { return }
+        campos.precoDigitado = teclas.digitar(novo)
+    }
+
+    @Test func oOkSemDigitarDeixaOsCamposComoEstavam() {
+        let a = obra("a", estimada: 300_000), b = obra("b", estimada: 180_000)
+        var campos = CamposDoSimulador()
+        let antes = campos
+        let teclas = PrecoNasTeclas()
+        #expect(teclas.centavos == 0)
+        #expect(!teclas.digitou)
+        // Abrir as teclas e dar OK não grava nada: o preço continua acompanhando a venda estimada da obra escolhida.
+        #expect(campos == antes)
+        #expect(precoNaTela(campos, [a, b]) == 300_000)
+        campos.obraId = "b"
+        #expect(precoNaTela(campos, [a, b]) == 180_000)
+    }
+
+    @Test func aPrimeiraTeclaSubstituiOValorAVista() {
+        let a = obra("a", estimada: 300_000)
+        var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
+        tocar(.digito(5), &teclas, &campos)
+        // Parte do zero, e não dos R$ 300.000,00 que estavam à vista (com o dígito a mais, seriam R$ 3.000.000,05).
+        #expect(teclas.centavos == 5)
+        #expect(teclas.digitou)
+        #expect(campos.precoDigitado == 0.05)
+        #expect(precoNaTela(campos, [a]) == 0.05)
+    }
+
+    @Test func tambemSubstituiOPrecoQueAPessoaJaTinhaDigitado() {
+        var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
+        campos.precoDigitado = 250_000
+        tocar(.digito(9), &teclas, &campos)
+        #expect(campos.precoDigitado == 0.09)
+    }
+
+    @Test func asTeclasSeguintesEntramPelaDireita() {
+        var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
+        for tecla in [TeclaDeValor.digito(1), .digito(4), .digito(5), .duploZero, .duploZero, .duploZero] {
+            tocar(tecla, &teclas, &campos)
+        }
+        #expect(teclas.centavos == 145_000_000)
+        #expect(campos.precoDigitado == 1_450_000)
+        tocar(.apagar, &teclas, &campos)
+        #expect(campos.precoDigitado == 145_000)
+    }
+
+    @Test func oZeroEOApagarNaPrimeiraTeclaNaoMudamNada() {
+        let a = obra("a", estimada: 300_000)
+        for tecla in [TeclaDeValor.digito(0), .duploZero, .apagar] {
+            var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
+            tocar(tecla, &teclas, &campos)
+            #expect(!teclas.digitou, "\(tecla.nome)")
+            #expect(campos.precoDigitado == nil, "\(tecla.nome)")
+            #expect(precoNaTela(campos, [a]) == 300_000, "\(tecla.nome)")
+        }
+    }
+
+    @Test func digitarEApagarTudoDeixaOCampoVazio() {
+        let a = obra("a", estimada: 300_000), b = obra("b", estimada: 180_000)
+        var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
+        tocar(.digito(7), &teclas, &campos)
+        tocar(.apagar, &teclas, &campos)
+        #expect(teclas.centavos == 0)
+        #expect(teclas.digitou)
+        // O campo apagado é campo tocado: fica vazio e não volta para a estimada, nem trocando de obra (como no site).
+        #expect(campos.precoDigitado == 0)
+        #expect(precoNaTela(campos, [a, b]) == nil)
+        campos.obraId = "b"
+        #expect(precoNaTela(campos, [a, b]) == nil)
+    }
+}
diff --git a/app-ios/CusttaUITests/ValeAPenaUITests.swift b/app-ios/CusttaUITests/ValeAPenaUITests.swift
index 0fb6911..f288cd6 100644
--- a/app-ios/CusttaUITests/ValeAPenaUITests.swift
+++ b/app-ios/CusttaUITests/ValeAPenaUITests.swift
@@ -149,6 +149,80 @@ final class ValeAPenaUITests: XCTestCase {
         XCTAssertFalse(app.elemento("simTabela-7").exists, "sete linhas")
     }
 
+    /// As teclas do preço (decisão do Giovani de 24/11): o toque na linha do preço troca a cápsula de abas pelas teclas, com
+    /// o valor à vista. O OK sem digitar devolve a cápsula e deixa tudo como estava: o preço segue acompanhando a venda
+    /// estimada (o Sobrado não tem, e o campo fica vazio).
+    @MainActor func testAsTeclasAbremComOValorEOOkSemDigitarNaoMudaNada() {
+        let app = abrirAAba()
+        let preco = app.elemento("simPreco"), teclas = app.elemento("teclasDoPreco"), ok = app.buttons["teclasDoPreco-ok"]
+        XCTAssertFalse(teclas.exists, "fechadas até o toque no preço")
+        preco.tap()
+        XCTAssertTrue(ok.waitForExistence(timeout: 5), "as teclas do preço")
+        XCTAssertEqual(app.elemento("teclasDoPreco-titulo").label, "Preço de venda")
+        XCTAssertEqual(ok.label, "OK")
+        XCTAssertTrue(app.abasDaCapsula.isEmpty, "as teclas tomam o lugar da cápsula de abas")
+        XCTAssertEqual(preco.value as? String, "R$\u{00A0}1.450.000,00", "o valor fica à vista")
+        XCTAssertLessThanOrEqual(preco.frame.maxY, teclas.frame.minY, "a linha do preço fica acima das teclas")
+        ok.tap()
+        XCTAssertTrue(app.buttons["aba-valeAPena"].waitForExistence(timeout: 5), "o OK devolve a cápsula")
+        XCTAssertFalse(ok.exists)
+        XCTAssertEqual(preco.value as? String, "R$\u{00A0}1.450.000,00")
+        app.buttons["simObra"].tap()
+        let sobrado = app.buttons["Sobrado Granja Viana"]
+        XCTAssertTrue(sobrado.waitForExistence(timeout: 5))
+        sobrado.tap()
+        XCTAssertEqual(preco.value as? String, "sem preço", "nada foi digitado: o preço ainda acompanha a venda estimada")
+    }
+
+    /// A primeira tecla substitui o valor à vista, e as seguintes entram pela direita, com a conta acompanhando cada uma:
+    /// R$ 800.000,00 na Casa Alphaville (custou R$ 842.317,45) rende menos que o banco. Apagado até o fim, o campo fica vazio
+    /// e a frase do site volta; depois do OK ele não retorna à venda estimada, nem trocando de obra (campo tocado, como no site).
+    @MainActor func testAPrimeiraTeclaSubstituiOValorEAContaAcompanha() {
+        let app = abrirAAba()
+        let preco = app.elemento("simPreco"), ok = app.buttons["teclasDoPreco-ok"]
+        preco.tap()
+        XCTAssertTrue(ok.waitForExistence(timeout: 5))
+        app.buttons["tecla-8"].tap()
+        XCTAssertEqual(preco.value as? String, "R$\u{00A0}0,08", "parte do zero, e não do R$ 1.450.000,00 que estava à vista")
+        for tecla in ["tecla-0", "tecla-00", "tecla-00", "tecla-00"] { app.buttons[tecla].tap() }
+        XCTAssertEqual(preco.value as? String, "R$\u{00A0}800.000,00")
+        let veredito = app.elemento("simVeredito")
+        XCTAssertTrue(veredito.label.hasPrefix("Rende menos que o banco, "), veredito.label)
+        XCTAssertEqual(app.elemento("simPilula").label, "abaixo do banco")
+        for _ in 1...9 { app.buttons["tecla-del"].tap() }
+        XCTAssertEqual(preco.value as? String, "sem preço")
+        XCTAssertTrue(app.elemento("simSemPreco").waitForExistence(timeout: 5), "sem preço, a frase do site")
+        XCTAssertFalse(veredito.exists)
+        ok.tap()
+        XCTAssertTrue(app.buttons["aba-valeAPena"].waitForExistence(timeout: 5))
+        XCTAssertEqual(preco.value as? String, "sem preço", "o campo apagado não volta para a venda estimada")
+        app.buttons["simObra"].tap()
+        let vilaNova = app.buttons["Sobrado Vila Nova"]
+        XCTAssertTrue(vilaNova.waitForExistence(timeout: 5))
+        vilaNova.tap()
+        XCTAssertEqual(app.buttons["simObra"].value as? String, "Sobrado Vila Nova")
+        XCTAssertEqual(preco.value as? String, "sem preço", "nem trocando para uma obra com venda estimada")
+    }
+
+    /// Na letra máxima, a linha do preço nasce mais embaixo, e as teclas são mais altas que a cápsula: ao abrir, a linha
+    /// sobe o que falta para ficar inteira acima delas, e abaixo da barra de cima.
+    @MainActor func testNaLetraMaximaALinhaDoPrecoFicaAcimaDasTeclas() {
+        let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
+                           argumentos: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
+        XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
+        let preco = app.elemento("simPreco"), teclas = app.elemento("teclasDoPreco")
+        app.rolarAte(preco)
+        preco.tap()
+        XCTAssertTrue(app.buttons["teclasDoPreco-ok"].waitForExistence(timeout: 5), "as teclas do preço")
+        // A rolagem que põe a linha à vista termina depois de as teclas aparecerem: espera o quadro assentar.
+        let acima = NSPredicate { _, _ in preco.frame.maxY <= teclas.frame.minY + 0.5 }
+        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: acima, object: nil)], timeout: 5), .completed,
+                       "a linha do preço (\(preco.frame)) acima das teclas (\(teclas.frame))")
+        XCTAssertGreaterThanOrEqual(preco.frame.minY, app.navigationBars.firstMatch.frame.maxY, "e abaixo da barra de cima")
+        app.buttons["tecla-5"].tap()
+        XCTAssertEqual(preco.value as? String, "R$\u{00A0}0,05")
+    }
+
     /// Sem nenhuma obra elegível, a linha da obra diz o que fazer, como no site, e não há lista para abrir.
     @MainActor func testSemObraElegivelALinhaDizOQueFazer() {
         let app = abrirApp(conta: "senha", dados: "vazio", abrir: "aba:valeAPena")
```

### Tarefa 10: trilho da faixa do "Vale a pena?" com os 46 pt do mockup

**Commit das fatias:** `d83291b` · **Mensagem:** `fix: trilho da faixa do "Vale a pena?" com os 46 pt do mockup`

O trilho da faixa "Onde a sua venda cai" saía com 62 pt, e não com os 46 do mockup (parte2.css:84). A pilha do desenho
cresce até a marca mais alta, a venda, com 16 pt a mais que a faixa, e o trilho, sem altura própria, crescia com ela. Na
tela, a zona hachurada cobria só os 46 pt de cima, sobrava uma tira cinza embaixo, e as marcas passavam do trilho só em
cima. Com a altura escrita no trilho, as marcas passam dele em cima e embaixo, como no mockup. Achado da revisão da Lupa,
medido por pixel no 18 Pro: o trilho ia de 1139 a 1325 px e passa a ir de 1139 a 1277.

**Prova:** Patch do Forja (achado da Lupa na tarefa 6), aplicado como veio; a suíte da aba verde no iOS 27.

**Arquivos:**

```
 app-ios/Custta/Analise/ValeAPenaView.swift | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Analise/ValeAPenaView.swift b/app-ios/Custta/Analise/ValeAPenaView.swift
index 0fe1f45..0a4b445 100644
--- a/app-ios/Custta/Analise/ValeAPenaView.swift
+++ b/app-ios/Custta/Analise/ValeAPenaView.swift
@@ -270,8 +270,9 @@ struct DesenhoDaFaixa: View {
             let tinta = paleta.cor(.texto)
             let zona = UnevenRoundedRectangle(bottomTrailingRadius: 12, topTrailingRadius: 12)
             ZStack(alignment: .topLeading) {
-                // O trilho: o texto a 14%, como o da barra do orçamento.
-                RoundedRectangle(cornerRadius: 12).fill(tinta.opacity(0.14))
+                // O trilho: o texto a 14%, como o da barra do orçamento. A altura vai escrita: a pilha cresce até a marca mais
+                // alta (a venda, 16 pt a mais), e um trilho sem altura cresceria com ela, para 62 pt, e sobraria embaixo da zona.
+                RoundedRectangle(cornerRadius: 12).fill(tinta.opacity(0.14)).frame(height: altura)
                 Group {
                     // A zona "acima do banco": do empate até o fim, hachurada, com o contorno no destaque.
                     zona.fill(paleta.cor(.positivoFundo))
```

### Tarefa 11: testes da análise na pasta dela, com a máquina do laudo e da auditoria aberta

**Commit das fatias:** `49da3d6` · **Mensagem:** `test: testes da análise na pasta dela, com a máquina do laudo e da auditoria aberta`

Os testes das telas da análise passam a morar em CusttaUITests/Analise e em CusttaTests/Analise, e as duas auditorias do "Vale a pena?" saem do AuditoriaUITests para o AuditoriaDaAnaliseUITests, sem mudar de conteúdo. É o que o filtro de portões por superfície precisa: pelo spec, o PR que só mexe na análise e nos testes dela roda só os jobs da etapa 4, e mexer num arquivo compartilhado de laudo ou de auditoria leva o PR ao nível tudo.

Para o arquivo novo usar a mesma máquina, os ajudantes que eram privados das duas classes viram extensões de protocolo (LaudoDeLeitura e AuditoriaDeTela), no mesmo arquivo e com o mesmo código: a cena do laudo sobe para o nível do arquivo (CenaDoLaudo), e as constantes viram propriedades calculadas. Nenhuma cena e nenhuma auditoria muda.

**Prova:** iOS 27: 18 testes de tela e 228 de unidade, sem mudança de resultado.

**Arquivos:**

```
 .../{ => Analise}/CosturaDaAnaliseTests.swift      |  0
 .../{ => Analise}/FaixaDoValeAPenaTests.swift      |  0
 .../{ => Analise}/TabelaDoValeAPenaTests.swift     |  0
 .../{ => Analise}/AnaliseUITests.swift             |  0
 .../Analise/AuditoriaDaAnaliseUITests.swift        | 37 +++++++++
 .../{ => Analise}/ValeAPenaUITests.swift           |  0
 app-ios/CusttaUITests/AuditoriaUITests.swift       | 57 ++++---------
 app-ios/CusttaUITests/LeituraNoVidroUITests.swift  | 97 ++++++++++++----------
 8 files changed, 107 insertions(+), 84 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/CusttaTests/CosturaDaAnaliseTests.swift b/app-ios/CusttaTests/Analise/CosturaDaAnaliseTests.swift
similarity index 100%
rename from app-ios/CusttaTests/CosturaDaAnaliseTests.swift
rename to app-ios/CusttaTests/Analise/CosturaDaAnaliseTests.swift
diff --git a/app-ios/CusttaTests/FaixaDoValeAPenaTests.swift b/app-ios/CusttaTests/Analise/FaixaDoValeAPenaTests.swift
similarity index 100%
rename from app-ios/CusttaTests/FaixaDoValeAPenaTests.swift
rename to app-ios/CusttaTests/Analise/FaixaDoValeAPenaTests.swift
diff --git a/app-ios/CusttaTests/TabelaDoValeAPenaTests.swift b/app-ios/CusttaTests/Analise/TabelaDoValeAPenaTests.swift
similarity index 100%
rename from app-ios/CusttaTests/TabelaDoValeAPenaTests.swift
rename to app-ios/CusttaTests/Analise/TabelaDoValeAPenaTests.swift
diff --git a/app-ios/CusttaUITests/AnaliseUITests.swift b/app-ios/CusttaUITests/Analise/AnaliseUITests.swift
similarity index 100%
rename from app-ios/CusttaUITests/AnaliseUITests.swift
rename to app-ios/CusttaUITests/Analise/AnaliseUITests.swift
diff --git a/app-ios/CusttaUITests/Analise/AuditoriaDaAnaliseUITests.swift b/app-ios/CusttaUITests/Analise/AuditoriaDaAnaliseUITests.swift
new file mode 100644
index 0000000..b568bc5
--- /dev/null
+++ b/app-ios/CusttaUITests/Analise/AuditoriaDaAnaliseUITests.swift
@@ -0,0 +1,37 @@
+import XCTest
+
+/* As auditorias de acessibilidade das telas da análise (etapa 4, marco 2), no arquivo delas: o PR que só mexe na análise
+   as roda nos jobs da etapa 4, sem as auditorias do resto do app (spec, "Portões por superfície"). A máquina é a do
+   AuditoriaUITests (`AuditoriaDeTela`): o que fica de fora e por quê está lá. */
+final class AuditoriaDaAnaliseUITests: XCTestCase, AuditoriaDeTela {
+    /// O "Vale a pena?" na maior letra, com a conta inteira (a Casa Alphaville tem venda estimada): os campos um embaixo do
+    /// outro, o veredito, a faixa com a lista e a tabela com um valor por linha, rolada até o fim; também com "Aumentar
+    /// contraste" e com "Reduzir transparência".
+    @MainActor func testValeAPenaNoMaiorTamanho() throws {
+        for opcao in [[], ["-custta.aumentarContraste", "YES"], solido] {
+            let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena", argumentos: maiorLetra + parado + opcao)
+            XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
+            try auditar(app, tiposDeAuditoria)
+            for _ in 0..<6 {
+                rolar(app)
+                try auditar(app, tiposDeAuditoria)
+            }
+            app.terminate()
+        }
+    }
+
+    /// O "Vale a pena?" com superfícies sólidas, no escuro e no claro: os campos, o veredito no sólido, a faixa e a tabela.
+    @MainActor func testContrasteDoValeAPenaNosDoisTemas() throws {
+        for tema in temas {
+            let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
+                               argumentos: ["-custta.tema", tema] + solido + parado)
+            XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
+            try auditar(app, [.contrast])
+            for _ in 0..<2 {
+                rolar(app)
+                try auditar(app, [.contrast])
+            }
+            app.terminate()
+        }
+    }
+}
diff --git a/app-ios/CusttaUITests/ValeAPenaUITests.swift b/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift
similarity index 100%
rename from app-ios/CusttaUITests/ValeAPenaUITests.swift
rename to app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift
diff --git a/app-ios/CusttaUITests/AuditoriaUITests.swift b/app-ios/CusttaUITests/AuditoriaUITests.swift
index 6ee96b4..2768c8c 100644
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -12,24 +12,28 @@ import UIKit
    escuro sobre a pílula sólida do segmentado, e os mesmos textos com tinta de 6% ou de 50%). Aqui as cores
    são conferidas com "Reduzir transparência" (superfícies sólidas, sem o vidro na frente da aurora), também
    na maior letra; a leitura sobre o vidro de verdade é medida pixel a pixel pelo LeituraNoVidroUITests. */
-final class AuditoriaUITests: XCTestCase {
-    private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
-    private let tiposDeAuditoria: XCUIAccessibilityAuditType = [.dynamicType, .textClipped, .sufficientElementDescription, .hitRegion]
+/// A máquina das auditorias: os argumentos, o que fica de fora e a rolagem. Adota quem audita: o AuditoriaUITests e a
+/// auditoria de cada área que mora em arquivo próprio (a da análise, em CusttaUITests/Analise).
+protocol AuditoriaDeTela: XCTestCase {}
+
+extension AuditoriaDeTela {
+    var maiorLetra: [String] { ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
+    var tiposDeAuditoria: XCUIAccessibilityAuditType { [.dynamicType, .textClipped, .sufficientElementDescription, .hitRegion] }
     /// Fundo parado: aurora no quadro inicial, globo no ângulo de partida, logo pronto.
-    private let parado = ["-custta.reduzirMovimento", "YES"]
-    private let solido = ["-custta.reduzirTransparencia", "YES"]
-    private let temas = ["escuro", "claro"]
+    var parado: [String] { ["-custta.reduzirMovimento", "YES"] }
+    var solido: [String] { ["-custta.reduzirTransparencia", "YES"] }
+    var temas: [String] { ["escuro", "claro"] }
     /// A borda de rolagem (`BordaDeRolagem`): o véu do fundo cobre 140 pt no alto, depois de rolar, e embaixo,
     /// nas telas com a cápsula de abas (88% e 80% com "Reduzir transparência").
-    private let borda: CGFloat = 140
+    var borda: CGFloat { 140 }
 
     /// Deixa fora o que não cresce de propósito (dinâmico: a cápsula de abas e o texto do botão do Google,
     /// pelo rótulo, porque a auditoria rola a tela sozinha) e o conteúdo que passa por baixo da barra de
     /// navegação, da cápsula, do indicador de início ou da borda de rolagem (contraste: ele é auditado quando
     /// está à vista). Os rótulos da própria cápsula entram na auditoria de contraste. Com `corteSemElemento`, deixa passar
     /// também o "Text clipped" sem elemento, e só ele: o ponto cego do ViewThatFits na maior letra (T34), nas cenas com um à vista.
-    @MainActor private func auditar(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType,
-                                    corteSemElemento: Bool = false) throws {
+    @MainActor func auditar(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType,
+                            corteSemElemento: Bool = false) throws {
         // Com a folha aberta, a cápsula fica atrás dela: nada da folha é cortado pela regra da cápsula.
         let folha = app.elemento("tituloDaFolha").exists
         let abas = folha ? [] : (app.abasDaCapsula + [app.buttons["botaoMais"]]).filter(\.exists).map(\.frame)
@@ -115,12 +119,14 @@ final class AuditoriaUITests: XCTestCase {
     }
 
     /// Rola e espera a rolagem parar antes de auditar.
-    @MainActor private func rolar(_ app: XCUIApplication) {
+    @MainActor func rolar(_ app: XCUIApplication) {
         app.swipeUp()
         app.swipeUp()
         Thread.sleep(forTimeInterval: 1.5)
     }
+}
 
+final class AuditoriaUITests: XCTestCase, AuditoriaDeTela {
     @MainActor func testEntrarNoMaiorTamanho() throws {
         let app = abrirApp(argumentos: maiorLetra + parado)
         XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10))
@@ -258,37 +264,6 @@ final class AuditoriaUITests: XCTestCase {
         }
     }
 
-    /// O "Vale a pena?" na maior letra, com a conta inteira (a Casa Alphaville tem venda estimada): os campos um embaixo do
-    /// outro, o veredito, a faixa com a lista e a tabela com um valor por linha, rolada até o fim; também com "Aumentar
-    /// contraste" e com "Reduzir transparência".
-    @MainActor func testValeAPenaNoMaiorTamanho() throws {
-        for opcao in [[], ["-custta.aumentarContraste", "YES"], solido] {
-            let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena", argumentos: maiorLetra + parado + opcao)
-            XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
-            try auditar(app, tiposDeAuditoria)
-            for _ in 0..<6 {
-                rolar(app)
-                try auditar(app, tiposDeAuditoria)
-            }
-            app.terminate()
-        }
-    }
-
-    /// O "Vale a pena?" com superfícies sólidas, no escuro e no claro: os campos, o veredito no sólido, a faixa e a tabela.
-    @MainActor func testContrasteDoValeAPenaNosDoisTemas() throws {
-        for tema in temas {
-            let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
-                               argumentos: ["-custta.tema", tema] + solido + parado)
-            XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
-            try auditar(app, [.contrast])
-            for _ in 0..<2 {
-                rolar(app)
-                try auditar(app, [.contrast])
-            }
-            app.terminate()
-        }
-    }
-
     /// O falta pouco das contas Apple e Google, que nenhuma outra auditoria abre na maior letra.
     @MainActor func testFaltaPoucoNoMaiorTamanho() throws {
         for conta in ["apple-sem-perfil", "google-sem-perfil"] {
diff --git a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
index 11e7d30..5bfdb71 100644
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -13,47 +13,56 @@ import UIKit
    (decisão do Giovani em 09/10). Na CI (iOS 26) o laudo também é portão: o simulador de lá desenha o
    vidro diferente do Mac, mas igual de uma rodada para outra (as 47 cenas deram as mesmas notas em quatro
    rodadas do PR 3, todas acima de 4,5). */
-final class LeituraNoVidroUITests: XCTestCase {
+/// A máquina do laudo de leitura: as constantes, a cena e a medida. Adota quem mede: o LeituraNoVidroUITests e o laudo de
+/// cada área que mora em arquivo próprio (o da análise, em CusttaUITests/Analise).
+protocol LaudoDeLeitura: XCTestCase {}
+
+/// Uma cena do laudo: a tela, o estado e o que ela mede.
+struct CenaDoLaudo {
+    let nome: String
+    let conta: String
+    let argumentos: [String]
+    /// Elemento que diz que a tela abriu.
+    let espera: String
+    /// "tudo" mede o conteúdo (da cápsula de abas para baixo fica de fora); "navegacao" mede só os rótulos
+    /// da cápsula, com o conteúdo que passa por baixo dela intacto nos dois prints.
+    let escopo: String
+    /// Dados dos falsos e tela aberta pelo gancho (`obra:v1`, a obra do mockup na vitrine; `aba:ajustes`, a aba).
+    var dados = "exemplo"
+    var abrir: String? = nil
+    /// Folha aberta pelo gancho quando os dados chegam (`novaObra`, `venda:v2`; etapa 2, parte 3).
+    var folha: String? = nil
+    /// Tela rolada: o texto que passa por baixo da barra é borrado pela borda de rolagem e muda quando é apagado, a
+    /// mais de 5 pt das letras; os 140 pt de cima (a borda) ficam de fora, como os de baixo.
+    var rolada = false
+    /// Toques depois de a tela abrir e antes do print, os mesmos nos dois (a busca, o mês, os Feitos, a linha arrastada;
+    /// etapa 3, PR 3): o estado a que se chega pelo toque, sem gancho de teste.
+    var toques: (@MainActor (XCUIApplication) -> Void)? = nil
+    /// O que a cena mede: identificadores (ou o texto, sem identificador) conferidos à vista antes de cada print, abaixo da
+    /// barra de status e acima da faixa de baixo (`conferirAssunto`). Toda cena com rolagem fixa tem o seu: o laudo passa
+    /// com a rolagem medindo outra coisa (com a obra em blocos da etapa 4, a "busca, nada achado" em 596 media os blocos
+    /// do alto, com o vazio sob a cápsula).
+    var assunto: [String] = []
+}
+
+extension LaudoDeLeitura {
+    typealias Cena = CenaDoLaudo
+
     /// Fundo parado no pior momento: Reduzir movimento (globo em 1,2 e logo pronto) e a aurora no pior ponto
     /// da deriva inteira, que também cobre o quadro em que ela para com Reduzir movimento.
-    private let piorMomento = ["-custta.reduzirMovimento", "YES", "-custta.auroraPiorCaso", "YES", "-custta.semSimbolos", "YES"]
-    private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
-    private let temas = ["escuro", "claro"]
-    private static let portao = 4.5
+    var piorMomento: [String] { ["-custta.reduzirMovimento", "YES", "-custta.auroraPiorCaso", "YES", "-custta.semSimbolos", "YES"] }
+    var maiorLetra: [String] { ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
+    var temas: [String] { ["escuro", "claro"] }
+    static var portao: Double { 4.5 }
     /// O mínimo das marcas de gráfico (spec da etapa 4, "Laudo das marcas"), o do mockup.
-    private static let portaoDasMarcas = 3.0
+    static var portaoDasMarcas: Double { 3.0 }
     /// A barra de status fica de fora: a hora muda entre os dois prints.
-    private static let barraDeStatus: CGFloat = 70
+    static var barraDeStatus: CGFloat { 70 }
     /// Rolagens da lista sob a cápsula de abas: no Mac, de 10 em 10 pt até 60 e o fim (260); na CI
     /// (`CUSTTA_VARREDURA=curta`), 0, 20, 40 e 260, para o job caber em 45 min.
-    private static let rolagens = ProcessInfo.processInfo.environment["CUSTTA_VARREDURA"] == "curta"
-        ? [0, 20, 40, 260] : Array(stride(from: 0, through: 60, by: 10)) + [260]
-
-    private struct Cena {
-        let nome: String
-        let conta: String
-        let argumentos: [String]
-        /// Elemento que diz que a tela abriu.
-        let espera: String
-        /// "tudo" mede o conteúdo (da cápsula de abas para baixo fica de fora); "navegacao" mede só os rótulos
-        /// da cápsula, com o conteúdo que passa por baixo dela intacto nos dois prints.
-        let escopo: String
-        /// Dados dos falsos e tela aberta pelo gancho (`obra:v1`, a obra do mockup na vitrine; `aba:ajustes`, a aba).
-        var dados = "exemplo"
-        var abrir: String? = nil
-        /// Folha aberta pelo gancho quando os dados chegam (`novaObra`, `venda:v2`; etapa 2, parte 3).
-        var folha: String? = nil
-        /// Tela rolada: o texto que passa por baixo da barra é borrado pela borda de rolagem e muda quando é apagado, a
-        /// mais de 5 pt das letras; os 140 pt de cima (a borda) ficam de fora, como os de baixo.
-        var rolada = false
-        /// Toques depois de a tela abrir e antes do print, os mesmos nos dois (a busca, o mês, os Feitos, a linha arrastada;
-        /// etapa 3, PR 3): o estado a que se chega pelo toque, sem gancho de teste.
-        var toques: (@MainActor (XCUIApplication) -> Void)? = nil
-        /// O que a cena mede: identificadores (ou o texto, sem identificador) conferidos à vista antes de cada print, abaixo da
-        /// barra de status e acima da faixa de baixo (`conferirAssunto`). Toda cena com rolagem fixa tem o seu: o laudo passa
-        /// com a rolagem medindo outra coisa (com a obra em blocos da etapa 4, a "busca, nada achado" em 596 media os blocos
-        /// do alto, com o vazio sob a cápsula).
-        var assunto: [String] = []
+    static var rolagens: [Int] {
+        ProcessInfo.processInfo.environment["CUSTTA_VARREDURA"] == "curta"
+            ? [0, 20, 40, 260] : Array(stride(from: 0, through: 60, by: 10)) + [260]
     }
 
     /// A tabela de exceções do laudo: a cena e a figura que sai dos dois prints dela (`foraDoLaudo(_:)` no app, com
@@ -65,9 +74,9 @@ final class LeituraNoVidroUITests: XCTestCase {
     ///   mudam até 204: viram "letra" com o próprio triângulo de fundo (1,33:1). Nenhuma folga inteira casa (a melhor é
     ///   0 px). Só o ícone sai: a frase do aviso, na mesma cor (alertaNoVidro), segue medida nesta cena, nas outras e no
     ///   18 Pro (decisão do Prumo, 21/10).
-    private static let excecoes = ["obra com orçamento por tópico, na maior letra": "iconeDoAviso"]
+    static var excecoes: [String: String] { ["obra com orçamento por tópico, na maior letra": "iconeDoAviso"] }
 
-    @MainActor private func fotografar(_ cena: Cena, textoApagado: Bool) -> (XCUIScreenshot, [CGRect], CGFloat, [CGRect], [CGRect]) {
+    @MainActor func fotografar(_ cena: Cena, textoApagado: Bool) -> (XCUIScreenshot, [CGRect], CGFloat, [CGRect], [CGRect]) {
         let excecao = Self.excecoes[cena.nome].map { ["-custta.foraDoLaudo", $0] } ?? []
         let app = abrirApp(conta: cena.conta, dados: cena.dados, abrir: cena.abrir, folha: cena.folha,
                            argumentos: cena.argumentos + excecao + (textoApagado ? ["-custta.textoApagado", cena.escopo] : []))
@@ -92,7 +101,7 @@ final class LeituraNoVidroUITests: XCTestCase {
     /// O assunto da cena à vista antes do print: abaixo da barra de status e acima da faixa de baixo, a borda de 140 pt ou a
     /// cápsula de abas, o que vier antes (a mesma de `conferir`). Pelo identificador ou, sem ele, pelo texto (a frase do aviso
     /// dos tópicos, dentro do bloco do orçamento).
-    @MainActor private func conferirAssunto(_ cena: Cena, _ app: XCUIApplication) {
+    @MainActor func conferirAssunto(_ cena: Cena, _ app: XCUIApplication) {
         let altura = app.frame.height
         let capsula = app.buttons["aba-obras"]
         let fim = min(capsula.exists ? capsula.frame.minY - 10 : altura, altura - 140)
@@ -112,7 +121,7 @@ final class LeituraNoVidroUITests: XCTestCase {
     /// medido. Sai a caixa do campo vazio e, embaixo dela, as linhas do exemplo, medidas como na AuditoriaUITests (letra
     /// do corpo na largura do campo). Com texto digitado o exemplo some e nada sai; o texto do campo, como o prompt, o
     /// UIKit desenha e o laudo não vê (mutação no terciário passa): o Texto sobre a LinhaDaFolha fica no PARES_SOLIDOS.
-    @MainActor private func exemploDaDescricao(_ app: XCUIApplication, _ cena: Cena) -> [CGRect] {
+    @MainActor func exemploDaDescricao(_ app: XCUIApplication, _ cena: Cena) -> [CGRect] {
         let campo = app.textFields["descricao"]
         guard campo.exists, let exemplo = campo.placeholderValue else { return [] }
         let valor = campo.value as? String ?? ""
@@ -129,7 +138,7 @@ final class LeituraNoVidroUITests: XCTestCase {
     }
 
     /// Mede as cenas e cobra o portão de cada uma.
-    @MainActor private func cobrar(_ cenas: [Cena]) {
+    @MainActor func cobrar(_ cenas: [Cena]) {
         for cena in cenas {
             let falhas: [String]
             do { falhas = try conferir(cena) } catch {
@@ -141,7 +150,7 @@ final class LeituraNoVidroUITests: XCTestCase {
     }
 
     /// Mede uma cena, anexa o print anotado e a tabela e devolve as palavras abaixo do portão.
-    @MainActor private func conferir(_ cena: Cena) throws -> [String] {
+    @MainActor func conferir(_ cena: Cena) throws -> [String] {
         let (normal, abas, largura, informativo, voltar) = fotografar(cena, textoApagado: false)
         let (semTexto, _, _, _, _) = fotografar(cena, textoApagado: true)
         let imagem = normal.image.cgImage!
@@ -176,8 +185,8 @@ final class LeituraNoVidroUITests: XCTestCase {
 
     /// As marcas saem com o prefixo "marcas" e o portão delas: o comparador do laudo (`scripts/compara-laudo.mjs`) lê só as
     /// tabelas "leitura — …", com o portão de 4,5.
-    @MainActor private func anexar(_ nome: String, _ imagem: UIImage, _ palavras: [LaudoDeContraste.Palavra], _ escala: CGFloat,
-                                   portao: Double = LeituraNoVidroUITests.portao, tipo: String = "leitura") {
+    @MainActor func anexar(_ nome: String, _ imagem: UIImage, _ palavras: [LaudoDeContraste.Palavra], _ escala: CGFloat,
+                                   portao: Double = Self.portao, tipo: String = "leitura") {
         let formato = UIGraphicsImageRendererFormat()
         formato.scale = 1
         let tamanho = CGSize(width: imagem.size.width * imagem.scale, height: imagem.size.height * imagem.scale)
@@ -209,7 +218,9 @@ final class LeituraNoVidroUITests: XCTestCase {
         tabela.lifetime = .keepAlways
         add(tabela)
     }
+}
 
+final class LeituraNoVidroUITests: XCTestCase, LaudoDeLeitura {
     /// Entrar (Fosco), Obras (Transparente, com o aviso de e-mail) e os rótulos da cápsula de abas sobre a
     /// lista rolada, no escuro e no claro.
     @MainActor func testLeituraNosDoisTemas() {
```

### Tarefa 12: espera do menu da obra depois das teclas do "Vale a pena?"

**Commit das fatias:** `26c33db` · **Mensagem:** `test: espera do menu da obra depois das teclas do "Vale a pena?"`

Dois testes das teclas do preço escolhem a obra no menu logo depois do OK. O testAPrimeiraTeclaSubstituiOValorEAContaAcompanha
caía no iOS 26.5 do Mac por dois motivos do teste, que a Lupa reproduziu, com 1 queda em 25 e 2 em 40. O toque no menu saía
150 ms depois de a cápsula voltar, com a rolagem ainda assentando, e se perdia: o item da obra não aparecia em 5 s. E a obra
era lida logo depois do toque no item, antes de a escolha chegar, e ainda vinha a de antes.

Os dois testes passam por um ajudante que espera as teclas saírem da árvore, toca de novo no menu se o item não aparecer, como
o digitarComFoco, e espera a obra trocar antes de seguir. A leitura do preço que vem depois passa a acontecer com a escolha já
feita.

**Prova:** Patch do Forja. Antes dele, 1 queda em 16 no iOS 26.5 do Mac; a Lupa mediu 1 em 25 e 2 em 40.

**Arquivos:**

```
 .../CusttaUITests/Analise/ValeAPenaUITests.swift   | 30 +++++++++++++++-------
 1 file changed, 21 insertions(+), 9 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift b/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift
index f288cd6..88d2fcd 100644
--- a/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift
+++ b/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift
@@ -167,10 +167,7 @@ final class ValeAPenaUITests: XCTestCase {
         XCTAssertTrue(app.buttons["aba-valeAPena"].waitForExistence(timeout: 5), "o OK devolve a cápsula")
         XCTAssertFalse(ok.exists)
         XCTAssertEqual(preco.value as? String, "R$\u{00A0}1.450.000,00")
-        app.buttons["simObra"].tap()
-        let sobrado = app.buttons["Sobrado Granja Viana"]
-        XCTAssertTrue(sobrado.waitForExistence(timeout: 5))
-        sobrado.tap()
+        escolherObraDepoisDasTeclas(app, "Sobrado Granja Viana")
         XCTAssertEqual(preco.value as? String, "sem preço", "nada foi digitado: o preço ainda acompanha a venda estimada")
     }
 
@@ -196,14 +193,29 @@ final class ValeAPenaUITests: XCTestCase {
         ok.tap()
         XCTAssertTrue(app.buttons["aba-valeAPena"].waitForExistence(timeout: 5))
         XCTAssertEqual(preco.value as? String, "sem preço", "o campo apagado não volta para a venda estimada")
-        app.buttons["simObra"].tap()
-        let vilaNova = app.buttons["Sobrado Vila Nova"]
-        XCTAssertTrue(vilaNova.waitForExistence(timeout: 5))
-        vilaNova.tap()
-        XCTAssertEqual(app.buttons["simObra"].value as? String, "Sobrado Vila Nova")
+        escolherObraDepoisDasTeclas(app, "Sobrado Vila Nova")
         XCTAssertEqual(preco.value as? String, "sem preço", "nem trocando para uma obra com venda estimada")
     }
 
+    /// Escolhe a obra no menu logo depois do OK das teclas. O OK devolve a cápsula antes de a rolagem assentar, e o toque no
+    /// menu nesse meio se perdia; e a escolha chega depois de o menu fechar, então a leitura sem espera pegava a obra de antes
+    /// (Lupa, no iOS 26.5: 1 queda em 25 e 2 em 40). Espera as teclas saírem, toca de novo se o item não aparecer, como o
+    /// `digitarComFoco`, e espera a obra trocar.
+    @MainActor private func escolherObraDepoisDasTeclas(_ app: XCUIApplication, _ nome: String) {
+        XCTAssertTrue(app.elemento("teclasDoPreco").waitForNonExistence(timeout: 5), "as teclas fecharam")
+        let obra = app.buttons["simObra"], item = app.buttons[nome]
+        for _ in 0..<3 {
+            guard !item.exists else { break }
+            obra.tap()
+            _ = item.waitForExistence(timeout: 3)
+        }
+        XCTAssertTrue(item.exists, "\(nome) no menu da obra")
+        item.tap()
+        let trocou = NSPredicate { _, _ in obra.value as? String == nome }
+        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: trocou, object: nil)], timeout: 5), .completed,
+                       "a obra escolhida: \(String(describing: obra.value))")
+    }
+
     /// Na letra máxima, a linha do preço nasce mais embaixo, e as teclas são mais altas que a cápsula: ao abrir, a linha
     /// sobe o que falta para ficar inteira acima delas, e abaixo da barra de cima.
     @MainActor func testNaLetraMaximaALinhaDoPrecoFicaAcimaDasTeclas() {
```

### Tarefa 13: última linha do "Vale a pena?" acima da cápsula de abas

**Commit das fatias:** `b94d4a9` · **Mensagem:** `fix: última linha do "Vale a pena?" acima da cápsula de abas`

A tela terminava com 24 pt de folga embaixo, como Obras e Ajustes, e a última linha da tabela parava atrás da cápsula de abas: a barra de baixo do PrincipalView não entra na área segura da rolagem (medido: 34 pt de recuo embaixo, só o do aparelho). Passa a 98, a folga das telas que rolam por baixo da cápsula (a obra, o Orçamento e os Afazeres).

**Prova:** Visto no print da cena "tabela" do laudo, no iOS 27: com a folga de 24 a última linha ficava atrás da cápsula; com 98, fica à vista. Sem teste que reprove a folga de 24 sozinha.

**Arquivos:**

```
 app-ios/Custta/Analise/ValeAPenaView.swift | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Analise/ValeAPenaView.swift b/app-ios/Custta/Analise/ValeAPenaView.swift
index 0a4b445..67b412c 100644
--- a/app-ios/Custta/Analise/ValeAPenaView.swift
+++ b/app-ios/Custta/Analise/ValeAPenaView.swift
@@ -38,7 +38,9 @@ struct ValeAPenaView: View {
                         }
                     }
                     .padding(.horizontal, Grade.externa)
-                    .padding(.bottom, 24)
+                    // A folga das telas que rolam por baixo da cápsula (62 de altura, 22 da borda e 14 de respiro): a barra de
+                    // baixo do PrincipalView não entra na área segura da rolagem, e com 24 a última linha da tabela parava atrás dela.
+                    .padding(.bottom, 98)
                 }
                 .scrollIndicators(.hidden)
                 // Quando as teclas entram, a área de baixo da rolagem cresce: a linha do preço sobe só o que falta para ficar à
```

### Tarefa 14: laudo do "Vale a pena?", auditoria com as teclas e os estados que faltavam

**Commit das fatias:** `76aaac9` · **Mensagem:** `test: laudo do "Vale a pena?", auditoria com as teclas e os estados que faltavam`

O laudo de leitura da aba entra no arquivo da análise (LeituraDaAnaliseUITests): os campos e o veredito nos dois temas e nos dois vidros, a faixa e a tabela roladas, o veredito âmbar e as teclas do preço abertas; os estados do site (sem obra, sem preço, obra com menos de 1 mês); e a maior letra. As duas auditorias da aba passam a abrir as teclas do preço antes de rolar.

Três testes de tela que o spec pede e faltavam: o + para em 120 meses, a obra com menos de 1 mês não tem taxa, e os alvos de 44 pt com os títulos que quebram na maior letra. Este último fecha o que a auditoria do Xcode não vê nesta tela: na prova da Lupa com defeito plantado, ela não pegou o + com 28 pt nem o título preso numa linha.

Para os testes chegarem lá, dois ganchos de Debug (a rolagem fixa na tela da aba e -custta.simMeses) e os identificadores dos dois títulos. A rolagem fixa do teste passa a ir de novo até a pedida quando o conteúdo cresce: nesta aba a conta só aparece quando os dados chegam, e a rolagem tinha parado no fim do conteúdo curto.

O laudo das marcas da faixa fica de fora: o tracejado do empate e a barra da venda medem 1,90:1 no escuro e 2,96:1 no claro sobre o contorno e as listras da zona hachurada, abaixo dos 3:1. É decisão de desenho, do Giovani com o Croqui.

**Prova:** iOS 27: 19 de 19 (laudo da aba, ações da fase, suíte da aba). iOS 26.5, a ponta inteira: 22 de 23; a queda foi o toque no OK das teclas em `testContrasteDoValeAPenaNosDoisTemas` (Pendências, 2). **Sem mutação** no teste dos alvos de 44 pt.

**Arquivos:**

```
 app-ios/Custta/Analise/ValeAPenaView.swift         |   6 ++
 app-ios/Custta/Identidade/Componentes.swift        |   5 +
 app-ios/Custta/Telas/PrincipalView.swift           |  12 ++-
 .../Analise/AuditoriaDaAnaliseUITests.swift        |  20 +++-
 .../Analise/LeituraDaAnaliseUITests.swift          | 103 +++++++++++++++++++++
 .../CusttaUITests/Analise/ValeAPenaUITests.swift   |  62 +++++++++++++
 app-ios/CusttaUITests/AuditoriaUITests.swift       |   5 +-
 7 files changed, 208 insertions(+), 5 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Analise/ValeAPenaView.swift b/app-ios/Custta/Analise/ValeAPenaView.swift
index 67b412c..4036df1 100644
--- a/app-ios/Custta/Analise/ValeAPenaView.swift
+++ b/app-ios/Custta/Analise/ValeAPenaView.swift
@@ -43,6 +43,10 @@ struct ValeAPenaView: View {
                     .padding(.bottom, 98)
                 }
                 .scrollIndicators(.hidden)
+                #if DEBUG
+                // O laudo de leitura mede o veredito, a faixa e a tabela com a tela parada numa rolagem dada.
+                .rolagemFixaSoComOArgumento()
+                #endif
                 // Quando as teclas entram, a área de baixo da rolagem cresce: a linha do preço sobe só o que falta para ficar à
                 // vista acima delas (na letra máxima ela nasce mais embaixo). O gatilho é a medida, e não um tempo.
                 .onScrollGeometryChange(for: CGFloat.self) { $0.contentInsets.bottom } action: { antes, depois in
@@ -230,6 +234,7 @@ struct FaixaDoValeAPena: View {
                     .fixedSize(horizontal: false, vertical: true)
                     .frame(maxWidth: grande ? nil : .infinity, alignment: .leading)
                     .accessibilityAddTraits(.isHeader)
+                    .accessibilityIdentifier("simTituloDaFaixa")
                 EtiquetaDoIndicador(texto: faixa.pilula, cor: faixa.acima ? .positivo : .alerta)
                     .accessibilityIdentifier("simPilula")
             }
@@ -381,6 +386,7 @@ struct TabelaDoValeAPena: View {
                 .foregroundStyle(paleta.cor(.texto))
                 .fixedSize(horizontal: false, vertical: true)
                 .accessibilityAddTraits(.isHeader)
+                .accessibilityIdentifier("simTituloDaTabela")
                 .padding(.bottom, 8)
             if !grande {
                 HStack(spacing: 12) {
diff --git a/app-ios/Custta/Identidade/Componentes.swift b/app-ios/Custta/Identidade/Componentes.swift
index 1f97cf9..0dbd05c 100644
--- a/app-ios/Custta/Identidade/Componentes.swift
+++ b/app-ios/Custta/Identidade/Componentes.swift
@@ -412,6 +412,11 @@ struct RolagemFixaDoTeste: ViewModifier {
             .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, y in
                 if segurando, abs(y - rolagemFixa) > 0.5 { posicao.scrollTo(y: rolagemFixa) }
             }
+            // A tela que cresce depois de a rolagem ser pedida (o "Vale a pena?", quando os dados chegam e a conta aparece): a
+            // rolagem tinha parado no fim do conteúdo curto, e o conteúdo novo não a mexe. Vai de novo até a pedida.
+            .onScrollGeometryChange(for: CGFloat.self) { $0.contentSize.height } action: { _, _ in
+                if segurando { posicao.scrollTo(y: rolagemFixa) }
+            }
             .onScrollPhaseChange { _, fase in if fase == .interacting { segurando = false } }
     }
 }
diff --git a/app-ios/Custta/Telas/PrincipalView.swift b/app-ios/Custta/Telas/PrincipalView.swift
index 0d67f78..9de8787 100644
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -12,7 +12,7 @@ struct PrincipalView: View {
     @State private var caminhoDeObras = PrincipalView.caminhoInicial
     /// Os campos do "Vale a pena?": moram aqui, e não na tela da aba, que sai da árvore quando a pessoa troca de aba. Assim
     /// duram enquanto o app está aberto (spec da etapa 4, "Dados e estado").
-    @State private var simulador = CamposDoSimulador()
+    @State private var simulador = PrincipalView.simuladorInicial
     /// As teclas do preço do "Vale a pena?" estão abertas, e a cápsula de abas sai (mockup da etapa 4, `sim-teclado`).
     @State private var teclasDoPreco = false
     @State private var folhas = Folhas()
@@ -192,6 +192,16 @@ extension PrincipalView {
     }
     #endif
 
+    /// Os campos com que o "Vale a pena?" abre: os do núcleo, com os meses em 0. Em Debug, `-custta.simMeses <n>` já abre
+    /// com os meses andados, para o teste de tela chegar ao limite de 120 sem 120 toques.
+    static var simuladorInicial: CamposDoSimulador {
+        var campos = CamposDoSimulador()
+        #if DEBUG
+        campos.andarMeses(UserDefaults.standard.integer(forKey: "custta.simMeses"))
+        #endif
+        return campos
+    }
+
     /// A aba em que o app abre: Obras. Em Debug, `CUSTTA_ABRIR=aba:<nome>` abre noutra (`aba:ajustes`), para os testes de
     /// tela, o laudo de leitura e a conferência visual chegarem a uma aba sem tocar na cápsula.
     static var abaInicial: Aba {
diff --git a/app-ios/CusttaUITests/Analise/AuditoriaDaAnaliseUITests.swift b/app-ios/CusttaUITests/Analise/AuditoriaDaAnaliseUITests.swift
index b568bc5..9f94819 100644
--- a/app-ios/CusttaUITests/Analise/AuditoriaDaAnaliseUITests.swift
+++ b/app-ios/CusttaUITests/Analise/AuditoriaDaAnaliseUITests.swift
@@ -6,12 +6,13 @@ import XCTest
 final class AuditoriaDaAnaliseUITests: XCTestCase, AuditoriaDeTela {
     /// O "Vale a pena?" na maior letra, com a conta inteira (a Casa Alphaville tem venda estimada): os campos um embaixo do
     /// outro, o veredito, a faixa com a lista e a tabela com um valor por linha, rolada até o fim; também com "Aumentar
-    /// contraste" e com "Reduzir transparência".
+    /// contraste" e com "Reduzir transparência". Antes de rolar, as teclas do preço abertas no lugar da cápsula.
     @MainActor func testValeAPenaNoMaiorTamanho() throws {
         for opcao in [[], ["-custta.aumentarContraste", "YES"], solido] {
             let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena", argumentos: maiorLetra + parado + opcao)
             XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
             try auditar(app, tiposDeAuditoria)
+            try auditarComAsTeclasDoPreco(app, tiposDeAuditoria)
             for _ in 0..<6 {
                 rolar(app)
                 try auditar(app, tiposDeAuditoria)
@@ -20,13 +21,15 @@ final class AuditoriaDaAnaliseUITests: XCTestCase, AuditoriaDeTela {
         }
     }
 
-    /// O "Vale a pena?" com superfícies sólidas, no escuro e no claro: os campos, o veredito no sólido, a faixa e a tabela.
+    /// O "Vale a pena?" com superfícies sólidas, no escuro e no claro: os campos, as teclas do preço, o veredito no sólido,
+    /// a faixa e a tabela.
     @MainActor func testContrasteDoValeAPenaNosDoisTemas() throws {
         for tema in temas {
             let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
                                argumentos: ["-custta.tema", tema] + solido + parado)
             XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
             try auditar(app, [.contrast])
+            try auditarComAsTeclasDoPreco(app, [.contrast])
             for _ in 0..<2 {
                 rolar(app)
                 try auditar(app, [.contrast])
@@ -34,4 +37,17 @@ final class AuditoriaDaAnaliseUITests: XCTestCase, AuditoriaDeTela {
             app.terminate()
         }
     }
+
+    /// Abre as teclas do preço, audita com elas à vista e fecha pelo "OK". Na maior letra, a linha do preço fica abaixo da
+    /// dobra: a tela rola até ela antes do toque.
+    @MainActor private func auditarComAsTeclasDoPreco(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType) throws {
+        let preco = app.elemento("simPreco"), ok = app.buttons["teclasDoPreco-ok"]
+        app.rolarAte(preco)
+        preco.tap()
+        XCTAssertTrue(ok.waitForExistence(timeout: 5), "as teclas do preço")
+        Thread.sleep(forTimeInterval: 1)                                   // a rolagem que põe a linha à vista assenta
+        try auditar(app, tipos)
+        ok.tap()
+        XCTAssertTrue(app.buttons["aba-valeAPena"].waitForExistence(timeout: 5), "o OK devolve a cápsula")
+    }
 }
diff --git a/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift b/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift
new file mode 100644
index 0000000..8be9109
--- /dev/null
+++ b/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift
@@ -0,0 +1,103 @@
+import XCTest
+
+/* O laudo de leitura das telas da análise (etapa 4, marco 2), no arquivo delas: o PR que só mexe na análise roda este
+   laudo no job laudo-etapa4, sem o laudo inteiro (spec, "Portões por superfície"). A máquina é a do LeituraNoVidroUITests
+   (`LaudoDeLeitura`): cada cena em dois prints, um normal e um com o texto apagado, com o fundo parado no pior caso, e o
+   portão de 4,5:1 no pior ponto de cada palavra. */
+final class LeituraDaAnaliseUITests: XCTestCase, LaudoDeLeitura {
+    /// Uma cena do "Vale a pena?", com os falsos da análise: a Casa Alphaville é a primeira obra elegível, com a venda
+    /// estimada em R$ 1.450.000,00 (vale a pena).
+    private func cena(_ nome: String, _ argumentos: [String], espera: String = "tituloValeAPena", dados: String = "analise",
+                      rolagem: Int? = nil, assunto: [String] = [], toques: (@MainActor (XCUIApplication) -> Void)? = nil) -> Cena {
+        Cena(nome: "vale a pena, \(nome)", conta: "senha", argumentos: argumentos + (rolagem.map { ["-custta.rolagem", "\($0)"] } ?? []),
+             espera: espera, escopo: "tudo", dados: dados, abrir: "aba:valeAPena", rolada: rolagem != nil, toques: toques,
+             assunto: assunto)
+    }
+
+    /// Escolhe uma obra na lista "Obra" e espera a lista fechar.
+    @MainActor private static func escolherObra(_ app: XCUIApplication, _ nome: String) {
+        app.buttons["simObra"].tap()
+        let obra = app.buttons[nome].firstMatch
+        XCTAssertTrue(obra.waitForExistence(timeout: 10), "a obra \(nome) na lista")
+        obra.tap()
+        XCTAssertTrue(app.buttons["simObra"].waitForExistence(timeout: 10))
+    }
+
+    /// Abre as teclas do preço e digita: cada tecla pelo nome ("8", "00", "del").
+    @MainActor private static func digitarOPreco(_ app: XCUIApplication, _ teclas: [String] = [], ok: Bool = false) {
+        app.elemento("simPreco").tap()
+        XCTAssertTrue(app.buttons["teclasDoPreco-ok"].waitForExistence(timeout: 10), "as teclas do preço")
+        for tecla in teclas { app.buttons["tecla-\(tecla)"].tap() }
+        if ok {
+            app.buttons["teclasDoPreco-ok"].tap()
+            XCTAssertTrue(app.buttons["aba-valeAPena"].waitForExistence(timeout: 10), "o OK devolve a cápsula")
+        }
+    }
+
+    /// O "Vale a pena?" nos dois temas: os campos e o veredito verde no alto (no Transparente e no Fosco); a faixa com a
+    /// legenda e a tabela, roladas; o veredito âmbar ("Rende menos que o banco", a R$ 800.000,00, pelas teclas); e as teclas
+    /// do preço abertas no lugar da cápsula, com o valor à vista.
+    @MainActor func testLeituraDoValeAPena() {
+        var cenas: [Cena] = []
+        for tema in temas {
+            let combo = ["-custta.tema", tema] + piorMomento
+            cenas += [
+                cena("\(tema), Transparente", combo, assunto: ["simObra", "simPreco", "simNota"]),
+                cena("\(tema), Fosco", combo + ["-custta.vidro", "fosco"], assunto: ["simObra", "simPreco", "simNota"]),
+                cena("veredito e faixa, \(tema)", combo, espera: "simFaixa", rolagem: Self.rolagemDaFaixa,
+                     assunto: ["simVeredito", "simFaixa", "simFaixa-venda"]),
+                cena("tabela, \(tema)", combo, espera: "simTabela-6", rolagem: Self.rolagemDaTabela,
+                     assunto: ["simTabela-0", "simTabela-6"]),
+                cena("rende menos que o banco, \(tema)", combo, rolagem: Self.rolagemDoVeredito, assunto: ["simVeredito"]) { app in
+                    Self.digitarOPreco(app, ["8", "0", "00", "00", "00"], ok: true)
+                },
+                cena("teclas do preço, \(tema)", combo, assunto: ["simPreco", "teclasDoPreco-titulo", "teclasDoPreco-ok"]) { app in
+                    Self.digitarOPreco(app)
+                },
+            ]
+        }
+        cobrar(cenas)
+    }
+
+    /// Os estados do site, no escuro: sem obra elegível, sem preço (o Sobrado Granja Viana não tem venda estimada) e a obra
+    /// com menos de 1 mês (o Sobrado Vila Nova: o veredito sem taxa, com a frase do site); e o alto com "Aumentar contraste".
+    @MainActor func testLeituraDosEstadosDoValeAPena() {
+        let escuro = ["-custta.tema", "escuro"] + piorMomento
+        cobrar([
+            cena("sem obra", escuro, dados: "vazio", assunto: ["simSemObra", "simNota"]),
+            cena("sem preço", escuro, assunto: ["simSemPreco"]) { app in Self.escolherObra(app, "Sobrado Granja Viana") },
+            cena("obra com menos de 1 mês", escuro, rolagem: Self.rolagemDoVeredito, assunto: ["simVeredito"]) { app in
+                Self.escolherObra(app, "Sobrado Vila Nova")
+            },
+            cena("com Aumentar contraste", escuro + ["-custta.aumentarContraste", "YES"], assunto: ["simObra", "simPreco", "simNota"]),
+        ])
+    }
+
+    /// Na maior letra, no escuro: os campos um embaixo do outro, o veredito, a faixa com a legenda, a tabela com um valor por
+    /// linha (o começo e o lucro, em verde) e as teclas do preço abertas, com a linha do preço acima delas.
+    @MainActor func testLeituraDoValeAPenaNaMaiorLetra() {
+        let grande = ["-custta.tema", "escuro"] + piorMomento + maiorLetra
+        cobrar([
+            cena("na maior letra", grande, assunto: ["simObra"]),
+            cena("na maior letra, veredito", grande, espera: "simVeredito", rolagem: Self.rolagemDoVereditoNaMaiorLetra, assunto: ["simVeredito"]),
+            cena("na maior letra, faixa", grande, espera: "simFaixa", rolagem: Self.rolagemDaFaixaNaMaiorLetra,
+                 assunto: ["simFaixa", "simFaixa-custo"]),
+            cena("na maior letra, tabela", grande, espera: "simTabela-0", rolagem: Self.rolagemDaTabelaNaMaiorLetra, assunto: ["simTabela-0"]),
+            cena("na maior letra, lucro", grande, espera: "simTabela-2", rolagem: Self.rolagemDoLucroNaMaiorLetra, assunto: ["simTabela-2"]),
+            cena("na maior letra, teclas do preço", grande, espera: "simPreco", rolagem: Self.rolagemDoPrecoNaMaiorLetra,
+                 assunto: ["simPreco", "teclasDoPreco-ok"]) { app in Self.digitarOPreco(app) },
+        ])
+    }
+
+    // As rolagens das cenas, em pontos, medidas no 18 Pro (402 × 874): cada uma deixa o assunto inteiro entre a borda de cima
+    // (140 pt) e a de baixo (734), e o `assunto` de cada cena confere isso antes do print, em qualquer aparelho. A do
+    // veredito deixa a obra e o preço à vista, para o toque; a da tabela é quase o fim da tela.
+    private static let rolagemDoVeredito = 50
+    private static let rolagemDaFaixa = 300
+    private static let rolagemDaTabela = 605
+    private static let rolagemDoVereditoNaMaiorLetra = 1440
+    private static let rolagemDaFaixaNaMaiorLetra = 2080
+    private static let rolagemDaTabelaNaMaiorLetra = 2760
+    private static let rolagemDoLucroNaMaiorLetra = 3340
+    private static let rolagemDoPrecoNaMaiorLetra = 250
+}
diff --git a/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift b/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift
index 88d2fcd..022eb00 100644
--- a/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift
+++ b/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift
@@ -149,6 +149,39 @@ final class ValeAPenaUITests: XCTestCase {
         XCTAssertFalse(app.elemento("simTabela-7").exists, "sete linhas")
     }
 
+    /// O + para em 120 meses, como o campo do site. O app abre já em 119 pelo gancho de Debug (`-custta.simMeses`), para
+    /// o teste não dar 120 toques.
+    @MainActor func testOsMesesParamEm120() {
+        let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena", argumentos: ["-custta.simMeses", "119"])
+        let meses = app.elemento("simMeses"), mais = app.buttons["simMais"]
+        XCTAssertTrue(meses.waitForExistence(timeout: 10))
+        XCTAssertEqual(meses.value as? String, "119 meses")
+        XCTAssertTrue(mais.isEnabled)
+        mais.tap()
+        XCTAssertEqual(meses.value as? String, "120 meses")
+        XCTAssertFalse(mais.isEnabled, "em 120, o + não anda")
+        XCTAssertTrue(app.elemento("simVeredito").label.contains(", vendendo daqui a 120 meses, "), app.elemento("simVeredito").label)
+        app.buttons["simMenos"].tap()
+        XCTAssertEqual(meses.value as? String, "119 meses")
+        XCTAssertTrue(mais.isEnabled)
+    }
+
+    /// A obra com menos de 1 mês (o Sobrado Vila Nova começou neste mês): não há taxa ao mês, e o veredito sai pelo preço
+    /// contra o custo corrigido, com a frase do site (decisão 5 da parte 2: manter o site).
+    @MainActor func testObraComMenosDeUmMesNaoTemTaxa() {
+        let app = abrirAAba()
+        app.buttons["simObra"].tap()
+        let vilaNova = app.buttons["Sobrado Vila Nova"]
+        XCTAssertTrue(vilaNova.waitForExistence(timeout: 5))
+        vilaNova.tap()
+        XCTAssertEqual(app.buttons["simObra"].value as? String, "Sobrado Vila Nova")
+        XCTAssertEqual(app.elemento("simPreco").value as? String, "R$\u{00A0}1.100.000,00", "a venda estimada dela")
+        let veredito = app.elemento("simVeredito")
+        XCTAssertTrue(veredito.waitForExistence(timeout: 5))
+        XCTAssertTrue(veredito.label.hasPrefix("Vale a pena, sem taxa ao mês, "), veredito.label)
+        XCTAssertTrue(veredito.label.contains("menos de 1 mês"), veredito.label)
+    }
+
     /// As teclas do preço (decisão do Giovani de 24/11): o toque na linha do preço troca a cápsula de abas pelas teclas, com
     /// o valor à vista. O OK sem digitar devolve a cápsula e deixa tudo como estava: o preço segue acompanhando a venda
     /// estimada (o Sobrado não tem, e o campo fica vazio).
@@ -235,6 +268,35 @@ final class ValeAPenaUITests: XCTestCase {
         XCTAssertEqual(preco.value as? String, "R$\u{00A0}0,05")
     }
 
+    /// O que a auditoria do Xcode não vê nesta tela (prova da Lupa na fatia 8, com defeito plantado): o alvo pequeno e o
+    /// título preso numa linha. Os alvos se medem pelo quadro: 44 pt, e o − e o + com 72 na maior letra. Nela, os títulos
+    /// da faixa e da tabela não cabem numa linha de 53 pt e têm de quebrar: o quadro passa de duas linhas.
+    @MainActor func testOsAlvosTem44PontosEOsTitulosQuebramNaMaiorLetra() {
+        var app = abrirAAba()
+        for id in ["simObra", "simPreco", "simMenos", "simMais"] {
+            let alvo = app.elemento(id).frame
+            XCTAssertGreaterThanOrEqual(min(alvo.width, alvo.height), 44, "\(id): \(alvo)")
+        }
+        app.elemento("simPreco").tap()
+        let ok = app.buttons["teclasDoPreco-ok"]
+        XCTAssertTrue(ok.waitForExistence(timeout: 5))
+        XCTAssertGreaterThanOrEqual(min(ok.frame.width, ok.frame.height), 44, "o OK das teclas: \(ok.frame)")
+        app.terminate()
+        app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
+                       argumentos: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
+        XCTAssertTrue(app.elemento("tituloValeAPena").waitForExistence(timeout: 10))
+        for id in ["simMenos", "simMais"] {
+            let alvo = app.elemento(id).frame
+            XCTAssertGreaterThanOrEqual(min(alvo.width, alvo.height), 72, "\(id) na maior letra: \(alvo)")
+        }
+        for id in ["simTituloDaFaixa", "simTituloDaTabela"] {
+            let titulo = app.elemento(id)
+            XCTAssertTrue(titulo.exists, id)
+            XCTAssertGreaterThanOrEqual(titulo.frame.height, 106, "\(id) em duas linhas ou mais na maior letra: \(titulo.frame)")
+            XCTAssertLessThanOrEqual(titulo.frame.width, app.frame.width - 68, "\(id) dentro das bordas de 34 pt: \(titulo.frame)")
+        }
+    }
+
     /// Sem nenhuma obra elegível, a linha da obra diz o que fazer, como no site, e não há lista para abrir.
     @MainActor func testSemObraElegivelALinhaDizOQueFazer() {
         let app = abrirApp(conta: "senha", dados: "vazio", abrir: "aba:valeAPena")
diff --git a/app-ios/CusttaUITests/AuditoriaUITests.swift b/app-ios/CusttaUITests/AuditoriaUITests.swift
index 2768c8c..044902c 100644
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -45,7 +45,8 @@ extension AuditoriaDeTela {
         let daBarra = barra.exists ? barra.descendants(matching: .any).allElementsBoundByIndex.map(\.frame) : []
         // Com as teclas encaixadas abertas (folha do orçamento), a lista termina onde a faixa delas começa: o que a lista tem
         // embaixo da faixa está escondido (montado pela lista preguiçosa, mas fora da vista). As teclas e a barra entram.
-        let teclas = app.elemento("tecladoEncaixado")
+        // As teclas do preço do "Vale a pena?" (etapa 4) cobrem a tela da aba do mesmo jeito.
+        let teclas = app.elemento(app.elemento("teclasDoPreco").exists ? "teclasDoPreco" : "tecladoEncaixado")
         let topoDasTeclas = teclas.exists ? teclas.frame.minY : .infinity
         let dasTeclas = teclas.exists ? teclas.descendants(matching: .any).allElementsBoundByIndex.map(\.frame) : []
         // E começa embaixo do cabeçalho fixo da folha (o segmentado e o total): o que a lista tem em cima dele foi rolado para
@@ -92,7 +93,7 @@ extension AuditoriaDeTela {
                 fora = elemento.label == "Continuar com o Google" || elemento.identifier == "tituloPequenoDaBarra"
                     || elemento.identifier.hasPrefix("tituloDaFolha") || elemento.identifier.hasPrefix("visorDoValor")
                     || elemento.identifier.hasPrefix("tecla-") || elemento.identifier.hasPrefix("apagar-")
-                    || elemento.identifier.hasPrefix("barraDasTeclas-")
+                    || elemento.identifier.hasPrefix("barraDasTeclas-") || elemento.identifier.hasPrefix("teclasDoPreco-")
                     || abas.contains { $0.contains(centro) }
             case .contrast:
                 if elemento.identifier.hasPrefix("aba-") { fora = false }   // o rótulo da própria cápsula
```

### Tarefa 15: auditoria das ações da fase na maior letra

**Commit das fatias:** `0d36402` · **Mensagem:** `test: auditoria das ações da fase na maior letra`

O "Desfazer venda" da obra vendida e o "Registrar venda" com o "Voltar pra construção" da pronta voltam a ser auditados na maior letra (achado 9 do marco 1): com a obra em blocos, mais alta, as rolagens da auditoria da parte 3 deixaram de alcançá-los. A auditoria roda numa obra de lista longa, a Casa Alphaville dos falsos da análise (a1, vendida, e a9, a cópia pronta que entra agora), numa rolagem fixa com as pílulas à vista: com conteúdo de sobra embaixo, a rolagem não passa do fim nos tamanhos menores que a auditoria experimenta.

Só contam os achados nas pílulas (acao-): o auditar ganha o soEm, que manda os outros para o log sem reprovar. Os blocos em volta têm a auditoria deles no alto e no fim da obra.

**Prova:** Verde no iOS 27 e no 26.5. **Sem mutação.**

**Arquivos:**

```
 app-ios/Custta/Falsos/VitrineDaAnalise.swift  |  2 ++
 app-ios/CusttaTests/DadosDeExemploTests.swift |  6 ++++-
 app-ios/CusttaUITests/AuditoriaUITests.swift  | 37 ++++++++++++++++++++++++++-
 3 files changed, 43 insertions(+), 2 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Falsos/VitrineDaAnalise.swift b/app-ios/Custta/Falsos/VitrineDaAnalise.swift
index f7246ca..2562043 100644
--- a/app-ios/Custta/Falsos/VitrineDaAnalise.swift
+++ b/app-ios/Custta/Falsos/VitrineDaAnalise.swift
@@ -16,6 +16,7 @@ import CusttaNucleo
    a6  Casa Granja Viana, com Outros (0,25%) e Extras (0,05%) abaixo de 1% (o piso e o "<1%")
    a7  Casa Morumbi, 30 meses de gastos, com 3 meses parados no meio (os últimos 24 meses)
    a8  a Casa Alphaville sem a venda estimada (o Relatório e o PDF sem venda)
+   a9  a Casa Alphaville pronta, com os 46 gastos (as ações da fase numa obra de lista longa, para a auditoria na maior letra)
    A Cotia, o Terreno Granja e o Sobrado Vila Nova começam no dia 1º deste mês, e os gastos deles caem neste mês: o dia do
    mockup, sem passar de hoje (no dia 1º, todos caem nele). */
 extension DadosDeExemplo {
@@ -98,6 +99,7 @@ extension DadosDeExemplo {
                 gasto(String(format: "k%02d", i + 1), g.1, g.2, g.3, meses(-g.0))
             }),
             copiaDaCasa("a8", ["valorEstimadoVenda": .nulo]),
+            copiaDaCasa("a9", ["fase": .texto("pronta")]),
         ])
         return .objeto(raiz)
     }
diff --git a/app-ios/CusttaTests/DadosDeExemploTests.swift b/app-ios/CusttaTests/DadosDeExemploTests.swift
index 7211084..81a2038 100644
--- a/app-ios/CusttaTests/DadosDeExemploTests.swift
+++ b/app-ios/CusttaTests/DadosDeExemploTests.swift
@@ -127,7 +127,7 @@ struct DadosDeExemploTests {
             return dataLocalISO(calendario.date(byAdding: .day, value: dia - 1, to: alvo)!, fuso: .current)
         }
         let estado = Estado.de(DadosDeExemplo.vitrineDaAnalise(hoje: hoje))
-        #expect(estado.obras.map(\.id) == ["v1", "v2", "v3", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"])
+        #expect(estado.obras.map(\.id) == ["v1", "v2", "v3", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9"])
         #expect(Array(estado.obras.prefix(3)) == Estado.de(DadosDeExemplo.vitrine(hoje: hoje)).obras, "a vitrine de sempre na frente")
         let obra = Dictionary(uniqueKeysWithValues: estado.obras.map { ($0.id, $0) })
         let ids = estado.obras.flatMap { $0.gastos.map(\.id) }
@@ -180,6 +180,10 @@ struct DadosDeExemploTests {
         #expect(semVenda.nome == "Casa Alphaville" && semVenda.fase == .construcao && semVenda.venda == nil)
         #expect(semVenda.valorEstimadoVenda == nil && casa.valorEstimadoVenda == 1_450_000)
         #expect(semVenda.gastos.map(\.valor) == casa.gastos.map(\.valor) && semVenda.gastos.map(\.data) == casa.gastos.map(\.data))
+        // a9: a Casa Alphaville pronta, com os mesmos gastos e a venda estimada.
+        let pronta = try #require(obra["a9"])
+        #expect(pronta.nome == "Casa Alphaville" && pronta.fase == .pronta && pronta.venda == nil && pronta.valorEstimadoVenda == 1_450_000)
+        #expect(pronta.gastos.map(\.valor) == casa.gastos.map(\.valor))
     }
 
     /// A conta de mês para trás dos falsos no fim do mês: o dia que o mês não tem fica no último dele, sem transbordar para 1º de
diff --git a/app-ios/CusttaUITests/AuditoriaUITests.swift b/app-ios/CusttaUITests/AuditoriaUITests.swift
index 044902c..ebde4db 100644
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -32,8 +32,10 @@ extension AuditoriaDeTela {
     /// navegação, da cápsula, do indicador de início ou da borda de rolagem (contraste: ele é auditado quando
     /// está à vista). Os rótulos da própria cápsula entram na auditoria de contraste. Com `corteSemElemento`, deixa passar
     /// também o "Text clipped" sem elemento, e só ele: o ponto cego do ViewThatFits na maior letra (T34), nas cenas com um à vista.
+    /// Com `soEm`, só contam os achados nos elementos cujo identificador começa por ele (as pílulas das ações da fase,
+    /// `acao-`): os outros, e os sem elemento, vão para o log e não reprovam.
     @MainActor func auditar(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType,
-                            corteSemElemento: Bool = false) throws {
+                            corteSemElemento: Bool = false, soEm: String? = nil) throws {
         // Com a folha aberta, a cápsula fica atrás dela: nada da folha é cortado pela regra da cápsula.
         let folha = app.elemento("tituloDaFolha").exists
         let abas = folha ? [] : (app.abasDaCapsula + [app.buttons["botaoMais"]]).filter(\.exists).map(\.frame)
@@ -64,6 +66,10 @@ extension AuditoriaDeTela {
         let totalMudaDeLugar = app.launchArguments.contains { $0.hasPrefix("UICTContentSizeCategoryAccessibility") }
             && !ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 0))
         try app.performAccessibilityAudit(for: tipos) { achado in
+            if let soEm, achado.element?.identifier.hasPrefix(soEm) != true {
+                Swift.print("auditoria | \(achado.compactDescription) | \(achado.element?.identifier ?? "sem elemento") | fora de \(soEm)")
+                return true
+            }
             guard let elemento = achado.element else {
                 // O arranjo que o ViewThatFits descartou dá "Text clipped" sem elemento, com a tela mostrando o outro inteiro.
                 // Qualquer outro achado sem elemento reprova, também nessas cenas.
@@ -168,6 +174,35 @@ final class AuditoriaUITests: XCTestCase, AuditoriaDeTela {
         try auditar(app, tiposDeAuditoria)
     }
 
+    /// As ações da fase na maior letra (achado 9 do marco 1): o "Desfazer venda" da obra vendida e o "Registrar venda" com o
+    /// "Voltar pra construção" da pronta, que a auditoria da parte 3 deixou de alcançar com a obra em blocos. Numa obra de
+    /// lista longa (a Casa Alphaville dos falsos da análise, com 46 gastos: a1, vendida, e a9, pronta), numa rolagem fixa com
+    /// as pílulas à vista: com conteúdo de sobra embaixo, a rolagem não passa do fim nos tamanhos menores que a auditoria
+    /// experimenta. Só contam os achados nas pílulas (`acao-`): os blocos em volta têm a auditoria deles no alto e no fim da
+    /// obra, e a troca de letra da auditoria dá neles achados que a tela parada não tem (problema conhecido, 03/11).
+    @MainActor func testAcoesDaFaseNoMaiorTamanho() throws {
+        for (obra, rolagem, acoes) in [("a1", Self.rolagemDasAcoesDaVendida, ["desfazerVenda"]),
+                                       ("a9", Self.rolagemDasAcoesDaPronta, ["registrarVenda", "voltarConstrucao"])] {
+            let app = abrirApp(conta: "senha", dados: "analise", abrir: "obra:\(obra)",
+                               argumentos: maiorLetra + parado + ["-custta.rolagem", "\(rolagem)"])
+            XCTAssertTrue(app.buttons["editarObra"].waitForExistence(timeout: 10))
+            Thread.sleep(forTimeInterval: 1.5)
+            // As pílulas inteiras à vista, abaixo da borda de cima e acima da cápsula: é nelas que a auditoria conta.
+            let capsula = app.buttons["aba-obras"].frame
+            for acao in acoes {
+                let pilula = app.buttons["acao-\(acao)"]
+                XCTAssertTrue(pilula.waitForExistence(timeout: 5) && pilula.frame.minY >= borda && pilula.frame.maxY <= capsula.minY,
+                              "\(obra): a pílula \(acao) à vista (\(pilula.frame); de \(borda) a \(capsula.minY))")
+            }
+            try auditar(app, tiposDeAuditoria, soEm: "acao-")
+            app.terminate()
+        }
+    }
+    // Medidas no 18 Pro, na maior letra: a 3050, o "Desfazer venda" fica de 245 a 394 pt; a 2500, o "Registrar venda" de 260 a
+    // 409 e o "Voltar pra construção" de 419 a 568.
+    private static let rolagemDasAcoesDaVendida = 3050
+    private static let rolagemDasAcoesDaPronta = 2500
+
     /// O bloco A pagar da obra na maior letra, inteiro: a etiqueta dos vencimentos e a nota "Parcelas e gastos futuros". Na
     /// obra, ele fica abaixo da dobra, e a auditoria olha só o topo; rolado, numa List ou numa ScrollView, a troca de letra
     /// da auditoria tira a rolagem do lugar (na vitrine, as rolagens de 900 a 3600 caíam todas na mesma tela). Aqui ele vem
```

### Tarefa 16: portões por superfície e jobs da etapa 4 no app nativo

**Commit das fatias:** `bfa8d97` · **Mensagem:** `ci: portões por superfície e jobs da etapa 4 no app nativo`

O job portoes, no Ubuntu, lê o diff do commit de merge do PR e escolhe o nível da rodada (scripts/portoes-app-ios.mjs, com teste): nucleo, quando o PR só mexe no CusttaNucleo, no site e nos vetores; telas, quando além disso só mexe em Custta/Analise e nos testes dela; tudo, em qualquer outro caso e em qualquer dúvida. É o filtro do spec da etapa 4. O arquivo que não dispara o workflow não muda o nível.

Cada job diz em que nível roda. Os nove de sempre rodam no tudo, com o if escrito pela negativa: só são pulados quando o filtro disse nucleo ou telas, e rodam se ele falhar. O unidade (a Release sem assinatura e os testes de unidade) toma o lugar do app nos níveis sem tela. Os três da etapa 4 (app-etapa4, laudo-etapa4 e auditoria-etapa4) rodam as suítes de CusttaUITests/Analise no telas e no tudo, e o app deixa de rodá-las. No botão, o nível é escolhido, e o padrão é tudo.

No tests/workflow.test.cjs, a proibição de needs e if nos jobs vira uma tabela com o nível de cada job e o if exato de cada nível: um job novo sem nível reprova, e toda suíte da pasta da análise tem de rodar num job da etapa 4.

**Prova:** `tests/portoes-app-ios.test.mjs`: 13 testes, 15 mutações pegas; `tests/workflow.test.cjs`: guarda nova, 10 mutações pegas; guardas Node 85 de 85. Não rodou na CI.

**Arquivos:**

```
 .github/workflows/app-ios.yml  | 267 ++++++++++++++++++++++++++++++++++++++++-
 package.json                   |   2 +-
 scripts/portoes-app-ios.mjs    |  80 ++++++++++++
 tests/portoes-app-ios.test.mjs | 155 ++++++++++++++++++++++++
 tests/workflow.test.cjs        |  74 ++++++++++--
 5 files changed, 562 insertions(+), 16 deletions(-)
```

**Mudança:**

```diff
diff --git a/.github/workflows/app-ios.yml b/.github/workflows/app-ios.yml
index b4e1975..aa9567e 100644
--- a/.github/workflows/app-ios.yml
+++ b/.github/workflows/app-ios.yml
@@ -14,7 +14,15 @@ name: app-ios
 # - laudo, laudo-parte3, laudo-etapa3 e auditoria: o laudo de leitura sobre o vidro e as auditorias de acessibilidade,
 #   cada um num simulador próprio, em paralelo com o app (o app com os dois passava dos 65 min com as telas da etapa 2,
 #   os dois num job só chegavam a 75 min com a folha do gasto, a parte 3 da etapa 2 levava o laudo ao teto, e as telas da
-#   etapa 3 moram no laudo-etapa3 desde a primeira).
+#   etapa 3 moram no laudo-etapa3 desde a primeira);
+# - app-etapa4, laudo-etapa4 e auditoria-etapa4: os testes de tela, o laudo e as auditorias das telas da análise (etapa 4),
+#   que moram nas pastas Analise dos testes.
+#
+# Portões por superfície (spec da etapa 4): o job portoes, no Ubuntu, lê o diff do PR e escolhe o nível
+# (scripts/portoes-app-ios.mjs). No nível tudo rodam todos os jobs, menos o unidade (o app já compila e roda os testes de
+# unidade); no telas, o nucleo, o unidade e os três da etapa 4; no nucleo, o nucleo e o unidade. Na dúvida, tudo: o job que
+# roda em todo nível tudo só é pulado quando o portoes disse nucleo ou telas, e roda se ele falhar. No botão, o nível é o
+# pedido (tudo, se ninguém escolher).
 # Os testes contra os emuladores do Firebase e a conferência cruzada com o site rodam no Mac
 # (npm run test:app-ios:emuladores e npm run test:app-ios:cruzado): precisam de Java, dos
 # emuladores e da assinatura de simulador para o keychain do Firebase Auth.
@@ -41,6 +49,14 @@ on:
         description: 'Resolver os pacotes Swift do app nativo de novo e mostrar o Package.resolved novo no resumo'
         type: boolean
         default: false
+      nivel:
+        description: 'Portões: tudo (todos os jobs), telas (núcleo, unidade e os jobs da etapa 4) ou nucleo (núcleo e unidade)'
+        type: choice
+        default: tudo
+        options:
+          - tudo
+          - telas
+          - nucleo
 
 permissions:
   contents: read
@@ -53,6 +69,33 @@ concurrency:
   cancel-in-progress: true
 
 jobs:
+  portoes:
+    runs-on: ubuntu-latest
+    timeout-minutes: 5
+    outputs:
+      nivel: ${{ steps.nivel.outputs.nivel }}
+    steps:
+      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
+        with:
+          # No PR, o checkout é o merge com a base, e a base é o 1º pai: com dois commits, o HEAD^1 existe para o diff.
+          fetch-depth: 2
+      - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
+        with:
+          node-version: 22
+
+      # O nível sai do diff do PR; no botão, do nível pedido. O script grava `nivel` na saída do passo e o porquê no resumo.
+      - name: Nível dos portões
+        id: nivel
+        env:
+          EVENTO: ${{ github.event_name }}
+          NIVEL: ${{ inputs.nivel }}
+        run: |
+          if [ "$EVENTO" = pull_request ]; then
+            node scripts/portoes-app-ios.mjs
+          else
+            node scripts/portoes-app-ios.mjs --nivel "$NIVEL"
+          fi
+
   nucleo:
     runs-on: macos-26
     timeout-minutes: 20
@@ -73,6 +116,8 @@ jobs:
 
   app:
     runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' && needs.portoes.outputs.nivel != 'telas' }}
     # Sem o laudo e as auditorias (jobs laudo, laudo-parte3, laudo-etapa3 e auditoria) e sem os testes de tela da etapa 3
     # (jobs app-etapa3, app-etapa3-b e app-etapa3-c): ~41 min de testes + ~11 de preparo ≈ 53 min numa VM normal. Numa
     # lenta, 67 min, com 48,9 de testes de tela (run 39799242127): o teto de 75 deixava 8 min de folga, e passa a 90. No
@@ -123,8 +168,9 @@ jobs:
             build
 
       # Testes com os serviços falsos (nada de rede): unidade e tela. Os que dependem dos emuladores pulam
-      # sozinhos aqui; o laudo de leitura e as auditorias de acessibilidade rodam nos jobs laudo e auditoria, e os
-      # testes de tela da etapa 3, no app-etapa3, no app-etapa3-b e no app-etapa3-c.
+      # sozinhos aqui; o laudo de leitura e as auditorias de acessibilidade rodam nos jobs laudo e auditoria, os
+      # testes de tela da etapa 3, no app-etapa3, no app-etapa3-b e no app-etapa3-c, e os das telas da análise, com o laudo e
+      # as auditorias delas, no app-etapa4, no laudo-etapa4 e no auditoria-etapa4.
       - name: Testes de unidade e de tela no simulador
         run: |
           set -o pipefail
@@ -146,6 +192,10 @@ jobs:
             -skip-testing:CusttaUITests/DetalheDoTopicoUITests \
             -skip-testing:CusttaUITests/BuscaUITests \
             -skip-testing:CusttaUITests/AfazeresUITests \
+            -skip-testing:CusttaUITests/ValeAPenaUITests \
+            -skip-testing:CusttaUITests/AnaliseUITests \
+            -skip-testing:CusttaUITests/LeituraDaAnaliseUITests \
+            -skip-testing:CusttaUITests/AuditoriaDaAnaliseUITests \
             CODE_SIGNING_ALLOWED=NO
 
       # Unidade ou tela reprovadas: o resultado dos testes fica 7 dias no artefato. Também quando o job é cancelado: o run
@@ -160,6 +210,8 @@ jobs:
 
   app-etapa3:
     runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' && needs.portoes.outputs.nivel != 'telas' }}
     # Os testes de tela da etapa 3, com o preparo do app, sem o build Release e sem o "resolver de novo": com eles, o app
     # passou do teto de 75 min (runs 39693700450 e 39710458060). No PR 1, o OrcamentoUITests; no PR 2, o
     # FolhasDeOrigemUITests. No run 39813469497, FolhasDeOrigem 25,0 + Orçamento 23,4 min, 58,8 com o preparo, numa VM
@@ -211,6 +263,8 @@ jobs:
 
   app-etapa3-b:
     runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' && needs.portoes.outputs.nivel != 'telas' }}
     # Os testes de tela da etapa 3 que não cabem no app-etapa3 (55 min no run 40019534025 e 58,8 numa VM lenta, no
     # 39813469497; com a suíte do detalhe, ~70 a 75): no PR 2, o DetalheDoTopicoUITests. As suítes de tela do PR 3
     # (~22 min de testes no run 39878786962) o levariam a ~50 min e vão para o app-etapa3-c.
@@ -258,6 +312,8 @@ jobs:
 
   app-etapa3-c:
     runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' && needs.portoes.outputs.nivel != 'telas' }}
     # Os testes de tela do PR 3 da etapa 3, que não cabem no app-etapa3-b: com eles (~22 min de testes no run
     # 39878786962), ele chegaria a ~50 min. No PR 3, o BuscaUITests e o AfazeresUITests. O mesmo preparo do app-etapa3, em
     # paralelo com ele. Teto de 60, como o do app-etapa3-b; como no app-etapa3, cada PR da etapa anota aqui o tempo do job.
@@ -302,6 +358,8 @@ jobs:
 
   laudo:
     runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' && needs.portoes.outputs.nivel != 'telas' }}
     # Leitura e auditorias em dois jobs que levam o mesmo tempo. Num job só (c1bc06a, 15/10): leitura 2089 s, auditorias
     # 718 s e ~7 min de build e simulador, 54 min; a folha do gasto soma ~1150 s de leitura e ~320 s de auditoria (perto
     # do dobro do Mac), 75–79 min. A leitura da folha, a mais pesada, roda no job auditoria: ~35 min de testes e ~43 min de
@@ -364,6 +422,8 @@ jobs:
 
   laudo-parte3:
     runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' && needs.portoes.outputs.nivel != 'telas' }}
     # As leituras e as auditorias da parte 3 da etapa 2: as ações da fase, a lista vazia, as folhas da obra e da venda,
     # o gasto numa vendida, a obra vendida com lucro e com prejuízo e o alerta de "Não salvou". A conta do tempo está
     # no job laudo.
@@ -414,6 +474,8 @@ jobs:
 
   laudo-etapa3:
     runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' && needs.portoes.outputs.nivel != 'telas' }}
     # As leituras e as auditorias das telas da etapa 3 do app nativo (conselho de 19/10, decisão 3: o job nasce com elas, sem
     # esperar um job passar de ~50 min). No PR 1, o orçamento: a linha na obra, a tela Orçamento e a folha com as teclas
     # encaixadas, no escuro, no claro e na maior letra. No PR 2, as folhas de origem (o A pagar e o detalhe do tópico), no
@@ -469,6 +531,8 @@ jobs:
 
   laudo-etapa3-b:
     runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' && needs.portoes.outputs.nivel != 'telas' }}
     # As leituras e as auditorias da etapa 3 que não cabem no laudo-etapa3: ele foi a 52 min no run 40125911713 e a 46 no
     # 40152738846 (teto de 60), com a maior letra e as auditorias das folhas de origem em 13,6 e 11,6 min. Essas três saem de
     # lá e abrem este job, com o laudo da busca e dos afazeres (PR 3), que o laudo pula. O mesmo preparo do laudo-etapa3, em
@@ -519,6 +583,8 @@ jobs:
 
   auditoria:
     runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' && needs.portoes.outputs.nivel != 'telas' }}
     # As auditorias de acessibilidade (as da parte 3 rodam no laudo-parte3, e as da etapa 3, no laudo-etapa3 e no
     # laudo-etapa3-b) e a leitura da folha do gasto; a conta do tempo está no job laudo. No fim do PR 2 da etapa 3, 37,8 min:
     # as 14 auditorias em 19,1 e a leitura em 11,2 (run 40125911713).
@@ -568,3 +634,198 @@ jobs:
           name: auditoria-app-ios
           path: ${{ runner.temp }}/auditoria.xcresult
           retention-days: 7
+
+  unidade:
+    runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && (needs.portoes.outputs.nivel == 'nucleo' || needs.portoes.outputs.nivel == 'telas') }}
+    # Nos níveis nucleo e telas, no lugar do app: o build Release sem assinatura e os testes de unidade, sem os de tela.
+    # Sem medida ainda: o primeiro PR que rodar neste nível anota aqui o tempo do job.
+    timeout-minutes: 45
+    steps:
+      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
+      - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
+        with:
+          node-version: 22
+
+      - name: Versão do Xcode
+        run: xcodebuild -version
+
+      # O mesmo build do job app: a Release compila sem segredo nenhum.
+      - name: Compilar (Release, sem assinatura)
+        run: |
+          set -o pipefail
+          xcodebuild \
+            -project app-ios/Custta.xcodeproj \
+            -scheme Custta \
+            -configuration Release \
+            -destination 'generic/platform=iOS' \
+            -derivedDataPath app-ios/build \
+            -skipMacroValidation \
+            -skipPackagePluginValidation \
+            -onlyUsePackageVersionsFromResolvedFile \
+            CODE_SIGNING_ALLOWED=NO \
+            CODE_SIGNING_REQUIRED=NO \
+            CODE_SIGN_IDENTITY= \
+            build
+
+      # Os testes de unidade do app, com os serviços falsos. Os de tela ficam com os jobs da etapa 4 (no nível telas).
+      - name: Testes de unidade no simulador
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
+            -resultBundlePath "$RUNNER_TEMP/unidade.xcresult" \
+            -only-testing:CusttaTests \
+            CODE_SIGNING_ALLOWED=NO
+
+      # Unidade reprovada: o resultado fica 7 dias no artefato, também quando o job é cortado no teto.
+      - name: Resultado dos testes de unidade quando reprovam ou o job é cortado
+        if: failure() || cancelled()
+        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
+        with:
+          name: unidade-app-ios
+          path: ${{ runner.temp }}/unidade.xcresult
+          retention-days: 7
+
+  app-etapa4:
+    runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' }}
+    # Os testes de tela das telas da análise (etapa 4): as suítes da pasta CusttaUITests/Analise. Roda nos níveis telas e
+    # tudo. O mesmo preparo do app-etapa3; como lá, cada PR da etapa anota aqui o tempo do job. Sem medida ainda (4a).
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
+      - name: Testes de tela da etapa 4 no simulador
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
+            -resultBundlePath "$RUNNER_TEMP/testes-etapa4.xcresult" \
+            -only-testing:CusttaUITests/ValeAPenaUITests \
+            -only-testing:CusttaUITests/AnaliseUITests \
+            CODE_SIGNING_ALLOWED=NO
+
+      # Tela reprovada: o resultado dos testes fica 7 dias no artefato, também quando o job é cortado no teto.
+      - name: Resultado dos testes da etapa 4 quando reprovam ou o job é cortado
+        if: failure() || cancelled()
+        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
+        with:
+          name: testes-etapa4-app-ios
+          path: ${{ runner.temp }}/testes-etapa4.xcresult
+          retention-days: 7
+
+  laudo-etapa4:
+    runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' }}
+    # O laudo de leitura das telas da análise (etapa 4), com o laudo das marcas: o LeituraDaAnaliseUITests, que mora na
+    # pasta CusttaUITests/Analise. Roda nos níveis telas e tudo. Sem medida ainda (4a): cada PR da etapa anota aqui o tempo.
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
+      # A mesma varredura curta do job laudo.
+      - name: Laudo de leitura da etapa 4 no simulador
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
+            -resultBundlePath "$RUNNER_TEMP/laudo-etapa4.xcresult" \
+            -only-testing:CusttaUITests/LeituraDaAnaliseUITests \
+            CODE_SIGNING_ALLOWED=NO
+
+      # Laudo reprovado: o resultado e os prints anotados ficam 7 dias no artefato (o log só traz as notas).
+      - name: Resultado do laudo da etapa 4 quando reprova
+        if: failure()
+        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
+        with:
+          name: laudo-etapa4-app-ios
+          path: ${{ runner.temp }}/laudo-etapa4.xcresult
+          retention-days: 7
+
+  auditoria-etapa4:
+    runs-on: macos-26
+    needs: portoes
+    if: ${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' }}
+    # As auditorias de acessibilidade das telas da análise (etapa 4): o AuditoriaDaAnaliseUITests, que mora na pasta
+    # CusttaUITests/Analise. Roda nos níveis telas e tudo. Sem medida ainda (4a): cada PR da etapa anota aqui o tempo.
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
+      # A mesma varredura curta do job laudo: uma auditoria troca de job sem mudar o que mede.
+      - name: Auditorias de acessibilidade da etapa 4 no simulador
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
+            -resultBundlePath "$RUNNER_TEMP/auditoria-etapa4.xcresult" \
+            -only-testing:CusttaUITests/AuditoriaDaAnaliseUITests \
+            CODE_SIGNING_ALLOWED=NO
+
+      # Auditoria reprovada: o resultado e os prints anotados ficam 7 dias no artefato.
+      - name: Resultado das auditorias da etapa 4 quando reprovam
+        if: failure()
+        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
+        with:
+          name: auditoria-etapa4-app-ios
+          path: ${{ runner.temp }}/auditoria-etapa4.xcresult
+          retention-days: 7
diff --git a/package.json b/package.json
index 964f851..d73795e 100644
--- a/package.json
+++ b/package.json
@@ -6,7 +6,7 @@
   "description": "Custta: aplicação estática sem build no deploy; npm mantém SDK local, testes, Capacitor e a função de cron do servidor.",
   "scripts": {
     "test": "npm run test:unit && npm run test:rules",
-    "test:unit": "node --test tests/calc.test.cjs tests/moeda.test.cjs tests/icons.test.cjs tests/logo-escrito.test.cjs tests/teclado.test.cjs tests/resumo.test.cjs tests/xss.test.cjs tests/headers.test.cjs tests/vercel.test.cjs tests/pwa.test.cjs tests/workflow.test.cjs tests/sync.test.cjs tests/fila.test.mjs tests/diagnostico.test.cjs tests/share.test.cjs tests/conta.test.mjs tests/fuso.test.cjs tests/dados.test.cjs tests/cadastro.test.cjs tests/sentry.test.cjs tests/nativo.test.cjs tests/ios.test.cjs tests/gestos.test.cjs tests/molas.test.mjs tests/vidro.test.cjs tests/build-www.test.mjs tests/capacitor.test.cjs tests/cloud-nativo.test.mjs tests/dialogos.test.cjs tests/push.test.cjs tests/push-cloud.test.mjs tests/enviar.test.cjs tests/cron.test.cjs tests/privacidade.test.cjs tests/screenshots.test.mjs tests/conta-demo.test.mjs tests/docs.test.mjs tests/google-cloud.test.mjs tests/apple-cloud.test.mjs tests/admin-deps.test.cjs tests/corte.test.cjs tests/pacotes.test.cjs tests/sonda-banco.test.mjs tests/vetores.test.mjs tests/app-ios.test.cjs tests/compara-laudo.test.mjs tests/cache-do-sw.test.mjs tests/csp-terceiros.test.cjs",
+    "test:unit": "node --test tests/calc.test.cjs tests/moeda.test.cjs tests/icons.test.cjs tests/logo-escrito.test.cjs tests/teclado.test.cjs tests/resumo.test.cjs tests/xss.test.cjs tests/headers.test.cjs tests/vercel.test.cjs tests/pwa.test.cjs tests/workflow.test.cjs tests/sync.test.cjs tests/fila.test.mjs tests/diagnostico.test.cjs tests/share.test.cjs tests/conta.test.mjs tests/fuso.test.cjs tests/dados.test.cjs tests/cadastro.test.cjs tests/sentry.test.cjs tests/nativo.test.cjs tests/ios.test.cjs tests/gestos.test.cjs tests/molas.test.mjs tests/vidro.test.cjs tests/build-www.test.mjs tests/capacitor.test.cjs tests/cloud-nativo.test.mjs tests/dialogos.test.cjs tests/push.test.cjs tests/push-cloud.test.mjs tests/enviar.test.cjs tests/cron.test.cjs tests/privacidade.test.cjs tests/screenshots.test.mjs tests/conta-demo.test.mjs tests/docs.test.mjs tests/google-cloud.test.mjs tests/apple-cloud.test.mjs tests/admin-deps.test.cjs tests/corte.test.cjs tests/pacotes.test.cjs tests/sonda-banco.test.mjs tests/vetores.test.mjs tests/app-ios.test.cjs tests/compara-laudo.test.mjs tests/cache-do-sw.test.mjs tests/csp-terceiros.test.cjs tests/portoes-app-ios.test.mjs",
     "test:rules": "firebase emulators:exec --only firestore \"node --test tests/rules.test.mjs\"",
     "rules:deploy": "firebase deploy --only firestore:rules",
     "vendor:firebase": "node scripts/vendor-firebase.mjs",
diff --git a/scripts/portoes-app-ios.mjs b/scripts/portoes-app-ios.mjs
new file mode 100644
index 0000000..bb1223a
--- /dev/null
+++ b/scripts/portoes-app-ios.mjs
@@ -0,0 +1,80 @@
+// Portões por superfície do app nativo (spec da etapa 4, "Portões por superfície"): lê os arquivos que o PR muda e escolhe
+// o nível da CI do app-ios.yml. Na dúvida, roda tudo.
+//
+// uso: node scripts/portoes-app-ios.mjs              o diff do PR, lido do git (HEAD é o commit de merge do PR)
+//      node scripts/portoes-app-ios.mjs --nivel <n>  o botão (workflow_dispatch): o nível pedido; sem ele, ou errado, tudo
+//
+// | nível  | quando                                                           | o que roda                            |
+// | nucleo | o PR só mexe no CusttaNucleo, no site e nos vetores               | nucleo e unidade                      |
+// | telas  | além disso, só em Custta/Analise e nos testes dela (…/Analise/)  | o nível nucleo e os jobs da etapa 4   |
+// | tudo   | qualquer outro arquivo que dispara o workflow, ou qualquer dúvida | todos os jobs                         |
+//
+// O arquivo que não dispara o app-ios.yml (um plano, o checklist, o CSS do site) não muda o nível: sozinho, nem roda o
+// workflow. Imprime o nível e o porquê; grava `nivel=<nível>` no GITHUB_OUTPUT e o resumo no GITHUB_STEP_SUMMARY.
+import { execFileSync } from 'node:child_process';
+import fs from 'node:fs';
+import { fileURLToPath } from 'node:url';
+
+export const NIVEIS = ['nucleo', 'telas', 'tudo'];
+
+/** Os caminhos que disparam o app-ios.yml (`on.pull_request.paths`); o tests/workflow.test.cjs confere que são os mesmos. */
+export const DISPARAM = ['app-ios/**', 'calc.js', 'dados.js', 'push.js', 'cadastro.js', 'teclado.js',
+  'scripts/vetores-calc.mjs', 'scripts/simulador-ios.mjs', 'tests/vetores/**', '.github/workflows/app-ios.yml'];
+
+const dispara = arquivo => DISPARAM.some(c => c.endsWith('/**') ? arquivo.startsWith(c.slice(0, -2)) : arquivo === c);
+
+/** O núcleo, o site e os vetores: as regras e o que as confere. */
+const NUCLEO = [/^app-ios\/CusttaNucleo\//, /^(calc|dados|push|cadastro|teclado)\.js$/, /^scripts\/vetores-calc\.mjs$/, /^tests\/vetores\//];
+/** As telas da análise e os testes delas, cada um na pasta `Analise` do alvo dele. */
+const TELAS = [/^app-ios\/Custta\/Analise\//, /^app-ios\/CusttaTests\/Analise\//, /^app-ios\/CusttaUITests\/Analise\//];
+
+/** A superfície de um arquivo do diff: 'fora' (não dispara o workflow), 'nucleo', 'telas' ou 'tudo'. */
+export function superficie(arquivo) {
+  // Um caminho que o git devolveu entre aspas (nome com acento, sem o -z) não casa com regra nenhuma: é dúvida.
+  if (!arquivo || arquivo.startsWith('"')) return 'tudo';
+  if (!dispara(arquivo)) return 'fora';
+  if (NUCLEO.some(r => r.test(arquivo))) return 'nucleo';
+  if (TELAS.some(r => r.test(arquivo))) return 'telas';
+  return 'tudo';
+}
+
+/** O nível do PR pelos arquivos do diff, com os arquivos que o decidiram (até 5). */
+export function nivelDosPortoes(arquivos) {
+  const porSuperficie = { fora: [], nucleo: [], telas: [], tudo: [] };
+  for (const arquivo of arquivos) porSuperficie[superficie(arquivo)].push(arquivo);
+  const nivel = [...NIVEIS].reverse().find(n => porSuperficie[n].length > 0);
+  // Nada do diff dispara o workflow, e ele rodou mesmo assim: o diff não é o do PR. Dúvida.
+  if (!nivel) return { nivel: 'tudo', porque: ['nenhum arquivo do diff dispara o app-ios.yml'] };
+  return { nivel, porque: porSuperficie[nivel].slice(0, 5), mais: Math.max(0, porSuperficie[nivel].length - 5) };
+}
+
+/** Os arquivos que o PR muda: o diff do commit de merge do PR (HEAD) contra o 1º pai, a ponta da base. Sem as
+    renomeações juntas, para o arquivo que sai de uma pasta contar pelas duas; com -z, para o nome com acento vir inteiro. */
+export function arquivosDoPR(cwd = process.cwd()) {
+  const git = (...args) => execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
+  git('rev-parse', '--verify', '--quiet', 'HEAD^2');       // não é um merge: falha, e quem chama roda tudo
+  return git('diff', '--name-only', '--no-renames', '-z', 'HEAD^1', 'HEAD').split('\0').filter(Boolean);
+}
+
+/** O nível da rodada: o pedido no botão, ou o do diff do PR; qualquer erro é dúvida. */
+export function escolher(args, cwd) {
+  const i = args.indexOf('--nivel');
+  if (i >= 0) {
+    const pedido = args[i + 1];
+    return NIVEIS.includes(pedido) ? { nivel: pedido, porque: ['pedido no botão'] }
+                                   : { nivel: 'tudo', porque: [`nível pedido no botão não existe: ${pedido ?? '(vazio)'}`] };
+  }
+  try {
+    return nivelDosPortoes(arquivosDoPR(cwd));
+  } catch (erro) {
+    return { nivel: 'tudo', porque: [`o diff do PR não pôde ser lido: ${String(erro.message).split('\n')[0]}`] };
+  }
+}
+
+if (process.argv[1] === fileURLToPath(import.meta.url)) {
+  const { nivel, porque, mais } = escolher(process.argv.slice(2));
+  const motivo = porque.join(', ') + (mais ? ` e mais ${mais}` : '');
+  console.log(`portões: ${nivel} (${motivo})`);
+  if (process.env.GITHUB_OUTPUT) fs.appendFileSync(process.env.GITHUB_OUTPUT, `nivel=${nivel}\n`);
+  if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, `### Portões do app nativo: ${nivel}\n\n${motivo}\n`);
+}
diff --git a/tests/portoes-app-ios.test.mjs b/tests/portoes-app-ios.test.mjs
new file mode 100644
index 0000000..e44fc67
--- /dev/null
+++ b/tests/portoes-app-ios.test.mjs
@@ -0,0 +1,155 @@
+import { test } from 'node:test';
+import assert from 'node:assert/strict';
+import { execFileSync } from 'node:child_process';
+import { mkdtempSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
+import { tmpdir } from 'node:os';
+import { dirname, join } from 'node:path';
+import { fileURLToPath } from 'node:url';
+import { DISPARAM, NIVEIS, arquivosDoPR, escolher, nivelDosPortoes, superficie } from '../scripts/portoes-app-ios.mjs';
+
+/* O filtro de portões do app nativo (spec da etapa 4, "Portões por superfície"): o nível sai dos arquivos que o PR muda
+   e, na dúvida, é tudo. Um nível baixo demais deixa de rodar teste: cada regra tem o caso que sobe e o que não sobe. */
+const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');
+const script = join(raiz, 'scripts', 'portoes-app-ios.mjs');
+const nivel = (...arquivos) => nivelDosPortoes(arquivos).nivel;
+
+test('o núcleo, o site e os vetores ficam no nível núcleo', () => {
+  for (const arquivo of ['app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift', 'app-ios/CusttaNucleo/Package.swift',
+    'app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift', 'calc.js', 'dados.js', 'push.js', 'cadastro.js',
+    'teclado.js', 'scripts/vetores-calc.mjs', 'tests/vetores/calc.json'])
+    assert.equal(superficie(arquivo), 'nucleo', arquivo);
+  assert.equal(nivel('calc.js', 'tests/vetores/calc.json', 'app-ios/CusttaNucleo/Sources/CusttaNucleo/Calc.swift'), 'nucleo');
+});
+
+test('a análise e os testes dela ficam no nível telas, que inclui o núcleo', () => {
+  for (const arquivo of ['app-ios/Custta/Analise/ValeAPenaView.swift', 'app-ios/Custta/Analise/Graficos/Anel.swift',
+    'app-ios/CusttaTests/Analise/FaixaDoValeAPenaTests.swift', 'app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift'])
+    assert.equal(superficie(arquivo), 'telas', arquivo);
+  assert.equal(nivel('app-ios/Custta/Analise/ValeAPenaView.swift'), 'telas');
+  assert.equal(nivel('app-ios/CusttaNucleo/Sources/CusttaNucleo/Pedacos.swift', 'app-ios/Custta/Analise/Anel.swift',
+    'app-ios/CusttaUITests/Analise/GraficosUITests.swift'), 'telas', 'o 2a: núcleo e análise juntos');
+});
+
+test('qualquer outro arquivo do app, o catálogo, os testes compartilhados e o workflow rodam tudo', () => {
+  for (const arquivo of ['app-ios/Custta/Telas/ObraView.swift', 'app-ios/Custta/Identidade/Blocos.swift',
+    'app-ios/Custta/Assets.xcassets/Esmeralda/Placa.colorset/Contents.json', 'app-ios/Custta/Falsos/VitrineDaAnalise.swift',
+    'app-ios/CusttaUITests/LeituraNoVidroUITests.swift', 'app-ios/CusttaUITests/AuditoriaUITests.swift',
+    'app-ios/CusttaUITests/Abrir.swift', 'app-ios/CusttaTests/BlocosTests.swift', 'app-ios/Custta.xcodeproj/project.pbxproj',
+    'app-ios/Custta/AnaliseNova/X.swift', 'app-ios/CusttaUITests/AnaliseUITests.swift', 'app-ios/ExportOptions.plist',
+    'scripts/simulador-ios.mjs', '.github/workflows/app-ios.yml'])
+    assert.equal(superficie(arquivo), 'tudo', arquivo);
+  // Um arquivo só já sobe o PR inteiro.
+  assert.equal(nivel('app-ios/Custta/Analise/ValeAPenaView.swift', 'app-ios/Custta/Telas/PrincipalView.swift'), 'tudo');
+  assert.equal(nivel('calc.js', '.github/workflows/app-ios.yml'), 'tudo');
+});
+
+test('o que não dispara o workflow não muda o nível', () => {
+  for (const arquivo of ['docs/plans/2026-11-24-app-nativo-etapa4-marco2.md', 'styles.css', 'app.js', 'package.json',
+    'tests/workflow.test.cjs', 'scripts/portoes-app-ios.mjs', 'scripts/icones-app-ios.mjs', 'ios/App/App/Info.plist',
+    '.github/workflows/test.yml', 'app-ios.md', 'tests/vetores.test.mjs'])
+    assert.equal(superficie(arquivo), 'fora', arquivo);
+  assert.equal(nivel('docs/plans/checklist.md', 'app-ios/Custta/Analise/Anel.swift'), 'telas');
+  assert.equal(nivel('styles.css', 'calc.js'), 'nucleo');
+});
+
+test('na dúvida, tudo', () => {
+  assert.deepEqual(nivelDosPortoes([]), { nivel: 'tudo', porque: ['nenhum arquivo do diff dispara o app-ios.yml'] });
+  assert.equal(nivel('docs/plans/x.md', 'styles.css'), 'tudo', 'o workflow rodou e nada do diff o dispara: o diff não é o do PR');
+  // O caminho entre aspas é o nome com acento que o git escapou: não casa com regra nenhuma.
+  assert.equal(superficie('"app-ios/Custta/Telas/Relat\\303\\263rio.swift"'), 'tudo');
+  assert.equal(superficie(''), 'tudo');
+  assert.equal(nivel('calc.js', '"app-ios/Custta/Telas/Relat\\303\\263rio.swift"'), 'tudo');
+});
+
+test('o porquê traz os arquivos que decidiram o nível, até cinco', () => {
+  const telas = [1, 2, 3, 4, 5, 6, 7].map(n => `app-ios/Custta/Analise/A${n}.swift`);
+  const r = nivelDosPortoes(['calc.js', ...telas]);
+  assert.equal(r.nivel, 'telas');
+  assert.deepEqual(r.porque, telas.slice(0, 5));
+  assert.equal(r.mais, 2);
+  assert.deepEqual(nivelDosPortoes(['calc.js', 'app-ios/Custta/Telas/ObraView.swift']).porque, ['app-ios/Custta/Telas/ObraView.swift']);
+});
+
+test('os níveis e os caminhos que disparam são os do workflow', () => {
+  assert.deepEqual(NIVEIS, ['nucleo', 'telas', 'tudo']);
+  const yml = readFileSync(join(raiz, '.github', 'workflows', 'app-ios.yml'), 'utf8');
+  const caminhos = [...(/\n  pull_request:\n    paths:\n((?:      - .*\n)+)/.exec(yml)?.[1] ?? '').matchAll(/- '([^']+)'/g)].map(m => m[1]);
+  assert.deepEqual(caminhos, DISPARAM, 'o filtro e o app-ios.yml têm de concordar sobre o que dispara o workflow');
+  // Cada caminho que dispara tem nível: nenhum fica de fora.
+  for (const caminho of DISPARAM) assert.notEqual(superficie(caminho.replace('**', 'x')), 'fora', caminho);
+});
+
+// Um repositório de mentira com o commit de merge de um PR, como o checkout do `pull_request` (refs/pull/N/merge).
+function repositorio(mudancas) {
+  const pasta = mkdtempSync(join(tmpdir(), 'portoes-'));
+  const git = (...args) => execFileSync('git', ['-c', 'user.name=teste', '-c', 'user.email=teste@exemplo.invalid', '-c',
+    'commit.gpgsign=false', ...args], { cwd: pasta, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
+  const gravar = arquivos => {
+    for (const [nome, texto] of Object.entries(arquivos)) {
+      mkdirSync(dirname(join(pasta, nome)), { recursive: true });
+      writeFileSync(join(pasta, nome), texto);
+    }
+    git('add', '-A');
+  };
+  git('init', '-q', '-b', 'main');
+  gravar({ 'calc.js': '1\n', 'app-ios/Custta/Telas/Velha.swift': 'struct Velha {}\n', 'LEIA.md': 'a\n' });
+  git('commit', '-q', '-m', 'base');
+  git('switch', '-q', '-c', 'pr');
+  mudancas({ gravar, git, pasta });
+  git('commit', '-q', '-m', 'pr');
+  git('switch', '-q', 'main');
+  gravar({ 'LEIA.md': 'b\n' });
+  git('commit', '-q', '-m', 'a base andou');
+  git('merge', '-q', '--no-ff', '-m', 'merge do PR', 'pr');
+  return { pasta, git };
+}
+
+test('lê o diff do commit de merge do PR, e não o que a base andou', () => {
+  const { pasta } = repositorio(({ gravar }) => gravar({ 'app-ios/Custta/Analise/Anel.swift': 'struct Anel {}\n' }));
+  assert.deepEqual(arquivosDoPR(pasta), ['app-ios/Custta/Analise/Anel.swift']);
+  assert.equal(escolher([], pasta).nivel, 'telas');
+});
+
+test('o arquivo que sai de uma pasta compartilhada para a análise conta pelas duas', () => {
+  const { pasta } = repositorio(({ git, pasta }) => {
+    mkdirSync(join(pasta, 'app-ios/Custta/Analise'), { recursive: true });
+    git('mv', 'app-ios/Custta/Telas/Velha.swift', 'app-ios/Custta/Analise/Velha.swift');
+  });
+  assert.deepEqual(arquivosDoPR(pasta).sort(), ['app-ios/Custta/Analise/Velha.swift', 'app-ios/Custta/Telas/Velha.swift']);
+  assert.equal(escolher([], pasta).nivel, 'tudo');
+});
+test('o nome com acento chega inteiro', () => {
+  const { pasta } = repositorio(({ gravar }) => gravar({ 'app-ios/Custta/Telas/Relatório.swift': 'struct R {}\n' }));
+  assert.deepEqual(arquivosDoPR(pasta), ['app-ios/Custta/Telas/Relatório.swift']);
+  assert.equal(escolher([], pasta).nivel, 'tudo');
+});
+
+test('fora de um commit de merge, ou sem git, roda tudo e diz por quê', () => {
+  const { pasta, git } = repositorio(({ gravar }) => gravar({ 'calc.js': '2\n' }));
+  assert.equal(escolher([], pasta).nivel, 'nucleo');
+  git('switch', '-q', '--detach', 'pr');
+  const semMerge = escolher([], pasta);
+  assert.equal(semMerge.nivel, 'tudo');
+  assert.match(semMerge.porque[0], /^o diff do PR não pôde ser lido: /);
+  assert.equal(escolher([], join(tmpdir(), 'portoes-pasta-que-nao-existe')).nivel, 'tudo');
+});
+
+test('no botão, o nível pedido; sem ele ou errado, tudo', () => {
+  for (const n of NIVEIS) assert.deepEqual(escolher(['--nivel', n]), { nivel: n, porque: ['pedido no botão'] });
+  assert.equal(escolher(['--nivel', 'nada']).nivel, 'tudo');
+  assert.equal(escolher(['--nivel', '']).nivel, 'tudo');
+  assert.equal(escolher(['--nivel']).nivel, 'tudo');
+});
+
+test('a linha de comando grava o nível para o workflow', () => {
+  const saida = join(mkdtempSync(join(tmpdir(), 'portoes-saida-')), 'saida');
+  const resumo = saida + '-resumo';
+  const { pasta } = repositorio(({ gravar }) => gravar({ 'app-ios/CusttaNucleo/Sources/CusttaNucleo/X.swift': 'let x = 1\n' }));
+  const dito = execFileSync(process.execPath, [script], { cwd: pasta, encoding: 'utf8', env: { ...process.env, GITHUB_OUTPUT: saida, GITHUB_STEP_SUMMARY: resumo } });
+  assert.equal(dito, 'portões: nucleo (app-ios/CusttaNucleo/Sources/CusttaNucleo/X.swift)\n');
+  assert.equal(readFileSync(saida, 'utf8'), 'nivel=nucleo\n');
+  assert.match(readFileSync(resumo, 'utf8'), /^### Portões do app nativo: nucleo\n\napp-ios\/CusttaNucleo\//);
+  const noBotao = execFileSync(process.execPath, [script, '--nivel', 'telas'], { cwd: pasta, encoding: 'utf8', env: { ...process.env, GITHUB_OUTPUT: saida, GITHUB_STEP_SUMMARY: resumo } });
+  assert.equal(noBotao, 'portões: telas (pedido no botão)\n');
+  assert.equal(readFileSync(saida, 'utf8'), 'nivel=nucleo\nnivel=telas\n');
+});
diff --git a/tests/workflow.test.cjs b/tests/workflow.test.cjs
index 740c453..8c95baa 100644
--- a/tests/workflow.test.cjs
+++ b/tests/workflow.test.cjs
@@ -228,10 +228,10 @@ assert.ok(!/^on:\n(?:.*\n)*?\s{2}push:/m.test(appIos), 'o app nativo não roda e
 assert.match(appIos, /workflow_dispatch:/, 'o app nativo precisa do botão manual');
 assert.match(appIos, /resolver_de_novo:/, 'sem o botão de resolver os pacotes Swift do app nativo de novo');
 assert.match(appIosSemComentario, /- name: Resolver os pacotes Swift de novo\n\s+if: inputs\.resolver_de_novo\n/, 'o passo de resolver de novo só roda no botão (if: inputs.resolver_de_novo)');
-assert.equal((appIosSemComentario.match(/CODE_SIGNING_ALLOWED=NO/g) || []).length, 10, 'build, testes, os testes da etapa 3 (app-etapa3, app-etapa3-b e app-etapa3-c), os quatro laudos e auditoria sem assinatura');
+assert.equal((appIosSemComentario.match(/CODE_SIGNING_ALLOWED=NO/g) || []).length, 15, 'build, testes, os testes da etapa 3 (app-etapa3, app-etapa3-b e app-etapa3-c), os quatro laudos, auditoria, o unidade (build e testes) e os três jobs da etapa 4 sem assinatura');
 assert.match(appIosSemComentario, /-project app-ios\/Custta\.xcodeproj[\s\S]*-configuration Release[\s\S]*CODE_SIGNING_ALLOWED=NO/, 'o app compila em Release sem assinatura');
 assert.match(appIosSemComentario, /xcodebuild test[\s\S]*-destination "\$DESTINO"/, 'os testes rodam no simulador escolhido pelo script');
-assert.equal((appIosSemComentario.match(/-onlyUsePackageVersionsFromResolvedFile/g) || []).length, 10, 'build, testes, os testes da etapa 3 (app-etapa3, app-etapa3-b e app-etapa3-c), os quatro laudos e auditoria com os pacotes travados');
+assert.equal((appIosSemComentario.match(/-onlyUsePackageVersionsFromResolvedFile/g) || []).length, 15, 'build, testes, os testes da etapa 3 (app-etapa3, app-etapa3-b e app-etapa3-c), os quatro laudos, auditoria, o unidade (build e testes) e os três jobs da etapa 4 com os pacotes travados');
 // O laudo de leitura e as auditorias moram nos jobs laudo, laudo-parte3, laudo-etapa3, laudo-etapa3-b e auditoria, em
 // paralelo: o app pula os dois. O laudo roda a leitura; o laudo-parte3 (as leituras da parte 3 da etapa 2), o laudo-etapa3 e
 // o laudo-etapa3-b (as da etapa 3) e o auditoria rodam as leituras que o laudo pula, e o auditoria também as auditorias, menos
@@ -243,6 +243,9 @@ const jobApp = jobAppIos('app'), jobLaudo = jobAppIos('laudo'), jobParte3 = jobA
 const jobEtapa3 = jobAppIos('laudo-etapa3'), jobEtapa3b = jobAppIos('laudo-etapa3-b'), jobAppEtapa3 = jobAppIos('app-etapa3');
 const jobAppEtapa3b = jobAppIos('app-etapa3-b');
 const jobAppEtapa3c = jobAppIos('app-etapa3-c');
+// Os jobs da etapa 4 (as telas da análise) e os dos portões por superfície.
+const jobAppEtapa4 = jobAppIos('app-etapa4'), jobLaudoEtapa4 = jobAppIos('laudo-etapa4'), jobAuditoriaEtapa4 = jobAppIos('auditoria-etapa4');
+const jobPortoes = jobAppIos('portoes'), jobUnidade = jobAppIos('unidade'), jobNucleo = jobAppIos('nucleo');
 assert.match(jobApp, /-skip-testing:CusttaUITests\/LeituraNoVidroUITests[\s\S]*-skip-testing:CusttaUITests\/AuditoriaUITests/,
   'o job app pula o laudo e as auditorias');
 assert.match(jobLaudo, /-only-testing:CusttaUITests\/LeituraNoVidroUITests \\\n/, 'o job laudo roda o laudo de leitura');
@@ -271,7 +274,8 @@ assert.ok(!/-only-testing:CusttaUITests\/AuditoriaUITests \\\n/.test(jobParte3 +
 const auditoria = readFileSync(join(__dirname, '..', 'app-ios', 'CusttaUITests', 'AuditoriaUITests.swift'), 'utf8');
 for(const metodo of puladasNoAuditoria)
   assert.match(auditoria, new RegExp(`func ${metodo}\\(`), `o app-ios.yml divide ${metodo}, que não existe mais no AuditoriaUITests`);
-for(const [nome, job] of [['laudo', jobLaudo], ['laudo-parte3', jobParte3], ['laudo-etapa3', jobEtapa3], ['laudo-etapa3-b', jobEtapa3b], ['auditoria', jobAuditoria]]){
+for(const [nome, job] of [['laudo', jobLaudo], ['laudo-parte3', jobParte3], ['laudo-etapa3', jobEtapa3], ['laudo-etapa3-b', jobEtapa3b], ['auditoria', jobAuditoria],
+  ['laudo-etapa4', jobLaudoEtapa4], ['auditoria-etapa4', jobAuditoriaEtapa4]]){
   assert.match(job, /\n    runs-on: macos-26\n/, `o job ${nome} roda no macOS 26 fixo`);
   assert.match(job, /\n\s+TEST_RUNNER_CUSTTA_VARREDURA: curta\n/, `o job ${nome} usa a varredura curta (a lista sob a cápsula só em 0, 20, 40 e 260 pt)`);
   assert.match(job, new RegExp(`-resultBundlePath "\\$RUNNER_TEMP/${nome}\\.xcresult"[\\s\\S]*if: failure\\(\\)[\\s\\S]*path: \\$\\{\\{ runner\\.temp \\}\\}/${nome}\\.xcresult`),
@@ -286,27 +290,73 @@ for(const [nome, job] of [['laudo', jobLaudo], ['laudo-parte3', jobParte3], ['la
 const suitesInteiras = (job, opcao) => [...job.matchAll(new RegExp(`-${opcao}-testing:CusttaUITests/(\\w+)(?![\\w/])`, 'g'))].map(m => m[1]);
 const suitesQueRodam = job => [...job.matchAll(/-only-testing:CusttaUITests\/(\w+)/g)].map(m => m[1]);
 assert.ok(!/-skip-testing:CusttaUITests\/\w+\//.test(jobApp), 'o app pula suítes de tela inteiras');
-for(const [nome, job] of [['app-etapa3', jobAppEtapa3], ['app-etapa3-b', jobAppEtapa3b], ['app-etapa3-c', jobAppEtapa3c]]){
+for(const [nome, job] of [['app-etapa3', jobAppEtapa3], ['app-etapa3-b', jobAppEtapa3b], ['app-etapa3-c', jobAppEtapa3c],
+  ['app-etapa4', jobAppEtapa4], ['laudo-etapa4', jobLaudoEtapa4], ['auditoria-etapa4', jobAuditoriaEtapa4]]){
   assert.ok(!/-(?:only|skip)-testing:CusttaUITests\/\w+\//.test(job), `o ${nome} roda suítes de tela inteiras`);
-  assert.ok(suitesInteiras(job, 'only').length > 0, `o ${nome} roda só as suítes da etapa 3 (sem -only-testing, rodaria todas)`);
+  assert.ok(suitesInteiras(job, 'only').length > 0, `o ${nome} roda só as suítes dele (sem -only-testing, rodaria todas)`);
   assert.match(job, /\n    runs-on: macos-26\n/, `o job ${nome} roda no macOS 26 fixo`);
 }
 const puladasNoApp = suitesInteiras(jobApp, 'skip');
 const nosLaudos = [...new Set([jobLaudo, jobParte3, jobEtapa3, jobEtapa3b, jobAuditoria].flatMap(suitesQueRodam))];
-assert.deepStrictEqual([...nosLaudos, ...[jobAppEtapa3, jobAppEtapa3b, jobAppEtapa3c].flatMap(job => suitesInteiras(job, 'only'))].sort(), [...puladasNoApp].sort(),
-  'a suíte de tela que o app pula roda nos laudos, no auditoria, no app-etapa3, no app-etapa3-b ou no app-etapa3-c, uma vez só, e os três rodam só o que o app pula');
-const telas = readdirSync(join(__dirname, '..', 'app-ios', 'CusttaUITests')).filter(f => f.endsWith('.swift'))
+const daEtapa4 = [jobAppEtapa4, jobLaudoEtapa4, jobAuditoriaEtapa4].flatMap(job => suitesInteiras(job, 'only'));
+assert.deepStrictEqual([...nosLaudos, ...[jobAppEtapa3, jobAppEtapa3b, jobAppEtapa3c].flatMap(job => suitesInteiras(job, 'only')), ...daEtapa4].sort(), [...puladasNoApp].sort(),
+  'a suíte de tela que o app pula roda nos laudos, no auditoria, no app-etapa3, no app-etapa3-b, no app-etapa3-c ou num job da etapa 4, uma vez só, e eles rodam só o que o app pula');
+// As telas da análise: toda suíte de tela da pasta CusttaUITests/Analise roda num job da etapa 4, e eles só rodam as dela. No
+// nível telas, o app não roda: a suíte da análise que ficasse com ele não rodaria em PR nenhum que só mexe na análise.
+const pastaDaAnalise = join(__dirname, '..', 'app-ios', 'CusttaUITests', 'Analise');
+const suitesDaAnalise = readdirSync(pastaDaAnalise).filter(f => f.endsWith('.swift'))
+  .flatMap(f => [...readFileSync(join(pastaDaAnalise, f), 'utf8').matchAll(/^(?:@MainActor\s+)?final class (\w+): XCTestCase/gm)].map(m => m[1]));
+assert.ok(suitesDaAnalise.length >= 4, `as suítes de tela da análise: ${suitesDaAnalise}`);
+assert.deepStrictEqual([...daEtapa4].sort(), [...suitesDaAnalise].sort(),
+  'cada suíte de CusttaUITests/Analise roda num job da etapa 4 (app-etapa4, laudo-etapa4 ou auditoria-etapa4), uma vez só, e eles só rodam as dela');
+assert.ok(existsSync(join(__dirname, '..', 'app-ios', 'CusttaTests', 'Analise')), 'os testes de unidade da análise moram em CusttaTests/Analise (o filtro de portões conta com a pasta)');
+const telas = readdirSync(join(__dirname, '..', 'app-ios', 'CusttaUITests'), { recursive: true }).filter(f => f.endsWith('.swift'))
   .map(f => readFileSync(join(__dirname, '..', 'app-ios', 'CusttaUITests', f), 'utf8')).join('\n');
 for(const suite of puladasNoApp)
   assert.match(telas, new RegExp(`\\bclass ${suite}\\b`), `o app-ios.yml divide ${suite}, que não existe no CusttaUITests`);
 // O resultado sobe também quando o job é cancelado: o run 39710458060 foi cortado no teto e ficou sem xcresult.
 for(const [nome, job, resultado] of [['app', jobApp, 'testes'], ['app-etapa3', jobAppEtapa3, 'testes-etapa3'], ['app-etapa3-b', jobAppEtapa3b, 'testes-etapa3-b'],
-  ['app-etapa3-c', jobAppEtapa3c, 'testes-etapa3-c']])
+  ['app-etapa3-c', jobAppEtapa3c, 'testes-etapa3-c'], ['app-etapa4', jobAppEtapa4, 'testes-etapa4'], ['unidade', jobUnidade, 'unidade']])
   assert.match(job, new RegExp(`-resultBundlePath "\\$RUNNER_TEMP/${resultado}\\.xcresult"[\\s\\S]*\\n\\s+if: failure\\(\\) \\|\\| cancelled\\(\\)\\n[\\s\\S]*path: \\$\\{\\{ runner\\.temp \\}\\}/${resultado}\\.xcresult`),
     `o job ${nome} guarda o próprio resultado quando reprova e quando é cortado no teto`);
-assert.ok(!/\n    (?:needs|if):/.test(jobApp + jobAppEtapa3 + jobAppEtapa3b + jobAppEtapa3c + jobLaudo + jobParte3 + jobEtapa3 + jobEtapa3b + jobAuditoria), 'o app, o app-etapa3, o app-etapa3-b, o app-etapa3-c, os laudos e o auditoria rodam em todo PR e em paralelo: nenhum tem if nem espera outro job');
-assert.ok(!/continue-on-error/.test(jobApp + jobAppEtapa3 + jobAppEtapa3b + jobAppEtapa3c + jobLaudo + jobParte3 + jobEtapa3 + jobEtapa3b + jobAuditoria), 'o app, o app-etapa3, o app-etapa3-b, o app-etapa3-c, os laudos e o auditoria são portão: nenhum passa com falha (continue-on-error)');
-for(const job of ['nucleo', 'app', 'app-etapa3', 'app-etapa3-b', 'app-etapa3-c', 'laudo', 'laudo-parte3', 'laudo-etapa3', 'laudo-etapa3-b', 'auditoria'])
+/* Portões por superfície (spec da etapa 4): o job portoes escolhe o nível pelo diff do PR, e cada job diz em que nível roda.
+   Um job novo sem nível reprova aqui: a tabela é a lista inteira dos jobs do app-ios.yml. Só o `if` exato de cada nível
+   passa; o de quem roda no nível tudo é escrito pela negativa, para o job rodar na dúvida (o portoes falhou ou não disse
+   nada) e só ser pulado quando o filtro disse nucleo ou telas. */
+const SE = {
+  tudo: "${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' && needs.portoes.outputs.nivel != 'telas' }}",
+  telasETudo: "${{ !cancelled() && needs.portoes.outputs.nivel != 'nucleo' }}",
+  nucleoETelas: "${{ !cancelled() && (needs.portoes.outputs.nivel == 'nucleo' || needs.portoes.outputs.nivel == 'telas') }}",
+};
+const NIVEL_DOS_JOBS = {
+  portoes: null, nucleo: null,
+  app: 'tudo', 'app-etapa3': 'tudo', 'app-etapa3-b': 'tudo', 'app-etapa3-c': 'tudo',
+  laudo: 'tudo', 'laudo-parte3': 'tudo', 'laudo-etapa3': 'tudo', 'laudo-etapa3-b': 'tudo', auditoria: 'tudo',
+  unidade: 'nucleoETelas',
+  'app-etapa4': 'telasETudo', 'laudo-etapa4': 'telasETudo', 'auditoria-etapa4': 'telasETudo',
+};
+const jobsDoAppIos = [...appIosSemComentario.slice(appIosSemComentario.indexOf('\njobs:\n')).matchAll(/\n  ([\w-]+):\n/g)].map(m => m[1]);
+assert.deepStrictEqual(jobsDoAppIos.sort(), Object.keys(NIVEL_DOS_JOBS).sort(), 'todo job do app-ios.yml tem nível na tabela dos portões, e a tabela não tem job que não existe');
+for(const [nome, nivel] of Object.entries(NIVEL_DOS_JOBS)){
+  const job = jobAppIos(nome);
+  const condicoes = [...job.matchAll(/\n    (needs|if): (.*)/g)].map(m => `${m[1]}: ${m[2]}`);
+  assert.deepStrictEqual(condicoes, nivel ? ['needs: portoes', `if: ${SE[nivel]}`] : [],
+    nivel ? `o job ${nome} roda no nível ${nivel}: needs: portoes e o if exato desse nível` : `o job ${nome} roda em todo nível, sem needs nem if`);
+  assert.ok(!/continue-on-error/.test(job), `o job ${nome} é portão: nenhum passa com erro`);
+}
+// O portoes roda no Ubuntu (não ocupa vaga de macOS), lê o diff do commit de merge do PR e entrega o nível.
+assert.match(jobPortoes, /\n    runs-on: ubuntu-latest\n/, 'o portoes roda no Ubuntu');
+assert.match(jobPortoes, /\n    outputs:\n      nivel: \$\{\{ steps\.nivel\.outputs\.nivel \}\}\n/, 'o portoes entrega o nível aos outros jobs');
+assert.match(jobPortoes, /fetch-depth: 2\n/, 'o portoes precisa do 1º pai do merge do PR (HEAD^1) para o diff');
+assert.match(jobPortoes, /\n        id: nivel\n        env:\n          EVENTO: \$\{\{ github\.event_name \}\}\n          NIVEL: \$\{\{ inputs\.nivel \}\}\n/, 'o evento e o nível pedido entram por env:');
+assert.match(jobPortoes, /if \[ "\$EVENTO" = pull_request \]; then\n\s+node scripts\/portoes-app-ios\.mjs\n\s+else\n\s+node scripts\/portoes-app-ios\.mjs --nivel "\$NIVEL"\n\s+fi\n/,
+  'no PR, o nível sai do diff; no botão, do nível pedido');
+assert.ok(existsSync(join(__dirname, '..', 'scripts', 'portoes-app-ios.mjs')), 'falta o script dos portões');
+assert.match(appIos, /\n      nivel:\n(?:.*\n)*?        type: choice\n        default: tudo\n        options:\n          - tudo\n          - telas\n          - nucleo\n/, 'no botão, o nível é escolhido, e o padrão é tudo');
+// O unidade faz, nos níveis sem o app, o que o app faz além dos testes de tela: a Release sem assinatura e a unidade.
+assert.match(jobUnidade, /-configuration Release[\s\S]*CODE_SIGNING_ALLOWED=NO[\s\S]*-only-testing:CusttaTests \\\n/, 'o unidade compila a Release sem assinatura e roda os testes de unidade');
+assert.ok(!/CusttaUITests/.test(jobUnidade), 'o unidade não roda teste de tela');
+for(const job of Object.keys(NIVEL_DOS_JOBS))
   assert.match(jobAppIos(job), /\n    timeout-minutes: \d+\n/, `o job ${job} do app nativo precisa de timeout-minutes (sem ele, um job travado só cai em 6 h)`);
 // O resultado de cada job sobe com um nome só dele: no mesmo run o upload-artifact não aceita o mesmo nome duas vezes, e dois
 // jobs reprovados juntos perderiam um dos resultados.
```

### Tarefa 17: checklist do aparelho do "Vale a pena?"

**Commit das fatias:** `b579d8e` · **Mensagem:** `docs: checklist do aparelho do "Vale a pena?"`

Os itens do marco 2 para o PR 4a: a aba, as teclas do preço, os meses, a faixa, a tabela, a maior letra e a acessibilidade.

**Prova:** Só texto; os itens saem das tarefas 4 a 9.

**Arquivos:**

```
 ...6-10-29-app-nativo-etapa4-checklist-aparelho.md | 47 ++++++++++++++++++++++
 1 file changed, 47 insertions(+)
```

**Mudança:**

```diff
diff --git a/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md b/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
index 73df9b7..2ec1053 100644
--- a/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
+++ b/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
@@ -87,3 +87,50 @@ do marco 1 nas mesmas obras.
 - [ ] Controle por Voz ("Mostrar nomes"): "Tocar Orçamento", "Tocar A pagar", "Tocar Afazeres" e o nome de um lançamento.
 - [ ] Com Reduzir movimento, Aumentar contraste e Reduzir transparência ligados nos Ajustes do iPhone (não no app), a obra
   continua como no marco 1.
+
+## Marco 2: o "Vale a pena?" e os Gráficos
+
+**A aba "Vale a pena?"** (PR 4a; mockup aprovado, parte 2)
+
+- [ ] A cápsula tem três abas: Obras, Vale a pena? e Ajustes. A nova fica no meio, e o + some nela, como em Ajustes. A
+  cápsula continua a 16 pt da borda e não pula ao trocar de aba.
+- [ ] A aba abre com a primeira obra em andamento que tem gastos, o preço na venda estimada dela e os meses em 0. A conta já
+  aparece: o bloco verde "Vale a pena" ou o âmbar "Rende menos que o banco", com a taxa ao mês em mono. Com a mesma obra,
+  o mesmo preço e os mesmos meses, os números são os do simulador do site.
+- [ ] "Obra": a lista traz só as obras não vendidas que têm gastos. Trocar de obra troca o preço, enquanto você não digitou.
+- [ ] Toque em "Se eu vender por": as teclas tomam o lugar da cápsula, com o valor ainda à vista. O primeiro dígito
+  substitui o valor (não emenda nele), os centavos entram pela direita, e a conta acompanha cada tecla. "OK" fecha as
+  teclas, e a cápsula volta. Abrir e dar "OK" sem digitar deixa tudo como estava. Diga se o valor à vista, com o cursor
+  depois dele, deixa claro que o próximo dígito substitui (o mockup só desenha o campo vazio).
+- [ ] Apague o preço até o fim: o campo fica com "R$ 0,00" apagado, e aparece "Digite o preço de venda pra ver a conta.". Ele
+  não volta para a venda estimada, nem trocando de obra. Fechando e abrindo o app, volta.
+- [ ] O − e o + andam de um em um mês; o − para em 0 e o + em 120, e a frase do bloco acompanha ("vendendo hoje", "vendendo
+  daqui a 6 meses").
+- [ ] A faixa "Onde a sua venda cai": o custo numa barra, o tracejado do empate com o banco e a venda numa barra com um
+  ponto em cima; a parte hachurada é o lado "acima do banco". A etiqueta diz de que lado a venda caiu, e os três valores
+  vêm embaixo, cada um com o marcador dele.
+- [ ] A tabela "Relatório da simulação", pelo bruto e pelo corrigido; na obra com área, a última linha é o preço por m². Um
+  preço abaixo do custo mostra o prejuízo em âmbar, nunca em vermelho.
+- [ ] Numa obra que começou há menos de 1 mês: a taxa vira "—", e aparece "obra com menos de 1 mês — % ao mês ainda não diz
+  muito".
+- [ ] Vá a Ajustes e volte: a obra, o preço e os meses continuam. Lance um gasto na obra escolhida e volte à aba: a conta já
+  mudou.
+
+**Texto Maior no máximo**
+
+- [ ] O título quebra em duas linhas; cada campo fica com o valor embaixo do nome; o − e o + crescem.
+- [ ] Toque no preço: a linha "Se eu vender por" sobe e fica inteira acima das teclas. As teclas param de crescer antes do
+  máximo, como as do orçamento, e a barra delas ("Preço de venda" e "OK") também: tocar e segurar no "OK" mostra o texto
+  grande no meio da tela.
+- [ ] O veredito, a faixa com os três valores e a tabela, com um valor por linha, sem nada cortado.
+
+**Acessibilidade**
+
+- [ ] VoiceOver, nos campos: "Obra, Casa Alphaville", "Se eu vender por, R$ …, botão" e "Daqui a, 6 meses", com "Um mês a
+  menos" e "Um mês a mais". Nas teclas, cada toque fala o valor novo; o gesto de sair (o Z com dois dedos) as fecha.
+- [ ] VoiceOver, na conta: o veredito é um elemento só, com a frase inteira; a faixa é uma imagem com os três valores; cada
+  linha da tabela fala o nome e os dois valores.
+- [ ] Controle por Voz ("Mostrar nomes"): "Tocar Obra", "Tocar Se eu vender por", "Tocar Um mês a mais" e "Tocar OK".
+- [ ] No escuro e no claro, nos vidros Transparente e Fosco: as três marcas da faixa se distinguem do trilho e da parte
+  hachurada, e o "OK" das teclas se lê. Com Reduzir transparência, os blocos e as teclas ficam sólidos.
+- [ ] Com Aumentar contraste, a aba inteira continua legível, e os blocos verde e âmbar não mudam de cor.
```

### Tarefa 18: zona da faixa do "Vale a pena?" recortada em volta das marcas

**Commit das fatias:** `ccb239c` · **Mensagem:** `fix: zona da faixa do "Vale a pena?" recortada em volta das marcas`

O laudo das marcas reprovou o tracejado do empate e a barra da venda em 1,90:1 no escuro e 2,96:1 no claro: os dois eram desenhados sobre o contorno verde da zona hachurada. Por decisão do Giovani de 24/11, entre as saídas que o Croqui mediu, a zona fica com a hachura, o contorno e as cores do mockup, mas começa 4 pt depois do tracejado e abre uma fenda de 8 pt onde passa a venda. Atrás das três marcas fica o trilho, como já ficava atrás do custo. Não entra cor nem token novo.

A zona sai do grupo das marcas: é fundo, e fica no print das marcas apagadas. O laudo das marcas da faixa (testMarcasDaFaixaDoValeAPena) entra no LeituraDaAnaliseUITests, com o portão de 3:1 nos dois temas e nos vidros Transparente e Fosco. O item do checklist pergunta se a venda ainda se lê como dentro da zona.

**Prova:** Laudo das marcas (`testMarcasDaFaixaDoValeAPena`) verde no iOS 27 (pior nota 4,96:1, escuro e Transparente) e no 26.5 (5,73:1); `testAFaixaMostraOndeAVendaCai` verde nos dois. Vermelho por mutação: a zona sem o recorte (vão e fenda zerados) dá 1,90:1 e 2,96:1, os números de antes; só sem a fenda, a venda cai para os mesmos 1,90 e 2,96. Recorte e fenda conferidos nos prints anexados.

**Arquivos:**

```
 app-ios/Custta/Analise/ValeAPenaView.swift         | 30 +++++++++++---
 .../Analise/LeituraDaAnaliseUITests.swift          | 47 ++++++++++++++++++++++
 ...6-10-29-app-nativo-etapa4-checklist-aparelho.md |  6 ++-
 3 files changed, 75 insertions(+), 8 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Analise/ValeAPenaView.swift b/app-ios/Custta/Analise/ValeAPenaView.swift
index 4036df1..27e9d56 100644
--- a/app-ios/Custta/Analise/ValeAPenaView.swift
+++ b/app-ios/Custta/Analise/ValeAPenaView.swift
@@ -258,6 +258,10 @@ struct FaixaDoValeAPena: View {
 /// O desenho da faixa, em formas (sem texto): cada marca no x que o núcleo deu, como fração da largura.
 struct DesenhoDaFaixa: View {
     static let altura: CGFloat = 46
+    /// Do tracejado do empate ao começo da zona: o tracejado tem 2 pt, e sobram 2 de trilho entre ele e a hachura.
+    static let vaoDoEmpate: CGFloat = 4
+    /// A fenda da zona onde passa a venda: a barra tem 4 pt, e sobram 2 de trilho de cada lado.
+    static let fendaDaVenda: CGFloat = 8
     let faixa: FaixaDoSimulador
     @Environment(\.paleta) private var paleta
     #if DEBUG
@@ -280,13 +284,27 @@ struct DesenhoDaFaixa: View {
                 // O trilho: o texto a 14%, como o da barra do orçamento. A altura vai escrita: a pilha cresce até a marca mais
                 // alta (a venda, 16 pt a mais), e um trilho sem altura cresceria com ela, para 62 pt, e sobraria embaixo da zona.
                 RoundedRectangle(cornerRadius: 12).fill(tinta.opacity(0.14)).frame(height: altura)
+                // A zona "acima do banco", hachurada, com o contorno no destaque, recortada em volta das marcas (decisão do
+                // Giovani de 24/11, saída (c) do Croqui): o contorno sob o empate e a venda as deixava em 1,90:1 no escuro e
+                // 2,96:1 no claro. Ela começa 4 pt depois do tracejado e abre uma fenda de 8 pt onde passa a venda; atrás das
+                // marcas fica o trilho, como atrás do custo. É fundo, e não marca: fica no print das marcas apagadas.
+                let inicio = empate + Self.vaoDoEmpate
+                zona.fill(paleta.cor(.positivoFundo))
+                    .overlay { Hachura(traco: 2, passo: 6).fill(paleta.cor(.destaque).opacity(0.55)).clipShape(zona) }
+                    .overlay { zona.strokeBorder(paleta.cor(.destaque), lineWidth: 1.5) }
+                    .frame(width: max(0, largura - inicio), height: altura)
+                    // A fenda fora da zona (a venda abaixo do banco) não recorta nada.
+                    .mask(alignment: .leading) {
+                        ZStack(alignment: .leading) {
+                            Rectangle()
+                            Rectangle().frame(width: Self.fendaDaVenda)
+                                .offset(x: venda - inicio - Self.fendaDaVenda / 2)
+                                .blendMode(.destinationOut)
+                        }
+                        .compositingGroup()
+                    }
+                    .offset(x: inicio)
                 Group {
-                    // A zona "acima do banco": do empate até o fim, hachurada, com o contorno no destaque.
-                    zona.fill(paleta.cor(.positivoFundo))
-                        .overlay { Hachura(traco: 2, passo: 6).fill(paleta.cor(.destaque).opacity(0.55)).clipShape(zona) }
-                        .overlay { zona.strokeBorder(paleta.cor(.destaque), lineWidth: 1.5) }
-                        .frame(width: max(0, largura - empate), height: altura)
-                        .offset(x: empate)
                     // O custo: uma barra de 3 pt, 6 acima e 6 abaixo da faixa.
                     RoundedRectangle(cornerRadius: 2).fill(tinta).frame(width: 3, height: altura + 12).offset(x: custo, y: -6)
                     // O empate com o banco: o tracejado.
diff --git a/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift b/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift
index 8be9109..a2b4934 100644
--- a/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift
+++ b/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift
@@ -89,6 +89,53 @@ final class LeituraDaAnaliseUITests: XCTestCase, LaudoDeLeitura {
         ])
     }
 
+    /// O laudo das marcas da faixa "Onde a sua venda cai" (spec da etapa 4, "Laudo das marcas"): o custo, o empate e a venda a
+    /// 3:1 com o que fica atrás deles, nos dois temas e nos vidros Transparente e Fosco. Cada cena sai em dois prints, um
+    /// normal e um com as marcas apagadas (`-custta.marcasApagadas`, só Debug); a zona, com o recorte em volta das marcas, é
+    /// fundo e fica nos dois. Na Casa Alphaville a venda cai dentro da zona: a fenda está no print.
+    @MainActor func testMarcasDaFaixaDoValeAPena() {
+        var falhas: [String] = []
+        for tema in temas {
+            for vidro in ["transparente", "fosco"] {
+                let nome = "marcas, faixa do vale a pena, \(tema), \(vidro)"
+                let argumentos = ["-custta.tema", tema, "-custta.vidro", vidro, "-custta.rolagem", "\(Self.rolagemDaFaixa)"] + piorMomento
+                func fotografar(apagadas: Bool) -> (XCUIScreenshot, CGRect, CGFloat) {
+                    let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
+                                       argumentos: argumentos + (apagadas ? ["-custta.marcasApagadas", "YES"] : []))
+                    let faixa = app.elemento("simFaixa")
+                    XCTAssertTrue(faixa.waitForExistence(timeout: 30), "\(nome): a aba não abriu")
+                    Thread.sleep(forTimeInterval: 2)                   // o vidro e a rolagem assentam
+                    let foto = XCUIScreen.main.screenshot()
+                    // As marcas passam da faixa: 8 pt em cima e embaixo, e o ponto da venda, 15 em cima.
+                    let quadro = faixa.frame.insetBy(dx: -4, dy: -18), largura = app.frame.width
+                    app.terminate()
+                    return (foto, quadro, largura)
+                }
+                let (normal, quadro, largura) = fotografar(apagadas: false)
+                let (semMarcas, _, _) = fotografar(apagadas: true)
+                let imagem = normal.image.cgImage!
+                let escala = CGFloat(imagem.width) / largura
+                let marcas: [LaudoDeContraste.Palavra]
+                do {
+                    marcas = try LaudoDeContraste.medirMarcas(normal: Retrato(imagem), semMarcas: Retrato(semMarcas.image.cgImage!),
+                                                              escala: escala, em: [quadro])
+                } catch {
+                    XCTFail("\(nome): \(error)")
+                    continue
+                }
+                // O custo, a venda (a barra com o ponto) e os traços do empate.
+                XCTAssertGreaterThanOrEqual(marcas.count, 3, "\(nome): \(marcas.map(\.corHex))")
+                anexar(nome, normal.image, marcas, escala, portao: Self.portaoDasMarcas, tipo: "marcas")
+                Swift.print(String(format: "marcas | %@ | %d marcas | pior nota %.2f", nome, marcas.count, marcas.map(\.nota).min() ?? 0))
+                falhas += marcas.filter { $0.nota < Self.portaoDasMarcas }.map { m in
+                    "\(nome): marca \(m.corHex) em \(Int(m.caixa.minX)),\(Int(m.caixa.minY)) fica em "
+                        + String(format: "%.2f:1 (pior pixel %.2f:1)", m.nota, m.minimo)
+                }
+            }
+        }
+        XCTAssertTrue(falhas.isEmpty, "Abaixo de \(Self.portaoDasMarcas):1:\n" + falhas.joined(separator: "\n"))
+    }
+
     // As rolagens das cenas, em pontos, medidas no 18 Pro (402 × 874): cada uma deixa o assunto inteiro entre a borda de cima
     // (140 pt) e a de baixo (734), e o `assunto` de cada cena confere isso antes do print, em qualquer aparelho. A do
     // veredito deixa a obra e o preço à vista, para o toque; a da tabela é quase o fim da tela.
diff --git a/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md b/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
index 2ec1053..b69f863 100644
--- a/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
+++ b/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
@@ -131,6 +131,8 @@ do marco 1 nas mesmas obras.
 - [ ] VoiceOver, na conta: o veredito é um elemento só, com a frase inteira; a faixa é uma imagem com os três valores; cada
   linha da tabela fala o nome e os dois valores.
 - [ ] Controle por Voz ("Mostrar nomes"): "Tocar Obra", "Tocar Se eu vender por", "Tocar Um mês a mais" e "Tocar OK".
-- [ ] No escuro e no claro, nos vidros Transparente e Fosco: as três marcas da faixa se distinguem do trilho e da parte
-  hachurada, e o "OK" das teclas se lê. Com Reduzir transparência, os blocos e as teclas ficam sólidos.
+- [ ] No escuro e no claro, nos vidros Transparente e Fosco: as três marcas da faixa se distinguem do trilho, e o "OK" das
+  teclas se lê. A parte hachurada começa um pouco depois do tracejado e abre uma fenda onde passa a venda (decisão de
+  24/11): diga se a venda ainda se lê como "dentro" da parte hachurada. Com Reduzir transparência, os blocos e as teclas
+  ficam sólidos.
 - [ ] Com Aumentar contraste, a aba inteira continua legível, e os blocos verde e âmbar não mudam de cor.
```

### Tarefa 19: apagar como primeira tecla limpa o preço do "Vale a pena?"

**Commit das fatias:** `4bb0cd9` · **Mensagem:** `feat: apagar como primeira tecla limpa o preço do "Vale a pena?"`

Com o valor à vista nas teclas do preço, o apagar antes de qualquer dígito não fazia nada: a digitação parte do zero, e apagar o zero não muda o valor. Por decisão do Giovani de 24/11 ("apagar limpa o campo"), ele agora deixa o campo vazio, como apagar tudo: aparece a frase do site, o campo não volta para a venda estimada, e a tecla seguinte parte do zero. O 0 e o 00 como primeira tecla seguem sem fazer nada, porque sobre eles não houve decisão.

A regra fica no núcleo, em PrecoNasTeclas.tocar(_:), que diz o que cada tecla faz com o campo. A GradeDeTeclas ganha uma regra opcional de quem a usa; sem ela, o teclado de valor segue igual. O checklist do aparelho ganha o item.

**Prova:** Núcleo: vermelho por asserção com o esqueleto (a regra de antes), depois 306 testes em 48 suítes; 2 mutações pegas (o apagar limpando sempre; qualquer primeira tecla limpando). Tela: `ValeAPenaUITests` 15 de 15 no iOS 27 e no 26.5; `testOApagarNaPrimeiraTeclaLimpaOCampo` cai com a regra tirada do núcleo. Guardas do `tests/app-ios.test.cjs` 71 de 71 (o trecho do teclado de valor que a guarda fixa ficou igual).

**Arquivos:**

```
 app-ios/Custta/Analise/TeclasDoPreco.swift         | 15 ++++----
 app-ios/Custta/Identidade/TecladoDeValor.swift     | 10 +++++-
 .../Sources/CusttaNucleo/Simulador.swift           | 12 ++++++-
 .../CusttaNucleoTests/PrecoNasTeclasTests.swift    | 42 +++++++++++++++++-----
 .../CusttaUITests/Analise/ValeAPenaUITests.swift   | 16 +++++++++
 ...6-10-29-app-nativo-etapa4-checklist-aparelho.md |  2 ++
 6 files changed, 80 insertions(+), 17 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Analise/TeclasDoPreco.swift b/app-ios/Custta/Analise/TeclasDoPreco.swift
index c42dc0d..914df73 100644
--- a/app-ios/Custta/Analise/TeclasDoPreco.swift
+++ b/app-ios/Custta/Analise/TeclasDoPreco.swift
@@ -4,10 +4,10 @@ import CusttaNucleo
 /* As teclas do preço do "Vale a pena?" (etapa 4, PR 4a; mockup aprovado, parte 2, `sim-teclado`): tomam o lugar da cápsula de
    abas enquanto a pessoa digita o "Se eu vender por". Uma faixa da Folha com os cantos de cima redondos, a barra ("Preço de
    venda" e "OK") e as teclas do teclado de valor da etapa 3 (a GradeDeTeclas encaixada: os centavos entram pela direita, com
-   "00" e apagar), num campo só, sem ‹ ›. O que a digitação faz com o campo é do núcleo (`PrecoNasTeclas`, decisão do Giovani
-   de 24/11): o valor fica à vista, a primeira tecla o substitui e o OK sem digitar deixa tudo como estava. A conta da tela
-   acompanha cada tecla, como no site. Entram na área segura de baixo da tela da aba (`safeAreaInset`), como o "Salvar" das
-   folhas: é por ela que a rolagem sabe onde as teclas começam. */
+   "00" e apagar), num campo só, sem ‹ ›. O que cada tecla faz com o campo é do núcleo (`PrecoNasTeclas`, decisões do Giovani
+   de 24/11): o valor fica à vista, a primeira tecla o substitui, o apagar como primeira tecla limpa o campo e o OK sem
+   digitar deixa tudo como estava. A conta da tela acompanha cada tecla, como no site. Entram na área segura de baixo da tela
+   da aba (`safeAreaInset`), como o "Salvar" das folhas: é por ela que a rolagem sabe onde as teclas começam. */
 struct TeclasDoPreco: View {
     @Binding var campos: CamposDoSimulador
     let ok: () -> Void
@@ -40,8 +40,11 @@ struct TeclasDoPreco: View {
             }
             .padding(.horizontal, 8)
             .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
-            GradeDeTeclas(centavos: Binding(get: { preco.centavos }, set: { campos.precoDigitado = preco.digitar($0) }),
-                          tamanho: .encaixado)
+            GradeDeTeclas(centavos: .constant(preco.centavos), tamanho: .encaixado) { tecla in
+                guard let reais = preco.tocar(tecla) else { return nil }
+                campos.precoDigitado = reais
+                return preco.centavos
+            }
         }
         .padding(.horizontal, 12)
         .padding(.top, 4)
diff --git a/app-ios/Custta/Identidade/TecladoDeValor.swift b/app-ios/Custta/Identidade/TecladoDeValor.swift
index 60cb2b9..be1def7 100644
--- a/app-ios/Custta/Identidade/TecladoDeValor.swift
+++ b/app-ios/Custta/Identidade/TecladoDeValor.swift
@@ -48,10 +48,14 @@ enum TamanhoDasTeclas: Sendable {
 }
 
 /// As doze teclas do teclado de valor e o que cada uma faz com os centavos: a regra do núcleo (o teto e a tecla ignorada) e
-/// o valor novo falado pelo VoiceOver a cada tecla. Serve ao TecladoDeValor e ao TecladoEncaixado.
+/// o valor novo falado pelo VoiceOver a cada tecla. Serve ao TecladoDeValor, ao TecladoEncaixado e às teclas do preço do
+/// "Vale a pena?", que trazem regra própria.
 struct GradeDeTeclas: View {
     @Binding var centavos: Int
     let tamanho: TamanhoDasTeclas
+    /// A regra de quem usa, no lugar da do teclado de valor: devolve os centavos novos, ou nil quando a tecla não muda nada.
+    /// Com ela, os centavos do binding não são lidos: quem usa guarda os seus.
+    var regra: ((TeclaDeValor) -> Int?)? = nil
 
     static let linhas: [[TeclaDeValor]] = [
         [.digito(1), .digito(2), .digito(3)],
@@ -76,6 +80,10 @@ struct GradeDeTeclas: View {
     }
 
     private func tocar(_ tecla: TeclaDeValor) {
+        if let regra {
+            if let novo = regra(tecla) { AccessibilityNotification.Announcement(fmtCentavos(novo)).post() }
+            return
+        }
         let novo = aplicarTecla(centavos, tecla)
         guard novo != centavos else { return }
         centavos = novo
diff --git a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
index c44270b..782b42a 100644
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
@@ -223,7 +223,7 @@ public struct CamposDoSimulador: Equatable, Sendable {
     }
 }
 
-/* O preço nas teclas do "Vale a pena?" (decisão do Giovani de 24/11/2026; o mockup só desenha as teclas com o campo vazio).
+/* O preço nas teclas do "Vale a pena?" (decisões do Giovani de 24/11/2026; o mockup só desenha as teclas com o campo vazio).
    As teclas abrem com o valor do campo à vista; a primeira tecla o substitui: a digitação parte do zero, e não do valor que
    estava, que quase sempre é a venda estimada (com os centavos entrando pela direita, um dígito a mais faria de
    R$ 1.450.000,00 R$ 14.500.000,0X). O OK sem digitar deixa os campos como estavam, com o preço ainda acompanhando a venda
@@ -237,6 +237,16 @@ public struct PrecoNasTeclas: Equatable, Sendable {
 
     public init() {}
 
+    /// Uma tecla: devolve o preço novo, em reais, para o campo, ou nil quando a tecla não muda nada. O apagar como primeira
+    /// tecla limpa o campo ("apagar limpa o campo", decisão do Giovani de 24/11); as outras seguem a regra do teclado de
+    /// valor, a partir do zero. O 0 e o 00 como primeira tecla não mudam nada: sobre eles, ele não decidiu.
+    public mutating func tocar(_ tecla: TeclaDeValor) -> Double? {
+        if tecla == .apagar && !digitou { return digitar(0) }
+        let novo = aplicarTecla(centavos, tecla)
+        guard novo != centavos else { return nil }
+        return digitar(novo)
+    }
+
     /// As teclas mudaram o valor: guarda os centavos e devolve o preço, em reais, para o campo. Zero é o campo apagado.
     public mutating func digitar(_ centavos: Int) -> Double {
         self.centavos = max(0, centavos)
diff --git a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PrecoNasTeclasTests.swift b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PrecoNasTeclasTests.swift
index 6712088..fd7b8b9 100644
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PrecoNasTeclasTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PrecoNasTeclasTests.swift
@@ -1,9 +1,10 @@
 import Testing
 @testable import CusttaNucleo
 
-/* O preço nas teclas do "Vale a pena?" (decisão do Giovani de 24/11/2026): as teclas abrem com o valor do campo à vista, a
-   primeira tecla o substitui e o OK sem digitar deixa os campos como estavam. Cada teste toca as teclas como a grade do app
-   faz: aplica a regra do teclado aos centavos das teclas e só entrega o valor quando ele muda. */
+/* O preço nas teclas do "Vale a pena?" (decisões do Giovani de 24/11/2026): as teclas abrem com o valor do campo à vista, a
+   primeira tecla o substitui, o apagar como primeira tecla limpa o campo e o OK sem digitar deixa os campos como estavam.
+   Cada teste toca as teclas como a grade do app faz: pergunta ao `PrecoNasTeclas` o que a tecla faz e só grava o preço
+   quando ele devolve um. */
 struct PrecoNasTeclasTests {
     private let hoje = "2026-10-12"
 
@@ -20,11 +21,9 @@ struct PrecoNasTeclasTests {
         simulacaoNaTela(campos, obras: obras, hoje: hoje, taxa: 1).preco
     }
 
-    /// Uma tecla, como a `GradeDeTeclas`: a regra do teclado sobre os centavos das teclas, e o campo só muda se o valor mudou.
+    /// Uma tecla, como as `TeclasDoPreco`: o campo só muda quando a tecla devolve um preço.
     private func tocar(_ tecla: TeclaDeValor, _ teclas: inout PrecoNasTeclas, _ campos: inout CamposDoSimulador) {
-        let novo = aplicarTecla(teclas.centavos, tecla)
-        guard novo != teclas.centavos else { return }
-        campos.precoDigitado = teclas.digitar(novo)
+        if let preco = teclas.tocar(tecla) { campos.precoDigitado = preco }
     }
 
     @Test func oOkSemDigitarDeixaOsCamposComoEstavam() {
@@ -70,9 +69,10 @@ struct PrecoNasTeclasTests {
         #expect(campos.precoDigitado == 145_000)
     }
 
-    @Test func oZeroEOApagarNaPrimeiraTeclaNaoMudamNada() {
+    /// O 0 e o 00 como primeira tecla seguem sem fazer nada: o Giovani decidiu só o apagar (24/11).
+    @Test func oZeroEOZeroZeroNaPrimeiraTeclaNaoMudamNada() {
         let a = obra("a", estimada: 300_000)
-        for tecla in [TeclaDeValor.digito(0), .duploZero, .apagar] {
+        for tecla in [TeclaDeValor.digito(0), .duploZero] {
             var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
             tocar(tecla, &teclas, &campos)
             #expect(!teclas.digitou, "\(tecla.nome)")
@@ -81,6 +81,30 @@ struct PrecoNasTeclasTests {
         }
     }
 
+    /// "Apagar limpa o campo" (decisão do Giovani de 24/11): com o valor à vista, o apagar como primeira tecla deixa o campo
+    /// vazio, como apagar tudo; a tecla seguinte parte do zero, e outro apagar no campo vazio não faz nada.
+    @Test func oApagarNaPrimeiraTeclaLimpaOCampo() {
+        let a = obra("a", estimada: 300_000), b = obra("b", estimada: 180_000)
+        var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
+        tocar(.apagar, &teclas, &campos)
+        #expect(teclas.digitou)
+        #expect(teclas.centavos == 0)
+        #expect(campos.precoDigitado == 0)
+        #expect(precoNaTela(campos, [a, b]) == nil)
+        campos.obraId = "b"
+        #expect(precoNaTela(campos, [a, b]) == nil, "campo tocado: não volta para a venda estimada")
+        #expect(teclas.tocar(.apagar) == nil, "o apagar no campo vazio não faz nada")
+        tocar(.digito(5), &teclas, &campos)
+        #expect(campos.precoDigitado == 0.05)
+    }
+
+    @Test func tambemLimpaOPrecoQueAPessoaJaTinhaDigitado() {
+        var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
+        campos.precoDigitado = 250_000
+        tocar(.apagar, &teclas, &campos)
+        #expect(campos.precoDigitado == 0)
+    }
+
     @Test func digitarEApagarTudoDeixaOCampoVazio() {
         let a = obra("a", estimada: 300_000), b = obra("b", estimada: 180_000)
         var campos = CamposDoSimulador(), teclas = PrecoNasTeclas()
diff --git a/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift b/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift
index 022eb00..92efd86 100644
--- a/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift
+++ b/app-ios/CusttaUITests/Analise/ValeAPenaUITests.swift
@@ -230,6 +230,22 @@ final class ValeAPenaUITests: XCTestCase {
         XCTAssertEqual(preco.value as? String, "sem preço", "nem trocando para uma obra com venda estimada")
     }
 
+    /// "Apagar limpa o campo" (decisão do Giovani de 24/11): com o valor à vista, o apagar como primeira tecla deixa o campo
+    /// vazio, com a frase do site, e o OK mantém o campo vazio.
+    @MainActor func testOApagarNaPrimeiraTeclaLimpaOCampo() {
+        let app = abrirAAba()
+        let preco = app.elemento("simPreco"), ok = app.buttons["teclasDoPreco-ok"]
+        preco.tap()
+        XCTAssertTrue(ok.waitForExistence(timeout: 5), "as teclas do preço")
+        XCTAssertEqual(preco.value as? String, "R$\u{00A0}1.450.000,00", "o valor à vista")
+        app.buttons["tecla-del"].tap()
+        XCTAssertEqual(preco.value as? String, "sem preço", "o apagar como primeira tecla limpa o campo")
+        XCTAssertTrue(app.elemento("simSemPreco").waitForExistence(timeout: 5), "sem preço, a frase do site")
+        ok.tap()
+        XCTAssertTrue(app.buttons["aba-valeAPena"].waitForExistence(timeout: 5), "o OK devolve a cápsula")
+        XCTAssertEqual(preco.value as? String, "sem preço", "o campo limpo fica limpo depois do OK")
+    }
+
     /// Escolhe a obra no menu logo depois do OK das teclas. O OK devolve a cápsula antes de a rolagem assentar, e o toque no
     /// menu nesse meio se perdia; e a escolha chega depois de o menu fechar, então a leitura sem espera pegava a obra de antes
     /// (Lupa, no iOS 26.5: 1 queda em 25 e 2 em 40). Espera as teclas saírem, toca de novo se o item não aparecer, como o
diff --git a/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md b/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
index b69f863..0be9aa1 100644
--- a/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
+++ b/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
@@ -102,6 +102,8 @@ do marco 1 nas mesmas obras.
   substitui o valor (não emenda nele), os centavos entram pela direita, e a conta acompanha cada tecla. "OK" fecha as
   teclas, e a cápsula volta. Abrir e dar "OK" sem digitar deixa tudo como estava. Diga se o valor à vista, com o cursor
   depois dele, deixa claro que o próximo dígito substitui (o mockup só desenha o campo vazio).
+- [ ] Com o valor à vista, toque em apagar antes de qualquer dígito: o campo fica vazio, com a frase do site, e continua
+  vazio depois do "OK" (decisão de 24/11). O 0 e o 00 como primeira tecla não fazem nada.
 - [ ] Apague o preço até o fim: o campo fica com "R$ 0,00" apagado, e aparece "Digite o preço de venda pra ver a conta.". Ele
   não volta para a venda estimada, nem trocando de obra. Fechando e abrindo o app, volta.
 - [ ] O − e o + andam de um em um mês; o − para em 0 e o + em 120, e a frase do bloco acompanha ("vendendo hoje", "vendendo
```

### Tarefa 20: laudo das marcas da faixa confere cada marca pela forma

**Commit das fatias:** `9ef1661` · **Mensagem:** `test: laudo das marcas da faixa confere cada marca pela forma`

O laudo das marcas da faixa do "Vale a pena?" só pedia três manchas ou mais, e os traços do tracejado do empate sozinhos já dão sete: com a venda sumida, ele passaria. Agora confere cada marca pela forma da caixa: a venda (a barra com o ponto de 12 pt), o custo (a barra fina que passa a faixa) e os traços do empate. Achado da Lupa na revisão da zona recortada.

**Prova:** Verde no iOS 27 e no 26.5. Três mutações pegas, uma por marca: a venda escondida ("a venda": 0 em vez de 1), o custo escondido ("o custo": 0 em vez de 1) e o tracejado escondido ("os traços do empate": 0, mínimo 5). As faixas de altura das caixas foram medidas no 18 Pro e no 26.5, não no Pro Max.

**Arquivos:**

```
 app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift b/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift
index a2b4934..be00419 100644
--- a/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift
+++ b/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift
@@ -123,8 +123,15 @@ final class LeituraDaAnaliseUITests: XCTestCase, LaudoDeLeitura {
                     XCTFail("\(nome): \(error)")
                     continue
                 }
-                // O custo, a venda (a barra com o ponto) e os traços do empate.
-                XCTAssertGreaterThanOrEqual(marcas.count, 3, "\(nome): \(marcas.map(\.corHex))")
+                // As três marcas, cada uma pela forma (caixas em pontos; a faixa tem 46 de altura): a venda é a barra com o
+                // ponto de 12 pt, 69 de altura; o custo, a barra fina de 58; o empate, os traços de 5 pt. Só contar manchas
+                // não basta: os traços do empate sozinhos já dão sete, e a venda sumida passaria.
+                let formas = marcas.map { "\(Int($0.caixa.width))×\(Int($0.caixa.height))" }
+                XCTAssertEqual(marcas.filter { $0.caixa.width >= 10 && $0.caixa.height >= 60 }.count, 1, "\(nome): a venda, em \(formas)")
+                XCTAssertEqual(marcas.filter { $0.caixa.width <= 5 && (50..<60).contains($0.caixa.height) }.count, 1,
+                               "\(nome): o custo, em \(formas)")
+                XCTAssertGreaterThanOrEqual(marcas.filter { $0.caixa.width <= 5 && $0.caixa.height <= 6 }.count, 5,
+                                            "\(nome): os traços do empate, em \(formas)")
                 anexar(nome, normal.image, marcas, escala, portao: Self.portaoDasMarcas, tipo: "marcas")
                 Swift.print(String(format: "marcas | %@ | %d marcas | pior nota %.2f", nome, marcas.count, marcas.map(\.nota).min() ?? 0))
                 falhas += marcas.filter { $0.nota < Self.portaoDasMarcas }.map { m in
```

### Tarefa 21: VoiceOver fala "sem preço" quando as teclas limpam o preço do "Vale a pena?"

**Commit das fatias:** `a163cc8` · **Mensagem:** `fix: VoiceOver fala "sem preço" quando as teclas limpam o preço do "Vale a pena?"`

Depois do apagar que limpa o campo, ou de apagar tudo, o VoiceOver falava "0,00", o valor do teclado de valor, enquanto a linha do preço dizia "sem preço". Agora a fala acompanha a linha: o campo vazio fala "sem preço", o mesmo texto do valor dela, numa constante só.

O que cada tecla grava nos campos e o que ela fala ficam em TeclasDoPreco.tocar, com teste de unidade próprio; a regra opcional da GradeDeTeclas passa a devolver o texto falado. Sem regra, o teclado de valor fala como antes.

**Prova:** `TeclasDoPrecoTests` (4 testes): vermelho com a fala de antes ("0,00" no lugar de "sem preço"), verde depois, no iOS 27 e no 26.5; `testOApagarNaPrimeiraTeclaLimpaOCampo` e `testAPrimeiraTeclaSubstituiOValorEAContaAcompanha` verdes nos dois; guardas Node 71 de 71. O anúncio em si não é lido por teste: o teste prova o texto que a grade recebe.

**Arquivos:**

```
 app-ios/Custta/Analise/TeclasDoPreco.swift         | 17 +++++++----
 app-ios/Custta/Analise/ValeAPenaView.swift         |  2 +-
 app-ios/Custta/Identidade/TecladoDeValor.swift     |  8 ++---
 .../CusttaTests/Analise/TeclasDoPrecoTests.swift   | 35 ++++++++++++++++++++++
 4 files changed, 52 insertions(+), 10 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Analise/TeclasDoPreco.swift b/app-ios/Custta/Analise/TeclasDoPreco.swift
index 914df73..d6c570b 100644
--- a/app-ios/Custta/Analise/TeclasDoPreco.swift
+++ b/app-ios/Custta/Analise/TeclasDoPreco.swift
@@ -40,11 +40,7 @@ struct TeclasDoPreco: View {
             }
             .padding(.horizontal, 8)
             .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
-            GradeDeTeclas(centavos: .constant(preco.centavos), tamanho: .encaixado) { tecla in
-                guard let reais = preco.tocar(tecla) else { return nil }
-                campos.precoDigitado = reais
-                return preco.centavos
-            }
+            GradeDeTeclas(centavos: .constant(preco.centavos), tamanho: .encaixado) { Self.tocar($0, &preco, &campos) }
         }
         .padding(.horizontal, 12)
         .padding(.top, 4)
@@ -57,6 +53,17 @@ struct TeclasDoPreco: View {
         .accessibilityIdentifier("teclasDoPreco")
     }
 
+    /// O valor da linha do preço com o campo vazio, e o que o VoiceOver fala quando uma tecla o deixa assim.
+    static let semPreco = "sem preço"
+
+    /// Uma tecla: o que o núcleo faz com o campo, gravado nos campos, e o que o VoiceOver fala; nil quando a tecla não muda
+    /// nada. O campo que fica vazio fala o mesmo que a linha do preço diz, e não o "0,00" do teclado de valor.
+    static func tocar(_ tecla: TeclaDeValor, _ preco: inout PrecoNasTeclas, _ campos: inout CamposDoSimulador) -> String? {
+        guard let reais = preco.tocar(tecla) else { return nil }
+        campos.precoDigitado = reais
+        return reais > 0 ? fmtCentavos(preco.centavos) : semPreco
+    }
+
     /// A Folha, como a das folhas do app: a cor do token sobre o desfoque do que rola atrás; com "Reduzir transparência",
     /// opaca, sobre o Fundo. Sem a sombra de cima do mockup (preto a 35%): o app não tem token de sombra de painel, e cor
     /// solta não entra.
diff --git a/app-ios/Custta/Analise/ValeAPenaView.swift b/app-ios/Custta/Analise/ValeAPenaView.swift
index 27e9d56..f8b2902 100644
--- a/app-ios/Custta/Analise/ValeAPenaView.swift
+++ b/app-ios/Custta/Analise/ValeAPenaView.swift
@@ -157,7 +157,7 @@ struct CamposDoValeAPena: View {
         .buttonStyle(.plain)
         .accessibilityElement(children: .ignore)
         .accessibilityLabel("Se eu vender por")
-        .accessibilityValue(tela.preco.map { moeda($0) } ?? "sem preço")
+        .accessibilityValue(tela.preco.map { moeda($0) } ?? TeclasDoPreco.semPreco)
         .accessibilityAddTraits(.isButton)
         .accessibilityIdentifier("simPreco")
     }
diff --git a/app-ios/Custta/Identidade/TecladoDeValor.swift b/app-ios/Custta/Identidade/TecladoDeValor.swift
index be1def7..2a714eb 100644
--- a/app-ios/Custta/Identidade/TecladoDeValor.swift
+++ b/app-ios/Custta/Identidade/TecladoDeValor.swift
@@ -53,9 +53,9 @@ enum TamanhoDasTeclas: Sendable {
 struct GradeDeTeclas: View {
     @Binding var centavos: Int
     let tamanho: TamanhoDasTeclas
-    /// A regra de quem usa, no lugar da do teclado de valor: devolve os centavos novos, ou nil quando a tecla não muda nada.
-    /// Com ela, os centavos do binding não são lidos: quem usa guarda os seus.
-    var regra: ((TeclaDeValor) -> Int?)? = nil
+    /// A regra de quem usa, no lugar da do teclado de valor: faz o que a tecla faz e devolve o que o VoiceOver fala, ou nil
+    /// quando a tecla não muda nada. Com ela, os centavos do binding não são lidos: quem usa guarda os seus.
+    var regra: ((TeclaDeValor) -> String?)? = nil
 
     static let linhas: [[TeclaDeValor]] = [
         [.digito(1), .digito(2), .digito(3)],
@@ -81,7 +81,7 @@ struct GradeDeTeclas: View {
 
     private func tocar(_ tecla: TeclaDeValor) {
         if let regra {
-            if let novo = regra(tecla) { AccessibilityNotification.Announcement(fmtCentavos(novo)).post() }
+            if let fala = regra(tecla) { AccessibilityNotification.Announcement(fala).post() }
             return
         }
         let novo = aplicarTecla(centavos, tecla)
diff --git a/app-ios/CusttaTests/Analise/TeclasDoPrecoTests.swift b/app-ios/CusttaTests/Analise/TeclasDoPrecoTests.swift
new file mode 100644
index 0000000..44169c7
--- /dev/null
+++ b/app-ios/CusttaTests/Analise/TeclasDoPrecoTests.swift
@@ -0,0 +1,35 @@
+import Testing
+import CusttaNucleo
+@testable import Custta
+
+/* O que as teclas do preço do "Vale a pena?" gravam nos campos e o que o VoiceOver fala a cada tecla. A fala acompanha a
+   linha do preço: com o campo vazio, "sem preço", como o valor dela, e não o "0,00" do teclado de valor. */
+@MainActor
+struct TeclasDoPrecoTests {
+    @Test func oApagarQueLimpaFalaSemPreco() {
+        var preco = PrecoNasTeclas(), campos = CamposDoSimulador()
+        #expect(TeclasDoPreco.tocar(.apagar, &preco, &campos) == "sem preço")
+        #expect(campos.precoDigitado == 0)
+        #expect(TeclasDoPreco.semPreco == "sem preço", "o mesmo texto do valor da linha do preço")
+    }
+
+    @Test func apagarTudoTambemFalaSemPreco() {
+        var preco = PrecoNasTeclas(), campos = CamposDoSimulador()
+        #expect(TeclasDoPreco.tocar(.digito(7), &preco, &campos) == "0,07")
+        #expect(TeclasDoPreco.tocar(.apagar, &preco, &campos) == "sem preço")
+    }
+
+    @Test func cadaDigitoFalaOValorNovo() {
+        var preco = PrecoNasTeclas(), campos = CamposDoSimulador()
+        for tecla in [TeclaDeValor.digito(8), .duploZero, .duploZero, .duploZero] { _ = TeclasDoPreco.tocar(tecla, &preco, &campos) }
+        #expect(campos.precoDigitado == 80_000)
+        #expect(TeclasDoPreco.tocar(.digito(0), &preco, &campos) == "800.000,00")
+    }
+
+    @Test func aTeclaQueNaoMudaNadaNaoFala() {
+        var preco = PrecoNasTeclas(), campos = CamposDoSimulador()
+        #expect(TeclasDoPreco.tocar(.digito(0), &preco, &campos) == nil)
+        #expect(TeclasDoPreco.tocar(.duploZero, &preco, &campos) == nil)
+        #expect(campos.precoDigitado == nil)
+    }
+}
```

### Tarefa 22: laudo das marcas da faixa com a venda abaixo do banco

**Commit das fatias:** `7818ea5` · **Mensagem:** `test: laudo das marcas da faixa com a venda abaixo do banco`

O laudo das marcas da faixa do "Vale a pena?" só fotografava a venda dentro da zona hachurada. Agora roda também a cena com a venda abaixo do banco, fora da zona, sobre o trilho, com o mesmo portão de 3:1 nos dois temas e nos dois vidros. A cena confere a pílula ("abaixo do banco") antes do print, para não passar com a cena errada.

O preço da cena entra por um gancho de Debug novo, -custta.simPreco, ao lado do -custta.simMeses no simuladorInicial: sem ele, o laudo teria de tocar nas teclas antes de cada print.

**Prova:** As duas cenas (venda na zona e abaixo do banco) verdes no iOS 27 (pior nota 4,96:1) e no 26.5 (5,72:1); no print, a venda à esquerda do custo, sobre o trilho. Com o gancho `-custta.simPreco` ignorado, a cena cai pela pílula ("acima do banco").

**Arquivos:**

```
 app-ios/Custta/Telas/PrincipalView.swift           |  5 +-
 .../Analise/LeituraDaAnaliseUITests.swift          | 95 ++++++++++++----------
 2 files changed, 56 insertions(+), 44 deletions(-)
```

**Mudança:**

```diff
diff --git a/app-ios/Custta/Telas/PrincipalView.swift b/app-ios/Custta/Telas/PrincipalView.swift
index 9de8787..327591d 100644
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -193,11 +193,14 @@ extension PrincipalView {
     #endif
 
     /// Os campos com que o "Vale a pena?" abre: os do núcleo, com os meses em 0. Em Debug, `-custta.simMeses <n>` já abre
-    /// com os meses andados, para o teste de tela chegar ao limite de 120 sem 120 toques.
+    /// com os meses andados, para o teste de tela chegar ao limite de 120 sem 120 toques, e `-custta.simPreco <reais>`, com
+    /// o preço digitado, para o laudo fotografar a venda abaixo do banco sem tocar nas teclas.
     static var simuladorInicial: CamposDoSimulador {
         var campos = CamposDoSimulador()
         #if DEBUG
         campos.andarMeses(UserDefaults.standard.integer(forKey: "custta.simMeses"))
+        let preco = UserDefaults.standard.double(forKey: "custta.simPreco")
+        if preco > 0 { campos.precoDigitado = preco }
         #endif
         return campos
     }
diff --git a/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift b/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift
index be00419..9a9c489 100644
--- a/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift
+++ b/app-ios/CusttaUITests/Analise/LeituraDaAnaliseUITests.swift
@@ -92,51 +92,60 @@ final class LeituraDaAnaliseUITests: XCTestCase, LaudoDeLeitura {
     /// O laudo das marcas da faixa "Onde a sua venda cai" (spec da etapa 4, "Laudo das marcas"): o custo, o empate e a venda a
     /// 3:1 com o que fica atrás deles, nos dois temas e nos vidros Transparente e Fosco. Cada cena sai em dois prints, um
     /// normal e um com as marcas apagadas (`-custta.marcasApagadas`, só Debug); a zona, com o recorte em volta das marcas, é
-    /// fundo e fica nos dois. Na Casa Alphaville a venda cai dentro da zona: a fenda está no print.
+    /// fundo e fica nos dois. Duas cenas na Casa Alphaville: com a venda estimada, a venda cai dentro da zona (a fenda está
+    /// no print); com o preço de R$ 800.000,00 (`-custta.simPreco`, só Debug), abaixo do banco, sobre o trilho, fora da zona.
     @MainActor func testMarcasDaFaixaDoValeAPena() {
         var falhas: [String] = []
-        for tema in temas {
-            for vidro in ["transparente", "fosco"] {
-                let nome = "marcas, faixa do vale a pena, \(tema), \(vidro)"
-                let argumentos = ["-custta.tema", tema, "-custta.vidro", vidro, "-custta.rolagem", "\(Self.rolagemDaFaixa)"] + piorMomento
-                func fotografar(apagadas: Bool) -> (XCUIScreenshot, CGRect, CGFloat) {
-                    let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
-                                       argumentos: argumentos + (apagadas ? ["-custta.marcasApagadas", "YES"] : []))
-                    let faixa = app.elemento("simFaixa")
-                    XCTAssertTrue(faixa.waitForExistence(timeout: 30), "\(nome): a aba não abriu")
-                    Thread.sleep(forTimeInterval: 2)                   // o vidro e a rolagem assentam
-                    let foto = XCUIScreen.main.screenshot()
-                    // As marcas passam da faixa: 8 pt em cima e embaixo, e o ponto da venda, 15 em cima.
-                    let quadro = faixa.frame.insetBy(dx: -4, dy: -18), largura = app.frame.width
-                    app.terminate()
-                    return (foto, quadro, largura)
-                }
-                let (normal, quadro, largura) = fotografar(apagadas: false)
-                let (semMarcas, _, _) = fotografar(apagadas: true)
-                let imagem = normal.image.cgImage!
-                let escala = CGFloat(imagem.width) / largura
-                let marcas: [LaudoDeContraste.Palavra]
-                do {
-                    marcas = try LaudoDeContraste.medirMarcas(normal: Retrato(imagem), semMarcas: Retrato(semMarcas.image.cgImage!),
-                                                              escala: escala, em: [quadro])
-                } catch {
-                    XCTFail("\(nome): \(error)")
-                    continue
-                }
-                // As três marcas, cada uma pela forma (caixas em pontos; a faixa tem 46 de altura): a venda é a barra com o
-                // ponto de 12 pt, 69 de altura; o custo, a barra fina de 58; o empate, os traços de 5 pt. Só contar manchas
-                // não basta: os traços do empate sozinhos já dão sete, e a venda sumida passaria.
-                let formas = marcas.map { "\(Int($0.caixa.width))×\(Int($0.caixa.height))" }
-                XCTAssertEqual(marcas.filter { $0.caixa.width >= 10 && $0.caixa.height >= 60 }.count, 1, "\(nome): a venda, em \(formas)")
-                XCTAssertEqual(marcas.filter { $0.caixa.width <= 5 && (50..<60).contains($0.caixa.height) }.count, 1,
-                               "\(nome): o custo, em \(formas)")
-                XCTAssertGreaterThanOrEqual(marcas.filter { $0.caixa.width <= 5 && $0.caixa.height <= 6 }.count, 5,
-                                            "\(nome): os traços do empate, em \(formas)")
-                anexar(nome, normal.image, marcas, escala, portao: Self.portaoDasMarcas, tipo: "marcas")
-                Swift.print(String(format: "marcas | %@ | %d marcas | pior nota %.2f", nome, marcas.count, marcas.map(\.nota).min() ?? 0))
-                falhas += marcas.filter { $0.nota < Self.portaoDasMarcas }.map { m in
-                    "\(nome): marca \(m.corHex) em \(Int(m.caixa.minX)),\(Int(m.caixa.minY)) fica em "
-                        + String(format: "%.2f:1 (pior pixel %.2f:1)", m.nota, m.minimo)
+        let cenas: [(nome: String, pilula: String, argumentos: [String])] = [
+            ("venda na zona", "acima do banco", []),
+            ("venda abaixo do banco", "abaixo do banco", ["-custta.simPreco", "800000"]),
+        ]
+        for cena in cenas {
+            for tema in temas {
+                for vidro in ["transparente", "fosco"] {
+                    let nome = "marcas, faixa do vale a pena, \(cena.nome), \(tema), \(vidro)"
+                    let argumentos = ["-custta.tema", tema, "-custta.vidro", vidro, "-custta.rolagem", "\(Self.rolagemDaFaixa)"]
+                        + piorMomento + cena.argumentos
+                    func fotografar(apagadas: Bool) -> (XCUIScreenshot, CGRect, CGFloat) {
+                        let app = abrirApp(conta: "senha", dados: "analise", abrir: "aba:valeAPena",
+                                           argumentos: argumentos + (apagadas ? ["-custta.marcasApagadas", "YES"] : []))
+                        let faixa = app.elemento("simFaixa")
+                        XCTAssertTrue(faixa.waitForExistence(timeout: 30), "\(nome): a aba não abriu")
+                        XCTAssertEqual(app.elemento("simPilula").label, cena.pilula, "\(nome): a cena")
+                        Thread.sleep(forTimeInterval: 2)                   // o vidro e a rolagem assentam
+                        let foto = XCUIScreen.main.screenshot()
+                        // As marcas passam da faixa: 8 pt em cima e embaixo, e o ponto da venda, 15 em cima.
+                        let quadro = faixa.frame.insetBy(dx: -4, dy: -18), largura = app.frame.width
+                        app.terminate()
+                        return (foto, quadro, largura)
+                    }
+                    let (normal, quadro, largura) = fotografar(apagadas: false)
+                    let (semMarcas, _, _) = fotografar(apagadas: true)
+                    let imagem = normal.image.cgImage!
+                    let escala = CGFloat(imagem.width) / largura
+                    let marcas: [LaudoDeContraste.Palavra]
+                    do {
+                        marcas = try LaudoDeContraste.medirMarcas(normal: Retrato(imagem), semMarcas: Retrato(semMarcas.image.cgImage!),
+                                                                  escala: escala, em: [quadro])
+                    } catch {
+                        XCTFail("\(nome): \(error)")
+                        continue
+                    }
+                    // As três marcas, cada uma pela forma (caixas em pontos; a faixa tem 46 de altura): a venda é a barra com o
+                    // ponto de 12 pt, 69 de altura; o custo, a barra fina de 58; o empate, os traços de 5 pt. Só contar manchas
+                    // não basta: os traços do empate sozinhos já dão sete, e a venda sumida passaria.
+                    let formas = marcas.map { "\(Int($0.caixa.width))×\(Int($0.caixa.height))" }
+                    XCTAssertEqual(marcas.filter { $0.caixa.width >= 10 && $0.caixa.height >= 60 }.count, 1, "\(nome): a venda, em \(formas)")
+                    XCTAssertEqual(marcas.filter { $0.caixa.width <= 5 && (50..<60).contains($0.caixa.height) }.count, 1,
+                                   "\(nome): o custo, em \(formas)")
+                    XCTAssertGreaterThanOrEqual(marcas.filter { $0.caixa.width <= 5 && $0.caixa.height <= 6 }.count, 5,
+                                                "\(nome): os traços do empate, em \(formas)")
+                    anexar(nome, normal.image, marcas, escala, portao: Self.portaoDasMarcas, tipo: "marcas")
+                    Swift.print(String(format: "marcas | %@ | %d marcas | pior nota %.2f", nome, marcas.count, marcas.map(\.nota).min() ?? 0))
+                    falhas += marcas.filter { $0.nota < Self.portaoDasMarcas }.map { m in
+                        "\(nome): marca \(m.corHex) em \(Int(m.caixa.minX)),\(Int(m.caixa.minY)) fica em "
+                            + String(format: "%.2f:1 (pior pixel %.2f:1)", m.nota, m.minimo)
+                    }
                 }
             }
         }
```

## Depois do 4a

As tabelas abaixo são o esqueleto de 23/11, revisto por um revisor independente. As linhas de produção são estimativa, sem medida. Cada tarefa vira commit provado, no iOS 27 e no 26.5 do Mac, antes de entrar neste plano com o código.

### PR 2a: Gráficos, a tela e o anel

**Risco único:** o anel desenhado pelo app (entrada, toque, acessibilidade feita à mão). **Portões:** telas novas (5 jobs de macOS, mais o `portoes` no Ubuntu; tempo ainda não medido), desde que o PR só mexa no núcleo, em `Custta/Analise/` e nas pastas `Analise` dos testes (tarefas 11 e 16 do 4a); um arquivo compartilhado a mais, e roda tudo. **Escondido:** a tela só abre pelo Debug. **Spec:** ~700 a 900 linhas.

| # | Tarefa | Produção (est.) |
|---|---|---|
| 1 | Núcleo: os textos do anel que ainda não existem (resumo do contêiner para o VoiceOver, rótulo de cada item, valor arredondado ao real, o meio do anel, o vazio) | ~90 |
| 2 | O arco como `Shape` (pontas redondas que montam, o aro na ponta, o trilho), com teste da geometria e o modo de marcas apagadas | ~120 |
| 3 | O anel parado: pedaços, cores, placa, o total no meio; 240 pt, 300 na letra máxima | ~140 |
| 4 | A entrada: cada pedaço gira do topo (1,2 s, 0,1 s entre eles), só quando a tela é empurrada; um toque encerra a entrada, e a lista aceita toque já no 1º quadro; com Reduzir movimento, pronto. Prova por rajada de prints | ~90 |
| 5 | O toque C: escolhe, engrossa, apaga os outros pela cor, o 2º toque solta; a faixa de toque com 44 pt ou mais no raio, não só a espessura do traço; "Ver gastos ›" de 44 pt (72 na letra máxima); "Outros" sem o botão | ~120 |
| 6 | A lista: uma linha por tópico, com seta, que abre a folha do tópico; três linhas por tópico na letra máxima; "Inclui R$ … a vencer." | ~130 |
| 7 | A tela e os estados (1 gasto, 1 tópico, tópico pequeno, sem gastos); troca do `DestinoDaAnalise`; a rota sai quando a obra some; dado novo redesenha sem repetir a entrada e avisa o VoiceOver. A acessibilidade do anel: uma lista de itens num contêiner com o resumo, cada item com o quadro do pedaço, o toque duplo que abre o detalhe do tópico, e "Outros" dizendo quantos tópicos junta | ~150 |
| 8 | Testes de tela, cenas do laudo, laudo das marcas do anel, auditoria, lado a lado com os prints | teste |
| 9 | Checklist do aparelho: o anel | docs |

Soma: ~840. Perto do teto. Se as fatias passarem de ~1.000, a lista (tarefa 6) vira um PR seguinte, com a decisão dele.

### PR 2b: evolução e gasto por mês (fecha o marco)

**Risco único:** o gesto de arrastar nos meses, numa tela que rola. **Portões:** tudo. **Escondido:** sem o "Exportar PDF"; nenhuma porta. **Spec:** ~850 a 1.000 linhas; acima disso, a evolução vira um 2c.

| # | Tarefa | Produção (est.) |
|---|---|---|
| 1 | Núcleo: o valor falado do mês, o passo do ajustável, os dados do descritor, os textos da leitura e das legendas | ~120 |
| 2 | A base dos dois gráficos: eixos (rótulos em texto, parados em 19 pt, com a exceção da auditoria por identificador e o teste de largura em 375 pt na letra máxima), grade, placa; a guarda Node que barra texto desenhado em `Canvas` | ~120 |
| 3 | Gasto por mês: barras, mês aceso, parcelas a vencer hachuradas, média, maior e meses, aviso dos 24 meses | ~170 |
| 4 | Evolução: linha com degradê, tracejado "no banco já seria", leitura acima, frase em âmbar do que ficou fora, aviso dos 24 meses também aqui | ~170 |
| 5 | Toque e arrasto: o gráfico inteiro como alvo, o arrasto só assume na horizontal, vibração a cada mês, o fundo para durante o gesto | ~130 |
| 6 | VoiceOver: um elemento ajustável por gráfico, com o descritor e os rótulos de voz; aviso ao VoiceOver quando o dado muda com a tela à vista; prova dentro do processo | ~90 |
| 7 | Medição de quadros: `Shape` contra `Canvas`, com o medidor do protótipo (spec: se o `Shape` perder quadro, só as marcas vão para o `Canvas`) | medida |
| 8 | A barra empilhada da obra abre os Gráficos, com "Gráficos ›" (junta num lugar só a acessibilidade do bloco: untangle 11) | ~40 |
| 9 | Testes, laudo com as marcas, auditoria, laudo inteiro comparado, checklist do marco 2, tag `etapa4-marco-2` | teste |

Soma: ~840 a 1.000. **No limite do 2c.** O spec diz que, se o 2b passar de ~1.000, a evolução vira um 2c, que fecha o marco (`:280`); quem decide é a medida das fatias. A minha estimativa aponta para o limite, e por isso levo a ele a pergunta desde já. Nesse corte, o 2b fica com a base, o gasto por mês, o gesto e o VoiceOver (tarefas 1, 2, 3, 5, 6 e 7), e o 2c traz a evolução. **Leitura minha, que o spec não escreve:** a porta da obra (tarefa 8) iria com o 2c, pela regra do "escondido por ausência" (a porta entra no PR que completa o destino). Custa uma rodada inteira da CI a mais.

### Sondas na CI do iOS 26, antes das tarefas que dependem da VM lenta

Cada uma num ramo `proto/`, num run só com o job dela (`gh workflow run app-ios.yml --ref <ramo>`).

| Sonda | Para qual tarefa | O que prova |
|---|---|---|
| S1 | 2b, tarefa 5 | O arrasto horizontal num gráfico dentro de uma tela que rola: a tela rola quando o dedo começa no gráfico, e o voltar pela borda segue funcionando |
| S2 | 2a, tarefas 5 e 6 | Dois toques espaçados no anel (escolher e soltar) na VM lenta; a lista de 14 tópicos na letra máxima sem `LazyVStack` (o laço de layout do iOS 26) |
| S3 | 4a, tarefas 4 e 9 | A troca da cápsula pelas teclas na aba e o `Menu` dentro do vidro, na letra máxima |
| S4 | 2a e 2b, laudo | As marcas sobre a placa fraca no laudo da CI: o mockup mediu 3,04:1 no pior caso (o verde-água no claro), com folga de 0,04. No marco 1, a CI mediu 0,4 abaixo do Pro Max num texto (o nome da obra no claro: 4,40 contra 4,80); para marca de gráfico não há medida. Se ficar abaixo de 3:1, é cor ou placa, e aí é decisão dele com o Croqui |

### Para o PR que fecha o marco

- Rodar o workflow inteiro pelo botão (`nivel: tudo`) se o filtro não der `tudo` sozinho, o laudo inteiro comparado com o do commit anterior e o laudo no Pro Max.
- A tag `etapa4-marco-2` no merge, e o TestFlight com o OK do Giovani.

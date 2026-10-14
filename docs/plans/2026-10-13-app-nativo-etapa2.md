# Obras e gastos (etapa 2 do app nativo) — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> Neste time: o Forja implementa uma tarefa por vez, o Lupa revisa cada uma antes da próxima; nas tarefas de tela, o Verniz confere o simulador lado a lado com o mockup aprovado. Ninguém faz commit, push ou PR sem o Orquestrador pedir; quando pedir, valem os comandos de commit de cada tarefa.

**Goal:** O app nativo passa a gravar: tela da obra, lançar, editar e apagar gasto, fases e venda, criar, editar e apagar obra, com as regras do site conferidas pelos vetores, num PR do site e três do app que já gravam (um build no TestFlight a cada um, na conta de teste) e um quarto PR do app, de uma tarefa, que passa para a conta real depois do OK do Giovani.

**Architecture:** As regras que hoje só existem no `app.js` passam antes para o `calc.js` e o `dados.js` (PR 0), com a cópia em Swift no `CusttaNucleo` conferida pelos vetores no mesmo PR. O núcleo ganha as mutações sobre o estado; o `Sincronizador.aplicar` troca o estado na hora e grava o documento inteiro, como o site, e a resposta do servidor segue pela pílula de sincronização. As telas novas são a tela da obra (ScrollView com um cartão de vidro por mês e o arrastar próprio), a folha do sistema em passos (NavigationStack dentro da `.sheet`) e o teclado de valor reutilizável.

**Tech Stack:** SwiftUI no iOS 26 (Swift 6 estrito; Xcode 26.6 na CI), Swift Testing, XCTest e XCUITest, pacote `CusttaNucleo`; Node (`node:test`) e Playwright para o site; emuladores do Firebase para a conferência cruzada.

**Spec:** [`docs/specs/2026-10-13-app-nativo-etapa2-design.md`](../specs/2026-10-13-app-nativo-etapa2-design.md), com as correções da seção "O que muda em relação ao spec". Inventário do site, com arquivo e linha do `origin/main` (`7c700a5`): [`2026-10-13-app-nativo-etapa2-inventario.md`](2026-10-13-app-nativo-etapa2-inventario.md). Mockup aprovado: `~/Documents/custta-mockups/nativo/etapa2/` (abrir no Chrome; o `LEIA-ME.md` resume as três partes).

**Como este plano foi escrito.** O código das tarefas 1 a 26 saiu de um protótipo completo dos PRs 0, 1 e 2; o das tarefas 27 a 37, de um protótipo do PR 3 feito em paralelo por um subagente sobre o fim do PR 2 e mesclado depois; o da tarefa 38, do protótipo sem a guarda da conta de teste. Os três estão na branch `proto/etapa2` (`aea9811`, `9a31a39`, `a7e3957`; não é para entrar na `main`). Cada protótipo foi fatiado num commit por tarefa, num clone local, e cada fatia foi conferida sozinha: testes do site (`npm run test:unit` e as suítes de browser que ela muda), guardas em Node, núcleo (`swift test`) e compilação do app com os testes. No fim de cada PR rodaram os testes de tela, o laudo de leitura e as auditorias no 18 Pro e no Pro Max e, nos PRs 2 e 3, a conferência cruzada contra os emuladores. O estado final das fatias de cada PR é idêntico, byte a byte, ao do protótipo. Os diffs aplicam um sobre o outro, na ordem das tarefas, a partir do `origin/main` `7c700a5`; arquivos gerados (`tests/vetores/calc.json`, cores e ícones do catálogo) nunca aparecem no plano: a tarefa diz o comando que os gera.

## Global Constraints

- iOS 26.0 mínimo, iPhone. Nada que só exista no SDK do iOS 27: a CI compila com o Xcode 26.6 (Swift 6.3.3); o Mac do time tem o 27.
- Swift 6 com concorrência estrita e nenhum aviso de compilador novo.
- Nenhuma dependência nova, no app ou no site; nada de runtime novo no browser; CSP do site intacta.
- Português no código, nos identificadores, nos comentários e na interface.
- Cores só por tokens (`scripts/cores-app-ios.mjs`, conferido por `tests/app-ios.test.cjs`); ícones do `icons.js` pelo `scripts/icones-app-ios.mjs`; SF Symbols só onde já se usam (setas, lixeira, relógio, raio e cartão dentro do texto, apagar do teclado e o "+").
- Nunca vidro dentro de vidro: vidro só nos cartões, pílulas e navegação da tela; dentro da folha, tudo sólido (a folha já é o vidro).
- Formato do estado sem chave nova; `firestore.rules` não muda nesta etapa.
- O app grava exatamente o que o site gravaria com as mesmas respostas: regra nova em `calc.js`/`dados.js` entra nos vetores com leitor no núcleo no mesmo PR, e cada mutação passa pela conferência cruzada.
- Textos: os do site, menos os que o mockup aprovado mudou (lista em "Decisões tomadas por recomendação").
- Reduzir movimento respeitado em toda animação (`tests/app-ios.test.cjs`); `lineLimit`/`minimumScaleFactor` só nos componentes da lista fixa da guarda.
- O PR do site só muda arquivos que já existem, mas sobe o `CACHE` do `sw.js` uma vez, no fim (o comentário do topo pede).
- Commits: autor só `Giovani Stuchi <stuchigiovani@gmail.com>`, sem `Co-Authored-By` e sem rodapé; título conventional em português com acento; corpo em prosa; um commit por tarefa; branch e PR, nunca direto na `main`.
- O app grava na conta de teste até o OK do Giovani no checklist do build do PR 3; o PR 4 tira a guarda (`ContaDeTeste`), que no build do TestFlight só deixa gravar em conta com `custta-teste` no e-mail.
- Um simulador por agente (`CUSTTA_SIMULADOR=<udid>`): `D9F432D6` é do Forja; os testes de tela rodam com `-collect-test-diagnostics never`.

## Decisões

### Conselho de 13/10: a lista da obra e a folha em dois passos

As duas decisões que o spec mandou ao conselho passaram por ele (três subagentes Opus com lentes de desempenho e bateria, acessibilidade e legibilidade, e fidelidade ao mockup, à HIG e ao spec; propostas às cegas, crítica cruzada, o Prumo como presidente). Antes, um experimento no simulador (iOS 27) mediu os caminhos. A nota do Maestri "Conselho — lista e folha (etapa 2)" guarda as propostas e as críticas.

**O que o experimento mostrou.** `List` com fundo de vidro por linha dá um vidro por linha, com aro em cada emenda, e 17 a 27 camadas de vidro contra 9; o botão do sistema é uma pílula só com o ícone, e "Apagar" fica cinza fora dela. O `swipeActionsContainer` do iOS 27, fora da `List`, pinta `#FF6769` ignorando a cor (branco a 2,84:1), lê "Apagar, Apagar", parou o voltar pelo meio da tela e não compila no Xcode 26.6. O arrastar próprio (`UIPanGestureRecognizer`) passou em tudo e é o único igual ao mockup. Na folha, o `NavigationStack` dentro da `.sheet` mantém o voltar pela borda; esconder o voltar do sistema mata a borda; a ponte para o "tentou fechar" do UIKit não quebra o SwiftUI; o `confirmationDialog` do iOS 27 virou popover sem "Cancelar".

| Decisão | Escolha | Descartado | Críticas que pesaram |
| --- | --- | --- | --- |
| Lista da obra × `.swipeActions` | `ScrollView` + `LazyVStack`, um cartão de vidro por mês com o vidro como fundo à parte (`CartaoDaLista`); arrastar próprio com a física da `List` (começa só no arrasto horizontal, 20 pt da borda livres para o voltar, abre em −100 pt, estica com resistência, decide pela posição projetada com o impulso, mola sem quique que parte da velocidade normalizada, vibra uma vez em −40 pt); botão "Apagar" de 80 pt no token `Apagar`, crescendo até o AX2, na árvore de acessibilidade, mais a ação "Apagar" no rotor; alerta para o gasto e para a parcela; estado aplicado na hora dentro da animação; fundo parado com folha ou alerta aberto; foco e anúncio do VoiceOver depois de apagar, um depois do outro; tocar com a linha aberta só fecha; rolar fecha | `List` estilizada; `swipeActions` do iOS 27 fora da `List`; `.id(aberto)` no cartão | o `confirmationDialog` preso ao botão vermelho não tem de onde nascer pela ação do VoiceOver e vira popover sem "Continuar editando" (→ `.alert`); botão escondido do VoiceOver tira o "Apagar" do Controle por Voz e do Controle Assistivo (→ botão na árvore); `initialVelocity` em pt/s arremessa a linha (→ normalizada e limitada); o `.id` no cartão mata a animação (→ o vidro de fundo, provado no simulador); "Novo." no rótulo quebra o contrato dos testes e anúncio junto com foco se atropelam (→ sem "Novo." no rótulo; foco, depois anúncio) |
| Folha em dois passos | `NavigationStack(path:)` dentro da `.sheet`; voltar e borda do sistema; × (`Button(role: .close)`) à esquerda na raiz e à direita nos passos de dentro; título em duas linhas na barra (17 semibold e a obra em 13 secundário, até perto de 22 pt, com o Visualizador de Conteúdo Grande); fundo Folha; "Você já preencheu este gasto." num `.alert` ("Descartar gasto" / "Continuar editando") pelo ×, ao puxar a folha (ponte para o `presentationControllerDidAttemptToDismiss`) e pelo escapar do VoiceOver na raiz; no gasto novo pergunta só depois do valor, na edição só se algo mudou; sugestões por um índice montado ao abrir a folha, igual ao do site em todos os vetores; grupos próprios; "Salvar" fixo embaixo, subindo com o teclado | passos próprios (perdem a borda); esconder o voltar do sistema; `Form`; `confirmationDialog` | a ponte guarda o delegado do SwiftUI e o devolve quando a folha desce, com um contador de pontes vivas no teste (o risco era vazar a folha); o `.alert` também para descartar (o popover do iOS 27 não tem "Continuar editando") |

**Exceção nomeada, levada ao Giovani:** os círculos da barra da folha (voltar e ×) são o vidro do sistema, não os sólidos do mockup. Com eles vem o voltar pela borda dentro da folha.

### Conselho de 13/10 (segunda rodada): a dose de vidro e a ordem dos PRs

Duas decisões que o protótipo levantou mudam a cara do app e a ordem do trabalho, e passaram pelo mesmo conselho (três subagentes Opus, propostas às cegas, crítica cruzada, o Prumo como presidente). A nota do Maestri "Conselho — dose de vidro e ordem (etapa 2)" guarda as propostas e as críticas. Antes, o laudo do protótipo da tela da obra mediu, com as doses de 09/10 (45% no Transparente, 20% no Fosco): o cabeçalho do mês em 4,44:1 na lista escura e, com Aumentar contraste, a linha de baixo do gasto em 4,21:1.

| Decisão | Escolha | Descartado | Críticas que pesaram |
| --- | --- | --- | --- |
| C: a dose de vidro na tela da obra | Transparente 50% (era 45%), Fosco 20% como hoje, cabeçalho do mês secundário como no mockup, e com Aumentar contraste o secundário passa a ser o `SecundarioTransparente` em toda dose menos a sólida (Tarefa 10). Medido depois na varredura da lista em seis alturas, nas duas peles, sem e com Aumentar contraste: 18 Pro, pior 4,87 (padrão) e 5,22 (AC); Pro Max, 4,93 e 4,63 | Fosco 30% nos cartões (com a troca do secundário, não precisa, e mudaria a entrada aprovada); cabeçalho do mês na cor do texto (B'); véu local atrás do cabeçalho; dose só da obra | O Aumentar contraste baixava o contraste: o `SecundarioFosco` é 24% mais fraco que o `SecundarioTransparente` sobre o mesmo fundo (achado da lente de acessibilidade, conferido pelas outras duas). Clarear o texto fica fora da escada de 09/10 e contra o "sem clarear o texto" de 10/10, e só conserta a palavra medida: a linha de baixo, o texto mais lido, ficava em 4,90. O 4,56 do topo claro é a etiqueta sólida "estimativa", não vidro. "A só quando uma segunda tela reprovar" abriria exceção por tela. As três lentes terminaram em A mais a troca (C: 1 > 3 > 2) |
| D: a ordem dos PRs | Um PR só do site (0b e 0a em commits separados, uma subida do `CACHE`); o PR 1 começa quando o do site entra em revisão; depois 2 → 3 → 4, com o PR 2 começando pelo núcleo e a gravação (sem tela) até o OK do PR 1 no aparelho; o job do laudo é a primeira tarefa do PR 1; a conta de teste é pedida ao Giovani no dia 0 | 0b → 0a → 1 → 2 → 3 em série; PR 1 primeiro e os do site na espera do aparelho; um segundo implementador | Dois PRs do site são duas rodadas do workflow do app (~50 min cada), duas subidas do `CACHE` (1,28 MB por PWA instalado) e duas prévias; os defeitos corrigidos são raros (o `parseNum` só erra com três casas; a parcela não se perde, volta), então não há urgência nem razão para esperar; com o PR 1 primeiro, o PR 2 esperaria o OK do aparelho (o checklist do build 1.2 ainda está aberto); os emuladores têm portas fixas e o Mac já tem quatro simuladores (contra o segundo implementador). Duas lentes em (iv) (D: 2 > 3 > 1); a terceira manteve o PR 1 primeiro, mas adotou o PR único do site |

Dois achados do laudo do PR 3 mesclado entraram na mesma tarefa, pelo mesmo degrau da escada (escurecimento primeiro, no menor passo que passa): com o + na lista de obras a cápsula de abas encolhe e "Ajustes" passava sobre o texto branco do comparativo a 2,75:1 (a etapa 1 passava a 4,58 com a cápsula inteira), então a navegação ganha 30% de escurecimento no escuro; e a etiqueta âmbar ("nada em 30 dias", "Em construção") ficava em 4,42:1 na faixa do véu do topo no Pro Max, então o texto dela ganha o token `AlertaEtiqueta` no claro, porque o `Alerta` é o `--warn` do site e a guarda os mantém iguais.

### Decididas por recomendação

O Giovani delegou em 13/10 ("faça sempre o recomendado"). Ficaram assim:

| Decisão | Escolha | Por quê |
| --- | --- | --- |
| Escopo dos PRs do site | O 0b leva as sugestões, o repetido e a taxa do cartão para o `calc.js` **e** o que o formulário do gasto grava (`conferirGasto`, `gastosLancados`, `gastoEditado`) para o `dados.js`, mais o teclado de valor nos vetores; o 0a leva o que os formulários da obra e da venda gravam (`conferirObra`, `obraNova`, `obraEditada`, `conferirVenda`) e o limite de 300. Cada um traz a cópia em Swift no núcleo, com os leitores dos vetores | O núcleo tem a guarda "todo grupo dos vetores tem leitor": vetor novo sem leitor quebra a CI do app no mesmo PR. E assim o que o app grava fica conferido contra o que o site grava, não só as sugestões |
| Defeitos do site achados no inventário | Corrigidos no 0b (parcela apagada pela folha com a nuvem chegando) e no 0a (área com três casas lida como milhar ao editar) | Os dois perdem dado do usuário; os testes de browser provam o vermelho antes do verde |
| Aviso do limite de 300 | No começo do `formNovaObra` (as quatro entradas do site) | Só no + deixaria passar "+ Nova obra", o + sem obra aberta e o `formGasto` sem obra |
| "O valor precisa ter pelo menos um centavo por parcela" | Não entra | O site nunca mostra (o `parcelamentoCartao` devolve `null` antes, e aparece "Confira valor, parcelas, data e taxa de juros") |
| Resumo do cartão | O texto do site: "10x de R$ 498,00 · Juros do cartão: R$ 0,00 · Total: R$ 4.980,00", e a ajuda do site | O spec manda o resumo do site; o print do mockup ("sem juros · total") era aproximação. Um texto só nos dois lados |
| "Condições originais da compra" | Entra na edição de gasto com juros, abaixo do pagamento, com o texto do site | O mockup não desenhou; sem ela, quem edita uma parcela não sabe que o valor já inclui os juros |
| Alerta de `nao-carregado` | Título com o texto do site ("Carregando suas obras, tente em instantes."; sem rede, "Conecte à internet para carregar suas obras antes de lançar."), mensagem do mockup ("O gasto continua aqui; nada foi salvo ainda.") e "OK" | O texto do site diz o que fazer; a mensagem diz o que o app faz diferente (no site a folha fechava) |
| Obra ou gasto apagados em outro aparelho com a folha aberta | A folha fecha sem gravar | Não há onde gravar; o site fica parado sem mensagem |
| O + da cápsula | Lança gasto numa obra que recebe gasto; some em Ajustes, como o do site, e a cápsula ocupa a largura toda; no PR 2 some também numa obra vendida (a linha "Obra" chega no PR 3); o PR 3 põe "Nova obra" na lista | O + do site também some fora de Início e da obra |
| Ícone do + | SF Symbol `plus` | O "mais" do `icons.js` é o + dentro de um círculo; o mockup desenha o + solto |
| Tópico | Linha que abre a lista dentro da folha: "Usados nesta obra" (os três com mais gastos; no empate, o do gasto mais recente) e "Todos" (os 21 e os próprios, na ordem do site); o gasto novo começa no tópico do último gasto da obra | Opção A aprovada no mockup; regra nova do app, com teste próprio |
| Descrição | Até 500 unidades UTF-16 no próprio campo (o `maxlength` do site), sem partir emoji | Assim a mensagem "Use até 500 caracteres." praticamente não aparece, como no site |
| Repetido | A regra e a assinatura do site; qualquer mudança no formulário desfaz o aviso | No site, mudar o valor não escondia o aviso; aqui a assinatura muda e o botão volta a "Salvar" |
| Depois de salvar | A folha desce, a lista abre o "A vencer" se o gasto foi para lá, rola até ele em dois tempos (o cartão, depois a linha), acende por 2 s (Aceso e a etiqueta "novo" no lançado; editar acende sem etiqueta), vibra (sucesso) e o VoiceOver vai para a linha | Mockup aprovado; os dois tempos porque a `LazyVStack` só cria a linha quando o cartão aparece |
| Apagar | "Apagar este gasto?" com "nome · valor. Não dá para desfazer." ("Cancelar" / "Apagar"); na parcela, um alerta de três botões ("Apagar só esta parcela", "Apagar a compra toda (N parcelas)", "Cancelar"), N = as que restam (como o site). Depois: foco na linha vizinha (ou em "Lançamentos") e o anúncio "Gasto apagado" ou "Compra apagada" | Mockup ("Apagar" em tudo) e conselho (alerta em vez de diálogo de ações) |
| Halo do título da obra | 30% | O título na maior letra media 3,38:1; a dose do vidro é decisão do conselho (segunda rodada) |
| Seta do "A pagar" | Fora até a etapa 3, com a nota "Parcelas e gastos futuros" (sem o "Ver") | A regra do Giovani de 08/10 para a seta das obras: a seta prometeria navegação, e a folha do A pagar é da etapa 3 |
| Conta de teste no build | No Release, `ModeloApp.gravar` recusa fora de conta com `custta-teste` no e-mail, com o alerta "Este build ainda não grava na sua conta"; em Debug grava sempre | O Giovani pode entrar na conta de sempre por engano: o app mostra os dados e não grava nada. Sai no PR 4 |
| Obra marcada na linha "Obra" (gasto numa vendida) | A primeira obra aberta na ordem da lista (as não vendidas, da que começou mais recente) | É a primeira que a pessoa vê na lista; o site marca a primeira do documento, em geral a mais antiga |
| Depois de salvar o gasto numa vendida | A obra que o recebeu toma o lugar da vendida por trás da folha, sem animação; a folha desce mostrando o gasto aceso | O desenho aprovado não tem toast; ficar na vendida não daria retorno nenhum |
| "Não salvou" | Uma vez por erro (o Sincronizador conta as confirmações do servidor), com o texto do site partido em título e mensagem e "Tentar de novo"; o mesmo erro de novo fica só na pílula; com folha aberta, espera ela descer | É o "uma vez" do spec; no site é um toast a cada erro |
| Textos dos alertas da parte 3 | Os do site: "Desfazer a venda?" / "A obra volta pra “Pronta”."; "Apagar “{nome}”?" com "Os N lançamentos dela serão perdidos. Não dá para desfazer." (singular com 1; só "Não dá para desfazer." com 0); descartar na edição diz "Descartar alterações" | O spec manda o texto do site; "Descartar obra" na edição se lê como apagar a obra |
| Nota "O orçamento fica na própria obra (etapa 3)" do mockup | Não entra | Promete uma tela que a etapa 2 não tem, como a aba "Vale a pena?" |
| Área na edição | Com vírgula (`areaParaCampo`) | O site mostra "3.125" e o `parseNum` lia 3125 (defeito corrigido na Tarefa 6) |
| Mutações da fase | Só pelos caminhos da tela (construção ↔ pronta; vender só a pronta; desfazer só a vendida), senão `nil` | Uma tela velha não atropela o que outro aparelho mudou |
| Zero nos valores opcionais da obra | Vale, como apagar o valor | Estimativa e orçamento são opcionais |
| Data da venda | Hoje, com o calendário do início da obra até hoje; obra que começa no futuro fica só com hoje e a mensagem do site | Sem isso o intervalo invertido derrubava o app |
| Lucro e prejuízo sobre o vidro | Tokens `PositivoNoVidro` e `NegativoNoVidro` (Tarefa 15) | O Positivo e o Negativo do site ficavam entre 2,76 e 3,66:1 com a aurora atrás; a etiqueta "Vendida em…" continua no Positivo sobre o fundo dela. O tom vai ao Giovani no build do PR 3 |
| Cartão de vidro | O vidro como fundo à parte (`CartaoDaLista`) | Com o vidro aplicado ao conteúdo, no iOS 27, o cartão que cresce levava junto o quadro de acessibilidade da primeira linha (o cabeçalho do "A vencer" respondia pelo cartão inteiro) |
| CI | Laudo de leitura e auditorias num job próprio (`laudo`), no PR 1 | O job `app` estava em 42–53 min com teto de 75; as cenas novas o fariam passar |
| Folha com Reduzir transparência | Opaca (a Folha sobre o Fundo, sem material) | Respeita a opção do iPhone; com o material, a auditoria de contraste do Xcode lia o resumo do cartão (16,4:1 nos pixels) como reprovado |
| Teclado físico no teclado de valor | Fica fora | No iPhone é raro; o site aceita dígitos, Backspace, Enter e Esc. Entra se o Giovani pedir |
| Tokens | Os cinco do spec (Folha, Linha da folha, Tecla, Tecla tocada, Segmentado escolhido) e mais seis do mockup: Separador da folha, Segmentado fundo, Apagar, Sobre apagar, Sobre alerta e Aceso | O mockup usa as seis cores; sem token, seriam cores soltas, que a guarda barra |
| Pix para cartão na edição | Como o site: vira cartão sem juros nem parcelas | `app.js:1071` |
| VoiceOver no teclado de valor | O visor é um elemento ("Valor", "R$ …"); cada tecla anuncia o valor novo; "00" se lê "zero zero" | O visor muda sem foco; sem o anúncio, quem não vê não sabe o que digitou |

### O que muda em relação ao spec

| Spec | Plano | Por quê |
| --- | --- | --- |
| spec:141–142, PRs 0a e 0b | Um PR só do site, com escopo maior: a cópia em Swift e os leitores dos vetores no mesmo PR, as regras de gravação no `dados.js`, o teclado nos vetores e dois defeitos do site corrigidos | Conselho (segunda rodada); ver "Escopo dos PRs do site" e "Defeitos do site" |
| spec, cinco PRs | Seis: o PR 4 tira a guarda da conta de teste depois do OK do Giovani no build do PR 3 | O build que ele testa sai da `main`; a troca para a conta real precisa de outro build |
| spec:27 e 218, "A pagar (com chevron)" | Sem a seta e sem o "Ver" até a etapa 3 | Regra do Giovani de 08/10 |
| spec:141, "o + da lista avisa antes de abrir" | O aviso fica no começo do `formNovaObra` | Quatro entradas no site (inventário, seção 13) |
| spec:89, "O valor precisa ter pelo menos um centavo por parcela" | Não entra | Código morto no site |
| spec:49, "Carregando suas obras" | O texto completo do site no título e a mensagem do mockup; o gasto continua na folha (comportamento novo do app) | Inventário, seção 8 |
| spec:90–91, repetido e sugestões | As regras completas do site (só com descrição; normalizada; centavos; menos o próprio gasto; quatro pesos; até 5) | Inventário, seção 2 |
| spec:37, ordem dos campos | "Obra" só aparece na obra vendida (PR 3); "Condições originais da compra" na edição com juros | O site mostra "Obra" sempre, desabilitada quando fixa |
| spec:39, "o resumo do site" | O texto do site; o print do mockup tinha outro | Ver "Resumo do cartão" |
| spec:44, "o Apagar do sistema" no arrastar e "diálogo de ações" na parcela | Arrastar próprio com o desenho do mockup; alerta de três botões | Conselho de 13/10 |
| spec:72, tokens novos | Mais seis | Ver "Tokens" |
| spec:143, PR 1 | Também o job `laudo` da CI, o escurecimento e o halo, o `CartaoDaLista` e a obra do mockup nos dados de exemplo | Achados do laudo e do protótipo |
| spec:144, conferência cruzada do PR 2 | O roteiro do app (Pix, cartão 3x com juros, editar um gasto e uma parcela, apagar na obra vendida, apagar a compra toda) contra o que o `dados.js` grava com as mesmas respostas e os mesmos ids | Confere o documento inteiro, não só a soma |
| spec:145, PR 3 | Também o roteiro da obra na conferência cruzada (criar, editar, fase, venda, desfazer, apagar), os tokens do lucro e do prejuízo, a Folha sólida com Reduzir transparência e o "Não salvou" uma vez por erro | Achados do protótipo e do laudo |
| spec, folha da obra | Campos na ordem do mockup (nome, início, área, estimado, orçamento), não na do site | A área obrigatória fica à vista acima do teclado |
| spec:49, `nao-carregado` nas folhas da obra e da venda | A folha continua aberta, como no gasto | O mesmo comportamento nas três folhas |
| mockup, "Use até 120 caracteres." como alerta | O campo limita em 120 (o `maxlength` do site); se a mensagem aparecer, é nota vermelha embaixo do campo | Como a descrição do gasto |
| mockup, botões dos alertas na cor da marca e lado a lado | Alertas do sistema, com o tint na cor do texto; o iOS 27 empilha os de "Desfazer a venda?" | São alertas do sistema; o laudo mede os botões entre 6,2 e 9,1:1 |

### O que a revisão independente mudou

Um subagente que não escreveu nada leu o plano contra o spec e os três mockups antes da entrega. O que ele achou e o que mudou:

- O texto da edição do gasto estava desatualizado no plano (copiava o `trocandoGasto`, já trocado pelo `editandoGasto`, que parte do gasto atual): corrigido, com o teste `editarNoLugarAPartirDoGastoAtual`.
- Havia janelas vermelhas na CI entre tarefas (o job `laudo` nascia depois das cenas que ele roda; o + na lista chegaria antes da dose que o faz passar): o job `laudo` virou a primeira tarefa do PR 1 e a dose a segunda.
- Faltavam testes de tela que o spec implica: lançar sem rede, editar o valor pelo teclado, a folha que fecha quando outro aparelho apaga o gasto (gancho `CUSTTA_APAGAR_REMOTO` nos falsos) e "apagar só esta parcela": entraram no `GastoUITests`.
- "Todos" os tópicos repetia os "Usados nesta obra": `topicosSemOsUsados`, com teste.
- Menores: o pagamento desconhecido de um gasto do site é preservado na edição; o título do passo do valor na edição é "Valor"; `CampoDeData` com mínimo e máximo; "OK" na barra do teclado dos juros; a mensagem de `nao-carregado` para um documento que o app não lê; `LinhaDaLista` com a ação do VoiceOver.
- No PR 3 (segunda leitura, sobre o protótipo mesclado): a seta do "A pagar" saiu até a etapa 3; o gancho `-custta.folha` da folha do gasto e o `CUSTTA_FOLHA` das folhas novas viraram um gancho só; o apagador de texto do laudo dentro da folha ficou num lugar só (`FolhaEmPassos`); o laudo da obra vendida ficou no teste da parte 3 (lucro e prejuízo), em vez de duplicado; e o laudo do estado mesclado achou os dois problemas da cápsula e da etiqueta âmbar, resolvidos na Tarefa 10.

## O que roda na CI e o que roda só no Mac

| Testes | Onde | Observação |
| --- | --- | --- |
| Site: `npm run test:unit` (vetores, `dados.test.cjs`, guardas) e as suítes de browser com dados sintéticos (`cartao`, `obras`, `mobile`…) | CI (`verificar`) e Mac | `obras.cjs` é novo (PR 0); `fase3.cjs` (sugestões e segundo toque, com emuladores) continua na CI |
| Núcleo (`swift test`) | CI, job `nucleo`, e `npm run test:nucleo` | 124 testes hoje; 143 no fim do PR 0, 150 no fim do PR 1, 164 no fim do PR 2 e 178 no fim do PR 3 |
| Unidade do app com falsos (`CusttaTests`) | CI, job `app` | 89 no fim do PR 1, 98 no fim do PR 2, 103 no fim do PR 3 e 102 no fim do PR 4 |
| Tela com falsos (`CusttaUITests` menos laudo e auditorias) | CI, job `app` | `ObraUITests` (PR 1, 7 testes), `GastoUITests` (PR 2, 17), `FasesUITests`, `FolhaDaObraUITests` e `EstadosUITests` (PR 3, 17) |
| Laudo de leitura e auditorias (`LeituraNoVidroUITests`, `AuditoriaUITests`) | CI, job `laudo` (novo no PR 1) e Mac | Portão: nenhuma palavra abaixo de 4,5:1 sobre o vidro; a obra soma 10 cenas mais a varredura (24 no Mac, 8 na CI), a folha do gasto 32 e a parte 3 mais 32 e o alerta; no Mac, também no Pro Max |
| Guardas em Node do app (`tests/app-ios.test.cjs`) | CI e Mac | Tokens e pares sólidos, Reduzir movimento, `lineLimit` só nos componentes fixos |
| Contra os emuladores (`npm run test:app-ios:emuladores`) e conferência cruzada (`npm run test:app-ios:cruzado`) | Só no Mac (Java e emuladores) | Obrigatórios antes de cada envio ao TestFlight; o cruzado do PR 2 confere o roteiro de gastos e o do PR 3 também o da obra |
| Conferência visual com o mockup | Mac, simulador (Verniz) | Lado a lado com os `parte*-*.png`, nos quatro combos e na maior letra |

Todos os comandos rodam na raiz do worktree. Os de simulador usam o simulador de cada agente:

```bash
export CUSTTA_SIMULADOR=<udid do seu simulador>          # nunca o D9F432D6 de outro agente
DESTINO=$(node scripts/simulador-ios.mjs)
XB=(-project app-ios/Custta.xcodeproj -scheme Custta -destination "$DESTINO"
    -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile)
# compilar uma vez por mudança e rodar só o que interessa
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/ObraUITests 2>&1 | tail -5
# núcleo
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter ObraNaTelaTests 2>&1 | tail -3
```

## Review Focus

Entradas e situações que o spec não cita e que mais podem pegar quem usa o app; cada uma tem o teste que a prende, na tarefa dona do código:

1. **Outro aparelho apaga a obra ou o gasto com a folha aberta.** A folha fecha e nada é gravado (o `gravar` devolve `.sumiu`). Teste: `GravacaoDoAppTests.obraQueSumiuNaoGravaNada` (Tarefa 20); a folha observa a existência da obra e do gasto (Tarefa 22).
2. **Datas na virada do mês e no fuso.** Cartão lançado em 31/01 vence em 28/02; o calendário trabalha ao meio-dia local, longe das mudanças de horário. Testes: vetores de `dados.gastosLancados` (Tarefa 2) e `GravacaoDoAppTests.rascunhoDoGastoNovoComecaComoOMockup` (Tarefa 22).
3. **Valores nos extremos.** A tecla que passaria de R$ 99.999.999,99 é ignorada; R$ 0,05 em 10x não fecha o parcelamento ("Confira valor, parcelas, data e taxa de juros"); valor grande na maior letra encolhe no visor. Testes: vetores `teclado.aplicarTecla` (Tarefa 4) e `dados.conferirGasto` (Tarefa 2); laudo "folha, valor, na maior letra" (Tarefa 24).
4. **Texto longo.** Descrição com 500 unidades e emoji no fim; nome de obra comprido na barra da obra e da folha (uma linha, cortada como a do sistema). Testes: `GravacaoDoAppTests.descricaoParaEm500UnidadesSemPartirEmoji` (Tarefa 22) e a guarda de `lineLimit` (Tarefa 21).
5. **Gestos que disputam o mesmo dedo.** Arrastar a linha × rolar × voltar pela borda (da obra e de dentro da folha) × tocar outra linha com uma aberta. Testes: `ObraUITests.testVoltarPelaBorda` (Tarefa 15, roda de novo no PR 2 com o arrastar), `GastoUITests.testVoltarPelaBordaDentroDaFolha` (Tarefa 22) e `testCancelarFechaALinhaENaoApaga` (Tarefa 23).

## Riscos

- **Primeira gravação do app em produção.** Cada gravação regrava o documento inteiro. Mitigação: conta de teste até o PR 3, guarda de gravação com a marca do servidor, regras iguais às do site pelos vetores e a conferência cruzada de cada mutação (o documento inteiro, não só a soma), com campos que o app não conhece preservados.
- **A ponte do "tentou fechar".** Ela troca o delegado do presentation controller que o SwiftUI instalou. Se uma versão do iOS mudar isso, puxar a folha com algo preenchido fecharia sem perguntar. Mitigação: o teste de tela de puxar roda no iOS 26 (CI) e no 27 (Mac), a ponte devolve o delegado quando a folha desce e o teste conta as pontes vivas.
- **Arrastar próprio.** Precisa acertar os gestos do sistema e a acessibilidade à mão. Mitigação: o arrasto só começa na horizontal e longe da borda esquerda; testes de tela de voltar pela borda; botão na árvore de acessibilidade e ação no rotor; itens no checklist do aparelho (VoiceOver, Controle por Voz).
- **Tempo da CI.** As 32 cenas da folha somam ~15 min ao job `laudo` (que nasce no PR 1 com as da etapa 1 e as da obra); o job `app` ganha ~5 min com o `GastoUITests`. Se algum passar de ~65 min, divide de novo.
- **Teclado do sistema na folha.** A descrição sobe acima do teclado quando ele aparece; em telas pequenas e na letra grande sobra pouco espaço. Mitigação: conferência no simulador de 375 pt (13 mini) e item no checklist do aparelho.
- **iOS 26 × 27.** O vidro, os alertas e o `Button(role: .close)` mudam de desenho entre as versões. Mitigação: CI no 26, Mac no 27, laudo nos dois.
- **O + muda a cápsula.** Na lista de obras a cápsula encolhe para o + caber, e os rótulos passam sobre outro trecho do conteúdo: o laudo da etapa 1 reprovou a 2,75:1 no protótipo mesclado. Mitigação: 30% de escurecimento sob a navegação (Tarefa 10) e a varredura da cápsula sobre a lista continua no laudo.
- **A conta de teste e a conta de sempre.** Até o PR 4 o build recusa gravar fora da conta de teste; se o Giovani entrar na conta de sempre, vê os dados e nada muda. Mitigação: o alerta diz isso, e o checklist pede o teste.

## Como entregar

| PR | Branch e worktree | Tarefas | Build |
| --- | --- | --- | --- |
| 0 (site) | `feat/regras-nos-vetores-e-limite-de-obras` em `.claude/worktrees/regras-nos-vetores` | 1 a 8 | — (prévia da Vercel) |
| 1 (app) | `feat/app-nativo-etapa2-obra` em `.claude/worktrees/app-nativo-etapa2-obra` | 9 a 18 | TestFlight 2.0 |
| 2 (app) | `feat/app-nativo-etapa2-gasto` em `.claude/worktrees/app-nativo-etapa2-gasto` | 19 a 26 | TestFlight 2.0 |
| 3 (app) | `feat/app-nativo-etapa2-obras` em `.claude/worktrees/app-nativo-etapa2-obras` | 27 a 37 | TestFlight 2.0 |
| 4 (app) | `feat/app-nativo-conta-real` em `.claude/worktrees/app-nativo-conta-real` | 38 | TestFlight 2.0, na conta real |

Ordem (conselho de 13/10, segunda rodada): o PR 0 primeiro; o PR 1 começa quando o PR 0 entra em revisão (os arquivos não se cruzam; o rebase sobre a `main` depois é pequeno); o PR 2 começa pelas Tarefas 19 e 20 (núcleo e gravação, sem tela) e só segue para a tela com o OK do Giovani no build do PR 1; o PR 3 depois do OK do PR 2; o PR 4 só depois do OK do PR 3. Cada PR nasce num worktree novo a partir da `origin/main` atualizada:

```bash
cd "$(git rev-parse --path-format=absolute --git-common-dir)/.."
git fetch origin
git worktree add .claude/worktrees/<nome> -b <branch> origin/main
cd .claude/worktrees/<nome> && npm ci
```

**Pontos de controle.**
- Fim do PR 0: a prévia da Vercel conferida (lançar no cartão com juros, apagar uma parcela com a folha aberta; criar a 300ª obra e ver o aviso; editar uma obra com área 3,125).
- Fim da Tarefa 10: os prints de antes e depois da dose (lista de obras, cápsula, etiqueta âmbar no claro) vão ao Giovani.
- Fim da Tarefa 15: o Verniz confere a tela da obra lado a lado com `parte1-obra-topo.png`, `parte1-obra-rolada.png`, `parte1-obra-meio-da-lista.png` e `parte1-obra-a-vencer-aberto.png`; o Orquestrador manda os prints ao Giovani, com os de antes e depois do escurecimento da lista de obras.
- Fim da Tarefa 22 e da 23: o Verniz confere a folha e a lista com os `parte2-*.png` (os prints `lancar-*`, `topico-a`, `editar`, `editar-parcela`, `apagar-*`, `aviso-*`).
- Antes de cada envio ao TestFlight: `npm run test:app-ios:emuladores` e `npm run test:app-ios:cruzado` no Mac, verdes; o laudo verde no Mac.

**Na entrega de cada PR:** descrição em prosa (contexto, o que muda, decisão técnica), o link da prévia da Vercel conferido e o "como testar". O Orquestrador abre cada PR como rascunho logo depois do primeiro commit, para a CI rodar desde a primeira tarefa.

**TestFlight:** depois que cada PR do app entra na `main`, o Orquestrador dispara o workflow `app-ios-testflight` com o OK do Giovani. O Giovani instala, entra **na conta de teste** e marca o checklist do aparelho da etapa 2 (`docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`).

**Falhas da CI que não vêm do diff:** as conhecidas da etapa 1 (ping do Google em `apple.cjs:292` e `google.cjs:324`; `#cSenha` invisível em `google.cjs:190`): rode de novo só o job.

### O que só o Giovani faz (pendências físicas)

1. Exportar o JSON das obras pelo site (Ajustes → Exportar dados), antes do primeiro build.
2. Escolher o e-mail e a senha da conta de teste.
3. Disponibilizar a conta de serviço do Firebase na máquina (`FIREBASE_SERVICE_ACCOUNT`) e rodar o `conta-demo.mjs --importar` (ou autorizar quem rode), como no checklist.
4. Instalar cada build pelo TestFlight, entrar com a conta de teste e marcar o checklist.
5. Olhar os prints de antes e depois da dose do vidro (Tarefa 10: lista de obras, cápsula de abas, etiqueta âmbar) e dizer se o tom serve; no build do PR 3, o mesmo para o lucro e o prejuízo da obra vendida sobre o vidro.
6. Dar o OK de cada envio ao TestFlight e, com o checklist do PR 3 marcado, o OK para o PR 4 (a conta real).

## Mapa de arquivos

**Site (PR 0)**
- `calc.js`: `normalizaDescricao`, `distanciaEdicao`, `sugestoesDescricao`, `gastoRepetido`, `lerTaxaCartao` (saem do `app.js`).
- `dados.js`: o que os formulários gravam (`conferirGasto`, `gastosLancados`, `gastoEditado`, `conferirObra`, `obraNova`, `obraEditada`, `conferirVenda`) e o teto de obras (`LIMITE_OBRAS`, `avisoLimiteDeObras`).
- `app.js`: usa as regras acima; aviso do limite no `formNovaObra`; correções da parcela e da área.
- `scripts/vetores-calc.mjs`, `tests/vetores/calc.json` (gerado), `tests/vetores.test.mjs`: grupos novos, inclusive o `teclado.js`.
- `tests/browser/cartao.cjs`, `tests/browser/obras.cjs` (novo), `tests/browser/rodar.cjs`, `tests/dados.test.cjs`, `sw.js`.

**Núcleo (`app-ios/CusttaNucleo`)**
- `Sugestoes.swift` (novo): sugestões, repetido, taxa do cartão e o índice das sugestões.
- `Formularios.swift` (novo): o que os formulários gravam, o limite de obras e os textos da folha do gasto.
- `Centavos.swift` (novo) e `NumeroJS.swift`: o teclado de valor (`toFixed` até 4 casas).
- `ObraNaTela.swift` (novo): lista por mês, "A vencer", linha do gasto, indicadores e textos de apagar.
- `Mutacoes.swift` (novo): lançar, editar, apagar um gasto e a compra toda; no PR 3, criar, editar e apagar a obra, mudar a fase, registrar e desfazer a venda.
- `ObraEFases.swift` (novo, PR 3): as ações da fase, os textos de apagar obra, desfazer venda, das folhas, da lista vazia e do "Não salvou", a área no campo e as obras abertas.
- `Topicos.swift`: tópicos da folha, "Usados nesta obra" e o tópico inicial.
- `Sincronizador.swift`: a marca do servidor e o `aplicar` com a `Gravacao`; `Telas.swift`: o texto de `nao-carregado`.

**App (`app-ios/Custta`)**
- `Telas/ObraView.swift` e `Telas/PecasDaObra.swift` (novos): a tela da obra.
- `Telas/FolhaEmPassos.swift`, `Telas/FolhaDoGasto.swift`, `Telas/LinhaArrastavel.swift` (novos): a folha em passos com a ponte, a folha do gasto e o arrastar para apagar.
- `Identidade/TecladoDeValor.swift`, `Identidade/PecasDaFolha.swift` (novos): teclado de valor e peças da folha.
- `Estado/Folhas.swift` (novo) e `Estado/ModeloApp.swift`: qual folha está aberta e o que ela pede a Obras depois (`navegar`); `gravar`, a mensagem de `nao-carregado` e o alerta de "Não salvou"; `Estado/ContaDeTeste.swift` (novo no PR 1, sai no PR 4).
- `Telas/FolhaDaObra.swift` e `Telas/FolhaDaVenda.swift` (novos, PR 3): nova e editar obra, com apagar; a venda em dois passos.
- `Dados/MarcaNasPreferencias.swift` (novo), `Dados/BancoFirebase.swift`, `Composicao.swift`, `Falsos/*`: a marca do servidor e os dados da obra do mockup.
- `Identidade/CapsulaDeAbas.swift` (o +), `Identidade/Componentes.swift`, `Identidade/Paleta.swift`, `Identidade/Vidro.swift`, `Identidade/Aurora.swift`, `Telas/ObrasView.swift`, `Telas/PrincipalView.swift`.
- Testes: `CusttaTests/GravacaoDoAppTests.swift` (novo), `CusttaUITests/ObraUITests.swift`, `GastoUITests.swift`, `FasesUITests.swift`, `FolhaDaObraUITests.swift` e `EstadosUITests.swift` (novos), `LeituraNoVidroUITests.swift`, `AuditoriaUITests.swift`, `CruzadoTests.swift` e os demais ajustes.

**Scripts, CI e documentos:** `scripts/cores-app-ios.mjs`, `scripts/icones-app-ios.mjs`, `scripts/conta-demo.mjs`, `tests/app-ios.test.cjs`, `tests/app-ios/cruzado.mjs`, `.github/workflows/app-ios.yml` (job `laudo`), `tests/workflow.test.cjs`, `.gitignore`, `CLAUDE.md`, `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md` (novo).

---

## PR 0 (site): as regras do gasto e da obra nos vetores e o limite de 300

Um PR só do site (conselho de 13/10, segunda rodada), em oito commits. Tira do `app.js` o que o app nativo precisa copiar: do formulário do gasto, as sugestões de descrição, o repetido e a leitura da taxa do cartão vão para o `calc.js`, e a conferência e os objetos que o "Salvar" grava vão para o `dados.js` (Tarefas 1 a 4); dos formulários da obra e da venda, o que "Criar obra", "Salvar" e "Confirmar venda" gravam, mais o aviso do limite de 300 obras (Tarefas 5 a 7). O comportamento do site não muda (as suítes de browser continuam verdes), exceto as duas correções: a parcela apagada com a folha aberta (Tarefa 3) e a área com casas decimais ao editar a obra (Tarefa 6). Cada regra entra nos vetores com o leitor em Swift no mesmo commit, porque o núcleo barra grupo de vetor sem leitor. Uma subida só do `CACHE`, no fim (Tarefa 8).

### Task 1: Sugestões de descrição, repetido e taxa do cartão no calc.js

As três regras saem do `app.js` sem mudar de comportamento: recebem as obras por parâmetro em vez de ler o `db` global, e o `app.js` passa a chamá-las pelo `OBRA_CALC`. A cópia em Swift usa as mesmas bordas do JavaScript: distância de edição em unidades UTF-16, `localeCompare('pt-BR')` com o desempate do V8 nas formas que o ICU junta ("ﬁ" e "fi"), e o `\d` só ASCII da taxa.

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Sugestoes.swift`
- Test (criar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SugestoesTests.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (alterar): `scripts/vetores-calc.mjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `semAcento` do `calc.js`; no núcleo, `aparadoJS`, `semAcento`, `menorJS`, `contem`, `ordenadoEstavel`, `ehEspacoJS`, `ehDigito` e `arredondarJS` (já existem).
- Produces: `OBRA_CALC.normalizaDescricao(s)`, `distanciaEdicao(a, b)`, `sugestoesDescricao(obras, obraId, topicoId, termo, ignorarId)` (até 5 `{texto, chave, vezes, mesmaObra, mesmoTopico, ultima}`), `gastoRepetido(obra, descricao, valor, data, ignorarId)` e `lerTaxaCartao(texto)` (número ou `NaN`). Em Swift: `normalizaDescricao(_:)`, `distanciaEdicao(_:_:)`, `SugestaoDeDescricao` (com `contexto`: "mesmo tópico" ou "N× usado"), `sugestoesDescricao(_:obraId:topicoId:termo:ignorarId:)`, `gastoRepetido(_:descricao:valor:data:ignorarId:)` e `lerTaxaCartao(_:) -> Double`.

- [ ] **Step 1: Escrever os vetores e os leitores em Swift**

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SugestoesTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/// As obras de um caso dos vetores (lista de objetos, normalizada ou não).
func obrasDoCaso(_ v: ValorJSON) -> [Obra] { (v.comoLista ?? []).compactMap { $0.comoObjeto.map(Obra.init(arvore:)) } }

extension SugestaoDeDescricao {
    var json: ValorJSON {
        .objeto(["texto": .texto(texto), "chave": .texto(chave), "vezes": .numero(Double(vezes)),
                 "mesmaObra": .booleano(mesmaObra), "mesmoTopico": .booleano(mesmoTopico), "ultima": .texto(ultima)])
    }
}

struct SugestoesTests {
    @Test func descricaoComparavel() {
        for c in Vetores.casos("calc.normalizaDescricao") {
            confere(.texto(normalizaDescricao(c.arg(0)?.comoTexto)), c.saida, .exata, c.caso)
        }
    }

    @Test func distanciaDeEdicaoEmUTF16() {
        for c in Vetores.casos("calc.distanciaEdicao") {
            confere(.numero(Double(distanciaEdicao(c.args[0].comoTexto!, c.args[1].comoTexto!))), c.saida, .exata, c.caso)
        }
    }

    @Test func sugestoesComOsPesosEODesempateDoSite() {
        for c in Vetores.casos("calc.sugestoesDescricao") {
            let r = sugestoesDescricao(obrasDoCaso(c.args[0]), obraId: c.args[1].comoTexto!, topicoId: c.args[2].comoTexto!,
                                       termo: c.args[3].comoTexto!, ignorarId: c.args[4].comoTexto)
            confere(.lista(r.map(\.json)), c.saida, .exata, c.caso)
        }
    }

    @Test func contextoDaSugestao() {
        let base = SugestaoDeDescricao(texto: "Cimento", chave: "cimento", vezes: 1, mesmaObra: false, mesmoTopico: false, ultima: "2026-01-01")
        #expect(base.contexto == "1× usado")
        #expect(SugestaoDeDescricao(texto: "Cimento", chave: "cimento", vezes: 3, mesmaObra: true, mesmoTopico: true, ultima: "").contexto == "mesmo tópico")
    }

    @Test func gastoRepetidoComoOSite() {
        for c in Vetores.casos("calc.gastoRepetido") {
            let obra = Obra(arvore: c.args[0].comoObjeto!)
            let r = gastoRepetido(obra, descricao: c.args[1].comoTexto!, valor: c.args[2].numero, data: c.args[3].comoTexto!,
                                  ignorarId: c.args[4].comoTexto)
            confere(.booleano(r), c.saida, .exata, c.caso)
        }
    }

    @Test func taxaDoCartaoComoOFormularioLe() {
        for c in Vetores.casos("calc.lerTaxaCartao") {
            let n = lerTaxaCartao(c.arg(0)?.comoTexto)
            confere(n.isFinite ? .numero(n) : .nulo, c.saida, .exata, c.caso)
        }
    }
}
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -268,6 +268,69 @@ filtra('tópico próprio pelo nome', O4.gastos, TOPICOS_MAPA, { texto: 'automaca
 filtra('tópico apagado busca pelo id', [{ id: 'k', valor: 1, topico: 'c_sumiu', descricao: '', data: '2026-01-01' }], TOPICOS_MAPA, { texto: 'c_sum' });
 filtra('nada encontrado', O1.gastos, TOPICOS_MAPA, { texto: 'xyz' });
 
+/* ---------- descrição do gasto: sugestões e repetido ---------- */
+const normDesc = calc('normalizaDescricao');
+for(const s of ['  Cimento   CP-II ', 'ÁCIDO\tmuriático', '\u{a0}a\u{2003}b\u{a0}', '', 'Tinta\nacrílica', 'ΟΔΟΣ', '\u{180e}x'])
+  normDesc(JSON.stringify(s), s);
+normDesc('nulo', null);
+const dist = calc('distanciaEdicao');
+for(const [a, b] of [['', ''], ['abc', ''], ['', 'abc'], ['cimento', 'cinemto'], ['kitten', 'sitting'], ['😀a', 'a'], ['ação', 'acao'], ['areia', 'areia']])
+  dist(`${a}|${b}`, a, b);
+/* Descrições de duas obras: a mesma chave em textos diferentes (o mais recente dá o texto; no mesmo dia, o
+   último), empates de peso e de data (desempate pelo localeCompare pt-BR), erro de digitação e o gasto em edição. */
+const SUG = D.normaliza({ obras: [
+  { id: 's1', nome: 'Casa', dataInicio: '2026-01-01', gastos: [
+    { id: 'a1', valor: 10, topico: 'matbasicos', descricao: 'Cimento CP-II, 120 sacos', data: '2026-03-01' },
+    { id: 'a2', valor: 10, topico: 'matbasicos', descricao: 'cimento cp-ii, 120 sacos', data: '2026-04-01' },
+    { id: 'a3', valor: 10, topico: 'revest', descricao: 'Cimento cola AC-II', data: '2026-04-01' },
+    { id: 'a4', valor: 10, topico: 'revest', descricao: 'Cimento cola AC-II', data: '2026-02-01' },
+    { id: 'a5', valor: 10, topico: 'pintura', descricao: '  Tinta   acrílica ', data: '2026-05-01' },
+    { id: 'a6', valor: 10, topico: 'matbasicos', descricao: 'Areia média', data: '2026-05-02' },
+    { id: 'a7', valor: 10, topico: 'matbasicos', descricao: 'Areia fina', data: '2026-05-02' },
+    { id: 'a8', valor: 10, topico: 'matbasicos', descricao: 'areia grossa', data: '2026-05-02' },
+    { id: 'a9', valor: 10, topico: 'matbasicos', descricao: 'Areia Grossa', data: '2026-05-02' },
+    { id: 'a10', valor: 10, topico: 'outros', descricao: '', data: '2026-05-03' },
+    { id: 'a11', valor: 10, topico: 'matbasicos', descricao: 'Cimento', data: '2026-01-15' },
+  ] },
+  { id: 's2', nome: 'Sobrado', dataInicio: '2026-01-01', gastos: [
+    { id: 'b1', valor: 10, topico: 'matbasicos', descricao: 'Cimento branco', data: '2026-06-01' },
+    { id: 'b2', valor: 10, topico: 'matbasicos', descricao: 'Cimento branco', data: '2026-06-02' },
+    { id: 'b3', valor: 10, topico: 'eletrica', descricao: 'Ciment', data: '2026-06-03' },
+    { id: 'b4', valor: 10, topico: 'eletrica', descricao: 'Areia lavada', data: '2026-05-02' },
+    { id: 'b5', valor: 10, topico: 'eletrica', descricao: 'Ácido muriático', data: '2026-05-02' },
+    { id: 'b6', valor: 10, topico: 'eletrica', descricao: 'acido muriatico', data: '2026-05-01' },
+    { id: 'b7', valor: 10, topico: 'eletrica', descricao: 'Areia', data: '2026-05-02' },
+  ] },
+], config: {} }).obras;
+const sug = calc('sugestoesDescricao');
+sug('termo vazio', SUG, 's1', 'matbasicos', '', null);
+sug('só espaços', SUG, 's1', 'matbasicos', '   ', null);
+sug('mesmo tópico e mesma obra pesam', SUG, 's1', 'matbasicos', 'cimen', null);
+sug('de outra obra', SUG, 's2', 'revest', 'Cimento', null);
+sug('sem acento, caixa e espaços', SUG, 's1', 'pintura', 'TINTA  acrilica', null);
+sug('erro de digitação a 2 edições', SUG, 's1', 'matbasicos', 'cinemto', null);
+sug('erro de digitação com menos de 4 letras não vale', SUG, 's1', 'matbasicos', 'cmt', null);
+sug('empate no peso e na data, desempate pt-BR, até 5', SUG, 's1', 'matbasicos', 'areia', null);
+sug('ignora o gasto em edição', SUG, 's1', 'revest', 'cimento cola', 'a3');
+sug('o gasto em edição só conta na obra dele', SUG, 's2', 'revest', 'cimento cola', 'a3');
+sug('acento no termo', SUG, 's2', 'eletrica', 'ácido', null);
+sug('nada parecido', SUG, 's1', 'matbasicos', 'xyzw', null);
+const rep = calc('gastoRepetido');
+const OBRA_REP = { id: 'r', gastos: [
+  { id: 'x1', valor: 4980, descricao: 'Cimento CP-II', data: '2026-10-10' },
+  { id: 'x2', valor: 0.1 + 0.2, descricao: 'Prego', data: '2026-10-10' },
+] };
+rep('mesma descrição, valor e data', OBRA_REP, 'cimento  cp-ii', 4980, '2026-10-10', null);
+rep('sem descrição nunca', OBRA_REP, '', 4980, '2026-10-10', null);
+rep('valor diferente', OBRA_REP, 'Cimento CP-II', 4980.01, '2026-10-10', null);
+rep('data diferente', OBRA_REP, 'Cimento CP-II', 4980, '2026-10-11', null);
+rep('o próprio gasto em edição não conta', OBRA_REP, 'Cimento CP-II', 4980, '2026-10-10', 'x1');
+rep('centavos arredondados', OBRA_REP, 'Prego', 0.3, '2026-10-10', null);
+rep('acento e caixa não contam', OBRA_REP, 'CIMENTO CP-ÍI', 4980, '2026-10-10', null);
+for(const t of ['0', '2,5', '2.5', ' 3 ', '10', '.5', ',5', '5.', '5,', '1,2,3', '-1', '+1', 'abc', '', '1e2', '100', '100,01', '\u{663}'])
+  caso('calc.lerTaxaCartao', JSON.stringify(t), [t], x => { const n = C.lerTaxaCartao(x); return Number.isFinite(n) ? n : null; });
+caso('calc.lerTaxaCartao', 'nulo', [null], x => { const n = C.lerTaxaCartao(x); return Number.isFinite(n) ? n : null; });
+
 /* ---------- parcelas ---------- */
 const parcelas = calc('gerarParcelas');
 parcelas('resto de centavo na última', 100, 3, '2026-01-15');
```


- [ ] **Step 2: Ver falhar**

Run: `node scripts/vetores-calc.mjs`
Expected: FAIL com `TypeError: fn is not a function` (o `calc.js` ainda não exporta `normalizaDescricao`).

- [ ] **Step 3: Implementar no calc.js, no app.js e no núcleo**

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/Sugestoes.swift`:

```swift
import Foundation

/* A descrição do gasto como o formulário do site a trata (calc.js): as sugestões de descrição, o aviso de
   gasto repetido e a leitura da taxa de juros do cartão. Cada regra tem caso nos vetores. */

/// `normalizaDescricao` do calc.js: sem acento, em minúsculas, aparada e com os espaços do meio juntados.
public func normalizaDescricao(_ s: String?) -> String {
    var r = String.UnicodeScalarView()
    var emEspaco = false
    for u in aparadoJS(semAcento(s)).unicodeScalars {
        if ehEspacoJS(u) {
            if !emEspaco { r.append(" ") }
            emEspaco = true
        } else {
            r.append(u)
            emEspaco = false
        }
    }
    return String(r)
}

/// `distanciaEdicao` do calc.js: Levenshtein em unidades UTF-16, como o índice das strings do JavaScript.
public func distanciaEdicao(_ a: String, _ b: String) -> Int {
    let x = Array(a.utf16), y = Array(b.utf16)
    if x == y { return 0 }
    if x.isEmpty { return y.count }
    if y.isEmpty { return x.count }
    var anterior = Array(0...y.count)
    for i in 1...x.count {
        var atual = [i]
        for j in 1...y.count {
            atual.append(min(atual[j - 1] + 1, anterior[j] + 1, anterior[j - 1] + (x[i - 1] == y[j - 1] ? 0 : 1)))
        }
        anterior = atual
    }
    return anterior[y.count]
}

/// O `localeCompare(b, 'pt-BR')` do site: a comparação do iOS com a localidade pt_BR (o mesmo ICU no fundo) e, no
/// empate de formas que ele junta (ligadura "ﬁ" e "fi", "º" e "o"), a ordem das unidades UTF-16, que é a do V8.
func ordemPtBR(_ a: String, _ b: String) -> ComparisonResult {
    let r = a.compare(b, locale: Locale(identifier: "pt_BR"))
    if r != .orderedSame || a == b { return r }
    return menorJS(a, b) ? .orderedAscending : menorJS(b, a) ? .orderedDescending : .orderedSame
}

/// Uma sugestão de descrição: o texto do lançamento mais recente com essa descrição e de onde ela vem.
public struct SugestaoDeDescricao: Equatable, Sendable {
    public let texto: String
    public let chave: String
    public let vezes: Int
    public let mesmaObra: Bool
    public let mesmoTopico: Bool
    public let ultima: String

    /// O que o formulário mostra ao lado: "mesmo tópico" ou "N× usado".
    public var contexto: String { mesmoTopico ? "mesmo tópico" : "\(vezes)× usado" }

    var peso: Int { (mesmoTopico ? 100 : 0) + (mesmaObra ? 40 : 0) + min(vezes, 10) }
}

/// `sugestoesDescricao` do calc.js: as descrições já lançadas em todas as obras, sem repetir, que contêm o termo ou, com
/// 4 letras ou mais, ficam a até 2 edições dele. Pesam o mesmo tópico, a mesma obra, o começo igual e o uso; até 5.
/// `ignorarId` tira o gasto em edição (só na obra dele).
public func sugestoesDescricao(_ obras: [Obra], obraId: String, topicoId: String, termo: String,
                               ignorarId: String?) -> [SugestaoDeDescricao] {
    let busca = normalizaDescricao(termo)
    if busca.isEmpty { return [] }
    var ordem: [String] = []
    var itens: [String: SugestaoDeDescricao] = [:]
    for o in obras {
        for g in o.gastos {
            if o.id == obraId && g.id == ignorarId { continue }
            let texto = aparadoJS(g.descricao), chave = normalizaDescricao(texto)
            if chave.isEmpty { continue }
            let anterior = itens[chave]
            if anterior == nil { ordem.append(chave) }
            let base = anterior ?? SugestaoDeDescricao(texto: texto, chave: chave, vezes: 0, mesmaObra: false, mesmoTopico: false, ultima: "")
            let maisNova = !menorJS(g.data, base.ultima)
            itens[chave] = SugestaoDeDescricao(texto: maisNova ? texto : base.texto, chave: chave, vezes: base.vezes + 1,
                                               mesmaObra: base.mesmaObra || o.id == obraId,
                                               mesmoTopico: base.mesmoTopico || g.topico == topicoId,
                                               ultima: maisNova ? g.data : base.ultima)
        }
    }
    let tamanho = busca.utf16.count
    let candidatas = ordem.compactMap { itens[$0] }.filter { x in
        contem(x.chave, busca)
            || (tamanho >= 4 && abs(x.chave.utf16.count - tamanho) <= 2 && distanciaEdicao(x.chave, busca) <= 2)
    }
    func peso(_ x: SugestaoDeDescricao) -> Int { x.peso + (x.chave.utf16.starts(with: busca.utf16) ? 25 : 0) }
    let ordenadas = ordenadoEstavel(candidatas) { a, b in
        let pa = peso(a), pb = peso(b)
        if pa != pb { return pa > pb }
        if a.ultima != b.ultima { return menorJS(b.ultima, a.ultima) }
        return ordemPtBR(a.texto, b.texto) == .orderedAscending
    }
    return Array(ordenadas.prefix(5))
}

/// `gastoRepetido` do calc.js: mesma descrição comparável, mesmo valor em centavos e mesma data de um gasto da obra.
/// Sem descrição nunca parece repetido; `ignorarId` tira o gasto em edição.
public func gastoRepetido(_ obra: Obra, descricao: String, valor: Double, data: String, ignorarId: String?) -> Bool {
    if descricao.isEmpty { return false }
    let chave = normalizaDescricao(descricao), centavos = arredondarJS(valor * 100)
    return obra.gastos.contains { x in
        x.id != ignorarId && normalizaDescricao(x.descricao) == chave && arredondarJS(x.valor * 100) == centavos && x.data == data
    }
}

/// `lerTaxaCartao` do calc.js: dígitos com vírgula ou ponto decimal, sem sinal (o `\d` do JavaScript é só o ASCII);
/// o resto é NaN.
public func lerTaxaCartao(_ texto: String?) -> Double {
    let t = Array(aparadoJS(texto ?? "").unicodeScalars)
    let separadores = t.indices.filter { t[$0] == "," || t[$0] == "." }
    guard !t.isEmpty, separadores.count <= 1, t.allSatisfy({ ehDigito($0) || $0 == "," || $0 == "." }) else { return .nan }
    if let s = separadores.first, s == t.count - 1 { return .nan }        // "5," e "5." não valem
    var r = String.UnicodeScalarView()
    r.append(contentsOf: t.map { $0 == "," ? "." : $0 })
    return Double(String(r)) ?? .nan
}
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -80,42 +80,6 @@ const $ = s => document.querySelector(s);
 const el = (tag,cls,html)=>{ const e=document.createElement(tag); if(cls)e.className=cls; if(html!=null)e.innerHTML=html; return e; };
 // String() antes do replace: campo numérico do blob (areaM2, valor) também passa por aqui
 function escapeHtml(s){ return (s==null||s===false ? '' : String(s)).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
-const normalizaDescricao = s => OBRA_CALC.semAcento(String(s || '')).trim().replace(/\s+/g, ' ');
-function distanciaEdicao(a,b){
-  if(a===b) return 0;
-  if(!a.length) return b.length;
-  if(!b.length) return a.length;
-  let ant=Array.from({length:b.length+1},(_,i)=>i);
-  for(let i=1;i<=a.length;i++){
-    const atual=[i];
-    for(let j=1;j<=b.length;j++) atual[j]=Math.min(atual[j-1]+1,ant[j]+1,ant[j-1]+(a[i-1]===b[j-1]?0:1));
-    ant=atual;
-  }
-  return ant[b.length];
-}
-function sugestoesDescricao(obraId, topicoId, termo, ignorarId){
-  const busca=normalizaDescricao(termo);
-  if(!busca) return [];
-  const unicas=new Map();
-  db.obras.forEach(o=>o.gastos.forEach(g=>{
-    if(o.id===obraId && g.id===ignorarId) return;
-    const texto=String(g.descricao||'').trim(), chave=normalizaDescricao(texto);
-    if(!chave) return;
-    const item=unicas.get(chave)||{texto,chave,vezes:0,mesmaObra:false,mesmoTopico:false,ultima:''};
-    item.vezes++;
-    if(o.id===obraId) item.mesmaObra=true;
-    if(g.topico===topicoId) item.mesmoTopico=true;
-    if((g.data||'')>=item.ultima){ item.ultima=g.data||''; item.texto=texto; }
-    unicas.set(chave,item);
-  }));
-  return [...unicas.values()].filter(x=>x.chave.includes(busca)
-      || (busca.length>=4 && Math.abs(x.chave.length-busca.length)<=2 && distanciaEdicao(x.chave,busca)<=2))
-    .sort((a,b)=>{
-      const sa=(a.mesmoTopico?100:0)+(a.mesmaObra?40:0)+(a.chave.startsWith(busca)?25:0)+Math.min(a.vezes,10);
-      const sb=(b.mesmoTopico?100:0)+(b.mesmaObra?40:0)+(b.chave.startsWith(busca)?25:0)+Math.min(b.vezes,10);
-      return sb-sa || b.ultima.localeCompare(a.ultima) || a.texto.localeCompare(b.texto,'pt-BR');
-    }).slice(0,5);
-}
 function emptyBlock(icon,msg){ return `<div class="empty"><div class="big">${icon}</div><p>${msg}</p></div>`; }
 // KPIs de milhao estouram a largura do card (overflow:hidden corta o numero).
 // Reduz a fonte do numero so o quanto precisar pra caber; grande quando cabe.
@@ -955,7 +919,7 @@ function formGasto(obraId, gasto, valorInicial, aoFechar){
   const pintarSugestoes = ()=>{
     const lista=$('#descSugestoes'), campo=$('#fDesc');
     const obraIdAtual=oFix ? oFix.id : ($('#fObra')?.value||'');
-    const sugestoes=sugestoesDescricao(obraIdAtual,top,campo.value,isEdit?gasto.id:null);
+    const sugestoes=OBRA_CALC.sugestoesDescricao(db.obras,obraIdAtual,top,campo.value,isEdit?gasto.id:null);
     lista.innerHTML='';
     sugestoes.forEach(s=>{
       const b=el('button','desc-sugestao'); b.type='button'; b.setAttribute('role','option');
@@ -994,11 +958,8 @@ function formGasto(obraId, gasto, valorInicial, aoFechar){
 
   let pagto = isEdit ? (gasto.pagamento || 'pix') : 'pix';
   const datasPagamento={pix:$('#fData').value,cartao:OBRA_CALC.addMesesClampado($('#fData').value,1)};
-  const lerTaxaCartao=()=>{
-    const texto=($('#fJuros')?.value||'').trim();
-    return /^(?:\d+(?:[.,]\d+)?|[.,]\d+)$/.test(texto) ? Number(texto.replace(',','.')) : NaN;
-  };
-  const calcularCartao=()=>OBRA_CALC.parcelamentoCartao(parseNum($('#fVal').value),Number($('#fParc')?.value),lerTaxaCartao(),$('#fData').value);
+  const calcularCartao=()=>OBRA_CALC.parcelamentoCartao(parseNum($('#fVal').value),Number($('#fParc')?.value),
+    OBRA_CALC.lerTaxaCartao($('#fJuros')?.value),$('#fData').value);
   const atualizarCartao=()=>{
     if(isEdit) return;
     $('#fDataLabel').textContent=pagto==='cartao'?'Primeiro vencimento':'Data';
@@ -1052,10 +1013,8 @@ function formGasto(obraId, gasto, valorInicial, aoFechar){
       $('#fJuros').focus(); return;
     }
     if(cartao) valor=cartao.totalCompra;
-    const assinatura=[o.id,top,normalizaDescricao(desc),Math.round(valor*100),data0,nParc,cartao?.taxaMensal].join('|');
-    const pareceDuplicado=desc && o.gastos.some(x=>x.id!==(isEdit&&gasto.id)
-      && normalizaDescricao(x.descricao)===normalizaDescricao(desc)
-      && Math.round(x.valor*100)===Math.round(valor*100) && x.data===data0);
+    const assinatura=[o.id,top,OBRA_CALC.normalizaDescricao(desc),Math.round(valor*100),data0,nParc,cartao?.taxaMensal].join('|');
+    const pareceDuplicado=OBRA_CALC.gastoRepetido(o, desc, valor, data0, isEdit ? gasto.id : null);
     if(pareceDuplicado && duplicadoConfirmado!==assinatura){
       duplicadoConfirmado=assinatura;
       $('#dupWarning').textContent='Este gasto parece já lançado: mesma descrição, valor e data. Confira ou toque novamente para salvar mesmo assim.';
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -237,6 +237,63 @@
     });
   }
 
+  /* ---- descrição do gasto: sugestões e repetido (formulário do gasto) ---- */
+  /* Descrição comparável: sem acento, em minúsculas, aparada e com os espaços do meio juntados. */
+  function normalizaDescricao(s){
+    return semAcento(String(s || '')).trim().replace(/\s+/g, ' ');
+  }
+  /* Distância de edição (Levenshtein), em unidades UTF-16 como o índice das strings. */
+  function distanciaEdicao(a,b){
+    if(a===b) return 0;
+    if(!a.length) return b.length;
+    if(!b.length) return a.length;
+    let ant=Array.from({length:b.length+1},(_,i)=>i);
+    for(let i=1;i<=a.length;i++){
+      const atual=[i];
+      for(let j=1;j<=b.length;j++) atual[j]=Math.min(atual[j-1]+1,ant[j]+1,ant[j-1]+(a[i-1]===b[j-1]?0:1));
+      ant=atual;
+    }
+    return ant[b.length];
+  }
+  /* Sugestões de descrição: as descrições já lançadas em todas as obras, sem repetir (o texto é o do
+     lançamento mais recente), que contêm o termo ou, com 4 letras ou mais, ficam a até 2 edições dele.
+     Pesam o mesmo tópico, a mesma obra, o começo igual e o uso; até 5. ignorarId tira o gasto em edição. */
+  function sugestoesDescricao(obras, obraId, topicoId, termo, ignorarId){
+    const busca=normalizaDescricao(termo);
+    if(!busca) return [];
+    const unicas=new Map();
+    obras.forEach(o=>o.gastos.forEach(g=>{
+      if(o.id===obraId && g.id===ignorarId) return;
+      const texto=String(g.descricao||'').trim(), chave=normalizaDescricao(texto);
+      if(!chave) return;
+      const item=unicas.get(chave)||{texto,chave,vezes:0,mesmaObra:false,mesmoTopico:false,ultima:''};
+      item.vezes++;
+      if(o.id===obraId) item.mesmaObra=true;
+      if(g.topico===topicoId) item.mesmoTopico=true;
+      if((g.data||'')>=item.ultima){ item.ultima=g.data||''; item.texto=texto; }
+      unicas.set(chave,item);
+    }));
+    return [...unicas.values()].filter(x=>x.chave.includes(busca)
+        || (busca.length>=4 && Math.abs(x.chave.length-busca.length)<=2 && distanciaEdicao(x.chave,busca)<=2))
+      .sort((a,b)=>{
+        const sa=(a.mesmoTopico?100:0)+(a.mesmaObra?40:0)+(a.chave.startsWith(busca)?25:0)+Math.min(a.vezes,10);
+        const sb=(b.mesmoTopico?100:0)+(b.mesmaObra?40:0)+(b.chave.startsWith(busca)?25:0)+Math.min(b.vezes,10);
+        return sb-sa || b.ultima.localeCompare(a.ultima) || a.texto.localeCompare(b.texto,'pt-BR');
+      }).slice(0,5);
+  }
+  /* Gasto que parece já lançado na obra: mesma descrição comparável, mesmo valor em centavos e mesma
+     data. Sem descrição nunca parece repetido; ignorarId tira o gasto em edição. */
+  function gastoRepetido(obra, descricao, valor, data, ignorarId){
+    return !!descricao && obra.gastos.some(x=>x.id!==ignorarId
+      && normalizaDescricao(x.descricao)===normalizaDescricao(descricao)
+      && Math.round(x.valor*100)===Math.round(valor*100) && x.data===data);
+  }
+  /* Taxa de juros do cartão como o formulário lê: dígitos com vírgula ou ponto decimal, sem sinal; o resto é NaN. */
+  function lerTaxaCartao(texto){
+    const t=String(texto==null?'':texto).trim();
+    return /^(?:\d+(?:[.,]\d+)?|[.,]\d+)$/.test(t) ? Number(t.replace(',','.')) : NaN;
+  }
+
   /* Soma meses a uma data ISO; dia inexistente clampa no último dia do mês
      (31/01 + 1 mês = 28 ou 29/02). */
   function addMesesClampado(dataISO, meses){
@@ -405,7 +462,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, semAcento, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, money, moneyShort, moneyCurto, fmtMeses, canon };
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
```
Expected: `ℹ fail 0`; `✔ Test run with 130 tests … passed` (os 6 novos em `SugestoesTests`).

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Sugestoes.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SugestoesTests.swift \
  app.js \
  calc.js \
  scripts/vetores-calc.mjs \
  tests/vetores/calc.json
git commit -m "feat: sugestões de descrição, repetido e taxa do cartão no calc.js" -m "As sugestões de descrição, o aviso de gasto repetido e a leitura da taxa de juros do cartão saem do app.js para o calc.js, sem mudar o comportamento: recebem as obras por parâmetro e entram nos vetores. O app nativo copia as três regras e as confere pelos mesmos casos."
```

### Task 2: O que o formulário do gasto grava, no dados.js

O "Salvar" do gasto vira três funções puras: `conferirGasto` (a ordem do formulário: valor, descrição, cartão), `gastosLancados` (um gasto ou as parcelas do cartão, com `jurosCartao`) e `gastoEditado` (só o gasto editado; o pagamento só fora de parcela; Pix apaga `jurosCartao`). O `app.js` passa a usá-las. O toast "O valor precisa ter pelo menos um centavo por parcela" some: era código morto (o `parcelamentoCartao` já devolve `null` antes).

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift`
- Test (criar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift`
- Modify: `app.js`
- Modify: `dados.js`
- Test (alterar): `scripts/vetores-calc.mjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: Tarefa 1 (`gastoRepetido`, `normalizaDescricao`); `parcelamentoCartao` do `calc.js` (e o `parcelamentoCartao` do núcleo).
- Produces: `OBRA_DADOS.conferirGasto(entrada, editado, hoje)` → `{erro, mensagem?}` ou `{valor, data, parcelas, cartao}`; `gastosLancados(entrada, conferido, novoId)` → gastos; `gastoEditado(gasto, entrada, conferido)` → gasto. `entrada = {valor, topico, descricao (aparada), data, pagamento, parcelas, juros}`. Em Swift: `ErroDeFormulario(campo:mensagem:)`, `EntradaDoGasto`, `GastoConferido`, `conferirGasto(_:editado:hoje:) -> Result<GastoConferido, ErroDeFormulario>`, `gastosLancados(_:_:novoId:) -> [Gasto]`, `gastoEditado(_:_:_:) -> Gasto`.

- [ ] **Step 1: Escrever os vetores e os leitores**

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

extension EntradaDoGasto {
    /// A entrada de um caso dos vetores; juros ilegíveis vêm como null (o NaN do site).
    init(caso v: ValorJSON) {
        let o = v.comoObjeto!
        self.init(valor: o["valor"]!.numero, topico: o["topico"]!.comoTexto!, descricao: o["descricao"]!.comoTexto!,
                  data: o["data"]!.comoTexto!, pagamento: o["pagamento"]!.comoTexto!,
                  parcelas: Int(o["parcelas"]!.numero), juros: o["juros"]?.comoNumero ?? .nan)
    }
}

extension Parcelamento {
    init(caso v: ValorJSON) {
        let o = v.comoObjeto!
        self.init(valorCompra: o["valorCompra"]!.numero, taxaMensal: o["taxaMensal"]!.numero, nParcelas: Int(o["nParcelas"]!.numero),
                  totalCompra: o["totalCompra"]!.numero, jurosCompra: o["jurosCompra"]!.numero,
                  parcelas: o["parcelas"]!.comoLista!.map { ParcelaGerada(valor: $0.comoObjeto!["valor"]!.numero, data: $0.comoObjeto!["data"]!.comoTexto!) })
    }
}

extension GastoConferido {
    init(caso v: ValorJSON) {
        let o = v.comoObjeto!
        self.init(valor: o["valor"]!.numero, data: o["data"]!.comoTexto!, parcelas: Int(o["parcelas"]!.numero),
                  cartao: o["cartao"] == .nulo ? nil : Parcelamento(caso: o["cartao"]!))
    }
    var json: ValorJSON {
        .objeto(["valor": .numero(valor), "data": .texto(data), "parcelas": .numero(Double(parcelas)), "cartao": cartao?.json ?? .nulo])
    }
}

extension ErroDeFormulario {
    var json: ValorJSON {
        var o: [String: ValorJSON] = ["erro": .texto(campo)]
        if let mensagem { o["mensagem"] = .texto(mensagem) }
        return .objeto(o)
    }
}

/// Os ids de um caso, um a cada pedido, na ordem.
@MainActor final class FilaDeIds {
    private var ids: [String]
    init(_ v: ValorJSON) { ids = v.comoLista!.map { $0.comoTexto! } }
    func proximo() -> String { ids.removeFirst() }
}

@MainActor
struct FormulariosTests {
    @Test func conferirGastoNaOrdemDoFormulario() {
        for c in Vetores.casos("dados.conferirGasto") {
            let editado = c.args[1] == .nulo ? nil : Gasto(campos: c.args[1].comoObjeto!)
            let r = conferirGasto(EntradaDoGasto(caso: c.args[0]), editado: editado, hoje: c.args[2].comoTexto!)
            switch r {
            case .success(let g): confere(g.json, c.saida, .exata, c.caso)
            case .failure(let e): confere(e.json, c.saida, .exata, c.caso)
            }
        }
    }

    @Test func gastosLancadosComoOSiteGrava() {
        for c in Vetores.casos("dados.gastosLancados") {
            let fila = FilaDeIds(c.args[2])
            let r = gastosLancados(EntradaDoGasto(caso: c.args[0]), GastoConferido(caso: c.args[1]), novoId: fila.proximo)
            confere(.lista(r.map { .objeto($0.campos) }), c.saida, .exata, c.caso)
        }
    }

    @Test func gastoEditadoComoOSiteGrava() {
        for c in Vetores.casos("dados.gastoEditado") {
            let r = gastoEditado(Gasto(campos: c.args[0].comoObjeto!), EntradaDoGasto(caso: c.args[1]), GastoConferido(caso: c.args[2]))
            confere(.objeto(r.campos), c.saida, .exata, c.caso)
        }
    }
}
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -490,6 +490,48 @@ n('orçamento de modo desconhecido vira total', obraCom({ orcamento: { modo: 'xy
 n('orçamento total zero some', obraCom({ orcamento: { modo: 'total', total: 0 } }));
 n('orçamento que não é objeto some', obraCom({ orcamento: 'muito' }));
 
+/* O que o formulário do gasto grava. Os juros ilegíveis (NaN) vão como null no caso. */
+const ENTRADA = { valor: 1380, topico: 'matbasicos', descricao: 'Cimento', data: '2026-10-12', pagamento: 'pix', parcelas: 1, juros: 0 };
+const comNaN = e => ({ ...e, juros: e.juros ?? NaN });
+const conferir = (nome, entrada, editado) => caso('dados.conferirGasto', nome, [entrada, editado, HOJE], (e, ed, h) => D.conferirGasto(comNaN(e), ed, h));
+const EM_PIX = O1.gastos[0], PARCELA = O1.gastos[4];
+const NO_CARTAO = { id: 'k1', valor: 250.5, topico: 'outros', descricao: 'Fone', data: '2026-02-10', pagamento: 'cartao', notaSoDoSite: 'fica',
+  jurosCartao: { taxaMensal: 0, valorCompra: 250.5, nParcelas: 1, totalCompra: 250.5, jurosCompra: 0 } };
+conferir('pix', ENTRADA, null);
+conferir('valor zero', { ...ENTRADA, valor: 0 }, null);
+conferir('valor negativo', { ...ENTRADA, valor: -5 }, null);
+conferir('descrição com 500', { ...ENTRADA, descricao: 'a'.repeat(500) }, null);
+conferir('descrição com 501', { ...ENTRADA, descricao: 'a'.repeat(501) }, null);
+conferir('descrição conta unidades UTF-16', { ...ENTRADA, descricao: '😀'.repeat(250) + 'a' }, null);
+conferir('data vazia vira hoje', { ...ENTRADA, data: '' }, null);
+conferir('cartão 10x sem juros', { ...ENTRADA, pagamento: 'cartao', parcelas: 10, data: '2026-11-12' }, null);
+conferir('cartão 3x com juros', { ...ENTRADA, valor: 3000, pagamento: 'cartao', parcelas: 3, juros: 2.5, data: '2026-11-12' }, null);
+conferir('cartão 1x', { ...ENTRADA, pagamento: 'cartao', parcelas: 1, juros: 3, data: '2026-11-12' }, null);
+conferir('cartão com juros ilegíveis', { ...ENTRADA, pagamento: 'cartao', parcelas: 3, juros: null }, null);
+conferir('cartão com juros acima de 100', { ...ENTRADA, pagamento: 'cartao', parcelas: 3, juros: 101 }, null);
+conferir('cartão com mais parcelas que centavos', { ...ENTRADA, valor: 0.02, pagamento: 'cartao', parcelas: 3 }, null);
+conferir('cartão com data inválida', { ...ENTRADA, pagamento: 'cartao', parcelas: 3, data: '2026-02-30' }, null);
+conferir('cartão com data vazia vence a partir de hoje', { ...ENTRADA, pagamento: 'cartao', parcelas: 2, data: '' }, null);
+conferir('edição: data vazia fica a do gasto', { ...ENTRADA, data: '' }, EM_PIX);
+conferir('edição no cartão não parcela de novo', { ...ENTRADA, pagamento: 'cartao', parcelas: 5, juros: 99 }, EM_PIX);
+conferir('edição de parcela', { ...ENTRADA, valor: 1100, pagamento: 'cartao' }, PARCELA);
+conferir('edição com valor zero', { ...ENTRADA, valor: 0 }, EM_PIX);
+const lancados = (nome, entrada, ids) => caso('dados.gastosLancados', nome, [entrada, D.conferirGasto(comNaN(entrada), null, HOJE), ids],
+  (e, c, l) => { const fila = [...l]; return D.gastosLancados(e, c, () => fila.shift()); });
+lancados('pix', ENTRADA, ['n1']);
+lancados('cartão 1x guarda as condições da compra', { ...ENTRADA, pagamento: 'cartao', parcelas: 1, juros: 3, data: '2026-11-12' }, ['n1']);
+lancados('cartão 3x com juros: irmãos no mesmo grupo', { ...ENTRADA, valor: 3000, pagamento: 'cartao', parcelas: 3, juros: 2.5, data: '2026-01-31' },
+  ['grupo', 'n1', 'n2', 'n3']);
+lancados('cartão 7x sem juros, resto na última', { ...ENTRADA, valor: 1000, pagamento: 'cartao', parcelas: 7, data: '2026-11-12' },
+  ['grupo', 'n1', 'n2', 'n3', 'n4', 'n5', 'n6', 'n7']);
+const editado = (nome, gasto, entrada) => caso('dados.gastoEditado', nome, [gasto, entrada, D.conferirGasto(comNaN(entrada), gasto, HOJE)], D.gastoEditado);
+editado('pix continua pix', EM_PIX, { ...ENTRADA, valor: 99000, descricao: 'Sapatas' });
+editado('pix vira cartão', EM_PIX, { ...ENTRADA, pagamento: 'cartao' });
+editado('cartão vira pix: as condições da compra saem', NO_CARTAO, { ...ENTRADA });
+editado('cartão continua cartão: as condições ficam', NO_CARTAO, { ...ENTRADA, pagamento: 'cartao' });
+editado('parcela: muda só ela e o pagamento fica', PARCELA, { ...ENTRADA, valor: 1100, pagamento: 'cartao', data: '2026-09-30' });
+editado('data vazia fica a do gasto', EM_PIX, { ...ENTRADA, data: '' });
+
 /* ---------- push.js e id ---------- */
 for(const t of ['', 'a', 'abc', 'fcm-token:APA91bHun4MxP5egoKMwt2KZFBaFUH-1RYqx', 'https://fcm.googleapis.com/fcm/send/eXyZ', 'ç😀', 'x'.repeat(300)])
   caso('push.hashEndpoint', JSON.stringify(t.length > 40 ? t.slice(0, 40) + '…' : t), [t], P.hashEndpoint);
```


- [ ] **Step 2: Ver falhar**

Run: `node scripts/vetores-calc.mjs`
Expected: FAIL com `TypeError: D.conferirGasto is not a function`.

- [ ] **Step 3: Implementar**

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift`:

```swift
import Foundation

/* O que os formulários do site gravam (dados.js): a conferência na ordem do formulário e os objetos que vão para o
   documento. O app grava exatamente o que o site gravaria com as mesmas respostas; cada regra tem caso nos vetores. */

/// Erro de um formulário. Sem mensagem, a tela volta ao campo (o valor do gasto, o nome da obra) sem texto, como o site.
public struct ErroDeFormulario: Error, Equatable, Sendable {
    public let campo: String
    public let mensagem: String?
    public init(campo: String, mensagem: String? = nil) { self.campo = campo; self.mensagem = mensagem }
}

/// O que a pessoa respondeu no formulário do gasto: valor em reais, descrição aparada, parcelas inteiras e os juros já
/// lidos por `lerTaxaCartao` (NaN quando ilegíveis).
public struct EntradaDoGasto: Equatable, Sendable {
    public var valor: Double
    public var topico: String
    public var descricao: String
    /// AAAA-MM-DD; vazia vale a data do gasto em edição, ou hoje.
    public var data: String
    /// "pix" ou "cartao".
    public var pagamento: String
    public var parcelas: Int
    public var juros: Double

    public init(valor: Double, topico: String, descricao: String, data: String, pagamento: String, parcelas: Int = 1, juros: Double = 0) {
        self.valor = valor; self.topico = topico; self.descricao = descricao; self.data = data
        self.pagamento = pagamento; self.parcelas = parcelas; self.juros = juros
    }
}

/// O gasto conferido: o valor que vai para o documento (no cartão, o total com juros), a data (no cartão, o primeiro
/// vencimento), quantas parcelas e o parcelamento do cartão num lançamento novo.
public struct GastoConferido: Equatable, Sendable {
    public let valor: Double
    public let data: String
    public let parcelas: Int
    public let cartao: Parcelamento?
}

/// `conferirGasto` do dados.js: o "Salvar" do gasto na ordem do formulário (valor, descrição, cartão).
public func conferirGasto(_ entrada: EntradaDoGasto, editado: Gasto?, hoje: String) -> Result<GastoConferido, ErroDeFormulario> {
    let valor = entrada.valor
    if !valor.isFinite || valor <= 0 { return .failure(ErroDeFormulario(campo: "valor")) }
    if entrada.descricao.utf16.count > Limites.descricao {
        return .failure(ErroDeFormulario(campo: "descricao", mensagem: "Use até \(Limites.descricao) caracteres."))
    }
    let data = entrada.data.isEmpty ? (editado?.data ?? hoje) : entrada.data
    let parcelaDeCompra = editado?.grupoId != nil
    let cartao = entrada.pagamento == "cartao"
    let parcelas = !parcelaDeCompra && cartao && entrada.parcelas != 0 ? entrada.parcelas : 1   // o `parcelas || 1` do site
    var parcelamento: Parcelamento?
    if editado == nil && cartao {
        guard let p = parcelamentoCartao(valor, entrada.parcelas, entrada.juros, data) else {
            return .failure(ErroDeFormulario(campo: "cartao", mensagem: "Confira valor, parcelas, data e taxa de juros"))
        }
        parcelamento = p
    }
    return .success(GastoConferido(valor: parcelamento?.totalCompra ?? valor, data: data, parcelas: parcelas, cartao: parcelamento))
}

/// `gastosLancados` do dados.js: no cartão parcelado, um gasto por parcela, com o mesmo `grupoId` (o primeiro id pedido)
/// e `parcela {n, de}`; no cartão, as condições da compra em `jurosCartao`; senão, um gasto só.
public func gastosLancados(_ entrada: EntradaDoGasto, _ conferido: GastoConferido, novoId: () -> String) -> [Gasto] {
    var condicoes: [String: ValorJSON] = [:]
    if let c = conferido.cartao {
        condicoes["jurosCartao"] = .objeto(["taxaMensal": .numero(c.taxaMensal), "valorCompra": .numero(c.valorCompra),
                                            "nParcelas": .numero(Double(c.nParcelas)), "totalCompra": .numero(c.totalCompra),
                                            "jurosCompra": .numero(c.jurosCompra)])
    }
    if conferido.parcelas > 1, let c = conferido.cartao {
        let grupoId = novoId()
        return c.parcelas.enumerated().map { i, p in
            var campos: [String: ValorJSON] = ["id": .texto(novoId()), "valor": .numero(p.valor), "topico": .texto(entrada.topico),
                                               "descricao": .texto(entrada.descricao), "data": .texto(p.data), "pagamento": .texto("cartao"),
                                               "grupoId": .texto(grupoId),
                                               "parcela": .objeto(["n": .numero(Double(i + 1)), "de": .numero(Double(conferido.parcelas))])]
            campos.merge(condicoes) { _, novo in novo }
            return Gasto(campos: campos)
        }
    }
    var campos: [String: ValorJSON] = ["id": .texto(novoId()), "valor": .numero(conferido.valor), "topico": .texto(entrada.topico),
                                       "descricao": .texto(entrada.descricao), "data": .texto(conferido.data),
                                       "pagamento": .texto(entrada.pagamento)]
    campos.merge(condicoes) { _, novo in novo }
    return [Gasto(campos: campos)]
}

/// `gastoEditado` do dados.js: valor, tópico, descrição e data; o pagamento só fora de uma compra parcelada; fora do
/// cartão, sem `jurosCartao`. Os outros campos, inclusive os que o app não conhece, ficam como estavam.
public func gastoEditado(_ gasto: Gasto, _ entrada: EntradaDoGasto, _ conferido: GastoConferido) -> Gasto {
    var g = gasto
    g.valor = conferido.valor
    g.topico = entrada.topico
    g.descricao = entrada.descricao
    g.data = conferido.data
    if gasto.grupoId == nil { g.pagamento = entrada.pagamento }
    if entrada.pagamento != "cartao" { g.campos["jurosCartao"] = nil }
    return g
}
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -999,22 +999,17 @@ function formGasto(obraId, gasto, valorInicial, aoFechar){
   if(isEdit) $('#fVal').focus();
   $('#cCancel').onclick = fechar;
   $('#cSave').onclick = ()=>{
-    let valor = parseNum($('#fVal').value);
-    if(!Number.isFinite(valor) || valor<=0){ if(isEdit) $('#fVal').focus(); else pedirValor(); return; }
-    const desc = $('#fDesc').value.trim();
-    if(!textoValido(desc, 'descricao', $('#fDesc'))) return;
+    // regras puras no dados.js e no calc.js, as mesmas que o app nativo confere pelos vetores
+    const entrada = { valor:parseNum($('#fVal').value), topico:top, descricao:$('#fDesc').value.trim(), data:$('#fData').value,
+      pagamento:pagto, parcelas:parseInt($('#fParc')?.value,10)||1, juros:OBRA_CALC.lerTaxaCartao($('#fJuros')?.value) };
+    const r = OBRA_DADOS.conferirGasto(entrada, isEdit ? gasto : null, todayISO());
+    if(r.erro==='valor'){ if(isEdit) $('#fVal').focus(); else pedirValor(); return; }
+    if(r.erro==='descricao'){ toast(r.mensagem, "erro"); $('#fDesc').focus(); return; }
     const o = obraById(oFix ? oFix.id : $('#fObra').value);
     if(!o) return;
-    const data0 = $('#fData').value || (isEdit ? gasto.data : todayISO());
-    const nParc = !isParcela && pagto==='cartao' ? parseInt($('#fParc').value,10)||1 : 1;
-    const cartao = !isEdit && pagto==='cartao' ? calcularCartao() : null;
-    if(!isEdit && pagto==='cartao' && !cartao){
-      toast('Confira valor, parcelas, data e taxa de juros');
-      $('#fJuros').focus(); return;
-    }
-    if(cartao) valor=cartao.totalCompra;
-    const assinatura=[o.id,top,OBRA_CALC.normalizaDescricao(desc),Math.round(valor*100),data0,nParc,cartao?.taxaMensal].join('|');
-    const pareceDuplicado=OBRA_CALC.gastoRepetido(o, desc, valor, data0, isEdit ? gasto.id : null);
+    if(r.erro==='cartao'){ toast(r.mensagem); $('#fJuros').focus(); return; }
+    const assinatura=[o.id,top,OBRA_CALC.normalizaDescricao(entrada.descricao),Math.round(r.valor*100),r.data,r.parcelas,r.cartao?.taxaMensal].join('|');
+    const pareceDuplicado=OBRA_CALC.gastoRepetido(o, entrada.descricao, r.valor, r.data, isEdit ? gasto.id : null);
     if(pareceDuplicado && duplicadoConfirmado!==assinatura){
       duplicadoConfirmado=assinatura;
       $('#dupWarning').textContent='Este gasto parece já lançado: mesma descrição, valor e data. Confira ou toque novamente para salvar mesmo assim.';
@@ -1023,30 +1018,10 @@ function formGasto(obraId, gasto, valorInicial, aoFechar){
       return;
     }
     if(isEdit){
-      const g = o.gastos.find(x=>x.id===gasto.id); if(!g) return;
-      g.valor = valor; g.topico = top;
-      g.descricao = desc;
-      g.data = data0;
-      if(!isParcela) g.pagamento = pagto;
-      if(pagto!=='cartao') delete g.jurosCartao;
+      const i = o.gastos.findIndex(x=>x.id===gasto.id); if(i<0) return;
+      o.gastos[i] = OBRA_DADOS.gastoEditado(o.gastos[i], entrada, r);
     } else {
-      const dadosCartao = cartao ? { jurosCartao:{taxaMensal:cartao.taxaMensal,valorCompra:cartao.valorCompra,
-        nParcelas:cartao.nParcelas,totalCompra:cartao.totalCompra,jurosCompra:cartao.jurosCompra} } : {};
-      if(nParc > 1){
-        const grupoId = uid();
-        const parcelas = cartao.parcelas;
-        if(!parcelas.length){
-          toast('O valor precisa ter pelo menos um centavo por parcela');
-          $('#fParc').focus();
-          return;
-        }
-        parcelas.forEach((p,i)=>{
-          o.gastos.push({ id:uid(), valor:p.valor, topico:top, descricao:desc,
-            data:p.data, pagamento:'cartao', grupoId, parcela:{n:i+1, de:nParc}, ...dadosCartao });
-        });
-      } else {
-        o.gastos.push({ id:uid(), valor, topico:top, descricao:desc, data:data0, pagamento:pagto, ...dadosCartao });
-      }
+      o.gastos.push(...OBRA_DADOS.gastosLancados(entrada, r, uid));
     }
     salvarComAviso(isEdit ? 'Gasto atualizado' : 'Gasto lançado com sucesso')
       .then(()=>OBRA_NATIVO.vibrar(), ()=>{}); // vibra só com o servidor confirmando
```

Em `dados.js`:

```diff
--- a/dados.js
+++ b/dados.js
@@ -66,7 +66,47 @@
       taxaMensal:taxa>0&&taxa<=20?taxa:1,
       topicosCustom:lista(config.topicosCustom,t=>texto(t.id)&&texto(t.nm)?{...t,id:texto(t.id),nm:texto(t.nm),ic:texto(t.ic)||'etiqueta'}:null)}};
   }
-  const api={normaliza,LIMITES};
+  /* ---- o que o formulário do gasto grava (app.js formGasto) ----
+     O calc.js carrega antes deste arquivo no navegador; no Node vem pelo require. */
+  const calc = () => root.OBRA_CALC || require('./calc.js');
+  /* "Salvar" do gasto, na ordem do formulário. entrada: {valor, topico, descricao, data, pagamento, parcelas,
+     juros} como a tela leu (valor em reais, descrição aparada, parcelas inteiras e juros pelo lerTaxaCartao);
+     editado: o gasto em edição ou null; hoje: AAAA-MM-DD. Erro: {erro:'valor'} (a tela volta ao valor),
+     {erro:'descricao', mensagem} ou {erro:'cartao', mensagem}. Certo: {valor, data, parcelas, cartao}, com o
+     valor que vai para o documento (no cartão, o total com juros) e a data (no cartão, o primeiro vencimento). */
+  function conferirGasto(entrada, editado, hoje){
+    const valor=entrada.valor;
+    if(!Number.isFinite(valor) || valor<=0) return {erro:'valor'};
+    if(entrada.descricao.length>LIMITES.descricao) return {erro:'descricao', mensagem:`Use até ${LIMITES.descricao} caracteres.`};
+    const data=entrada.data || (editado ? editado.data : hoje);
+    const parcelas=!(editado && editado.grupoId) && entrada.pagamento==='cartao' ? entrada.parcelas||1 : 1;
+    const cartao=!editado && entrada.pagamento==='cartao' ? calc().parcelamentoCartao(valor, entrada.parcelas, entrada.juros, data) : null;
+    if(!editado && entrada.pagamento==='cartao' && !cartao) return {erro:'cartao', mensagem:'Confira valor, parcelas, data e taxa de juros'};
+    return {valor:cartao ? cartao.totalCompra : valor, data, parcelas, cartao};
+  }
+  /* Os gastos de um lançamento novo: no cartão parcelado, um por parcela, com o mesmo grupoId (o primeiro id
+     pedido) e parcela {n, de}; no cartão, as condições da compra em jurosCartao; senão, um gasto só. */
+  function gastosLancados(entrada, conferido, novoId){
+    const c=conferido.cartao;
+    const dadosCartao=c ? {jurosCartao:{taxaMensal:c.taxaMensal, valorCompra:c.valorCompra, nParcelas:c.nParcelas,
+      totalCompra:c.totalCompra, jurosCompra:c.jurosCompra}} : {};
+    if(conferido.parcelas>1){
+      const grupoId=novoId();
+      return c.parcelas.map((p,i)=>({id:novoId(), valor:p.valor, topico:entrada.topico, descricao:entrada.descricao,
+        data:p.data, pagamento:'cartao', grupoId, parcela:{n:i+1, de:conferido.parcelas}, ...dadosCartao}));
+    }
+    return [{id:novoId(), valor:conferido.valor, topico:entrada.topico, descricao:entrada.descricao, data:conferido.data,
+      pagamento:entrada.pagamento, ...dadosCartao}];
+  }
+  /* O gasto editado: valor, tópico, descrição e data; o pagamento só fora de uma compra parcelada; fora do
+     cartão, sem jurosCartao. Os outros campos, inclusive os que o app não conhece, ficam como estavam. */
+  function gastoEditado(gasto, entrada, conferido){
+    const g={...gasto, valor:conferido.valor, topico:entrada.topico, descricao:entrada.descricao, data:conferido.data};
+    if(!gasto.grupoId) g.pagamento=entrada.pagamento;
+    if(entrada.pagamento!=='cartao') delete g.jurosCartao;
+    return g;
+  }
+  const api={normaliza,LIMITES,conferirGasto,gastosLancados,gastoEditado};
   if(typeof module !== 'undefined' && module.exports) module.exports=api;
   else root.OBRA_DADOS=api;
 })(typeof window !== 'undefined' ? window : globalThis);
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```


- [ ] **Step 4: Ver passar**

Run: `node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4`, o núcleo como na Tarefa 1 e, com o servidor de testes (`node tests/browser/servidor.cjs &`), `node tests/browser/cartao.cjs`.
Expected: `ℹ fail 0`; `✔ Test run with 133 tests … passed`; `ok - juros mensais, parcelas, edição sem reaplicar juros e Pix sem taxa`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift \
  app.js \
  dados.js \
  scripts/vetores-calc.mjs \
  tests/vetores/calc.json
git commit -m "feat: o que o formulário do gasto grava, no dados.js" -m "O Salvar do gasto passa a ser três funções puras do dados.js: a conferência na ordem do formulário, os gastos de um lançamento (com as parcelas do cartão) e o gasto editado. O app.js as usa e os vetores as conferem, para o app nativo gravar exatamente o mesmo documento. Sai o toast de um centavo por parcela, que nunca aparecia."
```

### Task 3: Parcela apagada com a folha aberta não se perde quando a nuvem chega

Defeito do site achado no inventário (seção 12, item 6): a folha "Excluir parcela" guardava a obra do momento do toque no ×; se um snapshot trocasse o `db` com a folha aberta, a exclusão ia para uma cópia velha e a parcela voltava. Agora o toque relê a obra.

**Files:**
- Modify: `app.js`
- Test (alterar): `tests/browser/cartao.cjs`

**Interfaces:**
- Consumes: `obraById` do `app.js`.
- Produces: nada novo.

- [ ] **Step 1: Escrever o teste de browser**

Em `tests/browser/cartao.cjs`:

```diff
--- a/tests/browser/cartao.cjs
+++ b/tests/browser/cartao.cjs
@@ -59,8 +59,14 @@ const {chromium}=require('playwright');
     await page.locator('#fParc').selectOption('3');
     await page.locator('#cSave').click();
     assert.deepEqual(await page.evaluate(()=>obraById('o').gastos.slice(-3).map(g=>g.valor)),[33.33,33.33,33.34]);
+    // Apagar só esta parcela com a folha aberta enquanto um snapshot troca o db: a exclusão vai para a obra de agora.
+    const ultima=await page.evaluate(()=>obraById('o').gastos.at(-1).id);
+    await page.locator('#oGastos li',{hasText:'(3/3)'}).locator('.li-del').click();
+    await page.evaluate(()=>{ db=normaliza(JSON.parse(JSON.stringify(db))); });
+    await page.locator('#dUma').click();
+    assert.equal(await page.evaluate(id=>obraById('o').gastos.some(g=>g.id===id),ultima),false,'a parcela apagada voltou');
     await page.waitForTimeout(200);
     assert.deepEqual(await page.evaluate(()=>errosCartao),[]);
-    console.log('ok - juros mensais, parcelas, edição sem reaplicar juros e Pix sem taxa');
+    console.log('ok - juros mensais, parcelas, edição sem reaplicar juros, Pix sem taxa e parcela apagada com snapshot no meio');
   }finally{await browser.close();}
 })().catch(e=>{console.error(e);process.exitCode=1;});
```


- [ ] **Step 2: Ver falhar**

Run (com o servidor de testes no ar): `node tests/browser/cartao.cjs`
Expected: FAIL com `AssertionError [ERR_ASSERTION]: a parcela apagada voltou`.

- [ ] **Step 3: Corrigir**

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -759,8 +759,9 @@ function gastoRow(o, g, opts){
         <button class="layout-19 btn ghost" id="dCancel">Cancelar</button>
       </div>`);
     $('#dCancel').onclick = fechar;
-    $('#dUma').onclick = ()=>{ oo.gastos = oo.gastos.filter(x=>x.id!==g.id); save(); renderAll(); fechar(); };
-    $('#dTodas').onclick = ()=>{ oo.gastos = oo.gastos.filter(x=>x.grupoId!==g.grupoId); save(); renderAll(); fechar(); };
+    // relê a obra no toque: um snapshot com a folha aberta troca os objetos do db, e a exclusão iria para uma cópia velha
+    $('#dUma').onclick = ()=>{ const atual = obraById(o.id); if(atual){ atual.gastos = atual.gastos.filter(x=>x.id!==g.id); save(); renderAll(); } fechar(); };
+    $('#dTodas').onclick = ()=>{ const atual = obraById(o.id); if(atual){ atual.gastos = atual.gastos.filter(x=>x.grupoId!==g.grupoId); save(); renderAll(); } fechar(); };
   };
   li.appendChild(del);
   return li;
```


- [ ] **Step 4: Ver passar**

Run: `node tests/browser/cartao.cjs`
Expected: `ok - juros mensais, parcelas, edição sem reaplicar juros, Pix sem taxa e parcela apagada com snapshot no meio`.

- [ ] **Step 5: Commit**

```bash
git add app.js \
  tests/browser/cartao.cjs
git commit -m "fix: parcela apagada com a folha aberta não se perde quando a nuvem chega" -m "A folha de apagar parcela guardava a obra do momento do toque. Se a nuvem trocasse os dados com a folha aberta, a exclusão ia para uma cópia velha e a parcela voltava. Agora o toque em Excluir relê a obra, como o gasto simples já fazia."
```

### Task 4: Teclado de valor nos vetores

O app nativo copia a regra dos centavos do `teclado.js` (dígito pela direita, "00", apagar, teto de R$ 99.999.999,99, reais ↔ centavos com o `toFixed(4)`). As funções já eram exportadas; entram nos vetores, com a guarda "toda exportação do teclado.js tem vetor", e o `teclado.js` passa a disparar o workflow do app. O `toFixedJS` do núcleo aceita até 4 casas, com casos novos.

**Files:**
- Modify: `.github/workflows/app-ios.yml`
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Centavos.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/NumeroJS.swift`
- Test (criar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CentavosTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/vetores.test.mjs`
- Test (alterar): `tests/workflow.test.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `TETO`, `aplicarTecla`, `fmtCentavos`, `centavosParaReais`, `reaisParaCentavos` do `teclado.js`.
- Produces: em Swift, `tetoDoTeclado`, `enum TeclaDeValor` (`digito(Int)`, `duploZero`, `apagar`; `nome`, `init?(nome:)`), `aplicarTecla(_:_:)`, `fmtCentavos(_:)`, `centavosParaReais(_:)`, `reaisParaCentavos(_:)`.

- [ ] **Step 1: Escrever a guarda, os vetores e os leitores**

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CentavosTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

struct CentavosTests {
    @Test func tetoDoSite() {
        #expect(Vetores.casos("teclado.TETO").first?.saida == .numero(Double(tetoDoTeclado)))
    }

    @Test func teclaPelaDireitaComoAMaquininha() {
        for c in Vetores.casos("teclado.aplicarTecla") {
            let centavos = Int(c.args[0].numero)
            let r = TeclaDeValor(nome: c.args[1].comoTexto!).map { aplicarTecla(centavos, $0) } ?? centavos   // não é tecla: o site ignora
            confere(.numero(Double(r)), c.saida, .exata, c.caso)
        }
    }

    @Test func nomeDaTeclaIdaEVolta() {
        for t in [TeclaDeValor.digito(0), .digito(9), .duploZero, .apagar] { #expect(TeclaDeValor(nome: t.nome) == t) }
        #expect(TeclaDeValor(nome: "10") == nil)
        #expect(TeclaDeValor(nome: "x") == nil)
    }

    @Test func visorDoValor() {
        for c in Vetores.casos("teclado.fmtCentavos") { confere(.texto(fmtCentavos(Int(c.args[0].numero))), c.saida, .exata, c.caso) }
    }

    @Test func centavosEReais() {
        for c in Vetores.casos("teclado.centavosParaReais") {
            confere(.numero(centavosParaReais(Int(c.args[0].numero))), c.saida, .exata, c.caso)
        }
        for c in Vetores.casos("teclado.reaisParaCentavos") {
            confere(.numero(Double(reaisParaCentavos(c.args[0].numero))), c.saida, .exata, c.caso)
        }
    }
}
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -1,5 +1,5 @@
 /* Vetores de teste compartilhados entre o site e o app nativo (docs/specs/2026-10-06-app-nativo-design.md,
-   "Testes e validação"). Roda as funções de verdade do calc.js, do dados.js, do push.js e do cadastro.js sobre casos
+   "Testes e validação"). Roda as funções de verdade do calc.js, do dados.js, do push.js, do cadastro.js e do teclado.js sobre casos
    fixos e grava entrada e saída em tests/vetores/calc.json. O teste do site (tests/vetores.test.mjs)
    confere que o arquivo está em dia com o código; o núcleo Swift (app-ios/CusttaNucleo) lê o mesmo
    arquivo. Se as duas cópias das regras divergirem, um dos lados falha.
@@ -36,6 +36,7 @@ const C = require('../calc.js');
 const D = require('../dados.js');
 const P = require('../push.js');
 const K = require('../cadastro.js');
+const T = require('../teclado.js');
 
 /* ---------- registro dos casos ---------- */
 const grupos = {};
@@ -539,6 +540,16 @@ for(const t of ['', 'a', 'abc', 'fcm-token:APA91bHun4MxP5egoKMwt2KZFBaFUH-1RYqx'
 for(const ms of [0, 35, 36, 1759750000000, 1700000000123, 4102444800000])
   caso('id.base36', String(ms), [ms], x => x.toString(36));
 
+/* ---------- teclado.js: o teclado de valor (centavos como inteiro) ---------- */
+constante('teclado.TETO', T.TETO);
+for(const [c, t] of [[0, '1'], [1, '2'], [12, '3'], [0, '0'], [0, '00'], [5, '00'], [123, 'del'], [0, 'del'], [999999999, '9'],
+  [9999999999, '1'], [999999999, '00'], [99999999, '00'], [12, 'x'], [12, '10'], [9999999999, 'del']])
+  caso('teclado.aplicarTecla', `${c} ${t}`, [c, t], T.aplicarTecla);
+for(const c of [0, 5, 100, 123456, 100000000, 9999999999]) caso('teclado.fmtCentavos', String(c), [c], T.fmtCentavos);
+for(const c of [0, 1, 12345, 9999999999]) caso('teclado.centavosParaReais', String(c), [c], T.centavosParaReais);
+for(const r of [0, 8.7, 0.1 + 0.2, 1380, -5, 99999999.99, 1e12, 0.005, 1.005])
+  caso('teclado.reaisParaCentavos', String(r), [r], T.reaisParaCentavos);
+
 /* ---------- cadastro.js ---------- */
 constante('cadastro.REGRAS_SENHA', K.REGRAS_SENHA);
 constante('cadastro.ORIGENS', K.ORIGENS);
@@ -614,7 +625,9 @@ for(const s of ['  12 ', '0x10', '0X1f', '1,5', '1e3', '1E-2', '.5', '5.', '+5',
   '0x200000000000018', '0o20000000000000003', '0b1000000000000000000000000000000000000000000000000000011', '0o4000000000000000014'])
   caso('js.textoParaNumero', JSON.stringify(s), [s], v => { const x = Number(v); return Number.isFinite(x) ? x : null; });
 for(const [x, casas] of [[8.25, 1], [1.005, 2], [2.5, 0], [0.5, 0], [10.25, 1], [12.35, 1], [1.45, 1], [999.95, 1], [0.05, 1], [1.25, 1], [1234.5678, 2], [0, 2],
-  [-1.5, 0], [-0.001, 2], [1e21, 2]]) // bordas: negativo no empate, negativo que zera e o limite de 1e21
+  [-1.5, 0], [-0.001, 2], [1e21, 2], // bordas: negativo no empate, negativo que zera e o limite de 1e21
+  // 4 casas, as do teclado de valor (reaisParaCentavos): o toFixed(4) acerta o 8,7 × 100 e o 1,005 × 100
+  [8.7 * 100, 4], [1.005 * 100, 4], [0.1 * 3 * 100, 4], [9999999999, 4], [0.5, 4], [1.00005, 4], [2.00015, 4], [99999999.99 * 100, 4], [123.45675, 3]])
   caso('js.toFixed', `${x}.toFixed(${casas})`, [x, casas], (v, c) => v.toFixed(c));
 for(const x of [0.5, 1.5, 2.5, -0.5, -1.5, -2.5, 0.49999999999999994, 1e16 + 1, -0.4])
   caso('js.round', String(x), [x], v => Math.round(v) + 0); // + 0 tira o −0, que o JSON já não guarda
```

Em `tests/vetores.test.mjs`:

```diff
--- a/tests/vetores.test.mjs
+++ b/tests/vetores.test.mjs
@@ -1,5 +1,5 @@
 /* Os vetores compartilhados (tests/vetores/calc.json) têm de estar em dia com o calc.js, o
-   dados.js, o push.js e o cadastro.js: o app nativo confere a cópia dele das regras contra este arquivo
+   dados.js, o push.js, o cadastro.js e o teclado.js: o app nativo confere a cópia dele das regras contra este arquivo
    (app-ios/CusttaNucleo). Falhou aqui? Rode `npm run vetores` e faça commit do arquivo junto
    com a mudança da regra; o workflow app-ios roda o lado Swift. */
 import { test } from 'node:test';
@@ -54,6 +54,11 @@ test('toda exportação do cadastro.js tem vetor', () => {
   assert.deepEqual(faltam, []);
 });
 
+test('toda exportação do teclado.js tem vetor', () => {
+  const faltam = Object.keys(require('../teclado.js')).filter(k => !vetores.grupos[`teclado.${k}`]);
+  assert.deepEqual(faltam, []);
+});
+
 test('toda exportação do dados.js tem vetor; do push.js, a chave do token', () => {
   const faltam = Object.keys(require('../dados.js')).filter(k => !vetores.grupos[`dados.${k}`]);
   assert.deepEqual(faltam, []);
```

Em `tests/workflow.test.cjs`:

```diff
--- a/tests/workflow.test.cjs
+++ b/tests/workflow.test.cjs
@@ -222,7 +222,7 @@ assert.match(appIos, /runs-on:\s*macos-26/, 'o app nativo precisa do runner macO
 assert.match(appIos, /swift test --package-path app-ios\/CusttaNucleo/, 'sem o swift test do núcleo');
 assert.match(appIos, /TZ:\s*America\/Sao_Paulo/, 'os testes do núcleo rodam no fuso dos vetores');
 assert.match(appIos, /DEVELOPER_DIR:\s*\/Applications\/Xcode_26\.6\.app\/Contents\/Developer/, 'o Xcode da CI é fixo: o padrão do runner muda sem aviso');
-for(const caminho of ['app-ios/**', 'calc.js', 'dados.js', 'push.js', 'cadastro.js', 'scripts/vetores-calc.mjs', 'scripts/simulador-ios.mjs', 'tests/vetores/**', '.github/workflows/app-ios.yml'])
+for(const caminho of ['app-ios/**', 'calc.js', 'dados.js', 'push.js', 'cadastro.js', 'teclado.js', 'scripts/vetores-calc.mjs', 'scripts/simulador-ios.mjs', 'tests/vetores/**', '.github/workflows/app-ios.yml'])
   assert.ok(appIos.includes(`- '${caminho}'`), `app-ios.yml não dispara quando ${caminho} muda`);
 assert.ok(!/^on:\n(?:.*\n)*?\s{2}push:/m.test(appIos), 'o app nativo não roda em todo push');
 assert.match(appIos, /workflow_dispatch:/, 'o app nativo precisa do botão manual');
```


- [ ] **Step 2: Ver falhar**

Run: `node --test tests/vetores.test.mjs`
Expected: FAIL em `✖ toda exportação do teclado.js tem vetor`.

- [ ] **Step 3: Implementar**

Em `.github/workflows/app-ios.yml`:

```diff
--- a/.github/workflows/app-ios.yml
+++ b/.github/workflows/app-ios.yml
@@ -20,6 +20,7 @@ on:
       - 'dados.js'
       - 'push.js'
       - 'cadastro.js'
+      - 'teclado.js'
       - 'scripts/vetores-calc.mjs'
       - 'scripts/simulador-ios.mjs'
       - 'tests/vetores/**'
```

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/Centavos.swift`:

```swift
import Foundation

/* O teclado de valor do site (teclado.js), na parte pura: centavos como inteiro, dígitos entrando pela direita como
   numa maquininha. Cada regra tem caso nos vetores (grupos teclado.*). */

/// `TETO` do teclado.js: R$ 99.999.999,99. Acima disso a tecla é ignorada, para nunca mudar o número em silêncio.
public let tetoDoTeclado = 9_999_999_999

/// Uma tecla do teclado de valor.
public enum TeclaDeValor: Equatable, Sendable {
    case digito(Int)
    case duploZero
    case apagar

    /// O nome da tecla no teclado.js ('0'…'9', '00', 'del').
    public var nome: String {
        switch self {
        case .digito(let d): return String(d)
        case .duploZero: return "00"
        case .apagar: return "del"
        }
    }

    /// '0'…'9', '00' e 'del'; o resto não é tecla (o teclado.js ignora).
    public init?(nome: String) {
        switch nome {
        case "00": self = .duploZero
        case "del": self = .apagar
        default:
            guard nome.count == 1, let d = Int(nome), (0...9).contains(d) else { return nil }
            self = .digito(d)
        }
    }
}

/// `aplicarTecla` do teclado.js: dígito pela direita, "00" multiplica por 100, apagar tira o último dígito.
public func aplicarTecla(_ centavos: Int, _ tecla: TeclaDeValor) -> Int {
    let c = max(0, centavos)
    switch tecla {
    case .apagar: return c / 10
    case .duploZero:
        let (n, estourou) = c.multipliedReportingOverflow(by: 100)
        return estourou || n > tetoDoTeclado ? c : n
    case .digito(let d):
        let (n, estourou) = c.multipliedReportingOverflow(by: 10)
        return estourou || n + d > tetoDoTeclado ? c : n + d
    }
}

/// `fmtCentavos` do teclado.js: "1.234,56" (milhar com ponto, sempre duas casas), sem o "R$".
public func fmtCentavos(_ centavos: Int) -> String {
    let c = max(0, centavos)
    let resto = c % 100
    return agruparMilhar(String(c / 100)) + "," + (resto < 10 ? "0\(resto)" : "\(resto)")
}

/// `centavosParaReais` do teclado.js.
public func centavosParaReais(_ centavos: Int) -> Double { Double(centavos) / 100 }

/// `reaisParaCentavos` do teclado.js: arredonda pelo toFixed(4) antes (8,7 × 100 dá 869,999… em ponto flutuante) e para no
/// teto; zero ou negativo vira 0.
public func reaisParaCentavos(_ reais: Double) -> Int {
    guard reais.isFinite, reais > 0 else { return 0 }
    let arredondado = arredondarJS(parseFloatJS(toFixedJS(reais * 100, 4)) ?? 0)
    return Int(min(Double(tetoDoTeclado), arredondado))
}
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/NumeroJS.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/NumeroJS.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/NumeroJS.swift
@@ -52,11 +52,11 @@ public func arredondarJS(_ x: Double) -> Double {
     return x - piso >= 0.5 ? piso + 1 : piso
 }
 
-/// `numero.toFixed(casas)` do JavaScript para casas de 0 a 2, as que o site usa: arredonda pelo valor
-/// binário exato e, no empate exato, fica com o maior (8.25 → "8.3", 1.005 → "1.00"). Com mais casas,
-/// valor grande estouraria os 128 bits da conta.
+/// `numero.toFixed(casas)` do JavaScript para casas de 0 a 4, as que o site usa (o teclado de valor arredonda em 4):
+/// arredonda pelo valor binário exato e, no empate exato, fica com o maior (8.25 → "8.3", 1.005 → "1.00"). Abaixo de
+/// 1e21 a conta cabe em 84 bits com 4 casas; com muito mais casas, valor grande estouraria os 128 bits.
 public func toFixedJS(_ x: Double, _ casas: Int) -> String {
-    precondition((0...2).contains(casas), "toFixedJS: casas de 0 a 2")
+    precondition((0...4).contains(casas), "toFixedJS: casas de 0 a 4")
     if x.isNaN { return "NaN" }
     if abs(x) >= 1e21 { return numeroJS(x) }
     let negativo = x < 0
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```


- [ ] **Step 4: Ver passar**

Run: `node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4` e o núcleo.
Expected: `ℹ fail 0`; `✔ Test run with 138 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/app-ios.yml \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/Centavos.swift \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/NumeroJS.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CentavosTests.swift \
  scripts/vetores-calc.mjs \
  tests/vetores.test.mjs \
  tests/vetores/calc.json \
  tests/workflow.test.cjs
git commit -m "test: teclado de valor nos vetores" -m "O teclado de valor do site entra nos vetores (centavos pela direita, 00, apagar, teto e a conversão com toFixed de 4 casas), com a guarda de que toda exportação do teclado.js tem vetor. O app nativo copia a regra para o teclado dele, e mudar o teclado.js passa a rodar o workflow do app."
```

### Task 5: O que os formulários da obra e da venda gravam, no dados.js

"Criar obra", "Salvar" da obra e "Confirmar venda" viram funções puras do `dados.js`, com os textos do site: `conferirObra` (nome de 1 a 120; área maior que zero só ao criar), `obraNova` (em construção, `gastos: []`, estimativa e orçamento só quando maiores que zero), `obraEditada` (o resto da obra fica) e `conferirVenda` (valor maior que zero; data entre o início e hoje).

**Files:**
- Modify: `CLAUDE.md`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift`
- Modify: `app.js`
- Modify: `dados.js`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (criar): `tests/browser/obras.cjs`
- Test (alterar): `tests/browser/rodar.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `LIMITES` e `textoValido` (comprimento em UTF-16), `dataIgualOuDepois`.
- Produces: `OBRA_DADOS.conferirObra(campos, nova)`, `obraNova(campos, id, hoje)`, `obraEditada(obra, campos)`, `conferirVenda(valor, data, dataInicio, hoje)`; `campos = {nome (aparado), dataInicio, valorEstimadoVenda, areaM2, orcamento}`. Em Swift: `CamposDaObra`, `conferirObra(_:nova:) -> ErroDeFormulario?`, `obraNova(_:id:hoje:) -> [String: ValorJSON]`, `obraEditada(_:_:) -> [String: ValorJSON]`, `conferirVenda(valor:data:dataInicio:hoje:) -> ErroDeFormulario?`.

- [ ] **Step 1: Escrever os vetores, os leitores e o teste de browser**

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift
@@ -74,3 +74,39 @@ struct FormulariosTests {
         }
     }
 }
+
+extension CamposDaObra {
+    init(caso v: ValorJSON) {
+        let o = v.comoObjeto!
+        self.init(nome: o["nome"]!.comoTexto!, dataInicio: o["dataInicio"]!.comoTexto!, valorEstimadoVenda: o["valorEstimadoVenda"]!.numero,
+                  areaM2: o["areaM2"]!.numero, orcamento: o["orcamento"]?.comoNumero ?? 0)
+    }
+}
+
+struct FormulariosDaObraTests {
+    @Test func conferirObraNaOrdemDoFormulario() {
+        for c in Vetores.casos("dados.conferirObra") {
+            let r = conferirObra(CamposDaObra(caso: c.args[0]), nova: c.args[1] == .booleano(true))
+            confere(r?.json ?? .nulo, c.saida, .exata, c.caso)
+        }
+    }
+
+    @Test func obraNovaComoOSiteGrava() {
+        for c in Vetores.casos("dados.obraNova") {
+            confere(.objeto(obraNova(CamposDaObra(caso: c.args[0]), id: c.args[1].comoTexto!, hoje: c.args[2].comoTexto!)), c.saida, .exata, c.caso)
+        }
+    }
+
+    @Test func obraEditadaComoOSiteGrava() {
+        for c in Vetores.casos("dados.obraEditada") {
+            confere(.objeto(obraEditada(c.args[0].comoObjeto!, CamposDaObra(caso: c.args[1]))), c.saida, .exata, c.caso)
+        }
+    }
+
+    @Test func vendaEntreOInicioEHoje() {
+        for c in Vetores.casos("dados.conferirVenda") {
+            let r = conferirVenda(valor: c.args[0].numero, data: c.args[1].comoTexto!, dataInicio: c.args[2].comoTexto!, hoje: c.args[3].comoTexto!)
+            confere(r?.json ?? .nulo, c.saida, .exata, c.caso)
+        }
+    }
+}
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -533,6 +533,39 @@ editado('cartão continua cartão: as condições ficam', NO_CARTAO, { ...ENTRAD
 editado('parcela: muda só ela e o pagamento fica', PARCELA, { ...ENTRADA, valor: 1100, pagamento: 'cartao', data: '2026-09-30' });
 editado('data vazia fica a do gasto', EM_PIX, { ...ENTRADA, data: '' });
 
+/* O que os formulários da obra gravam: nova, editada e a venda. */
+const CAMPOS_OBRA = { nome: 'Casa Alphaville', dataInicio: '2025-08-12', valorEstimadoVenda: 1450000, areaM2: 300, orcamento: 0 };
+const conferirObra = (nome, campos, nova) => caso('dados.conferirObra', nome, [campos, nova], D.conferirObra);
+conferirObra('nova completa', CAMPOS_OBRA, true);
+conferirObra('nome vazio', { ...CAMPOS_OBRA, nome: '' }, true);
+conferirObra('nome com 120', { ...CAMPOS_OBRA, nome: 'x'.repeat(120) }, true);
+conferirObra('nome com 121', { ...CAMPOS_OBRA, nome: 'x'.repeat(121) }, true);
+conferirObra('nome em UTF-16', { ...CAMPOS_OBRA, nome: '🏠'.repeat(60) + 'x' }, true);
+conferirObra('nova sem área', { ...CAMPOS_OBRA, areaM2: 0 }, true);
+conferirObra('nova com área negativa', { ...CAMPOS_OBRA, areaM2: -3 }, true);
+conferirObra('edição sem área vale', { ...CAMPOS_OBRA, areaM2: 0 }, false);
+conferirObra('nome vence a área', { ...CAMPOS_OBRA, nome: '', areaM2: 0 }, true);
+const novaObra = (nome, campos) => caso('dados.obraNova', nome, [campos, 'novaid', HOJE], D.obraNova);
+novaObra('completa com orçamento', { ...CAMPOS_OBRA, orcamento: 1200000 });
+novaObra('sem estimativa nem orçamento', { ...CAMPOS_OBRA, valorEstimadoVenda: 0 });
+novaObra('estimativa negativa vira null', { ...CAMPOS_OBRA, valorEstimadoVenda: -1 });
+novaObra('início vazio vira hoje', { ...CAMPOS_OBRA, dataInicio: '' });
+const editada = (nome, obra, campos) => caso('dados.obraEditada', nome, [obra, campos], D.obraEditada);
+editada('nome, início, estimativa e área', O1, { ...CAMPOS_OBRA, areaM2: 3.125 });
+editada('início vazio fica o antigo', O1, { ...CAMPOS_OBRA, dataInicio: '' });
+editada('estimativa e área zeradas viram null', O1, { ...CAMPOS_OBRA, valorEstimadoVenda: 0, areaM2: 0 });
+editada('vendida: venda, gastos, orçamento e o resto ficam', { ...O2, campoSoDoSite: { a: 1 } }, CAMPOS_OBRA);
+const venda = (nome, valor, data, inicio = '2025-08-12') => caso('dados.conferirVenda', nome, [valor, data, inicio, HOJE], D.conferirVenda);
+venda('certa', 1500000, '2026-10-01');
+venda('no dia do início', 1500000, '2025-08-12');
+venda('hoje', 1500000, HOJE);
+venda('valor zero', 0, '2026-10-01');
+venda('valor negativo', -1, '2026-10-01');
+venda('antes do início', 1500000, '2025-08-11');
+venda('depois de hoje', 1500000, '2026-10-07');
+venda('data vazia', 1500000, '');
+venda('data inválida', 1500000, '2026-02-30');
+
 /* ---------- push.js e id ---------- */
 for(const t of ['', 'a', 'abc', 'fcm-token:APA91bHun4MxP5egoKMwt2KZFBaFUH-1RYqx', 'https://fcm.googleapis.com/fcm/send/eXyZ', 'ç😀', 'x'.repeat(300)])
   caso('push.hashEndpoint', JSON.stringify(t.length > 40 ? t.slice(0, 40) + '…' : t), [t], P.hashEndpoint);
```

Criar `tests/browser/obras.cjs`:

```js
/* Formulários da obra com dados sintéticos, sem serviços externos: a obra nova com o orçamento total e a venda fora
   do intervalo. */
const assert=require('node:assert/strict');
const {chromium}=require('playwright');
(async()=>{
  const browser=await chromium.launch();
  try{
    const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:393,height:852}});
    await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
    await ctx.route('https://**/*',r=>r.abort());
    await ctx.addInitScript(()=>{
      sessionStorage.setItem('splashVista','1');window.errosObras=[];
      addEventListener('error',e=>errosObras.push(e.message));
      addEventListener('securitypolicyviolation',e=>errosObras.push(e.violatedDirective));
      window.CLOUD={user:()=>({uid:'teste'}),onAuth:cb=>cb({uid:'teste'}),watchDados:()=>()=>{},saveDados:()=>Promise.resolve(),estado:()=> 'ocioso'};
    });
    const page=await ctx.newPage();
    await page.goto('http://localhost:8123');
    // a obra nova entra com o orçamento total
    await page.evaluate(()=>{ dadosCarregados=true; db=normaliza({obras:[]}); renderAll(); formNovaObra(); });
    await page.locator('#fNome').fill('Casa nova');
    await page.locator('#fArea').fill('3,125');
    await page.locator('#fOrc').fill('100.000,00');
    await page.locator('#cSave').click();
    const nova=await page.evaluate(()=>db.obras.at(-1));
    assert.equal(nova.nome,'Casa nova');assert.equal(nova.areaM2,3.125);assert.deepEqual(nova.orcamento,{modo:'total',total:100000});
    // venda antes do início não grava
    await page.evaluate(id=>formVenda(obraById(id)),nova.id);
    await page.locator('#fVal').fill('500.000,00');
    await page.locator('#fData').fill('2020-01-01');
    await page.locator('#cSave').click();
    assert.equal(await page.evaluate(id=>obraById(id).fase,nova.id),'construcao');
    await page.waitForTimeout(200);
    assert.deepEqual(await page.evaluate(()=>errosObras),[]);
    console.log('ok - obra nova com orçamento e venda fora do intervalo');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
```

Em `tests/browser/rodar.cjs`:

```diff
--- a/tests/browser/rodar.cjs
+++ b/tests/browser/rodar.cjs
@@ -25,6 +25,7 @@ const run=(file,args=[])=>new Promise((resolve,reject)=>{
     await run('tests/browser/vidro.cjs');
     await run('tests/browser/contraste.cjs',[os.tmpdir()]);
     await run('tests/browser/cartao.cjs');
+    await run('tests/browser/obras.cjs');
     await run('tests/browser/nativo.cjs');
     await run('tests/browser/sentry.cjs');
     await run('tests/browser/persistencia.cjs');
```


- [ ] **Step 2: Ver falhar**

Run: `node scripts/vetores-calc.mjs`
Expected: FAIL com `TypeError: D.conferirObra is not a function`.

- [ ] **Step 3: Implementar**

Em `CLAUDE.md`:

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -51,6 +51,7 @@ Scripts clássicos com globais, carregados na ordem em que aparecem no `index.ht
 | Arquivo | Global exposto | Papel |
 | --- | --- | --- |
 | [calc.js](calc.js) | `OBRA_CALC` + `module.exports` | regras de negócio puras, zero DOM — é o que os testes de unidade cobrem |
+| [dados.js](dados.js) | `OBRA_DADOS` + `module.exports` | normalização do blob na leitura e o que os formulários gravam (gasto, obra, venda, teto de obras), puro e nos vetores |
 | [cloud.js](cloud.js) | `window.CLOUD`, evento `cloud-pronto` | único ponto de contato com o Firebase |
 | [auth.js](auth.js) | — | overlay de login (`#auth` + `body.locked`) |
 | [nativo.js](nativo.js) | `OBRA_NATIVO` + `module.exports` | único ponto que toca `window.Capacitor`; no browser tudo é neutro |
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift
@@ -98,3 +98,58 @@ public func gastoEditado(_ gasto: Gasto, _ entrada: EntradaDoGasto, _ conferido:
     if entrada.pagamento != "cartao" { g.campos["jurosCartao"] = nil }
     return g
 }
+
+/// O que a pessoa respondeu no formulário da obra: nome aparado e os valores lidos como o `parseNum` (0 quando vazios).
+public struct CamposDaObra: Equatable, Sendable {
+    public var nome: String
+    /// AAAA-MM-DD; vazia vale hoje (obra nova) ou a antiga (edição).
+    public var dataInicio: String
+    public var valorEstimadoVenda: Double
+    public var areaM2: Double
+    /// Orçamento total (só na obra nova).
+    public var orcamento: Double
+
+    public init(nome: String, dataInicio: String, valorEstimadoVenda: Double = 0, areaM2: Double = 0, orcamento: Double = 0) {
+        self.nome = nome; self.dataInicio = dataInicio; self.valorEstimadoVenda = valorEstimadoVenda
+        self.areaM2 = areaM2; self.orcamento = orcamento
+    }
+}
+
+/// `conferirObra` do dados.js: nome (vazio, sem mensagem; mais de 120 unidades UTF-16) e, só na obra nova, a área.
+public func conferirObra(_ campos: CamposDaObra, nova: Bool) -> ErroDeFormulario? {
+    if campos.nome.isEmpty { return ErroDeFormulario(campo: "nome") }
+    if campos.nome.utf16.count > Limites.nome { return ErroDeFormulario(campo: "nome", mensagem: "Use até \(Limites.nome) caracteres.") }
+    if nova && !(campos.areaM2 > 0) { return ErroDeFormulario(campo: "area", mensagem: "Informe área construída maior que zero.") }
+    return nil
+}
+
+/// `obraNova` do dados.js, na forma que o site grava: em construção e sem gastos; valor estimado e orçamento total só quando
+/// maiores que zero. Sem `venda` e sem `afazeres`, que a leitura normalizada acrescenta.
+public func obraNova(_ campos: CamposDaObra, id: String, hoje: String) -> [String: ValorJSON] {
+    var o: [String: ValorJSON] = ["id": .texto(id), "nome": .texto(campos.nome), "fase": .texto("construcao"),
+                                  "dataInicio": .texto(campos.dataInicio.isEmpty ? hoje : campos.dataInicio),
+                                  "valorEstimadoVenda": campos.valorEstimadoVenda > 0 ? .numero(campos.valorEstimadoVenda) : .nulo,
+                                  "areaM2": .numero(campos.areaM2), "gastos": .lista([])]
+    if campos.orcamento > 0 { o["orcamento"] = .objeto(["modo": .texto("total"), "total": .numero(campos.orcamento)]) }
+    return o
+}
+
+/// `obraEditada` do dados.js: nome, início (vazio fica o antigo), valor estimado e área (zero ou vazio viram null); o resto
+/// da obra, inclusive o que o app não conhece, fica.
+public func obraEditada(_ obra: [String: ValorJSON], _ campos: CamposDaObra) -> [String: ValorJSON] {
+    var o = obra
+    o["nome"] = .texto(campos.nome)
+    if !campos.dataInicio.isEmpty { o["dataInicio"] = .texto(campos.dataInicio) }
+    o["valorEstimadoVenda"] = campos.valorEstimadoVenda > 0 ? .numero(campos.valorEstimadoVenda) : .nulo
+    o["areaM2"] = campos.areaM2 > 0 ? .numero(campos.areaM2) : .nulo
+    return o
+}
+
+/// `conferirVenda` do dados.js: valor maior que zero e data entre o início da obra e hoje.
+public func conferirVenda(valor: Double, data: String, dataInicio: String, hoje: String) -> ErroDeFormulario? {
+    if valor <= 0 { return ErroDeFormulario(campo: "valor") }
+    if !dataIgualOuDepois(data, dataInicio) || !dataIgualOuDepois(hoje, data) {
+        return ErroDeFormulario(campo: "data", mensagem: "Data da venda precisa ficar entre o início da obra e hoje")
+    }
+    return nil
+}
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -786,13 +786,10 @@ function formVenda(o){
   $('#cCancel').onclick = closeSheet;
   $('#cSave').onclick = ()=>{
     const valor = parseNum($('#fVal').value);
-    if(valor<=0){ $('#fVal').focus(); return; }
     const data = $('#fData').value;
-    if(!OBRA_CALC.dataIgualOuDepois(data, o.dataInicio) || !OBRA_CALC.dataIgualOuDepois(todayISO(), data)){
-      toast('Data da venda precisa ficar entre o início da obra e hoje');
-      $('#fData').focus();
-      return;
-    }
+    const erro = OBRA_DADOS.conferirVenda(valor, data, o.dataInicio, todayISO());
+    if(erro?.erro==='valor'){ $('#fVal').focus(); return; }
+    if(erro?.erro==='data'){ toast(erro.mensagem); $('#fData').focus(); return; }
     const oo = obraById(o.id); if(!oo) return;
     oo.venda = { valor, data };
     oo.fase = 'vendida';
@@ -815,16 +812,12 @@ function formEditarObra(o){
     </div>`);
   maskMoney('#fEst');
   $('#cSave').onclick = ()=>{
-    const nome = $('#fNome').value.trim();
-    if(!nome){ $('#fNome').focus(); return; }
-    if(!textoValido(nome, 'nome', $('#fNome'))) return;
-    const oo = obraById(o.id); if(!oo) return;
-    oo.nome = nome;
-    oo.dataInicio = $('#fData').value || oo.dataInicio;
-    const est = parseNum($('#fEst').value);
-    oo.valorEstimadoVenda = est>0 ? est : null;
-    const area = parseNum($('#fArea').value);
-    oo.areaM2 = area>0 ? area : null;
+    const campos = { nome:$('#fNome').value.trim(), dataInicio:$('#fData').value,
+      valorEstimadoVenda:parseNum($('#fEst').value), areaM2:parseNum($('#fArea').value) };
+    const erro = OBRA_DADOS.conferirObra(campos, false);
+    if(erro){ if(erro.mensagem) toast(erro.mensagem, "erro"); $('#fNome').focus(); return; }
+    const i = db.obras.findIndex(x=>x.id===o.id); if(i<0) return;
+    db.obras[i] = OBRA_DADOS.obraEditada(db.obras[i], campos);
     save(); closeSheet(); renderAll();
   };
   $('#cDel').onclick = async()=>{
@@ -1799,26 +1792,18 @@ function formNovaObra(){
   });
   $('#cCancel').onclick = closeSheet;
   $('#cSave').onclick = ()=>{
-    const nome = $('#fNome').value.trim();
-    if(!nome){ $('#fNome').focus(); return; }
-    if(!textoValido(nome, 'nome', $('#fNome'))) return;
-    const est = parseNum($('#fEst').value);
-    const area = parseNum($('#fArea').value);
-    if(!(area>0)){
+    const campos = { nome:$('#fNome').value.trim(), dataInicio:$('#fData').value, valorEstimadoVenda:parseNum($('#fEst').value),
+      areaM2:parseNum($('#fArea').value), orcamento:parseNum($('#fOrc').value) };
+    const erro = OBRA_DADOS.conferirObra(campos, true);
+    if(erro?.erro==='nome'){ if(erro.mensagem) toast(erro.mensagem, "erro"); $('#fNome').focus(); return; }
+    if(erro?.erro==='area'){
+      $('#fAreaErro').textContent = erro.mensagem;
       $('#fAreaErro').classList.remove('hidden');
       $('#fArea').setAttribute('aria-invalid','true');
       $('#fArea').focus();
       return;
     }
-    const o = {
-      id: uid(), nome, fase: 'construcao',
-      dataInicio: $('#fData').value || todayISO(),
-      valorEstimadoVenda: est > 0 ? est : null,
-      areaM2: area,
-      gastos: [],
-    };
-    const orcTotal = parseNum($('#fOrc').value);
-    if(orcTotal > 0) o.orcamento = { modo:'total', total:orcTotal };
+    const o = OBRA_DADOS.obraNova(campos, uid(), todayISO());
     db.obras.push(o); save(); closeSheet(); renderAll(); openObra(o.id);
   };
 }
```

Em `dados.js`:

```diff
--- a/dados.js
+++ b/dados.js
@@ -106,7 +106,38 @@
     if(entrada.pagamento!=='cartao') delete g.jurosCartao;
     return g;
   }
-  const api={normaliza,LIMITES,conferirGasto,gastosLancados,gastoEditado};
+  /* ---- o que os formulários da obra gravam (app.js formNovaObra, formEditarObra e formVenda) ---- */
+  /* "Criar obra" e "Salvar" da obra, na ordem do formulário. campos: {nome (aparado), dataInicio, valorEstimadoVenda,
+     areaM2, orcamento}, com os valores lidos pelo parseNum (0 quando vazios). Erro: {erro:'nome'} (vazio: a tela volta
+     ao nome), {erro:'nome', mensagem} ou, só na obra nova, {erro:'area', mensagem}; certo: null. */
+  function conferirObra(campos, nova){
+    if(!campos.nome) return {erro:'nome'};
+    if(campos.nome.length>LIMITES.nome) return {erro:'nome', mensagem:`Use até ${LIMITES.nome} caracteres.`};
+    if(nova && !(campos.areaM2>0)) return {erro:'area', mensagem:'Informe área construída maior que zero.'};
+    return null;
+  }
+  /* A obra nova: em construção e sem gastos; valor estimado e orçamento total só quando maiores que zero. */
+  function obraNova(campos, id, hoje){
+    const o={id, nome:campos.nome, fase:'construcao', dataInicio:campos.dataInicio||hoje,
+      valorEstimadoVenda:campos.valorEstimadoVenda>0?campos.valorEstimadoVenda:null, areaM2:campos.areaM2, gastos:[]};
+    if(campos.orcamento>0) o.orcamento={modo:'total', total:campos.orcamento};
+    return o;
+  }
+  /* A obra editada: nome, início (vazio fica o antigo), valor estimado e área (zero ou vazio viram null). O resto fica. */
+  function obraEditada(obra, campos){
+    return {...obra, nome:campos.nome, dataInicio:campos.dataInicio||obra.dataInicio,
+      valorEstimadoVenda:campos.valorEstimadoVenda>0?campos.valorEstimadoVenda:null, areaM2:campos.areaM2>0?campos.areaM2:null};
+  }
+  /* "Confirmar venda": valor maior que zero e data entre o início da obra e hoje. Erro: {erro:'valor'} (a tela volta ao
+     valor) ou {erro:'data', mensagem}; certo: null. */
+  function conferirVenda(valor, data, dataInicio, hoje){
+    if(valor<=0) return {erro:'valor'};
+    const C=calc();
+    if(!C.dataIgualOuDepois(data, dataInicio) || !C.dataIgualOuDepois(hoje, data))
+      return {erro:'data', mensagem:'Data da venda precisa ficar entre o início da obra e hoje'};
+    return null;
+  }
+  const api={normaliza,LIMITES,conferirGasto,gastosLancados,gastoEditado,conferirObra,obraNova,obraEditada,conferirVenda};
   if(typeof module !== 'undefined' && module.exports) module.exports=api;
   else root.OBRA_DADOS=api;
 })(typeof window !== 'undefined' ? window : globalThis);
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```


- [ ] **Step 4: Ver passar**

Run: `node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4`, o núcleo e `node tests/browser/obras.cjs` (com o servidor de testes).
Expected: `ℹ fail 0`; `✔ Test run with 142 tests … passed`; `ok - obra nova com orçamento e venda fora do intervalo`.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift \
  app.js \
  dados.js \
  scripts/vetores-calc.mjs \
  tests/browser/obras.cjs \
  tests/browser/rodar.cjs \
  tests/vetores/calc.json
git commit -m "feat: o que os formulários da obra e da venda gravam, no dados.js" -m "Criar obra, salvar a obra e confirmar a venda passam a ser funções puras do dados.js, com as mensagens do site, usadas pelo app.js e conferidas pelos vetores. O app nativo copia as quatro regras para gravar a obra como o site grava."
```

### Task 6: Área com casas decimais não se multiplica ao editar a obra

Defeito do site (inventário, seção 12, item 5): o campo de área da edição mostrava o número cru ("3.125"), e o `parseNum` lia o ponto como separador de milhar e gravava 3125. O campo passa a vir com vírgula.

**Files:**
- Modify: `app.js`
- Test (alterar): `tests/browser/obras.cjs`

- [ ] **Step 1: Estender o teste de browser**

Em `tests/browser/obras.cjs`:

```diff
--- a/tests/browser/obras.cjs
+++ b/tests/browser/obras.cjs
@@ -1,5 +1,5 @@
-/* Formulários da obra com dados sintéticos, sem serviços externos: a obra nova com o orçamento total e a venda fora
-   do intervalo. */
+/* Formulários da obra com dados sintéticos, sem serviços externos: a obra nova com o orçamento total, a área com casas
+   decimais na edição e a venda fora do intervalo. */
 const assert=require('node:assert/strict');
 const {chromium}=require('playwright');
 (async()=>{
@@ -24,6 +24,11 @@ const {chromium}=require('playwright');
     await page.locator('#cSave').click();
     const nova=await page.evaluate(()=>db.obras.at(-1));
     assert.equal(nova.nome,'Casa nova');assert.equal(nova.areaM2,3.125);assert.deepEqual(nova.orcamento,{modo:'total',total:100000});
+    // editar sem mexer na área com três casas não a multiplica por mil (o parseNum lia "3.125" como 3125)
+    await page.evaluate(id=>formEditarObra(obraById(id)),nova.id);
+    assert.equal(await page.locator('#fArea').inputValue(),'3,125');
+    await page.locator('#cSave').click();
+    assert.equal(await page.evaluate(id=>obraById(id).areaM2,nova.id),3.125);
     // venda antes do início não grava
     await page.evaluate(id=>formVenda(obraById(id)),nova.id);
     await page.locator('#fVal').fill('500.000,00');
@@ -32,6 +37,6 @@ const {chromium}=require('playwright');
     assert.equal(await page.evaluate(id=>obraById(id).fase,nova.id),'construcao');
     await page.waitForTimeout(200);
     assert.deepEqual(await page.evaluate(()=>errosObras),[]);
-    console.log('ok - obra nova com orçamento e venda fora do intervalo');
+    console.log('ok - obra nova com orçamento, área com três casas na edição e venda fora do intervalo');
   }finally{await browser.close();}
 })().catch(e=>{console.error(e);process.exitCode=1;});
```


- [ ] **Step 2: Ver falhar**

Run: `node tests/browser/obras.cjs`
Expected: FAIL com `actual: '3.125'`, `expected: '3,125'`.

- [ ] **Step 3: Corrigir**

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -805,7 +805,7 @@ function formEditarObra(o){
     <div class="field"><label>Valor estimado de venda (opcional)</label>
       <div class="money"><b>R$</b><input id="fEst" inputmode="decimal" placeholder="0,00" value="${o.valorEstimadoVenda?OBRA_CALC.numParaCampo(o.valorEstimadoVenda):''}" autocomplete="off"></div></div>
     <div class="field"><label>Área construída em m² (opcional)</label>
-      <input id="fArea" inputmode="decimal" placeholder="Ex: 320" value="${escapeHtml(o.areaM2||'')}" autocomplete="off"></div>
+      <input id="fArea" inputmode="decimal" placeholder="Ex: 320" value="${escapeHtml(String(o.areaM2||'').replace('.',','))}" autocomplete="off"></div>
     <div class="sheet-actions">
       <button class="layout-42 btn ghost" id="cDel">Apagar obra</button>
       <button class="btn primary" id="cSave">Salvar</button>
```


- [ ] **Step 4: Ver passar**

Run: `node tests/browser/obras.cjs`
Expected: `ok - obra nova com orçamento, área com três casas na edição e venda fora do intervalo`.

- [ ] **Step 5: Commit**

```bash
git add app.js \
  tests/browser/obras.cjs
git commit -m "fix: área com casas decimais não se multiplica ao editar a obra" -m "O campo de área da edição mostrava o número com ponto, e salvar sem mexer lia o ponto como milhar: 3,125 m² virava 3125. O campo passa a vir com vírgula, como o usuário digitou."
```

### Task 7: Aviso do limite de 300 obras

As `firestore.rules` aceitam até 300 obras, e o site não avisava: a 301ª entrava no `db`, a gravação era recusada e toda gravação seguinte falhava até apagar uma obra. Agora o começo do `formNovaObra` (as quatro entradas) avisa com o texto decidido ("Limite de 300 obras" / "Apague uma obra antiga para criar outra.") e não abre a folha. O teto mora no `dados.js`, com um teste que o compara com o das rules.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift`
- Modify: `app.js`
- Modify: `dados.js`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/obras.cjs`
- Test (alterar): `tests/dados.test.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `OBRA_CONFIRM.avisar` (`ui-confirm.js`).
- Produces: `OBRA_DADOS.LIMITE_OBRAS` (300) e `avisoLimiteDeObras(quantidade)` → `{titulo, texto}` ou `null`; em Swift, `limiteDeObras`, `AvisoDeLimite` e `avisoLimiteDeObras(_:)`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift
@@ -84,6 +84,14 @@ extension CamposDaObra {
 }
 
 struct FormulariosDaObraTests {
+    @Test func tetoDeObrasDasRules() {
+        #expect(Vetores.casos("dados.LIMITE_OBRAS").first?.saida == .numero(Double(limiteDeObras)))
+        for c in Vetores.casos("dados.avisoLimiteDeObras") {
+            let r = avisoLimiteDeObras(Int(c.args[0].numero))
+            confere(r.map { .objeto(["titulo": .texto($0.titulo), "texto": .texto($0.texto)]) } ?? .nulo, c.saida, .exata, c.caso)
+        }
+    }
+
     @Test func conferirObraNaOrdemDoFormulario() {
         for c in Vetores.casos("dados.conferirObra") {
             let r = conferirObra(CamposDaObra(caso: c.args[0]), nova: c.args[1] == .booleano(true))
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -533,7 +533,9 @@ editado('cartão continua cartão: as condições ficam', NO_CARTAO, { ...ENTRAD
 editado('parcela: muda só ela e o pagamento fica', PARCELA, { ...ENTRADA, valor: 1100, pagamento: 'cartao', data: '2026-09-30' });
 editado('data vazia fica a do gasto', EM_PIX, { ...ENTRADA, data: '' });
 
-/* O que os formulários da obra gravam: nova, editada e a venda. */
+/* O que os formulários da obra gravam: nova, editada, a venda e o teto de obras das rules. */
+constante('dados.LIMITE_OBRAS', D.LIMITE_OBRAS);
+for(const n of [0, 1, 299, 300, 301]) caso('dados.avisoLimiteDeObras', String(n), [n], D.avisoLimiteDeObras);
 const CAMPOS_OBRA = { nome: 'Casa Alphaville', dataInicio: '2025-08-12', valorEstimadoVenda: 1450000, areaM2: 300, orcamento: 0 };
 const conferirObra = (nome, campos, nova) => caso('dados.conferirObra', nome, [campos, nova], D.conferirObra);
 conferirObra('nova completa', CAMPOS_OBRA, true);
```

Em `tests/browser/obras.cjs`:

```diff
--- a/tests/browser/obras.cjs
+++ b/tests/browser/obras.cjs
@@ -1,4 +1,4 @@
-/* Formulários da obra com dados sintéticos, sem serviços externos: a obra nova com o orçamento total, a área com casas
+/* Formulários da obra com dados sintéticos, sem serviços externos: o teto de obras das rules, a área com casas
    decimais na edição e a venda fora do intervalo. */
 const assert=require('node:assert/strict');
 const {chromium}=require('playwright');
@@ -16,8 +16,18 @@ const {chromium}=require('playwright');
     });
     const page=await ctx.newPage();
     await page.goto('http://localhost:8123');
-    // a obra nova entra com o orçamento total
-    await page.evaluate(()=>{ dadosCarregados=true; db=normaliza({obras:[]}); renderAll(); formNovaObra(); });
+    // 300 obras: "Nova obra" avisa e não abre a folha (a 301ª as rules recusam, e toda gravação seguinte falharia)
+    await page.evaluate(()=>{
+      dadosCarregados=true;
+      db=normaliza({obras:Array.from({length:300},(_,i)=>({id:`o${i}`,nome:`Obra ${i}`,dataInicio:'2026-01-01',gastos:[]}))});
+      renderAll();formNovaObra();
+    });
+    await page.locator('dialog.confirma-dialog').waitFor();
+    assert.equal(await page.locator('dialog.confirma-dialog .confirma-msg').textContent(),'Limite de 300 obras. Apague uma obra antiga para criar outra.');
+    assert.equal(await page.locator('#fNome').count(),0,'a folha de nova obra não abre');
+    await page.locator('dialog.confirma-dialog button').click();
+    // com 299, abre; a obra nova entra com o orçamento total
+    await page.evaluate(()=>{ db.obras.pop(); formNovaObra(); });
     await page.locator('#fNome').fill('Casa nova');
     await page.locator('#fArea').fill('3,125');
     await page.locator('#fOrc').fill('100.000,00');
@@ -37,6 +47,6 @@ const {chromium}=require('playwright');
     assert.equal(await page.evaluate(id=>obraById(id).fase,nova.id),'construcao');
     await page.waitForTimeout(200);
     assert.deepEqual(await page.evaluate(()=>errosObras),[]);
-    console.log('ok - obra nova com orçamento, área com três casas na edição e venda fora do intervalo');
+    console.log('ok - teto de obras, área com três casas na edição e venda fora do intervalo');
   }finally{await browser.close();}
 })().catch(e=>{console.error(e);process.exitCode=1;});
```

Em `tests/dados.test.cjs`:

```diff
--- a/tests/dados.test.cjs
+++ b/tests/dados.test.cjs
@@ -50,3 +50,11 @@ test('orçamento por tópico: só ids de texto até 80 e valores positivos, no m
   const d = normaliza({ obras:[obraBase({ orcamento:{ modo:'topicos', topicos } })] });
   assert.deepEqual(normaliza(d), d);
 });
+
+test('o teto de obras é o mesmo das firestore.rules', () => {
+  const D = require('../dados.js');
+  const rules = require('node:fs').readFileSync(require('node:path').join(__dirname, '..', 'firestore.rules'), 'utf8');
+  assert.match(rules, new RegExp(`d\\.obras\\.size\\(\\) <= ${D.LIMITE_OBRAS}\\b`));
+  assert.equal(D.avisoLimiteDeObras(D.LIMITE_OBRAS - 1), null);
+  assert.deepEqual(D.avisoLimiteDeObras(D.LIMITE_OBRAS), { titulo: 'Limite de 300 obras', texto: 'Apague uma obra antiga para criar outra.' });
+});
```


- [ ] **Step 2: Ver falhar**

Run: `node --test tests/dados.test.cjs` e `node tests/browser/obras.cjs`
Expected: FAIL no teto (`D.LIMITE_OBRAS` é `undefined`) e `TimeoutError` esperando o aviso no browser.

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift
@@ -99,6 +99,21 @@ public func gastoEditado(_ gasto: Gasto, _ entrada: EntradaDoGasto, _ conferido:
     return g
 }
 
+/// `LIMITE_OBRAS` do dados.js: o teto de obras por conta das firestore.rules.
+public let limiteDeObras = 300
+
+/// O aviso de "Nova obra" com o teto cheio.
+public struct AvisoDeLimite: Equatable, Sendable {
+    public let titulo: String
+    public let texto: String
+}
+
+/// `avisoLimiteDeObras` do dados.js: com o teto cheio, "Nova obra" avisa em vez de abrir (a obra a mais faria toda
+/// gravação seguinte ser recusada pelas rules até apagar uma).
+public func avisoLimiteDeObras(_ quantidade: Int) -> AvisoDeLimite? {
+    quantidade >= limiteDeObras ? AvisoDeLimite(titulo: "Limite de \(limiteDeObras) obras", texto: "Apague uma obra antiga para criar outra.") : nil
+}
+
 /// O que a pessoa respondeu no formulário da obra: nome aparado e os valores lidos como o `parseNum` (0 quando vazios).
 public struct CamposDaObra: Equatable, Sendable {
     public var nome: String
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -1768,6 +1768,9 @@ function formOrcamento(obraId){
 
 function formNovaObra(){
   if(!dadosCarregados){ avisaNaoCarregado(); return; }
+  // todas as entradas passam por aqui (+, "+ Nova obra" e o + sem obra aberta): a 301ª obra as rules recusam
+  const limite = OBRA_DADOS.avisoLimiteDeObras(db.obras.length);
+  if(limite){ OBRA_CONFIRM.avisar(`${limite.titulo}. ${limite.texto}`); return; }
   openSheet(`
     <h3>Nova obra</h3>
     <div class="field"><label>Nome da obra</label><input id="fNome" maxlength="120" placeholder="Ex: Casa Alphaville" autocomplete="off"></div>
```

Em `dados.js`:

```diff
--- a/dados.js
+++ b/dados.js
@@ -107,6 +107,12 @@
     return g;
   }
   /* ---- o que os formulários da obra gravam (app.js formNovaObra, formEditarObra e formVenda) ---- */
+  /* Teto de obras por conta, o mesmo das firestore.rules (d.obras.size() <= 300). Com ele cheio, "Nova obra" avisa em
+     vez de abrir: a obra a mais faria toda gravação seguinte ser recusada até apagar uma. */
+  const LIMITE_OBRAS = 300;
+  function avisoLimiteDeObras(quantidade){
+    return quantidade>=LIMITE_OBRAS ? {titulo:`Limite de ${LIMITE_OBRAS} obras`, texto:'Apague uma obra antiga para criar outra.'} : null;
+  }
   /* "Criar obra" e "Salvar" da obra, na ordem do formulário. campos: {nome (aparado), dataInicio, valorEstimadoVenda,
      areaM2, orcamento}, com os valores lidos pelo parseNum (0 quando vazios). Erro: {erro:'nome'} (vazio: a tela volta
      ao nome), {erro:'nome', mensagem} ou, só na obra nova, {erro:'area', mensagem}; certo: null. */
@@ -137,7 +143,7 @@
       return {erro:'data', mensagem:'Data da venda precisa ficar entre o início da obra e hoje'};
     return null;
   }
-  const api={normaliza,LIMITES,conferirGasto,gastosLancados,gastoEditado,conferirObra,obraNova,obraEditada,conferirVenda};
+  const api={normaliza,LIMITES,conferirGasto,gastosLancados,gastoEditado,LIMITE_OBRAS,avisoLimiteDeObras,conferirObra,obraNova,obraEditada,conferirVenda};
   if(typeof module !== 'undefined' && module.exports) module.exports=api;
   else root.OBRA_DADOS=api;
 })(typeof window !== 'undefined' ? window : globalThis);
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/vetores-calc.mjs
```


- [ ] **Step 4: Ver passar**

Run: `node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | tail -4`, o núcleo e `node tests/browser/obras.cjs`.
Expected: `ℹ fail 0`; `✔ Test run with 143 tests … passed`; `ok - teto de obras, área com três casas na edição e venda fora do intervalo`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift \
  app.js \
  dados.js \
  scripts/vetores-calc.mjs \
  tests/browser/obras.cjs \
  tests/dados.test.cjs \
  tests/vetores/calc.json
git commit -m "feat: aviso do limite de 300 obras antes de abrir \"Nova obra\"" -m "As rules aceitam até 300 obras, e a 301ª entrava no aparelho, era recusada pela nuvem e travava toda gravação seguinte. Agora toda entrada de Nova obra avisa antes de abrir a folha, com o teto no dados.js conferido contra o das rules e nos vetores para o app nativo."
```

### Task 8: Nova versão do cache offline

**Files:**
- Modify: `sw.js`

- [ ] **Step 1: Subir o `CACHE`**

Em `sw.js`:

```diff
--- a/sw.js
+++ b/sw.js
@@ -1,6 +1,6 @@
 /* Service worker — network-first. Online sempre pega a versão nova; o cache
    é só o retrato pra funcionar offline. Bump CACHE ao mudar arquivos. */
-const CACHE = 'obras-v67';
+const CACHE = 'obras-v68';
 const ASSETS = ['./vendor/sentry/sentry.js', './sentry-config.js', './sentry.js', './vendor/firebase/firebase-app.js', './vendor/firebase/firebase-auth.js', './vendor/firebase/firebase-firestore.js', './vendor/firebase/shared-VONABDH2.js', './styles.css', './privacidade.css', './dados.js', './cadastro.js', './', './index.html', './app.js', './gestos.js', './push.js', './share.js', './ui-confirm.js', './privacidade.html', './auth.js', './globe.js', './calc.js', './cloud.js', './icons.js', './splash.js', './splash-pre.js', './teclado.js', './tema.js', './nativo.js', './pwa.js', './manifest.json', './apple-touch-icon.png', './icon-192.png', './icon-512.png', './favicon.svg', './google-g.svg', './fontes/hanken-grotesk-800.woff2'];
 
 self.addEventListener('install', e => {
```


- [ ] **Step 2: Commit**

```bash
git add sw.js
git commit -m "chore: nova versão do cache offline para as regras do gasto e da obra" -m "O app.js, o calc.js e o dados.js mudaram: aparelhos com o site instalado baixam a versão nova em vez de continuar com a guardada."
```

**Ponto de controle do PR 0:** na prévia da Vercel, lançar no cartão em 3x com juros, editar uma parcela, apagar uma parcela pela folha, ver as sugestões ao digitar uma descrição já usada, criar uma obra com orçamento, editar uma obra com área 3,125 sem mexer na área, tentar registrar uma venda antes do início da obra e, numa conta com 300 obras (o teste de browser monta uma), ver o aviso. O Forja começa o PR 1 quando este PR entra em revisão.

---

## PR 1 (app): a tela da obra, a guarda de gravação e a conta de teste

A parte 1 do mockup inteira, só leitura; as duas pendências obrigatórias da guarda de gravação (plano da etapa 1); o job próprio do laudo na CI; e o script da conta de teste. Nada grava ainda.

### Task 9: Laudo de leitura e auditorias num job próprio

O job `app` estava em 42–53 min com teto de 75, e as cenas novas da obra e da folha o fariam passar. O laudo e as auditorias vão para um job `laudo` próprio, que compila e roda só as duas classes, em paralelo ao `app` (que passa a pulá-las), com a varredura curta da lista sob a cápsula.

**Files:**
- Modify: `.github/workflows/app-ios.yml`
- Test (alterar): `tests/workflow.test.cjs`

- [ ] **Step 1: Escrever a guarda do workflow**

Em `tests/workflow.test.cjs`:

```diff
--- a/tests/workflow.test.cjs
+++ b/tests/workflow.test.cjs
@@ -228,10 +228,15 @@ assert.ok(!/^on:\n(?:.*\n)*?\s{2}push:/m.test(appIos), 'o app nativo não roda e
 assert.match(appIos, /workflow_dispatch:/, 'o app nativo precisa do botão manual');
 assert.match(appIos, /resolver_de_novo:/, 'sem o botão de resolver os pacotes Swift do app nativo de novo');
 assert.match(appIosSemComentario, /- name: Resolver os pacotes Swift de novo\n\s+if: inputs\.resolver_de_novo\n/, 'o passo de resolver de novo só roda no botão (if: inputs.resolver_de_novo)');
-assert.equal((appIosSemComentario.match(/CODE_SIGNING_ALLOWED=NO/g) || []).length, 2, 'build e testes sem assinatura');
+assert.equal((appIosSemComentario.match(/CODE_SIGNING_ALLOWED=NO/g) || []).length, 3, 'build, testes e laudo sem assinatura');
 assert.match(appIosSemComentario, /-project app-ios\/Custta\.xcodeproj[\s\S]*-configuration Release[\s\S]*CODE_SIGNING_ALLOWED=NO/, 'o app compila em Release sem assinatura');
 assert.match(appIosSemComentario, /xcodebuild test[\s\S]*-destination "\$DESTINO"/, 'os testes rodam no simulador escolhido pelo script');
-assert.equal((appIosSemComentario.match(/-onlyUsePackageVersionsFromResolvedFile/g) || []).length, 2, 'build e testes com os pacotes travados');
+assert.equal((appIosSemComentario.match(/-onlyUsePackageVersionsFromResolvedFile/g) || []).length, 3, 'build, testes e laudo com os pacotes travados');
+// O laudo de leitura e as auditorias moram no job laudo, em paralelo: o app pula os dois e o laudo roda só os dois.
+assert.match(appIosSemComentario, /-skip-testing:CusttaUITests\/LeituraNoVidroUITests[\s\S]*-skip-testing:CusttaUITests\/AuditoriaUITests/,
+  'o job app pula o laudo e as auditorias');
+assert.match(appIosSemComentario, /\n  laudo:\n[\s\S]*-only-testing:CusttaUITests\/LeituraNoVidroUITests[\s\S]*-only-testing:CusttaUITests\/AuditoriaUITests/,
+  'o job laudo roda o laudo e as auditorias');
 const appIosTf = readFileSync(join(dir, 'app-ios-testflight.yml'), 'utf8');
 const appIosTfSemComentario = appIosTf.split('\n').filter(l => !/^\s*#/.test(l)).join('\n');
 assert.match(appIosTf, /runs-on:\s*macos-26/);
```


- [ ] **Step 2: Ver falhar**

Run: `node tests/workflow.test.cjs`
Expected: FAIL nas contagens (o `CODE_SIGNING_ALLOWED=NO` e o `-onlyUsePackageVersionsFromResolvedFile` aparecem 2 vezes; a guarda pede 3) e no `-skip-testing` do laudo no job `app`.

- [ ] **Step 3: Separar o job**

Em `.github/workflows/app-ios.yml`:

```diff
--- a/.github/workflows/app-ios.yml
+++ b/.github/workflows/app-ios.yml
@@ -4,7 +4,9 @@ name: app-ios
 #   vetores gerados do site (tests/vetores/calc.json); por isso também dispara quando calc.js,
 #   dados.js, push.js, cadastro.js ou o gerador mudam;
 # - app: compila o app em Release sem assinatura (o caminho do TestFlight) e roda os testes de
-#   unidade e de tela no simulador com os serviços falsos.
+#   unidade e de tela no simulador com os serviços falsos;
+# - laudo: o laudo de leitura sobre o vidro e as auditorias de acessibilidade, num simulador próprio,
+#   em paralelo com o app (os dois juntos passavam dos 65 min com as telas da etapa 2).
 # Os testes contra os emuladores do Firebase e a conferência cruzada com o site rodam no Mac
 # (npm run test:app-ios:emuladores e npm run test:app-ios:cruzado): precisam de Java, dos
 # emuladores e da assinatura de simulador para o keychain do Firebase Auth.
@@ -63,7 +65,7 @@ jobs:
 
   app:
     runs-on: macos-26
-    # O laudo de leitura leva ~29 s por cena aqui, e a varredura das abas o leva a 43 cenas: o job passa dos 40 min (53 min na pior rodada de 12/10).
+    # Sem o laudo e as auditorias (job laudo), o job fica perto de 30 min; o teto é o de 12/10, com folga para a VM lenta.
     timeout-minutes: 75
     steps:
       - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
@@ -108,14 +110,9 @@ jobs:
             CODE_SIGN_IDENTITY= \
             build
 
-      # Testes com os serviços falsos (nada de rede): unidade e tela, inclusive as auditorias de
-      # acessibilidade. Os que dependem dos emuladores pulam sozinhos aqui. O laudo de leitura sobre o
-      # vidro (LeituraNoVidroUITests) é portão aqui também: o simulador da máquina virtual desenha o
-      # vidro diferente do Mac, mas igual de uma rodada para outra. A lista sob a cápsula de abas é
-      # medida só em 0, 20, 40 e 260 pt (a varredura completa fica no Mac), para o job caber em 45 min.
+      # Testes com os serviços falsos (nada de rede): unidade e tela. Os que dependem dos emuladores pulam
+      # sozinhos aqui; o laudo de leitura e as auditorias de acessibilidade rodam no job laudo.
       - name: Testes de unidade e de tela no simulador
-        env:
-          TEST_RUNNER_CUSTTA_VARREDURA: curta
         run: |
           set -o pipefail
           DESTINO="$(node scripts/simulador-ios.mjs)"
@@ -129,6 +126,8 @@ jobs:
             -skipPackagePluginValidation \
             -onlyUsePackageVersionsFromResolvedFile \
             -resultBundlePath "$RUNNER_TEMP/testes.xcresult" \
+            -skip-testing:CusttaUITests/LeituraNoVidroUITests \
+            -skip-testing:CusttaUITests/AuditoriaUITests \
             CODE_SIGNING_ALLOWED=NO
 
       # Laudo ou tela reprovados: os prints anotados ficam 7 dias no artefato (o log só traz as notas).
@@ -139,3 +138,48 @@ jobs:
           name: testes-app-ios
           path: ${{ runner.temp }}/testes.xcresult
           retention-days: 7
+
+  laudo:
+    runs-on: macos-26
+    # ~29 s por cena do laudo; com as telas da etapa 2 (obra, folhas, quatro combos e letra máxima), o laudo e as
+    # auditorias passam de 30 min sozinhos.
+    timeout-minutes: 75
+    steps:
+      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
+      - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
+        with:
+          node-version: 22
+
+      - name: Versão do Xcode
+        run: xcodebuild -version
+
+      # O laudo de leitura sobre o vidro (LeituraNoVidroUITests) é portão aqui também: o simulador da máquina virtual
+      # desenha o vidro diferente do Mac, mas igual de uma rodada para outra. A lista sob a cápsula de abas é medida só
+      # em 0, 20, 40 e 260 pt (a varredura completa fica no Mac).
+      - name: Laudo de leitura e auditorias de acessibilidade no simulador
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
+            -resultBundlePath "$RUNNER_TEMP/laudo.xcresult" \
+            -only-testing:CusttaUITests/LeituraNoVidroUITests \
+            -only-testing:CusttaUITests/AuditoriaUITests \
+            CODE_SIGNING_ALLOWED=NO
+
+      - name: Resultado do laudo quando reprova
+        if: failure()
+        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
+        with:
+          name: laudo-app-ios
+          path: ${{ runner.temp }}/laudo.xcresult
+          retention-days: 7
```


- [ ] **Step 4: Ver passar**

Run: `node tests/workflow.test.cjs`
Expected: sai sem erro. Na CI do PR, o job `laudo` roda em paralelo ao `app`, e o `app` cai para perto dos 30 min.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/app-ios.yml \
  tests/workflow.test.cjs
git commit -m "ci: laudo de leitura e auditorias num job próprio" -m "O job do app nativo estava perto do teto de 75 minutos, e a etapa 2 soma as cenas da obra e da folha ao laudo de leitura. O laudo e as auditorias passam para um job próprio, em paralelo, com a varredura curta da CI; o job do app fica com a unidade e os testes de tela."
```

### Task 10: A dose do vidro e o âmbar das etiquetas pelo laudo de leitura

O protótipo da tela da obra, medido pelo laudo com as doses de 09/10 (45% no Transparente, 20% no Fosco), reprovou duas vezes: o cabeçalho do mês em 4,44:1 na lista escura e, com Aumentar contraste, a linha de baixo do gasto em 4,21:1, porque o `SecundarioFosco` é 24% mais fraco que o `SecundarioTransparente` sobre o mesmo fundo. Decisão do conselho de 13/10 (segunda rodada): o Transparente sobe para 50% (o mesmo degrau da escada de 09/10 e o mesmo passo de 10/10), o Fosco fica em 20%, o cabeçalho do mês continua secundário como no mockup, e com Aumentar contraste o secundário passa a ser o `SecundarioTransparente` em toda dose menos a sólida. Dois achados do laudo do PR 3 entram aqui porque são tokens de todo o app: 30% de escurecimento sob a cápsula de abas e o + no escuro (com o + na lista de obras a cápsula encolhe e "Ajustes" passava sobre o texto branco do comparativo a 2,75:1, com o véu da borda sozinho) e o token `AlertaEtiqueta` para o texto âmbar das etiquetas no claro (o `Alerta` é o `--warn` do site e ficava em 4,42:1 na faixa do véu do topo). As medidas estão em "Conselho de 13/10 (segunda rodada)".

**Files:**
- Modify: `app-ios/Custta/Identidade/Componentes.swift`
- Modify: `app-ios/Custta/Identidade/Paleta.swift`
- Modify: `app-ios/Custta/Identidade/Vidro.swift`
- Test (alterar): `app-ios/CusttaTests/CoresTests.swift`
- Modify: `scripts/cores-app-ios.mjs`
- Gerado: cores em `app-ios/Custta/Assets.xcassets/{Esmeralda,Azul}/` (`node scripts/cores-app-ios.mjs`)

**Interfaces:**
- Consumes: `VidroTokens`, `Paleta` e as etiquetas da fase (etapa 1).
- Produces: `VidroTokens.escurecimento(_:escuro:)` com 50% no Transparente, 20% no Fosco e 30% na navegação; `VidroTokens.secundario` olhando o Aumentar contraste; o token `AlertaEtiqueta` (`Paleta.alertaEtiqueta`) no texto das etiquetas âmbar.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaTests/CoresTests.swift`:

```diff
--- a/app-ios/CusttaTests/CoresTests.swift
+++ b/app-ios/CusttaTests/CoresTests.swift
@@ -66,11 +66,12 @@ struct VidroTokensTests {
     @Test func escurecimentoSobOVidroSoNoEscuro() {
         let transparente = VidroTokens(nivel: .transparente, contorno: false), fosco = VidroTokens(nivel: .fosco, contorno: true)
         for papel in [PapelDoVidro.conteudo, .cartaoEntrada, .segmentado] {
-            #expect(transparente.escurecimento(papel, escuro: true) == 0.45)
+            #expect(transparente.escurecimento(papel, escuro: true) == 0.5)
             #expect(fosco.escurecimento(papel, escuro: true) == 0.2)
             #expect(transparente.escurecimento(papel, escuro: false) == 0 && fosco.escurecimento(papel, escuro: false) == 0)
         }
-        #expect(transparente.escurecimento(.navegacao, escuro: true) == 0, "a navegação tem o véu da borda")
+        #expect(transparente.escurecimento(.navegacao, escuro: true) == 0.3 && fosco.escurecimento(.navegacao, escuro: true) == 0.3,
+                "sob a cápsula com o + na lista, 30% (o véu da borda sozinho deixava o rótulo em 2,75:1)")
         #expect(VidroTokens(nivel: .solido, contorno: false).escurecimento(.conteudo, escuro: true) == 0)
     }
 
@@ -90,6 +91,8 @@ struct VidroTokensTests {
         #expect(VidroTokens(nivel: .transparente, contorno: false).secundario == .secundarioTransparente)
         #expect(VidroTokens(nivel: .fosco, contorno: false).secundario == .secundarioFosco)
         #expect(VidroTokens(nivel: .solido, contorno: false).secundario == .secundarioSolido)
+        #expect(VidroTokens(nivel: .fosco, contorno: true).secundario == .secundarioTransparente,
+                "com Aumentar contraste, o secundário mais forte: ligar a opção não pode baixar a leitura")
         #expect(VidroTokens(nivel: .transparente, contorno: false).link == .texto, "link solto na cor do texto")
         #expect(VidroTokens(nivel: .fosco, contorno: false).link == .linkNoVidro)
     }
```


- [ ] **Step 2: Ver falhar**

Run: `xcodebuild build-for-testing "${XB[@]}"` e `xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/VidroTokensTests`
Expected: FAIL: `escurecimentoSobOVidroSoNoEscuro` (0,45 em vez de 0,5; 0 em vez de 0,3 na navegação) e `secundario` com contorno devolvendo `.secundarioFosco`.

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Identidade/Componentes.swift`:

```diff
--- a/app-ios/Custta/Identidade/Componentes.swift
+++ b/app-ios/Custta/Identidade/Componentes.swift
@@ -261,7 +261,7 @@ struct EtiquetaDeFase: View {
 
     var body: some View {
         let (texto, fundo): (Token, Token) = switch fase {
-        case .construcao: (.alerta, .alertaFundo)
+        case .construcao: (.alertaEtiqueta, .alertaFundo)
         case .pronta: (.informacao, .informacaoFundo)
         case .vendida: (.positivo, .positivoFundo)
         }
```

Em `app-ios/Custta/Identidade/Paleta.swift`:

```diff
--- a/app-ios/Custta/Identidade/Paleta.swift
+++ b/app-ios/Custta/Identidade/Paleta.swift
@@ -22,6 +22,8 @@ enum Token: String, CaseIterable, Sendable {
     case positivoFundo = "PositivoFundo"
     case alerta = "Alerta"
     case alertaFundo = "AlertaFundo"
+    /// O texto âmbar sobre a AlertaFundo (etiquetas): no claro, mais escuro que o Alerta do site.
+    case alertaEtiqueta = "AlertaEtiqueta"
     case informacao = "Informacao"
     case informacaoFundo = "InformacaoFundo"
     case negativo = "Negativo"
```

Em `app-ios/Custta/Identidade/Vidro.swift`:

```diff
--- a/app-ios/Custta/Identidade/Vidro.swift
+++ b/app-ios/Custta/Identidade/Vidro.swift
@@ -69,16 +69,20 @@ struct VidroTokens: Equatable, Sendable {
         }
     }
 
-    /// Escurecimento sob o vidro: só no escuro e fora da navegação, 45% no Transparente e 20% no Fosco (decisão
-    /// do Giovani em 09/10, com o laudo de leitura como juiz). O vidro do iOS clareia o fundo e quase não o
-    /// desfoca, e o texto dos cartões não fechava 4,5:1 sobre a aurora e os pontos do globo; o vidro do mockup
-    /// escurecia o fundo (brilho de 0,84 no Transparente e 0,56 no Fosco). A navegação tem o véu da borda.
+    /// Escurecimento sob o vidro: só no escuro e fora da navegação, 50% no Transparente e 20% no Fosco (decisão do
+    /// Giovani em 09/10, com o laudo de leitura como juiz; o Transparente subiu de 45% na etapa 2, quando o laudo da
+    /// obra mediu o cabeçalho do mês em 4,44:1). O vidro do iOS clareia o fundo e quase não o desfoca, e o texto dos
+    /// cartões não fechava 4,5:1 sobre a aurora e os pontos do globo; o vidro do mockup escurecia o fundo (brilho de
+    /// 0,84 no Transparente e 0,56 no Fosco). Sob a cápsula de abas e o +, 30%: com o + na lista de obras (etapa 2,
+    /// parte 3) a cápsula encolhe e o rótulo "Ajustes" passa sobre o texto branco do comparativo, a 2,75:1 só com o véu
+    /// da borda.
     func escurecimento(_ papel: PapelDoVidro, escuro: Bool) -> Double {
-        guard escuro, papel != .navegacao else { return 0 }
-        switch nivel {
-        case .transparente: return 0.45
-        case .fosco: return 0.2
-        case .solido: return 0
+        guard escuro else { return 0 }
+        switch (nivel, papel) {
+        case (.solido, _): return 0
+        case (_, .navegacao): return 0.30
+        case (.transparente, _): return 0.50
+        case (.fosco, _): return 0.20
         }
     }
 
@@ -90,8 +94,11 @@ struct VidroTokens: Equatable, Sendable {
         }
     }
 
-    /// Texto secundário sobre a superfície (o --muted do site não fecha 4,5:1 sobre o vidro).
+    /// Texto secundário sobre a superfície (o --muted do site não fecha 4,5:1 sobre o vidro). Com Aumentar contraste, o do
+    /// Transparente, mais forte que o do Fosco: sobre o mesmo fundo, o do Fosco dava 24% menos contraste, e ligar a opção
+    /// baixava a leitura (conselho de 13/10).
     var secundario: Token {
+        if contorno && nivel != .solido { return .secundarioTransparente }
         switch nivel {
         case .transparente: return .secundarioTransparente
         case .fosco: return .secundarioFosco
```

Em `scripts/cores-app-ios.mjs`:

```diff
--- a/scripts/cores-app-ios.mjs
+++ b/scripts/cores-app-ios.mjs
@@ -30,6 +30,9 @@ export const CORES = {
     PositivoFundo: ['#0C2F1E', '#D7F2E2'],
     Alerta: ['#E0A83A', '#8A5A06'],                 // --warn; fase em construção
     AlertaFundo: ['#33260F', '#F5ECD2'],
+    // O texto âmbar das etiquetas ("Em construção", "nada em 30 dias"): o Alerta do site (--warn) sobre a AlertaFundo ficava
+    // em 4,42:1 no laudo, na faixa do véu do topo; no claro, um âmbar mais escuro só nas etiquetas.
+    AlertaEtiqueta: ['#E0A83A', '#7A5410'],
     Informacao: ['#3AA0E0', '#1C68A0'],             // fase pronta
     InformacaoFundo: ['#0E2735', '#DCEBF7'],
     Negativo: ['#FB7185', '#C22E55'],               // --red
@@ -81,6 +84,7 @@ export const CORES = {
     PositivoFundo: ['#0C2B1C', '#D7F2E2'],
     Alerta: ['#FBBF24', '#8A5A06'],
     AlertaFundo: ['#33280F', '#F8ECC9'],
+    AlertaEtiqueta: ['#FBBF24', '#7A5410'],
     Informacao: ['#60A5FA', '#2A63C4'],
     InformacaoFundo: ['#122238', '#DCE9FA'],
     Negativo: ['#FB7185', '#C22E55'],
@@ -125,7 +129,7 @@ export const CORES = {
 export const PARES_SOLIDOS = [
   ['Texto', 'Superficie'], ['SecundarioSolido', 'Superficie'], ['LinkNoVidro', 'Superficie'], ['ErroNoVidro', 'Superficie'],
   ['Texto', 'Campo'], ['SobreMarca', 'Marca'], ['SobreTinta', 'Tinta'], ['FantasmaTexto', 'FantasmaFundo'],
-  ['Alerta', 'AlertaFundo'], ['Informacao', 'InformacaoFundo'], ['Positivo', 'PositivoFundo'], ['GoogleTexto', 'GoogleFundo'],
+  ['Alerta', 'AlertaFundo'], ['AlertaEtiqueta', 'AlertaFundo'], ['Informacao', 'InformacaoFundo'], ['Positivo', 'PositivoFundo'], ['GoogleTexto', 'GoogleFundo'],
 ];
 
 const info = { author: 'xcode', version: 1 };
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/cores-app-ios.mjs
```


- [ ] **Step 4: Ver passar**

Run: `node scripts/cores-app-ios.mjs && node --test tests/app-ios.test.cjs 2>&1 | grep -E "^ℹ (pass|fail)"`, o `VidroTokensTests` e, no Mac, o `LeituraNoVidroUITests` inteiro.
Expected: guardas verdes (o par `AlertaEtiqueta`/`AlertaFundo` passa de 4,5:1 nos quatro combos); nenhuma cena da etapa 1 abaixo de 4,5:1, com as notas do escuro maiores do que antes.

- [ ] **Step 5: Prints para o Giovani**

A lista de obras e a cápsula de abas no escuro, antes (`main`) e depois, nos dois tons de pele, e uma etiqueta "Em construção" no claro: o Orquestrador manda ao Giovani com o checklist. Se ele disser que o tom incomoda, o recuo é o cabeçalho do mês na cor do texto (variante B' do conselho), medido de novo.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Assets.xcassets \
  app-ios/Custta/Identidade/Componentes.swift \
  app-ios/Custta/Identidade/Paleta.swift \
  app-ios/Custta/Identidade/Vidro.swift \
  app-ios/CusttaTests/CoresTests.swift \
  scripts/cores-app-ios.mjs
git commit -m "fix: a dose do vidro e o âmbar das etiquetas pelo laudo de leitura" -m "O laudo da tela da obra mediu o cabeçalho do mês em 4,44:1 e, com Aumentar contraste, a linha de baixo do gasto em 4,21:1. O escurecimento sob o vidro sobe para 50% no escuro, o secundário com Aumentar contraste passa a ser o mais forte (ligar a opção baixava a leitura), a cápsula de abas ganha 30% (com o + na lista o rótulo passava sobre texto branco) e o âmbar das etiquetas ganha um token próprio no claro, porque o Alerta é o do site."
```

### Task 11: Marca por conta de que o servidor já respondeu

A guarda de gravação da etapa 1 só considerava os dados vistos com o documento no cache ou com a resposta do servidor. Uma conta vazia (sem documento) aberta sem rede ficava "carregando" para sempre e não podia lançar, mesmo que o servidor já tivesse respondido a ela neste aparelho. Agora o Sincronizador aceita uma marca por conta, gravada na primeira resposta do servidor e apagada junto com o cache (ao sair, ou na limpeza interrompida).

**Files:**
- Modify: `app-ios/Custta/Composicao.swift`
- Modify: `app-ios/Custta/Dados/BancoFirebase.swift`
- Create: `app-ios/Custta/Dados/MarcaNasPreferencias.swift`
- Modify: `app-ios/Custta/Falsos/MontarFalso.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Falsos.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift`
- Test (alterar): `app-ios/CusttaTests/BancoFirebaseTests.swift`
- Test (alterar): `app-ios/CusttaTests/ModeloAppTests.swift`

**Interfaces:**
- Consumes: `Sincronizador` e `BancoFirebase` da etapa 1.
- Produces: `@MainActor protocol MarcaDoServidor { func respondeu(uid: String) -> Bool; func marcar(uid: String) }`; `Sincronizador(transporte:relogio:online:marca:)` (marca opcional); `MarcaNasPreferencias` (chave `custta-servidor-respondeu` no `UserDefaults`); `BancoFirebase.cacheApagado()`; nos falsos, `MarcaEmMemoria` e `CUSTTA_MARCA=servidor`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Falsos.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Falsos.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Falsos.swift
@@ -43,6 +43,13 @@
     }
 }
 
+/// A marca "o servidor já respondeu" em memória.
+@MainActor final class MarcaFalsa: MarcaDoServidor {
+    var contas: Set<String> = []
+    func respondeu(uid: String) -> Bool { contas.contains(uid) }
+    func marcar(uid: String) { contas.insert(uid) }
+}
+
 @MainActor final class RelogioFalso: Relogio {
     final class Agendado: Cancelavel {
         let quando: Int64
```

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift
@@ -353,6 +353,8 @@ struct CenarioDeAbertura: Sendable, CustomTestStringConvertible {
     let nome: String
     let doCache: Bool
     let comDocumento: Bool
+    /// A marca "o servidor já respondeu" desta conta, de uma abertura anterior neste aparelho.
+    var servidorJaRespondeu = false
     let podeGravar: Bool
     var testDescription: String { nome }
 }
@@ -361,6 +363,8 @@ private let cenariosDeAbertura = [
     CenarioDeAbertura(nome: "sem rede e sem dados no aparelho", doCache: true, comDocumento: false, podeGravar: false),
     CenarioDeAbertura(nome: "com rede e conta ainda sem documento", doCache: false, comDocumento: false, podeGravar: true),
     CenarioDeAbertura(nome: "sem rede e com o blob no cache", doCache: true, comDocumento: true, podeGravar: true),
+    CenarioDeAbertura(nome: "sem rede, conta vazia que o servidor já respondeu", doCache: true, comDocumento: false,
+                      servidorJaRespondeu: true, podeGravar: true),
 ]
 
 /* Sem a guarda, `salvar` ficaria esperando uma confirmação que o transporte falso nunca dá. As esperas
@@ -372,7 +376,9 @@ struct SincronizadorCarregamentoTests {
     @Test(arguments: cenariosDeAbertura)
     func salvarSoDepoisDeVerOsDados(_ c: CenarioDeAbertura) async {
         let transporte = TransporteFalso()
-        let s = Sincronizador(transporte: transporte, relogio: RelogioFalso(), online: !c.doCache)
+        let marca = MarcaFalsa()
+        if c.servidorJaRespondeu { marca.marcar(uid: "u1") }
+        let s = Sincronizador(transporte: transporte, relogio: RelogioFalso(), online: !c.doCache, marca: marca)
         s.iniciar(uid: "u1")
         transporte.chega(c.comDocumento ? blobCom(["Casa"]) : nil, doCache: c.doCache)
         #expect(s.dadosCarregados == c.podeGravar)
@@ -392,6 +398,29 @@ struct SincronizadorCarregamentoTests {
         }
     }
 
+    @Test func soOServidorMarcaQueRespondeu() {
+        let transporte = TransporteFalso()
+        let marca = MarcaFalsa()
+        let s = Sincronizador(transporte: transporte, relogio: RelogioFalso(), marca: marca)
+        s.iniciar(uid: "u1")
+        transporte.chega(blobCom(["Casa"]), doCache: true)
+        #expect(marca.contas.isEmpty, "o cache não prova nada sobre o servidor")
+        transporte.chega(blobCom(["Casa"]))
+        #expect(marca.contas.isEmpty, "com documento, o cache dele basta: a marca não faz falta")
+        transporte.chega(nil)
+        #expect(marca.contas == ["u1"], "o servidor respondeu que a conta não tem documento")
+    }
+
+    @Test func marcaDeOutraContaNaoVale() {
+        let transporte = TransporteFalso()
+        let marca = MarcaFalsa()
+        marca.marcar(uid: "outra")
+        let s = Sincronizador(transporte: transporte, relogio: RelogioFalso(), online: false, marca: marca)
+        s.iniciar(uid: "u1")
+        transporte.chega(nil, doCache: true)
+        #expect(!s.dadosCarregados, "a marca é por conta: o aparelho viu a outra, não esta")
+    }
+
     @Test func erroDeLeituraAntesDeCarregarNaoDeixaGravar() async {
         let transporte = TransporteFalso()
         let s = Sincronizador(transporte: transporte, relogio: RelogioFalso())
```

Em `app-ios/CusttaTests/BancoFirebaseTests.swift`:

```diff
--- a/app-ios/CusttaTests/BancoFirebaseTests.swift
+++ b/app-ios/CusttaTests/BancoFirebaseTests.swift
@@ -25,6 +25,22 @@ struct BancoFirebaseTests {
         #expect(!banco.limpezaPendente, "a abertura terminou a limpeza e tirou a marca")
     }
 
+    @Test func apagarOCacheLevaJuntoAMarcaDoServidor() async throws {
+        // A marca diz que o cache sem documento é conta vazia; sem o cache, ela mentiria.
+        let nome = "marca-\(UUID().uuidString.prefix(8).lowercased())"
+        FirebaseApp.configure(name: nome, options: Composicao.opcoesDosEmuladores())
+        let preferencias = try #require(UserDefaults(suiteName: nome))
+        let marca = MarcaNasPreferencias(preferencias: preferencias)
+        marca.marcar(uid: "u1")
+        marca.marcar(uid: "u2")
+        #expect(marca.respondeu(uid: "u1") && marca.respondeu(uid: "u2") && !marca.respondeu(uid: "u3"))
+        let banco = BancoFirebase(app: try #require(FirebaseApp.app(name: nome)), emulador: ("127.0.0.1", 8080), preferencias: preferencias)
+        banco.marcarLimpeza()
+        try await banco.limparCache()
+        #expect(!marca.respondeu(uid: "u1") && !marca.respondeu(uid: "u2"), "sem o cache, nenhuma conta fica marcada")
+        #expect(!banco.limpezaPendente)
+    }
+
     @Test func limpezaRetomadaApagaOCacheDeVerdade() async throws {
         // O app fechou no meio de um "sair": gravação só no cache (sem rede), instância encerrada e a marca de pé.
         let nome = "retomada-\(UUID().uuidString.prefix(8).lowercased())"
```

Em `app-ios/CusttaTests/ModeloAppTests.swift`:

```diff
--- a/app-ios/CusttaTests/ModeloAppTests.swift
+++ b/app-ios/CusttaTests/ModeloAppTests.swift
@@ -9,6 +9,8 @@ struct Abertura: Sendable, CustomTestStringConvertible {
     let nome: String
     let semRede: Bool
     let comDados: Bool
+    /// O servidor já respondeu a esta conta numa abertura anterior (a marca do Sincronizador).
+    var servidorJaRespondeu = false
     let carrega: Bool
     var testDescription: String { nome }
 }
@@ -17,6 +19,7 @@ let aberturas = [
     Abertura(nome: "sem rede e sem dados no aparelho", semRede: true, comDados: false, carrega: false),
     Abertura(nome: "com rede e conta ainda sem documento", semRede: false, comDados: false, carrega: true),
     Abertura(nome: "sem rede e com o blob no cache", semRede: true, comDados: true, carrega: true),
+    Abertura(nome: "sem rede, conta vazia que o servidor já respondeu", semRede: true, comDados: false, servidorJaRespondeu: true, carrega: true),
 ]
 
 /* O modelo das telas com a conta e o transporte falsos: quem decide a tela, a mensagem de sessão
@@ -29,10 +32,13 @@ struct ModeloAppTests {
         let transporte: TransporteFalsoApp
     }
 
-    func montar(conta inicial: String = "nenhuma", semRede: Bool = false, dados: ValorJSON? = DadosDeExemplo.blob) -> Montagem {
+    func montar(conta inicial: String = "nenhuma", semRede: Bool = false, dados: ValorJSON? = DadosDeExemplo.blob,
+                servidorJaRespondeu: Bool = false) -> Montagem {
         let conta = ContaFalsa(inicial: inicial)
         let transporte = TransporteFalsoApp(dados: dados, semRede: semRede)
-        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede)
+        let marca = MarcaEmMemoria()
+        marca.marcarTodas = servidorJaRespondeu
+        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede, marca: marca)
         let modelo = ModeloApp(conta: conta, sincronizador: sincronizador, rede: MonitorDeRede(forcarSemRede: semRede))
         return Montagem(modelo: modelo, conta: conta, transporte: transporte)
     }
@@ -213,7 +219,8 @@ struct ModeloAppTests {
 
     @Test(.timeLimit(.minutes(1)), arguments: aberturas)       // espera limitada (Desfecho); o limite de tempo é a última trava
     func abrirOAppNaoGravaNada(_ a: Abertura) async {
-        let montagem = montar(conta: "senha", semRede: a.semRede, dados: a.comDados ? DadosDeExemplo.blob : nil)
+        let montagem = montar(conta: "senha", semRede: a.semRede, dados: a.comDados ? DadosDeExemplo.blob : nil,
+                              servidorJaRespondeu: a.servidorJaRespondeu)
         let m = montagem.modelo
         await ate { m.fase.ehPrincipal }
         try? await Task.sleep(for: .milliseconds(400))
```


- [ ] **Step 2: Ver falhar**

Run: `TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter SincronizadorTests 2>&1 | grep -E "error:" | head -3`
Expected: não compila: `error: extra argument 'marca' in call` (e `cannot find type 'MarcaDoServidor' in scope` nos falsos).

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Composicao.swift`:

```diff
--- a/app-ios/Custta/Composicao.swift
+++ b/app-ios/Custta/Composicao.swift
@@ -29,7 +29,8 @@ enum Composicao {
         #endif
         let rede = MonitorDeRede()
         let conta = ContaFirebase(app: app, banco: banco, online: { rede.online })
-        let sincronizador = Sincronizador(transporte: TransporteFirebase(banco: banco), relogio: RelogioDoSistema(), online: rede.online)
+        let sincronizador = Sincronizador(transporte: TransporteFirebase(banco: banco), relogio: RelogioDoSistema(), online: rede.online,
+                                          marca: MarcaNasPreferencias())
         return ModeloApp(conta: conta, sincronizador: sincronizador, rede: rede)
     }
```

Em `app-ios/Custta/Dados/BancoFirebase.swift`:

```diff
--- a/app-ios/Custta/Dados/BancoFirebase.swift
+++ b/app-ios/Custta/Dados/BancoFirebase.swift
@@ -162,14 +162,14 @@ final class BancoFirebase {
         let db = firestore()
         try await db.terminate()
         try await apagar(db)
-        desmarcarLimpeza()
+        cacheApagado()
     }
 
     private func terminarLimpezaInterrompida() async {
         registro.notice("limpeza do cache interrompida encontrada na abertura; terminando antes de ler")
         do {
             try await apagar(firestore())      // instância nova, ainda sem uso
-            desmarcarLimpeza()
+            cacheApagado()
         } catch {
             registro.error("limpeza retomada falhou; bloqueado até tentar de novo: \(String(describing: error), privacy: .public)")
             bloqueado = true
@@ -178,6 +178,13 @@ final class BancoFirebase {
         liberar()
     }
 
+    /// O cache foi apagado: some a marca "o servidor já respondeu" de todas as contas (o aparelho deixou de ter o que ela
+    /// garantia) e só depois a da limpeza; se o app fechar no meio, a abertura seguinte limpa de novo e apaga as duas.
+    private func cacheApagado() {
+        preferencias.removeObject(forKey: MarcaNasPreferencias.chave)
+        desmarcarLimpeza()
+    }
+
     private func liberar() {
         ocupado = false
         let fila = esperando
```

Criar `app-ios/Custta/Dados/MarcaNasPreferencias.swift`:

```swift
import Foundation
import CusttaNucleo

/// A marca "o servidor já respondeu" de cada conta (`MarcaDoServidor`, do Sincronizador), nas preferências do app. O
/// BancoFirebase a apaga junto com o cache local: as duas dizem o que este aparelho já viu da conta, e uma sem a outra
/// faria o cache vazio de um aparelho limpo passar por conta vazia.
@MainActor
final class MarcaNasPreferencias: MarcaDoServidor {
    static let chave = "custta-servidor-respondeu"
    private let preferencias: UserDefaults

    init(preferencias: UserDefaults = .standard) { self.preferencias = preferencias }

    func respondeu(uid: String) -> Bool { (preferencias.stringArray(forKey: Self.chave) ?? []).contains(uid) }

    func marcar(uid: String) {
        var contas = preferencias.stringArray(forKey: Self.chave) ?? []
        guard !contas.contains(uid) else { return }
        contas.append(uid)
        preferencias.set(contas, forKey: Self.chave)
    }
}
```

Em `app-ios/Custta/Falsos/MontarFalso.swift`:

```diff
--- a/app-ios/Custta/Falsos/MontarFalso.swift
+++ b/app-ios/Custta/Falsos/MontarFalso.swift
@@ -9,6 +9,8 @@ import CusttaNucleo
    CUSTTA_DADOS   vitrine (padrão: as obras do mockup) | exemplo (as dos testes) | vazio
    CUSTTA_REDE    offline (abre "em modo avião": dados do cache e indicador "Sem conexão")
    CUSTTA_LEITURA erro (a escuta falha com permission-denied) | formato (documento que o app não lê)
+   CUSTTA_MARCA   servidor (o servidor já respondeu a esta conta numa abertura anterior: com CUSTTA_REDE=offline e
+                  CUSTTA_DADOS=vazio, é a conta vazia que abre sem rede e pode lançar)
    CUSTTA_LIMPEZA falha (a limpeza do cache falha no sair e na 1ª nova tentativa) | abertura (abre bloqueado,
                   e a 1ª nova tentativa também falha); cada nova tentativa leva 8 s, para o "Limpando…" ficar à
                   vista mesmo no simulador da CI, onde o teste só o encontra uns 4 s depois do toque */
@@ -29,8 +31,20 @@ extension Composicao {
         }
         let transporte = TransporteFalsoApp(dados: dados, semRede: semRede, falhaDeLeitura: falha)
         let rede = MonitorDeRede(forcarSemRede: semRede)
-        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede)
+        let marca = MarcaEmMemoria()
+        if ambiente["CUSTTA_MARCA"] == "servidor" { marca.marcarTodas = true }
+        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede, marca: marca)
         return ModeloApp(conta: conta, sincronizador: sincronizador, rede: rede)
     }
 }
+
+/// A marca "o servidor já respondeu" em memória (só Debug): cada abertura com os falsos começa sem ela, a não ser que o
+/// teste peça (`marcarTodas`, a conta de qualquer uid já vista).
+@MainActor
+final class MarcaEmMemoria: MarcaDoServidor {
+    var marcarTodas = false
+    private(set) var contas: Set<String> = []
+    func respondeu(uid: String) -> Bool { marcarTodas || contas.contains(uid) }
+    func marcar(uid: String) { contas.insert(uid) }
+}
 #endif
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift
@@ -15,9 +15,11 @@ import Observation
      normalização e só trocam o estado se o conteúdo mudou.
 
    Como o site, nunca grava antes de ver os dados: até chegar um snapshot do servidor, ou do
-   cache com o documento, `salvar` recusa com "nao-carregado". Uma regra a mais que o site: volta
-   a recusar se chegar um documento que não deu para ler inteiro ("formato-desconhecido"). Sem
-   isso, uma edição regravaria o documento inteiro por cima do que o app não viu. */
+   cache com o documento, `salvar` recusa com "nao-carregado". Duas regras a mais que o site:
+   volta a recusar se chegar um documento que não deu para ler inteiro ("formato-desconhecido"),
+   porque uma edição regravaria o documento inteiro por cima do que o app não viu; e o cache sem
+   documento vale quando a marca diz que o servidor já respondeu a esta conta neste aparelho
+   (a conta vazia que fechou o app sem gravar e abriu sem rede). A marca some junto com o cache. */
 
 public enum OrigemErro: String, Sendable {
     case escrita, leitura
@@ -59,6 +61,14 @@ public struct Instantaneo: Sendable {
     func aguardarGravacoesPendentes(concluir: @escaping @MainActor (String?) -> Void)
 }
 
+/// Marca, por conta, de que o servidor já respondeu neste aparelho que a conta não tem documento (com documento, o cache
+/// dele basta). Mora fora do cache do banco e é apagada junto com ele: com a marca, o cache sem documento quer dizer
+/// conta vazia, e não aparelho novo.
+@MainActor public protocol MarcaDoServidor: AnyObject {
+    func respondeu(uid: String) -> Bool
+    func marcar(uid: String)
+}
+
 @MainActor public protocol Relogio: AnyObject {
     var agoraMs: Int64 { get }
     func agendar(depois ms: Int, _ acao: @escaping @MainActor () -> Void) -> any Cancelavel
@@ -130,6 +140,7 @@ public final class Sincronizador {
 
     @ObservationIgnored private let transporte: TransporteDados
     @ObservationIgnored private let relogio: Relogio
+    @ObservationIgnored private let marca: MarcaDoServidor?
     @ObservationIgnored private var uid: String?
     @ObservationIgnored private var online: Bool
     @ObservationIgnored private var pendente: ValorJSON?
@@ -146,9 +157,10 @@ public final class Sincronizador {
     @ObservationIgnored private var pendenciaCache = false
     @ObservationIgnored private var ultimoAvisoRaro: Int64?
 
-    public init(transporte: TransporteDados, relogio: Relogio, online: Bool = true) {
+    public init(transporte: TransporteDados, relogio: Relogio, online: Bool = true, marca: MarcaDoServidor? = nil) {
         self.transporte = transporte
         self.relogio = relogio
+        self.marca = marca
         self.online = online
         self.estadoSinc = online ? .ocioso : .offline
     }
@@ -332,7 +344,9 @@ public final class Sincronizador {
         guard !sujo else { return }          // edição desta sessão ainda não confirmada vence o eco
         let novo = normaliza(i.dados)
         if !mesmoConteudo(novo, estado.arvore) { estado = Estado(normalizado: novo) }
-        if !i.doCache || i.dados != nil { dadosCarregados = true }
+        if !i.doCache, i.dados == nil, let uid { marca?.marcar(uid: uid) }
+        let contaVaziaJaVista = uid.map { marca?.respondeu(uid: $0) ?? false } ?? false
+        if !i.doCache || i.dados != nil || contaVaziaJaVista { dadosCarregados = true }
     }
 
     /* ---------- estado e avisos ---------- */
```


- [ ] **Step 4: Ver passar**

Run: o núcleo inteiro; depois `xcodebuild build-for-testing "${XB[@]}"` e `xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/ModeloAppTests -only-testing:CusttaTests/BancoFirebaseTests`.
Expected: `✔ Test run with 145 tests … passed`; os dois do app verdes, inclusive a abertura "sem rede, conta vazia que o servidor já respondeu".

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Composicao.swift \
  app-ios/Custta/Dados/BancoFirebase.swift \
  app-ios/Custta/Dados/MarcaNasPreferencias.swift \
  app-ios/Custta/Falsos/MontarFalso.swift \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Falsos.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift \
  app-ios/CusttaTests/BancoFirebaseTests.swift \
  app-ios/CusttaTests/ModeloAppTests.swift
git commit -m "feat: marca por conta de que o servidor já respondeu, na guarda de gravação" -m "Uma conta sem documento aberta sem rede ficava carregando para sempre, mesmo quando o servidor já tinha respondido a ela neste aparelho. O Sincronizador passa a aceitar uma marca por conta, gravada na primeira resposta do servidor e apagada junto com o cache, e a conta vazia já vista pode lançar sem rede. Fecha a primeira pendência obrigatória do plano da etapa 1."
```

### Task 12: Aviso de nao-carregado com o texto do site

A segunda pendência: a tela que grava antes de ver os dados da conta mostra o texto do site (com rede, "Carregando suas obras, tente em instantes."; sem rede, "Conecte à internet para carregar suas obras antes de lançar.").

**Files:**
- Modify: `app-ios/Custta/Estado/ModeloApp.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Telas.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TelasTests.swift`
- Test (alterar): `app-ios/CusttaTests/ModeloAppTests.swift`

**Interfaces:**
- Produces: `textoNaoCarregado(online:) -> String` (núcleo); `ModeloApp.mensagemDeNaoCarregado`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TelasTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TelasTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TelasTests.swift
@@ -89,4 +89,9 @@ struct TelasTests {
         #expect(Nonce.gerar() != n)
         #expect(Nonce.sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
     }
+
+    @Test func textoDeQuemGravaAntesDeCarregar() {
+        #expect(textoNaoCarregado(online: true) == "Carregando suas obras, tente em instantes.")
+        #expect(textoNaoCarregado(online: false) == "Conecte à internet para carregar suas obras antes de lançar.")
+    }
 }
```

Em `app-ios/CusttaTests/ModeloAppTests.swift`:

```diff
--- a/app-ios/CusttaTests/ModeloAppTests.swift
+++ b/app-ios/CusttaTests/ModeloAppTests.swift
@@ -234,6 +234,20 @@ struct ModeloAppTests {
         }
     }
 
+    @Test func mensagemDeNaoCarregadoComoOSite() async {
+        #expect(montar().modelo.mensagemDeNaoCarregado == "Carregando suas obras, tente em instantes.")
+        #expect(montar(semRede: true).modelo.mensagemDeNaoCarregado == "Conecte à internet para carregar suas obras antes de lançar.")
+    }
+
+    /// Documento num formato que o app não lê: gravar fica recusado, e "carregando" seria para sempre.
+    @Test func mensagemDeNaoCarregadoComDocumentoQueOAppNaoLe() async {
+        let s = Sincronizador(transporte: TransporteFalsoApp(dados: nil, semRede: false, falhaDeLeitura: "formato-desconhecido"),
+                              relogio: RelogioDoSistema())
+        let m = ModeloApp(conta: ContaFalsa(inicial: "senha"), sincronizador: s, rede: MonitorDeRede(forcarSemRede: false))
+        await ate { if case .erro = m.sincronizador.estadoSinc { return true }; return false }
+        #expect(m.mensagemDeNaoCarregado == textoErroDeLeitura("formato-desconhecido"))
+    }
+
     @Test func confirmarOEmailAvisaATelaQueLeOUsuario() async {
         let m = montar(conta: "senha-confirma-ao-conferir").modelo
         await ate { m.fase.ehPrincipal }
```


- [ ] **Step 2: Ver falhar**

Run: o filtro `TelasTests` do núcleo.
Expected: não compila: `cannot find 'textoNaoCarregado' in scope`.

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Estado/ModeloApp.swift`:

```diff
--- a/app-ios/Custta/Estado/ModeloApp.swift
+++ b/app-ios/Custta/Estado/ModeloApp.swift
@@ -238,6 +238,18 @@ final class ModeloApp {
         }
     }
 
+    /* ---------- gravação ---------- */
+
+    /// O alerta de quem tenta gravar antes de o app ver os dados da conta (`nao-carregado`). O que a pessoa preencheu
+    /// continua na folha (no site, a folha fechava). Documento num formato que o app não lê também não deixa gravar, e
+    /// aí "carregando" seria para sempre: vale o texto do erro de leitura.
+    var mensagemDeNaoCarregado: String {
+        if case .erro(let codigo, .leitura) = sincronizador.estadoSinc, codigo == "formato-desconhecido" {
+            return textoErroDeLeitura(codigo)
+        }
+        return textoNaoCarregado(online: rede.online)
+    }
+
     /* ---------- sincronização e avisos ---------- */
 
     func tentarDeNovo() {
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Telas.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Telas.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Telas.swift
@@ -80,6 +80,12 @@ public func textoErroDeLeitura(_ codigo: String) -> String {
     return "Não deu para buscar suas obras agora. Confira a internet e tente de novo. Nada foi alterado: as obras continuam salvas como estavam."
 }
 
+/// O alerta de quem tenta gravar antes de o app ver os dados da conta (`nao-carregado`), com os textos do
+/// `avisaNaoCarregado` do app.js: com rede, o primeiro snapshot só está demorando; sem rede, é preciso conectar.
+public func textoNaoCarregado(online: Bool) -> String {
+    online ? "Carregando suas obras, tente em instantes." : "Conecte à internet para carregar suas obras antes de lançar."
+}
+
 /// Nonce do login com a Apple: 32 bytes aleatórios em hexadecimal (a Apple assina o SHA-256 dele).
 public enum Nonce {
     public static func gerar() -> String {
```


- [ ] **Step 4: Ver passar**

Run: o núcleo e `-only-testing:CusttaTests/ModeloAppTests`.
Expected: `✔ Test run with 146 tests … passed`; `ModeloAppTests` verde.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Estado/ModeloApp.swift \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/Telas.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TelasTests.swift \
  app-ios/CusttaTests/ModeloAppTests.swift
git commit -m "feat: aviso de nao-carregado com o texto do site" -m "Quem tenta gravar antes de o app ver os dados da conta recebe o texto do site, com e sem rede. As telas que gravam (a folha do gasto, no PR seguinte) mostram esse texto num alerta e mantêm o que foi preenchido. Fecha a segunda pendência obrigatória do plano da etapa 1."
```

### Task 13: Regras da tela da obra no núcleo

Os textos e a montagem da tela da obra, puros e testados: a lista por mês do mais recente (a ordem do site, `data + id` decrescente), o "A vencer" agrupado no alto (o futuro, do mais próximo), o resumo "N gastos · o próximo é em dd/mm/aa", a linha do gasto (sem descrição, o título é o tópico e a linha de baixo não o repete; parcela com "(n/de)" e ", parcela n de de" no que o VoiceOver lê; "Pix" e "Cartão" por extenso) e os quatro indicadores com os textos do site (na venda sem estimativa, "Toque no lápis para informar o valor").

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/ObraNaTela.swift`
- Test (criar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraNaTelaTests.swift`

**Interfaces:**
- Consumes: `totalBruto`, `totalCorrigido`, `aPagar`, `mesesDeObra`, `precoPorM2`, `moeda`, `moedaCurta`, `fmtMeses` e `mapaDeTopicos` (núcleo da etapa 1).
- Produces: `dataCurta(_:)`, `dataPorExtenso(_:)`, `tituloDoMes(_:)`, `textoDoInicio(_:hoje:)`, `MesDeGastos`, `GrupoAVencer` (`quantidade`, `proximo`, `resumo`), `ListaDaObra`, `listaDaObra(_:hoje:)`, `LinhaDeGasto` (`titulo`, `topico`, `pagamento`, `data`, `valor`, `rotulo`, `valorFalado`, `icone`), `linhaDeGasto(_:topicos:)`, `VendaNaTela`, `IndicadoresDaObra`, `indicadoresDaObra(_:taxa:hoje:)`.

- [ ] **Step 1: Escrever os testes**

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraNaTelaTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/* A tela da obra: lista por mês, "A vencer" no alto, a linha do gasto e os indicadores, com os números dos vetores. */
struct ObraNaTelaTests {
    static let hoje = "2026-10-12"

    func gasto(_ id: String, _ data: String, _ valor: Double, descricao: String = "", topico: String = "matbasicos",
               pagamento: String = "pix", parcela: (Int, Int)? = nil) -> ValorJSON {
        var g: [String: ValorJSON] = ["id": .texto(id), "valor": .numero(valor), "topico": .texto(topico), "descricao": .texto(descricao),
                                      "data": .texto(data), "pagamento": .texto(pagamento)]
        if let parcela {
            g["grupoId"] = .texto("gr")
            g["parcela"] = .objeto(["n": .numero(Double(parcela.0)), "de": .numero(Double(parcela.1))])
        }
        return .objeto(g)
    }

    func obra(_ gastos: [ValorJSON], extra: [String: ValorJSON] = [:]) -> Obra {
        var o: [String: ValorJSON] = ["id": .texto("o1"), "nome": .texto("Casa Alphaville"), "dataInicio": .texto("2025-08-12"),
                                      "fase": .texto("construcao"), "gastos": .lista(gastos)]
        o.merge(extra) { _, novo in novo }
        return Estado.de(.objeto(["obras": .lista([.objeto(o)])])).obras[0]
    }

    @Test func datasDaTela() {
        #expect(dataCurta("2026-10-05") == "05/10/26")
        #expect(dataPorExtenso("2026-10-05") == "5 de outubro de 2026")
        #expect(tituloDoMes("2026-03") == "Março de 2026")
        #expect(textoDoInicio(obra([]), hoje: Self.hoje) == "começou em 12/08/25 · 14 meses")
    }

    @Test func mesesDoMaisRecenteEAVencerNoAlto() {
        let o = obra([
            gasto("a", "2026-09-30", 100), gasto("b", "2026-10-10", 4980), gasto("c", "2026-10-12", 10),
            gasto("d", "2026-11-05", 6150, parcela: (5, 10)), gasto("e", "2026-10-15", 4800, parcela: (2, 6)),
            gasto("f", "2026-10-10", 1), gasto("g", "2026-11-05", 2300, parcela: (2, 3)),
        ])
        let lista = listaDaObra(o, hoje: Self.hoje)
        #expect(lista.meses.map(\.id) == ["2026-10", "2026-09"], "hoje fica fora do A vencer")
        #expect(lista.meses[0].gastos.map(\.id) == ["c", "f", "b"], "data e id do mais recente para o mais antigo, como o site")
        #expect(lista.meses[0].total == 4991)
        #expect(lista.meses[0].titulo == "Outubro de 2026")
        let aVencer = try! #require(lista.aVencer)
        #expect(aVencer.meses.map(\.id) == ["2026-10", "2026-11"], "o próximo vencimento primeiro")
        #expect(aVencer.meses[1].gastos.map(\.id) == ["d", "g"])
        #expect(aVencer.total == 13250)
        #expect(aVencer.resumo == "3 gastos · o próximo é em 15/10/26")
        #expect(listaDaObra(obra([gasto("a", "2026-09-30", 100)]), hoje: Self.hoje).aVencer == nil)
    }

    @Test func linhaDoGasto() {
        let topicos = mapaDeTopicos([])
        let pix = linhaDeGasto(Gasto(campos: gasto("a", "2026-10-10", 4980, descricao: "Cimento CP-II, 120 sacos").comoObjeto!), topicos: topicos)
        #expect(pix.titulo == "Cimento CP-II, 120 sacos")
        #expect(pix.topico == "Materiais básicos")
        #expect(pix.pagamento == "Pix")
        #expect(pix.data == "10/10/26")
        #expect(pix.valor == "\u{2212}R$\u{a0}4.980,00")
        #expect(pix.rotulo == "Cimento CP-II, 120 sacos. Materiais básicos, Pix, 10 de outubro de 2026")
        #expect(pix.valorFalado == "R$\u{a0}4.980,00")
        let semDescricao = linhaDeGasto(Gasto(campos: gasto("b", "2026-10-06", 2300, topico: "pintura", pagamento: "cartao", parcela: (1, 3)).comoObjeto!),
                                        topicos: topicos)
        #expect(semDescricao.titulo == "Pintura (1/3)", "sem descrição, o título é o tópico")
        #expect(semDescricao.topico == nil, "e a linha de baixo não repete o tópico")
        #expect(semDescricao.pagamento == "Cartão")
        #expect(semDescricao.rotulo == "Pintura, parcela 1 de 3. Cartão, 6 de outubro de 2026")
        let estranho = linhaDeGasto(Gasto(campos: gasto("c", "2026-10-06", 1, topico: "c_sumiu", pagamento: "boleto").comoObjeto!), topicos: topicos)
        #expect(estranho.titulo == "c_sumiu" && estranho.icone == "etiqueta" && estranho.pagamento == nil)
    }

    @Test func indicadoresComOsTextosDoSite() {
        let comGastos = obra([gasto("a", "2026-09-30", 100), gasto("b", "2026-10-20", 50), gasto("c", "2026-12-20", 70)],
                             extra: ["valorEstimadoVenda": .numero(1_450_000), "areaM2": .numero(300)])
        let i = indicadoresDaObra(comGastos, taxa: 1, hoje: Self.hoje)
        #expect(i.totalGasto == "R$\u{a0}220,00")
        #expect(i.etiquetaDoTotal == "3 lançamentos")
        #expect(i.notaDoCorrigido.hasPrefix("Correção até hoje: +R$"))
        #expect(i.aPagar == "R$\u{a0}50,00" && i.etiquetaDoAPagar == "1 vencimento")
        #expect(i.venda == .estimada(valor: "R$\u{a0}1.450.000,00", nota: "R$ 4,8 mil/m² · 300 m²"))
        let vazia = indicadoresDaObra(obra([]), taxa: 1, hoje: Self.hoje)
        #expect(vazia.etiquetaDoTotal == "sem gastos" && vazia.etiquetaDoAPagar == "nada em 30 dias")
        #expect(vazia.venda == .semEstimativa)
        let semArea = indicadoresDaObra(obra([gasto("a", "2026-09-30", 100)], extra: ["valorEstimadoVenda": .numero(1000)]), taxa: 0, hoje: Self.hoje)
        #expect(semArea.venda == .estimada(valor: "R$\u{a0}1.000,00", nota: "margem R$\u{a0}900,00"))
        let vendida = obra([gasto("a", "2025-09-30", 200_000)],
                           extra: ["fase": .texto("vendida"), "venda": .objeto(["valor": .numero(150_000), "data": .texto("2026-06-30")])])
        let v = indicadoresDaObra(vendida, taxa: 1, hoje: Self.hoje)
        #expect(v.notaDoCorrigido.hasPrefix("Correção até a venda: +R$"))
        guard case .vendida(let valor, let etiqueta, let nota, let positivo) = v.venda else { Issue.record("vendida"); return }
        #expect(valor == "R$\u{a0}150.000,00" && etiqueta == "Vendida em 30/06/26" && !positivo)
        #expect(nota.hasPrefix("lucro -R$ 50 mil · -R$"), "\(nota)")
    }
}
```


- [ ] **Step 2: Ver falhar**

Run: o filtro `ObraNaTelaTests` do núcleo.
Expected: não compila: `cannot find 'listaDaObra' in scope`.

- [ ] **Step 3: Implementar**

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/ObraNaTela.swift`:

```swift
import Foundation

/* Regras da tela da obra: os textos do renderObra e do gastoRow do app.js, com o desenho aprovado na etapa 2 (lista
   por mês com o total, "A vencer" agrupado no alto, valor sem vermelho, "Pix" e "Cartão" por extenso e a linha sem
   descrição sem repetir o tópico). Os números vêm das funções do calc.js que já têm vetor (totalBruto, totalCorrigido,
   aPagar, lucroVenda, precoPorM2, mesesDeObra); o agrupamento é do app e tem teste próprio. */

let nomesDosMeses = ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro",
                     "novembro", "dezembro"]

/// "dd/mm/aa", o `fmtData` do app.js.
public func dataCurta(_ iso: String) -> String {
    guard let c = componentesISO(iso) else { return iso }
    let ano = String(c.ano)
    return doisDigitos(c.dia) + "/" + doisDigitos(c.mes) + "/" + String(ano.suffix(2))
}

/// "10 de outubro de 2026", para o VoiceOver.
public func dataPorExtenso(_ iso: String) -> String {
    guard let c = componentesISO(iso) else { return iso }
    return "\(c.dia) de \(nomesDosMeses[c.mes - 1]) de \(c.ano)"
}

/// "Outubro de 2026", do mês AAAA-MM.
public func tituloDoMes(_ mes: String) -> String {
    guard let c = componentesISO(mes + "-01") else { return mes }
    let nome = nomesDosMeses[c.mes - 1]
    return nome.prefix(1).uppercased() + nome.dropFirst() + " de \(c.ano)"
}

/// "começou em 12/08/25 · 14 meses", a linha de baixo do cabeçalho da obra.
public func textoDoInicio(_ obra: Obra, hoje: String) -> String {
    "começou em \(dataCurta(obra.dataInicio)) · \(fmtMeses(mesesDeObra(obra, hoje: hoje)))"
}

/// Os gastos de um mês, com o total dele.
public struct MesDeGastos: Equatable, Sendable, Identifiable {
    /// AAAA-MM.
    public let id: String
    public let titulo: String
    public let total: Double
    public let gastos: [Gasto]
}

/// O "A vencer": os gastos com data depois de hoje (parcelas futuras e gastos agendados), fechado no alto da lista.
public struct GrupoAVencer: Equatable, Sendable {
    public let total: Double
    /// Por mês, do mais próximo para o mais distante; dentro do mês, por data.
    public let meses: [MesDeGastos]

    public var quantidade: Int { meses.reduce(0) { $0 + $1.gastos.count } }
    /// A data do próximo vencimento.
    public var proximo: String { meses.first?.gastos.first?.data ?? "" }
    /// "13 gastos · o próximo é em 15/10/26".
    public var resumo: String {
        "\(quantidade) \(quantidade == 1 ? "gasto" : "gastos") · o próximo é em \(dataCurta(proximo))"
    }
}

/// A lista de gastos da obra: o "A vencer" (se houver) e os meses, do mais recente para o mais antigo.
public struct ListaDaObra: Equatable, Sendable {
    public let aVencer: GrupoAVencer?
    public let meses: [MesDeGastos]
}

private func porMes(_ gastos: [Gasto]) -> [MesDeGastos] {
    var ordem: [String] = []
    var grupos: [String: [Gasto]] = [:]
    for g in gastos {
        let mes = String(g.data.prefix(7))
        if grupos[mes] == nil { ordem.append(mes) }
        grupos[mes, default: []].append(g)
    }
    return ordem.map { mes in
        let lista = grupos[mes] ?? []
        return MesDeGastos(id: mes, titulo: tituloDoMes(mes), total: lista.reduce(0) { $0 + $1.valor }, gastos: lista)
    }
}

/// A lista da tela da obra. Fora do "A vencer", a ordem é a do site (data e id, do mais recente para o mais antigo);
/// no "A vencer", a contrária, para o próximo vencimento vir primeiro.
public func listaDaObra(_ obra: Obra, hoje: String) -> ListaDaObra {
    let ordenados = ordenadoEstavel(obra.gastos) { menorJS($1.data + $1.id, $0.data + $0.id) }
    let futuros = ordenados.filter { menorJS(hoje, $0.data) }
    let passados = ordenados.filter { !menorJS(hoje, $0.data) }
    let aVencer = futuros.isEmpty ? nil
        : GrupoAVencer(total: futuros.reduce(0) { $0 + $1.valor }, meses: porMes(futuros.reversed()))
    return ListaDaObra(aVencer: aVencer, meses: porMes(passados))
}

/// O que a linha de um gasto mostra e o que o VoiceOver lê.
public struct LinhaDeGasto: Equatable, Sendable {
    /// A descrição, ou o nome do tópico quando ela está vazia, com " (n/de)" na parcela.
    public let titulo: String
    /// O nome do tópico na linha de baixo; nil quando o título já é o tópico (sem descrição).
    public let topico: String?
    /// "Pix", "Cartão" ou nil (outra forma de pagamento que o site gravou).
    public let pagamento: String?
    /// "10/10/26".
    public let data: String
    /// "−R$ 4.980,00": o menos (U+2212) e o valor do site, sem vermelho.
    public let valor: String
    /// "Cimento CP-II, 120 sacos. Materiais básicos, Pix, 10 de outubro de 2026" (sem o valor, que vai no value).
    public let rotulo: String
    /// "R$ 4.980,00", sem o "menos".
    public let valorFalado: String
    public let icone: String
}

/// A linha do gasto. O tópico que o app não conhece (apagado em Ajustes) aparece pelo id, com o ícone etiqueta, como
/// no site.
public func linhaDeGasto(_ g: Gasto, topicos: [String: Topico]) -> LinhaDeGasto {
    let topico = topicos[g.topico] ?? Topico(id: g.topico, nome: g.topico.isEmpty ? "Outros" : g.topico, icone: "etiqueta")
    let descricao = g.descricao                      // o `g.descricao || t.nm` do site: só a descrição vazia cai no tópico
    let parcela = g.parcela.map { " (\($0.n)/\($0.de))" } ?? ""
    let titulo = (descricao.isEmpty ? topico.nome : descricao) + parcela
    let pagamento: String? = g.pagamento == "pix" ? "Pix" : g.pagamento == "cartao" ? "Cartão" : nil
    let tituloFalado = (descricao.isEmpty ? topico.nome : descricao) + (g.parcela.map { ", parcela \($0.n) de \($0.de)" } ?? "")
    let detalhes = [descricao.isEmpty ? nil : topico.nome, pagamento, dataPorExtenso(g.data)].compactMap { $0 }
    return LinhaDeGasto(titulo: titulo, topico: descricao.isEmpty ? nil : topico.nome, pagamento: pagamento,
                        data: dataCurta(g.data), valor: "\u{2212}" + moeda(g.valor),
                        rotulo: tituloFalado + ". " + detalhes.joined(separator: ", "), valorFalado: moeda(g.valor),
                        icone: topico.icone)
}

/// O indicador de venda, nas três situações do site.
public enum VendaNaTela: Equatable, Sendable {
    /// "Venda", "Vendida em dd/mm/aa", o valor e "lucro … · … vs banco" (verde com lucro bruto ≥ 0).
    case vendida(valor: String, etiqueta: String, nota: String, lucroPositivo: Bool)
    /// "Venda estimada", "estimativa", o valor e o R$/m² com a área (ou a margem sobre o corrigido).
    case estimada(valor: String, nota: String)
    /// "Venda estimada", "—" e "Toque no lápis para informar o valor" (no site, "cadastre no editar obra").
    case semEstimativa
}

/// Os quatro indicadores da obra (opção A do mockup: o total gasto em destaque e os outros três num cartão).
public struct IndicadoresDaObra: Equatable, Sendable {
    public let totalGasto: String
    /// "46 lançamentos", "1 lançamento" ou "sem gastos".
    public let etiquetaDoTotal: String
    public let corrigido: String
    /// "Correção até hoje: +R$ …", ou "até a venda".
    public let notaDoCorrigido: String
    public let aPagar: String
    /// "3 vencimentos", "1 vencimento" ou "nada em 30 dias".
    public let etiquetaDoAPagar: String
    public let venda: VendaNaTela
}

public func indicadoresDaObra(_ obra: Obra, taxa: Double, hoje: String) -> IndicadoresDaObra {
    let bruto = totalBruto(obra)
    let corr = totalCorrigido(obra, taxa: taxa, hoje: hoje)
    let vencimentos = aPagar([obra], hoje: hoje)
    let n = obra.gastos.count
    let venda: VendaNaTela
    if obra.fase == .vendida, let v = obra.venda, let lucro = lucroVenda(obra, taxa: taxa) {
        venda = .vendida(valor: moeda(v.valor), etiqueta: "Vendida em \(dataCurta(v.data))",
                         nota: "lucro \(moedaCurta(lucro.bruto)) · \(lucro.vsBanco >= 0 ? "+" : "")\(moedaCurta(lucro.vsBanco)) vs banco",
                         lucroPositivo: lucro.bruto >= 0)
    } else if let estimado = obra.valorEstimadoVenda, estimado != 0 {
        let nota = precoPorM2(estimado, obra.areaM2).map { "\(moedaCurta($0))/m² · \(numeroJS(obra.areaM2 ?? 0).replacingOccurrences(of: ".", with: ",")) m²" }
            ?? "margem \(moedaCurta(estimado - corr))"
        venda = .estimada(valor: moeda(estimado), nota: nota)
    } else {
        venda = .semEstimativa
    }
    return IndicadoresDaObra(
        totalGasto: moeda(bruto), etiquetaDoTotal: n == 0 ? "sem gastos" : "\(n) lançamento\(n > 1 ? "s" : "")",
        corrigido: moeda(corr), notaDoCorrigido: "Correção até \(obra.venda != nil ? "a venda" : "hoje"): +\(moeda(corr - bruto))",
        aPagar: moeda(vencimentos.total),
        etiquetaDoAPagar: vencimentos.qtd == 0 ? "nada em 30 dias" : "\(vencimentos.qtd) vencimento\(vencimentos.qtd > 1 ? "s" : "")",
        venda: venda)
}
```


- [ ] **Step 4: Ver passar**

Run: o núcleo inteiro.
Expected: `✔ Test run with 150 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/ObraNaTela.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraNaTelaTests.swift
git commit -m "feat: regras da tela da obra no núcleo" -m "A lista de gastos por mês, o A vencer agrupado no alto, a linha do gasto e os quatro indicadores, com os textos do site e o desenho aprovado no mockup (Pix e Cartão por extenso, linha sem descrição sem repetir o tópico, venda sem estimativa pedindo o lápis). Tudo puro e testado, antes da tela."
```

### Task 14: Ícones dos tópicos e peças da tela da obra

Os 21 ícones dos tópicos e os da tela (etiqueta dos tópicos próprios, calendário, cartão, lápis, acordo, voltar, recibo) entram no catálogo pelo script; as peças pequenas que a tela usa ficam nos componentes: a etiqueta da fase grande da pílula, o dinheiro numa linha só que encolhe (`ValorEmDinheiro`), o ícone do catálogo com o da etiqueta para tópico desconhecido e o `.foraDoLaudo()` para os símbolos soltos (o apagador de texto do laudo apagava o traço fino da seta, que virava uma "palavra" de nota errada).

**Files:**
- Modify: `app-ios/Custta/Identidade/Componentes.swift`
- Modify: `scripts/icones-app-ios.mjs`
- Test (alterar): `tests/app-ios.test.cjs`
- Gerado: ícones em `app-ios/Custta/Assets.xcassets/Icones/` (`node scripts/icones-app-ios.mjs`)

**Interfaces:**
- Produces: `EtiquetaDeFase(fase:grande:)`, `ValorEmDinheiro(texto:fonte:)`, `iconeDoCatalogo(_:) -> String`, `View.foraDoLaudo()` (em Debug, `-custta.semSimbolos` some com o símbolo nos dois prints do laudo).

- [ ] **Step 1: Pôr o dinheiro e o título pequeno na lista fixa da guarda**

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -423,11 +423,13 @@ test('ícone junto de texto cresce com a letra: o dos Label, a seta da dica de e
   assert.doesNotMatch(conta[0], /\.frame\(width: \d/, 'o logo da Apple é letra (.body): o círculo e o G do Google crescem junto (@ScaledMetric)');
 });
 
-test('texto cresce com a letra: lineLimit e minimumScaleFactor só no botão do Google e no indicador da barra', () => {
+test('texto cresce com a letra: lineLimit e minimumScaleFactor só no botão do Google, no indicador da barra e no dinheiro', () => {
   // A auditoria de texto cortado do Xcode não vê dentro de um elemento que o VoiceOver lê inteiro (o cartão da
   // obra): com o nome da obra preso numa linha, ela passa na maior letra. Ficam numa linha, por decisão, o botão
-  // do Google (letra travada, fora da auditoria de tipo dinâmico) e o indicador de sincronização da barra.
-  const fixos = new Set(['BotaoGoogle', 'IndicadorDeSincronizacao']);
+  // do Google (letra travada, fora da auditoria de tipo dinâmico), o indicador de sincronização da barra, o
+  // dinheiro (ValorEmDinheiro, mockup da etapa 2: encolhe até a metade em vez de quebrar) e o título pequeno da
+  // barra da obra (corta como o do sistema, em vez de empurrar o voltar e o lápis).
+  const fixos = new Set(['BotaoGoogle', 'IndicadorDeSincronizacao', 'ValorEmDinheiro', 'TituloPequenoDaBarra']);
   for(const f of arquivosSwift('app-ios/Custta')){
     const t = ler(f);
     for(const m of t.matchAll(/\.(lineLimit|minimumScaleFactor)\(/g)){
```


- [ ] **Step 2: Ver falhar**

Com a lista `USADOS` nova no `scripts/icones-app-ios.mjs` (o bloco dele no Step 3) e o catálogo ainda velho:
Run: `node --test tests/app-ios.test.cjs 2>&1 | grep "✖"`
Expected: FAIL em `✖ ícones em dia com o icons.js do site` (catálogo defasado).

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Identidade/Componentes.swift`:

```diff
--- a/app-ios/Custta/Identidade/Componentes.swift
+++ b/app-ios/Custta/Identidade/Componentes.swift
@@ -257,6 +257,8 @@ struct DivisorOu: View {
 /// Etiqueta da fase da obra, nas cores do site (âmbar, azul e verde).
 struct EtiquetaDeFase: View {
     let fase: Fase
+    /// A da pílula da tela da obra: 13 semibold, com 3/12 de recuo (mockup da etapa 2).
+    var grande = false
     @Environment(\.paleta) private var paleta
 
     var body: some View {
@@ -266,14 +268,37 @@ struct EtiquetaDeFase: View {
         case .vendida: (.positivo, .positivoFundo)
         }
         Text(fase.rotulo)
-            .font(.caption.weight(.semibold))
+            .font(grande ? .footnote.weight(.semibold) : .caption.weight(.semibold))
             .foregroundStyle(paleta.cor(texto))
-            .padding(.horizontal, 8)
-            .padding(.vertical, 1)
+            .padding(.horizontal, grande ? 12 : 8)
+            .padding(.vertical, grande ? 3 : 1)
             .background(paleta.cor(fundo), in: .capsule)
     }
 }
 
+/// Dinheiro numa linha só, encolhendo até a metade para caber (mockup da etapa 2, letra máxima): um valor quebrado em
+/// duas linhas se lê errado. Os outros textos crescem e quebram. Algarismos tabulares, na cor do texto.
+struct ValorEmDinheiro: View {
+    let texto: String
+    let fonte: Font
+    @Environment(\.paleta) private var paleta
+
+    var body: some View {
+        Text(texto)
+            .font(fonte)
+            .monospacedDigit()
+            .foregroundStyle(paleta.cor(.texto))
+            .lineLimit(1)
+            .minimumScaleFactor(0.5)
+    }
+}
+
+/// O ícone de um tópico no catálogo; o de um tópico que o app não tem (um nome de ícone que o site ainda não usava) cai
+/// no "etiqueta", como o tópico desconhecido do site.
+func iconeDoCatalogo(_ nome: String) -> String {
+    UIImage(named: "Icones/\(nome)") != nil ? "Icones/\(nome)" : "Icones/etiqueta"
+}
+
 /// Barra fina de progresso: degradê da marca, ou âmbar quando pede atenção.
 struct BarraDeProgresso: View {
     let fracao: Double
@@ -343,3 +368,24 @@ extension View {
     /// A borda de rolagem suave da tela; `abas` liga a de baixo, sob a cápsula de abas.
     func bordaDeRolagem(abas: Bool) -> some View { modifier(BordaDeRolagem(abas: abas)) }
 }
+
+extension View {
+    /// Símbolo que não é texto (as setas). O laudo de leitura mede palavras: o apagador de texto apagava também o traço
+    /// fino do símbolo, que virava uma "palavra" de nota errada. Em Debug, com `-custta.semSimbolos`, o símbolo some dos
+    /// dois prints; o contraste dele (3:1, de figura) fica com a auditoria do Xcode, com superfícies sólidas.
+    func foraDoLaudo() -> some View { modifier(ForaDoLaudo()) }
+}
+
+private struct ForaDoLaudo: ViewModifier {
+    #if DEBUG
+    @AppStorage("custta.semSimbolos") private var semSimbolos = false
+    #endif
+
+    func body(content: Content) -> some View {
+        #if DEBUG
+        content.opacity(semSimbolos ? 0 : 1)
+        #else
+        content
+        #endif
+    }
+}
```

Em `scripts/icones-app-ios.mjs`:

```diff
--- a/scripts/icones-app-ios.mjs
+++ b/scripts/icones-app-ios.mjs
@@ -14,8 +14,12 @@ const require = createRequire(import.meta.url);
 const { ICONES } = require('../icons.js');
 const PASTA = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../app-ios/Custta/Assets.xcassets/Icones');
 
-/** Ícones que as telas usam: abas, fases da obra, sair, olho da senha e a seta da dica. */
-export const USADOS = ['predio', 'engrenagem', 'sair', 'guindaste', 'casa', 'check', 'olho', 'olhoFechado', 'setaBaixo'];
+/** Ícones que as telas usam: abas, fases da obra, sair, olho da senha e a seta da dica; na etapa 2, os dos 21 tópicos
+    (TOPICOS do calc.js) e o "etiqueta" dos tópicos próprios, o calendário do "A vencer", o cartão do pagamento, o lápis
+    de editar, o acordo da venda, o voltar das fases e as notas da obra sem gastos. */
+export const USADOS = ['predio', 'engrenagem', 'sair', 'guindaste', 'casa', 'check', 'olho', 'olhoFechado', 'setaBaixo',
+  'mapa', 'documento', 'tijolos', 'pa', 'vergalhao', 'raio', 'gota', 'porta', 'ladrilho', 'rolo', 'piscina', 'arvore', 'capacete',
+  'caixa', 'etiqueta', 'calendario', 'cartao', 'lapis', 'acordo', 'voltar', 'notas'];
 
 const info = { author: 'xcode', version: 1 };
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/icones-app-ios.mjs
```


- [ ] **Step 4: Ver passar**

Run: `node --test tests/app-ios.test.cjs 2>&1 | grep -E "^ℹ (pass|fail)"` e `xcodebuild build-for-testing "${XB[@]}"`.
Expected: `ℹ pass 33`, `ℹ fail 0`; `** TEST BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Assets.xcassets \
  app-ios/Custta/Identidade/Componentes.swift \
  scripts/icones-app-ios.mjs \
  tests/app-ios.test.cjs
git commit -m "feat: ícones dos tópicos e peças da tela da obra" -m "Os ícones dos 21 tópicos e os da tela da obra entram no catálogo pelo script, iguais aos do icons.js. Os componentes ganham a etiqueta grande da fase, o dinheiro numa linha que encolhe para caber, o ícone com reserva para tópico desconhecido e a marca que tira os símbolos soltos do laudo de leitura."
```

### Task 15: Tela da obra só leitura, com a lista por mês e o "A vencer"

A parte 1 do mockup. Obras ganha o `NavigationStack(path:)` com o caminho morando no `PrincipalView` (sobrevive à troca de aba, como o plano da etapa 1 previu) e a seta ">" de volta nas linhas. A tela da obra: título grande com halo (30%, para fechar a leitura na maior letra), pílula de vidro da fase e do tempo (recuo de 18 pt, como os cartões), indicadores na opção A, "Lançamentos N", "A vencer" fechado no alto e um cartão de vidro por mês (`CartaoDaLista`: vidro como fundo à parte). O título pequeno entra na barra quando o grande sai de baixo dela e sai enquanto a pílula de sincronização aparece; mora num objeto próprio, para a rolagem não refazer a tela inteira. A obra que some (apagada em outro aparelho) volta para Obras; aberta antes de os dados chegarem, mostra o carregando. Os dados de exemplo ganham a obra do mockup (46 lançamentos em dias contados a partir de hoje), para os testes e o laudo verem os números aprovados.

**Files:**
- Modify: `app-ios/Custta/Falsos/TransporteFalsoApp.swift`
- Create: `app-ios/Custta/Falsos/VitrineDaObra.swift`
- Modify: `app-ios/Custta/Identidade/Aurora.swift`
- Modify: `app-ios/Custta/Identidade/Paleta.swift`
- Create: `app-ios/Custta/Telas/ObraView.swift`
- Modify: `app-ios/Custta/Telas/ObrasView.swift`
- Create: `app-ios/Custta/Telas/PecasDaObra.swift`
- Modify: `app-ios/Custta/Telas/PrincipalView.swift`
- Test (alterar): `app-ios/CusttaTests/DadosDeExemploTests.swift`
- Test (alterar): `app-ios/CusttaUITests/Abrir.swift`
- Test (alterar): `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`
- Test (criar): `app-ios/CusttaUITests/ObraUITests.swift`
- Modify: `scripts/cores-app-ios.mjs`
- Gerado: cores em `app-ios/Custta/Assets.xcassets/{Esmeralda,Azul}/` (`node scripts/cores-app-ios.mjs`)

**Interfaces:**
- Consumes: Tarefas 13 e 14; `CartaoDeEstado`, `IndicadorDeSincronizacao`, `.superficie`, `.bordaDeRolagem`, `.pausaOFundoAoRolar` (etapa 1).
- Produces: `enum RotaDeObras { case obra(String) }`; `ObrasView(caminho:)`; `PrincipalView.caminhoInicial` (em Debug, `CUSTTA_ABRIR=obra:<id>` abre a obra direto); `ObraView(id:caminho:)`; `CartaoDaLista`, `CartaoDoMes`, `CartaoDoAVencer`, `LinhaDeGastoView`, `TituloPequenoDaBarra`; `HaloDoTitulo.naObra`; nos testes de tela, `abrirApp(conta:dados:rede:leitura:limpeza:abrir:marca:argumentos:)`, `rolarAte(_:)` e `voltarPelaBorda()`. Identificadores: `obra-<id>`, `tituloDaObra`, `faseDaObra`, `indicadorTotal`, `indicadorCorrigido`, `indicadorAPagar`, `indicadorVenda`, `lancamentos`, `aVencer`, `cartaoAVencer`, `mes-<AAAA-MM>`, `gasto-<id>`, `obraSemGastos`, `tituloPequenoDaBarra`.

- [ ] **Step 1: Escrever os testes de tela e os números da obra do mockup**

Em `app-ios/CusttaTests/DadosDeExemploTests.swift`:

```diff
--- a/app-ios/CusttaTests/DadosDeExemploTests.swift
+++ b/app-ios/CusttaTests/DadosDeExemploTests.swift
@@ -21,8 +21,17 @@ struct DadosDeExemploTests {
         #expect(obras.map(\.fase.rotulo) == ["Em construção", "Pronta · à venda", "Vendida"])
         #expect(obras.map { fmtMeses(mesesDeObra($0, hoje: iso)) } == ["14 meses", "23 meses", "18 meses"])
         #expect(obras.map { moedaCurta(totalBruto($0)) } == ["R$ 842 mil", "R$ 1,38 mi", "R$ 976 mil"])
-        #expect(obras.map { moedaCurta(totalCorrigido($0, taxa: 1, hoje: iso)) } == ["R$ 928 mil", "R$ 1,65 mi", "R$ 1,12 mi"])
+        #expect(obras.map { moedaCurta(totalCorrigido($0, taxa: 1, hoje: iso)) } == ["R$ 927 mil", "R$ 1,65 mi", "R$ 1,12 mi"])
         #expect(orcamentoObra(obras[0]).map(textoOrcamentoNaLista) == "70% do orçamento")
+        // a tela da obra do mockup da etapa 2 (parte1.html)
+        let casa = obras[0]
+        let indicadores = indicadoresDaObra(casa, taxa: 1, hoje: iso)
+        #expect(indicadores.totalGasto == "R$\u{a0}842.317,45" && indicadores.etiquetaDoTotal == "46 lançamentos")
+        #expect(indicadores.corrigido == "R$\u{a0}926.847,69")
+        #expect(indicadores.aPagar == "R$\u{a0}13.250,00" && indicadores.etiquetaDoAPagar == "3 vencimentos")
+        #expect(indicadores.venda == .estimada(valor: "R$\u{a0}1.450.000,00", nota: "R$ 4,8 mil/m² · 300 m²"))
+        let lista = listaDaObra(casa, hoje: iso)
+        #expect(lista.aVencer?.quantidade == 13 && lista.aVencer?.total == 65_500)
         #expect(orcamentoObra(obras[1]) == nil && orcamentoObra(obras[2]) == nil)
     }
 }
```

Em `app-ios/CusttaUITests/Abrir.swift`:

```diff
--- a/app-ios/CusttaUITests/Abrir.swift
+++ b/app-ios/CusttaUITests/Abrir.swift
@@ -1,11 +1,13 @@
 import XCTest
 
-/// Abre o app com os serviços falsos (Custta/Falsos). Nada de rede nem de Firebase.
+/// Abre o app com os serviços falsos (Custta/Falsos). Nada de rede nem de Firebase. `abrir: "obra:v1"` já abre a obra.
 @MainActor
 func abrirApp(conta: String = "nenhuma", dados: String = "exemplo", rede: String? = nil, leitura: String? = nil,
-              limpeza: String? = nil, argumentos: [String] = []) -> XCUIApplication {
+              limpeza: String? = nil, abrir: String? = nil, marca: String? = nil, argumentos: [String] = []) -> XCUIApplication {
     let app = XCUIApplication()
     var ambiente = ["CUSTTA_SERVICOS": "falsos", "CUSTTA_CONTA": conta, "CUSTTA_DADOS": dados]
+    if let abrir { ambiente["CUSTTA_ABRIR"] = abrir }
+    if let marca { ambiente["CUSTTA_MARCA"] = marca }
     if let rede { ambiente["CUSTTA_REDE"] = rede }
     if let leitura { ambiente["CUSTTA_LEITURA"] = leitura }
     if let limpeza { ambiente["CUSTTA_LIMPEZA"] = limpeza }
@@ -19,6 +21,25 @@ extension XCUIApplication {
     /// Elemento por identificador, de qualquer tipo (linha de lista, seção, texto).
     func elemento(_ id: String) -> XCUIElement { descendants(matching: .any).matching(identifier: id).firstMatch }
 
+    /// Rola aos poucos até o elemento ficar à vista acima da cápsula de abas: o que passa por baixo dela não recebe o
+    /// toque, e o `isHittable` do XCUITest não sabe disso (o toque cai na aba). O arrasto termina parado, sem impulso:
+    /// um toque com a lista ainda deslizando só a para e não chega ao botão.
+    func rolarAte(_ elemento: XCUIElement, tentativas: Int = 12) {
+        let capsula = buttons["aba-obras"]
+        let limite = (capsula.exists ? capsula.frame.minY : frame.maxY) - 16
+        for _ in 0..<tentativas where !(elemento.exists && elemento.isHittable && elemento.frame.maxY < limite) {
+            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
+                .press(forDuration: 0.05, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)),
+                       withVelocity: .slow, thenHoldForDuration: 0.3)
+        }
+    }
+
+    /// Volta pelo gesto da borda esquerda, como o polegar (o XCUITest não tem "voltar" do sistema).
+    func voltarPelaBorda() {
+        let borda = coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
+        borda.press(forDuration: 0.05, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)))
+    }
+
     /// Troca de aba pela cápsula de abas (aba-obras, aba-ajustes).
     func abrirAba(_ aba: String) {
         let botao = buttons["aba-\(aba)"]
```

Em `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -14,7 +14,7 @@ import UIKit
 final class LeituraNoVidroUITests: XCTestCase {
     /// Fundo parado no pior momento: Reduzir movimento (globo em 1,2 e logo pronto) e a aurora no pior ponto
     /// da deriva inteira, que também cobre o quadro em que ela para com Reduzir movimento.
-    private let piorMomento = ["-custta.reduzirMovimento", "YES", "-custta.auroraPiorCaso", "YES"]
+    private let piorMomento = ["-custta.reduzirMovimento", "YES", "-custta.auroraPiorCaso", "YES", "-custta.semSimbolos", "YES"]
     private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
     private let quatroCombos = [("escuro", "esmeralda"), ("claro", "esmeralda"), ("escuro", "azul"), ("claro", "azul")]
     private static let portao = 4.5
```

Criar `app-ios/CusttaUITests/ObraUITests.swift`:

```swift
import XCTest

/* A tela da obra (etapa 2, PR 1), com os dados da vitrine (a obra do mockup aprovado: 46 lançamentos, 13 a vencer):
   entrar pela lista e voltar pelo círculo e pela borda; o caminho que sobrevive à troca de aba; os indicadores com os
   números do mockup; o "A vencer" fechado que abre e fecha; e a obra sem gastos. */
@MainActor
final class ObraUITests: XCTestCase {
    func testEntrarPelaListaEVoltarPeloCirculo() {
        let app = abrirApp(conta: "senha", dados: "vitrine")
        let obra = app.elemento("obra-v1")
        XCTAssertTrue(obra.waitForExistence(timeout: 10))
        obra.tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "a obra abriu")
        XCTAssertTrue(app.buttons["aba-obras"].exists, "a cápsula de abas fica fixa durante o push")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.elemento("obra-v1").waitForExistence(timeout: 5), "voltou para Obras")
    }

    func testVoltarPelaBorda() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.voltarPelaBorda()
        XCTAssertTrue(app.elemento("obra-v1").waitForExistence(timeout: 5), "a borda esquerda volta para Obras")
    }

    func testAObraAbertaSobreviveATrocaDeAba() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        app.abrirAba("obras")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "volta para a obra que estava aberta")
    }

    func testIndicadoresComOsNumerosDoMockup() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        let total = app.elemento("indicadorTotal")
        XCTAssertTrue(total.label.contains("R$\u{a0}842.317,45") && total.label.contains("46 lançamentos"), total.label)
        XCTAssertTrue(app.elemento("indicadorCorrigido").label.contains("R$\u{a0}926.847,69"))
        let aPagar = app.elemento("indicadorAPagar").label
        XCTAssertTrue(aPagar.contains("R$\u{a0}13.250,00") && aPagar.contains("3 vencimentos"), aPagar)
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.450.000,00"))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
    }

    func testAVencerFechadoAbreEFecha() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        let aVencer = app.elemento("aVencer")
        XCTAssertTrue(aVencer.waitForExistence(timeout: 10))
        app.rolarAte(aVencer)
        XCTAssertEqual(aVencer.value as? String, "fechado")
        XCTAssertFalse(app.elemento("gasto-g037").exists, "as parcelas futuras não aparecem com o grupo fechado")
        aVencer.tap()
        XCTAssertTrue(app.elemento("gasto-g039").waitForExistence(timeout: 5), "aberto, mostra o próximo vencimento")
        XCTAssertEqual(aVencer.value as? String, "aberto")
        app.rolarAte(aVencer)
        aVencer.tap()
        XCTAssertTrue(app.elemento("gasto-g039").waitForNonExistence(timeout: 5), "fechado de novo, as parcelas somem")
        XCTAssertEqual(aVencer.value as? String, "fechado")
    }

    func testLinhaDoGastoComORotuloDoMockup() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        let cimento = app.elemento("gasto-g027")
        app.rolarAte(cimento)
        XCTAssertTrue(cimento.waitForExistence(timeout: 5))
        XCTAssertTrue(cimento.label.hasPrefix("Cimento CP-II, 120 sacos. Materiais básicos, Pix, "), cimento.label)
        XCTAssertEqual(cimento.value as? String, "R$\u{a0}4.980,00")
    }

    func testObraSemGastos() {
        let app = abrirApp(conta: "senha", dados: "exemplo", abrir: "obra:o3")
        XCTAssertTrue(app.elemento("obraSemGastos").waitForExistence(timeout: 10))
        XCTAssertTrue(app.elemento("indicadorTotal").label.contains("sem gastos"))
    }
}
```


- [ ] **Step 2: Ver falhar**

Run: `xcodebuild build-for-testing "${XB[@]}"` e `xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/ObraUITests -only-testing:CusttaTests/DadosDeExemploTests`
Expected: FAIL: `testEntrarPelaListaEVoltarPeloCirculo` em "a obra abriu" (o cartão da obra ainda não navega) e `DadosDeExemploTests` nos números da vitrine.

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Falsos/TransporteFalsoApp.swift`:

```diff
--- a/app-ios/Custta/Falsos/TransporteFalsoApp.swift
+++ b/app-ios/Custta/Falsos/TransporteFalsoApp.swift
@@ -74,7 +74,8 @@ enum DadosDeExemplo {
 
     /// As três obras do mockup aprovado (Casa Alphaville, Sobrado Granja Viana e Casa Tamboré 4), com as
     /// datas contadas a partir de hoje: a lista mostra sempre os números do mockup (14 meses, R$ 842 mil,
-    /// R$ 928 mil corrigido, 70% do orçamento…), para comparar o simulador com ele lado a lado.
+    /// R$ 927 mil corrigido, 70% do orçamento…), para comparar o simulador com ele lado a lado. A Casa
+    /// Alphaville tem os 46 lançamentos da tela da obra do mockup da etapa 2 (VitrineDaObra.swift).
     static func vitrine(hoje: Date = .now) -> ValorJSON {
         let calendario = Calendar(identifier: .gregorian)
         func data(_ mesesAtras: Int) -> ValorJSON {
@@ -94,9 +95,9 @@ enum DadosDeExemplo {
         }
         return .objeto([
             "obras": .lista([
-                obra("v1", "Casa Alphaville", "construcao", inicio: 14,
-                     gastos: [(14, 92_000), (13, 150_000), (11, 230_000), (8, 190_000), (5, 180_000)],
-                     extra: ["orcamento": .objeto(["modo": .texto("total"), "total": .numero(1_200_000)])]),
+                obra("v1", "Casa Alphaville", "construcao", inicio: 14, gastos: [],
+                     extra: ["orcamento": .objeto(["modo": .texto("total"), "total": .numero(1_200_000)]),
+                             "valorEstimadoVenda": .numero(1_450_000), "areaM2": .numero(300), "gastos": gastosDaVitrine(hoje: hoje)]),
                 obra("v2", "Sobrado Granja Viana", "pronta", inicio: 23,
                      gastos: [(23, 250_000), (21, 330_000), (18, 310_000), (15, 280_000), (12, 210_000)]),
                 obra("v3", "Casa Tamboré 4", "vendida", inicio: 20,
```

Criar `app-ios/Custta/Falsos/VitrineDaObra.swift`:

```swift
#if DEBUG
import Foundation
import CusttaNucleo

/* A obra do mockup aprovado da etapa 2 (parte1.html, de 12/10/2026): a Casa Alphaville com os 46 lançamentos, contados em
   dias a partir de hoje para a tela mostrar os números do mockup em qualquer dia: R$ 842.317,45 gastos, R$ 926.847,69
   corrigido, 3 vencimentos em 30 dias (R$ 13.250,00), 13 gastos a vencer e as compras no cartão em 10x, 6x e 3x. */
extension DadosDeExemplo {
    typealias GastoDaVitrine = (id: String, dias: Int, valor: Double, topico: String, descricao: String, pagamento: String,
                                parcela: (n: Int, de: Int, grupo: String)?)

    static let gastosDaCasaAlphaville: [GastoDaVitrine] = [
        ("g001", -424, 199847.85, "terreno", "Entrada do terreno", "pix", nil),
        ("g002", -418, 18500, "projeto", "Projeto arquitetônico", "pix", nil),
        ("g003", -410, 4380.5, "projeto", "Taxas e alvará da prefeitura", "pix", nil),
        ("g004", -397, 120000, "terreno", "Parcela final do terreno", "pix", nil),
        ("g005", -389, 9800, "maoobra", "Limpeza e terraplanagem", "pix", nil),
        ("g006", -371, 64200, "fundacao", "Sapatas e baldrames", "pix", nil),
        ("g007", -355, 21450.8, "ferragem", "Vergalhão 10 mm e estribos", "pix", nil),
        ("g008", -334, 14320, "matbasicos", "Cimento, areia e brita", "pix", nil),
        ("g009", -319, 12600, "maoobra", "Quinzena da equipe da fundação", "pix", nil),
        ("g010", -307, 38900, "estrutura", "Concreto usinado da laje do térreo", "pix", nil),
        ("g011", -297, 17240.6, "ferragem", "Ferragem da laje", "pix", nil),
        ("g012", -271, 11870, "alvenaria", "Tijolos cerâmicos de 8 furos", "pix", nil),
        ("g013", -255, 16400, "maoobra", "Pedreiro e ajudantes", "pix", nil),
        ("g014", -238, 52300, "estrutura", "Pilares e vigas do pavimento superior", "pix", nil),
        ("g015", -215, 27650, "telhado", "Madeiramento do telhado", "pix", nil),
        ("g016", -201, 18420.3, "telhado", "Telhas de cerâmica", "pix", nil),
        ("g017", -187, 6890.4, "eletrica", "Eletrodutos e caixas", "pix", nil),
        ("g018", -171, 9740, "hidraulica", "Tubulação de água e esgoto", "pix", nil),
        ("g019", -152, 13200, "maoobra", "Eletricista e encanador", "pix", nil),
        ("g020", -136, 8350.9, "matbasicos", "Argamassa e reboco", "pix", nil),
        ("g021", -124, 15200, "revest", "Contrapiso e regularização", "pix", nil),
        ("g028", -99, 6150, "revest", "Porcelanato 60×60", "cartao", (1, 10, "vpor")),
        ("g022", -83, 11480.2, "eletrica", "Fios, cabos e quadro de luz", "pix", nil),
        ("g029", -68, 6150, "revest", "Porcelanato 60×60", "cartao", (2, 10, "vpor")),
        ("g023", -55, 8400, "maoobra", "Quinzena do pedreiro", "pix", nil),
        ("g030", -37, 6150, "revest", "Porcelanato 60×60", "cartao", (3, 10, "vpor")),
        ("g038", -27, 4800, "esquadrias", "Janelas e portas de alumínio", "cartao", (1, 6, "vjan")),
        ("g024", -18, 7320.5, "hidraulica", "Louças e metais", "pix", nil),
        ("g025", -10, 3275.4, "eletrica", "Luminárias e tomadas", "pix", nil),
        ("g031", -7, 6150, "revest", "Porcelanato 60×60", "cartao", (4, 10, "vpor")),
        ("g044", -6, 2300, "pintura", "Tinta acrílica", "cartao", (1, 3, "vtin")),
        ("g026", -4, 8400, "maoobra", "Quinzena do pedreiro", "pix", nil),
        ("g027", -2, 4980, "matbasicos", "Cimento CP-II, 120 sacos", "pix", nil),
        ("g039", 3, 4800, "esquadrias", "Janelas e portas de alumínio", "cartao", (2, 6, "vjan")),
        ("g032", 24, 6150, "revest", "Porcelanato 60×60", "cartao", (5, 10, "vpor")),
        ("g045", 25, 2300, "pintura", "Tinta acrílica", "cartao", (2, 3, "vtin")),
        ("g040", 34, 4800, "esquadrias", "Janelas e portas de alumínio", "cartao", (3, 6, "vjan")),
        ("g033", 54, 6150, "revest", "Porcelanato 60×60", "cartao", (6, 10, "vpor")),
        ("g046", 55, 2300, "pintura", "Tinta acrílica", "cartao", (3, 3, "vtin")),
        ("g041", 64, 4800, "esquadrias", "Janelas e portas de alumínio", "cartao", (4, 6, "vjan")),
        ("g034", 85, 6150, "revest", "Porcelanato 60×60", "cartao", (7, 10, "vpor")),
        ("g042", 95, 4800, "esquadrias", "Janelas e portas de alumínio", "cartao", (5, 6, "vjan")),
        ("g035", 116, 6150, "revest", "Porcelanato 60×60", "cartao", (8, 10, "vpor")),
        ("g043", 126, 4800, "esquadrias", "Janelas e portas de alumínio", "cartao", (6, 6, "vjan")),
        ("g036", 144, 6150, "revest", "Porcelanato 60×60", "cartao", (9, 10, "vpor")),
        ("g037", 175, 6150, "revest", "Porcelanato 60×60", "cartao", (10, 10, "vpor")),    ]

    /// Os gastos da Casa Alphaville do mockup, com as datas contadas de hoje; as parcelas com o grupo e as condições da
    /// compra (sem juros), como o site grava.
    static func gastosDaVitrine(hoje: Date) -> ValorJSON {
        let calendario = Calendar(identifier: .gregorian)
        let compras = Dictionary(grouping: gastosDaCasaAlphaville.filter { $0.parcela != nil }) { $0.parcela!.grupo }
        return .lista(gastosDaCasaAlphaville.map { g in
            var campos: [String: ValorJSON] = [
                "id": .texto(g.id), "valor": .numero(g.valor), "topico": .texto(g.topico), "descricao": .texto(g.descricao),
                "data": .texto(dataLocalISO(calendario.date(byAdding: .day, value: g.dias, to: hoje) ?? hoje, fuso: .current)),
                "pagamento": .texto(g.pagamento),
            ]
            if let p = g.parcela {
                let total = (compras[p.grupo] ?? []).reduce(0) { $0 + $1.valor }
                campos["grupoId"] = .texto(p.grupo)
                campos["parcela"] = .objeto(["n": .numero(Double(p.n)), "de": .numero(Double(p.de))])
                campos["jurosCartao"] = .objeto(["taxaMensal": .numero(0), "valorCompra": .numero(total), "nParcelas": .numero(Double(p.de)),
                                                 "totalCompra": .numero(total), "jurosCompra": .numero(0)])
            }
            return .objeto(campos)
        })
    }
}
#endif
```

Em `app-ios/Custta/Identidade/Aurora.swift`:

```diff
--- a/app-ios/Custta/Identidade/Aurora.swift
+++ b/app-ios/Custta/Identidade/Aurora.swift
@@ -190,6 +190,8 @@ struct HaloDoTitulo: View {
     /// halo, o título "Obras", branco do sistema, ficava em 4,41:1, e a versão em Ajustes, em 4,42:1).
     nonisolated static let naEntrada = 0.50
     nonisolated static let naBarra = 0.05
+    /// Atrás do nome da obra (etapa 2): o nome quebra em várias linhas e, na letra grande, chega à parte clara da aurora.
+    nonisolated static let naObra = 0.30
     let grande: Bool
     var opacidade = HaloDoTitulo.naEntrada
     @Environment(\.paleta) private var paleta
```

Em `app-ios/Custta/Identidade/Paleta.swift`:

```diff
--- a/app-ios/Custta/Identidade/Paleta.swift
+++ b/app-ios/Custta/Identidade/Paleta.swift
@@ -62,6 +62,9 @@ enum Token: String, CaseIterable, Sendable {
     case globoOceano = "GloboOceano"
     case globoHalo = "GloboHalo"
     case globoAro = "GloboAro"
+    /// O lucro e o prejuízo da obra vendida sobre o vidro (o Positivo e o Negativo não fechavam 4,5:1 com a aurora atrás).
+    case positivoNoVidro = "PositivoNoVidro"
+    case negativoNoVidro = "NegativoNoVidro"
 }
 
 struct Paleta: Equatable, Sendable {
```

Criar `app-ios/Custta/Telas/ObraView.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* A tela da obra (mockup aprovado da etapa 2, parte 1): o nome no título grande, a pílula da fase e do tempo, os
   indicadores na opção A, a pílula "Lançamentos" e a lista de gastos por mês, com o "A vencer" fechado no alto. Entra
   pelo push do NavigationStack de Obras e volta pelo círculo e pela borda (sistema). A obra que some (apagada em outro
   aparelho) fecha a tela, como o site volta ao Início. */
struct ObraView: View {
    let id: String
    @Binding var caminho: [RotaDeObras]
    @Environment(ModeloApp.self) private var modelo
    @State private var aVencerAberto = false
    /// O título pequeno mora num objeto próprio, lido só pela peça da barra: ao cruzar o limite no meio da rolagem, só
    /// ela se refaz, e não a tela inteira (lista, indicadores e cartões).
    @State private var barra = BarraDaObra()
    #if DEBUG
    /// Laudo de leitura e conferência visual: a tela parada numa rolagem dada, em pt (o mesmo gancho de Obras).
    @AppStorage("custta.rolagem") private var rolagemFixa = -1.0
    @State private var posicao = ScrollPosition(edge: .top)
    #endif

    var body: some View {
        let estado = modelo.sincronizador.estado
        if let obra = estado.obras.first(where: { $0.id == id }) {
            conteudo(obra, taxa: estado.config.taxaMensal, topicos: mapaDeTopicos(estado.config.topicosProprios))
        } else if !modelo.sincronizador.dadosCarregados {
            ProgressView()                               // aberta antes de os dados chegarem (o caminho sobrevive à troca de conta)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Color.clear                                  // a obra sumiu (apagada em outro aparelho): volta para Obras
                .onAppear { caminho.removeAll { $0 == .obra(id) } }
        }
    }

    private func conteudo(_ obra: Obra, taxa: Double, topicos: [String: Topico]) -> some View {
        let hoje = dataLocalISO(.now, fuso: .current)
        let lista = listaDaObra(obra, hoje: hoje)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                TituloDaObra(nome: obra.nome)
                PilulaDaFase(obra: obra, hoje: hoje)
                IndicadoresDaObraView(indicadores: indicadoresDaObra(obra, taxa: taxa, hoje: hoje))
                    .padding(.bottom, 14)
                PilulaDeLancamentos(quantidade: obra.gastos.count)
                if obra.gastos.isEmpty {
                    CartaoDeEstado(titulo: "Nenhum gasto lançado.", texto: "Toque no + para lançar o primeiro.",
                                   identificador: "obraSemGastos", icone: "Icones/notas") { EmptyView() }
                } else {
                    if let aVencer = lista.aVencer {
                        CartaoDoAVencer(grupo: aVencer, aberto: $aVencerAberto, topicos: topicos)
                    }
                    ForEach(lista.meses) { mes in CartaoDoMes(mes: mes, topicos: topicos) }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        // O título pequeno entra na barra quando o grande sai de baixo dela (como o título grande do sistema).
        .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 44 } action: { _, saiu in
            withAnimation(.easeOut(duration: 0.2)) { barra.tituloVisivel = saiu }
        }
        #if DEBUG
        .scrollPosition($posicao)
        .task {
            guard rolagemFixa >= 0 else { return }
            try? await Task.sleep(for: .milliseconds(300))
            posicao.scrollTo(y: rolagemFixa)
        }
        #endif
        .pausaOFundoAoRolar()
        .bordaDeRolagem(abas: true)
        .containerBackground(.clear, for: .navigation)
        .navigationTitle(obra.nome)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: obra.nome) }
            ToolbarItem(placement: .topBarTrailing) { IndicadorDeSincronizacao() }
                .sharedBackgroundVisibility(.hidden)
        }
    }
}

/// Se o título pequeno aparece na barra da obra.
@MainActor @Observable
final class BarraDaObra {
    var tituloVisivel = false
}

/// O título pequeno só existe depois que o grande sai de baixo da barra, e sai enquanto a pílula de sincronização aparece
/// (na barra não cabem os dois com o voltar e o lápis). Fora disso, nem fica invisível na árvore; vazio, a barra
/// mostraria o título do sistema (branco) por cima do título grande.
struct TituloDaBarraDaObra: View {
    let barra: BarraDaObra
    let nome: String
    @Environment(ModeloApp.self) private var modelo

    var body: some View {
        if barra.tituloVisivel && indicador(modelo.sincronizador.estadoSinc) == nil {
            TituloPequenoDaBarra(nome: nome).transition(.opacity)
        } else {
            Color.clear.frame(width: 1, height: 1).accessibilityHidden(true)
        }
    }
}

/// O nome da obra na barra, depois de rolar: uma linha só, até 236 pt, como o título pequeno do sistema (que corta o nome
/// longo em vez de empurrar o voltar e o lápis). Na letra grande para perto de 22 pt (mockup) e mostra o Visualizador de
/// Conteúdo Grande, como a cápsula de abas.
struct TituloPequenoDaBarra: View {
    let nome: String
    @Environment(\.paleta) private var paleta

    var body: some View {
        Text(nome)
            .font(.headline)
            .foregroundStyle(paleta.cor(.texto))
            .lineLimit(1)
            .frame(maxWidth: 236)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityAddTraits(.isHeader)
            .accessibilityShowsLargeContentViewer()
            .accessibilityIdentifier("tituloPequenoDaBarra")
    }
}

/// O "A vencer": fechado, uma linha; aberto, o mesmo cartão com os meses futuros dentro.
struct CartaoDoAVencer: View {
    let grupo: GrupoAVencer
    @Binding var aberto: Bool
    let topicos: [String: Topico]
    @Environment(\.opcoes) private var opcoes
    @Environment(\.paleta) private var paleta

    var body: some View {
        CartaoDaLista {
            LinhaDoAVencer(grupo: grupo, aberto: aberto)
                .onTapGesture(perform: alternar)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("A vencer, \(moeda(grupo.total)), \(grupo.resumo.replacingOccurrences(of: " · ", with: ", "))")
                .accessibilityAddTraits(.isButton)
                .accessibilityValue(aberto ? "aberto" : "fechado")
                .accessibilityHint(aberto ? "Fecha os gastos a vencer" : "Mostra os gastos a vencer")
                .accessibilityAction { alternar() }
                .accessibilityIdentifier("aVencer")
            if aberto {
                ForEach(grupo.meses) { mes in
                    CabecalhoDoMes(mes: mes)
                    linhas(mes)
                }
                .padding(.bottom, 6)
            }
        }
    }

    private func alternar() {
        if opcoes.reduzirMovimento { aberto.toggle() } else { withAnimation(.snappy) { aberto.toggle() } }
    }

    @ViewBuilder private func linhas(_ mes: MesDeGastos) -> some View {
        ForEach(Array(mes.gastos.enumerated()), id: \.element.id) { i, gasto in
            if i > 0 { LinhaFina().padding(.leading, 67) }
            LinhaDeGastoView(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos))
        }
    }
}

/// Um mês: o cartão de vidro com o cabeçalho e as linhas sólidas dentro.
struct CartaoDoMes: View {
    let mes: MesDeGastos
    let topicos: [String: Topico]
    @Environment(\.paleta) private var paleta

    var body: some View {
        CartaoDaLista {
            CabecalhoDoMes(mes: mes)
            ForEach(Array(mes.gastos.enumerated()), id: \.element.id) { i, gasto in
                if i > 0 { LinhaFina().padding(.leading, 67) }
                LinhaDeGastoView(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos))
            }
            Color.clear.frame(height: 6)
        }
    }
}
```

Em `app-ios/Custta/Telas/ObrasView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObrasView.swift
+++ b/app-ios/Custta/Telas/ObrasView.swift
@@ -1,10 +1,16 @@
 import SwiftUI
 import CusttaNucleo
 
-/* Obras, só leitura na etapa 1: aviso de e-mail não confirmado, "N obras", um cartão de vidro por obra
-   (fase, meses, orçamento e total gasto, na ordem e com os totais do site) e o comparativo entre obras.
-   Antes de carregar: carregando, ou o erro de leitura explicando que nada foi alterado. */
+/// Para onde se vai dentro de Obras (o caminho do NavigationStack, que mora no PrincipalView).
+enum RotaDeObras: Hashable, Sendable {
+    case obra(String)
+}
+
+/* Obras: aviso de e-mail não confirmado, "N obras", um cartão de vidro por obra (fase, meses, orçamento e total
+   gasto, na ordem e com os totais do site), que abre a obra, e o comparativo entre obras. Antes de carregar:
+   carregando, ou o erro de leitura explicando que nada foi alterado. */
 struct ObrasView: View {
+    @Binding var caminho: [RotaDeObras]
     @Environment(ModeloApp.self) private var modelo
     @State private var confirmarSaida = false
     #if DEBUG
@@ -17,7 +23,7 @@ struct ObrasView: View {
         let sinc = modelo.sincronizador
         let obras = obrasOrdenadas(sinc.estado.obras)
         let hoje = dataLocalISO(.now, fuso: .current)
-        NavigationStack {
+        NavigationStack(path: $caminho) {
             ScrollView {
                 VStack(alignment: .leading, spacing: 10) {
                     if let usuario = modelo.usuario, usuario.precisaConfirmarEmail {
@@ -41,7 +47,10 @@ struct ObrasView: View {
                                        identificador: "obrasVazio") { EmptyView() }
                     } else {
                         ContagemDeObras(quantidade: obras.count)
-                        ForEach(obras, id: \.id) { obra in CartaoDeObra(obra: obra, hoje: hoje) }
+                        ForEach(obras, id: \.id) { obra in
+                            NavigationLink(value: RotaDeObras.obra(obra.id)) { CartaoDeObra(obra: obra, hoje: hoje) }
+                                .buttonStyle(.plain)
+                        }
                         let comparativo = comparativoEntreObras(obras, taxa: sinc.estado.config.taxaMensal, hoje: hoje)
                         if !comparativo.isEmpty { PainelComparativo(linhas: comparativo).padding(.top, 2) }
                     }
@@ -65,6 +74,11 @@ struct ObrasView: View {
             .navigationTitle("Obras")
             .toolbar { BarraDoApp(confirmarSaida: $confirmarSaida) }
             .confirmaSaida($confirmarSaida)
+            .navigationDestination(for: RotaDeObras.self) { rota in
+                switch rota {
+                case .obra(let id): ObraView(id: id, caminho: $caminho)
+                }
+            }
         }
     }
 }
@@ -88,11 +102,9 @@ struct ContagemDeObras: View {
     }
 }
 
-/// Uma obra: ícone da fase, nome, etiqueta, meses, orçamento e total gasto. O valor de acessibilidade
-/// ("Em construção · 14 meses, total gasto R$ …, 70% do orçamento") é contrato com a conferência cruzada.
-/// Sem a seta ">" do mockup até a etapa 2 (decisão do Giovani em 08/10): tocar na obra ainda não abre
-/// nada. A seta volta com a tela da obra, no fim da linha e, na letra grande, ao lado do nome
-/// (`chevron.right` na cor secundária do vidro), e a margem da direita volta a 14 pt.
+/// Uma obra: ícone da fase, nome, etiqueta, meses, orçamento, total gasto e a seta ">" de quem abre (no fim da
+/// linha e, na letra grande, ao lado do nome). O valor de acessibilidade ("Em construção · 14 meses, total gasto
+/// R$ …, 70% do orçamento") é contrato com a conferência cruzada.
 struct CartaoDeObra: View {
     let obra: Obra
     let hoje: String
@@ -108,7 +120,7 @@ struct CartaoDeObra: View {
         Group {
             if tamanho.isAccessibilitySize {
                 VStack(alignment: .leading, spacing: 6) {
-                    nome
+                    HStack(alignment: .firstTextBaseline) { nome; Spacer(minLength: 8); seta }
                     EtiquetaDeFase(fase: obra.fase)
                     tempo(meses)
                     if let orcamento { linhaDoOrcamento(orcamento) }
@@ -134,10 +146,12 @@ struct CartaoDeObra: View {
                         .font(.body.weight(.semibold))
                         .monospacedDigit()
                         .foregroundStyle(paleta.cor(.texto))
+                    seta
                 }
             }
         }
-        .padding(.horizontal, 16)
+        .padding(.leading, 16)
+        .padding(.trailing, 14)
         .padding(.vertical, 12)
         .frame(maxWidth: .infinity, alignment: .leading)
         .superficie(.conteudo, em: .rect(cornerRadius: 22))
@@ -151,6 +165,14 @@ struct CartaoDeObra: View {
         Text(obra.nome).font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
     }
 
+    private var seta: some View {
+        Image(systemName: "chevron.right")
+            .font(.footnote.weight(.semibold))
+            .foregroundStyle(paleta.cor(vidro.secundario))
+            .accessibilityHidden(true)
+            .foraDoLaudo()
+    }
+
     private func tempo(_ meses: String) -> some View {
         Text("· \(meses)").font(.footnote).foregroundStyle(paleta.cor(vidro.secundario))
     }
@@ -288,13 +310,15 @@ struct CartaoDeEstado<Acao: View>: View {
     let titulo: String
     let texto: String?
     let identificador: String
+    /// O ícone do alto: o guindaste nas Obras; as notas na obra sem gastos (mockup da etapa 2).
+    var icone = "Icones/guindaste"
     @ViewBuilder let acao: () -> Acao
     @Environment(\.paleta) private var paleta
     @Environment(\.vidro) private var vidro
 
     var body: some View {
         VStack(spacing: 8) {
-            Image(decorative: "Icones/guindaste")
+            Image(decorative: icone)
                 .resizable().frame(width: 36, height: 36)
                 .foregroundStyle(paleta.cor(.texto))
                 .accessibilityHidden(true)
```

Criar `app-ios/Custta/Telas/PecasDaObra.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* As peças da tela da obra (mockup aprovado da etapa 2, parte 1): o título com o nome, a pílula da fase e do tempo,
   os indicadores na opção A, a pílula "Lançamentos", o "A vencer", o cabeçalho do mês e a linha do gasto. Medidas do
   mockup: margem de 20, cartões de raio 24 e recuo interno de 18 em tudo, para o texto de cima e o de baixo começarem
   na mesma vertical. Nenhum token novo; nunca vidro dentro de vidro (o que fica dentro de um cartão é sólido). */

/// O nome da obra no título grande, em quantas linhas precisar (o título grande do sistema corta nome longo), com o
/// halo atrás do bloco inteiro no escuro, como o título grande de Obras.
struct TituloDaObra: View {
    let nome: String
    @Environment(\.paleta) private var paleta

    var body: some View {
        Text(nome)
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(paleta.cor(.texto))
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("tituloDaObra")    // antes do halo: com ele, o quadro do VoiceOver ia até a borda do halo
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { HaloDoTitulo(grande: false, opacidade: HaloDoTitulo.naObra) }
    }
}

/// Fase e tempo numa pílula de vidro: um cartão baixo de raio 24 com a etiqueta da fase e "começou em… · N meses".
struct PilulaDaFase: View {
    let obra: Obra
    let hoje: String
    @Environment(\.paleta) private var paleta

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EtiquetaDeFase(fase: obra.fase, grande: true)
            Text(textoDoInicio(obra, hoje: hoje))
                .font(.subheadline)
                .foregroundStyle(paleta.cor(.texto))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("faseDaObra")
    }
}

/// Uma etiqueta pequena colorida ao lado do rótulo de um indicador ("46 lançamentos", "3 vencimentos", "estimativa").
struct EtiquetaDoIndicador: View {
    enum Cor { case marca, alerta, positivo, neutro }
    let texto: String
    let cor: Cor
    @Environment(\.paleta) private var paleta

    var body: some View {
        let (frente, fundo): (Token, Token) = switch cor {
        case .marca: (.fantasmaTexto, .fantasmaFundo)
        case .alerta: (.alertaEtiqueta, .alertaFundo)
        case .positivo: (.positivo, .positivoFundo)
        case .neutro: (.textoSecundario, .campo)
        }
        Text(texto)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(paleta.cor(frente))
            .fixedSize(horizontal: false, vertical: true)    // na letra grande, quebra em vez de cortar
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
            .background(paleta.cor(fundo), in: .capsule)
    }
}

/// Os indicadores na opção A do mockup: o total gasto em destaque e um cartão com Corrigido, A pagar (a folha e a seta são
/// da etapa 3) e Venda. Os textos e as contas são os do site (indicadoresDaObra).
struct IndicadoresDaObraView: View {
    let indicadores: IndicadoresDaObra
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    /// "N lançamentos" na marca; "sem gastos" neutra, como o chip cinza do mockup.
    private var corDoTotal: EtiquetaDoIndicador.Cor { indicadores.etiquetaDoTotal == "sem gastos" ? .neutro : .marca }

    var body: some View {
        VStack(spacing: 10) {
            heroi
            VStack(spacing: 0) {
                linha(rotulo: "Corrigido pelo banco", etiqueta: nil, valor: indicadores.corrigido, nota: indicadores.notaDoCorrigido,
                      identificador: "indicadorCorrigido")
                LinhaFina().padding(.leading, 18)
                // Sem a seta e sem o "Ver" até a etapa 3, que traz a folha do A pagar: a seta prometeria navegação (regra
                // do Giovani de 08/10 para a seta das obras).
                linha(rotulo: "A pagar · 30 dias", etiqueta: (indicadores.etiquetaDoAPagar, .alerta), valor: indicadores.aPagar,
                      nota: "Parcelas e gastos futuros", identificador: "indicadorAPagar")
                LinhaFina().padding(.leading, 18)
                venda
            }
            .superficie(.conteudo, em: .rect(cornerRadius: 24))
        }
    }

    private var heroi: some View {
        VStack(alignment: .leading, spacing: 6) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    rotulo("Total gasto")
                    Spacer(minLength: 8)
                    EtiquetaDoIndicador(texto: indicadores.etiquetaDoTotal, cor: corDoTotal)
                }
                VStack(alignment: .leading, spacing: 6) {
                    rotulo("Total gasto")
                    EtiquetaDoIndicador(texto: indicadores.etiquetaDoTotal, cor: corDoTotal)
                }
            }
            ValorEmDinheiro(texto: indicadores.totalGasto, fonte: .largeTitle.weight(.bold))
            Text("bruto, sem correção").font(.subheadline).foregroundStyle(paleta.cor(vidro.secundario))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("indicadorTotal")
    }

    @ViewBuilder private var venda: some View {
        switch indicadores.venda {
        case .vendida(let valor, let etiqueta, let nota, let lucroPositivo):
            linha(rotulo: "Venda", etiqueta: (etiqueta, .positivo), valor: valor, nota: nota, identificador: "indicadorVenda",
                  corDaNota: lucroPositivo ? .positivoNoVidro : .negativoNoVidro)
        case .estimada(let valor, let nota):
            linha(rotulo: "Venda estimada", etiqueta: ("estimativa", .positivo), valor: valor, nota: nota, identificador: "indicadorVenda")
        case .semEstimativa:
            linha(rotulo: "Venda estimada", etiqueta: nil, valor: "—", nota: "Toque no lápis para informar o valor",
                  identificador: "indicadorVenda")
        }
    }

    /// Na letra grande, o rótulo ao lado da etiqueta recebia a altura de uma linha e cortava ("A pagar · 3…"): a altura
    /// ideal para a largura dada resolve.
    private func rotulo(_ texto: String) -> some View {
        Text(texto).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto)).fixedSize(horizontal: false, vertical: true)
    }

    private func linha(rotulo texto: String, etiqueta: (String, EtiquetaDoIndicador.Cor)?, valor: String, nota: String,
                       identificador: String, corDaNota: Token? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    rotulo(texto)
                    Spacer(minLength: 8)
                    if let etiqueta { EtiquetaDoIndicador(texto: etiqueta.0, cor: etiqueta.1) }
                }
                VStack(alignment: .leading, spacing: 6) {
                    rotulo(texto)
                    if let etiqueta { EtiquetaDoIndicador(texto: etiqueta.0, cor: etiqueta.1) }
                }
            }
            ValorEmDinheiro(texto: valor, fonte: .title2.weight(.bold))
            Text(nota).font(.subheadline).foregroundStyle(paleta.cor(corDaNota ?? vidro.secundario))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 13, leading: 18, bottom: 13, trailing: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identificador)
    }
}

/// "Lançamentos 46": a pílula de vidro antes da lista.
struct PilulaDeLancamentos: View {
    let quantidade: Int
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        HStack(spacing: 6) {
            Text("Lançamentos").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
            Text("\(quantidade)").font(.body).foregroundStyle(paleta.cor(vidro.secundario))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .superficie(.conteudo, em: .capsule)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("lancamentos")
    }
}

/// O cabeçalho de um mês dentro do cartão: o nome e o total; sem espaço, o total quebra para baixo.
struct CabecalhoDoMes: View {
    let mes: MesDeGastos
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack { titulo; Spacer(minLength: 8); total }
            VStack(alignment: .leading, spacing: 2) { titulo; total }
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(paleta.cor(vidro.secundario))
        .padding(EdgeInsets(top: 12, leading: 18, bottom: 6, trailing: 18))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("mes-\(mes.id)")
    }

    private var titulo: some View { Text(mes.titulo) }
    private var total: some View { Text(moeda(mes.total)).monospacedDigit() }
}

/// A linha do "A vencer", fechado ou aberto: ícone de calendário, título, total, chevron e o resumo.
struct LinhaDoAVencer: View {
    let grupo: GrupoAVencer
    let aberto: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho
    @ScaledMetric(relativeTo: .body) private var icone: CGFloat = 38

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !tamanho.isAccessibilitySize {
                Image(decorative: "Icones/calendario")
                    .resizable().frame(width: icone * 0.55, height: icone * 0.55)
                    .foregroundStyle(paleta.cor(.alertaEtiqueta))
                    .frame(width: icone, height: icone)
                    .background(paleta.cor(.alertaFundo), in: .rect(cornerRadius: 11))
            }
            VStack(alignment: .leading, spacing: 2) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("A vencer").font(.body.weight(.semibold))
                        Spacer(minLength: 8)
                        ValorEmDinheiro(texto: moeda(grupo.total), fonte: .body.weight(.semibold))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("A vencer").font(.body.weight(.semibold))
                        ValorEmDinheiro(texto: moeda(grupo.total), fonte: .body.weight(.semibold))
                    }
                }
                .foregroundStyle(paleta.cor(.texto))
                Text(grupo.resumo).font(.footnote).foregroundStyle(paleta.cor(vidro.secundario))
            }
            Image(systemName: aberto ? "chevron.down" : "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(paleta.cor(vidro.secundario))
                .accessibilityHidden(true)
                .foraDoLaudo()
        }
        .padding(EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 16))
        .contentShape(.rect)
    }
}

/// A linha de um gasto: ícone do tópico (sólido), título e valor, e embaixo o tópico, o pagamento e a data. O valor vem
/// sem vermelho, só com o "−"; "Pix" e "Cartão" por extenso. Na letra grande, cada informação numa linha, sem o ícone e
/// sem os "·". O VoiceOver lê "Cimento CP-II, 120 sacos. Materiais básicos, Pix, 10 de outubro de 2026" e o valor.
struct LinhaDeGastoView: View {
    let gasto: Gasto
    let linha: LinhaDeGasto
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        Group {
            if tamanho.isAccessibilitySize { empilhada } else { normal }
        }
        .padding(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18))
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(linha.rotulo)
        .accessibilityValue(linha.valorFalado)
        .accessibilityIdentifier("gasto-\(gasto.id)")
    }

    private var normal: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(decorative: iconeDoCatalogo(linha.icone))
                .resizable().frame(width: 20, height: 20)
                .foregroundStyle(paleta.cor(.marca))
                .frame(width: 38, height: 38)
                .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    titulo
                    Spacer(minLength: 0)
                    valor
                }
                meta
            }
        }
    }

    private var empilhada: some View {
        VStack(alignment: .leading, spacing: 4) {
            titulo
            valor
            if let topico = linha.topico { detalhe(topico) }
            if let pagamento = linha.pagamento { detalhe(pagamento) }
            detalhe(linha.data)
        }
    }

    private var titulo: some View {
        Text(linha.titulo).font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
    }

    private var valor: some View { ValorEmDinheiro(texto: linha.valor, fonte: .body.weight(.semibold)) }

    /// Tópico · forma de pagamento com o ícone · data, num texto só (quebra sozinho; um "·" solto era um texto de 4 pt
    /// que a auditoria de contraste do Xcode não conseguia medir). Os ícones do pagamento são os do sistema, que crescem
    /// com a letra dentro do texto: o raio do Pix ("bolt") e o cartão ("creditcard").
    private var meta: some View {
        var partes: [Text] = []
        if let topico = linha.topico { partes.append(Text(topico)) }
        if let pagamento = linha.pagamento {
            partes.append(Text("\(Image(systemName: pagamento == "Pix" ? "bolt" : "creditcard")) \(pagamento)"))
        }
        partes.append(Text(linha.data))
        let junto = partes.dropFirst().reduce(partes[0]) { Text("\($0) · \($1)") }
        return junto.font(.footnote).foregroundStyle(paleta.cor(vidro.secundario))
    }

    private func detalhe(_ texto: String) -> some View {
        Text(texto).font(.footnote).foregroundStyle(paleta.cor(vidro.secundario))
    }
}

/// A linha fina entre as linhas de um cartão (hairline), na cor do token Linha.
struct LinhaFina: View {
    @Environment(\.paleta) private var paleta
    @Environment(\.displayScale) private var escala

    var body: some View {
        Rectangle().fill(paleta.cor(.linha)).frame(height: 1 / escala).accessibilityHidden(true)
    }
}

/// Cartão de vidro da lista da obra (um mês, o "A vencer"): o conteúdo recortado no raio do cartão (a linha arrastada não
/// passa do canto) e o vidro atrás, como fundo à parte. Com o vidro aplicado ao conteúdo (`.superficie` direto), no iOS 27
/// o cartão que cresce (o "A vencer" abrindo, um gasto entrando no mês) levava junto o quadro de acessibilidade da primeira
/// linha: o cabeçalho passava a responder pelo cartão inteiro, no VoiceOver e no XCUITest. Com o vidro de fundo, não.
struct CartaoDaLista<Conteudo: View>: View {
    @ViewBuilder let conteudo: () -> Conteudo

    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: conteudo)
            .clipShape(.rect(cornerRadius: 24, style: .continuous))
            .background { Color.clear.superficie(.conteudo, em: .rect(cornerRadius: 24, style: .continuous)) }
    }
}
```

Em `app-ios/Custta/Telas/PrincipalView.swift`:

```diff
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -1,19 +1,20 @@
 import SwiftUI
 import CusttaNucleo
 
-/* O app por dentro: as abas da etapa 1 (Obras e Ajustes; "Vale a pena?" chega na etapa 4 e o + na 2)
-   com a cápsula de abas própria, e a barra de cada tela com a sincronização e o sair do topo, em vidro,
-   como no site. Sair pede confirmação pelo alerta do sistema (decisão do Giovani). Só a aba escolhida
-   fica montada: o TabView do sistema pinta um fundo opaco por trás das abas no iOS 26 (esconderia a
-   aurora), e uma aba só escondida continuaria na árvore do VoiceOver pela barra de navegação. O que
-   precisar sobreviver à troca de aba (o caminho dentro de Obras, na etapa 2) mora aqui, no PrincipalView. */
+/* O app por dentro: as abas (Obras e Ajustes; "Vale a pena?" chega na etapa 4) com a cápsula de abas
+   própria, e a barra de cada tela com a sincronização e o sair do topo, em vidro, como no site. Sair pede
+   confirmação pelo alerta do sistema (decisão do Giovani). Só a aba escolhida fica montada: o TabView do
+   sistema pinta um fundo opaco por trás das abas no iOS 26 (esconderia a aurora), e uma aba só escondida
+   continuaria na árvore do VoiceOver pela barra de navegação. Por isso o caminho dentro de Obras mora aqui:
+   quem vai a Ajustes e volta encontra a obra que tinha aberto. */
 struct PrincipalView: View {
     @State private var aba = Aba.obras
+    @State private var caminhoDeObras = PrincipalView.caminhoInicial
 
     var body: some View {
         Group {
             switch aba {
-            case .obras: ObrasView()
+            case .obras: ObrasView(caminho: $caminhoDeObras)
             case .ajustes: AjustesView()
             }
         }
@@ -26,6 +27,19 @@ struct PrincipalView: View {
     }
 }
 
+extension PrincipalView {
+    /// O caminho com que Obras abre: vazio; em Debug, `CUSTTA_ABRIR=obra:<id>` abre a obra direto (testes de tela, laudo
+    /// de leitura e conferência visual).
+    static var caminhoInicial: [RotaDeObras] {
+        #if DEBUG
+        if let abrir = ProcessInfo.processInfo.environment["CUSTTA_ABRIR"], abrir.hasPrefix("obra:") {
+            return [.obra(String(abrir.dropFirst(5)))]
+        }
+        #endif
+        return []
+    }
+}
+
 /// Sincronização e sair, no canto da barra de Obras e de Ajustes.
 struct BarraDoApp: ToolbarContent {
     @Binding var confirmarSaida: Bool
```

Em `scripts/cores-app-ios.mjs`:

```diff
--- a/scripts/cores-app-ios.mjs
+++ b/scripts/cores-app-ios.mjs
@@ -70,6 +70,10 @@ export const CORES = {
     GloboOceano: ['#0F7C6A', '#0F7C6A'],
     GloboHalo: ['#14B39A', '#14B39A'],
     GloboAro: ['#3AD17E', '#3AD17E'],
+    // O lucro e o prejuízo da obra vendida sobre o vidro (etapa 2): o Positivo e o Negativo do site ficavam entre 2,5 e
+    // 3,7:1 com a aurora atrás (laudo de leitura); estes passam de 4,5:1 no pior pixel nos quatro combos.
+    PositivoNoVidro: ['#8CF0BC', '#084A27'],
+    NegativoNoVidro: ['#FFC4CE', '#8A1538'],
   },
   Azul: {
     Fundo: ['#070C18', '#EEF2F9'],
@@ -120,6 +124,8 @@ export const CORES = {
     GloboOceano: ['#4E72E0', '#4E72E0'],
     GloboHalo: ['#3A64F5', '#3A64F5'],
     GloboAro: ['#648CFF', '#648CFF'],
+    PositivoNoVidro: ['#86EFAC', '#084A27'],
+    NegativoNoVidro: ['#FFC4CE', '#8A1538'],
   },
 };
 
@@ -130,6 +136,7 @@ export const PARES_SOLIDOS = [
   ['Texto', 'Superficie'], ['SecundarioSolido', 'Superficie'], ['LinkNoVidro', 'Superficie'], ['ErroNoVidro', 'Superficie'],
   ['Texto', 'Campo'], ['SobreMarca', 'Marca'], ['SobreTinta', 'Tinta'], ['FantasmaTexto', 'FantasmaFundo'],
   ['Alerta', 'AlertaFundo'], ['AlertaEtiqueta', 'AlertaFundo'], ['Informacao', 'InformacaoFundo'], ['Positivo', 'PositivoFundo'], ['GoogleTexto', 'GoogleFundo'],
+  ['TextoSecundario', 'Campo'], ['PositivoNoVidro', 'Superficie'], ['NegativoNoVidro', 'Superficie'],
 ];
 
 const info = { author: 'xcode', version: 1 };
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/cores-app-ios.mjs
```


- [ ] **Step 4: Ver passar**

Run: o mesmo do Step 2 e `-only-testing:CusttaUITests/ObrasUITests`.
Expected: os 7 de `ObraUITests`, `DadosDeExemploTests` e `ObrasUITests` verdes.

- [ ] **Step 5: Conferência visual (Verniz)**

No simulador, `CUSTTA_SERVICOS=falsos CUSTTA_CONTA=senha CUSTTA_DADOS=vitrine CUSTTA_ABRIR=obra:v1`, lado a lado com `parte1-obra-topo.png`, `parte1-obra-rolada.png` (rolagem 640), `parte1-obra-meio-da-lista.png` e `parte1-obra-a-vencer-aberto.png`, nos quatro combos e na maior letra. Diferenças anotadas no PR.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Assets.xcassets \
  app-ios/Custta/Falsos/TransporteFalsoApp.swift \
  app-ios/Custta/Falsos/VitrineDaObra.swift \
  app-ios/Custta/Identidade/Aurora.swift \
  app-ios/Custta/Identidade/Paleta.swift \
  app-ios/Custta/Telas/ObraView.swift \
  app-ios/Custta/Telas/ObrasView.swift \
  app-ios/Custta/Telas/PecasDaObra.swift \
  app-ios/Custta/Telas/PrincipalView.swift \
  app-ios/CusttaTests/DadosDeExemploTests.swift \
  app-ios/CusttaUITests/Abrir.swift \
  app-ios/CusttaUITests/LeituraNoVidroUITests.swift \
  app-ios/CusttaUITests/ObraUITests.swift \
  scripts/cores-app-ios.mjs
git commit -m "feat: tela da obra só leitura, com a lista por mês e o \"A vencer\"" -m "Tocar numa obra abre a tela da obra pelo push do NavigationStack, com o caminho no PrincipalView para sobreviver à troca de aba. A tela segue a parte 1 do mockup: título grande, pílula da fase, indicadores na opção A, A vencer fechado no alto e um cartão de vidro por mês com o total. O vidro do cartão vai como fundo à parte: aplicado ao conteúdo que cresce, o iOS 27 esticava o quadro de acessibilidade da primeira linha. Os dados de exemplo ganham a obra do mockup."
```

### Task 16: Leitura sobre o vidro e auditoria da tela da obra

O laudo de leitura ganha as cenas da obra (topo e lista rolada nos quatro combos, a obra vendida nos quatro combos, a maior letra e o Aumentar contraste) e a varredura da lista rolando em seis alturas, nas duas peles, sem e com Aumentar contraste (na CI, duas alturas); as auditorias do Xcode passam pela obra na maior letra e nos quatro combos com superfícies sólidas. Com a dose da Tarefa 10, tudo passa: foi medido no protótipo antes e depois.

**Files:**
- Test (alterar): `app-ios/CusttaUITests/AuditoriaUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`

**Interfaces:**
- Consumes: Tarefas 10 e 15; os ganchos `-custta.rolagem`, `-custta.semSimbolos`, `-custta.auroraPiorCaso`.
- Produces: cena do laudo com `dados`, `abrir` e `rolada`; `testLeituraDaObra`, `testLeituraDaObraRolando`, `testObraNoMaiorTamanho`, `testContrasteDaObraNosQuatroCombos`; o título pequeno da barra fora da auditoria de tipo dinâmico (para perto de 22 pt, como o do sistema, com o Visualizador de Conteúdo Grande); `CUSTTA_VARREDURA=curta` na CI.

- [ ] **Step 1: Escrever as cenas e as auditorias**

Em `app-ios/CusttaUITests/AuditoriaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -4,8 +4,9 @@ import UIKit
 /* Requisitos verificáveis do spec, seção 8, com a cara do PWA: no maior tamanho de letra de
    acessibilidade nada corta, todo controle tem rótulo e alvo de 44 pt; o contraste das cores passa nos
    quatro combos e sobre a aurora parada (no quadro inicial e nos extremos da deriva). Não crescem com a
-   letra, por decisão do mockup, a cápsula de abas e o botão do Google: os dois mostram o Visualizador de
-   Conteúdo Grande, e a auditoria de tipo dinâmico os deixa de fora.
+   letra, por decisão do mockup, a cápsula de abas, o botão do Google e o título pequeno da barra da obra
+   (para perto de 22 pt): os três mostram o Visualizador de Conteúdo Grande, e a auditoria de tipo dinâmico
+   os deixa de fora.
 
    Contraste: a auditoria do Xcode não lê fundo de vidro (no simulador do iOS 27 ela reprova até texto
    escuro sobre a pílula sólida do segmentado, e os mesmos textos com tinta de 6% ou de 50%). Aqui as cores
@@ -40,7 +41,9 @@ final class AuditoriaUITests: XCTestCase {
             let fora: Bool
             switch achado.auditType {
             case .dynamicType:
-                fora = elemento.label == "Continuar com o Google"
+                // O título pequeno da barra da obra para perto de 22 pt, como o do sistema (mockup da etapa 2), com o
+                // Visualizador de Conteúdo Grande.
+                fora = elemento.label == "Continuar com o Google" || elemento.identifier == "tituloPequenoDaBarra"
                     || abas.contains { $0.contains(CGPoint(x: elemento.frame.midX, y: elemento.frame.midY)) }
             case .contrast:
                 if elemento.identifier.hasPrefix("aba-") { fora = false }   // o rótulo da própria cápsula
@@ -94,6 +97,14 @@ final class AuditoriaUITests: XCTestCase {
         try auditar(app, tiposDeAuditoria)
     }
 
+    @MainActor func testObraNoMaiorTamanho() throws {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: maiorLetra + parado)
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
+        try auditar(app, tiposDeAuditoria)
+        rolar(app)
+        try auditar(app, tiposDeAuditoria)
+    }
+
     @MainActor func testAjustesNoMaiorTamanho() throws {
         let app = abrirApp(conta: "senha-nao-confirmada", argumentos: maiorLetra + parado)
         app.abrirAba("ajustes")
@@ -193,6 +204,18 @@ final class AuditoriaUITests: XCTestCase {
         }
     }
 
+    /// A tela da obra (etapa 2), no topo e com a lista rolada, nos quatro combos, com superfícies sólidas.
+    @MainActor func testContrasteDaObraNosQuatroCombos() throws {
+        for (tema, pele) in quatroCombos {
+            let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: ["-custta.tema", tema, "-custta.pele", pele] + solido + parado)
+            XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
+            try auditar(app, [.contrast])
+            rolar(app)
+            try auditar(app, [.contrast])
+            app.terminate()
+        }
+    }
+
     /// A deriva move os brilhos da aurora: o título e a dica da entrada são medidos também com a aurora
     /// congelada nos quadros de 13 s e 26 s (os extremos da deriva), no escuro, onde ela é mais clara.
     @MainActor func testContrasteDoTituloComAAuroraEmMovimento() throws {
```

Em `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -36,10 +36,17 @@ final class LeituraNoVidroUITests: XCTestCase {
         let escopo: String
         /// Aba aberta pela cápsula antes do print (Ajustes não tem gancho de abertura).
         var aba: String? = nil
+        /// Dados dos falsos e tela aberta pelo gancho (`obra:v1`, a obra do mockup na vitrine).
+        var dados = "exemplo"
+        var abrir: String? = nil
+        /// Tela rolada: o texto que passa por baixo da barra é borrado pela borda de rolagem e muda quando é apagado, a
+        /// mais de 5 pt das letras; os 140 pt de cima (a borda) ficam de fora, como os de baixo.
+        var rolada = false
     }
 
     @MainActor private func fotografar(_ cena: Cena, textoApagado: Bool) -> (XCUIScreenshot, [CGRect], CGFloat) {
-        let app = abrirApp(conta: cena.conta, argumentos: cena.argumentos + (textoApagado ? ["-custta.textoApagado", cena.escopo] : []))
+        let app = abrirApp(conta: cena.conta, dados: cena.dados, abrir: cena.abrir,
+                           argumentos: cena.argumentos + (textoApagado ? ["-custta.textoApagado", cena.escopo] : []))
         XCTAssertTrue(app.elemento(cena.espera).waitForExistence(timeout: 10), "\(cena.nome): a tela não abriu")
         if let aba = cena.aba {
             app.abrirAba(aba)
@@ -81,10 +88,11 @@ final class LeituraNoVidroUITests: XCTestCase {
         // O indicador de início, como a barra de status, é do sistema e muda entre os prints (aparece ou não, e
         // muda de cor com o que tem por baixo): os 34 pt de baixo ficam de fora em toda cena.
         let indicador = [CGRect(x: 0, y: altura - 34, width: largura, height: 34)]
+        let borda = cena.rolada ? [CGRect(x: 0, y: 0, width: largura, height: 140)] : []
         let palavras = try LaudoDeContraste.medir(normal: Retrato(imagem), semTexto: Retrato(semTexto.image.cgImage!),
                                                   escala: escala, topo: Self.barraDeStatus,
                                                   somenteEm: cena.escopo == "navegacao" ? regiao : nil,
-                                                  ignorar: (cena.escopo == "tudo" ? abaixo : []) + indicador)
+                                                  ignorar: (cena.escopo == "tudo" ? abaixo : []) + indicador + borda)
         XCTAssertFalse(palavras.isEmpty, "\(cena.nome): nenhum texto medido")
         anexar(cena.nome, normal.image, palavras, escala)
         Swift.print(String(format: "leitura | %@ | %d palavras, %d abaixo | pior nota %.2f", cena.nome, palavras.count,
@@ -280,6 +288,55 @@ extension LeituraNoVidroUITests {
         }
         XCTAssertTrue(falhas.isEmpty, "Abaixo de \(Self.portao):1 no Finalizar saída:\n" + falhas.joined(separator: "\n"))
     }
+
+    /// A tela da obra (etapa 2): o topo (título, fase, indicadores) e a lista rolada (o "A vencer" e os cartões dos meses),
+    /// nos quatro combos; mais a maior letra e o Aumentar contraste, no escuro esmeralda.
+    @MainActor func testLeituraDaObra() {
+        var cenas: [Cena] = []
+        for (tema, pele) in quatroCombos {
+            let combo = ["-custta.tema", tema, "-custta.pele", pele] + piorMomento
+            cenas += [
+                Cena(nome: "obra, topo, \(tema), \(pele)", conta: "senha", argumentos: combo, espera: "tituloDaObra", escopo: "tudo",
+                     dados: "vitrine", abrir: "obra:v1"),
+                Cena(nome: "obra, lista, \(tema), \(pele)", conta: "senha", argumentos: combo + ["-custta.rolagem", "640"],
+                     espera: "aVencer", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
+            ]
+        }
+        // A obra vendida: a venda com a nota de lucro (PositivoNoVidro) e a etiqueta "Vendida", nos quatro combos (o
+        // Positivo do site ficava em 2,76:1 no claro azul).
+        for (tema, pele) in quatroCombos {
+            cenas.append(Cena(nome: "obra vendida, \(tema), \(pele)", conta: "senha",
+                              argumentos: ["-custta.tema", tema, "-custta.pele", pele] + piorMomento, espera: "tituloDaObra",
+                              escopo: "tudo", dados: "vitrine", abrir: "obra:v3"))
+        }
+        let escuro = ["-custta.tema", "escuro", "-custta.pele", "esmeralda"] + piorMomento
+        cenas += [
+            Cena(nome: "obra na maior letra", conta: "senha", argumentos: escuro + maiorLetra, espera: "tituloDaObra", escopo: "tudo",
+                 dados: "vitrine", abrir: "obra:v1"),
+            Cena(nome: "obra com Aumentar contraste", conta: "senha", argumentos: escuro + ["-custta.aumentarContraste", "YES", "-custta.rolagem", "640"],
+                 espera: "aVencer", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
+        ]
+        cobrar(cenas)
+    }
+
+    /// A lista da obra rolando, no escuro (onde a dose de vidro decide), sem e com Aumentar contraste, nas duas peles: o pior
+    /// ponto de um cabeçalho de mês ou de uma linha de baixo pode estar fora do quadro de 640 pt. No Mac, seis rolagens; na
+    /// CI, duas.
+    @MainActor func testLeituraDaObraRolando() {
+        let rolagens = ProcessInfo.processInfo.environment["CUSTTA_VARREDURA"] == "curta" ? [400, 900] : [200, 400, 640, 900, 1200, 1500]
+        var cenas: [Cena] = []
+        for (pele, contraste) in [("esmeralda", false), ("azul", false), ("esmeralda", true), ("azul", true)] {
+            for y in rolagens {
+                let argumentos = ["-custta.tema", "escuro", "-custta.pele", pele, "-custta.rolagem", "\(y)"] + piorMomento
+                    + (contraste ? ["-custta.aumentarContraste", "YES"] : [])
+                // Espera o título pequeno da barra: rolada, a lista já soltou o título grande da árvore.
+                cenas.append(Cena(nome: "obra rolando \(y), escuro, \(pele)\(contraste ? ", Aumentar contraste" : "")", conta: "senha",
+                                  argumentos: argumentos, espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "vitrine",
+                                  abrir: "obra:v1", rolada: true))
+            }
+        }
+        cobrar(cenas)
+    }
 }
 
 /* O medidor com imagens sintéticas: sem abrir o app. */
@@ -350,4 +407,5 @@ final class LaudoDeContrasteTests: XCTestCase {
             XCTAssertTrue(erro is LaudoDeContraste.CenaNaoDeterministica)
         }
     }
+
 }
```


- [ ] **Step 2: Ver medir**

Run: `xcodebuild build-for-testing "${XB[@]}"` e `xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaObra -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaObraRolando -only-testing:CusttaUITests/AuditoriaUITests/testObraNoMaiorTamanho -only-testing:CusttaUITests/AuditoriaUITests/testContrasteDaObraNosQuatroCombos`; no Mac, também no Pro Max.
Expected: todas as cenas com "0 abaixo": no 18 Pro, pior 4,56 no topo claro (a etiqueta sólida "estimativa"), 4,87 na lista escura rolada e 5,22 com Aumentar contraste; no Pro Max, 4,93 e 4,63; auditorias sem achado. Para ver o vermelho que motivou a Tarefa 10, volte o `escurecimento` do Transparente a 0,45 e o `secundario` sem o contorno: "obra, lista, escuro, esmeralda" cai a 4,44:1 e "obra com Aumentar contraste" a 4,21:1.

- [ ] **Step 3: Commit**

```bash
git add app-ios/CusttaUITests/AuditoriaUITests.swift \
  app-ios/CusttaUITests/LeituraNoVidroUITests.swift
git commit -m "test: leitura sobre o vidro e auditoria da tela da obra" -m "O laudo de leitura mede a tela da obra no topo, com a lista rolada e a obra vendida nos quatro combos, na maior letra e com Aumentar contraste, mais a lista rolando em seis alturas nas duas peles; as auditorias do Xcode passam por ela. Com a dose nova, nenhuma palavra fica abaixo de 4,5:1 no 18 Pro nem no Pro Max."
```

### Task 17: Conta de teste com as obras exportadas do site

O `scripts/conta-demo.mjs`, que já cria e repovoa a conta de revisão da Apple com a conta de serviço, ganha `--importar <arquivo>`: lê o JSON que o site exporta (Ajustes → Exportar dados), confere o formato e os limites das rules (300 obras, 50 tópicos próprios, tamanho do documento) e grava as obras e a config dele numa conta própria (`--email`). A conta de revisão nunca recebe a cópia, e o arquivo nunca entra no repositório (`.gitignore`).

**Files:**
- Modify: `.gitignore`
- Modify: `scripts/conta-demo.mjs`
- Test (alterar): `tests/conta-demo.test.mjs`

**Interfaces:**
- Consumes: `normaliza`, `LIMITE_OBRAS` (`dados.js`), `tamanhoBlob`, `LIMITE_BLOB` (`calc.js`).
- Produces: `documentoImportado(texto, agora)` e as opções `--importar` e `--email`.

- [ ] **Step 1: Escrever os testes**

Em `tests/conta-demo.test.mjs`:

```diff
--- a/tests/conta-demo.test.mjs
+++ b/tests/conta-demo.test.mjs
@@ -8,7 +8,7 @@ import assert from 'node:assert/strict';
 import { readFileSync } from 'node:fs';
 import path from 'node:path';
 import { fileURLToPath } from 'node:url';
-import { documentoDados, documentoPerfil, lerArgs, EMAIL_PADRAO, SENHA_EMULADOR } from '../scripts/conta-demo.mjs';
+import { documentoDados, documentoImportado, documentoPerfil, lerArgs, EMAIL_PADRAO, SENHA_EMULADOR } from '../scripts/conta-demo.mjs';
 
 const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
 const rules = readFileSync(path.join(RAIZ, 'firestore.rules'), 'utf8');
@@ -84,3 +84,35 @@ test('nenhuma senha de verdade está escrita no script', () => {
   const suspeitas = literais.filter(s => /[A-Z]/.test(s) && /[0-9]/.test(s) && /[^A-Za-z0-9\s./:@_-]/.test(s));
   assert.deepEqual(suspeitas, [], `parece senha escrita no código: ${suspeitas.join(', ')}`);
 });
+
+/* A conta de teste da etapa 2 recebe uma cópia das obras exportadas pelo site. O Admin SDK passa por
+   cima das rules, então o formato é conferido aqui, como no documento de demonstração. */
+const exportado = dados => JSON.stringify({ formato: 'custta', versao: 1, exportadoEm: '2026-10-13T12:00:00.000Z', dados });
+
+test('importar: só obras, config (taxa e tópicos) e _atualizado, normalizados', () => {
+  const doc = documentoImportado(exportado({
+    obras: [{ id: 'o1', nome: 'Casa', dataInicio: '2026-01-01', gastos: [{ id: 'g', valor: '10', data: '2026-01-02' }], campoDoSite: 1 }],
+    config: { taxaMensal: 1.2, topicosCustom: [], tema: 'claro' },
+    chaveSolta: true,
+  }), 1758240000000);
+  assert.deepEqual(Object.keys(doc).sort(), ['_atualizado', 'config', 'obras']);
+  assert.deepEqual(Object.keys(doc.config).sort(), ['taxaMensal', 'topicosCustom']);
+  assert.equal(doc.obras[0].gastos[0].valor, 10, 'normalizado como o app lê');
+  assert.equal(doc.obras[0].campoDoSite, 1, 'campo que o app não conhece fica dentro da obra');
+  assert.equal(doc._atualizado, 1758240000000);
+});
+
+test('importar recusa o que não é arquivo do Custta e o que as rules recusariam', () => {
+  assert.throws(() => documentoImportado('não é json'), /não é JSON/);
+  assert.throws(() => documentoImportado(JSON.stringify({ obras: [] })), /não é um arquivo exportado/);
+  const muitas = Array.from({ length: 301 }, (_, i) => ({ id: `o${i}`, nome: 'O', dataInicio: '2026-01-01', gastos: [] }));
+  assert.throws(() => documentoImportado(exportado({ obras: muitas, config: {} })), /até 300/);
+});
+
+test('importar exige a conta de teste: a de revisão da Apple nunca recebe dados de verdade', () => {
+  assert.throws(() => lerArgs(['--importar', 'x.json']), /conta de teste/);
+  assert.throws(() => lerArgs(['--importar', 'x.json', '--email', EMAIL_PADRAO]), /conta de teste/);
+  assert.throws(() => lerArgs(['--importar', '--email', 'teste@exemplo.com']), /caminho do arquivo/);
+  assert.equal(lerArgs(['--importar', 'x.json', '--email', 'teste@exemplo.com']).importar, 'x.json');
+  assert.equal(lerArgs([]).importar, null);
+});
```


- [ ] **Step 2: Ver falhar**

Run: `node --test tests/conta-demo.test.mjs`
Expected: FAIL com `SyntaxError: The requested module '../scripts/conta-demo.mjs' does not provide an export named 'documentoImportado'`.

- [ ] **Step 3: Implementar**

Em `.gitignore`:

```diff
--- a/.gitignore
+++ b/.gitignore
@@ -17,6 +17,8 @@ notificacoes/node_modules/
 *.pem
 *.key
 vapid-keys.txt
+# Cópia das obras exportada pelo site (Ajustes → Seus dados → Exportar dados completos): dados pessoais, para a conta de teste
+custta-*.json
 
 # Assinatura de app iOS
 *.p8
```

Em `scripts/conta-demo.mjs`:

```diff
--- a/scripts/conta-demo.mjs
+++ b/scripts/conta-demo.mjs
@@ -11,6 +11,14 @@
      node scripts/conta-demo.mjs                              # emulador (padrão, não toca em nada real)
      node scripts/conta-demo.mjs --producao --senha 'SENHA'   # projeto real
      node scripts/conta-demo.mjs --email outro@exemplo.com    # troca o e-mail
+     node scripts/conta-demo.mjs --producao --email teste@exemplo.com --senha 'SENHA' \
+       --importar ~/Downloads/custta-2026-10-13.json          # conta de teste com uma cópia das obras
+
+   --importar lê o arquivo que o site exporta (Ajustes → Seus dados → Exportar dados completos) e grava as obras e a
+   config dele no lugar dos dados de demonstração: é a conta de teste em que o app nativo grava até a
+   conferência da etapa 2 (docs/specs/2026-10-13-app-nativo-etapa2-design.md, "Conta de teste"). O
+   arquivo tem dados pessoais e nunca entra no repositório (o .gitignore barra custta-*.json); a conta
+   de revisão da Apple nunca recebe uma cópia dele.
 
    No emulador nada é preciso além do próprio emulador rodando. Em produção,
    FIREBASE_SERVICE_ACCOUNT precisa ter o JSON da conta de serviço — a mesma
@@ -20,9 +28,15 @@
 
    O script é idempotente: rodar de novo na mesma conta só repõe os dados. */
 'use strict';
+import { readFileSync } from 'node:fs';
+import { createRequire } from 'node:module';
 import { pathToFileURL } from 'node:url';
 import { dadosDemo } from './dados-demo.mjs';
 
+const require = createRequire(import.meta.url);
+const { normaliza, LIMITE_OBRAS } = require('../dados.js');
+const { tamanhoBlob, LIMITE_BLOB } = require('../calc.js');
+
 export const EMAIL_PADRAO = 'revisao.custta@gmail.com';
 export const PROJETO = 'app-construcao-civil';
 
@@ -36,6 +50,23 @@ export function documentoDados(agora = Date.now()){
   return { obras, config, _atualizado: agora };
 }
 
+/* A cópia das obras de um arquivo exportado pelo site ({formato: 'custta', versao: 1, dados}),
+   normalizada como o app lê e cortada ao que as rules aceitam: no topo só obras, config e
+   _atualizado; na config só taxaMensal e topicosCustom; até LIMITE_OBRAS obras; e o tamanho que o
+   cliente aceita gravar. Recusa o que não for um arquivo do Custta em vez de gravar pela metade. */
+export function documentoImportado(texto, agora = Date.now()){
+  let arquivo;
+  try { arquivo = JSON.parse(texto); } catch { throw new Error('--importar: o arquivo não é JSON.'); }
+  if(arquivo?.formato !== 'custta' || arquivo?.versao !== 1 || typeof arquivo?.dados !== 'object' || !arquivo.dados)
+    throw new Error('--importar: não é um arquivo exportado pelo Custta (formato "custta", versão 1).');
+  const { obras, config } = normaliza(arquivo.dados);
+  if(obras.length > LIMITE_OBRAS) throw new Error(`--importar: ${obras.length} obras; as rules aceitam até ${LIMITE_OBRAS}.`);
+  if(config.topicosCustom.length > 50) throw new Error('--importar: mais de 50 tópicos próprios; as rules aceitam até 50.');
+  const doc = { obras, config: { taxaMensal: config.taxaMensal, topicosCustom: config.topicosCustom }, _atualizado: agora };
+  if(tamanhoBlob({ obras: doc.obras, config: doc.config }) > LIMITE_BLOB) throw new Error('--importar: os dados passam do limite de tamanho do documento.');
+  return doc;
+}
+
 /* `perfis` aceita só email, criado e tz. `plano` fica de fora de propósito:
    nenhum cliente grava esse campo, é o que reserva espaço pra cobrar depois. */
 export function documentoPerfil(email, agora = new Date()){
@@ -49,13 +80,22 @@ export function documentoPerfil(email, agora = new Date()){
 export const SENHA_EMULADOR = 'emulador-local';
 
 export function lerArgs(argv, env = process.env){
+  // Outra opção logo depois do nome (`--importar --email x`) quer dizer valor vazio, e não o nome da opção.
   const valor = nome => {
     const i = argv.indexOf('--' + nome);
-    return i >= 0 ? (argv[i + 1] ?? '') : null;
+    if(i < 0) return null;
+    const v = argv[i + 1] ?? '';
+    return v.startsWith('--') ? '' : v;
   };
   const producao = argv.includes('--producao');
   const senha = valor('senha') || env.CONTA_DEMO_SENHA || (producao ? '' : SENHA_EMULADOR);
-  return { producao, email: valor('email') || EMAIL_PADRAO, senha };
+  const email = valor('email') || EMAIL_PADRAO;
+  const importar = valor('importar');
+  /* A conta de revisão da Apple mostra o app a quem revisa: os dados de verdade de alguém
+     nunca vão para ela. A cópia vai para uma conta de teste com e-mail próprio. */
+  if(importar !== null && (!importar || email === EMAIL_PADRAO))
+    throw new Error('--importar precisa do caminho do arquivo e de --email com a conta de teste: a conta de revisão da Apple só recebe os dados de demonstração.');
+  return { producao, email, senha, importar };
 }
 
 /* Cria o usuário, ou reaproveita o que já existe repondo a senha — ela precisa
@@ -108,7 +148,7 @@ async function principal(opcoes){
   const uid = await garantirUsuario(getAuth(), opcoes);
   const db = getFirestore();
 
-  const dados = documentoDados();
+  const dados = opcoes.importar ? documentoImportado(readFileSync(opcoes.importar, 'utf8')) : documentoDados();
   await db.doc(`dados/${uid}`).set(dados);
   console.log(`dados/${uid}: ${dados.obras.length} obras, ${dados.obras.reduce((s, o) => s + o.gastos.length, 0)} gastos`);
 
@@ -116,6 +156,11 @@ async function principal(opcoes){
   console.log(`perfis/${uid}: pronto`);
 
   console.log('');
+  if(opcoes.importar){
+    console.log(`Conta de teste pronta: ${opcoes.email}, com a cópia de ${opcoes.importar}.`);
+    if(!opcoes.producao) console.log('\n(isto rodou no EMULADOR — para valer, rode com --producao)');
+    return;
+  }
   console.log('Para colar em App Store Connect → Informações da versão → Login obrigatório:');
   console.log(`  E-mail: ${opcoes.email}`);
   /* A senha de produção veio de quem rodou o comando, que já a conhece.
```


- [ ] **Step 4: Ver passar**

Run: `node --test tests/conta-demo.test.mjs` e, com o emulador do Firestore no ar, `node scripts/conta-demo.mjs --email teste@exemplo.com --importar <um JSON exportado>`.
Expected: `ℹ fail 0`; a conta criada no emulador com as obras do arquivo.

- [ ] **Step 5: Commit**

```bash
git add .gitignore \
  scripts/conta-demo.mjs \
  tests/conta-demo.test.mjs
git commit -m "feat: conta de teste com as obras exportadas do site" -m "O script da conta de revisão ganha a opção de importar o JSON que o site exporta para uma conta própria, conferindo o formato e os limites das rules. É a conta em que o app nativo grava até a conferência da etapa 2. A conta de revisão da Apple nunca recebe a cópia, e o arquivo, com dados pessoais, fica fora do repositório."
```

### Task 18: Checklist do aparelho da etapa 2 e o CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`
- Create: `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`

- [ ] **Step 1: Escrever**

Em `CLAUDE.md`:

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -100,7 +100,7 @@ Adicionar uma chave de topo em `db` **quebra as escritas em produção** se as r
 
 ### App nativo (app-ios/)
 
-App em SwiftUI que vai substituir o Capacitor (spec `docs/specs/2026-10-06-app-nativo-design.md`, planos `docs/plans/2026-10-06-app-nativo-*`, mockup aprovado da etapa 1 em `~/Documents/custta-mockups/nativo/etapa1/final.html`, com a borda de rolagem do `final-v2.html` e as decisões de 10/10 no `final-v4.html`). O `app-ios/Custta.xcodeproj` é escrito à mão no formato do Xcode 16 (pastas sincronizadas): arquivo novo dentro de `Custta/`, `CusttaTests/` ou `CusttaUITests/` entra no alvo sozinho; não deixe o Xcode subir o `objectVersion` (77), porque a CI usa o Xcode 26 (`tests/app-ios.test.cjs` barra). As regras moram no pacote `app-ios/CusttaNucleo`, puro e conferido contra os vetores do site; o app tem a identidade em `Custta/Identidade/` (tokens de cor e de vidro, aurora, globo, título escrito à mão, superfícies de vidro e cápsula de abas, escritos uma vez e reusados), as telas, o `ModeloApp` e a camada fina do Firebase em `Custta/Dados/`. A cara é a do PWA: cores só por tokens (`scripts/cores-app-ios.mjs`; rode o script depois de mudar), ícones do `icons.js` (`scripts/icones-app-ios.mjs`), logo e globo iguais aos do site (as guardas comparam), toda superfície por `.superficie(_:em:)` com a dose de vidro da tela (`VidroTokens`), nunca vidro dentro de vidro, a mesma borda de rolagem em toda tela que rola (`.bordaDeRolagem(abas:)`), e animação própria só olhando o Reduzir movimento. O vidro do iOS não acompanha escala nem transformação 3D, e a auditoria de contraste do Xcode não lê vidro: as cores são auditadas com superfícies sólidas (e os pares de texto sobre sólido, em Node, pelo `PARES_SOLIDOS`), e a leitura sobre o vidro de verdade é medida pelo laudo de leitura (`LeituraNoVidroUITests`: dois prints do mesmo quadro, com e sem o texto, e 4,5:1 no pior ponto de cada palavra; portão no Mac e na CI, que mede a lista sob a cápsula em menos rolagens; o texto que o sistema desenha, como os botões dos alertas, é medido contra o fundo em volta das letras, e as exceções têm nome no teste). No escuro, uma camada do tom do fundo sob o vidro do conteúdo (`VidroTokens.escurecimento`) e o globo mais fundo dentro do app fecham a leitura; mexer na dose de vidro, na aurora, no globo ou na borda pede o laudo de novo. Nenhum build vai ao TestFlight com o laudo reprovando no Mac. Pacotes Swift: só firebase-ios-sdk e GoogleSignIn-iOS, em versão exata, com o `Package.resolved` versionado (para atualizar, botão "resolver de novo" do workflow `app-ios`); a Roboto Medium do botão do Google é a única fonte embutida, travada por SHA-256. Em Debug o app aceita `CUSTTA_SERVICOS=falsos` (telas e testes de tela; dados `vitrine` por padrão, as obras do mockup, e `exemplo` nos testes) e `CUSTTA_EMULADORES=1` (emuladores, com uma chave falsa, para um pedido que escape deles ser recusado pela produção); o Release não tem nenhum dos dois. Os emuladores rodam num FirebaseApp próprio (`Composicao.nomeDoAppDosEmuladores`), para a sessão deles nunca ocupar a vaga da produção no keychain. Nenhum teste monta a composição com rede, e cada agente roda os testes no seu simulador (`CUSTTA_SIMULADOR=<udid>`). A CI (`app-ios.yml`) roda o núcleo, o build Release sem assinatura e os testes no simulador com os serviços falsos; os testes contra os emuladores e a conferência cruzada rodam no Mac e são obrigatórios antes de cada envio. O app nunca grava antes de ver os dados da conta (`Sincronizador`, erro `nao-carregado`). Sair segue o `cloud.js`: para a escuta, grava a marca `custta-limpar-cache` (`UserDefaults`), sai e apaga o cache; a abertura seguinte termina uma limpeza interrompida. Se apagar o cache falhar, a entrada fica bloqueada e o alerta "Finalizar saída" pede para limpar de novo, como o `cacheBloqueado` do site. Os identificadores de acessibilidade são contrato com os testes, inclusive a conferência cruzada. O Xcode da CI é fixo (`DEVELOPER_DIR` do 26.6). O `PrivacyInfo.xcprivacy` acompanha a política de privacidade do site: dado novo coletado entra nos dois. Envio: workflow `app-ios-testflight`, no botão, versão 2.0 no mesmo cadastro (`br.com.custta.app`). Pendências de aparelho: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md`.
+App em SwiftUI que vai substituir o Capacitor (spec `docs/specs/2026-10-06-app-nativo-design.md`, planos `docs/plans/2026-10-06-app-nativo-*`, mockup aprovado da etapa 1 em `~/Documents/custta-mockups/nativo/etapa1/final.html`, com a borda de rolagem do `final-v2.html` e as decisões de 10/10 no `final-v4.html`). O `app-ios/Custta.xcodeproj` é escrito à mão no formato do Xcode 16 (pastas sincronizadas): arquivo novo dentro de `Custta/`, `CusttaTests/` ou `CusttaUITests/` entra no alvo sozinho; não deixe o Xcode subir o `objectVersion` (77), porque a CI usa o Xcode 26 (`tests/app-ios.test.cjs` barra). As regras moram no pacote `app-ios/CusttaNucleo`, puro e conferido contra os vetores do site; o app tem a identidade em `Custta/Identidade/` (tokens de cor e de vidro, aurora, globo, título escrito à mão, superfícies de vidro e cápsula de abas, escritos uma vez e reusados), as telas, o `ModeloApp` e a camada fina do Firebase em `Custta/Dados/`. A cara é a do PWA: cores só por tokens (`scripts/cores-app-ios.mjs`; rode o script depois de mudar), ícones do `icons.js` (`scripts/icones-app-ios.mjs`), logo e globo iguais aos do site (as guardas comparam), toda superfície por `.superficie(_:em:)` com a dose de vidro da tela (`VidroTokens`), nunca vidro dentro de vidro, a mesma borda de rolagem em toda tela que rola (`.bordaDeRolagem(abas:)`), e animação própria só olhando o Reduzir movimento. O vidro do iOS não acompanha escala nem transformação 3D, e a auditoria de contraste do Xcode não lê vidro: as cores são auditadas com superfícies sólidas (e os pares de texto sobre sólido, em Node, pelo `PARES_SOLIDOS`), e a leitura sobre o vidro de verdade é medida pelo laudo de leitura (`LeituraNoVidroUITests`: dois prints do mesmo quadro, com e sem o texto, e 4,5:1 no pior ponto de cada palavra; portão no Mac e na CI, que mede a lista sob a cápsula em menos rolagens; o texto que o sistema desenha, como os botões dos alertas, é medido contra o fundo em volta das letras, e as exceções têm nome no teste). No escuro, uma camada do tom do fundo sob o vidro do conteúdo (`VidroTokens.escurecimento`) e o globo mais fundo dentro do app fecham a leitura; mexer na dose de vidro, na aurora, no globo ou na borda pede o laudo de novo. Nenhum build vai ao TestFlight com o laudo reprovando no Mac. Pacotes Swift: só firebase-ios-sdk e GoogleSignIn-iOS, em versão exata, com o `Package.resolved` versionado (para atualizar, botão "resolver de novo" do workflow `app-ios`); a Roboto Medium do botão do Google é a única fonte embutida, travada por SHA-256. Em Debug o app aceita `CUSTTA_SERVICOS=falsos` (telas e testes de tela; dados `vitrine` por padrão, as obras do mockup, e `exemplo` nos testes) e `CUSTTA_EMULADORES=1` (emuladores, com uma chave falsa, para um pedido que escape deles ser recusado pela produção); o Release não tem nenhum dos dois. Os emuladores rodam num FirebaseApp próprio (`Composicao.nomeDoAppDosEmuladores`), para a sessão deles nunca ocupar a vaga da produção no keychain. Nenhum teste monta a composição com rede, e cada agente roda os testes no seu simulador (`CUSTTA_SIMULADOR=<udid>`). A CI (`app-ios.yml`) roda o núcleo, o build Release sem assinatura e os testes no simulador com os serviços falsos; os testes contra os emuladores e a conferência cruzada rodam no Mac e são obrigatórios antes de cada envio. O app nunca grava antes de ver os dados da conta (`Sincronizador`, erro `nao-carregado`, com o alerta do texto do site); conta sem documento conta como vista quando o servidor já respondeu a ela neste aparelho (marca `custta-servidor-respondeu` no `UserDefaults`, apagada junto com o cache). Cartão de vidro que cresce (um mês da lista, o "A vencer") é um `CartaoDaLista`: com o vidro aplicado ao próprio conteúdo, o iOS 27 estica o quadro de acessibilidade da primeira linha até o cartão inteiro. Sair segue o `cloud.js`: para a escuta, grava a marca `custta-limpar-cache` (`UserDefaults`), sai e apaga o cache; a abertura seguinte termina uma limpeza interrompida. Se apagar o cache falhar, a entrada fica bloqueada e o alerta "Finalizar saída" pede para limpar de novo, como o `cacheBloqueado` do site. Os identificadores de acessibilidade são contrato com os testes, inclusive a conferência cruzada. O Xcode da CI é fixo (`DEVELOPER_DIR` do 26.6). O `PrivacyInfo.xcprivacy` acompanha a política de privacidade do site: dado novo coletado entra nos dois. Envio: workflow `app-ios-testflight`, no botão, versão 2.0 no mesmo cadastro (`br.com.custta.app`). Pendências de aparelho: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md` e `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`. Até a conferência do PR 3 da etapa 2, o app grava numa conta de teste criada por `scripts/conta-demo.mjs --importar` com as obras exportadas pelo site (o arquivo, com dados pessoais, nunca entra no repositório).
 
 ## UI
```

Criar `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`:

```markdown
# App nativo, etapa 2: checklist no iPhone

O Giovani roda no iPhone, pelo TestFlight, a cada build da etapa 2 (um por PR do app), **na conta de teste**. Cada item que falhar vira tarefa para o Forja, com o passo, o que apareceu e uma captura de tela. Os itens de um PR continuam valendo nos builds seguintes.

## Antes do primeiro build: a conta de teste

O app grava de verdade a partir desta etapa, e cada gravação regrava o documento inteiro da conta. Até a conferência do PR 3 passar, ele grava numa conta separada, com uma cópia das obras.

- [ ] No site, na conta de sempre: Ajustes → Seus dados → Exportar dados completos. Guarde o arquivo (`custta-AAAA-MM-DD.json`) fora do repositório.
- [ ] Escolha o e-mail da conta de teste com `custta-teste` nele (um apelido do Gmail serve, como `seu.nome+custta-teste@gmail.com`) e uma senha forte. Até o fim do PR 3, o build do TestFlight só grava em conta assim; na conta de sempre ele mostra os dados e recusa lançar.
- [ ] Com a conta de serviço do Firebase na máquina (`FIREBASE_SERVICE_ACCOUNT`, a mesma do cron de push), rode na raiz do repositório. A senha entra pelo `read -s`, para não ficar no histórico do terminal:
  `read -s CONTA_DEMO_SENHA && export CONTA_DEMO_SENHA`
  `node scripts/conta-demo.mjs --producao --email <e-mail de teste> --importar <caminho do JSON>`
  Saída esperada: a conta criada (ou repovoada) com o número de obras do arquivo.
- [ ] No site, entre com a conta de teste: as obras e os totais são os da conta de sempre.
- [ ] No iPhone, instale o build pelo TestFlight e entre com a conta de teste (Ajustes → Sair da conta, se já estiver na outra).

## PR 1: a tela da obra (só leitura)

- [ ] Toque numa obra da lista: a tela da obra abre, com o nome no título grande, a pílula da fase e do tempo ("começou em … · N meses") e os indicadores. Total gasto, Corrigido pelo banco, A pagar e Venda têm os mesmos números da obra no site.
- [ ] Volte pelo círculo do topo e, de novo, arrastando da borda esquerda da tela.
- [ ] Com uma obra aberta, vá a Ajustes e volte a Obras: a obra continua aberta.
- [ ] Role a obra: o nome sai do título grande e aparece pequeno na barra. Com a pílula de sincronização na barra ("Salvando…", "Sem conexão"), o nome pequeno some.
- [ ] A lista vem em cartões por mês, do mais recente, com o total de cada mês igual à soma dos gastos daquele mês no site.
- [ ] O "A vencer" aparece fechado no alto, com o total e "N gastos · o próximo é em dd/mm/aa"; um toque abre, outro fecha.
- [ ] Cada linha: o título (a descrição, ou o tópico quando não há descrição), o tópico, "Pix" ou "Cartão" escrito, a data e o valor com "−", sem vermelho; parcela com "(n/de)" no título.
- [ ] Obra sem gastos: "Nenhum gasto lançado." e "Toque no + para lançar o primeiro." (o + chega no PR 2).
- [ ] Venda sem estimativa: "Toque no lápis para informar o valor". O lápis (editar a obra) chega no PR 3; o texto já é o aprovado.
- [ ] VoiceOver: cada linha lê título, tópico, pagamento, data e valor; o "A vencer" diz se está aberto ou fechado.
- [ ] Ajustes do iPhone → Acessibilidade → Tela e Tamanho do Texto → Texto Maior, no máximo: o dinheiro fica numa linha só, encolhendo para caber; o resto quebra; cada informação da linha de gasto ocupa uma linha.
- [ ] Modo avião com o app já aberto uma vez: a obra abre do cache, com "Sem conexão" na barra.
- [ ] Leitura sobre o fundo: com o fundo animado, em claro e escuro, nada fica difícil de ler (títulos, cabeçalhos dos meses, linhas).
- [ ] Compare a lista de obras com o build anterior: os cartões ficaram um pouco mais escuros no tema escuro (o escurecimento sob o vidro subiu de 45% para 50%). Diga se incomoda.
```


- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md \
  docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md
git commit -m "docs: checklist do aparelho da etapa 2 e a conta de teste" -m "O checklist do iPhone da etapa 2 começa com a conta de teste e a tela da obra. O CLAUDE.md registra a marca do servidor na guarda de gravação, o cartão de vidro que cresce e a conta de teste até a conferência do PR 3."
```

**Ponto de controle do PR 1:** CI verde (núcleo, `app` e `laudo`); `npm run test:app-ios:emuladores` e `npm run test:app-ios:cruzado` verdes no Mac; o Giovani faz os passos da conta de teste do checklist; depois do merge, o Orquestrador dispara o `app-ios-testflight` com o OK dele, e o Giovani marca a seção do PR 1 no iPhone.

---

## PR 2 (app): o gasto inteiro

A parte 2 do mockup: o + na cápsula, a folha em dois passos com o teclado de valor, tópico, cartão, descrição com sugestões, data, editar, apagar arrastando e pela folha, avisos e a animação de apagar. Daqui em diante o app grava (na conta de teste).

### Task 19: Regras da folha do gasto e mutações do gasto no núcleo

Tudo o que a folha decide sem tela: o índice das sugestões (montado uma vez ao abrir a folha; responde igual ao `sugestoesDescricao` do site em todos os vetores), os tópicos da folha (a ordem do site, "Usados nesta obra" e o tópico inicial), os textos (assinatura e aviso do repetido, resumo e ajuda do cartão, aviso da parcela, condições originais, alertas de apagar) e as mutações do gasto sobre o estado (lançar no fim, editar no lugar, apagar um gasto, apagar a compra toda), que devolvem `nil` quando a obra ou o gasto sumiram e preservam os campos que o app não conhece.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift`
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/ObraNaTela.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Sugestoes.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Topicos.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift`
- Test (criar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MutacoesTests.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraNaTelaTests.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SugestoesTests.swift`

**Interfaces:**
- Consumes: Tarefas 1, 2 e 13 (`sugestoesDescricao`, `conferirGasto`, `LinhaDeGasto`); `Estado`, `Obra`, `Gasto` (etapa 1).
- Produces: `IndiceDeSugestoes(_:obraId:ignorarId:)` e `sugestoes(topicoId:termo:)`; `topicosDoFormulario(_:)`, `usadosNestaObra(_:topicos:)`, `topicoInicial(_:topicos:)`; `assinaturaDoGasto(obraId:entrada:conferido:)`, `avisoDeRepetido`, `resumoDoCartao(_:)`, `avisoDaParcela(_:)`, `ajudaDoCartao`, `condicoesOriginais(_:)`; `textoDeApagarGasto(_:)` e `textoDeApagarParcela(_:parcela:restantes:)`; `Estado.lancandoGastos(_:naObra:)`, `trocandoGasto(_:naObra:)`, `apagandoGasto(_:daObra:)`, `apagandoCompra(_:daObra:)`; `parcelasDaCompra(_:naObra:)`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift
@@ -118,3 +118,40 @@ struct FormulariosDaObraTests {
         }
     }
 }
+
+struct ResumoEAssinaturaTests {
+    @Test func resumoDoCartaoComOTextoDoSite() {
+        #expect(resumoDoCartao(parcelamentoCartao(100, 3, 0, "2026-01-15"))
+                == "3x de R$\u{a0}33,33 (última: R$\u{a0}33,34) · Juros do cartão: R$\u{a0}0,00 · Total: R$\u{a0}100,00")
+        #expect(resumoDoCartao(parcelamentoCartao(1000, 2, 10, "2026-10-11"))
+                == "2x de R$\u{a0}576,19 · Juros do cartão: R$\u{a0}152,38 · Total: R$\u{a0}1.152,38", "o exemplo do teste do site (cartao.cjs)")
+        #expect(resumoDoCartao(nil) == "Informe valor, parcelas, data válida e taxa entre 0 e 100% ao mês.")
+    }
+
+    @Test func assinaturaMudaComQualquerCampo() throws {
+        let e = EntradaDoGasto(valor: 1380, topico: "matbasicos", descricao: "Cimento", data: "2026-10-12", pagamento: "pix")
+        let c = try conferirGasto(e, editado: nil, hoje: "2026-10-12").get()
+        let a = assinaturaDoGasto(obraId: "o1", entrada: e, conferido: c)
+        #expect(a == "o1|matbasicos|cimento|138000|2026-10-12|1|")
+        var outra = e
+        outra.descricao = "Cimento cola"
+        #expect(assinaturaDoGasto(obraId: "o1", entrada: outra, conferido: try conferirGasto(outra, editado: nil, hoje: "2026-10-12").get()) != a)
+        #expect(assinaturaDoGasto(obraId: "o2", entrada: e, conferido: c) != a)
+    }
+}
+
+struct TextosDaFolhaDoGastoTests {
+    @Test func avisoDaParcelaEAjuda() {
+        #expect(avisoDaParcela(Parcela(n: 4, de: 10)) == "Parcela 4/10 de uma compra no cartão — a edição vale só pra esta parcela.")
+        #expect(ajudaDoCartao.hasPrefix("0 = sem juros.") && ajudaDoCartao.hasSuffix("A data abaixo é o primeiro vencimento."))
+    }
+
+    @Test func condicoesOriginaisComATaxaDoJavaScript() {
+        let g = Gasto(campos: ["id": .texto("p"), "jurosCartao": .objeto(["taxaMensal": .numero(2.5), "valorCompra": .numero(1000),
+                                                                       "nParcelas": .numero(10), "totalCompra": .numero(1124.6),
+                                                                       "jurosCompra": .numero(124.6)])])
+        #expect(condicoesOriginais(g) == "Condições originais da compra: 2,5% ao mês · 10x · juros R$\u{a0}124,60 · total R$\u{a0}1.124,60. "
+                + "O valor editável já inclui juros; não serão aplicados novamente.")
+        #expect(condicoesOriginais(Gasto(campos: ["id": .texto("x")])) == nil)
+    }
+}
```

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MutacoesTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/* O que as telas que gravam fazem no estado: lançar no fim, editar no lugar, apagar um gasto e a compra toda, sem tocar
   no que o app não conhece; obra ou gasto que sumiram devolvem nil (nada é gravado). */
struct MutacoesTests {
    func estado() -> Estado {
        Estado.de(.objeto(["obras": .lista([
            .objeto(["id": .texto("o1"), "nome": .texto("Casa"), "dataInicio": .texto("2026-01-01"), "campoDoSite": .numero(7), "gastos": .lista([
                .objeto(["id": .texto("a"), "valor": .numero(10), "topico": .texto("pintura"), "descricao": .texto("Tinta"), "data": .texto("2026-02-01"),
                         "pagamento": .texto("pix"), "notaSoDoSite": .texto("fica")]),
                .objeto(["id": .texto("p1"), "valor": .numero(5), "topico": .texto("eletrica"), "descricao": .texto("Fios"), "data": .texto("2026-03-01"),
                         "pagamento": .texto("cartao"), "grupoId": .texto("g"), "parcela": .objeto(["n": .numero(1), "de": .numero(2)])]),
                .objeto(["id": .texto("p2"), "valor": .numero(5), "topico": .texto("eletrica"), "descricao": .texto("Fios"), "data": .texto("2026-04-01"),
                         "pagamento": .texto("cartao"), "grupoId": .texto("g"), "parcela": .objeto(["n": .numero(2), "de": .numero(2)])]),
            ])]),
            .objeto(["id": .texto("o2"), "nome": .texto("Sobrado"), "dataInicio": .texto("2026-01-01"), "gastos": .lista([])]),
        ])]))
    }

    @Test func lancarNoFimDaObra() throws {
        let novo = Gasto(campos: ["id": .texto("n"), "valor": .numero(1), "topico": .texto("outros"), "descricao": .texto(""),
                                  "data": .texto("2026-05-01"), "pagamento": .texto("pix")])
        let e = try #require(estado().lancandoGastos([novo], naObra: "o1"))
        #expect(e.obras[0].gastos.map(\.id) == ["a", "p1", "p2", "n"])
        #expect(e.obras[0].campos["campoDoSite"] == .numero(7), "o que o app não conhece fica")
        #expect(estado().lancandoGastos([novo], naObra: "sumiu") == nil)
    }

    @Test func editarNoLugarAPartirDoGastoAtual() throws {
        let entrada = EntradaDoGasto(valor: 99, topico: "pintura", descricao: "Tinta fosca", data: "2026-02-01", pagamento: "pix")
        let conferido = try conferirGasto(entrada, editado: estado().obras[0].gastos[0], hoje: "2026-10-13").get()
        let e = try #require(estado().editandoGasto("a", entrada, conferido, naObra: "o1"))
        #expect(e.obras[0].gastos.map(\.id) == ["a", "p1", "p2"])
        #expect(e.obras[0].gastos[0].valor == 99 && e.obras[0].gastos[0].descricao == "Tinta fosca")
        #expect(e.obras[0].gastos[0].campos["notaSoDoSite"] == .texto("fica"))
        // Outro aparelho mudou o gasto com a folha aberta: a edição parte do que está no estado agora.
        var mudado = estado()
        mudado.obras[0].gastos[0].campos["notaSoDoSite"] = .texto("mudou em outro aparelho")
        let depois = try #require(mudado.editandoGasto("a", entrada, conferido, naObra: "o1"))
        #expect(depois.obras[0].gastos[0].campos["notaSoDoSite"] == .texto("mudou em outro aparelho"))
        #expect(estado().editandoGasto("x", entrada, conferido, naObra: "o1") == nil, "o gasto sumiu")
    }

    @Test func apagarUmEAcompraToda() throws {
        let um = try #require(estado().apagandoGasto("p1", daObra: "o1"))
        #expect(um.obras[0].gastos.map(\.id) == ["a", "p2"], "só esta parcela")
        let toda = try #require(estado().apagandoCompra("g", daObra: "o1"))
        #expect(toda.obras[0].gastos.map(\.id) == ["a"], "as parcelas que restam saem juntas")
        #expect(estado().apagandoGasto("x", daObra: "o1") == nil && estado().apagandoCompra("x", daObra: "o1") == nil)
        #expect(parcelasDaCompra(estado().obras[0].gastos[1], naObra: estado().obras[0]) == 2)
        #expect(parcelasDaCompra(um.obras[0].gastos[1], naObra: um.obras[0]) == 1, "conta as que restam, não o parcela.de")
        #expect(parcelasDaCompra(estado().obras[0].gastos[0], naObra: estado().obras[0]) == 1)
    }

    @Test func topicosDaFolha() {
        let topicos = topicosDoFormulario([])
        #expect(topicos.count == 21 && topicos.first?.id == "terreno")
        let comProprio = topicosDoFormulario([TopicoProprio(campos: ["id": .texto("c_x"), "nm": .texto("Automação"), "ic": .texto("etiqueta")])])
        #expect(comProprio.last?.nome == "Automação")
        let obra = estado().obras[0]
        #expect(topicoInicial(obra, topicos: topicos) == "eletrica", "o do último gasto lançado")
        #expect(topicoInicial(estado().obras[1], topicos: topicos) == "terreno", "obra sem gasto começa no primeiro, como o site")
        #expect(usadosNestaObra(obra, topicos: topicos).map(\.id) == ["eletrica", "pintura"])
        var empate = obra
        empate.gastos.append(Gasto(campos: ["id": .texto("z"), "valor": .numero(1), "topico": .texto("pintura"), "data": .texto("2026-06-01")]))
        #expect(usadosNestaObra(empate, topicos: topicos).map(\.id) == ["pintura", "eletrica"], "no empate, o do gasto mais recente")
    }
}
```

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraNaTelaTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraNaTelaTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraNaTelaTests.swift
@@ -91,4 +91,16 @@ struct ObraNaTelaTests {
         #expect(valor == "R$\u{a0}150.000,00" && etiqueta == "Vendida em 30/06/26" && !positivo)
         #expect(nota.hasPrefix("lucro -R$ 50 mil · -R$"), "\(nota)")
     }
+
+    @Test func textosDeApagar() {
+        let topicos = mapaDeTopicos([])
+        let pix = linhaDeGasto(Gasto(campos: gasto("a", "2026-10-10", 4980, descricao: "Cimento CP-II, 120 sacos").comoObjeto!), topicos: topicos)
+        #expect(textoDeApagarGasto(pix).titulo == "Apagar este gasto?")
+        #expect(textoDeApagarGasto(pix).mensagem == "Cimento CP-II, 120 sacos · R$\u{a0}4.980,00. Não dá para desfazer.")
+        let parcela = linhaDeGasto(Gasto(campos: gasto("p", "2026-10-05", 6150, descricao: "Porcelanato 60×60", parcela: (4, 10)).comoObjeto!), topicos: topicos)
+        let t = textoDeApagarParcela(parcela, parcela: Parcela(n: 4, de: 10), restantes: 10)
+        #expect(t.titulo == "Porcelanato 60×60 (4/10)" && t.mensagem == "Esta parcela faz parte de uma compra em 10x no cartão.")
+        #expect(t.soEsta == "Apagar só esta parcela" && t.compraToda == "Apagar a compra toda (10 parcelas)")
+        #expect(textoDeApagarParcela(parcela, parcela: Parcela(n: 4, de: 10), restantes: 1).compraToda == "Apagar a compra toda (1 parcela)")
+    }
 }
```

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SugestoesTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SugestoesTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SugestoesTests.swift
@@ -54,3 +54,27 @@ struct SugestoesTests {
         }
     }
 }
+
+struct IndiceDeSugestoesTests {
+    /// O índice responde igual à regra do site em todos os casos dos vetores.
+    @Test func igualAoDoSiteNosVetores() {
+        for c in Vetores.casos("calc.sugestoesDescricao") {
+            let obras = obrasDoCaso(c.args[0])
+            let obraId = c.args[1].comoTexto!, topico = c.args[2].comoTexto!, termo = c.args[3].comoTexto!, ignorar = c.args[4].comoTexto
+            let indice = IndiceDeSugestoes(obras, obraId: obraId, ignorarId: ignorar)
+            #expect(indice.sugestoes(topicoId: topico, termo: termo)
+                    == sugestoesDescricao(obras, obraId: obraId, topicoId: topico, termo: termo, ignorarId: ignorar), "\(c.caso)")
+        }
+    }
+
+    /// Trocar o tópico com a folha aberta muda o peso sem montar o índice de novo.
+    @Test func trocarDeTopicoNaoPedeOutroIndice() {
+        let c = Vetores.casos("calc.sugestoesDescricao").first { $0.caso == "mesmo tópico e mesma obra pesam" }!
+        let obras = obrasDoCaso(c.args[0])
+        let indice = IndiceDeSugestoes(obras, obraId: "s1", ignorarId: nil)
+        for topico in ["matbasicos", "revest", "eletrica", "outros"] {
+            #expect(indice.sugestoes(topicoId: topico, termo: "cimen")
+                    == sugestoesDescricao(obras, obraId: "s1", topicoId: topico, termo: "cimen", ignorarId: nil), "\(topico)")
+        }
+    }
+}
```


- [ ] **Step 2: Ver falhar**

Run: `TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | grep error: | head -3`
Expected: não compila: `cannot find 'IndiceDeSugestoes' in scope` (e as demais).

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift
@@ -168,3 +168,41 @@ public func conferirVenda(valor: Double, data: String, dataInicio: String, hoje:
     }
     return nil
 }
+
+/// A "assinatura" do gasto no aviso de repetido do site (app.js): obra, tópico, descrição comparável, valor em centavos,
+/// data, parcelas e taxa. O segundo toque em "Salvar mesmo assim" grava se ela não mudou; qualquer mudança pede de novo.
+public func assinaturaDoGasto(obraId: String, entrada: EntradaDoGasto, conferido: GastoConferido) -> String {
+    [obraId, entrada.topico, normalizaDescricao(entrada.descricao), numeroJS(arredondarJS(conferido.valor * 100)), conferido.data,
+     String(conferido.parcelas), conferido.cartao.map { numeroJS($0.taxaMensal) } ?? ""].joined(separator: "|")
+}
+
+/// O aviso de gasto repetido, com o texto do site.
+public let avisoDeRepetido = "Este gasto parece já lançado: mesma descrição, valor e data. Confira ou toque novamente para salvar mesmo assim."
+
+/// O resumo ao vivo do cartão, com o texto do site: "3x de R$ 33,33 (última: R$ 33,34) · Juros do cartão: R$ 0,00 ·
+/// Total: R$ 100,00", ou o pedido de conferir quando o parcelamento não fecha.
+public func resumoDoCartao(_ p: Parcelamento?) -> String {
+    guard let p, let primeira = p.parcelas.first, let ultima = p.parcelas.last else {
+        return "Informe valor, parcelas, data válida e taxa entre 0 e 100% ao mês."
+    }
+    let fim = ultima.valor != primeira.valor ? " (última: \(moeda(ultima.valor)))" : ""
+    return "\(p.nParcelas)x de \(moeda(primeira.valor))\(fim) · Juros do cartão: \(moeda(p.jurosCompra)) · Total: \(moeda(p.totalCompra))"
+}
+
+/// O aviso que toma o lugar do pagamento na edição de uma parcela (app.js:895).
+public func avisoDaParcela(_ p: Parcela) -> String {
+    "Parcela \(p.n)/\(p.de) de uma compra no cartão — a edição vale só pra esta parcela."
+}
+
+/// A ajuda do cartão no gasto novo (app.js:901).
+public let ajudaDoCartao = "0 = sem juros. Informe o valor da compra sem juros. Parcelas mensais fixas, com primeiro pagamento após um mês. A data abaixo é o primeiro vencimento."
+
+/// "Condições originais da compra" na edição de um gasto com `jurosCartao` (app.js:922): a taxa como o String() do
+/// JavaScript, com vírgula. nil quando o gasto não tem as condições (ou elas vêm sem os números).
+public func condicoesOriginais(_ gasto: Gasto) -> String? {
+    guard let j = gasto.campos["jurosCartao"]?.comoObjeto, let taxa = j["taxaMensal"]?.comoNumero, let n = j["nParcelas"]?.comoNumero,
+          let juros = j["jurosCompra"]?.comoNumero, let total = j["totalCompra"]?.comoNumero else { return nil }
+    let taxaTexto = numeroJS(taxa).replacingOccurrences(of: ".", with: ",")
+    return "Condições originais da compra: \(taxaTexto)% ao mês · \(numeroJS(n))x · juros \(moeda(juros)) · total \(moeda(total)). "
+        + "O valor editável já inclui juros; não serão aplicados novamente."
+}
```

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift`:

```swift
import Foundation

/* As mudanças que as telas que gravam fazem no estado, como o site faz no `db` antes do `save()`: cada uma parte do
   estado do momento (não de uma cópia guardada quando a folha abriu) e devolve o estado novo (o app grava pelo
   Sincronizador) ou nil quando a obra ou o gasto sumiram (apagados em outro aparelho com a folha aberta; o site, nesse
   caso, também não grava nada). Campos que o app não conhece ficam. */
public extension Estado {
    func indiceDaObra(_ id: String) -> Int? { obras.firstIndex { $0.id == id } }

    /// Os gastos novos no fim da obra, como o `push` do site.
    func lancandoGastos(_ novos: [Gasto], naObra obraId: String) -> Estado? {
        guard let i = indiceDaObra(obraId) else { return nil }
        var e = self
        e.obras[i].gastos.append(contentsOf: novos)
        return e
    }

    /// O gasto editado, montado a partir do que está no estado agora, como o site faz com o `o.gastos[i]` do momento do
    /// "Salvar": o que outro aparelho mudou no gasto com a folha aberta fica, menos o que a pessoa respondeu.
    func editandoGasto(_ gastoId: String, _ entrada: EntradaDoGasto, _ conferido: GastoConferido, naObra obraId: String) -> Estado? {
        guard let i = indiceDaObra(obraId), let j = obras[i].gastos.firstIndex(where: { $0.id == gastoId }) else { return nil }
        var e = self
        e.obras[i].gastos[j] = gastoEditado(obras[i].gastos[j], entrada, conferido)
        return e
    }

    /// Sem o gasto: o "Apagar" de um gasto, ou de uma parcela só.
    func apagandoGasto(_ gastoId: String, daObra obraId: String) -> Estado? {
        guard let i = indiceDaObra(obraId), obras[i].gastos.contains(where: { $0.id == gastoId }) else { return nil }
        var e = self
        e.obras[i].gastos.removeAll { $0.id == gastoId }
        return e
    }

    /// Sem nenhuma parcela da compra: o "Apagar a compra toda" (as que restam com o mesmo `grupoId`).
    func apagandoCompra(_ grupoId: String, daObra obraId: String) -> Estado? {
        guard let i = indiceDaObra(obraId), obras[i].gastos.contains(where: { $0.grupoId == grupoId }) else { return nil }
        var e = self
        e.obras[i].gastos.removeAll { $0.grupoId == grupoId }
        return e
    }
}

/// As parcelas que restam da compra do gasto (o N do "Apagar a compra toda (N parcelas)", contado como o site: as irmãs
/// que ainda existem, não o `parcela.de`).
public func parcelasDaCompra(_ gasto: Gasto, naObra obra: Obra) -> Int {
    guard let grupo = gasto.grupoId else { return 1 }
    return obra.gastos.filter { $0.grupoId == grupo }.count
}
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/ObraNaTela.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/ObraNaTela.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/ObraNaTela.swift
@@ -171,3 +171,15 @@ public func indicadoresDaObra(_ obra: Obra, taxa: Double, hoje: String) -> Indic
         etiquetaDoAPagar: vencimentos.qtd == 0 ? "nada em 30 dias" : "\(vencimentos.qtd) vencimento\(vencimentos.qtd > 1 ? "s" : "")",
         venda: venda)
 }
+
+/// O alerta de apagar um gasto (mockup aprovado, "Apagar" em tudo): "Apagar este gasto?" com o nome e o valor.
+public func textoDeApagarGasto(_ linha: LinhaDeGasto) -> (titulo: String, mensagem: String) {
+    ("Apagar este gasto?", "\(linha.titulo) · \(linha.valorFalado). Não dá para desfazer.")
+}
+
+/// O alerta de apagar uma parcela: só esta ou a compra toda, com o N das que restam (o site conta as irmãs que existem).
+public func textoDeApagarParcela(_ linha: LinhaDeGasto, parcela: Parcela, restantes: Int)
+    -> (titulo: String, mensagem: String, soEsta: String, compraToda: String) {
+    (linha.titulo, "Esta parcela faz parte de uma compra em \(parcela.de)x no cartão.", "Apagar só esta parcela",
+     "Apagar a compra toda (\(restantes) parcela\(restantes == 1 ? "" : "s"))")
+}
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Sugestoes.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Sugestoes.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Sugestoes.swift
@@ -119,3 +119,62 @@ public func lerTaxaCartao(_ texto: String?) -> Double {
     r.append(contentsOf: t.map { $0 == "," ? "." : $0 })
     return Double(String(r)) ?? .nan
 }
+
+/// As descrições já lançadas, prontas para as sugestões do formulário: monta uma vez ao abrir a folha e responde a cada
+/// letra sem passar por todos os gastos de novo. O resultado é o de `sugestoesDescricao` (o do site); os testes conferem
+/// os dois em todos os casos dos vetores.
+public struct IndiceDeSugestoes: Sendable {
+    struct Entrada: Sendable {
+        let texto: String
+        let chave: String
+        let vezes: Int
+        let naObra: Bool
+        let topicos: Set<String>
+        let ultima: String
+    }
+    private let entradas: [Entrada]
+
+    /// `obraId`: a obra do gasto (pesa "mesma obra" e é onde o `ignorarId`, o gasto em edição, sai).
+    public init(_ obras: [Obra], obraId: String, ignorarId: String?) {
+        var ordem: [String] = []
+        var itens: [String: (texto: String, vezes: Int, naObra: Bool, topicos: Set<String>, ultima: String)] = [:]
+        for o in obras {
+            for g in o.gastos {
+                if o.id == obraId && g.id == ignorarId { continue }
+                let texto = aparadoJS(g.descricao), chave = normalizaDescricao(texto)
+                if chave.isEmpty { continue }
+                var item = itens[chave] ?? (texto, 0, false, [], "")
+                if itens[chave] == nil { ordem.append(chave) }
+                item.vezes += 1
+                if o.id == obraId { item.naObra = true }
+                item.topicos.insert(g.topico)
+                if !menorJS(g.data, item.ultima) { item.ultima = g.data; item.texto = texto }
+                itens[chave] = item
+            }
+        }
+        entradas = ordem.compactMap { chave in
+            itens[chave].map { Entrada(texto: $0.texto, chave: chave, vezes: $0.vezes, naObra: $0.naObra, topicos: $0.topicos, ultima: $0.ultima) }
+        }
+    }
+
+    public func sugestoes(topicoId: String, termo: String) -> [SugestaoDeDescricao] {
+        let busca = normalizaDescricao(termo)
+        if busca.isEmpty { return [] }
+        let tamanho = busca.utf16.count
+        let candidatas = entradas.filter { x in
+            contem(x.chave, busca)
+                || (tamanho >= 4 && abs(x.chave.utf16.count - tamanho) <= 2 && distanciaEdicao(x.chave, busca) <= 2)
+        }.map { x in
+            SugestaoDeDescricao(texto: x.texto, chave: x.chave, vezes: x.vezes, mesmaObra: x.naObra,
+                                mesmoTopico: x.topicos.contains(topicoId), ultima: x.ultima)
+        }
+        func peso(_ x: SugestaoDeDescricao) -> Int { x.peso + (x.chave.utf16.starts(with: busca.utf16) ? 25 : 0) }
+        let ordenadas = ordenadoEstavel(candidatas) { a, b in
+            let pa = peso(a), pb = peso(b)
+            if pa != pb { return pa > pb }
+            if a.ultima != b.ultima { return menorJS(b.ultima, a.ultima) }
+            return ordemPtBR(a.texto, b.texto) == .orderedAscending
+        }
+        return Array(ordenadas.prefix(5))
+    }
+}
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Topicos.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Topicos.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Topicos.swift
@@ -38,3 +38,36 @@ public func mapaDeTopicos(_ proprios: [TopicoProprio]) -> [String: Topico] {
     for t in proprios { mapa[t.id] = Topico(id: t.id, nome: t.nome, icone: t.icone) }
     return mapa
 }
+
+/// Os tópicos na ordem do formulário do site: os 21 fixos e depois os próprios (o `topicos()` do app.js).
+public func topicosDoFormulario(_ proprios: [TopicoProprio]) -> [Topico] {
+    let mapa = mapaDeTopicos(proprios)
+    var vistos = Set<String>()
+    return (topicosPadrao.map(\.id) + proprios.map(\.id)).compactMap { id in
+        guard vistos.insert(id).inserted else { return nil }
+        return mapa[id]
+    }
+}
+
+/// "Usados nesta obra" (regra do app, aprovada no mockup da etapa 2): os três tópicos com mais gastos na obra; no empate,
+/// o do gasto mais recente (data e id, a ordem da lista). Só tópicos que existem na lista.
+public func usadosNestaObra(_ obra: Obra, topicos: [Topico]) -> [Topico] {
+    let existentes = Dictionary(topicos.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
+    var contagem: [String: (vezes: Int, ultimo: String)] = [:]
+    for g in obra.gastos where existentes[g.topico] != nil {
+        let chave = g.data + g.id
+        let atual = contagem[g.topico] ?? (0, "")
+        contagem[g.topico] = (atual.vezes + 1, menorJS(atual.ultimo, chave) ? chave : atual.ultimo)
+    }
+    let ordem = contagem.sorted { a, b in
+        a.value.vezes != b.value.vezes ? a.value.vezes > b.value.vezes : menorJS(b.value.ultimo, a.value.ultimo)
+    }
+    return ordem.prefix(3).compactMap { existentes[$0.key] }
+}
+
+/// O tópico com que um gasto novo começa (regra do app, aprovada no mockup): o do último gasto lançado na obra (o site
+/// põe o gasto novo no fim da lista); obra sem gasto, ou tópico que não existe mais, começa no primeiro, como no site.
+public func topicoInicial(_ obra: Obra, topicos: [Topico]) -> String {
+    if let ultimo = obra.gastos.last?.topico, topicos.contains(where: { $0.id == ultimo }) { return ultimo }
+    return topicos.first?.id ?? "terreno"
+}
```


- [ ] **Step 4: Ver passar**

Run: o núcleo inteiro.
Expected: `✔ Test run with 161 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Formularios.swift \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/ObraNaTela.swift \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/Sugestoes.swift \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/Topicos.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/FormulariosTests.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MutacoesTests.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraNaTelaTests.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SugestoesTests.swift
git commit -m "feat: regras da folha do gasto e mutações do gasto no núcleo" -m "O que a folha do gasto decide sem tela: o índice das sugestões, igual ao do site em todos os vetores, os tópicos da folha com os usados nesta obra e o tópico inicial, os textos do repetido, do cartão, da parcela e dos alertas de apagar, e as mutações do gasto sobre o estado, que preservam os campos que o app não conhece."
```

### Task 20: Gravação aplicada na hora, com a confirmação do servidor depois

O `salvar` do Sincronizador esperava o servidor. Para a tela animar a mudança na mesma transação (a linha que sai, os totais que mudam), o começo dele vira `aplicar`: troca o estado na hora, entrega o documento e devolve uma `Gravacao` que o servidor confirma depois; `salvar` passa a ser `aplicar` + esperar. O `ModeloApp.gravar` recebe a mudança do núcleo e devolve o que aconteceu (gravou, sumiu, não carregado, sem conta).

**Files:**
- Create: `app-ios/Custta/Estado/ContaDeTeste.swift`
- Modify: `app-ios/Custta/Estado/ModeloApp.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift`
- Test (criar): `app-ios/CusttaTests/GravacaoDoAppTests.swift`

**Interfaces:**
- Consumes: Tarefas 11 e 19.
- Produces: `Sincronizador.aplicar(_:) throws -> Gravacao` (`@discardableResult`); `Gravacao.confirmou` e `confirmada() async throws`; `ModeloApp.gravar(_ mudanca: (Estado) -> Estado?) -> ResultadoDaGravacao` (`.gravou`, `.sumiu`, `.naoCarregado`, `.semConta`); em Debug, `-custta.recusarGravacao nao-carregado`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift
@@ -27,6 +27,32 @@ struct SincronizadorEscritaTests {
         #expect(!s.temPendencia)
     }
 
+    @Test func aplicarTrocaOEstadoNaHoraEAConfirmacaoChegaDepois() async throws {
+        let s = montar(), t = transporte
+        let g = try s.aplicar(Estado.de(blobCom(["Nova"])))
+        #expect(s.estado.obras.map(\.nome) == ["Nova"], "o estado troca antes de qualquer espera: a tela anima na mesma transação")
+        #expect(t.gravacoes.count == 1 && !g.confirmou)
+        t.gravacoes[0].concluir(nil)
+        try await g.confirmada()
+        #expect(g.confirmou)
+    }
+
+    @Test func aplicarRecusaNaHoraAntesDeVerOsDados() {
+        let t = TransporteFalso()
+        let s = Sincronizador(transporte: t, relogio: RelogioFalso())
+        s.iniciar(uid: "u1")
+        #expect(throws: ErroSinc(codigo: "nao-carregado")) { try s.aplicar(Estado.de(blobCom(["Nova"]))) }
+        #expect(t.gravacoes.isEmpty && s.estado == .vazio)
+    }
+
+    @Test func aplicarComErroTerminalFalhaNaConfirmacao() async {
+        let s = montar(), t = transporte
+        let g = try! s.aplicar(Estado.de(blobCom(["Nova"])))
+        t.gravacoes[0].concluir("permission-denied")
+        await #expect(throws: ErroSinc(codigo: "permission-denied")) { try await g.confirmada() }
+        #expect(!g.confirmou)
+    }
+
     @Test func semRedeMostraSemConexaoEEnviaMesmoAssim() async throws {
         let s = montar(online: false)
         let tarefa = Task { try await s.salvar(Estado.de(blobCom(["Casa"]))) }
```

Criar `app-ios/CusttaTests/GravacaoDoAppTests.swift`:

```swift
import Foundation
import Testing
@testable import Custta
import CusttaNucleo

/* O que as telas que gravam usam (etapa 2): o `gravar` do modelo (troca o estado na hora e sobe o documento; recusa
   sem ver os dados; nada sobe quando a obra sumiu). */
@MainActor
struct GravacaoDoAppTests {
    func montar(semRede: Bool = false, dados: ValorJSON? = DadosDeExemplo.blob) -> (ModeloApp, TransporteFalsoApp, ContaFalsa) {
        let conta = ContaFalsa(inicial: "senha")
        let transporte = TransporteFalsoApp(dados: dados, semRede: semRede)
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede, marca: MarcaEmMemoria())
        return (ModeloApp(conta: conta, sincronizador: sincronizador, rede: MonitorDeRede(forcarSemRede: semRede)), transporte, conta)
    }

    @Test func gravarTrocaOEstadoNaHoraESobeODocumento() async {
        let (m, transporte, _) = montar()
        await ate { m.sincronizador.dadosCarregados }
        let obra = m.sincronizador.estado.obras[0]
        let antes = obra.gastos.count
        let novo = Gasto(campos: ["id": .texto("novo"), "valor": .numero(10), "topico": .texto("outros"), "descricao": .texto(""),
                                  "data": .texto("2026-10-13"), "pagamento": .texto("pix")])
        #expect(m.gravar { $0.lancandoGastos([novo], naObra: obra.id) } == .gravou)
        #expect(m.sincronizador.estado.obras[0].gastos.count == antes + 1, "a tela vê o gasto antes do servidor responder")
        #expect(transporte.gravacoes == 1)
    }

    @Test func buildDoTestFlightSoGravaEmContaDeTeste() {
        #expect(!ContaDeTeste.podeGravar(email: "giovani@exemplo.com", release: true), "a conta de sempre não grava no build de teste")
        #expect(ContaDeTeste.podeGravar(email: "Giovani+Custta-Teste@gmail.com", release: true))
        #expect(ContaDeTeste.podeGravar(email: "giovani@exemplo.com", release: false), "em Debug grava sempre")
        #expect(!ContaDeTeste.podeGravar(email: nil, release: true))
    }

    @Test func obraQueSumiuNaoGravaNada() async {
        let (m, transporte, _) = montar()
        await ate { m.sincronizador.dadosCarregados }
        #expect(m.gravar { $0.apagandoGasto("x", daObra: "nao-existe") } == .sumiu)
        #expect(transporte.gravacoes == 0)
    }

    @Test func antesDeVerOsDadosRecusaComOTextoDoSite() async {
        let (m, transporte, _) = montar(semRede: true, dados: nil)
        await ate { m.fase.ehPrincipal }
        let estado = m.sincronizador.estado
        #expect(m.gravar { $0.lancandoGastos([], naObra: $0.obras.first?.id ?? "") ?? $0 } == .naoCarregado)
        #expect(m.sincronizador.estado == estado && transporte.gravacoes == 0)
        #expect(m.mensagemDeNaoCarregado == "Conecte à internet para carregar suas obras antes de lançar.")
    }

    @Test func depoisDeSairNaoGrava() async {
        let (m, transporte, _) = montar()
        await ate { m.sincronizador.dadosCarregados }
        m.sincronizador.parar()
        #expect(m.gravar { $0 } == .semConta)
        #expect(transporte.gravacoes == 0)
    }
}
```


- [ ] **Step 2: Ver falhar**

Run: o filtro `SincronizadorEscritaTests` do núcleo.
Expected: não compila: `value of type 'Sincronizador' has no member 'aplicar'`.

- [ ] **Step 3: Implementar**

Criar `app-ios/Custta/Estado/ContaDeTeste.swift`:

```swift
import Foundation

/* Até a conferência cruzada do PR 3 da etapa 2 (spec docs/specs/2026-10-13-app-nativo-etapa2-design.md, "Conta de
   teste"), o build do TestFlight (Release) grava só em conta de teste: e-mail com "custta-teste" (um apelido do Gmail
   serve, como nome+custta-teste@gmail.com). Na conta de sempre, o app mostra os dados e recusa gravar, para um lançamento
   por hábito não regravar o documento inteiro da conta real. Em Debug (simulador e testes) grava sempre. A troca para a
   conta real, no fim do PR 3, apaga este arquivo. */
enum ContaDeTeste {
    static let marca = "custta-teste"

    static func podeGravar(email: String?, release: Bool = ehRelease) -> Bool {
        !release || (email ?? "").lowercased().contains(marca)
    }

    static let titulo = "Este build ainda não grava na sua conta"
    static let mensagem = "Até o fim dos testes, lançar, editar e apagar só valem na conta de teste. Nada foi gravado."

    #if DEBUG
    static let ehRelease = false
    #else
    static let ehRelease = true
    #endif
}
```

Em `app-ios/Custta/Estado/ModeloApp.swift`:

```diff
--- a/app-ios/Custta/Estado/ModeloApp.swift
+++ b/app-ios/Custta/Estado/ModeloApp.swift
@@ -250,6 +250,38 @@ final class ModeloApp {
         return textoNaoCarregado(online: rede.online)
     }
 
+    /// O que aconteceu com uma gravação pedida por uma tela.
+    enum ResultadoDaGravacao: Equatable {
+        case gravou
+        /// A obra ou o gasto sumiram (apagados em outro aparelho com a folha aberta): nada foi gravado.
+        case sumiu
+        /// Antes de ver os dados da conta: o alerta com `mensagemDeNaoCarregado`, e nada foi gravado.
+        case naoCarregado
+        /// A conta saiu no meio.
+        case semConta
+        /// Build do TestFlight numa conta que não é de teste (até a conferência do PR 3): nada foi gravado.
+        case contaReal
+    }
+
+    /// Muda o estado na hora, pela regra do núcleo, e entrega o documento inteiro para gravar (o `save()` do site). A tela
+    /// que chama dentro de uma animação anima a mudança na mesma transação. A resposta do servidor segue pela pílula de
+    /// sincronização e pelos avisos, como no resto do app.
+    func gravar(_ mudanca: (Estado) -> Estado?) -> ResultadoDaGravacao {
+        #if DEBUG
+        if UserDefaults.standard.string(forKey: "custta.recusarGravacao") == "nao-carregado" { return .naoCarregado }
+        #endif
+        guard ContaDeTeste.podeGravar(email: usuario?.email) else { return .contaReal }
+        guard let novo = mudanca(sincronizador.estado) else { return .sumiu }
+        do {
+            try sincronizador.aplicar(novo)
+            return .gravou
+        } catch let erro as ErroSinc where erro.codigo == "nao-carregado" {
+            return .naoCarregado
+        } catch {
+            return .semConta
+        }
+    }
+
     /* ---------- sincronização e avisos ---------- */
 
     func tentarDeNovo() {
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift
@@ -197,6 +197,15 @@ public final class Sincronizador {
     /// versão (ou uma mais nova); lança ErroSinc no erro terminal, se a conta saiu ("cancelled") ou
     /// se ainda não deu para ver os dados desta conta ("nao-carregado").
     public func salvar(_ novo: Estado) async throws {
+        try await aplicar(novo).confirmada()
+    }
+
+    /// O começo do `salvar`, sem esperar: troca o estado na hora e entrega o documento para gravar. Quem chama
+    /// dentro de um `withAnimation` anima a mudança na mesma transação (o apagar e o lançar das telas). Lança na hora
+    /// o que o `salvar` lançaria antes de gravar ("cancelled", "nao-carregado"); a resposta do servidor chega pela
+    /// `Gravacao`.
+    @discardableResult
+    public func aplicar(_ novo: Estado) throws -> Gravacao {
         guard uid != nil else {
             avisar(.naoSalvou(codigo: "cancelled", terminal: true))
             throw ErroSinc(codigo: "cancelled")
@@ -207,17 +216,15 @@ public final class Sincronizador {
         let tamanho = tamanhoBlob(blob)
         if tamanho >= avisoBlob && tamanho <= limiteBlob && !avisouTamanho { avisouTamanho = true; avisar(.pertoDoLimite) }
         if tamanho < avisoBlob { avisouTamanho = false }
-        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
-            esperas.append { codigo in
-                if let codigo { c.resume(throwing: ErroSinc(codigo: codigo)) } else { c.resume() }
-            }
-            pendente = blob
-            sujo = true
-            if estadoSinc.ehErro { tentativa = 0 }
-            repeticao?.cancelar(); repeticao = nil
-            publicar(online ? .salvando : .offline)
-            enviar()
-        }
+        let gravacao = Gravacao()
+        esperas.append { codigo in gravacao.concluir(codigo) }
+        pendente = blob
+        sujo = true
+        if estadoSinc.ehErro { tentativa = 0 }
+        repeticao?.cancelar(); repeticao = nil
+        publicar(online ? .salvando : .offline)
+        enviar()
+        return gravacao
     }
 
     /// Toque no indicador de erro: reabre a leitura que falhou e reenvia o que está pendente.
@@ -366,6 +373,36 @@ public final class Sincronizador {
     }
 }
 
+/// A resposta do servidor a uma gravação já aplicada: chega quando ele confirma esta versão (ou uma mais nova) e falha no
+/// erro terminal ou se a conta saiu ("cancelled"). Quem não espera não perde nada: o estado já foi trocado e a fila segue.
+@MainActor public final class Gravacao {
+    /// nil enquanto espera; depois, o código do erro (nil dentro) ou a confirmação.
+    private var resultado: String??
+    private var esperando: [CheckedContinuation<Void, Error>] = []
+
+    init() {}
+
+    /// O servidor confirmou.
+    public var confirmou: Bool { resultado == .some(nil) }
+
+    func concluir(_ codigo: String?) {
+        guard resultado == nil else { return }
+        resultado = .some(codigo)
+        let todos = esperando
+        esperando = []
+        for c in todos { if let codigo { c.resume(throwing: ErroSinc(codigo: codigo)) } else { c.resume() } }
+    }
+
+    /// Espera a resposta do servidor.
+    public func confirmada() async throws {
+        if let r = resultado {
+            if let codigo = r { throw ErroSinc(codigo: codigo) }
+            return
+        }
+        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in esperando.append(c) }
+    }
+}
+
 /// Junta várias esperas num resultado só: true quando todas cumprem, false no primeiro erro ou no tempo.
 @MainActor private final class EsperaUnica {
     private let continuacao: CheckedContinuation<Bool, Never>
```


- [ ] **Step 4: Ver passar**

Run: o núcleo inteiro; `xcodebuild build-for-testing "${XB[@]}"` e `-only-testing:CusttaTests`.
Expected: `✔ Test run with 164 tests … passed`; `CusttaTests` com 93 testes verdes.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Estado/ContaDeTeste.swift \
  app-ios/Custta/Estado/ModeloApp.swift \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift \
  app-ios/CusttaTests/GravacaoDoAppTests.swift
git commit -m "feat: gravação aplicada na hora, com a confirmação do servidor depois" -m "O começo do salvar do Sincronizador vira aplicar: troca o estado na hora e entrega o documento, e a confirmação do servidor chega depois por uma Gravacao. Assim a tela anima a mudança na mesma transação, e o ModeloApp ganha o gravar que as telas usam, com o resultado de cada pedido."
```

### Task 21: Tokens da folha, peças da folha e teclado de valor

Os onze tokens novos (os cinco do spec e seis do mockup), com os valores dos quatro combos da parte 2 e os pares de texto sobre sólido na guarda de contraste; as peças de dentro da folha (grupo, linha com rótulo, separador, nota, título da barra, segmentado Pix | Cartão), com o rótulo em cima do valor e o segmentado empilhado na letra grande; e o teclado de valor reutilizável: teclas na ordem do telefone, "00" e apagar, teto do site, visor que encolhe para caber, teclas até o AX2, e o VoiceOver ouvindo o valor a cada tecla.

**Files:**
- Modify: `app-ios/Custta/Identidade/Paleta.swift`
- Create: `app-ios/Custta/Identidade/PecasDaFolha.swift`
- Create: `app-ios/Custta/Identidade/TecladoDeValor.swift`
- Modify: `scripts/cores-app-ios.mjs`
- Test (alterar): `tests/app-ios.test.cjs`
- Gerado: cores em `app-ios/Custta/Assets.xcassets/{Esmeralda,Azul}/` (`node scripts/cores-app-ios.mjs`)

**Interfaces:**
- Consumes: Tarefa 4 (`aplicarTecla`, `fmtCentavos`, `TeclaDeValor`); `.foraDoLaudo()` (Tarefa 14).
- Produces: `Token.folha`, `.linhaDaFolha`, `.separadorDaFolha`, `.tecla`, `.teclaTocada`, `.segmentadoFundo`, `.segmentadoEscolhido`, `.apagar`, `.sobreApagar`, `.sobreAlerta`, `.aceso`; `GrupoDaFolha`, `SeparadorDaFolha(recuo:)`, `LinhaDaFolhaComRotulo(rotulo:altura:valor:)`, `SetaDaLinha`, `NotaDaFolha(texto:cor:identificador:)`, `TituloDaFolha(titulo:subtitulo:)`, `SegmentadoDaFolha(opcoes:escolhida:identificador:)`; `TecladoDeValor(centavos:acao:confirmar:)`, `VisorDoValor`, `TeclaDoValor`, `BotaoDaFolha(ambar:)`. Identificadores: `visorDoValor`, `tecla-<nome>`, `confirmarValor`, `tituloDaFolha`.

- [ ] **Step 1: Pôr o visor e o título da folha na lista fixa da guarda**

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -427,9 +427,10 @@ test('texto cresce com a letra: lineLimit e minimumScaleFactor só no botão do
   // A auditoria de texto cortado do Xcode não vê dentro de um elemento que o VoiceOver lê inteiro (o cartão da
   // obra): com o nome da obra preso numa linha, ela passa na maior letra. Ficam numa linha, por decisão, o botão
   // do Google (letra travada, fora da auditoria de tipo dinâmico), o indicador de sincronização da barra, o
-  // dinheiro (ValorEmDinheiro, mockup da etapa 2: encolhe até a metade em vez de quebrar) e o título pequeno da
-  // barra da obra (corta como o do sistema, em vez de empurrar o voltar e o lápis).
-  const fixos = new Set(['BotaoGoogle', 'IndicadorDeSincronizacao', 'ValorEmDinheiro', 'TituloPequenoDaBarra']);
+  // dinheiro (ValorEmDinheiro e o visor do teclado de valor, mockup da etapa 2: encolhe para caber em vez de quebrar)
+  // e os títulos da barra, o pequeno da obra e o da folha (cortam como o do sistema, em vez de empurrar os botões).
+  const fixos = new Set(['BotaoGoogle', 'IndicadorDeSincronizacao', 'ValorEmDinheiro', 'VisorDoValor', 'TituloPequenoDaBarra',
+    'TituloDaFolha']);
   for(const f of arquivosSwift('app-ios/Custta')){
     const t = ler(f);
     for(const m of t.matchAll(/\.(lineLimit|minimumScaleFactor)\(/g)){
```


- [ ] **Step 2: Ver falhar**

Com a tabela nova no `scripts/cores-app-ios.mjs` (o bloco dele no Step 3) e o catálogo ainda velho:
Run: `node --test tests/app-ios.test.cjs 2>&1 | grep "✖"`
Expected: FAIL na guarda das cores (catálogo de cores defasado).

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Identidade/Paleta.swift`:

```diff
--- a/app-ios/Custta/Identidade/Paleta.swift
+++ b/app-ios/Custta/Identidade/Paleta.swift
@@ -65,6 +65,23 @@ enum Token: String, CaseIterable, Sendable {
     /// O lucro e o prejuízo da obra vendida sobre o vidro (o Positivo e o Negativo não fechavam 4,5:1 com a aurora atrás).
     case positivoNoVidro = "PositivoNoVidro"
     case negativoNoVidro = "NegativoNoVidro"
+    /// A folha do sistema (etapa 2): o fundo, os grupos sólidos dentro dela e a linha fina entre as linhas de um grupo.
+    case folha = "Folha"
+    case linhaDaFolha = "LinhaDaFolha"
+    case separadorDaFolha = "SeparadorDaFolha"
+    /// Teclas do teclado de valor, soltas e tocadas.
+    case tecla = "Tecla"
+    case teclaTocada = "TeclaTocada"
+    /// O segmentado Pix | Cartão: o trilho e a opção escolhida.
+    case segmentadoFundo = "SegmentadoFundo"
+    case segmentadoEscolhido = "SegmentadoEscolhido"
+    /// O botão do arrastar para apagar e o texto sobre ele.
+    case apagar = "Apagar"
+    case sobreApagar = "SobreApagar"
+    /// Texto sobre o Alerta ("Salvar mesmo assim").
+    case sobreAlerta = "SobreAlerta"
+    /// O fundo da linha que acabou de entrar.
+    case aceso = "Aceso"
 }
 
 struct Paleta: Equatable, Sendable {
```

Criar `app-ios/Custta/Identidade/PecasDaFolha.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* As peças de dentro da folha do sistema (mockup da etapa 2, parte 2, "Medidas"): grupos sólidos na Linha da folha, a
   16 pt das bordas, raio 24 e 20 pt entre eles; linhas de 52 pt (a do valor, 60) com rótulo à esquerda e valor à direita;
   a linha fina recuada 16 pt; cabeçalho e rodapé em 13 pt secundário. Dentro da folha nada é vidro: a folha já é. Na
   letra grande, o rótulo vai em cima do valor. */

/// Um grupo de linhas: o fundo sólido e o recorte no raio do grupo.
struct GrupoDaFolha<Conteudo: View>: View {
    @ViewBuilder let conteudo: () -> Conteudo
    @Environment(\.paleta) private var paleta

    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: conteudo)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(paleta.cor(.linhaDaFolha), in: .rect(cornerRadius: 24, style: .continuous))
            .clipShape(.rect(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 16)
    }
}

/// A linha fina entre duas linhas de um grupo, recuada do começo (16 pt; 60 na lista de tópicos).
struct SeparadorDaFolha: View {
    var recuo: CGFloat = 16
    @Environment(\.paleta) private var paleta
    @Environment(\.displayScale) private var escala

    var body: some View {
        Rectangle()
            .fill(paleta.cor(.separadorDaFolha))
            .frame(height: 1 / escala)
            .padding(.leading, recuo)
            .accessibilityHidden(true)
    }
}

/// Uma linha com rótulo e valor ("Valor", "Tópico", "Data", "Parcelas"): lado a lado; na letra grande, um em cima do
/// outro. `altura` é a mínima (52; a do valor, 60).
struct LinhaDaFolhaComRotulo<Valor: View>: View {
    let rotulo: String
    var altura: CGFloat = 52
    @ViewBuilder let valor: () -> Valor
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let layout = tamanho.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            Text(rotulo)
                .foregroundStyle(paleta.cor(.texto))
                .fixedSize(horizontal: false, vertical: true)
            if !tamanho.isAccessibilitySize { Spacer(minLength: 0) }
            valor()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, minHeight: altura, alignment: .leading)
        .contentShape(.rect)
    }
}

/// A seta ">" das linhas que abrem outro passo.
struct SetaDaLinha: View {
    @Environment(\.paleta) private var paleta

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(paleta.cor(.secundarioSolido))
            .accessibilityHidden(true)
            .foraDoLaudo()
    }
}

/// Texto solto na folha, fora dos grupos (resumo do cartão, ajuda, avisos): 13 pt secundário, a 34 pt da borda (16 do
/// grupo + 18), como o rodapé de um grupo de Ajustes do sistema.
struct NotaDaFolha: View {
    let texto: String
    var cor: Token = .textoSecundario
    var identificador: String?

    @Environment(\.paleta) private var paleta

    var body: some View {
        Text(texto)
            .font(.footnote)
            .foregroundStyle(paleta.cor(cor))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 34)
            .accessibilityIdentifier(identificador ?? "")
    }
}

/// O título da folha na barra: 17 semibold e, embaixo, o nome da obra em 13 secundário (mockup). Uma linha cada; na
/// letra grande para perto de 22 pt e mostra o Visualizador de Conteúdo Grande, como o título pequeno da obra.
struct TituloDaFolha: View {
    let titulo: String
    var subtitulo: String?
    @Environment(\.paleta) private var paleta

    var body: some View {
        // Os identificadores vão também em cada texto: na barra, o VoiceOver junta os dois, mas a auditoria de tipo
        // dinâmico do Xcode olha cada um (e a exceção de "para perto de 22 pt" é por identificador).
        VStack(spacing: 0) {
            Text(titulo)
                .font(.headline)
                .foregroundStyle(paleta.cor(.texto))
                .accessibilityIdentifier("tituloDaFolha")
            if let subtitulo {
                Text(subtitulo)
                    .font(.footnote)
                    .foregroundStyle(paleta.cor(.textoSecundario))
                    .accessibilityIdentifier("tituloDaFolha-obra")
            }
        }
        .lineLimit(1)
        .frame(maxWidth: 250)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityShowsLargeContentViewer()
        .accessibilityIdentifier("tituloDaFolha")
    }
}

/// O segmentado de duas opções da folha (Pix | Cartão): o trilho em cápsula e a opção escolhida sólida. Opções de 36 pt,
/// no mínimo 86 de largura, ícone e palavra; na letra grande, uma em cima da outra. VoiceOver lê cada opção como botão,
/// com "1 de 2" e "selecionado", como a cápsula de abas.
struct SegmentadoDaFolha<Opcao: Hashable>: View {
    let opcoes: [(valor: Opcao, rotulo: String, icone: String)]
    @Binding var escolhida: Opcao
    var identificador: String
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho
    @Environment(\.opcoes) private var opcoesDoAparelho

    var body: some View {
        let layout = tamanho.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 4)) : AnyLayout(HStackLayout(spacing: 0))
        layout {
            ForEach(Array(opcoes.enumerated()), id: \.offset) { i, opcao in
                let ativa = opcao.valor == escolhida
                Button {
                    guard !ativa else { return }
                    if opcoesDoAparelho.reduzirMovimento { escolhida = opcao.valor }
                    else { withAnimation(.spring(duration: 0.3, bounce: 0)) { escolhida = opcao.valor } }
                } label: {
                    HStack(spacing: 6) {
                        Image(decorative: opcao.icone).resizable().frame(width: 18, height: 18)
                        Text(opcao.rotulo).font(.body.weight(ativa ? .semibold : .regular))
                    }
                    .fixedSize()
                    .foregroundStyle(paleta.cor(.texto))
                    .padding(.horizontal, 14)
                    .frame(minWidth: 86, minHeight: 36)
                    .frame(maxWidth: tamanho.isAccessibilitySize ? .infinity : nil)
                    .background {
                        if ativa { Capsule().fill(paleta.cor(.segmentadoEscolhido)) }
                    }
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(opcao.rotulo)
                .accessibilityValue("\(i + 1) de \(opcoes.count)")
                .accessibilityAddTraits(ativa ? [.isSelected] : [])
                .accessibilityIdentifier("\(identificador)-\(opcao.rotulo)")
            }
        }
        .padding(3)
        .background(paleta.cor(.segmentadoFundo), in: .capsule)
    }
}
```

Criar `app-ios/Custta/Identidade/TecladoDeValor.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* O teclado de valor (teclado.js, mockup da etapa 2, parte 2): centavos entram pela direita, "00" e apagar, teto de
   R$ 99.999.999,99 (a tecla que passaria do teto é ignorada). As teclas vêm na ordem do telefone, 1 2 3 em cima
   (sugestão aprovada; o site usa a da calculadora). Serve ao gasto, à venda, ao valor estimado e ao orçamento: quem usa
   dá o rótulo do botão ("Avançar", "Pronto") e o que fazer com o valor. O botão fica desabilitado no zero, como no site. */
struct TecladoDeValor: View {
    @Binding var centavos: Int
    let acao: String
    let confirmar: () -> Void
    @Environment(\.paleta) private var paleta

    private static let linhas: [[TeclaDeValor]] = [
        [.digito(1), .digito(2), .digito(3)],
        [.digito(4), .digito(5), .digito(6)],
        [.digito(7), .digito(8), .digito(9)],
        [.duploZero, .digito(0), .apagar],
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            VisorDoValor(centavos: centavos)
            Spacer(minLength: 12)
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(Self.linhas.indices, id: \.self) { i in
                    GridRow {
                        ForEach(Self.linhas[i], id: \.nome) { tecla in
                            // A letra das teclas cresce até o AX2 (mockup): o limite fica por fora, para a medida de dentro
                            // (@ScaledMetric) já ler o tamanho limitado.
                            TeclaDoValor(tecla: tecla) { tocar(tecla) }
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        }
                    }
                }
            }
            Button(acao, action: confirmar)
                .buttonStyle(BotaoDaFolha())
                .disabled(centavos == 0)
                .padding(.top, 14)
                .accessibilityIdentifier("confirmarValor")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func tocar(_ tecla: TeclaDeValor) {
        let novo = aplicarTecla(centavos, tecla)
        guard novo != centavos else { return }
        centavos = novo
        // VoiceOver: o visor é um elemento só; a cada tecla, o valor novo é falado.
        AccessibilityNotification.Announcement(fmtCentavos(novo)).post()
    }
}

/// "R$" e o valor, centrados; o número encolhe para caber (R$ 1.380.000,00 não cabia em 64 pt). Zero fica apagado.
struct VisorDoValor: View {
    let centavos: Int
    @Environment(\.paleta) private var paleta

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            // Tamanhos fixos de propósito (mockup): o número de 64 pt já passa do texto na maior letra e encolhe para caber;
            // os identificadores levam a exceção da auditoria de tipo dinâmico, que olha cada texto.
            Text("R$")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(paleta.cor(.textoSecundario))
                .accessibilityIdentifier("visorDoValor-rs")
            Text(fmtCentavos(centavos))
                .font(.system(size: 64, weight: .bold).monospacedDigit())
                .foregroundStyle(paleta.cor(centavos == 0 ? .textoTerciario : .texto))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .accessibilityIdentifier("visorDoValor-numero")
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Valor")
        .accessibilityValue("R$ \(fmtCentavos(centavos))")
        .accessibilityIdentifier("visorDoValor")
    }
}

/// Uma tecla: 62 pt de altura, raio 20, na cor Tecla; encolhe e acende no toque. A letra (30) e a altura crescem com o
/// tamanho de letra, como o .title; quem usa limita no AX2 (mockup). Com a letra fixa, o limite não faria nada.
struct TeclaDoValor: View {
    let tecla: TeclaDeValor
    let tocar: () -> Void
    @Environment(\.paleta) private var paleta
    @ScaledMetric(relativeTo: .title) private var letra: CGFloat = 30
    @ScaledMetric(relativeTo: .title) private var simbolo: CGFloat = 26
    @ScaledMetric(relativeTo: .title) private var altura: CGFloat = 62

    var body: some View {
        Button(action: tocar) {
            Group {
                switch tecla {
                case .apagar: Image(systemName: "delete.left").font(.system(size: simbolo, weight: .regular))
                case .duploZero: Text("00")
                case .digito(let d): Text(String(d))
                }
            }
            .font(.system(size: letra, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: altura)
        }
        .buttonStyle(EstiloDaTecla())
        .accessibilityLabel(rotulo)
        .accessibilityIdentifier("tecla-\(tecla.nome)")
    }

    private var rotulo: String {
        switch tecla {
        case .apagar: "Apagar"
        case .duploZero: "zero zero"
        case .digito(let d): String(d)
        }
    }
}

private struct EstiloDaTecla: ButtonStyle {
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(paleta.cor(.texto))
            .background(paleta.cor(configuration.isPressed ? .teclaTocada : .tecla), in: .rect(cornerRadius: 20, style: .continuous))
            .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.96 : 1)
            .animation(configuration.isPressed ? .easeOut(duration: 0.1) : .spring(duration: 0.3), value: configuration.isPressed)
    }
}

/// O botão grande da folha ("Avançar", "Salvar", "Confirmar venda"): 56 pt, raio 28, na Marca; desabilitado, apagado.
/// `ambar` é o "Salvar mesmo assim" do gasto repetido.
struct BotaoDaFolha: ButtonStyle {
    var ambar = false
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Environment(\.isEnabled) private var habilitado

    func makeBody(configuration: Configuration) -> some View {
        let fundo: Color = !habilitado ? paleta.cor(.texto).opacity(0.12) : paleta.cor(ambar ? .alerta : .marca)
        configuration.label
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(paleta.cor(!habilitado ? .textoTerciario : ambar ? .sobreAlerta : .sobreMarca))
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, 16)
            .background(fundo, in: .capsule)
            .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.97 : 1)
            .animation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.3), value: configuration.isPressed)
    }
}
```

Em `scripts/cores-app-ios.mjs`:

```diff
--- a/scripts/cores-app-ios.mjs
+++ b/scripts/cores-app-ios.mjs
@@ -74,6 +74,19 @@ export const CORES = {
     // 3,7:1 com a aurora atrás (laudo de leitura); estes passam de 4,5:1 no pior pixel nos quatro combos.
     PositivoNoVidro: ['#8CF0BC', '#084A27'],
     NegativoNoVidro: ['#FFC4CE', '#8A1538'],
+    // Etapa 2 (~/Documents/custta-mockups/nativo/etapa2/parte2.html e parte3.html, aprovados em 13/10): a folha do
+    // sistema e o que vai dentro dela, o arrastar para apagar e a linha que acabou de entrar.
+    Folha: ['#0A1E18E6', '#F4F9F6F0'],              // --folha: fundo da folha (presentationBackground)
+    LinhaDaFolha: ['#12352C', '#FFFFFF'],           // --folha-linha: grupos sólidos da folha; a linha arrastada
+    SeparadorDaFolha: ['#FFFFFF14', '#142B2317'],   // --folha-sep: linha fina entre as linhas de um grupo
+    Tecla: ['#16403A', '#FFFFFF'],                  // --folha-tecla: teclas do teclado de valor
+    TeclaTocada: ['#1E5247', '#E2EFE8'],            // --folha-tecla-on
+    SegmentadoFundo: ['#FFFFFF14', '#142B2312'],    // --seg-fundo: trilho do Pix | Cartão
+    SegmentadoEscolhido: ['#2A6B5C', '#FFFFFF'],    // --seg-on
+    Apagar: ['#C42B3A', '#C22E55'],                 // botão do arrastar (o vermelho do sistema não passa 4,5:1 com branco)
+    SobreApagar: ['#FFFFFF', '#FFFFFF'],
+    SobreAlerta: ['#1F1503', '#FFFFFF'],            // "Salvar mesmo assim", sobre o Alerta
+    Aceso: ['#14B39A38', '#0B7A6824'],              // --aceso: a linha nova, por 2 s
   },
   Azul: {
     Fundo: ['#070C18', '#EEF2F9'],
@@ -126,6 +139,17 @@ export const CORES = {
     GloboAro: ['#648CFF', '#648CFF'],
     PositivoNoVidro: ['#86EFAC', '#084A27'],
     NegativoNoVidro: ['#FFC4CE', '#8A1538'],
+    Folha: ['#0E1628E6', '#F4F9F6F0'],              // no claro, o mockup usa o mesmo das duas peles
+    LinhaDaFolha: ['#1A2640', '#FFFFFF'],
+    SeparadorDaFolha: ['#FFFFFF14', '#142B2317'],
+    Tecla: ['#1F2D4A', '#FFFFFF'],
+    TeclaTocada: ['#2A3B60', '#E7EDF7'],
+    SegmentadoFundo: ['#FFFFFF14', '#142B2312'],
+    SegmentadoEscolhido: ['#34477A', '#FFFFFF'],
+    Apagar: ['#C42B3A', '#C22E55'],
+    SobreApagar: ['#FFFFFF', '#FFFFFF'],
+    SobreAlerta: ['#1F1503', '#FFFFFF'],
+    Aceso: ['#5B8CFF38', '#3560CF24'],
   },
 };
 
@@ -137,6 +161,9 @@ export const PARES_SOLIDOS = [
   ['Texto', 'Campo'], ['SobreMarca', 'Marca'], ['SobreTinta', 'Tinta'], ['FantasmaTexto', 'FantasmaFundo'],
   ['Alerta', 'AlertaFundo'], ['AlertaEtiqueta', 'AlertaFundo'], ['Informacao', 'InformacaoFundo'], ['Positivo', 'PositivoFundo'], ['GoogleTexto', 'GoogleFundo'],
   ['TextoSecundario', 'Campo'], ['PositivoNoVidro', 'Superficie'], ['NegativoNoVidro', 'Superficie'],
+  ['Texto', 'LinhaDaFolha'], ['SecundarioSolido', 'LinhaDaFolha'], ['LinkNoVidro', 'LinhaDaFolha'], ['ErroNoVidro', 'LinhaDaFolha'],
+  ['Alerta', 'LinhaDaFolha'], ['Texto', 'Tecla'], ['Texto', 'TeclaTocada'], ['Texto', 'SegmentadoEscolhido'],
+  ['SobreApagar', 'Apagar'], ['SobreAlerta', 'Alerta'],
 ];
 
 const info = { author: 'xcode', version: 1 };
```

Gerar os arquivos derivados (nunca à mão):

```bash
node scripts/cores-app-ios.mjs
```


- [ ] **Step 4: Ver passar**

Run: `node --test tests/app-ios.test.cjs 2>&1 | grep -E "^ℹ (pass|fail)"` e `xcodebuild build-for-testing "${XB[@]}"`.
Expected: `ℹ fail 0` (os dez pares novos passam de 4,5:1 nos quatro combos); `** TEST BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Assets.xcassets \
  app-ios/Custta/Identidade/Paleta.swift \
  app-ios/Custta/Identidade/PecasDaFolha.swift \
  app-ios/Custta/Identidade/TecladoDeValor.swift \
  scripts/cores-app-ios.mjs \
  tests/app-ios.test.cjs
git commit -m "feat: tokens da folha, peças da folha e teclado de valor" -m "Os tokens da folha entram nos quatro combos com os valores do mockup aprovado, e os pares de texto sobre sólido passam pela guarda de contraste. As peças de dentro da folha e o teclado de valor ficam prontos para o gasto, a venda e a obra: teclas na ordem do telefone, o teto do site, o visor que encolhe e o VoiceOver ouvindo o valor."
```

### Task 22: Folha do gasto em dois passos, aberta pelo + da cápsula

O + volta para a cápsula (lança gasto numa obra que recebe gasto; some em Ajustes e na obra vendida). A folha é um `NavigationStack` dentro da `.sheet`: no gasto novo, o valor e depois os detalhes; na edição, direto nos detalhes, com o valor no mesmo teclado ("Pronto"). Os detalhes seguem o mockup: valor e tópico, pagamento com o cartão (parcelas, juros, resumo e ajuda do site; a data vira "Primeiro vencimento" e cada forma guarda a sua), descrição com as sugestões acima do teclado do sistema, data no calendário, o aviso do repetido com "Salvar mesmo assim" em âmbar e o alerta de `nao-carregado` que mantém o gasto na folha. Fechar pergunta antes quando há o que perder (×, puxar, escapar do VoiceOver). Salvar fecha a folha e pede à tela da obra para mostrar o gasto (a tela atende na Tarefa 23). A folha fica opaca com Reduzir transparência, e o fundo do app para enquanto ela está aberta.

**Files:**
- Create: `app-ios/Custta/Estado/Folhas.swift`
- Modify: `app-ios/Custta/Identidade/CapsulaDeAbas.swift`
- Create: `app-ios/Custta/Telas/FolhaDoGasto.swift`
- Create: `app-ios/Custta/Telas/FolhaEmPassos.swift`
- Modify: `app-ios/Custta/Telas/PrincipalView.swift`
- Test (alterar): `app-ios/CusttaTests/GravacaoDoAppTests.swift`
- Test (alterar): `app-ios/CusttaUITests/AuditoriaUITests.swift`
- Test (criar): `app-ios/CusttaUITests/GastoUITests.swift`

**Interfaces:**
- Consumes: Tarefas 19, 20 e 21.
- Produces: `Folhas` (`aberta: Qual?` com `.novoGasto(obraId:)` e `.editarGasto(obraId:gastoId:)`; `fechar(depois:)`, `fechou()`, `destacar(_:novo:)`, `apagar(_:)`, `Destaque`, `PedidoDeApagar`); `View.folhaDoApp(perguntar:pergunta:descartar:fechar:)`, `View.passoDaFolha(_:subtitulo:fechar:raiz:)`, `PonteDeFechamento`, `ControladorDaPonte.vivas` (Debug); `AcaoDoMais`, `CapsulaDeAbas(escolhida:abas:mais:)`; `FolhaDoGasto(obraId:gastoId:)`, `RascunhoDoGasto`, `CampoDeData(iso:minimo:maximo:)`, `IconeDoTopico`, `PerguntaDeApagar`. Ganchos de Debug: `-custta.folha valor|detalhes|cartao|topicos|repetido|editar:<id>`, `-custta.contarPontes YES`. Identificadores: `botaoMais`, `fecharFolha`, `linhaValor`, `linhaTopico`, `pagamento-Pix`, `pagamento-Cartão`, `parcelas`, `juros`, `resumoDoCartao`, `descricao`, `sugestao-<texto>`, `data`, `avisoRepetido`, `avisoParcela`, `apagarGasto`, `salvarGasto`, `topico-<id>`, `usado-<id>`, `pontesVivas`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaTests/GravacaoDoAppTests.swift`:

```diff
--- a/app-ios/CusttaTests/GravacaoDoAppTests.swift
+++ b/app-ios/CusttaTests/GravacaoDoAppTests.swift
@@ -4,7 +4,7 @@ import Testing
 import CusttaNucleo
 
 /* O que as telas que gravam usam (etapa 2): o `gravar` do modelo (troca o estado na hora e sobe o documento; recusa
-   sem ver os dados; nada sobe quando a obra sumiu). */
+   sem ver os dados; nada sobe quando a obra sumiu), o vaivém das folhas e o rascunho do gasto. */
 @MainActor
 struct GravacaoDoAppTests {
     func montar(semRede: Bool = false, dados: ValorJSON? = DadosDeExemplo.blob) -> (ModeloApp, TransporteFalsoApp, ContaFalsa) {
@@ -56,4 +56,83 @@ struct GravacaoDoAppTests {
         #expect(m.gravar { $0 } == .semConta)
         #expect(transporte.gravacoes == 0)
     }
+
+    @Test func folhasRodamODepoisSoQuandoAFolhaDesce() {
+        let folhas = Folhas()
+        folhas.aberta = .novoGasto(obraId: "o1")
+        var rodou = false
+        folhas.fechar { rodou = true }
+        #expect(folhas.aberta == nil && !rodou, "o depois espera a folha terminar de descer")
+        folhas.fechou()
+        #expect(rodou)
+        folhas.fechou()
+        folhas.destacar(["a"], novo: true)
+        let primeiro = folhas.destaque
+        folhas.destacar(["a"], novo: true)
+        #expect(folhas.destaque != primeiro, "o mesmo gasto acende de novo")
+        folhas.apagar(.init(obraId: "o1", gastoId: "g", grupoId: nil))
+        #expect(folhas.pedidoDeApagar?.gastoId == "g")
+    }
+
+    func obra(_ gastos: [[String: ValorJSON]]) -> Obra {
+        Obra(arvore: ["id": .texto("o1"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
+                      "gastos": .lista(gastos.map(ValorJSON.objeto))])
+    }
+
+    @Test func rascunhoDoGastoNovoComecaComoOMockup() {
+        let o = obra([["id": .texto("a"), "valor": .numero(1), "topico": .texto("pintura"), "descricao": .texto("Tinta"),
+                       "data": .texto("2026-10-01"), "pagamento": .texto("pix")]])
+        let r = RascunhoDoGasto(obra: o, editado: nil, todas: [o], proprios: [], hoje: "2026-01-31")
+        #expect(r.topico == "pintura", "o tópico do último gasto da obra")
+        #expect(r.pagamento == "pix" && r.data == "2026-01-31")
+        r.pagamento = "cartao"
+        #expect(r.data == "2026-02-28", "o cartão começa um mês à frente, com o fim do mês ajustado")
+        r.data = "2026-03-10"
+        r.pagamento = "pix"
+        #expect(r.data == "2026-01-31", "cada forma de pagamento guarda a sua data")
+        #expect(!r.temOQuePerder, "no valor ainda, fechar não pergunta")
+        r.passouDoValor = true
+        #expect(r.temOQuePerder)
+    }
+
+    @Test func rascunhoDaEdicaoPerguntaSoSeMudou() {
+        let g: [String: ValorJSON] = ["id": .texto("p1"), "valor": .numero(615), "topico": .texto("revest"), "descricao": .texto("Piso"),
+                                      "data": .texto("2026-10-05"), "pagamento": .texto("cartao"), "grupoId": .texto("gr"),
+                                      "parcela": .objeto(["n": .numero(4), "de": .numero(10)])]
+        let o = obra([g])
+        let r = RascunhoDoGasto(obra: o, editado: o.gastos[0], todas: [o], proprios: [], hoje: "2026-10-13")
+        #expect(r.centavos == 61_500 && r.parcela == Parcela(n: 4, de: 10) && !r.cartaoNovo)
+        #expect(!r.temOQuePerder)
+        r.descricao = "Piso novo"
+        #expect(r.temOQuePerder)
+        r.descricao = "Piso"
+        #expect(!r.temOQuePerder, "voltou ao que era")
+        r.data = "2026-10-06"
+        #expect(r.entrada.data == "2026-10-06", "na edição a data é uma só, qualquer que seja o pagamento")
+    }
+
+    @Test func pagamentoDesconhecidoFicaComoVeio() {
+        let o = obra([["id": .texto("b"), "valor": .numero(5), "topico": .texto("outros"), "descricao": .texto("Taxa"),
+                       "data": .texto("2026-10-01"), "pagamento": .texto("boleto")]])
+        let r = RascunhoDoGasto(obra: o, editado: o.gastos[0], todas: [o], proprios: [], hoje: "2026-10-13")
+        #expect(r.entrada.pagamento == "boleto", "o site regrava o que estava enquanto nenhuma forma é escolhida")
+    }
+
+    @Test func todosOsTopicosSemRepetirOsUsados() {
+        let o = obra([["id": .texto("a"), "valor": .numero(1), "topico": .texto("pintura"), "descricao": .texto(""),
+                       "data": .texto("2026-10-01"), "pagamento": .texto("pix")]])
+        let r = RascunhoDoGasto(obra: o, editado: nil, todas: [o], proprios: [], hoje: "2026-10-13")
+        #expect(r.usados.map(\.id) == ["pintura"])
+        #expect(r.topicosSemOsUsados.count == 20 && !r.topicosSemOsUsados.contains { $0.id == "pintura" })
+    }
+
+    @Test func descricaoParaEm500UnidadesSemPartirEmoji() {
+        let o = obra([])
+        let r = RascunhoDoGasto(obra: o, editado: nil, todas: [o], proprios: [], hoje: "2026-10-13")
+        r.descricao = String(repeating: "a", count: 499) + "🧱🧱"
+        r.limitarDescricao()
+        #expect(r.descricao.utf16.count == 499, "o tijolo (2 unidades) não cabe inteiro e sai")
+        r.descricao = "  Cimento  "
+        #expect(r.entrada.descricao == "Cimento", "a descrição sai aparada, como no site")
+    }
 }
```

Em `app-ios/CusttaUITests/AuditoriaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -28,7 +28,7 @@ final class AuditoriaUITests: XCTestCase {
     /// navegação, da cápsula, do indicador de início ou da borda de rolagem (contraste: ele é auditado quando
     /// está à vista). Os rótulos da própria cápsula entram na auditoria de contraste.
     @MainActor private func auditar(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType) throws {
-        let abas = ["aba-obras", "aba-ajustes"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
+        let abas = ["aba-obras", "aba-ajustes", "botaoMais"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
         let fundoDaTela = abas.isEmpty ? app.frame.maxY : min(abas.map(\.minY).min()!, app.frame.maxY - borda)
         let barra = app.navigationBars.firstMatch
         let topoDoConteudo = barra.exists ? max(barra.frame.maxY, borda) : 0
```

Criar `app-ios/CusttaUITests/GastoUITests.swift`:

```swift
import XCTest

/* O gasto (etapa 2, PR 2), na obra da vitrine (46 lançamentos): lançar no Pix (com e sem rede), descartar pelo × e
   puxando a folha, o voltar pela borda dentro da folha, o repetido e o `nao-carregado`. */
@MainActor
final class GastoUITests: XCTestCase {
    private func abrirObra(_ argumentos: [String] = []) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: argumentos)
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        return app
    }

    /// + → o valor no teclado → "Avançar".
    private func lancarValor(_ app: XCUIApplication, _ teclas: String) {
        app.buttons["botaoMais"].tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        for t in teclas { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForExistence(timeout: 5))
    }

    private func escrever(_ app: XCUIApplication, _ texto: String, apagando: Int = 0) {
        let campo = app.textFields["descricao"]
        for _ in 0..<5 where !app.keyboards.firstMatch.exists { campo.tap(); sleep(1) }
        if apagando > 0 { campo.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: apagando)) }
        campo.typeText(texto)
    }

    private func comRotulo(_ app: XCUIApplication, comecando texto: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", texto))
    }

    private func puxarFolha(_ app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.92)),
                   withVelocity: .fast, thenHoldForDuration: 0)
    }

    func testLancarNoPixAcendeALinhaNova() {
        let app = abrirObra()
        lancarValor(app, "138000")
        XCTAssertEqual(app.elemento("linhaValor").value as? String, "R$\u{a0}1.380,00")
        escrever(app, "Areia média, 6 m³")
        app.buttons["salvarGasto"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5), "a folha desce")
        XCTAssertTrue(comRotulo(app, comecando: "Areia média, 6 m³").firstMatch.waitForExistence(timeout: 5), "a linha nova aparece")
        XCTAssertTrue(app.elemento("lancamentos").label.contains("47"), app.elemento("lancamentos").label)
    }

    func testLancarSemRedeEntraNaLista() {
        let app = abrirApp(conta: "senha", dados: "vitrine", rede: "offline", abrir: "obra:v1")
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
        lancarValor(app, "100")
        escrever(app, "Areia sem rede")
        app.buttons["salvarGasto"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
        XCTAssertTrue(comRotulo(app, comecando: "Areia sem rede").firstMatch.waitForExistence(timeout: 5), "sem rede, o gasto entra na lista")
        XCTAssertEqual(app.elemento("indicadorSincronizacao").label, "Sem conexão", "e espera a rede na fila")
    }

    func testFecharDepoisDoValorPerguntaAntes() {
        let app = abrirObra()
        lancarValor(app, "1")
        app.buttons["fecharFolha"].tap()
        let alerta = app.alerts["Você já preencheu este gasto."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        alerta.buttons["Continuar editando"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").exists, "continua na folha")
        app.buttons["fecharFolha"].tap()
        app.alerts["Você já preencheu este gasto."].buttons["Descartar gasto"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("lancamentos").label.contains("46"), "nada foi gravado")
    }

    func testPuxarAFolhaPreenchidaPerguntaESemValorFecha() {
        let app = abrirObra(["-custta.contarPontes", "YES"])
        lancarValor(app, "1")
        puxarFolha(app)
        XCTAssertTrue(app.alerts["Você já preencheu este gasto."].waitForExistence(timeout: 4), "puxar com valor pergunta")
        app.alerts["Você já preencheu este gasto."].buttons["Descartar gasto"].tap()
        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
        app.buttons["botaoMais"].tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        XCTAssertEqual(app.elemento("visorDoValor").value as? String, "R$ 0,00", "reabre limpa")
        puxarFolha(app)
        XCTAssertTrue(app.elemento("visorDoValor").waitForNonExistence(timeout: 5), "sem valor, puxar fecha sem perguntar")
        let pontes = app.elemento("pontesVivas")
        let zerou = NSPredicate(format: "label == 'pontes 0'")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: zerou, object: pontes)], timeout: 5), .completed,
                       "nenhuma ponte presa depois de fechar: \(pontes.label)")
    }

    func testVoltarPelaBordaDentroDaFolha() {
        let app = abrirObra()
        lancarValor(app, "1")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5), "a borda volta ao valor, dentro da folha")
        XCTAssertTrue(app.elemento("tituloDaFolha").exists, "a folha continua aberta")
    }

    func testRepetidoPedeOSegundoToque() {
        let app = abrirObra()
        for vez in 0..<2 {
            lancarValor(app, "10000")
            escrever(app, "Areia fina")
            app.buttons["salvarGasto"].tap()
            if vez == 1 {
                XCTAssertTrue(app.elemento("avisoRepetido").waitForExistence(timeout: 3), "o segundo igual avisa")
                XCTAssertEqual(app.buttons["salvarGasto"].label, "Salvar mesmo assim")
                app.buttons["salvarGasto"].tap()
            }
            XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
        }
        let linhas = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'gasto-' AND label BEGINSWITH 'Areia fina'"))
        XCTAssertEqual(Set(linhas.allElementsBoundByIndex.map(\.identifier)).count, 2, "os dois gastos iguais foram gravados")
    }

    func testNaoCarregadoAvisaEMantemAFolha() {
        let app = abrirObra(["-custta.recusarGravacao", "nao-carregado"])
        lancarValor(app, "138000")
        app.buttons["salvarGasto"].tap()
        let alerta = app.alerts["Carregando suas obras, tente em instantes."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
        XCTAssertTrue(alerta.staticTexts["O gasto continua aqui; nada foi salvo ainda."].exists)
        alerta.buttons["OK"].tap()
        XCTAssertEqual(app.elemento("linhaValor").value as? String, "R$\u{a0}1.380,00", "o gasto continua na folha")
    }
}
```


- [ ] **Step 2: Ver falhar**

Run: `xcodebuild build-for-testing "${XB[@]}"` e `xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/GastoUITests`
Expected: não compila o `CusttaTests` (`cannot find 'Folhas' in scope`, `cannot find 'RascunhoDoGasto' in scope`); sem eles, os testes de tela falham esperando o `botaoMais`.

- [ ] **Step 3: Implementar**

Criar `app-ios/Custta/Estado/Folhas.swift`:

```swift
import Foundation
import Observation

/* A folha aberta por cima das abas (o + da cápsula, o toque numa linha de gasto) e o que a tela da obra faz quando ela
   termina de descer: rolar até o gasto que acabou de entrar e acendê-lo, ou apagar com a animação à vista. Mora acima
   das abas, como o caminho de Obras, porque o + é da cápsula. */
@MainActor @Observable
final class Folhas {
    enum Qual: Identifiable, Hashable {
        case novoGasto(obraId: String)
        case editarGasto(obraId: String, gastoId: String)

        var id: Self { self }
    }

    /// O que a tela da obra mostra depois de salvar: os gastos que entraram (acendem por 2 s; `novo` põe a etiqueta) e o
    /// primeiro deles (a lista rola até ele). `vez` muda a cada salvar, para o mesmo gasto acender de novo.
    struct Destaque: Equatable {
        let ids: [String]
        let novo: Bool
        let vez: Int
    }

    /// "Apagar gasto" confirmado na folha de edição: a tela da obra apaga quando a folha termina de descer, com a mesma
    /// animação do arrastar. `grupoId` apaga a compra toda.
    struct PedidoDeApagar: Equatable {
        let obraId: String
        let gastoId: String
        let grupoId: String?
        var vez = 0
    }

    var aberta: Qual?
    private(set) var destaque: Destaque?
    private(set) var pedidoDeApagar: PedidoDeApagar?
    @ObservationIgnored private var depoisDeFechar: (() -> Void)?
    @ObservationIgnored private var vezes = 0

    /// Fecha a folha; `depois` roda quando ela terminar de descer (o onDismiss da .sheet).
    func fechar(depois: (() -> Void)? = nil) {
        depoisDeFechar = depois
        aberta = nil
    }

    /// O onDismiss da .sheet.
    func fechou() {
        let f = depoisDeFechar
        depoisDeFechar = nil
        f?()
    }

    func destacar(_ ids: [String], novo: Bool) {
        vezes += 1
        destaque = Destaque(ids: ids, novo: novo, vez: vezes)
    }

    func apagar(_ pedido: PedidoDeApagar) {
        vezes += 1
        var p = pedido
        p.vez = vezes
        pedidoDeApagar = p
    }
}
```

Em `app-ios/Custta/Identidade/CapsulaDeAbas.swift`:

```diff
--- a/app-ios/Custta/Identidade/CapsulaDeAbas.swift
+++ b/app-ios/Custta/Identidade/CapsulaDeAbas.swift
@@ -6,7 +6,14 @@ import SwiftUI
    dois tokens com qualquer coisa passando por baixo; na lente de vidro, a lista rolada derrubava o "Obras"
    para 3,8:1 no escuro. O que a barra do sistema dava de graça vem à mão: VoiceOver lê o nome,
    "1 de 2" e "selecionada", alvo de 44 pt e o Visualizador de Conteúdo Grande no lugar de crescer com a
-   letra. Na etapa 1, duas abas e nenhum +. */
+   letra. O + volta na etapa 2, ao lado da cápsula e na Tinta (mockup): lança gasto na obra; some onde não há o que
+   criar (Ajustes), como o do site, e a cápsula ocupa a largura toda. */
+
+/// O + ao lado da cápsula: o rótulo para o VoiceOver ("Lançar gasto") e o que ele faz.
+struct AcaoDoMais {
+    let rotulo: String
+    let acao: () -> Void
+}
 
 enum Aba: String, CaseIterable, Identifiable, Sendable {
     case obras
@@ -20,11 +27,37 @@ enum Aba: String, CaseIterable, Identifiable, Sendable {
 struct CapsulaDeAbas: View {
     @Binding var escolhida: Aba
     var abas: [Aba] = Aba.allCases
+    var mais: AcaoDoMais?
     @Environment(\.paleta) private var paleta
     @Environment(\.opcoes) private var opcoes
     @Namespace private var pilula
 
     var body: some View {
+        HStack(spacing: 10) {
+            abasNaCapsula
+            if let mais {
+                Button(action: mais.acao) {
+                    Image(systemName: "plus")
+                        .font(.system(size: 26, weight: .medium))
+                        .foregroundStyle(paleta.cor(.sobreTinta))
+                        .frame(width: 62, height: 62)
+                        .background(paleta.cor(.tinta), in: .circle)
+                        .contentShape(.circle)
+                }
+                .buttonStyle(.plain)
+                .accessibilityLabel(mais.rotulo)
+                .accessibilityIdentifier("botaoMais")
+                .accessibilityShowsLargeContentViewer { Label(mais.rotulo, systemImage: "plus") }
+                .transition(.scale(scale: 0.6).combined(with: .opacity))
+            }
+        }
+        .dynamicTypeSize(.large)
+        .padding(.horizontal, 20)
+        .padding(.bottom, 22)               // da borda da tela (mockup aprovado), como a barra de abas do sistema
+        .animation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.35, bounce: 0), value: mais != nil)
+    }
+
+    private var abasNaCapsula: some View {
         HStack(spacing: 0) {
             ForEach(Array(abas.enumerated()), id: \.element) { indice, aba in
                 let ativa = aba == escolhida
@@ -55,8 +88,5 @@ struct CapsulaDeAbas: View {
         .padding(4)
         .frame(height: 62)
         .superficie(.navegacao, em: .capsule)
-        .dynamicTypeSize(.large)
-        .padding(.horizontal, 20)
-        .padding(.bottom, 22)               // da borda da tela (mockup aprovado), como a barra de abas do sistema
     }
 }
```

Criar `app-ios/Custta/Telas/FolhaDoGasto.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* A folha do gasto (mockup da etapa 2, parte 2; formGasto do site). Gasto novo: o valor no teclado de valor e
   "Avançar" empurra os detalhes, na ordem do site (valor, tópico, pagamento, descrição e data), com "Salvar" fixo
   embaixo. Editar: direto nos detalhes; o valor abre o mesmo teclado ("Pronto"); numa parcela, o aviso do site no lugar
   do pagamento; "Apagar gasto" no fim. O que vira gasto e as mensagens vêm do núcleo (as regras do dados.js); a tela só
   guarda o rascunho e decide para onde ir. */

enum PassoDoGasto: Hashable {
    case detalhes
    case valor
    case topicos
}

/// O formulário enquanto a folha está aberta: começa do gasto em edição, ou do vazio do gasto novo, e só vira gasto no
/// "Salvar".
@MainActor @Observable
final class RascunhoDoGasto {
    let obraId: String
    let editado: Gasto?
    let topicos: [Topico]
    let usados: [Topico]
    let indice: IndiceDeSugestoes
    var centavos: Int
    var topico: String
    var pagamento: String
    var parcelas = 1
    var juros = "0"
    var descricao: String
    /// Cada forma de pagamento guarda a sua data no gasto novo (app.js:996, 1022-1026): o Pix começa hoje; o cartão, um
    /// mês à frente. Na edição a data é uma só.
    private var datas: [String: String]
    /// Repetido: a assinatura do primeiro toque no "Salvar". O segundo toque com a mesma salva; mexer em qualquer campo
    /// muda a assinatura e o aviso some.
    var assinaturaAvisada: String?
    /// Gasto novo: passou do valor, e fechar passa a perguntar.
    var passouDoValor = false
    private var inicial: [String] = []

    init(obra: Obra, editado: Gasto?, todas: [Obra], proprios: [TopicoProprio], hoje: String) {
        obraId = obra.id
        self.editado = editado
        topicos = topicosDoFormulario(proprios)
        usados = usadosNestaObra(obra, topicos: topicos)
        indice = IndiceDeSugestoes(todas, obraId: obra.id, ignorarId: editado?.id)
        if let g = editado {
            centavos = reaisParaCentavos(g.valor)
            topico = g.topico
            // Pagamento fora de Pix e Cartão fica como veio até a pessoa escolher (o site regrava o que estava).
            pagamento = g.pagamento.isEmpty ? "pix" : g.pagamento
            descricao = g.descricao
            datas = ["pix": g.data, "cartao": g.data]
        } else {
            centavos = 0
            topico = topicoInicial(obra, topicos: topicos)
            pagamento = "pix"
            descricao = ""
            datas = ["pix": hoje, "cartao": addMesesClampado(hoje, 1)]
        }
        inicial = foto
    }

    var data: String {
        get { datas[pagamento] ?? "" }
        set {
            if editado == nil { datas[pagamento] = newValue } else { datas = ["pix": newValue, "cartao": newValue] }
        }
    }

    /// Parcela de uma compra no cartão: a edição vale só para ela, e o pagamento não muda.
    var parcela: Parcela? { editado?.grupoId != nil ? editado?.parcela : nil }

    /// O cartão parcelado só existe no gasto novo (no site, o bloco fica escondido na edição).
    var cartaoNovo: Bool { editado == nil && pagamento == "cartao" }

    /// "Todos" na lista de tópicos, sem os de "Usados nesta obra" (o mockup não repete).
    var topicosSemOsUsados: [Topico] { topicos.filter { t in !usados.contains { $0.id == t.id } } }

    var entrada: EntradaDoGasto {
        EntradaDoGasto(valor: centavosParaReais(centavos), topico: topico, descricao: aparadoJS(descricao), data: data,
                       pagamento: pagamento, parcelas: parcelas, juros: lerTaxaCartao(juros))
    }

    /// O resumo ao vivo do cartão (app.js:1007-1008).
    var resumoDoCartao: String {
        let e = entrada
        return CusttaNucleo.resumoDoCartao(parcelamentoCartao(e.valor, e.parcelas, e.juros, e.data))
    }

    /// Fechar pergunta antes: no gasto novo, depois de passar do valor; na edição, se algo mudou.
    var temOQuePerder: Bool { editado == nil ? passouDoValor : foto != inicial }

    private var foto: [String] {
        [String(centavos), topico, pagamento, String(parcelas), juros, descricao, datas["pix"] ?? "", datas["cartao"] ?? ""]
    }

    /// A descrição tem até 500 unidades UTF-16, como o `maxlength` do site.
    func limitarDescricao() {
        guard descricao.utf16.count > Limites.descricao else { return }
        var r = ""
        for c in descricao where r.utf16.count + String(c).utf16.count <= Limites.descricao { r.append(c) }
        descricao = r
    }
}

struct FolhaDoGasto: View {
    let obraId: String
    let gastoId: String?
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @State private var rascunho: RascunhoDoGasto?
    @State private var caminho: [PassoDoGasto] = []

    var body: some View {
        Group {
            if let rascunho {
                FolhaDoGastoAberta(rascunho: rascunho, caminho: $caminho)
            } else {
                Color.clear
            }
        }
        .onAppear(perform: montar)
        // A obra ou o gasto sumiram (apagados em outro aparelho) com a folha aberta: não há onde gravar; a folha fecha.
        .onChange(of: existe) { _, agora in if !agora { folhas.fechar() } }
    }

    private var existe: Bool {
        guard let obra = modelo.sincronizador.estado.obras.first(where: { $0.id == obraId }) else { return false }
        return gastoId.map { id in obra.gastos.contains { $0.id == id } } ?? true
    }

    private func montar() {
        guard rascunho == nil else { return }
        let estado = modelo.sincronizador.estado
        guard let obra = estado.obras.first(where: { $0.id == obraId }) else { folhas.fechar(); return }
        let editado = gastoId.flatMap { id in obra.gastos.first { $0.id == id } }
        if gastoId != nil && editado == nil { folhas.fechar(); return }
        rascunho = RascunhoDoGasto(obra: obra, editado: editado, todas: estado.obras, proprios: estado.config.topicosProprios,
                                   hoje: dataLocalISO(.now, fuso: .current))
        #if DEBUG
        if editado == nil, let r = rascunho { abrirNoPassoDeTeste(r, obra: obra) }
        #endif
    }
}

#if DEBUG
extension FolhaDoGasto {
    /// Laudo e conferência visual (`-custta.folha <passo>`, com o PrincipalView): a folha do gasto novo já preenchida.
    private func abrirNoPassoDeTeste(_ r: RascunhoDoGasto, obra: Obra) {
        switch UserDefaults.standard.string(forKey: "custta.folha") {
        case "valor":
            r.centavos = 138_000
        case "detalhes", "topicos":
            r.centavos = 138_000
            r.passouDoValor = true
            caminho = UserDefaults.standard.string(forKey: "custta.folha") == "topicos" ? [.detalhes, .topicos] : [.detalhes]
        case "cartao":
            r.centavos = 498_000
            r.pagamento = "cartao"
            r.parcelas = 10
            r.passouDoValor = true
            caminho = [.detalhes]
        case "repetido":
            // O mesmo gasto que já existe na obra (a regra do site avisa) e o aviso já mostrado.
            guard let g = obra.gastos.first(where: { !$0.descricao.isEmpty && $0.grupoId == nil }) else { return }
            r.centavos = reaisParaCentavos(g.valor)
            r.topico = g.topico
            r.descricao = g.descricao
            r.data = g.data
            r.passouDoValor = true
            if case .success(let c) = conferirGasto(r.entrada, editado: nil, hoje: dataLocalISO(.now, fuso: .current)) {
                r.assinaturaAvisada = assinaturaDoGasto(obraId: obra.id, entrada: r.entrada, conferido: c)
            }
            caminho = [.detalhes]
        default:
            break
        }
    }
}
#endif

private struct FolhaDoGastoAberta: View {
    @Bindable var rascunho: RascunhoDoGasto
    @Binding var caminho: [PassoDoGasto]
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas

    private var nomeDaObra: String {
        modelo.sincronizador.estado.obras.first { $0.id == rascunho.obraId }?.nome ?? ""
    }

    var body: some View {
        NavigationStack(path: $caminho) {
            Group {
                if rascunho.editado == nil {
                    PassoDoValor(rascunho: rascunho, titulo: "Valor do gasto", subtitulo: nomeDaObra, acao: "Avançar", raiz: true) {
                        rascunho.passouDoValor = true
                        caminho = [.detalhes]
                    }
                } else {
                    PassoDosDetalhes(rascunho: rascunho, caminho: $caminho, subtitulo: nomeDaObra, raiz: true)
                }
            }
            .navigationDestination(for: PassoDoGasto.self) { passo in
                switch passo {
                case .detalhes:
                    PassoDosDetalhes(rascunho: rascunho, caminho: $caminho, subtitulo: nomeDaObra, raiz: false)
                case .valor:
                    PassoDoValor(rascunho: rascunho, titulo: "Valor", subtitulo: nomeDaObra, acao: "Pronto", raiz: false) {
                        caminho.removeLast()
                    }
                case .topicos:
                    ListaDeTopicos(rascunho: rascunho) { caminho.removeLast() }
                }
            }
        }
        .folhaDoApp(perguntar: rascunho.temOQuePerder, pergunta: "Você já preencheu este gasto.", descartar: "Descartar gasto") {
            folhas.fechar()
        }
    }
}

/// O passo do valor: o teclado de valor ocupando a folha.
private struct PassoDoValor: View {
    @Bindable var rascunho: RascunhoDoGasto
    let titulo: String
    let subtitulo: String
    let acao: String
    let raiz: Bool
    let confirmar: () -> Void

    var body: some View {
        TecladoDeValor(centavos: $rascunho.centavos, acao: acao, confirmar: confirmar)
            .passoDaFolha(titulo, subtitulo: subtitulo, fechar: raiz ? .esquerda : nil, raiz: raiz)
    }
}

/// Os detalhes: valor, tópico, pagamento (com o cartão), descrição e data; "Salvar" fixo embaixo.
private struct PassoDosDetalhes: View {
    @Bindable var rascunho: RascunhoDoGasto
    @Binding var caminho: [PassoDoGasto]
    let subtitulo: String
    let raiz: Bool
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @FocusState private var foco: Campo?
    @State private var erroDoCartao: String?
    @State private var erroDaDescricao: String?
    @State private var naoCarregado = false
    @State private var contaReal = false
    @State private var apagando = false
    @State private var sugestaoEscolhida: String?

    enum Campo: Hashable { case juros, descricao }

    var body: some View {
        ScrollViewReader { leitor in
            ScrollView {
                VStack(spacing: 20) {
                    GrupoDaFolha {
                        linhaDoValor
                        SeparadorDaFolha()
                        linhaDoTopico
                    }
                    pagamento
                    if let c = rascunho.editado.flatMap(condicoesOriginais) { NotaDaFolha(texto: c) }
                    descricao.id("descricao")
                    GrupoDaFolha {
                        let rotulo = rascunho.cartaoNovo ? "Primeiro vencimento" : "Data"
                        LinhaDaFolhaComRotulo(rotulo: rotulo) {
                            CampoDeData(iso: $rascunho.data, rotulo: rotulo)
                        }
                    }
                    if avisoDeRepetido { NotaDaFolha(texto: CusttaNucleo.avisoDeRepetido, cor: .alerta, identificador: "avisoRepetido") }
                    if rascunho.editado != nil {
                        GrupoDaFolha {
                            Button("Apagar gasto") { apagando = true }
                                .foregroundStyle(paleta.cor(.erroNoVidro))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .accessibilityIdentifier("apagarGasto")
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            // O teclado decimal dos juros não tem tecla de fechar.
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if foco == .juros {
                        Spacer()
                        Button("OK") { foco = nil }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // O identificador no próprio botão: depois do fundo (que desce até a borda da tela, atrás do teclado), o
                // quadro de acessibilidade ia junto, e o toque do VoiceOver e do XCUITest caía no teclado.
                Button(avisoDeRepetido ? "Salvar mesmo assim" : "Salvar", action: salvar)
                    .buttonStyle(BotaoDaFolha(ambar: avisoDeRepetido))
                    .accessibilityIdentifier("salvarGasto")
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 8)
                    .background {
                        LinearGradient(stops: [.init(color: paleta.cor(.folha), location: 0.62), .init(color: paleta.cor(.folha).opacity(0), location: 1)],
                                       startPoint: .bottom, endPoint: .top)
                            .ignoresSafeArea()
                            .accessibilityHidden(true)
                    }
            }
            // Com o teclado do sistema, a descrição sobe para as sugestões caberem acima dele.
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                guard foco == .descricao else { return }
                withAnimation(opcoes.reduzirMovimento ? nil : .easeOut(duration: 0.25)) { leitor.scrollTo("descricao", anchor: .top) }
            }
        }
        .passoDaFolha(rascunho.editado == nil ? "Novo gasto" : "Editar gasto", subtitulo: subtitulo,
                      fechar: raiz ? .esquerda : .direita, raiz: raiz)
        .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("O gasto continua aqui; nada foi salvo ainda.")
        }
        .alert(ContaDeTeste.titulo, isPresented: $contaReal) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(ContaDeTeste.mensagem)
        }
        .modifier(PerguntaDeApagar(apresentada: $apagando, obraId: rascunho.obraId, gasto: rascunho.editado) { pedido in
            folhas.fechar { folhas.apagar(pedido) }
        })
    }

    private var avisoDeRepetido: Bool {
        guard let a = rascunho.assinaturaAvisada, case .success(let c) = conferirGasto(rascunho.entrada, editado: rascunho.editado,
                                                                                        hoje: dataLocalISO(.now, fuso: .current)) else { return false }
        return a == assinaturaDoGasto(obraId: rascunho.obraId, entrada: rascunho.entrada, conferido: c)
    }

    private var linhaDoValor: some View {
        Button {
            if rascunho.editado == nil { caminho.removeAll() } else { caminho.append(.valor) }
        } label: {
            LinhaDaFolhaComRotulo(rotulo: "Valor", altura: 60) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("R$").font(.callout.weight(.semibold)).foregroundStyle(paleta.cor(.secundarioSolido))
                    ValorEmDinheiro(texto: fmtCentavos(rascunho.centavos), fonte: .title2.weight(.bold))
                        .foregroundStyle(paleta.cor(.texto))
                    SetaDaLinha()
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Valor")
        .accessibilityValue(moeda(centavosParaReais(rascunho.centavos)))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("linhaValor")
    }

    private var linhaDoTopico: some View {
        let t = mapaDeTopicos(modelo.sincronizador.estado.config.topicosProprios)[rascunho.topico]
        return Button { caminho.append(.topicos) } label: {
            LinhaDaFolhaComRotulo(rotulo: "Tópico") {
                HStack(spacing: 10) {
                    IconeDoTopico(icone: t?.icone ?? "etiqueta")
                    Text(t?.nome ?? rascunho.topico).foregroundStyle(paleta.cor(.texto)).multilineTextAlignment(.trailing)
                    SetaDaLinha()
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tópico")
        .accessibilityValue(t?.nome ?? rascunho.topico)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("linhaTopico")
    }

    @ViewBuilder private var pagamento: some View {
        if let p = rascunho.parcela {
            GrupoDaFolha {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(decorative: "Icones/cartao").resizable().frame(width: 20, height: 20)
                        .foregroundStyle(paleta.cor(.linkNoVidro))
                    Text(avisoDaParcela(p)).foregroundStyle(paleta.cor(.texto)).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("avisoParcela")
            }
        } else {
            VStack(spacing: 8) {
                GrupoDaFolha {
                    LinhaDaFolhaComRotulo(rotulo: "Pagamento") {
                        SegmentadoDaFolha(opcoes: [("pix", "Pix", "Icones/raio"), ("cartao", "Cartão", "Icones/cartao")],
                                          escolhida: $rascunho.pagamento, identificador: "pagamento")
                    }
                    if rascunho.cartaoNovo {
                        SeparadorDaFolha()
                        LinhaDaFolhaComRotulo(rotulo: "Parcelas") {
                            Picker("Parcelas", selection: $rascunho.parcelas) {
                                ForEach(1...36, id: \.self) { Text("\($0)x").tag($0) }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .tint(paleta.cor(.linkNoVidro))
                            .padding(.horizontal, 4)
                            .frame(minHeight: 36)
                            .background(paleta.cor(.segmentadoFundo), in: .rect(cornerRadius: 12, style: .continuous))
                            .accessibilityIdentifier("parcelas")
                        }
                        SeparadorDaFolha()
                        LinhaDaFolhaComRotulo(rotulo: "Juros ao mês") {
                            HStack(spacing: 4) {
                                TextField("0", text: $rascunho.juros)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($foco, equals: .juros)
                                    .frame(minWidth: 44, maxWidth: 90)
                                    .accessibilityLabel("Juros ao mês, em porcentagem")
                                    .accessibilityIdentifier("juros")
                                Text("%").foregroundStyle(paleta.cor(.secundarioSolido)).accessibilityHidden(true)
                            }
                            .padding(.horizontal, 12)
                            .frame(minHeight: 36)
                            .background(paleta.cor(.segmentadoFundo), in: .rect(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                if rascunho.cartaoNovo {
                    NotaDaFolha(texto: rascunho.resumoDoCartao, cor: .texto, identificador: "resumoDoCartao")
                        .accessibilityAddTraits(.updatesFrequently)
                    if let erroDoCartao { NotaDaFolha(texto: erroDoCartao, cor: .erroNoVidro, identificador: "erroDoCartao") }
                    NotaDaFolha(texto: ajudaDoCartao)
                }
            }
        }
    }

    private var descricao: some View {
        let termo = rascunho.descricao
        let sugestoes = foco == .descricao && termo != sugestaoEscolhida
            ? rascunho.indice.sugestoes(topicoId: rascunho.topico, termo: termo) : []
        return VStack(spacing: 8) {
            GrupoDaFolha {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Descrição (opcional)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(paleta.cor(.secundarioSolido))
                        .accessibilityHidden(true)
                    TextField("Descrição (opcional)", text: $rascunho.descricao,
                              prompt: Text("Ex: 50 sacos de cimento").foregroundStyle(paleta.cor(.textoTerciario)))
                        .foregroundStyle(paleta.cor(.texto))
                        .focused($foco, equals: .descricao)
                        .submitLabel(.done)
                        .onChange(of: rascunho.descricao) { _, _ in rascunho.limitarDescricao(); erroDaDescricao = nil }
                        .accessibilityIdentifier("descricao")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                ForEach(sugestoes, id: \.chave) { s in
                    SeparadorDaFolha()
                    Button {
                        rascunho.descricao = s.texto
                        sugestaoEscolhida = s.texto
                    } label: {
                        LinhaDeSugestao(sugestao: s, termo: termo)
                    }
                    .buttonStyle(.plain)
                }
            }
            if let erroDaDescricao { NotaDaFolha(texto: erroDaDescricao, cor: .erroNoVidro) }
        }
    }

    private func salvar() {
        foco = nil
        let entrada = rascunho.entrada
        switch conferirGasto(entrada, editado: rascunho.editado, hoje: dataLocalISO(.now, fuso: .current)) {
        case .failure(let erro):
            switch erro.campo {
            case "valor":
                // Sem mensagem, como o site: volta ao teclado.
                if rascunho.editado == nil { caminho.removeAll() } else { caminho.append(.valor) }
            case "descricao":
                erroDaDescricao = erro.mensagem
                foco = .descricao
            default:
                erroDoCartao = erro.mensagem
                foco = .juros
                if let m = erro.mensagem { AccessibilityNotification.Announcement(m).post() }
            }
        case .success(let conferido):
            erroDoCartao = nil
            guard let obra = modelo.sincronizador.estado.obras.first(where: { $0.id == rascunho.obraId }) else { folhas.fechar(); return }
            if gastoRepetido(obra, descricao: entrada.descricao, valor: conferido.valor, data: conferido.data, ignorarId: rascunho.editado?.id) {
                let assinatura = assinaturaDoGasto(obraId: obra.id, entrada: entrada, conferido: conferido)
                if rascunho.assinaturaAvisada != assinatura {
                    rascunho.assinaturaAvisada = assinatura
                    AccessibilityNotification.Announcement(CusttaNucleo.avisoDeRepetido).post()
                    return
                }
            }
            gravar(entrada, conferido)
        }
    }

    private func gravar(_ entrada: EntradaDoGasto, _ conferido: GastoConferido) {
        let obraId = rascunho.obraId
        let novos: [Gasto]
        let resultado: ModeloApp.ResultadoDaGravacao
        if let editado = rascunho.editado {
            // A edição parte do gasto que está no estado agora (outro aparelho pode tê-lo mudado com a folha aberta).
            novos = [editado]
            resultado = modelo.gravar { $0.editandoGasto(editado.id, entrada, conferido, naObra: obraId) }
        } else {
            novos = gastosLancados(entrada, conferido) { gerarId() }
            resultado = modelo.gravar { $0.lancandoGastos(novos, naObra: obraId) }
        }
        switch resultado {
        case .gravou:
            let ids = novos.map(\.id)
            let novo = rascunho.editado == nil
            folhas.fechar { folhas.destacar(ids, novo: novo) }
        case .naoCarregado:
            naoCarregado = true
        case .contaReal:
            contaReal = true
        case .sumiu, .semConta:
            folhas.fechar()
        }
    }
}

/// O ícone de um tópico: 32 pt, raio 9, no fundo fantasma.
struct IconeDoTopico: View {
    let icone: String
    @Environment(\.paleta) private var paleta

    var body: some View {
        Image(decorative: iconeDoCatalogo(icone))
            .resizable()
            .frame(width: 18, height: 18)
            .foregroundStyle(paleta.cor(.fantasmaTexto))
            .frame(width: 32, height: 32)
            .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 9, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Uma sugestão de descrição: o relógio, o texto com o começo igual ao digitado em destaque e de onde ela vem.
private struct LinhaDeSugestao: View {
    let sugestao: SugestaoDeDescricao
    let termo: String
    @Environment(\.paleta) private var paleta

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock").foregroundStyle(paleta.cor(.secundarioSolido)).accessibilityHidden(true)
            texto.frame(maxWidth: .infinity, alignment: .leading)
            Text(sugestao.contexto).font(.footnote).foregroundStyle(paleta.cor(.secundarioSolido))
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sugestao.texto)
        .accessibilityValue(sugestao.contexto)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("sugestao-\(sugestao.texto)")
    }

    private var texto: Text {
        let t = sugestao.texto
        let busca = aparadoJS(termo)
        guard !busca.isEmpty, let r = t.range(of: busca, options: [.caseInsensitive, .diacriticInsensitive, .anchored]) else {
            return Text(t).foregroundStyle(paleta.cor(.texto))
        }
        return Text("\(Text(t[r]).foregroundStyle(paleta.cor(.linkNoVidro)))\(Text(t[r.upperBound...]).foregroundStyle(paleta.cor(.texto)))")
    }
}

/// A data no calendário do iPhone (DatePicker compacto, que abre o calendário gráfico), em português.
struct CampoDeData: View {
    @Binding var iso: String
    /// O rótulo da linha, que o VoiceOver lê junto da data ("Primeiro vencimento", "Data da venda").
    var rotulo = "Data"
    var minimo: String?
    var maximo: String?

    var body: some View {
        DatePicker(rotulo, selection: data, in: intervalo, displayedComponents: .date)
            .labelsHidden()
            .datePickerStyle(.compact)
            // A pílula da data não quebra linha: no AX5 passava da largura da folha e empurrava os grupos para fora.
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .environment(\.locale, Locale(identifier: "pt_BR"))
            .accessibilityIdentifier("data")
    }

    private var data: Binding<Date> {
        Binding(get: { Self.dia(iso) ?? .now }, set: { iso = dataLocalISO($0, fuso: .current) })
    }

    /// Mínimo depois do máximo (a obra que começa no futuro, na venda) vira só o máximo: o ClosedRange invertido derruba o app.
    private var intervalo: ClosedRange<Date> {
        let fim = maximo.flatMap(Self.dia) ?? .distantFuture
        return min(minimo.flatMap(Self.dia) ?? .distantPast, fim)...fim
    }

    /// AAAA-MM-DD ao meio-dia local (longe das mudanças de horário).
    static func dia(_ iso: String) -> Date? {
        let p = iso.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        var c = DateComponents()
        c.year = p[0]; c.month = p[1]; c.day = p[2]; c.hour = 12
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = .current
        return calendario.date(from: c)
    }
}

/// A lista de tópicos dentro da folha: "Usados nesta obra" no alto (três) e "Todos"; tocar escolhe e volta.
private struct ListaDeTopicos: View {
    @Bindable var rascunho: RascunhoDoGasto
    let voltar: () -> Void
    @Environment(\.paleta) private var paleta

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if !rascunho.usados.isEmpty {
                    cabecalho("Usados nesta obra")
                    grupo(rascunho.usados, prefixo: "usado")
                    Color.clear.frame(height: 12)
                }
                cabecalho("Todos")
                grupo(rascunho.topicosSemOsUsados, prefixo: "topico")
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .passoDaFolha("Tópico", fechar: nil)
    }

    private func cabecalho(_ texto: String) -> some View {
        Text(texto)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(paleta.cor(.textoSecundario))
            .padding(.horizontal, 34)
            .accessibilityAddTraits(.isHeader)
    }

    private func grupo(_ topicos: [Topico], prefixo: String) -> some View {
        GrupoDaFolha {
            ForEach(Array(topicos.enumerated()), id: \.element.id) { i, t in
                if i > 0 { SeparadorDaFolha(recuo: 60) }
                Button {
                    rascunho.topico = t.id
                    voltar()
                } label: {
                    HStack(spacing: 12) {
                        IconeDoTopico(icone: t.icone)
                        Text(t.nome).foregroundStyle(paleta.cor(.texto)).frame(maxWidth: .infinity, alignment: .leading)
                        if t.id == rascunho.topico {
                            Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.linkNoVidro))
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 52)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(t.id == rascunho.topico ? [.isSelected] : [])
                .accessibilityIdentifier("\(prefixo)-\(t.id)")
            }
        }
    }
}

/// "Apagar este gasto?" (gasto simples) ou "só esta parcela / a compra toda" (parcela), pelo alerta do sistema, com os
/// textos do mockup ("Apagar" em tudo). Os dois alertas ficam sempre presos (cada um num fundo vazio, com os botões na
/// cor do texto, como o "Sair da conta?"); `gasto` diz qual aparece. Quem usa decide o que fazer com a confirmação: a
/// lista apaga na hora; a folha de edição fecha antes, para a animação aparecer.
struct PerguntaDeApagar: ViewModifier {
    @Binding var apresentada: Bool
    let obraId: String
    let gasto: Gasto?
    let confirmar: (Folhas.PedidoDeApagar) -> Void
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    func body(content: Content) -> some View {
        let estado = modelo.sincronizador.estado
        let obra = estado.obras.first { $0.id == obraId }
        let linha = gasto.map { linhaDeGasto($0, topicos: mapaDeTopicos(estado.config.topicosProprios)) }
        let parcela = gasto.flatMap { g in g.grupoId != nil ? g.parcela : nil }
        let simples = linha.map(textoDeApagarGasto)
        let compra = linha.flatMap { l in parcela.map { textoDeApagarParcela(l, parcela: $0, restantes: obra.map { o in parcelasDaCompra(gasto!, naObra: o) } ?? 1) } }
        content
            .background {
                Color.clear
                    .alert(simples?.titulo ?? "", isPresented: Binding(get: { apresentada && parcela == nil }, set: { apresentada = $0 })) {
                        Button("Cancelar", role: .cancel) {}
                        Button("Apagar", role: .destructive) { pedir(compraToda: false) }
                    } message: { Text(simples?.mensagem ?? "") }
                    .tint(paleta.cor(.texto))
            }
            .background {
                Color.clear
                    .alert(compra?.titulo ?? "", isPresented: Binding(get: { apresentada && parcela != nil }, set: { apresentada = $0 })) {
                        Button(compra?.soEsta ?? "", role: .destructive) { pedir(compraToda: false) }
                        Button(compra?.compraToda ?? "", role: .destructive) { pedir(compraToda: true) }
                        Button("Cancelar", role: .cancel) {}
                    } message: { Text(compra?.mensagem ?? "") }
                    .tint(paleta.cor(.texto))
            }
            .pausaOFundo(enquanto: apresentada)
    }

    private func pedir(compraToda: Bool) {
        guard let gasto else { return }
        confirmar(Folhas.PedidoDeApagar(obraId: obraId, gastoId: gasto.id, grupoId: compraToda ? gasto.grupoId : nil))
    }
}
```

Criar `app-ios/Custta/Telas/FolhaEmPassos.swift`:

```swift
import SwiftUI
import UIKit

/* A folha do sistema com passos (conselho de 13/10, decisão b): um NavigationStack dentro da .sheet, com o voltar e o
   gesto da borda do sistema; o × fecha, à esquerda na raiz e à direita nos passos de dentro (o voltar fica à esquerda);
   o título em duas linhas na barra; o fundo na Folha. Quando há o que perder, fechar pergunta antes, por qualquer
   caminho: o ×, puxar a folha para baixo (a ponte para o "tentou fechar" do UIKit, que o SwiftUI não expõe) e o gesto
   de escapar do VoiceOver (Z com dois dedos) na raiz. Serve ao gasto, à venda e à obra. Os círculos da barra são o vidro
   do sistema, não os sólidos do mockup: com eles vem o voltar pela borda (exceção levada ao Giovani). */

/// O que um passo da folha chama para fechar: pergunta antes, se houver o que perder.
struct PedidoDeFechar {
    let pedir: () -> Void
    func callAsFunction() { pedir() }
}

extension EnvironmentValues {
    @Entry var pedirParaFechar = PedidoDeFechar {}
}

extension View {
    /// Em volta do NavigationStack da folha: a Folha de fundo, a pergunta antes de descartar e a ponte do puxar para baixo.
    /// `perguntar` diz se há o que perder; `pergunta` e `descartar` são os textos do alerta ("Você já preencheu este
    /// gasto." / "Descartar gasto"); `fechar` fecha de fato.
    func folhaDoApp(perguntar: Bool, pergunta: String, descartar: String, fechar: @escaping () -> Void) -> some View {
        modifier(FolhaDoApp(perguntar: perguntar, pergunta: pergunta, descartar: descartar, fechar: fechar))
    }

    /// Um passo da folha: o título na barra, o × no lado dado (nil: sem ×, como a lista de tópicos), o fundo transparente
    /// para a Folha aparecer. Na raiz, o escapar do VoiceOver fecha (pedindo antes).
    func passoDaFolha(_ titulo: String, subtitulo: String? = nil, fechar lado: LadoDoFechar?, raiz: Bool = false) -> some View {
        modifier(PassoDaFolha(titulo: titulo, subtitulo: subtitulo, lado: lado, raiz: raiz))
    }
}

enum LadoDoFechar { case esquerda, direita }

private struct FolhaDoApp: ViewModifier {
    let perguntar: Bool
    let pergunta: String
    let descartar: String
    let fechar: () -> Void
    @State private var confirmando = false
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    #if DEBUG
    @AppStorage("custta.textoApagado") private var textoApagado = ""
    #endif

    func body(content: Content) -> some View {
        let pedido = PedidoDeFechar { if perguntar { confirmando = true } else { fechar() } }
        content
            #if DEBUG
            // Laudo de leitura: o apagador de texto da raiz não chega dentro da .sheet.
            .modifier(ApagaTexto(ativo: textoApagado == "tudo"))
            #endif
            .environment(\.pedirParaFechar, pedido)
            .interactiveDismissDisabled(perguntar)
            .background { PonteDeFechamento { if perguntar { confirmando = true } } }
            .alert(pergunta, isPresented: $confirmando) {
                Button(descartar, role: .destructive, action: fechar)
                Button("Continuar editando", role: .cancel) {}
            }
            .presentationDragIndicator(.visible)
            .presentationBackground {
                // A Folha (vidro denso do mockup): a cor do token sobre o desfoque do que fica atrás. Com "Reduzir
                // transparência", opaca: a Folha sobre o Fundo, sem material.
                if opcoes.reduzirTransparencia {
                    Rectangle().fill(paleta.cor(.folha)).background(paleta.cor(.fundo))
                } else {
                    Rectangle().fill(paleta.cor(.folha)).background(.ultraThinMaterial)
                }
            }
    }
}

private struct PassoDaFolha: ViewModifier {
    let titulo: String
    let subtitulo: String?
    let lado: LadoDoFechar?
    let raiz: Bool
    @Environment(\.pedirParaFechar) private var pedirParaFechar
    @Environment(\.paleta) private var paleta

    func body(content: Content) -> some View {
        content
            .containerBackground(.clear, for: .navigation)
            .navigationTitle(titulo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { TituloDaFolha(titulo: titulo, subtitulo: subtitulo) }
                if let lado {
                    ToolbarItem(placement: lado == .esquerda ? .topBarLeading : .topBarTrailing) {
                        Button(role: .close) { pedirParaFechar() }
                            .tint(paleta.cor(.texto))
                            .accessibilityIdentifier("fecharFolha")
                    }
                }
            }
            .accessibilityAction(.escape) { if raiz { pedirParaFechar() } }
    }
}

// MARK: - Ponte para o "tentou fechar"

/// Um controlador invisível dentro da folha: acha o presentation controller dela e põe na frente do delegado do SwiftUI
/// um repassador que avisa a tentativa de fechar (puxar a folha com o fechar desligado) e repassa todo o resto ao
/// original. Quando a folha some, devolve o delegado original, para nada ficar preso.
struct PonteDeFechamento: UIViewControllerRepresentable {
    let tentou: () -> Void

    func makeUIViewController(context: Context) -> ControladorDaPonte { ControladorDaPonte() }

    func updateUIViewController(_ controlador: ControladorDaPonte, context: Context) {
        controlador.tentou = tentou
        controlador.instalar()
    }
}

final class ControladorDaPonte: UIViewController {
    var tentou: (() -> Void)?
    private var repassador: RepassadorDeFechamento?
    private weak var controle: UIPresentationController?
    #if DEBUG
    /// Pontes vivas: o teste de tela abre e fecha a folha e confere que nenhuma ficou para trás.
    nonisolated(unsafe) static var vivas = 0
    #endif

    init() {
        super.init(nibName: nil, bundle: nil)
        #if DEBUG
        Self.vivas += 1
        #endif
    }

    required init?(coder: NSCoder) { fatalError("sem storyboard") }

    deinit {
        #if DEBUG
        Self.vivas -= 1
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        instalar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        instalar()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        var raiz: UIViewController = self
        while let pai = raiz.parent { raiz = pai }
        // A folha desceu: o delegado volta a ser o do SwiftUI (o repassador segurava o original com referência forte).
        if raiz.isBeingDismissed || raiz.presentingViewController == nil { desinstalar() }
    }

    func instalar() {
        var raiz: UIViewController = self
        while let pai = raiz.parent { raiz = pai }
        // Sem pai, ou se a raiz não foi apresentada, ler presentationController criaria um à toa.
        guard raiz !== self, raiz.presentingViewController != nil, let controle = raiz.presentationController else { return }
        if let atual = controle.delegate as? RepassadorDeFechamento, atual === repassador { return }
        let novo = RepassadorDeFechamento(original: controle.delegate) { [weak self] in self?.tentou?() }
        repassador = novo
        self.controle = controle
        controle.delegate = novo
    }

    private func desinstalar() {
        if let controle, let repassador, controle.delegate === repassador { controle.delegate = repassador.original }
        repassador = nil
    }
}

@MainActor
final class RepassadorDeFechamento: NSObject, UIAdaptivePresentationControllerDelegate {
    /// Forte de propósito (experimento de 13/10): o presentation controller só segura o delegado com referência fraca.
    nonisolated(unsafe) let original: (any UIAdaptivePresentationControllerDelegate)?
    private let tentou: () -> Void

    init(original: (any UIAdaptivePresentationControllerDelegate)?, tentou: @escaping () -> Void) {
        self.original = original
        self.tentou = tentou
        super.init()
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        tentou()
        original?.presentationControllerDidAttemptToDismiss?(presentationController)
    }

    nonisolated override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        return original?.responds(to: aSelector) ?? false
    }

    nonisolated override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let original, original.responds(to: aSelector) { return original }
        return super.forwardingTarget(for: aSelector)
    }
}
```

Em `app-ios/Custta/Telas/PrincipalView.swift`:

```diff
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -10,6 +10,8 @@ import CusttaNucleo
 struct PrincipalView: View {
     @State private var aba = Aba.obras
     @State private var caminhoDeObras = PrincipalView.caminhoInicial
+    @State private var folhas = Folhas()
+    @Environment(ModeloApp.self) private var modelo
 
     var body: some View {
         Group {
@@ -18,8 +20,28 @@ struct PrincipalView: View {
             case .ajustes: AjustesView()
             }
         }
+        .environment(folhas)
         // Barra própria: o que rola por baixo dela passa pela borda suave de cada tela (BordaDeRolagem).
-        .safeAreaBar(edge: .bottom, spacing: 0) { CapsulaDeAbas(escolhida: $aba) }
+        .safeAreaBar(edge: .bottom, spacing: 0) { CapsulaDeAbas(escolhida: $aba, mais: acaoDoMais) }
+        .sheet(item: $folhas.aberta, onDismiss: folhas.fechou) { qual in
+            switch qual {
+            case .novoGasto(let obraId): FolhaDoGasto(obraId: obraId, gastoId: nil).environment(folhas)
+            case .editarGasto(let obraId, let gastoId): FolhaDoGasto(obraId: obraId, gastoId: gastoId).environment(folhas)
+            }
+        }
+        // Com a folha aberta o fundo para: ela cobre quase tudo, e cada quadro da aurora refaria o desfoque dela.
+        .pausaOFundo(enquanto: folhas.aberta != nil)
+        #if DEBUG
+        .task { await abrirFolhaDeTeste() }
+        // Teste de tela: quantas pontes de fechamento estão vivas (abrir e fechar a folha não pode deixar nenhuma).
+        .overlay(alignment: .topLeading) {
+            if UserDefaults.standard.bool(forKey: "custta.contarPontes") {
+                TimelineView(.periodic(from: .now, by: 0.5)) { _ in
+                    Text("pontes \(ControladorDaPonte.vivas)").font(.caption2).accessibilityIdentifier("pontesVivas")
+                }
+            }
+        }
+        #endif
         // A cápsula se mede da borda da tela, como a barra de abas do sistema, e não acompanha o teclado: ao
         // entrar com ele aberto, o teclado da entrada ainda está fechando quando esta tela aparece, e a barra
         // nascia em cima dele, no meio da tela, e saltava. As telas das abas não têm campo de texto.
@@ -28,6 +50,26 @@ struct PrincipalView: View {
 }
 
 extension PrincipalView {
+    /// O + da cápsula: dentro de uma obra que ainda recebe gasto, lança gasto nela. Obra vendida não recebe gasto novo
+    /// (como no site); a escolha de outra obra chega no PR 3, junto com "Nova obra" na lista.
+    private var acaoDoMais: AcaoDoMais? {
+        guard aba == .obras, case .obra(let id)? = caminhoDeObras.last,
+              let obra = modelo.sincronizador.estado.obras.first(where: { $0.id == id }), obra.fase != .vendida else { return nil }
+        return AcaoDoMais(rotulo: "Lançar gasto") { folhas.aberta = .novoGasto(obraId: id) }
+    }
+
+    #if DEBUG
+    /// Laudo de leitura, auditoria e conferência visual: com `CUSTTA_ABRIR=obra:<id>`, `-custta.folha <passo>` abre a folha
+    /// do gasto novo já no passo (valor, detalhes, cartao, topicos, repetido) e `-custta.folha editar:<gasto>`, a edição.
+    private func abrirFolhaDeTeste() async {
+        guard let passo = UserDefaults.standard.string(forKey: "custta.folha"), case .obra(let obraId)? = caminhoDeObras.last else { return }
+        while !modelo.sincronizador.dadosCarregados { try? await Task.sleep(for: .milliseconds(100)) }
+        try? await Task.sleep(for: .milliseconds(300))
+        folhas.aberta = passo.hasPrefix("editar:") ? .editarGasto(obraId: obraId, gastoId: String(passo.dropFirst(7)))
+                                                   : .novoGasto(obraId: obraId)
+    }
+    #endif
+
     /// O caminho com que Obras abre: vazio; em Debug, `CUSTTA_ABRIR=obra:<id>` abre a obra direto (testes de tela, laudo
     /// de leitura e conferência visual).
     static var caminhoInicial: [RotaDeObras] {
```


- [ ] **Step 4: Ver passar**

Run: o mesmo do Step 2 e `-only-testing:CusttaTests`.
Expected: os 6 de `GastoUITests` desta tarefa verdes (lançar no Pix, descartar pelo ×, puxar com e sem valor e a contagem das pontes, voltar pela borda dentro da folha, repetido, `nao-carregado`); `CusttaTests` com 97.

- [ ] **Step 5: Conferência visual (Verniz)**

Com `-custta.folha valor|detalhes|cartao|topicos|repetido` e `editar:g031`, lado a lado com `parte2-lancar-1.png`, `lancar-3`, `lancar-4`, `lancar-5`, `lancar-6`, `topico-a`, `editar-parcela`, `aviso-dup` e `aviso-carregando`, nos quatro combos, na maior letra e no simulador de 375 pt (13 mini, com o teclado aberto na descrição). Diferenças conhecidas e aceitas: os círculos da barra são o vidro do sistema (exceção nomeada) e o resumo do cartão tem o texto do site.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Estado/Folhas.swift \
  app-ios/Custta/Identidade/CapsulaDeAbas.swift \
  app-ios/Custta/Telas/FolhaDoGasto.swift \
  app-ios/Custta/Telas/FolhaEmPassos.swift \
  app-ios/Custta/Telas/PrincipalView.swift \
  app-ios/CusttaTests/GravacaoDoAppTests.swift \
  app-ios/CusttaUITests/AuditoriaUITests.swift \
  app-ios/CusttaUITests/GastoUITests.swift
git commit -m "feat: folha do gasto em dois passos, aberta pelo + da cápsula" -m "O + volta para a cápsula e abre a folha do gasto: o valor no teclado de valor e depois os detalhes, na ordem do site, com tópico, cartão, descrição com sugestões e data. A folha é um NavigationStack dentro da sheet, com o voltar e a borda do sistema, e pergunta antes de descartar pelo ×, ao puxar e pelo escapar do VoiceOver, por uma ponte para o aviso do UIKit que devolve o delegado ao fechar. Grava pelas regras do núcleo, avisa o repetido e mantém o gasto na folha quando os dados ainda não chegaram."
```

### Task 23: Editar tocando na linha e apagar arrastando, com a animação do sistema

A lista da obra passa a agir: tocar na linha abre a edição; arrastar para a esquerda mostra o "Apagar" (o arrastar próprio do conselho), que pergunta num alerta e apaga com a animação do sistema (a linha sai pela esquerda, as de baixo sobem, os totais mudam juntos); a parcela oferece só esta ou a compra toda; o "Apagar gasto" da folha de edição apaga depois que a folha desce. Depois de salvar, a lista abre o "A vencer" se for o caso, rola até o gasto em dois tempos, acende por 2 s ("novo" no lançado) e vibra. O VoiceOver vai para a linha nova; depois de apagar, para a vizinha, e ouve "Gasto apagado".

**Files:**
- Modify: `app-ios/Custta/Falsos/MontarFalso.swift`
- Modify: `app-ios/Custta/Falsos/TransporteFalsoApp.swift`
- Create: `app-ios/Custta/Telas/LinhaArrastavel.swift`
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Modify: `app-ios/Custta/Telas/PecasDaObra.swift`
- Test (alterar): `app-ios/CusttaTests/GravacaoDoAppTests.swift`
- Test (alterar): `app-ios/CusttaUITests/Abrir.swift`
- Test (alterar): `app-ios/CusttaUITests/GastoUITests.swift`

**Interfaces:**
- Consumes: Tarefas 19 a 22.
- Produces: `LinhaArrastavel(id:aberta:apagar:conteudo:)`, `ArrastoParaApagar`; `AcoesDaLista`, `LinhaDaLista`, `AlvoDoFoco`, `vizinhoDepoisDeApagar(_:ordem:)`; `LinhaDeGastoView(gasto:linha:acesa:novo:)`, `EtiquetaNovo`; em Debug, `-custta.linhaAberta <id>`. Identificadores: `apagar-<id>`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaTests/GravacaoDoAppTests.swift`:

```diff
--- a/app-ios/CusttaTests/GravacaoDoAppTests.swift
+++ b/app-ios/CusttaTests/GravacaoDoAppTests.swift
@@ -4,7 +4,8 @@ import Testing
 import CusttaNucleo
 
 /* O que as telas que gravam usam (etapa 2): o `gravar` do modelo (troca o estado na hora e sobe o documento; recusa
-   sem ver os dados; nada sobe quando a obra sumiu), o vaivém das folhas e o rascunho do gasto. */
+   sem ver os dados; nada sobe quando a obra sumiu), o vaivém das folhas, o rascunho do gasto e para onde o VoiceOver vai
+   depois de apagar. */
 @MainActor
 struct GravacaoDoAppTests {
     func montar(semRede: Bool = false, dados: ValorJSON? = DadosDeExemplo.blob) -> (ModeloApp, TransporteFalsoApp, ContaFalsa) {
@@ -135,4 +136,11 @@ struct GravacaoDoAppTests {
         r.descricao = "  Cimento  "
         #expect(r.entrada.descricao == "Cimento", "a descrição sai aparada, como no site")
     }
+
+    @Test func vizinhoDoVoiceOverDepoisDeApagar() {
+        #expect(vizinhoDepoisDeApagar(["b"], ordem: ["a", "b", "c"]) == "c")
+        #expect(vizinhoDepoisDeApagar(["c"], ordem: ["a", "b", "c"]) == "b")
+        #expect(vizinhoDepoisDeApagar(["b", "c"], ordem: ["a", "b", "c", "d"]) == "d", "a compra toda sai junta")
+        #expect(vizinhoDepoisDeApagar(["a"], ordem: ["a"]) == nil, "sem vizinho, vai para Lançamentos")
+    }
 }
```

Em `app-ios/CusttaUITests/Abrir.swift`:

```diff
--- a/app-ios/CusttaUITests/Abrir.swift
+++ b/app-ios/CusttaUITests/Abrir.swift
@@ -1,11 +1,13 @@
 import XCTest
 
-/// Abre o app com os serviços falsos (Custta/Falsos). Nada de rede nem de Firebase. `abrir: "obra:v1"` já abre a obra.
+/// Abre o app com os serviços falsos (Custta/Falsos). Nada de rede nem de Firebase. `abrir: "obra:v1"` já abre a obra;
+/// `extra` passa outras variáveis dos falsos (`CUSTTA_APAGAR_REMOTO`).
 @MainActor
 func abrirApp(conta: String = "nenhuma", dados: String = "exemplo", rede: String? = nil, leitura: String? = nil,
-              limpeza: String? = nil, abrir: String? = nil, marca: String? = nil, argumentos: [String] = []) -> XCUIApplication {
+              limpeza: String? = nil, abrir: String? = nil, marca: String? = nil, argumentos: [String] = [],
+              extra: [String: String] = [:]) -> XCUIApplication {
     let app = XCUIApplication()
-    var ambiente = ["CUSTTA_SERVICOS": "falsos", "CUSTTA_CONTA": conta, "CUSTTA_DADOS": dados]
+    var ambiente = ["CUSTTA_SERVICOS": "falsos", "CUSTTA_CONTA": conta, "CUSTTA_DADOS": dados].merging(extra) { _, novo in novo }
     if let abrir { ambiente["CUSTTA_ABRIR"] = abrir }
     if let marca { ambiente["CUSTTA_MARCA"] = marca }
     if let rede { ambiente["CUSTTA_REDE"] = rede }
```

Em `app-ios/CusttaUITests/GastoUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/GastoUITests.swift
+++ b/app-ios/CusttaUITests/GastoUITests.swift
@@ -1,7 +1,9 @@
 import XCTest
 
-/* O gasto (etapa 2, PR 2), na obra da vitrine (46 lançamentos): lançar no Pix (com e sem rede), descartar pelo × e
-   puxando a folha, o voltar pela borda dentro da folha, o repetido e o `nao-carregado`. */
+/* O gasto (etapa 2, PR 2), na obra da vitrine (46 lançamentos): lançar no Pix (com e sem rede) e no cartão parcelado,
+   editar (a descrição e o valor no teclado), apagar arrastando e pela folha, a parcela (só esta ou a compra toda),
+   descartar pelo × e puxando a folha, o voltar pela borda dentro da folha, o repetido, o `nao-carregado` e a folha que
+   fecha quando outro aparelho apaga o gasto. */
 @MainActor
 final class GastoUITests: XCTestCase {
     private func abrirObra(_ argumentos: [String] = []) -> XCUIApplication {
@@ -58,6 +60,145 @@ final class GastoUITests: XCTestCase {
         XCTAssertEqual(app.elemento("indicadorSincronizacao").label, "Sem conexão", "e espera a rede na fila")
     }
 
+    func testLancarNoCartaoEm10xVaiParaOAVencer() {
+        let app = abrirObra()
+        lancarValor(app, "498000")
+        app.buttons["pagamento-Cartão"].tap()
+        app.buttons["parcelas"].tap()
+        app.buttons["10x"].tap()
+        let resumo = app.elemento("resumoDoCartao")
+        XCTAssertTrue(resumo.waitForExistence(timeout: 3))
+        XCTAssertEqual(resumo.label, "10x de R$\u{a0}498,00 · Juros do cartão: R$\u{a0}0,00 · Total: R$\u{a0}4.980,00")
+        escrever(app, "Revestimento da varanda")
+        app.buttons["salvarGasto"].tap()
+        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
+        XCTAssertEqual(app.elemento("aVencer").value as? String, "aberto", "o primeiro vencimento é daqui a um mês: o A vencer abre")
+        XCTAssertTrue(comRotulo(app, comecando: "Revestimento da varanda (1/10)").firstMatch.waitForExistence(timeout: 5))
+        XCTAssertTrue(app.elemento("lancamentos").label.contains("56"), "10 parcelas entraram")
+    }
+
+    func testEditarGastoTrocaADescricao() {
+        let app = abrirObra()
+        let linha = app.elemento("gasto-g027")
+        app.rolarAte(linha)
+        linha.tap()
+        XCTAssertTrue(app.elemento("tituloDaFolha").waitForExistence(timeout: 5))
+        XCTAssertTrue(app.elemento("tituloDaFolha").label.hasPrefix("Editar gasto"))
+        XCTAssertEqual(app.elemento("linhaValor").value as? String, "R$\u{a0}4.980,00")
+        escrever(app, "Cimento CP-V, 120 sacos", apagando: 30)
+        app.buttons["salvarGasto"].tap()
+        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
+        XCTAssertTrue(app.elemento("gasto-g027").label.hasPrefix("Cimento CP-V, 120 sacos"), app.elemento("gasto-g027").label)
+        XCTAssertTrue(app.elemento("lancamentos").label.contains("46"))
+    }
+
+    func testEditarOValorPeloTeclado() {
+        let app = abrirObra()
+        let linha = app.elemento("gasto-g027")
+        app.rolarAte(linha)
+        linha.tap()
+        XCTAssertTrue(app.elemento("linhaValor").waitForExistence(timeout: 5))
+        app.elemento("linhaValor").tap()
+        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
+        XCTAssertEqual(app.buttons["confirmarValor"].label, "Pronto")
+        for _ in 0..<6 { app.buttons["tecla-del"].tap() }
+        for t in "12345" { app.buttons["tecla-\(t)"].tap() }
+        app.buttons["confirmarValor"].tap()
+        XCTAssertEqual(app.elemento("linhaValor").value as? String, "R$\u{a0}123,45", "o valor novo volta aos detalhes")
+        app.buttons["salvarGasto"].tap()
+        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
+        XCTAssertEqual(app.elemento("gasto-g027").value as? String, "R$\u{a0}123,45")
+    }
+
+    func testFolhaFechaQuandoOutroAparelhoApagaOGasto() {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", extra: ["CUSTTA_APAGAR_REMOTO": "v1/g027@12"])
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
+        let linha = app.elemento("gasto-g027")
+        app.rolarAte(linha)
+        linha.tap()
+        XCTAssertTrue(app.elemento("linhaTopico").waitForExistence(timeout: 5), "a edição abriu antes de o outro aparelho apagar")
+        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 20), "o gasto sumiu: a folha fecha sem gravar")
+        XCTAssertFalse(app.elemento("gasto-g027").exists)
+    }
+
+    func testEditarParcelaMostraOAvisoDoSite() {
+        let app = abrirObra()
+        let linha = app.elemento("gasto-g031")
+        app.rolarAte(linha)
+        linha.tap()
+        let aviso = app.elemento("avisoParcela")
+        XCTAssertTrue(aviso.waitForExistence(timeout: 5))
+        XCTAssertEqual(aviso.label, "Parcela 4/10 de uma compra no cartão — a edição vale só pra esta parcela.")
+        XCTAssertFalse(app.buttons["pagamento-Pix"].exists, "numa parcela o pagamento não muda")
+    }
+
+    func testApagarArrastandoPerguntaComNomeEValor() {
+        let app = abrirObra()
+        let linha = app.elemento("gasto-g027")
+        app.rolarAte(linha)
+        linha.swipeLeft()
+        let apagar = app.buttons["apagar-g027"]
+        XCTAssertTrue(apagar.waitForExistence(timeout: 3), "arrastar para a esquerda mostra Apagar")
+        apagar.tap()
+        let alerta = app.alerts["Apagar este gasto?"]
+        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
+        XCTAssertTrue(alerta.staticTexts["Cimento CP-II, 120 sacos · R$\u{a0}4.980,00. Não dá para desfazer."].exists)
+        alerta.buttons["Apagar"].tap()
+        XCTAssertTrue(app.elemento("gasto-g027").waitForNonExistence(timeout: 5))
+        XCTAssertTrue(app.elemento("lancamentos").label.contains("45"))
+    }
+
+    func testCancelarFechaALinhaENaoApaga() {
+        let app = abrirObra()
+        let linha = app.elemento("gasto-g027")
+        app.rolarAte(linha)
+        linha.swipeLeft()
+        app.buttons["apagar-g027"].tap()
+        app.alerts["Apagar este gasto?"].buttons["Cancelar"].tap()
+        XCTAssertTrue(app.buttons["apagar-g027"].waitForNonExistence(timeout: 3), "cancelar fecha a linha")
+        XCTAssertTrue(app.elemento("gasto-g027").exists)
+    }
+
+    func testApagarACompraTodaDeUmaParcela() {
+        let app = abrirObra()
+        let linha = app.elemento("gasto-g031")
+        app.rolarAte(linha)
+        linha.swipeLeft()
+        app.buttons["apagar-g031"].tap()
+        let alerta = app.alerts["Porcelanato 60×60 (4/10)"]
+        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
+        XCTAssertTrue(alerta.buttons["Apagar só esta parcela"].exists)
+        alerta.buttons["Apagar a compra toda (10 parcelas)"].tap()
+        XCTAssertTrue(app.elemento("gasto-g031").waitForNonExistence(timeout: 5))
+        XCTAssertTrue(app.elemento("lancamentos").label.contains("36"), "as 10 parcelas saíram juntas")
+    }
+
+    func testApagarSoEstaParcela() {
+        let app = abrirObra()
+        let linha = app.elemento("gasto-g031")
+        app.rolarAte(linha)
+        linha.swipeLeft()
+        app.buttons["apagar-g031"].tap()
+        let alerta = app.alerts["Porcelanato 60×60 (4/10)"]
+        XCTAssertTrue(alerta.waitForExistence(timeout: 3))
+        alerta.buttons["Apagar só esta parcela"].tap()
+        XCTAssertTrue(app.elemento("gasto-g031").waitForNonExistence(timeout: 5))
+        XCTAssertTrue(app.elemento("lancamentos").label.contains("45"), "só a parcela saiu; as outras nove ficam")
+    }
+
+    func testApagarPelaFolhaDeEdicao() {
+        let app = abrirObra()
+        let linha = app.elemento("gasto-g027")
+        app.rolarAte(linha)
+        linha.tap()
+        let botao = app.buttons["apagarGasto"]
+        XCTAssertTrue(botao.waitForExistence(timeout: 5))
+        botao.tap()
+        app.alerts["Apagar este gasto?"].buttons["Apagar"].tap()
+        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5), "a folha desce")
+        XCTAssertTrue(app.elemento("gasto-g027").waitForNonExistence(timeout: 5), "e a linha sai depois")
+    }
+
     func testFecharDepoisDoValorPerguntaAntes() {
         let app = abrirObra()
         lancarValor(app, "1")
```


- [ ] **Step 2: Ver falhar**

Run: `xcodebuild build-for-testing "${XB[@]}"` e `-only-testing:CusttaUITests/GastoUITests`.
Expected: não compila o `CusttaTests` (`cannot find 'vizinhoDepoisDeApagar' in scope`); sem ele, os testes novos de tela falham esperando a edição e o `apagar-g027`.

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Falsos/MontarFalso.swift`:

```diff
--- a/app-ios/Custta/Falsos/MontarFalso.swift
+++ b/app-ios/Custta/Falsos/MontarFalso.swift
@@ -9,6 +9,7 @@ import CusttaNucleo
    CUSTTA_DADOS   vitrine (padrão: as obras do mockup) | exemplo (as dos testes) | vazio
    CUSTTA_REDE    offline (abre "em modo avião": dados do cache e indicador "Sem conexão")
    CUSTTA_LEITURA erro (a escuta falha com permission-denied) | formato (documento que o app não lê)
+   CUSTTA_APAGAR_REMOTO <obra>/<gasto>@<segundos> (outro aparelho apaga o gasto, com o app aberto)
    CUSTTA_MARCA   servidor (o servidor já respondeu a esta conta numa abertura anterior: com CUSTTA_REDE=offline e
                   CUSTTA_DADOS=vazio, é a conta vazia que abre sem rede e pode lançar)
    CUSTTA_LIMPEZA falha (a limpeza do cache falha no sair e na 1ª nova tentativa) | abertura (abre bloqueado,
@@ -29,7 +30,13 @@ extension Composicao {
         case "exemplo": DadosDeExemplo.blob
         default: DadosDeExemplo.vitrine()
         }
-        let transporte = TransporteFalsoApp(dados: dados, semRede: semRede, falhaDeLeitura: falha)
+        // CUSTTA_APAGAR_REMOTO=<obra>/<gasto>@<segundos>: outro aparelho apaga um gasto com o app aberto.
+        let remoto = ambiente["CUSTTA_APAGAR_REMOTO"].flatMap { v -> (obra: String, gasto: String, depois: Double)? in
+            let partes = v.split(whereSeparator: { $0 == "/" || $0 == "@" }).map(String.init)
+            guard partes.count == 3, let segundos = Double(partes[2]) else { return nil }
+            return (partes[0], partes[1], segundos)
+        }
+        let transporte = TransporteFalsoApp(dados: dados, semRede: semRede, falhaDeLeitura: falha, apagarRemoto: remoto)
         let rede = MonitorDeRede(forcarSemRede: semRede)
         let marca = MarcaEmMemoria()
         if ambiente["CUSTTA_MARCA"] == "servidor" { marca.marcarTodas = true }
```

Em `app-ios/Custta/Falsos/TransporteFalsoApp.swift`:

```diff
--- a/app-ios/Custta/Falsos/TransporteFalsoApp.swift
+++ b/app-ios/Custta/Falsos/TransporteFalsoApp.swift
@@ -4,33 +4,55 @@ import CusttaNucleo
 
 /// Transporte falso dos testes (só Debug): entrega um blob fixo e confirma gravações depois de
 /// 300 ms (nunca, sem rede). `falhaDeLeitura` faz a escuta falhar com esse código antes do primeiro
-/// snapshot (CUSTTA_LEITURA=erro: permission-denied; formato: formato-desconhecido).
+/// snapshot (CUSTTA_LEITURA=erro: permission-denied; formato: formato-desconhecido). `apagarRemoto`
+/// simula outro aparelho apagando um gasto: um segundo snapshot, sem ele, depois de alguns segundos
+/// (CUSTTA_APAGAR_REMOTO=<obra>/<gasto>@<segundos>).
 @MainActor
 final class TransporteFalsoApp: TransporteDados {
     private final class Nada: Cancelavel { func cancelar() {} }
     private let dados: ValorJSON?
     private let semRede: Bool
     private let falhaDeLeitura: String?
+    private let apagarRemoto: (obra: String, gasto: String, depois: Double)?
     /// Quantas gravações chegaram (os testes conferem que abrir o app não grava nada).
     private(set) var gravacoes = 0
 
-    init(dados: ValorJSON?, semRede: Bool, falhaDeLeitura: String? = nil) {
+    init(dados: ValorJSON?, semRede: Bool, falhaDeLeitura: String? = nil,
+         apagarRemoto: (obra: String, gasto: String, depois: Double)? = nil) {
         self.dados = dados
         self.semRede = semRede
         self.falhaDeLeitura = falhaDeLeitura
+        self.apagarRemoto = apagarRemoto
     }
 
     func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                  aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel {
-        let dados = self.dados, semRede = self.semRede, falha = falhaDeLeitura
+        let dados = self.dados, semRede = self.semRede, falha = falhaDeLeitura, remoto = apagarRemoto
         Task { @MainActor in
             try? await Task.sleep(for: .milliseconds(200))
             if let falha { aoFalhar(falha); return }
             aoReceber(Instantaneo(dados: dados, doCache: semRede, gravacaoPendente: false))
+            guard let remoto else { return }
+            try? await Task.sleep(for: .seconds(remoto.depois))
+            aoReceber(Instantaneo(dados: Self.sem(remoto.gasto, naObra: remoto.obra, em: dados), doCache: semRede, gravacaoPendente: false))
         }
         return Nada()
     }
 
+    /// O blob sem um gasto, como outro aparelho o gravaria.
+    private static func sem(_ gastoId: String, naObra obraId: String, em dados: ValorJSON?) -> ValorJSON? {
+        guard case .objeto(var raiz)? = dados, case .lista(let obras)? = raiz["obras"] else { return dados }
+        raiz["obras"] = .lista(obras.map { o in
+            guard case .objeto(var obra) = o, obra["id"] == .texto(obraId), case .lista(let gastos)? = obra["gastos"] else { return o }
+            obra["gastos"] = .lista(gastos.filter { g in
+                if case .objeto(let campos) = g { return campos["id"] != .texto(gastoId) }
+                return true
+            })
+            return .objeto(obra)
+        })
+        return .objeto(raiz)
+    }
+
     func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void) {
         gravacoes += 1
         guard !semRede else { return }
```

Criar `app-ios/Custta/Telas/LinhaArrastavel.swift`:

```swift
import SwiftUI
import UIKit

/* Arrastar a linha de gasto para a esquerda mostra "Apagar" (conselho de 13/10, decisão a). O .swipeActions do sistema
   só existe dentro de List, e a List não desenha um cartão de vidro por mês (vira um vidro por linha, com emenda); o
   swipeActionsContainer do iOS 27 ignora a cor e não compila no Xcode da CI. Por isso o arrastar é próprio, com a física
   da List: só começa num arrasto mais horizontal que vertical, para a esquerda (para a direita só com a linha aberta);
   os 20 pt da borda esquerda ficam com o voltar do sistema; a linha abre em −100 pt (o botão de 80 e as folgas), estica
   com resistência além disso, decide no soltar pela posição projetada com o impulso (gestos.js) e assenta numa mola sem
   quique que parte da velocidade do dedo. Vibra uma vez ao passar de −40 pt. Nunca apaga no arrasto até o fim: o botão
   pergunta antes. Tocar com uma linha aberta só fecha; rolar fecha. */

struct LinhaArrastavel<Conteudo: View>: View {
    let id: String
    @Binding var aberta: String?
    let apagar: () -> Void
    @ViewBuilder let conteudo: () -> Conteudo
    @State private var arrasto: CGFloat = 0
    @State private var passou = false
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    /// O botão cresce com a letra até o tamanho AX2 (mockup: "Apagar" de 13 pt num botão de 80).
    @ScaledMetric(relativeTo: .footnote) private var larguraDoBotao: CGFloat = 80

    private var largura: CGFloat { min(larguraDoBotao, 120) }
    private var revelado: CGFloat { largura + 20 }
    static var limiar: CGFloat { 40 }

    var body: some View {
        let estaAberta = aberta == id
        let x = posicao(base: estaAberta ? -revelado : 0, arrasto: arrasto)
        ZStack(alignment: .trailing) {
            if x < 0 {
                Button(action: apagar) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash").font(.system(size: 18, weight: .semibold))
                        Text("Apagar").font(.footnote.weight(.semibold))
                    }
                    .foregroundStyle(paleta.cor(.sobreApagar))
                    .frame(width: largura)
                    .frame(maxHeight: .infinity)
                    .background(paleta.cor(.apagar), in: .rect(cornerRadius: 22, style: .continuous))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 7)
                .padding(.trailing, 10)
                .opacity(min(1, -x / 70))
                .accessibilityLabel("Apagar")
                .accessibilityIdentifier("apagar-\(id)")
            }
            conteudo()
                .background(x < 0 ? paleta.cor(.linhaDaFolha) : .clear)
                .offset(x: x)
                .accessibilityAction(named: "Apagar", apagar)
        }
        .clipped()
        .gesture(ArrastoParaApagar(aberta: estaAberta, mudou: { t in
            arrasto = t
            let alem = !estaAberta && posicao(base: 0, arrasto: t) < -Self.limiar
            if alem != passou { passou = alem }
        }, terminou: { t, velocidade in soltar(t, velocidade: velocidade, estavaAberta: estaAberta) }))
        .sensoryFeedback(.impact(weight: .medium), trigger: passou) { antes, agora in agora && !antes }
    }

    /// A posição da linha: até −revelado acompanha o dedo; além, estica com um quarto do arrasto; nunca passa de 0.
    private func posicao(base: CGFloat, arrasto: CGFloat) -> CGFloat {
        let p = base + arrasto
        if p > 0 { return 0 }
        if p < -revelado { return -revelado + (p + revelado) * 0.25 }
        return p
    }

    private func soltar(_ t: CGFloat, velocidade: CGFloat, estavaAberta: Bool) {
        let p = posicao(base: estavaAberta ? -revelado : 0, arrasto: t)
        // O ponto final projetado com o impulso (taxa 0,995 por ms, como o gestos.js): ~0,2 s de velocidade.
        let abrir = -(p + velocidade * 0.199) > Self.limiar
        let alvo: CGFloat = abrir ? -revelado : 0
        let distancia = alvo - p
        // A mola parte da velocidade do dedo, medida em "distâncias por segundo" (o que a API pede); só a favor do alvo
        // e limitada, para um arremesso não atravessar o botão.
        let inicial = distancia == 0 ? 0 : min(max(velocidade / distancia, 0), 15)
        let animacao: Animation = opcoes.reduzirMovimento ? .easeOut(duration: 0.2)
            : .interpolatingSpring(Spring(duration: 0.3, bounce: 0), initialVelocity: inicial)
        withAnimation(animacao) {
            arrasto = 0
            if abrir { aberta = id } else if aberta == id { aberta = nil }
        }
        passou = false
    }
}

/// O pan do UIKit: começa só num arrasto mais horizontal que vertical (|dx| > 1,2·|dy|, como o gestos.js), para a
/// esquerda (para a direita só com a linha aberta, para fechar) e fora dos 20 pt da borda esquerda (o voltar do
/// sistema). Vertical fica com a rolagem.
struct ArrastoParaApagar: UIGestureRecognizerRepresentable {
    let aberta: Bool
    let mudou: (CGFloat) -> Void
    let terminou: (CGFloat, CGFloat) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordenador { Coordenador() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        context.coordinator.aberta = aberta
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.aberta = aberta
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let t = recognizer.translation(in: recognizer.view).x
        switch recognizer.state {
        case .began, .changed: mudou(t)
        case .ended: terminou(t, recognizer.velocity(in: recognizer.view).x)
        case .cancelled, .failed: terminou(0, 0)
        default: break
        }
    }

    @MainActor final class Coordenador: NSObject, UIGestureRecognizerDelegate {
        var aberta = false

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            if let janela = pan.view?.window, pan.location(in: janela).x < 20 { return false }
            let v = pan.velocity(in: pan.view)
            guard abs(v.x) > abs(v.y) * 1.2 else { return false }
            return v.x < 0 || aberta
        }
    }
}
```

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -9,13 +9,28 @@ struct ObraView: View {
     let id: String
     @Binding var caminho: [RotaDeObras]
     @Environment(ModeloApp.self) private var modelo
+    @Environment(Folhas.self) private var folhas
+    @Environment(\.opcoes) private var opcoes
     @State private var aVencerAberto = false
+    /// A linha arrastada que mostra "Apagar" (uma por vez).
+    @State private var linhaAberta: String?
+    /// "Apagar" tocado na linha: o gasto da pergunta. Fica depois que o alerta fecha, para ele não trocar de texto saindo.
+    @State private var alvoDoApagar: Gasto?
+    @State private var perguntando = false
+    @State private var naoCarregado = false
+    @State private var contaReal = false
+    /// Os gastos que acabaram de ser salvos (acesos por 2 s) e se levam a etiqueta "novo".
+    @State private var acesos: Set<String> = []
+    @State private var novos = false
+    @AccessibilityFocusState private var foco: AlvoDoFoco?
     /// O título pequeno mora num objeto próprio, lido só pela peça da barra: ao cruzar o limite no meio da rolagem, só
     /// ela se refaz, e não a tela inteira (lista, indicadores e cartões).
     @State private var barra = BarraDaObra()
     #if DEBUG
     /// Laudo de leitura e conferência visual: a tela parada numa rolagem dada, em pt (o mesmo gancho de Obras).
     @AppStorage("custta.rolagem") private var rolagemFixa = -1.0
+    /// Laudo e conferência visual: a linha que abre mostrando "Apagar" (`-custta.linhaAberta g027`).
+    @AppStorage("custta.linhaAberta") private var linhaDeTeste = ""
     @State private var posicao = ScrollPosition(edge: .top)
     #endif
 
@@ -35,27 +50,57 @@ struct ObraView: View {
     private func conteudo(_ obra: Obra, taxa: Double, topicos: [String: Topico]) -> some View {
         let hoje = dataLocalISO(.now, fuso: .current)
         let lista = listaDaObra(obra, hoje: hoje)
-        return ScrollView {
-            LazyVStack(alignment: .leading, spacing: 10) {
-                TituloDaObra(nome: obra.nome)
-                PilulaDaFase(obra: obra, hoje: hoje)
-                IndicadoresDaObraView(indicadores: indicadoresDaObra(obra, taxa: taxa, hoje: hoje))
-                    .padding(.bottom, 14)
-                PilulaDeLancamentos(quantidade: obra.gastos.count)
-                if obra.gastos.isEmpty {
-                    CartaoDeEstado(titulo: "Nenhum gasto lançado.", texto: "Toque no + para lançar o primeiro.",
-                                   identificador: "obraSemGastos", icone: "Icones/notas") { EmptyView() }
-                } else {
-                    if let aVencer = lista.aVencer {
-                        CartaoDoAVencer(grupo: aVencer, aberto: $aVencerAberto, topicos: topicos)
+        let acoes = AcoesDaLista(aberta: $linhaAberta, acesos: acesos, novos: novos, foco: $foco,
+                                 tocar: { gasto in
+                                     if linhaAberta != nil { fecharLinha(); return }
+                                     folhas.aberta = .editarGasto(obraId: obra.id, gastoId: gasto.id)
+                                 },
+                                 apagar: { gasto in
+                                     alvoDoApagar = gasto
+                                     perguntando = true
+                                 })
+        return ScrollViewReader { leitor in
+            ScrollView {
+                LazyVStack(alignment: .leading, spacing: 10) {
+                    TituloDaObra(nome: obra.nome)
+                    PilulaDaFase(obra: obra, hoje: hoje)
+                    IndicadoresDaObraView(indicadores: indicadoresDaObra(obra, taxa: taxa, hoje: hoje))
+                        .padding(.bottom, 14)
+                    PilulaDeLancamentos(quantidade: obra.gastos.count)
+                        .accessibilityFocused($foco, equals: .lancamentos)
+                    if obra.gastos.isEmpty {
+                        CartaoDeEstado(titulo: "Nenhum gasto lançado.", texto: "Toque no + para lançar o primeiro.",
+                                       identificador: "obraSemGastos", icone: "Icones/notas") { EmptyView() }
+                    } else {
+                        if let aVencer = lista.aVencer {
+                            CartaoDoAVencer(grupo: aVencer, aberto: $aVencerAberto, topicos: topicos, lista: acoes)
+                                .id("aVencer")
+                        }
+                        ForEach(lista.meses) { mes in
+                            CartaoDoMes(mes: mes, topicos: topicos, lista: acoes).id("mes-\(mes.id)")
+                        }
                     }
-                    ForEach(lista.meses) { mes in CartaoDoMes(mes: mes, topicos: topicos) }
                 }
+                .padding(.horizontal, 20)
+                .padding(.bottom, 24)
+                // Tocar fora da linha aberta fecha (o "Apagar" é um botão e vence este toque).
+                .contentShape(.rect)
+                .onTapGesture { if linhaAberta != nil { fecharLinha() } }
             }
-            .padding(.horizontal, 20)
-            .padding(.bottom, 24)
+            .onChange(of: folhas.destaque) { _, d in if let d { mostrar(d, lista: lista, leitor: leitor) } }
         }
         .scrollIndicators(.hidden)
+        .onScrollPhaseChange { _, fase in if fase != .idle, linhaAberta != nil { fecharLinha() } }
+        .onChange(of: folhas.aberta) { _, aberta in if aberta != nil { linhaAberta = nil } }
+        .onChange(of: folhas.pedidoDeApagar) { _, p in if let p, p.obraId == obra.id { apagar(p, obra: obra, lista: lista) } }
+        .onDisappear { linhaAberta = nil }
+        .sensoryFeedback(.success, trigger: folhas.destaque)
+        .modifier(PerguntaDeApagar(apresentada: $perguntando, obraId: obra.id, gasto: alvoDoApagar) { pedido in
+            apagar(pedido, obra: obra, lista: lista)
+        })
+        .onChange(of: perguntando) { _, agora in if !agora { fecharLinha() } }
+        .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) { Button("OK", role: .cancel) {} }
+        .alert(ContaDeTeste.titulo, isPresented: $contaReal) { Button("OK", role: .cancel) {} } message: { Text(ContaDeTeste.mensagem) }
         // O título pequeno entra na barra quando o grande sai de baixo dela (como o título grande do sistema).
         .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 44 } action: { _, saiu in
             withAnimation(.easeOut(duration: 0.2)) { barra.tituloVisivel = saiu }
@@ -63,6 +108,7 @@ struct ObraView: View {
         #if DEBUG
         .scrollPosition($posicao)
         .task {
+            if !linhaDeTeste.isEmpty { linhaAberta = linhaDeTeste }
             guard rolagemFixa >= 0 else { return }
             try? await Task.sleep(for: .milliseconds(300))
             posicao.scrollTo(y: rolagemFixa)
@@ -81,6 +127,102 @@ struct ObraView: View {
     }
 }
 
+extension ObraView {
+    private func fecharLinha() {
+        guard linhaAberta != nil else { return }
+        if opcoes.reduzirMovimento { linhaAberta = nil } else { withAnimation(.spring(duration: 0.3, bounce: 0)) { linhaAberta = nil } }
+    }
+
+    /// Depois de salvar: abre o "A vencer" se o gasto foi para lá, rola em dois tempos (o cartão do mês, que a LazyVStack
+    /// cria, e depois a linha), acende por 2 s e leva o VoiceOver para a linha.
+    private func mostrar(_ d: Folhas.Destaque, lista: ListaDaObra, leitor: ScrollViewProxy) {
+        guard let primeiro = d.ids.first else { return }
+        let noAVencer = lista.aVencer?.meses.contains { $0.gastos.contains { $0.id == primeiro } } ?? false
+        let cartao = noAVencer ? "aVencer" : lista.meses.first { $0.gastos.contains { $0.id == primeiro } }.map { "mes-\($0.id)" }
+        if noAVencer { aVencerAberto = true }
+        acesos = Set(d.ids)
+        novos = d.novo
+        Task { @MainActor in
+            if let cartao { leitor.scrollTo(cartao, anchor: .center) }
+            try? await Task.sleep(for: .milliseconds(80))
+            withAnimation(opcoes.reduzirMovimento ? nil : .easeOut(duration: 0.3)) { leitor.scrollTo(primeiro, anchor: .center) }
+            try? await Task.sleep(for: .milliseconds(450))
+            foco = .gasto(primeiro)
+            try? await Task.sleep(for: .seconds(2))
+            guard folhas.destaque == d else { return }
+            withAnimation(.easeOut(duration: 0.4)) { acesos = [] }
+        }
+    }
+
+    /// Apaga um gasto (ou a compra toda) com a animação do sistema: a linha sai pela esquerda, as de baixo sobem e os
+    /// totais mudam na mesma transação. Depois, o VoiceOver vai para a linha vizinha (ou para "Lançamentos") e ouve o
+    /// que aconteceu, um depois do outro.
+    private func apagar(_ p: Folhas.PedidoDeApagar, obra: Obra, lista: ListaDaObra) {
+        let saem: Set<String> = p.grupoId.map { g in Set(obra.gastos.filter { $0.grupoId == g }.map(\.id)) } ?? [p.gastoId]
+        let ordem = (aVencerAberto ? (lista.aVencer?.meses ?? []) : []).flatMap(\.gastos).map(\.id)
+            + lista.meses.flatMap(\.gastos).map(\.id)
+        let vizinho = vizinhoDepoisDeApagar(saem, ordem: ordem)
+        linhaAberta = nil
+        let resultado = withAnimation(opcoes.reduzirMovimento ? nil : .snappy(duration: 0.35)) {
+            modelo.gravar { e in p.grupoId.map { e.apagandoCompra($0, daObra: p.obraId) } ?? e.apagandoGasto(p.gastoId, daObra: p.obraId) }
+        }
+        if resultado == .naoCarregado { naoCarregado = true; return }
+        if resultado == .contaReal { contaReal = true; return }
+        guard resultado == .gravou else { return }
+        Task { @MainActor in
+            try? await Task.sleep(for: .milliseconds(500))
+            foco = vizinho.map(AlvoDoFoco.gasto) ?? .lancamentos
+            try? await Task.sleep(for: .milliseconds(700))
+            var aviso = AttributedString(saem.count > 1 ? "Compra apagada" : "Gasto apagado")
+            aviso.accessibilitySpeechAnnouncementPriority = .low
+            AccessibilityNotification.Announcement(aviso).post()
+        }
+    }
+}
+
+/// Onde o VoiceOver vai depois de apagar: a próxima linha que fica na lista, senão a anterior; nil, "Lançamentos".
+func vizinhoDepoisDeApagar(_ saem: Set<String>, ordem: [String]) -> String? {
+    guard let i = ordem.firstIndex(where: saem.contains) else { return nil }
+    return ordem[i...].first { !saem.contains($0) } ?? ordem[..<i].last { !saem.contains($0) }
+}
+
+/// Para onde o VoiceOver vai na lista da obra.
+enum AlvoDoFoco: Hashable {
+    case gasto(String)
+    case lancamentos
+}
+
+/// O que as linhas da lista fazem, passado do ObraView aos cartões.
+struct AcoesDaLista {
+    let aberta: Binding<String?>
+    let acesos: Set<String>
+    let novos: Bool
+    let foco: AccessibilityFocusState<AlvoDoFoco?>.Binding
+    let tocar: (Gasto) -> Void
+    let apagar: (Gasto) -> Void
+}
+
+/// Uma linha de gasto na lista: tocar edita, arrastar mostra "Apagar", acende depois de salvar. Para o VoiceOver é um
+/// botão (abre a edição) com a ação "Apagar"; o Controle por Voz chama pelo título.
+struct LinhaDaLista: View {
+    let gasto: Gasto
+    let linha: LinhaDeGasto
+    let lista: AcoesDaLista
+
+    var body: some View {
+        LinhaArrastavel(id: gasto.id, aberta: lista.aberta, apagar: { lista.apagar(gasto) }) {
+            LinhaDeGastoView(gasto: gasto, linha: linha, acesa: lista.acesos.contains(gasto.id), novo: lista.novos)
+                .onTapGesture { lista.tocar(gasto) }
+                .accessibilityAddTraits(.isButton)
+                .accessibilityAction { lista.tocar(gasto) }
+                .accessibilityInputLabels([linha.titulo])
+                .accessibilityFocused(lista.foco, equals: .gasto(gasto.id))
+        }
+        .id(gasto.id)
+        .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
+    }
+}
+
 /// Se o título pequeno aparece na barra da obra.
 @MainActor @Observable
 final class BarraDaObra {
@@ -129,6 +271,7 @@ struct CartaoDoAVencer: View {
     let grupo: GrupoAVencer
     @Binding var aberto: Bool
     let topicos: [String: Topico]
+    let lista: AcoesDaLista
     @Environment(\.opcoes) private var opcoes
     @Environment(\.paleta) private var paleta
 
@@ -154,13 +297,19 @@ struct CartaoDoAVencer: View {
     }
 
     private func alternar() {
+        // Com uma linha aberta, o toque só fecha a linha.
+        if lista.aberta.wrappedValue != nil {
+            if opcoes.reduzirMovimento { lista.aberta.wrappedValue = nil }
+            else { withAnimation(.spring(duration: 0.3, bounce: 0)) { lista.aberta.wrappedValue = nil } }
+            return
+        }
         if opcoes.reduzirMovimento { aberto.toggle() } else { withAnimation(.snappy) { aberto.toggle() } }
     }
 
     @ViewBuilder private func linhas(_ mes: MesDeGastos) -> some View {
         ForEach(Array(mes.gastos.enumerated()), id: \.element.id) { i, gasto in
             if i > 0 { LinhaFina().padding(.leading, 67) }
-            LinhaDeGastoView(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos))
+            LinhaDaLista(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos), lista: lista)
         }
     }
 }
@@ -169,6 +318,7 @@ struct CartaoDoAVencer: View {
 struct CartaoDoMes: View {
     let mes: MesDeGastos
     let topicos: [String: Topico]
+    let lista: AcoesDaLista
     @Environment(\.paleta) private var paleta
 
     var body: some View {
@@ -176,7 +326,7 @@ struct CartaoDoMes: View {
             CabecalhoDoMes(mes: mes)
             ForEach(Array(mes.gastos.enumerated()), id: \.element.id) { i, gasto in
                 if i > 0 { LinhaFina().padding(.leading, 67) }
-                LinhaDeGastoView(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos))
+                LinhaDaLista(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos), lista: lista)
             }
             Color.clear.frame(height: 6)
         }
```

Em `app-ios/Custta/Telas/PecasDaObra.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDaObra.swift
+++ b/app-ios/Custta/Telas/PecasDaObra.swift
@@ -258,6 +258,9 @@ struct LinhaDoAVencer: View {
 struct LinhaDeGastoView: View {
     let gasto: Gasto
     let linha: LinhaDeGasto
+    /// Acabou de ser salvo: o fundo Aceso por 2 s; `novo` põe a etiqueta (gasto lançado, não editado).
+    var acesa = false
+    var novo = false
     @Environment(\.paleta) private var paleta
     @Environment(\.vidro) private var vidro
     @Environment(\.dynamicTypeSize) private var tamanho
@@ -268,6 +271,7 @@ struct LinhaDeGastoView: View {
         }
         .padding(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18))
         .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
+        .background(acesa ? paleta.cor(.aceso) : .clear)
         .contentShape(.rect)
         .accessibilityElement(children: .ignore)
         .accessibilityLabel(linha.rotulo)
@@ -304,7 +308,10 @@ struct LinhaDeGastoView: View {
     }
 
     private var titulo: some View {
-        Text(linha.titulo).font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
+        HStack(spacing: 8) {
+            Text(linha.titulo).font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
+            if acesa && novo { EtiquetaNovo() }
+        }
     }
 
     private var valor: some View { ValorEmDinheiro(texto: linha.valor, fonte: .body.weight(.semibold)) }
@@ -328,6 +335,21 @@ struct LinhaDeGastoView: View {
     }
 }
 
+/// A etiqueta "novo" da linha que acabou de ser lançada (some com o destaque, em ~2 s).
+struct EtiquetaNovo: View {
+    @Environment(\.paleta) private var paleta
+
+    var body: some View {
+        Text("novo")
+            .font(.caption.weight(.bold))
+            .foregroundStyle(paleta.cor(.sobreMarca))
+            .padding(.horizontal, 8)
+            .padding(.vertical, 1)
+            .background(paleta.cor(.marca), in: .capsule)
+            .accessibilityHidden(true)
+    }
+}
+
 /// A linha fina entre as linhas de um cartão (hairline), na cor do token Linha.
 struct LinhaFina: View {
     @Environment(\.paleta) private var paleta
```


- [ ] **Step 4: Ver passar**

Run: `-only-testing:CusttaUITests/GastoUITests -only-testing:CusttaUITests/ObraUITests -only-testing:CusttaTests`.
Expected: os 13 de `GastoUITests`, os 7 de `ObraUITests` (o voltar pela borda continua com o arrastar) e os 98 de `CusttaTests` verdes.

- [ ] **Step 5: Conferência visual (Verniz)**

`parte2-lancar-8.png` (linha acesa), `parte2-apagar-1.png` (com `-custta.rolagem 640 -custta.linhaAberta g027`), `apagar-2` e `apagar-3`; e a animação de apagar gravada (`xcrun simctl io <udid> recordVideo`), com o Reduzir movimento ligado e desligado.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Falsos/MontarFalso.swift \
  app-ios/Custta/Falsos/TransporteFalsoApp.swift \
  app-ios/Custta/Telas/LinhaArrastavel.swift \
  app-ios/Custta/Telas/ObraView.swift \
  app-ios/Custta/Telas/PecasDaObra.swift \
  app-ios/CusttaTests/GravacaoDoAppTests.swift \
  app-ios/CusttaUITests/Abrir.swift \
  app-ios/CusttaUITests/GastoUITests.swift
git commit -m "feat: editar tocando na linha e apagar arrastando, com a animação do sistema" -m "Tocar num gasto abre a edição; arrastar para a esquerda mostra o Apagar, que pergunta com o nome e o valor e tira a linha com a animação do sistema, com os totais mudando juntos; a parcela oferece só esta ou a compra toda. O arrastar é próprio, com a física da List, porque a List não desenha um cartão de vidro por mês. Depois de salvar, a lista rola até o gasto e o acende; o VoiceOver acompanha o gasto novo e, depois de apagar, a linha vizinha."
```

### Task 24: Leitura sobre o vidro e auditoria da folha do gasto

O laudo mede a folha em cada passo (valor, detalhes, cartão, tópicos, parcela e repetido) nos quatro combos, a linha aberta com o "Apagar", a maior letra e o Aumentar contraste: 32 cenas, todas acima de 4,5:1 no protótipo (pior 4,87 na lista com a linha aberta; na folha, 5,06). As auditorias passam pela folha na maior letra e no contraste dos quatro combos, com as exceções de desenho por identificador (título da folha perto de 22 pt, visor de 64 pt, teclas e "Apagar" até o AX2). Os identificadores por texto no título e no visor e a folha opaca com Reduzir transparência (Tarefa 22) vieram do que estas auditorias acharam no protótipo.

**Files:**
- Test (alterar): `app-ios/CusttaUITests/AuditoriaUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`

- [ ] **Step 1: Escrever as cenas e as auditorias**

Em `app-ios/CusttaUITests/AuditoriaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -28,7 +28,9 @@ final class AuditoriaUITests: XCTestCase {
     /// navegação, da cápsula, do indicador de início ou da borda de rolagem (contraste: ele é auditado quando
     /// está à vista). Os rótulos da própria cápsula entram na auditoria de contraste.
     @MainActor private func auditar(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType) throws {
-        let abas = ["aba-obras", "aba-ajustes", "botaoMais"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
+        // Com a folha aberta, a cápsula fica atrás dela: nada da folha é cortado pela regra da cápsula.
+        let folha = app.elemento("tituloDaFolha").exists
+        let abas = folha ? [] : ["aba-obras", "aba-ajustes", "botaoMais"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
         let fundoDaTela = abas.isEmpty ? app.frame.maxY : min(abas.map(\.minY).min()!, app.frame.maxY - borda)
         let barra = app.navigationBars.firstMatch
         let topoDoConteudo = barra.exists ? max(barra.frame.maxY, borda) : 0
@@ -43,7 +45,11 @@ final class AuditoriaUITests: XCTestCase {
             case .dynamicType:
                 // O título pequeno da barra da obra para perto de 22 pt, como o do sistema (mockup da etapa 2), com o
                 // Visualizador de Conteúdo Grande.
+                // Na folha (mockup da etapa 2): o título para perto de 22 pt, as teclas e o "Apagar" do arrastar param no
+                // AX2, e o visor do valor (64 pt) já é maior que o texto na maior letra e encolhe para caber.
                 fora = elemento.label == "Continuar com o Google" || elemento.identifier == "tituloPequenoDaBarra"
+                    || elemento.identifier.hasPrefix("tituloDaFolha") || elemento.identifier.hasPrefix("visorDoValor")
+                    || elemento.identifier.hasPrefix("tecla-") || elemento.identifier.hasPrefix("apagar-")
                     || abas.contains { $0.contains(CGPoint(x: elemento.frame.midX, y: elemento.frame.midY)) }
             case .contrast:
                 if elemento.identifier.hasPrefix("aba-") { fora = false }   // o rótulo da própria cápsula
@@ -105,6 +111,39 @@ final class AuditoriaUITests: XCTestCase {
         try auditar(app, tiposDeAuditoria)
     }
 
+    /// A folha do gasto (etapa 2, PR 2) em cada passo, na maior letra; os detalhes também rolados.
+    @MainActor func testFolhaDoGastoNoMaiorTamanho() throws {
+        for (passo, espera) in [("valor", "visorDoValor"), ("detalhes", "linhaTopico"), ("cartao", "linhaTopico"),
+                                ("topicos", "topico-terreno"), ("editar:g031", "avisoParcela")] {
+            let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: maiorLetra + parado + ["-custta.folha", passo])
+            XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), passo)
+            try auditar(app, tiposDeAuditoria)
+            if passo != "valor" {
+                rolar(app)
+                try auditar(app, tiposDeAuditoria)
+            }
+            app.terminate()
+        }
+    }
+
+    /// A folha do gasto (valor e cartão) e a linha aberta com o "Apagar", nos quatro combos, com superfícies sólidas.
+    @MainActor func testContrasteDaFolhaNosQuatroCombos() throws {
+        for (tema, pele) in quatroCombos {
+            let combo = ["-custta.tema", tema, "-custta.pele", pele] + solido + parado
+            for (passo, espera) in [("valor", "visorDoValor"), ("cartao", "resumoDoCartao")] {
+                let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: combo + ["-custta.folha", passo])
+                XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), passo)
+                try auditar(app, [.contrast])
+                app.terminate()
+            }
+            let lista = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1",
+                                 argumentos: combo + ["-custta.rolagem", "640", "-custta.linhaAberta", "g027"])
+            XCTAssertTrue(lista.buttons["apagar-g027"].waitForExistence(timeout: 10))
+            try auditar(lista, [.contrast])
+            lista.terminate()
+        }
+    }
+
     @MainActor func testAjustesNoMaiorTamanho() throws {
         let app = abrirApp(conta: "senha-nao-confirmada", argumentos: maiorLetra + parado)
         app.abrirAba("ajustes")
```

Em `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -337,6 +337,40 @@ extension LeituraNoVidroUITests {
         }
         cobrar(cenas)
     }
+
+    /// A folha do gasto (PR 2 da etapa 2): o teclado de valor, os detalhes no Pix e no cartão (o resumo e a ajuda ficam
+    /// direto na Folha), a lista de tópicos, a edição de uma parcela e o "Salvar mesmo assim" âmbar, nos quatro combos;
+    /// na maior letra e com Aumentar contraste; e a linha arrastada com o "Apagar" na lista da obra.
+    @MainActor func testLeituraDaFolhaDoGasto() {
+        func folha(_ nome: String, _ passo: String, _ argumentos: [String], espera: String) -> Cena {
+            Cena(nome: nome, conta: "senha", argumentos: argumentos + ["-custta.folha", passo], espera: espera, escopo: "tudo",
+                 dados: "vitrine", abrir: "obra:v1")
+        }
+        var cenas: [Cena] = []
+        for (tema, pele) in quatroCombos {
+            let combo = ["-custta.tema", tema, "-custta.pele", pele] + piorMomento
+            cenas += [
+                folha("folha, valor, \(tema), \(pele)", "valor", combo, espera: "visorDoValor"),
+                folha("folha, detalhes, \(tema), \(pele)", "detalhes", combo, espera: "linhaTopico"),
+                folha("folha, cartão, \(tema), \(pele)", "cartao", combo, espera: "resumoDoCartao"),
+                folha("folha, tópicos, \(tema), \(pele)", "topicos", combo, espera: "topico-terreno"),
+                folha("folha, parcela, \(tema), \(pele)", "editar:g031", combo, espera: "avisoParcela"),
+                folha("folha, repetido, \(tema), \(pele)", "repetido", combo, espera: "avisoRepetido"),
+                Cena(nome: "obra, linha aberta, \(tema), \(pele)", conta: "senha",
+                     argumentos: combo + ["-custta.rolagem", "640", "-custta.linhaAberta", "g027"], espera: "apagar-g027",
+                     escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
+            ]
+        }
+        let escuro = ["-custta.tema", "escuro", "-custta.pele", "esmeralda"] + piorMomento
+        let contraste = escuro + ["-custta.aumentarContraste", "YES"]
+        cenas += [
+            folha("folha, valor, na maior letra", "valor", escuro + maiorLetra, espera: "visorDoValor"),
+            folha("folha, cartão, na maior letra", "cartao", escuro + maiorLetra, espera: "linhaTopico"),
+            folha("folha, cartão, com Aumentar contraste", "cartao", contraste, espera: "resumoDoCartao"),
+            folha("folha, repetido, com Aumentar contraste", "repetido", contraste, espera: "avisoRepetido"),
+        ]
+        cobrar(cenas)
+    }
 }
 
 /* O medidor com imagens sintéticas: sem abrir o app. */
```


- [ ] **Step 2: Rodar**

Run: `xcodebuild build-for-testing "${XB[@]}"` e `xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaFolhaDoGasto -only-testing:CusttaUITests/AuditoriaUITests/testFolhaDoGastoNoMaiorTamanho -only-testing:CusttaUITests/AuditoriaUITests/testContrasteDaFolhaNosQuatroCombos`
Expected: `0 abaixo` nas 32 cenas; as duas auditorias verdes. Uma cena abaixo de 4,5:1 para a tarefa: a correção é no token ou no escurecimento, com o laudo de novo.

- [ ] **Step 3: Commit**

```bash
git add app-ios/CusttaUITests/AuditoriaUITests.swift \
  app-ios/CusttaUITests/LeituraNoVidroUITests.swift
git commit -m "test: leitura sobre o vidro e auditoria da folha do gasto" -m "O laudo de leitura mede a folha do gasto em cada passo, nos quatro combos, na maior letra e com Aumentar contraste, e a linha aberta com o Apagar. As auditorias do Xcode passam pela folha, com as exceções de desenho do mockup nomeadas por identificador."
```

### Task 25: Conferência cruzada do gasto lançado, editado e apagado no app

A metade app do `cruzado.mjs` deixa de acrescentar um gasto cru e segue um roteiro pelas mesmas regras das telas: lançar no Pix, lançar no cartão em 3x a 2,5%, editar um gasto do site (Pix para cartão, sem perder o campo que só o site conhece), editar uma parcela, apagar um gasto da obra vendida e apagar a compra toda, cada passo gravado pelo Sincronizador com os ids do roteiro. O roteiro calcula o que o site gravaria com as mesmas respostas (`dados.js`, os mesmos ids) e compara o documento inteiro.

**Files:**
- Test (alterar): `app-ios/CusttaTests/CruzadoTests.swift`
- Test (alterar): `tests/app-ios/cruzado.mjs`

- [ ] **Step 1: Escrever o roteiro nos dois lados**

Em `app-ios/CusttaTests/CruzadoTests.swift`:

```diff
--- a/app-ios/CusttaTests/CruzadoTests.swift
+++ b/app-ios/CusttaTests/CruzadoTests.swift
@@ -4,25 +4,58 @@ import FirebaseAuth
 @testable import Custta
 import CusttaNucleo
 
-/* Metade app da conferência cruzada (tests/app-ios/cruzado.mjs): entra na conta que o "site"
-   criou, carrega o documento, lança um gasto (o que o roteiro mandou) e grava pelo Sincronizador,
-   como uma edição da etapa 2 fará. O roteiro confere depois, com o SDK JavaScript, que o gasto
-   chegou e que nada do site se perdeu. */
+/* Metade app da conferência cruzada (tests/app-ios/cruzado.mjs): entra na conta que o "site" criou, carrega o
+   documento e segue o roteiro de gastos do site (lançar no Pix e no cartão parcelado, editar um gasto e uma parcela,
+   apagar um gasto e a compra toda) pelas mesmas regras das telas: o núcleo confere e monta cada gasto, o estado muda
+   pelas mutações e cada passo grava pelo Sincronizador, como um toque em "Salvar" ou "Apagar". Os ids vêm do roteiro,
+   para o site montar o mesmo resultado. O roteiro confere depois, com o SDK JavaScript, que o documento é o que o
+   site gravaria com as mesmas respostas e que nada do site se perdeu. */
 @MainActor
 @Suite(.enabled(if: ProcessInfo.processInfo.environment["CUSTTA_CRUZADO"] == "1"))
 struct CruzadoTests {
-    @Test func appLancaGastoQueOSiteVe() async throws {
+    @Test func appSegueORoteiroDeGastosDoSite() async throws {
         let ambiente = ProcessInfo.processInfo.environment
         let u = try await Auth.auth(app: Emulador.app).signIn(withEmail: ambiente["CUSTTA_EMAIL"]!, password: ambiente["CUSTTA_SENHA"]!).user
         let s = Sincronizador(transporte: TransporteFirebase(banco: Emulador.banco), relogio: RelogioDoSistema())
         s.iniciar(uid: u.uid)
         for _ in 0..<200 where !s.dadosCarregados { try await Task.sleep(for: .milliseconds(50)) }
         try #require(s.dadosCarregados, "o app não carregou o documento que o site gravou")
-        let gasto = try JSONDecoder().decode(ValorJSON.self, from: Data(try #require(ambiente["CUSTTA_GASTO_DO_APP"]).utf8))
-        var estado = s.estado
-        let i = try #require(estado.obras.firstIndex { $0.id == ambiente["CUSTTA_OBRA_DO_APP"] }, "a obra do roteiro não está no documento")
-        estado.obras[i].gastos.append(Gasto(campos: try #require(gasto.comoObjeto)))
-        try await s.salvar(estado)
+        let roteiro = try JSONDecoder().decode(ValorJSON.self, from: Data(try #require(ambiente["CUSTTA_ROTEIRO"]).utf8))
+        var ids = try #require(ambiente["CUSTTA_IDS"]).split(separator: ",").map(String.init)
+        let novoId = { ids.removeFirst() }
+        let hoje = try #require(ambiente["CUSTTA_HOJE"])
+        var ultima: Gravacao?
+        for passo in try #require(roteiro.comoLista) {
+            let p = try #require(passo.comoObjeto)
+            let acao = try #require(p["acao"]?.comoTexto), obraId = try #require(p["obra"]?.comoTexto)
+            let obra = try #require(s.estado.obras.first { $0.id == obraId }, "a obra \(obraId) do roteiro")
+            let novo: Estado?
+            switch acao {
+            case "lancar":
+                let entrada = try entradaDoRoteiro(p)
+                let conferido = try conferirGasto(entrada, editado: nil, hoje: hoje).get()
+                novo = s.estado.lancandoGastos(gastosLancados(entrada, conferido, novoId: novoId), naObra: obraId)
+            case "editar":
+                let editado = try #require(obra.gastos.first { $0.id == p["gasto"]?.comoTexto })
+                let entrada = try entradaDoRoteiro(p)
+                let conferido = try conferirGasto(entrada, editado: editado, hoje: hoje).get()
+                novo = s.estado.editandoGasto(editado.id, entrada, conferido, naObra: obraId)
+            case "apagar":
+                novo = s.estado.apagandoGasto(try #require(p["gasto"]?.comoTexto), daObra: obraId)
+            default:
+                novo = s.estado.apagandoCompra(try #require(p["grupo"]?.comoTexto), daObra: obraId)
+            }
+            ultima = try s.aplicar(try #require(novo, "o passo \(acao) achou o que mudar"))
+        }
+        try await #require(ultima).confirmada()
         s.parar()
     }
+
+    private func entradaDoRoteiro(_ passo: [String: ValorJSON]) throws -> EntradaDoGasto {
+        let e = try #require(passo["entrada"]?.comoObjeto)
+        return EntradaDoGasto(valor: try #require(e["valor"]?.comoNumero), topico: try #require(e["topico"]?.comoTexto),
+                              descricao: e["descricao"]?.comoTexto ?? "", data: e["data"]?.comoTexto ?? "",
+                              pagamento: try #require(e["pagamento"]?.comoTexto), parcelas: Int(e["parcelas"]?.comoNumero ?? 1),
+                              juros: e["juros"]?.comoNumero ?? 0)
+    }
 }
```

Em `tests/app-ios/cruzado.mjs`:

```diff
--- a/tests/app-ios/cruzado.mjs
+++ b/tests/app-ios/cruzado.mjs
@@ -8,9 +8,12 @@
         tópico estourado, obra com compra parcelada no cartão com juros e campos que só o site conhece);
      2. CruzadoUITests entra pelo formulário e confere o total e o orçamento que o calc.js calculou;
      3. o teste pede a v2 (POST no auxiliar abaixo) e espera ver os números novos sozinhos;
-     4. CruzadoTests lança um gasto no app e grava pelo Sincronizador;
-     5. este roteiro confere que o documento final foi gravado pelo app (o _atualizado avançou),
-        que é exatamente a v2 normalizada com o gasto do app e que o site soma esse gasto.
+     4. CruzadoTests segue o roteiro de gastos abaixo pelas regras das telas do app (lançar no Pix e no cartão
+        parcelado com juros, editar um gasto do site e uma parcela, apagar um gasto da obra vendida e a compra
+        toda), gravando cada passo pelo Sincronizador;
+     5. este roteiro confere que o documento final foi gravado pelo app (o _atualizado avançou), que é
+        exatamente o que o site gravaria com as mesmas respostas (dados.js, com os mesmos ids), sem perder os
+        campos que só o site conhece, e que o site soma o resultado.
    Teste pulado não passa: sem o pedido de mudança ou sem a gravação do app, o roteiro falha. */
 import assert from 'node:assert/strict';
 import { createServer } from 'node:http';
@@ -61,7 +64,34 @@ const v1 = {
 };
 const v2 = structuredClone(v1);
 v2.obras[0].gastos.push({ id: 'x2', valor: 40000, topico: 'estrutura', descricao: 'Laje', data: '2026-03-01', pagamento: 'pix' });
-const gastoDoApp = { id: 'w1app', valor: 999.99, topico: 'pintura', descricao: 'Tinta lançada no app', data: '2026-04-01', pagamento: 'pix' };
+/* O roteiro de gastos do app (etapa 2): cada passo é o que a pessoa responde na folha do gasto. Os ids dos gastos
+   novos vêm daqui, para o site montar o mesmo resultado com as regras dele. */
+const HOJE = '2026-04-01';
+const roteiro = [
+  { acao: 'lancar', obra: 'c1', entrada: { valor: 999.99, topico: 'pintura', descricao: 'Tinta lançada no app', data: '2026-04-01', pagamento: 'pix' } },
+  { acao: 'lancar', obra: 'c1', entrada: { valor: 3000, topico: 'eletrica', descricao: 'Quadro de luz', data: '2026-04-10', pagamento: 'cartao', parcelas: 3, juros: 2.5 } },
+  { acao: 'editar', obra: 'c1', gasto: 'x1', entrada: { valor: 12000, topico: 'fundacao', descricao: 'Sapatas e baldrames', data: '2026-02-02', pagamento: 'cartao' } },
+  { acao: 'editar', obra: 'c3', gasto: 'z2', entrada: { valor: 1100, topico: 'eletrica', descricao: 'Fios e disjuntores', data: '2026-04-10', pagamento: 'cartao' } },
+  { acao: 'apagar', obra: 'c2', gasto: 'y3' },
+  { acao: 'apagarCompra', obra: 'c3', grupo: 'gz' },
+];
+const ids = ['app1', 'app2', 'app3', 'app4', 'app5'];
+/** O que o site gravaria com as mesmas respostas: as regras do dados.js e os filtros do apagar do app.js. */
+function comoOSite(blob){
+  const db = D.normaliza(structuredClone(blob));
+  const fila = [...ids], novoId = () => fila.shift();
+  for(const p of roteiro){
+    const o = db.obras.find(x => x.id === p.obra);
+    if(p.acao === 'lancar') o.gastos.push(...D.gastosLancados(p.entrada, D.conferirGasto(p.entrada, null, HOJE), novoId));
+    else if(p.acao === 'editar'){
+      const i = o.gastos.findIndex(g => g.id === p.gasto);
+      o.gastos[i] = D.gastoEditado(o.gastos[i], p.entrada, D.conferirGasto(p.entrada, o.gastos[i], HOJE));
+    }
+    else if(p.acao === 'apagar') o.gastos = o.gastos.filter(g => g.id !== p.gasto);
+    else o.gastos = o.gastos.filter(g => g.grupoId !== p.grupo);
+  }
+  return db;
+}
 
 /* O que a lista de obras do site mostra (app.js, renderInicio): total curto na tela, completo para o
    leitor de tela, e a linha do orçamento. */
@@ -83,7 +113,7 @@ await new Promise(r => auxiliar.listen(8124, '127.0.0.1', r));
 
 const env = { CUSTTA_CRUZADO: '1', CUSTTA_EMULADORES: '1', CUSTTA_EMAIL: email, CUSTTA_SENHA: senha,
   CUSTTA_ESPERADO_V1: JSON.stringify(esperado(v1)), CUSTTA_ESPERADO_V2: JSON.stringify(esperado(v2)),
-  CUSTTA_OBRA_DO_APP: 'c1', CUSTTA_GASTO_DO_APP: JSON.stringify(gastoDoApp) };
+  CUSTTA_ROTEIRO: JSON.stringify(roteiro), CUSTTA_IDS: ids.join(','), CUSTTA_HOJE: HOJE };
 let antesDoApp;
 try{
   await testarNoSimulador(['CusttaUITests/CruzadoUITests'], env);
@@ -96,12 +126,23 @@ const final = (await getDocFromServer(documento)).data();
 assert.ok(final._atualizado instanceof Timestamp, 'a gravação do app leva _atualizado do servidor');
 assert.ok(final._atualizado.toMillis() > antesDoApp.toMillis(), 'o documento não foi regravado depois do teste do app: ele foi pulado ou não gravou');
 delete final._atualizado;
-const v3 = structuredClone(v2);
-v3.obras[0].gastos.push(gastoDoApp);
-assert.equal(C.canon(final), C.canon(D.normaliza(v3)), 'o app gravou a v2 normalizada com o gasto lançado nele, sem tirar nem pôr nada');
+const v3 = comoOSite(v2);
+assert.equal(C.canon(final), C.canon(D.normaliza(v3)), 'o app gravou o que o site gravaria com as mesmas respostas, sem tirar nem pôr nada');
 assert.deepEqual(final.obras[0].campoSoDoSite, { versao: 7 }, 'campo de obra que só o site conhece');
-assert.equal(final.obras[0].gastos[0].notaSoDoSite, 'fica', 'campo de gasto que só o site conhece');
-assert.equal(C.money(C.totalBruto(D.normaliza(final).obras[0])), C.money(12345.67 + 40000 + 999.99), 'o site soma o gasto lançado no app');
+const x1 = final.obras[0].gastos.find(g => g.id === 'x1');
+assert.equal(x1.notaSoDoSite, 'fica', 'campo de gasto que só o site conhece, num gasto editado no app');
+assert.equal(x1.pagamento, 'cartao', 'a edição trocou o Pix pelo cartão');
+assert.ok(!('jurosCartao' in x1), 'cartão na edição não ganha juros nem parcelas (app.js:1071)');
+const z = final.obras[2].gastos;
+assert.equal(z.length, 0, 'a compra toda da obra c3 saiu, inclusive a parcela editada');
+assert.deepEqual(final.obras[1].gastos.map(g => g.id), ['y1', 'y2'], 'gasto de obra vendida também se apaga');
+const compraDoApp = final.obras[0].gastos.filter(g => g.grupoId === 'app2');
+assert.deepEqual(compraDoApp.map(g => [g.parcela.n, g.parcela.de, g.data]), [[1, 3, '2026-04-10'], [2, 3, '2026-05-10'], [3, 3, '2026-06-10']],
+  'a compra em 3x lançada no app: as parcelas e as datas do site');
+const cartao = C.parcelamentoCartao(3000, 3, 2.5, '2026-04-10');
+assert.deepEqual(compraDoApp[0].jurosCartao, { taxaMensal: 2.5, valorCompra: 3000, nParcelas: 3, totalCompra: cartao.totalCompra, jurosCompra: cartao.jurosCompra },
+  'as condições da compra, iguais nas parcelas');
+assert.equal(C.money(C.totalBruto(D.normaliza(final).obras[0])), C.money(12000 + 40000 + 999.99 + cartao.totalCompra), 'o site soma o que o app gravou');
 await terminate(db);
-console.log('ok - site e app na mesma conta: totais e orçamentos iguais, mudança do site chegou ao app, gasto lançado no app chegou ao site sem perder nada');
+console.log('ok - site e app na mesma conta: totais e orçamentos iguais, mudança do site chegou ao app, e o roteiro de gastos do app gravou o que o site gravaria, sem perder nada');
 process.exit(0);
```


- [ ] **Step 2: Rodar contra os emuladores**

Run: `CUSTTA_SIMULADOR=<udid> npm run test:app-ios:cruzado 2>&1 | tail -5`
Expected: `ok - site e app na mesma conta: …`. Um passo do app que gravasse diferente do site para em `o app gravou o que o site gravaria com as mesmas respostas`.

- [ ] **Step 3: Commit**

```bash
git add app-ios/CusttaTests/CruzadoTests.swift \
  tests/app-ios/cruzado.mjs
git commit -m "test: conferência cruzada do gasto lançado, editado e apagado no app" -m "A conferência cruzada passa a seguir um roteiro de gastos pelas regras das telas do app: lançar no Pix e no cartão com juros, editar um gasto do site e uma parcela, apagar um gasto da obra vendida e a compra toda. O documento final tem de ser exatamente o que o site gravaria com as mesmas respostas, sem perder os campos que só o site conhece."
```

### Task 26: O gasto no checklist do aparelho e o CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`
- Modify: `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`

- [ ] **Step 1: Escrever**

Em `CLAUDE.md`:

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -100,7 +100,7 @@ Adicionar uma chave de topo em `db` **quebra as escritas em produção** se as r
 
 ### App nativo (app-ios/)
 
-App em SwiftUI que vai substituir o Capacitor (spec `docs/specs/2026-10-06-app-nativo-design.md`, planos `docs/plans/2026-10-06-app-nativo-*`, mockup aprovado da etapa 1 em `~/Documents/custta-mockups/nativo/etapa1/final.html`, com a borda de rolagem do `final-v2.html` e as decisões de 10/10 no `final-v4.html`). O `app-ios/Custta.xcodeproj` é escrito à mão no formato do Xcode 16 (pastas sincronizadas): arquivo novo dentro de `Custta/`, `CusttaTests/` ou `CusttaUITests/` entra no alvo sozinho; não deixe o Xcode subir o `objectVersion` (77), porque a CI usa o Xcode 26 (`tests/app-ios.test.cjs` barra). As regras moram no pacote `app-ios/CusttaNucleo`, puro e conferido contra os vetores do site; o app tem a identidade em `Custta/Identidade/` (tokens de cor e de vidro, aurora, globo, título escrito à mão, superfícies de vidro e cápsula de abas, escritos uma vez e reusados), as telas, o `ModeloApp` e a camada fina do Firebase em `Custta/Dados/`. A cara é a do PWA: cores só por tokens (`scripts/cores-app-ios.mjs`; rode o script depois de mudar), ícones do `icons.js` (`scripts/icones-app-ios.mjs`), logo e globo iguais aos do site (as guardas comparam), toda superfície por `.superficie(_:em:)` com a dose de vidro da tela (`VidroTokens`), nunca vidro dentro de vidro, a mesma borda de rolagem em toda tela que rola (`.bordaDeRolagem(abas:)`), e animação própria só olhando o Reduzir movimento. O vidro do iOS não acompanha escala nem transformação 3D, e a auditoria de contraste do Xcode não lê vidro: as cores são auditadas com superfícies sólidas (e os pares de texto sobre sólido, em Node, pelo `PARES_SOLIDOS`), e a leitura sobre o vidro de verdade é medida pelo laudo de leitura (`LeituraNoVidroUITests`: dois prints do mesmo quadro, com e sem o texto, e 4,5:1 no pior ponto de cada palavra; portão no Mac e na CI, que mede a lista sob a cápsula em menos rolagens; o texto que o sistema desenha, como os botões dos alertas, é medido contra o fundo em volta das letras, e as exceções têm nome no teste). No escuro, uma camada do tom do fundo sob o vidro do conteúdo (`VidroTokens.escurecimento`) e o globo mais fundo dentro do app fecham a leitura; mexer na dose de vidro, na aurora, no globo ou na borda pede o laudo de novo. Nenhum build vai ao TestFlight com o laudo reprovando no Mac. Pacotes Swift: só firebase-ios-sdk e GoogleSignIn-iOS, em versão exata, com o `Package.resolved` versionado (para atualizar, botão "resolver de novo" do workflow `app-ios`); a Roboto Medium do botão do Google é a única fonte embutida, travada por SHA-256. Em Debug o app aceita `CUSTTA_SERVICOS=falsos` (telas e testes de tela; dados `vitrine` por padrão, as obras do mockup, e `exemplo` nos testes) e `CUSTTA_EMULADORES=1` (emuladores, com uma chave falsa, para um pedido que escape deles ser recusado pela produção); o Release não tem nenhum dos dois. Os emuladores rodam num FirebaseApp próprio (`Composicao.nomeDoAppDosEmuladores`), para a sessão deles nunca ocupar a vaga da produção no keychain. Nenhum teste monta a composição com rede, e cada agente roda os testes no seu simulador (`CUSTTA_SIMULADOR=<udid>`). A CI (`app-ios.yml`) roda o núcleo, o build Release sem assinatura e os testes no simulador com os serviços falsos; os testes contra os emuladores e a conferência cruzada rodam no Mac e são obrigatórios antes de cada envio. O app nunca grava antes de ver os dados da conta (`Sincronizador`, erro `nao-carregado`, com o alerta do texto do site); conta sem documento conta como vista quando o servidor já respondeu a ela neste aparelho (marca `custta-servidor-respondeu` no `UserDefaults`, apagada junto com o cache). Cartão de vidro que cresce (um mês da lista, o "A vencer") é um `CartaoDaLista`: com o vidro aplicado ao próprio conteúdo, o iOS 27 estica o quadro de acessibilidade da primeira linha até o cartão inteiro. Sair segue o `cloud.js`: para a escuta, grava a marca `custta-limpar-cache` (`UserDefaults`), sai e apaga o cache; a abertura seguinte termina uma limpeza interrompida. Se apagar o cache falhar, a entrada fica bloqueada e o alerta "Finalizar saída" pede para limpar de novo, como o `cacheBloqueado` do site. Os identificadores de acessibilidade são contrato com os testes, inclusive a conferência cruzada. O Xcode da CI é fixo (`DEVELOPER_DIR` do 26.6). O `PrivacyInfo.xcprivacy` acompanha a política de privacidade do site: dado novo coletado entra nos dois. Envio: workflow `app-ios-testflight`, no botão, versão 2.0 no mesmo cadastro (`br.com.custta.app`). Pendências de aparelho: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md` e `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`. Até a conferência do PR 3 da etapa 2, o app grava numa conta de teste criada por `scripts/conta-demo.mjs --importar` com as obras exportadas pelo site (o arquivo, com dados pessoais, nunca entra no repositório).
+App em SwiftUI que vai substituir o Capacitor (spec `docs/specs/2026-10-06-app-nativo-design.md`, planos `docs/plans/2026-10-06-app-nativo-*`, mockup aprovado da etapa 1 em `~/Documents/custta-mockups/nativo/etapa1/final.html`, com a borda de rolagem do `final-v2.html` e as decisões de 10/10 no `final-v4.html`). O `app-ios/Custta.xcodeproj` é escrito à mão no formato do Xcode 16 (pastas sincronizadas): arquivo novo dentro de `Custta/`, `CusttaTests/` ou `CusttaUITests/` entra no alvo sozinho; não deixe o Xcode subir o `objectVersion` (77), porque a CI usa o Xcode 26 (`tests/app-ios.test.cjs` barra). As regras moram no pacote `app-ios/CusttaNucleo`, puro e conferido contra os vetores do site; o app tem a identidade em `Custta/Identidade/` (tokens de cor e de vidro, aurora, globo, título escrito à mão, superfícies de vidro e cápsula de abas, escritos uma vez e reusados), as telas, o `ModeloApp` e a camada fina do Firebase em `Custta/Dados/`. A cara é a do PWA: cores só por tokens (`scripts/cores-app-ios.mjs`; rode o script depois de mudar), ícones do `icons.js` (`scripts/icones-app-ios.mjs`), logo e globo iguais aos do site (as guardas comparam), toda superfície por `.superficie(_:em:)` com a dose de vidro da tela (`VidroTokens`), nunca vidro dentro de vidro, a mesma borda de rolagem em toda tela que rola (`.bordaDeRolagem(abas:)`), e animação própria só olhando o Reduzir movimento. O vidro do iOS não acompanha escala nem transformação 3D, e a auditoria de contraste do Xcode não lê vidro: as cores são auditadas com superfícies sólidas (e os pares de texto sobre sólido, em Node, pelo `PARES_SOLIDOS`), e a leitura sobre o vidro de verdade é medida pelo laudo de leitura (`LeituraNoVidroUITests`: dois prints do mesmo quadro, com e sem o texto, e 4,5:1 no pior ponto de cada palavra; portão no Mac e na CI, que mede a lista sob a cápsula em menos rolagens; o texto que o sistema desenha, como os botões dos alertas, é medido contra o fundo em volta das letras, e as exceções têm nome no teste). No escuro, uma camada do tom do fundo sob o vidro do conteúdo (`VidroTokens.escurecimento`) e o globo mais fundo dentro do app fecham a leitura; mexer na dose de vidro, na aurora, no globo ou na borda pede o laudo de novo. Nenhum build vai ao TestFlight com o laudo reprovando no Mac. Pacotes Swift: só firebase-ios-sdk e GoogleSignIn-iOS, em versão exata, com o `Package.resolved` versionado (para atualizar, botão "resolver de novo" do workflow `app-ios`); a Roboto Medium do botão do Google é a única fonte embutida, travada por SHA-256. Em Debug o app aceita `CUSTTA_SERVICOS=falsos` (telas e testes de tela; dados `vitrine` por padrão, as obras do mockup, e `exemplo` nos testes) e `CUSTTA_EMULADORES=1` (emuladores, com uma chave falsa, para um pedido que escape deles ser recusado pela produção); o Release não tem nenhum dos dois. Os emuladores rodam num FirebaseApp próprio (`Composicao.nomeDoAppDosEmuladores`), para a sessão deles nunca ocupar a vaga da produção no keychain. Nenhum teste monta a composição com rede, e cada agente roda os testes no seu simulador (`CUSTTA_SIMULADOR=<udid>`). A CI (`app-ios.yml`) roda o núcleo, o build Release sem assinatura e os testes no simulador com os serviços falsos; os testes contra os emuladores e a conferência cruzada rodam no Mac e são obrigatórios antes de cada envio. O app nunca grava antes de ver os dados da conta (`Sincronizador`, erro `nao-carregado`, com o alerta do texto do site); conta sem documento conta como vista quando o servidor já respondeu a ela neste aparelho (marca `custta-servidor-respondeu` no `UserDefaults`, apagada junto com o cache). Telas que gravam: a mudança vem do núcleo (mutações de `Estado`, as mesmas regras do `dados.js`), o `ModeloApp.gravar` a aplica na hora (`Sincronizador.aplicar`; a tela anima na mesma transação) e a resposta do servidor segue pela pílula de sincronização. Folha com passos é `.folhaDoApp` em volta de um `NavigationStack` e `.passoDaFolha` em cada passo (voltar e borda do sistema; pergunta antes de descartar pelo ×, ao puxar e pelo escapar do VoiceOver); valor de dinheiro se digita sempre no `TecladoDeValor`. Cartão de vidro que cresce (um mês da lista, o "A vencer") é um `CartaoDaLista`: com o vidro aplicado ao próprio conteúdo, o iOS 27 estica o quadro de acessibilidade da primeira linha até o cartão inteiro. Sair segue o `cloud.js`: para a escuta, grava a marca `custta-limpar-cache` (`UserDefaults`), sai e apaga o cache; a abertura seguinte termina uma limpeza interrompida. Se apagar o cache falhar, a entrada fica bloqueada e o alerta "Finalizar saída" pede para limpar de novo, como o `cacheBloqueado` do site. Os identificadores de acessibilidade são contrato com os testes, inclusive a conferência cruzada. O Xcode da CI é fixo (`DEVELOPER_DIR` do 26.6). O `PrivacyInfo.xcprivacy` acompanha a política de privacidade do site: dado novo coletado entra nos dois. Envio: workflow `app-ios-testflight`, no botão, versão 2.0 no mesmo cadastro (`br.com.custta.app`). Pendências de aparelho: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md` e `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`. Até a conferência do PR 3 da etapa 2, o app grava numa conta de teste criada por `scripts/conta-demo.mjs --importar` com as obras exportadas pelo site (o arquivo, com dados pessoais, nunca entra no repositório).
 
 ## UI
```

Em `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`:

```diff
--- a/docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md
+++ b/docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md
@@ -32,3 +32,27 @@ O app grava de verdade a partir desta etapa, e cada gravação regrava o documen
 - [ ] Leitura sobre o fundo: com o fundo animado, em claro e escuro, nada fica difícil de ler (títulos, cabeçalhos dos meses, linhas).
 - [ ] Compare a lista de obras com o build anterior: os cartões ficaram um pouco mais escuros no tema escuro (o escurecimento sob o vidro subiu de 45% para 50%). Diga se incomoda.
 
+## PR 2: o gasto
+
+- [ ] Dentro de uma obra em construção, o + aparece ao lado da cápsula de abas; em Ajustes ele some. Na lista de obras e numa obra vendida ele ainda não aparece (chega no PR 3).
+- [ ] Toque no +: a folha abre com "Valor do gasto" e o teclado de maquininha (1 2 3 em cima). Digite 1, 3, 8, 0, 0, 0: o visor mostra R$ 1.380,00; "00" acrescenta dois zeros; apagar tira o último dígito. Com o visor em zero, "Avançar" fica apagado.
+- [ ] "Avançar": os detalhes, na ordem valor, tópico, pagamento, descrição e data; o tópico começa no do último gasto desta obra.
+- [ ] Tópico: a lista abre dentro da folha, com "Usados nesta obra" (três) no alto e o resto em "Todos", sem repetir; escolher volta aos detalhes. O voltar pela borda esquerda funciona dentro da folha.
+- [ ] Cartão: aparecem "Parcelas" (1x a 36x) e "Juros ao mês"; o resumo do site muda ao vivo ("10x de R$ … · Juros do cartão: R$ … · Total: R$ …"); a data vira "Primeiro vencimento", um mês à frente. Volte para Pix: a data volta a ser hoje.
+- [ ] Descrição: ao digitar "Cimen", as sugestões do site aparecem acima do teclado, com "mesmo tópico" ou "N× usado"; tocar numa preenche.
+- [ ] Data: o calendário do iPhone; data futura é aceita.
+- [ ] "Salvar": a folha desce, a lista rola até o gasto novo, que acende por uns 2 s com a etiqueta "novo", e o iPhone vibra. No site, o gasto aparece igual (valor, tópico, descrição, data, pagamento).
+- [ ] Lance no cartão em 10x: a lista abre o "A vencer" e mostra a 1ª parcela; no site, as 10 parcelas e os juros batem.
+- [ ] Lance de novo um gasto igual (mesma descrição, valor e data): aparece o aviso do site e o botão "Salvar mesmo assim" em âmbar; um segundo toque salva.
+- [ ] Feche pelo × depois de passar do valor: aparece "Você já preencheu este gasto." ("Descartar gasto" / "Continuar editando"). Puxar a folha para baixo pergunta igual. No valor ainda, fecha direto.
+- [ ] Toque num gasto: "Editar gasto" abre direto nos detalhes; o valor abre o mesmo teclado ("Pronto"); "Salvar" troca no site também.
+- [ ] Toque numa parcela: aparece o aviso "Parcela n/de de uma compra no cartão — a edição vale só pra esta parcela." e, com juros, as condições originais da compra.
+- [ ] Arraste um gasto para a esquerda: aparece o "Apagar" vermelho; tocar pergunta com o nome e o valor; "Apagar" tira a linha com animação, e o total do mês e os indicadores mudam juntos. Tocar fora ou rolar fecha a linha sem apagar.
+- [ ] Arraste uma parcela e toque em "Apagar": o alerta oferece "Apagar só esta parcela" e "Apagar a compra toda (N parcelas)"; a compra toda sai de uma vez, também no site.
+- [ ] "Apagar gasto" no fim da folha de edição: a folha desce e a linha sai.
+- [ ] O voltar pela borda esquerda continua voltando para a lista de obras, mesmo com as linhas que arrastam.
+- [ ] VoiceOver: o visor do valor lê o valor a cada tecla; dois toques numa linha de gasto abrem a edição; a linha tem a ação "Apagar" no rotor; depois de apagar, o foco vai para a linha vizinha e ouve-se "Gasto apagado".
+- [ ] Texto Maior no máximo: as teclas param de crescer num ponto; na folha, o rótulo vai em cima do valor e Pix/Cartão empilham.
+- [ ] iPhone 13 mini ou SE, se tiver: com o teclado aberto na descrição, as sugestões e o "Salvar" cabem.
+- [ ] Modo avião: lance um gasto; a pílula mostra "Sem conexão"; ao voltar a internet, o gasto chega ao site.
+- [ ] Na conta de sempre (sem `custta-teste` no e-mail), tente lançar: aparece "Este build ainda não grava na sua conta" e nada muda no site.
```


- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md \
  docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md
git commit -m "docs: o gasto no checklist do aparelho e as telas que gravam no CLAUDE.md" -m "O checklist do iPhone ganha a seção do gasto (lançar, cartão, sugestões, repetido, descartar, editar, apagar arrastando e pela folha, VoiceOver e letra máxima). O CLAUDE.md registra como as telas gravam e como uma folha com passos se monta."
```

**Ponto de controle do PR 2:** CI verde (núcleo, `app` e `laudo`); `npm run test:app-ios:emuladores` e `npm run test:app-ios:cruzado` verdes no Mac; depois do merge, o build no TestFlight com o OK do Giovani, que marca a seção do PR 2 no iPhone, na conta de teste, conferindo cada gasto também no site.

---

## PR 3 (app): a obra, as fases, a venda e os estados

A parte 3 do mockup: as ações da fase na tela da obra, a folha da venda em dois passos, "Nova obra" pelo + da lista, "Editar obra" pelo lápis da barra (com "Apagar obra"), o gasto lançado de dentro de uma obra vendida (a linha "Obra"), os estados (lista vazia, carregando, limite de 300, sem conexão, "Não salvou" uma vez por erro) e a leitura, a auditoria e a conferência cruzada de tudo isso. O código saiu de um protótipo feito em paralelo sobre o fim do PR 2 e mesclado depois: as diferenças que a mescla e a revisão corrigiram estão em "O que a revisão independente mudou".

### Task 27: A obra no documento como o site grava, com criar, editar e apagar no núcleo

A obra nova vai para o fim do documento exatamente como o `obraNova` do `dados.js` a monta: sem `afazeres` e sem `venda` (a leitura normalizada acrescenta os dois; o app guarda se a árvore os trazia). Editar troca só nome, início, valor estimado e área pela regra do `obraEditada`; apagar tira a obra. A 301ª obra não entra: as rules recusariam toda gravação seguinte.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Modelo.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift`
- Test (criar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraEFasesTests.swift`

**Interfaces:**
- Consumes: Tarefas 5 e 7 (`obraNova`, `obraEditada`, `CamposDaObra`, `limiteDeObras`); `Estado`, `Obra` (etapa 1).
- Produces: `Obra.afazeresNaArvore`; `Estado.criandoObra(_ arvore: [String: ValorJSON]) -> Estado?`, `editandoObra(_ obraId: String, _ campos: CamposDaObra) -> Estado?`, `apagandoObra(_ obraId: String) -> Estado?`.

- [ ] **Step 1: Escrever os testes**

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraEFasesTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/* O que as folhas da obra e da venda e as ações da fase fazem no estado (app.js formNovaObra, formEditarObra, formVenda,
   mudarFase e o desfazer da venda): a obra nova no fim e na forma que o site grava; editar só os campos do formulário;
   apagar; a fase só entre construção e pronta; vender só a pronta; desfazer apaga a chave `venda`. Obra que sumiu, ou
   que outro aparelho mudou de fase com a tela aberta, devolve nil: nada é gravado. */
struct MutacoesDaObraTests {
    func estado() -> Estado {
        Estado.de(.objeto(["obras": .lista([
            .objeto(["id": .texto("o1"), "nome": .texto("Casa"), "dataInicio": .texto("2026-01-01"), "fase": .texto("construcao"),
                     "areaM2": .numero(120), "valorEstimadoVenda": .numero(900_000), "campoDoSite": .numero(7),
                     "orcamento": .objeto(["modo": .texto("total"), "total": .numero(500_000)]),
                     "gastos": .lista([.objeto(["id": .texto("a"), "valor": .numero(10), "topico": .texto("pintura"),
                                                "descricao": .texto("Tinta"), "data": .texto("2026-02-01"), "pagamento": .texto("pix")])])]),
            .objeto(["id": .texto("o2"), "nome": .texto("Sobrado"), "dataInicio": .texto("2025-06-01"), "fase": .texto("pronta"),
                     "gastos": .lista([])]),
            .objeto(["id": .texto("o3"), "nome": .texto("Vendida"), "dataInicio": .texto("2024-01-01"), "fase": .texto("vendida"),
                     "venda": .objeto(["valor": .numero(800_000), "data": .texto("2025-02-10"), "notaDoSite": .texto("fica")]),
                     "gastos": .lista([])]),
        ])]))
    }

    /// A obra `i` do documento que vai para o banco.
    func gravada(_ e: Estado, _ i: Int) -> [String: ValorJSON]? {
        guard case .objeto(let raiz) = e.arvore, case .lista(let obras) = raiz["obras"], i < obras.count else { return nil }
        return obras[i].comoObjeto
    }

    @Test func obraNovaNoFimComoOSiteGrava() throws {
        let nova = obraNova(CamposDaObra(nome: "Casa Granja Viana 2", dataInicio: "2026-10-01", valorEstimadoVenda: 1_600_000, areaM2: 280),
                            id: "n1", hoje: "2026-10-13")
        let e = try #require(estado().criandoObra(nova))
        #expect(e.obras.map(\.id) == ["o1", "o2", "o3", "n1"], "o push do site: no fim do documento")
        let documento = try #require(gravada(e, 3))
        #expect(documento == nova, "no documento como o site grava")
        #expect(documento["afazeres"] == nil && documento["venda"] == nil, "sem venda e sem afazeres (a leitura acrescenta)")
        let antiga = try #require(gravada(e, 0))
        #expect(antiga["afazeres"] == .lista([]) && antiga["venda"] == .nulo && antiga["campoDoSite"] == .numero(7),
                "as que já estavam continuam como a leitura normalizada deixou")
    }

    @Test func obraNovaNaoPassaDoTetoDasRules() {
        var cheio = Estado.vazio
        cheio.obras = (0..<limiteDeObras).map { Obra(arvore: ["id": .texto("x\($0)"), "nome": .texto("O"), "dataInicio": .texto("2026-01-01")]) }
        let nova = obraNova(CamposDaObra(nome: "A mais", dataInicio: "", areaM2: 1), id: "a", hoje: "2026-10-13")
        #expect(cheio.criandoObra(nova) == nil, "a 301ª faria toda gravação seguinte ser recusada pelas rules")
        cheio.obras.removeLast()
        #expect(cheio.criandoObra(nova)?.obras.count == limiteDeObras, "a 300ª ainda entra")
    }

    @Test func editarSoOsCamposDoFormulario() throws {
        let e = try #require(estado().editandoObra("o1", CamposDaObra(nome: "Casa Nova", dataInicio: "", valorEstimadoVenda: 0, areaM2: 3.125)))
        let o = e.obras[0]
        #expect(o.nome == "Casa Nova" && o.dataInicio == "2026-01-01", "início vazio fica o antigo")
        #expect(o.campos["valorEstimadoVenda"] == .nulo, "estimado zero vira null")
        #expect(o.areaM2 == 3.125)
        #expect(o.campos["campoDoSite"] == .numero(7) && o.orcamento != nil && o.gastos.count == 1 && o.fase == .construcao, "o resto fica")
        let semArea = try #require(estado().editandoObra("o1", CamposDaObra(nome: "Casa", dataInicio: "2025-12-01", valorEstimadoVenda: 1, areaM2: 0)))
        #expect(semArea.obras[0].campos["areaM2"] == .nulo && semArea.obras[0].dataInicio == "2025-12-01", "área opcional na edição")
        #expect(estado().editandoObra("sumiu", CamposDaObra(nome: "X", dataInicio: "")) == nil)
    }

    @Test func apagarObra() throws {
        let e = try #require(estado().apagandoObra("o2"))
        #expect(e.obras.map(\.id) == ["o1", "o3"])
        #expect(estado().apagandoObra("sumiu") == nil)
    }
}
```


- [ ] **Step 2: Ver falhar**

Run: `TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter MutacoesDaObraTests 2>&1 | grep error: | head -3`
Expected: não compila: `value of type 'Estado' has no member 'criandoObra'`.

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Modelo.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Modelo.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Modelo.swift
@@ -96,10 +96,14 @@ public struct Obra: Equatable, Sendable {
     public var campos: [String: ValorJSON]
     public var gastos: [Gasto]
     public var afazeres: [Afazer]
+    /// A árvore trazia `afazeres`. A obra nova do site não traz (a leitura normalizada acrescenta): sem afazer, ela volta
+    /// ao documento sem a chave, como o site grava.
+    var afazeresNaArvore: Bool
 
     public init(arvore: [String: ValorJSON]) {
         var c = arvore
         gastos = (c.removeValue(forKey: "gastos")?.comoLista ?? []).compactMap { $0.comoObjeto.map(Gasto.init(campos:)) }
+        afazeresNaArvore = c["afazeres"] != nil
         afazeres = (c.removeValue(forKey: "afazeres")?.comoLista ?? []).compactMap { $0.comoObjeto.map(Afazer.init(campos:)) }
         campos = c
     }
@@ -108,7 +112,7 @@ public struct Obra: Equatable, Sendable {
     public var arvore: [String: ValorJSON] {
         var c = campos
         c["gastos"] = .lista(gastos.map { .objeto($0.campos) })
-        c["afazeres"] = .lista(afazeres.map { .objeto($0.campos) })
+        if afazeresNaArvore || !afazeres.isEmpty { c["afazeres"] = .lista(afazeres.map { .objeto($0.campos) }) }
         return c
     }
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift
@@ -41,6 +41,33 @@ public extension Estado {
     }
 }
 
+/* As da obra (app.js formNovaObra, formEditarObra e o apagar). */
+public extension Estado {
+    /// A obra nova (de `obraNova`) no fim do documento, como o `push` do site; nil com o teto de obras cheio (a obra a mais
+    /// faria toda gravação seguinte ser recusada pelas rules até apagar uma).
+    func criandoObra(_ arvore: [String: ValorJSON]) -> Estado? {
+        guard obras.count < limiteDeObras else { return nil }
+        var e = self
+        e.obras.append(Obra(arvore: arvore))
+        return e
+    }
+
+    /// Nome, início, valor estimado e área pela regra do `obraEditada`; o resto da obra fica.
+    func editandoObra(_ obraId: String, _ campos: CamposDaObra) -> Estado? {
+        guard let i = indiceDaObra(obraId) else { return nil }
+        var e = self
+        e.obras[i].campos = obraEditada(obras[i].campos, campos)
+        return e
+    }
+
+    func apagandoObra(_ obraId: String) -> Estado? {
+        guard let i = indiceDaObra(obraId) else { return nil }
+        var e = self
+        e.obras.remove(at: i)
+        return e
+    }
+}
+
 /// As parcelas que restam da compra do gasto (o N do "Apagar a compra toda (N parcelas)", contado como o site: as irmãs
 /// que ainda existem, não o `parcela.de`).
 public func parcelasDaCompra(_ gasto: Gasto, naObra obra: Obra) -> Int {
```


- [ ] **Step 4: Ver passar**

Run: o núcleo inteiro.
Expected: `✔ Test run with 168 tests … passed`; o `obraNovaNoFimComoOSiteGrava` prova o documento sem `afazeres` e sem `venda` na obra nova e com `afazeres: []` e `venda: null` nas que a leitura normalizou.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Modelo.swift \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraEFasesTests.swift
git commit -m "feat: a obra no documento como o site grava, com criar, editar e apagar no núcleo" -m "A obra nova entra no fim do documento como o obraNova do dados.js a monta, sem afazeres e sem venda; o app passa a lembrar se a árvore trazia afazeres, para não pôr o que a leitura acrescenta. Editar troca só os campos do formulário e apagar tira a obra; a 301ª não entra, porque as rules recusariam toda gravação seguinte."
```

### Task 28: Fases e venda no núcleo, com os textos da parte 3

A fase só anda pelos caminhos que a tela oferece (construção ↔ pronta; vender só a pronta; desfazer só a vendida): quem a mudou em outro aparelho com esta tela aberta não é atropelado. "Desfazer venda" tira a chave `venda` (o `delete` do site, não `null`). Os textos da parte 3 (ações da fase com os rótulos e ícones do site, as perguntas de apagar obra e desfazer venda, as notas das folhas, a lista vazia, o "Não salvou" partido em título e mensagem, a área no campo com vírgula e a ordem das obras abertas) ficam no núcleo, com teste.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift`
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/ObraEFases.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraEFasesTests.swift`

**Interfaces:**
- Consumes: Tarefa 27; `obrasOrdenadas` (etapa 1); `AvisoSinc` (`Sincronizador`).
- Produces: `Estado.mudandoFase(_:para:)`, `registrandoVenda(_:valor:data:)`, `desfazendoVenda(_:)`; `AcaoDaFase` (`.marcarPronta`, `.voltarConstrucao`, `.registrarVenda`, `.desfazerVenda`, com `rotulo`, `icone` e `principal`) e `acoesDaFase(_:)`; `textoDeApagarObra(nome:lancamentos:)`, `textoDeDesfazerVenda`, `notaDaDataDaVenda(dataInicio:)`, `notaDaObraVendida(_:)`, `listaDeObrasVazia`, `alertaDeNaoSalvou(codigo:)`, `areaParaCampo(_:)`, `obrasAbertas(_:)`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraEFasesTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraEFasesTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraEFasesTests.swift
@@ -66,4 +66,87 @@ struct MutacoesDaObraTests {
         #expect(e.obras.map(\.id) == ["o1", "o3"])
         #expect(estado().apagandoObra("sumiu") == nil)
     }
+
+    @Test func faseSoEntreConstrucaoEPronta() throws {
+        let pronta = try #require(estado().mudandoFase("o1", para: .pronta))
+        #expect(pronta.obras[0].fase == .pronta && pronta.obras[0].campos["campoDoSite"] == .numero(7))
+        #expect(try #require(pronta.mudandoFase("o1", para: .construcao)).obras[0].fase == .construcao)
+        #expect(estado().mudandoFase("o1", para: .vendida) == nil, "vender é pela folha da venda")
+        #expect(estado().mudandoFase("o3", para: .pronta) == nil, "da vendida só se sai desfazendo a venda")
+        #expect(estado().mudandoFase("sumiu", para: .pronta) == nil)
+    }
+
+    @Test func registrarVendaSoDaPronta() throws {
+        let e = try #require(estado().registrandoVenda("o2", valor: 1_380_000, data: "2026-10-12"))
+        #expect(e.obras[1].fase == .vendida)
+        #expect(e.obras[1].campos["venda"] == .objeto(["valor": .numero(1_380_000), "data": .texto("2026-10-12")]), "venda {valor, data}, como o site")
+        #expect(estado().registrandoVenda("o1", valor: 1, data: "2026-10-12") == nil, "a construção não se vende (a tela não oferece)")
+        #expect(estado().registrandoVenda("o3", valor: 1, data: "2026-10-12") == nil, "outro aparelho já vendeu")
+        #expect(estado().registrandoVenda("sumiu", valor: 1, data: "2026-10-12") == nil)
+    }
+
+    @Test func desfazerVendaApagaAChave() throws {
+        let e = try #require(estado().desfazendoVenda("o3"))
+        #expect(e.obras[2].fase == .pronta)
+        #expect(e.obras[2].campos["venda"] == nil && gravada(e, 2)?["venda"] == nil, "o delete do site: a chave sai, não vira null")
+        #expect(estado().desfazendoVenda("o2") == nil, "só a vendida")
+        #expect(estado().desfazendoVenda("sumiu") == nil)
+    }
+}
+
+struct TextosDaObraTests {
+    @Test func acoesDaFaseComOsTextosDoSite() {
+        #expect(acoesDaFase(.construcao) == [.marcarPronta])
+        #expect(acoesDaFase(.pronta) == [.registrarVenda, .voltarConstrucao])
+        #expect(acoesDaFase(.vendida) == [.desfazerVenda])
+        #expect(AcaoDaFase.allCases.map(\.rotulo) == ["Marcar como pronta", "Registrar venda", "Voltar pra construção", "Desfazer venda"])
+        #expect(AcaoDaFase.allCases.map(\.icone) == ["casa", "acordo", "voltar", "voltar"])
+        #expect(AcaoDaFase.allCases.map(\.principal) == [true, true, false, false], "o próximo passo sólido; voltar em vidro")
+    }
+
+    @Test func perguntasDeApagarObraEDesfazerVenda() {
+        let pergunta = textoDeApagarObra(nome: "Casa Alphaville", lancamentos: 46)
+        #expect(pergunta.titulo == "Apagar “Casa Alphaville”?")
+        #expect(pergunta.mensagem == "Os 46 lançamentos dela serão perdidos. Não dá para desfazer.")
+        #expect(textoDeApagarObra(nome: "X", lancamentos: 1).mensagem == "1 lançamento dela será perdido. Não dá para desfazer.")
+        #expect(textoDeApagarObra(nome: "X", lancamentos: 0).mensagem == "Não dá para desfazer.", "sem gasto, o site não fala em lançamentos")
+        #expect(textoDeDesfazerVenda.titulo == "Desfazer a venda?")
+        #expect(textoDeDesfazerVenda.mensagem == "A obra volta pra “Pronta”.")
+        #expect(textoDeDesfazerVenda.botao == "Desfazer venda")
+    }
+
+    @Test func notasDasFolhasEListaVazia() {
+        #expect(notaDaDataDaVenda(dataInicio: "2024-11-01") == "Entre o início da obra (01/11/24) e hoje. A correção pelo banco para nessa data.")
+        #expect(notaDaObraVendida("Casa Alphaville") == "Casa Alphaville está vendida; o gasto vai para uma obra aberta.")
+        #expect(listaDeObrasVazia.titulo == "Nenhuma obra ainda.")
+        #expect(listaDeObrasVazia.texto == "Toque no + para criar a primeira obra.", "o \"pra\" do site vira \"para\" nas telas vazias")
+    }
+
+    @Test func alertaDeNaoSalvouComOTextoDoSite() {
+        let comum = alertaDeNaoSalvou(codigo: "permission-denied")
+        #expect(comum.titulo == "Não salvou na nuvem")
+        #expect(comum.mensagem == "Confira sua conexão e conta; toque no aviso para tentar novamente.")
+        let limite = alertaDeNaoSalvou(codigo: "limite")
+        #expect(limite.titulo == "Não salvou: limite de dados atingido")
+        for codigo in ["permission-denied", "unauthenticated", "limite"] {
+            let a = alertaDeNaoSalvou(codigo: codigo)
+            #expect("\(a.titulo). \(a.mensagem)" == AvisoSinc.naoSalvou(codigo: codigo, terminal: true).mensagem, "o texto do site, em título e mensagem")
+        }
+    }
+
+    @Test func areaNoCampoSemOErroDoSite() {
+        // O site mostra a área crua ("3.125") e o parseNum lê o ponto como milhar (3125); com a vírgula, volta igual.
+        for area in [3.125, 280, 1234.5, 0.75, 12_345.678] { #expect(lerNumero(areaParaCampo(area)) == area, "\(area)") }
+        #expect(areaParaCampo(3.125) == "3,125" && areaParaCampo(280) == "280" && areaParaCampo(nil) == "")
+    }
+
+    @Test func obrasAbertasNaOrdemDaLista() {
+        let e = Estado.de(.objeto(["obras": .lista([
+            .objeto(["id": .texto("a"), "nome": .texto("A"), "dataInicio": .texto("2025-01-01"), "fase": .texto("construcao")]),
+            .objeto(["id": .texto("b"), "nome": .texto("B"), "dataInicio": .texto("2026-03-01"), "fase": .texto("vendida"),
+                     "venda": .objeto(["valor": .numero(1), "data": .texto("2026-04-01")])]),
+            .objeto(["id": .texto("c"), "nome": .texto("C"), "dataInicio": .texto("2026-02-01"), "fase": .texto("pronta")]),
+        ])]))
+        #expect(obrasAbertas(e.obras).map(\.id) == ["c", "a"], "sem as vendidas, a que começou mais recente primeiro")
+    }
 }
```


- [ ] **Step 2: Ver falhar**

Run: o filtro `MutacoesDaObraTests` e `TextosDaObraTests` do núcleo.
Expected: não compila: `value of type 'Estado' has no member 'mudandoFase'`; `cannot find 'acoesDaFase' in scope`.

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift
@@ -41,7 +41,8 @@ public extension Estado {
     }
 }
 
-/* As da obra (app.js formNovaObra, formEditarObra e o apagar). */
+/* As da obra e das fases (app.js formNovaObra, formEditarObra, formVenda, mudarFase e o desfazer da venda). A fase só
+   anda pelos caminhos que a tela oferece: quem a mudou em outro aparelho com esta tela aberta não é atropelado (nil). */
 public extension Estado {
     /// A obra nova (de `obraNova`) no fim do documento, como o `push` do site; nil com o teto de obras cheio (a obra a mais
     /// faria toda gravação seguinte ser recusada pelas rules até apagar uma).
@@ -66,6 +67,33 @@ public extension Estado {
         e.obras.remove(at: i)
         return e
     }
+
+    /// O `mudarFase` do site, só entre construção e pronta: vender é pela folha da venda, e da vendida só se sai desfazendo.
+    func mudandoFase(_ obraId: String, para fase: Fase) -> Estado? {
+        guard let i = indiceDaObra(obraId), fase != .vendida, obras[i].fase != .vendida else { return nil }
+        var e = self
+        e.obras[i].fase = fase
+        return e
+    }
+
+    /// "Confirmar venda": `venda {valor, data}` e a fase vendida, só a partir da pronta. Valor e data já conferidos
+    /// (`conferirVenda`).
+    func registrandoVenda(_ obraId: String, valor: Double, data: String) -> Estado? {
+        guard let i = indiceDaObra(obraId), obras[i].fase == .pronta else { return nil }
+        var e = self
+        e.obras[i].venda = Venda(valor: valor, data: data)
+        e.obras[i].fase = .vendida
+        return e
+    }
+
+    /// "Desfazer venda": a chave `venda` sai (o `delete` do site, não `null`) e a obra volta para pronta.
+    func desfazendoVenda(_ obraId: String) -> Estado? {
+        guard let i = indiceDaObra(obraId), obras[i].fase == .vendida else { return nil }
+        var e = self
+        e.obras[i].campos["venda"] = nil
+        e.obras[i].fase = .pronta
+        return e
+    }
 }
 
 /// As parcelas que restam da compra do gasto (o N do "Apagar a compra toda (N parcelas)", contado como o site: as irmãs
```

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/ObraEFases.swift`:

```swift
import Foundation

/* Regras e textos das telas da obra na etapa 2, parte 3 (mockup aprovado em 13/10): as ações da fase com os textos do
   site (renderObra, app.js:428-433), as perguntas de apagar a obra e de desfazer a venda, as notas das folhas, a lista
   vazia, o alerta de "Não salvou" e o campo da área. Os textos vêm do site; onde o mockup acrescenta (o "Não dá para
   desfazer", o plural de "lançamentos"), fica o do mockup, como no apagar gasto. */

/// Uma ação da fase, logo abaixo dos indicadores.
public enum AcaoDaFase: String, Sendable, CaseIterable {
    case marcarPronta, registrarVenda, voltarConstrucao, desfazerVenda

    public var rotulo: String {
        switch self {
        case .marcarPronta: return "Marcar como pronta"
        case .registrarVenda: return "Registrar venda"
        case .voltarConstrucao: return "Voltar pra construção"
        case .desfazerVenda: return "Desfazer venda"
        }
    }

    /// O ícone do site (icons.js).
    public var icone: String {
        switch self {
        case .marcarPronta: return "casa"
        case .registrarVenda: return "acordo"
        case .voltarConstrucao, .desfazerVenda: return "voltar"
        }
    }

    /// O próximo passo vai sólido, na marca (o `primary` do site); voltar, em vidro (o `ghost`).
    public var principal: Bool { self == .marcarPronta || self == .registrarVenda }
}

/// As ações de cada fase, na ordem do site: construção → pronta; pronta → venda ou de volta; vendida → desfazer.
public func acoesDaFase(_ fase: Fase) -> [AcaoDaFase] {
    switch fase {
    case .construcao: return [.marcarPronta]
    case .pronta: return [.registrarVenda, .voltarConstrucao]
    case .vendida: return [.desfazerVenda]
    }
}

/// O alerta de apagar a obra: o nome no título, com as aspas do site, e quantos lançamentos se perdem.
public func textoDeApagarObra(nome: String, lancamentos n: Int) -> (titulo: String, mensagem: String) {
    let perdidos = n == 0 ? "" : n == 1 ? "1 lançamento dela será perdido. " : "Os \(n) lançamentos dela serão perdidos. "
    return ("Apagar “\(nome)”?", perdidos + "Não dá para desfazer.")
}

/// A pergunta do "Desfazer venda" (app.js:513), em título e mensagem.
public let textoDeDesfazerVenda = (titulo: "Desfazer a venda?", mensagem: "A obra volta pra “Pronta”.", botao: "Desfazer venda")

/// A nota embaixo da data da venda.
public func notaDaDataDaVenda(dataInicio: String) -> String {
    "Entre o início da obra (\(dataCurta(dataInicio))) e hoje. A correção pelo banco para nessa data."
}

/// A nota da linha "Obra" no gasto lançado de dentro de uma obra vendida.
public func notaDaObraVendida(_ nome: String) -> String { "\(nome) está vendida; o gasto vai para uma obra aberta." }

/// A lista de obras vazia, com os dados já vistos (app.js:258, com "para").
public let listaDeObrasVazia = (titulo: "Nenhuma obra ainda.", texto: "Toque no + para criar a primeira obra.")

/// O alerta de quando a gravação não passa sozinha (o erro terminal): o texto do site (`AvisoSinc.naoSalvou`), partido
/// em título e mensagem no primeiro ponto.
public func alertaDeNaoSalvou(codigo: String) -> (titulo: String, mensagem: String) {
    let texto = AvisoSinc.naoSalvou(codigo: codigo, terminal: true).mensagem
    guard let ponto = texto.range(of: ". ") else { return (texto, "") }
    return (String(texto[..<ponto.lowerBound]), String(texto[ponto.upperBound...]))
}

/// A área no campo da edição, com vírgula ("3,125"): o site mostra o número cru ("3.125"), que o `parseNum` lê como
/// milhar (3125). Vazio sem área.
public func areaParaCampo(_ area: Double?) -> String {
    guard let area else { return "" }
    return numeroJS(area).replacingOccurrences(of: ".", with: ",")
}

/// As obras que recebem gasto novo (não vendidas), na ordem da lista de obras.
public func obrasAbertas(_ obras: [Obra]) -> [Obra] { obrasOrdenadas(obras).filter { $0.fase != .vendida } }
```


- [ ] **Step 4: Ver passar**

Run: o núcleo inteiro.
Expected: `✔ Test run with 177 tests … passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Mutacoes.swift \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/ObraEFases.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ObraEFasesTests.swift
git commit -m "feat: fases e venda no núcleo, com os textos da parte 3" -m "Mudar a fase, registrar a venda e desfazê-la só pelos caminhos que a tela oferece, para uma tela velha não atropelar o que outro aparelho mudou; desfazer tira a chave venda, como o delete do site. Os textos das ações da fase, das perguntas, das notas das folhas e dos estados moram no núcleo, com teste."
```

### Task 29: Ações da fase na tela da obra, com a vibração leve

Abaixo dos indicadores, o próximo passo numa pílula sólida da marca ("Marcar como pronta", "Registrar venda") e o voltar numa pílula de vidro ("Voltar pra construção", "Desfazer venda"), como o mockup. Construção ↔ pronta muda na hora, sem pergunta, com a etiqueta e as ações trocando na mola e uma vibração leve; "Desfazer venda" pergunta com o texto do site. "Registrar venda" abre a folha da venda, que chega na Tarefa 31.

**Files:**
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Modify: `app-ios/Custta/Telas/PecasDaObra.swift`
- Test (criar): `app-ios/CusttaUITests/FasesUITests.swift`

**Interfaces:**
- Consumes: Tarefa 28; `ModeloApp.gravar` (Tarefa 20); `.superficie` e os ícones do site (Tarefa 14).
- Produces: `AcoesDaFaseView(fase:agir:)` e `PilulaDaAcao(principal:)`, com os identificadores `acao-marcarPronta`, `acao-voltarConstrucao`, `acao-registrarVenda` e `acao-desfazerVenda`; na `ObraView`, `agir(_:obra:)` e `mudar(_:_:)`.

- [ ] **Step 1: Escrever os testes**

Criar `app-ios/CusttaUITests/FasesUITests.swift`:

```swift
import XCTest

/* Fases e venda (etapa 2, parte 3), com as obras da vitrine: a Casa Alphaville em construção (v1), o Sobrado Granja Viana
   pronto (v2) e a Casa Tamboré 4 vendida (v3). Mudar entre construção e pronta não pergunta; a venda vai em dois passos
   (teclado de valor, depois a data) e grava a fase vendida; desfazer pergunta com o texto do site e volta para pronta. */
@MainActor
final class FasesUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testMarcarComoProntaEVoltarPraConstrucaoSemPergunta() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
        let pronta = app.buttons["acao-marcarPronta"]
        XCTAssertTrue(pronta.waitForExistence(timeout: 10))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
        XCTAssertFalse(app.buttons["acao-registrarVenda"].exists, "a construção não se vende")
        app.rolarAte(pronta)
        pronta.tap()
        let voltar = app.buttons["acao-voltarConstrucao"]
        XCTAssertTrue(voltar.waitForExistence(timeout: 5), "pronta: voltar e registrar venda")
        XCTAssertTrue(app.buttons["acao-registrarVenda"].exists)
        XCTAssertFalse(app.alerts.firstMatch.exists, "mudar a fase não pergunta (o mudarFase do site)")
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Pronta · à venda"))
        app.rolarAte(voltar)
        voltar.tap()
        XCTAssertTrue(app.buttons["acao-marcarPronta"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
    }

    func testDesfazerVendaPerguntaComOTextoDoSite() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
        let desfazer = app.buttons["acao-desfazerVenda"]
        XCTAssertTrue(desfazer.waitForExistence(timeout: 10))
        app.rolarAte(desfazer)
        desfazer.tap()
        let alerta = app.alerts["Desfazer a venda?"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["A obra volta pra “Pronta”."].exists)
        alerta.buttons["Cancelar"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Vendida"), "cancelar não muda nada")
        app.rolarAte(desfazer)
        desfazer.tap()
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Desfazer venda"].tap()
        XCTAssertTrue(app.buttons["acao-registrarVenda"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Pronta · à venda"))
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("Venda estimada"), "a venda saiu; volta a estimativa")
    }
}
```


- [ ] **Step 2: Ver falhar**

Run: `xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | tail -3`
Expected: compila; `-only-testing:CusttaUITests/FasesUITests` falha em `testMarcarComoProntaEVoltarPraConstrucaoSemPergunta` (`acao-marcarPronta` não existe).

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -1,16 +1,17 @@
 import SwiftUI
 import CusttaNucleo
 
-/* A tela da obra (mockup aprovado da etapa 2, parte 1): o nome no título grande, a pílula da fase e do tempo, os
-   indicadores na opção A, a pílula "Lançamentos" e a lista de gastos por mês, com o "A vencer" fechado no alto. Entra
-   pelo push do NavigationStack de Obras e volta pelo círculo e pela borda (sistema). A obra que some (apagada em outro
-   aparelho) fecha a tela, como o site volta ao Início. */
+/* A tela da obra (mockup aprovado da etapa 2, partes 1 e 3): o nome no título grande, a pílula da fase e do tempo, os
+   indicadores na opção A, as ações da fase, a pílula "Lançamentos" e a lista de gastos por mês, com o "A vencer" fechado
+   no alto; o lápis na barra abre "Editar obra". Entra pelo push do NavigationStack de Obras e volta pelo círculo e pela
+   borda (sistema). A obra que some (apagada em outro aparelho) fecha a tela, como o site volta ao Início. */
 struct ObraView: View {
     let id: String
     @Binding var caminho: [RotaDeObras]
     @Environment(ModeloApp.self) private var modelo
     @Environment(Folhas.self) private var folhas
     @Environment(\.opcoes) private var opcoes
+    @Environment(\.paleta) private var paleta
     @State private var aVencerAberto = false
     /// A linha arrastada que mostra "Apagar" (uma por vez).
     @State private var linhaAberta: String?
@@ -19,6 +20,10 @@ struct ObraView: View {
     @State private var perguntando = false
     @State private var naoCarregado = false
     @State private var contaReal = false
+    /// "Desfazer venda" tocado: a pergunta do site.
+    @State private var desfazendo = false
+    /// Muda a cada ação da fase feita aqui: a vibração leve do mockup (a de outro aparelho não vibra).
+    @State private var mudouAFase = 0
     /// Os gastos que acabaram de ser salvos (acesos por 2 s) e se levam a etiqueta "novo".
     @State private var acesos: Set<String> = []
     @State private var novos = false
@@ -65,6 +70,8 @@ struct ObraView: View {
                     TituloDaObra(nome: obra.nome)
                     PilulaDaFase(obra: obra, hoje: hoje)
                     IndicadoresDaObraView(indicadores: indicadoresDaObra(obra, taxa: taxa, hoje: hoje))
+                    AcoesDaFaseView(fase: obra.fase) { agir($0, obra: obra) }
+                        .padding(.top, 2)
                         .padding(.bottom, 14)
                     PilulaDeLancamentos(quantidade: obra.gastos.count)
                         .accessibilityFocused($foco, equals: .lancamentos)
@@ -95,12 +102,22 @@ struct ObraView: View {
         .onChange(of: folhas.pedidoDeApagar) { _, p in if let p, p.obraId == obra.id { apagar(p, obra: obra, lista: lista) } }
         .onDisappear { linhaAberta = nil }
         .sensoryFeedback(.success, trigger: folhas.destaque)
+        .sensoryFeedback(.impact(weight: .light), trigger: mudouAFase)
         .modifier(PerguntaDeApagar(apresentada: $perguntando, obraId: obra.id, gasto: alvoDoApagar) { pedido in
             apagar(pedido, obra: obra, lista: lista)
         })
         .onChange(of: perguntando) { _, agora in if !agora { fecharLinha() } }
         .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) { Button("OK", role: .cancel) {} }
         .alert(ContaDeTeste.titulo, isPresented: $contaReal) { Button("OK", role: .cancel) {} } message: { Text(ContaDeTeste.mensagem) }
+        .background {
+            Color.clear
+                .alert(textoDeDesfazerVenda.titulo, isPresented: $desfazendo) {
+                    Button("Cancelar", role: .cancel) {}
+                    Button(textoDeDesfazerVenda.botao, role: .destructive) { mudar(obra) { $0.desfazendoVenda(obra.id) } }
+                } message: { Text(textoDeDesfazerVenda.mensagem) }
+                .tint(paleta.cor(.texto))
+        }
+        .pausaOFundo(enquanto: desfazendo)
         // O título pequeno entra na barra quando o grande sai de baixo dela (como o título grande do sistema).
         .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 44 } action: { _, saiu in
             withAnimation(.easeOut(duration: 0.2)) { barra.tituloVisivel = saiu }
@@ -128,6 +145,23 @@ struct ObraView: View {
 }
 
 extension ObraView {
+    /// Uma ação da fase: mudar entre construção e pronta na hora, sem pergunta (o mudarFase do site), com a etiqueta e as
+    /// ações trocando na mola; a venda abre a folha; desfazer pergunta.
+    private func agir(_ acao: AcaoDaFase, obra: Obra) {
+        switch acao {
+        case .marcarPronta: mudar(obra) { $0.mudandoFase(obra.id, para: .pronta) }
+        case .voltarConstrucao: mudar(obra) { $0.mudandoFase(obra.id, para: .construcao) }
+        case .registrarVenda: break    // a folha da venda chega na Tarefa 31
+        case .desfazerVenda: desfazendo = true
+        }
+    }
+
+    private func mudar(_ obra: Obra, _ mudanca: (Estado) -> Estado?) {
+        let resultado = withAnimation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.35, bounce: 0)) { modelo.gravar(mudanca) }
+        if resultado == .naoCarregado { naoCarregado = true }
+        if resultado == .gravou { mudouAFase += 1 }
+    }
+
     private func fecharLinha() {
         guard linhaAberta != nil else { return }
         if opcoes.reduzirMovimento { linhaAberta = nil } else { withAnimation(.spring(duration: 0.3, bounce: 0)) { linhaAberta = nil } }
```

Em `app-ios/Custta/Telas/PecasDaObra.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDaObra.swift
+++ b/app-ios/Custta/Telas/PecasDaObra.swift
@@ -140,6 +140,7 @@ struct IndicadoresDaObraView: View {
         Text(texto).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto)).fixedSize(horizontal: false, vertical: true)
     }
 
+
     private func linha(rotulo texto: String, etiqueta: (String, EtiquetaDoIndicador.Cor)?, valor: String, nota: String,
                        identificador: String, corDaNota: Token? = nil) -> some View {
         VStack(alignment: .leading, spacing: 4) {
@@ -373,3 +374,53 @@ struct CartaoDaLista<Conteudo: View>: View {
             .background { Color.clear.superficie(.conteudo, em: .rect(cornerRadius: 24, style: .continuous)) }
     }
 }
+
+/// As ações da fase, logo abaixo dos indicadores (mockup da etapa 2, parte 3): o próximo passo numa pílula sólida da marca
+/// ("Marcar como pronta", "Registrar venda"); voltar numa pílula de vidro ("Voltar pra construção", "Desfazer venda").
+/// Pílulas de 52 pt que crescem com a letra, 10 entre elas, ícone de 20 e o texto em .body semibold.
+struct AcoesDaFaseView: View {
+    let fase: Fase
+    let agir: (AcaoDaFase) -> Void
+    @ScaledMetric(relativeTo: .body) private var icone: CGFloat = 20
+
+    var body: some View {
+        VStack(spacing: 10) {
+            ForEach(acoesDaFase(fase), id: \.self) { acao in
+                Button { agir(acao) } label: {
+                    Label {
+                        Text(acao.rotulo)
+                    } icon: {
+                        Image(decorative: "Icones/\(acao.icone)").resizable().frame(width: icone, height: icone)
+                    }
+                }
+                .buttonStyle(PilulaDaAcao(principal: acao.principal))
+                .accessibilityIdentifier("acao-\(acao.rawValue)")
+            }
+        }
+    }
+}
+
+/// A pílula de uma ação da fase: sólida na Marca, com o texto em SobreMarca, ou no vidro do conteúdo, com o texto na cor
+/// do texto. Encolhe no toque, como os botões do app.
+struct PilulaDaAcao: ButtonStyle {
+    let principal: Bool
+    @Environment(\.paleta) private var paleta
+    @Environment(\.opcoes) private var opcoes
+
+    func makeBody(configuration: Configuration) -> some View {
+        let rotulo = configuration.label
+            .font(.body.weight(.semibold))
+            .multilineTextAlignment(.center)
+            .foregroundStyle(paleta.cor(principal ? .sobreMarca : .texto))
+            .padding(.horizontal, 20)
+            .padding(.vertical, 12)
+            .frame(maxWidth: .infinity, minHeight: 52)
+        Group {
+            if principal { rotulo.background(paleta.cor(.marca), in: .capsule) }
+            else { rotulo.superficie(.conteudo, em: .capsule) }
+        }
+        .contentShape(.capsule)
+        .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.97 : 1)
+        .animation(configuration.isPressed ? .easeOut(duration: 0.1) : .spring(duration: 0.3), value: configuration.isPressed)
+    }
+}
```


- [ ] **Step 4: Ver passar**

Run: `-only-testing:CusttaUITests/FasesUITests -only-testing:CusttaUITests/ObraUITests`.
Expected: os 2 testes de `FasesUITests` e os 7 de `ObraUITests` verdes; as guardas em Node verdes (a troca das ações usa `opcoes.reduzirMovimento`).

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Telas/ObraView.swift \
  app-ios/Custta/Telas/PecasDaObra.swift \
  app-ios/CusttaUITests/FasesUITests.swift
git commit -m "feat: ações da fase na tela da obra, com a vibração leve" -m "O próximo passo numa pílula sólida e o voltar numa pílula de vidro, abaixo dos indicadores, como o mockup. Construção e pronta trocam na hora e sem pergunta, com a etiqueta e as ações na mola e uma vibração leve só quando a ação é feita aqui; desfazer a venda pergunta com o texto do site."
```

### Task 30: "Não salvou" uma vez por erro, com o alerta do site, e a pílula da barra na largura dela

O erro de gravação que não passa sozinho (permission-denied, limite de dados) vira o alerta "Não salvou na nuvem" com "OK" e "Tentar de novo", uma vez por erro: o Sincronizador conta as confirmações do servidor, e um erro novo sem confirmação no meio é o mesmo erro, que fica só na pílula. Com uma folha aberta, o alerta espera ela descer. A pílula "Sem conexão" / "Não salvou" fica na largura do rótulo: ao lado do lápis (Tarefa 33), a barra cortava "Sem conex…".

**Files:**
- Modify: `app-ios/Custta/Estado/ModeloApp.swift`
- Modify: `app-ios/Custta/Falsos/MontarFalso.swift`
- Modify: `app-ios/Custta/Falsos/TransporteFalsoApp.swift`
- Modify: `app-ios/Custta/Telas/PrincipalView.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift`
- Test (alterar): `app-ios/CusttaTests/ModeloAppTests.swift`
- Test (alterar): `app-ios/CusttaUITests/Abrir.swift`
- Test (criar): `app-ios/CusttaUITests/EstadosUITests.swift`

**Interfaces:**
- Consumes: Tarefas 11 e 28 (`alertaDeNaoSalvou`); `Sincronizador.aoAvisar`.
- Produces: `Sincronizador.confirmadas`; `ModeloApp.alertaDeGravacao`, `fecharAlertaDeGravacao()` e `AlertaDeGravacao`; `AvisosDoPrincipal` (privado da `PrincipalView`); nos falsos, `CUSTTA_GRAVACAO=recusa`; nos testes, `abrirApp(gravacao:)` e `digitarComFoco(_:em:)`, e o `TransporteNaMao`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift
@@ -275,6 +275,25 @@ struct SincronizadorEscritaTests {
         relogio.avancar(30_000)
         #expect(transporte.gravacoes.count == 1, "a falha atrasada da u1 não volta para a fila e não sobe na u2")
     }
+
+    /// O "Não salvou" avisa uma vez por erro (etapa 2): quem avisa conta as gravações que o servidor confirmou, e só um erro
+    /// depois de uma confirmação nova é outro erro. Confirmação velha (de uma versão já trocada) não conta.
+    @Test func confirmadasContaSoAsVersoesQueOServidorConfirmou() throws {
+        let s = montar(), t = transporte
+        #expect(s.confirmadas == 0)
+        try s.aplicar(Estado.de(blobCom(["A"])))
+        t.gravacoes[0].concluir("permission-denied")
+        #expect(s.confirmadas == 0 && s.estadoSinc == .erro(codigo: "permission-denied", origem: .escrita))
+        s.tentarDeNovo()
+        t.gravacoes[1].concluir("permission-denied")
+        #expect(s.confirmadas == 0, "o erro que não passa sozinho continua o mesmo")
+        s.tentarDeNovo()
+        try s.aplicar(Estado.de(blobCom(["A", "B"])))
+        t.gravacoes[2].concluir(nil)
+        #expect(s.confirmadas == 0, "a confirmação de uma versão já trocada não conta")
+        t.gravacoes[3].concluir(nil)
+        #expect(s.confirmadas == 1 && s.estadoSinc == .ocioso)
+    }
 }
 
 @MainActor
```

Em `app-ios/CusttaTests/ModeloAppTests.swift`:

```diff
--- a/app-ios/CusttaTests/ModeloAppTests.swift
+++ b/app-ios/CusttaTests/ModeloAppTests.swift
@@ -281,13 +281,39 @@ struct ModeloAppTests {
         #expect(m.sincronizador.estado.obras.count == 4, "a escuta volta para a conta que entrou")
     }
 
-    @Test func avisoDoSincronizadorApareceNaTela() async {
+    /// O erro que não passa sozinho (aqui, o limite de dados) vira o alerta com o texto do site, e não o aviso do topo.
+    @Test func erroQueNaoPassaSozinhoViraOAlerta() async {
         let m = montar(conta: "senha").modelo
         await ate { m.sincronizador.dadosCarregados }
         let grande = Estado.de(.objeto(["obras": .lista([]), "config": .objeto(["taxaMensal": .numero(1)]),
                                         "notas": .texto(String(repeating: "a", count: 900_000))]))
         _ = try? await m.sincronizador.salvar(grande)
-        #expect(m.aviso == "Não salvou: limite de dados atingido. Reduza os dados e tente novamente.")
+        #expect(m.alertaDeGravacao == AlertaDeGravacao(titulo: "Não salvou: limite de dados atingido", mensagem: "Reduza os dados e tente novamente."))
+        #expect(m.aviso == nil)
+    }
+
+    /// Um alerta por erro (etapa 2, parte 3): tentar de novo e falhar de novo fica só na pílula; depois de uma gravação
+    /// confirmada, o erro seguinte é outro e alerta de novo.
+    @Test func naoSalvouAlertaUmaVezPorErro() async {
+        let transporte = TransporteNaMao()
+        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema())
+        let m = ModeloApp(conta: ContaFalsa(inicial: "senha"), sincronizador: sincronizador, rede: MonitorDeRede(forcarSemRede: false))
+        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
+        _ = try? m.sincronizador.aplicar(Estado.de(.objeto(["obras": .lista([])])))
+        transporte.responder("permission-denied")
+        #expect(m.alertaDeGravacao?.titulo == "Não salvou na nuvem")
+        #expect(m.alertaDeGravacao?.mensagem == "Confira sua conexão e conta; toque no aviso para tentar novamente.")
+        m.fecharAlertaDeGravacao()
+        m.tentarDeNovo()
+        transporte.responder("permission-denied")
+        #expect(m.alertaDeGravacao == nil, "o mesmo erro: só a pílula")
+        #expect(m.aviso == "Tentando de novo…")
+        m.tentarDeNovo()
+        transporte.responder(nil)
+        #expect(m.sincronizador.estadoSinc == .ocioso)
+        _ = try? m.sincronizador.aplicar(Estado.de(.objeto(["obras": .lista([])])))
+        transporte.responder("permission-denied")
+        #expect(m.alertaDeGravacao != nil, "depois de salvar, o erro seguinte é outro")
     }
 
     /// Como o cloud.js: a rede que volta confere a sessão sem forçar; a gravação recusada com
@@ -309,6 +335,29 @@ struct ModeloAppTests {
     }
 }
 
+/// Transporte em que o teste responde cada gravação na hora que quiser (`responder`), com o documento já visto.
+@MainActor
+final class TransporteNaMao: TransporteDados {
+    private final class Nada: Cancelavel { func cancelar() {} }
+    private var esperando: [(String?) -> Void] = []
+
+    func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
+                 aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel {
+        Task { @MainActor in aoReceber(Instantaneo(dados: nil, doCache: false, gravacaoPendente: false)) }
+        return Nada()
+    }
+
+    func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void) { esperando.append(concluir) }
+
+    func aguardarGravacoesPendentes(concluir: @escaping @MainActor (String?) -> Void) { concluir(nil) }
+
+    /// Responde a gravação mais antiga que ainda espera.
+    func responder(_ codigo: String?) {
+        guard !esperando.isEmpty else { return }
+        esperando.removeFirst()(codigo)
+    }
+}
+
 /// Transporte que responde do servidor (conta ainda sem documento) e recusa toda gravação com o
 /// código dado; o TransporteFalsoApp sempre confirma.
 @MainActor
```

Em `app-ios/CusttaUITests/Abrir.swift`:

```diff
--- a/app-ios/CusttaUITests/Abrir.swift
+++ b/app-ios/CusttaUITests/Abrir.swift
@@ -1,14 +1,17 @@
 import XCTest
 
 /// Abre o app com os serviços falsos (Custta/Falsos). Nada de rede nem de Firebase. `abrir: "obra:v1"` já abre a obra;
-/// `extra` passa outras variáveis dos falsos (`CUSTTA_APAGAR_REMOTO`).
+/// `folha: "novaObra"` abre uma folha quando os dados chegam; `gravacao: "recusa"` recusa toda gravação; `extra` passa
+/// outras variáveis dos falsos (`CUSTTA_APAGAR_REMOTO`).
 @MainActor
 func abrirApp(conta: String = "nenhuma", dados: String = "exemplo", rede: String? = nil, leitura: String? = nil,
-              limpeza: String? = nil, abrir: String? = nil, marca: String? = nil, argumentos: [String] = [],
-              extra: [String: String] = [:]) -> XCUIApplication {
+              limpeza: String? = nil, abrir: String? = nil, marca: String? = nil, folha: String? = nil, gravacao: String? = nil,
+              argumentos: [String] = [], extra: [String: String] = [:]) -> XCUIApplication {
     let app = XCUIApplication()
     var ambiente = ["CUSTTA_SERVICOS": "falsos", "CUSTTA_CONTA": conta, "CUSTTA_DADOS": dados].merging(extra) { _, novo in novo }
     if let abrir { ambiente["CUSTTA_ABRIR"] = abrir }
+    if let folha { ambiente["CUSTTA_FOLHA"] = folha }
+    if let gravacao { ambiente["CUSTTA_GRAVACAO"] = gravacao }
     if let marca { ambiente["CUSTTA_MARCA"] = marca }
     if let rede { ambiente["CUSTTA_REDE"] = rede }
     if let leitura { ambiente["CUSTTA_LEITURA"] = leitura }
@@ -49,6 +52,17 @@ extension XCUIApplication {
         botao.tap()
     }
 
+    /// Digita num campo que já devia estar com o foco: o XCUITest não espera a transição da folha, então toca no campo até
+    /// o teclado aparecer (FinalizarSaida, be2242c).
+    func digitarComFoco(_ texto: String, em campo: XCUIElement) {
+        XCTAssertTrue(campo.waitForExistence(timeout: 10), "campo \(campo.identifier)")
+        for _ in 0..<5 where !keyboards.firstMatch.exists {
+            campo.tap()
+            _ = keyboards.firstMatch.waitForExistence(timeout: 1.5)
+        }
+        campo.typeText(texto)
+    }
+
     func digitar(_ texto: String, em id: String, seguro: Bool = false) {
         let campo = seguro ? secureTextFields[id] : textFields[id]
         XCTAssertTrue(campo.waitForExistence(timeout: 10), "campo \(id)")
```

Criar `app-ios/CusttaUITests/EstadosUITests.swift`:

```swift
import XCTest

/* Os estados da etapa 2, parte 3, e o gasto numa obra vendida: a lista vazia que convida ao +; o + que avisa enquanto os
   dados não chegam; o gasto lançado de dentro de uma vendida, que vai para uma aberta escolhida na linha "Obra"; sem
   conexão, gravar continua; o "Não salvou" que não passa sozinho alerta uma vez e tocar na pílula tenta de novo. */
@MainActor
final class EstadosUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testSemConexaoGravarContinua() {
        let app = abrirApp(conta: "senha", dados: "vitrine", rede: "offline", abrir: "obra:v1")
        let pilula = app.buttons["indicadorSincronizacao"]
        XCTAssertTrue(pilula.waitForExistence(timeout: 10))
        XCTAssertEqual(pilula.label, "Sem conexão")
        let pronta = app.buttons["acao-marcarPronta"]
        app.rolarAte(pronta)
        pronta.tap()
        XCTAssertTrue(app.buttons["acao-registrarVenda"].waitForExistence(timeout: 5), "a fase muda na hora, sem rede")
        XCTAssertEqual(pilula.label, "Sem conexão")
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    func testNaoSalvouAlertaUmaVezETocarTentaDeNovo() {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", gravacao: "recusa")
        let pronta = app.buttons["acao-marcarPronta"]
        XCTAssertTrue(pronta.waitForExistence(timeout: 10))
        app.rolarAte(pronta)
        pronta.tap()
        let alerta = app.alerts["Não salvou na nuvem"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["Confira sua conexão e conta; toque no aviso para tentar novamente."].exists)
        alerta.buttons["Tentar de novo"].tap()
        XCTAssertTrue(app.staticTexts["Tentando de novo…"].waitForExistence(timeout: 3))
        let pilula = app.buttons["indicadorSincronizacao"]
        XCTAssertTrue(pilula.waitForExistence(timeout: 5))
        XCTAssertFalse(alerta.waitForExistence(timeout: 3), "o mesmo erro não alerta de novo")
        XCTAssertEqual(pilula.label, "Não salvou")
        pilula.tap()
        XCTAssertTrue(app.staticTexts["Tentando de novo…"].waitForExistence(timeout: 3), "tocar na pílula tenta de novo")
        XCTAssertFalse(alerta.waitForExistence(timeout: 3))
        XCTAssertEqual(pilula.label, "Não salvou")
    }
}
```


- [ ] **Step 2: Ver falhar**

Run: o filtro `SincronizadorEscritaTests` do núcleo; depois `xcodebuild build-for-testing`.
Expected: `value of type 'Sincronizador' has no member 'confirmadas'`; no app, `has no member 'alertaDeGravacao'`.

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Estado/ModeloApp.swift`:

```diff
--- a/app-ios/Custta/Estado/ModeloApp.swift
+++ b/app-ios/Custta/Estado/ModeloApp.swift
@@ -39,6 +39,9 @@ final class ModeloApp {
     private(set) var saindo = false
     /// O "Finalizar saída", ou nil quando não há limpeza do cache pendente.
     private(set) var limpeza: Limpeza?
+    /// O alerta do "Não salvou" quando a gravação não passa sozinha (o erro terminal), uma vez por erro: depois dele, só a
+    /// pílula da barra (no site, um toast a cada erro).
+    private(set) var alertaDeGravacao: AlertaDeGravacao?
     let sincronizador: Sincronizador
     let rede: MonitorDeRede
 
@@ -48,12 +51,15 @@ final class ModeloApp {
     @ObservationIgnored private var saindoDeProposito = false
     @ObservationIgnored private var checagem = 0
     @ObservationIgnored private var tarefaDoAviso: Task<Void, Never>?
+    /// As confirmações do servidor quando o último alerta de "Não salvou" apareceu: um erro novo sem confirmação no meio é
+    /// o mesmo erro, e não alerta de novo.
+    @ObservationIgnored private var alertouNaConfirmacao: Int?
 
     init(conta: ServicoConta, sincronizador: Sincronizador, rede: MonitorDeRede) {
         self.conta = conta
         self.sincronizador = sincronizador
         self.rede = rede
-        sincronizador.aoAvisar = { [weak self] aviso in self?.avisar(aviso.mensagem) }
+        sincronizador.aoAvisar = { [weak self] aviso in self?.receber(aviso) }
         sincronizador.aoPedirVerificacaoDeSessao = { [weak self] forcar in
             Task { await self?.conta.verificarSessao(forcar: forcar) }
         }
@@ -85,6 +91,7 @@ final class ModeloApp {
             uidAtivo = nil
             sincronizador.parar()
             nome = nil
+            esquecerAlertaDeGravacao()
             if expirou { mensagemEntrada = Self.sessaoExpirada }
             fase = .entrada
             return
@@ -93,6 +100,7 @@ final class ModeloApp {
         mensagemEntrada = nil
         if uidAtivo != u.uid {
             uidAtivo = u.uid
+            esquecerAlertaDeGravacao()
             sincronizador.iniciar(uid: u.uid)
         }
         if u.contaSocial, await conta.perfilPendente() {
@@ -289,6 +297,23 @@ final class ModeloApp {
         sincronizador.tentarDeNovo()
     }
 
+    /// Os avisos do Sincronizador: o erro terminal de gravação vira o alerta, uma vez por erro; os outros, o aviso do topo.
+    private func receber(_ aviso: AvisoSinc) {
+        guard case .naoSalvou(let codigo, true) = aviso else { avisar(aviso.mensagem); return }
+        guard alertouNaConfirmacao != sincronizador.confirmadas else { return }
+        alertouNaConfirmacao = sincronizador.confirmadas
+        let a = alertaDeNaoSalvou(codigo: codigo)
+        alertaDeGravacao = AlertaDeGravacao(titulo: a.titulo, mensagem: a.mensagem)
+    }
+
+    /// O alerta do "Não salvou" fechou (OK ou "Tentar de novo").
+    func fecharAlertaDeGravacao() { alertaDeGravacao = nil }
+
+    private func esquecerAlertaDeGravacao() {
+        alertouNaConfirmacao = nil
+        alertaDeGravacao = nil
+    }
+
     func avisar(_ texto: String) {
         aviso = texto
         tarefaDoAviso?.cancel()
@@ -299,3 +324,9 @@ final class ModeloApp {
         }
     }
 }
+
+/// O alerta do "Não salvou", com o texto do site partido em título e mensagem.
+struct AlertaDeGravacao: Equatable {
+    let titulo: String
+    let mensagem: String
+}
```

Em `app-ios/Custta/Falsos/MontarFalso.swift`:

```diff
--- a/app-ios/Custta/Falsos/MontarFalso.swift
+++ b/app-ios/Custta/Falsos/MontarFalso.swift
@@ -9,6 +9,7 @@ import CusttaNucleo
    CUSTTA_DADOS   vitrine (padrão: as obras do mockup) | exemplo (as dos testes) | vazio
    CUSTTA_REDE    offline (abre "em modo avião": dados do cache e indicador "Sem conexão")
    CUSTTA_LEITURA erro (a escuta falha com permission-denied) | formato (documento que o app não lê)
+   CUSTTA_GRAVACAO recusa (toda gravação volta com permission-denied: o "Não salvou" que não passa sozinho)
    CUSTTA_APAGAR_REMOTO <obra>/<gasto>@<segundos> (outro aparelho apaga o gasto, com o app aberto)
    CUSTTA_MARCA   servidor (o servidor já respondeu a esta conta numa abertura anterior: com CUSTTA_REDE=offline e
                   CUSTTA_DADOS=vazio, é a conta vazia que abre sem rede e pode lançar)
@@ -36,7 +37,9 @@ extension Composicao {
             guard partes.count == 3, let segundos = Double(partes[2]) else { return nil }
             return (partes[0], partes[1], segundos)
         }
-        let transporte = TransporteFalsoApp(dados: dados, semRede: semRede, falhaDeLeitura: falha, apagarRemoto: remoto)
+        let transporte = TransporteFalsoApp(dados: dados, semRede: semRede, falhaDeLeitura: falha,
+                                            recusa: ambiente["CUSTTA_GRAVACAO"] == "recusa" ? "permission-denied" : nil,
+                                            apagarRemoto: remoto)
         let rede = MonitorDeRede(forcarSemRede: semRede)
         let marca = MarcaEmMemoria()
         if ambiente["CUSTTA_MARCA"] == "servidor" { marca.marcarTodas = true }
```

Em `app-ios/Custta/Falsos/TransporteFalsoApp.swift`:

```diff
--- a/app-ios/Custta/Falsos/TransporteFalsoApp.swift
+++ b/app-ios/Custta/Falsos/TransporteFalsoApp.swift
@@ -4,7 +4,8 @@ import CusttaNucleo
 
 /// Transporte falso dos testes (só Debug): entrega um blob fixo e confirma gravações depois de
 /// 300 ms (nunca, sem rede). `falhaDeLeitura` faz a escuta falhar com esse código antes do primeiro
-/// snapshot (CUSTTA_LEITURA=erro: permission-denied; formato: formato-desconhecido). `apagarRemoto`
+/// snapshot (CUSTTA_LEITURA=erro: permission-denied; formato: formato-desconhecido). `recusa` responde toda gravação
+/// com esse código (CUSTTA_GRAVACAO=recusa: permission-denied, o "Não salvou" que não passa sozinho). `apagarRemoto`
 /// simula outro aparelho apagando um gasto: um segundo snapshot, sem ele, depois de alguns segundos
 /// (CUSTTA_APAGAR_REMOTO=<obra>/<gasto>@<segundos>).
 @MainActor
@@ -13,15 +14,17 @@ final class TransporteFalsoApp: TransporteDados {
     private let dados: ValorJSON?
     private let semRede: Bool
     private let falhaDeLeitura: String?
+    private let recusa: String?
     private let apagarRemoto: (obra: String, gasto: String, depois: Double)?
     /// Quantas gravações chegaram (os testes conferem que abrir o app não grava nada).
     private(set) var gravacoes = 0
 
-    init(dados: ValorJSON?, semRede: Bool, falhaDeLeitura: String? = nil,
+    init(dados: ValorJSON?, semRede: Bool, falhaDeLeitura: String? = nil, recusa: String? = nil,
          apagarRemoto: (obra: String, gasto: String, depois: Double)? = nil) {
         self.dados = dados
         self.semRede = semRede
         self.falhaDeLeitura = falhaDeLeitura
+        self.recusa = recusa
         self.apagarRemoto = apagarRemoto
     }
 
@@ -56,9 +59,10 @@ final class TransporteFalsoApp: TransporteDados {
     func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void) {
         gravacoes += 1
         guard !semRede else { return }
+        let recusa = self.recusa
         Task { @MainActor in
             try? await Task.sleep(for: .milliseconds(300))
-            concluir(nil)
+            concluir(recusa)
         }
     }
```

Em `app-ios/Custta/Telas/PrincipalView.swift`:

```diff
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -31,6 +31,7 @@ struct PrincipalView: View {
         }
         // Com a folha aberta o fundo para: ela cobre quase tudo, e cada quadro da aurora refaria o desfoque dela.
         .pausaOFundo(enquanto: folhas.aberta != nil)
+        .modifier(AvisosDoPrincipal(folhaAberta: folhas.aberta != nil))
         #if DEBUG
         .task { await abrirFolhaDeTeste() }
         // Teste de tela: quantas pontes de fechamento estão vivas (abrir e fechar a folha não pode deixar nenhuma).
@@ -82,6 +83,31 @@ extension PrincipalView {
     }
 }
 
+/// O alerta do "Não salvou" (uma vez por erro, com "Tentar de novo") por cima das abas, num fundo vazio, com os botões na
+/// cor do texto, como o "Sair da conta?". Espera a folha aberta descer.
+private struct AvisosDoPrincipal: ViewModifier {
+    let folhaAberta: Bool
+    @Environment(ModeloApp.self) private var modelo
+    @Environment(\.paleta) private var paleta
+
+    func body(content: Content) -> some View {
+        let gravacao = modelo.alertaDeGravacao
+        content
+            .background {
+                Color.clear
+                    .alert(gravacao?.titulo ?? "", isPresented: Binding(get: { gravacao != nil && !folhaAberta },
+                                                                         set: { if !$0 { modelo.fecharAlertaDeGravacao() } })) {
+                        Button("OK", role: .cancel) {}
+                        Button("Tentar de novo") { modelo.tentarDeNovo() }
+                    } message: {
+                        Text(gravacao?.mensagem ?? "")
+                    }
+                    .tint(paleta.cor(.texto))
+            }
+            .pausaOFundo(enquanto: gravacao != nil && !folhaAberta)
+    }
+}
+
 /// Sincronização e sair, no canto da barra de Obras e de Ajustes.
 struct BarraDoApp: ToolbarContent {
     @Binding var confirmarSaida: Bool
@@ -108,7 +134,9 @@ struct IndicadorDeSincronizacao: View {
                 HStack(spacing: 7) {
                     if i.girando { ProgressView().controlSize(.mini) }
                     else { Circle().fill(paleta.cor(i.erro ? .erroNoVidro : .texto)).frame(width: 8, height: 8).opacity(i.erro ? 1 : 0.75) }
-                    Text(i.rotulo).font(.footnote.weight(.semibold)).lineLimit(1)
+                    // Na barra da obra, ao lado do lápis, a barra oferecia uns 2 pt a menos do que o rótulo pede e cortava
+                    // "Sem conex…": o rótulo fica na largura dele.
+                    Text(i.rotulo).font(.footnote.weight(.semibold)).lineLimit(1).fixedSize()
                 }
                 .foregroundStyle(paleta.cor(.texto))
                 .padding(.horizontal, 14)
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift
@@ -131,6 +131,9 @@ public final class Sincronizador {
     /// Cache sem documento (app recém-instalado, sem rede) não conta: o servidor pode ter obras.
     /// Volta a falso se chegar um documento que o app não conseguiu ler inteiro.
     public private(set) var dadosCarregados = false
+    /// Quantas vezes o servidor confirmou a versão mais nova (a fila ficou em dia). Quem avisa do erro que não passa
+    /// sozinho avisa uma vez por erro: um erro depois de uma confirmação nova é outro erro.
+    @ObservationIgnored public private(set) var confirmadas = 0
 
     @ObservationIgnored public var aoAvisar: ((AvisoSinc) -> Void)?
     /// Pede para conferir a sessão, como o `verificarSessao` do cloud.js: o erro "unauthenticated" ao
@@ -285,6 +288,7 @@ public final class Sincronizador {
         tentativa = 0
         if pendente != nil { enviar(); return }
         sujo = false
+        confirmadas += 1
         publicar(.ocioso)
         terminarEsperas(nil)
     }
```


- [ ] **Step 4: Ver passar**

Run: o núcleo inteiro; `-only-testing:CusttaTests -only-testing:CusttaUITests/EstadosUITests`.
Expected: `✔ Test run with 178 tests … passed`; `CusttaTests` verde (99 testes); os 2 testes de `EstadosUITests` verdes.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Estado/ModeloApp.swift \
  app-ios/Custta/Falsos/MontarFalso.swift \
  app-ios/Custta/Falsos/TransporteFalsoApp.swift \
  app-ios/Custta/Telas/PrincipalView.swift \
  app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift \
  app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift \
  app-ios/CusttaTests/ModeloAppTests.swift \
  app-ios/CusttaUITests/Abrir.swift \
  app-ios/CusttaUITests/EstadosUITests.swift
git commit -m "feat: \"Não salvou\" uma vez por erro, com o alerta do site, e a pílula da barra na largura dela" -m "O erro de gravação que não passa sozinho vira o alerta do site, com Tentar de novo, uma vez por erro: o Sincronizador conta as confirmações do servidor e só um erro depois de uma confirmação nova é outro erro; o resto fica na pílula. O alerta espera a folha aberta descer. A pílula de sincronização passa a ter a largura do rótulo, porque ao lado do lápis a barra cortava o texto."
```

### Task 31: Folha da venda em dois passos, com a data no calendário

"Registrar venda" abre o teclado de valor ("Avançar") e depois "Data da venda" (hoje; o calendário vai do início da obra até hoje) e "Confirmar venda". O valor volta ao teclado pela linha; a data fora do intervalo mostra a mensagem do site. Depois do valor, fechar pergunta "Você já preencheu esta venda.". Gravada, a obra vira vendida na hora e a folha desce.

**Files:**
- Modify: `app-ios/Custta/Estado/Folhas.swift`
- Modify: `app-ios/Custta/Identidade/PecasDaFolha.swift`
- Create: `app-ios/Custta/Telas/FolhaDaVenda.swift`
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Modify: `app-ios/Custta/Telas/PrincipalView.swift`
- Test (alterar): `app-ios/CusttaUITests/FasesUITests.swift`

**Interfaces:**
- Consumes: Tarefas 5 (`conferirVenda`), 21 (`TecladoDeValor`, `GrupoDaFolha`, `LinhaDaFolhaComRotulo`, `SetaDaLinha`), 22 (`.folhaDoApp`, `.passoDaFolha`, `CampoDeData`), 28 e 29.
- Produces: `FolhaDaVenda(obraId:)`, `RascunhoDaVenda`, `PassoDaVenda`; `Folhas.Qual.venda(obraId:)`; `LinhaDeDinheiro(rotulo:centavos:opcional:altura:identificador:abrir:)`; em Debug, `CUSTTA_FOLHA=venda:<id>` abre a folha quando os dados chegam e `-custta.folha detalhes` já a põe na data; os identificadores `confirmarVenda`, `confirmarValor` e `fecharFolha`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaUITests/FasesUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/FasesUITests.swift
+++ b/app-ios/CusttaUITests/FasesUITests.swift
@@ -26,6 +26,38 @@ final class FasesUITests: XCTestCase {
         XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
     }
 
+    func testRegistrarVendaEmDoisPassos() {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2")
+        let vender = app.buttons["acao-registrarVenda"]
+        XCTAssertTrue(vender.waitForExistence(timeout: 10))
+        app.rolarAte(vender)
+        vender.tap()
+        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
+        XCTAssertFalse(app.buttons["confirmarValor"].isEnabled, "\"Avançar\" só com valor")
+        for t in ["1", "3", "8", "0", "0", "0", "0", "0", "0"] { app.buttons["tecla-\(t)"].tap() }
+        XCTAssertEqual(app.elemento("visorDoValor").value as? String, "R$ 1.380.000,00")
+        app.buttons["confirmarValor"].tap()
+        let confirmar = app.buttons["confirmarVenda"]
+        XCTAssertTrue(confirmar.waitForExistence(timeout: 5))
+        XCTAssertEqual(app.elemento("linhaValorDaVenda").value as? String, "R$\u{a0}1.380.000,00")
+        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Entre o início da obra (")).firstMatch.exists)
+        confirmar.tap()
+        XCTAssertTrue(confirmar.waitForNonExistence(timeout: 5), "a folha desce")
+        XCTAssertTrue(app.buttons["acao-desfazerVenda"].waitForExistence(timeout: 5), "vendida: só desfazer")
+        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Vendida"))
+        let venda = app.elemento("indicadorVenda").label
+        XCTAssertTrue(venda.contains("R$\u{a0}1.380.000,00") && venda.contains("Vendida em "), venda)
+    }
+
+    func testValorDaVendaVoltaAoTecladoPelaLinha() {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2", folha: "venda:v2", argumentos: ["-custta.folha", "detalhes"])
+        let linha = app.elemento("linhaValorDaVenda")
+        XCTAssertTrue(linha.waitForExistence(timeout: 10))
+        linha.tap()
+        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5), "a linha do valor volta ao teclado")
+        XCTAssertEqual(app.elemento("visorDoValor").value as? String, "R$ 1.380.000,00")
+    }
+
     func testDesfazerVendaPerguntaComOTextoDoSite() {
         let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
         let desfazer = app.buttons["acao-desfazerVenda"]
@@ -46,4 +78,15 @@ final class FasesUITests: XCTestCase {
         XCTAssertTrue(app.elemento("faseDaObra").label.contains("Pronta · à venda"))
         XCTAssertTrue(app.elemento("indicadorVenda").label.contains("Venda estimada"), "a venda saiu; volta a estimativa")
     }
+
+    func testDescartarVendaDepoisDoValorPergunta() {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2", folha: "venda:v2", argumentos: ["-custta.folha", "detalhes"])
+        XCTAssertTrue(app.buttons["confirmarVenda"].waitForExistence(timeout: 10))
+        app.buttons["fecharFolha"].tap()
+        let alerta = app.alerts["Você já preencheu esta venda."]
+        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
+        alerta.buttons["Descartar venda"].tap()
+        XCTAssertTrue(app.buttons["confirmarVenda"].waitForNonExistence(timeout: 5))
+        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Pronta · à venda"), "nada foi gravado")
+    }
 }
```


- [ ] **Step 2: Ver falhar**

Run: `xcodebuild build-for-testing` e `-only-testing:CusttaUITests/FasesUITests`.
Expected: `testRegistrarVendaEmDoisPassos` falha (`acao-registrarVenda` não abre nada).

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Estado/Folhas.swift`:

```diff
--- a/app-ios/Custta/Estado/Folhas.swift
+++ b/app-ios/Custta/Estado/Folhas.swift
@@ -9,6 +9,7 @@ final class Folhas {
     enum Qual: Identifiable, Hashable {
         case novoGasto(obraId: String)
         case editarGasto(obraId: String, gastoId: String)
+        case venda(obraId: String)
 
         var id: Self { self }
     }
```

Em `app-ios/Custta/Identidade/PecasDaFolha.swift`:

```diff
--- a/app-ios/Custta/Identidade/PecasDaFolha.swift
+++ b/app-ios/Custta/Identidade/PecasDaFolha.swift
@@ -62,6 +62,40 @@ struct LinhaDaFolhaComRotulo<Valor: View>: View {
     }
 }
 
+/// Uma linha de dinheiro que abre o teclado de valor ("Valor estimado de venda", "Orçamento total", "Valor da venda"):
+/// "R$" e o valor, ou "Opcional" vazia, e a seta.
+struct LinhaDeDinheiro: View {
+    let rotulo: String
+    let centavos: Int
+    var opcional = true
+    var altura: CGFloat = 52
+    var identificador: String
+    let abrir: () -> Void
+    @Environment(\.paleta) private var paleta
+
+    var body: some View {
+        Button(action: abrir) {
+            LinhaDaFolhaComRotulo(rotulo: rotulo, altura: altura) {
+                HStack(alignment: .firstTextBaseline, spacing: 6) {
+                    if centavos == 0 && opcional {
+                        Text("Opcional").foregroundStyle(paleta.cor(.secundarioSolido))
+                    } else {
+                        Text("R$").font(.callout.weight(.semibold)).foregroundStyle(paleta.cor(.secundarioSolido))
+                        ValorEmDinheiro(texto: fmtCentavos(centavos), fonte: altura > 52 ? .title2.weight(.bold) : .body.weight(.semibold))
+                    }
+                    SetaDaLinha()
+                }
+            }
+        }
+        .buttonStyle(.plain)
+        .accessibilityElement(children: .ignore)
+        .accessibilityLabel(rotulo)
+        .accessibilityValue(centavos == 0 && opcional ? "Opcional" : moeda(centavosParaReais(centavos)))
+        .accessibilityAddTraits(.isButton)
+        .accessibilityIdentifier(identificador)
+    }
+}
+
 /// A seta ">" das linhas que abrem outro passo.
 struct SetaDaLinha: View {
     @Environment(\.paleta) private var paleta
```

Criar `app-ios/Custta/Telas/FolhaDaVenda.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* A folha da venda (mockup da etapa 2, parte 3; formVenda do site), em dois passos como o gasto: o valor no teclado de
   valor e "Avançar" empurra a data, no calendário limitado entre o início da obra e hoje (no site, um erro depois), e
   "Confirmar venda". Grava `venda {valor, data}` e a fase vendida pela regra do núcleo; a folha desce e a obra mostra o
   lucro. */

enum PassoDaVenda: Hashable {
    case data
}

@MainActor @Observable
final class RascunhoDaVenda {
    var centavos = 0
    var data: String
    /// Passou do valor: fechar passa a perguntar.
    var passouDoValor = false

    init(hoje: String) { data = hoje }
}

struct FolhaDaVenda: View {
    let obraId: String
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @State private var rascunho = RascunhoDaVenda(hoje: dataLocalISO(.now, fuso: .current))
    @State private var caminho: [PassoDaVenda] = []

    private var obra: Obra? { modelo.sincronizador.estado.obras.first { $0.id == obraId } }

    var body: some View {
        NavigationStack(path: $caminho) {
            TecladoDeValor(centavos: $rascunho.centavos, acao: "Avançar") {
                rascunho.passouDoValor = true
                caminho = [.data]
            }
            .passoDaFolha("Valor da venda", subtitulo: obra?.nome, fechar: .esquerda, raiz: true)
            .navigationDestination(for: PassoDaVenda.self) { _ in
                PassoDaDataDaVenda(rascunho: rascunho, caminho: $caminho, obraId: obraId)
            }
        }
        .folhaDoApp(perguntar: rascunho.passouDoValor, pergunta: "Você já preencheu esta venda.", descartar: "Descartar venda") {
            folhas.fechar()
        }
        // A obra sumiu ou outro aparelho mudou a fase com a folha aberta: não há o que vender; a folha fecha.
        .onChange(of: obra?.fase == .pronta) { _, pronta in if !pronta { folhas.fechar() } }
        #if DEBUG
        // Testes de tela e laudo: a folha aberta já na data (`-custta.folha detalhes`), com o valor do mockup.
        .onAppear {
            guard UserDefaults.standard.string(forKey: "custta.folha") == "detalhes", caminho.isEmpty else { return }
            rascunho.centavos = 138_000_000
            rascunho.passouDoValor = true
            caminho = [.data]
        }
        #endif
    }
}

private struct PassoDaDataDaVenda: View {
    @Bindable var rascunho: RascunhoDaVenda
    @Binding var caminho: [PassoDaVenda]
    let obraId: String
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @Environment(\.paleta) private var paleta
    @State private var erro: String?
    @State private var naoCarregado = false
    @State private var contaReal = false

    var body: some View {
        let obra = modelo.sincronizador.estado.obras.first { $0.id == obraId }
        let hoje = dataLocalISO(.now, fuso: .current)
        let inicio = obra?.dataInicio ?? hoje
        ScrollView {
            VStack(spacing: 8) {
                GrupoDaFolha {
                    LinhaDeDinheiro(rotulo: "Valor da venda", centavos: rascunho.centavos, opcional: false, altura: 60,
                                    identificador: "linhaValorDaVenda") { caminho.removeAll() }
                    SeparadorDaFolha()
                    LinhaDaFolhaComRotulo(rotulo: "Data da venda") {
                        // O calendário só deixa escolher entre o início e hoje (obra que começa no futuro: só hoje, e o
                        // "Confirmar venda" explica com o texto do site).
                        CampoDeData(iso: $rascunho.data, minimo: min(inicio, hoje), maximo: hoje)
                    }
                }
                NotaDaFolha(texto: notaDaDataDaVenda(dataInicio: inicio))
                if let erro { NotaDaFolha(texto: erro, cor: .erroNoVidro, identificador: "erroDaVenda") }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Confirmar venda") { confirmar(inicio: inicio, hoje: hoje) }
                .buttonStyle(BotaoDaFolha())
                .accessibilityIdentifier("confirmarVenda")
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)
        }
        .onChange(of: rascunho.data) { _, _ in erro = nil }
        .passoDaFolha("Registrar venda", subtitulo: obra?.nome, fechar: .direita)
        .background {
            Color.clear
                .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("A venda continua aqui; nada foi salvo ainda.")
                }
                .tint(paleta.cor(.texto))
        }
        .alert(ContaDeTeste.titulo, isPresented: $contaReal) { Button("OK", role: .cancel) {} } message: { Text(ContaDeTeste.mensagem) }
        .pausaOFundo(enquanto: naoCarregado || contaReal)
    }

    private func confirmar(inicio: String, hoje: String) {
        let valor = centavosParaReais(rascunho.centavos)
        if let e = conferirVenda(valor: valor, data: rascunho.data, dataInicio: inicio, hoje: hoje) {
            if e.campo == "valor" { caminho.removeAll(); return }       // sem mensagem, como o site: volta ao teclado
            erro = e.mensagem
            if let m = e.mensagem { AccessibilityNotification.Announcement(m).post() }
            return
        }
        switch modelo.gravar({ $0.registrandoVenda(obraId, valor: valor, data: rascunho.data) }) {
        case .gravou, .sumiu, .semConta: folhas.fechar()
        case .naoCarregado: naoCarregado = true
        case .contaReal: contaReal = true
        }
    }
}
```

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -151,7 +151,7 @@ extension ObraView {
         switch acao {
         case .marcarPronta: mudar(obra) { $0.mudandoFase(obra.id, para: .pronta) }
         case .voltarConstrucao: mudar(obra) { $0.mudandoFase(obra.id, para: .construcao) }
-        case .registrarVenda: break    // a folha da venda chega na Tarefa 31
+        case .registrarVenda: folhas.aberta = .venda(obraId: obra.id)
         case .desfazerVenda: desfazendo = true
         }
     }
```

Em `app-ios/Custta/Telas/PrincipalView.swift`:

```diff
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -24,16 +24,20 @@ struct PrincipalView: View {
         // Barra própria: o que rola por baixo dela passa pela borda suave de cada tela (BordaDeRolagem).
         .safeAreaBar(edge: .bottom, spacing: 0) { CapsulaDeAbas(escolhida: $aba, mais: acaoDoMais) }
         .sheet(item: $folhas.aberta, onDismiss: folhas.fechou) { qual in
-            switch qual {
-            case .novoGasto(let obraId): FolhaDoGasto(obraId: obraId, gastoId: nil).environment(folhas)
-            case .editarGasto(let obraId, let gastoId): FolhaDoGasto(obraId: obraId, gastoId: gastoId).environment(folhas)
+            Group {
+                switch qual {
+                case .novoGasto(let obraId): FolhaDoGasto(obraId: obraId, gastoId: nil)
+                case .editarGasto(let obraId, let gastoId): FolhaDoGasto(obraId: obraId, gastoId: gastoId)
+                case .venda(let obraId): FolhaDaVenda(obraId: obraId)
+                }
             }
+            .environment(folhas)
         }
         // Com a folha aberta o fundo para: ela cobre quase tudo, e cada quadro da aurora refaria o desfoque dela.
         .pausaOFundo(enquanto: folhas.aberta != nil)
         .modifier(AvisosDoPrincipal(folhaAberta: folhas.aberta != nil))
         #if DEBUG
-        .task { await abrirFolhaDeTeste() }
+        .task { await abrirFolhaDoGancho() }
         // Teste de tela: quantas pontes de fechamento estão vivas (abrir e fechar a folha não pode deixar nenhuma).
         .overlay(alignment: .topLeading) {
             if UserDefaults.standard.bool(forKey: "custta.contarPontes") {
@@ -60,14 +64,28 @@ extension PrincipalView {
     }
 
     #if DEBUG
-    /// Laudo de leitura, auditoria e conferência visual: com `CUSTTA_ABRIR=obra:<id>`, `-custta.folha <passo>` abre a folha
-    /// do gasto novo já no passo (valor, detalhes, cartao, topicos, repetido) e `-custta.folha editar:<gasto>`, a edição.
-    private func abrirFolhaDeTeste() async {
-        guard let passo = UserDefaults.standard.string(forKey: "custta.folha"), case .obra(let obraId)? = caminhoDeObras.last else { return }
-        while !modelo.sincronizador.dadosCarregados { try? await Task.sleep(for: .milliseconds(100)) }
+    /// Testes de tela, laudo e conferência visual: `CUSTTA_FOLHA` abre uma folha quando os dados chegam (`venda:<id>`,
+    /// `novoGasto:<id>`). Sem ele, com `CUSTTA_ABRIR=obra:<id>`,
+    /// `-custta.folha <passo>` abre a folha do gasto novo já no passo (valor, detalhes, cartao, topicos, repetido) e
+    /// `-custta.folha editar:<gasto>`, a edição.
+    private func abrirFolhaDoGancho() async {
+        let pedido = ProcessInfo.processInfo.environment["CUSTTA_FOLHA"]
+        let passo = UserDefaults.standard.string(forKey: "custta.folha")
+        guard pedido != nil || passo != nil else { return }
+        for _ in 0..<50 where !modelo.sincronizador.dadosCarregados { try? await Task.sleep(for: .milliseconds(100)) }
         try? await Task.sleep(for: .milliseconds(300))
-        folhas.aberta = passo.hasPrefix("editar:") ? .editarGasto(obraId: obraId, gastoId: String(passo.dropFirst(7)))
-                                                   : .novoGasto(obraId: obraId)
+        if let pedido {
+            let partes = pedido.split(separator: ":", maxSplits: 1).map(String.init)
+            let id = partes.count > 1 ? partes[1] : ""
+            switch partes[0] {
+            case "venda": folhas.aberta = .venda(obraId: id)
+            case "novoGasto": folhas.aberta = .novoGasto(obraId: id)
+            default: break
+            }
+        } else if let passo, case .obra(let obraId)? = caminhoDeObras.last {
+            folhas.aberta = passo.hasPrefix("editar:") ? .editarGasto(obraId: obraId, gastoId: String(passo.dropFirst(7)))
+                                                       : .novoGasto(obraId: obraId)
+        }
     }
     #endif
```


- [ ] **Step 4: Ver passar**

Run: `-only-testing:CusttaUITests/FasesUITests`.
Expected: os 5 testes verdes.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Estado/Folhas.swift \
  app-ios/Custta/Identidade/PecasDaFolha.swift \
  app-ios/Custta/Telas/FolhaDaVenda.swift \
  app-ios/Custta/Telas/ObraView.swift \
  app-ios/Custta/Telas/PrincipalView.swift \
  app-ios/CusttaUITests/FasesUITests.swift
git commit -m "feat: folha da venda em dois passos, com a data no calendário" -m "Registrar venda abre o teclado de valor e depois a data no calendário do iPhone, do início da obra até hoje, com Confirmar venda; o valor volta ao teclado pela linha, a data fora do intervalo mostra a mensagem do site e fechar depois do valor pergunta antes de descartar."
```

### Task 32: Nova obra pelo + da lista, com a lista vazia, o carregando e o aviso do limite

O + da cápsula aparece na lista de obras e abre "Nova obra": nome, "Começou em", área, valor estimado e orçamento (a ordem do mockup; os dois valores no teclado de valor, com zero valendo como apagar). Sem nome, a folha volta ao nome sem mensagem; sem área, "Informe área construída maior que zero.". Salvar grava a obra e entra nela com o push do sistema. Antes de ver os dados, o + avisa "Carregando suas obras…"; com 300 obras, "Limite de 300 obras". A lista vazia convida para o +, o carregando mostra só o indicador, e o cartão de estado ganha o desenho do mockup (ícone de 52 pt num quadrado de raio 16). A folha nasce inteira, com o modo editar e "Apagar obra", que ganham o lápis e os testes na Tarefa 33.

**Files:**
- Modify: `app-ios/Custta/Estado/Folhas.swift`
- Modify: `app-ios/Custta/Falsos/MontarFalso.swift`
- Modify: `app-ios/Custta/Falsos/TransporteFalsoApp.swift`
- Modify: `app-ios/Custta/Falsos/VitrineDaObra.swift`
- Modify: `app-ios/Custta/Identidade/PecasDaFolha.swift`
- Modify: `app-ios/Custta/Identidade/TecladoDeValor.swift`
- Create: `app-ios/Custta/Telas/FolhaDaObra.swift`
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Modify: `app-ios/Custta/Telas/ObrasView.swift`
- Modify: `app-ios/Custta/Telas/PrincipalView.swift`
- Test (alterar): `app-ios/CusttaUITests/EstadosUITests.swift`
- Test (criar): `app-ios/CusttaUITests/FolhaDaObraUITests.swift`

**Interfaces:**
- Consumes: Tarefas 5 e 7 (`conferirObra`, `obraNova`, `avisoLimiteDeObras`), 27, 28, 30 e 31.
- Produces: `FolhaDaObra(obraId:)`, `RascunhoDaObra`, `PassoDaObra`, `PerguntaDeApagarObra`; `CampoComRotuloEmCima(rotulo:erro:campo:)`; `TecladoDeValor.permiteZero`; `Folhas.Qual.novaObra` e `.editarObra(obraId:)`, `Folhas.Navegacao` (`.entrar`, `.trocar`, `.apagar`) e `Folhas.navegar(_:)`; na `PrincipalView`, `pedirNovaObra()`, `navegar(_:)` e `AvisoDoMais`; `CartaoDeEstado(titulo:texto:icone:carregando:identificador:acao:)`; nos falsos, `DadosDeExemplo.noTeto()`, `CUSTTA_DADOS=limite` e `CUSTTA_LEITURA=nunca`; em Debug, `CUSTTA_FOLHA=novaObra|editarObra:<id>` e `-custta.folha preenchida`; os identificadores `nomeDaObra`, `areaDaObra`, `salvarObra`, `apagarObra` e `obrasVazio`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaUITests/EstadosUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/EstadosUITests.swift
+++ b/app-ios/CusttaUITests/EstadosUITests.swift
@@ -7,6 +7,25 @@ import XCTest
 final class EstadosUITests: XCTestCase {
     override func setUp() { continueAfterFailure = false }
 
+    func testListaVaziaConvidaParaOMais() {
+        let app = abrirApp(conta: "senha", dados: "vazio")
+        let vazio = app.elemento("obrasVazio")
+        XCTAssertTrue(vazio.waitForExistence(timeout: 10))
+        XCTAssertEqual(vazio.label, "Nenhuma obra ainda.")
+        XCTAssertTrue(app.staticTexts["Toque no + para criar a primeira obra."].exists)
+        XCTAssertEqual(app.buttons["botaoMais"].label, "Nova obra")
+    }
+
+    func testCarregandoOMaisAvisaEmVezDeAbrir() {
+        let app = abrirApp(conta: "senha", leitura: "nunca")
+        XCTAssertTrue(app.elemento("obrasCarregando").waitForExistence(timeout: 10))
+        app.buttons["botaoMais"].tap()
+        let alerta = app.alerts["Carregando suas obras, tente em instantes."]
+        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
+        alerta.buttons["OK"].tap()
+        XCTAssertFalse(app.textFields["nomeDaObra"].exists, "sem ver os dados, \"Nova obra\" não abre")
+    }
+
     func testSemConexaoGravarContinua() {
         let app = abrirApp(conta: "senha", dados: "vitrine", rede: "offline", abrir: "obra:v1")
         let pilula = app.buttons["indicadorSincronizacao"]
```

Criar `app-ios/CusttaUITests/FolhaDaObraUITests.swift`:

```swift
import XCTest

/* Criar, editar e apagar obra (etapa 2, parte 3). Nova obra pelo + da lista: o cursor no nome e o teclado aberto; a área
   obrigatória com o erro do site, que some ao digitar; o valor estimado no teclado de valor; "Criar obra" entra direto na
   obra nova. Editar pelo lápis da barra; apagar no fim da folha, com o alerta do nome e dos lançamentos, volta à lista e a
   linha sai. O + avisa o teto de 300 obras antes de abrir. */
@MainActor
final class FolhaDaObraUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testCriarObraComOErroDaAreaEEntrarNela() {
        let app = abrirApp(conta: "senha", dados: "vitrine")
        let mais = app.buttons["botaoMais"]
        XCTAssertTrue(app.elemento("obra-v1").waitForExistence(timeout: 10))
        XCTAssertEqual(mais.label, "Nova obra")
        mais.tap()
        let nome = app.textFields["nomeDaObra"]
        XCTAssertTrue(nome.waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "o cursor no nome e o teclado aberto")
        app.digitarComFoco("Casa Granja Viana 2", em: nome)
        app.elemento("linhaEstimado").tap()
        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
        for t in ["1", "6", "0", "0", "0", "0", "0", "0", "0"] { app.buttons["tecla-\(t)"].tap() }
        app.buttons["confirmarValor"].tap()
        XCTAssertTrue(app.elemento("linhaEstimado").waitForExistence(timeout: 5))
        XCTAssertEqual(app.elemento("linhaEstimado").value as? String, "R$\u{a0}1.600.000,00")
        XCTAssertEqual(app.elemento("linhaOrcamento").value as? String, "Opcional")
        app.buttons["salvarObra"].tap()
        let erro = app.elemento("erroDaArea")
        XCTAssertTrue(erro.waitForExistence(timeout: 5))
        XCTAssertEqual(erro.label, "Informe área construída maior que zero.")
        app.digitarComFoco("280", em: app.textFields["areaDaObra"])
        XCTAssertTrue(erro.waitForNonExistence(timeout: 3), "o erro some ao digitar")
        app.buttons["salvarObra"].tap()
        let titulo = app.elemento("tituloDaObra")
        XCTAssertTrue(titulo.waitForExistence(timeout: 8), "\"Criar obra\" entra direto na obra nova")
        XCTAssertEqual(titulo.label, "Casa Granja Viana 2")
        XCTAssertTrue(app.elemento("obraSemGastos").exists)
        XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.600.000,00"))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["4 obras"].waitForExistence(timeout: 5), "a obra nova está na lista")
    }

    func testNomeVazioVoltaAoNomeSemMensagem() {
        let app = abrirApp(conta: "senha", dados: "vitrine", folha: "novaObra")
        XCTAssertTrue(app.textFields["nomeDaObra"].waitForExistence(timeout: 10))
        app.buttons["salvarObra"].tap()
        XCTAssertFalse(app.elemento("erroDoNome").exists, "sem mensagem, como o site")
        XCTAssertTrue(app.textFields["nomeDaObra"].exists, "a folha continua aberta")
    }

    func testDescartarObraPreenchidaPergunta() {
        let app = abrirApp(conta: "senha", dados: "vitrine", folha: "novaObra")
        app.digitarComFoco("Casa", em: app.textFields["nomeDaObra"])
        app.buttons["fecharFolha"].tap()
        let alerta = app.alerts["Você já preencheu esta obra."]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Continuar editando"].tap()
        XCTAssertTrue(app.textFields["nomeDaObra"].exists)
        app.buttons["fecharFolha"].tap()
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        alerta.buttons["Descartar obra"].tap()
        XCTAssertTrue(app.textFields["nomeDaObra"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["3 obras"].exists, "nada foi gravado")
    }

    func testLimiteDe300ObrasAvisaAntesDeAbrir() {
        let app = abrirApp(conta: "senha", dados: "limite")
        XCTAssertTrue(app.elemento("obra-t1").waitForExistence(timeout: 10))
        app.buttons["botaoMais"].tap()
        let alerta = app.alerts["Limite de 300 obras"]
        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
        XCTAssertTrue(alerta.staticTexts["Apague uma obra antiga para criar outra."].exists)
        alerta.buttons["OK"].tap()
        XCTAssertTrue(alerta.waitForNonExistence(timeout: 5))
        XCTAssertFalse(app.textFields["nomeDaObra"].exists, "\"Nova obra\" não abre")
    }
}
```


- [ ] **Step 2: Ver falhar**

Run: `xcodebuild build-for-testing` e `-only-testing:CusttaUITests/FolhaDaObraUITests -only-testing:CusttaUITests/EstadosUITests`.
Expected: `testCriarObraComOErroDaAreaEEntrarNela` falha (o + da lista não existe).

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Estado/Folhas.swift`:

```diff
--- a/app-ios/Custta/Estado/Folhas.swift
+++ b/app-ios/Custta/Estado/Folhas.swift
@@ -1,14 +1,17 @@
 import Foundation
 import Observation
 
-/* A folha aberta por cima das abas (o + da cápsula, o toque numa linha de gasto) e o que a tela da obra faz quando ela
-   termina de descer: rolar até o gasto que acabou de entrar e acendê-lo, ou apagar com a animação à vista. Mora acima
-   das abas, como o caminho de Obras, porque o + é da cápsula. */
+/* A folha aberta por cima das abas (o + da cápsula, o toque numa linha de gasto, o lápis e as ações da obra) e o que as
+   telas fazem quando ela termina de descer: rolar até o gasto que acabou de entrar e acendê-lo, apagar com a animação à
+   vista, entrar na obra criada ou voltar à lista e apagar a obra. Mora acima das abas, como o caminho de Obras, porque o
+   + é da cápsula. */
 @MainActor @Observable
 final class Folhas {
     enum Qual: Identifiable, Hashable {
         case novoGasto(obraId: String)
         case editarGasto(obraId: String, gastoId: String)
+        case novaObra
+        case editarObra(obraId: String)
         case venda(obraId: String)
 
         var id: Self { self }
@@ -31,9 +34,26 @@ final class Folhas {
         var vez = 0
     }
 
+    /// Para onde Obras vai por causa de uma folha.
+    enum Navegacao: Equatable {
+        /// Entra na obra (a que acabou de ser criada), com o push do sistema, depois que a folha desce.
+        case entrar(String)
+        /// Troca a obra aberta sem animação, por trás da folha: o gasto lançado de dentro de uma vendida foi para outra, e
+        /// a folha desce mostrando a obra que o recebeu.
+        case trocar(String)
+        /// Volta à lista e só então apaga a obra, para a linha sair com a animação à vista.
+        case apagar(String)
+    }
+
+    struct PedidoDeNavegacao: Equatable {
+        let navegacao: Navegacao
+        let vez: Int
+    }
+
     var aberta: Qual?
     private(set) var destaque: Destaque?
     private(set) var pedidoDeApagar: PedidoDeApagar?
+    private(set) var navegacao: PedidoDeNavegacao?
     @ObservationIgnored private var depoisDeFechar: (() -> Void)?
     @ObservationIgnored private var vezes = 0
 
@@ -61,4 +81,9 @@ final class Folhas {
         p.vez = vezes
         pedidoDeApagar = p
     }
+
+    func navegar(_ n: Navegacao) {
+        vezes += 1
+        navegacao = PedidoDeNavegacao(navegacao: n, vez: vezes)
+    }
 }
```

Em `app-ios/Custta/Falsos/MontarFalso.swift`:

```diff
--- a/app-ios/Custta/Falsos/MontarFalso.swift
+++ b/app-ios/Custta/Falsos/MontarFalso.swift
@@ -6,9 +6,10 @@ import CusttaNucleo
    Variáveis que o teste passa ao abrir o app:
    CUSTTA_CONTA   conta inicial da ContaFalsa (nenhuma, senha, senha-nao-confirmada, apple-sem-perfil,
                   google-sem-perfil, google-perfil-concorrente)
-   CUSTTA_DADOS   vitrine (padrão: as obras do mockup) | exemplo (as dos testes) | vazio
+   CUSTTA_DADOS   vitrine (padrão: as obras do mockup) | exemplo (as dos testes) | vazio | limite (as 300 obras do teto)
    CUSTTA_REDE    offline (abre "em modo avião": dados do cache e indicador "Sem conexão")
-   CUSTTA_LEITURA erro (a escuta falha com permission-denied) | formato (documento que o app não lê)
+   CUSTTA_LEITURA erro (a escuta falha com permission-denied) | formato (documento que o app não lê) | nunca (a escuta
+                  não responde: "Carregando suas obras…")
    CUSTTA_GRAVACAO recusa (toda gravação volta com permission-denied: o "Não salvou" que não passa sozinho)
    CUSTTA_APAGAR_REMOTO <obra>/<gasto>@<segundos> (outro aparelho apaga o gasto, com o app aberto)
    CUSTTA_MARCA   servidor (o servidor já respondeu a esta conta numa abertura anterior: com CUSTTA_REDE=offline e
@@ -29,6 +30,7 @@ extension Composicao {
         let dados: ValorJSON? = switch ambiente["CUSTTA_DADOS"] {
         case "vazio": nil
         case "exemplo": DadosDeExemplo.blob
+        case "limite": DadosDeExemplo.noTeto()
         default: DadosDeExemplo.vitrine()
         }
         // CUSTTA_APAGAR_REMOTO=<obra>/<gasto>@<segundos>: outro aparelho apaga um gasto com o app aberto.
@@ -38,6 +40,7 @@ extension Composicao {
             return (partes[0], partes[1], segundos)
         }
         let transporte = TransporteFalsoApp(dados: dados, semRede: semRede, falhaDeLeitura: falha,
+                                            semLeitura: ambiente["CUSTTA_LEITURA"] == "nunca",
                                             recusa: ambiente["CUSTTA_GRAVACAO"] == "recusa" ? "permission-denied" : nil,
                                             apagarRemoto: remoto)
         let rede = MonitorDeRede(forcarSemRede: semRede)
```

Em `app-ios/Custta/Falsos/TransporteFalsoApp.swift`:

```diff
--- a/app-ios/Custta/Falsos/TransporteFalsoApp.swift
+++ b/app-ios/Custta/Falsos/TransporteFalsoApp.swift
@@ -4,8 +4,9 @@ import CusttaNucleo
 
 /// Transporte falso dos testes (só Debug): entrega um blob fixo e confirma gravações depois de
 /// 300 ms (nunca, sem rede). `falhaDeLeitura` faz a escuta falhar com esse código antes do primeiro
-/// snapshot (CUSTTA_LEITURA=erro: permission-denied; formato: formato-desconhecido). `recusa` responde toda gravação
-/// com esse código (CUSTTA_GRAVACAO=recusa: permission-denied, o "Não salvou" que não passa sozinho). `apagarRemoto`
+/// snapshot (CUSTTA_LEITURA=erro: permission-denied; formato: formato-desconhecido); `semLeitura`, a escuta
+/// nunca responde (CUSTTA_LEITURA=nunca: "Carregando suas obras…" para sempre). `recusa` responde toda gravação com
+/// esse código (CUSTTA_GRAVACAO=recusa: permission-denied, o "Não salvou" que não passa sozinho). `apagarRemoto`
 /// simula outro aparelho apagando um gasto: um segundo snapshot, sem ele, depois de alguns segundos
 /// (CUSTTA_APAGAR_REMOTO=<obra>/<gasto>@<segundos>).
 @MainActor
@@ -14,16 +15,18 @@ final class TransporteFalsoApp: TransporteDados {
     private let dados: ValorJSON?
     private let semRede: Bool
     private let falhaDeLeitura: String?
+    private let semLeitura: Bool
     private let recusa: String?
     private let apagarRemoto: (obra: String, gasto: String, depois: Double)?
     /// Quantas gravações chegaram (os testes conferem que abrir o app não grava nada).
     private(set) var gravacoes = 0
 
-    init(dados: ValorJSON?, semRede: Bool, falhaDeLeitura: String? = nil, recusa: String? = nil,
+    init(dados: ValorJSON?, semRede: Bool, falhaDeLeitura: String? = nil, semLeitura: Bool = false, recusa: String? = nil,
          apagarRemoto: (obra: String, gasto: String, depois: Double)? = nil) {
         self.dados = dados
         self.semRede = semRede
         self.falhaDeLeitura = falhaDeLeitura
+        self.semLeitura = semLeitura
         self.recusa = recusa
         self.apagarRemoto = apagarRemoto
     }
@@ -31,6 +34,7 @@ final class TransporteFalsoApp: TransporteDados {
     func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                  aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel {
         let dados = self.dados, semRede = self.semRede, falha = falhaDeLeitura, remoto = apagarRemoto
+        guard !semLeitura else { return Nada() }
         Task { @MainActor in
             try? await Task.sleep(for: .milliseconds(200))
             if let falha { aoFalhar(falha); return }
```

Em `app-ios/Custta/Falsos/VitrineDaObra.swift`:

```diff
--- a/app-ios/Custta/Falsos/VitrineDaObra.swift
+++ b/app-ios/Custta/Falsos/VitrineDaObra.swift
@@ -79,4 +79,17 @@ extension DadosDeExemplo {
         })
     }
 }
+
+extension DadosDeExemplo {
+    /// O teto das rules: 300 obras ("Obra 1" a "Obra 300"), para o aviso de "Nova obra".
+    static func noTeto() -> ValorJSON {
+        .objeto([
+            "obras": .lista((1...limiteDeObras).map { i in
+                .objeto(["id": .texto("t\(i)"), "nome": .texto("Obra \(i)"), "dataInicio": .texto("2026-01-01"), "fase": .texto("construcao"),
+                         "gastos": .lista([])])
+            }),
+            "config": .objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([])]),
+        ])
+    }
+}
 #endif
```

Em `app-ios/Custta/Identidade/PecasDaFolha.swift`:

```diff
--- a/app-ios/Custta/Identidade/PecasDaFolha.swift
+++ b/app-ios/Custta/Identidade/PecasDaFolha.swift
@@ -62,6 +62,28 @@ struct LinhaDaFolhaComRotulo<Valor: View>: View {
     }
 }
 
+/// Um campo de texto com o rótulo em cima, dentro de um grupo ("Nome da obra", "Área construída em m²"), como a
+/// descrição do gasto: rótulo em 13 semibold secundário (no erro, na cor do erro) e o campo embaixo.
+struct CampoComRotuloEmCima<Campo: View>: View {
+    let rotulo: String
+    var erro = false
+    @ViewBuilder let campo: () -> Campo
+    @Environment(\.paleta) private var paleta
+
+    var body: some View {
+        VStack(alignment: .leading, spacing: 2) {
+            Text(rotulo)
+                .font(.footnote.weight(.semibold))
+                .foregroundStyle(paleta.cor(erro ? .erroNoVidro : .secundarioSolido))
+                .accessibilityHidden(true)
+            campo()
+        }
+        .padding(.horizontal, 16)
+        .padding(.vertical, 11)
+        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
+    }
+}
+
 /// Uma linha de dinheiro que abre o teclado de valor ("Valor estimado de venda", "Orçamento total", "Valor da venda"):
 /// "R$" e o valor, ou "Opcional" vazia, e a seta.
 struct LinhaDeDinheiro: View {
```

Em `app-ios/Custta/Identidade/TecladoDeValor.swift`:

```diff
--- a/app-ios/Custta/Identidade/TecladoDeValor.swift
+++ b/app-ios/Custta/Identidade/TecladoDeValor.swift
@@ -4,10 +4,12 @@ import CusttaNucleo
 /* O teclado de valor (teclado.js, mockup da etapa 2, parte 2): centavos entram pela direita, "00" e apagar, teto de
    R$ 99.999.999,99 (a tecla que passaria do teto é ignorada). As teclas vêm na ordem do telefone, 1 2 3 em cima
    (sugestão aprovada; o site usa a da calculadora). Serve ao gasto, à venda, ao valor estimado e ao orçamento: quem usa
-   dá o rótulo do botão ("Avançar", "Pronto") e o que fazer com o valor. O botão fica desabilitado no zero, como no site. */
+   dá o rótulo do botão ("Avançar", "Pronto") e o que fazer com o valor. O botão fica desabilitado no zero, como no site;
+   nos valores opcionais da obra (valor estimado e orçamento), zero vale: é como apagar o valor. */
 struct TecladoDeValor: View {
     @Binding var centavos: Int
     let acao: String
+    var permiteZero = false
     let confirmar: () -> Void
     @Environment(\.paleta) private var paleta
 
@@ -37,7 +39,7 @@ struct TecladoDeValor: View {
             }
             Button(acao, action: confirmar)
                 .buttonStyle(BotaoDaFolha())
-                .disabled(centavos == 0)
+                .disabled(centavos == 0 && !permiteZero)
                 .padding(.top, 14)
                 .accessibilityIdentifier("confirmarValor")
         }
```

Criar `app-ios/Custta/Telas/FolhaDaObra.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* A folha da obra (mockup da etapa 2, parte 3; formNovaObra e formEditarObra do site). Nova: o + da lista abre com o
   cursor no nome e o teclado aberto; os campos do site, agrupados como no mockup (nome e início; a área, obrigatória;
   valor estimado e orçamento, opcionais, no teclado de valor); "Criar obra" entra direto na obra nova. Editar: o lápis da
   barra da obra; os mesmos campos menos o orçamento, a área opcional e "Apagar obra" no fim (o alerta com o nome e os
   lançamentos; depois, a lista, e a linha sai com a animação). O que vai para o documento e as mensagens vêm do núcleo. */

enum PassoDaObra: Hashable {
    case estimado
    case orcamento
}

/// O formulário enquanto a folha está aberta; só vira obra no "Criar obra" ou no "Salvar".
@MainActor @Observable
final class RascunhoDaObra {
    /// nil: obra nova.
    let obraId: String?
    var nome: String
    var dataInicio: String
    var area: String
    var estimado: Int
    var orcamento = 0
    private var inicial: [String] = []

    init(obra: Obra?, hoje: String) {
        obraId = obra?.id
        nome = obra?.nome ?? ""
        dataInicio = obra?.dataInicio ?? hoje
        area = areaParaCampo(obra?.areaM2)
        estimado = obra?.valorEstimadoVenda.map(reaisParaCentavos) ?? 0
        inicial = foto
    }

    var nova: Bool { obraId == nil }

    /// O que a pessoa respondeu, lido como o site lê (nome aparado, área pelo parseNum, dinheiro em reais).
    var campos: CamposDaObra {
        CamposDaObra(nome: aparadoJS(nome), dataInicio: dataInicio, valorEstimadoVenda: centavosParaReais(estimado),
                     areaM2: lerNumero(area), orcamento: centavosParaReais(orcamento))
    }

    /// Fechar pergunta antes quando algo mudou desde que a folha abriu.
    var temOQuePerder: Bool { foto != inicial }

    private var foto: [String] { [nome, dataInicio, area, String(estimado), String(orcamento)] }

    /// O nome tem até 120 unidades UTF-16, como o `maxlength` do site.
    func limitarNome() {
        guard nome.utf16.count > Limites.nome else { return }
        var r = ""
        for c in nome where r.utf16.count + String(c).utf16.count <= Limites.nome { r.append(c) }
        nome = r
    }
}

struct FolhaDaObra: View {
    /// nil: obra nova.
    let obraId: String?
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @State private var rascunho: RascunhoDaObra?
    @State private var caminho: [PassoDaObra] = []

    var body: some View {
        Group {
            if let rascunho {
                FolhaDaObraAberta(rascunho: rascunho, caminho: $caminho)
            } else {
                Color.clear
            }
        }
        .onAppear(perform: montar)
        // A obra sumiu (apagada em outro aparelho) com a folha de edição aberta: não há o que editar; a folha fecha.
        .onChange(of: existe) { _, agora in if !agora { folhas.fechar() } }
    }

    private var existe: Bool { obraId.map { id in modelo.sincronizador.estado.obras.contains { $0.id == id } } ?? true }

    private func montar() {
        guard rascunho == nil else { return }
        let obra = obraId.flatMap { id in modelo.sincronizador.estado.obras.first { $0.id == id } }
        if obraId != nil && obra == nil { folhas.fechar(); return }
        rascunho = RascunhoDaObra(obra: obra, hoje: dataLocalISO(.now, fuso: .current))
        #if DEBUG
        // Conferência visual e laudo: a obra nova já preenchida (`-custta.folha preenchida`), como o nova-1 do mockup.
        if obra == nil, UserDefaults.standard.string(forKey: "custta.folha") == "preenchida" {
            rascunho?.nome = "Casa Granja Viana 2"
            rascunho?.dataInicio = "2026-10-01"
            rascunho?.area = "280"
            rascunho?.estimado = 160_000_000
        }
        #endif
    }
}

private struct FolhaDaObraAberta: View {
    @Bindable var rascunho: RascunhoDaObra
    @Binding var caminho: [PassoDaObra]
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas

    private var nome: String {
        rascunho.obraId.flatMap { id in modelo.sincronizador.estado.obras.first { $0.id == id }?.nome } ?? ""
    }

    var body: some View {
        NavigationStack(path: $caminho) {
            FormularioDaObra(rascunho: rascunho, caminho: $caminho, subtitulo: rascunho.nova ? nil : nome)
                .navigationDestination(for: PassoDaObra.self) { passo in
                    switch passo {
                    case .estimado:
                        TecladoDeValor(centavos: $rascunho.estimado, acao: "Pronto", permiteZero: true) { caminho.removeLast() }
                            .passoDaFolha("Valor estimado de venda", subtitulo: rascunho.nova ? "Nova obra" : nome, fechar: nil)
                    case .orcamento:
                        TecladoDeValor(centavos: $rascunho.orcamento, acao: "Pronto", permiteZero: true) { caminho.removeLast() }
                            .passoDaFolha("Orçamento total", subtitulo: "Nova obra", fechar: nil)
                    }
                }
        }
        .folhaDoApp(perguntar: rascunho.temOQuePerder,
                    pergunta: rascunho.nova ? "Você já preencheu esta obra." : "Você mudou esta obra.",
                    descartar: rascunho.nova ? "Descartar obra" : "Descartar alterações") {
            folhas.fechar()
        }
    }
}

/// Os campos da obra e o botão fixo embaixo.
private struct FormularioDaObra: View {
    @Bindable var rascunho: RascunhoDaObra
    @Binding var caminho: [PassoDaObra]
    let subtitulo: String?
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @Environment(\.paleta) private var paleta
    @FocusState private var foco: Campo?
    @State private var erroDoNome: String?
    @State private var erroDaArea: String?
    @State private var naoCarregado = false
    @State private var contaReal = false
    @State private var limite = false
    @State private var apagando = false
    /// O foco no nome vale só ao abrir: a raiz da pilha reaparece ao voltar do teclado de valor.
    @State private var abriu = false

    enum Campo: Hashable { case nome, area }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    GrupoDaFolha {
                        CampoComRotuloEmCima(rotulo: "Nome da obra") {
                            // Quebra linha na letra grande, como os campos da entrada ("nada corta"); o Return, que aqui
                            // viraria "\n", vai para a área.
                            TextField("Nome da obra", text: $rascunho.nome,
                                      prompt: Text("Ex: Casa Alphaville").foregroundStyle(paleta.cor(.textoTerciario)), axis: .vertical)
                                .foregroundStyle(paleta.cor(.texto))
                                .focused($foco, equals: .nome)
                                .submitLabel(.next)
                                .onChange(of: rascunho.nome) { _, novo in
                                    if novo.contains("\n") {
                                        rascunho.nome = novo.replacingOccurrences(of: "\n", with: "")
                                        foco = .area
                                    }
                                    rascunho.limitarNome()
                                    erroDoNome = nil
                                }
                                .accessibilityIdentifier("nomeDaObra")
                        }
                        SeparadorDaFolha()
                        LinhaDaFolhaComRotulo(rotulo: "Começou em") { CampoDeData(iso: $rascunho.dataInicio) }
                    }
                    if let erroDoNome { NotaDaFolha(texto: erroDoNome, cor: .erroNoVidro, identificador: "erroDoNome") }
                }
                VStack(spacing: 8) {
                    GrupoDaFolha {
                        CampoComRotuloEmCima(rotulo: rascunho.nova ? "Área construída em m²" : "Área construída em m² (opcional)",
                                             erro: erroDaArea != nil) {
                            TextField(rascunho.nova ? "Área construída em m²" : "Área construída em m², opcional", text: $rascunho.area,
                                      prompt: Text("Ex: 320").foregroundStyle(paleta.cor(.textoTerciario)))
                                .keyboardType(.decimalPad)
                                .foregroundStyle(paleta.cor(.texto))
                                .focused($foco, equals: .area)
                                .onChange(of: rascunho.area) { _, _ in erroDaArea = nil }
                                .accessibilityIdentifier("areaDaObra")
                                // "280 m²": a unidade logo depois do número (um texto invisível igual ao digitado mede onde
                                // ele termina), sem tirar a largura do campo, que continua todo tocável.
                                .overlay(alignment: .leading) {
                                    if !rascunho.area.isEmpty {
                                        HStack(spacing: 4) {
                                            Text(rascunho.area).hidden()
                                            Text("m²").foregroundStyle(paleta.cor(.texto))
                                        }
                                        .allowsHitTesting(false)
                                        .accessibilityHidden(true)
                                    }
                                }
                        }
                    }
                    if let erroDaArea { NotaDaFolha(texto: erroDaArea, cor: .erroNoVidro, identificador: "erroDaArea") }
                }
                VStack(spacing: 8) {
                    GrupoDaFolha {
                        LinhaDeDinheiro(rotulo: "Valor estimado de venda", centavos: rascunho.estimado, identificador: "linhaEstimado") {
                            foco = nil
                            caminho.append(.estimado)
                        }
                        if rascunho.nova {
                            SeparadorDaFolha()
                            LinhaDeDinheiro(rotulo: "Orçamento total", centavos: rascunho.orcamento, identificador: "linhaOrcamento") {
                                foco = nil
                                caminho.append(.orcamento)
                            }
                        }
                    }
                    if rascunho.nova { NotaDaFolha(texto: "Os dois são opcionais e podem ser informados depois.") }
                }
                if !rascunho.nova {
                    GrupoDaFolha {
                        Button("Apagar obra") { foco = nil; apagando = true }
                            .foregroundStyle(paleta.cor(.erroNoVidro))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .accessibilityIdentifier("apagarObra")
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // O identificador no próprio botão (o fundo desce até a borda, atrás do teclado; ver a folha do gasto).
            Button(rascunho.nova ? "Criar obra" : "Salvar", action: salvar)
                .buttonStyle(BotaoDaFolha())
                .accessibilityIdentifier("salvarObra")
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)
                .background {
                    LinearGradient(stops: [.init(color: paleta.cor(.folha), location: 0.62), .init(color: paleta.cor(.folha).opacity(0), location: 1)],
                                   startPoint: .bottom, endPoint: .top)
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                }
        }
        .passoDaFolha(rascunho.nova ? "Nova obra" : "Editar obra", subtitulo: subtitulo, fechar: .esquerda, raiz: true)
        // Obra nova: o cursor no nome e o teclado aberto (sugestão aprovada; o site só faz isso no computador).
        .onAppear {
            guard !abriu else { return }
            abriu = true
            if rascunho.nova && rascunho.nome.isEmpty { foco = .nome }
        }
        .background {
            Color.clear
                .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("A obra continua aqui; nada foi salvo ainda.")
                }
                .tint(paleta.cor(.texto))
        }
        .background {
            Color.clear
                .alert(avisoLimiteDeObras(limiteDeObras)?.titulo ?? "", isPresented: $limite) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(avisoLimiteDeObras(limiteDeObras)?.texto ?? "")
                }
                .tint(paleta.cor(.texto))
        }
        .modifier(PerguntaDeApagarObra(apresentada: $apagando, obraId: rascunho.obraId) {
            guard let id = rascunho.obraId else { return }
            folhas.fechar { folhas.navegar(.apagar(id)) }
        })
        .alert(ContaDeTeste.titulo, isPresented: $contaReal) { Button("OK", role: .cancel) {} } message: { Text(ContaDeTeste.mensagem) }
        .pausaOFundo(enquanto: naoCarregado || limite || contaReal)
    }

    private func salvar() {
        foco = nil
        let campos = rascunho.campos
        if let erro = conferirObra(campos, nova: rascunho.nova) {
            // Nome vazio volta ao nome sem mensagem, como o site; a área, com o erro do site embaixo e o rótulo em vermelho.
            if erro.campo == "area" { erroDaArea = erro.mensagem; foco = .area } else { erroDoNome = erro.mensagem; foco = .nome }
            if let m = erro.mensagem { AccessibilityNotification.Announcement(m).post() }
            return
        }
        guard let id = rascunho.obraId else { criar(campos); return }
        switch modelo.gravar({ $0.editandoObra(id, campos) }) {
        case .gravou, .sumiu, .semConta: folhas.fechar()
        case .naoCarregado: naoCarregado = true
        case .contaReal: contaReal = true
        }
    }

    private func criar(_ campos: CamposDaObra) {
        // O teto pode ter enchido com a folha aberta (outro aparelho): avisa em vez de criar a 301ª.
        if avisoLimiteDeObras(modelo.sincronizador.estado.obras.count) != nil { limite = true; return }
        let id = gerarId()
        switch modelo.gravar({ $0.criandoObra(obraNova(campos, id: id, hoje: dataLocalISO(.now, fuso: .current))) }) {
        case .gravou: folhas.fechar { folhas.navegar(.entrar(id)) }
        case .naoCarregado: naoCarregado = true
        case .contaReal: contaReal = true
        case .sumiu: limite = true
        case .semConta: folhas.fechar()
        }
    }
}

/// "Apagar “Casa Alphaville”?" com os lançamentos que se perdem, pelo alerta do sistema (num fundo vazio, com os botões
/// na cor do texto, como o apagar gasto).
struct PerguntaDeApagarObra: ViewModifier {
    @Binding var apresentada: Bool
    let obraId: String?
    let confirmar: () -> Void
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    func body(content: Content) -> some View {
        let obra = obraId.flatMap { id in modelo.sincronizador.estado.obras.first { $0.id == id } }
        let texto = textoDeApagarObra(nome: obra?.nome ?? "", lancamentos: obra?.gastos.count ?? 0)
        content
            .background {
                Color.clear
                    .alert(texto.titulo, isPresented: $apresentada) {
                        Button("Cancelar", role: .cancel) {}
                        Button("Apagar obra", role: .destructive, action: confirmar)
                    } message: { Text(texto.mensagem) }
                    .tint(paleta.cor(.texto))
            }
            .pausaOFundo(enquanto: apresentada)
    }
}
```

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -76,8 +76,8 @@ struct ObraView: View {
                     PilulaDeLancamentos(quantidade: obra.gastos.count)
                         .accessibilityFocused($foco, equals: .lancamentos)
                     if obra.gastos.isEmpty {
-                        CartaoDeEstado(titulo: "Nenhum gasto lançado.", texto: "Toque no + para lançar o primeiro.",
-                                       identificador: "obraSemGastos", icone: "Icones/notas") { EmptyView() }
+                        CartaoDeEstado(titulo: "Nenhum gasto lançado.", texto: "Toque no + para lançar o primeiro.", icone: "Icones/notas",
+                                       identificador: "obraSemGastos") { EmptyView() }
                     } else {
                         if let aVencer = lista.aVencer {
                             CartaoDoAVencer(grupo: aVencer, aberto: $aVencerAberto, topicos: topicos, lista: acoes)
```

Em `app-ios/Custta/Telas/ObrasView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObrasView.swift
+++ b/app-ios/Custta/Telas/ObrasView.swift
@@ -8,7 +8,8 @@ enum RotaDeObras: Hashable, Sendable {
 
 /* Obras: aviso de e-mail não confirmado, "N obras", um cartão de vidro por obra (fase, meses, orçamento e total
    gasto, na ordem e com os totais do site), que abre a obra, e o comparativo entre obras. Antes de carregar:
-   carregando, ou o erro de leitura explicando que nada foi alterado. */
+   carregando, ou o erro de leitura explicando que nada foi alterado. Sem obras, o convite para o + (que cria a obra).
+   A obra apagada sai da lista com a animação do apagar gasto. */
 struct ObrasView: View {
     @Binding var caminho: [RotaDeObras]
     @Environment(ModeloApp.self) private var modelo
@@ -38,13 +39,12 @@ struct ObrasView: View {
                                 .accessibilityIdentifier("tentarLerDeNovo")
                         }
                     } else if !sinc.dadosCarregados {
-                        CartaoDeEstado(titulo: "Carregando suas obras…", texto: nil, identificador: "obrasCarregando") {
-                            ProgressView()
-                        }
+                        CartaoDeEstado(titulo: "Carregando suas obras…", texto: nil, icone: nil, carregando: true,
+                                       identificador: "obrasCarregando") { EmptyView() }
                     } else if obras.isEmpty {
-                        CartaoDeEstado(titulo: "Nenhuma obra ainda.",
-                                       texto: "Nesta versão de teste, crie as obras pelo site. Elas aparecem aqui sozinhas.",
-                                       identificador: "obrasVazio") { EmptyView() }
+                        CartaoDeEstado(titulo: listaDeObrasVazia.titulo, texto: listaDeObrasVazia.texto, identificador: "obrasVazio") {
+                            EmptyView()
+                        }
                     } else {
                         ContagemDeObras(quantidade: obras.count)
                         ForEach(obras, id: \.id) { obra in
@@ -305,25 +305,34 @@ struct AvisoDeEmail: View {
     }
 }
 
-/// Cartão de estado da lista (vazia, carregando, erro de leitura): ícone, título, texto e ação.
+/// Cartão de estado (lista vazia, carregando, erro de leitura, obra sem gastos), o "Estado vazio" do mockup da etapa 2:
+/// ícone de 52 num quadrado de raio 16 (ou, carregando, só o indicador), título em .body semibold, texto em .subheadline
+/// secundário e a ação.
 struct CartaoDeEstado<Acao: View>: View {
     let titulo: String
     let texto: String?
+    var icone: String? = "Icones/guindaste"
+    var carregando = false
     let identificador: String
-    /// O ícone do alto: o guindaste nas Obras; as notas na obra sem gastos (mockup da etapa 2).
-    var icone = "Icones/guindaste"
     @ViewBuilder let acao: () -> Acao
     @Environment(\.paleta) private var paleta
     @Environment(\.vidro) private var vidro
 
     var body: some View {
         VStack(spacing: 8) {
-            Image(decorative: icone)
-                .resizable().frame(width: 36, height: 36)
-                .foregroundStyle(paleta.cor(.texto))
-                .accessibilityHidden(true)
+            if carregando {
+                ProgressView().padding(.bottom, 4)
+            } else if let icone {
+                Image(decorative: icone)
+                    .resizable().frame(width: 26, height: 26)
+                    .foregroundStyle(paleta.cor(.marca))
+                    .frame(width: 52, height: 52)
+                    .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 16, style: .continuous))
+                    .accessibilityHidden(true)
+                    .padding(.bottom, 6)
+            }
             Text(titulo)
-                .font(.body.weight(.semibold))
+                .font(carregando ? .body : .body.weight(.semibold))
                 .foregroundStyle(paleta.cor(.texto))
                 .accessibilityIdentifier(identificador)
             if let texto {
@@ -332,7 +341,7 @@ struct CartaoDeEstado<Acao: View>: View {
             acao().padding(.top, 4)
         }
         .multilineTextAlignment(.center)
-        .padding(.horizontal, 20)
+        .padding(.horizontal, 22)
         .padding(.vertical, 28)
         .frame(maxWidth: .infinity)
         .superficie(.conteudo, em: .rect(cornerRadius: 22))
```

Em `app-ios/Custta/Telas/PrincipalView.swift`:

```diff
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -11,7 +11,11 @@ struct PrincipalView: View {
     @State private var aba = Aba.obras
     @State private var caminhoDeObras = PrincipalView.caminhoInicial
     @State private var folhas = Folhas()
+    /// O + da lista avisou em vez de abrir "Nova obra": o teto de obras ou os dados ainda não vistos.
+    @State private var avisoDoMais: AvisoDoMais?
     @Environment(ModeloApp.self) private var modelo
+    @Environment(\.opcoes) private var opcoes
+    @Environment(\.paleta) private var paleta
 
     var body: some View {
         Group {
@@ -28,6 +32,8 @@ struct PrincipalView: View {
                 switch qual {
                 case .novoGasto(let obraId): FolhaDoGasto(obraId: obraId, gastoId: nil)
                 case .editarGasto(let obraId, let gastoId): FolhaDoGasto(obraId: obraId, gastoId: gastoId)
+                case .novaObra: FolhaDaObra(obraId: nil)
+                case .editarObra(let obraId): FolhaDaObra(obraId: obraId)
                 case .venda(let obraId): FolhaDaVenda(obraId: obraId)
                 }
             }
@@ -35,7 +41,8 @@ struct PrincipalView: View {
         }
         // Com a folha aberta o fundo para: ela cobre quase tudo, e cada quadro da aurora refaria o desfoque dela.
         .pausaOFundo(enquanto: folhas.aberta != nil)
-        .modifier(AvisosDoPrincipal(folhaAberta: folhas.aberta != nil))
+        .onChange(of: folhas.navegacao) { _, pedido in if let pedido { navegar(pedido.navegacao) } }
+        .modifier(AvisosDoPrincipal(avisoDoMais: $avisoDoMais, folhaAberta: folhas.aberta != nil))
         #if DEBUG
         .task { await abrirFolhaDoGancho() }
         // Teste de tela: quantas pontes de fechamento estão vivas (abrir e fechar a folha não pode deixar nenhuma).
@@ -55,17 +62,52 @@ struct PrincipalView: View {
 }
 
 extension PrincipalView {
-    /// O + da cápsula: dentro de uma obra que ainda recebe gasto, lança gasto nela. Obra vendida não recebe gasto novo
-    /// (como no site); a escolha de outra obra chega no PR 3, junto com "Nova obra" na lista.
+    /// O + da cápsula, como o do site: na lista, "Nova obra"; dentro de uma obra que ainda recebe gasto, lança gasto nela.
+    /// Obra vendida não recebe gasto novo (como no site); a escolha de outra obra chega na Tarefa 34. Em Ajustes, some.
     private var acaoDoMais: AcaoDoMais? {
-        guard aba == .obras, case .obra(let id)? = caminhoDeObras.last,
-              let obra = modelo.sincronizador.estado.obras.first(where: { $0.id == id }), obra.fase != .vendida else { return nil }
+        guard aba == .obras else { return nil }
+        let obras = modelo.sincronizador.estado.obras
+        guard case .obra(let id)? = caminhoDeObras.last else { return AcaoDoMais(rotulo: "Nova obra", acao: pedirNovaObra) }
+        guard let obra = obras.first(where: { $0.id == id }) else { return nil }
+        guard obra.fase != .vendida else { return nil }
         return AcaoDoMais(rotulo: "Lançar gasto") { folhas.aberta = .novoGasto(obraId: id) }
     }
 
+    /// "Nova obra" avisa antes de abrir: sem os dados vistos, o "Carregando suas obras" do site; com o teto cheio, o
+    /// "Limite de 300 obras" (a obra a mais faria toda gravação seguinte ser recusada).
+    private func pedirNovaObra() {
+        let sinc = modelo.sincronizador
+        if !sinc.dadosCarregados { avisoDoMais = .naoCarregado(modelo.mensagemDeNaoCarregado); return }
+        if let aviso = avisoLimiteDeObras(sinc.estado.obras.count) { avisoDoMais = .limite(aviso); return }
+        folhas.aberta = .novaObra
+    }
+
+    /// O que uma folha pediu para Obras depois de gravar.
+    private func navegar(_ n: Folhas.Navegacao) {
+        switch n {
+        case .entrar(let id):
+            aba = .obras
+            caminhoDeObras = [.obra(id)]
+        case .trocar(let id):
+            var semAnimacao = Transaction()
+            semAnimacao.disablesAnimations = true
+            withTransaction(semAnimacao) { caminhoDeObras = [.obra(id)] }
+        case .apagar(let id):
+            caminhoDeObras.removeAll()
+            // Depois do voltar do sistema, a linha sai da lista com a animação do apagar gasto.
+            Task { @MainActor in
+                try? await Task.sleep(for: .milliseconds(opcoes.reduzirMovimento ? 100 : 500))
+                let resultado = withAnimation(opcoes.reduzirMovimento ? nil : .snappy(duration: 0.35)) {
+                    modelo.gravar { $0.apagandoObra(id) }
+                }
+                if resultado == .naoCarregado { avisoDoMais = .naoCarregado(modelo.mensagemDeNaoCarregado) }
+            }
+        }
+    }
+
     #if DEBUG
-    /// Testes de tela, laudo e conferência visual: `CUSTTA_FOLHA` abre uma folha quando os dados chegam (`venda:<id>`,
-    /// `novoGasto:<id>`). Sem ele, com `CUSTTA_ABRIR=obra:<id>`,
+    /// Testes de tela, laudo e conferência visual: `CUSTTA_FOLHA` abre uma folha quando os dados chegam (`novaObra`,
+    /// `editarObra:<id>`, `venda:<id>`, `novoGasto:<id>`). Sem ele, com `CUSTTA_ABRIR=obra:<id>`,
     /// `-custta.folha <passo>` abre a folha do gasto novo já no passo (valor, detalhes, cartao, topicos, repetido) e
     /// `-custta.folha editar:<gasto>`, a edição.
     private func abrirFolhaDoGancho() async {
@@ -78,6 +120,8 @@ extension PrincipalView {
             let partes = pedido.split(separator: ":", maxSplits: 1).map(String.init)
             let id = partes.count > 1 ? partes[1] : ""
             switch partes[0] {
+            case "novaObra": folhas.aberta = .novaObra
+            case "editarObra": folhas.aberta = .editarObra(obraId: id)
             case "venda": folhas.aberta = .venda(obraId: id)
             case "novoGasto": folhas.aberta = .novoGasto(obraId: id)
             default: break
@@ -101,9 +145,28 @@ extension PrincipalView {
     }
 }
 
-/// O alerta do "Não salvou" (uma vez por erro, com "Tentar de novo") por cima das abas, num fundo vazio, com os botões na
-/// cor do texto, como o "Sair da conta?". Espera a folha aberta descer.
+/// O aviso do + da lista no lugar de "Nova obra".
+enum AvisoDoMais: Equatable {
+    case limite(AvisoDeLimite)
+    case naoCarregado(String)
+
+    var titulo: String {
+        switch self {
+        case .limite(let a): return a.titulo
+        case .naoCarregado(let texto): return texto
+        }
+    }
+
+    var mensagem: String? {
+        if case .limite(let a) = self { return a.texto }
+        return nil
+    }
+}
+
+/// Os alertas do app por cima das abas: o aviso do + e o "Não salvou" (uma vez por erro, com "Tentar de novo"). Cada um
+/// num fundo vazio, com os botões na cor do texto, como o "Sair da conta?". O "Não salvou" espera a folha aberta descer.
 private struct AvisosDoPrincipal: ViewModifier {
+    @Binding var avisoDoMais: AvisoDoMais?
     let folhaAberta: Bool
     @Environment(ModeloApp.self) private var modelo
     @Environment(\.paleta) private var paleta
@@ -111,6 +174,15 @@ private struct AvisosDoPrincipal: ViewModifier {
     func body(content: Content) -> some View {
         let gravacao = modelo.alertaDeGravacao
         content
+            .background {
+                Color.clear
+                    .alert(avisoDoMais?.titulo ?? "", isPresented: Binding(get: { avisoDoMais != nil }, set: { if !$0 { avisoDoMais = nil } })) {
+                        Button("OK", role: .cancel) {}
+                    } message: {
+                        if let m = avisoDoMais?.mensagem { Text(m) }
+                    }
+                    .tint(paleta.cor(.texto))
+            }
             .background {
                 Color.clear
                     .alert(gravacao?.titulo ?? "", isPresented: Binding(get: { gravacao != nil && !folhaAberta },
@@ -122,7 +194,7 @@ private struct AvisosDoPrincipal: ViewModifier {
                     }
                     .tint(paleta.cor(.texto))
             }
-            .pausaOFundo(enquanto: gravacao != nil && !folhaAberta)
+            .pausaOFundo(enquanto: avisoDoMais != nil || (gravacao != nil && !folhaAberta))
     }
 }
```


- [ ] **Step 4: Ver passar**

Run: `-only-testing:CusttaUITests/FolhaDaObraUITests -only-testing:CusttaUITests/EstadosUITests -only-testing:CusttaUITests/GastoUITests`; as guardas em Node.
Expected: 4 de `FolhaDaObraUITests`, 4 de `EstadosUITests` e os 17 de `GastoUITests` verdes; a guarda de `lineLimit` continua verde (o nome da obra quebra, não corta).

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Estado/Folhas.swift \
  app-ios/Custta/Falsos/MontarFalso.swift \
  app-ios/Custta/Falsos/TransporteFalsoApp.swift \
  app-ios/Custta/Falsos/VitrineDaObra.swift \
  app-ios/Custta/Identidade/PecasDaFolha.swift \
  app-ios/Custta/Identidade/TecladoDeValor.swift \
  app-ios/Custta/Telas/FolhaDaObra.swift \
  app-ios/Custta/Telas/ObraView.swift \
  app-ios/Custta/Telas/ObrasView.swift \
  app-ios/Custta/Telas/PrincipalView.swift \
  app-ios/CusttaUITests/EstadosUITests.swift \
  app-ios/CusttaUITests/FolhaDaObraUITests.swift
git commit -m "feat: nova obra pelo + da lista, com a lista vazia, o carregando e o aviso do limite" -m "O + da cápsula aparece na lista e abre Nova obra, com os campos na ordem do mockup e os valores no teclado de valor; salvar entra na obra criada. Antes de ver os dados o + avisa, e com 300 obras avisa o limite, como o site. A lista vazia convida para o +, o carregando mostra só o indicador e o cartão de estado ganha o desenho do mockup."
```

### Task 33: O lápis da barra abre "Editar obra" e a obra apagada sai da lista com a animação

O lápis (círculo de vidro na barra, como o sair) abre "Editar obra" preenchida, com a área com vírgula; fechar com algo mudado pergunta "Você mudou esta obra." ("Descartar alterações"). "Apagar obra" pergunta com o nome e os lançamentos; confirmado, a folha desce, a tela volta à lista pelo voltar do sistema e só então a obra é apagada, para a linha sair com a animação do apagar gasto (sem animação com Reduzir movimento).

**Files:**
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Modify: `app-ios/Custta/Telas/ObrasView.swift`
- Modify: `app-ios/Custta/Telas/PecasDaObra.swift`
- Test (alterar): `app-ios/CusttaUITests/FolhaDaObraUITests.swift`

**Interfaces:**
- Consumes: Tarefa 32.
- Produces: `BotaoDeEditarObra(editar:)` com o identificador `editarObra`; a transição da linha apagada na `ObrasView`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaUITests/FolhaDaObraUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/FolhaDaObraUITests.swift
+++ b/app-ios/CusttaUITests/FolhaDaObraUITests.swift
@@ -65,6 +65,45 @@ final class FolhaDaObraUITests: XCTestCase {
         XCTAssertTrue(app.staticTexts["3 obras"].exists, "nada foi gravado")
     }
 
+    func testEditarObraPeloLapis() {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
+        let lapis = app.buttons["editarObra"]
+        XCTAssertTrue(lapis.waitForExistence(timeout: 10))
+        lapis.tap()
+        let nome = app.textFields["nomeDaObra"]
+        XCTAssertTrue(nome.waitForExistence(timeout: 5))
+        XCTAssertEqual(nome.value as? String, "Casa Alphaville")
+        XCTAssertEqual(app.textFields["areaDaObra"].value as? String, "300")
+        XCTAssertFalse(app.elemento("linhaOrcamento").exists, "sem orçamento na edição")
+        XCTAssertFalse(app.keyboards.firstMatch.exists, "editar não abre o teclado sozinho")
+        app.elemento("linhaEstimado").tap()
+        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
+        XCTAssertEqual(app.elemento("visorDoValor").value as? String, "R$ 1.450.000,00")
+        for _ in 0..<9 { app.buttons["tecla-del"].tap() }
+        for t in ["1", "5", "0", "0", "0", "0", "0", "0", "0"] { app.buttons["tecla-\(t)"].tap() }
+        app.buttons["confirmarValor"].tap()
+        XCTAssertTrue(app.buttons["salvarObra"].waitForExistence(timeout: 5))
+        app.buttons["salvarObra"].tap()
+        XCTAssertTrue(nome.waitForNonExistence(timeout: 5), "a folha desce e a tela fica na obra")
+        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.500.000,00"), app.elemento("indicadorVenda").label)
+    }
+
+    func testApagarObraVoltaParaAListaEALinhaSai() {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
+        XCTAssertTrue(app.buttons["editarObra"].waitForExistence(timeout: 10))
+        app.buttons["editarObra"].tap()
+        let apagar = app.buttons["apagarObra"]
+        XCTAssertTrue(apagar.waitForExistence(timeout: 5))
+        apagar.tap()
+        let alerta = app.alerts["Apagar “Casa Alphaville”?"]
+        XCTAssertTrue(alerta.waitForExistence(timeout: 5))
+        XCTAssertTrue(alerta.staticTexts["Os 46 lançamentos dela serão perdidos. Não dá para desfazer."].exists)
+        alerta.buttons["Apagar obra"].tap()
+        XCTAssertTrue(app.elemento("obra-v2").waitForExistence(timeout: 5), "volta para a lista")
+        XCTAssertTrue(app.elemento("obra-v1").waitForNonExistence(timeout: 5), "a linha sai")
+        XCTAssertTrue(app.staticTexts["2 obras"].waitForExistence(timeout: 3))
+    }
+
     func testLimiteDe300ObrasAvisaAntesDeAbrir() {
         let app = abrirApp(conta: "senha", dados: "limite")
         XCTAssertTrue(app.elemento("obra-t1").waitForExistence(timeout: 10))
```


- [ ] **Step 2: Ver falhar**

Run: `xcodebuild build-for-testing` e `-only-testing:CusttaUITests/FolhaDaObraUITests`.
Expected: `testEditarObraPeloLapis` falha (`editarObra` não existe).

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -140,6 +140,8 @@ struct ObraView: View {
             ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: obra.nome) }
             ToolbarItem(placement: .topBarTrailing) { IndicadorDeSincronizacao() }
                 .sharedBackgroundVisibility(.hidden)
+            ToolbarItem(placement: .topBarTrailing) { BotaoDeEditarObra { folhas.aberta = .editarObra(obraId: obra.id) } }
+                .sharedBackgroundVisibility(.hidden)
         }
     }
 }
```

Em `app-ios/Custta/Telas/ObrasView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObrasView.swift
+++ b/app-ios/Custta/Telas/ObrasView.swift
@@ -13,6 +13,7 @@ enum RotaDeObras: Hashable, Sendable {
 struct ObrasView: View {
     @Binding var caminho: [RotaDeObras]
     @Environment(ModeloApp.self) private var modelo
+    @Environment(\.opcoes) private var opcoes
     @State private var confirmarSaida = false
     #if DEBUG
     /// Laudo de leitura (Tarefa 11): a lista parada numa rolagem dada, em pt, para dois prints iguais.
@@ -50,6 +51,8 @@ struct ObrasView: View {
                         ForEach(obras, id: \.id) { obra in
                             NavigationLink(value: RotaDeObras.obra(obra.id)) { CartaoDeObra(obra: obra, hoje: hoje) }
                                 .buttonStyle(.plain)
+                                .transition(opcoes.reduzirMovimento ? .opacity
+                                            : .asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
                         }
                         let comparativo = comparativoEntreObras(obras, taxa: sinc.estado.config.taxaMensal, hoje: hoje)
                         if !comparativo.isEmpty { PainelComparativo(linhas: comparativo).padding(.top, 2) }
```

Em `app-ios/Custta/Telas/PecasDaObra.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDaObra.swift
+++ b/app-ios/Custta/Telas/PecasDaObra.swift
@@ -424,3 +424,23 @@ struct PilulaDaAcao: ButtonStyle {
         .animation(configuration.isPressed ? .easeOut(duration: 0.1) : .spring(duration: 0.3), value: configuration.isPressed)
     }
 }
+
+/// O lápis da barra da obra: círculo de vidro com o ícone do site, como o sair do topo; abre "Editar obra".
+struct BotaoDeEditarObra: View {
+    let editar: () -> Void
+    @Environment(\.paleta) private var paleta
+
+    var body: some View {
+        Button(action: editar) {
+            Image(decorative: "Icones/lapis")
+                .resizable()
+                .frame(width: 22, height: 22)
+                .foregroundStyle(paleta.cor(.texto))
+                .frame(width: 44, height: 44)
+                .superficie(.navegacao, em: .circle)
+        }
+        .buttonStyle(.plain)
+        .accessibilityLabel("Editar obra")
+        .accessibilityIdentifier("editarObra")
+    }
+}
```


- [ ] **Step 4: Ver passar**

Run: `-only-testing:CusttaUITests/FolhaDaObraUITests -only-testing:CusttaUITests/ObraUITests`.
Expected: os 6 de `FolhaDaObraUITests` e os 7 de `ObraUITests` verdes; as guardas em Node verdes.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Telas/ObraView.swift \
  app-ios/Custta/Telas/ObrasView.swift \
  app-ios/Custta/Telas/PecasDaObra.swift \
  app-ios/CusttaUITests/FolhaDaObraUITests.swift
git commit -m "feat: o lápis da barra abre \"Editar obra\" e a obra apagada sai da lista com a animação" -m "O lápis da barra da obra, um círculo de vidro como o sair, abre a edição preenchida, com a área com vírgula e Apagar obra no fim. Apagar volta à lista pelo voltar do sistema e só então grava, para a linha sair com a animação do apagar gasto."
```

### Task 34: O + numa obra vendida lança o gasto numa obra aberta, pela linha "Obra"

Obra vendida não recebe gasto novo (como no site). O + nela abre a folha do gasto com a linha "Obra" nos detalhes, marcada na primeira obra aberta da lista, e a nota do mockup; a lista das abertas abre dentro da folha e trocar a obra troca os "Usados nesta obra" e as sugestões. Depois de salvar, a obra que recebeu o gasto toma o lugar da vendida por trás da folha, sem animação, e a folha desce mostrando o gasto aceso. Sem nenhuma obra aberta, o + cria obra. Editar um gasto da vendida continua possível, sem a linha "Obra".

**Files:**
- Modify: `app-ios/Custta/Estado/Folhas.swift`
- Modify: `app-ios/Custta/Telas/FolhaDoGasto.swift`
- Modify: `app-ios/Custta/Telas/PrincipalView.swift`
- Test (alterar): `app-ios/CusttaUITests/EstadosUITests.swift`

**Interfaces:**
- Consumes: Tarefas 22, 28 (`obrasAbertas`, `notaDaObraVendida`) e 32.
- Produces: `Folhas.Qual.gastoDeVendida(vendidaId:)`; `FolhaDoGasto(obraId:gastoId:vendida:)`, `RascunhoDoGasto.vendida` e `trocarObra(_:)`, `PassoDoGasto.obras`, `ListaDeObrasAbertas`; em Debug, `CUSTTA_FOLHA=gastoDeVendida:<id>`; os identificadores `linhaObra`, `notaObraVendida` e `obraAberta-<id>`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaUITests/EstadosUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/EstadosUITests.swift
+++ b/app-ios/CusttaUITests/EstadosUITests.swift
@@ -26,6 +26,45 @@ final class EstadosUITests: XCTestCase {
         XCTAssertFalse(app.textFields["nomeDaObra"].exists, "sem ver os dados, \"Nova obra\" não abre")
     }
 
+    func testMaisNumaObraVendidaLancaNumaAberta() {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
+        let mais = app.buttons["botaoMais"]
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
+        XCTAssertEqual(mais.label, "Lançar gasto")
+        mais.tap()
+        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
+        for t in ["1", "3", "8", "0", "0", "0"] { app.buttons["tecla-\(t)"].tap() }
+        app.buttons["confirmarValor"].tap()
+        let linha = app.elemento("linhaObra")
+        XCTAssertTrue(linha.waitForExistence(timeout: 5))
+        XCTAssertEqual(linha.value as? String, "Casa Alphaville", "vem a primeira aberta da lista de obras")
+        XCTAssertEqual(app.elemento("notaObraVendida").label, "Casa Tamboré 4 está vendida; o gasto vai para uma obra aberta.")
+        linha.tap()
+        let sobrado = app.buttons["obraAberta-v2"]
+        XCTAssertTrue(sobrado.waitForExistence(timeout: 5))
+        XCTAssertFalse(app.buttons["obraAberta-v3"].exists, "a vendida não entra na escolha")
+        sobrado.tap()
+        XCTAssertTrue(linha.waitForExistence(timeout: 5))
+        XCTAssertEqual(linha.value as? String, "Sobrado Granja Viana")
+        app.buttons["salvarGasto"].tap()
+        let titulo = app.elemento("tituloDaObra")
+        XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5))
+        XCTAssertEqual(titulo.label, "Sobrado Granja Viana", "a folha desce na obra que recebeu o gasto")
+        XCTAssertTrue(app.elemento("indicadorTotal").label.contains("6 lançamentos"), app.elemento("indicadorTotal").label)
+        app.navigationBars.buttons.firstMatch.tap()
+        XCTAssertTrue(app.elemento("obra-v3").waitForExistence(timeout: 5), "o voltar leva à lista")
+    }
+
+    func testGastoDeObraVendidaContinuaEditavel() {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
+        let gasto = app.elemento("gasto-v3g3")
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
+        app.rolarAte(gasto)
+        gasto.tap()
+        XCTAssertTrue(app.buttons["salvarGasto"].waitForExistence(timeout: 5), "abre \"Editar gasto\"")
+        XCTAssertFalse(app.elemento("linhaObra").exists, "editar não troca a obra")
+    }
+
     func testSemConexaoGravarContinua() {
         let app = abrirApp(conta: "senha", dados: "vitrine", rede: "offline", abrir: "obra:v1")
         let pilula = app.buttons["indicadorSincronizacao"]
```


- [ ] **Step 2: Ver falhar**

Run: `xcodebuild build-for-testing` e `-only-testing:CusttaUITests/EstadosUITests`.
Expected: `testMaisNumaObraVendidaLancaNumaAberta` falha (o + some na vendida).

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Estado/Folhas.swift`:

```diff
--- a/app-ios/Custta/Estado/Folhas.swift
+++ b/app-ios/Custta/Estado/Folhas.swift
@@ -10,6 +10,8 @@ final class Folhas {
     enum Qual: Identifiable, Hashable {
         case novoGasto(obraId: String)
         case editarGasto(obraId: String, gastoId: String)
+        /// O + numa obra vendida: o gasto vai para uma obra aberta, escolhida na linha "Obra" da folha.
+        case gastoDeVendida(vendidaId: String)
         case novaObra
         case editarObra(obraId: String)
         case venda(obraId: String)
```

Em `app-ios/Custta/Telas/FolhaDoGasto.swift`:

```diff
--- a/app-ios/Custta/Telas/FolhaDoGasto.swift
+++ b/app-ios/Custta/Telas/FolhaDoGasto.swift
@@ -4,24 +4,30 @@ import CusttaNucleo
 /* A folha do gasto (mockup da etapa 2, parte 2; formGasto do site). Gasto novo: o valor no teclado de valor e
    "Avançar" empurra os detalhes, na ordem do site (valor, tópico, pagamento, descrição e data), com "Salvar" fixo
    embaixo. Editar: direto nos detalhes; o valor abre o mesmo teclado ("Pronto"); numa parcela, o aviso do site no lugar
-   do pagamento; "Apagar gasto" no fim. O que vira gasto e as mensagens vêm do núcleo (as regras do dados.js); a tela só
-   guarda o rascunho e decide para onde ir. */
+   do pagamento; "Apagar gasto" no fim. Lançado de dentro de uma obra vendida (que não recebe gasto novo, como no site),
+   a folha ganha a linha "Obra" para escolher entre as abertas. O que vira gasto e as mensagens vêm do núcleo (as regras
+   do dados.js); a tela só guarda o rascunho e decide para onde ir. */
 
 enum PassoDoGasto: Hashable {
     case detalhes
     case valor
     case topicos
+    case obras
 }
 
 /// O formulário enquanto a folha está aberta: começa do gasto em edição, ou do vazio do gasto novo, e só vira gasto no
 /// "Salvar".
 @MainActor @Observable
 final class RascunhoDoGasto {
-    let obraId: String
+    /// A obra que recebe o gasto; lançado de dentro de uma vendida, a escolhida na linha "Obra".
+    private(set) var obraId: String
     let editado: Gasto?
+    /// O gasto lançado de dentro desta obra vendida (nil no caso comum).
+    let vendida: String?
     let topicos: [Topico]
-    let usados: [Topico]
-    let indice: IndiceDeSugestoes
+    private(set) var usados: [Topico]
+    private(set) var indice: IndiceDeSugestoes
+    private let todas: [Obra]
     var centavos: Int
     var topico: String
     var pagamento: String
@@ -38,9 +44,11 @@ final class RascunhoDoGasto {
     var passouDoValor = false
     private var inicial: [String] = []
 
-    init(obra: Obra, editado: Gasto?, todas: [Obra], proprios: [TopicoProprio], hoje: String) {
+    init(obra: Obra, editado: Gasto?, todas: [Obra], proprios: [TopicoProprio], hoje: String, vendida: String? = nil) {
         obraId = obra.id
         self.editado = editado
+        self.vendida = vendida
+        self.todas = todas
         topicos = topicosDoFormulario(proprios)
         usados = usadosNestaObra(obra, topicos: topicos)
         indice = IndiceDeSugestoes(todas, obraId: obra.id, ignorarId: editado?.id)
@@ -95,6 +103,14 @@ final class RascunhoDoGasto {
         [String(centavos), topico, pagamento, String(parcelas), juros, descricao, datas["pix"] ?? "", datas["cartao"] ?? ""]
     }
 
+    /// Outra obra na linha "Obra": os "Usados nesta obra" e as sugestões passam a ser os dela; o tópico escolhido fica.
+    func trocarObra(_ obra: Obra) {
+        guard obra.id != obraId else { return }
+        obraId = obra.id
+        usados = usadosNestaObra(obra, topicos: topicos)
+        indice = IndiceDeSugestoes(todas, obraId: obra.id, ignorarId: nil)
+    }
+
     /// A descrição tem até 500 unidades UTF-16, como o `maxlength` do site.
     func limitarDescricao() {
         guard descricao.utf16.count > Limites.descricao else { return }
@@ -107,6 +123,8 @@ final class RascunhoDoGasto {
 struct FolhaDoGasto: View {
     let obraId: String
     let gastoId: String?
+    /// Lançado de dentro desta obra vendida: `obraId` é a obra aberta que vem marcada na linha "Obra".
+    var vendida: String? = nil
     @Environment(ModeloApp.self) private var modelo
     @Environment(Folhas.self) private var folhas
     @State private var rascunho: RascunhoDoGasto?
@@ -126,7 +144,8 @@ struct FolhaDoGasto: View {
     }
 
     private var existe: Bool {
-        guard let obra = modelo.sincronizador.estado.obras.first(where: { $0.id == obraId }) else { return false }
+        let id = rascunho?.obraId ?? obraId
+        guard let obra = modelo.sincronizador.estado.obras.first(where: { $0.id == id }) else { return false }
         return gastoId.map { id in obra.gastos.contains { $0.id == id } } ?? true
     }
 
@@ -137,7 +156,7 @@ struct FolhaDoGasto: View {
         let editado = gastoId.flatMap { id in obra.gastos.first { $0.id == id } }
         if gastoId != nil && editado == nil { folhas.fechar(); return }
         rascunho = RascunhoDoGasto(obra: obra, editado: editado, todas: estado.obras, proprios: estado.config.topicosProprios,
-                                   hoje: dataLocalISO(.now, fuso: .current))
+                                   hoje: dataLocalISO(.now, fuso: .current), vendida: vendida)
         #if DEBUG
         if editado == nil, let r = rascunho { abrirNoPassoDeTeste(r, obra: obra) }
         #endif
@@ -186,8 +205,10 @@ private struct FolhaDoGastoAberta: View {
     @Environment(ModeloApp.self) private var modelo
     @Environment(Folhas.self) private var folhas
 
-    private var nomeDaObra: String {
-        modelo.sincronizador.estado.obras.first { $0.id == rascunho.obraId }?.nome ?? ""
+    /// O nome da obra embaixo do título; lançado de dentro de uma vendida, nenhum (a obra está na linha "Obra").
+    private var nomeDaObra: String? {
+        guard rascunho.vendida == nil else { return nil }
+        return modelo.sincronizador.estado.obras.first { $0.id == rascunho.obraId }?.nome ?? ""
     }
 
     var body: some View {
@@ -212,6 +233,8 @@ private struct FolhaDoGastoAberta: View {
                     }
                 case .topicos:
                     ListaDeTopicos(rascunho: rascunho) { caminho.removeLast() }
+                case .obras:
+                    ListaDeObrasAbertas(rascunho: rascunho) { caminho.removeLast() }
                 }
             }
         }
@@ -225,7 +248,7 @@ private struct FolhaDoGastoAberta: View {
 private struct PassoDoValor: View {
     @Bindable var rascunho: RascunhoDoGasto
     let titulo: String
-    let subtitulo: String
+    let subtitulo: String?
     let acao: String
     let raiz: Bool
     let confirmar: () -> Void
@@ -240,7 +263,7 @@ private struct PassoDoValor: View {
 private struct PassoDosDetalhes: View {
     @Bindable var rascunho: RascunhoDoGasto
     @Binding var caminho: [PassoDoGasto]
-    let subtitulo: String
+    let subtitulo: String?
     let raiz: Bool
     @Environment(ModeloApp.self) private var modelo
     @Environment(Folhas.self) private var folhas
@@ -260,6 +283,7 @@ private struct PassoDosDetalhes: View {
         ScrollViewReader { leitor in
             ScrollView {
                 VStack(spacing: 20) {
+                    if let vendida = rascunho.vendida { linhaDaObra(vendida) }
                     GrupoDaFolha {
                         linhaDoValor
                         SeparadorDaFolha()
@@ -342,6 +366,31 @@ private struct PassoDosDetalhes: View {
         return a == assinaturaDoGasto(obraId: rascunho.obraId, entrada: rascunho.entrada, conferido: c)
     }
 
+    /// A linha "Obra" do gasto lançado de dentro de uma obra vendida, com a nota do mockup embaixo.
+    private func linhaDaObra(_ vendida: String) -> some View {
+        let obras = modelo.sincronizador.estado.obras
+        let nome = obras.first { $0.id == rascunho.obraId }?.nome ?? ""
+        return VStack(spacing: 8) {
+            GrupoDaFolha {
+                Button { caminho.append(.obras) } label: {
+                    LinhaDaFolhaComRotulo(rotulo: "Obra") {
+                        HStack(spacing: 10) {
+                            Text(nome).foregroundStyle(paleta.cor(.texto)).multilineTextAlignment(.trailing)
+                            SetaDaLinha()
+                        }
+                    }
+                }
+                .buttonStyle(.plain)
+                .accessibilityElement(children: .ignore)
+                .accessibilityLabel("Obra")
+                .accessibilityValue(nome)
+                .accessibilityAddTraits(.isButton)
+                .accessibilityIdentifier("linhaObra")
+            }
+            NotaDaFolha(texto: notaDaObraVendida(obras.first { $0.id == vendida }?.nome ?? ""), identificador: "notaObraVendida")
+        }
+    }
+
     private var linhaDoValor: some View {
         Button {
             if rascunho.editado == nil { caminho.removeAll() } else { caminho.append(.valor) }
@@ -529,6 +578,9 @@ private struct PassoDosDetalhes: View {
         case .gravou:
             let ids = novos.map(\.id)
             let novo = rascunho.editado == nil
+            // De dentro de uma vendida, o gasto foi para outra obra: ela toma o lugar da vendida por trás da folha, que desce
+            // mostrando o gasto aceso onde ele entrou.
+            if rascunho.vendida != nil { folhas.navegar(.trocar(obraId)) }
             folhas.fechar { folhas.destacar(ids, novo: novo) }
         case .naoCarregado:
             naoCarregado = true
@@ -588,7 +640,9 @@ private struct LinhaDeSugestao: View {
     }
 }
 
-/// A data no calendário do iPhone (DatePicker compacto, que abre o calendário gráfico), em português.
+/// A data no calendário do iPhone (DatePicker compacto, que abre o calendário gráfico), em português. A pílula da data não
+/// quebra linha: no maior tamanho de letra ela passava da largura da folha e empurrava os grupos para fora da tela; para no
+/// AX2, como as teclas do teclado de valor (o calendário que ela abre é do sistema).
 struct CampoDeData: View {
     @Binding var iso: String
     /// O rótulo da linha, que o VoiceOver lê junto da data ("Primeiro vencimento", "Data da venda").
@@ -687,6 +741,53 @@ private struct ListaDeTopicos: View {
     }
 }
 
+/// A lista das obras abertas dentro da folha (o gasto lançado de dentro de uma vendida): na ordem da lista de obras, com a
+/// marca na escolhida; tocar escolhe e volta.
+private struct ListaDeObrasAbertas: View {
+    @Bindable var rascunho: RascunhoDoGasto
+    let voltar: () -> Void
+    @Environment(ModeloApp.self) private var modelo
+    @Environment(\.paleta) private var paleta
+
+    var body: some View {
+        let abertas = obrasAbertas(modelo.sincronizador.estado.obras)
+        ScrollView {
+            GrupoDaFolha {
+                ForEach(Array(abertas.enumerated()), id: \.element.id) { i, obra in
+                    if i > 0 { SeparadorDaFolha() }
+                    Button {
+                        rascunho.trocarObra(obra)
+                        voltar()
+                    } label: {
+                        HStack(spacing: 12) {
+                            VStack(alignment: .leading, spacing: 2) {
+                                Text(obra.nome).foregroundStyle(paleta.cor(.texto))
+                                Text(obra.fase.rotulo).font(.footnote).foregroundStyle(paleta.cor(.secundarioSolido))
+                            }
+                            .frame(maxWidth: .infinity, alignment: .leading)
+                            if obra.id == rascunho.obraId {
+                                Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.linkNoVidro))
+                                    .accessibilityHidden(true)
+                            }
+                        }
+                        .padding(.horizontal, 16)
+                        .padding(.vertical, 8)
+                        .frame(minHeight: 52)
+                        .contentShape(.rect)
+                    }
+                    .buttonStyle(.plain)
+                    .accessibilityElement(children: .combine)
+                    .accessibilityAddTraits(obra.id == rascunho.obraId ? [.isSelected] : [])
+                    .accessibilityIdentifier("obraAberta-\(obra.id)")
+                }
+            }
+            .padding(.top, 8)
+            .padding(.bottom, 24)
+        }
+        .passoDaFolha("Obra", fechar: nil)
+    }
+}
+
 /// "Apagar este gasto?" (gasto simples) ou "só esta parcela / a compra toda" (parcela), pelo alerta do sistema, com os
 /// textos do mockup ("Apagar" em tudo). Os dois alertas ficam sempre presos (cada um num fundo vazio, com os botões na
 /// cor do texto, como o "Sair da conta?"); `gasto` diz qual aparece. Quem usa decide o que fazer com a confirmação: a
```

Em `app-ios/Custta/Telas/PrincipalView.swift`:

```diff
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -32,6 +32,14 @@ struct PrincipalView: View {
                 switch qual {
                 case .novoGasto(let obraId): FolhaDoGasto(obraId: obraId, gastoId: nil)
                 case .editarGasto(let obraId, let gastoId): FolhaDoGasto(obraId: obraId, gastoId: gastoId)
+                case .gastoDeVendida(let vendidaId):
+                    // Vem marcada a primeira aberta da lista de obras (a que começou mais recente), não a primeira do
+                    // documento, como no site (em geral a mais antiga).
+                    if let destino = obrasAbertas(modelo.sincronizador.estado.obras).first {
+                        FolhaDoGasto(obraId: destino.id, gastoId: nil, vendida: vendidaId)
+                    } else {
+                        Color.clear.onAppear { folhas.fechar() }
+                    }
                 case .novaObra: FolhaDaObra(obraId: nil)
                 case .editarObra(let obraId): FolhaDaObra(obraId: obraId)
                 case .venda(let obraId): FolhaDaVenda(obraId: obraId)
@@ -62,15 +70,17 @@ struct PrincipalView: View {
 }
 
 extension PrincipalView {
-    /// O + da cápsula, como o do site: na lista, "Nova obra"; dentro de uma obra que ainda recebe gasto, lança gasto nela.
-    /// Obra vendida não recebe gasto novo (como no site); a escolha de outra obra chega na Tarefa 34. Em Ajustes, some.
+    /// O + da cápsula, como o do site: na lista, "Nova obra"; dentro de uma obra, lança gasto nela. Obra vendida não recebe
+    /// gasto novo: o + abre a folha do gasto com a linha "Obra", para escolher entre as abertas; sem nenhuma aberta, cria
+    /// obra. Em Ajustes, some.
     private var acaoDoMais: AcaoDoMais? {
         guard aba == .obras else { return nil }
         let obras = modelo.sincronizador.estado.obras
         guard case .obra(let id)? = caminhoDeObras.last else { return AcaoDoMais(rotulo: "Nova obra", acao: pedirNovaObra) }
         guard let obra = obras.first(where: { $0.id == id }) else { return nil }
-        guard obra.fase != .vendida else { return nil }
-        return AcaoDoMais(rotulo: "Lançar gasto") { folhas.aberta = .novoGasto(obraId: id) }
+        if obra.fase != .vendida { return AcaoDoMais(rotulo: "Lançar gasto") { folhas.aberta = .novoGasto(obraId: id) } }
+        if obrasAbertas(obras).isEmpty { return AcaoDoMais(rotulo: "Nova obra", acao: pedirNovaObra) }
+        return AcaoDoMais(rotulo: "Lançar gasto") { folhas.aberta = .gastoDeVendida(vendidaId: id) }
     }
 
     /// "Nova obra" avisa antes de abrir: sem os dados vistos, o "Carregando suas obras" do site; com o teto cheio, o
@@ -107,7 +117,7 @@ extension PrincipalView {
 
     #if DEBUG
     /// Testes de tela, laudo e conferência visual: `CUSTTA_FOLHA` abre uma folha quando os dados chegam (`novaObra`,
-    /// `editarObra:<id>`, `venda:<id>`, `novoGasto:<id>`). Sem ele, com `CUSTTA_ABRIR=obra:<id>`,
+    /// `editarObra:<id>`, `venda:<id>`, `gastoDeVendida:<id>`, `novoGasto:<id>`). Sem ele, com `CUSTTA_ABRIR=obra:<id>`,
     /// `-custta.folha <passo>` abre a folha do gasto novo já no passo (valor, detalhes, cartao, topicos, repetido) e
     /// `-custta.folha editar:<gasto>`, a edição.
     private func abrirFolhaDoGancho() async {
@@ -123,6 +133,7 @@ extension PrincipalView {
             case "novaObra": folhas.aberta = .novaObra
             case "editarObra": folhas.aberta = .editarObra(obraId: id)
             case "venda": folhas.aberta = .venda(obraId: id)
+            case "gastoDeVendida": folhas.aberta = .gastoDeVendida(vendidaId: id)
             case "novoGasto": folhas.aberta = .novoGasto(obraId: id)
             default: break
             }
```


- [ ] **Step 4: Ver passar**

Run: `-only-testing:CusttaUITests/EstadosUITests -only-testing:CusttaUITests/GastoUITests -only-testing:CusttaTests`.
Expected: os 6 de `EstadosUITests`, os 17 de `GastoUITests` e `CusttaTests` verdes.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Estado/Folhas.swift \
  app-ios/Custta/Telas/FolhaDoGasto.swift \
  app-ios/Custta/Telas/PrincipalView.swift \
  app-ios/CusttaUITests/EstadosUITests.swift
git commit -m "feat: o + numa obra vendida lança o gasto numa obra aberta, pela linha \"Obra\"" -m "A obra vendida não recebe gasto novo, como no site: o + nela abre a folha do gasto com a linha Obra, marcada na primeira obra aberta da lista, e a lista das abertas dentro da folha. Depois de salvar, a obra que recebeu o gasto toma o lugar da vendida por trás da folha, para o gasto aparecer aceso onde entrou."
```

### Task 35: Leitura sobre o vidro e auditoria da parte 3, na maior letra e nos quatro combos

O laudo mede as ações da fase (a sólida e a de vidro), a lista vazia, as folhas da obra e da venda, o gasto numa vendida e a obra vendida com lucro e com prejuízo (os tokens `PositivoNoVidro` e `NegativoNoVidro` da Tarefa 15) nos quatro combos e na maior letra, mais os botões do alerta "Não salvou"; a auditoria do Xcode passa pelas mesmas telas na maior letra e nos quatro combos com superfícies sólidas. O "—" da venda sem estimativa e os títulos das barras entram nas exceções nomeadas. A vitrine ganha a variante com prejuízo.

**Files:**
- Modify: `app-ios/Custta/Falsos/MontarFalso.swift`
- Modify: `app-ios/Custta/Falsos/VitrineDaObra.swift`
- Test (alterar): `app-ios/CusttaUITests/AuditoriaUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`

**Interfaces:**
- Consumes: Tarefas 16 e 24 (laudo e auditoria), 29 a 34.
- Produces: `Cena.folha`; `DadosDeExemplo.vitrineComPrejuizo()` e `CUSTTA_DADOS=prejuizo`; os testes `testLeituraDaParte3`, `testLeituraDaObraVendida`, `testLeituraDaParte3NaMaiorLetra`, `testLeituraDoAlertaDeNaoSalvou`, `testParte3NoMaiorTamanho` e `testContrasteDaParte3NosQuatroCombos`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaUITests/AuditoriaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -35,6 +35,7 @@ final class AuditoriaUITests: XCTestCase {
         let barra = app.navigationBars.firstMatch
         let topoDoConteudo = barra.exists ? max(barra.frame.maxY, borda) : 0
         let daBarra = barra.exists ? barra.descendants(matching: .any).allElementsBoundByIndex.map(\.frame) : []
+        let barras = app.navigationBars.allElementsBoundByIndex.map(\.frame)
         try app.performAccessibilityAudit(for: tipos) { achado in
             guard let elemento = achado.element else {
                 Swift.print("auditoria | \(achado.compactDescription) | sem elemento | reprova")
@@ -43,16 +44,21 @@ final class AuditoriaUITests: XCTestCase {
             let fora: Bool
             switch achado.auditType {
             case .dynamicType:
-                // O título pequeno da barra da obra para perto de 22 pt, como o do sistema (mockup da etapa 2), com o
-                // Visualizador de Conteúdo Grande.
-                // Na folha (mockup da etapa 2): o título para perto de 22 pt, as teclas e o "Apagar" do arrastar param no
-                // AX2, e o visor do valor (64 pt) já é maior que o texto na maior letra e encolhe para caber.
+                // Os títulos das barras param perto de 22 pt, como os do sistema (mockup da etapa 2), com o Visualizador de
+                // Conteúdo Grande: o pequeno da obra e o das folhas (título e o nome da obra embaixo), na barra da folha.
+                // Na folha do gasto, as teclas e o "Apagar" do arrastar param no AX2, e o visor do valor (64 pt) já é
+                // maior que o texto na maior letra e encolhe para caber.
+                let centro = CGPoint(x: elemento.frame.midX, y: elemento.frame.midY)
                 fora = elemento.label == "Continuar com o Google" || elemento.identifier == "tituloPequenoDaBarra"
                     || elemento.identifier.hasPrefix("tituloDaFolha") || elemento.identifier.hasPrefix("visorDoValor")
                     || elemento.identifier.hasPrefix("tecla-") || elemento.identifier.hasPrefix("apagar-")
-                    || abas.contains { $0.contains(CGPoint(x: elemento.frame.midX, y: elemento.frame.midY)) }
+                    || barras.contains { $0.contains(centro) } || abas.contains { $0.contains(centro) }
             case .contrast:
                 if elemento.identifier.hasPrefix("aba-") { fora = false }   // o rótulo da própria cápsula
+                // O travessão da venda sem estimativa: um traço de 3 pt que a auditoria não consegue medir (como o "·"
+                // solto da linha de gasto); está na cor do texto, na mesma superfície dos valores que passam, e o laudo
+                // de leitura mede o pixel dele.
+                else if elemento.label == "—" { fora = true }
                 else {
                     let sobABarra = elemento.frame.minY < topoDoConteudo && !daBarra.contains(elemento.frame)
                     fora = sobABarra || elemento.frame.maxY > fundoDaTela
@@ -255,6 +261,61 @@ final class AuditoriaUITests: XCTestCase {
         }
     }
 
+    /// As telas da etapa 2, parte 3, na maior letra: a obra pronta (com as duas ações da fase, a sólida e a de vidro) em
+    /// rolagens fixas, a lista vazia, as folhas da obra (nova e editar) e a da venda. Na obra, rolagem fixa e não o arrasto:
+    /// logo depois do arrasto, a auditoria marcava "Text clipped" nos indicadores da v2, que parados não cortam (triagem em
+    /// 0, 400 e 800 pt, na v1 e na v2).
+    @MainActor func testParte3NoMaiorTamanho() throws {
+        var app: XCUIApplication
+        for rolagem in [0, 800, 1600] {
+            app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2",
+                           argumentos: maiorLetra + parado + ["-custta.rolagem", "\(rolagem)"])
+            XCTAssertTrue(app.buttons["editarObra"].waitForExistence(timeout: 10))
+            Thread.sleep(forTimeInterval: 1.5)
+            try auditar(app, tiposDeAuditoria)
+            app.terminate()
+        }
+        app = abrirApp(conta: "senha", dados: "vazio", argumentos: maiorLetra + parado)
+        XCTAssertTrue(app.elemento("obrasVazio").waitForExistence(timeout: 10))
+        try auditar(app, tiposDeAuditoria)
+        app.terminate()
+        for (folha, espera, abrir) in [("novaObra", "nomeDaObra", nil), ("editarObra:v1", "apagarObra", "obra:v1"),
+                                       ("venda:v2", "confirmarVenda", "obra:v2")] {
+            app = abrirApp(conta: "senha", dados: "vitrine", abrir: abrir, folha: folha,
+                           argumentos: maiorLetra + parado + ["-custta.folha", folha == "novaObra" ? "preenchida" : "detalhes"])
+            XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), folha)
+            try auditar(app, tiposDeAuditoria)
+            app.swipeUp()
+            Thread.sleep(forTimeInterval: 1.5)
+            try auditar(app, tiposDeAuditoria)
+            app.terminate()
+        }
+    }
+
+    /// As mesmas telas nos quatro combos, com superfícies sólidas.
+    @MainActor func testContrasteDaParte3NosQuatroCombos() throws {
+        for (tema, pele) in quatroCombos {
+            let combo = ["-custta.tema", tema, "-custta.pele", pele] + solido + parado
+            var app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v2", argumentos: combo + ["-custta.rolagem", "250"])
+            XCTAssertTrue(app.buttons["acao-voltarConstrucao"].waitForExistence(timeout: 10))
+            Thread.sleep(forTimeInterval: 1)
+            try auditar(app, [.contrast])
+            app.terminate()
+            app = abrirApp(conta: "senha", dados: "vazio", argumentos: combo)
+            XCTAssertTrue(app.elemento("obrasVazio").waitForExistence(timeout: 10))
+            try auditar(app, [.contrast])
+            app.terminate()
+            for (folha, espera, abrir) in [("novaObra", "nomeDaObra", nil), ("venda:v2", "confirmarVenda", "obra:v2")] {
+                app = abrirApp(conta: "senha", dados: "vitrine", abrir: abrir, folha: folha,
+                               argumentos: combo + ["-custta.folha", folha == "novaObra" ? "preenchida" : "detalhes"])
+                XCTAssertTrue(app.elemento(espera).waitForExistence(timeout: 10), folha)
+                Thread.sleep(forTimeInterval: 1)
+                try auditar(app, [.contrast])
+                app.terminate()
+            }
+        }
+    }
+
     /// A deriva move os brilhos da aurora: o título e a dica da entrada são medidos também com a aurora
     /// congelada nos quadros de 13 s e 26 s (os extremos da deriva), no escuro, onde ela é mais clara.
     @MainActor func testContrasteDoTituloComAAuroraEmMovimento() throws {
```

Em `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -39,13 +39,15 @@ final class LeituraNoVidroUITests: XCTestCase {
         /// Dados dos falsos e tela aberta pelo gancho (`obra:v1`, a obra do mockup na vitrine).
         var dados = "exemplo"
         var abrir: String? = nil
+        /// Folha aberta pelo gancho quando os dados chegam (`novaObra`, `venda:v2`; etapa 2, parte 3).
+        var folha: String? = nil
         /// Tela rolada: o texto que passa por baixo da barra é borrado pela borda de rolagem e muda quando é apagado, a
         /// mais de 5 pt das letras; os 140 pt de cima (a borda) ficam de fora, como os de baixo.
         var rolada = false
     }
 
     @MainActor private func fotografar(_ cena: Cena, textoApagado: Bool) -> (XCUIScreenshot, [CGRect], CGFloat) {
-        let app = abrirApp(conta: cena.conta, dados: cena.dados, abrir: cena.abrir,
+        let app = abrirApp(conta: cena.conta, dados: cena.dados, abrir: cena.abrir, folha: cena.folha,
                            argumentos: cena.argumentos + (textoApagado ? ["-custta.textoApagado", cena.escopo] : []))
         XCTAssertTrue(app.elemento(cena.espera).waitForExistence(timeout: 10), "\(cena.nome): a tela não abriu")
         if let aba = cena.aba {
@@ -290,7 +292,8 @@ extension LeituraNoVidroUITests {
     }
 
     /// A tela da obra (etapa 2): o topo (título, fase, indicadores) e a lista rolada (o "A vencer" e os cartões dos meses),
-    /// nos quatro combos; mais a maior letra e o Aumentar contraste, no escuro esmeralda.
+    /// nos quatro combos; mais a maior letra e o Aumentar contraste, no escuro esmeralda. A vendida fica no
+    /// testLeituraDaObraVendida (lucro e prejuízo).
     @MainActor func testLeituraDaObra() {
         var cenas: [Cena] = []
         for (tema, pele) in quatroCombos {
@@ -302,13 +305,6 @@ extension LeituraNoVidroUITests {
                      espera: "aVencer", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
             ]
         }
-        // A obra vendida: a venda com a nota de lucro (PositivoNoVidro) e a etiqueta "Vendida", nos quatro combos (o
-        // Positivo do site ficava em 2,76:1 no claro azul).
-        for (tema, pele) in quatroCombos {
-            cenas.append(Cena(nome: "obra vendida, \(tema), \(pele)", conta: "senha",
-                              argumentos: ["-custta.tema", tema, "-custta.pele", pele] + piorMomento, espera: "tituloDaObra",
-                              escopo: "tudo", dados: "vitrine", abrir: "obra:v3"))
-        }
         let escuro = ["-custta.tema", "escuro", "-custta.pele", "esmeralda"] + piorMomento
         cenas += [
             Cena(nome: "obra na maior letra", conta: "senha", argumentos: escuro + maiorLetra, espera: "tituloDaObra", escopo: "tudo",
@@ -373,6 +369,97 @@ extension LeituraNoVidroUITests {
     }
 }
 
+extension LeituraNoVidroUITests {
+    /// A parte 3 da etapa 2: as ações da fase (a sólida da marca e a de vidro), a lista vazia, as folhas da obra e da venda
+    /// e a do gasto lançado de dentro de uma vendida, nos quatro combos; mais a maior letra no escuro esmeralda.
+    @MainActor func testLeituraDaParte3() {
+        var cenas: [Cena] = []
+        for (tema, pele) in quatroCombos {
+            let combo = ["-custta.tema", tema, "-custta.pele", pele] + piorMomento
+            cenas += [
+                Cena(nome: "obra pronta, ações da fase, \(tema), \(pele)", conta: "senha", argumentos: combo + ["-custta.rolagem", "250"],
+                     espera: "acao-voltarConstrucao", escopo: "tudo", dados: "vitrine", abrir: "obra:v2", rolada: true),
+                Cena(nome: "lista vazia, \(tema), \(pele)", conta: "senha", argumentos: combo, espera: "obrasVazio", escopo: "tudo", dados: "vazio"),
+                Cena(nome: "folha da obra nova, \(tema), \(pele)", conta: "senha", argumentos: combo + ["-custta.folha", "preenchida"],
+                     espera: "nomeDaObra", escopo: "tudo", dados: "vitrine", folha: "novaObra"),
+                Cena(nome: "folha da venda, data, \(tema), \(pele)", conta: "senha", argumentos: combo + ["-custta.folha", "detalhes"],
+                     espera: "confirmarVenda", escopo: "tudo", dados: "vitrine", abrir: "obra:v2", folha: "venda:v2"),
+            ]
+        }
+        let escuro = ["-custta.tema", "escuro", "-custta.pele", "esmeralda"] + piorMomento
+        cenas += [
+            Cena(nome: "folha do gasto numa vendida", conta: "senha", argumentos: escuro + ["-custta.folha", "detalhes"],
+                 espera: "linhaObra", escopo: "tudo", dados: "vitrine", abrir: "obra:v3", folha: "gastoDeVendida:v3"),
+            Cena(nome: "folha de editar obra", conta: "senha", argumentos: escuro, espera: "apagarObra", escopo: "tudo",
+                 dados: "vitrine", abrir: "obra:v1", folha: "editarObra:v1"),
+        ]
+        cobrar(cenas)
+    }
+
+    /// A obra vendida: o lucro (PositivoNoVidro) e o prejuízo (NegativoNoVidro) sobre o vidro e o "Desfazer venda" de vidro,
+    /// nos quatro combos. Com o Positivo e o Negativo do site, o lucro ficava em 3,66:1 no escuro esmeralda e 2,76:1 no
+    /// claro azul.
+    @MainActor func testLeituraDaObraVendida() {
+        var cenas: [Cena] = []
+        for (tema, pele) in quatroCombos {
+            let combo = ["-custta.tema", tema, "-custta.pele", pele] + piorMomento + ["-custta.rolagem", "400"]
+            cenas += [
+                Cena(nome: "obra vendida com lucro, \(tema), \(pele)", conta: "senha", argumentos: combo, espera: "acao-desfazerVenda",
+                     escopo: "tudo", dados: "vitrine", abrir: "obra:v3", rolada: true),
+                Cena(nome: "obra vendida com prejuízo, \(tema), \(pele)", conta: "senha", argumentos: combo, espera: "acao-desfazerVenda",
+                     escopo: "tudo", dados: "prejuizo", abrir: "obra:v3", rolada: true),
+            ]
+        }
+        cobrar(cenas)
+    }
+
+    @MainActor func testLeituraDaParte3NaMaiorLetra() {
+        let escuro = ["-custta.tema", "escuro", "-custta.pele", "esmeralda"] + piorMomento + maiorLetra
+        cobrar([
+            // Espera o lápis da barra: rolada a 1100 pt em 300 ms, o título sai da pilha preguiçosa antes da espera achar.
+            Cena(nome: "obra pronta, ações da fase, na maior letra", conta: "senha", argumentos: escuro + ["-custta.rolagem", "1100"],
+                 espera: "editarObra", escopo: "tudo", dados: "vitrine", abrir: "obra:v2", rolada: true),
+            Cena(nome: "lista vazia na maior letra", conta: "senha", argumentos: escuro, espera: "obrasVazio", escopo: "tudo", dados: "vazio"),
+            Cena(nome: "folha da obra nova na maior letra", conta: "senha", argumentos: escuro + ["-custta.folha", "preenchida"],
+                 espera: "nomeDaObra", escopo: "tudo", dados: "vitrine", folha: "novaObra"),
+            Cena(nome: "folha da venda na maior letra", conta: "senha", argumentos: escuro + ["-custta.folha", "detalhes"],
+                 espera: "confirmarVenda", escopo: "tudo", dados: "vitrine", abrir: "obra:v2", folha: "venda:v2"),
+        ])
+    }
+
+    /// O "Não salvou" (uma vez, quando o erro não passa sozinho), nos quatro combos: "OK" e "Tentar de novo" no tint do alerta
+    /// (Texto), medidos contra a própria cápsula, como o "Cancelar" do "Sair da conta?".
+    @MainActor func testLeituraDoAlertaDeNaoSalvou() {
+        var falhas: [String] = []
+        for (tema, pele) in quatroCombos {
+            let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", gravacao: "recusa",
+                               argumentos: ["-custta.tema", tema, "-custta.pele", pele] + piorMomento)
+            let pronta = app.buttons["acao-marcarPronta"]
+            XCTAssertTrue(pronta.waitForExistence(timeout: 10))
+            app.rolarAte(pronta)
+            pronta.tap()
+            let alerta = app.alerts["Não salvou na nuvem"]
+            XCTAssertTrue(alerta.waitForExistence(timeout: 8), "\(tema), \(pele): o alerta não abriu")
+            Thread.sleep(forTimeInterval: 2)
+            let foto = XCUIScreen.main.screenshot()
+            let imagem = foto.image.cgImage!
+            let escala = CGFloat(imagem.width) / app.frame.width
+            let botoes = ["OK", "Tentar de novo"].map { ($0, alerta.buttons[$0].frame) }
+            app.terminate()
+            for (rotulo, quadro) in botoes {
+                let nome = "alerta Não salvou, \(rotulo), \(tema), \(pele)"
+                guard let palavra = LaudoDeContraste.medirRotulo(Retrato(imagem), quadro: quadro, escala: escala) else {
+                    XCTFail("\(nome): o rótulo não foi achado"); continue
+                }
+                anexar(nome, foto.image, [palavra], escala)
+                Swift.print(String(format: "leitura | %@ | %@ | nota %.2f (pior pixel %.2f)", nome, palavra.corHex, palavra.nota, palavra.minimo))
+                if palavra.nota < Self.portao { falhas.append(String(format: "%@ em %.2f:1", nome, palavra.nota)) }
+            }
+        }
+        XCTAssertTrue(falhas.isEmpty, "Abaixo de \(Self.portao):1 no alerta:\n" + falhas.joined(separator: "\n"))
+    }
+}
+
 /* O medidor com imagens sintéticas: sem abrir o app. */
 final class LaudoDeContrasteTests: XCTestCase {
     private func retrato(_ largura: Int, _ altura: Int, fundo: (UInt8, UInt8, UInt8),
```


- [ ] **Step 2: Ver falhar**

Run: `-only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaObraVendida` com os tokens `Positivo`/`Negativo` no lugar dos `NoVidro` (troque na `IndicadoresDaObraView` e volte).
Expected: "obra vendida com lucro, claro, azul … fica em 2,76:1".

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Falsos/MontarFalso.swift`:

```diff
--- a/app-ios/Custta/Falsos/MontarFalso.swift
+++ b/app-ios/Custta/Falsos/MontarFalso.swift
@@ -6,7 +6,8 @@ import CusttaNucleo
    Variáveis que o teste passa ao abrir o app:
    CUSTTA_CONTA   conta inicial da ContaFalsa (nenhuma, senha, senha-nao-confirmada, apple-sem-perfil,
                   google-sem-perfil, google-perfil-concorrente)
-   CUSTTA_DADOS   vitrine (padrão: as obras do mockup) | exemplo (as dos testes) | vazio | limite (as 300 obras do teto)
+   CUSTTA_DADOS   vitrine (padrão: as obras do mockup) | exemplo (as dos testes) | vazio | limite (as 300 obras do teto) |
+                  prejuizo (a vitrine com a vendida no prejuízo)
    CUSTTA_REDE    offline (abre "em modo avião": dados do cache e indicador "Sem conexão")
    CUSTTA_LEITURA erro (a escuta falha com permission-denied) | formato (documento que o app não lê) | nunca (a escuta
                   não responde: "Carregando suas obras…")
@@ -31,6 +32,7 @@ extension Composicao {
         case "vazio": nil
         case "exemplo": DadosDeExemplo.blob
         case "limite": DadosDeExemplo.noTeto()
+        case "prejuizo": DadosDeExemplo.vitrineComPrejuizo()
         default: DadosDeExemplo.vitrine()
         }
         // CUSTTA_APAGAR_REMOTO=<obra>/<gasto>@<segundos>: outro aparelho apaga um gasto com o app aberto.
```

Em `app-ios/Custta/Falsos/VitrineDaObra.swift`:

```diff
--- a/app-ios/Custta/Falsos/VitrineDaObra.swift
+++ b/app-ios/Custta/Falsos/VitrineDaObra.swift
@@ -81,6 +81,17 @@ extension DadosDeExemplo {
 }
 
 extension DadosDeExemplo {
+    /// A vitrine com a Casa Tamboré 4 vendida com prejuízo (R$ 800 mil por R$ 976 mil gastos): a nota do prejuízo no laudo.
+    static func vitrineComPrejuizo() -> ValorJSON {
+        guard case .objeto(var raiz) = vitrine(), case .lista(var obras) = raiz["obras"], case .objeto(var tambore) = obras[2],
+              case .objeto(var venda) = tambore["venda"] else { return vitrine() }
+        venda["valor"] = .numero(800_000)
+        tambore["venda"] = .objeto(venda)
+        obras[2] = .objeto(tambore)
+        raiz["obras"] = .lista(obras)
+        return .objeto(raiz)
+    }
+
     /// O teto das rules: 300 obras ("Obra 1" a "Obra 300"), para o aviso de "Nova obra".
     static func noTeto() -> ValorJSON {
         .objeto([
```


- [ ] **Step 4: Ver passar**

Run: `-only-testing:CusttaUITests/LeituraNoVidroUITests -only-testing:CusttaUITests/AuditoriaUITests` no 18 Pro e, no Mac, também no Pro Max (`CUSTTA_SIMULADOR`).
Expected: nenhuma palavra abaixo de 4,5:1 (a pior é a etiqueta sólida "estimativa", 4,56); as auditorias sem achado.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Falsos/MontarFalso.swift \
  app-ios/Custta/Falsos/VitrineDaObra.swift \
  app-ios/CusttaUITests/AuditoriaUITests.swift \
  app-ios/CusttaUITests/LeituraNoVidroUITests.swift
git commit -m "test: leitura sobre o vidro e auditoria da parte 3, na maior letra e nos quatro combos" -m "O laudo mede as ações da fase, a lista vazia, as folhas da obra e da venda, o gasto numa vendida, a obra vendida com lucro e com prejuízo e o alerta de Não salvou; a auditoria passa pelas mesmas telas na maior letra e nos quatro combos. A vitrine ganha a variante com prejuízo."
```

### Task 36: Conferência cruzada da obra criada, editada, vendida e apagada no app

O roteiro da obra entra na conferência cruzada: criar duas obras (uma com a área 3,125 e o orçamento), editar uma do site apagando a estimativa, marcar como pronta, vender, desfazer a venda da obra vendida do site e apagar uma das criadas. O app grava cada passo pelas mesmas mutações das telas; o site confere, com o `dados.js`, que o documento é exatamente o que ele gravaria (a obra nova sem `afazeres` e sem `venda`, a venda como `{valor, data}`, o desfazer sem a chave, os campos que só o site conhece intactos).

**Files:**
- Test (alterar): `app-ios/CusttaTests/CruzadoTests.swift`
- Test (alterar): `tests/app-ios/cruzado.mjs`

**Interfaces:**
- Consumes: Tarefa 25 (o roteiro dos gastos), 27 e 28.
- Produces: `CUSTTA_ROTEIRO_OBRA`; o teste `appSegueOsRoteirosDoSite` (os dois roteiros, um depois do outro, na mesma conta).

- [ ] **Step 1: Escrever o roteiro e o teste**

Em `app-ios/CusttaTests/CruzadoTests.swift`:

```diff
--- a/app-ios/CusttaTests/CruzadoTests.swift
+++ b/app-ios/CusttaTests/CruzadoTests.swift
@@ -5,15 +5,16 @@ import FirebaseAuth
 import CusttaNucleo
 
 /* Metade app da conferência cruzada (tests/app-ios/cruzado.mjs): entra na conta que o "site" criou, carrega o
-   documento e segue o roteiro de gastos do site (lançar no Pix e no cartão parcelado, editar um gasto e uma parcela,
-   apagar um gasto e a compra toda) pelas mesmas regras das telas: o núcleo confere e monta cada gasto, o estado muda
-   pelas mutações e cada passo grava pelo Sincronizador, como um toque em "Salvar" ou "Apagar". Os ids vêm do roteiro,
-   para o site montar o mesmo resultado. O roteiro confere depois, com o SDK JavaScript, que o documento é o que o
-   site gravaria com as mesmas respostas e que nada do site se perdeu. */
+   documento e segue os roteiros do site pelas mesmas regras das telas: o dos gastos (lançar no Pix e no cartão
+   parcelado, editar um gasto e uma parcela, apagar um gasto e a compra toda) e o da obra (criar, editar, marcar como
+   pronta, vender, desfazer a venda e apagar). O núcleo confere e monta cada mudança, o estado muda pelas mutações e
+   cada passo grava pelo Sincronizador, como um toque em "Salvar", "Confirmar venda" ou "Apagar". Os ids vêm do
+   roteiro, para o site montar o mesmo resultado. O roteiro confere depois, com o SDK JavaScript, que o documento é o
+   que o site gravaria com as mesmas respostas e que nada do site se perdeu. */
 @MainActor
 @Suite(.enabled(if: ProcessInfo.processInfo.environment["CUSTTA_CRUZADO"] == "1"))
 struct CruzadoTests {
-    @Test func appSegueORoteiroDeGastosDoSite() async throws {
+    @Test func appSegueOsRoteirosDoSite() async throws {
         let ambiente = ProcessInfo.processInfo.environment
         let u = try await Auth.auth(app: Emulador.app).signIn(withEmail: ambiente["CUSTTA_EMAIL"]!, password: ambiente["CUSTTA_SENHA"]!).user
         let s = Sincronizador(transporte: TransporteFirebase(banco: Emulador.banco), relogio: RelogioDoSistema())
@@ -47,10 +48,47 @@ struct CruzadoTests {
             }
             ultima = try s.aplicar(try #require(novo, "o passo \(acao) achou o que mudar"))
         }
+        // A obra (parte 3): cada passo como a folha da obra, as ações da fase e a folha da venda gravam.
+        let roteiroDaObra = try JSONDecoder().decode(ValorJSON.self, from: Data(try #require(ambiente["CUSTTA_ROTEIRO_OBRA"]).utf8))
+        for passo in try #require(roteiroDaObra.comoLista) {
+            let p = try #require(passo.comoObjeto)
+            let acao = try #require(p["acao"]?.comoTexto), obraId = p["obra"]?.comoTexto ?? ""
+            let novo: Estado?
+            switch acao {
+            case "criar":
+                let campos = try camposDoRoteiro(p)
+                try #require(conferirObra(campos, nova: true) == nil)
+                novo = s.estado.criandoObra(obraNova(campos, id: try #require(p["id"]?.comoTexto), hoje: hoje))
+            case "editar":
+                let campos = try camposDoRoteiro(p)
+                try #require(conferirObra(campos, nova: false) == nil)
+                novo = s.estado.editandoObra(obraId, campos)
+            case "fase":
+                let fase = try #require(p["fase"]?.comoTexto)
+                novo = s.estado.mudandoFase(obraId, para: try #require(Fase(rawValue: fase)))
+            case "vender":
+                let obra = try #require(s.estado.obras.first { $0.id == obraId }, "a obra \(obraId) do roteiro")
+                let valor = try #require(p["valor"]?.comoNumero), data = try #require(p["data"]?.comoTexto)
+                try #require(conferirVenda(valor: valor, data: data, dataInicio: obra.dataInicio, hoje: hoje) == nil)
+                novo = s.estado.registrandoVenda(obraId, valor: valor, data: data)
+            case "desfazer":
+                novo = s.estado.desfazendoVenda(obraId)
+            default:
+                novo = s.estado.apagandoObra(obraId)
+            }
+            ultima = try s.aplicar(try #require(novo, "o passo \(acao) da obra achou o que mudar"))
+        }
         try await #require(ultima).confirmada()
         s.parar()
     }
 
+    private func camposDoRoteiro(_ passo: [String: ValorJSON]) throws -> CamposDaObra {
+        let c = try #require(passo["campos"]?.comoObjeto)
+        return CamposDaObra(nome: try #require(c["nome"]?.comoTexto), dataInicio: c["dataInicio"]?.comoTexto ?? "",
+                            valorEstimadoVenda: c["valorEstimadoVenda"]?.comoNumero ?? 0, areaM2: c["areaM2"]?.comoNumero ?? 0,
+                            orcamento: c["orcamento"]?.comoNumero ?? 0)
+    }
+
     private func entradaDoRoteiro(_ passo: [String: ValorJSON]) throws -> EntradaDoGasto {
         let e = try #require(passo["entrada"]?.comoObjeto)
         return EntradaDoGasto(valor: try #require(e["valor"]?.comoNumero), topico: try #require(e["topico"]?.comoTexto),
```

Em `tests/app-ios/cruzado.mjs`:

```diff
--- a/tests/app-ios/cruzado.mjs
+++ b/tests/app-ios/cruzado.mjs
@@ -8,12 +8,13 @@
         tópico estourado, obra com compra parcelada no cartão com juros e campos que só o site conhece);
      2. CruzadoUITests entra pelo formulário e confere o total e o orçamento que o calc.js calculou;
      3. o teste pede a v2 (POST no auxiliar abaixo) e espera ver os números novos sozinhos;
-     4. CruzadoTests segue o roteiro de gastos abaixo pelas regras das telas do app (lançar no Pix e no cartão
-        parcelado com juros, editar um gasto do site e uma parcela, apagar um gasto da obra vendida e a compra
-        toda), gravando cada passo pelo Sincronizador;
+     4. CruzadoTests segue os roteiros abaixo pelas regras das telas do app: o dos gastos (lançar no Pix e no
+        cartão parcelado com juros, editar um gasto do site e uma parcela, apagar um gasto da obra vendida e a
+        compra toda) e o da obra (criar duas, editar, marcar como pronta, vender, desfazer a venda da obra vendida
+        do site e apagar uma das criadas), gravando cada passo pelo Sincronizador;
      5. este roteiro confere que o documento final foi gravado pelo app (o _atualizado avançou), que é
         exatamente o que o site gravaria com as mesmas respostas (dados.js, com os mesmos ids), sem perder os
-        campos que só o site conhece, e que o site soma o resultado.
+        campos que só o site conhece nem pôr o que a leitura acrescentaria, e que o site soma o resultado.
    Teste pulado não passa: sem o pedido de mudança ou sem a gravação do app, o roteiro falha. */
 import assert from 'node:assert/strict';
 import { createServer } from 'node:http';
@@ -76,6 +77,17 @@ const roteiro = [
   { acao: 'apagarCompra', obra: 'c3', grupo: 'gz' },
 ];
 const ids = ['app1', 'app2', 'app3', 'app4', 'app5'];
+/* O roteiro da obra (etapa 2, parte 3): o que a pessoa responde na folha "Nova obra" (a área com três casas, que o
+   editar do site multiplicava por 1000), em "Editar obra" (estimativa apagada), nas ações da fase e na folha da venda. */
+const roteiroDaObra = [
+  { acao: 'criar', id: 'appo1', campos: { nome: 'Galpão criado no app', dataInicio: '2026-04-01', valorEstimadoVenda: 350000, areaM2: 3.125, orcamento: 120000 } },
+  { acao: 'criar', id: 'appo2', campos: { nome: 'Obra criada e apagada no app', dataInicio: '', valorEstimadoVenda: 0, areaM2: 50, orcamento: 0 } },
+  { acao: 'editar', obra: 'c1', campos: { nome: 'Casa do teste cruzado, editada', dataInicio: '2026-01-12', valorEstimadoVenda: 0, areaM2: 180.5, orcamento: 0 } },
+  { acao: 'fase', obra: 'c1', fase: 'pronta' },
+  { acao: 'vender', obra: 'c1', valor: 650000, data: '2026-04-01' },
+  { acao: 'desfazer', obra: 'c2' },
+  { acao: 'apagarObra', obra: 'appo2' },
+];
 /** O que o site gravaria com as mesmas respostas: as regras do dados.js e os filtros do apagar do app.js. */
 function comoOSite(blob){
   const db = D.normaliza(structuredClone(blob));
@@ -90,6 +102,16 @@ function comoOSite(blob){
     else if(p.acao === 'apagar') o.gastos = o.gastos.filter(g => g.id !== p.gasto);
     else o.gastos = o.gastos.filter(g => g.grupoId !== p.grupo);
   }
+  // A obra: formNovaObra, formEditarObra, mudarFase, a venda e o desfazer do app.js, e o apagar.
+  for(const p of roteiroDaObra){
+    const o = db.obras.find(x => x.id === p.obra);
+    if(p.acao === 'criar'){ assert.equal(D.conferirObra(p.campos, true), null); db.obras.push(D.obraNova(p.campos, p.id, HOJE)); }
+    else if(p.acao === 'editar'){ assert.equal(D.conferirObra(p.campos, false), null); db.obras[db.obras.indexOf(o)] = D.obraEditada(o, p.campos); }
+    else if(p.acao === 'fase') o.fase = p.fase;
+    else if(p.acao === 'vender'){ assert.equal(D.conferirVenda(p.valor, p.data, o.dataInicio, HOJE), null); o.venda = { valor: p.valor, data: p.data }; o.fase = 'vendida'; }
+    else if(p.acao === 'desfazer'){ delete o.venda; o.fase = 'pronta'; }
+    else db.obras = db.obras.filter(x => x.id !== p.obra);
+  }
   return db;
 }
 
@@ -113,7 +135,7 @@ await new Promise(r => auxiliar.listen(8124, '127.0.0.1', r));
 
 const env = { CUSTTA_CRUZADO: '1', CUSTTA_EMULADORES: '1', CUSTTA_EMAIL: email, CUSTTA_SENHA: senha,
   CUSTTA_ESPERADO_V1: JSON.stringify(esperado(v1)), CUSTTA_ESPERADO_V2: JSON.stringify(esperado(v2)),
-  CUSTTA_ROTEIRO: JSON.stringify(roteiro), CUSTTA_IDS: ids.join(','), CUSTTA_HOJE: HOJE };
+  CUSTTA_ROTEIRO: JSON.stringify(roteiro), CUSTTA_IDS: ids.join(','), CUSTTA_ROTEIRO_OBRA: JSON.stringify(roteiroDaObra), CUSTTA_HOJE: HOJE };
 let antesDoApp;
 try{
   await testarNoSimulador(['CusttaUITests/CruzadoUITests'], env);
@@ -127,22 +149,37 @@ assert.ok(final._atualizado instanceof Timestamp, 'a gravação do app leva _atu
 assert.ok(final._atualizado.toMillis() > antesDoApp.toMillis(), 'o documento não foi regravado depois do teste do app: ele foi pulado ou não gravou');
 delete final._atualizado;
 const v3 = comoOSite(v2);
-assert.equal(C.canon(final), C.canon(D.normaliza(v3)), 'o app gravou o que o site gravaria com as mesmas respostas, sem tirar nem pôr nada');
-assert.deepEqual(final.obras[0].campoSoDoSite, { versao: 7 }, 'campo de obra que só o site conhece');
-const x1 = final.obras[0].gastos.find(g => g.id === 'x1');
+assert.equal(C.canon(final), C.canon(v3), 'o app gravou o que o site gravaria com as mesmas respostas, sem tirar nem pôr nada');
+const porId = id => final.obras.find(o => o.id === id);
+assert.deepEqual(final.obras.map(o => o.id), ['c1', 'c2', 'c3', 'appo1'], 'a obra criada no app no fim, como o push do site; a outra criada foi apagada');
+const c1 = porId('c1'), c2 = porId('c2'), c3 = porId('c3'), criada = porId('appo1');
+assert.deepEqual(c1.campoSoDoSite, { versao: 7 }, 'campo de obra que só o site conhece, numa obra editada e vendida no app');
+const x1 = c1.gastos.find(g => g.id === 'x1');
 assert.equal(x1.notaSoDoSite, 'fica', 'campo de gasto que só o site conhece, num gasto editado no app');
 assert.equal(x1.pagamento, 'cartao', 'a edição trocou o Pix pelo cartão');
 assert.ok(!('jurosCartao' in x1), 'cartão na edição não ganha juros nem parcelas (app.js:1071)');
-const z = final.obras[2].gastos;
-assert.equal(z.length, 0, 'a compra toda da obra c3 saiu, inclusive a parcela editada');
-assert.deepEqual(final.obras[1].gastos.map(g => g.id), ['y1', 'y2'], 'gasto de obra vendida também se apaga');
-const compraDoApp = final.obras[0].gastos.filter(g => g.grupoId === 'app2');
+assert.equal(c3.gastos.length, 0, 'a compra toda da obra c3 saiu, inclusive a parcela editada');
+assert.deepEqual(c2.gastos.map(g => g.id), ['y1', 'y2'], 'gasto de obra vendida também se apaga');
+const compraDoApp = c1.gastos.filter(g => g.grupoId === 'app2');
 assert.deepEqual(compraDoApp.map(g => [g.parcela.n, g.parcela.de, g.data]), [[1, 3, '2026-04-10'], [2, 3, '2026-05-10'], [3, 3, '2026-06-10']],
   'a compra em 3x lançada no app: as parcelas e as datas do site');
 const cartao = C.parcelamentoCartao(3000, 3, 2.5, '2026-04-10');
 assert.deepEqual(compraDoApp[0].jurosCartao, { taxaMensal: 2.5, valorCompra: 3000, nParcelas: 3, totalCompra: cartao.totalCompra, jurosCompra: cartao.jurosCompra },
   'as condições da compra, iguais nas parcelas');
-assert.equal(C.money(C.totalBruto(D.normaliza(final).obras[0])), C.money(12000 + 40000 + 999.99 + cartao.totalCompra), 'o site soma o que o app gravou');
+assert.equal(C.money(C.totalBruto(D.normaliza(final).obras.find(o => o.id === 'c1'))), C.money(12000 + 40000 + 999.99 + cartao.totalCompra), 'o site soma o que o app gravou');
+// A obra (etapa 2, parte 3).
+assert.ok(!('afazeres' in criada) && !('venda' in criada), 'a obra criada no app vai como o obraNova do site: sem afazeres e sem venda (a leitura acrescenta)');
+assert.equal(criada.areaM2, 3.125, 'a área com três casas chega inteira');
+assert.deepEqual(criada.orcamento, { modo: 'total', total: 120000 }, 'o orçamento total da obra nova');
+assert.equal(criada.valorEstimadoVenda, 350000);
+assert.equal(c1.nome, 'Casa do teste cruzado, editada');
+assert.equal(c1.valorEstimadoVenda, null, 'a estimativa apagada na edição vira null, como no site');
+assert.equal(c1.areaM2, 180.5);
+assert.deepEqual(c1.orcamento, { modo: 'total', total: 50000 }, 'editar a obra não mexe no orçamento');
+assert.equal(c1.fase, 'vendida');
+assert.deepEqual(c1.venda, { valor: 650000, data: '2026-04-01' }, 'a venda como o site grava');
+assert.equal(c2.fase, 'pronta');
+assert.ok(!('venda' in c2), 'desfazer a venda tira a chave, como o delete do site');
 await terminate(db);
-console.log('ok - site e app na mesma conta: totais e orçamentos iguais, mudança do site chegou ao app, e o roteiro de gastos do app gravou o que o site gravaria, sem perder nada');
+console.log('ok - site e app na mesma conta: totais e orçamentos iguais, mudança do site chegou ao app, e os roteiros do gasto e da obra gravaram o que o site gravaria, sem perder nada');
 process.exit(0);
```


- [ ] **Step 2: Ver falhar**

Run: `CUSTTA_SIMULADOR=<udid> npm run test:app-ios:cruzado 2>&1 | tail -5` com o passo `criar` trocado por um `editar` da obra `c3`.
Expected: `o app gravou o que o site gravaria com as mesmas respostas, sem tirar nem pôr nada` falha (os documentos diferem).

- [ ] **Step 3: Desfazer o passo trocado**

Volte o passo `criar` do roteiro como está no Step 1.

- [ ] **Step 4: Ver passar**

Run: `CUSTTA_SIMULADOR=<udid> npm run test:app-ios:cruzado 2>&1 | tail -3`
Expected: `ok - site e app na mesma conta: … os roteiros do gasto e da obra gravaram o que o site gravaria, sem perder nada`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaTests/CruzadoTests.swift \
  tests/app-ios/cruzado.mjs
git commit -m "test: conferência cruzada da obra criada, editada, vendida e apagada no app" -m "O roteiro da obra entra na conferência cruzada contra os emuladores: o app cria, edita, muda a fase, vende, desfaz e apaga pelas mutações das telas, e o site confere com o dados.js que o documento é exatamente o que ele gravaria, sem perder os campos que só ele conhece nem pôr o que a leitura acrescentaria."
```

### Task 37: A obra e os estados no checklist do aparelho e no CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`
- Modify: `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`

- [ ] **Step 1: Escrever**

Em `CLAUDE.md`:

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -100,7 +100,7 @@ Adicionar uma chave de topo em `db` **quebra as escritas em produção** se as r
 
 ### App nativo (app-ios/)
 
-App em SwiftUI que vai substituir o Capacitor (spec `docs/specs/2026-10-06-app-nativo-design.md`, planos `docs/plans/2026-10-06-app-nativo-*`, mockup aprovado da etapa 1 em `~/Documents/custta-mockups/nativo/etapa1/final.html`, com a borda de rolagem do `final-v2.html` e as decisões de 10/10 no `final-v4.html`). O `app-ios/Custta.xcodeproj` é escrito à mão no formato do Xcode 16 (pastas sincronizadas): arquivo novo dentro de `Custta/`, `CusttaTests/` ou `CusttaUITests/` entra no alvo sozinho; não deixe o Xcode subir o `objectVersion` (77), porque a CI usa o Xcode 26 (`tests/app-ios.test.cjs` barra). As regras moram no pacote `app-ios/CusttaNucleo`, puro e conferido contra os vetores do site; o app tem a identidade em `Custta/Identidade/` (tokens de cor e de vidro, aurora, globo, título escrito à mão, superfícies de vidro e cápsula de abas, escritos uma vez e reusados), as telas, o `ModeloApp` e a camada fina do Firebase em `Custta/Dados/`. A cara é a do PWA: cores só por tokens (`scripts/cores-app-ios.mjs`; rode o script depois de mudar), ícones do `icons.js` (`scripts/icones-app-ios.mjs`), logo e globo iguais aos do site (as guardas comparam), toda superfície por `.superficie(_:em:)` com a dose de vidro da tela (`VidroTokens`), nunca vidro dentro de vidro, a mesma borda de rolagem em toda tela que rola (`.bordaDeRolagem(abas:)`), e animação própria só olhando o Reduzir movimento. O vidro do iOS não acompanha escala nem transformação 3D, e a auditoria de contraste do Xcode não lê vidro: as cores são auditadas com superfícies sólidas (e os pares de texto sobre sólido, em Node, pelo `PARES_SOLIDOS`), e a leitura sobre o vidro de verdade é medida pelo laudo de leitura (`LeituraNoVidroUITests`: dois prints do mesmo quadro, com e sem o texto, e 4,5:1 no pior ponto de cada palavra; portão no Mac e na CI, que mede a lista sob a cápsula em menos rolagens; o texto que o sistema desenha, como os botões dos alertas, é medido contra o fundo em volta das letras, e as exceções têm nome no teste). No escuro, uma camada do tom do fundo sob o vidro do conteúdo (`VidroTokens.escurecimento`) e o globo mais fundo dentro do app fecham a leitura; mexer na dose de vidro, na aurora, no globo ou na borda pede o laudo de novo. Nenhum build vai ao TestFlight com o laudo reprovando no Mac. Pacotes Swift: só firebase-ios-sdk e GoogleSignIn-iOS, em versão exata, com o `Package.resolved` versionado (para atualizar, botão "resolver de novo" do workflow `app-ios`); a Roboto Medium do botão do Google é a única fonte embutida, travada por SHA-256. Em Debug o app aceita `CUSTTA_SERVICOS=falsos` (telas e testes de tela; dados `vitrine` por padrão, as obras do mockup, e `exemplo` nos testes) e `CUSTTA_EMULADORES=1` (emuladores, com uma chave falsa, para um pedido que escape deles ser recusado pela produção); o Release não tem nenhum dos dois. Os emuladores rodam num FirebaseApp próprio (`Composicao.nomeDoAppDosEmuladores`), para a sessão deles nunca ocupar a vaga da produção no keychain. Nenhum teste monta a composição com rede, e cada agente roda os testes no seu simulador (`CUSTTA_SIMULADOR=<udid>`). A CI (`app-ios.yml`) roda o núcleo, o build Release sem assinatura e os testes no simulador com os serviços falsos; os testes contra os emuladores e a conferência cruzada rodam no Mac e são obrigatórios antes de cada envio. O app nunca grava antes de ver os dados da conta (`Sincronizador`, erro `nao-carregado`, com o alerta do texto do site); conta sem documento conta como vista quando o servidor já respondeu a ela neste aparelho (marca `custta-servidor-respondeu` no `UserDefaults`, apagada junto com o cache). Telas que gravam: a mudança vem do núcleo (mutações de `Estado`, as mesmas regras do `dados.js`), o `ModeloApp.gravar` a aplica na hora (`Sincronizador.aplicar`; a tela anima na mesma transação) e a resposta do servidor segue pela pílula de sincronização. Folha com passos é `.folhaDoApp` em volta de um `NavigationStack` e `.passoDaFolha` em cada passo (voltar e borda do sistema; pergunta antes de descartar pelo ×, ao puxar e pelo escapar do VoiceOver); valor de dinheiro se digita sempre no `TecladoDeValor`. Cartão de vidro que cresce (um mês da lista, o "A vencer") é um `CartaoDaLista`: com o vidro aplicado ao próprio conteúdo, o iOS 27 estica o quadro de acessibilidade da primeira linha até o cartão inteiro. Sair segue o `cloud.js`: para a escuta, grava a marca `custta-limpar-cache` (`UserDefaults`), sai e apaga o cache; a abertura seguinte termina uma limpeza interrompida. Se apagar o cache falhar, a entrada fica bloqueada e o alerta "Finalizar saída" pede para limpar de novo, como o `cacheBloqueado` do site. Os identificadores de acessibilidade são contrato com os testes, inclusive a conferência cruzada. O Xcode da CI é fixo (`DEVELOPER_DIR` do 26.6). O `PrivacyInfo.xcprivacy` acompanha a política de privacidade do site: dado novo coletado entra nos dois. Envio: workflow `app-ios-testflight`, no botão, versão 2.0 no mesmo cadastro (`br.com.custta.app`). Pendências de aparelho: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md` e `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`. Até a conferência do PR 3 da etapa 2, o app grava numa conta de teste criada por `scripts/conta-demo.mjs --importar` com as obras exportadas pelo site (o arquivo, com dados pessoais, nunca entra no repositório).
+App em SwiftUI que vai substituir o Capacitor (spec `docs/specs/2026-10-06-app-nativo-design.md`, planos `docs/plans/2026-10-06-app-nativo-*`, mockup aprovado da etapa 1 em `~/Documents/custta-mockups/nativo/etapa1/final.html`, com a borda de rolagem do `final-v2.html` e as decisões de 10/10 no `final-v4.html`). O `app-ios/Custta.xcodeproj` é escrito à mão no formato do Xcode 16 (pastas sincronizadas): arquivo novo dentro de `Custta/`, `CusttaTests/` ou `CusttaUITests/` entra no alvo sozinho; não deixe o Xcode subir o `objectVersion` (77), porque a CI usa o Xcode 26 (`tests/app-ios.test.cjs` barra). As regras moram no pacote `app-ios/CusttaNucleo`, puro e conferido contra os vetores do site; o app tem a identidade em `Custta/Identidade/` (tokens de cor e de vidro, aurora, globo, título escrito à mão, superfícies de vidro e cápsula de abas, escritos uma vez e reusados), as telas, o `ModeloApp` e a camada fina do Firebase em `Custta/Dados/`. A cara é a do PWA: cores só por tokens (`scripts/cores-app-ios.mjs`; rode o script depois de mudar), ícones do `icons.js` (`scripts/icones-app-ios.mjs`), logo e globo iguais aos do site (as guardas comparam), toda superfície por `.superficie(_:em:)` com a dose de vidro da tela (`VidroTokens`), nunca vidro dentro de vidro, a mesma borda de rolagem em toda tela que rola (`.bordaDeRolagem(abas:)`), e animação própria só olhando o Reduzir movimento. O vidro do iOS não acompanha escala nem transformação 3D, e a auditoria de contraste do Xcode não lê vidro: as cores são auditadas com superfícies sólidas (e os pares de texto sobre sólido, em Node, pelo `PARES_SOLIDOS`), e a leitura sobre o vidro de verdade é medida pelo laudo de leitura (`LeituraNoVidroUITests`: dois prints do mesmo quadro, com e sem o texto, e 4,5:1 no pior ponto de cada palavra; portão no Mac e na CI, que mede a lista sob a cápsula em menos rolagens; o texto que o sistema desenha, como os botões dos alertas, é medido contra o fundo em volta das letras, e as exceções têm nome no teste). No escuro, uma camada do tom do fundo sob o vidro do conteúdo (`VidroTokens.escurecimento`) e o globo mais fundo dentro do app fecham a leitura; mexer na dose de vidro, na aurora, no globo ou na borda pede o laudo de novo. Nenhum build vai ao TestFlight com o laudo reprovando no Mac. Pacotes Swift: só firebase-ios-sdk e GoogleSignIn-iOS, em versão exata, com o `Package.resolved` versionado (para atualizar, botão "resolver de novo" do workflow `app-ios`); a Roboto Medium do botão do Google é a única fonte embutida, travada por SHA-256. Em Debug o app aceita `CUSTTA_SERVICOS=falsos` (telas e testes de tela; dados `vitrine` por padrão, as obras do mockup, e `exemplo` nos testes) e `CUSTTA_EMULADORES=1` (emuladores, com uma chave falsa, para um pedido que escape deles ser recusado pela produção); o Release não tem nenhum dos dois. Os emuladores rodam num FirebaseApp próprio (`Composicao.nomeDoAppDosEmuladores`), para a sessão deles nunca ocupar a vaga da produção no keychain. Nenhum teste monta a composição com rede, e cada agente roda os testes no seu simulador (`CUSTTA_SIMULADOR=<udid>`). A CI (`app-ios.yml`) roda o núcleo, o build Release sem assinatura e os testes no simulador com os serviços falsos; os testes contra os emuladores e a conferência cruzada rodam no Mac e são obrigatórios antes de cada envio. O app nunca grava antes de ver os dados da conta (`Sincronizador`, erro `nao-carregado`, com o alerta do texto do site); conta sem documento conta como vista quando o servidor já respondeu a ela neste aparelho (marca `custta-servidor-respondeu` no `UserDefaults`, apagada junto com o cache). Telas que gravam: a mudança vem do núcleo (mutações de `Estado`, as mesmas regras do `dados.js`), o `ModeloApp.gravar` a aplica na hora (`Sincronizador.aplicar`; a tela anima na mesma transação) e a resposta do servidor segue pela pílula de sincronização. Folha com passos é `.folhaDoApp` em volta de um `NavigationStack` e `.passoDaFolha` em cada passo (voltar e borda do sistema; pergunta antes de descartar pelo ×, ao puxar e pelo escapar do VoiceOver); valor de dinheiro se digita sempre no `TecladoDeValor`. As folhas da obra (`FolhaDaObra`, nova e editar) e da venda (`FolhaDaVenda`) seguem o mesmo molde, e o que uma folha pede a Obras depois de gravar (entrar na obra criada, trocar a obra por trás da folha, voltar e apagar) passa por `Folhas.navegar`. Os textos da obra, das fases e dos estados moram em `ObraEFases.swift`, no núcleo. O erro de gravação que não passa sozinho vira o alerta "Não salvou" uma vez por erro (`ModeloApp.alertaDeGravacao`, contado por `Sincronizador.confirmadas`); os outros avisos seguem no topo. Cartão de vidro que cresce (um mês da lista, o "A vencer") é um `CartaoDaLista`: com o vidro aplicado ao próprio conteúdo, o iOS 27 estica o quadro de acessibilidade da primeira linha até o cartão inteiro. Sair segue o `cloud.js`: para a escuta, grava a marca `custta-limpar-cache` (`UserDefaults`), sai e apaga o cache; a abertura seguinte termina uma limpeza interrompida. Se apagar o cache falhar, a entrada fica bloqueada e o alerta "Finalizar saída" pede para limpar de novo, como o `cacheBloqueado` do site. Os identificadores de acessibilidade são contrato com os testes, inclusive a conferência cruzada. O Xcode da CI é fixo (`DEVELOPER_DIR` do 26.6). O `PrivacyInfo.xcprivacy` acompanha a política de privacidade do site: dado novo coletado entra nos dois. Envio: workflow `app-ios-testflight`, no botão, versão 2.0 no mesmo cadastro (`br.com.custta.app`). Pendências de aparelho: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md` e `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`. Até a conferência do PR 3 da etapa 2, o app grava numa conta de teste criada por `scripts/conta-demo.mjs --importar` com as obras exportadas pelo site (o arquivo, com dados pessoais, nunca entra no repositório).
 
 ## UI
```

Em `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`:

```diff
--- a/docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md
+++ b/docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md
@@ -56,3 +56,30 @@ O app grava de verdade a partir desta etapa, e cada gravação regrava o documen
 - [ ] iPhone 13 mini ou SE, se tiver: com o teclado aberto na descrição, as sugestões e o "Salvar" cabem.
 - [ ] Modo avião: lance um gasto; a pílula mostra "Sem conexão"; ao voltar a internet, o gasto chega ao site.
 - [ ] Na conta de sempre (sem `custta-teste` no e-mail), tente lançar: aparece "Este build ainda não grava na sua conta" e nada muda no site.
+
+## PR 3: a obra, as fases e os estados
+
+- [ ] Na lista de obras, o + aparece ao lado da cápsula: "Nova obra" abre a folha com o nome, "Começou em", a área, o valor estimado e o orçamento, nessa ordem; o teclado sobe junto com a folha, já no nome.
+- [ ] Salve sem área: "Informe área construída maior que zero." em vermelho embaixo do campo; sem nome, a folha volta ao nome, sem mensagem.
+- [ ] Toque em "Valor estimado de venda": o teclado de valor abre ("Opcional" na linha; zero apaga o valor). O mesmo no orçamento.
+- [ ] Crie uma obra com área 3,125: a folha desce e a obra abre na tela dela; no site, a área é 3,125 m² (não 3.125).
+- [ ] Toque no lápis da barra: "Editar obra" vem preenchida (a área com vírgula) e com "Apagar obra" no fim; mude o nome e salve: muda no site também.
+- [ ] Feche a edição depois de mudar algo: "Você mudou esta obra." ("Descartar alterações" / "Continuar editando"); sem mudar nada, fecha direto.
+- [ ] "Apagar obra": a pergunta traz o nome e "Os N lançamentos dela serão perdidos. Não dá para desfazer."; "Apagar" volta à lista, a linha sai com animação e a obra some do site.
+- [ ] Numa obra em construção, "Marcar como pronta" (pílula sólida) troca a etiqueta para "Pronta · à venda" na hora, com uma vibração leve e sem perguntar; "Voltar pra construção" (pílula de vidro) desfaz. No site, a fase muda.
+- [ ] Numa obra pronta, "Registrar venda": o teclado de valor, depois "Data da venda" (hoje; o calendário vai do início da obra até hoje) e "Confirmar venda". A obra vira "Vendida em dd/mm/aa" e o indicador mostra a venda com o lucro (ou o prejuízo).
+- [ ] Na vendida, "Desfazer venda" pergunta "Desfazer a venda?" / "A obra volta pra “Pronta”."; confirmar volta para pronta no app e no site.
+- [ ] Numa obra vendida, o + abre a folha do gasto com a linha "Obra" (vem marcada a primeira obra aberta da lista) e a nota de que a vendida não recebe gasto; troque a obra e salve: o gasto aparece na obra escolhida, que toma o lugar da vendida por trás da folha.
+- [ ] Toque num gasto de uma obra vendida: a edição continua possível, sem a linha "Obra".
+- [ ] Conta sem obras (apague todas as obras da conta de teste, ou use outra conta de teste): "Nenhuma obra ainda." / "Toque no + para criar a primeira obra."; o + cria.
+- [ ] Modo avião logo depois de instalar (antes de o app ver os dados): o + avisa "Carregando suas obras…" em vez de abrir. O limite de 300 obras não precisa de teste no aparelho (o teste de tela cobre).
+- [ ] Modo avião com os dados já vistos: marque uma obra como pronta; a pílula mostra "Sem conexão"; ao voltar a internet, o site mostra a fase nova.
+- [ ] "Não salvou" (só se acontecer): o alerta "Não salvou na nuvem" aparece uma vez, com "Tentar de novo"; depois fica só a pílula, e tocar nela tenta de novo.
+- [ ] Texto Maior no máximo: as pílulas das ações crescem e o texto quebra; as folhas da obra e da venda não cortam nada à esquerda; a pílula da data para de crescer num ponto.
+- [ ] VoiceOver: as ações da fase são botões com o nome inteiro; a linha "Obra" lê o nome da obra escolhida; "Apagar obra" pergunta antes.
+- [ ] Nos quatro combos (claro e escuro, esmeralda e azul), o lucro e o prejuízo da obra vendida sobre o vidro: verde mais claro e rosa no escuro, verde mais escuro e vinho no claro (tokens novos, medidos a 4,5:1). Diga se o tom serve.
+- [ ] Na conta de sempre, tente criar uma obra ou mudar a fase: "Este build ainda não grava na sua conta" e nada muda no site.
+
+## Depois do OK do PR 3: a conta real
+
+- [ ] Com os itens acima marcados, o Orquestrador abre o PR da conta real (a guarda da conta de teste sai) e manda o build. Instale, entre na conta de sempre, lance um gasto de teste e apague-o; confira no site que ele entrou e saiu.
```


- [ ] **Step 2: Conferir**

Run: `node --test tests/docs.test.mjs 2>&1 | tail -3`
Expected: `ℹ fail 0`.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md \
  docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md
git commit -m "docs: a obra e os estados no checklist do aparelho e no CLAUDE.md" -m "O checklist do build do PR 3 e o passo da conta real; no CLAUDE.md, as folhas da obra e da venda, o navegar das folhas, os textos da parte 3 no núcleo e o Não salvou uma vez por erro."
```

**Ponto de controle do PR 3:** o Verniz confere as telas com os `parte3-*.png` (ações da fase nas três fases, venda 1 e 2, nova 0/1/erro/2, editar e apagar obra, "+ numa vendida", lista vazia e carregando, limite, sem conexão e "Não salvou"), nos quatro combos e na maior letra; `npm run test:app-ios:emuladores` e `npm run test:app-ios:cruzado` verdes no Mac; laudo e auditorias verdes no 18 Pro e no Pro Max. O Orquestrador manda o build; o Giovani marca o checklist do PR 3 na conta de teste e diz se o tom do lucro e do prejuízo sobre o vidro serve.

---

## PR 4 (app): a conta real

Só depois do OK do Giovani no checklist do build do PR 3. Sai a guarda que, no build do TestFlight, só deixava gravar em conta com `custta-teste` no e-mail: o app passa a gravar na conta de quem entra. Nada mais muda; o script da conta de teste continua no repositório para testar um build antes de gravar na conta de sempre.

### Task 38: O app grava na conta de quem entra

**Files:**
- Modify: `CLAUDE.md`
- Delete: `app-ios/Custta/Estado/ContaDeTeste.swift`
- Modify: `app-ios/Custta/Estado/ModeloApp.swift`
- Modify: `app-ios/Custta/Telas/FolhaDaObra.swift`
- Modify: `app-ios/Custta/Telas/FolhaDaVenda.swift`
- Modify: `app-ios/Custta/Telas/FolhaDoGasto.swift`
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Test (alterar): `app-ios/CusttaTests/GravacaoDoAppTests.swift`

**Interfaces:**
- Consumes: Tarefa 20 (`ModeloApp.gravar`).
- Produces: `ResultadoDaGravacao` sem o caso `.contaReal`.

- [ ] **Step 1: Tirar o teste da guarda e a guarda**

Em `app-ios/CusttaTests/GravacaoDoAppTests.swift`:

```diff
--- a/app-ios/CusttaTests/GravacaoDoAppTests.swift
+++ b/app-ios/CusttaTests/GravacaoDoAppTests.swift
@@ -27,13 +27,6 @@ struct GravacaoDoAppTests {
         #expect(transporte.gravacoes == 1)
     }
 
-    @Test func buildDoTestFlightSoGravaEmContaDeTeste() {
-        #expect(!ContaDeTeste.podeGravar(email: "giovani@exemplo.com", release: true), "a conta de sempre não grava no build de teste")
-        #expect(ContaDeTeste.podeGravar(email: "Giovani+Custta-Teste@gmail.com", release: true))
-        #expect(ContaDeTeste.podeGravar(email: "giovani@exemplo.com", release: false), "em Debug grava sempre")
-        #expect(!ContaDeTeste.podeGravar(email: nil, release: true))
-    }
-
     @Test func obraQueSumiuNaoGravaNada() async {
         let (m, transporte, _) = montar()
         await ate { m.sincronizador.dadosCarregados }
```


Em `CLAUDE.md`:

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -100,7 +100,7 @@ Adicionar uma chave de topo em `db` **quebra as escritas em produção** se as r
 
 ### App nativo (app-ios/)
 
-App em SwiftUI que vai substituir o Capacitor (spec `docs/specs/2026-10-06-app-nativo-design.md`, planos `docs/plans/2026-10-06-app-nativo-*`, mockup aprovado da etapa 1 em `~/Documents/custta-mockups/nativo/etapa1/final.html`, com a borda de rolagem do `final-v2.html` e as decisões de 10/10 no `final-v4.html`). O `app-ios/Custta.xcodeproj` é escrito à mão no formato do Xcode 16 (pastas sincronizadas): arquivo novo dentro de `Custta/`, `CusttaTests/` ou `CusttaUITests/` entra no alvo sozinho; não deixe o Xcode subir o `objectVersion` (77), porque a CI usa o Xcode 26 (`tests/app-ios.test.cjs` barra). As regras moram no pacote `app-ios/CusttaNucleo`, puro e conferido contra os vetores do site; o app tem a identidade em `Custta/Identidade/` (tokens de cor e de vidro, aurora, globo, título escrito à mão, superfícies de vidro e cápsula de abas, escritos uma vez e reusados), as telas, o `ModeloApp` e a camada fina do Firebase em `Custta/Dados/`. A cara é a do PWA: cores só por tokens (`scripts/cores-app-ios.mjs`; rode o script depois de mudar), ícones do `icons.js` (`scripts/icones-app-ios.mjs`), logo e globo iguais aos do site (as guardas comparam), toda superfície por `.superficie(_:em:)` com a dose de vidro da tela (`VidroTokens`), nunca vidro dentro de vidro, a mesma borda de rolagem em toda tela que rola (`.bordaDeRolagem(abas:)`), e animação própria só olhando o Reduzir movimento. O vidro do iOS não acompanha escala nem transformação 3D, e a auditoria de contraste do Xcode não lê vidro: as cores são auditadas com superfícies sólidas (e os pares de texto sobre sólido, em Node, pelo `PARES_SOLIDOS`), e a leitura sobre o vidro de verdade é medida pelo laudo de leitura (`LeituraNoVidroUITests`: dois prints do mesmo quadro, com e sem o texto, e 4,5:1 no pior ponto de cada palavra; portão no Mac e na CI, que mede a lista sob a cápsula em menos rolagens; o texto que o sistema desenha, como os botões dos alertas, é medido contra o fundo em volta das letras, e as exceções têm nome no teste). No escuro, uma camada do tom do fundo sob o vidro do conteúdo (`VidroTokens.escurecimento`) e o globo mais fundo dentro do app fecham a leitura; mexer na dose de vidro, na aurora, no globo ou na borda pede o laudo de novo. Nenhum build vai ao TestFlight com o laudo reprovando no Mac. Pacotes Swift: só firebase-ios-sdk e GoogleSignIn-iOS, em versão exata, com o `Package.resolved` versionado (para atualizar, botão "resolver de novo" do workflow `app-ios`); a Roboto Medium do botão do Google é a única fonte embutida, travada por SHA-256. Em Debug o app aceita `CUSTTA_SERVICOS=falsos` (telas e testes de tela; dados `vitrine` por padrão, as obras do mockup, e `exemplo` nos testes) e `CUSTTA_EMULADORES=1` (emuladores, com uma chave falsa, para um pedido que escape deles ser recusado pela produção); o Release não tem nenhum dos dois. Os emuladores rodam num FirebaseApp próprio (`Composicao.nomeDoAppDosEmuladores`), para a sessão deles nunca ocupar a vaga da produção no keychain. Nenhum teste monta a composição com rede, e cada agente roda os testes no seu simulador (`CUSTTA_SIMULADOR=<udid>`). A CI (`app-ios.yml`) roda o núcleo, o build Release sem assinatura e os testes no simulador com os serviços falsos; os testes contra os emuladores e a conferência cruzada rodam no Mac e são obrigatórios antes de cada envio. O app nunca grava antes de ver os dados da conta (`Sincronizador`, erro `nao-carregado`, com o alerta do texto do site); conta sem documento conta como vista quando o servidor já respondeu a ela neste aparelho (marca `custta-servidor-respondeu` no `UserDefaults`, apagada junto com o cache). Telas que gravam: a mudança vem do núcleo (mutações de `Estado`, as mesmas regras do `dados.js`), o `ModeloApp.gravar` a aplica na hora (`Sincronizador.aplicar`; a tela anima na mesma transação) e a resposta do servidor segue pela pílula de sincronização. Folha com passos é `.folhaDoApp` em volta de um `NavigationStack` e `.passoDaFolha` em cada passo (voltar e borda do sistema; pergunta antes de descartar pelo ×, ao puxar e pelo escapar do VoiceOver); valor de dinheiro se digita sempre no `TecladoDeValor`. As folhas da obra (`FolhaDaObra`, nova e editar) e da venda (`FolhaDaVenda`) seguem o mesmo molde, e o que uma folha pede a Obras depois de gravar (entrar na obra criada, trocar a obra por trás da folha, voltar e apagar) passa por `Folhas.navegar`. Os textos da obra, das fases e dos estados moram em `ObraEFases.swift`, no núcleo. O erro de gravação que não passa sozinho vira o alerta "Não salvou" uma vez por erro (`ModeloApp.alertaDeGravacao`, contado por `Sincronizador.confirmadas`); os outros avisos seguem no topo. Cartão de vidro que cresce (um mês da lista, o "A vencer") é um `CartaoDaLista`: com o vidro aplicado ao próprio conteúdo, o iOS 27 estica o quadro de acessibilidade da primeira linha até o cartão inteiro. Sair segue o `cloud.js`: para a escuta, grava a marca `custta-limpar-cache` (`UserDefaults`), sai e apaga o cache; a abertura seguinte termina uma limpeza interrompida. Se apagar o cache falhar, a entrada fica bloqueada e o alerta "Finalizar saída" pede para limpar de novo, como o `cacheBloqueado` do site. Os identificadores de acessibilidade são contrato com os testes, inclusive a conferência cruzada. O Xcode da CI é fixo (`DEVELOPER_DIR` do 26.6). O `PrivacyInfo.xcprivacy` acompanha a política de privacidade do site: dado novo coletado entra nos dois. Envio: workflow `app-ios-testflight`, no botão, versão 2.0 no mesmo cadastro (`br.com.custta.app`). Pendências de aparelho: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md` e `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`. Até a conferência do PR 3 da etapa 2, o app grava numa conta de teste criada por `scripts/conta-demo.mjs --importar` com as obras exportadas pelo site (o arquivo, com dados pessoais, nunca entra no repositório).
+App em SwiftUI que vai substituir o Capacitor (spec `docs/specs/2026-10-06-app-nativo-design.md`, planos `docs/plans/2026-10-06-app-nativo-*`, mockup aprovado da etapa 1 em `~/Documents/custta-mockups/nativo/etapa1/final.html`, com a borda de rolagem do `final-v2.html` e as decisões de 10/10 no `final-v4.html`). O `app-ios/Custta.xcodeproj` é escrito à mão no formato do Xcode 16 (pastas sincronizadas): arquivo novo dentro de `Custta/`, `CusttaTests/` ou `CusttaUITests/` entra no alvo sozinho; não deixe o Xcode subir o `objectVersion` (77), porque a CI usa o Xcode 26 (`tests/app-ios.test.cjs` barra). As regras moram no pacote `app-ios/CusttaNucleo`, puro e conferido contra os vetores do site; o app tem a identidade em `Custta/Identidade/` (tokens de cor e de vidro, aurora, globo, título escrito à mão, superfícies de vidro e cápsula de abas, escritos uma vez e reusados), as telas, o `ModeloApp` e a camada fina do Firebase em `Custta/Dados/`. A cara é a do PWA: cores só por tokens (`scripts/cores-app-ios.mjs`; rode o script depois de mudar), ícones do `icons.js` (`scripts/icones-app-ios.mjs`), logo e globo iguais aos do site (as guardas comparam), toda superfície por `.superficie(_:em:)` com a dose de vidro da tela (`VidroTokens`), nunca vidro dentro de vidro, a mesma borda de rolagem em toda tela que rola (`.bordaDeRolagem(abas:)`), e animação própria só olhando o Reduzir movimento. O vidro do iOS não acompanha escala nem transformação 3D, e a auditoria de contraste do Xcode não lê vidro: as cores são auditadas com superfícies sólidas (e os pares de texto sobre sólido, em Node, pelo `PARES_SOLIDOS`), e a leitura sobre o vidro de verdade é medida pelo laudo de leitura (`LeituraNoVidroUITests`: dois prints do mesmo quadro, com e sem o texto, e 4,5:1 no pior ponto de cada palavra; portão no Mac e na CI, que mede a lista sob a cápsula em menos rolagens; o texto que o sistema desenha, como os botões dos alertas, é medido contra o fundo em volta das letras, e as exceções têm nome no teste). No escuro, uma camada do tom do fundo sob o vidro do conteúdo (`VidroTokens.escurecimento`) e o globo mais fundo dentro do app fecham a leitura; mexer na dose de vidro, na aurora, no globo ou na borda pede o laudo de novo. Nenhum build vai ao TestFlight com o laudo reprovando no Mac. Pacotes Swift: só firebase-ios-sdk e GoogleSignIn-iOS, em versão exata, com o `Package.resolved` versionado (para atualizar, botão "resolver de novo" do workflow `app-ios`); a Roboto Medium do botão do Google é a única fonte embutida, travada por SHA-256. Em Debug o app aceita `CUSTTA_SERVICOS=falsos` (telas e testes de tela; dados `vitrine` por padrão, as obras do mockup, e `exemplo` nos testes) e `CUSTTA_EMULADORES=1` (emuladores, com uma chave falsa, para um pedido que escape deles ser recusado pela produção); o Release não tem nenhum dos dois. Os emuladores rodam num FirebaseApp próprio (`Composicao.nomeDoAppDosEmuladores`), para a sessão deles nunca ocupar a vaga da produção no keychain. Nenhum teste monta a composição com rede, e cada agente roda os testes no seu simulador (`CUSTTA_SIMULADOR=<udid>`). A CI (`app-ios.yml`) roda o núcleo, o build Release sem assinatura e os testes no simulador com os serviços falsos; os testes contra os emuladores e a conferência cruzada rodam no Mac e são obrigatórios antes de cada envio. O app nunca grava antes de ver os dados da conta (`Sincronizador`, erro `nao-carregado`, com o alerta do texto do site); conta sem documento conta como vista quando o servidor já respondeu a ela neste aparelho (marca `custta-servidor-respondeu` no `UserDefaults`, apagada junto com o cache). Telas que gravam: a mudança vem do núcleo (mutações de `Estado`, as mesmas regras do `dados.js`), o `ModeloApp.gravar` a aplica na hora (`Sincronizador.aplicar`; a tela anima na mesma transação) e a resposta do servidor segue pela pílula de sincronização. Folha com passos é `.folhaDoApp` em volta de um `NavigationStack` e `.passoDaFolha` em cada passo (voltar e borda do sistema; pergunta antes de descartar pelo ×, ao puxar e pelo escapar do VoiceOver); valor de dinheiro se digita sempre no `TecladoDeValor`. As folhas da obra (`FolhaDaObra`, nova e editar) e da venda (`FolhaDaVenda`) seguem o mesmo molde, e o que uma folha pede a Obras depois de gravar (entrar na obra criada, trocar a obra por trás da folha, voltar e apagar) passa por `Folhas.navegar`. Os textos da obra, das fases e dos estados moram em `ObraEFases.swift`, no núcleo. O erro de gravação que não passa sozinho vira o alerta "Não salvou" uma vez por erro (`ModeloApp.alertaDeGravacao`, contado por `Sincronizador.confirmadas`); os outros avisos seguem no topo. Cartão de vidro que cresce (um mês da lista, o "A vencer") é um `CartaoDaLista`: com o vidro aplicado ao próprio conteúdo, o iOS 27 estica o quadro de acessibilidade da primeira linha até o cartão inteiro. Sair segue o `cloud.js`: para a escuta, grava a marca `custta-limpar-cache` (`UserDefaults`), sai e apaga o cache; a abertura seguinte termina uma limpeza interrompida. Se apagar o cache falhar, a entrada fica bloqueada e o alerta "Finalizar saída" pede para limpar de novo, como o `cacheBloqueado` do site. Os identificadores de acessibilidade são contrato com os testes, inclusive a conferência cruzada. O Xcode da CI é fixo (`DEVELOPER_DIR` do 26.6). O `PrivacyInfo.xcprivacy` acompanha a política de privacidade do site: dado novo coletado entra nos dois. Envio: workflow `app-ios-testflight`, no botão, versão 2.0 no mesmo cadastro (`br.com.custta.app`). Pendências de aparelho: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md` e `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`. O app grava na conta de quem entra; a conta de teste da etapa 2 (`scripts/conta-demo.mjs --importar`, com as obras exportadas pelo site; o arquivo, com dados pessoais, nunca entra no repositório) continua disponível para testar um build antes de gravar na conta de sempre.
 
 ## UI
```

Apagar `app-ios/Custta/Estado/ContaDeTeste.swift`:

```bash
git rm app-ios/Custta/Estado/ContaDeTeste.swift
```

Em `app-ios/Custta/Estado/ModeloApp.swift`:

```diff
--- a/app-ios/Custta/Estado/ModeloApp.swift
+++ b/app-ios/Custta/Estado/ModeloApp.swift
@@ -267,8 +267,6 @@ final class ModeloApp {
         case naoCarregado
         /// A conta saiu no meio.
         case semConta
-        /// Build do TestFlight numa conta que não é de teste (até a conferência do PR 3): nada foi gravado.
-        case contaReal
     }
 
     /// Muda o estado na hora, pela regra do núcleo, e entrega o documento inteiro para gravar (o `save()` do site). A tela
@@ -278,7 +276,6 @@ final class ModeloApp {
         #if DEBUG
         if UserDefaults.standard.string(forKey: "custta.recusarGravacao") == "nao-carregado" { return .naoCarregado }
         #endif
-        guard ContaDeTeste.podeGravar(email: usuario?.email) else { return .contaReal }
         guard let novo = mudanca(sincronizador.estado) else { return .sumiu }
         do {
             try sincronizador.aplicar(novo)
```

Em `app-ios/Custta/Telas/FolhaDaObra.swift`:

```diff
--- a/app-ios/Custta/Telas/FolhaDaObra.swift
+++ b/app-ios/Custta/Telas/FolhaDaObra.swift
@@ -139,7 +139,6 @@ private struct FormularioDaObra: View {
     @State private var erroDoNome: String?
     @State private var erroDaArea: String?
     @State private var naoCarregado = false
-    @State private var contaReal = false
     @State private var limite = false
     @State private var apagando = false
     /// O foco no nome vale só ao abrir: a raiz da pilha reaparece ao voltar do teclado de valor.
@@ -276,8 +275,7 @@ private struct FormularioDaObra: View {
             guard let id = rascunho.obraId else { return }
             folhas.fechar { folhas.navegar(.apagar(id)) }
         })
-        .alert(ContaDeTeste.titulo, isPresented: $contaReal) { Button("OK", role: .cancel) {} } message: { Text(ContaDeTeste.mensagem) }
-        .pausaOFundo(enquanto: naoCarregado || limite || contaReal)
+        .pausaOFundo(enquanto: naoCarregado || limite)
     }
 
     private func salvar() {
@@ -293,7 +291,6 @@ private struct FormularioDaObra: View {
         switch modelo.gravar({ $0.editandoObra(id, campos) }) {
         case .gravou, .sumiu, .semConta: folhas.fechar()
         case .naoCarregado: naoCarregado = true
-        case .contaReal: contaReal = true
         }
     }
 
@@ -304,7 +301,6 @@ private struct FormularioDaObra: View {
         switch modelo.gravar({ $0.criandoObra(obraNova(campos, id: id, hoje: dataLocalISO(.now, fuso: .current))) }) {
         case .gravou: folhas.fechar { folhas.navegar(.entrar(id)) }
         case .naoCarregado: naoCarregado = true
-        case .contaReal: contaReal = true
         case .sumiu: limite = true
         case .semConta: folhas.fechar()
         }
```

Em `app-ios/Custta/Telas/FolhaDaVenda.swift`:

```diff
--- a/app-ios/Custta/Telas/FolhaDaVenda.swift
+++ b/app-ios/Custta/Telas/FolhaDaVenda.swift
@@ -66,7 +66,6 @@ private struct PassoDaDataDaVenda: View {
     @Environment(\.paleta) private var paleta
     @State private var erro: String?
     @State private var naoCarregado = false
-    @State private var contaReal = false
 
     var body: some View {
         let obra = modelo.sincronizador.estado.obras.first { $0.id == obraId }
@@ -109,8 +108,7 @@ private struct PassoDaDataDaVenda: View {
                 }
                 .tint(paleta.cor(.texto))
         }
-        .alert(ContaDeTeste.titulo, isPresented: $contaReal) { Button("OK", role: .cancel) {} } message: { Text(ContaDeTeste.mensagem) }
-        .pausaOFundo(enquanto: naoCarregado || contaReal)
+        .pausaOFundo(enquanto: naoCarregado)
     }
 
     private func confirmar(inicio: String, hoje: String) {
@@ -124,7 +122,6 @@ private struct PassoDaDataDaVenda: View {
         switch modelo.gravar({ $0.registrandoVenda(obraId, valor: valor, data: rascunho.data) }) {
         case .gravou, .sumiu, .semConta: folhas.fechar()
         case .naoCarregado: naoCarregado = true
-        case .contaReal: contaReal = true
         }
     }
 }
```

Em `app-ios/Custta/Telas/FolhaDoGasto.swift`:

```diff
--- a/app-ios/Custta/Telas/FolhaDoGasto.swift
+++ b/app-ios/Custta/Telas/FolhaDoGasto.swift
@@ -273,7 +273,6 @@ private struct PassoDosDetalhes: View {
     @State private var erroDoCartao: String?
     @State private var erroDaDescricao: String?
     @State private var naoCarregado = false
-    @State private var contaReal = false
     @State private var apagando = false
     @State private var sugestaoEscolhida: String?
 
@@ -350,11 +349,6 @@ private struct PassoDosDetalhes: View {
         } message: {
             Text("O gasto continua aqui; nada foi salvo ainda.")
         }
-        .alert(ContaDeTeste.titulo, isPresented: $contaReal) {
-            Button("OK", role: .cancel) {}
-        } message: {
-            Text(ContaDeTeste.mensagem)
-        }
         .modifier(PerguntaDeApagar(apresentada: $apagando, obraId: rascunho.obraId, gasto: rascunho.editado) { pedido in
             folhas.fechar { folhas.apagar(pedido) }
         })
@@ -584,8 +578,6 @@ private struct PassoDosDetalhes: View {
             folhas.fechar { folhas.destacar(ids, novo: novo) }
         case .naoCarregado:
             naoCarregado = true
-        case .contaReal:
-            contaReal = true
         case .sumiu, .semConta:
             folhas.fechar()
         }
```

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -19,7 +19,6 @@ struct ObraView: View {
     @State private var alvoDoApagar: Gasto?
     @State private var perguntando = false
     @State private var naoCarregado = false
-    @State private var contaReal = false
     /// "Desfazer venda" tocado: a pergunta do site.
     @State private var desfazendo = false
     /// Muda a cada ação da fase feita aqui: a vibração leve do mockup (a de outro aparelho não vibra).
@@ -108,7 +107,6 @@ struct ObraView: View {
         })
         .onChange(of: perguntando) { _, agora in if !agora { fecharLinha() } }
         .alert(modelo.mensagemDeNaoCarregado, isPresented: $naoCarregado) { Button("OK", role: .cancel) {} }
-        .alert(ContaDeTeste.titulo, isPresented: $contaReal) { Button("OK", role: .cancel) {} } message: { Text(ContaDeTeste.mensagem) }
         .background {
             Color.clear
                 .alert(textoDeDesfazerVenda.titulo, isPresented: $desfazendo) {
@@ -203,7 +201,6 @@ extension ObraView {
             modelo.gravar { e in p.grupoId.map { e.apagandoCompra($0, daObra: p.obraId) } ?? e.apagandoGasto(p.gastoId, daObra: p.obraId) }
         }
         if resultado == .naoCarregado { naoCarregado = true; return }
-        if resultado == .contaReal { contaReal = true; return }
         guard resultado == .gravou else { return }
         Task { @MainActor in
             try? await Task.sleep(for: .milliseconds(500))
```


- [ ] **Step 2: Ver passar**

Run: `node --test tests/app-ios.test.cjs 2>&1 | grep -E "^ℹ (pass|fail)"`; `xcodebuild build-for-testing "${XB[@]}"` e `-only-testing:CusttaTests -only-testing:CusttaUITests/GastoUITests`.
Expected: guardas verdes; nenhum aviso de compilador; `CusttaTests` verde (102 testes) e os 17 de `GastoUITests` verdes.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md \
  app-ios/Custta/Estado/ContaDeTeste.swift \
  app-ios/Custta/Estado/ModeloApp.swift \
  app-ios/Custta/Telas/FolhaDaObra.swift \
  app-ios/Custta/Telas/FolhaDaVenda.swift \
  app-ios/Custta/Telas/FolhaDoGasto.swift \
  app-ios/Custta/Telas/ObraView.swift \
  app-ios/CusttaTests/GravacaoDoAppTests.swift
git commit -m "feat: o app grava na conta de quem entra (sai a guarda da conta de teste)" -m "Com o checklist do PR 3 aprovado na conta de teste, o build do TestFlight passa a gravar na conta de quem entra: sai a guarda que recusava lançar, editar e apagar fora de uma conta com custta-teste no e-mail, com o alerta e o teste dela."
```

**Ponto de controle do PR 4:** `npm run test:app-ios:emuladores` e `npm run test:app-ios:cruzado` verdes no Mac; o Orquestrador manda o build; o Giovani entra na conta de sempre, lança um gasto de teste e o apaga, e confere no site.

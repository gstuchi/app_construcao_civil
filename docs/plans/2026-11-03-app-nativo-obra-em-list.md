# A obra em List (etapa 4 do app nativo) — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> Neste time, o Forja implementa uma tarefa por vez e o Lupa revisa cada uma antes da próxima. Ninguém faz commit, push ou PR sem o Orquestrador pedir; quando ele pedir, valem os comandos de commit de cada tarefa.

**Goal:** Tirar o bloqueio da App Store trocando a estrutura da tela da obra: de ScrollView com LazyVStack para uma `List`, com um cartão por mês numa linha.
- No iOS 26, a LazyVStack entra em laço de layout ao arrastar na maior letra numa obra de lista curta. Por isso o teste está pulado nele desde o #99.
- A tela não muda.
- É um PR só, "A obra na List", e ele fecha o TestFlight da troca, antes do marco 2.

**Architecture:** As peças da obra continuam as de hoje (`ObraView`, `BlocosDaObra`, `PecasDaObra`); só o contêiner muda.
- **Linhas:** cada peça vira uma linha da `List` (`.plain`, sem recuo, separador nem fundo), e o cartão de cada mês é uma linha só.
- **A borda de 16 pt** vem da margem da `List`, e não do recuo da linha. Na `List`, a célula é o elemento de acessibilidade, então o quadro do VoiceOver fica o de hoje. Onde a peça é sozinha na linha (o título, a cápsula, a soma dos achados), uma vista vazia do UIKit no fundo dela faz da célula um contêiner, e o anel abraça a peça, como hoje.
- **O rolar até o gasto salvo** precisa de uma ponte do UIKit (`PonteDaRolagem`). O `scrollTo` da `List` só acha a linha, que é o cartão inteiro, e trata a âncora fracionária como o centro. A mesma ponte leva a pílula ao topo na lupa, segura a linha do alto quando o Tamanho do Texto muda com a obra rolada e dá a janela da `List` ao teclado da busca, que fecha quando o campo passa de meia tela além da tela, como hoje. Ela é o segundo risco do PR.
- **Debug:** a `List` ganha um gancho próprio de rolagem fixa para os testes de tela. Os testes passam a rolar até a peça abaixo da dobra antes de lê-la.

**Decisões do Giovani para este plano** (03/11; a tabela de Decisões dá o porquê):
1. **A estrutura.** A obra vai para a `List` com um cartão por mês numa linha. A linha por gasto saiu.
2. **Um PR com dois riscos.** "A obra na List" leva a estrutura e a ponte do UIKit, os dois escritos no corpo do PR. O merge
   fica fora do automático e só sai com o OK dele.
3. **A célula gigante** segue aceita até a medida no iPhone dele com o Instruments, com teto de ~1 s por parada. Acima
   disso, volta a ele.
4. **O VoiceOver e a obra pesada** se provam numa sessão só, no iPhone dele, com uma versão de Debug do ramo pelo Xcode e
   `CUSTTA_DADOS=pesada`. É o portão antes do merge, e ele roda. O iPhone dele é recente e roda iOS 27: a CI do iOS 26
   segue como o pior caso.
5. **Tocar no vão** entre as linhas não fecha mais a linha aberta. O alcance inteiro do toque que sai (também o título, a
   cápsula, os blocos de número, o cabeçalho do mês e os gastos por tópico) foi achado depois e vai a ele no checklist.

**Decidido pelo Orquestrador, a contar ao Giovani** (03/11, pela delegação para decisão com recomendação clara): a
auditoria da obra na maior letra fica no topo, nos dois sistemas; o bloco A pagar ganha auditoria própria; a letra que muda
com a obra rolada vira conserto do app, na ponte; e os dois achados da obra rolada ficam como problema conhecido (Decisões e
Como entregar). Em 04/11, também pela delegação: o commit da vitrine na frente do PR (1).

**Tech Stack:** SwiftUI no iOS 26 (Swift 6 estrito; Xcode 26.6 na CI), Swift Testing, XCTest e XCUITest. Nada muda no site, no núcleo nem no formato do estado.

**De onde vem.**
- As provas estão em `~/.claude/projects/-Users-giovanistuchi-Documents-app-construcao-civil/etapa4-roteiros/`:
  - `prumo-1c-ios26/QUATRO-ESTRUTURAS.md`: as quatro estruturas da LazyVStack, medidas em 02/11;
  - `prumo-list/` (`LEIA-ME.md` e `paridade.md`): o protótipo da `List` de 02/11 e a lista do que muda;
  - `prumo-list-linha/`: a linha por gasto, descartada, a causa do voltar mais escuro e o rolar até o gasto, de 03/11.
- A decisão é do Giovani, de 03/11: a `List`, com um cartão por mês.
- O corte saiu do conselho de 03/11 (Decisões). O registro está em `prumo-plano-obra-list/conselho-decisao.md`.
- Mockup aprovado: `~/Documents/custta-mockups/nativo/etapa4/` (a obra da parte 1). A tela não muda: os prints de hoje são a referência.

**Como este plano foi escrito.** O código de cada tarefa saiu de fatias: um commit por tarefa, num clone da `origin/main` `08512b3`, cada uma conferida antes da seguinte. A `main` de 04/11 (`04b057e`) não mudou nada em `app-ios` (só o README, o teste dele, as imagens de `docs/img` e o script das capturas da loja), e a ponta foi à CI por cima dela.
- **Compilação:** sem aviso novo, no Xcode do Mac.
- **Testes da tarefa:** no simulador iOS 26.5 do Mac. O "ver falhar" deste texto é a saída real.
- **A tela:** prints da obra nas 22 cenas, comparados pixel a pixel com os de hoje.
- **Na ponta:**
  - as seis suítes da obra, mais Afazeres e FolhaDaObra, no 26.5 e no 27 (127 testes de tela e 12 de unidade, sem queda nos dois, em 04/11), e os laudos que leem a obra no 26.5;
  - runs completos da CI do iOS 26 em ramos `proto/`. O primeiro (41706879156) achou:
    - cinco testes fora das seis suítes lendo a obra abaixo da dobra;
    - o gancho que brigava com o UIKit na busca;
    - o A vencer que abria tarde na VM lenta;
    - o custo do laudo que refazia o print.
    Os das duas pontas anteriores (41750989997 e 41763664501) caíram em quatro testes cada um, nenhum da obra (Como
    entregar); o desta ponta é o run 41873791727 (`proto/obra-em-list-plano-17`, 04/11): na 1ª tentativa, `nucleo`, `app-etapa3`, `app-etapa3-b`, `laudo-etapa3` e `auditoria` verdes; os outros cinco (`app`, `laudo`, `laudo-parte3`, `laudo-etapa3-b` e `app-etapa3-c`) não pegaram máquina ("not acquired by Runner", falta de macOS arm64 no GitHub) e rodam na 2ª tentativa, com o resultado no PR;
  - as sondas da o4 (10 vezes) e da obra pesada na maior letra (3 vezes), só no job delas, e a do × da busca (6 vezes, na
    ponta);
  - três revisões às cegas (Opus) do plano gerado. A 1ª: 2 bloqueios, 11 "deve consertar" e 12 menores; os bloqueios (o anel
    do VoiceOver na `List` e o conserto da lupa fora do texto) e os "deve consertar" estão consertados nas fatias ou escritos
    nas Decisões e no "Como entregar". A 2ª: nenhum bloqueio, 2 "deve consertar" (a prova da busca na VM era de outro
    teclado; digitar com a lista deslizando) e 9 menores, consertados nas fatias ou no texto. O teclado dos arrastos longos,
    achado junto, também: o `onScrollVisibilityChange` não dispara na `List`. A 3ª, só do que mudou: 1 bloqueio (a régua do
    teclado dentro da medida `@Sendable` dava dois avisos de isolamento), 1 "deve consertar" (com a ponte desligada caem
    quatro testes, e não cinco) e 5 menores, todos consertados;
  - os prints `main` × ponta das 22 cenas, que acharam a v1 a 400 5,33 pt abaixo da `main` (a fração da linha do alto presa
    a 0 no vão entre duas linhas; Decisões). Os menores que não entraram estão em "Depois do PR".

O texto de cada tarefa foi gerado das fatias: arquivo novo entra inteiro, e arquivo alterado entra em diff.

## Global Constraints

- **Plataforma:** iOS 26.0 mínimo, iPhone. Nada que só exista no SDK do iOS 27. A CI compila com o Xcode 26.6 (Swift 6.3.3).
  O Mac tem o 27 e um runtime 26.5 para reproduzir o que só o 26 mostra. A VM lenta do iOS 26 só se prova na CI.
- **Swift:** 6, com concorrência estrita e nenhum aviso de compilador novo.
- **Dependências:** nenhuma nova.
- **Estado:** o formato não muda, e as `firestore.rules` também não.
- **Língua:** português no código, nos identificadores, nos comentários e na interface.
- **A tela não muda.** A obra sai igual à de hoje nos prints das 22 cenas, nos dois temas, na letra padrão e na maior. O
  limite é a diferença máxima de ruído medida entre dois prints de hoje: ≤ 13/255 na área do conteúdo.
- **Ajustes de acessibilidade:** o quadro de cada peça para o VoiceOver é o de hoje (x 16, largura da coluna; a cápsula a 16
  pt do sólido; o título, a cápsula e a soma dos achados com a largura deles, e não a da linha). A letra máxima, o Negrito, o Aumentar contraste, o Reduzir transparência e o Reduzir movimento seguem
  valendo. Nenhum teste de tela é afrouxado.
- **Vidro:** nunca vidro dentro de vidro. O cartão do mês é um vidro só, numa linha da `List`.
- **Debug:** ganchos de teste só em `#if DEBUG`. O build de Release não leva nenhum deles: `RolagemFixaDaLista`,
  `AncoraDaRolagemFixa`, `TrocaDeLetraDoTeste` e o `avisarCaminho` da ponte. Confere-se pelo `nm`, com `RaizView` e
  `ModeloApp` de controle positivo (memória `release-sem-ganchos-conferir-por-nm`), e o `npm run test:unit` lê os ganchos
  em todo Swift do app.
- **Commits:** autor só `Giovani Stuchi <stuchigiovani@gmail.com>`, sem `Co-Authored-By` e sem rodapé. Título conventional
  em português com acento, corpo em prosa, um commit por tarefa, branch e PR, nunca direto na `main`.
- **Simuladores:** um por agente (`CUSTTA_SIMULADOR=<udid>`). Os testes de tela rodam com `-collect-test-diagnostics never`.

## Decisões

As do Giovani estão marcadas com a data. As quatro que o conselho levou a ele em 03/11 (o PR com dois riscos, a célula
gigante, o VoiceOver e a obra pesada no iPhone) ele decidiu como o plano recomendava, por volta das 14h35. As do item 9 (a
auditoria na maior letra) foram decididas pelo Orquestrador, pela delegação do Giovani para decisão com recomendação clara
(regra de 21/10), e estão marcadas como "Orquestrador, a contar ao Giovani".

| Decisão | Escolha | Por quê |
| --- | --- | --- |
| A estrutura (Giovani, 03/11) | `List` com um cartão por mês numa linha | A linha por gasto, com o vidro do mês em fatias, deixava uma faixa clara nas emendas (vidro vendo vidro). O cartão por mês saiu idêntico ao de hoje (`prumo-list-linha/LEIA-ME.md`) |
| Tocar fora das linhas (o vão: Giovani, 03/11; o resto vai a ele no checklist) | Não fecha mais a linha aberta: no vão entre as linhas, no título, na cápsula, nos blocos de número, no cabeçalho do mês e nos gastos por tópico. Rolar, tocar outra linha e tocar o A pagar ainda fecham | Hoje, um toque na pilha que nenhuma peça usa fecha a linha aberta; na `List`, esse toque sai. O aceite de 03/11 foi do vão (item 6 da paridade). A revisão às cegas achou o alcance inteiro, que está no checklist do aparelho (11) para ele dizer se serve |
| A célula gigante (Giovani, 03/11, com os números inteiros) | Aceita até a medida no iPhone dele pelo Instruments, com teto de ~1 s por parada; acima disso, volta a ele | O mês de 38 gastos da obra pesada é uma célula de 13.848 pt na maior letra. Na VM da CI, em 02/11, as paradas de 1 s ou mais somaram 9,4 e 28,9 s (hoje, 1,7 e 6,7 s), e o 1º arrasto saiu a 10,9 e 7,6 s da abertura (hoje, 3,8 e 4,2 s). Parte disso é o próprio XCUITest consultando a tela. No Mac, sem freio, nenhuma parada passa de 250 ms. Na sonda de 03/11 (run 41707295783, 3 rodadas), nenhuma trava: abertura de 18,7 a 46,7 s; as paradas de 1 s ou mais somaram 4,7, 14,0 e 39,6 s, a maior de 7,2 s. A sonda da ponta mede de novo (Como entregar) |
| Um PR com dois riscos (Giovani, 03/11: exceção à regra de um risco por PR) | "A obra na List" leva a estrutura e a ponte do UIKit, com os dois riscos escritos no corpo e o merge esperando o OK do Giovani | Decisão do conselho de 03/11 (abaixo). Com a ponte depois, a `main` ficaria com o gasto salvo fora da vista (o `mostrar` roda também na edição, `FolhaDoGasto.swift:645`) e com o teste da maior letra caindo. Com a ponte antes, sobre a LazyVStack, ela escreveria na rolagem que trava no iOS 26, com a o4 pulada, sem provar nada da `List` |
| O corte e a ordem (conselho, 03/11) | Um PR. Primeiro, os testes adaptados, o laudo, a auditoria na maior letra e o rótulo da pílula, provados no Mac na estrutura de hoje. Depois a `List`, o gancho e a o4 sem pulo (1º push), a ponte num push próprio e, no fim, o iOS 27 e as sondas | Três lentes, crítica às cegas. A auditoria (a T4 do conselho) foi para antes da `List` pela decisão do item 9 (abaixo): a obra auditada só no topo e o A pagar à parte valem nas duas estruturas. Descartados: dois PRs, com a `List` antes e um rolar provisório (regressão visível na edição; o teste da maior letra cai), e a o4 sem pulo só no último push (os runs mais informativos ficariam com ela pulada). Registro em `prumo-plano-obra-list/conselho-decisao.md` |
| O quadro da cápsula (item 2 da paridade) | Sem recuo dentro da célula da cápsula: do sólido para baixo, uma `Section`, e os 16 pt vêm do espaço antes dela | Com o recuo de 4 pt dentro da célula, o anel do VoiceOver da cápsula ficava 4 pt mais alto e o teste da grade media 12, não 16. O Giovani não aceitou mudar o anel. Medido: espaço entre `Section`s é o maior dos dois lados, então só a `Section` que começa no sólido fecha 8 pt acima e 16 abaixo da cápsula |
| A ponte do UIKit (item 3 da paridade) | Uma marca (vista vazia, com a própria chave) na linha acesa e na pílula; a ponte sobe dela até a UICollectionView e anda até o meio do gasto ou leva a pílula ao topo. Com a linha à vista (edição), vai direto; senão, o cartão vai ao topo e ela tenta a cada quadro até a lista parar de se medir, com teto de ~1 s. Com o gasto num A vencer fechado, ele abre no tempo de hoje. Sem forçar o layout. Quando a letra ou o filtro mudam, segura a linha do alto até a lista assentar (10 quadros com a mesma altura), com teto de 3 s | O `scrollTo` com âncora fracionária parou a 1ª parcela em y −3062 (3/3), e o da pílula não rola uma linha já à vista. Tempo fixo e uma tentativa só viram moeda na VM (conselho); por isso também a espera da letra é por assentar, e não 1,5 s fixos (revisão às cegas). `-custta.semPonte` (Debug) desliga a ponte para provar que a vigiam o A vencer e o g024 na maior letra, o da busca e o da letra (o do gasto salvo passa sem ela: o gasto novo é o 1º do cartão do mês, que a reserva leva ao topo); o aviso do caminho prova que a edição vai direto |
| O voltar mais escuro (item 8 da paridade) | Nada muda no app. O laudo deixa o quadro do voltar de fora, como já deixa a barra de status e o indicador de início | Causa provada em 03/11: o vidro do voltar, do sistema, assenta segundos depois de a tela abrir; com o texto apagado, na `List`, de 1 a 8 s, e o laudo fotografava aos 2 s (`prumo-list-linha/voltar/`). O voltar não tem texto do app. Descartado: refazer o print sem texto até a barra bater. Na CI, 36 de 37 cenas chegaram à 3ª tentativa, e o `laudo` foi de 26 para 53 min |
| O teclado da busca | O `.scrollDismissesKeyboard(.interactively)` de hoje, e o campo fecha o teclado quando o dedo o rola meia tela além da tela (`onGeometryChange` do campo contra a janela da `List`, que a ponte dá; só com a fase da rolagem) | Hoje, o arrasto curto deixa o teclado aberto, e os longos o fecham porque o campo sai da janela da LazyVStack, meia tela além da borda. Na `List`, a célula com o foco fica viva: só com o `.interactively`, o teclado seguia aberto depois de 12 arrastos; com o `.immediately` (1ª versão do plano), fechava já no arrasto curto (1ª revisão às cegas); com o `onScrollVisibilityChange` (2ª versão), não fechava nunca, porque ele não dispara na `List` (o campo foi a y −2.846 sem um evento). Medido em arrastos de ~77 pt sem impulso: na `main` (26.5), o teclado fecha no 9º arrasto para cima e no 15º para baixo; na ponta (26.5 e 27), no 10º e no 15º. O arrasto curto com impulso não fecha nas duas (na ponta, ele para o campo em y −111, a ~370 pt da régua), e os 12 longos fecham nas duas. Fechar ao sair da tela (folga 0) fecharia no 4º, no 10º e no curto, antes de hoje: descartado. Só com o dedo: quando os dados mudam, a `List` refaz as linhas e o campo pula. O `.ignoresSafeArea(.keyboard)` da 1ª versão saiu: a corrida da 1ª letra com o teclado subindo, que ele evitava (3 em 5), a ponte resolve segurando a linha do alto quando o filtro muda (5 em 5 no lugar, no Mac, sonda de 03/11), e com ele o "Limpar a busca" podia ficar sob o teclado |
| O gancho da rolagem fixa (Debug) | Segura a linha que ficou no alto, pela fração dela, e não o número. Anda preso ao fim do conteúdo que a `List` já mediu | Sem o limite, as cenas do fim (99999) andavam ~229 passos além dele, no vazio, e a parte 3 podia auditar uma tela sem nada. Quando os dados mudam, a `List` volta as linhas de cima da tela à altura estimada e o UIKit compensa a rolagem. Segurando o número, a cena "busca, achados" do laudo parava 300 pt abaixo da pílula. Em fração, e não em pontos: na troca de letra da auditoria, uma folga em pontos passava do fim da linha e a auditoria perdia os textos (12 achados sem elemento na obra do `testOrcamentoNoMaiorTamanho`) |
| O rótulo da pílula de ação (item 11 da paridade) | `labelStyle(.titleAndIcon)` e `labelIconToTitleSpacing(8)` no `PilulaDaAcao` | Dentro da `List`, o `Label` ganha o estilo da linha (ícone numa coluna) e o texto anda alguns pt. O título e ícone segura o alinhamento, mas a `List` afasta o ícone do texto 8 pt a mais; a folga fixa nos 8 pt de fora deixa os prints iguais aos de hoje no 26.5 e no 27. Descartados: um `LabelStyle` próprio (1 px de diferença na vertical) e o `labelReservedIconWidth(0)` (desmonta o rótulo) |
| A auditoria da obra na maior letra (item 9; Orquestrador, a contar ao Giovani, 03/11) | A obra (a v1) é auditada só no topo, nos dois sistemas, e volta a valer na CI do iOS 26; a parte 3 segue com a v2 a 800 e no fim e a v3 no fim, e as ações, os afazeres, a pílula e o A vencer da v1 rolada ficam sem auditoria na maior letra (problema conhecido). O bloco A pagar ganha auditoria própria na maior letra, no alto da vitrine das peças (`-custta.vitrineAPagar`), com mutação que cai. A letra que muda com a obra rolada vira conserto do app, na ponte, com teste próprio | A auditoria troca a letra em volta de cada auditoria (iOS 26 e 27). Na `List` rolada, isso tirava a obra do lugar (10 achados sem elemento; conserto na ponte) e pegava a célula se medindo (2 achados com elemento no A pagar, inteiros na tela: problema conhecido). Descartados: exceção por identificador nos dois textos (outra rolagem traz outros textos da mesma célula) e investigar a célula sem prazo |
| A linha do alto no vão | A fração da linha do alto, no gancho dos testes e na ponte, pode ser negativa: quando o alto da parte à vista cai no vão de 12 pt entre duas linhas, o ponto fica no vão (`linhaDoAlto`, função pura com teste) | Os prints `main` × ponta de 04/11 acharam a v1 a 400 5,33 pt abaixo da `main`, nos dois temas e nos dois sistemas, com o conteúdo igual. O alto (y 400) caía no vão entre duas linhas, a 1ª linha abaixo dele começava em 405,33, e a fração presa a 0 (`max(0, …)`, desde a troca dos pontos pela fração, para a auditoria que muda a letra) segurava o topo dela. Na ponte, a mesma trava fazia a lista pular até 12 pt quando a letra ou o filtro mudavam com o alto num vão. Negativa, a fração devolve o alto ao vão e escala com a letra; a dentro da linha não muda. Achado e decidido em 04/11 (Orquestrador) |
| A lupa, o foco e o filtro | A pílula vai ao topo quando a lista assenta (ou com a última medida, se ela não assenta em 30 quadros), e o foco vem logo depois. Quando o filtro da busca muda os dados, a ponte segura a linha do alto, como na letra que muda | Na VM da CI, a pílula subia 160 pt durante a digitação, com o campo sob a barra e o × fora do alcance (sondas 41738960913, 1 de 4, e 41743119168, 2 de 6, já com a espera da lupa): a `List` reestima as linhas de cima quando os dados mudam, e o UIKit nem sempre compensa. Com o conserto (sonda 41749639956, 6 rodadas, na pilha anterior, com o teclado de lá), a pílula ficou em y 129 nas 6; o × limpou em 4, e as outras 2 foram toques perdidos da VM. Na ponta desta pilha, a mesma sonda: nas 6 rodadas, a pílula ficou em y 129 antes e depois de abrir o A vencer, e o × limpou a busca (run 41873797898, `proto/obra-em-list-sonda-x17`, 04/11; rodadas de 173 a 442 s). Outra mudança de dados com a busca aberta (outro aparelho apaga um gasto) não passa pela ponte: mesma causa, sem conserto aqui. Num aparelho rápido, a espera é de um ou dois quadros |
| O VoiceOver e a obra pesada no iPhone (Giovani, 03/11) | Uma versão de Debug do ramo no iPhone dele, pelo Xcode, com `CUSTTA_DADOS=pesada`, numa sessão só, antes do merge: ele confere o VoiceOver (foco depois de salvar e de apagar, anel e ordem de leitura) e o Controle por Voz, e o Prumo grava as paradas da obra pesada no Instruments. É o portão do merge (Como entregar) | O simulador não roda o VoiceOver nem o Controle por Voz, e os dados falsos só existem em Debug. A obra pesada entra nos falsos nesta troca (10). O build da sessão sai com `SWIFT_OPTIMIZATION_LEVEL=-O`, que mantém o `DEBUG` e os falsos: em `-Onone`, uma parada acima de 1 s poderia ser da falta de otimização, e não da célula |
| O anel do VoiceOver na `List` (achado da revisão às cegas) | Uma vista vazia do UIKit (`QuadroProprio`) no fundo do título, da cápsula e da soma dos achados | Sozinha numa linha, a peça virava a célula inteira para o VoiceOver: a cápsula com 370 pt de largura (269 hoje) e a soma também (266 hoje). Com a vista, a célula vira um contêiner, e os 31 identificadores em comum com a `main` têm o mesmo quadro. Descartado: a peça num `VStack` com `.accessibilityElement(children: .contain)`, que manteve os 370 pt |

## Como entregar

- **Um PR, num worktree novo, a partir da `origin/main` atualizada.** Nada entra na `main` antes dele. A `main` fica no
  `04b057e` de 04/11 (a estrutura de hoje, com a o4 pulada no iOS 26; de `08512b3` para cá, nada em `app-ios`: o README,
  o teste dele, as imagens de `docs/img` e o script das capturas da loja) até o merge.
- **Uma tarefa por vez.** O Forja segue os passos e faz o commit da tarefa; o Lupa revisa antes da próxima: o diff, os testes
  da tarefa e uma mutação nas linhas que ela escreve. Achado menor vai para o fim do PR, num commit só.
- **A ordem e os pushes** (decisão do conselho, 03/11):
  1. **Tarefas 1 a 5, só no Mac.** Elas provam na estrutura de hoje que nada muda:
     - a vitrine passa no dia 3, no 4 e num dia comum, e sai igual à da `main` no dia comum;
     - o rótulo da pílula sai com os prints iguais;
     - os testes adaptados passam no 26.5 e no 27, e a mutação ainda morde;
     - o laudo da obra sai igual palavra por palavra;
     - a auditoria da obra no topo e a do A pagar passam, e a mutação no A pagar cai.
     Nenhuma CI é gasta numa estrutura que não chega à `main`.
  2. **Tarefas 6 a 8: a `List`, o gancho e a o4 sem pulo.** Depois da 8, push e PR em
     rascunho: o 1º run já lê a o4 com a `List`, e a CI do iOS 26 é lida antes da tarefa seguinte (memória
     `ci-do-ios-26-cedo-no-pr-de-tela`). Antes do push, as suítes da obra rodam no 26.5 (8, Step 3): caem, de
     propósito, só os testes que dependem da ponte, que ainda não entrou. Escreva no rascunho quais são, com a saída.
  3. **Tarefa 9, a ponte, num push próprio.** Se uma instabilidade nova aparecer no iOS 26, ela tem dono.
  4. **Tarefas 10 e 11: a obra pesada nos falsos e o checklist do aparelho.** Depois, o portão da
     ponta e a sessão no iPhone (abaixo).
- **O portão da ponta, antes de sair do rascunho:**
  - no Mac, no 26.5 e no 27: as seis suítes da obra (Obra, Gasto, Busca, Fases, FolhasDeOrigem, Estados), mais Afazeres e
    FolhaDaObra, e os testes de unidade da ponte e dos falsos (`PonteDaRolagemTests`, `DadosDeExemploTests`);
  - `npm run test:unit` (o `verificar` da CI): ele lê todo Swift do app (ganchos em `#if DEBUG`, animação com Reduzir
    movimento, o `onChange` do destaque na `ObraView`);
  - no 26.5: a (b) 10 vezes, o cruzado com os emuladores (`CUSTTA_SIMULADOR=<udid> npm run test:app-ios:cruzado`) e os
    prints das 22 cenas contra os de hoje. A (b) é a sonda `Sonda26UITests.testListB1Arrastos` do protótipo de 02/11 (abrir
    a busca com a lista à vista e arrastar, a trava que a `List` resolveu), no patch 0003 de
    `etapa4-roteiros/prumo-list/patches/etapa4-obra-em-list/`. A vigia do app (`Sonda26.swift` e o gancho do `-custta.sonda`)
    nasce no 0001, que traz também uma obra pesada própria, e o 0003 reescreve a `ObraView` do protótipo: nenhum dos dois se
    aplica na ponta. Quem roda é o Prumo, num clone do scratch: porta à mão o `Sonda26.swift` do 0001 com a mudança do 0003,
    o gancho do `-custta.sonda` e o `Sonda26UITests` do 0002 e do 0003. O critério é nenhuma trava em 10;
  - o laudo inteiro de leitura no Pro Max, comparado palavra por palavra com o da `main`;
  - as auditorias na maior letra, no 26.5 e no 27: a da obra (no topo), a do A pagar, a da vitrine das peças, a da parte 3
    e a do Orçamento;
  - o `nm` do Release: nenhum símbolo dos ganchos (`RolagemFixaDaLista`, `AncoraDaRolagemFixa`, `TrocaDeLetraDoTeste`,
    `avisarCaminho`), e `RaizView` e `ModeloApp` presentes (controle positivo);
  - na CI: o run completo verde, mais as duas sondas só do job no mesmo commit. Uma roda a o4 10 vezes; a outra, a obra
    pesada na maior letra 3 vezes, lendo a abertura e a soma das paradas com o teste calado. Se a o4 travar uma vez, o PR
    não sai: a troca não provou o que promete. A pesada é informativa: o critério dela é o do iPhone (~1 s por parada).
    Quem roda as duas é o Prumo, num ramo `proto/` com o commit da ponta. O código delas está no `fatias.bundle` de
    `prumo-plano-obra-list/`, nos ramos `sonda-o4` (`446b95c`) e `sonda-pesada` (`c937f99` e `03fddcd`), feitos sobre a
    ponta de 03/11: vão à ponta a vigia do app, as sondas e o workflow, e não a `vitrinePesada` do `c937f99`, que a
    10 já traz. O `ci-list.py`, em `prumo-list/scripts/`, deixa só o job `app-etapa3-c` no workflow (`if: false`
    nos outros, `-only-testing` por método). Comando: `gh workflow run app-ios.yml --ref proto/<ramo>`, e a leitura pelo log
    do job. A terceira sonda é a do × da busca, 6 rodadas na ponta (`SondaXUITests`, em `ferramentas/`, com o print de cada
    rodada): a pílula no lugar em todas, e um × que não limpa só passa como toque perdido se o print da rodada mostrar isso.
    Na ponta desta pilha: nas 6 rodadas, a pílula ficou em y 129 antes e depois de abrir o A vencer, e o × limpou a busca (run 41873797898, `proto/obra-em-list-sonda-x17`, 04/11; rodadas de 173 a 442 s)
- **As provas que o conselho pediu antes do plano** (03/11; `conselho-decisao.md`), na ponta:
  - o iOS 27: o portão acima, nos dois sistemas;
  - o anel do título e da cápsula: a guarda de largura na grade e na busca (6), com mutação que cai;
  - o realce ao tocar o Orçamento e os Afazeres: nos prints a ~0,9 s do toque longo, nenhum realce cinza no bloco inteiro do Orçamento nem dos Afazeres, na ponta (prints de 03/11) e na `main` (04/11), que saem iguais (sonda `SondaConselhoUITests.testRealceDoLink`; prints em `prumo-plano-obra-list/realce-list/` e `realce-main/`);
  - o caminho da ponte: o aviso "direto" no teste da edição (9) e, na obra pesada na maior letra, com o freio
    (~3× mais lento, a M6 do conselho): na obra pesada na maior letra, a ponte foi direto ao gasto editado, em 1,3 s sem o freio e em 2,0 s com ele, e a linha ficou inteira à vista (de y 287,67 a 668,33, entre a barra em 116 e as abas em 794), na ponta de 04/11 no 26.5;
  - os primeiros arrastos logo ao abrir: no protótipo de 02/11, a `List` levou 17 a 18 arrastos lentos até a lupa, contra 16
    hoje (`prumo-list/paridade.md`); depois disso, os dois mostram o mesmo trecho. No simulador isso mede o XCUITest numa
    thread ocupada, e não o dedo: fica na sessão no iPhone;
  - os rótulos do Controle por Voz e a célula gigante ao apagar, acender e abrir o A vencer (a M3): o simulador não tem
    Controle por Voz, e a M3 mede paradas, que são do Instruments. Os dois ficam na sessão no iPhone.
- **A sessão no iPhone do Giovani, portão do merge** (decisão dele, 03/11). Uma versão de Debug do ramo no iPhone dele (iOS
  27), com o Texto Maior no máximo nos Ajustes do iPhone. O build sai com `SWIFT_OPTIMIZATION_LEVEL=-O` no Debug (mantém o
  `DEBUG` e os falsos; em `-Onone`, a parada podia ser da falta de otimização, e não da célula), pela linha de comando, sem
  mexer no projeto; pelo Xcode, o ajuste vai só na cópia local e não entra em commit:
  ```bash
  xcodebuild build -project app-ios/Custta.xcodeproj -scheme Custta -configuration Debug -destination 'id=<udid do iPhone>' \
    -derivedDataPath <dd do aparelho> -allowProvisioningUpdates SWIFT_OPTIMIZATION_LEVEL=-O
  xcrun devicectl device install app --device <udid do iPhone> <dd do aparelho>/Build/Products/Debug-iphoneos/Custta.app
  xcrun devicectl device process launch --device <udid do iPhone> \
    -e '{"CUSTTA_SERVICOS":"falsos","CUSTTA_CONTA":"senha","CUSTTA_DADOS":"pesada","CUSTTA_ABRIR":"obra:v1"}' br.com.custta.app
  ```
  Numa sessão só:
  - ele confere o VoiceOver: o anel de cada peça, o foco depois de salvar e de apagar (também a compra toda) e o rotor de
    cabeçalhos pelos meses; e o Controle por Voz ("Mostrar nomes"): Orçamento, A pagar, Afazeres e um lançamento;
  - ele toca no Orçamento e nos Afazeres (nenhum realce cinza no bloco inteiro), arrasta logo depois de abrir (os primeiros
    arrastos andam como os de depois) e edita o último gasto do mês mais cheio (ao salvar, a lista não vai ao topo do mês
    e volta);
  - ele digita na busca logo depois de um arrasto curto, com a lista ainda deslizando: o teclado fica, e a letra entra;
  - o Prumo grava no Instruments enquanto ele abre a obra, rola até o mês mais cheio e volta, apaga uma linha dele e lança
    um gasto (com o traço gravando, ele volta à lista de obras e abre a obra pesada de novo: a abertura pelo `devicectl` fica
    antes do traço). Reabra o app só pelo `devicectl`: pelo ícone, a versão de Debug sobe com os serviços reais e a conta
    dele, e a sessão apagaria e lançaria gastos de verdade: `xcrun xctrace record --device <udid do iPhone> --template 'Time Profiler' --instrument Hangs --attach Custta
    --time-limit 3m --output <pasta>/sessao.trace`;
  - teto de ~1 s por parada. Acima disso, a célula gigante volta a ele, e o merge espera.
  O iPhone dele é recente: o que for liso nele não prova um iPhone antigo, e a CI do iOS 26 segue como o pior caso.
- **Merge com o OK do Giovani** (exceção à regra de um risco por PR; Decisões). O Orquestrador leva a ele:
  - os prints de hoje × `List` (claro e escuro, letra padrão e maior, 402 e 375 pt);
  - o tempo de cada job contra o teto (`app` e `app-etapa3` 90 min; `laudo-etapa3` 75; os outros 60);
  - os números das sondas;
  - as decisões do item 9 (a auditoria da obra na maior letra só no topo, o A pagar à parte, os problemas conhecidos), que
    afrouxam uma guarda de acessibilidade e foram tomadas pelo Orquestrador;
  - o alcance do toque que fecha a linha aberta (Decisões).
- **CI: o que já cai sem relação com a obra.** No último run do #99 (41464095512, a `main` de hoje), o iOS 26 deu duas
  quedas que não são da estrutura:
  - `AuditoriaUITests.testParte3NoMaiorTamanho`, no `laudo-parte3`: "partially unsupported" nas folhas, com elemento
    (memória `auditoria-ios-26-letra-vai-e-volta`);
  - `OrcamentoUITests.testDefinirPorTotal`, no `app-etapa3`: uma tecla perdida (memória `toque-perdido-na-vm-lenta-do-ios-26`).
  No run completo da ponta anterior (41750989997, 03/11), mais quatro, nenhuma da obra, cada uma com a prova no xcresult:
  - `testContrasteDaFolhaNosDoisTemas` (`auditoria`): um aviso do sistema, "Ready for Apple Intelligence", caiu sobre o
    título da folha do gasto no meio da auditoria de contraste (está no print da queda). Ele pode derrubar qualquer PR;
  - `testFolhasDeOrigemNoMaiorTamanho` (`laudo-etapa3-b`): "Text clipped" sem elemento na folha do tópico Cerâmica, aberta
    do Orçamento, uma tela que este PR não toca;
  - `testContrasteDaParte3NosDoisTemas` (`laudo-parte3`): a auditoria passou do tempo na tela de Obras, com a VM levando
    ~5 s por consulta;
  - `DetalheDoTopicoUITests.testArrastarOUltimoGastoDesceAFolha` (`app-etapa3-b`): o arrasto para a esquerda não mostrou o
    "Apagar" na folha da Alvenaria, aberta do Orçamento (a obra nem está na árvore), num teste que levou 146 s, contra ~60
    nos outros runs: um toque perdido da VM.
  No run da pilha anterior (41763664501, 04/11), mais quatro testes, em três jobs, nenhum da obra:
  - `VitrineUITests.testLancamentosNaLinhaMono` (`app`): a vitrine nos dias 3 e 4 do mês, em que a `main` também cai até
    este PR entrar; o conserto é a 1;
  - dois testes das `FolhasDeOrigemUITests` (`app-etapa3`): o app não abriu ("Timed out while launching application" e
    "Failed to get background assertion"), falha da VM;
  - `LeituraNoVidroUITests.testLeituraEmAjustes` (`laudo`): "Ajustes não abriu"; o vídeo mostra Obras na tela, sem banner,
    depois do toque na aba: um toque perdido da VM.

  No portão do Mac numa pilha intermediária (04/11), duas quedas fora da obra, as duas instáveis também na `main`: o
  `FolhaDaObraUITests.testNomeVazioVoltaAoNomeSemMensagem` (26.5; o toque na área não leva o foco, na folha de nova obra,
  aberta da lista de obras; repetido 3 vezes, caiu 2 na ponta e 1 na `main`) e o `FasesUITests.testNaoCarregadoAvisaEMantemAVenda`
  (27; o alerta não veio em 3 s; repetido, 3 de 3 nas duas). No portão da ponta, 127 testes de tela e 12 de unidade, sem queda nos dois sistemas.
  No Mac, as três auditorias passam na `main` e na `List`, também com o freio. Se voltarem, repita só o job (`gh run rerun <id>
  --failed`) e diga no PR. O × da busca (`testBuscarSemAcentoPeloTopicoEPelaDescricao`, "o × do texto limpa a busca"):
  repita o job uma vez; a mesma queda duas vezes seguidas não é moeda (memória `mesma-cena-caindo-traz-o-conserto`). Achado
  "sem elemento" da auditoria: na obra, não é moeda (item 9, abaixo); numa tela que o PR não toca, conta como as outras
  quedas desta lista.
- **CI: o tempo do `app`.** No 1º run completo (41706879156), o `app` foi cancelado pelo teto de 90 min, aos 92,7: o preparo
  (build e 1º boot) levou ~40 min, contra ~19 na `main` (41464095512), e as suítes andaram quase iguais. No run da pilha
  anterior (41763664501), 83,3 min. O run da ponta: o run 41873791727 (`proto/obra-em-list-plano-17`, 04/11): na 1ª tentativa, `nucleo`, `app-etapa3`, `app-etapa3-b`, `laudo-etapa3` e `auditoria` verdes; os outros cinco (`app`, `laudo`, `laudo-parte3`, `laudo-etapa3-b` e `app-etapa3-c`) não pegaram máquina ("not acquired by Runner", falta de macOS arm64 no GitHub) e rodam na 2ª tentativa, com o resultado no PR. Queda por tempo: repita só o job. Se o `app` passar de ~85 min numa VM normal, mova uma suíte dele (Fases ou
  Obra, ~5 min) para o `app-etapa3-b`, que levou 30 de 60.
- **Problemas conhecidos** (decisão do item 9; Orquestrador, a contar ao Giovani):
  - **A obra rolada na auditoria do Xcode.** Com a obra rolada na maior letra, a auditoria acha "Text clipped" em dois textos
    do bloco A pagar: "3 vencimentos" (a etiqueta) e "Parcelas e gastos futuros" (a nota). Caiu 3 de 3 no 26.5 e 2 de 2 no
    27. É a célula da `List` se medindo durante a troca de letra da auditoria: na tela, os dois estão inteiros (print em
    `prumo-plano-obra-list/prototipo-letra/fl9/aud-rolada-depois.png`). A LazyVStack de hoje também não é firme nesse teste
    no iOS 27 (passou 1 de 2). Por isso, a obra é auditada só no topo, e o A pagar, à parte (5).
  - **O que fica sem auditoria na maior letra.** Da v1 rolada: as ações, os afazeres, a pílula e o A vencer. A vitrine das
    peças audita o alto dela e uma tela rolada (as rolagens de 900 a 3600 caíam todas na mesma tela), e a parte 3, a v2 a 800
    e no fim e a v3 no fim. O conserto natural vem depois: cada peça no alto da vitrine por argumento, como o
    `-custta.vitrineAPagar`.
  - **O A pagar da vitrine é uma cópia do rótulo do bloco.** A mutação prova as peças comuns (etiqueta, número, nota), mas
    uma mudança só no `BlocosDaObra.aPagar` (espaço, `lineLimit`, `fixedSize`) passaria. Fica para depois: extrair o rótulo
    (`RotuloDoAPagar`) e usá-lo nos dois.
- **TestFlight:** o merge leva a tag `etapa4-obra-em-list`, e o TestFlight sai dela com o OK do Giovani, antes do 1º merge
  do marco 2. Vai junto o checklist do aparelho (11). Nenhum PR do marco 2 mexe na obra antes do checklist.

Os comandos rodam na raiz do worktree, cada agente no seu simulador:

```bash
export CUSTTA_SIMULADOR=<udid do seu simulador>          # nunca o de outro agente
DESTINO=$(node scripts/simulador-ios.mjs)
XB=(-project app-ios/Custta.xcodeproj -scheme Custta -destination "$DESTINO"
    -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile)
# compilar uma vez por mudança (no seu DerivedData) e rodar só o que interessa
xcodebuild build-for-testing "${XB[@]}" -derivedDataPath <seu dd> 2>&1 | grep -E "error:|warning:|TEST BUILD" | tail -5
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:<alvo> 2>&1 | tail -5
```

**Prints antes × depois** (as tarefas que dizem "a tela não muda"). As ferramentas são do Prumo, na pasta durável dele, e
servem a qualquer simulador: `prints-da-obra.sh` tira as 22 cenas da obra com o fundo parado, e `compara-prints.py` compara
pixel a pixel só a área do conteúdo. A barra e a cápsula ficam de fora: o vidro adaptativo delas muda sozinho entre
aberturas.

```bash
F=~/.claude/projects/-Users-giovanistuchi-Documents-app-construcao-civil/etapa4-roteiros/prumo-plano-obra-list/ferramentas
# o produto de antes, uma vez por PR: a main num worktree dela e noutro DerivedData (caminhos por extenso)
git -C <raiz do repositório> worktree add <pasta da main> origin/main
(cd <pasta da main> && xcodebuild build-for-testing "${XB[@]}" -derivedDataPath <dd da main> 2>&1 | tail -1)
bash $F/prints-da-obra.sh <udid> <dd da main>/Build/Products/Debug-iphonesimulator/Custta.app <prints>/antes
bash $F/prints-da-obra.sh <udid> <seu dd>/Build/Products/Debug-iphonesimulator/Custta.app <prints>/depois-<tarefa>
python3 -I $F/compara-prints.py <prints>/antes <prints>/depois-<tarefa>
```
Uma cena que falte numa das pastas derruba a comparação. Na tarefa que só olha algumas cenas, `--cenas '<regex>'` compara só
elas, e a falta de qualquer uma delas também derruba.

---

## PR "A obra na List" (app)

**Branch:** `feat/obra-em-list`. **Título:** `feat: obra numa List, com um cartão por mês numa linha`.

**Tamanho:** +581 −41 linhas no app. Delas, +212 −6 só existem em Debug: o gancho da rolagem fixa (+108 −3), o gancho da
troca de letra e o aviso do caminho da ponte (+52), o A pagar da vitrine (+26), a obra pesada nos falsos (+22) e os
lançamentos da vitrine (+4 −3). O que vai ao Release é +369 −35. Por tarefa: a ponte, +315 −19 (com o que ela troca na
`ObraView`, o teclado da busca, a tentativa direta e a linha do alto); a `List`, +53 −20 (com o quadro próprio do anel); o
rótulo da pílula, +5. Quatro linhas que a `List` põe e a ponte troca contam nas duas. Os testes somam +336 −51, e o
checklist do aparelho, +41.

**Os dois riscos**, escritos no corpo do PR, com a exceção à regra pedida ao Giovani (Decisões):
1. **A estrutura.** A obra deixa a LazyVStack e vira uma `List` (UICollectionView). O que pode quebrar:
   - os laços de layout do iOS 26 (sem trava até aqui: a (b) 10/10 no 26.5 e a o4 10/10 na CI, run 41706961537);
   - a célula gigante (o mês de 13.848 pt na maior letra);
   - o quadro do VoiceOver, porque na `List` o elemento é a célula;
   - os testes que leem peça fora da tela, porque na `List` o XCUITest só vê a linha que está na tela (a LazyVStack a
     expunha a ~1.700 pt).
2. **A ponte do UIKit**: o rolar até o gasto salvo, a lupa até a pílula, a obra que segura a linha do alto quando o
   Tamanho do Texto muda e a janela da `List` para o teclado da busca. Ela depende de a `List` ser uma UICollectionView com
   as vistas da linha dentro dela, que é detalhe do SwiftUI. Se um iOS novo mudar isso, a ponte não rola: a lista fica no
   topo do cartão, a pílula fica onde está, a letra que muda tira a obra do lugar e o teclado não fecha nos arrastos
   longos. Caem dois testes da maior letra do `GastoUITests` (o A vencer e o g024), o da busca, o da letra e o do teclado.
   Eles são a guarda: com a ponte desligada, caem os quatro que ela rola (o do gasto salvo passa, porque o gasto novo é o
   1º do cartão do mês, que a reserva leva ao topo), e o aviso do caminho prova que a edição com a linha à vista vai direto.

**O que a CI do PR prova.**
- A o4 sem pulo no iOS 26, em todo run desde o 1º push.
- As seis suítes da obra com os testes adaptados.
- O laudo e a auditoria da obra e da parte 3.
- O rolar até o gasto salvo na maior letra: a 1ª parcela no A vencer, e o gasto editado no fim de um mês longo.
- A lupa levando a pílula ao topo, com o campo fora da barra, e o laudo da busca com o campo e a soma à vista.
- O teclado da busca como hoje: o arrasto curto o deixa, os longos o fecham.
- A vitrine em qualquer dia do mês.
- A auditoria da obra na maior letra no topo e a do A pagar, de volta à CI.
- Cada job dentro do teto.

**O que ela não prova:**
- a taxa de trava que sobra (por isso a sonda da o4 roda 10 vezes);
- a célula gigante, porque a obra pesada não está nos dados da CI (por isso a sonda pesada);
- o iOS 27 (portão no Mac);
- o VoiceOver de verdade e o aparelho: a sessão no iPhone do Giovani, antes do merge, e o checklist do TestFlight.

**Entre as tarefas:** a `main` não muda; o PR é um só. Dentro do PR, entre a 6 e a 9, caem, de
propósito, os testes que dependem da ponte: a lista está no fim da 8, com a saída do 26.5.

### Task 1: A vitrine com os dois lançamentos mais recentes em qualquer dia do mês

O `VitrineUITests.testLancamentosNaLinhaMono` cai nos dias 3 e 4 de todo mês, na `main` também: no run 41763664501 (CI da
pilha anterior, 04/11) e, no Mac, no build da `main` do mesmo dia (`XCTAssertEqual failed: ("2") is not equal to ("3")`).
- **Por quê.** A vitrine das peças põe na linha mono os dois primeiros gastos do mês mais recente e um de R$ 1 bilhão, e os
  gastos dela são contados a partir de hoje: o mais recente é de anteontem, o seguinte de 4 dias atrás. Nos dias 3 e 4, o mês
  corrente só tem um, e o cartão sai com 2 linhas, e não 3.
- **O conserto.** Os dois mais recentes, de qualquer mês. Nos outros dias, são os mesmos de antes. É código de Debug (a
  vitrine não vai ao Release), na frente do PR para a CI dele não cair nesses dias. Decidido pelo Orquestrador em 04/11.
  Até este PR entrar, a `main` cai nos dias 3 e 4 (Como entregar, "CI: o que já cai").

**Files:**
- Modify: `app-ios/Custta/Falsos/VitrineDasPecas.swift`

**Interfaces:**
- Consumes: `listaDaObra(_:hoje:)`.
- Produces: nada.

- [ ] **Step 1: Implementar**

Em `app-ios/Custta/Falsos/VitrineDasPecas.swift`:

```diff
--- a/app-ios/Custta/Falsos/VitrineDasPecas.swift
+++ b/app-ios/Custta/Falsos/VitrineDasPecas.swift
@@ -57,10 +57,11 @@ struct VitrineDasPecas: View {
                 }
                 .accessibilityElement(children: .contain)
                 .accessibilityIdentifier("vitrine-topicos")
-                // Os lançamentos na linha mono: os dois primeiros do mês mais recente e um de R$ 1 bilhão, que não cabe ao
-                // lado do título (deixaria menos de 120 pt para ele) e desce para baixo dele.
+                // Os lançamentos na linha mono: os dois mais recentes, de qualquer mês (nos dias 3 e 4, o mês corrente
+                // só tem um), e um de R$ 1 bilhão, que não cabe ao lado do título (deixaria menos de 120 pt para ele) e
+                // desce para baixo dele.
                 let topicos = mapaDeTopicos(estado.config.topicosProprios)
-                let lancamentos = Array(listaDaObra(casa, hoje: hoje).meses.first?.gastos.prefix(2) ?? []) + [Self.gigante]
+                let lancamentos = Array(listaDaObra(casa, hoje: hoje).meses.flatMap(\.gastos).prefix(2)) + [Self.gigante]
                 CartaoDaLista {
                     ForEach(Array(lancamentos.enumerated()), id: \.element.id) { i, gasto in
                         if i > 0 { LinhaFina().padding(.horizontal, Grade.recuo) }
```

- [ ] **Step 2: Ver falhar e ver passar, no dia deslocado**

O teste já existe; a prova desloca o hoje da vitrine, só no clone e nunca em commit. O `desloc.py` (na pasta das
ferramentas) faz a vitrine contar o hoje com `CUSTTA_DESLOC` dias a mais e o `Abrir.swift` repassar a variável do executor ao
app. Compile a `main` e este commit com ele, e rode com o hoje no dia 3, no 4 e num dia comum (o 10). No Mac, em 04/11, foram
os desvios −1, 0 e +6:
```bash
python3 $F/desloc.py <raiz do clone>     # nos dois clones; desfaça depois com git checkout -- app-ios
for d in -1 0 6; do
  # a main: só o da linha mono
  TEST_RUNNER_CUSTTA_DESLOC=$d xcodebuild test-without-building "${XB[@]}" -derivedDataPath <dd da main> \
    -collect-test-diagnostics never -only-testing:CusttaUITests/VitrineUITests/testLancamentosNaLinhaMono 2>&1 \
    | grep -E "Test Case .*(passed|failed)|error:"
  # este commit: as cinco da vitrine
  TEST_RUNNER_CUSTTA_DESLOC=$d xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> \
    -collect-test-diagnostics never -only-testing:CusttaUITests/VitrineUITests 2>&1 | grep -E "Test Case .*(passed|failed)|error:"
done
```
Expected (a `main` cai nos dias 3 e 4 e passa no 10; este commit passa nos três, com as cinco da vitrine):
```
# main, dia 3 (desvio -1)
VitrineUITests.swift:84: error: -[CusttaUITests.VitrineUITests testLancamentosNaLinhaMono] : XCTAssertEqual failed: ("2") is not equal to ("3") - []
Test Case '-[CusttaUITests.VitrineUITests testLancamentosNaLinhaMono]' failed (14.597 seconds).
# main, dia 4 (desvio 0)
VitrineUITests.swift:84: error: -[CusttaUITests.VitrineUITests testLancamentosNaLinhaMono] : XCTAssertEqual failed: ("2") is not equal to ("3") - []
Test Case '-[CusttaUITests.VitrineUITests testLancamentosNaLinhaMono]' failed (13.227 seconds).
# main, dia 10 (desvio 6)
Test Case '-[CusttaUITests.VitrineUITests testLancamentosNaLinhaMono]' passed (48.134 seconds).
# este commit, dia 3 (desvio -1)
Test Case '-[CusttaUITests.VitrineUITests testBarraDeTopicosComALegenda]' passed (42.573 seconds).
Test Case '-[CusttaUITests.VitrineUITests testBlocosNaGradeDeBordas]' passed (14.213 seconds).
Test Case '-[CusttaUITests.VitrineUITests testLancamentosNaLinhaMono]' passed (44.377 seconds).
Test Case '-[CusttaUITests.VitrineUITests testNumeroMonoLidoInteiroECabeNaLetraMaxima]' passed (33.696 seconds).
Test Case '-[CusttaUITests.VitrineUITests testTituloECapsulaDeMetadadosNaGrade]' passed (15.330 seconds).
# este commit, dia 4 (desvio 0)
Test Case '-[CusttaUITests.VitrineUITests testBarraDeTopicosComALegenda]' passed (35.795 seconds).
Test Case '-[CusttaUITests.VitrineUITests testBlocosNaGradeDeBordas]' passed (13.929 seconds).
Test Case '-[CusttaUITests.VitrineUITests testLancamentosNaLinhaMono]' passed (45.511 seconds).
Test Case '-[CusttaUITests.VitrineUITests testNumeroMonoLidoInteiroECabeNaLetraMaxima]' passed (31.785 seconds).
Test Case '-[CusttaUITests.VitrineUITests testTituloECapsulaDeMetadadosNaGrade]' passed (12.783 seconds).
# este commit, dia 10 (desvio 6)
Test Case '-[CusttaUITests.VitrineUITests testBarraDeTopicosComALegenda]' passed (35.622 seconds).
Test Case '-[CusttaUITests.VitrineUITests testBlocosNaGradeDeBordas]' passed (12.266 seconds).
Test Case '-[CusttaUITests.VitrineUITests testLancamentosNaLinhaMono]' passed (40.284 seconds).
Test Case '-[CusttaUITests.VitrineUITests testNumeroMonoLidoInteiroECabeNaLetraMaxima]' passed (29.661 seconds).
Test Case '-[CusttaUITests.VitrineUITests testTituloECapsulaDeMetadadosNaGrade]' passed (12.771 seconds).
```

- [ ] **Step 3: A vitrine igual à de hoje num dia comum**

No dia 10, as duas versões põem as mesmas linhas. Os prints da vitrine (5 alturas, nos dois temas) têm de sair iguais aos
da `main`, e a auditoria dela na maior letra passa nas duas:
```bash
bash $F/prints-da-vitrine.sh <udid> <dd da main>/Build/Products/Debug-iphonesimulator/Custta.app <prints>/vitrine-main 6
bash $F/prints-da-vitrine.sh <udid> <seu dd>/Build/Products/Debug-iphonesimulator/Custta.app <prints>/vitrine 6
python3 -I $F/compara-prints.py <prints>/vitrine-main <prints>/vitrine
TEST_RUNNER_CUSTTA_DESLOC=6 xcodebuild test-without-building "${XB[@]}" -derivedDataPath <dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/AuditoriaUITests/testVitrineDasPecasNoMaiorTamanho 2>&1 | grep -E "Test Case .*(passed|failed)"
```
Expected:
```
# prints da vitrine no dia 10 (desvio 6), main × este commit, no 27
vitrine-0-claro.png: canais >16: 0, >48: 0, máx 1, média 0.000
vitrine-0-escuro.png: canais >16: 0, >48: 0, máx 0, média 0.000
vitrine-1400-claro.png: canais >16: 0, >48: 0, máx 0, média 0.000
vitrine-1400-escuro.png: canais >16: 0, >48: 0, máx 0, média 0.000
vitrine-2100-claro.png: canais >16: 0, >48: 0, máx 0, média 0.000
vitrine-2100-escuro.png: canais >16: 0, >48: 0, máx 0, média 0.000
vitrine-2800-claro.png: canais >16: 0, >48: 0, máx 0, média 0.000
vitrine-2800-escuro.png: canais >16: 0, >48: 0, máx 0, média 0.000
vitrine-700-claro.png: canais >16: 0, >48: 0, máx 0, média 0.000
vitrine-700-escuro.png: canais >16: 0, >48: 0, máx 0, média 0.000
# a auditoria na maior letra no dia 10, na main:
Test Case '-[CusttaUITests.AuditoriaUITests testVitrineDasPecasNoMaiorTamanho]' passed (61.739 seconds).
# e neste commit:
Test Case '-[CusttaUITests.AuditoriaUITests testVitrineDasPecasNoMaiorTamanho]' passed (60.386 seconds).
# e neste commit no dia 4 (hoje, 04/11):
Test Case '-[CusttaUITests.AuditoriaUITests testVitrineDasPecasNoMaiorTamanho]' passed (62.698 seconds).
```

- [ ] **Step 4: Commit**

```bash
git add app-ios/Custta/Falsos/VitrineDasPecas.swift
git commit -m "test: vitrine com os dois lançamentos mais recentes em qualquer dia do mês" -m "A vitrine das peças mostra na linha mono os dois primeiros gastos do mês mais recente e um de R\$ 1 bilhão, e os gastos dela são contados a partir de hoje. Nos dias 3 e 4 de cada mês, o mês corrente só tem um gasto, o de anteontem, e o testLancamentosNaLinhaMono caía com 2 linhas no lugar de 3 (run 41763664501, de 04/11; a main cai igual). Agora são os dois mais recentes, de qualquer mês: nos outros dias, os mesmos de antes."
```

### Task 2: O rótulo da pílula de ação com o ícone junto do texto

Dentro de uma linha de `List`, o `Label` ganha o estilo de rótulo da linha: o ícone vai para uma coluna à esquerda, e o
texto anda alguns pontos (print `prumo-list-linha/prints-tela/6-pilula-hoje-em-cima-list-embaixo.png`). As pílulas de ação
da fase ("Marcar como pronta", "Registrar venda", "Voltar pra construção", "Desfazer venda", "Definir orçamento") usam
`Label` dentro do `PilulaDaAcao` (`PecasDaObra.swift`).
- **O estilo título e ícone** fixado no estilo do botão segura o alinhamento vertical, mas dentro da `List` ainda afasta o
  ícone do texto 8 pt a mais: cada um anda 4 pt (medido no print da `v2-topo`: ícone de x 377 para 365 e texto de 463 para
  475, em pixels de 3×).
- **A folga** fica fixa nos 8 pt de fora da `List`, com o `labelIconToTitleSpacing(8)`, do iOS 26 (o mínimo do app).
- **O que foi descartado.** Um `LabelStyle` próprio (`HStack` com o ícone e o título) acerta a folga, mas desce o texto 1 px
  e sobe o ícone 1 px; o `labelReservedIconWidth(0)` desmonta o rótulo. Os dois saem nos prints.

A tarefa vem antes da troca e se prova na estrutura de hoje: os prints não mudam. Na `List`, a prova é a mesma comparação, na
ponta (6 em diante), no 26.5 e no 27.

**Files:**
- Modify: `app-ios/Custta/Telas/PecasDaObra.swift`

**Interfaces:**
- Consumes: `PilulaDaAcao` (`ButtonStyle`) e o `Label` das ações em `AcoesDaFaseView`.
- Produces: nada novo; o rótulo da pílula deixa de depender do contêiner.

- [ ] **Step 1: Implementar**

Em `app-ios/Custta/Telas/PecasDaObra.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDaObra.swift
+++ b/app-ios/Custta/Telas/PecasDaObra.swift
@@ -436,6 +436,11 @@ struct PilulaDaAcao: ButtonStyle {
 
     func makeBody(configuration: Configuration) -> some View {
         let rotulo = configuration.label
+            // O ícone junto do texto, no meio da pílula. Numa linha de List, o Label ganharia o estilo da linha (o ícone numa
+            // coluna à esquerda), e o texto andaria; o título e ícone segura o alinhamento, mas lá afasta o ícone do texto 8 pt
+            // a mais. A folga fica nos 8 pt de fora da List.
+            .labelStyle(.titleAndIcon)
+            .labelIconToTitleSpacing(8)
             .font(.body.weight(.semibold))
             .multilineTextAlignment(.center)
             .foregroundStyle(paleta.cor(principal ? .sobreMarca : .texto))
```

- [ ] **Step 2: Conferir que a tela não muda**

Sem teste novo: o XCUITest vê a pílula como um botão só, sem o quadro do ícone e do texto. A prova é o print. Tire as cenas
da obra com a pílula à vista na `main` e neste commit e compare pixel a pixel:
- a obra v1 rolada a 400;
- o topo da v2 (pronta) e da v3 (vendida);
- a v1 na maior letra a 1500;
- tudo nos dois temas.

Run: os prints antes × depois de "Como entregar". O `<prints>/antes` é o de lá, com as 22 cenas da `main`, tirado uma vez
por PR. Aqui, só as cenas com a pílula à vista (`v1-400`, `v2-topo`, `v3-topo` e `v1-ax5-1500`, nos dois temas); com o
`--cenas`, a comparação cai se alguma delas faltar numa das pastas:
```bash
bash $F/prints-da-obra.sh <udid> <seu dd>/Build/Products/Debug-iphonesimulator/Custta.app <prints>/depois-2 '400|v2-topo|v3-topo|ax5-1500'
python3 -I $F/compara-prints.py <prints>/antes <prints>/depois-2 --cenas '400|v2-topo|v3-topo|ax5-1500'
```
Expected (no 26.5; a pílula à vista nas cenas `400` e `v2-topo`):
```
v1-400-claro.png: canais >16: 0, >48: 0, máx 2, média 0.000
v1-400-escuro.png: canais >16: 0, >48: 0, máx 1, média 0.000
v1-ax5-1500-claro.png: canais >16: 0, >48: 0, máx 1, média 0.000
v1-ax5-1500-escuro.png: canais >16: 0, >48: 0, máx 0, média 0.000
v2-topo-claro.png: canais >16: 0, >48: 0, máx 1, média 0.000
v2-topo-escuro.png: canais >16: 0, >48: 0, máx 0, média 0.000
v3-topo-claro.png: canais >16: 0, >48: 0, máx 1, média 0.000
v3-topo-escuro.png: canais >16: 0, >48: 0, máx 1, média 0.000
```

- [ ] **Step 3: Commit**

```bash
git add app-ios/Custta/Telas/PecasDaObra.swift
git commit -m "refactor: rótulo da pílula de ação com o ícone junto do texto" -m "Numa linha de List, o Label da pílula de ação ganha o estilo de rótulo da linha: o ícone vai para uma coluna à esquerda e o texto anda alguns pontos. O estilo título e ícone, fixado no PilulaDaAcao, segura o alinhamento, mas dentro da List ainda afasta o ícone do texto 8 pt a mais. A folga fica fixa nos 8 pt de fora da List (labelIconToTitleSpacing, do iOS 26). Na ScrollView de hoje, os prints não mudam."
```

### Task 3: Os testes da obra rolam até a peça abaixo da dobra

Na `List`, o XCUITest só vê a linha que está na tela; a LazyVStack expunha a peça a ~1.700 pt. Vinte e um testes leem ou
tocam uma peça abaixo da dobra logo ao abrir, sem rolar, e caem na `List`:
- as ações da fase: Fases ×3, Estados ×2 e o laudo do alerta de não salvou;
- a pílula "Lançamentos": o ajudante `pilula` da busca ×3 e o "nada foi gravado" do Gasto;
- o A vencer, a Venda, os gastos por tópico e o cartão vazio: Obra ×5 e a obra criada na FolhaDaObra;
- a linha dos afazeres: Afazeres ×2 e o teste cruzado com o site;
- uma peça do alto depois de a lista rolar para longe dela (a fase e o título, depois de salvar noutra obra): Estados ×1;
- a cena da obra sem gastos do laudo, que esperava o cartão vazio.

Quinze saíram do inventário do protótipo, nas seis suítes da obra (03/11). Cinco, do run completo da CI do mesmo dia
(41706879156), em outras suítes. O cruzado, que a CI não roda, saiu de uma busca pelo mesmo padrão (`waitForExistence` da
peça antes do `rolarAte` dela).

A adaptação segue estas regras:
- **Ao abrir:** o teste espera uma peça do alto, rola até a peça como a pessoa rolaria (`rolarAte`) e só então lê.
- **Ausência:** a que o teste confere ("a construção não se vende", "sem os gastos por tópico") fica depois de a lista chegar
  à região, para o teste seguir pegando o que pegava.
- **Depois de uma ação que mexe na rolagem** (salvar, a lupa, o A vencer que abre), o teste não rola antes de conferir: se
  a peça não estiver à vista, o defeito é do app. Para ler o que ficou no alto, o teste volta pelo dedo (`rolarAteOTopo`,
  novo).
- **A cena do laudo** espera o total gasto, no alto. O cartão vazio fica abaixo da dobra também hoje: a cena mede a mesma
  tela de antes.

A tarefa vem antes da troca e se prova na estrutura de hoje: os testes passam nela, e passam na `List` da 6.

**Files:**
- Test (alterar): `app-ios/CusttaUITests/Abrir.swift`
- Test (alterar): `app-ios/CusttaUITests/AfazeresUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/BuscaUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/CruzadoUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/EstadosUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/FasesUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/FolhaDaObraUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/GastoUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/ObraUITests.swift`

**Interfaces:**
- Consumes: `XCUIApplication.rolarAte(_:tentativas:)` e `elemento(_:)` (`Abrir.swift`).
- Produces: `XCUIApplication.rolarAteOTopo(tentativas:)`.

- [ ] **Step 1: Adaptar os testes**

Em `app-ios/CusttaUITests/Abrir.swift`:

```diff
--- a/app-ios/CusttaUITests/Abrir.swift
+++ b/app-ios/CusttaUITests/Abrir.swift
@@ -41,6 +41,16 @@ extension XCUIApplication {
         }
     }
 
+    /// Volta a lista ao alto pelo dedo, até o título da obra ficar à vista. Na List, a peça do alto sai da árvore quando a lista
+    /// rola para longe dela.
+    func rolarAteOTopo(tentativas: Int = 12) {
+        let titulo = elemento("tituloDaObra")
+        for _ in 0..<tentativas {
+            if titulo.exists && titulo.isHittable { return }
+            swipeDown(velocity: .fast)
+        }
+    }
+
     /// Volta pelo gesto da borda esquerda, como o polegar (o XCUITest não tem "voltar" do sistema). No iOS 26 da CI, o arrasto
     /// sintetizado às vezes não volta depois de voltar pelo botão e entrar de novo, sem alerta e com o voltar à vista (runs
     /// 39710458060 e 39799242127). Lá, se `saindo` não some em 2 s, ele se repete uma vez, com um print e uma linha no log;
```

Em `app-ios/CusttaUITests/AfazeresUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/AfazeresUITests.swift
+++ b/app-ios/CusttaUITests/AfazeresUITests.swift
@@ -35,8 +35,9 @@ final class AfazeresUITests: XCTestCase {
             XCTAssertTrue(cartao.waitForExistence(timeout: 10))
             cartao.tap()
             let linha = app.elemento("linhaDosAfazeres")
-            XCTAssertTrue(linha.waitForExistence(timeout: 5))
+            XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5))
             app.rolarAte(linha)
+            XCTAssertTrue(linha.exists)
             XCTAssertEqual(linha.label, "Afazeres")
             XCTAssertEqual(linha.value as? String, valor, obra)
             linha.tap()
@@ -178,8 +179,9 @@ final class AfazeresUITests: XCTestCase {
         while pendentes(app) != "Pendentes, 2" && Date.now < ate { usleep(200_000) }
         app.navigationBars.buttons["BackButton"].tap()
         let linha = app.elemento("linhaDosAfazeres")
-        XCTAssertTrue(linha.waitForExistence(timeout: 5))
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5))
         app.rolarAte(linha)
+        XCTAssertTrue(linha.exists)
         XCTAssertTrue((linha.value as? String ?? "").hasSuffix("com a altura do peitoril e o lado de abrir de cada folha."),
                       "o VoiceOver lê o pendente de 213 caracteres inteiro")
         XCTAssertLessThan(linha.frame.height, 110, "duas linhas do pendente, e não seis")
```

Em `app-ios/CusttaUITests/BuscaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/BuscaUITests.swift
+++ b/app-ios/CusttaUITests/BuscaUITests.swift
@@ -63,6 +63,7 @@ final class BuscaUITests: XCTestCase {
     /// soma deles, e o "A vencer" abre sozinho com os 6 que vêm. Com acento, maiúscula e espaço no fim, o mesmo.
     func testBuscarSemAcentoPeloTopicoEPelaDescricao() {
         let app = abrirObra()
+        app.rolarAte(app.elemento("lancamentos"))
         XCTAssertEqual(pilula(app), "Lançamentos, 46")
         buscar(app, "ceramica")
         XCTAssertEqual(app.textFields["campoDaBusca"].label, "Buscar gasto ou tópico", "o rótulo do campo para o VoiceOver")
@@ -207,7 +208,9 @@ final class BuscaUITests: XCTestCase {
     /// Obra sem gasto: a pílula sem número (o contador do site) e sem a lupa e o mês, que não teriam o que filtrar.
     func testObraSemGastoSoAPilula() {
         let app = abrirApp(conta: "senha", dados: "exemplo", abrir: "obra:o3")
-        XCTAssertTrue(app.elemento("obraSemGastos").waitForExistence(timeout: 10))
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
+        app.rolarAte(app.elemento("obraSemGastos"))
+        XCTAssertTrue(app.elemento("obraSemGastos").exists)
         XCTAssertEqual(pilula(app), "Lançamentos")
         XCTAssertFalse(app.buttons["buscar"].exists)
         XCTAssertFalse(app.buttons["filtrarPorMes"].exists)
@@ -265,13 +268,15 @@ final class BuscaUITests: XCTestCase {
         app.navigationBars.buttons["BackButton"].tap()
         XCTAssertTrue(v2.waitForExistence(timeout: 5))
         v2.tap()
-        XCTAssertTrue(app.elemento("lancamentos").waitForExistence(timeout: 5))
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5))
+        app.rolarAte(app.elemento("lancamentos"))
         XCTAssertEqual(pilula(app), "Lançamentos, 5")
         XCTAssertFalse(app.textFields["campoDaBusca"].exists)
         app.navigationBars.buttons["BackButton"].tap()
         XCTAssertTrue(v1.waitForExistence(timeout: 5))
         v1.tap()
-        XCTAssertTrue(app.elemento("lancamentos").waitForExistence(timeout: 5))
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5))
+        app.rolarAte(app.elemento("lancamentos"))
         XCTAssertEqual(pilula(app), "Lançamentos, 46", "de volta à mesma obra, sem o filtro")
         XCTAssertFalse(app.textFields["campoDaBusca"].exists)
     }
```

Em `app-ios/CusttaUITests/CruzadoUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/CruzadoUITests.swift
+++ b/app-ios/CusttaUITests/CruzadoUITests.swift
@@ -58,8 +58,9 @@ final class CruzadoUITests: XCTestCase {
         app.recusarGuardarSenha()                       // a oferta do iOS de guardar a senha do formulário cobre a lista
         elemento("obra-\(afazeres.obra)").tap()
         let linha = elemento("linhaDosAfazeres")
-        XCTAssertTrue(linha.waitForExistence(timeout: 30))
+        XCTAssertTrue(elemento("tituloDaObra").waitForExistence(timeout: 30))
         app.rolarAte(linha)
+        XCTAssertTrue(linha.exists)
         XCTAssertEqual(linha.value as? String, afazeres.linha)
         linha.tap()
         XCTAssertTrue(elemento("pendentes").waitForExistence(timeout: 10))
```

Em `app-ios/CusttaUITests/EstadosUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/EstadosUITests.swift
+++ b/app-ios/CusttaUITests/EstadosUITests.swift
@@ -54,6 +54,8 @@ final class EstadosUITests: XCTestCase {
         app.buttons["salvarGasto"].tap()
         let titulo = app.elemento("tituloDaObra")
         XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5))
+        // Depois de salvar, a lista rola até o gasto novo; o título e o total ficam no alto.
+        app.rolarAteOTopo()
         XCTAssertEqual(titulo.label, "Sobrado Granja Viana", "a folha desce na obra que recebeu o gasto")
         XCTAssertTrue(app.elemento("indicadorTotal").label.contains("6 lançamentos"), app.elemento("indicadorTotal").label)
         app.navigationBars.buttons.firstMatch.tap()
@@ -239,8 +241,9 @@ final class EstadosUITests: XCTestCase {
     func testNaoSalvouAlertaUmaVezETocarTentaDeNovo() {
         let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", gravacao: "recusa")
         let pronta = app.buttons["acao-marcarPronta"]
-        XCTAssertTrue(pronta.waitForExistence(timeout: 10))
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
         app.rolarAte(pronta)
+        XCTAssertTrue(pronta.exists)
         pronta.tap()
         let alerta = app.alerts["Não salvou na nuvem"]
         XCTAssertTrue(alerta.waitForExistence(timeout: 5))
@@ -263,8 +266,9 @@ final class EstadosUITests: XCTestCase {
         let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", gravacao: "recusa",
                            extra: ["CUSTTA_GRAVACAO_ESPERA": "aviso"])
         let pronta = app.buttons["acao-marcarPronta"]
-        XCTAssertTrue(pronta.waitForExistence(timeout: 10))
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
         app.rolarAte(pronta)
+        XCTAssertTrue(pronta.exists)
         pronta.tap()
         app.buttons["botaoMais"].tap()
         XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
```

Em `app-ios/CusttaUITests/FasesUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/FasesUITests.swift
+++ b/app-ios/CusttaUITests/FasesUITests.swift
@@ -10,19 +10,23 @@ final class FasesUITests: XCTestCase {
     func testMarcarComoProntaEVoltarPraConstrucaoSemPergunta() {
         let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
         let pronta = app.buttons["acao-marcarPronta"]
-        XCTAssertTrue(pronta.waitForExistence(timeout: 10))
+        XCTAssertTrue(app.elemento("faseDaObra").waitForExistence(timeout: 10))
         XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
-        XCTAssertFalse(app.buttons["acao-registrarVenda"].exists, "a construção não se vende")
+        // As ações ficam abaixo da dobra: a lista cria a linha delas quando chega perto, e só então a ausência prova algo.
         app.rolarAte(pronta)
+        XCTAssertTrue(pronta.exists)
+        XCTAssertFalse(app.buttons["acao-registrarVenda"].exists, "a construção não se vende")
         pronta.tap()
         let voltar = app.buttons["acao-voltarConstrucao"]
         XCTAssertTrue(voltar.waitForExistence(timeout: 5), "pronta: voltar e registrar venda")
         XCTAssertTrue(app.buttons["acao-registrarVenda"].exists)
         XCTAssertFalse(app.alerts.firstMatch.exists, "mudar a fase não pergunta (o mudarFase do site)")
+        app.rolarAteOTopo()
         XCTAssertTrue(app.elemento("faseDaObra").label.contains("Pronta · à venda"))
         app.rolarAte(voltar)
         voltar.tap()
         XCTAssertTrue(app.buttons["acao-marcarPronta"].waitForExistence(timeout: 5))
+        app.rolarAteOTopo()
         XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
     }
 
@@ -61,21 +65,25 @@ final class FasesUITests: XCTestCase {
     func testDesfazerVendaPerguntaComOTextoDoSite() {
         let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v3")
         let desfazer = app.buttons["acao-desfazerVenda"]
-        XCTAssertTrue(desfazer.waitForExistence(timeout: 10))
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
         app.rolarAte(desfazer)
+        XCTAssertTrue(desfazer.exists)
         desfazer.tap()
         let alerta = app.alerts["Desfazer a venda?"]
         XCTAssertTrue(alerta.waitForExistence(timeout: 5))
         XCTAssertTrue(alerta.staticTexts["A obra volta pra “Pronta”."].exists)
         alerta.buttons["Cancelar"].tap()
         XCTAssertTrue(alerta.waitForNonExistence(timeout: 5))
+        app.rolarAteOTopo()
         XCTAssertTrue(app.elemento("faseDaObra").label.contains("Vendida"), "cancelar não muda nada")
         app.rolarAte(desfazer)
         desfazer.tap()
         XCTAssertTrue(alerta.waitForExistence(timeout: 5))
         alerta.buttons["Desfazer venda"].tap()
         XCTAssertTrue(app.buttons["acao-registrarVenda"].waitForExistence(timeout: 5))
+        app.rolarAteOTopo()
         XCTAssertTrue(app.elemento("faseDaObra").label.contains("Pronta · à venda"))
+        app.rolarAte(app.elemento("indicadorVenda"))
         XCTAssertTrue(app.elemento("indicadorVenda").label.contains("Venda estimada"), "a venda saiu; volta a estimativa")
     }
 
@@ -98,10 +106,12 @@ final class FasesUITests: XCTestCase {
         XCTAssertTrue(confirmar.waitForExistence(timeout: 10))
         confirmar.doubleTap()
         XCTAssertTrue(confirmar.waitForNonExistence(timeout: 5), "a folha desce")
+        app.rolarAte(app.buttons["acao-desfazerVenda"])
         XCTAssertTrue(app.buttons["acao-desfazerVenda"].waitForExistence(timeout: 5))
         sleep(1)
         XCTAssertFalse(app.alerts.firstMatch.exists, "nenhum aviso")
         XCTAssertFalse(app.elemento("tituloDaFolha").exists, "nenhuma folha abriu por baixo")
+        app.rolarAte(app.elemento("indicadorVenda"))
         XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.380.000,00"))
     }
 
```

Em `app-ios/CusttaUITests/FolhaDaObraUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/FolhaDaObraUITests.swift
+++ b/app-ios/CusttaUITests/FolhaDaObraUITests.swift
@@ -37,9 +37,13 @@ final class FolhaDaObraUITests: XCTestCase {
         let titulo = app.elemento("tituloDaObra")
         XCTAssertTrue(titulo.waitForExistence(timeout: 8), "\"Criar obra\" entra direto na obra nova")
         XCTAssertEqual(titulo.label, "Casa Granja Viana 2")
-        XCTAssertTrue(app.elemento("obraSemGastos").exists)
         XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
-        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.600.000,00"))
+        // Abaixo da dobra, onde a List só cria a linha que entra na tela.
+        let venda = app.elemento("indicadorVenda"), vazia = app.elemento("obraSemGastos")
+        app.rolarAte(venda)
+        XCTAssertTrue(venda.label.contains("R$\u{a0}1.600.000,00"))
+        app.rolarAte(vazia)
+        XCTAssertTrue(vazia.exists)
         app.navigationBars.buttons.firstMatch.tap()
         XCTAssertTrue(app.staticTexts["4 obras"].waitForExistence(timeout: 5), "a obra nova está na lista")
     }
```

Em `app-ios/CusttaUITests/GastoUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/GastoUITests.swift
+++ b/app-ios/CusttaUITests/GastoUITests.swift
@@ -297,6 +297,7 @@ final class GastoUITests: XCTestCase {
         app.buttons["fecharFolha"].tap()
         app.alerts["Você já preencheu este gasto."].buttons["Descartar gasto"].tap()
         XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5))
+        app.rolarAte(app.elemento("lancamentos"))
         XCTAssertTrue(app.elemento("lancamentos").label.contains("46"), "nada foi gravado")
     }
 
```

Em `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -410,7 +410,9 @@ extension LeituraNoVidroUITests {
                 Cena(nome: "obra, gastos por tópico, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "804"],
                      espera: "gastosPorTopico", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true,
                      assunto: ["gastosPorTopico"]),
-                Cena(nome: "obra sem gastos, \(tema)", conta: "senha", argumentos: combo, espera: "obraSemGastos", escopo: "tudo",
+                // Espera o total gasto, no alto: o cartão vazio fica abaixo da dobra, e a List só cria a linha que entra na tela
+                // (a LazyVStack o criava fora dela). A cena mede a mesma tela de antes.
+                Cena(nome: "obra sem gastos, \(tema)", conta: "senha", argumentos: combo, espera: "indicadorTotal", escopo: "tudo",
                      abrir: "obra:o3"),
                 Cena(nome: "obra sem orçamento, ações, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "350"],
                      espera: "definirOrcamento", escopo: "tudo", dados: "semOrcamento", abrir: "obra:v1", rolada: true,
@@ -619,8 +621,9 @@ extension LeituraNoVidroUITests {
             let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", gravacao: "recusa",
                                argumentos: ["-custta.tema", tema] + piorMomento)
             let pronta = app.buttons["acao-marcarPronta"]
-            XCTAssertTrue(pronta.waitForExistence(timeout: 10))
+            XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
             app.rolarAte(pronta)
+            XCTAssertTrue(pronta.exists)
             pronta.tap()
             let alerta = app.alerts["Não salvou na nuvem"]
             XCTAssertTrue(alerta.waitForExistence(timeout: 8), "\(tema): o alerta não abriu")
```

Em `app-ios/CusttaUITests/ObraUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/ObraUITests.swift
+++ b/app-ios/CusttaUITests/ObraUITests.swift
@@ -42,19 +42,21 @@ final class ObraUITests: XCTestCase {
         XCTAssertTrue(aPagar.contains("R$\u{a0}13.250,00") && aPagar.contains("3 vencimentos"), aPagar)
         XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.450.000,00"))
         XCTAssertTrue(app.elemento("faseDaObra").label.contains("Em construção"))
-        let fase = app.elemento("faseDaObra").label, lancamentos = app.elemento("lancamentos").label
+        let fase = app.elemento("faseDaObra").label
         XCTAssertTrue(fase.contains("14 meses"), fase)
-        XCTAssertTrue(lancamentos.contains("46"), lancamentos)
         let tituloPequeno = app.elemento("tituloPequenoDaBarra")
         XCTAssertFalse(tituloPequeno.exists, "no alto, o nome fica só no título grande")
-        app.swipeUp()
+        // A pílula fica abaixo da dobra: rolada a tela até ela, o nome passa para a barra.
+        let lancamentos = app.elemento("lancamentos")
+        app.rolarAte(lancamentos)
+        XCTAssertTrue(lancamentos.label.contains("46"), lancamentos.label)
         XCTAssertTrue(tituloPequeno.waitForExistence(timeout: 5), "rolada a tela, o nome passa para a barra")
     }
 
     func testAVencerFechadoAbreEFecha() {
         let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
         let aVencer = app.elemento("aVencer")
-        XCTAssertTrue(aVencer.waitForExistence(timeout: 10))
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
         app.rolarAte(aVencer)
         XCTAssertEqual(aVencer.value as? String, "fechado")
         XCTAssertFalse(app.elemento("gasto-g037").exists, "as parcelas futuras não aparecem com o grupo fechado")
@@ -97,9 +99,12 @@ final class ObraUITests: XCTestCase {
 
     func testObraSemGastos() {
         let app = abrirApp(conta: "senha", dados: "exemplo", abrir: "obra:o3")
-        XCTAssertTrue(app.elemento("obraSemGastos").waitForExistence(timeout: 10))
+        XCTAssertTrue(app.elemento("indicadorTotal").waitForExistence(timeout: 10))
         let total = app.elemento("indicadorTotal").label
         XCTAssertTrue(total.contains("sem gastos") && total.contains("R$\u{a0}0,00"), total)
+        // O cartão vazio fica no fim, abaixo da dobra.
+        app.rolarAte(app.elemento("obraSemGastos"))
+        XCTAssertTrue(app.elemento("obraSemGastos").exists)
         // Etapa 4: o sólido com R$ 0,00 convida a lançar o primeiro gasto.
         XCTAssertTrue(total.contains("Toque no + para lançar o primeiro gasto."), total)
     }
@@ -141,6 +146,7 @@ final class ObraUITests: XCTestCase {
         XCTAssertEqual(orcamento.minY - lucro.frame.maxY, 12, accuracy: 0.5, "o Orçamento logo depois do sólido")
         XCTAssertEqual(total.frame.minY - orcamento.maxY, 12, accuracy: 0.5, "o Total gasto logo depois do Orçamento")
         XCTAssertTrue(total.label.contains("R$\u{a0}842.317,45") && total.label.contains("46 lançamentos"), total.label)
+        app.rolarAte(app.elemento("indicadorVenda"))
         XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.380.000,00"))
     }
 
@@ -185,7 +191,10 @@ final class ObraUITests: XCTestCase {
     /// Sem gastos, somem os gastos por tópico (como as portas do site).
     func testSemGastosSemGastosPorTopico() {
         let app = abrirApp(conta: "senha", dados: "exemplo", abrir: "obra:o3")
-        XCTAssertTrue(app.elemento("obraSemGastos").waitForExistence(timeout: 10))
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
+        // O cartão vazio é a última peça: com a lista nele, o lugar dos gastos por tópico está na tela.
+        app.rolarAte(app.elemento("obraSemGastos"))
+        XCTAssertTrue(app.elemento("obraSemGastos").exists)
         XCTAssertFalse(app.elemento("gastosPorTopico").exists)
         XCTAssertTrue(app.elemento("linhaDosAfazeres").exists)
     }
```

- [ ] **Step 2: Ver passar na estrutura de hoje**

Os testes de app (18):

Run:
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/FasesUITests/testMarcarComoProntaEVoltarPraConstrucaoSemPergunta \
  -only-testing:CusttaUITests/FasesUITests/testDesfazerVendaPerguntaComOTextoDoSite \
  -only-testing:CusttaUITests/FasesUITests/testToqueDuploNoConfirmarVendaVendeUmaVez \
  -only-testing:CusttaUITests/EstadosUITests/testNaoSalvouAlertaUmaVezETocarTentaDeNovo \
  -only-testing:CusttaUITests/EstadosUITests/testNaoSalvouEsperaAFolhaDescer \
  -only-testing:CusttaUITests/EstadosUITests/testMaisNumaObraVendidaLancaNumaAberta \
  -only-testing:CusttaUITests/GastoUITests/testFecharDepoisDoValorPerguntaAntes \
  -only-testing:CusttaUITests/ObraUITests/testIndicadoresComOsNumerosDoMockup \
  -only-testing:CusttaUITests/ObraUITests/testAVencerFechadoAbreEFecha \
  -only-testing:CusttaUITests/ObraUITests/testObraSemGastos \
  -only-testing:CusttaUITests/ObraUITests/testVendidaComLucroNoSolido \
  -only-testing:CusttaUITests/ObraUITests/testSemGastosSemGastosPorTopico \
  -only-testing:CusttaUITests/BuscaUITests/testBuscarSemAcentoPeloTopicoEPelaDescricao \
  -only-testing:CusttaUITests/BuscaUITests/testObraSemGastoSoAPilula \
  -only-testing:CusttaUITests/BuscaUITests/testFiltroZeraAoTrocarDeObra \
  -only-testing:CusttaUITests/AfazeresUITests/testLinhaNosTresEstadosAbreAfazeres \
  -only-testing:CusttaUITests/AfazeresUITests/testLinhaCortaOPrimeiroPendenteEmDuasLinhas \
  -only-testing:CusttaUITests/FolhaDaObraUITests/testCriarObraComOErroDaAreaEEntrarNela 2>&1 | grep -cE "Test Case .*passed"
```
Expected: `18` (no 26.5 do Mac, 439 s). O `grep -c` só conta; para ver uma queda, troque por
`grep -E "Test Case .*failed|error:"`, que tem de sair vazio.

Os dois do laudo:

Run:
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaObraEmBlocos \
  -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDoAlertaDeNaoSalvou 2>&1 | grep -E "Test Case .*(passed|failed)"
```
Expected:
```
Test Case '-[CusttaUITests.LeituraNoVidroUITests testLeituraDaObraEmBlocos]' passed (171.082 seconds).
Test Case '-[CusttaUITests.LeituraNoVidroUITests testLeituraDoAlertaDeNaoSalvou]' passed (25.239 seconds).
```

O cruzado, com os emuladores (Java), no seu simulador:

Run:
```bash
CUSTTA_SIMULADOR=<udid do seu simulador> npm run test:app-ios:cruzado 2>&1 | tail -3
```
Expected (no 26.5, com a `List` já na ponta, onde a adaptação importa; 133 s):
```
✔ Test run with 1 test in 1 suite passed after 0.862 seconds.
** TEST SUCCEEDED **
✔  Script exited successfully (code 0)
```
(o `CruzadoUITests`, que roda antes, também sai `** TEST SUCCEEDED **`).

- [ ] **Step 3: Mutação: os testes ainda mordem**

Mute o app duas vezes e rode os testes da mutação; cada um tem de cair, e depois desfaça:
- `acoesDaFase(.construcao)` devolvendo também `.registrarVenda`: cai o `testMarcarComoProntaEVoltarPraConstrucaoSemPergunta`
  ("a construção não se vende");
- o bloco dos gastos por tópico sem o `if !obra.gastos.isEmpty`: cai o `testSemGastosSemGastosPorTopico`.

Expected:
```
FasesUITests.swift:18: error: -[CusttaUITests.FasesUITests testMarcarComoProntaEVoltarPraConstrucaoSemPergunta] : XCTAssertFalse failed - a construção não se vende
ObraUITests.swift:198: error: -[CusttaUITests.ObraUITests testSemGastosSemGastosPorTopico] : XCTAssertFalse failed
```

- [ ] **Step 4: Commit**

```bash
git add app-ios/CusttaUITests/Abrir.swift app-ios/CusttaUITests/AfazeresUITests.swift app-ios/CusttaUITests/BuscaUITests.swift app-ios/CusttaUITests/CruzadoUITests.swift app-ios/CusttaUITests/EstadosUITests.swift app-ios/CusttaUITests/FasesUITests.swift app-ios/CusttaUITests/FolhaDaObraUITests.swift app-ios/CusttaUITests/GastoUITests.swift app-ios/CusttaUITests/LeituraNoVidroUITests.swift app-ios/CusttaUITests/ObraUITests.swift
git commit -m "test: testes da obra rolam até a peça abaixo da dobra" -m "Na List, o XCUITest só vê a linha que está na tela (a LazyVStack expunha a ~1.700 pt). Vinte e um testes liam ou tocavam uma peça abaixo da dobra logo ao abrir, sem rolar: as ações da fase, a pílula, o A vencer, a linha dos afazeres, o cartão vazio e a Venda, também no laudo do alerta de não salvou e no teste cruzado com o site. Agora eles esperam uma peça do alto, rolam até a peça como a pessoa rolaria e só então leem; a ausência que um teste confere fica depois de a lista chegar à região, para ele seguir pegando o que pegava. Depois de uma ação que mexe na rolagem (salvar, a lupa), o teste não rola antes de conferir. A cena da obra sem gastos do laudo espera o total gasto, no alto, e mede a mesma tela."
```

### Task 4: O laudo deixa o vidro do voltar de fora, como a barra de status

O laudo de leitura mede o que muda entre um print normal e outro com o texto apagado (`LeituraNoVidroUITests.conferir`).
O que é do sistema e muda entre os dois prints já fica de fora em toda cena: a barra de status (o `topo`) e o indicador de
início (os 34 pt de baixo).
- **O voltar.** Também é do sistema e não tem texto do app. O vidro dele se adapta ao que tem atrás e assenta segundos
  depois de a tela abrir.
- **O que dá errado.** Na `List`, com o texto apagado, o vidro leva de 1 a 8 s para assentar, e o print sai aos 2 s. O vidro
  diferente vira "texto". Nas condições do laudo, a `List` caiu 3 de 3, sempre no voltar (16,70); a estrutura de hoje
  passou:
  - "obra, topo, escuro: texto #0A8A7B em 16,70 (44×36 pt) fica em 1.63:1";
  - "obra na maior letra: texto #0A8D7C … 1.66:1";
  - "obra, topo, claro: 11138 pixels mudaram longe das letras".
  A causa e o A/B estão em `prumo-list-linha/voltar/`.
- **O conserto.** O `fotografar` devolve também o quadro do voltar (`BackButton`), com 4 pt de folga, e ele entra no
  `ignorar`, como os dois. O `ignorar` vale para as duas guardas do laudo: as palavras e a cena que mudou longe delas. Nas
  cenas roladas, a borda de cima (140 pt) já o deixava de fora. Com uma folha aberta, entram os dois voltar, o da folha e o
  da tela de baixo. O de baixo cai no cabeçalho da folha (12–64 × 58–110), onde hoje só há o × do sistema, sem texto: um
  texto novo ali ficaria fora do laudo, e o comentário do `fotografar` diz isso.
- **O que foi descartado.** Refazer o print sem texto, com mais espera, enquanto a barra diferisse. No run completo da CI de
  03/11 (41706879156), 36 das 37 cenas que refizeram chegaram à 3ª tentativa: a barra difere também pelo lápis e pelo que
  passa por baixo dela. Custou ~100 s por cena: o `laudo` foi de 26 para 53 min, e o `laudo-etapa3` bateu o teto de 75.
- **Quando entra.** A tarefa vem antes da troca. Na estrutura de hoje, o laudo sai igual palavra por palavra (nada de texto
  cai dentro do voltar). Depois da 6, é ela que deixa o laudo da obra passar.

**Files:**
- Test (alterar): `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`

**Interfaces:**
- Consumes: `LeituraNoVidroUITests.fotografar(_:textoApagado:)`, `LaudoDeContraste.medir(…ignorar:)`.
- Produces: `fotografar(_:textoApagado:)` devolve também o quadro do voltar (`[CGRect]`, vazio sem voltar).

- [ ] **Step 1: Escrever o conserto**

Em `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -69,7 +69,7 @@ final class LeituraNoVidroUITests: XCTestCase {
     ///   18 Pro (decisão do Prumo, 21/10).
     private static let excecoes = ["obra com orçamento por tópico, na maior letra": "iconeDoAviso"]
 
-    @MainActor private func fotografar(_ cena: Cena, textoApagado: Bool) -> (XCUIScreenshot, [CGRect], CGFloat, [CGRect]) {
+    @MainActor private func fotografar(_ cena: Cena, textoApagado: Bool) -> (XCUIScreenshot, [CGRect], CGFloat, [CGRect], [CGRect]) {
         let excecao = Self.excecoes[cena.nome].map { ["-custta.foraDoLaudo", $0] } ?? []
         let app = abrirApp(conta: cena.conta, dados: cena.dados, abrir: cena.abrir, folha: cena.folha,
                            argumentos: cena.argumentos + excecao + (textoApagado ? ["-custta.textoApagado", cena.escopo] : []))
@@ -87,8 +87,12 @@ final class LeituraNoVidroUITests: XCTestCase {
         let abas = ["aba-obras", "aba-ajustes"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
         let largura = app.frame.width
         let informativo = exemploDaDescricao(app, cena)
+        // Todos os voltar: com a folha aberta, o da tela de baixo e o da folha. O da tela de baixo cai no cabeçalho da folha
+        // (12–64 × 58–110), onde hoje só há o × do sistema, sem texto; um texto novo ali ficaria fora do laudo.
+        let doVoltar = app.navigationBars.buttons.matching(identifier: "BackButton").allElementsBoundByIndex.filter(\.exists)
+            .map { $0.frame.insetBy(dx: -4, dy: -4) }
         app.terminate()
-        return (foto, abas, largura, informativo)
+        return (foto, abas, largura, informativo, doVoltar)
     }
 
     /// O assunto da cena à vista antes do print: abaixo da barra de status e acima da faixa de baixo, a borda de 140 pt ou a
@@ -144,8 +148,8 @@ final class LeituraNoVidroUITests: XCTestCase {
 
     /// Mede uma cena, anexa o print anotado e a tabela e devolve as palavras abaixo do portão.
     @MainActor private func conferir(_ cena: Cena) throws -> [String] {
-        let (normal, abas, largura, informativo) = fotografar(cena, textoApagado: false)
-        let (semTexto, _, _, _) = fotografar(cena, textoApagado: true)
+        let (normal, abas, largura, informativo, voltar) = fotografar(cena, textoApagado: false)
+        let (semTexto, _, _, _, _) = fotografar(cena, textoApagado: true)
         let imagem = normal.image.cgImage!
         let escala = CGFloat(imagem.width) / largura
         let capsula = abas.reduce(CGRect.null) { $0.union($1) }
@@ -158,11 +162,14 @@ final class LeituraNoVidroUITests: XCTestCase {
         // O indicador de início, como a barra de status, é do sistema e muda entre os prints (aparece ou não, e
         // muda de cor com o que tem por baixo): os 34 pt de baixo ficam de fora em toda cena.
         let indicador = [CGRect(x: 0, y: altura - 34, width: largura, height: 34)]
+        // O voltar também: é do sistema, sem texto do app, e o vidro dele se adapta ao que tem atrás e assenta depois de a
+        // tela abrir. Na obra em List, com o texto apagado, assenta de 1 a 8 s, e o print sai aos 2 s: o vidro diferente
+        // virava "texto" a 1,63:1. Nas cenas roladas, a borda de cima já o deixa de fora.
         let borda = cena.rolada ? [CGRect(x: 0, y: 0, width: largura, height: 140)] : []
         let palavras = try LaudoDeContraste.medir(normal: Retrato(imagem), semTexto: Retrato(semTexto.image.cgImage!),
                                                   escala: escala, topo: Self.barraDeStatus,
                                                   somenteEm: cena.escopo == "navegacao" ? regiao : nil,
-                                                  ignorar: (cena.escopo == "tudo" ? abaixo : []) + indicador + borda + informativo)
+                                                  ignorar: (cena.escopo == "tudo" ? abaixo : []) + indicador + voltar + borda + informativo)
         XCTAssertFalse(palavras.isEmpty, "\(cena.nome): nenhum texto medido")
         anexar(cena.nome, normal.image, palavras, escala)
         Swift.print(String(format: "leitura | %@ | %d palavras, %d abaixo | pior nota %.2f", cena.nome, palavras.count,
```

- [ ] **Step 2: Ver o laudo da obra igual na estrutura de hoje**

Run:
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaObra 2>&1 | grep -E "leitura \||Test Case .*(passed|failed)" | tail -12
```
Expected: as mesmas linhas da `main`, palavra por palavra (no 26.5, rodado nas duas):
```
leitura | obra, topo, escuro | 29 palavras, 0 abaixo | pior nota 5.51
leitura | obra, lista, escuro | 42 palavras, 0 abaixo | pior nota 6.62
leitura | obra, topo, claro | 29 palavras, 0 abaixo | pior nota 4.56
leitura | obra, lista, claro | 42 palavras, 0 abaixo | pior nota 6.53
leitura | obra na maior letra | 18 palavras, 0 abaixo | pior nota 5.47
leitura | obra com Aumentar contraste | 42 palavras, 0 abaixo | pior nota 10.84
Test Case '-[CusttaUITests.LeituraNoVidroUITests testLeituraDaObra]' passed (116.141 seconds).
```

As cenas com folha (`testLeituraDaFolhaDoGasto`, `testLeituraDasFolhasDeOrigem` e as da maior letra) não rodam aqui: elas
se provam no laudo inteiro da ponta, no Pro Max e no job `laudo` da CI (Como entregar).

- [ ] **Step 3: Commit**

```bash
git add app-ios/CusttaUITests/LeituraNoVidroUITests.swift
git commit -m "test: laudo deixa o vidro do voltar de fora, como a barra de status" -m "O laudo de leitura mede o que muda entre um print normal e outro com o texto apagado, e já deixa de fora o que é do sistema e muda entre os dois: a barra de status e o indicador de início. O voltar também é do sistema e não tem texto do app, mas o vidro dele se adapta ao que tem atrás e assenta depois de a tela abrir: na obra em List, com o texto apagado, de 1 a 8 s, e o print sai aos 2 s. O vidro diferente virava \"texto\" a 1,63:1. Agora o quadro de cada voltar (com a folha aberta, também o da tela de baixo) fica de fora, como os dois; nas cenas roladas, a borda de cima já o deixava."
```

### Task 5: A auditoria da obra na maior letra no topo, e o A pagar à parte

A auditoria do Xcode (`performAccessibilityAudit`) troca a letra, da padrão para a maior e de volta, em volta de cada
auditoria, no iOS 26 e no 27. Com a obra numa `List`, isso tem dois efeitos, medidos em 03/11 (CI 41706879156 e o Mac):
- **Sem elemento.** Rolada, a obra mudava de lugar durante a troca: a `List` guarda o número da rolagem e, na volta, as linhas
  de cima ficam na altura estimada. A tela ia de "Corrigido pelo banco / A pagar" para "Outubro de 2026", e a auditoria
  perdia os textos: 5 "Dynamic Type font sizes are unsupported" e 5 "Text clipped", sem elemento. A `main` volta ao mesmo
  lugar. Isso é diferença para a pessoa que muda o Tamanho do Texto com a obra rolada, e o conserto é do app, na ponte
  (9), com teste próprio.
- **Com elemento.** Mesmo com a obra segurando a linha do alto, a célula se mede de novo durante a troca, e dois textos do
  bloco A pagar saem como cortados: "3 vencimentos" (a etiqueta) e "Parcelas e gastos futuros" (a nota). Caem 3 de 3 no
  26.5 e 2 de 2 no 27. Na tela, os dois estão inteiros (print em `prumo-plano-obra-list/prototipo-letra/fl9/`). A `main`
  também não é firme nesse teste no iOS 27: 1 de 2.

**Decidido pelo Orquestrador, a contar ao Giovani (03/11, duas rodadas):**
- a `testObraNoMaiorTamanho` audita a obra na maior letra só no topo, nos dois sistemas, e volta a valer na CI do iOS 26;
- o bloco A pagar ganha auditoria própria na maior letra, com prova de que ela pega um corte de verdade nele;
- os dois achados da obra rolada ficam como problema conhecido (Como entregar).

**O A pagar à parte.** A vitrine das peças (`CUSTTA_ABRIR=pecas`, só Debug) não tinha o bloco. Com `-custta.vitrineAPagar`, ela
abre com ele no alto, montado com as peças do app (a etiqueta de indicador, o valor e a nota, com a seta), e a
`testAPagarNoMaiorTamanho` o audita sem rolar. Rolado, não serve: na vitrine, que é uma ScrollView, as auditorias de 900 a
3600 pt caíam todas na mesma tela, porque a troca de letra tira a rolagem do lugar. Sem o argumento, a vitrine fica como
hoje.
- **Sem o botão.** No app, o bloco é um botão, que vira um elemento só para a acessibilidade, e a auditoria não vê os
  textos dentro dele: com o `lineLimit(1)` na nota, a vitrine com o botão passava. Na vitrine, o bloco vai sem o botão e com
  os textos um a um (`.accessibilityElement(children: .contain)`), como os outros blocos dela.

A tarefa vem antes da troca e se prova na estrutura de hoje.

**Files:**
- Modify: `app-ios/Custta/Falsos/VitrineDasPecas.swift`
- Test (alterar): `app-ios/CusttaUITests/AuditoriaUITests.swift`

**Interfaces:**
- Consumes: `AuditoriaUITests.auditar(_:_:corteSemElemento:)`, `EtiquetaDoIndicador`, `NotaDoBloco`, `SetaDoBloco`,
  `IndicadoresDaObra` (`etiquetaDoAPagar`, `aPagar`).
- Produces: `-custta.vitrineAPagar` (Debug); `AuditoriaUITests.testAPagarNoMaiorTamanho`.

- [ ] **Step 1: Escrever os testes**

Em `app-ios/CusttaUITests/AuditoriaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -148,12 +148,29 @@ final class AuditoriaUITests: XCTestCase {
         try auditar(app, tiposDeAuditoria)
     }
 
+    /// A obra (a v1) na maior letra, no topo. Rolada, não: a obra é uma List, e a auditoria troca a letra (padrão e maior) em
+    /// volta de cada auditoria, no iOS 26 e no 27. A List se mede de novo durante a troca, e textos do bloco A pagar ("3
+    /// vencimentos", "Parcelas e gastos futuros") saíam como cortados, com a tela mostrando os dois inteiros (problema
+    /// conhecido, 03/11; a LazyVStack também não era firme nesse teste no iOS 27, 1 de 2). Abaixo da dobra, a auditoria na
+    /// maior letra fica assim: o A pagar na testAPagarNoMaiorTamanho; a v2 a 800 e no fim e a v3 no fim na
+    /// testParte3NoMaiorTamanho; as peças da vitrine no alto dela e numa tela rolada na testVitrineDasPecasNoMaiorTamanho. As
+    /// ações, os afazeres, a pílula e o A vencer da v1 rolada ficam sem auditoria na maior letra (problema conhecido).
     @MainActor func testObraNoMaiorTamanho() throws {
         let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: maiorLetra + parado)
         XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
         try auditar(app, tiposDeAuditoria)
-        rolar(app)
-        try auditar(app, tiposDeAuditoria)
+    }
+
+    /// O bloco A pagar da obra na maior letra, inteiro: a etiqueta dos vencimentos e a nota "Parcelas e gastos futuros". Na
+    /// obra, ele fica abaixo da dobra, e a auditoria olha só o topo; rolado, numa List ou numa ScrollView, a troca de letra
+    /// da auditoria tira a rolagem do lugar (na vitrine, as rolagens de 900 a 3600 caíam todas na mesma tela). Aqui ele vem
+    /// no alto da vitrine das peças (`-custta.vitrineAPagar`) e é auditado sem rolar.
+    @MainActor func testAPagarNoMaiorTamanho() throws {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "pecas",
+                           argumentos: maiorLetra + parado + ["-custta.vitrineAPagar", "YES"])
+        XCTAssertTrue(app.elemento("vitrine-aPagar").waitForExistence(timeout: 10))
+        Thread.sleep(forTimeInterval: 1.5)
+        try auditar(app, [.dynamicType, .textClipped])
     }
 
     /// A vitrine das peças da identidade nova (etapa 4, PR 1b; só no Debug, com CUSTTA_ABRIR=pecas) na maior letra, em
```

- [ ] **Step 2: O A pagar na vitrine**

Em `app-ios/Custta/Falsos/VitrineDasPecas.swift`:

```diff
--- a/app-ios/Custta/Falsos/VitrineDasPecas.swift
+++ b/app-ios/Custta/Falsos/VitrineDasPecas.swift
@@ -15,6 +15,9 @@ struct VitrineDasPecas: View {
     ])])])).obras[0].gastos[0]
     @Environment(\.paleta) private var paleta
     @Environment(\.dynamicTypeSize) private var letra
+    /// Com `-custta.vitrineAPagar`, a vitrine abre com o bloco A pagar da obra no alto, para a auditoria na maior letra o ver
+    /// sem rolar (AuditoriaUITests.testAPagarNoMaiorTamanho).
+    @AppStorage("custta.vitrineAPagar") private var aPagarNoAlto = false
 
     var body: some View {
         let casa = estado.obras[0]
@@ -22,6 +25,7 @@ struct VitrineDasPecas: View {
         let indicadores = indicadoresDaObra(casa, taxa: estado.config.taxaMensal, hoje: hoje)
         ScrollView {
             VStack(alignment: .leading, spacing: Grade.entreBlocos) {
+                if aPagarNoAlto { aPagar(indicadores) }
                 TituloMono(texto: casa.nome, identificador: "vitrine-titulo")
                 CapsulaDeMetadados {
                     EtiquetaDeFase(fase: casa.fase, grande: true)
@@ -113,5 +117,27 @@ struct VitrineDasPecas: View {
         .navigationBarTitleDisplayMode(.inline)
         .toolbar { ToolbarItem(placement: .principal) { TituloPequenoMono(texto: casa.nome, letra: letra) } }
     }
+
+    /// O bloco A pagar da obra: o rótulo do botão em BlocosDaObra.aPagar, com a etiqueta dos vencimentos e a nota, montado
+    /// com as mesmas peças. Sem o botão e com os textos um a um, como os outros blocos da vitrine: dentro do botão, a
+    /// auditoria não os vê.
+    private func aPagar(_ indicadores: IndicadoresDaObra) -> some View {
+        HStack(spacing: 10) {
+            VStack(alignment: .leading, spacing: 0) {
+                CabecalhoDoBloco(rotulo: "A pagar · 30 dias") {
+                    EtiquetaDoIndicador(texto: indicadores.etiquetaDoAPagar, cor: .alerta)
+                }
+                ValorEmDinheiro(indicadores.aPagar, mono: .bloco)
+                NotaDoBloco(texto: "Parcelas e gastos futuros")
+            }
+            .frame(maxWidth: .infinity, alignment: .leading)
+            SetaDoBloco()
+        }
+        .padding(.vertical, Grade.recuoVertical(letra))
+        .padding(.horizontal, Grade.recuo)
+        .superficie(.conteudo, em: .rect(cornerRadius: Grade.raioDoBloco(letra)))
+        .accessibilityElement(children: .contain)
+        .accessibilityIdentifier("vitrine-aPagar")
+    }
 }
 #endif
```

- [ ] **Step 3: Ver passar na estrutura de hoje**

Run:
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/AuditoriaUITests/testAPagarNoMaiorTamanho \
  -only-testing:CusttaUITests/AuditoriaUITests/testObraNoMaiorTamanho \
  -only-testing:CusttaUITests/AuditoriaUITests/testVitrineDasPecasNoMaiorTamanho 2>&1 | grep -E "Test Case .*(passed|failed)"
```
Expected (no 26.5 do Mac; no 27, os mesmos três):
```
Test Case '-[CusttaUITests.AuditoriaUITests testAPagarNoMaiorTamanho]' passed (12.720 seconds).
Test Case '-[CusttaUITests.AuditoriaUITests testObraNoMaiorTamanho]' passed (8.910 seconds).
Test Case '-[CusttaUITests.AuditoriaUITests testVitrineDasPecasNoMaiorTamanho]' passed (52.549 seconds).
```

- [ ] **Step 4: Mutação: a auditoria do A pagar morde**

Ponha `.lineLimit(1)` no `Text` da `EtiquetaDoIndicador` (`PecasDaObra.swift`) e rode só a `testAPagarNoMaiorTamanho`;
desfaça e faça o mesmo no `Text` da `NotaDoBloco` (`Blocos.swift`). Cada uma tem de cair no texto dela. Para cada mutação:
```bash
xcodebuild build-for-testing "${XB[@]}" -derivedDataPath <seu dd> 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/AuditoriaUITests/testAPagarNoMaiorTamanho 2>&1 \
  | grep -E "auditoria \| .*reprova|Test Case .*(passed|failed)"
```

Expected (no 26.5, com a `List` já na ponta: a vitrine é uma ScrollView e não muda com ela), na etiqueta e na nota:
```
auditoria | Text clipped | 48 "3 vencimentos"  (44.0, 265.66666666666663, 271.66666666666663, 52.666666666666686) | barra até 140.0, conteúdo até 734.0 | reprova
Test Case '-[CusttaUITests.AuditoriaUITests testAPagarNoMaiorTamanho]' failed (11.627 seconds).
auditoria | Text clipped | 48 "Parcelas e gastos futuros"  (34.0, 431.3333333333333, 302.3333333333333, 58.666666666666686) | barra até 140.0, conteúdo até 734.0 | reprova
Test Case '-[CusttaUITests.AuditoriaUITests testAPagarNoMaiorTamanho]' failed (10.815 seconds).
```

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Falsos/VitrineDasPecas.swift app-ios/CusttaUITests/AuditoriaUITests.swift
git commit -m "test: auditoria da obra na maior letra no topo, e o A pagar à parte" -m "A auditoria do Xcode troca a letra (padrão e maior) em volta de cada auditoria. Com a obra numa List, ela se mede de novo durante a troca, e, com a obra rolada, textos do bloco A pagar (\"3 vencimentos\", \"Parcelas e gastos futuros\") saíam como cortados, com a tela mostrando os dois inteiros, no iOS 26 e no 27. A auditoria da obra na maior letra passa a olhar só o topo, nos dois sistemas. O bloco A pagar ganha uma auditoria própria na maior letra: com -custta.vitrineAPagar, a vitrine das peças abre com ele no alto, montado com as peças do app e os textos um a um, e a auditoria o vê sem rolar. Rolada, a troca de letra tira a rolagem do lugar também numa ScrollView."
```

### Task 6: A obra numa List, com um cartão por mês numa linha

A troca em si.
- **Por quê.** No iOS 26, a LazyVStack da obra entra em laço de layout ao arrastar na maior letra numa obra de lista curta.
  Na CI, a estrutura de hoje travou 2 de 3 e a `List`, 0 de 3 (run 41530054757). A busca com a lista à vista, que travava
  a estrutura de um bloco só, passa 10 de 10 na `List` no 26.5.
- **A estrutura.** As peças continuam as mesmas e no mesmo recuo do código. Só muda o contêiner: `List` `.plain`, uma peça
  por linha e o cartão de cada mês numa linha.
- **Os modificadores.**
  - Linha sem recuo, separador nem fundo.
  - `listRowSpacing` 12 e `defaultMinListRowHeight` 0.
  - A margem da `List` dá a borda de 16 pt e os 98 pt de baixo.
  - `buttonStyle(.borderless)`: cada botão da linha (a lupa, o mês) responde ao próprio toque, e não ao da linha.
  - O chevron que a `List` põe nos `NavigationLink` (o Orçamento e os afazeres) fica escondido; ele estreitava o bloco.
- **A cápsula.** Do sólido para baixo, uma `Section`. Os 16 pt entre a cápsula e o sólido vêm do espaço antes dela, e não de
  um recuo dentro da célula da cápsula. Na `List`, a célula é o elemento de acessibilidade, e o recuo deixaria o anel do
  VoiceOver 4 pt mais alto (o teste da grade mediria 12, não 16).
- **O anel do VoiceOver.** Sozinha numa linha, a peça vira a célula inteira para o VoiceOver: o anel da cápsula ia a 370 pt
  de largura (269 hoje; 355 na maior letra), e o da soma dos achados também (266 hoje). Uma vista vazia do UIKit no fundo da
  peça (`QuadroProprio`, no título, na cápsula e na soma) faz da célula um contêiner, e o anel volta ao quadro da peça. Na
  varredura de 03/11 (letra padrão e maior, obra pronta, a pílula à vista), os 31 identificadores em comum com a `main` têm o
  mesmo quadro. O `testOAltoEmBlocosNaGrade` e o `testBuscarSemAcentoPeloTopicoEPelaDescricao` passam a vigiar a largura.
  Com a ponte (9), mais duas guardas: a cápsula na maior letra e a pílula sozinha da obra sem gastos.
- **O id da pílula.** O `.id("lancamentos")` vai na linha inteira, por fora do recuo de 6 pt: o `scrollTo` da `List` só acha
  o id da linha. Mesmo assim, a lupa não leva a pílula ao topo nesta tarefa: o `scrollTo` da `List` não rola uma linha que
  já está na tela, e a pílula está: ela fica onde a lista estava (no teste da busca, em y 641 no 26.5 e 396 na CI; o teste quer menos de 200). Quem a leva é a ponte,
  na 9.
- **O teclado da busca.** Nada muda nesta tarefa: fica o `.scrollDismissesKeyboard(.interactively)` de hoje. Hoje, o arrasto
  curto (de 55% a 45% da tela) deixa o teclado aberto, e uma série de arrastos longos o fecha, porque o campo sai da janela
  da LazyVStack, meia tela além da borda, e perde o foco. Na `List`, a célula com o foco fica viva, e os arrastos longos
  deixam de fechar o teclado até a ponte (9), que dá a janela da `List` para medir o campo. Até lá, a 1ª letra
  digitada enquanto o teclado sobe também pode rolar o campo para baixo da barra (3 em 5 na sonda de 03/11, sem a ponte);
  com a ponte, que segura a linha do alto quando o filtro muda, 5 em 5 ficam no lugar.
- **O toque fora das linhas.** Sai o toque na pilha que fechava a linha aberta. Hoje, qualquer toque que nenhuma peça usa a
  fecha: o vão entre duas linhas (aceito pelo Giovani em 03/11), mas também o título, a cápsula, os blocos de número, o
  cabeçalho do mês e os gastos por tópico. Na `List`, só rolar, tocar outra linha e tocar o A pagar fecham. O alcance
  inteiro está no checklist do aparelho (11), para o Giovani dizer se serve.
- **Depois desta tarefa:** a rolagem fixa dos testes de tela ainda não rola a `List`, porque o gancho é a 7. Os
  testes que caem até a ponte, que é a 9, estão no fim da 8, com a saída do 26.5.

**Files:**
- Modify: `app-ios/Custta/Telas/BlocosDaObra.swift`
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Test (alterar): `app-ios/CusttaUITests/BuscaUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/EstadosUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/FolhasDeOrigemUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/ObraUITests.swift`

**Interfaces:**
- Consumes: as peças da obra (`TituloMono`, `CapsulaDeMetadados`, `BlocosDaObra`, `AcoesDaFaseView`, `CartaoDoMes`…).
- Produces: nada novo; a `ObraView` passa a ser uma `List`.

- [ ] **Step 1: As guardas do anel e os comentários dos testes**

A prova da troca é a o4 sem pulo (8). Aqui, prova-se que a tela não muda e que o quadro de acessibilidade é o de
hoje. As guardas novas: o anel do título e o da cápsula mais estreitos que a coluna, e o da soma dos achados também. Os
comentários que falavam da LazyVStack da obra passam a falar da `List`.

Em `app-ios/CusttaUITests/BuscaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/BuscaUITests.swift
+++ b/app-ios/CusttaUITests/BuscaUITests.swift
@@ -70,6 +70,8 @@ final class BuscaUITests: XCTestCase {
         XCTAssertLessThan(app.elemento("lancamentos").frame.minY, 200, "a lista rola até a pílula, com o campo embaixo")
         XCTAssertEqual(pilula(app), "Lançamentos, 12 de 46")
         XCTAssertEqual(app.elemento("somaDosAchados").label, "Soma dos achados: R$\u{a0}95.120,30")
+        XCTAssertLessThan(app.elemento("somaDosAchados").frame.width, app.frame.width - 32 - 40,
+                          "o anel do VoiceOver abraça a soma, e não a linha da List")
         let aVencer = app.elemento("aVencer")
         XCTAssertEqual(aVencer.value as? String, "aberto", "com filtro, o A vencer abre sozinho")
         XCTAssertTrue(aVencer.label.hasPrefix("A vencer, R$\u{a0}36.900,00, 6 gastos"), aVencer.label)
@@ -228,8 +230,8 @@ final class BuscaUITests: XCTestCase {
         let lupa = app.buttons["buscar"], mes = app.buttons["filtrarPorMes"]
         app.rolarAte(mes, tentativas: 20)                 // na maior letra, as 12 roladas do padrão chegam sem folga
         escolherMes(app, "Junho de 2023")
-        // O chip e a soma dos achados, que o mês põe embaixo dos botões, levam o gasto para baixo da dobra, onde a
-        // LazyVStack pode ainda não o ter criado (no iOS 26 da CI, não tinha): espera o chip e rola até a linha.
+        // O chip e a soma dos achados, que o mês põe embaixo dos botões, levam o gasto para baixo da dobra, onde a List
+        // pode ainda não ter criado a célula dele (no iOS 26 da CI, não tinha): espera o chip e rola até a linha.
         XCTAssertTrue(app.elemento("chipDoMes").waitForExistence(timeout: 5))
         let linha = app.elemento("gasto-j1")              // o único gasto da obra
         app.rolarAte(linha)
```

Em `app-ios/CusttaUITests/EstadosUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/EstadosUITests.swift
+++ b/app-ios/CusttaUITests/EstadosUITests.swift
@@ -102,8 +102,8 @@ final class EstadosUITests: XCTestCase {
         app.buttons["salvarGasto"].doubleTap()
         XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5))
         sleep(1)
-        // A lista rolou até a linha nova (o destaque). Com a obra em blocos (etapa 4), o alto fica longe e sai da lista
-        // preguiçosa: o nome vem do título pequeno da barra, e a contagem, da pílula "Lançamentos", logo acima da linha.
+        // A lista rolou até a linha nova (o destaque). Com a obra em blocos (etapa 4), o alto fica longe e sai da List: o
+        // nome vem do título pequeno da barra, e a contagem, da pílula "Lançamentos", logo acima da linha.
         XCTAssertEqual(app.elemento("tituloPequenoDaBarra").label, "Casa Alphaville")
         XCTAssertTrue(app.elemento("lancamentos").label.contains("47"), app.elemento("lancamentos").label)
     }
```

Em `app-ios/CusttaUITests/FolhasDeOrigemUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/FolhasDeOrigemUITests.swift
+++ b/app-ios/CusttaUITests/FolhasDeOrigemUITests.swift
@@ -27,7 +27,7 @@ final class FolhasDeOrigemUITests: XCTestCase {
     /// A seta do indicador "A pagar · 30 dias": rola até ele e toca; a folha abre com o resumo.
     private func abrirAPagar(_ app: XCUIApplication) {
         let indicador = app.elemento("indicadorAPagar")
-        // Rola antes de exigir: na maior letra o A pagar nasce fora da janela e, solto na LazyVStack da obra, só entra na
+        // Rola antes de exigir: na maior letra o A pagar fica abaixo da dobra e, numa linha da List da obra, só entra na
         // árvore quando a lista chega nele (o rolarAte pergunta pelo exists a cada volta e rola enquanto não acha).
         app.rolarAte(indicador)
         XCTAssertTrue(indicador.waitForExistence(timeout: 5))
```

Em `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -603,7 +603,7 @@ extension LeituraNoVidroUITests {
     @MainActor func testLeituraDaParte3NaMaiorLetra() {
         let escuro = ["-custta.tema", "escuro"] + piorMomento + maiorLetra
         cobrar([
-            // Espera o lápis da barra: rolada, o título sai da pilha preguiçosa antes da espera achar. A 1977 pt, as ações à vista
+            // Espera o lápis da barra: rolada, o título sai da List antes da espera achar. A 1977 pt, as ações à vista
             // nos dois iPhones (a 1100 da etapa 3, a obra em blocos punha a tela entre o A pagar e a Venda estimada, sem ação
             // nenhuma). A obra quebra 162 pt a mais no 18 Pro, e nenhuma rolagem acha um vão comum fora do "Toque no lápis para
             // informar o valor": no 18 Pro (a largura da CI), a borda fica entre a 1ª e a 2ª linha dessa frase (6 pt abaixo da
```

Em `app-ios/CusttaUITests/ObraUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/ObraUITests.swift
+++ b/app-ios/CusttaUITests/ObraUITests.swift
@@ -87,7 +87,7 @@ final class ObraUITests: XCTestCase {
         // No fim da rolagem, o último gasto fica à vista, acima da cápsula de abas (mockup: o conteúdo termina 132 pt acima
         // da borda de baixo).
         let ultimo = app.elemento("gasto-g001")
-        var fim = -1.0                                   // a pilha cria o último gasto antes de ele entrar na tela
+        var fim = -1.0                                   // a List cria o último cartão um pouco antes de ele entrar na tela
         for _ in 0..<16 {
             app.swipeUp()
             guard ultimo.exists else { continue }
@@ -129,6 +129,9 @@ final class ObraUITests: XCTestCase {
         XCTAssertEqual(titulo.minX, 16, accuracy: 0.5, "o título solto na borda de 16 pt")
         XCTAssertEqual(fase.minX, 16, accuracy: 0.5, "a cápsula na borda de 16 pt")
         XCTAssertEqual(quadros[0].minY - fase.maxY, 16, accuracy: 0.5, "a cápsula 16 pt acima do sólido")
+        // O anel do VoiceOver abraça a peça, e não a linha da List (a cápsula tem 269 pt, o título 258, a coluna 370).
+        XCTAssertLessThan(titulo.width, largura - 32 - 40, "o anel do título abraça o título: \(titulo)")
+        XCTAssertLessThan(fase.width, largura - 32 - 40, "o anel da cápsula abraça a cápsula: \(fase)")
         XCTAssertFalse(app.elemento("indicadorLucro").exists, "fora da vendida, o sólido é o Total gasto")
     }
 
```

- [ ] **Step 2: Implementar**

Em `app-ios/Custta/Telas/BlocosDaObra.swift`:

```diff
--- a/app-ios/Custta/Telas/BlocosDaObra.swift
+++ b/app-ios/Custta/Telas/BlocosDaObra.swift
@@ -35,11 +35,11 @@ func comSinal(_ valor: Double) -> String {
     valor < 0 ? "\u{2212}" + moeda(-valor) : "+" + moeda(valor)
 }
 
-/// O sólido e os blocos de vidro do alto da obra, 12 pt um do outro (o espaço da LazyVStack da obra). Cada bloco é um filho
-/// dela, num Group, e não um VStack só: no iOS 26, os blocos num filho único de ~630 pt (~2.500 na maior letra) faziam a
-/// LazyVStack reestimar a lista inteira cada vez que ele entrava e saía da janela, e abrir a busca perto da lista (a lupa,
-/// "ceramica" e o buscar do teclado) prendia a thread principal num laço de layout (sonda de 02/11, iOS 26.5: 10 travas em 10
-/// com o VStack, nenhuma em 2 com os blocos soltos).
+/// O sólido e os blocos de vidro do alto da obra, 12 pt um do outro (o espaço entre as linhas da List da obra). Cada bloco é
+/// uma linha dela, num Group, e não um VStack só: uma linha se mede sozinha. Na LazyVStack de antes, no iOS 26, os blocos num
+/// filho único de ~630 pt (~2.500 na maior letra) faziam a lista reestimar tudo cada vez que ele entrava e saía da janela, e
+/// abrir a busca perto da lista (a lupa, "ceramica" e o buscar do teclado) prendia a thread principal num laço de layout
+/// (sonda de 02/11, iOS 26.5: 10 travas em 10 com o VStack, nenhuma em 2 com os blocos soltos).
 struct BlocosDaObra: View {
     let obra: Obra
     let taxa: Double
```

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -71,18 +71,24 @@ struct ObraView: View {
                                      perguntando = true
                                  })
         return ScrollViewReader { leitor in
-            ScrollView {
-                LazyVStack(alignment: .leading, spacing: Grade.entreBlocos) {
+            // A obra numa List (UICollectionView), uma peça por linha e um cartão por mês numa linha: no iOS 26, a LazyVStack
+            // entrava em laço de layout ao arrastar na maior letra numa obra de lista curta (#99).
+            List {
+                Group {
                     // O título solto e a cápsula com a fase e o tempo: 8 pt entre eles e 16 até o sólido (mockup, .ob-meta-w).
                     TituloMono(texto: obra.nome)
                         .padding(EdgeInsets(top: -6, leading: 0, bottom: -4, trailing: 0))
+                        .background { QuadroProprio() }
                     CapsulaDeMetadados {
                         EtiquetaDeFase(fase: obra.fase, grande: true)
                         Text(textoDoInicio(obra, hoje: hoje))
                     }
                     .accessibilityElement(children: .combine)
                     .accessibilityIdentifier("faseDaObra")
-                    .padding(.bottom, 4)
+                    .background { QuadroProprio() }
+                    // Do sólido para baixo, uma Section própria: os 16 pt até o sólido vêm do espaço entre as Sections, e não
+                    // de um recuo na célula da cápsula, que é o elemento de acessibilidade dela (o anel do VoiceOver).
+                    Section {
                     BlocosDaObra(obra: obra, taxa: taxa, hoje: hoje) {
                         // Com uma linha arrastada aberta, o toque só a fecha, como o das linhas.
                         if linhaAberta != nil { fecharLinha(); return }
@@ -114,14 +120,14 @@ struct ObraView: View {
                         .accessibilityValue(faladoDaBarra(pedacos, topicos: topicos))
                         .accessibilityIdentifier("gastosPorTopico")
                     }
-                    // 18 pt acima dos lançamentos (mockup, .lan-cab). O id vem antes do recuo: a lupa rola até a pílula, e não
-                    // até os 6 pt de cima dela.
+                    // 18 pt acima dos lançamentos (mockup, .lan-cab). O id fica na linha inteira, por fora do recuo: o scrollTo
+                    // da List só acha o id da linha, e a lupa rola até a pílula com os 6 pt de cima dela.
                     CabecalhoDosLancamentos(contador: contadorLancamentos(total: obra.gastos.count, achados: achados.count, filtro: busca.filtro),
                                             busca: busca, meses: mesesDoFiltro(obra.gastos, escolhido: busca.mes),
                                             comBotoes: !obra.gastos.isEmpty || filtrando || busca.aberta, foco: $foco,
                                             abrir: { abrirBusca(leitor) }, fechar: fecharBusca)
-                        .id("lancamentos")
                         .padding(.top, 6)
+                        .id("lancamentos")
                     if busca.aberta {
                         CampoDaBusca(texto: $busca.texto, foco: $buscaEmFoco, fechar: fecharBusca)
                     }
@@ -130,6 +136,7 @@ struct ObraView: View {
                     }
                     if let soma = somaDosAchados(achados, filtrando: filtrando) {
                         SomaDosAchadosView(soma: soma)
+                            .background { QuadroProprio() }
                     }
                     if obra.gastos.isEmpty {
                         CartaoDeEstado(titulo: "Nenhum gasto lançado.", texto: "Toque no + para lançar o primeiro.", icone: "Icones/notas",
@@ -147,17 +154,29 @@ struct ObraView: View {
                             CartaoDoMes(mes: mes, topicos: topicos, lista: acoes)
                         }
                     }
+                    }
+                    .listSectionSpacing(16)
                 }
-                .padding(.horizontal, Grade.externa)
-                // A linha do gasto na forma mono da identidade nova (as folhas ficam com a da etapa 3).
-                .environment(\.linhaMono, true)
-                // O fim da lista fica à vista acima da cápsula de abas, como no mockup: 132 pt da borda de baixo (a cápsula, de
-                // 62 a 22 da borda, e 48 de folga), menos os 34 do indicador de início, que a rolagem já desconta.
-                .padding(.bottom, 98)
-                // Tocar fora da linha aberta fecha (o "Apagar" é um botão e vence este toque).
-                .contentShape(.rect)
-                .onTapGesture { if linhaAberta != nil { fecharLinha() } }
+                // Sem recuo, separador nem fundo de linha. A borda de 16 pt vem da margem da List, e não do recuo da linha: a
+                // célula, que na List é o elemento de acessibilidade, fica com a largura do bloco (x 16, 370 pt num 402).
+                .listRowInsets(EdgeInsets())
+                .listRowSeparator(.hidden)
+                .listRowBackground(Color.clear)
+                // O Orçamento e os afazeres (NavigationLink) sem o chevron da célula, que estreitava o bloco.
+                .navigationLinkIndicatorVisibility(.hidden)
             }
+            .listStyle(.plain)
+            .listRowSpacing(Grade.entreBlocos)
+            .environment(\.defaultMinListRowHeight, 0)
+            .scrollContentBackground(.hidden)
+            // Cada botão de uma linha responde ao próprio toque (a lupa e o mês ao lado da pílula), e não ao da linha inteira.
+            .buttonStyle(.borderless)
+            // A linha do gasto na forma mono da identidade nova (as folhas ficam com a da etapa 3).
+            .environment(\.linhaMono, true)
+            .contentMargins(.horizontal, Grade.externa, for: .scrollContent)
+            // O fim da lista fica à vista acima da cápsula de abas, como no mockup: 132 pt da borda de baixo (a cápsula, de
+            // 62 a 22 da borda, e 48 de folga), menos os 34 do indicador de início, que a rolagem já desconta.
+            .contentMargins(.bottom, 98, for: .scrollContent)
             // Só com a obra à vista: o gasto lançado pelo + da tela Orçamento não rola nem leva o foco aqui, por baixo dela.
             .onChange(of: folhas.destaque) { _, d in if let d, caminho.last == .obra(obra.id) { mostrar(d, lista: lista, leitor: leitor) } }
         }
@@ -516,3 +535,17 @@ struct SeparadorDaLista: View {
         if mono { LinhaFina().padding(.horizontal, Grade.recuo) } else { LinhaFina().padding(.leading, 67) }
     }
 }
+
+/// O quadro próprio de uma peça sozinha numa linha da List (o título, a cápsula, a soma dos achados): uma vista vazia do
+/// UIKit no fundo da linha. Sem ela, a célula inteira vira o elemento de acessibilidade, e o anel do VoiceOver toma a linha
+/// toda (a cápsula com 370 pt de largura, e não os 269 dela). Com ela, a célula vira um contêiner, e a peça fica com o quadro
+/// dela, igual ao da ScrollView. Depende de a List ser uma UICollectionView, como a ponte; o testOAltoEmBlocosNaGrade vigia.
+private struct QuadroProprio: UIViewRepresentable {
+    func makeUIView(context: Context) -> UIView {
+        let vista = UIView()
+        vista.isUserInteractionEnabled = false
+        return vista
+    }
+
+    func updateUIView(_ uiView: UIView, context: Context) {}
+}
```

- [ ] **Step 3: Ver a grade e os quadros**

Run:
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/ObraUITests/testOAltoEmBlocosNaGrade \
  -only-testing:CusttaUITests/ObraUITests/testVendidaComPrejuizoNoTotal \
  -only-testing:CusttaUITests/ObraUITests/testAfazeresEGastosPorTopicoEmBlocos \
  -only-testing:CusttaUITests/BuscaUITests/testBuscarSemAcentoPeloTopicoEPelaDescricao 2>&1 | grep -E "Test Case .*(passed|failed)|error:"
```
Expected: os três da obra `passed`. O da busca cai só na pílula, que a ponte leva ao topo na 9; a guarda da
soma passa. Com o recuo de 4 pt dentro da célula da cápsula, em vez da `Section`, o `testOAltoEmBlocosNaGrade` cai com
`("12.0") is not equal to ("16.0") +/- ("0.5") - a cápsula 16 pt acima do sólido`.
```
BuscaUITests.swift:70: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : XCTAssertLessThan failed: ("396.3333333333333") is not less than ("200.0") - a lista rola até a pílula, com o campo embaixo
BuscaUITests.swift:83: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : XCTAssertEqual failed: ("Lançamentos, 12 de 46") is not equal to ("Lançamentos, 46") - o × do texto limpa a busca
BuscaUITests.swift:88: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : XCTAssertEqual failed: ("Lançamentos, 0 de 46") is not equal to ("Lançamentos, 12 de 46") - com acento, maiúscula e espaço no fim, o mesmo
BuscaUITests.swift:89: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Any` -> `Elements matching predicate '"aVencer" IN identifiers'`, given input App element pid: 3984
Test Case '-[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao]' failed (42.010 seconds).
Test Case '-[CusttaUITests.ObraUITests testAfazeresEGastosPorTopicoEmBlocos]' passed (15.407 seconds).
Test Case '-[CusttaUITests.ObraUITests testOAltoEmBlocosNaGrade]' passed (7.874 seconds).
Test Case '-[CusttaUITests.ObraUITests testVendidaComPrejuizoNoTotal]' passed (6.981 seconds).
```

- [ ] **Step 4: A guarda do anel morde**

Tire as três linhas `.background { QuadroProprio() }` da `ObraView`, compile, rode os mesmos dois testes da guarda e ponha as
linhas de volta:
```bash
xcodebuild build-for-testing "${XB[@]}" -derivedDataPath <seu dd> 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/ObraUITests/testOAltoEmBlocosNaGrade \
  -only-testing:CusttaUITests/BuscaUITests/testBuscarSemAcentoPeloTopicoEPelaDescricao 2>&1 | grep -E "error:"
```
Expected: o anel do título, o da cápsula e o da soma com a largura da linha:
```
BuscaUITests.swift:70: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : XCTAssertLessThan failed: ("396.3333333333333") is not less than ("200.0") - a lista rola até a pílula, com o campo embaixo
BuscaUITests.swift:73: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : XCTAssertLessThan failed: ("370.0") is not less than ("330.0") - o anel do VoiceOver abraça a soma, e não a linha da List
BuscaUITests.swift:83: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : XCTAssertEqual failed: ("Lançamentos, 12 de 46") is not equal to ("Lançamentos, 46") - o × do texto limpa a busca
BuscaUITests.swift:88: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : XCTAssertEqual failed: ("Lançamentos, 0 de 46") is not equal to ("Lançamentos, 12 de 46") - com acento, maiúscula e espaço no fim, o mesmo
BuscaUITests.swift:89: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Any` -> `Elements matching predicate '"aVencer" IN identifiers'`, given input App element pid: 2392
ObraUITests.swift:133: error: -[CusttaUITests.ObraUITests testOAltoEmBlocosNaGrade] : XCTAssertLessThan failed: ("370.0") is not less than ("330.0") - o anel do título abraça o título: (16.0, 116.0, 370.0, 26.0)
ObraUITests.swift:134: error: -[CusttaUITests.ObraUITests testOAltoEmBlocosNaGrade] : XCTAssertLessThan failed: ("370.0") is not less than ("330.0") - o anel da cápsula abraça a cápsula: (16.0, 154.0, 370.0, 67.66666666666666)
```

- [ ] **Step 5: Ver a tela igual**

Run: os prints antes × depois de "Como entregar", só as cenas do topo (a rolagem fixa ainda não rola a `List`):
```bash
bash $F/prints-da-obra.sh <udid> <seu dd>/Build/Products/Debug-iphonesimulator/Custta.app <prints>/depois-6 'topo'
python3 -I $F/compara-prints.py <prints>/antes <prints>/depois-6 --cenas 'topo'
```
Expected (no 26.5; as tarefas seguintes não mexem nas cenas do topo, e a saída é a da ponta):
```
porTopico-topo-claro.png: canais >16: 0, >48: 0, máx 1, média 0.000
porTopico-topo-escuro.png: canais >16: 0, >48: 0, máx 3, média 0.000
v1-ax5-topo-claro.png: canais >16: 70751, >48: 0, máx 35, média 0.480  ← passa do limite
v1-ax5-topo-escuro.png: canais >16: 0, >48: 0, máx 10, média 0.080
v1-topo-claro.png: canais >16: 0, >48: 0, máx 0, média 0.000
v1-topo-escuro.png: canais >16: 0, >48: 0, máx 3, média 0.000
v2-topo-claro.png: canais >16: 0, >48: 0, máx 0, média 0.000
v2-topo-escuro.png: canais >16: 0, >48: 0, máx 1, média 0.000
v3-topo-claro.png: canais >16: 0, >48: 0, máx 3, média 0.003
v3-topo-escuro.png: canais >16: 0, >48: 0, máx 0, média 0.000
```

A `v1-ax5-topo-claro` tem dois estados de uma abertura para outra, nas duas estruturas: o véu de baixo, sobre o número do sólido, assenta em tons diferentes. Duas tiragens da própria `main` diferem em 70.751 canais (máx. 35, nenhum acima de 48); entre a `main` e a `List`, na mesma tiragem, a diferença é 0. Se ela passar do limite, tire de novo as duas.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Telas/BlocosDaObra.swift app-ios/Custta/Telas/ObraView.swift app-ios/CusttaUITests/BuscaUITests.swift app-ios/CusttaUITests/EstadosUITests.swift app-ios/CusttaUITests/FolhasDeOrigemUITests.swift app-ios/CusttaUITests/LeituraNoVidroUITests.swift app-ios/CusttaUITests/ObraUITests.swift
git commit -m "feat: obra numa List, com um cartão por mês numa linha" -m "No iOS 26, a LazyVStack da obra entrava em laço de layout ao arrastar na maior letra numa obra de lista curta, e o teste estava pulado no iOS 26 desde o #99. A obra passa a ser uma List (UICollectionView): uma peça por linha e o cartão de cada mês numa linha, sem recuo, separador nem fundo de linha, com 12 pt entre as linhas. A borda de 16 pt vem da margem da List, e os 16 pt entre a cápsula e o sólido, do espaço antes da Section que vai do sólido para baixo: na List, a célula é o elemento de acessibilidade, e um recuo dentro dela alargaria o anel do VoiceOver. Sozinhos numa linha, o título, a cápsula e a soma dos achados viravam a célula inteira para o VoiceOver (a cápsula com 370 pt de largura, e não 269): uma vista vazia do UIKit no fundo de cada um faz da célula um contêiner, e o anel volta ao quadro da peça. O id da pílula fica na linha inteira, onde o scrollTo da List o acha. O teclado da busca segue com o .interactively de hoje. Na LazyVStack, os arrastos longos o fechavam: o campo saía da janela dela e perdia o foco. Na List, a célula com o foco fica viva, e isso volta com a ponte do UIKit, que conhece a janela da List. O chevron que a List põe nos links fica escondido. Tocar fora das linhas e dos botões não fecha mais a linha aberta: no vão entre as linhas (aceito pelo Giovani em 03/11) e também no título, na cápsula, nos blocos de número, no cabeçalho do mês e nos gastos por tópico. Rolar, tocar outra linha e tocar o A pagar ainda fecham."
```

### Task 7: A rolagem fixa dos testes de tela na List

O laudo, a auditoria e os prints põem a obra numa rolagem dada pelo gancho de Debug `-custta.rolagem`. Nas telas em
ScrollView, ele usa o `.scrollPosition` (`RolagemFixaDoTeste`), que não rola a `List`.
- **O gancho da obra.** Uma vista vazia no fundo da 1ª linha acha a UICollectionView acima dela e põe o deslocamento pedido,
  na mesma régua (o y com o recuo de cima ajustado).
- **O que ele segura.** A linha que ficou no alto da parte à vista, no mesmo ponto, até alguém arrastar. Ele desfaz o que
  mexe na rolagem sozinho: a volta ao topo do iOS 26, a ponte e o `scrollTo`, como o gancho da ScrollView. Não segura o
  número: quando os dados mudam (a busca, o filtro do mês), a `List` volta as linhas de cima da tela à altura estimada, e o
  UIKit compensa a rolagem para a tela não pular. Segurando o número, a cena "busca, achados" do laudo ia parar 300 pt
  abaixo da pílula, com o campo e a soma fora da tela (sonda de 03/11: o UIKit compensava para y 784, e o gancho voltava a
  1118). Segurando a linha, a pílula fica em y 154 antes e depois da busca, no 26.5 e no 27. Preso ao fim do conteúdo: a
  busca que acha pouco encolhe a lista.
- **Em fração da linha, e não em pontos.** A auditoria do Xcode troca a letra em volta de cada auditoria. Com a folga em
  pontos, na letra padrão ela passava do fim da linha e mostrava outras, que a auditoria perdia: 12 achados sem elemento
  na cena da obra do `testOrcamentoNoMaiorTamanho` (run 41730473278). Em fração, a mesma linha fica no alto nas duas
  letras. A fração pode ser negativa: quando o alto cai no vão de 12 pt entre duas linhas, a linha do alto é a de baixo, e o
  ponto fica no vão. Presa a 0, ela segurava o topo da linha de baixo, e a v1 a 400 parava 5,33 pt abaixo da `main` nos
  prints (04/11). Na ponte (9), a conta vira uma função pura com teste, e o gancho passa a usá-la.
- **Os passos.** A `List` só mede as linhas por onde passa, e um salto direto a 2.600 pt caía além do conteúdo estimado ao
  abrir (2.063 pt), no vazio. A rolagem vai em passos de meia tela, um por quadro, sem forçar o layout. Na maior letra, um
  `layoutIfNeeded` mediria de uma vez o cartão de um mês gigante. Cada passo fica preso ao fim do conteúdo que a `List` já
  mediu, e o laço para quando três passos seguidos não andam: as cenas do fim (99999) param no fim, e não ~229 passos
  (~3,7 s) além dele, no vazio. Ao segurar, o gancho já se ajusta uma vez, sem esperar outro evento da rolagem.
- **A parte 3 no fim.** Antes de auditar a v2 e a v3 a 99999, a `testParte3NoMaiorTamanho` confere que a última linha de
  gasto (a mais antiga, `g0`) está à vista. Sem isso, a lista no vazio passaria a auditoria sem elemento nenhum.
- **A folha.** A cena com folha fica sem gancho na obra, como hoje.
- **O argumento.** O argumento de lançamento chega como texto ("400"): o `double(forKey:)` o converte. Um `as? Double` sobre o
  `object(forKey:)` falha calado, e a lista fica no topo.

Só Debug.

**Files:**
- Modify: `app-ios/Custta/Identidade/Componentes.swift`
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Create: `app-ios/Custta/Telas/RolagemFixaDaLista.swift`
- Test (alterar): `app-ios/CusttaUITests/AuditoriaUITests.swift`

**Interfaces:**
- Consumes: o `-custta.rolagem` dos testes de tela; `CUSTTA_FOLHA`.
- Produces: `View.rolagemFixaDaLista()` (Debug); `RolagemFixaDaLista` e `AncoraDaRolagemFixa`.
- Prova a mais: o laudo da busca (`testLeituraDaBuscaEDosAfazeres`) só passa na `List` com o gancho segurando a linha.

- [ ] **Step 1: A conferência do fim na parte 3**

Em `app-ios/CusttaUITests/AuditoriaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -369,12 +369,14 @@ final class AuditoriaUITests: XCTestCase {
     /// achados sem elemento enquanto a auditoria trocava o tamanho da letra (CI, 17/10; no Mac passam).
     /// Com a obra em blocos (etapa 4), mais alta, a v2 a 800 cai no Corrigido e no A pagar (18 Pro). No meio da obra não dá:
     /// a auditoria troca o tamanho da letra, nos menores o conteúdo fica mais curto que a rolagem fixa, a lista salta, e os
-    /// blocos que estavam à vista saem da janela da LazyVStack. A auditoria acusa "Dynamic Type font sizes are unsupported"
+    /// blocos que estavam à vista saíam da janela da LazyVStack de antes. A auditoria acusa "Dynamic Type font sizes are unsupported"
     /// sem elemento, com o texto crescendo a cada passo de letra (sonda de 02/11, iOS 27: a v2 e a v3 a 1600 com os blocos
     /// soltos, e a v3 a 2000 também com o VStack de antes; a v2 a 1850 já dava o mesmo). Por isso a v2 e a
     /// v3 ficam no topo e no fim (99999, que a rolagem fixa leva ao fim em toda letra), onde a janela fica nas mesmas peças.
-    /// As peças do meio (blocos, número mono, cabeçalhos) seguem na maior letra na testVitrineDasPecasNoMaiorTamanho.
-    /// Prova no PR #99.
+    /// As peças do meio (blocos, número mono, cabeçalhos) seguem na maior letra na testVitrineDasPecasNoMaiorTamanho, no alto
+    /// dela e numa tela rolada. Prova no PR #99. Na List (03/11), a rolagem fixa é o gancho da List (RolagemFixaDaLista): anda
+    /// até a rolagem pedida, presa ao fim do conteúdo que ela mede, e segura a linha do alto; no fim (99999), antes de
+    /// auditar, o teste confere que a última linha de gasto (a mais antiga, g0) está à vista, e não o vazio.
     @MainActor func testParte3NoMaiorTamanho() throws {
         var app: XCUIApplication
         for (obra, rolagem) in [("v2", 0), ("v2", 800), ("v2", 99_999), ("v3", 0), ("v3", 99_999)] {
@@ -382,6 +384,11 @@ final class AuditoriaUITests: XCTestCase {
                            argumentos: maiorLetra + parado + ["-custta.rolagem", "\(rolagem)"])
             XCTAssertTrue(app.buttons["editarObra"].waitForExistence(timeout: 10))
             Thread.sleep(forTimeInterval: 1.5)
+            if rolagem == 99_999 {
+                let ultima = app.elemento("gasto-\(obra)g0")
+                XCTAssertTrue(ultima.waitForExistence(timeout: 5) && app.frame.intersects(ultima.frame),
+                              "\(obra) no fim: a última linha de gasto à vista, \(ultima.frame)")
+            }
             try auditar(app, tiposDeAuditoria)
             app.terminate()
         }
```

- [ ] **Step 2: Implementar**

Em `app-ios/Custta/Identidade/Componentes.swift`:

```diff
--- a/app-ios/Custta/Identidade/Componentes.swift
+++ b/app-ios/Custta/Identidade/Componentes.swift
@@ -419,12 +419,12 @@ struct RolagemFixaDoTeste: ViewModifier {
 extension View {
     /// A rolagem fixa do laudo só com o `-custta.rolagem`: sem ele, a lista fica sem o `.scrollPosition`, que muda a rolagem
     /// dela, como em Release. É a das folhas de origem (o A pagar e o detalhe do tópico ficam como sem o gancho nos testes de
-    /// tela); a obra e a tela Orçamento usam a `rolagemFixaSemFolha`.
+    /// tela); a tela Orçamento usa a `rolagemFixaSemFolha`, e a obra, que é uma List, a `rolagemFixaDaLista`.
     @ViewBuilder func rolagemFixaSoComOArgumento() -> some View {
         if UserDefaults.standard.object(forKey: "custta.rolagem") != nil { modifier(RolagemFixaDoTeste()) } else { self }
     }
 
-    /// A rolagem fixa das telas de baixo das folhas (a obra e a tela Orçamento). Na cena que abre uma folha
+    /// A rolagem fixa da tela de baixo das folhas em ScrollView (a tela Orçamento). Na cena que abre uma folha
     /// (`CUSTTA_FOLHA`) com o `-custta.rolagem`, a rolagem é só da folha, e a tela de baixo fica sem o gancho: na VM do
     /// iOS 26, rolar também a obra atrás da folha parava a thread principal de 14 a 21 s, e a cena do fim do A pagar
     /// passava dos 10 s de espera do laudo (sonda do run 40590390423).
```

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -79,6 +79,9 @@ struct ObraView: View {
                     TituloMono(texto: obra.nome)
                         .padding(EdgeInsets(top: -6, leading: 0, bottom: -4, trailing: 0))
                         .background { QuadroProprio() }
+                        #if DEBUG
+                        .rolagemFixaDaLista()
+                        #endif
                     CapsulaDeMetadados {
                         EtiquetaDeFase(fase: obra.fase, grande: true)
                         Text(textoDoInicio(obra, hoje: hoje))
@@ -207,7 +210,6 @@ struct ObraView: View {
         .background { LeitorDaLetra(barra: barra) }
         #if DEBUG
         .task { if !linhaDeTeste.isEmpty { linhaAberta = linhaDeTeste } }
-        .rolagemFixaSemFolha()
         #endif
         .pausaOFundoAoRolar()
         .bordaDeRolagem(abas: true)
```

Criar `app-ios/Custta/Telas/RolagemFixaDaLista.swift`:

```swift
#if DEBUG
import SwiftUI
import UIKit

/* O gancho `-custta.rolagem` dos testes de tela (laudo, auditoria, prints) na obra, que é uma List: o `.scrollPosition` da
   RolagemFixaDoTeste não rola a List (UICollectionView). Uma vista vazia no fundo da 1ª linha acha a rolagem acima dela, põe
   o deslocamento pedido, na régua do gancho da ScrollView (y = contentOffset.y + o recuo de cima ajustado), e o segura até
   alguém arrastar: no iOS 26, a lista às vezes volta sozinha ao topo depois de rolada (RolagemFixaDoTeste). A List só mede
   as linhas por onde passa, e as outras ficam na altura estimada: um salto direto a 2.600 pt caía além do conteúdo estimado
   ao abrir (2.063 pt), no vazio. Por isso a rolagem vai em passos de meia tela, um por quadro. */
struct RolagemFixaDaLista: UIViewRepresentable {
    func makeUIView(context: Context) -> AncoraDaRolagemFixa { AncoraDaRolagemFixa() }
    func updateUIView(_ uiView: AncoraDaRolagemFixa, context: Context) {}
}

final class AncoraDaRolagemFixa: UIView {
    /// Fora da instância: a célula da 1ª linha sai da tela, e a âncora com ela, e o gancho segue segurando.
    private static var observacoes: [NSKeyValueObservation] = []
    /// Uma vez por abertura do app: a obra que volta à tela não rola de novo.
    private static var feito = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // O argumento de lançamento chega como texto ("400"): o double(forKey:) o converte.
        let pedida = UserDefaults.standard.object(forKey: "custta.rolagem") != nil
        let y = UserDefaults.standard.double(forKey: "custta.rolagem")
        guard window != nil, !Self.feito, pedida, y >= 0 else { return }
        var vista: UIView? = superview
        while let atual = vista, !(atual is UICollectionView) { vista = atual.superview }
        guard let lista = vista as? UICollectionView else { return }
        Self.feito = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            // Um passo por quadro: a lista mede as linhas por onde passou no tempo dela, sem layout forçado. Preso ao fim do
            // conteúdo, que cresce conforme ela mede: as cenas do fim (99999) param ali, e não andam no vazio.
            var atual = lista.contentOffset.y
            let alvo = y - lista.adjustedContentInset.top
            var parado = 0
            while atual < alvo && parado < 3 {
                let proximo = min(alvo, Self.fim(lista), atual + lista.bounds.height / 2)
                parado = proximo <= atual ? parado + 1 : 0
                atual = max(atual, proximo)
                lista.setContentOffset(CGPoint(x: 0, y: atual), animated: false)
                try? await Task.sleep(for: .milliseconds(16))
            }
            lista.setContentOffset(CGPoint(x: 0, y: min(alvo, Self.fim(lista))), animated: false)
            Self.segurar(lista, y: y)
        }
    }

    /// Segura a linha que ficou no alto da parte à vista, no mesmo ponto dela, até alguém arrastar. Não segura o número:
    /// quando os dados mudam (a busca, o filtro do mês), a List volta as linhas de cima da tela à altura estimada, e o UIKit
    /// compensa a rolagem para a tela não pular. Segurando o número, a busca de "achados" ia parar 300 pt abaixo da pílula. A
    /// linha do alto também desfaz o que mexe na rolagem sozinho (a ponte, o scrollTo, a volta ao topo do iOS 26), como o
    /// gancho da ScrollView. O ponto é a fração da linha, e não os pontos dentro dela: a auditoria troca a letra, e, na letra
    /// padrão, uma folga em pontos passava do fim da linha e mostrava outras, que a auditoria perdia ("sem elemento").
    private static func segurar(_ lista: UICollectionView, y: Double) {
        let topo = lista.contentOffset.y + lista.adjustedContentInset.top
        let ancora = lista.indexPathsForVisibleItems
            .compactMap { indice in lista.layoutAttributesForItem(at: indice).map { (indice, $0.frame) } }
            .filter { $0.1.maxY > topo }
            .min { $0.1.minY < $1.1.minY }
        let indice = ancora?.0
        // Negativa quando o alto cai no vão de 12 pt entre duas linhas: o ponto fica no vão, como o número da ScrollView.
        // Presa a 0, ela levava o alto ao topo da linha de baixo (a v1 a 400 parava 5,33 pt abaixo da main).
        let fracao = ancora.map { (topo - $0.1.minY) / max(1, $0.1.height) } ?? 0
        observacoes = [
            lista.observe(\.contentOffset, options: [.new]) { rolada, _ in
                MainActor.assumeIsolated { ajustar(rolada, y: y, ancora: indice, fracao: fracao) }
            },
            lista.observe(\.contentSize, options: [.new]) { rolada, _ in
                MainActor.assumeIsolated { ajustar(rolada, y: y, ancora: indice, fracao: fracao) }
            },
        ]
        ajustar(lista, y: y, ancora: indice, fracao: fracao)
    }

    /// O deslocamento do fim do conteúdo, como o medido até agora.
    private static func fim(_ lista: UICollectionView) -> CGFloat {
        max(-lista.adjustedContentInset.top, lista.contentSize.height + lista.adjustedContentInset.bottom - lista.bounds.height)
    }

    private static func ajustar(_ lista: UICollectionView, y: Double, ancora: IndexPath?, fracao: CGFloat) {
        if lista.isTracking || lista.isDragging { observacoes = []; return }
        var topo = CGFloat(y)
        if let indice = ancora, indice.section < lista.numberOfSections,
           indice.item < lista.numberOfItems(inSection: indice.section),
           let quadro = lista.layoutAttributesForItem(at: indice)?.frame {
            topo = quadro.minY + fracao * quadro.height
        }
        // Preso ao fim do conteúdo, como o scrollTo(y:) da ScrollView: a busca que acha pouco encolhe a lista.
        let alvo = min(topo - lista.adjustedContentInset.top, fim(lista))
        if abs(lista.contentOffset.y - alvo) > 0.5 { lista.contentOffset.y = alvo }
    }
}

extension View {
    /// O gancho da rolagem fixa na obra: só com o `-custta.rolagem` e sem folha na cena. Na cena que abre uma folha
    /// (`CUSTTA_FOLHA`), a rolagem é só da folha, como na `rolagemFixaSemFolha` das telas em ScrollView.
    @ViewBuilder func rolagemFixaDaLista() -> some View {
        let pedida = UserDefaults.standard.object(forKey: "custta.rolagem") != nil
        let comFolha = ProcessInfo.processInfo.environment["CUSTTA_FOLHA"] != nil
        if pedida && !comFolha { background { RolagemFixaDaLista().frame(width: 0, height: 0) } } else { self }
    }
}
#endif
```

- [ ] **Step 3: Ver as cenas roladas iguais às de hoje**

Run:
```bash
bash $F/prints-da-obra.sh <udid> <seu dd>/Build/Products/Debug-iphonesimulator/Custta.app <prints>/depois-7 '400|1118|2600|1500|700|1900'
python3 -I $F/compara-prints.py <prints>/antes <prints>/depois-7 --cenas '400|1118|2600|1500|700|1900'
```
Expected (no 26.5, na ponta; a ponte não mexe nas cenas paradas):
```
porTopico-ax5-700-claro.png: canais >16: 0, >48: 0, máx 0, média 0.000
porTopico-ax5-700-escuro.png: canais >16: 0, >48: 0, máx 0, média 0.000
v1-1118-claro.png: canais >16: 0, >48: 0, máx 1, média 0.000
v1-1118-escuro.png: canais >16: 0, >48: 0, máx 8, média 0.000
v1-2600-claro.png: canais >16: 0, >48: 0, máx 0, média 0.000
v1-2600-escuro.png: canais >16: 0, >48: 0, máx 2, média 0.000
v1-400-claro.png: canais >16: 0, >48: 0, máx 3, média 0.000
v1-400-escuro.png: canais >16: 0, >48: 0, máx 3, média 0.015
v1-ax5-1500-claro.png: canais >16: 0, >48: 0, máx 3, média 0.000
v1-ax5-1500-escuro.png: canais >16: 0, >48: 0, máx 3, média 0.019
v1-linha-aberta-1900-claro.png: canais >16: 0, >48: 0, máx 1, média 0.000
v1-linha-aberta-1900-escuro.png: canais >16: 0, >48: 0, máx 1, média 0.000
```

Sem o gancho (no commit anterior), essas cenas ficam no topo da obra.

- [ ] **Step 4: Ver a busca do laudo**

Run:
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaBuscaEDosAfazeres 2>&1 | grep -E "Test Case .*(passed|failed)"
```
Expected (no 26.5, na ponta; com o gancho ligado, quem segura a rolagem é ele, e a ponte não age):
```
Test Case '-[CusttaUITests.LeituraNoVidroUITests testLeituraDaBuscaEDosAfazeres]' passed (496.837 seconds).
```
Antes deste gancho (segurando o número da rolagem), a mesma cena caía com o campo e a soma fora da tela (`campoDaBusca fora
da vista ((inf, inf, 0.0, 0.0)`).

- [ ] **Step 5: A parte 3 na maior letra, firme**

A obra rolada na maior letra caiu na auditoria na v1 (problema conhecido, 5). A parte 3 audita a v2 a 800 e no fim
e a v3 no fim, com este gancho: rode-a 3 vezes no 26.5 e 2 no 27.
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never -test-iterations 3 \
  -only-testing:CusttaUITests/AuditoriaUITests/testParte3NoMaiorTamanho 2>&1 | grep -E "Test Case .*(passed|failed)|error:"
```
Expected: todas `passed`.
```
# 26.5, com as auditorias
Test Case '-[CusttaUITests.AuditoriaUITests testParte3NoMaiorTamanho]' passed (129.379 seconds).
# 26.5, 2 rodadas
Test Case '-[CusttaUITests.AuditoriaUITests testParte3NoMaiorTamanho]' passed (132.791 seconds).
Test Case '-[CusttaUITests.AuditoriaUITests testParte3NoMaiorTamanho]' passed (130.455 seconds).
# 27, com as auditorias
Test Case '-[CusttaUITests.AuditoriaUITests testParte3NoMaiorTamanho]' passed (126.621 seconds).
# 27, 2 rodadas
Test Case '-[CusttaUITests.AuditoriaUITests testParte3NoMaiorTamanho]' passed (128.126 seconds).
Test Case '-[CusttaUITests.AuditoriaUITests testParte3NoMaiorTamanho]' passed (124.995 seconds).
```
Se uma cair, a v2 a 800 sai (fica no topo e no fim, como a v3), e o A pagar já está na `testAPagarNoMaiorTamanho`.

A conferência do fim tem de cair sem o limite. Tire o `Self.fim(lista)` das duas linhas do laço da `RolagemFixaDaLista` (o
`min` do passo e o `setContentOffset` do fim) e o `ajustar(lista, y: y, ancora: indice, fracao: fracao)` que vem depois dos
observadores, compile e rode a parte 3 uma vez; desfaça depois:
```bash
xcodebuild build-for-testing "${XB[@]}" -derivedDataPath <seu dd> 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/AuditoriaUITests/testParte3NoMaiorTamanho 2>&1 | grep -E "error:|Test Case .*failed" | cut -c1-240
```
Expected (a lista anda no vazio, e a cena do fim não chega à última linha):
```
AuditoriaUITests.swift:389: error: -[CusttaUITests.AuditoriaUITests testParte3NoMaiorTamanho] : Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Any` -> `Elements matching predicate '"gasto-v2g0" IN identifiers'`, given input App element pid: 10782
Test Case '-[CusttaUITests.AuditoriaUITests testParte3NoMaiorTamanho]' failed (34.469 seconds).
```

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Identidade/Componentes.swift app-ios/Custta/Telas/ObraView.swift app-ios/Custta/Telas/RolagemFixaDaLista.swift app-ios/CusttaUITests/AuditoriaUITests.swift
git commit -m "test: rolagem fixa dos testes de tela na List da obra" -m "O gancho -custta.rolagem das telas em ScrollView usa o scrollPosition, que não rola a List. Na obra, uma vista vazia no fundo da 1ª linha acha a UICollectionView e põe o deslocamento pedido na mesma régua (o y com o recuo de cima). A List só mede as linhas por onde passa, e um salto direto caía no vazio: a rolagem vai em passos de meia tela, presa ao fim do conteúdo que a List já mediu, e as cenas do fim (99999) param no fim, e não no vazio depois dele. Depois, o gancho segura a linha que ficou no alto (o ponto dela, em fração da altura), e não o número, até alguém arrastar. Quando os dados mudam (a busca), a List volta as linhas de cima à altura estimada e o UIKit compensa a rolagem; segurando o número, a cena da busca ia parar 300 pt abaixo da pílula. Em fração, e não em pontos: a auditoria troca a letra, e uma folga em pontos passava do fim da linha na letra padrão, mostrando outras linhas. Antes de auditar o fim, a parte 3 confere que a última linha de gasto está à vista. A cena com folha segue sem gancho na obra. Só em Debug."
```

### Task 8: O arrasto da obra de lista curta volta a rodar no iOS 26

O teste da busca na obra de lista curta, na maior letra (a "o4"), estava pulado no iOS 26 desde o #99 (`060fc88`): arrastar
travava a LazyVStack na VM lenta da CI. No Mac, nem desacelerado, ele trava. Com a `List`, o pulo sai, e o teste volta a
valer nos dois sistemas.

**Files:**
- Test (alterar): `app-ios/CusttaUITests/BuscaUITests.swift`

**Interfaces:**
- Consumes: nada novo.
- Produces: nada novo.

- [ ] **Step 1: Tirar o pulo**

Em `app-ios/CusttaUITests/BuscaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/BuscaUITests.swift
+++ b/app-ios/CusttaUITests/BuscaUITests.swift
@@ -220,11 +220,7 @@ final class BuscaUITests: XCTestCase {
 
     /// A obra que fica sem gasto segue com a lupa e o mês enquanto há filtro ou busca: com o mês escolhido, e depois, sem o
     /// mês, com a busca aberta, em que a lupa da maior letra é o × que fecha. Fechada a busca, só a pílula.
-    func testObraQueFicaSemGastoComMesOuBuscaAbertaFicaComOsBotoes() throws {
-        // Só no iOS 26: o simulador roda o sistema que o teste vê, e no 27 o método segue valendo.
-        try XCTSkipIf(ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 26,
-                      "problema conhecido: no iOS 26, arrastar na maior letra na obra de lista curta trava a LazyVStack "
-                      + "(só na VM lenta da CI, 3 em 4); a estrutura da obra será trocada antes da App Store; ver #99")
+    func testObraQueFicaSemGastoComMesOuBuscaAbertaFicaComOsBotoes() {
         let app = abrirObra("o4", dados: "exemplo",
                             argumentos: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
         let lupa = app.buttons["buscar"], mes = app.buttons["filtrarPorMes"]
```

- [ ] **Step 2: Ver falhar e ver passar (CI do iOS 26)**

O "ver falhar" é só da VM da CI: no Mac, a estrutura de hoje passa até com o simulador a ~3× mais lento (freio, 3 de 3). Na
CI, no mesmo run (41530054757, 02/11), o mesmo teste deu:
- estrutura de hoje: falhou 2 de 3, com a thread principal presa em `LazyStack.measureEstimates`/`placeSubviews`;
- `List`: passou 3 de 3, em 131 a 142 s.

Depois desta tarefa, push e PR em rascunho (Como entregar). A o4 passa a vigiar todo run.

Expected (1º run do rascunho): o `app-etapa3-c` com `testObraQueFicaSemGastoComMesOuBuscaAbertaFicaComOsBotoes` `passed`,
sem `skipped`. Medido nos ramos `proto/` de 03/11:
```
Test Case '-[CusttaUITests.BuscaUITests testObraQueFicaSemGastoComMesOuBuscaAbertaFicaComOsBotoes]' passed (124.821 seconds).
```
(run 41730473278) e, na sonda só do job, 10 de 10, de 136 a 203 s (run 41706961537).

- [ ] **Step 3: As suítes da obra na List, antes do push**

O 1º push leva a `List` à CI. Antes dele, rode no 26.5 as seis suítes da obra, os Afazeres, a FolhaDaObra e os quatro laudos
que leem a obra (também os dois que a 3 adaptou à `List`), para o rascunho dizer o que cai e por quê:
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/ObraUITests -only-testing:CusttaUITests/GastoUITests \
  -only-testing:CusttaUITests/BuscaUITests -only-testing:CusttaUITests/FasesUITests \
  -only-testing:CusttaUITests/FolhasDeOrigemUITests -only-testing:CusttaUITests/EstadosUITests \
  -only-testing:CusttaUITests/AfazeresUITests -only-testing:CusttaUITests/FolhaDaObraUITests \
  -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaObra \
  -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaBuscaEDosAfazeres \
  -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaObraEmBlocos \
  -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDoAlertaDeNaoSalvou 2>&1 \
  | grep -E "Test Case .*failed|Executed .* tests"
```
Expected (no 26.5; só caem os que dependem da ponte, que é a 9):
```
Executed 15 tests, with 0 failures (0 unexpected) in 242.115 (242.124) seconds
Test Case '-[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao]' failed (44.426 seconds).
Executed 11 tests, with 4 failures (0 unexpected) in 369.457 (369.462) seconds
Executed 13 tests, with 0 failures (0 unexpected) in 205.755 (205.763) seconds
Executed 9 tests, with 0 failures (0 unexpected) in 130.490 (130.494) seconds
Executed 15 tests, with 0 failures (0 unexpected) in 248.667 (248.674) seconds
Executed 24 tests, with 0 failures (0 unexpected) in 619.713 (619.725) seconds
Test Case '-[CusttaUITests.GastoUITests testNaMaiorLetraAListaRolaAteOAVencer]' failed (11.573 seconds).
Executed 24 tests, with 1 failure (0 unexpected) in 484.877 (484.886) seconds
Executed 4 tests, with 0 failures (0 unexpected) in 801.801 (801.802) seconds
Executed 13 tests, with 0 failures (0 unexpected) in 179.951 (179.957) seconds
Executed 128 tests, with 5 failures (0 unexpected) in 3282.826 (3282.893) seconds
Executed 128 tests, with 5 failures (0 unexpected) in 3282.826 (3282.897) seconds
```
Escreva essas quedas no rascunho.

- [ ] **Step 4: As ausências mordem na List**

As duas mutações da 3, de novo, agora na `List`: lá, a LazyVStack criava as peças a ~1.700 pt, e a ausência
morderia mesmo sem mudar de lugar. Cada uma tem de cair; compile antes de rodar e desfaça depois.
- `acoesDaFase(.construcao)` devolvendo também `.registrarVenda` (no `ObraEFases.swift` do núcleo);
- o bloco dos gastos por tópico sem o `if !obra.gastos.isEmpty` (na `ObraView`, `if true {`).
```bash
xcodebuild build-for-testing "${XB[@]}" -derivedDataPath <seu dd> 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/FasesUITests/testMarcarComoProntaEVoltarPraConstrucaoSemPergunta 2>&1 | grep -E "error:" | cut -c1-240
# desfaça a 1ª, faça a 2ª e compile de novo
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/ObraUITests/testSemGastosSemGastosPorTopico 2>&1 | grep -E "error:" | cut -c1-240
```

Expected:
```
# acoesDaFase(.construcao) com .registrarVenda
FasesUITests.swift:18: error: -[CusttaUITests.FasesUITests testMarcarComoProntaEVoltarPraConstrucaoSemPergunta] : XCTAssertFalse failed - a construção não se vende
# o bloco dos gastos por tópico sem o if
ObraUITests.swift:201: error: -[CusttaUITests.ObraUITests testSemGastosSemGastosPorTopico] : XCTAssertFalse failed
```

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaUITests/BuscaUITests.swift
git commit -m "test: arrasto da obra de lista curta volta a rodar no iOS 26" -m "O teste da busca na obra de lista curta, na maior letra, estava pulado no iOS 26 desde o #99: arrastar travava a LazyVStack na VM lenta da CI (3 em 4). Com a obra numa List, o mesmo arrasto passou 3 de 3 na CI do protótipo (run 41530054757), e o pulo sai: o teste volta a valer nos dois sistemas e passa a vigiar a troca em todo run."
```

### Task 9: A obra rola até o gasto salvo e até a pílula pela ponte do UIKit

Depois de salvar (um gasto novo ou uma edição), a obra rola até a linha do gasto e a acende por 2 s (spec da etapa 2: rolar
e acender). A lupa leva a pílula "Lançamentos" ao topo antes de pôr o teclado.
- **O que falha na `List`.** O `scrollTo` dela só acha a linha, que é o cartão do mês inteiro, trata a âncora fracionária
  como o centro e não rola uma linha que já está na tela.
  - Na maior letra, a 1ª parcela de uma compra no cartão parava em y 2230, fora da tela; com a âncora calculada, em y −3062.
  - A lupa deixava a pílula onde a lista estava (no teste da busca, em y 641 no 26.5 e 396 na CI; ele quer menos de 200).
- **A ponte.** Uma marca, uma vista vazia (`MarcaDaLinha`), por chave: em cada linha acesa (o id do gasto) e na pílula
  (`"lancamentos"`). A ponte sobe da marca até a UICollectionView da `List` (e não até a 1ª rolagem que achar), converte o
  quadro dela para o conteúdo e anda até a fração pedida da parte à vista (`deslocamento(levando:a:…)`, função pura com
  teste): o meio, para o gasto; o topo, para a pílula. A vista da marca guarda a própria chave e sai da ponte quando a linha
  sai (`dismantleUIView`): se o SwiftUI a reaproveitar noutra linha, a chave velha não leva a rolagem para a linha errada.
  - Com a linha do gasto já na tela, como na edição, a ponte vai direto, sem passar pelo topo do cartão (o salto que o
    conselho descartou). A tentativa direta (`rolarSeAVista`) procura a marca por 3 quadros; achada, espera a lista parar
    de se medir (até ~1 s) e rola, com a última medida se ela não assentar. Assim, a célula ainda se medindo (a etiqueta
    "novo" quebrando a linha) não manda a obra pelo cartão, e o caminho direto não depende de a lista assentar em três quadros numa VM
    lenta
    (2ª revisão às cegas). Em Debug, ela avisa o caminho que tomou (`avisarCaminho(direto:)`, um `notify_post`), e o teste da
    edição confere "direto": se o direto falhasse, a reserva também terminaria com a linha à vista, e o teste não veria.
  - Senão, o cartão vai ao topo e a ponte tenta a cada quadro até a altura do conteúdo ser a mesma em dois quadros
    seguidos, com teto de ~1 s.
  - Com o gasto num A vencer fechado, a linha ainda não existe: o cartão vai ao topo e o A vencer abre 80 ms depois, no
    tempo de hoje, sem esperar a tentativa direta. Esperando, na VM lenta da CI, o teste do cartão em 10x lia o A vencer
    ainda fechado (run 41706879156).
  - Ela não força o layout: um cartão gigante se mediria de novo, de uma vez, na thread principal.
  - Com Reduzir movimento, sem animação. O foco do VoiceOver vem 450 ms depois, com a rolagem assentada.
- **A lupa.** A ponte leva a pílula ao topo quando a lista assenta (o campo que entra faz a `List` medir de novo as linhas
  de cima), e o foco no campo vem logo depois, com o teclado. Num aparelho rápido, isso leva um ou dois quadros. Se a lista
  não assenta em 30 quadros, a ponte rola com a última medida (`insistir`): hoje, o `scrollTo` sempre rolava, e sem isso a
  pílula ficaria onde estava. Com a ponte, a pílula para em y 129 no 18 Pro, o campo em 189 e a soma dos achados em 234, como
  na ScrollView de hoje (medido nas duas: a marca cobre os 6 pt de cima da pílula, e a ponte leva o topo dela ao alto).
  O `.id("lancamentos")` e o leitor da lupa saem: ninguém mais rola até a pílula pelo `scrollTo`.
- **O filtro da busca.** Cada letra muda os dados, e a `List` volta as linhas de cima da tela à altura estimada. Na VM da CI,
  nem sempre o UIKit compensava: a pílula subia 160,33 pt (o bloco dos gastos por tópico, estimado menor que os 212 pt
  dele), o campo ficava sob a barra, e o × não limpava a busca (`BuscaUITests` linha 81 nos dois runs completos; sondas
  41738960913, 1 de 4, e 41743119168, 2 de 6, já com a espera da lupa). A ponte segura a linha do alto quando o filtro muda,
  como quando a letra muda: para digitar, o campo está na tela, e a linha do alto é a pílula ou um bloco acima dela, que o
  filtro não muda. Na sonda com o conserto (41749639956, 6 rodadas na VM), a pílula ficou em y 129 nas 6. O × limpou em 4.
  Nas outras 2 houve um toque perdido da VM (memória `toque-perdido-na-vm-lenta-do-ios-26`): na 1ª rodada, a mais lenta
  (242 s), o × tocado não fez nada; na 2ª, o texto digitado não entrou no campo. Essa sonda é da pilha anterior, com o
  teclado de lá (`.immediately` e `.ignoresSafeArea(.keyboard)`). Na ponta desta, a mesma sonda rodou 6 vezes na VM (Como
  entregar): nas 6 rodadas, a pílula ficou em y 129 antes e depois de abrir o A vencer, e o × limpou a busca (run 41873797898, `proto/obra-em-list-sonda-x17`, 04/11; rodadas de 173 a 442 s)
  - A 1ª letra só chega com o teclado em cima, e o teclado só vem depois de a ponte começar a rolar (a animação é mais curta
    que a subida dele): a ponte não segura uma linha do meio da animação.
  - Outra mudança de dados com a busca aberta (outro aparelho apaga um gasto, a linha filtrada apagada) não passa pela
    ponte. A causa é a mesma, e só a VM mostrou o salto. Fica no checklist do aparelho, e não tem conserto aqui.
- **A letra que muda.** Com a obra rolada, quando o Tamanho do Texto muda (pela Central de Controle; a auditoria do Xcode
  faz o mesmo), a `List` guarda o número da rolagem e, na ida e volta, a tela parava num mês lá embaixo. A `main` volta ao
  mesmo lugar. A ponte conhece a `List` pela marca da 1ª linha (`MarcaDaLista`, no título), guarda a linha do alto e a
  fração dela a cada rolagem (`linhaDoAlto`, função pura com teste, que o gancho dos testes também passa a usar: negativa
  quando o alto cai no vão de 12 pt entre duas linhas, e aí o ponto fica no vão; presa a 0, a lista pulava até 12 pt) e,
  quando a letra muda, a segura a cada quadro até a lista parar de se medir: a mesma altura
  do conteúdo por 10 quadros (o critério do `rolarQuandoAssentar`, a lista parar de se medir, com mais quadros), com teto
  de 3 s. Um tempo fixo (1,5 s) seria a moeda na VM que o conselho descartou para o gasto salvo. Um arrasto, ou a lista
  deslizando depois dele, solta (`isTracking`, `isDragging`, `isDecelerating`): sem o último, a ponte punha a rolagem contra
  a desaceleração a cada quadro (2ª revisão às cegas). O arrasto não tem teste, porque no Mac a lista assenta antes de o
  arrasto sintetizado começar. Teste novo:
  `ObraUITests.testNaMaiorLetraIdaEVoltaDaLetraDeixaAObraNoLugar`, que troca a letra pelo gancho de Debug
  `TrocaDeLetraDoTeste` (o teste avisa por `notify_post`, e o app troca o traço da cena). Ele confere que a peça encolhe na
  letra padrão: se o aviso não chegasse ao app, a peça ficaria parada, e o teste passaria vazio. Com o gancho dos testes
  (`-custta.rolagem`), quem segura é ele.
- **O teclado da busca.** Fica o `.scrollDismissesKeyboard(.interactively)` de hoje, e o campo fecha o teclado quando o dedo
  o rola meia tela além da tela. Hoje, o arrasto curto deixa o teclado aberto, e os longos o fecham porque o campo sai da
  janela da LazyVStack, meia tela além da borda, e perde o foco. Na `List`, a célula com o foco fica viva:
  - com o `.interactively` sozinho, o teclado seguia aberto depois de 12 arrastos longos (sonda de 03/11: teclado em y 583);
  - com o `.immediately` (a 1ª versão do plano), fechava já no arrasto curto (1ª revisão às cegas);
  - com o `onScrollVisibilityChange` do campo (a 2ª versão), não fechava nunca: ele não dispara na `List`, e o campo foi a
    y −2.846 sem um evento (sonda de 04/11).

  O quadro do campo, sim, anda a cada quadro. Um `onGeometryChange` o mede (a medida é `@Sendable` e só lê o quadro; a
  conta fica na ação, que é da thread principal, como a ponte; na 1ª versão, a conta dentro da medida dava dois avisos novos
  de isolamento, 3ª revisão às cegas) contra a janela da `List`, que a ponte dá
  (`janela`: a rolagem inteira, que passa por baixo da barra e do teclado), e o teclado fecha quando ele passa de meia tela
  além da borda, em cima ou embaixo (`ObraView.campoForaDaJanela`, função pura com teste). Só com o dedo (a fase da
  rolagem): quando os dados mudam (o ×, cada letra), a `List` refaz as linhas, e o campo pula sem ninguém rolar (178 → 362
  → 178 pt em 30 ms numa letra). Se o campo já estava além da janela quando o dedo parou, o arrasto seguinte fecha.
  Medido em arrastos de ~77 pt sem impulso, `main` × ponta: na `main` (26.5), o teclado fecha no 9º arrasto para cima e no 15º para baixo; na ponta, no 10º e no 15º, no 26.5 e no 27. O arrasto curto com impulso não fecha nas duas (na `main`, a pílula vai a y −160,67; na ponta, sai da tela), e os 12 arrastos longos fecham nas duas (sondas `SondaTecladoUITests`, `SondaRevisaoUITests.testArrastoCurtoComTeclado` e `SondaLupaUITests.testFimDaListaComTeclado`, de 04/11, em `prumo-plano-obra-list/ferramentas/`).
  Fechar ao sair da tela (folga 0) fecharia no 4º arrasto para cima, no 10º para baixo e no arrasto curto, antes de hoje.
  Digitar logo depois de um arrasto curto, com a lista ainda deslizando, não se prova aqui: o XCUITest espera a lista parar
  antes de digitar. Vai para a sessão no iPhone e para o checklist do aparelho.
- **RISCO, no corpo do PR.** A ponte depende de a `List` ser uma UICollectionView com as vistas da linha dentro dela, que é
  detalhe do SwiftUI. Se um iOS novo mudar isso, ela não rola: a lista fica no topo do cartão, a pílula fica onde está, a
  letra que muda tira a obra do lugar, o teclado da busca não fecha mais nos arrastos longos, e caem dois testes da maior
  letra do Gasto (o A vencer e o g024), o da busca, o da letra e o do teclado.
  `-custta.semPonte` (Debug) desliga a ponte para provar que eles a vigiam.
- **Teste novo.** Editar "Louças e metais" (g024, um dos últimos de um mês longo) na maior letra, conferir a linha inteira
  entre a barra e a cápsula de abas e o caminho "direto". Os testes que a ponte agora rola ficam mais firmes: no Gasto, a
  linha e a parcela entre a barra e a cápsula de abas (e não só dentro da janela, que aceitava a linha sob a barra); na
  busca, a pílula e o campo abaixo da barra (o defeito de 160 pt só caía pela linha do ×, por consequência). Mais três: o
  teclado (`BuscaUITests.testArrastoCurtoDeixaOTecladoEOsLongosOFecham`), a régua dele em teste de unidade
  (`campoForaDaJanelaSoAMeiaTelaDaBorda`), o alto no vão quando a letra muda, também em teste de unidade
  (`altoNoVaoFicaNoVaoQuandoALetraMuda`), e duas guardas do anel que dependem de uma vista do UIKit no fundo da linha (2ª
  revisão às cegas): a pílula sozinha da obra sem gastos, no `testObraSemGastoSoAPilula`, e a cápsula na maior letra, no
  teste da ida e volta da letra. A varredura dos quadros de acessibilidade na ponta, contra a `main`: na ponta de 04/11 (26.5), os 107 identificadores em comum com a `main`, em 7 cenas (letra padrão e maior, obra em construção e pronta, com e sem a pílula à vista, e a busca), têm o mesmo quadro; só na busca as listas diferem, porque a `main` ainda expõe as peças do alto, fora da tela, e a `List` só as da tela (`SondaQuadrosUITests`).

**Files:**
- Modify: `app-ios/Custta/CusttaApp.swift`
- Create: `app-ios/Custta/Falsos/TrocaDeLetraDoTeste.swift`
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Create: `app-ios/Custta/Telas/PonteDaRolagem.swift`
- Modify: `app-ios/Custta/Telas/RolagemFixaDaLista.swift`
- Test (novo): `app-ios/CusttaTests/PonteDaRolagemTests.swift`
- Test (alterar): `app-ios/CusttaUITests/BuscaUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/GastoUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/ObraUITests.swift`

**Interfaces:**
- Consumes: `Folhas.Destaque`, `AcoesDaLista`, `LinhaDaLista`, o `ScrollViewProxy` da obra, `aVencerAbertoAgora`.
- Produces: `PonteDaRolagem` (`marcar(_:chave:)`, `esquecer(_:)`,
  `rolarQuandoAssentar(ate:a:quadros:animado:insistir:) async -> Bool`, `rolarSeAVista(ate:procurar:quadros:animado:)
  async -> Bool`, `conhecer(_:)`, `segurarOAlto()`, `janela: CGRect?`,
  `avisarCaminho(direto:)` em Debug), `deslocamento(levando:a:recuoDeCima:recuoDeBaixo:altura:conteudo:) -> CGFloat`,
  `MarcaDaLinha(ponte:chave:)` com `MarcaDaLinha.Vista`, `MarcaDaLista(ponte:)`; `linhaDoAlto(_:em:) -> (indice: IndexPath, fracao: CGFloat)?`;
  `ObraView.campoForaDaJanela(_:janela:) ->
  Bool`; `AcoesDaLista.ponte: PonteDaRolagem?` (nil
  nas folhas); `TrocaDeLetraDoTeste.vigiar()` e `CUSTTA_TROCA_LETRA=aviso` (Debug); os avisos
  `br.com.custta.falso.ponte.direto` e `.cartao` (Debug).

- [ ] **Step 1: Escrever os testes**

A conta da ponte, com os números do iPhone 17 Pro (janela de 874 pt, recuos de 116 e 34): o gasto no meio, perto do começo,
perto do fim, num conteúdo mais curto que a janela, e a pílula no topo; a régua do teclado, meia tela além da janela; e o
alto no vão entre duas linhas, que segue no vão quando a letra muda. Na
maior letra, o gasto editado no fim do mês e a ida e volta da letra com a obra rolada (com a cápsula mais estreita que a
célula); na busca, o teclado (o arrasto curto o deixa, os longos o fecham) e o anel da pílula sozinha.

Criar `app-ios/CusttaTests/PonteDaRolagemTests.swift`:

```swift
import Testing
import CoreGraphics
import Foundation
@testable import Custta

/* A conta da ponte (PonteDaRolagem.swift): o meio do quadro do gasto vai ao meio da parte à vista, e o topo da pílula, ao
   topo dela, entre o recuo de cima (a barra) e o de baixo, preso ao começo e ao fim do conteúdo. Os números são os do iPhone
   17 Pro: janela de 874 pt e recuos de 116 e 34, o que deixa 724 pt à vista. */
struct PonteDaRolagemTests {
    @Test func gastoVaiAoMeioDaParteAVista() {
        // O meio do gasto (4.778 + 165 = 4.943) fica 116 + 362 pt abaixo do topo da janela.
        #expect(deslocamento(levando: CGRect(x: 16, y: 4778, width: 370, height: 330), a: 0.5, recuoDeCima: 116,
                                     recuoDeBaixo: 34, altura: 874, conteudo: 20000) == 4465)
    }

    @Test func gastoPertoDoTopoParaNoComeco() {
        #expect(deslocamento(levando: CGRect(x: 16, y: 40, width: 370, height: 60), a: 0.5, recuoDeCima: 116,
                                     recuoDeBaixo: 34, altura: 874, conteudo: 20000) == -116)
    }

    @Test func gastoPertoDoFimParaNoFim() {
        // O fim do conteúdo: 3.000 + 34 − 874 = 2.160.
        #expect(deslocamento(levando: CGRect(x: 16, y: 2900, width: 370, height: 60), a: 0.5, recuoDeCima: 116,
                                     recuoDeBaixo: 34, altura: 874, conteudo: 3000) == 2160)
    }

    @Test func conteudoMaisCurtoQueAJanelaFicaNoComeco() {
        #expect(deslocamento(levando: CGRect(x: 16, y: 300, width: 370, height: 60), a: 0.5, recuoDeCima: 116,
                                     recuoDeBaixo: 34, altura: 874, conteudo: 500) == -116)
    }

    /// O teclado da busca (ObraView.campoForaDaJanela): o campo fecha o teclado só a meia tela além da borda, onde a
    /// LazyVStack de antes o desmontava; na janela de 874 pt, 437 acima do topo ou abaixo do fim.
    @Test func campoForaDaJanelaSoAMeiaTelaDaBorda() {
        let janela = CGRect(x: 0, y: 0, width: 402, height: 874)
        func campo(_ y: CGFloat) -> CGRect { CGRect(x: 56, y: y, width: 272, height: 22) }
        #expect(!ObraView.campoForaDaJanela(campo(189), janela: janela))
        #expect(!ObraView.campoForaDaJanela(campo(-459), janela: janela))   // o fim do campo em −437: na borda
        #expect(ObraView.campoForaDaJanela(campo(-460), janela: janela))
        #expect(!ObraView.campoForaDaJanela(campo(1311), janela: janela))   // o topo em 874 + 437
        #expect(ObraView.campoForaDaJanela(campo(1312), janela: janela))
    }

    /// O alto no vão de 12 pt entre duas linhas, como na v1 a 400 na letra padrão (a linha de cima termina em 393,33 e a
    /// de baixo começa em 405,33): a linha do alto é a de baixo, e a fração negativa devolve o alto ao vão. A letra que muda
    /// escala as linhas, e o alto segue no vão acima da linha, sem pular para o topo dela.
    @Test func altoNoVaoFicaNoVaoQuandoALetraMuda() {
        let cima = IndexPath(indexes: [1, 1]), baixo = IndexPath(indexes: [1, 2])
        let alto = linhaDoAlto(400, em: [(cima, CGRect(x: 16, y: 289, width: 370, height: 104.33)),
                                         (baixo, CGRect(x: 16, y: 405.33, width: 370, height: 104.33))])
        #expect(alto?.indice == baixo)
        let fracao = alto?.fracao ?? 0
        let volta = CGFloat(405.33) + fracao * CGFloat(104.33)
        #expect(abs(volta - 400) < 0.01)
        // Na maior letra, a linha de baixo começa em 520 e tem 200 pt, e a de cima termina em 508: o alto fica no vão.
        let naMaiorLetra = CGFloat(520) + fracao * CGFloat(200)
        #expect(naMaiorLetra > 508 && naMaiorLetra < 520)
    }

    @Test func pilulaVaiAoTopoDaParteAVista() {
        // O topo da pílula (1.250) fica logo abaixo da barra: 1.250 − 116.
        #expect(deslocamento(levando: CGRect(x: 16, y: 1250, width: 370, height: 44), a: 0, recuoDeCima: 116,
                             recuoDeBaixo: 34, altura: 874, conteudo: 20000) == 1134)
    }
}
```

Em `app-ios/CusttaUITests/BuscaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/BuscaUITests.swift
+++ b/app-ios/CusttaUITests/BuscaUITests.swift
@@ -68,6 +68,9 @@ final class BuscaUITests: XCTestCase {
         buscar(app, "ceramica")
         XCTAssertEqual(app.textFields["campoDaBusca"].label, "Buscar gasto ou tópico", "o rótulo do campo para o VoiceOver")
         XCTAssertLessThan(app.elemento("lancamentos").frame.minY, 200, "a lista rola até a pílula, com o campo embaixo")
+        let barra = app.navigationBars.firstMatch.frame
+        XCTAssertGreaterThanOrEqual(app.elemento("lancamentos").frame.minY, barra.maxY - 1, "a pílula abaixo da barra, e não sob ela")
+        XCTAssertGreaterThanOrEqual(app.textFields["campoDaBusca"].frame.minY, barra.maxY, "o campo abaixo da barra")
         XCTAssertEqual(pilula(app), "Lançamentos, 12 de 46")
         XCTAssertEqual(app.elemento("somaDosAchados").label, "Soma dos achados: R$\u{a0}95.120,30")
         XCTAssertLessThan(app.elemento("somaDosAchados").frame.width, app.frame.width - 32 - 40,
@@ -216,6 +219,28 @@ final class BuscaUITests: XCTestCase {
         XCTAssertEqual(pilula(app), "Lançamentos")
         XCTAssertFalse(app.buttons["buscar"].exists)
         XCTAssertFalse(app.buttons["filtrarPorMes"].exists)
+        // O anel do VoiceOver abraça a pílula, e não a célula da List (370 pt): sozinha na linha, ela depende da marca da
+        // ponte no fundo, uma vista do UIKit (ver o QuadroProprio, na ObraView).
+        let quadro = app.elemento("lancamentos").frame
+        XCTAssertLessThan(quadro.width, app.windows.firstMatch.frame.width - 32 - 40, "o anel da pílula: \(quadro)")
+    }
+
+    /// O teclado da busca fica como na LazyVStack de antes: o arrasto curto o deixa aberto, mesmo com o impulso levando o
+    /// campo para fora da tela, e os arrastos longos o fecham quando o campo passa de meia tela além dela. Na List, a célula
+    /// com o foco fica viva, e sem a régua do campo contra a janela (ObraView.campoForaDaJanela) o teclado não fechava
+    /// nunca: 12 arrastos, e ele seguia em y 583 (sonda de 03/11).
+    func testArrastoCurtoDeixaOTecladoEOsLongosOFecham() {
+        let app = abrirObra()
+        buscar(app, "o")
+        let teclado = app.keyboards.firstMatch, meio = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
+        meio.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)))
+        XCTAssertTrue(teclado.exists, "o arrasto curto fechou o teclado")
+        for _ in 0..<12 {
+            guard teclado.exists else { break }
+            meio.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)),
+                       withVelocity: .slow, thenHoldForDuration: 0.3)
+        }
+        XCTAssertTrue(teclado.waitForNonExistence(timeout: 3), "os arrastos longos não fecharam o teclado")
     }
 
     /// A obra que fica sem gasto segue com a lupa e o mês enquanto há filtro ou busca: com o mês escolhido, e depois, sem o
```

Em `app-ios/CusttaUITests/GastoUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/GastoUITests.swift
+++ b/app-ios/CusttaUITests/GastoUITests.swift
@@ -50,20 +50,22 @@ final class GastoUITests: XCTestCase {
         XCTAssertTrue(app.elemento("lancamentos").label.contains("47"), app.elemento("lancamentos").label)
     }
 
-    /// Na maior letra, depois de salvar, a lista rola até o gasto e ele acende à vista: o cartão do mês fica fora da parte
-    /// que a LazyVStack já criou, e a rolagem vai pela identidade do ForEach (um .id no cartão só existe depois de criado).
+    /// Na maior letra, depois de salvar, a lista rola até o gasto e ele acende à vista, entre a barra e a cápsula de abas: o
+    /// cartão do mês é uma linha da List, e a ponte do UIKit leva o gasto ao meio da parte à vista.
     func testNaMaiorLetraAListaRolaAteOGastoSalvo() {
         let app = abrirObra(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
         lancarValor(app, "777777")
         app.buttons["salvarGasto"].tap()
         XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5), "a folha desce")
         let linha = app.descendants(matching: .any).matching(NSPredicate(format: "value == %@", "R$\u{a0}7.777,77")).firstMatch
-        XCTAssertTrue(linha.waitForExistence(timeout: 5), "a lista rolou até o cartão do mês, que a LazyVStack cria")
-        XCTAssertTrue(app.frame.contains(linha.frame), "e a linha acesa está inteira à vista: \(linha.frame)")
+        XCTAssertTrue(linha.waitForExistence(timeout: 5), "a lista rolou até o cartão do mês")
+        let barra = app.navigationBars.firstMatch.frame, abas = app.buttons["aba-obras"].frame
+        XCTAssertGreaterThanOrEqual(linha.frame.minY, barra.maxY, "e a linha acesa está inteira à vista, abaixo da barra: \(linha.frame)")
+        XCTAssertLessThanOrEqual(linha.frame.maxY, abas.minY, "e acima da cápsula de abas: \(linha.frame)")
     }
 
-    /// Na maior letra, a compra no cartão vai para o "A vencer", que também fica fora da parte que a LazyVStack já criou:
-    /// a lista rola até ele, que abre, e a 1ª parcela acende à vista (o primeiro vencimento é daqui a um mês).
+    /// Na maior letra, a compra no cartão vai para o "A vencer": a lista rola até ele, que abre, e a 1ª parcela acende à vista,
+    /// entre a barra e a cápsula de abas (o primeiro vencimento é daqui a um mês).
     func testNaMaiorLetraAListaRolaAteOAVencer() {
         let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: [
             "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-custta.folha", "cartao"])
@@ -71,11 +73,40 @@ final class GastoUITests: XCTestCase {
         app.buttons["salvarGasto"].tap()
         XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5), "a folha desce")
         let aVencer = app.elemento("aVencer")
-        XCTAssertTrue(aVencer.waitForExistence(timeout: 5), "a lista rolou até o A vencer, que a LazyVStack cria")
+        XCTAssertTrue(aVencer.waitForExistence(timeout: 5), "a lista rolou até o A vencer")
         XCTAssertEqual(aVencer.value as? String, "aberto")
         let parcela = app.descendants(matching: .any).matching(NSPredicate(format: "value == %@", "R$\u{a0}498,00")).firstMatch
         XCTAssertTrue(parcela.waitForExistence(timeout: 5))
-        XCTAssertTrue(app.frame.contains(parcela.frame), "e a 1ª parcela está inteira à vista: \(parcela.frame)")
+        let barra = app.navigationBars.firstMatch.frame, abas = app.buttons["aba-obras"].frame
+        XCTAssertGreaterThanOrEqual(parcela.frame.minY, barra.maxY, "e a 1ª parcela está inteira à vista, abaixo da barra: \(parcela.frame)")
+        XCTAssertLessThanOrEqual(parcela.frame.maxY, abas.minY, "e acima da cápsula de abas: \(parcela.frame)")
+    }
+
+    /// Na maior letra, editar um gasto do fim de um mês longo e salvar: a linha fica inteira à vista, entre a barra e a cápsula
+    /// de abas. O cartão do mês passa da tela, e o scrollTo da List só acha o cartão: quem leva a rolagem até a linha é a ponte
+    /// do UIKit (PonteDaRolagem.swift), e este teste cai quando ela não acha a linha. Com a linha à vista, a ponte vai direto
+    /// ao gasto, sem passar pelo topo do cartão (o salto que o conselho de 03/11 descartou): o aviso do caminho diz "direto".
+    func testNaMaiorLetraEditarUmGastoDoFimDoMesDeixaALinhaAVista() {
+        let app = abrirObra(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
+        let linha = app.elemento("gasto-g024")
+        app.rolarAte(linha, tentativas: 30)
+        linha.tap()
+        XCTAssertTrue(app.elemento("linhaValor").waitForExistence(timeout: 5))
+        app.elemento("linhaValor").tap()
+        XCTAssertTrue(app.elemento("visorDoValor").waitForExistence(timeout: 5))
+        for _ in 0..<8 { app.buttons["tecla-del"].tap() }
+        for t in "12345" { app.buttons["tecla-\(t)"].tap() }
+        app.buttons["confirmarValor"].tap()
+        XCTAssertTrue(app.buttons["salvarGasto"].waitForExistence(timeout: 5))
+        let avisos = AvisosDaPonte()
+        app.buttons["salvarGasto"].tap()
+        XCTAssertTrue(app.elemento("linhaTopico").waitForNonExistence(timeout: 5), "a folha desce")
+        sleep(2)
+        XCTAssertEqual(avisos.caminhos(), ["direto"], "a ponte vai direto ao gasto à vista, sem passar pelo topo do cartão")
+        let barra = app.navigationBars.firstMatch.frame, capsula = app.buttons["aba-obras"].frame
+        XCTAssertTrue(linha.exists, "a linha editada está na árvore")
+        XCTAssertGreaterThanOrEqual(linha.frame.minY, barra.maxY, "a linha não fica sob a barra: \(linha.frame)")
+        XCTAssertLessThanOrEqual(linha.frame.maxY, capsula.minY, "nem sob a cápsula de abas: \(linha.frame)")
     }
 
     /// Na maior letra, a folha nas medidas do mockup (AX5): o nome da obra sai da barra e fica para o VoiceOver, no valor
@@ -365,4 +396,27 @@ final class GastoUITests: XCTestCase {
         alerta.buttons["OK"].tap()
         XCTAssertEqual(app.elemento("linhaValor").value as? String, "R$\u{a0}1.380,00", "o gasto continua na folha")
     }
+
+    /// Os avisos do caminho da ponte (PonteDaRolagem.avisarCaminho, só em Debug), lidos depois da ação.
+    private final class AvisosDaPonte {
+        private var direto: Int32 = 0, cartao: Int32 = 0
+
+        init() {
+            notify_register_check("br.com.custta.falso.ponte.direto", &direto)
+            notify_register_check("br.com.custta.falso.ponte.cartao", &cartao)
+            _ = caminhos()                                      // o 1º notify_check sempre diz que mudou
+        }
+
+        func caminhos() -> [String] {
+            var foiDireto: Int32 = 0, foiCartao: Int32 = 0
+            notify_check(direto, &foiDireto)
+            notify_check(cartao, &foiCartao)
+            return (foiDireto != 0 ? ["direto"] : []) + (foiCartao != 0 ? ["cartão"] : [])
+        }
+
+        deinit {
+            notify_cancel(direto)
+            notify_cancel(cartao)
+        }
+    }
 }
```

Em `app-ios/CusttaUITests/ObraUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/ObraUITests.swift
+++ b/app-ios/CusttaUITests/ObraUITests.swift
@@ -1,4 +1,5 @@
 import XCTest
+import notify
 
 /* A tela da obra (etapa 2, PR 1), com os dados da vitrine (a obra do mockup aprovado: 46 lançamentos, 13 a vencer):
    entrar pela lista e voltar pelo círculo e pela borda; o caminho que sobrevive à troca de aba; os indicadores com os
@@ -53,6 +54,36 @@ final class ObraUITests: XCTestCase {
         XCTAssertTrue(tituloPequeno.waitForExistence(timeout: 5), "rolada a tela, o nome passa para a barra")
     }
 
+    /// Com a obra rolada na maior letra, o Tamanho do Texto vai à letra padrão e volta, como pela Central de Controle (a
+    /// auditoria do iOS 26 faz o mesmo em volta de cada auditoria): a obra volta com a mesma peça no mesmo lugar. A List
+    /// guardava o número da rolagem e, na volta, com as linhas de cima na altura estimada, a tela parava num mês lá embaixo.
+    func testNaMaiorLetraIdaEVoltaDaLetraDeixaAObraNoLugar() {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1",
+                           argumentos: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"],
+                           extra: ["CUSTTA_TROCA_LETRA": "aviso"])
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
+        // Na maior letra, o anel da cápsula abraça a cápsula (355 pt), e não a célula da List (370): o QuadroProprio no
+        // fundo da linha. Na letra padrão, quem vigia é o testOAltoEmBlocosNaGrade.
+        let fase = app.elemento("faseDaObra").frame
+        XCTAssertLessThan(fase.width, app.windows.firstMatch.frame.width - 32 - 8, "o anel da cápsula na maior letra: \(fase)")
+        app.swipeUp()
+        app.swipeUp()
+        Thread.sleep(forTimeInterval: 1.5)
+        let pecas = ["indicadorTotal", "indicadorCorrigido", "indicadorAPagar", "indicadorVenda", "linhaDosAfazeres", "lancamentos"]
+        guard let id = pecas.first(where: { app.elemento($0).exists && app.elemento($0).isHittable }) else {
+            return XCTFail("nenhuma peça do alto à vista depois de rolar")
+        }
+        let peca = app.elemento(id), antes = peca.frame
+        notify_post("br.com.custta.falso.trocarLetra")          // a letra padrão
+        Thread.sleep(forTimeInterval: 2.5)
+        XCTAssertTrue(peca.exists, "\(id) segue na tela na letra padrão")
+        XCTAssertLessThan(peca.frame.height, antes.height - 1, "a letra padrão encolhe \(id): a troca chegou ao app")
+        notify_post("br.com.custta.falso.trocarLetra")          // de volta à maior
+        Thread.sleep(forTimeInterval: 2.5)
+        XCTAssertTrue(peca.exists, "\(id) segue na tela depois de a letra ir e voltar")
+        XCTAssertEqual(peca.frame.minY, antes.minY, accuracy: 2, "\(id) no mesmo lugar: antes \(antes), depois \(peca.frame)")
+    }
+
     func testAVencerFechadoAbreEFecha() {
         let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
         let aVencer = app.elemento("aVencer")
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" -derivedDataPath <seu dd> 2>&1 | grep -E "error:" | head -2
```
Expected (caminho encurtado):
```
CusttaTests/PonteDaRolagemTests.swift:11:17: error: cannot find 'deslocamento' in scope
CusttaTests/PonteDaRolagemTests.swift:16:17: error: cannot find 'deslocamento' in scope
```
Os testes de tela que a ponte rola (o A vencer e o g024 na maior letra, o da busca e o da letra) caem sem ela no Step 5,
com a ponte desligada; o do teclado e as duas guardas do anel caem nas mutações 5.3 e 5.4.

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/CusttaApp.swift`:

```diff
--- a/app-ios/Custta/CusttaApp.swift
+++ b/app-ios/Custta/CusttaApp.swift
@@ -16,6 +16,7 @@ struct CusttaApp: App {
             UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.clear]
             UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.clear]
         }
+        TrocaDeLetraDoTeste.vigiar()
         #endif
     }
 
```

Criar `app-ios/Custta/Falsos/TrocaDeLetraDoTeste.swift`:

```swift
#if DEBUG
import UIKit
import notify

/// Testes de tela: com `CUSTTA_TROCA_LETRA=aviso`, cada aviso do teste (notify_post de "br.com.custta.falso.trocarLetra")
/// troca o Tamanho do Texto do app, como a pessoa pela Central de Controle: o 1º põe a letra padrão por cima da do
/// lançamento, o 2º tira, e assim por diante. A troca é pelo traço da cena, que chega ao UIKit e ao SwiftUI como a do sistema.
@MainActor
enum TrocaDeLetraDoTeste {
    private static var padrao = false

    static func vigiar() {
        guard ProcessInfo.processInfo.environment["CUSTTA_TROCA_LETRA"] == "aviso" else { return }
        var token: Int32 = 0
        notify_register_dispatch("br.com.custta.falso.trocarLetra", &token, .main) { _ in
            MainActor.assumeIsolated { trocar() }
        }
    }

    private static func trocar() {
        padrao.toggle()
        for case let cena as UIWindowScene in UIApplication.shared.connectedScenes {
            if padrao {
                cena.traitOverrides.preferredContentSizeCategory = .large
            } else {
                cena.traitOverrides.remove(UITraitPreferredContentSizeCategory.self)
            }
        }
    }
}
#endif
```

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -19,6 +19,11 @@ struct ObraView: View {
     /// do Sincronizador não apagar o que está sendo digitado nem tirar o foco do campo.
     @State private var busca = BuscaDaObra()
     @FocusState private var buscaEmFoco: Bool
+    /// O dedo rola a lista (ou ela desliza depois dele): se o campo da busca passa da janela nesse meio tempo, o
+    /// teclado fecha.
+    @State private var dedoRolando = false
+    /// O campo da busca está além da janela (`campoForaDaJanela`): o arrasto seguinte fecha o teclado.
+    @State private var campoFora = false
     /// O "A vencer" com filtro abre sozinho, com os achados, a cada filtro novo; fechá-lo aí não mexe no de sem filtro.
     @State private var aVencerAbertoNaBusca = true
     /// A linha arrastada que mostra "Apagar" (uma por vez).
@@ -38,6 +43,8 @@ struct ObraView: View {
     /// O título pequeno mora num objeto próprio, lido só pela peça da barra: ao cruzar o limite no meio da rolagem, só
     /// ela se refaz, e não a tela inteira (lista, indicadores e cartões).
     @State private var barra = BarraDaObra()
+    /// A rolagem da List e as marcas das linhas acesas, para o rolar até o gasto salvo (PonteDaRolagem.swift).
+    @State private var ponte = PonteDaRolagem()
     #if DEBUG
     /// Laudo e conferência visual: a linha que abre mostrando "Apagar" (`-custta.linhaAberta g027`).
     @AppStorage("custta.linhaAberta") private var linhaDeTeste = ""
@@ -69,7 +76,8 @@ struct ObraView: View {
                                  apagar: { gasto in
                                      alvoDoApagar = gasto
                                      perguntando = true
-                                 })
+                                 },
+                                 ponte: ponte)
         return ScrollViewReader { leitor in
             // A obra numa List (UICollectionView), uma peça por linha e um cartão por mês numa linha: no iOS 26, a LazyVStack
             // entrava em laço de layout ao arrastar na maior letra numa obra de lista curta (#99).
@@ -79,6 +87,7 @@ struct ObraView: View {
                     TituloMono(texto: obra.nome)
                         .padding(EdgeInsets(top: -6, leading: 0, bottom: -4, trailing: 0))
                         .background { QuadroProprio() }
+                        .background { MarcaDaLista(ponte: ponte) }
                         #if DEBUG
                         .rolagemFixaDaLista()
                         #endif
@@ -123,16 +132,28 @@ struct ObraView: View {
                         .accessibilityValue(faladoDaBarra(pedacos, topicos: topicos))
                         .accessibilityIdentifier("gastosPorTopico")
                     }
-                    // 18 pt acima dos lançamentos (mockup, .lan-cab). O id fica na linha inteira, por fora do recuo: o scrollTo
-                    // da List só acha o id da linha, e a lupa rola até a pílula com os 6 pt de cima dela.
+                    // 18 pt acima dos lançamentos (mockup, .lan-cab). A marca da ponte cobre a pílula e os 6 pt de cima dela: a
+                    // lupa leva o topo da marca ao alto da parte à vista, e a pílula para onde parava na ScrollView (y 129 no 18
+                    // Pro, medido nas duas em 03/11).
                     CabecalhoDosLancamentos(contador: contadorLancamentos(total: obra.gastos.count, achados: achados.count, filtro: busca.filtro),
                                             busca: busca, meses: mesesDoFiltro(obra.gastos, escolhido: busca.mes),
                                             comBotoes: !obra.gastos.isEmpty || filtrando || busca.aberta, foco: $foco,
-                                            abrir: { abrirBusca(leitor) }, fechar: fecharBusca)
+                                            abrir: { abrirBusca() }, fechar: fecharBusca)
                         .padding(.top, 6)
-                        .id("lancamentos")
+                        .background { MarcaDaLinha(ponte: ponte, chave: "lancamentos") }
                     if busca.aberta {
                         CampoDaBusca(texto: $busca.texto, foco: $buscaEmFoco, fechar: fecharBusca)
+                            // O teclado fecha quando o dedo rola o campo meia tela além da tela, como na LazyVStack de antes,
+                            // que o desmontava ali, e ele perdia o foco. Na List, a célula com o foco fica viva e nunca sai da
+                            // tela para o onScrollVisibilityChange, e o .interactively sozinho só fecha quando o arrasto chega
+                            // ao teclado; o quadro do campo, sim, anda a cada quadro. Só com o dedo: quando os dados mudam (o
+                            // ×, cada letra), a List refaz as linhas, e o campo pula sem ninguém rolar. A medida é @Sendable e
+                            // só lê o quadro; a conta fica na ação, que é da thread principal, como a ponte.
+                            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { quadro in
+                                let fora = ponte.janela.map { Self.campoForaDaJanela(quadro, janela: $0) } ?? false
+                                if fora != campoFora { campoFora = fora }
+                                if fora && dedoRolando { buscaEmFoco = false }
+                            }
                     }
                     if !busca.mes.isEmpty {
                         ChipDoMes(mes: busca.mes, tirar: tirarOMes)
@@ -185,9 +206,16 @@ struct ObraView: View {
         }
         .scrollIndicators(.hidden)
         .scrollDismissesKeyboard(.interactively)
-        .onScrollPhaseChange { _, fase in if fase != .idle, linhaAberta != nil { fecharLinha() } }
+        .onScrollPhaseChange { _, fase in
+            if fase != .idle, linhaAberta != nil { fecharLinha() }
+            dedoRolando = fase == .tracking || fase == .interacting || fase == .decelerating
+            // O campo já estava além da janela (o dedo parou ali, ou a lista foi sem dedo): o arrasto seguinte fecha.
+            if dedoRolando && campoFora { buscaEmFoco = false }
+        }
         .onChange(of: folhas.aberta) { _, aberta in if aberta != nil { linhaAberta = nil } }
         .onChange(of: busca.filtrando) { _, agora in if agora { aVencerAbertoNaBusca = true } }
+        // Cada letra da busca muda os dados da List: a ponte segura a linha do alto (a pílula, com o campo embaixo).
+        .onChange(of: busca.filtro) { ponte.segurarOAlto() }
         .onChange(of: folhas.pedidoDeApagar) { _, p in if let p, p.obraId == obra.id { apagar(p, obra: obra, lista: lista) } }
         .onDisappear { linhaAberta = nil }
         .sensoryFeedback(.success, trigger: folhas.destaque)
@@ -258,12 +286,17 @@ extension ObraView {
 
     /// A lupa: abre o campo embaixo da pílula, rola a lista até a pílula e põe o teclado; com o campo aberto, só devolve o
     /// foco a ele.
-    private func abrirBusca(_ leitor: ScrollViewProxy) {
+    private func abrirBusca() {
         let rolar = !busca.aberta
         busca.aberta = true
         Task { @MainActor in
             if rolar {
-                withAnimation(opcoes.reduzirMovimento ? nil : .easeOut(duration: 0.3)) { leitor.scrollTo("lancamentos", anchor: .top) }
+                // O scrollTo da List não rola uma linha que já está na tela, e a pílula está: a ponte a leva ao topo. Com o
+                // campo entrando, a List mede de novo as linhas de cima: a ponte espera a lista assentar para calcular o
+                // alvo, e o foco vem depois, com o campo já na tela. Na VM lenta da CI, com o foco antes de o campo existir
+                // e o alvo calculado no meio da medida, a lista parava 160 pt além, com o campo sob a barra (1 em 4).
+                await ponte.rolarQuandoAssentar(ate: "lancamentos", a: 0, quadros: 30, animado: !opcoes.reduzirMovimento,
+                                                insistir: true)
             }
             buscaEmFoco = true
         }
@@ -288,8 +321,8 @@ extension ObraView {
         foco = .lancamentos
     }
 
-    /// Depois de salvar: rola em dois tempos (o cartão, que a LazyVStack cria, e depois a linha), abre o "A vencer" se o
-    /// gasto foi para lá, acende por 2 s e leva o VoiceOver para a linha.
+    /// Depois de salvar: leva o cartão do gasto ao topo, abre o "A vencer" se o gasto foi para lá, rola até o meio da linha
+    /// pela ponte do UIKit (o scrollTo da List só acha o cartão), acende por 2 s e leva o VoiceOver para a linha.
     private func mostrar(_ d: Folhas.Destaque, lista: ListaDaObra, leitor: ScrollViewProxy) {
         guard let primeiro = d.ids.first else { return }
         let noAVencer = lista.aVencer?.meses.contains { $0.gastos.contains { $0.id == primeiro } } ?? false
@@ -297,15 +330,26 @@ extension ObraView {
         acesos = Set(d.ids)
         novos = d.novo
         Task { @MainActor in
-            if let cartao { leitor.scrollTo(cartao, anchor: .center) }
-            // O "A vencer" abre depois de a lista chegar nele, ainda fechado: aberto antes, na maior letra (milhares de
-            // pontos que a LazyVStack ainda não criou), a rolagem parava num mês lá embaixo.
-            if noAVencer {
-                try? await Task.sleep(for: .milliseconds(80))
-                abrirAVencer()
+            let animado = !opcoes.reduzirMovimento
+            // Com a linha já na tela (a edição), a ponte vai direto ao gasto, sem passar pelo topo do cartão. No "A vencer"
+            // fechado a linha não existe: ele abre no tempo de antes, sem esperar a tentativa.
+            var direto = false
+            if !(noAVencer && !aVencerAbertoAgora) {
+                direto = await ponte.rolarSeAVista(ate: primeiro, animado: animado)
             }
-            try? await Task.sleep(for: .milliseconds(80))
-            withAnimation(opcoes.reduzirMovimento ? nil : .easeOut(duration: 0.3)) { leitor.scrollTo(primeiro, anchor: .center) }
+            if !direto {
+                if let cartao { leitor.scrollTo(cartao, anchor: .top) }
+                // O "A vencer" abre depois de a lista chegar nele, ainda fechado.
+                if noAVencer {
+                    try? await Task.sleep(for: .milliseconds(80))
+                    abrirAVencer()
+                }
+                // A marca da linha aparece quando a célula do cartão entra na tela e se mede: até ~1 s.
+                await ponte.rolarQuandoAssentar(ate: primeiro, quadros: 60, animado: animado)
+            }
+            #if DEBUG
+            ponte.avisarCaminho(direto: direto)
+            #endif
             try? await Task.sleep(for: .milliseconds(450))
             foco = .gasto(primeiro)
             try? await Task.sleep(for: .seconds(2))
@@ -362,6 +406,8 @@ struct AcoesDaLista {
     let foco: AccessibilityFocusState<AlvoDoFoco?>.Binding
     let tocar: (Gasto) -> Void
     let apagar: (Gasto) -> Void
+    /// Só na obra: a ponte que acha a linha do gasto salvo na rolagem (nil nas folhas).
+    var ponte: PonteDaRolagem? = nil
 }
 
 /// Uma linha de gasto na lista: tocar edita, arrastar mostra "Apagar", acende depois de salvar. Para o VoiceOver é um
@@ -382,6 +428,9 @@ struct LinhaDaLista: View {
         }
         .id(gasto.id)
         .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
+        .background {
+            if let ponte = lista.ponte, lista.acesos.contains(gasto.id) { MarcaDaLinha(ponte: ponte, chave: gasto.id) }
+        }
     }
 }
 
@@ -541,7 +590,10 @@ struct SeparadorDaLista: View {
 /// O quadro próprio de uma peça sozinha numa linha da List (o título, a cápsula, a soma dos achados): uma vista vazia do
 /// UIKit no fundo da linha. Sem ela, a célula inteira vira o elemento de acessibilidade, e o anel do VoiceOver toma a linha
 /// toda (a cápsula com 370 pt de largura, e não os 269 dela). Com ela, a célula vira um contêiner, e a peça fica com o quadro
-/// dela, igual ao da ScrollView. Depende de a List ser uma UICollectionView, como a ponte; o testOAltoEmBlocosNaGrade vigia.
+/// dela, igual ao da ScrollView. Depende de a List ser uma UICollectionView, como a ponte. As linhas que dependem de uma vista
+/// do UIKit no fundo: o título (este quadro e a marca da lista), a cápsula e a soma (este quadro) e a pílula sozinha da obra
+/// sem gastos (a marca "lancamentos" da ponte). Vigiam o testOAltoEmBlocosNaGrade (título e cápsula), o
+/// testNaMaiorLetraIdaEVoltaDaLetraDeixaAObraNoLugar (cápsula na maior letra) e a BuscaUITests (soma e pílula sozinha).
 private struct QuadroProprio: UIViewRepresentable {
     func makeUIView(context: Context) -> UIView {
         let vista = UIView()
@@ -551,3 +603,13 @@ private struct QuadroProprio: UIViewRepresentable {
 
     func updateUIView(_ uiView: UIView, context: Context) {}
 }
+
+extension ObraView {
+    /// O campo da busca passou da janela em que a LazyVStack de antes o mantinha montado: meia tela além da borda da tela, em
+    /// cima ou embaixo. Na main, em 04/11, no 26.5 (arrastos de 77 pt), o teclado fechava com o topo do campo entre −428 e
+    /// −505 pt e entre 1.271 e 1.326 pt, numa tela de 874. A janela é a da List, que passa por baixo da barra e do teclado.
+    nonisolated static func campoForaDaJanela(_ campo: CGRect, janela: CGRect) -> Bool {
+        let folga = janela.height / 2
+        return campo.maxY < janela.minY - folga || campo.minY > janela.maxY + folga
+    }
+}
```

Criar `app-ios/Custta/Telas/PonteDaRolagem.swift`:

```swift
import SwiftUI
import UIKit
#if DEBUG
import notify
#endif

/* A ponte do UIKit para rolar a obra até uma peça. A obra é uma List (UICollectionView), e o scrollTo dela só acha a linha,
   que é o cartão do mês inteiro (na maior letra, um mês da obra pesada passa de 13 mil pt), trata a âncora fracionária como
   o centro e não rola uma linha que já está na tela: a 1ª parcela de uma compra no cartão parava fora da tela, e a lupa não
   levava a pílula ao topo. A ponte guarda uma marca (uma vista vazia) por chave: em cada linha acesa depois de salvar (o id
   do gasto) e na pílula ("lancamentos"). Da marca, ela sobe até a rolagem que a contém, a da List; o quadro da marca,
   convertido para a rolagem, diz onde a peça está no conteúdo, e a rolagem anda até ela. A ponte tenta uma vez por
   quadro, até a lista parar de se medir, sem forçar o layout: um cartão gigante se mediria de novo, de uma vez, na thread
   principal.
   Quando o Tamanho do Texto muda com a obra rolada, a ponte segura a linha que estava no alto (a List guardaria o número da
   rolagem, e a tela iria para outro lugar). Ela conhece a List pela marca da 1ª linha, que está na tela quando a obra abre.
   RISCO: a ponte depende de a List ser uma UICollectionView com as vistas da linha dentro dela, que é detalhe do SwiftUI. Se
   um iOS novo mudar isso, ela não acha a rolagem ou a marca e não rola: a lista fica no topo do cartão, e os testes da maior
   letra (GastoUITests, ObraUITests) e o da busca caem e avisam. */
@MainActor
final class PonteDaRolagem {
    private var marcas: [String: Fraca] = [:]

    private final class Fraca {
        weak var vista: MarcaDaLinha.Vista?
        init(_ vista: MarcaDaLinha.Vista) { self.vista = vista }
    }

    func marcar(_ vista: MarcaDaLinha.Vista, chave: String) {
        vista.chave = chave
        marcas[chave] = Fraca(vista)
    }

    /// A marca saiu da linha (ou trocou de chave): a chave dela deixa de apontar para essa vista.
    func esquecer(_ vista: MarcaDaLinha.Vista) {
        if let chave = vista.chave, marcas[chave]?.vista === vista { marcas[chave] = nil }
    }

    /// A rolagem em que a marca da chave está, se ela está na tela: a da List, e não uma rolagem de dentro da linha.
    private func rolagem(de chave: String) -> (UIScrollView, UIView)? {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "custta.semPonte") { return nil }   // o caminho manso, para o teste que o reprova
        #endif
        // A vista guarda a chave: se o SwiftUI a reaproveitou noutra linha, a chave velha não acha a linha errada.
        guard let marca = marcas[chave]?.vista, marca.chave == chave, marca.window != nil else { return nil }
        var vista = marca.superview
        while let atual = vista, !(atual is UICollectionView) { vista = atual.superview }
        return (vista as? UICollectionView).map { ($0, marca) }
    }

    #if DEBUG
    /// Testes de tela: o caminho que a rolagem até o gasto salvo tomou, num aviso do sistema ("…ponte.direto", direto ao gasto
    /// à vista; "…ponte.cartao", pelo topo do cartão do mês). O GastoUITests confere que a edição com a linha à vista vai direto.
    func avisarCaminho(direto: Bool) {
        notify_post(direto ? "br.com.custta.falso.ponte.direto" : "br.com.custta.falso.ponte.cartao")
    }
    #endif

    /// Tenta uma vez por quadro, até `quadros` vezes: quando a marca da peça está na tela e a altura do conteúdo é a mesma
    /// em dois quadros seguidos (a lista parou de se medir), rola até o ponto `fracao` dela (o meio do gasto; o topo da
    /// pílula). Devolve se rolou; sem a marca, a lista fica onde está. Nada força o layout: a lista se mede no tempo dela.
    /// Com `insistir`, se a lista não assenta nesses quadros, rola com a última medida (a lupa: sem isso, a pílula ficava onde
    /// estava e o campo podia ficar sob o teclado).
    @discardableResult func rolarQuandoAssentar(ate chave: String, a fracao: CGFloat = 0.5, quadros: Int,
                                                animado: Bool, insistir: Bool = false) async -> Bool {
        var anterior: CGFloat?
        for _ in 0..<quadros {
            try? await Task.sleep(for: .milliseconds(16))
            guard let (rolagem, _) = rolagem(de: chave) else { anterior = nil; continue }
            let altura = rolagem.contentSize.height
            if altura == anterior { return rolar(chave, a: fracao, animado: animado) }
            anterior = altura
        }
        return insistir && rolar(chave, a: fracao, animado: animado)
    }

    /// A tentativa direta do `mostrar`: procura a marca do gasto por `procurar` quadros; achada, espera a lista parar de se
    /// medir (até `quadros`) e rola até o meio dela, com a última medida se ela não assentar. Só devolve falso quando a marca
    /// não aparece: a célula ainda se medindo (a etiqueta "novo" quebrando a linha) não manda a obra pelo cartão, o salto que
    /// o conselho descartou, e o caminho direto não depende de a lista assentar em três quadros numa VM lenta.
    func rolarSeAVista(ate chave: String, procurar: Int = 3, quadros: Int = 60, animado: Bool) async -> Bool {
        var anterior: CGFloat?
        var achou = false
        for i in 0..<quadros {
            try? await Task.sleep(for: .milliseconds(16))
            guard let (rolagem, _) = rolagem(de: chave) else {
                if !achou && i + 1 >= procurar { return false }
                anterior = nil
                continue
            }
            achou = true
            let altura = rolagem.contentSize.height
            if altura == anterior { return rolar(chave, a: 0.5, animado: animado) }
            anterior = altura
        }
        return achou && rolar(chave, a: 0.5, animado: animado)
    }

    // MARK: A letra que muda com a obra rolada

    private weak var lista: UICollectionView?

    /// A janela da List na tela inteira (a rolagem passa por baixo da barra e do teclado): o teclado da busca mede o campo
    /// contra ela (ObraView.campoForaDaJanela).
    var janela: CGRect? { lista?.window?.bounds }
    private var observacao: NSKeyValueObservation?
    /// A linha no alto da parte à vista e onde, dentro dela, a parte à vista começa (0 é o topo da linha, 1 o fim; negativa
    /// quando o alto cai no vão de 12 pt acima dela, e aí o ponto fica no vão: presa a 0, a lista pulava até 12 pt).
    private var alto: (indice: IndexPath, fracao: CGFloat)?
    private var segurarAte = Date.distantPast
    /// Quadros seguidos com a mesma altura do conteúdo, desde a última mudança.
    private var estavel = 0

    /// A List da obra, achada pela marca da 1ª linha, que está na tela quando a obra abre.
    func conhecer(_ marca: UIView) {
        var vista = marca.superview
        while let atual = vista, !(atual is UICollectionView) { vista = atual.superview }
        guard let lista = vista as? UICollectionView, lista !== self.lista else { return }
        self.lista = lista
        observacao = lista.observe(\.contentOffset, options: [.new]) { [weak self] lista, _ in
            MainActor.assumeIsolated { self?.guardarOAlto(lista) }
        }
        lista.registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { [weak self] (lista: UICollectionView, _: UITraitCollection) in
            MainActor.assumeIsolated { self?.segurarOAltoAteAssentar(lista) }
        }
    }

    private func guardarOAlto(_ lista: UICollectionView) {
        guard Date.now > segurarAte else { return }
        let topo = lista.contentOffset.y + lista.adjustedContentInset.top
        alto = linhaDoAlto(topo, em: lista.indexPathsForVisibleItems
            .compactMap { indice in lista.layoutAttributesForItem(at: indice).map { (indice, $0.frame) } })
    }

    /// O filtro da busca mudou os dados: a List volta as linhas de cima da tela à altura estimada e, na VM lenta da CI, nem
    /// sempre compensa a rolagem; a pílula subia 160 pt, com o campo sob a barra (2 de 6). Segura a linha do alto como na
    /// letra que muda. Outra mudança de dados com a busca aberta (outro aparelho apaga um gasto) não passa por aqui.
    func segurarOAlto() {
        guard let lista else { return }
        segurarOAltoAteAssentar(lista)
    }

    /// O Tamanho do Texto mudou (ou o filtro da busca): a List mede as linhas de novo e guarda o número da rolagem, e a tela
    /// vai para outro lugar (na ida e volta da letra, as linhas de cima ficam na altura estimada, e a obra rolada parava num
    /// mês lá embaixo). A ponte segura a linha que estava no alto, no mesmo ponto dela, a cada quadro, até a lista parar de se
    /// medir (a mesma altura do conteúdo por 10 quadros), com teto de 3 s; um arrasto, ou a lista deslizando depois dele,
    /// solta.
    private func segurarOAltoAteAssentar(_ lista: UICollectionView) {
        #if DEBUG
        if UserDefaults.standard.object(forKey: "custta.rolagem") != nil { return }   // o gancho dos testes segura
        if UserDefaults.standard.bool(forKey: "custta.semPonte") { return }           // o caminho manso, para o teste que o reprova
        #endif
        guard let alto else { return }
        let segurando = Date.now < segurarAte
        segurarAte = Date.now.addingTimeInterval(3)
        estavel = 0
        guard !segurando else { return }
        Task { @MainActor in
            var anterior: CGFloat?
            while Date.now < segurarAte {
                try? await Task.sleep(for: .milliseconds(16))
                if lista.isTracking || lista.isDragging || lista.isDecelerating { segurarAte = .distantPast; break }
                let altura = lista.contentSize.height
                estavel = altura == anterior ? estavel + 1 : 0
                anterior = altura
                if estavel >= 10 { segurarAte = .distantPast; break }
                guard alto.indice.section < lista.numberOfSections,
                      alto.indice.item < lista.numberOfItems(inSection: alto.indice.section),
                      let quadro = lista.layoutAttributesForItem(at: alto.indice)?.frame else { continue }
                let ponto = CGRect(x: quadro.minX, y: quadro.minY + alto.fracao * quadro.height, width: quadro.width, height: 0)
                let alvo = deslocamento(levando: ponto, a: 0, recuoDeCima: lista.adjustedContentInset.top,
                                        recuoDeBaixo: lista.adjustedContentInset.bottom, altura: lista.bounds.height,
                                        conteudo: lista.contentSize.height)
                if abs(lista.contentOffset.y - alvo) > 0.5 { lista.contentOffset.y = alvo }
            }
        }
    }

    private func rolar(_ chave: String, a fracao: CGFloat, animado: Bool) -> Bool {
        guard let (rolagem, marca) = rolagem(de: chave) else { return false }
        let y = deslocamento(levando: marca.convert(marca.bounds, to: rolagem), a: fracao,
                             recuoDeCima: rolagem.adjustedContentInset.top, recuoDeBaixo: rolagem.adjustedContentInset.bottom,
                             altura: rolagem.bounds.height, conteudo: rolagem.contentSize.height)
        rolagem.setContentOffset(CGPoint(x: rolagem.contentOffset.x, y: y), animated: animado)
        return true
    }
}

/// A linha no alto da parte à vista (a 1ª que termina abaixo do alto) e onde, nela, o alto cai: a fração da altura, 0 no
/// topo e 1 no fim, negativa quando o alto cai no vão de 12 pt acima dela. Com a fração negativa, o ponto fica no vão: presa
/// a 0, ela levava o alto ao topo da linha de baixo, e a lista pulava até 12 pt quando a letra ou o filtro mudavam (o gancho
/// dos testes, que usa esta conta, parava a v1 a 400 5,33 pt abaixo da main).
func linhaDoAlto(_ topo: CGFloat, em quadros: [(IndexPath, CGRect)]) -> (indice: IndexPath, fracao: CGFloat)? {
    quadros.filter { $0.1.maxY > topo }.min { $0.1.minY < $1.1.minY }.map { ($0.0, (topo - $0.1.minY) / max(1, $0.1.height)) }
}

/// O deslocamento da rolagem que leva o ponto `fracao` do quadro (na régua do conteúdo; 0 é o topo, 0,5 o meio) ao mesmo
/// ponto da parte à vista, entre os recuos de cima e de baixo, preso ao começo e ao fim do conteúdo.
func deslocamento(levando quadro: CGRect, a fracao: CGFloat, recuoDeCima: CGFloat, recuoDeBaixo: CGFloat, altura: CGFloat,
                  conteudo: CGFloat) -> CGFloat {
    let visivel = altura - recuoDeCima - recuoDeBaixo
    let comeco = -recuoDeCima
    let fim = max(comeco, conteudo + recuoDeBaixo - altura)
    let ponto = quadro.minY + fracao * quadro.height
    return min(max(ponto - recuoDeCima - fracao * visivel, comeco), fim)
}

/// A marca da 1ª linha: apresenta a List à ponte quando entra na janela.
struct MarcaDaLista: UIViewRepresentable {
    let ponte: PonteDaRolagem

    final class Vista: UIView {
        weak var ponte: PonteDaRolagem?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil { ponte?.conhecer(self) }
        }
    }

    func makeUIView(context: Context) -> Vista {
        let vista = Vista()
        vista.isUserInteractionEnabled = false
        vista.ponte = ponte
        return vista
    }

    func updateUIView(_ uiView: Vista, context: Context) { uiView.ponte = ponte }
}

/// A marca de uma peça: uma vista vazia no fundo dela, que a ponte converte para a rolagem.
struct MarcaDaLinha: UIViewRepresentable {
    let ponte: PonteDaRolagem
    let chave: String

    /// A vista vazia, com a chave da peça e a ponte que a guarda.
    final class Vista: UIView {
        var chave: String?
        weak var ponte: PonteDaRolagem?
    }

    func makeUIView(context: Context) -> Vista {
        let vista = Vista()
        vista.isUserInteractionEnabled = false
        return vista
    }

    func updateUIView(_ uiView: Vista, context: Context) {
        if uiView.chave != nil && uiView.chave != chave { uiView.ponte?.esquecer(uiView) }
        uiView.ponte = ponte
        ponte.marcar(uiView, chave: chave)
    }

    static func dismantleUIView(_ uiView: Vista, coordinator: ()) { uiView.ponte?.esquecer(uiView) }
}
```

Em `app-ios/Custta/Telas/RolagemFixaDaLista.swift`:

```diff
--- a/app-ios/Custta/Telas/RolagemFixaDaLista.swift
+++ b/app-ios/Custta/Telas/RolagemFixaDaLista.swift
@@ -56,14 +56,11 @@ final class AncoraDaRolagemFixa: UIView {
     /// padrão, uma folga em pontos passava do fim da linha e mostrava outras, que a auditoria perdia ("sem elemento").
     private static func segurar(_ lista: UICollectionView, y: Double) {
         let topo = lista.contentOffset.y + lista.adjustedContentInset.top
-        let ancora = lista.indexPathsForVisibleItems
-            .compactMap { indice in lista.layoutAttributesForItem(at: indice).map { (indice, $0.frame) } }
-            .filter { $0.1.maxY > topo }
-            .min { $0.1.minY < $1.1.minY }
-        let indice = ancora?.0
-        // Negativa quando o alto cai no vão de 12 pt entre duas linhas: o ponto fica no vão, como o número da ScrollView.
-        // Presa a 0, ela levava o alto ao topo da linha de baixo (a v1 a 400 parava 5,33 pt abaixo da main).
-        let fracao = ancora.map { (topo - $0.1.minY) / max(1, $0.1.height) } ?? 0
+        // A conta da ponte (linhaDoAlto): a fração fica negativa quando o alto cai no vão entre duas linhas.
+        let ancora = linhaDoAlto(topo, em: lista.indexPathsForVisibleItems
+            .compactMap { indice in lista.layoutAttributesForItem(at: indice).map { (indice, $0.frame) } })
+        let indice = ancora?.indice
+        let fracao = ancora?.fracao ?? 0
         observacoes = [
             lista.observe(\.contentOffset, options: [.new]) { rolada, _ in
                 MainActor.assumeIsolated { ajustar(rolada, y: y, ancora: indice, fracao: fracao) }
```

- [ ] **Step 4: Ver passar**

Run:
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaTests/PonteDaRolagemTests -only-testing:CusttaUITests/GastoUITests \
  -only-testing:CusttaUITests/BuscaUITests \
  -only-testing:CusttaUITests/ObraUITests/testNaMaiorLetraIdaEVoltaDaLetraDeixaAObraNoLugar 2>&1 \
  | grep -E "Executed|SUCCEEDED|FAILED" | tail -3
```
Expected (no 26.5 e no 27, 0 quedas):
```
# 26.5
Executed 38 tests, with 0 failures (0 unexpected) in 960.412 (960.429) seconds
Executed 38 tests, with 0 failures (0 unexpected) in 960.412 (960.430) seconds
** TEST EXECUTE SUCCEEDED **
# 27
Executed 38 tests, with 0 failures (0 unexpected) in 875.568 (875.604) seconds
Executed 38 tests, with 0 failures (0 unexpected) in 875.568 (875.605) seconds
** TEST EXECUTE SUCCEEDED **
```
e, antes, `✔ Test run with 7 tests in 1 suite passed` da `PonteDaRolagemTests`.

- [ ] **Step 5: As guardas mordem**

Cada mutação: troque, compile (`xcodebuild build-for-testing "${XB[@]}" -derivedDataPath <seu dd> 2>&1 | grep -E
"error:|TEST BUILD" | tail -1`), rode e desfaça.

1. A ponte desligada: troque o `UserDefaults.standard.bool(forKey: "custta.semPonte")` por `true` nos dois lugares da
   `PonteDaRolagem` (o mesmo que o `-custta.semPonte` de Debug), compile e rode os três do Gasto na maior letra, o da busca
   e o da letra. Desfaça depois. Caem quatro; o do gasto salvo passa, porque o gasto novo é o 1º do cartão do mês, que a
   reserva leva ao topo: quem vigia a ponte no gasto salvo são o A vencer e o g024.
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/GastoUITests/testNaMaiorLetraAListaRolaAteOGastoSalvo \
  -only-testing:CusttaUITests/GastoUITests/testNaMaiorLetraAListaRolaAteOAVencer \
  -only-testing:CusttaUITests/GastoUITests/testNaMaiorLetraEditarUmGastoDoFimDoMesDeixaALinhaAVista \
  -only-testing:CusttaUITests/BuscaUITests/testBuscarSemAcentoPeloTopicoEPelaDescricao \
  -only-testing:CusttaUITests/ObraUITests/testNaMaiorLetraIdaEVoltaDaLetraDeixaAObraNoLugar 2>&1 | grep -E "error:" | cut -c1-240
```
Expected:
```
BuscaUITests.swift:70: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : XCTAssertLessThan failed: ("396.3333333333333") is not less than ("200.0") - a lista rola até a pílula, com o campo embaixo
BuscaUITests.swift:86: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : XCTAssertEqual failed: ("Lançamentos, 12 de 46") is not equal to ("Lançamentos, 46") - o × do texto limpa a busca
BuscaUITests.swift:91: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : XCTAssertEqual failed: ("Lançamentos, 0 de 46") is not equal to ("Lançamentos, 12 de 46") - com acento, maiúscula e espaço no fim, o mesmo
BuscaUITests.swift:92: error: -[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao] : Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Any` -> `Elements matching predicate '"aVencer" IN identifiers'`, given input App element pid: 9163
Test Case '-[CusttaUITests.BuscaUITests testBuscarSemAcentoPeloTopicoEPelaDescricao]' failed (40.266 seconds).
GastoUITests.swift:82: error: -[CusttaUITests.GastoUITests testNaMaiorLetraAListaRolaAteOAVencer] : XCTAssertLessThanOrEqual failed: ("2341.333333333334") is greater than ("794.0") - e acima da cápsula de abas: (16.0, 2012.0000000000007, 370.0, 329.33333333333326)
Test Case '-[CusttaUITests.GastoUITests testNaMaiorLetraAListaRolaAteOAVencer]' failed (10.193 seconds).
Test Case '-[CusttaUITests.GastoUITests testNaMaiorLetraAListaRolaAteOGastoSalvo]' passed (16.239 seconds).
GastoUITests.swift:105: error: -[CusttaUITests.GastoUITests testNaMaiorLetraEditarUmGastoDoFimDoMesDeixaALinhaAVista] : XCTAssertEqual failed: ("["cartão"]") is not equal to ("["direto"]") - a ponte vai direto ao gasto à vista, sem passar pelo topo do cartão
GastoUITests.swift:109: error: -[CusttaUITests.GastoUITests testNaMaiorLetraEditarUmGastoDoFimDoMesDeixaALinhaAVista] : XCTAssertLessThanOrEqual failed: ("2077.6666666666665") is greater than ("794.0") - nem sob a cápsula de abas: (16.0, 1697.0, 370.0, 380.6666666666665)
Test Case '-[CusttaUITests.GastoUITests testNaMaiorLetraEditarUmGastoDoFimDoMesDeixaALinhaAVista]' failed (85.233 seconds).
ObraUITests.swift:79: error: -[CusttaUITests.ObraUITests testNaMaiorLetraIdaEVoltaDaLetraDeixaAObraNoLugar] : XCTAssertTrue failed - indicadorCorrigido segue na tela na letra padrão
ObraUITests.swift:80: error: -[CusttaUITests.ObraUITests testNaMaiorLetraIdaEVoltaDaLetraDeixaAObraNoLugar] : Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Any` -> `Elements matching predicate '"indicadorCorrigido" IN identifiers'`, given input App element pid: 10473
Test Case '-[CusttaUITests.ObraUITests testNaMaiorLetraIdaEVoltaDaLetraDeixaAObraNoLugar]' failed (18.160 seconds).
```
2. O caminho direto: na `ObraView.mostrar`, troque a tentativa direta (`direto = await ponte.rolarSeAVista(ate: primeiro,
   animado: animado)`) por `direto = false`, compile e rode o teste do g024. Desfaça depois.
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/GastoUITests/testNaMaiorLetraEditarUmGastoDoFimDoMesDeixaALinhaAVista 2>&1 | grep -E "error:"
```
Expected (a linha termina à vista pelo caminho de reserva, e só o aviso do caminho cai):
```
GastoUITests.swift:105: error: -[CusttaUITests.GastoUITests testNaMaiorLetraEditarUmGastoDoFimDoMesDeixaALinhaAVista] : XCTAssertEqual failed: ("["cartão"]") is not equal to ("["direto"]") - a ponte vai direto ao gasto à vista, sem passar pelo topo do cartão
```
3. O teclado: (a) na ação do `onGeometryChange` do campo, troque o `let fora = ponte.janela.map { … } ?? false` por
   `let fora = false` (o campo nunca passa da janela); (b) depois, em `campoForaDaJanela`, troque a folga de meia tela por
   0. Rode o teste do teclado em cada uma:
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaUITests/BuscaUITests/testArrastoCurtoDeixaOTecladoEOsLongosOFecham 2>&1 | grep -E "error:" | cut -c1-240
```
Expected (em a, os longos não fecham; em b, o curto fecha):
```
# a: o campo nunca passa da janela
BuscaUITests.swift:243: error: -[CusttaUITests.BuscaUITests testArrastoCurtoDeixaOTecladoEOsLongosOFecham] : XCTAssertTrue failed - os arrastos longos não fecharam o teclado
Test Case '-[CusttaUITests.BuscaUITests testArrastoCurtoDeixaOTecladoEOsLongosOFecham]' failed (46.211 seconds).
# b: folga 0
BuscaUITests.swift:237: error: -[CusttaUITests.BuscaUITests testArrastoCurtoDeixaOTecladoEOsLongosOFecham] : XCTAssertTrue failed - o arrasto curto fechou o teclado
Test Case '-[CusttaUITests.BuscaUITests testArrastoCurtoDeixaOTecladoEOsLongosOFecham]' failed (19.668 seconds).
```
4. O anel: (a) tire o `.background { MarcaDaLinha(ponte: ponte, chave: "lancamentos") }` da pílula e rode o
   `BuscaUITests/testObraSemGastoSoAPilula`; (b) tire o `.background { QuadroProprio() }` da cápsula (`faseDaObra`) e rode o
   `ObraUITests/testNaMaiorLetraIdaEVoltaDaLetraDeixaAObraNoLugar`.
Expected (o anel com a largura da linha):
```
# a: sem a marca no fundo da pílula
BuscaUITests.swift:225: error: -[CusttaUITests.BuscaUITests testObraSemGastoSoAPilula] : XCTAssertLessThan failed: ("370.0") is not less than ("330.0") - o anel da pílula: (16.0, 526.6666666666667, 370.0, 36.0)
Test Case '-[CusttaUITests.BuscaUITests testObraSemGastoSoAPilula]' failed (15.493 seconds).
# b: sem o quadro próprio da cápsula
ObraUITests.swift:68: error: -[CusttaUITests.ObraUITests testNaMaiorLetraIdaEVoltaDaLetraDeixaAObraNoLugar] : XCTAssertLessThan failed: ("370.0") is not less than ("362.0") - o anel da cápsula na maior letra: (16.0, 223.33333333333334, 370.0, 275.33333333333337)
Test Case '-[CusttaUITests.ObraUITests testNaMaiorLetraIdaEVoltaDaLetraDeixaAObraNoLugar]' failed (22.623 seconds).
```
5. A linha do alto no vão: em `linhaDoAlto`, ponha de volta o `max(0, …)` na fração, rode a `PonteDaRolagemTests` e tire o
   print da v1 a 400 (`prints-da-obra.sh … 'v1-400'`, comparado com o `antes` da `main`, `--cenas 'v1-400'`).
Expected (o teste do vão cai, e a v1 a 400 sai 5,33 pt abaixo da `main`):
```
# PonteDaRolagemTests com o max(0, …) de volta em linhaDoAlto
✘ Test altoNoVaoFicaNoVaoQuandoALetraMuda() recorded an issue at PonteDaRolagemTests.swift:54:9: Expectation failed: abs(volta - 400) < 0.01
✘ Test altoNoVaoFicaNoVaoQuandoALetraMuda() recorded an issue at PonteDaRolagemTests.swift:57:9: Expectation failed: naMaiorLetra > 508 && naMaiorLetra < 520
✘ Test altoNoVaoFicaNoVaoQuandoALetraMuda() failed after 0.011 seconds with 2 issues.
✘ Suite PonteDaRolagemTests failed after 0.018 seconds with 2 issues.
✘ Test run with 7 tests in 1 suite failed after 0.022 seconds with 2 issues.
# o print da v1 a 400, contra a main (--cenas v1-400)
v1-400-claro.png: canais >16: 1079565, >48: 633757, máx 244, média 15.396  ← passa do limite
v1-400-escuro.png: canais >16: 906351, >48: 580027, máx 221, média 13.994  ← passa do limite
```

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/CusttaApp.swift app-ios/Custta/Falsos/TrocaDeLetraDoTeste.swift app-ios/Custta/Telas/ObraView.swift app-ios/Custta/Telas/PonteDaRolagem.swift app-ios/Custta/Telas/RolagemFixaDaLista.swift app-ios/CusttaTests/PonteDaRolagemTests.swift app-ios/CusttaUITests/BuscaUITests.swift app-ios/CusttaUITests/GastoUITests.swift app-ios/CusttaUITests/ObraUITests.swift
git commit -m "feat: obra rola até o gasto salvo e até a pílula pela ponte do UIKit" -m "Na List, o scrollTo só acha a linha, que é o cartão do mês inteiro, trata a âncora fracionária como o centro e não rola uma linha que já está na tela: na maior letra, a 1ª parcela de uma compra no cartão parava fora da tela, e a lupa não levava a pílula ao topo. A ponte guarda uma marca (uma vista vazia) por chave, em cada linha acesa depois de salvar e na pílula; dela, sobe até a UICollectionView e anda até a peça. A marca guarda a própria chave e sai quando a linha sai: uma vista reaproveitada noutra linha não leva a rolagem para a linha errada. Com a linha do gasto na tela, como na edição, a ponte espera a lista assentar ali e vai direto ao meio dela; senão, o cartão vai ao topo e a ponte tenta a cada quadro até a lista parar de se medir (até ~1 s), sem forçar o layout. Em Debug, ela avisa o caminho que tomou, e o teste da edição confere que foi direto. Com o gasto num A vencer fechado, a linha ainda não existe, e ele abre no tempo de antes. A lupa leva a pílula ao topo depois de a lista assentar (o campo que entra faz a List medir de novo as linhas de cima), ou com a última medida se ela não assenta, e o teclado vem logo depois, com o campo já na tela; o id da pílula e o leitor da lupa saem. Cada letra da busca muda os dados, e a List volta as linhas de cima à altura estimada; na VM lenta da CI, nem sempre compensava, e a pílula subia 160 pt, com o campo sob a barra e o × fora do alcance. Quando o filtro muda ou o Tamanho do Texto muda com a obra rolada, a ponte segura a linha que estava no alto até a lista parar de se medir (a mesma altura por 10 quadros, com teto de 3 s), e um arrasto, ou a lista deslizando depois dele, solta: a List guardava o número da rolagem e, na ida e volta da letra, a tela parava num mês lá embaixo. O teclado da busca volta a fechar quando o dedo rola o campo meia tela além da tela, como na LazyVStack de hoje, que o desmontava ali: a ponte dá a janela da List, e a obra mede o campo contra ela a cada quadro. Risco: depende de a List ser uma UICollectionView com as vistas da linha dentro dela; se um iOS novo mudar isso, os testes da maior letra e o da busca caem."
```

### Task 10: A obra pesada nos falsos, para a medida no iPhone

A sessão no iPhone do Giovani, portão do merge, mede a célula gigante no Instruments. Ela usa uma versão de Debug com os
serviços falsos, e a obra pesada ainda não existe neles: até aqui, só nos ramos `proto/`.
- **Os dados.** `CUSTTA_DADOS=pesada` põe 520 gastos a mais na Casa Alphaville, um por dia para trás a partir de ontem, 566
  no total.
- **O mês cheio.** Cada mês passado fica com uns 30 gastos. Na maior letra, o cartão de um mês vira uma célula de mais de
  13 mil pt.
- **Variante nova de falso** pede um teste que a carregue (memória `variante-de-falso-sem-teste-de-formato`). O teste roda em
  todo dia da vitrine, também no 29/02, e prende a forma de que a medida depende: `p001` ontem e `p520` há 520 dias, um por
  dia, nenhum hoje nem no futuro, o A vencer igual ao da vitrine e um mês passado com 30 ou mais. Contar só os 566 deixaria
  passar os 520 no futuro (um A vencer gigante, e não meses cheios).

**Files:**
- Modify: `app-ios/Custta/Falsos/MontarFalso.swift`
- Modify: `app-ios/Custta/Falsos/VitrineDaObra.swift`
- Test (alterar): `app-ios/CusttaTests/DadosDeExemploTests.swift`

**Interfaces:**
- Consumes: `DadosDeExemplo.vitrine(hoje:)`, `Composicao` (`MontarFalso.swift`).
- Produces: `DadosDeExemplo.vitrinePesada(hoje:) -> ValorJSON`; `CUSTTA_DADOS=pesada`.

- [ ] **Step 1: Escrever o teste**

Em `app-ios/CusttaTests/DadosDeExemploTests.swift`:

```diff
--- a/app-ios/CusttaTests/DadosDeExemploTests.swift
+++ b/app-ios/CusttaTests/DadosDeExemploTests.swift
@@ -36,6 +36,35 @@ struct DadosDeExemploTests {
         #expect(orcamentoObra(obras[1]) == nil && orcamentoObra(obras[2]) == nil)
     }
 
+    /// A obra pesada (`CUSTTA_DADOS=pesada`, a da medida da obra em List no iPhone) carrega em qualquer dia: a Casa
+    /// Alphaville com 520 gastos a mais, um por dia, de ontem para trás (p001 ontem, p520 há 520 dias), 566 no total, um mês
+    /// passado com 30 ou mais, o A vencer e as outras obras como na vitrine. A medida depende dessa forma: meses passados
+    /// cheios, e não um A vencer gigante.
+    @Test(arguments: dias)
+    func obraPesadaComUmGastoPorDia(_ dia: String) throws {
+        var calendario = Calendar(identifier: .gregorian)
+        calendario.timeZone = .current
+        let partes = dia.split(separator: "-").map { Int($0)! }
+        let hoje = try #require(calendario.date(from: DateComponents(year: partes[0], month: partes[1], day: partes[2], hour: 12)))
+        let iso = dataLocalISO(hoje, fuso: .current)
+        let pesada = Estado.de(DadosDeExemplo.vitrinePesada(hoje: hoje)), vitrine = Estado.de(DadosDeExemplo.vitrine(hoje: hoje))
+        let casa = try #require(pesada.obras.first { $0.id == "v1" })
+        let daVitrine = try #require(vitrine.obras.first { $0.id == "v1" })
+        #expect(casa.gastos.count == 566)
+        let novos = casa.gastos.filter { $0.id.hasPrefix("p") }
+        #expect(novos.count == 520)
+        for i in [1, 2, 31, 260, 519, 520] {
+            let dia = try #require(calendario.date(byAdding: .day, value: -i, to: hoje))
+            #expect(novos.first { $0.id == String(format: "p%03d", i) }?.data == dataLocalISO(dia, fuso: .current), "p\(i)")
+        }
+        #expect(Set(novos.map(\.data)).count == 520, "um gasto por dia")
+        #expect(novos.allSatisfy { $0.data < iso }, "nenhum hoje nem no futuro")
+        let lista = listaDaObra(casa, hoje: iso)
+        #expect(lista.aVencer == listaDaObra(daVitrine, hoje: iso).aVencer, "o A vencer da vitrine")
+        #expect((lista.meses.map(\.gastos.count).max() ?? 0) >= 30, "um mês cheio: a célula gigante da List na maior letra")
+        #expect(pesada.obras.filter { $0.id != "v1" } == vitrine.obras.filter { $0.id != "v1" })
+    }
+
     /// Os orçamentos da etapa 3 sobre a vitrine mostram os números do mockup aprovado (parte1.html) em qualquer dia.
     @Test(arguments: dias)
     func orcamentosDoMockupDaEtapa3(_ dia: String) throws {
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" -derivedDataPath <seu dd> 2>&1 | grep -E "error:" | head -2
```
Expected (caminho encurtado):
```
CusttaTests/DadosDeExemploTests.swift:50:47: error: type 'DadosDeExemplo' has no member 'vitrinePesada'
```

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Falsos/MontarFalso.swift`:

```diff
--- a/app-ios/Custta/Falsos/MontarFalso.swift
+++ b/app-ios/Custta/Falsos/MontarFalso.swift
@@ -50,6 +50,7 @@ extension Composicao {
         case "prejuizo": DadosDeExemplo.vitrineComPrejuizo()
         case let v? where ["porTopico", "perto", "passou", "semOrcamento", "muitosTopicos", "topicoLongo"].contains(v): DadosDeExemplo.vitrineDoOrcamento(v)
         case "avista": DadosDeExemplo.vitrineComVencimentoAVista()
+        case "pesada": DadosDeExemplo.vitrinePesada()
         case "analise": DadosDeExemplo.vitrineDaAnalise()
         default: DadosDeExemplo.vitrine()
         }
```

Em `app-ios/Custta/Falsos/VitrineDaObra.swift`:

```diff
--- a/app-ios/Custta/Falsos/VitrineDaObra.swift
+++ b/app-ios/Custta/Falsos/VitrineDaObra.swift
@@ -111,6 +111,27 @@ extension DadosDeExemplo {
         return .objeto(raiz)
     }
 
+    /// A obra pesada (`CUSTTA_DADOS=pesada`): a vitrine com 520 gastos a mais na Casa Alphaville, um por dia para trás a
+    /// partir de ontem, 566 no total. Cada mês passado fica com uns 30 gastos, e o cartão de um mês vira uma célula gigante da
+    /// List na maior letra: é a obra da medida no iPhone, no Instruments, e das sondas da CI.
+    static func vitrinePesada(hoje: Date = .now) -> ValorJSON {
+        guard case .objeto(var raiz) = vitrine(hoje: hoje), case .lista(var obras) = raiz["obras"], case .objeto(var alphaville) = obras[0],
+              case .lista(var gastos) = alphaville["gastos"] else { return vitrine(hoje: hoje) }
+        let topicos = ["matbasicos", "maoobra", "eletrica", "hidraulica", "revest", "pintura", "ferragem", "alvenaria"]
+        var calendario = Calendar(identifier: .gregorian)
+        calendario.timeZone = .current
+        for i in 1...520 {
+            let dia = calendario.date(byAdding: .day, value: -i, to: hoje) ?? hoje
+            gastos.append(.objeto(["id": .texto(String(format: "p%03d", i)), "valor": .numero(Double(100 + (i * 37) % 9000)),
+                                   "topico": .texto(topicos[i % topicos.count]), "descricao": .texto("Compra de material \(i)"),
+                                   "data": .texto(dataLocalISO(dia, fuso: .current)), "pagamento": .texto("pix")]))
+        }
+        alphaville["gastos"] = .lista(gastos)
+        obras[0] = .objeto(alphaville)
+        raiz["obras"] = .lista(obras)
+        return .objeto(raiz)
+    }
+
     /// A vitrine com um vencimento à vista no A pagar (`CUSTTA_DADOS=avista`): a caçamba de entulho no Pix, agendada para
     /// daqui a 2 dias, antes das três parcelas do mockup. O apagar à vista de dentro da folha do A pagar ("Apagar este
     /// gasto?", com o nome e o valor).
```

- [ ] **Step 4: Ver passar**

Run:
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaTests/DadosDeExemploTests 2>&1 | grep -E "passed|failed|SUCCEEDED|FAILED" | tail -3
```
Expected:
```
✔ Suite DadosDeExemploTests passed after 0.092 seconds.
✔ Test run with 5 tests in 1 suite passed after 0.095 seconds.
** TEST EXECUTE SUCCEEDED **
```

- [ ] **Step 5: A forma morde**

Mande os 520 para o futuro (`value: -i` vira `value: i` no `vitrinePesada`), compile, rode o mesmo teste e desfaça:
```bash
xcodebuild test-without-building "${XB[@]}" -derivedDataPath <seu dd> -collect-test-diagnostics never \
  -only-testing:CusttaTests/DadosDeExemploTests 2>&1 | grep -E "✘ Test obraPesada.*failed|Expectation failed" | head -4
```
Expected:
```
✘ Test obraPesadaComUmGastoPorDia(_:) recorded an issue with 1 argument dia → "2026-01-31" at DadosDeExemploTests.swift:58:13: Expectation failed: novos.first { $0.id == String(format: "p%03d", i) }?.data == dataLocalISO(dia, fuso: .current)
✘ Test obraPesadaComUmGastoPorDia(_:) recorded an issue with 1 argument dia → "2026-01-31" at DadosDeExemploTests.swift:61:9: Expectation failed: novos.allSatisfy { $0.data < iso }
✘ Test obraPesadaComUmGastoPorDia(_:) recorded an issue with 1 argument dia → "2026-01-31" at DadosDeExemploTests.swift:63:9: Expectation failed: lista.aVencer == listaDaObra(daVitrine, hoje: iso).aVencer
✘ Test obraPesadaComUmGastoPorDia(_:) recorded an issue with 1 argument dia → "2026-01-31" at DadosDeExemploTests.swift:64:9: Expectation failed: (lista.meses.map(\.gastos.count).max() ?? 0) >= 30
```

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Falsos/MontarFalso.swift app-ios/Custta/Falsos/VitrineDaObra.swift app-ios/CusttaTests/DadosDeExemploTests.swift
git commit -m "test: obra pesada nos falsos para a medida no iPhone" -m "A medida da obra em List no iPhone do Giovani, no Instruments, e a sessão de VoiceOver usam a mesma versão de teste, com a obra pesada: CUSTTA_DADOS=pesada põe 520 gastos a mais na Casa Alphaville, um por dia para trás, 566 no total. Cada mês passado fica com uns 30 gastos, e o cartão de um mês vira uma célula gigante na maior letra. O teste carrega a obra em todo dia da vitrine e prende a forma de que a medida depende: p001 ontem e p520 há 520 dias, um por dia, nenhum hoje nem no futuro, o A vencer igual ao da vitrine e um mês passado com 30 ou mais."
```

### Task 11: O checklist do aparelho da obra em List

O TestFlight da troca sai com o checklist no iPhone, antes do marco 2. A seção nova vai no checklist da etapa 4 e cobre três
grupos:
- **O que tem de ficar igual ao marco 1:** a tela, a rolagem do dedo, o toque no Orçamento e nos Afazeres, o rolar até o gasto
  salvo, o arrastar para apagar e a busca (o teclado como no marco 1; digitar com a lista ainda deslizando; e um gasto de
  teste lançado no site, que a busca acha, apagado no site com a busca aberta).
- **A letra máxima:** a obra de lista curta (o defeito do iOS 26) e a obra mais cheia.
- **O que só o aparelho prova:** o VoiceOver (anel, foco depois de salvar e de apagar, rotor), o Controle por Voz e os ajustes
  do sistema. Os testes ligam esses ajustes pelo app, não pelos Ajustes do iPhone.

**Files:**
- Modify: `docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md`

**Interfaces:**
- Consumes: nada.
- Produces: nada.

- [ ] **Step 1: Escrever a seção**

Em `docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md`:

```diff
--- a/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
+++ b/docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
@@ -46,3 +46,44 @@ A etapa não grava nada novo: os caminhos de gravação são os das etapas 2 e 3
 - [ ] Controle por Voz ("Mostrar nomes"): "Tocar Orçamento", "Tocar A pagar", "Tocar Afazeres" e o nome de um lançamento funcionam; os gastos por tópico não aparecem como botão.
 - [ ] No escuro e no claro, nos vidros Transparente e Fosco (Ajustes → Aparência), os pedaços da barra se distinguem da placa atrás e entre si, e o texto da legenda se lê. Com Reduzir transparência, os blocos ficam sólidos e nada some.
 - [ ] Com Aumentar contraste, a obra inteira continua legível, e o bloco verde não muda de cor.
+
+## A obra em List (o TestFlight da troca, antes do marco 2)
+
+A tela da obra trocou de estrutura por dentro, para não travar no iOS 26. Nada deveria mudar à vista: compare com o build
+do marco 1 nas mesmas obras.
+
+- [ ] A obra abre igual à do marco 1: o título, a cápsula, os blocos, as ações, os Afazeres, os gastos por tópico, a pílula
+  "Lançamentos" e os meses, com os mesmos espaços. O botão "Marcar como pronta" com o ícone junto do texto, no meio.
+- [ ] Rolar com o dedo, devagar e rápido, de cima a baixo e de volta: a lista acompanha o dedo, sem soluço nem salto.
+  Logo depois de abrir, os primeiros arrastos andam como os de depois.
+- [ ] Tocar no Orçamento e nos Afazeres abre como antes, sem um realce cinza no bloco inteiro; ao voltar, nada pisca.
+- [ ] Lançar um gasto pelo +: a lista rola até a linha nova, que acende por 2 s. Editar um gasto do fim de um mês longo:
+  ao salvar, a linha fica à vista e acende, sem a lista ir ao topo do mês e voltar.
+- [ ] Uma compra no cartão em 10x: a lista rola até o "A vencer", que abre, com a 1ª parcela à vista e acesa.
+- [ ] Arrastar um lançamento para a esquerda mostra "Apagar"; tocar em outra linha, no A pagar ou rolar fecha. Tocar fora
+  das linhas e dos botões não fecha mais a linha aberta: no vão entre duas linhas (aceito em 03/11), e também no título,
+  na cápsula, nos blocos de número, no cabeçalho de um mês e nos gastos por tópico. Diga se isso serve.
+- [ ] A lupa: o campo abre embaixo da pílula, a lista rola até ela, e o teclado sobe e desce sem a tela travar. O campo
+  nunca fica escondido sob a barra de cima, e o × dele limpa a busca. Com o teclado aberto, um arrasto curto o deixa
+  aberto, e rolar até o campo ir longe da tela (meia tela além) o fecha, como no marco 1. Digitar logo depois de um
+  arrasto curto, com a lista ainda deslizando: o teclado fica, e a letra entra.
+- [ ] Lance no site um gasto de teste ("teste busca"), busque por ele no iPhone e, com a busca aberta e o teclado em cima,
+  apague esse gasto no site: o campo segue abaixo da barra, e o × limpa a busca.
+
+**Texto Maior no máximo**
+
+- [ ] Numa obra de lista curta, arrastar a lista para cima e para baixo várias vezes: nada trava (era o defeito do iOS 26).
+- [ ] Na obra de mais lançamentos que você tiver, rolar até o mês mais cheio e de volta: diga se alguma parada se nota, e
+  quanto tempo dura. A versão de teste da sessão (Decisões) mede isso no Instruments.
+- [ ] Com a obra rolada até o meio, mudar o Tamanho do Texto pela Central de Controle, para um menor e de volta ao máximo:
+  a obra volta com o mesmo bloco no alto da tela, sem pular para outro mês.
+
+**Acessibilidade**
+
+- [ ] VoiceOver: o anel de cada bloco, da cápsula e do título tem o tamanho de antes (a cápsula não fica mais alta).
+- [ ] VoiceOver, depois de salvar um gasto, o foco vai para a linha nova; depois de apagar, para a linha vizinha, e ele
+  diz "Gasto apagado". Apague a compra toda (uma parcela do A vencer): o foco vai para uma linha que existe na tela.
+- [ ] VoiceOver, o rotor de cabeçalhos passa por todos os meses, também os que estavam fora da tela.
+- [ ] Controle por Voz ("Mostrar nomes"): "Tocar Orçamento", "Tocar A pagar", "Tocar Afazeres" e o nome de um lançamento.
+- [ ] Com Reduzir movimento, Aumentar contraste e Reduzir transparência ligados nos Ajustes do iPhone (não no app), a obra
+  continua como no marco 1.
```

- [ ] **Step 2: Commit**

```bash
git add docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
git commit -m "docs: checklist do aparelho da obra em List" -m "O TestFlight da troca leva o checklist no iPhone, antes do marco 2: o que tem de ficar igual ao marco 1 (a tela, a rolagem do dedo, o toque no Orçamento e nos Afazeres, o rolar até o gasto salvo, o arrastar para apagar e a busca), a obra de lista curta e a mais cheia na letra máxima, e o que só o aparelho prova: o VoiceOver (anel, foco depois de salvar e de apagar, rotor), o Controle por Voz e os ajustes do sistema."
```

---

## Depois do PR

- **O que segue aberto, para o Giovani:**
  - a sessão no iPhone dele, portão do merge: o VoiceOver e a medida da obra pesada no Instruments (limite de ~1 s por
    parada). Acima do limite, a célula gigante volta a ele. A saída conhecida é a linha por gasto, que muda o vidro do mês
    e foi descartada em 03/11;
  - o OK do merge (exceção à regra de um risco por PR) e o do TestFlight;
  - as decisões do item 9, tomadas pelo Orquestrador, para ele saber (Decisões);
  - o toque que não fecha mais a linha aberta: o aceite de 03/11 foi do vão, e o alcance inteiro (título, cápsula, blocos
    de número, cabeçalho do mês, gastos por tópico) está no checklist do aparelho.
- **Menores que ficam para depois** (achados da revisão às cegas de 03/11, sem risco para o merge):
  - o A pagar da vitrine é uma cópia do rótulo do bloco: extrair `RotuloDoAPagar` e usá-lo nos dois, para a auditoria
    olhar o bloco da obra;
  - a auditoria na maior letra da v1 rolada (as ações, os afazeres, a pílula, o A vencer): cada peça no alto da vitrine por
    argumento, como o `-custta.vitrineAPagar`;
  - outra mudança de dados com a busca aberta (outro aparelho apaga um gasto) não passa pela ponte; se o salto de 160 pt
    aparecer fora da VM, o `segurarOAlto()` vale também ali;
  - o arrasto que solta a ponte durante a espera da letra não tem teste: no Mac, a lista assenta antes de o arrasto
    sintetizado começar;
  - o voltar sob a folha: o laudo deixa de fora o quadro do voltar da tela de baixo também quando a folha o cobre
    (`filter(\.exists)`). Ali hoje só há o × do sistema, sem texto; medir esse canto pede o `isHittable` e o laudo das
    cenas com folha, onde o vidro do × assenta como o do voltar (1ª revisão às cegas).
- **Peças fora da obra continuam em ScrollView:** a tela Orçamento, as folhas de origem (A pagar, detalhe do tópico) e
  Ajustes. Elas não travaram no iOS 26; a regra das estruturas (memória `lazyvstack-aninhada-trava-no-ios-26`) vale se
  alguma delas crescer.
- **O protótipo e as sondas** ficam nos ramos `proto/` (`proto/etapa4-obra-em-list*`, `proto/obra-em-list-*`) e nas pastas
  `prumo-list/`, `prumo-list-linha/` e `prumo-plano-obra-list/`. Nada disso vai para a `main`.

# Análise (etapa 4 do app nativo), marco 1 — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> Neste time, o Forja implementa uma tarefa por vez e o Lupa revisa cada uma antes da próxima. Nas tarefas de tela, o Verniz confere o simulador lado a lado com o mockup aprovado. Ninguém faz commit, push ou PR sem o Orquestrador pedir; quando ele pedir, valem os comandos de commit de cada tarefa.

**Goal:** Entregar o marco 1 da etapa 4, que termina num build no TestFlight com o OK do Giovani. São cinco PRs:
- **0, no site:** as regras da análise que hoje só vivem no `app.js` sobem para o `calc.js`, com os dois alinhamentos aprovados;
- **0b, no núcleo:** as regras novas do app e a paginação do PDF;
- **1a, 1b e 1c, no app:** a identidade nova em três passos (os tokens globais, as peças e a obra reescrita), com a costura das telas da análise.

**Architecture:** O que o app copia do site entra nos vetores, com o leitor em Swift no mesmo commit. As regras que só o app tem moram no `CusttaNucleo`, com teste próprio, e ficam sem uso na `main` até as telas dos marcos 2 e 3.

A identidade nova chega ao app em três PRs, cada um com um risco:
1. **Os tokens globais (1a)** valem no app inteiro. O laudo inteiro, comparado palavra por palavra com o do commit anterior, prova o que mudou nas telas das etapas 1 a 3.
2. **As peças (1b)** nascem sem tela, provadas na vitrine e em teste.
3. **A obra (1c)** é reescrita em blocos, e a costura das telas da análise (`Custta/Analise/`) entra sem porta, só pelo `CUSTTA_ABRIR` de Debug.

**Tech Stack:** SwiftUI no iOS 26 (Swift 6 estrito; Xcode 26.6 na CI), Swift Testing, XCTest e XCUITest, e o pacote `CusttaNucleo`. No site, Node (`node:test`) e Playwright.

**Spec:** [`docs/specs/2026-10-29-app-nativo-etapa4-design.md`](../specs/2026-10-29-app-nativo-etapa4-design.md).
- As seções "PRs" e "Decisões do conselho" dão o corte, os portões e os marcos, com as decisões do Giovani de 29/10.
- Inventário do site: [`2026-10-29-app-nativo-etapa4-inventario.md`](2026-10-29-app-nativo-etapa4-inventario.md).
- Mockup aprovado: `~/Documents/custta-mockups/nativo/etapa4/`. Abra no Chrome; o `LEIA-ME.md` resume as duas partes.

**Só o marco 1.** Os marcos 2 (4a, 2a, 2b) e 3 (3a, 3b, 4b) ganham plano quando chegarem as referências que o Giovani vai procurar:
- a 5, a 6 e a 8 mudam o 3b e o 4a;
- a 1, a 2 e a 7 podem mexer no gesto dos meses, no anel e no PDF; a 2 (anel com muitas categorias) mexe também nos pedaços do 0b e na barra empilhada do 1c.

O resultado das duas sondas do PDF na CI entra no plano do marco 3.

**Como este plano foi escrito.** O código de cada tarefa saiu de fatias: um commit por tarefa, num clone da `origin/main` `767ebe9`, cada uma conferida antes do commit seguinte:
- **site e núcleo:** os testes da tarefa sobre o commit anterior (o "ver falhar" deste texto é a saída real) e, depois, a tarefa inteira com `node scripts/vetores-calc.mjs`, `npm run test:unit`, `swift test` e a suíte de browser que ela toca;
- **app:** a compilação sem aviso novo e os testes da tarefa no simulador;
- **fim de cada PR:** o laudo inteiro de leitura no Pro Max.

O texto de cada tarefa foi gerado das fatias. Arquivo novo entra inteiro, arquivo alterado entra em diff, e arquivo gerado só pelo comando. Depois, o plano foi aplicado numa cópia limpa da `origin/main`, e a árvore de cada tarefa saiu igual, byte a byte, à da fatia.

## Global Constraints

- **Plataforma:** iOS 26.0 mínimo, iPhone. Nada que só exista no SDK do iOS 27. A CI compila com o Xcode 26.6 (Swift 6.3.3); o Mac do time tem o 27 e não tem o runtime do 26, então o que só o iOS 26 prova, a CI prova.
- **Swift:** 6, com concorrência estrita e nenhum aviso de compilador novo.
- **Dependências:** nenhuma nova, no app ou no site. Nada de runtime novo no browser, e a CSP do site fica intacta. Os gráficos não usam o Swift Charts (decisão do Giovani, 29/10).
- **Língua:** português no código, nos identificadores, nos comentários e na interface.
- **Cores e ícones:**
  - cores só por tokens (`scripts/cores-app-ios.mjs`, conferido por `tests/app-ios.test.cjs`);
  - ícones do `icons.js` pelo `scripts/icones-app-ios.mjs`;
  - SF Symbols só onde a etapa já usa e onde a tarefa disser.
- **Identidade nova (brief 2):** números em SF Mono, com o R$ e os centavos menores na linha do número, nunca abaixo de 11 pt.
- **Vidro:**
  - nunca vidro dentro de vidro;
  - um bloco sólido por tela, como o spec diz;
  - dentro das folhas, tudo sólido.
- **Estado:** o formato não ganha chave nova, e as `firestore.rules` não mudam nesta etapa.
- **Regras:** o app mostra o que o site mostraria. A regra que mora no `calc.js` entra nos vetores com o leitor no núcleo, no mesmo commit; a regra que só o app tem mora no núcleo, com teste próprio.
- **Textos:** os do site, menos os que o mockup aprovado mudou (o spec lista).
- **Ajustes de acessibilidade:** a letra máxima (AX5), o Negrito, o Aumentar contraste, o Reduzir transparência, o Fosco e o Reduzir movimento valem em toda tela e animação nova. `lineLimit` e `minimumScaleFactor` só nos componentes da lista fixa da guarda.
- **Site:** o PR do site só muda arquivos que já existem, mais as suítes novas que a tarefa disser, e sobe o `CACHE` do `sw.js` uma vez, no fim.
- **Commits:** autor só `Giovani Stuchi <stuchigiovani@gmail.com>`, sem `Co-Authored-By` e sem rodapé. Título conventional em português com acento, corpo em prosa, um commit por tarefa, branch e PR, nunca direto na `main`.
- **Simuladores:** um por agente (`CUSTTA_SIMULADOR=<udid>`). Os testes de tela rodam com `-collect-test-diagnostics never`. Sem a variável, o app de Debug fala com o Firebase de produção: os testes de tela passam pelo `abrirApp` (falsos).
- **Laudo:** o inteiro de leitura roda no Pro Max no fim de cada PR do app (1a, 1b e 1c); o 0 e o 0b não têm tela. Nos PRs que mudam peça compartilhada (1a, 1b e 1c), ele é comparado palavra por palavra com o do commit anterior (spec, "A comparação").

## Decisões

As do Giovani estão no spec, nas seções "Decisões de desenho", "PRs" e "Decisões do conselho". Aqui ficam as que valem para o marco 1 e as que as fatias trouxeram. As marcadas **a confirmar** vão a ele na revisão do PR em que entram. Até lá, as fatias seguem o spec ou a recomendação.

| Decisão | Escolha | Por quê |
| --- | --- | --- |
| Corte do marco 1 | 0, 0b, 1a, 1b e 1c, nessa ordem; o 1c fecha o marco | Decisões do Giovani de 29/10: corte por risco, o PR 1 em três e o TestFlight por marco |
| Merge | Automático, com a CI verde, a revisão aprovada e nenhum rerun no iOS 26. O 1a e o TestFlight esperam o OK dele | Decisão 3 dele, 29/10 |
| Os dois alinhamentos do site | Entram no PR 0: os meses de 0 a 120 (Tarefa 5) e o preço que segue a obra (Tarefa 6) | Confirmação 4 dele, 29/10 |
| O preço do simulador na obra sem venda estimada (**decidido pelo Giovani em 30/10: campo vazio**) | O campo fica vazio ("Digite o preço de venda pra ver a conta.") | É a leitura do plano para "o preço acompanha a venda estimada". Hoje, a obra herda o preço da anterior. Manter o anterior é uma linha na cola, sem mexer na regra. O PR 0 vai ao ar no merge; por isso a pergunta foi a ele antes do PR |
| Soma por tópico no site | `Map`, não objeto (Tarefas 1 e 2) | O objeto passava o tópico de id numérico à frente no empate, e o tópico `"__proto__"` derrubava o Relatório. O `Map` faz o empate do spec, que é o que a cópia em Swift já fazia. A tela só muda nesses dois casos, que ela não cria |
| O `confere` do núcleo | Reprova quando só um lado não é finito (1ª tarefa do 0b) | A tolerância `.continua` deixava passar infinito contra qualquer número. É achado do PR 0 e foi provado no multiplicador da TIR com taxa zero |
| O tópico fixo "Outros" no anel e na barra (**decidido pelo Giovani em 30/10: o "Outros" fixo vai sempre para o cinza**; entra no 0b-2) | O tópico fixo "Outros" (id `outros`) vai sempre para o pedaço cinza, por último: com até 6 tópicos comuns, sozinho e com o próprio nome; com 7 ou mais, junto do resto, em "Outros · N tópicos" (N conta o fixo). Os 6 coloridos são os 6 maiores sem ele. Obra com todos os gastos em "Outros" fica com a barra toda cinza | Com 8 tópicos ou mais, o "Outros" da pessoa pode sair colorido ao lado do "Outros · N tópicos" cinza. A troca muda a regra dos 6 maiores e é pequena no núcleo |
| A parte com 1 casa no Relatório (**a confirmar antes do 3a**) | "<0,1%" abaixo de 0,1% | O spec diz só "1 casa", e o texto não está no mockup. Segue o mesmo princípio do "<1%" |
| Média, maior e meses; o mês a vencer | Contam desde o 1º gasto. O mês a vencer não depende de este mês estar na série | Assim manda o spec. O mockup contava só os 24 meses à vista |
| O halo do título mono da obra (PR 1c; **decidido pelo Giovani em 30/10: 20%**) | 20% em todo tamanho | Pela regra dele (o menor passo que fecha 4,5:1 no Pro Max, decisão de 10/10), seria 10%. No Pro Max, "Alphaville" fica em 3,92:1 sem halo, 4,61 com 10% (pior pixel 4,50) e 5,41 com 20%. Mas o iOS 26 da CI mede o nome da obra 0,4 abaixo do Pro Max, e o laudo é portão lá: com 10%, ele reprovaria. Se a CI passar folgada com 20%, o 10% pode ser tentado num PR à parte |
| O "<1%" na folha do detalhe | Entra no 1c, que reescreve a obra, de onde a folha abre | Confirmação 7. No 0b, mexeria em tela da etapa 3 num PR sem tela |
| O "<1%" na lista da tela Orçamento (**decidido pelo Giovani em 30/10: muda junto**) | Se a função da folha também serve à lista, a lista muda junto | Assim o número não muda ao abrir a folha. Mas a tela Orçamento está fora do escopo da etapa |
| O `gastoPorTopico` em Swift | Perde o `hoje:` e o `taxaMensal:` no 1c | Os dois não mudam o resultado. Tirá-los no PR 0 mexeria no app |
| A linha de lançamento da obra sem o ícone do pagamento (PR 1b, na obra a partir do 1c) | Segue o mockup aprovado: "Pix" e "Cartão" por extenso, sem o raio e o cartão do sistema que a etapa 3 põe antes deles. As folhas (A pagar e detalhe do tópico) ficam com a linha da etapa 3 | O spec diz só "o valor em mono e o ícone pequeno na 2ª linha"; o mockup (`gastoLinha`, parte1.js:248-252) não tem o ícone. Se o Giovani quiser o ícone de volta, é o parâmetro `iconeDoPagamento` da linha |
| A CI do marco 1 (decisão do Orquestrador em 29/10, como rotina, informada ao Giovani; muda o portão da tabela para o 0 e o 0b) | Igual à de hoje: o 0 e o 0b rodam os 10 jobs, uns 90 min, e não só os do núcleo. O filtro por superfície e os jobs da etapa 4 entram no 4a | É recomendação deste plano. O spec pede o filtro num PR que já roda tudo, antes do 2a. Pôr o filtro no 0 juntaria um risco de CI ao PR do site, e um PR só de CI seria o 12º. O custo: o 0 e o 0b esperam mais, e um rerun no iOS 26 tira o PR do merge automático |
| O tempo dos jobs da CI no marco 1 (pedido do Orquestrador em 29/10, depois do #93; a escolha é decisão dele, informada ao Giovani) | Nada muda no `app`: o teto continua em 90 min. O teto do `laudo-etapa3` sobe de 60 para 75 min no PR 0b, numa linha dita no corpo do PR (Tarefa 14; decisão do Orquestrador em 29/10). O `app` só é partido por classe, como foi o `app-etapa3`, se passar de ~140 testes de tela ou de 70 min numa VM normal | O teto do `app` é 90, não 60 (`app-ios.yml`, linha 81). Os 60,1 min da 1ª rodada do #93 reprovaram por um teste instável (`EntradaUITests.testMensagensDoFormulario`, espera de 5 s), não pelo teto. Nos 10 últimos runs com os mesmos 105 testes de tela, o `app` levou de 46,9 a 67,5 min (mediana 58,4). O que varia é a VM, de 22 a 31 s por teste, e os mesmos 101 testes já levaram de 32,3 a 48,9 min. Desde 18/10, o job ganhou só 4 testes de tela (Ajustes, 24/10) e 51 de unidade (+40 s). O marco 1 põe uns 14 testes de tela no `app`: 6 da vitrine e da cápsula, no 1a e no 1b, e uns 8 da obra e da costura, no 1c. A conta dá ~65 min numa VM normal e ~75 na mais lenta já vista, ainda com 15 de folga. Os testes de tela da etapa 4 vão para jobs próprios no 4a, então o `app` para de crescer. O job mais perto do teto é o `laudo-etapa3`: mediana 46, máximo 57,3 de 60, e o marco 1 não lhe acrescenta nada. Partir o `app` agora custaria mais um job de macOS, com ~10 min de preparo, e não mudaria o tempo do run, que depende das 5 vagas (~360 min de job por run) |

## Como entregar

- **Ordem: 0, 0b, 1a, 1b e 1c.** Cada PR nasce num worktree novo, a partir da `origin/main` atualizada, ou empilhado sobre o PR que espera o OK do Giovani. No máximo 2 PRs esperam ao mesmo tempo (decisão 3 dele, 29/10).
- **Uma tarefa por vez.** O Forja segue os passos e faz o commit da tarefa; o Lupa revisa antes da próxima: o diff, os testes da tarefa e uma mutação nas linhas que ela escreve. Achado menor vai para o fim do PR, num commit só.
- **Merge (decisão 3 do Giovani, 29/10).**
  - Com a CI toda verde, a revisão aprovada e nenhum rerun no iOS 26, o Orquestrador mescla, até 5 seguidos. No 5º, manda ao Giovani o resumo com os prints lado a lado (simulador × mockup) de cada PR.
  - Sempre esperam o OK dele:
    - o **1a**, com os prints antes × depois das telas principais no claro e no escuro (tarefa do laudo comparado do 1a);
    - o **1c**, que fecha o marco e refaz a tela da obra, antes do merge e da tag, com os prints lado a lado dos desvios do mockup que ele registra;
    - o **TestFlight do fecho do marco**.
- **O PR 0 muda o site no merge:** os dois alinhamentos vão ao ar em custta.com.br. A prévia da Vercel é conferida nos dois viewports antes do merge, como no ponto de controle do PR 0. As quatro respostas que o PR 0 e o 1c esperavam foram dadas pelo Giovani em 30/10 (Decisões): o preço vazio na obra sem venda estimada, o tópico fixo "Outros" sempre no pedaço cinza, o halo de 20% e o "<1%" da tela Orçamento junto com a folha. Nenhum PR do marco 1 espera mais uma resposta; a pendência "a confirmar" que sobra (o "<0,1%" do Relatório) é do marco 3 e tem prazo na própria linha.
- **CI no marco 1: igual à de hoje.**
  - Todo PR que mexe no app, no núcleo ou nos vetores roda os 10 jobs do `app-ios.yml`, de 79 a 96 min de relógio, porque a conta tem 5 vagas de macOS.
  - A única mudança na CI do marco 1 é o teto do `laudo-etapa3`, que sobe de 60 para 75 min no 0b (Decisões).
  - O filtro por superfície, a guarda dele e os jobs da etapa 4 entram no 4a, o primeiro PR do marco 2, que já roda tudo (spec, "Onde moram o filtro e os jobs"). Antes do 2a, que é o primeiro PR que só traz tela nova.
  - O laudo inteiro no Pro Max roda no Mac, no fim de cada PR do app (1a, 1b e 1c).
  - O tempo do job `app` vai no texto de cada PR do app (1a, 1b e 1c): os minutos e os testes de tela do run. Fica de olho se ele passar de 70 min numa VM normal, ou seja, com menos de 26 s por teste (Decisões).
- **Fecho do marco 1:**
  - o merge do 1c leva a tag `etapa4-marco-1`;
  - o TestFlight sai da tag, com o OK do Giovani, e o checklist do aparelho do marco 1 vai junto;
  - um conserto urgente sai da tag, não da `main`;
  - o 1º PR do marco 2 (o 4a) pode ser feito durante o teste dele no iPhone, mas só é mesclado depois do OK dele no build.

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

---

## PR 0 (site): as regras da análise nos vetores e o "Vale a pena?" alinhado ao app

Um PR só do site, em sete commits, na forma do PR 0 das etapas 2 e 3. Ele tira do `app.js` as seis regras da análise que o app nativo precisa copiar: o gasto por tópico do donut (Tarefa 1), os grupos, o fim, a linha da correção e a soma da seleção do Relatório (Tarefas 2 a 4) e o "Vale a pena?" (Tarefas 5 e 6). Cada regra entra nos vetores com a cópia e o leitor em Swift no mesmo commit, porque o núcleo barra grupo de vetor sem leitor. O site mostra o mesmo, salvo os dois alinhamentos que o Giovani aprovou em 29/10 (confirmação 4): os meses de 0 a 120 na conta (Tarefa 5) e o preço que acompanha a venda estimada da obra escolhida enquanto a pessoa não digitou (Tarefa 6), cada um com teste de browser que cai com o alinhamento desfeito. Uma subida só do `CACHE`, no fim (Tarefa 7). O risco é baixo: são regras puras, conferidas por vetores, e a cola do `app.js` é presa por uma suíte nova de browser (`tests/browser/analise.cjs`), com o dia fixo pelo relógio do Playwright. Na `main`, nada fica escondido no site: os dois alinhamentos vão ao ar no merge. No app, as regras novas ficam no núcleo, sem tela, até o PR 3a (Relatório) e o 4a ("Vale a pena?"); o `gastoPorTopico` já é usado pela tela Orçamento da etapa 3 e não muda. Na CI, o PR roda os 10 jobs do `app-ios.yml`, de 79 a 96 min de relógio, como hoje roda todo PR que toca o `calc.js`, o núcleo ou os vetores: o nível "núcleo" que a tabela do spec dá a ele depende do filtro por superfície, que fica para o 4a (decisão do Orquestrador; ver as Decisões). Um rerun no iOS 26, mesmo num job de tela que este PR não toca, tira o PR do merge automático. O PR abre o marco 1 deste plano (na tabela do spec, o 0 e o 0b vêm antes do 1a, sem marco). São 490 linhas de produção (acréscimos + remoções em `calc.js`, `app.js`, `sw.js` e no núcleo, pelo `git diff --numstat`; 514 somando as tarefas, que reescrevem linhas umas das outras), abaixo dos ~600–850 da tabela. Os vetores vão de 100 grupos e 1015 casos para 110 grupos e 1107 casos; o `swift test` do núcleo, de 233 testes em 37 suítes para 243 em 39; o `npm run test:unit` fica em 407.

**Branch:** `feat/regras-da-analise-nos-vetores`. **Título:** `feat: regras da análise nos vetores e o simulador alinhado ao app`.

**Como foi provado.** Cada fatia foi conferida sozinha: os testes da tarefa sobre o commit anterior (o "ver falhar" de cada tarefa é a saída real), a tarefa inteira (`node scripts/vetores-calc.mjs`, `npm run test:unit`, `swift test` do núcleo e as suítes de browser que ela toca), mutação nas regras do `calc.js` (59 de 59 mortas pelo `vetores.test.mjs`), nas cópias em Swift (45 de 45 pelos leitores) e na cola do `app.js` (41 de 41 pela `analise.cjs`), com casos novos onde um mutante vivia (a parcela a vencer na base do %, o 0,075% que separa o padrão pt-BR do `toFixed`, a obra pronta com a venda guardada, o lucro zero e o multiplicador sem taxa). No fim, o `npm run test:browser` inteiro, com os emuladores: verde em 3 min 25 s.

**A porta 8123 é uma só.** As suítes de browser abrem o site no `servidor.cjs`, que escuta sempre na 8123. Cada passo que roda uma suíte sobe o servidor do próprio worktree, confere pelo `lsof` que a porta é dele e o derruba no fim; o `npm run test:browser` da Tarefa 7 sobe o seu, com a CSP aberta para os emuladores, e precisa da porta livre. O Forja e o Lupa não rodam suíte de browser ao mesmo tempo: com outro servidor no ar, o segundo cai em `EADDRINUSE`, e a suíte testa a árvore do outro worktree.

### Mapa de arquivos do PR 0

- `calc.js`: `gastoPorTopico` (Tarefa 1); `relatorioObra` (2); `fimRelatorio`, `linhaCorrecao` e o auxiliar interno `dataCurta` (3); `somaSelecao` (4); `MESES_SIMULADOR`, `contaSimulador` e `textosSimulador` (5); `obrasSimulador` e `precoInicialSimulador` (6).
- `app.js`: a cola de cada tarefa, que passa a chamar as regras pelo `OBRA_CALC`: o donut e a legenda da obra e dos Gráficos, sem o `byTopico` (1); o `renderRelatorio` (2 a 4); o `simulaCompute` (5 e 6) e o `renderSimula` (6).
- `sw.js`: o `CACHE`, de `obras-v71` para `obras-v72` (7).
- `scripts/vetores-calc.mjs` e `tests/vetores/calc.json` (gerado): os casos de cada regra (1 a 6).
- Núcleo: `DentroDaObra.swift` (1, só o comentário do `gastoPorTopico`), `Relatorio.swift` (novo, 2 a 4) e `Simulador.swift` (novo, 5 e 6), com os leitores em `DentroDaObraTests.swift` (1), `RelatorioTests.swift` (novo, 2 a 4) e `SimuladorTests.swift` (novo, 5 e 6).
- Browser: `tests/browser/analise.cjs` (nova, 1 a 6), posta no `rodar.cjs` (1).

### Ponto de controle do fim do PR

Na prévia da Vercel, nos dois viewports (393 e 1280), comparada com a produção:
- numa obra com 8 tópicos ou mais, a legenda do donut (7, do maior para o menor) e a dos Gráficos (todos, na ordem do anel);
- o Relatório de uma obra com venda estimada, de uma vendida e de uma sem as duas: a tabela, o fim com a cor pelo sinal, a linha da correção e a soma de dois gastos marcados;
- no "Vale a pena?": trocar de obra sem digitar o preço (o preço segue a venda estimada e fica vazio na obra sem estimada; na produção, a segunda obra herda o preço da primeira), digitar um preço e trocar de novo (fica o digitado), e digitar 200 meses (a prévia diz "vendendo daqui a 120 meses"; a produção, "200 meses");
- na CI, os 10 jobs do `app-ios.yml` verdes, sem rerun.

O Forja começa o PR 0b quando este entra em revisão, empilhado neste ramo (ver o PR 0b, "De onde o ramo nasce").

### Achados que mudam o spec ou uma decisão

1. **Soma por tópico em `Map`, não em objeto (Tarefas 1 e 2).** No objeto do site, um tópico de id numérico ("12") passava à frente no empate do donut e do Relatório, e o tópico `"__proto__"` sumia do donut e derrubava o Relatório (`push` em `Object.prototype`). O `Map` faz o que o spec descreve ("no empate, a ordem em que o tópico aparece nos gastos") e o que a cópia em Swift já fazia. Nenhum tópico do site tem id assim (os fixos são palavras, os próprios são `c_` + uid), então nada muda para quem usa. **Recomendação:** aceitar e registrar no spec, na lista do que o site não muda, como "caso inalcançável".
2. **O `confere` do núcleo deixa passar infinito contra um número (`Vetores.swift`, tolerância `.continua`).** `abs(inf − 0) ≤ 1e-9 × inf` dá verdadeiro, então um multiplicador infinito (TIR ÷ taxa zero) passava contra o 0 do site. A Tarefa 5 contorna no leitor (`isFinite`). **Recomendação:** um menor fora deste PR (entrou no 0b, Tarefa 8): o `confere` reprova quando só um lado não é finito, rodando o `swift test` inteiro para ver que nenhum leitor dependia disso.
3. **A descrição vazia que vira o nome do tópico fica na cola (Tarefa 2).** O spec lista a regra em "Relatório" ("descrição vazia vira o nome do tópico"), mas a tabela do PR 0 cita só app.js:1164-1178 e 1188, e o nome depende do mapa de tópicos da tela. Sem vetor, o app precisa repetir a troca. **Recomendação:** o plano do PR 3a leva um teste de unidade da linha sem descrição (com tópico próprio e tópico apagado, que cai no id).
4. **O preço vazio na obra sem estimada (Tarefa 6).** "O preço acompanha a venda estimada da obra escolhida enquanto a pessoa não digitou" foi lido como: a obra sem estimada deixa o campo vazio ("Digite o preço de venda pra ver a conta."), em vez de manter o preço da obra anterior. **Decidido pelo Giovani em 30/10: o campo fica vazio**, como a fatia faz (Decisões).
5. **Os sinais da tabela do simulador viram dado da regra (Tarefa 5).** O `textosSimulador` devolve, por linha, `sinalBruto` e `sinalCorrigido` (`'positivo'`, `'negativo'` ou `null`) e o `destaque` do lucro; o site os traduz em `pos`, `neg` e `rep-total`, e o app usa o negativo em âmbar. A marcação muda num detalhe: a célula colorida sem valor perde o `class=""` vazio, sem efeito na tela.
6. **O `gastoPorTopico` em Swift continua com `hoje:` e `taxaMensal:`, que não mudam o resultado (Tarefa 1).** Tirá-los mexeria no `OrcamentoView` e nos testes do app, e o PR passaria a mudar o app (laudo e comparação). **Recomendação:** limpar no PR 1c, que já mexe na obra.
7. **Linhas abaixo da estimativa:** 490 contra ~600–850. O PR não precisa de corte.

### Task 1: Gasto por tópico do donut no calc.js

A soma bruta por tópico e a ordem do donut saem do `app.js`, onde estavam repetidas na obra (app.js:412-414) e nos Gráficos (`byTopico`, app.js:1060-1064), para o `calc.js` (`gastoPorTopico`), com o "% da obra" da legenda (app.js:545 e 1052). A regra: o bruto de todos os gastos, com as parcelas a vencer; do maior para o menor; no empate, o tópico que aparece primeiro nos gastos (o `sort` é estável); o `pct` é `Math.round(bruto / total × 100)`, o mesmo do `resumoTopico`, e 0 na obra sem gasto (ou com todos os gastos de valor zero). A soma usa um `Map`: no objeto do site, um tópico de id numérico ("12") passaria à frente no empate e o `"__proto__"` sumiria; nenhum tópico do site tem id assim (os fixos são palavras e os próprios, `c_` + uid), então o site não muda. O núcleo já tinha a cópia (`gastoPorTopico`, DentroDaObra.swift:62, da etapa 3), sem vetor: ganha o leitor, e só o comentário muda. A tarefa abre a suíte de browser da etapa, `tests/browser/analise.cjs`, posta no `rodar.cjs`.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (novo): `tests/browser/analise.cjs`
- Test (alterar): `tests/browser/rodar.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `totalBruto` do `calc.js`; no núcleo, `gastoPorTopico(_:hoje:taxaMensal:)` e `GastoDoTopico` (já existem).
- Produces: `OBRA_CALC.gastoPorTopico(obra)` → `[{id, bruto, pct}]`, na ordem do donut. No `app.js`, `drawDonutObra(topicos, total)` e `donutComLegendaHtml(topicos, total, size)` recebem essa lista; o `byTopico` sai.

- [ ] **Step 1: Escrever os testes**

Os vetores cobrem o empate pela ordem dos gastos (a ordem natural pelo nome daria outra), o meio ponto, o tópico abaixo de 0,5%, o id numérico, os gastos de valor zero e a parcela a vencer na base do %. O leitor em Swift compara exato: o bruto soma na ordem do documento, como o site. A suíte nova não muda de resultado com a tarefa: ela prende a cola que a tarefa reescreve (a legenda da obra para em 7, a dos Gráficos traz todos, na mesma ordem do anel).

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift
@@ -88,6 +88,16 @@ struct DentroDaObraTests {
         #expect(dicaDoModoTotal == "Para comparar tópico a tópico, toque no lápis e escolha \"Por tópico\".")
     }
 
+    @Test func gastoPorTopicoComoOSite() {
+        // calc.js gastoPorTopico (o donut e a legenda da obra e dos Gráficos). Exato: o bruto soma os gastos na ordem do
+        // documento, como o site, e o "% da obra" é inteiro.
+        for c in Vetores.casos("calc.gastoPorTopico") {
+            let linhas = gastoPorTopico(c.args[0].obra, hoje: Self.hoje, taxaMensal: 1)
+            confere(.lista(linhas.map { .objeto(["id": .texto($0.id), "bruto": .numero($0.bruto), "pct": .numero($0.pct)]) }),
+                    c.saida, .exata, c.caso)
+        }
+    }
+
     @Test func gastoPorTopicoNoEmpateSegueAOrdemDosGastos() {
         // A legenda do donut do site: o byTop nasce na ordem dos gastos e o sort do JavaScript é estável, então no empate do
         // bruto vem o tópico que aparece primeiro na lista (fundação, pintura, estrutura): não o de id menor nem o de id maior,
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -201,6 +201,18 @@ resumoTop('meio ponto arredonda para cima, como o donut', { id: 'r', dataInicio:
 resumoTop('a base do % conta a parcela a vencer de outro tópico', { id: 'v', dataInicio: '2026-01-01', gastos: [
   { id: 'v1', valor: 50, topico: 'pintura', descricao: '', data: '2026-01-01', pagamento: 'pix' },
   { id: 'v2', valor: 50, topico: 'eletrica', descricao: '', data: '2026-12-01', pagamento: 'pix' }] }, 'pintura', HOJE, 1);
+/* Gasto por tópico (app.js: o donut e a legenda da obra e dos Gráficos): a ordem e o "% da obra" de cada tópico. */
+const gastoDe = (id, topico, valor, data = '2026-01-01', descricao = '') => ({ id, valor, topico, descricao, data, pagamento: 'pix' });
+const obraDe = (id, gastos, campos = {}) => ({ id, nome: 'Obra', dataInicio: '2026-01-01', fase: 'construcao', gastos, ...campos });
+const porTopico = calc('gastoPorTopico');
+for(const o of BLOB.obras) porTopico(o.nome, o);
+porTopico('empate: o tópico que aparece primeiro, não o de nome menor nem o do último gasto',
+  obraDe('e', [gastoDe('e1', 'pintura', 60), gastoDe('e2', 'alvenaria', 100), gastoDe('e3', 'pintura', 40)]));
+porTopico('meio ponto arredonda para cima: 12,5% vai a 13 e 87,5% a 88', obraDe('m', [gastoDe('m1', 'pintura', 1), gastoDe('m2', 'eletrica', 7)]));
+porTopico('tópico pequeno fica com 0%', obraDe('p', [gastoDe('p1', 'terreno', 1000), gastoDe('p2', 'pintura', 4)]));
+porTopico('tópico de id numérico fica na ordem dos gastos', obraDe('n', [gastoDe('n1', 'pintura', 50), gastoDe('n2', '12', 50), gastoDe('n3', '3', 50)]));
+porTopico('gastos de valor zero: % zero', obraDe('z', [gastoDe('z1', 'pintura', 0), gastoDe('z2', 'eletrica', 0)]));
+porTopico('a base do % conta a parcela a vencer', obraDe('v', [gastoDe('v1', 'pintura', 50), gastoDe('v2', 'eletrica', 50, '2026-12-01')]));
 const lucro = calc('lucroVenda');
 for(const o of BLOB.obras) lucro(o.nome, o, 1);
 lucro('gasto depois da venda entra pelo valor', O2, 2);
```

Criar `tests/browser/analise.cjs`:

```js
/* Análise com dados sintéticos: o donut e a legenda da obra e dos Gráficos. Sem contas nem rede.
   Precisa de `node tests/browser/servidor.cjs` no ar (porta 8123). */
const assert=require('node:assert/strict');
const {chromium}=require('playwright');

const g=(id,topico,valor,data,descricao='')=>({id,valor,topico,descricao,data,pagamento:'pix'});
/* Nove tópicos: a legenda da obra mostra 7, a dos Gráficos todos. Pintura e Alvenaria empatam em R$ 10 mil (a Pintura
   aparece primeiro nos gastos) e Outros fica abaixo de 0,5%. */
const CASA={id:'a',nome:'Casa Alphaville',dataInicio:'2025-11-10',fase:'construcao',valorEstimadoVenda:450000,areaM2:120,gastos:[
  g('a1','pintura',6000,'2026-02-01','Tinta acrílica'),g('a2','alvenaria',10000,'2026-01-15','Blocos'),
  g('a3','pintura',2500,'2026-01-15'),g('a4','terreno',150000,'2025-12-01','Terreno'),g('a5','eletrica',5400.5,'2026-02-10','Fios'),
  g('a6','hidraulica',3000,'2026-02-10','Tubos'),g('a7','fundacao',20000,'2026-01-20','Sapatas'),
  g('a8','telhado',2500,'2026-12-03','Telhas'),g('a9','projeto',1200,'2026-01-05','Alvará'),g('a10','outros',300,'2026-03-10','Limpeza'),
  g('a11','pintura',1500,'2026-01-15','Massa corrida')]};

(async()=>{
  const browser=await chromium.launch();
  try{
    const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:393,height:852}});
    await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
    await ctx.route('https://**/*',r=>r.abort());
    await ctx.addInitScript(()=>{
      sessionStorage.setItem('splashVista','1');window.errosAnalise=[];
      addEventListener('error',e=>errosAnalise.push(e.message));
      addEventListener('securitypolicyviolation',e=>errosAnalise.push(e.violatedDirective));
      window.CLOUD={user:()=>({uid:'teste'}),onAuth:cb=>cb({uid:'teste'}),watchDados:()=>()=>{},saveDados:()=>Promise.resolve(),estado:()=>'ocioso'};
    });
    const page=await ctx.newPage();
    await page.goto('http://localhost:8123');
    await page.evaluate(obras=>{document.getElementById('auth')?.classList.add('hidden');document.body.classList.remove('locked');
      db=normaliza({obras,config:{taxaMensal:1,topicosCustom:[]}});
      dadosCarregados=true;renderAll();openObra('a');},[CASA]);
    const texto=s=>s.replace(/\s+/g,' ').trim();

    // Gasto por tópico na obra: do maior para o menor, no empate o que aparece primeiro nos gastos; a legenda para em 7
    const legendaDaObra=await page.$$eval('#oDonutLeg .row',rs=>rs.map(r=>[r.querySelector('.nm').textContent,r.querySelector('.vl').textContent]));
    assert.deepEqual(legendaDaObra.map(([n,v])=>[texto(n),texto(v)]),[['Terreno','74% · R$ 150 mil'],['Fundação','10% · R$ 20 mil'],
      ['Pintura','5% · R$ 10 mil'],['Alvenaria','5% · R$ 10 mil'],['Elétrica','3% · R$ 5,4 mil'],['Encanamento','1% · R$ 3,0 mil'],
      ['Telhado','1% · R$ 2,5 mil']]);
    assert.equal(await page.locator('#oDonut circle').count(),9);
    assert.equal(texto(await page.locator('#oDonutTotal').textContent()),'R$ 202 mil');

    // Nos Gráficos: todos os tópicos, na mesma ordem, no anel e na legenda
    await page.evaluate(()=>{showView('graficos');renderGraficos();});
    const legendaDosGraficos=await page.$$eval('#grafBody .graf-leg li',ls=>ls.map(l=>[l.dataset.top,l.querySelector('.t').textContent,l.querySelector('.li-val').textContent]));
    assert.deepEqual(legendaDosGraficos.map(([id,n,v])=>[id,texto(n),texto(v)]),[['terreno','Terreno','74% · R$ 150 mil'],
      ['fundacao','Fundação','10% · R$ 20 mil'],['pintura','Pintura','5% · R$ 10 mil'],['alvenaria','Alvenaria','5% · R$ 10 mil'],
      ['eletrica','Elétrica','3% · R$ 5,4 mil'],['hidraulica','Encanamento','1% · R$ 3,0 mil'],['telhado','Telhado','1% · R$ 2,5 mil'],
      ['projeto','Documentação','1% · R$ 1,2 mil'],['outros','Outros','0% · R$ 300,00']]);
    assert.deepEqual(await page.$$eval('#grafBody .graf-donut circle',cs=>cs.map(c=>c.dataset.top)),
      ['terreno','fundacao','pintura','alvenaria','eletrica','hidraulica','telhado','projeto','outros']);

    assert.deepEqual(await page.evaluate(()=>errosAnalise),[]);
    await ctx.close();
    console.log('ok - análise: gasto por tópico na obra e nos Gráficos');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
```

Em `tests/browser/rodar.cjs`:

```diff
--- a/tests/browser/rodar.cjs
+++ b/tests/browser/rodar.cjs
@@ -22,6 +22,7 @@ const run=(file,args=[])=>new Promise((resolve,reject)=>{
     await run('tests/browser/escrita.cjs');
     await run('tests/browser/orcamento.cjs');
     await run('tests/browser/dentro-da-obra.cjs');
+    await run('tests/browser/analise.cjs');
     await run('tests/browser/ios.cjs');
     await run('tests/browser/vidro.cjs');
     await run('tests/browser/contraste.cjs',[os.tmpdir()]);
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs 2>&1 | grep -m1 Error
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter DentroDaObraTests 2>&1 | grep -A1 'recorded an issue'
node tests/browser/servidor.cjs > "$TMPDIR/servidor-8123.log" 2>&1 & SERVIDOR=$!
curl -s -o /dev/null --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8123
lsof -nP -iTCP:8123 -sTCP:LISTEN -t | grep -qx "$SERVIDOR" && echo 'a 8123 é deste worktree'
node tests/browser/analise.cjs
kill $SERVIDOR
```
Expected: o gerador para com `TypeError: fn is not a function` (o `calc.js` ainda não exporta `gastoPorTopico`); no núcleo, `✘ Test gastoPorTopicoComoOSite() recorded an issue at Vetores.swift:56:36: Issue recorded` e `↳ grupo calc.gastoPorTopico sem casos em tests/vetores/calc.json`; o servidor sobe: `a 8123 é deste worktree` (sem essa linha, a porta é de outro worktree: pare e combine com quem a usa); a suíte de browser já passa (`ok - análise: gasto por tópico na obra e nos Gráficos`), porque o site não muda.

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift
@@ -55,10 +55,10 @@ public struct GastoDoTopico: Equatable, Sendable, Identifiable {
     public let pct: Double
 }
 
-/// O "Gasto por tópico" do modo total: cada tópico com gasto, com o bruto e o "% da obra" do resumo do tópico, para o número
-/// ser o mesmo que o detalhe mostra ao abrir. A ordem é a da legenda do donut do site (renderObra do app.js,
-/// `Object.entries(byTop).sort((a,b)=>b[1]-a[1])`): do maior bruto para o menor e, no empate, o tópico que aparece primeiro
-/// nos gastos, porque o byTop nasce na ordem dos gastos e o sort do JavaScript é estável.
+/// `gastoPorTopico` do calc.js (o donut e a legenda da obra e dos Gráficos), também o "Gasto por tópico" do modo total: cada
+/// tópico com gasto, com o bruto e o "% da obra" do resumo do tópico, para o número ser o mesmo que o detalhe mostra ao abrir.
+/// Do maior bruto para o menor e, no empate, o tópico que aparece primeiro nos gastos (o sort do JavaScript é estável).
+/// `hoje` e `taxaMensal` não mudam o resultado.
 public func gastoPorTopico(_ obra: Obra, hoje: String, taxaMensal: Double) -> [GastoDoTopico] {
     var ids: [String] = []
     for g in obra.gastos where !ids.contains(g.topico) { ids.append(g.topico) }
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -409,9 +409,7 @@ function renderObra(){
       <ul class="list" id="oAfazeres"></ul>
     </div>`;
 
-  const byTop = {};
-  o.gastos.forEach(g=>{ byTop[g.topico]=(byTop[g.topico]||0)+g.valor; });
-  const entries = Object.entries(byTop).sort((a,b)=>b[1]-a[1]);
+  const porTopico = OBRA_CALC.gastoPorTopico(o);
 
   const graficos = `
     <div class="panel"><h2>Gastos por tópico</h2>
@@ -446,7 +444,7 @@ function renderObra(){
   fitNums($('#obraBody'));
   pintaBarrasOrc($('#obraBody'));
 
-  drawDonutObra(entries, bruto);
+  drawDonutObra(porTopico, bruto);
   bindEvoChart(o);
   bindMesChart(o);
   $('#fBusca').addEventListener('input', ()=>{ filtroTexto = $('#fBusca').value; renderGastosFiltrados(obraById(obraAberta)); });
@@ -519,15 +517,16 @@ function afazerRow(o, a){
   return li;
 }
 
-function drawDonutObra(entries, total){
+/* topicos: o gastoPorTopico do calc.js ({id, bruto, pct}, na ordem do donut) */
+function drawDonutObra(topicos, total){
   const svg = $('#oDonut'), leg = $('#oDonutLeg');
   $('#oDonutTotal').textContent = moneyShort(total);
   if(!total){ svg.innerHTML=''; leg.innerHTML = `<div class="layout-37 empty"><p>Sem gastos ainda</p></div>`; return; }
   const cs = getComputedStyle(document.documentElement);
   const R = 15.915, C = 2*Math.PI*R;
   let off = 0, paths = '';
-  entries.forEach(([id,val],i)=>{
-    const len = val/total*C;
+  topicos.forEach(({bruto},i)=>{
+    const len = bruto/total*C;
     const color = cs.getPropertyValue(PIE[i%PIE.length]).trim();
     paths += `<circle cx="18" cy="18" r="${R}" fill="none" stroke="${color}" stroke-width="4.4"
       stroke-dasharray="${len} ${C-len}" stroke-dashoffset="${-off}" transform="rotate(-90 18 18)"></circle>`;
@@ -536,13 +535,13 @@ function drawDonutObra(entries, total){
   svg.innerHTML = paths;
   leg.innerHTML = '';
   const map = TOP_MAP();
-  entries.slice(0,7).forEach(([id,val],i)=>{
+  topicos.slice(0,7).forEach(({id,bruto,pct},i)=>{
     const t = map[id] || {nm:id, ic:'etiqueta'};
     const color = cs.getPropertyValue(PIE[i%PIE.length]).trim();
     leg.appendChild(el('div','row',
       `<span class="dot pie-${i%PIE.length}"></span>
        <span class="nm">${ICON(t.ic)} ${escapeHtml(t.nm)}</span>
-       <span class="vl">${Math.round(val/total*100)}% · ${moneyShort(val)}</span>`));
+       <span class="vl">${pct}% · ${moneyShort(bruto)}</span>`));
   });
 }
 
@@ -1029,27 +1028,27 @@ $('#btnRelVoltar').onclick = ()=>{ if(obraAberta) openObra(obraAberta); else { s
 $('#btnGrafVoltar').onclick = ()=>{ if(obraAberta) openObra(obraAberta); else { showView('inicio'); renderAll(); } };
 
 /* donut + legenda largura cheia (nome completo, % e valor) — reusado
-   pela tela Gráficos e pelo dashboard do início */
-function donutComLegendaHtml(entries, total, size){
+   pela tela Gráficos e pelo dashboard do início. topicos: o gastoPorTopico do calc.js */
+function donutComLegendaHtml(topicos, total, size){
   if(!(total > 0)) return emptyBlock(ICON('recibo'),'Sem gastos ainda.');
   const cs = getComputedStyle(document.documentElement);
   const map = TOP_MAP();
   const R = 15.915, C = 2*Math.PI*R;
   let off = 0, paths = '';
-  entries.forEach(([id,val],i)=>{
-    const len = val/total*C;
+  topicos.forEach(({id,bruto},i)=>{
+    const len = bruto/total*C;
     const color = cs.getPropertyValue(PIE[i%PIE.length]).trim();
     paths += `<circle cx="18" cy="18" r="${R}" fill="none" stroke="${color}" stroke-width="4.4"
       stroke-dasharray="${len} ${C-len}" stroke-dashoffset="${-off}" transform="rotate(-90 18 18)"
       data-top="${escapeHtml(id)}"></circle>`;
     off += len;
   });
-  const legenda = entries.map(([id,val],i)=>{
+  const legenda = topicos.map(({id,bruto,pct},i)=>{
     const t = map[id] || {nm:id, ic:'etiqueta'};
     const color = cs.getPropertyValue(PIE[i%PIE.length]).trim();
     return `<li data-top="${escapeHtml(id)}"><span class="dot pie-${i%PIE.length}"></span>
       <div class="li-main"><div class="t">${ICON(t.ic)} ${escapeHtml(t.nm)}</div></div>
-      <div class="li-val">${Math.round(val/total*100)}% · ${moneyShort(val)}</div></li>`;
+      <div class="li-val">${pct}% · ${moneyShort(bruto)}</div></li>`;
   }).join('');
   return `<div class="graf-donut"><div class="donut donut-${size}">
       <svg viewBox="0 0 36 36" width="${size}" height="${size}">${paths}</svg>
@@ -1057,12 +1056,6 @@ function donutComLegendaHtml(entries, total, size){
     </div></div>
     <ul class="list graf-leg">${legenda}</ul>`;
 }
-const byTopico = gastos => {
-  const by = {};
-  gastos.forEach(g=>{ by[g.topico]=(by[g.topico]||0)+g.valor; });
-  return Object.entries(by).sort((a,b)=>b[1]-a[1]);
-};
-
 /* liga o clique da legenda e das fatias do donut. Separado do helper de HTML
    porque ele devolve string: o bind só existe depois de inserir no DOM —
    mesmo par de bindEvoChart/bindMesChart. Quem não chamar isso fica sem
@@ -1090,7 +1083,7 @@ function renderGraficos(){
   const o = obraById(obraAberta);
   if(!o){ showView('inicio'); renderAll(); return; }
   const bruto = OBRA_CALC.totalBruto(o);
-  const donutLeg = donutComLegendaHtml(byTopico(o.gastos), bruto, 240);
+  const donutLeg = donutComLegendaHtml(OBRA_CALC.gastoPorTopico(o), bruto, 240);
 
   $('#grafBody').innerHTML = `
     <div class="panel">
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -87,6 +87,17 @@
     return { qtd: gs.length, bruto, corrigido: gs.reduce((s, g) => s + corrigido(g.valor, g.data, fim, taxaPct), 0),
       pct: total > 0 ? Math.round(bruto / total * 100) : 0 };
   }
+  /* Gasto por tópico (o donut e a legenda da obra e dos Gráficos): o bruto de todos os gastos, com as parcelas a vencer, do
+     maior para o menor; no empate, o tópico que aparece primeiro nos gastos (o sort é estável). pct: o "% da obra" da
+     legenda, com o arredondamento do resumoTopico (0 na obra sem gasto). Map, e não objeto: num objeto, o tópico de id
+     numérico ("12") passaria à frente no empate e o "__proto__" sumiria. */
+  function gastoPorTopico(obra){
+    const por = new Map();
+    obra.gastos.forEach(g => por.set(g.topico, (por.get(g.topico) || 0) + g.valor));
+    const total = totalBruto(obra);
+    return [...por].sort((a, b) => b[1] - a[1])
+      .map(([id, bruto]) => ({ id, bruto, pct: total > 0 ? Math.round(bruto / total * 100) : 0 }));
+  }
   function lucroVenda(obra, taxaPct){
     if(!obra.venda) return null;
     return {
@@ -535,7 +546,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, gastoPorTopico, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Regerar:

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | grep -E '^ℹ (pass|fail)'
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'warning:|Test run with'
node tests/browser/servidor.cjs > "$TMPDIR/servidor-8123.log" 2>&1 & SERVIDOR=$!
curl -s -o /dev/null --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8123
lsof -nP -iTCP:8123 -sTCP:LISTEN -t | grep -qx "$SERVIDOR" && echo 'a 8123 é deste worktree'
node tests/browser/analise.cjs && node tests/browser/xss.cjs && node tests/browser/nativo.cjs
kill $SERVIDOR
```
Expected: `tests/vetores/calc.json: 101 grupos, 1025 casos`; `ℹ pass 407` e `ℹ fail 0`; `✔ Test run with 234 tests in 37 suites passed after 0.212 seconds.` (1 novo em `DentroDaObraTests`), sem nenhum `warning:`; `a 8123 é deste worktree`; as três suítes terminam com `ok`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift app.js calc.js scripts/vetores-calc.mjs tests/browser/analise.cjs tests/browser/rodar.cjs tests/vetores/calc.json
git commit -m "feat: gasto por tópico do donut no calc.js" -m "A soma bruta por tópico, a ordem do donut (do maior para o menor; no empate, o tópico que aparece primeiro nos gastos) e o \"% da obra\" da legenda saem do app.js, onde a conta estava repetida na obra e nos Gráficos, para o calc.js, e entram nos vetores. O app nativo já tinha a cópia (gastoPorTopico) e passa a ser conferido pelos mesmos casos." -m "A soma usa um Map: num objeto, um tópico de id numérico passaria à frente no empate e o \"__proto__\" sumiria. Nenhum tópico do site tem id assim. A suíte nova analise.cjs prende a legenda da obra e a dos Gráficos."
```

### Task 2: Grupos do relatório no calc.js

Os grupos do Relatório saem do `renderRelatorio` (app.js:1164-1178 e 1188) para o `calc.js` (`relatorioObra`). A regra: a correção vai até a venda ou hoje (`fimCorrecao`; o `app.js` tinha uma cópia à mão, app.js:1164); um grupo por tópico, do maior bruto para o menor e, no empate, o tópico que aparece primeiro nos gastos; no grupo, os gastos por data (`localeCompare` da data ISO; na mesma data, a ordem do documento, porque o `sort` é estável), cada um com o corrigido até o fim (o gasto a vencer fica com correção zero, porque os dias nunca ficam negativos); o bruto e o corrigido do grupo somam os gastos na ordem do documento, não na das datas; e os totais da obra (`totalBruto` e `totalCorrigido`). O agrupamento usa um `Map`, como o `gastoPorTopico` da tarefa anterior. A descrição vazia que vira o nome do tópico (app.js:1190) continua na cola: o nome do tópico vem do mapa de tópicos da tela. A cópia em Swift mora num arquivo novo do núcleo, `Relatorio.swift`, que as próximas tarefas completam.

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (novo): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/analise.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `fimCorrecao`, `corrigido`, `totalBruto` e `totalCorrigido` do `calc.js`; no núcleo, `fimCorrecao(_:hoje:)`, `corrigido(_:de:ate:taxa:)`, `totalBruto(_:)`, `totalCorrigido(_:taxa:hoje:)`, `ordenadoEstavel` e `menorJS` (já existem).
- Produces: `OBRA_CALC.relatorioObra(obra, hojeISO, taxaPct)` → `{fim, grupos: [{topico, itens: [{gasto, corrigido}], bruto, corrigido}], totalBruto, totalCorrigido}`. Em Swift: `ItemDoRelatorio`, `GrupoDoRelatorio`, `RelatorioDaObra` e `relatorioObra(_:hoje:taxa:)`.

- [ ] **Step 1: Escrever os testes**

Os vetores cobrem a vendida (o fim é a venda, mesmo com outro hoje), a taxa com vírgula, a mesma data com ids em ordem contrária à do documento, o empate de bruto, o tópico de id numérico e a soma do grupo em 0,1 + 0,2 + 0,3 com as datas ao contrário: na ordem do documento dá 0,6000000000000001, na das datas 0,6. O teste do site tolera 1e-12 e não vê essa diferença; o leitor em Swift confere o bruto exato. Na suíte de browser, o dia fica em 06/10/2026 pelo relógio do Playwright, no fuso de São Paulo, e a tabela inteira é conferida: ela não muda com a tarefa.

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

extension RelatorioDaObra {
    var json: ValorJSON {
        .objeto(["fim": .texto(fim), "totalBruto": .numero(totalBruto), "totalCorrigido": .numero(totalCorrigido),
                 "grupos": .lista(grupos.map { g in
                     .objeto(["topico": .texto(g.topico), "bruto": .numero(g.bruto), "corrigido": .numero(g.corrigido),
                              "itens": .lista(g.itens.map { .objeto(["gasto": .objeto($0.gasto.campos), "corrigido": .numero($0.corrigido)]) })])
                 })])
    }
}

/* O relatório da obra (calc.js relatorioObra e companhia), conferido contra os vetores do site. */
struct RelatorioTests {
    @Test func gruposDoRelatorio() {
        for c in Vetores.casos("calc.relatorioObra") {
            let r = relatorioObra(c.args[0].obra, hoje: c.args[1].comoTexto!, taxa: c.args[2].numero)
            confere(r.json, c.saida, .dinheiro, c.caso)
            // O bruto de cada grupo e o total somam na ordem do documento, como o site: exato.
            let esperado = c.saida.comoObjeto ?? [:]
            confere(.lista(r.grupos.map { .numero($0.bruto) } + [.numero(r.totalBruto)]),
                    .lista((esperado["grupos"]?.comoLista ?? []).map { $0.comoObjeto?["bruto"] ?? .nulo } + [esperado["totalBruto"] ?? .nulo]),
                    .exata, c.caso + " (bruto exato)")
        }
    }
}
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -213,6 +213,18 @@ porTopico('tópico pequeno fica com 0%', obraDe('p', [gastoDe('p1', 'terreno', 1
 porTopico('tópico de id numérico fica na ordem dos gastos', obraDe('n', [gastoDe('n1', 'pintura', 50), gastoDe('n2', '12', 50), gastoDe('n3', '3', 50)]));
 porTopico('gastos de valor zero: % zero', obraDe('z', [gastoDe('z1', 'pintura', 0), gastoDe('z2', 'eletrica', 0)]));
 porTopico('a base do % conta a parcela a vencer', obraDe('v', [gastoDe('v1', 'pintura', 50), gastoDe('v2', 'eletrica', 50, '2026-12-01')]));
+/* Relatório da obra (app.js renderRelatorio): os grupos por tópico, os gastos de cada um com o corrigido e os totais. */
+const relatorio = calc('relatorioObra');
+for(const o of BLOB.obras) relatorio(o.nome, o, HOJE, 1);
+relatorio('vendida corrige até a venda, mesmo com outro hoje', O2, '2030-01-01', 1);
+relatorio('taxa com vírgula', O4, HOJE, 0.85);
+relatorio('na mesma data, a ordem do documento, não a do id', obraDe('d', [gastoDe('k3', 'pintura', 300, '2026-02-01'),
+  gastoDe('k2', 'pintura', 100, '2026-01-15'), gastoDe('k1', 'pintura', 200, '2026-01-15')]), HOJE, 1);
+relatorio('empate de bruto: o tópico que aparece primeiro', obraDe('e', [gastoDe('e1', 'pintura', 60, '2026-03-01'),
+  gastoDe('e2', 'alvenaria', 100, '2026-02-01'), gastoDe('e3', 'pintura', 40, '2026-01-01')]), HOJE, 1);
+relatorio('o bruto do grupo soma na ordem do documento', obraDe('s', [gastoDe('s1', 'pintura', 0.1, '2026-03-01'),
+  gastoDe('s2', 'pintura', 0.2, '2026-02-01'), gastoDe('s3', 'pintura', 0.3, '2026-01-01')]), HOJE, 0);
+relatorio('tópico de id numérico fica na ordem dos gastos', obraDe('n', [gastoDe('n1', 'pintura', 50), gastoDe('n2', '12', 50)]), HOJE, 1);
 const lucro = calc('lucroVenda');
 for(const o of BLOB.obras) lucro(o.nome, o, 1);
 lucro('gasto depois da venda entra pelo valor', O2, 2);
```

Em `tests/browser/analise.cjs`:

```diff
--- a/tests/browser/analise.cjs
+++ b/tests/browser/analise.cjs
@@ -1,4 +1,5 @@
-/* Análise com dados sintéticos: o donut e a legenda da obra e dos Gráficos. Sem contas nem rede.
+/* Análise com dados sintéticos: o donut e a legenda da obra e dos Gráficos e o Relatório. Sem contas nem rede.
+   Hoje fica em 06/10/2026, no fuso de São Paulo (o relógio do Playwright), para os valores corrigidos não mudarem com o dia.
    Precisa de `node tests/browser/servidor.cjs` no ar (porta 8123). */
 const assert=require('node:assert/strict');
 const {chromium}=require('playwright');
@@ -16,7 +17,8 @@ const CASA={id:'a',nome:'Casa Alphaville',dataInicio:'2025-11-10',fase:'construc
 (async()=>{
   const browser=await chromium.launch();
   try{
-    const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:393,height:852}});
+    const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:393,height:852},timezoneId:'America/Sao_Paulo'});
+    await ctx.clock.setFixedTime(new Date('2026-10-06T12:00:00-03:00'));
     await ctx.route('**/cloud.js',r=>r.fulfill({contentType:'text/javascript',body:''}));
     await ctx.route('https://**/*',r=>r.abort());
     await ctx.addInitScript(()=>{
@@ -50,8 +52,28 @@ const CASA={id:'a',nome:'Casa Alphaville',dataInicio:'2025-11-10',fase:'construc
     assert.deepEqual(await page.$$eval('#grafBody .graf-donut circle',cs=>cs.map(c=>c.dataset.top)),
       ['terreno','fundacao','pintura','alvenaria','eletrica','hidraulica','telhado','projeto','outros']);
 
+    // Relatório: um grupo por tópico, do maior bruto para o menor (no empate, o que aparece primeiro nos gastos); no grupo, os
+    // gastos por data e, na mesma data, a ordem do documento; a descrição vazia vira o nome do tópico; o gasto a vencer não corrige
+    await page.evaluate(()=>{showView('relatorio');renderRelatorio();});
+    const linhasDoRelatorio=async()=>(await page.$$eval('#relBody .rep-table tbody tr',trs=>trs.map(tr=>[...tr.children].map(td=>td.textContent))))
+      .map(l=>l.map(texto));
+    assert.deepEqual((await linhasDoRelatorio()).slice(0,21),[
+      ['Terreno','','R$ 150.000,00','R$ 165.942,65','+R$ 15.942,65'],['Terreno','01/12/25','R$ 150.000,00','R$ 165.942,65','+R$ 15.942,65'],
+      ['Fundação','','R$ 20.000,00','R$ 21.767,00','+R$ 1.767,00'],['Sapatas','20/01/26','R$ 20.000,00','R$ 21.767,00','+R$ 1.767,00'],
+      ['Pintura','','R$ 10.000,00','R$ 10.865,06','+R$ 865,06'],['Pintura','15/01/26','R$ 2.500,00','R$ 2.725,33','+R$ 225,33'],
+      ['Massa corrida','15/01/26','R$ 1.500,00','R$ 1.635,20','+R$ 135,20'],['Tinta acrílica','01/02/26','R$ 6.000,00','R$ 6.504,54','+R$ 504,54'],
+      ['Alvenaria','','R$ 10.000,00','R$ 10.901,30','+R$ 901,30'],['Blocos','15/01/26','R$ 10.000,00','R$ 10.901,30','+R$ 901,30'],
+      ['Elétrica','','R$ 5.400,50','R$ 5.837,43','+R$ 436,93'],['Fios','10/02/26','R$ 5.400,50','R$ 5.837,43','+R$ 436,93'],
+      ['Encanamento','','R$ 3.000,00','R$ 3.242,71','+R$ 242,71'],['Tubos','10/02/26','R$ 3.000,00','R$ 3.242,71','+R$ 242,71'],
+      ['Telhado','','R$ 2.500,00','R$ 2.500,00','+R$ 0,00'],['Telhas','03/12/26','R$ 2.500,00','R$ 2.500,00','+R$ 0,00'],
+      ['Documentação','','R$ 1.200,00','R$ 1.312,44','+R$ 112,44'],['Alvará','05/01/26','R$ 1.200,00','R$ 1.312,44','+R$ 112,44'],
+      ['Outros','','R$ 300,00','R$ 321,32','+R$ 21,32'],['Limpeza','10/03/26','R$ 300,00','R$ 321,32','+R$ 21,32'],
+      ['TOTAL','','R$ 202.400,50','R$ 222.689,91','+R$ 20.289,41']]);
+    // cada caixinha leva o id do seu gasto, na ordem das linhas
+    assert.deepEqual(await page.$$eval('#relBody .rel-check',cs=>cs.map(c=>c.dataset.gasto)),['a4','a7','a3','a11','a1','a2','a5','a6','a8','a9','a10']);
+
     assert.deepEqual(await page.evaluate(()=>errosAnalise),[]);
     await ctx.close();
-    console.log('ok - análise: gasto por tópico na obra e nos Gráficos');
+    console.log('ok - análise: gasto por tópico na obra e nos Gráficos; grupos do relatório');
   }finally{await browser.close();}
 })().catch(e=>{console.error(e);process.exitCode=1;});
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs 2>&1 | grep -m1 Error
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter RelatorioTests 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'RelatorioTests.swift:[0-9:]* error: cannot find [^|]*' | sort -t: -k2,2n -u | head -3
node tests/browser/servidor.cjs > "$TMPDIR/servidor-8123.log" 2>&1 & SERVIDOR=$!
curl -s -o /dev/null --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8123
lsof -nP -iTCP:8123 -sTCP:LISTEN -t | grep -qx "$SERVIDOR" && echo 'a 8123 é deste worktree'
node tests/browser/analise.cjs
kill $SERVIDOR
```
Expected: o gerador para com `TypeError: fn is not a function` (o `calc.js` ainda não exporta `relatorioObra`); o núcleo não compila: `RelatorioTests.swift:4:11: error: cannot find type 'RelatorioDaObra' in scope` e `RelatorioTests.swift:18:21: error: cannot find 'relatorioObra' in scope`; o servidor sobe: `a 8123 é deste worktree` (sem essa linha, a porta é de outro worktree: pare e combine com quem a usa); a suíte de browser já passa (`ok - análise: gasto por tópico na obra e nos Gráficos; grupos do relatório`), porque o site não muda.

- [ ] **Step 3: Implementar**

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift`:

```swift
import Foundation

/* O relatório da obra, como o calc.js o monta (morava no app.js renderRelatorio). Conferido pelos vetores do site
   (RelatorioTests). */

/// Um gasto do relatório, com o corrigido até o fim da correção.
public struct ItemDoRelatorio: Equatable, Sendable {
    public let gasto: Gasto
    public let corrigido: Double
}

/// Um tópico do relatório: os gastos por data, o bruto e o corrigido.
public struct GrupoDoRelatorio: Equatable, Sendable {
    public let topico: String
    public let itens: [ItemDoRelatorio]
    public let bruto: Double
    public let corrigido: Double
}

public struct RelatorioDaObra: Equatable, Sendable {
    /// Até onde a correção vai: a data da venda, ou hoje.
    public let fim: String
    public let grupos: [GrupoDoRelatorio]
    public let totalBruto: Double
    public let totalCorrigido: Double
}

/// `relatorioObra` do calc.js. Um grupo por tópico, do maior bruto para o menor (no empate, o tópico que aparece primeiro nos
/// gastos); no grupo, os gastos por data (na mesma data, a ordem do documento), cada um com o corrigido até o fim; o bruto e
/// o corrigido do grupo somam os gastos na ordem do documento, não na das datas. E os totais da obra.
public func relatorioObra(_ obra: Obra, hoje: String, taxa: Double) -> RelatorioDaObra {
    let fim = fimCorrecao(obra, hoje: hoje)
    var topicos: [String] = []
    var porTopico: [String: [Gasto]] = [:]
    for g in obra.gastos {
        if porTopico[g.topico] == nil { topicos.append(g.topico) }
        porTopico[g.topico, default: []].append(g)
    }
    let grupos = topicos.map { topico in
        let gs = porTopico[topico] ?? []
        let itens = ordenadoEstavel(gs) { menorJS($0.data, $1.data) }
            .map { ItemDoRelatorio(gasto: $0, corrigido: corrigido($0.valor, de: $0.data, ate: fim, taxa: taxa)) }
        return GrupoDoRelatorio(topico: topico, itens: itens, bruto: gs.reduce(0) { $0 + $1.valor },
                                corrigido: gs.reduce(0) { $0 + corrigido($1.valor, de: $1.data, ate: fim, taxa: taxa) })
    }
    return RelatorioDaObra(fim: fim, grupos: ordenadoEstavel(grupos) { $0.bruto > $1.bruto },
                           totalBruto: totalBruto(obra), totalCorrigido: totalCorrigido(obra, taxa: taxa, hoje: hoje))
}
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -1154,31 +1154,22 @@ function renderRelatorio(){
   const o = obraById(obraAberta);
   if(!o){ showView('inicio'); renderAll(); return; }
   const hoje = todayISO();
-  const fim = (o.venda && o.venda.data) || hoje;
   const tx = taxa();
   const map = TOP_MAP();
 
-  const byTop = {};
-  o.gastos.forEach(g=>{ (byTop[g.topico] = byTop[g.topico] || []).push(g); });
-  const groups = Object.entries(byTop).map(([id,gs])=>({
-    id,
-    gs: [...gs].sort((a,b)=>a.data.localeCompare(b.data)),
-    bruto: gs.reduce((s,g)=>s+g.valor,0),
-    corr:  gs.reduce((s,g)=>s+OBRA_CALC.corrigido(g.valor,g.data,fim,tx),0),
-  })).sort((a,b)=>b.bruto-a.bruto);
-
-  const totB = OBRA_CALC.totalBruto(o);
-  const totC = OBRA_CALC.totalCorrigido(o, tx, hoje);
+  // grupos, gastos com o corrigido e totais: calc.js relatorioObra (o app nativo usa o mesmo)
+  const rel = OBRA_CALC.relatorioObra(o, hoje, tx);
+  const totB = rel.totalBruto;
+  const totC = rel.totalCorrigido;
   const lucro = OBRA_CALC.lucroVenda(o, tx);
   const itensRelatorio = new Map();
 
   let rows = '';
-  groups.forEach(gr=>{
-    const t = map[gr.id] || {nm:gr.id, ic:'etiqueta'};
+  rel.grupos.forEach(gr=>{
+    const t = map[gr.topico] || {nm:gr.topico, ic:'etiqueta'};
     rows += `<tr class="rt-top"><td>${ICON(t.ic)} ${escapeHtml(t.nm)}</td><td></td>
-      <td>${money(gr.bruto)}</td><td>${money(gr.corr)}</td><td>+${money(gr.corr-gr.bruto)}</td></tr>`;
-    gr.gs.forEach(g=>{
-      const c = OBRA_CALC.corrigido(g.valor, g.data, fim, tx);
+      <td>${money(gr.bruto)}</td><td>${money(gr.corrigido)}</td><td>+${money(gr.corrigido-gr.bruto)}</td></tr>`;
+    gr.itens.forEach(({gasto:g, corrigido:c})=>{
       itensRelatorio.set(g.id,{g,c});
       const descricao=g.descricao||t.nm;
       rows += `<tr><td class="rt-desc"><label class="rep-pick no-print"><input class="rel-check" type="checkbox" data-gasto="${escapeHtml(g.id)}" aria-label="Selecionar ${escapeHtml(descricao)}"></label>${escapeHtml(descricao)}</td><td>${fmtData(g.data)}</td>
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -98,6 +98,22 @@
     return [...por].sort((a, b) => b[1] - a[1])
       .map(([id, bruto]) => ({ id, bruto, pct: total > 0 ? Math.round(bruto / total * 100) : 0 }));
   }
+  /* ---- relatório da obra (app.js renderRelatorio): morava no app.js; o app nativo confere a cópia pelos vetores ---- */
+  /* A correção vai até a venda ou hoje (fim). Um grupo por tópico, do maior bruto para o menor (no empate, o tópico que
+     aparece primeiro nos gastos); no grupo, os gastos por data (na mesma data, a ordem do documento), cada um com o
+     corrigido até o fim; o bruto e o corrigido do grupo somam os gastos na ordem do documento. E os totais da obra. */
+  function relatorioObra(obra, hojeISO, taxaPct){
+    const fim = fimCorrecao(obra, hojeISO);
+    const por = new Map();
+    obra.gastos.forEach(g => { if(!por.has(g.topico)) por.set(g.topico, []); por.get(g.topico).push(g); });
+    const grupos = [...por].map(([topico, gs]) => ({
+      topico,
+      itens: [...gs].sort((a, b) => a.data.localeCompare(b.data)).map(g => ({ gasto: g, corrigido: corrigido(g.valor, g.data, fim, taxaPct) })),
+      bruto: gs.reduce((s, g) => s + g.valor, 0),
+      corrigido: gs.reduce((s, g) => s + corrigido(g.valor, g.data, fim, taxaPct), 0),
+    })).sort((a, b) => b.bruto - a.bruto);
+    return { fim, grupos, totalBruto: totalBruto(obra), totalCorrigido: totalCorrigido(obra, taxaPct, hojeISO) };
+  }
   function lucroVenda(obra, taxaPct){
     if(!obra.venda) return null;
     return {
@@ -546,7 +562,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, gastoPorTopico, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, gastoPorTopico, relatorioObra, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Regerar:

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | grep -E '^ℹ (pass|fail)'
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'warning:|Test run with'
node tests/browser/servidor.cjs > "$TMPDIR/servidor-8123.log" 2>&1 & SERVIDOR=$!
curl -s -o /dev/null --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8123
lsof -nP -iTCP:8123 -sTCP:LISTEN -t | grep -qx "$SERVIDOR" && echo 'a 8123 é deste worktree'
node tests/browser/analise.cjs && node tests/browser/xss.cjs && node tests/browser/mobile.cjs && node tests/browser/nativo.cjs
kill $SERVIDOR
```
Expected: `tests/vetores/calc.json: 102 grupos, 1035 casos`; `ℹ pass 407` e `ℹ fail 0`; `✔ Test run with 235 tests in 38 suites passed after 0.177 seconds.` (`RelatorioTests` é nova), sem nenhum `warning:`; `a 8123 é deste worktree`; as quatro suítes terminam com `ok`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift app.js calc.js scripts/vetores-calc.mjs tests/browser/analise.cjs tests/vetores/calc.json
git commit -m "feat: grupos do relatório no calc.js" -m "O fim da correção (até a venda ou hoje, antes uma cópia à mão do fimCorrecao), os grupos por tópico do maior bruto para o menor, os gastos de cada grupo por data com o corrigido de cada um, o bruto e o corrigido do grupo e os totais saem do app.js para o calc.js (relatorioObra) e entram nos vetores. O app nativo ganha a cópia em Swift, conferida pelos mesmos casos, para o Relatório da etapa 4." -m "O bruto do grupo soma os gastos na ordem do documento, como antes, e o leitor em Swift confere esse número exato. O site mostra o mesmo relatório: a suíte analise.cjs prende a tabela inteira com o dia fixo."
```

### Task 3: Fim e linha da correção do relatório no calc.js

Duas regras pequenas do Relatório saem do `renderRelatorio` para o `calc.js`. O fim (app.js:1196-1206, `fimRelatorio`): na obra com venda, o valor e a data da venda, o lucro bruto (venda − gasto) e o acima do banco (venda − corrigido até a venda), pelo `lucroVenda`; senão, com venda estimada, a estimada e a margem (a estimada menos o corrigido até hoje); sem as duas, `null`. Como no site, o teste é a venda existir, não a fase, e a estimada zero não conta (`if(o.valorEstimadoVenda)`). A linha da correção (app.js:1213, `linhaCorrecao`): "Correção de {taxa}% ao mês, da data de cada gasto até a venda ({dd/mm/aa})." ou "… até hoje ({dd/mm/aa}).", com a taxa pelo `String` do JavaScript e a vírgula no lugar do ponto. A data curta vira um auxiliar interno do `calc.js` (`dataCurta`), igual ao `fmtData` do `app.js`, sem o escape, que fica na cola. Os rótulos ("Venda em", "Lucro bruto (venda − gasto)"…) e a cor pelo sinal continuam na cola: no app, o mockup escreve os dele e o negativo vai em âmbar.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/analise.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `lucroVenda` e `totalCorrigido` do `calc.js`; no núcleo, `lucroVenda(_:taxa:)`, `totalCorrigido(_:taxa:hoje:)`, `dataCurta(_:)` e `numeroJS(_:)` (já existem).
- Produces: `OBRA_CALC.fimRelatorio(obra, hojeISO, taxaPct)` → `{tipo:'venda', valor, data, lucroBruto, acimaDoBanco}`, `{tipo:'estimada', valor, margem}` ou `null`; `OBRA_CALC.linhaCorrecao(obra, hojeISO, taxaPct)` → texto. Em Swift: `FimDoRelatorio` (`.venda(valor:data:lucroBruto:acimaDoBanco:)` e `.estimada(valor:margem:)`), `fimRelatorio(_:hoje:taxa:)` e `linhaCorrecao(_:hoje:taxa:)`.

- [ ] **Step 1: Escrever os testes**

Os vetores cobrem a vendida com lucro, com prejuízo e com venda zero, a vendida que não depende de hoje, a margem negativa e com outro hoje, a estimada zero, a obra pronta com a venda guardada (o teste é a venda, não a fase) e a taxa em 0,85, 1,5, 20 e 1e-7 (o `String` do JavaScript escreve "1e-7"). Na suíte de browser, o fim e a linha nas quatro obras: estimada com margem positiva, vendida com lucro e abaixo do banco (a 1,5% ao mês), pronta com margem negativa e a sem venda nem estimada.

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift
@@ -11,6 +11,18 @@ extension RelatorioDaObra {
     }
 }
 
+extension FimDoRelatorio {
+    var json: ValorJSON {
+        switch self {
+        case let .venda(valor, data, lucroBruto, acimaDoBanco):
+            .objeto(["tipo": .texto("venda"), "valor": .numero(valor), "data": .texto(data), "lucroBruto": .numero(lucroBruto),
+                     "acimaDoBanco": .numero(acimaDoBanco)])
+        case let .estimada(valor, margem):
+            .objeto(["tipo": .texto("estimada"), "valor": .numero(valor), "margem": .numero(margem)])
+        }
+    }
+}
+
 /* O relatório da obra (calc.js relatorioObra e companhia), conferido contra os vetores do site. */
 struct RelatorioTests {
     @Test func gruposDoRelatorio() {
@@ -24,4 +36,16 @@ struct RelatorioTests {
                     .exata, c.caso + " (bruto exato)")
         }
     }
+
+    @Test func fimDoRelatorio() {
+        for c in Vetores.casos("calc.fimRelatorio") {
+            confere(fimRelatorio(c.args[0].obra, hoje: c.args[1].comoTexto!, taxa: c.args[2].numero)?.json ?? .nulo, c.saida, .dinheiro, c.caso)
+        }
+    }
+
+    @Test func linhaDaCorrecao() {
+        for c in Vetores.casos("calc.linhaCorrecao") {
+            confere(.texto(linhaCorrecao(c.args[0].obra, hoje: c.args[1].comoTexto!, taxa: c.args[2].numero)), c.saida, .exata, c.caso)
+        }
+    }
 }
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -225,6 +225,21 @@ relatorio('empate de bruto: o tópico que aparece primeiro', obraDe('e', [gastoD
 relatorio('o bruto do grupo soma na ordem do documento', obraDe('s', [gastoDe('s1', 'pintura', 0.1, '2026-03-01'),
   gastoDe('s2', 'pintura', 0.2, '2026-02-01'), gastoDe('s3', 'pintura', 0.3, '2026-01-01')]), HOJE, 0);
 relatorio('tópico de id numérico fica na ordem dos gastos', obraDe('n', [gastoDe('n1', 'pintura', 50), gastoDe('n2', '12', 50)]), HOJE, 1);
+/* O fim do relatório (venda e lucro, ou venda estimada e margem, ou nada) e a linha da correção do cabeçalho. */
+const fimRel = calc('fimRelatorio');
+for(const o of BLOB.obras) fimRel(o.nome, o, HOJE, 1);
+fimRel('vendida não depende de hoje', O2, '2030-01-01', 1);
+fimRel('vendida com prejuízo', { ...O2, venda: { valor: 500000, data: '2025-02-10' } }, HOJE, 1);
+fimRel('venda zero', { ...O2, venda: { valor: 0, data: '2025-02-10' } }, HOJE, 1);
+fimRel('margem negativa', { ...O4, valorEstimadoVenda: 300000 }, HOJE, 1);
+fimRel('margem com outro hoje', O4, '2027-04-06', 1);
+fimRel('venda estimada zero não conta', { ...O4, valorEstimadoVenda: 0 }, HOJE, 1);
+fimRel('taxa com vírgula', O1, HOJE, 0.85);
+fimRel('obra pronta com a venda guardada', { ...O4, venda: { valor: 600000, data: '2026-09-30' } }, HOJE, 1);
+const linhaCorr = calc('linhaCorrecao');
+for(const o of BLOB.obras) linhaCorr(o.nome, o, HOJE, 1);
+for(const taxa of [0.85, 1.5, 20, 1e-7]) linhaCorr(`taxa ${taxa}`, O1, HOJE, taxa);
+linhaCorr('obra pronta com a venda guardada', { ...O4, venda: { valor: 600000, data: '2026-09-30' } }, HOJE, 1);
 const lucro = calc('lucroVenda');
 for(const o of BLOB.obras) lucro(o.nome, o, 1);
 lucro('gasto depois da venda entra pelo valor', O2, 2);
```

Em `tests/browser/analise.cjs`:

```diff
--- a/tests/browser/analise.cjs
+++ b/tests/browser/analise.cjs
@@ -13,6 +13,13 @@ const CASA={id:'a',nome:'Casa Alphaville',dataInicio:'2025-11-10',fase:'construc
   g('a6','hidraulica',3000,'2026-02-10','Tubos'),g('a7','fundacao',20000,'2026-01-20','Sapatas'),
   g('a8','telhado',2500,'2026-12-03','Telhas'),g('a9','projeto',1200,'2026-01-05','Alvará'),g('a10','outros',300,'2026-03-10','Limpeza'),
   g('a11','pintura',1500,'2026-01-15','Massa corrida')]};
+/* Vendida com lucro bruto e abaixo do banco (e um gasto depois da venda); pronta com margem negativa; sem venda nem estimada. */
+const VENDIDA={id:'v',nome:'Sobrado Centro',dataInicio:'2025-05-01',fase:'vendida',venda:{valor:230000,data:'2026-05-20'},
+  valorEstimadoVenda:280000,areaM2:90,gastos:[g('v1','terreno',120000,'2025-06-01','Lote'),g('v2','alvenaria',90000,'2025-09-10','Paredes'),
+  g('v3','outros',5000,'2026-07-01','Limpeza depois da venda')]};
+const PRONTA={id:'p',nome:'Pronta Jardins',dataInicio:'2026-01-05',fase:'pronta',valorEstimadoVenda:100000,
+  gastos:[g('p1','estrutura',150000,'2026-02-01','Estrutura')]};
+const SEM_VENDA={id:'s',nome:'Terreno novo',dataInicio:'2026-09-01',fase:'construcao',gastos:[g('s1','terreno',80000,'2026-09-02','Sinal')]};
 
 (async()=>{
   const browser=await chromium.launch();
@@ -31,7 +38,7 @@ const CASA={id:'a',nome:'Casa Alphaville',dataInicio:'2025-11-10',fase:'construc
     await page.goto('http://localhost:8123');
     await page.evaluate(obras=>{document.getElementById('auth')?.classList.add('hidden');document.body.classList.remove('locked');
       db=normaliza({obras,config:{taxaMensal:1,topicosCustom:[]}});
-      dadosCarregados=true;renderAll();openObra('a');},[CASA]);
+      dadosCarregados=true;renderAll();openObra('a');},[CASA,VENDIDA,PRONTA,SEM_VENDA]);
     const texto=s=>s.replace(/\s+/g,' ').trim();
 
     // Gasto por tópico na obra: do maior para o menor, no empate o que aparece primeiro nos gastos; a legenda para em 7
@@ -72,8 +79,27 @@ const CASA={id:'a',nome:'Casa Alphaville',dataInicio:'2025-11-10',fase:'construc
     // cada caixinha leva o id do seu gasto, na ordem das linhas
     assert.deepEqual(await page.$$eval('#relBody .rel-check',cs=>cs.map(c=>c.dataset.gasto)),['a4','a7','a3','a11','a1','a2','a5','a6','a8','a9','a10']);
 
+    // Fim do relatório, com a cor pelo sinal, e a linha da correção: venda estimada e margem; venda, lucro e acima do banco;
+    // margem negativa; e nada sem as duas
+    const fimDoRelatorio=()=>page.$$eval('#relBody .rep-table tbody tr',trs=>trs.slice(trs.findIndex(tr=>tr.children[0].textContent.trim()==='TOTAL')+1)
+      .map(tr=>[...tr.children].map(td=>[td.textContent.replace(/\s+/g,' ').trim(),td.className])));
+    const linhaDaCorrecao=async()=>texto((await page.locator('#relBody .rep-head').innerText()).split('\n')[1]);
+    assert.deepEqual(await fimDoRelatorio(),[[['Venda estimada',''],['',''],['R$ 450.000,00','']],
+      [['Margem estimada (estimado − corrigido)',''],['',''],['R$ 227.310,09','pos']]]);
+    assert.equal(await linhaDaCorrecao(),'Correção de 1% ao mês, da data de cada gasto até hoje (06/10/26).');
+    await page.evaluate(()=>{db.config.taxaMensal=1.5;openObra('v');showView('relatorio');renderRelatorio();});
+    assert.deepEqual(await fimDoRelatorio(),[[['Venda em 20/05/26',''],['',''],['R$ 230.000,00','']],
+      [['Lucro bruto (venda − gasto)',''],['',''],['R$ 15.000,00','pos']],[['Acima do banco (venda − corrigido)',''],['',''],['-R$ 19.420,73','neg']]]);
+    assert.equal(await linhaDaCorrecao(),'Correção de 1,5% ao mês, da data de cada gasto até a venda (20/05/26).');
+    await page.evaluate(()=>{db.config.taxaMensal=1;openObra('p');showView('relatorio');renderRelatorio();});
+    assert.deepEqual(await fimDoRelatorio(),[[['Venda estimada',''],['',''],['R$ 100.000,00','']],
+      [['Margem estimada (estimado − corrigido)',''],['',''],['-R$ 62.613,38','neg']]]);
+    await page.evaluate(()=>{openObra('s');showView('relatorio');renderRelatorio();});
+    assert.deepEqual(await fimDoRelatorio(),[]);
+    assert.equal(await linhaDaCorrecao(),'Correção de 1% ao mês, da data de cada gasto até hoje (06/10/26).');
+
     assert.deepEqual(await page.evaluate(()=>errosAnalise),[]);
     await ctx.close();
-    console.log('ok - análise: gasto por tópico na obra e nos Gráficos; grupos do relatório');
+    console.log('ok - análise: gasto por tópico na obra e nos Gráficos; grupos, fim e linha da correção do relatório');
   }finally{await browser.close();}
 })().catch(e=>{console.error(e);process.exitCode=1;});
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs 2>&1 | grep -m1 Error
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter RelatorioTests 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'RelatorioTests.swift:[0-9:]* error: cannot find [^|]*' | sort -u
node tests/browser/servidor.cjs > "$TMPDIR/servidor-8123.log" 2>&1 & SERVIDOR=$!
curl -s -o /dev/null --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8123
lsof -nP -iTCP:8123 -sTCP:LISTEN -t | grep -qx "$SERVIDOR" && echo 'a 8123 é deste worktree'
node tests/browser/analise.cjs
kill $SERVIDOR
```
Expected: o gerador para com `TypeError: fn is not a function` (sem `fimRelatorio` no `calc.js`); o núcleo não compila: `RelatorioTests.swift:14:11: error: cannot find type 'FimDoRelatorio' in scope`, `RelatorioTests.swift:42:21: error: cannot find 'fimRelatorio' in scope` e `RelatorioTests.swift:48:28: error: cannot find 'linhaCorrecao' in scope`; o servidor sobe: `a 8123 é deste worktree` (sem essa linha, a porta é de outro worktree: pare e combine com quem a usa); a suíte de browser já passa (`ok - análise: gasto por tópico na obra e nos Gráficos; grupos, fim e linha da correção do relatório`), porque o site não muda.

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift
@@ -1,7 +1,7 @@
 import Foundation
 
-/* O relatório da obra, como o calc.js o monta (morava no app.js renderRelatorio). Conferido pelos vetores do site
-   (RelatorioTests). */
+/* O relatório da obra, como o calc.js o monta (morava no app.js renderRelatorio): os grupos, o fim e a linha da correção.
+   Conferido pelos vetores do site (RelatorioTests). */
 
 /// Um gasto do relatório, com o corrigido até o fim da correção.
 public struct ItemDoRelatorio: Equatable, Sendable {
@@ -46,3 +46,28 @@ public func relatorioObra(_ obra: Obra, hoje: String, taxa: Double) -> Relatorio
     return RelatorioDaObra(fim: fim, grupos: ordenadoEstavel(grupos) { $0.bruto > $1.bruto },
                            totalBruto: totalBruto(obra), totalCorrigido: totalCorrigido(obra, taxa: taxa, hoje: hoje))
 }
+
+/// O fim do relatório.
+public enum FimDoRelatorio: Equatable, Sendable {
+    /// Na obra vendida: a venda, o lucro bruto (venda − gasto) e o acima do banco (venda − corrigido até a venda).
+    case venda(valor: Double, data: String, lucroBruto: Double, acimaDoBanco: Double)
+    /// Com venda estimada: a estimada e a margem (a estimada menos o corrigido até hoje).
+    case estimada(valor: Double, margem: Double)
+}
+
+/// `fimRelatorio` do calc.js: nil sem venda e sem venda estimada (a estimada zero não conta, como no site).
+public func fimRelatorio(_ obra: Obra, hoje: String, taxa: Double) -> FimDoRelatorio? {
+    if let venda = obra.venda, let lucro = lucroVenda(obra, taxa: taxa) {
+        return .venda(valor: venda.valor, data: venda.data, lucroBruto: lucro.bruto, acimaDoBanco: lucro.vsBanco)
+    }
+    if let estimada = obra.valorEstimadoVenda, estimada != 0 {
+        return .estimada(valor: estimada, margem: estimada - totalCorrigido(obra, taxa: taxa, hoje: hoje))
+    }
+    return nil
+}
+
+/// `linhaCorrecao` do calc.js: "Correção de 1,5% ao mês, da data de cada gasto até a venda (20/05/26)." ou "… até hoje (…).".
+public func linhaCorrecao(_ obra: Obra, hoje: String, taxa: Double) -> String {
+    let ate = obra.venda.map { "a venda (\(dataCurta($0.data)))" } ?? "hoje (\(dataCurta(hoje)))"
+    return "Correção de \(numeroJS(taxa).replacingOccurrences(of: ".", with: ","))% ao mês, da data de cada gasto até \(ate)."
+}
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -1161,7 +1161,6 @@ function renderRelatorio(){
   const rel = OBRA_CALC.relatorioObra(o, hoje, tx);
   const totB = rel.totalBruto;
   const totC = rel.totalCorrigido;
-  const lucro = OBRA_CALC.lucroVenda(o, tx);
   const itensRelatorio = new Map();
 
   let rows = '';
@@ -1177,16 +1176,18 @@ function renderRelatorio(){
     });
   });
 
+  // venda e lucro, ou venda estimada e margem, ou nada: calc.js fimRelatorio
+  const fimRel = OBRA_CALC.fimRelatorio(o, hoje, tx);
   let venda = '';
-  if(o.venda && lucro){
+  if(fimRel && fimRel.tipo === 'venda'){
     venda = `
-      <tr class="rep-total"><td>${ICON('acordo')} Venda em ${fmtData(o.venda.data)}</td><td></td><td colspan="3">${money(o.venda.valor)}</td></tr>
-      <tr><td>Lucro bruto (venda − gasto)</td><td></td><td colspan="3" class="${lucro.bruto>=0?'pos':'neg'}">${money(lucro.bruto)}</td></tr>
-      <tr><td>Acima do banco (venda − corrigido)</td><td></td><td colspan="3" class="${lucro.vsBanco>=0?'pos':'neg'}">${money(lucro.vsBanco)}</td></tr>`;
-  } else if(o.valorEstimadoVenda){
+      <tr class="rep-total"><td>${ICON('acordo')} Venda em ${fmtData(fimRel.data)}</td><td></td><td colspan="3">${money(fimRel.valor)}</td></tr>
+      <tr><td>Lucro bruto (venda − gasto)</td><td></td><td colspan="3" class="${fimRel.lucroBruto>=0?'pos':'neg'}">${money(fimRel.lucroBruto)}</td></tr>
+      <tr><td>Acima do banco (venda − corrigido)</td><td></td><td colspan="3" class="${fimRel.acimaDoBanco>=0?'pos':'neg'}">${money(fimRel.acimaDoBanco)}</td></tr>`;
+  } else if(fimRel){
     venda = `
-      <tr class="rep-total"><td>${ICON('alvo')} Venda estimada</td><td></td><td colspan="3">${money(o.valorEstimadoVenda)}</td></tr>
-      <tr><td>Margem estimada (estimado − corrigido)</td><td></td><td colspan="3" class="${o.valorEstimadoVenda-totC>=0?'pos':'neg'}">${money(o.valorEstimadoVenda-totC)}</td></tr>`;
+      <tr class="rep-total"><td>${ICON('alvo')} Venda estimada</td><td></td><td colspan="3">${money(fimRel.valor)}</td></tr>
+      <tr><td>Margem estimada (estimado − corrigido)</td><td></td><td colspan="3" class="${fimRel.margem>=0?'pos':'neg'}">${money(fimRel.margem)}</td></tr>`;
   }
 
   $('#relBody').innerHTML = `
@@ -1194,7 +1195,7 @@ function renderRelatorio(){
       <h2 class="layout-28">${ICON('documento')} Relatório — ${escapeHtml(o.nome)}</h2>
       <div class="rep-head">
         ${FASES[o.fase].nm} · começou em ${fmtData(o.dataInicio)} · ${fmtMeses(OBRA_CALC.mesesDeObra(o,hoje))}<br>
-        Correção de ${escapeHtml(String(tx).replace('.',','))}% ao mês, da data de cada gasto até ${o.venda ? `a venda (${fmtData(o.venda.data)})` : `hoje (${fmtData(hoje)})`}.<br>
+        ${escapeHtml(OBRA_CALC.linhaCorrecao(o, hoje, tx))}<br>
         Marque gastos para somar somente itens escolhidos.
       </div>
       <div class="rep-selected hidden" id="relSelected" aria-live="polite">
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -114,6 +114,23 @@
     })).sort((a, b) => b.bruto - a.bruto);
     return { fim, grupos, totalBruto: totalBruto(obra), totalCorrigido: totalCorrigido(obra, taxaPct, hojeISO) };
   }
+  /* O fim do relatório: na obra vendida, a venda, o lucro bruto e o acima do banco; senão, com venda estimada, a estimada e a
+     margem (a estimada menos o corrigido até hoje); sem as duas, null. */
+  function fimRelatorio(obra, hojeISO, taxaPct){
+    if(obra.venda){
+      const l = lucroVenda(obra, taxaPct);
+      return { tipo: 'venda', valor: obra.venda.valor, data: obra.venda.data, lucroBruto: l.bruto, acimaDoBanco: l.vsBanco };
+    }
+    if(obra.valorEstimadoVenda)
+      return { tipo: 'estimada', valor: obra.valorEstimadoVenda, margem: obra.valorEstimadoVenda - totalCorrigido(obra, taxaPct, hojeISO) };
+    return null;
+  }
+  /* A linha da correção no cabeçalho do relatório, com a taxa com vírgula: até a venda (com a data dela) ou até hoje. */
+  const dataCurta = iso => { const [a, m, d] = iso.split('-'); return `${d}/${m}/${a.slice(2)}`; };
+  function linhaCorrecao(obra, hojeISO, taxaPct){
+    const ate = obra.venda ? `a venda (${dataCurta(obra.venda.data)})` : `hoje (${dataCurta(hojeISO)})`;
+    return `Correção de ${String(taxaPct).replace('.', ',')}% ao mês, da data de cada gasto até ${ate}.`;
+  }
   function lucroVenda(obra, taxaPct){
     if(!obra.venda) return null;
     return {
@@ -562,7 +579,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, gastoPorTopico, relatorioObra, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, gastoPorTopico, relatorioObra, fimRelatorio, linhaCorrecao, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Regerar:

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | grep -E '^ℹ (pass|fail)'
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'warning:|Test run with'
node tests/browser/servidor.cjs > "$TMPDIR/servidor-8123.log" 2>&1 & SERVIDOR=$!
curl -s -o /dev/null --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8123
lsof -nP -iTCP:8123 -sTCP:LISTEN -t | grep -qx "$SERVIDOR" && echo 'a 8123 é deste worktree'
node tests/browser/analise.cjs && node tests/browser/xss.cjs && node tests/browser/mobile.cjs && node tests/browser/nativo.cjs
kill $SERVIDOR
```
Expected: `tests/vetores/calc.json: 104 grupos, 1056 casos`; `ℹ pass 407` e `ℹ fail 0`; `✔ Test run with 237 tests in 38 suites passed after 0.228 seconds.` (2 novos em `RelatorioTests`), sem nenhum `warning:`; `a 8123 é deste worktree`; as quatro suítes terminam com `ok`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift app.js calc.js scripts/vetores-calc.mjs tests/browser/analise.cjs tests/vetores/calc.json
git commit -m "feat: fim e linha da correção do relatório no calc.js" -m "O fim do relatório (na vendida, a venda, o lucro bruto e o acima do banco; com venda estimada, a estimada e a margem até hoje; sem as duas, nada) e a linha da correção do cabeçalho (\"até a venda\" ou \"até hoje\", com a data e a taxa com vírgula) saem do app.js para o calc.js (fimRelatorio e linhaCorrecao) e entram nos vetores, com a cópia em Swift no núcleo. A estimada zero continua sem margem, como no site." -m "O site mostra o mesmo: a suíte analise.cjs confere as linhas do fim e a cor pelo sinal na obra com venda estimada, na vendida, na de margem negativa e na sem as duas."
```

### Task 4: Soma da seleção do relatório no calc.js

A soma dos gastos marcados no Relatório sai do `atualizarSelecao` (app.js:1235-1243) para o `calc.js` (`somaSelecao`). A regra: recebe os itens do `relatorioObra` (`{gasto, corrigido}`), na ordem do relatório, e o total bruto da obra; devolve "1 item" ou "N itens" (0 é "0 itens"), o bruto, o corrigido (a soma dos corrigidos sem arredondar cada um antes) e a parte do total, `bruto ÷ total × 100` com 2 casas no padrão pt-BR (`toLocaleString`), ou "0%" com o total zero. No app nativo, a mesma conta serve ao Selecionar do Relatório e ao resumo dos achados da busca. A cópia em Swift escreve a parte com os dígitos e o arredondamento do `moeda` (`duasCasasPtBR`, interno), que são os do ICU: arredonda o decimal mais curto, não o binário, então 0,075% vira 0,08% e 99,995% vira 100,00%. A cola passa a guardar no mapa da tela o próprio item do relatório.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/analise.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: os itens de `relatorioObra` (Tarefa anterior); no núcleo, `ItemDoRelatorio` e `moeda(_:)`.
- Produces: `OBRA_CALC.somaSelecao(itens, totalBrutoObra)` → `{quantos, bruto, corrigido, parte}`. Em Swift: `SomaDaSelecao` e `somaSelecao(_:totalBruto:)`.

- [ ] **Step 1: Escrever os testes**

Os vetores cobrem nenhum, um, dois de valores diferentes e todos os itens, a vendida (corrigido até a venda), o total zero e os arredondamentos de 1/3, 2/3, 0,125%, 0,0625%, 99,995% e 0,075%, este o único que separa o padrão pt-BR do `toFixed` (no JavaScript e no Swift). Na suíte de browser, marcar e desmarcar dois gastos da Casa (o corrigido da soma é R$ 9.229,86, e não a soma dos dois arredondados, R$ 9.229,87), o painel que some sem nada marcado e a obra de total zero.

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift
@@ -23,6 +23,14 @@ extension FimDoRelatorio {
     }
 }
 
+extension ValorJSON {
+    /// Um item do relatorioObra do site ({gasto, corrigido}).
+    var itemDoRelatorio: ItemDoRelatorio {
+        let o = comoObjeto ?? [:]
+        return ItemDoRelatorio(gasto: Gasto(campos: o["gasto"]?.comoObjeto ?? [:]), corrigido: o["corrigido"]!.numero)
+    }
+}
+
 /* O relatório da obra (calc.js relatorioObra e companhia), conferido contra os vetores do site. */
 struct RelatorioTests {
     @Test func gruposDoRelatorio() {
@@ -43,6 +51,14 @@ struct RelatorioTests {
         }
     }
 
+    @Test func somaDaSelecao() {
+        for c in Vetores.casos("calc.somaSelecao") {
+            let r = somaSelecao((c.args[0].comoLista ?? []).map(\.itemDoRelatorio), totalBruto: c.args[1].numero)
+            confere(.objeto(["quantos": .texto(r.quantos), "bruto": .numero(r.bruto), "corrigido": .numero(r.corrigido), "parte": .texto(r.parte)]),
+                    c.saida, .dinheiro, c.caso)
+        }
+    }
+
     @Test func linhaDaCorrecao() {
         for c in Vetores.casos("calc.linhaCorrecao") {
             confere(.texto(linhaCorrecao(c.args[0].obra, hoje: c.args[1].comoTexto!, taxa: c.args[2].numero)), c.saida, .exata, c.caso)
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -240,6 +240,22 @@ const linhaCorr = calc('linhaCorrecao');
 for(const o of BLOB.obras) linhaCorr(o.nome, o, HOJE, 1);
 for(const taxa of [0.85, 1.5, 20, 1e-7]) linhaCorr(`taxa ${taxa}`, O1, HOJE, taxa);
 linhaCorr('obra pronta com a venda guardada', { ...O4, venda: { valor: 600000, data: '2026-09-30' } }, HOJE, 1);
+/* A soma da seleção do relatório: os itens são os do relatorioObra, na ordem do relatório. */
+const somaSel = calc('somaSelecao');
+const itensDoRelatorio = (o, ids) => C.relatorioObra(o, HOJE, 1).grupos.flatMap(gr => gr.itens).filter(x => !ids || ids.includes(x.gasto.id));
+const itemDe = (valor, corrigido = valor) => ({ gasto: gastoDe('i1', 'pintura', valor), corrigido });
+somaSel('nenhum', [], C.totalBruto(O1));
+somaSel('um item', itensDoRelatorio(O1, ['g01']), C.totalBruto(O1));
+somaSel('dois itens de valores diferentes', itensDoRelatorio(O1, ['g02', 'g03']), C.totalBruto(O1));
+somaSel('tudo dá 100%', itensDoRelatorio(O1), C.totalBruto(O1));
+somaSel('vendida: o corrigido vai até a venda', itensDoRelatorio(O2, ['h01', 'h04']), C.totalBruto(O2));
+somaSel('total zero', [itemDe(0)], 0);
+somaSel('um terço', [itemDe(1)], 3);
+somaSel('dois terços', [itemDe(2, 2.5)], 3);
+somaSel('meio centésimo sobe: 0,125%', [itemDe(1)], 800);
+somaSel('0,0625% fica em 0,06%', [itemDe(1)], 1600);
+somaSel('99,995% vira 100,00%', [itemDe(19999)], 20000);
+somaSel('0,075% vira 0,08%: arredonda o decimal, não o binário (o toFixed daria 0,07%)', [itemDe(3)], 4000);
 const lucro = calc('lucroVenda');
 for(const o of BLOB.obras) lucro(o.nome, o, 1);
 lucro('gasto depois da venda entra pelo valor', O2, 2);
```

Em `tests/browser/analise.cjs`:

```diff
--- a/tests/browser/analise.cjs
+++ b/tests/browser/analise.cjs
@@ -20,6 +20,8 @@ const VENDIDA={id:'v',nome:'Sobrado Centro',dataInicio:'2025-05-01',fase:'vendid
 const PRONTA={id:'p',nome:'Pronta Jardins',dataInicio:'2026-01-05',fase:'pronta',valorEstimadoVenda:100000,
   gastos:[g('p1','estrutura',150000,'2026-02-01','Estrutura')]};
 const SEM_VENDA={id:'s',nome:'Terreno novo',dataInicio:'2026-09-01',fase:'construcao',gastos:[g('s1','terreno',80000,'2026-09-02','Sinal')]};
+/* Total bruto zero: a parte do total da seleção fica em "0%". */
+const ZERADA={id:'z',nome:'Obra zerada',dataInicio:'2026-03-01',fase:'construcao',gastos:[g('z1','pintura',0,'2026-03-02','Brinde')]};
 
 (async()=>{
   const browser=await chromium.launch();
@@ -38,7 +40,7 @@ const SEM_VENDA={id:'s',nome:'Terreno novo',dataInicio:'2026-09-01',fase:'constr
     await page.goto('http://localhost:8123');
     await page.evaluate(obras=>{document.getElementById('auth')?.classList.add('hidden');document.body.classList.remove('locked');
       db=normaliza({obras,config:{taxaMensal:1,topicosCustom:[]}});
-      dadosCarregados=true;renderAll();openObra('a');},[CASA,VENDIDA,PRONTA,SEM_VENDA]);
+      dadosCarregados=true;renderAll();openObra('a');},[CASA,VENDIDA,PRONTA,SEM_VENDA,ZERADA]);
     const texto=s=>s.replace(/\s+/g,' ').trim();
 
     // Gasto por tópico na obra: do maior para o menor, no empate o que aparece primeiro nos gastos; a legenda para em 7
@@ -98,8 +100,23 @@ const SEM_VENDA={id:'s',nome:'Terreno novo',dataInicio:'2026-09-01',fase:'constr
     assert.deepEqual(await fimDoRelatorio(),[]);
     assert.equal(await linhaDaCorrecao(),'Correção de 1% ao mês, da data de cada gasto até hoje (06/10/26).');
 
+    // Soma da seleção: "N item(ns)", o bruto, o corrigido sem arredondar cada gasto antes e a parte do total com 2 casas
+    const selecao=async()=>page.evaluate(()=>[$('#relSelected').classList.contains('hidden'),
+      ...['#relSelQtd','#relSelBruto','#relSelCorr','#relSelPct'].map(s=>$(s).textContent.replace(/\s+/g,' '))]);
+    await page.evaluate(()=>{openObra('a');showView('relatorio');renderRelatorio();});
+    await page.locator('.rel-check[data-gasto="a1"]').check();
+    await page.locator('.rel-check[data-gasto="a3"]').check();
+    assert.deepEqual(await selecao(),[false,'2 itens','R$ 8.500,00','R$ 9.229,86','4,20%']);
+    await page.locator('.rel-check[data-gasto="a1"]').uncheck();
+    assert.deepEqual(await selecao(),[false,'1 item','R$ 2.500,00','R$ 2.725,33','1,24%']);
+    await page.locator('.rel-check[data-gasto="a3"]').uncheck();
+    assert.equal((await selecao())[0],true);
+    await page.evaluate(()=>{openObra('z');showView('relatorio');renderRelatorio();});
+    await page.locator('.rel-check[data-gasto="z1"]').check();
+    assert.deepEqual(await selecao(),[false,'1 item','R$ 0,00','R$ 0,00','0%']);
+
     assert.deepEqual(await page.evaluate(()=>errosAnalise),[]);
     await ctx.close();
-    console.log('ok - análise: gasto por tópico na obra e nos Gráficos; grupos, fim e linha da correção do relatório');
+    console.log('ok - análise: gasto por tópico na obra e nos Gráficos; grupos, fim, linha da correção e soma da seleção do relatório');
   }finally{await browser.close();}
 })().catch(e=>{console.error(e);process.exitCode=1;});
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs 2>&1 | grep -m1 Error
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter RelatorioTests 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'RelatorioTests.swift:[0-9:]* error: cannot find [^|]*' | sort -u
node tests/browser/servidor.cjs > "$TMPDIR/servidor-8123.log" 2>&1 & SERVIDOR=$!
curl -s -o /dev/null --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8123
lsof -nP -iTCP:8123 -sTCP:LISTEN -t | grep -qx "$SERVIDOR" && echo 'a 8123 é deste worktree'
node tests/browser/analise.cjs
kill $SERVIDOR
```
Expected: o gerador para com `TypeError: fn is not a function` (sem `somaSelecao` no `calc.js`); o núcleo não compila: `RelatorioTests.swift:56:21: error: cannot find 'somaSelecao' in scope`; o servidor sobe: `a 8123 é deste worktree` (sem essa linha, a porta é de outro worktree: pare e combine com quem a usa); a suíte de browser já passa (`ok - análise: … e soma da seleção do relatório`), porque o site não muda.

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift
@@ -1,7 +1,7 @@
 import Foundation
 
-/* O relatório da obra, como o calc.js o monta (morava no app.js renderRelatorio): os grupos, o fim e a linha da correção.
-   Conferido pelos vetores do site (RelatorioTests). */
+/* O relatório da obra, como o calc.js o monta (morava no app.js renderRelatorio): os grupos, o fim, a linha da correção e a
+   soma da seleção. Conferido pelos vetores do site (RelatorioTests). */
 
 /// Um gasto do relatório, com o corrigido até o fim da correção.
 public struct ItemDoRelatorio: Equatable, Sendable {
@@ -71,3 +71,25 @@ public func linhaCorrecao(_ obra: Obra, hoje: String, taxa: Double) -> String {
     let ate = obra.venda.map { "a venda (\(dataCurta($0.data)))" } ?? "hoje (\(dataCurta(hoje)))"
     return "Correção de \(numeroJS(taxa).replacingOccurrences(of: ".", with: ","))% ao mês, da data de cada gasto até \(ate)."
 }
+
+/// A soma da seleção do relatório (e a dos achados da busca).
+public struct SomaDaSelecao: Equatable, Sendable {
+    /// "1 item" ou "N itens".
+    public let quantos: String
+    public let bruto: Double
+    public let corrigido: Double
+    /// A parte do total bruto da obra, com 2 casas ("4,20%"), ou "0%" com o total zero.
+    public let parte: String
+}
+
+/// `somaSelecao` do calc.js: os itens na ordem do relatório (a soma em ponto flutuante segue essa ordem).
+public func somaSelecao(_ itens: [ItemDoRelatorio], totalBruto: Double) -> SomaDaSelecao {
+    let bruto = itens.reduce(0) { $0 + $1.gasto.valor }
+    return SomaDaSelecao(quantos: "\(itens.count) \(itens.count == 1 ? "item" : "itens")", bruto: bruto,
+                         corrigido: itens.reduce(0) { $0 + $1.corrigido },
+                         parte: totalBruto > 0 ? duasCasasPtBR(bruto / totalBruto * 100) + "%" : "0%")
+}
+
+/// `x.toLocaleString('pt-BR', {minimumFractionDigits: 2, maximumFractionDigits: 2})`: os dígitos e o arredondamento do
+/// `moeda` (o mesmo formatador do ICU), sem o "R$ ".
+func duasCasasPtBR(_ x: Double) -> String { moeda(x).replacingOccurrences(of: "R$\u{00A0}", with: "") }
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -1168,8 +1168,9 @@ function renderRelatorio(){
     const t = map[gr.topico] || {nm:gr.topico, ic:'etiqueta'};
     rows += `<tr class="rt-top"><td>${ICON(t.ic)} ${escapeHtml(t.nm)}</td><td></td>
       <td>${money(gr.bruto)}</td><td>${money(gr.corrigido)}</td><td>+${money(gr.corrigido-gr.bruto)}</td></tr>`;
-    gr.itens.forEach(({gasto:g, corrigido:c})=>{
-      itensRelatorio.set(g.id,{g,c});
+    gr.itens.forEach(item=>{
+      const {gasto:g, corrigido:c} = item;
+      itensRelatorio.set(g.id,item);
       const descricao=g.descricao||t.nm;
       rows += `<tr><td class="rt-desc"><label class="rep-pick no-print"><input class="rel-check" type="checkbox" data-gasto="${escapeHtml(g.id)}" aria-label="Selecionar ${escapeHtml(descricao)}"></label>${escapeHtml(descricao)}</td><td>${fmtData(g.data)}</td>
         <td>${money(g.valor)}</td><td>${money(c)}</td><td>+${money(c-g.valor)}</td></tr>`;
@@ -1219,13 +1220,12 @@ function renderRelatorio(){
   const atualizarSelecao=()=>{
     const marcados=[...document.querySelectorAll('.rel-check:checked')]
       .map(c=>itensRelatorio.get(c.dataset.gasto)).filter(Boolean);
-    const bruto=marcados.reduce((s,x)=>s+x.g.valor,0);
-    const corr=marcados.reduce((s,x)=>s+x.c,0);
+    const soma=OBRA_CALC.somaSelecao(marcados,totB);
     $('#relSelected').classList.toggle('hidden',marcados.length===0);
-    $('#relSelQtd').textContent=`${marcados.length} ${marcados.length===1?'item':'itens'}`;
-    $('#relSelBruto').textContent=money(bruto);
-    $('#relSelCorr').textContent=money(corr);
-    $('#relSelPct').textContent=totB>0?(bruto/totB*100).toLocaleString('pt-BR',{minimumFractionDigits:2,maximumFractionDigits:2})+'%':'0%';
+    $('#relSelQtd').textContent=soma.quantos;
+    $('#relSelBruto').textContent=money(soma.bruto);
+    $('#relSelCorr').textContent=money(soma.corrigido);
+    $('#relSelPct').textContent=soma.parte;
   };
   document.querySelectorAll('.rel-check').forEach(c=>c.addEventListener('change',atualizarSelecao));
   ligarImprimir($('#relPrint'));
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -131,6 +131,14 @@
     const ate = obra.venda ? `a venda (${dataCurta(obra.venda.data)})` : `hoje (${dataCurta(hojeISO)})`;
     return `Correção de ${String(taxaPct).replace('.', ',')}% ao mês, da data de cada gasto até ${ate}.`;
   }
+  /* A soma da seleção do relatório (no app, também a dos achados da busca): quantos ("1 item", "N itens"), o bruto, o
+     corrigido e a parte do total bruto da obra com 2 casas no padrão pt-BR ("0%" com o total zero). itens: os do
+     relatorioObra ({gasto, corrigido}), na ordem do relatório. */
+  function somaSelecao(itens, totalBrutoObra){
+    const bruto = itens.reduce((s, x) => s + x.gasto.valor, 0);
+    return { quantos: `${itens.length} ${itens.length === 1 ? 'item' : 'itens'}`, bruto, corrigido: itens.reduce((s, x) => s + x.corrigido, 0),
+      parte: totalBrutoObra > 0 ? (bruto / totalBrutoObra * 100).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '%' : '0%' };
+  }
   function lucroVenda(obra, taxaPct){
     if(!obra.venda) return null;
     return {
@@ -579,7 +587,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, gastoPorTopico, relatorioObra, fimRelatorio, linhaCorrecao, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, gastoPorTopico, relatorioObra, fimRelatorio, linhaCorrecao, somaSelecao, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Regerar:

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | grep -E '^ℹ (pass|fail)'
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'warning:|Test run with'
node tests/browser/servidor.cjs > "$TMPDIR/servidor-8123.log" 2>&1 & SERVIDOR=$!
curl -s -o /dev/null --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8123
lsof -nP -iTCP:8123 -sTCP:LISTEN -t | grep -qx "$SERVIDOR" && echo 'a 8123 é deste worktree'
node tests/browser/analise.cjs && node tests/browser/xss.cjs && node tests/browser/mobile.cjs && node tests/browser/nativo.cjs
kill $SERVIDOR
```
Expected: `tests/vetores/calc.json: 105 grupos, 1068 casos`; `ℹ pass 407` e `ℹ fail 0`; `✔ Test run with 238 tests in 38 suites passed after 0.210 seconds.` (1 novo em `RelatorioTests`), sem nenhum `warning:`; `a 8123 é deste worktree`; as quatro suítes terminam com `ok`. O `fase3.cjs`, que também marca gastos no Relatório ("66,67%"), roda com os emuladores no fim do PR.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Relatorio.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/RelatorioTests.swift app.js calc.js scripts/vetores-calc.mjs tests/browser/analise.cjs tests/vetores/calc.json
git commit -m "feat: soma da seleção do relatório no calc.js" -m "A soma dos gastos marcados no Relatório (\"1 item\" ou \"N itens\", o bruto, o corrigido e a parte do total bruto com 2 casas no padrão pt-BR, ou \"0%\" com o total zero) sai do app.js para o calc.js (somaSelecao) e entra nos vetores. No app nativo, a mesma conta serve ao Selecionar do Relatório e ao resumo dos achados da busca." -m "A cópia em Swift escreve a parte com os dígitos e o arredondamento do moeda, que são os do ICU: 0,075% vira 0,08%, onde o toFixed daria 0,07%. A suíte analise.cjs marca e desmarca gastos e confere o painel."
```

### Task 5: Conta do simulador no calc.js, com os meses de 0 a 120

A conta e os textos do "Vale a pena?" saem do `simulaCompute` (app.js:1267-1312) para o `calc.js`, com um dos dois alinhamentos que o Giovani aprovou em 29/10 (confirmação 4): os meses ficam entre 0 e 120 na conta (`MESES_SIMULADOR`); antes, o teto só existia no `<input>` (index.html:234) e 200 meses digitados entravam na conta (achado 5). A conta (`contaSimulador`): sem preço (venda ≤ 0), `null`; senão, alvo = hoje + meses (`addMesesClampado`), custo bruto de todos os gastos, corrigido até o alvo, obra com menos de 1 mês até o alvo sem taxa (`mesesDeObra < 1`), TIR (`tirMensal`), acima do banco (`rendimentoAcima`), veredito (venda > corrigido) e multiplicador (TIR ÷ taxa; 0 sem TIR ou sem taxa). Os textos (`textosSimulador`): o veredito, a taxa ("x,xx% ao mês" ou "—"), os detalhes do cartão ("vendendo hoje" ou "vendendo daqui a N mês/meses", "banco paga {taxa}%", "rende N,N× o banco" só com TIR e multiplicador ≥ 1, e o aviso da obra com menos de 1 mês), que o site junta com " · ", e as linhas da tabela, na ordem do site (inventário, seção 4), com a cor pelo sinal só no lucro e nas duas porcentagens (`'positivo'`, `'negativo'` ou `null` sem valor) e o R$/m² só com área. A cola continua lendo os campos (`parseNum` e `parseInt(…) || 0`) e mapeia o sinal nas classes `pos` e `neg`; o preço inicial e as obras elegíveis ficam para a próxima tarefa.

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (novo): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/analise.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `addMesesClampado`, `totalBruto`, `totalCorrigido`, `mesesDeObra`, `tirMensal`, `rendimentoAcima`, `resumoVenda` e `money` do `calc.js`; no núcleo, as cópias de cada um (`addMesesClampado(_:_:)`, `tirMensal(_:venda:alvo:)`, `resumoVenda(_:custo:)`, `moeda(_:)`, `toFixedJS(_:_:)`, `numeroJS(_:)`).
- Produces: `OBRA_CALC.MESES_SIMULADOR` (120), `OBRA_CALC.contaSimulador(obra, venda, meses, hojeISO, taxaPct)` → `{venda, meses, alvo, bruto, corrigido, novaDemais, tir, acima, vale, multiplicador}` ou `null`, e `OBRA_CALC.textosSimulador(conta, taxaPct, areaM2)` → `{veredito, taxa, detalhes, tabela: [{rotulo, bruto, corrigido, sinalBruto, sinalCorrigido, destaque}]}`. Em Swift: `mesesSimulador`, `ContaDoSimulador` e `contaSimulador(_:venda:meses:hoje:taxa:)`, `SinalDaSimulacao`, `LinhaDaSimulacao`, `TextosDoSimulador` e `textosSimulador(_:taxa:area:)`.

- [ ] **Step 1: Escrever os testes**

Os vetores da conta cobrem os meses 0, 1, 120, 121, 500 e −3, o rende menos, a taxa com vírgula, a obra nova sem taxa e a mesma obra um mês depois, a taxa zero (o multiplicador fica 0, e o leitor confere que não é infinito, porque a tolerância relativa do `confere` deixa passar infinito contra 0), o sem preço e o fim do mês (31/01 + 1 mês = 28/02). Os dos textos cobrem a área (com vírgula, zero e ausente), o multiplicador 1, 0,99 e 2,25 (o `toFixed` do JavaScript leva o empate para cima: "2,3"), o sem TIR, a TIR −0,004 ("-0,00% ao mês"), o lucro zero (cor do positivo) e o custo zero ("—"). Na suíte de browser, o cartão e a tabela inteiros na Casa; os 200 meses digitados, que caem com o alinhamento desfeito; os meses negativos e vazios; outra obra com o banco a 1,5%; e o sem preço.

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

extension ContaDoSimulador {
    var json: ValorJSON {
        .objeto(["venda": .numero(venda), "meses": .numero(Double(meses)), "alvo": .texto(alvo), "bruto": .numero(bruto),
                 "corrigido": .numero(corrigido), "novaDemais": .booleano(novaDemais), "tir": opcional(tir), "acima": opcional(acima),
                 "vale": .booleano(vale), "multiplicador": .numero(multiplicador)])
    }
}

extension ValorJSON {
    /// A conta do contaSimulador do site.
    var contaDoSimulador: ContaDoSimulador {
        let o = comoObjeto ?? [:]
        return ContaDoSimulador(venda: o["venda"]!.numero, meses: Int(o["meses"]!.numero), alvo: o["alvo"]!.comoTexto!,
                                bruto: o["bruto"]!.numero, corrigido: o["corrigido"]!.numero, novaDemais: o["novaDemais"] == .booleano(true),
                                tir: o["tir"]?.numeroOuNil, acima: o["acima"]?.numeroOuNil, vale: o["vale"] == .booleano(true),
                                multiplicador: o["multiplicador"]!.numero)
    }
}

extension TextosDoSimulador {
    var json: ValorJSON {
        .objeto(["veredito": .texto(veredito), "taxa": .texto(taxa), "detalhes": .lista(detalhes.map(ValorJSON.texto)),
                 "tabela": .lista(tabela.map { l in
                     .objeto(["rotulo": .texto(l.rotulo), "bruto": .texto(l.bruto), "corrigido": .texto(l.corrigido),
                              "sinalBruto": l.sinalBruto.map { .texto($0.rawValue) } ?? .nulo,
                              "sinalCorrigido": l.sinalCorrigido.map { .texto($0.rawValue) } ?? .nulo, "destaque": .booleano(l.destaque)])
                 })])
    }
}

/* O "Vale a pena?" (calc.js contaSimulador e companhia), conferido contra os vetores do site. */
struct SimuladorTests {
    @Test func mesesDoSimulador() {
        #expect(Double(mesesSimulador) == Vetores.casos("calc.MESES_SIMULADOR")[0].saida.comoNumero)
    }

    @Test func contaDoSimulador() {
        for c in Vetores.casos("calc.contaSimulador") {
            let r = contaSimulador(c.args[0].obra, venda: c.args[1].numero, meses: Int(c.args[2].numero), hoje: c.args[3].comoTexto!,
                                   taxa: c.args[4].numero)
            confere(r?.json ?? .nulo, c.saida, .continua, c.caso)
            // A tolerância relativa deixa passar infinito contra 0 (o confere): sem taxa, o multiplicador é 0, nunca TIR ÷ 0.
            #expect(r.map { $0.multiplicador.isFinite } ?? true, "\(c.caso): multiplicador infinito")
        }
    }

    @Test func textosDoSimulador() {
        for c in Vetores.casos("calc.textosSimulador") {
            confere(textosSimulador(c.args[0].contaDoSimulador, taxa: c.args[1].numero, area: c.args[2].numeroOuNil).json, c.saida, .exata, c.caso)
        }
    }
}
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -297,6 +297,40 @@ resumo('prejuízo', 800000, 1000000);
 resumo('venda zero', 0, 1000);
 resumo('custo zero', 1000, 0);
 
+/* O "Vale a pena?" (app.js simulaCompute): a conta, com os meses de 0 a 120, e os textos do cartão e da tabela. */
+constante('calc.MESES_SIMULADOR', C.MESES_SIMULADOR);
+const contaSim = calc('contaSimulador');
+const OBRA_NOVA = obraDe('nova', [gastoDe('n1', 'terreno', 1000, HOJE)], { dataInicio: HOJE });
+contaSim('vale a pena, vendendo hoje', O1, 1250000, 0, HOJE, 1);
+contaSim('daqui a 1 mês', O1, 1250000, 1, HOJE, 1);
+contaSim('daqui a 120 meses', O1, 1250000, 120, HOJE, 1);
+contaSim('121 meses param em 120', O1, 1250000, 121, HOJE, 1);
+contaSim('500 meses param em 120', O1, 1250000, 500, HOJE, 1);
+contaSim('meses negativos viram 0', O1, 1250000, -3, HOJE, 1);
+contaSim('rende menos que o banco', O4, 300000, 0, HOJE, 1);
+contaSim('taxa com vírgula', O4, 700000, 6, HOJE, 0.85);
+contaSim('obra com menos de 1 mês até o alvo fica sem taxa', OBRA_NOVA, 2000, 0, HOJE, 1);
+contaSim('um mês depois a obra nova já tem taxa', OBRA_NOVA, 2000, 1, HOJE, 1);
+contaSim('taxa zero não dá multiplicador (a leitura a põe em 1)', O4, 700000, 0, HOJE, 0);
+contaSim('sem preço', O1, 0, 0, HOJE, 1);
+contaSim('preço negativo', O1, -5, 0, HOJE, 1);
+contaSim('o fim do mês fica no último dia (31/01 + 1 mês)', O4, 610000, 1, '2027-01-31', 1);
+const textosSim = calc('textosSimulador');
+const CONTA = C.contaSimulador(O1, 1250000, 0, HOJE, 1);
+textosSim('vale a pena, com área', CONTA, 1, 210);
+textosSim('daqui a 1 mês, sem área', C.contaSimulador(O1, 1250000, 1, HOJE, 1), 1, null);
+textosSim('daqui a 120 meses, área zero', C.contaSimulador(O1, 1250000, 500, HOJE, 1), 1, 0);
+textosSim('rende menos, área com vírgula', C.contaSimulador(O4, 300000, 0, HOJE, 1), 1, 95.5);
+textosSim('taxa com vírgula', C.contaSimulador(O4, 700000, 6, HOJE, 0.85), 0.85, 95.5);
+textosSim('obra com menos de 1 mês: sem taxa e o aviso', C.contaSimulador(OBRA_NOVA, 2000, 0, HOJE, 1), 1, null);
+textosSim('multiplicador 1 aparece', { ...CONTA, tir: 1, multiplicador: 1 }, 1, null);
+textosSim('multiplicador abaixo de 1 some', { ...CONTA, tir: 0.99, multiplicador: 0.99 }, 1, null);
+textosSim('multiplicador 2,25 arredonda para 2,3', { ...CONTA, tir: 2.25, multiplicador: 2.25 }, 1, null);
+textosSim('sem TIR, o multiplicador some', { ...CONTA, tir: null, acima: null, multiplicador: 1.5 }, 1, null);
+textosSim('TIR negativa perto de zero: -0,00%', { ...CONTA, tir: -0.004, acima: -1.0039, vale: false, multiplicador: -0.004 }, 1, null);
+textosSim('lucro zero fica com a cor do positivo', { ...CONTA, venda: CONTA.bruto }, 1, null);
+textosSim('custo zero: lucro e porcentagens sem valor', { ...CONTA, bruto: 0, corrigido: 0 }, 1, null);
+
 /* ---------- séries dos gráficos ---------- */
 const evo = calc('serieEvolucao');
 for(const o of BLOB.obras) evo(o.nome, o, 1, HOJE);
```

Em `tests/browser/analise.cjs`:

```diff
--- a/tests/browser/analise.cjs
+++ b/tests/browser/analise.cjs
@@ -1,4 +1,4 @@
-/* Análise com dados sintéticos: o donut e a legenda da obra e dos Gráficos e o Relatório. Sem contas nem rede.
+/* Análise com dados sintéticos: o donut e a legenda da obra e dos Gráficos, o Relatório e o "Vale a pena?". Sem contas nem rede.
    Hoje fica em 06/10/2026, no fuso de São Paulo (o relógio do Playwright), para os valores corrigidos não mudarem com o dia.
    Precisa de `node tests/browser/servidor.cjs` no ar (porta 8123). */
 const assert=require('node:assert/strict');
@@ -115,8 +115,46 @@ const ZERADA={id:'z',nome:'Obra zerada',dataInicio:'2026-03-01',fase:'construcao
     await page.locator('.rel-check[data-gasto="z1"]').check();
     assert.deepEqual(await selecao(),[false,'1 item','R$ 0,00','R$ 0,00','0%']);
 
+    // "Vale a pena?": o cartão e a tabela da simulação, com a cor pelo sinal no lucro e nas porcentagens
+    const cartao=()=>page.evaluate(()=>{const c=$('#simOut .card.saldo');return c&&[c.classList.contains('saldo-abaixo'),
+      ...['.k-label','.k-val','.k-sub'].map(s=>c.querySelector(s).textContent.replace(/\s+/g,' ').trim())];});
+    const tabela=()=>page.$$eval('#simOut .rep-sim tbody tr',trs=>trs.map(tr=>[tr.className,...[...tr.children].map(td=>[td.textContent.replace(/\s+/g,' ').trim(),td.className])]));
+    const linha=(rotulo,b,c,cb='',cc='',tr='')=>[tr,[rotulo,''],[b,cb],[c,cc]];
+    await page.evaluate(()=>{showView('simula');renderSimula();});
+    assert.equal(await page.locator('#simObra').inputValue(),'a');
+    assert.equal(await page.locator('#simValor').inputValue(),'450.000,00');
+    assert.deepEqual(await cartao(),[false,'Vale a pena','8,63% ao mês','vendendo hoje · banco paga 1% · rende 8,6× o banco']);
+    assert.deepEqual(await tabela(),[linha('Custo até a venda','R$ 202.400,50','R$ 222.689,91'),linha('Venda','R$ 450.000,00','R$ 450.000,00'),
+      linha('Lucro','R$ 247.599,50','R$ 227.310,09','pos','pos','rep-total'),linha('% sobre o custo','122,3%','102,1%','pos','pos'),
+      linha('% sobre a venda','55,0%','50,5%','pos','pos'),linha('Rendimento ao mês','8,63% a.m.','7,55% a.m.'),
+      linha('Preço por m² (120 m²)','R$ 3.750,00','R$ 3.750,00')]);
+    // Os meses param em 120 na conta, mesmo digitados além do teto do campo (achado 5); negativos viram hoje
+    await page.locator('#simMeses').fill('200');
+    assert.deepEqual(await cartao(),[true,'Rende menos que o banco','0,62% ao mês','vendendo daqui a 120 meses · banco paga 1%']);
+    assert.deepEqual(await tabela(),[linha('Custo até a venda','R$ 202.400,50','R$ 734.855,94'),linha('Venda','R$ 450.000,00','R$ 450.000,00'),
+      linha('Lucro','R$ 247.599,50','-R$ 284.855,94','pos','neg','rep-total'),linha('% sobre o custo','122,3%','-38,8%','pos','neg'),
+      linha('% sobre a venda','55,0%','-63,3%','pos','neg'),linha('Rendimento ao mês','0,62% a.m.','-0,38% a.m.'),
+      linha('Preço por m² (120 m²)','R$ 3.750,00','R$ 3.750,00')]);
+    for(const meses of ['-2','']){
+      await page.locator('#simMeses').fill(meses);
+      assert.equal((await cartao())[3],'vendendo hoje · banco paga 1% · rende 8,6× o banco');
+    }
+    // Outra obra, com preço e meses digitados e o banco a 1,5%: rende menos, sem área
+    await page.evaluate(()=>{db.config.taxaMensal=1.5;});
+    await page.locator('#simObra').selectOption('p');
+    await page.locator('#simValor').fill('120.000,00');
+    await page.locator('#simMeses').fill('3');
+    assert.deepEqual(await cartao(),[true,'Rende menos que o banco','-1,98% ao mês','vendendo daqui a 3 meses · banco paga 1,5%']);
+    assert.deepEqual(await tabela(),[linha('Custo até a venda','R$ 150.000,00','R$ 177.052,22'),linha('Venda','R$ 120.000,00','R$ 120.000,00'),
+      linha('Lucro','-R$ 30.000,00','-R$ 57.052,22','neg','neg','rep-total'),linha('% sobre o custo','-20,0%','-32,2%','neg','neg'),
+      linha('% sobre a venda','-25,0%','-47,5%','neg','neg'),linha('Rendimento ao mês','-1,98% a.m.','-3,43% a.m.')]);
+    await page.evaluate(()=>{db.config.taxaMensal=1;});
+    // Sem preço, a frase do site e nenhuma conta
+    await page.locator('#simValor').fill('0');
+    assert.equal(texto(await page.locator('#simOut').textContent()),'Digite o preço de venda pra ver a conta.');
+
     assert.deepEqual(await page.evaluate(()=>errosAnalise),[]);
     await ctx.close();
-    console.log('ok - análise: gasto por tópico na obra e nos Gráficos; grupos, fim, linha da correção e soma da seleção do relatório');
+    console.log('ok - análise: gasto por tópico na obra e nos Gráficos; grupos, fim, linha da correção e soma da seleção do relatório; conta e textos do "Vale a pena?"');
   }finally{await browser.close();}
 })().catch(e=>{console.error(e);process.exitCode=1;});
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs 2>&1 | grep -m1 Error
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter SimuladorTests 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'SimuladorTests.swift:[0-9:]* error: cannot find [^|]*' | sort -u | head -3
node tests/browser/servidor.cjs > "$TMPDIR/servidor-8123.log" 2>&1 & SERVIDOR=$!
curl -s -o /dev/null --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8123
lsof -nP -iTCP:8123 -sTCP:LISTEN -t | grep -qx "$SERVIDOR" && echo 'a 8123 é deste worktree'
node tests/browser/analise.cjs 2>&1 | grep -A9 AssertionError
kill $SERVIDOR
```
Expected: o gerador para com `TypeError: fn is not a function` (sem `contaSimulador` no `calc.js`); o núcleo não compila: `SimuladorTests.swift:14:27: error: cannot find type 'ContaDoSimulador' in scope`, `SimuladorTests.swift:16:16: error: cannot find 'ContaDoSimulador' in scope` e `SimuladorTests.swift:23:11: error: cannot find type 'TextosDoSimulador' in scope`; o servidor sobe: `a 8123 é deste worktree` (sem essa linha, a porta é de outro worktree: pare e combine com quem a usa); a suíte de browser cai nos 200 meses:
```
AssertionError [ERR_ASSERTION]: Expected values to be strictly deep-equal:
+ actual - expected

  [
    true,
    'Rende menos que o banco',
+   '0,38% ao mês',
+   'vendendo daqui a 200 meses · banco paga 1%'
-   '0,62% ao mês',
-   'vendendo daqui a 120 meses · banco paga 1%'
```

- [ ] **Step 3: Implementar**

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift`:

```swift
import Foundation

/* O "Vale a pena?", como o calc.js o calcula e escreve (morava no app.js simulaCompute). Conferido pelos vetores do site
   (SimuladorTests). */

/// `MESES_SIMULADOR` do calc.js: os meses da venda vão de 0 a 120 na conta.
public let mesesSimulador = 120

public struct ContaDoSimulador: Equatable, Sendable {
    public let venda: Double
    /// Os meses da conta, entre 0 e 120.
    public let meses: Int
    /// Hoje mais os meses (`addMesesClampado`).
    public let alvo: String
    public let bruto: Double
    /// Corrigido até o alvo.
    public let corrigido: Double
    /// Menos de 1 mês de obra até o alvo: fica sem taxa.
    public let novaDemais: Bool
    /// A TIR, em % ao mês; nil sem taxa.
    public let tir: Double?
    public let acima: Double?
    /// A venda passa do corrigido.
    public let vale: Bool
    /// TIR ÷ taxa; 0 sem TIR.
    public let multiplicador: Double
}

/// `contaSimulador` do calc.js: vender a obra por `venda` daqui a `meses`, sem gasto novo até lá; nil sem preço.
public func contaSimulador(_ obra: Obra, venda: Double, meses: Int, hoje: String, taxa: Double) -> ContaDoSimulador? {
    if venda <= 0 { return nil }
    let m = min(mesesSimulador, max(0, meses))
    let alvo = addMesesClampado(hoje, m)
    let corrigido = totalCorrigido(obra, taxa: taxa, hoje: alvo)
    let novaDemais = mesesDeObra(obra, hoje: alvo) < 1
    let tir = novaDemais ? nil : tirMensal(obra.gastos, venda: venda, alvo: alvo)
    return ContaDoSimulador(venda: venda, meses: m, alvo: alvo, bruto: totalBruto(obra), corrigido: corrigido, novaDemais: novaDemais,
                            tir: tir, acima: rendimentoAcima(tir, taxa: taxa), vale: venda > corrigido,
                            multiplicador: tir.map { taxa > 0 ? $0 / taxa : 0 } ?? 0)
}

/// A cor de um número da tabela, pelo sinal.
public enum SinalDaSimulacao: String, Sendable {
    case positivo, negativo
}

public struct LinhaDaSimulacao: Equatable, Sendable {
    public let rotulo: String
    /// Pelo bruto.
    public let bruto: String
    /// Pelo corrigido.
    public let corrigido: String
    /// Só no lucro e nas duas porcentagens; nil sem valor.
    public let sinalBruto: SinalDaSimulacao?
    public let sinalCorrigido: SinalDaSimulacao?
    /// A linha do lucro.
    public let destaque: Bool
}

public struct TextosDoSimulador: Equatable, Sendable {
    /// "Vale a pena" ou "Rende menos que o banco".
    public let veredito: String
    /// "8,63% ao mês" ou "—".
    public let taxa: String
    /// "vendendo hoje", "banco paga 1%", "rende 8,6× o banco" e o aviso da obra com menos de 1 mês (o site junta com " · ").
    public let detalhes: [String]
    public let tabela: [LinhaDaSimulacao]
}

/// `textosSimulador` do calc.js: o cartão e a tabela da simulação. O R$/m² só com área.
public func textosSimulador(_ conta: ContaDoSimulador, taxa: Double, area: Double?) -> TextosDoSimulador {
    func virgula(_ v: Double, _ casas: Int) -> String { toFixedJS(v, casas).replacingOccurrences(of: ".", with: ",") }
    func din(_ v: Double?) -> String { v.map { moeda($0) } ?? "—" }
    func pct1(_ v: Double?) -> String { v.map { virgula($0, 1) + "%" } ?? "—" }
    func taxa2(_ v: Double?) -> String { v.map { virgula($0, 2) + "% a.m." } ?? "—" }
    func sinal(_ v: Double?) -> SinalDaSimulacao? { v.map { $0 >= 0 ? .positivo : .negativo } }
    func linha(_ rotulo: String, _ bruto: String, _ corrigido: String, sinais: (Double?, Double?)? = nil,
               destaque: Bool = false) -> LinhaDaSimulacao {
        LinhaDaSimulacao(rotulo: rotulo, bruto: bruto, corrigido: corrigido, sinalBruto: sinais.flatMap { sinal($0.0) },
                         sinalCorrigido: sinais.flatMap { sinal($0.1) }, destaque: destaque)
    }
    let rb = resumoVenda(conta.venda, custo: conta.bruto)
    let rc = resumoVenda(conta.venda, custo: conta.corrigido)
    var detalhes = [conta.meses == 0 ? "vendendo hoje" : "vendendo daqui a \(conta.meses) \(conta.meses == 1 ? "mês" : "meses")",
                    "banco paga \(numeroJS(taxa).replacingOccurrences(of: ".", with: ","))%"]
    if conta.tir != nil && conta.multiplicador >= 1 { detalhes.append("rende \(virgula(conta.multiplicador, 1))× o banco") }
    if conta.novaDemais { detalhes.append("obra com menos de 1 mês — % ao mês ainda não diz muito") }
    var tabela = [
        linha("Custo até a venda", moeda(conta.bruto), moeda(conta.corrigido)),
        linha("Venda", moeda(conta.venda), moeda(conta.venda)),
        linha("Lucro", din(rb.lucro), din(rc.lucro), sinais: (rb.lucro, rc.lucro), destaque: true),
        linha("% sobre o custo", pct1(rb.pctCusto), pct1(rc.pctCusto), sinais: (rb.pctCusto, rc.pctCusto)),
        linha("% sobre a venda", pct1(rb.pctVenda), pct1(rc.pctVenda), sinais: (rb.pctVenda, rc.pctVenda)),
        linha("Rendimento ao mês", taxa2(conta.tir), taxa2(conta.acima)),
    ]
    if let area, area > 0 {
        tabela.append(linha("Preço por m² (\(numeroJS(area).replacingOccurrences(of: ".", with: ",")) m²)", moeda(conta.venda / area),
                            moeda(conta.venda / area)))
    }
    return TextosDoSimulador(veredito: conta.vale ? "Vale a pena" : "Rende menos que o banco",
                             taxa: conta.tir.map { virgula($0, 2) + "% ao mês" } ?? "—", detalhes: detalhes, tabela: tabela)
}
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -1250,51 +1250,29 @@ function simulaCompute(){
 
   const vInp = $('#simValor');
   if(!vInp.value && o.valorEstimadoVenda && !vInp.dataset.touched) vInp.value = OBRA_CALC.numParaCampo(o.valorEstimadoVenda);
-  const venda = parseNum(vInp.value);
-  const meses = Math.max(0, parseInt($('#simMeses').value,10) || 0);
-
-  const alvoISO = OBRA_CALC.addMesesClampado(todayISO(), meses);
-  const bruto = OBRA_CALC.totalBruto(o);
-  const corr  = OBRA_CALC.totalCorrigido(o, taxa(), alvoISO);
-
-  if(venda<=0){
+  /* A conta e os textos: calc.js contaSimulador e textosSimulador (o app nativo usa os mesmos). Os meses param em 120 na
+     conta, mesmo digitados além do teto do campo. A obra com menos de 1 mês fica sem taxa (o % ao mês explodiria), e a TIR
+     passa da taxa do banco exatamente quando a venda passa do corrigido. */
+  const conta = OBRA_CALC.contaSimulador(o, parseNum(vInp.value), parseInt($('#simMeses').value,10) || 0, todayISO(), taxa());
+  if(!conta){
     out.innerHTML = `<div class="panel"><p class="muted-note">Digite o preço de venda pra ver a conta.</p></div>`;
     return;
   }
-  // obra com menos de 1 mês: o % ao mês explode (divide por quase zero) e vira número absurdo
-  const novaDemais = OBRA_CALC.mesesDeObra(o, alvoISO) < 1;
-  // TIR: cada gasto na sua data — passa da taxa do banco exatamente quando venda > corrigido
-  const rate = novaDemais ? null : OBRA_CALC.tirMensal(o.gastos, venda, alvoISO);
-  const acima = OBRA_CALC.rendimentoAcima(rate, taxa());
-  const bate = venda > corr;
-  const mult = (rate!=null && taxa()>0) ? rate/taxa() : 0;
-  const quando = meses===0 ? 'vendendo hoje' : `vendendo daqui a ${meses} ${meses===1?'mês':'meses'}`;
-
-  const rb = OBRA_CALC.resumoVenda(venda, bruto);
-  const rc = OBRA_CALC.resumoVenda(venda, corr);
-  const pct1  = v => v==null ? '—' : v.toFixed(1).replace('.',',')+'%';
-  const taxa2 = v => v==null ? '—' : v.toFixed(2).replace('.',',')+'% a.m.';
-  const din   = v => v==null ? '—' : money(v);
-  const sinal = v => v==null ? '' : (v>=0 ? 'pos' : 'neg');
+  const t = OBRA_CALC.textosSimulador(conta, taxa(), o.areaM2);
+  const cor = s => s ? ` class="${s === 'negativo' ? 'neg' : 'pos'}"` : '';
 
   out.innerHTML = `
-    <div class="card saldo big ${bate?'':'saldo-abaixo'}">
-      <div class="k-label"><span class="k-ic">${ICON(bate?'check':'alerta')}</span> ${bate?'Vale a pena':'Rende menos que o banco'}</div>
-      <div class="layout-45 k-val">${rate!=null ? rate.toFixed(2).replace('.',',')+'% ao mês' : '—'}</div>
-      <div class="k-sub">${quando} · banco paga ${escapeHtml(String(taxa()).replace('.',','))}%${rate!=null && mult>=1 ? ' · rende '+mult.toFixed(1).replace('.',',')+'× o banco' : ''}${novaDemais ? ' · obra com menos de 1 mês — % ao mês ainda não diz muito' : ''}</div>
+    <div class="card saldo big ${conta.vale?'':'saldo-abaixo'}">
+      <div class="k-label"><span class="k-ic">${ICON(conta.vale?'check':'alerta')}</span> ${t.veredito}</div>
+      <div class="layout-45 k-val">${t.taxa}</div>
+      <div class="k-sub">${escapeHtml(t.detalhes.join(' · '))}</div>
     </div>
     <div class="panel">
       <h2 class="layout-28">${ICON('documento')} Relatório da simulação</h2>
       <div class="rep-scroll"><table class="rep-table rep-sim">
         <thead><tr><th></th><th>Pelo bruto</th><th>Pelo corrigido</th></tr></thead>
         <tbody>
-          <tr><td>Custo até a venda</td><td>${money(bruto)}</td><td>${money(corr)}</td></tr>
-          <tr><td>Venda</td><td>${money(venda)}</td><td>${money(venda)}</td></tr>
-          <tr class="rep-total"><td>Lucro</td><td class="${sinal(rb.lucro)}">${din(rb.lucro)}</td><td class="${sinal(rc.lucro)}">${din(rc.lucro)}</td></tr>
-          <tr><td>% sobre o custo</td><td class="${sinal(rb.pctCusto)}">${pct1(rb.pctCusto)}</td><td class="${sinal(rc.pctCusto)}">${pct1(rc.pctCusto)}</td></tr>
-          <tr><td>% sobre a venda</td><td class="${sinal(rb.pctVenda)}">${pct1(rb.pctVenda)}</td><td class="${sinal(rc.pctVenda)}">${pct1(rc.pctVenda)}</td></tr>
-          <tr><td>Rendimento ao mês</td><td>${taxa2(rate)}</td><td>${taxa2(acima)}</td></tr>
-          ${o.areaM2 > 0 ? `<tr><td>Preço por m² (${escapeHtml(String(o.areaM2).replace('.',','))} m²)</td><td>${money(venda/o.areaM2)}</td><td>${money(venda/o.areaM2)}</td></tr>` : ''}
+          ${t.tabela.map(l => `<tr${l.destaque ? ' class="rep-total"' : ''}><td>${escapeHtml(l.rotulo)}</td><td${cor(l.sinalBruto)}>${l.bruto}</td><td${cor(l.sinalCorrigido)}>${l.corrigido}</td></tr>`).join('\n          ')}
         </tbody>
       </table></div>
     </div>`;
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -189,6 +189,51 @@
     };
   }
 
+  /* ---- "Vale a pena?" (app.js simulaCompute): morava no app.js; o app nativo confere a cópia pelos vetores ---- */
+  /* Os meses da venda vão de 0 a 120 na conta, como no campo. */
+  const MESES_SIMULADOR = 120;
+  /* Vender a obra por `venda` daqui a `meses` (inteiro), sem gasto novo até lá: o alvo (hoje + meses), o custo bruto e o
+     corrigido até o alvo, a obra com menos de 1 mês até o alvo (fica sem taxa), a TIR, o acima do banco, o veredito (venda
+     acima do corrigido) e o multiplicador (TIR ÷ taxa; 0 sem TIR). null sem preço. */
+  function contaSimulador(obra, venda, meses, hojeISO, taxaPct){
+    if(venda <= 0) return null;
+    const m = Math.min(MESES_SIMULADOR, Math.max(0, meses));
+    const alvo = addMesesClampado(hojeISO, m);
+    const corr = totalCorrigido(obra, taxaPct, alvo);
+    const novaDemais = mesesDeObra(obra, alvo) < 1;
+    const tir = novaDemais ? null : tirMensal(obra.gastos, venda, alvo);
+    return { venda, meses: m, alvo, bruto: totalBruto(obra), corrigido: corr, novaDemais, tir, acima: rendimentoAcima(tir, taxaPct),
+      vale: venda > corr, multiplicador: tir != null && taxaPct > 0 ? tir / taxaPct : 0 };
+  }
+  /* Os textos do cartão e da tabela, da conta acima. Na tabela, o lucro e as duas porcentagens levam a cor pelo sinal
+     (sinalBruto e sinalCorrigido: 'positivo', 'negativo', ou null sem valor); custo, venda, rendimento e R$/m² não têm cor, e
+     o R$/m² só aparece com área. destaque: a linha do lucro. */
+  function textosSimulador(conta, taxaPct, areaM2){
+    const virgula = (v, casas) => v.toFixed(casas).replace('.', ',');
+    const din = v => v == null ? '—' : money(v);
+    const pct1 = v => v == null ? '—' : virgula(v, 1) + '%';
+    const taxa2 = v => v == null ? '—' : virgula(v, 2) + '% a.m.';
+    const sinal = v => v == null ? null : v >= 0 ? 'positivo' : 'negativo';
+    const linha = (rotulo, bruto, corrigido, [sinalBruto, sinalCorrigido] = [null, null], destaque = false) =>
+      ({ rotulo, bruto, corrigido, sinalBruto, sinalCorrigido, destaque });
+    const rb = resumoVenda(conta.venda, conta.bruto), rc = resumoVenda(conta.venda, conta.corrigido);
+    const detalhes = [conta.meses === 0 ? 'vendendo hoje' : `vendendo daqui a ${conta.meses} ${conta.meses === 1 ? 'mês' : 'meses'}`,
+      `banco paga ${String(taxaPct).replace('.', ',')}%`];
+    if(conta.tir != null && conta.multiplicador >= 1) detalhes.push(`rende ${virgula(conta.multiplicador, 1)}× o banco`);
+    if(conta.novaDemais) detalhes.push('obra com menos de 1 mês — % ao mês ainda não diz muito');
+    const tabela = [
+      linha('Custo até a venda', money(conta.bruto), money(conta.corrigido)),
+      linha('Venda', money(conta.venda), money(conta.venda)),
+      linha('Lucro', din(rb.lucro), din(rc.lucro), [sinal(rb.lucro), sinal(rc.lucro)], true),
+      linha('% sobre o custo', pct1(rb.pctCusto), pct1(rc.pctCusto), [sinal(rb.pctCusto), sinal(rc.pctCusto)]),
+      linha('% sobre a venda', pct1(rb.pctVenda), pct1(rc.pctVenda), [sinal(rb.pctVenda), sinal(rc.pctVenda)]),
+      linha('Rendimento ao mês', taxa2(conta.tir), taxa2(conta.acima)),
+    ];
+    if(areaM2 > 0) tabela.push(linha(`Preço por m² (${String(areaM2).replace('.', ',')} m²)`, money(conta.venda / areaM2), money(conta.venda / areaM2)));
+    return { veredito: conta.vale ? 'Vale a pena' : 'Rende menos que o banco', taxa: conta.tir != null ? virgula(conta.tir, 2) + '% ao mês' : '—',
+      detalhes, tabela };
+  }
+
   /* Série mensal acumulada da obra (pro gráfico de evolução):
      um ponto por mês-calendário, do 1º gasto até o fim da correção
      (hoje ou a venda), cortando no fim de cada mês. Máx 24 últimos. */
@@ -587,7 +632,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, gastoPorTopico, relatorioObra, fimRelatorio, linhaCorrecao, somaSelecao, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, gastoPorTopico, relatorioObra, fimRelatorio, linhaCorrecao, somaSelecao, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, MESES_SIMULADOR, contaSimulador, textosSimulador, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Regerar:

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | grep -E '^ℹ (pass|fail)'
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'warning:|Test run with'
node tests/browser/servidor.cjs > "$TMPDIR/servidor-8123.log" 2>&1 & SERVIDOR=$!
curl -s -o /dev/null --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8123
lsof -nP -iTCP:8123 -sTCP:LISTEN -t | grep -qx "$SERVIDOR" && echo 'a 8123 é deste worktree'
node tests/browser/analise.cjs && node tests/browser/mobile.cjs && node tests/browser/xss.cjs && node tests/browser/ios.cjs && node tests/browser/vidro.cjs
kill $SERVIDOR
```
Expected: `tests/vetores/calc.json: 108 grupos, 1096 casos`; `ℹ pass 407` e `ℹ fail 0`; `✔ Test run with 241 tests in 39 suites passed after 0.211 seconds.` (`SimuladorTests` é nova, com 3), sem nenhum `warning:`; `a 8123 é deste worktree`; as cinco suítes terminam com `ok` (o `mobile.cjs` confere o veredito do simulador no limite do corrigido).

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift app.js calc.js scripts/vetores-calc.mjs tests/browser/analise.cjs tests/vetores/calc.json
git commit -m "feat: conta do simulador no calc.js, com os meses de 0 a 120" -m "A conta do \"Vale a pena?\" (o alvo, o custo bruto e o corrigido até o alvo, a obra com menos de 1 mês sem taxa, a TIR, o acima do banco, o veredito e o multiplicador) e os textos do cartão e da tabela da simulação saem do app.js para o calc.js (contaSimulador e textosSimulador) e entram nos vetores, com a cópia em Swift no núcleo." -m "Os meses ficam entre 0 e 120 na conta, como o Giovani aprovou em 29/10: antes o teto só existia no campo, e 200 meses digitados entravam na conta. Fora isso, o site mostra o mesmo cartão e a mesma tabela, que a suíte analise.cjs confere com a cor pelo sinal."
```

### Task 6: Obras e preço do simulador no calc.js, o preço segue a obra

O resto da regra 6 sai do `renderSimula` e do `simulaCompute` (app.js:1252-1257 e 1267) para o `calc.js`, com o outro alinhamento aprovado pelo Giovani em 29/10 (confirmação 4). As obras (`obrasSimulador`): as não vendidas com gastos, na ordem do documento, como `{id, nome}`; a escolhida continua escolhida enquanto for elegível e, senão (vendida, apagada ou nenhuma escolhida ainda), cai na primeira; `null` sem nenhuma, e o site mostra "— crie uma obra com gastos —". O preço (`precoInicialSimulador`): a venda estimada da obra, ou `null` sem ela (a estimada zero não conta). O alinhamento: enquanto a pessoa não digitou, o campo acompanha a venda estimada da obra escolhida, e fica vazio na obra sem estimada; antes ele só era preenchido vazio, e a segunda obra herdava o preço da primeira (achado 4). Depois de digitar, o preço fica o digitado em qualquer obra, como já era. No app, a mesma regra: o preço digitado, ou o `precoInicialSimulador` da obra escolhida.

**Files:**
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift`
- Modify: `app.js`
- Modify: `calc.js`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift`
- Test (alterar): `scripts/vetores-calc.mjs`
- Test (alterar): `tests/browser/analise.cjs`
- Gerado: `tests/vetores/calc.json` (`node scripts/vetores-calc.mjs`)

**Interfaces:**
- Consumes: `numParaCampo` do `calc.js` (na cola) e o `contaSimulador` da tarefa anterior; no núcleo, `Obra`, `Fase`.
- Produces: `OBRA_CALC.obrasSimulador(obras, escolhidaId)` → `{elegiveis: [{id, nome}], escolhida}` e `OBRA_CALC.precoInicialSimulador(obra)` → número ou `null`. Em Swift: `ObrasDoSimulador` (`elegiveis: [Obra]`, `escolhida: String?`), `obrasSimulador(_:escolhida:)` e `precoInicialSimulador(_:)`.

- [ ] **Step 1: Escrever os testes**

Os vetores cobrem a escolha vazia, a escolhida que continua, a vendida e a apagada que caem na primeira, a ordem do documento contra a do nome, nenhuma elegível e a estimada zero. Na suíte de browser, antes de digitar o preço: as opções, o preço que segue a obra pronta (R$ 100 mil, e não os R$ 450 mil da Casa), o campo vazio na obra sem estimada e a volta à Casa; depois de digitar: o preço que fica ao trocar de obra; e a escolhida que continua ao redesenhar e cai na primeira quando vira vendida.

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift
@@ -37,6 +37,20 @@ struct SimuladorTests {
         #expect(Double(mesesSimulador) == Vetores.casos("calc.MESES_SIMULADOR")[0].saida.comoNumero)
     }
 
+    @Test func obrasDoSimulador() {
+        for c in Vetores.casos("calc.obrasSimulador") {
+            let r = obrasSimulador(c.args[0].obras, escolhida: c.args[1].comoTexto)
+            confere(.objeto(["elegiveis": .lista(r.elegiveis.map { .objeto(["id": .texto($0.id), "nome": .texto($0.nome)]) }),
+                             "escolhida": r.escolhida.map(ValorJSON.texto) ?? .nulo]), c.saida, .exata, c.caso)
+        }
+    }
+
+    @Test func precoInicial() {
+        for c in Vetores.casos("calc.precoInicialSimulador") {
+            confere(opcional(precoInicialSimulador(c.args[0].obra)), c.saida, .exata, c.caso)
+        }
+    }
+
     @Test func contaDoSimulador() {
         for c in Vetores.casos("calc.contaSimulador") {
             let r = contaSimulador(c.args[0].obra, venda: c.args[1].numero, meses: Int(c.args[2].numero), hoje: c.args[3].comoTexto!,
```

Em `scripts/vetores-calc.mjs`:

```diff
--- a/scripts/vetores-calc.mjs
+++ b/scripts/vetores-calc.mjs
@@ -299,6 +299,16 @@ resumo('custo zero', 1000, 0);
 
 /* O "Vale a pena?" (app.js simulaCompute): a conta, com os meses de 0 a 120, e os textos do cartão e da tabela. */
 constante('calc.MESES_SIMULADOR', C.MESES_SIMULADOR);
+const obrasSim = calc('obrasSimulador');
+obrasSim('as não vendidas com gastos, na ordem do documento; sem escolha, a primeira', BLOB.obras, '');
+obrasSim('a escolhida continua escolhida', BLOB.obras, 'o4');
+obrasSim('a vendida não é escolhida: cai na primeira', BLOB.obras, 'o2');
+obrasSim('a apagada cai na primeira', BLOB.obras, 'sumiu');
+obrasSim('a ordem é a do documento, não a do nome', [O4, O3, O2, O1], 'o3');
+obrasSim('nenhuma elegível', [O2, O3], 'o2');
+const precoSim = calc('precoInicialSimulador');
+for(const o of BLOB.obras) precoSim(o.nome, o);
+precoSim('venda estimada zero não conta', { ...O4, valorEstimadoVenda: 0 });
 const contaSim = calc('contaSimulador');
 const OBRA_NOVA = obraDe('nova', [gastoDe('n1', 'terreno', 1000, HOJE)], { dataInicio: HOJE });
 contaSim('vale a pena, vendendo hoje', O1, 1250000, 0, HOJE, 1);
```

Em `tests/browser/analise.cjs`:

```diff
--- a/tests/browser/analise.cjs
+++ b/tests/browser/analise.cjs
@@ -123,6 +123,17 @@ const ZERADA={id:'z',nome:'Obra zerada',dataInicio:'2026-03-01',fase:'construcao
     await page.evaluate(()=>{showView('simula');renderSimula();});
     assert.equal(await page.locator('#simObra').inputValue(),'a');
     assert.equal(await page.locator('#simValor').inputValue(),'450.000,00');
+    // As obras: as não vendidas com gastos, na ordem do documento. Enquanto a pessoa não digitou, o preço acompanha a venda
+    // estimada da obra escolhida (achado 4: a segunda obra herdava o preço da primeira); sem estimada, o campo fica vazio
+    assert.deepEqual(await page.$$eval('#simObra option',os=>os.map(o=>[o.value,o.textContent])),
+      [['a','Casa Alphaville'],['p','Pronta Jardins'],['s','Terreno novo'],['z','Obra zerada']]);
+    await page.locator('#simObra').selectOption('p');
+    assert.equal(await page.locator('#simValor').inputValue(),'100.000,00');
+    await page.locator('#simObra').selectOption('s');
+    assert.equal(await page.locator('#simValor').inputValue(),'');
+    assert.equal(texto(await page.locator('#simOut').textContent()),'Digite o preço de venda pra ver a conta.');
+    await page.locator('#simObra').selectOption('a');
+    assert.equal(await page.locator('#simValor').inputValue(),'450.000,00');
     assert.deepEqual(await cartao(),[false,'Vale a pena','8,63% ao mês','vendendo hoje · banco paga 1% · rende 8,6× o banco']);
     assert.deepEqual(await tabela(),[linha('Custo até a venda','R$ 202.400,50','R$ 222.689,91'),linha('Venda','R$ 450.000,00','R$ 450.000,00'),
       linha('Lucro','R$ 247.599,50','R$ 227.310,09','pos','pos','rep-total'),linha('% sobre o custo','122,3%','102,1%','pos','pos'),
@@ -152,9 +163,20 @@ const ZERADA={id:'z',nome:'Obra zerada',dataInicio:'2026-03-01',fase:'construcao
     // Sem preço, a frase do site e nenhuma conta
     await page.locator('#simValor').fill('0');
     assert.equal(texto(await page.locator('#simOut').textContent()),'Digite o preço de venda pra ver a conta.');
+    // Depois de digitar, o preço fica o digitado, em qualquer obra
+    await page.locator('#simValor').fill('95.000,00');
+    await page.locator('#simObra').selectOption('a');
+    assert.equal(await page.locator('#simValor').inputValue(),'95.000,00');
+    assert.equal((await tabela())[1][2][0],'R$ 95.000,00');
+    // A escolhida continua escolhida ao redesenhar; vendida, cai na primeira elegível
+    await page.locator('#simObra').selectOption('z');
+    await page.evaluate(()=>renderSimula());
+    assert.equal(await page.locator('#simObra').inputValue(),'z');
+    await page.evaluate(()=>{const o=obraById('z');o.fase='vendida';o.venda={valor:1,data:'2026-10-01'};renderSimula();});
+    assert.equal(await page.locator('#simObra').inputValue(),'a');
 
     assert.deepEqual(await page.evaluate(()=>errosAnalise),[]);
     await ctx.close();
-    console.log('ok - análise: gasto por tópico na obra e nos Gráficos; grupos, fim, linha da correção e soma da seleção do relatório; conta e textos do "Vale a pena?"');
+    console.log('ok - análise: gasto por tópico na obra e nos Gráficos; grupos, fim, linha da correção e soma da seleção do relatório; conta, textos, obras e preço do "Vale a pena?"');
   }finally{await browser.close();}
 })().catch(e=>{console.error(e);process.exitCode=1;});
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node scripts/vetores-calc.mjs 2>&1 | grep -m1 Error
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter SimuladorTests 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'SimuladorTests.swift:[0-9:]* error: cannot find [^|]*' | sort -u
node tests/browser/servidor.cjs > "$TMPDIR/servidor-8123.log" 2>&1 & SERVIDOR=$!
curl -s -o /dev/null --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8123
lsof -nP -iTCP:8123 -sTCP:LISTEN -t | grep -qx "$SERVIDOR" && echo 'a 8123 é deste worktree'
node tests/browser/analise.cjs 2>&1 | grep -A5 AssertionError
kill $SERVIDOR
```
Expected: o gerador para com `TypeError: fn is not a function` (sem `obrasSimulador` no `calc.js`); o núcleo não compila: `SimuladorTests.swift:42:21: error: cannot find 'obrasSimulador' in scope` e `SimuladorTests.swift:50:30: error: cannot find 'precoInicialSimulador' in scope`; o servidor sobe: `a 8123 é deste worktree` (sem essa linha, a porta é de outro worktree: pare e combine com quem a usa); a suíte de browser cai no preço da obra pronta:
```
AssertionError [ERR_ASSERTION]: Expected values to be strictly equal:
+ actual - expected

+ '450.000,00'
- '100.000,00'
```

- [ ] **Step 3: Implementar**

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
@@ -1,7 +1,29 @@
 import Foundation
 
-/* O "Vale a pena?", como o calc.js o calcula e escreve (morava no app.js simulaCompute). Conferido pelos vetores do site
-   (SimuladorTests). */
+/* O "Vale a pena?", como o calc.js o calcula e escreve (morava no app.js renderSimula e simulaCompute). Conferido pelos
+   vetores do site (SimuladorTests). */
+
+/// As obras do simulador e a escolhida.
+public struct ObrasDoSimulador: Equatable, Sendable {
+    /// As não vendidas com gastos, na ordem do documento.
+    public let elegiveis: [Obra]
+    /// A escolhida, enquanto elegível; senão, a primeira; nil sem nenhuma.
+    public let escolhida: String?
+}
+
+/// `obrasSimulador` do calc.js.
+public func obrasSimulador(_ obras: [Obra], escolhida: String?) -> ObrasDoSimulador {
+    let elegiveis = obras.filter { $0.fase != .vendida && !$0.gastos.isEmpty }
+    let mantida = elegiveis.contains { $0.id == escolhida } ? escolhida : nil
+    return ObrasDoSimulador(elegiveis: elegiveis, escolhida: mantida ?? elegiveis.first?.id)
+}
+
+/// `precoInicialSimulador` do calc.js: o preço acompanha a venda estimada da obra escolhida enquanto a pessoa não digitou;
+/// nil sem estimada (a zero não conta, como no site).
+public func precoInicialSimulador(_ obra: Obra) -> Double? {
+    guard let estimada = obra.valorEstimadoVenda, estimada != 0 else { return nil }
+    return estimada
+}
 
 /// `MESES_SIMULADOR` do calc.js: os meses da venda vão de 0 a 120 na conta.
 public let mesesSimulador = 120
```

Em `app.js`:

```diff
--- a/app.js
+++ b/app.js
@@ -1234,12 +1234,12 @@ function renderRelatorio(){
 /* ===== SERÁ QUE VALE A PENA? ===== */
 function renderSimula(){
   const sel = $('#simObra');
-  const cands = db.obras.filter(o=>o.fase!=='vendida' && o.gastos.length);
-  const cur = sel.value;
-  sel.innerHTML = cands.length
-    ? cands.map(o=>`<option value="${escapeHtml(o.id)}">${escapeHtml(o.nome)}</option>`).join('')
+  // as obras e a escolhida: calc.js obrasSimulador (o app nativo usa o mesmo)
+  const { elegiveis, escolhida } = OBRA_CALC.obrasSimulador(db.obras, sel.value);
+  sel.innerHTML = elegiveis.length
+    ? elegiveis.map(o=>`<option value="${escapeHtml(o.id)}">${escapeHtml(o.nome)}</option>`).join('')
     : '<option value="">— crie uma obra com gastos —</option>';
-  if(cands.some(o=>o.id===cur)) sel.value = cur;
+  if(escolhida) sel.value = escolhida;
   simulaCompute();
 }
 
@@ -1249,7 +1249,8 @@ function simulaCompute(){
   if(!o){ out.innerHTML = ''; return; }
 
   const vInp = $('#simValor');
-  if(!vInp.value && o.valorEstimadoVenda && !vInp.dataset.touched) vInp.value = OBRA_CALC.numParaCampo(o.valorEstimadoVenda);
+  // enquanto a pessoa não digitou, o preço acompanha a venda estimada da obra escolhida (vazio sem estimada)
+  if(!vInp.dataset.touched) vInp.value = OBRA_CALC.numParaCampo(OBRA_CALC.precoInicialSimulador(o));
   /* A conta e os textos: calc.js contaSimulador e textosSimulador (o app nativo usa os mesmos). Os meses param em 120 na
      conta, mesmo digitados além do teto do campo. A obra com menos de 1 mês fica sem taxa (o % ao mês explodiria), e a TIR
      passa da taxa do banco exatamente quando a venda passa do corrigido. */
```

Em `calc.js`:

```diff
--- a/calc.js
+++ b/calc.js
@@ -190,6 +190,14 @@
   }
 
   /* ---- "Vale a pena?" (app.js simulaCompute): morava no app.js; o app nativo confere a cópia pelos vetores ---- */
+  /* As obras do simulador: as não vendidas com gastos, na ordem do documento ({id, nome}). A escolhida continua escolhida
+     enquanto for elegível; senão, a primeira (null sem nenhuma). */
+  function obrasSimulador(obras, escolhidaId){
+    const elegiveis = obras.filter(o => o.fase !== 'vendida' && o.gastos.length).map(o => ({ id: o.id, nome: o.nome }));
+    return { elegiveis, escolhida: elegiveis.some(o => o.id === escolhidaId) ? escolhidaId : elegiveis.length ? elegiveis[0].id : null };
+  }
+  /* O preço acompanha a venda estimada da obra escolhida enquanto a pessoa não digitou: null sem estimada (a zero não conta). */
+  const precoInicialSimulador = obra => obra.valorEstimadoVenda || null;
   /* Os meses da venda vão de 0 a 120 na conta, como no campo. */
   const MESES_SIMULADOR = 120;
   /* Vender a obra por `venda` daqui a `meses` (inteiro), sem gasto novo até lá: o alvo (hoje + meses), o custo bruto e o
@@ -632,7 +640,7 @@
       ? Object.keys(v).sort().reduce((a, c) => { a[c] = v[c]; return a; }, {}) : v);
   }
 
-  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, gastoPorTopico, relatorioObra, fimRelatorio, linhaCorrecao, somaSelecao, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, MESES_SIMULADOR, contaSimulador, textosSimulador, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
+  const api = { DIAS_MES, LIMITE_BLOB, AVISO_BLOB, tamanhoBlob, blobCabe, erroEhTerminal, proximoBackoff, dataLocalISO, dataISOValida, dataIgualOuDepois, diasEntre, corrigido, totalBruto, totalCorrigido, resumoTopico, gastoPorTopico, relatorioObra, fimRelatorio, linhaCorrecao, somaSelecao, lucroVenda, mesesDeObra, tirMensal, rendimentoAcima, resumoVenda, obrasSimulador, precoInicialSimulador, MESES_SIMULADOR, contaSimulador, textosSimulador, serieEvolucao, serieMensal, serieEvolucaoAgregada, aPagar, textoVencimentos, gastosRecentes, precoPorM2, filtraGastos, contadorLancamentos, mesesDoFiltro, semAcento, normalizaDescricao, distanciaEdicao, sugestoesDescricao, gastoRepetido, lerTaxaCartao, addMesesClampado, gerarParcelas, parcelamentoCartao, fmtDigitado, fmtCompleto, numParaCampo, parseNum, versaoMaior, TOPICOS, orcamentoObra, ORC_PILULA, larguraBarraOrc, fraseTopicoOrc, rodapeOrc, linhaTopicoOrc, somaTopicosOrc, totalPreenchidoOrc, pecasOrcamento, afazeresEmOrdem, contadorDeAfazeres, money, moneyShort, moneyCurto, fmtMeses, canon };
   if (typeof module !== 'undefined' && module.exports) module.exports = api;
   else root.OBRA_CALC = api;
 })(this);
```

Regerar:

```bash
node scripts/vetores-calc.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node scripts/vetores-calc.mjs && npm run test:unit 2>&1 | grep -E '^ℹ (pass|fail)'
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'warning:|Test run with'
node tests/browser/servidor.cjs > "$TMPDIR/servidor-8123.log" 2>&1 & SERVIDOR=$!
curl -s -o /dev/null --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8123
lsof -nP -iTCP:8123 -sTCP:LISTEN -t | grep -qx "$SERVIDOR" && echo 'a 8123 é deste worktree'
node tests/browser/analise.cjs && node tests/browser/mobile.cjs && node tests/browser/xss.cjs && node tests/browser/ios.cjs && node tests/browser/vidro.cjs
kill $SERVIDOR
```
Expected: `tests/vetores/calc.json: 110 grupos, 1107 casos`; `ℹ pass 407` e `ℹ fail 0`; `✔ Test run with 243 tests in 39 suites passed after 0.233 seconds.` (2 novos em `SimuladorTests`), sem nenhum `warning:`; `a 8123 é deste worktree`; as cinco suítes terminam com `ok`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift app.js calc.js scripts/vetores-calc.mjs tests/browser/analise.cjs tests/vetores/calc.json
git commit -m "feat: obras e preço do simulador no calc.js, o preço segue a obra" -m "As obras do \"Vale a pena?\" (as não vendidas com gastos, na ordem do documento; a escolhida continua escolhida enquanto for elegível, senão cai na primeira) e o preço inicial pela venda estimada saem do app.js para o calc.js (obrasSimulador e precoInicialSimulador) e entram nos vetores, com a cópia em Swift no núcleo." -m "O preço passa a acompanhar a venda estimada da obra escolhida enquanto a pessoa não digitou, como o Giovani aprovou em 29/10: antes o campo só era preenchido vazio, e a segunda obra herdava o preço da primeira. Depois de digitar, o preço fica o digitado em qualquer obra."
```

### Task 7: Nova versão do cache offline

O `calc.js` e o `app.js` mudaram nas tarefas anteriores: aparelhos com o site instalado baixam a versão nova em vez de continuar com a guardada. Nenhum arquivo novo na raiz (a suíte nova mora em `tests/browser/`), então o `ASSETS` não muda; o `CACHE` sobe uma vez, de `obras-v71` para `obras-v72`.

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
-const CACHE = 'obras-v71';
+const CACHE = 'obras-v72';
 const ASSETS = ['./vendor/sentry/sentry.js', './sentry-config.js', './sentry.js', './vendor/firebase/firebase-app.js', './vendor/firebase/firebase-auth.js', './vendor/firebase/firebase-firestore.js', './vendor/firebase/shared-VONABDH2.js', './styles.css', './privacidade.css', './dados.js', './cadastro.js', './', './index.html', './app.js', './gestos.js', './push.js', './share.js', './ui-confirm.js', './privacidade.html', './auth.js', './globe.js', './calc.js', './cloud.js', './icons.js', './splash.js', './splash-pre.js', './teclado.js', './tema.js', './nativo.js', './pwa.js', './manifest.json', './apple-touch-icon.png', './icon-192.png', './icon-512.png', './favicon.svg', './google-g.svg', './fontes/hanken-grotesk-800.woff2'];
 
 self.addEventListener('install', e => {
```

- [ ] **Step 2: Ver passar e conferir o PR inteiro**

Run:
```bash
npm run test:unit 2>&1 | grep -E '^ℹ (pass|fail)'
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'warning:|Test run with'
lsof -nP -iTCP:8123 -sTCP:LISTEN || echo 'a 8123 está livre'
npm run test:browser > "$TMPDIR/browser.log" 2>&1; echo "saída $?"; grep -cE '^not ok|Error:' "$TMPDIR/browser.log"; grep 'Script exited' "$TMPDIR/browser.log"
```
Expected: `ℹ pass 407` e `ℹ fail 0`; `✔ Test run with 243 tests in 39 suites passed after 0.277 seconds.`, sem nenhum `warning:`; `a 8123 está livre` (o `rodar.cjs` sobe o próprio servidor, com a CSP aberta para os emuladores, e só espera a 8123 responder: com outro servidor no ar, o dele cai em `EADDRINUSE`, e `sync`, `fase3` e `persistencia` caem; se o `lsof` mostrar um processo, derrube-o antes); depois, em ~3 min 30 s, `saída 0`, `0` (nenhuma suíte cai na rodada inteira de browser, com os emuladores: a `analise.cjs` inclusive, e o `fase3.cjs` marca gastos no Relatório e confere "66,67%") e a linha do fim do script, antes de os emuladores pararem:
```
✔  Script exited successfully (code 0)
```

- [ ] **Step 3: Commit**

```bash
git add sw.js
git commit -m "chore: nova versão do cache offline para as regras da análise" -m "O calc.js e o app.js mudaram: aparelhos com o site instalado baixam a versão nova em vez de continuar com a guardada. Nenhum arquivo novo na raiz, então o ASSETS não muda."
```

**Ponto de controle do PR 0:** na prévia da Vercel, nos dois viewports (393 e 1280), numa obra com gastos: a legenda do donut (7 tópicos, do maior para o menor) e a dos Gráficos (todos); o Relatório inteiro, com o fim (obra com venda estimada, vendida e uma sem as duas), a linha da correção e a soma de dois gastos marcados; no "Vale a pena?", trocar de obra sem digitar o preço (o preço segue a venda estimada, e fica vazio na obra sem estimada), digitar um preço e trocar de novo (fica o digitado), e digitar 200 meses (o cartão diz "vendendo daqui a 120 meses"); na CI, os 10 jobs do `app-ios.yml` verdes, sem rerun. Depois do merge, o site publica os dois alinhamentos; no app, as regras ficam no núcleo, sem tela, até o PR 3a e o 4a.

---

## PR 0b (núcleo): as regras novas do app e a paginação do PDF

Um PR do núcleo, em sete commits, com as regras que o app da etapa 4 tem e o site não: os pedaços do anel e da barra empilhada (6 cores e o "Outros"), com o piso de arco e de largura, o pedaço sob o dedo e o "<1%" (Tarefa 9); a escala redonda, os rótulos dos meses e o mês sob o dedo (Tarefa 10); o mês de referência e o padrão, os meses a vencer, as frases do que ficou fora, o aviso dos 24 meses e a média, o maior e os meses (Tarefa 11); a linha do tópico no Relatório, com "N de M gastos" e a parte com 1 casa (Tarefa 12); e a paginação da tabela do PDF, com as colunas pelo maior valor (Tarefa 13). Por último, uma linha da CI: o teto do job `laudo-etapa3` sobe de 60 para 75 min (Tarefa 14). Antes delas, o achado 2 do PR 0: o `confere` dos testes deixa de aceitar infinito contra número, e o contorno do leitor do simulador sai (Tarefa 8, só teste). Nenhuma regra tem vetor do site, porque o site não as tem: cada uma tem teste próprio, conferido por mutação (66 de 66 mortas). O risco é baixo: tudo é conta pura, sem tela, sem gravação e sem mudança nas regras com vetor; o `anoMes` e o `chaveMes` das séries só deixam de ser privados. Na `main`, as regras ficam sem uso até as telas: a barra no PR 1c, os Gráficos no 2a e no 2b, o Relatório e a busca no 3a e o PDF no 4b. Na CI, o PR roda os 10 jobs do `app-ios.yml`, como o PR 0: o nível "núcleo" da tabela do spec depende do filtro por superfície, que fica para o 4a (decisão do Orquestrador; ver as Decisões). O corpo do PR diz, numa linha, que o PR também sobe o teto do `laudo-etapa3` para 75 min (decisão do Orquestrador em 29/10): é a única mudança fora do núcleo, e o 0b roda todos os jobs e não vai ao site. Um rerun no iOS 26, mesmo num job de tela que este PR não toca, tira o PR do merge automático. No marco 1 deste plano, ele vem depois do 0 e antes do 1a. São 564 linhas de produção (acréscimos + remoções em `CusttaNucleo/Sources/`, pelo `git diff --numstat`), dentro dos ~450–600 da tabela; os testes vão de 243 em 39 suítes para 279 em 44 no `swift test` do núcleo, e o `npm run test:unit` fica em 407.

**Branch:** `feat/regras-novas-do-app-no-nucleo`. **Título:** `feat: regras novas da análise e paginação do PDF no núcleo`.

**De onde o ramo nasce.** O 0b depende do código do 0: a Tarefa 8 altera o `SimuladorTests.swift`, criado na Tarefa 5, e a Tarefa 13 usa o `RelatorioDaObra`, o `relatorioObra`, o `fimRelatorio` e o `duasCasasPtBR` do `Relatorio.swift` (Tarefas 2 a 4). Ele nasce da `main` depois do merge do 0 ou, enquanto o 0 não é mesclado, empilhado no ramo `feat/regras-da-analise-nos-vetores`, com o PR apontando para ele; mesclado o 0, a base do PR vira a `main`, com merge da `main` e sem rebase. Nascido da `main` sem o 0, ele cai já na Tarefa 8.

**Como foi provado.** Cada fatia foi conferida sozinha: os testes da tarefa sobre o commit anterior (o "ver falhar" de cada tarefa é a saída real), o `swift test` inteiro sem aviso e, no fim, o `npm run test:unit`. A mutação trocou um trecho por vez nas regras novas e rodou a suíte da tarefa: 26 de 26 nos pedaços (10 delas na regra do tópico fixo "Outros", de 30/10), 8 de 8 nos eixos, 13 de 13 nos meses, 6 de 6 na linha do tópico e 13 de 13 na paginação; os casos que mataram as que viviam entraram na própria tarefa (o dedo tão perto do topo que a fração arredonda para 1, a potência pelo piso do log, a altura do texto de 3 linhas, a linha mínima e o gasto de várias linhas que cabe numa página nova). Os casos da revisão do plano entraram do mesmo jeito: o tópico de R$ 0 (Tarefa 9), a evolução de 25 meses (Tarefa 11) e a 1ª página da tabela que saía vazia (Tarefa 13). Na Tarefa 8, a mutação "sem guarda da taxa zero" do PR 0 continua morrendo sem o contorno do leitor.

### Mapa de arquivos do PR 0b

- `Pedacos.swift` (novo, 9): `pedacosDoAnel`, `arcosDoAnel`, `pedacoNoAnel`, `largurasDaBarra`, `porcentoDoTopico`, `legendaDaBarra` e os textos dos tópicos.
- `Eixos.swift` (novo, 10): `escalaRedonda`, `rotulosDoEixoX`, `rotuloDoMes`, `mesNaColuna` e `mesNoPonto`.
- `MesesDosGraficos.swift` (novo, 11): `mesDeReferencia`, `mesPadraoDoGastoPorMes`, `mesAVencer`, as frases, o aviso dos 24 meses e `resumoDosMeses`.
- `TopicoNoRelatorio.swift` (novo, 12): `contagemDeGastos`, `parteComUmaCasa` e `linhaDoTopicoNoRelatorio`.
- `PaginacaoDoPDF.swift` (novo, 13): `MedidasDoPDF`, `colunasDoPDF`, `maiorValorDoPDF`, `paginarTabelaDoPDF` e `rodapeDoPDF`.
- `Series.swift` (10 e 11): o `anoMes` e o `chaveMes` deixam de ser privados.
- `.github/workflows/app-ios.yml` (14): o teto do job `laudo-etapa3`, de 60 para 75 min, com o porquê no comentário.
- Testes: `Vetores.swift`, `VetoresTests.swift` e `SimuladorTests.swift` (8); uma suíte nova por tarefa, `PedacosTests` (9), `EixosTests` (10), `MesesDosGraficosTests` (11), `TopicoNoRelatorioTests` (12) e `PaginacaoDoPDFTests` (13).

### Ponto de controle do fim do PR

Não há tela: o ponto de controle é a CI inteira, os 10 jobs do `app-ios.yml` verdes e sem rerun, e, no Mac, `TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo` (279 testes em 44 suítes, nenhum aviso) e `npm run test:unit` (407). Na revisão, vale ler os "Produces" das Tarefas 9 a 13 contra as telas que vão usá-los (1c, 2a, 2b, 3a e 4b): os nomes são os que elas chamam.

### Achados que mudam o spec ou uma decisão

1. **Resolvido em 30/10 (decisão do Giovani): o tópico fixo "Outros" vai sempre para o pedaço cinza, com qualquer número de tópicos; a regra está na Tarefa 9.** O achado era: **o "Outros" do anel bate com o tópico fixo "Outros" (`outros`, Topicos.swift:31).** Numa obra com 8 tópicos ou mais em que o tópico "Outros" está entre os 6 maiores, o anel mostra um "Outros" colorido e o "Outros · N tópicos" cinza. A recomendação valia só com 8 tópicos ou mais; a decisão vale para qualquer número. No marco 2, o estado de poucos tópicos dos Gráficos (a obra `a6`, quadro `est-pequeno` do mockup) mostra o "Outros" cinza no fim, e não como a 4ª cor do mockup: o lado a lado do 2a registra a diferença.
2. **O "<1%" da folha do detalhe e da tela Orçamento.** O spec põe o "<1%" também no "% da obra" da folha (confirmação 7), e a lista "Gasto por tópico" da tela Orçamento usa o mesmo texto (`textoDaParteDaObra`, PecasDaTelaOrcamento.swift:58; a folha, DentroDaObra.swift:192). Trocar aqui mudaria duas telas da etapa 3 e mexeria no app (laudo e comparação). **Decidido pelo Giovani em 30/10: muda junto.** O PR 1c, o primeiro que mostra o "<1%" (na legenda da barra da obra), troca o `textoDaParteDaObra` para receber o bruto e o total e usar o `porcentoDoTopico`, com teste, nas duas telas.
3. **"<0,1%" no Relatório (Tarefa 12).** O spec só diz "com 1 casa"; um tópico com dinheiro mostraria "0,0%", o engano que o "<1%" corrige no anel. **Recomendação:** manter o "<0,1%", como regra deste PR.
4. **A média, o maior e os meses contam do 1º gasto (Tarefa 11).** O spec diz "do 1º gasto até este mês" (confirmação 2); o mockup conta só os meses à vista, os últimos 24. Só muda nas obras com mais de 24 meses. **Recomendação:** ficar com o spec, como está.
5. **O mês a vencer não depende do mês de referência estar na série (Tarefa 11).** O mockup só hachura quando este mês está na série, e a obra só com parcelas futuras sairia sem hachura. **Recomendação:** ficar com o spec ("depois deste mês ou da venda"), como está.
6. **A evolução também é cortada em 24 meses, e o aviso só existe no gasto por mês.** Numa obra parada há tempo, a evolução vai até hoje e é cortada, e o gasto por mês, não. O núcleo dá as duas respostas (`evolucaoFoiCortada` e `gastoPorMesFoiCortado`). **Recomendação:** o PR 2b põe o mesmo aviso embaixo da evolução quando ela foi cortada.
7. **O pedaço sob o ângulo e o mês sob o x entraram aqui.** A linha do 0b na tabela do spec não os cita, mas a "Conta pura" do conselho (item 1) sim, e o pedaço depende dos arcos com o piso. O valor falado, o passo e o descritor do VoiceOver, que o spec também quer em conta pura, ficam para o 2b, com a tela.
8. **As medidas do PDF são as do mockup.** As alturas de linha (15, 20, 22, 18), as margens e a coluna da data vêm do `parte2.js` e do protótipo; o 4b as acerta no desenho (são todas `var` em `MedidasDoPDF`) e confere que o SF Mono tem o mesmo avanço no peso das linhas de total e de tópico, que o `maiorValorDoPDF` supõe.
9. **Dois detalhes do mockup que a regra do núcleo deixou iguais:** a barra empilhada tira o piso do maior pedaço, como o anel (o mockup usa o `flex` do CSS, que tira de todos; a diferença não se vê), e a evolução de um mês só leva o ano no rótulo, como o gasto por mês. O "e mais 1 tópico" vai no singular.
10. **O tópico de R$ 0 fica sem pedaço (Tarefa 9, revisão do plano).** O `positivo` do `dados.js` aceita o gasto de R$ 0, e o piso dava a esse tópico um pedaço colorido de "0%", tirado do maior. Agora ele fica sem arco, sem largura e sem vão, como o arco de comprimento 0 do site, e continua na legenda com "0%". Não muda o spec: o piso é para o "tópico pequeno".

### Task 8: O confere do núcleo reprova infinito contra número

Achado 2 do PR 0. A tolerância `.continua` do `confere` (Vetores.swift:71) aceita `abs(a − b) ≤ 1e-9 × max(|a|, |b|)`; com um lado infinito, o lado direito também vira infinito e a comparação passa contra qualquer número. Um multiplicador infinito do simulador (TIR ÷ taxa zero) passaria contra o 0 do site, e a Tarefa 5 (PR 0) contornou com um `#expect(… isFinite …)` no leitor (SimuladorTests.swift:59-60). A regra nova: no `.continua`, se um dos lados não é finito, só vale a igualdade exata (infinito com o mesmo infinito; NaN com nada). O integer exato e a tolerância relativa dos números finitos não mudam. O contorno do leitor sai, porque a mutação que tira a guarda da taxa zero (`multiplicador: tir.map { $0 / taxa }`) passa a morrer pelo `confere`. A tarefa só mexe em teste: zero linha de produção.

**Files:**
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Vetores.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/VetoresTests.swift`

**Interfaces:**
- Consumes: `confere(_:_:_:_:)` e `Tolerancia` (Vetores.swift, só nos testes).
- Produces: nada novo; o `confere` reprova `.continua` quando só um lado não é finito.

- [ ] **Step 1: Escrever o teste e a correção**

O teste prende os dois lados (infinito obtido e infinito esperado), o menos infinito e o NaN, cada um num `withKnownIssue`, que falha quando o `confere` não acusa nada; e confere que infinito contra o mesmo infinito, a soma `0,1 + 0,2` contra `0,3` e o inteiro exato continuam passando. A correção é a linha nova no `confere`; o leitor do simulador perde o contorno.

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift
@@ -56,8 +56,6 @@ struct SimuladorTests {
             let r = contaSimulador(c.args[0].obra, venda: c.args[1].numero, meses: Int(c.args[2].numero), hoje: c.args[3].comoTexto!,
                                    taxa: c.args[4].numero)
             confere(r?.json ?? .nulo, c.saida, .continua, c.caso)
-            // A tolerância relativa deixa passar infinito contra 0 (o confere): sem taxa, o multiplicador é 0, nunca TIR ÷ 0.
-            #expect(r.map { $0.multiplicador.isFinite } ?? true, "\(c.caso): multiplicador infinito")
         }
     }
 
```

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Vetores.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Vetores.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Vetores.swift
@@ -67,7 +67,8 @@ func confere(_ obtido: ValorJSON, _ esperado: ValorJSON, _ tolerancia: Toleranci
         let ok: Bool = switch tolerancia {
         case .exata: a == b
         case .dinheiro: abs(a - b) < 0.005
-        case .continua where a.isFinite && b.isFinite && a.rounded() == a && b.rounded() == b: a == b   // inteiro dos dois lados: exato, como no site
+        case .continua where !a.isFinite || !b.isFinite: a == b   // infinito só bate com ele mesmo, e NaN com nada
+        case .continua where a.rounded() == a && b.rounded() == b: a == b   // inteiro dos dois lados: exato, como no site
         case .continua: a == b || abs(a - b) <= max(1e-9 * max(abs(a), abs(b)), 1e-12)   // piso: perto de zero o relativo não fecha
         }
         #expect(ok, "\(onde): obtido \(a), esperado \(b)", sourceLocation: sourceLocation)
```

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/VetoresTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/VetoresTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/VetoresTests.swift
@@ -17,4 +17,16 @@ struct VetoresTests {
         #expect(v.comoObjeto?["a"]?.comoLista?.count == 6)
         #expect(ValorJSON.texto("x").comoNumero == nil)
     }
+
+    /// A tolerância relativa do `.continua` multiplica pelo maior lado: com um lado infinito, ela vira infinito e aceitava
+    /// qualquer número do outro lado (o multiplicador TIR ÷ 0 passava contra o 0 do site).
+    @Test func continuaReprovaQuandoSoUmLadoNaoEFinito() {
+        withKnownIssue("infinito contra zero") { confere(.numero(.infinity), .numero(0), .continua, "∞ × 0") }
+        withKnownIssue("menos infinito contra número") { confere(.numero(-.infinity), .numero(2.5), .continua, "-∞ × 2,5") }
+        withKnownIssue("número contra infinito") { confere(.numero(1e300), .numero(.infinity), .continua, "1e300 × ∞") }
+        withKnownIssue("NaN contra número") { confere(.numero(.nan), .numero(0), .continua, "NaN × 0") }
+        confere(.numero(.infinity), .numero(.infinity), .continua, "∞ × ∞")
+        confere(.numero(0.1 + 0.2), .numero(0.3), .continua, "a tolerância relativa continua")
+        confere(.numero(2), .numero(2), .continua, "inteiro exato")
+    }
 }
```

- [ ] **Step 2: Ver falhar sem a correção**

Run:
```bash
git stash push -q -- app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Vetores.swift
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter VetoresTests 2>&1 | grep -E 'Known issue was not recorded|Test run with'
git stash pop -q
```
Expected: com o `confere` antigo, três dos quatro `withKnownIssue` não veem falha (o NaN já falhava):
```
✘ Test continuaReprovaQuandoSoUmLadoNaoEFinito() recorded an issue at VetoresTests.swift:24:23: Known issue was not recorded
✘ Test continuaReprovaQuandoSoUmLadoNaoEFinito() recorded an issue at VetoresTests.swift:25:23: Known issue was not recorded
✘ Test continuaReprovaQuandoSoUmLadoNaoEFinito() recorded an issue at VetoresTests.swift:26:23: Known issue was not recorded
✘ Test run with 3 tests in 1 suite failed after 0.091 seconds with 4 issues (including 1 known issue).
```

- [ ] **Step 3: Ver passar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | tail -1
```
Expected: `━ Test run with 244 tests in 39 suites passed after 0.236 seconds with 4 known issues.` (1 teste novo em `VetoresTests`; os 4 "known issues" são os do teste novo, que o Swift Testing conta como esperados).

- [ ] **Step 4: Conferir que o contorno sobrava**

A mutação "sem guarda da taxa zero" do PR 0 troca `multiplicador: tir.map { taxa > 0 ? $0 / taxa : 0 } ?? 0)` por `multiplicador: tir.map { $0 / taxa } ?? 0)` em `Simulador.swift`. Sem o `isFinite` do leitor, ela precisa morrer pelo `confere`.

Run:
```bash
sed -i '' 's|multiplicador: tir.map { taxa > 0 ? $0 / taxa : 0 } ?? 0)|multiplicador: tir.map { $0 / taxa } ?? 0)|' app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter SimuladorTests 2>&1 | grep -E 'recorded an issue|Test run with'
git checkout -- app-ios/CusttaNucleo/Sources/CusttaNucleo/Simulador.swift
```
Expected: o caso da taxa zero cai no `confere` do leitor, e o arquivo volta ao original:
```
✘ Test contaDoSimulador() recorded an issue at SimuladorTests.swift:58:20: Expectation failed: ok
✘ Test run with 5 tests in 1 suite failed after 0.084 seconds with 1 issue.
```

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SimuladorTests.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Vetores.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/VetoresTests.swift
git commit -m "test: confere do núcleo reprova infinito contra número" -m "A tolerância contínua do confere multiplica a margem relativa pelo maior lado. Com um lado infinito, a margem também virava infinito e aceitava qualquer número do outro lado: um multiplicador TIR ÷ 0 do simulador passaria contra o 0 do site, e o PR anterior contornou isso com um isFinite no leitor." -m "Agora infinito só bate com o mesmo infinito, e NaN com nada. O teste novo prova os dois lados com withKnownIssue. O contorno do leitor do simulador sai, porque o confere já reprova o multiplicador infinito."
```

### Task 9: Pedaços do anel e da barra, com o piso e o "<1%"

Regra nova do app, sem vetor do site (spec, "Regras novas do app" e "### 1. Gráficos", conta pura), para o anel dos Gráficos (PR 2a), a barra empilhada da obra (PR 1c) e o anel da página 1 do PDF (PR 4b). O site dá uma cor por tópico e repete as 8 do 9º em diante (`PIE[i % PIE.length]`, app.js:8, 530 e 1040); o app tem 6 cores e o "Outros" em cinza. A regra, sobre a lista do `gastoPorTopico` (do maior para o menor), chamando de comuns os tópicos que não são o fixo "Outros" (id `outros`, o último de `topicosPadrao`): os 6 maiores comuns ganham as cores 0 a 5, na ordem, e o resto vai para um pedaço cinza, sempre por último e na mesma ordem. Com um tópico só, o cinza é o próprio tópico, com o nome dele (`outros: false`); com dois ou mais, é o "Outros", que junta os tópicos e soma o bruto deles na ordem (`outros: true`). Sem o fixo, é o que o mockup faz (`parte1.js:57-67`): até 7 tópicos, um pedaço por tópico, com o 7º em cinza; com 8 ou mais, os 6 maiores e o "Outros". O fixo vai sempre para o cinza, mesmo quando é o maior tópico (decisão do Giovani de 30/10; com os 6 maiores quaisquer, numa obra de 8 tópicos ou mais, o "Outros" da pessoa podia sair colorido ao lado do "Outros · N tópicos" cinza): com até 6 comuns, ele fica sozinho no cinza, e a legenda mostra "Outros", não "Outros · 1 tópico"; com 7 comuns ou mais, ele entra no "Outros" no lugar dele da ordem e conta no N. A obra só com o fixo tem o anel todo cinza. O piso: o pedaço com menos de 10 pt de arco (medidos na circunferência do meio do aro) sobe para 10 pt, e o que ele ganhou sai do maior (no empate, o primeiro, o `indexOf(Math.max(…))` do mockup); na barra, o piso é de 8 pt de largura, depois de tirar os vãos de 3 pt (12 e 4 pt na letra máxima, `parte1.css:209-210`), e a mesma regra vale (o mockup usa o `flex` do CSS, que tira de todos; a diferença não se vê). Quando o maior desceria abaixo do piso, que é quando o piso de todos não cabe, ou sem bruto, ou sem largura, as partes ficam iguais (zero na barra sem largura, o 1º quadro do `GeometryReader`). O tópico de bruto zero (um gasto de R$ 0, que o `positivo` do `dados.js` aceita, como o "Brinde" da suíte de browser do PR 0) fica sem pedaço: parte 0, sem piso, sem largura e sem vão na barra, fora das partes iguais e nunca sob o dedo; só a obra sem bruto nenhum divide tudo igual. É o que o site mostra: ele desenha o arco desse tópico com comprimento 0 (`bruto/total*C`, app.js:529 e 1039), e o piso do spec é para o "tópico pequeno" (spec, "Decisões tomadas por recomendação"), não para o vazio; com o piso, o anel ganharia um pedaço colorido de R$ 0,00 com "0%", tirado do maior. Na legenda, o tópico continua, com "0%", como na legenda do site (decisão da revisão do plano). Os arcos vão do topo no sentido do relógio, e o último termina em 1. O pedaço sob o dedo é o arco que contém o ângulo do ponto (o "pedaço mais perto do dedo" do Croqui); quem decide se o dedo está na faixa de 44 pt é a tela. O % é o `Math.round(bruto / total × 100)` do site (o do detalhe do tópico), sem casa decimal no meio do anel (spec, "Deste spec"), e "<1%" quando o verdadeiro fica entre 0 e 1 (o site mostraria 0% ou 1%); sem total, "0%". O VoiceOver lê o "<1%" como "menos de 1%", como o rótulo do mockup e sem depender do nível de pontuação: o `porcentoFalado` troca o "<1%" de um texto e serve ao % sozinho (a barra, Tarefa 22) e à frase com ele ("<1% da obra" na lista e no detalhe do tópico, Tarefa 26). Os textos novos: "Outros · N tópicos" e "e mais N tópicos" (com "1 tópico" no singular, que o mockup não trata).

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Pedacos.swift`
- Test (novo): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PedacosTests.swift`

**Interfaces:**
- Consumes: `GastoDoTopico` e `gastoPorTopico(_:hoje:taxaMensal:)` (DentroDaObra.swift), `numeroJS` e `arredondarJS` (já existem).
- Produces: `coresDoAnel` (6), `pisoDoArco` (10), `pisoDaBarra` (8), `vaoDaBarra` (3); `PedacoDoAnel` (`topicos: [GastoDoTopico]`, `bruto`, `cor: Int?`, `outros: Bool`) e `pedacosDoAnel(_ topicos: [GastoDoTopico]) -> [PedacoDoAnel]`; `ArcoDoPedaco` (`inicio`, `fim`) e `arcosDoAnel(_:circunferencia:piso:) -> [ArcoDoPedaco]`; `fracaoNoAnel(x:y:) -> Double` e `pedacoNoAnel(x:y:arcos:) -> Int?` (x e y a partir do centro, y para baixo); `largurasDaBarra(_:largura:piso:vao:) -> [Double]`; `porcentoDoTopico(_ bruto: Double, total: Double) -> String`; `porcentoFalado(_ texto: String) -> String`; `contagemDeTopicos(_:) -> String`; `rotuloDoOutros(_:) -> String`; `LegendaDaBarra` (`pedacos`, `mais: String?`) e `legendaDaBarra(_:quantos:) -> LegendaDaBarra`. Internas: `idDoOutrosFixo` ("outros"), `temPedaco(_:)` e `partesComPiso(_:comprimento:piso:)`.

- [ ] **Step 1: Escrever os testes**

Os testes prendem os pedaços com 1, 7, 8 e 14 tópicos (cores, "Outros" e a soma dele na ordem), o fixo "Outros" sempre no cinza (o maior, no meio e o menor, com 3, 7 e 8 tópicos; no meio dos que o "Outros" junta, com 10; sozinho), com o rótulo e o "e mais N tópicos" contando com ele, o piso que sai do maior e o empate do maior, o tópico de bruto zero (sem arco, sem largura e sem vão, fora das partes iguais e nunca sob o dedo), as partes iguais (sem bruto, sem comprimento, piso que não cabe, maior que desceria abaixo do piso, barra sem largura), a barra nas duas letras, o pedaço sob o dedo nos quatro pontos cardeais, na divisa entre dois arcos e tão perto do topo que a fração arredonda para 1, e os textos com o singular e o "menos de 1%" falado (sozinho, na frase e no meio dela). Mutações no clone: sem o tratamento do fixo, com o fixo pelo nome, o fixo no fim do cinza fora da ordem, os 6 primeiros de todos sem o fixo, 7 cores, o "Outros" com 1 ou com 3 tópicos, o cinza primeiro e o falado só no "<1%" sozinho ou sem troca: as 10 morrem.

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PedacosTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/* Os pedaços do anel dos Gráficos e da barra empilhada da obra (regra do app, sem vetor do site): até 7 tópicos, um pedaço
   cada; com 8 ou mais, os 6 maiores e "Outros"; o fixo "Outros" sempre no cinza; o piso de arco e de largura; o pedaço sob
   o dedo; o "<1%" e o "menos de 1%" falado. */
struct PedacosTests {
    /// Tópicos já na ordem do `gastoPorTopico` (do maior para o menor), com ids t1, t2…
    func topicos(_ brutos: [Double]) -> [GastoDoTopico] {
        brutos.enumerated().map { i, b in GastoDoTopico(id: "t\(i + 1)", bruto: b, pct: 0) }
    }

    func perto(_ a: [Double], _ b: [Double]) -> Bool {
        a.count == b.count && zip(a, b).allSatisfy { abs($0 - $1) < 1e-12 }
    }

    @Test func umPedacoPorTopicoAteSete() {
        let um = pedacosDoAnel(topicos([500]))
        #expect(um == [PedacoDoAnel(topicos: topicos([500]), bruto: 500, cor: 0, outros: false)])
        let sete = pedacosDoAnel(topicos([70, 60, 50, 40, 30, 20, 10]))
        #expect(sete.map(\.cor) == [0, 1, 2, 3, 4, 5, nil])
        #expect(sete.map(\.outros) == [false, false, false, false, false, false, false])
        #expect(sete.map { $0.topicos.map(\.id) } == [["t1"], ["t2"], ["t3"], ["t4"], ["t5"], ["t6"], ["t7"]])
        #expect(pedacosDoAnel([]).isEmpty)
    }

    @Test func oitoOuMaisViramSeisEOutros() {
        let oito = pedacosDoAnel(topicos([80, 70, 60, 50, 40, 30, 20, 10]))
        #expect(oito.count == 7)
        #expect(oito.map(\.cor) == [0, 1, 2, 3, 4, 5, nil])
        #expect(oito.map(\.outros) == [false, false, false, false, false, false, true])
        #expect(oito[6].topicos.map(\.id) == ["t7", "t8"])
        #expect(oito[6].bruto == 30)
        let quatorze = pedacosDoAnel(topicos((1...14).map { Double(15 - $0) * 1000.25 }))
        #expect(quatorze.count == 7)
        #expect(quatorze[6].topicos.map(\.id) == ["t7", "t8", "t9", "t10", "t11", "t12", "t13", "t14"])
        #expect(quatorze[6].bruto == [8.0, 7, 6, 5, 4, 3, 2, 1].map { $0 * 1000.25 }.reduce(0, +))
        #expect(quatorze[5].topicos.map(\.id) == ["t6"])
    }

    /// `total` tópicos já na ordem do `gastoPorTopico` (brutos de 10 × `total` a 10), com o fixo "Outros" (id `outros`) na
    /// posição dada (0 é o maior) e os comuns c1, c2… nas outras.
    func comOFixo(total: Int, em posicao: Int) -> [GastoDoTopico] {
        var comum = 0
        return (0..<total).map { i in
            let bruto = Double(total - i) * 10
            if i == posicao { return GastoDoTopico(id: "outros", bruto: bruto, pct: 0) }
            comum += 1
            return GastoDoTopico(id: "c\(comum)", bruto: bruto, pct: 0)
        }
    }

    @Test func oFixoComAteSeisComunsFicaSozinhoNoCinza() {
        // O maior, no meio e o menor: os comuns ganham as cores, e o fixo vai para o fim, cinza e com o nome dele.
        for (total, posicoes) in [(3, [0, 1, 2]), (7, [0, 3, 6])] {
            for p in posicoes {
                let pedacos = pedacosDoAnel(comOFixo(total: total, em: p))
                let comuns = (1..<total).map { ["c\($0)"] }
                #expect(pedacos.map { $0.topicos.map(\.id) } == comuns + [["outros"]], "\(total) tópicos, o fixo em \(p)")
                #expect(pedacos.map(\.cor) == Array(0..<total - 1) + [nil], "\(total) tópicos, o fixo em \(p)")
                #expect(pedacos.allSatisfy { !$0.outros }, "\(total) tópicos, o fixo em \(p)")
                #expect(pedacos.last?.bruto == Double(total - p) * 10, "\(total) tópicos, o fixo em \(p)")
            }
        }
        // Só o fixo: o anel inteiro cinza.
        #expect(pedacosDoAnel(comOFixo(total: 1, em: 0)) == [PedacoDoAnel(topicos: comOFixo(total: 1, em: 0), bruto: 10, cor: nil, outros: false)])
    }

    @Test func oFixoComSeteComunsOuMaisEntraNoOutros() {
        // 7 comuns + o fixo: os 6 maiores comuns coloridos e, por último, o "Outros" com o 7º comum e o fixo, do maior para o
        // menor, mesmo quando o fixo é o maior.
        for (p, juntos) in [(0, ["outros", "c7"]), (3, ["outros", "c7"]), (7, ["c7", "outros"])] {
            let pedacos = pedacosDoAnel(comOFixo(total: 8, em: p))
            #expect(pedacos.count == 7, "o fixo em \(p)")
            #expect(pedacos.prefix(6).map { $0.topicos.map(\.id) } == (1...6).map { ["c\($0)"] }, "o fixo em \(p)")
            #expect(pedacos.map(\.cor) == [0, 1, 2, 3, 4, 5, nil], "o fixo em \(p)")
            #expect(pedacos.map(\.outros) == [false, false, false, false, false, false, true], "o fixo em \(p)")
            #expect(pedacos[6].topicos.map(\.id) == juntos, "o fixo em \(p)")
            #expect(pedacos[6].bruto == Double(8 - p) * 10 + (p == 7 ? 20 : 10), "o fixo em \(p)")
            #expect(rotuloDoOutros(pedacos[6]) == "Outros · 2 tópicos", "o fixo em \(p)")
        }
        // O fixo no meio dos que o "Outros" junta fica no lugar dele, e conta no rótulo e no "e mais".
        let dez = pedacosDoAnel(comOFixo(total: 10, em: 7))
        #expect(dez[6].topicos.map(\.id) == ["c7", "outros", "c8", "c9"])
        #expect(rotuloDoOutros(dez[6]) == "Outros · 4 tópicos")
        #expect(legendaDaBarra(dez, quantos: 4).mais == "e mais 6 tópicos")
    }

    @Test func pisoDeArcoSaiDoMaior() {
        // Num anel de 1.000 pt e piso de 10 pt (1%), os dois pedaços de 0,5% sobem para 1%, e o 1% que eles ganham sai do maior.
        let arcos = arcosDoAnel(pedacosDoAnel(topicos([900, 90, 5, 5])), circunferencia: 1000, piso: 10)
        #expect(perto(arcos.map(\.inicio), [0, 0.89, 0.98, 0.99]))
        #expect(perto(arcos.map(\.fim), [0.89, 0.98, 0.99, 1]))
        // No empate do maior, o primeiro perde.
        let empate = arcosDoAnel(pedacosDoAnel(topicos([495, 495, 5, 5])), circunferencia: 1000, piso: 10)
        #expect(perto(empate.map(\.fim), [0.485, 0.98, 0.99, 1]))
        // Com o piso do anel de verdade (10 pt numa circunferência de 2π × 100), o pequeno fica com 10 pt de arco.
        let anel = arcosDoAnel(pedacosDoAnel(topicos([999, 1])), circunferencia: 2 * Double.pi * 100)
        #expect(abs((anel[1].fim - anel[1].inicio) * 2 * Double.pi * 100 - 10) < 1e-9)
        #expect(anel[1].fim == 1)
        // O tópico de bruto zero (um gasto de R$ 0) fica sem arco e sem piso, como o arco de comprimento 0 do site.
        let zero = arcosDoAnel(pedacosDoAnel(topicos([900, 100, 0])), circunferencia: 1000, piso: 10)
        #expect(perto(zero.map(\.inicio), [0, 0.9, 1]))
        #expect(perto(zero.map(\.fim), [0.9, 1, 1]))
    }

    @Test func pisoQueNaoCabeDeixaTudoIgual() {
        // Sem bruto (gastos de valor zero), sem comprimento e quando o piso de todos passa do comprimento, as partes ficam iguais.
        #expect(perto(arcosDoAnel(pedacosDoAnel(topicos([0, 0])), circunferencia: 1000).map(\.fim), [0.5, 1]))
        #expect(perto(arcosDoAnel(pedacosDoAnel(topicos([3, 1])), circunferencia: 0).map(\.fim), [0.5, 1]))
        #expect(perto(largurasDaBarra(pedacosDoAnel(topicos([90, 9, 1])), largura: 30, piso: 8, vao: 3), [8, 8, 8]))
        #expect(largurasDaBarra(pedacosDoAnel(topicos([90, 9, 1])), largura: 5) == [0, 0, 0])
        // Com 4 pt a mais, o piso já cabe: os dois pequenos ficam com 8 pt, e o maior, com o resto.
        #expect(perto(largurasDaBarra(pedacosDoAnel(topicos([90, 9, 1])), largura: 34, piso: 8, vao: 3), [12, 8, 8]))
        // O maior não desce abaixo do piso: com 4 pedaços grandes e 3 pequenos num piso de 7%, a conta tiraria demais dele.
        let apertado = partesComPiso([25, 25, 25, 24.97, 0.01, 0.01, 0.01], comprimento: 100, piso: 7)
        #expect(perto(apertado, Array(repeating: 1.0 / 7, count: 7)))
        // As partes iguais ficam só entre os tópicos com bruto: o de bruto zero continua sem arco.
        #expect(perto(arcosDoAnel(pedacosDoAnel(topicos([3, 1, 0])), circunferencia: 0).map(\.fim), [0.5, 1, 1]))
    }

    @Test func barraComVaosEPiso() {
        let pedacos = pedacosDoAnel(topicos([700, 200, 95, 5]))
        let larguras = largurasDaBarra(pedacos, largura: 309)
        // 309 − 3 vãos de 3 pt = 300 pt para os pedaços; o de 5 (1,5 pt) sobe para 8, e os 6,5 pt saem do maior.
        #expect(perto(larguras, [203.5, 60, 28.5, 8]))
        // Na letra máxima, o piso e o vão crescem.
        #expect(perto(largurasDaBarra(pedacos, largura: 412, piso: 12, vao: 4), [270, 80, 38, 12]))
        #expect(largurasDaBarra([], largura: 300).isEmpty)
        // O pedaço de bruto zero fica sem largura e sem vão: 303 − 1 vão de 3 pt = 300 pt para os dois com bruto.
        #expect(perto(largurasDaBarra(pedacosDoAnel(topicos([900, 100, 0])), largura: 303), [270, 30, 0]))
    }

    @Test func pedacoSobODedo() {
        let arcos = [ArcoDoPedaco(inicio: 0, fim: 0.5), ArcoDoPedaco(inicio: 0.5, fim: 0.75), ArcoDoPedaco(inicio: 0.75, fim: 1)]
        #expect(pedacoNoAnel(x: 0, y: -100, arcos: arcos) == 0)        // topo
        #expect(pedacoNoAnel(x: 100, y: 0, arcos: arcos) == 0)         // direita: 1/4 da volta
        #expect(pedacoNoAnel(x: 0, y: 100, arcos: arcos) == 1)         // embaixo: metade, o começo do 2º
        #expect(pedacoNoAnel(x: -100, y: 0, arcos: arcos) == 2)        // esquerda: 3/4, o começo do 3º
        #expect(pedacoNoAnel(x: -1, y: -100, arcos: arcos) == 2)       // logo antes do topo
        #expect(pedacoNoAnel(x: -1e-20, y: -100, arcos: arcos) == 2)   // tão perto do topo que a fração arredonda para 1
        #expect(pedacoNoAnel(x: 0, y: -100, arcos: []) == nil)
        // O arco vazio do tópico de bruto zero, no fim, nunca fica sob o dedo, nem no topo.
        let comZero = [ArcoDoPedaco(inicio: 0, fim: 0.9), ArcoDoPedaco(inicio: 0.9, fim: 1), ArcoDoPedaco(inicio: 1, fim: 1)]
        #expect(pedacoNoAnel(x: -1e-20, y: -100, arcos: comZero) == 1)
        #expect(abs(fracaoNoAnel(x: 1, y: 1) - 0.375) < 1e-15)      // embaixo, à direita
    }

    @Test func porcentoComMenosDeUm() {
        #expect(porcentoDoTopico(380, total: 1000) == "38%")
        #expect(porcentoDoTopico(125, total: 1000) == "13%")          // o Math.round do site: o meio sobe
        #expect(porcentoDoTopico(4, total: 1000) == "<1%")            // o site diria 0%
        #expect(porcentoDoTopico(7, total: 1000) == "<1%")            // o site diria 1%
        #expect(porcentoDoTopico(10, total: 1000) == "1%")
        #expect(porcentoDoTopico(996, total: 1000) == "100%")
        #expect(porcentoDoTopico(0, total: 1000) == "0%")
        #expect(porcentoDoTopico(0, total: 0) == "0%")
    }

    @Test func porcentoFaladoSemOSinal() {
        // O VoiceOver lê o "<1%" como "menos de 1%", sozinho (a barra) e na frase (a lista e o detalhe do tópico).
        #expect(porcentoFalado(porcentoDoTopico(4, total: 1000)) == "menos de 1%")
        #expect(porcentoFalado("<1% da obra") == "menos de 1% da obra")
        #expect(porcentoFalado("3 gastos · <1% da obra") == "3 gastos · menos de 1% da obra")
        #expect(porcentoFalado("38%") == "38%")
        #expect(porcentoFalado("1 gasto · 1% da obra") == "1 gasto · 1% da obra")
    }

    @Test func textosDosTopicos() {
        #expect(contagemDeTopicos(1) == "1 tópico")
        #expect(contagemDeTopicos(14) == "14 tópicos")
        let pedacos = pedacosDoAnel(topicos((1...14).map { Double(15 - $0) }))
        #expect(rotuloDoOutros(pedacos[6]) == "Outros · 8 tópicos")
        let legenda = legendaDaBarra(pedacos, quantos: 4)
        #expect(legenda.pedacos.map { $0.topicos[0].id } == ["t1", "t2", "t3", "t4"])
        #expect(legenda.mais == "e mais 10 tópicos")
        #expect(legendaDaBarra(pedacos, quantos: 3).mais == "e mais 11 tópicos")
        #expect(legendaDaBarra(pedacosDoAnel(topicos([5, 4, 3, 2, 1])), quantos: 4).mais == "e mais 1 tópico")
        #expect(legendaDaBarra(pedacosDoAnel(topicos([4, 3, 2, 1])), quantos: 4).mais == nil)
        #expect(legendaDaBarra(pedacosDoAnel(topicos([2, 1])), quantos: 4).pedacos.count == 2)
    }
}
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter PedacosTests 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'PedacosTests.swift:[0-9:]* error: cannot find [^|]*' | sort -t: -k2,2n -u | head -3
```
Expected: o núcleo não compila:
```
PedacosTests.swift:18:18: error: cannot find 'pedacosDoAnel' in scope
PedacosTests.swift:19:24: error: cannot find 'PedacoDoAnel' in scope
PedacosTests.swift:20:20: error: cannot find 'pedacosDoAnel' in scope
```
Com o `Pedacos.swift` da regra de antes (os 6 maiores quaisquer) e o teste `porcentoFaladoSemOSinal` fora do arquivo (sem a função, ele não compila), os dois testes do fixo reprovam, pelo mesmo `TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter PedacosTests 2>&1 | tail -5`: `✘ Test run with 10 tests in 1 suite failed after 0.002 seconds with 18 issues.` Os 3 tópicos com o fixo em qualquer lugar, os 7 e os 8 com ele no 1º ou no 4º e a obra só com ele; os 7 e os 8 com ele no fim e os 10 já davam o mesmo.

- [ ] **Step 3: Implementar**

O cinza é o que sobra dos 6 maiores comuns, tirado por índice e na ordem da entrada; o fixo não precisa de caso à parte. O `for … where` do piso é um filtro de propósito: todo pedaço pequeno sobe, não só os primeiros. O `max(by:)` devolve o primeiro no empate.

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/Pedacos.swift`:

```swift
import Foundation

/* Os pedaços do anel dos Gráficos e da barra empilhada da obra: regra do app, sem vetor do site (spec da etapa 4, "Regras
   novas do app"). O site dá uma cor por tópico e repete depois da 8ª; o app tem 6 cores e o "Outros" em cinza, onde o
   tópico fixo "Outros" sempre fica (decisão do Giovani de 30/10). O pedaço pequeno ganha um piso de arco (anel) ou de
   largura (barra), tirado do maior; o % mostrado é o verdadeiro, com "<1%". */

/// Quantas cores o anel tem. O pedaço depois delas é cinza: o "Outros", ou o tópico que fica sozinho no cinza.
public let coresDoAnel = 6

/// O id do tópico fixo "Outros" (o último de `topicosPadrao`), que vai sempre para o pedaço cinza.
let idDoOutrosFixo = "outros"

/// O piso de arco do anel, em pontos, medido na circunferência do meio do aro.
public let pisoDoArco = 10.0
/// O piso de largura da barra empilhada e o vão entre os pedaços, em pontos (na letra padrão).
public let pisoDaBarra = 8.0
public let vaoDaBarra = 3.0

/// Um pedaço do anel e da barra empilhada.
public struct PedacoDoAnel: Equatable, Sendable {
    /// Os tópicos do pedaço, do maior para o menor: um só, ou os que o "Outros" junta.
    public let topicos: [GastoDoTopico]
    /// A soma do bruto dos tópicos, na ordem deles.
    public let bruto: Double
    /// A cor, de 0 a 5; nil no cinza.
    public let cor: Int?
    /// O pedaço cinza que junta dois tópicos ou mais: os comuns do 7º em diante e o fixo "Outros". Fica sempre por último,
    /// mesmo quando o fixo é o maior tópico.
    public let outros: Bool
}

/// Os pedaços, sobre a lista do `gastoPorTopico` (do maior para o menor): os 6 maiores tópicos comuns (todos menos o fixo
/// "Outros"), um por cor; e, por último, o pedaço cinza com o resto, na mesma ordem: o fixo e os comuns do 7º em diante. O
/// cinza fica no fim mesmo quando o fixo é o maior tópico (decisão do Giovani de 30/10: o "Outros" da pessoa nunca sai
/// colorido ao lado do "Outros · N tópicos"). Com um tópico só, o cinza é ele mesmo, com o nome dele (o fixo, ou o 7º
/// de uma obra com 7 comuns e sem o fixo); com dois ou mais, é o "Outros", com a soma e os tópicos que ele junta.
public func pedacosDoAnel(_ topicos: [GastoDoTopico]) -> [PedacoDoAnel] {
    let coloridos = Array(topicos.indices.filter { topicos[$0].id != idDoOutrosFixo }.prefix(coresDoAnel))
    var pedacos = coloridos.enumerated().map { cor, i in
        PedacoDoAnel(topicos: [topicos[i]], bruto: topicos[i].bruto, cor: cor, outros: false)
    }
    let cinza = topicos.indices.filter { !coloridos.contains($0) }.map { topicos[$0] }
    if !cinza.isEmpty {
        pedacos.append(PedacoDoAnel(topicos: cinza, bruto: cinza.reduce(0) { $0 + $1.bruto }, cor: nil, outros: cinza.count > 1))
    }
    return pedacos
}

/// Quem tem pedaço no anel e na barra: os tópicos de bruto maior que zero. O de bruto zero (um gasto de R$ 0) fica sem
/// pedaço, como o arco de comprimento 0 do site; numa obra sem bruto nenhum, todos têm.
func temPedaco(_ brutos: [Double]) -> [Bool] {
    brutos.contains { $0 > 0 } ? brutos.map { $0 > 0 } : brutos.map { _ in true }
}

/// As partes de cada bruto no comprimento (frações que somam 1), com o piso: a parte menor que o piso sobe para ele, e o
/// que ela ganhou sai da maior (no empate, a primeira); o bruto zero fica com 0, sem piso. Ficam iguais entre os que têm
/// pedaço sem bruto, sem comprimento ou quando a maior desceria abaixo do piso, que é quando o piso de todas não cabe (no
/// anel e na barra da obra, isso só acontece sem gasto).
func partesComPiso(_ brutos: [Double], comprimento: Double, piso: Double) -> [Double] {
    let soma = brutos.reduce(0, +), minima = piso / comprimento
    let com = temPedaco(brutos), quantos = Double(com.filter { $0 }.count)
    let iguais = com.map { $0 ? 1 / quantos : 0 }
    if brutos.isEmpty || !(soma > 0) || !(comprimento > 0) { return iguais }
    var partes = brutos.map { $0 / soma }
    var falta = 0.0
    for i in partes.indices where partes[i] > 0 && partes[i] < minima {
        falta += minima - partes[i]
        partes[i] = minima
    }
    let maior = partes.indices.max { partes[$0] < partes[$1] }!
    partes[maior] -= falta
    return partes[maior] < minima ? iguais : partes
}

/// Onde um pedaço começa e termina, em frações da volta do anel (de 0 a 1, a partir do topo, no sentido do relógio).
public struct ArcoDoPedaco: Equatable, Sendable {
    public let inicio: Double
    public let fim: Double
}

/// Os arcos do anel, um depois do outro a partir do topo, com o piso de arco; o último termina em 1.
public func arcosDoAnel(_ pedacos: [PedacoDoAnel], circunferencia: Double, piso: Double = pisoDoArco) -> [ArcoDoPedaco] {
    let partes = partesComPiso(pedacos.map(\.bruto), comprimento: circunferencia, piso: piso)
    var inicio = 0.0
    return partes.indices.map { i in
        let fim = i == partes.count - 1 ? 1 : inicio + partes[i]
        defer { inicio = fim }
        return ArcoDoPedaco(inicio: inicio, fim: fim)
    }
}

/// A fração da volta de um ponto, medido a partir do centro do anel (x para a direita, y para baixo, como na tela): 0 no
/// topo, 0,25 à direita, 0,5 embaixo.
public func fracaoNoAnel(x: Double, y: Double) -> Double {
    let f = atan2(x, -y) / (2 * Double.pi)
    return f < 0 ? f + 1 : f
}

/// O pedaço sob o dedo: o arco que contém o ângulo do ponto (o pedaço mais perto, ao longo do anel). O arco vazio (o tópico
/// de bruto zero) nunca fica sob o dedo. Se o dedo está na faixa de toque, quem decide é a tela.
public func pedacoNoAnel(x: Double, y: Double, arcos: [ArcoDoPedaco]) -> Int? {
    let f = fracaoNoAnel(x: x, y: y), cheios = arcos.indices.filter { arcos[$0].fim > arcos[$0].inicio }
    return cheios.first { f < arcos[$0].fim } ?? cheios.last
}

/// As larguras dos pedaços da barra empilhada: a largura sem os vãos, com o piso de largura (8 e 3 pt na letra padrão;
/// 12 e 4 pt na máxima, como o mockup). O pedaço de bruto zero fica sem largura e sem vão. Sem largura para os vãos (o 1º
/// quadro da tela), zero em todos.
public func largurasDaBarra(_ pedacos: [PedacoDoAnel], largura: Double, piso: Double = pisoDaBarra, vao: Double = vaoDaBarra) -> [Double] {
    let brutos = pedacos.map(\.bruto), comPedaco = temPedaco(brutos).filter { $0 }.count
    let util = max(0, largura - vao * Double(max(0, comPedaco - 1)))
    return partesComPiso(brutos, comprimento: util, piso: piso).map { $0 * util }
}

/// O % de um tópico (ou do "Outros") na lista, no meio do anel e na legenda: o `Math.round(bruto / total × 100)` do site, o
/// mesmo do detalhe do tópico, e "<1%" quando o % verdadeiro fica entre 0 e 1 (o site mostraria 0% ou 1%). Sem total, "0%".
public func porcentoDoTopico(_ bruto: Double, total: Double) -> String {
    let pct = total > 0 ? bruto / total * 100 : 0
    if pct > 0 && pct < 1 { return "<1%" }
    return numeroJS(arredondarJS(pct)) + "%"
}

/// O texto com o % como o VoiceOver o lê: o "<1%" vira "menos de 1%", como no rótulo do mockup, e a leitura não depende do
/// nível de pontuação. Serve ao % sozinho (a barra) e à frase com ele ("<1% da obra", na lista e no detalhe do tópico).
public func porcentoFalado(_ texto: String) -> String { texto.replacingOccurrences(of: "<1%", with: "menos de 1%") }

/// "1 tópico", "14 tópicos".
public func contagemDeTopicos(_ n: Int) -> String { "\(n) \(n == 1 ? "tópico" : "tópicos")" }

/// O nome do "Outros" no meio do anel: "Outros · 8 tópicos".
public func rotuloDoOutros(_ pedaco: PedacoDoAnel) -> String { "Outros · " + contagemDeTopicos(pedaco.topicos.count) }

/// A legenda da barra empilhada da obra.
public struct LegendaDaBarra: Equatable, Sendable {
    /// Os pedaços com linha na legenda.
    public let pedacos: [PedacoDoAnel]
    /// "e mais N tópicos", quando sobram tópicos; nil quando todos aparecem.
    public let mais: String?
}

/// A legenda da barra: os `quantos` primeiros pedaços (4; 3 na letra máxima) e "e mais N tópicos" com os que sobram.
public func legendaDaBarra(_ pedacos: [PedacoDoAnel], quantos: Int) -> LegendaDaBarra {
    let mostrados = Array(pedacos.prefix(quantos))
    let sobram = pedacos.reduce(0) { $0 + $1.topicos.count } - mostrados.reduce(0) { $0 + $1.topicos.count }
    return LegendaDaBarra(pedacos: mostrados, mais: sobram > 0 ? "e mais " + contagemDeTopicos(sobram) : nil)
}
```

- [ ] **Step 4: Ver passar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'warning:|Test run with'
```
Expected: `━ Test run with 255 tests in 40 suites passed after 0.161 seconds with 4 known issues.` (`PedacosTests` é nova, com 11), sem nenhum `warning:`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Pedacos.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PedacosTests.swift
git commit -m "feat: pedaços do anel e da barra no núcleo, com o piso e o \"<1%\"" -m "Os Gráficos e a obra da etapa 4 mostram o gasto por tópico em seis cores e um \"Outros\" em cinza; o site repete as oito cores do nono tópico em diante. A regra entra no núcleo com teste próprio, sem vetor do site e ainda sem tela: até 7 tópicos, um pedaço cada (o sétimo cinza); com 8 ou mais, os 6 maiores e o \"Outros\", que soma o resto." -m "O tópico fixo \"Outros\" fica sempre no cinza, no fim, mesmo quando é o maior (decisão do Giovani de 30/10). As cores vão para os 6 maiores dos outros tópicos; o fixo fica sozinho no cinza, com o nome dele, ou entra no \"Outros · N tópicos\" e conta no N. Assim o \"Outros\" da pessoa nunca sai colorido ao lado do \"Outros\" cinza." -m "O pedaço pequeno ganha um piso de 10 pt de arco no anel e de 8 pt de largura na barra, tirado do maior. O tópico de R\$ 0 fica sem pedaço, como o arco vazio do site: sem piso, sem vão na barra e nunca sob o dedo. A conta diz onde cada arco começa e termina e qual pedaço está sob o dedo. O % é o arredondado do site, com \"<1%\" quando o verdadeiro fica entre 0 e 1%, que o VoiceOver lê \"menos de 1%\" (porcentoFalado)."
```

### Task 10: Escala redonda, rótulos dos meses e o mês sob o dedo

Regra nova do app, sem vetor do site, para a evolução e o gasto por mês dos Gráficos (PR 2b). O site divide o eixo em frações do máximo (`evoChartHtml` e `mesChartHtml`; R$ 233 mil, 465 mil…); o app usa números redondos (R$ 250 mil, 500 mil…), a recomendação do Croqui que o spec registra. A escala é a do mockup (`parte1.js:114-121`): alvo = max(maior, 1) × 1,03 ÷ divisões; potência = 10 elevado ao piso do log10 do alvo; o passo é o primeiro de 1; 1,2; 1,5; 2; 2,5; 3; 4; 5; 6; 8; 10 vezes a potência que chega ao alvo; o topo é passo × divisões (4 na letra padrão, 2 na máxima). O "max(…, 1)" evita a escala zero na obra de gastos de valor zero. Os rótulos do eixo Y são o `moedaCurta` de cada linha, como o mockup (abaixo de mil, o `moneyShort` do site cai no `money`, com o espaço sem quebra). Os rótulos fixos do eixo X (`indicesRotulo` do mockup, `parte1.js:131`): `quantos` meses no índice `Math.round(i × (n − 1) ÷ (quantos − 1))`, sempre o primeiro e o último (4 na letra padrão, 3 na máxima), com o ano ("out/26") no primeiro e quando ele muda do rótulo anterior; o mês escolhido que não é fixo leva o ano só em janeiro. Uma diferença do mockup: a evolução de um mês só mostra "out" sem o ano e o gasto por mês, "out/26"; aqui os dois levam o ano. O mês sob o dedo (`ligarGrafico`, `parte1.js:237-238`): no gasto por mês, a coluna que contém x (colunas iguais), presa às pontas; na evolução, o ponto mais perto, com o meio subindo (`Math.round`). Medir o texto, ancorar o rótulo na borda e esconder o rótulo fixo que encosta no escolhido ficam na tela. O `anoMes` das séries (Series.swift:26) deixa de ser privado.

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Eixos.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Series.swift`
- Test (novo): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/EixosTests.swift`

**Interfaces:**
- Consumes: `moedaCurta`, `arredondarJS`, `nomesDosMeses` e `anoMes` (Series.swift, agora interno).
- Produces: `EscalaDoEixo` (`passo`, `divisoes`, `topo`, `linhas: [Double]`, `rotulos: [String]`) e `escalaRedonda(_ maior: Double, divisoes: Int) -> EscalaDoEixo`; `RotuloDoEixoX` (`indice`, `texto`) e `rotulosDoEixoX(_ meses: [String], quantos: Int) -> [RotuloDoEixoX]`; `rotuloDoMes(_ meses: [String], indice: Int, fixos: [RotuloDoEixoX]) -> String`; `mesNaColuna(x:inicio:largura:meses:) -> Int` e `mesNoPonto(x:inicio:largura:meses:) -> Int`. Interna: `mesAbreviado(_:comAno:)`.

- [ ] **Step 1: Escrever os testes**

Os testes prendem a escala na casa do milhar e da centena de milhar, nas duas letras, a folga de 3% (R$ 1 milhão vai a 1,2 mi), a potência pelo piso do log (3.502 fica no milhar) e a obra de gastos zero; os rótulos de 14, 6, 24, 2, 1 e 0 meses, com o ano que muda e o meio que sobe no empate (6 meses em 3 rótulos: 2,5 vira 3); o rótulo do escolhido em janeiro; e o mês sob o dedo nas divisas das colunas e no meio entre dois pontos.

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/EixosTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/* Os eixos dos gráficos de mês (regra do app, sem vetor do site): a escala em números redondos, os rótulos dos meses e o
   mês sob o dedo. */
struct EixosTests {
    /// Os meses AAAA-MM de `inicio` em diante, como a série mensal os dá.
    func meses(_ inicio: String, _ n: Int) -> [String] {
        var (ano, mes) = (Int(inicio.prefix(4))!, Int(inicio.suffix(2))!)
        return (0..<n).map { _ in
            defer { mes += 1; if mes > 12 { mes = 1; ano += 1 } }
            return "\(ano)-" + (mes < 10 ? "0\(mes)" : "\(mes)")
        }
    }

    @Test func escalaEmNumerosRedondos() {
        let e = escalaRedonda(777_000, divisoes: 4)
        #expect(e.passo == 250_000)
        #expect(e.topo == 1_000_000)
        #expect(e.linhas == [250_000, 500_000, 750_000, 1_000_000])
        #expect(e.rotulos == ["R$ 250 mil", "R$ 500 mil", "R$ 750 mil", "R$ 1,00 mi"])   // o site daria R$ 233 mil, 465 mil…
        // Na letra máxima, 2 divisões.
        #expect(escalaRedonda(777_000, divisoes: 2).rotulos == ["R$ 500 mil", "R$ 1,00 mi"])
        #expect(escalaRedonda(46_000, divisoes: 4).rotulos == ["R$ 12 mil", "R$ 24 mil", "R$ 36 mil", "R$ 48 mil"])
        #expect(escalaRedonda(5_400, divisoes: 4).passo == 1_500)
        // A potência de 10 vem do piso do log: 3.502 fica na casa do milhar (passo 4 mil), não na da dezena de milhar.
        #expect(escalaRedonda(13_600, divisoes: 4).passo == 4_000)
    }

    @Test func escalaComFolgaNoTopo() {
        // R$ 1 milhão não encosta no topo: os 3% de folga passam o passo de 250 para 300 mil.
        #expect(escalaRedonda(1_000_000, divisoes: 4).topo == 1_200_000)
        #expect(escalaRedonda(970_000, divisoes: 4).topo == 1_000_000)
        // Sem valor (gastos de zero), a escala de R$ 1, para o gráfico nunca dividir por zero. Abaixo de mil, o moneyShort do
        // site cai no money, com o espaço sem quebra depois do R$.
        #expect(escalaRedonda(0, divisoes: 4).rotulos == ["R$\u{00A0}0,30", "R$\u{00A0}0,60", "R$\u{00A0}0,90", "R$\u{00A0}1,20"])
    }

    @Test func rotulosDosMesesComOAnoQuandoMuda() {
        let m = meses("2025-08", 14)
        #expect(rotulosDoEixoX(m, quantos: 4) == [RotuloDoEixoX(indice: 0, texto: "ago/25"), RotuloDoEixoX(indice: 4, texto: "dez"),
                                                 RotuloDoEixoX(indice: 9, texto: "mai/26"), RotuloDoEixoX(indice: 13, texto: "set")])
        // Na letra máxima, 3; o meio sobe no empate, como o Math.round (6 meses: 2,5 vira 3).
        #expect(rotulosDoEixoX(meses("2026-01", 6), quantos: 3).map(\.indice) == [0, 3, 5])
        #expect(rotulosDoEixoX(meses("2024-11", 24), quantos: 3).map(\.texto) == ["nov/24", "nov/25", "out/26"])
        // Um mês só e dois meses.
        #expect(rotulosDoEixoX(["2026-10"], quantos: 4) == [RotuloDoEixoX(indice: 0, texto: "out/26")])
        #expect(rotulosDoEixoX(meses("2026-09", 2), quantos: 4).map(\.texto) == ["set/26", "out"])
        #expect(rotulosDoEixoX([], quantos: 4).isEmpty)
    }

    @Test func rotuloDoMesEscolhido() {
        let m = meses("2025-08", 14)
        let fixos = rotulosDoEixoX(m, quantos: 4)
        #expect(rotuloDoMes(m, indice: 9, fixos: fixos) == "mai/26")   // fixo: o texto dele
        #expect(rotuloDoMes(m, indice: 5, fixos: fixos) == "jan/26")   // janeiro leva o ano
        #expect(rotuloDoMes(m, indice: 6, fixos: fixos) == "fev")
    }

    @Test func mesSobODedo() {
        // Gasto por mês: 12 colunas de 20 pt a partir de x = 40.
        #expect(mesNaColuna(x: 40, inicio: 40, largura: 240, meses: 12) == 0)
        #expect(mesNaColuna(x: 59.99, inicio: 40, largura: 240, meses: 12) == 0)
        #expect(mesNaColuna(x: 60, inicio: 40, largura: 240, meses: 12) == 1)
        #expect(mesNaColuna(x: 279.9, inicio: 40, largura: 240, meses: 12) == 11)
        #expect(mesNaColuna(x: 400, inicio: 40, largura: 240, meses: 12) == 11)
        #expect(mesNaColuna(x: 0, inicio: 40, largura: 240, meses: 12) == 0)
        #expect(mesNaColuna(x: 50, inicio: 40, largura: 0, meses: 12) == 0)
        // Evolução: 12 pontos de 20 em 20 pt a partir de x = 40; o mais perto, com o meio subindo.
        #expect(mesNoPonto(x: 49.99, inicio: 40, largura: 220, meses: 12) == 0)
        #expect(mesNoPonto(x: 50, inicio: 40, largura: 220, meses: 12) == 1)
        #expect(mesNoPonto(x: 255, inicio: 40, largura: 220, meses: 12) == 11)
        #expect(mesNoPonto(x: 500, inicio: 40, largura: 220, meses: 12) == 11)
        #expect(mesNoPonto(x: -20, inicio: 40, largura: 220, meses: 12) == 0)
        #expect(mesNoPonto(x: 100, inicio: 40, largura: 220, meses: 1) == 0)
    }
}
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter EixosTests 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'EixosTests.swift:[0-9:]* error: cannot find [^|]*' | sort -t: -k2,2n -u | head -3
```
Expected: o núcleo não compila:
```
EixosTests.swift:17:17: error: cannot find 'escalaRedonda' in scope
EixosTests.swift:23:17: error: cannot find 'escalaRedonda' in scope
EixosTests.swift:24:17: error: cannot find 'escalaRedonda' in scope
```

- [ ] **Step 3: Implementar**

`Int(…)` de um Double não finito derruba o app: as duas funções do dedo saem antes com largura zero (o 1º quadro do `GeometryReader`) e prendem o índice ainda em Double.

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/Eixos.swift`:

```swift
import Foundation

/* Os eixos dos gráficos de mês (evolução e gasto por mês): regra do app, sem vetor do site. O site divide o eixo em frações
   do máximo (R$ 233 mil, 465 mil…); o app usa números redondos (R$ 250 mil, 500 mil…), como o mockup (`parte1.js:114-121`).
   Os rótulos dos meses e o mês sob o dedo também são conta pura; o resto (medir, ancorar na borda) é da tela. */

/// Os números redondos de cada potência de 10.
let passosRedondos: [Double] = [1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]

/// A escala do eixo de valor.
public struct EscalaDoEixo: Equatable, Sendable {
    /// A distância entre as linhas da grade.
    public let passo: Double
    /// Quantas linhas a grade tem acima do zero: 4 na letra padrão, 2 na máxima.
    public let divisoes: Int
    public var topo: Double { passo * Double(divisoes) }
    /// As linhas da grade, de baixo para cima, sem o zero.
    public var linhas: [Double] { (0..<divisoes).map { passo * Double($0 + 1) } }
    /// Os rótulos das linhas: o `moedaCurta` (o `moneyShort` do site), como o mockup.
    public var rotulos: [String] { linhas.map(moedaCurta) }
}

/// A escala redonda: o menor passo redondo (1; 1,2; 1,5; 2; 2,5; 3; 4; 5; 6; 8 ou 10 vezes uma potência de 10) que, vezes as
/// divisões, passa do maior valor com 3% de folga. Sem valor, conta como R$ 1, para o gráfico nunca dividir por zero.
public func escalaRedonda(_ maior: Double, divisoes: Int) -> EscalaDoEixo {
    let alvo = max(maior, 1) * 1.03 / Double(divisoes)
    let potencia = pow(10, log10(alvo).rounded(.down))
    let passo = passosRedondos.lazy.map { $0 * potencia }.first { $0 >= alvo } ?? 10 * potencia
    return EscalaDoEixo(passo: passo, divisoes: divisoes)
}

/// Um rótulo fixo do eixo X: o índice do mês na série e o texto.
public struct RotuloDoEixoX: Equatable, Sendable {
    public let indice: Int
    public let texto: String
}

/// "out", ou "out/26" com o ano, de um mês AAAA-MM.
func mesAbreviado(_ mes: String, comAno: Bool) -> String {
    let (ano, m) = anoMes(mes)
    return String(nomesDosMeses[m - 1].prefix(3)) + (comAno ? "/" + String(String(ano).suffix(2)) : "")
}

/// Os rótulos fixos do eixo X: `quantos` meses espalhados por igual, sempre o primeiro e o último (4 na letra padrão, 3 na
/// máxima), no índice `Math.round(i × (n − 1) ÷ (quantos − 1))`; o ano vai no primeiro e quando muda do rótulo anterior.
public func rotulosDoEixoX(_ meses: [String], quantos: Int) -> [RotuloDoEixoX] {
    let k = min(quantos, meses.count)
    var anoAnterior = ""
    return (0..<max(0, k)).map { i in
        let indice = Int(arredondarJS(Double(i) * Double(meses.count - 1) / Double(max(1, k - 1))))
        let ano = String(meses[indice].prefix(4))
        defer { anoAnterior = ano }
        return RotuloDoEixoX(indice: indice, texto: mesAbreviado(meses[indice], comAno: ano != anoAnterior))
    }
}

/// O rótulo do mês escolhido: o do rótulo fixo, se ele for um; senão o mês abreviado, com o ano só em janeiro.
public func rotuloDoMes(_ meses: [String], indice: Int, fixos: [RotuloDoEixoX]) -> String {
    if let fixo = fixos.first(where: { $0.indice == indice }) { return fixo.texto }
    return mesAbreviado(meses[indice], comAno: anoMes(meses[indice]).1 == 1)
}

/// O mês sob o dedo no gasto por mês: a coluna que contém x (as colunas dividem a largura por igual a partir de `inicio`),
/// presa ao primeiro e ao último mês.
public func mesNaColuna(x: Double, inicio: Double, largura: Double, meses: Int) -> Int {
    guard meses > 0, largura > 0 else { return 0 }
    let i = ((x - inicio) / (largura / Double(meses))).rounded(.down)
    return Int(max(0, min(Double(meses - 1), i)))
}

/// O mês sob o dedo na evolução: o ponto mais perto de x (os pontos vão de `inicio` a `inicio + largura`; no meio, o de
/// depois, como o `Math.round`), preso às pontas.
public func mesNoPonto(x: Double, inicio: Double, largura: Double, meses: Int) -> Int {
    guard meses > 1, largura > 0 else { return 0 }
    let i = arredondarJS((x - inicio) / largura * Double(meses - 1))
    return Int(max(0, min(Double(meses - 1), i)))
}
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Series.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Series.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Series.swift
@@ -23,7 +23,7 @@ func ordenadoEstavel<T>(_ itens: [T], _ antes: (T, T) -> Bool) -> [T] {
 /// Chave de mês do calc.js: o ano como número, sem completar com zeros.
 private func chaveMes(_ ano: Int, _ mes: Int) -> String { "\(ano)-" + doisDigitos(mes) }
 
-private func anoMes(_ chave: String) -> (Int, Int) {
+func anoMes(_ chave: String) -> (Int, Int) {
     (Int(chave.prefix(4)) ?? 0, Int(chave.dropFirst(5).prefix(2)) ?? 0)
 }
 
```

- [ ] **Step 4: Ver passar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'warning:|Test run with'
```
Expected: `━ Test run with 257 tests in 41 suites passed after 0.183 seconds with 4 known issues.` (`EixosTests` é nova, com 5), sem nenhum `warning:`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Eixos.swift app-ios/CusttaNucleo/Sources/CusttaNucleo/Series.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/EixosTests.swift
git commit -m "feat: escala redonda, rótulos dos meses e o mês sob o dedo no núcleo" -m "Os gráficos de mês da etapa 4 (evolução e gasto por mês) usam números redondos no eixo de valor (R\$ 250 mil, 500 mil...), onde o site divide o máximo em frações (R\$ 233 mil, 465 mil...). A escala pega o menor passo redondo que passa do maior valor com 3% de folga, em 4 divisões na letra padrão e 2 na máxima, como o mockup." -m "O eixo X espalha 4 rótulos de mês (3 na letra máxima), sempre o primeiro e o último, com o ano no primeiro e quando ele muda; o mês escolhido fora deles leva o ano em janeiro. O toque escolhe a coluna sob o dedo no gasto por mês e o ponto mais perto na evolução. Tudo é conta pura, ainda sem tela; o anoMes das séries deixa de ser privado para servir aos rótulos."
```

### Task 11: Mês padrão, meses a vencer, frases e média dos gráficos

Regra nova do app, sem vetor do site, para os Gráficos (PRs 2a e 2b) e a página 1 do PDF (PR 4b). O mês de referência é o do fim da correção (`fimCorrecao`): o da venda, na vendida; senão, este mês. O mês escolhido por padrão no gasto por mês é o de referência e, fora da série, o último com gasto (`mesHtml` do mockup, `parte1.js:180-182`); o site escolhe sempre o último com gasto, que pode ser um mês a vencer (achado 2 do inventário; na Casa Alphaville, abril de 2027). O mês a vencer (tracejado e hachurado) é o depois do de referência; o mês de referência conta inteiro, como pago (spec, "Deste spec"). O mockup só hachura quando o mês de referência está na série (`atual >= 0`): a obra com só parcelas futuras sairia sem hachura; aqui vale a regra do spec. As frases (textos novos em âmbar): o que ficou fora da evolução, que para no fim da correção, é o bruto dos gastos de data depois dele, na ordem do documento; "Fora do gráfico: R$ … a vencer (depois de hoje)." ou, na vendida, "Fora do gráfico: R$ … com data depois da venda." (um gasto no mesmo mês da venda, mas depois dela, também conta); embaixo do anel, que soma tudo, "Inclui R$ … a vencer.", que a vendida não tem; as duas só acima de meio centavo, como o mockup, e em `moeda` (o valor exato). O aviso "Mostrando os últimos 24 meses." só quando a série passou de 24 meses (spec, "Deste spec"; o mockup o mostra também com 24): o gasto por mês vai do mês do 1º gasto ao do último; a evolução, ao do fim da correção, e numa obra parada há tempo só ela é cortada. A média, o maior e os meses (confirmação 2): do mês do 1º gasto ao de referência, com os meses zerados e sem os meses a vencer; a média é a soma ÷ os meses; o maior, no empate, o primeiro (como o mockup); valores em `moedaCurta`. O mockup conta só os meses à vista (os últimos 24); o spec diz "do 1º gasto", e vale o spec. O dia entra por parâmetro, como em todo o núcleo, e os testes cobrem a virada do mês (31/10 e 1º/11) e a do ano (31/12 e 1º/01), além do gasto no próprio dia e da parcela que vence no mês corrente (memória `laudo-que-depende-do-dia`). O `chaveMes` das séries deixa de ser privado.

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/MesesDosGraficos.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Series.swift`
- Test (novo): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MesesDosGraficosTests.swift`

**Interfaces:**
- Consumes: `fimCorrecao`, `serieMensal` e `PontoMensal`, `moeda`, `moedaCurta`, `menorJS`, `anoMes` e `chaveMes` (Series.swift, agora internos), `mesAbreviado` (Tarefa anterior).
- Produces: `mesDeReferencia(_ obra: Obra, hoje: String) -> String`; `mesPadraoDoGastoPorMes(_ serie: [PontoMensal], referencia: String) -> Int?`; `mesAVencer(_ mes: String, referencia: String) -> Bool`; `foraDaEvolucao(_:hoje:) -> Double`, `fraseForaDaEvolucao(_:hoje:) -> String?` e `fraseAVencerDoAnel(_:hoje:) -> String?`; `avisoDos24Meses`, `gastoPorMesFoiCortado(_ gastos: [Gasto]) -> Bool` e `evolucaoFoiCortada(_:hoje:) -> Bool`; `NumeroDoResumo` (`rotulo`, `valor`), `ResumoDosMeses` (`media`, `maior: PontoMensal?`, `meses`, `numeros: [NumeroDoResumo]`) e `resumoDosMeses(_:hoje:) -> ResumoDosMeses`. Interna: `mesesEntre(_:_:)`.

- [ ] **Step 1: Escrever os testes**

Os testes prendem o mês de referência e o padrão (este mês, o da venda, o último com gasto fora da série, sem contar o mês zerado do fim), o mês a vencer, as frases com valores de milhar (que separam o `moeda` do `moedaCurta`), o gasto no próprio dia, o gasto depois da venda no mesmo mês, as viradas do mês e do ano, a média com os meses zerados e o empate do maior, a vendida, a obra só com gastos futuros e os cortes de 24 e 25 meses nas duas séries (na evolução, o 25º mês vem pelo dia de hoje: a obra parada de 2023-01 é cortada a partir de janeiro de 2025).

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MesesDosGraficosTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/* O mês dos gráficos de mês (regra do app, sem vetor do site): o mês de referência, o escolhido por padrão, os meses a
   vencer, as frases do que ficou fora, a média, o maior e os meses, e o aviso dos 24 meses. Tudo depende de hoje, que entra
   por parâmetro; os casos cobrem a virada do mês e do ano. */
struct MesesDosGraficosTests {
    func obra(_ gastos: [(data: String, valor: Double)], venda: String? = nil) -> Obra {
        var o: [String: ValorJSON] = ["id": .texto("o1"), "nome": .texto("Casa"), "dataInicio": .texto("2026-01-05"),
                                      "fase": .texto(venda == nil ? "construcao" : "vendida"),
                                      "gastos": .lista(gastos.enumerated().map { i, g in
                                          .objeto(["id": .texto("g\(i)"), "valor": .numero(g.valor), "topico": .texto("terreno"),
                                                   "descricao": .texto(""), "data": .texto(g.data), "pagamento": .texto("pix")])
                                      })]
        if let venda { o["venda"] = .objeto(["valor": .numero(2_000_000), "data": .texto(venda)]) }
        return Estado.de(.objeto(["obras": .lista([.objeto(o)])])).obras[0]
    }

    /// Uma obra com gastos de março de 2026 até uma parcela de novembro; hoje é 12/10/2026.
    var casa: Obra {
        obra([("2026-03-10", 100_000), ("2026-05-02", 400_000), ("2026-05-20", 200_000), ("2026-07-01", 600_000),
              ("2026-10-25", 300_000), ("2026-11-05", 900_000)])
    }

    @Test func mesDeReferenciaEsteMesOuODaVenda() {
        #expect(mesDeReferencia(casa, hoje: "2026-10-12") == "2026-10")
        #expect(mesDeReferencia(obra([("2026-03-10", 1)], venda: "2026-06-20"), hoje: "2026-10-12") == "2026-06")
    }

    @Test func mesEscolhidoPorPadrao() {
        let serie = serieMensal(casa.gastos)
        #expect(mesPadraoDoGastoPorMes(serie, referencia: "2026-10") == 7)     // este mês, não novembro (o site cairia nele)
        #expect(mesPadraoDoGastoPorMes(serie, referencia: "2026-06") == 3)     // o da venda
        // Fora da série, o último com gasto (o mês de valor zero no fim não conta).
        let parada = serieMensal(obra([("2025-01-10", 100), ("2025-03-02", 0)]).gastos)
        #expect(mesPadraoDoGastoPorMes(parada, referencia: "2026-10") == 0)
        #expect(mesPadraoDoGastoPorMes(serie, referencia: "2025-01") == 8)
        #expect(mesPadraoDoGastoPorMes([], referencia: "2026-10") == nil)
    }

    @Test func mesesAVencerDepoisDaReferencia() {
        #expect(mesAVencer("2026-11", referencia: "2026-10"))
        #expect(!mesAVencer("2026-10", referencia: "2026-10"))                // o mês corrente conta inteiro, como pago
        #expect(!mesAVencer("2026-09", referencia: "2026-10"))
        #expect(mesAVencer("2027-01", referencia: "2026-12"))
    }

    @Test func frasesDoQueFicouFora() {
        // A parcela de 25/10 está a vencer (depois de hoje), embora outubro conte inteiro no gasto por mês.
        #expect(foraDaEvolucao(casa, hoje: "2026-10-12") == 1_200_000)
        #expect(fraseForaDaEvolucao(casa, hoje: "2026-10-12") == "Fora do gráfico: R$\u{00A0}1.200.000,00 a vencer (depois de hoje).")
        #expect(fraseAVencerDoAnel(casa, hoje: "2026-10-12") == "Inclui R$\u{00A0}1.200.000,00 a vencer.")
        // No dia do gasto, ele já está no gráfico.
        #expect(fraseForaDaEvolucao(casa, hoje: "2026-11-05") == nil)
        #expect(fraseAVencerDoAnel(casa, hoje: "2026-11-05") == nil)
        // Na vendida, o que tem data depois da venda (no mesmo mês também); o anel não fala de "a vencer".
        let vendida = obra([("2026-03-10", 50_000), ("2026-06-20", 1_000), ("2026-06-25", 8_000), ("2026-07-01", 2_000)], venda: "2026-06-20")
        #expect(fraseForaDaEvolucao(vendida, hoje: "2026-10-12") == "Fora do gráfico: R$\u{00A0}10.000,00 com data depois da venda.")
        #expect(fraseAVencerDoAnel(vendida, hoje: "2026-10-12") == nil)
        #expect(fraseForaDaEvolucao(obra([("2026-03-10", 50_000)], venda: "2026-06-20"), hoje: "2026-10-12") == nil)
    }

    @Test func viradaDoMesEDoAno() {
        let virada = obra([("2026-09-15", 4_000), ("2026-11-01", 1_000)])
        // No último dia de outubro, novembro está a vencer e fica fora da média.
        #expect(mesDeReferencia(virada, hoje: "2026-10-31") == "2026-10")
        #expect(fraseForaDaEvolucao(virada, hoje: "2026-10-31") == "Fora do gráfico: R$\u{00A0}1.000,00 a vencer (depois de hoje).")
        #expect(resumoDosMeses(virada, hoje: "2026-10-31").meses == 2)
        // No 1º de novembro, novembro é este mês: entra na média e sai das frases.
        #expect(mesDeReferencia(virada, hoje: "2026-11-01") == "2026-11")
        #expect(!mesAVencer("2026-11", referencia: mesDeReferencia(virada, hoje: "2026-11-01")))
        #expect(fraseForaDaEvolucao(virada, hoje: "2026-11-01") == nil)
        #expect(resumoDosMeses(virada, hoje: "2026-11-01") == ResumoDosMeses(media: 5_000.0 / 3, maior: PontoMensal(mes: "2026-09", total: 4_000), meses: 3))
        // Na virada do ano.
        let ano = obra([("2026-12-20", 3_000), ("2027-01-01", 6_000)])
        #expect(resumoDosMeses(ano, hoje: "2026-12-31").meses == 1)
        #expect(resumoDosMeses(ano, hoje: "2027-01-01") == ResumoDosMeses(media: 4_500, maior: PontoMensal(mes: "2027-01", total: 6_000), meses: 2))
    }

    @Test func mediaMaiorEMeses() {
        // De março a outubro (8 meses, com abril, junho, agosto e setembro zerados); outubro conta inteiro, novembro não.
        let r = resumoDosMeses(casa, hoje: "2026-10-12")
        #expect(r == ResumoDosMeses(media: 200_000, maior: PontoMensal(mes: "2026-05", total: 600_000), meses: 8))  // maio empata com julho: o primeiro
        #expect(r.numeros == [NumeroDoResumo(rotulo: "Média por mês", valor: "R$ 200 mil"), NumeroDoResumo(rotulo: "Maior · mai", valor: "R$ 600 mil"),
                              NumeroDoResumo(rotulo: "Meses", valor: "8")])
        // Na vendida, até o mês da venda.
        #expect(resumoDosMeses(obra(casa.gastos.map { ($0.data, $0.valor) }, venda: "2026-06-20"), hoje: "2026-10-12")
                == ResumoDosMeses(media: 175_000, maior: PontoMensal(mes: "2026-05", total: 600_000), meses: 4))
        // Só gastos a vencer: nenhum mês.
        let futuro = resumoDosMeses(obra([("2026-11-05", 900_000)]), hoje: "2026-10-12")
        #expect(futuro == ResumoDosMeses(media: 0, maior: nil, meses: 0))
        #expect(futuro.numeros.map(\.valor) == ["R$\u{00A0}0,00", "—", "0"])
        #expect(futuro.numeros[1].rotulo == "Maior")
    }

    @Test func avisoSoComASerieCortada() {
        func mensal(_ de: String, _ ate: String) -> Obra { obra([(de + "-01", 10), (ate + "-01", 10)]) }
        #expect(!gastoPorMesFoiCortado(mensal("2024-11", "2026-10").gastos))           // 24 meses: cabem
        #expect(gastoPorMesFoiCortado(mensal("2024-10", "2026-10").gastos))            // 25: cortado
        #expect(!gastoPorMesFoiCortado([]))
        // A evolução vai até hoje: uma obra parada há tempo tem a evolução cortada e o gasto por mês inteiro.
        let parada = mensal("2023-01", "2024-06")
        #expect(evolucaoFoiCortada(parada, hoje: "2026-10-12"))
        #expect(!gastoPorMesFoiCortado(parada.gastos))
        #expect(!evolucaoFoiCortada(parada, hoje: "2024-12-31"))                       // 2023-01 a 2024-12: 24 meses
        #expect(evolucaoFoiCortada(parada, hoje: "2025-01-01"))                        // 2023-01 a 2025-01: 25, cortada
        #expect(!evolucaoFoiCortada(obra([]), hoje: "2026-10-12"))
        #expect(avisoDos24Meses == "Mostrando os últimos 24 meses.")
    }
}
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter MesesDosGraficosTests 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'MesesDosGraficosTests.swift:[0-9:]* error: cannot find [^|]*' | sort -t: -k2,2n -u | head -3
```
Expected: o núcleo não compila:
```
MesesDosGraficosTests.swift:26:17: error: cannot find 'mesDeReferencia' in scope
MesesDosGraficosTests.swift:27:17: error: cannot find 'mesDeReferencia' in scope
MesesDosGraficosTests.swift:32:17: error: cannot find 'mesPadraoDoGastoPorMes' in scope
```

- [ ] **Step 3: Implementar**

Um teste com o mesmo nome de uma função global a esconde dentro da suíte (`use of … refers to instance method`): por isso o teste do mês padrão se chama `mesEscolhidoPorPadrao`.

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/MesesDosGraficos.swift`:

```swift
import Foundation

/* O mês dos gráficos de mês e o que vai em volta deles: regra do app, sem vetor do site (spec da etapa 4, "Regras novas do
   app" e confirmação 2). O site escolhe o último mês com gasto, que pode ser um mês a vencer, e não tem as frases nem a
   média. Tudo depende de hoje, que entra por parâmetro: a virada do mês troca o mês de referência. */

/// O mês de referência dos Gráficos (AAAA-MM): o da venda, na obra vendida; senão, este mês. É o mês do fim da correção.
public func mesDeReferencia(_ obra: Obra, hoje: String) -> String { String(fimCorrecao(obra, hoje: hoje).prefix(7)) }

/// O mês escolhido por padrão no gasto por mês: o de referência; fora da série, o último com gasto (o que o mockup faz).
/// nil sem série.
public func mesPadraoDoGastoPorMes(_ serie: [PontoMensal], referencia: String) -> Int? {
    if serie.isEmpty { return nil }
    return serie.firstIndex { $0.mes == referencia } ?? serie.lastIndex { $0.total > 0 } ?? 0
}

/// O mês a vencer do gasto por mês (tracejado e hachurado): depois do mês de referência. O mês de referência conta
/// inteiro, como pago, mesmo com parcela que ainda vence nele.
public func mesAVencer(_ mes: String, referencia: String) -> Bool { menorJS(referencia, mes) }

private func vendida(_ obra: Obra) -> Bool { !(obra.venda?.data ?? "").isEmpty }

/// O bruto dos gastos de data depois do fim da correção (hoje, ou a venda), na ordem do documento: o que a evolução, que
/// para no fim da correção, deixa de fora.
public func foraDaEvolucao(_ obra: Obra, hoje: String) -> Double {
    let fim = fimCorrecao(obra, hoje: hoje)
    return obra.gastos.filter { menorJS(fim, $0.data) }.reduce(0) { $0 + $1.valor }
}

/// A frase embaixo da evolução: "Fora do gráfico: R$ … a vencer (depois de hoje)." ou, na vendida, "Fora do gráfico: R$ …
/// com data depois da venda."; nil sem nada fora.
public func fraseForaDaEvolucao(_ obra: Obra, hoje: String) -> String? {
    let fora = foraDaEvolucao(obra, hoje: hoje)
    if fora <= 0.005 { return nil }
    return "Fora do gráfico: \(moeda(fora)) " + (vendida(obra) ? "com data depois da venda." : "a vencer (depois de hoje).")
}

/// A frase embaixo do anel, que soma as parcelas a vencer: "Inclui R$ … a vencer."; nil sem nada a vencer e na vendida.
public func fraseAVencerDoAnel(_ obra: Obra, hoje: String) -> String? {
    if vendida(obra) { return nil }
    let fora = foraDaEvolucao(obra, hoje: hoje)
    return fora > 0.005 ? "Inclui \(moeda(fora)) a vencer." : nil
}

/// O aviso embaixo do gráfico cuja série passou de 24 meses e mostra só os últimos 24.
public let avisoDos24Meses = "Mostrando os últimos 24 meses."

/// Quantos meses vão de `de` a `ate` (AAAA-MM), os dois incluídos.
func mesesEntre(_ de: String, _ ate: String) -> Int {
    let (a1, m1) = anoMes(de), (a2, m2) = anoMes(ate)
    return (a2 - a1) * 12 + m2 - m1 + 1
}

/// O gasto por mês (`serieMensal`, do mês do 1º gasto ao do último) passou de 24 meses e foi cortado.
public func gastoPorMesFoiCortado(_ gastos: [Gasto]) -> Bool {
    let meses = gastos.map { String($0.data.prefix(7)) }.sorted(by: menorJS)
    guard let primeiro = meses.first, let ultimo = meses.last else { return false }
    return mesesEntre(primeiro, ultimo) > 24
}

/// A evolução (`serieEvolucao`, do mês do 1º gasto ao do fim da correção) passou de 24 meses e foi cortada. Na obra parada
/// há tempo, ela é cortada e o gasto por mês, não.
public func evolucaoFoiCortada(_ obra: Obra, hoje: String) -> Bool {
    guard let primeiro = obra.gastos.map({ String($0.data.prefix(7)) }).min(by: menorJS) else { return false }
    let fim = mesDeReferencia(obra, hoje: hoje)
    return mesesEntre(primeiro, menorJS(primeiro, fim) ? fim : primeiro) > 24
}

/// Um dos números embaixo do gasto por mês.
public struct NumeroDoResumo: Equatable, Sendable {
    public let rotulo: String
    public let valor: String
}

/// A média, o maior e os meses embaixo do gasto por mês.
public struct ResumoDosMeses: Equatable, Sendable {
    /// A soma dos meses ÷ os meses; 0 sem meses.
    public let media: Double
    /// O mês de maior bruto; no empate, o primeiro. nil sem meses.
    public let maior: PontoMensal?
    public let meses: Int

    /// "Média por mês", "Maior · mai" e "Meses", com os valores no `moedaCurta`, como o mockup.
    public var numeros: [NumeroDoResumo] {
        [NumeroDoResumo(rotulo: "Média por mês", valor: moedaCurta(media)),
         NumeroDoResumo(rotulo: maior.map { "Maior · " + mesAbreviado($0.mes, comAno: false) } ?? "Maior",
                        valor: maior.map { moedaCurta($0.total) } ?? "—"),
         NumeroDoResumo(rotulo: "Meses", valor: "\(meses)")]
    }
}

/// A conta da confirmação 2 do spec: do mês do 1º gasto ao mês de referência, com os meses zerados e sem os meses a vencer;
/// o mês de referência conta inteiro. Com o 1º gasto depois do mês de referência, nenhum mês.
public func resumoDosMeses(_ obra: Obra, hoje: String) -> ResumoDosMeses {
    let referencia = mesDeReferencia(obra, hoje: hoje)
    var porMes: [String: Double] = [:]
    for g in obra.gastos { porMes[String(g.data.prefix(7)), default: 0] += g.valor }
    guard let primeiro = porMes.keys.min(by: menorJS), !menorJS(referencia, primeiro) else {
        return ResumoDosMeses(media: 0, maior: nil, meses: 0)
    }
    var (ano, mes) = anoMes(primeiro)
    let pontos = (0..<mesesEntre(primeiro, referencia)).map { _ in
        defer { mes += 1; if mes > 12 { mes = 1; ano += 1 } }
        return PontoMensal(mes: chaveMes(ano, mes), total: porMes[chaveMes(ano, mes)] ?? 0)
    }
    let maior = pontos.dropFirst().reduce(pontos[0]) { $1.total > $0.total ? $1 : $0 }
    return ResumoDosMeses(media: pontos.reduce(0) { $0 + $1.total } / Double(pontos.count), maior: maior, meses: pontos.count)
}
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/Series.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/Series.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/Series.swift
@@ -21,7 +21,7 @@ func ordenadoEstavel<T>(_ itens: [T], _ antes: (T, T) -> Bool) -> [T] {
 }
 
 /// Chave de mês do calc.js: o ano como número, sem completar com zeros.
-private func chaveMes(_ ano: Int, _ mes: Int) -> String { "\(ano)-" + doisDigitos(mes) }
+func chaveMes(_ ano: Int, _ mes: Int) -> String { "\(ano)-" + doisDigitos(mes) }
 
 func anoMes(_ chave: String) -> (Int, Int) {
     (Int(chave.prefix(4)) ?? 0, Int(chave.dropFirst(5).prefix(2)) ?? 0)
```

- [ ] **Step 4: Ver passar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'warning:|Test run with'
```
Expected: `━ Test run with 264 tests in 42 suites passed after 0.190 seconds with 4 known issues.` (`MesesDosGraficosTests` é nova, com 7), sem nenhum `warning:`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/MesesDosGraficos.swift app-ios/CusttaNucleo/Sources/CusttaNucleo/Series.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/MesesDosGraficosTests.swift
git commit -m "feat: mês padrão, meses a vencer, frases e média dos gráficos no núcleo" -m "O gasto por mês da etapa 4 abre neste mês (o da venda, na vendida), e não no último mês com gasto, que o site usa e que pode ser um mês a vencer. Os meses depois dele ficam tracejados; o mês corrente conta inteiro. A evolução para em hoje ou na venda, e o que ficou de fora vira uma frase; o anel, que soma tudo, avisa quanto está a vencer." -m "Embaixo do gasto por mês entram a média, o maior e os meses, na conta da confirmação 2 do spec: do mês do primeiro gasto ao de referência, com os meses zerados. O aviso dos 24 meses só aparece quando a série foi cortada. O dia entra por parâmetro, e os testes cobrem a virada do mês e a do ano."
```

### Task 12: Linha do tópico no Relatório, com "N de M gastos" e 1 casa

Regra nova do app, sem vetor do site, para o Relatório (PR 3a), a busca (PR 3a) e o cabeçalho do tópico no PDF (PR 4b). Cada bloco de tópico diz quantos gastos tem e a parte da obra com 1 casa ("2 gastos · 38,0%", spec, "Relatório"), que o site não mostra; na busca, "N de M gastos" (o mockup, `parte2.js:51`), com o bruto só dos achados na parte (`parte2.js:50`). O substantivo vai pelo total: "1 de 3 gastos", "1 de 1 gasto". A mesma contagem serve ao resumo dos achados ("12 de 46 gastos", `parte2.js:71`) e ao "2 gastos" do tópico no PDF (`parte2.js:167`). A casa decimal segue o `toLocaleString` pt-BR do mockup (`pct1`, `parte2.js:12`), que é o arredondamento da parte do total da soma da seleção (`duasCasasPtBR`, Relatorio.swift:95): o meio sobe sobre os dígitos mais curtos, e 0,15% vira "0,2%", onde o `toFixed` daria "0,1%". Abaixo de 0,1%, a linha diz "<0,1%", como o "<1%" do anel; o spec só fala da casa decimal, e o "0,0%" de um tópico com dinheiro seria o mesmo engano que o "<1%" corrige (achado deste PR). Sem total, "0,0%".

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/TopicoNoRelatorio.swift`
- Test (novo): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TopicoNoRelatorioTests.swift`

**Interfaces:**
- Consumes: `digitosMaisCurtos` (NumeroJS.swift) e `agruparMilhar` (Moeda.swift).
- Produces: `contagemDeGastos(_ n: Int, de total: Int? = nil) -> String`; `parteComUmaCasa(_ bruto: Double, total: Double) -> String`; `linhaDoTopicoNoRelatorio(_ n: Int, de total: Int? = nil, bruto: Double, total: Double) -> String`. Interna: `casasPtBR(_ x: Double, _ casas: Int) -> String`.

- [ ] **Step 1: Escrever os testes**

Os testes prendem o singular e o plural pelo total, a parte com o meio que sobe (0,15% e 99,95%), o "<0,1%" na divisa de 0,1%, o zero, e o formatador com milhar, sinal e vai-um que cria um dígito inteiro.

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TopicoNoRelatorioTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/* A linha do tópico no Relatório do app (regra do app, sem vetor do site): quantos gastos, o "N de M gastos" da busca e a
   parte da obra com 1 casa. */
struct TopicoNoRelatorioTests {
    @Test func contagemDosGastos() {
        #expect(contagemDeGastos(1) == "1 gasto")
        #expect(contagemDeGastos(2) == "2 gastos")
        // Na busca, o substantivo vai pelo total do tópico.
        #expect(contagemDeGastos(1, de: 3) == "1 de 3 gastos")
        #expect(contagemDeGastos(11, de: 11) == "11 de 11 gastos")
        #expect(contagemDeGastos(1, de: 1) == "1 de 1 gasto")
        #expect(contagemDeGastos(12, de: 46) == "12 de 46 gastos")   // o resumo dos achados
    }

    @Test func parteDaObraComUmaCasa() {
        #expect(parteComUmaCasa(380, total: 1000) == "38,0%")
        #expect(parteComUmaCasa(1000, total: 1000) == "100,0%")
        #expect(parteComUmaCasa(9995, total: 10_000) == "100,0%")
        // 0,15% sobe para 0,2%, como o toLocaleString pt-BR (o toFixed do JavaScript daria 0,1%).
        #expect(parteComUmaCasa(15, total: 10_000) == "0,2%")
        // Abaixo de 0,1%, "<0,1%", como o "<1%" do anel; o zero continua zero.
        #expect(parteComUmaCasa(9, total: 10_000) == "<0,1%")
        #expect(parteComUmaCasa(10, total: 10_000) == "0,1%")
        #expect(parteComUmaCasa(0, total: 1000) == "0,0%")
        #expect(parteComUmaCasa(0, total: 0) == "0,0%")
    }

    @Test func casasNoFormatoDoSite() {
        #expect(casasPtBR(1234.56, 1) == "1.234,6")
        #expect(casasPtBR(-1234.56, 1) == "-1.234,6")
        #expect(casasPtBR(0.05, 1) == "0,1")
        #expect(casasPtBR(0.04, 1) == "0,0")
        #expect(casasPtBR(99.95, 1) == "100,0")
        #expect(casasPtBR(12.25, 2) == "12,25")
        #expect(casasPtBR(2.5, 0) == "3")
        #expect(casasPtBR(0, 1) == "0,0")
    }

    @Test func linhaDoTopico() {
        #expect(linhaDoTopicoNoRelatorio(2, bruto: 380, total: 1000) == "2 gastos · 38,0%")
        #expect(linhaDoTopicoNoRelatorio(11, de: 11, bruto: 380, total: 1000) == "11 de 11 gastos · 38,0%")
        #expect(linhaDoTopicoNoRelatorio(1, de: 3, bruto: 50, total: 1000) == "1 de 3 gastos · 5,0%")
    }
}
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter TopicoNoRelatorioTests 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'TopicoNoRelatorioTests.swift:[0-9:]* error: cannot find [^|]*' | sort -t: -k2,2n -u | head -3
```
Expected: o núcleo não compila:
```
TopicoNoRelatorioTests.swift:8:17: error: cannot find 'contagemDeGastos' in scope
TopicoNoRelatorioTests.swift:9:17: error: cannot find 'contagemDeGastos' in scope
TopicoNoRelatorioTests.swift:11:17: error: cannot find 'contagemDeGastos' in scope
```

- [ ] **Step 3: Implementar**

O `casasPtBR` generaliza o arredondamento do `moeda` para qualquer número de casas, sem mexer no `moeda` nem no `duasCasasPtBR`, que os vetores conferem.

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/TopicoNoRelatorio.swift`:

```swift
import Foundation

/* A linha de cada tópico no Relatório do app ("2 gastos · 38,0%"; na busca, "11 de 11 gastos · 38,0%"), que o site não
   mostra: regra do app, sem vetor do site. A parte do total da soma da seleção, com 2 casas, é a do site (`somaSelecao`). */

/// "1 gasto", "2 gastos"; com o total, "1 de 3 gastos", com o substantivo pelo total. Serve ao tópico na busca, ao resumo
/// dos achados ("12 de 46 gastos") e ao cabeçalho do tópico no PDF.
public func contagemDeGastos(_ n: Int, de total: Int? = nil) -> String {
    (total.map { "\(n) de \($0)" } ?? "\(n)") + ((total ?? n) == 1 ? " gasto" : " gastos")
}

/// `x.toLocaleString('pt-BR', {minimumFractionDigits: casas, maximumFractionDigits: casas})`: sobre os dígitos mais curtos,
/// o meio para longe do zero (o ICU, como o `moeda`), com o ponto de milhar e a vírgula.
func casasPtBR(_ x: Double, _ casas: Int) -> String {
    var digitos = [0], inteiros = 1
    if x.isFinite && x != 0 {
        let (d, n) = digitosMaisCurtos(abs(x))
        digitos = Array(repeating: 0, count: max(0, 1 - n)) + d.map { $0.wholeNumberValue ?? 0 }
        inteiros = max(n, 1)
    }
    digitos += Array(repeating: 0, count: max(0, inteiros + casas + 1 - digitos.count))
    var mantidos = Array(digitos[..<(inteiros + casas)])
    if digitos[inteiros + casas] >= 5 {
        var i = mantidos.count - 1
        while i >= 0 && mantidos[i] == 9 { mantidos[i] = 0; i -= 1 }
        if i >= 0 { mantidos[i] += 1 } else { mantidos.insert(1, at: 0); inteiros += 1 }
    }
    let texto = mantidos.map(String.init).joined()
    return (x < 0 ? "-" : "") + agruparMilhar(String(texto.prefix(inteiros))) + (casas > 0 ? "," + texto.dropFirst(inteiros) : "")
}

/// A parte da obra com 1 casa ("38,0%"), no arredondamento da parte do total da soma da seleção, e "<0,1%" quando a parte
/// verdadeira fica entre 0 e 0,1%, como o "<1%" do anel. Sem total, "0,0%".
public func parteComUmaCasa(_ bruto: Double, total: Double) -> String {
    let pct = total > 0 ? bruto / total * 100 : 0
    if pct > 0 && pct < 0.1 { return "<0,1%" }
    return casasPtBR(pct, 1) + "%"
}

/// A linha do tópico no Relatório: "2 gastos · 38,0%"; na busca, "11 de 11 gastos · 38,0%", com o bruto só dos achados.
public func linhaDoTopicoNoRelatorio(_ n: Int, de total: Int? = nil, bruto: Double, total totalDaObra: Double) -> String {
    contagemDeGastos(n, de: total) + " · " + parteComUmaCasa(bruto, total: totalDaObra)
}
```

- [ ] **Step 4: Ver passar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'warning:|Test run with'
```
Expected: `━ Test run with 268 tests in 43 suites passed after 0.264 seconds with 4 known issues.` (`TopicoNoRelatorioTests` é nova, com 4), sem nenhum `warning:`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/TopicoNoRelatorio.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TopicoNoRelatorioTests.swift
git commit -m "feat: linha do tópico no relatório, com \"N de M gastos\" e 1 casa" -m "Cada bloco de tópico do Relatório da etapa 4 diz quantos gastos tem e a parte da obra com uma casa (\"2 gastos · 38,0%\"), que o site não mostra; na busca, \"11 de 11 gastos\", com o bruto só dos achados. A contagem serve também ao resumo dos achados e ao cabeçalho do tópico no PDF." -m "A casa decimal segue o toLocaleString pt-BR, o mesmo arredondamento da parte do total da soma da seleção, e abaixo de 0,1% a linha diz \"<0,1%\", como o \"<1%\" do anel. Regra só do app, com teste próprio e ainda sem tela."
```

### Task 13: Paginação da tabela do PDF, com a coluna pelo maior valor

A paginação do PDF como conta pura, sem UIKit (spec, "### 2. PDF", "Paginação no núcleo"), para o gerador do PR 4b. O gerador mede o texto de cada gasto na largura da coluna, com o mesmo `NSAttributedString` com que desenha, passa a altura de cada linha do texto para cá e desenha cada página na altura prevista. As medidas (`MedidasDoPDF`) são as do mockup e do protótipo do conselho (A4 de 595 × 842 pt; margens de 34, 50 e 44; cabeçalho de 47; subtítulo de 30 só na 1ª página da tabela; títulos das colunas de 18 em toda página; tópico de 20; gasto de no mínimo 15, com 3 de respiro; total de 22; venda de 18; aviso sem venda de 23, `parte2.css:153-167` e `parte2.js:163-164`); o PR 4b as acerta no desenho, e todas são parâmetros. As regras: a linha do gasto é o teto da soma das linhas do texto mais o respiro, nunca menos que a mínima (o `max(15, ceil(h) + 3)` do protótipo); cabe o que chega exatamente ao fim do espaço; o tópico vai para a página seguinte se não cabe com o 1º gasto (ou com a 1ª linha dele, quando ele é partido); o gasto que não cabe vai inteiro para a página seguinte, que repete o tópico com "(continuação)" e sem os totais; o gasto mais alto que uma página nova (descontado o tópico) é partido entre as linhas do texto, a partir do que sobra na página, e só o pedaço da linha 0 leva a data e os valores; na 1ª página da tabela ainda vazia, menor por causa do subtítulo (643 pt depois do tópico, contra 673 numa página nova), o 1º gasto que não cabe inteiro também é partido ali, porque abrir outra página a deixaria em branco (um gasto de 57 a 59 linhas, que só uma descrição acima de 500 caracteres alcança: o formulário recusa, mas o `normaliza` não corta); o fim (o total e as 3 linhas da venda, as 2 da estimada, ou o aviso sem venda) fica inteiro numa página; o rodapé diz "página N de M", com a página 1 (o resumo) na conta. O protótipo não partia a descrição (RESULTADO.md, "O que a medida não prova"). As colunas: as três de valor têm a largura do maior valor (ou do maior título, se ele for mais largo) e 6 pt de folga de cada lado; a data tem 63,5; o gasto fica com o resto, e a descrição é medida nessa coluna sem o recuo de 19 e a folga. Os números da tabela são em SF Mono, de avanço igual: o valor de texto mais longo é o mais largo, e o gerador mede só ele (`maiorValorDoPDF`); a correção leva o "+" e pode ser a mais longa. O protótipo usava colunas fixas, e valores na casa dos milhões passavam da coluna.

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/PaginacaoDoPDF.swift`
- Test (novo): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PaginacaoDoPDFTests.swift`

**Interfaces:**
- Consumes: `RelatorioDaObra`, `relatorioObra`, `FimDoRelatorio`, `fimRelatorio` e `duasCasasPtBR` (Relatorio.swift, PR 0).
- Produces: `MedidasDoPDF` (as medidas, todas `var`, com `espaco(_ pagina: Int) -> Double` e `alturaDoFim(_: FimDoRelatorio?) -> Double`); `valorNoPDF(_:) -> String` e `correcaoNoPDF(_:) -> String`; `maiorValorDoPDF(_ r: RelatorioDaObra) -> String`; `ColunasDoPDF` (`gasto`, `data`, `valor`, `texto`) e `colunasDoPDF(larguraDoMaiorValor:larguraDoMaiorTitulo:medidas:) -> ColunasDoPDF`; `GastoMedidoDoPDF` (`linhas: [Double]`); `ItemDoPDF` (`.topico(Int, continuacao: Bool)`, `.gasto(topico:gasto:linhas: Range<Int>)`, `.fim`); `PaginaDoPDF` (`itens`, `usado`); `PaginacaoDoPDF` (`paginas`, `total`); `rodapeDoPDF(pagina:de:) -> String`; `paginarTabelaDoPDF(_ topicos: [[GastoMedidoDoPDF]], fim: FimDoRelatorio?, medidas: MedidasDoPDF = MedidasDoPDF()) -> PaginacaoDoPDF`. Interna: `alturaDoGasto(_:_:)`.

- [ ] **Step 1: Escrever os testes**

O motor do desenho é falso nos testes: 40 caracteres por linha de 11,34 pt, a medida do protótipo para a letra de 9,5 pt. Uma função confere o que vale para toda paginação (nenhuma página fica vazia nem passa do espaço; o usado é a soma das linhas; todo gasto aparece, na ordem, com as linhas inteiras e sem repetir; a página que continua um tópico começa por ele com "(continuação)"; nenhum tópico sozinho no fim; o fim uma vez só, no último lugar). Os casos: uma página só; o espaço de cada página e as três alturas do fim; o limite exato, com páginas de 200 pt e linhas de 20 (a página que enche no limite, o fim que cabe nos últimos 20 pt e o que não cabe); o tópico que não fica sozinho, com 30 e com 40 pt sobrando; o gasto que cabe numa página nova e vai inteiro, menos na 1ª página ainda vazia (57, 58 e 59 linhas, partidos ali) e, com ela já ocupada, o de 58 linhas que vai inteiro para a seguinte; a descrição de 3.000 caracteres (75 linhas), no meio e no começo do tópico, e uma de 150 linhas em três pedaços; a obra de 5.000 gastos em 14 tópicos, com 6 descrições de 3.000 caracteres, pelo `relatorioObra`; e as colunas, com a correção como o maior texto.

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PaginacaoDoPDFTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/* A paginação da tabela do PDF (conta pura, sem UIKit): as colunas pelo maior valor, a quebra de página, o "(continuação)",
   a descrição maior que uma página, o fim inteiro e o "página N de M". O motor do desenho é falso aqui: 40 caracteres por
   linha de 11,34 pt, a medida do protótipo para a letra de 9,5 pt na coluna da descrição. */
struct PaginacaoDoPDFTests {
    static let linha = 11.34

    func medido(_ texto: String) -> GastoMedidoDoPDF {
        GastoMedidoDoPDF(linhas: Array(repeating: Self.linha, count: max(1, (texto.count + 39) / 40)))
    }

    func linhas(_ n: Int, de altura: Double = Self.linha) -> GastoMedidoDoPDF { GastoMedidoDoPDF(linhas: Array(repeating: altura, count: n)) }

    /// Páginas de 200 pt de tabela, sem cabeçalhos, com linhas de 20 pt: as contas do limite ficam inteiras.
    var redondas: MedidasDoPDF {
        var m = MedidasDoPDF()
        m.altura = 200; m.margemDeCima = 0; m.margemDeBaixo = 0; m.cabecalho = 0; m.subtitulo = 0; m.cabecalhoDaTabela = 0
        m.linhaDoTopico = 20; m.linhaMinimaDoGasto = 20; m.respiroDoGasto = 0; m.linhaDoTotal = 20; m.linhaDaVenda = 20; m.avisoSemVenda = 0
        return m
    }

    /// Confere o que vale para toda paginação: nenhuma página fica vazia nem passa do espaço; o usado é a soma das linhas; os
    /// gastos aparecem todos, na ordem, com as linhas do texto inteiras e sem repetir; a página que continua um tópico começa
    /// por ele com "(continuação)"; nenhum tópico fica sozinho no fim da página; o fim é o último item, uma vez só.
    func confere(_ p: PaginacaoDoPDF, _ topicos: [[GastoMedidoDoPDF]], fim: FimDoRelatorio?, _ m: MedidasDoPDF) {
        var pedacos: [(t: Int, g: Int, linhas: Range<Int>)] = []
        for (i, pagina) in p.paginas.enumerated() {
            #expect(!pagina.itens.isEmpty, "página \(i) vazia")
            #expect(pagina.usado <= m.espaco(i), "página \(i): \(pagina.usado) de \(m.espaco(i))")
            var soma = 0.0
            for (k, item) in pagina.itens.enumerated() {
                switch item {
                case let .topico(t, continuacao):
                    soma += m.linhaDoTopico
                    if continuacao { #expect(k == 0 && pedacos.last?.t == t, "página \(i): continuação fora do lugar") }
                    if !topicos[t].isEmpty, case let .gasto(t2, _, _)? = pagina.itens.dropFirst(k + 1).first {
                        #expect(t2 == t, "página \(i): tópico \(t) sem gasto embaixo")
                    } else if !topicos[t].isEmpty {
                        Issue.record("página \(i): tópico \(t) sozinho no fim")
                    }
                case let .gasto(t, g, l):
                    soma += alturaDoGasto(topicos[t][g].linhas[l], m)
                    pedacos.append((t, g, l))
                case .fim:
                    soma += m.alturaDoFim(fim)
                    #expect(i == p.paginas.count - 1 && k == pagina.itens.count - 1, "o fim não é o último item")
                }
            }
            #expect(abs(soma - pagina.usado) < 1e-9, "página \(i): usado \(pagina.usado), soma \(soma)")
            if i > 0, case .gasto? = pagina.itens.first { Issue.record("página \(i) começa por um gasto, sem o tópico") }
        }
        var esperados: [(Int, Int)] = []
        for (t, gs) in topicos.enumerated() { for g in gs.indices { esperados.append((t, g)) } }
        var proximo = 0
        for (t, g) in esperados {
            var linha = 0
            while proximo < pedacos.count, pedacos[proximo].t == t, pedacos[proximo].g == g {
                #expect(pedacos[proximo].linhas.lowerBound == linha, "gasto \(t).\(g): linhas fora de ordem")
                linha = pedacos[proximo].linhas.upperBound
                proximo += 1
            }
            #expect(linha == topicos[t][g].linhas.count, "gasto \(t).\(g): \(linha) de \(topicos[t][g].linhas.count) linhas")
        }
        #expect(proximo == pedacos.count, "pedaços a mais")
        #expect(p.paginas.flatMap(\.itens).filter { $0 == .fim }.count == 1)
    }

    @Test func umaPaginaSo() {
        let topicos = [[linhas(1), linhas(1), linhas(1)], [linhas(1), linhas(3)]]
        let p = paginarTabelaDoPDF(topicos, fim: .estimada(valor: 900_000, margem: 10_000))
        #expect(p.paginas.count == 1)
        #expect(p.paginas[0].itens == [.topico(0, continuacao: false), .gasto(topico: 0, gasto: 0, linhas: 0..<1),
                                       .gasto(topico: 0, gasto: 1, linhas: 0..<1), .gasto(topico: 0, gasto: 2, linhas: 0..<1),
                                       .topico(1, continuacao: false), .gasto(topico: 1, gasto: 0, linhas: 0..<1),
                                       .gasto(topico: 1, gasto: 1, linhas: 0..<3), .fim])
        // 20 + 3 × 15 + 20 + 15 + (35 + 3) + (22 + 2 × 18): o texto de 3 linhas tem 34,02 pt, que vão a 35, mais o respiro.
        #expect(p.paginas[0].usado == Double(20 + 45 + 20 + 15 + 38 + 58))
        #expect(p.total == 2)
        #expect(rodapeDoPDF(pagina: 2, de: p.total) == "página 2 de 2")
        confere(p, topicos, fim: .estimada(valor: 900_000, margem: 10_000), MedidasDoPDF())
    }

    @Test func espacoDaPaginaEFim() {
        let m = MedidasDoPDF()
        #expect(m.espaco(0) == 663)                     // 842 − 34 − 50 − 47 − 30 (o subtítulo) − 18
        #expect(m.espaco(1) == 693)
        #expect(m.espaco(7) == 693)
        #expect(m.alturaDoFim(.venda(valor: 1, data: "2026-06-20", lucroBruto: 1, acimaDoBanco: 1)) == 76)
        #expect(m.alturaDoFim(.estimada(valor: 1, margem: 1)) == 58)
        #expect(m.alturaDoFim(nil) == 45)
    }

    @Test func limiteExato() {
        let m = redondas
        // 20 do tópico + 9 gastos de 20 = 200: a página enche no limite e o 10º gasto vai para a seguinte, com a continuação.
        let dez = [Array(repeating: linhas(1, de: 20), count: 10)]
        let p = paginarTabelaDoPDF(dez, fim: .estimada(valor: 1, margem: 1), medidas: m)
        #expect(p.paginas.map(\.usado) == [200, Double(20 + 20 + 60)])
        #expect(p.paginas[1].itens.prefix(2) == [.topico(0, continuacao: true), .gasto(topico: 0, gasto: 9, linhas: 0..<1)])
        confere(p, dez, fim: .estimada(valor: 1, margem: 1), m)
        // O fim de 20 pt (sem venda, com o aviso de 0 pt aqui) cabe nos últimos 20 pt; o de 60, não.
        let oito = [Array(repeating: linhas(1, de: 20), count: 8)]
        #expect(paginarTabelaDoPDF(oito, fim: nil, medidas: m).paginas.count == 1)
        #expect(paginarTabelaDoPDF(oito, fim: .estimada(valor: 1, margem: 1), medidas: m).paginas.map(\.itens) == [
            [.topico(0, continuacao: false)] + (0..<8).map { .gasto(topico: 0, gasto: $0, linhas: 0..<1) }, [.fim]])
    }

    @Test func topicoNaoFicaSozinho() {
        let m = redondas
        // O 1º tópico deixa 30 pt: cabe o tópico (20), mas não o tópico com o 1º gasto (40). O 2º tópico vai inteiro para a
        // página seguinte, sem "(continuação)".
        let topicos = [[linhas(1, de: 50), linhas(1, de: 50), linhas(1, de: 50)], [linhas(1, de: 20), linhas(1, de: 20)]]
        let p = paginarTabelaDoPDF(topicos, fim: nil, medidas: m)
        #expect(p.paginas[0].usado == 170)
        #expect(p.paginas[1].itens.first == .topico(1, continuacao: false))
        confere(p, topicos, fim: nil, m)
        // Com 40 pt sobrando, o tópico e o 1º gasto ficam; o 2º gasto continua na seguinte.
        let justo = [[linhas(1, de: 70), linhas(1, de: 70)], [linhas(1, de: 20), linhas(1, de: 20)]]
        let q = paginarTabelaDoPDF(justo, fim: nil, medidas: m)
        #expect(q.paginas[0].itens.suffix(2) == [.topico(1, continuacao: false), .gasto(topico: 1, gasto: 0, linhas: 0..<1)])
        #expect(q.paginas[1].itens.prefix(2) == [.topico(1, continuacao: true), .gasto(topico: 1, gasto: 1, linhas: 0..<1)])
        confere(q, justo, fim: nil, m)
    }

    @Test func gastoQueCabeNumaPaginaNaoParte() {
        let m = redondas
        // 17 linhas de 10 pt (170): não cabem no que sobra (140) e cabem numa página nova com a continuação (180): vão inteiras.
        let topicos = [[linhas(1, de: 40), linhas(17, de: 10)]]
        let p = paginarTabelaDoPDF(topicos, fim: nil, medidas: m)
        #expect(p.paginas[0].itens.count == 2)
        #expect(p.paginas[1].itens.prefix(2) == [.topico(0, continuacao: true), .gasto(topico: 0, gasto: 1, linhas: 0..<17)])
        confere(p, topicos, fim: nil, m)
        // A linha curta fica com a altura mínima (20 pt aqui).
        #expect(paginarTabelaDoPDF([[linhas(1, de: 10)]], fim: nil, medidas: m).paginas[0].usado == Double(20 + 20 + 20))
        // A exceção é a 1ª página da tabela ainda vazia, menor por causa do subtítulo: 58 linhas (661 pt) cabem numa página
        // nova (673, depois do tópico), mas não nos 643 da 1ª. Abrir outra a deixaria em branco: o gasto é partido ali.
        let quaseUmaPagina = [[linhas(58)]]
        let q = paginarTabelaDoPDF(quaseUmaPagina, fim: nil)
        #expect(q.paginas.map(\.itens) == [[.topico(0, continuacao: false), .gasto(topico: 0, gasto: 0, linhas: 0..<56)],
                                           [.topico(0, continuacao: true), .gasto(topico: 0, gasto: 0, linhas: 56..<58), .fim]])
        for n in 57...59 { confere(paginarTabelaDoPDF([[linhas(n)]], fim: nil), [[linhas(n)]], fim: nil, MedidasDoPDF()) }
        // Com a 1ª página já ocupada, o mesmo gasto vai inteiro para a seguinte, com o tópico.
        let depois = [[linhas(1)], [linhas(58)]]
        let r = paginarTabelaDoPDF(depois, fim: nil)
        #expect(r.paginas[1].itens.prefix(2) == [.topico(1, continuacao: false), .gasto(topico: 1, gasto: 0, linhas: 0..<58)])
        confere(r, depois, fim: nil, MedidasDoPDF())
    }

    @Test func descricaoDe3000Caracteres() {
        // 75 linhas de 11,34 pt (851 pt com o respiro): maior que uma página. Começa no que sobra da 1ª página e continua na
        // seguinte, partida entre as linhas.
        let longa = medido(String(repeating: "Telha cerâmica ", count: 200))
        #expect(longa.linhas.count == 75)
        let topicos = [[linhas(1), longa, linhas(1)]]
        let p = paginarTabelaDoPDF(topicos, fim: nil)
        #expect(p.paginas.count == 2)
        // 1ª página: 663 − 20 do tópico − 15 do 1º gasto = 628; cabem 55 linhas (624 + 3 = 627 pt, pelo teto de 623,7).
        #expect(p.paginas[0].itens.last == .gasto(topico: 0, gasto: 1, linhas: 0..<55))
        #expect(p.paginas[1].itens.prefix(3) == [.topico(0, continuacao: true), .gasto(topico: 0, gasto: 1, linhas: 55..<75),
                                                .gasto(topico: 0, gasto: 2, linhas: 0..<1)])
        confere(p, topicos, fim: nil, MedidasDoPDF())
        // Como 1º gasto do tópico, ela leva o tópico junto, com a 1ª linha embaixo dele.
        let primeiro = [[linhas(40)], [longa]]
        let q = paginarTabelaDoPDF(primeiro, fim: nil)
        #expect(q.paginas[0].itens.suffix(2).first == .topico(1, continuacao: false))
        confere(q, primeiro, fim: nil, MedidasDoPDF())
        // Maior que duas páginas: três pedaços.
        let enorme = [[linhas(150)]]
        let r = paginarTabelaDoPDF(enorme, fim: .venda(valor: 1, data: "2026-06-20", lucroBruto: 1, acimaDoBanco: 1))
        #expect(r.paginas.count == 3)
        confere(r, enorme, fim: .venda(valor: 1, data: "2026-06-20", lucroBruto: 1, acimaDoBanco: 1), MedidasDoPDF())
    }

    @Test func obraDe5000Gastos() {
        let ids = ["terreno", "projeto", "matbasicos", "fundacao", "estrutura", "alvenaria", "telhado", "eletrica", "hidraulica",
                   "revest", "pintura", "maoobra", "extras", "outros"]
        let gastos: [ValorJSON] = (0..<5000).map { i in
            let descricao = i % 997 == 0 ? String(repeating: "Concreto usinado fck 30 ", count: 125) : String(repeating: "Cimento ", count: 1 + i % 9)
            return .objeto(["id": .texto("g\(i)"), "valor": .numero(Double(100 + (i * 7919) % 90_000) + 0.45), "topico": .texto(ids[i % 14]),
                            "descricao": .texto(descricao), "data": .texto("2025-\(i % 12 < 9 ? "0" : "")\(i % 12 + 1)-\(10 + i % 18)"),
                            "pagamento": .texto("pix")])
        }
        let obra = Obra(arvore: ["id": .texto("o1"), "valorEstimadoVenda": .numero(9_000_000), "gastos": .lista(gastos)])
        let r = relatorioObra(obra, hoje: "2026-10-12", taxa: 1)
        let fim = fimRelatorio(obra, hoje: "2026-10-12", taxa: 1)
        let topicos = r.grupos.map { $0.itens.map { medido($0.gasto.descricao) } }
        let p = paginarTabelaDoPDF(topicos, fim: fim)
        #expect(topicos.joined().count == 5000)
        #expect(p.paginas.count > 100)
        confere(p, topicos, fim: fim, MedidasDoPDF())
        #expect(rodapeDoPDF(pagina: p.total, de: p.total) == "página \(p.total) de \(p.total)")
    }

    @Test func colunaDeValorPeloMaiorValor() {
        #expect(valorNoPDF(319_847.85) == "319.847,85")
        #expect(correcaoNoPDF(46_338.31) == "+46.338,31")
        #expect(correcaoNoPDF(0) == "+0,00")
        let c = colunasDoPDF(larguraDoMaiorValor: 57)
        #expect(c == ColunasDoPDF(gasto: 236.5, data: 63.5, valor: 69, texto: 211.5))       // 595 − 2 × 44 − 63,5 − 3 × 69
        // O título da coluna, se for mais largo que o maior valor, manda.
        #expect(colunasDoPDF(larguraDoMaiorValor: 40, larguraDoMaiorTitulo: 60).valor == 72)
        // O maior texto pode ser a correção, pelo "+": R$ 900 mil de 2020, corrigido a 1% ao mês, passa de 1,9 milhão.
        let velha = Obra(arvore: ["id": .texto("o1"), "gastos": .lista([
            .objeto(["id": .texto("a"), "valor": .numero(900_000), "topico": .texto("terreno"), "data": .texto("2020-01-10")]),
            .objeto(["id": .texto("b"), "valor": .numero(5_000), "topico": .texto("projeto"), "data": .texto("2026-10-01")])])])
        let r = relatorioObra(velha, hoje: "2026-10-12", taxa: 1)
        let maior = maiorValorDoPDF(r)
        #expect(maior.hasPrefix("+1."))
        #expect(maior.count == 13)
    }
}
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter PaginacaoDoPDFTests 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'PaginacaoDoPDFTests.swift:[0-9:]* error: cannot find [^|]*' | sort -t: -k2,2n -u | head -3
```
Expected: o núcleo não compila:
```
PaginacaoDoPDFTests.swift:10:37: error: cannot find type 'GastoMedidoDoPDF' in scope
PaginacaoDoPDFTests.swift:14:62: error: cannot find type 'GastoMedidoDoPDF' in scope
PaginacaoDoPDFTests.swift:17:19: error: cannot find type 'MedidasDoPDF' in scope
```

- [ ] **Step 3: Implementar**

O 1º gasto de cada tópico é decidido junto com o tópico (inteiro, ou partido a partir dali); por isso só do 2º gasto em diante o que não cabe vai inteiro para a página seguinte. Os dois `while` que partem a descrição param no primeiro pedaço que não cabe (o `while … , cabe(…)` sai do laço; um `for … where` pularia a linha e seguiria). Uma linha mais alta que a página inteira vai sozinha, para o laço nunca prender.

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/PaginacaoDoPDF.swift`:

```swift
import Foundation

/* A tabela do PDF (da página 2 em diante) como conta pura (spec da etapa 4, "### 2. PDF", "Paginação no núcleo"): as colunas,
   com a de valor pela largura do maior valor, e onde cada página quebra. O desenho (UIKit, no PR do PDF) mede o texto de cada
   gasto na largura da coluna, pelo mesmo motor com que desenha, passa as alturas das linhas para cá e desenha cada página na
   altura prevista. As medidas são as do mockup e do protótipo (A4, `parte2.js:163-164`); o PR do PDF as acerta no desenho. */

/// As medidas da página e da tabela do PDF, em pontos.
public struct MedidasDoPDF: Equatable, Sendable {
    public var largura = 595.0
    public var altura = 842.0
    /// O rodapé "página N de M" mora na margem de baixo.
    public var margemDeCima = 34.0
    public var margemDeBaixo = 50.0
    public var margemDosLados = 44.0
    /// O logo e o título do relatório, em toda página.
    public var cabecalho = 47.0
    /// O "Gastos por tópico" da 1ª página da tabela.
    public var subtitulo = 30.0
    /// Os títulos das colunas, repetidos em toda página.
    public var cabecalhoDaTabela = 18.0
    public var linhaDoTopico = 20.0
    /// A linha do gasto: o texto e o respiro, nunca menos que a linha mínima.
    public var linhaMinimaDoGasto = 15.0
    public var respiroDoGasto = 3.0
    /// O fim: o total, cada linha da venda (ou da margem) e o aviso da obra sem venda estimada.
    public var linhaDoTotal = 22.0
    public var linhaDaVenda = 18.0
    public var avisoSemVenda = 23.0
    public var colunaDaData = 63.5
    /// A folga de cada lado da célula, e o recuo do texto do gasto, depois do ponto do tópico.
    public var folga = 6.0
    public var recuoDoGasto = 19.0

    public init() {}

    /// O espaço da tabela na página `i` da tabela (a 0 tem o subtítulo).
    public func espaco(_ i: Int) -> Double {
        altura - margemDeCima - margemDeBaixo - cabecalho - (i == 0 ? subtitulo : 0) - cabecalhoDaTabela
    }

    /// O fim: o total e a venda, o lucro e o acima do banco; ou a venda estimada e a margem; ou o aviso sem venda.
    public func alturaDoFim(_ fim: FimDoRelatorio?) -> Double {
        switch fim {
        case .venda: linhaDoTotal + 3 * linhaDaVenda
        case .estimada: linhaDoTotal + 2 * linhaDaVenda
        case nil: linhaDoTotal + avisoSemVenda
        }
    }
}

/// O número das colunas de valor, sem o "R$" (o título da coluna diz "(R$)"): "319.847,85".
public func valorNoPDF(_ v: Double) -> String { duasCasasPtBR(v) }

/// A correção, com o sinal: "+46.338,31".
public func correcaoNoPDF(_ v: Double) -> String { (v < 0 ? "" : "+") + duasCasasPtBR(v) }

/// O texto mais longo das colunas de valor (bruto, corrigido e correção de cada gasto, de cada tópico e do total). Os números
/// da tabela são em SF Mono, de avanço igual: o mais longo é o mais largo, e o desenho mede só ele.
public func maiorValorDoPDF(_ r: RelatorioDaObra) -> String {
    var maior = ""
    func ve(_ bruto: Double, _ corrigido: Double) {
        for t in [valorNoPDF(bruto), valorNoPDF(corrigido), correcaoNoPDF(corrigido - bruto)] where t.count > maior.count { maior = t }
    }
    for g in r.grupos {
        ve(g.bruto, g.corrigido)
        for item in g.itens { ve(item.gasto.valor, item.corrigido) }
    }
    ve(r.totalBruto, r.totalCorrigido)
    return maior
}

/// As colunas da tabela.
public struct ColunasDoPDF: Equatable, Sendable {
    /// A do gasto (o ponto do tópico e a descrição): o que sobra.
    public let gasto: Double
    public let data: Double
    /// Cada uma das três de valor.
    public let valor: Double
    /// A largura em que a descrição é medida e desenhada: a coluna do gasto sem o recuo e a folga.
    public let texto: Double
}

/// As colunas: as três de valor com a largura do maior valor (`maiorValorDoPDF`, medido) ou do maior título, se ele for mais
/// largo, e a folga dos dois lados; a data fixa; o gasto com o resto da largura entre as margens.
public func colunasDoPDF(larguraDoMaiorValor: Double, larguraDoMaiorTitulo: Double = 0, medidas m: MedidasDoPDF = MedidasDoPDF()) -> ColunasDoPDF {
    let valor = max(larguraDoMaiorValor, larguraDoMaiorTitulo) + 2 * m.folga
    let gasto = m.largura - 2 * m.margemDosLados - m.colunaDaData - 3 * valor
    return ColunasDoPDF(gasto: gasto, data: m.colunaDaData, valor: valor, texto: gasto - m.recuoDoGasto - m.folga)
}

/// Um gasto da tabela, medido: a altura de cada linha do texto da descrição, na largura `ColunasDoPDF.texto`.
public struct GastoMedidoDoPDF: Equatable, Sendable {
    public var linhas: [Double]
    public init(linhas: [Double]) { self.linhas = linhas }
}

/// O que vai numa linha da tabela.
public enum ItemDoPDF: Equatable, Sendable {
    /// O tópico `topico` (o índice no relatório), com os totais; na continuação, com "(continuação)" e sem eles.
    case topico(Int, continuacao: Bool)
    /// As linhas `linhas` do texto do gasto `gasto` do tópico. O pedaço que começa na linha 0 leva a data e os valores.
    case gasto(topico: Int, gasto: Int, linhas: Range<Int>)
    /// O fim inteiro.
    case fim
}

/// Uma página da tabela e o espaço que ela usa.
public struct PaginaDoPDF: Equatable, Sendable {
    public internal(set) var itens: [ItemDoPDF] = []
    public internal(set) var usado = 0.0
}

/// As páginas da tabela, que vêm depois da página 1 (o resumo).
public struct PaginacaoDoPDF: Equatable, Sendable {
    public let paginas: [PaginaDoPDF]
    /// Quantas páginas o PDF tem, com a página 1.
    public var total: Int { paginas.count + 1 }
}

/// "página 2 de 5", no rodapé de toda página (a 1 é o resumo).
public func rodapeDoPDF(pagina: Int, de total: Int) -> String { "página \(pagina) de \(total)" }

/// A linha de um pedaço do texto de um gasto: as linhas e o respiro, arredondadas para cima, nunca menos que a mínima.
func alturaDoGasto(_ linhas: ArraySlice<Double>, _ m: MedidasDoPDF) -> Double {
    max(m.linhaMinimaDoGasto, linhas.reduce(0, +).rounded(.up) + m.respiroDoGasto)
}

/// Pagina a tabela: `topicos` traz, na ordem do relatório, cada gasto medido. Regras:
/// - o tópico vai para a página seguinte se não cabe com o 1º gasto (ou com a 1ª linha dele, se ele for partido);
/// - o gasto que não cabe vai inteiro para a página seguinte, que repete o tópico com "(continuação)", sem os totais;
/// - o gasto maior que uma página é partido entre as linhas do texto, a partir do que sobra na página;
/// - na página ainda vazia (a 1ª da tabela), o 1º gasto que não cabe inteiro também é partido ali;
/// - o fim fica inteiro numa página.
public func paginarTabelaDoPDF(_ topicos: [[GastoMedidoDoPDF]], fim: FimDoRelatorio?, medidas m: MedidasDoPDF = MedidasDoPDF()) -> PaginacaoDoPDF {
    var paginas = [PaginaDoPDF()]
    func cabe(_ h: Double) -> Bool { paginas[paginas.count - 1].usado + h <= m.espaco(paginas.count - 1) }
    func por(_ item: ItemDoPDF, _ h: Double) {
        paginas[paginas.count - 1].itens.append(item)
        paginas[paginas.count - 1].usado += h
    }
    func continua(_ t: Int) {
        paginas.append(PaginaDoPDF())
        por(.topico(t, continuacao: true), m.linhaDoTopico)
    }
    // O espaço de uma página nova, depois do tópico: o gasto mais alto que ele é partido.
    let paginaNova = m.espaco(1) - m.linhaDoTopico
    for (t, gastos) in topicos.enumerated() {
        // Na página ainda vazia (a 1ª da tabela, menor por causa do subtítulo), o 1º gasto que não cabe inteiro é partido ali:
        // abrir outra página a deixaria em branco.
        let vazia = paginas[paginas.count - 1].itens.isEmpty
        let limite = vazia ? m.espaco(paginas.count - 1) - m.linhaDoTopico : paginaNova
        let primeiro = gastos.first.map { g -> Double in
            let inteiro = alturaDoGasto(g.linhas[...], m)
            return inteiro <= limite ? inteiro : alturaDoGasto(g.linhas.prefix(1), m)
        } ?? 0
        if !cabe(m.linhaDoTopico + primeiro) { paginas.append(PaginaDoPDF()) }
        por(.topico(t, continuacao: false), m.linhaDoTopico)
        for (g, gasto) in gastos.enumerated() {
            let inteiro = alturaDoGasto(gasto.linhas[...], m), n = gasto.linhas.count
            // O 1º gasto já foi decidido com o tópico: inteiro, ou partido a partir daqui.
            if g > 0 && !cabe(inteiro) && inteiro <= paginaNova { continua(t) }
            if cabe(inteiro) {
                por(.gasto(topico: t, gasto: g, linhas: 0..<n), inteiro)
                continue
            }
            var a = 0
            while a < n {
                var b = a
                while b < n, cabe(alturaDoGasto(gasto.linhas[a...b], m)) { b += 1 }
                if b == a {
                    continua(t)
                    while b < n, cabe(alturaDoGasto(gasto.linhas[a...b], m)) { b += 1 }
                    b = max(b, a + 1)
                }
                por(.gasto(topico: t, gasto: g, linhas: a..<b), alturaDoGasto(gasto.linhas[a..<b], m))
                a = b
            }
        }
    }
    let alturaDoFim = m.alturaDoFim(fim)
    if !cabe(alturaDoFim) { paginas.append(PaginaDoPDF()) }
    por(.fim, alturaDoFim)
    return PaginacaoDoPDF(paginas: paginas)
}
```

- [ ] **Step 4: Ver passar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'warning:|Test run with'
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter 'PaginacaoDoPDFTests/obraDe5000Gastos' 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep 'Test obraDe5000Gastos() passed'
```
Expected: `━ Test run with 276 tests in 44 suites passed after 0.237 seconds with 4 known issues.` (`PaginacaoDoPDFTests` é nova, com 8), sem nenhum `warning:`; a obra de 5.000 gastos, do relatório à paginação conferida, em debug: `✔ Test obraDe5000Gastos() passed after 0.095 seconds.`

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/PaginacaoDoPDF.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PaginacaoDoPDFTests.swift
git commit -m "feat: paginação da tabela do PDF no núcleo, coluna pelo maior valor" -m "O PDF da etapa 4 desenha a tabela de gastos em UIKit, e a quebra de página sai de uma conta pura no núcleo, que se testa sem tela. Ela recebe a altura de cada linha do texto de cada gasto, medida pelo mesmo motor do desenho, e devolve o que vai em cada página." -m "O tópico nunca fica sozinho no fim da página; o gasto que não cabe passa para a seguinte, que repete o tópico com \"(continuação)\" e sem os totais; a descrição maior que uma página é partida entre as linhas do texto, como a que não cabe na primeira página da tabela, que assim não sai em branco; o fim, com o total e a venda, fica inteiro. O rodapé diz \"página N de M\", contando a página do resumo. As três colunas de valor têm a largura do maior valor da tabela, que em fonte mono é o de texto mais longo, e a descrição fica com o resto."
```

### Task 14: Teto de 75 min no job laudo-etapa3

O job `laudo-etapa3` do `app-ios.yml` (as leituras e as auditorias da tela Orçamento e das folhas de origem) tem teto de 60 min (`app-ios.yml:425`). Nos 15 runs de 24 a 29/10, sem cena nova, ele levou 46 min na mediana e chegou a 57,3 (run 40157409790, que reprovou e coletou o diagnóstico): é o job da CI mais perto do teto. O teto passa a 75 min, e o comentário do job registra o porquê, como os outros. Nenhum teste muda: a guarda do `tests/workflow.test.cjs` só cobra que todo job do app nativo tenha `timeout-minutes`. Decisão do Orquestrador em 29/10 (Decisões): a linha entra no 0b, que roda todos os jobs e não vai ao site, e o corpo do PR diz isso.

**Files:**
- Modify: `.github/workflows/app-ios.yml`

- [ ] **Step 1: Subir o teto**

Em `.github/workflows/app-ios.yml`:

```diff
--- a/.github/workflows/app-ios.yml
+++ b/.github/workflows/app-ios.yml
@@ -422,7 +422,9 @@ jobs:
     # estas três passam para o laudo-etapa3-b (como o app-etapa3-b), que também roda as leituras do PR 3.
     # No fim do PR 3, sem as três, 46,2 min: o orçamento em 22,9 e a leitura das folhas de origem em 15,0 (run
     # 40526951027, 2ª tentativa; na 1ª, a VM lenta passou dos 10 s de espera na cena do fim do A pagar).
-    timeout-minutes: 60
+    # Na etapa 4 (PR 0b), o teto passa de 60 para 75: nos 15 runs de 24 a 29/10, sem cena nova, o job levou 46 min na
+    # mediana e chegou a 57,3 (run 40157409790, que reprovou e coletou o diagnóstico).
+    timeout-minutes: 75
     steps:
       - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
       - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
```

- [ ] **Step 2: Ver passar**

Run:
```bash
node --test tests/workflow.test.cjs 2>&1 | grep -E '^ℹ (pass|fail)'
npm run test:unit 2>&1 | grep -E '^ℹ (pass|fail)'
git diff --stat
```
Expected: `ℹ pass 1` e `ℹ fail 0` na guarda; `ℹ pass 407` e `ℹ fail 0` no `test:unit`; e só o workflow no diff:
```
 .github/workflows/app-ios.yml | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)
```
Na CI do PR, o `laudo-etapa3` aparece com o teto novo e roda como antes.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/app-ios.yml
git commit -m "ci: teto de 75 min no job laudo-etapa3" -m "O job do laudo das telas da etapa 3 levou 46 min na mediana dos 15 runs de 24 a 29/10 e chegou a 57,3, a menos de 3 min do teto de 60, sem cena nova. Com 75, uma VM lenta, ou uma reprovação que coleta o diagnóstico, não corta o job antes de ele subir o resultado."
```

---

## PR 1a (app): os tokens globais da identidade nova

O PR leva ao app inteiro os tokens globais da identidade nova (confirmação 5 de 29/10): os tokens novos do catálogo de cores, sem uso (Tarefa 16); o âmbar de texto do claro mais escuro, #5E3A03 no `AlertaNoVidro` (Tarefa 17); e a cápsula de abas na borda de 16 pt, em vez de 20 (Tarefa 18). O globo e o halo do título, que o spec põe neste PR, foram medidos e não mudam (achados 1 e 2, abaixo). O risco é o das peças compartilhadas: o âmbar muda dois textos da etapa 3 (o aviso dos tópicos na linha do orçamento e o "Passou … do previsto" da tela Orçamento), e a cápsula muda o pé de toda tela de Obras e de Ajustes. A comparação do laudo inteiro, palavra por palavra, prova que nada mais mudou e que o que mudou subiu. Fica escondido na `main` até o PR 1b: os 19 tokens novos, que nenhuma tela usa. Portão da CI: "tudo, com a comparação" (o PR mexe no catálogo de cores e na cápsula). Marco 1. Este PR sempre espera o OK do Giovani, pelos prints antes × depois das telas principais no claro e no escuro (ponto de controle do fim do PR, passo 4), e o time segue no 1b, empilhado, enquanto ele olha.

- **Branch:** `feat/tokens-globais-da-identidade-nova`
- **Título:** `feat: tokens globais da identidade nova no app inteiro`

### Mapa de arquivos

| Arquivo | Tarefas |
| --- | --- |
| `scripts/compara-laudo.mjs` (novo) e `package.json` | 15 (o comparador do laudo palavra por palavra) |
| `tests/compara-laudo.test.mjs` (novo) | 15 |
| `scripts/cores-app-ios.mjs` | 16 (os tokens novos e os dois pares sólidos), 17 (o claro do `AlertaNoVidro`) |
| `app-ios/Custta/Assets.xcassets/Esmeralda/*.colorset` (gerado) | 16 (19 novos), 17 (`AlertaNoVidro`) |
| `app-ios/Custta/Identidade/Paleta.swift` | 16 |
| `app-ios/Custta/Identidade/CapsulaDeAbas.swift` | 18 |
| `app-ios/CusttaTests/CoresTests.swift` | 16, 17 |
| `app-ios/CusttaTests/OrcamentoTests.swift` e `app-ios/CusttaTests/TelaOrcamentoTests.swift` | 17 (o âmbar do claro nos testes da etapa 3) |
| `tests/app-ios.test.cjs` | 17 |
| `app-ios/CusttaUITests/AjustesUITests.swift` | 18 |

Linhas de produção: 29 de Swift (27 no `Paleta.swift`, 2 no `CapsulaDeAbas.swift`), abaixo dos ~50–150 da tabela do spec, porque três tokens do mockup reaproveitam os do app e o globo e o halo não mudam. Fora da conta, como o spec manda: o script das cores (32) e o catálogo gerado (728, os 19 colorsets novos e o do `AlertaNoVidro`).

### Ponto de controle do fim do PR

No Mac, com o produto da ponta do PR e o da `main` de antes dele (o pai do commit da Tarefa 15), cada um compilado no seu DerivedData e copiado com `cp -c`, para os dois simuladores rodarem ao mesmo tempo sem compilar por cima de uma rodada. Tudo fica numa pasta sua, fora do repositório (`P`), e não no `/tmp`, que é o mesmo dos outros agentes do Mac. Antes dos dois builds, ponha nos dois worktrees, o do PR e o da `main`, o teste dos prints do passo 4 (`app-ios/CusttaUITests/PrintsDoPR1aUITests.swift`, fora do commit). Na raiz do worktree do PR:

```bash
P=<uma pasta sua, fora do repositório>
UMAX=<udid do seu Pro Max>; U18=<udid do seu 18 Pro>
# o produto de depois: a ponta do PR
xcodebuild build-for-testing "${XB[@]}" -derivedDataPath "$P/dd-depois" 2>&1 | grep -E "error:|TEST BUILD" | tail -1
rm -rf "$P/depois"; cp -c -R "$P/dd-depois/Build/Products" "$P/depois"
# o de antes: a main de antes do PR, num worktree dela e noutro DerivedData
# (o caminho do git vai por extenso: com caminho em variável, o git cai na guarda do worktree)
git worktree add --detach <P>/main <o pai do commit da Tarefa 15>
(cd "$P/main" && xcodebuild build-for-testing "${XB[@]}" -derivedDataPath "$P/dd-antes" 2>&1 | grep -E "error:|TEST BUILD" | tail -1)
rm -rf "$P/antes"; cp -c -R "$P/dd-antes/Build/Products" "$P/antes"
# uma rodada: o resultado velho apagado (o xcodebuild recusa um -resultBundlePath que já existe), a barra em 9:41
# e o app desinstalado (sem isso, o simulador pode ficar com o produto da rodada anterior e comparar antes × antes)
rodar() {   # rodar <antes|depois> <udid> <nome> <-only-testing…>: o resultado em $P/<nome>.xcresult e o log em $P/<nome>.log
  local produto=$1 u=$2 nome=$3; shift 3
  rm -rf "$P/$nome.xcresult"
  xcrun simctl status_bar "$u" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 >/dev/null 2>&1
  xcrun simctl uninstall "$u" br.com.custta.app >/dev/null 2>&1
  xcodebuild test-without-building -xctestrun "$P/$produto"/Custta_*.xctestrun -destination "platform=iOS Simulator,id=$u" \
    -collect-test-diagnostics never -resultBundlePath "$P/$nome.xcresult" "$@" > "$P/$nome.log" 2>&1
  grep -E "Executed [0-9]+ test" "$P/$nome.log" | tail -1
}
```

Os itens 1 e 2 rodam ao mesmo tempo, cada um no seu terminal, com o mesmo `P`, os udids e o `rodar`:

1. **O laudo inteiro no Pro Max, comparado palavra por palavra com o da `main`** (spec, "Testes e validação", item 6; memória `laudo-inteiro-no-pro-max-no-fim-do-pr`; na CI, só o portão, achado 5). As duas rodadas no mesmo Pro Max, uma depois da outra, e o comparador do PR (Tarefa 15) sobre os dois resultados:
   ```bash
   rodar antes "$UMAX" laudo-antes -only-testing:CusttaUITests/LeituraNoVidroUITests
   rodar depois "$UMAX" laudo-depois -only-testing:CusttaUITests/LeituraNoVidroUITests
   node scripts/compara-laudo.mjs "$P/laudo-antes.xcresult" "$P/laudo-depois.xcresult" "$P/laudo-cmp" --detalhe > "$P/laudo-cmp.txt"
   tail -1 "$P/laudo-cmp.txt"
   ```
   Expected: as duas rodadas com `Executed 18 tests, with 0 failures` (~53 min cada: 3198 e 3207 s), e a comparação (Pro Max, iOS 27, `767ebe9` × ponta):
   ```
   TOTAL: 175 cenas, 3590 palavras, 3555 idênticas, 3 mudadas, 32 deslocadas, 0 sem par, 0 abaixo de 4.5
   ```
   - As 3 mudadas são as palavras âmbar do claro (Tarefa 17), e as três sobem: "obra com orçamento por tópico, claro" 6,43 → 7,96 (pior pixel 6,36 → 7,87); "tela Orçamento, topo, claro" 6,42 → 7,95 e 7,24 → 8,96.
   - As 32 deslocadas são os rótulos da cápsula nas 16 cenas "abas sobre a lista" (Tarefa 18): "Obras" 2 pt à esquerda e "Ajustes" 2 pt à direita (no Pro Max, de x 246 para 248), a mesma cor e o mesmo tamanho. Em 26 delas a nota é a mesma; nas outras 6, muda com a parte da lista que passa por baixo do rótulo (a menor dessas 6 fica em 6,79:1, pior pixel 6,71, e o maior recuo é de 10,91 para 10,25). O rótulo da aba escolhida fica na pílula sólida e tem a mesma nota antes e depois.
   - As outras 159 cenas, com as telas das etapas 1 a 3 inteiras (obra, folhas, Ajustes, entrar, orçamento, A pagar, afazeres e busca, nos dois temas, na letra padrão e na máxima, com Aumentar contraste), ficam idênticas palavra por palavra.
2. **Os testes inteiros no 18 Pro** (as auditorias entram aqui, na `AuditoriaUITests`):
   ```bash
   rodar depois "$U18" tudo -only-testing:CusttaTests -only-testing:CusttaUITests -skip-testing:CusttaUITests/LeituraNoVidroUITests
   grep -E "Test run with" "$P/tudo.log"
   ```
   Expected: nas telas, `Executed 221 tests, with 1 test skipped and 2 failures`, as duas fora do PR (conferidas); na unidade, `✔ Test run with 171 tests in 33 suites passed`.
   - `AuditoriaUITests/testContrasteDaObraNosDoisTemas`: `Audit failed to complete in time` (Code=-56), a carga das duas rodadas juntas (memória `portao-nos-dois-simuladores-em-paralelo`). A `AuditoriaUITests` inteira, sozinha, com o mesmo produto (`rodar depois "$U18" auditoria -only-testing:CusttaUITests/AuditoriaUITests`): `Executed 20 tests, with 0 failures`.
   - `FolhasDeOrigemUITests/testASetaDoIndicadorAbreAFolhaDoAPagar` (FolhasDeOrigemUITests.swift:132): `XCTAssertTrue failed - Novembro de 2026, R$ 13.250,00`. Reprova igual na `main` de antes do PR (`767ebe9`): o teste depende do dia (achado 3).
3. **Node:** `npm run test:unit 2>&1 | tail -8`. Expected: `ℹ tests 411`, `ℹ pass 411` e `ℹ fail 0` (3 deles são do comparador, Tarefa 15).
4. **Os prints antes × depois para o OK do Giovani**, no 18 Pro, depois do item 2, com a barra de status em 9:41 e o fundo parado (`-custta.reduzirMovimento YES`): entrar, a lista de obras, a obra (com o orçamento por tópico, onde está o aviso âmbar), a tela Orçamento no topo e rolada, a folha do gasto, Ajustes e a lista vazia (o globo, achado 1), no claro e no escuro, em `$P/prints` (`antes/`, `depois/` e `lado-a-lado/`). A maioria sai do teste de tela fora do commit, posto nos dois worktrees antes dos builds:
   ```swift
   import XCTest

   /* FORA DO COMMIT: os prints antes × depois do PR 1a da etapa 4 (as telas principais no claro e no escuro,
      com o mesmo estado e a mesma rolagem nos dois commits). PRINTS_DIR e PRINTS_ROTULO vêm de TEST_RUNNER_*. */
   final class PrintsDoPR1aUITests: XCTestCase {
       override func setUp() { continueAfterFailure = true }

       @MainActor private func gravar(_ app: XCUIApplication, _ nome: String) {
           let ambiente = ProcessInfo.processInfo.environment
           guard let dir = ambiente["PRINTS_DIR"], let rotulo = ambiente["PRINTS_ROTULO"] else { return XCTFail("sem PRINTS_DIR") }
           let pasta = URL(fileURLWithPath: dir).appendingPathComponent(rotulo)
           try? FileManager.default.createDirectory(at: pasta, withIntermediateDirectories: true)
           Thread.sleep(forTimeInterval: 2.5)
           try? XCUIScreen.main.screenshot().pngRepresentation.write(to: pasta.appendingPathComponent("\(nome).png"))
           app.terminate()
       }

       @MainActor func testPrints() {
           for tema in ["escuro", "claro"] {
               let combo = ["-custta.tema", tema, "-custta.reduzirMovimento", "YES"]
               var app = abrirApp(conta: "nenhuma", argumentos: combo)
               XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 15))
               gravar(app, "1-entrar-\(tema)")

               app = abrirApp(conta: "senha", dados: "vitrine", argumentos: combo)
               XCTAssertTrue(app.elemento("obra-v1").waitForExistence(timeout: 15))
               gravar(app, "2-obras-\(tema)")

               app = abrirApp(conta: "senha", dados: "porTopico", abrir: "obra:v1", argumentos: combo)
               XCTAssertTrue(app.elemento("indicadorOrcamento").waitForExistence(timeout: 15))
               gravar(app, "3-obra-\(tema)")

               app = abrirApp(conta: "senha", dados: "porTopico", abrir: "orcamento:v1", argumentos: combo + ["-custta.rolagem", "700"])
               XCTAssertTrue(app.elemento("tituloPequenoDaBarra").waitForExistence(timeout: 15))
               gravar(app, "4-orcamento-rolado-\(tema)")

               app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1", argumentos: combo + ["-custta.folha", "detalhes"])
               XCTAssertTrue(app.elemento("linhaTopico").waitForExistence(timeout: 15))
               gravar(app, "5-folha-do-gasto-\(tema)")

               app = abrirApp(conta: "senha", dados: "vitrine", argumentos: combo)
               app.abrirAba("ajustes")
               XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 15))
               gravar(app, "6-ajustes-\(tema)")
           }
           // O globo dentro do app, no escuro, com a aurora parada e quase nada por cima (a medida do brilho dos pontos).
           let app = abrirApp(conta: "senha", dados: "vazio", argumentos: ["-custta.tema", "escuro", "-custta.reduzirMovimento", "YES"])
           XCTAssertTrue(app.elemento("obrasVazio").waitForExistence(timeout: 15))
           gravar(app, "7-globo-lista-vazia-escuro")
       }
   }
   ```
   Rodado com os dois produtos (`PRINTS_DIR` e `PRINTS_ROTULO` chegam ao teste pelo prefixo `TEST_RUNNER_`), cada rodada com `Executed 1 test, with 0 failures`:
   ```bash
   export TEST_RUNNER_PRINTS_DIR="$P/prints"
   export TEST_RUNNER_PRINTS_ROTULO=antes; rodar antes "$U18" prints-antes -only-testing:CusttaUITests/PrintsDoPR1aUITests
   export TEST_RUNNER_PRINTS_ROTULO=depois; rodar depois "$U18" prints-depois -only-testing:CusttaUITests/PrintsDoPR1aUITests
   ```
   A tela Orçamento no topo (`4b-…`, onde ficam os "Passou … do previsto") sai do `simctl launch`, com cada produto instalado de novo:
   ```bash
   xcrun simctl status_bar "$U18" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
   for rotulo in antes depois; do
     xcrun simctl uninstall "$U18" br.com.custta.app
     xcrun simctl install "$U18" "$P/$rotulo/Debug-iphonesimulator/Custta.app"
     for tema in escuro claro; do
       SIMCTL_CHILD_CUSTTA_SERVICOS=falsos SIMCTL_CHILD_CUSTTA_CONTA=senha SIMCTL_CHILD_CUSTTA_DADOS=porTopico \
       SIMCTL_CHILD_CUSTTA_ABRIR=orcamento:v1 xcrun simctl launch --terminate-running-process "$U18" br.com.custta.app \
         -custta.tema $tema -custta.reduzirMovimento YES > /dev/null
       sleep 8
       xcrun simctl io "$U18" screenshot "$P/prints/$rotulo/4b-orcamento-topo-$tema.png" > /dev/null 2>&1
     done
   done
   xcrun simctl terminate "$U18" br.com.custta.app; xcrun simctl uninstall "$U18" br.com.custta.app
   ```
   O lado a lado e a contagem saem deste script, salvo fora do repositório (`$P/lado-a-lado.py`) e rodado com `python3 "$P/lado-a-lado.py" "$P/prints"` (sem o `-I`: o PIL fica no site do usuário):
   ```python
   """Prints antes × depois do PR 1a: o lado a lado de cada tela e o que mudou (pixels com Δ > 8 e a caixa deles, em pt).
   Os 34 pt de baixo ficam fora da conta, como no laudo: a barra de início do sistema aparece numa rodada e não noutra.
   uso: python3 lado-a-lado.py <pasta com antes/ e depois/>"""
   import os, sys
   from PIL import Image, ImageChops, ImageDraw
   base = sys.argv[1]
   saida = os.path.join(base, 'lado-a-lado')
   os.makedirs(saida, exist_ok=True)
   for nome in sorted(os.listdir(os.path.join(base, 'antes'))):
       a = Image.open(os.path.join(base, 'antes', nome)).convert('RGB')
       d = Image.open(os.path.join(base, 'depois', nome)).convert('RGB')
       dif = ImageChops.difference(a, d).convert('L').point(lambda v: 255 if v > 8 else 0)
       dif = dif.crop((0, 0, dif.width, dif.height - 34 * 3))
       caixa = dif.getbbox()
       n = sum(1 for v in dif.getdata() if v)
       acima = sum(1 for v in dif.crop((0, 0, dif.width, 789 * 3)).getdata() if v)
       onde = 'nada' if not caixa else f'x {caixa[0]/3:.0f}–{caixa[2]/3:.0f} pt, y {caixa[1]/3:.0f}–{caixa[3]/3:.0f} pt'
       print(f'{nome}: {n} px com Δ > 8 ({onde}); acima da cápsula: {acima} px')
       w, h = a.width // 2, a.height // 2
       lado = Image.new('RGB', (2 * w + 30, h + 60), 'white')
       lado.paste(a.resize((w, h)), (0, 60)); lado.paste(d.resize((w, h)), (w + 30, 60))
       t = ImageDraw.Draw(lado)
       t.text((10, 15), 'antes (main)', fill='black'); t.text((w + 40, 15), 'depois (PR 1a)', fill='black')
       lado.save(os.path.join(saida, nome))
   ```
   Expected (18 Pro, iOS 27; pixels com Δ > 8 em qualquer canal, e a caixa deles em pt, ÷ 3):
   ```
   1-entrar-claro.png: 0 px com Δ > 8 (nada); acima da cápsula: 0 px
   1-entrar-escuro.png: 0 px com Δ > 8 (nada); acima da cápsula: 0 px
   2-obras-claro.png: 18672 px com Δ > 8 (x 15–386 pt, y 790–840 pt); acima da cápsula: 0 px
   2-obras-escuro.png: 19188 px com Δ > 8 (x 16–386 pt, y 790–840 pt); acima da cápsula: 0 px
   3-obra-claro.png: 25356 px com Δ > 8 (x 15–386 pt, y 496–840 pt); acima da cápsula: 7770 px
   3-obra-escuro.png: 19469 px com Δ > 8 (x 16–386 pt, y 790–840 pt); acima da cápsula: 0 px
   4-orcamento-rolado-claro.png: 21388 px com Δ > 8 (x 15–386 pt, y 790–840 pt); acima da cápsula: 0 px
   4-orcamento-rolado-escuro.png: 22553 px com Δ > 8 (x 16–386 pt, y 790–840 pt); acima da cápsula: 0 px
   4b-orcamento-topo-claro.png: 27164 px com Δ > 8 (x 15–386 pt, y 495–840 pt); acima da cápsula: 10101 px
   4b-orcamento-topo-escuro.png: 19391 px com Δ > 8 (x 16–386 pt, y 790–840 pt); acima da cápsula: 0 px
   5-folha-do-gasto-claro.png: 0 px com Δ > 8 (nada); acima da cápsula: 0 px
   5-folha-do-gasto-escuro.png: 0 px com Δ > 8 (nada); acima da cápsula: 0 px
   6-ajustes-claro.png: 13478 px com Δ > 8 (x 15–387 pt, y 790–840 pt); acima da cápsula: 0 px
   6-ajustes-escuro.png: 13823 px com Δ > 8 (x 16–386 pt, y 790–840 pt); acima da cápsula: 0 px
   7-globo-lista-vazia-escuro.png: 19213 px com Δ > 8 (x 16–386 pt, y 790–840 pt); acima da cápsula: 0 px
   ```
   A regra: acima da cápsula (y < 789 pt), 0 px, menos as linhas âmbar do claro na obra (y 496–510 pt) e no topo da tela Orçamento (y 495–507 e 571–583 pt), as palavras mudadas do laudo; a cápsula fica em y 790–840 pt; a entrada, sem cápsula, e a folha do gasto, com a cápsula atrás da folha, não mudam. Os 15 pares (antes à esquerda, depois à direita) vão ao Giovani com o pedido de OK do 1a. O pedido diz também, numa linha, que o secundário do Fosco no claro fica #3B574B (`SecundarioFosco`, `scripts/cores-app-ios.mjs:51`), fora do "#3B574B → #2F4A3F" aprovado para o app inteiro, pela recomendação do spec ("o Fosco fica como está, e o laudo do Fosco confere"). No fim, apague o teste dos prints do worktree do PR e remova o da `main` (`git worktree remove --force <P>/main`).

### Achados que mudam o spec ou uma decisão

1. **O globo não muda** (spec, "Globo": "fica com o mais apagado dos dois"). Medido no print `7-globo-lista-vazia-escuro` do ponto de controle (a lista vazia no escuro, `CUSTTA_DADOS=vazio`, com o fundo parado: o globo aparece abaixo do cartão, sem nada por cima) e no mockup (a aurora e o globo do `parte1.css` sozinhos no Chromium, a 402 × 874 pt em escala 3). Nos dois, na mesma região (x 220–400 pt, y 345–600 pt), o contraste de cada pixel contra a mediana de 31 px em volta (o fundo local, que tira a diferença da aurora), no p99,5. O do app, a 40% no escuro desde 09/10 (Globo.swift:82), dá 2,46:1 (máximo 2,64), antes e depois do PR; o do mockup, a 70% do mesmo desenho (`parte1.css:117`, sobre o `etapa3/globo/esmeralda.png`), 3,93:1 (máximo 4,15). O do app já é o mais apagado dos dois. O mockup da etapa 3 já desenhava o app a 40% (`etapa3/parte1.html:916`); o 70% da etapa 4 foi um passo para baixo a partir do 100% do quadro, e não do app. No claro, os dois ficam a 40%. A tela de entrar fica com o globo inteiro, como hoje: o mockup não a desenha, e o 70% veio do texto sobre o vidro com os pontos atrás, que a entrada não tem. Recomendação: o spec troca "o plano mede" pelo resultado (40% no app escuro, nada muda) e diz que a entrada fica de fora.
2. **O halo do título não muda neste PR.** O `HaloDoTitulo` atrás do nome da obra (30% no escuro e 10% no claro, Aurora.swift:192-195) segue no menor passo que passa de 4,5 no Pro Max, e o laudo inteiro confirma: nenhuma palavra das cenas da obra mudou. O 38% do mockup (62% na letra máxima) é o ponto de partida do título novo, em SF Mono 600, que só existe a partir do PR 1b (peça) e entra na tela no 1c; a calibração pelo laudo vai junto com ele, onde a cena existe. No claro, o "nenhum" do mockup não serve: sem halo, o nome da obra ficava em 4,40:1 no 17 Pro da CI (decisão de 10/10). Recomendação: na tabela do spec, a linha `HaloTitulo` passa a dizer "calibrado no PR que põe o título novo na tela (1c), a partir de 38%/62% no escuro e 10% no claro".
3. **Um teste de tela da `main` reprova nos últimos 3 dias de cada mês, inclusive hoje (29/10), em qualquer commit.** `FolhasDeOrigemUITests/testASetaDoIndicadorAbreAFolhaDoAPagar` (linhas 127-131) calcula o total do cabeçalho do mês do 2º vencimento só com o 2º e o 3º (`mes(daquiA: 24)` e `25`), mas o 1º vence em 3 dias (`g039`, VitrineDaObra.swift:46, R$ 4.800,00): de 29 a 31/10, os três caem em novembro e o cabeçalho mostra R$ 13.250,00. Um rerun não resolve: o dia é o mesmo. O conserto é o PR #93, só de teste, que entra antes do PR 0. Até ele entrar, de 29 a 31 de cada mês, o job `app-etapa3` reprova, e o merge espera o dia 1º.
4. **A régua do spec para o 1a (~50–150 de Swift) ficou grande:** o PR tem 29 linhas de Swift, porque o `DestaqueNumero`, a `LinhaBanco` e o `AmbarTexto` reaproveitam tokens do app e o globo e o halo não mudam. Pela régua do CONVENCOES (tudo em `app-ios/Custta/`), são 757, das quais 728 são o catálogo gerado. Nada a mudar no corte: o 1a continua sozinho porque é o PR que espera o OK do Giovani.
5. **O laudo é comparado só no Pro Max.** O spec ("Testes e validação", item 6) diz que o laudo inteiro roda nos dois aparelhos e que as tabelas são comparadas palavra por palavra com as do commit anterior. Este plano compara só no Pro Max (iOS 27), no Mac (ponto de controle, item 1). Na CI (iOS 26), o laudo é só portão, e o xcresult só sobe quando reprova (`app-ios.yml`, passo "Resultado do laudo quando reprova", `if: failure()`). Com a CI igual à de hoje no marco 1 (Decisões), recomendação: a diferença fica escrita aqui e na linha 6 do spec ("comparadas no Pro Max; na CI, o portão de 4,5"); no 4a, que já mexe na CI, o `laudo.xcresult` passa a subir sempre, e o iOS 26 também é comparado.

### Task 15: Comparador do laudo de leitura palavra por palavra

Os PRs 1a, 1b e 1c mudam peças compartilhadas, e o spec ("A comparação", na seção "PRs") pede o laudo inteiro de cada um comparado palavra por palavra com o do commit anterior. O comparador:
- exporta as tabelas do laudo (`*.txt`) dos dois xcresult com o `xcresulttool`, sempre do xcresult de agora: apaga antes a exportação que houver na pasta de saída, para uma rodada refeita nunca ler a da rodada anterior;
- casa as palavras de cada cena pela caixa (x, y, largura e altura), e para com erro numa cena de nome repetido, que tomaria o lugar da outra;
- conta, por cena, as palavras idênticas, as mudadas (a mesma caixa com a cor, a nota ou o pior diferente), as deslocadas (a mesma cor, o mesmo y, a mesma largura e a mesma altura, a até 6 pt na horizontal) e as sem par de cada lado;
- confere todas as palavras de depois contra o portão de 4,5, as sem par também.

Só as cenas com diferença aparecem, e o `--detalhe` lista cada palavra. Ele aceita também pastas já exportadas (com o `manifest.json`), e é assim que o teste o usa, porque o `test:unit` roda no Ubuntu da CI, sem o `xcrun`.

**Files:**
- Modify: `package.json`
- Create: `scripts/compara-laudo.mjs`
- Test (novo): `tests/compara-laudo.test.mjs`

**Interfaces:**
- Consumes: as tabelas do laudo de leitura, que o `LeituraNoVidroUITests` anexa como "leitura — <cena> (tabela)", com uma linha por palavra (`#RRGGBB  x, y  w× h pt  nota N  pior N`).
- Produces: `node scripts/compara-laudo.mjs <antes> <depois> <pasta de saída> [--detalhe]`, usado nas Tasks 17 e 18 e no fim de cada PR do app.

- [ ] **Step 1: Escrever os testes**

Os testes montam duas pastas como as que o `xcresulttool` exporta e conferem a saída inteira, com e sem `--detalhe`. Os casos cobertos: uma palavra idêntica, uma mudada que fica abaixo de 4,5, uma deslocada, uma só de antes, uma só de depois, uma cena que só existe de um lado e uma cena sem diferença, que não aparece na saída. O 3º teste prende a regra de cada classe numa cena só, no limite de cada uma: a nota e o pior contam como mudança, como a cor; a deslocada é a mesma cor, o mesmo y, a mesma largura e a mesma altura, a até 6 pt (a 7 pt, com outra cor, outro y ou outra largura, a palavra fica sem par); a sem par também passa pelo portão; 4,50 passa; a cena só com deslocadas também sai.

Criar `tests/compara-laudo.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');

// Uma pasta como a que o xcresulttool exporta: o manifest.json e uma tabela por cena.
function laudo(pasta, cenas) {
  mkdirSync(pasta, { recursive: true });
  const anexos = Object.entries(cenas).map(([cena, linhas], i) => {
    writeFileSync(join(pasta, `${i}.txt`), [`Leitura — ${cena} (portão 4.5:1)`, ...linhas].join('\n') + '\n');
    return { exportedFileName: `${i}.txt`, suggestedHumanReadableName: `leitura — ${cena} (tabela)` };
  });
  anexos.push({ exportedFileName: 'print.png', suggestedHumanReadableName: 'leitura — a, claro (print)' });
  writeFileSync(join(pasta, 'manifest.json'), JSON.stringify([{ attachments: anexos }]));
}

function compara(...extra) {
  const base = mkdtempSync(join(tmpdir(), 'compara-laudo-'));
  laudo(join(base, 'antes'), {
    'a, claro': [
      '#111111    10, 20    30× 12 pt  nota  7.00  pior  7.00',
      '#222222    50, 20    40× 12 pt  nota  5.00  pior  5.00',
      '#333333   100, 40    20× 10 pt  nota  8.00  pior  8.00',
      '#555555   300, 80    20× 10 pt  nota  6.00  pior  6.00',
    ],
    'c, escuro': ['#111111    10, 20    30× 12 pt  nota  7.00  pior  7.00'],
    'd, igual': ['#111111    10, 20    30× 12 pt  nota  7.00  pior  7.00'],
  });
  laudo(join(base, 'depois'), {
    'a, claro': [
      '#111111    10, 20    30× 12 pt  nota  7.00  pior  7.00',
      '#232323    50, 20    40× 12 pt  nota  4.40  pior  4.40',
      '#333333   104, 40    20× 10 pt  nota  8.00  pior  8.00',
      '#444444   200, 60    10× 10 pt  nota  9.00  pior  9.00',
    ],
    'b, claro': ['#111111    10, 20    30× 12 pt  nota  7.00  pior  7.00'],
    'd, igual': ['#111111    10, 20    30× 12 pt  nota  7.00  pior  7.00'],
  });
  return execFileSync('node', [join(raiz, 'scripts/compara-laudo.mjs'), join(base, 'antes'), join(base, 'depois'),
    join(base, 'saida'), ...extra], { encoding: 'utf8' });
}

test('por cena: idênticas, mudadas, deslocadas, sem par e abaixo do portão; cena sem diferença não sai', () => {
  assert.equal(compara(), [
    'a, claro: 4 palavras, 1 idênticas, 1 mudadas, 1 deslocadas, 1 só antes, 1 só depois, 1 abaixo de 4.5',
    'SÓ DEPOIS: b, claro',
    'SÓ ANTES: c, escuro',
    'TOTAL: 2 cenas, 5 palavras, 2 idênticas, 1 mudadas, 1 deslocadas, 2 sem par, 1 abaixo de 4.5',
    '',
  ].join('\n'));
});

test('o detalhe diz cada palavra que mudou, a que sobrou de cada lado e a que ficou abaixo de 4,5', () => {
  assert.equal(compara('--detalhe'), [
    'a, claro: 4 palavras, 1 idênticas, 1 mudadas, 1 deslocadas, 1 só antes, 1 só depois, 1 abaixo de 4.5',
    '   mudou 50,20 40×12: #222222 5.00 (pior 5.00) → #232323 4.40 (pior 4.40)',
    '   só antes  #555555 300,80 20×10 nota 6.00 pior 6.00',
    '   só depois #444444 200,60 10×10 nota 9.00 pior 9.00',
    '   ABAIXO #232323 50,20 40×12 nota 4.40',
    'SÓ DEPOIS: b, claro',
    'SÓ ANTES: c, escuro',
    'TOTAL: 2 cenas, 5 palavras, 2 idênticas, 1 mudadas, 1 deslocadas, 2 sem par, 1 abaixo de 4.5',
    '',
  ].join('\n'));
});

// Cada regra de classe numa cena só: nota e pior contam como mudança; a deslocada é a mesma cor, y, largura e
// altura a até 6 pt; a sem par também passa pelo portão; 4,50 passa; a cena só com deslocadas também sai.
test('a regra de cada classe, com o limite de cada uma', () => {
  const l = (cor, x, y, nota, pior = nota, w = 20) =>
    `${cor}  ${x}, ${y}  ${w}× 10 pt  nota ${nota.toFixed(2)}  pior ${pior.toFixed(2)}`;
  const base = mkdtempSync(join(tmpdir(), 'compara-laudo-'));
  laudo(join(base, 'antes'), {
    e: [l('#666666', 10, 100, 7), l('#666666', 60, 100, 7), l('#676767', 110, 100, 7), l('#777777', 100, 120, 8),
      l('#888888', 200, 140, 8), l('#999999', 300, 160, 8), l('#AAAAAA', 10, 200, 8), l('#BBBBBB', 10, 220, 4.5),
      l('#DDDDDD', 200, 260, 8)],
    f: [l('#111111', 10, 20, 7)],
  });
  laudo(join(base, 'depois'), {
    e: [l('#666666', 10, 100, 6.5), l('#666666', 60, 100, 7, 6.9), l('#686868', 110, 100, 7),
      l('#777777', 107, 120, 8), l('#898989', 202, 140, 8), l('#999999', 302, 161, 8), l('#AAAAAA', 16, 200, 7.5),
      l('#BBBBBB', 10, 220, 4.5), l('#CCCCCC', 10, 240, 4.4), l('#DDDDDD', 202, 260, 8, 8, 22)],
    f: [l('#111111', 12, 20, 7)],
  });
  const saida = execFileSync('node', [join(raiz, 'scripts/compara-laudo.mjs'), join(base, 'antes'),
    join(base, 'depois'), join(base, 'saida'), '--detalhe'], { encoding: 'utf8' });
  assert.equal(saida, [
    'e: 10 palavras, 1 idênticas, 3 mudadas, 1 deslocadas, 4 só antes, 5 só depois, 1 abaixo de 4.5',
    '   mudou 10,100 20×10: #666666 7.00 (pior 7.00) → #666666 6.50 (pior 6.50)',
    '   mudou 60,100 20×10: #666666 7.00 (pior 7.00) → #666666 7.00 (pior 6.90)',
    '   mudou 110,100 20×10: #676767 7.00 (pior 7.00) → #686868 7.00 (pior 7.00)',
    '   deslocada 10→16,200 20×10: #AAAAAA 8.00 (pior 8.00) → #AAAAAA 7.50 (pior 7.50)',
    '   só antes  #777777 100,120 20×10 nota 8.00 pior 8.00',
    '   só antes  #888888 200,140 20×10 nota 8.00 pior 8.00',
    '   só antes  #999999 300,160 20×10 nota 8.00 pior 8.00',
    '   só antes  #DDDDDD 200,260 20×10 nota 8.00 pior 8.00',
    '   só depois #777777 107,120 20×10 nota 8.00 pior 8.00',
    '   só depois #898989 202,140 20×10 nota 8.00 pior 8.00',
    '   só depois #999999 302,161 20×10 nota 8.00 pior 8.00',
    '   só depois #CCCCCC 10,240 20×10 nota 4.40 pior 4.40',
    '   só depois #DDDDDD 202,260 22×10 nota 8.00 pior 8.00',
    '   ABAIXO #CCCCCC 10,240 20×10 nota 4.40',
    'f: 1 palavras, 0 idênticas, 0 mudadas, 1 deslocadas, 0 só antes, 0 só depois, 0 abaixo de 4.5',
    'TOTAL: 2 cenas, 11 palavras, 1 idênticas, 3 mudadas, 2 deslocadas, 9 sem par, 1 abaixo de 4.5',
    '',
  ].join('\n'));
});
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node --test tests/compara-laudo.test.mjs 2>&1 | grep -E "^ℹ (pass|fail)|^  code: 'MODULE_NOT_FOUND'" | sort | uniq -c
```
Expected (os três testes caem porque o script ainda não existe):
```
   3   code: 'MODULE_NOT_FOUND',
   1 ℹ fail 3
   1 ℹ pass 0
```

- [ ] **Step 3: Implementar**

Implemente o script e ponha o teste novo no `test:unit` do `package.json`, que lista os testes um a um.

Em `package.json`:

```diff
--- a/package.json
+++ b/package.json
@@ -6,7 +6,7 @@
   "description": "Custta: aplicação estática sem build no deploy; npm mantém SDK local, testes, Capacitor e a função de cron do servidor.",
   "scripts": {
     "test": "npm run test:unit && npm run test:rules",
-    "test:unit": "node --test tests/calc.test.cjs tests/moeda.test.cjs tests/icons.test.cjs tests/logo-escrito.test.cjs tests/teclado.test.cjs tests/resumo.test.cjs tests/xss.test.cjs tests/headers.test.cjs tests/vercel.test.cjs tests/pwa.test.cjs tests/workflow.test.cjs tests/sync.test.cjs tests/fila.test.mjs tests/diagnostico.test.cjs tests/share.test.cjs tests/conta.test.mjs tests/fuso.test.cjs tests/dados.test.cjs tests/cadastro.test.cjs tests/sentry.test.cjs tests/nativo.test.cjs tests/ios.test.cjs tests/gestos.test.cjs tests/molas.test.mjs tests/vidro.test.cjs tests/build-www.test.mjs tests/capacitor.test.cjs tests/cloud-nativo.test.mjs tests/dialogos.test.cjs tests/push.test.cjs tests/push-cloud.test.mjs tests/enviar.test.cjs tests/cron.test.cjs tests/privacidade.test.cjs tests/screenshots.test.mjs tests/conta-demo.test.mjs tests/docs.test.mjs tests/google-cloud.test.mjs tests/apple-cloud.test.mjs tests/admin-deps.test.cjs tests/pacotes.test.cjs tests/sonda-banco.test.mjs tests/vetores.test.mjs tests/app-ios.test.cjs",
+    "test:unit": "node --test tests/calc.test.cjs tests/moeda.test.cjs tests/icons.test.cjs tests/logo-escrito.test.cjs tests/teclado.test.cjs tests/resumo.test.cjs tests/xss.test.cjs tests/headers.test.cjs tests/vercel.test.cjs tests/pwa.test.cjs tests/workflow.test.cjs tests/sync.test.cjs tests/fila.test.mjs tests/diagnostico.test.cjs tests/share.test.cjs tests/conta.test.mjs tests/fuso.test.cjs tests/dados.test.cjs tests/cadastro.test.cjs tests/sentry.test.cjs tests/nativo.test.cjs tests/ios.test.cjs tests/gestos.test.cjs tests/molas.test.mjs tests/vidro.test.cjs tests/build-www.test.mjs tests/capacitor.test.cjs tests/cloud-nativo.test.mjs tests/dialogos.test.cjs tests/push.test.cjs tests/push-cloud.test.mjs tests/enviar.test.cjs tests/cron.test.cjs tests/privacidade.test.cjs tests/screenshots.test.mjs tests/conta-demo.test.mjs tests/docs.test.mjs tests/google-cloud.test.mjs tests/apple-cloud.test.mjs tests/admin-deps.test.cjs tests/pacotes.test.cjs tests/sonda-banco.test.mjs tests/vetores.test.mjs tests/app-ios.test.cjs tests/compara-laudo.test.mjs",
     "test:rules": "firebase emulators:exec --only firestore \"node --test tests/rules.test.mjs\"",
     "rules:deploy": "firebase deploy --only firestore:rules",
     "vendor:firebase": "node scripts/vendor-firebase.mjs",
```

Criar `scripts/compara-laudo.mjs`:

```js
// Compara o laudo de leitura de dois commits, palavra por palavra (spec da etapa 4, "A comparação").
//
// uso: node scripts/compara-laudo.mjs <antes> <depois> <pasta de saída> [--detalhe]
//
// <antes> e <depois> são os xcresult do laudo (o script exporta só as tabelas, *.txt, para <saída>/antes e
// <saída>/depois) ou pastas já exportadas, com o manifest.json. As palavras de cada cena casam pela caixa
// (x, y, largura e altura). Por cena, o script conta as idênticas (cor, nota e pior iguais), as mudadas (a mesma
// caixa com cor ou nota diferente), as deslocadas (a mesma palavra, que andou até 6 pt na horizontal) e as sem
// par dos dois lados, e confere as palavras de depois contra o portão de 4,5. Só as cenas com diferença saem.
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const PORTAO = 4.5;
const LINHA = /^(#[0-9A-Fa-f]{6,8})\s+(-?\d+),\s*(-?\d+)\s+(\d+)×\s*(\d+) pt\s+nota\s+([\d.]+)\s+pior\s+([\d.]+)/;

function exportar(origem, destino) {
  let pasta = origem;
  if (origem.replace(/\/+$/, '').endsWith('.xcresult')) {
    pasta = destino;
    fs.rmSync(destino, { recursive: true, force: true });   // sempre do xcresult de agora, nunca de uma rodada velha
    fs.mkdirSync(destino, { recursive: true });
    execFileSync('xcrun', ['xcresulttool', 'export', 'attachments', '--path', origem, '--output-path', destino,
      '--filter', '*.txt'], { stdio: 'pipe' });
  }
  const manifesto = JSON.parse(fs.readFileSync(path.join(pasta, 'manifest.json'), 'utf8'));
  const cenas = new Map();
  for (const teste of manifesto) {
    for (const anexo of teste.attachments ?? []) {
      const m = /^leitura — (.*) \(tabela\)/.exec(anexo.suggestedHumanReadableName ?? '');
      if (!m) continue;
      if (cenas.has(m[1])) throw new Error(`cena repetida no laudo: ${m[1]}`);
      const palavras = [];
      for (const linha of fs.readFileSync(path.join(pasta, anexo.exportedFileName), 'utf8').split('\n')) {
        const p = LINHA.exec(linha.trim());
        if (p) palavras.push({ cor: p[1].toUpperCase(), x: +p[2], y: +p[3], w: +p[4], h: +p[5], nota: +p[6], pior: +p[7] });
      }
      cenas.set(m[1], palavras);
    }
  }
  return cenas;
}

const caixa = p => `${p.x},${p.y},${p.w},${p.h}`;
const igual = (a, b) => caixa(a) === caixa(b) && a.cor === b.cor && a.nota === b.nota && a.pior === b.pior;
const n2 = v => v.toFixed(2);

function main() {
  const [antesX, depoisX, saida] = process.argv.slice(2, 5);
  const detalhe = process.argv.includes('--detalhe');
  const antes = exportar(antesX, path.join(saida, 'antes'));
  const depois = exportar(depoisX, path.join(saida, 'depois'));
  const total = { cenas: 0, palavras: 0, iguais: 0, mudadas: 0, semPar: 0, deslocadas: 0, abaixo: 0 };
  for (const cena of [...new Set([...antes.keys(), ...depois.keys()])].sort()) {
    const a = antes.get(cena);
    const d = depois.get(cena);
    if (!a || !d) {
      console.log(`SÓ ${a ? 'ANTES' : 'DEPOIS'}: ${cena}`);
      continue;
    }
    const porCaixaA = new Map();
    for (const p of a) {
      if (!porCaixaA.has(caixa(p))) porCaixaA.set(caixa(p), []);
      porCaixaA.get(caixa(p)).push(p);
    }
    let iguais = 0;
    const mudadas = [];
    const semParD = [];
    for (const p of d) {
      const lista = porCaixaA.get(caixa(p));
      if (lista && lista.length) {
        const q = lista.shift();
        if (igual(q, p)) iguais += 1;
        else mudadas.push([q, p]);
      } else {
        semParD.push(p);
      }
    }
    const semParA = [...porCaixaA.values()].flat();
    // Segunda passada: a mesma palavra deslocada na horizontal (mesma cor, y, largura e altura; |Δx| ≤ 6 pt).
    const deslocadas = [];
    for (const p of [...semParD]) {
      const q = semParA.find(q => q.cor === p.cor && q.y === p.y && q.w === p.w && q.h === p.h && Math.abs(q.x - p.x) <= 6);
      if (q) {
        semParA.splice(semParA.indexOf(q), 1);
        semParD.splice(semParD.indexOf(p), 1);
        deslocadas.push([q, p]);
      }
    }
    const abaixo = d.filter(p => p.nota < PORTAO);
    total.cenas += 1;
    total.palavras += d.length;
    total.iguais += iguais;
    total.mudadas += mudadas.length;
    total.semPar += semParA.length + semParD.length;
    total.deslocadas += deslocadas.length;
    total.abaixo += abaixo.length;
    if (mudadas.length || semParA.length || semParD.length || abaixo.length || deslocadas.length) {
      console.log(`${cena}: ${d.length} palavras, ${iguais} idênticas, ${mudadas.length} mudadas, ${deslocadas.length} deslocadas, ` +
        `${semParA.length} só antes, ${semParD.length} só depois, ${abaixo.length} abaixo de ${PORTAO}`);
      if (detalhe) {
        for (const [q, p] of mudadas) {
          console.log(`   mudou ${q.x},${q.y} ${q.w}×${q.h}: ${q.cor} ${n2(q.nota)} (pior ${n2(q.pior)}) → ${p.cor} ${n2(p.nota)} (pior ${n2(p.pior)})`);
        }
        for (const [q, p] of deslocadas) {
          if (q.cor !== p.cor || q.nota !== p.nota || q.pior !== p.pior) {
            console.log(`   deslocada ${q.x}→${p.x},${p.y} ${p.w}×${p.h}: ${q.cor} ${n2(q.nota)} (pior ${n2(q.pior)}) → ${p.cor} ${n2(p.nota)} (pior ${n2(p.pior)})`);
          }
        }
        for (const p of semParA) console.log(`   só antes  ${p.cor} ${p.x},${p.y} ${p.w}×${p.h} nota ${n2(p.nota)} pior ${n2(p.pior)}`);
        for (const p of semParD) console.log(`   só depois ${p.cor} ${p.x},${p.y} ${p.w}×${p.h} nota ${n2(p.nota)} pior ${n2(p.pior)}`);
        for (const p of abaixo) console.log(`   ABAIXO ${p.cor} ${p.x},${p.y} ${p.w}×${p.h} nota ${n2(p.nota)}`);
      }
    }
  }
  console.log(`TOTAL: ${total.cenas} cenas, ${total.palavras} palavras, ${total.iguais} idênticas, ${total.mudadas} mudadas, ` +
    `${total.deslocadas} deslocadas, ${total.semPar} sem par, ${total.abaixo} abaixo de ${PORTAO}`);
}

main();
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node --test tests/compara-laudo.test.mjs 2>&1 | grep -E "^ℹ (pass|fail)"
npm run test:unit 2>&1 | grep -E "^ℹ (pass|fail)"
```
Expected: `ℹ pass 3` e `ℹ fail 0`; no `test:unit`, `ℹ pass 410` e `ℹ fail 0`.

- [ ] **Step 5: Commit**

```bash
git add package.json scripts/compara-laudo.mjs tests/compara-laudo.test.mjs
git commit -m "test: comparador do laudo de leitura palavra por palavra" -m "Os PRs 1a, 1b e 1c da etapa 4 mudam peças compartilhadas, e o spec pede o laudo inteiro de cada um comparado palavra por palavra com o do commit anterior. O scripts/compara-laudo.mjs exporta as tabelas dos dois xcresult, casa as palavras de cada cena pela caixa e diz as idênticas, as mudadas, as deslocadas, as sem par e as que ficaram abaixo de 4,5. Ele aceita também pastas já exportadas, que é o que o teste usa, porque o test:unit roda no Ubuntu da CI, sem o xcrun."
```

### Task 16: Tokens da identidade nova no catálogo de cores

O catálogo ganha os tokens da identidade nova que o app ainda não tinha, com os valores do mockup aprovado (spec, tabela "Tokens: do mockup para o app", coluna "No app" = "novo"): o bloco sólido verde (`DestaqueSolido`, #3AD17E nos dois temas) e o texto sobre ele (`TintaSobreDestaque`, #04100C); o texto verde sobre o vidro (`DestaqueTexto`, #3AD17E e, no claro, o #0E7A41 do site); o sólido âmbar do veredito (`SolidoAmbar`, #FFD98A e, no claro, #F2C15A, confirmação 1 de 29/10) e o texto sobre ele (`TintaSobreAmbar`, #2B1B00); as placas (`Placa`, #04100C a 58% e branco a 66%; `PlacaForte`, a 84% e 92%); as seis cores do anel e da barra (`Grafico1` a `Grafico6`) com o cinza de "Outros" (`GraficoOutros`); e as cores dos gráficos de mês e do anel (`BarraApagada`, `GradeGrafico`, `EixoGrafico`, `AnelApagado`, `AnelSeparador`). A transparência vai no próprio valor (`#RRGGBBAA`), como a `Folha`. Três tokens do mockup não viram token, pela regra do spec ("Tokens pelo valor": o do app fica quando tem o mesmo papel e valor igual ou mais forte): o `DestaqueNumero` é o `PositivoNoVidro` (#8CF0BC e #084A27 contra #8CF0B4 e #0A5530), a `LinhaBanco` é o `SecundarioTransparente` (#D6E8E0 e #2B463B contra #B8D4C7 e #2F4A3F) e o `AmbarTexto` é o `AlertaNoVidro`, cujo claro escurece na tarefa seguinte. O `HaloTitulo` não é cor do catálogo: é a opacidade do `Fundo` no `HaloDoTitulo` (Aurora.swift:185), que se calibra pelo laudo com o título novo (ver o PR). O `SecundarioForte` fica fora até o laudo da letra máxima pedir (spec). Nenhuma tela usa os tokens novos: as peças do PR 1b usam. Os dois pares de texto sobre sólido entram no `PARES_SOLIDOS`, que o `tests/app-ios.test.cjs` confere a 4,5:1 sem Xcode (9,78:1 no verde; 12,34 e 9,97:1 no âmbar, no escuro e no claro).

**Files:**
- Modify: `app-ios/Custta/Identidade/Paleta.swift`
- Modify: `scripts/cores-app-ios.mjs`
- Test (alterar): `app-ios/CusttaTests/CoresTests.swift`
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/AnelApagado.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/AnelSeparador.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/BarraApagada.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/DestaqueSolido.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/DestaqueTexto.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/EixoGrafico.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/GradeGrafico.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/Grafico1.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/Grafico2.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/Grafico3.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/Grafico4.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/Grafico5.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/Grafico6.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/GraficoOutros.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/Placa.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/PlacaForte.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/SolidoAmbar.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/TintaSobreAmbar.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/TintaSobreDestaque.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)

**Interfaces:**
- Consumes: `Token`, `Paleta.nome(_:_:)` e `Paleta.cor(_:)` (Paleta.swift); `CORES` e `PARES_SOLIDOS` (`scripts/cores-app-ios.mjs`).
- Produces: `Token.destaqueSolido`, `.tintaSobreDestaque`, `.destaqueTexto`, `.solidoAmbar`, `.tintaSobreAmbar`, `.placa`, `.placaForte`, `.grafico1` a `.grafico6`, `.graficoOutros`, `.barraApagada`, `.gradeGrafico`, `.eixoGrafico`, `.anelApagado` e `.anelSeparador`, lidos por `paleta.cor(_:)`.

- [ ] **Step 1: Escrever os testes**

O teste lê cada token novo do catálogo compilado, nos dois temas, e o compara com a tabela do spec; o `hex` passa a dizer a transparência (`#RRGGBBAA`) quando ela existe.

Em `app-ios/CusttaTests/CoresTests.swift`:

```diff
--- a/app-ios/CusttaTests/CoresTests.swift
+++ b/app-ios/CusttaTests/CoresTests.swift
@@ -25,13 +25,36 @@ struct CoresTests {
         }
     }
 
-    /// "#RRGGBB" da cor do catálogo no esquema dado.
+    /// "#RRGGBB" da cor do catálogo no esquema dado; com transparência, "#RRGGBBAA".
     private func hex(_ token: Token, _ estilo: UIUserInterfaceStyle) -> String {
         guard let cor = UIColor(named: Paleta.nome(token, .esmeralda), in: .main, compatibleWith: nil)?
             .resolvedColor(with: UITraitCollection(userInterfaceStyle: estilo)) else { return "" }
         var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
         cor.getRed(&r, green: &g, blue: &b, alpha: &a)
-        return String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
+        let rgb = String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
+        return a < 1 ? rgb + String(format: "%02X", Int((a * 255).rounded())) : rgb
+    }
+
+    /// A identidade nova da etapa 4, com os valores do mockup aprovado (spec 2026-10-29, "Tokens: do mockup para o app"),
+    /// nos dois temas: só os tokens que o app ainda não tinha. O DestaqueNumero do mockup é o PositivoNoVidro, a LinhaBanco é
+    /// o SecundarioTransparente e o AmbarTexto é o AlertaNoVidro.
+    @Test func tokensDaIdentidadeNova() {
+        let tabela: [(Token, escuro: String, claro: String)] = [
+            (.destaqueSolido, "#3AD17E", "#3AD17E"), (.tintaSobreDestaque, "#04100C", "#04100C"),
+            (.destaqueTexto, "#3AD17E", "#0E7A41"),
+            (.solidoAmbar, "#FFD98A", "#F2C15A"), (.tintaSobreAmbar, "#2B1B00", "#2B1B00"),   // o claro: confirmação 1 de 29/10
+            (.placa, "#04100C94", "#FFFFFFA8"), (.placaForte, "#04100CD6", "#FFFFFFEB"),        // 58% e 66%; 84% e 92%
+            (.grafico1, "#199E70", "#10976A"), (.grafico2, "#3987E5", "#2A78D6"), (.grafico3, "#D55181", "#D14F86"),
+            (.grafico4, "#9085E9", "#6250D6"), (.grafico5, "#D95926", "#DC5A1E"), (.grafico6, "#14A3C7", "#0C86A4"),
+            (.graficoOutros, "#8FA89C", "#5E7A6E"),
+            (.barraApagada, "#EAFFF666", "#142B2394"),                                          // 40% e 58%
+            (.gradeGrafico, "#EAFFF624", "#142B2324"), (.eixoGrafico, "#EAFFF64D", "#142B2352"), // 14%; 30% e 32%
+            (.anelApagado, "#123128", "#DCEAE3"), (.anelSeparador, "#04100C8C", "#FFFFFFBF"),   // 55% e 75%
+        ]
+        for (token, escuro, claro) in tabela {
+            #expect(hex(token, .dark) == escuro, "\(token) no escuro")
+            #expect(hex(token, .light) == claro, "\(token) no claro")
+        }
     }
 
     /// O âmbar de texto sobre o vidro do conteúdo (etapa 3, o --amber-v do mockup): no claro, #6F4705; no escuro, #FFD98A.
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E '^/.*error:' | sed 's/^.*CusttaTests\//CusttaTests\//' | head -3
```
Expected: o `CusttaTests` não compila:
```
CusttaTests/CoresTests.swift:43:15: error: type 'Token' has no member 'destaqueSolido'
CusttaTests/CoresTests.swift:43:56: error: type 'Token' has no member 'tintaSobreDestaque'
CusttaTests/CoresTests.swift:44:15: error: type 'Token' has no member 'destaqueTexto'
```

- [ ] **Step 3: Implementar**

Os tokens entram no fim da tabela, depois dos da etapa 2, com o comentário de onde vêm; os casos do `Token` seguem a mesma ordem. Os valores com transparência saem do percentual do mockup arredondado a 1/255 (58% → `94`, 66% → `A8`, 84% → `D6`, 92% → `EB`, 40% → `66`, 14% → `24`, 30% → `4D`, 32% → `52`, 55% → `8C`, 75% → `BF`).

Em `app-ios/Custta/Identidade/Paleta.swift`:

```diff
--- a/app-ios/Custta/Identidade/Paleta.swift
+++ b/app-ios/Custta/Identidade/Paleta.swift
@@ -90,6 +90,33 @@ enum Token: String, CaseIterable, Sendable {
     case aceso = "Aceso"
     /// O aro claro das barrinhas de vidro desenhadas na miniatura de cada opção do vidro (Ajustes › Aparência).
     case aroDaMiniatura = "AroDaMiniatura"
+    /// A identidade nova (etapa 4): o bloco sólido protagonista de cada tela, que não é vidro, e o texto sobre ele; o texto
+    /// verde sobre o vidro; o sólido âmbar do "Rende menos que o banco" e o texto sobre ele.
+    case destaqueSolido = "DestaqueSolido"
+    case tintaSobreDestaque = "TintaSobreDestaque"
+    case destaqueTexto = "DestaqueTexto"
+    case solidoAmbar = "SolidoAmbar"
+    case tintaSobreAmbar = "TintaSobreAmbar"
+    /// A placa, um tom chapado sem desfoque (não é vidro), atrás do anel e dos gráficos; a forte, atrás da barra empilhada
+    /// da obra. Com ela, as marcas ficam a 3:1 com a aurora atrás.
+    case placa = "Placa"
+    case placaForte = "PlacaForte"
+    /// As seis cores do anel e da barra empilhada, do maior tópico para o menor, e o cinza de "Outros".
+    case grafico1 = "Grafico1"
+    case grafico2 = "Grafico2"
+    case grafico3 = "Grafico3"
+    case grafico4 = "Grafico4"
+    case grafico5 = "Grafico5"
+    case grafico6 = "Grafico6"
+    case graficoOutros = "GraficoOutros"
+    /// Os gráficos de mês: os meses não escolhidos e a hachura das parcelas a vencer, a grade e os eixos.
+    case barraApagada = "BarraApagada"
+    case gradeGrafico = "GradeGrafico"
+    case eixoGrafico = "EixoGrafico"
+    /// O anel: o trilho e os pedaços apagados pelo toque (por cor, sem opacidade, para as emendas não virarem bolinhas), e
+    /// o aro na ponta de cada pedaço.
+    case anelApagado = "AnelApagado"
+    case anelSeparador = "AnelSeparador"
 }
 
 struct Paleta: Equatable, Sendable {
```

Em `scripts/cores-app-ios.mjs`:

```diff
--- a/scripts/cores-app-ios.mjs
+++ b/scripts/cores-app-ios.mjs
@@ -103,6 +103,30 @@ export const CORES = {
     // Ajustes › Aparência: o aro claro das barrinhas de vidro desenhadas na miniatura de cada opção (no mockup, branco a 70% no
     // Transparente e a 30% no Fosco, nos dois temas). O vidro de verdade tem o aro do sistema.
     AroDaMiniatura: ['#FFFFFF', '#FFFFFF'],
+    // Etapa 4 (~/Documents/custta-mockups/nativo/etapa4/, aprovado em 28/10; spec 2026-10-29, "Tokens: do mockup para o
+    // app"): a identidade nova, só o que o app não tinha. O DestaqueNumero do mockup é o PositivoNoVidro, a LinhaBanco é o
+    // SecundarioTransparente e o AmbarTexto é o AlertaNoVidro: o do app tem o mesmo papel e é igual ou mais forte.
+    DestaqueSolido: ['#3AD17E', '#3AD17E'],         // o bloco sólido protagonista de cada tela (não é vidro)
+    TintaSobreDestaque: ['#04100C', '#04100C'],     // o texto sobre ele
+    DestaqueTexto: ['#3AD17E', '#0E7A41'],          // texto verde sobre o vidro; no claro, o --green do site
+    SolidoAmbar: ['#FFD98A', '#F2C15A'],            // o veredito "Rende menos que o banco" (o claro: confirmação 1 de 29/10)
+    TintaSobreAmbar: ['#2B1B00', '#2B1B00'],
+    Placa: ['#04100C94', '#FFFFFFA8'],              // tom chapado, sem desfoque, atrás do anel e dos gráficos (58% e 66%)
+    PlacaForte: ['#04100CD6', '#FFFFFFEB'],         // atrás da barra empilhada da obra (84% e 92%)
+    // As seis cores do anel e da barra empilhada (verde-água, azul, magenta, violeta, laranja e ciano), validadas nos dois
+    // temas a 3:1 contra o vidro, e o cinza de "Outros", neutro de propósito.
+    Grafico1: ['#199E70', '#10976A'],
+    Grafico2: ['#3987E5', '#2A78D6'],
+    Grafico3: ['#D55181', '#D14F86'],
+    Grafico4: ['#9085E9', '#6250D6'],
+    Grafico5: ['#D95926', '#DC5A1E'],
+    Grafico6: ['#14A3C7', '#0C86A4'],
+    GraficoOutros: ['#8FA89C', '#5E7A6E'],
+    BarraApagada: ['#EAFFF666', '#142B2394'],       // os meses não escolhidos e a hachura das parcelas a vencer (40% e 58%)
+    GradeGrafico: ['#EAFFF624', '#142B2324'],       // 14%
+    EixoGrafico: ['#EAFFF64D', '#142B2352'],        // 30% e 32%
+    AnelApagado: ['#123128', '#DCEAE3'],            // o trilho e os pedaços apagados pelo toque: por cor, sem opacidade
+    AnelSeparador: ['#04100C8C', '#FFFFFFBF'],      // o aro de 2,5 pt na ponta de cada pedaço (55% e 75%)
   },
 };
 
@@ -117,6 +141,7 @@ export const PARES_SOLIDOS = [
   ['Texto', 'LinhaDaFolha'], ['SecundarioSolido', 'LinhaDaFolha'], ['SecundarioTransparente', 'LinhaDaFolha'], ['LinkNoVidro', 'LinhaDaFolha'], ['ErroNoVidro', 'LinhaDaFolha'],
   ['Negativo', 'LinhaDaFolha'], ['Alerta', 'LinhaDaFolha'], ['Texto', 'Tecla'], ['Texto', 'TeclaTocada'], ['Texto', 'SegmentadoEscolhido'],
   ['SobreApagar', 'Apagar'], ['SobreAlerta', 'Alerta'],
+  ['TintaSobreDestaque', 'DestaqueSolido'], ['TintaSobreAmbar', 'SolidoAmbar'],
 ];
 
 const info = { author: 'xcode', version: 1 };
```

Regerar:

```bash
node scripts/cores-app-ios.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | tail -8 | grep -E "ℹ (pass|fail)"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/CoresTests 2>&1 | grep -E "Test run with"
```
Expected: `ℹ pass 68`, `ℹ fail 0`; `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 5 tests in 1 suite passed`.

- [ ] **Step 5: Conferir que nenhuma tela usa os tokens novos**

O git do Mac (Apple Git 2.54) não entende o `\b` no `-E`, e a busca com ele dá 0 sempre: o fim do nome vai como `([^A-Za-z0-9_]|$)`. A segunda linha é o controle, com o mesmo padrão sobre um token que tem uso.

Run:
```bash
git grep -nE '\.(destaqueSolido|tintaSobreDestaque|destaqueTexto|solidoAmbar|tintaSobreAmbar|placa|placaForte|grafico[1-6]|graficoOutros|barraApagada|gradeGrafico|eixoGrafico|anelApagado|anelSeparador)([^A-Za-z0-9_]|$)' -- app-ios/Custta | wc -l
git grep -nE '\.(alertaNoVidro)([^A-Za-z0-9_]|$)' -- app-ios/Custta | wc -l
```
Expected: `0` e `2` (os dois leitores do `AlertaNoVidro`, PecasDoOrcamento.swift:149 e PecasDaTelaOrcamento.swift:242). Sem uso, as telas das etapas 1 a 3 não mudam; o laudo inteiro do fim do PR confirma.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Assets.xcassets/Esmeralda/AnelApagado.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/AnelSeparador.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/BarraApagada.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/DestaqueSolido.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/DestaqueTexto.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/EixoGrafico.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/GradeGrafico.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/Grafico1.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/Grafico2.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/Grafico3.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/Grafico4.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/Grafico5.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/Grafico6.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/GraficoOutros.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/Placa.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/PlacaForte.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/SolidoAmbar.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/TintaSobreAmbar.colorset/Contents.json app-ios/Custta/Assets.xcassets/Esmeralda/TintaSobreDestaque.colorset/Contents.json app-ios/Custta/Identidade/Paleta.swift app-ios/CusttaTests/CoresTests.swift scripts/cores-app-ios.mjs
git commit -m "feat: tokens da identidade nova da etapa 4 no catálogo de cores" -m "O catálogo ganha os tokens da identidade nova que o app ainda não tinha, com os valores do mockup aprovado da etapa 4: o bloco sólido verde e o texto sobre ele, o texto verde sobre o vidro, o sólido âmbar do veredito (no claro, #F2C15A com o texto #2B1B00, confirmado pelo Giovani em 29/10), as placas atrás dos gráficos e da barra empilhada, as seis cores do anel com o cinza de \"Outros\" e as cores das barras, da grade, dos eixos e do anel." -m "O DestaqueNumero, a LinhaBanco e o AmbarTexto do mockup não viram token: o app já tem o PositivoNoVidro, o SecundarioTransparente e o AlertaNoVidro, com o mesmo papel e valor igual ou mais forte. Nenhuma tela usa os tokens novos por enquanto; as peças do PR seguinte usam. Os dois pares de texto sobre sólido entram no PARES_SOLIDOS, que confere 4,5:1 sem Xcode."
```

### Task 17: Âmbar de texto do claro mais escuro no app inteiro

No claro, o `AlertaNoVidro` passa de #6F4705 a #5E3A03, o `AmbarTexto` do mockup da etapa 4: o texto mais escuro do claro, aprovado pelo Giovani em 28/10 (no mockup, o #6F4705 ficava em 3,9:1 no pior ponto da aurora clara), que a confirmação 5 de 29/10 leva ao app inteiro (spec, "Tokens globais: os valores aprovados"). O escuro (#FFD98A) não muda. O token tem dois leitores, os dois da etapa 3: o aviso dos tópicos na linha do orçamento da obra (`AvisoDoOrcamento`, PecasDoOrcamento.swift:149) e o "Passou … do previsto" da tela Orçamento (`FraseDoTopicoNoOrcamento`, PecasDaTelaOrcamento.swift:242). O outro texto que o mockup escureceu, o `SecundarioTransparente` (#3B574B → #2F4A3F), não muda no app: o do app já é #2B463B, mais escuro (spec, tabela de tokens). Uma guarda nova prende a regra do spec "Tokens pelo valor" para os três tokens do mockup que o app já tem: o do app só fica no lugar se tiver contraste igual ou maior contra o vidro de referência do mockup (#10241D no escuro, #DDF3EA no claro, o do validador de paleta do Croqui); com o #6F4705, o `AlertaNoVidro` do claro fica em 7,01:1 contra 8,68:1 do #5E3A03 e reprova.

**Files:**
- Modify: `scripts/cores-app-ios.mjs`
- Test (alterar): `app-ios/CusttaTests/CoresTests.swift`
- Test (alterar): `app-ios/CusttaTests/OrcamentoTests.swift`
- Test (alterar): `app-ios/CusttaTests/TelaOrcamentoTests.swift`
- Test (alterar): `tests/app-ios.test.cjs`
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/AlertaNoVidro.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)

**Interfaces:**
- Consumes: `Token.alertaNoVidro`; `CORES` (`scripts/cores-app-ios.mjs`).
- Produces: nada novo (o valor do `AlertaNoVidro` no claro).

- [ ] **Step 1: Escrever os testes**

O `CoresTests` e a guarda do catálogo pedem o claro novo; a guarda nova compara, contra o vidro de referência, o token do app com o do mockup que ele substitui. Os dois testes do âmbar sobre o vidro do orçamento (`OrcamentoTests` e `TelaOrcamentoTests`, da etapa 3) passam a esperar o #5E3A03 no claro.

Em `app-ios/CusttaTests/CoresTests.swift`:

```diff
--- a/app-ios/CusttaTests/CoresTests.swift
+++ b/app-ios/CusttaTests/CoresTests.swift
@@ -57,10 +57,11 @@ struct CoresTests {
         }
     }
 
-    /// O âmbar de texto sobre o vidro do conteúdo (etapa 3, o --amber-v do mockup): no claro, #6F4705; no escuro, #FFD98A.
+    /// O âmbar de texto sobre o vidro do conteúdo (etapa 3, o --amber-v do mockup): no claro, #5E3A03, o texto mais escuro do
+    /// claro da etapa 4 (era #6F4705); no escuro, #FFD98A.
     /// E a decisão 6: no Fosco escuro, o secundário é o do Transparente; no claro, o do Fosco fica.
     @Test func ambarSobreOVidroESecundarioDoFoscoNoEscuro() {
-        #expect(hex(.alertaNoVidro, .light) == "#6F4705")
+        #expect(hex(.alertaNoVidro, .light) == "#5E3A03")
         #expect(hex(.alertaNoVidro, .dark) == "#FFD98A")
         #expect(hex(.secundarioFosco, .dark) == hex(.secundarioTransparente, .dark))
         #expect(hex(.secundarioFosco, .light) != hex(.secundarioTransparente, .light))
```

Em `app-ios/CusttaTests/OrcamentoTests.swift`:

```diff
--- a/app-ios/CusttaTests/OrcamentoTests.swift
+++ b/app-ios/CusttaTests/OrcamentoTests.swift
@@ -109,10 +109,10 @@ struct OrcamentoTests {
         return Dictionary(grouping: opacos, by: { $0 }).max { $0.value.count < $1.value.count }?.key ?? []
     }
 
-    /// O aviso dos tópicos no âmbar sobre o vidro: #6F4705 no claro (o Alerta do site, #8A5A06, não fechava 4,5:1 sobre a
+    /// O aviso dos tópicos no âmbar sobre o vidro: #5E3A03 no claro (o Alerta do site, #8A5A06, não fechava 4,5:1 sobre a
     /// aurora clara) e #FFD98A no escuro.
     @Test func avisoDosTopicosNoAmbarSobreOVidro() throws {
-        #expect(try corDoTexto(.light) == [0x6F, 0x47, 0x05])
+        #expect(try corDoTexto(.light) == [0x5E, 0x3A, 0x03])
         #expect(try corDoTexto(.dark) == [0xFF, 0xD9, 0x8A])
     }
 }
```

Em `app-ios/CusttaTests/TelaOrcamentoTests.swift`:

```diff
--- a/app-ios/CusttaTests/TelaOrcamentoTests.swift
+++ b/app-ios/CusttaTests/TelaOrcamentoTests.swift
@@ -95,7 +95,7 @@ struct TelaOrcamentoTests {
         #expect(altura(60, .accessibility5) > altura(1000, .accessibility5), "na letra grande, quebra")
     }
 
-    /// A frase do "passou" no âmbar sobre o vidro (#6F4705 no claro, #FFD98A no escuro); as outras, fora do âmbar.
+    /// A frase do "passou" no âmbar sobre o vidro (#5E3A03 no claro, #FFD98A no escuro); as outras, fora do âmbar.
     @MainActor @Test func fraseDoPassouNoAmbarSobreOVidro() throws {
         func cor(_ alerta: Bool, _ esquema: ColorScheme) throws -> [UInt8] {
             let r = ImageRenderer(content: FraseDoTopicoNoOrcamento(texto: "Passou R$ 6,2 mil do previsto", alerta: alerta)
@@ -112,8 +112,8 @@ struct TelaOrcamentoTests {
             let opacos = stride(from: 0, to: rgba.count, by: 4).filter { rgba[$0 + 3] == 255 }.map { Array(rgba[$0..<$0 + 3]) }
             return Dictionary(grouping: opacos, by: { $0 }).max { $0.value.count < $1.value.count }?.key ?? []
         }
-        #expect(try cor(true, .light) == [0x6F, 0x47, 0x05])
+        #expect(try cor(true, .light) == [0x5E, 0x3A, 0x03])
         #expect(try cor(true, .dark) == [0xFF, 0xD9, 0x8A])
-        #expect(try cor(false, .light) != [0x6F, 0x47, 0x05] && cor(false, .dark) != [0xFF, 0xD9, 0x8A], "a frase que não é do passou")
+        #expect(try cor(false, .light) != [0x5E, 0x3A, 0x03] && cor(false, .dark) != [0xFF, 0xD9, 0x8A], "a frase que não é do passou")
     }
 }
```

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -156,10 +156,10 @@ test('catálogo de cores em dia com scripts/cores-app-ios.mjs e com os tokens da
     // topo no Pro Max (faixa que o laudo deixa de fora, porque ali o texto é borrado); no escuro, o próprio Alerta.
     const alerta = bloco.match(/\bAlerta: \['(#\w+)', '#\w+'\]/)[1];
     assert.match(bloco, new RegExp(`\\bAlertaEtiqueta: \\['${alerta}', '#7A5410'\\]`), `AlertaEtiqueta da pele ${pele}`);
-    // O texto âmbar sobre o vidro do conteúdo (etapa 3, o --amber-v do mockup): no claro, #6F4705 (o Alerta do site dava
-    // 3,79–4,15:1 sobre a aurora clara); no escuro, #FFD98A (o Alerta ficava em 3,12:1 no alto da tela Orçamento rolada, na
-    // maior letra).
-    assert.match(bloco, /\bAlertaNoVidro: \['#FFD98A', '#6F4705'\]/, `AlertaNoVidro da pele ${pele}`);
+    // O texto âmbar sobre o vidro do conteúdo (etapa 3, o --amber-v do mockup): no claro, #5E3A03, o AmbarTexto do mockup da
+    // etapa 4 (o texto mais escuro do claro, aprovado em 28/10; o #6F4705 da etapa 3 ficava em 3,9:1 no pior ponto da aurora
+    // clara do mockup); no escuro, #FFD98A (o Alerta ficava em 3,12:1 no alto da tela Orçamento rolada, na maior letra).
+    assert.match(bloco, /\bAlertaNoVidro: \['#FFD98A', '#5E3A03'\]/, `AlertaNoVidro da pele ${pele}`);
     // Decisão 6 da etapa 3: no Fosco escuro, o texto secundário é o do Transparente (o do Fosco ficava abaixo de 4,5:1 em
     // dois pontos claros da aurora); no claro, o do Fosco fica.
     const secundario = nome => bloco.match(new RegExp(`\\b${nome}: \\['(#\\w+)', '(#\\w+)'\\]`)).slice(1);
@@ -224,6 +224,26 @@ test('texto sobre sólido fecha 4,5:1 nos quatro combos', async () => {
   }
 });
 
+test('token do mockup da etapa 4 que o app já tem: o do app é igual ou mais forte', async () => {
+  // Spec 2026-10-29, "Tokens: do mockup para o app": onde o app já tem um token com o mesmo papel, ele fica no lugar do do
+  // mockup se o valor for igual ou mais forte (o do mockup não clareia o texto que o app já escureceu). Mais forte é mais
+  // contraste contra o vidro de referência do mockup (#10241D no escuro, #DDF3EA no claro). O AmbarTexto do claro ficou
+  // mais escuro em 28/10 (#6F4705 → #5E3A03) e vale no app inteiro (confirmação 5 de 29/10).
+  const { CORES } = await import(join(RAIZ, 'scripts/cores-app-ios.mjs'));
+  const linear = c => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
+  const luminancia = hex => [0.2126, 0.7152, 0.0722].reduce((s, peso, i) => s + peso * linear(parseInt(hex.slice(1 + 2 * i, 3 + 2 * i), 16) / 255), 0);
+  const razao = (a, b) => { const [x, y] = [luminancia(a), luminancia(b)].sort((m, n) => n - m); return (x + 0.05) / (y + 0.05); };
+  const vidro = ['#10241D', '#DDF3EA'];
+  const doMockup = [['DestaqueNumero', 'PositivoNoVidro', '#8CF0B4', '#0A5530'], ['LinhaBanco', 'SecundarioTransparente', '#B8D4C7', '#2F4A3F'],
+    ['AmbarTexto', 'AlertaNoVidro', '#FFD98A', '#5E3A03']];
+  for(const [nome, token, ...valores] of doMockup){
+    for(const [lado, tema] of [[0, 'escuro'], [1, 'claro']]){
+      const app = CORES.Esmeralda[token][lado];
+      assert.ok(razao(app, vidro[lado]) >= razao(valores[lado], vidro[lado]), `${token} no ${tema}: ${app} mais fraco que o ${valores[lado]} do ${nome}`);
+    }
+  }
+});
+
 test('ícones em dia com o icons.js do site', async () => {
   execFileSync(process.execPath, ['scripts/icones-app-ios.mjs', '--conferir'], { cwd: RAIZ, stdio: 'pipe' });
   // O quadro do SVG (viewBox, linha e pontas) e o traço de cada ícone iguais aos do ICON() do site.
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | grep -E "AssertionError \[|ℹ fail"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/CoresTests -only-testing:CusttaTests/OrcamentoTests -only-testing:CusttaTests/TelaOrcamentoTests 2>&1 | grep -E "Expectation failed|Test run with"
```
Expected: duas reprovações no Node (`ℹ fail 2`):
```
  AssertionError [ERR_ASSERTION]: AlertaNoVidro da pele Esmeralda
  AssertionError [ERR_ASSERTION]: AlertaNoVidro no claro: #6F4705 mais fraco que o #5E3A03 do AmbarTexto
```
e, compilado, as três suítes reprovam pelo âmbar:
```
✘ Test ambarSobreOVidroESecundarioDoFoscoNoEscuro() recorded an issue at CoresTests.swift:64:9: Expectation failed: hex(.alertaNoVidro, .light) == "#5E3A03"
✘ Test avisoDosTopicosNoAmbarSobreOVidro() recorded an issue at OrcamentoTests.swift:115:9: Expectation failed: try corDoTexto(.light) == [0x5E, 0x3A, 0x03]
✘ Test fraseDoPassouNoAmbarSobreOVidro() recorded an issue at TelaOrcamentoTests.swift:115:9: Expectation failed: try cor(true, .light) == [0x5E, 0x3A, 0x03]
✘ Test run with 18 tests in 3 suites failed after 0.215 seconds with 3 issues.
```

- [ ] **Step 3: Implementar**

Só o valor do claro e o comentário; o catálogo sai do script.

Em `scripts/cores-app-ios.mjs`:

```diff
--- a/scripts/cores-app-ios.mjs
+++ b/scripts/cores-app-ios.mjs
@@ -81,11 +81,12 @@ export const CORES = {
     PositivoNoVidro: ['#8CF0BC', '#084A27'],
     NegativoNoVidro: ['#FFD2D9', '#8A1538'],
     // O texto âmbar sobre o vidro do conteúdo (etapa 3, o --amber-v do mockup: o aviso dos tópicos na linha do orçamento e o
-    // "Passou … do previsto"): no claro, #6F4705 (o Alerta do site dava 3,79–4,15:1 sobre a aurora clara; este, 5,21–5,71:1).
-    // No escuro, um âmbar claro: o Alerta do site (#E0A83A) ficava em 3,12:1 (pior pixel 2,98) no alto da tela Orçamento
+    // "Passou … do previsto"): no claro, #5E3A03, o AmbarTexto do mockup da etapa 4 (o texto mais escuro do claro, aprovado em
+    // 28/10 e no app inteiro pela confirmação 5 de 29/10: o #6F4705 da etapa 3 ficava em 3,9:1 no pior ponto da aurora clara
+    // do mockup; o Alerta do site dava 3,79–4,15:1 sobre a do app). No escuro, um âmbar claro: o Alerta do site (#E0A83A) ficava em 3,12:1 (pior pixel 2,98) no alto da tela Orçamento
     // rolada, na maior letra, onde a aurora clareia o vidro (laudo da etapa 3); este, 4,9 ali. Não é o AlertaEtiqueta, que vai
     // sobre o fundo âmbar das etiquetas.
-    AlertaNoVidro: ['#FFD98A', '#6F4705'],
+    AlertaNoVidro: ['#FFD98A', '#5E3A03'],
     // Etapa 2 (~/Documents/custta-mockups/nativo/etapa2/parte2.html e parte3.html, aprovados em 13/10): a folha do
     // sistema e o que vai dentro dela, o arrastar para apagar e a linha que acabou de entrar.
     Folha: ['#0A1E18E6', '#F4F9F6F0'],              // --folha: fundo da folha (presentationBackground)
```

Regerar:

```bash
node scripts/cores-app-ios.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | tail -8 | grep -E "ℹ (pass|fail)"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/CoresTests -only-testing:CusttaTests/OrcamentoTests -only-testing:CusttaTests/TelaOrcamentoTests 2>&1 | grep -E "Test run with"
```
Expected: `ℹ pass 69`, `ℹ fail 0`; `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 18 tests in 3 suites passed`.

- [ ] **Step 5: Comparar o laudo das telas do orçamento com o do commit anterior**

O âmbar mudado aparece em duas telas da etapa 3, e o laudo delas, palavra por palavra, prova que só ele mudou e que subiu. Rode a mesma suíte com o produto do commit anterior e com o desta tarefa, no mesmo simulador, e compare as tabelas com o comparador (`node scripts/compara-laudo.mjs`, Tarefa 15: casa as palavras de cada cena pela caixa e lista as mudadas, as deslocadas e as sem par). Os resultados ficam numa pasta sua, fora do repositório, e não no `/tmp`, que é o mesmo dos outros agentes do Mac. Cada rodada começa apagando o resultado dela, porque o `xcodebuild` recusa um `-resultBundlePath` que já existe; o caminho vai por extenso, porque no zsh um glob sem casamento aborta o comando.

Run:
```bash
P=<uma pasta sua, fora do repositório>
LEITURA=-only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDoOrcamento
# no commit anterior (git stash ou checkout dele, build-for-testing) e depois neste, cada um no seu resultado:
rm -rf "$P/orc-antes.xcresult"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never "$LEITURA" -resultBundlePath "$P/orc-antes.xcresult" 2>&1 | grep -E "Executed [0-9]+ test" | tail -1
rm -rf "$P/orc-depois.xcresult"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never "$LEITURA" -resultBundlePath "$P/orc-depois.xcresult" 2>&1 | grep -E "Executed [0-9]+ test" | tail -1
node scripts/compara-laudo.mjs "$P/orc-antes.xcresult" "$P/orc-depois.xcresult" "$P/orc-cmp" --detalhe | tail -6
```
Expected (18 Pro, iOS 27): as duas rodadas com `Executed 1 test, with 0 failures`, e só as três palavras âmbar do claro mudam, todas para cima:
```
obra com orçamento por tópico, claro: 32 palavras, 31 idênticas, 1 mudadas, 0 deslocadas, 0 só antes, 0 só depois, 0 abaixo de 4.5
   mudou 61,496 222×14: #6F4705 6.96 (pior 6.85) → #5E3A03 8.62 (pior 8.48)
tela Orçamento, topo, claro: 26 palavras, 24 idênticas, 2 mudadas, 0 deslocadas, 0 só antes, 0 só depois, 0 abaixo de 4.5
   mudou 88,495 184×13: #6F4705 6.91 (pior 6.77) → #5E3A03 8.56 (pior 8.39)
   mudou 88,571 185×13: #6F4705 7.66 (pior 7.63) → #5E3A03 9.49 (pior 9.45)
TOTAL: 12 cenas, 314 palavras, 311 idênticas, 3 mudadas, 0 deslocadas, 0 sem par, 0 abaixo de 4.5
```
As outras cenas (as do escuro, a tela Orçamento rolada e a folha das teclas) ficam idênticas. No Pro Max, o laudo inteiro do fim do PR repete a conta em todas as cenas.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Assets.xcassets/Esmeralda/AlertaNoVidro.colorset/Contents.json app-ios/CusttaTests/CoresTests.swift app-ios/CusttaTests/OrcamentoTests.swift app-ios/CusttaTests/TelaOrcamentoTests.swift scripts/cores-app-ios.mjs tests/app-ios.test.cjs
git commit -m "feat: âmbar de texto do claro mais escuro no app inteiro" -m "No claro, o AlertaNoVidro passa de #6F4705 a #5E3A03, o AmbarTexto do mockup da etapa 4: o texto mais escuro do claro, aprovado pelo Giovani em 28/10, que a confirmação 5 de 29/10 leva ao app inteiro. Muda o aviso dos tópicos na linha do orçamento da obra e o \"Passou … do previsto\" da tela Orçamento, que ganham contraste; o escuro não muda." -m "Uma guarda nova prende a regra do spec para os tokens do mockup que o app já tem (DestaqueNumero, LinhaBanco e AmbarTexto): o do app só fica no lugar se for igual ou mais forte contra o vidro de referência do mockup."
```

### Task 18: Cápsula de abas na borda de 16 pt em todas as telas

A cápsula de abas e o + passam a ficar a 16 pt das bordas da tela, e não mais a 20 (CapsulaDeAbas.swift:55): é a borda externa de toda forma na grade 16/34 da identidade nova (spec, "Identidade", grade de bordas; ajuste 3 do mockup). O Giovani aprovou em 29/10 levar a cápsula ao app inteiro (confirmação 5): com 16 só nas telas novas, ela pularia de lugar ao trocar de aba (16 nas telas novas, 20 nas outras). A cápsula fica 8 pt mais larga, as duas abas ganham 4 pt cada e o + anda 4 pt para a direita; a altura (62), a margem de 4 pt das abas dentro da cápsula, o vão de 10 até o + e os 22 pt da borda de baixo não mudam. Em Ajustes, sem o +, a cápsula ocupa a largura toda menos 16 de cada lado. Como a cápsula é um `safeAreaBar` do `PrincipalView` (PrincipalView.swift:29), a mudança vale em toda tela de Obras e de Ajustes, inclusive a obra e as telas empurradas.

**Files:**
- Modify: `app-ios/Custta/Identidade/CapsulaDeAbas.swift`
- Test (alterar): `app-ios/CusttaUITests/AjustesUITests.swift`

**Interfaces:**
- Consumes: `CapsulaDeAbas` (o `safeAreaBar` do `PrincipalView`); os identificadores `aba-obras`, `aba-ajustes` e `botaoMais`.
- Produces: nada novo (a borda de 16 pt da cápsula).

- [ ] **Step 1: Escrever os testes**

O teste de tela mede a cápsula pelos quadros das abas e do +, como o `testCapsulaFica22PontosAcimaDaBorda` mede a de baixo: em Obras, a aba da esquerda a 16 + 4 pt da borda e o + a 16 pt da direita; em Ajustes, a aba da direita a 16 + 4 pt.

Em `app-ios/CusttaUITests/AjustesUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/AjustesUITests.swift
+++ b/app-ios/CusttaUITests/AjustesUITests.swift
@@ -79,6 +79,23 @@ final class AjustesUITests: XCTestCase {
         XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
         XCTAssertEqual(app.buttons["aba-ajustes"].frame.maxY + 4, base - 22, accuracy: 1)
     }
+
+    /// A cápsula na borda externa de 16 pt dos dois lados, a da grade 16/34 da etapa 4 (ajuste 3), no app inteiro
+    /// (confirmação 5 de 29/10): em Obras, a cápsula à esquerda e o + à direita; em Ajustes, sem o +, a cápsula na largura
+    /// toda. As abas ficam a 4 pt da borda da cápsula.
+    @MainActor func testCapsulaNaBordaDe16Pontos() {
+        let app = abrirApp(conta: "senha")
+        let obras = app.buttons["aba-obras"], mais = app.buttons["botaoMais"]
+        XCTAssertTrue(obras.waitForExistence(timeout: 10))
+        let largura = app.windows.firstMatch.frame.width
+        XCTAssertEqual(obras.frame.minX - 4, 16, accuracy: 0.5)
+        XCTAssertEqual(mais.frame.maxX, largura - 16, accuracy: 0.5)
+        app.abrirAba("ajustes")
+        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
+        XCTAssertTrue(mais.waitForNonExistence(timeout: 3), "em Ajustes não há o +")
+        XCTAssertEqual(obras.frame.minX - 4, 16, accuracy: 0.5)
+        XCTAssertEqual(app.buttons["aba-ajustes"].frame.maxX + 4, largura - 16, accuracy: 0.5)
+    }
     /// Ajustes › Aparência (a escolha do vidro, adiantada da etapa 5 para o TestFlight): tocar Fosco grava a escolha deste
     /// aparelho e o app passa ao Fosco na hora; a escolha fica ao reabrir; o Transparente volta do mesmo jeito. A prova é
     /// relativa, pelo print do painel da Conta, logo abaixo (o mesmo conteúdo e o mesmo lugar nas duas doses; só o vidro
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/AjustesUITests/testCapsulaNaBordaDe16Pontos 2>&1 | grep -E "error:|Executed"
```
Expected: compila (`** TEST BUILD SUCCEEDED **`), e o teste novo reprova na primeira medida, com a cápsula a 20 pt:
```
AjustesUITests.swift:91: error: -[CusttaUITests.AjustesUITests testCapsulaNaBordaDe16Pontos] : XCTAssertEqualWithAccuracy failed: ("20.0") is not equal to ("16.0") +/- ("0.5")
	 Executed 1 test, with 1 failure (0 unexpected) in 5.920 (5.923) seconds
```

- [ ] **Step 3: Implementar**

Só a borda: o resto da cápsula fica como está.

Em `app-ios/Custta/Identidade/CapsulaDeAbas.swift`:

```diff
--- a/app-ios/Custta/Identidade/CapsulaDeAbas.swift
+++ b/app-ios/Custta/Identidade/CapsulaDeAbas.swift
@@ -52,7 +52,7 @@ struct CapsulaDeAbas: View {
             }
         }
         .dynamicTypeSize(.large)
-        .padding(.horizontal, 20)
+        .padding(.horizontal, 16)           // a borda externa de toda forma (grade 16/34 da etapa 4), em todas as telas
         .padding(.bottom, 22)               // da borda da tela (mockup aprovado), como a barra de abas do sistema
         .animation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.35, bounce: 0), value: mais != nil)
     }
```

- [ ] **Step 4: Ver passar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/AjustesUITests 2>&1 | grep -E "error:|Executed"
```
Expected: `** TEST BUILD SUCCEEDED **`, sem aviso; `Executed 11 tests, with 0 failures (0 unexpected)` (o teste novo e os 10 de Ajustes, inclusive o `testCapsulaFica22PontosAcimaDaBorda`, que segue com os 22 pt de baixo).

- [ ] **Step 5: Comparar o laudo dos rótulos da cápsula com o do commit anterior**

A cápsula só é medida nas 16 cenas "abas sobre a lista" (escopo `navegacao`), que o `testLeituraNosDoisTemas` roda junto com as 4 de entrar e de Obras; nas outras, a faixa da cápsula fica fora do laudo. Rode essa suíte com o produto do commit anterior e com o desta tarefa, no mesmo simulador, e compare as tabelas com o comparador do PR. Os resultados vão para a mesma pasta sua da Tarefa 17, fora do repositório, e cada rodada começa apagando o resultado dela.

Run:
```bash
P=<uma pasta sua, fora do repositório>
LEITURA=-only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraNosDoisTemas
# no commit anterior (git stash ou checkout dele, build-for-testing) e depois neste, cada um no seu resultado:
rm -rf "$P/abas-antes.xcresult"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never "$LEITURA" -resultBundlePath "$P/abas-antes.xcresult" 2>&1 | grep -E "Executed [0-9]+ test" | tail -1
rm -rf "$P/abas-depois.xcresult"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never "$LEITURA" -resultBundlePath "$P/abas-depois.xcresult" 2>&1 | grep -E "Executed [0-9]+ test" | tail -1
node scripts/compara-laudo.mjs "$P/abas-antes.xcresult" "$P/abas-depois.xcresult" "$P/abas-cmp" --detalhe | grep -B1 "^   deslocada" | grep -v "^--"
node scripts/compara-laudo.mjs "$P/abas-antes.xcresult" "$P/abas-depois.xcresult" "$P/abas-cmp" | tail -1
```
Expected (18 Pro, iOS 27): as duas rodadas com `Executed 1 test, with 0 failures`. As 4 cenas de entrar e de Obras ficam idênticas; nas 16 cenas "abas sobre a lista", só os dois rótulos andam 2 pt ("Obras" de x 80 para 78 e "Ajustes" de 217 para 219, a mesma cor e o mesmo tamanho), e a nota só muda onde o rótulo passa a ter outra parte da lista por baixo, sempre acima de 4,5:
```
abas sobre a lista em 10 pt, escuro: 2 palavras, 0 idênticas, 0 mudadas, 2 deslocadas, 0 só antes, 0 só depois, 0 abaixo de 4.5
   deslocada 217→219,830 37×10: #EAFFF6 11.34 (pior 11.01) → #EAFFF6 11.22 (pior 10.87)
abas sobre a lista em 30 pt, claro: 2 palavras, 0 idênticas, 0 mudadas, 2 deslocadas, 0 só antes, 0 só depois, 0 abaixo de 4.5
   deslocada 217→219,830 37×10: #13261E 9.11 (pior 7.84) → #13261E 8.62 (pior 7.71)
abas sobre a lista em 30 pt, escuro: 2 palavras, 0 idênticas, 0 mudadas, 2 deslocadas, 0 só antes, 0 só depois, 0 abaixo de 4.5
   deslocada 217→219,830 37×10: #EAFFF6 6.57 (pior 5.90) → #EAFFF6 6.28 (pior 5.81)
TOTAL: 20 cenas, 113 palavras, 81 idênticas, 0 mudadas, 32 deslocadas, 0 sem par, 0 abaixo de 4.5
```
O rótulo da aba escolhida fica na pílula sólida (`SobreTinta` sobre `Tinta`, 7,32:1 no escuro e 5,25:1 no claro, iguais antes e depois). No Pro Max, o laudo inteiro do fim do PR repete a conta em todas as cenas.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Identidade/CapsulaDeAbas.swift app-ios/CusttaUITests/AjustesUITests.swift
git commit -m "feat: cápsula de abas na borda de 16 pt em todas as telas" -m "A cápsula de abas e o + passam a ficar a 16 pt das bordas da tela, e não mais a 20: é a borda externa de toda forma na grade 16/34 da identidade nova (ajuste 3 do mockup da etapa 4). O Giovani aprovou em 29/10 levar a cápsula ao app inteiro (confirmação 5): com 16 só nas telas novas, ela pularia de lugar ao trocar de aba. A cápsula fica 8 pt mais larga; a altura e os 22 pt da borda de baixo não mudam."
```

---

## PR 1b (app): as peças da identidade nova, sem tela

O PR traz as peças da identidade nova que a obra (PR 1c) e as telas da análise vão usar, todas sem tela na `main`: a grade de bordas 16/34, o bloco de vidro e o sólido verde e âmbar, com o rótulo, a nota e a etiqueta de dentro deles, e a placa (Tarefa 19); o número mono, com o R$ e os centavos menores na linha do número e o piso de 11 pt, como forma nova do `ValorEmDinheiro` (Tarefa 20); o título em SF Mono, o pequeno da barra e a cápsula de metadados (Tarefa 21); a barra empilhada de tópicos, desenhada em `Shape` com os pedaços do núcleo do PR 0b, e a hachura (Tarefa 22); a linha de lançamento na forma mono (Tarefa 23); e a auditoria das peças na maior letra (Tarefa 24). Para provar o que não tem tela, as peças moram numa vitrine só do Debug (`Falsos/VitrineDasPecas.swift`), empurrada em Obras com `CUSTTA_ABRIR=pecas`, com os números da Casa Alphaville da vitrine (os do mockup): os testes de tela, a auditoria e a conferência visual olham para ela. O risco é o das peças compartilhadas: o `ValorEmDinheiro` (20 usos) ganha a forma mono como opção (`mono: nil` é a de hoje), a `LinhaDeGastoView` (a obra e as folhas) ganha a forma mono pelo `linhaMono` do environment (desligado é a de hoje), o `ObrasView` ganha o gancho de Debug da vitrine, e o catálogo ganha um token (`LuzDoSolido`, o filete do sólido). O laudo inteiro, comparado palavra por palavra com o da ponta do 1a, prova que as telas das etapas 1 a 3 não mudaram. Fica escondido na `main` até o PR 1c: todas as peças (nenhuma tela as usa) e a vitrine, que não vai ao Release. Portão da CI: "tudo, com a comparação" (o `ValorEmDinheiro` e a linha do gasto são compartilhados, e o catálogo muda). Marco 1. São 577 linhas de produção (acréscimos + remoções em `app-ios/Custta/` sem `Falsos/`, pelo `git diff --numstat` da ponta do 1a à do 1b), um pouco abaixo dos ~600–800 da tabela do spec; fora da conta, a vitrine em `Falsos/` (116), o colorset gerado (38) e o script das cores (1).

- **Branch:** `feat/pecas-da-identidade-nova`
- **Título:** `feat: peças da identidade nova, sem tela`

### Mapa de arquivos

| Arquivo | Tarefas |
| --- | --- |
| `app-ios/Custta/Identidade/Blocos.swift` (novo) | 19 |
| `app-ios/Custta/Identidade/NumeroMono.swift` (novo) | 20, 21 (o `crescendoComALetra`) |
| `app-ios/Custta/Identidade/Componentes.swift` (`ValorEmDinheiro`) | 20 |
| `app-ios/Custta/Identidade/Titulos.swift` (novo) | 21 |
| `app-ios/Custta/Identidade/BarraEmpilhada.swift` (novo) | 22 |
| `app-ios/Custta/Telas/PecasDaObra.swift` (`LinhaDeGastoView`) | 23 |
| `app-ios/Custta/Identidade/Paleta.swift`, `scripts/cores-app-ios.mjs` e o colorset `LuzDoSolido` (gerado) | 19 |
| `app-ios/Custta/Telas/ObrasView.swift` (o gancho `CUSTTA_ABRIR=pecas`, só Debug) | 19 |
| `app-ios/Custta/Falsos/VitrineDasPecas.swift` (novo, só Debug) | 19 a 23 |
| `app-ios/CusttaTests/BlocosTests.swift`, `NumeroMonoTests.swift`, `TitulosTests.swift`, `BarraEmpilhadaTests.swift`, `LinhaMonoTests.swift` (novos) | 19 a 23, um por tarefa |
| `app-ios/CusttaTests/CoresTests.swift` | 19 |
| `app-ios/CusttaUITests/VitrineUITests.swift` (novo) | 19 a 23 |
| `app-ios/CusttaUITests/AuditoriaUITests.swift` | 24 |
| `tests/app-ios.test.cjs` | 20 (a guarda do `ValorEmDinheiro`), 21 (o `TituloPequenoMono` na lista fixa do `lineLimit`) |

### As peças, para o PR 1c

- **Grade** (`Grade`): `externa` 16, `recuo` 18, `interna` 34, `entreBlocos` 12; `raioDoBloco(_:)` (26; 32 na letra de acessibilidade) e `recuoVertical(_:)` (16; 22). A coluna da tela leva `.padding(.horizontal, Grade.externa)`; as peças não têm margem de fora.
- **Blocos:** `BlocoDeVidro { … }` (o vidro do conteúdo, uma coluna sem espaço entre as linhas); `BlocoSolido(cor: CorDoSolido = .verde) { … }` (`.verde` ou `.ambar`; põe a tinta no `foregroundStyle` e no `tintaDoBloco` do environment); `CabecalhoDoBloco(rotulo:) { etiqueta }` e `CabecalhoDoBloco(rotulo:)` (8 pt acima do número; na letra de acessibilidade, a etiqueta embaixo); `RotuloDoBloco(texto:)`, `NotaDoBloco(texto:)` (2 pt abaixo do número) e `EtiquetaDoSolido(texto:)`, que seguem a tinta do sólido; dentro do vidro, as etiquetas coloridas continuam a `EtiquetaDoIndicador` da etapa 3; `.placa(forte: Bool = false, raio: CGFloat = 12)`.
- **Número:** `ValorEmDinheiro(_ texto: String, mono: TamanhoDoNumero, cor: Token = .texto)`, com o texto do núcleo (`moeda(…)`, `"−" + moeda(…)`, `linha.valor`); `TamanhoDoNumero` `.principal` (40/56), `.grande` (30/48), `.bloco` (22/40), `.linha` (17/34) e `.miudo` (17/30); dentro do sólido, a tinta dele no lugar da `cor`. `corpoDoTexto(_:)` e `crescendoComALetra(de:ate:corpo:)` servem a outra medida do mockup que vai da letra padrão à máxima.
- **Título:** `TituloMono(texto:identificador:)` (o identificador padrão é `tituloDaObra`; o halo é o do nome da obra de hoje); `TituloPequenoMono(texto:letra:)` (identificador `tituloPequenoDaBarra`), com a letra lida fora da barra: a tela lê o `@Environment(\.dynamicTypeSize)` e a passa, porque dentro do `ToolbarItem` ela para antes da letra de acessibilidade; `CapsulaDeMetadados { … }` (subheadline no secundário do vidro; uma coluna com 6 pt entre as linhas).
- **Barra:** `BarraDeTopicos(pedacos: [PedacoDoAnel], topicos: [String: Topico])` (a barra na placa forte, com o identificador `barraDeTopicos` e o rótulo "Gastos por tópico", e a legenda); `BarraEmpilhada(pedacos:)` sozinha; `corDoPedaco(_:)`, `nomeDoPedaco(_:topicos:)` e `fonteDoTexto(_:_:)`; `Hachura(traco:passo:)`, uma `Shape`. Os pedaços saem de `pedacosDoAnel(gastoPorTopico(obra, …))`.
- **Linha:** `.environment(\.linhaMono, true)` na lista da obra; a `LinhaDeGastoView`, a `LinhaArrastavel` e os identificadores ficam os mesmos.

### Ponto de controle do fim do PR

No Mac, com o produto da ponta do PR e o da ponta do 1a (o commit anterior ao PR), cada um copiado com `cp -c` e rodado pelo seu `.xctestrun`, para os dois simuladores rodarem ao mesmo tempo sem compilar por cima de uma rodada:

1. **O laudo inteiro no Pro Max, comparado palavra por palavra com o da ponta do 1a** (spec, "A comparação"; memória `laudo-inteiro-no-pro-max-no-fim-do-pr`): `-only-testing:CusttaUITests/LeituraNoVidroUITests` nos dois produtos, no mesmo Pro Max, e o comparador (`node scripts/compara-laudo.mjs <antes.xcresult> <depois.xcresult> <pasta> [--detalhe]`, da Tarefa 15) sobre os dois resultados. Este laudo é a prova da linha da etapa 3: o `meta(_:iconeDoPagamento:)` da Tarefa 23 passa por ela (com a fonte e o ícone do Pix e do cartão), e nenhum teste de unidade prende o ícone do pagamento na linha antiga; por isso ele roda com o produto da ponta do PR, e não com o de uma tarefa do meio. Expected: as duas rodadas com `Executed 18 tests, with 0 failures (0 unexpected)` (3.307 s na ponta do 1a e 3.167 s na do 1b), e o comparador: `TOTAL: 175 cenas, 3590 palavras, 3590 idênticas, 0 mudadas, 0 deslocadas, 0 sem par, 0 abaixo de 4.5`. As telas das etapas 1 a 3 não mudaram: a forma de hoje do `ValorEmDinheiro` e da linha do gasto saiu igual, palavra por palavra. (Esses números saíram de um produto anterior ao `meta(_:iconeDoPagamento:)`; com o da ponta, a comparação tem de dar o mesmo.)
2. **Os testes inteiros no 18 Pro**, ao mesmo tempo: `-only-testing:CusttaTests -only-testing:CusttaUITests -skip-testing:CusttaUITests/LeituraNoVidroUITests` (as auditorias entram aqui, na `AuditoriaUITests`, com a da vitrine). Expected: `Executed 227 tests, with 1 test skipped and 1 failure` nas telas, em 4.474 s, com a `AuditoriaUITests` inteira verde (inclusive a da vitrine) e a `VitrineUITests`. A falha é o `FolhasDeOrigemUITests/testASetaDoIndicadorAbreAFolhaDoAPagar` (achado 3 do PR 1a): 1 failure nos 3 últimos dias do mês; fora deles, 0. O conserto é o PR #93, só de teste, que entra antes do PR 0. Na unidade: `✔ Test run with 195 tests in 38 suites passed` (conferido em 30/10 na ponta do 1b, `ab36f9f`, com o teste do Negrito da Tarefa 19).
3. **Node:** `npm run test:unit 2>&1 | tail -8`. Expected: `ℹ tests 411`, `ℹ pass 411`, `ℹ fail 0`.
4. **A vitrine lado a lado com o mockup**, no 18 Pro, com a barra de status em 9:41 e o fundo parado, numa pasta fora do repositório: o alto (título, cápsula, sólido e blocos), a barra de tópicos, os lançamentos e os números, no escuro e no claro, e o alto na letra máxima. Com o app da ponta instalado, cada print abre a vitrine pelo `simctl`:
   ```bash
   U=<udid do seu 18 Pro>
   xcrun simctl status_bar $U override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
   SIMCTL_CHILD_CUSTTA_SERVICOS=falsos SIMCTL_CHILD_CUSTTA_CONTA=senha SIMCTL_CHILD_CUSTTA_DADOS=vitrine SIMCTL_CHILD_CUSTTA_ABRIR=pecas \
     xcrun simctl launch --terminate-running-process $U br.com.custta.app -custta.reduzirMovimento YES -custta.rolagem 0
   # rolagens 0, 450, 900 e 1350; no claro, -custta.tema claro; na letra máxima,
   # -UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL
   sleep 7; xcrun simctl io $U screenshot 1-topo-escuro.png
   ```
   Expected: 8 prints do app (o alto, o meio, o fim e os números no escuro; o alto e o meio no claro; o alto na letra máxima nos dois temas) e 6 lado a lado com os do mockup (o alto, a barra de tópicos e os lançamentos no escuro; o alto no claro; o alto na letra máxima, no escuro e no claro). As peças batem com o `parte1-obra-topo`, o `obra-meio` e o `obra-fim`: o sólido com o R$ e os centavos menores na linha do número, a cápsula, a barra com os 7 pedaços e a legenda "Terreno 38%, Estrutura 11%, Cerâmica 9%, Mão de obra 8%, e mais 10 tópicos", a linha mono com o ícone do tópico. Diferenças: na letra máxima, "Casa Alphaville" quebra em duas linhas (achado 7); a data do "começou em" segue o dia de hoje (a vitrine conta as datas de hoje).
5. **O Release sem a vitrine** (spec, "Escondido na `main`": "o `nm` confere"; memória `release-sem-ganchos-conferir-por-nm`: o `strings` engana). O Release compila para o simulador sem assinar, no DerivedData do produto da ponta (`<dd>`), e o `nm` conta os símbolos da vitrine no binário do Release e, de controle, os da `RaizView`, que vai ao Release; no Debug, a vitrine fica no `Custta.debug.dylib`:
   ```bash
   xcodebuild build -project app-ios/Custta.xcodeproj -scheme Custta -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -derivedDataPath <dd> -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | tail -1
   for s in VitrineDasPecas RaizView; do echo "$s release=$(nm -a <dd>/Build/Products/Release-iphonesimulator/Custta.app/Custta | grep -c $s) debug=$(nm -a <dd>/Build/Products/Debug-iphonesimulator/Custta.app/Custta.debug.dylib | grep -c $s)"; done
   ```
   Expected: `** BUILD SUCCEEDED **` e:
   ```
   VitrineDasPecas release=0 debug=250
   RaizView release=90 debug=384
   ```

### Achados que mudam o spec ou uma decisão

1. **O `@ScaledMetric(relativeTo: .body)` para em 48 na letra máxima, e o corpo do texto é 53.** Medida do mockup que vai da letra padrão à máxima não sai do `@ScaledMetric` (ele chega a 48/17 do valor, não a 53/17): as peças leem o tamanho da fonte (`corpoDoTexto`, `fonteDoTexto`) e crescem por `crescendoComALetra`. **Recomendação:** o 1c usa as mesmas funções para as medidas da letra máxima do mockup (a altura de 72 pt das linhas, os chips de 32 pt, o raio de 32 dos blocos já está na `Grade`).
2. **A auditoria de tipo dinâmico não prende o número.** Com o número mono fixo (o corpo em 17), com teto no AX2 (`.dynamicTypeSize(...accessibility2)`) ou sem o piso de encolher (`minimumScaleFactor(1)`, o maior valor cortado com reticências), a auditoria da vitrine na maior letra passa; com o título fixo, ela reprova ("Dynamic Type font sizes are unsupported"). **Recomendação:** a prova do número fica nos testes de unidade da Tarefa 20: o `numeroNaTelaCresceACadaPasso`, que mede a largura do número na tela a cada passo da letra (sobe a cada passo e, na máxima, é 56/40 da padrão) e reprova com o corpo fixo em 17 e com o teto no AX2, e a largura do maior valor na letra máxima em 375 pt, como o spec já diz para o corte ("o laudo não vê corte; a prova é o teste de largura"); o 1c repete o teste de largura no sólido da obra montada.
3. **Número solto reprova a descrição suficiente.** A auditoria acha "Label not human-readable" num elemento só de algarismos ("R$ 842.317,45"), com o mono, com o SF Pro e até num `Text` simples (cinco variantes provadas). **Recomendação:** na obra (1c), cada bloco junta o rótulo, a etiqueta, o número e a nota num elemento (`.accessibilityElement(children: .combine)`), como os indicadores da etapa 3 ("Total gasto, 46 lançamentos, R$ 842.317,45, bruto, sem correção"); por isso a auditoria da vitrine (Tarefa 24) fica sem a descrição suficiente.
4. **A linha mono sem o ícone do pagamento.** O spec diz só que a linha da obra "ganha o valor em mono e o ícone pequeno na 2ª linha"; o mockup aprovado (`gastoLinha`, parte1.js:248-252; `parte1-obra-fim.png`) também tira o raio e o cartão do sistema que a etapa 3 põe antes de "Pix" e "Cartão". A linha mono segue o mockup; o texto fica por extenso, e a linha das folhas não muda. **Recomendação:** manter; se o Giovani quiser o ícone de volta, é o parâmetro `iconeDoPagamento` do `meta`.
5. **"Quando não cabe ao lado do nome, desce" sem número no spec.** A linha mono deixa o valor ao lado enquanto sobram 120 pt para o título (cerca de 12 letras do título em body semibold). Num iPhone de 375 pt (307 no cartão), até "−R$ 1.234.567,89" fica ao lado; o de R$ 1 bilhão desce. **Recomendação:** 120 pt, como está.
6. **Irmão fracionário, duas vezes.** A legenda da barra (o % de largura fracionária ao lado do nome, em 7 de 36 combinações de letra e largura) e a linha mono (o ícone do tópico em tamanho fracionário, na AX2 e AX3) passavam 1/3 de pt da largura e alargavam a coluna inteira da vitrine (o teste da grade pegou 386,5 no lugar de 386). Consertado na própria tarefa (o % numa coluna de largura inteira; o ícone em pontos inteiros), com uma varredura por `sizeThatFits` em todas as letras, em 343, 370 e 408 pt. **Recomendação:** o 1c faz a mesma varredura na obra montada (memória `irmao-fracionario-passa-um-pixel`).
7. **O título na letra máxima quebra "Casa Alphaville".** O SF Mono semibold do iOS avança ~0,62 em (a linha "Alphaville" mede 252 pt em 44 pt), e o nome não cabe em 370 pt; no mockup (Chromium), coube numa linha. O spec já aceita ("nome comprido quebra em duas linhas"). O app fica com a altura de linha da fonte, e não os 38 pt de linha do CSS no título de 30. **Recomendação:** o Verniz confere no lado a lado da obra (1c); nada muda no spec.
8. **O halo do título não muda neste PR:** o `TituloMono` usa o do nome da obra de hoje (30% no escuro, 10% no claro); a calibração do mockup (38%, 62% na letra máxima) vai com o título na obra, pelo laudo (nota do 1a).
9. **Duas medidas sem token exato, resolvidas por token:** a sombra do sólido âmbar no claro é o `Alerta` (#8A5A06) a 22% (o mockup usa um âmbar escuro solto, #A06E0A), e o filete de luz do sólido ganhou o token `LuzDoSolido` (branco a 35%), porque o catálogo não tinha um branco com esse papel.
10. **O contraste das peças sobre a aurora ainda não tem laudo:** nenhuma cena abre a vitrine; ele é medido quando a obra (1c) entrar no laudo. O texto sobre os sólidos já está no `PARES_SOLIDOS` (Tarefa 16).
11. **O título pequeno não cresce lendo a letra dentro da barra.** Dentro do `ToolbarItem`, o `dynamicTypeSize` para antes da letra de acessibilidade (memória `pecas-da-folha-na-letra-grande`): lida ali, a letra deixava o título em ~16,5 pt na máxima, e não nos 20 do spec ("na letra máxima, 44 e 20 pt"), e nada pegava (o teste de unidade mede a peça solta, e a auditoria exclui o título pelo identificador). O `TituloPequenoMono(texto:letra:)` recebe a letra de fora da barra, como o `PassoDaFolha` com o `letraGrande`, e a guarda de altura da vitrine (Tarefa 21) prende o crescimento dentro da barra. **Recomendação:** na obra (1c), a tela lê a letra fora da barra e a passa ao título, e o teste de tela da obra repete a guarda de altura.

### Task 19: Grade 16/34, blocos de vidro e sólido e placa

As peças de bloco da identidade nova nascem sem tela (spec, "Identidade" e a linha 1b da tabela de PRs; medidas do `parte1.html`, "Medidas e especificação", e do `parte1.css:165-174` e `:207`). A grade de bordas (`Grade`): toda forma começa a 16 pt da borda da tela e todo texto dentro dela a 34 (os 16 e o recuo de 18), igual à direita, e a letra máxima não muda as bordas; entre blocos, 12 pt. O bloco de vidro (`BlocoDeVidro`) é o vidro do conteúdo (`.superficie(.conteudo, …)`), com cantos de 26 pt e recuo de 16 × 18 pt, que passam a 32 e 22 × 18 na letra de acessibilidade (o mockup só desenha a AX5; da AX1 em diante, os da AX5). O sólido (`BlocoSolido`), um por tela e que não é vidro, é o verde (`DestaqueSolido`, texto `TintaSobreDestaque`) ou o âmbar (`SolidoAmbar`, texto `TintaSobreAmbar`), com a sombra de 36 pt de desfoque a 14 pt para baixo na cor do bloco (20% no escuro e 22% no claro; o mockup usa o `Destaque` no verde e, no âmbar do claro, um âmbar escuro, aqui o `Alerta`) e o filete de luz de 1 pt no topo (o `inset 0 1px 0` branco a 35%), que ganha o token `LuzDoSolido`. Dentro do sólido, o rótulo, a nota e a etiqueta vêm na tinta dele (o mockup troca o `--sec` pela tinta), pelo `tintaDoBloco` do environment; fora, no secundário do vidro. O cabeçalho do bloco põe a etiqueta à direita do rótulo e, na letra de acessibilidade, embaixo dele; fora dela, o rótulo ocupa o que sobra por um `frame(maxWidth: .infinity)`, e não por um `Spacer` ao lado: com o Negrito (`legibilityWeight` `.bold`), o `Spacer` arredondava para cima, e o cabeçalho do sólido passava 1/3 pt da largura de dentro dele (372,333 nos 372 do Pro Max, achado 1 da revisão B do PR 1c). A etiqueta do sólido ("46 lançamentos") é a `EtiquetaDoIndicador` (PecasDaObra.swift:55) na tinta sobre ela mesma a 14%, sem mexer na da etapa 3. A placa é o tom chapado do fundo, sem desfoque, atrás das marcas de gráfico (`Placa` a 58% e 66%; a forte, 84% e 92%, atrás da barra empilhada). Hoje a obra tem 20 pt de borda (ObraView.swift:126) e cartões de raio 24 (PecasDaObra.swift:479): a obra muda no PR 1c. As peças aparecem na vitrine, uma tela só do Debug, empurrada em Obras com `CUSTTA_ABRIR=pecas`, com os números da Casa Alphaville da vitrine (os do mockup).

**Files:**
- Create: `app-ios/Custta/Falsos/VitrineDasPecas.swift`
- Create: `app-ios/Custta/Identidade/Blocos.swift`
- Modify: `app-ios/Custta/Identidade/Paleta.swift`
- Modify: `app-ios/Custta/Telas/ObrasView.swift`
- Modify: `scripts/cores-app-ios.mjs`
- Test (novo): `app-ios/CusttaTests/BlocosTests.swift`
- Test (alterar): `app-ios/CusttaTests/CoresTests.swift`
- Test (novo): `app-ios/CusttaUITests/VitrineUITests.swift`
- Gerado: `app-ios/Custta/Assets.xcassets/Esmeralda/LuzDoSolido.colorset/Contents.json` (`node scripts/cores-app-ios.mjs`)

**Interfaces:**
- Consumes: `.superficie(_:em:)` e `VidroTokens.secundario` (Vidro.swift); os tokens `destaqueSolido`, `tintaSobreDestaque`, `solidoAmbar`, `tintaSobreAmbar`, `placa`, `placaForte`, `destaque` e `alerta`; `indicadoresDaObra(_:taxa:hoje:)` e `DadosDeExemplo.vitrine()` (só na vitrine).
- Produces: `Grade.externa` (16), `.recuo` (18), `.interna` (34), `.entreBlocos` (12), `Grade.raioDoBloco(_:)` e `Grade.recuoVertical(_:)`; `BlocoDeVidro { … }`; `CorDoSolido` (`.verde`, `.ambar`) e `BlocoSolido(cor:) { … }`; `CabecalhoDoBloco(rotulo:) { etiqueta }` e `CabecalhoDoBloco(rotulo:)`; `RotuloDoBloco(texto:)`, `NotaDoBloco(texto:)` e `EtiquetaDoSolido(texto:)`; `EnvironmentValues.tintaDoBloco: Token?`; `.placa(forte:raio:)`; `Token.luzDoSolido`; `VitrineDasPecas` (Debug) e o `CUSTTA_ABRIR=pecas`.

- [ ] **Step 1: Escrever os testes**

Os testes de unidade prendem por pixel as cores do sólido nos dois temas, com o filete de 1 pt no topo, a tinta do bloco no texto de dentro e as duas placas; o recuo e o raio na letra de acessibilidade; e, por pixel, o canto do sólido, que segue o raio (a 8 pt das duas bordas, dentro da quina de 26 e fora da de 32), porque a função `Grade.raioDoBloco` sozinha não prova que o bloco a usa. A varredura do cabeçalho do sólido com a etiqueta mede por `sizeThatFits`, com e sem o Negrito, em todo tamanho de letra, na escala 3 e na largura de dentro do sólido nos três iPhones (o bloco de 343, 370 e 408 pt menos o `Grade.recuo` de cada lado: 307, 334 e 372). O de tela, as bordas de 16 e 34 pt na vitrine, na letra padrão e na máxima.

Criar `app-ios/CusttaTests/BlocosTests.swift`:

```swift
import Testing
import SwiftUI
@testable import Custta

/* As peças de bloco da identidade nova (etapa 4, PR 1b) que o print não prova sozinho: as cores do sólido verde e do âmbar
   nos dois temas, com o filete de luz no topo; a tinta do bloco no rótulo, na nota e na etiqueta de dentro dele; as duas
   placas; e o recuo e o raio do bloco, que crescem na letra de acessibilidade. */
@MainActor
struct BlocosTests {
    /// Os pixels RGBA (pré-multiplicados) do desenho no esquema dado.
    private func pixels(_ conteudo: some View, _ esquema: ColorScheme, escala: CGFloat = 1) throws -> (w: Int, h: Int, em: (Int, Int) -> [Int]) {
        let r = ImageRenderer(content: conteudo.environment(\.paleta, Paleta()).environment(\.colorScheme, esquema))
        r.scale = escala
        let imagem = try #require(r.cgImage)
        let (w, h) = (imagem.width, imagem.height)
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        rgba.withUnsafeMutableBytes { bytes in
            CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        let copia = rgba
        return (w, h, { x, y in (0..<4).map { Int(copia[(y * w + x) * 4 + $0]) } })
    }

    private func perto(_ a: [Int], _ b: [Int], folga: Int = 2) -> Bool { zip(a, b).allSatisfy { abs($0 - $1) <= folga } }

    /// O fundo do sólido (#3AD17E nos dois temas; o âmbar, #FFD98A e #F2C15A) e o filete de luz de 1 pt no topo, o branco a
    /// 35% sobre ele; logo abaixo do filete, o fundo de novo.
    @Test(arguments: [ColorScheme.dark, .light])
    func solidoVerdeEAmbarComOFileteNoTopo(_ esquema: ColorScheme) throws {
        let ambar = esquema == .dark ? [0xFF, 0xD9, 0x8A] : [0xF2, 0xC1, 0x5A]
        for (cor, fundo) in [(CorDoSolido.verde, [0x3A, 0xD1, 0x7E]), (.ambar, ambar)] {
            let p = try pixels(BlocoSolido(cor: cor) { Color.clear }.frame(width: 100, height: 60), esquema)
            let filete = fundo.map { Int((Double($0) + Double(255 - $0) * 0.35).rounded()) }
            #expect(perto(p.em(50, 30), fundo + [0xFF]), "\(cor), o fundo: \(p.em(50, 30))")
            #expect(perto(p.em(50, 0), filete + [0xFF]), "\(cor), o filete: \(p.em(50, 0))")
            #expect(perto(p.em(50, 1), fundo + [0xFF]), "\(cor), 1 pt abaixo do filete: \(p.em(50, 1))")
        }
    }

    /// A cor mais comum entre os pixels opacos (o miolo das letras).
    private func corDoTexto(_ conteudo: some View, _ esquema: ColorScheme = .dark) throws -> [Int] {
        let p = try pixels(conteudo, esquema, escala: 3)
        var contagem: [[Int]: Int] = [:]
        for y in 0..<p.h { for x in 0..<p.w { let c = p.em(x, y); if c[3] == 255 { contagem[Array(c[0..<3]), default: 0] += 1 } } }
        return contagem.max { $0.value < $1.value }?.key ?? []
    }

    /// Dentro do sólido, o rótulo, a nota e a etiqueta vêm na tinta dele (#04100C no verde, #2B1B00 no âmbar); fora, o rótulo e
    /// a nota vêm no secundário do vidro.
    @Test func tintaDoBlocoNoRotuloNaNotaENaEtiqueta() throws {
        for (tinta, cor) in [(Token.tintaSobreDestaque, [0x04, 0x10, 0x0C]), (.tintaSobreAmbar, [0x2B, 0x1B, 0x00])] {
            #expect(try corDoTexto(RotuloDoBloco(texto: "Total gasto").environment(\.tintaDoBloco, tinta)) == cor)
            #expect(try corDoTexto(NotaDoBloco(texto: "bruto, sem correção").environment(\.tintaDoBloco, tinta)) == cor)
            #expect(try corDoTexto(EtiquetaDoSolido(texto: "46 lançamentos").environment(\.tintaDoBloco, tinta)) == cor)
        }
        #expect(try corDoTexto(RotuloDoBloco(texto: "Corrigido pelo banco")) == [0xD6, 0xE8, 0xE0], "o SecundarioTransparente")
        #expect(try corDoTexto(NotaDoBloco(texto: "Correção até hoje")) == [0xD6, 0xE8, 0xE0])
    }

    /// A placa, um tom chapado do fundo: 58% no escuro e 66% no claro; a forte, 84% e 92%.
    @Test func placaEPlacaForte() throws {
        for (esquema, placa, forte) in [(ColorScheme.dark, 0x94, 0xD6), (.light, 0xA8, 0xEB)] {
            #expect(try pixels(Color.clear.frame(width: 40, height: 40).placa(), esquema).em(20, 20)[3] == placa)
            #expect(try pixels(Color.clear.frame(width: 40, height: 40).placa(forte: true), esquema).em(20, 20)[3] == forte)
        }
    }

    /// O recuo de cima e de baixo do bloco (16 pt; 22 na letra de acessibilidade) e o raio (26; 32), no vidro e no sólido.
    @Test func recuoERaioCrescemNaLetraDeAcessibilidade() {
        func altura<V: View>(_ bloco: V, _ t: DynamicTypeSize) -> CGFloat {
            UIHostingController(rootView: bloco.dynamicTypeSize(t)).sizeThatFits(in: CGSize(width: 300, height: CGFloat.infinity)).height
        }
        for (t, recuo) in [(DynamicTypeSize.large, CGFloat(16)), (.accessibility1, 22), (.accessibility5, 22)] {
            let (vidro, solido) = (altura(BlocoDeVidro { Color.clear.frame(height: 10) }, t), altura(BlocoSolido { Color.clear.frame(height: 10) }, t))
            #expect(vidro == 10 + 2 * recuo, "\(t): \(vidro)")
            #expect(solido == 10 + 2 * recuo, "\(t): \(solido)")
        }
        #expect(Grade.raioDoBloco(.large) == 26 && Grade.raioDoBloco(.xxxLarge) == 26 && Grade.raioDoBloco(.accessibility1) == 32)
        #expect(Grade.externa == 16 && Grade.interna == 34 && Grade.entreBlocos == 12)
    }

    /// O canto do sólido segue o raio da grade: a 8 pt das duas bordas, dentro da quina de 26 e fora da de 32.
    @Test func raioDoSolidoCresceNaLetraDeAcessibilidade() throws {
        for (letra, dentro) in [(DynamicTypeSize.large, true), (.accessibility1, false)] {
            let p = try pixels(BlocoSolido { Color.clear }.frame(width: 100, height: 100).dynamicTypeSize(letra), .dark)
            #expect((p.em(8, 8)[3] == 255) == dentro, "\(letra): \(p.em(8, 8))")
        }
    }

    /// O cabeçalho do sólido com a etiqueta, com e sem o Negrito, em todo tamanho de letra e na largura de dentro do sólido
    /// nos três iPhones (o bloco de 343, 370 e 408 pt, menos o recuo de 18 de cada lado), na escala 3 deles: nunca passa da
    /// largura que recebe. Com o Negrito, o rótulo ao lado de um `Spacer` arredondava para cima, e o cabeçalho passava 1/3
    /// pt (372,333 nos 372 do Pro Max), e o bloco com ele.
    @Test func cabecalhoDoSolidoNaoPassaDaLargura() {
        let pares = [("Total gasto", "46 lançamentos"), ("Total gasto", "1 lançamento"), ("Total gasto", "sem gastos"),
                     ("Rende menos que o banco", "banco paga 1%")]
        for negrito in [false, true] {
            for tamanho in DynamicTypeSize.allCases {
                for bloco in [CGFloat(343), 370, 408] {
                    let disponivel = bloco - 2 * Grade.recuo
                    for (rotulo, etiqueta) in pares {
                        let cabecalho = CabecalhoDoBloco(rotulo: rotulo) { EtiquetaDoSolido(texto: etiqueta) }
                            .environment(\.tintaDoBloco, .tintaSobreDestaque).dynamicTypeSize(tamanho)
                            .environment(\.legibilityWeight, negrito ? .bold : .regular).environment(\.displayScale, 3)
                        let medida = UIHostingController(rootView: cabecalho)
                            .sizeThatFits(in: CGSize(width: disponivel, height: CGFloat.infinity)).width
                        #expect(medida <= disponivel, "\(rotulo), \(etiqueta), \(tamanho), negrito \(negrito), a \(disponivel) pt: \(medida)")
                    }
                }
            }
        }
    }
}
```

Em `app-ios/CusttaTests/CoresTests.swift`:

```diff
--- a/app-ios/CusttaTests/CoresTests.swift
+++ b/app-ios/CusttaTests/CoresTests.swift
@@ -50,6 +50,7 @@ struct CoresTests {
             (.barraApagada, "#EAFFF666", "#142B2394"),                                          // 40% e 58%
             (.gradeGrafico, "#EAFFF624", "#142B2324"), (.eixoGrafico, "#EAFFF64D", "#142B2352"), // 14%; 30% e 32%
             (.anelApagado, "#123128", "#DCEAE3"), (.anelSeparador, "#04100C8C", "#FFFFFFBF"),   // 55% e 75%
+            (.luzDoSolido, "#FFFFFF59", "#FFFFFF59"),                                         // o filete do sólido: branco a 35%
         ]
         for (token, escuro, claro) in tabela {
             #expect(hex(token, .dark) == escuro, "\(token) no escuro")
```

Criar `app-ios/CusttaUITests/VitrineUITests.swift`:

```swift
import XCTest

/* A vitrine das peças da identidade nova (etapa 4, PR 1b), que só o Debug abre (CUSTTA_ABRIR=pecas, em Obras): as peças
   sobre a aurora, nas medidas do mockup aprovado, antes de a obra (PR 1c) usá-las. */
@MainActor
final class VitrineUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    private func abrirVitrine(_ argumentos: [String] = []) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "pecas", argumentos: argumentos)
        XCTAssertTrue(app.elemento("vitrine-solido").waitForExistence(timeout: 10), "a vitrine das peças")
        return app
    }

    /// A grade de bordas (ajuste 3 do mockup): os blocos a 16 pt das duas bordas da tela e o texto de dentro a 34, na letra
    /// padrão e na máxima, que não muda as bordas.
    func testBlocosNaGradeDeBordas() {
        for argumentos in [[], maiorLetra] {
            let app = abrirVitrine(argumentos)
            let tela = app.frame.width
            for id in ["vitrine-solido", "vitrine-vidro", "vitrine-ambar"] {
                let bloco = app.elemento(id).frame
                XCTAssertEqual(bloco.minX, 16, accuracy: 0.5, "\(id) \(argumentos)")
                XCTAssertEqual(bloco.maxX, tela - 16, accuracy: 0.5, "\(id) \(argumentos)")
            }
            for rotulo in ["Total gasto", "Corrigido pelo banco", "Rende menos que o banco"] {
                XCTAssertEqual(app.staticTexts[rotulo].frame.minX, 34, accuracy: 0.5, "\(rotulo) \(argumentos)")
            }
            app.terminate()
        }
    }
}
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E '^/.*error:' | sed 's/^.*CusttaTests\//CusttaTests\//' | sort -t: -k2,2n -u | head -3
```
Expected: o `CusttaTests` não compila, nos dois arquivos de teste (no `BlocosTests`, o compilador só aponta o primeiro erro):
```
CusttaTests/BlocosTests.swift:33:31: error: cannot find 'CorDoSolido' in scope
CusttaTests/CoresTests.swift:53:15: error: type 'Token' has no member 'luzDoSolido'
```
Com o cabeçalho de antes (o rótulo e um `Spacer(minLength: 0)` ao lado, no lugar do `frame`), a varredura compila e reprova só no Negrito:
```bash
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/BlocosTests 2>&1 | grep -E "↳ .*negrito .* pt: |Test run with"
```
```
↳ Total gasto, 46 lançamentos, .medium, negrito true, a 372.0 pt: 372.3333333333333
↳ Rende menos que o banco, banco paga 1%, .xxxLarge, negrito true, a 307.0 pt: 307.3333333333333
↳ Rende menos que o banco, banco paga 1%, .xxxLarge, negrito true, a 372.0 pt: 372.3333333333333
✘ Test run with 6 tests in 1 suite failed after 0.229 seconds with 3 issues.
```

- [ ] **Step 3: Implementar**

Os dois blocos empilham o conteúdo numa coluna antes do recuo: num `TupleView` solto, o recuo cairia em cada filho. O filete é a forma menos ela mesma 1 pt abaixo (`subtracting`), que afina nas quinas como o `inset` do CSS. A vitrine vive em `Falsos/` (só Debug) e cresce a cada tarefa do PR.

Criar `app-ios/Custta/Falsos/VitrineDasPecas.swift`:

```swift
#if DEBUG
import SwiftUI
import CusttaNucleo

/* A vitrine das peças da identidade nova (etapa 4, PR 1b), só no Debug: nenhuma tela as usa antes da obra (PR 1c), e aqui
   os testes de tela e a conferência visual as veem sobre a aurora, nas medidas do mockup aprovado (parte1.html), com os
   números da Casa Alphaville da vitrine (os do mockup). `CUSTTA_ABRIR=pecas` a empurra em Obras. */
struct VitrineDasPecas: View {
    private let estado = Estado.de(DadosDeExemplo.vitrine())

    var body: some View {
        let casa = estado.obras[0]
        let hoje = dataLocalISO(.now, fuso: .current)
        let indicadores = indicadoresDaObra(casa, taxa: estado.config.taxaMensal, hoje: hoje)
        ScrollView {
            VStack(alignment: .leading, spacing: Grade.entreBlocos) {
                BlocoSolido {
                    CabecalhoDoBloco(rotulo: "Total gasto") { EtiquetaDoSolido(texto: indicadores.etiquetaDoTotal) }
                    ValorEmDinheiro(texto: indicadores.totalGasto, fonte: .largeTitle.weight(.bold), cor: .tintaSobreDestaque)
                    NotaDoBloco(texto: "bruto, sem correção")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("vitrine-solido")
                BlocoDeVidro {
                    CabecalhoDoBloco(rotulo: "Corrigido pelo banco")
                    ValorEmDinheiro(texto: indicadores.corrigido, fonte: .title2.weight(.bold))
                    NotaDoBloco(texto: indicadores.notaDoCorrigido)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("vitrine-vidro")
                BlocoSolido(cor: .ambar) {
                    CabecalhoDoBloco(rotulo: "Rende menos que o banco") { EtiquetaDoSolido(texto: "banco paga 1%") }
                    NotaDoBloco(texto: "vendendo daqui a 12 meses")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("vitrine-ambar")
                BlocoDeVidro {
                    CabecalhoDoBloco(rotulo: "Placa e placa forte")
                    Color.clear.frame(height: 16).padding(8).placa().accessibilityIdentifier("vitrine-placa")
                    Color.clear.frame(height: 16).padding(8).placa(forte: true).accessibilityIdentifier("vitrine-placaForte")
                }
            }
            .padding(.horizontal, Grade.externa)
            .padding(.bottom, 98)
        }
        .scrollIndicators(.hidden)
        .bordaDeRolagem(abas: true)
        .containerBackground(.clear, for: .navigation)
        .navigationTitle("Peças")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
```

Criar `app-ios/Custta/Identidade/Blocos.swift`:

```swift
import SwiftUI

/* As peças de bloco da identidade nova (etapa 4; mockup aprovado em ~/Documents/custta-mockups/nativo/etapa4/, parte1.css e
   "Medidas e especificação" do parte1.html): a grade de bordas 16/34, o bloco de vidro de um assunto, o bloco sólido
   protagonista (verde, ou âmbar no veredito), o rótulo, a nota e a etiqueta de dentro deles, e a placa, um tom chapado sem
   desfoque que não é vidro. Nenhuma tela as usa ainda: a obra (PR 1c) e as telas da análise. Nunca vidro dentro de vidro:
   dentro do bloco de vidro, só o sólido e a placa. */

/// A grade de bordas (ajuste 3 do mockup): toda forma (bloco, cápsula, botão, cápsula de abas, voltar) e o título solto
/// começam a 16 pt da borda da tela; todo texto, chip, ponto ou ícone dentro de uma forma, a 34 (os 16 e o recuo de 18 do
/// bloco). À direita, o mesmo. A letra máxima não muda as bordas; o texto centralizado é a exceção.
enum Grade {
    static let externa: CGFloat = 16
    static let recuo: CGFloat = 18
    static let interna: CGFloat = externa + recuo
    /// O espaço entre dois blocos.
    static let entreBlocos: CGFloat = 12

    /// O raio dos cantos do bloco e o recuo de cima e de baixo: 26 e 16 pt; 32 e 22 na letra de acessibilidade.
    static func raioDoBloco(_ tamanho: DynamicTypeSize) -> CGFloat { tamanho.isAccessibilitySize ? 32 : 26 }
    static func recuoVertical(_ tamanho: DynamicTypeSize) -> CGFloat { tamanho.isAccessibilitySize ? 22 : 16 }
}

extension EnvironmentValues {
    /// A tinta do bloco sólido em volta (nil fora dele): o rótulo, a nota, a etiqueta e o número de dentro seguem ela.
    @Entry var tintaDoBloco: Token? = nil
}

/// Um assunto por bloco, no vidro do conteúdo, com os cantos e o recuo da grade. Ocupa a largura toda; a borda de 16 pt é
/// da coluna da tela.
struct BlocoDeVidro<Conteudo: View>: View {
    @ViewBuilder let conteudo: Conteudo
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { conteudo }
            .padding(.vertical, Grade.recuoVertical(tamanho))
            .padding(.horizontal, Grade.recuo)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficie(.conteudo, em: .rect(cornerRadius: Grade.raioDoBloco(tamanho)))
    }
}

/// O bloco sólido protagonista, um por tela, que não é vidro: o verde (o Total gasto da obra, o total do Relatório, o "Vale
/// a pena") ou o âmbar (o "Rende menos que o banco"), com o texto escuro, a sombra de 36 pt na cor do bloco (20% no escuro,
/// 22% no claro) e o filete de luz no topo. Os textos de dentro vêm na tinta do bloco, o secundário também (o mockup troca o
/// --sec pela tinta). No claro, a sombra do âmbar é o Alerta, mais escuro que o bloco, como o mockup.
struct BlocoSolido<Conteudo: View>: View {
    var cor: CorDoSolido = .verde
    @ViewBuilder let conteudo: Conteudo
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let escuro = esquema == .dark
        let (fundo, tinta, sombra): (Token, Token, Token) = switch cor {
        case .verde: (.destaqueSolido, .tintaSobreDestaque, .destaque)
        case .ambar: (.solidoAmbar, .tintaSobreAmbar, escuro ? .solidoAmbar : .alerta)
        }
        let forma = RoundedRectangle(cornerRadius: Grade.raioDoBloco(tamanho))
        VStack(alignment: .leading, spacing: 0) { conteudo }
            .padding(.vertical, Grade.recuoVertical(tamanho))
            .padding(.horizontal, Grade.recuo)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(paleta.cor(tinta))
            .environment(\.tintaDoBloco, tinta)
            .background {
                forma.fill(paleta.cor(fundo))
                    .shadow(color: paleta.cor(sombra).opacity(escuro ? 0.20 : 0.22), radius: 18, y: 14)
                    // O filete: a forma menos ela mesma 1 pt abaixo (o inset 0 1px 0 do mockup), afinando nas quinas.
                    .overlay { forma.subtracting(forma.offset(y: 1)).fill(paleta.cor(.luzDoSolido)) }
            }
    }
}

/// O alto do bloco: o rótulo e, à direita, a etiqueta; na letra de acessibilidade, a etiqueta embaixo do rótulo (o
/// .cab-bloco do mockup). 8 pt acima do número.
struct CabecalhoDoBloco<Etiqueta: View>: View {
    let rotulo: String
    @ViewBuilder var etiqueta: Etiqueta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let grande = tamanho.isAccessibilitySize
        let layout = grande ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 10))
        layout {
            // O rótulo ocupa o que sobra pelo frame, e não um Spacer ao lado: com o Negrito, o Spacer arredondava para cima,
            // e o cabeçalho passava 1/3 pt da largura.
            RotuloDoBloco(texto: rotulo).frame(maxWidth: grande ? nil : .infinity, alignment: .leading)
            etiqueta
        }
        .padding(.bottom, 8)
    }
}

extension CabecalhoDoBloco where Etiqueta == EmptyView {
    init(rotulo: String) { self.init(rotulo: rotulo) { EmptyView() } }
}

enum CorDoSolido: Sendable { case verde, ambar }

/// O rótulo do bloco ("Total gasto", "Corrigido pelo banco"): subheadline semibold no secundário do vidro; no sólido,
/// negrito na tinta dele.
struct RotuloDoBloco: View {
    let texto: String
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.tintaDoBloco) private var tinta

    var body: some View {
        Text(texto)
            .font(.subheadline.weight(tinta == nil ? .semibold : .bold))
            .foregroundStyle(paleta.cor(tinta ?? vidro.secundario))
    }
}

/// A nota embaixo do número ("bruto, sem correção", "Correção até hoje: +R$ …"): subheadline no secundário do vidro, ou na
/// tinta do sólido.
struct NotaDoBloco: View {
    let texto: String
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.tintaDoBloco) private var tinta

    var body: some View {
        Text(texto)
            .font(.subheadline)
            .foregroundStyle(paleta.cor(tinta ?? vidro.secundario))
            .padding(.top, 2)
    }
}

/// A etiqueta dentro do sólido ("46 lançamentos", "Vendida em 20/06/26"): a tinta do bloco sobre ela mesma a 14%, nas
/// medidas da `EtiquetaDoIndicador` (footnote semibold, recuo de 10 × 3 e o raio de uma linha, que não come a quina do
/// texto quando ela quebra na letra grande).
struct EtiquetaDoSolido: View {
    let texto: String
    @Environment(\.paleta) private var paleta
    @Environment(\.tintaDoBloco) private var tinta
    @ScaledMetric(relativeTo: .footnote) private var linha: CGFloat = 16

    var body: some View {
        let cor = paleta.cor(tinta ?? .tintaSobreDestaque)
        Text(texto)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(cor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(cor.opacity(0.14), in: .rect(cornerRadius: (linha + 6) / 2))
    }
}

extension View {
    /// A placa atrás das marcas de gráfico: um tom chapado do fundo, sem desfoque (não é vidro), para as cores ficarem a 3:1
    /// com a aurora atrás. A forte (84% no escuro, 92% no claro) vai atrás da barra empilhada da obra; a outra (58% e 66%),
    /// atrás do anel e dos gráficos de mês.
    func placa(forte: Bool = false, raio: CGFloat = 12) -> some View { modifier(Placa(forte: forte, raio: raio)) }
}

private struct Placa: ViewModifier {
    let forte: Bool
    let raio: CGFloat
    @Environment(\.paleta) private var paleta

    func body(content: Content) -> some View {
        content.background(paleta.cor(forte ? .placaForte : .placa), in: .rect(cornerRadius: raio))
    }
}
```

Em `app-ios/Custta/Identidade/Paleta.swift`:

```diff
--- a/app-ios/Custta/Identidade/Paleta.swift
+++ b/app-ios/Custta/Identidade/Paleta.swift
@@ -117,6 +117,8 @@ enum Token: String, CaseIterable, Sendable {
     /// o aro na ponta de cada pedaço.
     case anelApagado = "AnelApagado"
     case anelSeparador = "AnelSeparador"
+    /// O filete de luz no topo do bloco sólido (o inset do mockup, branco a 35%).
+    case luzDoSolido = "LuzDoSolido"
 }
 
 struct Paleta: Equatable, Sendable {
```

Em `app-ios/Custta/Telas/ObrasView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObrasView.swift
+++ b/app-ios/Custta/Telas/ObrasView.swift
@@ -30,6 +30,8 @@ struct ObrasView: View {
     /// Laudo de leitura (Tarefa 11): a lista parada numa rolagem dada, em pt, para dois prints iguais.
     @AppStorage("custta.rolagem") private var rolagemFixa = -1.0
     @State private var posicao = ScrollPosition(edge: .top)
+    /// A vitrine das peças da identidade nova (etapa 4, PR 1b), empurrada com `CUSTTA_ABRIR=pecas`.
+    @State private var vitrine = ProcessInfo.processInfo.environment["CUSTTA_ABRIR"] == "pecas"
     #endif
 
     var body: some View {
@@ -95,6 +97,9 @@ struct ObrasView: View {
                 case .afazeres(let id): AfazeresView(obraId: id, caminho: $caminho)
                 }
             }
+            #if DEBUG
+            .navigationDestination(isPresented: $vitrine) { VitrineDasPecas() }
+            #endif
         }
     }
 }
```

Em `scripts/cores-app-ios.mjs`:

```diff
--- a/scripts/cores-app-ios.mjs
+++ b/scripts/cores-app-ios.mjs
@@ -128,6 +128,7 @@ export const CORES = {
     EixoGrafico: ['#EAFFF64D', '#142B2352'],        // 30% e 32%
     AnelApagado: ['#123128', '#DCEAE3'],            // o trilho e os pedaços apagados pelo toque: por cor, sem opacidade
     AnelSeparador: ['#04100C8C', '#FFFFFFBF'],      // o aro de 2,5 pt na ponta de cada pedaço (55% e 75%)
+    LuzDoSolido: ['#FFFFFF59', '#FFFFFF59'],        // o filete de luz no topo do bloco sólido (branco a 35%, nos dois temas)
   },
 };
 
```

Regerar:

```bash
node scripts/cores-app-ios.mjs
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | tail -8 | grep -E "ℹ (pass|fail)"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/BlocosTests -only-testing:CusttaTests/CoresTests 2>&1 | grep -E "Test run with"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/VitrineUITests 2>&1 | grep -E "error:|Executed [0-9]+ test" | tail -1
```
Expected: `ℹ pass 69`, `ℹ fail 0`; `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 11 tests in 2 suites passed`; `Executed 1 test, with 0 failures (0 unexpected)`.

- [ ] **Step 5: Conferir na vitrine**

Run:
```bash
U=$CUSTTA_SIMULADOR
SIMCTL_CHILD_CUSTTA_SERVICOS=falsos SIMCTL_CHILD_CUSTTA_CONTA=senha SIMCTL_CHILD_CUSTTA_DADOS=vitrine SIMCTL_CHILD_CUSTTA_ABRIR=pecas \
  xcrun simctl launch --terminate-running-process $U br.com.custta.app -custta.reduzirMovimento YES
sleep 6; xcrun simctl io $U screenshot /tmp/vitrine-1.png
```
Expected: a tela "Peças", empurrada sobre Obras: o sólido verde "Total gasto · 46 lançamentos" com R$ 842.317,45 e "bruto, sem correção" no texto escuro, o bloco de vidro "Corrigido pelo banco" (R$ 926.847,69, "Correção até hoje: +R$ 84.530,24"), o sólido âmbar e as duas placas; todos a 16 pt das bordas, o texto a 34. Nenhuma tela do app muda: o `CUSTTA_ABRIR=pecas` só existe no Debug.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Assets.xcassets/Esmeralda/LuzDoSolido.colorset/Contents.json app-ios/Custta/Falsos/VitrineDasPecas.swift app-ios/Custta/Identidade/Blocos.swift app-ios/Custta/Identidade/Paleta.swift app-ios/Custta/Telas/ObrasView.swift app-ios/CusttaTests/BlocosTests.swift app-ios/CusttaTests/CoresTests.swift app-ios/CusttaUITests/VitrineUITests.swift scripts/cores-app-ios.mjs
git commit -m "feat: grade 16/34, blocos de vidro e sólido e placa da identidade nova" -m "As peças de bloco da identidade nova da etapa 4 nascem sem tela, como o spec pede para o PR 1b: a grade de bordas (16 pt para toda forma, 34 para o texto dentro dela), o bloco de vidro de um assunto, o bloco sólido protagonista, verde ou âmbar, com a sombra na cor dele e o filete de luz no topo, o cabeçalho, o rótulo, a nota e a etiqueta de dentro dos blocos, que seguem a tinta do sólido, e a placa, o tom chapado sem desfoque atrás das marcas de gráfico. O filete ganha um token próprio, LuzDoSolido, branco a 35% nos dois temas. Nenhuma tela usa as peças até a obra do PR 1c: a vitrine, só no Debug e aberta com CUSTTA_ABRIR=pecas, as mostra sobre a aurora para os testes de tela e a conferência visual." -m "No cabeçalho do bloco, o rótulo ocupa o que sobra por um frame, e não por um Spacer ao lado: com o Negrito, o Spacer arredondava para cima, e o cabeçalho do sólido passava 1/3 pt da largura de dentro dele (372,333 nos 372 do Pro Max). A varredura nova prende isso nos três iPhones, com e sem o Negrito, em todo tamanho de letra."
```

### Task 20: Número mono com o R$ e os centavos menores e piso de 11 pt

O `ValorEmDinheiro` ganha a forma mono da identidade nova (spec, "O número que encolhe" e "Identidade", brief 2; `parte1.css:150-152`): o número em SF Mono 600 com o tracking de −0,035 em, o R$ a 58% do número e os centavos (com a vírgula) a 62%, os dois nunca abaixo de 11 pt (o `max(.58em, min(1em, 11px))` do mockup) e na mesma linha de base dos dígitos, nunca sobrescritos; o R$ com o respiro de 0,22 do tamanho dele. Um texto só, que encolhe para caber até o R$ chegar a 11 pt (`minimumScaleFactor` = 11 ÷ o tamanho do R$), no lugar da metade fixa de hoje (Componentes.swift:294); na linha (17 pt), o R$ já está em 11 e o número não encolhe, e quem não cabe ao lado do nome desce para baixo dele (a linha de lançamento, Tarefa 23). Os tamanhos são os do mockup na letra padrão e na máxima: o principal (o sólido) 40 e 56, o grande 30 e 48, o de bloco 22 e 40, o de linha 17 e 34 e o miúdo (o total do mês) 17 e 30. Entre a padrão e a máxima, o número cresce com o corpo do texto (o tamanho do `body`, de 17 a 53 pt), a cada passo da letra, como o texto do sistema: chega ao tamanho do mockup na máxima sem parar no caminho (um teto pelo `.dynamicTypeSize` pararia no AX2). O corpo vem da fonte (`UIFont.preferredFont(forTextStyle: .body)`), e não do `@ScaledMetric(relativeTo: .body)`, que para em 48 na máxima. O valor chega como o núcleo o escreve ("R$ 842.317,45", "−R$ 4.980,00"): o que vem antes do "R$" é o sinal, no tamanho do número; sem "R$" (o "—"), o texto vai inteiro no tamanho do número. Dentro do sólido, o número vem na tinta dele (`tintaDoBloco`, Tarefa 19), e o VoiceOver lê o texto do núcleo inteiro, num elemento só. Os 20 usos de hoje não mudam: a forma mono só existe com o tamanho dado, e nenhuma tela o dá até o PR 1c; o laudo inteiro do fim do PR confirma.

**Files:**
- Modify: `app-ios/Custta/Falsos/VitrineDasPecas.swift`
- Modify: `app-ios/Custta/Identidade/Componentes.swift`
- Create: `app-ios/Custta/Identidade/NumeroMono.swift`
- Test (novo): `app-ios/CusttaTests/NumeroMonoTests.swift`
- Test (alterar): `app-ios/CusttaUITests/VitrineUITests.swift`
- Test (alterar): `tests/app-ios.test.cjs`

**Interfaces:**
- Consumes: `ValorEmDinheiro(texto:fonte:cor:prefixo:)` (Componentes.swift); `EnvironmentValues.tintaDoBloco` (Tarefa 19); `moeda(_:)` (núcleo, nos testes).
- Produces: `TamanhoDoNumero` (`.principal`, `.grande`, `.bloco`, `.linha`, `.miudo`; `padrao`, `maximo` e `medidas(corpo:) -> MedidasDoNumero`); `MedidasDoNumero` (`numero`, `moeda`, `centavos`, `fatorMinimo`); `corpoDoTexto(_: DynamicTypeSize) -> CGFloat`; `PartesDoValor` e `partesDoValor(_:) -> PartesDoValor?`; `ValorEmDinheiro(_ texto: String, mono: TamanhoDoNumero, cor: Token = .texto)` e a propriedade `mono: TamanhoDoNumero?`.

- [ ] **Step 1: Escrever os testes**

Os testes de unidade prendem as medidas nas duas pontas, o crescimento a cada passo da letra com o R$ encolhido em 11 pt, o número na tela crescendo a cada passo (a largura natural do mesmo valor sobe a cada passo e, na máxima, é 56/40 da padrão: as medidas sozinhas não provam que a vista as usa, e a auditoria não pega o número parado), as partes do valor do núcleo, o maior valor (R$ 1.000.000.000,00) cabendo nos 307 pt do sólido na letra máxima num iPhone de 375 pt (spec: "teste de largura no maior valor") e, por pixel, o R$ e os centavos na linha de base do número, menores que ele. O de tela confere que o VoiceOver lê o valor inteiro e que o maior valor fica entre as bordas de 34 pt na letra máxima. A guarda Node do `ValorEmDinheiro` passa a conferir as duas formas.

Criar `app-ios/CusttaTests/NumeroMonoTests.swift`:

```swift
import Testing
import SwiftUI
import UIKit
@testable import Custta
import CusttaNucleo

/* O número mono da identidade nova (etapa 4, PR 1b; spec, "O número que encolhe"): os tamanhos do mockup na letra padrão e
   na máxima, crescendo a cada passo; o R$ e os centavos a 58% e 62% do número, nunca abaixo de 11 pt; o valor do núcleo
   partido; o maior valor, que cabe no sólido na letra máxima em 375 pt; e o R$ e os centavos na linha do número. */
@MainActor
struct NumeroMonoTests {
    @Test func medidasNaLetraPadraoENaMaxima() {
        let principal = TamanhoDoNumero.principal.medidas(corpo: 17)
        #expect(principal == MedidasDoNumero(numero: 40, moeda: 0.58 * 40, centavos: 0.62 * 40, fatorMinimo: 11 / (0.58 * 40)))
        let maxima = TamanhoDoNumero.principal.medidas(corpo: 53)
        #expect(maxima.numero == CGFloat(56) && maxima.fatorMinimo == 11 / (0.58 * CGFloat(56)))
        // Na linha, 58% do número fica abaixo de 11: o R$ e os centavos em 11, e o número não encolhe.
        #expect(TamanhoDoNumero.linha.medidas(corpo: 17) == MedidasDoNumero(numero: 17, moeda: 11, centavos: 11, fatorMinimo: 1))
        #expect(TamanhoDoNumero.allCases.map { $0.medidas(corpo: 17).numero } == [CGFloat(40), 30, 22, 17, 17])
        #expect(TamanhoDoNumero.allCases.map { $0.medidas(corpo: 53).numero } == [CGFloat(56), 48, 40, 34, 30])
    }

    /// Da menor letra à máxima, o número cresce a cada passo, como o texto do sistema, e chega ao tamanho do mockup na máxima;
    /// o R$ encolhido até o fator mínimo fica em 11 pt.
    @Test func cresceACadaPassoDaLetra() {
        let passos = DynamicTypeSize.allCases
        #expect(passos.count == 12 && corpoDoTexto(.large) == 17 && corpoDoTexto(.accessibility5) == 53)
        for tamanho in TamanhoDoNumero.allCases {
            let medidas = passos.map { tamanho.medidas(corpo: corpoDoTexto($0)) }
            #expect(zip(medidas, medidas.dropFirst()).allSatisfy { $0.numero < $1.numero }, "\(tamanho): \(medidas.map(\.numero))")
            #expect(abs(medidas[3].numero - tamanho.padrao) < 0.01 && abs(medidas[11].numero - tamanho.maximo) < 0.01, "\(tamanho): \(medidas.map(\.numero))")
            #expect(medidas.allSatisfy { $0.moeda * $0.fatorMinimo >= 11 - 1e-9 }, "\(tamanho): o R$ encolhido")
        }
    }

    @Test func partesDoValorDoNucleo() {
        #expect(partesDoValor(moeda(842_317.45)) == PartesDoValor(sinal: "", inteiro: "842.317", centavos: "45"))
        #expect(partesDoValor("−" + moeda(4_980)) == PartesDoValor(sinal: "−", inteiro: "4.980", centavos: "00"))
        #expect(partesDoValor(moeda(-5)) == PartesDoValor(sinal: "-", inteiro: "5", centavos: "00"))
        #expect(partesDoValor(moeda(.infinity)) == PartesDoValor(sinal: "", inteiro: "∞", centavos: nil))
        #expect(partesDoValor("—") == nil)
    }

    /// O maior valor (R$ 1.000.000.000,00) cabe nos 307 pt do sólido na letra máxima num iPhone de 375 pt (os 16 de borda e
    /// os 18 de recuo dos dois lados), sem chegar ao piso: encolhido, o R$ fica acima de 11 pt e o texto, numa linha.
    @Test func maiorValorCabeNoSolidoNaLetraMaximaEm375() {
        let valor = ValorEmDinheiro("R$\u{a0}1.000.000.000,00", mono: .principal).dynamicTypeSize(.accessibility5)
        let natural = UIHostingController(rootView: valor.fixedSize()).sizeThatFits(in: CGSize(width: 10_000, height: 10_000))
        let medidas = TamanhoDoNumero.principal.medidas(corpo: 53)
        let fator = 307 / natural.width
        #expect(fator < 1 && fator > medidas.fatorMinimo,
                "fator \(fator): o número em \(medidas.numero * fator) pt e o R$ em \(medidas.moeda * fator) pt")
        let em307 = UIHostingController(rootView: valor).sizeThatFits(in: CGSize(width: 307, height: 10_000))
        #expect(em307.width <= 307 && em307.height < natural.height, "\(em307) contra \(natural)")
    }

    /// Os pés e o alto de cada letra desenhada, da esquerda para a direita (colunas com tinta seguidas).
    private func letras(_ texto: String) throws -> [(topo: Int, base: Int)] {
        let r = ImageRenderer(content: ValorEmDinheiro(texto, mono: .principal)
            .environment(\.paleta, Paleta()).environment(\.colorScheme, .dark))
        r.scale = 2
        let imagem = try #require(r.cgImage)
        let (w, h) = (imagem.width, imagem.height)
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        rgba.withUnsafeMutableBytes { bytes in
            CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        let colunas = (0..<w).map { x in (0..<h).filter { rgba[($0 * w + x) * 4 + 3] > 128 } }
        var saida: [(topo: Int, base: Int)] = []
        var atual: (topo: Int, base: Int)?
        for coluna in colunas {
            if let topo = coluna.first, let base = coluna.last {
                atual = atual.map { (min($0.topo, topo), max($0.base, base)) } ?? (topo, base)
            } else if let a = atual {
                saida.append(a)
                atual = nil
            }
        }
        if let atual { saida.append(atual) }
        return saida
    }

    /// O R$ e os centavos na linha do número, nunca sobrescritos: o pé do "R", o dos "8" grandes e o dos "8" dos centavos na
    /// mesma linha de base, e o alto do "R" e dos centavos bem abaixo do alto dos dígitos (58% e 62% do tamanho).
    @Test func moedaECentavosNaLinhaDoNumero() throws {
        let l = try letras("R$\u{a0}88,88")
        try #require(l.count == 7, "R, $, 8, 8, a vírgula, 8 e 8: \(l)")
        let (rs, oito, centavo) = (l[0], l[2], l[5])
        let altura = oito.base - oito.topo
        #expect(abs(rs.base - oito.base) <= 1 && abs(centavo.base - oito.base) <= 1, "\(l)")
        #expect(rs.base - rs.topo < altura * 3 / 4 && centavo.base - centavo.topo < altura * 3 / 4, "\(l)")
    }

    /// Na tela, o número cresce a cada passo da letra e chega ao tamanho do mockup na máxima: a largura natural do mesmo
    /// valor sobe a cada passo, e na máxima é 56/40 da padrão. (As medidas acima não provam que a vista as usa.)
    @Test func numeroNaTelaCresceACadaPasso() {
        let larguras = DynamicTypeSize.allCases.map { letra in
            UIHostingController(rootView: ValorEmDinheiro("R$\u{a0}88,88", mono: .principal).dynamicTypeSize(letra).fixedSize())
                .sizeThatFits(in: CGSize(width: 10_000, height: 10_000)).width
        }
        #expect(zip(larguras, larguras.dropFirst()).allSatisfy { $0 < $1 }, "\(larguras)")
        #expect(abs(larguras[11] / larguras[3] - 56.0 / 40) < 0.03, "\(larguras)")
    }
}
```

Em `app-ios/CusttaUITests/VitrineUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/VitrineUITests.swift
+++ b/app-ios/CusttaUITests/VitrineUITests.swift
@@ -31,4 +31,16 @@ final class VitrineUITests: XCTestCase {
             app.terminate()
         }
     }
+
+    /// O número mono é um elemento só, que o VoiceOver lê inteiro, com o texto do núcleo; o maior valor, na letra máxima,
+    /// fica dentro do bloco, entre as bordas de 34 pt.
+    func testNumeroMonoLidoInteiroECabeNaLetraMaxima() {
+        let app = abrirVitrine(maiorLetra)
+        XCTAssertEqual(app.elemento("vitrine-total").label, "R$\u{a0}842.317,45")
+        let maior = app.elemento("vitrine-maiorValor")
+        app.rolarAte(maior)
+        XCTAssertEqual(maior.label, "R$\u{a0}1.000.000.000,00")
+        XCTAssertEqual(maior.frame.minX, 34, accuracy: 0.5)
+        XCTAssertLessThanOrEqual(maior.frame.maxX, app.frame.width - 34 + 0.5)
+    }
 }
```

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -494,10 +494,12 @@ test('texto cresce com a letra: lineLimit e minimumScaleFactor só no botão do
   // ValorEmDinheiro, que encolhe.
   for(const f of arquivosSwift('app-ios/Custta/Telas'))
     assert.doesNotMatch(ler(f), /Text\(moeda\(/, `${f}: dinheiro por extenso num Text; use o ValorEmDinheiro`);
-  // E o ValorEmDinheiro fica numa linha: sem o lineLimit, num iPhone de 375 pt o valor quebra antes de encolher.
+  // E o ValorEmDinheiro fica numa linha: sem o lineLimit, num iPhone de 375 pt o valor quebra antes de encolher. Na forma
+  // mono da identidade nova (etapa 4), encolhe até o R$ chegar a 11 pt; na de antes, até a metade.
   const componentes = ler('app-ios/Custta/Identidade/Componentes.swift');
-  assert.match(componentes.slice(componentes.indexOf('struct ValorEmDinheiro')), /^[^}]*\.lineLimit\(1\)\s*\.minimumScaleFactor\(0\.5\)/,
-               'o ValorEmDinheiro numa linha, encolhendo até a metade');
+  const inicio = componentes.indexOf('struct ValorEmDinheiro'), valor = componentes.slice(inicio, componentes.indexOf('\n}\n', inicio));
+  assert.match(valor, /\.lineLimit\(1\)\s*\.minimumScaleFactor\(0\.5\)/, 'o ValorEmDinheiro numa linha, encolhendo até a metade');
+  assert.match(valor, /\.lineLimit\(1\)\s*\.minimumScaleFactor\(medidas\.fatorMinimo\)/, 'o número mono numa linha, até o piso de 11 pt');
 });
 
 test('dica do fim do modo total: cresce com a letra e quebra linha, sem altura fixa', () => {
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | grep -m1 "✖ texto"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E '^/.*error:' | sed 's/^.*CusttaTests\//CusttaTests\//' | sort -t: -k2,2n -u | head -3
```
Expected: a guarda reprova `✖ texto cresce com a letra: lineLimit e minimumScaleFactor só no botão do Google, no indicador da barra e no dinheiro` (não há a forma mono); o `CusttaTests` não compila:
```
CusttaTests/NumeroMonoTests.swift:13:25: error: cannot find 'TamanhoDoNumero' in scope
CusttaTests/NumeroMonoTests.swift:14:30: error: cannot find 'MedidasDoNumero' in scope
CusttaTests/NumeroMonoTests.swift:15:22: error: cannot find 'TamanhoDoNumero' in scope
```

- [ ] **Step 3: Implementar**

O R$ é um `Text("R")` e um `Text("$")` com `kerning` (o respiro fica só depois do cifrão); tudo vai por interpolação de `Text`, que guarda a fonte, o tracking e o kerning de cada parte. A vitrine passa a mostrar o total e o corrigido em mono e um bloco "Números" com os tamanhos e o maior valor.

Em `app-ios/Custta/Falsos/VitrineDasPecas.swift`:

```diff
--- a/app-ios/Custta/Falsos/VitrineDasPecas.swift
+++ b/app-ios/Custta/Falsos/VitrineDasPecas.swift
@@ -16,14 +16,14 @@ struct VitrineDasPecas: View {
             VStack(alignment: .leading, spacing: Grade.entreBlocos) {
                 BlocoSolido {
                     CabecalhoDoBloco(rotulo: "Total gasto") { EtiquetaDoSolido(texto: indicadores.etiquetaDoTotal) }
-                    ValorEmDinheiro(texto: indicadores.totalGasto, fonte: .largeTitle.weight(.bold), cor: .tintaSobreDestaque)
+                    ValorEmDinheiro(indicadores.totalGasto, mono: .principal).accessibilityIdentifier("vitrine-total")
                     NotaDoBloco(texto: "bruto, sem correção")
                 }
                 .accessibilityElement(children: .contain)
                 .accessibilityIdentifier("vitrine-solido")
                 BlocoDeVidro {
                     CabecalhoDoBloco(rotulo: "Corrigido pelo banco")
-                    ValorEmDinheiro(texto: indicadores.corrigido, fonte: .title2.weight(.bold))
+                    ValorEmDinheiro(indicadores.corrigido, mono: .bloco)
                     NotaDoBloco(texto: indicadores.notaDoCorrigido)
                 }
                 .accessibilityElement(children: .contain)
@@ -34,6 +34,17 @@ struct VitrineDasPecas: View {
                 }
                 .accessibilityElement(children: .contain)
                 .accessibilityIdentifier("vitrine-ambar")
+                BlocoDeVidro {
+                    CabecalhoDoBloco(rotulo: "Números")
+                    VStack(alignment: .leading, spacing: 6) {
+                        ValorEmDinheiro("R$\u{a0}1.000.000.000,00", mono: .principal).accessibilityIdentifier("vitrine-maiorValor")
+                        ValorEmDinheiro(indicadores.aPagar, mono: .bloco)
+                        ValorEmDinheiro("−R$\u{a0}4.980,00", mono: .linha)
+                        ValorEmDinheiro("R$\u{a0}72.300,00", mono: .miudo)
+                    }
+                }
+                .accessibilityElement(children: .contain)
+                .accessibilityIdentifier("vitrine-numeros")
                 BlocoDeVidro {
                     CabecalhoDoBloco(rotulo: "Placa e placa forte")
                     Color.clear.frame(height: 16).padding(8).placa().accessibilityIdentifier("vitrine-placa")
```

Em `app-ios/Custta/Identidade/Componentes.swift`:

```diff
--- a/app-ios/Custta/Identidade/Componentes.swift
+++ b/app-ios/Custta/Identidade/Componentes.swift
@@ -280,18 +280,30 @@ struct EtiquetaDeFase: View {
 /// duas linhas se lê errado. Os outros textos crescem e quebram. Algarismos tabulares, na cor do texto ou na que o
 /// lugar pede (o total do mês vai no secundário do cabeçalho). Com `prefixo`, o "R$" das linhas da folha vem no mesmo
 /// texto, menor e no secundário: encolhe junto com o número (em dois textos, na letra máxima só o número encolhia e o
-/// "R$" ficava maior que ele).
+/// "R$" ficava maior que ele). Com `mono`, a forma da identidade nova (NumeroMono.swift): encolhe até o R$ chegar a 11 pt.
 struct ValorEmDinheiro: View {
     let texto: String
     let fonte: Font
     var cor: Token = .texto
     var prefixo: Font?
+    var mono: TamanhoDoNumero?
     @Environment(\.paleta) private var paleta
+    @Environment(\.tintaDoBloco) private var tinta
+    @Environment(\.dynamicTypeSize) private var tamanhoDaLetra
 
     var body: some View {
-        conteudo
-            .lineLimit(1)
-            .minimumScaleFactor(0.5)
+        if let mono {
+            let medidas = mono.medidas(corpo: corpoDoTexto(tamanhoDaLetra))
+            // O VoiceOver lê o valor inteiro do núcleo ("R$ 842.317,45"), num elemento só.
+            textoMono(medidas, cor: paleta.cor(tinta ?? cor))
+                .lineLimit(1)
+                .minimumScaleFactor(medidas.fatorMinimo)
+                .accessibilityLabel(texto)
+        } else {
+            conteudo
+                .lineLimit(1)
+                .minimumScaleFactor(0.5)
+        }
     }
 
     private var conteudo: Text {
```

Criar `app-ios/Custta/Identidade/NumeroMono.swift`:

```swift
import SwiftUI

/* O número da identidade nova (etapa 4, brief 2): SF Mono 600, com o R$ e os centavos menores na linha do número, nunca
   sobrescritos e nunca abaixo de 11 pt (parte1.css:150-152). É a forma mono do `ValorEmDinheiro` (spec, "O número que
   encolhe"): um texto só, que encolhe para caber até o R$ chegar a 11 pt, no lugar da metade fixa da forma de antes. */

/// Os tamanhos do número mono, na letra padrão e na máxima (AX5), do mockup (--n-gig, --n-gr, --n-med, --n-pq e --n-ax).
/// Entre os dois, ele cresce com o corpo do texto, a cada passo da letra, como o texto do sistema: chega ao tamanho do
/// mockup na máxima sem parar no caminho.
enum TamanhoDoNumero: Sendable, CaseIterable {
    /// O número do sólido: 40 pt; 56 na letra máxima.
    case principal
    /// 30 e 48.
    case grande
    /// O número de um bloco de vidro: 22 e 40.
    case bloco
    /// O valor de uma linha (um lançamento, uma lista): 17 e 34.
    case linha
    /// O total do mês e os números miúdos: 17 e 30.
    case miudo

    var padrao: CGFloat {
        switch self {
        case .principal: 40
        case .grande: 30
        case .bloco: 22
        case .linha, .miudo: 17
        }
    }

    var maximo: CGFloat {
        switch self {
        case .principal: 56
        case .grande: 48
        case .bloco: 40
        case .linha: 34
        case .miudo: 30
        }
    }

    /// As medidas no corpo de texto dado (o `body` do Dynamic Type: 17 pt na letra padrão, 53 na máxima).
    func medidas(corpo: CGFloat) -> MedidasDoNumero {
        let numero = padrao + (maximo - padrao) * (corpo - 17) / (53 - 17)
        // O `max(.58em, min(1em, 11px))` do mockup: 58% do número, mas nunca abaixo de 11 pt (salvo número menor que isso).
        let menor = { (fracao: CGFloat) in max(fracao * numero, min(numero, 11)) }
        let moeda = menor(0.58)
        return MedidasDoNumero(numero: numero, moeda: moeda, centavos: menor(0.62), fatorMinimo: min(1, 11 / moeda))
    }
}

/// O número, o R$ e os centavos em pontos, e o quanto o texto pode encolher para caber: até o R$, o menor dos três, chegar
/// a 11 pt. Na linha (17 pt), o R$ já está em 11, e o número não encolhe.
struct MedidasDoNumero: Equatable, Sendable {
    let numero: CGFloat
    let moeda: CGFloat
    let centavos: CGFloat
    let fatorMinimo: CGFloat
}

/// O valor partido para o número mono: o que vem antes do "R$" (o "−" do gasto, o "+" do lucro), os dígitos e os centavos,
/// sem a vírgula.
struct PartesDoValor: Equatable, Sendable {
    let sinal: String
    let inteiro: String
    let centavos: String?
}

/// O corpo do texto (o `body`) no tamanho de letra dado: 17 pt na letra padrão, 53 na máxima. É o tamanho da fonte, e não
/// o `@ScaledMetric(relativeTo: .body)`, que para em 48 na máxima.
func corpoDoTexto(_ tamanho: DynamicTypeSize) -> CGFloat {
    UIFont.preferredFont(forTextStyle: .body, compatibleWith: UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(tamanho)))
        .pointSize
}

/// As partes de um valor do núcleo ("R$ 842.317,45", "−R$ 4.980,00"); nil sem "R$" (o "—" da venda sem estimativa).
func partesDoValor(_ texto: String) -> PartesDoValor? {
    guard let rs = texto.range(of: "R$") else { return nil }
    let resto = texto[rs.upperBound...].trimmingCharacters(in: .whitespaces)
    guard let virgula = resto.lastIndex(of: ",") else {
        return PartesDoValor(sinal: String(texto[..<rs.lowerBound]), inteiro: resto, centavos: nil)
    }
    return PartesDoValor(sinal: String(texto[..<rs.lowerBound]), inteiro: String(resto[..<virgula]),
                         centavos: String(resto[resto.index(after: virgula)...]))
}

extension ValorEmDinheiro {
    /// O número mono da identidade nova, no tamanho dado. Dentro do sólido, na tinta dele.
    init(_ texto: String, mono tamanho: TamanhoDoNumero, cor: Token = .texto) {
        self.init(texto: texto, fonte: .body, cor: cor, mono: tamanho)
    }

    /// O sinal e os dígitos no tamanho do número, com o tracking de −0,035 do mockup; o R$ e os centavos menores, na mesma
    /// linha de base, e o R$ com o respiro de 0,22 do tamanho dele antes dos dígitos.
    func textoMono(_ medidas: MedidasDoNumero, cor: Color) -> Text {
        let fonte = { (tamanho: CGFloat) in Font.system(size: tamanho, weight: .semibold, design: .monospaced) }
        guard let partes = partesDoValor(texto) else {
            return Text(texto).font(fonte(medidas.numero)).tracking(-0.035 * medidas.numero).foregroundStyle(cor)
        }
        let sinal = Text(partes.sinal).font(fonte(medidas.numero))
        let moeda = Text("\(Text("R"))\(Text("$").kerning(0.22 * medidas.moeda))").font(fonte(medidas.moeda))
        let digitos = Text(partes.inteiro).font(fonte(medidas.numero)).tracking(-0.035 * medidas.numero)
        let centavos = Text(partes.centavos.map { ",\($0)" } ?? "").font(fonte(medidas.centavos))
        return Text("\(sinal)\(moeda)\(digitos)\(centavos)").foregroundStyle(cor)
    }
}
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | tail -8 | grep -E "ℹ (pass|fail)"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/NumeroMonoTests 2>&1 | grep -E "Test run with"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/VitrineUITests 2>&1 | grep -E "error:|Executed [0-9]+ test" | tail -1
```
Expected: `ℹ pass 69`, `ℹ fail 0`; `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 6 tests in 1 suite passed`; `Executed 2 tests, with 0 failures (0 unexpected)`.

- [ ] **Step 5: Conferir na vitrine**

Run: o mesmo do Step 5 da Tarefa 19.
Expected: o total "R$ 842.317,45" do sólido em mono, o R$ e o ",45" menores na linha do número, como o `parte1-obra-topo.png` do mockup; o corrigido no tamanho de bloco; no bloco "Números", o maior valor numa linha, o "−R$ 4.980,00" da linha (o R$ em 11 pt) e o total do mês.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Falsos/VitrineDasPecas.swift app-ios/Custta/Identidade/Componentes.swift app-ios/Custta/Identidade/NumeroMono.swift app-ios/CusttaTests/NumeroMonoTests.swift app-ios/CusttaUITests/VitrineUITests.swift tests/app-ios.test.cjs
git commit -m "feat: número mono com o R\$ e os centavos menores e piso de 11 pt" -m "O ValorEmDinheiro ganha a forma mono da identidade nova (spec, \"O número que encolhe\"): o número em SF Mono 600, com o R\$ e os centavos menores na linha do número (58% e 62% dele, nunca abaixo de 11 pt), num texto só, que encolhe para caber até o R\$ chegar a 11 pt, no lugar da metade fixa da forma de antes. Os cinco tamanhos do mockup (40, 30, 22 e duas vezes 17 pt, e 56, 48, 40, 34 e 30 na letra máxima) crescem com o corpo do texto a cada passo da letra, sem parar no caminho. Dentro do sólido, o número vem na tinta dele, e o VoiceOver lê o valor inteiro do núcleo. Os 20 usos de hoje não mudam: a forma mono só existe com o tamanho dado, e nenhuma tela o dá até o PR 1c."
```

### Task 21: Título em SF Mono e cápsula de metadados

O título solto da identidade nova (spec, "Identidade", ajuste 1, opção C; `parte1.css:365-366`): SF Mono 600, 30 pt com o tracking de −0,045 em, 44 na letra máxima, em quantas linhas precisar (o nome comprido quebra), a 16 pt da borda. O título pequeno da barra: 16 pt, 20 na letra máxima (vale 20, não os 22 da linha "Letra máxima" das medidas: spec, "Mockup aprovado"), numa linha só, até 236 pt, com o Visualizador de Conteúdo Grande e o identificador `tituloPequenoDaBarra`, como o `TituloPequenoDaBarra` da obra de hoje (ObraView.swift:375), que fica. O pequeno recebe a letra da tela (`TituloPequenoMono(texto:letra:)`), lida fora da barra, como o `PassoDaFolha` faz com o `letraGrande`: dentro do `ToolbarItem`, o `dynamicTypeSize` para antes da letra de acessibilidade (memória `pecas-da-folha-na-letra-grande`), e, com a letra lida ali, o título ficava em ~16,5 pt na máxima, no lugar dos 20. Os dois crescem com o corpo do texto a cada passo da letra, como o número (Tarefa 20): a regra sai do `TamanhoDoNumero` para o `crescendoComALetra(de:ate:corpo:)`. Atrás do título, no escuro, o halo do nome da obra de hoje (`HaloDoTitulo.naObra`, 30%, e 10% no claro; Aurora.swift:192-195): o do mockup (`HaloTitulo`, 38% e 62% na letra máxima) é o ponto de partida da calibração pelo laudo (spec, "Deste spec"), que vai com o título na obra (PR 1c). A cápsula de metadados (ajuste 2; `parte1.css:147-149`): o vidro do conteúdo que abraça o que leva (até a largura toda), a 16 pt da borda, com o texto a 34; uma coluna com 6 pt entre as linhas (8 na letra de acessibilidade), em subheadline no secundário do vidro, cantos de 22 pt e recuo de 10 × 18 × 12 (30 e 16 × 18 × 18 na letra de acessibilidade). O raio é o de uma linha, não o da cápsula da altura toda, para a quina não comer o texto quando ele quebra (memória `capsula-em-texto-que-quebra`). Na obra de hoje, o nome é SF Pro em `largeTitle` (PecasDaObra.swift:19) e a pílula da fase tem raio 24, o texto a 38 pt (PecasDaObra.swift:31-51, raio na 46). Na vitrine, o título e a cápsula vão no alto, como a obra do mockup, e o título pequeno fica na barra.

**Files:**
- Modify: `app-ios/Custta/Falsos/VitrineDasPecas.swift`
- Modify: `app-ios/Custta/Identidade/NumeroMono.swift`
- Create: `app-ios/Custta/Identidade/Titulos.swift`
- Test (novo): `app-ios/CusttaTests/TitulosTests.swift`
- Test (alterar): `app-ios/CusttaUITests/VitrineUITests.swift`
- Test (alterar): `tests/app-ios.test.cjs`

**Interfaces:**
- Consumes: `corpoDoTexto(_:)` (Tarefa 20); `HaloDoTitulo` (Aurora.swift); `Grade.recuo` e `.superficie(_:em:)`; `EtiquetaDeFase` e `textoDoInicio(_:hoje:)` (só na vitrine).
- Produces: `crescendoComALetra(de:ate:corpo:) -> CGFloat`; `TituloMono(texto:identificador:)` (identificador padrão `tituloDaObra`); `TituloPequenoMono(texto:letra:)` (a `letra: DynamicTypeSize` é a da tela, lida fora da barra); `CapsulaDeMetadados { … }`.

- [ ] **Step 1: Escrever os testes**

Os testes de unidade medem no layout que o título e o pequeno da barra são do SF Mono (a mesma largura para "i" e "M") e têm a altura de uma linha dele no tamanho do mockup, nas duas pontas da letra; que o nome comprido quebra o título e não o pequeno; e que a cápsula abraça o conteúdo com o recuo do mockup. O de tela confere a grade na vitrine: o título e a cápsula a 16 pt, a fase e o "começou em …" a 34; e o título pequeno dentro da barra, mais de 1,2 vez mais alto na letra máxima que na padrão (o teste de unidade mede a peça solta, fora da barra, e não veria a letra parada; a guarda mede a altura, e não a largura, porque o `.frame(maxWidth: 236)` pode dar ao elemento a largura do quadro). O `TituloPequenoMono` entra na lista fixa da guarda Node do `lineLimit`.

Criar `app-ios/CusttaTests/TitulosTests.swift`:

```swift
import Testing
import SwiftUI
import UIKit
@testable import Custta

/* O título e a cápsula de metadados da identidade nova (etapa 4, PR 1b; ajustes 1 e 2 do mockup): o título em SF Mono 600 de
   30 pt (44 na letra máxima), que quebra o nome comprido, o pequeno da barra de 16 pt (20), numa linha só, e a cápsula que
   abraça o conteúdo com o recuo do mockup. Medidos no layout, num UIHostingController em escala 1. */
@MainActor
struct TitulosTests {
    private func medida<V: View>(_ vista: V, _ letra: DynamicTypeSize = .large, largura: CGFloat = 10_000) -> CGSize {
        UIHostingController(rootView: vista.dynamicTypeSize(letra).environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: largura, height: 10_000))
    }

    /// Uma linha do SF Mono semibold no tamanho dado.
    private func linha(_ tamanho: CGFloat) -> CGFloat { UIFont.monospacedSystemFont(ofSize: tamanho, weight: .semibold).lineHeight }

    /// O título e o pequeno da barra são do SF Mono (a mesma largura para "i" e "M") e têm a altura de uma linha dele no
    /// tamanho do mockup, na letra padrão e na máxima.
    @Test func tituloEPequenoDaBarraNoMonoNosTamanhosDoMockup() {
        let estreito = medida(TituloMono(texto: "iiiiiiii").fixedSize()), largo = medida(TituloMono(texto: "MMMMMMMM").fixedSize())
        #expect(abs(estreito.width - largo.width) < 0.5, "\(estreito.width) contra \(largo.width)")
        for (letra, grande, pequeno) in [(DynamicTypeSize.large, CGFloat(30), CGFloat(16)), (.accessibility5, 44, 20)] {
            #expect(abs(medida(TituloMono(texto: "Casa"), letra).height - linha(grande)) < 1, "\(letra)")
            #expect(abs(medida(TituloPequenoMono(texto: "Casa", letra: letra), letra).height - linha(pequeno)) < 1, "\(letra)")
        }
    }

    /// O nome comprido quebra o título (o mockup: "nome comprido quebra em duas linhas"); o pequeno da barra fica numa linha.
    @Test func nomeCompridoQuebraOTituloENaoOPequenoDaBarra() {
        let nome = "Residencial Jardim das Palmeiras, bloco B"
        #expect(medida(TituloMono(texto: nome), largura: 370).height > 1.8 * linha(30))
        #expect(abs(medida(TituloPequenoMono(texto: nome, letra: .large), largura: 236).height - linha(16)) < 1)
    }

    /// A cápsula abraça o conteúdo, com o recuo de 18 dos lados e 10 + 12 em cima e embaixo (16 + 18 na letra de
    /// acessibilidade).
    @Test func capsulaAbracaOConteudoComORecuo() {
        let conteudo = Color.clear.frame(width: 100, height: 20)
        #expect(medida(CapsulaDeMetadados { conteudo }) == CGSize(width: 136, height: 42))
        #expect(medida(CapsulaDeMetadados { conteudo }, .accessibility1) == CGSize(width: 136, height: 54))
    }
}
```

Em `app-ios/CusttaUITests/VitrineUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/VitrineUITests.swift
+++ b/app-ios/CusttaUITests/VitrineUITests.swift
@@ -32,6 +32,27 @@ final class VitrineUITests: XCTestCase {
         }
     }
 
+    /// O título solto a 16 pt da borda; a cápsula de metadados a 16 e o texto dela (a fase e "começou em …") a 34 (ajuste 2
+    /// do mockup), na letra padrão e na máxima; o título pequeno da barra no nome da obra, maior na letra máxima.
+    func testTituloECapsulaDeMetadadosNaGrade() {
+        var alturas: [CGFloat] = []
+        for argumentos in [[], maiorLetra] {
+            let app = abrirVitrine(argumentos)
+            XCTAssertEqual(app.elemento("vitrine-titulo").frame.minX, 16, accuracy: 0.5, "\(argumentos)")
+            let capsula = app.elemento("vitrine-metadados")
+            XCTAssertEqual(capsula.frame.minX, 16, accuracy: 0.5, "\(argumentos)")
+            // A etiqueta da fase começa a 34; o texto dela, 12 pt para dentro (EtiquetaDeFase).
+            XCTAssertEqual(capsula.staticTexts["Em construção"].frame.minX, 34 + 12, accuracy: 0.5, "\(argumentos)")
+            let inicio = capsula.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'começou em'")).firstMatch
+            XCTAssertEqual(inicio.frame.minX, 34, accuracy: 0.5, "\(argumentos)")
+            XCTAssertEqual(app.elemento("tituloPequenoDaBarra").label, "Casa Alphaville")
+            alturas.append(app.elemento("tituloPequenoDaBarra").frame.height)
+            app.terminate()
+        }
+        // O título da barra lê a letra de fora dela: de 16 pt na padrão a 20 na máxima.
+        XCTAssertGreaterThan(alturas[1] / alturas[0], 1.2, "\(alturas)")
+    }
+
     /// O número mono é um elemento só, que o VoiceOver lê inteiro, com o texto do núcleo; o maior valor, na letra máxima,
     /// fica dentro do bloco, entre as bordas de 34 pt.
     func testNumeroMonoLidoInteiroECabeNaLetraMaxima() {
```

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -478,11 +478,11 @@ test('texto cresce com a letra: lineLimit e minimumScaleFactor só no botão do
   // obra): com o nome da obra preso numa linha, ela passa na maior letra. Ficam numa linha, por decisão, o botão
   // do Google (letra travada, fora da auditoria de tipo dinâmico), o indicador de sincronização da barra, o
   // dinheiro (ValorEmDinheiro e o visor do teclado de valor, mockup da etapa 2: encolhe para caber em vez de quebrar)
-  // e os títulos da barra, o pequeno da obra e o da folha, e o nome da linha na barra das teclas encaixadas (cortam como o do
+  // e os títulos da barra, o pequeno da obra (também o mono da etapa 4) e o da folha, e o nome da linha na barra das teclas encaixadas (cortam como o do
   // sistema, em vez de empurrar os botões). Na etapa 3, o primeiro pendente na linha dos afazeres da obra para em duas
   // linhas (quatro na maior letra), como no mockup: o texto inteiro está na tela Afazeres, e o VoiceOver o lê inteiro pela linha.
   const fixos = new Set(['BotaoGoogle', 'IndicadorDeSincronizacao', 'ValorEmDinheiro', 'VisorDoValor', 'TituloPequenoDaBarra',
-    'TituloDaFolha', 'BarraDasTeclas', 'PrimeiroPendente']);
+    'TituloPequenoMono', 'TituloDaFolha', 'BarraDasTeclas', 'PrimeiroPendente']);
   for(const f of arquivosSwift('app-ios/Custta')){
     const t = ler(f);
     for(const m of t.matchAll(/\.(lineLimit|minimumScaleFactor)\(/g)){
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E '^/.*error: cannot find' | sed 's/^.*CusttaTests\//CusttaTests\//' | sort -t: -k2,2n -u | head -3
```
Expected: o `CusttaTests` não compila:
```
CusttaTests/TitulosTests.swift:22:31: error: cannot find 'TituloMono' in scope
CusttaTests/TitulosTests.swift:25:32: error: cannot find 'TituloMono' in scope
CusttaTests/TitulosTests.swift:26:32: error: cannot find 'TituloPequenoMono' in scope
```

- [ ] **Step 3: Implementar**

O identificador vem antes do halo, como no `TituloDaObra`: com ele depois, o quadro do VoiceOver iria até a borda do halo. A vitrine lê a letra no `@Environment(\.dynamicTypeSize)` dela, fora da barra, e a passa ao título pequeno.

Em `app-ios/Custta/Falsos/VitrineDasPecas.swift`:

```diff
--- a/app-ios/Custta/Falsos/VitrineDasPecas.swift
+++ b/app-ios/Custta/Falsos/VitrineDasPecas.swift
@@ -7,6 +7,7 @@ import CusttaNucleo
    números da Casa Alphaville da vitrine (os do mockup). `CUSTTA_ABRIR=pecas` a empurra em Obras. */
 struct VitrineDasPecas: View {
     private let estado = Estado.de(DadosDeExemplo.vitrine())
+    @Environment(\.dynamicTypeSize) private var letra
 
     var body: some View {
         let casa = estado.obras[0]
@@ -14,6 +15,14 @@ struct VitrineDasPecas: View {
         let indicadores = indicadoresDaObra(casa, taxa: estado.config.taxaMensal, hoje: hoje)
         ScrollView {
             VStack(alignment: .leading, spacing: Grade.entreBlocos) {
+                TituloMono(texto: casa.nome, identificador: "vitrine-titulo")
+                CapsulaDeMetadados {
+                    EtiquetaDeFase(fase: casa.fase, grande: true)
+                    Text(textoDoInicio(casa, hoje: hoje))
+                }
+                .accessibilityElement(children: .contain)
+                .accessibilityIdentifier("vitrine-metadados")
+                .padding(.bottom, 4)
                 BlocoSolido {
                     CabecalhoDoBloco(rotulo: "Total gasto") { EtiquetaDoSolido(texto: indicadores.etiquetaDoTotal) }
                     ValorEmDinheiro(indicadores.totalGasto, mono: .principal).accessibilityIdentifier("vitrine-total")
@@ -59,6 +68,7 @@ struct VitrineDasPecas: View {
         .containerBackground(.clear, for: .navigation)
         .navigationTitle("Peças")
         .navigationBarTitleDisplayMode(.inline)
+        .toolbar { ToolbarItem(placement: .principal) { TituloPequenoMono(texto: casa.nome, letra: letra) } }
     }
 }
 #endif
```

Em `app-ios/Custta/Identidade/NumeroMono.swift`:

```diff
--- a/app-ios/Custta/Identidade/NumeroMono.swift
+++ b/app-ios/Custta/Identidade/NumeroMono.swift
@@ -40,7 +40,7 @@ enum TamanhoDoNumero: Sendable, CaseIterable {
 
     /// As medidas no corpo de texto dado (o `body` do Dynamic Type: 17 pt na letra padrão, 53 na máxima).
     func medidas(corpo: CGFloat) -> MedidasDoNumero {
-        let numero = padrao + (maximo - padrao) * (corpo - 17) / (53 - 17)
+        let numero = crescendoComALetra(de: padrao, ate: maximo, corpo: corpo)
         // O `max(.58em, min(1em, 11px))` do mockup: 58% do número, mas nunca abaixo de 11 pt (salvo número menor que isso).
         let menor = { (fracao: CGFloat) in max(fracao * numero, min(numero, 11)) }
         let moeda = menor(0.58)
@@ -72,6 +72,11 @@ func corpoDoTexto(_ tamanho: DynamicTypeSize) -> CGFloat {
         .pointSize
 }
 
+/// Um tamanho do mockup que vai do da letra padrão ao da máxima junto com o corpo do texto (de 17 a 53 pt), a cada passo.
+func crescendoComALetra(de padrao: CGFloat, ate maximo: CGFloat, corpo: CGFloat) -> CGFloat {
+    padrao + (maximo - padrao) * (corpo - 17) / (53 - 17)
+}
+
 /// As partes de um valor do núcleo ("R$ 842.317,45", "−R$ 4.980,00"); nil sem "R$" (o "—" da venda sem estimativa).
 func partesDoValor(_ texto: String) -> PartesDoValor? {
     guard let rs = texto.range(of: "R$") else { return nil }
```

Criar `app-ios/Custta/Identidade/Titulos.swift`:

```swift
import SwiftUI

/* O título e a cápsula de metadados da identidade nova (etapa 4; ajustes 1 e 2 do mockup aprovado, parte1.css:143-149 e
   :365-366): o título solto em SF Mono 600 e o pequeno da barra, e a cápsula de vidro com o que fica embaixo do título (a
   fase e "começou em … · N meses" na obra, o nome da obra nas telas da análise). Nenhuma tela os usa ainda. */

/// O título solto: SF Mono 600, 30 pt com o tracking de −0,045 em (44 na letra máxima, crescendo a cada passo), em quantas
/// linhas precisar (o nome comprido quebra), a 16 pt da borda. Atrás dele, no escuro, o halo do nome da obra de hoje (30%,
/// e 10% no claro): o do mockup (38%, 62% na letra máxima) se calibra pelo laudo, na obra (PR 1c).
struct TituloMono: View {
    let texto: String
    var identificador = "tituloDaObra"
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        let tamanho = crescendoComALetra(de: 30, ate: 44, corpo: corpoDoTexto(letra))
        Text(texto)
            .font(.system(size: tamanho, weight: .semibold, design: .monospaced))
            .tracking(-0.045 * tamanho)
            .foregroundStyle(paleta.cor(.texto))
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier(identificador)    // antes do halo: com ele, o quadro do VoiceOver ia até a borda do halo
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { HaloDoTitulo(grande: false, opacidade: HaloDoTitulo.naObra, noClaro: HaloDoTitulo.naObraNoClaro) }
    }
}

/// O título pequeno da barra no mono: 16 pt (20 na letra máxima, crescendo a cada passo), numa linha só, até 236 pt, como
/// o `TituloPequenoDaBarra` da obra de hoje, com o Visualizador de Conteúdo Grande.
struct TituloPequenoMono: View {
    let texto: String
    @Environment(\.paleta) private var paleta
    /// A letra da tela, lida fora da barra: dentro do ToolbarItem, o dynamicTypeSize para antes da letra de acessibilidade.
    let letra: DynamicTypeSize

    var body: some View {
        let tamanho = crescendoComALetra(de: 16, ate: 20, corpo: corpoDoTexto(letra))
        Text(texto)
            .font(.system(size: tamanho, weight: .semibold, design: .monospaced))
            .tracking(-0.02 * tamanho)
            .foregroundStyle(paleta.cor(.texto))
            .lineLimit(1)
            .frame(maxWidth: 236)
            .accessibilityAddTraits(.isHeader)
            .accessibilityShowsLargeContentViewer()
            .accessibilityIdentifier("tituloPequenoDaBarra")
    }
}

/// A cápsula de metadados embaixo do título: o vidro do conteúdo, que abraça o que leva (até a largura toda), a 16 pt da
/// borda e com o texto a 34; uma coluna com 6 pt entre as linhas, em subheadline no secundário do vidro. Cantos de 22 pt e
/// recuo de 10 × 18 × 12, que passam a 30 e 16 × 18 × 18 na letra de acessibilidade (8 pt entre as linhas): o raio de uma
/// linha, e não a cápsula da altura toda, para a quina não comer o texto quando ele quebra.
struct CapsulaDeMetadados<Conteudo: View>: View {
    @ViewBuilder let conteudo: Conteudo
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        let grande = letra.isAccessibilitySize
        VStack(alignment: .leading, spacing: grande ? 8 : 6) { conteudo }
            .font(.subheadline)
            .foregroundStyle(paleta.cor(vidro.secundario))
            .padding(EdgeInsets(top: grande ? 16 : 10, leading: Grade.recuo, bottom: grande ? 18 : 12, trailing: Grade.recuo))
            .superficie(.conteudo, em: .rect(cornerRadius: grande ? 30 : 22))
    }
}
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | tail -8 | grep -E "ℹ (pass|fail)"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/TitulosTests -only-testing:CusttaTests/NumeroMonoTests 2>&1 | grep -E "Test run with"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/VitrineUITests 2>&1 | grep -E "error:|Executed [0-9]+ test" | tail -1
```
Expected: `ℹ pass 69`, `ℹ fail 0`; `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 9 tests in 2 suites passed`; `Executed 3 tests, with 0 failures (0 unexpected)`.

- [ ] **Step 5: Conferir na vitrine**

Run: o mesmo do Step 5 da Tarefa 19.
Expected: "Casa Alphaville" em SF Mono no alto e na barra; embaixo, a cápsula com "Em construção" e "começou em … · 14 meses" a 34 pt, como o `parte1-obra-topo.png` do mockup (a data muda com o dia: a vitrine conta as datas de hoje).

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Falsos/VitrineDasPecas.swift app-ios/Custta/Identidade/NumeroMono.swift app-ios/Custta/Identidade/Titulos.swift app-ios/CusttaTests/TitulosTests.swift app-ios/CusttaUITests/VitrineUITests.swift tests/app-ios.test.cjs
git commit -m "feat: título em SF Mono e cápsula de metadados da identidade nova" -m "O título solto da identidade nova vem em SF Mono 600, de 30 pt com o tracking do mockup a 44 na letra máxima, crescendo a cada passo, e quebra o nome comprido em quantas linhas precisar; o pequeno da barra, de 16 a 20 pt, fica numa linha só, como o da obra de hoje. Atrás do título, o halo do nome da obra continua o de hoje: a calibração do mockup vai com a obra, pelo laudo. A cápsula de metadados é o vidro que abraça o que fica embaixo do título, com o texto a 34 pt e o raio de uma linha, que não come a quina quando o texto quebra. Nenhuma tela os usa até o PR 1c; a vitrine os mostra no alto, como a obra do mockup."
```

### Task 22: Barra empilhada de tópicos e hachura

A barra empilhada que o Giovani pediu em 29/10 no lugar do mini-anel da obra (spec, "Tela da obra", a barra empilhada; LEIA-ME, "Mudanças de 29/10"; `parte1.css:206-216`), sem tela e sem toque (a porta para os Gráficos chega no PR 2b), desenhada em `Shape`, sem Swift Charts. Os pedaços e as larguras vêm do núcleo (Tarefa 9, `Pedacos.swift`): `pedacosDoAnel` sobre o `gastoPorTopico` (os 6 maiores tópicos comuns, um por cor, e no fim o cinza: o tópico que sobra sozinho ou o "Outros", que junta o resto; o tópico fixo "Outros" vai sempre para o cinza), nas cores `Grafico1` a `Grafico6` e `GraficoOutros`, e `largurasDaBarra` (proporcionais, com o vão de 3 pt e o piso de 8 pt tirado do maior). Cada pedaço é uma cápsula de 16 pt de altura (raio de 8). Na letra de acessibilidade, a barra tem 26 pt, o vão 4 e o piso 12 (`parte1.css:209-210`; o mockup só desenha a AX5, e da AX1 em diante valem os da AX5). A barra vai sobre a placa forte, com 8 pt de recuo e cantos de 12, para as cores ficarem a 3:1 com a aurora atrás. A legenda é uma coluna com os 4 maiores (3 na letra de acessibilidade; `legendaDaBarra` do núcleo): o ponto de 12 pt na cor do pedaço, no meio da primeira linha do nome, o nome inteiro em subheadline (quebra em vez de cortar), o % em SF Mono semibold no secundário (`porcentoDoTopico`, com o "<1%") e "e mais N tópicos" na vertical do nome (22 pt para dentro, o ponto e o vão de 10). O nome é o do tópico; o tópico que o app não conhece aparece pelo id, como na linha do gasto (`linhaDeGasto`, ObraNaTela.swift:115), e o "Outros", como "Outros · N tópicos" (`rotuloDoOutros`). O VoiceOver lê a barra num elemento só, uma imagem com o rótulo "Gastos por tópico" e o valor pedaço a pedaço ("Terreno, 38%; Estrutura, 11%; …", com "menos de 1%" no lugar do "<1%", como o rótulo do mockup, pelo `porcentoFalado` do núcleo). A hachura é a forma a 45° ("/") com o traço e o passo medidos de través, como o `repeating-linear-gradient(-45deg)` do mockup: 2 pt a cada 6 no excesso do orçamento (`parte1.css:187`) e na zona "acima do banco"; 1,5 a cada 4 nas parcelas a vencer do gasto por mês (`parte1.css:300`). Ela não troca as listras do "passou" da etapa 3 (`ListrasDoExcesso`, PecasDoOrcamento.swift:71): quem usa é o gasto por mês (PR 2b) e o "Vale a pena?" (PR 4a). Na vitrine, a barra da Casa Alphaville (14 tópicos: Terreno 38%, Estrutura 11%, Cerâmica 9%, Mão de obra 8% e "e mais 10 tópicos") e duas amostras da hachura; a vitrine ganha o `-custta.rolagem` de Debug, para os prints das peças de baixo.

**Files:**
- Modify: `app-ios/Custta/Falsos/VitrineDasPecas.swift`
- Create: `app-ios/Custta/Identidade/BarraEmpilhada.swift`
- Test (novo): `app-ios/CusttaTests/BarraEmpilhadaTests.swift`
- Test (alterar): `app-ios/CusttaUITests/VitrineUITests.swift`

**Interfaces:**
- Consumes: `PedacoDoAnel`, `pedacosDoAnel(_:)`, `largurasDaBarra(_:largura:piso:vao:)`, `pisoDaBarra`, `vaoDaBarra`, `porcentoDoTopico(_:total:)`, `porcentoFalado(_:)`, `rotuloDoOutros(_:)`, `legendaDaBarra(_:quantos:)` e `gastoPorTopico(_:hoje:taxaMensal:)` (núcleo, PR 0b e PR 0); `Topico` e `mapaDeTopicos(_:)`; `.placa(forte:raio:)` (Tarefa 19); `rolagemFixaSoComOArgumento()` (só na vitrine).
- Produces: `corDoPedaco(_: PedacoDoAnel) -> Token`; `nomeDoPedaco(_:topicos:) -> String`; `fonteDoTexto(_: UIFont.TextStyle, _: DynamicTypeSize) -> UIFont`; `BarraEmpilhada(pedacos:)`; `BarraDeTopicos(pedacos:topicos:)` (a barra na placa e a legenda; identificador `barraDeTopicos` na barra); `Hachura(traco:passo:)`, uma `Shape`.

- [ ] **Step 1: Escrever os testes**

Os testes de unidade prendem as cores dos pedaços com 7 e 8 tópicos e o nome de cada um; por pixel, na linha do meio da barra, cada pedaço na cor e na largura do núcleo, com o vão transparente e o pequeno no piso, na letra padrão e na máxima; a hachura cobrindo um terço do retângulo em listras "/"; e, numa varredura de todos os tamanhos de letra nas larguras de 343, 370 e 408 pt, o bloco com a barra e a legenda sem passar da largura. O de tela confere na vitrine a barra a 34 pt, o rótulo e o valor do VoiceOver, e a legenda com 4 nomes ("e mais 10 tópicos"; 3 e "e mais 11" na letra máxima), a 56 pt.

Criar `app-ios/CusttaTests/BarraEmpilhadaTests.swift`:

```swift
import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* A barra empilhada de tópicos e a hachura da identidade nova (etapa 4, PR 1b): as cores dos pedaços (os 6 maiores nas do
   anel e o "Outros" em cinza), as larguras do núcleo desenhadas com o vão e o piso, na letra padrão e na de acessibilidade,
   o nome de cada pedaço e a hachura a 45°, por pixel. */
@MainActor
struct BarraEmpilhadaTests {
    /// Os pedaços de uma obra com um gasto por tópico ("t0", "t1"…), nos valores dados.
    private func pedacos(_ brutos: [Double]) -> [PedacoDoAnel] {
        let gastos: [ValorJSON] = brutos.enumerated().map { i, valor in
            .objeto(["id": .texto("g\(i)"), "valor": .numero(valor), "topico": .texto("t\(i)"), "descricao": .texto(""),
                     "data": .texto("2026-02-01"), "pagamento": .texto("pix")])
        }
        let estado = Estado.de(.objeto(["obras": .lista([.objeto([
            "id": .texto("o"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
            "gastos": .lista(gastos)])])]))
        return pedacosDoAnel(gastoPorTopico(estado.obras[0], hoje: "2026-10-29", taxaMensal: 1))
    }

    @Test func coresDoAnelEOutrosCinza() {
        let oito = pedacos([800, 700, 600, 500, 400, 300, 200, 100])
        #expect(oito.map(corDoPedaco) == [.grafico1, .grafico2, .grafico3, .grafico4, .grafico5, .grafico6, .graficoOutros])
        let sete = pedacos([700, 600, 500, 400, 300, 200, 100])
        #expect(sete.map(corDoPedaco).last == .graficoOutros && !sete.last!.outros, "o 7º tópico de uma obra com 7, em cinza")
        let nomes = ["t0": Topico(id: "t0", nome: "Terreno", icone: "casa")]
        #expect(nomeDoPedaco(oito[0], topicos: nomes) == "Terreno" && nomeDoPedaco(oito[1], topicos: nomes) == "t1")
        #expect(nomeDoPedaco(oito[6], topicos: nomes) == "Outros · 2 tópicos")
    }

    /// Os pixels RGBA (pré-multiplicados) do desenho, no escuro, em escala 1.
    private func pixels(_ conteudo: some View) throws -> (w: Int, h: Int, em: (Int, Int) -> [Int]) {
        let r = ImageRenderer(content: conteudo.environment(\.paleta, Paleta()).environment(\.colorScheme, .dark))
        r.scale = 1
        let imagem = try #require(r.cgImage)
        let (w, h) = (imagem.width, imagem.height)
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        rgba.withUnsafeMutableBytes { bytes in
            CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        let copia = rgba
        return (w, h, { x, y in (0..<4).map { Int(copia[(y * w + x) * 4 + $0]) } })
    }

    /// Na linha do meio, cada pedaço na cor dele e nas larguras do núcleo, com o vão transparente entre eles: o pequeno sobe
    /// ao piso (8 pt; 12 na letra de acessibilidade, com o vão de 4 e 26 pt de altura).
    @Test(arguments: [DynamicTypeSize.large, .accessibility5])
    func pedacosNasLargurasDoNucleoComOVao(_ letra: DynamicTypeSize) throws {
        let tres = pedacos([600, 300, 1])
        let grande = letra.isAccessibilitySize
        let (vao, piso, altura) = grande ? (4.0, 12.0, 26) : (3.0, 8.0, 16)
        let larguras = largurasDaBarra(tres, largura: 300, piso: piso, vao: vao)
        #expect(larguras[2] == piso)
        let p = try pixels(BarraEmpilhada(pedacos: tres).frame(width: 300).dynamicTypeSize(letra))
        #expect(p.w == 300 && p.h == altura)
        let cores = [[0x19, 0x9E, 0x70], [0x39, 0x87, 0xE5], [0xD5, 0x51, 0x81]]
        var x = 0.0
        for (i, largura) in larguras.enumerated() {
            let meio = Int(x + largura / 2)
            #expect(p.em(meio, p.h / 2) == cores[i] + [0xFF], "pedaço \(i) em \(meio): \(p.em(meio, p.h / 2))")
            if i < larguras.count - 1 {
                let fresta = Int(x + largura + vao / 2)
                #expect(p.em(fresta, p.h / 2)[3] == 0, "o vão depois do pedaço \(i), em \(fresta)")
            }
            x += largura + vao
        }
    }

    /// A hachura de 2 pt a cada 6 cobre um terço do retângulo, em listras "/": o pixel de uma linha se repete 1 pt à direita
    /// na linha de cima.
    @Test func hachuraA45GrausNoPassoDoMockup() throws {
        let p = try pixels(Hachura().fill(ambar).frame(width: 120, height: 40))
        var cheios = 0, iguais = 0, comparados = 0
        for y in 1..<p.h {
            for x in 0..<(p.w - 1) {
                let cheio = p.em(x, y)[3] > 127
                if cheio { cheios += 1 }
                comparados += 1
                if cheio == (p.em(x + 1, y - 1)[3] > 127) { iguais += 1 }
            }
        }
        let fracao = Double(cheios) / Double(comparados)
        #expect(abs(fracao - 1.0 / 3) < 0.04, "\(fracao)")
        #expect(Double(iguais) / Double(comparados) > 0.97, "\(iguais) de \(comparados)")
    }

    private var ambar: Color { Paleta().cor(.alerta) }

    /// A barra e a legenda não passam da largura do bloco em nenhum tamanho de letra, nas larguras dos iPhones: o % é um
    /// irmão de largura fracionária do nome, e o nome que recebe uma largura fora da grade de pixels arredonda para cima (o
    /// bloco passava 1/3 de pt na letra máxima).
    @Test func barraDeTopicosNaoPassaDaLargura() {
        let estado = Estado.de(DadosDeExemplo.vitrine())
        let pedacos = pedacosDoAnel(gastoPorTopico(estado.obras[0], hoje: "2026-10-29", taxaMensal: 1))
        let topicos = mapaDeTopicos(estado.config.topicosProprios)
        for letra in DynamicTypeSize.allCases {
            for largura in [CGFloat(343), 370, 408] {
                let bloco = BlocoDeVidro { BarraDeTopicos(pedacos: pedacos, topicos: topicos) }.dynamicTypeSize(letra)
                let medida = UIHostingController(rootView: bloco).sizeThatFits(in: CGSize(width: largura, height: 10_000)).width
                #expect(medida == largura, "\(letra) em \(largura): \(medida)")
            }
        }
    }
}
```

Em `app-ios/CusttaUITests/VitrineUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/VitrineUITests.swift
+++ b/app-ios/CusttaUITests/VitrineUITests.swift
@@ -53,6 +53,26 @@ final class VitrineUITests: XCTestCase {
         XCTAssertGreaterThan(alturas[1] / alturas[0], 1.2, "\(alturas)")
     }
 
+    /// A barra de tópicos da Casa Alphaville (14 tópicos): a placa a 34 pt e a barra 8 pt para dentro, um elemento só que o
+    /// VoiceOver lê pedaço a pedaço; a legenda com os 4 maiores (3 na letra máxima), o nome a 34 + 12 + 10 pt e "e mais N
+    /// tópicos" na mesma vertical.
+    func testBarraDeTopicosComALegenda() {
+        for (argumentos, mostrados) in [([String](), 4), (maiorLetra, 3)] {
+            let app = abrirVitrine(argumentos)
+            let barra = app.elemento("barraDeTopicos")
+            app.rolarAte(barra)
+            XCTAssertEqual(barra.label, "Gastos por tópico")
+            XCTAssertTrue((barra.value as? String ?? "").hasPrefix("Terreno, 38%; "), "\(barra.value ?? "")")
+            XCTAssertEqual(barra.frame.minX, 34, accuracy: 0.5, "\(argumentos)")
+            let mais = app.staticTexts["e mais \(14 - mostrados) tópicos"]
+            app.rolarAte(mais)
+            XCTAssertTrue(mais.exists, "\(argumentos)")
+            XCTAssertEqual(mais.frame.minX, 56, accuracy: 0.5, "\(argumentos)")
+            XCTAssertEqual(app.staticTexts["Terreno"].frame.minX, 56, accuracy: 0.5, "\(argumentos)")
+            app.terminate()
+        }
+    }
+
     /// O número mono é um elemento só, que o VoiceOver lê inteiro, com o texto do núcleo; o maior valor, na letra máxima,
     /// fica dentro do bloco, entre as bordas de 34 pt.
     func testNumeroMonoLidoInteiroECabeNaLetraMaxima() {
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E '^/.*error: cannot find' | sed 's/^.*CusttaTests\//CusttaTests\//' | sort -t: -k2,2n -u | head -3
```
Expected: o `CusttaTests` não compila:
```
CusttaTests/BarraEmpilhadaTests.swift:25:26: error: cannot find 'corDoPedaco' in scope
CusttaTests/BarraEmpilhadaTests.swift:27:26: error: cannot find 'corDoPedaco' in scope
CusttaTests/BarraEmpilhadaTests.swift:29:17: error: cannot find 'nomeDoPedaco' in scope
```

- [ ] **Step 3: Implementar**

As larguras saem do `GeometryReader` (no 1º quadro, sem largura, o núcleo dá zero em todos). O ponto da legenda fica no meio da primeira linha do nome pela altura de uma linha da fonte (`fonteDoTexto`), e não pelo `@ScaledMetric`, que não acompanha a fonte na letra máxima (Tarefa 20). O % vai numa coluna de largura inteira, a do "100%" no SF Mono semibold: com a largura fracionária do % ao lado, o nome recebia uma largura fora da grade de pixels e arredondava para cima, e o bloco passava 1/3 de pt em 7 das 36 combinações da varredura (memória `irmao-fracionario-passa-um-pixel`). A hachura é presa ao retângulo (`intersection`).

Em `app-ios/Custta/Falsos/VitrineDasPecas.swift`:

```diff
--- a/app-ios/Custta/Falsos/VitrineDasPecas.swift
+++ b/app-ios/Custta/Falsos/VitrineDasPecas.swift
@@ -7,6 +7,7 @@ import CusttaNucleo
    números da Casa Alphaville da vitrine (os do mockup). `CUSTTA_ABRIR=pecas` a empurra em Obras. */
 struct VitrineDasPecas: View {
     private let estado = Estado.de(DadosDeExemplo.vitrine())
+    @Environment(\.paleta) private var paleta
     @Environment(\.dynamicTypeSize) private var letra
 
     var body: some View {
@@ -43,6 +44,27 @@ struct VitrineDasPecas: View {
                 }
                 .accessibilityElement(children: .contain)
                 .accessibilityIdentifier("vitrine-ambar")
+                BlocoDeVidro {
+                    Text("Gastos por tópico").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto)).padding(.bottom, 8)
+                    BarraDeTopicos(pedacos: pedacosDoAnel(gastoPorTopico(casa, hoje: hoje, taxaMensal: estado.config.taxaMensal)),
+                                   topicos: mapaDeTopicos(estado.config.topicosProprios))
+                }
+                .accessibilityElement(children: .contain)
+                .accessibilityIdentifier("vitrine-topicos")
+                BlocoDeVidro {
+                    CabecalhoDoBloco(rotulo: "Hachura: a vencer e o excesso")
+                    HStack(spacing: 12) {
+                        // A barra a vencer do gasto por mês: o contorno tracejado e a hachura de 1,5 a cada 4, na cor apagada.
+                        let forma = UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4)
+                        Hachura(traco: 1.5, passo: 4).fill(paleta.cor(.barraApagada)).clipShape(forma)
+                            .overlay { forma.stroke(paleta.cor(.barraApagada), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])) }
+                            .frame(width: 26, height: 64)
+                        // O excesso do orçamento: 2 a cada 6, no âmbar.
+                        Hachura().fill(paleta.cor(.alerta)).frame(height: 10).clipShape(.capsule)
+                    }
+                    .accessibilityElement(children: .ignore)
+                    .accessibilityIdentifier("vitrine-hachura")
+                }
                 BlocoDeVidro {
                     CabecalhoDoBloco(rotulo: "Números")
                     VStack(alignment: .leading, spacing: 6) {
@@ -64,6 +86,7 @@ struct VitrineDasPecas: View {
             .padding(.bottom, 98)
         }
         .scrollIndicators(.hidden)
+        .rolagemFixaSoComOArgumento()
         .bordaDeRolagem(abas: true)
         .containerBackground(.clear, for: .navigation)
         .navigationTitle("Peças")
```

Criar `app-ios/Custta/Identidade/BarraEmpilhada.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* A barra empilhada de tópicos e a hachura da identidade nova (etapa 4; a barra foi pedida pelo Giovani em 29/10, no lugar
   do mini-anel da obra: parte1.css:206-216 e "Mudanças de 29/10" do LEIA-ME). Desenhadas em Shape, sem Swift Charts. Os
   pedaços e as larguras vêm do núcleo (Pedacos.swift): os 6 maiores nas cores do anel e o "Outros" em cinza (onde o tópico
   fixo "Outros" sempre fica), com o vão e o piso de largura. A barra não tem toque: a porta para os Gráficos chega com eles
   (PR 2b). */

/// A cor de um pedaço: as seis do anel, do maior para o menor, e o cinza do "Outros" (ou do tópico sozinho no cinza: o fixo
/// "Outros", ou o 7º de uma obra com 7 sem ele).
func corDoPedaco(_ pedaco: PedacoDoAnel) -> Token {
    guard let cor = pedaco.cor else { return .graficoOutros }
    return [Token.grafico1, .grafico2, .grafico3, .grafico4, .grafico5, .grafico6][cor]
}

/// O nome de um pedaço na legenda e no VoiceOver: o do tópico (o que o app não conhece aparece pelo id, como na linha do
/// gasto) ou "Outros · N tópicos".
func nomeDoPedaco(_ pedaco: PedacoDoAnel, topicos: [String: Topico]) -> String {
    if pedaco.outros { return rotuloDoOutros(pedaco) }
    let id = pedaco.topicos.first?.id ?? ""
    return topicos[id]?.nome ?? (id.isEmpty ? "Outros" : id)
}

/// A fonte do estilo de texto no tamanho de letra dado (a altura de uma linha e o tamanho dela crescem com a letra).
func fonteDoTexto(_ estilo: UIFont.TextStyle, _ letra: DynamicTypeSize) -> UIFont {
    UIFont.preferredFont(forTextStyle: estilo, compatibleWith: UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(letra)))
}

/// A barra: um pedaço por tópico, de cantos redondos, com a largura do núcleo (proporcional, com o piso de 8 pt tirado do
/// maior) e o vão de 3 pt; 16 pt de altura. Na letra de acessibilidade, 26 pt, vão de 4 e piso de 12 (parte1.css:209-210).
struct BarraEmpilhada: View {
    let pedacos: [PedacoDoAnel]
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        let grande = letra.isAccessibilitySize
        let (altura, vao, piso): (CGFloat, Double, Double) = grande ? (26, 4, 12) : (16, vaoDaBarra, pisoDaBarra)
        GeometryReader { geo in
            let larguras = largurasDaBarra(pedacos, largura: geo.size.width, piso: piso, vao: vao)
            HStack(spacing: vao) {
                ForEach(Array(pedacos.enumerated()), id: \.offset) { i, pedaco in
                    Capsule().fill(paleta.cor(corDoPedaco(pedaco))).frame(width: larguras[i])
                }
            }
        }
        .frame(height: altura)
    }
}

/// O conteúdo do bloco "Gastos por tópico" da obra: a barra sobre a placa forte (8 pt de recuo e cantos de 12, para as cores
/// ficarem a 3:1 com a aurora atrás) e a legenda numa coluna, com os 4 maiores (3 na letra de acessibilidade): o ponto da
/// cor, o nome inteiro (quebra em vez de cortar) e o % (o "<1%" do núcleo), e "e mais N tópicos" quando sobram. O VoiceOver
/// lê a barra inteira num elemento ("Gastos por tópico": cada pedaço com o %).
struct BarraDeTopicos: View {
    let pedacos: [PedacoDoAnel]
    let topicos: [String: Topico]
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        let total = pedacos.reduce(0) { $0 + $1.bruto }
        let legenda = legendaDaBarra(pedacos, quantos: letra.isAccessibilitySize ? 3 : 4)
        // O ponto no meio da primeira linha do nome, que cresce com a letra. O % numa coluna de largura inteira, a do "100%":
        // assim o nome recebe uma largura na grade de pixels (com o % de largura fracionária ao lado, o nome arredondava para
        // cima, e o bloco passava 1/3 de pt da largura).
        let fonte = fonteDoTexto(.subheadline, letra)
        let mono = UIFont.monospacedSystemFont(ofSize: fonte.pointSize, weight: .semibold)
        let colunaDoPorcento = ("100%" as NSString).size(withAttributes: [.font: mono]).width.rounded(.up)
        VStack(alignment: .leading, spacing: 4) {
            BarraEmpilhada(pedacos: pedacos)
                .padding(8)
                .placa(forte: true)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Gastos por tópico")
                .accessibilityValue(pedacos.map { pedaco in
                    // O "<1%" falado como "menos de 1%" (o porcentoFalado do núcleo), como no rótulo do mockup.
                    "\(nomeDoPedaco(pedaco, topicos: topicos)), \(porcentoFalado(porcentoDoTopico(pedaco.bruto, total: total)))"
                }.joined(separator: "; "))
                .accessibilityAddTraits(.isImage)
                .accessibilityIdentifier("barraDeTopicos")
                .padding(.top, 2)
                .padding(.bottom, 8)
            ForEach(Array(legenda.pedacos.enumerated()), id: \.offset) { _, pedaco in
                HStack(alignment: .top, spacing: 10) {
                    Circle().fill(paleta.cor(corDoPedaco(pedaco))).frame(width: 12, height: 12)
                        .padding(.top, (fonte.lineHeight - 12) / 2)
                    Text(nomeDoPedaco(pedaco, topicos: topicos))
                        .foregroundStyle(paleta.cor(.texto))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(porcentoDoTopico(pedaco.bruto, total: total))
                        .font(.subheadline.monospaced().weight(.semibold))
                        .foregroundStyle(paleta.cor(vidro.secundario))
                        .frame(width: colunaDoPorcento, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
            }
            if let mais = legenda.mais {
                Text(mais).foregroundStyle(paleta.cor(vidro.secundario)).padding(.leading, 22)
            }
        }
        .font(.subheadline)
    }
}

/// A hachura a 45° ("/") da identidade nova, com o traço e o passo medidos de través, como o `repeating-linear-gradient(-45deg)`
/// do mockup: 2 pt a cada 6 no excesso do orçamento e na zona "acima do banco"; 1,5 a cada 4 nas parcelas a vencer do gasto
/// por mês (parte1.css:187 e :300). Uma forma presa ao retângulo: quem usa a preenche na cor e a recorta pela marca.
struct Hachura: Shape {
    var traco: CGFloat = 2
    var passo: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        // A 45°, a medida de través vale √2 vezes na horizontal.
        let largura = traco * CGFloat(2).squareRoot(), avanco = passo * CGFloat(2).squareRoot(), h = rect.height
        var listras = Path()
        var x = rect.minX - h
        while x < rect.maxX {
            listras.move(to: CGPoint(x: x, y: rect.maxY))
            listras.addLine(to: CGPoint(x: x + largura, y: rect.maxY))
            listras.addLine(to: CGPoint(x: x + largura + h, y: rect.minY))
            listras.addLine(to: CGPoint(x: x + h, y: rect.minY))
            listras.closeSubpath()
            x += avanco
        }
        return listras.intersection(Path(rect))
    }
}
```

- [ ] **Step 4: Ver passar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/BarraEmpilhadaTests 2>&1 | grep -E "Test run with"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/VitrineUITests 2>&1 | grep -E "error:|Executed [0-9]+ test" | tail -1
```
Expected: `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 4 tests in 1 suite passed`; `Executed 4 tests, with 0 failures (0 unexpected)`.

- [ ] **Step 5: Conferir na vitrine**

Run: o do Step 5 da Tarefa 19, com `-custta.rolagem 560` depois do `-custta.reduzirMovimento YES`.
Expected: o bloco "Gastos por tópico" como o do `parte1-obra-meio.png` do mockup: a barra de 7 pedaços sobre a placa forte (verde-água, azul, magenta, violeta, laranja, ciano e o cinza largo do "Outros"), a legenda "Terreno 38%", "Estrutura 11%", "Cerâmica 9%", "Mão de obra 8%" e "e mais 10 tópicos"; embaixo, a hachura das duas amostras.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Falsos/VitrineDasPecas.swift app-ios/Custta/Identidade/BarraEmpilhada.swift app-ios/CusttaTests/BarraEmpilhadaTests.swift app-ios/CusttaUITests/VitrineUITests.swift
git commit -m "feat: barra empilhada de tópicos e hachura da identidade nova" -m "A barra empilhada que o Giovani pediu no lugar do mini-anel da obra nasce sem tela e sem toque, desenhada em Shape: um pedaço por tópico, de cantos redondos, com as larguras do núcleo (os 6 maiores nas cores do anel e o \"Outros\" em cinza, o vão de 3 pt e o piso de 8 pt, que passam a 4 e 12 na letra de acessibilidade, com a barra de 26 pt), sobre a placa forte. A legenda fica numa coluna, com os 4 maiores (3 na letra de acessibilidade), o nome inteiro, o % do núcleo numa coluna de largura inteira (com a largura fracionária dele, o nome arredondava para cima e o bloco passava da largura) e \"e mais N tópicos\"; o VoiceOver lê a barra num elemento só, pedaço a pedaço. A hachura a 45° é uma forma, com o traço e o passo do mockup, para as parcelas a vencer, o excesso do orçamento e a zona acima do banco. A vitrine mostra a barra da Casa Alphaville e ganha o gancho da rolagem fixa."
```

### Task 23: Linha de lançamento com o valor em mono e o ícone na 2ª linha

A linha do gasto ganha a forma mono da identidade nova (spec, "Telas": "A linha de lançamento da obra ganha o valor em mono e o ícone pequeno na 2ª linha; as folhas (A pagar e detalhe do tópico) continuam com a linha da etapa 3"; ajuste 3 do mockup: "lançamentos: o ícone quadrado saiu e título e valor vão de 88 → 34"; `parte1.css:223-237`). Na forma mono, sai o ícone quadrado de 38 pt (PecasDaObra.swift:370-374), e o título e o valor ficam na borda de 34 pt (o recuo de 18 do cartão); embaixo do título, o ícone do tópico (16 pt, 42 na letra máxima, crescendo a cada passo e em pontos inteiros) no começo da linha do tópico, do pagamento e da data, 3 pt abaixo da linha de base (5 na letra máxima), em subheadline no secundário (a etapa 3 usa footnote). O valor vai em mono no tamanho de linha (`ValorEmDinheiro(_:mono: .linha)`, Tarefa 20), ao lado do título e no meio da altura, enquanto sobram 120 pt para o título; quando não cabe ao lado, desce para baixo dele (spec, "O número que encolhe": na linha, o R$ já está em 11 pt e o valor não encolhe). Num iPhone de 375 pt, o cartão tem 307 pt sem o recuo: o "−R$ 1.234.567,89" fica ao lado, e o de R$ 1 bilhão desce. Na letra de acessibilidade, tudo vai numa coluna (título, a linha de baixo e o valor), como o mockup na AX5. O recuo passa a 10 × 18 pt e a altura mínima a 52 (16 × 18 e 72 na letra de acessibilidade). Na linha de baixo, "Pix" e "Cartão" seguem por extenso, sem o ícone do pagamento da etapa 3 (o raio e o cartão do sistema), que o mockup não tem na linha mono (`parte1.js:248-252`, o `gastoLinha`). Ficam como na etapa 3: os "·", a linha de baixo que quebra em vez de cortar (o mockup corta em duas linhas; aqui a guarda só deixa `lineLimit` na lista fixa), o fundo aceso, a etiqueta "novo", o VoiceOver (o rótulo do núcleo e o valor por extenso) e o identificador `gasto-<id>`. A forma vem do `linhaMono` do environment (padrão desligado): a obra a liga no PR 1c, e as folhas do A pagar e do detalhe do tópico, que não o ligam, ficam com a linha da etapa 3. Na vitrine, um cartão com dois lançamentos da Casa Alphaville e um de R$ 1 bilhão, na linha mono.

**Files:**
- Modify: `app-ios/Custta/Falsos/VitrineDasPecas.swift`
- Modify: `app-ios/Custta/Telas/PecasDaObra.swift`
- Test (novo): `app-ios/CusttaTests/LinhaMonoTests.swift`
- Test (alterar): `app-ios/CusttaUITests/VitrineUITests.swift`

**Interfaces:**
- Consumes: `LinhaDeGastoView(gasto:linha:acesa:novo:)` e `CartaoDaLista`, `LinhaFina` (PecasDaObra.swift); `linhaDeGasto(_:topicos:)` e `listaDaObra(_:hoje:)` (núcleo); `ValorEmDinheiro(_:mono:)`, `corpoDoTexto(_:)` e `crescendoComALetra(de:ate:corpo:)` (Tarefas 20 e 21).
- Produces: `EnvironmentValues.linhaMono: Bool` (padrão `false`), que liga a forma mono da `LinhaDeGastoView`.

- [ ] **Step 1: Escrever os testes**

Os testes de unidade prendem por pixel onde o valor fica (ao lado do título, ou embaixo dele quando sobrariam menos de 120 pt), com as larguras dos valores que decidem; o valor ao lado inteiro, terminando nos centavos e não em reticências (o de R$ 1 bilhão numa linha de 370 pt); a altura mínima de 52 pt; a linha sem passar da largura do cartão em nenhum tamanho de letra (o ícone fracionário passava 1/3 de pt); o ícone quadrado, que sai da linha mono e fica na da etapa 3; e o ícone do tópico crescendo com a letra (na máxima, a linha de baixo mede o ícone de 42 pt, o vão de 6 e o texto; com o ícone parado em 16, os outros testes e a auditoria passam). O de tela confere na vitrine os três lançamentos de borda a borda do cartão, com 52 pt (72 na letra máxima), lidos como na etapa 3.

Criar `app-ios/CusttaTests/LinhaMonoTests.swift`:

```swift
import Testing
import SwiftUI
import UIKit
@testable import Custta
import CusttaNucleo

/* A linha do gasto na forma mono da identidade nova (etapa 4, PR 1b): sem o ícone quadrado da etapa 3, com o valor ao lado
   do título enquanto cabe e embaixo dele quando não cabe, e 52 pt de altura mínima. Medida no layout, num
   UIHostingController em escala 1, e nos pixels, no escuro. */
@MainActor
struct LinhaMonoTests {
    private func gasto(_ valor: Double) -> Gasto {
        Estado.de(.objeto(["obras": .lista([.objeto([
            "id": .texto("o"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
            "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(valor), "topico": .texto("x"),
                                       "descricao": .texto("Cal"), "data": .texto("2026-10-10"), "pagamento": .texto("pix")])]),
        ])])])).obras[0].gastos[0]
    }

    private func linha(_ g: Gasto, mono: Bool) -> some View {
        LinhaDeGastoView(gasto: g, linha: linhaDeGasto(g, topicos: mapaDeTopicos([]))).environment(\.linhaMono, mono)
    }

    /// Os pixels RGBA (pré-multiplicados) da linha na largura dada, no escuro, em escala 1.
    private func pixels(_ conteudo: some View) throws -> (w: Int, h: Int, rgba: [UInt8]) {
        let r = ImageRenderer(content: conteudo.environment(\.paleta, Paleta()).environment(\.colorScheme, .dark))
        r.scale = 1
        let imagem = try #require(r.cgImage)
        let (w, h) = (imagem.width, imagem.height)
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        rgba.withUnsafeMutableBytes { bytes in
            CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                .draw(imagem, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        return (w, h, rgba)
    }

    /// Há tinta nos 30 pt antes do recuo da direita? Com o título e a linha de baixo curtos ("Cal"; "x · Pix · 10/10/26"),
    /// só o valor ao lado do título chega lá; embaixo do título, ele começa no recuo da esquerda e não passa de 190 pt.
    private func valorAoLado(_ g: Gasto, largura: Int) throws -> Bool {
        let p = try pixels(linha(g, mono: true).frame(width: CGFloat(largura)))
        return (0..<p.h).contains { y in ((largura - 48)..<(largura - 18)).contains { x in p.rgba[(y * p.w + x) * 4 + 3] > 128 } }
    }

    /// A altura da tinta nos 8 pt antes do recuo da direita: os centavos (",00") do valor inteiro têm ~8 pt; as reticências do
    /// valor cortado, ~3.
    private func tintaNaPontaDireita(_ g: Gasto, largura: Int) throws -> Int {
        let p = try pixels(linha(g, mono: true).frame(width: CGFloat(largura)))
        let linhas = (0..<p.h).filter { y in ((largura - 26)..<(largura - 18)).contains { x in p.rgba[(y * p.w + x) * 4 + 3] > 128 } }
        return (linhas.last ?? 0) - (linhas.first ?? 0) + 1
    }

    /// O valor ao lado do título fica inteiro: o de R$ 1 bilhão, numa linha de 370 pt (o cartão num iPhone de 402), cabe ao
    /// lado e termina nos centavos, sem reticências (a pilha dava ao valor só a metade da linha).
    @Test func valorAoLadoNaoCorta() throws {
        #expect(try valorAoLado(gasto(1_000_000_000), largura: 370))
        #expect(try tintaNaPontaDireita(gasto(1_000_000_000), largura: 370) >= 6)
        #expect(try tintaNaPontaDireita(gasto(4_980), largura: 370) >= 6)
    }

    /// O valor fica ao lado do título enquanto sobram 120 pt para o título: numa linha de 280 pt (244 sem o recuo), o comum
    /// fica ao lado e o de R$ 1 bilhão desce para baixo dele; em 343 pt (o cartão num iPhone de 375; 307 sem o recuo), o de
    /// R$ 1.234.567,89 fica ao lado e o de R$ 1 bilhão, com mais de 175 pt, ainda desce. A linha tem 52 pt no mínimo.
    @Test func valorAoLadoDoTituloOuEmbaixoDele() throws {
        let largura = { (valor: Double) in
            UIHostingController(rootView: ValorEmDinheiro("−" + moeda(valor), mono: .linha).fixedSize())
                .sizeThatFits(in: CGSize(width: 1000, height: 1000)).width
        }
        #expect(largura(4_980) <= 244 - 12 - 120 && largura(1_234_567.89) <= 307 - 12 - 120 && largura(1_000_000_000) > 307 - 12 - 120,
                "\(largura(4_980)), \(largura(1_234_567.89)) e \(largura(1_000_000_000))")
        #expect(try valorAoLado(gasto(4_980), largura: 280))
        #expect(try !valorAoLado(gasto(1_000_000_000), largura: 280))
        #expect(try valorAoLado(gasto(1_234_567.89), largura: 343))
        #expect(try !valorAoLado(gasto(1_000_000_000), largura: 343))
        let altura = UIHostingController(rootView: linha(gasto(4_980), mono: true).environment(\.displayScale, 1))
            .sizeThatFits(in: CGSize(width: 1000, height: 10_000)).height
        #expect(altura >= 52, "\(altura)")
    }

    /// A linha não passa da largura do cartão em nenhum tamanho de letra, nas larguras dos iPhones, com os lançamentos da
    /// vitrine e o de R$ 1 bilhão: o ícone do tópico, que cresce com a letra, fica ao lado do texto de baixo.
    @Test func linhaNaoPassaDaLargura() {
        let estado = Estado.de(DadosDeExemplo.vitrine())
        let topicos = mapaDeTopicos(estado.config.topicosProprios)
        let gastos = Array(estado.obras[0].gastos.prefix(6)) + [gasto(1_000_000_000)]
        for letra in DynamicTypeSize.allCases {
            for largura in [CGFloat(343), 370, 408] {
                for g in gastos {
                    let vista = LinhaDeGastoView(gasto: g, linha: linhaDeGasto(g, topicos: topicos)).environment(\.linhaMono, true)
                        .dynamicTypeSize(letra)
                    let medida = UIHostingController(rootView: vista).sizeThatFits(in: CGSize(width: largura, height: 10_000)).width
                    #expect(medida == largura, "\(g.id) \(letra) em \(largura): \(medida)")
                }
            }
        }
    }

    /// O ícone quadrado da etapa 3 (o fundo FantasmaFundo, #0A3F30 no escuro) sai da linha mono; a da etapa 3 continua com ele.
    @Test func semOIconeQuadrado() throws {
        func fundosDoIcone(mono: Bool) throws -> Int {
            let r = ImageRenderer(content: linha(gasto(4_980), mono: mono).frame(width: 343)
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
            return stride(from: 0, to: rgba.count, by: 4).filter { rgba[$0] == 0x0A && rgba[$0 + 1] == 0x3F && rgba[$0 + 2] == 0x30 }.count
        }
        #expect(try fundosDoIcone(mono: false) > 500)
        #expect(try fundosDoIcone(mono: true) == 0)
    }

    /// O ícone do tópico cresce com a letra: na máxima, a linha de baixo mede o ícone de 42 pt, o vão de 6 e o texto.
    @Test func iconeDoTopicoCresceComALetra() {
        let g = gasto(4_980), l = linhaDeGasto(g, topicos: mapaDeTopicos([]))
        func ideal(_ v: some View) -> CGFloat {
            UIHostingController(rootView: v.dynamicTypeSize(.accessibility5).fixedSize())
                .sizeThatFits(in: CGSize(width: 10_000, height: 10_000)).width
        }
        let texto = ideal(Text([l.topico, l.pagamento, l.data].compactMap { $0 }.joined(separator: " · ")).font(.subheadline))
        let linhaInteira = ideal(linha(g, mono: true))
        #expect(abs(linhaInteira - 2 * 18 - 42 - 6 - texto) < 1, "\(linhaInteira) e \(texto)")
    }
}
```

Em `app-ios/CusttaUITests/VitrineUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/VitrineUITests.swift
+++ b/app-ios/CusttaUITests/VitrineUITests.swift
@@ -73,6 +73,27 @@ final class VitrineUITests: XCTestCase {
         }
     }
 
+    /// Os lançamentos na linha mono: cada linha um elemento só, de borda a borda do cartão (16 pt), com 52 pt de altura no
+    /// mínimo (72 na letra máxima), lida como na etapa 3 (o título, o tópico, o pagamento e a data; o valor por extenso).
+    func testLancamentosNaLinhaMono() {
+        for (argumentos, minima) in [([String](), CGFloat(52)), (maiorLetra, 72)] {
+            let app = abrirVitrine(argumentos)
+            let cartao = app.elemento("vitrine-lancamentos")
+            app.rolarAte(cartao)
+            let linhas = cartao.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'gasto-'"))
+            XCTAssertEqual(linhas.count, 3, "\(argumentos)")
+            for linha in linhas.allElementsBoundByIndex {
+                XCTAssertEqual(linha.frame.minX, 16, accuracy: 0.5, "\(argumentos)")
+                XCTAssertEqual(linha.frame.maxX, app.frame.width - 16, accuracy: 0.5, "\(argumentos)")
+                XCTAssertGreaterThanOrEqual(linha.frame.height, minima, "\(linha.label) \(argumentos)")
+            }
+            let gigante = app.elemento("gasto-gigante")
+            XCTAssertTrue(gigante.label.hasPrefix("Terreno do condomínio. Terreno, Pix, "), gigante.label)
+            XCTAssertEqual(gigante.value as? String, "R$\u{a0}1.000.000.000,00")
+            app.terminate()
+        }
+    }
+
     /// O número mono é um elemento só, que o VoiceOver lê inteiro, com o texto do núcleo; o maior valor, na letra máxima,
     /// fica dentro do bloco, entre as bordas de 34 pt.
     func testNumeroMonoLidoInteiroECabeNaLetraMaxima() {
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E '^/.*error:' | sed 's/^.*CusttaTests\//CusttaTests\//' | sort -u | head -3
```
Expected: o `CusttaTests` não compila:
```
CusttaTests/LinhaMonoTests.swift:21:100: error: cannot convert value of type 'KeyPath<EnvironmentValues, V>' to expected argument type 'WritableKeyPath<EnvironmentValues, V>'
CusttaTests/LinhaMonoTests.swift:21:100: error: value of type 'EnvironmentValues' has no member 'linhaMono'
CusttaTests/LinhaMonoTests.swift:90:114: error: cannot convert value of type 'KeyPath<EnvironmentValues, V>' to expected argument type 'WritableKeyPath<EnvironmentValues, V>'
```

- [ ] **Step 3: Implementar**

A escolha entre o valor ao lado e embaixo é um `ViewThatFits`: na medida ideal, a coluna do título vale 120 pt (`idealWidth`), e a linha fica com o primeiro arranjo que cabe. Ao lado, o valor tem prioridade de layout: sem ela, a pilha dá a ele no máximo a metade da linha, e o de R$ 1 bilhão saía cortado em reticências num iPhone de 402 pt (o teste `valorAoLadoNaoCorta` reprova sem a prioridade). Na letra de acessibilidade, a coluna direto, sem o `ViewThatFits`, que na maior letra deixa o "Text clipped" sem elemento do arranjo descartado na auditoria (T34 da etapa 3). A linha da etapa 3 não muda: o `meta` passa a receber a fonte (footnote nela, subheadline na mono) e se leva o ícone do pagamento (na mono, não), e o recuo e a altura mínima saem do `linhaMono`.

Em `app-ios/Custta/Falsos/VitrineDasPecas.swift`:

```diff
--- a/app-ios/Custta/Falsos/VitrineDasPecas.swift
+++ b/app-ios/Custta/Falsos/VitrineDasPecas.swift
@@ -7,6 +7,12 @@ import CusttaNucleo
    números da Casa Alphaville da vitrine (os do mockup). `CUSTTA_ABRIR=pecas` a empurra em Obras. */
 struct VitrineDasPecas: View {
     private let estado = Estado.de(DadosDeExemplo.vitrine())
+    private static let gigante = Estado.de(.objeto(["obras": .lista([.objeto([
+        "id": .texto("x"), "nome": .texto("x"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
+        "gastos": .lista([.objeto(["id": .texto("gigante"), "valor": .numero(1_000_000_000), "topico": .texto("terreno"),
+                                   "descricao": .texto("Terreno do condomínio"), "data": .texto("2026-10-01"),
+                                   "pagamento": .texto("pix")])]),
+    ])])])).obras[0].gastos[0]
     @Environment(\.paleta) private var paleta
     @Environment(\.dynamicTypeSize) private var letra
 
@@ -51,6 +57,19 @@ struct VitrineDasPecas: View {
                 }
                 .accessibilityElement(children: .contain)
                 .accessibilityIdentifier("vitrine-topicos")
+                // Os lançamentos na linha mono: os dois primeiros do mês mais recente e um de R$ 1 bilhão, que não cabe ao
+                // lado do título (deixaria menos de 120 pt para ele) e desce para baixo dele.
+                let topicos = mapaDeTopicos(estado.config.topicosProprios)
+                let lancamentos = Array(listaDaObra(casa, hoje: hoje).meses.first?.gastos.prefix(2) ?? []) + [Self.gigante]
+                CartaoDaLista {
+                    ForEach(Array(lancamentos.enumerated()), id: \.element.id) { i, gasto in
+                        if i > 0 { LinhaFina().padding(.horizontal, Grade.recuo) }
+                        LinhaDeGastoView(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos))
+                    }
+                }
+                .environment(\.linhaMono, true)
+                .accessibilityElement(children: .contain)
+                .accessibilityIdentifier("vitrine-lancamentos")
                 BlocoDeVidro {
                     CabecalhoDoBloco(rotulo: "Hachura: a vencer e o excesso")
                     HStack(spacing: 12) {
```

Em `app-ios/Custta/Telas/PecasDaObra.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDaObra.swift
+++ b/app-ios/Custta/Telas/PecasDaObra.swift
@@ -337,7 +337,8 @@ struct LinhaDoAVencer: View {
 
 /// A linha de um gasto: ícone do tópico (sólido), título e valor, e embaixo o tópico, o pagamento e a data. O valor vem
 /// sem vermelho, só com o "−"; "Pix" e "Cartão" por extenso. Na letra grande, cada informação numa linha, sem o ícone e
-/// sem os "·". O VoiceOver lê "Cimento CP-II, 120 sacos. Materiais básicos, Pix, 10 de outubro de 2026" e o valor.
+/// sem os "·". O VoiceOver lê "Cimento CP-II, 120 sacos. Materiais básicos, Pix, 10 de outubro de 2026" e o valor. Com o
+/// `linhaMono` do environment, a forma da identidade nova (etapa 4): a obra a liga no PR 1c; as folhas ficam com esta.
 struct LinhaDeGastoView: View {
     let gasto: Gasto
     let linha: LinhaDeGasto
@@ -350,13 +351,14 @@ struct LinhaDeGastoView: View {
     @Environment(\.colorScheme) private var esquema
     @Environment(\.displayScale) private var escala
     @Environment(\.dentroDaFolha) private var naFolha
+    @Environment(\.linhaMono) private var mono
 
     var body: some View {
         Group {
-            if tamanho.isAccessibilitySize { empilhada } else { normal }
+            if mono { formaMono } else if tamanho.isAccessibilitySize { empilhada } else { normal }
         }
-        .padding(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18))
-        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
+        .padding(recuo)
+        .frame(maxWidth: .infinity, minHeight: alturaMinima, alignment: .leading)
         .background(acesa ? paleta.cor(.aceso) : .clear)
         .contentShape(.rect)
         .accessibilityElement(children: .ignore)
@@ -378,11 +380,58 @@ struct LinhaDeGastoView: View {
                     Spacer(minLength: 0)
                     valor
                 }
-                meta
+                meta(.footnote)
             }
         }
     }
 
+    /// 12 × 18 pt e 44 de altura; na linha mono, 10 × 18 e 52 (16 × 18 e 72 na letra de acessibilidade), como o mockup.
+    private var recuo: EdgeInsets {
+        let vertical: CGFloat = mono ? (tamanho.isAccessibilitySize ? 16 : 10) : 12
+        return EdgeInsets(top: vertical, leading: 18, bottom: vertical, trailing: 18)
+    }
+
+    private var alturaMinima: CGFloat { mono ? (tamanho.isAccessibilitySize ? 72 : 52) : 44 }
+
+    /// A linha mono (mockup da etapa 4, parte1.css:223-237): sem o ícone quadrado, o título e o valor na borda de 34 pt; embaixo,
+    /// o ícone pequeno do tópico no começo da linha do tópico, do pagamento e da data, em subheadline, sem o ícone do Pix e do
+    /// cartão (o mockup só tem o do tópico; "Pix" e "Cartão" seguem por extenso). O valor em mono, ao lado
+    /// do título e no meio da altura; quando não cabe ao lado (sobrariam menos de 120 pt para o título), desce para baixo dele,
+    /// como na letra de acessibilidade, onde tudo vai numa coluna.
+    @ViewBuilder private var formaMono: some View {
+        let valor = ValorEmDinheiro(linha.valor, mono: .linha)
+        let coluna = VStack(alignment: .leading, spacing: 6) { textosMono; valor }
+        if tamanho.isAccessibilitySize {
+            coluna
+        } else {
+            ViewThatFits(in: .horizontal) {
+                HStack(spacing: 12) {
+                    textosMono.frame(minWidth: 0, idealWidth: 120, maxWidth: .infinity, alignment: .leading)
+                    // Sem a prioridade, a pilha dá ao valor no máximo a metade da linha e corta o maior com reticências.
+                    valor.layoutPriority(1)
+                }
+                coluna
+            }
+        }
+    }
+
+    /// O título e, embaixo, o ícone do tópico (16 pt; 42 na letra máxima) na linha de base do texto, 3 pt abaixo dela (5). O
+    /// ícone em pontos inteiros: com o tamanho fracionário ao lado, o texto arredondava para cima e a linha passava 1/3 de pt.
+    private var textosMono: some View {
+        let corpo = corpoDoTexto(tamanho)
+        let (icone, descida) = (crescendoComALetra(de: 16, ate: 42, corpo: corpo).rounded(), crescendoComALetra(de: 3, ate: 5, corpo: corpo))
+        return VStack(alignment: .leading, spacing: 2) {
+            titulo
+            HStack(alignment: .firstTextBaseline, spacing: 6) {
+                Image(decorative: iconeDoCatalogo(linha.icone))
+                    .resizable().frame(width: icone, height: icone)
+                    .alignmentGuide(.firstTextBaseline) { $0.height - descida }
+                meta(.subheadline, iconeDoPagamento: false)
+            }
+            .foregroundStyle(paleta.cor(secundario))
+        }
+    }
+
     private var empilhada: some View {
         VStack(alignment: .leading, spacing: 4) {
             titulo
@@ -413,15 +462,16 @@ struct LinhaDeGastoView: View {
     /// Tópico · forma de pagamento com o ícone · data, num texto só (quebra sozinho; um "·" solto era um texto de 4 pt
     /// que a auditoria de contraste do Xcode não conseguia medir). Os ícones do pagamento são os do sistema, que crescem
     /// com a letra dentro do texto: o raio do Pix ("bolt") e o cartão ("creditcard").
-    private var meta: some View {
+    private func meta(_ fonte: Font, iconeDoPagamento: Bool = true) -> some View {
         var partes: [Text] = []
         if let topico = linha.topico { partes.append(Text(topico)) }
         if let pagamento = linha.pagamento {
-            partes.append(Text("\(Image(systemName: pagamento == "Pix" ? "bolt" : "creditcard")) \(pagamento)"))
+            partes.append(iconeDoPagamento ? Text("\(Image(systemName: pagamento == "Pix" ? "bolt" : "creditcard")) \(pagamento)")
+                                           : Text(pagamento))
         }
         partes.append(Text(linha.data))
         let junto = partes.dropFirst().reduce(partes[0]) { Text("\($0) · \($1)") }
-        return junto.font(.footnote).foregroundStyle(paleta.cor(secundario))
+        return junto.font(fonte).foregroundStyle(paleta.cor(secundario))
     }
 
     private func detalhe(_ texto: String) -> some View {
@@ -432,6 +482,11 @@ struct LinhaDeGastoView: View {
     private var secundario: Token { naFolha ? .secundarioTransparente : vidro.secundario }
 }
 
+extension EnvironmentValues {
+    /// A linha do gasto na forma mono da identidade nova (etapa 4).
+    @Entry var linhaMono = false
+}
+
 /// A etiqueta "novo" da linha que acabou de ser lançada (some com o destaque, em ~2 s).
 struct EtiquetaNovo: View {
     @Environment(\.paleta) private var paleta
```

- [ ] **Step 4: Ver passar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/LinhaMonoTests 2>&1 | grep -E "Test run with"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/VitrineUITests 2>&1 | grep -E "error:|Executed [0-9]+ test" | tail -1
```
Expected: `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 5 tests in 1 suite passed`; `Executed 5 tests, with 0 failures (0 unexpected)`.

- [ ] **Step 5: Conferir na vitrine**

Run: o do Step 5 da Tarefa 19, com `-custta.rolagem 900`.
Expected: o cartão dos lançamentos como os do `parte1-obra-meio.png` do mockup: "Cimento CP-II, 120 sacos" e o "−R$ 4.980,00" em mono à direita, embaixo o ícone pequeno do tópico e "Materiais básicos · Pix · …"; o de R$ 1 bilhão com o valor embaixo do título num iPhone de 375 pt.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Falsos/VitrineDasPecas.swift app-ios/Custta/Telas/PecasDaObra.swift app-ios/CusttaTests/LinhaMonoTests.swift app-ios/CusttaUITests/VitrineUITests.swift
git commit -m "feat: linha de lançamento com o valor em mono e o ícone na 2ª linha" -m "A linha do gasto ganha a forma mono da identidade nova (spec, \"Telas\": a linha de lançamento da obra ganha o valor em mono e o ícone pequeno na 2ª linha): sem o ícone quadrado, com o título e o valor na borda de 34 pt e, embaixo, o ícone do tópico no começo da linha do tópico, do pagamento e da data, em subheadline, sem o ícone do Pix e do cartão, como o mockup. O valor em mono fica ao lado do título, no meio da altura, enquanto sobram 120 pt para o título; quando não cabe, desce para baixo dele, como na letra de acessibilidade, onde tudo vai numa coluna. A forma vem do linhaMono do environment, que a obra liga no PR 1c; as folhas do A pagar e do detalhe do tópico ficam com a linha da etapa 3, como o spec pede."
```

### Task 24: Auditoria da vitrine das peças na maior letra

A auditoria de acessibilidade do Xcode passa pela vitrine das peças na maior letra (AX5), antes de a obra do PR 1c usá-las (spec, "Testes e validação", item 5: as auditorias cobrem as telas novas na letra máxima). São cinco rolagens fixas (0, 900, 1800, 2700 e 3600 pt; a vitrine tem ~4.450 pt na AX5 do 18 Pro), e não arrastos, como na obra (AuditoriaUITests.swift, `testParte3NoMaiorTamanho`: logo depois de um arrasto, a auditoria acha corte que parado não há). Ela confere o tipo dinâmico, o texto cortado e os alvos de 44 pt: o título em SF Mono e a cápsula de metadados, os blocos, o número mono, a barra de tópicos e a linha mono crescem com a letra, nada corta e nada é pequeno demais para o dedo. O título pequeno da barra fica de fora pelo identificador `tituloPequenoDaBarra`, como o da obra de hoje, e a cápsula de abas, como em todas as telas. Com a letra lida fora da barra (Tarefa 21), o título chega a 20 pt na máxima e a auditoria da vitrine já não acha nada nele; quem prova que ele cresce é a guarda de altura do `testTituloECapsulaDeMetadadosNaGrade`, da mesma tarefa. A descrição suficiente fica para a obra: na vitrine, o número fica solto, sem o rótulo do bloco, e a auditoria acha "Label not human-readable" no elemento só de algarismos ("R$ 842.317,45"), com o mono ou sem ele, até num `Text` simples em SF Pro (provado com as cinco variantes); na obra, o rótulo e o número do bloco são um elemento, como nos indicadores da etapa 3 (`IndicadoresDaObraView`). A auditoria não pega tudo: com o número sem crescer (o corpo fixo em 17) ou sem encolher (`minimumScaleFactor(1)`, o maior valor cortado com reticências), ela passa; quem prende isso são os testes de unidade da Tarefa 20: o `numeroNaTelaCresceACadaPasso`, que mede o número na tela a cada passo (reprova com o corpo fixo em 17 e com o teto no AX2), e a largura do maior valor. Com o título num tamanho fixo, ela reprova.

**Files:**
- Test (alterar): `app-ios/CusttaUITests/AuditoriaUITests.swift`

**Interfaces:**
- Consumes: `auditar(_:_:corteSemElemento:)`, `maiorLetra` e `parado` (AuditoriaUITests.swift); a vitrine (`CUSTTA_ABRIR=pecas`, Tarefas 19 a 23) e o `-custta.rolagem` dela (Tarefa 22).
- Produces: `AuditoriaUITests.testVitrineDasPecasNoMaiorTamanho`.

- [ ] **Step 1: Escrever o teste**

Em `app-ios/CusttaUITests/AuditoriaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -151,6 +151,24 @@ final class AuditoriaUITests: XCTestCase {
         try auditar(app, tiposDeAuditoria)
     }
 
+    /// A vitrine das peças da identidade nova (etapa 4, PR 1b; só no Debug, com CUSTTA_ABRIR=pecas) na maior letra, em
+    /// rolagens fixas (como a obra: logo depois de um arrasto, a auditoria acha corte que parado não há): o título e a cápsula
+    /// de metadados, os blocos, o número mono, a barra de tópicos e a linha mono crescem com a letra e nada corta, e os alvos
+    /// têm 44 pt, antes de a obra (PR 1c) usá-los. O título pequeno da barra é o da obra (`tituloPequenoDaBarra`), que para
+    /// perto de 20 pt. Sem a descrição suficiente: na vitrine, o número fica solto, sem o rótulo do bloco, e a auditoria acha
+    /// "Label not human-readable" num elemento só de algarismos, com ou sem o mono; na obra, o rótulo e o número do bloco são
+    /// um elemento, como os indicadores da etapa 3.
+    @MainActor func testVitrineDasPecasNoMaiorTamanho() throws {
+        for rolagem in [0, 900, 1800, 2700, 3600] {
+            let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "pecas",
+                               argumentos: maiorLetra + parado + ["-custta.rolagem", "\(rolagem)"])
+            XCTAssertTrue(app.elemento("vitrine-solido").waitForExistence(timeout: 10))
+            Thread.sleep(forTimeInterval: 1.5)
+            try auditar(app, [.dynamicType, .textClipped, .hitRegion])
+            app.terminate()
+        }
+    }
+
     /// A folha do gasto (etapa 2, PR 2) em cada passo, na maior letra; os detalhes também rolados, e o valor também com o
     /// número mais largo do visor (13 caracteres, a largura do teto R$ 99.999.999,99), que encolhe para caber.
     @MainActor func testFolhaDoGastoNoMaiorTamanho() throws {
```

- [ ] **Step 2: Ver falhar, com o título num tamanho fixo**

Troque, só para ver, `let tamanho = crescendoComALetra(de: 30, ate: 44, corpo: corpoDoTexto(letra))` por `let tamanho: CGFloat = 30` no `TituloMono` (Titulos.swift), compile e rode.

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/AuditoriaUITests/testVitrineDasPecasNoMaiorTamanho > /tmp/auditoria-vitrine.log 2>&1
grep -E "auditoria \|.*reprova" /tmp/auditoria-vitrine.log | sed 's/ (.*//' | sort | uniq -c
grep -E "Executed [0-9]+ test" /tmp/auditoria-vitrine.log | tail -1
git checkout -- app-ios/Custta/Identidade/Titulos.swift
```
Expected: `** TEST BUILD SUCCEEDED **`, e a auditoria reprova o título na primeira rolagem:
```
   1 auditoria | Dynamic Type font sizes are unsupported | 48 "Casa Alphaville" vitrine-titulo
	 Executed 1 test, with 1 failure (0 unexpected) in 58.180 (58.186) seconds
```

- [ ] **Step 3: Ver passar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/AuditoriaUITests/testVitrineDasPecasNoMaiorTamanho > /tmp/auditoria-vitrine.log 2>&1
grep -E "auditoria \|" /tmp/auditoria-vitrine.log | sed 's/ (.*//' | sort | uniq -c
grep -E "Executed [0-9]+ test" /tmp/auditoria-vitrine.log | tail -1
```
Expected: `** TEST BUILD SUCCEEDED **`, sem aviso; só achados de fora (a cápsula de abas), 5 de cada (um por rolagem), e nenhuma reprovação:
```
   5 auditoria | Dynamic Type font sizes are unsupported | 48 "Ajustes"
   5 auditoria | Dynamic Type font sizes are unsupported | 48 "Obras"
	 Executed 1 test, with 0 failures (0 unexpected) in 53.035 (53.037) seconds
```

- [ ] **Step 4: Commit**

```bash
git add app-ios/CusttaUITests/AuditoriaUITests.swift
git commit -m "test: auditoria da vitrine das peças na maior letra" -m "A auditoria de acessibilidade passa pela vitrine das peças da identidade nova na maior letra, em cinco rolagens fixas, antes de a obra do PR 1c usá-las: o título e a cápsula de metadados, os blocos, o número mono, a barra de tópicos e a linha mono crescem com a letra, nada corta e os alvos têm 44 pt. O título pequeno da barra fica de fora pelo identificador, como o da obra. A descrição suficiente fica para a obra: na vitrine, o número fica solto, sem o rótulo do bloco, e a auditoria acha \"Label not human-readable\" num elemento só de algarismos, com ou sem o mono."
```

---

## PR 1c (app): a obra em blocos, com a costura das telas da análise

O PR fecha o marco 1. Na primeira parte, ele prepara o caminho das telas da análise sem tela nova: o `gastoPorTopico` do núcleo sem `hoje` e sem taxa, que a barra de tópicos refaz a cada desenho da obra (Tarefa 25); o "<1%" no "% da obra" da folha do detalhe do tópico e da lista da tela Orçamento (Tarefa 26); a costura das telas da análise em `Custta/Analise/`, com a rota, o destino provisório e a abertura de Debug, sem porta (Tarefa 27); e os falsos dos estados da análise (Tarefa 28). Antes da obra nova, a marca `gravado` no rascunho do gasto faz o toque duplo no "Salvar" de dentro da vendida gravar uma vez (Tarefa 29; achado 1). Na segunda, a obra troca a identidade da etapa 3 pela nova, com as peças do PR 1b: o alto em blocos, do título mono ao bloco da venda, com o sólido do Total gasto ou do lucro (Tarefa 30); os afazeres, os gastos por tópico com a barra empilhada (um elemento só para o VoiceOver) e os lançamentos na linha mono (Tarefa 31); o halo do título calibrado pelo laudo e as cenas da obra nova (Tarefa 32); o laudo das marcas, com a barra a 3:1 (Tarefa 33); e o checklist do aparelho do marco 1 (Tarefa 34). O risco é o da obra reescrita, a tela mais usada: os testes de tela das etapas 2 e 3 sobre ela (lista, busca, arrastar, "A vencer", folhas, destaque da linha nova, rolagem e as auditorias) continuam verdes, com os mesmos identificadores, e o laudo inteiro, comparado palavra por palavra com o da ponta do 1b, mostra as cenas da obra mudando, o "<1%" da Pintura na cena "tela Orçamento, só o total, fim" (Tarefa 26) e o resto igual. Fica escondido na `main` até o PR seguinte: a barra de tópicos sem toque e sem "Gráficos ›", nenhuma porta ("Ver gráficos", "Relatório"), as telas da análise só pelo `CUSTTA_ABRIR=graficos:<id>`/`relatorio:<id>` e o `-custta.marcasApagadas`, todos só no Debug (o `nm` do Release confere). Portão da CI: "tudo, com a comparação" (a obra, o `PrincipalView`, as peças e o laudo mudam), e o PR fecha o marco 1: TestFlight com o OK do Giovani e o checklist. **Exceção ao merge automático** (Como entregar): o 1c espera o Giovani antes do merge e da tag. As respostas sobre o tópico fixo "Outros", o "<1%" na tela Orçamento e o halo de 20% vieram dele em 30/10 e já estão nas fatias (Decisões); os desvios do mockup do achado 7 vão a ele nos prints lado a lado do fecho. São 780 linhas de produção (acréscimos + remoções em `app-ios/Custta/` sem `Falsos/` e em `CusttaNucleo/Sources/`, pelo `git diff --numstat` da ponta do 1b à do 1c), abaixo dos ~1.000–1.200 da tabela do spec: a obra da etapa 3 saiu menos do que o spec estimou, porque a lista, os cartões dos meses, o "A vencer", as ações e as folhas ficaram e ganharam a forma nova por opção; fora da conta, os falsos (111), os testes (911) e o checklist (48). Não há o que partir num 1d.

- **Branch:** `feat/obra-em-blocos`
- **Título:** `feat: obra em blocos da identidade nova e costura das telas da análise`

### Mapa de arquivos

| Arquivo | Tarefas |
| --- | --- |
| `app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift` (`gastoPorTopico`, `textoDaParteDaObra`) | 25, 26 |
| `app-ios/Custta/Telas/OrcamentoView.swift` | 25, 26 |
| `app-ios/Custta/Telas/PecasDaTelaOrcamento.swift`, `FolhaDoTopico.swift` (o "<1%" e o falado) | 26 |
| `app-ios/Custta/Analise/TelaDaAnalise.swift` (novo), `Telas/PrincipalView.swift`, `Telas/ObrasView.swift` | 27 |
| `app-ios/Custta/Falsos/VitrineDaAnalise.swift` (novo), `MontarFalso.swift` | 28 |
| `app-ios/Custta/Falsos/VitrineDasPecas.swift` | 25 |
| `app-ios/Custta/Telas/FolhaDoGasto.swift` (a marca `gravado`) | 29 |
| `app-ios/Custta/Telas/BlocosDaObra.swift` (novo: o sólido, os blocos, `solidoDaObra`, `SetaDoBloco`) | 30 |
| `app-ios/Custta/Telas/ObraView.swift` | 30, 31 |
| `app-ios/Custta/Telas/PecasDaObra.swift` (sai a `PilulaDaFase` e o `IndicadoresDaObraView`; o mês e o "A vencer" mono) | 30, 31 |
| `app-ios/Custta/Telas/PecasDoOrcamento.swift` (a linha do orçamento vira bloco) | 30 |
| `app-ios/Custta/Identidade/Blocos.swift` (`NotaDoBloco` com cor; rótulo e nota com `fixedSize`) | 30 |
| `app-ios/Custta/Telas/AfazeresView.swift` (os afazeres em bloco) | 31 |
| `app-ios/Custta/Identidade/BarraEmpilhada.swift` (`faladoDaBarra`; `marcasApagadas`, só Debug) | 31, 33 |
| `app-ios/Custta/Identidade/Aurora.swift` (`naObraMono`), `Titulos.swift` | 32 |
| `app-ios/Custta/Telas/RaizView.swift` (`marcasApagadas`, só Debug) | 33 |
| `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift` | 25, 26 |
| `app-ios/CusttaTests/BarraEmpilhadaTests.swift` | 25 |
| `app-ios/CusttaTests/TelaOrcamentoTests.swift` | 25, 26 |
| `app-ios/CusttaTests/OrcamentoEm375Tests.swift` | 25, 26, 30 |
| `app-ios/CusttaTests/CosturaDaAnaliseTests.swift` (novo) | 27 |
| `app-ios/CusttaTests/DadosDeExemploTests.swift` | 28 |
| `app-ios/CusttaTests/BlocosDaObraTests.swift` (novo), `LinhaDoOrcamentoTests.swift` | 30 |
| `app-ios/CusttaTests/ListaDaObraTests.swift` (novo) | 31 |
| `app-ios/CusttaUITests/DetalheDoTopicoUITests.swift` | 26 |
| `app-ios/CusttaUITests/AnaliseUITests.swift` (novo) | 27, 28 |
| `app-ios/CusttaUITests/ObraUITests.swift` | 30, 31 |
| `app-ios/CusttaUITests/OrcamentoUITests.swift`, `AuditoriaUITests.swift` | 30 |
| `app-ios/CusttaUITests/EstadosUITests.swift` | 31 |
| `app-ios/CusttaUITests/LeituraNoVidroUITests.swift` | 31, 32, 33 |
| `app-ios/CusttaUITests/LaudoDeContraste.swift` | 33 |
| `tests/app-ios.test.cjs` (as guardas das folhas que gravam, da seta dos blocos e do âmbar) | 29, 30, 31 |
| `docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md` (novo) | 34 |

### Para os marcos 2 e 3

- **A obra:** `BlocosDaObra(obra:taxa:hoje:abrirAPagar:)` e `solidoDaObra(_:taxa:)`; o bloco dos gastos por tópico é um elemento só para o VoiceOver, com o identificador `gastosPorTopico` e o valor do `faladoDaBarra(_:topicos:)` (a barra continua `barraDeTopicos`, filha dele na árvore do XCUITest; o VoiceOver lê só o bloco). O PR 2b põe o toque no bloco e o "Gráficos ›" (`RotaDeObras.analise(.graficos(id))`), e o 3b, a fileira de portas depois das ações.
- **O laudo das marcas:** o `marcasApagadas` do environment (só Debug) e o `LaudoDeContraste.medirMarcas(normal:semMarcas:escala:em:)`; o anel, as linhas e as barras dos Gráficos se apagam pelo mesmo environment, e a `BarraApagada` conta como marca.
- **O checklist:** os marcos 2 e 3 acrescentam as seções deles ao `docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md`.
- **O laudo:** toda cena com rolagem fixa tem o `assunto` (o identificador do que ela mede, conferido à vista antes do print; Tarefa 31), e as cenas novas dos Gráficos e do Relatório com rolagem fixa também; a borda de cima num vão nos dois iPhones, como as da obra.
- **A tela provisória da análise fica em branco se a obra some** (apagada em outro aparelho): o `DestinoDaAnalise` mostra um texto vazio e fica no caminho, e o `caminho` já chega a ele sem uso (só se chega pela abertura de Debug). O 2a, que troca o destino pela tela de verdade, tira a rota como a `AfazeresView` (`caminho.removeAll { $0.obraId == … }`, `AfazeresView.swift:177`).
- **A auditoria das ações da fase na letra máxima, num PR de teste no 4a** (achado 9): auditar na AX5 numa obra de lista longa, a `a1` dos falsos da análise (a Casa Alphaville vendida, com os 46 gastos, `dados: "analise"`) e uma cópia pronta dela (`copiaDaCasa("a9", ["fase": .texto("pronta")])`, com uma linha no teste de formato), numa rolagem fixa com o "Desfazer venda" e o "Voltar pra construção" à vista: com conteúdo de sobra, a rolagem não passa do fim nos tamanhos menores que a auditoria experimenta. Prova: a mutação `.lineLimit(1)` no rótulo da `PilulaDaAcao` na letra de acessibilidade reprova pelo identificador `acao-…`; se os achados sem elemento do iOS 26 aparecerem, contam só os do `acao-`. O mesmo PR troca os dois `swipeUp` do `testObraNoMaiorTamanho` por rolagens fixas (como a vitrine das peças), para a auditoria na AX5 cobrir a metade de baixo que o 1c mudou: os afazeres, os gastos por tópico, o "A vencer" e os meses mono.

### Ponto de controle do fim do PR

No Mac, com o produto da ponta do PR copiado (`cp -c`) e rodado pelo seu `.xctestrun`, o laudo no Pro Max e os testes no 18 Pro ao mesmo tempo:

1. **O laudo inteiro no Pro Max, comparado palavra por palavra com o da ponta do 1b** (spec, "A comparação"): `-only-testing:CusttaUITests/LeituraNoVidroUITests` e `node scripts/compara-laudo.mjs <antes> <depois> <pasta> --detalhe`. Expected: `Executed 20 tests, with 0 failures (0 unexpected) in 3324.368 (3324.379) seconds` e o comparador: `TOTAL: 163 cenas, 3096 palavras, 2173 idênticas, 4 mudadas, 0 deslocadas, 1843 sem par, 0 abaixo de 4.5`, mais 15 cenas "SÓ DEPOIS" (as 9 cenas novas da obra em blocos, Tarefa 32, e as 6 da obra rolando nas rolagens novas, Tarefa 31) e 12 "SÓ ANTES" (as 12 da obra rolando nas rolagens da etapa 3), e as 4 tabelas das marcas, fora do comparador. Das 163 cenas casadas, 129 ficam idênticas (entrar, Obras, Ajustes, finalizar saída, as folhas, a tela Orçamento, o detalhe, o A pagar e os afazeres); as 34 com diferença são 28 da obra e da busca (topo, lista, linha aberta, busca, pronta, vendidas, orçamento por tópico, maior letra e Aumentar contraste, todas sem par, como o spec prevê) e seis esperadas: "tela Orçamento, só o total, fim", nos dois temas (o "<1% da obra" da Pintura, Tarefa 26: a palavra passa de 66 a 74 pt, com a mesma nota), e "alerta Não salvou", nos dois botões e nos dois temas (o botão do alerta do sistema, desenhado sobre a obra: o "OK" sobe de 8,24 para 9,12:1 no claro e de 5,77 para 6,70 no escuro; o "Tentar de novo" fica em 9,25 e 6,93, eram 9,37 e 6,98). Nas cenas que mudaram de rolagem, o print mostra o assunto à vista (a pronta na maior letra com as três ações, o aviso dos tópicos inteiro, o vazio da busca com o "Limpar a busca", o "A vencer" e os meses na lista), e nenhuma palavra começa na borda de cima; as únicas palavras na borda são de cenas que não mudam desde o 1b ("A pagar, fim", "tela Orçamento, só o total, fim" e "ajustes, na maior letra, rolada", com as mesmas notas). O laudo de antes é o da ponta do 1b (`ab36f9f`), no mesmo Pro Max e no mesmo dia: o 1b não tem cena da vitrine das peças, e a 1b-1 e a 1b-4 não mexem em tela nenhuma de antes do 1c. As cenas roladas também rodam no 18 Pro, a largura da CI (os Steps de laudo das Tarefas 31 e 32).
2. **Os testes no 18 Pro:** `-only-testing:CusttaTests` e as suítes de tela da obra e das folhas (`ObraUITests`, `AuditoriaUITests`, `OrcamentoUITests`, `GastoUITests`, `FolhasDeOrigemUITests`, `BuscaUITests`, `AfazeresUITests`, `FasesUITests`, `EstadosUITests`, `FolhaDaObraUITests`, `AnaliseUITests`, `DetalheDoTopicoUITests`, `FaltaPoucoUITests` e `VitrineUITests`), com `-skip-testing` só no `testASetaDoIndicadorAbreAFolhaDoAPagar` (cai nos 3 últimos dias do mês, em qualquer commit). Expected: `✔ Test run with 204 tests in 41 suites passed after 15.226 seconds.` e, nas telas, `Executed 201 tests, with 0 failures (0 unexpected) in 4186.230 (4186.343) seconds`, com as 14 classes na contagem por classe (13 da `ObraUITests`, 21 da `AuditoriaUITests`, 29 da `OrcamentoUITests`, 24 da `GastoUITests`, 23 da `FolhasDeOrigemUITests`, 11 da `BuscaUITests`, 15 da `AfazeresUITests`, 9 da `FasesUITests`, 13 da `EstadosUITests`, 15 da `FolhaDaObraUITests`, 3 da `AnaliseUITests`, 17 da `DetalheDoTopicoUITests`, 3 da `FaltaPoucoUITests` e 5 da `VitrineUITests`). O `EstadosUITests/testToqueDuploNoSalvarDaVendidaLancaUmGasto` passa desde a Tarefa 29 (achado 1).
3. **Node:** `npm run test:unit 2>&1 | tail -8`. Expected: `ℹ tests 411`, `ℹ pass 411`, `ℹ fail 0`.
4. **O `nm -a` do Release** (como no Step 5 da Tarefa 33 e no Step 6 da 28: o Release do simulador, sem assinar, no mesmo DerivedData, e o `nm -a`, que conta também os símbolos de depuração, no binário do Release e no `Custta.debug.dylib` do Debug). Expected:
   ```
   marcasApagadas release=0 debug=60
   BlocosDaObra release=327 debug=498
   vitrineDaAnalise release=0 debug=30
   vitrineDoOrcamento release=0 debug=16
   RaizView release=90 debug=400
   ```
   Os ganchos das marcas apagadas e dos falsos da análise ficam fora do Release; o `BlocosDaObra` e a `RaizView` são o controle (na Tarefa 28, antes das marcas, a `RaizView` dá 90 e 384).
5. **Os estados da obra lado a lado com o mockup**, no 18 Pro, com a barra de status em 9:41 e o fundo parado: 12 prints e 11 lado a lado, que vão no corpo do PR (o topo, o meio e o fim no escuro; o topo no claro; sem orçamento; sem gastos; pronta; vendida com lucro e com prejuízo; e o topo na letra máxima, no escuro e no claro). Batem com o mockup: o título mono, a cápsula, o sólido (na vendida, "+R$ 537.682,55" e "+R$ 482.871,47 acima do banco", os números do mockup), os blocos, a barra com a legenda e as linhas mono. As diferenças estão no achado 7; a de dado: a vitrine tem o orçamento total, e o mockup, o por tópico.

### Achados que mudam o spec ou uma decisão

1. **O toque duplo no "Salvar" gravava dois gastos com a obra em blocos: resolvido na Tarefa 29.** No `EstadosUITests/testToqueDuploNoSalvarDaVendidaLancaUmGasto` (lançar de dentro da vendida e tocar duas vezes no "Salvar"), a obra ficava com 48 lançamentos e R$ 842.319,45. A janela é antiga (desde 17/10): o `gravar` da folha troca a obra por trás dela e só fecha a folha no turno seguinte, e até lá a guarda da folha aberta deixa passar o segundo toque. Na `main`, ela é curta demais para o `doubleTap()` do teste (20 de 20, 10 delas com 500 gastos a mais, porque a lista é preguiçosa); só a obra em blocos, mais pesada de montar por trás da folha, a abre. A marca `gravado` no rascunho, ligada antes do `navegar(.trocar(obraId))` e lida na guarda da primeira linha do `salvar()`, fecha a janela. A/B na Tarefa 30, 7 rodadas: com a marca, `Executed 7 tests, with 0 failures`; sem ela (o `FolhaDoGasto.swift` da Tarefa 28), `Executed 7 tests, with 6 failures`. A guarda Node das folhas que gravam passa a exigir a marca.
2. **O halo do título mono fica em 20%, e não no menor passo que fecha.** No laudo do Pro Max, "Alphaville" fica em 3,92:1 sem halo, 4,61 com 10% (pior pixel 4,50), 5,41 com 20% e 5,94 com 30% (na maior letra, 4,20, 4,82, 5,49 e 6,19). Pela regra do app (o menor passo que fecha 4,5:1 no Pro Max, decisão de 10/10), seria 10%; mas o iOS 26 da CI mediu o nome da obra 0,4 abaixo do Pro Max (o claro sem halo, 4,40 contra 4,80; Aurora.swift:193-195), e o laudo é portão lá. O 62% da letra máxima do mockup não é preciso. **Decidido pelo Giovani em 30/10:** 20% em todo tamanho (Tarefa 32); se a CI do PR passar folgada, o 10% pode ser tentado num PR à parte.
3. **O rótulo do bloco cortava na maior letra do 18 Pro.** A auditoria da obra na AX5 achou "Text clipped" em "A pagar · 30 dias", o rótulo do bloco com a seta ao lado (no Pro Max, mais largo, ela passa); a auditoria da vitrine do 1b não via, porque lá nenhum bloco tem seta. O `RotuloDoBloco` (peça do 1b) ganhou o `fixedSize` vertical, como o rótulo da etapa 3 tinha. **Recomendação:** manter na Tarefa 30; as telas da análise herdam.
4. **O prejuízo da venda sai do vermelho.** A etapa 3 punha a nota do lucro negativo no `NegativoNoVidro`; o spec pede o lucro da vendida com prejuízo "em âmbar, nunca vermelho". A nota foi para o `AlertaNoVidro`, o âmbar sobre o vidro já medido no laudo, e uma guarda Node prende o âmbar e barra o `negativoNoVidro` nos blocos (o laudo, que só mede contraste, passaria com o vermelho). **Recomendação:** manter; o laudo inteiro mede a cena "obra vendida com prejuízo".
5. **A obra ficou com 780 linhas, abaixo dos ~1.000–1.200 do spec.** A lista, os cartões dos meses, o "A vencer", as ações e as folhas ficaram e ganharam a forma nova por opção (o `linhaMono` e a seta), e só a `PilulaDaFase` e o `IndicadoresDaObraView` saíram. Não há 1d.
6. **A obra pronta da Casa Alphaville não entrou nos falsos.** O lado a lado da pronta usa o `v2` da vitrine, outra obra pronta: a tela é a mesma (as ações "Registrar venda" e "Voltar pra construção"). **Recomendação:** não criar o falso.
7. **Peças da etapa 3 e do 1b ficaram no lugar das medidas do mockup** (nos prints lado a lado do ponto de controle, no corpo do PR): o cabeçalho dos lançamentos é a pílula da etapa 3 ("Lançamentos 46" em subheadline, que abraça o texto; no mockup, "Lançamentos" em title3 negrito com o chip verde "46", até a lupa); o "A vencer" fechado tem a seta para a direita (no mockup, para baixo) e os meses começam com maiúscula ("Outubro de 2026"; no mockup, "outubro de 2026"); os cartões dos meses ficam com o raio 24 (o bloco do mockup tem 26); as pílulas das ações, com 52 pt e o ícone de 20 (54 e 22); e, na letra máxima, a etiqueta do sólido ("46 lançamentos") e o chip da fase saem maiores que no mockup (o footnote do iOS na AX5), e a etiqueta quebra em duas linhas. **Recomendação:** vão ao Giovani nos prints lado a lado do fecho do marco, e o Verniz decide com ele; nenhuma muda a leitura (o laudo passa) nem os testes, e o cabeçalho dos lançamentos é o que mais se vê.
8. **As marcas da barra passam a 3:1 nos dois vidros.** O pior pedaço é o verde-água no claro, 3,60:1 no Transparente e 3,68 no Fosco (o mockup mediu 3,54); no escuro, o laranja, 4,49. A `BarraApagada` conta como marca quando o gasto por mês chegar (PR 2b), pelo mesmo `marcasApagadas`.
9. **A auditoria da parte 3 na maior letra não alcança mais o "Desfazer venda" nem a ação de vidro da obra pronta; a cena do laudo delas voltou.** Com a obra em blocos, mais alta, as rolagens fixas do `testParte3NoMaiorTamanho` caem em outras peças (no 18 Pro): a v2 a 1600 na Venda estimada e no "Registrar venda", com o "Voltar pra construção" sob a cápsula; a v3 a 1600 no A pagar e no começo da Venda. Mais fundo, com as duas ações à vista (a v2 a 1850 e a v3 a 2250), a auditoria reprova no 18 Pro: quatro "Dynamic Type font sizes are unsupported" sem elemento na v2 e "Text clipped" nos blocos de cima da v3, que ela vê quando experimenta letras menores e a rolagem passa do fim do alto (a v3 a 700 e a 1300 passa); rolar por arrasto até a ação deu o mesmo. As rolagens ficaram, e o comentário diz onde caem (Tarefa 30). A cena do laudo "obra pronta, ações da fase, na maior letra", que também tinha perdido as ações (a 1100, a tela ficava entre o A pagar e a Venda estimada), voltou a medi-las no 1c: a 1960, com o "Registrar venda" e o "Voltar pra construção" à vista nos dois iPhones e conferidos pelo `assunto` (Tarefa 31). **Decidido pelo Orquestrador em 30/10:** a auditoria das pílulas na AX5 fica para um PR de teste no 4a ("Para os marcos 2 e 3"): as pílulas não mudam neste PR, a coluna ficou 8 pt mais larga (16 de borda contra 20), e uma auditoria nova provada só no iOS 27 é risco de rerun no iOS 26.
10. **As rolagens fixas do laudo da obra foram refeitas, e cada cena rolada confere o seu assunto** (Tarefa 31; revisão do PR, achado importante). Com a obra em blocos, a lista desceu 283 pt, e as rolagens da etapa 3 passavam no laudo medindo outra coisa: a "busca, nada achado" media os blocos do alto, com o vazio sob a cápsula; a "obra pronta, ações da fase, na maior letra" ficava sem ação nenhuma. Cada uma ganhou a borda de cima num vão nos dois iPhones e o `assunto`, que reprova a cena quando o que ela mede não está à vista. Duas coisas apareceram só no 18 Pro, a largura da CI, que o portão de antes não rodava: a "obra, linha aberta, claro" reprovava (a g027 aberta tem a nota em duas linhas no 18 Pro, e a fatia de um algarismo cortada pela borda do cartão ficava em 2,83:1; a CI, na mesma largura, corria o risco de cair nela), e passou para a g026; e a obra rolando, dentro dos cartões dos meses, não acha vão comum aos dois iPhones nem a todos os dias (no 18 Pro, a nota de alguns gastos quebra em duas linhas; as linhas mudam com o dia), e uma linha cortada pela borda reprovava no véu (4,04 a 4,35:1 no Pro Max, com o hoje deslocado 10 dias). **Recomendação:** a obra rolando fica com as três rolagens de fora dos meses (612, 883 e 1247, que já mostra as linhas dos meses da borda de cima à de baixo; na CI, a 883 e a 1247), e as cenas roladas do laudo rodam também no 18 Pro nos PRs que mexem na obra, como rodaram neste (Tarefa 31).

### Task 25: Gasto por tópico sem hoje e taxa

Achado 6 do PR 0. O `gastoPorTopico` em Swift (DentroDaObra.swift:62) recebe `hoje:` e `taxaMensal:` só para chamar o `resumoTopico` de cada tópico, que corrige cada gasto até o fim da correção; a lista usa só o bruto e o "% da obra", que não dependem de nenhum dos dois, e o `gastoPorTopico` do `calc.js` recebe só a obra. A cópia passa a fazer a conta do site: soma o bruto de cada tópico na ordem do documento (a mesma soma do `resumoTopico`, então o "% da obra" da lista continua igual ao do detalhe do tópico), tira o "% da obra" do `totalBruto` com o `arredondarJS` e ordena do maior bruto para o menor, estável no empate. O resultado não muda: os vetores do PR 0 (`calc.gastoPorTopico`) conferem, e a conta fica mais leve, sem a correção de cada gasto, para a barra empilhada da obra, que a chama a cada desenho. A tela Orçamento (OrcamentoView.swift:37), a vitrine das peças (VitrineDasPecas.swift:55, Tarefa 22) e os testes, inclusive os da barra empilhada (BarraEmpilhadaTests.swift:20 e 98), param de passar os dois parâmetros. Nenhuma tela muda.

**Files:**
- Modify: `app-ios/Custta/Falsos/VitrineDasPecas.swift`
- Modify: `app-ios/Custta/Telas/OrcamentoView.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift`
- Test (alterar): `app-ios/CusttaTests/BarraEmpilhadaTests.swift`
- Test (alterar): `app-ios/CusttaTests/OrcamentoEm375Tests.swift`
- Test (alterar): `app-ios/CusttaTests/TelaOrcamentoTests.swift`

**Interfaces:**
- Consumes: `totalBruto(_:)` e `arredondarJS(_:)` (núcleo); `ordenadoEstavel(_:_:)` (núcleo).
- Produces: `gastoPorTopico(_ obra: Obra) -> [GastoDoTopico]` (sem `hoje:` nem `taxaMensal:`), que a barra empilhada da obra e os Gráficos chamam.

- [ ] **Step 1: Escrever os testes**

Os testes chamam o `gastoPorTopico` só com a obra: os do núcleo (o modo total, os vetores do site e o empate pela ordem dos gastos) e os do app (as linhas do "Gasto por tópico" da tela Orçamento e a varredura das larguras em 375 pt).

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift
@@ -79,12 +79,12 @@ struct DentroDaObraTests {
         let o = obra([gasto("e1", "2026-09-01", 3_000, topico: "estrutura"), gasto("x1", "2026-09-02", 1_500, topico: "c_apagado"),
                       gasto("f1", "2026-09-03", 3_000, topico: "fundacao"), gasto("l1", "2026-09-04", 2_000, topico: "eletrica"),
                       gasto("l2", "2026-12-04", 2_500, topico: "eletrica")])
-        let linhas = gastoPorTopico(o, hoje: Self.hoje, taxaMensal: 1)
+        let linhas = gastoPorTopico(o)
         #expect(linhas.map(\.id) == ["eletrica", "estrutura", "fundacao", "c_apagado"], "do maior para o menor; no empate, a ordem dos gastos")
         #expect(linhas.map(\.bruto) == [4_500, 3_000, 3_000, 1_500], "o bruto, com o gasto futuro")
         #expect(linhas.map(\.pct) == [38, 25, 25, 13], "o Math.round do site: 37,5 vai a 38")
         #expect(textoDaParteDaObra(linhas[0].pct) == "38% da obra")
-        #expect(gastoPorTopico(obra([]), hoje: Self.hoje, taxaMensal: 1).isEmpty)
+        #expect(gastoPorTopico(obra([])).isEmpty)
         #expect(dicaDoModoTotal == "Para comparar tópico a tópico, toque no lápis e escolha \"Por tópico\".")
     }
 
@@ -92,7 +92,7 @@ struct DentroDaObraTests {
         // calc.js gastoPorTopico (o donut e a legenda da obra e dos Gráficos). Exato: o bruto soma os gastos na ordem do
         // documento, como o site, e o "% da obra" é inteiro.
         for c in Vetores.casos("calc.gastoPorTopico") {
-            let linhas = gastoPorTopico(c.args[0].obra, hoje: Self.hoje, taxaMensal: 1)
+            let linhas = gastoPorTopico(c.args[0].obra)
             confere(.lista(linhas.map { .objeto(["id": .texto($0.id), "bruto": .numero($0.bruto), "pct": .numero($0.pct)]) }),
                     c.saida, .exata, c.caso)
         }
@@ -105,7 +105,7 @@ struct DentroDaObraTests {
         let o = obra([gasto("l1", "2026-09-28", 1_990, topico: "eletrica"), gasto("f1", "2026-09-03", 2_000, topico: "fundacao"),
                       gasto("p1", "2026-09-20", 1_000, topico: "pintura"), gasto("e1", "2026-09-01", 2_000, topico: "estrutura"),
                       gasto("p2", "2026-09-25", 1_000, topico: "pintura"), gasto("a1", "2026-09-02", 2_500, topico: "acabamento")])
-        let linhas = gastoPorTopico(o, hoje: Self.hoje, taxaMensal: 1)
+        let linhas = gastoPorTopico(o)
         #expect(linhas.map(\.id) == ["acabamento", "fundacao", "pintura", "estrutura", "eletrica"])
         #expect(linhas.map(\.bruto) == [2_500, 2_000, 2_000, 2_000, 1_990])
         #expect(linhas.map(\.pct) == [24, 19, 19, 19, 19], "o empate é do bruto, não do % arredondado")
```

Em `app-ios/CusttaTests/BarraEmpilhadaTests.swift`:

```diff
--- a/app-ios/CusttaTests/BarraEmpilhadaTests.swift
+++ b/app-ios/CusttaTests/BarraEmpilhadaTests.swift
@@ -17,7 +17,7 @@ struct BarraEmpilhadaTests {
         let estado = Estado.de(.objeto(["obras": .lista([.objeto([
             "id": .texto("o"), "nome": .texto("Casa"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
             "gastos": .lista(gastos)])])]))
-        return pedacosDoAnel(gastoPorTopico(estado.obras[0], hoje: "2026-10-29", taxaMensal: 1))
+        return pedacosDoAnel(gastoPorTopico(estado.obras[0]))
     }
 
     @Test func coresDoAnelEOutrosCinza() {
@@ -95,7 +95,7 @@ struct BarraEmpilhadaTests {
     /// bloco passava 1/3 de pt na letra máxima).
     @Test func barraDeTopicosNaoPassaDaLargura() {
         let estado = Estado.de(DadosDeExemplo.vitrine())
-        let pedacos = pedacosDoAnel(gastoPorTopico(estado.obras[0], hoje: "2026-10-29", taxaMensal: 1))
+        let pedacos = pedacosDoAnel(gastoPorTopico(estado.obras[0]))
         let topicos = mapaDeTopicos(estado.config.topicosProprios)
         for letra in DynamicTypeSize.allCases {
             for largura in [CGFloat(343), 370, 408] {
```

Em `app-ios/CusttaTests/OrcamentoEm375Tests.swift`:

```diff
--- a/app-ios/CusttaTests/OrcamentoEm375Tests.swift
+++ b/app-ios/CusttaTests/OrcamentoEm375Tests.swift
@@ -37,8 +37,7 @@ struct OrcamentoEm375Tests {
         let topicos = mapaDeTopicos(porTopico.config.topicosProprios)
         let previstos = linhasPorTopico(resumo, topicos: topicos, gastos: casa.gastos).filter(\.abre)
         let fora = linhasForaDoOrcamento(resumo, topicos: topicos)
-        let porGasto = linhasDoGastoPorTopico(gastoPorTopico(casa, hoje: dataLocalISO(.now, fuso: .current),
-                                                             taxaMensal: porTopico.config.taxaMensal), topicos: topicos)
+        let porGasto = linhasDoGastoPorTopico(gastoPorTopico(casa), topicos: topicos)
         #expect(!previstos.isEmpty && fora.count == 2 && !porGasto.isEmpty, "as três listas")
         for linha in previstos + fora + porGasto {
             #expect(linha.abre, "\(linha.nome) com a seta")
```

Em `app-ios/CusttaTests/TelaOrcamentoTests.swift`:

```diff
--- a/app-ios/CusttaTests/TelaOrcamentoTests.swift
+++ b/app-ios/CusttaTests/TelaOrcamentoTests.swift
@@ -53,7 +53,7 @@ struct TelaOrcamentoTests {
         #expect(linhasForaDoOrcamento(r, topicos: mapaDeTopicos([])).map(\.abre) == [true], "o fora do orçamento abre")
         let total = obra(.objeto(["modo": .texto("total"), "total": .numero(1_000_000)]),
                          gastos: [("terreno", 319_847.85), ("revest", 0), ("c_meu", 2_000)])
-        let porGasto = linhasDoGastoPorTopico(gastoPorTopico(total, hoje: "2026-10-20", taxaMensal: 1), topicos: mapaDeTopicos([]))
+        let porGasto = linhasDoGastoPorTopico(gastoPorTopico(total), topicos: mapaDeTopicos([]))
         #expect(porGasto.map(\.id) == ["terreno", "c_meu", "revest"])
         #expect(porGasto.allSatisfy { $0.abre }, "no gasto por tópico, todas abrem, mesmo a de R$ 0,00")
     }
@@ -62,7 +62,7 @@ struct TelaOrcamentoTests {
         let o = obra(.objeto(["modo": .texto("total"), "total": .numero(1_000_000)]),
                      gastos: [("terreno", 319_847.85), ("revest", 76_700), ("c_meu", 2_000)])
         let proprio = TopicoProprio(campos: ["id": .texto("c_meu"), "nm": .texto("Gesso"), "ic": .texto("etiqueta")])
-        let linhas = linhasDoGastoPorTopico(gastoPorTopico(o, hoje: "2026-10-20", taxaMensal: 1), topicos: mapaDeTopicos([proprio]))
+        let linhas = linhasDoGastoPorTopico(gastoPorTopico(o), topicos: mapaDeTopicos([proprio]))
         #expect(linhas.map(\.nome) == ["Terreno", "Cerâmica", "Gesso"])
         #expect(linhas.map(\.gasto) == ["R$ 320 mil", "R$ 77 mil", "R$ 2 mil"])
         #expect(linhas.map(\.frase) == ["80% da obra", "19% da obra", "1% da obra"])
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter DentroDaObraTests 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'DentroDaObraTests.swift:[0-9:]* error: missing [^|]*' | sort -t: -k2,2n -u
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E '^/.*error: missing' | sed 's/^.*CusttaTests\//CusttaTests\//' | sort -u
```
Expected: o núcleo e o `CusttaTests` não compilam (o compilador do app para no primeiro arquivo):
```
DentroDaObraTests.swift:82:37: error: missing arguments for parameters 'hoje', 'taxaMensal' in call
DentroDaObraTests.swift:87:32: error: missing arguments for parameters 'hoje', 'taxaMensal' in call
DentroDaObraTests.swift:95:41: error: missing arguments for parameters 'hoje', 'taxaMensal' in call
DentroDaObraTests.swift:108:37: error: missing arguments for parameters 'hoje', 'taxaMensal' in call
CusttaTests/OrcamentoEm375Tests.swift:40:62: error: missing arguments for parameters 'hoje', 'taxaMensal' in call
```

- [ ] **Step 3: Implementar**

O dicionário guarda o bruto e o vetor `ids`, a ordem em que cada tópico aparece: é o `Map` do site, que dá o empate pela ordem dos gastos. A soma começa em zero e segue a ordem do documento, como o `(por.get(g.topico) || 0) + g.valor` do `calc.js`, para o bruto sair igual ao do site até o último bit.

Em `app-ios/Custta/Falsos/VitrineDasPecas.swift`:

```diff
--- a/app-ios/Custta/Falsos/VitrineDasPecas.swift
+++ b/app-ios/Custta/Falsos/VitrineDasPecas.swift
@@ -52,7 +52,7 @@ struct VitrineDasPecas: View {
                 .accessibilityIdentifier("vitrine-ambar")
                 BlocoDeVidro {
                     Text("Gastos por tópico").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto)).padding(.bottom, 8)
-                    BarraDeTopicos(pedacos: pedacosDoAnel(gastoPorTopico(casa, hoje: hoje, taxaMensal: estado.config.taxaMensal)),
+                    BarraDeTopicos(pedacos: pedacosDoAnel(gastoPorTopico(casa)),
                                    topicos: mapaDeTopicos(estado.config.topicosProprios))
                 }
                 .accessibilityElement(children: .contain)
```

Em `app-ios/Custta/Telas/OrcamentoView.swift`:

```diff
--- a/app-ios/Custta/Telas/OrcamentoView.swift
+++ b/app-ios/Custta/Telas/OrcamentoView.swift
@@ -34,7 +34,7 @@ struct OrcamentoView: View {
 
     private func conteudo(_ obra: Obra, _ r: ResumoOrcamento, estado: Estado) -> some View {
         let topicos = mapaDeTopicos(estado.config.topicosProprios)
-        let gastos = r.modo == "topicos" ? [] : gastoPorTopico(obra, hoje: dataLocalISO(.now, fuso: .current), taxaMensal: estado.config.taxaMensal)
+        let gastos = r.modo == "topicos" ? [] : gastoPorTopico(obra)
         return ScrollView {
             LazyVStack(alignment: .leading, spacing: 10) {
                 TituloDaObra(nome: "Orçamento", identificador: "tituloDoOrcamento")
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift
@@ -57,14 +57,19 @@ public struct GastoDoTopico: Equatable, Sendable, Identifiable {
 
 /// `gastoPorTopico` do calc.js (o donut e a legenda da obra e dos Gráficos), também o "Gasto por tópico" do modo total: cada
 /// tópico com gasto, com o bruto e o "% da obra" do resumo do tópico, para o número ser o mesmo que o detalhe mostra ao abrir.
-/// Do maior bruto para o menor e, no empate, o tópico que aparece primeiro nos gastos (o sort do JavaScript é estável).
-/// `hoje` e `taxaMensal` não mudam o resultado.
-public func gastoPorTopico(_ obra: Obra, hoje: String, taxaMensal: Double) -> [GastoDoTopico] {
+/// Do maior bruto para o menor e, no empate, o tópico que aparece primeiro nos gastos (o sort do JavaScript é estável). O
+/// bruto soma os gastos do tópico na ordem do documento, como o `resumoTopico`, e não depende de hoje nem da taxa.
+public func gastoPorTopico(_ obra: Obra) -> [GastoDoTopico] {
     var ids: [String] = []
-    for g in obra.gastos where !ids.contains(g.topico) { ids.append(g.topico) }
+    var brutos: [String: Double] = [:]
+    for g in obra.gastos {
+        if brutos[g.topico] == nil { ids.append(g.topico) }
+        brutos[g.topico, default: 0] += g.valor
+    }
+    let total = totalBruto(obra)
     let linhas = ids.map { id in
-        let r = resumoTopico(obra, topico: id, hoje: hoje, taxaMensal: taxaMensal)
-        return GastoDoTopico(id: id, bruto: r.bruto, pct: r.pct)
+        let bruto = brutos[id] ?? 0
+        return GastoDoTopico(id: id, bruto: bruto, pct: total > 0 ? arredondarJS(bruto / total * 100) : 0)
     }
     return ordenadoEstavel(linhas) { $0.bruto > $1.bruto }
 }
```

- [ ] **Step 4: Ver passar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter DentroDaObraTests 2>&1 | tail -1
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never '-only-testing:CusttaTests/TelaOrcamentoTests/abreODetalheNasTresListas()' '-only-testing:CusttaTests/TelaOrcamentoTests/gastoPorTopicoComAParteDaObra()' -only-testing:CusttaTests/OrcamentoEm375Tests 2>&1 | grep -E "Test run with"
```
Expected: `✔ Test run with 15 tests in 1 suite passed`; `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 5 tests in 2 suites passed`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Falsos/VitrineDasPecas.swift app-ios/Custta/Telas/OrcamentoView.swift app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift app-ios/CusttaTests/BarraEmpilhadaTests.swift app-ios/CusttaTests/OrcamentoEm375Tests.swift app-ios/CusttaTests/TelaOrcamentoTests.swift
git commit -m "refactor: gasto por tópico sem hoje e taxa no núcleo" -m "O gastoPorTopico em Swift recebia hoje e taxaMensal só para chamar o resumoTopico de cada tópico, que corrige cada gasto até o fim da correção; a lista usa só o bruto e o \"% da obra\", que não dependem de nenhum dos dois. O calc.js recebe só a obra. A cópia passa a somar o bruto de cada tópico na ordem do documento, como o resumoTopico e o site, e a tirar o \"% da obra\" do total bruto, com o mesmo arredondamento: o resultado não muda, e os vetores do PR 0 conferem." -m "A tela Orçamento e os testes param de passar os dois parâmetros. Era o achado 6 do PR 0, deixado para o PR que mexe na obra."
```

### Task 26: "<1%" no "% da obra" do detalhe do tópico e da tela Orçamento

Confirmação 7 do Giovani (29/10): a folha do detalhe do tópico fica como na etapa 3, e nesta etapa só o "% da obra" muda, com o "<1%" da lista e do anel (spec, "Regras: iguais ao site", gasto por tópico, e "Decisões tomadas por recomendação", o % do meio do anel). Hoje o `detalheDoTopico` monta "N gastos · {pct}% da obra" com o `Math.round` do site (DentroDaObra.swift:197, `resumoTopico`, Correcao.swift:49): um tópico com dinheiro e menos de 1% da obra aparece como "0% da obra" ou "1% da obra". A regra nova é a do `porcentoDoTopico` do PR 0b (Pedacos.swift:118): "<1%" quando o % verdadeiro fica entre 0 e 1, exclusive; o resto continua com o `Math.round` (37,5% vai a 38%), e sem dinheiro, ou sem total, "0%". O `textoDaParteDaObra` (DentroDaObra.swift:78) passa a receber o bruto e o total e devolve o `porcentoDoTopico` com " da obra". A mesma função monta a frase da lista "Gasto por tópico" da tela Orçamento no modo total (PecasDaTelaOrcamento.swift:58), que abre o detalhe: a lista muda junto, para o número não mudar ao abrir a folha, e as duas passam o mesmo bruto (a soma do tópico na ordem do documento) e o mesmo total (`totalBruto(obra)`), o que garante o mesmo texto até no arredondamento. Na Casa Alphaville da vitrine, a Pintura (R$ 6.900,00 de R$ 842.317,45, 0,8%) passa de "1% da obra" para "<1% da obra" na linha e no detalhe; nenhum outro tópico da vitrine fica abaixo de 1%. O `pct` do `GastoDoTopico` e do `ResumoDoTopico` continua o do site, conferido pelos vetores. O VoiceOver lê esse "<1%" como "menos de 1%" na linha e no detalhe, como na barra empilhada (Tarefa 22): o `Text` da frase (`FraseDoTopicoNoOrcamento`, PecasDaTelaOrcamento.swift:240) e o da linha do detalhe (FolhaDoTopico.swift:160) ganham o `.accessibilityLabel` com o `porcentoFalado` do PR 0b, e o texto à vista não muda. Sem isso, o mesmo número seria falado de dois jeitos, e a leitura do "<" dependeria do nível de pontuação do VoiceOver.

**Files:**
- Modify: `app-ios/Custta/Telas/FolhaDoTopico.swift`
- Modify: `app-ios/Custta/Telas/OrcamentoView.swift`
- Modify: `app-ios/Custta/Telas/PecasDaTelaOrcamento.swift`
- Modify: `app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift`
- Test (alterar): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift`
- Test (alterar): `app-ios/CusttaTests/OrcamentoEm375Tests.swift`
- Test (alterar): `app-ios/CusttaTests/TelaOrcamentoTests.swift`
- Test (alterar): `app-ios/CusttaUITests/DetalheDoTopicoUITests.swift`

**Interfaces:**
- Consumes: `porcentoDoTopico(_:total:)` e `porcentoFalado(_:)` (PR 0b, Pedacos.swift); `totalBruto(_:)`; `gastoPorTopico(_:)` (Tarefa anterior).
- Produces: `textoDaParteDaObra(_ bruto: Double, total: Double) -> String` e `linhasDoGastoPorTopico(_ gastos: [GastoDoTopico], total: Double, topicos: [String: Topico]) -> [LinhaDeTopicoDoOrcamento]`.

- [ ] **Step 1: Escrever os testes**

No núcleo, o texto nos dois lados do 1% (0,4% e 0,5%, que o site mostraria como 0% e 1%), no 1% exato e sem dinheiro, e a linha do detalhe de dois tópicos pequenos. No app, a frase da lista do modo total ("<1% da obra" para o tópico de 0,5%) e, na tela, a linha da Pintura e o detalhe que ela abre com o mesmo "<1%", que o VoiceOver lê "menos de 1% da obra".

Em `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift`:

```diff
--- a/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift
+++ b/app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift
@@ -83,11 +83,25 @@ struct DentroDaObraTests {
         #expect(linhas.map(\.id) == ["eletrica", "estrutura", "fundacao", "c_apagado"], "do maior para o menor; no empate, a ordem dos gastos")
         #expect(linhas.map(\.bruto) == [4_500, 3_000, 3_000, 1_500], "o bruto, com o gasto futuro")
         #expect(linhas.map(\.pct) == [38, 25, 25, 13], "o Math.round do site: 37,5 vai a 38")
-        #expect(textoDaParteDaObra(linhas[0].pct) == "38% da obra")
+        #expect(textoDaParteDaObra(linhas[0].bruto, total: 12_000) == "38% da obra")
         #expect(gastoPorTopico(obra([])).isEmpty)
         #expect(dicaDoModoTotal == "Para comparar tópico a tópico, toque no lápis e escolha \"Por tópico\".")
     }
 
+    /// O "% da obra" da lista "Gasto por tópico" e do detalhe do tópico: o `porcentoDoTopico` da etapa 4, com "<1%" quando o
+    /// tópico tem dinheiro e não chega a 1% (o site mostraria 0% ou 1%), sobre o mesmo bruto e o mesmo total nas duas telas.
+    @Test func parteDaObraAbaixoDeUmPorCento() {
+        #expect(textoDaParteDaObra(4, total: 1_000) == "<1% da obra", "o site diria 0%")
+        #expect(textoDaParteDaObra(5, total: 1_000) == "<1% da obra", "o site diria 1%")
+        #expect(textoDaParteDaObra(10, total: 1_000) == "1% da obra")
+        #expect(textoDaParteDaObra(0, total: 1_000) == "0% da obra" && textoDaParteDaObra(0, total: 0) == "0% da obra")
+        let o = obra([gasto("r1", "2026-09-01", 99_100, topico: "revest"), gasto("p1", "2026-09-02", 500, topico: "pintura"),
+                      gasto("d1", "2026-09-03", 400, topico: "projeto")])
+        #expect(detalheDoTopico(o, topico: "pintura", hoje: Self.hoje, taxaMensal: 1).linha == "1 gasto · <1% da obra")
+        #expect(detalheDoTopico(o, topico: "projeto", hoje: Self.hoje, taxaMensal: 1).linha == "1 gasto · <1% da obra")
+        #expect(detalheDoTopico(o, topico: "revest", hoje: Self.hoje, taxaMensal: 1).linha == "1 gasto · 99% da obra")
+    }
+
     @Test func gastoPorTopicoComoOSite() {
         // calc.js gastoPorTopico (o donut e a legenda da obra e dos Gráficos). Exato: o bruto soma os gastos na ordem do
         // documento, como o site, e o "% da obra" é inteiro.
```

Em `app-ios/CusttaTests/OrcamentoEm375Tests.swift`:

```diff
--- a/app-ios/CusttaTests/OrcamentoEm375Tests.swift
+++ b/app-ios/CusttaTests/OrcamentoEm375Tests.swift
@@ -37,7 +37,7 @@ struct OrcamentoEm375Tests {
         let topicos = mapaDeTopicos(porTopico.config.topicosProprios)
         let previstos = linhasPorTopico(resumo, topicos: topicos, gastos: casa.gastos).filter(\.abre)
         let fora = linhasForaDoOrcamento(resumo, topicos: topicos)
-        let porGasto = linhasDoGastoPorTopico(gastoPorTopico(casa), topicos: topicos)
+        let porGasto = linhasDoGastoPorTopico(gastoPorTopico(casa), total: totalBruto(casa), topicos: topicos)
         #expect(!previstos.isEmpty && fora.count == 2 && !porGasto.isEmpty, "as três listas")
         for linha in previstos + fora + porGasto {
             #expect(linha.abre, "\(linha.nome) com a seta")
```

Em `app-ios/CusttaTests/TelaOrcamentoTests.swift`:

```diff
--- a/app-ios/CusttaTests/TelaOrcamentoTests.swift
+++ b/app-ios/CusttaTests/TelaOrcamentoTests.swift
@@ -53,7 +53,7 @@ struct TelaOrcamentoTests {
         #expect(linhasForaDoOrcamento(r, topicos: mapaDeTopicos([])).map(\.abre) == [true], "o fora do orçamento abre")
         let total = obra(.objeto(["modo": .texto("total"), "total": .numero(1_000_000)]),
                          gastos: [("terreno", 319_847.85), ("revest", 0), ("c_meu", 2_000)])
-        let porGasto = linhasDoGastoPorTopico(gastoPorTopico(total), topicos: mapaDeTopicos([]))
+        let porGasto = linhasDoGastoPorTopico(gastoPorTopico(total), total: totalBruto(total), topicos: mapaDeTopicos([]))
         #expect(porGasto.map(\.id) == ["terreno", "c_meu", "revest"])
         #expect(porGasto.allSatisfy { $0.abre }, "no gasto por tópico, todas abrem, mesmo a de R$ 0,00")
     }
@@ -62,10 +62,10 @@ struct TelaOrcamentoTests {
         let o = obra(.objeto(["modo": .texto("total"), "total": .numero(1_000_000)]),
                      gastos: [("terreno", 319_847.85), ("revest", 76_700), ("c_meu", 2_000)])
         let proprio = TopicoProprio(campos: ["id": .texto("c_meu"), "nm": .texto("Gesso"), "ic": .texto("etiqueta")])
-        let linhas = linhasDoGastoPorTopico(gastoPorTopico(o), topicos: mapaDeTopicos([proprio]))
+        let linhas = linhasDoGastoPorTopico(gastoPorTopico(o), total: totalBruto(o), topicos: mapaDeTopicos([proprio]))
         #expect(linhas.map(\.nome) == ["Terreno", "Cerâmica", "Gesso"])
         #expect(linhas.map(\.gasto) == ["R$ 320 mil", "R$ 77 mil", "R$ 2 mil"])
-        #expect(linhas.map(\.frase) == ["80% da obra", "19% da obra", "1% da obra"])
+        #expect(linhas.map(\.frase) == ["80% da obra", "19% da obra", "<1% da obra"], "o Gesso tem 0,5%: o site diria 1%")
         #expect(linhas.allSatisfy { $0.previsto == nil && $0.item == nil && !$0.fraseEmAlerta })
     }
 
```

Em `app-ios/CusttaUITests/DetalheDoTopicoUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/DetalheDoTopicoUITests.swift
+++ b/app-ios/CusttaUITests/DetalheDoTopicoUITests.swift
@@ -176,6 +176,18 @@ final class DetalheDoTopicoUITests: XCTestCase {
         linhaInteiraEFechar(app, "gastoTopico-terreno", quadro)
     }
 
+    /// No modo total, a Pintura da Casa Alphaville (R$ 6.900,00 de R$ 842.317,45, 0,8%) mostra "<1% da obra" na linha e no
+    /// detalhe que ela abre: o site mostraria "1%" (o `Math.round`), e a confirmação 7 da etapa 4 pede o "<1%" na folha. O
+    /// VoiceOver lê "menos de 1% da obra" nos dois, como na barra empilhada.
+    func testParteAbaixoDeUmPorCentoNaLinhaENoDetalhe() {
+        let app = abrirOrcamento("vitrine")
+        let linha = app.elemento("gastoTopico-pintura")
+        app.rolarAte(linha)
+        XCTAssertTrue(linha.label.contains("menos de 1% da obra"), linha.label)
+        guard abrirPelaLinha(app, "gastoTopico-pintura") != nil else { return }
+        confere(app.elemento("resumoDoTopico"), contem: ["3 gastos · menos de 1% da obra", "R$\u{a0}6.900,00"])
+    }
+
     func testObraApagadaEmOutroAparelhoFechaODetalhe() {
         let app = abrirDetalhe("revest", extra: ["CUSTTA_APAGAR_REMOTO": "v1@0"])
         notify_post("br.com.custta.falso.apagarRemoto")
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter DentroDaObraTests 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -o 'DentroDaObraTests.swift:[0-9:]* error: [^|]*' | sort -t: -k2,2n -u | head -3
git stash push -q -- app-ios/CusttaTests app-ios/CusttaNucleo/Tests
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/DetalheDoTopicoUITests/testParteAbaixoDeUmPorCentoNaLinhaENoDetalhe 2>&1 | grep -oE 'XCTAssertTrue failed - .*' | head -2
git stash pop -q
```
Expected: o núcleo não compila, e a tela, com os testes de unidade guardados, mostra o "1%" do site na linha e no detalhe:
```
DentroDaObraTests.swift:86:60: error: extra argument 'total' in call
DentroDaObraTests.swift:94:46: error: extra argument 'total' in call
DentroDaObraTests.swift:95:46: error: extra argument 'total' in call
** TEST BUILD SUCCEEDED **
XCTAssertTrue failed - Pintura, R$ 6,9 mil, 1% da obra
XCTAssertTrue failed - "3 gastos · menos de 1% da obra" em "3 gastos · 1% da obra, R$ 6.900,00, corrigido: R$ 6.904,52"
```

- [ ] **Step 3: Implementar**

A tela Orçamento monta as linhas uma vez, com o total da obra, em vez de passar os tópicos e montar as linhas dentro do `ForEach`.

Em `app-ios/Custta/Telas/FolhaDoTopico.swift`:

```diff
--- a/app-ios/Custta/Telas/FolhaDoTopico.swift
+++ b/app-ios/Custta/Telas/FolhaDoTopico.swift
@@ -157,7 +157,9 @@ private struct ResumoDoDetalhe: View {
                                 .frame(width: 34, height: 34)
                                 .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 10))
                         }
+                        // O VoiceOver lê o "<1%" como "menos de 1%", como na barra empilhada e na lista.
                         Text(detalhe.linha)
+                            .accessibilityLabel(porcentoFalado(detalhe.linha))
                             .font(.subheadline)
                             .foregroundStyle(paleta.cor(.secundarioTransparente))
                             .fixedSize(horizontal: false, vertical: true)
```

Em `app-ios/Custta/Telas/OrcamentoView.swift`:

```diff
--- a/app-ios/Custta/Telas/OrcamentoView.swift
+++ b/app-ios/Custta/Telas/OrcamentoView.swift
@@ -34,7 +34,7 @@ struct OrcamentoView: View {
 
     private func conteudo(_ obra: Obra, _ r: ResumoOrcamento, estado: Estado) -> some View {
         let topicos = mapaDeTopicos(estado.config.topicosProprios)
-        let gastos = r.modo == "topicos" ? [] : gastoPorTopico(obra)
+        let porGasto = r.modo == "topicos" ? [] : linhasDoGastoPorTopico(gastoPorTopico(obra), total: totalBruto(obra), topicos: topicos)
         return ScrollView {
             LazyVStack(alignment: .leading, spacing: 10) {
                 TituloDaObra(nome: "Orçamento", identificador: "tituloDoOrcamento")
@@ -64,10 +64,10 @@ struct OrcamentoView: View {
                         }
                     }
                 } else {
-                    PilulaDaLista(titulo: "Gasto por tópico", quantidade: gastos.count, identificador: "gastoPorTopico")
+                    PilulaDaLista(titulo: "Gasto por tópico", quantidade: porGasto.count, identificador: "gastoPorTopico")
                         .padding(.top, 14)
                     CartaoDaLista {
-                        ForEach(Array(linhasDoGastoPorTopico(gastos, topicos: topicos).enumerated()), id: \.element.id) { i, linha in
+                        ForEach(Array(porGasto.enumerated()), id: \.element.id) { i, linha in
                             if i > 0 { LinhaFina().padding(.leading, 67) }
                             LinhaDeTopicoNoOrcamento(linha: linha, identificador: "gastoTopico-\(linha.id)", abrir: { abrirDetalhe(linha.id) })
                         }
```

Em `app-ios/Custta/Telas/PecasDaTelaOrcamento.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDaTelaOrcamento.swift
+++ b/app-ios/Custta/Telas/PecasDaTelaOrcamento.swift
@@ -50,12 +50,13 @@ func linhasForaDoOrcamento(_ r: ResumoOrcamento, topicos: [String: Topico]) -> [
     }
 }
 
-/// O "Gasto por tópico" do modo total: o bruto e o "% da obra" de cada tópico com gasto; todas abrem o detalhe.
-func linhasDoGastoPorTopico(_ gastos: [GastoDoTopico], topicos: [String: Topico]) -> [LinhaDeTopicoDoOrcamento] {
+/// O "Gasto por tópico" do modo total: o bruto e o "% da obra" de cada tópico com gasto ("<1%" abaixo de 1%), sobre o
+/// `totalBruto` da obra, o mesmo do detalhe que a linha abre; todas abrem o detalhe.
+func linhasDoGastoPorTopico(_ gastos: [GastoDoTopico], total: Double, topicos: [String: Topico]) -> [LinhaDeTopicoDoOrcamento] {
     gastos.map { g in
         let t = topico(g.id, topicos)
         return LinhaDeTopicoDoOrcamento(id: g.id, nome: t.nome, icone: t.icone, gasto: moedaCurtaSemZero(g.bruto), previsto: nil,
-                                        item: nil, frase: textoDaParteDaObra(g.pct), abre: true)
+                                        item: nil, frase: textoDaParteDaObra(g.bruto, total: total), abre: true)
     }
 }
 
@@ -229,7 +230,7 @@ struct LinhaDeTopicoNoOrcamento: View {
 }
 
 /// A frase do site embaixo da barra ("Faltam R$ 3,3 mil — 96%"; no modo total, "38% da obra"), no secundário; a do
-/// "passou", em semibold, no âmbar sobre o vidro.
+/// "passou", em semibold, no âmbar sobre o vidro. O VoiceOver lê o "<1%" como "menos de 1%", como na barra empilhada.
 struct FraseDoTopicoNoOrcamento: View {
     let texto: String
     let alerta: Bool
@@ -238,6 +239,7 @@ struct FraseDoTopicoNoOrcamento: View {
 
     var body: some View {
         Text(texto)
+            .accessibilityLabel(porcentoFalado(texto))
             .font(.footnote.weight(alerta ? .semibold : .regular))
             .foregroundStyle(paleta.cor(alerta ? .alertaNoVidro : vidro.secundario))
             .fixedSize(horizontal: false, vertical: true)
```

Em `app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift`:

```diff
--- a/app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift
+++ b/app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift
@@ -74,8 +74,10 @@ public func gastoPorTopico(_ obra: Obra) -> [GastoDoTopico] {
     return ordenadoEstavel(linhas) { $0.bruto > $1.bruto }
 }
 
-/// "38% da obra".
-public func textoDaParteDaObra(_ pct: Double) -> String { "\(numeroJS(pct))% da obra" }
+/// "38% da obra" e, quando o tópico tem dinheiro e não chega a 1%, "<1% da obra" (o `porcentoDoTopico` da barra e do anel da
+/// etapa 4; o site mostraria 0% ou 1%). A lista "Gasto por tópico" e o detalhe do tópico passam o mesmo bruto e o mesmo total
+/// (`totalBruto`), para o número não mudar ao abrir o detalhe.
+public func textoDaParteDaObra(_ bruto: Double, total: Double) -> String { porcentoDoTopico(bruto, total: total) + " da obra" }
 
 /// A dica do fim da tela Orçamento no modo total.
 public let dicaDoModoTotal = "Para comparar tópico a tópico, toque no lápis e escolha \"Por tópico\"."
@@ -174,7 +176,7 @@ public func fraseDoOrcamentoNoDetalhe(_ item: ItemOrcamento) -> FraseDoOrcamento
 /// A folha do detalhe do tópico.
 public struct DetalheDoTopico: Equatable, Sendable {
     public let resumo: ResumoDoTopico
-    /// "6 gastos · 12% da obra".
+    /// "6 gastos · 12% da obra" ("<1% da obra" abaixo de 1%).
     public let linha: String
     /// "corrigido: R$ …".
     public let corrigido: String
@@ -194,7 +196,8 @@ public func detalheDoTopico(_ obra: Obra, topico: String, hoje: String, taxaMens
     } else {
         orcamento = .nenhum
     }
-    return DetalheDoTopico(resumo: r, linha: "\(r.qtd) gasto\(r.qtd == 1 ? "" : "s") · \(textoDaParteDaObra(r.pct))",
+    let parte = textoDaParteDaObra(r.bruto, total: totalBruto(obra))
+    return DetalheDoTopico(resumo: r, linha: "\(r.qtd) gasto\(r.qtd == 1 ? "" : "s") · \(parte)",
                            corrigido: "corrigido: " + moeda(r.corrigido), orcamento: orcamento,
                            aVencer: ordenados.filter { menorJS(hoje, $0.data) }.reversed(),
                            pagos: ordenados.filter { !menorJS(hoje, $0.data) })
```

- [ ] **Step 4: Ver passar**

Run:
```bash
TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo --filter DentroDaObraTests 2>&1 | tail -1
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never '-only-testing:CusttaTests/TelaOrcamentoTests/abreODetalheNasTresListas()' '-only-testing:CusttaTests/TelaOrcamentoTests/gastoPorTopicoComAParteDaObra()' -only-testing:CusttaTests/OrcamentoEm375Tests 2>&1 | grep -E "Test run with"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/DetalheDoTopicoUITests -only-testing:CusttaUITests/OrcamentoUITests 2>&1 | grep -E "Executed [0-9]+ tests" | tail -1
```
Expected: `✔ Test run with 16 tests in 1 suite passed`; `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 5 tests in 2 suites passed`; `Executed 46 tests, with 0 failures` (os 17 do `DetalheDoTopicoUITests`, com o novo, e os 29 do `OrcamentoUITests`, que inclui a extensão do `FolhaDoOrcamentoUITests.swift`), em ~14 min no 18 Pro (828 s).

- [ ] **Step 5: Conferir o laudo da tela Orçamento**

A cena "tela Orçamento, só o total, fim" (LeituraNoVidroUITests.swift:546) mostra a linha da Pintura, que ganha o "<".

Run:
```bash
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDoOrcamento 2>&1 | grep -E "^leitura \|" | sort -u | grep -c " 0 abaixo"
```
Expected: `12`: as 12 cenas (6 telas, nos dois temas) sem nenhuma palavra abaixo de 4,5:1; a "só o total, fim" com 28 palavras, pior nota 5,64 no escuro e 6,59 no claro, no 18 Pro (~4 min). A comparação palavra por palavra com o commit anterior fica para o laudo inteiro do fim do PR.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Telas/FolhaDoTopico.swift app-ios/Custta/Telas/OrcamentoView.swift app-ios/Custta/Telas/PecasDaTelaOrcamento.swift app-ios/CusttaNucleo/Sources/CusttaNucleo/DentroDaObra.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/DentroDaObraTests.swift app-ios/CusttaTests/OrcamentoEm375Tests.swift app-ios/CusttaTests/TelaOrcamentoTests.swift app-ios/CusttaUITests/DetalheDoTopicoUITests.swift
git commit -m "feat: \"<1%\" no % da obra do detalhe do tópico e da tela Orçamento" -m "O \"% da obra\" da folha do detalhe do tópico arredondava como o site (Math.round): um tópico com dinheiro e menos de 1% da obra aparecia como \"0% da obra\" ou \"1% da obra\". A etapa 4 mostra \"<1%\" no anel e na barra empilhada, e o Giovani confirmou em 29/10 que a folha, nesta etapa, só muda nisso (confirmação 7)." -m "O textoDaParteDaObra passa a receber o bruto e o total e usa o porcentoDoTopico do núcleo. A lista \"Gasto por tópico\" da tela Orçamento, no modo total, usa o mesmo texto e muda junto, sobre o mesmo bruto e o mesmo totalBruto do detalhe, para o número não mudar ao abrir a folha. Na Casa Alphaville da vitrine, a Pintura (0,8%) passa de \"1%\" para \"<1% da obra\" na linha e no detalhe." -m "O VoiceOver lê o \"<1%\" da linha e do detalhe como \"menos de 1%\", pelo porcentoFalado do núcleo, como já fazia na barra empilhada: o mesmo número não é falado de dois jeitos, e o \"<\" não depende do nível de pontuação."
```

### Task 27: Costura das telas da análise, sem porta, com a abertura de Debug

As telas da análise moram em `Custta/Analise/` e se ligam ao resto do app por uma costura só (spec, "Arquitetura", "Telas"; linha 1c da tabela dos PRs). A tarefa a faz sem destino. Os Gráficos e o Relatório são empurrados no caminho de Obras sobre a obra, como a tela Orçamento (`RotaDeObras`, ObrasView.swift:5): a rota ganha um caso só, `.analise(TelaDaAnalise)`, e o `navigationDestination` de Obras leva ao `DestinoDaAnalise`, a única peça que as telas de verdade trocam (os Gráficos no 2a, o Relatório no 3a), para os PRs delas mexerem só em `Custta/Analise/` e nos testes dela, o portão "telas novas" (spec, "Portões por superfície"). Nenhuma porta entra: a obra continua sem caminho para essas telas até o PR que completa cada destino (a barra empilhada no 2b, a fileira de portas no 3b; spec, "Escondido na `main`"). Até lá, só a abertura de Debug chega a elas: `CUSTTA_ABRIR=graficos:<id>` e `relatorio:<id>` abrem a obra pelo caminho inicial e empurram a tela quando os dados chegam, como um toque na porta, igual ao `afazeres:<id>` de hoje (PrincipalView.swift:162-172), que passa a usar o mesmo gancho. A tela é uma provisória mínima: o título na barra ("Gráficos" ou "Relatório") e o nome da obra. O + da cápsula lança gasto na obra da tela, como nas telas Orçamento e Afazeres (confirmação 6): o `obraId` da rota é o da tela. O "Vale a pena?" não passa por aqui: é uma aba (spec, "Telas"), que chega no 4a com a cápsula de três abas, e o PDF não é tela. O leitor do gancho fica em `#if DEBUG`, e o `nm` do Release confere que ele não vai ao Release.

**Files:**
- Create: `app-ios/Custta/Analise/TelaDaAnalise.swift`
- Modify: `app-ios/Custta/Telas/ObrasView.swift`
- Modify: `app-ios/Custta/Telas/PrincipalView.swift`
- Test (novo): `app-ios/CusttaTests/CosturaDaAnaliseTests.swift`
- Test (novo): `app-ios/CusttaUITests/AnaliseUITests.swift`

**Interfaces:**
- Consumes: `RotaDeObras` e o `navigationDestination` de Obras (ObrasView.swift); `PrincipalView.caminhoInicial` e o gancho dos afazeres (PrincipalView.swift); `abrirApp(conta:dados:abrir:)` (Abrir.swift).
- Produces: `enum TelaDaAnalise: Hashable, Sendable { case graficos(String); case relatorio(String) }`, com `obraId` e `titulo`; `RotaDeObras.analise(TelaDaAnalise)`; `struct DestinoDaAnalise: View` (`tela:`, `caminho:`), que o 2a e o 3a trocam; em Debug, `TelaDaAnalise(gancho:)`, que lê `graficos:<id>` e `relatorio:<id>`.

- [ ] **Step 1: Escrever os testes**

O de unidade prende o leitor do gancho (só as duas telas, com o id; as outras aberturas e o gancho sem id dão nil) e a obra e o título de cada rota. O de tela abre cada uma pelo gancho, sobre a obra, com o título, o nome da obra e o + que lança gasto, e volta para a obra e dela para Obras.

Criar `app-ios/CusttaTests/CosturaDaAnaliseTests.swift`:

```swift
import Testing
@testable import Custta

/* A costura das telas da análise (etapa 4, PR 1c): a abertura de Debug lê do gancho a tela e a obra, só dos Gráficos e do
   Relatório, e a rota no caminho de Obras leva a obra da tela ao + da cápsula. */
struct CosturaDaAnaliseTests {
    @Test func ganchoDeAberturaComATelaEAObra() {
        #expect(TelaDaAnalise(gancho: "graficos:v1") == .graficos("v1"))
        #expect(TelaDaAnalise(gancho: "relatorio:o2") == .relatorio("o2"))
        for outro in ["obra:v1", "orcamento:v1", "afazeres:v1", "valeAPena:v1", "graficos:", "graficos", ":v1", ""] {
            #expect(TelaDaAnalise(gancho: outro) == nil, "\(outro)")
        }
    }

    @Test func rotaComAObraEOTituloDaTela() {
        #expect(RotaDeObras.analise(.graficos("v1")).obraId == "v1")
        #expect(RotaDeObras.analise(.relatorio("v3")).obraId == "v3")
        #expect(TelaDaAnalise.graficos("v1").titulo == "Gráficos" && TelaDaAnalise.relatorio("v1").titulo == "Relatório")
    }
}
```

Criar `app-ios/CusttaUITests/AnaliseUITests.swift`:

```swift
import XCTest

/* A costura das telas da análise (etapa 4, PR 1c). A obra não tem porta para elas: os Gráficos e o Relatório só abrem pela
   abertura de Debug (`CUSTTA_ABRIR=graficos:<id>` e `relatorio:<id>`), empurrados sobre a obra quando os dados chegam, como
   num toque na porta, numa tela provisória com o título na barra e o nome da obra. O voltar leva à obra e, dela, a Obras; o
   + da cápsula lança gasto na obra da tela (confirmação 6). As telas de verdade trocam a provisória no 2a e no 3a. */
@MainActor
final class AnaliseUITests: XCTestCase {
    /// Abre a tela da análise pelo gancho e confere o título, a obra e o + da cápsula.
    private func abrir(_ gancho: String, titulo: String, obra: String) -> XCUIApplication {
        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: gancho)
        XCTAssertTrue(app.navigationBars[titulo].waitForExistence(timeout: 10), "a tela \(titulo)")
        XCTAssertEqual(app.elemento("obraDaAnalise").label, obra)
        XCTAssertEqual(app.buttons["botaoMais"].label, "Lançar gasto", "o + lança gasto na obra da tela")
        return app
    }

    func testGraficosAbremSobreAObraEVoltamParaEla() {
        let app = abrir("graficos:v1", titulo: "Gráficos", obra: "Casa Alphaville")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "o voltar leva à obra")
        XCTAssertFalse(app.navigationBars["Gráficos"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.elemento("obra-v1").waitForExistence(timeout: 5), "e a obra, a Obras")
    }

    func testRelatorioAbreSobreAObraEVoltaParaEla() {
        let app = abrir("relatorio:v3", titulo: "Relatório", obra: "Casa Tamboré 4")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 5), "o voltar leva à obra")
        XCTAssertFalse(app.navigationBars["Relatório"].exists)
    }
}
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E '^/.*error:' | sed 's/^.*CusttaTests\//CusttaTests\//' | sort -t: -k2,2n -u | head -3
git stash push -u -q -- app-ios/CusttaTests/CosturaDaAnaliseTests.swift
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/AnaliseUITests 2>&1 | grep -oE 'XCTAssertTrue failed - .*' | sort -u
git stash pop -q
```
Expected: o `CusttaTests` não compila; sem o teste de unidade, o de tela compila e cai, porque o gancho sem a costura abre a lista de Obras:
```
CusttaTests/CosturaDaAnaliseTests.swift:8:17: error: cannot find 'TelaDaAnalise' in scope
CusttaTests/CosturaDaAnaliseTests.swift:9:17: error: cannot find 'TelaDaAnalise' in scope
CusttaTests/CosturaDaAnaliseTests.swift:11:21: error: cannot find 'TelaDaAnalise' in scope
** TEST BUILD SUCCEEDED **
XCTAssertTrue failed - a tela Gráficos
XCTAssertTrue failed - a tela Relatório
```

- [ ] **Step 3: Implementar**

A tela entra no caminho depois dos dados, como os afazeres: empurrada junto com a obra na abertura, ela apareceria antes de os dados chegarem, e a entrada do anel do 2a (que só roda quando a tela é empurrada) não seria a de um toque na porta. O leitor do gancho mora com as telas, em `Custta/Analise/`, para o 2a e o 3a acrescentarem o que precisarem sem sair da pasta.

Criar `app-ios/Custta/Analise/TelaDaAnalise.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* A costura das telas da análise (etapa 4) com o resto do app: elas moram nesta pasta e chegam ao app só por aqui (spec da
   etapa 4, "Telas"). Gráficos e Relatório são empurrados no caminho de Obras, sobre a obra, como a tela Orçamento
   (`RotaDeObras.analise`), e o + da cápsula lança gasto nessa obra (confirmação 6). Ainda não há porta: até o PR que completa
   cada destino (a barra empilhada da obra no 2b, a fileira de portas no 3b), só a abertura de Debug chega a elas
   (`CUSTTA_ABRIR=graficos:<id>` e `relatorio:<id>`, no PrincipalView), e cada uma é uma tela provisória, que a de verdade
   troca no `DestinoDaAnalise` (os Gráficos no 2a, o Relatório no 3a). O "Vale a pena?" não passa por aqui: é uma aba, que
   chega no 4a com a cápsula de três abas. */

/// Uma tela da análise de uma obra, empurrada no caminho de Obras.
enum TelaDaAnalise: Hashable, Sendable {
    case graficos(String)
    case relatorio(String)

    /// A obra da tela: o + da cápsula lança gasto nela, como na tela Orçamento.
    var obraId: String {
        switch self {
        case .graficos(let id), .relatorio(let id): return id
        }
    }

    /// O título da barra.
    var titulo: String {
        switch self {
        case .graficos: return "Gráficos"
        case .relatorio: return "Relatório"
        }
    }
}

/// Para onde cada tela da análise leva no caminho de Obras: a única peça que as telas de verdade trocam fora delas.
struct DestinoDaAnalise: View {
    let tela: TelaDaAnalise
    @Binding var caminho: [RotaDeObras]

    var body: some View {
        TelaProvisoriaDaAnalise(tela: tela)
    }
}

/// A tela provisória, só pela abertura de Debug: o título na barra e o nome da obra.
struct TelaProvisoriaDaAnalise: View {
    let tela: TelaDaAnalise
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    var body: some View {
        let obra = modelo.sincronizador.estado.obras.first { $0.id == tela.obraId }
        ScrollView {
            Text(obra?.nome ?? "")
                .font(.title3.weight(.semibold))
                .foregroundStyle(paleta.cor(.texto))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .accessibilityIdentifier("obraDaAnalise")
        }
        .containerBackground(.clear, for: .navigation)
        .navigationTitle(tela.titulo)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
extension TelaDaAnalise {
    /// A tela do gancho de abertura dos testes de tela, do laudo e da conferência visual: `graficos:<id>` ou `relatorio:<id>`;
    /// nil para as outras aberturas (`obra:`, `orcamento:`, `afazeres:`) e sem o id.
    init?(gancho: String) {
        let partes = gancho.split(separator: ":", maxSplits: 1).map(String.init)
        guard partes.count == 2, !partes[1].isEmpty else { return nil }
        switch partes[0] {
        case "graficos": self = .graficos(partes[1])
        case "relatorio": self = .relatorio(partes[1])
        default: return nil
        }
    }
}
#endif
```

Em `app-ios/Custta/Telas/ObrasView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObrasView.swift
+++ b/app-ios/Custta/Telas/ObrasView.swift
@@ -8,11 +8,14 @@ enum RotaDeObras: Hashable, Sendable {
     case orcamento(String)
     /// A tela "Afazeres" da obra, empurrada pela linha dos afazeres (etapa 3).
     case afazeres(String)
+    /// Uma tela da análise da obra, Gráficos ou Relatório (etapa 4), empurrada sobre ela: a costura com Custta/Analise.
+    case analise(TelaDaAnalise)
 
-    /// A obra da tela: a própria, ou a dona do orçamento ou dos afazeres (o + da cápsula lança gasto nela).
+    /// A obra da tela: a própria, ou a dona do orçamento, dos afazeres ou da tela da análise (o + da cápsula lança gasto nela).
     var obraId: String {
         switch self {
         case .obra(let id), .orcamento(let id), .afazeres(let id): return id
+        case .analise(let tela): return tela.obraId
         }
     }
 }
@@ -95,6 +98,7 @@ struct ObrasView: View {
                 case .obra(let id): ObraView(id: id, caminho: $caminho)
                 case .orcamento(let id): OrcamentoView(id: id, caminho: $caminho)
                 case .afazeres(let id): AfazeresView(obraId: id, caminho: $caminho)
+                case .analise(let tela): DestinoDaAnalise(tela: tela, caminho: $caminho)
                 }
             }
             #if DEBUG
```

Em `app-ios/Custta/Telas/PrincipalView.swift`:

```diff
--- a/app-ios/Custta/Telas/PrincipalView.swift
+++ b/app-ios/Custta/Telas/PrincipalView.swift
@@ -56,7 +56,7 @@ struct PrincipalView: View {
         .modifier(AvisosDoPrincipal(avisoDoMais: $avisoDoMais, folhaAberta: folhas.aberta != nil))
         #if DEBUG
         .task { await abrirFolhaDoGancho() }
-        .task { await abrirAfazeresDoGancho() }
+        .task { await empurrarDoGancho() }
         // Teste de tela: quantas pontes de fechamento estão vivas (abrir e fechar a folha não pode deixar nenhuma).
         .overlay(alignment: .topLeading) {
             if UserDefaults.standard.bool(forKey: "custta.contarPontes") {
@@ -159,27 +159,35 @@ extension PrincipalView {
         }
     }
 
-    /// `CUSTTA_ABRIR=afazeres:<id>`: a obra abre pelo caminho inicial e os afazeres dela são empurrados quando os dados
-    /// chegam, como num toque na linha. Empurrados junto com a obra na abertura, o título grande "Afazeres" nascia recolhido.
-    private func abrirAfazeresDoGancho() async {
-        guard let abrir = ProcessInfo.processInfo.environment["CUSTTA_ABRIR"], abrir.hasPrefix("afazeres:") else { return }
+    /// `CUSTTA_ABRIR=afazeres:<id>`, `graficos:<id>` e `relatorio:<id>`: a obra abre pelo caminho inicial, e a tela é empurrada
+    /// sobre ela quando os dados chegam, como num toque na linha ou na porta. Empurrados junto com a obra na abertura, o título
+    /// grande "Afazeres" nascia recolhido.
+    private func empurrarDoGancho() async {
+        guard let rota = Self.empurradaDoGancho else { return }
         for _ in 0..<50 {
             guard !modelo.sincronizador.dadosCarregados else { break }
             try? await Task.sleep(for: .milliseconds(100))
         }
         try? await Task.sleep(for: .milliseconds(300))
-        caminhoDeObras.append(.afazeres(String(abrir.dropFirst(9))))
+        caminhoDeObras.append(rota)
+    }
+
+    /// A tela que o `CUSTTA_ABRIR` empurra sobre a obra: os afazeres ou uma tela da análise (o leitor mora em Custta/Analise).
+    private static var empurradaDoGancho: RotaDeObras? {
+        guard let abrir = ProcessInfo.processInfo.environment["CUSTTA_ABRIR"] else { return nil }
+        if abrir.hasPrefix("afazeres:") { return .afazeres(String(abrir.dropFirst(9))) }
+        return TelaDaAnalise(gancho: abrir).map { .analise($0) }
     }
     #endif
 
     /// O caminho com que Obras abre: vazio; em Debug, `CUSTTA_ABRIR=obra:<id>` abre a obra direto,
     /// `CUSTTA_ABRIR=orcamento:<id>`, a tela Orçamento dela (testes de tela, laudo de leitura e conferência visual), e
-    /// `afazeres:<id>`, a obra, com os afazeres dela empurrados depois.
+    /// `afazeres:<id>`, `graficos:<id>` e `relatorio:<id>`, a obra, com a tela empurrada depois.
     static var caminhoInicial: [RotaDeObras] {
         #if DEBUG
         if let abrir = ProcessInfo.processInfo.environment["CUSTTA_ABRIR"] {
             if abrir.hasPrefix("obra:") { return [.obra(String(abrir.dropFirst(5)))] }
-            if abrir.hasPrefix("afazeres:") { return [.obra(String(abrir.dropFirst(9)))] }
+            if let empurrada = empurradaDoGancho { return [.obra(empurrada.obraId)] }
         }
         if let abrir = ProcessInfo.processInfo.environment["CUSTTA_ABRIR"], abrir.hasPrefix("orcamento:") {
             let id = String(abrir.dropFirst(10))
```

- [ ] **Step 4: Ver passar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/CosturaDaAnaliseTests 2>&1 | grep -E "Test run with"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/AnaliseUITests -only-testing:CusttaUITests/AfazeresUITests 2>&1 | grep -E "Executed [0-9]+ tests" | tail -1
```
Expected: `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 2 tests in 1 suite passed`; `Executed 17 tests, with 0 failures` (os 2 da costura e os 15 dos afazeres, que passam pelo mesmo gancho), em ~4 min no 18 Pro.

- [ ] **Step 5: Conferir que a abertura de Debug não vai ao Release**

O Release compila para o simulador sem assinar, no mesmo DerivedData do `XB`, e o `nm` procura os nomes do leitor do gancho e do empurrar (só Debug) e, de controle, os da costura, que vão ao Release sem porta (memória `release-sem-ganchos-conferir-por-nm`: o `strings` engana).

Run:
```bash
xcodebuild build -project app-ios/Custta.xcodeproj -scheme Custta -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | tail -1
PROD=$(xcodebuild "${XB[@]}" -showBuildSettings 2>/dev/null | awk -F' = ' '/^ *BUILD_DIR = /{print $2; exit}')
for s in TelaDaAnaliseO6gancho empurradaDoGancho empurrarDoGancho DestinoDaAnalise RaizView; do echo "$s release=$(nm -a "$PROD/Release-iphonesimulator/Custta.app/Custta" | grep -c $s) debug=$(nm -a "$PROD/Debug-iphonesimulator/Custta.app/Custta.debug.dylib" | grep -c $s)"; done
```
Expected: `** BUILD SUCCEEDED **` e:
```
TelaDaAnaliseO6gancho release=0 debug=4
empurradaDoGancho release=0 debug=4
empurrarDoGancho release=0 debug=18
DestinoDaAnalise release=135 debug=208
RaizView release=90 debug=384
```

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Analise/TelaDaAnalise.swift app-ios/Custta/Telas/ObrasView.swift app-ios/Custta/Telas/PrincipalView.swift app-ios/CusttaTests/CosturaDaAnaliseTests.swift app-ios/CusttaUITests/AnaliseUITests.swift
git commit -m "feat: costura das telas da análise, sem porta, com a abertura de Debug" -m "Os Gráficos e o Relatório da etapa 4 moram em Custta/Analise e chegam ao app por uma costura só: a rota RotaDeObras.analise, empurrada no caminho de Obras sobre a obra, como a tela Orçamento, e o DestinoDaAnalise, a única peça que as telas de verdade trocam fora da pasta. Assim os PRs 2a e 3a mexem só em Custta/Analise e nos testes dela, o portão \"telas novas\" do spec." -m "Nenhuma porta entra: a obra continua sem caminho para essas telas até o PR que completa cada destino. Até lá, só a abertura de Debug chega a elas: CUSTTA_ABRIR=graficos:<id> e relatorio:<id> abrem a obra e empurram a tela quando os dados chegam, como um toque na porta, numa tela provisória com o título e o nome da obra. Os afazeres passam pelo mesmo gancho. O + da cápsula lança gasto na obra da tela, como pede a confirmação 6. O \"Vale a pena?\" não passa por aqui: é uma aba, que chega no 4a com a cápsula de três abas."
```

### Task 28: Falsos com as obras dos estados da análise

Os marcos 2 e 3 testam, medem no laudo e conferem lado a lado com o mockup os Gráficos, o Relatório, o "Vale a pena?" e o PDF em estados que a vitrine não tem (spec, "Testes e validação", item 3, e os estados de cada tela em "Decisões de desenho"). O `CUSTTA_DADOS=analise` monta a vitrine de sempre e mais as obras dos estados do mockup aprovado da etapa 4, com os números do `gera-dados-p1.cjs` (que parte do `calc.js` da `cec9fc0`, hoje 12/10/2026), as datas contadas de hoje, como na vitrine (VitrineDaObra.swift:62). A vitrine já tem a Casa Alphaville (`v1`) com 14 tópicos (o anel junta 8 no "Outros"), 13 parcelas a vencer e a venda estimada; o Sobrado Granja Viana (`v2`), pronto e sem venda estimada (o "sem preço" do "Vale a pena?"); e a Casa Tamboré 4 (`v3`), vendida, com 1 tópico. As obras novas, com os nomes e os valores do mockup:
- `a1`: a Casa Alphaville vendida por R$ 1.380.000,00 há 114 dias (o `est-vendida` e o Relatório e o PDF da vendida): os gastos depois da venda ficam fora da evolução;
- `a2`: Casa Cotia, sem gastos (o `est-vazio` e a obra sem gastos);
- `a3`: Terreno Granja, 1 gasto de R$ 120.000,00 (o `est-1-gasto`; apagando o gasto pela folha do tópico, os Gráficos sem gastos);
- `a4`: Sobrado Vila Nova, 5 gastos neste mês, até hoje, com a venda estimada de R$ 1.100.000,00 e 220 m² (o `est-1-mes` e, no "Vale a pena?", a obra com menos de 1 mês);
- `a5`: Galpão Jundiaí, 7 gastos, todos em Estrutura (o `est-1-topico`);
- `a6`: Casa Granja Viana, com Outros (0,25%) e Extras (0,05%) abaixo de 1% (o `est-pequeno`: o piso e o "<1%");
- `a7`: Casa Morumbi, que o mockup não desenha: 30 meses de gastos, do 30º mês atrás ao mês passado, com 3 meses parados no meio, para o "Mostrando os últimos 24 meses." nos dois gráficos de mês;
- `a8`: a Casa Alphaville sem a venda estimada (o Relatório e o PDF "sem venda" do mockup).

A Cotia, o Terreno Granja e o Sobrado Vila Nova começam no dia 1º deste mês, e os gastos deles caem neste mês, no dia do mockup sem passar de hoje (no dia 1º, todos caem nele): por dias contados de hoje, a obra de 1 mês teria 2 meses nos dias 1 a 9 (memória `laudo-que-depende-do-dia`). As cópias da Casa Alphaville levam ids próprios nos gastos (`a1g001`…). Um teste de formato prende o que cada obra promete, em seis datas (fim de mês, dia 1º, fim do ano e fevereiro do bissexto), como o dos orçamentos da etapa 3 (memória `variante-de-falso-sem-teste-de-formato`). O "sem obra" do "Vale a pena?" é o `vazio`. Só Debug: o `nm` do Release confere.

**Files:**
- Modify: `app-ios/Custta/Falsos/MontarFalso.swift`
- Create: `app-ios/Custta/Falsos/VitrineDaAnalise.swift`
- Test (alterar): `app-ios/CusttaTests/DadosDeExemploTests.swift`
- Test (alterar): `app-ios/CusttaUITests/AnaliseUITests.swift`

**Interfaces:**
- Consumes: `DadosDeExemplo.vitrine(hoje:)` (TransporteFalsoApp.swift) e o `switch` do `CUSTTA_DADOS` (MontarFalso.swift); `TelaDaAnalise` e a abertura `graficos:<id>` (Tarefa anterior).
- Produces: `DadosDeExemplo.vitrineDaAnalise(hoje: Date = .now) -> ValorJSON`, pelo `CUSTTA_DADOS=analise`, com as obras `v1` a `v3` e `a1` a `a8`.

- [ ] **Step 1: Escrever os testes**

O de formato confere cada obra pelas regras do núcleo (os tópicos, os pedaços, as séries, os cortes de 24 meses, o "<1%", os meses de obra e a venda), as datas das obras de 1 mês (os gastos do Terreno Granja e do Sobrado Vila Nova neste mês, até hoje, e a Casa Cotia, o Terreno Granja e o Sobrado Vila Nova começando no dia 1º) e que os ids dos gastos não se repetem, nas 6 datas; o de tela abre os Gráficos da Casa Morumbi pela abertura de Debug com o `CUSTTA_DADOS=analise`.

Em `app-ios/CusttaTests/DadosDeExemploTests.swift`:

```diff
--- a/app-ios/CusttaTests/DadosDeExemploTests.swift
+++ b/app-ios/CusttaTests/DadosDeExemploTests.swift
@@ -4,7 +4,7 @@ import Testing
 import CusttaNucleo
 
 /* A vitrine mostra os números do mockup aprovado em qualquer dia (as datas são contadas de hoje), também com os orçamentos
-   da etapa 3. */
+   da etapa 3 e as obras dos estados da análise da etapa 4. */
 struct DadosDeExemploTests {
     static let dias = ["2026-01-31", "2026-03-01", "2026-10-08", "2026-12-31", "2027-02-28", "2028-02-29"]
 
@@ -77,4 +77,71 @@ struct DadosDeExemploTests {
         let data = Dictionary(uniqueKeysWithValues: diarias.map { ($0.id, $0.data) })
         #expect(data["d001"] == iso(-1) && data["d100"] == iso(-100) && data["d101"] == iso(1) && data["d120"] == iso(20), "de ontem para trás e de amanhã em diante")
     }
+
+    /// As obras dos estados da análise (etapa 4, `CUSTTA_DADOS=analise`) sobre a vitrine, em qualquer dia: o que cada uma
+    /// promete às telas dos marcos 2 e 3. No dia 1º, os gastos deste mês caem todos nele, e a obra de 1 mês continua com 1 mês.
+    @Test(arguments: dias)
+    func obrasDosEstadosDaAnalise(_ dia: String) throws {
+        var calendario = Calendar(identifier: .gregorian)
+        calendario.timeZone = .current
+        let partes = dia.split(separator: "-").map { Int($0)! }
+        let hoje = try #require(calendario.date(from: DateComponents(year: partes[0], month: partes[1], day: partes[2], hour: 12)))
+        let iso = dataLocalISO(hoje, fuso: .current)
+        func dias(_ n: Int) -> String { dataLocalISO(calendario.date(byAdding: .day, value: n, to: hoje)!, fuso: .current) }
+        func meses(_ n: Int) -> String { dataLocalISO(calendario.date(byAdding: .month, value: n, to: hoje)!, fuso: .current) }
+        let estado = Estado.de(DadosDeExemplo.vitrineDaAnalise(hoje: hoje))
+        #expect(estado.obras.map(\.id) == ["v1", "v2", "v3", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"])
+        #expect(Array(estado.obras.prefix(3)) == Estado.de(DadosDeExemplo.vitrine(hoje: hoje)).obras, "a vitrine de sempre na frente")
+        let obra = Dictionary(uniqueKeysWithValues: estado.obras.map { ($0.id, $0) })
+        let ids = estado.obras.flatMap { $0.gastos.map(\.id) }
+        #expect(Set(ids).count == ids.count, "cada gasto com id próprio")
+        // A Casa Alphaville (v1): 14 tópicos (o anel junta 8 no "Outros") e 13 parcelas a vencer.
+        let casa = try #require(obra["v1"])
+        #expect(gastoPorTopico(casa).count == 14 && pedacosDoAnel(gastoPorTopico(casa)).last?.topicos.count == 8)
+        #expect(listaDaObra(casa, hoje: iso).aVencer?.quantidade == 13)
+        // a1: a Casa Alphaville vendida há 114 dias por R$ 1.380.000,00, com os gastos dela; os depois da venda ficam fora da
+        // evolução.
+        let vendida = try #require(obra["a1"])
+        #expect(vendida.nome == "Casa Alphaville" && vendida.fase == .vendida && vendida.venda == Venda(valor: 1_380_000, data: dias(-114)))
+        #expect(vendida.gastos.map(\.valor) == casa.gastos.map(\.valor) && vendida.gastos.map(\.data) == casa.gastos.map(\.data))
+        #expect(fraseForaDaEvolucao(vendida, hoje: iso)?.hasSuffix("com data depois da venda.") == true)
+        // a2: sem gastos.
+        let cotia = try #require(obra["a2"])
+        #expect(cotia.nome == "Casa Cotia" && cotia.gastos.isEmpty && cotia.fase == .construcao)
+        // a3: 1 gasto, neste mês.
+        let terreno = try #require(obra["a3"])
+        #expect(terreno.nome == "Terreno Granja" && terreno.gastos.map(\.valor) == [120_000])
+        #expect(serieMensal(terreno.gastos).count == 1 && serieEvolucao(terreno, taxa: 1, hoje: iso).count == 1)
+        #expect(terreno.gastos.allSatisfy { $0.data.prefix(7) == iso.prefix(7) && $0.data <= iso }, "neste mês, até hoje")
+        // a4: 5 gastos neste mês, até hoje: 1 mês nos gráficos e menos de 1 mês de obra no "Vale a pena?".
+        let vilaNova = try #require(obra["a4"])
+        #expect(vilaNova.nome == "Sobrado Vila Nova" && vilaNova.gastos.count == 5 && gastoPorTopico(vilaNova).count == 4)
+        #expect(vilaNova.gastos.allSatisfy { $0.data.prefix(7) == iso.prefix(7) && $0.data <= iso }, "neste mês, até hoje")
+        #expect(serieMensal(vilaNova.gastos).count == 1 && serieEvolucao(vilaNova, taxa: 1, hoje: iso).count == 1)
+        #expect(mesesDeObra(vilaNova, hoje: iso) < 1 && vilaNova.valorEstimadoVenda == 1_100_000 && vilaNova.areaM2 == 220)
+        #expect([cotia, terreno, vilaNova].allSatisfy { $0.dataInicio == String(iso.prefix(8)) + "01" }, "no dia 1º deste mês")
+        // a5: 7 gastos, todos em Estrutura.
+        let galpao = try #require(obra["a5"])
+        #expect(galpao.nome == "Galpão Jundiaí" && galpao.gastos.count == 7 && gastoPorTopico(galpao).map(\.id) == ["estrutura"])
+        // a6: Outros e Extras abaixo de 1%.
+        let granja = try #require(obra["a6"])
+        let topicos = gastoPorTopico(granja)
+        #expect(granja.nome == "Casa Granja Viana" && topicos.map(\.id) == ["terreno", "fundacao", "projeto", "outros", "extras"])
+        #expect(topicos.map { porcentoDoTopico($0.bruto, total: totalBruto(granja)) } == ["78%", "17%", "5%", "<1%", "<1%"])
+        // a7: 30 meses de gastos (do 30º mês atrás ao mês passado), com 3 parados: os dois gráficos de mês passam de 24 e
+        // mostram os últimos 24, com os 3 parados entre eles.
+        let morumbi = try #require(obra["a7"])
+        #expect(morumbi.nome == "Casa Morumbi" && morumbi.dataInicio == meses(-30) && morumbi.gastos.count == 27)
+        #expect(morumbi.gastos.first?.data == meses(-30) && morumbi.gastos.last?.data == meses(-1))
+        #expect(gastoPorMesFoiCortado(morumbi.gastos) && evolucaoFoiCortada(morumbi, hoje: iso))
+        let porMes = serieMensal(morumbi.gastos)
+        #expect(porMes.count == 24 && porMes.first?.mes == String(meses(-24).prefix(7)))
+        #expect(porMes.filter { $0.total == 0 }.map(\.mes) == [-20, -19, -18].map { String(meses($0).prefix(7)) }, "3 meses parados, seguidos")
+        #expect(!gastoPorMesFoiCortado(casa.gastos) && !evolucaoFoiCortada(casa, hoje: iso), "a Casa Alphaville cabe em 24")
+        // a8: a Casa Alphaville sem a venda estimada, com os mesmos gastos.
+        let semVenda = try #require(obra["a8"])
+        #expect(semVenda.nome == "Casa Alphaville" && semVenda.fase == .construcao && semVenda.venda == nil)
+        #expect(semVenda.valorEstimadoVenda == nil && casa.valorEstimadoVenda == 1_450_000)
+        #expect(semVenda.gastos.map(\.valor) == casa.gastos.map(\.valor) && semVenda.gastos.map(\.data) == casa.gastos.map(\.data))
+    }
 }
```

Em `app-ios/CusttaUITests/AnaliseUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/AnaliseUITests.swift
+++ b/app-ios/CusttaUITests/AnaliseUITests.swift
@@ -3,7 +3,8 @@ import XCTest
 /* A costura das telas da análise (etapa 4, PR 1c). A obra não tem porta para elas: os Gráficos e o Relatório só abrem pela
    abertura de Debug (`CUSTTA_ABRIR=graficos:<id>` e `relatorio:<id>`), empurrados sobre a obra quando os dados chegam, como
    num toque na porta, numa tela provisória com o título na barra e o nome da obra. O voltar leva à obra e, dela, a Obras; o
-   + da cápsula lança gasto na obra da tela (confirmação 6). As telas de verdade trocam a provisória no 2a e no 3a. */
+   + da cápsula lança gasto na obra da tela (confirmação 6). As obras dos estados da análise (`CUSTTA_DADOS=analise`) abrem
+   pelo mesmo gancho. As telas de verdade trocam a provisória no 2a e no 3a. */
 @MainActor
 final class AnaliseUITests: XCTestCase {
     /// Abre a tela da análise pelo gancho e confere o título, a obra e o + da cápsula.
@@ -24,6 +25,13 @@ final class AnaliseUITests: XCTestCase {
         XCTAssertTrue(app.elemento("obra-v1").waitForExistence(timeout: 5), "e a obra, a Obras")
     }
 
+    /// Os falsos da análise (`CUSTTA_DADOS=analise`) chegam pela mesma abertura: os Gráficos da Casa Morumbi, a obra de 30 meses.
+    func testObrasDosEstadosDaAnaliseAbremPeloGancho() {
+        let app = abrirApp(conta: "senha", dados: "analise", abrir: "graficos:a7")
+        XCTAssertTrue(app.navigationBars["Gráficos"].waitForExistence(timeout: 10), "a tela Gráficos")
+        XCTAssertEqual(app.elemento("obraDaAnalise").label, "Casa Morumbi")
+    }
+
     func testRelatorioAbreSobreAObraEVoltaParaEla() {
         let app = abrir("relatorio:v3", titulo: "Relatório", obra: "Casa Tamboré 4")
         app.navigationBars.buttons.firstMatch.tap()
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E '^/.*error:' | sed 's/^.*CusttaTests\//CusttaTests\//' | sort -t: -k2,2n -u | head -1
git stash push -q -- app-ios/CusttaTests/DadosDeExemploTests.swift
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/AnaliseUITests/testObrasDosEstadosDaAnaliseAbremPeloGancho 2>&1 | grep -oE "No matches found for .*obraDaAnalise[^,]*" | sort -u
git stash pop -q
```
Expected: o `CusttaTests` não compila; sem o teste de formato, o de tela compila e cai, porque sem a variante o app abre a vitrine, onde não há a `a7`, e a tela abre sem o nome da obra:
```
CusttaTests/DadosDeExemploTests.swift:92:47: error: type 'DadosDeExemplo' has no member 'vitrineDaAnalise'
** TEST BUILD SUCCEEDED **
No matches found for first query match sequence: `Descendants matching type Any` -> `Elements matching predicate '"obraDaAnalise" IN identifiers'`
```

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Falsos/MontarFalso.swift`:

```diff
--- a/app-ios/Custta/Falsos/MontarFalso.swift
+++ b/app-ios/Custta/Falsos/MontarFalso.swift
@@ -9,7 +9,8 @@ import CusttaNucleo
    CUSTTA_DADOS   vitrine (padrão: as obras do mockup) | exemplo (as dos testes) | vazio | limite (as 300 obras do teto) |
                   prejuizo (a vitrine com a vendida no prejuízo) | porTopico, perto, passou, semOrcamento, muitosTopicos,
                   topicoLongo (os orçamentos do mockup da etapa 3 sobre a vitrine: VitrineDoOrcamento.swift) | avista (a
-                  vitrine com um vencimento à vista no A pagar)
+                  vitrine com um vencimento à vista no A pagar) | analise (a vitrine e as obras dos estados da análise da
+                  etapa 4: VitrineDaAnalise.swift)
    CUSTTA_REDE    offline (abre "em modo avião": dados do cache e indicador "Sem conexão")
    CUSTTA_LEITURA erro (a escuta falha com permission-denied) | formato (documento que o app não lê) | nunca (a escuta
                   não responde: "Carregando suas obras…")
@@ -49,6 +50,7 @@ extension Composicao {
         case "prejuizo": DadosDeExemplo.vitrineComPrejuizo()
         case let v? where ["porTopico", "perto", "passou", "semOrcamento", "muitosTopicos", "topicoLongo"].contains(v): DadosDeExemplo.vitrineDoOrcamento(v)
         case "avista": DadosDeExemplo.vitrineComVencimentoAVista()
+        case "analise": DadosDeExemplo.vitrineDaAnalise()
         default: DadosDeExemplo.vitrine()
         }
         // CUSTTA_APAGAR_REMOTO=<obra>/<gasto>@<segundos>: outro aparelho apaga um gasto com o app aberto; sem o gasto
```

Criar `app-ios/Custta/Falsos/VitrineDaAnalise.swift`:

```swift
#if DEBUG
import Foundation
import CusttaNucleo

/* As obras dos estados do mockup aprovado da etapa 4 (gera-dados-p1.cjs e gera-dados-p2.cjs, de 28 e 29/10/2026) sobre a
   vitrine, para as telas da análise dos marcos 2 e 3 (Gráficos, Relatório, "Vale a pena?" e PDF), com as datas contadas de
   hoje, como na vitrine. CUSTTA_DADOS=analise (MontarFalso): a vitrine de sempre (a Casa Alphaville, v1, com 14 tópicos, 13
   parcelas a vencer e a venda estimada; o Sobrado Granja Viana, v2, pronto e sem venda estimada; a Casa Tamboré 4, v3,
   vendida, com 1 tópico) e mais:
   a1  a Casa Alphaville vendida por R$ 1.380.000,00 há 114 dias, com os 46 gastos dela (os depois da venda ficam fora da
       evolução)
   a2  Casa Cotia, sem gastos
   a3  Terreno Granja, 1 gasto de R$ 120.000,00
   a4  Sobrado Vila Nova, 5 gastos neste mês, até hoje (1 mês; no "Vale a pena?", menos de 1 mês de obra)
   a5  Galpão Jundiaí, 7 gastos, todos em Estrutura (1 tópico)
   a6  Casa Granja Viana, com Outros (0,25%) e Extras (0,05%) abaixo de 1% (o piso e o "<1%")
   a7  Casa Morumbi, 30 meses de gastos, com 3 meses parados no meio (os últimos 24 meses)
   a8  a Casa Alphaville sem a venda estimada (o Relatório e o PDF sem venda)
   A Cotia, o Terreno Granja e o Sobrado Vila Nova começam no dia 1º deste mês, e os gastos deles caem neste mês: o dia do
   mockup, sem passar de hoje (no dia 1º, todos caem nele). */
extension DadosDeExemplo {
    static func vitrineDaAnalise(hoje: Date = .now) -> ValorJSON {
        let base = vitrine(hoje: hoje)
        guard case .objeto(var raiz) = base, case .lista(let obras) = raiz["obras"], let primeira = obras.first,
              case .objeto(let casa) = primeira, case .lista(let gastosDaCasa) = casa["gastos"] else { return base }
        let calendario = Calendar(identifier: .gregorian)
        func dias(_ n: Int) -> String { dataLocalISO(calendario.date(byAdding: .day, value: n, to: hoje) ?? hoje, fuso: .current) }
        func meses(_ n: Int) -> String { dataLocalISO(calendario.date(byAdding: .month, value: n, to: hoje) ?? hoje, fuso: .current) }
        let hojeISO = dataLocalISO(hoje, fuso: .current)
        /// O dia `n` deste mês, sem passar de hoje.
        func desteMes(_ n: Int) -> String { String(hojeISO.prefix(8)) + String(format: "%02d", min(n, Int(hojeISO.suffix(2)) ?? 1)) }
        func gasto(_ id: String, _ valor: Double, _ topico: String, _ descricao: String, _ data: String) -> ValorJSON {
            .objeto(["id": .texto(id), "valor": .numero(valor), "topico": .texto(topico), "descricao": .texto(descricao),
                     "data": .texto(data), "pagamento": .texto("pix")])
        }
        func obra(_ id: String, _ nome: String, inicio: String, gastos: [ValorJSON], extra: [String: ValorJSON] = [:]) -> ValorJSON {
            var campos: [String: ValorJSON] = ["id": .texto(id), "nome": .texto(nome), "fase": .texto("construcao"),
                                               "dataInicio": .texto(inicio), "gastos": .lista(gastos)]
            campos.merge(extra) { _, novo in novo }
            return .objeto(campos)
        }
        /// A Casa Alphaville da vitrine com outro id, e os gastos com ids próprios.
        func copiaDaCasa(_ id: String, _ mudar: [String: ValorJSON]) -> ValorJSON {
            var campos = casa
            campos["id"] = .texto(id)
            campos["gastos"] = .lista(gastosDaCasa.map { g in
                guard case .objeto(var copia) = g, let deles = copia["id"]?.comoTexto else { return g }
                copia["id"] = .texto(id + deles)
                return .objeto(copia)
            })
            campos.merge(mudar) { _, novo in novo }
            return .objeto(campos)
        }
        let morumbi: [(Int, Double, String, String)] = [
            (30, 250_000, "terreno", "Compra do terreno"), (29, 18_500, "projeto", "Projeto e aprovação"),
            (28, 42_000, "fundacao", "Estacas e blocos"), (27, 38_600, "fundacao", "Vigas baldrame"),
            (26, 51_200, "estrutura", "Pilares do térreo"), (25, 47_800, "estrutura", "Laje do térreo"),
            (24, 29_300, "alvenaria", "Blocos de concreto"), (23, 16_400, "maoobra", "Pedreiro e ajudantes"),
            (22, 52_300, "estrutura", "Laje do pavimento superior"), (21, 21_100, "alvenaria", "Alvenaria do pavimento superior"),
            (17, 16_400, "maoobra", "Pedreiro e ajudantes"), (16, 33_900, "telhado", "Madeiramento do telhado"),
            (15, 18_200, "telhado", "Telhas de cerâmica"), (14, 12_800, "eletrica", "Eletrodutos e caixas"),
            (13, 10_900, "hidraulica", "Tubulação de água e esgoto"), (12, 16_400, "maoobra", "Pedreiro e ajudantes"),
            (11, 24_600, "revest", "Reboco interno"), (10, 19_800, "revest", "Contrapiso"),
            (9, 27_400, "esquadrias", "Janelas de alumínio"), (8, 16_400, "maoobra", "Pedreiro e ajudantes"),
            (7, 31_200, "revest", "Porcelanato"), (6, 14_900, "eletrica", "Fios e quadro de luz"),
            (5, 12_300, "hidraulica", "Louças e metais"), (4, 16_400, "maoobra", "Pedreiro e ajudantes"),
            (3, 22_800, "pintura", "Pintura interna"), (2, 9_800, "pintura", "Pintura externa"),
            (1, 16_400, "maoobra", "Pedreiro e ajudantes"),
        ]
        raiz["obras"] = .lista(obras + [
            copiaDaCasa("a1", ["fase": .texto("vendida"), "venda": .objeto(["valor": .numero(1_380_000), "data": .texto(dias(-114))])]),
            obra("a2", "Casa Cotia", inicio: desteMes(1), gastos: []),
            obra("a3", "Terreno Granja", inicio: desteMes(1), gastos: [gasto("u1", 120_000, "terreno", "Entrada do terreno", desteMes(5))]),
            obra("a4", "Sobrado Vila Nova", inicio: desteMes(1), gastos: [
                gasto("m1", 180_000, "terreno", "Entrada do terreno", desteMes(2)),
                gasto("m2", 18_500, "projeto", "Projeto arquitetônico", desteMes(3)),
                gasto("m3", 9_800, "maoobra", "Limpeza do terreno", desteMes(6)),
                gasto("m4", 14_320, "matbasicos", "Cimento, areia e brita", desteMes(8)),
                gasto("m5", 4_380.5, "projeto", "Taxas e alvará da prefeitura", desteMes(9)),
            ], extra: ["valorEstimadoVenda": .numero(1_100_000), "areaM2": .numero(220)]),
            obra("a5", "Galpão Jundiaí", inicio: dias(-224), gastos: [
                gasto("t1", 52_300, "estrutura", "Pilares e vigas", dias(-210)),
                gasto("t2", 38_900, "estrutura", "Concreto da laje", dias(-186)),
                gasto("t3", 12_400.9, "estrutura", "Ferragem da laje", dias(-153)),
                gasto("t4", 26_900, "estrutura", "Formas e escoramento", dias(-116)),
                gasto("t5", 31_700.5, "estrutura", "Estrutura metálica da cobertura", dias(-83)),
                gasto("t6", 24_300, "estrutura", "Vigas de borda", dias(-48)),
                gasto("t7", 19_600, "estrutura", "Concreto do piso", dias(-6)),
            ]),
            obra("a6", "Casa Granja Viana", inicio: dias(-194), gastos: [
                gasto("p1", 300_000, "terreno", "Terreno", dias(-185)),
                gasto("p2", 64_200, "fundacao", "Sapatas e baldrames", dias(-126)),
                gasto("p3", 18_500, "projeto", "Projeto arquitetônico", dias(-160)),
                gasto("p4", 950, "outros", "Caçamba de entulho", dias(-28)),
                gasto("p5", 180, "extras", "Cópia de chaves", dias(-9)),
            ], extra: ["valorEstimadoVenda": .numero(900_000), "areaM2": .numero(180)]),
            obra("a7", "Casa Morumbi", inicio: meses(-30), gastos: morumbi.enumerated().map { i, g in
                gasto(String(format: "k%02d", i + 1), g.1, g.2, g.3, meses(-g.0))
            }),
            copiaDaCasa("a8", ["valorEstimadoVenda": .nulo]),
        ])
        return .objeto(raiz)
    }
}
#endif
```

- [ ] **Step 4: Ver passar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/DadosDeExemploTests 2>&1 | grep -E "Test run with"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/AnaliseUITests 2>&1 | grep -E "Executed [0-9]+ tests" | tail -1
```
Expected: `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 3 tests in 1 suite passed` (cada um nas 6 datas); `Executed 3 tests, with 0 failures`.

- [ ] **Step 5: Conferir que o teste de formato prende o dia do mês**

Sem o teto de hoje no dia deste mês, a obra de 1 mês ganha gastos no futuro nos primeiros dias do mês (a parcela a vencer muda o gráfico), e o teste cai. O gasto do Terreno Granja fora deste mês (`dias(5)` no lugar de `desteMes(5)`) também cai, só pelo "neste mês, até hoje": as contagens dele dão 1 mesmo com o gasto no futuro, porque a série da evolução vai do mês do 1º gasto até o mês de hoje, ou até o do próprio gasto, se ele vier depois (`Series.swift:36-38`). Sem esse `#expect`, a troca passa: `✔ Test run with 3 tests in 1 suite passed`.

Run:
```bash
sed -i '' 's/min(n, Int(hojeISO.suffix(2)) ?? 1)/n/' app-ios/Custta/Falsos/VitrineDaAnalise.swift
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/DadosDeExemploTests 2>&1 | grep -E "Test run with"
git checkout -- app-ios/Custta/Falsos/VitrineDaAnalise.swift
sed -i '' 's/"Entrada do terreno", desteMes(5))/"Entrada do terreno", dias(5))/' app-ios/Custta/Falsos/VitrineDaAnalise.swift
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/DadosDeExemploTests 2>&1 | grep -E "Test run with"
git checkout -- app-ios/Custta/Falsos/VitrineDaAnalise.swift
```
Expected: `** TEST BUILD SUCCEEDED **` e `✘ Test run with 3 tests in 1 suite failed after … with 3 issues.`: o "neste mês, até hoje" cai em 2026-03-01 (no Terreno Granja, com o gasto do dia 5, e no Sobrado Vila Nova) e em 2026-10-08 (o gasto do dia 9 do Sobrado Vila Nova passa de hoje); depois, `** TEST BUILD SUCCEEDED **` e `✘ Test run with 3 tests in 1 suite failed after … with 6 issues.`: o "neste mês, até hoje" do Terreno Granja, nas 6 datas. O arquivo volta ao original. Compile de novo antes do passo seguinte.

- [ ] **Step 6: Conferir que os falsos não vão ao Release**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild build -project app-ios/Custta.xcodeproj -scheme Custta -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | tail -1
PROD=$(xcodebuild "${XB[@]}" -showBuildSettings 2>/dev/null | awk -F' = ' '/^ *BUILD_DIR = /{print $2; exit}')
for s in vitrineDaAnalise vitrineDoOrcamento RaizView; do echo "$s release=$(nm -a "$PROD/Release-iphonesimulator/Custta.app/Custta" | grep -c $s) debug=$(nm -a "$PROD/Debug-iphonesimulator/Custta.app/Custta.debug.dylib" | grep -c $s)"; done
```
Expected: `** TEST BUILD SUCCEEDED **`, `** BUILD SUCCEEDED **` e:
```
vitrineDaAnalise release=0 debug=30
vitrineDoOrcamento release=0 debug=16
RaizView release=90 debug=384
```

- [ ] **Step 7: Commit**

```bash
git add app-ios/Custta/Falsos/MontarFalso.swift app-ios/Custta/Falsos/VitrineDaAnalise.swift app-ios/CusttaTests/DadosDeExemploTests.swift app-ios/CusttaUITests/AnaliseUITests.swift
git commit -m "feat: falsos com as obras dos estados da análise" -m "Os marcos 2 e 3 testam e conferem os Gráficos, o Relatório, o \"Vale a pena?\" e o PDF em estados que a vitrine não tem. O CUSTTA_DADOS=analise monta a vitrine de sempre e mais as obras dos estados do mockup aprovado da etapa 4, com os números do gera-dados-p1.cjs: a Casa Alphaville vendida e sem a venda estimada, uma obra sem gastos, uma com 1 gasto, uma com 1 mês, uma com 1 tópico e uma com tópicos abaixo de 1%. Entra também uma obra com 30 meses de gastos, que o mockup não desenha, para o \"Mostrando os últimos 24 meses.\". A Casa Alphaville da vitrine já tem os 14 tópicos e as parcelas a vencer." -m "As datas contam de hoje, como na vitrine. As obras de 1 mês começam no dia 1º e os gastos delas caem neste mês, sem passar de hoje, para o estado não mudar com o dia do mês. Um teste de formato prende o que cada obra promete às telas, em seis datas, do dia 1º ao fim de fevereiro do ano bissexto."
```

### Task 29: O toque duplo no "Salvar" da vendida grava um gasto só

O gasto lançado de dentro de uma obra vendida vai para a obra escolhida na linha "Obra" (etapa 3): o `gravar` da folha troca a obra por trás dela (`folhas.navegar(.trocar(obraId))`) e só fecha a folha no turno seguinte, num `Task { @MainActor in folhas.fechar { … } }`, para ela descer com a animação dela (FolhaDoGasto.swift:636-637, desde 17/10). Até esse `Task` rodar, a folha ainda conta como aberta, e a guarda do `salvar()`, que olha a folha aberta (`saida.aberta(folhas, gastoId:)`, FolhaDeOrigem.swift:164-169), deixa passar o segundo toque de um toque duplo, que grava o gasto de novo. A janela é antiga, mas na `main` ela é curta demais para o `doubleTap()` do teste de tela: o `EstadosUITests/testToqueDuploNoSalvarDaVendidaLancaUmGasto` passou 20 de 20 na `main` (`9bda3aa`), 10 deles com 500 gastos a mais na obra que recebe o lançamento, porque a lista é preguiçosa e os gastos a mais quase não pesam na montagem. Só a obra em blocos da Tarefa 30, mais pesada de montar por trás da folha, abre a janela: sem esta tarefa, o teste reprova com ela em 7 de 7 rodadas na ponta de 29/10 e em 6 de 7 na pilha de 30/10 ("Total gasto, 48 lançamentos" em vez de 47), e com a marca passa em 7 de 7 nas duas (no 18 Pro). O rascunho ganha a marca `gravado`, ligada na hora, antes da troca, e o `salvar()` não grava com ela ligada, na mesma guarda da folha aberta. Nos outros caminhos, a folha fecha no mesmo turno, e a guarda dela basta.

**Files:**
- Modify: `app-ios/Custta/Telas/FolhaDoGasto.swift`
- Test (alterar): `tests/app-ios.test.cjs`

**Interfaces:**
- Consumes: `SaidaDaEdicao.aberta(_:gastoId:)` (FolhaDeOrigem.swift), `Folhas.navegar(_:)` e `Folhas.fechar(depois:)`; o `EstadosUITests/testToqueDuploNoSalvarDaVendidaLancaUmGasto` (etapa 3), que lê a contagem na pílula "Lançamentos".
- Produces: `RascunhoDoGasto.gravado: Bool`.

- [ ] **Step 1: Escrever os testes**

O teste de tela do toque duplo já existe e não muda. A guarda Node das folhas que gravam passa a exigir a marca na primeira linha do `salvar()` do gasto, junto da folha aberta, e a marca ligada logo antes da troca e do fechamento no turno seguinte.

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -716,7 +716,7 @@ test('folhas que gravam: o segundo toque de um toque duplo não grava de novo',
   // só às vezes sem ela; aqui, a guarda é a primeira linha da ação de cada folha.
   // A edição empurrada numa folha de origem (etapa 3) não fecha a folha: a guarda dela é a edição ainda no topo do caminho.
   const acoes = {
-    'app-ios/Custta/Telas/FolhaDoGasto.swift': ['private func salvar() {', /guard saida\.aberta\(folhas, gastoId: rascunho\.editado\?\.id\) else \{ return \}/],
+    'app-ios/Custta/Telas/FolhaDoGasto.swift': ['private func salvar() {', /guard !rascunho\.gravado, saida\.aberta\(folhas, gastoId: rascunho\.editado\?\.id\) else \{ return \}/],
     'app-ios/Custta/Telas/FolhaDaVenda.swift': ['private func confirmar(inicio: String, hoje: String) {', /guard folhas\.aberta != nil else \{ return \}/],
     'app-ios/Custta/Telas/FolhaDaObra.swift': ['private func salvar() {', /guard folhas\.aberta != nil else \{ return \}/],
     'app-ios/Custta/Telas/FolhaDoOrcamento.swift': ['private func salvar() {', /guard folhas\.aberta != nil else \{ return \}/],
@@ -731,6 +731,11 @@ test('folhas que gravam: o segundo toque de um toque duplo não grava de novo',
   assert.match(origem, /case \.folha: folhas\.aberta != nil\n\s*case \.origem\(let origem\): origem\.editando\(gastoId\)/,
                'a guarda da edição: a folha aberta ou, na origem, a edição no topo do caminho');
   assert.match(origem, /func editando\(_ gastoId: String\?\) -> Bool \{\n\s*guard let gastoId else \{ return false \}\n\s*return caminho\.last == \.editar\(gastoId\)/);
+  // O gasto lançado de dentro de uma vendida fecha a folha só no turno seguinte, e até lá ela ainda conta como aberta: a
+  // marca do rascunho, ligada antes de trocar a obra por trás da folha, é a guarda (a obra em blocos alarga essa janela).
+  assert.match(ler('app-ios/Custta/Telas/FolhaDoGasto.swift'),
+               /rascunho\.gravado = true\n\s*folhas\.navegar\(\.trocar\(obraId\)\)\n\s*Task \{ @MainActor in folhas\.fechar \{/,
+               'a marca na hora, antes da troca e do fechamento no turno seguinte');
 });
 
 test('volta à folha de origem: a trava do puxar lida no FolhaDoApp, o voltar escondido por modificador e o Z fixo por passo', () => {
```

- [ ] **Step 2: Ver falhar**

O teste de tela não tem "ver falhar" nesta tarefa: ele passa na tarefa anterior, porque a janela só abre com a obra em blocos, e reprova em 6 ou 7 de 7 rodadas na Tarefa 30 sem esta. Só a guarda Node reprova antes da marca.

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | grep -E "ℹ (pass|fail)|AssertionError"
```
Expected:
```
ℹ pass 68
ℹ fail 1
  AssertionError [ERR_ASSERTION]: app-ios/Custta/Telas/FolhaDoGasto.swift: a guarda do toque duplo na primeira linha da ação
```

- [ ] **Step 3: Implementar**

A marca entra no ramo da vendida, antes da troca: ligada depois, no `Task`, ela chegaria tarde como a folha. Nenhum `body` lê a marca, e ligá-la não redesenha a folha.

Em `app-ios/Custta/Telas/FolhaDoGasto.swift`:

```diff
--- a/app-ios/Custta/Telas/FolhaDoGasto.swift
+++ b/app-ios/Custta/Telas/FolhaDoGasto.swift
@@ -42,6 +42,9 @@ final class RascunhoDoGasto {
     var assinaturaAvisada: String?
     /// Gasto novo: passou do valor, e fechar passa a perguntar.
     var passouDoValor = false
+    /// Já gravou, e a folha só desce no turno seguinte (o gasto lançado de dentro de uma vendida): até lá ela ainda conta
+    /// como aberta, e a marca é que segura o segundo toque de um toque duplo.
+    var gravado = false
     private var inicial: [String] = []
 
     init(obra: Obra, editado: Gasto?, todas: [Obra], proprios: [TopicoProprio], hoje: String, vendida: String? = nil) {
@@ -578,8 +581,9 @@ struct PassoDosDetalhes: View {
 
     private func salvar() {
         // O primeiro toque já gravou, e a folha está descendo (ou a edição voltando à folha de origem): o segundo toque de
-        // um toque duplo não lança de novo.
-        guard saida.aberta(folhas, gastoId: rascunho.editado?.id) else { return }
+        // um toque duplo não lança de novo. A folha que só fecha no turno seguinte ainda conta como aberta: a marca do
+        // rascunho segura até lá.
+        guard !rascunho.gravado, saida.aberta(folhas, gastoId: rascunho.editado?.id) else { return }
         foco = nil
         let entrada = rascunho.entrada
         switch conferirGasto(entrada, editado: rascunho.editado, hoje: dataLocalISO(.now, fuso: .current)) {
@@ -633,6 +637,7 @@ struct PassoDosDetalhes: View {
                 // De dentro de uma vendida, o gasto foi para outra obra: ela toma o lugar da vendida por trás da folha, sem
                 // animação, e a folha desce no turno seguinte, com a animação dela, mostrando o gasto aceso onde ele entrou.
                 // No mesmo turno, a transação sem animação da troca valia também para a folha, que sumia de uma vez.
+                rascunho.gravado = true
                 folhas.navegar(.trocar(obraId))
                 Task { @MainActor in folhas.fechar { folhas.destacar(ids, novo: novo) } }
                 return
```

- [ ] **Step 4: Ver passar**

Run:
```bash
node --test tests/app-ios.test.cjs 2>&1 | tail -8 | grep -E "ℹ (pass|fail)"
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/EstadosUITests/testToqueDuploNoSalvarDaVendidaLancaUmGasto -test-iterations 5 2>&1 | grep -E "error:|Executed [0-9]+ test" | tail -1
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/GastoUITests -only-testing:CusttaUITests/FolhasDeOrigemUITests 2>&1 | grep -E "error:|Executed [0-9]+ test" | tail -1
```
Expected: `ℹ pass 69`, `ℹ fail 0`; `** TEST BUILD SUCCEEDED **`, sem aviso; `Executed 5 tests, with 0 failures (0 unexpected)`; `Executed 48 tests, with 1 failure (0 unexpected)` (os 24 de cada classe): a falha é o `FolhasDeOrigemUITests/testASetaDoIndicadorAbreAFolhaDoAPagar` ("Novembro de 2026, R$ 13.250,00"), que cai nos 3 últimos dias do mês em qualquer commit (achado 3 do PR 1a; consertado na `main` pelo #93, só de teste); rodou em 30/10, e fora desses dias dá 0.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Telas/FolhaDoGasto.swift tests/app-ios.test.cjs
git commit -m "fix: toque duplo no salvar do gasto de dentro da vendida grava uma vez" -m "O gasto lançado de dentro de uma obra vendida vai para outra obra: o gravar troca a obra por trás da folha e só fecha a folha no turno seguinte, para ela descer com a animação dela. Até esse turno, a folha ainda conta como aberta, e a guarda do Salvar, que olha a folha aberta, deixava o segundo toque de um toque duplo gravar o gasto de novo." -m "A janela existe desde 17/10, mas na main ela é curta demais para o toque duplo do teste de tela: ele passou 20 de 20, inclusive com 500 gastos a mais na obra que recebe o lançamento, porque a lista é preguiçosa. A obra em blocos da tarefa seguinte, mais pesada de montar por trás da folha, a abre: sem esta marca, o teste do toque duplo da vendida reprova em 6 ou 7 de 7 rodadas, com 48 lançamentos em vez de 47; com ela, passa em 7 de 7." -m "O rascunho ganha a marca gravado, ligada na hora, antes da troca, e o Salvar não grava com ela ligada. A guarda Node das folhas que gravam passa a exigir a marca na primeira linha do Salvar e ligada antes da troca."
```

### Task 30: O alto da obra em blocos, do título à venda

A obra troca o alto da etapa 3 pela identidade nova (spec, "Tela da obra"; mockup aprovado, `parte1.js:254-287` e `parte1-obra-topo.png`), com as peças do PR 1b: o nome no `TituloMono`, a `CapsulaDeMetadados` com a etiqueta da fase e "começou em … · N meses", o Total gasto no `BlocoSolido` verde e um `BlocoDeVidro` por assunto, na ordem da etapa 3 (Orçamento, Corrigido pelo banco, A pagar · 30 dias e Venda), com os números no `ValorEmDinheiro(_:mono:)` (`.principal` no Total gasto e no lucro, `.bloco` nos outros). Hoje a obra põe o título grande em SF Pro (`TituloDaObra`, PecasDaObra.swift:12), a pílula da fase (`PilulaDaFase`, :31) e os indicadores num cartão só (`IndicadoresDaObraView`, :86), numa coluna de 20 pt de borda e 10 entre as peças (ObraView.swift:74 e :126). A coluna passa a 16 pt da borda (`Grade.externa`) e 12 entre os blocos (`Grade.entreBlocos`); o título fica 8 pt acima da cápsula e a cápsula, 16 acima do sólido (mockup, `.ob-meta-w`). A regra do sólido (`solidoDaObra`, decisão 4 do mockup): na obra vendida com lucro bruto ≥ 0, o sólido é o "Lucro da venda", com a etiqueta "Vendida em dd/mm/aa", o lucro com o sinal ("+R$ 537.682,55") e "+R$ … acima do banco" (o acima do banco negativo vem com o menos U+2212, spec, "Decisões tomadas por recomendação"), e o Total gasto desce para um bloco de vidro logo depois do Orçamento; com prejuízo (B), o sólido volta a ser o Total gasto, e o lucro fica no bloco da Venda, no âmbar (`alertaNoVidro`) e não no vermelho de antes (`negativoNoVidro`), como o spec pede ("em âmbar, nunca vermelho"). Sem gastos, o sólido mostra R$ 0,00 com "Toque no + para lançar o primeiro gasto." no lugar de "bruto, sem correção" (o texto novo do mockup, `parte1.js:269`); na vendida sem gastos, não: ali o + não lança gasto nessa obra (abre a folha com a linha "Obra", para escolher outra), e o Total gasto, no vidro, fica com o "bruto, sem correção" (`notaDoTotal`). O Orçamento e o A pagar são blocos inteiros que abrem a tela Orçamento e a folha do A pagar, com a seta de 14 pt (`SetaDoBloco`, 20 na letra de acessibilidade) 10 pt depois do texto (`.k-linha` do mockup); o `LinhaDoOrcamento` vira o bloco (só a obra o usa), com "Orçamento" no rótulo do bloco e "sobra"/"passou" no número mono. Cada bloco continua um elemento só para o VoiceOver (`.combine`; achado 3 do PR 1b: o número solto reprova a descrição suficiente), com os mesmos identificadores (`indicadorTotal`, `indicadorOrcamento`, `indicadorCorrigido`, `indicadorAPagar`, `indicadorVenda`, `faseDaObra`, `tituloDaObra`) e o novo `indicadorLucro`; o título pequeno da barra passa ao `TituloPequenoMono` só na obra (a tela Orçamento fica com o de antes), com a letra da tela lida fora da barra, por uma vista de fundo da obra (`LeitorDaLetra`), e guardada na `BarraDaObra` (`barra.letra`), que só o título pequeno lê: dentro do `ToolbarItem`, o `dynamicTypeSize` para antes da letra de acessibilidade (Tarefa 21). A `NotaDoBloco` ganha a cor opcional (o lucro da venda), e ela e o `RotuloDoBloco` ganham o `fixedSize` vertical, para quebrar em vez de cortar na letra grande: sem ele, a auditoria da obra na maior letra (`AuditoriaUITests/testObraNoMaiorTamanho`) acha "Text clipped" em "A pagar · 30 dias", o rótulo do bloco com a seta ao lado, como o rótulo da etapa 3 cortava ("A pagar · 3…").

**Files:**
- Modify: `app-ios/Custta/Identidade/Blocos.swift`
- Create: `app-ios/Custta/Telas/BlocosDaObra.swift`
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Modify: `app-ios/Custta/Telas/PecasDaObra.swift`
- Modify: `app-ios/Custta/Telas/PecasDoOrcamento.swift`
- Test (novo): `app-ios/CusttaTests/BlocosDaObraTests.swift`
- Test (alterar): `app-ios/CusttaTests/LinhaDoOrcamentoTests.swift`
- Test (alterar): `app-ios/CusttaTests/OrcamentoEm375Tests.swift`
- Test (alterar): `app-ios/CusttaUITests/AuditoriaUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/ObraUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/OrcamentoUITests.swift`
- Test (alterar): `tests/app-ios.test.cjs`

**Interfaces:**
- Consumes: `TituloMono(texto:identificador:)`, `TituloPequenoMono(texto:letra:)`, `CapsulaDeMetadados`, `BlocoSolido`, `BlocoDeVidro`, `CabecalhoDoBloco(rotulo:)`, `EtiquetaDoSolido(texto:)`, `NotaDoBloco(texto:)`, `ValorEmDinheiro(_:mono:cor:)` e `Grade` (PR 1b); `indicadoresDaObra(_:taxa:hoje:)`, `orcamentoObra(_:)`, `lucroVenda(_:taxa:)`, `moeda(_:)`, `dataCurta(_:)` e `textoDoInicio(_:hoje:)` (núcleo); `EtiquetaDoIndicador` e `EtiquetaDeFase` (etapas 2 e 3).
- Produces: `enum SolidoDaObra { case total; case lucro(valor:etiqueta:nota:) }`; `solidoDaObra(_ obra: Obra, taxa: Double) -> SolidoDaObra`; `notaDoTotal(_ obra: Obra) -> String`; `comSinal(_ valor: Double) -> String`; `BlocosDaObra(obra:taxa:hoje:abrirAPagar:)`; `SetaDoBloco()`; `NotaDoBloco(texto:cor:)`; `TituloDaBarraDaObra(barra:nome:mono:)`, `BarraDaObra.letra`; o identificador `indicadorLucro`.

- [ ] **Step 1: Escrever os testes**

Os de unidade prendem o que o sólido mostra em cada fase (construção e pronta, vendida com prejuízo, com lucro, com lucro zero e com o acima do banco negativo), a nota do Total gasto sem gastos (o convite, menos na vendida), o sinal dos valores e a varredura por `sizeThatFits` dos blocos montados em todos os tamanhos de letra, com e sem o Negrito, em escala 3, nas larguras de 343, 370 e 408 pt, na obra da vitrine, na vendida com lucro, na vendida com prejuízo (a v3 da `vitrineComPrejuizo`) e com o maior valor (R$ 1.000.000.000,00) no sólido (achados 2 e 6 do PR 1b). Com o Negrito, o `CabecalhoDoBloco` de antes do conserto da Tarefa 19 (o `Spacer` ao lado do rótulo) passava 1/3 de pt nos 408, e a varredura o pega. Os de tela conferem a grade (16 pt de borda, a largura da coluna, 12 pt entre os blocos e 16 entre a cápsula e o sólido), a vendida com o lucro no sólido e o Total gasto logo depois do Orçamento, a vendida com prejuízo e o sólido da obra sem gastos; o do orçamento passa a medir o bloco próprio (12 pt abaixo do sólido e a barra com 310 pt nos 370 do bloco). O `LinhaDoOrcamentoTests` da etapa 3 passa a medir a seta nova (o bloco com a seta tem a coluna de texto do bloco sem ela 30 pt mais estreito, os 20 da seta e os 10 do vão, nas larguras de 343, 370 e 408 pt), e as duas guardas Node dos chevrons do Orçamento e do A pagar viram uma, a da `SetaDoBloco` (o teto no AX2, 14 e 20 pt, fora do VoiceOver e do laudo, usada pelos dois blocos). Uma guarda Node nova prende o prejuízo no âmbar: a nota da venda usa `lucroPositivo ? .positivoNoVidro : .alertaNoVidro`, e o `negativoNoVidro` não aparece nos blocos (nenhum teste de tela vê a cor, e o laudo, que mede só o contraste, passa também com o vermelho). O `OrcamentoEm375Tests` da etapa 3 passa a medir o bloco do orçamento nos 343 pt da coluna num iPhone de 375 (375 menos as bordas de 16), e não mais nos 335 da linha de antes. A auditoria aceita o "Text clipped" do `tituloPequenoDaBarra`, pelo identificador do próprio texto (ele não está num `.combine`): o título pequeno mono corta o nome comprido com reticências, como o do sistema, e na maior letra (20 pt) "Sobrado Granja Viana" passa dos 236 pt (`AuditoriaUITests/testParte3NoMaiorTamanho`, no 18 Pro); o título pequeno da etapa 3, em SF Pro e com teto no xxxLarge, cabia. O comentário do `testParte3NoMaiorTamanho` passa a dizer onde as rolagens fixas caem na obra em blocos (no 18 Pro, na maior letra): a v2 a 800 no Corrigido e no A pagar; a v2 a 1600 na Venda estimada e no "Registrar venda", com a ação de vidro sob a cápsula; a v3 a 1600 no A pagar e no começo da Venda. As rolagens ficam: mais fundo, com as duas ações à vista (a v2 a 1850 e a v3 a 2250, ou rolando por arrasto até a ação), a auditoria reprova no 18 Pro, com quatro achados sem elemento na v2 e "Text clipped" nos blocos de cima da v3 (nos tamanhos menores que ela experimenta, a rolagem passa do fim do alto; a v3 a 700 e a 1300 passa). A prova do iOS 26 é a CI do PR.

Criar `app-ios/CusttaTests/BlocosDaObraTests.swift`:

```swift
import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* O alto da obra em blocos (etapa 4, PR 1c): o que o sólido mostra em cada fase (o lucro na vendida com lucro, decisão 4:
   A; o Total gasto no resto, e na vendida com prejuízo, B), o sinal dos valores, e os blocos montados sem passar da largura
   em nenhum tamanho de letra, com o maior valor no sólido (o irmão fracionário alargava a coluna inteira; memória
   `irmao-fracionario-passa-um-pixel`). */
@MainActor
struct BlocosDaObraTests {
    /// Uma obra com um gasto de 100 mil em 01/01/26 e, se vendida, a venda em 01/07/26.
    private func obra(fase: String = "construcao", venda: Double? = nil, gasto: Double = 100_000) -> Obra {
        var campos: [String: ValorJSON] = [
            "id": .texto("o"), "nome": .texto("Casa"), "fase": .texto(fase), "dataInicio": .texto("2026-01-01"),
            "gastos": .lista([.objeto(["id": .texto("g1"), "valor": .numero(gasto), "topico": .texto("terreno"),
                                       "descricao": .texto("Terreno"), "data": .texto("2026-01-01"), "pagamento": .texto("pix")])]),
        ]
        if let venda { campos["venda"] = .objeto(["valor": .numero(venda), "data": .texto("2026-07-01")]) }
        return Estado.de(.objeto(["obras": .lista([.objeto(campos)])])).obras[0]
    }

    @Test func solidoDoTotalForaDaVendidaComLucro() {
        #expect(solidoDaObra(obra(), taxa: 1) == .total)
        #expect(solidoDaObra(obra(fase: "pronta"), taxa: 1) == .total)
        // Com prejuízo (B), o sólido volta a ser o Total gasto.
        #expect(solidoDaObra(obra(fase: "vendida", venda: 80_000), taxa: 0) == .total)
    }

    @Test func solidoDoLucroNaVendida() {
        // Sem correção, o acima do banco é o próprio lucro.
        #expect(solidoDaObra(obra(fase: "vendida", venda: 150_000), taxa: 0)
            == .lucro(valor: "+R$\u{a0}50.000,00", etiqueta: "Vendida em 01/07/26", nota: "+R$\u{a0}50.000,00 acima do banco"))
        // Lucro zero conta como lucro, como o `>= 0` do mockup.
        #expect(solidoDaObra(obra(fase: "vendida", venda: 100_000), taxa: 0)
            == .lucro(valor: "+R$\u{a0}0,00", etiqueta: "Vendida em 01/07/26", nota: "+R$\u{a0}0,00 acima do banco"))
        // Com lucro e o acima do banco negativo (10% ao mês por 6 meses passa dos 50 mil), o sólido continua o lucro, e o
        // acima do banco vem com o menos.
        guard case let .lucro(valor, _, nota) = solidoDaObra(obra(fase: "vendida", venda: 150_000), taxa: 10) else {
            Issue.record("o sólido devia ser o lucro"); return
        }
        #expect(valor == "+R$\u{a0}50.000,00")
        #expect(nota.hasPrefix("\u{2212}R$\u{a0}") && nota.hasSuffix(" acima do banco"), "\(nota)")
    }

    /// Sem gastos, o Total gasto convida a lançar o primeiro pelo +, menos na vendida: o + de lá não lança nela (abre a folha
    /// com a linha "Obra", para escolher outra).
    @Test func notaDoTotalSemGastos() {
        var semGastos = obra()
        semGastos.gastos = []
        #expect(notaDoTotal(semGastos) == "Toque no + para lançar o primeiro gasto.")
        #expect(notaDoTotal(obra()) == "bruto, sem correção")
        var vendida = obra(fase: "vendida", venda: 150_000)
        vendida.gastos = []
        #expect(notaDoTotal(vendida) == "bruto, sem correção", "a vendida sem gastos não convida a lançar nela")
    }

    @Test func valorComSinal() {
        #expect(comSinal(1234.5) == "+R$\u{a0}1.234,50")
        #expect(comSinal(-1234.5) == "\u{2212}R$\u{a0}1.234,50")
        #expect(comSinal(0) == "+R$\u{a0}0,00")
    }

    /// Os blocos montados não passam da largura da coluna em nenhum tamanho de letra, com e sem o Negrito, nas larguras dos
    /// iPhones (375, 402 e 440 pt menos as bordas de 16), em escala 3: na obra da vitrine, na vendida com lucro, na vendida com
    /// prejuízo (a v3 da vitrine com prejuízo: o Total gasto no sólido e o lucro no âmbar) e com o maior valor no sólido. Com
    /// o Negrito, o rótulo do sólido ao lado da etiqueta passava 1/3 de pt nos 408 (o `CabecalhoDoBloco` do PR 1b).
    @Test func blocosNaoPassamDaLargura() {
        let vitrine = Estado.de(DadosDeExemplo.vitrine()).obras[0]
        var vendida = vitrine
        vendida.fase = .vendida
        vendida.venda = Venda(valor: 1_380_000, data: "2026-07-01")
        let prejuizo = Estado.de(DadosDeExemplo.vitrineComPrejuizo()).obras[2]
        let obras = [vitrine, vendida, prejuizo, obra(gasto: 1_000_000_000)]
        for negrito in [false, true] {
            for (i, obra) in obras.enumerated() {
                for letra in DynamicTypeSize.allCases {
                    for largura in [CGFloat(343), 370, 408] {
                        let blocos = BlocosDaObra(obra: obra, taxa: 1, hoje: "2026-10-12") {}.dynamicTypeSize(letra)
                            .environment(\.legibilityWeight, negrito ? .bold : .regular).environment(\.displayScale, 3)
                        let medida = UIHostingController(rootView: blocos).sizeThatFits(in: CGSize(width: largura, height: 20_000)).width
                        #expect(medida == largura, "obra \(i), \(letra), negrito \(negrito), em \(largura): \(medida)")
                    }
                }
            }
        }
    }
}
```

Em `app-ios/CusttaTests/LinhaDoOrcamentoTests.swift`:

```diff
--- a/app-ios/CusttaTests/LinhaDoOrcamentoTests.swift
+++ b/app-ios/CusttaTests/LinhaDoOrcamentoTests.swift
@@ -3,9 +3,9 @@ import SwiftUI
 @testable import Custta
 import CusttaNucleo
 
-/* A linha do orçamento na obra, na maior letra (conferência do Verniz contra o mockup da etapa 3, PR 1): o chevron ocupa só os
-   18 pt dele, e a coluna de texto fica com os 306 pt do mockup no 18 Pro, com "80% usado de" numa linha. Medida num
-   UIHostingController em escala 1, na largura da linha na tela (o iPhone menos os 20 de cada lado). */
+/* O bloco do orçamento na obra, na maior letra (conferência do Verniz contra o mockup da etapa 3, PR 1; o bloco da etapa 4,
+   PR 1c): a seta ocupa só os 20 pt dela, 10 pt depois do texto. Medido num UIHostingController em escala 1, na largura do
+   bloco na tela (o iPhone menos os 16 de cada lado). */
 @MainActor
 struct LinhaDoOrcamentoTests {
     private func altura(_ resumo: ResumoOrcamento, comSeta: Bool, _ largura: CGFloat) -> CGFloat {
@@ -14,18 +14,19 @@ struct LinhaDoOrcamentoTests {
             .sizeThatFits(in: CGSize(width: largura, height: CGFloat.infinity)).height
     }
 
-    /// Com a seta, a coluna de texto é a da linha sem seta 22 pt mais estreita: os 18 do chevron e os 4 do vão. Sem o quadro,
-    /// o símbolo cresce com a letra e reserva cerca de 6 pt além do traço: no 18 Pro a coluna caía para 284, e o "de" de
-    /// "80% usado de" ficava sozinho numa linha (o orçamento por tópico da vitrine). Nas três larguras de iPhone: 375, 402 e 440.
-    @Test(arguments: [CGFloat(335), 362, 400]) func chevronOcupaOsDezoitoDoMockup(largura: CGFloat) throws {
+    /// Com a seta, a coluna de texto é a do bloco sem seta 30 pt mais estreito: os 20 da seta e os 10 do vão (o .k-linha do
+    /// mockup). Sem o quadro, o símbolo cresce com a letra e reserva cerca de 6 pt além do traço: no 18 Pro a coluna caía, e o
+    /// "de" de "80% usado de" ficava sozinho numa linha (o orçamento por tópico da vitrine). Nas três larguras de iPhone: 375,
+    /// 402 e 440.
+    @Test(arguments: [CGFloat(343), 370, 408]) func setaOcupaOsVinteDoMockup(largura: CGFloat) throws {
         let dados = [DadosDeExemplo.vitrine(), DadosDeExemplo.vitrineDoOrcamento("porTopico"), DadosDeExemplo.vitrineDoOrcamento("perto"),
                      DadosDeExemplo.vitrineDoOrcamento("passou")]
         for (i, base) in dados.enumerated() {
             let casa = try #require(Estado.de(base).obras.first { $0.id == "v1" })
             let resumo = try #require(orcamentoObra(casa))
             let comSeta = altura(resumo, comSeta: true, largura)
-            let semSeta = altura(resumo, comSeta: false, largura - 22)
-            #expect(comSeta == semSeta, "vitrine \(i): com a seta, \(comSeta); sem ela e 22 pt mais estreita, \(semSeta)")
+            let semSeta = altura(resumo, comSeta: false, largura - 30)
+            #expect(comSeta == semSeta, "vitrine \(i): com a seta, \(comSeta); sem ela e 30 pt mais estreito, \(semSeta)")
         }
     }
 }
```

Em `app-ios/CusttaTests/OrcamentoEm375Tests.swift`:

```diff
--- a/app-ios/CusttaTests/OrcamentoEm375Tests.swift
+++ b/app-ios/CusttaTests/OrcamentoEm375Tests.swift
@@ -5,7 +5,8 @@ import CusttaNucleo
 
 /* O orçamento num iPhone de 375 pt (etapa 3, PR 1; as linhas com a seta, do PR 2), na maior letra, com e sem Texto em
    negrito: nenhuma peça passa da largura. O laudo e as auditorias rodam no 18 Pro (402) e no Pro Max (440); 375 só aqui, num UIHostingController em escala
-   1, com a largura de cada peça na tela (375 menos os 20 de cada lado; na folha, a linha já traz o recuo dela). */
+   1, com a largura de cada peça na tela: o bloco do orçamento na obra, 375 menos as bordas de 16 (etapa 4); as peças da
+   tela Orçamento, 375 menos os 20 de cada lado; na folha, a linha já traz o recuo dela. */
 @MainActor
 struct OrcamentoEm375Tests {
     private let porTopico = Estado.de(DadosDeExemplo.vitrineDoOrcamento("porTopico"))
@@ -19,7 +20,7 @@ struct OrcamentoEm375Tests {
     @Test(arguments: [false, true]) func telaDaObraEOrcamentoCabemEm375(negrito: Bool) throws {
         let casa = try #require(porTopico.obras.first { $0.id == "v1" })
         let resumo = try #require(orcamentoObra(casa))
-        #expect(largura(LinhaDoOrcamento(resumo: resumo, comSeta: true), 335, negrito: negrito) <= 335, "a linha do orçamento")
+        #expect(largura(LinhaDoOrcamento(resumo: resumo, comSeta: true), 343, negrito: negrito) <= 343, "o bloco do orçamento")
         #expect(largura(CartaoDoOrcamento(resumo: resumo), 335, negrito: negrito) <= 335, "o cartão")
         let topicos = mapaDeTopicos(porTopico.config.topicosProprios)
         for linha in linhasPorTopico(resumo, topicos: topicos, gastos: casa.gastos) + linhasForaDoOrcamento(resumo, topicos: topicos) {
```

Em `app-ios/CusttaUITests/AuditoriaUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/AuditoriaUITests.swift
+++ b/app-ios/CusttaUITests/AuditoriaUITests.swift
@@ -72,6 +72,11 @@ final class AuditoriaUITests: XCTestCase {
             switch achado.auditType {
             case .dynamicType where noTotal && achado.compactDescription.contains("partially"), .textClipped where noTotal:
                 fora = true
+            // O título pequeno da obra em SF Mono (etapa 4): numa linha só, até 236 pt, ele corta o nome comprido com reticências,
+            // como o título pequeno do sistema, em vez de empurrar o voltar e o lápis; na maior letra (20 pt), "Sobrado Granja
+            // Viana" passa dos 236. O nome inteiro está no título grande, no VoiceOver e no Visualizador de Conteúdo Grande.
+            case .textClipped where elemento.identifier == "tituloPequenoDaBarra":
+                fora = true
             case .dynamicType:
                 // Os títulos das barras param perto de 22 pt, como os do sistema (mockup da etapa 2), com o Visualizador de
                 // Conteúdo Grande: o pequeno da obra e o das folhas (na maior letra o nome da obra sai da barra da folha e
@@ -340,12 +345,16 @@ final class AuditoriaUITests: XCTestCase {
         }
     }
 
-    /// As telas da etapa 2, parte 3, na maior letra: a obra pronta (com as duas ações da fase, a sólida e a de vidro)
-    /// e a vendida (a venda com o lucro e o "Desfazer venda") em rolagens fixas, a lista vazia, as folhas da obra (nova
-    /// e editar), a da venda e a do gasto lançado de dentro de uma vendida. Na obra, rolagem fixa e não o arrasto:
-    /// logo depois do arrasto, a auditoria marcava "Text clipped" nos indicadores da v2, que parados não cortam (triagem em
-    /// 0, 400 e 800 pt, na v1 e na v2). A vendida fica sem os 800 pt: ali estão os indicadores, os mesmos da v2 a 800, e no
-    /// iOS 26 eles davam sete achados sem elemento enquanto a auditoria trocava o tamanho da letra (CI, 17/10; no Mac passam).
+    /// As telas da etapa 2, parte 3, na maior letra: a obra pronta e a vendida em rolagens fixas, a lista vazia, as folhas
+    /// da obra (nova e editar), a da venda e a do gasto lançado de dentro de uma vendida. Na obra, rolagem fixa e não o
+    /// arrasto: logo depois do arrasto, a auditoria marcava "Text clipped" nos indicadores da v2, que parados não cortam
+    /// (triagem em 0, 400 e 800 pt, na v1 e na v2). A vendida fica sem os 800 pt: no iOS 26, os blocos de lá davam sete
+    /// achados sem elemento enquanto a auditoria trocava o tamanho da letra (CI, 17/10; no Mac passam).
+    /// Com a obra em blocos (etapa 4), mais alta, as rolagens caem em outras peças (18 Pro): a v2 a 800, no Corrigido e no
+    /// A pagar; a v2 a 1600, na Venda estimada e no "Registrar venda", com a ação de vidro sob a cápsula; a v3 a 1600, no
+    /// A pagar e no começo da Venda. Mais fundo não dá: a auditoria troca o tamanho da letra, e nos menores a rolagem passa
+    /// do fim do alto. Com as duas ações à vista, a v2 a 1850 deu quatro achados sem elemento, e a v3 a 2250 (a venda e o
+    /// "Desfazer venda") deu "Text clipped" nos blocos de cima; rolar por arrasto até a ação deu o mesmo.
     @MainActor func testParte3NoMaiorTamanho() throws {
         var app: XCUIApplication
         for (obra, rolagem) in [("v2", 0), ("v2", 800), ("v2", 1600), ("v3", 0), ("v3", 1600)] {
```

Em `app-ios/CusttaUITests/ObraUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/ObraUITests.swift
+++ b/app-ios/CusttaUITests/ObraUITests.swift
@@ -98,6 +98,60 @@ final class ObraUITests: XCTestCase {
     func testObraSemGastos() {
         let app = abrirApp(conta: "senha", dados: "exemplo", abrir: "obra:o3")
         XCTAssertTrue(app.elemento("obraSemGastos").waitForExistence(timeout: 10))
-        XCTAssertTrue(app.elemento("indicadorTotal").label.contains("sem gastos"))
+        let total = app.elemento("indicadorTotal").label
+        XCTAssertTrue(total.contains("sem gastos") && total.contains("R$\u{a0}0,00"), total)
+        // Etapa 4: o sólido com R$ 0,00 convida a lançar o primeiro gasto.
+        XCTAssertTrue(total.contains("Toque no + para lançar o primeiro gasto."), total)
+    }
+
+    /// Etapa 4 (PR 1c): o alto em blocos, na grade 16/34. O título, a cápsula e os blocos a 16 pt da borda; os blocos na
+    /// largura da coluna, 12 pt um do outro, na ordem do mockup (o sólido do Total gasto, Orçamento, Corrigido, A pagar e
+    /// Venda) e a cápsula 16 pt acima do sólido.
+    func testOAltoEmBlocosNaGrade() {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
+        let largura = app.windows.firstMatch.frame.width
+        let ids = ["indicadorTotal", "indicadorOrcamento", "indicadorCorrigido", "indicadorAPagar", "indicadorVenda"]
+        let quadros = ids.map { app.elemento($0).frame }
+        for (id, quadro) in zip(ids, quadros) {
+            XCTAssertEqual(quadro.minX, 16, accuracy: 0.5, "\(id) na borda de 16 pt")
+            XCTAssertEqual(quadro.width, largura - 32, accuracy: 0.5, "\(id) na largura da coluna")
+        }
+        for i in 1..<quadros.count {
+            XCTAssertEqual(quadros[i].minY - quadros[i - 1].maxY, 12, accuracy: 0.5, "\(ids[i]) 12 pt abaixo de \(ids[i - 1])")
+        }
+        let titulo = app.elemento("tituloDaObra").frame, fase = app.elemento("faseDaObra").frame
+        XCTAssertEqual(titulo.minX, 16, accuracy: 0.5, "o título solto na borda de 16 pt")
+        XCTAssertEqual(fase.minX, 16, accuracy: 0.5, "a cápsula na borda de 16 pt")
+        XCTAssertEqual(quadros[0].minY - fase.maxY, 16, accuracy: 0.5, "a cápsula 16 pt acima do sólido")
+        XCTAssertFalse(app.elemento("indicadorLucro").exists, "fora da vendida, o sólido é o Total gasto")
+    }
+
+    /// A vendida com lucro (decisão 4: A): o sólido é o lucro da venda, e o Total gasto desce para o vidro, logo depois do
+    /// Orçamento, com os mesmos números.
+    func testVendidaComLucroNoSolido() {
+        let app = abrirApp(conta: "senha", dados: "analise", abrir: "obra:a1")
+        let lucro = app.elemento("indicadorLucro")
+        XCTAssertTrue(lucro.waitForExistence(timeout: 10))
+        XCTAssertTrue(lucro.label.hasPrefix("Lucro da venda, Vendida em ") && lucro.label.contains(", +R$\u{a0}")
+                      && lucro.label.hasSuffix(" acima do banco"), lucro.label)
+        let fase = app.elemento("faseDaObra").frame, orcamento = app.elemento("indicadorOrcamento").frame
+        let total = app.elemento("indicadorTotal")
+        XCTAssertEqual(lucro.frame.minY - fase.maxY, 16, accuracy: 0.5, "o lucro é o sólido, logo abaixo da cápsula")
+        XCTAssertEqual(orcamento.minY - lucro.frame.maxY, 12, accuracy: 0.5, "o Orçamento logo depois do sólido")
+        XCTAssertEqual(total.frame.minY - orcamento.maxY, 12, accuracy: 0.5, "o Total gasto logo depois do Orçamento")
+        XCTAssertTrue(total.label.contains("R$\u{a0}842.317,45") && total.label.contains("46 lançamentos"), total.label)
+        XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.380.000,00"))
+    }
+
+    /// Com prejuízo (B), o sólido volta a ser o Total gasto, e o lucro negativo fica no bloco da venda.
+    func testVendidaComPrejuizoNoTotal() {
+        let app = abrirApp(conta: "senha", dados: "prejuizo", abrir: "obra:v3")
+        let total = app.elemento("indicadorTotal")
+        XCTAssertTrue(total.waitForExistence(timeout: 10))
+        XCTAssertFalse(app.elemento("indicadorLucro").exists, "com prejuízo, nada de lucro no sólido")
+        XCTAssertEqual(total.frame.minY - app.elemento("faseDaObra").frame.maxY, 16, accuracy: 0.5, "o Total gasto é o sólido")
+        let venda = app.elemento("indicadorVenda").label
+        XCTAssertTrue(venda.contains("R$\u{a0}800.000,00") && venda.contains("lucro -R$"), venda)
     }
 }
```

Em `app-ios/CusttaUITests/OrcamentoUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/OrcamentoUITests.swift
+++ b/app-ios/CusttaUITests/OrcamentoUITests.swift
@@ -39,18 +39,20 @@ final class OrcamentoUITests: XCTestCase {
         }
     }
 
-    /// A primeira linha do grupo dos indicadores: logo abaixo do Total gasto, que não sai do lugar, e antes do Corrigido.
+    /// O primeiro bloco depois do sólido: logo abaixo do Total gasto, que não sai do lugar, e antes do Corrigido (etapa 4:
+    /// um bloco de vidro por assunto).
     func testALinhaVemLogoAbaixoDoTotalGasto() {
         let (app, _) = linha("porTopico")
         let total = app.elemento("indicadorTotal").frame, orcamento = app.elemento("indicadorOrcamento").frame
         let corrigido = app.elemento("indicadorCorrigido").frame
-        // O grupo começa 10 pt abaixo do Total gasto, e a linha inteira é o botão que abre a tela Orçamento: o quadro dela começa
-        // no alto e na borda do grupo, 18 pt antes do texto do Corrigido (o quadro de uma linha sem toque começa no texto).
-        XCTAssertEqual(orcamento.minY - total.maxY, 10, accuracy: 1, "a primeira linha do grupo, logo abaixo do Total gasto")
-        XCTAssertLessThanOrEqual(orcamento.maxY, corrigido.minY, "antes do Corrigido")
-        XCTAssertEqual(orcamento.minX + 18, corrigido.minX, accuracy: 0.5, "no mesmo grupo")
-        // Na letra padrão, o chevron no quadro de 9 pt do mockup: a barra com os 315,1 pt dele.
-        XCTAssertEqual(larguraDaBarra(app.elemento("indicadorOrcamento")), 315.1, accuracy: 0.5, "a largura da barra")
+        // O bloco começa 12 pt abaixo do sólido, e o bloco inteiro é o botão que abre a tela Orçamento: o quadro dele é o do
+        // bloco, na mesma borda do Corrigido, o bloco seguinte.
+        XCTAssertEqual(orcamento.minY - total.maxY, 12, accuracy: 0.5, "o primeiro bloco, logo abaixo do Total gasto")
+        XCTAssertEqual(corrigido.minY - orcamento.maxY, 12, accuracy: 0.5, "antes do Corrigido")
+        XCTAssertEqual(orcamento.minX, corrigido.minX, accuracy: 0.5, "na mesma borda")
+        // Na letra padrão, o recuo de 18 dos dois lados e a seta de 14 pt, 10 pt depois da barra (mockup, .k-linha): a barra
+        // com 310 pt nos 370 do bloco.
+        XCTAssertEqual(larguraDaBarra(app.elemento("indicadorOrcamento")), 310, accuracy: 0.5, "a largura da barra")
     }
 
     /// A largura da barra da linha do orçamento, por pixel (o VoiceOver junta a linha num elemento só): a corrida mais longa
```

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -516,28 +516,30 @@ test('dica do fim do modo total: cresce com a letra e quebra linha, sem altura f
   assert.doesNotMatch(dica, /\.frame\([^)]*height|\.lineLimit|minimumScaleFactor/, 'sem altura fixa nem limite de linhas');
 });
 
-test('linha do orçamento: o chevron para no AX2 e ocupa os 18 pt do mockup na maior letra e os 9 na letra padrão', () => {
-  // O LinhaDoOrcamentoTests mede os 18 pt da coluna do chevron, mas não o teto: com o quadro de 18, um símbolo que crescesse
-  // até a AX5 passaria do quadro sem mudar a altura da linha. E nenhum teste de tela vê o símbolo, que fica fora da árvore de
-  // acessibilidade (accessibilityHidden) e do laudo (foraDoLaudo).
-  const t = ler('app-ios/Custta/Telas/PecasDoOrcamento.swift');
-  const inicio = t.indexOf('struct LinhaDoOrcamento');
-  assert.ok(inicio >= 0, 'a LinhaDoOrcamento');
-  const linha = t.slice(inicio, t.indexOf('\n}\n', inicio));
-  assert.match(linha, /Image\(systemName: "chevron\.right"\)\n\s*\.font\(\.body\.weight\(\.semibold\)\)\n(?:\s*\/\/.*\n)*\s*\.dynamicTypeSize\(\.\.\.DynamicTypeSize\.accessibility2\)\n\s*\.frame\(width: tamanho\.isAccessibilitySize \? 18 : 9\)\n/,
-    'o chevron para no AX2 e ocupa 18 pt na letra de acessibilidade e 9 na padrão');
-});
-
-test('linha do A pagar: o chevron é o do Orçamento, para no AX2 e ocupa os 18 pt do mockup na maior letra e os 9 na letra padrão', () => {
-  // Os dois chevrons do cartão dos indicadores são o mesmo .k-chev do mockup. Sem o teto, o do A pagar sai com ~27 × 46 pt
-  // na AX5, contra os 17 × 29 do Orçamento. E nenhum teste de tela vê o símbolo, que fica fora da árvore de acessibilidade
-  // (accessibilityHidden) e do laudo (foraDoLaudo).
-  const t = ler('app-ios/Custta/Telas/PecasDaObra.swift');
-  const inicio = t.indexOf('private var aPagar: some View');
-  assert.ok(inicio >= 0, 'a linha do A pagar');
-  const linha = t.slice(inicio, t.indexOf('\n    }\n', inicio));
-  assert.match(linha, /Image\(systemName: "chevron\.right"\)\n\s*\.font\(\.body\.weight\(\.semibold\)\)\n(?:\s*\/\/.*\n)*\s*\.dynamicTypeSize\(\.\.\.DynamicTypeSize\.accessibility2\)\n\s*\.frame\(width: tamanho\.isAccessibilitySize \? 18 : 9\)\n/,
-    'o chevron do A pagar é o do Orçamento: para no AX2 e ocupa 18 pt na letra de acessibilidade e 9 na padrão');
+test('bloco da venda da obra: o lucro em verde e o prejuízo em âmbar, nunca no vermelho', () => {
+  // O spec pede o prejuízo "em âmbar, nunca vermelho". Nenhum teste de tela vê a cor: o laudo mede só o contraste, e o
+  // vermelho de antes (negativoNoVidro) também passa nele.
+  const t = ler('app-ios/Custta/Telas/BlocosDaObra.swift');
+  assert.match(t, /corDaNota: lucroPositivo \? \.positivoNoVidro : \.alertaNoVidro\)/, 'a nota do lucro no verde e a do prejuízo no âmbar');
+  assert.doesNotMatch(t, /negativoNoVidro/, 'nada no vermelho nos blocos da obra');
+});
+
+test('seta dos blocos da obra: para no AX2 e ocupa os 20 pt do mockup na maior letra e os 14 na letra padrão', () => {
+  // O .chev do mockup da etapa 4 (14 × 20 pt; 20 × 36 na letra máxima), nos blocos do Orçamento e do A pagar. Sem o teto, o
+  // símbolo sai com ~27 × 46 pt na AX5, mais largo que o quadro. Nenhum teste de tela vê o símbolo, que fica fora da árvore
+  // de acessibilidade (accessibilityHidden) e do laudo (foraDoLaudo).
+  const t = ler('app-ios/Custta/Telas/BlocosDaObra.swift');
+  const inicio = t.indexOf('struct SetaDoBloco');
+  assert.ok(inicio >= 0, 'a SetaDoBloco');
+  const seta = t.slice(inicio, t.indexOf('\n}\n', inicio));
+  assert.match(seta, /Image\(systemName: "chevron\.right"\)\n\s*\.font\(\.body\.weight\(\.semibold\)\)\n\s*\.dynamicTypeSize\(\.\.\.DynamicTypeSize\.accessibility2\)\n\s*\.frame\(width: letra\.isAccessibilitySize \? 20 : 14\)\n/,
+    'a seta para no AX2 e ocupa 20 pt na letra de acessibilidade e 14 na padrão');
+  assert.match(seta, /\.accessibilityHidden\(true\)\n\s*\.foraDoLaudo\(\)/, 'fora do VoiceOver e do laudo');
+  const orcamento = ler('app-ios/Custta/Telas/PecasDoOrcamento.swift');
+  const linha = orcamento.slice(orcamento.indexOf('struct LinhaDoOrcamento'));
+  assert.match(linha.slice(0, linha.indexOf('\n}\n')), /if comSeta \{ SetaDoBloco\(\) \}/, 'o bloco do Orçamento usa a seta');
+  const aPagar = t.slice(t.indexOf('private func aPagar('));
+  assert.match(aPagar.slice(0, aPagar.indexOf('\n    }\n')), /SetaDoBloco\(\)/, 'o bloco do A pagar usa a seta');
 });
 
 test('linha dos afazeres: a seta é a das linhas do Orçamento e do A pagar, para no AX2 e ocupa 18 pt na maior letra', () => {
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E '^/.*error: ' | sed 's/^.*CusttaTests\//CusttaTests\//' | sort -t: -k2,2n -u | head -3
```
Expected: o `CusttaTests` não compila:
```
CusttaTests/BlocosDaObraTests.swift:24:17: error: cannot find 'solidoDaObra' in scope
CusttaTests/BlocosDaObraTests.swift:25:17: error: cannot find 'solidoDaObra' in scope
CusttaTests/BlocosDaObraTests.swift:27:17: error: cannot find 'solidoDaObra' in scope
```

- [ ] **Step 3: Implementar**

Os blocos moram num arquivo novo, `Telas/BlocosDaObra.swift`, e entram na obra num `VStack` só, filho da `LazyVStack` da tela (o alto é sempre criado). A ordem dos blocos na vendida com lucro segue o `indicadores()` do mockup: o lucro, o Orçamento, o Total gasto no vidro, o Corrigido, o A pagar e a Venda. O método que monta um bloco de vidro não pode se chamar `vidro`: a tela já lê o `@Environment(\.vidro)`. Sai da `PecasDaObra.swift` a obra da etapa 3 que nenhuma outra tela usa (a `PilulaDaFase` e o `IndicadoresDaObraView`); o `TituloDaObra` e a `EtiquetaDoIndicador` ficam, porque a tela Orçamento e as folhas os usam.

Em `app-ios/Custta/Identidade/Blocos.swift`:

```diff
--- a/app-ios/Custta/Identidade/Blocos.swift
+++ b/app-ios/Custta/Identidade/Blocos.swift
@@ -112,6 +112,9 @@ struct RotuloDoBloco: View {
         Text(texto)
             .font(.subheadline.weight(tinta == nil ? .semibold : .bold))
             .foregroundStyle(paleta.cor(tinta ?? vidro.secundario))
+            // Na letra grande, num bloco com a seta ao lado, o rótulo recebia menos altura que as linhas dele e cortava
+            // ("A pagar · 30 dias" na AX5): a altura ideal para a largura dada resolve.
+            .fixedSize(horizontal: false, vertical: true)
     }
 }
 
@@ -119,6 +122,8 @@ struct RotuloDoBloco: View {
 /// tinta do sólido.
 struct NotaDoBloco: View {
     let texto: String
+    /// Outra cor no vidro (o lucro da venda no verde ou no âmbar); no sólido vale a tinta dele.
+    var cor: Token? = nil
     @Environment(\.paleta) private var paleta
     @Environment(\.vidro) private var vidro
     @Environment(\.tintaDoBloco) private var tinta
@@ -126,7 +131,8 @@ struct NotaDoBloco: View {
     var body: some View {
         Text(texto)
             .font(.subheadline)
-            .foregroundStyle(paleta.cor(tinta ?? vidro.secundario))
+            .foregroundStyle(paleta.cor(tinta ?? cor ?? vidro.secundario))
+            .fixedSize(horizontal: false, vertical: true)
             .padding(.top, 2)
     }
 }
```

Criar `app-ios/Custta/Telas/BlocosDaObra.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* O alto da obra na identidade nova (etapa 4, PR 1c; mockup aprovado, parte1.js:254-287 e parte1-obra-topo.png): o bloco
   sólido protagonista e um bloco de vidro por assunto, na ordem da etapa 3 (Orçamento, Corrigido pelo banco, A pagar ·
   30 dias, Venda). Na vendida com lucro (decisão 4: A), o sólido é o lucro e o Total gasto desce para um bloco de vidro
   logo depois do Orçamento; com prejuízo (B), o sólido volta a ser o Total gasto e o lucro fica no bloco da venda, em
   âmbar, nunca vermelho. Os textos e as contas são os do site (indicadoresDaObra, orcamentoObra, lucroVenda). Cada bloco é
   um elemento só para o VoiceOver: o número solto reprova a descrição suficiente da auditoria. */

/// O que o sólido da obra mostra: o Total gasto ou, na vendida com lucro, o lucro da venda.
enum SolidoDaObra: Equatable {
    case total
    /// "+R$ 537.682,55", "Vendida em 20/06/26" e "+R$ 482.871,47 acima do banco" (o acima do banco negativo leva o "−").
    case lucro(valor: String, etiqueta: String, nota: String)
}

/// A vendida com lucro bruto (zero conta como lucro, como o `>= 0` do mockup) põe o lucro no sólido; o resto, o Total gasto.
func solidoDaObra(_ obra: Obra, taxa: Double) -> SolidoDaObra {
    guard obra.fase == .vendida, let venda = obra.venda, let lucro = lucroVenda(obra, taxa: taxa), lucro.bruto >= 0 else {
        return .total
    }
    return .lucro(valor: comSinal(lucro.bruto), etiqueta: "Vendida em \(dataCurta(venda.data))",
                  nota: "\(comSinal(lucro.vsBanco)) acima do banco")
}

/// A nota do Total gasto: sem gastos, o convite para lançar o primeiro pelo +; na vendida, não (o + de lá não lança nela:
/// abre a folha com a linha "Obra", para escolher outra), e fica o "bruto, sem correção".
func notaDoTotal(_ obra: Obra) -> String {
    obra.gastos.isEmpty && obra.fase != .vendida ? "Toque no + para lançar o primeiro gasto." : "bruto, sem correção"
}

/// O valor com o sinal na frente: "+R$ …" ou "−R$ …" (o menos tipográfico, o do gasto).
func comSinal(_ valor: Double) -> String {
    valor < 0 ? "\u{2212}" + moeda(-valor) : "+" + moeda(valor)
}

/// O sólido e os blocos de vidro do alto da obra, 12 pt um do outro.
struct BlocosDaObra: View {
    let obra: Obra
    let taxa: Double
    let hoje: String
    /// O bloco "A pagar · 30 dias": a folha dele.
    let abrirAPagar: () -> Void
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        let indicadores = indicadoresDaObra(obra, taxa: taxa, hoje: hoje)
        let solido = solidoDaObra(obra, taxa: taxa)
        VStack(spacing: Grade.entreBlocos) {
            switch solido {
            case .total: total(indicadores, solido: true)
            case let .lucro(valor, etiqueta, nota): lucro(valor: valor, etiqueta: etiqueta, nota: nota)
            }
            if let orcamento = orcamentoObra(obra) {
                NavigationLink(value: RotaDeObras.orcamento(obra.id)) { LinhaDoOrcamento(resumo: orcamento, comSeta: true) }
                    .buttonStyle(.plain)
                    // O Controle por Voz chama pelo nome do bloco ("Tocar Orçamento"), não pelo rótulo inteiro.
                    .accessibilityInputLabels(["Orçamento"])
            }
            if solido != .total { total(indicadores, solido: false) }
            blocoDeVidro(rotulo: "Corrigido pelo banco", etiqueta: nil, valor: indicadores.corrigido, nota: indicadores.notaDoCorrigido)
                .accessibilityIdentifier("indicadorCorrigido")
            aPagar(indicadores)
            venda(indicadores.venda)
        }
    }

    /// O Total gasto: no sólido, ou no vidro logo depois do Orçamento quando o sólido é o lucro. Sem gastos, o R$ 0,00 com o
    /// convite para lançar o primeiro.
    private func total(_ indicadores: IndicadoresDaObra, solido: Bool) -> some View {
        let nota = notaDoTotal(obra)
        return Group {
            if solido {
                BlocoSolido {
                    CabecalhoDoBloco(rotulo: "Total gasto") { EtiquetaDoSolido(texto: indicadores.etiquetaDoTotal) }
                    ValorEmDinheiro(indicadores.totalGasto, mono: .principal)
                    NotaDoBloco(texto: nota)
                }
            } else {
                BlocoDeVidro {
                    CabecalhoDoBloco(rotulo: "Total gasto") {
                        EtiquetaDoIndicador(texto: indicadores.etiquetaDoTotal, cor: obra.gastos.isEmpty ? .neutro : .marca)
                    }
                    ValorEmDinheiro(indicadores.totalGasto, mono: .principal)
                    NotaDoBloco(texto: nota)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("indicadorTotal")
    }

    private func lucro(valor: String, etiqueta: String, nota: String) -> some View {
        BlocoSolido {
            CabecalhoDoBloco(rotulo: "Lucro da venda") { EtiquetaDoSolido(texto: etiqueta) }
            ValorEmDinheiro(valor, mono: .principal)
            NotaDoBloco(texto: nota)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("indicadorLucro")
    }

    /// Um bloco de vidro com o rótulo, a etiqueta, o número e a nota, num elemento só.
    private func blocoDeVidro(rotulo: String, etiqueta: (String, EtiquetaDoIndicador.Cor)?, valor: String, nota: String,
                       corDaNota: Token? = nil) -> some View {
        BlocoDeVidro { miolo(rotulo: rotulo, etiqueta: etiqueta, valor: valor, nota: nota, corDaNota: corDaNota) }
            .accessibilityElement(children: .combine)
    }

    private func miolo(rotulo: String, etiqueta: (String, EtiquetaDoIndicador.Cor)?, valor: String, nota: String,
                       corDaNota: Token? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CabecalhoDoBloco(rotulo: rotulo) {
                if let etiqueta { EtiquetaDoIndicador(texto: etiqueta.0, cor: etiqueta.1) }
            }
            // O "—" de valor nenhum (venda sem estimativa) vai no secundário, como no mockup.
            ValorEmDinheiro(valor, mono: .bloco, cor: valor == "—" ? vidro.secundario : .texto)
            NotaDoBloco(texto: nota, cor: corDaNota)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// "A pagar · 30 dias": o bloco inteiro é o botão da folha dele, com a seta das linhas tocáveis no meio da altura.
    private func aPagar(_ indicadores: IndicadoresDaObra) -> some View {
        Button(action: abrirAPagar) {
            HStack(spacing: 10) {
                miolo(rotulo: "A pagar · 30 dias", etiqueta: (indicadores.etiquetaDoAPagar, .alerta), valor: indicadores.aPagar,
                      nota: "Parcelas e gastos futuros")
                SetaDoBloco()
            }
            .padding(.vertical, Grade.recuoVertical(letra))
            .padding(.horizontal, Grade.recuo)
            .contentShape(.rect)
            .superficie(.conteudo, em: .rect(cornerRadius: Grade.raioDoBloco(letra)))
        }
        .buttonStyle(.plain)
        // O Controle por Voz chama pelo nome do bloco ("Tocar A pagar"), não pelo rótulo inteiro.
        .accessibilityInputLabels(["A pagar"])
        .accessibilityIdentifier("indicadorAPagar")
    }

    @ViewBuilder private func venda(_ venda: VendaNaTela) -> some View {
        switch venda {
        case .vendida(let valor, let etiqueta, let nota, let lucroPositivo):
            blocoDeVidro(rotulo: "Venda", etiqueta: (etiqueta, .positivo), valor: valor, nota: nota,
                       corDaNota: lucroPositivo ? .positivoNoVidro : .alertaNoVidro)
                .accessibilityIdentifier("indicadorVenda")
        case .estimada(let valor, let nota):
            blocoDeVidro(rotulo: "Venda estimada", etiqueta: ("estimativa", .positivo), valor: valor, nota: nota)
                .accessibilityIdentifier("indicadorVenda")
        case .semEstimativa:
            blocoDeVidro(rotulo: "Venda estimada", etiqueta: nil, valor: "—", nota: "Toque no lápis para informar o valor")
                .accessibilityIdentifier("indicadorVenda")
        }
    }
}

/// A seta dos blocos tocáveis (Orçamento, A pagar, Afazeres): 14 pt de largura, no secundário do vidro (o .chev do
/// mockup); para no AX2 e ocupa 20 pt na letra de acessibilidade. Figura, fora do VoiceOver e do laudo.
struct SetaDoBloco: View {
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.body.weight(.semibold))
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .frame(width: letra.isAccessibilitySize ? 20 : 14)
            .foregroundStyle(paleta.cor(vidro.secundario))
            .accessibilityHidden(true)
            .foraDoLaudo()
    }
}
```

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -1,11 +1,12 @@
 import SwiftUI
 import CusttaNucleo
 
-/* A tela da obra (mockup aprovado da etapa 2, partes 1 e 3): o nome no título grande, a pílula da fase e do tempo, os
-   indicadores na opção A, as ações da fase, a pílula "Lançamentos" e a lista de gastos por mês, com o "A vencer" fechado
-   no alto; o lápis na barra abre "Editar obra". Entra pelo push do NavigationStack de Obras e volta pelo círculo e pela
-   borda (sistema). A obra que some (apagada em outro aparelho) fecha a tela, como o site volta ao Início. Na etapa 3, a
-   busca e o mês ao lado da pílula filtram só a lista (BuscaDaObra.swift); indicadores e orçamento ficam com a obra inteira. */
+/* A tela da obra, em blocos na identidade nova (etapa 4, PR 1c; mockup aprovado, parte1.html): o nome no título mono, a
+   cápsula da fase e do tempo, o sólido e os blocos de vidro (BlocosDaObra.swift), as ações da fase, os afazeres, a pílula
+   "Lançamentos" e a lista de gastos por mês, com o "A vencer" fechado no alto; o lápis na barra abre "Editar obra". Entra
+   pelo push do NavigationStack de Obras e volta pelo círculo e pela borda (sistema). A obra que some (apagada em outro
+   aparelho) fecha a tela, como o site volta ao Início. Na etapa 3, a busca e o mês ao lado da pílula filtram só a lista
+   (BuscaDaObra.swift); os blocos e o orçamento ficam com a obra inteira. */
 struct ObraView: View {
     let id: String
     @Binding var caminho: [RotaDeObras]
@@ -71,11 +72,18 @@ struct ObraView: View {
                                  })
         return ScrollViewReader { leitor in
             ScrollView {
-                LazyVStack(alignment: .leading, spacing: 10) {
-                    TituloDaObra(nome: obra.nome)
-                    PilulaDaFase(obra: obra, hoje: hoje)
-                    IndicadoresDaObraView(indicadores: indicadoresDaObra(obra, taxa: taxa, hoje: hoje), orcamento: orcamentoObra(obra),
-                                          rotaDoOrcamento: .orcamento(obra.id)) {
+                LazyVStack(alignment: .leading, spacing: Grade.entreBlocos) {
+                    // O título solto e a cápsula com a fase e o tempo: 8 pt entre eles e 16 até o sólido (mockup, .ob-meta-w).
+                    TituloMono(texto: obra.nome)
+                        .padding(EdgeInsets(top: -6, leading: 0, bottom: -4, trailing: 0))
+                    CapsulaDeMetadados {
+                        EtiquetaDeFase(fase: obra.fase, grande: true)
+                        Text(textoDoInicio(obra, hoje: hoje))
+                    }
+                    .accessibilityElement(children: .combine)
+                    .accessibilityIdentifier("faseDaObra")
+                    .padding(.bottom, 4)
+                    BlocosDaObra(obra: obra, taxa: taxa, hoje: hoje) {
                         // Com uma linha arrastada aberta, o toque só a fecha, como o das linhas.
                         if linhaAberta != nil { fecharLinha(); return }
                         folhas.aberta = .aPagar(obraId: obra.id)
@@ -84,8 +92,6 @@ struct ObraView: View {
                                     definirOrcamento: pecasOrcamento(obra).definir ? { folhas.aberta = .orcamento(obraId: obra.id) } : nil) {
                         agir($0, obra: obra)
                     }
-                        .padding(.top, 2)
-                        .padding(.bottom, 2)
                     // Os afazeres, 12 abaixo das ações e 24 acima dos lançamentos (mockup da etapa 3), em todas as fases.
                     NavigationLink(value: RotaDeObras.afazeres(obra.id)) {
                         LinhaDosAfazeresView(linha: linhaDosAfazeres(obra.afazeres))
@@ -123,7 +129,7 @@ struct ObraView: View {
                         }
                     }
                 }
-                .padding(.horizontal, 20)
+                .padding(.horizontal, Grade.externa)
                 // O fim da lista fica à vista acima da cápsula de abas, como no mockup: 132 pt da borda de baixo (a cápsula, de
                 // 62 a 22 da borda, e 48 de folga), menos os 34 do indicador de início, que a rolagem já desconta.
                 .padding(.bottom, 98)
@@ -158,6 +164,7 @@ struct ObraView: View {
         }
         .pausaOFundo(enquanto: desfazendo)
         .tituloPequenoAoRolar(barra)
+        .background { LeitorDaLetra(barra: barra) }
         #if DEBUG
         .task { if !linhaDeTeste.isEmpty { linhaAberta = linhaDeTeste } }
         .rolagemFixaSemFolha()
@@ -168,7 +175,7 @@ struct ObraView: View {
         .navigationTitle(obra.nome)
         .navigationBarTitleDisplayMode(.inline)
         .toolbar {
-            ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: obra.nome) }
+            ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: obra.nome, mono: true) }
             ToolbarItem(placement: .topBarTrailing) { IndicadorDeSincronizacao() }
                 .sharedBackgroundVisibility(.hidden)
             ToolbarItem(placement: .topBarTrailing) { BotaoDeEditarObra { folhas.aberta = .editarObra(obraId: obra.id) } }
@@ -340,6 +347,23 @@ struct LinhaDaLista: View {
 @MainActor @Observable
 final class BarraDaObra {
     var tituloVisivel = false
+    /// A letra da tela, para o título pequeno mono: dentro do ToolbarItem, o dynamicTypeSize para antes da letra de
+    /// acessibilidade. Mora aqui, e não num @Environment da ObraView: só o título pequeno se refaz quando a letra muda (a
+    /// obra inteira refeita pesava a troca por trás da folha; o toque duplo é segurado pela marca `gravado` do rascunho
+    /// do gasto, na FolhaDoGasto).
+    var letra: DynamicTypeSize = .large
+}
+
+/// Lê a letra da tela fora da barra e a guarda na BarraDaObra: só o título pequeno se refaz quando ela muda.
+private struct LeitorDaLetra: View {
+    let barra: BarraDaObra
+    @Environment(\.dynamicTypeSize) private var letra
+
+    var body: some View {
+        Color.clear
+            .accessibilityHidden(true)
+            .onChange(of: letra, initial: true) { _, nova in if barra.letra != nova { barra.letra = nova } }
+    }
 }
 
 extension View {
@@ -358,11 +382,17 @@ extension View {
 struct TituloDaBarraDaObra: View {
     let barra: BarraDaObra
     let nome: String
+    /// O título pequeno em SF Mono da identidade nova (a obra, desde a etapa 4), na letra da tela, lida fora da barra
+    /// (`barra.letra`); a tela Orçamento fica com o de antes.
+    var mono = false
     @Environment(ModeloApp.self) private var modelo
 
     var body: some View {
         if barra.tituloVisivel && indicador(modelo.sincronizador.estadoSinc) == nil {
-            TituloPequenoDaBarra(nome: nome).transition(.opacity)
+            Group {
+                if mono { TituloPequenoMono(texto: nome, letra: barra.letra) } else { TituloPequenoDaBarra(nome: nome) }
+            }
+            .transition(.opacity)
         } else {
             Color.clear.frame(width: 1, height: 1).accessibilityHidden(true)
         }
```

Em `app-ios/Custta/Telas/PecasDaObra.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDaObra.swift
+++ b/app-ios/Custta/Telas/PecasDaObra.swift
@@ -1,10 +1,10 @@
 import SwiftUI
 import CusttaNucleo
 
-/* As peças da tela da obra (mockup aprovado da etapa 2, parte 1): o título com o nome, a pílula da fase e do tempo,
-   os indicadores na opção A, a pílula "Lançamentos", o "A vencer", o cabeçalho do mês e a linha do gasto. Medidas do
-   mockup: margem de 20, cartões de raio 24 e recuo interno de 18 em tudo, para o texto de cima e o de baixo começarem
-   na mesma vertical. Nenhum token novo; nunca vidro dentro de vidro (o que fica dentro de um cartão é sólido). */
+/* As peças da tela da obra (mockup aprovado da etapa 2, parte 1): o título com o nome (hoje, o da tela Orçamento; a obra
+   usa o título mono da etapa 4), a etiqueta dos blocos, a pílula "Lançamentos", o "A vencer", o cabeçalho do mês e a
+   linha do gasto. Medidas do mockup: cartões de raio 24 e recuo interno de 18 em tudo, para o texto de cima e o de baixo
+   começarem na mesma vertical. Nunca vidro dentro de vidro (o que fica dentro de um cartão é sólido). */
 
 /// O nome da obra no título grande, em quantas linhas precisar (o título grande do sistema corta nome longo), com o
 /// halo atrás do bloco inteiro no escuro, como o título grande de Obras. Nas alturas do mockup: 6 pt acima do início da
@@ -26,30 +26,6 @@ struct TituloDaObra: View {
     }
 }
 
-/// Fase e tempo numa pílula de vidro: um cartão baixo de raio 24 com a etiqueta da fase e "começou em… · N meses", a 16 pt
-/// do total gasto, como no mockup (6 além do espaço da pilha).
-struct PilulaDaFase: View {
-    let obra: Obra
-    let hoje: String
-    @Environment(\.paleta) private var paleta
-
-    var body: some View {
-        VStack(alignment: .leading, spacing: 8) {
-            EtiquetaDeFase(fase: obra.fase, grande: true)
-            Text(textoDoInicio(obra, hoje: hoje))
-                .font(.subheadline)
-                .foregroundStyle(paleta.cor(.texto))
-        }
-        .padding(.horizontal, 18)
-        .padding(.vertical, 14)
-        .frame(maxWidth: .infinity, alignment: .leading)
-        .superficie(.conteudo, em: .rect(cornerRadius: 24))
-        .accessibilityElement(children: .combine)
-        .accessibilityIdentifier("faseDaObra")
-        .padding(.bottom, 6)
-    }
-}
-
 /// Uma etiqueta pequena colorida ao lado do rótulo de um indicador ("46 lançamentos", "3 vencimentos", "estimativa"), nas
 /// medidas do mockup: footnote semibold, recuo de 10 nos lados e 3 em cima e embaixo.
 struct EtiquetaDoIndicador: View {
@@ -80,149 +56,6 @@ struct EtiquetaDoIndicador: View {
     }
 }
 
-/// Os indicadores na opção A do mockup: o total gasto em destaque e um cartão com o orçamento (etapa 3, a primeira linha,
-/// só com orçamento), Corrigido, A pagar (a linha inteira abre a folha dele, etapa 3) e Venda. Os textos e as contas são
-/// os do site (indicadoresDaObra, orcamentoObra).
-struct IndicadoresDaObraView: View {
-    let indicadores: IndicadoresDaObra
-    var orcamento: ResumoOrcamento? = nil
-    /// Para onde a linha do orçamento leva (a tela Orçamento da obra).
-    var rotaDoOrcamento: RotaDeObras? = nil
-    /// A seta do "A pagar · 30 dias": a folha dele.
-    let abrirAPagar: () -> Void
-    @Environment(\.paleta) private var paleta
-    @Environment(\.vidro) private var vidro
-    @Environment(\.dynamicTypeSize) private var tamanho
-
-    /// "N lançamentos" na marca; "sem gastos" neutra, como o chip cinza do mockup.
-    private var corDoTotal: EtiquetaDoIndicador.Cor { indicadores.etiquetaDoTotal == "sem gastos" ? .neutro : .marca }
-
-    var body: some View {
-        VStack(spacing: 10) {
-            heroi
-            VStack(spacing: 0) {
-                if let orcamento {
-                    if let rotaDoOrcamento {
-                        NavigationLink(value: rotaDoOrcamento) { LinhaDoOrcamento(resumo: orcamento, comSeta: true) }
-                            .buttonStyle(.plain)
-                            // O Controle por Voz chama pelo nome da linha ("Tocar Orçamento"), não pelo rótulo inteiro.
-                            .accessibilityInputLabels(["Orçamento"])
-                    } else {
-                        LinhaDoOrcamento(resumo: orcamento)
-                    }
-                    LinhaFina().padding(.leading, 18)
-                }
-                linha(rotulo: "Corrigido pelo banco", etiqueta: nil, valor: indicadores.corrigido, nota: indicadores.notaDoCorrigido,
-                      identificador: "indicadorCorrigido")
-                LinhaFina().padding(.leading, 18)
-                aPagar
-                LinhaFina().padding(.leading, 18)
-                venda
-            }
-            .superficie(.conteudo, em: .rect(cornerRadius: 24))
-        }
-    }
-
-    /// O "A pagar · 30 dias": a linha inteira é o botão da folha dele, com a seta das linhas tocáveis no meio da altura
-    /// (o .k-chev do mockup), a mesma do "A vencer". Embaixo, "Parcelas e gastos futuros", como antes.
-    private var aPagar: some View {
-        Button(action: abrirAPagar) {
-            HStack(spacing: 4) {
-                miolo(rotulo: "A pagar · 30 dias", etiqueta: (indicadores.etiquetaDoAPagar, .alerta), valor: indicadores.aPagar,
-                      nota: "Parcelas e gastos futuros", corDaNota: nil)
-                Image(systemName: "chevron.right")
-                    .font(.body.weight(.semibold))
-                    // O mesmo chevron da linha do Orçamento, no mesmo cartão.
-                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
-                    .frame(width: tamanho.isAccessibilitySize ? 18 : 9)
-                    .foregroundStyle(paleta.cor(vidro.secundario))
-                    .accessibilityHidden(true)
-                    .foraDoLaudo()
-            }
-            .padding(EdgeInsets(top: 13, leading: 18, bottom: 13, trailing: 16))
-            .contentShape(.rect)
-        }
-        .buttonStyle(.plain)
-        // O Controle por Voz chama pelo nome da linha ("Tocar A pagar"), não pelo rótulo inteiro.
-        .accessibilityInputLabels(["A pagar"])
-        .accessibilityIdentifier("indicadorAPagar")
-    }
-
-    private var heroi: some View {
-        VStack(alignment: .leading, spacing: 6) {
-            ViewThatFits(in: .horizontal) {
-                HStack(alignment: .firstTextBaseline) {
-                    rotulo("Total gasto")
-                    Spacer(minLength: 8)
-                    EtiquetaDoIndicador(texto: indicadores.etiquetaDoTotal, cor: corDoTotal)
-                }
-                VStack(alignment: .leading, spacing: 6) {
-                    rotulo("Total gasto")
-                    EtiquetaDoIndicador(texto: indicadores.etiquetaDoTotal, cor: corDoTotal)
-                }
-            }
-            ValorEmDinheiro(texto: indicadores.totalGasto, fonte: .largeTitle.weight(.bold))
-            Text("bruto, sem correção").font(.subheadline).foregroundStyle(paleta.cor(vidro.secundario))
-        }
-        .padding(.horizontal, 18)
-        .padding(.vertical, 16)
-        .frame(maxWidth: .infinity, alignment: .leading)
-        .superficie(.conteudo, em: .rect(cornerRadius: 24))
-        .accessibilityElement(children: .combine)
-        .accessibilityIdentifier("indicadorTotal")
-    }
-
-    @ViewBuilder private var venda: some View {
-        switch indicadores.venda {
-        case .vendida(let valor, let etiqueta, let nota, let lucroPositivo):
-            linha(rotulo: "Venda", etiqueta: (etiqueta, .positivo), valor: valor, nota: nota, identificador: "indicadorVenda",
-                  corDaNota: lucroPositivo ? .positivoNoVidro : .negativoNoVidro)
-        case .estimada(let valor, let nota):
-            linha(rotulo: "Venda estimada", etiqueta: ("estimativa", .positivo), valor: valor, nota: nota, identificador: "indicadorVenda")
-        case .semEstimativa:
-            linha(rotulo: "Venda estimada", etiqueta: nil, valor: "—", nota: "Toque no lápis para informar o valor",
-                  identificador: "indicadorVenda")
-        }
-    }
-
-    /// Na letra grande, o rótulo ao lado da etiqueta recebia a altura de uma linha e cortava ("A pagar · 3…"): a altura
-    /// ideal para a largura dada resolve.
-    private func rotulo(_ texto: String) -> some View {
-        Text(texto).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto)).fixedSize(horizontal: false, vertical: true)
-    }
-
-    private func linha(rotulo texto: String, etiqueta: (String, EtiquetaDoIndicador.Cor)?, valor: String, nota: String,
-                       identificador: String, corDaNota: Token? = nil) -> some View {
-        miolo(rotulo: texto, etiqueta: etiqueta, valor: valor, nota: nota, corDaNota: corDaNota)
-            .padding(EdgeInsets(top: 13, leading: 18, bottom: 13, trailing: 16))
-            .accessibilityElement(children: .combine)
-            .accessibilityIdentifier(identificador)
-    }
-
-    /// O rótulo com a etiqueta, o valor e a nota de uma linha do cartão.
-    private func miolo(rotulo texto: String, etiqueta: (String, EtiquetaDoIndicador.Cor)?, valor: String, nota: String,
-                       corDaNota: Token?) -> some View {
-        VStack(alignment: .leading, spacing: 4) {
-            ViewThatFits(in: .horizontal) {
-                HStack(alignment: .firstTextBaseline) {
-                    rotulo(texto)
-                    Spacer(minLength: 8)
-                    if let etiqueta { EtiquetaDoIndicador(texto: etiqueta.0, cor: etiqueta.1) }
-                }
-                VStack(alignment: .leading, spacing: 6) {
-                    rotulo(texto)
-                    if let etiqueta { EtiquetaDoIndicador(texto: etiqueta.0, cor: etiqueta.1) }
-                }
-            }
-            // O "—" de valor nenhum (venda sem estimativa) vai no secundário, como no mockup.
-            ValorEmDinheiro(texto: valor, fonte: .title2.weight(.bold), cor: valor == "—" ? vidro.secundario : .texto)
-            Text(nota).font(.subheadline).foregroundStyle(paleta.cor(corDaNota ?? vidro.secundario))
-                .fixedSize(horizontal: false, vertical: true)
-        }
-        .frame(maxWidth: .infinity, alignment: .leading)
-    }
-}
-
 /// A pílula de vidro antes de uma lista: "Lançamentos 46" na obra (`BuscaDaObra`), "Pendentes 3" nos afazeres
 /// (`AfazeresView`) e, na tela Orçamento, "Por tópico 14" e "Gasto por tópico 14" (`OrcamentoView`). O título em subheadline
 /// semibold e o número em peso médio, no secundário (sem número, só o título), num texto só: na maior letra a pílula quebra
```

Em `app-ios/Custta/Telas/PecasDoOrcamento.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDoOrcamento.swift
+++ b/app-ios/Custta/Telas/PecasDoOrcamento.swift
@@ -150,9 +150,9 @@ struct AvisoDoOrcamento: View {
     }
 }
 
-/// A linha do orçamento nos indicadores: "Orçamento" e o nível do site, quanto sobra (ou passou), a barra, "{pct}% usado de
-/// {previsto}" e, por tópico, o pior aviso dos tópicos e o que está fora; com a seta, ela abre a tela Orçamento (a linha
-/// inteira é o botão). Um elemento só para o VoiceOver, como as outras linhas dos indicadores.
+/// O bloco do orçamento na obra (identidade nova, etapa 4; mockup, parte1.js:254-265): "Orçamento" e o nível do site,
+/// quanto sobra (ou passou) no número mono, a barra, "{pct}% usado de {previsto}" e, por tópico, o pior aviso dos tópicos e
+/// o que está fora; com a seta, ele abre a tela Orçamento (o bloco inteiro é o botão). Um elemento só para o VoiceOver.
 struct LinhaDoOrcamento: View {
     let resumo: ResumoOrcamento
     var comSeta = false
@@ -163,41 +163,28 @@ struct LinhaDoOrcamento: View {
     var body: some View {
         let geral = resumo.geral
         let rodape = rodapeOrc(geral)
-        HStack(spacing: 4) {
+        HStack(spacing: 10) {
             conteudo(geral, rodape)
-            if comSeta {
-                Image(systemName: "chevron.right")
-                    .font(.body.weight(.semibold))
-                    // Na maior letra o chevron para no AX2 e ocupa só os 18 pt dele (18 × 30 do mockup): a coluna de texto fica com os
-                    // 306 pt e "80% usado de" cabe numa linha (o símbolo sozinho reserva ~6 pt além do traço). Na letra padrão, os 9 pt
-                    // do mockup (9 × 15): a barra fica com os 315 dele.
-                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
-                    .frame(width: tamanho.isAccessibilitySize ? 18 : 9)
-                    .foregroundStyle(paleta.cor(vidro.secundario))
-                    .accessibilityHidden(true)
-                    .foraDoLaudo()
-            }
+            if comSeta { SetaDoBloco() }
         }
-        .padding(EdgeInsets(top: 13, leading: 18, bottom: 13, trailing: 16))
+        .padding(.vertical, Grade.recuoVertical(tamanho))
+        .padding(.horizontal, Grade.recuo)
         .contentShape(.rect)
+        .superficie(.conteudo, em: .rect(cornerRadius: Grade.raioDoBloco(tamanho)))
         .accessibilityElement(children: .combine)
         .accessibilityIdentifier("indicadorOrcamento")
     }
 
     private func conteudo(_ geral: ItemOrcamento, _ rodape: RodapeDoOrcamento) -> some View {
         VStack(alignment: .leading, spacing: 0) {
-            ViewThatFits(in: .horizontal) {
-                HStack(alignment: .firstTextBaseline) { rotulo; Spacer(minLength: 8); etiqueta(geral.nivel) }
-                VStack(alignment: .leading, spacing: 6) { rotulo; etiqueta(geral.nivel) }
-            }
+            CabecalhoDoBloco(rotulo: "Orçamento") { etiqueta(geral.nivel) }
             // "sobra R$ …" numa linha; na letra grande, um em cima do outro (mockup).
             let layout = tamanho.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
-                                                     : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 7))
+                                                     : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 6))
             layout {
-                Text(rodape.rotulo).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(vidro.secundario))
-                ValorEmDinheiro(texto: rodape.valor, fonte: .title2.weight(.bold))
+                Text(rodape.rotulo).font(.subheadline.weight(.medium)).foregroundStyle(paleta.cor(vidro.secundario))
+                ValorEmDinheiro(rodape.valor, mono: .bloco)
             }
-            .padding(.top, 2)
             BarraDoOrcamento(item: geral)
                 .padding(.top, 9)
                 .padding(.bottom, 7)
@@ -211,11 +198,6 @@ struct LinhaDoOrcamento: View {
         .frame(maxWidth: .infinity, alignment: .leading)
     }
 
-    private var rotulo: some View {
-        Text("Orçamento").font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
-            .fixedSize(horizontal: false, vertical: true)
-    }
-
     private func etiqueta(_ nivel: NivelOrcamento) -> some View {
         EtiquetaDoIndicador(texto: nivel.pilula, cor: corDoNivel(nivel))
     }
```

- [ ] **Step 4: Ver passar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/BlocosDaObraTests -only-testing:CusttaTests/LinhaDoOrcamentoTests -only-testing:CusttaTests/OrcamentoEm375Tests 2>&1 | grep -E "Test run with"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/ObraUITests -only-testing:CusttaUITests/OrcamentoUITests/testALinhaVemLogoAbaixoDoTotalGasto 2>&1 | grep -E "error:|Executed [0-9]+ test" | tail -1
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/AuditoriaUITests/testObraNoMaiorTamanho -only-testing:CusttaUITests/AuditoriaUITests/testParte3NoMaiorTamanho 2>&1 | grep -E "error:|Executed [0-9]+ test" | tail -1
npm run test:unit 2>&1 | grep -E "ℹ (pass|fail)"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/EstadosUITests/testToqueDuploNoSalvarDaVendidaLancaUmGasto -test-iterations 7 2>&1 | grep -E "error:|Executed [0-9]+ test" | tail -1
```
Expected: `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 9 tests in 3 suites passed`; `Executed 11 tests, with 0 failures (0 unexpected)`; `Executed 2 tests, with 0 failures (0 unexpected)` (no 18 Pro, 137 s); `ℹ pass 411`, `ℹ fail 0` (como antes: as duas guardas dos chevrons viraram uma, e entra a do âmbar). Com o `CabecalhoDoBloco` de antes do conserto da Tarefa 19 (o `Spacer` ao lado do rótulo), a varredura reprova só com o Negrito: `✘ Test run with 4 tests in 1 suite failed after 1.175 seconds with 2 issues.`, com "obra 0, .medium, negrito true, em 408.0: 408.3333333333333" (a vitrine) e "obra 2, .large, negrito true, em 408.0: 408.3333333333333" (a vendida com prejuízo). Sem o `obra.fase != .vendida` da `notaDoTotal`, o teste da nota reprova: `✘ Test run with 5 tests in 1 suite failed after 1.005 seconds with 1 issue.`, com `Expectation failed: notaDoTotal(vendida) == "bruto, sem correção"` e `notaDoTotal(vendida) → "Toque no + para lançar o primeiro gasto."`. Trocar o `.alertaNoVidro` da nota da venda por `.negativoNoVidro` derruba a guarda nova: `ℹ fail 1`, "AssertionError [ERR_ASSERTION]: a nota do lucro no verde e a do prejuízo no âmbar". Sem o `fixedSize` do `RotuloDoBloco`, a auditoria da obra na maior letra reprova no 18 Pro com "Text clipped" em "A pagar · 30 dias" (no Pro Max, mais largo, ela passa com e sem ele). No toque duplo, `Executed 7 tests, with 0 failures (0 unexpected)`. Sem a Tarefa 29 (a marca `gravado` no rascunho do gasto), esse teste reprova com a obra em blocos em 6 ou 7 de 7 rodadas (`Executed 7 tests, with 6 failures`, "Total gasto, 48 lançamentos" em vez de 47): a obra, mais pesada de montar por trás da folha, abre a janela do fechamento no turno seguinte.

- [ ] **Step 5: Conferir com o mockup**

Run: abrir a obra da vitrine no 18 Pro, com a barra de status em 9:41 e o fundo parado (`CUSTTA_SERVICOS=falsos CUSTTA_CONTA=senha CUSTTA_DADOS=vitrine CUSTTA_ABRIR=obra:v1` e `-custta.reduzirMovimento YES`, pelo `simctl launch`), e tirar o print.
Expected: o alto como o `parte1-obra-topo.png`: "Casa Alphaville" no título mono a 16 pt da borda; a cápsula com "Em construção" e "começou em … · 14 meses"; o sólido verde com "Total gasto", "46 lançamentos", R$ 842.317,45 com o R$ e os centavos menores na linha do número e "bruto, sem correção"; os blocos do Orçamento (com a seta), do Corrigido (R$ 926.847,69, "Correção até hoje: +R$ 84.530,24"), do A pagar (R$ 13.250,00, "3 vencimentos", com a seta) e da Venda estimada. Diferença de dado, não de tela: a vitrine tem o orçamento total de R$ 1.200.000,00 ("sobra R$ 357.682,55", 70%), e o mockup, o por tópico.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Identidade/Blocos.swift app-ios/Custta/Telas/BlocosDaObra.swift app-ios/Custta/Telas/ObraView.swift app-ios/Custta/Telas/PecasDaObra.swift app-ios/Custta/Telas/PecasDoOrcamento.swift app-ios/CusttaTests/BlocosDaObraTests.swift app-ios/CusttaTests/LinhaDoOrcamentoTests.swift app-ios/CusttaTests/OrcamentoEm375Tests.swift app-ios/CusttaUITests/AuditoriaUITests.swift app-ios/CusttaUITests/ObraUITests.swift app-ios/CusttaUITests/OrcamentoUITests.swift tests/app-ios.test.cjs
git commit -m "feat: o alto da obra em blocos, do título à venda" -m "A obra troca o alto da etapa 3 pela identidade nova do mockup aprovado da etapa 4: o nome no título mono, a cápsula com a fase e o tempo, o Total gasto no bloco sólido verde e um bloco de vidro por assunto, na ordem de sempre (Orçamento, Corrigido pelo banco, A pagar e Venda), com os números em SF Mono e a coluna na borda de 16 pt." -m "Na obra vendida com lucro, o sólido passa a mostrar o lucro da venda e o acima do banco, e o Total gasto desce para o vidro logo depois do Orçamento (decisão 4, A). Com prejuízo, o sólido volta a ser o Total gasto e o lucro fica no bloco da venda, em âmbar. Sem gastos, o sólido mostra R\$ 0,00 com o convite para lançar o primeiro gasto pelo +; na vendida sem gastos, não, porque o + de lá não lança nela." -m "Cada bloco continua um elemento só para o VoiceOver, com os mesmos identificadores, e os testes das etapas 2 e 3 sobre a obra seguem valendo; o do orçamento passa a medir o bloco próprio."
```

### Task 31: Afazeres, gastos por tópico e lançamentos da obra na grade nova

Embaixo das ações, a obra passa à identidade nova (spec, "Tela da obra"; mockup, `parte1.js:298-328`, `parte1-obra-meio.png` e `parte1-obra-fim.png`). Os afazeres viram um bloco de vidro com os cantos e o recuo da grade (26 e 16 × 18; 32 e 22 na letra de acessibilidade), sem o ícone do check da etapa 3 (AfazeresView.swift:23-30) e com "Afazeres" em body semibold (o `.afz .t1` do mockup), a etiqueta logo depois do título e a `SetaDoBloco` da Tarefa 30, 12 pt depois do texto (o `.afz{gap:12px}` do mockup, parte1.css:198; nos blocos do alto, 10, o do `.k-linha`). Depois deles, só com gastos, o bloco "Gastos por tópico" (título em body semibold, 8 pt acima da barra) com a `BarraDeTopicos` do PR 1b: a barra empilhada no lugar do mini-anel, sobre a placa forte, e a legenda dos 4 maiores (3 na letra de acessibilidade) com "e mais N tópicos", com os pedaços de `pedacosDoAnel(gastoPorTopico(obra))`. Para o VoiceOver, o bloco é um elemento só, como os outros: "Gastos por tópico", com o valor falado da barra (cada pedaço com o nome e o %, o "<1%" como "menos de 1%"), que sai da `BarraDeTopicos` para a função `faladoDaBarra(_:topicos:)` e serve aos dois; a legenda não é lida de novo. Com o `.contain`, o VoiceOver passava por cinco a sete paradas e dizia o título duas vezes (no texto e na barra), e esconder o título com o `accessibilityHidden` dentro do `.contain` não o tiraria da árvore. O bloco fica sem toque e sem o "Gráficos ›" do mockup, e as portas "Ver gráficos" e "Relatório" não aparecem: entram no PR que completa o destino (spec, tabela dos PRs, linha 1c, "a barra empilhada sem toque e sem 'Gráficos ›'; nenhuma porta"). Os lançamentos ficam 18 pt abaixo do bloco anterior (`.lan-cab`) e passam à linha mono (`.environment(\.linhaMono, true)` na coluna da obra, PR 1b, Tarefa 23): na lista da obra, o total do mês e o do "A vencer" vão no número mono (`.miudo`), o nome do mês em subheadline semibold (`.mes-cab`), na linha de base do total, e o "A vencer" perde o ícone do calendário; nos dois, o título ocupa o que sobra pelo `frame(maxWidth: .infinity)`, e não por um `Spacer` (o "A vencer" com o Negrito passava 1/3 de pt da largura nos três iPhones, como o cabeçalho dos blocos do PR 1b, e o cabeçalho de alguns meses também; nas folhas, o cabeçalho do mês continua centrado e com o `Spacer`, como na etapa 3), e a linha fina entre dois gastos fica nos 18 pt do recuo dos dois lados (antes, 67 pt depois do ícone). As folhas (A pagar, detalhe do tópico), que não estão na coluna da obra, continuam com a linha, o cabeçalho e a linha fina da etapa 3. Hoje a obra põe os afazeres num cartão de raio 24 com o ícone e 14 pt acima dos lançamentos (ObraView.swift:95-100), sem barra de tópicos. Com a obra em blocos (o alto da Tarefa 30 e estes blocos), a lista desce 283 pt, e as rolagens fixas do laudo da obra, calibradas na etapa 3, passam a medir outra coisa ou a cortar palavra pela borda de cima: em 835, o chip "3 pendentes" dos afazeres ficava cortado pela borda, e o pedaço de baixo das letras era medido no véu dela (4,46:1 no claro); em 596, a "busca, nada achado" media os blocos do alto, com o vazio sob a cápsula; em 1100, a "obra pronta, ações da fase, na maior letra" ficava entre o A pagar e a Venda estimada, sem ação nenhuma. Elas são refeitas aqui, com a obra inteira, cada uma com a borda de cima num vão (sem palavra cortada) no 18 Pro, a largura da CI, e no Pro Max, conferido nos quadros da árvore do XCUITest e nas tabelas do laudo. Para isso não voltar, a `Cena` ganha o `assunto`: os identificadores do que ela mede (ou o texto, sem identificador), conferidos à vista antes de cada print, abaixo da barra de status e acima da faixa de baixo (a borda de 140 pt ou a cápsula, a mesma que o laudo deixa de fora); toda cena com rolagem fixa tem o seu, menos as "abas sobre a lista", que medem só a cápsula. As rolagens:

| Cena | Antes | Agora | A borda de cima | Assunto |
| --- | --- | --- | --- | --- |
| obra, lista (e com Aumentar contraste) | 905 | 1170 | entre a pílula "Lançamentos" e o "A vencer" | `aVencer` |
| obra rolando (no Mac; na CI, só a 883 e a 1247) | 318, 561, 905, 1101, 1423, 1715 (na CI, 561 e 1101) | 612, 883, 1247 | entre o A pagar e a Venda; entre os afazeres e os gastos por tópico; entre o "A vencer" e o 1º mês, com as linhas dos meses da borda de cima à de baixo | `gastosPorTopico`, `aVencer`, `gasto-g027` |
| busca: em repouso, mês, achados | 1118 | 1118 | entre a legenda dos gastos por tópico e a pílula | `campoDaBusca`, `chipDoMes`, `somaDosAchados` |
| obra, linha aberta | 1118, com a g027 aberta | 1118, com a g026 | entre a legenda dos gastos por tópico e a pílula | `apagar-g026` |
| busca, nada achado | 596 | 1118 (o fim) | no 18 Pro, entre os afazeres e os gastos por tópico; no Pro Max, entre a ação e os afazeres | `buscaNadaEncontrado`, `limparFiltro` |
| busca, mês sem gasto | 1118 (o fim) | 804 | entre a ação "Marcar como pronta" e os afazeres (no Pro Max, o fim: no alto da ação, longe da letra) | `buscaMesSemGasto` |
| obra vendida com lucro / com prejuízo | 400 | 375 / 350 | antes do Corrigido / antes do A pagar | `acao-desfazerVenda` |
| obra pronta, ações da fase, na maior letra | 1100 | 1977 | no 18 Pro, entre a 1ª e a 2ª linha do "Toque no lápis para informar o valor"; no Pro Max, no alto da pílula do "Registrar venda", 10 pt acima do rótulo | `acao-registrarVenda`, `acao-voltarConstrucao` |
| obra com orçamento por tópico, na maior letra | 700 | 897 | no 18 Pro, entre o "Orçamento" e a etiqueta; no Pro Max, entre a etiqueta e o "sobra" | o texto "2 tópicos passaram do previsto" |
| obra pronta, ações da fase; as outras roladas (Ajustes, tela Orçamento, A pagar, detalhe do tópico) | iguais | iguais | já num vão | `acao-registrarVenda` e `acao-voltarConstrucao`, `nomeConta`, `topicoOrc-hidraulica`, `gastoTopico-pintura`, `topicoOrc-fundacao`, `gasto-d117`, `secao-Pagos`, o mês do 1º vencimento, `secao-A vencer` |

As rolagens foram escolhidas nos quadros da árvore do XCUITest de uma sonda (a obra aberta de 400 em 400 pt e, para os meses, com o hoje deslocado de 0 a 30 dias) e conferidas nas tabelas do laudo: nas cenas que mudaram, nenhuma palavra começa na borda (y = 140), nos dois iPhones. Na letra padrão, o alto, os afazeres, os gastos por tópico, a pílula, o "A vencer" e o cabeçalho do primeiro mês ficam iguais nos dois iPhones e em qualquer dia; nos cartões dos meses, não: no 18 Pro, a nota de alguns gastos quebra em duas linhas (a lista desce cada vez mais), e as linhas mudam com o dia (a vitrine conta os gastos a partir de hoje). Por isso a obra rolando fica fora dos cartões dos meses (a 1247 já põe as linhas deles da borda de cima à de baixo): a 1778 e a 1956, num vão nos dois iPhones em 30/10/2026, cortavam uma linha com o hoje deslocado 10 dias, e a parte de baixo dela, medida no véu da borda, ficava em 4,04 a 4,35:1 no Pro Max; a 1609 cortava uma linha no Pro Max e a 2524, no 18 Pro, e na 2524 com o hoje deslocado 5 dias a lista preguiçosa parou em lugares diferentes nos dois prints (55849 pixels longe das letras). A 612, a 883 e a 1247 passam com o hoje deslocado 5 e 15 dias no 18 Pro e 10 e 25 no Pro Max. A linha aberta passa da g027 à g026: aberta, a linha corre 96 pt para a esquerda e a borda do cartão corta o começo das letras; a nota da g027 quebra em duas no 18 Pro, e a fatia de um algarismo da data, na 2ª linha, ficava em 2,83:1 no claro (no Pro Max, passava). Na letra máxima, a obra quebra 162 pt a mais no 18 Pro que no Pro Max, e nenhuma rolagem acha um vão comum fora do "Toque no lápis…" com as duas ações à vista; a 1960 cortava a 1ª linha da frase no 18 Pro (onze pedaços de letra na borda, todos acima de 4,9:1).

**Files:**
- Modify: `app-ios/Custta/Identidade/BarraEmpilhada.swift`
- Modify: `app-ios/Custta/Telas/AfazeresView.swift`
- Modify: `app-ios/Custta/Telas/ObraView.swift`
- Modify: `app-ios/Custta/Telas/PecasDaObra.swift`
- Test (novo): `app-ios/CusttaTests/ListaDaObraTests.swift`
- Test (alterar): `app-ios/CusttaUITests/EstadosUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`
- Test (alterar): `app-ios/CusttaUITests/ObraUITests.swift`
- Test (alterar): `tests/app-ios.test.cjs`

**Interfaces:**
- Consumes: `BlocoDeVidro`, `BarraDeTopicos(pedacos:topicos:)`, `pedacosDoAnel(_:)`, `gastoPorTopico(_:)`, `ValorEmDinheiro(_:mono:)`, o `linhaMono` do environment e `Grade` (PR 1b e Tarefa 25); `SetaDoBloco` (Tarefa 30).
- Produces: o identificador `gastosPorTopico` (o bloco, um elemento só para o VoiceOver, com o rótulo "Gastos por tópico" e o valor falado da barra; a barra continua `barraDeTopicos`, filha dele na árvore do XCUITest); `faladoDaBarra(_ pedacos: [PedacoDoAnel], topicos: [String: Topico]) -> String`; `SeparadorDaLista()`; o `CabecalhoDoMes` e a `LinhaDoAVencer` com a forma mono pelo `linhaMono`; no laudo, `Cena.assunto: [String]` (identificadores ou o texto, conferidos à vista antes do print por `conferirAssunto(_:_:)`), que as cenas novas com rolagem fixa também levam.

- [ ] **Step 1: Escrever os testes**

A guarda Node da seta dos afazeres passa a pedir a `SetaDoBloco` (e nenhuma outra seta) no lugar do chevron de 14/18 pt da etapa 3. Na tela, os afazeres e os gastos por tópico na grade (16 pt de borda, a largura da coluna, 12 pt entre eles; o teste confere que o bloco existe logo depois de rolar até ele), o rótulo e o valor no `gastosPorTopico`, um elemento só (com o `.contain` de antes, ele ficava sem rótulo e sem valor; o XCUITest continua mostrando a legenda e a barra como filhas do bloco, como mostra o "Total gasto" dentro do `indicadorTotal`, de `.combine`, e o VoiceOver lê só o bloco), a legenda com "e mais 10 tópicos" dentro dele, o bloco que não é botão e os lançamentos depois; o "menos de 1%" no valor falado da Casa Granja Viana (a `a6` dos falsos da análise, Tarefa 28), que tem o Extras e o Outros abaixo de 1% (na Casa Alphaville, a Pintura, com 0,8%, fica dentro do "Outros · 8 tópicos" e não é falada à parte); na obra sem gastos, o bloco não existe e os afazeres sim. Na unidade, a varredura por `sizeThatFits` do "A vencer" fechado, do cabeçalho de cada mês da Casa Alphaville na forma mono e do bloco dos afazeres, com e sem o Negrito, em todo tamanho de letra e em escala 3, nas colunas de 343, 370 e 408 pt (`ListaDaObraTests`): a largura inteira no "A vencer" e nos afazeres (no "A vencer" na letra de acessibilidade, que empilha e abraça o texto, `<=`), e `<=` no cabeçalho do mês, que com um nome longo já empilha no xxxLarge com o Negrito, em 343. No laudo, o `assunto` de cada cena com rolagem fixa e as rolagens novas (a tabela acima). O teste do toque duplo no "Salvar" da vendida (`EstadosUITests`, etapa 2) passa a ler o nome no título pequeno da barra e a contagem na pílula "Lançamentos": a lista rola até a linha nova, e com o bloco dos gastos por tópico o alto sai da lista preguiçosa (sem isso, `tituloDaObra` não é achado). Com a marca `gravado` da Tarefa 29, ele passa.

Criar `app-ios/CusttaTests/ListaDaObraTests.swift`:

```swift
import Testing
import SwiftUI
@testable import Custta
import CusttaNucleo

/* As peças da lista da obra na grade nova (etapa 4, PR 1c): o "A vencer" fechado e o cabeçalho do mês na forma mono, e o
   bloco dos afazeres, não passam da largura da coluna em nenhum tamanho de letra, com e sem o Negrito, nas larguras dos
   iPhones (375, 402 e 440 pt menos as bordas de 16), em escala 3, com o cabeçalho de cada mês da Casa Alphaville. Com o
   Negrito, o "A vencer" mono passava 1/3 de pt nas três larguras: o Spacer ao lado do título arredondava para cima, como no
   cabeçalho dos blocos do PR 1b. */
@MainActor
struct ListaDaObraTests {
    /// A largura que a peça ocupa na coluna, na forma mono da lista da obra.
    private func medida(de peca: AnyView, letra: DynamicTypeSize, negrito: Bool, em coluna: CGFloat) -> CGFloat {
        UIHostingController(rootView: peca.environment(\.linhaMono, true).dynamicTypeSize(letra)
            .environment(\.legibilityWeight, negrito ? .bold : .regular).environment(\.displayScale, 3))
            .sizeThatFits(in: CGSize(width: coluna, height: CGFloat.infinity)).width
    }

    @Test func pecasDaListaNaoPassamDaLargura() throws {
        let hoje = Date.now
        let casa = Estado.de(DadosDeExemplo.vitrine(hoje: hoje)).obras[0]
        let lista = listaDaObra(casa, hoje: dataLocalISO(hoje, fuso: .current))
        let aVencer = try #require(lista.aVencer)
        #expect(!lista.meses.isEmpty)
        let afazeres = linhaDosAfazeres(casa.afazeres)
        for negrito in [false, true] {
            for letra in DynamicTypeSize.allCases {
                for largura in [CGFloat(343), 370, 408] {
                    let medir = { (peca: AnyView) in medida(de: peca, letra: letra, negrito: negrito, em: largura) }
                    let onde = "\(letra), negrito \(negrito), em \(largura)"
                    let bloco = medir(AnyView(LinhaDosAfazeresView(linha: afazeres)))
                    #expect(bloco == largura, "afazeres, \(onde): \(bloco)")
                    // Na letra de acessibilidade, o "A vencer" empilha o título e o total e abraça o texto; fora dela, ocupa a
                    // coluna inteira.
                    let linha = medir(AnyView(LinhaDoAVencer(grupo: aVencer, aberto: false)))
                    if letra.isAccessibilitySize {
                        #expect(linha <= largura, "A vencer, \(onde): \(linha)")
                    } else {
                        #expect(linha == largura, "A vencer, \(onde): \(linha)")
                    }
                    // O cabeçalho de um mês de nome longo empilha o total já no xxxLarge com o Negrito, em 343, e abraça o texto.
                    for mes in lista.meses {
                        let cabecalho = medir(AnyView(CabecalhoDoMes(mes: mes)))
                        #expect(cabecalho <= largura, "\(mes.titulo), \(onde): \(cabecalho)")
                    }
                }
            }
        }
    }
}
```

Em `app-ios/CusttaUITests/EstadosUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/EstadosUITests.swift
+++ b/app-ios/CusttaUITests/EstadosUITests.swift
@@ -100,8 +100,10 @@ final class EstadosUITests: XCTestCase {
         app.buttons["salvarGasto"].doubleTap()
         XCTAssertTrue(app.buttons["salvarGasto"].waitForNonExistence(timeout: 5))
         sleep(1)
-        XCTAssertEqual(app.elemento("tituloDaObra").label, "Casa Alphaville")
-        XCTAssertTrue(app.elemento("indicadorTotal").label.contains("47 lançamentos"), app.elemento("indicadorTotal").label)
+        // A lista rolou até a linha nova (o destaque). Com a obra em blocos (etapa 4), o alto fica longe e sai da lista
+        // preguiçosa: o nome vem do título pequeno da barra, e a contagem, da pílula "Lançamentos", logo acima da linha.
+        XCTAssertEqual(app.elemento("tituloPequenoDaBarra").label, "Casa Alphaville")
+        XCTAssertTrue(app.elemento("lancamentos").label.contains("47"), app.elemento("lancamentos").label)
     }
 
     /// Na maior letra o nome da obra quebra embaixo do rótulo e fica à esquerda, como no mockup (`.f-lin .d` alinhado à
```

Em `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -49,6 +49,11 @@ final class LeituraNoVidroUITests: XCTestCase {
         /// Toques depois de a tela abrir e antes do print, os mesmos nos dois (a busca, o mês, os Feitos, a linha arrastada;
         /// etapa 3, PR 3): o estado a que se chega pelo toque, sem gancho de teste.
         var toques: (@MainActor (XCUIApplication) -> Void)? = nil
+        /// O que a cena mede: identificadores (ou o texto, sem identificador) conferidos à vista antes de cada print, abaixo da
+        /// barra de status e acima da faixa de baixo (`conferirAssunto`). Toda cena com rolagem fixa tem o seu: o laudo passa
+        /// com a rolagem medindo outra coisa (com a obra em blocos da etapa 4, a "busca, nada achado" em 596 media os blocos
+        /// do alto, com o vazio sob a cápsula).
+        var assunto: [String] = []
     }
 
     /// A tabela de exceções do laudo: a cena e a figura que sai dos dois prints dela (`foraDoLaudo(_:)` no app, com
@@ -75,6 +80,7 @@ final class LeituraNoVidroUITests: XCTestCase {
         }
         cena.toques?(app)
         Thread.sleep(forTimeInterval: 2)                           // o vidro e a rolagem assentam
+        conferirAssunto(cena, app)
         let foto = XCUIScreen.main.screenshot()
         let abas = ["aba-obras", "aba-ajustes"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
         let largura = app.frame.width
@@ -83,6 +89,22 @@ final class LeituraNoVidroUITests: XCTestCase {
         return (foto, abas, largura, informativo)
     }
 
+    /// O assunto da cena à vista antes do print: abaixo da barra de status e acima da faixa de baixo, a borda de 140 pt ou a
+    /// cápsula de abas, o que vier antes (a mesma de `conferir`). Pelo identificador ou, sem ele, pelo texto (a frase do aviso
+    /// dos tópicos, dentro do bloco do orçamento).
+    @MainActor private func conferirAssunto(_ cena: Cena, _ app: XCUIApplication) {
+        let altura = app.frame.height
+        let capsula = app.buttons["aba-obras"]
+        let fim = min(capsula.exists ? capsula.frame.minY - 10 : altura, altura - 140)
+        for assunto in cena.assunto {
+            let alvo = app.descendants(matching: .any)
+                .matching(NSPredicate(format: "identifier == %@ OR label == %@", assunto, assunto)).firstMatch
+            let quadro = alvo.exists ? alvo.frame : .null
+            XCTAssertTrue(!quadro.isNull && quadro.minY >= Self.barraDeStatus && quadro.maxY <= fim,
+                          "\(cena.nome): \(assunto) fora da vista (\(quadro); a cena mede de \(Int(Self.barraDeStatus)) a \(Int(fim)) pt)")
+        }
+    }
+
     /// O exemplo da descrição do gasto ("Ex: 50 sacos de cimento") é o único texto fora do portão: o mockup aprovado o
     /// marca como informativo (parte2.html:1981), no terciário sobre a linha sólida da folha (3,40:1 no escuro esmeralda,
     /// 3,84 no escuro azul), o mesmo tom do prompt do campo no build 3.1. O laudo não via aquele prompt (quem o desenha é
@@ -234,7 +256,7 @@ final class LeituraNoVidroUITests: XCTestCase {
                   ("na maior letra, rolada", escuro + maiorLetra + ["-custta.rolagem", "2000"], true)]
         cobrar(cenas.map { nome, argumentos, rolada in
             Cena(nome: "ajustes, \(nome)", conta: "senha", argumentos: argumentos, espera: "aba-ajustes", escopo: "tudo",
-                 aba: "ajustes", rolada: rolada)
+                 aba: "ajustes", rolada: rolada, assunto: rolada ? ["nomeConta"] : [])
         })
     }
 }
@@ -343,10 +365,11 @@ extension LeituraNoVidroUITests {
 
     /// A tela da obra (etapa 2): o topo (título, fase, indicadores) e a lista rolada (o "A vencer" e os cartões dos meses),
     /// no escuro e no claro; mais a maior letra e o Aumentar contraste, no escuro esmeralda. A vendida fica no
-    /// testLeituraDaObraVendida (lucro e prejuízo). A lista em 905 pt: a 640 até a etapa 2; a linha do orçamento da vitrine
-    /// (118 pt, PR 1 da etapa 3) e a linha dos afazeres com o cabeçalho da busca (117 pt, PR 3) empurraram tudo o que vem
-    /// depois deles. A borda de cima fica no vão entre a pílula "Lançamentos" e o "A vencer" (no 18 Pro, 23 pt abaixo da pílula
-    /// e 18 acima do "A vencer"): a 875, os mesmos 758 de antes mais 117, ela cortava a pílula.
+    /// testLeituraDaObraVendida (lucro e prejuízo). A lista em 1170 pt: a 640 até a etapa 2 e a 905 na etapa 3, depois da
+    /// linha do orçamento e da linha dos afazeres com o cabeçalho da busca; com a obra em blocos da etapa 4 (o alto, o bloco
+    /// dos afazeres e o dos gastos por tópico), a 905 punha a borda no bloco dos gastos por tópico. A borda de cima fica no vão
+    /// entre a pílula "Lançamentos" e o "A vencer", igual nos dois iPhones (13 pt abaixo do texto da pílula e 20 acima do "A
+    /// vencer"), acima de tudo o que muda com o dia.
     @MainActor func testLeituraDaObra() {
         var cenas: [Cena] = []
         for tema in temas {
@@ -354,34 +377,37 @@ extension LeituraNoVidroUITests {
             cenas += [
                 Cena(nome: "obra, topo, \(tema)", conta: "senha", argumentos: combo, espera: "tituloDaObra", escopo: "tudo",
                      dados: "vitrine", abrir: "obra:v1"),
-                Cena(nome: "obra, lista, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "905"],
-                     espera: "aVencer", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
+                Cena(nome: "obra, lista, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "1170"],
+                     espera: "aVencer", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true, assunto: ["aVencer"]),
             ]
         }
         let escuro = ["-custta.tema", "escuro"] + piorMomento
         cenas += [
             Cena(nome: "obra na maior letra", conta: "senha", argumentos: escuro + maiorLetra, espera: "tituloDaObra", escopo: "tudo",
                  dados: "vitrine", abrir: "obra:v1"),
-            Cena(nome: "obra com Aumentar contraste", conta: "senha", argumentos: escuro + ["-custta.aumentarContraste", "YES", "-custta.rolagem", "905"],
-                 espera: "aVencer", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
+            Cena(nome: "obra com Aumentar contraste", conta: "senha",
+                 argumentos: escuro + ["-custta.aumentarContraste", "YES", "-custta.rolagem", "1170"], espera: "aVencer",
+                 escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true, assunto: ["aVencer"]),
         ]
         cobrar(cenas)
     }
 
     /// A lista da obra rolando, no escuro (onde a dose de vidro decide), sem e com Aumentar contraste: o pior
-    /// ponto de um cabeçalho de mês ou de uma linha de baixo pode estar fora do quadro de 640 pt. No Mac, seis rolagens; na
+    /// ponto de um cabeçalho de mês ou de uma linha de baixo pode estar fora do quadro de 640 pt. No Mac, três rolagens; na
     /// CI, duas.
     @MainActor func testLeituraDaObraRolando() {
-        // As da etapa 2 (200 a 1500) desceram 118 pt com a linha do orçamento da vitrine (PR 1 da etapa 3). No PR 3, cada uma
-        // tem a borda de cima no meio de um vão entre duas linhas (de 12 a 23 pt de folga no 18 Pro, em 25/10), sem palavra
-        // cortada pela borda: a 318 fica; a 561 é a 518 mais 43 (a 518 já cortava uma palavra); da terceira em diante, as de
-        // antes mais 117 (a linha dos afazeres e o cabeçalho da busca, que o PR 3 pôs depois das ações) cortavam palavra (a
-        // 1318, a linha de baixo de um gasto em 3,91), e cada uma foi para o vão mais perto. A 318 e a 561 mostram a linha dos
-        // afazeres e a busca embaixo. Da 1101 para baixo, as linhas são as dos cartões dos meses, que mudam com o dia (a
-        // vitrine conta os gastos a partir de hoje): em 26/10, a "Quinzena do pedreiro" de 55 dias atrás passou de agosto para
-        // setembro, e a 1715 ficou com 8 pt de folga embaixo; com o hoje deslocado para 3/11 (o cartão do mês novo nasce com um
-        // gasto só), a 561 e a 1101 seguem num vão, e a 1423 e a 1715 cortam uma palavra pela borda (que passa, de 6,26 a 7,26).
-        let rolagens = ProcessInfo.processInfo.environment["CUSTTA_VARREDURA"] == "curta" ? [561, 1101] : [318, 561, 905, 1101, 1423, 1715]
+        // Cada rolagem tem a borda de cima num vão entre duas linhas, igual no 18 Pro e no Pro Max e em qualquer dia, e o seu
+        // assunto à vista. Com a obra em blocos da etapa 4, as da etapa 3 (318 a 1715) cortavam palavra ou mostravam outra coisa:
+        // - 612: entre o A pagar e a Venda estimada (os afazeres e os gastos por tópico embaixo);
+        // - 883: entre os afazeres e os gastos por tópico (a pílula, o "A vencer" e o começo dos meses embaixo);
+        // - 1247: entre o "A vencer" e o cabeçalho do primeiro mês, que vem sempre logo depois dele, com as linhas dos meses
+        //   da borda de cima à de baixo.
+        // Nenhuma fica dentro dos cartões dos meses: ali, os dois iPhones se desencontram (no 18 Pro, a nota de alguns gastos
+        // quebra em duas linhas, e a lista desce cada vez mais) e as linhas mudam com o dia (a vitrine conta os gastos a partir
+        // de hoje). A 1778 e a 1956, num vão nos dois em 30/10/2026, cortavam uma linha com o hoje deslocado 10 dias, e a parte
+        // de baixo dela, medida no véu da borda, ficava em 4,04 a 4,35:1 no Pro Max. Na CI, a 883 e a 1247.
+        let rolagens = ProcessInfo.processInfo.environment["CUSTTA_VARREDURA"] == "curta" ? [883, 1247] : [612, 883, 1247]
+        let assuntos = [612: "gastosPorTopico", 883: "aVencer", 1247: "gasto-g027"]
         var cenas: [Cena] = []
         for contraste in [false, true] {
             for y in rolagens {
@@ -390,7 +416,7 @@ extension LeituraNoVidroUITests {
                 // Espera o título pequeno da barra: rolada, a lista já soltou o título grande da árvore.
                 cenas.append(Cena(nome: "obra rolando \(y), escuro\(contraste ? ", Aumentar contraste" : "")", conta: "senha",
                                   argumentos: argumentos, espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "vitrine",
-                                  abrir: "obra:v1", rolada: true))
+                                  abrir: "obra:v1", rolada: true, assunto: assuntos[y].map { [$0] } ?? []))
             }
         }
         cobrar(cenas)
@@ -414,11 +440,14 @@ extension LeituraNoVidroUITests {
                 folha("folha, tópicos, \(tema)", "topicos", combo, espera: "topico-terreno"),
                 folha("folha, parcela, \(tema)", "editar:g031", combo, espera: "avisoParcela"),
                 folha("folha, repetido, \(tema)", "repetido", combo, espera: "avisoRepetido"),
-                // A 835 põe a borda no vão entre os afazeres e a pílula; a 758 de antes, com a lista 117 pt mais abaixo
-                // desde o PR 3, cortava o cabeçalho dos afazeres.
+                // A 1118 põe a borda no vão entre a legenda dos gastos por tópico e a pílula "Lançamentos" (32 pt abaixo de uma e
+                // 9 acima da outra), como as cenas da busca; a 835 da etapa 3, com a obra em blocos, cortava o chip "3 pendentes".
+                // A linha aberta é a g026, com a nota numa linha nos dois iPhones: aberta, ela corre 96 pt para a esquerda, e a
+                // borda do cartão corta o começo das letras. Na g027 da etapa 3, a nota quebra em duas no 18 Pro, e a fatia de um
+                // algarismo da data, cortada na 2ª linha, ficava em 2,83:1 no claro.
                 Cena(nome: "obra, linha aberta, \(tema)", conta: "senha",
-                     argumentos: combo + ["-custta.rolagem", "835", "-custta.linhaAberta", "g027"], espera: "apagar-g027",
-                     escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true),
+                     argumentos: combo + ["-custta.rolagem", "1118", "-custta.linhaAberta", "g026"], espera: "apagar-g026",
+                     escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true, assunto: ["apagar-g026"]),
             ]
         }
         let escuro = ["-custta.tema", "escuro"] + piorMomento
@@ -442,7 +471,8 @@ extension LeituraNoVidroUITests {
             let combo = ["-custta.tema", tema] + piorMomento
             cenas += [
                 Cena(nome: "obra pronta, ações da fase, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "250"],
-                     espera: "acao-voltarConstrucao", escopo: "tudo", dados: "vitrine", abrir: "obra:v2", rolada: true),
+                     espera: "acao-voltarConstrucao", escopo: "tudo", dados: "vitrine", abrir: "obra:v2", rolada: true,
+                     assunto: ["acao-registrarVenda", "acao-voltarConstrucao"]),
                 Cena(nome: "lista vazia, \(tema)", conta: "senha", argumentos: combo, espera: "obrasVazio", escopo: "tudo", dados: "vazio"),
                 Cena(nome: "folha da obra nova, \(tema)", conta: "senha", argumentos: combo + ["-custta.folha", "preenchida"],
                      espera: "nomeDaObra", escopo: "tudo", dados: "vitrine", folha: "novaObra"),
@@ -466,12 +496,17 @@ extension LeituraNoVidroUITests {
     @MainActor func testLeituraDaObraVendida() {
         var cenas: [Cena] = []
         for tema in temas {
-            let combo = ["-custta.tema", tema] + piorMomento + ["-custta.rolagem", "400"]
+            let combo = ["-custta.tema", tema] + piorMomento
+            // Na obra em blocos, a borda fica no vão antes do Corrigido (com lucro, o Total gasto desce para o vidro) e antes do
+            // A pagar (com prejuízo, ele fica no sólido), 22 pt abaixo de uma nota e acima de um rótulo; a 400 da etapa 3
+            // cortava o "Corrigido pelo banco" da com lucro.
             cenas += [
-                Cena(nome: "obra vendida com lucro, \(tema)", conta: "senha", argumentos: combo, espera: "acao-desfazerVenda",
-                     escopo: "tudo", dados: "vitrine", abrir: "obra:v3", rolada: true),
-                Cena(nome: "obra vendida com prejuízo, \(tema)", conta: "senha", argumentos: combo, espera: "acao-desfazerVenda",
-                     escopo: "tudo", dados: "prejuizo", abrir: "obra:v3", rolada: true),
+                Cena(nome: "obra vendida com lucro, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "375"],
+                     espera: "acao-desfazerVenda", escopo: "tudo", dados: "vitrine", abrir: "obra:v3", rolada: true,
+                     assunto: ["acao-desfazerVenda"]),
+                Cena(nome: "obra vendida com prejuízo, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "350"],
+                     espera: "acao-desfazerVenda", escopo: "tudo", dados: "prejuizo", abrir: "obra:v3", rolada: true,
+                     assunto: ["acao-desfazerVenda"]),
             ]
         }
         cobrar(cenas)
@@ -480,9 +515,15 @@ extension LeituraNoVidroUITests {
     @MainActor func testLeituraDaParte3NaMaiorLetra() {
         let escuro = ["-custta.tema", "escuro"] + piorMomento + maiorLetra
         cobrar([
-            // Espera o lápis da barra: rolada a 1100 pt em 300 ms, o título sai da pilha preguiçosa antes da espera achar.
-            Cena(nome: "obra pronta, ações da fase, na maior letra", conta: "senha", argumentos: escuro + ["-custta.rolagem", "1100"],
-                 espera: "editarObra", escopo: "tudo", dados: "vitrine", abrir: "obra:v2", rolada: true),
+            // Espera o lápis da barra: rolada, o título sai da pilha preguiçosa antes da espera achar. A 1977 pt, as ações à vista
+            // nos dois iPhones (a 1100 da etapa 3, a obra em blocos punha a tela entre o A pagar e a Venda estimada, sem ação
+            // nenhuma). A obra quebra 162 pt a mais no 18 Pro, e nenhuma rolagem acha um vão comum fora do "Toque no lápis para
+            // informar o valor": no 18 Pro (a largura da CI), a borda fica entre a 1ª e a 2ª linha dessa frase (6 pt abaixo da
+            // perna do "p" e 9 acima da linha de baixo; a 1960 cortava a 1ª linha); no Pro Max, no alto do "Registrar venda", 10
+            // pt acima do rótulo.
+            Cena(nome: "obra pronta, ações da fase, na maior letra", conta: "senha", argumentos: escuro + ["-custta.rolagem", "1977"],
+                 espera: "editarObra", escopo: "tudo", dados: "vitrine", abrir: "obra:v2", rolada: true,
+                 assunto: ["acao-registrarVenda", "acao-voltarConstrucao"]),
             Cena(nome: "lista vazia na maior letra", conta: "senha", argumentos: escuro, espera: "obrasVazio", escopo: "tudo", dados: "vazio"),
             Cena(nome: "folha da obra nova na maior letra", conta: "senha", argumentos: escuro + ["-custta.folha", "preenchida"],
                  espera: "nomeDaObra", escopo: "tudo", dados: "vitrine", folha: "novaObra"),
@@ -540,11 +581,13 @@ extension LeituraNoVidroUITests {
                      espera: "cartaoDoOrcamento", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1"),
                 // Espera o título pequeno da barra: rolada, a lista já soltou o título grande da árvore.
                 Cena(nome: "tela Orçamento, rolada, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "700"],
-                     espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", rolada: true),
+                     espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", rolada: true,
+                     assunto: ["topicoOrc-hidraulica"]),
                 // 8 pt antes do fim: no fim, a borda de cima cortava o "5% da obra" do Telhado (o laudo mede a parte de baixo
                 // de uma palavra que entra no véu); aqui ela fica entre o nome do Telhado e o percentual, e a dica ainda aparece.
                 Cena(nome: "tela Orçamento, só o total, fim, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "606"],
-                     espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "vitrine", abrir: "orcamento:v1", rolada: true),
+                     espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "vitrine", abrir: "orcamento:v1", rolada: true,
+                     assunto: ["gastoTopico-pintura"]),
                 Cena(nome: "folha do orçamento, por tópico, digitando, \(tema)", conta: "senha",
                      argumentos: combo + ["-custta.folha", "teclas:eletrica"], espera: "barraDasTeclas-nome", escopo: "tudo",
                      dados: "porTopico", abrir: "orcamento:v1", folha: "orcamento:v1"),
@@ -561,9 +604,13 @@ extension LeituraNoVidroUITests {
         let escuro = ["-custta.tema", "escuro"] + piorMomento
         let grande = escuro + maiorLetra, contraste = escuro + ["-custta.aumentarContraste", "YES"]
         cobrar([
-            // O triângulo do aviso sai dos dois prints desta cena (a tabela de exceções, `excecoes`); a frase dele fica.
-            Cena(nome: "obra com orçamento por tópico, na maior letra", conta: "senha", argumentos: grande + ["-custta.rolagem", "700"],
-                 espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "porTopico", abrir: "obra:v1", rolada: true),
+            // O triângulo do aviso sai dos dois prints desta cena (a tabela de exceções, `excecoes`); a frase dele fica. A 897 pt,
+            // o aviso inteiro à vista nos dois iPhones, com a borda num vão: no 18 Pro (a largura da CI), entre o "Orçamento" e a
+            // etiqueta "dentro do previsto"; no Pro Max, onde a obra sobe 102 pt, entre a etiqueta e o "sobra". A 700 da etapa 3,
+            // no 18 Pro, a obra em blocos punha o aviso sob a faixa de baixo.
+            Cena(nome: "obra com orçamento por tópico, na maior letra", conta: "senha", argumentos: grande + ["-custta.rolagem", "897"],
+                 espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "porTopico", abrir: "obra:v1", rolada: true,
+                 assunto: ["2 tópicos passaram do previsto"]),
             Cena(nome: "tela Orçamento, topo, na maior letra", conta: "senha", argumentos: grande, espera: "cartaoDoOrcamento",
                  escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1"),
             // A 1637 pt, nos dois iPhones, a borda de cima fica no vão entre a Estrutura e a Fundação, sem texto nem barra logo
@@ -572,7 +619,8 @@ extension LeituraNoVidroUITests {
             // texto borrado pelo véu logo acima, e o alto dela mudava entre os dois prints (1837 px longe das letras:
             // CenaNaoDeterministica). De 1615 a 1660, nos dois, nenhum pixel muda longe das letras.
             Cena(nome: "tela Orçamento, rolada, na maior letra", conta: "senha", argumentos: grande + ["-custta.rolagem", "1637"],
-                 espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", rolada: true),
+                 espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", rolada: true,
+                 assunto: ["topicoOrc-fundacao"]),
             // Na maior letra, a linha ativa no meio da faixa leva o alto da lista (o segmentado) para baixo da barra da folha,
             // que borra o que passa por ela: as cenas da folha com as teclas são roladas.
             Cena(nome: "folha do orçamento, por tópico, digitando, na maior letra", conta: "senha",
@@ -604,7 +652,8 @@ extension LeituraNoVidroUITests {
                 // entre duas diárias; a frase do fim cai na faixa de baixo, que o laudo deixa de fora (a da cápsula de abas, que
                 // segue atrás da folha): a cena mede as linhas que passam pelo meio.
                 Cena(nome: "A pagar, fim, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "1092"],
-                     espera: "ponteDoAPagar", escopo: "tudo", dados: "topicoLongo", abrir: "obra:v1", folha: "aPagar:v1", rolada: true),
+                     espera: "ponteDoAPagar", escopo: "tudo", dados: "topicoLongo", abrir: "obra:v1", folha: "aPagar:v1", rolada: true,
+                     assunto: ["gasto-d117"]),
                 Cena(nome: "A pagar vazio, \(tema)", conta: "senha", argumentos: combo, espera: "aPagarVazio", escopo: "tudo",
                      dados: "vitrine", abrir: "obra:v2", folha: "aPagar:v2"),
                 Cena(nome: "A pagar, editar gasto, \(tema)", conta: "senha", argumentos: combo + ["-custta.origem", "editar:g039"],
@@ -615,7 +664,7 @@ extension LeituraNoVidroUITests {
                 // A espera não prova a rolagem: a pilha preguiçosa já monta as 16 peças da Cerâmica no topo.
                 Cena(nome: "detalhe, Cerâmica, rolada, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "500"],
                      espera: "gasto-g021", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:revest",
-                     rolada: true),
+                     rolada: true, assunto: ["secao-Pagos"]),
                 Cena(nome: "detalhe, Estrutura, passou, \(tema)", conta: "senha", argumentos: combo, espera: "orcamentoDoTopico",
                      escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:estrutura"),
                 Cena(nome: "detalhe, Documentação, fora, \(tema)", conta: "senha", argumentos: combo, espera: "orcamentoDoTopico",
@@ -645,7 +694,8 @@ extension LeituraNoVidroUITests {
             // (o mês do primeiro vencimento vem sempre logo depois do resumo); os de baixo, sim (os vencimentos da vitrine mudam de
             // mês com o dia). A cena mede o cabeçalho do mês e a primeira linha quase inteira.
             Cena(nome: "A pagar, rolado, na maior letra", conta: "senha", argumentos: grande + ["-custta.rolagem", "248"],
-                 espera: "resumoDoAPagar", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", folha: "aPagar:v1", rolada: true),
+                 espera: "resumoDoAPagar", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", folha: "aPagar:v1", rolada: true,
+                 assunto: [Self.idDoMes(daqui: 3)]),
             Cena(nome: "A pagar, editar gasto, na maior letra", conta: "senha", argumentos: grande + ["-custta.origem", "editar:g039"],
                  espera: "salvarGasto", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", folha: "aPagar:v1"),
             Cena(nome: "detalhe, Cerâmica, topo, na maior letra", conta: "senha", argumentos: grande, espera: "orcamentoDoTopico",
@@ -656,7 +706,7 @@ extension LeituraNoVidroUITests {
             // a cena rolada da letra padrão.
             Cena(nome: "detalhe, Cerâmica, rolada, na maior letra", conta: "senha", argumentos: grande + ["-custta.rolagem", "628"],
                  espera: "orcamentoDoTopico", escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:revest",
-                 rolada: true),
+                 rolada: true, assunto: ["secao-A vencer"]),
             Cena(nome: "detalhe, Estrutura, passou, na maior letra", conta: "senha", argumentos: grande, espera: "orcamentoDoTopico",
                  escopo: "tudo", dados: "porTopico", abrir: "orcamento:v1", folha: "topico:v1:estrutura"),
             Cena(nome: "detalhe, editar gasto, na maior letra", conta: "senha", argumentos: grande + ["-custta.origem", "editar:g021"],
@@ -673,36 +723,42 @@ extension LeituraNoVidroUITests {
     /// A busca e os afazeres (etapa 3, PR 3), no escuro e no claro, na Casa Alphaville da vitrine; tudo pelo toque
     /// (`Cena.toques`), sem gancho novo. A busca: os lançamentos com o campo vazio e o chip do mês de hoje, em repouso (o
     /// "buscar" do teclado o fecha); o mês de hoje com a soma; "ceramica", com os achados e a soma deles; "azulejo", nada
-    /// achado, com o "Limpar a busca"; e o mês sem gasto, com o "Ver todos os meses" (o mês mais novo tem só a última parcela
-    /// do porcelanato, daqui a 175 dias, em qualquer dia: apagada só ela, o mês fica vazio). A lista fica parada pela rolagem
-    /// fixa da obra, que a segura mesmo depois da lupa (sem ela, a lupa põe a pílula "Lançamentos" sob a borda). A 835 pt, a
-    /// borda de cima fica no vão entre a linha dos afazeres e a pílula (no 18 Pro, 26 pt abaixo de uma e 32 acima da outra),
-    /// acima de tudo o que muda com o dia. As listas curtas não chegam aos 835 e param no fim: no mês sem gasto, a borda fica
-    /// no vão entre os dois últimos indicadores (7 pt abaixo do "Parcelas e gastos futuros" e 24 acima do "Venda estimada");
-    /// no nada achado, o fim a punha sobre o valor da venda estimada, e a 596 pt (7 antes do fim) ela fica no vão entre o
-    /// "Venda estimada" e o valor, a 7 pt de cada um, com o "Limpar a busca" 26 pt acima da faixa de baixo. Nenhuma dessas
-    /// linhas muda com o dia. Os afazeres: a tela com os 3 pendentes (o de 213 caracteres inteiro) e os "Feitos" fechados, os
-    /// "Feitos" abertos, o vazio (a Casa Tamboré) e a linha arrastada com o "Apagar". Ficam de fora: o menu do mês, que é do
-    /// sistema (nem a cor nem o vidro dele são do app); e o texto digitado e o prompt dos campos, que o UIKit desenha e o
-    /// texto apagado não tira (ponto cego do laudo: saem iguais nos dois prints). Roda no job laudo-etapa3-b.
+    /// achado, com o "Limpar a busca"; e o mês sem gasto, com o "Ver todos os meses" (o mês mais novo tem só a última
+    /// parcela do porcelanato, daqui a 175 dias, em qualquer dia: apagada só ela, o mês fica vazio). A lista fica parada
+    /// pela rolagem fixa da obra, que a segura mesmo depois da lupa (sem ela, a lupa põe a pílula "Lançamentos" sob a
+    /// borda). A 1118 pt, a borda de cima fica no vão entre a legenda dos gastos por tópico e a pílula (32 pt abaixo de uma
+    /// e 9 acima da outra, nos dois iPhones), acima de tudo o que muda com o dia. As listas curtas param antes: no nada
+    /// achado, a 1118 vai até o fim, com a borda num vão (no 18 Pro, entre os afazeres e o "Gastos por tópico"; no Pro Max,
+    /// mais alto, entre a ação "Marcar como pronta" e os afazeres) e o "Limpar a busca" à vista nos dois; no mês sem gasto,
+    /// mais curto, o fim cortava o "Afazeres" no 18 Pro, e a 804 pt a borda fica entre a ação e os afazeres (no Pro Max, a
+    /// 804 passa do fim, que a põe no alto da ação, longe da letra). Nenhuma dessas linhas muda com o dia. Os afazeres: a
+    /// tela com os 3 pendentes (o de 213 caracteres inteiro) e os "Feitos" fechados, os "Feitos" abertos, o vazio (a Casa
+    /// Tamboré) e a linha arrastada com o "Apagar". Ficam de fora: o menu do mês, que é do sistema (nem a cor nem o vidro
+    /// dele são do app); e o texto digitado e o prompt dos campos, que o UIKit desenha e o texto apagado não tira (ponto
+    /// cego do laudo: saem iguais nos dois prints). Roda no job laudo-etapa3-b.
     @MainActor func testLeituraDaBuscaEDosAfazeres() {
         let hoje = Self.mesPorExtenso(daqui: 0), maisNovo = Self.mesPorExtenso(daqui: 175)
         var cenas: [Cena] = []
         for tema in temas {
             let combo = ["-custta.tema", tema] + piorMomento
-            func busca(_ nome: String, rolagem: Int = 835, _ toques: @escaping @MainActor (XCUIApplication) -> Void) -> Cena {
+            // A pílula "Lançamentos" logo abaixo da borda de rolagem, como na etapa 3 (835): a obra em blocos da etapa 4 desceu a
+            // lista 283 pt. Em 835, o chip "3 pendentes" dos afazeres ficava cortado pela borda, e o pedaço de baixo da letra
+            // era medido no véu dela (4,46:1 no claro); em 596, o vazio do nada achado ficava sob a cápsula.
+            func busca(_ nome: String, rolagem: Int = 1118, assunto: [String],
+                       _ toques: @escaping @MainActor (XCUIApplication) -> Void) -> Cena {
                 Cena(nome: "busca, \(nome), \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "\(rolagem)"],
-                     espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true, toques: toques)
+                     espera: "tituloPequenoDaBarra", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true, toques: toques,
+                     assunto: assunto)
             }
             cenas += [
-                busca("em repouso") { app in
+                busca("em repouso", assunto: ["campoDaBusca", "chipDoMes"]) { app in
                     Self.buscar(app, "")
                     Self.escolherMes(app, hoje)
                 },
-                busca("mês") { app in Self.escolherMes(app, hoje) },
-                busca("achados") { app in Self.buscar(app, "ceramica") },
-                busca("nada achado", rolagem: 596) { app in Self.buscar(app, "azulejo") },
-                busca("mês sem gasto") { app in
+                busca("mês", assunto: ["chipDoMes", "somaDosAchados"]) { app in Self.escolherMes(app, hoje) },
+                busca("achados", assunto: ["campoDaBusca", "somaDosAchados"]) { app in Self.buscar(app, "ceramica") },
+                busca("nada achado", assunto: ["buscaNadaEncontrado", "limparFiltro"]) { app in Self.buscar(app, "azulejo") },
+                busca("mês sem gasto", rolagem: 804, assunto: ["buscaMesSemGasto"]) { app in
                     Self.escolherMes(app, maisNovo)
                     let linha = app.elemento("gasto-g037")
                     XCTAssertTrue(linha.waitForExistence(timeout: 5), "a última parcela no A vencer, aberto pelo filtro")
@@ -741,6 +797,16 @@ extension LeituraNoVidroUITests {
         return texto.prefix(1).uppercased() + texto.dropFirst()
     }
 
+    /// O identificador do cartão de um mês (`mes-AAAA-MM`) daqui a tantos dias: o do primeiro vencimento da vitrine no A pagar
+    /// (o g039, daqui a 3 dias).
+    private static func idDoMes(daqui dias: Int) -> String {
+        let data = Calendar(identifier: .gregorian).date(byAdding: .day, value: dias, to: .now) ?? .now
+        let formato = DateFormatter()
+        formato.locale = Locale(identifier: "en_US_POSIX")
+        formato.dateFormat = "yyyy-MM"
+        return "mes-" + formato.string(from: data)
+    }
+
     /// O mês pelo menu do sistema, tocado pelo título (o item traz a contagem no subtítulo), como no BuscaUITests.
     @MainActor private static func escolherMes(_ app: XCUIApplication, _ titulo: String) {
         app.buttons["filtrarPorMes"].tap()
```

Em `app-ios/CusttaUITests/ObraUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/ObraUITests.swift
+++ b/app-ios/CusttaUITests/ObraUITests.swift
@@ -144,6 +144,52 @@ final class ObraUITests: XCTestCase {
         XCTAssertTrue(app.elemento("indicadorVenda").label.contains("R$\u{a0}1.380.000,00"))
     }
 
+    /// Embaixo das ações, os afazeres e os gastos por tópico, blocos de vidro na grade, 12 pt um do outro: o bloco dos gastos
+    /// por tópico é um elemento só no VoiceOver, com o título e os pedaços no rótulo e no valor (a legenda, dentro dele, não
+    /// é lida de novo), sem toque (a porta para os Gráficos chega com eles); depois, os lançamentos.
+    func testAfazeresEGastosPorTopicoEmBlocos() {
+        let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1")
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
+        let largura = app.windows.firstMatch.frame.width
+        let topicos = app.elemento("gastosPorTopico")
+        app.rolarAte(topicos)
+        XCTAssertTrue(topicos.exists, "o bloco dos gastos por tópico")
+        let afazeres = app.elemento("linhaDosAfazeres").frame, bloco = topicos.frame
+        for (nome, quadro) in [("afazeres", afazeres), ("gastos por tópico", bloco)] {
+            XCTAssertEqual(quadro.minX, 16, accuracy: 0.5, "\(nome) na borda de 16 pt")
+            XCTAssertEqual(quadro.width, largura - 32, accuracy: 0.5, "\(nome) na largura da coluna")
+        }
+        XCTAssertEqual(bloco.minY - afazeres.maxY, 12, accuracy: 0.5, "os gastos por tópico 12 pt abaixo dos afazeres")
+        XCTAssertEqual(topicos.label, "Gastos por tópico")
+        XCTAssertTrue((topicos.value as? String ?? "").hasPrefix("Terreno, 38%; Estrutura, 11%; Cerâmica, 9%; Mão de obra, 8%"),
+                      "\(topicos.value ?? "")")
+        // O VoiceOver lê só o bloco. O XCUITest mostra os textos de dentro como filhos dele, como os do `indicadorTotal`
+        // (.combine) e o dos afazeres (.ignore); com o .contain de antes, o bloco não tinha rótulo nem valor.
+        XCTAssertTrue(topicos.staticTexts["e mais 10 tópicos"].exists, "a legenda dentro do bloco")
+        XCTAssertFalse(app.buttons["gastosPorTopico"].exists, "o bloco não é botão")
+        XCTAssertGreaterThan(app.elemento("lancamentos").frame.minY, bloco.maxY, "os lançamentos depois")
+    }
+
+    /// O "<1%" falado como "menos de 1%" no bloco: a Casa Granja Viana tem o Outros (R$ 950,00) e o Extras (R$ 180,00) abaixo
+    /// de 1% da obra. Na Casa Alphaville, a Pintura (0,8%) fica dentro do "Outros · 8 tópicos".
+    func testGastosPorTopicoFalaMenosDeUmPorcento() {
+        let app = abrirApp(conta: "senha", dados: "analise", abrir: "obra:a6")
+        XCTAssertTrue(app.elemento("tituloDaObra").waitForExistence(timeout: 10))
+        let topicos = app.elemento("gastosPorTopico")
+        app.rolarAte(topicos)
+        XCTAssertTrue(topicos.exists, "o bloco dos gastos por tópico")
+        let valor = topicos.value as? String ?? ""
+        XCTAssertTrue(valor.hasSuffix("Extras, menos de 1%; Outros, menos de 1%") && !valor.contains("<"), valor)
+    }
+
+    /// Sem gastos, somem os gastos por tópico (como as portas do site).
+    func testSemGastosSemGastosPorTopico() {
+        let app = abrirApp(conta: "senha", dados: "exemplo", abrir: "obra:o3")
+        XCTAssertTrue(app.elemento("obraSemGastos").waitForExistence(timeout: 10))
+        XCTAssertFalse(app.elemento("gastosPorTopico").exists)
+        XCTAssertTrue(app.elemento("linhaDosAfazeres").exists)
+    }
+
     /// Com prejuízo (B), o sólido volta a ser o Total gasto, e o lucro negativo fica no bloco da venda.
     func testVendidaComPrejuizoNoTotal() {
         let app = abrirApp(conta: "senha", dados: "prejuizo", abrir: "obra:v3")
```

Em `tests/app-ios.test.cjs`:

```diff
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -542,15 +542,16 @@ test('seta dos blocos da obra: para no AX2 e ocupa os 20 pt do mockup na maior l
   assert.match(aPagar.slice(0, aPagar.indexOf('\n    }\n')), /SetaDoBloco\(\)/, 'o bloco do A pagar usa a seta');
 });
 
-test('linha dos afazeres: a seta é a das linhas do Orçamento e do A pagar, para no AX2 e ocupa 18 pt na maior letra', () => {
-  // Sem o teto, a seta sai com ~27 × 46 pt na AX5, num quadro de 22, contra os 17 × 29 do Orçamento e do A pagar. E nenhum
-  // teste de tela vê o símbolo, que fica fora da árvore de acessibilidade (accessibilityHidden) e do laudo (foraDoLaudo).
+test('bloco dos afazeres: a seta é a dos blocos do Orçamento e do A pagar', () => {
+  // A mesma seta dos blocos tocáveis da obra (a SetaDoBloco, com o teto no AX2 e os 20 pt do mockup na letra máxima). Sem o
+  // teto, ela sai com ~27 × 46 pt na AX5, mais larga que o quadro; nenhum teste de tela vê o símbolo, fora da árvore de
+  // acessibilidade e do laudo.
   const t = ler('app-ios/Custta/Telas/AfazeresView.swift');
   const inicio = t.indexOf('struct LinhaDosAfazeresView');
   assert.ok(inicio >= 0, 'a LinhaDosAfazeresView');
   const linha = t.slice(inicio, t.indexOf('\n}\n', inicio));
-  assert.match(linha, /Image\(systemName: "chevron\.right"\)\n\s*\.font\(\.body\.weight\(\.semibold\)\)\n\s*\.foregroundStyle\(.*\)\n(?:\s*\/\/.*\n)*\s*\.dynamicTypeSize\(\.\.\.DynamicTypeSize\.accessibility2\)\n\s*\.frame\(width: grande \? 18 : 14\)\n/,
-    'a seta para no AX2 e ocupa 18 pt na letra de acessibilidade');
+  assert.match(linha, /SetaDoBloco\(\)/, 'a seta dos blocos');
+  assert.doesNotMatch(linha, /chevron\.right/, 'nenhuma outra seta');
 });
 
 test('linhas da tela Orçamento: a que abre é o botão inteiro, com o quadro e o contentShape no rótulo, e a seta é a do Orçamento', () => {
```

- [ ] **Step 2: Ver falhar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | grep -v appintents | tail -1
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/ObraUITests/testAfazeresEGastosPorTopicoEmBlocos -only-testing:CusttaUITests/ObraUITests/testGastosPorTopicoFalaMenosDeUmPorcento -only-testing:CusttaUITests/ObraUITests/testSemGastosSemGastosPorTopico 2>&1 | grep -E "error: -\[|Executed [0-9]+ test" | sed 's/^.*\] : //' | sed -n '1p;$p'
```
Expected: compila, e o teste da grade e o do "menos de 1%" reprovam logo depois de rolar, porque o bloco não existe (o da obra sem gastos já passa):
```
** TEST BUILD SUCCEEDED **
XCTAssertTrue failed - o bloco dos gastos por tópico
	 Executed 3 tests, with 4 failures (0 unexpected) in 72.307 (72.311) seconds
```

- [ ] **Step 3: Implementar**

O bloco "Gastos por tópico" lê `gastoPorTopico(obra)` a cada desenho da obra; ele soma só o bruto, sem corrigir gasto a gasto (Tarefa 25, achado 6 da primeira parte). A forma mono do cabeçalho do mês e do "A vencer" vem do mesmo `linhaMono` da linha, para as folhas, que usam o `CabecalhoDoMes` (ListaDaOrigem.swift:72), ficarem como estão. O `.id("lancamentos")` vem antes do recuo de 6 pt: a lupa rola até a pílula (`scrollTo("lancamentos", anchor: .top)`), como na etapa 3, e não até os 6 pt de cima dela.

Em `app-ios/Custta/Identidade/BarraEmpilhada.swift`:

```diff
--- a/app-ios/Custta/Identidade/BarraEmpilhada.swift
+++ b/app-ios/Custta/Identidade/BarraEmpilhada.swift
@@ -75,10 +75,7 @@ struct BarraDeTopicos: View {
                 .placa(forte: true)
                 .accessibilityElement(children: .ignore)
                 .accessibilityLabel("Gastos por tópico")
-                .accessibilityValue(pedacos.map { pedaco in
-                    // O "<1%" falado como "menos de 1%" (o porcentoFalado do núcleo), como no rótulo do mockup.
-                    "\(nomeDoPedaco(pedaco, topicos: topicos)), \(porcentoFalado(porcentoDoTopico(pedaco.bruto, total: total)))"
-                }.joined(separator: "; "))
+                .accessibilityValue(faladoDaBarra(pedacos, topicos: topicos))
                 .accessibilityAddTraits(.isImage)
                 .accessibilityIdentifier("barraDeTopicos")
                 .padding(.top, 2)
@@ -105,6 +102,16 @@ struct BarraDeTopicos: View {
     }
 }
 
+/// O que o VoiceOver diz da barra: cada pedaço com o nome e o % da obra, separados por ponto e vírgula, com o "<1%" falado
+/// como "menos de 1%" (o `porcentoFalado` do núcleo), como no rótulo do mockup. Serve à barra e ao bloco "Gastos por
+/// tópico" da obra, que é um elemento só.
+func faladoDaBarra(_ pedacos: [PedacoDoAnel], topicos: [String: Topico]) -> String {
+    let total = pedacos.reduce(0) { $0 + $1.bruto }
+    return pedacos.map { pedaco in
+        "\(nomeDoPedaco(pedaco, topicos: topicos)), \(porcentoFalado(porcentoDoTopico(pedaco.bruto, total: total)))"
+    }.joined(separator: "; ")
+}
+
 /// A hachura a 45° ("/") da identidade nova, com o traço e o passo medidos de través, como o `repeating-linear-gradient(-45deg)`
 /// do mockup: 2 pt a cada 6 no excesso do orçamento e na zona "acima do banco"; 1,5 a cada 4 nas parcelas a vencer do gasto
 /// por mês (parte1.css:187 e :300). Uma forma presa ao retângulo: quem usa a preenche na cor e a recorta pela marca.
```

Em `app-ios/Custta/Telas/AfazeresView.swift`:

```diff
--- a/app-ios/Custta/Telas/AfazeresView.swift
+++ b/app-ios/Custta/Telas/AfazeresView.swift
@@ -18,38 +18,24 @@ struct LinhaDosAfazeresView: View {
     @Environment(\.dynamicTypeSize) private var tamanho
 
     var body: some View {
-        let grande = tamanho.isAccessibilitySize
-        HStack(spacing: 11) {
-            if !grande {
-                Image(decorative: "Icones/check")
-                    .resizable().frame(width: 20, height: 20)
-                    .foregroundStyle(paleta.cor(.marca))
-                    .frame(width: 38, height: 38)
-                    .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 11))
-                    .frame(maxHeight: .infinity, alignment: .top)
-            }
+        // Na identidade nova (etapa 4; mockup, .afz): um bloco de vidro, sem o ícone, com "Afazeres" em body semibold e a seta
+        // dos blocos tocáveis, 12 pt depois do texto (o gap do .afz; nos blocos do alto, 10, o do .k-linha).
+        HStack(spacing: 12) {
             VStack(alignment: .leading, spacing: 3) {
                 ViewThatFits(in: .horizontal) {
-                    HStack(alignment: .firstTextBaseline) { titulo; Spacer(minLength: 10); etiqueta }
+                    HStack(alignment: .firstTextBaseline, spacing: 8) { titulo; etiqueta; Spacer(minLength: 0) }
                     VStack(alignment: .leading, spacing: 4) { titulo; etiqueta }
                 }
                 PrimeiroPendente(texto: textoDeBaixo, cortado: pendente)
             }
             .frame(maxWidth: .infinity, alignment: .leading)
-            Image(systemName: "chevron.right")
-                .font(.body.weight(.semibold))
-                .foregroundStyle(paleta.cor(vidro.secundario))
-                // A seta das linhas do Orçamento e do A pagar: para no AX2 e ocupa 18 pt na maior letra (sem o teto, ~27 × 46 pt
-                // na AX5, mais larga que o quadro).
-                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
-                .frame(width: grande ? 18 : 14)
-                .accessibilityHidden(true)
-                .foraDoLaudo()
+            SetaDoBloco()
         }
-        .padding(EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 14))
+        .padding(.vertical, Grade.recuoVertical(tamanho))
+        .padding(.horizontal, Grade.recuo)
         .frame(maxWidth: .infinity, alignment: .leading)
         .contentShape(.rect)
-        .superficie(.conteudo, em: .rect(cornerRadius: 24))
+        .superficie(.conteudo, em: .rect(cornerRadius: Grade.raioDoBloco(tamanho)))
         .accessibilityElement(children: .ignore)
         .accessibilityLabel("Afazeres")
         .accessibilityValue(falado)
@@ -58,7 +44,7 @@ struct LinhaDosAfazeresView: View {
     }
 
     private var titulo: some View {
-        Text("Afazeres").font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
+        Text("Afazeres").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
             .fixedSize(horizontal: false, vertical: true)
     }
 
```

Em `app-ios/Custta/Telas/ObraView.swift`:

```diff
--- a/app-ios/Custta/Telas/ObraView.swift
+++ b/app-ios/Custta/Telas/ObraView.swift
@@ -92,17 +92,36 @@ struct ObraView: View {
                                     definirOrcamento: pecasOrcamento(obra).definir ? { folhas.aberta = .orcamento(obraId: obra.id) } : nil) {
                         agir($0, obra: obra)
                     }
-                    // Os afazeres, 12 abaixo das ações e 24 acima dos lançamentos (mockup da etapa 3), em todas as fases.
+                    // Os afazeres, 12 abaixo das ações, em todas as fases.
                     NavigationLink(value: RotaDeObras.afazeres(obra.id)) {
                         LinhaDosAfazeresView(linha: linhaDosAfazeres(obra.afazeres))
                     }
                     .buttonStyle(.plain)
-                    .padding(.bottom, 14)
+                    // Os gastos por tópico, só com gastos: a barra empilhada no lugar do mini-anel (pedida em 29/10), sem toque
+                    // e sem "Gráficos ›" até os Gráficos chegarem (PR 2b).
+                    if !obra.gastos.isEmpty {
+                        let pedacos = pedacosDoAnel(gastoPorTopico(obra))
+                        // Um elemento só para o VoiceOver, como os outros blocos: o título e os pedaços com o %, sem a
+                        // legenda, que repetiria os maiores. Com o .contain, o título vinha duas vezes (no texto e na barra),
+                        // e esconder um filho dentro dele não o tira da árvore.
+                        BlocoDeVidro {
+                            Text("Gastos por tópico").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
+                                .padding(.bottom, 8)
+                            BarraDeTopicos(pedacos: pedacos, topicos: topicos)
+                        }
+                        .accessibilityElement(children: .ignore)
+                        .accessibilityLabel("Gastos por tópico")
+                        .accessibilityValue(faladoDaBarra(pedacos, topicos: topicos))
+                        .accessibilityIdentifier("gastosPorTopico")
+                    }
+                    // 18 pt acima dos lançamentos (mockup, .lan-cab). O id vem antes do recuo: a lupa rola até a pílula, e não
+                    // até os 6 pt de cima dela.
                     CabecalhoDosLancamentos(contador: contadorLancamentos(total: obra.gastos.count, achados: achados.count, filtro: busca.filtro),
                                             busca: busca, meses: mesesDoFiltro(obra.gastos, escolhido: busca.mes),
                                             comBotoes: !obra.gastos.isEmpty || filtrando || busca.aberta, foco: $foco,
                                             abrir: { abrirBusca(leitor) }, fechar: fecharBusca)
                         .id("lancamentos")
+                        .padding(.top, 6)
                     if busca.aberta {
                         CampoDaBusca(texto: $busca.texto, foco: $buscaEmFoco, fechar: fecharBusca)
                     }
@@ -130,6 +149,8 @@ struct ObraView: View {
                     }
                 }
                 .padding(.horizontal, Grade.externa)
+                // A linha do gasto na forma mono da identidade nova (as folhas ficam com a da etapa 3).
+                .environment(\.linhaMono, true)
                 // O fim da lista fica à vista acima da cápsula de abas, como no mockup: 132 pt da borda de baixo (a cápsula, de
                 // 62 a 22 da borda, e 48 de folga), menos os 34 do indicador de início, que a rolagem já desconta.
                 .padding(.bottom, 98)
@@ -461,7 +482,7 @@ struct CartaoDoAVencer: View {
 
     @ViewBuilder private func linhas(_ mes: MesDeGastos) -> some View {
         ForEach(Array(mes.gastos.enumerated()), id: \.element.id) { i, gasto in
-            if i > 0 { LinhaFina().padding(.leading, 67) }
+            if i > 0 { SeparadorDaLista() }
             LinhaDaLista(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos), lista: lista)
         }
     }
@@ -478,10 +499,20 @@ struct CartaoDoMes: View {
         CartaoDaLista {
             CabecalhoDoMes(mes: mes)
             ForEach(Array(mes.gastos.enumerated()), id: \.element.id) { i, gasto in
-                if i > 0 { LinhaFina().padding(.leading, 67) }
+                if i > 0 { SeparadorDaLista() }
                 LinhaDaLista(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos), lista: lista)
             }
             Color.clear.frame(height: 6)
         }
     }
 }
+
+/// A linha fina entre dois gastos de um cartão: depois do ícone, na linha da etapa 3; na mono, nos 18 pt do recuo dos dois
+/// lados, como na vitrine das peças.
+struct SeparadorDaLista: View {
+    @Environment(\.linhaMono) private var mono
+
+    var body: some View {
+        if mono { LinhaFina().padding(.horizontal, Grade.recuo) } else { LinhaFina().padding(.leading, 67) }
+    }
+}
```

Em `app-ios/Custta/Telas/PecasDaObra.swift`:

```diff
--- a/app-ios/Custta/Telas/PecasDaObra.swift
+++ b/app-ios/Custta/Telas/PecasDaObra.swift
@@ -97,13 +97,22 @@ struct CabecalhoDoMes: View {
     @Environment(\.paleta) private var paleta
     @Environment(\.vidro) private var vidro
     @Environment(\.dentroDaFolha) private var naFolha
+    /// Na lista da obra da etapa 4 (mockup, .mes-cab): o nome em subheadline e o total no número mono, na cor do texto.
+    @Environment(\.linhaMono) private var mono
 
     var body: some View {
         ViewThatFits(in: .horizontal) {
-            HStack { titulo; Spacer(minLength: 8); total }
+            // Na linha mono, o nome e o total na mesma linha de base, e o nome ocupa o que sobra pelo frame, e não por um
+            // Spacer: com ele, a linha passava 1/3 pt da largura em alguns meses, como o "A vencer". Nas folhas, centrados e
+            // com o Spacer, como na etapa 3.
+            if mono {
+                HStack(alignment: .firstTextBaseline, spacing: 8) { titulo.frame(maxWidth: .infinity, alignment: .leading); total }
+            } else {
+                HStack { titulo; Spacer(minLength: 8); total }
+            }
             VStack(alignment: .leading, spacing: 2) { titulo; total }
         }
-        .font(.footnote.weight(.semibold))
+        .font(mono ? .subheadline.weight(.semibold) : .footnote.weight(.semibold))
         .foregroundStyle(paleta.cor(secundario))
         // Na folha, o .f-grupo .mes-cab do mockup: 16 dos lados, como as linhas da folha, e 2 embaixo.
         .padding(naFolha ? EdgeInsets(top: 12, leading: 16, bottom: 2, trailing: 16) : EdgeInsets(top: 12, leading: 18, bottom: 6, trailing: 18))
@@ -115,8 +124,9 @@ struct CabecalhoDoMes: View {
     /// O secundário do vidro; na folha, o da folha.
     private var secundario: Token { naFolha ? .secundarioTransparente : vidro.secundario }
     private var titulo: some View { Text(mes.titulo) }
-    private var total: some View {
-        ValorEmDinheiro(texto: moeda(mes.total), fonte: .footnote.weight(.semibold), cor: secundario)
+    @ViewBuilder private var total: some View {
+        if mono { ValorEmDinheiro(moeda(mes.total), mono: .miudo) }
+        else { ValorEmDinheiro(texto: moeda(mes.total), fonte: .footnote.weight(.semibold), cor: secundario) }
     }
 }
 
@@ -127,11 +137,13 @@ struct LinhaDoAVencer: View {
     @Environment(\.paleta) private var paleta
     @Environment(\.vidro) private var vidro
     @Environment(\.dynamicTypeSize) private var tamanho
+    /// Na lista da obra da etapa 4 (mockup): sem o ícone, e o total no número mono.
+    @Environment(\.linhaMono) private var mono
     @ScaledMetric(relativeTo: .body) private var icone: CGFloat = 38
 
     var body: some View {
         HStack(alignment: .top, spacing: 12) {
-            if !tamanho.isAccessibilitySize {
+            if !tamanho.isAccessibilitySize && !mono {
                 Image(decorative: "Icones/calendario")
                     .resizable().frame(width: icone * 0.55, height: icone * 0.55)
                     .foregroundStyle(paleta.cor(.alertaEtiqueta))
@@ -140,14 +152,15 @@ struct LinhaDoAVencer: View {
             }
             VStack(alignment: .leading, spacing: 2) {
                 ViewThatFits(in: .horizontal) {
-                    HStack(alignment: .firstTextBaseline) {
-                        Text("A vencer").font(.body.weight(.semibold))
-                        Spacer(minLength: 8)
-                        ValorEmDinheiro(texto: moeda(grupo.total), fonte: .body.weight(.semibold))
+                    // O título ocupa o que sobra pelo frame, e não um Spacer ao lado: com o Negrito, o Spacer arredondava
+                    // para cima, e a linha passava 1/3 pt da largura, como o cabeçalho dos blocos (PR 1b).
+                    HStack(alignment: .firstTextBaseline, spacing: 8) {
+                        Text("A vencer").font(.body.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading)
+                        total
                     }
                     VStack(alignment: .leading, spacing: 2) {
                         Text("A vencer").font(.body.weight(.semibold))
-                        ValorEmDinheiro(texto: moeda(grupo.total), fonte: .body.weight(.semibold))
+                        total
                     }
                 }
                 .foregroundStyle(paleta.cor(.texto))
@@ -166,6 +179,11 @@ struct LinhaDoAVencer: View {
         .padding(EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 16))
         .contentShape(.rect)
     }
+
+    @ViewBuilder private var total: some View {
+        if mono { ValorEmDinheiro(moeda(grupo.total), mono: .miudo) }
+        else { ValorEmDinheiro(texto: moeda(grupo.total), fonte: .body.weight(.semibold)) }
+    }
 }
 
 /// A linha de um gasto: ícone do tópico (sólido), título e valor, e embaixo o tópico, o pagamento e a data. O valor vem
```

- [ ] **Step 4: Ver passar**

Run:
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaTests/ListaDaObraTests -only-testing:CusttaTests/BarraEmpilhadaTests 2>&1 | grep -E "Test run with"
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/ObraUITests -only-testing:CusttaUITests/AfazeresUITests -only-testing:CusttaUITests/GastoUITests -only-testing:CusttaUITests/BuscaUITests 2>&1 | grep -E "error:|Executed [0-9]+ test" | tail -1
npm run test:unit 2>&1 | grep -E "ℹ (pass|fail)"
```
Expected: `** TEST BUILD SUCCEEDED **`, sem aviso; `✔ Test run with 5 tests in 2 suites passed`; `Executed 63 tests, with 0 failures (0 unexpected)` (os 13 da `ObraUITests`, os 15 da `AfazeresUITests`, os 24 da `GastoUITests` e os 11 da `BuscaUITests`, que dependem da altura da obra: o destaque da linha nova, a rolagem até o gasto salvo e até o "A vencer", o arrastar e a lupa que rola até os lançamentos; ~27 min no 18 Pro. Rodado em duas vezes, com a mesma produção: as quatro classes, com os 50 das três últimas sem falha, e a `ObraUITests` de novo depois de o teste da grade passar a ler a legenda dentro do bloco, `Executed 13 tests, with 0 failures (0 unexpected)`); `ℹ pass 411`, `ℹ fail 0`. Com o `Spacer` de antes no "A vencer", a varredura reprova só com o Negrito, nas letras pequena e média, nas três larguras: `✘ Test run with 1 test in 1 suite failed after 0.246 seconds with 6 issues.`, com "A vencer, medium, negrito true, em 408.0: 408.3333333333333". Com o `Spacer` de antes no cabeçalho do mês mono, a varredura de todos os meses reprova em três (os meses mudam com o dia; em 30/10/2026): `✘ Test run with 1 test in 1 suite failed after 0.622 seconds with 3 issues.`, com "Junho de 2026, xSmall, negrito false, em 408.0: 408.3333333333333", "Maio de 2026, xSmall, negrito false, em 408.0: 408.3333333333333" e "Abril de 2026, xSmall, negrito true, em 408.0: 408.3333333333333" (o primeiro mês, o único que a varredura media antes, passava). Com o bloco em `.contain`, o teste da grade cai no rótulo (`XCTAssertEqual failed: ("") is not equal to ("Gastos por tópico")`) e no valor, e o do "menos de 1%", no valor vazio.

- [ ] **Step 5: Conferir com o mockup**

Run: o do Step 5 da Tarefa 30, com `-custta.rolagem 750` e, depois, `-custta.rolagem 1000`.
Expected: o meio e o fim como o `parte1-obra-meio.png` e o `parte1-obra-fim.png`: "Marcar como pronta"; o bloco dos afazeres ("Afazeres", "3 pendentes" e o primeiro pendente, com a seta); "Gastos por tópico" com a barra de 7 pedaços na placa forte e a legenda "Terreno 38%", "Estrutura 11%", "Cerâmica 9%", "Mão de obra 8%" e "e mais 10 tópicos"; a pílula "Lançamentos 46" com a lupa e o mês; o "A vencer" sem o ícone, com R$ 65.500,00 no mono; e os meses com o total no mono e as linhas mono, com a linha fina nos 18 pt. Diferenças que ficam: sem o "Gráficos ›" e sem as portas (escondidos até os Gráficos), e a pílula "Lançamentos" abraça o texto, como na etapa 3 (no mockup ela vai até a lupa).

- [ ] **Step 6: Conferir o laudo das cenas roladas**

Run (no Pro Max, como na Tarefa 32, e de novo no simulador de sempre, o 18 Pro, a largura da CI; os 12 testes com cena de rolagem fixa):
```bash
T=(); for t in EmAjustes DaObra DaObraRolando DaFolhaDoGasto DaParte3 DaObraVendida DaParte3NaMaiorLetra DoOrcamento DoOrcamentoNaMaiorLetra DasFolhasDeOrigem DasFolhasDeOrigemNaMaiorLetra DaBuscaEDosAfazeres; do T+=(-only-testing:CusttaUITests/LeituraNoVidroUITests/testLeitura$t); done
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never "${T[@]}" 2>&1 | grep -E "^leitura \| (obra, lista|obra com Aumentar|obra rolando|obra, linha|obra vendida com|obra pronta, ações da fase, na maior|obra com orçamento por tópico, na maior|busca, nada|busca, mês sem)|Executed [0-9]+ test" | tail -22
```
Expected, no Pro Max (as cenas que mudaram de rolagem):
```
leitura | busca, nada achado, escuro | 18 palavras, 0 abaixo | pior nota 5.04
leitura | busca, mês sem gasto, escuro | 18 palavras, 0 abaixo | pior nota 5.45
leitura | busca, nada achado, claro | 18 palavras, 0 abaixo | pior nota 5.91
leitura | busca, mês sem gasto, claro | 18 palavras, 0 abaixo | pior nota 5.25
leitura | obra, lista, escuro | 53 palavras, 0 abaixo | pior nota 5.87
leitura | obra, lista, claro | 53 palavras, 0 abaixo | pior nota 6.46
leitura | obra com Aumentar contraste | 53 palavras, 0 abaixo | pior nota 5.34
leitura | obra vendida com lucro, escuro | 19 palavras, 0 abaixo | pior nota 5.78
leitura | obra vendida com prejuízo, escuro | 22 palavras, 0 abaixo | pior nota 5.19
leitura | obra vendida com lucro, claro | 19 palavras, 0 abaixo | pior nota 4.56
leitura | obra vendida com prejuízo, claro | 22 palavras, 0 abaixo | pior nota 4.56
leitura | obra com orçamento por tópico, na maior letra | 35 palavras, 0 abaixo | pior nota 5.19
leitura | obra, linha aberta, escuro | 51 palavras, 0 abaixo | pior nota 5.51
leitura | obra, linha aberta, claro | 51 palavras, 0 abaixo | pior nota 5.50
leitura | obra rolando 612, escuro | 26 palavras, 0 abaixo | pior nota 5.78
leitura | obra rolando 883, escuro | 43 palavras, 0 abaixo | pior nota 4.92
leitura | obra rolando 1247, escuro | 54 palavras, 0 abaixo | pior nota 5.49
leitura | obra rolando 612, escuro, Aumentar contraste | 26 palavras, 0 abaixo | pior nota 5.90
leitura | obra rolando 883, escuro, Aumentar contraste | 43 palavras, 0 abaixo | pior nota 5.91
leitura | obra rolando 1247, escuro, Aumentar contraste | 54 palavras, 0 abaixo | pior nota 6.07
leitura | obra pronta, ações da fase, na maior letra | 16 palavras, 0 abaixo | pior nota 6.40
	 Executed 12 tests, with 0 failures (0 unexpected) in 2608.705 (2608.713) seconds
```
Rodado em três vezes nos dois iPhones, com a mesma produção: os 12 testes (no 18 Pro, `Executed 12 tests, with 1 failure (0 unexpected) in 2593.933 (2593.943) seconds`, pela g027, abaixo), e de novo o `testLeituraDaFolhaDoGasto` depois da troca da linha aberta para a g026 (`Executed 1 test, with 0 failures (0 unexpected) in 348.313 (348.318) seconds` no 18 Pro, 355.030 no Pro Max) e o `testLeituraDaObraRolando` com o `testLeituraDaParte3NaMaiorLetra` depois da pronta a 1977 (`Executed 2 tests, with 0 failures (0 unexpected) in 268.480 (268.484) seconds` no 18 Pro, 271.419 no Pro Max, ainda com a 1778 e a 1956 na obra rolando, que saíram depois, pelo dia); na primeira vez, a g027 reprovava no 18 Pro (`obra, linha aberta, claro: texto #2B463B em 16,369 (4×11 pt) fica em 2.83:1 (pior pixel 2.76:1)`). Nenhuma palavra começa na borda (y = 140) nas tabelas das cenas que mudaram, nos dois iPhones. Com a rolagem de antes da "busca, nada achado" (596), o laudo da busca passa nas notas e cai pelo `assunto`, nos dois temas e nos dois prints de cada cena:
```
XCTAssertTrue failed - busca, nada achado, escuro: buscaNadaEncontrado fora da vista ((88.5, 865.6666666666665, 263.0, 20.333333333333144); a cena mede de 70 a 816 pt)
XCTAssertTrue failed - busca, nada achado, escuro: limparFiltro fora da vista ((147.66666666666666, 949.9999999999997, 144.66666666666666, 44.0); a cena mede de 70 a 816 pt)
	 Executed 1 test, with 8 failures (0 unexpected) in 480.805 (480.807) seconds
```
(No Pro Max; a cena em si fica em `19 palavras, 0 abaixo | pior nota 5.87`, medindo os blocos do alto.)

- [ ] **Step 7: Commit**

```bash
git add app-ios/Custta/Identidade/BarraEmpilhada.swift app-ios/Custta/Telas/AfazeresView.swift app-ios/Custta/Telas/ObraView.swift app-ios/Custta/Telas/PecasDaObra.swift app-ios/CusttaTests/ListaDaObraTests.swift app-ios/CusttaUITests/EstadosUITests.swift app-ios/CusttaUITests/LeituraNoVidroUITests.swift app-ios/CusttaUITests/ObraUITests.swift tests/app-ios.test.cjs
git commit -m "feat: afazeres, gastos por tópico e lançamentos da obra na grade nova" -m "Embaixo das ações, a obra passa à identidade nova do mockup aprovado: os afazeres num bloco de vidro, sem o ícone e com a seta dos blocos tocáveis; o bloco \"Gastos por tópico\", só com gastos, com a barra empilhada no lugar do mini-anel e a legenda dos 4 maiores; e os lançamentos na linha mono, com o total do mês e o do \"A vencer\" no número mono e a linha fina nos 18 pt do recuo." -m "O bloco dos gastos por tópico é um elemento só para o VoiceOver, como os outros blocos: o título e cada pedaço com o %, sem a legenda, que repetiria os maiores. Com o Negrito, o \"A vencer\" e o cabeçalho do mês na linha mono não passam mais da largura: o título ocupa o que sobra pelo frame, e não um Spacer." -m "Com a obra em blocos, a lista desce, e as rolagens fixas do laudo da obra são refeitas, com a borda de cima num vão nos dois iPhones. Cada cena com rolagem fixa ganha o seu assunto, conferido à vista antes do print: o laudo passava com a rolagem medindo outra coisa." -m "A barra fica sem toque e sem o \"Gráficos ›\" até os Gráficos chegarem, e as folhas continuam com a linha da etapa 3."
```

### Task 32: Halo do título da obra calibrado pelo laudo, e as cenas da obra em blocos

O halo atrás do título mono da obra, que o PR 1a não mudou (nota do PR 1a; achado 8 do PR 1b), se calibra agora, com o título na obra, pela regra do app: o menor passo que fecha 4,5:1 no Pro Max (decisão do Giovani em 10/10, Aurora.swift:186-188), partindo dos 38% do mockup (62% na letra máxima; spec, "Decisões tomadas por recomendação", halo do título). Hoje o `TituloMono` usa o halo do nome da obra da etapa 2 (`HaloDoTitulo.naObra`, 30% no escuro, e `naObraNoClaro`, 10% no claro), o mesmo do `TituloDaObra` da tela Orçamento, que não muda. Medido no laudo do Pro Max (`testLeituraDaObra`, as cenas "obra, topo, escuro" e "obra na maior letra"), o pior ponto de "Alphaville" fica em 3,92:1 sem halo (reprova), 4,61 com 10% (pior pixel 4,50), 5,41 com 20% e 5,94 com 30%; na maior letra, 4,20, 4,82, 5,49 e 6,19. O menor passo que fecha é o 10%, mas sem folga: o iOS 26 da CI mediu o nome da obra 0,4 abaixo do Pro Max (o claro sem halo, 4,40:1 no iPhone 17 Pro da CI e 4,80 no Pro Max; Aurora.swift:193-195), e o laudo é portão lá. Fica 20% (`HaloDoTitulo.naObraMono`; decidido pelo Giovani em 30/10, Decisões), em todo tamanho de letra (o 62% da letra máxima do mockup não é preciso: 5,49 com 20%); o claro continua com os 10% do nome da obra (sem halo, reprovava na CI), e lá o título fica em 7,14. Junto, o laudo ganha as cenas da obra em blocos que as de antes não abrem (spec, "Testes e validação", item 5): o bloco "Gastos por tópico" (a legenda da barra), a obra sem gastos (o sólido com o convite), a sem orçamento (as ações com "Definir orçamento") e o sólido do lucro na vendida, nos dois temas, e o sólido do lucro na maior letra. As duas roladas têm a borda de cima num vão, igual nos dois iPhones, e o `assunto` da Tarefa 31: a dos gastos por tópico a 804 pt, entre a ação "Marcar como pronta" e os afazeres (a 750 cortava a ação pela borda), com o `gastosPorTopico`; a da sem orçamento a 350, entre o Corrigido e o A pagar (a 400 deixava a borda 1 pt acima do valor do A pagar), com o `definirOrcamento`.

**Files:**
- Modify: `app-ios/Custta/Identidade/Aurora.swift`
- Modify: `app-ios/Custta/Identidade/Titulos.swift`
- Test (alterar): `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`

**Interfaces:**
- Consumes: `HaloDoTitulo(grande:opacidade:noClaro:)` e `naObraNoClaro` (Aurora.swift); `TituloMono` (PR 1b); os identificadores `gastosPorTopico`, `obraSemGastos`, `definirOrcamento` e `indicadorLucro` (Tarefas 30 e 31); as variantes dos falsos `vitrine`, `exemplo` e `semOrcamento`.
- Produces: `HaloDoTitulo.naObraMono` (0,20); `LeituraNoVidroUITests.testLeituraDaObraEmBlocos()`.

- [ ] **Step 1: Escrever as cenas**

As cenas novas, no molde das outras do laudo (dois prints, um com o texto apagado, e o portão de 4,5:1 em cada palavra).

Em `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -392,6 +392,34 @@ extension LeituraNoVidroUITests {
         cobrar(cenas)
     }
 
+    /// A obra em blocos da etapa 4 (PR 1c), nos estados do mockup que as cenas de antes não abrem: o bloco "Gastos por
+    /// tópico" (a legenda da barra empilhada), a obra sem gastos (o sólido com o convite), a sem orçamento (o "Definir
+    /// orçamento" nas ações) e o sólido do lucro na vendida, nos dois temas; e o sólido do lucro na maior letra. As roladas
+    /// com a borda num vão, igual nos dois iPhones: a dos gastos por tópico entre a ação "Marcar como pronta" e os afazeres (a
+    /// 750 cortava a ação), e a da sem orçamento entre o Corrigido e o A pagar (a 400, 1 pt acima do valor do A pagar).
+    @MainActor func testLeituraDaObraEmBlocos() {
+        var cenas: [Cena] = []
+        for tema in temas {
+            let combo = ["-custta.tema", tema] + piorMomento
+            cenas += [
+                Cena(nome: "obra, gastos por tópico, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "804"],
+                     espera: "gastosPorTopico", escopo: "tudo", dados: "vitrine", abrir: "obra:v1", rolada: true,
+                     assunto: ["gastosPorTopico"]),
+                Cena(nome: "obra sem gastos, \(tema)", conta: "senha", argumentos: combo, espera: "obraSemGastos", escopo: "tudo",
+                     abrir: "obra:o3"),
+                Cena(nome: "obra sem orçamento, ações, \(tema)", conta: "senha", argumentos: combo + ["-custta.rolagem", "350"],
+                     espera: "definirOrcamento", escopo: "tudo", dados: "semOrcamento", abrir: "obra:v1", rolada: true,
+                     assunto: ["definirOrcamento"]),
+                Cena(nome: "obra vendida, sólido do lucro, \(tema)", conta: "senha", argumentos: combo, espera: "indicadorLucro",
+                     escopo: "tudo", dados: "vitrine", abrir: "obra:v3"),
+            ]
+        }
+        let escuro = ["-custta.tema", "escuro"] + piorMomento
+        cenas.append(Cena(nome: "obra vendida, sólido do lucro, na maior letra", conta: "senha", argumentos: escuro + maiorLetra,
+                          espera: "indicadorLucro", escopo: "tudo", dados: "vitrine", abrir: "obra:v3"))
+        cobrar(cenas)
+    }
+
     /// A lista da obra rolando, no escuro (onde a dose de vidro decide), sem e com Aumentar contraste: o pior
     /// ponto de um cabeçalho de mês ou de uma linha de baixo pode estar fora do quadro de 640 pt. No Mac, três rolagens; na
     /// CI, duas.
```

- [ ] **Step 2: Implementar**

O valor novo é só do título mono: o `naObra` continua no `TituloDaObra` da tela Orçamento. O `naObraMono` entra com os 20% que o Step 3 mede contra os outros passos.

Em `app-ios/Custta/Identidade/Aurora.swift`:

```diff
--- a/app-ios/Custta/Identidade/Aurora.swift
+++ b/app-ios/Custta/Identidade/Aurora.swift
@@ -193,6 +193,11 @@ struct HaloDoTitulo: View {
     /// No claro, atrás do nome da obra: na tela de 402 pt a aurora azul cai mais escura sob a primeira palavra (sem halo,
     /// 4,40:1 no iPhone 17 Pro da CI, 4,80:1 no Pro Max).
     nonisolated static let naObraNoClaro = 0.10
+    /// Atrás do título mono da obra (etapa 4, PR 1c), no escuro: o mockup partia de 38% (62% na letra de acessibilidade). No
+    /// laudo do Pro Max, "Alphaville" fica em 3,92:1 sem halo, 4,61 com 10% (pior pixel 4,50), 5,41 com 20% e 5,94 com 30%;
+    /// na maior letra, 4,20, 4,82, 5,49 e 6,19. Fica 20%: o 10%, o menor passo que fecha, não deixa folga para o iOS 26 da
+    /// CI, que mediu 0,4 abaixo do Pro Max no nome da obra (naObraNoClaro). No claro, o mesmo 10% do nome da obra.
+    nonisolated static let naObraMono = 0.20
     let grande: Bool
     var opacidade = HaloDoTitulo.naEntrada
     var noClaro = 0.0
```

Em `app-ios/Custta/Identidade/Titulos.swift`:

```diff
--- a/app-ios/Custta/Identidade/Titulos.swift
+++ b/app-ios/Custta/Identidade/Titulos.swift
@@ -5,8 +5,8 @@ import SwiftUI
    fase e "começou em … · N meses" na obra, o nome da obra nas telas da análise). Nenhuma tela os usa ainda. */
 
 /// O título solto: SF Mono 600, 30 pt com o tracking de −0,045 em (44 na letra máxima, crescendo a cada passo), em quantas
-/// linhas precisar (o nome comprido quebra), a 16 pt da borda. Atrás dele, no escuro, o halo do nome da obra de hoje (30%,
-/// e 10% no claro): o do mockup (38%, 62% na letra máxima) se calibra pelo laudo, na obra (PR 1c).
+/// linhas precisar (o nome comprido quebra), a 16 pt da borda. Atrás dele, o halo calibrado pelo laudo da obra (PR 1c): 20%
+/// no escuro, em todo tamanho de letra, e 10% no claro (`HaloDoTitulo.naObraMono`).
 struct TituloMono: View {
     let texto: String
     var identificador = "tituloDaObra"
@@ -22,7 +22,7 @@ struct TituloMono: View {
             .accessibilityAddTraits(.isHeader)
             .accessibilityIdentifier(identificador)    // antes do halo: com ele, o quadro do VoiceOver ia até a borda do halo
             .frame(maxWidth: .infinity, alignment: .leading)
-            .background { HaloDoTitulo(grande: false, opacidade: HaloDoTitulo.naObra, noClaro: HaloDoTitulo.naObraNoClaro) }
+            .background { HaloDoTitulo(grande: false, opacidade: HaloDoTitulo.naObraMono, noClaro: HaloDoTitulo.naObraNoClaro) }
     }
 }
 
```

- [ ] **Step 3: Medir o halo**

Run (no Pro Max: `export CUSTTA_SIMULADOR=<udid do Pro Max>` e o `DESTINO` e o `XB` de novo, como no cabeçalho; trocando o valor do `naObraMono` do Step 2 por 0 (sem halo), 0,10, 0,20 e 0,30, um build para cada, e voltando aos 0,20 no fim; as tabelas saem do xcresult com `xcrun xcresulttool export attachments --path <xcresult> --output-path <pasta> --filter '*.txt'`):
```bash
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaObra -resultBundlePath halo.xcresult 2>&1 | grep -E "Executed [0-9]+ test" | tail -1
```
Expected: sem halo, `Executed 1 test, with 2 failures`, com "Alphaville" em 3,92:1 no topo e 4,20 na maior letra; com 10%, 20% e 30%, `Executed 1 test, with 0 failures`, com "Alphaville" em 4,61, 5,41 e 5,94 no topo e 4,82, 5,49 e 6,19 na maior letra.

- [ ] **Step 4: Ver passar**

Run (o build no simulador de sempre; as cenas no Pro Max, como no Step 3):
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaObra -only-testing:CusttaUITests/LeituraNoVidroUITests/testLeituraDaObraEmBlocos 2>&1 | grep -E "^leitura \||Executed [0-9]+ test" | tail -16
```
Expected: `** TEST BUILD SUCCEEDED **`, sem aviso, e
```
leitura | obra, topo, escuro | 35 palavras, 0 abaixo | pior nota 5.41
leitura | obra, lista, escuro | 53 palavras, 0 abaixo | pior nota 5.87
leitura | obra, topo, claro | 35 palavras, 0 abaixo | pior nota 4.56
leitura | obra, lista, claro | 53 palavras, 0 abaixo | pior nota 6.46
leitura | obra na maior letra | 29 palavras, 0 abaixo | pior nota 5.31
leitura | obra com Aumentar contraste | 53 palavras, 0 abaixo | pior nota 5.34
leitura | obra, gastos por tópico, escuro | 39 palavras, 0 abaixo | pior nota 4.98
leitura | obra sem gastos, escuro | 27 palavras, 0 abaixo | pior nota 5.41
leitura | obra sem orçamento, ações, escuro | 23 palavras, 0 abaixo | pior nota 5.78
leitura | obra vendida, sólido do lucro, escuro | 42 palavras, 0 abaixo | pior nota 5.40
leitura | obra, gastos por tópico, claro | 39 palavras, 0 abaixo | pior nota 5.91
leitura | obra sem gastos, claro | 27 palavras, 0 abaixo | pior nota 5.25
leitura | obra sem orçamento, ações, claro | 23 palavras, 0 abaixo | pior nota 4.56
leitura | obra vendida, sólido do lucro, claro | 42 palavras, 0 abaixo | pior nota 4.56
leitura | obra vendida, sólido do lucro, na maior letra | 36 palavras, 0 abaixo | pior nota 5.23
	 Executed 2 tests, with 0 failures (0 unexpected) in 288.932 (288.938) seconds
```
No 18 Pro, a largura da CI, o `testLeituraDaObraEmBlocos` também passa (`Executed 1 test, with 0 failures (0 unexpected) in 167.197 (167.201) seconds`), sem palavra na borda das duas roladas. Nas cenas de antes da obra, o título fica em 5,41:1 no escuro (era 5,94 com os 30% da etapa 2) e 7,14 no claro; o pior das cenas novas é o texto dos chips verdes no claro (`#0E7A41`: "estimativa", "Vendida", "Vendida em …"), 4,56, o mesmo das cenas de antes e do mockup (4,56 no LEIA-ME).

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Identidade/Aurora.swift app-ios/Custta/Identidade/Titulos.swift app-ios/CusttaUITests/LeituraNoVidroUITests.swift
git commit -m "feat: halo do título da obra calibrado pelo laudo e cenas da obra nova" -m "O título mono da obra ganha o halo próprio no escuro, 20%, medido no laudo do Pro Max a partir dos 38% do mockup: sem halo, \"Alphaville\" fica em 3,92:1; com 10%, o menor passo que fecha, em 4,61, sem folga para o iOS 26 da CI, que mede o nome da obra abaixo do Pro Max; com 20%, em 5,41 (5,49 na maior letra). O claro continua com os 10% do nome da obra, e o título da tela Orçamento não muda." -m "O laudo ganha as cenas da obra em blocos que as de antes não abriam: os gastos por tópico, a obra sem gastos, a sem orçamento e o sólido do lucro na vendida, nos dois temas, e o sólido do lucro na maior letra."
```

### Task 33: Marcas apagadas no laudo e a barra de tópicos a 3:1

O laudo das marcas (spec, "1. Gráficos", "Laudo das marcas"; "Testes e validação", item 5): um modo de Debug apaga só as marcas de gráfico, como o texto apagado apaga o texto (`-custta.textoApagado`, RaizView.swift:29 e Vidro.swift:169-185), e o laudo mede cada marca a 3:1 com o que fica atrás dela, nos vidros Transparente e Fosco. Com `-custta.marcasApagadas YES`, a `RaizView` põe o `marcasApagadas` no environment, e a `BarraEmpilhada` pinta os pedaços com opacidade zero, sem mexer no layout (só no Debug; no Release o valor é a constante `false`, e o environment nem existe). O medidor novo, `LaudoDeContraste.medirMarcas`, segue o `medir` das palavras: os pixels que mudam de um print para o outro, dentro do quadro da barra (`barraDeTopicos`), são a marca; mas cada marca é um grupo de pixels juntos, sem a dilatação de 3 pt das palavras, para o vão de 3 pt entre os pedaços separar as marcas; a cor é a mediana dos pixels que mais mudaram e a nota, o percentil 1 do contraste dela contra o fundo no miolo (o mesmo pixel do print sem marcas e os de 2 px em volta), fora do serrilhado das pontas; longe das marcas (mais de 2 pt), os dois prints têm de ser iguais, ou a cena não é a mesma e o laudo dá erro. O teste novo, `testMarcasDaBarraDeTopicos`, abre a obra da vitrine com a barra à vista (`-custta.rolagem 750`), nos dois temas e nos dois vidros, cobra os 7 pedaços da Casa Alphaville (os 6 maiores e o cinza do "Outros · 8 tópicos") e o portão de 3:1 (`portaoDasMarcas`), e anexa o print anotado e a tabela com o prefixo "marcas", que o comparador do laudo (`scripts/compara-laudo.mjs`, portão de 4,5) não lê. A `BarraApagada` conta como dado (spec): a regra vale para as barras apagadas do gasto por mês quando elas chegarem (PR 2b), que passam a usar o mesmo `marcasApagadas`.

**Files:**
- Modify: `app-ios/Custta/Identidade/BarraEmpilhada.swift`
- Modify: `app-ios/Custta/Telas/RaizView.swift`
- Test (alterar): `app-ios/CusttaUITests/LaudoDeContraste.swift`
- Test (alterar): `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`

**Interfaces:**
- Consumes: `BarraEmpilhada` e `BarraDeTopicos` (PR 1b, identificador `barraDeTopicos`); `LaudoDeContraste.medir`, `Retrato`, `Palavra`, `dilatar`, `limiarDaLetra` e `ruido` (etapa 2, Tarefa 11); `abrirApp(conta:dados:abrir:argumentos:)`; `-custta.rolagem`, `-custta.tema` e `-custta.vidro`.
- Produces: `EnvironmentValues.marcasApagadas` (só Debug) e o argumento `-custta.marcasApagadas`; `LaudoDeContraste.medirMarcas(normal:semMarcas:escala:em:) throws -> [Palavra]`; `LeituraNoVidroUITests.portaoDasMarcas` (3,0) e `testMarcasDaBarraDeTopicos()`; o `anexar(_:_:_:_:portao:tipo:)`. Os PRs 2a e 2b apagam o anel, as linhas e as barras pelo mesmo environment e medem com o mesmo `medirMarcas`.

- [ ] **Step 1: Escrever o medidor e o teste**

O medidor das marcas no `LaudoDeContraste` e o teste das marcas no laudo; o `anexar` ganha o portão e o prefixo do anexo.

Em `app-ios/CusttaUITests/LaudoDeContraste.swift`:

```diff
--- a/app-ios/CusttaUITests/LaudoDeContraste.swift
+++ b/app-ios/CusttaUITests/LaudoDeContraste.swift
@@ -180,6 +180,79 @@ enum LaudoDeContraste {
         return palavras.sorted { ($0.caixa.minY, $0.caixa.minX) < ($1.caixa.minY, $1.caixa.minX) }
     }
 
+    /// Mede as marcas de gráfico (spec da etapa 4, "Laudo das marcas"): os pixels que mudam do print normal para o print
+    /// com as marcas apagadas (`-custta.marcasApagadas`), dentro das regiões dadas (em pontos). Cada marca é um grupo de
+    /// pixels juntos, sem a dilatação das palavras (o vão de 3 pt entre os pedaços da barra separa as marcas); a cor é a
+    /// mediana dos pixels que mais mudaram, e a nota, o percentil 1 do contraste dela contra o fundo no miolo (o mesmo
+    /// pixel do print sem marcas e os de 2 px em volta), fora do serrilhado das pontas. Longe das marcas (mais de 2 pt), os
+    /// dois prints têm de ser iguais.
+    static func medirMarcas(normal: Retrato, semMarcas: Retrato, escala: CGFloat, em regioes: [CGRect]) throws -> [Palavra] {
+        precondition(normal.largura == semMarcas.largura && normal.altura == semMarcas.altura)
+        let w = normal.largura, h = normal.altura
+        let a = normal.rgba, b = semMarcas.rgba
+        var dentro = [Bool](repeating: false, count: w * h)
+        for r in regioes {
+            let x0 = max(0, Int((r.minX * escala).rounded(.down))), y0 = max(0, Int((r.minY * escala).rounded(.down)))
+            let x1 = min(w, Int((r.maxX * escala).rounded(.up))), y1 = min(h, Int((r.maxY * escala).rounded(.up)))
+            for y in y0..<max(y0, y1) { for x in x0..<max(x0, x1) { dentro[y * w + x] = true } }
+        }
+        var diferenca = [UInt8](repeating: 0, count: w * h)
+        var marca = [Bool](repeating: false, count: w * h)
+        for i in 0..<(w * h) where dentro[i] {
+            let k = i * 4
+            let d = max(abs(Int(a[k]) - Int(b[k])), abs(Int(a[k + 1]) - Int(b[k + 1])), abs(Int(a[k + 2]) - Int(b[k + 2])))
+            diferenca[i] = UInt8(d)
+            marca[i] = d > limiarDaLetra
+        }
+        let perto = dilatar(marca, w, h, rx: Int(2 * escala), ry: Int(2 * escala))
+        var mudou = 0
+        for i in 0..<(w * h) where dentro[i] && !perto[i] && Int(diferenca[i]) > ruido { mudou += 1 }
+        if mudou > max(40, w * h / 5000) { throw CenaNaoDeterministica(pixels: mudou) }
+
+        var visto = [Bool](repeating: false, count: w * h)
+        var marcas: [Palavra] = []
+        for inicio in 0..<(w * h) where marca[inicio] && !visto[inicio] {
+            var pilha = [inicio], membros: [Int] = []
+            visto[inicio] = true
+            while let i = pilha.popLast() {
+                membros.append(i)
+                let x = i % w
+                for v in [x > 0 ? i - 1 : -1, x < w - 1 ? i + 1 : -1, i >= w ? i - w : -1, i < w * (h - 1) ? i + w : -1]
+                where v >= 0 && marca[v] && !visto[v] {
+                    visto[v] = true
+                    pilha.append(v)
+                }
+            }
+            guard membros.count >= 20 else { continue }
+            let fortes = membros.sorted { diferenca[$0] > diferenca[$1] }.prefix(max(1, membros.count / 4))
+            func mediana(_ canal: Int) -> UInt8 { fortes.map { a[$0 * 4 + canal] }.sorted()[fortes.count / 2] }
+            let cor = (r: mediana(0), g: mediana(1), b: mediana(2))
+            let miolo = membros.filter { i in
+                let k = i * 4
+                return max(abs(Int(a[k]) - Int(cor.r)), abs(Int(a[k + 1]) - Int(cor.g)), abs(Int(a[k + 2]) - Int(cor.b))) <= 28
+            }
+            guard miolo.count >= 8 else { continue }
+            let lt = luminancia(cor.r, cor.g, cor.b)
+            var notas: [Double] = []
+            for i in miolo {
+                let x = i % w, y = i / w
+                for (dx, dy) in [(0, 0), (-2, 0), (2, 0), (0, -2), (0, 2)] {
+                    let vx = x + dx, vy = y + dy
+                    guard vx >= 0, vx < w, vy >= 0, vy < h, dentro[vy * w + vx] else { continue }
+                    let v = (vy * w + vx) * 4
+                    notas.append(contraste(lt, luminancia(b[v], b[v + 1], b[v + 2])))
+                }
+            }
+            notas.sort()
+            var x0 = w, y0 = h, x1 = 0, y1 = 0
+            for i in membros { let x = i % w, y = i / w; x0 = min(x0, x); y0 = min(y0, y); x1 = max(x1, x); y1 = max(y1, y) }
+            let caixa = CGRect(x: CGFloat(x0) / escala, y: CGFloat(y0) / escala,
+                               width: CGFloat(x1 - x0 + 1) / escala, height: CGFloat(y1 - y0 + 1) / escala)
+            marcas.append(Palavra(caixa: caixa, cor: cor, nota: notas[notas.count / 100], minimo: notas[0]))
+        }
+        return marcas.sorted { ($0.caixa.minY, $0.caixa.minX) < ($1.caixa.minY, $1.caixa.minX) }
+    }
+
     /// Rótulo que o app não apaga (o botão de um alerta do sistema), medido num print só: o fundo é a própria
     /// cápsula. `quadro` é o do botão, em pontos; por dentro da borda (6 pt), as letras são os pixels longe da
     /// cor da cápsula (a mediana do quadro, que o texto não domina). A cor do texto sai do miolo das letras, como
```

Em `app-ios/CusttaUITests/LeituraNoVidroUITests.swift`:

```diff
--- a/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
+++ b/app-ios/CusttaUITests/LeituraNoVidroUITests.swift
@@ -20,6 +20,8 @@ final class LeituraNoVidroUITests: XCTestCase {
     private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
     private let temas = ["escuro", "claro"]
     private static let portao = 4.5
+    /// O mínimo das marcas de gráfico (spec da etapa 4, "Laudo das marcas"), o do mockup.
+    private static let portaoDasMarcas = 3.0
     /// A barra de status fica de fora: a hora muda entre os dois prints.
     private static let barraDeStatus: CGFloat = 70
     /// Rolagens da lista sob a cápsula de abas: no Mac, de 10 em 10 pt até 60 e o fim (260); na CI
@@ -171,7 +173,10 @@ final class LeituraNoVidroUITests: XCTestCase {
         }
     }
 
-    @MainActor private func anexar(_ nome: String, _ imagem: UIImage, _ palavras: [LaudoDeContraste.Palavra], _ escala: CGFloat) {
+    /// As marcas saem com o prefixo "marcas" e o portão delas: o comparador do laudo (`scripts/compara-laudo.mjs`) lê só as
+    /// tabelas "leitura — …", com o portão de 4,5.
+    @MainActor private func anexar(_ nome: String, _ imagem: UIImage, _ palavras: [LaudoDeContraste.Palavra], _ escala: CGFloat,
+                                   portao: Double = LeituraNoVidroUITests.portao, tipo: String = "leitura") {
         let formato = UIGraphicsImageRendererFormat()
         formato.scale = 1
         let tamanho = CGSize(width: imagem.size.width * imagem.scale, height: imagem.size.height * imagem.scale)
@@ -180,7 +185,7 @@ final class LeituraNoVidroUITests: XCTestCase {
             for p in palavras {
                 let caixa = CGRect(x: p.caixa.minX * escala, y: p.caixa.minY * escala,
                                    width: p.caixa.width * escala, height: p.caixa.height * escala).insetBy(dx: -4, dy: -4)
-                let cor: UIColor = p.nota < Self.portao ? .systemRed : .systemGreen
+                let cor: UIColor = p.nota < portao ? .systemRed : .systemGreen
                 cor.setStroke()
                 ctx.cgContext.setLineWidth(4)
                 ctx.cgContext.stroke(caixa)
@@ -191,15 +196,15 @@ final class LeituraNoVidroUITests: XCTestCase {
             }
         }
         let foto = XCTAttachment(image: anotada)
-        foto.name = "leitura — \(nome)"
+        foto.name = "\(tipo) — \(nome)"
         foto.lifetime = .keepAlways
         add(foto)
         let linhas = palavras.map { p in
             String(format: "%@  %4.0f,%4.0f  %4.0f×%3.0f pt  nota %5.2f  pior %5.2f", p.corHex,
                    p.caixa.minX, p.caixa.minY, p.caixa.width, p.caixa.height, p.nota, p.minimo)
         }
-        let tabela = XCTAttachment(string: "Leitura — \(nome) (portão \(Self.portao):1)\n" + linhas.joined(separator: "\n"))
-        tabela.name = "leitura — \(nome) (tabela)"
+        let tabela = XCTAttachment(string: "\(tipo == "leitura" ? "Leitura" : "Marcas") — \(nome) (portão \(portao):1)\n" + linhas.joined(separator: "\n"))
+        tabela.name = "\(tipo) — \(nome) (tabela)"
         tabela.lifetime = .keepAlways
         add(tabela)
     }
@@ -420,6 +425,52 @@ extension LeituraNoVidroUITests {
         cobrar(cenas)
     }
 
+    /// O laudo das marcas (spec da etapa 4, "Laudo das marcas"): os pedaços da barra empilhada da obra a 3:1 com o que fica
+    /// atrás deles (a placa forte sobre o vidro), nos dois temas e nos vidros Transparente e Fosco. Cada cena sai em dois
+    /// prints, um normal e um com as marcas apagadas (`-custta.marcasApagadas`, só Debug), como o texto apagado; a marca é o
+    /// que muda de um para o outro, dentro do quadro da barra.
+    @MainActor func testMarcasDaBarraDeTopicos() {
+        var falhas: [String] = []
+        for tema in temas {
+            for vidro in ["transparente", "fosco"] {
+                let nome = "marcas, barra de tópicos, \(tema), \(vidro)"
+                let argumentos = ["-custta.tema", tema, "-custta.vidro", vidro, "-custta.rolagem", "750"] + piorMomento
+                func fotografar(apagadas: Bool) -> (XCUIScreenshot, CGRect, CGFloat) {
+                    let app = abrirApp(conta: "senha", dados: "vitrine", abrir: "obra:v1",
+                                       argumentos: argumentos + (apagadas ? ["-custta.marcasApagadas", "YES"] : []))
+                    let barra = app.elemento("barraDeTopicos")
+                    XCTAssertTrue(barra.waitForExistence(timeout: 30), "\(nome): a obra não abriu")
+                    Thread.sleep(forTimeInterval: 2)                   // o vidro e a rolagem assentam
+                    let foto = XCUIScreen.main.screenshot()
+                    let quadro = barra.frame, largura = app.frame.width
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
+                // Os 7 pedaços da Casa Alphaville: os 6 maiores e o "Outros".
+                XCTAssertEqual(marcas.count, 7, "\(nome): \(marcas.map(\.corHex))")
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
     /// A lista da obra rolando, no escuro (onde a dose de vidro decide), sem e com Aumentar contraste: o pior
     /// ponto de um cabeçalho de mês ou de uma linha de baixo pode estar fora do quadro de 640 pt. No Mac, três rolagens; na
     /// CI, duas.
```

- [ ] **Step 2: Ver falhar**

Run (no Pro Max, como na Tarefa 32):
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | grep -v appintents | tail -1
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/LeituraNoVidroUITests/testMarcasDaBarraDeTopicos 2>&1 | grep -oE 'XCTAssertEqual failed.*|Executed [0-9]+ tests?, with [0-9]+ failures?' | sed -n '1p;$p'
```
Expected: compila, e sem o modo de Debug nada muda entre os dois prints: nenhuma marca medida, nas quatro cenas.
```
** TEST BUILD SUCCEEDED **
XCTAssertEqual failed: ("0") is not equal to ("7") - marcas, barra de tópicos, escuro, transparente: []
Executed 1 test, with 4 failures
```

- [ ] **Step 3: Implementar**

Em `app-ios/Custta/Identidade/BarraEmpilhada.swift`:

```diff
--- a/app-ios/Custta/Identidade/BarraEmpilhada.swift
+++ b/app-ios/Custta/Identidade/BarraEmpilhada.swift
@@ -33,6 +33,11 @@ struct BarraEmpilhada: View {
     let pedacos: [PedacoDoAnel]
     @Environment(\.paleta) private var paleta
     @Environment(\.dynamicTypeSize) private var letra
+    #if DEBUG
+    @Environment(\.marcasApagadas) private var apagadas
+    #else
+    private let apagadas = false
+    #endif
 
     var body: some View {
         let grande = letra.isAccessibilitySize
@@ -41,7 +46,7 @@ struct BarraEmpilhada: View {
             let larguras = largurasDaBarra(pedacos, largura: geo.size.width, piso: piso, vao: vao)
             HStack(spacing: vao) {
                 ForEach(Array(pedacos.enumerated()), id: \.offset) { i, pedaco in
-                    Capsule().fill(paleta.cor(corDoPedaco(pedaco))).frame(width: larguras[i])
+                    Capsule().fill(paleta.cor(corDoPedaco(pedaco)).opacity(apagadas ? 0 : 1)).frame(width: larguras[i])
                 }
             }
         }
@@ -135,3 +140,12 @@ struct Hachura: Shape {
         return listras.intersection(Path(rect))
     }
 }
+
+#if DEBUG
+extension EnvironmentValues {
+    /// Laudo das marcas (spec da etapa 4, "Laudo das marcas"; só Debug): com `-custta.marcasApagadas YES` as marcas de
+    /// gráfico somem sem mexer no layout, como o texto apagado apaga o texto; os dois prints dão a cor de cada marca e o
+    /// fundo atrás dela (a placa sobre o vidro), e o laudo cobra 3:1.
+    @Entry var marcasApagadas = false
+}
+#endif
```

Em `app-ios/Custta/Telas/RaizView.swift`:

```diff
--- a/app-ios/Custta/Telas/RaizView.swift
+++ b/app-ios/Custta/Telas/RaizView.swift
@@ -27,6 +27,8 @@ struct RaizView: View {
     /// O globo para pelo "Reduzir movimento".
     @AppStorage("custta.auroraPiorCaso") private var auroraPiorCaso = false
     @AppStorage("custta.textoApagado") private var textoApagado = ""
+    /// Laudo das marcas (etapa 4): as marcas de gráfico apagadas, sem mexer no layout (`-custta.marcasApagadas YES`).
+    @AppStorage("custta.marcasApagadas") private var marcasApagadas = false
     #endif
 
     var body: some View {
@@ -50,6 +52,7 @@ struct RaizView: View {
         #if DEBUG
         .modifier(ApagaTexto(ativo: textoApagado == "tudo"))
         .environment(\.apagaTextoDaNavegacao, textoApagado == "navegacao")
+        .environment(\.marcasApagadas, marcasApagadas)
         #endif
         // O aviso e o "Finalizar saída" ficam por cima de todas as telas; vêm antes do .environment para receber
         // a mesma paleta.
```

- [ ] **Step 4: Ver passar**

Run (no Pro Max):
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|warning:|TEST BUILD" | grep -v appintents | tail -3
xcodebuild test-without-building "${XB[@]}" -collect-test-diagnostics never -only-testing:CusttaUITests/LeituraNoVidroUITests/testMarcasDaBarraDeTopicos 2>&1 | grep -E "^marcas \||Executed [0-9]+ test" | tail -5
```
Expected: `** TEST BUILD SUCCEEDED **`, sem aviso, e
```
marcas | marcas, barra de tópicos, escuro, transparente | 7 marcas | pior nota 4.49
marcas | marcas, barra de tópicos, escuro, fosco | 7 marcas | pior nota 4.52
marcas | marcas, barra de tópicos, claro, transparente | 7 marcas | pior nota 3.60
marcas | marcas, barra de tópicos, claro, fosco | 7 marcas | pior nota 3.68
	 Executed 1 test, with 0 failures (0 unexpected) in 74.311 (74.314) seconds
```
A cor de cada marca medida é a do token, nos dois temas (no escuro, `#199E70`, `#3987E5`, `#D55181`, `#9085E9`, `#D95926`, `#14A3C7` e o `#8FA89C` do "Outros"; no claro, `#10976A` a `#0C86A4` e `#5E7A6E`). O pior pedaço é o verde-água no claro, 3,60:1 no Transparente e 3,68 no Fosco (o mockup mediu 3,54); no escuro, o laranja, 4,49.

- [ ] **Step 5: Conferir o Release**

O modo de marcas apagadas é só do Debug (memória `release-sem-ganchos-conferir-por-nm`): compilar o Release para o simulador, sem assinar, e contar o símbolo no binário do Release e no `Custta.debug.dylib` do Debug, com um símbolo de produção de controle.

Run (como no Step 6 da Tarefa 28: o Release sem `-derivedDataPath`, no mesmo DerivedData do `XB`, e o `nm -a` nos dois):
```bash
xcodebuild build-for-testing "${XB[@]}" 2>&1 | grep -E "error:|TEST BUILD" | tail -1
xcodebuild build -project app-ios/Custta.xcodeproj -scheme Custta -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | tail -1
PROD=$(xcodebuild "${XB[@]}" -showBuildSettings 2>/dev/null | awk -F' = ' '/^ *BUILD_DIR = /{print $2; exit}')
for s in marcasApagadas BlocosDaObra; do echo "$s release=$(nm -a "$PROD/Release-iphonesimulator/Custta.app/Custta" | grep -c $s) debug=$(nm -a "$PROD/Debug-iphonesimulator/Custta.app/Custta.debug.dylib" | grep -c $s)"; done
```
Expected: `** TEST BUILD SUCCEEDED **`, `** BUILD SUCCEEDED **` e:
```
marcasApagadas release=0 debug=60
BlocosDaObra release=327 debug=498
```
O `marcasApagadas` fica fora do Release; o `BlocosDaObra` é o controle. (Com o `nm -a`, que conta também os símbolos de depuração; o `nm` sem ele dava 0 e 30, e 161 e 243.)

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Identidade/BarraEmpilhada.swift app-ios/Custta/Telas/RaizView.swift app-ios/CusttaUITests/LaudoDeContraste.swift app-ios/CusttaUITests/LeituraNoVidroUITests.swift
git commit -m "test: marcas apagadas no laudo e a barra de tópicos a 3:1" -m "O laudo ganha o modo de Debug que apaga só as marcas de gráfico, como o texto apagado apaga o texto: com -custta.marcasApagadas, a barra empilhada pinta os pedaços sem cor e sem mudar o layout. O medidor das marcas separa cada pedaço pelo vão da barra, lê a cor no miolo e mede o contraste contra a placa que fica atrás, no print sem marcas." -m "O teste novo cobra os 7 pedaços da Casa Alphaville a 3:1, nos dois temas e nos vidros Transparente e Fosco; o pior é o verde-água no claro, 3,60:1. As tabelas das marcas saem com o próprio prefixo, fora do comparador do laudo, que mede texto a 4,5:1."
```

### Task 34: Checklist do aparelho do marco 1

O checklist que o Giovani roda no iPhone no build do fecho de cada marco da etapa 4 (spec, "Marcos e espera", o checklist: "Cada marco tem um checklist do aparelho, com VoiceOver, Controle por Voz e a letra máxima. O da etapa fecha no 4b"), no estilo do da etapa 3 (Task 21 do plano da etapa 3, `docs/plans/2026-10-19-app-nativo-etapa3-checklist-aparelho.md`), na conta de sempre. O arquivo nasce com a parte de antes do primeiro build (a cópia dos dados e o PR 0 do site no ar) e a seção do marco 1: os tokens globais no app inteiro (o âmbar de texto mais escuro do claro e a cápsula de abas na borda de 16 pt, PR 1a; o globo e o secundário ficam como estavam); a obra em blocos (o título mono, o sólido, um bloco por assunto, os gastos por tópico sem toque e sem portas, com o "Outros" sempre no cinza, a linha mono, a obra sem orçamento, sem gastos e vendida com lucro e com prejuízo, numa "Obra de teste" criada no app e apagada no fim, como pede o spec, "Conta"); a letra máxima; e a acessibilidade, com VoiceOver, Controle por Voz, os dois vidros e Reduzir transparência e Aumentar contraste. Os marcos 2 e 3 completam o mesmo arquivo (o 4b fecha o da etapa).

**Files:**
- Create: `docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md`

- [ ] **Step 1: Escrever o checklist**

Criar `docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md`:

```markdown
# App nativo, etapa 4: checklist no iPhone

O Giovani roda no iPhone, pelo TestFlight, o build de cada fecho de marco da etapa 4 (marco 1: os PRs 1a, 1b e 1c; marco 2: 4a, 2a e 2b; marco 3: 3a, 3b e 4b), **na conta de sempre**. Cada item que falhar vira tarefa para o Forja, com o passo, o que apareceu e uma captura de tela. Os itens de um marco continuam valendo nos builds seguintes. Os itens que mexem em gasto usam uma obra de teste criada no próprio app ("Obra de teste") e apagada no fim.

## Antes do primeiro build

A etapa não grava nada novo: os caminhos de gravação são os das etapas 2 e 3. Mesmo assim, a cópia vale antes de cada build de marco.

- [ ] No site: Ajustes → Seus dados → Exportar dados completos. Guarde o arquivo (`custta-AAAA-MM-DD.json`) fora do repositório, como cópia de segurança.
- [ ] O PR 0 do site já está publicado (as seis regras no `calc.js` e os dois alinhamentos do "Vale a pena?").

## Marco 1: os tokens globais e a obra em blocos

**Os tokens, no app inteiro** (PR 1a)

- [ ] No claro, o âmbar dos textos sobre o vidro ficou mais escuro (`#5E3A03`): o aviso dos tópicos na linha do orçamento, o "Passou … do previsto" da tela Orçamento e o prejuízo no bloco da Venda. Diga se algum texto ficou pesado demais.
- [ ] No escuro, o globo continua como antes (a 40% dentro do app: o 1a mediu, e ele já era mais apagado que o do mockup); nada fica difícil de ler por cima dele.
- [ ] A cápsula de abas e o + ficam a 16 pt da borda em todas as telas (Obras, a obra, Orçamento, Afazeres, Ajustes) e não pulam de lugar ao trocar de aba.

**A obra em blocos** (PRs 1b e 1c; mockup aprovado, parte 1)

- [ ] Abra a obra de sempre: o nome no título em letra mono (SF Mono), quebrando em duas linhas se for comprido; embaixo, a cápsula com a fase e "começou em … · N meses".
- [ ] O Total gasto no bloco verde, com o número em mono e o R$ e os centavos menores na mesma linha; "N lançamentos" na etiqueta e "bruto, sem correção" embaixo. Os números são os do site.
- [ ] Depois, um bloco por assunto, na ordem de antes: Orçamento (com a seta, abre a tela Orçamento), Corrigido pelo banco, A pagar · 30 dias (com a seta, abre a folha do A pagar) e Venda estimada. As ações da fase, os Afazeres, "Gastos por tópico" e os Lançamentos vêm depois; nada da etapa 3 sumiu.
- [ ] "Gastos por tópico": a barra com um pedaço por tópico (os 6 maiores nas cores e "Outros" em cinza) e a legenda dos 4 maiores com o %, e "e mais N tópicos". Os % batem com a folha do detalhe de cada tópico. A barra não abre nada neste build (os Gráficos chegam no marco 2), e não há "Ver gráficos" nem "Relatório".
- [ ] Os lançamentos com o valor em mono à direita e o ícone pequeno do tópico na linha de baixo; um título comprido quebra, e o valor desce para baixo do título só quando não cabe ao lado. As folhas (A pagar e detalhe do tópico) continuam com a linha de antes.
- [ ] Uma obra sem orçamento: o bloco do Orçamento some e "Definir orçamento" aparece nas ações.
- [ ] Na "Obra de teste", sem gastos: o bloco verde mostra R$ 0,00 e "Toque no + para lançar o primeiro gasto."; somem "Gastos por tópico", a lupa e o mês. Lance um gasto pelo +, no tópico "Outros": a barra de tópicos aparece com ele, toda cinza, e a linha nova acende na lista.
- [ ] Lance outro gasto na "Obra de teste", menor, em "Terreno": o Terreno sai colorido, e o "Outros" fica cinza, no fim da barra, mesmo sendo o maior.
- [ ] Marque a "Obra de teste" como pronta, registre uma venda maior que os gastos e confira: o bloco verde vira "Lucro da venda", com "+R$ …", "Vendida em …" e "+R$ … acima do banco", e o Total gasto desce para um bloco de vidro logo abaixo do sólido (depois do Orçamento, se a obra tiver um). Desfaça a venda e registre uma menor que o gasto: o bloco verde volta a ser o Total gasto, e o lucro negativo fica no bloco da Venda, em âmbar (nunca vermelho). Desfaça a venda e apague a "Obra de teste".
- [ ] Os gestos de antes: arrastar um lançamento para a esquerda mostra "Apagar"; o "A vencer" abre e fecha; a lupa e o mês filtram só a lista; rolar a tela faz o nome passar para a barra, também em mono.

**Texto Maior no máximo** (Ajustes do iPhone → Acessibilidade → Tela e Tamanho do Texto → Texto Maior)

- [ ] O título cresce e quebra em duas linhas (numa obra de nome comprido); a cápsula, os blocos e a etiqueta de cada bloco empilham, sem nada cortado.
- [ ] O número do bloco verde encolhe só o necessário para caber numa linha, sem reticências, com o R$ e os centavos ainda legíveis; os números dos outros blocos, o mesmo.
- [ ] Na legenda da barra, 3 tópicos e "e mais N tópicos"; o nome comprido quebra em vez de cortar.
- [ ] Nos lançamentos, o valor desce para baixo do título e cada informação fica numa linha.

**Acessibilidade**

- [ ] VoiceOver, na obra: cada bloco é um elemento só, lido inteiro ("Total gasto, 46 lançamentos, R$ 842.317,45, bruto, sem correção"); o número é lido como dinheiro, com os centavos. O título é um cabeçalho.
- [ ] VoiceOver, nos gastos por tópico: o bloco é um elemento só, "Gastos por tópico", com os pedaços e o % de cada um ("Terreno, 38%; Estrutura, 11%; …"; "menos de 1%" no lugar do "<1%"); a legenda não é lida de novo.
- [ ] VoiceOver, na vendida com lucro: "Lucro da venda, Vendida em …, +R$ …, +R$ … acima do banco". Diga se o "mais" e o "menos" são falados de um jeito que se entende.
- [ ] VoiceOver, os blocos com seta: dois toques no Orçamento abrem a tela Orçamento e no A pagar abrem a folha dele; o rotor e o gesto de escape continuam como na etapa 3.
- [ ] Controle por Voz ("Mostrar nomes"): "Tocar Orçamento", "Tocar A pagar", "Tocar Afazeres" e o nome de um lançamento funcionam; os gastos por tópico não aparecem como botão.
- [ ] No escuro e no claro, nos vidros Transparente e Fosco (Ajustes → Aparência), os pedaços da barra se distinguem da placa atrás e entre si, e o texto da legenda se lê. Com Reduzir transparência, os blocos ficam sólidos e nada some.
- [ ] Com Aumentar contraste, a obra inteira continua legível, e o bloco verde não muda de cor.
```

- [ ] **Step 2: Ver passar**

Run: `grep -c '^- \[ \]' docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md`
Expected: `26` (os itens do checklist). O `tests/docs.test.mjs` não serve aqui: ele lista os arquivos pelo `git ls-files`, e o checklist só entra no índice no `git add` do Step 3; o teste dos links só olha os `*.md` da raiz e os `docs/*.md`.

- [ ] **Step 3: Commit**

```bash
git add docs/plans/2026-10-29-app-nativo-etapa4-checklist-aparelho.md
git commit -m "docs: checklist do aparelho do marco 1 da etapa 4" -m "O checklist que o Giovani roda no iPhone no build que fecha cada marco da etapa 4, na conta de sempre, no estilo do da etapa 3: antes do primeiro build, a cópia dos dados e o PR 0 do site no ar; e a seção do marco 1, com os tokens globais no app inteiro, a obra em blocos nos estados do mockup (numa obra de teste criada e apagada no próprio app), a letra máxima e a acessibilidade, com VoiceOver, Controle por Voz, os dois vidros, Reduzir transparência e Aumentar contraste. Os marcos 2 e 3 completam o mesmo arquivo."
```

---

## Para os planos dos marcos 2 e 3

O que as fatias e as sondas deste marco deixam para os planos seguintes.

**Sondas do PDF na CI** (OK do Giovani em 29/10). O ramo é `proto/etapa4-sondas-pdf`, com os commits `cc029f7` (a sonda) e `07b3948` (só o job). Foram três runs verdes, no Xcode 26.6, Swift 6.3.3 e iOS 26.5: [40932514055](https://github.com/gstuchi/app_construcao_civil/actions/runs/40932514055), [40934839915](https://github.com/gstuchi/app_construcao_civil/actions/runs/40934839915) e [40938500971](https://github.com/gstuchi/app_construcao_civil/actions/runs/40938500971). O ramo nunca vai à `main`.

- **O gerador fora da thread principal passou.**
  - O Swift 6.3.3 compila em Release e em Debug sem aviso. Para isso, o gerador precisou de:
    - `@MainActor` no `gerar` e na `paginaUm`;
    - os structs `Sendable`;
    - `withTaskCancellationHandler` em volta de cada `Task.detached`, porque o detached não herda o cancelamento, e `Task.isCancelled` entre as páginas.
  - O PDF feito fora da principal sai igual ao feito todo nela, em texto e em pixels, com 500 e com 5.000 gastos.
  - Com 5.000 gastos, a principal fica presa de 16 a 23 ms, só na página 1, e o total na VM leva de 1,3 a 1,8 s.
  - O Main Thread Checker está ligado na CI, mas o aviso dele só sai no stderr (0 `runtimeWarnings` no xcresult). A guarda do 4b roda com `MTC_CRASH_ON_REPORT`, que derruba o processo, e cabe no job `app`.
- **A marcação para leitor de tela não passou, e o 4b sai sem ela, pela regra do spec**: só com o título (`kCGPDFContextTitle`).
  - A API do iOS 13 fecha as tags no fim de cada página, então a tabela não atravessa página.
  - O `/Lang` não chega ao catálogo.
  - O `/ParentTree` e o `/IDTree` ficam pendentes, e nenhuma página leva `/StructParents`, inclusive no iOS e no macOS 27.
  - Custa de 16% a 23% a mais de tempo, e o arquivo fica 4,2 vezes maior.
  - A marcação volta a ser estudada com a API do iOS 27, que ainda não foi medida.
- **O teste da ordem do texto do 4b é por retângulo.** O PDFKit do iOS 26.5 parte a linha da página 1 logo depois do "m²" e ignora a árvore.

**Do PR 0.** A descrição vazia que vira o nome do tópico continua na cola do site, porque depende do mapa de tópicos da tela. O 3a repete a troca no app e leva um teste de unidade da linha sem descrição.

**Do PR 0b.**
- A evolução também é cortada em 24 meses, mas o aviso dos 24 meses só existe no gasto por mês. O núcleo já devolve `evolucaoFoiCortada`. O 2b põe o mesmo aviso na evolução.
- As medidas do PDF que a paginação usa são as do mockup, todas em `MedidasDoPDF`. O 4b as acerta no desenho real e confere que o SF Mono em negrito tem a mesma largura por caractere, porque a coluna de valor supõe isso.
- O valor falado, o passo e o descritor do VoiceOver dos gráficos de mês ficam para o 2b, como conta pura com teste de unidade. O pedaço sob o ângulo e o mês sob o x já estão no núcleo (Tarefas do 0b).

**Da revisão dos PRs 0 e 0b.**
- O `linhaDeGasto(...).titulo` do núcleo já troca a descrição vazia pelo nome do tópico, com teste. O 3a e o 4b o reusam, em vez de repetir a troca.
- O 2a vai mostrar valores arredondados ao real (R$ 319.847,85 vira R$ 319.848), e o núcleo ainda não tem essa função. Ela entra no plano do 2a, com teste.

**Para o 4a, da CI (Decisões).**
- Os testes de tela da etapa 4 vão para jobs próprios, e o `app` para de crescer. Ele termina o marco 1 com uns 119 testes de tela.
- O `laudo.xcresult` passa a subir sempre, e não só quando reprova. Assim, as tabelas do iOS 26 também são comparadas palavra por palavra com as do commit anterior (spec, "Testes e validação", item 6). No marco 1, a comparação é só no Pro Max (iOS 27), e a CI é o portão de 4,5.

**Do PR 1c (a costura das telas da análise).**
- **O "Vale a pena?" não tem rota em `RotaDeObras`, porque é uma aba.** O 4a põe a `Aba.valeAPena` e, junto, o gancho `CUSTTA_ABRIR=valeAPena:<id>`. Os falsos dos estados dele já estão no `CUSTTA_DADOS=analise`, e o "sem obra" no `vazio`.
- **Os Gráficos (2a) e o Relatório (3a) trocam só o `DestinoDaAnalise(tela:caminho:)`.** A rota (`RotaDeObras.analise(.graficos(id))` e `.relatorio(id)`) e o gancho (`CUSTTA_ABRIR=graficos:<id>` e `relatorio:<id>`) já existem.
- **Obra que some com a tela aberta.** Hoje, com a obra inexistente ou apagada, a tela provisória abre na raiz, sem nome. As telas de verdade do 2a e do 3a voltam quando a obra some, como a tela Orçamento.
- **`CUSTTA_FOLHA` sobre as telas da análise.** Ele funciona (sonda, 3 de 3), então os testes do 2a e do 3a abrem folhas sem mexer no `PrincipalView`.

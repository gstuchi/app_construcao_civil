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
| O preço do simulador na obra sem venda estimada (**a confirmar antes do merge do PR 0**) | O campo fica vazio ("Digite o preço de venda pra ver a conta.") | É a leitura do plano para "o preço acompanha a venda estimada". Hoje, a obra herda o preço da anterior. Manter o anterior é uma linha na cola, sem mexer na regra. O PR 0 vai ao ar no merge, então ele espera a resposta |
| Soma por tópico no site | `Map`, não objeto (Tarefas 1 e 2) | O objeto passava o tópico de id numérico à frente no empate, e o tópico `"__proto__"` derrubava o Relatório. O `Map` faz o empate do spec, que é o que a cópia em Swift já fazia. A tela só muda nesses dois casos, que ela não cria |
| O `confere` do núcleo | Reprova quando só um lado não é finito (1ª tarefa do 0b) | A tolerância `.continua` deixava passar infinito contra qualquer número. É achado do PR 0 e foi provado no multiplicador da TIR com taxa zero |
| O tópico fixo "Outros" no anel e na barra (**a confirmar antes do merge do 1c**, o primeiro que mostra a barra) | As fatias seguem o spec: os 6 maiores, quaisquer, e o resto no "Outros" cinza. **Recomendação:** o tópico fixo "Outros" (id `outros`) vai sempre para o pedaço cinza | Com 8 tópicos ou mais, o "Outros" da pessoa pode sair colorido ao lado do "Outros · N tópicos" cinza. A troca muda a regra dos 6 maiores e é pequena no núcleo |
| A parte com 1 casa no Relatório (**a confirmar antes do 3a**) | "<0,1%" abaixo de 0,1% | O spec diz só "1 casa", e o texto não está no mockup. Segue o mesmo princípio do "<1%" |
| Média, maior e meses; o mês a vencer | Contam desde o 1º gasto. O mês a vencer não depende de este mês estar na série | Assim manda o spec. O mockup contava só os 24 meses à vista |
| O "<1%" na folha do detalhe | Entra no 1c, que reescreve a obra, de onde a folha abre | Confirmação 7. No 0b, mexeria em tela da etapa 3 num PR sem tela |
| O "<1%" na lista da tela Orçamento (**a confirmar antes do merge do 1c**) | Se a função da folha também serve à lista, a lista muda junto | Assim o número não muda ao abrir a folha. Mas a tela Orçamento está fora do escopo da etapa |
| O `gastoPorTopico` em Swift | Perde o `hoje:` e o `taxaMensal:` no 1c | Os dois não mudam o resultado. Tirá-los no PR 0 mexeria no app |
| A CI do marco 1 (decisão do Orquestrador em 29/10, como rotina, informada ao Giovani; muda o portão da tabela para o 0 e o 0b) | Igual à de hoje: o 0 e o 0b rodam os 10 jobs, uns 90 min, e não só os do núcleo. O filtro por superfície e os jobs da etapa 4 entram no 4a | É recomendação deste plano. O spec pede o filtro num PR que já roda tudo, antes do 2a. Pôr o filtro no 0 juntaria um risco de CI ao PR do site, e um PR só de CI seria o 12º. O custo: o 0 e o 0b esperam mais, e um rerun no iOS 26 tira o PR do merge automático |

## Como entregar

- **Ordem: 0, 0b, 1a, 1b e 1c.** Cada PR nasce num worktree novo, a partir da `origin/main` atualizada, ou empilhado sobre o PR que espera o OK do Giovani. No máximo 2 PRs esperam ao mesmo tempo (decisão 3 dele, 29/10).
- **Uma tarefa por vez.** O Forja segue os passos e faz o commit da tarefa; o Lupa revisa antes da próxima: o diff, os testes da tarefa e uma mutação nas linhas que ela escreve. Achado menor vai para o fim do PR, num commit só.
- **Merge (decisão 3 do Giovani, 29/10).**
  - Com a CI toda verde, a revisão aprovada e nenhum rerun no iOS 26, o Orquestrador mescla, até 5 seguidos. No 5º, manda ao Giovani o resumo com os prints lado a lado (simulador × mockup) de cada PR.
  - Sempre esperam o OK dele:
    - o **1a**, com os prints antes × depois das telas principais no claro e no escuro (tarefa do laudo comparado do 1a);
    - o **TestFlight do fecho do marco**.
- **O PR 0 muda o site no merge:** os dois alinhamentos vão ao ar em custta.com.br. A prévia da Vercel é conferida nos dois viewports antes do merge, como no ponto de controle do PR 0. **Exceção ao merge automático:** o PR 0 espera a resposta do Giovani sobre o preço vazio na obra sem venda estimada (Decisões). As outras pendências "a confirmar" têm prazo na própria linha.
- **CI no marco 1: igual à de hoje.**
  - Todo PR que mexe no app, no núcleo ou nos vetores roda os 10 jobs do `app-ios.yml`, de 79 a 96 min de relógio, porque a conta tem 5 vagas de macOS.
  - O filtro por superfície, a guarda dele e os jobs da etapa 4 entram no 4a, o primeiro PR do marco 2, que já roda tudo (spec, "Onde moram o filtro e os jobs"). Antes do 2a, que é o primeiro PR que só traz tela nova.
  - O laudo inteiro no Pro Max roda no Mac, no fim de cada PR do app (1a, 1b e 1c).
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

Um PR só do site, em sete commits, na forma do PR 0 das etapas 2 e 3. Ele tira do `app.js` as seis regras da análise que o app nativo precisa copiar: o gasto por tópico do donut (Tarefa 1), os grupos, o fim, a linha da correção e a soma da seleção do Relatório (Tarefas 2 a 4) e o "Vale a pena?" (Tarefas 5 e 6). Cada regra entra nos vetores com a cópia e o leitor em Swift no mesmo commit, porque o núcleo barra grupo de vetor sem leitor. O site mostra o mesmo, salvo os dois alinhamentos que o Giovani aprovou em 29/10 (confirmação 4): os meses de 0 a 120 na conta (Tarefa 5) e o preço que acompanha a venda estimada da obra escolhida enquanto a pessoa não digitou (Tarefa 6), cada um com teste de browser que cai com o alinhamento desfeito. Uma subida só do `CACHE`, no fim (Tarefa 7). O risco é baixo: são regras puras, conferidas por vetores, e a cola do `app.js` é presa por uma suíte nova de browser (`tests/browser/analise.cjs`), com o dia fixo pelo relógio do Playwright. Na `main`, nada fica escondido no site: os dois alinhamentos vão ao ar no merge. No app, as regras novas ficam no núcleo, sem tela, até o PR 3a (Relatório) e o 4a ("Vale a pena?"); o `gastoPorTopico` já é usado pela tela Orçamento da etapa 3 e não muda. Na CI, o PR roda os 10 jobs do `app-ios.yml`, de 79 a 96 min de relógio, como hoje roda todo PR que toca o `calc.js`, o núcleo ou os vetores: o nível "núcleo" que a tabela do spec dá a ele depende do filtro por superfície, que o plano recomenda pôr no 4a (a confirmar com o Giovani; ver as Decisões). Um rerun no iOS 26, mesmo num job de tela que este PR não toca, tira o PR do merge automático. O PR abre o marco 1 deste plano (na tabela do spec, o 0 e o 0b vêm antes do 1a, sem marco). São 490 linhas de produção (acréscimos + remoções em `calc.js`, `app.js`, `sw.js` e no núcleo, pelo `git diff --numstat`; 514 somando as tarefas, que reescrevem linhas umas das outras), abaixo dos ~600–850 da tabela. Os vetores vão de 100 grupos e 1015 casos para 110 grupos e 1107 casos; o `swift test` do núcleo, de 233 testes em 37 suítes para 243 em 39; o `npm run test:unit` fica em 407.

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
4. **O preço vazio na obra sem estimada (Tarefa 6).** "O preço acompanha a venda estimada da obra escolhida enquanto a pessoa não digitou" foi lido como: a obra sem estimada deixa o campo vazio ("Digite o preço de venda pra ver a conta."), em vez de manter o preço da obra anterior. **Recomendação:** confirmar com o Giovani na revisão do PR; se ele preferir manter o anterior, é uma linha na cola e um passo no `analise.cjs`.
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

Um PR só do núcleo, em seis commits, com as regras que o app da etapa 4 tem e o site não: os pedaços do anel e da barra empilhada (6 cores e o "Outros"), com o piso de arco e de largura, o pedaço sob o dedo e o "<1%" (Tarefa 9); a escala redonda, os rótulos dos meses e o mês sob o dedo (Tarefa 10); o mês de referência e o padrão, os meses a vencer, as frases do que ficou fora, o aviso dos 24 meses e a média, o maior e os meses (Tarefa 11); a linha do tópico no Relatório, com "N de M gastos" e a parte com 1 casa (Tarefa 12); e a paginação da tabela do PDF, com as colunas pelo maior valor (Tarefa 13). Antes delas, o achado 2 do PR 0: o `confere` dos testes deixa de aceitar infinito contra número, e o contorno do leitor do simulador sai (Tarefa 8, só teste). Nenhuma regra tem vetor do site, porque o site não as tem: cada uma tem teste próprio, conferido por mutação (56 de 56 mortas). O risco é baixo: tudo é conta pura, sem tela, sem gravação e sem mudança nas regras com vetor; o `anoMes` e o `chaveMes` das séries só deixam de ser privados. Na `main`, as regras ficam sem uso até as telas: a barra no PR 1c, os Gráficos no 2a e no 2b, o Relatório e a busca no 3a e o PDF no 4b. Na CI, o PR roda os 10 jobs do `app-ios.yml`, como o PR 0: o nível "núcleo" da tabela do spec depende do filtro por superfície, que o plano recomenda pôr no 4a (a confirmar com o Giovani; ver as Decisões). Um rerun no iOS 26, mesmo num job de tela que este PR não toca, tira o PR do merge automático. No marco 1 deste plano, ele vem depois do 0 e antes do 1a. São 552 linhas de produção (acréscimos + remoções em `CusttaNucleo/Sources/`, pelo `git diff --numstat`), dentro dos ~450–600 da tabela; os testes vão de 243 em 39 suítes para 276 em 44 no `swift test` do núcleo, e o `npm run test:unit` fica em 407.

**Branch:** `feat/regras-novas-do-app-no-nucleo`. **Título:** `feat: regras novas da análise e paginação do PDF no núcleo`.

**De onde o ramo nasce.** O 0b depende do código do 0: a Tarefa 8 altera o `SimuladorTests.swift`, criado na Tarefa 5, e a Tarefa 13 usa o `RelatorioDaObra`, o `relatorioObra`, o `fimRelatorio` e o `duasCasasPtBR` do `Relatorio.swift` (Tarefas 2 a 4). Ele nasce da `main` depois do merge do 0 ou, enquanto o 0 não é mesclado, empilhado no ramo `feat/regras-da-analise-nos-vetores`, com o PR apontando para ele; mesclado o 0, a base do PR vira a `main`, com merge da `main` e sem rebase. Nascido da `main` sem o 0, ele cai já na Tarefa 8.

**Como foi provado.** Cada fatia foi conferida sozinha: os testes da tarefa sobre o commit anterior (o "ver falhar" de cada tarefa é a saída real), o `swift test` inteiro sem aviso e, no fim, o `npm run test:unit`. A mutação trocou um trecho por vez nas regras novas e rodou a suíte da tarefa: 16 de 16 nos pedaços, 8 de 8 nos eixos, 13 de 13 nos meses, 6 de 6 na linha do tópico e 13 de 13 na paginação; os casos que mataram as que viviam entraram na própria tarefa (o dedo tão perto do topo que a fração arredonda para 1, a potência pelo piso do log, a altura do texto de 3 linhas, a linha mínima e o gasto de várias linhas que cabe numa página nova). Os casos da revisão do plano entraram do mesmo jeito: o tópico de R$ 0 (Tarefa 9), a evolução de 25 meses (Tarefa 11) e a 1ª página da tabela que saía vazia (Tarefa 13). Na Tarefa 8, a mutação "sem guarda da taxa zero" do PR 0 continua morrendo sem o contorno do leitor.

### Mapa de arquivos do PR 0b

- `Pedacos.swift` (novo, 9): `pedacosDoAnel`, `arcosDoAnel`, `pedacoNoAnel`, `largurasDaBarra`, `porcentoDoTopico`, `legendaDaBarra` e os textos dos tópicos.
- `Eixos.swift` (novo, 10): `escalaRedonda`, `rotulosDoEixoX`, `rotuloDoMes`, `mesNaColuna` e `mesNoPonto`.
- `MesesDosGraficos.swift` (novo, 11): `mesDeReferencia`, `mesPadraoDoGastoPorMes`, `mesAVencer`, as frases, o aviso dos 24 meses e `resumoDosMeses`.
- `TopicoNoRelatorio.swift` (novo, 12): `contagemDeGastos`, `parteComUmaCasa` e `linhaDoTopicoNoRelatorio`.
- `PaginacaoDoPDF.swift` (novo, 13): `MedidasDoPDF`, `colunasDoPDF`, `maiorValorDoPDF`, `paginarTabelaDoPDF` e `rodapeDoPDF`.
- `Series.swift` (10 e 11): o `anoMes` e o `chaveMes` deixam de ser privados.
- Testes: `Vetores.swift`, `VetoresTests.swift` e `SimuladorTests.swift` (8); uma suíte nova por tarefa, `PedacosTests` (9), `EixosTests` (10), `MesesDosGraficosTests` (11), `TopicoNoRelatorioTests` (12) e `PaginacaoDoPDFTests` (13).

### Ponto de controle do fim do PR

Não há tela: o ponto de controle é a CI inteira, os 10 jobs do `app-ios.yml` verdes e sem rerun, e, no Mac, `TZ=America/Sao_Paulo swift test --package-path app-ios/CusttaNucleo` (276 testes em 44 suítes, nenhum aviso) e `npm run test:unit` (407). Na revisão, vale ler os "Produces" das Tarefas 9 a 13 contra as telas que vão usá-los (1c, 2a, 2b, 3a e 4b): os nomes são os que elas chamam.

### Achados que mudam o spec ou uma decisão

1. **O "Outros" do anel bate com o tópico fixo "Outros" (`outros`, Topicos.swift:31).** Numa obra com 8 tópicos ou mais em que o tópico "Outros" está entre os 6 maiores, o anel mostra um "Outros" colorido e o "Outros · N tópicos" cinza. **Recomendação:** com 8 tópicos ou mais, o tópico "Outros" entra sempre no pedaço cinza (e conta entre os N), e os 6 coloridos são os 6 maiores sem ele. Mantém o nome aprovado no mockup e custa umas 3 linhas no `pedacosDoAnel`, com um teste; pede o OK do Giovani, porque muda o "6 maiores".
2. **O "<1%" da folha do detalhe e da tela Orçamento.** O spec põe o "<1%" também no "% da obra" da folha (confirmação 7), e a lista "Gasto por tópico" da tela Orçamento usa o mesmo texto (`textoDaParteDaObra`, PecasDaTelaOrcamento.swift:58; a folha, DentroDaObra.swift:192). Trocar aqui mudaria duas telas da etapa 3 e mexeria no app (laudo e comparação). **Recomendação:** o PR 1c, o primeiro que mostra o "<1%" (na legenda da barra da obra), troca o `textoDaParteDaObra` para receber o bruto e o total e usar o `porcentoDoTopico`, com teste, nas duas telas.
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

Regra nova do app, sem vetor do site (spec, "Regras novas do app" e "### 1. Gráficos", conta pura), para o anel dos Gráficos (PR 2a), a barra empilhada da obra (PR 1c) e o anel da página 1 do PDF (PR 4b). O site dá uma cor por tópico e repete as 8 do 9º em diante (`PIE[i % PIE.length]`, app.js:8, 530 e 1040); o app tem 6 cores e o "Outros" em cinza. A regra, sobre a lista do `gastoPorTopico` (do maior para o menor): até 7 tópicos, um pedaço por tópico, com as cores 0 a 5 e o 7º em cinza (como o mockup, `parte1.js:57-67`); com 8 ou mais, os 6 maiores e o "Outros", que junta os outros tópicos e soma o bruto deles na ordem. O piso: o pedaço com menos de 10 pt de arco (medidos na circunferência do meio do aro) sobe para 10 pt, e o que ele ganhou sai do maior (no empate, o primeiro, o `indexOf(Math.max(…))` do mockup); na barra, o piso é de 8 pt de largura, depois de tirar os vãos de 3 pt (12 e 4 pt na letra máxima, `parte1.css:209-210`), e a mesma regra vale (o mockup usa o `flex` do CSS, que tira de todos; a diferença não se vê). Quando o maior desceria abaixo do piso, que é quando o piso de todos não cabe, ou sem bruto, ou sem largura, as partes ficam iguais (zero na barra sem largura, o 1º quadro do `GeometryReader`). O tópico de bruto zero (um gasto de R$ 0, que o `positivo` do `dados.js` aceita, como o "Brinde" da suíte de browser do PR 0) fica sem pedaço: parte 0, sem piso, sem largura e sem vão na barra, fora das partes iguais e nunca sob o dedo; só a obra sem bruto nenhum divide tudo igual. É o que o site mostra: ele desenha o arco desse tópico com comprimento 0 (`bruto/total*C`, app.js:529 e 1039), e o piso do spec é para o "tópico pequeno" (spec, "Decisões tomadas por recomendação"), não para o vazio; com o piso, o anel ganharia um pedaço colorido de R$ 0,00 com "0%", tirado do maior. Na legenda, o tópico continua, com "0%", como na legenda do site (decisão da revisão do plano). Os arcos vão do topo no sentido do relógio, e o último termina em 1. O pedaço sob o dedo é o arco que contém o ângulo do ponto (o "pedaço mais perto do dedo" do Croqui); quem decide se o dedo está na faixa de 44 pt é a tela. O % é o `Math.round(bruto / total × 100)` do site (o do detalhe do tópico), sem casa decimal no meio do anel (spec, "Deste spec"), e "<1%" quando o verdadeiro fica entre 0 e 1 (o site mostraria 0% ou 1%); sem total, "0%". Os textos novos: "Outros · N tópicos" e "e mais N tópicos" (com "1 tópico" no singular, que o mockup não trata).

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Pedacos.swift`
- Test (novo): `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PedacosTests.swift`

**Interfaces:**
- Consumes: `GastoDoTopico` e `gastoPorTopico(_:hoje:taxaMensal:)` (DentroDaObra.swift), `numeroJS` e `arredondarJS` (já existem).
- Produces: `coresDoAnel` (6), `pisoDoArco` (10), `pisoDaBarra` (8), `vaoDaBarra` (3); `PedacoDoAnel` (`topicos: [GastoDoTopico]`, `bruto`, `cor: Int?`, `outros: Bool`) e `pedacosDoAnel(_ topicos: [GastoDoTopico]) -> [PedacoDoAnel]`; `ArcoDoPedaco` (`inicio`, `fim`) e `arcosDoAnel(_:circunferencia:piso:) -> [ArcoDoPedaco]`; `fracaoNoAnel(x:y:) -> Double` e `pedacoNoAnel(x:y:arcos:) -> Int?` (x e y a partir do centro, y para baixo); `largurasDaBarra(_:largura:piso:vao:) -> [Double]`; `porcentoDoTopico(_ bruto: Double, total: Double) -> String`; `contagemDeTopicos(_:) -> String`; `rotuloDoOutros(_:) -> String`; `LegendaDaBarra` (`pedacos`, `mais: String?`) e `legendaDaBarra(_:quantos:) -> LegendaDaBarra`. Internas: `temPedaco(_:)` e `partesComPiso(_:comprimento:piso:)`.

- [ ] **Step 1: Escrever os testes**

Os testes prendem os pedaços com 1, 7, 8 e 14 tópicos (cores, "Outros" e a soma dele na ordem), o piso que sai do maior e o empate do maior, o tópico de bruto zero (sem arco, sem largura e sem vão, fora das partes iguais e nunca sob o dedo), as partes iguais (sem bruto, sem comprimento, piso que não cabe, maior que desceria abaixo do piso, barra sem largura), a barra nas duas letras, o pedaço sob o dedo nos quatro pontos cardeais, na divisa entre dois arcos e tão perto do topo que a fração arredonda para 1, e os textos com o singular.

Criar `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PedacosTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

/* Os pedaços do anel dos Gráficos e da barra empilhada da obra (regra do app, sem vetor do site): até 7 tópicos, um pedaço
   cada; com 8 ou mais, os 6 maiores e "Outros"; o piso de arco e de largura; o pedaço sob o dedo; o "<1%". */
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
PedacosTests.swift:17:18: error: cannot find 'pedacosDoAnel' in scope
PedacosTests.swift:18:24: error: cannot find 'PedacoDoAnel' in scope
PedacosTests.swift:19:20: error: cannot find 'pedacosDoAnel' in scope
```

- [ ] **Step 3: Implementar**

O `for … where` do piso é um filtro de propósito: todo pedaço pequeno sobe, não só os primeiros. O `max(by:)` devolve o primeiro no empate.

Criar `app-ios/CusttaNucleo/Sources/CusttaNucleo/Pedacos.swift`:

```swift
import Foundation

/* Os pedaços do anel dos Gráficos e da barra empilhada da obra: regra do app, sem vetor do site (spec da etapa 4, "Regras
   novas do app"). O site dá uma cor por tópico e repete depois da 8ª; o app tem 6 cores e o "Outros" em cinza. O pedaço
   pequeno ganha um piso de arco (anel) ou de largura (barra), tirado do maior; o % mostrado é o verdadeiro, com "<1%". */

/// Quantas cores o anel tem. O 7º pedaço é cinza: o "Outros", ou o 7º tópico de uma obra com 7.
public let coresDoAnel = 6

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
    /// O pedaço que junta os tópicos do 7º em diante.
    public let outros: Bool
}

/// Os pedaços, na ordem do `gastoPorTopico`: até 7 tópicos, um pedaço por tópico; com 8 ou mais, os 6 maiores e o "Outros",
/// com a soma e os tópicos que ele junta.
public func pedacosDoAnel(_ topicos: [GastoDoTopico]) -> [PedacoDoAnel] {
    let junta = topicos.count > coresDoAnel + 1
    var pedacos = (junta ? Array(topicos.prefix(coresDoAnel)) : topicos).enumerated().map { i, t in
        PedacoDoAnel(topicos: [t], bruto: t.bruto, cor: i < coresDoAnel ? i : nil, outros: false)
    }
    if junta {
        let resto = Array(topicos.dropFirst(coresDoAnel))
        pedacos.append(PedacoDoAnel(topicos: resto, bruto: resto.reduce(0) { $0 + $1.bruto }, cor: nil, outros: true))
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
Expected: `━ Test run with 252 tests in 40 suites passed after 0.228 seconds with 4 known issues.` (`PedacosTests` é nova, com 8), sem nenhum `warning:`.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo/Sources/CusttaNucleo/Pedacos.swift app-ios/CusttaNucleo/Tests/CusttaNucleoTests/PedacosTests.swift
git commit -m "feat: pedaços do anel e da barra no núcleo, com o piso e o \"<1%\"" -m "Os Gráficos e a obra da etapa 4 mostram o gasto por tópico em seis cores e um \"Outros\" em cinza; o site repete as oito cores do nono tópico em diante. A regra entra no núcleo com teste próprio, sem vetor do site e ainda sem tela: até 7 tópicos, um pedaço cada (o sétimo cinza); com 8 ou mais, os 6 maiores e o \"Outros\", que soma o resto." -m "O pedaço pequeno ganha um piso de 10 pt de arco no anel e de 8 pt de largura na barra, tirado do maior. O tópico de R\$ 0 fica sem pedaço, como o arco vazio do site: sem piso, sem vão na barra e nunca sob o dedo. A conta diz onde cada arco começa e termina e qual pedaço está sob o dedo. O % é o arredondado do site, com \"<1%\" quando o verdadeiro fica entre 0 e 1%."
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

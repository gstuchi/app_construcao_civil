# Gráfico de evolução + respiro mobile + busca nos lançamentos — design

Data: 2026-07-06 · Aprovado por Giovani no chat (referência visual: area chart
dark com curvas suaves, gradiente e grade tracejada).

## Parte 1 — Gráfico "Evolução da obra"

Substitui o painel "Gasto mês a mês" (barras `mbars`) no detalhe da obra.

- **Conteúdo:** duas séries acumuladas por mês, do início da obra até hoje (ou
  até a venda): *gasto bruto acumulado* (linha clara) e *acumulado corrigido
  pelo banco* (linha + área com gradiente por baixo). A distância entre elas é
  o juro embutido.
- **Visual:** SVG puro gerado em `app.js` (sem lib). Curvas suavizadas
  (Catmull-Rom → cúbicas de Bézier), gradiente vertical sob a série corrigida,
  3–4 linhas de grade horizontais tracejadas com rótulo `moneyShort` à
  esquerda, meses (`MESAB`) no eixo de baixo. Cores do tema (`--brand` e um
  tom mais claro), legenda pequena com as duas séries.
- **Interação:** tocar/clicar num mês destaca o ponto e mostra acima do
  gráfico: `jun/26 · gasto R$ 800 mil · corrigido R$ 812 mil`. Sem tooltip
  flutuante (mobile-first).
- **Dados:** função pura `serieEvolucao(obra, taxaPct, hojeISO)` em `calc.js` →
  `[{ mes:'2026-06', bruto, corrigido }]` — um ponto por mês-calendário entre o
  primeiro gasto e o fim da correção; meses sem gasto repetem o acumulado
  (bruto constante, corrigido continua rendendo). Máx. 24 pontos (janela mais
  recente). Obra sem gasto: painel mostra estado vazio atual.
- Antes de codar o gráfico, LER a skill `dataviz` (regra do projeto pra
  qualquer chart) e validar cores/contraste com o que ela mandar.

## Parte 2 — Respiro no mobile

Só CSS em `index.html`:

- `ul.list li`: padding vertical 10px → 14px, gap 11px → 13px.
- `.li-del`: área de toque ≥ 40×40px (padding maior).
- Espaço entre painéis/cards no mobile: gap dos `.cards` e margem dos `.panel`
  +4–6px (só na largura < 768px, sem mexer no desktop).
- Nada de mudar cores, fontes ou identidade (decisão do pai).

## Parte 3 — Busca nos lançamentos

No painel "Lançamentos" do detalhe da obra, acima da lista:

- **Campo texto** (`placeholder="Pesquisar gasto ou tópico"`): filtra ao
  digitar; casa com a descrição do gasto **ou** o nome do tópico, sem
  diferenciar acento/maiúscula (normalizar com `normalize('NFD')` + strip
  diacríticos). "tinta" acha gastos do tópico Pintura só se "tinta" estiver na
  descrição OU o tópico se chamar assim — busca é textual, sem sinônimos.
- **Seletor de mês**: `<select>` com "Todos os meses" + meses que têm gasto
  (`jun/26`…), mais recente primeiro.
- Filtros combinam (E). Contador do painel mostra `achados/total` quando algum
  filtro ativo (ex.: `3/13`). Lista vazia após filtro: mensagem "Nada
  encontrado com esse filtro." (estado vazio atual).
- Filtro vive só em memória (não salva na nuvem, some ao trocar de obra).
- Função pura `filtraGastos(gastos, topicosMap, {texto, mes})` em `calc.js`,
  testada em Node.

## Testes

- Unit (`tests/calc.test.cjs`): `serieEvolucao` (obra com 2 gastos em meses
  distintos → pontos mensais, acumulado certo, corrigido ≥ bruto, mês sem
  gasto repete bruto; vendida congela no mês da venda) e `filtraGastos`
  (texto com acento, por tópico, por mês, combinado, vazio).
- E2E: obra com gastos em 2 meses → gráfico presente (`svg` com 2 `path` de
  série), busca digitando texto reduz a lista, seletor de mês filtra,
  contador `n/total` aparece.
- Visual: screenshots mobile (viewport 390×844) e desktop.

## Fora de escopo

Gráficos das outras telas (donut, comparativo) ficam como estão; busca global
entre obras; salvar filtros.

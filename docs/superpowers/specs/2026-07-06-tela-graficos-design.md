# Tela "Gráficos da obra" — design

Data: 2026-07-06 · Aprovado por Giovani ("pode mandar ver"). Motivação: pai
precisa de um lugar com os gráficos grandes e legíveis (legenda do donut hoje
trunca "Mão…"), com saída em PDF.

## O quê

**Nova view `#v-graficos`** (mesmo padrão do relatório: seção + "‹ Voltar"):

1. **Donut grande** (≥240px) de gastos por tópico; embaixo, lista largura
   cheia, uma linha por tópico: bolinha da cor + nome completo + % + valor
   (`Mão de obra · 67% · R$ 800 mil`). Ordem: maior primeiro (igual donut).
2. **Evolução da obra grande**: mesmo gráfico do detalhe, mais alto
   (H≈300 no viewBox) e textos maiores; toque no mês continua funcionando.
3. Botão **"Imprimir / salvar PDF"** (`window.print()`, classe `no-print` nos
   controles) — PDF com os dois gráficos e a lista.

**Entradas:** botão "Ver gráficos" nas ações da obra + toque no painel do
donut no detalhe. "‹ Voltar" retorna pro detalhe da obra.

**Extra herdado da conversa:** barra de abas com fundo sólido
(`--surface-solid`, sem transparência/blur) — no iPhone do Giovani ela segue
"flutuando".

## Como

- `app.js`: `renderGraficos()` + view wiring (showView já genérico);
  `evoChartHtml(o, opts)` ganha `{sufixo, H, big}` pra coexistirem duas
  instâncias sem conflito de id (`#evoSvg` vs `#evoSvgG`); `bindEvoChart(o,
  sufixo)` idem. Donut grande reaproveita a geometria do `drawDonutObra`
  (função com raio/tamanho parametrizados ou duplicação mínima consciente).
- `index.html`: seção `#v-graficos`, CSS da lista de tópicos e do donut
  grande; `nav.tabs` sólida; print CSS igual ao do relatório.
- `sw.js`: `obras-v10`.
- Dados: tudo já existe (`byTop`, `serieEvolucao`) — sem função nova em calc.

## Testes

- E2E: obra com 2 gastos de tópicos diferentes → botão "Ver gráficos" abre a
  view; lista tem nomes completos (contém "Mão de obra", sem "…"); evolução
  presente; voltar funciona. Regressões anteriores verdes.
- Visual: screenshot mobile 390×844.

## Fora de escopo

Gráficos novos (tipos além dos 2 atuais); relatório-tabela existente intocado.

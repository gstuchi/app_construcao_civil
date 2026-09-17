# Dashboard da tela inicial + área m² — design

Data: 2026-07-06 · Aprovado por Giovani. Referência visual: sketch dark bento
(cartões KPI com chip e brilho, gráfico grande, donut, lançamentos recentes).
Decisões do brainstorm: campo área m² ENTRA; blocos sem dado real CORTADOS
(orçamento fixado, previsão, fornecedores/NF, busca ⌘K, sino, ERP, linha
"previsto"); sem Tailwind, sem fonte nova, CSS do tema.

## Tela inicial (aba Obras), de cima pra baixo

1. **KPIs** (grid 2×2 mobile, 4 col desktop ≥900px), cartão estilo sketch
   (`.panel` atual + brilho radial no canto + chip):
   - **Total gasto** (bruto, todas as obras) · chip `N obras`
   - **Corrigido pelo banco** · sub `Juros embutidos: +R$ X`
   - **A pagar 30 dias** (gastos com data em `(hoje, hoje+30d]`) · chip
     `N vencimentos` (âmbar). Zero vencimentos: valor R$ 0,00, chip "nada a vencer".
   - **Venda estimada** (soma `valorEstimadoVenda`) · chip `N obras avaliadas`
     (verde). Nenhuma estimativa: "—" e chip "sem estimativas".
2. **Lista "Minhas obras"** (painel atual, intocado — navegação principal).
3. **Evolução geral**: gráfico de área existente somando todas as obras —
   série agregada mês a mês (bruto e corrigido acumulados; obra vendida
   congela o corrigido dela no mês da venda). Toque no mês funciona. Vazio:
   estado vazio atual.
4. **Gastos por categoria**: donut 200px + legenda largura cheia (estilo tela
   Gráficos), agregado de todas as obras.
5. **Lançamentos recentes**: últimos 5 gastos (data desc, desempate por id)
   de todas as obras — ícone do tópico, descrição, `nome da obra · data`,
   valor; toque abre a obra. Sem "ver tudo" global (a lista completa vive na
   obra).
6. **Comparativo entre obras** (painel atual) permanece no fim.

## Área m² e preço por m²

- Campo opcional **"Área construída (m²)"** em Nova obra / Editar obra
  (`inputmode="decimal"`, aceita vírgula; salvo como número `areaM2` no blob;
  obra antiga sem o campo: nada quebra, R$/m² só não aparece).
- Detalhe da obra: quando tem `areaM2` e `valorEstimadoVenda`, o cartão
  "Venda estimada" ganha sub `R$ X/m² · Y m²`.
- Simulador: relatório da simulação ganha linha **"Preço por m²"** (venda
  digitada ÷ área; colunas iguais nas duas bases) — só quando a obra tem
  área; senão a linha não aparece.

## Funções puras novas (calc.js, testadas)

- `serieEvolucaoAgregada(obras, taxaPct, hojeISO)` → mesmo formato de
  `serieEvolucao`, meses = união; cada obra contribui com o acumulado dela no
  corte do mês (corrigido congela na venda da obra). Máx 24 últimos.
- `aPagar(obras, hojeISO, dias=30)` → `{ total, qtd }` de gastos com
  `hoje < data <= hoje+dias`.
- `gastosRecentes(obras, n=5)` → `[{obraId, obraNome, gasto}]` ordenado por
  data desc, id desc.
- `precoPorM2(valor, areaM2)` → número ou `null` (área inválida/ausente).

## Testes

- Unit: as 4 funções (agregada com 2 obras e venda no meio; aPagar com
  parcelas dentro/fora da janela; recentes com desempate; precoPorM2 nulos).
- E2E: 2 obras com gastos → início mostra 4 KPIs com valores, evolução geral,
  donut agregado, 5 recentes no máx, toque em recente abre a obra; criar obra
  com área + estimativa → cartão mostra R$/m²; simulador mostra linha "Preço
  por m²". Regressões verdes, zero emoji.
- Visual: screenshots mobile 390×844 e desktop 1280.

## Fora de escopo

Orçamento/previsto, fornecedores, busca global, notificações, fontes novas,
mudança na tela de detalhe além do sub R$/m².

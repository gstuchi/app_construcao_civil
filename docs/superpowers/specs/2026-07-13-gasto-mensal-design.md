# Gasto por mês — barras mensais (2026-07-13)

## Problema
O gráfico "Evolução da obra" é acumulado: mostra tendência e juros, mas não responde
"quanto saiu do bolso em cada mês". Picos (parcelas de terreno, cartão) e meses parados
ficam invisíveis.

## Solução
Novo card "Gasto por mês": barras verticais, uma por mês-calendário, valor bruto somado
(sem correção, sem acumulado). Meses sem gasto aparecem com barra zero.

## Dados (calc.js)
`serieMensal(gastos)` — pura, testável em Node:
- agrupa `gastos` por `data.slice(0,7)`, soma `valor`;
- preenche meses-calendário contínuos do primeiro ao último gasto (zeros no meio);
- retorna `[{mes:'2026-02', total:45000}, ...]`, máx. 24 últimos meses (janela igual à
  de `serieEvolucao`);
- sem gastos → `[]`.

Inclui parcelas futuras (data > hoje), igual o gráfico de evolução faz com o corte.

## Visual (app.js)
- SVG feito à mão, mesmo idioma do gráfico de evolução: mesmas variáveis de cor,
  grid horizontal tracejado, rótulos de mês embaixo, eixo com `moneyShort`.
- Barras na cor `--c1`; barra selecionada acende (classe `on`).
- Tocar numa barra mostra no subtítulo `fev/26 · R$ 45 mil` (mesmo padrão do evo).
  Padrão: último mês com gasto selecionado.
- Sem gastos: card não aparece.

## Onde
1. Detalhe da obra: card logo abaixo de "Evolução da obra".
2. Tela "Ver gráficos": idem, abaixo do evo.

## Testes
Casos em tests/calc.test.cjs: soma por mês; meses vazios zerados; um gasto só;
vazio → []; janela de 24 meses.

# Simulador: rendimento ao mês pela TIR

## Problema

O "Vale a pena?" mostra duas coisas que deveriam concordar e às vezes não concordam:

- **O veredito** ("Vale a pena" / "Rende menos que o banco") compara a venda com o
  custo corrigido: cada gasto rende 1% ao mês (ou a taxa configurada) da data em
  que saiu até a data da venda. Essa conta está certa.
- **O número grande** ("X% ao mês") vem de `taxaEquivalenteMensal(venda, bruto, meses)`,
  que trata o custo inteiro como se tivesse saído no primeiro dia da obra. Como o
  dinheiro sai aos poucos, ele subestima o rendimento.

Com os dados de demonstração, o sobrado vendido hoje por R$ 668 mil mostra
"Vale a pena · 0,83% ao mês · banco paga 1%": o veredito diz que bate o banco e o
número diz que não. A TIR (taxa interna de retorno) desses mesmos fluxos é 1,15%.
Vendido por R$ 950 mil daqui a 6 meses, a tela mostra 2,97% e a TIR é 3,54%.

## Decisão

O rendimento ao mês passa a ser a **TIR mensal** dos fluxos da obra: cada gasto
como saída na sua data e a venda como entrada na data simulada. É a taxa `r` que
zera `venda − Σ gasto × (1 + r)^(dias até a venda / 30,44)` — a mesma fórmula de
`corrigido`, só que resolvida para a taxa. Por construção:

- TIR = taxa do banco exatamente quando venda = custo corrigido;
- TIR > taxa do banco exatamente quando o veredito diz "Vale a pena".

Número e veredito não se contradizem mais.

| Linha "Rendimento ao mês" | Antes | Depois |
| --- | --- | --- |
| Pelo bruto | `(venda/bruto)^(1/meses) − 1` | TIR dos fluxos |
| Pelo corrigido | `(venda/corrigido)^(1/meses) − 1` | rendimento acima do banco: `(1 + TIR)/(1 + taxa) − 1` |

"Rende N× o banco" continua sendo TIR ÷ taxa. Lucro, % sobre o custo e % sobre a
venda não mudam. Obra com menos de 1 mês continua sem % ao mês.

## Implementação

- `calc.js`: `tirMensal(gastos, venda, alvoISO)` em %, por bissecção (o valor
  presente cai sempre que a taxa sobe, então a raiz é única); `null` quando não há
  venda, não há gasto ou nenhum dia passou entre os gastos e a venda.
  `rendimentoAcima(tirPct, taxaPct)` em %. Sai `taxaEquivalenteMensal`, que só o
  simulador usava; `resumoVenda(venda, custo)` deixa de calcular taxa.
- `app.js`: `simulaCompute` usa as duas funções novas.
- Testes de unidade: TIR igual à fórmula antiga quando todo o custo sai no
  primeiro dia; TIR igual à taxa do banco quando a venda é o custo corrigido;
  TIR maior que a fórmula antiga com gastos espalhados; prejuízo negativo; casos
  `null`.

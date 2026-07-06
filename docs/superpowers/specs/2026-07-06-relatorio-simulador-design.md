# Relatório bruto × corrigido no simulador — design

Data: 2026-07-06 · Aprovado por Giovani no chat.

## Objetivo

Na aba "Vale a pena?", mostrar a conta completa **pelos dois custos** (bruto e
corrigido pelo banco), com **porcentagem ao lado de todo valor em dinheiro** —
um relatório na tela, sem download.

## O que muda

O cartão grande do veredito ("Vale a pena / X% ao mês") fica como está. Os três
cartões menores de hoje (Lucro bruto, Acima do banco, Custo até lá) são
substituídos por um painel "Relatório da simulação" com uma tabela:

| Linha | Pelo bruto | Pelo corrigido |
| --- | --- | --- |
| Custo até a venda | `money(bruto)` | `money(corr)` |
| Venda | `money(venda)` | `money(venda)` |
| **Lucro** | `money(venda−bruto)` | `money(venda−corr)` |
| % sobre o custo | `lucro/custo` | idem base corrigida |
| % sobre a venda | `lucro/venda` | idem |
| Rendimento ao mês | `taxaEquivalenteMensal(venda, bruto, meses)` | `taxaEquivalenteMensal(venda, corr, meses)` |

- Coluna "Pelo corrigido" responde: descontado o rendimento que o dinheiro teria
  no banco, sobrou quanto?
- Lucro negativo em vermelho (classe `neg` existente); percentuais acompanham.
- Atualiza ao vivo com preço e meses, igual hoje (mesmo `simulaCompute`).
- Formatação: dinheiro com `money()`; % sobre custo/venda com 1 casa decimal e
  vírgula (`50,0%`); rendimento com 2 casas (`2,93% a.m.`). Divisão por zero ou
  meses inválidos mostram `—`.

## Arquitetura

- `calc.js`: nova função pura `resumoVenda(venda, custo, meses)` →
  `{ lucro, pctCusto, pctVenda, taxaMes }` (`pct*`/`taxaMes` em %, `null` quando
  a base é ≤ 0). Chamada duas vezes (custo bruto e corrigido). Testes em
  `tests/moeda.test.cjs`? Não — arquivo novo não; entra em `tests/calc.test.cjs`
  (é cálculo de obra, não formatação).
- `app.js` (`simulaCompute`): monta a tabela reusando as classes visuais do
  relatório de impressão (`rep-scroll`, `rep-table`).
- Sem mudança de dados salvos, sem SW bump obrigatório (mesmos arquivos já
  cacheados — bump mesmo assim pra celular pegar rápido: `obras-v6`).

## Testes

- Unit: `resumoVenda` — caso do exemplo (venda 3 mi, custo 2 mi, 24 meses →
  lucro 1 mi, 50% custo, 33,3% venda, ~1,70% a.m.), lucro negativo, base zero →
  `null`s.
- E2E existente adaptado: digitar venda no simulador e conferir presença de
  "% sobre o custo" e valores nas duas colunas.

## Fora de escopo

Download/PDF do relatório da simulação; mudanças no relatório de impressão da obra.

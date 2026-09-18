# Dashboard móvel: KPIs saem do início e entram na obra — design

Data: 2026-07-06 · Aprovado por Giovani. Motivo: com 1 obra, o início
duplicava o detalhe (feedback com print).

## Início (volta a ser enxuto)

Somente: painel "Minhas obras" (+ Nova obra) e "Comparativo entre obras"
(quando 2+). Removidos da tela: KPIs, Evolução geral, Gastos por categoria,
Lançamentos recentes (código de agregação `serieEvolucaoAgregada`/`aPagar`/
`gastosRecentes` continua em calc.js — `aPagar` passa a ser usado por obra;
os outros ficam disponíveis).

## Detalhe da obra (vira o dashboard)

O cartão duplo "Total gasto" + cards condicionais atuais dão lugar aos 4 KPIs
estilo novo (`.kpis`/`.kpi`, mesmos chips):

1. **Total gasto** (bruto) · obs `N lançamento(s)`
2. **Corrigido pelo banco** · obs `Juros embutidos: +R$ X`
3. **A pagar · 30 dias** (só desta obra: `aPagar([o], hoje)`) · chip âmbar
   `N vencimentos`/"nada a vencer"
4. **Venda** (dinâmico):
   - vendida: valor da venda · chip verde `Vendida em dd/mm/aa` · obs
     `lucro R$ X · +R$ Y vs banco` (obs vermelha se lucro negativo)
   - com estimativa: valor estimado · chip `estimativa` · obs
     `R$ Z/m² · A m²` (quando tem área) ou `margem R$ W`
   - sem nada: `—` · obs "cadastre no editar obra"

Resto do detalhe intocado (ações, donut, evolução, lançamentos+busca).

## Testes

E2E `smoke-dash` reescrito: início SEM "A pagar"/"Evolução geral"; obra COM os
4 KPIs (inclusive R$/m² na obra com área); simulador com "Preço por m²"
continua. Regressões e unit verdes. SW `obras-v13`.

# Design — Minhas Obras (pivô do dashboard financeiro)

Data: 2026-07-04
Status: aprovado em conversa (Giovani)

## Contexto e objetivo

O app deixa de ser dashboard financeiro pessoal e vira **controle de custos de obras de alto padrão**. Usuário principal: pai do Giovani, construtor que constrói casas para vender depois (sem cliente contratante). Objetivo: saber na ponta do lápis quanto cada obra custou, quanto custaria se o dinheiro tivesse rendido no banco (valor corrigido), e o lucro real na venda.

Sucesso = ele abre o app, entende em 5 segundos quanto já gastou em cada obra e, ao vender, vê se bateu o banco.

## O que fica do app atual

- Identidade visual completa (aprovada pelo pai): tokens CSS dark premium, globo animado (`globe.js`), cards, painéis, sheet de lançamento, donut e gráfico de área, FAB, bottom nav / sidebar desktop.
- Login local CPF+senha (`auth.js`) e contas já criadas.
- PWA offline-first: `manifest.json`, `sw.js`, localStorage por usuário, vanilla JS sem build.

## O que muda

- Todas as telas de domínio (início, lançamentos, contas, negócio, investimentos) são substituídas.
- `app.js` reescrito do zero com o modelo de obras.
- Dados antigos de finanças pessoais no localStorage: descartados.
- Título do app: "Minhas Finanças" → **"Minhas Obras"** (nome final pode mudar; atualizar `index.html`, `manifest.json`, tela de login e `sw.js` cache name).

## Telas e navegação

Bottom nav com 2 abas (**Início**, **Ajustes**) + FAB de lançar gasto. Detalhe da obra empilha sobre o Início com botão voltar. Desktop: sidebar equivalente.

### 1. Início

- Card grande: **total gasto em obras em andamento** (bruto + corrigido).
- Lista de obras: 1 card por obra com nome, fase (🏗 em construção / 🏠 pronta à venda / ✅ vendida), meses desde o início, total gasto. Tocar abre o detalhe.
- Gráfico comparativo: barra horizontal por obra (bruto vs. corrigido).
- Botão "Nova obra".
- Estado vazio ensina: "Crie sua primeira obra".

### 2. Detalhe da obra

- Cabeçalho: nome, fase, meses de obra, data de início.
- Card grande: total gasto **bruto** e **corrigido**.
- Se tiver valor estimado de venda: margem estimada (estimado − corrigido).
- Donut: gastos por tópico.
- Barras: gasto mês a mês.
- Lista de lançamentos (mais recente primeiro); tocar edita, botão apaga com confirmação.
- Ações por fase:
  - Em construção → "Marcar como pronta".
  - Pronta → "Registrar venda" (data + valor real). Obra pronta continua aceitando gastos (IPTU, manutenção).
  - Vendida → mostra **lucro final**: lucro bruto (venda − gasto total) e lucro vs. banco (venda − corrigido até a data da venda). Correção congela na venda.
  - Toda fase pode voltar atrás (marcou errado).
- Editar obra: nome, data de início, valor estimado de venda.

### 3. Lançar gasto (sheet via FAB)

- Campos: obra (pré-selecionada se estiver no detalhe), tópico (chips), valor, data (padrão hoje), descrição curta.
- Mesmo componente sheet/chips do app atual.

### 4. Ajustes

- Taxa de correção mensal (padrão **1% a.m.**, editável).
- Gerenciar tópicos personalizados (criar/remover; remoção só se tópico sem gastos).
- Sair da conta.

## Modelo de dados (localStorage, por usuário)

```text
Obra {
  id, nome,
  fase: "construcao" | "pronta" | "vendida",
  dataInicio,
  valorEstimadoVenda?,        // opcional, editável
  venda?: { data, valor },    // preenchido ao vender
  gastos: [ { id, valor, topico, data, descricao } ]
}
Config { taxaMensal = 0.01, topicosCustom: [] }
```

## Valor corrigido (custo de oportunidade)

- Juro composto pró-rata por dia:
  `corrigido = valor × (1 + taxa)^(dias/30.44)` da data do gasto até **hoje** (obra aberta) ou até a **data da venda** (obra vendida — congela).
- Taxa única global nos Ajustes; ao mudar, recalcula tudo com a taxa nova (sem histórico de taxas — conta transparente e conferível).
- Exemplo canônico: R$ 10.000 em 04/07/2026, 1% a.m. → 6 meses depois = 10.000 × 1,01⁶ ≈ R$ 10.615.

## Tópicos padrão

Terreno · Projeto/Documentação · Terraplenagem/Fundação · Estrutura · Alvenaria · Telhado · Elétrica · Hidráulica · Esquadrias · Revestimentos · Pintura · Paisagismo · Mão de obra · Outros

Terreno incluído de propósito: maior gasto típico e entra na correção desde o dia 1. Usuário pode criar tópicos próprios.

## Gráficos

Reaproveitam os componentes SVG existentes (donut, área/barras), paleta `--c1..--c8` já validada para daltonismo:

1. Donut por tópico (detalhe da obra).
2. Barras de gasto mês a mês (detalhe da obra).
3. Barras horizontais comparando obras (início), bruto vs. corrigido.

## Fora de escopo (futuro, estrutura já comporta)

- Simulador "vender agora vs. depois": taxa composta mensal equivalente do lucro (`(venda/custo)^(1/meses) − 1`) comparada com a taxa do banco. Conexão direta com o valor corrigido: se venda > custo corrigido, bateu o banco.
- Foto de nota fiscal, relatório/PDF, multiusuário por obra, backup externo.

## Tratamento de erros e bordas

- Valor de gasto ≤ 0 ou vazio: bloqueia com mensagem simples.
- Data de gasto anterior à data de início da obra: permite (compra antecipada), sem aviso.
- Obra sem gastos: detalhe mostra estados vazios didáticos.
- Apagar obra: confirmação simples com aviso de quantos lançamentos serão perdidos junto.
- Obra vendida: não aceita novos gastos (voltar a fase para "pronta" se precisar corrigir algo).
- Números sempre em BRL, `font-variant-numeric: tabular-nums`, corpo ≥16px, valores-chave ≥24px (acessibilidade do PRODUCT.md mantida).

## Testes (manuais, app vanilla sem build)

- Conta da correção validada com exemplo canônico (10.000 → 10.615 em 6 meses).
- Fluxo completo: criar obra → lançar gastos em tópicos → marcar pronta → lançar gasto pós-pronta → registrar venda → conferir lucro bruto e vs. banco.
- Mudar taxa nos Ajustes e conferir recálculo.
- Offline: abrir sem rede após instalação PWA.
- `prefers-reduced-motion` e telas pequenas (Android do pai).

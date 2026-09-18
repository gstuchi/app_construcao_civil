# Drill-down por tópico na tela Gráficos — design

Data: 2026-08-24 · Aprovado por Giovani no chat.

Pedido de origem: na tela Gráficos, o donut mostra que Estrutura levou 12% /
R$ 101 mil, mas não há como ver *quais* gastos formam esse número sem voltar
pra lista de lançamentos e filtrar na mão. Clicar no tópico deve abrir só os
gastos dele.

## Comportamento

Na tela Gráficos, no painel "Gastos por tópico", cada item da legenda e cada
fatia do donut respondem ao toque. O toque abre a folha (sheet) com os gastos
daquele tópico, da obra aberta.

Conteúdo da folha:

- Cabeçalho: ícone e nome do tópico, botão de fechar.
- Resumo: `N gastos · X% da obra`, total bruto em destaque e o total corrigido
  logo abaixo, em tom secundário. O `X%` é a fatia do tópico sobre o total
  bruto da obra (`OBRA_CALC.totalBruto`), arredondado como na legenda do donut,
  pra bater com o número que ele acabou de tocar. Corrigido usa a regra do relatório —
  `OBRA_CALC.corrigido` de cada gasto, da data dele até a venda (se houver) ou
  hoje, com a taxa de `taxa()`.
- Lista: um `gastoRow(o, g)` por gasto, ordenada por data decrescente
  (`(b.data+b.id).localeCompare(a.data+a.id)`), igual à lista de lançamentos.

Editar e excluir funcionam de dentro da folha e voltam pra folha do tópico já
atualizada. Se o último gasto do tópico for excluído, a folha fecha em vez de
reabrir vazia.

Fora de escopo: filtro/busca dentro da folha, imprimir a folha, drill-down nos
outros gráficos (evolução, mês a mês), e drill-down em qualquer tela que não
seja Gráficos.

## Arquitetura

Três mudanças em `app.js`. Nenhuma escrita nova no Firestore — a tela é só
leitura sobre `db`, então não há migração de dados nem mudança nas rules.

### 1. `donutComLegendaHtml` marca os alvos; um bind novo amarra os cliques

`donutComLegendaHtml(entries, total, size)` mantém a assinatura e passa a
escrever `data-top="<id do tópico>"` em cada `<li>` da legenda e em cada
`<circle>` de fatia. Só isso — o helper continua devolvendo string e continua
sendo seguro pra qualquer chamador.

Função nova `bindDonutLegenda(container, onPick)`: varre `[data-top]` dentro do
container e liga `onclick` chamando `onPick(topicoId)`, mais `cursor:pointer`.
Segue o padrão já usado por `bindEvoChart` / `bindMesChart` — HTML primeiro,
bind depois de inserir. Quem não chamar o bind (hoje, ninguém além de
`renderGraficos`) não ganha comportamento novo.

`renderGraficos` passa a chamar
`bindDonutLegenda($('#grafBody'), id => sheetTopico(o.id, id))`.

### 2. `sheetTopico(obraId, topicoId)`

Função nova. Resolve a obra por id na hora (o snapshot da nuvem pode ter
trocado os objetos de `db` desde o render — mesma disciplina dos outros
handlers), filtra `o.gastos` pelo tópico, monta o HTML acima via `openSheet` e
anexa as linhas com `gastoRow(o, g, { voltar })`, onde
`voltar = () => sheetTopico(obraId, topicoId)`.

Se o tópico não tiver mais nenhum gasto, chama `closeSheet()` e retorna.

### 3. Retorno pra folha do tópico

`formGasto(obraId, gasto, valorInicial, aoFechar)` — quarto parâmetro
opcional. Quando presente, Salvar e Cancelar chamam `aoFechar()` em vez de
`closeSheet()`. O `save()` / `renderAll()` / `toast()` do Salvar continuam
acontecendo, na mesma ordem.

`gastoRow(o, g, opts)` — terceiro parâmetro opcional com `opts.voltar`.
Repassa pro `formGasto` no clique da linha, e usa nas três saídas da folha de
excluir parcela (excluir só esta, excluir a compra toda, cancelar), que hoje
chamam `closeSheet()` direto. A exclusão simples (sem `grupoId`) usa `confirm`
e não abre folha; depois de excluir, chama `voltar()` se existir.

Sem `opts`, `gastoRow` se comporta exatamente como hoje — é o que a lista de
lançamentos e o dashboard continuam usando.

## Riscos

O acerto do clique na **fatia** do donut depende de o navegador respeitar o
`stroke-dasharray` no teste de toque. Se falhar em algum aparelho, a legenda
continua funcionando; a legenda é o alvo real, já que no celular uma fatia de
0% é fina demais pra acertar com o dedo. Não vale código defensivo pra isso.

A folha é única no app (`openSheet` troca o `innerHTML`), então navegar
folha do tópico → formulário → folha do tópico é sempre remontagem, não
empilhamento. É por isso que o retorno é um callback e não um histórico.

## Testes

- Unit (`tests/calc.test.cjs`): nada novo — a mudança é de interface e reusa
  `OBRA_CALC.corrigido`, já testado.
- E2E manual com Playwright, conforme a skill `verify`, nos dois viewports
  (414×896 e 1440×900) e nos dois temas:
  1. Obra com gastos em ≥ 2 tópicos → abrir Gráficos → clicar num item da
     legenda → folha abre com a contagem, o % e os gastos certos, e nenhum
     gasto de outro tópico.
  2. Dentro da folha, editar um gasto e salvar → volta pra folha do tópico com
     o valor novo já refletido no resumo.
  3. Excluir o único gasto de um tópico → folha fecha e o tópico some do donut.
  4. Clicar numa fatia do donut → mesma folha do item de legenda correspondente.
- Regressão: lançar um gasto novo pelo botão `+` e editar um gasto pela lista
  de lançamentos continuam fechando a folha ao salvar, como hoje.

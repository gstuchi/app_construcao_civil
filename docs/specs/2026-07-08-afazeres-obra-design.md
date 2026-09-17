# Lista de afazeres dentro da obra — design

Data: 2026-07-08 · Aprovado por Giovani. Motivo: dentro da obra o pai quer
anotar o que falta fazer/comprar ("pagar pedreiro", "buscar tinta"), riscar
quando resolve e apagar. Checklist simples por obra, sem prazo nem valor.

## Dado

Novo campo na obra: `afazeres: []`. Cada item = `{ id, texto, feito }`:

- `id`: `uid()` (mesmo gerador dos gastos).
- `texto`: string, o afazer digitado (trim; vazio é ignorado).
- `feito`: boolean, default `false`.

Obras antigas não têm o campo → todo acesso usa `o.afazeres || []`; a primeira
escrita cria o array. Persistência via `save()` → `CLOUD.saveDados(db)`, tempo
real, como o resto do app. Sem migração em `empty()`/`normaliza()` (campo é
opcional por obra).

Pegadinha da nuvem (já conhecida): o snapshot troca os objetos de `db`. Os
handlers de clique **re-resolvem** obra por id (`obraById(obraAberta)`) e o
afazer por id na hora do clique — nunca guardam referência do render.

## UI e lugar

Painel "Afazeres" no detalhe da obra, **entre as Ações e os Gráficos**. Os 4
KPIs continuam no topo (regra "saldo em 5s" — nada compete com eles).

Painel:

- Título com contador: `Afazeres (N pendentes)`; sem pendentes → `Afazeres`.
- Linha de entrada: `<input>` texto + botão **+**. Enter no input também adiciona.
- `<ul class="list">` reusando o estilo dos lançamentos.
- Cada item (`<li>`): texto à esquerda (toque risca/desrisca), botão **X**
  (`li-del`, mesmo dos gastos) à direita apaga.
- Ordem: pendentes primeiro, feitos embaixo (dentro de cada grupo, ordem de
  inserção; novo pendente entra no topo dos pendentes).
- Item feito: `text-decoration:line-through` + opacidade reduzida.
- Vazio: "Nenhum afazer. Anote o que falta na obra."

## Comportamento

- **Adicionar:** trim; vazio ignora. Cria `{id, texto, feito:false}`, `unshift`
  no array. `save()` + re-render. Limpa o input e mantém o foco (adicionar
  vários seguidos).
- **Riscar:** toque no texto alterna `feito`. `save()` + re-render (item migra
  pro fim da lista).
- **Apagar:** X remove o item na hora, sem `confirm` (ação barata; pedido de
  "rapidinho"). `save()` + re-render.

## Isolamento e teste

- Função própria `renderAfazeres(o)`: monta o `<ul>` e liga os binds, chamada no
  fim de `renderObra` — mesmo padrão de `renderGastosFiltrados`. O HTML do painel
  (input + `<ul id="oAfazeres">`) entra no template de `renderObra`.
- CSS: reusa `panel`/`list`/`li-del`; só uma classe `.done` pra riscado.
- Bump do Service Worker pra `obras-v15` (senão o celular instalado serve versão
  velha — lição do bug de cache).
- E2E no padrão que funciona (puppeteer + Edge headless, viewport 1280×900,
  clique via `$eval(el=>el.click())`, esperar `#v-obra.active`, cuidar do
  overlay splash ~3.6s): entra na obra → adiciona 2 afazeres → risca 1 → apaga 1
  → recarrega → confere que persistiu (1 pendente + estado riscado). Regressões
  e unit continuam verdes.

## Fora de escopo (YAGNI)

Sem prazo/data, sem tópico, sem virar gasto, sem badge na lista de obras, sem
sugestão por fase. Só adicionar / riscar / apagar por obra.

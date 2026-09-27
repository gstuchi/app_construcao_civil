# Orçamento previsto × real — design

Data: 2026-09-26 · Escopo aprovado por Giovani no chat, a partir do mockup
`~/Documents/custta-mockups/orcamento.html` (três telas e quatro notas de decisão).

## Por quê

Hoje o Custta responde "quanto essa obra já custou", mas não "estou dentro do
que planejei?". O construtor define um orçamento antes de começar (às vezes só
o total, às vezes separado por etapa) e hoje faz essa conta de cabeça. A
funcionalidade põe o previsto ao lado do real, na obra, no Início e no push
diário, sem mudar nada para quem não usa.

## Regras do mockup (não negociáveis)

- **Cores calmas.** Verde-marca abaixo de 90%, âmbar de 90% em diante. Nunca
  vermelho (anti-referência do PRODUCT.md).
- **Um número por vez.** O card mostra só "gasto de previsto", a barra, o % usado
  e a sobra. O detalhe fica na lista por tópico.
- **Opcional.** Obra sem orçamento fica como hoje: sem card, sem barra, sem
  número. Sem migração e sem mudar regra do Firestore.
- **Base de comparação = valor bruto** (`OBRA_CALC.totalBruto`, que já inclui
  parcelas a vencer). O corrigido continua só nos KPIs.

## Dados

Campo novo e opcional dentro da obra, no blob `dados/{uid}`:

```js
o.orcamento = { modo: 'total', total: 800000 }
// ou
o.orcamento = { modo: 'topicos', topicos: { terreno: 180000, fundacao: 90000, ... } }
```

- `modo: 'total'`: um número só (`total > 0`).
- `modo: 'topicos'`: mapa `idDoTópico → valor > 0`. O previsto total é a soma.
  Vale para os tópicos fixos (`TOPICOS`) e para os próprios
  (`db.config.topicosCustom`).
- Sem orçamento = chave ausente. Salvar com tudo vazio apaga a chave.
- Ao salvar, grava só o modo ativo (trocar de modo e salvar descarta o outro).

`firestore.rules` só restringe as chaves do topo do blob (`obras`, `config`,
`_atualizado`), então o campo dentro da obra não pede mudança de rules.

**Normalização (`dados.js` → `obra()`).** `orcamento(v)` devolve o objeto limpo
ou nada:

- não é objeto → nada;
- `modo` diferente de `'topicos'` vira `'total'`;
- `total`: número finito > 0, senão o orçamento `total` é descartado;
- `topicos`: só entradas com id texto não vazio de até 80 caracteres
  (`LIMITES.topico`) e valor número finito > 0; no máximo 100 entradas; mapa
  vazio → descartado;
- campos desconhecidos são preservados (mesma política do resto do
  `normaliza`); a obra sem orçamento válido sai **sem** a chave `orcamento`
  (nada de `orcamento: null`), para `normaliza(d)` continuar idempotente e a
  obra antiga continuar igual.

## Cálculo (`calc.js`, puro, com teste)

`TOPICOS` sai de `app.js` e passa a morar em `calc.js` (`OBRA_CALC.TOPICOS`):
o push (Node) precisa do nome do tópico e não pode ter uma cópia que envelhece.
`app.js` passa a ler `const TOPICOS = OBRA_CALC.TOPICOS`.

`OBRA_CALC.orcamentoObra(obra)` → `null` sem orçamento válido, senão:

```js
{
  modo: 'total' | 'topicos',
  previsto,   // total previsto (soma dos tópicos no modo 'topicos')
  gasto,      // bruto comparado (ver abaixo)
  pct,        // Math.round(gasto / previsto * 100)
  sobra,      // previsto - gasto (negativo = passou)
  nivel,      // 'ok' | 'perto' | 'passou'
  topicos: [{ id, previsto, gasto, pct, sobra, nivel }], // só no modo 'topicos', pct desc
  fora: [{ id, gasto }],   // tópicos com gasto e sem previsto (só modo 'topicos'), gasto desc
  foraTotal,               // soma de `fora`
}
```

- **Gasto comparado.** Modo `total`: `totalBruto(obra)` inteiro. Modo `topicos`:
  soma dos gastos dos tópicos que têm valor previsto. Tópico com gasto e sem
  valor fica fora da comparação, mas aparece em `fora` para o dinheiro não
  sumir da tela.
- **Nível.** `passou` quando `gasto - previsto > 0,005` (meio centavo);
  senão `perto` quando `pct >= 90`; senão `ok`. O `pct` arredondado é o que a
  tela mostra, então cor e número nunca discordam (89,6% aparece "90%" e já é
  âmbar). Exatamente 100% é `perto` (âmbar), seguindo a regra escrita "âmbar
  de 90% em diante"; o Terreno verde a 100% do mockup é ilustração.

## Telas

### 1. Tela da obra (`renderObra`)

Com orçamento, entre o cabeçalho e os KPIs:

- **Card "Orçamento"** (`.panel.orc-card`): rótulo "Orçamento" + pill à direita
  ("dentro do previsto" verde; "perto do limite" ou "passou do previsto"
  âmbar); número grande "R$ 612.400,00 **de R$ 800.000,00**"; barra
  (largura `min(pct,100)%`, verde-marca ou âmbar); rodapé "**77%** usado" à
  esquerda e "sobra **R$ 187.600,00**" à direita (ou "passou **R$ …**").
- **"Por tópico"** (só no modo `topicos`): cabeçalho de seção e um painel com
  uma linha por tópico previsto: nome, "**R$ 98 mil** / 90 mil", barra fina e,
  quando for o caso, a frase: `passou` → "Passou R$ 8 mil do previsto" (âmbar);
  `perto` → "Faltam R$ 19 mil — 92%" (tom secundário; a 100% exato, "Chegou ao
  previsto — 100%"); `ok` → nada. Se houver `fora`, uma última linha "Fora do
  orçamento · R$ 12 mil" com os nomes dos tópicos embaixo, sem barra. Tocar numa
  linha de tópico abre a folha do tópico que já existe (`sheetTopico`) quando
  ele tem gasto.
- **Botão "Editar orçamento"** (`.btn.ghost`, largura cheia).

Sem orçamento: tudo como hoje, mais um único botão tingido "Definir orçamento"
na fileira de ações da obra (junto de "Ver gráficos" / "Relatório"), exceto em
obra vendida. É a porta de entrada para obras que já existem.

### 2. Início (`renderInicio`)

Cada obra com orçamento ganha, embaixo do subtítulo da linha, uma mini barra e
o texto: "77% do orçamento" (ok e perto; a barra fica âmbar a partir de 90%) ou
"104% · passou R$ 40 mil" (texto âmbar). Obra sem orçamento: linha idêntica à
de hoje.

### 3. Folha "Orçamento da obra" (`formOrcamento(obraId)`)

- Título "Orçamento da obra".
- Segmentado `.seg` "Só o total" / "Por tópico" (botões com `aria-pressed`). Abre
  no modo salvo; obra sem orçamento abre em "Só o total".
- **Só o total:** campo de dinheiro "Orçamento total".
- **Por tópico:** um painel com uma linha por tópico (fixos e próprios, na ordem
  de `topicos()`): nome à esquerda, campo de dinheiro à direita com placeholder
  "sem valor". Embaixo, faixa "Total" com a soma ao vivo e a dica "Tópico sem
  valor não entra na comparação."
- Campos com a máscara de dinheiro existente (`maskMoney`), `inputmode="decimal"`,
  fonte 16px (sem zoom no iOS).
- Rodapé padrão das folhas: "Cancelar" / "Salvar". Com orçamento existente, um
  botão destrutivo discreto "Tirar orçamento" confirma com `OBRA_CONFIRM.perguntar`.
- Salvar tudo vazio equivale a tirar o orçamento. Depois de salvar: `save()`,
  `closeSheet()`, `renderAll()`.

### 4. Nova obra (`formNovaObra`)

Campo "Orçamento total (opcional)" com máscara de dinheiro, depois de "Valor
estimado de venda". Preenchido (> 0) → `orcamento: { modo:'total', total }`.
Editar obra (lápis) não muda: o orçamento se ajusta pelo botão da tela da obra.

## Push diário

`notificacoes/resumo.js` ganha avisos de orçamento; o resto do resumo não muda.

**O que avisa.** Para cada obra não vendida com orçamento: o total e, no modo
`topicos`, cada tópico previsto. Frases:

- tópico `passou`: "Fundação passou R$ 8 mil do previsto"
- tópico `perto`: "Estrutura chegou a 92% do previsto"
- total `passou`: "Casa Alphaville passou R$ 40 mil do orçamento"
- total `perto`: "Casa Alphaville chegou a 92% do orçamento"

Com mais de uma obra não vendida com orçamento, a frase de tópico ganha a obra
entre parênteses: "Fundação (Casa Alphaville) passou R$ 8 mil do previsto". No
máximo 3 frases de orçamento; o excedente vira "+ N avisos de orçamento". As
frases de orçamento vêm antes das outras linhas do resumo (são as mais
importantes) e as obras delas entram na conta do atalho `obraId`.

**Regra de não repetir: avisa uma vez por subida de nível.** Cada item (obra ×
tópico, ou obra × total) tem nível `ok < perto < passou`. O push avisa só
quando o nível atual é **maior** que o último nível avisado daquele item. Ficou
no mesmo nível → silêncio, por dias. Subiu de `perto` para `passou` → avisa de
novo (é notícia nova). Desceu (aumentou o orçamento, apagou gasto) → a memória
desce junto, e uma nova subida volta a avisar.

**Onde fica a memória.** `perfis/{uid}.avisosOrcamento` — mapa
`"<obraId>|total"` / `"<obraId>|t:<topicoId>"` → `'perto' | 'passou'` (só
itens a partir de `perto`). Por que ali:

- o cron já lê `perfis/{uid}` (fuso);
- as rules do perfil já tornam campos fora da lista não graváveis pelo cliente
  (mesmo mecanismo do `plano`): update do cliente é por `affectedKeys()`, então
  o campo escrito pelo Admin SDK não quebra salvar nome/fuso;
- apagar a conta já apaga `perfis/{uid}`: a memória vai junto.
- `push/{uid}` **não** serve: as rules dele exigem `keys().hasOnly(['subs','tokens'])`
  no documento inteiro, e um campo a mais quebraria a inscrição de push do
  cliente.

O Admin SDK só atualiza o perfil se ele existir (nunca cria perfil, o que
confundiria o fluxo de "completar perfil"). Sem perfil não há memória, e então
não há aviso de orçamento para essa conta (silêncio é melhor que repetição).

**Quando grava.** `enviaTodos` calcula o estado novo (níveis atuais ≥ `perto`).
Se o resumo saiu e ao menos um aparelho recebeu, grava. Se não havia nada a
dizer, grava também (só pode ter sido descida). Se todos os envios falharam, não
grava: o aviso tenta de novo no próximo disparo. Conta sem aparelho inscrito
não é visitada, então quem liga o push depois recebe o estado atual uma vez.

Funções puras novas em `resumo.js`, com teste: `estadoOrcamento(dados)` e
`avisosOrcamento(dados, anterior)`; `montaResumo(dados, hojeISO, periodo,
anterior)` ganha o 4º parâmetro (ausente/`null` = sem memória = sem aviso de
orçamento, o que mantém os chamadores e testes atuais iguais). `resumo.js` passa
a usar `../calc.js` e `../dados.js` (o cron roda no checkout inteiro e a Vercel
rastreia `require` relativo).

## Fora de escopo

Orçamento no relatório/gráficos, histórico de revisões do orçamento, orçamento
corrigido pelo banco, alerta dentro do app, orçamento por mês, cópia de
orçamento entre obras.

## Testes

- `tests/calc.test.cjs`: `orcamentoObra` (sem orçamento, modo total, modo
  tópicos, limites 89,6/90/100/100,01%, `fora`, parcela futura conta, tópico
  próprio), `TOPICOS` exportado.
- `tests/dados.test.cjs`: normalização do `orcamento` (valores inválidos,
  negativos, ids vazios/longos, modo desconhecido, idempotência, obra sem
  orçamento continua sem a chave).
- `tests/resumo.test.cjs`: frases, nível subindo/estável/descendo, limite de 3
  frases, obra vendida ignorada, sem memória = sem aviso, obraId.
- `tests/enviar.test.cjs`: grava a memória só depois de entregar, não cria perfil,
  não grava quando tudo falhou.
- `tests/rules.test.mjs`: cliente atualiza nome com `avisosOrcamento` presente
  no perfil; cliente não grava `avisosOrcamento`.
- `tests/browser/orcamento.cjs` (dados sintéticos, `CLOUD` falso, sem rede):
  card, lista, Início, folha nos dois modos com soma ao vivo, Nova obra,
  obra sem orçamento igual, sem rolagem horizontal de 320 a 1440px, contraste
  do texto âmbar nos 4 combos tema × skin, sem violação de CSP.
- Validação manual no WebKit do Playwright (folha e foco) e no agent-browser
  contra a prévia da Vercel com `CLOUD` falso.

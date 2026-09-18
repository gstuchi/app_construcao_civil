# Tela de valor com teclado próprio

Data: 2026-08-12

## Problema

No iPhone, lançar um gasto é ruim. O teclado do iOS não encolhe a viewport de
elementos `position:fixed`, então metade do sheet fica atrás do teclado. Já
mitigamos com `visualViewport` (`--vvh`/`--vvtop`), mas o campo Valor continua
sendo o pior: é o primeiro campo, é o mais importante, e é justamente onde o
teclado do sistema atrapalha mais.

## Solução

O valor deixa de ser um campo dentro do sheet e vira uma tela própria, com
teclado numérico desenhado pelo app. O teclado do iOS nunca abre nesse fluxo
porque o display é uma `<div>`, não um `<input>`.

## Alcance

Só o fluxo de **novo gasto pelo FAB (+)**, que só existe dentro da obra, na tela
de Lançamentos. Não muda:

- editar gasto (tocar na lista) — abre o sheet direto, campo de valor normal
- valor estimado de venda (nova obra / editar obra)
- registrar venda

## Fluxo

```
FAB (+)
  └─ tela de valor  ──[Avançar]──>  sheet do gasto (valor já preenchido)
       │                                  │
       └─[X] cancela tudo                 └─[toca no valor] volta pra tela de valor
```

- `X` no topo da tela de valor cancela o lançamento inteiro.
- No sheet, o valor no topo vira botão. Tocar nele reabre a tela de valor com o
  número atual carregado; confirmar volta pro sheet preservando o que já foi
  escolhido (tópico, pagamento, parcelas, descrição, data).

## Tela de valor

Ocupa a área visível via `--vvh`. Três faixas empilhadas: display no topo,
teclado no meio, `Avançar` embaixo.

Teclado 3×4:

```
[7] [8] [9]
[4] [5] [6]
[1] [2] [3]
[00][0] [⌫]
```

`Avançar` fica desabilitado enquanto o valor for R$ 0,00.

## Entrada de dígitos

Estilo maquininha: os dígitos entram pela direita, centavos primeiro. Não existe
tecla de vírgula.

```
toca 1   -> R$ 0,01
toca 2   -> R$ 0,12
toca 5   -> R$ 1,25
toca 0   -> R$ 12,50
⌫        -> R$ 1,25
```

O estado é um inteiro em **centavos**, o que evita erro de ponto flutuante na
digitação. Converte pra reais só na saída.

Teto de R$ 99.999.999,99 (9.999.999.999 centavos). Tecla que estouraria o teto é
ignorada em vez de truncar, pra não mudar o número em silêncio.

## Arquitetura

Arquivo novo `teclado.js`, no mesmo padrão de `calc.js`: IIFE que exporta via
`module.exports` no Node e `window.TECLADO` no browser.

Duas camadas separadas:

**Lógica pura** (testável sem DOM):

```js
TECLADO.aplicarTecla(centavos, tecla) -> centavos   // tecla: '0'..'9' | '00' | 'del'
TECLADO.fmtCentavos(centavos)         -> '1.250,00'
TECLADO.centavosParaReais(centavos)   -> 1250.5
TECLADO.reaisParaCentavos(reais)      -> 125050
```

**Camada de tela**:

```js
TECLADO.abrir({ valorInicial, onConfirm, onCancel })
```

`valorInicial` e o argumento de `onConfirm` são reais (número), não centavos — a
fronteira do módulo fala a mesma língua do resto do app.

`app.js` muda em dois pontos: o `onclick` do FAB e a assinatura de `formGasto`,
que passa a aceitar um valor inicial e a pintar o topo como botão quando não é
edição.

## Testes

`tests/teclado.test.cjs`, mesmo formato dos existentes (`node tests/*.cjs`):
digitação sequencial, `00`, apagar, apagar até zero, apagar em zero, teto,
formatação de milhar, ida e volta reais↔centavos.

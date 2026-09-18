# Tema claro / escuro (day mode / night mode)

**Data:** 2026-07-09
**Status:** aprovado pelo Giovani (posição: tela Ajustes; padrão: escuro)

## Objetivo

Permitir alternar entre tema escuro (atual, continua padrão) e tema claro, com um
toggle animado estilo pílula (lua/sol deslizando) na tela Ajustes. Preferência salva
por aparelho. Sem framework: HTML/CSS/JS puro, coerente com "Offline é sagrado".

## Contexto

- Todas as cores da UI vivem em CSS variables no `:root` (`index.html:22-33`).
- Os gráficos canvas leem cores via `getComputedStyle(document.documentElement)`
  (`app.js:356`, `app.js:684`) — seguem o tema automaticamente, só precisam de
  re-render após a troca.
- Referência visual do usuário: componente React/shadcn "theme-toggle" (pílula
  64×32px, bolinha com lua/sol desliza, transição 300ms). Será portado pra
  vanilla CSS/JS com o mesmo visual; React NÃO será instalado.
- `PRODUCT.md` princípio 4 dizia "tema único dark"; decisão revisada pelo dono
  do produto — o princípio passa a ser "Dark é o padrão; claro é opção".

## Design

### 1. Paleta clara

Novo bloco `html[data-theme="light"]` sobrescrevendo as variáveis do `:root`:
fundo branco-gelo (`#f3f6fc`-ish), superfícies brancas, texto azul-escuro,
`--muted` com contraste ≥4.5:1, soft-colors (`--*-soft`) em tons pastel claros,
série de gráficos (`--c1..--c8`, `--chart-rec`, `--chart-desp`) escurecida o
suficiente pra contraste em fundo claro (validar com dataviz/contraste).
`--shadow` mais suave. Valores exatos definidos na implementação com checagem
de contraste.

Ajustes fora das variáveis:

- Gradientes radiais do `body` (glow azul/roxo): versão clara mais sutil via
  override no bloco light.
- Globo de fundo (`globe.js`, azuis fixos): em tema claro, canvas `#globe`
  recebe `opacity` reduzida via CSS — sem mexer no globe.js.
- Card saldo negativo com gradiente hardcoded (`app.js:847`): manter — gradiente
  escuro com texto branco funciona nos dois temas (conferir contraste no claro).
- `<meta name="theme-color">`: atualizada via JS conforme tema (barra do PWA).

### 2. Toggle pílula (porte do componente)

- Pílula 64×32px, `border-radius` total, borda 1px; bolinha 24px desliza
  esquerda↔direita com `transition: transform .3s`; ícone lua (escuro) / sol
  (claro) trocam; ícone oposto esmaecido no lado vazio. Mesmo visual do
  componente de referência.
- Ícones: SVGs inline de lua e sol adicionados ao `icons.js` (padrão existente
  `data-ico`).
- Acessibilidade: `role="switch"`, `aria-checked`, foco visível, acionável por
  teclado (Enter/Espaço), alvo de toque ≥44px (padding em volta da pílula).
- `prefers-reduced-motion`: transição instantânea.

### 3. Localização na UI

Tela Ajustes (`index.html` seção `v-ajustes`), novo painel **"Aparência"**
inserido antes do painel "Conta": label "Tema" + toggle à direita.

### 4. Lógica

- Chave `localStorage` própria (ex.: `mo_tema`), por aparelho — NÃO sincroniza
  com Firebase (preferência de dispositivo, não dado do usuário).
- Script inline mínimo no `<head>`, antes do CSS, aplica
  `document.documentElement.dataset.theme` a partir do localStorage — evita
  flash do tema errado no load.
- Clique no toggle: alterna `data-theme`, salva no localStorage, atualiza
  `<meta theme-color>`, dispara re-render da tela ativa (gráficos releem as
  variáveis).
- Sem escolha salva: escuro (comportamento atual intocado).

### 5. Fora de escopo (futuro)

- Animação de transição elaborada entre temas (usuário vai mandar referência
  depois). Na v1 a troca de tema é seca (sem transição de cores na página);
  só a bolinha do toggle anima.
- Opção "seguir sistema" (prefers-color-scheme).

## Erros e casos-limite

- localStorage indisponível (Safari private antigo): try/catch, cai no escuro.
- Valor inválido na chave: trata como ausente (escuro).
- Splash screen (`splash.js`) e tela de login: devem respeitar o tema salvo
  (script no head roda antes de tudo, então já cobre).

## Testes / verificação

- Toggle alterna tema e persiste após reload.
- Sem flash de tema errado no load (testar com claro salvo).
- Gráficos (donut, evolução) redesenham com cores certas após troca.
- Contraste AA nos dois temas (texto, muted, chips soft, série de gráfico).
- PWA: barra de status muda de cor conforme tema.
- `prefers-reduced-motion` desliga animação da bolinha.

## Arquivos tocados

- `index.html` — bloco light de variáveis, painel Aparência, script no head,
  CSS do toggle.
- `icons.js` — ícones lua/sol.
- `app.js` — handler do toggle em `renderAjustes()`, re-render pós-troca.
- `PRODUCT.md` — princípio 4 atualizado.

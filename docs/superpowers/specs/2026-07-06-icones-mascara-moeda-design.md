# Ícones minimalistas + máscara de moeda — design

Data: 2026-07-06 · Aprovado por Giovani no chat.

## Objetivo

Deixar o app com cara profissional: (1) substituir **todos** os emojis da interface
por ícones SVG de linha (estilo Lucide); (2) campos de valor em dinheiro formatam
enquanto o usuário digita (`2000000` → `R$ 2.000.000,00`).

## Parte 1 — Ícones

### Abordagem

SVG embutido no próprio site (sem CDN, sem fonte de ícones, sem arquivos de imagem
separados) — obrigatório porque o app é PWA offline e o service worker só cacheia
assets locais. Novo arquivo `icons.js`:

- Objeto com os paths SVG por nome (traço `stroke="currentColor"`, `fill="none"`,
  `stroke-width="2"`, viewBox 24×24 — padrão Lucide).
- Função global `ICON(nome, cls)` que devolve a string `<svg class="ico ...">…</svg>`
  pra interpolar nos templates (`innerHTML`), padrão que o app.js já usa.
- Cor vem de `currentColor` — as classes existentes (`ic-green`, `ic-blue`,
  `ic-brand`, `k-ic`) continuam mandando na cor. Nada de cor nova.

`icons.js` entra no `index.html` antes de `app.js`/`auth.js` e na lista `ASSETS`
do `sw.js` (bump do nome do cache).

### Inventário de substituição (todos os emojis somem)

| Onde | Emoji hoje | Ícone |
| --- | --- | --- |
| Logo (sidebar + header) | 🏗️ | guindaste/prédio em obra |
| Menu: Obras / Vale a pena? / Ajustes / Sair | 🏗️ 🤔 ⚙️ 🚪 | prédio, balança, engrenagem, log-out |
| Botão sair (header e Ajustes) | 🚪 | log-out |
| KPIs | 💰 💸 🏦 🎯 🤝 ↑ | moedas, seta-saída, banco/prédio-colunas, alvo, aperto de mão, seta-cima |
| Fases (`FASES`) | 🏗️ 🏠 ✅ | guindaste, casa, check |
| Tópicos de gasto (`TOPICOS`, 14) | 🗺️ 📐 ⛏️ 🏗️ 🧱 🏠 ⚡ 🚿 🚪 🪨 🎨 🌳 👷 📦 | mapa, régua/esquadro, picareta, guindaste, tijolos, telhado, raio, gota/chuveiro, porta, pedra/camadas, rolo de tinta, árvore, capacete, caixa |
| Tópico desconhecido | 🏷️ | etiqueta |
| Pagamento | 💳 ⚡ | cartão, raio (Pix) |
| Botões de ação | ✏️ 📄 🖨️ ↩ | lápis, documento, impressora, seta-voltar |
| Telas vazias | 🏗️ 🧾 📅 | guindaste, recibo, calendário |
| Simulador (título e veredito) | 🤔 ✅ ⚠️ | balança, check, alerta |
| Aviso instalar | 📲 | celular com seta |
| Olho da senha | 👁 🙈 | eye / eye-off |
| Dica "Role para entrar ↓" | ↓ | seta-baixo (SVG ou entidade estilizada) |
| Relatório impresso | 🤝 🎯 e ícones de tópicos | mesmos ícones (imprimem bem em linha) |

Estética atual (dark, globo, cores) não muda — decisão do pai, intocável.

## Parte 2 — Máscara de moeda

### Comportamento (decidido pelo Giovani)

- Dígitos digitados são **reais inteiros**; pontos de milhar aparecem ao vivo:
  `2000000` exibe `2.000.000`.
- Centavos só se digitar vírgula: `2500,5` exibe `2.500,5`.
- Ao sair do campo (blur), completa centavos: `2.000.000,00` / `2.500,50`.
- Prefixo **R$** fixo, fora do valor digitável (span dentro do `.field`, à esquerda
  do input) — o `value` do input carrega só `2.000.000,00`, que o parser atual
  (`app.js:62`, aceita `2.000,50`) já entende sem mudança.
- Apagar tudo deixa vazio (placeholder `0,00`).
- Cola de texto: mantém só dígitos e a primeira vírgula, reformata.

### Campos que recebem a máscara

Todos os inputs de dinheiro (`inputmode="decimal"`):

- `#fVal` — lançar gasto, editar gasto, registrar venda
- `#fEst` — valor estimado de venda (criar e editar obra)
- `#simValor` — simulador "Vale a pena?"

Campos que **não** recebem: `#ajTaxa` (é %, não R$), `#simMeses`, `#cCpf`.

Inputs que abrem já com valor salvo (ex.: editar gasto, `#fEst` com
`o.valorEstimadoVenda`) aparecem já formatados.

Função única `maskMoney(input)` (em `app.js`, perto do parser) aplicada a cada
campo na criação do modal — sem duplicação por modal.

### Dados

Nada muda no que é salvo na nuvem: número continua número no blob. Máscara é só
apresentação na digitação.

## Testes

- Unit (padrão `tests/calc.test.cjs`): formatação — `"2000000"→"2.000.000"`,
  blur `"2500,5"→"2.500,50"`, parse de volta bate com o número original.
- E2E no site rodando: digitar `2000000` num gasto e ver `R$ 2.000.000,00`;
  varrer a página renderizada e garantir **zero emoji** sobrando (regex de faixas
  Unicode de emoji, mesma usada no levantamento).
- Visual: conferir sidebar, KPIs, lista de gastos, relatório de impressão.

## Fora de escopo

Simulador "vender agora vs. depois", fotos de nota, PDF, backup — ficam pra depois.

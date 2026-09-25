# Custta com cara e toque de app iOS

Data: 2026-09-25. Primeiro retorno de uso real do app instalado pelo TestFlight (PR #17): "parece web meio travado".

## O que o Giovani apontou (print do iPhone, obra aberta)

- Cards, busca, filtro de mês e o botão + cortados na borda direita.
- Conteúdo rolando por baixo do relógio e da bateria, sem barra cobrindo.
- Barra de abas de baixo com cara de site.
- Fundo pontilhado (globo) aparecendo atrás e através dos cards.

## Diagnóstico

1. **O corte à direita é o zoom automático do iOS.** A busca e o filtro de mês (`.filter-row`) têm fonte de 14px, e `.field input` fora dos sheets tem 15px. Ao tocar num campo com fonte abaixo de 16px, o iOS amplia a página e não desfaz. No Chromium a 390px a largura do documento é exatamente 390: não existe transbordo de layout.
2. **A capa da barra de status só existe no PWA.** O `body::after` que cobre `safe-area-inset-top` está dentro de `@media (display-mode: standalone)`. No WKWebView do Capacitor esse media query não casa.
3. **O "travado" vem do fundo.** `background-attachment: fixed` no `body` (que o iOS repinta a cada quadro de rolagem) somado ao canvas do globo animado em `requestAnimationFrame` atrás de tudo.
4. **As barras são de site.** A barra de abas é sólida e tem botões arredondados; o cabeçalho é uma logo que rola junto; o "‹ Voltar" é um link solto no conteúdo.

## Decisões (tomadas com o Giovani)

- **Escopo: app e site no celular, com uma base só.** O pai usa o PWA instalado pelo Safari; mudar só o app deixaria ele no visual antigo. O desktop (≥900px, com a barra lateral) não muda.
- **Referência: apps da Apple** (Ajustes, Carteira, Saúde): título grande que vira título pequeno ao rolar, barras translúcidas com desfoque, listas agrupadas, toque com resposta imediata.
- **Globo: fica.** O Giovani avaliou que o globo não é o problema — e ele é a identidade (PRODUCT.md, "Wow que não cansa"). O que muda é o custo e a interferência: as superfícies de conteúdo ficam opacas (os pontos não aparecem através dos cards), o laço de animação pausa durante a rolagem e o toque (retoma após ~400ms parado) e quando a página está oculta.
- **Gestos:** arrastar o gasto para a esquerda para apagar; puxar o sheet para baixo para fechar; arrastar da borda esquerda para voltar; vibração leve no app nativo.
- **Mantém:** tema escuro como padrão, tema claro e as duas cores (esmeralda e azul), letra generosa (corpo ≥16px, números grandes), alvos ≥44px, offline, vanilla sem build, CSP estrita.

## Desenho

### 1. Fundação (vale em todo celular)

- Todo `input`, `select` e `textarea` com fonte ≥16px no celular, e `maximum-scale=1` no `<meta viewport>`. As duas coisas juntas: a fonte é a correção de verdade; o `maximum-scale` impede o zoom de foco no WKWebView e o Safari continua permitindo pinça (acessibilidade).
- `nativo.js` marca `<html class="nativo">` no `<head>` quando está no Capacitor; `tema.js` marca `standalone` quando `display-mode: standalone` ou `navigator.standalone`. A capa da barra de status passa a valer para `.nativo` e `.standalone`.
- Fundo: sem `background-attachment: fixed` no celular; o brilho vira uma camada `position: fixed` própria, pintada uma vez.
- Globo: continua em todas as telas. `globe.js` pausa o laço enquanto há rolagem ou toque (retoma ~400ms depois do último evento) e quando `document.hidden`; o canvas não muda de tamanho durante a rolagem (sem `resize` disparado pela barra do Safari recolhendo). As superfícies de conteúdo (`--surface` do celular) ficam opacas.
- Chrome de interface sem seleção de texto nem menu de toque longo (`-webkit-user-select: none`, `-webkit-touch-callout: none`) em botões, barras, cabeçalhos e linhas de lista; campos e textos de dados continuam selecionáveis.
- Toque: todo elemento tocável tem `:active` imediato (opacidade/realce de linha), sem `transition` de entrada no press.

### 2. Barras no estilo iOS

- **Barra de navegação** no topo de cada tela, fixa, cobrindo também a área do relógio: título grande (34px, peso 700) no conteúdo; ao rolar além dele, a barra ganha material translúcido com desfoque e mostra o título pequeno (17px, peso 600) centralizado, com linha fina embaixo. Na tela da obra, à esquerda, o botão "‹ Obras" substitui o "‹ Voltar" solto. À direita, o indicador de sincronização. Títulos: Obras, nome da obra, Relatório, Gráficos, Vale a pena?, Ajustes.
- **Barra de abas:** material translúcido com desfoque e linha fina em cima, altura 49px + área segura, ícones 25px e rótulos 11px, cor ativa da marca, sem fundo arredondado no botão; ao tocar, só a opacidade responde.
- Material translúcido por combinação tema × cor: cada bloco que define `--bg` define também `--barra` (cor do material, com alfa). Sem `color-mix`, que o WKWebView do iOS 15 não tem.
- O botão + (FAB) continua, na mesma função, com sombra discreta e posição sempre acima da barra de abas.

### 3. Conteúdo

- Painéis e cards viram grupos no estilo "inset grouped": cantos 14px, sem borda grossa nem sombra pesada, superfície levemente elevada sobre o fundo; título da seção (o `h2` do painel) com peso 600.
- Listas: linha com altura mínima de 56px, separador fino recuado a partir do texto (não atravessa o ícone), realce da linha inteira ao tocar; linhas que abrem outra tela (lista de obras) ganham chevron "›".
- Busca no estilo iOS: campo arredondado com lupa, 16px, e o filtro de mês como botão de menu ao lado.
- Botões: primário preenchido e secundário tingido, cantos 12px, altura ≥50px.
- Sheets: alça ("grabber") no topo, cantos 14px, fundo sólido do tema.
- Transições: abrir a obra desliza da direita; voltar desliza para a direita; troca de aba é um fade curto. Tudo desligado com `prefers-reduced-motion`.

### 4. Gestos (`gestos.js`, novo)

Um arquivo novo, carregado depois do `app.js`, com a lógica pura exportada para `node --test` (padrão de `nativo.js` e `share.js`) e a ligação ao DOM por delegação de eventos, sem mexer nos renderizadores.

- **Arrastar para apagar:** em `li.gasto-row` (e demais linhas que têm `.li-del`), arrastar para a esquerda revela um botão vermelho "Apagar" (80px). Soltar além da metade deixa aberto; tocar em "Apagar" dispara o mesmo `.li-del` de hoje (com o diálogo de confirmação atual e o fluxo de parcelas). Abrir outra linha, tocar fora ou rolar fecha a que estava aberta. Gesto só horizontal: se o movimento começar vertical, é rolagem e o gesto não assume. Em telas de toque o "×" some da vista, mas continua no DOM, acessível ao VoiceOver e ao teclado.
- **Puxar para fechar o sheet:** arrastar para baixo a partir da alça ou do topo do sheet (com `scrollTop` 0). Passou de 120px, ou soltou rápido para baixo, chama `closeSheet()`; senão volta com mola. Não vale para diálogos `<dialog>` de confirmação.
- **Voltar arrastando da borda:** toque que começa nos primeiros 24px da borda esquerda, na tela da obra (ou relatório/gráficos), arrastando para a direita além de 35% da largura (ou rápido) aciona o "voltar" da tela, com a tela acompanhando o dedo. Só no app nativo e no PWA instalado: no Safari comum a borda é o "voltar" do navegador.
- **Vibração leve** (via `OBRA_NATIVO.vibrar`, que no browser não faz nada): ao trocar de aba, ao revelar "Apagar" e ao fechar um sheet pelo gesto.
- Todos os gestos com `touch-action`/`passive` corretos para não travar a rolagem.

### 5. Service worker e empacotamento

`gestos.js` entra em `ASSETS` do `sw.js` (que também alimenta `build-www`), `CACHE` incrementa, e o `<script>` entra no `index.html` depois do `app.js`.

## Testes e validação

- Unitários (`node --test`): lógica pura dos gestos (decisão horizontal × vertical, limiares de abrir/fechar/voltar por distância e velocidade).
- Guardas de CSS/HTML: nenhuma regra de `input`/`select`/`textarea` abaixo de 16px no celular; `maximum-scale=1` no viewport; `gestos.js` em `ASSETS` e no HTML; sem `background-attachment: fixed` fora do desktop.
- Playwright (`tests/browser/mobile.cjs` e `nativo.cjs`, 390×844, toque): nenhum campo abaixo de 16px em cada tela; largura do documento = largura da tela em todas as telas; capa da barra de status visível no nativo; globo presente e laço pausado durante rolagem; título grande colapsa ao rolar; arrastar gasto revela "Apagar" e o apagar passa pelo diálogo; puxar sheet fecha; arrastar da borda volta da obra para Obras; `contraste.cjs` continua passando nos quatro combos.
- Suíte unitária inteira verde; CI do PR verde.
- agent-browser no preview da Vercel, viewport de iPhone, claro e escuro: capturas de Obras, obra aberta, sheet de gasto, Vale a pena? e Ajustes.
- Build no TestFlight a partir da branch (`gh workflow run ios-testflight.yml --ref feat/ios-nativo`) para o Giovani sentir no aparelho antes do merge.

## Fora do escopo

Desktop, telas de login/cadastro (só herdam a correção de fonte e de zoom), novas funcionalidades, login com Apple.

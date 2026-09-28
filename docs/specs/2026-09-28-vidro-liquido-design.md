# Custta no padrão Apple com Liquid Glass

Data: 2026-09-28. Continuação do visual iOS do PR #18 (título grande, abas translúcidas, listas agrupadas, gestos). O pedido do Giovani: "atualize toda a interface para a interface Apple e aplique Liquid Glass onde a Apple sugerir".

## O que é o Liquid Glass e onde a Apple manda usar

Liquid Glass é o material do iOS 26 / macOS Tahoe: uma camada translúcida que desfoca e satura o que passa por baixo, com um brilho fino na borda (a luz batendo no vidro) e sombra suave. A regra central das diretrizes da Apple é **vidro só na camada de navegação e de controle, que flutua acima do conteúdo** — barra de abas, barras de ferramentas e seus botões, barra lateral, sheets, alertas, menus e botões flutuantes. **O conteúdo nunca é de vidro**: listas, cards, tabelas e gráficos continuam opacos. E nunca vidro sobre vidro.

Complementos que andam junto no iOS 26: barra de abas como cápsula flutuante, botões de barra como cápsulas/círculos de vidro, sheets flutuando descoladas das bordas com cantos grandes, botões de ação em cápsula, "efeito de borda de rolagem" (o conteúdo some num esfumado sob a barra, em vez de uma linha dura) e movimento com mola.

## Decisões

Tomadas com o Giovani (2026-09-28):

- **Escopo: tudo.** Celular (app iOS + PWA), desktop ≥900px no estilo macOS Tahoe, login e cadastro, sheets, diálogos, teclado de valor e avisos. Uma linguagem visual só.
- **Barra de abas: cápsula de vidro flutuante com o botão + separado**, um círculo de vidro tingido à direita dela (como a busca nos apps Música e Fotos do iOS 26). O FAB redondo sobre o conteúdo deixa de existir no celular.
- **Entrega:** PR com commits separados, CI verde, prévia da Vercel conferida no agent-browser e build da branch no TestFlight. O merge é do Giovani, depois de sentir no iPhone.

Tomadas por mim, com o motivo:

- **A cápsula não encolhe ao rolar.** No iOS 26 isso é opcional (Música e Notícias usam); aqui o usuário principal é o pai do Giovani, não técnico, e esconder as abas custa descoberta sem ganho real numa tela curta.
- **Sem refração de verdade (lente com distorção via filtro SVG).** Só o Chromium aplica `backdrop-filter: url(#filtro)`; o Safari e o WKWebView, que são o alvo, não. O vidro é desfoque + saturação + brilho de borda + sombra, que é o que o Safari renderiza bem.
- **Mola sem biblioteca.** PRODUCT.md exige vanilla sem dependência de runtime. As molas viram curvas CSS `linear()` geradas por um script puro a partir dos dois parâmetros da Apple (amortecimento e resposta), com `cubic-bezier` de recuo para WebKit antigo.
- **Globo, tema escuro padrão, as duas cores (esmeralda e azul), letra generosa e alvos ≥44px ficam.** O vidro fica melhor justamente sobre fundo com cor e movimento — o globo é o que dá vida ao material.
- **`privacidade.html` e o splash de abertura ficam como estão.** Não são interface de uso (uma é página legal, o outro já é animação de marca própria).

## Desenho

### 1. Material (tokens em `styles.css`)

Cada bloco de tema×cor que hoje define `--barra` passa a definir o material inteiro. Sem `color-mix` (o WKWebView do iOS 15 não tem).

| Token | Papel |
| --- | --- |
| `--vidro` | preenchimento do vidro comum (cor do tema com alfa) |
| `--vidro-folha` | preenchimento mais denso para sheets e diálogos (formulário por cima precisa de leitura) |
| `--vidro-tinta` | vidro tingido da marca (botão +, ação primária flutuante), com `--fab-ink` como tinta |
| `--vidro-brilho` | sombra interna que desenha a borda de luz (1px claro em cima + contorno de .5px) |
| `--vidro-sombra` | sombra externa suave, mais funda quanto maior a superfície |
| `--vidro-filtro` | `saturate(180%) blur(24px)`; sheets e barra lateral usam `blur(40px)` |

Uma classe utilitária não é criada; os seletores que podem ter vidro são uma lista fechada (abaixo), e um teste garante que `backdrop-filter` só aparece neles.

**Onde há vidro:** cápsula de abas e botão +; botões da barra de navegação (voltar, sair, pílula de sincronização); barra lateral do desktop; sheets; diálogos (`<dialog>` de conta e de confirmação); toasts; o cartão do login/cadastro; o fundo da tela de valor (teclado).

**Onde não há:** painéis, cards, listas, KPIs, gráficos, campos, chips, avisos de instalar/notificação/e-mail. Seguem opacos (`--surface-solid` no celular, como já estão).

**Acessibilidade do material:**

- `prefers-reduced-transparency: reduce` → vidro vira sólido (`--surface-solid`), sem `backdrop-filter`.
- `prefers-contrast: more` → vidro quase sólido com contorno de 1px em `--line-strong`.
- Sem suporte a `backdrop-filter` (`@supports not`) → mesmo recuo sólido.
- Contraste: rótulo inativo das abas e texto dos botões de barra ≥4,5:1 sobre o pior fundo que passa por baixo (o card de saldo), nos quatro combos. O alfa do `--vidro` é ajustado até passar em `contraste.cjs`, como foi feito com o `--barra` no PR #18.

### 2. Barra de abas e botão + (celular, <900px)

- `nav.tabs` vira uma cápsula flutuante: 62px de altura, cantos 31px, 12px das bordas laterais, base em `max(12px, safe-area-inset-bottom − 10px)` acima do rodapé, material `--vidro`. Sem linha no topo.
- Aba selecionada: um realce em cápsula (lente) atrás do ícone e do rótulo, que **desliza** de uma aba para outra com mola (o `nav.tabs` ganha `data-aba` com o índice, e a lente se move por `transform`). Ícone e rótulo da selecionada na cor da marca.
- Ao tocar, a aba responde no toque (sem esperar soltar): a lente cresce levemente.
- O botão + (`#fab`) vira um círculo de vidro tingido de 62px, alinhado à base da cápsula, 10px à direita dela. Aparece em **Obras** ("Nova obra") e **na obra** ("Lançar gasto"); nas outras telas some e a cápsula ocupa a largura toda, com a borda direita deslizando com mola. `aria-label` acompanha a ação.
- O "+ Nova obra" dentro do conteúdo some no celular (o + da barra faz a mesma coisa); o texto da lista vazia vira "Toque no + pra criar a primeira obra.". No desktop o botão do conteúdo fica.
- Esfumado de borda embaixo: uma faixa fixa de ~90px com gradiente do `--bg` para transparente atrás da cápsula, para o conteúdo sumir suave em vez de cortar sob o vidro.
- Toasts sobem para acima da cápsula e viram cápsulas de vidro.

### 3. Barra de navegação (celular e desktop)

- `header.top` fica sem material próprio. Os itens viram botões de vidro: voltar como cápsula "‹ Obras" (44px de altura), sair como círculo de 44px, e a pílula de sincronização como cápsula de vidro.
- Ao rolar (a classe `colapsada` que já existe), em vez de a barra ganhar fundo e linha, aparece o **efeito de borda de rolagem**: esfumado do `--bg` para transparente com desfoque progressivo (`mask-image` em gradiente sobre uma camada com `backdrop-filter`), e o título pequeno centralizado.
- Título grande continua (34px, 700). Tracking por tamanho: `-0.02em` nos títulos grandes, 0 no corpo.

### 4. Sheets, diálogos e tela de valor

- **Sheet no celular:** flutua descolada, 8px das laterais e da base (mais a área segura embaixo), cantos de 32px (concêntricos com a tela do iPhone), material `--vidro-folha` com `blur(40px)`, alça no topo. Quando o conteúdo passa de 88% da altura visível, a sheet vira folha cheia (classe `cheia`): encosta nas bordas, cantos só em cima, fundo sólido — como a Apple faz no detent grande. A medida é feita em `openSheet()` e refeita por um `ResizeObserver` no `#sheet` (conteúdo que cresce, como as parcelas) e no resize do `visualViewport`.
- A barra de ações fixa no pé da sheet troca o bloco sólido por um esfumado para o preenchimento da sheet.
- **Entrada e saída pelo mesmo caminho:** hoje a sheet sobe animada e some de uma vez. Passa a descer ao fechar, com o fundo escurecido esmaecendo junto. O estado (`show`, `sheet-open`, rolagem restaurada) continua mudando na hora em `closeSheet()`; só a pintura da saída dura a animação (classe `saindo` no backdrop, sem cliques). Abrir outra sheet durante a saída cancela a saída.
- **Sheet no desktop:** centralizada na tela como a "form sheet" do iPad/Mac, cantos de 28px, entra e sai crescendo de 96% para 100% com desfoque diminuindo ("materializar", não só fade).
- **Diálogos** (`.conta-dialog`, `.confirma-dialog`): vidro `--vidro-folha`, cantos de 28px, botões em cápsula, `::backdrop` escurecido, entrada materializando.
- **Tela de valor (teclado próprio):** fundo vira `--vidro-folha` sobre a obra desfocada; teclas continuam opacas (são conteúdo de digitação) e respondem no toque.

### 5. Conteúdo e controles

- Botões de ação (`.btn`) viram **cápsulas** (cantos 999px), altura ≥50px no celular. Primário preenchido, secundário tingido, destrutivo vermelho sobre cinza — como já está no PR #18, só o formato muda.
- Grupos "inset grouped" do celular (cantos 14px, sem borda nem sombra) passam a valer também no desktop, que hoje ainda tem borda e sombra de site.
- Chave de tema (`.tgl-tema`): ao tocar, a bolinha vira uma lente de vidro que cresce um pouco, e volta com mola ao soltar (o controle "vira vidro enquanto você mexe", como no iOS 26).
- Campos, busca, chips e listas: sem mudança além do formato (a busca já é o campo arredondado com lupa).

### 6. Desktop (≥900px) no estilo macOS Tahoe

- A barra lateral vira um painel de vidro flutuante: 10px de margem das bordas da janela, cantos de 22px, `blur(40px)`, sombra funda; o fundo (globo, brilho) aparece desfocado através dela. Item selecionado: cápsula tingida da marca. "Sair da conta" continua no pé, como botão de vidro.
- O conteúdo passa a usar a mesma estrutura do celular: título grande no topo da tela que colapsa para a barra, voltar como cápsula de vidro na barra (o "‹ Voltar" solto no conteúdo some, como já some no celular), sem a logo repetida no cabeçalho (ela fica na lateral).
- O botão flutuante da obra no desktop vira círculo de vidro tingido, no mesmo canto de hoje.

### 7. Login e cadastro

- O cartão da tela de entrada (hoje moldura cinza sólida com `#6C6C6C`/`#222` fixos, fora das variáveis) vira vidro `--vidro-folha` sobre o globo e o brilho, cantos 32px, brilho de borda; botões em cápsula; campos cheios. Some a cor hardcoded.
- A animação de entrada atual (`boost`) passa a usar a mola padrão.

### 8. Movimento

Molas no padrão da Apple, em dois parâmetros (amortecimento, resposta), geradas por `scripts/molas.mjs` como curvas `linear()`:

| Token | Amortecimento | Resposta | Uso |
| --- | --- | --- | --- |
| `--mola` | 1,0 | 0,35s | padrão: sheet abrindo/fechando, lente das abas, cápsula mudando de largura, diálogos |
| `--mola-quique` | 0,8 | 0,3s | só depois de gesto com impulso: sheet voltando ao lugar, linha de apagar, voltar pela borda |

Cada token tem uma duração pareada (`--mola-dur`, `--mola-quique-dur`) igual ao tempo de acomodação calculado. Antes de cada `linear()` vai uma declaração com `cubic-bezier(.2,.8,.2,1)`, que o WebKit sem `linear()` usa. Um teste compara o CSS com a saída do gerador.

Física dos gestos (`gestos.js`, funções puras testadas):

- **Projeção de impulso** (função da Apple, `projeta(v, 0.998)`): soltar a sheet, a linha e o voltar pela borda decide o destino pelo ponto projetado, não pela posição de soltura. Um peteleco curto fecha; um arrasto lento que para no meio volta.
- **Elástico nos limites** (`elastico(excesso, dimensao)`): puxar a sheet para cima além do topo e a linha para a direita além do zero resistem progressivamente, em vez de parar seco.
- A animação depois do gesto parte do ponto atual (já é assim com `transition` sobre a posição corrente) e usa `--mola-quique`.

`prefers-reduced-motion`: molas, deslizes e crescimento viram troca por opacidade curta ou instantânea; nada de quique.

### 9. Globo

Continua em todas as telas. Pausa também enquanto há sheet, diálogo ou tela de valor aberta (o vidro grande por cima custaria recompor o desfoque a cada quadro).

## Testes e validação

- **Unitários (`node --test`):** `projeta` e `elastico`; decisões de fim de gesto com projeção; `scripts/molas.mjs` (curva começa em 0, termina em 1, a sem quique nunca passa de 1, a com quique passa); guardas de CSS — tokens de vidro nos quatro combos tema×cor, bloco `prefers-reduced-transparency` e `prefers-contrast`, `backdrop-filter` só nos seletores permitidos, `-webkit-backdrop-filter` junto de todo `backdrop-filter`, sem `color-mix`, sem `#6C6C6C`/`#222` no login, tokens de mola iguais aos do gerador.
- **Playwright (suítes existentes ajustadas + `tests/browser/vidro.cjs` nova):** cápsula de abas descolada das bordas e acima da área segura; lente na aba certa após trocar de tela; + visível com o rótulo certo em Obras e na obra, ausente em Vale a pena? e Ajustes, e cápsula mais larga nelas; + abre Nova obra e Lançar gasto; nenhum painel/card com `backdrop-filter`; com transparência reduzida (emulada via CDP) nada tem `backdrop-filter`; sheet flutuante no celular e centralizada no desktop; fechar sheet deixa `closeSheet()` com o estado na hora e o backdrop sai depois da animação; diálogo com vidro; lateral flutuante no desktop; `contraste.cjs` passando nos quatro combos com a cápsula; largura do documento = largura da tela em todas as telas. As suítes que dependiam do FAB antigo, da barra cheia e da sheet encostada no fundo (`ios.cjs`, `fase2.cjs`, `nativo.cjs`, `contraste.cjs`) são atualizadas para o desenho novo.
- Suíte unitária e de navegador inteiras verdes; CI do PR verde.
- **agent-browser na prévia da Vercel:** iPhone 16 Pro e desktop 1440×900, escuro e claro, esmeralda e azul — capturas de Obras, obra aberta, sheet de gasto, diálogo de confirmação, Vale a pena?, Ajustes e login.
- Build da branch no TestFlight (`gh workflow run ios-testflight.yml --ref feat/vidro-liquido`).

## Fora do escopo

Refração com distorção (filtro SVG), cápsula que encolhe ao rolar, busca movida para a barra de baixo, `privacidade.html`, splash de abertura, funcionalidade nova.

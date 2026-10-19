# Inventário do site para a etapa 3 do app nativo

Data: 2026-10-18. Este levantamento descreve o que o PWA faz hoje nos cinco blocos da etapa 3 ("Dentro da obra"): orçamento previsto × real, afazeres, busca e filtro por mês, detalhe do tópico e a folha "A pagar", com o retorno do formulário de gasto para a folha de origem (`aoFechar`). Ele foi tirado do worktree `app-nativo-etapa2-conta-real` no `d076784`. Esse commit é o `origin/main` `e40ba3f` mais um commit que não mexe no site (o app iOS, o `CLAUDE.md` e o `tests/app-ios.test.cjs`). Desde 18/10 ele é também a árvore da main: o merge do #76 (`33ba862`) não muda nada nela. Caminhos e números de linha são dessa revisão e relativos à raiz do repositório.

O escopo vem do spec da etapa 2, seção "Fora do escopo" (docs/specs/2026-10-13-app-nativo-etapa2-design.md:211-218), e da tabela de etapas do spec do app nativo (docs/specs/2026-10-06-app-nativo-design.md:174-185).

Este é um levantamento feito por leitura, e as lacunas estão em "Cobertura". Antes de portar um trecho, confira no código: o código manda, e este documento só aponta onde olhar.

**Conferência (18/10, na main `33ba862`).** Antes de entrar no repositório, as 317 referências arquivo:linha, as contagens e os textos entre aspas foram conferidos no código. Nenhum texto citado estava errado; 11 números de linha foram corrigidos e sete frases, acertadas (o commit de base, os 12 casos do orçamento, o botão "Entendi", os testes dos afazeres e do detalhe do tópico, a ordem da lista e o limite dos tópicos próprios). O [spec da etapa 3](../specs/2026-10-18-app-nativo-etapa3-design.md) parte daqui.

**Cobertura.**
- **Lidos inteiros nos trechos da etapa:** `app.js` (2020 linhas; mudou desde o inventário da etapa 2, que citava 2097):
  - estado e helpers (app.js:1-135);
  - `openObra`, `renderAll`, `renderInicio` e o orçamento (app.js:200-320);
  - `renderObra`, afazeres e o donut da obra (app.js:323-550);
  - lista de lançamentos, `gastoRow`, venda e editar obra (app.js:700-831);
  - começo e fim do `formGasto` (app.js:834-880 e 990-1024);
  - `byTopico`, Gráficos, `sheetAPagar` e `sheetTopico` (app.js:1030-1161);
  - folha, toast, `formOrcamento`, `formNovaObra`, o + e o `bootCloud` (app.js:1578-1906).
- **Lidos inteiros:** `dados.js` (150 linhas) e o bloco `dados/{uid}` das `firestore.rules` (firestore.rules:14-36).
- **`calc.js`:** li datas e totais (calc.js:44-80), `aPagar`, `semAcento` e `filtraGastos` (calc.js:196-240), dinheiro digitado (calc.js:338-370) e tópicos, orçamento e exibição (calc.js:380-468). Não li TIR, séries, sugestões nem cartão (fora da etapa).
- **Por grep ou por trecho:**
  - `app.js` fora dos trechos acima: Ajustes (só a guarda de apagar tópico, app.js:1540-1560), gráficos, relatório e simulador;
  - `index.html`: só a tela da obra e a folha (index.html:208-210 e 333-336);
  - `styles.css`: lista, afazeres, orçamento, busca e folhas do tópico e do A pagar (styles.css:244-261, 321-334, 794-805, 819-820, 931-965);
  - `gestos.js` (arrastar e puxar a folha), `ui-confirm.js` (textos padrão do `perguntar` e do `avisar`) e `notificacoes/resumo.js` (afazeres e orçamento no push);
  - `scripts/vetores-calc.mjs`, `tests/vetores/calc.json` (contagem de casos), `tests/calc.test.cjs`, `tests/dados.test.cjs`, `tests/browser/orcamento.cjs` (inteiro), `tests/browser/mobile.cjs` (o A pagar), `tests/browser/xss.cjs` (o que toca a etapa);
  - os specs de origem de cada bloco: afazeres (docs/specs/2026-07-08-afazeres-obra-design.md), busca (docs/specs/2026-07-06-grafico-evolucao-busca-design.md:40-72), detalhe do tópico (docs/specs/2026-08-24-drilldown-topico-design.md) e orçamento (docs/specs/2026-09-26-orcamento-previsto-real-design.md:95-140);
  - o núcleo e as telas em `app-ios/`, só para marcar o que já existe.
- **Não li:** `cloud.js`, `auth.js`, `share.js`, `teclado.js`, `push.js`, o resto do CSS e os mockups (fora do repositório). Nada foi rodado: os números deste documento saem do código, não de execução.

---

### 1. Orçamento previsto × real

**Onde aparece**
- **Tela da obra:** com orçamento válido, entre o cabeçalho da obra e os indicadores (app.js:445). A ordem é: cabeçalho → cartão "Orçamento" → "Por tópico" (só no modo por tópico) → botão "Editar orçamento" → indicadores → ações → afazeres → gráficos → lançamentos (app.js:445, 319).
- **Início (lista de obras):** uma mini barra e um texto embaixo da fase de cada obra com orçamento (app.js:228-229, 235, 242).
- **Nova obra:** o campo "Orçamento total (opcional)" grava `{modo:'total', total}` (app.js:1779, 1799; dados.js:130). Já está no app (FolhaDaObra.swift:6, 24, 41).
- **Obra vendida:** o cartão e o "Editar orçamento" continuam aparecendo. Só o "Definir orçamento" some (app.js:398). Ver "Achados".

**Cálculo (`orcamentoObra`, calc.js:407-439)**
- **Base:** o total **bruto**, com as parcelas futuras. Nunca o corrigido (calc.js:407-409).
- **Item (`itemOrcamento`, calc.js:411-415):**
  - `pct = Math.round(gasto / previsto * 100)`;
  - `sobra = previsto - gasto`;
  - nível `passou` se `gasto - previsto > 0,005` (mais de meio centavo acima);
  - senão `perto` se `pct >= 90` (`LIMIAR_PERTO`, calc.js:410);
  - senão `ok`.
  - O nível sai do `pct` arredondado: 89,5% vira 90% e já é `perto`.
- **Modo total:** compara `totalBruto(obra)` com `orc.total`. `orc.total` precisa ser número finito > 0, senão não há orçamento (calc.js:437-438).
- **Modo por tópico (calc.js:420-436):**
  - entram os ids com previsto número finito > 0;
  - sem nenhum, não há orçamento (`null`);
  - cada tópico previsto vira um item, mesmo com gasto zero;
  - ordem: maior razão gasto/previsto primeiro; empate pelo id com `localeCompare` (calc.js:427-428);
  - `fora`: tópicos com gasto > 0 que não têm previsto, do maior gasto ao menor, empate pelo id (calc.js:429-431);
  - o geral (`gasto`, `previsto`, `pct`, `nivel`) soma **só os tópicos previstos**. O gasto "fora" não entra (calc.js:432-434). Fica à parte, em `foraTotal`.
- **Leitura (`dados.js`, dados.js:17-40, 58-59):**
  - `modo: 'topicos'`: até 100 tópicos (`MAX_TOPICOS_ORC`), id não vazio e com até 80 unidades UTF-16 (`LIMITES.topico`), valor > 0; número em texto vira número. Sem nenhum válido, a chave `orcamento` some. A chave `total` é apagada;
  - qualquer outro `modo` (ou nenhum) vira `total`: `total` > 0, senão some. A chave `topicos` é apagada;
  - campos desconhecidos dentro de `orcamento` ficam (`{...v}`).
- **Rules:** nada valida `orcamento`. As rules não olham dentro da obra (firestore.rules:24-36).

**Cartão "Orçamento" (`orcamentoHtml`, app.js:288-298)**
- Rótulo "Orçamento" e a pílula do nível (`ORC_PILL`, app.js:275):
  - `ok`: "dentro do previsto" (verde);
  - `perto`: "perto do limite" (âmbar);
  - `passou`: "passou do previsto" (âmbar).
- Número: `money(gasto)` e, menor, "de {money(previsto)}" (app.js:294).
- Barra: largura `pct` limitada a 0–100, gradiente da marca no `ok` e âmbar no resto (app.js:276-282; styles.css:937-939). A largura vai por CSSOM porque a CSP proíbe `style` no HTML.
- Rodapé: "**{pct}%** usado" à esquerda; à direita "sobra **{money(|sobra|)}**" ou, no `passou`, "passou **{money(|sobra|)}**" (app.js:296-297).
- **Só duas cores para três níveis:** `perto` e `passou` usam o mesmo âmbar (classe `alerta`, styles.css:934, 939). O que diferencia é o texto da pílula.

**"Por tópico" (só no modo por tópico, app.js:300-317)**
- Título de seção "Por tópico" e um painel com uma linha por tópico previsto, na ordem do cálculo.
- Linha: nome do tópico (`nomeTopico`; tópico apagado cai no id, app.js:61), depois "**{moneyCurto(gasto)}** / {moneyCurto(previsto) sem o "R$ "}", por exemplo "**R$ 98 mil** / 90 mil" (app.js:304-305; `semCifrao`, app.js:67).
- Barra fina e a frase (`fraseTopicoOrc`, app.js:283-287):
  - `passou`: "Passou {moneyCurto(-sobra)} do previsto", em âmbar;
  - `perto` com `sobra > 0,005`: "Faltam {moneyCurto(sobra)} — {pct}%";
  - `perto` com `sobra <= 0,005`: "Chegou ao previsto — {pct}%";
  - `ok`: nada.
- **Tocar:** só a linha de tópico **com gasto** vira botão e abre a folha do tópico (bloco 4) (app.js:301, 308-310, 481-483). Tópico previsto sem gasto é um `div`, sem ação.
- **"Fora do orçamento":** última linha, sem barra, com `moneyCurto(foraTotal)` e embaixo os nomes dos tópicos separados por ", " (app.js:312-316). Ela **não** é tocável.
- `moneyCurto` tira o ",0" de "R$ 8,0 mil" (calc.js:453). Abaixo de mil, mostra o valor inteiro, por exemplo "R$ 500,00".

**Início (app.js:228-229)**
- `ok` e `perto`: "{pct}% do orçamento".
- `passou`: "{pct}% · passou {moneyCurto(-sobra)}", em âmbar (`orc-mini-alerta`).
- A mini barra tem 56 px (styles.css:941).
- Obra sem orçamento: a linha não muda.

**"Definir orçamento" e "Editar orçamento"**
- "Definir orçamento" (ícone `alvo`, ghost) fica na fileira de ações, depois dos botões da fase e antes de "Ver gráficos" e "Relatório". Aparece só **sem orçamento e fora da vendida** (app.js:398).
- "Editar orçamento" (ghost, largura cheia) fica logo abaixo do cartão ou da lista "Por tópico" (app.js:319; styles.css:959).
- Os dois chamam `formOrcamento(o.id)` (app.js:478-479).

**Folha "Orçamento da obra" (`formOrcamento`, app.js:1692-1767)**
- **Título:** "Orçamento da obra" (app.js:1704).
- **Segmentado** `role="group"` com `aria-label` "Tipo de orçamento": "Só o total" e "Por tópico", com `aria-pressed` (app.js:1705-1708, 1728-1732). Abre no modo salvo; sem orçamento, em "Só o total" (app.js:1698).
- **Só o total:** campo "Orçamento total" com "R$", máscara de dinheiro e placeholder "0,00". Vem preenchido só se o orçamento salvo for total (app.js:1709-1710).
- **Por tópico** (app.js:1700-1702, 1711-1715):
  - uma linha por tópico de `topicos()`: os 21 fixos e depois os próprios (app.js:59);
  - campo de dinheiro com placeholder "sem valor", preenchido com o valor salvo (`numParaCampo`);
  - faixa "Total" com a soma ao vivo (`aria-live="polite"`). A soma usa `max(0, parseNum)` (app.js:1722-1725);
  - dica: "Tópico sem valor não entra na comparação."
- **"Tirar orçamento":** só quando a obra já tem orçamento (app.js:1716). Pergunta "Tirar o orçamento desta obra? Os gastos continuam como estão.", com os botões "Cancelar" e "Tirar orçamento" (app.js:1763-1766; ui-confirm.js:191).
- **Rodapé:** "Cancelar" e "Salvar" (app.js:1717-1720).
- **Trocar para "Só o total" com o campo vazio** pré-preenche o total com a soma dos tópicos, se ela for > 0 (app.js:1735-1740). Trocar de modo não grava nada.
- **Salvar** grava só o modo ativo (app.js:1753-1762):
  - total: `total > 0` grava `{modo:'total', total}`; senão **tira o orçamento**;
  - por tópico: grava `{modo:'topicos', topicos}` só com os valores > 0; sem nenhum, **tira o orçamento**;
  - tirar = `delete oo.orcamento` (a chave some, não vira `null`) (app.js:1749);
  - depois: `save()`, a folha fecha, `renderAll()`. Não há toast (app.js:1747-1751).
- **Limites:** nenhum teto de valor. A máscara aceita quantos dígitos vierem (calc.js:340-348). Não há guarda de `dadosCarregados` (o `formNovaObra` tem, app.js:1770).
- **Foco:** nenhum campo recebe foco ao abrir.
- **Tópico próprio no orçamento não pode ser apagado em Ajustes:** aviso "Este tópico está no orçamento de uma obra. Tire o valor dele no orçamento antes de apagar.", com o botão "Entendi" do `avisar` (app.js:1553-1554; ui-confirm.js:192). É etapa 5, mas protege o orçamento.

**Push (fora da etapa, para saber)**
- O resumo diário avisa quando o nível de um item sobe, com memória em `perfis/{uid}.avisosOrcamento` (notificacoes/resumo.js:40-74; spec do orçamento:148-196). Usa o mesmo `orcamentoObra`. Mudar a regra muda o push.

**Já existe no núcleo/app**
- `orcamentoObra`, `ItemOrcamento`, `ForaOrcamento` e `ResumoOrcamento` (app-ios/CusttaNucleo/Sources/CusttaNucleo/Orcamento.swift:3-75), conferidos pelos vetores (OrcamentoTests.swift:23).
- A linha de Início: `textoOrcamentoNaLista` (Telas.swift:69-72) e a lista de obras (ObrasView.swift:120-190).
- A normalização (Normalizacao.swift:14, 58-86) e o campo cru `Obra.orcamento` (Modelo.swift:157-160).
- **Não existe:** cartão na tela da obra, "Por tópico", textos do `fraseTopicoOrc` e do `ORC_PILL`, "Definir/Editar orçamento", a folha e uma mutação de orçamento (`Mutacoes.swift` só tem gasto, obra, fase e venda: Mutacoes.swift:11-96).

**Vetores e testes**
- `calc.orcamentoObra`: 12 casos (scripts/vetores-calc.mjs:413-425): as quatro obras de exemplo, passou/perto/sem gasto, meio centavo, 89,5%, empates de razão e de "fora", previsto zero e sem orçamento.
- `dados.normaliza`: 8 casos de orçamento (scripts/vetores-calc.mjs:510-519).
- `calc.moneyCurto`: 7 casos (scripts/vetores-calc.mjs:407-408).
- `tests/calc.test.cjs:388` e seguintes; `tests/dados.test.cjs:25-52`.
- Browser: `tests/browser/orcamento.cjs` (dados sintéticos, sem rede): textos de Início, pílula, frases, barra, "Editar"/"Definir", modo total com máscara, folha por tópico com soma ao vivo, troca de modo com pré-preenchimento, salvar vazio, "Tirar orçamento", nova obra, larguras 320-1440, temas, guarda de Ajustes e contraste nos quatro combos (orcamento.cjs:45-233). Roda pelo `tests/browser/rodar.cjs:23`.
- XSS: o nome do tópico na lista do orçamento (tests/browser/xss.cjs:79).

---

### 2. Afazeres

**Onde aparece**
- Painel "Afazeres" na tela da obra, entre as ações e os gráficos (app.js:404-411, 445). Aparece em **todas as fases**, inclusive na vendida.
- O push diário conta os pendentes de todas as obras (notificacoes/resumo.js:102-109).

**Dado**
- `afazeres?: [{id, texto, feito}]` na obra (spec afazeres:9-16).
- **Leitura** (dados.js:57): afazer sem `id` some; `texto` vira texto (número vira string, o resto vira ""); `feito` é `true` só com `true` exato; campos desconhecidos ficam. A leitura sempre acrescenta `afazeres: []`.
- **Limite:** `LIMITES.afazer` = 500 unidades UTF-16 (dados.js:6). Só vale ao digitar; texto maior vindo da nuvem não é cortado (dados.js:3).
- **Rules:** nada valida afazeres (firestore.rules:24-36). Não há limite de quantidade além do 1 MB do blob.

**Textos e campos (app.js:404-411)**
- Título "Afazeres" e, ao lado, em tom secundário, "({N} pendente)" ou "({N} pendentes)". Sem pendentes, nada (app.js:492).
- Campo: `maxlength="500"`, placeholder "Ex: pagar pedreiro, buscar tinta", `autocomplete="off"`, **sem rótulo e sem `aria-label`**.
- Botão "+" com `aria-label` "Adicionar afazer" e `title` "Adicionar".
- Estado vazio: ícone `check` e "Nenhum afazer.<br>Anote o que falta na obra." (app.js:494).

**Adicionar (app.js:457-466)**
- Pelo "+" ou por Enter no campo.
- Texto aparado; vazio só devolve o foco ao campo, sem mensagem.
- Mais de 500: toast de erro "Use até 500 caracteres." e foco no campo (`textoValido`, app.js:25-29). Na prática o `maxlength` já impede.
- Grava `{id: uid(), texto, feito: false}` **no começo** do array (`unshift`). Cria o array se a obra não tiver.
- Depois: `save()`, limpa o campo, repinta só a lista (`renderAfazeres`) e **devolve o foco ao campo**, para adicionar vários seguidos.
- Sem toast e sem guarda de `dadosCarregados`.

**Marcar e desmarcar (app.js:498-510)**
- Pelo círculo à esquerda (botão com o ícone `check`) ou tocando no texto.
- O círculo tem `aria-label` "Marcar feito" ou "Desmarcar afazer". Não tem `aria-pressed`.
- Inverte `feito` no próprio objeto (mantém campos desconhecidos), `save()` e repinta a lista.
- Feito: círculo verde cheio, texto riscado e esmaecido (opacidade 0,5) (styles.css:799-805).

**Apagar (app.js:511-516)**
- Botão "×" com `aria-label` "Apagar afazer". Apaga **na hora, sem perguntar** (decisão do spec afazeres:48-49).
- O arrastar para apagar do gasto também vale aqui, porque o `gestos.js` pega qualquer `li` com `.li-del` (gestos.js:222).
- Apagar o último deixa `afazeres: []` no documento.

**Ordem (app.js:489-495)**
- Pendentes primeiro, depois feitos. Dentro de cada grupo, a ordem do array.
- Como o novo entra com `unshift`, o pendente mais novo fica no topo.
- Marcar como feito leva o item para o grupo dos feitos **na posição dele no array**, não para o fim. Desmarcar o devolve à posição original entre os pendentes, não ao topo. Ver "Achados".

**Exibição**
- Pendente: uma linha só, cortada com reticências (`.li-main .t`, styles.css:245).
- Feito: quebra linha (styles.css:805).

**Regras**
- Tudo só no `app.js`. Não há função de afazer no `calc.js` nem no `dados.js` além da leitura.

**Já existe no núcleo/app**
- O modelo `Afazer` (id, texto, feito, campos preservados) e a obra com `afazeres` e `afazeresNaArvore` (Modelo.swift:76-117).
- A leitura (Normalizacao.swift:11, 114, 143) e o limite `Limites.afazer` = 500.
- O arrastar para apagar (`LinhaArrastavel`, Telas/LinhaArrastavel.swift).
- **Não existe:** mutação de afazer e qualquer tela.

**Vetores e testes**
- `dados.normaliza`: um caso de afazer (scripts/vetores-calc.mjs:506-507), mais os afazeres do blob de exemplo (scripts/vetores-calc.mjs:75).
- Nenhum vetor para ordem, contador, adicionar ou alternar.
- Browser: só XSS (tests/browser/xss.cjs:22, 79). O rótulo "Apagar afazer" é conferido por um teste Node que lê o `app.js` (tests/ios.test.cjs:93). Nenhum teste de comportamento.
- Push: tests/resumo.test.cjs:27-57.

---

### 3. Busca e filtro por mês nos lançamentos

**Onde aparece**
- Na tela da obra, no topo do painel "Lançamentos" (app.js:430-443).

**Campos**
- **Busca:** campo com o ícone `lupa` e `aria-label` "Pesquisar gasto ou tópico".
  - Placeholder "Buscar" abaixo de 900 px e "Pesquisar gasto ou tópico" acima (app.js:432). É decidido no render, não acompanha o giro.
  - Vem preenchido com o texto do filtro em memória (app.js:437).
- **Mês:** `<select>` com "Todos os meses" e um item por mês que tem gasto, do mais novo ao mais antigo, inclusive meses futuros (parcelas) (app.js:430, 438-440).
  - Rótulo: `{mês abreviado}/{ano em 2 dígitos}`, por exemplo "out/26" (`MESAB`, app.js:68, 439).
  - Valor: "AAAA-MM".

**Estado**
- `filtroTexto` e `filtroMes` vivem só em memória (app.js:20). Não vão para a nuvem nem para o `localStorage`.
- `openObra` zera os dois (app.js:203). Trocar de obra, criar obra ou voltar à obra pelo relatório zera o filtro.
- Digitar repinta só a lista e o contador, sem perder o foco (`renderGastosFiltrados`, app.js:452, 706-718). Trocar o mês, idem (app.js:453).
- Um `renderAll` (por exemplo, uma mudança vinda de outro aparelho) reescreve a tela inteira: o texto continua, o foco sai do campo (app.js:445, 1894-1897).

**Regra (`filtraGastos`, calc.js:225-239)**
- `semAcento`: minúsculas, NFD e remoção dos acentos combinantes U+0300–U+036F (calc.js:225-227).
- O texto procura na descrição **ou** no nome do tópico. Tópico desconhecido (apagado) é procurado pelo id (calc.js:235-237).
- O mês compara `data.slice(0, 7)` (calc.js:232).
- Texto e mês combinam em E. Texto vazio ou mês vazio não filtram.
- O texto **não é aparado**: "cimento " com espaço no fim não acha "…cimento" no fim da descrição. Não procura valor nem data.

**Contador e estados vazios (app.js:711-715)**
- Ao lado de "Lançamentos", em tom secundário:
  - sem gastos: nada;
  - sem filtro: o total, por exemplo "13";
  - com filtro: "{achados}/{total}", por exemplo "3/13".
- Obra sem gastos: ícone `recibo` e "Nenhum gasto lançado.<br>Toque no + pra lançar o primeiro." A busca continua visível.
- Filtro sem resultado: "Nada encontrado com esse filtro." Não há botão de limpar o filtro.
- A lista filtrada segue a ordem da lista normal: data e id, do mais novo ao mais antigo (app.js:716).
- O filtro só mexe na lista. Indicadores, orçamento e gráficos continuam com a obra inteira.

**Já existe no núcleo/app**
- `semAcento` e `filtraGastos` (Listas.swift:45-76), com vetores (ListasTests.swift:32, 38).
- A lista do app é **agrupada por mês**, com o cartão "A vencer" no topo para os gastos futuros (`listaDaObra`, ObraNaTela.swift:82-89; ObraView.swift:83-90). O site é uma lista plana.
- A pílula "Lançamentos {N}" (PecasDaObra.swift:176-188) mostra só o total.
- **Não existe:** campo de busca, seletor de mês, contador "achados/total" e o estado "Nada encontrado com esse filtro."

**Vetores e testes**
- `calc.semAcento`: 8 casos; `calc.filtraGastos`: 8 casos (scripts/vetores-calc.mjs:259-270).
- `tests/calc.test.cjs:284-297`.
- Browser: só XSS do campo (tests/browser/xss.cjs:80-82). Nenhum teste do contador nem do seletor de mês.
- **Sem vetor:** a lista de meses do seletor, o rótulo "out/26" e o contador.

---

### 4. Detalhe do tópico (`sheetTopico`, app.js:1125-1161)

**Como abre**
- Na tela da obra: tocando numa linha do "Por tópico" do orçamento que tenha gasto (app.js:308-310, 481-483). É a **única entrada na etapa 3**.
- Na tela Gráficos (etapa 4): tocando na legenda ou numa fatia do donut (app.js:1105; `bindDonutLegenda`, app.js:1069-1074).
- O donut pequeno da tela da obra **não** abre a folha do tópico: o toque nele vai para Gráficos (app.js:419, 473). A lista de lançamentos também não.

**Conteúdo (app.js:1131-1149)**
- Cabeçalho: ícone do tópico e o nome em `<h3>`. Tópico desconhecido: o id e o ícone `etiqueta`.
- Resumo, nesta ordem:
  - "{N} gasto" ou "{N} gastos", " · {pct}% da obra";
  - `money(bruto)` em destaque;
  - "corrigido: {money(corrigido)}".
- Lista dos gastos do tópico, por data e id, do mais novo ao mais antigo, com a mesma linha da lista de lançamentos (`gastoRow`, com `voltar`) (app.js:1157-1159).
- Botão "Fechar" (ghost) (app.js:1149, 1160).

**Cálculos (só no `app.js`)**
- `bruto`: soma dos valores do tópico, com as parcelas futuras (app.js:1135).
- `corrigido`: soma de `corrigido(valor, data, fim, taxa)`, com `fim` = data da venda ou hoje (app.js:1133-1136). É a mesma regra do `fimCorrecao` (calc.js:70-72), copiada à mão.
- `pct = Math.round(bruto / totalBruto(obra) * 100)`; com total zero, 0 (app.js:1137-1139). É o mesmo arredondamento da legenda do donut, para o número não mudar ao abrir.

**Casos de borda**
- Obra que não existe: não abre (app.js:1127).
- Tópico sem nenhum gasto: **fecha a folha** (app.js:1129). Acontece quando o último gasto do tópico é apagado ou trocado de tópico de dentro da folha.
- Gasto editado para outro tópico some da folha na volta.
- Tópico com gasto de R$ 0 (a leitura aceita `valor: 0`, dados.js:10, 42): a linha do orçamento vira botão e a folha abre com "R$ 0,00".
- Se a folha foi aberta de Gráficos, a volta repinta Gráficos antes de reabrir (app.js:1153-1156).

**Já existe no núcleo/app**
- `corrigido` e `fimCorrecao` (Correcao.swift:11-20), `totalBruto` (Correcao.swift:22), `mapaDeTopicos` (Topicos.swift:35), a linha de gasto (`linhaDeGasto`, ObraNaTela.swift:112).
- **Não existe:** a soma por tópico, o "% da obra" e a folha.

**Vetores e testes**
- Nenhum vetor da soma por tópico nem do "% da obra". `corrigido` e `totalBruto` têm vetores (scripts/vetores-calc.mjs:177-185).
- Browser: o XSS da folha (tests/browser/xss.cjs:95) e a abertura pela linha "Fundação" do orçamento, que só confere o nome (tests/browser/orcamento.cjs:77-80). O spec do detalhe pedia um E2E manual com Playwright (docs/specs/2026-08-24-drilldown-topico-design.md:98-106); nenhuma suíte confere o resumo nem a volta.

---

### 5. Folha "A pagar" e o retorno do formulário (`aoFechar`)

**O indicador (app.js:383-388, 469)**
- É um `<button>` (`kpi amber kpi-link`), sempre tocável, mesmo sem nada a pagar.
- Rótulo "A pagar · 30 dias"; etiqueta "{N} vencimento" ou "{N} vencimentos", ou "nada em 30 dias"; valor `money(total)`; nota "Ver parcelas e gastos futuros →".

**Regra (`aPagar`, calc.js:197-210)**
- Entra o gasto com `data > hoje` e `data <= hoje + 30 dias`. O limite é calculado em hora local (calc.js:200-201).
- O gasto de hoje **não** entra (já pago). Por isso a folha diz "a partir de amanhã".
- Ordem: data crescente, empate na ordem do array (sort estável) (calc.js:207).
- Vale para qualquer gasto futuro, não só parcela de cartão.

**A folha (`sheetAPagar`, app.js:1111-1123)**
- Título: "A pagar · próximos 30 dias".
- Resumo: `money(total)` em destaque e, embaixo, "{N} vencimento" ou "{N} vencimentos", " · a partir de amanhã". Zero dá "0 vencimentos" (app.js:1116-1117).
- Lista com a linha de gasto de sempre, com a etiqueta "a vencer" em cada uma (app.js:728, 734) e `voltar` para a própria folha (app.js:1121).
- Vazia: "Nenhum gasto previsto para esse período." (app.js:1119). A folha **não fecha** quando fica vazia (a do tópico fecha).
- Botão "Fechar" (ghost).
- Obra que não existe: fecha a folha (app.js:1113).
- O resumo vem antes do subtítulo aqui e depois na folha do tópico (app.js:1116-1117 × 1144-1146). Mesmas classes, ordem invertida.

**O retorno (`aoFechar` e `opts.voltar`)**
- A folha é única: `openSheet` troca o conteúdo da mesma folha (app.js:1636-1650). Ir da folha "A pagar" ao formulário e voltar é sempre **remontar**, não empilhar. Por isso o retorno é uma função, não um histórico (docs/specs/2026-08-24-drilldown-topico-design.md, seção "Riscos").
- `gastoRow(o, g, {voltar})` (app.js:720-768):
  - tocar no miolo da linha abre `formGasto(o.id, g, undefined, voltar)` (app.js:738);
  - apagar gasto simples: pergunta "Excluir este gasto?" com o botão "Excluir"; no sim, apaga, `save()`, `renderAll()` e chama `voltar()` (app.js:743-750). No não, nada muda e a folha de origem continua aberta por trás do diálogo;
  - apagar parcela: a folha troca para "Excluir parcela {n}/{de}" com "Excluir só esta parcela", "Excluir a compra toda ({N} parcela(s))" e "Cancelar". As três saídas chamam `voltar` em vez de fechar (app.js:752-764).
- `formGasto(obraId, gasto, valorInicial, aoFechar)` (app.js:834-837):
  - "Cancelar" chama `aoFechar` (app.js:994);
  - "Salvar" faz a gravação, o toast de sempre e `renderAll()`, e só então `aoFechar` (app.js:1020-1022);
  - erro de validação (valor, descrição, cartão, repetido) não fecha nem volta (app.js:1000-1013).
- **O que não volta:** tocar no fundo, Esc e puxar a folha para baixo chamam `closeSheet` e fecham tudo (app.js:1689-1690; gestos.js:166-168). Só "Cancelar", "Salvar" e as saídas do apagar voltam.
- **Rolagem:** reabrir a folha volta ao topo (`sheet.scrollTop = 0`, app.js:1646). Quem editou o 15º item volta ao começo da lista.
- **Obra da edição:** na edição, o formulário usa a obra aberta (`obraById(obraAberta)`), não a obra da linha (app.js:842). Funciona porque as duas folhas só abrem com a obra aberta.

**Acessibilidade e foco**
- A folha não tem `role="dialog"` nem `aria-modal` (index.html:334-336). As folhas do A pagar, do tópico e do orçamento não movem o foco ao abrir.

**Já existe no núcleo/app**
- `aPagar` (Listas.swift:3-26) com vetores (ListasTests.swift:16); o indicador com a etiqueta e o total (ObraNaTela.swift:144-171; PecasDaObra.swift:96-97).
- **Sem seta e sem "Ver"** no indicador do app, por decisão da etapa 2 (PecasDaObra.swift:94-95; docs/plans/2026-10-13-app-nativo-etapa2.md:82, 108). O spec da etapa 2 ainda diz "com chevron" (spec:27, 218).
- As folhas do app são uma por vez, num `enum` (`Folhas.Qual`: novo gasto, editar gasto, gasto de vendida, nova obra, editar obra, venda) (app-ios/Custta/Estado/Folhas.swift:10-19). Não há folha "A pagar", folha do tópico nem retorno.
- O app já tem "Apagar gasto" no fim da folha de edição (spec da etapa 2:43; Folhas.swift:30-31).
- **Não existe:** a folha, o toque no indicador e o retorno.

**Vetores e testes**
- `calc.aPagar`: 5 casos (scripts/vetores-calc.mjs:245-252); `tests/calc.test.cjs:316-341`, inclusive fusos.
- Browser: `tests/browser/mobile.cjs:24-36` abre a folha, edita o gasto de dentro dela e confere que voltou à folha com o texto novo. Não cobre o apagar, a parcela nem o Cancelar.

---

### Regras que só vivem no app.js

Candidatas a subir para `calc.js` ou `dados.js` com vetor antes de portar, como o PR 0 da etapa 2 fez. Textos de tela entram aqui quando dependem de conta ou de limiar.

1. **Frases do orçamento** (app.js:275, 283-287, 294-297, 305):
   - pílula por nível;
   - "Passou {X} do previsto" / "Faltam {X} — {pct}%" / "Chegou ao previsto — {pct}%", com o limiar de meio centavo na sobra;
   - rodapé "sobra"/"passou" com o valor absoluto;
   - linha "{moneyCurto(gasto)} / {moneyCurto(previsto) sem R$}".
2. **Largura da barra:** `pct` limitado a 0–100 (app.js:277).
3. **Quando mostrar cada peça do orçamento:** cartão com orçamento válido; "Por tópico" só no modo por tópico; "Definir" só sem orçamento e fora da vendida; linha tocável só com gasto (app.js:301, 308, 398, 445).
4. **O que a folha do orçamento grava** (app.js:1753-1762): total > 0 ou tira; por tópico só valores > 0, vazio tira; o objeto inteiro é trocado.
5. **Pré-preenchimento do total pela soma dos tópicos** e a soma ao vivo com `max(0, …)` (app.js:1722, 1737-1740).
6. **Afazeres:** adicionar (aparar, vazio, limite, `unshift`, `feito: false`), alternar, apagar, a ordem pendentes → feitos e o contador "({N} pendente(s))" (app.js:457-464, 489-495, 500-516).
7. **Seletor de mês:** os meses com gasto, do mais novo ao mais antigo, e o rótulo "out/26" (app.js:430, 439).
8. **Contador dos lançamentos:** vazio, "N" ou "achados/total" (app.js:711-712).
9. **Resumo do tópico:** bruto, corrigido até a venda ou hoje e "% da obra" arredondado (app.js:1133-1139). Hoje copia o `fimCorrecao` à mão. A soma por tópico também existe em `byTopico` (app.js:1059-1063) e no donut da obra (app.js:413-415).
10. **Textos do A pagar:** "{N} vencimento(s) · a partir de amanhã" na folha (app.js:1117). A etiqueta do indicador já está no núcleo (ObraNaTela.swift:171).
11. **Guarda de Ajustes:** tópico próprio com previsto > 0 em algum orçamento não pode ser apagado (app.js:1553-1554). É da etapa 5, mas a regra é de orçamento.

O resto (`filtraGastos`, `aPagar`, `orcamentoObra`, `semAcento`, `moneyCurto`, leitura de `orcamento` e `afazeres`) já está no `calc.js`/`dados.js`, com vetores e com a cópia no núcleo. A ordem da lista (data e id, do mais novo ao mais antigo) não está: mora no app.js:716 e, na folha do tópico, no app.js:1158, sem vetor. É a mesma regra do `calc.gastosRecentes` (calc.js:215), que tem vetores, e o núcleo já a tem na `listaDaObra`, com testes escritos à mão (ObraNaTelaTests.swift).

---

### Achados

**Defeitos do site (só reportados, nada corrigido)**

1. **Filtro de mês fantasma.** Com um mês escolhido, apagar o último gasto dele (ou mudar a data para outro mês) tira o mês do seletor no próximo render. O `<select>` passa a mostrar "Todos os meses", mas o `filtroMes` continua com o mês velho. A lista diz "Nada encontrado com esse filtro." e o contador "0/N" (app.js:430, 439, 453, 710-715). Só sai trocando de obra (app.js:203) ou escolhendo outro mês.
2. **Afazer pendente longo não se lê.** O pendente fica numa linha, cortado com reticências (styles.css:245). Só o feito quebra linha (styles.css:805). Um afazer de 500 caracteres pendente mostra só o começo, e não há outro lugar para ver o texto inteiro.
3. **Mudança vinda de outro aparelho apaga o afazer em digitação.** O `renderAll` reescreve a tela da obra inteira, com o campo de afazer vazio (app.js:404-411, 445, 1894-1897). O texto da busca sobrevive (vem do `filtroTexto`), mas o foco sai do campo.
4. **A ordem dos afazeres não é a do spec.** O spec diz que o item marcado "migra pro fim da lista" (spec afazeres:36-37, 46-47). No código, ele vai para o grupo dos feitos na posição do array, que pode ser antes de feitos mais antigos. Desmarcar o devolve à posição original, não ao topo (app.js:489-495).
5. **Orçamento na vendida pela metade.** Sem orçamento, a vendida não tem "Definir orçamento". Com orçamento, ela mostra o cartão, "Editar orçamento" e "Tirar orçamento" (app.js:319, 398, 1716).
6. **Salvar vazio tira o orçamento sem perguntar; "Tirar orçamento" pergunta** (app.js:1756, 1761 × 1765). É decisão do spec do orçamento (spec:137), mas o resultado é o mesmo por dois caminhos, um com confirmação e outro sem.
7. **A folha do orçamento perde dados fora da lista de tópicos.** Ela só tem campos para `topicos()` (app.js:1700). Salvar no modo por tópico descarta o previsto de um tópico que não está na lista (tópico próprio apagado em dado antigo ou por outro caminho; o vetor de exemplo tem `c_apagado`, scripts/vetores-calc.mjs:417). E o objeto é trocado inteiro, então campos desconhecidos dentro de `orcamento`, que a leitura preserva (dados.js:31, 37), somem no primeiro Salvar (app.js:1749).
8. **Push conta afazer de forma diferente do site.** O push lê o documento cru e conta `!a.feito` (notificacoes/resumo.js:105); o site só considera feito com `true` exato (dados.js:57). `feito: "true"` é pendente no site e feito no push. O push também conta pendentes das obras vendidas, para sempre.
9. **Comentário trocado:** "Folha com só os gastos de um tópico" está em cima do `sheetAPagar` (app.js:1109-1111).

**Inconsistências e comportamentos para decidir (não são defeito, mas o app precisa escolher)**

10. **No modo por tópico, o cartão não fecha com o total gasto.** "R$ X de R$ Y" e o "% do orçamento" de Início somam só os tópicos previstos; o gasto "fora" fica de fora (calc.js:432-434). É coerente com a linha "Fora do orçamento", mas o número do cartão difere do "Total gasto" logo abaixo.
11. **"Fora do orçamento" não é tocável** (app.js:312-316), enquanto as linhas previstas com gasto abrem a folha do tópico.
12. **Sem teto no valor do orçamento** (calc.js:340-348). O teclado do app para em R$ 99.999.999,99.
13. **A folha do A pagar não fecha quando fica vazia; a do tópico fecha** (app.js:1119 × 1129).
14. **Fechar pelo fundo, Esc ou puxando** a folha do formulário aberta de dentro do A pagar ou do tópico fecha tudo, sem voltar (app.js:1689-1690; gestos.js:166-168).
15. **Reabrir a folha volta ao topo** (app.js:1646).
16. **A busca não apara o texto** e não procura valor nem data (calc.js:229-237).
17. **O indicador "A pagar" abre mesmo vazio**, com "0 vencimentos" (app.js:383, 1117).
18. **A tabela de etapas do spec do app nativo** põe "Parcelas no cartão" na etapa 3 (docs/specs/2026-10-06-app-nativo-design.md:182), mas a etapa 2 já entregou o cartão (spec da etapa 2:18, 39). Vale acertar a tabela.
19. **O pedido deste levantamento dizia que o indicador do app "já tem chevron".** O código e o plano da etapa 2 dizem o contrário: a seta saiu até a etapa 3 (PecasDaObra.swift:94-95; plano da etapa 2:82, 108). O spec da etapa 2 ainda diz "com chevron" (spec:27, 218).

**Decisões de desenho que o mockup da etapa 3 vai ter de tomar**

1. **Onde mora o orçamento na tela da obra.** No site, o cartão vem antes dos indicadores, e a lista "Por tópico" (os 21 tópicos fixos mais os próprios, que as rules limitam a 50, firestore.rules:35; a leitura aceita até 100 ids, dados.js:19) empurra o "Total gasto" para baixo. Isso briga com o "saldo em 5 segundos" (PRODUCT.md). Opções: cartão depois do herói, "Por tópico" numa folha ou numa tela própria.
2. **Onde ficam "Definir orçamento" e "Editar orçamento".** O app tem a fileira de ações da fase (`AcoesDaFaseView`, PecasDaObra.swift:410). E se a vendida pode definir, editar ou só ver.
3. **Formulário do orçamento:** o spec da etapa 2 prevê o teclado de valor reutilizável também para o orçamento (spec:132). Com 21+ tópicos, um teclado por tópico pede uma lista de linhas tocáveis em vez de campos. Também: o segmentado "Só o total"/"Por tópico", o pré-preenchimento pela soma e se o Salvar vazio pergunta.
4. **Três níveis com duas cores?** O site usa o mesmo âmbar para "perto" e "passou". Decidir se o app separa (sem usar vermelho, que o spec do orçamento proíbe: spec do orçamento:16-17) e conferir o contraste nos quatro combos.
5. **Afazeres na tela da obra ou fora dela.** No site, o painel fica entre as ações e os gráficos, com o campo sempre visível. No app: campo fixo na tela, botão que abre folha, ou seção própria. Também: como mostrar texto longo, rótulo do campo para o VoiceOver, o círculo como alternância (traço de botão selecionado) e o arrastar para apagar (a `LinhaArrastavel` já existe).
6. **Busca e mês contra a lista agrupada.** O app agrupa por mês e tem o cartão "A vencer" (ObraNaTela.swift:82-89). Decidir se o filtro de mês vira um seletor, um salto para o mês ou some. Decidir onde vai a busca (`.searchable` na barra ou campo na lista), o que acontece com "A vencer" e com os cartões de mês durante a busca, e como a pílula "Lançamentos" mostra "achados/total".
7. **"A pagar" contra "A vencer".** A folha do A pagar mostra os próximos 30 dias; o cartão "A vencer" da lista já mostra todos os gastos futuros, agrupados por mês. Decidir se a folha continua uma folha, se o toque no indicador rola até o "A vencer" ou se os dois convivem. E a volta da seta no indicador.
8. **O retorno às folhas no SwiftUI.** O app tem uma folha por vez (`Folhas.Qual`). Para editar um gasto de dentro do A pagar ou do tópico e voltar: navegação dentro da folha (push para a edição), folha sobre folha, ou troca do `enum` guardando a origem. Incluir o "Apagar gasto" da folha de edição, a pergunta de parcela, o Cancelar, o arrastar para baixo (o site fecha tudo) e a posição de rolagem.
9. **Entrada da folha do tópico na etapa 3.** No site, só pelo orçamento por tópico (Gráficos é da etapa 4). Decidir se o app abre também pela linha "Fora do orçamento" ou por outro lugar, e se a folha fecha quando fica vazia.
10. **Teto do orçamento:** seguir o teto do teclado do app (R$ 99.999.999,99) ou aceitar o que o site aceita.

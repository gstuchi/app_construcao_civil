# Custta nativo, etapa 3: dentro da obra

Data: 2026-10-18. Spec da etapa 3 do app nativo (`docs/specs/2026-10-06-app-nativo-design.md`, seção "Etapas"): orçamento previsto × real, detalhe do tópico, a folha "A pagar" com a volta à folha de origem, busca e filtro por mês e afazeres. Ele junta o que o Giovani aprovou no mockup do Croqui (duas partes, 18/10, todas as recomendações) e as decisões de planejamento que já têm recomendação. As decisões grandes do plano passam antes pelo conselho (seção "Para o conselho"); o plano de implementação, com protótipo, tarefas e código, é escrito depois dele, a partir daqui.

## Contexto

A etapa 2 fechou com o #76 (18/10, `33ba862`): o app lança, edita e apaga gasto, cria, edita e apaga obra, muda a fase e registra a venda. Desde o build 5.1 ele grava na conta de quem entra: a guarda da conta de teste saiu, e o Giovani lançou e apagou um gasto na conta de sempre. O checklist do aparelho da etapa 2 fecha junto com este spec.

A etapa 3 não muda o formato do estado. `orcamento` e `afazeres` já existem dentro da obra, o app já os lê e os preserva (`Modelo.swift`, `Normalizacao.swift`), e as `firestore.rules` não olham dentro da obra. O que é novo é o app **gravar** os dois: duas mutações novas, já na conta de sempre, com o documento `dados/{uid}` inteiro regravado a cada salvar, como no site.

## Mockup aprovado

Fora do repositório, em `~/Documents/custta-mockups/nativo/etapa3/` (abrir no Chrome, com a pasta `globo/` ao lado; o resumo de cada parte e as decisões estão no `LEIA-ME.md` da pasta, e o pedido ao Croqui no `BRIEF.md`):

| Parte | Arquivo | O que desenha | Aprovação |
| --- | --- | --- | --- |
| 1 | `parte1.html` | o orçamento na tela da obra (opção A), a tela Orçamento, a folha do orçamento, a obra vendida e o detalhe do tópico | 18/10, "A, recomendado, todas" |
| 2 | `parte2.html` | a folha "A pagar · 30 dias", a volta à folha de origem, a busca e o filtro por mês, os afazeres e as duas doses de vidro | 18/10, "recomendado em tudo, vidro (a)": todas as recomendações, e o vidro do escuro fica como está |

Cada parte traz no fim "O que vem do site e o que muda" (obrigatório × diferente do site), "Medidas e tokens para o código" e a tabela de contraste. Os 143 prints (`parte1-*.png` e `parte2-*.png`; as doses de vidro das telas da parte 1 saíram com a parte 2) são a referência da conferência visual. Depois da aprovação, os oito `*-fosco-escuro*` foram refeitos com a decisão 6. Os números vêm do `calc.js` da main (Casa Alphaville, hoje 12/10/26, orçamento por tópico em 14 tópicos).

O inventário do site para esta etapa, com arquivo e linha conferidos na main `33ba862`, está em `docs/plans/2026-10-18-app-nativo-etapa3-inventario.md`. Os "achados" citados aqui são os dele.

## Decisões de desenho (aprovadas no mockup)

As decisões levam o número do `LEIA-ME.md` de cada parte. Todas as sugestões marcadas no mockup entraram (parte 1, decisão 4; parte 2, decisão 5) e aparecem abaixo, cada uma na sua tela; cada uma sai sem mexer no resto.

**Orçamento na tela da obra (parte 1, decisão 1: opção A).**
- O Total gasto continua no alto, sem nada em cima. O orçamento é a primeira linha do grupo dos indicadores, logo abaixo dele, no mesmo vidro, com o chevron das linhas tocáveis. A obra cresce 169 pt; o cartão do site na obra (opção B, 497 pt) fica no mockup só como referência.
- Sem orçamento, "Definir orçamento" entra nas ações da fase, o lugar do site.
- Com orçamento, por total ou por tópico, a linha mostra o nível do site: "dentro do previsto", "perto do limite" ou "passou do previsto".
- Perto e passou em âmbar, nunca vermelho. No "passou", a barra para no previsto, com uma fresta, e o excesso vem listrado: a diferença está na forma, não só na cor.
- No modo por tópico, a linha traz o pior aviso dos tópicos ("2 tópicos passaram do previsto" ou, sem nenhum, "N perto do limite") e o que está fora.
- **Token novo** de âmbar para texto sobre o vidro do conteúdo (`--amber-v` no mockup): `#6F4705` no claro e o âmbar de sempre no escuro. O âmbar do site dava 3,79–4,15:1 sobre a aurora clara; o novo dá 5,21–5,71:1. Não é o `AlertaEtiqueta` da etapa 2 (`#7A5410` no claro esmeralda).

**Tela "Orçamento".**
- Empurrada pela linha, no caminho de Obras, com título grande e o lápis na barra (o mesmo círculo da obra).
- O cartão do site ("{pct}% usado", "sobra" ou "passou"), mais "previstos em N tópicos" e a frase do que está fora: no modo por tópico, o cartão soma só os tópicos previstos e não fecha com o Total gasto (achado 10).
- "Por tópico" com as frases do site ("Passou R$ 6,2 mil do previsto", "Faltam R$ 3,3 mil — 96%", "Chegou ao previsto — 100%") e uma linha por tópico fora do orçamento, que abre o detalhe (no site, o "Fora do orçamento" é uma linha só, sem toque: achado 11).
- Tópico previsto com gasto abre o detalhe; sem gasto, não abre (site).
- No modo total não há "Por tópico": a tela mostra o "Gasto por tópico" (bruto e % da obra), cada linha abre o detalhe, e no fim vem a dica "Para comparar tópico a tópico, toque no lápis e escolha "Por tópico"."

**Folha "Orçamento da obra" (parte 1, decisão 2).**
- Segmentado "Só o total" | "Por tópico" (os 21 fixos e depois os próprios, até 50), com o total ao vivo. Abre no modo salvo. "Definir", sem orçamento, abre em "Só o total" com as teclas já abertas, o "Salvar" apagado até ter valor e sem "Tirar orçamento".
- Trocar para "Só o total" com o total vazio preenche com a soma dos tópicos ("Preenchido com a soma dos tópicos."). Trocar de modo não grava. No modo "Só o total", o rodapé diz "Comparado com o Total gasto (bruto), com as parcelas a vencer."
- Os valores entram no `TecladoDeValor`, com as teclas **encaixadas embaixo da folha**, ‹ › para o tópico anterior e o próximo e "Pronto". Teto de R$ 99.999.999,99, o do teclado do app; o site não tem teto (achado 12).
- "Tirar orçamento" com a pergunta do site ("Tirar o orçamento desta obra? Os gastos continuam como estão."). Salvar com tudo vazio faz a mesma pergunta; no site, tira sem perguntar (achado 6). Sem orçamento antes, o "Salvar" fica apagado enquanto tudo está vazio. Depois de tirar, a linha some da obra e a tela Orçamento volta para a obra.
- Na letra máxima, o segmentado e o total rolam com a lista, e o "Salvar" sai enquanto as teclas estão abertas.

**Obra vendida (parte 1, decisão 3).** Igual ao site: com orçamento, mostra, edita e tira; sem orçamento, não oferece "Definir orçamento" (achado 5).

**Detalhe do tópico (folha).**
- Resumo num grupo sólido: bruto, corrigido e "N gastos · N% da obra"; a linha do orçamento do tópico, quando ele tem previsto, ou "Sem valor no orçamento" no lugar da barra, quando ele está fora.
- Os gastos do tópico em "A vencer" (o próximo primeiro, como na obra) e "Pagos" (o mais novo primeiro, como no site), com a linha de gasto da etapa 2 sem o tópico.
- Tocar num gasto empurra a edição dentro da mesma folha; "Salvar" volta ao detalhe na mesma posição, com os números novos e a linha acesa (sem a etiqueta "novo", que é de gasto lançado).
- A folha desce quando sai o último gasto do tópico (site).

**A pagar · 30 dias (parte 2, decisão 1: a folha, junto com o "A vencer").**
- A seta volta ao indicador, com "Parcelas e gastos futuros" embaixo; a linha inteira é o botão e abre a folha do site.
- Título igual ao do indicador, "A pagar · 30 dias" (o do site, "A pagar · próximos 30 dias", corta na letra máxima).
- O mesmo total e os mesmos vencimentos do indicador ("3 vencimentos · a partir de amanhã"), agrupados por mês, sem a etiqueta "a vencer" em cada linha. No fim, uma frase diz quanto vem depois dos 30 dias e que isso está no "A vencer".
- O cartão "A vencer" da lista não muda e continua com todos os gastos futuros.
- Vazia, a folha abre com "Nenhum gasto previsto para esse período." e não fecha quando fica vazia (site; achados 13 e 17). O botão "Fechar" do site sai: fecham o × e o puxar.

**Volta à folha de origem (parte 2, decisão 2: o puxar fecha tudo).**
- Editar um gasto do A pagar ou do detalhe do tópico empurra a edição na mesma folha, com o chevron de voltar e o nome da origem no subtítulo ("A pagar", "Cerâmica").
- "Salvar", o chevron e as saídas do apagar voltam para a origem, **na mesma rolagem** e com os números novos; no "Salvar", a linha editada volta acesa. No site, a folha é remontada e volta ao topo (achado 15).
- O apagar vale para o gasto à vista ("Apagar este gasto?", com nome e valor) e para a parcela ("Apagar só esta parcela", "Apagar a compra toda (N parcelas)", "Cancelar"), com os textos da etapa 2.
- Com mudança, o chevron pergunta antes de descartar: "Você mudou este gasto. As mudanças ainda não foram salvas." ("Descartar mudanças" / "Continuar editando").
- Puxar para baixo fecha a folha inteira, como o sistema e o site. Com mudança, a folha não desce e pergunta (no site, fecha sem perguntar: achado 14).
- Arrastar para apagar funciona dentro da folha, e ela continua aberta.
- O mockup desenha a volta como navegação dentro da folha, como a parte 1. A forma técnica vai ao conselho.

**Busca e filtro por mês (parte 2, decisão 3: opção A).**
- Dois botões redondos, lupa e mês, ao lado da pílula "Lançamentos". A tela não cresce; o campo sempre à vista do site (opção B) descia a lista 54 pt em toda obra.
- A lupa abre o campo ("Buscar gasto ou tópico") e o teclado; o × fecha a busca e limpa o texto. A busca é sem acento e sem diferença de maiúscula, na descrição ou no tópico, com o texto aparado (achado 16).
- O mês é escolhido num `Menu` do sistema, com "Todos os meses" e os meses que têm gasto, por extenso, como nos cartões da lista, e quantos gastos cada um tem.
- O filtro aparece num chip com ×, e a pílula conta "achados/total".
- Com filtro, o "A vencer" abre sozinho com os achados, cada mês soma só os seus achados, e "Soma dos achados" dá o total.
- Sem resultado: "Nada encontrado com esse filtro.", a frase "A busca olha a descrição e o tópico, com ou sem acento." e o botão "Limpar a busca", "Limpar o mês" ou "Limpar busca e mês", conforme o filtro. Mês sem gasto: "Nenhum gasto em março de 2026." e "Ver todos os meses".
- **O filtro de mês nunca fica escondido**, o conserto do achado 1: o chip mostra o mês até a pessoa tirar, e o menu mantém o mês marcado, mesmo quando ele não tem mais gasto.
- O filtro vive só na tela e zera ao trocar de obra (site). Indicadores e orçamento continuam com a obra inteira.
- Na letra máxima, a pílula e os botões ocupam duas linhas, o campo fica com a largura toda e o próprio botão da lupa vira × para fechar.

**Afazeres (parte 2, decisão 4: opção A).**
- Uma linha na obra, entre as ações e os lançamentos, em três estados: com pendentes, "N pendentes" e o primeiro deles (até duas linhas); tudo feito, "tudo feito" e quantos; vazio, a frase do site. A obra cresce 87 pt; o painel do site (opção B) tinha 639 pt e crescia a cada afazer. Aparece em todas as fases, como no site.
- A linha empurra a tela "Afazeres":
  - campo no alto, com o rótulo "Novo afazer" para o VoiceOver (no site não tem) e até 500 caracteres; o novo entra no topo e o cursor fica no campo;
  - pendentes com o texto inteiro, quebrando linha (no site, o pendente corta numa linha: achado 2);
  - círculo que marca, com alvo de 44 pt; "Feitos · N" fechado;
  - o feito vai para o alto dos Feitos e, desmarcado, volta ao alto dos pendentes (achado 4); fica riscado e na cor secundária (a opacidade 0,5 do site não passa de 4,5:1);
  - arrastar para apagar, sem pergunta (spec dos afazeres); o × fixo do site sai.
- Vazio: "Nenhum afazer." / "Anote o que falta na obra."

**Quatro combos e letra máxima** (402 e 375 pt), em todas as telas novas.
- Dinheiro dentro de frase vai para a própria linha e encolhe para caber; o chip quebra em duas linhas; as teclas param no tamanho AX2; o afazer quebra inteiro, com o círculo maior.
- **Correção que vale também para a etapa 2:** na letra máxima, o cabeçalho do "A vencer" empilha título, valor e linha de baixo, e o valor encolhe para caber. No mockup da etapa 2, o valor passava por cima do título. O plano confere no app (o laudo de leitura não vê corte) e, se o defeito estiver lá, corrige no primeiro PR do app.

**Vidro.**
- As duas doses seguem a receita do app (`Vidro.swift`): Transparente (padrão) e Fosco, com a camada do tom do fundo no escuro a 50% e 20%. **O vidro do escuro fica como está** (parte 2, decisão 7: "vidro (a)"). É a camada de 50% que faz o Transparente escuro parecer fosco; tirá-la derruba o pior texto da obra de 5,42:1 para 3,87:1.
- **Parte 2, decisão 6: texto secundário no Fosco escuro.** Passa a ser o `SecundarioTransparente`, como o Aumentar contraste já faz (`VidroTokens.secundario`, Vidro.swift:96-106). No mockup, o `SecundarioFosco` ficava abaixo de 4,5:1 em dois pontos claros da aurora: 4,24:1 em "de R$ 1.019.847,85 previstos…", no cartão do Orçamento, e 4,47:1 em "6 gastos · o próximo…", no "A vencer" da busca. Com a troca, eles vão a 5,25:1 e 5,55:1, e o pior do Fosco passa a 4,56:1 (o mesmo chip verde do claro). No claro, nada muda. A forma (a variante escura do `SecundarioFosco` nos dois skins, ou o `secundario` olhando o esquema de cor) fica para o plano.
  - Hoje o Fosco aparece sempre nas telas de entrar, criar conta e falta pouco e, com o Aumentar contraste, em todas (já com o secundário do Transparente). Nas outras telas do app, só quando Ajustes › Aparência chegar, na etapa 5.
  - A troca muda, portanto, o secundário das telas de entrada no escuro, para mais contraste, e o laudo delas muda junto.
- **Pior contraste medido:** Transparente 4,56:1, no chip verde "dentro do previsto" no claro, o par de tokens do site (o mesmo chip "estimativa" da etapa 2); fora dele, 4,84:1 ou mais. O "Salvar" apagado (3,13:1) é estado desativado e fica fora da regra, como no sistema.

## Regras: iguais ao site

O comportamento vem do site de hoje (`app.js`: o orçamento na obra, `formOrcamento`, os afazeres, a lista de lançamentos, `sheetTopico`, `sheetAPagar`, `gastoRow` e `formGasto` com o `aoFechar`; `calc.js`; `dados.js`), lido na main `33ba862`. O inventário tem o arquivo e a linha de cada uma. O cálculo em si não muda: o núcleo já tem `orcamentoObra`, `aPagar`, `filtraGastos` e `semAcento`, com vetores, e a lista de obras já mostra o orçamento (`textoOrcamentoNaLista`). As regras que importam para o código:

- **Orçamento** (`orcamentoObra`, já no núcleo com vetores):
  - base no total **bruto**, com as parcelas futuras, nunca no corrigido;
  - `pct` arredondado; "perto" a partir de 90%; "passou" com mais de meio centavo acima;
  - por tópico, só os previstos > 0, da maior razão gasto/previsto para a menor (empate pelo id);
  - "fora": tópicos com gasto e sem previsto, que não entram no geral (`foraTotal`).
- **O que a folha do orçamento grava:** só o modo ativo; no total, `total > 0` grava `{modo: 'total', total}`; por tópico, só os valores > 0; vazio tira o orçamento (a chave some, não vira `null`). A leitura aceita até 100 tópicos (`MAX_TOPICOS_ORC`).
- **Afazeres:** `{id, texto, feito}`. Adicionar apara o texto, vazio não faz nada, até 500 (`LIMITES.afazer`), entra no começo do array com `feito: false`. Marcar pelo círculo ou pelo texto; apagar sem perguntar; pendentes antes dos feitos; contador "({N} pendente(s))".
- **Busca** (`filtraGastos` e `semAcento`, já no núcleo com vetores): na descrição ou no nome do tópico (tópico apagado, pelo id); o mês por `data.slice(0, 7)`; os dois em E. Só a lista muda. O contador é "N" ou "achados/total". Os meses são os que têm gasto, do mais novo ao mais antigo, com os futuros.
- **Detalhe do tópico:** bruto com as parcelas futuras; corrigido até a venda ou hoje; "% da obra" = `Math.round(bruto / totalBruto × 100)`, ou 0 com total zero (o mesmo arredondamento do donut). No site, os gastos vêm por data e id, do mais novo ao mais antigo (app.js:1158); no app, o "Pagos" segue essa ordem e o "A vencer" põe o próximo primeiro, como na lista da obra.
- **A pagar** (`aPagar`, já no núcleo): data depois de hoje e até hoje + 30 dias, em hora local, por ordem de data; abre mesmo vazio.
- **Volta:** "Salvar", "Cancelar" e as três saídas do apagar voltam para a origem; erro de validação não fecha nem volta.
- **Formato do estado:** nenhuma chave nova. `firestore.rules` não muda nesta etapa.

As diferenças aprovadas estão na seção anterior: o lugar do orçamento, da busca e dos afazeres; as teclas encaixadas e o teto; salvar vazio pergunta; a volta na mesma rolagem; o puxar que pergunta; o filtro de mês à vista; o afazer inteiro; a ordem e a cor do feito; a busca aparada. E uma regra de gravação que não é desenho: **o app guarda o que não mostra** (achado 7). A gravação do orçamento mantém os campos desconhecidos dentro de `orcamento` e o previsto de tópico que não está na lista da folha (tópico próprio apagado); o site, hoje, perde os dois no primeiro "Salvar".
- O tópico fora da lista é raro (Ajustes não deixa apagar tópico com previsto). Ele continua no "Por tópico" com o id como nome, como hoje, e sai com "Tirar orçamento" ou ao salvar em "Só o total"; a folha não ganha linha para ele.

## PR 0 do site: as regras que só vivem no app.js

Como na etapa 2, a regra que hoje só existe dentro do `app.js` sobe antes para o `calc.js` ou o `dados.js`, num PR só do site, e entra nos vetores (`scripts/vetores-calc.mjs`), para site e app serem conferidos pelos mesmos casos. O PR segue a forma do PR 0 da etapa 2 (conselho de 13/10, segunda rodada):
- a cópia em Swift e o leitor de cada grupo de vetores entram no mesmo commit da regra, porque o núcleo barra grupo de vetor sem leitor;
- o comportamento do site não muda (as suítes de browser continuam verdes), salvo as correções desta seção;
- uma subida só do `CACHE` do `sw.js`, no fim.

**As nove regras** (inventário, "Regras que só vivem no app.js", itens 1 a 9; linhas do `app.js` da main):

| # | Regra | `app.js` | Sobe para |
| --- | --- | --- | --- |
| 1 | Frases do orçamento: a pílula por nível; "Passou {X} do previsto", "Faltam {X} — {pct}%" e "Chegou ao previsto — {pct}%", com o limiar de meio centavo na sobra; o rodapé "sobra"/"passou" com o valor absoluto; a linha "{moneyCurto(gasto)} / {moneyCurto(previsto) sem o R$}" | 275, 283-287, 294-297, 305 | `calc.js` |
| 2 | Largura da barra: `pct` limitado a 0–100 | 277 | `calc.js` |
| 3 | Quando mostrar cada peça do orçamento: o cartão só com orçamento válido; "Por tópico" só no modo por tópico; "Definir" só sem orçamento e fora da vendida; a linha do tópico tocável só com gasto | 301, 308, 398, 445 | `calc.js` |
| 4 | O que a folha do orçamento grava: total > 0 ou tira; por tópico, só os valores > 0; vazio tira | 1753-1762 | `dados.js` |
| 5 | O total preenchido pela soma dos tópicos ao trocar de modo, e a soma ao vivo com `max(0, …)` | 1722, 1737-1740 | `calc.js` |
| 6 | Afazeres: adicionar (aparar, vazio, limite, começo do array, `feito: false`), alternar e apagar; a ordem pendentes → feitos; o contador "({N} pendente(s))" | 457-464, 489-495, 500-516 | `dados.js` (as mutações) e `calc.js` (a ordem e o contador) |
| 7 | Meses do filtro: os meses com gasto, do mais novo ao mais antigo, com os futuros | 430, 439 | `calc.js` |
| 8 | Contador dos lançamentos: vazio, "N" ou "achados/total" | 711-712 | `calc.js` |
| 9 | Resumo do tópico: bruto, corrigido até a venda ou hoje (pelo `fimCorrecao`, que o `app.js` hoje copia à mão) e "% da obra" | 1133-1139 | `calc.js` |

- **Uma décima, pequena, aprovada pelo Giovani em 18/10: o item 10 do inventário**, o texto da folha do A pagar ("{N} vencimento(s) · a partir de amanhã", app.js:1117). Ele não está no núcleo: a etiqueta do indicador (`ObraNaTela.swift:171`) usa a mesma contagem, mas diz "nada em 30 dias" no zero, e a folha vazia diz "0 vencimentos · a partir de amanhã". O mockup o marca como obrigatório, e um vetor custa pouco.
- O item 11, a guarda de Ajustes, fica para a etapa 5.
- O rótulo "out/26" do `<select>` fica no site: o app escreve o mês por extenso.
- Quantos gastos cada mês tem (o menu do app) entra na regra 7, que passa a devolver o mês e a contagem; o site ignora a contagem.
- De carona, o comentário trocado em cima do `sheetAPagar` (achado 9), no mesmo commit da regra 9.

**Correção do filtro de mês preso (achado 1).** Hoje, com um mês escolhido, apagar o último gasto dele (ou mudar a data para outro mês) tira o mês do `<select>`, que passa a mostrar "Todos os meses" enquanto o filtro continua no mês velho. A lista diz "Nada encontrado com esse filtro." e o contador "0/N", sem nada à vista que explique; só sai trocando de obra ou escolhendo outro mês.
- O conserto é o mesmo do app: a lista de meses da regra 7 inclui o mês escolhido mesmo sem gasto. O `<select>` continua mostrando o mês que filtra, e a pessoa pode tirá-lo.
- Entra com vetor (mês escolhido sem gasto; mês escolhido com gasto não se repete; sem mês escolhido, nada muda) e com um teste de browser do caminho do defeito: escolher o mês, apagar o último gasto dele, conferir o `<select>` e o contador.

**Três alinhamentos, aprovados pelo Giovani em 18/10 (além do pedido).** Em três regras, o mockup aprovado faz o app diferir do site. Subir a regra já com o comportamento do app evita duas cópias diferentes da mesma gravação:
- **Ordem do afazer (achado 4):** marcar ou desmarcar leva o afazer ao começo do array. Com a exibição de hoje do site (pendentes e depois feitos, cada grupo na ordem do array), o feito vai para o alto dos Feitos e o desmarcado para o alto dos pendentes, no app e no site. O mockup desenha os dois: o que acabou de ser marcado fica no alto dos Feitos, e tocar de novo devolve ao alto dos pendentes. É o que o mockup chama de "a ordem dos afazeres muda o array na nuvem, e o site mostra a mesma ordem".
- **O orçamento guarda o que a folha não mostra (achado 7):** com a regra 4 no `dados.js` já preservando, o site deixa de perder esses dados.
- **Busca aparada (achado 16):** o texto é aparado antes do `filtraGastos`; no site, é um `trim()` na leitura do campo.

**Armadilhas conferidas.** Nenhuma chave nova no blob, então as rules não mudam. Nenhum arquivo novo na raiz, então o `ASSETS` do `sw.js` não muda; o `CACHE` sobe uma vez, porque `calc.js`, `dados.js` e `app.js` mudam. Nenhuma dependência de runtime no browser. Nada inline no HTML (CSP).

**Regras novas do app, sem vetor do site** (com teste próprio, como o "Tópico inicial" da etapa 2):
- os tópicos que passaram do previsto e o aviso da linha do orçamento;
- "previstos em N tópicos" e a frase do que está fora, no cartão;
- o gasto por tópico no modo total (a mesma soma da regra 9);
- o A pagar agrupado por mês e quanto vem depois dos 30 dias;
- "Soma dos achados";
- "A vencer" e "Pagos" no detalhe do tópico;
- o primeiro pendente na linha dos afazeres (pela ordem da regra 6).

## Arquitetura

As três camadas do spec do app nativo, sem pacote novo.

**Núcleo (`CusttaNucleo`).**
- A cópia das dez regras do PR 0, com os vetores, e as regras novas do app, com teste próprio.
- Duas mutações novas sobre o estado, que devolvem o estado novo, como as da etapa 2 (`Mutacoes.swift`):
  - orçamento: definir ou editar (o objeto da regra 4, guardando o que a folha não mostra) e tirar;
  - afazeres: adicionar, alternar e apagar.
- Editar e apagar gasto de dentro das folhas usam as mutações que já existem (`editandoGasto`, `apagandoGasto`, `apagandoCompra`).

**Dados e estado (app).**
- O `ModeloApp` ganha as ações das mutações novas, pelo mesmo caminho de gravação da etapa 2 (`Sincronizador.salvar`), com a recusa de `nao-carregado` e o alerta do site em toda tela que grava, afazeres e orçamento inclusive.
- O filtro (texto e mês) mora na tela da obra, não no modelo: zera ao trocar de obra e não vai para a nuvem.
- Uma mudança vinda de outro aparelho não pode apagar o afazer em digitação nem tirar o foco da busca (achado 3). O texto em digitação e o foco moram na tela, e o redesenho que chega do `Sincronizador` não os recria.
- A folha de origem e a edição dentro dela: a forma técnica sai do conselho. Hoje há uma folha por vez (`Folhas.Qual`, Folhas.swift:10-20), e a folha com passos já é um `NavigationStack` dentro da `.sheet` (`FolhaEmPassos`, conselho de 13/10, decisão b).

**Telas (app).**
- A linha do orçamento nos indicadores; a tela Orçamento (push no caminho de Obras, que mora no `PrincipalView`); a folha do orçamento com as teclas encaixadas; o detalhe do tópico (folha).
- A seta no indicador "A pagar" e a folha dele; a edição empurrada nas duas folhas.
- Na lista: os botões de busca e de mês, o campo, o chip, "Soma dos achados" e os estados vazios.
- A linha dos afazeres e a tela Afazeres (push).
- Arrastar para apagar: a `LinhaArrastavel` da etapa 2 (arrastar próprio, conselho de 13/10, decisão a), também na tela Afazeres. O mockup cita o `swipeActions` do sistema; a divergência é a mesma da etapa 2 (o `.swipeActions` só existe dentro de `List`, e a `List` não desenha o grupo de vidro). Dentro das folhas, que são sólidas, uma `List` seria possível: entra no item 1 do conselho.
- Teclado de valor: o `TecladoDeValor` da etapa 2, numa forma nova, encaixada embaixo da folha, com ‹ › e "Pronto".

## PRs

Recomendação, que passa pelo conselho (é a ordem do trabalho): **fatias que já gravam**, como na etapa 2. Cada PR do app entrega um bloco inteiro da etapa, gravando de verdade, e gera um build no TestFlight que o Giovani testa no iPhone.

| PR | O que entrega | Build |
| --- | --- | --- |
| 0 (site) | As dez regras do `app.js` no `calc.js` e no `dados.js`, com vetores, cópia em Swift e leitores; a correção do filtro de mês preso; os três alinhamentos; uma subida do `CACHE`. | — |
| 1 | Orçamento (a parte 1 sem o detalhe do tópico): a linha nos indicadores com os três níveis e o aviso dos tópicos; a tela Orçamento; a folha com as teclas encaixadas; definir, editar e tirar; a obra vendida; o token âmbar sobre o vidro; a decisão 6; a correção do "A vencer" na letra máxima, se o app tiver o defeito. Conferência cruzada do orçamento. | sim |
| 2 | Detalhe do tópico e A pagar, com a volta à folha de origem: a seta no indicador; as duas folhas; a edição empurrada; apagar à vista e parcela de dentro da folha; o puxar que pergunta; o arrastar dentro da folha; a folha do tópico que desce sem gasto. As linhas da tela Orçamento passam a abrir o detalhe. | sim |
| 3 | Busca e filtro por mês; afazeres (linha, tela, adicionar, marcar, apagar e ordem); os dois temas e a letra máxima conferidos em todas as telas da etapa; o checklist do aparelho da etapa 3. Conferência cruzada completa. | sim |

- **Por que esse corte:** o PR 1 traz a primeira mutação nova (orçamento) e as teclas encaixadas; o PR 2 traz o mecanismo da volta, que nasce no detalhe do tópico e serve ao A pagar, e só usa mutações que já existem; o PR 3 traz a segunda mutação nova (afazeres) e o filtro da lista.
- No build do PR 1, as linhas de tópico da tela Orçamento aparecem sem chevron e sem toque; o detalhe chega no PR 2, como o + da etapa 2 chegou um PR depois da tela da obra.
- **Ordem:** o PR 1 pode começar quando o PR 0 entrar em revisão, com rebase antes da primeira tarefa que use as regras novas; o PR 2 começa com o OK do Giovani no build do PR 1, e o PR 3 com o OK do PR 2. Cada PR nasce num worktree novo a partir da `origin/main` atualizada.

## Conta

Desde o #76, o app grava na conta de quem entra, e os builds da etapa 3 já gravam na conta de sempre.

Aprovado pelo Giovani em 18/10: **seguir na conta de sempre**. O caminho de gravação é o da etapa 2, já conferido no aparelho. As duas mutações novas só mexem dentro de uma obra e passam pelos vetores e pela conferência cruzada antes de cada build. Os itens do checklist que tiram dado (tirar orçamento, apagar afazer, apagar gasto de dentro da folha) usam uma obra de teste criada no próprio app e apagada no fim. A conta de teste (`custta-teste`) continua existindo para o caso de uma gravação suspeita.

## Testes e validação

Os mesmos portões da etapa 2, estendidos:

1. **Vetores:** as regras do PR 0 e o conserto do filtro conferidos contra o site (`swift test` no job `nucleo`). Os vetores de cada regra levam casos fora do exemplo de sempre: o nome do caso não prova nada sem um caso que mate a mutação.
2. **Unidade do app:** modelo e ações com serviços falsos (orçamento, afazeres, a recusa de `nao-carregado`), e as regras novas do app.
3. **Telas (XCUITest):**
   - definir o orçamento por total e por tópico (com ‹ ›), trocar de modo com o total vazio, salvar vazio, tirar;
   - a obra vendida com e sem orçamento;
   - abrir o detalhe do tópico pela tela Orçamento (previsto com gasto, fora e, no modo total, pelo "Gasto por tópico"); a folha que desce sem gasto;
   - abrir o A pagar, vazio e com vencimentos;
   - editar de dentro das duas folhas e voltar na mesma rolagem, com a linha acesa; descartar pelo chevron; puxar com e sem mudança; apagar à vista e parcela; arrastar dentro da folha;
   - buscar com acento e sem, escolher o mês, o mês que fica sem gasto, "Limpar a busca", "Ver todos os meses";
   - adicionar vários afazeres seguidos, marcar, desmarcar, abrir "Feitos", apagar arrastando;
   - uma mudança vinda de outro aparelho durante a digitação de um afazer e com a busca aberta (achado 3).
4. **Leitura sobre o vidro e acessibilidade:** o laudo de leitura (portão na CI) e as auditorias cobrem as telas novas nos dois temas (claro e escuro; a pele azul saiu do site e do app em 21/10, no #81) e na letra máxima, e as telas de entrada no escuro depois da decisão 6.
5. **Conferência visual:** simulador lado a lado com os prints do mockup, tela a tela.
6. **Conferência cruzada** contra os emuladores (`npm run test:app-ios:cruzado`):
   - orçamento: definir por total, por tópico, trocar de modo e tirar; o campo desconhecido e o tópico fora da lista guardados;
   - afazeres: adicionar, marcar, desmarcar e apagar, com a ordem vista no site;
   - editar e apagar de dentro das folhas;
   - e o que o site grava aparece no app.
   Cada passo é conferido no documento, não só o final: um roteiro que só compara o resultado deixa passar regra quebrada no meio.
7. **Site:** as suítes de browser continuam verdes no PR 0, mais o teste novo do filtro de mês, conferido por mutação.
8. **Aparelho:** um checklist da etapa 3 no estilo do da etapa 2, testado pelo Giovani a cada build e fechado no PR 3.

## Para o conselho

Decisões grandes que o planejador leva ao conselho amanhã (19/10), antes do plano: três subagentes Opus com lentes diferentes (desempenho e bateria; acessibilidade e legibilidade; fidelidade ao mockup, à HIG e ao spec), propostas às cegas, crítica cruzada, o Prumo como presidente. Quando a decisão depende de medida, um protótipo no simulador vem antes, como na etapa 2.

1. **Volta à folha de origem: navegação dentro da folha × folha sobre folha.** A edição como um passo empurrado no `NavigationStack` da folha do A pagar ou do tópico (o que o mockup desenha); uma segunda `.sheet` sobre a de origem; ou a troca do `Folhas.Qual` guardando a origem, como o site, que remonta a folha. Pesam:
   - o desenho aprovado: chevron e subtítulo com a origem, volta na mesma rolagem, puxar que fecha tudo e pergunta com mudança;
   - o `Folhas.Qual` de uma folha por vez e o `PedidoDeApagar` da etapa 2, que apaga depois que a folha desce, com a animação na tela da obra; aqui a folha de origem continua aberta e a linha sai dentro dela;
   - o "tentou fechar" do UIKit (a ponte da `FolhaEmPassos`) com mudança num passo de dentro;
   - os alertas dentro da folha: no iOS 27, o `.alert` da raiz toma o lugar de outro alerta e, com folha aberta, a derruba;
   - o arrastar da linha dentro da folha contra o puxar da folha e o voltar pela borda, e se ele é a `LinhaArrastavel` da lista da obra ou uma `List` com `.swipeActions`, possível numa folha sólida;
   - o VoiceOver (escape em cada passo e o foco na volta) e a folha do tópico que desce quando sai o último gasto.
2. **Teclas encaixadas na folha do orçamento.** Teclas próprias no rodapé da folha (o `TecladoDeValor` num `safeAreaInset`, com a linha ativa como estado da folha) × um campo por tópico com o teclado próprio como `inputView` (UIKit). Pesam:
   - o VoiceOver: o valor lido a cada tecla, a ordem dos 21 ou mais tópicos, ‹ › como ação;
   - a rolagem até a linha ativa;
   - a letra máxima em 375 pt, com as teclas no AX2 e o "Salvar" que sai;
   - o desempenho com a lista mais longa: até 71 linhas (os 21 fixos e até 50 próprios, o limite das rules).
3. **Corte e ordem dos PRs.** A proposta da seção "PRs" (PR 0; orçamento; folhas com a volta; busca e afazeres) × outras, como a parte 1 e a parte 2 em dois PRs do app, ou a volta antes do orçamento. Pesam: o mecanismo da volta nasce no detalhe do tópico (parte 1) e serve ao A pagar (parte 2); o tempo da CI por PR; o risco de cada mutação nova chegar sozinha a um build.

Não vão ao conselho, porque o mockup ou o spec já fixam, ou porque são pequenas: textos, medidas e tokens do mockup; a decisão 6; o vidro do escuro; a busca num campo próprio, e não no `.searchable` da barra (decisão 3); o arrastar da tela Afazeres pela `LinhaArrastavel` (a divergência com o `swipeActions` do mockup é a da etapa 2, decidida em 13/10); o filtro morando na tela; a conta (seção "Conta").

## Decisões tomadas por recomendação

- **Mockup:** todas as recomendações do Croqui, aprovadas pelo Giovani em 18/10 ("A, recomendado, todas" na parte 1; todas na parte 2; o vidro do escuro como está), inclusive a decisão 6.
- **PR 0 na forma do da etapa 2:** a cópia em Swift e os leitores no mesmo PR do site; é o que mantém site e app conferidos pelos mesmos vetores desde o primeiro commit.
- **As nove regras pedidas e uma décima, aprovada em 18/10:** o texto da folha do A pagar não está no núcleo e é obrigatório no mockup; a guarda de Ajustes é da etapa 5.
- **O conserto do filtro preso é o mesmo no site e no app:** o mês escolhido nunca some da lista.
- **Três alinhamentos no PR 0, aprovados em 18/10** (ordem do afazer, orçamento que guarda o que não mostra, busca aparada): uma regra só para os dois.
- **Conta de sempre, aprovada em 18/10**, com uma obra de teste para os itens que tiram dado.
- **Teto do orçamento igual ao do teclado** (R$ 99.999.999,99): o app já tem esse teto em todo valor.
- **Checklist da etapa 2 fechado** neste PR: o último item ("Depois do OK do PR 3: a conta real") foi feito pelo Giovani no build 5.1.

## Riscos

- **Mutações novas na conta de sempre.** Orçamento e afazeres regravam o documento inteiro, como tudo. Mitigado pelos vetores, pela conferência cruzada a cada passo, pela preservação de campos desconhecidos (também dentro de `orcamento`) e pela recusa de `nao-carregado`.
- **A volta à folha de origem** (ver "Para o conselho"): alertas dentro de folha no iOS 27, o "tentou fechar" num passo de dentro e gestos concorrentes.
- **Teclas encaixadas:** foco, VoiceOver e a letra máxima em 375 pt (13 mini).
- **Mudança de outro aparelho durante a digitação** (achado 3): pede teste de tela com escrita remota pelo emulador.
- **Tempo da CI.** No último run do `app-ios.yml` (#76, 18/10): `app` em 45 min (teto de 75), `laudo` em 41, `laudo-parte3` em 33 e `auditoria` em 44 (teto de 60 cada). As telas novas somam cenas ao laudo e às auditorias; o plano mede e, se um job passar de ~50 min, abre o job da leitura da etapa 3, como foi feito com o da parte 3.
- **A decisão 6 muda as telas de entrada no escuro:** o laudo e os prints delas mudam, só para mais contraste.
- **Lista longa no orçamento:** a folha tem até 71 linhas (os 21 fixos e até 50 próprios, o limite das rules), e a tela Orçamento até 100 tópicos previstos (o teto da leitura, `MAX_TOPICOS_ORC`, que conta também tópico fora da lista).

## Fora do escopo

- **Etapa 4:** gráficos (e com eles a outra entrada do detalhe do tópico, pela legenda e pelo donut), relatório, simulador "Vale a pena?" e PDF.
- **Etapa 5:** Ajustes › Aparência (o Fosco escolhido pela pessoa), tópicos próprios (criar e apagar, com a guarda do orçamento), exportar e notificações. O push já usa o `orcamentoObra` e conta os afazeres; nada muda nele. Fica registrado que ele conta o afazer de um jeito diferente do site (achado 8).
- **Fora da etapa:** mudança no site além do PR 0; mudança nas `firestore.rules`.

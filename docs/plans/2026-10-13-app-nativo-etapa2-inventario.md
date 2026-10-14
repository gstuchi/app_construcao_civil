# Inventário do site para a etapa 2 do app nativo

Data: 2026-10-13. Este levantamento descreve o que o PWA faz hoje nos fluxos da etapa 2: tela da obra, gasto, fases e venda, criar, editar e apagar obra, e os estados. Ele foi tirado do código no `origin/main` (`7c700a5`) para o plano da etapa 2. O [spec](../specs/2026-10-13-app-nativo-etapa2-design.md) está hoje no branch `docs/app-nativo-etapa2-spec`. Caminhos e números de linha são dessa revisão e relativos à raiz do repositório. As linhas do spec são as do arquivo nesse branch.

Este é um levantamento feito por leitura, e as lacunas estão em "Cobertura". Antes de portar um trecho, confira no código: o código manda, e este documento só aponta onde olhar.

**Cobertura.**
- **Lidos inteiros:** `app.js` (2097 linhas), `calc.js`, `dados.js`, `firestore.rules`, `teclado.js`, `gestos.js` e `ui-confirm.js`.
- **`cloud.js`:** li a fila de escrita, a leitura e a recusa `nao-carregado` (cloud.js:140-269 e 600-727). Não li login, conta e limpeza de cache (cloud.js:1-139 e 270-599).
- **`index.html`:** li o cabeçalho, Início, Obra, o + e a folha (index.html:150-215 e 318-341).
- **Por grep ou só no trecho de gasto:**
  - `styles.css`: cor do valor, aviso de repetido e botão do arrastar;
  - `nativo.js`: vibrar;
  - `sw.js`: cache;
  - `scripts/vetores-calc.mjs`: o que já tem vetor;
  - `tests/browser/fase3.cjs`, `tests/browser/cartao.cjs` e `tests/rules.test.mjs`;
  - o núcleo em `app-ios/`, só para saber o que já existe.
- **Conferido rodando o `calc.js` no Node:**
  - `parcelamentoCartao(0.05, 10, 0, …)` dá `null`;
  - `parseNum('3.125')` dá 3125;
  - `money` usa U+00A0 depois de "R$".
- **Lidos mas citados só quando tocam um fluxo da etapa:** as partes do `app.js` fora da etapa 2 (gráficos, relatório, simulador, ajustes, orçamento e afazeres).
- **Não li:** `auth.js`, `cadastro.js`, `push.js`, `share.js`, `splash*.js`, `globe.js`, `tema.js`, `pwa.js`, o resto do CSS e os mockups (estão fora do repositório).

---

### 1. Gasto: formulário (`formGasto`, app.js:878-1096)

**Como abre**
- O + só lança gasto na tela da obra. Em Início ele cria obra (app.js:190-194, 1893-1894).
- O + abre primeiro o teclado de valor, com `TECLADO.abrir({ valorInicial: 0, ... })`. Só no "Avançar" ele chama `formGasto(oid, null, v)` (app.js:1899-1900).
- Para editar, toca-se no miolo da linha, que chama `formGasto(o.id, g, undefined, voltar)` (app.js:774). Não há outro caminho de edição.
- `aoFechar`: quem abriu o formulário de dentro da folha "A pagar" ou da folha do tópico volta para ela no Salvar e no Cancelar (app.js:876-879, 1193, 1225-1231). Essas folhas são da etapa 3, mas o formulário é o mesmo.

**Campos, na ordem da folha (app.js:915-932)**
1. Título `<h3>`: "Novo gasto" ou "Editar gasto" (app.js:916).
2. Valor:
   - **No gasto novo:** um botão "Valor" com "R$ 0,00", pintado por `TECLADO.fmtCentavos`. O botão reabre o teclado com o valor atual. O número fica num `#fVal` escondido (app.js:911-913, 934-945).
   - **Na edição:** um campo de texto com máscara (`maskMoney`) e placeholder "0,00", preenchido com `numParaCampo(gasto.valor)`. O campo recebe foco ao abrir (app.js:908-910, 944, 1038).
3. "Obra": aparece sempre.
   - Com a obra fixa, é um campo desabilitado com o nome.
   - Sem obra fixa, é um `<select>` com as obras não vendidas, na ordem do array `db.obras` (app.js:880, 884-890).
   - Na edição, a obra é sempre a aberta (`obraById(obraAberta)`) e não muda (app.js:884).
4. "Tópico": chips de todos os tópicos.
   - Primeiro vêm os 21 fixos (calc.js:326-348), depois os próprios (`topicos()`, app.js:59).
   - Cada chip tem ícone, nome e `aria-pressed` (app.js:919-920, 979-993).
5. "Pagamento": chips "Pix" (ícone raio) e "Cartão" (ícone cartão), sem `aria-pressed` (app.js:896, 1015-1036).
   - O bloco do cartão fica escondido fora do cartão e sempre escondido na edição (app.js:897-903, 1032). Ele tem:
     - "Parcelas": `<select>` de "1x" a "36x", padrão 1x;
     - "Taxa de juros (% ao mês)": campo com valor inicial "0" e placeholder "Ex: 2,5";
     - a ajuda e o resumo ao vivo.
   - A ajuda diz (app.js:901): "0 = sem juros. Informe o valor da compra sem juros. Parcelas mensais fixas, com primeiro pagamento após um mês. A data abaixo é o primeiro vencimento."
   - Numa parcela (edição de gasto com `grupoId`), o bloco inteiro de pagamento dá lugar ao aviso, com ícone de cartão (app.js:893-895): "Parcela {n}/{de} de uma compra no cartão — a edição vale só pra esta parcela."
6. "Condições originais da compra": aparece só na edição de gasto com `jurosCartao`, seja parcela ou cartão 1x (app.js:922). O texto é "Condições originais da compra: {taxa}% ao mês · {N}x · juros {R$} · total {R$}. O valor editável já inclui juros; não serão aplicados novamente." A taxa sai com `String(taxa).replace('.', ',')`.
7. "Descrição (opcional)": `maxlength="500"`, placeholder "Ex: 50 sacos de cimento", combobox com a lista de sugestões (`role="listbox"`) (app.js:923-926).
8. "Data" (rótulo `#fDataLabel`): `<input type="date">` sem `min` e sem `max` (app.js:927).
9. Aviso de repetido, escondido, com `role="alert"` (app.js:928).
10. Botões "Cancelar" (ghost) e "Salvar" (primary) (app.js:929-932).

**Valor inicial de cada campo**
- **Valor:** o do teclado no gasto novo; o do gasto na edição (app.js:910, 913).
- **Tópico:** o gasto novo começa no primeiro da lista, `topicos()[0].id`, que é `terreno`. Na edição, é o do gasto (app.js:947).
- **Pagamento:** o gasto novo começa em `pix`. Na edição, é `gasto.pagamento || 'pix'` (app.js:995).
- **Data:** o gasto novo começa em hoje, pela hora local (`dataLocalISO`). Na edição, é a do gasto (app.js:69, 927).
- **Parcelas e juros:** 1x e "0" (app.js:898, 900).

**Data no cartão**
- Ao abrir, o formulário guarda duas datas: `pix` é a do campo (hoje) e `cartao` é `addMesesClampado(hoje, 1)` (app.js:996).
- No gasto novo, trocar a forma de pagamento guarda a data da forma que sai e põe a da forma que entra. Cada forma guarda a sua (app.js:1022-1026). A data do cartão não acompanha mudanças na data do Pix.
- O rótulo vira "Primeiro vencimento" no cartão e volta a "Data" no Pix, só no gasto novo (app.js:1004). Na edição fica sempre "Data", porque `atualizarCartao` retorna cedo (app.js:1003).
- `addMesesClampado`: 31/01 + 1 mês dá 28 ou 29/02 (calc.js:242-250).

**Resumo ao vivo do cartão (`#cartaoResumo`, `role="status"`, `aria-live="polite"`)**
- Quando o cartão é válido (app.js:1007), o texto é:
  - "{N}x de {R$ da 1ª parcela}";
  - depois " (última: {R$ da última})", só quando a última difere da primeira;
  - depois " · Juros do cartão: {R$} · Total: {R$}".
- Exemplos:
  - "2x de R$ 576,19 · Juros do cartão: R$ 152,38 · Total: R$ 1.152,38";
  - "3x de R$ 33,33 (última: R$ 33,34) · Juros do cartão: R$ 0,00 · Total: R$ 100,00".
- Quando é inválido (app.js:1008): "Informe valor, parcelas, data válida e taxa entre 0 e 100% ao mês."
- O resumo recalcula ao trocar pagamento, juros, parcelas, data e valor (app.js:937, 1011-1013, 1033). Só existe no gasto novo (app.js:1003).
- `money` é `Intl` pt-BR BRL, com espaço não separável (U+00A0) depois de "R$" (calc.js:387-388).

**Parcelas e juros**
- **Parcelas:** de 1 a 36 no `<select>` (app.js:898). `parcelamentoCartao` recusa valores fora de 1..36 (calc.js:268).
- **Juros:**
  - O texto aparado precisa casar com `^(?:\d+(?:[.,]\d+)?|[.,]\d+)$`. A vírgula vira ponto; o que não casa vira `NaN` (app.js:997-1000).
  - `parcelamentoCartao` exige 0 ≤ taxa ≤ 100 (calc.js:269).
  - Campo vazio é inválido: tem de ser "0". "1.000" é lido como 1%.

### 2. Gasto: salvar (app.js:1040-1095)

**Validações, na ordem**
1. **Valor não finito ou ≤ 0:** não há mensagem. No gasto novo reabre o teclado; na edição foca o campo (app.js:1041-1042).
2. **Descrição aparada com mais de 500 unidades UTF-16:** toast de erro "Use até 500 caracteres." e foco no campo (app.js:25-29, 1043-1044; `LIMITES.descricao`, dados.js:6). Com o `maxlength="500"` do campo, na prática só aparece se o valor vier por código.
3. **Obra não encontrada:** retorna sem mensagem (app.js:1045-1046).
4. **Cartão inválido no gasto novo** (`parcelamentoCartao` devolve `null`):
   - toast "Confira valor, parcelas, data e taxa de juros" e foco nos juros (app.js:1049-1053);
   - o toast não tem tipo de erro e sai com ícone de confirmação.
5. **Repetido:** ver abaixo (app.js:1055-1065).
6. **Parcelado com lista de parcelas vazia:** toast "O valor precisa ter pelo menos um centavo por parcela" e foco nas parcelas (app.js:1079-1083).
   - **Esse toast nunca aparece.** `parcelamentoCartao` já devolve `null` quando `gerarParcelas` sai vazio (calc.js:276-277), e o passo 4 dispara antes.
   - Exemplo: R$ 0,05 em 10x dá `null`.
- **Data:** `data0` é a do campo; se o campo estiver vazio, é a do gasto (edição) ou hoje (gasto novo) (app.js:1047). No Pix não há outra validação de data. No cartão a data precisa ser ISO válida (`dataISOValida`, calc.js:270).

**Objeto gravado no gasto novo**
- **Pix** (app.js:1089): `{ id: uid(), valor, topico, descricao, data, pagamento: 'pix' }`. `descricao` vai como `''` quando vazia; a chave nunca falta.
- **Cartão 1x** (app.js:1054, 1074-1075, 1089):
  - É um gasto só, sem `grupoId` e sem `parcela`: `{ id, valor: totalCompra, topico, descricao, data: data0, pagamento: 'cartao', jurosCartao }`.
  - Com juros, 1x cobra um mês de juros. Por exemplo, R$ 1.000 a 10% dá R$ 1.100.
- **Cartão N > 1** (app.js:1076-1087):
  - `grupoId = uid()`;
  - N gastos no formato `{ id: uid(), valor: p.valor, topico, descricao, data: p.data, pagamento: 'cartao', grupoId, parcela: { n: i + 1, de: N }, jurosCartao }`;
  - as parcelas entram em ordem, no fim do array.
- **`jurosCartao`:** `{ taxaMensal, valorCompra, nParcelas, totalCompra, jurosCompra }` (app.js:1074-1075). É igual em todas as parcelas.
- **Cálculo dos valores:**
  - `parcelamentoCartao(valor, n, taxa, data0)` usa a tabela Price (`expm1`/`log1p`) e arredonda o total a centavo (calc.js:267-280).
  - `gerarParcelas(total, n, data0)` conta em centavos e põe o resto na última parcela.
  - As datas são `addMesesClampado(data0, i)`, contadas sempre a partir do dia original: 31/01, 28/02, 31/03 (calc.js:254-262).
  - As parcelas guardam o valor **com juros**.
- **Onde entra:** `push` no fim de `o.gastos` (app.js:1085, 1089).

**Edição (app.js:1066-1072)**
- Muda só o gasto editado: `valor`, `topico`, `descricao` e `data`. `pagamento` só muda fora de parcela (app.js:1071).
- `if(pagto !== 'cartao') delete g.jurosCartao` (app.js:1072): editar para Pix apaga `jurosCartao`.
- Editar de Pix para Cartão vira `pagamento: 'cartao'` sem `jurosCartao`, sem parcelas e sem mudar a data.
- Numa parcela, `grupoId`, `parcela` e as irmãs ficam como estão. `jurosCartao` fica, porque o pagamento continua `cartao`.
- Se o gasto sumiu no meio (apagado em outro aparelho), retorna sem mensagem e a folha fica aberta (app.js:1067).

**Depois de salvar**
- `salvarComAviso` (app.js:47-56) mostra o toast "Gasto lançado com sucesso" ou "Gasto atualizado" **só quando o servidor confirma** (app.js:1092-1093).
- A vibração leve vem junto com o toast: `OBRA_NATIVO.vibrar`, Haptics `LIGHT` (nativo.js:134).
- Se o servidor não respondeu em 600 ms, aparece o toast "Aguardando sincronização — mantenha o app aberto até confirmar" (app.js:51).
- Logo em seguida, sem esperar o servidor, roda `renderAll()` e a folha fecha (ou volta à folha de origem) (app.js:1094).
- A tela continua onde estava. Não rola até o gasto novo.

**Repetido (app.js:1055-1065)**
- **Quando vale:** só com descrição preenchida (`desc && ...`, app.js:1056).
- **Com quais gastos compara:** os **da obra de destino** (`o.gastos`), menos o próprio gasto na edição (app.js:1056).
- **Regra:** as três condições abaixo precisam valer juntas (app.js:1057-1058).
  - `normalizaDescricao(x.descricao) === normalizaDescricao(desc)`.
    - `normalizaDescricao` aplica `semAcento`: minúsculas, NFD e remoção das marcas U+0300–U+036F.
    - Depois aplica `trim()` e troca espaços seguidos (`\s+`) por um só (app.js:83; calc.js:225-227).
  - `Math.round(x.valor*100) === Math.round(valor*100)`.
  - `x.data === data0`.
- **O que fica de fora:** tópico e pagamento não entram na comparação.
- **No cartão:** `valor` já é o `totalCompra` e `data0` é o primeiro vencimento (app.js:1054). Por isso uma compra parcelada repetida não é pega, porque cada parcela guarda só uma fração do total. A compra em 1x é pega.
- **Primeiro toque no Salvar:**
  - guarda a "assinatura" `[obra, tópico, descrição normalizada, centavos, data, N parcelas, taxa]` (app.js:1055);
  - mostra "Este gasto parece já lançado: mesma descrição, valor e data. Confira ou toque novamente para salvar mesmo assim.";
  - troca o botão para "Salvar mesmo assim" (app.js:1059-1064).
- **Segundo toque com a mesma assinatura:** salva.
- **`limpaDuplicado`** esconde o aviso e volta o botão a "Salvar" (app.js:950-954).
  - Roda ao digitar a descrição, escolher sugestão e mudar data, obra, tópico, pagamento, juros ou parcelas (app.js:965, 971, 977-978, 986, 1011-1012, 1027).
  - Mudar o valor não limpa o aviso, mas muda a assinatura, e o Salvar pede de novo.

**Sugestões de descrição (`sugestoesDescricao`, app.js:96-118)**
- **Fonte:** as descrições de **todas as obras**, inclusive as vendidas (app.js:100). Na edição, ignora o próprio gasto (app.js:101).
- **Agrupamento:**
  - as descrições se agrupam pela chave normalizada, e descrição vazia fica de fora (app.js:102-103);
  - para cada chave, guarda quantas vezes aparece, se aparece na mesma obra e se aparece no mesmo tópico;
  - guarda também o texto da ocorrência mais recente por data; no empate, vale a última percorrida (app.js:104-109).
- **Sem texto digitado, não há sugestão** (app.js:97-98).
- **Filtro:** a chave contém o termo, **ou** valem as três condições abaixo (app.js:111-112):
  - o termo tem 4 ou mais caracteres;
  - a diferença de tamanho é ≤ 2;
  - a distância de edição (Levenshtein, `distanciaEdicao`, app.js:84-95) é ≤ 2.
- **Ordem** (app.js:113-116):
  - pontos decrescentes, somando mesmo tópico 100, mesma obra 40, começa com o termo 25 e min(vezes, 10);
  - no empate, a data mais recente;
  - depois o texto em ordem alfabética (`localeCompare(..., 'pt-BR')`).
- **Limite:** até 5 sugestões (app.js:117).
- **Rótulo:** "mesmo tópico" se o tópico atual aparece no grupo; senão "{N}× usado", inclusive "1× usado" (app.js:963).
- **Quando aparecem** (app.js:965, 971-978, 987):
  - ao digitar e ao focar a descrição com texto;
  - somem 150 ms depois de sair do campo;
  - somem ao trocar de tópico, sem recalcular;
  - recalculam ao trocar de obra.
- **Tocar numa sugestão:** preenche o texto, fecha a lista, limpa o aviso de repetido e devolve o foco ao campo (app.js:965).
- O próprio texto digitado também aparece como sugestão quando já existe uma descrição igual.

**Onde moram (para o PR 0b)**
- **As duas regras estão só no `app.js`:**
  - `normalizaDescricao` (app.js:83);
  - `distanciaEdicao` (app.js:84-95);
  - `sugestoesDescricao` (app.js:96-118), que lê o global `db.obras`;
  - o repetido, **dentro** do clique do Salvar, sem função própria (app.js:1055-1065). Ele usa `o.gastos`, `desc`, `valor`, `data0`, `isEdit` e `gasto.id`.
- **Do `calc.js`,** as duas usam só `semAcento` (calc.js:225-227).
- **Para levar ao `calc.js` sem mudar o comportamento:**
  - receber `obras` (ou `gastos`) como parâmetro em vez do `db` global;
  - manter o `localeCompare` e o `\s` do JavaScript (o vetor `js.trim` já existe, scripts/vetores-calc.mjs:519-521);
  - a assinatura do "Salvar mesmo assim" é estado de tela e pode ficar no `app.js`.
- **Teste que protege hoje:** só o de navegador `tests/browser/fase3.cjs:30-44`, que cobre a sugestão "Cimento" e o segundo toque. Não há teste de unidade nem vetor.

### 3. Gasto: apagar

**Botão × da linha (app.js:775-800)**
- O botão tem `aria-label` "Apagar gasto" (app.js:776).
- **Gasto sem `grupoId`** (app.js:779-786):
  - pergunta com `OBRA_CONFIRM.perguntar('Excluir este gasto?', { confirmar: 'Excluir' })`;
  - no sim, tira o gasto pelo id e roda `save()` e `renderAll()`;
  - a pergunta não mostra nome nem valor.
- **Gasto com `grupoId`:** abre uma folha (app.js:788-799) com:
  - título "Excluir parcela {n}/{de}";
  - nota "Esta parcela faz parte de uma compra em {de}x no cartão.";
  - "Excluir só esta parcela" (primary), que tira só essa parcela;
  - "Excluir a compra toda ({N} parcelas)" (ghost), que tira todos os gastos com o mesmo `grupoId`. **N conta as irmãs que ainda existem na obra** (`irmas.length`), não `parcela.de`. Com uma só, o texto fica no singular, "1 parcela" (app.js:788, 794);
  - "Cancelar".
- A folha da parcela não pergunta de novo depois do toque. Nenhum dos dois caminhos mostra toast: chamam `save()` direto, sem `salvarComAviso`.

**Diálogo (`OBRA_CONFIRM`, ui-confirm.js:169-193)**
- É um `<dialog>` modal com a mensagem posta por `textContent` (ui-confirm.js:169-187).
- Tem dois botões: "Cancelar" (ghost, primeiro) e o de confirmar (primary).
- O foco inicial fica no "Cancelar", porque a ação destrutiva nunca recebe o foco.
- Esc fecha como "não".
- Os rótulos padrão são "Confirmar" e "Cancelar" (ui-confirm.js:191). `avisar` tem só o botão "Entendi" (ui-confirm.js:192).

**Arrastar para apagar (gestos.js)**
- **Onde vale:** em todo `li` com filho direto `.li-del` (gestos.js:222-223). Isso inclui as linhas de gasto, os afazeres e os tópicos próprios de Ajustes.
- **Início:**
  - o eixo é decidido depois de 10 px; é horizontal se |dx| > 1,2·|dy| (gestos.js:23-27);
  - linha fechada não abre para a direita (gestos.js:256).
- **Distâncias:** a linha abre em −80 px (`LARGURA_APAGAR`); o arrasto máximo é 120 px, com elástico além disso (gestos.js:6-7, 140-145).
- **Decisão no soltar:**
  - o ponto final é projetado com o impulso, taxa 0,995;
  - a linha abre se −(dx + projeção) > 40 px (gestos.js:12-15, 30-32, 158-160).
- **Vibração:** uma vez, ao passar de −40 px com a linha fechada (gestos.js:147).
- **Botão do gesto:**
  - o rótulo é "Apagar"; o botão é `aria-hidden` e fica fora do Tab (gestos.js:131-137);
  - o × continua disponível para VoiceOver e teclado;
  - no CSS o botão tem 120 px de largura, com 40 px de folga à direita (styles.css:1099).
- **Não apaga no arrasto até o fim:** tocar em "Apagar" fecha a linha e clica no × dela, que segue o fluxo acima (gestos.js:312-320).
- **Fechar a linha:**
  - tocar na linha aberta fora do botão só fecha e engole o clique por 400 ms;
  - tocar em outra linha fecha a aberta;
  - rolar mais de 8 px também fecha (gestos.js:153-156, 221, 299-303, 308-311).

### 4. Teclado de valor (teclado.js)

- **Centavos:** o teclado guarda centavos como inteiro (teclado.js:17-27).
  - Dígito entra pela direita (`c*10 + d`).
  - "00" multiplica por 100.
  - Apagar tira o último dígito (`floor(c/10)`).
- **Teto:** `9999999999` centavos, ou seja, R$ 99.999.999,99. A tecla que passaria do teto é **ignorada**; o valor não é truncado (teclado.js:10-12, 21-26).
- **Teclas, nesta ordem:** 7 8 9 / 4 5 6 / 1 2 3 / 00 0 apagar (teclado.js:52).
- **Rótulos:** a tecla de apagar tem `aria-label` "Apagar"; o X do topo tem "Cancelar lançamento" (teclado.js:69, 75).
- **Título e visor:** o título é fixo, "Valor do gasto". O visor mostra "R$" e `fmtCentavos`: milhar com ponto (`toLocaleString('pt-BR')`), vírgula e 2 casas (teclado.js:29-34, 70-72).
- **Zero:** "Avançar" fica desabilitado com zero, e o confirmar ignora zero (teclado.js:61, 78, 96).
- **Teclado físico:** aceita dígitos, Backspace, Enter (confirma) e Esc (cancela). Não há "00" (teclado.js:109-120).
- **Passagem do valor:**
  - `abrir({ valorInicial, onConfirm })` converte reais em centavos com `reaisParaCentavos`, que faz `toFixed(4)` antes do `round` e aplica o teto;
  - o `onConfirm` devolve **reais** (teclado.js:41-45, 95-100, 128-135);
  - o formulário guarda `numParaCampo(v)` no `#fVal` escondido e lê com `parseNum` (app.js:913, 937, 1041).
- **Cancelar:** o `app.js` não passa `onCancel` (app.js:934-939, 1900).
  - O X aberto pelo + fecha sem abrir o formulário.
  - O X aberto pelo botão "Valor" volta ao formulário com o valor antigo.
- **Uso no site:** o teclado só serve ao valor do gasto novo. Venda, valor estimado e orçamento usam campo com máscara (app.js:813, 819, 1847-1848, 1855-1856).
- **Testes:** as funções puras do teclado são exportadas (teclado.js:47, 138), mas **não estão nos vetores**. O `scripts/vetores-calc.mjs:35-38` só carrega calc, dados, push e cadastro.

### 5. Obra: criar, editar e apagar

**Nova obra (`formNovaObra`, app.js:1841-1889)**
- **Antes de ver os dados da conta,** a folha não abre e aparece o toast de `avisaNaoCarregado` (app.js:1842, 1920-1924).
- **Entradas:** todas passam por `formNovaObra` (app.js:881, 1890, 1894, 1896; index.html:195):
  - o + em Início;
  - o botão "+ Nova obra" de Início;
  - o + numa obra quando nenhuma obra está aberta (não vendida);
  - `formGasto` sem obra aberta.
- **Título e campos, na ordem** (app.js:1844-1854):
  1. "Nome da obra": `maxlength="120"`, placeholder "Ex: Casa Alphaville".
  2. "Começou em": data, padrão hoje.
  3. "Valor estimado de venda (opcional)": R$, placeholder "0,00".
  4. "Orçamento total (opcional)": R$, placeholder "0,00".
  5. "Área construída em m²": placeholder "Ex: 320", `required`, com o erro "Informe área construída maior que zero." escondido.
  6. Botões "Cancelar" e "Criar obra".
  - O título da folha é "Nova obra".
- **Foco no nome:** só quando não há toque (`pointer:coarse`). No celular, de propósito, nada vem focado, para a Área (obrigatória) não sumir atrás do teclado (app.js:1857-1860).
- **Salvar, na ordem** (app.js:1866-1888):
  1. Nome aparado vazio: foca o campo, sem mensagem.
  2. Nome com mais de 120: toast de erro "Use até 120 caracteres.".
  3. Área com `!(area > 0)`: mostra o erro inline, põe `aria-invalid="true"` e foca o campo. O erro some ao digitar na área (app.js:1861-1864, 1872-1877).
  - Valor estimado e orçamento inválidos ou ≤ 0 são ignorados.
- **Objeto gravado** (app.js:1878-1886):
  - `{ id: uid(), nome, fase: 'construcao', dataInicio, valorEstimadoVenda, areaM2: area, gastos: [] }`;
  - `dataInicio` é a do campo, ou hoje se vazio;
  - `valorEstimadoVenda` é o estimado se > 0, senão `null`;
  - se o orçamento for > 0, acrescenta `orcamento: { modo: 'total', total }`;
  - a obra nova **não leva** `venda` nem `afazeres`. A leitura normalizada acrescenta `venda: null` e `afazeres: []` (dados.js:53-57).
- **Depois:** `push` no fim de `db.obras`, `save()`, a folha fecha e a obra nova abre (`openObra`) (app.js:1887). Não há toast.
- A data de início aceita data futura, porque o campo não tem `max` (app.js:1846).

**Editar obra (`formEditarObra`, app.js:838-873)**
- Abre pelo lápis do cabeçalho, que tem `aria-label` "Editar obra" (app.js:372, 504).
- **Título e campos** (app.js:840-846). O título é "Editar obra". Não há orçamento. Os campos são:
  - "Nome": `maxlength="120"`, sem placeholder;
  - "Começou em";
  - "Valor estimado de venda (opcional)", preenchido com `numParaCampo`;
  - "Área construída em m² (opcional)": placeholder "Ex: 320", preenchido com o valor cru `o.areaM2`.
- **Botões:** "Apagar obra" (ghost) e "Salvar" (primary). **Não há "Cancelar"**: a folha fecha pelo fundo, por Esc ou puxando (app.js:847-850, 1761-1762).
- **Salvar** (app.js:852-864):
  - nome vazio: foca o campo;
  - nome com mais de 120: "Use até 120 caracteres.";
  - `dataInicio` é a do campo, ou a antiga se vazio;
  - estimado e área ≤ 0 ou vazios viram `null`;
  - a folha fecha e a tela fica na obra;
  - a data de início não é conferida com os gastos nem com a venda.

**Apagar obra (app.js:865-872)**
- A pergunta é `Apagar “{nome}”?`. Se a obra tem gastos, acrescenta ` Os {N} lançamento(s) dela serão perdidos.`, com o "(s)" literal e N = `o.gastos.length`.
- Os botões são "Cancelar" e "Apagar obra".
- No sim, a obra sai de `db.obras`, `obraAberta` vira `null`, roda `save()`, a folha fecha e a tela volta para Início. Não há toast.

**Limite de 300 obras**
- **Onde está:** só em `firestore.rules:27-28` (`d.obras.size() <= 300`), testado em `tests/rules.test.mjs:123-128`.
  - Não existe no `app.js`, no `dados.js` nem no `calc.js`.
  - O spec da etapa 1 já registrava a falta de aviso (docs/specs/2026-10-06-app-nativo-design.md:209).
- **O que o site faz hoje ao criar a 301ª obra:**
  - a obra entra em `db`;
  - a gravação é recusada com `permission-denied`, que é terminal (cloud.js:239-248);
  - aparece o toast "Não salvou na nuvem. Confira sua conexão e conta; toque no aviso para tentar novamente." e a pílula "Não salvou" (app.js:1997-2002);
  - a tela mantém a obra, porque os snapshots são ignorados enquanto `localDirty` (app.js:1964);
  - **toda gravação seguinte falha** até apagar uma obra, porque o blob inteiro continua com 301.

### 6. Fases e venda

- **Nomes das fases** (app.js:9-13):
  - `construcao`: "Em construção" (ícone guindaste);
  - `pronta`: "Pronta · à venda" (ícone casa);
  - `vendida`: "Vendida" (ícone check).
- **Botões por fase,** logo depois dos indicadores (app.js:428-433, 510-513):
  - construção: "Marcar como pronta" (primary), que chama `mudarFase(id, 'pronta')`;
  - pronta: "Registrar venda" (primary), que abre `formVenda`, e "Voltar pra construção" (ghost), que chama `mudarFase(id, 'construcao')`;
  - vendida: "Desfazer venda" (ghost).
- **`mudarFase(id, f)`:** troca `fase` e roda `save()` e `renderAll()`, sem pergunta e sem toast (app.js:808).
- Só se vende a partir de "pronta". Da fase vendida só se sai desfazendo a venda.

**Registrar venda (`formVenda`, app.js:810-836)**
- **Título:** "Registrar venda — {nome}".
- **Campos:**
  - campo grande de R$: placeholder "0,00", com máscara e foco ao abrir;
  - "Data da venda": `min` é o início da obra, `max` é hoje e o padrão é hoje.
- **Botões:** "Cancelar" e "Confirmar venda".
- **Validação:**
  - `valor <= 0`: foca o campo, sem mensagem (app.js:824);
  - data fora de [início, hoje]: toast "Data da venda precisa ficar entre o início da obra e hoje", sem tipo de erro, e foco na data (app.js:826-830). A conferência usa `dataIgualOuDepois`, que também recusa data inválida ou vazia (calc.js:58-60).
- **Gravação:** grava `venda: { valor, data }` e `fase: 'vendida'` e roda `save()`. A folha fecha e a tela fica na obra (app.js:832-834). Não há toast.

**Desfazer venda (app.js:513)**
- A pergunta é "Desfazer a venda? A obra volta pra “Pronta”.", com os botões "Cancelar" e "Desfazer venda".
- No sim, roda `delete venda` (a chave sai, não vira `null`) e `fase = 'pronta'`.

**Obra vendida no `dados.js` (dados.js:53-55)**
- `venda` só vale se for objeto com data ISO válida e `valor` número ≥ 0 (zero passa). Senão vira `null`.
- `fase` fora de construcao, pronta e vendida, ou `vendida` sem venda válida, vira `construcao`, não `pronta`.
- Correção e meses param na data da venda (`fimCorrecao`, calc.js:70-72, 87-89).

### 7. Obra vendida e o +

- **O + na tela da obra** (app.js:1893-1901) faz uma de três coisas:
  - não há obra não vendida: abre `formNovaObra`;
  - a obra aberta não está vendida: abre o teclado e depois `formGasto` com a obra fixa;
  - a obra aberta está vendida: abre o teclado e depois `formGasto` sem obra fixa.
- **Obra vendida aberta:**
  - o `<select>` "Obra" lista só as não vendidas (`fase !== 'vendida'`, app.js:880, 888-890);
  - vem marcada a primeira do array `db.obras`, em geral a mais antiga, e não a mais recente;
  - depois de lançar, a tela continua na obra vendida, mas o gasto foi para outra obra (app.js:1094).
- **Em Início,** o + é "Nova obra". O `aria-label` muda entre "Nova obra" e "Lançar gasto" (app.js:190-194).
- **Gastos de obra vendida** continuam editáveis e apagáveis, porque a linha não olha a fase (app.js:758-803). "Definir orçamento" some na vendida (app.js:434).
- **Lista de obras:** as não vendidas vêm primeiro, depois `dataInicio` decrescente, com ordenação estável (app.js:253-254).

### 8. Estados, textos e avisos

**Início**
- O contador mostra "{N} obra" ou "{N} obras" e fica vazio quando não há obra (app.js:255).
- **Sem obras e com os dados já vistos:** "Nenhuma obra ainda.", quebra de linha, "Toque no + pra criar a primeira obra." (app.js:257-258).
- **Antes de ver os dados:** "Carregando suas obras…", com reticências U+2026 (app.js:259).

**Obra sem gastos**
- O indicador Total gasto mostra a etiqueta "sem gastos". A pagar mostra "nada em 30 dias" (app.js:410, 421).
- A lista mostra "Nenhum gasto lançado.", quebra de linha, "Toque no + pra lançar o primeiro." (app.js:750).
- "Ver gráficos" e "Relatório" somem (app.js:435).
- O donut diz "Sem gastos ainda", sem ponto; a evolução diz "Sem gastos ainda." (app.js:560, 609).

**`nao-carregado`**
- **As duas marcas:** há duas marcas com a mesma regra, `dadosCarregados` no `app.js` e `carregado` no `cloud.js` (app.js:1913-1917, 1966-1969; cloud.js:158-165, 660).
  - Vale como dado visto o snapshot do servidor, com ou sem documento.
  - Vale também o snapshot do cache com documento.
- **Gravação antes disso:** `saveDados` não põe nada na fila e dispara `cloud-erro` com `code: 'nao-carregado'` (cloud.js:688-694).
- **`avisaNaoCarregado`** mostra um toast de erro (app.js:1920-1924):
  - com `navigator.onLine === false`: "Conecte à internet para carregar suas obras antes de lançar.";
  - senão: "Carregando suas obras, tente em instantes."
- **Onde é chamado:** em `formNovaObra`, na taxa e nos tópicos de Ajustes, e em qualquer `save()` recusado (app.js:1601, 1622, 1637, 1842, 1996).
- **No gasto:**
  - o formulário fecha mesmo com a recusa, e o gasto fica só na memória até o próximo snapshot (app.js:1092-1094);
  - na prática o site não chega a esse caso: só há obra na tela depois que os dados foram vistos.

**Pílula de sincronização (app.js:2005-2039; index.html:162)**
- Tem `role="status"` e `aria-live="polite"` e fica invisível no estado `ocioso`.
- **Textos por estado** (app.js:2009-2022):
  - `salvando` e `repetindo`: "Salvando…", com spinner;
  - `offline`: "Sem conexão";
  - `erro`: "Não salvou";
  - `erro` de leitura: "Não sincronizou".
- **No erro** (app.js:2023-2028):
  - o título é "Não foi possível sincronizar. Toque para tentar de novo.";
  - o toque mostra o toast "Tentando de novo…" e chama `CLOUD.tentarDeNovo()`.
- **Sem rede,** lançar continua funcionando. A escrita vai para a fila persistente do SDK, e o toast de sucesso só vem quando o servidor confirmar (cloud.js:702-704; app.js:47-56).

**Erros de gravação e leitura (`cloud-erro`, app.js:1993-2003)**
- **`limite`:** blob acima de 900.000 bytes (`LIMITE_BLOB`, calc.js:10; cloud.js:220). Mensagem: "Não salvou: limite de dados atingido. Reduza os dados e tente novamente."
- **Terminal:** permissão, sessão ou forma recusada pelas rules (`erroEhTerminal`, calc.js:28-34). Mensagem: "Não salvou na nuvem. Confira sua conexão e conta; toque no aviso para tentar novamente." O toast aparece **a cada** erro terminal.
- **Transitório:** "Sem salvar na nuvem agora — vamos tentar de novo sozinhos."
  - O toast aparece no máximo uma vez a cada 30 s (`avisoRaro`, app.js:1986-1992).
  - A gravação tenta de novo depois de 1, 2, 4, 8, 16 e 30 s (calc.js:38-42).
- **Erro de leitura:** "Não consegui ler seus dados da nuvem agora ({code})." pelo `avisoRaro` (app.js:2033-2034).
- **Perto do limite (700.000 bytes ou mais):** uma vez, "Seus dados estão próximos do limite de armazenamento." (app.js:33-41; calc.js:12).
- **Erro de JavaScript:** "Algo deu errado aqui dentro. Se atrapalhar, feche e abra o app." (app.js:2054-2062).

**Toasts dos fluxos da etapa 2**

O toast dura 2,2 s. Tem ícone de alerta só com o tipo `erro`; os outros saem com ícone de confirmação (app.js:1751-1760).

| Mensagem | Tipo | Onde | O que o spec faz com ela |
| --- | --- | --- | --- |
| "Use até 120 caracteres." / "Use até 500 caracteres." | erro | app.js:27 (chamado em 855, 1044, 1869) | mensagem do site (spec:89) |
| "Confira valor, parcelas, data e taxa de juros" | sem tipo | app.js:1051 | mensagem do site (spec:89) |
| "O valor precisa ter pelo menos um centavo por parcela" | sem tipo | app.js:1080 | o site nunca mostra (seção 2) |
| "Gasto lançado com sucesso" / "Gasto atualizado" | sem tipo | app.js:1092 (via 54) | sai: "sem toast" (spec:42) |
| "Aguardando sincronização — mantenha o app aberto até confirmar" | sem tipo | app.js:51 | não citado |
| "Data da venda precisa ficar entre o início da obra e hoje" | sem tipo | app.js:827 | o calendário limita a data (spec:53) |
| "Conecte à internet para carregar suas obras antes de lançar." / "Carregando suas obras, tente em instantes." | erro | app.js:1922-1923 | vira alerta (spec:49) |
| "Não salvou na nuvem. Confira sua conexão e conta; toque no aviso para tentar novamente." | erro | app.js:2000 | alerta uma vez (spec:64) |
| "Sem salvar na nuvem agora — vamos tentar de novo sozinhos." | erro, no máximo 1 a cada 30 s | app.js:2001 | não citado |
| "Não salvou: limite de dados atingido. Reduza os dados e tente novamente." | erro | app.js:1998 | não citado |
| "Seus dados estão próximos do limite de armazenamento." | erro, uma vez | app.js:37 | não citado |
| "Tentando de novo…" | sem tipo | app.js:2027 | "tocar tenta de novo" (spec:64) |
| "Não consegui ler seus dados da nuvem agora ({code})." | erro, no máximo 1 a cada 30 s | app.js:2034 | "Não sincronizou" (spec:65) |

### 9. Tela da obra: indicadores e lista (`renderObra`, app.js:359-521)

**Ordem da tela:** cabeçalho, orçamento (se houver), indicadores, ações, afazeres, gráficos e lançamentos (app.js:481).

**Cabeçalho (app.js:369-376)**
- Mostra o ícone da fase, o nome e o lápis "Editar obra".
- Embaixo vêm a etiqueta da fase, " · " e "começou em dd/mm/aa · {N meses}".
- `fmtMeses` dá "começando" abaixo de 1 mês, senão "1 mês" ou "N meses" (calc.js:397-401).

**Indicadores (app.js:378-426)**
- **Total gasto** (app.js:408-413):
  - etiqueta "{N} lançamento" ou "{N} lançamentos", ou "sem gastos";
  - valor `money(bruto)`;
  - nota "bruto, sem correção".
- **Corrigido pelo banco** (app.js:414-418):
  - valor `money(corrigido)`;
  - nota "Correção até hoje: +{R$}", ou "Correção até a venda: +{R$}" quando há `venda`.
- **A pagar · 30 dias** (app.js:419-424): é um botão que abre a folha.
  - etiqueta "{N} vencimento" ou "{N} vencimentos", ou "nada em 30 dias";
  - valor `money(total)`;
  - nota "Ver parcelas e gastos futuros →";
  - conta os gastos com data depois de hoje e até hoje + 30 dias, pela hora local (calc.js:198-209).
- **Venda,** em três variantes (app.js:381-405):
  - **vendida, com `venda`:** rótulo "Venda", etiqueta "Vendida em dd/mm/aa", valor `money(venda.valor)` e nota "lucro {moneyShort(bruto)} · {+}{moneyShort(vsBanco)} vs banco". A cor segue o lucro bruto ≥ 0;
  - **com valor estimado:** rótulo "Venda estimada", etiqueta "estimativa" e valor `money(estimado)`. A nota é "{moneyShort(R$/m²)}/m² · {área com vírgula} m²" quando há área, senão "margem {moneyShort(estimado − corrigido)}";
  - **sem estimativa:** rótulo "Venda estimada", valor "—" e nota "cadastre no editar obra".
- Os números grandes encolhem até caber, com mínimo de 13 px (`fitNums`, app.js:122-132).

**Lista de gastos (app.js:466-479, 743-803)**
- O painel "Lançamentos" tem um contador: N, ou "filtrados/total" quando há filtro. Busca e filtro por mês são da etapa 3 (app.js:466-479, 748).
- **Ordem:** `(b.data + b.id).localeCompare(a.data + a.id)`, ou seja, data decrescente e id decrescente no empate (app.js:752).
- A lista é plana: **não agrupa por mês** e não mostra o total do mês.
- **Linha** (app.js:761-772):
  - ícone do tópico. Para um tópico desconhecido, mostra o id (ou "Outros") com o ícone etiqueta (app.js:761);
  - título: a descrição, ou o nome do tópico quando ela está vazia, mais " ({n}/{de})" na parcela (app.js:763, 769);
  - linha de baixo (app.js:764-770): ícone de cartão ou de raio, sem escrever "Pix" ou "Cartão", mais o nome do tópico; data dd/mm/aa; etiqueta "a vencer" quando `data > hoje`;
  - valor: "−" (U+2212) seguido de `money(valor)`, com a classe `neg`, vermelha (styles.css:195; app.js:772);
  - botão × "Apagar gasto".
- **Formato de data:** `dd/mm/aa` (app.js:70).

**Acessibilidade**
- **Linha de gasto** (app.js:773-774):
  - não tem rótulo próprio;
  - o miolo que abre a edição é um `div` com `onclick`, não um botão;
  - só o × é botão com rótulo, "Apagar gasto";
  - o botão "Apagar" do arrastar é `aria-hidden` (gestos.js:135).
- **Lista de obras:** cada obra também é `li` com `onclick`, e o chevron é `aria-hidden` (app.js:262-275).
- **Outros controles:** o "A pagar" é `<button>`, o lápis tem `aria-label` "Editar obra" e o voltar tem "Voltar para Obras" (app.js:212, 372, 419).

### 10. `dados.js` e `firestore.rules`

**`LIMITES` (dados.js:6)**
- Os valores são nome 120, descrição 500, tópico 80 e afazer 500.
- Valem só na edição, por `textoValido`, que mede `.length` em unidades UTF-16 (app.js:25-29).
- Nunca truncam o que já existe.

**Normalização ao ler (dados.js:41-68)**

O site grava o `db` que já foi normalizado na leitura, mais a mudança.

- **Gasto** (dados.js:42-48):
  - precisa de `id` (texto), `data` ISO válida e `valor` número (ou texto numérico) **≥ 0**; senão some;
  - `topico` vazio vira `outros`, `pagamento` vazio vira `pix` e `descricao` vira sempre texto;
  - `parcela` inválida faz sair `grupoId` e `parcela`. Para valer, n e de precisam ser inteiros, com n > 0 e de ≥ n;
  - com `parcela` válida, `grupoId` vira texto, ou `''` se faltava;
  - `jurosCartao` passa sem conferência.
- **Obra** (dados.js:52-60):
  - precisa de `id` e de `dataInicio` ISO válida;
  - `venda` fica se for válida, senão vira `null`;
  - `nome` vazio vira "Obra sem nome";
  - `fase` segue a regra da seção 6;
  - `valorEstimadoVenda` e `areaM2` ficam se forem ≥ 0, senão viram `null`;
  - `gastos` e `afazeres` são sempre listas;
  - `orcamento` é normalizado ou removido.
- **Config** (dados.js:62-67):
  - `taxaMensal` fora de (0, 20] vira 1;
  - tópico próprio sem `id` ou sem `nm` some;
  - `ic` vazio vira `etiqueta`.
- **Campos desconhecidos** são preservados em todos os níveis (`{...g}`, `{...o}`, `{...origem}`, `{...config}`).
- **Escrita:** `saveDados` clona o blob por JSON e grava `{ ...blob, _atualizado: serverTimestamp() }`. A leitura apaga `_atualizado` (cloud.js:221, 661, 695).

**`firestore.rules` (dados/{uid}, firestore.rules:18-37)**
- No topo só são aceitos `obras`, `config` e `_atualizado` (`hasOnly`, firestore.rules:26).
- `obras` é uma lista com **no máximo 300** itens (firestore.rules:27-28).
- `config` é um mapa só com `taxaMensal` e `topicosCustom` (firestore.rules:29-35):
  - `taxaMensal` é número em (0, 20];
  - `topicosCustom` é lista com até 50 itens.
- **Não há `hasOnly` nem limite dentro de obra ou gasto.**
  - As rules aceitam qualquer chave, qualquer tipo e qualquer tamanho de texto em obra e gasto; o teste usa obras só com `id` (tests/rules.test.mjs:125).
  - Nome ≤ 120 e descrição ≤ 500 são só do cliente.
  - Para a pergunta "quais chaves as rules aceitam no gasto e na obra": todas.
- O limite de 1 MB por documento não é verificável nas rules. A guarda é do cliente, em 900.000 bytes (firestore.rules:15-17; cloud.js:220).
- **Consequência:** chave nova dentro de obra ou gasto não quebra a gravação. Chave nova no topo ou em `config` quebra.

### 11. `calc.js` e o que mora no `app.js`

**Funções exportadas que a etapa 2 usa (lista em calc.js:408)**
- **Datas:** `dataLocalISO`, `dataISOValida`, `dataIgualOuDepois`, `diasEntre` e `addMesesClampado` (calc.js:44-66, 242-250).
- **Totais:** `totalBruto`, `totalCorrigido`, `corrigido`, `lucroVenda`, `mesesDeObra`, `aPagar` e `precoPorM2` (calc.js:67-89, 198-209, 219-221). `fimCorrecao` é interna e não é exportada.
- **Cartão:** `gerarParcelas` e `parcelamentoCartao` (calc.js:254-280).
- **Dinheiro digitado:** `fmtDigitado`, `fmtCompleto`, `numParaCampo` e `parseNum` (calc.js:284-313).
- **Texto:** `semAcento` (calc.js:225-227).
- **Exibição:** `money`, `moneyShort`, `moneyCurto`, `fmtMeses` e `canon` (calc.js:387-406).
- **Outras:** `TOPICOS` (calc.js:326-348), `tamanhoBlob`, `blobCabe`, `LIMITE_BLOB`, `AVISO_BLOB`, `erroEhTerminal` e `proximoBackoff`.
- Desde o inventário de 06/10, o `aPagar` calcula o limite pela hora local (calc.js:201).

**Vetores (`scripts/vetores-calc.mjs`)**
- **Já cobrem:** `addMesesClampado`, `aPagar`, `semAcento`, `gerarParcelas`, `parcelamentoCartao`, `numParaCampo`, `parseNum`, `money` e o `dados.normaliza` (scripts/vetores-calc.mjs:165, 244, 258, 272, 281, 302-310, 358).
- **Não cobrem:** sugestões, repetido, teclado e o `uid()` inteiro.

**Só no `app.js`**
- **`uid()`** é `Date.now().toString(36) + Math.random().toString(36).slice(2,6)` (app.js:57).
  - Dá os milissegundos em base 36 e, em geral, 4 caracteres aleatórios.
  - Serve para obra, gasto, `grupoId`, afazer e tópico próprio (`'c_' + uid()`).
  - Os vetores só conferem o prefixo (scripts/vetores-calc.mjs:433-435).
- **As duas regras de descrição:** `normalizaDescricao`, `distanciaEdicao`, `sugestoesDescricao` e o repetido (seção 2).
- **Outras:** `textoValido` (app.js:25-29), `fmtData` (app.js:70), `FASES` (app.js:9-13) e `topicos()` (app.js:59).
- **Núcleo nativo, visto só por grep:** `Limites` já existe e conta em UTF-16 (app-ios/CusttaNucleo/Sources/CusttaNucleo/Normalizacao.swift:6-8). Também há um `Parcelas.swift`.

### 12. Pontos surpreendentes

1. **O site nunca mostra "O valor precisa ter pelo menos um centavo por parcela"** (app.js:1079-1083; calc.js:276-277).
2. **Três avisos de erro saem como toast de sucesso,** com ícone de confirmação (app.js:827, 1051, 1080, 1753):
   - "Confira valor, parcelas, data e taxa de juros";
   - "O valor precisa ter…";
   - "Data da venda precisa ficar…".
3. **Repetido** (app.js:1054-1058):
   - descrição vazia nunca conta como repetido;
   - compra parcelada repetida não é detectada, porque o total da compra é comparado com o valor de cada parcela.
4. **Sugestões:** vêm de todas as obras, inclusive as vendidas, e o texto mostrado é a grafia mais recente (app.js:100, 108).
5. **Área com 3 casas decimais vira ×1000 ao editar a obra** (app.js:846, 861; calc.js:310-311):
   - o campo de edição mostra o número cru, por exemplo "3.125";
   - `parseNum` lê esse ponto como separador de milhar e grava 3125;
   - a nova obra aceita "3,125" sem problema.
6. **Parcela apagada pela folha pode se perder** (app.js:778, 782, 798-799):
   - a folha usa a obra capturada no toque do × (`oo`);
   - se um snapshot trocar o `db` com a folha aberta, a exclusão se perde;
   - o gasto simples busca a obra de novo e não tem esse problema.
7. **"A compra toda (N)" conta as irmãs que restam,** não `parcela.de` (app.js:788, 794).
8. **A data do gasto não tem limite:** pode ser antes do início da obra, depois da venda ou futura (app.js:927).
9. **Editar de Pix para Cartão** não cria `jurosCartao` nem parcelas (app.js:1032, 1071-1072).
10. **Cartão 1x com juros** cobra um mês de juros (calc.js:273-274).
11. **O + numa obra vendida** pré-seleciona a primeira obra do array, e a tela fica na obra vendida depois de salvar (app.js:880, 889, 1094).
12. **A 301ª obra trava toda gravação seguinte** até apagar uma obra (seção 5).
13. **Obra criada pelo site não tem `venda` nem `afazeres`.** E desfazer a venda apaga a chave `venda` em vez de pôr `null` (app.js:513, 1878-1884).
14. **As rules não protegem nada dentro de obra e gasto** (seção 10).
15. **O arrastar vale também para afazeres e tópicos de Ajustes,** porque procura qualquer `li` com `.li-del` (gestos.js:222).
16. **`dados.js` aceita `valor: 0` em gasto e venda,** porque `positivo` é ≥ 0. Uma venda de R$ 0 mantém a obra vendida (dados.js:10, 42, 53).
17. **Parcela sem `grupoId`** (dados.js:46; app.js:763, 779, 893):
   - com `parcela` válida e sem `grupoId`, a normalização grava `grupoId: ''`;
   - a linha mostra "(n/de)", mas a edição e o apagar tratam como gasto simples.
18. **"Editar obra" não tem "Cancelar",** enquanto "Nova obra", "Registrar venda" e o gasto têm (app.js:847-850).
19. **Nenhuma folha pergunta antes de descartar:** Cancelar, toque no fundo, Esc e puxar a folha fecham direto (app.js:1039, 1761-1762; gestos.js:170-179).
20. **Cache offline:** o `sw.js` está em `obras-v67`, e o comentário pede bump ao mudar arquivos (sw.js:2-3). Os PRs 0a e 0b mexem em `app.js` e `calc.js`.

### 13. Divergências com o spec

**Afirmações do spec que o código não confirma**

| Spec | Código |
| --- | --- |
| spec:89, entre as mensagens do site: "O valor precisa ter pelo menos um centavo por parcela" | O site nunca mostra essa mensagem. `parcelamentoCartao` devolve `null` quando a parcela teria menos de um centavo (calc.js:276-277), e o Salvar mostra antes "Confira valor, parcelas, data e taxa de juros" (app.js:1049-1053). O toast de app.js:1080 é código morto. |
| spec:49: "alerta com o texto do site, "Carregando suas obras" (…); o gasto continua na folha." | O texto completo é "Carregando suas obras, tente em instantes." (app.js:1923). O site fecha a folha mesmo com a recusa (app.js:1094), então "continua na folha" é comportamento novo do app. |
| spec:90: "Repetido: mesma descrição, valor e data de um gasto que já existe na obra." | Faltam condições (app.js:1054-1065). Só vale com descrição preenchida. A descrição é comparada normalizada (sem acento, em minúsculas e com espaços colapsados) e o valor em centavos. Na edição, o próprio gasto fica de fora. No cartão, compara o total da compra com o primeiro vencimento, então compra parcelada repetida não é pega. O segundo toque com a mesma assinatura salva. |
| spec:91: "Sugestões de descrição: as do site (até cinco, priorizando o mesmo tópico)." | A prioridade tem quatro pesos: mesmo tópico 100, mesma obra 40, prefixo 25 e usos até 10. O desempate é por data e depois por ordem alfabética. Há busca aproximada (Levenshtein ≤ 2), a fonte são todas as obras e não há sugestão sem texto digitado (app.js:96-118). |
| spec:37: "na ordem do site: valor, tópico, pagamento, descrição e data" | O site tem "Obra" entre valor e tópico, sempre visível e desabilitada quando fixa. Na edição com juros, "Condições originais da compra" vem antes da descrição (app.js:917-922). |
| spec:141, PR 0a: "o + da lista avisa antes de abrir "Nova obra"" | Há quatro entradas para `formNovaObra`: o + de Início, o "+ Nova obra", o + numa obra quando nenhuma está aberta e `formGasto` sem obra aberta (app.js:881, 1890, 1894, 1896). Com o aviso só no +, as outras três passam. O lugar que cobre todas é o começo de `formNovaObra`, junto da guarda que já existe (app.js:1841-1842). |
| spec:58: "O alerta de apagar mostra o nome e o número de lançamentos." | Mostra, mas o número só aparece quando há gastos, e o plural é "lançamento(s)" literal (app.js:867). |

**Diferenças deliberadas do desenho (o app muda o que o site faz; não copiar o site aqui)**

| Spec | Site hoje |
| --- | --- |
| spec:36: teclas "na ordem do telefone" | 7 8 9 em cima, ordem de calculadora (teclado.js:52) |
| spec:38 e 118-120: tópico inicial é o do último gasto da obra | o primeiro tópico, `terreno` (app.js:947) |
| spec:39: "Juros ao mês" | "Taxa de juros (% ao mês)" (app.js:899) |
| spec:42: sem toast; a lista rola até o gasto, com a etiqueta "novo" | toast depois da confirmação do servidor, com vibração; a lista não rola (app.js:1092-1094) |
| spec:43: editar pelo teclado ("Pronto") e "Apagar gasto" no fim da folha | edição por campo com máscara; não há apagar na folha (app.js:908-910, 916-932) |
| spec:44: alerta com nome e valor; "Apagar" em tudo | "Excluir este gasto?" com o botão "Excluir"; a folha da parcela usa "Excluir…" (app.js:781, 790-795); "Apagar" só no rótulo do × e no arrastar (app.js:776; gestos.js:134) |
| spec:47: "Salvar mesmo assim" em âmbar | aviso em vermelho (`.dup-warning`, styles.css:357); o botão continua primary |
| spec:48: descartar pergunta antes | o site nunca pergunta (app.js:1039, 1761-1762; gestos.js:170-179) |
| spec:53: venda em dois passos (teclado, depois calendário) | uma folha com campo R$ e data com `min`/`max` (app.js:811-818) |
| spec:55: cursor no nome e teclado aberto | o site evita isso de propósito no toque, para a Área obrigatória não ficar escondida (app.js:1857-1860). Conferir no 13 mini. |
| spec:28-29: lista por mês, com total, e "A vencer" agrupado | lista plana por data e id, com a etiqueta "a vencer" em cada linha (app.js:752, 770) |
| spec:30: valor sem vermelho, "Pix"/"Cartão" por extenso, sem repetir o tópico | valor vermelho (`neg`), pagamento só com ícone, título que cai no tópico e linha de baixo que repete o tópico (app.js:765-772; styles.css:195) |
| spec:31: "Toque no lápis para informar o valor" | "cadastre no editar obra" (app.js:403) |
| spec:64: alerta uma vez quando o erro não passa sozinho | toast a cada erro terminal (app.js:2002) |
| spec:132: teclado reutilizável (gasto, venda, valor estimado, orçamento) | teclado só no gasto novo, com título fixo "Valor do gasto" (teclado.js:70; app.js:813, 1847-1848) |

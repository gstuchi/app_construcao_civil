# Inventário do site para o app nativo

Data: 2026-10-06. Levantamento do que o PWA faz hoje, tirado do código na `main` (`4d9a042`), para os planos de implementação do app nativo ([spec](../specs/2026-10-06-app-nativo-design.md)). Caminhos e números de linha são dessa revisão e relativos à raiz do repositório.

É um levantamento feito por leitura, com as lacunas declaradas em "Cobertura". Antes de portar um trecho, confira no código: o código manda, este documento só aponta onde olhar.

**Cobertura.** Li inteiros `calc.js`, `dados.js` e `firestore.rules`. Do `app.js` li a maior parte: navegação, Início, Obra, lançamentos, venda, editar obra, gasto, nova obra, orçamento, sincronização e boot. Algumas partes vi só por grep: interação de toque dos gráficos (`evoSel`/`mesSel`), corpo do Relatório/Simulador, Ajustes e sheets. Em `cloud.js`, `auth.js`, `cadastro.js`, `ui-confirm.js`, `push.js`, `share.js`, `teclado.js` e `gestos.js` li os trechos-chave. **Não li** `splash.js`, `globe.js`, `tema.js` nem os specs em `docs/specs/`.

---

### 1. Telas e navegação

**Estrutura geral**
- Três abas: `inicio` (título "Obras"), `simula` ("Vale a pena?") e `ajustes` ("Ajustes").
- Telas empilhadas acima de Obras: `obra`, `relatorio` e `graficos`. A aba Obras continua acesa dentro delas.
- `PILHA_OBRAS = ['inicio','obra','relatorio','graficos']` (app.js:184). A transição é `push`/`pop` dentro da pilha e `aba` entre abas (app.js:186-189).
- Título grande que vira título pequeno na barra quando sai da vista (IntersectionObserver, app.js:238-251).
- Botão "‹ Obras" (quando está na obra) ou "‹ Obra" (no relatório e nos gráficos), app.js:226-230. Voltar do relatório/gráficos reabre a obra (app.js:1117-1118).

**Botão + (FAB)**
- Em Início, cria obra.
- Na Obra, lança gasto: abre primeiro o teclado de valor e depois o formulário.
- Se não houver obra não vendida, abre "Nova obra" (app.js:208-213, 1903-1911).

**Restauração de estado**
- Grava `{tab, obraAberta}` em localStorage `custta-estado` e restaura após o 1º snapshot (app.js:156-180).
- Uma notificação tocada vence a restauração (app.js:1928-1937).
- Sem estado salvo: abre Início.

**Início (`v-inicio`)**
- Contador "N obra(s)" (app.js:273).
- Lista de obras ordenada: não vendidas primeiro, depois `dataInicio` decrescente (app.js:271-272).
- Cada linha mostra: ícone da fase; nome; tag da fase; "· N meses" (ou "começando" se < 1 mês, app.js:141-145); `moneyShort(totalBruto)`; chevron.
- Se a obra tem orçamento, a linha também mostra uma mini-barra com "X% do orçamento" ou "X% · passou R$ Y" (app.js:281).
- Vazio: "Nenhuma obra ainda. Toque no + pra criar a primeira obra."
- Botão "+ Nova obra".
- Painel "Comparativo entre obras": só aparece com 2 ou mais obras com gasto > 0. Barras horizontais "bruto gasto · corrigido", escala pelo maior corrigido (app.js:299-323).

**Obra (`v-obra`), em ordem (app.js:375-538)**
1. Cabeçalho: ícone, nome, botão lápis (editar), tag da fase, "começou em dd/mm/aa · N meses".
2. Card de Orçamento, se existir (app.js:340-374):
   - Rótulo e pílula: "dentro do previsto", "perto do limite" ou "passou do previsto".
   - "R$ gasto de R$ previsto", barra, "X% usado", "sobra/passou R$".
   - No modo por tópico, vem a seção "Por tópico", ordenada pela razão gasto/previsto decrescente. Cada linha: "R$ gasto / previsto", barra fina e frase ("Passou R$ X do previsto", "Faltam R$ X — N%" ou "Chegou ao previsto — N%"). Tópico com gasto abre o sheet do tópico.
   - Item final "Fora do orçamento" com a soma e os nomes dos tópicos.
   - Botão "Editar orçamento".
3. KPIs:
   - **Total gasto**: chip "N lançamento(s)" ou "sem gastos"; "bruto, sem correção".
   - **Corrigido pelo banco**: "Correção até hoje/a venda: +R$".
   - **A pagar · 30 dias** (botão): chip "N vencimento(s)" ou "nada em 30 dias"; "Ver parcelas e gastos futuros →".
   - **Venda**: se vendida, "Vendida em dd/mm/aa", valor e "lucro X · ±Y vs banco". Se há estimativa, "Venda estimada" com R$/m² e área, ou "margem estimado−corrigido". Sem estimativa: "—" e "cadastre no editar obra".
4. Ações por fase:
   - construção: "Marcar como pronta";
   - pronta: "Registrar venda" e "Voltar pra construção";
   - vendida: "Desfazer venda" (com confirmação).
   - "Definir orçamento" aparece se não houver orçamento e a obra não estiver vendida.
   - "Ver gráficos" e "Relatório" aparecem só com gastos.
5. Afazeres: campo com maxlength 500, placeholder "Ex: pagar pedreiro, buscar tinta", botão +, contador "(N pendente(s))". Pendentes primeiro, feitos depois. Vazio: "Nenhum afazer. Anote o que falta na obra." (app.js:539-572).
6. "Gastos por tópico": donut com o total no centro e legenda. Tocar abre Gráficos.
7. "Evolução da obra": linha bruto × corrigido, por mês, últimos 24. Vazio: "Sem gastos ainda." (app.js:621).
8. Barras de gasto por mês (`serieMensal`) (app.js:691).
9. Lançamentos:
   - Busca por texto (descrição ou nome do tópico, sem acento) e select de mês ("Todos os meses", formato "jan/26").
   - Contador "filtrados/total".
   - Ordenação: data + id decrescente.
   - Vazios: "Nenhum gasto lançado. Toque no + pra lançar o primeiro." e "Nada encontrado com esse filtro." (app.js:759-772).
   - Linha do gasto (app.js:774-822): ícone do tópico; descrição (ou nome do tópico) + " (n/de)"; ícone Pix/cartão + tópico; data; tag "a vencer" se a data é futura; "−R$ valor"; botão ×.

**Gráficos (`v-graficos`, app.js:1176)**
- Título "Gráficos — nome".
- Donut grande (240) com legenda: nome, % e valor.
- Evolução e barras mensais com H=300.
- Botão "Imprimir / salvar PDF".

**Relatório (`v-relatorio`, app.js:1251-1340)**
- Tabela com colunas Tópico / gasto · Data · Bruto · Corrigido · Correção pelo banco.
- Agrupada por tópico, com subtotal por grupo e linha TOTAL.
- Linhas finais:
  - vendida: "Venda em dd/mm/aa", "Lucro bruto (venda − gasto)", "Acima do banco (venda − corrigido)";
  - não vendida: "Venda estimada" e "Margem estimada (estimado − corrigido)".
- Checkbox por gasto. O painel "Selecionados" soma bruto e corrigido dos marcados.
- Botão "Imprimir / salvar PDF". O CSV da obra usa `dadosDaObra` (app.js:1170).

**Simulador (`v-simula`, app.js:1341-1413)**
- Campos:
  - "Obra": só obras não vendidas com gastos.
  - "Se eu vender por": R$, pré-preenchido com `valorEstimadoVenda` enquanto o usuário não mexeu (`dataset.touched`).
  - "Daqui a (meses)": de 0 a 120.
- Nota: "A conta considera que não haverá mais gastos até a venda."
- Venda ≤ 0: "Digite o preço de venda pra ver a conta."
- Card de resultado:
  - "Vale a pena" ou "Rende menos que o banco", conforme venda > corrigido na data-alvo;
  - TIR "x,xx% ao mês";
  - "vendendo hoje / daqui a N meses · banco paga T% · rende N,N× o banco".
- Tabela "Relatório da simulação", com colunas Pelo bruto | Pelo corrigido. Linhas: Venda, Custo até a venda, Lucro, % sobre o custo, % sobre a venda, Rendimento ao mês, R$/m².
- A TIR não é calculada se `mesesDeObra(o, alvo) < 1` ("novaDemais").

**Sheets e diálogos**
- Sheet "A pagar · próximos 30 dias" (app.js:1199): "N vencimentos · a partir de amanhã". Vazio: "Nenhum gasto previsto para esse período."
- Sheet do tópico (app.js:1213-1250):
  - "N gastos · X% da obra", com bruto e corrigido.
  - Lista de gastos do tópico. Editar ou excluir volta ao sheet, que fecha sozinho se o último gasto sumir.
- Diálogos de confirmação `OBRA_CONFIRM.perguntar/avisar` (ui-confirm.js:169-192).

---

### 2. Ações e formulários

**Nova obra (app.js:1853-1899)**
- Nome: obrigatório, até 120, placeholder "Ex: Casa Alphaville".
- Começou em: date, padrão hoje.
- Valor estimado de venda: opcional, R$.
- Orçamento total: opcional. Se > 0, grava `{modo:'total', total}`.
- Área construída em m²: **obrigatória** e > 0. Erro inline: "Informe área construída maior que zero."
- Ao salvar, abre a obra criada.

**Editar obra (app.js:854-892)**
- Campos: nome (obrigatório, ≤120), data de início, estimado e área. Estes dois são opcionais: ≤0 vira `null`.
- **A data de início não é validada contra os gastos.**
- "Apagar obra" pede confirmação: "Apagar “X”? Os N lançamento(s) dela serão perdidos."

**Registrar venda (app.js:826-852)**
- Valor > 0.
- Data entre `dataInicio` e hoje. Erro: toast "Data da venda precisa ficar entre o início da obra e hoje".
- Grava `venda` e `fase='vendida'`.
- "Desfazer venda" apaga `venda` e põe `fase='pronta'`.
- "Marcar como pronta" e "Voltar pra construção" só trocam a fase.

**Gasto: novo e editar (app.js:894-1116)**
- **Valor**
  - No novo, vem do teclado próprio e vira um botão "Valor R$ 0,00" que reabre o teclado.
  - No editar, é um campo com máscara.
  - Valor ≤ 0: reabre o teclado (novo) ou foca o campo (editar).
- **Obra**: select com as obras não vendidas, ou fixa se aberta da obra. No editar é sempre a obra aberta.
- **Tópico**: chips com padrões + custom. Padrão no novo: o 1º (`terreno`).
- **Pagamento**: chips Pix (`pix`) e Cartão (`cartao`). Padrão `pix`.
  - Ao trocar para cartão no novo, a data vira data + 1 mês (clamp) e o rótulo vira "Primeiro vencimento". Cada forma lembra a sua data.
- **Parcelas** (só cartão e só no novo): de 1x a 36x.
- **Taxa de juros (% ao mês)**:
  - padrão "0", regex `^\d+([.,]\d+)?$`, de 0 a 100.
  - Ajuda: "0 = sem juros…".
  - Resumo ao vivo: "Nx de R$ (última: R$) · Juros do cartão: R$ · Total: R$".
  - Inválido: "Informe valor, parcelas, data válida e taxa entre 0 e 100% ao mês." No salvar: toast "Confira valor, parcelas, data e taxa de juros".
- **Descrição**: opcional, ≤500, placeholder "Ex: 50 sacos de cimento". Combobox de sugestões (app.js:104-126):
  - até 5, vindas de todas as obras, sem acento;
  - casa por "contém" ou por Levenshtein ≤ 2 (termo com 4+ letras);
  - score: mesmo tópico +100, mesma obra +40, prefixo +25, mais min(vezes, 10);
  - rótulo "mesmo tópico" ou "N× usado".
- **Data**: padrão hoje.
- **Duplicado**: mesma obra, mesma descrição normalizada, mesmos centavos e mesma data. Mostra "Este gasto parece já lançado: mesma descrição, valor e data. Confira ou toque novamente para salvar mesmo assim." e o botão vira "Salvar mesmo assim". Mudar qualquer campo zera o aviso.
- **Gravação**
  - Cartão com N > 1: cria N gastos com o mesmo `grupoId`, `parcela {n, de}`, `pagamento 'cartao'` e `jurosCartao`. Os valores vêm de `gerarParcelas(totalCompra)`, já com juros.
  - Cartão 1x: um gasto com `valor = totalCompra` e `jurosCartao`.
  - Erro: "O valor precisa ter pelo menos um centavo por parcela".
- **Editar parcela**: pagamento e parcelas ficam travados. Mostra "Parcela n/de de uma compra no cartão — a edição vale só pra esta parcela." e "Condições originais da compra: …". No editar com pix, `jurosCartao` é removido.
- **Toast**: "Gasto lançado com sucesso" ou "Gasto atualizado", só depois que o servidor confirma, com vibração leve. Se o servidor não responder em 600 ms: "Aguardando sincronização — mantenha o app aberto até confirmar" (app.js:47-56).
- **Excluir**
  - Gasto simples: confirma "Excluir este gasto?".
  - Parcela: sheet com "Excluir só esta parcela", "Excluir a compra toda (N parcelas)" e "Cancelar".

**Orçamento (app.js:1778-1850)**
- Segmento "Só o total" ou "Por tópico".
  - Total: campo R$.
  - Por tópico: um campo por tópico (placeholder "sem valor") e a soma ao vivo.
- Trocar para total com o campo vazio preenche a soma dos tópicos.
- Valores vazios ou ≤ 0 resultam em orçamento removido.
- "Tirar orçamento" pede confirmação: "Tirar o orçamento desta obra? Os gastos continuam como estão."

**Afazeres**
- Adicionar com Enter ou +. Entra no topo (`unshift`). Texto ≤ 500.
- Tocar no texto ou no check alterna `feito`. O × apaga sem confirmar.

**Limites de texto**: toast "Use até N caracteres." Valores: nome 120, descrição 500, tópico 80, afazer 500 (dados.js:6). Os limites valem só na edição e nunca truncam o que já existe.

---

### 3. Modelo de dados

**Documento `dados/{uid}`** = `{obras:[...], config:{taxaMensal, topicosCustom:[...]}, _atualizado: serverTimestamp}`
- O blob vazio é `{obras:[], config:{taxaMensal:1, topicosCustom:[]}}` (app.js:15).
- As rules só aceitam as chaves `obras`, `config`, `_atualizado`. Limites: obras ≤ 300; config só com `taxaMensal` (número em (0, 20]) e `topicosCustom` (≤ 50) (firestore.rules:23-35).
- `_atualizado` é removido ao ler (cloud.js:652).

**IDs**: `Date.now().toString(36) + 4 caracteres aleatórios base36` (app.js:57).

**Obra**
- Campos: `{id, nome, dataInicio:'YYYY-MM-DD', fase:'construcao'|'pronta'|'vendida', venda:{valor, data}|null, valorEstimadoVenda:number|null, areaM2:number|null, gastos:[], afazeres:[], orcamento?}` (app.js:1884-1897; dados.js:51-61).
- Fases: construcao "Em construção", pronta "Pronta · à venda", vendida "Vendida" (app.js:9-13).

**Gasto**
- `{id, valor, topico, descricao, data, pagamento:'pix'|'cartao'}`.
- Opcionais: `grupoId`, `parcela:{n, de}` e `jurosCartao:{taxaMensal, valorCompra, nParcelas, totalCompra, jurosCompra}` (app.js:1092-1106).

**Afazer**: `{id, texto, feito:boolean}`.

**Orçamento**: `{modo:'total', total}` ou `{modo:'topicos', topicos:{[topicoId]: valor}}`. No máximo 100 tópicos e id com até 80 caracteres (dados.js:17-40).

**Tópico custom**: `{id:'c_'+uid, nm, ic:'etiqueta'}` (app.js:1652).

**Tópicos padrão** (calc.js:324-346), id = nome:
- terreno = Terreno; projeto = Documentação; matbasicos = Materiais básicos; fundacao = Fundação; ferragem = Ferragem; estrutura = Estrutura; alvenaria = Alvenaria;
- telhado = Telhado; eletrica = Elétrica; hidraulica = Encanamento; esquadrias = Esq. de alumínio; revest = Cerâmica; pintura = Pintura; acabamento = Acabamento;
- piscina = Piscina; paisagismo = Jardim; maoobra = Mão de obra; aluguelmaq = Aluguel de máquina; matextra = Materiais extra; extras = Extras; outros = Outros.

**Formas de pagamento**: só `pix` e `cartao`.

**`perfis/{uid}`**
- Campos: `{email, criado: ISO, tz: fuso IANA, nome?, sobrenome?, origem?, origemDetalhe?}` (cloud.js:406-407 e 440).
- Rules (firestore.rules:59-75):
  - email = e-mail do token, até 320; criado até 40; tz até 64; nome de 1 a 60; sobrenome até 80; origemDetalhe até 80;
  - `origem` ∈ instagram | indicacao | google | tiktok | youtube | outro.
- `plano` e `avisosOrcamento` só o Admin SDK grava. `cpf` é rejeitado.

**`push/{uid}`**: `{subs:{[chave]: …}, tokens:{[chave]: …}}`, no máximo 10 de cada (firestore.rules:86-93).
- **Token FCM do iOS**: `tokens.{chave} = {token, plataforma:'ios', criado: ISO}`, gravado com `setDoc(..., {merge:true})` (push.js:84-86; cloud.js:702).
- A chave é `hashEndpoint(token)`: djb2 (h=5381; `h*33 + charCode`, `>>>0`) em base36 (push.js:13-17).
- A chave também fica no localStorage `custta-push-token` (push.js:72, 91).
- Web Push: `subs.{hash(endpoint)} = {endpoint, keys, criado}`.

---

### 4. Funções de calc.js (exportadas em calc.js:382)

**Constantes**
- `DIAS_MES = 30.44`.
- `LIMITE_BLOB = 900000` bytes UTF-8 do JSON.

**Fila de escrita**
- `tamanhoBlob` e `blobCabe`: tamanho em bytes do JSON e se cabe no limite.
- `erroEhTerminal`: códigos permission-denied, unauthenticated, invalid-argument, not-found, failed-precondition, unimplemented, out-of-range. Normaliza `_`→`-` e o prefixo `x/`. Erro sem código é tratado como transitório.
- `proximoBackoff(n)`: 1 s, 2, 4, 8, 16 e trava em 30 s.

**Datas**
- `dataLocalISO`: data local, não UTC.
- `dataISOValida`: rejeita datas como 30/02.
- `dataIgualOuDepois`.
- `diasEntre`: em hora local `T00:00:00`, `Math.round`, nunca negativo.

**Correção e lucro**
- `corrigido = valor × (1 + taxa/100)^(dias/30.44)`: composto e diário.
- `fimCorrecao`: data da venda, ou hoje.
- `totalBruto` e `totalCorrigido`.
- `lucroVenda → {bruto, vsBanco}`: o corrigido vai até a data da venda.
- `mesesDeObra`: de `dataInicio` até o fim, dividido por 30.44.

**TIR e simulador**
- `tirMensal(gastos, venda, alvoISO)`: bisseção de 100 iterações no intervalo r ∈ [−99%, +1000%]. Retorna `null` se não houver venda ou gastos, se nenhum mês tiver passado, ou se a raiz estiver fora do intervalo. Gasto depois da venda conta como pago nela.
- `rendimentoAcima`: `(1 + tir)/(1 + taxa) − 1`, composto.
- `resumoVenda(venda, custo) → {lucro, pctCusto, pctVenda}`: `null`s se algum valor ≤ 0.

**Séries para gráficos**
- `serieEvolucao`: um ponto por mês-calendário, do 1º gasto até o fim. Corte no último dia do mês ou no fim. Devolve `{mes, bruto, corrigido}`, últimos 24.
- `serieMensal`: bruto por mês, com meses vazios em zero, últimos 24.
- `serieEvolucaoAgregada`: soma das obras por mês; obra vendida fica congelada.

**Outras**
- `aPagar(obras, hoje, 30)`: gastos com `data > hoje` e ≤ hoje + 30. **O limite é calculado com `toISOString`, em UTC.**
- `gastosRecentes`: n = 5, ordem data + id decrescente.
- `precoPorM2`.
- `semAcento` e `filtraGastos`: texto em descrição ou nome do tópico, mês `YYYY-MM`, combinados com E.
- `addMesesClampado`: 31/01 + 1 mês = 28 ou 29/02.
- `gerarParcelas`: conta em centavos; o resto do arredondamento fica na última. Vazio se n > centavos.
- `parcelamentoCartao(valor, n ≤ 36, taxa 0–100, data)`: prestação Price com `expm1`/`log1p`. Total arredondado a centavo e parcelas iguais (a última absorve o resto). Retorna `{valorCompra, taxaMensal, nParcelas, totalCompra, jurosCompra, parcelas}`.
- Máscara: `fmtDigitado` (milhar com ponto, 2 casas), `fmtCompleto` (completa ",00"), `numParaCampo`, `parseNum` (com vírgula, os pontos são milhar; sem vírgula, só remove pontos na posição de milhar).
- `versaoMaior`: compara x.y.z.
- `orcamentoObra`:
  - base sempre bruto, incluindo parcelas futuras;
  - pct arredondado;
  - nível `passou` se gasto − previsto > 0,005; `perto` se pct ≥ 90; senão `ok`;
  - tópicos ordenados por razão decrescente;
  - `fora` = tópicos com gasto mas sem previsto.

---

### 5. Sincronização (cloud.js e app.js)

**Escrita**
- Um documento só, sobrescrito inteiro com `setDoc({...blob, _atualizado: serverTimestamp()})`. O último blob vence (cloud.js:148-256).
- `saveDados` clona o blob e marca `dirty`. Envia imediatamente, mesmo offline, porque a fila persistente do Firestore guarda a ordem.
- A promise só resolve com a confirmação do servidor. Ela tem versão: só a última conta.
- **Guarda de tamanho**: acima de 900000 bytes, erro terminal `limite`. Entre 700k e 900k, toast único "Seus dados estão próximos do limite de armazenamento." (app.js:33-41).
- **Erros**
  - Terminal: para o backoff e o estado vira `erro`.
  - Transitório: estado `repetindo` (ou `offline`) e novo agendamento pelo backoff.
  - Voltar a rede com `online` reinicia a tentativa na hora.
  - `unauthenticated` força a verificação de sessão.
- **Toasts de erro** (app.js:1985-2003):
  - limite: "Não salvou: limite de dados atingido. Reduza os dados e tente novamente.";
  - terminal: "Não salvou na nuvem. Confira sua conexão e conta; toque no aviso para tentar novamente.";
  - transitório: "Sem salvar na nuvem agora — vamos tentar de novo sozinhos.", no máximo um a cada 30 s.

**Eco do snapshot**
- `onSnapshot` com `includeMetadataChanges`.
- Snapshots que chegam com edição local pendente (`localDirty`) são ignorados.
- Senão, normaliza e compara com `canon` (JSON com chaves ordenadas). Só troca o estado se mudou.
- Se a obra aberta sumiu, volta a Início (app.js:1960-1968).
- Erro de leitura vira estado `erro` com origem `leitura`.

**Pílula de sincronização** (app.js:2005-2029)
- Invisível no estado ocioso.
- "Salvando…" (spinner) em salvando/repetindo; "Sem conexão" quando offline; "Não salvou" no erro de escrita; "Não sincronizou" no erro de leitura.
- No erro, tocar dispara toast "Tentando de novo…" e `CLOUD.tentarDeNovo()`.
- Erro de leitura também mostra o toast "Não consegui ler seus dados da nuvem agora (code)."

**Sessão**
- `verificarSessao` faz `getIdToken(true)`, no máximo uma vez por 60 s. Os códigos `auth/invalid-refresh-token`, `user-disabled`, `user-token-expired`, `user-not-found` e `invalid-user-token` fazem signOut. Falta de rede nunca desloga (cloud.js:161-185).
- Na tela de login: "Sua sessão expirou por segurança. Entre de novo pra continuar." (auth.js:81).
- Conta apagada em outro aparelho é tratada pelo mesmo caminho (`user-not-found` / token inválido). Ao deslogar, o app limpa estado, sheet e `custta-estado` (app.js:1946-1954).

**E-mail não verificado**
- Banner `avisoEmail`: "Enviamos um link para {email}…", com "Reenviar link" e "Já confirmei".
- Mensagens: "Link reenviado. Confira também a caixa de spam.", "E-mail já confirmado." e "Conecte à internet…" (app.js:1500-1528).
- Ajustes tem o bloco "Confirme seu e-mail para manter acesso à conta. Você pode continuar usando o app."
- O uso não é bloqueado.

---

### 6. Login, cadastro e conta

**Entrar**
- E-mail (regex `\S+@\S+\.\S+`) e senha. Mensagens: "Digite seu e-mail." e "Digite a senha." (auth.js:192-195).
- "Esqueci minha senha" usa o e-mail digitado: "Digite seu e-mail no campo acima primeiro." e, depois do envio, "Enviamos um link de redefinição pro seu e-mail." (auth.js:203-207).

**Criar conta**
- Campos: Nome (2 a 60), Sobrenome (até 80), E-mail, Senha, Confirmar senha e "Como conheceu o Custta?".
- Origens: Instagram; Indicação de alguém (detalhe "Quem indicou? (opcional)"); Pesquisa no Google; TikTok; YouTube; Outro ("Onde? (opcional)"). Detalhe até 80 (cadastro.js:6-14).
- Regras da senha, mostradas como checklist: 8 ou mais caracteres; uma letra; um número; diferente do e-mail; não ser senha óbvia (lista fixa); máximo 128 (cadastro.js:15-44).

**Apple e Google**
- Web: popup, com fallback para redirect se o popup for bloqueado.
- iOS: plugin nativo, com nonce SHA-256 na Apple (cloud.js:54-90; nativo.js:73-87).
- Conta social sem perfil fica na tela "Falta pouco" até completar:
  - Apple: pede só a origem, porque o nome vem da Apple e a revisão reprova pedir de novo.
  - Google: confirma nome e origem.
  - Opção "Usar outra conta" (auth.js:60-97, 255-287).

**Ajustes > Conta**
- Nome e e-mail exibidos; "Adicionar nome" (diálogo "Seu nome": nome ≤60, sobrenome opcional ≤80).
- "Trocar senha": senha atual, nova (≤128) e repetição. Erro: "As senhas novas não são iguais."
- "Apagar conta" (ui-confirm.js:66-120; cloud.js:526-560):
  - Contas com senha digitam a senha atual. Contas Google/Apple reautenticam por popup ou nativo, ainda dentro do gesto do usuário.
  - É preciso digitar "APAGAR" exatamente.
  - Depois: espera a fila de escrita, remove o push, apaga em lote `dados`, `perfis` e `push/{uid}`, revoga o token Apple (timeout de 10 s), `deleteUser`, esquece o Google e limpa o cache local.
- **Sair** (auth.js:49-54)
  - Espera a fila de escrita.
  - Mensagens possíveis: "Conecte à internet e aguarde a sincronização antes de sair.", "Feche outras abas do Custta antes de sair.", "Não foi possível sair com segurança. Tente novamente."
  - Se o cache não puder ser limpo, aparece o diálogo "Finalizar saída".

---

### 7. Ajustes (index.html:245-330; app.js:1530-1655)

- **Correção pelo banco**: "Taxa ao mês (%)".
  - Aceita 0 < v ≤ 20; aceita vírgula. Fora disso: toast "Informe uma taxa maior que 0 e até 20% ao mês." e o campo volta ao valor anterior.
  - Nota: "Quanto seu dinheiro renderia por mês se estivesse no banco."
- **Meus tópicos**
  - Lista com remover. Vazio: "Nenhum tópico próprio ainda."
  - Adicionar: até 80 caracteres, placeholder "Ex: Piscina, Automação". Máximo 50 pelas rules.
  - Remover é bloqueado se o tópico tem gastos ("Este tópico tem gastos lançados. Mova ou apague os gastos antes.") ou está num orçamento por tópico. Senão pede confirmação.
- **Aparência** (só neste aparelho)
  - Modo claro: escuro é o padrão; localStorage `mo_tema` = 'claro' | 'escuro'.
  - Skin: Esmeralda (padrão) ou Azul; `mo_skin`.
  - Também atualiza theme-color e a barra de status nativa.
- **Notificações**: toggle "Notificações diárias".
  - Nota padrão: "Afazeres pendentes, parcelas do mês e lembrete de lançar gastos. Chega mesmo com o app fechado. Vale neste aparelho." (app.js:1441).
- **Seus dados**: "Exportar dados completos" (JSON) e "Planilha CSV" (share.js).
  - Nome do arquivo: `custta-YYYY-MM-DD.json|csv`.
  - JSON: `{formato:'custta', versao:1, exportadoEm, dados}`.
  - CSV: BOM, separador `;`, CRLF. Colunas: Obra, Fase, Data, Descrição, Tópico, Pagamento, Valor ("1234,56"), Parcela, Total de parcelas.
  - No iOS usa o share sheet nativo (Filesystem + Share). Na web, `navigator.share` ou download.
  - Erro: "Não foi possível exportar. Tente novamente."
- **Aviso de versão nova**: lê `https://app-construcao-civil.vercel.app/versao.json`. Se `versao` é maior que `APP_VERSAO` e `loja` começa com `itms-apps://`, mostra o link e "Agora não", que grava `custta-versao-dispensada` (app.js:2075-2086).
- **Diagnóstico**: anel com os últimos 20 erros `{hora, origem, msg, stack}` em `window.OBRA_DIAG`, além do Sentry (app.js:2039-2047). Não encontrei UI visível para isso.
- **Conta**: ver seção 6. Link para "Política de privacidade" (`privacidade.html`).

---

### 8. Notificações (cliente)

- **Convite após login** (banner com "Agora não" e "Ativar"): uma resposta encerra os convites para aquela conta neste aparelho (`custta-notif-convite-{uid}`). Continua disponível em Ajustes (app.js:1445-1480).
- **iOS (FCM)**:
  - `requestPermissions`, depois `getToken`, depois grava em `push/{uid}.tokens.{hash}` e salva a chave local.
  - A cada login, `sincronizarToken`: se o token mudou, grava o novo e apaga o antigo.
  - Desativar ou sair apaga só o token deste aparelho (push.js:70-125).
- **Toque na notificação**: lê `data.obraId` (iOS `notificationActionPerformed`; web `#obra=ID` ou mensagem do SW `tipo:'abrir-obra'`). Depois do 1º snapshot abre a obra; se ela não existir, abre Início. Ao trocar de conta, a pendência é descartada (push.js:58-64, 145; app.js:1927-1939).

---

### 9. Comportamentos transversais

**Formatação**
- Moeda: `Intl pt-BR BRL`.
- `moneyShort`: "R$ 1,23 mi" (2 casas abaixo de 10 mi, 1 acima) e "R$ 8,5 mil" (1 casa abaixo de 10 mil, 0 acima).
- `moneyCurto` tira ",0".
- Data dd/mm/aa. Meses abreviados "jan…dez" (app.js:65-78).

**Teclado de valor próprio**
- Trabalha em centavos inteiros, com teto R$ 99.999.999,99. Acima do teto a tecla é ignorada, não trunca.
- Teclas 0–9, "00" e del (teclado.js:10-28).

**Gestos** (gestos.js)
- Arrastar para apagar: largura de 80 px; arrasto máximo de 120; abre se passar da metade (com projeção de velocidade).
- Puxar o sheet: fecha se dy > 30 e dy + projeção > 120. Só puxa com o scroll no topo e, se houver campo focado, só pela alça de 32 px.
- Voltar pela borda: dx > 40 e dx + projeção > 35% da largura. Não funciona com sheet, diálogo ou teclado abertos.

**Outros**
- Vibração: `Haptics impact LIGHT`, só quando o servidor confirma um gasto (nativo.js:134).
- Sheet acompanha `visualViewport` para não ficar atrás do teclado do iOS.
- Ajuste de tamanho dos números grandes (`fitNums`).
- Acessibilidade: aria-labels, combobox nas sugestões, `aria-live` no resumo do cartão e na soma do orçamento. Não verifiquei o suporte a letra grande.
- Limites: 300 obras, 50 tópicos custom, 100 tópicos por orçamento, 10 tokens e 10 subs de push. As 300 obras são checadas só pelas rules; **não existe aviso na UI**, então a escrita vira erro terminal.

---

### 10. Pontos surpreendentes

1. **Normalização ao carregar** (dados.js:62-68):
   - taxa fora de (0, 20] vira 1;
   - gasto sem id, com data inválida ou valor negativo é descartado;
   - `topico` vazio vira 'outros'; `pagamento` vazio vira 'pix';
   - parcela inválida perde `grupoId` e `parcela`;
   - fase 'vendida' sem venda válida vira 'construcao';
   - nome vazio vira "Obra sem nome";
   - `afazer.feito` só é verdadeiro se for exatamente `true`;
   - ícone de tópico custom vazio vira 'etiqueta';
   - números em string são aceitos;
   - **campos desconhecidos são preservados**, e a reescrita precisa manter isso.
2. **CSV**: o nome do tópico só é resolvido para tópicos custom. Os padrões saem com o id (ex.: "maoobra") (share.js:13-14).
3. Tópico custom apagado faz o gasto exibir o id cru (app.js:61).
4. A migração antiga de localStorage `obras_data_v1*` foi removida de propósito, por vazar dados entre contas (app.js:1956-1959).
5. As parcelas guardam o valor **com juros**. `jurosCartao` é repetido em cada parcela.
6. O orçamento e o "A pagar" contam parcelas futuras no bruto. O lucro e o corrigido também incluem gastos futuros: `diasEntre` dá 0 quando o gasto é posterior.
7. Datas em hora local, exceto o limite do `aPagar`, que usa UTC e pode errar de um dia perto da meia-noite.
8. A busca nos lançamentos não é persistida e zera ao abrir outra obra.
9. Editar a data de início não revalida venda nem gastos.
10. Rotas de "voltar" internas: editar ou excluir dentro do sheet do tópico retorna ao sheet.
11. Arquivos principais: `app.js`, `calc.js`, `dados.js`, `cloud.js`, `auth.js`, `cadastro.js`, `ui-confirm.js`, `push.js`, `share.js`, `teclado.js`, `gestos.js`, `nativo.js`, `firestore.rules`, `index.html`, todos na raiz do repositório.

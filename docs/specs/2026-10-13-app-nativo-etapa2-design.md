# Custta nativo, etapa 2: obras e gastos

Data: 2026-10-13. Spec da etapa 2 do app nativo (`docs/specs/2026-10-06-app-nativo-design.md`, seção "Etapas"): lista de obras, obra com indicadores, lançar, editar e apagar gasto, fases e venda. Ele junta o que o Giovani aprovou no mockup do Croqui (três partes, 12 e 13/10) e as decisões de planejamento tomadas com ele em 13/10. O plano de implementação, com tarefas e código, é escrito a partir daqui.

## Contexto

A etapa 1 fechou com o #67 (12/10): o app entra na conta, mostra a lista de obras com os totais do site, sincroniza e funciona sem internet, mas ainda não grava nada. O TestFlight 2.0 build 1.2 está com o Giovani para o checklist do aparelho da etapa 1 (`docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md`).

A etapa 2 é a primeira em que o app nativo **grava** no Firebase de produção. Como o site, cada gravação regrava o documento `dados/{uid}` inteiro. Um defeito de gravação mexe em todas as obras da conta, por isso este spec trata a gravação com mais cuidado que a tela.

## Mockup aprovado

Fora do repositório, em `~/Documents/custta-mockups/nativo/etapa2/` (abrir no Chrome; o resumo de cada parte e as decisões estão no `LEIA-ME.md` da pasta):

| Parte | Arquivo | O que desenha | Aprovação |
| --- | --- | --- | --- |
| 1 | `parte1.html` | a tela da obra: cabeçalho, indicadores, lista de gastos por mês, "A vencer", entrar e voltar | 12/10 (com um ajuste na pílula da fase) |
| 2 | `parte2.html` | lançar, editar e apagar gasto; tópico; cartão parcelado; descrição; data; avisos | 13/10, "curti dms tudo" |
| 3 | `parte3.html` | fases e venda; criar, editar e apagar obra; estados; quatro combos; letra máxima | 13/10, "legal aprovada" |

Cada parte traz medidas, a separação "obrigatório × sugestão aprovada" e a tabela de contraste. Os prints `parte*-*.png` são a referência da conferência visual. `pwa-hoje-gasto/` e `pwa-hoje-obra/` têm o site de hoje nos mesmos fluxos.

## Decisões de desenho (aprovadas no mockup)

**Tela da obra (parte 1).**
- Nome da obra no título grande; fase e tempo numa pílula de vidro; voltar pelo círculo e pelo gesto da borda; lápis para editar a obra.
- Indicadores na **opção A**: o total gasto em destaque e um cartão com Corrigido, A pagar (com chevron; a folha é da etapa 3) e Venda.
- Lista de gastos em cartões de vidro por mês, com o total do mês; linhas sólidas dentro, sem vidro dentro de vidro.
- **"A vencer" agrupado e fechado** no alto da lista.
- Valor sem vermelho, só com o "−"; "Pix" e "Cartão" escritos por extenso; linha sem descrição sem repetir o tópico.
- Na venda sem estimativa, o texto "Toque no lápis para informar o valor".
- Entrar na obra pelo push do `NavigationStack`, com a seta ">" de volta nas linhas da lista (estava fora até esta etapa).

**Gasto (parte 2).**
- O + dentro da obra abre uma folha do sistema em **dois passos**:
  - primeiro o valor, no teclado de maquininha do app (centavos entram pela direita, teclas 0–9, 00 e apagar, teto R$ 99.999.999,99), com as teclas na ordem do telefone;
  - "Avançar" empurra os detalhes, na ordem do site: valor, tópico, pagamento, descrição e data, com "Salvar" fixo embaixo.
- **Tópico, opção A:** uma linha que abre a lista dentro da folha, com "Usados nesta obra" (três) no alto. O tópico inicial é o do último gasto lançado nesta obra.
- **Cartão:** "Parcelas" (menu de 1x a 36x), "Juros ao mês" e o resumo do site. A data vira "Primeiro vencimento" e começa um mês à frente; cada forma de pagamento guarda a sua data.
- **Descrição:** as sugestões do site (até cinco, com "mesmo tópico" ou "N× usado") aparecem acima do teclado do sistema.
- **Data:** no calendário do iPhone. Data futura é aceita e vai para "A vencer".
- **Depois de salvar:** sem toast. A folha desce, a lista rola até o gasto novo, que fica destacado por ~2 s com a etiqueta "novo", e o aparelho vibra.
- **Editar:** a mesma folha, direto nos detalhes ("Editar gasto"). O valor abre o mesmo teclado ("Pronto"). Numa parcela, aparece o aviso do site: a edição vale só para ela. "Apagar gasto" fica no fim da folha.
- **Apagar:** arrastar a linha para a esquerda (o "Apagar" do sistema, sem apagar no arrasto até o fim) ou o botão na folha. Sempre pergunta, num alerta com nome e valor. Numa parcela, um diálogo de ações oferece "Apagar só esta parcela" e "Apagar a compra toda (N parcelas)". A palavra é "Apagar" em tudo.
- **Animação de apagar:** a do sistema, só depois da confirmação. A linha sai, as de baixo sobem e o total do mês e os indicadores atualizam juntos. Mês que fica vazio fecha o cartão; "a compra toda" tira as N parcelas de uma vez. O Giovani deixou a animação a cargo do time ("vou confiar na sua animação").
- **Avisos:**
  - gasto repetido: o texto do site e o botão "Salvar mesmo assim" em âmbar;
  - descartar: perguntar só depois de passar do valor;
  - `nao-carregado`: alerta com o texto do site, "Carregando suas obras" (sem rede: "Conecte à internet para carregar suas obras antes de lançar."); o gasto continua na folha.

**Obra e estados (parte 3).**
- **Ações da fase**, logo abaixo dos indicadores. O próximo passo vai numa pílula sólida da marca ("Marcar como pronta", "Registrar venda"); voltar vai numa pílula de vidro ("Voltar pra construção", "Desfazer venda"). Só desfazer a venda pergunta, com o texto do site.
- **Venda** em dois passos: o valor no teclado de valor, depois a data, que o calendário limita entre o início da obra e hoje, e "Confirmar venda".
- **Obra vendida** não recebe gasto novo. O + abre a folha com uma linha "Obra" para escolher entre as obras abertas; os gastos que ela já tem continuam editáveis.
- **Nova obra:** o + da lista abre a folha, com o cursor no nome e o teclado aberto.
  - Campos do site: nome até 120, começou em, área obrigatória com o erro do site, e valor estimado e orçamento opcionais no teclado de valor.
  - "Criar obra" entra direto na obra nova.
- **Editar obra:** os mesmos campos menos o orçamento, com área opcional e "Apagar obra" no fim. O alerta de apagar mostra o nome e o número de lançamentos. Depois de apagar, o app volta à lista e a linha sai com a animação do sistema.
- **Estados:**
  - nenhuma obra;
  - carregando;
  - obra sem gastos;
  - sem conexão (lançar continua funcionando);
  - "Não salvou" (tocar tenta de novo; um alerta aparece uma vez quando o erro não passa sozinho, com o texto do site);
  - "Não sincronizou";
  - limite de 300 obras.
- **Na barra da obra** não cabem título pequeno, pílula de sincronização, voltar e lápis. Enquanto a pílula aparece, o título pequeno sai.
- **Letra máxima:** dinheiro numa linha só, encolhendo para caber (`minimumScaleFactor`); os textos quebram.
  - Na folha, o rótulo vai em cima do valor; o segmentado empilha.
  - As teclas do teclado de valor param no tamanho AX2; o título da barra para perto de 22 pt.
  - Na linha de gasto, cada informação ocupa uma linha, sem o "·".
- **Tokens novos, só da folha:** Folha (vidro denso), Linha da folha, Tecla, Tecla tocada e Segmentado escolhido, nos quatro combos. O contraste das superfícies sólidas novas passa de 4,5:1 nos quatro.

**Cápsula de abas.** O + volta para a cápsula, na Tinta, como no mockup. As abas seguem só **Obras** e **Ajustes**. A aba "Vale a pena?", que aparece no mockup, entra na etapa 4, com o simulador; aba vazia não se mostra.

## Regras: iguais ao site

O comportamento vem do site de hoje (`app.js` `formGasto`, `formNovaObra`, `formEditarObra`, `formVenda`, `mudarFase`; `teclado.js`; `gestos.js`; `ui-confirm.js`; `calc.js`; `dados.js`), lido no `origin/main` em 13/10. O plano refaz o inventário com arquivo e linha, como o `docs/plans/2026-10-06-app-nativo-inventario.md` fez na etapa 1. As regras que importam para o código:

- **Gasto:**
  - valor > 0;
  - descrição até 500 (`LIMITES`, `dados.js`);
  - cartão com 1 a 36 parcelas e juros de 0 a 100% ao mês;
  - parcelamento por `parcelamentoCartao`/`gerarParcelas` (Price; diferença de centavos na última parcela; datas mês a mês com clamp);
  - N gastos irmãos com o mesmo `grupoId`, `parcela {n, de}` e `jurosCartao`;
  - cartão 1x vira um gasto só;
  - mudar uma edição para Pix apaga `jurosCartao`;
  - editar uma parcela muda só ela;
  - mensagens de erro do site ("Use até 500 caracteres.", "Confira valor, parcelas, data e taxa de juros", "O valor precisa ter pelo menos um centavo por parcela").
- **Repetido:** mesma descrição, valor e data de um gasto que já existe na obra.
- **Sugestões de descrição:** as do site (até cinco, priorizando o mesmo tópico).
- **Obra:**
  - nome de 1 a 120 caracteres;
  - área > 0 ao criar e opcional ao editar;
  - orçamento > 0 grava `orcamento {modo: 'total', total}`;
  - obra nova nasce em `fase: 'construcao'` com `gastos: []`.
- **Fases:**
  - `mudarFase` sem pergunta;
  - venda com `valor > 0` e data entre o início e hoje, gravando `venda {valor, data}` e `fase: 'vendida'`;
  - desfazer apaga `venda` e volta para `pronta`;
  - correção e meses param na data da venda (já no núcleo).
- **Obra vendida:** fora da escolha de obra do gasto novo e no fim da lista.
- **Formato do estado:** nenhuma chave nova. `firestore.rules` não muda nesta etapa.

## Arquitetura

As três camadas do spec do app nativo, sem pacote novo.

**Núcleo (`CusttaNucleo`).** Ganha as regras puras que as telas que gravam precisam, todas testadas por vetores gerados do site, como na etapa 1A:

- **Validação:** do gasto, da obra e da venda, devolvendo as mensagens do site.
- **Mutações sobre o estado:**
  - gasto: lançar (com as parcelas), editar, apagar um gasto, apagar a compra toda;
  - obra: criar, editar e apagar;
  - fases: mudar a fase, registrar a venda, desfazer a venda.
  - Cada uma devolve o estado novo; o app grava o resultado pelo `Sincronizador`.
- **Sugestões de descrição** e **detecção de repetido.**
- **Tópico inicial e "Usados nesta obra":** regra nova do app, sem vetor do site, com teste próprio.
  - Usados nesta obra: os três tópicos com mais gastos na obra; no empate, o do gasto mais recente.
  - Tópico inicial: o do último gasto lançado na obra; obra sem gasto começa no primeiro tópico, como no site.

Regra que hoje só existe dentro do `app.js`, como as sugestões e o repetido, é movida antes para o `calc.js` num PR do site, para entrar nos vetores. As duas cópias nascem iguais, como manda o spec do app nativo.

**Dados e estado (app).**
- O `ModeloApp` ganha as ações que chamam as mutações e o `Sincronizador.salvar`.
- A **guarda de gravação** fecha as duas pendências obrigatórias do plano da etapa 1:
  1. uma marca por conta "o servidor já respondeu", apagada junto com o cache, que entra na condição da guarda;
  2. a mensagem própria para `nao-carregado` na tela que grava.
- A gravação preserva campos que o app não conhece; a conferência cruzada já confere isso desde a etapa 1 e passa a cobrir cada mutação.

**Telas (app).**
- Tela da obra; folha do gasto (passos valor, detalhes e tópicos); teclado de valor reutilizável (gasto, venda, valor estimado, orçamento); folha da obra; folha da venda; ações da fase; estados.
- O caminho dentro de Obras (`NavigationStack(path:)`) mora no `PrincipalView`, como o plano da etapa 1 previu, para sobreviver à troca de aba.

## PRs

Decisão de 13/10: **fatias que já gravam**. Cada PR entrega uma parte inteira, gravando de verdade, e gera um build 2.0 no TestFlight que o Giovani testa no iPhone na **conta de teste**.

| PR | O que entrega | Build |
| --- | --- | --- |
| 0a (site) | Aviso do limite de 300 obras: o + da lista avisa antes de abrir "Nova obra". O texto entra no site primeiro; o app copia. Recomendação: "Limite de 300 obras" / "Apague uma obra antiga para criar outra." | — |
| 0b (site) | Sugestões de descrição e detecção de repetido saem do `app.js` para o `calc.js`, sem mudar o comportamento, e entram nos vetores (`scripts/vetores-calc.mjs`). | — |
| 1 | Tela da obra só leitura (parte 1 inteira); entrar e voltar; a seta ">" na lista; o caminho no `PrincipalView`; a guarda de gravação com a marca por conta; o script da conta de teste. | sim |
| 2 | Gasto inteiro (parte 2): + na cápsula, folha em dois passos, teclado de valor, tópico A, cartão, descrição, data, editar, apagar (arrastar e folha), avisos e animação de apagar. Conferência cruzada: gasto lançado, editado e apagado no app aparece certo no site, inclusive parcelas. | sim |
| 3 | Obra e estados (parte 3): fases e venda, criar, editar e apagar obra, gasto em obra vendida, estados e pílula, quatro combos e letra máxima conferidos nas telas das três partes. Conferência cruzada completa. Checklist do aparelho da etapa 2. Depois dele, troca para a conta real. | sim |

Os PRs do site (0a e 0b) podem andar em paralelo com o PR 1. O 0a entra antes do PR 3 e o 0b antes do PR 2.

## Conta de teste

Decisão de 13/10: o app nativo grava numa **conta de teste em produção** até a conferência do PR 3 passar; depois o Giovani passa para a conta dele.

- A conta recebe uma cópia das obras do Giovani.
- Caminho recomendado: estender `scripts/conta-demo.mjs` (que já cria e repovoa a conta de revisão da Apple, confere o formato que as rules aceitam e usa `FIREBASE_SERVICE_ACCOUNT`) com uma opção que lê um JSON exportado pelo site (Ajustes → exportar) e um e-mail próprio.
- O JSON do Giovani nunca entra no repositório.
- **Passos que só ele faz:** exportar o JSON pelo site; criar a senha da conta de teste; disponibilizar a conta de serviço na máquina; instalar o build e entrar com a conta de teste.
- Se o pai usa a conta do Giovani, os dados dele também ficam protegidos por isso.

## Testes e validação

Os mesmos portões da etapa 1, estendidos:

1. **Vetores:** as regras novas do núcleo conferidas contra o site (`swift test` no job `nucleo`).
2. **Unidade do app:** modelo e ações com serviços falsos, incluindo a guarda de gravação (marca do servidor, cache sem documento, cache apagado) e a recusa com mensagem.
3. **Telas (XCUITest):**
   - abrir a obra e voltar (botão e borda);
   - lançar Pix e cartão;
   - editar;
   - apagar arrastando e pela folha;
   - apagar uma parcela e a compra toda;
   - criar, editar e apagar obra;
   - mudar a fase, registrar e desfazer a venda;
   - repetido;
   - descartar;
   - `nao-carregado`;
   - sem rede.
4. **Leitura sobre o vidro e acessibilidade:** o laudo de leitura (portão na CI) e as auditorias cobrem as telas novas nos quatro combos e na letra máxima, como na etapa 1.
5. **Conferência visual:** simulador lado a lado com os prints do mockup, tela a tela.
6. **Conferência cruzada** contra os emuladores (`npm run test:app-ios:cruzado`): cada mutação do app aparece certa no site, e o que o site grava aparece no app, inclusive campos que o app não conhece.
7. **Aparelho:** um checklist da etapa 2 no estilo do da etapa 1, testado pelo Giovani a cada build e fechado no PR 3.

## Para o conselho

Decisões grandes que o planejador leva ao conselho (três Opus com lentes diferentes, crítica às cegas):

1. **Lista da obra e o arrastar do sistema.** `.swipeActions` só funciona dentro de `List`, e a parte 1 desenha cartões de vidro por mês com linhas sólidas dentro. Os caminhos são três:
   - `List` estilizada (seções como cartões de vidro, `listRowBackground`, espaçamento das seções);
   - `ScrollView` com o arrastar feito à mão;
   - outro caminho que o conselho propuser.
   Pesam o desenho aprovado, a animação de apagar do sistema, o VoiceOver (ações personalizadas) e o desempenho com centenas de gastos.
2. **A folha em dois passos.** `NavigationStack` dentro da `.sheet` (valor → detalhes → tópicos) ou passos próprios. Pesam o voltar pela borda dentro da folha, o "descartar?" ao puxar para baixo (`interactiveDismissDisabled` só depois do valor) e o foco do teclado do sistema na descrição.

## Decisões tomadas por recomendação

Em 13/10 o Giovani pediu: "faça sempre o recomendado". Ficaram assim, com o porquê:

- **Fatias que já gravam** (escolhida por ele): teste no iPhone a cada PR; o Firebase já está ligado desde a etapa 1.
- **Conta de teste até o PR 3** (escolhida por ele): o site não importa backup, e a gravação regrava o documento inteiro.
- **Time do Maestri** (escolhido por ele): o Prumo escreve o plano a partir deste spec; o Forja implementa; o Lupa revisa cada tarefa; o Verniz confere com o mockup.
- **Aba "Vale a pena?" só na etapa 4:** uma aba sem conteúdo prometeria o que o app ainda não faz.
- **Regras do `app.js` passam antes pelo `calc.js`:** é o que mantém site e app conferidos pelos mesmos vetores.
- **Texto do limite de 300 obras:** "Limite de 300 obras" / "Apague uma obra antiga para criar outra.", no site primeiro. É curto, diz o que fazer e não promete aumento de limite.

## Riscos

- **Primeira gravação do app.** Mitigado pela conta de teste, pela guarda de gravação, pela conferência cruzada de cada mutação e pela preservação de campos desconhecidos.
- **Lista com o arrastar do sistema** (ver "Para o conselho"). Se a `List` não segurar o desenho, o arrastar feito à mão precisa acertar acessibilidade e gestos concorrentes (rolagem, voltar pela borda).
- **Tempo da CI.** O job `app` está em 42–53 min, com teto de 75. Telas e laudo novos somam tempo; o plano mede e, se passar de ~65 min, divide o job.
- **Teclado do sistema na folha.** A descrição sobe acima do teclado com o "Salvar" junto; na letra máxima sobra pouco espaço, e o plano confere em 375 pt (13 mini) além de 402.

## Fora do escopo

- **Etapa 3:**
  - orçamento previsto × real e "Definir orçamento";
  - afazeres;
  - busca e filtro por mês;
  - detalhe do tópico;
  - a folha "A pagar" (o indicador leva chevron, mas ainda não abre).
- **Etapa 4:** gráficos, relatório, simulador "Vale a pena?" e PDF.
- **Etapa 5:** tópicos próprios (criar e apagar em Ajustes), exportar e notificações.
- **Fora da etapa:** mudança no site além dos PRs 0a e 0b; mudança nas `firestore.rules`.

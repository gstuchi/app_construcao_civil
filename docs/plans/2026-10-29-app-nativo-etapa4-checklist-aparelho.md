# App nativo, etapa 4: checklist no iPhone

O Giovani roda no iPhone, pelo TestFlight, o build de cada fecho de marco da etapa 4 (marco 1: os PRs 1a, 1b e 1c; marco 2: 4a, 2a e 2b; marco 3: 3a, 3b e 4b), **na conta de sempre**. Cada item que falhar vira tarefa para o Forja, com o passo, o que apareceu e uma captura de tela. Os itens de um marco continuam valendo nos builds seguintes. Os itens que mexem em gasto usam uma obra de teste criada no próprio app ("Obra de teste") e apagada no fim.

## Antes do primeiro build

A etapa não grava nada novo: os caminhos de gravação são os das etapas 2 e 3. Mesmo assim, a cópia vale antes de cada build de marco.

- [ ] No site: Ajustes → Seus dados → Exportar dados completos. Guarde o arquivo (`custta-AAAA-MM-DD.json`) fora do repositório, como cópia de segurança.
- [ ] O PR 0 do site já está publicado (as seis regras no `calc.js` e os dois alinhamentos do "Vale a pena?").

## Marco 1: os tokens globais e a obra em blocos

**Os tokens, no app inteiro** (PR 1a)

- [ ] No claro, o âmbar dos textos sobre o vidro ficou mais escuro (`#5E3A03`): o aviso dos tópicos na linha do orçamento, o "Passou … do previsto" da tela Orçamento e o prejuízo no bloco da Venda. Diga se algum texto ficou pesado demais.
- [ ] No escuro, o globo continua como antes (a 40% dentro do app: o 1a mediu, e ele já era mais apagado que o do mockup); nada fica difícil de ler por cima dele.
- [ ] A cápsula de abas e o + ficam a 16 pt da borda em todas as telas (Obras, a obra, Orçamento, Afazeres, Ajustes) e não pulam de lugar ao trocar de aba.

**A obra em blocos** (PRs 1b e 1c; mockup aprovado, parte 1)

- [ ] Abra a obra de sempre: o nome no título em letra mono (SF Mono), quebrando em duas linhas se for comprido; embaixo, a cápsula com a fase e "começou em … · N meses".
- [ ] O Total gasto no bloco verde, com o número em mono e o R$ e os centavos menores na mesma linha; "N lançamentos" na etiqueta e "bruto, sem correção" embaixo. Os números são os do site.
- [ ] Depois, um bloco por assunto, na ordem de antes: Orçamento (com a seta, abre a tela Orçamento), Corrigido pelo banco, A pagar · 30 dias (com a seta, abre a folha do A pagar) e Venda estimada. As ações da fase, os Afazeres, "Gastos por tópico" e os Lançamentos vêm depois; nada da etapa 3 sumiu.
- [ ] "Gastos por tópico": a barra com um pedaço por tópico (os 6 maiores nas cores e "Outros" em cinza) e a legenda dos 4 maiores com o %, e "e mais N tópicos". Os % batem com a folha do detalhe de cada tópico. A barra não abre nada neste build (os Gráficos chegam no marco 2), e não há "Ver gráficos" nem "Relatório".
- [ ] Os lançamentos com o valor em mono à direita e o ícone pequeno do tópico na linha de baixo; um título comprido quebra, e o valor desce para baixo do título só quando não cabe ao lado. As folhas (A pagar e detalhe do tópico) continuam com a linha de antes.
- [ ] Uma obra sem orçamento: o bloco do Orçamento some e "Definir orçamento" aparece nas ações.
- [ ] Na "Obra de teste", sem gastos: o bloco verde mostra R$ 0,00 e "Toque no + para lançar o primeiro gasto."; somem "Gastos por tópico", a lupa e o mês. Lance um gasto pelo +, no tópico "Outros": a barra de tópicos aparece com ele, toda cinza, e a linha nova acende na lista.
- [ ] Lance outro gasto na "Obra de teste", menor, em "Terreno": o Terreno sai colorido, e o "Outros" fica cinza, no fim da barra, mesmo sendo o maior.
- [ ] Marque a "Obra de teste" como pronta, registre uma venda maior que os gastos e confira: o bloco verde vira "Lucro da venda", com "+R$ …", "Vendida em …" e "+R$ … acima do banco", e o Total gasto desce para um bloco de vidro logo abaixo do sólido (depois do Orçamento, se a obra tiver um). Desfaça a venda e registre uma menor que o gasto: o bloco verde volta a ser o Total gasto, e o lucro negativo fica no bloco da Venda, em âmbar (nunca vermelho). Desfaça a venda e apague a "Obra de teste".
- [ ] Os gestos de antes: arrastar um lançamento para a esquerda mostra "Apagar"; o "A vencer" abre e fecha; a lupa e o mês filtram só a lista; rolar a tela faz o nome passar para a barra, também em mono.

**Texto Maior no máximo** (Ajustes do iPhone → Acessibilidade → Tela e Tamanho do Texto → Texto Maior)

- [ ] O título cresce e quebra em duas linhas (numa obra de nome comprido); a cápsula, os blocos e a etiqueta de cada bloco empilham, sem nada cortado.
- [ ] O número do bloco verde encolhe só o necessário para caber numa linha, sem reticências, com o R$ e os centavos ainda legíveis; os números dos outros blocos, o mesmo.
- [ ] Na legenda da barra, 3 tópicos e "e mais N tópicos"; o nome comprido quebra em vez de cortar.
- [ ] Nos lançamentos, o valor desce para baixo do título e cada informação fica numa linha.

**Acessibilidade**

- [ ] VoiceOver, na obra: cada bloco é um elemento só, lido inteiro ("Total gasto, 46 lançamentos, R$ 842.317,45, bruto, sem correção"); o número é lido como dinheiro, com os centavos. O título é um cabeçalho.
- [ ] VoiceOver, nos gastos por tópico: o bloco é um elemento só, "Gastos por tópico", com os pedaços e o % de cada um ("Terreno, 38%; Estrutura, 11%; …"; "menos de 1%" no lugar do "<1%"); a legenda não é lida de novo.
- [ ] VoiceOver, na vendida com lucro: "Lucro da venda, Vendida em …, +R$ …, +R$ … acima do banco". Diga se o "mais" e o "menos" são falados de um jeito que se entende.
- [ ] VoiceOver, os blocos com seta: dois toques no Orçamento abrem a tela Orçamento e no A pagar abrem a folha dele; o rotor e o gesto de escape continuam como na etapa 3.
- [ ] Controle por Voz ("Mostrar nomes"): "Tocar Orçamento", "Tocar A pagar", "Tocar Afazeres" e o nome de um lançamento funcionam; os gastos por tópico não aparecem como botão.
- [ ] No escuro e no claro, nos vidros Transparente e Fosco (Ajustes → Aparência), os pedaços da barra se distinguem da placa atrás e entre si, e o texto da legenda se lê. Com Reduzir transparência, os blocos ficam sólidos e nada some.
- [ ] Com Aumentar contraste, a obra inteira continua legível, e o bloco verde não muda de cor.

## A obra em List (o TestFlight da troca, antes do marco 2)

A tela da obra trocou de estrutura por dentro, para não travar no iOS 26. Nada deveria mudar à vista: compare com o build
do marco 1 nas mesmas obras.

- [ ] A obra abre igual à do marco 1: o título, a cápsula, os blocos, as ações, os Afazeres, os gastos por tópico, a pílula
  "Lançamentos" e os meses, com os mesmos espaços. O botão "Marcar como pronta" com o ícone junto do texto, no meio.
- [ ] Rolar com o dedo, devagar e rápido, de cima a baixo e de volta: a lista acompanha o dedo, sem soluço nem salto.
  Logo depois de abrir, os primeiros arrastos andam como os de depois.
- [ ] Tocar no Orçamento e nos Afazeres abre como antes, sem um realce cinza no bloco inteiro; ao voltar, nada pisca.
- [ ] Lançar um gasto pelo +: a lista rola até a linha nova, que acende por 2 s. Editar um gasto do fim de um mês longo:
  ao salvar, a linha fica à vista e acende, sem a lista ir ao topo do mês e voltar.
- [ ] Uma compra no cartão em 10x: a lista rola até o "A vencer", que abre, com a 1ª parcela à vista e acesa.
- [ ] Arrastar um lançamento para a esquerda mostra "Apagar"; tocar em outra linha, no A pagar ou rolar fecha. Tocar fora
  das linhas e dos botões não fecha mais a linha aberta: no vão entre duas linhas (aceito em 03/11), e também no título,
  na cápsula, nos blocos de número, no cabeçalho de um mês e nos gastos por tópico. Diga se isso serve.
- [ ] A lupa: o campo abre embaixo da pílula, a lista rola até ela, e o teclado sobe e desce sem a tela travar. O campo
  nunca fica escondido sob a barra de cima, e o × dele limpa a busca. Com o teclado aberto, um arrasto curto o deixa
  aberto, e rolar até o campo ir longe da tela (meia tela além) o fecha, como no marco 1. Digitar logo depois de um
  arrasto curto, com a lista ainda deslizando: o teclado fica, e a letra entra.
- [ ] Lance no site um gasto de teste ("teste busca"), busque por ele no iPhone e, com a busca aberta e o teclado em cima,
  apague esse gasto no site: o campo segue abaixo da barra, e o × limpa a busca.

**Texto Maior no máximo**

- [ ] Numa obra de lista curta, arrastar a lista para cima e para baixo várias vezes: nada trava (era o defeito do iOS 26).
- [ ] Na obra de mais lançamentos que você tiver, rolar até o mês mais cheio e de volta: diga se alguma parada se nota, e
  quanto tempo dura. A versão de teste da sessão (Decisões) mede isso no Instruments.
- [ ] Com a obra rolada até o meio, mudar o Tamanho do Texto pela Central de Controle, para um menor e de volta ao máximo:
  a obra volta com o mesmo bloco no alto da tela, sem pular para outro mês.

**Acessibilidade**

- [ ] VoiceOver: o anel de cada bloco, da cápsula e do título tem o tamanho de antes (a cápsula não fica mais alta).
- [ ] VoiceOver, depois de salvar um gasto, o foco vai para a linha nova; depois de apagar, para a linha vizinha, e ele
  diz "Gasto apagado". Apague a compra toda (uma parcela do A vencer): o foco vai para uma linha que existe na tela.
- [ ] VoiceOver, o rotor de cabeçalhos passa por todos os meses, também os que estavam fora da tela.
- [ ] Controle por Voz ("Mostrar nomes"): "Tocar Orçamento", "Tocar A pagar", "Tocar Afazeres" e o nome de um lançamento.
- [ ] Com Reduzir movimento, Aumentar contraste e Reduzir transparência ligados nos Ajustes do iPhone (não no app), a obra
  continua como no marco 1.

## Marco 2: o "Vale a pena?" e os Gráficos

**A aba "Vale a pena?"** (PR 4a; mockup aprovado, parte 2)

- [ ] A cápsula tem três abas: Obras, Vale a pena? e Ajustes. A nova fica no meio, e o + some nela, como em Ajustes. A
  cápsula continua a 16 pt da borda e não pula ao trocar de aba.
- [ ] A aba abre com a primeira obra em andamento que tem gastos, o preço na venda estimada dela e os meses em 0. A conta já
  aparece: o bloco verde "Vale a pena" ou o âmbar "Rende menos que o banco", com a taxa ao mês em mono. Com a mesma obra,
  o mesmo preço e os mesmos meses, os números são os do simulador do site.
- [ ] "Obra": a lista traz só as obras não vendidas que têm gastos. Trocar de obra troca o preço, enquanto você não digitou.
- [ ] Toque em "Se eu vender por": as teclas tomam o lugar da cápsula, com o valor ainda à vista. O primeiro dígito
  substitui o valor (não emenda nele), os centavos entram pela direita, e a conta acompanha cada tecla. "OK" fecha as
  teclas, e a cápsula volta. Abrir e dar "OK" sem digitar deixa tudo como estava. Diga se o valor à vista, com o cursor
  depois dele, deixa claro que o próximo dígito substitui (o mockup só desenha o campo vazio).
- [ ] Apague o preço até o fim: o campo fica com "R$ 0,00" apagado, e aparece "Digite o preço de venda pra ver a conta.". Ele
  não volta para a venda estimada, nem trocando de obra. Fechando e abrindo o app, volta.
- [ ] O − e o + andam de um em um mês; o − para em 0 e o + em 120, e a frase do bloco acompanha ("vendendo hoje", "vendendo
  daqui a 6 meses").
- [ ] A faixa "Onde a sua venda cai": o custo numa barra, o tracejado do empate com o banco e a venda numa barra com um
  ponto em cima; a parte hachurada é o lado "acima do banco". A etiqueta diz de que lado a venda caiu, e os três valores
  vêm embaixo, cada um com o marcador dele.
- [ ] A tabela "Relatório da simulação", pelo bruto e pelo corrigido; na obra com área, a última linha é o preço por m². Um
  preço abaixo do custo mostra o prejuízo em âmbar, nunca em vermelho.
- [ ] Numa obra que começou há menos de 1 mês: a taxa vira "—", e aparece "obra com menos de 1 mês — % ao mês ainda não diz
  muito".
- [ ] Vá a Ajustes e volte: a obra, o preço e os meses continuam. Lance um gasto na obra escolhida e volte à aba: a conta já
  mudou.

**Texto Maior no máximo**

- [ ] O título quebra em duas linhas; cada campo fica com o valor embaixo do nome; o − e o + crescem.
- [ ] Toque no preço: a linha "Se eu vender por" sobe e fica inteira acima das teclas. As teclas param de crescer antes do
  máximo, como as do orçamento, e a barra delas ("Preço de venda" e "OK") também: tocar e segurar no "OK" mostra o texto
  grande no meio da tela.
- [ ] O veredito, a faixa com os três valores e a tabela, com um valor por linha, sem nada cortado.

**Acessibilidade**

- [ ] VoiceOver, nos campos: "Obra, Casa Alphaville", "Se eu vender por, R$ …, botão" e "Daqui a, 6 meses", com "Um mês a
  menos" e "Um mês a mais". Nas teclas, cada toque fala o valor novo; o gesto de sair (o Z com dois dedos) as fecha.
- [ ] VoiceOver, na conta: o veredito é um elemento só, com a frase inteira; a faixa é uma imagem com os três valores; cada
  linha da tabela fala o nome e os dois valores.
- [ ] Controle por Voz ("Mostrar nomes"): "Tocar Obra", "Tocar Se eu vender por", "Tocar Um mês a mais" e "Tocar OK".
- [ ] No escuro e no claro, nos vidros Transparente e Fosco: as três marcas da faixa se distinguem do trilho, e o "OK" das
  teclas se lê. A parte hachurada começa um pouco depois do tracejado e abre uma fenda onde passa a venda (decisão de
  24/11): diga se a venda ainda se lê como "dentro" da parte hachurada. Com Reduzir transparência, os blocos e as teclas
  ficam sólidos.
- [ ] Com Aumentar contraste, a aba inteira continua legível, e os blocos verde e âmbar não mudam de cor.

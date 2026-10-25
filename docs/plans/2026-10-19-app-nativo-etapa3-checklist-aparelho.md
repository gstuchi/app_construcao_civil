# App nativo, etapa 3: checklist no iPhone

O Giovani roda no iPhone, pelo TestFlight, a cada build da etapa 3 (um por PR do app), **na conta de sempre**. Cada item que falhar vira tarefa para o Forja, com o passo, o que apareceu e uma captura de tela. Os itens de um PR continuam valendo nos builds seguintes.

## Antes do primeiro build

O app grava na conta de sempre desde o fim da etapa 2, e cada gravação regrava o documento inteiro da conta, o orçamento também.

- [ ] No site: Ajustes → Seus dados → Exportar dados completos. Guarde o arquivo (`custta-AAAA-MM-DD.json`) fora do repositório, como cópia de segurança.
- [ ] O PR 0 do site já está publicado (o site e o app com as mesmas regras do orçamento): no site, numa obra com orçamento por tópico, abra a folha do orçamento e salve sem mudar nada; ela continua igual.

## PR 1: o orçamento

Conferido pelo Giovani no iPhone com o build 2.0 (6.1), em 23/10/2026.

**Na tela da obra**

- [x] Numa obra sem orçamento, em construção ou pronta: "Definir orçamento" aparece depois das ações da fase, numa pílula de vidro. Numa obra vendida sem orçamento, não aparece (como no site).
- [x] "Definir orçamento": a folha "Orçamento da obra" abre em "Só o total", com as teclas já abertas embaixo, o "Salvar" apagado até ter valor e sem "Tirar orçamento". Digite um total e salve: a folha desce e a linha do orçamento aparece logo abaixo do Total gasto, com o nível ("dentro do previsto", "perto do limite" ou "passou do previsto"), quanto sobra ou passou, a barra e "N% usado de R$ …". No site, o mesmo orçamento.
- [x] Os três níveis: mude o total pelo lápis da tela Orçamento até o uso passar de 90% e depois de 100%. Perto e passou vêm em âmbar, nunca em vermelho; no "passou", a barra para no previsto, com uma fresta, e o excesso vem listrado.
- [x] Com orçamento por tópico: a linha traz o pior aviso dos tópicos ("N tópicos passaram do previsto" ou "N perto do limite") em âmbar, com o triângulo, e o que está fora do orçamento.
- [x] Obra vendida com orçamento: a linha continua, como o orçamento fechou; o lápis da tela Orçamento edita e tira (como no site).

**A tela Orçamento**

- [x] Toque na linha do orçamento: a tela Orçamento abre, com o título grande e o lápis na barra. Volte pelo círculo do topo e, de novo, arrastando da borda esquerda.
- [x] O cartão: "Orçamento por tópico" ou "Orçamento total", o nível, o gasto, "de R$ … previstos em N tópicos" (no modo por tópico), a barra, "N% usado" e quanto sobra ou passou. Com gasto fora do orçamento, a frase "Os R$ … fora do orçamento não entram nesta conta.". Os números são os do site.
- [x] "Por tópico": os tópicos na ordem do site (quem passou do previsto primeiro), cada um com o gasto, "/ previsto", a barra fina e a frase do site ("Passou R$ 6,2 mil do previsto", "Faltam R$ 3,3 mil — 96%", "Chegou ao previsto — 100%"); o "Passou…" em âmbar. Um nome comprido quebra, e o valor fica numa linha só.
- [x] "Fora do orçamento": o total, "Tópico sem valor não entra na comparação." e uma linha por tópico fora, do maior gasto para o menor.
- [x] No modo total: "Gasto por tópico" (o bruto e a parte da obra de cada tópico) e, no fim, "Para comparar tópico a tópico, toque no lápis e escolha "Por tópico"."
- [x] Neste build, as linhas de tópico não têm seta e não abrem nada: o detalhe do tópico chega no PR 2.
- [x] O + na tela Orçamento lança gasto na obra dela; ao salvar, a tela Orçamento mostra os números novos e continua aberta.
- [x] Apague a obra no site com a tela Orçamento aberta no iPhone: o app volta para a lista de Obras.

**A folha "Orçamento da obra"**

- [x] Pelo lápis da tela Orçamento, a folha abre no modo salvo. "Por tópico" mostra os 21 tópicos fixos e depois os seus, e o total ao vivo ("R$ … · N de M tópicos com valor").
- [x] Toque numa linha: as teclas abrem embaixo da folha, com a barra "‹ › Elétrica · 9 de N Pronto"; a linha acende, com o cursor piscando. ‹ e › andam pelas linhas sem fechar as teclas e, nas pontas, não fazem nada; "Pronto" fecha.
- [x] Sem Reduzir movimento, com as teclas fechadas, toque numa linha de baixo (Hidráulica): as teclas abrem e a linha desliza uma vez até o meio, entre o alto da lista e as teclas, inteira, sem pulo e sem passar por baixo delas; com Reduzir movimento, ela já aparece no meio, sem deslizar.
- [x] A cada ›, até o último tópico, a linha ativa aparece inteira entre o alto da lista e as teclas.
- [x] Teto: depois de R$ 99.999.999,99, a tecla é ignorada (o site não tem teto).
- [x] Com o total vazio, troque para "Só o total": ele vem com a soma dos tópicos e a frase "Preenchido com a soma dos tópicos.". Trocar de modo não grava: feche pelo × e aparece "Você mudou este orçamento." ("Descartar alterações" / "Continuar editando"). No "Definir", fechar depois de digitar pergunta "Você já preencheu este orçamento." ("Descartar orçamento"). Puxar a folha para baixo pergunta igual.
- [x] No modo total, o rodapé diz "Comparado com o Total gasto (bruto), com as parcelas a vencer."
- [x] "Tirar orçamento" pergunta "Tirar o orçamento desta obra?" / "Os gastos continuam como estão."; "Cancelar" não muda nada; "Tirar orçamento" tira: a folha desce já na obra (a tela Orçamento voltou por trás), a linha some e "Definir orçamento" volta. No site também.
- [x] Apague todos os valores e toque em "Salvar": a mesma pergunta do "Tirar orçamento" (no site, tira sem perguntar).
- [x] Toque duas vezes seguidas, rápido, no "Salvar": o orçamento grava uma vez (no site, igual).
- [x] Modo avião com os dados já vistos: defina um orçamento; a pílula mostra "Sem conexão"; ao voltar a internet, o site mostra o orçamento.
- [x] Modo avião logo depois de instalar (antes de o app ver os dados): o "Salvar" avisa dentro da folha, com "O orçamento continua aqui; nada foi salvo ainda.", e a folha não fecha.
- [x] Com a folha aberta no iPhone, mude o orçamento no site: a folha não muda; ao salvar, vale o que está na folha. O que a folha não mostra (um tópico próprio apagado com valor no orçamento) continua no site.
- [x] Teclado físico (se tiver um teclado Bluetooth): com as teclas abertas, os dígitos e o apagar entram na linha ativa.

**Texto Maior no máximo** (Ajustes do iPhone → Acessibilidade → Tela e Tamanho do Texto → Texto Maior)

- [x] Na linha do orçamento e na tela Orçamento, o dinheiro de dentro das frases vai para a própria linha e encolhe para caber; o chip do nível quebra em duas linhas; nos tópicos, cada informação fica numa linha, sem o ícone.
- [x] Na folha, o segmentado e o total rolam com a lista; as teclas param de crescer num ponto; com as teclas abertas, o "Salvar" sai e a barra fica sem o nome; "Pronto" fecha e o "Salvar" volta. No "Só o total", a barra aparece só com o "Pronto".
- [x] O cabeçalho do "A vencer" empilha título, valor e linha de baixo, e o valor encolhe para caber (a correção do mockup da etapa 2, que o app já fazia).

**Acessibilidade**

- [x] VoiceOver, na obra: a linha do orçamento é um elemento só, que lê o nível, quanto sobra ou passou, quanto foi usado e o aviso dos tópicos; dois toques abrem a tela Orçamento.
- [x] VoiceOver, na tela Orçamento: o cartão e cada linha de tópico são lidos inteiros, um elemento cada, sem "botão" nas linhas de tópico.
- [x] VoiceOver, na folha: dois toques numa linha abrem as teclas nela; ouve-se "Elétrica, 9 de N, R$ …" e o foco vai para a linha ativa. No rotor da linha ativa, as ações "Tópico anterior", "Próximo tópico" e "Pronto". Cada tecla fala o valor novo. Diga o que o VoiceOver fala a cada tecla e a cada troca de tópico, e se alguma coisa sobra ou falta.
- [x] VoiceOver, gesto de escape (Z com dois dedos): com as teclas abertas, fecha as teclas; sem elas, faz o mesmo que o ×. Ao trocar para "Só o total" com o total vazio, ouve-se "Preenchido com a soma dos tópicos.".
- [x] Controle por Voz ("Mostrar nomes"): na obra, "Tocar Definir orçamento" abre a folha e "Tocar Orçamento" abre a tela Orçamento; nela, "Tocar Editar orçamento" abre a folha; na folha, o nome de cada linha de tópico abre as teclas nela, e "Tocar Próximo tópico", "Tocar Tópico anterior", "Tocar Pronto" e "Tocar Salvar" funcionam.
- [x] Controle Assistivo (varredura por item): na folha, a varredura passa pelas linhas, pela barra (‹, ›, Pronto), pelas teclas e pelo "Salvar"; dá para definir um orçamento por tópico e salvar só pela varredura.
- [x] No escuro e no claro, o aviso dos tópicos e o "Passou … do previsto" em âmbar se leem sobre o vidro (no claro, um âmbar mais escuro, `#6F4705`).
- [x] Nas telas de entrar e criar conta, no escuro: o texto secundário ficou um pouco mais claro (a decisão 6 da parte 2). Diga se incomoda.

## Aparência em Ajustes: o tema e o vidro

Adiantada da etapa 5 (23/10), para comparar as duas doses do vidro no iPhone. Vale só neste aparelho: o site não muda.

- [ ] Ajustes: o painel "Aparência" fica acima da Conta, com "Tema" e o segmentado "Escuro | Claro", e embaixo "Vidro", com os dois cartões (Transparente, o padrão, com o anel e o círculo marcado) e a nota.
- [ ] Toque em "Claro": o app inteiro troca na hora. Feche o app (deslize para cima na troca de apps) e abra de novo: continua claro. Volte ao Escuro.
- [ ] Toque em "Fosco": os cartões e os painéis ficam mais firmes na hora, e o "N obras" de Obras deixa a pílula e vira texto solto. Feche e abra o app: continua no Fosco.
- [ ] Compare as duas doses no escuro e no claro, em Obras, na obra, na tela Orçamento, nas folhas e em Ajustes, e diga qual fica (ou se as duas ficam como escolha).
- [ ] Com "Aumentar contraste" ligado no iPhone (Acessibilidade → Tela e Tamanho do Texto): o aviso "Com "Aumentar contraste" ligado no iPhone, o Custta usa o vidro fosco com contorno." no lugar da nota, e o vidro fosco com contorno nas duas escolhas.
- [ ] Com "Reduzir transparência" ligado: o aviso "O iPhone está com "Reduzir transparência" ligado. Enquanto isso, o Custta usa cartões sólidos.", as miniaturas e os círculos esmaecidos, e os cartões do vidro não respondem ao toque. Desligue: a escolha de antes volta.
- [ ] Texto Maior no máximo: o segmentado do tema desce para baixo de "Tema"; os dois cartões do vidro ficam um embaixo do outro, com o círculo em cima do nome; nada corta.
- [ ] VoiceOver: "Tema", depois "Escuro, selecionado, 1 de 2" e "Claro, 2 de 2"; no vidro, "Transparente, selecionado, 1 de 2" e "Fosco, 2 de 2", cada um um botão; dois toques trocam.

## PR 2: o A pagar e o detalhe do tópico

**Do PR 1, neste build** (cinco itens do PR 1 que o PR 2 muda; valem para o build do PR 2, e os que tiram dado rodam numa obra de teste)

- [ ] No build do PR 1, as linhas de tópico não têm seta e não abrem nada (o detalhe do tópico chega no PR 2). Do PR 2 em diante, só a do tópico previsto e ainda sem gasto fica sem seta e sem toque; as outras abrem o detalhe (os itens do PR 2).
- [ ] Numa obra de teste, criada no app com um orçamento (spec, "Conta": nunca numa obra de verdade), abra a tela Orçamento e apague a obra no site: o app volta para a lista de Obras.
- [ ] Numa obra de teste com orçamento, criada no app (spec, "Conta"): "Tirar orçamento" pergunta "Tirar o orçamento desta obra?" / "Os gastos continuam como estão."; "Cancelar" não muda nada; "Tirar orçamento" tira: a folha desce já na obra (a tela Orçamento voltou por trás), a linha some e "Definir orçamento" volta. No site também.
- [ ] Na mesma obra de teste, defina de novo o orçamento, apague todos os valores e toque em "Salvar": a mesma pergunta do "Tirar orçamento" (no site, tira sem perguntar). Depois, apague a obra de teste.
- [ ] VoiceOver, na tela Orçamento: o cartão e cada linha de tópico são lidos inteiros, um elemento cada. No build do PR 1, sem "botão" nas linhas de tópico; do PR 2 em diante, só a do tópico previsto e ainda sem gasto fica sem "botão", e dois toques numa linha com "botão" abrem o detalhe do tópico.

**O A pagar** (numa obra com vencimentos nos próximos 30 dias; nada aqui grava)

- [ ] Na obra, o indicador "A pagar · 30 dias" tem a seta à direita e "Parcelas e gastos futuros" embaixo. Toque em qualquer ponto da linha: a folha "A pagar · 30 dias" sobe, com o nome da obra embaixo do título e o × à esquerda. O × fecha a folha; puxá-la para baixo também.
- [ ] A folha: no alto, num grupo, o total e "N vencimentos · a partir de amanhã", os mesmos do indicador; depois, os vencimentos por mês, cada mês com o nome e o total, nas linhas de gasto da lista da obra; no fim, se há gasto a vencer depois dos 30 dias, "Depois de DD/MM/AA, mais N gastos a vencer (R$ …), no "A vencer" da obra.". No site, na mesma obra, o "A pagar" tem o mesmo total e os mesmos vencimentos. O cartão "A vencer" da lista da obra não muda e continua com todos os gastos futuros.
- [ ] Role a folha até o fim e toque num vencimento: a edição entra pela direita, na mesma folha, com "Editar gasto", "A pagar" embaixo e o voltar (‹) no lugar do ×. Volte sem mudar nada, pelo ‹ e, de novo, arrastando da borda esquerda: a folha volta na mesma rolagem, sem pular para o topo.
- [ ] Mude a descrição e não salve: o ‹ pergunta "Você mudou este gasto." / "As mudanças ainda não foram salvas." ("Descartar mudanças" / "Continuar editando"). "Continuar editando" fica na edição, com a mudança; "Descartar mudanças" volta para a folha sem gravar (no site, nada mudou). Arrastar da borda esquerda pergunta igual.
- [ ] Puxe a folha para baixo com a edição aberta: sem mudança, a folha inteira desce; com mudança, ela não desce e pergunta o mesmo, e "Descartar mudanças" fecha a folha sem gravar.

**O detalhe do tópico** (numa obra com orçamento por tópico; nada aqui grava)

- [ ] Na tela Orçamento, no "Por tópico", a linha de um tópico com gasto tem a seta à direita, e tocar em qualquer ponto dela abre a folha do tópico; a de um tópico previsto e ainda sem gasto fica sem seta, e o toque não abre nada. No "Fora do orçamento", cada linha tem a seta e abre a folha do tópico. (O "Gasto por tópico" do modo total vem na obra de teste, no grupo seguinte.)
- [ ] A folha do tópico: o nome do tópico no título, o nome da obra embaixo e o × à esquerda. No alto, num grupo: o ícone e "N gastos · N% da obra" ("1 gasto" quando é um só), o valor e "corrigido: R$ …"; embaixo de um fio, "No orçamento" e o previsto, a barra e a frase do tópico, a mesma da tela Orçamento ("Passou R$ … do previsto" em âmbar, "Faltam R$ … — N%" ou "Chegou ao previsto — 100%"), ou "N% usado" quando o tópico ainda está abaixo de 90% do previsto. Num tópico do "Fora do orçamento", no lugar disso, "Sem valor no orçamento: não entra na comparação.".
- [ ] Embaixo do grupo, "A vencer · N" (o próximo vencimento primeiro) e "Pagos · N" (o mais novo primeiro), cada um só quando há gasto nele, com as linhas da lista da obra sem o nome do tópico embaixo (um gasto sem descrição tem o nome do tópico no título, como na obra).
- [ ] Os números são os do site: no site, na mesma obra, toque no tópico no orçamento (ou na legenda dos Gráficos). "N gastos · N% da obra", o valor e o corrigido são os mesmos, e o previsto e a frase batem com os do tópico no orçamento do site (o "N% usado" é só do app); a lista do site tem os gastos do "A vencer" e do "Pagos" juntos, e os pagos na mesma ordem.
- [ ] Num tópico com muitos gastos, role até o fim e toque num gasto: a edição entra pela direita, na mesma folha, com "Editar gasto" e o nome do tópico embaixo. Volte sem mudar nada, pelo ‹ e pela borda esquerda: a folha volta na mesma rolagem. Com mudança, o ‹, a borda e o puxar perguntam, como no A pagar.

**Na obra de teste: salvar, trocar de tópico e apagar**

- [ ] Este grupo grava, troca de tópico e apaga gastos, então roda numa obra de teste, criada agora no próprio app e apagada no último item (spec, "Conta"), nunca numa obra de verdade. Os itens seguem em ordem, cada um sobre o que o anterior deixou; nos marcados "VoiceOver", o VoiceOver fica ligado ao menos no último toque (o atalho de acessibilidade liga e desliga). Na lista de Obras, + → "Nova obra", com o nome "Teste PR 2", e "Criar obra".
- [ ] Ainda sem gasto, abra o A pagar da obra de teste: "0 vencimentos · a partir de amanhã" e o cartão "Nenhum gasto previsto para esse período."; a folha não fecha sozinha.
- [ ] Lance pelo +: Piso (Cerâmica, hoje, R$ 1.000,00), Rejunte (Cerâmica, daqui a 10 dias, R$ 200,00), Argamassa (Cerâmica, daqui a 20 dias, R$ 300,00), Tinta (Pintura, hoje, R$ 300,00), Registro (Encanamento, daqui a 5 dias, R$ 150,00), Taxa (Documentação, hoje, R$ 100,00), Certidão (Documentação, hoje, R$ 80,00) e Fios (Elétrica, no cartão em 3x, R$ 900,00 sem juros, com o primeiro vencimento daqui a 10 dias). Depois, "Definir orçamento" → "Por tópico": R$ 2.000,00 em Cerâmica e R$ 1.000,00 em Alvenaria, Elétrica, Encanamento e Pintura; Documentação fica sem valor.
- [ ] O A pagar: R$ 950,00 e "4 vencimentos · a partir de amanhã" (Registro, Rejunte, Fios (1/3) e Argamassa) e, no fim, "Depois de DD/MM/AA, mais 2 gastos a vencer (R$ 600,00), no "A vencer" da obra." (a 2/3 e a 3/3 dos Fios). No site, o mesmo total e os mesmos vencimentos.
- [ ] VoiceOver: toque em Rejunte, mude a descrição para "Rejunte cinza" e salve: a folha volta na mesma rolagem, com a linha acesa por uns 2 segundos, sem a etiqueta "novo"; o foco fica nela, sem anúncio.
- [ ] VoiceOver: abra Argamassa, mude a data para daqui a 40 dias e salve: a linha sai do A pagar, o foco vai para a linha vizinha e ouve-se "O gasto saiu desta lista."; a frase do fim passa a "mais 3 gastos".
- [ ] VoiceOver: na linha de Registro, a ação "Apagar" do rotor pergunta "Apagar este gasto?" ("Registro · R$ 150,00. Não dá para desfazer."); "Apagar" tira a linha e a folha continua aberta; o foco vai para a linha vizinha e ouve-se "Gasto apagado".
- [ ] Arraste Fios (1/3) para a esquerda e toque em "Apagar": o alerta da parcela, "Fios (1/3)" / "Esta parcela faz parte de uma compra em 3x no cartão." ("Apagar só esta parcela", "Apagar a compra toda (3 parcelas)", "Cancelar"). "Cancelar" não apaga nada; arraste de novo e escolha "Apagar só esta parcela": só a 1/3 sai, ainda aberta, com o "Apagar" à vista, e a folha continua aberta.
- [ ] VoiceOver: abra Rejunte cinza, toque em "Apagar gasto" e em "Apagar": a edição volta ao A pagar e a linha sai lá. A lista fica vazia, com "Nenhum gasto previsto para esse período." e, embaixo, a frase do fim, e a folha não fecha; o foco vai para o cartão do vazio e ouve-se "Gasto apagado".
- [ ] Na tela Orçamento da obra de teste, no "Por tópico": Cerâmica, Elétrica e Pintura com a seta; Alvenaria e Encanamento (previstos, sem gasto) sem seta e sem toque. No "Fora do orçamento", Documentação com a seta, e a folha dela mostra "Sem valor no orçamento: não entra na comparação.".
- [ ] Abra Cerâmica: "2 gastos · N% da obra", "A vencer · 1" (Argamassa) e "Pagos · 1" (Piso). Toque em Piso, mude o valor para R$ 1.500,00 e salve: a folha volta na mesma rolagem, com a linha acesa e o valor, o corrigido e a frase do orçamento novos. Feche a folha: a linha da Cerâmica na tela Orçamento também mudou.
- [ ] VoiceOver: na Cerâmica, abra Argamassa, troque o tópico para Pintura e salve: a linha sai do detalhe, o foco vai para Piso e ouve-se "O gasto saiu desta lista."; o resumo passa a "1 gasto".
- [ ] VoiceOver: abra Piso, troque o tópico para Pintura e salve: era o último gasto da Cerâmica, e a folha desce, sem o "O gasto saiu desta lista.". Diga para onde vai o foco depois da descida. Na tela Orçamento, a Cerâmica fica sem seta.
- [ ] Abra Elétrica ("A vencer · 2": Fios (2/3) e Fios (3/3)) e, em Fios (2/3), toque em "Apagar gasto": o alerta da parcela, agora com "Apagar a compra toda (2 parcelas)". "Apagar só esta parcela" volta ao detalhe, a linha sai lá e o resumo passa a "1 gasto".
- [ ] VoiceOver: na linha de Fios (3/3), a ação "Apagar" do rotor e "Apagar só esta parcela": era o último gasto da Elétrica, e a folha desce; ouve-se "Gasto apagado". Diga para onde vai o foco depois da descida.
- [ ] Com a Pintura aberta no iPhone ("3 gastos": Tinta, Argamassa e Piso), mude no site o valor de Tinta: o detalhe no iPhone mostra o valor e o resumo novos, sem fechar.
- [ ] VoiceOver: no iPhone, abra a edição de Tinta e, com ela aberta, apague Tinta no site: a edição volta ao detalhe e a linha sai; o foco vai para a linha vizinha e ouve-se "Gasto apagado".
- [ ] Arraste Argamassa e toque em "Apagar": "Apagar este gasto?" ("Argamassa · R$ 300,00. Não dá para desfazer."); "Apagar" tira a linha, e a folha continua aberta, com "1 gasto" e os números novos.
- [ ] Com a Pintura aberta no iPhone (só Piso), troque no site o tópico de Piso para Cerâmica: a folha desce no iPhone.
- [ ] Abra Documentação, no "Fora do orçamento", e toque em Certidão, em "Apagar gasto" e em "Apagar": a edição volta ao detalhe, a linha sai lá e o resumo passa a "1 gasto".
- [ ] O modo total: pelo lápis da tela Orçamento, "Só o total" (vem com a soma dos tópicos) e "Salvar". No lugar do "Por tópico", o "Gasto por tópico", com Cerâmica e Documentação: cada linha tem a seta e abre a folha do tópico, sem a linha do orçamento.
- [ ] Por último, com a folha da Documentação aberta no iPhone, apague a obra de teste no site: a folha fecha e o app volta para a lista de Obras, sem ela. Se algo falhar, apague-a no app (lápis da obra, "Apagar obra").

**Texto Maior no máximo**

- [ ] Na obra, a seta do A pagar e, na tela Orçamento, a das linhas de tópico param de crescer num ponto e ficam numa coluna à direita, no meio da altura da linha; a linha do tópico previsto sem gasto deixa essa coluna vazia.
- [ ] No A pagar: o total do resumo fica numa linha só e encolhe para caber; em cada mês, o total desce para baixo do nome quando não cabe ao lado; numa obra sem vencimentos nos 30 dias, o cartão do vazio fica sem o ícone.
- [ ] No detalhe do tópico: o resumo fica sem o ícone; o valor fica numa linha só e encolhe para caber; o dinheiro do "corrigido:" vai para a própria linha; o previsto desce para baixo de "No orçamento" quando não cabe ao lado; "A vencer · N" e "Pagos · N" chegam mais perto da borda.
- [ ] No topo do A pagar e do detalhe, nada aparece cortado, nem o cabeçalho de cada mês nem a linha "No orçamento": nesses dois pontos a auditoria da CI não acha o corte (um ponto cego dela), e só o aparelho prova.

**Acessibilidade**

- [ ] VoiceOver, na obra: o indicador "A pagar · 30 dias" é um elemento só, lido inteiro e com "botão"; dois toques abrem a folha.
- [ ] VoiceOver, nas duas folhas: o resumo é um elemento só e, no detalhe, a linha do orçamento também; os meses do A pagar e o "A vencer · N" e o "Pagos · N" do detalhe são cabeçalhos; cada linha de gasto é um botão (dois toques abrem a edição) com a ação "Apagar" no rotor; no detalhe, a linha não lê o nome do tópico (o título da folha já o diz).
- [ ] VoiceOver, a volta sem salvar, pelo ‹ ou por "Descartar mudanças": o foco volta para a linha que abriu a edição.
- [ ] VoiceOver, gesto de escape (Z com dois dedos), nas duas folhas: na lista, faz o mesmo que o × (a folha desce); na edição sem mudança, volta para a lista, com o foco na linha que a abriu; com mudança, pergunta "Você mudou este gasto." ("Descartar mudanças" volta, "Continuar editando" fica); num passo de dentro da edição (o valor ou o tópico), volta para a edição.
- [ ] Controle por Voz ("Mostrar nomes"), nas duas folhas: cada linha de gasto mostra o título dela, e "Tocar" com ele abre a edição; "Tocar Fechar" fecha a folha; na edição com mudança, "Tocar Voltar" e "Tocar" com o nome da folha ("Tocar A pagar", "Tocar Cerâmica") perguntam "Você mudou este gasto.".
- [ ] Controle por Voz ("Mostrar nomes"), nas entradas: na obra, o indicador "A pagar · 30 dias" mostra "A pagar", e "Tocar A pagar" abre a folha; na tela Orçamento, cada linha de tópico que abre o detalhe mostra o nome do tópico, e "Tocar" com ele ("Tocar Cerâmica") abre a folha do tópico (a linha do orçamento, na obra, segue com "Orçamento"). Diga se algum nome não aparece ou não abre a folha.
- [ ] Controle Assistivo (varredura por item), nas duas folhas: a varredura passa pelo × e pelas linhas de gasto; selecionar uma linha abre a edição, e o "Apagar" dela aparece entre as ações; dá para abrir a edição e voltar só pela varredura.
- [ ] No escuro e no claro, e com Aumentar contraste, o "Passou R$ … do previsto" do detalhe (em âmbar, dentro da folha) e os textos secundários das duas folhas se leem.

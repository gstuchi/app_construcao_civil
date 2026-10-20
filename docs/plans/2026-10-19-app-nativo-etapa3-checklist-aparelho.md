# App nativo, etapa 3: checklist no iPhone

O Giovani roda no iPhone, pelo TestFlight, a cada build da etapa 3 (um por PR do app), **na conta de sempre**. Cada item que falhar vira tarefa para o Forja, com o passo, o que apareceu e uma captura de tela. Os itens de um PR continuam valendo nos builds seguintes.

## Antes do primeiro build

O app grava na conta de sempre desde o fim da etapa 2, e cada gravação regrava o documento inteiro da conta, o orçamento também.

- [ ] No site: Ajustes → Seus dados → Exportar dados completos. Guarde o arquivo (`custta-AAAA-MM-DD.json`) fora do repositório, como cópia de segurança.
- [ ] O PR 0 do site já está publicado (o site e o app com as mesmas regras do orçamento): no site, numa obra com orçamento por tópico, abra a folha do orçamento e salve sem mudar nada; ela continua igual.

## PR 1: o orçamento

**Na tela da obra**

- [ ] Numa obra sem orçamento, em construção ou pronta: "Definir orçamento" aparece depois das ações da fase, numa pílula de vidro. Numa obra vendida sem orçamento, não aparece (como no site).
- [ ] "Definir orçamento": a folha "Orçamento da obra" abre em "Só o total", com as teclas já abertas embaixo, o "Salvar" apagado até ter valor e sem "Tirar orçamento". Digite um total e salve: a folha desce e a linha do orçamento aparece logo abaixo do Total gasto, com o nível ("dentro do previsto", "perto do limite" ou "passou do previsto"), quanto sobra ou passou, a barra e "N% usado de R$ …". No site, o mesmo orçamento.
- [ ] Os três níveis: mude o total pelo lápis da tela Orçamento até o uso passar de 90% e depois de 100%. Perto e passou vêm em âmbar, nunca em vermelho; no "passou", a barra para no previsto, com uma fresta, e o excesso vem listrado.
- [ ] Com orçamento por tópico: a linha traz o pior aviso dos tópicos ("N tópicos passaram do previsto" ou "N perto do limite") em âmbar, com o triângulo, e o que está fora do orçamento.
- [ ] Obra vendida com orçamento: a linha continua, como o orçamento fechou; o lápis da tela Orçamento edita e tira (como no site).

**A tela Orçamento**

- [ ] Toque na linha do orçamento: a tela Orçamento abre, com o título grande e o lápis na barra. Volte pelo círculo do topo e, de novo, arrastando da borda esquerda.
- [ ] O cartão: "Orçamento por tópico" ou "Orçamento total", o nível, o gasto, "de R$ … previstos em N tópicos" (no modo por tópico), a barra, "N% usado" e quanto sobra ou passou. Com gasto fora do orçamento, a frase "Os R$ … fora do orçamento não entram nesta conta.". Os números são os do site.
- [ ] "Por tópico": os tópicos na ordem do site (quem passou do previsto primeiro), cada um com o gasto, "/ previsto", a barra fina e a frase do site ("Passou R$ 6,2 mil do previsto", "Faltam R$ 3,3 mil — 96%", "Chegou ao previsto — 100%"); o "Passou…" em âmbar. Um nome comprido quebra, e o valor fica numa linha só.
- [ ] "Fora do orçamento": o total, "Tópico sem valor não entra na comparação." e uma linha por tópico fora, do maior gasto para o menor.
- [ ] No modo total: "Gasto por tópico" (o bruto e a parte da obra de cada tópico) e, no fim, "Para comparar tópico a tópico, toque no lápis e escolha "Por tópico"."
- [ ] Neste build, as linhas de tópico não têm seta e não abrem nada: o detalhe do tópico chega no PR 2.
- [ ] O + na tela Orçamento lança gasto na obra dela; ao salvar, a tela Orçamento mostra os números novos e continua aberta.
- [ ] Apague a obra no site com a tela Orçamento aberta no iPhone: o app volta para a lista de Obras.

**A folha "Orçamento da obra"**

- [ ] Pelo lápis da tela Orçamento, a folha abre no modo salvo. "Por tópico" mostra os 21 tópicos fixos e depois os seus, e o total ao vivo ("R$ … · N de M tópicos com valor").
- [ ] Toque numa linha: as teclas abrem embaixo da folha, com a barra "‹ › Elétrica · 9 de N Pronto"; a linha acende, com o cursor piscando. ‹ e › andam pelas linhas sem fechar as teclas e, nas pontas, não fazem nada; "Pronto" fecha.
- [ ] Sem Reduzir movimento, com as teclas fechadas, toque numa linha de baixo (Hidráulica): as teclas abrem e a linha desliza uma vez até o meio, entre o alto da lista e as teclas, inteira, sem pulo e sem passar por baixo delas; com Reduzir movimento, ela já aparece no meio, sem deslizar.
- [ ] A cada ›, até o último tópico, a linha ativa aparece inteira entre o alto da lista e as teclas.
- [ ] Teto: depois de R$ 99.999.999,99, a tecla é ignorada (o site não tem teto).
- [ ] Com o total vazio, troque para "Só o total": ele vem com a soma dos tópicos e a frase "Preenchido com a soma dos tópicos.". Trocar de modo não grava: feche pelo × e aparece "Você mudou este orçamento." ("Descartar alterações" / "Continuar editando"). No "Definir", fechar depois de digitar pergunta "Você já preencheu este orçamento." ("Descartar orçamento"). Puxar a folha para baixo pergunta igual.
- [ ] No modo total, o rodapé diz "Comparado com o Total gasto (bruto), com as parcelas a vencer."
- [ ] "Tirar orçamento" pergunta "Tirar o orçamento desta obra?" / "Os gastos continuam como estão."; "Cancelar" não muda nada; "Tirar orçamento" tira: a folha desce já na obra (a tela Orçamento voltou por trás), a linha some e "Definir orçamento" volta. No site também.
- [ ] Apague todos os valores e toque em "Salvar": a mesma pergunta do "Tirar orçamento" (no site, tira sem perguntar).
- [ ] Toque duas vezes seguidas, rápido, no "Salvar": o orçamento grava uma vez (no site, igual).
- [ ] Modo avião com os dados já vistos: defina um orçamento; a pílula mostra "Sem conexão"; ao voltar a internet, o site mostra o orçamento.
- [ ] Modo avião logo depois de instalar (antes de o app ver os dados): o "Salvar" avisa dentro da folha, com "O orçamento continua aqui; nada foi salvo ainda.", e a folha não fecha.
- [ ] Com a folha aberta no iPhone, mude o orçamento no site: a folha não muda; ao salvar, vale o que está na folha. O que a folha não mostra (um tópico próprio apagado com valor no orçamento) continua no site.
- [ ] Teclado físico (se tiver um teclado Bluetooth): com as teclas abertas, os dígitos e o apagar entram na linha ativa.

**Texto Maior no máximo** (Ajustes do iPhone → Acessibilidade → Tela e Tamanho do Texto → Texto Maior)

- [ ] Na linha do orçamento e na tela Orçamento, o dinheiro de dentro das frases vai para a própria linha e encolhe para caber; o chip do nível quebra em duas linhas; nos tópicos, cada informação fica numa linha, sem o ícone.
- [ ] Na folha, o segmentado e o total rolam com a lista; as teclas param de crescer num ponto; com as teclas abertas, o "Salvar" sai e a barra fica sem o nome; "Pronto" fecha e o "Salvar" volta. No "Só o total", a barra aparece só com o "Pronto".
- [ ] O cabeçalho do "A vencer" empilha título, valor e linha de baixo, e o valor encolhe para caber (a correção do mockup da etapa 2, que o app já fazia).

**Acessibilidade**

- [ ] VoiceOver, na obra: a linha do orçamento é um elemento só, que lê o nível, quanto sobra ou passou, quanto foi usado e o aviso dos tópicos; dois toques abrem a tela Orçamento.
- [ ] VoiceOver, na tela Orçamento: o cartão e cada linha de tópico são lidos inteiros, um elemento cada, sem "botão" nas linhas de tópico.
- [ ] VoiceOver, na folha: dois toques numa linha abrem as teclas nela; ouve-se "Elétrica, 9 de N, R$ …" e o foco vai para a linha ativa. No rotor da linha ativa, as ações "Tópico anterior", "Próximo tópico" e "Pronto". Cada tecla fala o valor novo. Diga o que o VoiceOver fala a cada tecla e a cada troca de tópico, e se alguma coisa sobra ou falta.
- [ ] VoiceOver, gesto de escape (Z com dois dedos): com as teclas abertas, fecha as teclas; sem elas, faz o mesmo que o ×. Ao trocar para "Só o total" com o total vazio, ouve-se "Preenchido com a soma dos tópicos.".
- [ ] Controle por Voz ("Mostrar nomes"): na obra, "Tocar Definir orçamento" abre a folha e "Tocar Orçamento" abre a tela Orçamento; nela, "Tocar Editar orçamento" abre a folha; na folha, o nome de cada linha de tópico abre as teclas nela, e "Tocar Próximo tópico", "Tocar Tópico anterior", "Tocar Pronto" e "Tocar Salvar" funcionam.
- [ ] Controle Assistivo (varredura por item): na folha, a varredura passa pelas linhas, pela barra (‹, ›, Pronto), pelas teclas e pelo "Salvar"; dá para definir um orçamento por tópico e salvar só pela varredura.
- [ ] No escuro e no claro, o aviso dos tópicos e o "Passou … do previsto" em âmbar se leem sobre o vidro (no claro, um âmbar mais escuro, `#6F4705`).
- [ ] Nas telas de entrar e criar conta, no escuro: o texto secundário ficou um pouco mais claro (a decisão 6 da parte 2). Diga se incomoda.

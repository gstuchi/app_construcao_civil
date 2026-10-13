# App nativo, etapa 2: checklist no iPhone

O Giovani roda no iPhone, pelo TestFlight, a cada build da etapa 2 (um por PR do app), **na conta de teste**. Cada item que falhar vira tarefa para o Forja, com o passo, o que apareceu e uma captura de tela. Os itens de um PR continuam valendo nos builds seguintes.

## Antes do primeiro build: a conta de teste

O app grava de verdade a partir desta etapa, e cada gravação regrava o documento inteiro da conta. Até a conferência do PR 3 passar, ele grava numa conta separada, com uma cópia das obras.

- [ ] No site, na conta de sempre: Ajustes → Seus dados → Exportar dados completos. Guarde o arquivo (`custta-AAAA-MM-DD.json`) fora do repositório.
- [ ] Escolha o e-mail da conta de teste com `custta-teste` nele (um apelido do Gmail serve, como `seu.nome+custta-teste@gmail.com`) e uma senha forte. Até o fim do PR 3, o build do TestFlight só grava em conta assim; na conta de sempre ele mostra os dados e recusa lançar.
- [ ] Com a conta de serviço do Firebase na máquina (`FIREBASE_SERVICE_ACCOUNT`, a mesma do cron de push), rode na raiz do repositório. A senha entra pelo `read -s`, para não ficar no histórico do terminal:
  `read -s CONTA_DEMO_SENHA && export CONTA_DEMO_SENHA`
  `node scripts/conta-demo.mjs --producao --email <e-mail de teste> --importar <caminho do JSON>`
  Saída esperada: a conta criada (ou repovoada) com o número de obras do arquivo.
- [ ] No site, entre com a conta de teste: as obras e os totais são os da conta de sempre.
- [ ] No iPhone, instale o build pelo TestFlight e entre com a conta de teste (Ajustes → Sair da conta, se já estiver na outra).

## PR 1: a tela da obra (só leitura)

- [ ] Toque numa obra da lista: a tela da obra abre, com o nome no título grande, a pílula da fase e do tempo ("começou em … · N meses") e os indicadores. Total gasto, Corrigido pelo banco, A pagar e Venda têm os mesmos números da obra no site.
- [ ] Volte pelo círculo do topo e, de novo, arrastando da borda esquerda da tela.
- [ ] Com uma obra aberta, vá a Ajustes e volte a Obras: a obra continua aberta.
- [ ] Role a obra: o nome sai do título grande e aparece pequeno na barra. Com a pílula de sincronização na barra ("Salvando…", "Sem conexão"), o nome pequeno some.
- [ ] A lista vem em cartões por mês, do mais recente, com o total de cada mês igual à soma dos gastos daquele mês no site.
- [ ] O "A vencer" aparece fechado no alto, com o total e "N gastos · o próximo é em dd/mm/aa"; um toque abre, outro fecha.
- [ ] Cada linha: o título (a descrição, ou o tópico quando não há descrição), o tópico, "Pix" ou "Cartão" escrito, a data e o valor com "−", sem vermelho; parcela com "(n/de)" no título.
- [ ] Obra sem gastos: "Nenhum gasto lançado." e "Toque no + para lançar o primeiro." (o + chega no PR 2).
- [ ] Venda sem estimativa: "Toque no lápis para informar o valor". O lápis (editar a obra) chega no PR 3; o texto já é o aprovado.
- [ ] VoiceOver: cada linha lê título, tópico, pagamento, data e valor; o "A vencer" diz se está aberto ou fechado.
- [ ] Ajustes do iPhone → Acessibilidade → Tela e Tamanho do Texto → Texto Maior, no máximo: o dinheiro fica numa linha só, encolhendo para caber; o resto quebra; cada informação da linha de gasto ocupa uma linha.
- [ ] Modo avião com o app já aberto uma vez: a obra abre do cache, com "Sem conexão" na barra.
- [ ] Leitura sobre o fundo: com o fundo animado, em claro e escuro, nada fica difícil de ler (títulos, cabeçalhos dos meses, linhas).
- [ ] Compare a lista de obras com o build anterior: os cartões ficaram um pouco mais escuros no tema escuro (o escurecimento sob o vidro subiu de 45% para 50%). Diga se incomoda.

## PR 2: o gasto

- [ ] Dentro de uma obra em construção, o + aparece ao lado da cápsula de abas; em Ajustes ele some. Na lista de obras e numa obra vendida ele ainda não aparece (chega no PR 3).
- [ ] Toque no +: a folha abre com "Valor do gasto" e o teclado de maquininha (1 2 3 em cima). Digite 1, 3, 8, 0, 0, 0: o visor mostra R$ 1.380,00; "00" acrescenta dois zeros; apagar tira o último dígito. Com o visor em zero, "Avançar" fica apagado.
- [ ] "Avançar": os detalhes, na ordem valor, tópico, pagamento, descrição e data; o tópico começa no do último gasto desta obra.
- [ ] Tópico: a lista abre dentro da folha, com "Usados nesta obra" (três) no alto e o resto em "Todos", sem repetir; escolher volta aos detalhes. O voltar pela borda esquerda funciona dentro da folha.
- [ ] Cartão: aparecem "Parcelas" (1x a 36x) e "Juros ao mês"; o resumo do site muda ao vivo ("10x de R$ … · Juros do cartão: R$ … · Total: R$ …"); a data vira "Primeiro vencimento", um mês à frente. Volte para Pix: a data volta a ser hoje.
- [ ] Descrição: ao digitar "Cimen", as sugestões do site aparecem acima do teclado, com "mesmo tópico" ou "N× usado"; tocar numa preenche.
- [ ] Data: o calendário do iPhone; data futura é aceita.
- [ ] "Salvar": a folha desce, a lista rola até o gasto novo, que acende por uns 2 s com a etiqueta "novo", e o iPhone vibra. No site, o gasto aparece igual (valor, tópico, descrição, data, pagamento).
- [ ] Lance no cartão em 10x: a lista abre o "A vencer" e mostra a 1ª parcela; no site, as 10 parcelas e os juros batem.
- [ ] Lance de novo um gasto igual (mesma descrição, valor e data): aparece o aviso do site e o botão "Salvar mesmo assim" em âmbar; um segundo toque salva.
- [ ] Feche pelo × depois de passar do valor: aparece "Você já preencheu este gasto." ("Descartar gasto" / "Continuar editando"). Puxar a folha para baixo pergunta igual. No valor ainda, fecha direto.
- [ ] Toque num gasto: "Editar gasto" abre direto nos detalhes; o valor abre o mesmo teclado ("Pronto"); "Salvar" troca no site também.
- [ ] Toque numa parcela: aparece o aviso "Parcela n/de de uma compra no cartão — a edição vale só pra esta parcela." e, com juros, as condições originais da compra.
- [ ] Arraste um gasto para a esquerda: aparece o "Apagar" vermelho; tocar pergunta com o nome e o valor; "Apagar" tira a linha com animação, e o total do mês e os indicadores mudam juntos. Tocar fora ou rolar fecha a linha sem apagar.
- [ ] Arraste uma parcela e toque em "Apagar": o alerta oferece "Apagar só esta parcela" e "Apagar a compra toda (N parcelas)"; a compra toda sai de uma vez, também no site.
- [ ] "Apagar gasto" no fim da folha de edição: a folha desce e a linha sai.
- [ ] O voltar pela borda esquerda continua voltando para a lista de obras, mesmo com as linhas que arrastam.
- [ ] VoiceOver: o visor do valor lê o valor a cada tecla; dois toques numa linha de gasto abrem a edição; a linha tem a ação "Apagar" no rotor; depois de apagar, o foco vai para a linha vizinha e ouve-se "Gasto apagado".
- [ ] Texto Maior no máximo: as teclas param de crescer num ponto; na folha, o rótulo vai em cima do valor e Pix/Cartão empilham.
- [ ] iPhone 13 mini ou SE, se tiver: com o teclado aberto na descrição, as sugestões e o "Salvar" cabem.
- [ ] Modo avião: lance um gasto; a pílula mostra "Sem conexão"; ao voltar a internet, o gasto chega ao site.
- [ ] Na conta de sempre (sem `custta-teste` no e-mail), tente lançar: aparece "Este build ainda não grava na sua conta" e nada muda no site.

## PR 3: a obra, as fases e os estados

- [ ] Na lista de obras, o + aparece ao lado da cápsula: "Nova obra" abre a folha com o nome, "Começou em", a área, o valor estimado e o orçamento, nessa ordem; o teclado sobe junto com a folha, já no nome.
- [ ] Salve sem área: "Informe área construída maior que zero." em vermelho embaixo do campo; sem nome, a folha volta ao nome, sem mensagem.
- [ ] Toque em "Valor estimado de venda": o teclado de valor abre ("Opcional" na linha; zero apaga o valor). O mesmo no orçamento.
- [ ] Crie uma obra com área 3,125: a folha desce e a obra abre na tela dela; no site, a área é 3,125 m² (não 3.125).
- [ ] Toque no lápis da barra: "Editar obra" vem preenchida (a área com vírgula) e com "Apagar obra" no fim; mude o nome e salve: muda no site também.
- [ ] Feche a edição depois de mudar algo: "Você mudou esta obra." ("Descartar alterações" / "Continuar editando"); sem mudar nada, fecha direto.
- [ ] "Apagar obra": a pergunta traz o nome e "Os N lançamentos dela serão perdidos. Não dá para desfazer."; "Apagar" volta à lista, a linha sai com animação e a obra some do site.
- [ ] Numa obra em construção, "Marcar como pronta" (pílula sólida) troca a etiqueta para "Pronta · à venda" na hora, com uma vibração leve e sem perguntar; "Voltar pra construção" (pílula de vidro) desfaz. No site, a fase muda.
- [ ] Numa obra pronta, "Registrar venda": o teclado de valor, depois "Data da venda" (hoje; o calendário vai do início da obra até hoje) e "Confirmar venda". A obra vira "Vendida em dd/mm/aa" e o indicador mostra a venda com o lucro (ou o prejuízo).
- [ ] Na vendida, "Desfazer venda" pergunta "Desfazer a venda?" / "A obra volta pra “Pronta”."; confirmar volta para pronta no app e no site.
- [ ] Numa obra vendida, o + abre a folha do gasto com a linha "Obra" (vem marcada a primeira obra aberta da lista) e a nota de que a vendida não recebe gasto; troque a obra e salve: o gasto aparece na obra escolhida, que toma o lugar da vendida por trás da folha.
- [ ] Toque num gasto de uma obra vendida: a edição continua possível, sem a linha "Obra".
- [ ] Conta sem obras (apague todas as obras da conta de teste, ou use outra conta de teste): "Nenhuma obra ainda." / "Toque no + para criar a primeira obra."; o + cria.
- [ ] Modo avião logo depois de instalar (antes de o app ver os dados): o + avisa "Carregando suas obras…" em vez de abrir. O limite de 300 obras não precisa de teste no aparelho (o teste de tela cobre).
- [ ] Modo avião com os dados já vistos: marque uma obra como pronta; a pílula mostra "Sem conexão"; ao voltar a internet, o site mostra a fase nova.
- [ ] "Não salvou" (só se acontecer): o alerta "Não salvou na nuvem" aparece uma vez, com "Tentar de novo"; depois fica só a pílula, e tocar nela tenta de novo.
- [ ] Texto Maior no máximo: as pílulas das ações crescem e o texto quebra; as folhas da obra e da venda não cortam nada à esquerda; a pílula da data para de crescer num ponto.
- [ ] VoiceOver: as ações da fase são botões com o nome inteiro; a linha "Obra" lê o nome da obra escolhida; "Apagar obra" pergunta antes.
- [ ] Nos quatro combos (claro e escuro, esmeralda e azul), o lucro e o prejuízo da obra vendida sobre o vidro: verde mais claro e rosa no escuro, verde mais escuro e vinho no claro (tokens novos, medidos a 4,5:1). Diga se o tom serve.
- [ ] Na conta de sempre, tente criar uma obra ou mudar a fase: "Este build ainda não grava na sua conta" e nada muda no site.

## Depois do OK do PR 3: a conta real

- [ ] Com os itens acima marcados, o Orquestrador abre o PR da conta real (a guarda da conta de teste sai) e manda o build. Instale, entre na conta de sempre, lance um gasto de teste e apague-o; confira no site que ele entrou e saiu.

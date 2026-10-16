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
- [ ] Compare a lista de obras com o build anterior, no tema escuro: os cartões ficaram um pouco mais escuros (o escurecimento sob o vidro subiu de 45% para 50%), e o vidro da navegação (a cápsula de abas, a pílula de sincronização, o botão de sair e os avisos), que não escurecia, ganhou os mesmos 50%. Diga se incomoda.

## PR 2: o gasto

- [ ] Dentro de uma obra em construção, o + aparece ao lado da cápsula de abas; em Ajustes ele some. Na lista de obras e numa obra vendida ele ainda não aparece (chega no PR 3).
- [ ] Toque no +: a folha abre com "Valor do gasto" e o teclado de maquininha (1 2 3 em cima). Digite 1, 3, 8, 0, 0, 0: o visor mostra R$ 1.380,00; "00" acrescenta dois zeros; apagar tira o último dígito. Com o visor em zero, "Avançar" fica apagado.
- [ ] "Avançar": os detalhes, na ordem valor, tópico, pagamento, descrição e data; o tópico começa no do último gasto desta obra.
- [ ] Tópico: a lista abre dentro da folha, com "Usados nesta obra" (três) no alto e o resto em "Todos", sem repetir; escolher volta aos detalhes. O voltar pela borda esquerda funciona dentro da folha.
- [ ] Cartão: aparecem "Parcelas" (1x a 36x) e "Juros ao mês"; o resumo do site muda ao vivo ("10x de R$ … · Juros do cartão: R$ … · Total: R$ …"); a data vira "Primeiro vencimento", um mês à frente. Volte para Pix: a data volta a ser hoje.
- [ ] Descrição: ao digitar "Cimen", as sugestões do site aparecem acima do teclado, com "mesmo tópico" ou "N× usado"; tocar numa preenche.
- [ ] Data: o calendário do iPhone; data futura é aceita.
- [ ] "Salvar": a folha desce, a lista rola até o gasto novo, que acende por uns 2 s com a etiqueta "novo", e o iPhone vibra. No site, o gasto aparece igual (valor, tópico, descrição, data, pagamento).
- [ ] Toque duas vezes seguidas, rápido, no "Salvar" de um gasto sem descrição: entra um gasto só, na lista e no site; no cartão em 3x, ficam 3 parcelas, não 6.
- [ ] A etiqueta "novo", no claro e no escuro: fica colada à última palavra do título, na mesma linha dela, também numa descrição comprida que quebra; e tem a cor do tema em uso (no escuro, um tom mais claro que no claro).
- [ ] Lance no cartão em 10x: a lista abre o "A vencer" e mostra a 1ª parcela; no site, as 10 parcelas e os juros batem.
- [ ] Lance de novo um gasto igual (mesma descrição, valor e data): aparece o aviso do site e o botão "Salvar mesmo assim" em âmbar; um segundo toque salva.
- [ ] Feche pelo × depois de passar do valor: aparece "Você já preencheu este gasto." ("Descartar gasto" / "Continuar editando"). Puxar a folha para baixo pergunta igual. No valor ainda, fecha direto.
- [ ] Toque num gasto: "Editar gasto" abre direto nos detalhes; o valor abre o mesmo teclado ("Pronto"); "Salvar" troca no site também.
- [ ] Se alguma obra importada do site tiver um gasto numa forma de pagamento que o app não oferece (boleto, por exemplo), toque nele: o calendário mostra a data do gasto; escolha outra data e salve: no site, a data nova entra e a forma de pagamento continua a mesma.
- [ ] Toque numa parcela: aparece o aviso "Parcela n/de de uma compra no cartão — a edição vale só pra esta parcela." e, com juros, as condições originais da compra.
- [ ] Arraste um gasto para a esquerda: aparece o "Apagar" vermelho; tocar pergunta com o nome e o valor; "Apagar" tira a linha com animação, e o total do mês e os indicadores mudam juntos. Tocar fora ou rolar fecha a linha sem apagar.
- [ ] Arraste uma parcela e toque em "Apagar": o alerta oferece "Apagar só esta parcela" e "Apagar a compra toda (N parcelas)"; a compra toda sai de uma vez, também no site.
- [ ] Ao confirmar o "Apagar" de uma linha arrastada, ela sai da lista ainda aberta, com o "Apagar" à vista, sem fechar antes; na compra toda também.
- [ ] "Apagar gasto" no fim da folha de edição: a folha desce e a linha sai.
- [ ] O voltar pela borda esquerda continua voltando para a lista de obras, mesmo com as linhas que arrastam.
- [ ] VoiceOver: o visor do valor lê o valor a cada tecla; dois toques numa linha de gasto abrem a edição; a linha tem a ação "Apagar" no rotor; depois de apagar, o foco vai para a linha vizinha e ouve-se "Gasto apagado".
- [ ] VoiceOver, gesto de escape (Z com dois dedos): num passo de dentro da folha, volta ao anterior (do tópico aos detalhes, dos detalhes ao valor ao lançar, do valor aos detalhes ao editar); no primeiro passo, faz o mesmo que o ×.
- [ ] Texto Maior no máximo: as teclas param de crescer num ponto; na folha, o rótulo vai em cima do valor e Pix/Cartão empilham.
- [ ] Texto Maior no máximo, digite "Cimen" na descrição: cada sugestão quebra entre palavras, nunca no meio de uma, com o "mesmo tópico" ou "N× usado" embaixo do texto.
- [ ] Texto Maior no máximo, lance um gasto: ao salvar, a lista rola até ele e a linha acesa aparece inteira na tela.
- [ ] Texto Maior no máximo, lance no cartão em 10x: ao salvar, a lista rola até o "A vencer", que abre com a 1ª parcela à vista.
- [ ] iPhone 13 mini ou SE, se tiver: com o teclado aberto na descrição, as sugestões e o "Salvar" cabem.
- [ ] Modo avião: lance um gasto; a pílula mostra "Sem conexão"; ao voltar a internet, o gasto chega ao site.
- [ ] Na conta de sempre (sem `custta-teste` no e-mail), tente lançar: aparece "Este build ainda não grava na sua conta" e nada muda no site.

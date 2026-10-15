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

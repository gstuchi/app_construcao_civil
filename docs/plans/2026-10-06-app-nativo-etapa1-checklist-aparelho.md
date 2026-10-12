# App nativo, etapa 1: checklist no iPhone

O Giovani roda no iPhone, pelo TestFlight, com o build 2.0 da etapa 1. Cada item que falhar vira tarefa para o Forja, com o passo, o que apareceu e uma captura de tela.

## Antes de instalar

- [ ] O build 2.0 substitui o app de hoje no iPhone. Para voltar, abra o TestFlight, toque no Custta, "Builds anteriores" e instale o 18.1 (vale até 90 dias depois de 05/10/2026). Os dados estão na nuvem; no máximo é preciso entrar de novo.
- [ ] Tenha o site aberto no computador (custta.com.br) na mesma conta.

## Entrar

- [ ] Entrar com e-mail e senha: a lista de obras aparece.
- [ ] Ajustes > Sair da conta > Sair: volta para a tela de entrar.
- [ ] Continuar com a Apple: a folha da Apple abre, entra e mostra as obras da mesma conta de antes.
- [ ] Sair e Continuar com o Google: a tela do Google abre, entra e mostra as obras da mesma conta de antes.
- [ ] Senha errada: aparece "E-mail ou senha incorretos.".

## Conta que já existe no site

- [ ] Entrar com a conta Google que já usa no site: abre as mesmas obras do site, sem passar pelo "Falta pouco".
- [ ] Entrar com a conta Apple que já usa no site ou no app de hoje: abre as mesmas obras, sem "Falta pouco".

## Cadastro e Falta pouco

- [ ] Criar conta com um e-mail novo: o checklist da senha acompanha a digitação e a conta abre a lista (vazia) com o aviso "Confirme seu e-mail".
- [ ] Confirmar pelo link do e-mail, voltar ao app e tocar em "Já confirmei": o aviso some sem fechar o app.
- [ ] Conta Apple nova (sem cadastro no Custta): aparece "Falta pouco" pedindo só como conheceu o Custta, sem pedir o nome de novo.
- [ ] Conta Google nova: aparece "Falta pouco" com o nome já preenchido para confirmar.

## Totais iguais aos do site

- [ ] Para cada obra, o total na lista é o mesmo da lista de obras do site (os dois mostram o valor curto, como "R$ 329 mil"; com o VoiceOver ligado, o app lê o valor completo).
- [ ] Obra com orçamento: a porcentagem é a mesma do site; obra que passou do orçamento mostra "passou R$ …" igual ao site.
- [ ] A ordem é a do site: não vendidas primeiro, a mais recente em cima.

## Mudança no site chega ao iPhone

- [ ] Com o app aberto na lista, lance um gasto numa obra pelo site. Sem tocar no iPhone, o total daquela obra muda em poucos segundos.
- [ ] Apague o gasto pelo site: o total volta.

## Sem internet

- [ ] Ligue o modo avião, feche o app (arraste para cima no seletor de apps) e abra de novo: as obras estão lá e aparece "Sem conexão" no topo da lista.
- [ ] Ajustes > Sair da conta > Sair, ainda em modo avião: aparece "Conecte à internet e aguarde a sincronização antes de sair." e o app continua aberto.
- [ ] Desligue o modo avião: "Sem conexão" some sozinho.

## Finalizar saída (num iPhone com iOS 26, pelo Xcode)

O alerta "Finalizar saída" só aparece quando apagar os dados locais falha, o que no iPhone quase nunca acontece; o time o provoca com os serviços falsos, num build de Debug instalado pelo Xcode. Ele foi medido só no simulador do iOS 27.

- [ ] No Xcode, Product > Scheme > Edit Scheme > Run > Arguments > Environment Variables: `CUSTTA_SERVICOS=falsos`, `CUSTTA_CONTA=senha` e `CUSTTA_LIMPEZA=falha`. Rode no iPhone com iOS 26.
- [ ] Ajustes > Sair da conta > Sair: aparece o alerta "Finalizar saída", com um botão só, "Tentar limpar novamente".
- [ ] Toque no botão: quando o alerta fecha, a tela não clareia nem dá um degrau, e o "Limpando…" aparece no lugar dele. A primeira nova tentativa falha de propósito: o alerta volta com o texto do erro.
- [ ] Toque de novo: o escurecido sai sem aviso e a tela de entrar responde ao toque. Se a tela clarear ou der um degrau, anote para o Orquestrador: a saída é um alerta próprio, do UIKit (seção "Riscos" do plano da etapa 1B).

## Leitura confortável

- [ ] Ajustes do iPhone > Acessibilidade > Tela e Tamanho do Texto > Texto Maior, no máximo: nas telas de entrar, criar conta, obras e Ajustes nada fica cortado nem sobreposto.
- [ ] VoiceOver ligado: na lista, cada obra é lida com nome, fase, meses, total gasto e orçamento.
- [ ] O app abre escuro, sem clarão branco na abertura.

## Visual (a cara do mockup aprovado)

O app abre no escuro esmeralda, o padrão (claro e azul chegam com a Aparência, na etapa 5; o time confere os quatro combos no simulador). Compare com os prints do mockup (`~/Documents/custta-mockups/nativo/etapa1/prints-com-refracao/final-*.png`).

- [ ] Ao abrir, a aurora e o globo aparecem, o "custta." se escreve e o ponto carimba com uma vibração leve.
- [ ] Entrar, criar conta, falta pouco, obras e Ajustes batem com o mockup (cartão de vidro, campos, botões da Apple e do Google, lista em cartões, comparativo, cápsula de abas).
- [ ] Cápsula de abas: a aba escolhida é uma pílula cheia na cor da marca, com o nome legível com qualquer coisa passando por baixo; ao entrar com o teclado aberto, a cápsula aparece no lugar, sem pular.
- [ ] No escuro, o título grande de Obras e de Ajustes tem um halo leve atrás: lê-se bem sobre a aurora e não aparece mancha escura no canto. A versão, no pé de Ajustes, também se lê bem.
- [ ] Ajustes > Sair da conta: no alerta "Sair da conta?", o "Cancelar" vem na cor do texto e o "Sair" em vermelho, os dois legíveis.
- [ ] Ao entrar, a aurora escurece devagar (menos de um segundo); ao sair da conta, clareia de volta.
- [ ] Rolar a lista de obras rápido, para cima e para baixo: nada engasga, e a aurora e o globo param enquanto a lista rola.
- [ ] Borda de rolagem: com a lista rolada, os cartões passam desfocados e esmaecidos por baixo do título pequeno e do sair, e desfocados por baixo da cápsula de abas, sem faixa escura, e a aurora continua aparecendo; o título, o relógio e os nomes das abas se leem bem. Na tela de entrar, o mesmo no alto ao rolar.
- [ ] Dez minutos de uso, entrando e saindo das telas: o iPhone não esquenta.
- [ ] Ajustes do iPhone > Acessibilidade > Movimento > Reduzir movimento: a aurora e o globo ficam parados, o "custta." já aparece pronto e o título da entrada não se mexe ao rolar.
- [ ] Modo de Pouca Energia ligado: a aurora e o globo ficam parados.
- [ ] Ajustes do iPhone > Acessibilidade > Tela e Tamanho do Texto > Reduzir transparência: cartões e barras viram superfícies sólidas e legíveis; a aurora continua.
- [ ] Ajustes do iPhone > Acessibilidade > Tela e Tamanho do Texto > Aumentar contraste: o vidro fica mais firme, com contorno.
- [ ] Texto Maior no máximo: nada cortado sobre o vidro; a cápsula de abas não cresce e, segurando uma aba, aparece o nome ampliado.
- [ ] Leitura sobre o vidro, calibração: com Reduzir movimento ligado, tire um print da tela de entrar no escuro esmeralda e mande ao Orquestrador. Ele compara com o print do simulador nas áreas de vidro; se não bater, a medida do laudo de leitura (Tarefa 11) passa a ser refeita sobre os prints do aparelho.
- [ ] Leitura no sol: os cinco textos de menor margem do último laudo (o Orquestrador manda a lista) se leem bem com o sol na tela, com o brilho automático, com e sem óculos de leitura.
- [ ] Com a opção Tingido do Liquid Glass (Ajustes do iPhone > Tela e Brilho, no iOS 26.1 ou mais novo), o vidro fica mais opaco: nada some e nada fica ilegível.
- [ ] Aurora no escuro: sem faixas visíveis no degradê (a tela OLED mostra degraus que o simulador esconde).
- [ ] Vidro claro: compare a lista de obras com o app Tempo do iPhone, no claro e no escuro (o print do Tempo é pendência do Giovani, sem travar o PR 2). Se os cartões, a cápsula ou a barra ficarem mais opacos ou mais transparentes que no Tempo, ajuste as tintas do Transparente em `VidroTokens.tinta` (e, no escuro, o escurecimento sob o vidro em `VidroTokens.escurecimento`, hoje 45% no Transparente e 20% no Fosco), rode o laudo de leitura de novo e anote os números aqui.

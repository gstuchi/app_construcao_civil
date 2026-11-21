# Corte de gastos

Cloud Run function em projeto próprio (`custta-corte`), fora do app. Recebe do Pub/Sub dois orçamentos e o alerta de leituras e age sobre o projeto de produção:

- R$ 60 no orçamento do projeto, ou alerta aberto: desliga a API do Firestore. A cobrança fica.
- R$ 100 no orçamento do projeto: tira a cobrança só se a API não desligou, com falha por 6 horas.
- R$ 100 no orçamento de todos os serviços menos o Firestore: tira a cobrança.

Com `MODO_CORTE=oficial`, a receita oficial do Google para a volta às provas reprovadas, é um tempo só: R$ 60 no orçamento do projeto tira a cobrança na hora, sem tentar desligar a API, e o alerta de leituras só registra. O orçamento de fora do Firestore não muda. O padrão é `dois-tempos`; valor desconhecido dá `corte-erro` e nenhuma ação.

Com `MODO_CORTE=oficial-alerta`, a direção do conselho de 17/11, a cobrança sai primeiro: o alerta de leituras aberto e o orçamento do projeto em R$ 60, a cada mensagem, tiram a cobrança, e a função confere que `billingEnabled` caiu (até 6 leituras, 10 s entre elas). Erro na retirada, ou falta de confirmação, desliga a API de reserva, e o `corte-acao` diz que foi reserva e por quê. O orçamento de fora do Firestore segue como nos outros modos, sem reserva. `ARMADO_COBRANCA` arma a retirada, e `ARMADO_API`, só a reserva: com a cobrança desarmada, a função só registra que faria, mesmo com a API armada.

Nunca religa nada. Os dois interruptores (`ARMADO_API`, `ARMADO_COBRANCA`) começam em `false`: desarmada, a função só registra o que faria.

- `implantar.sh [--armar-api] [--armar-cobranca] [--modo-oficial | --modo-oficial-alerta]`: implanta a função; um modo só por comando.
- `religar.sh [--folga N] [--forcar "motivo"]`: volta depois de um corte; roda no Cloud Shell. Antes de tudo, a trava lê a política de leituras e só deixa religar com todas as somas abaixo da metade do limiar; quando segura, diz a hora em que solta. `--forcar` religa assim mesmo, com o motivo registrado no `estado.json`. Toda volta fica registrada e manda conferir os dados em até 7 dias, e a segunda volta no mesmo mês pede `--forcar`. Depois de um corte que tirou a cobrança, religa a API só se ela estiver desligada e manda religar a cobrança no console, em até 72 h do corte.

O roteiro de implantação e de volta está no plano da Blindagem 4, em `docs/plans/`; quanto esperar depois de um corte e quando forçar, em "Se o corte agir". Os testes ficam em `tests/corte.test.cjs`.

# Corte de gastos

Cloud Run function em projeto próprio (`custta-corte`), fora do app. Recebe do Pub/Sub dois orçamentos e o alerta de leituras e age sobre o projeto de produção:

- R$ 60 no orçamento do projeto, ou alerta aberto: desliga a API do Firestore. A cobrança fica.
- R$ 100 no orçamento do projeto: tira a cobrança só se a API não desligou, com falha por 6 horas.
- R$ 100 no orçamento de todos os serviços menos o Firestore: tira a cobrança.

Nunca religa nada. Os dois interruptores (`ARMADO_API`, `ARMADO_COBRANCA`) começam em `false`: desarmada, a função só registra o que faria.

- `implantar.sh [--armar-api] [--armar-cobranca]`: implanta a função.
- `religar.sh [--folga N]`: volta depois de um corte; roda no Cloud Shell.

O roteiro de implantação e de volta está no plano da Blindagem 4, em `docs/plans/`. Os testes ficam em `tests/corte.test.cjs`.

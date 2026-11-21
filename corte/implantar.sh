#!/usr/bin/env bash
# Implanta a função de corte no projeto próprio dela. Sem argumento sobe desarmada: só registra
# o que faria.
#
# Uso: corte/implantar.sh [--armar-api] [--armar-cobranca] [--modo-oficial | --modo-oficial-alerta]
#
# --modo-oficial é a receita oficial do Google, para a volta às provas reprovadas: um tempo só,
# tira a cobrança em R$ 60. Não arma nada: continua valendo --armar-cobranca. Sem ele, dois-tempos.
# --modo-oficial-alerta é a direção do conselho de 17/11: o alerta de leituras e o orçamento do
# projeto em R$ 60 tiram a cobrança, com a API de reserva (corte/README.md). Também não arma nada:
# --armar-cobranca arma a retirada, e --armar-api, a reserva. Um modo só por comando.
set -euo pipefail

uso(){ echo "uso: implantar.sh [--armar-api] [--armar-cobranca] [--modo-oficial | --modo-oficial-alerta]" >&2; exit 2; }

ARMADO_API=false
ARMADO_COBRANCA=false
MODO_CORTE=dois-tempos
MODO_DADO=
while [ $# -gt 0 ]; do
  case "$1" in
    --armar-api) ARMADO_API=true;;
    --armar-cobranca) ARMADO_COBRANCA=true;;
    --modo-oficial|--modo-oficial-alerta)
      [ -z "$MODO_DADO" ] || uso
      MODO_DADO="$1"
      MODO_CORTE="${1#--modo-}";;
    *) uso;;
  esac
  shift
done

PASTA="$(cd "$(dirname "$0")" && pwd)"
PROJETO_FUNCAO="${PROJETO_FUNCAO:-custta-corte}"
PROJETO_ALVO="${PROJETO_ALVO:-app-construcao-civil}"
BUCKET_ESTADO="${BUCKET_ESTADO:-custta-corte-estado}"
ORCAMENTO_PROJETO="${ORCAMENTO_PROJETO:-custta-projeto}"
ORCAMENTO_FORA_FIRESTORE="${ORCAMENTO_FORA_FIRESTORE:-custta-fora-firestore}"
POLITICA_ALERTA="${POLITICA_ALERTA:-custta-leituras}"
CONTA="custta-corte@${PROJETO_FUNCAO}.iam.gserviceaccount.com"

# timeout de 300 s: a confirmação do desligamento espera até 1 minuto, além das chamadas.
gcloud functions deploy custta-corte \
  --gen2 \
  --runtime=nodejs22 \
  --region=us-central1 \
  --source="$PASTA" \
  --entry-point=receber \
  --trigger-topic=custta-corte \
  --retry \
  --service-account="$CONTA" \
  --trigger-service-account="$CONTA" \
  --no-allow-unauthenticated \
  --timeout=300s \
  --max-instances=3 \
  --set-env-vars="ARMADO_API=$ARMADO_API,ARMADO_COBRANCA=$ARMADO_COBRANCA,MODO_CORTE=$MODO_CORTE,PROJETO_ALVO=$PROJETO_ALVO,BUCKET_ESTADO=$BUCKET_ESTADO,ORCAMENTO_PROJETO=$ORCAMENTO_PROJETO,ORCAMENTO_FORA_FIRESTORE=$ORCAMENTO_FORA_FIRESTORE,POLITICA_ALERTA=$POLITICA_ALERTA" \
  --project="$PROJETO_FUNCAO"

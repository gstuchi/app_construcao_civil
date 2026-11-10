#!/usr/bin/env bash
# Volta depois de um corte: grava a base do mês e só então religa a API do Firestore.
# Roda no Cloud Shell, sem o Mac: precisa só de gcloud e de python3 (que o Cloud Shell traz).
#
# Uso: corte/religar.sh [--folga N]     N em reais, padrão 0
#
# A função continua armada e os gatilhos valem sobre custo = costAmount - base. A folga soma à
# base do orçamento do projeto o gasto do ataque que o relatório atrasado ainda vai mostrar. O
# orçamento de fora do Firestore nunca leva folga e só ganha base nova se a cobrança foi tirada:
# sem corte, base nova subiria o teto de quem gasta fora do Firestore.
set -euo pipefail

uso(){ echo "uso: religar.sh [--folga N]" >&2; exit 2; }

FOLGA=0
while [ $# -gt 0 ]; do
  case "$1" in
    --folga) [ $# -ge 2 ] || uso; FOLGA="$2"; shift 2;;
    *) uso;;
  esac
done
case "$FOLGA" in
  ''|.|*[!0-9.]*|*.*.*) uso;;
esac

PROJETO_ALVO="${PROJETO_ALVO:-app-construcao-civil}"
BUCKET_ESTADO="${BUCKET_ESTADO:-custta-corte-estado}"
ORCAMENTO_PROJETO="${ORCAMENTO_PROJETO:-custta-projeto}"
ORCAMENTO_FORA_FIRESTORE="${ORCAMENTO_FORA_FIRESTORE:-custta-fora-firestore}"
OBJETO="gs://$BUCKET_ESTADO/estado.json"
PASTA="$(mktemp -d)"
trap 'rm -rf "$PASTA"' EXIT

# A geração vem antes do conteúdo: se o objeto mudar no meio, a gravação condicionada recusa.
# Cada comando tem o próprio || return porque set -e não vale dentro de função chamada em if.
gravar_base(){
  local geracao
  geracao="$(gcloud storage objects describe "$OBJETO" --format='value(generation)')" || return 1
  [ -n "$geracao" ] || return 1
  gcloud storage cat "$OBJETO" > "$PASTA/atual.json" || return 1
  FOLGA="$FOLGA" ORCAMENTO_PROJETO="$ORCAMENTO_PROJETO" ORCAMENTO_FORA_FIRESTORE="$ORCAMENTO_FORA_FIRESTORE" \
    python3 - "$PASTA/atual.json" "$PASTA/novo.json" "$PASTA/vale-agora.txt" <<'PY' || return 1
import json, os, sys

LIMITE_API, LIMITE_COBRANCA = 60, 100  # os de corte/regra.js, em reais

origem, destino, vale_agora = sys.argv[1:4]
folga = float(os.environ["FOLGA"])
with open(origem, encoding="utf-8") as f:
    estado = json.load(f)
orcamentos = estado.get("orcamentos") or {}

def rebasear(orcamento, acrescimo):
    orcamento["base"] = round(float(orcamento.get("maiorCusto", 0)) + acrescimo, 2)
    return orcamento["base"]

def reais(valor):
    return f"R$ {valor:.2f}".replace(".", ",")

projeto = orcamentos.get(os.environ["ORCAMENTO_PROJETO"])
base_projeto = rebasear(projeto, folga) if projeto is not None else 0
linhas = [f"API cai de novo em {reais(base_projeto + LIMITE_API)}"]
fora = orcamentos.get(os.environ["ORCAMENTO_FORA_FIRESTORE"])
if fora is not None and estado.get("cobrancaTiradaEm"):
    linhas.append(f"cobrança cai em {reais(rebasear(fora, 0) + LIMITE_COBRANCA)}")
estado["primeiraFalha"] = None
estado["apiDesligadaEm"] = None
estado["cobrancaTiradaEm"] = None
with open(destino, "w", encoding="utf-8") as f:
    json.dump(estado, f, ensure_ascii=False)
with open(vale_agora, "w", encoding="utf-8") as f:
    f.write("\n".join(linhas) + "\n")
PY
  gcloud storage cp "$PASTA/novo.json" "$OBJETO" --if-generation-match="$geracao" || return 1
}

if ! gravar_base; then
  echo "não gravou a base: tentando mais uma vez" >&2
  gravar_base || { echo "base não gravada: a API NÃO foi religada" >&2; exit 1; }
fi

gcloud services enable firestore.googleapis.com --project "$PROJETO_ALVO"
echo "API religada. Abra um aparelho por vez: o último a subir regrava o documento inteiro."
cat "$PASTA/vale-agora.txt"

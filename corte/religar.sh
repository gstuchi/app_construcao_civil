#!/usr/bin/env bash
# Volta depois de um corte: confere a trava das leituras, grava a base do mês e só então religa a
# API do Firestore. Roda no Cloud Shell, sem o Mac: precisa só de gcloud e de python3 (que o Cloud
# Shell traz).
#
# Uso: corte/religar.sh [--folga N] [--forcar "motivo"]     N em reais, padrão 0
#
# A trava lê a política do alerta de leituras no projeto alvo e, para cada condição, soma as
# leituras na janela dela mais 5 minutos, o atraso da métrica. Com alguma soma em metade do limiar
# ou mais, não religa e diz a hora em que solta: religada assim, pouca leitura nova abre o alerta e
# corta de novo. Sem conseguir ler a política ou a métrica, também não religa.
#
# --forcar religa assim mesmo, num corte falso (uso legítimo que cresceu: suba o limiar da
# política antes) ou com o Monitoring fora. O motivo é obrigatório e vai para o estado.json, na
# lista religadosForcados, com a hora, o resultado da trava (livre, segura ou nao-leu) e o que
# ela disse, na mesma gravação da base: sem base gravada, nem a API religa nem o registro fica.
#
# A função continua armada e os gatilhos valem sobre custo = costAmount - base. A folga soma à
# base o gasto do ataque que o relatório atrasado ainda vai mostrar. O orçamento de fora do
# Firestore só ganha base nova se a cobrança foi tirada, e aí com a mesma folga: sem corte, base
# nova subiria o teto de quem gasta fora do Firestore; com corte e sem folga, o custo atrasado do
# mesmo ataque tiraria a cobrança de novo assim que ela voltasse.
set -euo pipefail

uso(){ echo 'uso: religar.sh [--folga N] [--forcar "motivo"]' >&2; exit 2; }

FOLGA=0
MOTIVO=
while [ $# -gt 0 ]; do
  case "$1" in
    --folga) [ $# -ge 2 ] || uso; FOLGA="$2"; shift 2;;
    --forcar)
      # Motivo vazio, só de espaço ou outra opção no lugar dele param aqui, antes de qualquer gcloud.
      [ $# -ge 2 ] || uso
      case "$2" in -*) uso;; esac
      [[ "$2" =~ [^[:space:]] ]] || uso
      MOTIVO="$2"; shift 2;;
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
POLITICA_ALERTA="${POLITICA_ALERTA:-custta-leituras}"
# A cota das leituras do Monitoring vai para o projeto alvo, salvo PROJETO_COTA.
PROJETO_COTA="${PROJETO_COTA:-$PROJETO_ALVO}"
OBJETO="gs://$BUCKET_ESTADO/estado.json"

# Ganchos só dos testes. URL_MONITORING aponta a trava para um Monitoring falso e só aceita
# http://127.0.0.1:porta, para o token não sair para outro lugar. AGORA fixa o relógio e só vale
# junto com ela: fora dos testes, adiantar a hora soltaria a trava sem motivo nem registro.
URL_MONITORING="${URL_MONITORING:-}"
if [ -n "$URL_MONITORING" ]; then
  if ! [[ "$URL_MONITORING" =~ ^http://127\.0\.0\.1:[0-9]+$ ]]; then
    echo "URL_MONITORING só aceita http://127.0.0.1:porta, nos testes" >&2
    exit 2
  fi
elif [ -n "${AGORA:-}" ]; then
  echo "AGORA só vale nos testes, junto com URL_MONITORING" >&2
  exit 2
fi
PASTA="$(mktemp -d)"
trap 'rm -rf "$PASTA"' EXIT

# A trava vem antes de tudo: recusada, nada muda no bucket nem na API. Sai com 0 quando deixa, 3
# quando segura e 4 quando não conseguiu ler; qualquer outra saída também conta como não leu. O
# que ela diz fica em trava.txt, para o registro do --forcar.
TRAVA=0
PROJETO_ALVO="$PROJETO_ALVO" PROJETO_COTA="$PROJETO_COTA" POLITICA_ALERTA="$POLITICA_ALERTA" URL_MONITORING="$URL_MONITORING" \
  python3 - "$PASTA/trava.txt" <<'PY' || TRAVA=$?
import json, os, re, subprocess, sys
import urllib.error, urllib.parse, urllib.request
from datetime import datetime, timedelta, timezone

ATRASO = 300  # s somados a cada janela: o atraso da métrica
FRACAO = 0.5  # segura com a soma em metade do limiar ou mais
PAGINAS = 50  # teto de páginas por lista: resposta que nunca acaba vira falha, não laço
TESTE = bool(os.environ.get("URL_MONITORING"))  # o shell já conferiu que é o falso local
PRAZO = 5 if TESTE else 30  # s por pedido; nos testes, curto para o do prazo não esperar 30 s
try:
    from zoneinfo import ZoneInfo
    BRASILIA = ZoneInfo("America/Sao_Paulo")
except Exception:  # sem a base de fusos; Brasília não tem horário de verão desde 2019
    BRASILIA = timezone(timedelta(hours=-3))

projeto = os.environ["PROJETO_ALVO"]
cota = os.environ["PROJETO_COTA"]
nome = os.environ["POLITICA_ALERTA"]
base = os.environ["URL_MONITORING"] if TESTE else "https://monitoring.googleapis.com"


class SemRedirecionar(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None  # seguir levaria o token junto; o 3xx vira erro HTTP e falha fechada


# Sem proxy e sem redirecionamento: o token vai só ao Monitoring.
abrir = urllib.request.build_opener(urllib.request.ProxyHandler({}), SemRedirecionar).open


class SemLeitura(Exception):
    pass


def instante(texto):
    m = re.fullmatch(r"(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.(\d+))?Z", str(texto))
    if not m:
        raise SemLeitura(f"hora fora do formato: {texto}")
    *partes, fracao = m.groups()
    return datetime(*map(int, partes), int((fracao or "0")[:6].ljust(6, "0")), tzinfo=timezone.utc)


def rfc3339(t):
    return t.strftime("%Y-%m-%dT%H:%M:%SZ")


def numero(x):
    if x == int(x):
        return f"{int(x):,}".replace(",", ".")
    return f"{x:,.2f}".replace(",", " ").replace(".", ",").replace(" ", ".")


def duracao(segundos):
    h, m = divmod(segundos // 60, 60)
    if h and m:
        return f"{h} h {m:02d} min"
    return f"{h} h" if h else f"{m} min"


def hora(t):
    """Em Brasília, arredondada para o minuto seguinte: antes da hora dita a trava ainda segura."""
    t = t.astimezone(BRASILIA)
    if t.second or t.microsecond:
        t = t.replace(second=0, microsecond=0) + timedelta(minutes=1)
    return t.strftime("%d/%m %Hh%M")


def token_de_acesso():
    r = subprocess.run(["gcloud", "auth", "print-access-token"], capture_output=True, text=True)
    if r.returncode != 0 or not r.stdout.strip():
        erro = r.stderr.strip().splitlines()
        raise SemLeitura("o gcloud não deu o token de acesso: " + (erro[-1] if erro else f"saída {r.returncode}"))
    return r.stdout.strip()


def listar(recurso, chave, params, token):
    """GET na API REST do Monitoring, seguindo as páginas. O cabeçalho de cota evita a cota
    dividida do gcloud sem projeto de cota."""
    itens, pagina = [], None
    for _ in range(PAGINAS):
        busca = params + ([("pageToken", pagina)] if pagina else [])
        url = f"{base}/v3/projects/{projeto}/{recurso}" + ("?" + urllib.parse.urlencode(busca) if busca else "")
        pedido = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}", "x-goog-user-project": cota})
        try:
            with abrir(pedido, timeout=PRAZO) as resposta:
                corpo = json.load(resposta)
        except urllib.error.HTTPError as e:
            try:
                erro = json.load(e)["error"]
                motivo = f"{erro['status']}: {erro['message']}"
            except Exception:
                motivo = f"{e.reason}"
            raise SemLeitura(f"o Monitoring respondeu HTTP {e.code} {motivo}")
        itens += corpo.get(chave, [])
        pagina = corpo.get("nextPageToken")
        if not pagina:
            return itens
    raise SemLeitura(f"o Monitoring mandou mais de {PAGINAS} páginas de {recurso}")


def leituras_do(valor):
    """Quantas leituras o ponto traz. Soma de DELTA nunca é negativa nem booleana, e a API manda o
    int64Value em texto: fora disso, não lê."""
    if "int64Value" in valor:
        n = valor["int64Value"]
        if isinstance(n, str) and re.fullmatch(r"\d+", n):
            return int(n)
    elif "doubleValue" in valor:
        n = valor["doubleValue"]
        if isinstance(n, (int, float)) and not isinstance(n, bool) and n >= 0:
            return n
    raise SemLeitura(f"um ponto da série veio com valor fora do formato: {json.dumps(valor)}")


def janela_de(condicao):
    """Filtro, janela em segundos e limiar; só soma em janela acima de um limiar, que é a conta da trava."""
    limiar_ = condicao.get("conditionThreshold") or {}
    agregacoes = limiar_.get("aggregations") or []
    agregacao = agregacoes[0] if len(agregacoes) == 1 else {}
    periodo = re.fullmatch(r"(\d+)s", str(agregacao.get("alignmentPeriod", "")))
    limiar = limiar_.get("thresholdValue")
    if not (periodo and int(periodo.group(1)) > 0 and limiar_.get("filter") and not limiar_.get("denominatorFilter")
            and limiar_.get("comparison") == "COMPARISON_GT"
            and agregacao.get("perSeriesAligner") == "ALIGN_SUM" and agregacao.get("crossSeriesReducer") == "REDUCE_SUM"
            and isinstance(limiar, (int, float)) and not isinstance(limiar, bool) and limiar > 0):
        raise SemLeitura(f"a condição {condicao.get('displayName', '(sem nome)')} não é soma acima de um limiar, e a trava só sabe ler essa")
    return limiar_["filter"], int(periodo.group(1)), limiar


def avaliar(agora, token):
    politicas = [p for p in listar("alertPolicies", "alertPolicies", [], token) if p.get("displayName") == nome]
    if not politicas:
        raise SemLeitura(f"a política {nome} não existe no projeto {projeto}")
    if len(politicas) > 1:
        raise SemLeitura(f"há {len(politicas)} políticas {nome} no projeto {projeto}")
    condicoes = politicas[0].get("conditions") or []
    if not condicoes:
        raise SemLeitura(f"a política {nome} não tem condição")
    lidas = [(c.get("displayName", "(sem nome)"),) + janela_de(c) for c in condicoes]
    linhas, soltas = [], []
    for titulo, filtro, janela, limiar in lidas:
        alcance = janela + ATRASO
        inicio = agora - timedelta(seconds=alcance)
        series = listar("timeSeries", "timeSeries", [
            ("filter", filtro), ("interval.startTime", rfc3339(inicio)), ("interval.endTime", rfc3339(agora)),
            ("aggregation.alignmentPeriod", "60s"), ("aggregation.perSeriesAligner", "ALIGN_SUM"),
            ("aggregation.crossSeriesReducer", "REDUCE_SUM")], token)
        pontos = []
        for serie in series:
            for ponto in serie.get("points", []):
                fim, n = instante(ponto["interval"]["endTime"]), leituras_do(ponto["value"])
                if fim > inicio:
                    pontos.append((fim, n))
        pontos.sort()
        soma, meta = sum(n for _, n in pontos), limiar * FRACAO
        texto = f"- {titulo}: {numero(soma)} leituras em {duracao(alcance)}; segura com {numero(meta)} ou mais; "
        if soma < meta:
            linhas.append(texto + "livre.")
            continue
        # Com a API desligada não entra leitura nova: cada minuto sai da janela em fim + alcance.
        # Solta quando sai o minuto que deixa a soma abaixo da metade, não no fim do ataque + janela.
        resto = soma
        for fim, n in pontos:
            resto -= n
            if resto < meta:
                break
        solta = fim + timedelta(seconds=alcance)
        soltas.append(solta)
        linhas.append(texto + f"solta {hora(solta)}.")
    return linhas, soltas


def dizer(linhas):
    print("\n".join(linhas))
    with open(sys.argv[1], "w", encoding="utf-8") as f:
        f.write("\n".join(linhas) + "\n")


def principal():
    try:
        agora = instante(os.environ["AGORA"]) if os.environ.get("AGORA") else datetime.now(timezone.utc)
        linhas, soltas = avaliar(agora.replace(microsecond=0), token_de_acesso())
    except SemLeitura as e:
        motivo = str(e)
    except urllib.error.URLError as e:
        motivo = f"não falou com o Monitoring: {e.reason}"
    except (KeyError, TypeError, ValueError) as e:
        motivo = f"a resposta do Monitoring veio fora do formato ({type(e).__name__}: {e})"
    except Exception as e:
        motivo = f"{type(e).__name__}: {e}"
    else:
        if soltas:
            cabeca = (f"Trava: leituras ainda altas na política {nome}. Religue a partir de {hora(max(soltas))}, horário de Brasília: "
                      "é o mínimo, contando só as leituras que a métrica já mostra (ela atrasa uns 4 minutos).")
        else:
            cabeca = f"Trava: leituras abaixo da metade do limiar na política {nome}."
        dizer([cabeca] + linhas)
        return 3 if soltas else 0
    dizer([f"Trava: sem ler as leituras, não deixo religar: {motivo}."])
    return 4


sys.exit(principal())
PY
case "$TRAVA" in
  0) RESULTADO=livre;;
  3) RESULTADO=segura;;
  4) RESULTADO=nao-leu;;
  *) RESULTADO=nao-leu; echo "a trava não rodou até o fim (saída $TRAVA)" > "$PASTA/trava.txt";;
esac
if [ -z "$MOTIVO" ]; then
  case "$TRAVA" in
    0) ;;
    3) echo "a API NÃO foi religada: rode de novo a partir da hora acima. Num corte falso, de uso legítimo que cresceu, suba o limiar da política e rode com --forcar \"motivo\"." >&2; exit 3;;
    4) echo "a API NÃO foi religada: sem ler as leituras, a trava não deixa. Confira o acesso ao Monitoring e rode de novo, ou rode com --forcar \"motivo\"." >&2; exit 4;;
    *) echo "a trava não rodou até o fim (saída $TRAVA): a API NÃO foi religada." >&2; exit 4;;
  esac
else
  [ "$TRAVA" = 0 ] || [ "$TRAVA" = 3 ] || [ "$TRAVA" = 4 ] || echo "a trava não rodou até o fim (saída $TRAVA)" >&2
  echo "Religando à força, com a trava em \"$RESULTADO\". Motivo: $MOTIVO"
fi

# A geração vem antes do conteúdo: se o objeto mudar no meio, a gravação condicionada recusa.
# Cada comando tem o próprio || return porque set -e não vale dentro de função chamada em if.
gravar_base(){
  local geracao
  geracao="$(gcloud storage objects describe "$OBJETO" --format='value(generation)')" || return 1
  [ -n "$geracao" ] || return 1
  gcloud storage cat "$OBJETO" > "$PASTA/atual.json" || return 1
  FOLGA="$FOLGA" ORCAMENTO_PROJETO="$ORCAMENTO_PROJETO" ORCAMENTO_FORA_FIRESTORE="$ORCAMENTO_FORA_FIRESTORE" \
  MOTIVO="$MOTIVO" RESULTADO="$RESULTADO" \
    python3 - "$PASTA/atual.json" "$PASTA/novo.json" "$PASTA/vale-agora.txt" "$PASTA/trava.txt" <<'PY' || return 1
import json, os, sys
from datetime import datetime, timezone

LIMITE_API, LIMITE_COBRANCA = 60, 100  # os de corte/regra.js, em reais

origem, destino, vale_agora, trava = sys.argv[1:5]
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
    linhas.append(f"cobrança cai em {reais(rebasear(fora, folga) + LIMITE_COBRANCA)}")
estado["primeiraFalha"] = None
estado["apiDesligadaEm"] = None
estado["cobrancaTiradaEm"] = None
motivo = os.environ["MOTIVO"]
if motivo:
    # A lista só cresce: o registro de um --forcar não apaga o de outro. AGORA (testes) fixa a hora.
    try:
        with open(trava, encoding="utf-8") as f:
            disse = f.read().splitlines()
    except OSError:
        disse = []
    agora = os.environ.get("AGORA")
    quando = datetime.strptime(agora[:19], "%Y-%m-%dT%H:%M:%S").replace(tzinfo=timezone.utc) if agora else datetime.now(timezone.utc)
    anteriores = estado.get("religadosForcados")
    lista = anteriores if isinstance(anteriores, list) else ([] if anteriores is None else [anteriores])
    estado["religadosForcados"] = lista + [{
        "em": quando.isoformat(timespec="milliseconds").replace("+00:00", "Z"),
        "motivo": motivo, "resultado": os.environ["RESULTADO"], "trava": disse,
    }]
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

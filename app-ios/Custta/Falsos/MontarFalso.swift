#if DEBUG
import Foundation
import CusttaNucleo

/* Monta o app com os serviços falsos (CUSTTA_SERVICOS=falsos), para os testes de tela. Só Debug.
   Variáveis que o teste passa ao abrir o app:
   CUSTTA_CONTA   conta inicial da ContaFalsa (nenhuma, senha, senha-nao-confirmada, apple-sem-perfil,
                  google-sem-perfil, google-perfil-concorrente)
   CUSTTA_DADOS   vitrine (padrão: as obras do mockup) | exemplo (as dos testes) | vazio | limite (as 300 obras do teto)
   CUSTTA_REDE    offline (abre "em modo avião": dados do cache e indicador "Sem conexão")
   CUSTTA_LEITURA erro (a escuta falha com permission-denied) | formato (documento que o app não lê) | nunca (a escuta
                  não responde: "Carregando suas obras…")
   CUSTTA_GRAVACAO recusa (toda gravação volta com permission-denied: o "Não salvou" que não passa sozinho)
   CUSTTA_APAGAR_REMOTO <obra>/<gasto>@<segundos> (outro aparelho apaga o gasto, com o app aberto)
   CUSTTA_MARCA   servidor (o servidor já respondeu a esta conta numa abertura anterior: com CUSTTA_REDE=offline e
                  CUSTTA_DADOS=vazio, é a conta vazia que abre sem rede e pode lançar)
   CUSTTA_LIMPEZA falha (a limpeza do cache falha no sair e na 1ª nova tentativa) | abertura (abre bloqueado,
                  e a 1ª nova tentativa também falha); cada nova tentativa leva 8 s, para o "Limpando…" ficar à
                  vista mesmo no simulador da CI, onde o teste só o encontra uns 4 s depois do toque */
extension Composicao {
    static func montarFalso(_ ambiente: [String: String]) -> ModeloApp {
        let semRede = ambiente["CUSTTA_REDE"] == "offline"
        let conta = ContaFalsa(inicial: ambiente["CUSTTA_CONTA"] ?? "nenhuma", limpeza: ambiente["CUSTTA_LIMPEZA"])
        if ambiente["CUSTTA_LIMPEZA"] != nil { conta.demoraAoLimpar = .seconds(8) }
        let falha: String? = switch ambiente["CUSTTA_LEITURA"] {
        case "erro": "permission-denied"
        case "formato": "formato-desconhecido"
        default: nil
        }
        let dados: ValorJSON? = switch ambiente["CUSTTA_DADOS"] {
        case "vazio": nil
        case "exemplo": DadosDeExemplo.blob
        case "limite": DadosDeExemplo.noTeto()
        default: DadosDeExemplo.vitrine()
        }
        // CUSTTA_APAGAR_REMOTO=<obra>/<gasto>@<segundos>: outro aparelho apaga um gasto com o app aberto.
        let remoto = ambiente["CUSTTA_APAGAR_REMOTO"].flatMap { v -> (obra: String, gasto: String, depois: Double)? in
            let partes = v.split(whereSeparator: { $0 == "/" || $0 == "@" }).map(String.init)
            guard partes.count == 3, let segundos = Double(partes[2]) else { return nil }
            return (partes[0], partes[1], segundos)
        }
        let transporte = TransporteFalsoApp(dados: dados, semRede: semRede, falhaDeLeitura: falha,
                                            semLeitura: ambiente["CUSTTA_LEITURA"] == "nunca",
                                            recusa: ambiente["CUSTTA_GRAVACAO"] == "recusa" ? "permission-denied" : nil,
                                            apagarRemoto: remoto)
        let rede = MonitorDeRede(forcarSemRede: semRede)
        let marca = MarcaEmMemoria()
        if ambiente["CUSTTA_MARCA"] == "servidor" { marca.marcarTodas = true }
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede, marca: marca)
        return ModeloApp(conta: conta, sincronizador: sincronizador, rede: rede)
    }
}

/// A marca "o servidor já respondeu" em memória (só Debug): cada abertura com os falsos começa sem ela, a não ser que o
/// teste peça (`marcarTodas`, a conta de qualquer uid já vista).
@MainActor
final class MarcaEmMemoria: MarcaDoServidor {
    var marcarTodas = false
    private(set) var contas: Set<String> = []
    func respondeu(uid: String) -> Bool { marcarTodas || contas.contains(uid) }
    func marcar(uid: String) { contas.insert(uid) }
    func desmarcar(uid: String) { contas.remove(uid) }
}
#endif

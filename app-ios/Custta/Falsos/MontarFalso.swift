#if DEBUG
import Foundation
import CusttaNucleo

/* Monta o app com os serviços falsos (CUSTTA_SERVICOS=falsos), para os testes de tela. Só Debug.
   Variáveis que o teste passa ao abrir o app:
   CUSTTA_CONTA   conta inicial da ContaFalsa (nenhuma, senha, senha-nao-confirmada, apple-sem-perfil,
                  google-sem-perfil, google-perfil-concorrente)
   CUSTTA_DADOS   vitrine (padrão: as obras do mockup) | exemplo (as dos testes) | vazio
   CUSTTA_REDE    offline (abre "em modo avião": dados do cache e indicador "Sem conexão")
   CUSTTA_LEITURA erro (a escuta falha com permission-denied) | formato (documento que o app não lê) */
extension Composicao {
    static func montarFalso(_ ambiente: [String: String]) -> ModeloApp {
        let semRede = ambiente["CUSTTA_REDE"] == "offline"
        let conta = ContaFalsa(inicial: ambiente["CUSTTA_CONTA"] ?? "nenhuma")
        let falha: String? = switch ambiente["CUSTTA_LEITURA"] {
        case "erro": "permission-denied"
        case "formato": "formato-desconhecido"
        default: nil
        }
        let dados: ValorJSON? = switch ambiente["CUSTTA_DADOS"] {
        case "vazio": nil
        case "exemplo": DadosDeExemplo.blob
        default: DadosDeExemplo.vitrine()
        }
        let transporte = TransporteFalsoApp(dados: dados, semRede: semRede, falhaDeLeitura: falha)
        let rede = MonitorDeRede(forcarSemRede: semRede)
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede)
        return ModeloApp(conta: conta, sincronizador: sincronizador, rede: rede)
    }
}
#endif

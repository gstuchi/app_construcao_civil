#if DEBUG
import Foundation
import notify
import CusttaNucleo

/// Transporte falso dos testes (só Debug): entrega um blob fixo e confirma gravações depois de
/// 300 ms (nunca, sem rede). `falhaDeLeitura` faz a escuta falhar com esse código antes do primeiro
/// snapshot (CUSTTA_LEITURA=erro: permission-denied; formato: formato-desconhecido); `semLeitura`, a escuta
/// nunca responde (CUSTTA_LEITURA=nunca: "Carregando suas obras…" para sempre). `recusa` responde toda gravação com
/// esse código (CUSTTA_GRAVACAO=recusa: permission-denied, o "Não salvou" que não passa sozinho). `apagarRemoto`
/// simula outro aparelho apagando um gasto: um segundo snapshot, sem ele, depois de alguns segundos
/// (CUSTTA_APAGAR_REMOTO=<obra>/<gasto>@<segundos>); com o gasto vazio, a obra inteira.
@MainActor
final class TransporteFalsoApp: TransporteDados {
    private final class Nada: Cancelavel { func cancelar() {} }
    private let dados: ValorJSON?
    private let semRede: Bool
    private let falhaDeLeitura: String?
    private let semLeitura: Bool
    private let recusa: String?
    private let apagarRemoto: (obra: String, gasto: String, depois: Double)?
    /// Quantas gravações chegaram (os testes conferem que abrir o app não grava nada).
    private(set) var gravacoes = 0

    init(dados: ValorJSON?, semRede: Bool, falhaDeLeitura: String? = nil, semLeitura: Bool = false, recusa: String? = nil,
         apagarRemoto: (obra: String, gasto: String, depois: Double)? = nil) {
        self.dados = dados
        self.semRede = semRede
        self.falhaDeLeitura = falhaDeLeitura
        self.semLeitura = semLeitura
        self.recusa = recusa
        self.apagarRemoto = apagarRemoto
    }

    func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                 aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel {
        let dados = self.dados, semRede = self.semRede, falha = falhaDeLeitura, remoto = apagarRemoto
        guard !semLeitura else { return Nada() }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            if let falha { aoFalhar(falha); return }
            aoReceber(Instantaneo(dados: dados, doCache: semRede, gravacaoPendente: false))
            guard let remoto else { return }
            // Os segundos contam do aviso do teste (notify_post de "br.com.custta.falso.apagarRemoto", com a folha já
            // aberta), não da abertura do app: um relógio desde a abertura corria contra o teste, mais lento na CI.
            await withCheckedContinuation { (avisado: CheckedContinuation<Void, Never>) in
                var token: Int32 = 0
                notify_register_dispatch("br.com.custta.falso.apagarRemoto", &token, .main) { t in
                    notify_cancel(t)
                    avisado.resume()
                }
            }
            try? await Task.sleep(for: .seconds(remoto.depois))
            let depois = remoto.gasto.isEmpty ? Self.semAObra(remoto.obra, em: dados) : Self.sem(remoto.gasto, naObra: remoto.obra, em: dados)
            aoReceber(Instantaneo(dados: depois, doCache: semRede, gravacaoPendente: false))
        }
        return Nada()
    }

    /// O blob sem uma obra, como outro aparelho o gravaria.
    private static func semAObra(_ obraId: String, em dados: ValorJSON?) -> ValorJSON? {
        guard case .objeto(var raiz)? = dados, case .lista(let obras)? = raiz["obras"] else { return dados }
        raiz["obras"] = .lista(obras.filter { o in
            if case .objeto(let campos) = o { return campos["id"] != .texto(obraId) }
            return true
        })
        return .objeto(raiz)
    }

    /// O blob sem um gasto, como outro aparelho o gravaria.
    private static func sem(_ gastoId: String, naObra obraId: String, em dados: ValorJSON?) -> ValorJSON? {
        guard case .objeto(var raiz)? = dados, case .lista(let obras)? = raiz["obras"] else { return dados }
        raiz["obras"] = .lista(obras.map { o in
            guard case .objeto(var obra) = o, obra["id"] == .texto(obraId), case .lista(let gastos)? = obra["gastos"] else { return o }
            obra["gastos"] = .lista(gastos.filter { g in
                if case .objeto(let campos) = g { return campos["id"] != .texto(gastoId) }
                return true
            })
            return .objeto(obra)
        })
        return .objeto(raiz)
    }

    /// Cada gravação só responde quando o teste avisa (notify_post de "br.com.custta.falso.responderGravacao"), e não
    /// depois de 300 ms (CUSTTA_GRAVACAO_ESPERA=aviso): a recusa chega com a folha que o teste abriu depois de gravar.
    var respostaNoAviso = false

    func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void) {
        gravacoes += 1
        guard !semRede else { return }
        let recusa = self.recusa, noAviso = respostaNoAviso
        Task { @MainActor in
            if noAviso {
                await withCheckedContinuation { (avisado: CheckedContinuation<Void, Never>) in
                    var token: Int32 = 0
                    notify_register_dispatch("br.com.custta.falso.responderGravacao", &token, .main) { t in
                        notify_cancel(t)
                        avisado.resume()
                    }
                }
            } else {
                try? await Task.sleep(for: .milliseconds(300))
            }
            concluir(recusa)
        }
    }

    func aguardarGravacoesPendentes(concluir: @escaping @MainActor (String?) -> Void) {
        if !semRede { concluir(nil) }
    }
}

/// O blob de exemplo dos testes: obras com orçamento (uma passou), uma vendida, uma sem gasto e
/// uma de nome longo e total alto (a lista não pode cortar nada no maior tamanho de letra).
enum DadosDeExemplo {
    static let blob: ValorJSON = .objeto([
        "obras": .lista([
            .objeto(["id": .texto("o1"), "nome": .texto("Casa Alphaville"), "dataInicio": .texto("2025-03-10"), "fase": .texto("construcao"),
                     "orcamento": .objeto(["modo": .texto("total"), "total": .numero(400_000)]),
                     "gastos": .lista([
                        .objeto(["id": .texto("g1"), "valor": .numero(98_000), "topico": .texto("fundacao"), "descricao": .texto("Sapatas"), "data": .texto("2025-03-20"), "pagamento": .texto("pix")]),
                        .objeto(["id": .texto("g2"), "valor": .numero(231_000), "topico": .texto("estrutura"), "descricao": .texto("Laje"), "data": .texto("2025-06-02"), "pagamento": .texto("pix")]),
                     ])]),
            .objeto(["id": .texto("o2"), "nome": .texto("Sobrado Centro"), "dataInicio": .texto("2024-01-15"), "fase": .texto("vendida"),
                     "venda": .objeto(["valor": .numero(980_000), "data": .texto("2025-02-10")]),
                     "orcamento": .objeto(["modo": .texto("total"), "total": .numero(500_000)]),
                     "gastos": .lista([
                        .objeto(["id": .texto("h1"), "valor": .numero(559_500.75), "topico": .texto("alvenaria"), "descricao": .texto("Blocos"), "data": .texto("2024-05-31"), "pagamento": .texto("pix")]),
                     ])]),
            .objeto(["id": .texto("o3"), "nome": .texto("Terreno novo"), "dataInicio": .texto("2026-10-01"), "fase": .texto("construcao"), "gastos": .lista([])]),
            .objeto(["id": .texto("o4"), "nome": .texto("Residencial Jardim das Acácias, Bloco B, Casa 12"), "dataInicio": .texto("2023-05-20"),
                     "fase": .texto("construcao"),
                     "gastos": .lista([
                        .objeto(["id": .texto("j1"), "valor": .numero(123_456_789), "topico": .texto("estrutura"), "descricao": .texto("Estrutura"), "data": .texto("2023-06-01"), "pagamento": .texto("pix")]),
                     ])]),
        ]),
        "config": .objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([])]),
    ])

    /// As três obras do mockup aprovado (Casa Alphaville, Sobrado Granja Viana e Casa Tamboré 4), com as
    /// datas contadas a partir de hoje: a lista mostra sempre os números do mockup (14 meses, R$ 842 mil,
    /// R$ 927 mil corrigido, 70% do orçamento…), para comparar o simulador com ele lado a lado. A Casa
    /// Alphaville tem os 46 lançamentos da tela da obra do mockup da etapa 2 (VitrineDaObra.swift).
    static func vitrine(hoje: Date = .now) -> ValorJSON {
        let calendario = Calendar(identifier: .gregorian)
        func data(_ mesesAtras: Int) -> ValorJSON {
            .texto(dataLocalISO(calendario.date(byAdding: .month, value: -mesesAtras, to: hoje) ?? hoje, fuso: .current))
        }
        func obra(_ id: String, _ nome: String, _ fase: String, inicio: Int, gastos: [(Int, Double)],
                  extra: [String: ValorJSON] = [:]) -> ValorJSON {
            var campos: [String: ValorJSON] = [
                "id": .texto(id), "nome": .texto(nome), "fase": .texto(fase), "dataInicio": data(inicio),
                "gastos": .lista(gastos.enumerated().map { i, g in
                    .objeto(["id": .texto("\(id)g\(i)"), "valor": .numero(g.1), "topico": .texto("outros"),
                             "descricao": .texto("Etapa \(i + 1)"), "data": data(g.0), "pagamento": .texto("pix")])
                }),
            ]
            campos.merge(extra) { _, novo in novo }
            return .objeto(campos)
        }
        return .objeto([
            "obras": .lista([
                obra("v1", "Casa Alphaville", "construcao", inicio: 14, gastos: [],
                     extra: ["orcamento": .objeto(["modo": .texto("total"), "total": .numero(1_200_000)]),
                             "valorEstimadoVenda": .numero(1_450_000), "areaM2": .numero(300), "gastos": gastosDaVitrine(hoje: hoje)]),
                obra("v2", "Sobrado Granja Viana", "pronta", inicio: 23,
                     gastos: [(23, 250_000), (21, 330_000), (18, 310_000), (15, 280_000), (12, 210_000)]),
                obra("v3", "Casa Tamboré 4", "vendida", inicio: 20,
                     gastos: [(20, 210_000), (18, 260_000), (15, 250_000), (12, 256_000)],
                     extra: ["venda": .objeto(["valor": .numero(1_450_000), "data": data(2)])]),
            ]),
            "config": .objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([])]),
        ])
    }
}
#endif

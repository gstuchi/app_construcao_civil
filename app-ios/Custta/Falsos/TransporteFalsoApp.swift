#if DEBUG
import Foundation
import CusttaNucleo

/// Transporte falso dos testes (só Debug): entrega um blob fixo e confirma gravações depois de
/// 300 ms (nunca, sem rede). `falhaDeLeitura` faz a escuta falhar com esse código antes do primeiro
/// snapshot (CUSTTA_LEITURA=erro: permission-denied; formato: formato-desconhecido).
@MainActor
final class TransporteFalsoApp: TransporteDados {
    private final class Nada: Cancelavel { func cancelar() {} }
    private let dados: ValorJSON?
    private let semRede: Bool
    private let falhaDeLeitura: String?
    /// Quantas gravações chegaram (os testes conferem que abrir o app não grava nada).
    private(set) var gravacoes = 0

    init(dados: ValorJSON?, semRede: Bool, falhaDeLeitura: String? = nil) {
        self.dados = dados
        self.semRede = semRede
        self.falhaDeLeitura = falhaDeLeitura
    }

    func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                 aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel {
        let dados = self.dados, semRede = self.semRede, falha = falhaDeLeitura
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            if let falha { aoFalhar(falha); return }
            aoReceber(Instantaneo(dados: dados, doCache: semRede, gravacaoPendente: false))
        }
        return Nada()
    }

    func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void) {
        gravacoes += 1
        guard !semRede else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            concluir(nil)
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
    /// R$ 928 mil corrigido, 70% do orçamento…), para comparar o simulador com ele lado a lado.
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
                obra("v1", "Casa Alphaville", "construcao", inicio: 14,
                     gastos: [(14, 92_000), (13, 150_000), (11, 230_000), (8, 190_000), (5, 180_000)],
                     extra: ["orcamento": .objeto(["modo": .texto("total"), "total": .numero(1_200_000)])]),
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

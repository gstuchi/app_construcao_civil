import Foundation
import Testing
import FirebaseAuth
@testable import Custta
import CusttaNucleo

/* Metade app da conferência cruzada (tests/app-ios/cruzado.mjs): entra na conta que o "site"
   criou, carrega o documento, lança um gasto (o que o roteiro mandou) e grava pelo Sincronizador,
   como uma edição da etapa 2 fará. O roteiro confere depois, com o SDK JavaScript, que o gasto
   chegou e que nada do site se perdeu. */
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["CUSTTA_CRUZADO"] == "1"))
struct CruzadoTests {
    @Test func appLancaGastoQueOSiteVe() async throws {
        let ambiente = ProcessInfo.processInfo.environment
        let u = try await Auth.auth(app: Emulador.app).signIn(withEmail: ambiente["CUSTTA_EMAIL"]!, password: ambiente["CUSTTA_SENHA"]!).user
        let s = Sincronizador(transporte: TransporteFirebase(banco: Emulador.banco), relogio: RelogioDoSistema())
        s.iniciar(uid: u.uid)
        for _ in 0..<200 where !s.dadosCarregados { try await Task.sleep(for: .milliseconds(50)) }
        try #require(s.dadosCarregados, "o app não carregou o documento que o site gravou")
        let gasto = try JSONDecoder().decode(ValorJSON.self, from: Data(try #require(ambiente["CUSTTA_GASTO_DO_APP"]).utf8))
        var estado = s.estado
        let i = try #require(estado.obras.firstIndex { $0.id == ambiente["CUSTTA_OBRA_DO_APP"] }, "a obra do roteiro não está no documento")
        estado.obras[i].gastos.append(Gasto(campos: try #require(gasto.comoObjeto)))
        try await s.salvar(estado)
        s.parar()
    }
}

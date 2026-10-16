import Foundation

/* Até a conferência cruzada do PR 3 da etapa 2 (spec docs/specs/2026-10-13-app-nativo-etapa2-design.md, "Conta de
   teste"), o build do TestFlight (Release) grava só em conta de teste: e-mail com "custta-teste" (um apelido do Gmail
   serve, como nome+custta-teste@gmail.com). Na conta de sempre, o app mostra os dados e recusa gravar, para um lançamento
   por hábito não regravar o documento inteiro da conta real. Em Debug (simulador e testes) grava sempre. A troca para a
   conta real, no fim do PR 3, apaga este arquivo. */
@MainActor
enum ContaDeTeste {
    static let marca = "custta-teste"

    static func podeGravar(email: String?, release: Bool = ehRelease) -> Bool {
        !release || (email ?? "").lowercased().contains(marca)
    }

    static let titulo = "Este build ainda não grava na sua conta"
    static let mensagem = "Até o fim dos testes, lançar, editar e apagar só valem na conta de teste. Nada foi gravado."

    #if DEBUG
    /// Em Debug grava sempre; o teste do `gravar` liga por um instante para provar a ligação da guarda.
    static var ehRelease = false
    #else
    static let ehRelease = true
    #endif
}

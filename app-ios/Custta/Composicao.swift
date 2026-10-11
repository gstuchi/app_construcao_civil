import Foundation
import CusttaNucleo

/* Monta o app. Por enquanto só com os serviços falsos (Debug), que as telas e os testes de tela
   usam; a composição de produção (Firebase) e a dos emuladores chegam com a camada Firebase.
   O build Release, até lá, abre só a abertura. */
@MainActor
enum Composicao {
    /// O modelo das telas, ou nil quando o build ainda não tem serviço (Release, antes da camada Firebase).
    static func montar(ambiente: [String: String] = ProcessInfo.processInfo.environment) -> ModeloApp? {
        #if DEBUG
        return montarFalso(ambiente)
        #else
        return nil
        #endif
    }
}

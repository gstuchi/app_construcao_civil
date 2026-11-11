import FirebaseAppCheck
import FirebaseCore

/* A prova de que o pedido vem do app de verdade, num iPhone de verdade: o App Attest da Apple, entregue ao App Check
   do Firebase. Ninguém ativa a exigência: o console só observa, então uma prova que falha não barra login nem gravação.
   Só o Release registra esta fábrica (Composicao.configurarFirebase, antes do configure). Debug, emuladores e serviços
   falsos não a registram. Sem DeviceCheck: o app exige iOS 26, e todo iPhone com esse sistema tem o App Attest. */
final class FabricaDeProva: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        AppAttestProvider(app: app)
    }
}

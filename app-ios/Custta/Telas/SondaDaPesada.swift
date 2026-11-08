#if DEBUG
import Foundation

/* Sonda temporária (ramo proto/, nunca na main): com `-custta.sonda <nome>`, uma vigia da thread principal numa thread à
   parte manda um bloco à principal a cada 0,1 s e anota em /tmp/custta-sonda/sonda-<nome>-<ms>.log cada parada acima de
   250 ms. O teste lê o log no fim, sem consultar a tela durante os arrastos. */
enum SondaDaPesada {
    nonisolated(unsafe) private static var ligada = false

    static func vigiar() {
        guard !ligada, let nome = UserDefaults.standard.string(forKey: "custta.sonda"), !nome.isEmpty else { return }
        ligada = true
        let pasta = URL(fileURLWithPath: "/tmp/custta-sonda")
        try? FileManager.default.createDirectory(at: pasta, withIntermediateDirectories: true)
        let url = pasta.appendingPathComponent("sonda-\(nome)-\(Int(Date.now.timeIntervalSince1970 * 1000)).log")
        FileManager.default.createFile(atPath: url.path, contents: nil)
        guard let saida = try? FileHandle(forWritingTo: url) else { return }
        Thread.detachNewThread {
            while true {
                let antes = Date.now
                let sinal = DispatchSemaphore(value: 0)
                DispatchQueue.main.async { sinal.signal() }
                sinal.wait()
                let ms = Date.now.timeIntervalSince(antes) * 1000
                if ms > 250 {
                    saida.write(Data(String(format: "%.3f | parada %d ms\n", Date.now.timeIntervalSince1970, Int(ms)).utf8))
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
}
#endif

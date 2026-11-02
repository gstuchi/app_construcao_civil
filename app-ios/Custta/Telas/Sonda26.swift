import SwiftUI

/* Sonda das quatro falhas do iOS 26 no #99 (02/11/2026, temporária, só em ramo proto/). Com `-custta.sonda <variante>`, o
   app escreve um log (/tmp/custta-sonda, e o tmp do contêiner se /tmp não der): paradas da thread principal, a rolagem
   da obra (pulos e mudança de altura do conteúdo), as peças da lista que entram e saem e o gancho da rolagem fixa. Cada
   variante muda uma coisa só:
   - controle: nada (só a vigia e o log do gancho, que todas as variantes têm);
   - olhos: o controle com o log da rolagem e das peças da lista (diagnóstico; as outras não o têm);
   - semPosicao: a obra sem o `.scrollPosition` do gancho quando não há `-custta.rolagem` (como em Release);
   - semRefixar: o gancho rola uma vez e não reaplica a rolagem;
   - blocosSoltos: os blocos do alto viram filhos da LazyVStack, em vez de um VStack só;
   - pilhaComum: a obra num VStack, em vez da LazyVStack. */
enum Sonda {
    #if DEBUG
    static let variante: String = UserDefaults.standard.string(forKey: "custta.sonda") ?? ""
    #else
    static let variante = ""
    #endif
    static var ligada: Bool { !variante.isEmpty }
    static var semPosicao: Bool { variante == "semPosicao" }
    static var semRefixar: Bool { variante == "semRefixar" }
    static var blocosSoltos: Bool { variante == "blocosSoltos" || variante == "olhosSoltos" }
    static var pilhaComum: Bool { variante == "pilhaComum" }
    static var comOlhos: Bool { variante == "olhos" || variante == "olhosSoltos" }

    private static let fila = DispatchQueue(label: "br.com.custta.sonda")
    nonisolated(unsafe) private static var saida: FileHandle?
    nonisolated(unsafe) private static var pasta: URL?
    nonisolated(unsafe) private static var vigiando = false
    nonisolated(unsafe) private static var refixas = 0
    /// Da rolagem da obra, só na thread principal (as ações do onScrollGeometryChange e do onScrollPhaseChange).
    nonisolated(unsafe) static var yAtual = 0.0
    nonisolated(unsafe) static var yLogado = 0.0
    nonisolated(unsafe) static var fase = "idle"

    /// Uma linha no log, com a hora (segundos desde 1970, com milésimos, a mesma régua do xcresult).
    static func log(_ texto: String) {
        guard ligada else { return }
        let t = Date.now.timeIntervalSince1970
        let linha = String(format: "%.3f", t) + " | " + variante + " | " + texto + "\n"
        fila.async {
            if saida == nil { abrir(t) }
            saida?.write(Data(linha.utf8))
        }
    }

    private static func abrir(_ t: Double) {
        let candidatas = [URL(fileURLWithPath: "/tmp/custta-sonda"), FileManager.default.temporaryDirectory]
        for candidata in candidatas {
            try? FileManager.default.createDirectory(at: candidata, withIntermediateDirectories: true)
            let url = candidata.appendingPathComponent("sonda-\(variante)-\(Int(t * 1000)).log")
            if FileManager.default.createFile(atPath: url.path, contents: nil), let h = try? FileHandle(forWritingTo: url) {
                saida = h
                pasta = candidata
                h.write(Data("pasta \(candidata.path)\n".utf8))
                return
            }
        }
    }

    /// O gancho da rolagem fixa reaplicou a rolagem: as 30 primeiras vão uma a uma, depois de 200 em 200.
    static func refixou(_ y: Double, alvo: Double) {
        guard ligada else { return }
        fila.async {
            refixas += 1
            let n = refixas
            if n <= 30 || n % 200 == 0 { log("refixa #\(n) y=\(Int(y)) alvo=\(Int(alvo))") }
        }
    }

    /// A vigia da thread principal: a cada 0,1 s, quanto ela leva para rodar um bloco. Parada acima de 250 ms vai para o
    /// log; presa há 4 s, deixa a marca /tmp/custta-sonda/presa para a CI tirar um `sample` do app.
    static func vigiar() {
        guard ligada else { return }
        fila.sync {
            guard !vigiando else { return }
            vigiando = true
        }
        log("vigia ligada; versão \(ProcessInfo.processInfo.operatingSystemVersionString)")
        Thread.detachNewThread {
            while true {
                let antes = Date.now
                let sinal = DispatchSemaphore(value: 0)
                DispatchQueue.main.async { sinal.signal() }
                var esperou = 0
                while sinal.wait(timeout: .now() + 2) == .timedOut {
                    esperou += 2
                    log("presa há \(esperou) s")
                    if esperou == 4 {
                        FileManager.default.createFile(atPath: "/tmp/custta-sonda/presa", contents: Data(variante.utf8))
                    }
                }
                let ms = Date.now.timeIntervalSince(antes) * 1000
                if ms > 250 { log("parada \(Int(ms)) ms") }
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
}

/// A rolagem como a sonda a vê: o deslocamento (com o recuo de cima), a altura do conteúdo e a da janela.
struct GeoDaSonda: Equatable {
    var y: Double
    var altura: Double
    var janela: Double
}

extension View {
    /// Log da rolagem, em todas as variantes: cada fase (com o y), pulo de mais de 40 pt entre duas mudanças, andança de mais
    /// de 120 pt desde a última linha (pega a volta feita em vários quadros) e altura do conteúdo que muda mais de 4 pt. Com a
    /// fase parada (`idle`), y que anda é volta sem dedo.
    @ViewBuilder func sondaDaRolagem(_ nome: String) -> some View {
        if Sonda.ligada {
            onScrollGeometryChange(for: GeoDaSonda.self) {
                GeoDaSonda(y: Double($0.contentOffset.y + $0.contentInsets.top), altura: Double($0.contentSize.height),
                           janela: Double($0.containerSize.height))
            } action: { antes, agora in
                Sonda.yAtual = agora.y
                let pulo = abs(agora.y - antes.y) > 40, andou = abs(agora.y - Sonda.yLogado) > 120
                if pulo || andou || abs(agora.altura - antes.altura) > 4 || antes.janela != agora.janela {
                    Sonda.yLogado = agora.y
                    Sonda.log("\(nome) geo [\(Sonda.fase)] y \(Int(antes.y))→\(Int(agora.y)) altura \(Int(antes.altura))→\(Int(agora.altura))"
                              + " janela \(Int(agora.janela))\(pulo ? " PULO" : "")")
                }
            }
            .onScrollPhaseChange { antes, agora in
                Sonda.fase = "\(agora)"
                Sonda.log("\(nome) fase \(antes)→\(agora) y \(Int(Sonda.yAtual))")
            }
        } else {
            self
        }
    }

    /// Log de uma peça da lista: quando entra, quando sai e quando muda de altura.
    @ViewBuilder func sondaPeca(_ nome: String) -> some View {
        if Sonda.comOlhos {
            onAppear { Sonda.log("aparece \(nome)") }
                .onDisappear { Sonda.log("some \(nome)") }
                .onGeometryChange(for: Double.self) { Double($0.size.height) } action: { Sonda.log("altura \(nome) \(Int($0))") }
        } else {
            self
        }
    }
}

/// A pilha da obra: a LazyVStack de sempre ou, com `pilhaComum`, um VStack com o mesmo espaço e o mesmo alinhamento.
struct PilhaDaSonda<Conteudo: View>: View {
    let espaco: CGFloat
    @ViewBuilder let conteudo: () -> Conteudo

    var body: some View {
        if Sonda.pilhaComum {
            VStack(alignment: .leading, spacing: espaco, content: conteudo)
        } else {
            LazyVStack(alignment: .leading, spacing: espaco, content: conteudo)
        }
    }
}

/// Os blocos do alto: um VStack só ou, com `blocosSoltos`, cada um como filho da LazyVStack da obra (o mesmo espaço).
struct PilhaDosBlocos<Conteudo: View>: View {
    @ViewBuilder let conteudo: () -> Conteudo

    var body: some View {
        if Sonda.blocosSoltos {
            Group(content: conteudo)
        } else {
            VStack(spacing: Grade.entreBlocos, content: conteudo)
        }
    }
}

/// A letra da tela no log (a auditoria de tipo dinâmico a troca), só com olhos.
struct SondaDaLetra: View {
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        Color.clear
            .accessibilityHidden(true)
            .onChange(of: letra, initial: true) { _, nova in if Sonda.comOlhos { Sonda.log("letra \(nova)") } }
    }
}

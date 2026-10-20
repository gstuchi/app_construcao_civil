import Testing
@testable import Custta
import CusttaNucleo

/* A tela Afazeres (etapa 3): o campo que para em 500 unidades UTF-16 como o maxlength do site, sem partir um emoji, e tira
   o "\n" do OK do teclado, que adiciona; o estado à vista do afazer tocado, que troca na hora e muda de lugar meio segundo
   depois; e o segundo toque que desiste. */
struct AfazeresTests {
    @Test func campoParaEm500UnidadesSemPartirEmoji() {
        #expect(limitadoAoAfazer("Comprar areia") == "Comprar areia")
        let quinhentos = String(repeating: "a", count: 500)
        #expect(limitadoAoAfazer(quinhentos) == quinhentos, "cabe até a 500ª unidade")
        #expect(limitadoAoAfazer(quinhentos + "a") == quinhentos)
        #expect(limitadoAoAfazer(String(repeating: "a", count: 499) + "🧱b") == String(repeating: "a", count: 499),
                "corta no tijolo, como o maxlength: o b depois dele não entra")
        #expect(limitadoAoAfazer(String(repeating: "a", count: 498) + "🧱b") == String(repeating: "a", count: 498) + "🧱",
                "o tijolo que cabe inteiro fica")
    }

    /// O que o campo guarda do texto que o teclado deixou nele: o "OK" chega como "\n", que sai e adiciona, e o guardado
    /// nunca passa de 500 (o + grava o guardado, então nunca fica calado com o campo cheio).
    @Test func campoTiraOOKECortaEm500() {
        let quinhentos = String(repeating: "a", count: 500)
        let digitando = textoDoCampoDoAfazer("Comprar areia")
        #expect(digitando.texto == "Comprar areia" && !digitando.adiciona)
        let ok = textoDoCampoDoAfazer("Comprar areia\n")
        #expect(ok.texto == "Comprar areia" && ok.adiciona, "o OK sai do texto e adiciona")
        let cheio = textoDoCampoDoAfazer(quinhentos + "aa")
        #expect(cheio.texto == quinhentos && !cheio.adiciona, "a rajada que passa de 500 fica nos 500")
        let okCheio = textoDoCampoDoAfazer(quinhentos + "a\n")
        #expect(okCheio.texto == quinhentos && okCheio.adiciona, "o OK com a tela acima de 500 adiciona os 500")
        let okNoMeio = textoDoCampoDoAfazer(String(repeating: "a", count: 499) + "\nb")
        #expect(okNoMeio.texto == String(repeating: "a", count: 499) + "b" && okNoMeio.adiciona, "o \\n sai antes do corte")
    }

    @Test func estadoAVistaTrocaNaHoraDoToque() {
        let pendente = Afazer(campos: ["id": .texto("a1"), "texto": .texto("Pagar o gesso"), "feito": .booleano(false)])
        let feito = Afazer(campos: ["id": .texto("a2"), "texto": .texto("Ver o reboco"), "feito": .booleano(true)])
        #expect(!feitoAVista(pendente, trocando: []))
        #expect(feitoAVista(pendente, trocando: ["a1"]), "marcado agora: o círculo enche antes de a linha mudar de lugar")
        #expect(feitoAVista(feito, trocando: []))
        #expect(!feitoAVista(feito, trocando: ["a2"]), "desmarcado agora")
        #expect(feitoAVista(feito, trocando: ["a1"]), "o toque em outro não muda este")
    }

    /// Um segundo toque no meio segundo entre o círculo trocar e a linha mudar de lugar desiste, e nada é gravado (dois
    /// toques seguidos marcam e desmarcam, como no site). O toque duplo do XCUITest chega a esta linha como um toque só.
    @Test func segundoToqueNoMeioDoCaminhoDesiste() {
        var trocas = TrocasPendentes()
        let primeiro = trocas.tocar("a1")
        #expect(primeiro, "o primeiro toque pede a troca")
        #expect(trocas.ids == ["a1"], "o círculo já mostra o estado novo")
        let segundo = trocas.tocar("a1"), gravouDesistido = trocas.confirmar("a1")
        #expect(!segundo, "o segundo, antes do meio segundo, desiste")
        #expect(!gravouDesistido, "e nada é gravado")
        let deNovo = trocas.tocar("a1"), outro = trocas.tocar("a2")
        #expect(deNovo && outro, "um afazer não atrapalha o outro")
        let gravou = trocas.confirmar("a1"), gravouDeNovo = trocas.confirmar("a1")
        #expect(gravou, "meio segundo depois, grava")
        #expect(!gravouDeNovo, "uma vez só")
        #expect(trocas.ids == ["a2"])
    }
}

import Testing
@testable import CusttaNucleo

extension ValorJSON {
    /// Uma lista de afazeres dos vetores (ausente conta como vazia, como no site).
    var afazeres: [Afazer] { (comoLista ?? []).compactMap { $0.comoObjeto.map(Afazer.init(campos:)) } }
}

func jsonDosAfazeres(_ l: [Afazer]?) -> ValorJSON { l.map { .lista($0.map { .objeto($0.campos) }) } ?? .nulo }

struct AfazeresTests {
    @Test func conferirComoOSite() {
        for c in Vetores.casos("dados.conferirAfazer") {
            let r: ValorJSON = switch conferirAfazer(c.args[0].comoTexto!) {
            case .ok(let texto): .objeto(["texto": .texto(texto)])
            case .vazio: .objeto(["erro": .texto("vazio")])
            case .longo(let mensagem): .objeto(["erro": .texto("afazer"), "mensagem": .texto(mensagem)])
            }
            confere(r, c.saida, .exata, c.caso)
        }
    }

    @Test func novoNoComeco() {
        for c in Vetores.casos("dados.afazeresComNovo") {
            confere(jsonDosAfazeres(afazeresComNovo(c.args[0].afazeres, texto: c.args[1].comoTexto!, id: c.args[2].comoTexto!)), c.saida, .exata, c.caso)
        }
    }

    @Test func marcarEDesmarcarLevamAoComeco() {
        for c in Vetores.casos("dados.afazeresAlternado") {
            confere(jsonDosAfazeres(afazeresAlternado(c.args[0].afazeres, id: c.args[1].comoTexto!)), c.saida, .exata, c.caso)
        }
    }

    @Test func apagarSemPerguntar() {
        for c in Vetores.casos("dados.afazeresSem") {
            confere(jsonDosAfazeres(afazeresSem(c.args[0].afazeres, id: c.args[1].comoTexto!)), c.saida, .exata, c.caso)
        }
    }

    @Test func pendentesAntesDosFeitos() {
        for c in Vetores.casos("calc.afazeresEmOrdem") {
            confere(jsonDosAfazeres(afazeresEmOrdem(c.arg(0)?.afazeres ?? [])), c.saida, .exata, c.caso)
        }
    }

    @Test func contadorDosPendentes() {
        for c in Vetores.casos("calc.contadorDeAfazeres") {
            confere(.texto(contadorDeAfazeres(c.arg(0)?.afazeres ?? [])), c.saida, .exata, c.caso)
        }
    }
}

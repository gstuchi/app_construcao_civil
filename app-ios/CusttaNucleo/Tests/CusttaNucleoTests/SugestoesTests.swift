import Testing
@testable import CusttaNucleo

/// As obras de um caso dos vetores (lista de objetos, normalizada ou não).
func obrasDoCaso(_ v: ValorJSON) -> [Obra] { (v.comoLista ?? []).compactMap { $0.comoObjeto.map(Obra.init(arvore:)) } }

extension SugestaoDeDescricao {
    var json: ValorJSON {
        .objeto(["texto": .texto(texto), "chave": .texto(chave), "vezes": .numero(Double(vezes)),
                 "mesmaObra": .booleano(mesmaObra), "mesmoTopico": .booleano(mesmoTopico), "ultima": .texto(ultima)])
    }
}

struct SugestoesTests {
    @Test func descricaoComparavel() {
        for c in Vetores.casos("calc.normalizaDescricao") {
            confere(.texto(normalizaDescricao(c.arg(0)?.comoTexto)), c.saida, .exata, c.caso)
        }
    }

    @Test func distanciaDeEdicaoEmUTF16() {
        for c in Vetores.casos("calc.distanciaEdicao") {
            confere(.numero(Double(distanciaEdicao(c.args[0].comoTexto!, c.args[1].comoTexto!))), c.saida, .exata, c.caso)
        }
    }

    @Test func sugestoesComOsPesosEODesempateDoSite() {
        for c in Vetores.casos("calc.sugestoesDescricao") {
            let r = sugestoesDescricao(obrasDoCaso(c.args[0]), obraId: c.args[1].comoTexto!, topicoId: c.args[2].comoTexto!,
                                       termo: c.args[3].comoTexto!, ignorarId: c.args[4].comoTexto)
            confere(.lista(r.map(\.json)), c.saida, .exata, c.caso)
        }
    }

    @Test func contextoDaSugestao() {
        let base = SugestaoDeDescricao(texto: "Cimento", chave: "cimento", vezes: 1, mesmaObra: false, mesmoTopico: false, ultima: "2026-01-01")
        #expect(base.contexto == "1× usado")
        #expect(SugestaoDeDescricao(texto: "Cimento", chave: "cimento", vezes: 3, mesmaObra: true, mesmoTopico: true, ultima: "").contexto == "mesmo tópico")
    }

    @Test func gastoRepetidoComoOSite() {
        for c in Vetores.casos("calc.gastoRepetido") {
            let obra = Obra(arvore: c.args[0].comoObjeto!)
            let r = gastoRepetido(obra, descricao: c.args[1].comoTexto!, valor: c.args[2].numero, data: c.args[3].comoTexto!,
                                  ignorarId: c.args[4].comoTexto)
            confere(.booleano(r), c.saida, .exata, c.caso)
        }
    }

    @Test func taxaDoCartaoComoOFormularioLe() {
        for c in Vetores.casos("calc.lerTaxaCartao") {
            let n = lerTaxaCartao(c.arg(0)?.comoTexto)
            confere(n.isFinite ? .numero(n) : .nulo, c.saida, .exata, c.caso)
        }
    }
}

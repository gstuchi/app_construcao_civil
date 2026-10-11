import Testing
@testable import CusttaNucleo

private func texto(_ v: ValorJSON?) -> String? {
    switch v {
    case .texto(let s)?: return s
    case .numero(let n)?: return numeroJS(n)
    default: return nil
    }
}

extension ResultadoSenha {
    var json: ValorJSON {
        .objeto(["ok": .booleano(ok), "erro": .texto(erro),
                 "regras": .lista(regras.map { .objeto(["id": .texto($0.id), "texto": .texto($0.texto), "ok": .booleano($0.ok)]) })])
    }
}
extension ResultadoPerfil {
    var json: ValorJSON {
        .objeto(["ok": .booleano(ok), "campo": .texto(campo), "erro": .texto(erro), "perfil": perfil.map { .objeto($0.campos) } ?? .nulo])
    }
}

struct CadastroTests {
    @Test func constantesIguaisAoSite() {
        #expect(.lista(regrasSenha.map { .objeto(["id": .texto($0.id), "texto": .texto($0.texto)]) }) == Vetores.casos("cadastro.REGRAS_SENHA")[0].saida)
        let o = origens.map { o -> ValorJSON in
            var c: [String: ValorJSON] = ["id": .texto(o.id), "nome": .texto(o.nome)]
            if let d = o.detalhe { c["detalhe"] = .texto(d) }
            return .objeto(c)
        }
        #expect(.lista(o) == Vetores.casos("cadastro.ORIGENS")[0].saida)
        #expect(.objeto(["nome": .numero(60), "sobrenome": .numero(80), "origemDetalhe": .numero(80)]) == Vetores.casos("cadastro.LIMITES_PERFIL")[0].saida)
        #expect(LimitesPerfil.nome == 60 && LimitesPerfil.sobrenome == 80 && LimitesPerfil.origemDetalhe == 80)
    }

    @Test func senha() {
        for c in Vetores.casos("cadastro.validaSenha") {
            confere(validaSenha(texto(c.arg(0)), email: texto(c.arg(1))).json, c.saida, .exata, c.caso)
        }
    }

    @Test func nome() {
        for c in Vetores.casos("cadastro.normalizaNome") {
            let d = c.arg(0)?.comoObjeto
            confere(normalizaNome(nome: texto(d?["nome"]), sobrenome: texto(d?["sobrenome"])).json, c.saida, .exata, c.caso)
        }
    }

    @Test func perfil() {
        for c in Vetores.casos("cadastro.normalizaPerfil") {
            let d = c.arg(0)?.comoObjeto
            let opcional = c.arg(1)?.comoObjeto?["nomeOpcional"] == .booleano(true)
            let r = normalizaPerfil(nome: texto(d?["nome"]), sobrenome: texto(d?["sobrenome"]), origem: texto(d?["origem"]),
                                    origemDetalhe: texto(d?["origemDetalhe"]), nomeOpcional: opcional)
            confere(r.json, c.saida, .exata, c.caso)
        }
    }

    @Test func nomeVindoDoGoogleOuDaApple() {
        for c in Vetores.casos("cadastro.nomeDoGoogle") {
            let (n, s) = nomeDoGoogle(texto(c.arg(0)))
            #expect(ValorJSON.objeto(["nome": .texto(n), "sobrenome": .texto(s)]) == c.saida, "\(c.caso)")
        }
    }

    @Test func mensagensDeErro() {
        for c in Vetores.casos("cadastro.mensagemErroSocial") {
            #expect(mensagemErroSocial(codigo: texto(c.arg(0)), provedor: texto(c.arg(1))) == c.saida.comoTexto, "\(c.caso)")
        }
        for c in Vetores.casos("cadastro.mensagemErroGoogle") {
            #expect(mensagemErroSocial(codigo: texto(c.arg(0)), provedor: "google.com") == c.saida.comoTexto, "\(c.caso)")
        }
        for c in Vetores.casos("cadastro.mensagemErroSenha") {
            #expect(mensagemErroSenha(codigo: texto(c.arg(0)), tela: texto(c.arg(1))) == c.saida.comoTexto, "\(c.caso)")
        }
    }
}

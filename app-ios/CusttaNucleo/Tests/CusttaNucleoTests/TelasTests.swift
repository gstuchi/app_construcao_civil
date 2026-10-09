import Testing
@testable import CusttaNucleo

struct TelasTests {
    /// Saídas do /^\S+@\S+\.\S+$/ do auth.js, conferidas no Node.
    @Test func emailComoORegexDoSite() {
        let casos: [(String, Bool)] = [("a@b.c", true), ("joao@exemplo.com", true), ("a@@b.c", true), ("a@b.", false), ("a@.b", false),
            ("a.b@c", false), ("@b.c", false), ("a@b", false), ("a b@c.d", false), (" a@b.c", false), ("a@b.c ", false), ("a@b.c.d", true),
            ("a@b..c", true), ("ção@é.br", true), ("a@b\u{00A0}.c", false), ("", false), ("a@.b.c", true), ("a.@b.c", true)]
        for (email, esperado) in casos { #expect(emailParece(email) == esperado, "\(email)") }
    }

    @Test func entrarPedeEmailESenha() {
        #expect(validarEntrada(email: "joao", senha: "x") == "Digite seu e-mail.")
        #expect(validarEntrada(email: " joao@exemplo.com ", senha: "") == "Digite a senha.")
        #expect(validarEntrada(email: "joao@exemplo.com", senha: "x") == nil)
    }

    @Test func cadastroNaOrdemDoSite() {
        func v(nome: String = "Ana", email: String = "ana@exemplo.com", senha: String = "Casa2026x", confirmacao: String = "Casa2026x",
               origem: String? = "google", detalhe: String = "") -> ResultadoCadastro {
            validarCadastro(nome: nome, sobrenome: "", email: email, senha: senha, confirmacao: confirmacao, origem: origem, origemDetalhe: detalhe)
        }
        #expect(v(nome: "A", email: "errado", senha: "x", confirmacao: "y", origem: nil) == .falhou(campo: "nome", erro: "O nome precisa de pelo menos 2 letras."))
        #expect(v(email: "errado", senha: "x", confirmacao: "y", origem: nil) == .falhou(campo: "email", erro: "E-mail inválido."))
        #expect(v(senha: "curta1", confirmacao: "y", origem: nil) == .falhou(campo: "senha", erro: "Use pelo menos 8 caracteres."))
        #expect(v(confirmacao: "outra", origem: nil) == .falhou(campo: "confirmacao", erro: "As senhas não são iguais."))
        #expect(v(origem: nil) == .falhou(campo: "origem", erro: "Conte como conheceu o Custta."))
        #expect(v(origem: "outro", detalhe: String(repeating: "z", count: 81)) == .falhou(campo: "origemDetalhe", erro: "Use no máximo 80 caracteres."))
        #expect(v() == .ok(PerfilCadastro(nome: "Ana", origem: "google")))
    }

    @Test func listaDeObrasNaOrdemDoSite() {
        let estado = Estado.de(.objeto(["obras": .lista([
            .objeto(["id": .texto("v"), "nome": .texto("Vendida nova"), "dataInicio": .texto("2026-05-01"), "fase": .texto("vendida"),
                     "venda": .objeto(["valor": .numero(1), "data": .texto("2026-06-01")])]),
            .objeto(["id": .texto("a"), "nome": .texto("Antiga"), "dataInicio": .texto("2024-01-01")]),
            .objeto(["id": .texto("n"), "nome": .texto("Nova"), "dataInicio": .texto("2026-01-01"), "fase": .texto("pronta")]),
        ])]))
        #expect(obrasOrdenadas(estado.obras).map(\.id) == ["n", "a", "v"])
        #expect(estado.obras.map(\.fase.rotulo) == ["Vendida", "Em construção", "Pronta · à venda"])
    }

    @Test func textoDoOrcamentoNaLista() {
        func obra(total: Double, gasto: Double) -> Obra {
            Estado.de(.objeto(["obras": .lista([.objeto(["id": .texto("o"), "dataInicio": .texto("2026-01-01"),
                "orcamento": .objeto(["modo": .texto("total"), "total": .numero(total)]),
                "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(gasto), "data": .texto("2026-01-02")])])])])])).obras[0]
        }
        #expect(textoOrcamentoNaLista(orcamentoObra(obra(total: 100_000, gasto: 45_000))!) == "45% do orçamento")
        #expect(textoOrcamentoNaLista(orcamentoObra(obra(total: 100_000, gasto: 108_000))!) == "108% · passou R$ 8 mil")
    }

    /// Valores do totalCorrigido do calc.js, conferidos no Node.
    @Test func comparativoComoODoSite() {
        let estado = Estado.de(.objeto(["obras": .lista([
            .objeto(["id": .texto("b"), "nome": .texto("B"), "dataInicio": .texto("2025-01-01"), "fase": .texto("vendida"),
                     "venda": .objeto(["valor": .numero(1), "data": .texto("2026-01-01")]),
                     "gastos": .lista([.objeto(["id": .texto("h"), "valor": .numero(50_000), "data": .texto("2025-01-01")])])]),
            .objeto(["id": .texto("s"), "nome": .texto("Sem gasto"), "dataInicio": .texto("2026-02-01")]),
            .objeto(["id": .texto("a"), "nome": .texto("A"), "dataInicio": .texto("2026-01-01"),
                     "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(100_000), "data": .texto("2026-01-01")])])]),
        ])]))
        let linhas = comparativoEntreObras(estado.obras, taxa: 1, hoje: "2026-07-01")
        #expect(linhas.map(\.id) == ["a", "b"], "só as obras com gasto, na ordem da lista")
        #expect(abs(linhas[0].corrigido - 106_095.12340622896) < 1e-6)
        #expect(abs(linhas[1].corrigido - 56_336.09497694363) < 1e-6, "a vendida corrige até a venda")
        #expect(linhas[0].fracaoCorrigido == 1)
        #expect(abs(linhas[1].fracaoBruto - 50_000 / 106_095.12340622896) < 1e-12)
        #expect(comparativoEntreObras(Array(estado.obras.prefix(2)), taxa: 1, hoje: "2026-07-01").isEmpty,
                "com uma só obra com gasto não há comparativo")
    }

    @Test func erroDeLeituraDizQueNadaFoiAlterado() {
        #expect(textoErroDeLeitura("formato-desconhecido").contains("formato"))
        for codigo in ["formato-desconhecido", "permission-denied", "unavailable"] {
            #expect(textoErroDeLeitura(codigo).contains("Nada foi alterado"), "\(codigo)")
        }
    }

    @Test func nonceDaApple() {
        let n = Nonce.gerar()
        #expect(n.count == 64 && n.allSatisfy(\.isHexDigit))
        #expect(Nonce.gerar() != n)
        #expect(Nonce.sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}

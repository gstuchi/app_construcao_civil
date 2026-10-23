import Foundation

/* Os afazeres como o site os grava e mostra: adicionar, marcar, desmarcar e apagar (dados.js), a ordem da lista e o contador
   (calc.js). Marcar e desmarcar levam o afazer ao começo da lista: mostrada em pendentes e depois feitos, cada grupo na ordem
   da lista, o recém-marcado fica no alto dos feitos e o desmarcado volta ao alto dos pendentes. Campos que o app não conhece
   ficam em cada afazer. Cada regra tem caso nos vetores. */

public enum ConferenciaDoAfazer: Equatable, Sendable {
    /// O texto aparado, pronto para gravar.
    case ok(String)
    /// Nada a fazer (o campo fica com o foco).
    case vazio
    case longo(mensagem: String)
}

/// `conferirAfazer` do dados.js: o texto aparado; vazio não faz nada; até 500 unidades UTF-16.
public func conferirAfazer(_ texto: String) -> ConferenciaDoAfazer {
    let t = aparadoJS(texto)
    if t.isEmpty { return .vazio }
    if t.utf16.count > Limites.afazer { return .longo(mensagem: "Use até \(Limites.afazer) caracteres.") }
    return .ok(t)
}

/// `afazeresComNovo` do dados.js: o novo no começo da lista, pendente (texto já conferido).
public func afazeresComNovo(_ lista: [Afazer], texto: String, id: String) -> [Afazer] {
    [Afazer(campos: ["id": .texto(id), "texto": .texto(texto), "feito": .booleano(false)])] + lista
}

/// `afazeresAlternado` do dados.js: o feito trocado e o afazer no começo da lista; nil se o id sumiu.
public func afazeresAlternado(_ lista: [Afazer], id: String) -> [Afazer]? {
    guard let i = lista.firstIndex(where: { $0.id == id }) else { return nil }
    var resto = lista
    var afazer = resto.remove(at: i)
    afazer.feito.toggle()
    return [afazer] + resto
}

/// `afazeresSem` do dados.js: sem o afazer (todos com o id); nil se o id sumiu.
public func afazeresSem(_ lista: [Afazer], id: String) -> [Afazer]? {
    guard lista.contains(where: { $0.id == id }) else { return nil }
    return lista.filter { $0.id != id }
}

/// `afazeresEmOrdem` do calc.js: pendentes e depois feitos, cada grupo na ordem da lista.
public func afazeresEmOrdem(_ lista: [Afazer]) -> [Afazer] { lista.filter { !$0.feito } + lista.filter(\.feito) }

/// `contadorDeAfazeres` do calc.js: "(N pendente)", "(N pendentes)" ou nada.
public func contadorDeAfazeres(_ lista: [Afazer]) -> String {
    let n = lista.filter { !$0.feito }.count
    return n == 0 ? "" : "(\(n) pendente\(n > 1 ? "s" : ""))"
}

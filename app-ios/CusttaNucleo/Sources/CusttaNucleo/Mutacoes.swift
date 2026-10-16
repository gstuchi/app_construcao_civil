import Foundation

/* As mudanças que as telas que gravam fazem no estado, como o site faz no `db` antes do `save()`: cada uma parte do
   estado do momento (não de uma cópia guardada quando a folha abriu) e devolve o estado novo (o app grava pelo
   Sincronizador) ou nil quando a obra ou o gasto sumiram (apagados em outro aparelho com a folha aberta; o site, nesse
   caso, também não grava nada). Campos que o app não conhece ficam. */
public extension Estado {
    func indiceDaObra(_ id: String) -> Int? { obras.firstIndex { $0.id == id } }

    /// Os gastos novos no fim da obra, como o `push` do site.
    func lancandoGastos(_ novos: [Gasto], naObra obraId: String) -> Estado? {
        guard let i = indiceDaObra(obraId) else { return nil }
        var e = self
        e.obras[i].gastos.append(contentsOf: novos)
        return e
    }

    /// O gasto editado, montado a partir do que está no estado agora, como o site faz com o `o.gastos[i]` do momento do
    /// "Salvar": o que outro aparelho mudou no gasto com a folha aberta fica, menos o que a pessoa respondeu.
    func editandoGasto(_ gastoId: String, _ entrada: EntradaDoGasto, _ conferido: GastoConferido, naObra obraId: String) -> Estado? {
        guard let i = indiceDaObra(obraId), let j = obras[i].gastos.firstIndex(where: { $0.id == gastoId }) else { return nil }
        var e = self
        e.obras[i].gastos[j] = gastoEditado(obras[i].gastos[j], entrada, conferido)
        return e
    }

    /// Sem o gasto: o "Apagar" de um gasto, ou de uma parcela só.
    func apagandoGasto(_ gastoId: String, daObra obraId: String) -> Estado? {
        guard let i = indiceDaObra(obraId), obras[i].gastos.contains(where: { $0.id == gastoId }) else { return nil }
        var e = self
        e.obras[i].gastos.removeAll { $0.id == gastoId }
        return e
    }

    /// Sem nenhuma parcela da compra: o "Apagar a compra toda" (as que restam com o mesmo `grupoId`).
    func apagandoCompra(_ grupoId: String, daObra obraId: String) -> Estado? {
        guard let i = indiceDaObra(obraId), obras[i].gastos.contains(where: { $0.grupoId == grupoId }) else { return nil }
        var e = self
        e.obras[i].gastos.removeAll { $0.grupoId == grupoId }
        return e
    }
}

/* As da obra e das fases (app.js formNovaObra, formEditarObra, formVenda, mudarFase e o desfazer da venda). A fase só
   anda pelos caminhos que a tela oferece: quem a mudou em outro aparelho com esta tela aberta não é atropelado (nil). */
public extension Estado {
    /// A obra nova (de `obraNova`) no fim do documento, como o `push` do site; nil com o teto de obras cheio (a obra a mais
    /// faria toda gravação seguinte ser recusada pelas rules até apagar uma).
    func criandoObra(_ arvore: [String: ValorJSON]) -> Estado? {
        guard obras.count < limiteDeObras else { return nil }
        var e = self
        e.obras.append(Obra(arvore: arvore))
        return e
    }

    /// Nome, início, valor estimado e área pela regra do `obraEditada`; o resto da obra fica.
    func editandoObra(_ obraId: String, _ campos: CamposDaObra) -> Estado? {
        guard let i = indiceDaObra(obraId) else { return nil }
        var e = self
        e.obras[i].campos = obraEditada(obras[i].campos, campos)
        return e
    }

    func apagandoObra(_ obraId: String) -> Estado? {
        guard let i = indiceDaObra(obraId) else { return nil }
        var e = self
        e.obras.remove(at: i)
        return e
    }

    /// O `mudarFase` do site, só entre construção e pronta: vender é pela folha da venda, e da vendida só se sai desfazendo.
    func mudandoFase(_ obraId: String, para fase: Fase) -> Estado? {
        guard let i = indiceDaObra(obraId), fase != .vendida, obras[i].fase != .vendida else { return nil }
        var e = self
        e.obras[i].fase = fase
        return e
    }

    /// "Confirmar venda": `venda {valor, data}` e a fase vendida, só a partir da pronta. Valor e data já conferidos
    /// (`conferirVenda`).
    func registrandoVenda(_ obraId: String, valor: Double, data: String) -> Estado? {
        guard let i = indiceDaObra(obraId), obras[i].fase == .pronta else { return nil }
        var e = self
        e.obras[i].venda = Venda(valor: valor, data: data)
        e.obras[i].fase = .vendida
        return e
    }

    /// "Desfazer venda": a chave `venda` sai (o `delete` do site, não `null`) e a obra volta para pronta.
    func desfazendoVenda(_ obraId: String) -> Estado? {
        guard let i = indiceDaObra(obraId), obras[i].fase == .vendida else { return nil }
        var e = self
        e.obras[i].campos["venda"] = nil
        e.obras[i].fase = .pronta
        return e
    }
}

/// As parcelas que restam da compra do gasto (o N do "Apagar a compra toda (N parcelas)", contado como o site: as irmãs
/// que ainda existem, não o `parcela.de`).
public func parcelasDaCompra(_ gasto: Gasto, naObra obra: Obra) -> Int {
    guard let grupo = gasto.grupoId else { return 1 }
    return obra.gastos.filter { $0.grupoId == grupo }.count
}

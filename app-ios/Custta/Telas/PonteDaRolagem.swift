import SwiftUI
import UIKit
#if DEBUG
import notify
#endif

/* A ponte do UIKit para rolar a obra até uma peça. A obra é uma List (UICollectionView), e o scrollTo dela só acha a linha,
   que é o cartão do mês inteiro (na maior letra, um mês da obra pesada passa de 13 mil pt), trata a âncora fracionária como
   o centro e não rola uma linha que já está na tela: a 1ª parcela de uma compra no cartão parava fora da tela, e a lupa não
   levava a pílula ao topo. A ponte guarda uma marca (uma vista vazia) por chave: em cada linha acesa depois de salvar (o id
   do gasto) e na pílula ("lancamentos"). Da marca, ela sobe até a rolagem que a contém, a da List; o quadro da marca,
   convertido para a rolagem, diz onde a peça está no conteúdo, e a rolagem anda até ela. A ponte tenta uma vez por
   quadro, até a lista parar de se medir, sem forçar o layout: um cartão gigante se mediria de novo, de uma vez, na thread
   principal.
   Quando o Tamanho do Texto muda com a obra rolada, a ponte segura a linha que estava no alto (a List guardaria o número da
   rolagem, e a tela iria para outro lugar). Ela conhece a List pela marca da 1ª linha, que está na tela quando a obra abre.
   RISCO: a ponte depende de a List ser uma UICollectionView com as vistas da linha dentro dela, que é detalhe do SwiftUI. Se
   um iOS novo mudar isso, ela não acha a rolagem ou a marca e não rola: a lista fica no topo do cartão, e os testes da maior
   letra (GastoUITests, ObraUITests) e o da busca caem e avisam. */
@MainActor
final class PonteDaRolagem {
    private var marcas: [String: Fraca] = [:]

    private final class Fraca {
        weak var vista: MarcaDaLinha.Vista?
        init(_ vista: MarcaDaLinha.Vista) { self.vista = vista }
    }

    func marcar(_ vista: MarcaDaLinha.Vista, chave: String) {
        vista.chave = chave
        marcas[chave] = Fraca(vista)
    }

    /// A marca saiu da linha (ou trocou de chave): a chave dela deixa de apontar para essa vista.
    func esquecer(_ vista: MarcaDaLinha.Vista) {
        if let chave = vista.chave, marcas[chave]?.vista === vista { marcas[chave] = nil }
    }

    /// A rolagem em que a marca da chave está, se ela está na tela: a da List, e não uma rolagem de dentro da linha.
    private func rolagem(de chave: String) -> (UIScrollView, UIView)? {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "custta.semPonte") { return nil }   // o caminho manso, para o teste que o reprova
        #endif
        // A vista guarda a chave: se o SwiftUI a reaproveitou noutra linha, a chave velha não acha a linha errada.
        guard let marca = marcas[chave]?.vista, marca.chave == chave, marca.window != nil else { return nil }
        var vista = marca.superview
        while let atual = vista, !(atual is UICollectionView) { vista = atual.superview }
        return (vista as? UICollectionView).map { ($0, marca) }
    }

    #if DEBUG
    /// Testes de tela: o caminho que a rolagem até o gasto salvo tomou, num aviso do sistema ("…ponte.direto", direto ao gasto
    /// à vista; "…ponte.cartao", pelo topo do cartão do mês). O GastoUITests confere que a edição com a linha à vista vai direto.
    func avisarCaminho(direto: Bool) {
        notify_post(direto ? "br.com.custta.falso.ponte.direto" : "br.com.custta.falso.ponte.cartao")
    }
    #endif

    /// Tenta uma vez por quadro, até `quadros` vezes: quando a marca da peça está na tela e a altura do conteúdo é a mesma
    /// em dois quadros seguidos (a lista parou de se medir), rola até o ponto `fracao` dela (o meio do gasto; o topo da
    /// pílula). Devolve se rolou; sem a marca, a lista fica onde está. Nada força o layout: a lista se mede no tempo dela.
    /// Com `insistir`, se a lista não assenta nesses quadros, rola com a última medida (a lupa: sem isso, a pílula ficava onde
    /// estava e o campo podia ficar sob o teclado).
    @discardableResult func rolarQuandoAssentar(ate chave: String, a fracao: CGFloat = 0.5, quadros: Int,
                                                animado: Bool, insistir: Bool = false) async -> Bool {
        var anterior: CGFloat?
        for _ in 0..<quadros {
            try? await Task.sleep(for: .milliseconds(16))
            guard let (rolagem, _) = rolagem(de: chave) else { anterior = nil; continue }
            let altura = rolagem.contentSize.height
            if altura == anterior { return rolar(chave, a: fracao, animado: animado) }
            anterior = altura
        }
        return insistir && rolar(chave, a: fracao, animado: animado)
    }

    /// A tentativa direta do `mostrar`: procura a marca do gasto por `procurar` quadros; achada, espera a lista parar de se
    /// medir (até `quadros`) e rola até o meio dela, com a última medida se ela não assentar. Só devolve falso quando a marca
    /// não aparece: a célula ainda se medindo (a etiqueta "novo" quebrando a linha) não manda a obra pelo cartão, o salto que
    /// o conselho descartou, e o caminho direto não depende de a lista assentar em três quadros numa VM lenta.
    func rolarSeAVista(ate chave: String, procurar: Int = 3, quadros: Int = 60, animado: Bool) async -> Bool {
        var anterior: CGFloat?
        var achou = false
        for i in 0..<quadros {
            try? await Task.sleep(for: .milliseconds(16))
            guard let (rolagem, _) = rolagem(de: chave) else {
                if !achou && i + 1 >= procurar { return false }
                anterior = nil
                continue
            }
            achou = true
            let altura = rolagem.contentSize.height
            if altura == anterior { return rolar(chave, a: 0.5, animado: animado) }
            anterior = altura
        }
        return achou && rolar(chave, a: 0.5, animado: animado)
    }

    // MARK: A letra que muda com a obra rolada

    private weak var lista: UICollectionView?

    /// A janela da List na tela inteira (a rolagem passa por baixo da barra e do teclado): o teclado da busca mede o campo
    /// contra ela (ObraView.campoForaDaJanela).
    var janela: CGRect? { lista?.window?.bounds }
    private var observacao: NSKeyValueObservation?
    /// A linha no alto da parte à vista e onde, dentro dela, a parte à vista começa (0 é o topo da linha, 1 o fim).
    private var alto: (indice: IndexPath, fracao: CGFloat)?
    private var segurarAte = Date.distantPast
    /// Quadros seguidos com a mesma altura do conteúdo, desde a última mudança.
    private var estavel = 0

    /// A List da obra, achada pela marca da 1ª linha, que está na tela quando a obra abre.
    func conhecer(_ marca: UIView) {
        var vista = marca.superview
        while let atual = vista, !(atual is UICollectionView) { vista = atual.superview }
        guard let lista = vista as? UICollectionView, lista !== self.lista else { return }
        self.lista = lista
        observacao = lista.observe(\.contentOffset, options: [.new]) { [weak self] lista, _ in
            MainActor.assumeIsolated { self?.guardarOAlto(lista) }
        }
        lista.registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { [weak self] (lista: UICollectionView, _: UITraitCollection) in
            MainActor.assumeIsolated { self?.segurarOAltoAteAssentar(lista) }
        }
    }

    private func guardarOAlto(_ lista: UICollectionView) {
        guard Date.now > segurarAte else { return }
        let topo = lista.contentOffset.y + lista.adjustedContentInset.top
        let primeira = lista.indexPathsForVisibleItems
            .compactMap { indice in lista.layoutAttributesForItem(at: indice).map { (indice, $0.frame) } }
            .filter { $0.1.maxY > topo }
            .min { $0.1.minY < $1.1.minY }
        alto = primeira.map { ($0.0, max(0, topo - $0.1.minY) / max(1, $0.1.height)) }
    }

    /// O filtro da busca mudou os dados: a List volta as linhas de cima da tela à altura estimada e, na VM lenta da CI, nem
    /// sempre compensa a rolagem; a pílula subia 160 pt, com o campo sob a barra (2 de 6). Segura a linha do alto como na
    /// letra que muda. Outra mudança de dados com a busca aberta (outro aparelho apaga um gasto) não passa por aqui.
    func segurarOAlto() {
        guard let lista else { return }
        segurarOAltoAteAssentar(lista)
    }

    /// O Tamanho do Texto mudou (ou o filtro da busca): a List mede as linhas de novo e guarda o número da rolagem, e a tela
    /// vai para outro lugar (na ida e volta da letra, as linhas de cima ficam na altura estimada, e a obra rolada parava num
    /// mês lá embaixo). A ponte segura a linha que estava no alto, no mesmo ponto dela, a cada quadro, até a lista parar de se
    /// medir (a mesma altura do conteúdo por 10 quadros), com teto de 3 s; um arrasto, ou a lista deslizando depois dele,
    /// solta.
    private func segurarOAltoAteAssentar(_ lista: UICollectionView) {
        #if DEBUG
        if UserDefaults.standard.object(forKey: "custta.rolagem") != nil { return }   // o gancho dos testes segura
        if UserDefaults.standard.bool(forKey: "custta.semPonte") { return }           // o caminho manso, para o teste que o reprova
        #endif
        guard let alto else { return }
        let segurando = Date.now < segurarAte
        segurarAte = Date.now.addingTimeInterval(3)
        estavel = 0
        guard !segurando else { return }
        Task { @MainActor in
            var anterior: CGFloat?
            while Date.now < segurarAte {
                try? await Task.sleep(for: .milliseconds(16))
                if lista.isTracking || lista.isDragging || lista.isDecelerating { segurarAte = .distantPast; break }
                let altura = lista.contentSize.height
                estavel = altura == anterior ? estavel + 1 : 0
                anterior = altura
                if estavel >= 10 { segurarAte = .distantPast; break }
                guard alto.indice.section < lista.numberOfSections,
                      alto.indice.item < lista.numberOfItems(inSection: alto.indice.section),
                      let quadro = lista.layoutAttributesForItem(at: alto.indice)?.frame else { continue }
                let ponto = CGRect(x: quadro.minX, y: quadro.minY + alto.fracao * quadro.height, width: quadro.width, height: 0)
                let alvo = deslocamento(levando: ponto, a: 0, recuoDeCima: lista.adjustedContentInset.top,
                                        recuoDeBaixo: lista.adjustedContentInset.bottom, altura: lista.bounds.height,
                                        conteudo: lista.contentSize.height)
                if abs(lista.contentOffset.y - alvo) > 0.5 { lista.contentOffset.y = alvo }
            }
        }
    }

    private func rolar(_ chave: String, a fracao: CGFloat, animado: Bool) -> Bool {
        guard let (rolagem, marca) = rolagem(de: chave) else { return false }
        let y = deslocamento(levando: marca.convert(marca.bounds, to: rolagem), a: fracao,
                             recuoDeCima: rolagem.adjustedContentInset.top, recuoDeBaixo: rolagem.adjustedContentInset.bottom,
                             altura: rolagem.bounds.height, conteudo: rolagem.contentSize.height)
        rolagem.setContentOffset(CGPoint(x: rolagem.contentOffset.x, y: y), animated: animado)
        return true
    }
}

/// O deslocamento da rolagem que leva o ponto `fracao` do quadro (na régua do conteúdo; 0 é o topo, 0,5 o meio) ao mesmo
/// ponto da parte à vista, entre os recuos de cima e de baixo, preso ao começo e ao fim do conteúdo.
func deslocamento(levando quadro: CGRect, a fracao: CGFloat, recuoDeCima: CGFloat, recuoDeBaixo: CGFloat, altura: CGFloat,
                  conteudo: CGFloat) -> CGFloat {
    let visivel = altura - recuoDeCima - recuoDeBaixo
    let comeco = -recuoDeCima
    let fim = max(comeco, conteudo + recuoDeBaixo - altura)
    let ponto = quadro.minY + fracao * quadro.height
    return min(max(ponto - recuoDeCima - fracao * visivel, comeco), fim)
}

/// A marca da 1ª linha: apresenta a List à ponte quando entra na janela.
struct MarcaDaLista: UIViewRepresentable {
    let ponte: PonteDaRolagem

    final class Vista: UIView {
        weak var ponte: PonteDaRolagem?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil { ponte?.conhecer(self) }
        }
    }

    func makeUIView(context: Context) -> Vista {
        let vista = Vista()
        vista.isUserInteractionEnabled = false
        vista.ponte = ponte
        return vista
    }

    func updateUIView(_ uiView: Vista, context: Context) { uiView.ponte = ponte }
}

/// A marca de uma peça: uma vista vazia no fundo dela, que a ponte converte para a rolagem.
struct MarcaDaLinha: UIViewRepresentable {
    let ponte: PonteDaRolagem
    let chave: String

    /// A vista vazia, com a chave da peça e a ponte que a guarda.
    final class Vista: UIView {
        var chave: String?
        weak var ponte: PonteDaRolagem?
    }

    func makeUIView(context: Context) -> Vista {
        let vista = Vista()
        vista.isUserInteractionEnabled = false
        return vista
    }

    func updateUIView(_ uiView: Vista, context: Context) {
        if uiView.chave != nil && uiView.chave != chave { uiView.ponte?.esquecer(uiView) }
        uiView.ponte = ponte
        ponte.marcar(uiView, chave: chave)
    }

    static func dismantleUIView(_ uiView: Vista, coordinator: ()) { uiView.ponte?.esquecer(uiView) }
}

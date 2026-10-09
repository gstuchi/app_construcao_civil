import Foundation
import Testing
import SwiftUI
@testable import Custta

/* O leitor de caminhos SVG e o logo escrito. */
struct LogoTests {
    @Test func leComandosERepeticao() throws {
        let p = try CaminhoSVG.ler("M0 0 10 0V10H0Z")
        #expect(p.boundingRect == CGRect(x: 0, y: 0, width: 10, height: 10))
        let curva = try CaminhoSVG.ler("M0 0Q5 10 10 0C10 -5 0 -5 0 0")
        #expect(curva.currentPoint == CGPoint(x: 0, y: 0))
        #expect(throws: CaminhoSVG.ErroDeLeitura.self) { try CaminhoSVG.ler("M0 0 X1 1") }
        #expect(throws: CaminhoSVG.ErroDeLeitura.self) { try CaminhoSVG.ler("M0 0 10 0Z 5 5") }
    }

    @Test func arcoTerminaNoPontoDado() throws {
        let p = try CaminhoSVG.ler("M478 -385 L405 -355 A165 195 0 1 0 405 -135 L478 -105")
        let caixa = p.boundingRect
        // A elipse de raios 165 e 195 passa por (405, −355) e (405, −135): o centro fica em
        // x = 405 − 165·√(1 − (110/195)²) ≈ 268,76, e o ponto mais à esquerda do c, 165 antes disso.
        #expect(abs(caixa.minX - (405 - 165 * (1 - pow(110.0 / 195, 2)).squareRoot() - 165)) < 0.01)
        #expect(abs(caixa.maxX - 478) < 0.01, "o Path guarda a caixa em precisão simples")
        let arco = try CaminhoSVG.ler("M0 0 A10 10 0 0 1 20 0")
        #expect(abs(arco.currentPoint!.x - 20) < 1e-9 && abs(arco.currentPoint!.y) < 1e-9)
    }

    @Test func caminhosDoLogoLidosENaCaixa() {
        let c = LogoCaminhos.caminhos
        #expect(c.letras.count == 6 && c.letras.filter(\.tt).count == 2)
        #expect(c.letras.flatMap(\.penas).count == LogoCaminhos.tracos.count)
        for letra in c.letras {
            #expect(!letra.glifo.isEmpty && !letra.penas.contains(where: \.isEmpty))
            #expect(LogoCaminhos.caixa.insetBy(dx: -1, dy: -1).contains(letra.glifo.boundingRect))
        }
        #expect(!c.ponto.isEmpty)
    }

    @Test func temposEmOrdem() {
        let inicios = LogoCaminhos.tracos.map(\.inicio)
        #expect(inicios == inicios.sorted())
        #expect(LogoCaminhos.carimbo.inicio > inicios.last!)
        #expect(LogoCaminhos.vibracao > LogoCaminhos.carimbo.inicio && LogoCaminhos.inteiras < LogoCaminhos.varredura.inicio)
        #expect(LogoCaminhos.total > LogoCaminhos.some)
    }
}

#if DEBUG
import SwiftUI
import CusttaNucleo

/* A vitrine das peças da identidade nova (etapa 4, PR 1b), só no Debug: nenhuma tela as usa antes da obra (PR 1c), e aqui
   os testes de tela e a conferência visual as veem sobre a aurora, nas medidas do mockup aprovado (parte1.html), com os
   números da Casa Alphaville da vitrine (os do mockup). `CUSTTA_ABRIR=pecas` a empurra em Obras. */
struct VitrineDasPecas: View {
    private let estado = Estado.de(DadosDeExemplo.vitrine())

    var body: some View {
        let casa = estado.obras[0]
        let hoje = dataLocalISO(.now, fuso: .current)
        let indicadores = indicadoresDaObra(casa, taxa: estado.config.taxaMensal, hoje: hoje)
        ScrollView {
            VStack(alignment: .leading, spacing: Grade.entreBlocos) {
                BlocoSolido {
                    CabecalhoDoBloco(rotulo: "Total gasto") { EtiquetaDoSolido(texto: indicadores.etiquetaDoTotal) }
                    ValorEmDinheiro(indicadores.totalGasto, mono: .principal).accessibilityIdentifier("vitrine-total")
                    NotaDoBloco(texto: "bruto, sem correção")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("vitrine-solido")
                BlocoDeVidro {
                    CabecalhoDoBloco(rotulo: "Corrigido pelo banco")
                    ValorEmDinheiro(indicadores.corrigido, mono: .bloco)
                    NotaDoBloco(texto: indicadores.notaDoCorrigido)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("vitrine-vidro")
                BlocoSolido(cor: .ambar) {
                    CabecalhoDoBloco(rotulo: "Rende menos que o banco") { EtiquetaDoSolido(texto: "banco paga 1%") }
                    NotaDoBloco(texto: "vendendo daqui a 12 meses")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("vitrine-ambar")
                BlocoDeVidro {
                    CabecalhoDoBloco(rotulo: "Números")
                    VStack(alignment: .leading, spacing: 6) {
                        ValorEmDinheiro("R$\u{a0}1.000.000.000,00", mono: .principal).accessibilityIdentifier("vitrine-maiorValor")
                        ValorEmDinheiro(indicadores.aPagar, mono: .bloco)
                        ValorEmDinheiro("−R$\u{a0}4.980,00", mono: .linha)
                        ValorEmDinheiro("R$\u{a0}72.300,00", mono: .miudo)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("vitrine-numeros")
                BlocoDeVidro {
                    CabecalhoDoBloco(rotulo: "Placa e placa forte")
                    Color.clear.frame(height: 16).padding(8).placa().accessibilityIdentifier("vitrine-placa")
                    Color.clear.frame(height: 16).padding(8).placa(forte: true).accessibilityIdentifier("vitrine-placaForte")
                }
            }
            .padding(.horizontal, Grade.externa)
            .padding(.bottom, 98)
        }
        .scrollIndicators(.hidden)
        .bordaDeRolagem(abas: true)
        .containerBackground(.clear, for: .navigation)
        .navigationTitle("Peças")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif

#if DEBUG
import SwiftUI
import CusttaNucleo

/* A vitrine das peças da identidade nova (etapa 4, PR 1b), só no Debug: nenhuma tela as usa antes da obra (PR 1c), e aqui
   os testes de tela e a conferência visual as veem sobre a aurora, nas medidas do mockup aprovado (parte1.html), com os
   números da Casa Alphaville da vitrine (os do mockup). `CUSTTA_ABRIR=pecas` a empurra em Obras. */
struct VitrineDasPecas: View {
    private let estado = Estado.de(DadosDeExemplo.vitrine())
    private static let gigante = Estado.de(.objeto(["obras": .lista([.objeto([
        "id": .texto("x"), "nome": .texto("x"), "fase": .texto("construcao"), "dataInicio": .texto("2026-01-01"),
        "gastos": .lista([.objeto(["id": .texto("gigante"), "valor": .numero(1_000_000_000), "topico": .texto("terreno"),
                                   "descricao": .texto("Terreno do condomínio"), "data": .texto("2026-10-01"),
                                   "pagamento": .texto("pix")])]),
    ])])])).obras[0].gastos[0]
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var letra

    var body: some View {
        let casa = estado.obras[0]
        let hoje = dataLocalISO(.now, fuso: .current)
        let indicadores = indicadoresDaObra(casa, taxa: estado.config.taxaMensal, hoje: hoje)
        ScrollView {
            VStack(alignment: .leading, spacing: Grade.entreBlocos) {
                TituloMono(texto: casa.nome, identificador: "vitrine-titulo")
                CapsulaDeMetadados {
                    EtiquetaDeFase(fase: casa.fase, grande: true)
                    Text(textoDoInicio(casa, hoje: hoje))
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("vitrine-metadados")
                .padding(.bottom, 4)
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
                    Text("Gastos por tópico").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto)).padding(.bottom, 8)
                    BarraDeTopicos(pedacos: pedacosDoAnel(gastoPorTopico(casa, hoje: hoje, taxaMensal: estado.config.taxaMensal)),
                                   topicos: mapaDeTopicos(estado.config.topicosProprios))
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("vitrine-topicos")
                // Os lançamentos na linha mono: os dois primeiros do mês mais recente e um de R$ 1 bilhão, que não cabe ao
                // lado do título (deixaria menos de 120 pt para ele) e desce para baixo dele.
                let topicos = mapaDeTopicos(estado.config.topicosProprios)
                let lancamentos = Array(listaDaObra(casa, hoje: hoje).meses.first?.gastos.prefix(2) ?? []) + [Self.gigante]
                CartaoDaLista {
                    ForEach(Array(lancamentos.enumerated()), id: \.element.id) { i, gasto in
                        if i > 0 { LinhaFina().padding(.horizontal, Grade.recuo) }
                        LinhaDeGastoView(gasto: gasto, linha: linhaDeGasto(gasto, topicos: topicos))
                    }
                }
                .environment(\.linhaMono, true)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("vitrine-lancamentos")
                BlocoDeVidro {
                    CabecalhoDoBloco(rotulo: "Hachura: a vencer e o excesso")
                    HStack(spacing: 12) {
                        // A barra a vencer do gasto por mês: o contorno tracejado e a hachura de 1,5 a cada 4, na cor apagada.
                        let forma = UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4)
                        Hachura(traco: 1.5, passo: 4).fill(paleta.cor(.barraApagada)).clipShape(forma)
                            .overlay { forma.stroke(paleta.cor(.barraApagada), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])) }
                            .frame(width: 26, height: 64)
                        // O excesso do orçamento: 2 a cada 6, no âmbar.
                        Hachura().fill(paleta.cor(.alerta)).frame(height: 10).clipShape(.capsule)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier("vitrine-hachura")
                }
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
        .rolagemFixaSoComOArgumento()
        .bordaDeRolagem(abas: true)
        .containerBackground(.clear, for: .navigation)
        .navigationTitle("Peças")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .principal) { TituloPequenoMono(texto: casa.nome, letra: letra) } }
    }
}
#endif

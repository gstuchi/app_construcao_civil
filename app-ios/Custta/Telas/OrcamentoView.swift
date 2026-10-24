import SwiftUI
import CusttaNucleo

/* A tela Orçamento (mockup aprovado da etapa 3, parte 1, seção 3): empurrada pela linha do orçamento da obra, no caminho de
   Obras, com o título grande e o lápis na barra (o mesmo círculo da obra), que abre a folha do orçamento. O cartão do site,
   com "previstos em N tópicos" e a frase do que está fora (no modo por tópico, o cartão soma só os tópicos previstos e não
   fecha com o Total gasto: achado 10); o "Por tópico" com as frases do site, na ordem do site, e uma linha por tópico fora
   do orçamento (no site, uma linha só, com os nomes: achado 11); no modo total, o "Gasto por tópico" (bruto e % da obra, na
   ordem da legenda do donut) e a dica do lápis. As linhas com gasto (o previsto com gasto, toda linha de fora e toda do
   gasto por tópico) abrem o detalhe do tópico, com a seta; o previsto sem gasto não abre, como no site.
   Sem a obra (apagada em outro aparelho) ou sem o orçamento (tirado), a tela volta. */
struct OrcamentoView: View {
    let id: String
    @Binding var caminho: [RotaDeObras]
    @Environment(ModeloApp.self) private var modelo
    @Environment(Folhas.self) private var folhas
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @State private var barra = BarraDaObra()

    var body: some View {
        let estado = modelo.sincronizador.estado
        let obra = estado.obras.first { $0.id == id }
        if let obra, let resumo = orcamentoObra(obra) {
            conteudo(obra, resumo, estado: estado)
        } else if !modelo.sincronizador.dadosCarregados {
            ProgressView()                               // aberta antes de os dados chegarem
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Sem orçamento, volta para a obra; sem a obra, para Obras.
            Color.clear.onAppear { caminho.removeAll { $0 == .orcamento(id) || (obra == nil && $0 == .obra(id)) } }
        }
    }

    private func conteudo(_ obra: Obra, _ r: ResumoOrcamento, estado: Estado) -> some View {
        let topicos = mapaDeTopicos(estado.config.topicosProprios)
        let gastos = r.modo == "topicos" ? [] : gastoPorTopico(obra, hoje: dataLocalISO(.now, fuso: .current), taxaMensal: estado.config.taxaMensal)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                TituloDaObra(nome: "Orçamento", identificador: "tituloDoOrcamento")
                CartaoDoOrcamento(resumo: r)
                    .padding(.top, 8)
                if r.modo == "topicos" {
                    PilulaDaLista(titulo: "Por tópico", quantidade: r.topicos.count, identificador: "porTopico")
                        .padding(.top, 14)
                    CartaoDaLista {
                        ForEach(Array(linhasPorTopico(r, topicos: topicos, gastos: obra.gastos).enumerated()), id: \.element.id) { i, linha in
                            if i > 0 { LinhaFina().padding(.leading, 67) }
                            LinhaDeTopicoNoOrcamento(linha: linha, identificador: "topicoOrc-\(linha.id)", abrir: { abrirDetalhe(linha.id) })
                        }
                    }
                    if !r.fora.isEmpty {
                        CartaoDaLista {
                            CabecalhoDoForaDoOrcamento(total: r.foraTotal)
                            Text("Tópico sem valor não entra na comparação.")
                                .font(.footnote)
                                .foregroundStyle(paleta.cor(vidro.secundario))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(EdgeInsets(top: 0, leading: 18, bottom: 4, trailing: 18))
                            ForEach(Array(linhasForaDoOrcamento(r, topicos: topicos).enumerated()), id: \.element.id) { i, linha in
                                if i > 0 { LinhaFina().padding(.leading, 67) }
                                LinhaDeTopicoNoOrcamento(linha: linha, identificador: "foraOrc-\(linha.id)", abrir: { abrirDetalhe(linha.id) })
                            }
                        }
                    }
                } else {
                    PilulaDaLista(titulo: "Gasto por tópico", quantidade: gastos.count, identificador: "gastoPorTopico")
                        .padding(.top, 14)
                    CartaoDaLista {
                        ForEach(Array(linhasDoGastoPorTopico(gastos, topicos: topicos).enumerated()), id: \.element.id) { i, linha in
                            if i > 0 { LinhaFina().padding(.leading, 67) }
                            LinhaDeTopicoNoOrcamento(linha: linha, identificador: "gastoTopico-\(linha.id)", abrir: { abrirDetalhe(linha.id) })
                        }
                    }
                    DicaDoModoTotal()
                }
            }
            .padding(.horizontal, 20)
            // O fim da lista à vista acima da cápsula de abas, como na tela da obra.
            .padding(.bottom, 98)
        }
        .scrollIndicators(.hidden)
        .tituloPequenoAoRolar(barra)
        #if DEBUG
        .modifier(RolagemFixaDoTeste())
        #endif
        .pausaOFundoAoRolar()
        .bordaDeRolagem(abas: true)
        .containerBackground(.clear, for: .navigation)
        .navigationTitle("Orçamento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { TituloDaBarraDaObra(barra: barra, nome: "Orçamento") }
            ToolbarItem(placement: .topBarTrailing) { IndicadorDeSincronizacao() }
                .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .topBarTrailing) {
                BotaoDeEditarObra(rotulo: "Editar orçamento", identificador: "editarOrcamento") { folhas.aberta = .orcamento(obraId: id) }
            }
                .sharedBackgroundVisibility(.hidden)
        }
    }

    /// O toque numa linha que abre: o detalhe do tópico, nesta obra.
    private func abrirDetalhe(_ topico: String) { folhas.aberta = .topico(obraId: id, topicoId: topico) }
}

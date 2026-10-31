/* Cores do app nativo por token (spec, seção 8: "cores só por tokens"). A tabela abaixo é a
   fonte e o script grava os color sets do catálogo app-ios/Custta/Assets.xcassets: um por token
   da pele Esmeralda, com variante clara e escura, mais a cor de destaque do sistema e o fundo da abertura.
   Valores: os do styles.css do site no escuro e no claro e os do
   mockup aprovado da etapa 1 (~/Documents/custta-mockups/nativo/etapa1/final.html: tons de texto
   sobre o vidro, contorno do "Aumentar contraste", tintas do vidro e aurora). Mudança de cor é
   aqui, nunca no catálogo à mão. tests/app-ios.test.cjs roda --conferir.

   Uso: node scripts/cores-app-ios.mjs            grava o catálogo
        node scripts/cores-app-ios.mjs --conferir  só confere (sai com 1 se algo difere) */
import { mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const CATALOGO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../app-ios/Custta/Assets.xcassets');

/* token: [escuro, claro], por pele; '#RRGGBB' ou '#RRGGBBAA'. Origem no styles.css (:root e
   [data-theme="light"]) e no final.html. A pele Azul saiu em 21/10/2026: o Custta só tem a Esmeralda. */
export const CORES = {
  Esmeralda: {
    Fundo: ['#04100C', '#EDF5F1'],                  // --bg
    Superficie: ['#0C241D', '#FFFFFF'],             // --surface-solid: vidro com "Reduzir transparência"
    Linha: ['#1B3D33', '#C6DCD1'],                  // --line
    // A linha fina dentro dos cartões de vidro (etapa 2): no escuro, branco 9% como o mockup; o Linha sólido, mais escuro
    // que o vidro, sumia a 1,0–1,5:1 com a aurora atrás. No claro, o próprio Linha.
    LinhaNoVidro: ['#FFFFFF17', '#C6DCD1'],
    Texto: ['#EAFFF6', '#13261E'],                  // --text
    TextoSecundario: ['#86AA9A', '#4D685C'],        // --muted
    TextoTerciario: ['#64887A', '#5F7A6D'],         // "(opcional)" nos rótulos
    Marca: ['#14B39A', '#0B7A68'],                  // --brand
    Destaque: ['#3AD17E', '#177A4A'],               // --accent
    Positivo: ['#35D68A', '#0E7A41'],               // --profit; fase vendida
    PositivoFundo: ['#0C2F1E', '#D7F2E2'],
    Alerta: ['#E0A83A', '#8A5A06'],                 // --warn; fase em construção
    AlertaFundo: ['#33260F', '#F5ECD2'],
    // O texto âmbar das etiquetas ("Em construção", "nada em 30 dias"): o Alerta do site (--warn) sobre a AlertaFundo ficava
    // em 4,42:1 no laudo, na faixa do véu do topo; no claro, um âmbar mais escuro só nas etiquetas.
    AlertaEtiqueta: ['#E0A83A', '#7A5410'],
    Informacao: ['#3AA0E0', '#1C68A0'],             // fase pronta
    InformacaoFundo: ['#0E2735', '#DCEBF7'],
    Negativo: ['#FB7185', '#C22E55'],               // --red
    SobreMarca: ['#04100C', '#FFFFFF'],             // --btn-ink: texto do botão principal
    Tinta: ['#14B39A', '#0B7A68'],                  // segmentado escolhido (e o + da etapa 2)
    SobreTinta: ['#04100C', '#FFFFFF'],
    Campo: ['#10322A', '#E2EFE8'],                  // campos sólidos do cartão de entrada
    CampoBorda: ['#1B3D33', '#C6DCD1'],
    FantasmaFundo: ['#0A3F30', '#D6F0E7'],          // botão secundário ("Reenviar link", "Sair da conta")
    FantasmaTexto: ['#8FE8D5', '#096453'],
    // Texto secundário sobre o Fosco (entrada e opção). No escuro, o do Transparente (decisão 6 da etapa 3: o #B8D4C7 ficava
    // em 4,24:1 e 4,47:1 em dois pontos claros da aurora); no claro, o do Fosco.
    SecundarioFosco: ['#D6E8E0', '#3B574B'],
    SecundarioTransparente: ['#D6E8E0', '#2B463B'], // sobre o Transparente corrigido
    SecundarioSolido: ['#9DBDAF', '#4D685C'],       // sobre a superfície sólida
    LinkNoVidro: ['#8FE8D5', '#075243'],            // link e aba ativa sobre o vidro
    ErroNoVidro: ['#FFA3B3', '#A3153F'],
    Contorno: ['#EAFFF68C', '#13261E73'],           // "Aumentar contraste": 1,5 pt em volta do vidro
    TintaConteudo: ['#061611', '#FFFFFF'],          // vidro dos cartões e painéis
    TintaCartao: ['#0A1E18', '#FAFDFB'],            // vidro do cartão de entrada
    TintaNavegacao: ['#081A14', '#F6FAF8'],         // vidro da cápsula, do sair e da sincronização
    Aurora1: ['#10B9A0', '#14B39A'],
    Aurora2: ['#28C86E', '#3AD17E'],
    Aurora3: ['#085A96', '#3C96C8'],
    Aurora4: ['#78EBC3', '#96F0D2'],
    RealceLogo: ['#B8F5D2', '#0B7A68'],             // início do degradê do "tt." no escuro
    SombraDoTexto: ['#00000059', '#00000000'],      // --sombra-txt: texto solto sobre a aurora (só no escuro)
    // "Finalizar saída": sob o alerta, somado ao escurecido do sistema (no iOS 27, 48% e 20%), e sem o alerta, o total
    // dos dois. No claro, nada sob o alerta: o texto do botão é escuro e escurecer atrás do vidro só tira contraste.
    EscurecidoSobOAlerta: ['#0000006B', '#00000000'],
    Escurecido: ['#000000B2', '#00000033'],
    GoogleFundo: ['#131314', '#FFFFFF'],            // regras do botão do Google, iguais nas duas peles
    GoogleBorda: ['#8E918F', '#747775'],
    GoogleTexto: ['#E3E3E3', '#1F1F1F'],
    GloboTerra: ['#14B39A', '#14B39A'],             // globe.js: o claro usa o mesmo, com o globo a 40%
    GloboBrilho: ['#A8FFE0', '#A8FFE0'],
    GloboOceano: ['#0F7C6A', '#0F7C6A'],
    GloboHalo: ['#14B39A', '#14B39A'],
    GloboAro: ['#3AD17E', '#3AD17E'],
    // O lucro e o prejuízo da obra vendida sobre o vidro (etapa 2): o Positivo e o Negativo do site ficavam entre 2,4 e
    // 4,2:1 com a aurora atrás (laudo de leitura); estes passam de 4,5:1 no pior pixel. O prejuízo do escuro é o #FFD2D9:
    // com o #FFC4CE, a nota da venda ficava em 4,25:1 onde a aurora é mais clara (T35); com ele, 4,68 (pior pixel 4,61).
    PositivoNoVidro: ['#8CF0BC', '#084A27'],
    NegativoNoVidro: ['#FFD2D9', '#8A1538'],
    // O texto âmbar sobre o vidro do conteúdo (etapa 3, o --amber-v do mockup: o aviso dos tópicos na linha do orçamento e o
    // "Passou … do previsto"): no claro, #6F4705 (o Alerta do site dava 3,79–4,15:1 sobre a aurora clara; este, 5,21–5,71:1).
    // No escuro, um âmbar claro: o Alerta do site (#E0A83A) ficava em 3,12:1 (pior pixel 2,98) no alto da tela Orçamento
    // rolada, na maior letra, onde a aurora clareia o vidro (laudo da etapa 3); este, 4,9 ali. Não é o AlertaEtiqueta, que vai
    // sobre o fundo âmbar das etiquetas.
    AlertaNoVidro: ['#FFD98A', '#6F4705'],
    // Etapa 2 (~/Documents/custta-mockups/nativo/etapa2/parte2.html e parte3.html, aprovados em 13/10): a folha do
    // sistema e o que vai dentro dela, o arrastar para apagar e a linha que acabou de entrar.
    Folha: ['#0A1E18E6', '#F4F9F6F0'],              // --folha: fundo da folha (presentationBackground)
    LinhaDaFolha: ['#12352C', '#FFFFFF'],           // --folha-linha: grupos sólidos da folha; a linha arrastada
    SeparadorDaFolha: ['#FFFFFF14', '#142B2317'],   // --folha-sep: linha fina entre as linhas de um grupo
    Tecla: ['#16403A', '#FFFFFF'],                  // --folha-tecla: teclas do teclado de valor
    TeclaTocada: ['#1E5247', '#E2EFE8'],            // --folha-tecla-on
    SegmentadoFundo: ['#FFFFFF14', '#142B2312'],    // --seg-fundo: trilho do Pix | Cartão
    SegmentadoEscolhido: ['#2A6B5C', '#FFFFFF'],    // --seg-on
    SombraDoSegmentado: ['#0000002E', '#0000002E'], // sombra do --seg-on (0 1px 3px, preto 18%): no claro, separa o branco do trilho
    Apagar: ['#C42B3A', '#C22E55'],                 // botão do arrastar (o vermelho do sistema não passa 4,5:1 com branco)
    SobreApagar: ['#FFFFFF', '#FFFFFF'],
    SobreAlerta: ['#1F1503', '#FFFFFF'],            // "Salvar mesmo assim", sobre o Alerta
    Aceso: ['#14B39A38', '#0B7A6824'],              // --aceso: a linha nova, por 2 s
    // Ajustes › Aparência: o aro claro das barrinhas de vidro desenhadas na miniatura de cada opção (no mockup, branco a 70% no
    // Transparente e a 30% no Fosco, nos dois temas). O vidro de verdade tem o aro do sistema.
    AroDaMiniatura: ['#FFFFFF', '#FFFFFF'],
    // Etapa 4 (~/Documents/custta-mockups/nativo/etapa4/, aprovado em 28/10; spec 2026-10-29, "Tokens: do mockup para o
    // app"): a identidade nova, só o que o app não tinha. O DestaqueNumero do mockup é o PositivoNoVidro, a LinhaBanco é o
    // SecundarioTransparente e o AmbarTexto é o AlertaNoVidro: o do app tem o mesmo papel e é igual ou mais forte.
    DestaqueSolido: ['#3AD17E', '#3AD17E'],         // o bloco sólido protagonista de cada tela (não é vidro)
    TintaSobreDestaque: ['#04100C', '#04100C'],     // o texto sobre ele
    DestaqueTexto: ['#3AD17E', '#0E7A41'],          // texto verde sobre o vidro; no claro, o --green do site
    SolidoAmbar: ['#FFD98A', '#F2C15A'],            // o veredito "Rende menos que o banco" (o claro: confirmação 1 de 29/10)
    TintaSobreAmbar: ['#2B1B00', '#2B1B00'],
    Placa: ['#04100C94', '#FFFFFFA8'],              // tom chapado, sem desfoque, atrás do anel e dos gráficos (58% e 66%)
    PlacaForte: ['#04100CD6', '#FFFFFFEB'],         // atrás da barra empilhada da obra (84% e 92%)
    // As seis cores do anel e da barra empilhada (verde-água, azul, magenta, violeta, laranja e ciano), validadas nos dois
    // temas a 3:1 contra o vidro, e o cinza de "Outros", neutro de propósito.
    Grafico1: ['#199E70', '#10976A'],
    Grafico2: ['#3987E5', '#2A78D6'],
    Grafico3: ['#D55181', '#D14F86'],
    Grafico4: ['#9085E9', '#6250D6'],
    Grafico5: ['#D95926', '#DC5A1E'],
    Grafico6: ['#14A3C7', '#0C86A4'],
    GraficoOutros: ['#8FA89C', '#5E7A6E'],
    BarraApagada: ['#EAFFF666', '#142B2394'],       // os meses não escolhidos e a hachura das parcelas a vencer (40% e 58%)
    GradeGrafico: ['#EAFFF624', '#142B2324'],       // 14%
    EixoGrafico: ['#EAFFF64D', '#142B2352'],        // 30% e 32%
    AnelApagado: ['#123128', '#DCEAE3'],            // o trilho e os pedaços apagados pelo toque: por cor, sem opacidade
    AnelSeparador: ['#04100C8C', '#FFFFFFBF'],      // o aro de 2,5 pt na ponta de cada pedaço (55% e 75%)
  },
};

/* Texto sobre superfície sólida: [texto, fundo]. Os dois lados são opacos, então o contraste sai da conta
   (tests/app-ios.test.cjs confere 4,5:1 nos quatro combos sem Xcode); sobre o vidro, quem mede é o laudo
   de leitura (LeituraNoVidroUITests). */
export const PARES_SOLIDOS = [
  ['Texto', 'Superficie'], ['SecundarioSolido', 'Superficie'], ['LinkNoVidro', 'Superficie'], ['ErroNoVidro', 'Superficie'],
  ['Texto', 'Campo'], ['SobreMarca', 'Marca'], ['SobreTinta', 'Tinta'], ['FantasmaTexto', 'FantasmaFundo'],
  ['Alerta', 'AlertaFundo'], ['AlertaEtiqueta', 'AlertaFundo'], ['Informacao', 'InformacaoFundo'], ['Positivo', 'PositivoFundo'], ['GoogleTexto', 'GoogleFundo'],
  ['TextoSecundario', 'Campo'], ['PositivoNoVidro', 'Superficie'], ['NegativoNoVidro', 'Superficie'],
  ['Texto', 'LinhaDaFolha'], ['SecundarioSolido', 'LinhaDaFolha'], ['SecundarioTransparente', 'LinhaDaFolha'], ['LinkNoVidro', 'LinhaDaFolha'], ['ErroNoVidro', 'LinhaDaFolha'],
  ['Negativo', 'LinhaDaFolha'], ['Alerta', 'LinhaDaFolha'], ['Texto', 'Tecla'], ['Texto', 'TeclaTocada'], ['Texto', 'SegmentadoEscolhido'],
  ['SobreApagar', 'Apagar'], ['SobreAlerta', 'Alerta'],
  ['TintaSobreDestaque', 'DestaqueSolido'], ['TintaSobreAmbar', 'SolidoAmbar'],
];

const info = { author: 'xcode', version: 1 };
const componente = hex => ({ 'color-space': 'srgb',
  components: { red: '0x' + hex.slice(1, 3), green: '0x' + hex.slice(3, 5), blue: '0x' + hex.slice(5, 7),
    alpha: hex.length === 9 ? (parseInt(hex.slice(7, 9), 16) / 255).toFixed(3) : '1.000' } });

/** Color set com a variante clara (padrão) e a escura. */
export function colorSet([escuro, claro]){
  return { colors: [
    { idiom: 'universal', color: componente(claro) },
    { idiom: 'universal', appearances: [{ appearance: 'luminosity', value: 'dark' }], color: componente(escuro) },
  ], info };
}

/** Arquivos do catálogo que a tabela define: caminho relativo → texto. */
export function arquivos(){
  const json = o => JSON.stringify(o, null, 2) + '\n';
  const r = {};
  for(const [pele, tokens] of Object.entries(CORES)){
    r[`${pele}/Contents.json`] = json({ info, properties: { 'provides-namespace': true } });
    for(const [token, valores] of Object.entries(tokens)) r[`${pele}/${token}.colorset/Contents.json`] = json(colorSet(valores));
  }
  // Destaque dos controles do sistema antes da paleta valer, e o fundo da abertura (escuro, sem clarão).
  r['AccentColor.colorset/Contents.json'] = json(colorSet(CORES.Esmeralda.Marca));
  r['FundoAbertura.colorset/Contents.json'] = json({ colors: [{ idiom: 'universal', color: componente(CORES.Esmeralda.Fundo[0]) }], info });
  return r;
}

if(process.argv[1] === fileURLToPath(import.meta.url)){
  const conferir = process.argv.includes('--conferir');
  const diferentes = [];
  for(const [rel, texto] of Object.entries(arquivos())){
    const destino = path.join(CATALOGO, rel);
    if(conferir){
      if(!existsSync(destino) || readFileSync(destino, 'utf8') !== texto) diferentes.push(rel);
      continue;
    }
    mkdirSync(path.dirname(destino), { recursive: true });
    writeFileSync(destino, texto);
  }
  if(diferentes.length){
    console.error('catálogo de cores defasado; rode node scripts/cores-app-ios.mjs:\n' + diferentes.join('\n'));
    process.exit(1);
  }
  console.log(conferir ? 'ok - catálogo de cores em dia' : 'cores gravadas em app-ios/Custta/Assets.xcassets');
}

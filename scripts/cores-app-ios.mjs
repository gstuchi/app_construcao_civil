/* Cores do app nativo por token (spec, seção 8: "cores só por tokens"). A tabela abaixo é a
   fonte e o script grava os color sets do catálogo app-ios/Custta/Assets.xcassets: um por token
   e pele, com variante clara e escura, mais a cor de destaque do sistema e o fundo da abertura.
   Valores: os do styles.css do site nos quatro combos (escuro e claro, esmeralda e azul) e os do
   mockup aprovado da etapa 1 (~/Documents/custta-mockups/nativo/etapa1/final.html: tons de texto
   sobre o vidro, contorno do "Aumentar contraste", tintas do vidro e aurora). Mudança de cor é
   aqui, nunca no catálogo à mão. tests/app-ios.test.cjs roda --conferir.

   Uso: node scripts/cores-app-ios.mjs            grava o catálogo
        node scripts/cores-app-ios.mjs --conferir  só confere (sai com 1 se algo difere) */
import { mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const CATALOGO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../app-ios/Custta/Assets.xcassets');

/* token: [escuro, claro], por pele; '#RRGGBB' ou '#RRGGBBAA'. Origem no styles.css (:root,
   [data-theme="light"], [data-skin="azul"] e os dois juntos) e no final.html. */
export const CORES = {
  Esmeralda: {
    Fundo: ['#04100C', '#EDF5F1'],                  // --bg
    Superficie: ['#0C241D', '#FFFFFF'],             // --surface-solid: vidro com "Reduzir transparência"
    Linha: ['#1B3D33', '#C6DCD1'],                  // --line
    Texto: ['#EAFFF6', '#13261E'],                  // --text
    TextoSecundario: ['#86AA9A', '#4D685C'],        // --muted
    TextoTerciario: ['#64887A', '#5F7A6D'],         // "(opcional)" nos rótulos
    Marca: ['#14B39A', '#0B7A68'],                  // --brand
    Destaque: ['#3AD17E', '#177A4A'],               // --accent
    Positivo: ['#35D68A', '#0E7A41'],               // --profit; fase vendida
    PositivoFundo: ['#0C2F1E', '#D7F2E2'],
    Alerta: ['#E0A83A', '#8A5A06'],                 // --warn; fase em construção
    AlertaFundo: ['#33260F', '#F5ECD2'],
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
    SecundarioFosco: ['#B8D4C7', '#3B574B'],        // texto secundário sobre o Fosco (entrada e opção)
    SecundarioTransparente: ['#D6E8E0', '#2B463B'], // sobre o Transparente corrigido
    SecundarioSolido: ['#9DBDAF', '#4D685C'],       // sobre a superfície sólida
    LinkNoVidro: ['#8FE8D5', '#075243'],            // link e aba ativa sobre o vidro
    ErroNoVidro: ['#FFA3B3', '#A3153F'],
    Contorno: ['#EAFFF68C', '#13261E73'],           // "Aumentar contraste": 1,5 pt em volta do vidro
    LenteAba: ['#FFFFFF1C', '#142B2312'],           // fundo da aba escolhida na cápsula
    TintaConteudo: ['#061611', '#FFFFFF'],          // vidro dos cartões e painéis
    TintaCartao: ['#0A1E18', '#FAFDFB'],            // vidro do cartão de entrada
    TintaNavegacao: ['#081A14', '#F6FAF8'],         // vidro da cápsula, do sair e da sincronização
    Aurora1: ['#10B9A0', '#14B39A'],
    Aurora2: ['#28C86E', '#3AD17E'],
    Aurora3: ['#085A96', '#3C96C8'],
    Aurora4: ['#78EBC3', '#96F0D2'],
    RealceLogo: ['#B8F5D2', '#0B7A68'],             // início do degradê do "tt." no escuro
    SombraDoTexto: ['#00000059', '#00000000'],      // --sombra-txt: texto solto sobre a aurora (só no escuro)
    GoogleFundo: ['#131314', '#FFFFFF'],            // regras do botão do Google, iguais nas duas peles
    GoogleBorda: ['#8E918F', '#747775'],
    GoogleTexto: ['#E3E3E3', '#1F1F1F'],
    GloboTerra: ['#14B39A', '#14B39A'],             // globe.js: o claro usa o mesmo, com o globo a 40%
    GloboBrilho: ['#A8FFE0', '#A8FFE0'],
    GloboOceano: ['#0F7C6A', '#0F7C6A'],
    GloboHalo: ['#14B39A', '#14B39A'],
    GloboAro: ['#3AD17E', '#3AD17E'],
  },
  Azul: {
    Fundo: ['#070C18', '#EEF2F9'],
    Superficie: ['#111A2E', '#FFFFFF'],
    Linha: ['#243250', '#CDD8E8'],
    Texto: ['#EEF4FB', '#16233C'],
    TextoSecundario: ['#A3B4CA', '#556685'],
    TextoTerciario: ['#6E82A0', '#617594'],
    Marca: ['#5B8CFF', '#3560CF'],
    Destaque: ['#A78BFA', '#6D4FC9'],
    Positivo: ['#4ADE80', '#0E7A41'],
    PositivoFundo: ['#0C2B1C', '#D7F2E2'],
    Alerta: ['#FBBF24', '#8A5A06'],
    AlertaFundo: ['#33280F', '#F8ECC9'],
    Informacao: ['#60A5FA', '#2A63C4'],
    InformacaoFundo: ['#122238', '#DCE9FA'],
    Negativo: ['#FB7185', '#C22E55'],
    SobreMarca: ['#070C18', '#FFFFFF'],
    Tinta: ['#3B6CF0', '#3560CF'],
    SobreTinta: ['#FFFFFF', '#FFFFFF'],
    Campo: ['#182338', '#E7EDF7'],
    CampoBorda: ['#243250', '#CDD8E8'],
    FantasmaFundo: ['#16244A', '#DDE7FB'],
    FantasmaTexto: ['#A8C2FF', '#2B4FB0'],
    SecundarioFosco: ['#C4D1E3', '#36445F'],
    SecundarioTransparente: ['#DCE4F0', '#26324A'],
    SecundarioSolido: ['#A3B4CA', '#556685'],
    LinkNoVidro: ['#A8C2FF', '#223F92'],
    ErroNoVidro: ['#FFA3B3', '#A3153F'],
    Contorno: ['#EEF4FB8C', '#16233C73'],
    LenteAba: ['#FFFFFF1C', '#172B4D12'],
    TintaConteudo: ['#080C1C', '#FFFFFF'],
    TintaCartao: ['#0E1628', '#FBFCFF'],
    TintaNavegacao: ['#0A1020', '#F7F9FD'],
    Aurora1: ['#3B6CF0', '#3B6CF0'],
    Aurora2: ['#6E96FF', '#608CFF'],
    Aurora3: ['#6E32C8', '#8C5ADC'],
    Aurora4: ['#78D2FF', '#96D2FF'],
    RealceLogo: ['#D4E0FF', '#3560CF'],
    SombraDoTexto: ['#00000059', '#00000000'],
    GoogleFundo: ['#131314', '#FFFFFF'],
    GoogleBorda: ['#8E918F', '#747775'],
    GoogleTexto: ['#E3E3E3', '#1F1F1F'],
    GloboTerra: ['#608CFF', '#608CFF'],
    GloboBrilho: ['#A0C4FF', '#A0C4FF'],
    GloboOceano: ['#4E72E0', '#4E72E0'],
    GloboHalo: ['#3A64F5', '#3A64F5'],
    GloboAro: ['#648CFF', '#648CFF'],
  },
};

/* Texto sobre superfície sólida: [texto, fundo]. Os dois lados são opacos, então o contraste sai da conta
   (tests/app-ios.test.cjs confere 4,5:1 nos quatro combos sem Xcode); sobre o vidro, quem mede é o laudo
   de leitura (LeituraNoVidroUITests). */
export const PARES_SOLIDOS = [
  ['Texto', 'Superficie'], ['SecundarioSolido', 'Superficie'], ['LinkNoVidro', 'Superficie'], ['ErroNoVidro', 'Superficie'],
  ['Texto', 'Campo'], ['SobreMarca', 'Marca'], ['SobreTinta', 'Tinta'], ['FantasmaTexto', 'FantasmaFundo'],
  ['Alerta', 'AlertaFundo'], ['Informacao', 'InformacaoFundo'], ['Positivo', 'PositivoFundo'], ['GoogleTexto', 'GoogleFundo'],
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

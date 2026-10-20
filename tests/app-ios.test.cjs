'use strict';
/* Guardas do app nativo (app-ios/) que o Xcode não confere sozinho: formato do projeto, bundle,
   versão e plataforma, assinatura, pacotes travados, o que vem do app de hoje (ios/App/App),
   cores por token e os scripts dos testes locais. Sem rede e sem Xcode: roda no test:unit. */
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync, readdirSync, statSync } = require('node:fs');
const { join } = require('node:path');
const { execFileSync } = require('node:child_process');

const RAIZ = join(__dirname, '..');
const ler = p => readFileSync(join(RAIZ, p), 'utf8');
const PBX = 'app-ios/Custta.xcodeproj/project.pbxproj';
const RESOLVED = 'app-ios/Custta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved';

/* Blocos de build settings do alvo Custta (os que apontam para Custta/Info.plist), por nome. */
function configsDoApp(){
  const blocos = [...ler(PBX).matchAll(/isa = XCBuildConfiguration;\s*buildSettings = \{([\s\S]*?)\};\s*name = (\w+);/g)];
  return Object.fromEntries(blocos.filter(m => m[1].includes('INFOPLIST_FILE = Custta/Info.plist;')).map(m => [m[2], m[1]]));
}

function arquivosSwift(pasta){
  const r = [];
  for(const nome of readdirSync(join(RAIZ, pasta))){
    const rel = join(pasta, nome);
    if(statSync(join(RAIZ, rel)).isDirectory()) r.push(...arquivosSwift(rel));
    else if(nome.endsWith('.swift')) r.push(rel);
  }
  return r;
}

test('projeto no formato do Xcode 16+ (pastas sincronizadas), que o Xcode 26 da CI abre', () => {
  const pbx = ler(PBX);
  assert.match(pbx, /objectVersion = 77;/, 'abrir e salvar num Xcode mais novo pode subir o formato e quebrar a CI (Xcode 26)');
  assert.match(pbx, /preferredProjectObjectVersion = 77;/);
  for(const pasta of ['Custta', 'CusttaTests', 'CusttaUITests'])
    assert.match(pbx, new RegExp(`isa = PBXFileSystemSynchronizedRootGroup;[^}]*path = ${pasta};`), `pasta sincronizada ${pasta}`);
});

test('app: bundle br.com.custta.app, versão 2.0, iOS 26, só iPhone e só retrato', () => {
  const configs = configsDoApp();
  assert.deepEqual(Object.keys(configs).sort(), ['Debug', 'Release']);
  for(const [nome, c] of Object.entries(configs)){
    assert.match(c, /PRODUCT_BUNDLE_IDENTIFIER = br\.com\.custta\.app;/, nome);
    assert.match(c, /MARKETING_VERSION = 2\.0;/, nome);
    assert.match(c, /TARGETED_DEVICE_FAMILY = 1;/, nome);
    assert.match(c, /INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;/, nome);
    assert.match(c, /CODE_SIGN_ENTITLEMENTS = Custta\/Custta\.entitlements;/, nome);
  }
  const pbx = ler(PBX);
  const alvos = [...pbx.matchAll(/IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);/g)].map(m => m[1]);
  assert.ok(alvos.length >= 2 && alvos.every(v => v === '26.0'), `iOS mínimo 26.0: ${alvos}`);
  assert.ok(!pbx.includes('TARGETED_DEVICE_FAMILY = "1,2"'), 'só iPhone');
});

test('Release assina com o perfil App Store e push de produção; Debug assina sozinho', () => {
  const { Debug, Release } = configsDoApp();
  assert.match(Release, /CODE_SIGN_STYLE = Manual;/);
  assert.match(Release, /PROVISIONING_PROFILE_SPECIFIER = "Custta App Store";/);
  assert.match(Release, /"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = "Apple Distribution";/);
  assert.match(Release, /APS_ENVIRONMENT = production;/);
  assert.match(Debug, /CODE_SIGN_STYLE = Automatic;/);
  assert.match(Debug, /APS_ENVIRONMENT = development;/);
  assert.match(ler(PBX), /DEVELOPMENT_TEAM = 4S7JKDKN27;/);
});

test('pacotes: só Firebase e GoogleSignIn, em versão exata, e o Package.resolved bate', () => {
  const pbx = ler(PBX);
  assert.doesNotMatch(pbx, /upToNext(Major|Minor)Version|versionRange|minimumVersion/, 'pacote de terceiros só por versão exata');
  const remotos = [...pbx.matchAll(/repositoryURL = "([^"]+)";\s*requirement = \{\s*kind = (\w+);\s*version = ([\d.]+);/g)]
    .map(m => ({ url: m[1], tipo: m[2], versao: m[3] }));
  assert.deepEqual(remotos.map(r => r.url).sort(), ['https://github.com/firebase/firebase-ios-sdk.git', 'https://github.com/google/GoogleSignIn-iOS']);
  for(const r of remotos) assert.equal(r.tipo, 'exactVersion', `${r.url} preso por versão exata`);
  assert.deepEqual([...new Set([...pbx.matchAll(/isa = XCSwiftPackageProductDependency;[^}]*productName = (\w+);/g)].map(m => m[1]))].sort(),
    ['CusttaNucleo', 'FirebaseAuth', 'FirebaseFirestore', 'GoogleSignIn']);
  assert.match(pbx, /isa = XCLocalSwiftPackageReference;\s*relativePath = CusttaNucleo;/);

  const pins = JSON.parse(ler(RESOLVED)).pins;
  for(const r of remotos){
    const id = r.url.split('/').pop().replace(/\.git$/, '').toLowerCase();
    assert.equal(pins.find(p => p.identity === id)?.state.version, r.versao, `${id} no Package.resolved`);
  }
  // Mesma regra do app de hoje (tests/workflow.test.cjs): dono revisado, versão e commit, nunca branch.
  const DONOS = new Set(['firebase', 'google', 'openid', 'googleads']);
  for(const p of pins){
    const dono = /^https:\/\/github\.com\/([^/]+)\//.exec(p.location)?.[1];
    assert.ok(DONOS.has(dono), `${p.identity}: dono ${dono} não revisado`);
    assert.match(p.state.revision, /^[0-9a-f]{40}$/, `${p.identity} preso por commit`);
    assert.ok(p.state.version, `${p.identity} preso por versão`);
  }
});

test('o app nativo não leva o Sentry', () => {
  assert.doesNotMatch(ler(PBX), /sentry/i);
  for(const f of arquivosSwift('app-ios/Custta')) assert.doesNotMatch(ler(f), /import Sentry|SentrySDK/, f);
});

test('reaproveita do app de hoje: Firebase, entitlements e o esquema de URL do Google', () => {
  // Enquanto ios/ existir (até a remoção do Capacitor), as cópias não podem divergir.
  assert.equal(ler('app-ios/Custta/GoogleService-Info.plist'), ler('ios/App/App/GoogleService-Info.plist'));
  assert.equal(ler('app-ios/Custta/Custta.entitlements'), ler('ios/App/App/App.entitlements'));
  const google = ler('app-ios/Custta/GoogleService-Info.plist');
  const valor = chave => google.match(new RegExp(`<key>${chave}</key>\\s*<string>([^<]+)</string>`))[1];
  const info = ler('app-ios/Custta/Info.plist');
  assert.equal(info.match(/<key>GIDClientID<\/key>\s*<string>([^<]+)<\/string>/)?.[1], valor('CLIENT_ID'));
  assert.ok(info.includes(`<string>${valor('REVERSED_CLIENT_ID')}</string>`), 'sem o esquema o login do Google derruba o app');
});

test('ícone 1024×1024 sem canal alfa', () => {
  const png = readFileSync(join(RAIZ, 'app-ios/Custta/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png'));
  assert.equal(png.toString('ascii', 12, 16), 'IHDR');
  assert.equal(png.readUInt32BE(16), 1024);
  assert.equal(png.readUInt32BE(20), 1024);
  assert.equal(png[25], 2, 'a App Store recusa ícone com canal alfa (ITMS-90717)');
});

test('scheme compartilhado Custta com o app e os dois alvos de teste', () => {
  const xml = ler('app-ios/Custta.xcodeproj/xcshareddata/xcschemes/Custta.xcscheme');
  for(const alvo of ['Custta', 'CusttaTests', 'CusttaUITests']) assert.match(xml, new RegExp(`BlueprintName = "${alvo}"`), alvo);
  assert.match(xml, /ReferencedContainer = "container:Custta\.xcodeproj"/);
});

test('manifesto de privacidade: sem rastreamento, UserDefaults pelo motivo certo e os dados da política', () => {
  const m = ler('app-ios/Custta/PrivacyInfo.xcprivacy');
  assert.match(m, /<key>NSPrivacyTracking<\/key>\s*<false\/>/);
  assert.match(m, /<key>NSPrivacyTrackingDomains<\/key>\s*<array\/>/);
  assert.match(m, /NSPrivacyAccessedAPICategoryUserDefaults<\/string>[\s\S]*?<string>CA92\.1<\/string>/, '@AppStorage e a marca de limpeza usam UserDefaults');
  // Os mesmos dados da política de privacidade do site (privacidade.html); o token do FCM entra na etapa 5.
  for(const tipo of ['EmailAddress', 'Name', 'UserID', 'OtherUserContent', 'OtherDataTypes'])
    assert.match(m, new RegExp(`NSPrivacyCollectedDataType${tipo}<`), `dado coletado ${tipo}`);
  assert.doesNotMatch(m, /<key>NSPrivacyCollectedDataTypeTracking<\/key>\s*<true\/>/, 'nada coletado para rastrear');
});

test('cores só por tokens: nenhuma cor solta no código do app', () => {
  const sistema = '(red|green|blue|orange|yellow|pink|purple|black|white|gray|brown|cyan|mint|indigo|teal|primary|secondary)';
  const solta = new RegExp(String.raw`\bColor\s*\(\s*(red|hue|white|\.sRGB|\.displayP3|uiColor|\.system\w+)\b|\bUIColor\s*\(\s*(red|white|hue|displayP3)\b|\bUIColor\.(${sistema}|label|system\w+)\b|#colorLiteral|\bColor\.${sistema}\b|\.(foreground(Style|Color)|background|fill|stroke|strokeBorder|border|tint)\(\s*\.${sistema}\b|\.shadow\(\s*color:\s*\.${sistema}\b`);
  for(const f of arquivosSwift('app-ios/Custta')) assert.doesNotMatch(ler(f), solta, `${f}: use paleta.cor(.token)`);
});

test('catálogo de cores em dia com scripts/cores-app-ios.mjs e com os tokens da Paleta', async () => {
  execFileSync(process.execPath, ['scripts/cores-app-ios.mjs', '--conferir'], { cwd: RAIZ, stdio: 'pipe' });
  const paleta = ler('app-ios/Custta/Identidade/Paleta.swift');
  const enumToken = paleta.slice(paleta.indexOf('enum Token'), paleta.indexOf('}', paleta.indexOf('enum Token')));
  const tokens = [...enumToken.matchAll(/case \w+ = "(\w+)"/g)].map(m => m[1]).sort();
  const tabela = ler('scripts/cores-app-ios.mjs');
  // Uma pele só desde 21/10/2026: a Azul saiu do site e do app.
  assert.deepEqual(Object.keys((await import(join(RAIZ, 'scripts/cores-app-ios.mjs'))).CORES), ['Esmeralda'], 'só a pele Esmeralda');
  for(const pele of ['Esmeralda']){
    const bloco = tabela.slice(tabela.indexOf(`${pele}: {`), tabela.indexOf('}', tabela.indexOf(`${pele}: {`)));
    assert.deepEqual([...bloco.matchAll(/^\s+(\w+): \['/gm)].map(m => m[1]).sort(), tokens, `tokens da pele ${pele}`);
    // A linha fina dentro dos cartões de vidro: branco 9% no escuro, como o mockup (o Linha sólido, mais escuro que o vidro,
    // sumia a 1,0–1,5:1); no claro, o próprio Linha.
    const linha = bloco.match(/\bLinha: \['#\w+', '(#\w+)'\]/)[1];
    assert.match(bloco, new RegExp(`\\bLinhaNoVidro: \\['#FFFFFF17', '${linha}'\\]`), `LinhaNoVidro da pele ${pele}`);
    // O texto âmbar das etiquetas: no claro, um âmbar mais escuro que o Alerta do site, que ficava em 4,42:1 sob o véu do
    // topo no Pro Max (faixa que o laudo deixa de fora, porque ali o texto é borrado); no escuro, o próprio Alerta.
    const alerta = bloco.match(/\bAlerta: \['(#\w+)', '#\w+'\]/)[1];
    assert.match(bloco, new RegExp(`\\bAlertaEtiqueta: \\['${alerta}', '#7A5410'\\]`), `AlertaEtiqueta da pele ${pele}`);
    // O texto âmbar sobre o vidro do conteúdo (etapa 3, o --amber-v do mockup): no claro, #6F4705 (o Alerta do site dava
    // 3,79–4,15:1 sobre a aurora clara); no escuro, #FFD98A (o Alerta ficava em 3,12:1 no alto da tela Orçamento rolada, na
    // maior letra).
    assert.match(bloco, /\bAlertaNoVidro: \['#FFD98A', '#6F4705'\]/, `AlertaNoVidro da pele ${pele}`);
    // Decisão 6 da etapa 3: no Fosco escuro, o texto secundário é o do Transparente (o do Fosco ficava abaixo de 4,5:1 em
    // dois pontos claros da aurora); no claro, o do Fosco fica.
    const secundario = nome => bloco.match(new RegExp(`\\b${nome}: \\['(#\\w+)', '(#\\w+)'\\]`)).slice(1);
    const [foscoEscuro, foscoClaro] = secundario('SecundarioFosco'), [transparenteEscuro, transparenteClaro] = secundario('SecundarioTransparente');
    assert.equal(foscoEscuro, transparenteEscuro, `SecundarioFosco no escuro da pele ${pele}: o do Transparente`);
    assert.notEqual(foscoClaro, transparenteClaro, `SecundarioFosco no claro da pele ${pele}: o do Fosco`);
  }
  const pecas = ler('app-ios/Custta/Telas/PecasDaObra.swift');
  assert.match(pecas.slice(pecas.indexOf('struct LinhaFina')), /^[^}]*paleta\.cor\(\.linhaNoVidro\)/, 'a linha fina sobre o vidro usa o LinhaNoVidro');
  // Sobre o fundo âmbar, o texto é o AlertaEtiqueta, nunca o Alerta.
  for(const f of arquivosSwift('app-ios/Custta')){
    const t = ler(f), conta = token => (t.match(new RegExp(String.raw`\.${token}\b`, 'g')) || []).length;
    assert.equal(conta('alertaEtiqueta'), conta('alertaFundo'), `${f}: texto sobre a AlertaFundo no AlertaEtiqueta`);
  }
});

test('aurora nas mesmas cores do site, no escuro e no claro', async () => {
  const { CORES } = await import(join(RAIZ, 'scripts/cores-app-ios.mjs'));
  const css = ler('styles.css');
  const combos = { Esmeralda: [':root{', 'html[data-theme="light"]{'] };
  const hex = rgb => '#' + rgb.split(',').map(n => Number(n).toString(16).padStart(2, '0').toUpperCase()).join('');
  for(const [pele, [escuro, claro]] of Object.entries(combos)){
    for(const [lado, seletor] of [[0, escuro], [1, claro]]){
      const bloco = css.slice(css.indexOf(seletor + '\n    --aurora-1'));
      for(const n of [1, 2, 3, 4])
        assert.equal(CORES[pele][`Aurora${n}`][lado], hex(bloco.match(new RegExp(`--aurora-${n}:([\\d,]+);`))[1]), `${pele} Aurora${n}`);
    }
  }
});

test('cores de base iguais às do site, no escuro e no claro', async () => {
  const { CORES } = await import(join(RAIZ, 'scripts/cores-app-ios.mjs'));
  const css = ler('styles.css');
  const combos = { Esmeralda: [':root{', 'html[data-theme="light"]{'] };
  const site = { Fundo: 'bg', Superficie: 'surface-solid', Linha: 'line', Texto: 'text', TextoSecundario: 'muted', Marca: 'brand',
    Destaque: 'accent', Positivo: 'profit', Alerta: 'warn', Negativo: 'red', SobreMarca: 'btn-ink' };
  const hex = v => '#' + (v.length === 4 ? [...v.slice(1)].map(c => c + c).join('') : v.slice(1)).toUpperCase();
  for(const [pele, [escuro, claro]] of Object.entries(combos)){
    for(const [lado, seletor] of [[0, escuro], [1, claro]]){
      const bloco = css.slice(css.indexOf(seletor), css.indexOf('}', css.indexOf(seletor)));
      for(const [token, variavel] of Object.entries(site))
        assert.equal(CORES[pele][token][lado], hex(bloco.match(new RegExp(`--${variavel}:(#[0-9a-fA-F]+);`))[1]), `${pele} ${token} (--${variavel})`);
    }
  }
});

test('texto sobre sólido fecha 4,5:1 nos quatro combos', async () => {
  const { CORES, PARES_SOLIDOS } = await import(join(RAIZ, 'scripts/cores-app-ios.mjs'));
  const linear = c => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
  const luminancia = hex => {
    const [r, g, b] = [1, 3, 5].map(i => linear(parseInt(hex.slice(i, i + 2), 16) / 255));
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  };
  for(const [pele, tokens] of Object.entries(CORES)){
    for(const [lado, nome] of [[0, 'escuro'], [1, 'claro']]){
      for(const [texto, fundo] of PARES_SOLIDOS){
        const [a, b] = [luminancia(tokens[texto][lado]), luminancia(tokens[fundo][lado])];
        const razao = (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
        assert.ok(razao >= 4.5, `${pele} ${nome}: ${texto} sobre ${fundo} fica em ${razao.toFixed(2)}:1`);
      }
    }
  }
});

test('ícones em dia com o icons.js do site', async () => {
  execFileSync(process.execPath, ['scripts/icones-app-ios.mjs', '--conferir'], { cwd: RAIZ, stdio: 'pipe' });
  // O quadro do SVG (viewBox, linha e pontas) e o traço de cada ícone iguais aos do ICON() do site.
  const { USADOS, svg } = await import(join(RAIZ, 'scripts/icones-app-ios.mjs'));
  const { ICON } = require(join(RAIZ, 'icons.js'));
  const partes = s => {
    const [, abre, traco] = s.trim().match(/^<svg([^>]*)>([\s\S]*)<\/svg>$/);
    return { traco, ...Object.fromEntries([...abre.matchAll(/([\w-]+)="([^"]*)"/g)].map(m => [m[1], m[2]])) };
  };
  for(const nome of USADOS){
    const app = partes(svg(nome)), site = partes(ICON(nome));
    for(const chave of ['viewBox', 'fill', 'stroke-width', 'stroke-linecap', 'stroke-linejoin', 'traco'])
      assert.equal(app[chave], site[chave], `${nome}: ${chave} diferente do ICON() do site`);
  }
  // Todo tópico do site tem o seu ícone no catálogo: o que faltasse cairia no "etiqueta" do iconeDoCatalogo.
  const { TOPICOS } = require(join(RAIZ, 'calc.js'));
  for(const t of TOPICOS) assert.ok(USADOS.includes(t.ic), `${t.nm}: ícone ${t.ic} fora do USADOS`);
});

test('globo com os mesmos continentes do globe.js', () => {
  const pares = texto => [...texto.matchAll(/\[\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\]|\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)/g)]
    .map(m => (m[1] ?? m[3]) + ',' + (m[2] ?? m[4]));
  const js = ler('globe.js'), swift = ler('app-ios/Custta/Identidade/Globo.swift');
  const doSite = pares(js.slice(js.indexOf('const CONTINENTS'), js.indexOf('];', js.indexOf('const CONTINENTS'))));
  const doApp = pares(swift.slice(swift.indexOf('static let continentes'), swift.indexOf('    ]\n', swift.indexOf('static let continentes'))));
  assert.ok(doSite.length > 150);
  assert.deepEqual(doApp, doSite);
});

test('globo desenhado como o globe.js: giro, centro, raio, halo, aro, pontos e grade', () => {
  const js = ler('globe.js'), swift = ler('app-ios/Custta/Identidade/Globo.swift'), mov = ler('app-ios/Custta/Identidade/Movimento.swift');
  const n = (texto, re) => { const m = texto.match(re); assert.ok(m, `não achei ${re}`); return m.slice(1).map(Number); };
  const paradas = (texto, re, ordem) => [...texto.matchAll(re)].flatMap(m => ordem.map(i => Number(m[i])));
  const pares = {
    'ângulo inicial e giro (rad/s)': [[...n(js, /let angle=([\d.]+)/), n(js, /\(now-last\)\*([\d.]+)/)[0] * 1000], n(swift, /let angulo = ([\d.]+) \+ ([\d.]+) \* relogio\.segundos/)],
    'centro': [n(js, /cx=W\*([\d.]+); cy=H\*([\d.]+)/), n(swift, /x: tamanho\.width \* ([\d.]+), y: tamanho\.height \* ([\d.]+)/)],
    'raio': [n(js, /R=Math\.min\(H\*([\d.]+), W\*([\d.]+)\)/), n(swift, /min\(tamanho\.height \* ([\d.]+), tamanho\.width \* ([\d.]+)\)/)],
    'halo: raios': [n(js, /createRadialGradient\(cx,cy,R\*([\d.]+),cx,cy,R\*([\d.]+)\)/), n(swift, /startRadius: r \* ([\d.]+), endRadius: r \* ([\d.]+)/)],
    'halo: paradas': [paradas(js, /addColorStop\(([\d.]+),`rgba\(\$\{C\.halo\},([\d.]+)\)`\)/g, [1, 2]), paradas(swift, /halo\.opacity\(([\d.]+)\), location: ([\d.]+)\)/g, [2, 1])],
    'aro': [[...n(js, /arc\(cx,cy,R\*([\d.]+)/), ...n(js, /\$\{C\.ring\},([\d.]+)\)/), ...n(js, /lineWidth=([\d.]+)/)],
      [...n(swift, /c\.x - r \* ([\d.]+)/), ...n(swift, /aro\.opacity\(([\d.]+)\)\), lineWidth: ([\d.]+)/)]],
    'alfa por profundidade': [n(js, /const a=bright \? ([\d.]+)\+depth\*([\d.]+) : ([\d.]+)\+depth\*([\d.]+)/),
      n(swift, /alfa = terra \? ([\d.]+) \+ profundidade \* ([\d.]+) : ([\d.]+) \+ profundidade \* ([\d.]+)/)],
    'lado por profundidade': [n(js, /const s=bright \? ([\d.]+)\+depth\*([\d.]+) : ([\d.]+)\+depth\*([\d.]+)/),
      n(swift, /lado = terra \? ([\d.]+) \+ profundidade \* ([\d.]+) : ([\d.]+) \+ profundidade \* ([\d.]+)/)],
    'hemisfério da frente, brilho e folga da tela': [[...n(js, /if\(z<([\d.]+)\)/), ...n(js, /depth>([\d.]+) \?/), ...n(js, /sx<-(\d+)\|\|sx>W\+(\d+)/)],
      [...n(swift, /guard z >= ([\d.]+)/), ...n(swift, /terra && z > ([\d.]+)/), ...n(swift, /guard sx >= -(\d+), sx <= w \+ (\d+)/)]],
    'grade do celular': [[...n(js, /innerWidth<700 \? ([\d.]+)/), ...n(js, /let lat=(-?\d+); lat<=(\d+)/), ...n(js, /max\(cosL,([\d.]+)\)/), ...n(js, /lat<(-\d+) \? true/)],
      [...n(swift, /let passo = ([\d.]+)/), ...n(swift, /var lat = (-?[\d.]+)/), ...n(swift, /while lat <= (\d+)/), ...n(swift, /max\(cosL, ([\d.]+)\)/), ...n(swift, /lat < (-\d+) \|\|/)]],
    'pixels por ponto': [n(js, /Math\.min\(([\d.]+), window\.devicePixelRatio/), n(swift, /densidade: CGFloat = ([\d.]+)/)],
    'no claro a 40%': [n(ler('styles.css'), /html\[data-theme="light"\] #globe\{opacity:([\d.]+)\}/), n(swift, /compositingGroup\(\)\.opacity\(([\d.]+)\)/)],
    '30 quadros por segundo': [n(js, /INTERVALO = 1000\/(\d+)/), n(mov, /preferred: (\d+)\)/)],
    'volta 400 ms depois da rolagem': [n(js, /setTimeout\(retomar,(\d+)\)/), n(mov, /\.milliseconds\((\d+)\)/)],
  };
  const arred = x => Math.round(x * 1e6) / 1e6;
  for(const [nome, [site, app]] of Object.entries(pares)) assert.deepEqual(app.map(arred), site.map(arred), nome);
});

test('aurora com a deriva do site: os três quadros, 26 s de ida e volta, ease-in-out', () => {
  const css = ler('styles.css'), swift = ler('app-ios/Custta/Identidade/Aurora.swift');
  assert.match(css, /animation:aurora-deriva 26s ease-in-out infinite alternate/);
  const quadro = /translate3d\((-?[\d.]+)%,(-?[\d.]+)%,0\) rotate\((-?[\d.]+)deg\) scale\(([\d.]+)\)/g;
  const doSite = [...css.slice(css.indexOf('@keyframes aurora-deriva')).matchAll(quadro)].slice(0, 3)
    .map(m => [m[1] / 100, m[2] / 100, Number(m[3]), Number(m[4])]);
  const doApp = [...swift.matchAll(/Deriva\(x: (-?[\d.]+), y: (-?[\d.]+), giro: (-?[\d.]+), escala: ([\d.]+)\)/g)]
    .map(m => m.slice(1, 5).map(Number));
  assert.equal(doSite.length, 3);
  assert.deepEqual(doApp, doSite);
  assert.match(swift, /truncatingRemainder\(dividingBy: 52\)/, 'ciclo de 52 s: 26 de ida e 26 de volta');
  assert.match(ler('app-ios/Custta/Identidade/Movimento.swift'), /static let suave = CurvaBezier\(x1: 0\.42, y1: 0, x2: 0\.58, y2: 1\)/,
    'o ease-in-out do CSS');
});

test('aurora desenhada como o #aurora do site: brilhos, base de 100°, camada, altura e máscara', () => {
  const css = ler('styles.css'), swift = ler('app-ios/Custta/Identidade/Aurora.swift');
  const regra = css.slice(css.indexOf('#aurora{'), css.indexOf('@keyframes aurora-deriva'));
  const pct = x => Math.round(x * 100);
  // No CSS o primeiro fundo fica por cima; no app os brilhos vão de baixo para cima.
  const doSite = [...regra.matchAll(/radial-gradient\((\d+)% (\d+)% at (\d+)% (\d+)%, rgba\(var\(--aurora-(\d)\),var\(--aurora-a\)\), transparent (\d+)%\)/g)]
    .map(m => [+m[1], +m[2], +m[3], +m[4], m[5] - 1, +m[6]]).reverse();
  const doApp = [...swift.slice(swift.indexOf('static let brilhos')).matchAll(/\(([\d.]+), ([\d.]+), ([\d.]+), ([\d.]+), (\d), ([\d.]+)\)/g)]
    .slice(0, 4).map(m => [pct(m[1]), pct(m[2]), pct(m[3]), pct(m[4]), +m[5], pct(m[6])]);
  assert.equal(doSite.length, 4);
  assert.deepEqual(doApp, doSite, 'os quatro brilhos: tamanho, centro, cor e fim');
  const linear = regra.slice(regra.indexOf('linear-gradient(100deg'));
  const base = [...linear.slice(0, linear.indexOf(';')).matchAll(/rgba\(var\(--aurora-(\d)\),var\(--aurora-a\)\)(?: (\d+)%)?/g)]
    .map((m, i) => [m[1] - 1, m[2] ? +m[2] : i ? 100 : 0]);
  assert.deepEqual([...swift.matchAll(/\.init\(color: cores\[(\d)\]\.opacity\(a\), location: ([\d.]+)\)/g)].map(m => [+m[1], pct(m[2])]), base,
    'base: linear-gradient(100deg, A3, A1 35%, A2 65%, A3)');
  assert.equal(+swift.match(/let angulo = ([\d.]+) \* \.pi \/ 180/)[1], +regra.match(/linear-gradient\((\d+)deg/)[1], 'base a 100°');
  const [, cima, lado] = regra.match(/inset:-(\d+)% -(\d+)%/);
  const [, largura, altura] = swift.match(/\.frame\(width: largura \* ([\d.]+), height: altura \* ([\d.]+)\)/);
  assert.deepEqual([pct((largura - 1) / 2), pct((altura - 1) / 2)], [+lado, +cima], 'camada −30% dos lados e −15% em cima e embaixo');
  assert.equal(pct(swift.match(/geo\.size\.height \* ([\d.]+)/)[1]), +regra.match(/height:(\d+)vh/)[1], '78% da altura da tela');
  assert.equal(pct(swift.match(/fundo\.opacity\(0\), location: ([\d.]+)/)[1]), +regra.match(/linear-gradient\(to bottom,#000 (\d+)%,transparent\)/)[1],
    'some para baixo a partir de 40%');
});

test('animação própria respeita Reduzir movimento', () => {
  for(const f of arquivosSwift('app-ios/Custta')){
    const t = ler(f);
    if(/withAnimation|\.animation\(|\.transition\(/.test(t))
      assert.match(t, /accessibilityReduceMotion|reduzirMovimento/, `${f}: anima sem olhar o Reduzir movimento`);
    for(const m of t.matchAll(/LogoEscrito\(animado: ([^,)]+)/g))
      assert.match(m[1], /animaFundo/, `${f}: o logo se escreve sem olhar Reduzir movimento e Pouca Energia`);
  }
});

test('o logo escrito do app usa os caminhos do logo do site', () => {
  const svg = ler('index.html').match(/<svg class="logo-escrito"[\s\S]*?<\/svg>/)[0];
  const swift = ler('app-ios/Custta/Identidade/LogoEscrito.swift');
  const caminhos = [...svg.matchAll(/\sd="([^"]+)"/g)].map(m => m[1]);
  assert.ok(caminhos.length >= 16, 'caminhos do logo no index.html');
  for(const d of caminhos) assert.ok(swift.includes(`"${d}"`), `caminho do logo ausente no app: ${d.slice(0, 40)}…`);
});

test('logo escrito na ordem e nos tempos do site: letra, máscara, pena, traço, carimbo e varredura', () => {
  const svg = ler('index.html').match(/<svg class="logo-escrito"[\s\S]*?<\/svg>/)[0], css = ler('styles.css');
  const swift = ler('app-ios/Custta/Identidade/LogoEscrito.swift');
  const n = (texto, re) => { const m = texto.match(re); assert.ok(m, `não achei ${re}`); return m.slice(1).join(',').split(',').map(Number); };
  // Cada letra, na ordem do desenho, é revelada pelas penas da sua máscara (le-m0…le-m5), numeradas le-p0…le-p8.
  const mascaras = Object.fromEntries([...svg.matchAll(/<mask id="(le-m\d)"[\s\S]*?<\/mask>/g)]
    .map(m => [m[1], [...m[0].matchAll(/class="le-pena le-p(\d)" pathLength="1" d="([^"]+)"/g)]]));
  const doSite = [...svg.matchAll(/<path class="le-(neutra|tt)" mask="url\(#(le-m\d)\)" d="([^"]+)"/g)]
    .map(m => ({ glifo: m[3], penas: mascaras[m[2]].map(p => p[2]), tt: m[1] === 'tt' }));
  const doApp = [...swift.matchAll(/Letra\(glifo: "([^"]+)",\s+penas: \[([^\]]+)\],\s+tt: (true|false)\)/g)]
    .map(m => ({ glifo: m[1], penas: [...m[2].matchAll(/"([^"]+)"/g)].map(p => p[1]), tt: m[3] === 'true' }));
  assert.equal(doSite.length, 6);
  assert.deepEqual(doApp, doSite, 'as letras na ordem do site, cada uma com as penas da sua máscara');
  assert.deepEqual(Object.values(mascaras).flat().map(p => +p[1]), [0, 1, 2, 3, 4, 5, 6, 7, 8], 'penas na ordem le-p0…le-p8');
  // Os números do styles.css (duração, curva, início) e do desenho.
  const traco = i => n(css, new RegExp(`\\.le-p${i}\\{animation:leEscreve ([\\d.]+)s cubic-bezier\\(([\\d.,]+)\\) ([\\d.]+)s both\\}`));
  const carimbo = n(css, /\.le-ponto\{animation:leCarimba ([\d.]+)s cubic-bezier\(([\d.,]+)\) ([\d.]+)s both\}/);
  const varre = n(css, /\.le-varredura\{animation:leVarre ([\d.]+)s cubic-bezier\(([\d.,]+)\) ([\d.]+)s both\}/);
  const curva = nome => n(swift, new RegExp(`${nome} = CurvaBezier\\(x1: ([\\d.]+), y1: ([\\d.]+), x2: ([\\d.]+), y2: ([\\d.]+)\\)`));
  const pares = {
    'traços: início e duração (le-p0…le-p8)': [[0, 1, 2, 3, 4, 5, 6, 7, 8].flatMap(i => [traco(i)[5], traco(i)[0]]),
      [...swift.match(/static let tracos[^=]+= \[([^\]]+)\]/)[1].matchAll(/\(([\d.]+), ([\d.]+)\)/g)].flatMap(m => [+m[1], +m[2]])],
    'traços: a mesma curva nos nove': [[0, 1, 2, 3, 4, 5, 6, 7, 8].flatMap(i => traco(i).slice(1, 5)), Array(9).fill(curva('curvaDoTraco')).flat()],
    'traço: largura e dashoffset de 1,1 a 0': [[...n(css, /\.le-pena\{[^}]*stroke-width:(\d+)/), ...n(css, /leEscreve\{from\{stroke-dashoffset:([\d.]+)\}/)],
      [...n(swift, /larguraDaPena = ([\d.]+)/), ...n(swift, /let fim = 1 - ([\d.]+) \* \(1 -/)]],
    'carimbo: início, duração e curva com repique': [[carimbo[5], carimbo[0], ...carimbo.slice(1, 5)],
      [...n(swift, /carimbo = \(inicio: ([\d.]+), duracao: ([\d.]+)\)/), ...curva('curvaDoCarimbo')]],
    'vibração 120 ms depois do carimbo (auth.js)': [[carimbo[5] + n(ler('auth.js'), /'leCarimba'\) setTimeout\([^,]+, (\d+)\)/)[0] / 1000],
      n(swift, /vibracao = ([\d.]+)/)],
    'letras inteiras (le-fim)': [n(css, /\.le-fim\{animation:leAparece [\d.]+s linear ([\d.]+)s both\}/), n(swift, /inteiras = ([\d.]+)/)],
    'varredura: início, duração e curva': [[varre[5], varre[0], ...varre.slice(1, 5)],
      [...n(swift, /varredura = \(inicio: ([\d.]+), duracao: ([\d.]+)\)/), ...curva('curvaDaVarredura')]],
    'varredura: retângulo que cresce de x 1440': [n(svg, /class="le-varredura" x="(\d+)" y="(-\d+)" width="(\d+)" height="(\d+)"/),
      n(swift, /CGRect\(x: (\d+), y: (-\d+), width: (\d+) \* v, height: (\d+)\)/)],
    'degradê do tt (le-deg)': [n(svg, /id="le-deg" x1="0" y1="(-?\d+)" x2="0" y2="(-?\d+)"/),
      n(swift, /startPoint: CGPoint\(x: 0, y: (-?\d+)\), endPoint: CGPoint\(x: 0, y: (-?\d+)\)/)],
    'tt escuro some (leSome)': [n(css, /\.le-tt\{animation:leSome [\d.]+s linear ([\d.]+)s both\}/), n(swift, /static let some = ([\d.]+)/)],
    'caixa (viewBox)': [n(svg, /viewBox="(-?\d+) (-?\d+) (\d+) (\d+)"/), n(swift, /caixa = CGRect\(x: (-?\d+), y: (-?\d+), width: (\d+), height: (\d+)\)/)],
  };
  const arred = x => Math.round(x * 1e6) / 1e6;
  for(const [nome, [site, app]] of Object.entries(pares)) assert.deepEqual(app.map(arred), site.map(arred), nome);
});

test('fonte do botão do Google: Roboto Medium travada, registrada e com a licença', () => {
  const fonte = readFileSync(join(RAIZ, 'app-ios/Custta/Fontes/Roboto-Medium.ttf'));
  const hash = require('node:crypto').createHash('sha256').update(fonte).digest('hex');
  assert.equal(hash, '663bedb17df44144ea2ccf4c3a3c1853547bcfed2395ad29904502ea92c74bcb', 'Roboto v3.016 (unhinted/static) do googlefonts/roboto-3-classic');
  assert.match(ler('app-ios/Custta/Fontes/OFL-Roboto.txt'), /SIL Open Font License, Version 1\.1/);
  assert.match(ler('app-ios/Custta/Info.plist'), /<key>UIAppFonts<\/key>\s*<array>\s*<string>Roboto-Medium\.ttf<\/string>/);
});

test('G do botão do Google igual ao do site, byte a byte (o oficial, com as cores do Google)', () => {
  assert.ok(readFileSync(join(RAIZ, 'app-ios/Custta/Assets.xcassets/LogoGoogle.imageset/google-g.svg'))
    .equals(readFileSync(join(RAIZ, 'google-g.svg'))), 'copie o google-g.svg da raiz para o LogoGoogle.imageset');
});

test('ganchos dos testes e do laudo só no Debug: chave custta.* (fora tema, pele e vidro) e CUSTTA_* dentro de #if DEBUG', () => {
  for(const f of arquivosSwift('app-ios/Custta')){
    const pilha = [];
    ler(f).split('\n').forEach((linha, i) => {
      const d = linha.trim();
      if(/^#if\b/.test(d)) pilha.push({ debug: /^#if\s+DEBUG\b/.test(d), ehDebug: /^#if\s+DEBUG\b/.test(d) });
      else if(/^#else\b/.test(d)){ const topo = pilha.at(-1); if(topo?.ehDebug) topo.debug = false; }
      else if(/^#endif\b/.test(d)) pilha.pop();
      else if(/"(custta\.(?!(tema|pele|vidro)")|CUSTTA_)/.test(linha))
        assert.ok(pilha.some(x => x.debug), `${f}:${i + 1}: gancho fora do #if DEBUG: ${d}`);
    });
  }
});

test('mensagem e aviso anunciados a cada texto novo, não só ao aparecer', () => {
  for(const f of arquivosSwift('app-ios/Custta'))
    assert.doesNotMatch(ler(f), /\.onAppear\s*\{\s*AccessibilityNotification\.Announcement/,
      `${f}: anuncie no .onChange(of:initial:); o 2º erro seguido não reaparece e o VoiceOver não o lê`);
});

test('escurecimento sob o vidro segue o esquema da tela: no claro, nenhum', () => {
  assert.match(ler('app-ios/Custta/Identidade/Vidro.swift'),
    /let escuro = esquema == \.dark\n[\s\S]*?paleta\.cor\(\.fundo\)\.opacity\(vidro\.escurecimento\(papel, escuro: escuro\)\)/,
    'a Superficie passa o esquema da tela ao escurecimento (o ImageRenderer não serve de guarda: o vidro dele varia)');
});

test('título grande de Obras e de Ajustes e a versão em Ajustes com o halo no escuro', () => {
  // O título da barra é do UIKit, branco puro sobre a aurora: no Pro Max, sem o halo, o "Obras" fica em 4,41:1 e a
  // versão, texto solto, em 4,42:1. O laudo de leitura só cobra o portão no Mac; esta guarda vale também na CI.
  for(const tela of ['ObrasView', 'AjustesView'])
    assert.match(ler(`app-ios/Custta/Telas/${tela}.swift`), /\.haloDoTituloDaBarra\(\)/, `${tela}: o halo atrás do título grande`);
  assert.match(ler('app-ios/Custta/Telas/AjustesView.swift'),
    /Text\(Self\.versao\)[^}]*?HaloDoTitulo\(grande: false, opacidade: HaloDoTitulo\.naBarra\)/, 'AjustesView: o halo atrás da versão');
  // O halo sobe além da versão: por cima do painel, escurecia a base do "Sair da conta" (11/255 no Pro Max).
  assert.match(ler('app-ios/Custta/Telas/AjustesView.swift'),
    /HaloDoTitulo\(grande: false, opacidade: HaloDoTitulo\.naBarra\) \}(?:\s*\/\/[^\n]*)*\s*\.zIndex\(-1\)/,
    'AjustesView: a versão e o halo atrás do painel');
});

test('ícone junto de texto cresce com a letra: o dos Label, a seta da dica de entrar, o olho da senha e o logo da conta', () => {
  // A auditoria de tipo dinâmico do Xcode só olha texto: um ícone de tamanho fixo passa por ela e vira um
  // ponto ao lado da letra grande (D7 da conferência da Tarefa 10; a legenda do gráfico e o olho, na revisão da 11;
  // o logo da conta no falta pouco, na revisão dos ajustes da 11).
  for(const f of arquivosSwift('app-ios/Custta'))
    for(const m of ler(f).matchAll(/icon: \{[^\n]*?\.frame\(width: ([^,]+), height: ([^)]+)\)/g))
      assert.doesNotMatch(`${m[1]} ${m[2]}`, /^\d|\s\d/, `${f}: ícone de Label em tamanho fixo (use @ScaledMetric)`);
  const dica = ler('app-ios/Custta/Telas/EntradaView.swift').match(/Text\("Role para entrar"\)\s*\n\s*Image\([^\n]*/);
  assert.ok(dica, 'a dica "Role para entrar" com a seta logo depois');
  assert.doesNotMatch(dica[0], /\.frame\(width: \d/, 'a seta da dica tem 1em no mockup: cresce com a letra (@ScaledMetric)');
  const olho = ler('app-ios/Custta/Identidade/Componentes.swift').match(/"Icones\/olho"\)\s*\n\s*\.resizable\(\)[^\n]*/);
  assert.ok(olho, 'o olho do campo de senha');
  assert.doesNotMatch(olho[0], /\.frame\(width: \d/, 'o olho da senha cresce com a letra do campo (@ScaledMetric)');
  const conta = ler('app-ios/Custta/Telas/EntradaView.swift').match(/Image\(systemName: "apple\.logo"\)[\s\S]*?in: \.circle\)/);
  assert.ok(conta, 'o logo da conta Apple ou Google no círculo do falta pouco');
  assert.doesNotMatch(conta[0], /\.frame\(width: \d/, 'o logo da Apple é letra (.body): o círculo e o G do Google crescem junto (@ScaledMetric)');
});

test('texto cresce com a letra: lineLimit e minimumScaleFactor só no botão do Google, no indicador da barra e no dinheiro', () => {
  // A auditoria de texto cortado do Xcode não vê dentro de um elemento que o VoiceOver lê inteiro (o cartão da
  // obra): com o nome da obra preso numa linha, ela passa na maior letra. Ficam numa linha, por decisão, o botão
  // do Google (letra travada, fora da auditoria de tipo dinâmico), o indicador de sincronização da barra, o
  // dinheiro (ValorEmDinheiro e o visor do teclado de valor, mockup da etapa 2: encolhe para caber em vez de quebrar)
  // e os títulos da barra, o pequeno da obra e o da folha, e o nome da linha na barra das teclas encaixadas (cortam como o do
  // sistema, em vez de empurrar os botões).
  const fixos = new Set(['BotaoGoogle', 'IndicadorDeSincronizacao', 'ValorEmDinheiro', 'VisorDoValor', 'TituloPequenoDaBarra',
    'TituloDaFolha', 'BarraDasTeclas']);
  for(const f of arquivosSwift('app-ios/Custta')){
    const t = ler(f);
    for(const m of t.matchAll(/\.(lineLimit|minimumScaleFactor)\(/g)){
      const dono = [...t.slice(0, m.index).matchAll(/^(?:private )?struct (\w+)/gm)].at(-1)?.[1];
      assert.ok(fixos.has(dono), `${f}: ${m[0]} em ${dono}; texto cortado se resolve deixando o texto crescer`);
    }
  }
  // Dinheiro por extenso sozinho num Text quebra na letra grande ("R$" numa linha, o número na outra): vai pelo
  // ValorEmDinheiro, que encolhe.
  for(const f of arquivosSwift('app-ios/Custta/Telas'))
    assert.doesNotMatch(ler(f), /Text\(moeda\(/, `${f}: dinheiro por extenso num Text; use o ValorEmDinheiro`);
  // E o ValorEmDinheiro fica numa linha: sem o lineLimit, num iPhone de 375 pt o valor quebra antes de encolher.
  const componentes = ler('app-ios/Custta/Identidade/Componentes.swift');
  assert.match(componentes.slice(componentes.indexOf('struct ValorEmDinheiro')), /^[^}]*\.lineLimit\(1\)\s*\.minimumScaleFactor\(0\.5\)/,
               'o ValorEmDinheiro numa linha, encolhendo até a metade');
});

test('dica do fim do modo total: cresce com a letra e quebra linha, sem altura fixa', () => {
  // A auditoria não vê o fim da tela Orçamento no modo total na maior letra: ela diminui a letra, a lista longa encolhe para
  // cima da rolagem e a tela fica vazia (achados sem elemento; a cena dela fica a 2200 pt). As linhas do fim são as mesmas
  // da cena; só a dica não aparece em outro lugar. Que ela não corta, garante o código: letra do sistema, nenhum limite de
  // linhas (guarda acima), quebra para baixo e nenhuma altura fixa.
  const t = ler('app-ios/Custta/Telas/PecasDaTelaOrcamento.swift');
  const inicio = t.indexOf('struct DicaDoModoTotal');
  assert.ok(inicio >= 0, 'a DicaDoModoTotal');
  const dica = t.slice(inicio, t.indexOf('\n}\n', inicio));
  assert.match(dica, /Text\(dicaDoModoTotal\)\n\s*\.font\(\.footnote\)/, 'a dica na letra do sistema, que cresce');
  assert.match(dica, /\.fixedSize\(horizontal: false, vertical: true\)/, 'a dica quebra linha e cresce para baixo');
  assert.doesNotMatch(dica, /\.frame\([^)]*height|\.lineLimit|minimumScaleFactor/, 'sem altura fixa nem limite de linhas');
});

test('teclado de valor: ordem do telefone, teto do núcleo, "zero zero", o valor falado a cada tecla e teclas até o AX2', () => {
  // Nenhum teste de tela vê isso: eles tocam as teclas pelo identificador (a ordem não aparece), nenhum digita além do
  // teto, o anúncio do VoiceOver não chega ao XCUITest e a auditoria não mede o limite de tamanho das teclas.
  const t = ler('app-ios/Custta/Identidade/TecladoDeValor.swift');
  const tabela = t.match(/static let linhas: \[\[TeclaDeValor\]\] = \[\n([\s\S]*?)\n {4}\]/);
  assert.ok(tabela, 'a tabela das teclas');
  const linhas = tabela[1].trim().split('\n').map(l => [...l.matchAll(/\.(?:digito\((\d)\)|(duploZero|apagar))/g)].map(m => m[1] ?? m[2]));
  assert.deepEqual(linhas, [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['duploZero', '0', 'apagar']], 'ordem do telefone, 1 2 3 em cima');
  const tocar = t.slice(t.indexOf('private func tocar('), t.indexOf('\n    }\n', t.indexOf('private func tocar(')));
  assert.match(tocar, /let novo = aplicarTecla\(centavos, tecla\)\n\s*guard novo != centavos else \{ return \}\n\s*centavos = novo\n/, 'o teto e a tecla ignorada vêm do núcleo');
  assert.match(tocar, /AccessibilityNotification\.Announcement\(fmtCentavos\(novo\)\)\.post\(\)/, 'o VoiceOver ouve o valor novo a cada tecla');
  assert.match(t, /case \.duploZero: "zero zero"/);
  assert.match(t, /TeclaDoValor\(tecla: tecla, tamanho: tamanho\) \{ tocar\(tecla\) \}\n\s*\.dynamicTypeSize\(\.\.\.DynamicTypeSize\.accessibility2\)/, 'as teclas param no AX2');
  // As teclas encaixadas da folha do orçamento (etapa 3) são a mesma grade: a ordem, o teto e o anúncio valem nos dois.
  assert.match(t, /GradeDeTeclas\(centavos: \$centavos, tamanho: \.padrao\)/, 'o TecladoDeValor usa a grade');
  assert.match(ler('app-ios/Custta/Identidade/TecladoEncaixado.swift'), /GradeDeTeclas\(centavos: \$centavos, tamanho: \.encaixado\)/,
    'as teclas encaixadas usam a mesma grade');
  assert.match(t, /\.accessibilityElement\(children: \.ignore\)\n\s*\.accessibilityLabel\("Valor"\)/, 'o visor é um elemento só');
});

test('tela Orçamento: o gasto lançado pelo + dela não rola a obra por baixo', () => {
  // Nenhum teste de tela vê isso: a obra por baixo da tela Orçamento não está à vista, e o foco do VoiceOver não chega ao
  // XCUITest. Sem a condição, a lista escondida rolaria até o gasto novo e o foco do VoiceOver iria para uma linha fora da tela.
  const t = ler('app-ios/Custta/Telas/ObraView.swift');
  assert.match(t, /\.onChange\(of: folhas\.destaque\) \{ _, d in if let d, caminho\.last == \.obra\(obra\.id\) \{ mostrar\(d/,
    'a obra só mostra o gasto salvo quando está no topo do caminho');
});

test('ações da fase: gravação recusada avisa, como o apagar e as folhas', () => {
  // Nenhum teste de tela recusa a gravação no mudar: sem o alerta, a ação recusada não faria nada ao toque.
  const t = ler('app-ios/Custta/Telas/ObraView.swift');
  assert.match(t, /if resultado == \.naoCarregado \{ naoCarregado = true \}\n\s*if resultado == \.gravou \{ mudouAFase \+= 1 \}/,
    'o mudar da fase: o alerta do site antes de ver os dados, e a vibração só do que gravou');
});

test('ações da fase: a troca na mola só sem Reduzir movimento, e a vibração leve só da ação feita aqui', () => {
  // Nenhum teste de tela vê isso: o XCUITest espera a mola acabar e não sente a vibração, e a guarda de animação acima é
  // por arquivo (a ObraView já olha o Reduzir movimento ao fechar a linha arrastada).
  const t = ler('app-ios/Custta/Telas/ObraView.swift');
  const inicio = t.indexOf('private func mudar(');
  assert.ok(inicio > 0, 'a mudança da fase na ObraView');
  const mudar = t.slice(inicio, t.indexOf('\n    }\n', inicio));
  assert.match(mudar, /withAnimation\(opcoes\.reduzirMovimento \? nil : \.spring\(/, 'com Reduzir movimento, a etiqueta e as ações trocam sem mola');
  assert.match(mudar, /if resultado == \.gravou \{ mudouAFase \+= 1 \}/, 'vibra só quando a mudança foi gravada');
  assert.match(t, /\.sensoryFeedback\(\.impact\(weight: \.light\), trigger: mudouAFase\)/, 'a vibração leve, só da ação feita aqui (a de outro aparelho não vibra)');
  assert.equal(t.split('mudouAFase += 1').length - 1, 1, 'só o mudar soma: um onChange da fase vibraria também com a mudança vinda de outro aparelho');
});

test('folha da venda: gravação recusada avisa, como a folha do gasto', () => {
  // Sem o alerta, "Confirmar venda" recusado não faria nada ao toque (o achado da T29 no mudar da fase).
  const t = ler('app-ios/Custta/Telas/FolhaDaVenda.swift');
  assert.match(t, /case \.naoCarregado: naoCarregado = true/, 'antes de ver os dados, o alerta do site');
});

test('folha da obra e apagar obra: gravação recusada avisa, como as outras folhas', () => {
  // O apagar obra grava em Obras, depois de a folha descer (a linha sai com a animação à vista), e avisa pelo alerta de
  // Obras.
  const f = ler('app-ios/Custta/Telas/FolhaDaObra.swift');
  const p = ler('app-ios/Custta/Telas/PrincipalView.swift');
  const inicio = p.indexOf('case .apagar(let id):');
  assert.ok(inicio > 0, 'o apagar obra em Obras');
  const apagar = p.slice(inicio, p.indexOf('\n    }\n', inicio));
  assert.equal(f.match(/case \.naoCarregado: naoCarregado = true/g)?.length, 2, 'criar e salvar: antes de ver os dados, o alerta do site');
  assert.match(apagar, /if resultado == \.naoCarregado \{ avisoDoMais = \.naoCarregado\(modelo\.mensagemDeNaoCarregado\) \}/);
});

test('folha do orçamento: gravação recusada avisa, e tirar o orçamento leva a tela Orçamento de volta antes de a folha descer', () => {
  // A recusa de antes de ver os dados avisa dentro da folha, como nas outras. Tirar (pelo botão ou pelo "Salvar" vazio) volta
  // a tela Orçamento para a obra com a folha ainda em cima, e a folha desce no turno seguinte: no mesmo turno, a navegação
  // levaria junto a descida da folha (o achado da T34 com o gasto lançado de dentro de uma vendida). O "Tirar orçamento"
  // confirmado não grava duas vezes.
  const t = ler('app-ios/Custta/Telas/FolhaDoOrcamento.swift');
  assert.equal(t.match(/case \.naoCarregado: naoCarregado = true/g)?.length, 1, 'antes de ver os dados, o alerta do site');
  assert.match(t, /folhas\.navegar\(\.sairDoOrcamento\(rascunho\.obraId\)\)\n\s*Task \{ @MainActor in folhas\.fechar\(\) \}/,
    'a tela Orçamento volta e, no turno seguinte, a folha desce');
  assert.match(t.slice(t.indexOf('private func tirar() {')), /^private func tirar\(\) \{\n\s*guard folhas\.aberta != nil else \{ return \}\n/,
    'a guarda do toque duplo também no tirar');
  // Com Reduzir movimento, a lista vai até a linha ativa sem animar e o cursor fica parado (nenhum teste de tela vê a
  // animação: o XCUITest espera a rolagem acabar).
  assert.match(t, /if opcoes\.reduzirMovimento \{ leitor\.scrollTo\(campo, anchor: \.center\) \}\n\s*else \{ withAnimation/,
    'a rolagem até a linha ativa sem animação com Reduzir movimento');
  assert.match(t, /if opcoes\.reduzirMovimento \{\n\s*barra\(visivel: true\)/, 'o cursor parado com Reduzir movimento');
});

test('folha do orçamento: o teclado físico apaga como a tecla da tela, e a linha ativa volta ao meio quando a letra muda', () => {
  // O ⌫ de um teclado de verdade chega à folha como .delete (U+0008) e o ⌦ como .deleteForward: os dois são a tecla de apagar
  // da tela. Nenhum teste de tela prova isso: o typeKey do XCTest não entrega o apagar a uma view que não é campo de texto
  // (os dígitos ele entrega, e o testTecladoFisicoDigitaNaLinhaAtiva os confere). Com a letra trocada e as teclas abertas,
  // as linhas mudam de altura e a rolagem fica onde estava: sem voltar ao meio, a linha ativa sumia da vista (e, na auditoria
  // de tipo dinâmico, os achados saíam sem elemento).
  const t = ler('app-ios/Custta/Telas/FolhaDoOrcamento.swift');
  assert.match(t, /\.onKeyPress\(keys: \[\.delete, \.deleteForward\], phases: \.down\) \{ _ in\n\s*tocar\(\.apagar, em: campo\)/,
    'o apagar do teclado físico vai para a tecla de apagar');
  assert.match(t, /\.onChange\(of: tamanho\) \{ if let ativo \{ rolar\(ate: ativo, leitor\) \} \}/,
    'a linha ativa volta ao meio quando a letra muda');
});

test('folhas que gravam: o segundo toque de um toque duplo não grava de novo', () => {
  // A folha leva uns 0,4 s descendo depois de gravar, e o segundo toque de um toque duplo ainda chega no botão: sem a
  // guarda, o gasto entrava duas vezes (T22) e a obra nova também, com outro id. Os testes de tela do toque duplo falham
  // só às vezes sem ela; aqui, a guarda é a primeira linha da ação de cada folha.
  // A edição empurrada numa folha de origem (etapa 3) não fecha a folha: a guarda dela é a edição ainda no topo do caminho.
  const acoes = {
    'app-ios/Custta/Telas/FolhaDoGasto.swift': ['private func salvar() {', /guard saida\.aberta\(folhas, gastoId: rascunho\.editado\?\.id\) else \{ return \}/],
    'app-ios/Custta/Telas/FolhaDaVenda.swift': ['private func confirmar(inicio: String, hoje: String) {', /guard folhas\.aberta != nil else \{ return \}/],
    'app-ios/Custta/Telas/FolhaDaObra.swift': ['private func salvar() {', /guard folhas\.aberta != nil else \{ return \}/],
    'app-ios/Custta/Telas/FolhaDoOrcamento.swift': ['private func salvar() {', /guard folhas\.aberta != nil else \{ return \}/],
  };
  for(const [f, [assinatura, guarda]] of Object.entries(acoes)){
    const t = ler(f);
    assert.equal(t.split(assinatura).length, 2, `${f}: ${assinatura}`);
    assert.match(t.slice(t.indexOf(assinatura) + assinatura.length), new RegExp(String.raw`^\n(?:\s*\/\/[^\n]*\n)*\s*` + guarda.source + String.raw`\n`),
                 `${f}: a guarda do toque duplo na primeira linha da ação`);
  }
  const origem = ler('app-ios/Custta/Telas/FolhaDeOrigem.swift');
  assert.match(origem, /case \.folha: folhas\.aberta != nil\n\s*case \.origem\(let origem\): origem\.editando\(gastoId\)/,
               'a guarda da edição: a folha aberta ou, na origem, a edição no topo do caminho');
  assert.match(origem, /func editando\(_ gastoId: String\?\) -> Bool \{\n\s*guard let gastoId else \{ return false \}\n\s*return caminho\.last == \.editar\(gastoId\)/);
});

test('volta à folha de origem: a trava do puxar lida no FolhaDoApp, o voltar escondido por modificador e o Z fixo por passo', () => {
  // Nenhum teste de tela vê isso. A trava do puxar lida no corpo de quem monta a pilha refaria a lista da origem a cada tecla
  // da descrição; dentro do passo ela não chega à folha (medido em 19/10), e o puxar descartaria a mudança. O voltar trocado
  // por um `if` de estrutura recriaria o passo e derrubaria o foco do teclado na primeira tecla. E a ação de escape escolhida
  // pelo rascunho trocaria o passo do mesmo jeito, ou engoliria o voltar do VoiceOver (revisão da T22).
  const passos = ler('app-ios/Custta/Telas/FolhaEmPassos.swift');
  assert.match(passos, /func folhaDoApp\(perguntar: @escaping \(\) -> Bool,/, 'o folhaDoApp recebe uma função, e não o valor');
  assert.match(passos, /let temOQuePerder = perguntar\(\)[\s\S]*?\.interactiveDismissDisabled\(temOQuePerder\)/, 'lida no corpo do próprio FolhaDoApp');
  for(const f of arquivosSwift('app-ios/Custta').filter(f => !f.endsWith('FolhaEmPassos.swift')))
    assert.doesNotMatch(ler(f), /\.interactiveDismissDisabled\(/, `${f}: a trava do puxar só no FolhaDoApp, fora da pilha`);
  const aPagar = ler('app-ios/Custta/Telas/FolhaDoAPagar.swift');
  assert.match(aPagar, /NavigationStack\(path: \$origem\.caminho\) \{[\s\S]*?\n        \}\n(?:\s*\/\/[^\n]*\n|\s*\.[^\n]*\n)*?\s*\.folhaDoApp\(perguntar: \{ origem\.temOQuePerder \}/,
               'o folhaDoApp em volta da pilha da origem, com a mudança lida por ele');
  const origem = ler('app-ios/Custta/Telas/FolhaDeOrigem.swift');
  assert.match(origem, /\.navigationBarBackButtonHidden\(sujo\)\n\s*\.toolbar \{\n\s*if sujo \{\n\s*ToolbarItem\(placement: \.topBarLeading\)/,
               'o voltar do sistema sai por modificador, e o chevron entra pela barra');
  assert.equal(origem.match(/if sujo/g)?.length, 1, 'nenhum outro `if sujo`: a estrutura do passo não muda com a mudança');
  assert.match(origem, /\.gesture\(BordaQuePergunta\(ativa: sujo\)/, 'a borda que pergunta, ligada só com mudança');
  const gasto = ler('app-ios/Custta/Telas/FolhaDoGasto.swift');
  assert.match(gasto, /private var escape: EscapeDoPasso \{\n\s*if case \.origem\(let origem\) = saida \{\n\s*return \.proprio \{ if rascunho\.temOQuePerder \{ perguntandoAVolta = true \} else \{ origem\.voltar\(\) \} \}\n\s*\}\n\s*return raiz \? \.fechar : \.sistema\n\s*\}/,
               'o Z da edição: fixo pela saída e pela raiz; o rascunho só decide dentro da ação');
  assert.match(gasto, /\.passoDaFolha\(rascunho\.editado == nil \? "Novo gasto" : "Editar gasto", subtitulo: subtitulo, fechar: lado, escape: escape\)/);
});

test('folha: o R$ das linhas de dinheiro no texto do número e o degradê da folha atrás do botão de baixo', () => {
  // Na maior letra só o ValorEmDinheiro encolhe: um "R$" num Text à parte ficava maior que o número. Nas linhas da folha
  // ele vem pelo prefixo do ValorEmDinheiro (o visor do teclado tem o dele, do tamanho do número). A LinhaDeDinheiro é
  // medida por pixel no LinhaDeDinheiroTests; a linha do valor do gasto é privada da folha, e só esta guarda a vê.
  for(const f of ['app-ios/Custta/Identidade/PecasDaFolha.swift', ...arquivosSwift('app-ios/Custta/Telas')])
    assert.ok(!/Text\("R\$"\)/.test(ler(f)), `${f}: "R$" num Text à parte; use o prefixo do ValorEmDinheiro`);
  // O botão de baixo de cada folha (Salvar, Confirmar venda, Criar obra) tem atrás o degradê da folha, o .f-pe do mockup:
  // o que rola por baixo some antes de encostar nele (na maior letra, num iPhone de 375 pt, a nota da venda passava
  // cortada seca). E encosta no fundo, sem recuo embaixo: com 8, ficava 8 pt acima do mockup (784 no 18 Pro) e do Avançar
  // do teclado de valor. Com o teclado do sistema aberto (folha com campo de texto), fica 10 acima dele, o .f-pe.sobe do
  // mockup: com 0, o botão encostava no teclado. Nenhum teste de tela vê o degradê.
  const degrade = /\.background \{\s*LinearGradient\(stops: \[\.init\(color: paleta\.cor\(\.folha\), location: 0\.62\), \.init\(color: paleta\.cor\(\.folha\)\.opacity\(0\), location: 1\)\],\s*startPoint: \.bottom, endPoint: \.top\)\s*\.ignoresSafeArea\(\)/;
  let botoes = 0;
  for(const f of arquivosSwift('app-ios/Custta/Telas')){
    const t = ler(f);
    for(const m of t.matchAll(/\.safeAreaInset\(edge: \.bottom, spacing: 0\) \{/g)){
      let fim = m.index + m[0].length, nivel = 1;
      for(; nivel > 0 && fim < t.length; fim++) nivel += t[fim] === '{' ? 1 : t[fim] === '}' ? -1 : 0;
      const bloco = t.slice(m.index, fim);
      if(!bloco.includes('BotaoDaFolha(')) continue;
      botoes++;
      assert.match(bloco, degrade, `${f}: botão de baixo da folha sem o degradê da folha atrás`);
      // A folha com campo de texto tem o recuo do teclado; a sem (a venda), 0.
      const comTeclado = t.includes('TextField(');
      assert.match(bloco, comTeclado ? /\.padding\(\.bottom, foco == nil \? 0 : 10\)/ : /\.padding\(\.bottom, 0\)/,
                   `${f}: botão de baixo da folha ${comTeclado ? 'sem os 10 acima do teclado' : 'com recuo embaixo'}`);
    }
  }
  assert.ok(botoes >= 3, 'o Salvar do gasto, o Confirmar venda e o Criar obra');
});

test('campo de texto que quebra linha: o exemplo desenhado num Text, e o prompt transparente', () => {
  // O prompt do TextField fica numa linha só e corta com reticências na maior letra, mesmo com axis: .vertical ("Ex: Casa
  // Alp…" no nome da obra), e a auditoria não vê o exemplo de um campo. O campo que quebra linha desenha o exemplo num Text,
  // que quebra, e deixa o prompt transparente, só para o VoiceOver, como os campos da entrada.
  let campos = 0;
  for(const f of arquivosSwift('app-ios/Custta')){
    const t = ler(f);
    for(const m of t.matchAll(/\bTextField\(/g)){
      let fim = m.index + m[0].length, nivel = 1;
      for(; nivel > 0 && fim < t.length; fim++) nivel += t[fim] === '(' ? 1 : t[fim] === ')' ? -1 : 0;
      const chamada = t.slice(m.index, fim);
      if(!chamada.includes('axis:')) continue;
      campos++;
      const prompt = chamada.match(/prompt: (Text\([^)]*\))\.foregroundStyle\(\.clear\)/);
      assert.ok(prompt, `${f}: campo que quebra linha com o exemplo visível no prompt`);
      assert.ok(t.split(prompt[1]).length > 2, `${f}: o exemplo ${prompt[1]} não está desenhado num Text fora do prompt`);
    }
  }
  assert.ok(campos >= 2, 'os campos da entrada e o nome da obra');
});

test('barra: o botão de vidro (o sair, o lápis, a sincronização) sem o vidro da barra por trás', () => {
  // A barra do iOS 26 põe um fundo de vidro atrás de cada item; o círculo de vidro do sair ou do lápis ficaria vidro
  // dentro de vidro. Nenhum teste de tela vê o fundo; esta guarda liga cada peça de vidro posta na barra ao
  // .sharedBackgroundVisibility(.hidden).
  const fontes = arquivosSwift('app-ios/Custta').map(f => [f, ler(f)]);
  const deVidro = new Set();
  for(const [, t] of fontes)
    for(const m of t.matchAll(/struct (\w+)(?:<[^>]*>)?: View \{[\s\S]*?\n\}/g)) if(m[0].includes('.superficie(')) deVidro.add(m[1]);
  let itens = 0;
  for(const [f, t] of fontes){
    for(const m of t.matchAll(/ToolbarItem\([^)]*\) \{ (\w+)[ ({]/g)){
      if(!deVidro.has(m[1])) continue;
      itens++;
      const depois = t.slice(m.index + m[0].length).split('\n').slice(0, 2).join('\n');
      assert.match(depois, /\.sharedBackgroundVisibility\(\.hidden\)/, `${f}: ${m[1]} na barra com o vidro da barra por trás`);
    }
  }
  assert.ok(itens >= 4, 'o sair e a sincronização de Obras, o lápis e a sincronização da obra');
});

test('folha do gasto na letra grande: o nome da obra e o do tópico ficam embaixo do rótulo e à esquerda', () => {
  // Na letra padrão o valor fica à direita, junto da seta. Na letra grande a linha empilha, com o rótulo em cima, e o
  // mockup alinha o valor à esquerda (.f-lin .d{text-align:left} na AX5): com o .trailing fixo, o nome que quebra em
  // duas linhas mostrava a 1ª à direita, em cima da 2ª (o EstadosUITests mede a linha "Obra" por pixel).
  const t = ler('app-ios/Custta/Telas/FolhaDoGasto.swift');
  assert.match(t, /var alinhamentoDoValor: TextAlignment \{ tamanho\.isAccessibilitySize \? \.leading : \.trailing \}/);
  for(const valor of ['Text(nome)', 'Text(t?.nome ?? rascunho.topico)'])
    assert.ok(t.includes(`${valor}.foregroundStyle(paleta.cor(.texto)).multilineTextAlignment(alinhamentoDoValor)`),
      `${valor}: no alinhamento do valor`);
});

test('peças da folha na maior letra: rótulo, nota, cabeçalho dos tópicos e exemplo da descrição como no mockup', () => {
  // O mockup na AX5 (parte3.html): o rótulo da linha no secundário (também no .f-valor da letra padrão, as linhas de
  // 60 pt) e menor que o valor: no subheadline, 49 pt na AX5, e não no footnote do mockup (44 pt), que na AX1 fica nos
  // 23 pt do body da última letra comum, e a auditoria de tipo dinâmico marca o rótulo que não cresce ali. A nota e o
  // cabeçalho a 22 pt da borda (34 na letra padrão), e a nota com os 2 pt que faltam embaixo (36 pt em duas linhas de
  // 18); o exemplo da descrição quebra linha (o prompt do campo encolhia para caber numa) e o prompt fica no campo,
  // transparente, para o VoiceOver. A seta, a nota, as teclas e o botão o EstadosUITests e o GastoUITests medem.
  const pecas = ler('app-ios/Custta/Identidade/PecasDaFolha.swift');
  assert.match(pecas, /Text\(rotulo\)\n\s*\.font\(grande \? \.subheadline : nil\)\n\s*\.foregroundStyle\(paleta\.cor\(grande \|\| altura > 52 \? \.secundarioTransparente : \.texto\)\)/,
    'o rótulo da linha');
  assert.match(pecas, /\.padding\(\.bottom, 2\)\n\s*\.frame\(maxWidth: \.infinity, alignment: \.leading\)\n\s*\.padding\(\.horizontal, tamanho\.isAccessibilitySize \? 22 : 34\)/,
    'a nota');
  const gasto = ler('app-ios/Custta/Telas/FolhaDoGasto.swift');
  assert.match(gasto, /\.padding\(\.horizontal, tamanho\.isAccessibilitySize \? 22 : 34\)/, 'o cabeçalho dos tópicos');
  assert.match(gasto, /Text\("Ex: 50 sacos de cimento"\)\n\s*\.foregroundStyle\(paleta\.cor\(\.textoTerciario\)\)/, 'o exemplo, que quebra linha');
  assert.match(gasto, /prompt: Text\("Ex: 50 sacos de cimento"\)\.foregroundStyle\(\.clear\)/, 'o prompt transparente');
});

test('apagar no fim da folha: a linha inteira é o botão, no vermelho de negativo e em peso médio', () => {
  // O "Apagar obra" e o "Apagar gasto" são a única linha de um grupo sólido da folha (o .f-lin.destr do mockup): a cor é
  // o --red, que no app é .negativo (o .erroNoVidro é o da nota sobre o vidro), o peso é 500, e o toque é a linha
  // inteira. A medida e o contentShape ficam dentro do rótulo: fora dele, só o texto recebe o toque e o VoiceOver.
  let botoes = 0;
  for(const f of arquivosSwift('app-ios/Custta')){
    const t = ler(f);
    for(const m of t.matchAll(/\.accessibilityIdentifier\("apagar(?:Obra|Gasto)"\)/g)){
      botoes++;
      const inicio = t.lastIndexOf('Button', m.index);
      assert.ok(t.startsWith('Button {', inicio), `${f}: ${m[0]} sem rótulo próprio, o toque fica só no texto`);
      const abre = t.indexOf('label: {', inicio);
      let fim = abre + 'label: {'.length, nivel = 1;
      for(; nivel > 0 && fim < t.length; fim++) nivel += t[fim] === '{' ? 1 : t[fim] === '}' ? -1 : 0;
      const rotulo = t.slice(abre, fim), depois = t.slice(fim, m.index);
      assert.match(rotulo, /\.frame\(maxWidth: \.infinity, minHeight: 52\)\s*\.contentShape\(\.rect\)/, `${f}: ${m[0]} sem a linha inteira no rótulo`);
      assert.match(rotulo, /\.fontWeight\(\.medium\)/, `${f}: ${m[0]} fora do peso 500 do mockup`);
      assert.match(depois, /\.foregroundStyle\(paleta\.cor\(\.negativo\)\)/, `${f}: ${m[0]} fora do vermelho de negativo`);
    }
  }
  assert.equal(botoes, 2, 'o "Apagar obra" e o "Apagar gasto"');
});

test('gasto lançado de dentro de uma vendida: a obra troca por trás da folha, e a folha desce no turno seguinte', () => {
  // A troca da obra (o .trocar da PrincipalView) vai sem animação. No mesmo turno do fechar, essa transação valia também
  // para a folha, que sumia de uma vez em vez de descer (vídeo da revisão da T34): a troca vem primeiro, com a folha em
  // cima, e a folha fecha no turno seguinte, com a animação dela.
  const t = ler('app-ios/Custta/Telas/FolhaDoGasto.swift');
  assert.match(t, /folhas\.navegar\(\.trocar\(obraId\)\)\n\s*Task \{ @MainActor in folhas\.fechar \{ folhas\.destacar\(ids, novo: novo\) \} \}/,
    'a troca da obra e, no turno seguinte, o fechar da folha');
});

test('folha do A pagar: as peças da lista são filhas diretas da LazyVStack, com o fundo do grupo desenhado por peça', () => {
  // A LazyVStack só fatia filhos diretos: com o grupo do mês num VStack (o GrupoDaFolha), o grupo inteiro seria uma peça
  // só, criada de uma vez com todas as linhas (o detalhe do tópico, com a mesma lista, passa de cem gastos). Nenhum teste
  // de tela vê isso: a tela fica igual.
  const t = ler('app-ios/Custta/Telas/FolhaDoAPagar.swift');
  const pecas = t.search(/ForEach\(pecas(?:DaOrigem\([^)]*\))?\) \{/);
  assert.ok(pecas > 0, 'as peças da lista num ForEach');
  let nivel = 0, abre = -1;
  for(let i = pecas - 1; i >= 0 && abre < 0; i--){
    if(t[i] === '}') nivel++;
    else if(t[i] === '{'){ if(nivel === 0) abre = i; else nivel--; }
  }
  assert.match(t.slice(0, abre), /LazyVStack\([^)]*\)\s*$/, 'o ForEach das peças direto dentro da LazyVStack');
  let fim = t.indexOf('{', pecas) + 1;
  for(let n = 1; n > 0 && fim < t.length; fim++) n += t[fim] === '{' ? 1 : t[fim] === '}' ? -1 : 0;
  assert.equal(t.slice(pecas, fim).match(/\.modifier\(FundoDoGrupo\(/g)?.length, 2, 'o fundo do grupo no cabeçalho e em cada gasto');
});

test('scripts dos testes locais do app: emuladores e conferência cruzada', () => {
  const s = JSON.parse(ler('package.json')).scripts;
  for(const nome of ['test:app-ios:emuladores', 'test:app-ios:cruzado']){
    assert.match(s[nome] || '', /firebase emulators:exec --config firebase\.test\.json --project demo-custta-phase2 --only firestore,auth/, nome);
  }
  assert.match(s['test:app-ios:emuladores'], /scripts\/simulador-ios\.mjs --testar CusttaTests --emuladores/);
  assert.match(s['test:app-ios:cruzado'], /tests\/app-ios\/cruzado\.mjs/);
});

test('conferência cruzada: o texto do orçamento na lista é o do site', () => {
  const site = ler('app.js'), cruzado = ler('tests/app-ios/cruzado.mjs');
  for(const [noSite, noCruzado] of [
    ['${orc.pct}% · passou ${moneyCurto(-orc.sobra)}', '${orc.pct}% · passou ${C.moneyCurto(-orc.sobra)}'],
    ['${orc.pct}% do orçamento', '${orc.pct}% do orçamento'],
  ]){
    assert.ok(site.includes(noSite), `app.js mudou o texto da lista: ${noSite}`);
    assert.ok(cruzado.includes(noCruzado), `cruzado.mjs ficou para trás de app.js: ${noCruzado}`);
  }
});

test('simulador dos testes locais: CUSTTA_SIMULADOR escolhe pelo id, e teste que falha não segura a rodada no diagnose', async () => {
  const { escolherSimulador, argumentosDoTeste } = await import(join(RAIZ, 'scripts/simulador-ios.mjs'));
  const lista = {
    'com.apple.CoreSimulator.SimRuntime.iOS-26-4': [{ udid: 'A', name: 'iPhone 17', isAvailable: true }],
    'com.apple.CoreSimulator.SimRuntime.iOS-27-0': [{ udid: 'B', name: 'iPad Pro', isAvailable: true }, { udid: 'C', name: 'iPhone 18 Pro', isAvailable: true }],
  };
  assert.equal(escolherSimulador(lista), 'C', 'sem a variável, o de sempre: o primeiro iPhone do iOS mais novo');
  assert.equal(escolherSimulador(lista, 'A'), 'A', 'cada agente no seu simulador');
  assert.throws(() => escolherSimulador(lista, 'X'), /CUSTTA_SIMULADOR=X/, 'id que não existe para, em vez de cair no simulador de outro');
  const args = argumentosDoTeste(['CusttaTests'], 'platform=iOS Simulator,id=C');
  const i = args.indexOf('-collect-test-diagnostics');
  assert.deepEqual(args.slice(i, i + 2), ['-collect-test-diagnostics', 'never'], 'sem o simctl diagnose, que segura a rodada até 10 min');
  assert.deepEqual(args.slice(args.indexOf('-destination'), args.indexOf('-destination') + 2), ['-destination', 'platform=iOS Simulator,id=C']);
  assert.ok(args.includes('-only-testing:CusttaTests'));
});

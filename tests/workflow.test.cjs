'use strict';
const assert = require('assert');
const { readFileSync, readdirSync, existsSync } = require('fs');
const { join } = require('path');

const dir = join(__dirname, '..', '.github', 'workflows');
const arquivos = readdirSync(dir).filter(f => f.endsWith('.yml'));
assert.ok(arquivos.length >= 3, `poucos workflows: ${arquivos}`);

/* Em run:, ${{ }} vira texto do script antes de o shell rodar: título de PR, nome
   de branch ou mensagem de commit ali viram comando. Só passam números do run e
   segredos; o resto entra por env: e o shell lê como variável. */
const PERMITIDAS_EM_RUN = /^(github\.run_number|github\.run_attempt|secrets\.[A-Z0-9_]+)$/;
function expressoesEmRun(texto){
  const linhas = texto.split('\n');
  const blocos = [];
  for(let i = 0; i < linhas.length; i++){
    const m = /^(\s*)(?:-\s+)?run:\s*(.*)$/.exec(linhas[i]);
    if(!m) continue;
    if(!/^[|>]/.test(m[2])){ blocos.push(m[2]); continue; }
    const recuo = m[1].length;
    const corpo = [];
    for(let j = i + 1; j < linhas.length; j++){
      const l = linhas[j];
      if(l.trim() && l.length - l.trimStart().length <= recuo) break;
      corpo.push(l);
    }
    blocos.push(corpo.join('\n'));
  }
  return blocos.flatMap(b => [...b.matchAll(/\$\{\{([^}]*)\}\}/g)].map(m => m[1].trim()));
}
// O leitor pega bloco com linha em branco no meio e ignora env: (lá a expressão é segura).
assert.deepStrictEqual(expressoesEmRun([
  'jobs:', '  x:', '    steps:',
  '      - run: |', '          echo um', '', '          echo "${{ github.head_ref }}"',
  '      - name: y', '        env:', '          T: ${{ github.event.issue.title }}',
  '        run: echo "${{ secrets.A }}"',
].join('\n')), ['github.head_ref', 'secrets.A']);
let expressoesVistas = 0;

// Gatilhos que rodam com segredo em resposta a código ou texto de terceiros.
// O GitHub aceita várias grafias do gatilho: mapa (on:\n  trigger:), curta
// (on: trigger), lista (on: [a, trigger]), mapa inline (on: {trigger: {}}) e
// até comentário — por isso o teste tira comentários e procura a palavra.
const GATILHO_PERIGOSO = /\b(pull_request_target|workflow_run|issue_comment)\b/;
const temGatilhoPerigoso = texto => GATILHO_PERIGOSO.test(texto.replace(/#.*$/gm, ''));
// Testa cada grafia e certifica que comentário não ativa o alerta.
assert.ok(temGatilhoPerigoso('on: pull_request_target'), 'forma curta não foi detectada');
assert.ok(temGatilhoPerigoso('on: [push, pull_request_target]'), 'forma lista não foi detectada');
assert.ok(temGatilhoPerigoso('on:\n  - workflow_run'), 'forma híbrida não foi detectada');
assert.ok(temGatilhoPerigoso('on: {pull_request_target: {}}'), 'forma mapa inline não foi detectada');
assert.ok(temGatilhoPerigoso('on: issue_comment'), 'forma curta issue_comment não foi detectada');
assert.ok(temGatilhoPerigoso('on:\n  pull_request_target:'), 'forma mapa tradicional não foi detectada');
assert.ok(!temGatilhoPerigoso('# não usar pull_request_target\non:\n  push:'), 'comentário ativou alerta indevido');
assert.ok(!temGatilhoPerigoso('on:\n  pull_request:\n  push:'), 'pull_request normal foi bloqueado');

// Regras que valem para todo workflow, não só para o do push.
for(const arquivo of arquivos){
  const texto = readFileSync(join(dir, arquivo), 'utf8');
  const usos = [...texto.matchAll(/uses:\s*([^\s#]+)/g)].map(m => m[1]);
  assert.ok(usos.length > 0, `${arquivo}: workflow sem actions`);
  for(const uso of usos){
    const ref = uso.split('@')[1] || '';
    assert.match(ref, /^[0-9a-f]{40}$/, `${arquivo}: action sem SHA imutável: ${uso}`);
  }
  assert.match(texto, /permissions:\s*\n\s*contents:\s*read/, `${arquivo}: sem permissão mínima`);
  assert.ok(!temGatilhoPerigoso(texto),
    `${arquivo}: gatilho que roda com segredo para texto de terceiros`);
  for(const expr of expressoesEmRun(texto)){
    expressoesVistas++;
    assert.match(expr, PERMITIDAS_EM_RUN,
      `${arquivo}: \${{ ${expr} }} dentro de run: — passe por env: e leia como variável do shell`);
  }
}
assert.ok(expressoesVistas >= 2, 'o leitor de run: não achou nem o número do build do TestFlight — está quebrado');

const workflow = readFileSync(join(dir, 'push-diario.yml'), 'utf8');

const nodeVersion = Number(workflow.match(/node-version:\s*['"]?(\d+)/)?.[1]);
assert.ok(nodeVersion >= 22, `Firebase Admin 14 exige Node >=22; workflow usa ${nodeVersion}`);

// dois disparos por dia: 12:00 UTC = 9h e 21:00 UTC = 18h de Brasília.
// Quem mexer aqui tem que mexer no PERIODO junto — é o cron que o escolhe.
const crons = [...workflow.matchAll(/-\s*cron:\s*'([^']+)'/g)].map(m => m[1]);
assert.deepStrictEqual(crons, ['0 12 * * *', '0 21 * * *'], `crons inesperados: ${crons}`);
assert.match(workflow, /PERIODO:.*'0 12 \* \* \*'.*'manha'/,
  'o PERIODO precisa derivar do cron da manhã');

const ios = readFileSync(join(dir, 'ios-build.yml'), 'utf8');

assert.match(ios, /runs-on:\s*macos-latest/, 'o build iOS precisa do runner macOS');

// ios-build.yml fica sem assinatura de propósito: roda sem secrets (até em PR
// de fork) e prova que a Release manual (perfil "Custta App Store" no
// pbxproj) não quebra um build sem assinatura. A assinatura de verdade e o
// envio moram em ios-testflight.yml.
assert.match(ios, /CODE_SIGNING_ALLOWED=NO/, 'o build precisa dispensar assinatura');
assert.match(ios, /CODE_SIGNING_REQUIRED=NO/, 'o build precisa dispensar assinatura');

// Rodar a cada push queima runner à toa — o build nativo só interessa quando
// o diff mexe em algo que pode quebrá-lo.
assert.ok(!/^on:\n(?:.*\n)*?\s{2}push:/m.test(ios),
  'o build iOS não pode disparar em todo push');
assert.match(ios, /workflow_dispatch:/, 'o build iOS precisa do botão manual');

// Capacitor 8 é SPM: não existe Podfile no projeto, e `pod install` aqui só
// falharia depois de dez minutos de runner pago. Os comentários do YAML saem
// antes da checagem — eles explicam justamente por que o passo não existe.
const iosSemComentario = ios.split('\n').filter(l => !/^\s*#/.test(l)).join('\n');
assert.ok(!/pod install/.test(iosSemComentario), 'projeto é SPM, não CocoaPods');
assert.ok(!existsSync(join(__dirname, '..', 'ios', 'App', 'Podfile')),
  'apareceu um Podfile: o build do CI assume SPM');

// Os pacotes locais do Package.swift apontam para node_modules, então npm ci
// precisa vir antes do xcodebuild.
assert.ok(ios.indexOf('npm ci') < ios.indexOf('xcodebuild \\'),
  'npm ci precisa rodar antes do xcodebuild');

// xcodebuild -scheme só enxerga scheme compartilhado; o do Xcode local fica em
// xcuserdata, que é ignorado pelo git e nunca chega no runner.
const scheme = join(__dirname, '..', 'ios', 'App', 'App.xcodeproj',
  'xcshareddata', 'xcschemes', 'App.xcscheme');
assert.ok(existsSync(scheme), 'falta o scheme compartilhado App.xcscheme');
const xml = readFileSync(scheme, 'utf8');
assert.match(xml, /BlueprintName\s*=\s*"App"/, 'scheme não aponta para o target App');
assert.match(xml, /ReferencedContainer\s*=\s*"container:App\.xcodeproj"/,
  'scheme aponta para container errado');

const tf = readFileSync(join(dir, 'ios-testflight.yml'), 'utf8');
const tfSemComentario = tf.split('\n').filter(l => !/^\s*#/.test(l)).join('\n');
assert.match(tf, /runs-on:\s*macos-latest/, 'o envio precisa do runner macOS');
assert.match(tf, /workflow_dispatch:/, 'o envio precisa do botão manual');
// Cada execução vira um build no TestFlight: nada de disparo em todo push.
assert.ok(!/^on:\n(?:.*\n)*?\s{2}push:/m.test(tf), 'o envio não pode disparar em push');
assert.match(tf, /cancel-in-progress:\s*false/, 'cancelar no meio pode matar um upload');
assert.ok(!/pod install/.test(tfSemComentario), 'projeto é SPM, não CocoaPods');
assert.ok(tf.indexOf('npm ci') < tf.indexOf('xcodebuild \\'), 'npm ci precisa rodar antes do xcodebuild');
// Re-run repete o run_number; a Apple recusa build repetido.
assert.match(tf, /CURRENT_PROJECT_VERSION="\$\{\{ github\.run_number \}\}\.\$\{\{ github\.run_attempt \}\}"/,
  'build number precisa crescer e não repetir em re-run');
assert.match(tf, /if:\s*always\(\)[\s\S]*delete-keychain/, 'keychain temporária precisa sumir mesmo com falha');
for(const s of ['ASC_KEY_ID', 'ASC_ISSUER_ID', 'ASC_KEY_P8', 'APPLE_TEAM_ID', 'DIST_CERT_P12', 'DIST_CERT_SENHA', 'PERFIL_APP_STORE'])
  assert.match(tf, new RegExp(`secrets\\.${s}\\b`), `workflow não lê o secret ${s}`);
assert.ok(!/-----BEGIN/.test(tf), 'chave literal no workflow — repositório é público');
assert.match(tf, /AppleWWDRCAG3\.cer/, 'sem o intermediário WWDR G3 a identidade não é válida para assinar');

// PR de fork não recebe secrets — sem essa guarda o job roda vermelho com
// "secret ausente" em vez de simplesmente não disparar.
assert.match(tf, /github\.event\.pull_request\.head\.repo\.full_name\s*==\s*github\.repository/,
  'falta a guarda de PR de fork no job enviar');

// Perfil errado ainda assina, mas gera .ipa que a Apple recusa lá na frente —
// o Name e o TeamIdentifier do perfil precisam ser conferidos contra o
// esperado antes do archive.
assert.match(tf, /TeamIdentifier/, 'perfil precisa ter o TeamIdentifier conferido');
assert.match(tf, /!=\s*"Custta App Store"/, 'perfil precisa ter o Name conferido contra "Custta App Store"');
assert.match(tf, /TEAM"\s*!=\s*"\$APPLE_TEAM_ID"/,
  'perfil precisa comparar o time do perfil com APPLE_TEAM_ID');

// Sem jargão de plano interno sobrevivendo no comentário do workflow.
assert.ok(!/Task 2/.test(tf), 'comentário ainda referencia "Task 2" (jargão de plano interno)');

const exportOpts = readFileSync(join(__dirname, '..', 'ios', 'App', 'ExportOptions.plist'), 'utf8');
assert.match(exportOpts, /<key>method<\/key>\s*<string>app-store-connect<\/string>/);
assert.match(exportOpts, /<key>destination<\/key>\s*<string>upload<\/string>/);
assert.match(exportOpts, /<key>signingStyle<\/key>\s*<string>manual<\/string>/);
assert.match(exportOpts, /<key>teamID<\/key>\s*<string>4S7JKDKN27<\/string>/);
assert.match(exportOpts, /<key>br\.com\.custta\.app<\/key>\s*<string>Custta App Store<\/string>/);

// Pacotes Swift: o ios-build tem um botão para resolver de novo e mostrar o Package.resolved
// novo, que é como a versão travada é atualizada.
assert.match(ios, /resolver_de_novo:/, 'ios-build sem o botão de resolver os pacotes Swift de novo');

/* Pacotes Swift travados: o xcodebuild dos dois workflows usa só as versões do
   Package.resolved versionado, e cada pacote vem de repositório de dono revisado,
   preso por versão e commit — nunca por branch. Versão nova entra por commit. */
// googleads: google-ads-on-device-conversion-ios-sdk, puxado pelo GoogleAppMeasurement do Firebase.
const DONOS_SWIFT = new Set(['ionic-team', 'firebase', 'google', 'openid', 'googleads']);
function pinsForaDaLista(pins){
  return pins.filter(p => {
    const m = /^https:\/\/github\.com\/([^/]+)\/[^/]+?(?:\.git)?$/.exec(p.location || '');
    return !m || !DONOS_SWIFT.has(m[1]) || !/^[0-9a-f]{40}$/.test(p.state?.revision || '') || !p.state?.version;
  }).map(p => p.identity || p.location);
}
const commit40 = 'a'.repeat(40);
assert.deepStrictEqual(pinsForaDaLista([
  { identity: 'estranho', location: 'https://github.com/outro-dono/x.git', state: { revision: commit40, version: '1.0.0' } },
  { identity: 'em-branch', location: 'https://github.com/firebase/y.git', state: { revision: commit40, branch: 'main' } },
  { identity: 'ok', location: 'https://github.com/google/z', state: { revision: commit40, version: '2.0.0' } },
]), ['estranho', 'em-branch']);
for(const [nome, yml] of [['ios-build', iosSemComentario], ['ios-testflight', tfSemComentario]])
  assert.match(yml, /-onlyUsePackageVersionsFromResolvedFile/, `${nome}: xcodebuild sem trava de versão dos pacotes Swift`);
const resolved = join(__dirname, '..', 'ios', 'App', 'App.xcodeproj', 'project.xcworkspace', 'xcshareddata', 'swiftpm', 'Package.resolved');
assert.ok(existsSync(resolved), 'falta o Package.resolved versionado');
const pins = JSON.parse(readFileSync(resolved, 'utf8')).pins || [];
assert.ok(pins.some(p => /capacitor-swift-pm/.test(p.location)), 'o Package.resolved não tem o Capacitor — arquivo errado?');
assert.deepStrictEqual(pinsForaDaLista(pins), [], 'pacote Swift de dono não revisado ou preso a branch');

console.log('ok - Actions com SHA imutável e permissão mínima; build iOS sem assinatura e sob demanda; envio ao TestFlight assinado e sob demanda');

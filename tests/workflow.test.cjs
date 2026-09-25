'use strict';
const assert = require('assert');
const { readFileSync, readdirSync, existsSync } = require('fs');
const { join } = require('path');

const dir = join(__dirname, '..', '.github', 'workflows');
const arquivos = readdirSync(dir).filter(f => f.endsWith('.yml'));
assert.ok(arquivos.length >= 3, `poucos workflows: ${arquivos}`);

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
}

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

// Sem a matrícula na Apple não há certificado; o build só existe sem assinatura.
// Quando a conta sair, quem ligar a assinatura tira estas linhas de propósito.
assert.match(ios, /CODE_SIGNING_ALLOWED=NO/, 'o build precisa dispensar assinatura');
assert.match(ios, /CODE_SIGNING_REQUIRED=NO/, 'o build precisa dispensar assinatura');

// Minuto de macOS custa 10x. Rodar a cada push queima a cota do mês em dias.
assert.ok(!/^on:\n(?:.*\n)*?\s{2}push:/m.test(ios),
  'o build iOS não pode disparar em todo push — a cota macOS é 10x');
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

const exportOpts = readFileSync(join(__dirname, '..', 'ios', 'App', 'ExportOptions.plist'), 'utf8');
assert.match(exportOpts, /<key>method<\/key>\s*<string>app-store-connect<\/string>/);
assert.match(exportOpts, /<key>destination<\/key>\s*<string>upload<\/string>/);
assert.match(exportOpts, /<key>signingStyle<\/key>\s*<string>manual<\/string>/);
assert.match(exportOpts, /<key>teamID<\/key>\s*<string>4S7JKDKN27<\/string>/);
assert.match(exportOpts, /<key>br\.com\.custta\.app<\/key>\s*<string>Custta App Store<\/string>/);

console.log('ok - Actions com SHA imutável e permissão mínima; build iOS sem assinatura e sob demanda; envio ao TestFlight assinado e sob demanda');

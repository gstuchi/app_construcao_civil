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

console.log('ok - Actions com SHA imutável e permissão mínima; build iOS sem assinatura e sob demanda');

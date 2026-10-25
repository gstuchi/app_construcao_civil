'use strict';
const assert = require('assert');
const { readFileSync, readdirSync, existsSync } = require('fs');
const { join } = require('path');

const dir = join(__dirname, '..', '.github', 'workflows');
// O GitHub executa .yml e .yaml: ler só um dos dois deixaria o outro fora de todas as regras abaixo.
const ehWorkflow = f => /\.ya?ml$/.test(f);
const arquivos = readdirSync(dir).filter(ehWorkflow);
assert.ok(arquivos.length >= 3, `poucos workflows: ${arquivos}`);
assert.deepStrictEqual(['a.yml', 'b.yaml', 'c.yml.bak', 'd.txt', 'yaml'].filter(ehWorkflow), ['a.yml', 'b.yaml'],
  'o leitor de workflows tem de ver .yml e .yaml, e só eles');

/* Em run:, ${{ }} vira texto do script antes de o shell rodar: título de PR, nome
   de branch ou mensagem de commit ali viram comando, e um segredo ali sai pelo texto do script. Só passam os
   números do run; segredos e o resto entram por env: e o shell lê como variável. */
const PERMITIDAS_EM_RUN = /^(github\.run_number|github\.run_attempt)$/;
function expressoesEmRun(texto){
  const linhas = texto.split(/\r?\n/);
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
  return blocos.flatMap(b => [...b.matchAll(/\$\{\{([\s\S]*?)\}\}/g)].map(m => m[1].trim()));
}
// O leitor pega bloco com linha em branco no meio e ignora env: (lá a expressão é segura).
const AMOSTRA = [
  'jobs:', '  x:', '    steps:',
  '      - run: |', '          echo um', '', '          echo "${{ github.head_ref }}"',
  '      - name: y', '        env:', '          T: ${{ github.event.issue.title }}',
  '        run: echo "${{ secrets.A }}"',
];
assert.deepStrictEqual(expressoesEmRun(AMOSTRA.join('\n')), ['github.head_ref', 'secrets.A']);
// Chave dentro da expressão não a esconde: format('{0}', ...) devolve o texto de fora
// como comando, e o `[^}]*` parava na chave de dentro e não devolvia nada.
const COM_FORMAT = ['jobs:', '  x:', '    steps:',
  `      - run: echo "\${{ format('{0}', github.head_ref) }}"`,
  '      - run: |', `          echo "\${{ format('{0}-{1}', github.run_number, github.event.pull_request.title) }}"`];
const FORMATS = ["format('{0}', github.head_ref)", "format('{0}-{1}', github.run_number, github.event.pull_request.title)"];
assert.deepStrictEqual(expressoesEmRun(COM_FORMAT.join('\n')), FORMATS, 'format(...) com chave dentro sumiu do leitor');
for(const expr of FORMATS)
  assert.doesNotMatch(expr, PERMITIDAS_EM_RUN, `${expr} leva texto de fora para o shell e precisa reprovar`);
// Arquivo com fim de linha do Windows (CRLF), com \r\n até na última linha como o editor grava:
// o `.` não casa o \r e, sem separar por \r?\n, nenhuma linha de run: era reconhecida e o leitor saía vazio.
const emCrlf = linhas => linhas.join('\r\n') + '\r\n';
assert.deepStrictEqual(expressoesEmRun(emCrlf(AMOSTRA)), ['github.head_ref', 'secrets.A'], 'CRLF deixou o leitor vazio');
assert.deepStrictEqual(expressoesEmRun(emCrlf(COM_FORMAT)), FORMATS, 'CRLF escondeu o format(...) do leitor');
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

/* App nativo (app-ios/): núcleo contra os vetores do site e app no simulador, num macOS fixo. */
const appIos = readFileSync(join(dir, 'app-ios.yml'), 'utf8');
const appIosSemComentario = appIos.split('\n').filter(l => !/^\s*#/.test(l)).join('\n');
assert.match(appIos, /runs-on:\s*macos-26/, 'o app nativo precisa do runner macOS 26 (Xcode 26)');
assert.match(appIos, /swift test --package-path app-ios\/CusttaNucleo/, 'sem o swift test do núcleo');
assert.match(appIos, /TZ:\s*America\/Sao_Paulo/, 'os testes do núcleo rodam no fuso dos vetores');
assert.match(appIos, /DEVELOPER_DIR:\s*\/Applications\/Xcode_26\.6\.app\/Contents\/Developer/, 'o Xcode da CI é fixo: o padrão do runner muda sem aviso');
for(const caminho of ['app-ios/**', 'calc.js', 'dados.js', 'push.js', 'cadastro.js', 'teclado.js', 'scripts/vetores-calc.mjs', 'scripts/simulador-ios.mjs', 'tests/vetores/**', '.github/workflows/app-ios.yml'])
  assert.ok(appIos.includes(`- '${caminho}'`), `app-ios.yml não dispara quando ${caminho} muda`);
assert.ok(!/^on:\n(?:.*\n)*?\s{2}push:/m.test(appIos), 'o app nativo não roda em todo push');
assert.match(appIos, /workflow_dispatch:/, 'o app nativo precisa do botão manual');
assert.match(appIos, /resolver_de_novo:/, 'sem o botão de resolver os pacotes Swift do app nativo de novo');
assert.match(appIosSemComentario, /- name: Resolver os pacotes Swift de novo\n\s+if: inputs\.resolver_de_novo\n/, 'o passo de resolver de novo só roda no botão (if: inputs.resolver_de_novo)');
assert.equal((appIosSemComentario.match(/CODE_SIGNING_ALLOWED=NO/g) || []).length, 8, 'build, testes, os testes da etapa 3 (app-etapa3 e app-etapa3-b), os três laudos e auditoria sem assinatura');
assert.match(appIosSemComentario, /-project app-ios\/Custta\.xcodeproj[\s\S]*-configuration Release[\s\S]*CODE_SIGNING_ALLOWED=NO/, 'o app compila em Release sem assinatura');
assert.match(appIosSemComentario, /xcodebuild test[\s\S]*-destination "\$DESTINO"/, 'os testes rodam no simulador escolhido pelo script');
assert.equal((appIosSemComentario.match(/-onlyUsePackageVersionsFromResolvedFile/g) || []).length, 8, 'build, testes, os testes da etapa 3 (app-etapa3 e app-etapa3-b), os três laudos e auditoria com os pacotes travados');
// O laudo de leitura e as auditorias moram nos jobs laudo, laudo-parte3, laudo-etapa3 e auditoria, em paralelo: o app pula
// os dois. O laudo roda a leitura; o laudo-parte3 (as leituras da parte 3 da etapa 2), o laudo-etapa3 (as da etapa 3) e o
// auditoria rodam as leituras que o laudo pula, e o auditoria também as auditorias, menos as da parte 3 e as da etapa 3,
// que rodam no laudo-parte3 e no laudo-etapa3, para cada job caber no teto com folga.
// Cada job vai do nome até o próximo job (as linhas de comentário já saíram).
const jobAppIos = nome => (appIosSemComentario.match(new RegExp(`\\n  ${nome}:\\n(?:(?!\\n  \\S)[\\s\\S])*`)) || [''])[0];
const jobApp = jobAppIos('app'), jobLaudo = jobAppIos('laudo'), jobParte3 = jobAppIos('laudo-parte3'), jobAuditoria = jobAppIos('auditoria');
const jobEtapa3 = jobAppIos('laudo-etapa3'), jobAppEtapa3 = jobAppIos('app-etapa3'), jobAppEtapa3b = jobAppIos('app-etapa3-b');
assert.match(jobApp, /-skip-testing:CusttaUITests\/LeituraNoVidroUITests[\s\S]*-skip-testing:CusttaUITests\/AuditoriaUITests/,
  'o job app pula o laudo e as auditorias');
assert.match(jobLaudo, /-only-testing:CusttaUITests\/LeituraNoVidroUITests \\\n/, 'o job laudo roda o laudo de leitura');
assert.ok(!/AuditoriaUITests/.test(jobLaudo), 'as auditorias rodam no auditoria e no laudo-parte3, não no laudo');
assert.match(jobAuditoria, /-only-testing:CusttaUITests\/AuditoriaUITests \\\n/, 'o job auditoria roda as auditorias');
assert.ok(!/-only-testing:CusttaUITests\/LeituraNoVidroUITests \\\n/.test(jobAuditoria + jobParte3 + jobEtapa3), 'o laudo-parte3, o laudo-etapa3 e o auditoria rodam só as leituras que o laudo pula');
assert.match(jobEtapa3, /-only-testing:CusttaUITests\/LeituraNoVidroUITests\/\w+ \\\n/, 'o job laudo-etapa3 roda as leituras da etapa 3');
assert.match(jobParte3, /-only-testing:CusttaUITests\/LeituraNoVidroUITests\/\w+ \\\n/, 'o job laudo-parte3 roda as leituras da parte 3');
// Nenhuma leitura se perde nem roda duas vezes: a que o laudo pula roda no laudo-parte3, no laudo-etapa3 ou no auditoria, e
// só nele.
const leiturasDe = (job, opcao) => [...job.matchAll(new RegExp(`-${opcao}-testing:CusttaUITests/LeituraNoVidroUITests/(\\w+)`, 'g'))].map(m => m[1]).sort();
const puladasNoLaudo = leiturasDe(jobLaudo, 'skip');
assert.deepStrictEqual([...leiturasDe(jobParte3, 'only'), ...leiturasDe(jobEtapa3, 'only'), ...leiturasDe(jobAuditoria, 'only')].sort(), puladasNoLaudo,
  'a leitura que o laudo pula roda num dos outros três, uma vez só, e eles só rodam essas');
const leituraNoVidro = readFileSync(join(__dirname, '..', 'app-ios', 'CusttaUITests', 'LeituraNoVidroUITests.swift'), 'utf8');
for(const metodo of puladasNoLaudo)
  assert.match(leituraNoVidro, new RegExp(`func ${metodo}\\(`), `o app-ios.yml divide ${metodo}, que não existe mais no LeituraNoVidroUITests`);
// As auditorias da parte 3 e as da etapa 3 rodam no laudo-parte3 e no laudo-etapa3: a que o auditoria pula roda num deles,
// uma vez só, e só ela.
const auditoriasDe = (job, opcao) => [...job.matchAll(new RegExp(`-${opcao}-testing:CusttaUITests/AuditoriaUITests/(\\w+)`, 'g'))].map(m => m[1]).sort();
const puladasNoAuditoria = auditoriasDe(jobAuditoria, 'skip');
assert.deepStrictEqual([...auditoriasDe(jobParte3, 'only'), ...auditoriasDe(jobEtapa3, 'only')].sort(), puladasNoAuditoria,
  'a auditoria que o auditoria pula roda no laudo-parte3 ou no laudo-etapa3, uma vez só, e só ela');
assert.ok(!/-only-testing:CusttaUITests\/AuditoriaUITests \\\n/.test(jobParte3 + jobEtapa3), 'o laudo-parte3 e o laudo-etapa3 rodam só as auditorias que o auditoria pula');
const auditoria = readFileSync(join(__dirname, '..', 'app-ios', 'CusttaUITests', 'AuditoriaUITests.swift'), 'utf8');
for(const metodo of puladasNoAuditoria)
  assert.match(auditoria, new RegExp(`func ${metodo}\\(`), `o app-ios.yml divide ${metodo}, que não existe mais no AuditoriaUITests`);
for(const [nome, job] of [['laudo', jobLaudo], ['laudo-parte3', jobParte3], ['laudo-etapa3', jobEtapa3], ['auditoria', jobAuditoria]]){
  assert.match(job, /\n    runs-on: macos-26\n/, `o job ${nome} roda no macOS 26 fixo`);
  assert.match(job, /\n\s+TEST_RUNNER_CUSTTA_VARREDURA: curta\n/, `o job ${nome} usa a varredura curta (a lista sob a cápsula só em 0, 20, 40 e 260 pt)`);
  assert.match(job, new RegExp(`-resultBundlePath "\\$RUNNER_TEMP/${nome}\\.xcresult"[\\s\\S]*if: failure\\(\\)[\\s\\S]*path: \\$\\{\\{ runner\\.temp \\}\\}/${nome}\\.xcresult`),
    `o job ${nome} guarda o próprio resultado quando reprova`);
}
// Os testes de tela da etapa 3 rodam no app-etapa3 e no app-etapa3-b (o app-etapa3 não cresce mais: 55 a 58,8 min), em
// paralelo com o app, que passou do teto de 75 min com eles. Cada suíte de tela que o app pula (inteira) roda noutro job,
// uma vez só: as leituras e as auditorias nos laudos e no auditoria (teste por teste, acima), e as outras, inteiras, no
// app-etapa3 ou no app-etapa3-b, que só rodam o que o app pula. Pega a suíte que sai do app e não entra em nenhum job, e a
// que entra num dos dois sem sair do app (roda duas vezes).
const suitesInteiras = (job, opcao) => [...job.matchAll(new RegExp(`-${opcao}-testing:CusttaUITests/(\\w+)(?![\\w/])`, 'g'))].map(m => m[1]);
const suitesQueRodam = job => [...job.matchAll(/-only-testing:CusttaUITests\/(\w+)/g)].map(m => m[1]);
assert.ok(!/-skip-testing:CusttaUITests\/\w+\//.test(jobApp), 'o app pula suítes de tela inteiras');
for(const [nome, job] of [['app-etapa3', jobAppEtapa3], ['app-etapa3-b', jobAppEtapa3b]]){
  assert.ok(!/-(?:only|skip)-testing:CusttaUITests\/\w+\//.test(job), `o ${nome} roda suítes de tela inteiras`);
  assert.ok(suitesInteiras(job, 'only').length > 0, `o ${nome} roda só as suítes da etapa 3 (sem -only-testing, rodaria todas)`);
  assert.match(job, /\n    runs-on: macos-26\n/, `o job ${nome} roda no macOS 26 fixo`);
}
const puladasNoApp = suitesInteiras(jobApp, 'skip');
const nosLaudos = [...new Set([jobLaudo, jobParte3, jobEtapa3, jobAuditoria].flatMap(suitesQueRodam))];
assert.deepStrictEqual([...nosLaudos, ...suitesInteiras(jobAppEtapa3, 'only'), ...suitesInteiras(jobAppEtapa3b, 'only')].sort(), [...puladasNoApp].sort(),
  'a suíte de tela que o app pula roda nos laudos, no auditoria, no app-etapa3 ou no app-etapa3-b, uma vez só, e os dois rodam só o que o app pula');
const telas = readdirSync(join(__dirname, '..', 'app-ios', 'CusttaUITests')).filter(f => f.endsWith('.swift'))
  .map(f => readFileSync(join(__dirname, '..', 'app-ios', 'CusttaUITests', f), 'utf8')).join('\n');
for(const suite of puladasNoApp)
  assert.match(telas, new RegExp(`\\bclass ${suite}\\b`), `o app-ios.yml divide ${suite}, que não existe no CusttaUITests`);
// O resultado sobe também quando o job é cancelado: o run 39710458060 foi cortado no teto e ficou sem xcresult.
for(const [nome, job, resultado] of [['app', jobApp, 'testes'], ['app-etapa3', jobAppEtapa3, 'testes-etapa3'], ['app-etapa3-b', jobAppEtapa3b, 'testes-etapa3-b']])
  assert.match(job, new RegExp(`-resultBundlePath "\\$RUNNER_TEMP/${resultado}\\.xcresult"[\\s\\S]*\\n\\s+if: failure\\(\\) \\|\\| cancelled\\(\\)\\n[\\s\\S]*path: \\$\\{\\{ runner\\.temp \\}\\}/${resultado}\\.xcresult`),
    `o job ${nome} guarda o próprio resultado quando reprova e quando é cortado no teto`);
assert.ok(!/\n    (?:needs|if):/.test(jobApp + jobAppEtapa3 + jobAppEtapa3b + jobLaudo + jobParte3 + jobEtapa3 + jobAuditoria), 'o app, o app-etapa3, o app-etapa3-b, os laudos e o auditoria rodam em todo PR e em paralelo: nenhum tem if nem espera outro job');
assert.ok(!/continue-on-error/.test(jobApp + jobAppEtapa3 + jobAppEtapa3b + jobLaudo + jobParte3 + jobEtapa3 + jobAuditoria), 'o app, o app-etapa3, o app-etapa3-b, os laudos e o auditoria são portão: nenhum passa com falha (continue-on-error)');
for(const job of ['nucleo', 'app', 'app-etapa3', 'app-etapa3-b', 'laudo', 'laudo-parte3', 'laudo-etapa3', 'auditoria'])
  assert.match(jobAppIos(job), /\n    timeout-minutes: \d+\n/, `o job ${job} do app nativo precisa de timeout-minutes (sem ele, um job travado só cai em 6 h)`);
// O resultado de cada job sobe com um nome só dele: no mesmo run o upload-artifact não aceita o mesmo nome duas vezes, e dois
// jobs reprovados juntos perderiam um dos resultados.
const artefatos = [...appIosSemComentario.matchAll(/uses: actions\/upload-artifact@[^\n]*\n\s+with:\n\s+name: (\S+)\n/g)].map(m => m[1]);
assert.ok(artefatos.length >= 7, `os resultados que sobem: ${artefatos.length}`);
assert.equal(new Set(artefatos).size, artefatos.length, `cada job sobe o resultado com um nome só dele: ${artefatos}`);
const appIosTf = readFileSync(join(dir, 'app-ios-testflight.yml'), 'utf8');
const appIosTfSemComentario = appIosTf.split('\n').filter(l => !/^\s*#/.test(l)).join('\n');
assert.match(appIosTf, /runs-on:\s*macos-26/);
assert.match(appIosTf, /^on:\n\s+workflow_dispatch:\s*\n(?!\s{2}\S)/m, 'o envio do app nativo é só no botão');
assert.match(appIosTf, /cancel-in-progress:\s*false/, 'cancelar no meio pode matar um upload');
assert.match(appIosTfSemComentario, /-project app-ios\/Custta\.xcodeproj/);
assert.match(appIosTfSemComentario, /-onlyUsePackageVersionsFromResolvedFile/);
assert.match(appIosTf, /CURRENT_PROJECT_VERSION="\$\{\{ github\.run_number \}\}\.\$\{\{ github\.run_attempt \}\}"/);
assert.match(appIosTf, /-exportOptionsPlist app-ios\/ExportOptions\.plist/);
assert.match(appIosTf, /if:\s*always\(\)[\s\S]*delete-keychain/, 'keychain temporária precisa sumir mesmo com falha');
for(const s of ['ASC_KEY_ID', 'ASC_ISSUER_ID', 'ASC_KEY_P8', 'APPLE_TEAM_ID', 'DIST_CERT_P12', 'DIST_CERT_SENHA', 'PERFIL_APP_STORE'])
  assert.match(appIosTf, new RegExp(`secrets\\.${s}\\b`), `envio do app nativo não lê o secret ${s}`);
assert.ok(!/-----BEGIN/.test(appIosTf), 'chave literal no workflow — repositório é público');
assert.equal(readFileSync(join(__dirname, '..', 'app-ios', 'ExportOptions.plist'), 'utf8'),
  readFileSync(join(__dirname, '..', 'ios', 'App', 'ExportOptions.plist'), 'utf8'), 'o envio do app nativo usa as mesmas opções do de hoje');
assert.match(appIosTf, /DEVELOPER_DIR:\s*\/Applications\/Xcode_26\.6\.app\/Contents\/Developer/, 'o envio usa o mesmo Xcode fixo da CI');
assert.match(appIosTf, /AppleWWDRCAG3\.cer/, 'sem o intermediário WWDR G3 a identidade não é válida para assinar');
assert.match(appIosTf, /TeamIdentifier/, 'perfil precisa ter o TeamIdentifier conferido');
assert.match(appIosTf, /!=\s*"Custta App Store"/, 'perfil precisa ter o Name conferido contra "Custta App Store"');
assert.match(appIosTf, /TEAM"\s*!=\s*"\$APPLE_TEAM_ID"/, 'perfil precisa comparar o time do perfil com APPLE_TEAM_ID');
assert.match(appIosTf, /ExpirationDate[\s\S]*-lt 30/, 'sem o aviso de perfil vencendo em menos de 30 dias');

console.log('ok - Actions com SHA imutável e permissão mínima; build iOS sem assinatura e sob demanda; envio ao TestFlight assinado e sob demanda');

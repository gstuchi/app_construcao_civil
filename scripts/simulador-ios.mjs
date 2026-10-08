/* Simulador para os testes do app nativo (app-ios/). Os nomes dos iPhones mudam de um Xcode
   para outro, então o destino não fica fixo no workflow nem nos scripts.

   node scripts/simulador-ios.mjs                         imprime o destino do xcodebuild
   node scripts/simulador-ios.mjs --testar <alvo>... [--emuladores]
       roda `xcodebuild test -only-testing:<alvo>` (ex.: CusttaTests). Com --emuladores, passa
       CUSTTA_EMULADORES=1 aos testes (os que dependem dos emuladores do Firebase deixam de
       pular). Assina para o simulador, como o Xcode faz: sem assinatura o app não tem
       entitlements e o Firebase Auth falha no keychain (erro -34018). */
import { execFileSync, spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

/** "platform=iOS Simulator,id=…" do primeiro iPhone do iOS mais novo instalado. */
export function destinoDoSimulador(){
  const lista = JSON.parse(execFileSync('xcrun', ['simctl', 'list', 'devices', 'available', '-j'], { encoding: 'utf8' })).devices;
  const versao = runtime => (/iOS-(\d+)-(\d+)/.exec(runtime) || []).slice(1).map(Number);
  const runtimes = Object.keys(lista).filter(r => /SimRuntime\.iOS-/.test(r))
    .sort((a, b) => { const [x1, y1] = versao(a), [x2, y2] = versao(b); return x2 - x1 || y2 - y1; });
  for(const runtime of runtimes){
    const iphone = lista[runtime].find(d => d.isAvailable !== false && d.name.startsWith('iPhone'));
    if(iphone) return `platform=iOS Simulator,id=${iphone.udid}`;
  }
  throw new Error('nenhum iPhone no simulador: instale um runtime de iOS no Xcode (Settings > Components)');
}

/** xcodebuild test só dos alvos pedidos. `env` chega ao processo do teste (prefixo TEST_RUNNER_).
    Assíncrono de propósito: quem chama pode atender pedidos do teste enquanto ele roda. */
export function testarNoSimulador(alvos, env = {}){
  const ambiente = { ...process.env };
  for(const [k, v] of Object.entries(env)) ambiente[`TEST_RUNNER_${k}`] = v;
  const args = ['test', '-project', 'app-ios/Custta.xcodeproj', '-scheme', 'Custta', '-destination', destinoDoSimulador(),
    '-skipMacroValidation', '-skipPackagePluginValidation', '-onlyUsePackageVersionsFromResolvedFile',
    ...alvos.map(a => `-only-testing:${a}`)];
  return new Promise((resolve, reject) => spawn('xcodebuild', args, { cwd: RAIZ, stdio: 'inherit', env: ambiente })
    .on('error', reject)
    .on('exit', c => c === 0 ? resolve() : reject(new Error(`xcodebuild test falhou (${alvos.join(', ')})`))));
}

if(process.argv[1] === fileURLToPath(import.meta.url)){
  const args = process.argv.slice(2);
  try{
    if(args[0] === '--testar'){
      await testarNoSimulador(args.slice(1).filter(a => !a.startsWith('--')), args.includes('--emuladores') ? { CUSTTA_EMULADORES: '1' } : {});
    }else{
      console.log(destinoDoSimulador());
    }
  }catch(erro){
    console.error(erro.message);
    process.exit(1);
  }
}

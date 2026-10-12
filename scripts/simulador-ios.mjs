/* Simulador para os testes do app nativo (app-ios/). Os nomes dos iPhones mudam de um Xcode
   para outro, então o destino não fica fixo no workflow nem nos scripts.

   node scripts/simulador-ios.mjs                         imprime o destino do xcodebuild
   node scripts/simulador-ios.mjs --testar <alvo>... [--emuladores]
       roda `xcodebuild test -only-testing:<alvo>` (ex.: CusttaTests). Com --emuladores, passa
       CUSTTA_EMULADORES=1 aos testes (os que dependem dos emuladores do Firebase deixam de
       pular). Assina para o simulador, como o Xcode faz: sem assinatura o app não tem
       entitlements e o Firebase Auth falha no keychain (erro -34018).

   CUSTTA_SIMULADOR=<udid> escolhe o simulador (um por pessoa ou agente, para duas rodadas não
   disputarem o mesmo); sem ela, o primeiro iPhone do iOS mais novo instalado. */
import { execFileSync, spawn } from 'node:child_process';
import { realpathSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

/** "platform=iOS Simulator,id=…" do simulador dos testes (CUSTTA_SIMULADOR ou o de sempre). */
export function destinoDoSimulador(){
  const lista = JSON.parse(execFileSync('xcrun', ['simctl', 'list', 'devices', 'available', '-j'], { encoding: 'utf8' })).devices;
  return `platform=iOS Simulator,id=${escolherSimulador(lista, process.env.CUSTTA_SIMULADOR)}`;
}

/** Udid do simulador, na lista do `simctl list devices -j`: o `udid` pedido, se existir; sem ele, o
    primeiro iPhone do iOS mais novo. Um id que não existe para, em vez de cair no simulador de outro. */
export function escolherSimulador(lista, udid){
  if(udid){
    if(Object.values(lista).flat().some(d => d.udid === udid && d.isAvailable !== false)) return udid;
    throw new Error(`CUSTTA_SIMULADOR=${udid}: nenhum simulador disponível com esse id (xcrun simctl list devices)`);
  }
  const versao = runtime => (/iOS-(\d+)-(\d+)/.exec(runtime) || []).slice(1).map(Number);
  const runtimes = Object.keys(lista).filter(r => /SimRuntime\.iOS-/.test(r))
    .sort((a, b) => { const [x1, y1] = versao(a), [x2, y2] = versao(b); return x2 - x1 || y2 - y1; });
  for(const runtime of runtimes){
    const iphone = lista[runtime].find(d => d.isAvailable !== false && d.name.startsWith('iPhone'));
    if(iphone) return iphone.udid;
  }
  throw new Error('nenhum iPhone no simulador: instale um runtime de iOS no Xcode (Settings > Components)');
}

/** Argumentos do `xcodebuild test` só dos alvos pedidos. Sem os diagnósticos de teste que falha: o
    `simctl diagnose` que eles disparam segura a rodada até 10 min. */
export function argumentosDoTeste(alvos, destino){
  return ['test', '-project', 'app-ios/Custta.xcodeproj', '-scheme', 'Custta', '-destination', destino,
    '-skipMacroValidation', '-skipPackagePluginValidation', '-onlyUsePackageVersionsFromResolvedFile',
    '-collect-test-diagnostics', 'never', ...alvos.map(a => `-only-testing:${a}`)];
}

/** xcodebuild test só dos alvos pedidos. `env` chega ao processo do teste (prefixo TEST_RUNNER_).
    Assíncrono de propósito: quem chama pode atender pedidos do teste enquanto ele roda. */
export function testarNoSimulador(alvos, env = {}){
  const ambiente = { ...process.env };
  for(const [k, v] of Object.entries(env)) ambiente[`TEST_RUNNER_${k}`] = v;
  const args = argumentosDoTeste(alvos, destinoDoSimulador());
  return new Promise((resolve, reject) => spawn('xcodebuild', args, { cwd: RAIZ, stdio: 'inherit', env: ambiente })
    .on('error', reject)
    .on('exit', c => c === 0 ? resolve() : reject(new Error(`xcodebuild test falhou (${alvos.join(', ')})`))));
}

if(process.argv[1] && realpathSync(process.argv[1]) === fileURLToPath(import.meta.url)){
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

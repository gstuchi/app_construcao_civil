/* Servidor e suítes com encerramento garantido; usa somente emuladores locais. */
const {spawn}=require('node:child_process');
const path=require('node:path');
const os=require('node:os');
const server=spawn(process.execPath,['tests/browser/servidor.cjs'],{stdio:'inherit',env:{...process.env,CUSTTA_EMULADORES:'1'}});
const run=(file,args=[])=>new Promise((resolve,reject)=>{
  const child=spawn(process.execPath,[file,...args],{stdio:'inherit',env:{...process.env,TEMP:os.tmpdir()}});
  child.on('error',reject);child.on('exit',code=>code===0?resolve():reject(new Error(`${file}: ${code}`)));
});
(async()=>{
  try{
    for(let n=0;n<50;n++){
      try{if((await fetch('http://localhost:8123')).ok) break;}catch{}
      if(n===49) throw Error('Servidor não iniciou');
      await new Promise(r=>setTimeout(r,100));
    }
    await run('tests/browser/sync.cjs',[path.join(os.tmpdir(),'custta-sync.png')]);
    await run('tests/browser/fase3.cjs');
    await run('tests/browser/mobile.cjs');
    await run('tests/browser/ios.cjs');
    await run('tests/browser/cartao.cjs');
    await run('tests/browser/nativo.cjs');
    await run('tests/browser/sentry.cjs');
    await run('tests/browser/persistencia.cjs');
    await run('tests/browser/fase2.cjs');
    await run('tests/browser/cadastro.cjs');
    await run('tests/browser/google.cjs');
  }finally{server.kill();}
})().catch(e=>{console.error(e);process.exitCode=1;});

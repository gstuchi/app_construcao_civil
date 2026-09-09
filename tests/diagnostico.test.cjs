const { test } = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');
const script = name=>fs.readFileSync(path.join(__dirname,'..',name),'utf8');

test('falha no registro do PWA registra diagnóstico e aviso offline', async()=>{
  const erros=[], avisos=[];
  let load;
  const erro = new Error('registro indisponível');
  const context={
    navigator:{ serviceWorker:{ controller:null, addEventListener(){}, register:()=>Promise.reject(erro) } },
    window:{ addEventListener:(_e,cb)=>{ load=cb; }, OBRA_DIAG:{ registra:(...args)=>erros.push(args) } },
    toast:(...args)=>avisos.push(args), console
  };
  vm.runInNewContext(script('pwa.js'), context);
  await load();
  assert.equal(erros[0][0], 'pwa');
  assert.equal(erros[0][1], erro.message);
  assert.match(avisos[0][0], /uso offline/);
});

test('tema bloqueado preserva erro até diagnóstico carregar', ()=>{
  const context={ window:{}, console:{ error(){} }, localStorage:{ getItem(){ throw new Error('storage bloqueado'); } } };
  vm.runInNewContext(script('tema.js'), context);
  assert.equal(context.window.OBRA_ERROS_INICIAIS[0].origem, 'tema');
  assert.equal(context.window.OBRA_ERROS_INICIAIS[0].msg, 'storage bloqueado');
});

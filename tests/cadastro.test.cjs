const {test}=require('node:test');
const assert=require('node:assert/strict');
const C=require('../cadastro.js');

test('senha válida passa em todas as regras',()=>{
  const r=C.validaSenha('Obra2026x','ana@exemplo.com');
  assert.equal(r.ok,true); assert.equal(r.erro,'');
  assert.ok(r.regras.every(x=>x.ok));
  assert.deepEqual(r.regras.map(x=>x.id),['tamanho','letra','numero','email','comum']);
});
test('cada regra falha sozinha com mensagem própria',()=>{
  assert.equal(C.validaSenha('Ab1','').erro,'Use pelo menos 8 caracteres.');
  assert.equal(C.validaSenha('12345678901','').erro,'Inclua pelo menos uma letra.');
  assert.equal(C.validaSenha('abcdefghij','').erro,'Inclua pelo menos um número.');
  assert.equal(C.validaSenha('ana@exemplo.com1','ana@exemplo.com1').erro,'A senha não pode ser igual ao e-mail.');
  assert.equal(C.validaSenha('senha123','').erro,'Essa senha é muito comum. Escolha outra.');
  assert.equal(C.validaSenha('x'.repeat(120)+'1'.repeat(9),'').erro,'Use no máximo 128 caracteres.');
});
test('igualdade com e-mail e lista comum ignoram maiúsculas e espaços',()=>{
  assert.equal(C.validaSenha(' ANA@exemplo.com1 ','ana@exemplo.com1').ok,false);
  assert.equal(C.validaSenha('SENHA123','').ok,false);
  assert.equal(C.validaSenha('12345678a','').ok,false);
});
test('letra acentuada conta como letra',()=>{
  assert.equal(C.validaSenha('ÇÃOÉÊÍ12','').ok,true);
});
test('valores não-string não quebram',()=>{
  assert.equal(C.validaSenha(undefined,null).ok,false);
  assert.equal(C.validaSenha(12345678,undefined).ok,false);
});
test('origens na ordem combinada; só indicação e outro têm detalhe',()=>{
  assert.deepEqual(C.ORIGENS.map(o=>o.id),['instagram','indicacao','google','tiktok','youtube','outro']);
  assert.deepEqual(C.ORIGENS.filter(o=>o.detalhe).map(o=>o.id),['indicacao','outro']);
});
test('perfil normaliza espaços e omite vazios',()=>{
  const r=C.normalizaPerfil({nome:'  Ana   Maria ',sobrenome:'   ',origem:'instagram',origemDetalhe:'x'});
  assert.equal(r.ok,true);
  assert.deepEqual(r.perfil,{nome:'Ana Maria',origem:'instagram'});
});
test('detalhe só vai junto de origem que aceita',()=>{
  assert.deepEqual(C.normalizaPerfil({nome:'Ana',origem:'indicacao',origemDetalhe:'  Seu  João '}).perfil,
    {nome:'Ana',origem:'indicacao',origemDetalhe:'Seu João'});
  assert.deepEqual(C.normalizaPerfil({nome:'Ana',sobrenome:'Lima',origem:'google',origemDetalhe:'Seu João'}).perfil,
    {nome:'Ana',sobrenome:'Lima',origem:'google'});
});
test('erros de perfil apontam o campo',()=>{
  assert.deepEqual(pick(C.normalizaPerfil({nome:' ',origem:'instagram'})),{ok:false,campo:'nome',erro:'Digite seu nome.'});
  assert.deepEqual(pick(C.normalizaPerfil({nome:'A',origem:'instagram'})),{ok:false,campo:'nome',erro:'O nome precisa de pelo menos 2 letras.'});
  assert.deepEqual(pick(C.normalizaPerfil({nome:'A'.repeat(61),origem:'instagram'})),{ok:false,campo:'nome',erro:'Use no máximo 60 caracteres no nome.'});
  assert.deepEqual(pick(C.normalizaPerfil({nome:'Ana',sobrenome:'L'.repeat(81),origem:'instagram'})),{ok:false,campo:'sobrenome',erro:'Use no máximo 80 caracteres no sobrenome.'});
  assert.deepEqual(pick(C.normalizaPerfil({nome:'Ana',origem:''})),{ok:false,campo:'origem',erro:'Conte como conheceu o Custta.'});
  assert.deepEqual(pick(C.normalizaPerfil({nome:'Ana',origem:'orkut'})),{ok:false,campo:'origem',erro:'Conte como conheceu o Custta.'});
  assert.deepEqual(pick(C.normalizaPerfil({nome:'Ana',origem:'outro',origemDetalhe:'x'.repeat(81)})),{ok:false,campo:'origemDetalhe',erro:'Use no máximo 80 caracteres.'});
  function pick(r){ return {ok:r.ok,campo:r.campo,erro:r.erro}; }
});
test('normalizaNome valida só nome e sobrenome',()=>{
  assert.deepEqual(C.normalizaNome({nome:' Ana ',sobrenome:' Lima '}).perfil,{nome:'Ana',sobrenome:'Lima'});
  assert.deepEqual(C.normalizaNome({nome:'Ana',sobrenome:''}).perfil,{nome:'Ana'});
  assert.equal(C.normalizaNome({nome:''}).campo,'nome');
});
test('nomeDoGoogle separa primeira palavra e resto, com espaços limpos',()=>{
  assert.deepEqual(C.nomeDoGoogle('  Ana   Maria  Souza '),{nome:'Ana',sobrenome:'Maria Souza'});
  assert.deepEqual(C.nomeDoGoogle('Ana'),{nome:'Ana',sobrenome:''});
  assert.deepEqual(C.nomeDoGoogle(undefined),{nome:'',sobrenome:''});
  assert.deepEqual(C.nomeDoGoogle(42),{nome:'',sobrenome:''});
});
test('nomeDoGoogle corta nos limites do perfil',()=>{
  const r=C.nomeDoGoogle('A'.repeat(70)+' '+'B'.repeat(90));
  assert.equal(r.nome.length,60); assert.equal(r.sobrenome.length,80);
});
test('mensagemErroGoogle: desistência é silenciosa, o resto em português',()=>{
  for(const c of ['auth/popup-closed-by-user','auth/cancelled-popup-request','auth/user-cancelled'])
    assert.equal(C.mensagemErroGoogle(c),'');
  assert.equal(C.mensagemErroGoogle('auth/account-exists-with-different-credential'),'Este e-mail já tem conta com senha. Entre com e-mail e senha.');
  assert.equal(C.mensagemErroGoogle('auth/unauthorized-domain'),'Login com Google indisponível neste endereço. Use custta.com.br.');
  assert.equal(C.mensagemErroGoogle('auth/operation-not-supported-in-this-environment'),'Seu navegador bloqueou o login com Google. Use e-mail e senha.');
  assert.equal(C.mensagemErroGoogle('auth/web-storage-unsupported'),'Seu navegador bloqueou o login com Google. Use e-mail e senha.');
  assert.equal(C.mensagemErroGoogle('auth/network-request-failed'),'Sem internet. Conecte pra entrar.');
  assert.equal(C.mensagemErroGoogle('auth/too-many-requests'),'Muitas tentativas. Espere um pouco.');
  assert.equal(C.mensagemErroGoogle('auth/qualquer-outro'),'Não deu certo entrar com o Google. Tente de novo.');
  assert.equal(C.mensagemErroGoogle(undefined),'Não deu certo entrar com o Google. Tente de novo.');
  assert.equal(C.mensagemErroGoogle('toString'),'Não deu certo entrar com o Google. Tente de novo.');
});

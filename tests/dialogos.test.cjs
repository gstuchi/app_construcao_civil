'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');

test('app.js e auth.js não usam confirm/alert nativos (somem no WKWebView)', ()=>{
  for(const nome of ['app.js', 'auth.js']){
    const fonte = readFileSync(join(__dirname, '..', nome), 'utf8').replace(/\/\*[\s\S]*?\*\/|\/\/.*$/gm, '');
    assert.doesNotMatch(fonte, /(^|[^.\w])(confirm|alert)\s*\(/m, nome);
  }
});

test('conta só Google: sem trocar senha e apagar sem campo de senha', ()=>{
  const app = readFileSync(join(__dirname, '..', 'app.js'), 'utf8');
  assert.match(app, /\$\('#ajSenha'\)\.classList\.toggle\('hidden', conta\?\.temSenha === false\)/);
  const ui = readFileSync(join(__dirname, '..', 'ui-confirm.js'), 'utf8');
  assert.match(ui, /temSenha === false/);
  assert.match(ui, /auth\/popup-blocked/);
  assert.match(ui, /auth\/user-mismatch/);
});

test('login com Apple: botão acima do Google, bloco social e "Falta pouco" sem nome', ()=>{
  const html = readFileSync(join(__dirname, '..', 'index.html'), 'utf8');
  const social = html.match(/<div id="authSocial" class="auth-social">([\s\S]*?)<\/div>\s*<form id="fLogin"/);
  assert.ok(social, 'bloco #authSocial antes do formulário de login');
  assert.ok(social[1].indexOf('id="btnApple"') < social[1].indexOf('id="btnGoogle"'), 'Apple antes do Google (HIG)');
  assert.match(social[1], /<svg[^>]*aria-hidden="true"[\s\S]*?fill="currentColor"/);
  assert.match(social[1], /<span id="btnAppleTexto">Continuar com a Apple<\/span>/);
  assert.doesNotMatch(html, /id="authGoogle"/);
  assert.match(html, /<div id="pNomes">[\s\S]*?id="pNome"[\s\S]*?id="pSobrenome"[^>]*><\/div><\/div>/);
  assert.equal((html.match(/<div\b/g) || []).length, (html.match(/<\/div>/g) || []).length, '<div> e </div> balanceados no index.html');
  assert.match(html, /<p class="auth-perfil-texto" id="pTexto">/);
  const auth = readFileSync(join(__dirname, '..', 'auth.js'), 'utf8');
  assert.match(auth, /CLOUD\.entrarApple\(\)/);
  assert.match(auth, /cloud-social-erro/);
  assert.match(auth, /nomeOpcional/);
  const ui = readFileSync(join(__dirname, '..', 'ui-confirm.js'), 'utf8');
  assert.match(ui, /provedores\?\.includes\('apple\.com'\)/);
});

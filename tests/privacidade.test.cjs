'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const ler = p => readFileSync(join(__dirname, '..', p), 'utf8');

test('política cita token de dispositivo do FCM e lista de SDKs bate com package.json', ()=>{
  const politica = ler('privacidade.html');
  assert.match(politica, /Firebase Cloud Messaging/);
  assert.match(politica, /token/i);
  const sdks = ler('docs/sdks-fase4.md');
  const pkg = JSON.parse(ler('package.json'));
  for(const nome of Object.keys(pkg.devDependencies).filter(n => n.startsWith('@capacitor')))
    assert.ok(sdks.includes(nome), 'SDK sem registro: ' + nome);
  assert.match(sdks, /@sentry\/browser/);
  assert.match(sdks, /firebase 12\.18\.0/);
});

test('política publicada identifica o controlador e não é mais rascunho', ()=>{
  const politica = ler('privacidade.html');
  assert.doesNotMatch(politica, /Rascunho|será confirmado/);
  assert.match(politica, /<strong>Versão vigente:<\/strong> 22 de setembro de 2026\./);
  assert.match(politica, /Controlador dos dados pessoais: <strong>Giovani Stuchi<\/strong>/);
  assert.match(politica, /Resolução CD\/ANPD nº 2\/2022/);
});

test('política lista nome e como a pessoa conheceu o Custta, com finalidade', ()=>{
  const politica = ler('privacidade.html');
  assert.match(politica, /nome e, se informado, sobrenome/);
  assert.match(politica, /como conheceu o Custta/);
  assert.match(politica, /entender por quais canais o Custta é conhecido/);
});

test('Ajustes aponta para a política sem chamá-la de rascunho', ()=>{
  const index = ler('index.html');
  assert.match(index, /<a href="privacidade\.html"[^>]*>Política de privacidade<\/a>/);
});

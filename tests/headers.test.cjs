'use strict';
const assert = require('assert');
const { readFileSync } = require('fs');
const { join } = require('path');

const raiz = join(__dirname, '..');
const index = readFileSync(join(raiz, 'index.html'), 'utf8');
const vercel = JSON.parse(readFileSync(join(raiz, 'vercel.json'), 'utf8'));
const headers = Object.fromEntries(vercel.headers[0].headers.map(h => [h.key.toLowerCase(), h.value]));

assert.ok(headers['content-security-policy'], 'CSP ausente');
assert.ok(!headers['content-security-policy'].includes('unsafe-inline'));
assert.ok(!headers['content-security-policy'].includes('gstatic'));
for(const nome of ['index.html','privacidade.html','app.js']){
  const texto=readFileSync(join(raiz,nome),'utf8');
  assert.ok(!/<style\b|\sstyle=/.test(texto), `${nome}: CSS inline`);
}
assert.ok(!headers['content-security-policy'].includes("script-src 'self' 'unsafe-inline'"), 'CSP permite script inline');
assert.ok(headers['content-security-policy'].includes("object-src 'none'"));
assert.ok(headers['content-security-policy'].includes("frame-ancestors 'none'"));
assert.strictEqual(headers['x-content-type-options'], 'nosniff');
assert.strictEqual(headers['referrer-policy'], 'no-referrer');

const scriptsInline = [...index.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/gi)]
  .filter(m => m[1].trim());
assert.strictEqual(scriptsInline.length, 0, 'index.html ainda contém JavaScript inline');

const versaoHeaders = vercel.headers.find(h => h.source === '/versao.json');
assert.ok(versaoHeaders, 'versao.json precisa de CORS para o app nativo');
assert.deepStrictEqual(versaoHeaders.headers.find(h => h.key === 'Access-Control-Allow-Origin'), { key:'Access-Control-Allow-Origin', value:'capacitor://localhost' });

const csp = headers['content-security-policy'];
assert.ok(/script-src 'self' https:\/\/apis\.google\.com(;|$)/.test(csp), 'script-src do login com Google');
assert.ok(csp.includes("frame-src 'self' https://app-construcao-civil.firebaseapp.com"), 'frame-src do login com Google');
const fonteApp = new RegExp('^' + vercel.headers[0].source + '$');
assert.ok(fonteApp.test('/') && fonteApp.test('/index.html') && fonteApp.test('/privacidade.html'), 'CSP precisa cobrir o app');
assert.ok(!fonteApp.test('/__/auth/handler') && !fonteApp.test('/__/firebase/init.json'), 'CSP do Custta não pode cobrir o handler do Firebase');
const destinos = Object.fromEntries((vercel.rewrites || []).map(r => [r.source, r.destination]));
assert.strictEqual(destinos['/__/auth/:path*'], 'https://app-construcao-civil.firebaseapp.com/__/auth/:path*');
assert.strictEqual(destinos['/__/firebase/:path*'], 'https://app-construcao-civil.firebaseapp.com/__/firebase/:path*');

console.log('ok - headers e CSP bloqueiam scripts inline e embedding');

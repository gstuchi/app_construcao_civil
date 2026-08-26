'use strict';
const assert = require('assert');
const { readFileSync } = require('fs');
const { join } = require('path');

const raiz = join(__dirname, '..');
const index = readFileSync(join(raiz, 'index.html'), 'utf8');
const vercel = JSON.parse(readFileSync(join(raiz, 'vercel.json'), 'utf8'));
const headers = Object.fromEntries(vercel.headers[0].headers.map(h => [h.key.toLowerCase(), h.value]));

assert.ok(headers['content-security-policy'], 'CSP ausente');
assert.ok(!headers['content-security-policy'].includes("script-src 'self' 'unsafe-inline'"), 'CSP permite script inline');
assert.ok(headers['content-security-policy'].includes("object-src 'none'"));
assert.ok(headers['content-security-policy'].includes("frame-ancestors 'none'"));
assert.strictEqual(headers['x-content-type-options'], 'nosniff');
assert.strictEqual(headers['referrer-policy'], 'no-referrer');

const scriptsInline = [...index.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/gi)]
  .filter(m => m[1].trim());
assert.strictEqual(scriptsInline.length, 0, 'index.html ainda contém JavaScript inline');

console.log('ok - headers e CSP bloqueiam scripts inline e embedding');

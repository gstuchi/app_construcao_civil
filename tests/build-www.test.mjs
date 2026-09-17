import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, access } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { construir, cspNativa, PRODUCAO } from '../scripts/build-www.mjs';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');

test('copia arquivos servidos e injeta CSP nativa', async()=>{
  const destino = await mkdtemp(join(tmpdir(), 'custta-www-'));
  const lista = await construir({ raiz, destino });
  for(const a of ['index.html','app.js','nativo.js','vendor/firebase/firebase-app.js','fontes/hanken-grotesk-800.woff2'])
    assert.ok(lista.includes(a), 'faltou ' + a);
  assert.ok(!lista.some(a => a.startsWith('tests/') || a.startsWith('docs/')));
  const html = await readFile(join(destino, 'index.html'), 'utf8');
  const meta = html.match(/<meta http-equiv="Content-Security-Policy" content="([^"]+)">/);
  assert.ok(meta, 'meta CSP ausente');
  assert.ok(!meta[1].includes('unsafe-inline'));
  assert.ok(!meta[1].includes('frame-ancestors'));
  assert.ok(!meta[1].includes('upgrade-insecure-requests'));
  assert.match(meta[1], new RegExp("connect-src 'self' [^;]*" + PRODUCAO.replace(/\./g, '\\.')));
  await access(join(destino, 'app.js'));
  const versao = JSON.parse(await readFile(join(raiz, 'versao.json'), 'utf8')).versao;
  assert.equal(await readFile(join(destino, 'versao-app.js'), 'utf8'), `window.APP_VERSAO=${JSON.stringify(versao)};\n`);
  assert.ok(html.indexOf('<script src="versao-app.js"></script>') < html.indexOf('<script src="nativo.js"></script>'));
});

test('cspNativa remove diretivas que meta não aceita', ()=>{
  assert.equal(cspNativa("default-src 'none'; frame-ancestors 'none'; connect-src 'self'; upgrade-insecure-requests"),
    `default-src 'none'; connect-src 'self' ${PRODUCAO}`);
});

test('arquivo listado ausente falha', async()=>{
  const falsa = await mkdtemp(join(tmpdir(), 'custta-raiz-'));
  await writeFile(join(falsa, 'sw.js'), "const ASSETS = ['./', './index.html', './falta.js'];");
  await writeFile(join(falsa, 'styles.css'), '');
  await writeFile(join(falsa, 'index.html'), '<meta charset="utf-8">');
  await writeFile(join(falsa, 'vercel.json'), JSON.stringify({ headers:[{ source:'/(.*)', headers:[{ key:'Content-Security-Policy', value:"default-src 'none'" }] }] }));
  await writeFile(join(falsa, 'versao.json'), '{"versao":"1.0.0"}');
  await assert.rejects(construir({ raiz:falsa, destino:join(falsa, 'www') }), /falta\.js/);
});

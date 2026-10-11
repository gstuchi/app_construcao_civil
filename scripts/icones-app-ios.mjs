/* Ícones do app nativo: os mesmos traços do icons.js do site (decisão do mockup aprovado: "os
   ícones do PWA viram símbolos próprios no asset catalog"). O script grava um image set vetorial
   por ícone em app-ios/Custta/Assets.xcassets/Icones, como molde (template): a cor vem da tela,
   por token. Ícone novo no app entra na lista USADOS. tests/app-ios.test.cjs roda --conferir.

   Uso: node scripts/icones-app-ios.mjs            grava o catálogo
        node scripts/icones-app-ios.mjs --conferir  só confere (sai com 1 se algo difere) */
import { mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { ICONES } = require('../icons.js');
const PASTA = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../app-ios/Custta/Assets.xcassets/Icones');

/** Ícones que as telas usam: abas, fases da obra, sair, olho da senha e a seta da dica. */
export const USADOS = ['predio', 'engrenagem', 'sair', 'guindaste', 'casa', 'check', 'olho', 'olhoFechado', 'setaBaixo'];

const info = { author: 'xcode', version: 1 };

/** O SVG do ícone, com o traço do ICON() do site (24 × 24, linha 2, pontas redondas). */
export function svg(nome){
  if(!ICONES[nome]) throw new Error(`ícone ${nome} não existe no icons.js`);
  return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#000" '
    + `stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${ICONES[nome]}</svg>\n`;
}

/** Arquivos do catálogo: caminho relativo à pasta Icones → texto. */
export function arquivos(){
  const json = o => JSON.stringify(o, null, 2) + '\n';
  const r = { 'Contents.json': json({ info, properties: { 'provides-namespace': true } }) };
  for(const nome of USADOS){
    r[`${nome}.imageset/${nome}.svg`] = svg(nome);
    r[`${nome}.imageset/Contents.json`] = json({ images: [{ filename: `${nome}.svg`, idiom: 'universal' }], info,
      properties: { 'preserves-vector-representation': true, 'template-rendering-intent': 'template' } });
  }
  return r;
}

if(process.argv[1] === fileURLToPath(import.meta.url)){
  const conferir = process.argv.includes('--conferir');
  const diferentes = [];
  for(const [rel, texto] of Object.entries(arquivos())){
    const destino = path.join(PASTA, rel);
    if(conferir){
      if(!existsSync(destino) || readFileSync(destino, 'utf8') !== texto) diferentes.push(rel);
      continue;
    }
    mkdirSync(path.dirname(destino), { recursive: true });
    writeFileSync(destino, texto);
  }
  if(diferentes.length){
    console.error('ícones defasados; rode node scripts/icones-app-ios.mjs:\n' + diferentes.join('\n'));
    process.exit(1);
  }
  console.log(conferir ? 'ok - ícones em dia' : 'ícones gravados em app-ios/Custta/Assets.xcassets/Icones');
}

/* Copia o app web para www/ (webDir do Capacitor). Não é bundler: os arquivos
   saem como estão. A lista vem do precache do sw.js, que já é a fonte de verdade
   do que o app precisa para abrir offline. */
import { readFile, writeFile, mkdir, rm, cp, access } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const PRODUCAO = 'https://app-construcao-civil.vercel.app';

/* <meta> não aceita frame-ancestors, report-uri, sandbox nem upgrade-insecure-requests.
   Produção entra em connect-src para o aviso de versão do app nativo. */
export function cspNativa(csp){
  return csp.split(';').map(d => d.trim()).filter(Boolean)
    .filter(d => !/^(frame-ancestors|upgrade-insecure-requests|report-uri|sandbox)\b/.test(d))
    .map(d => d.startsWith('connect-src') ? `${d} ${PRODUCAO}` : d)
    .join('; ');
}

export async function construir({ raiz, destino }){
  const sw = await readFile(join(raiz, 'sw.js'), 'utf8');
  const bloco = sw.match(/const ASSETS = (\[[^\]]*\]);/);
  if(!bloco) throw new Error('ASSETS não encontrado em sw.js');
  const assets = JSON.parse(bloco[1].replace(/'/g, '"')).filter(a => a !== './');
  const css = await readFile(join(raiz, 'styles.css'), 'utf8');
  const doCss = [...css.matchAll(/url\(\s*['"]?([^'")]+)['"]?\s*\)/g)].map(m => m[1])
    .filter(u => !/^(data:|https?:|#)/.test(u));
  const arquivos = [...new Set([...assets, ...doCss].map(a => a.replace(/^\.\//, '')))];
  for(const a of arquivos){
    try{ await access(join(raiz, a)); }
    catch{ throw new Error('arquivo listado não existe: ' + a); }
  }
  await rm(destino, { recursive:true, force:true });
  for(const a of arquivos){
    await mkdir(dirname(join(destino, a)), { recursive:true });
    await cp(join(raiz, a), join(destino, a));
  }
  const vercel = JSON.parse(await readFile(join(raiz, 'vercel.json'), 'utf8'));
  const header = vercel.headers[0].headers.find(h => h.key === 'Content-Security-Policy');
  const indice = join(destino, 'index.html');
  const html = await readFile(indice, 'utf8');
  const marca = '<meta charset="utf-8">';
  if(!html.includes(marca)) throw new Error('index.html sem <meta charset="utf-8">');
  const { versao } = JSON.parse(await readFile(join(raiz, 'versao.json'), 'utf8'));
  await writeFile(join(destino, 'versao-app.js'), `window.APP_VERSAO=${JSON.stringify(versao)};\n`);
  const nativoTag = '<script src="nativo.js"></script>';
  if(!html.includes(nativoTag)) throw new Error('index.html sem ' + nativoTag);
  await writeFile(indice, html
    .replace(marca, `${marca}\n<meta http-equiv="Content-Security-Policy" content="${cspNativa(header.value)}">`)
    .replace(nativoTag, `<script src="versao-app.js"></script>\n${nativoTag}`));
  return arquivos;
}

if(process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)){
  const raiz = resolve(dirname(fileURLToPath(import.meta.url)), '..');
  const lista = await construir({ raiz, destino: join(raiz, 'www') });
  console.log(`www/ pronto com ${lista.length} arquivos`);
}

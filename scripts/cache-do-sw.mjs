/* Confere que o CACHE do sw.js sobe quando a lista ASSETS muda. Sem o incremento, quem já
   instalou o app continua com o retrato velho offline (AGENTS.md, "O que quebra produção").
   A CI roda nos PRs, contra a base. À mão: node scripts/cache-do-sw.mjs origin/main
   Compara o sw.js da árvore de trabalho com o da base no git. A ordem do ASSETS não conta, o
   CACHE nunca desce, e o conteúdo dos arquivos listados fica de fora. Sai com 1 se reprova. */
import { execFileSync } from 'node:child_process';
import { readFileSync, realpathSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = join(dirname(fileURLToPath(import.meta.url)), '..');

/* O ASSETS sai pelo mesmo leitor do scripts/build-www.mjs e do tests/vercel.test.cjs. */
export function lerSw(texto){
  const cache = /const CACHE = 'obras-v(\d+)';/.exec(texto);
  const assets = /const ASSETS = (\[[^\]]*\]);/.exec(texto);
  if(!cache || !assets){
    throw new Error("sw.js fora do formato const CACHE = 'obras-vNN'; e const ASSETS = [...];: ajuste scripts/cache-do-sw.mjs");
  }
  return { versao: Number(cache[1]), assets: JSON.parse(assets[1].replace(/'/g, '"')) };
}

/* { ok, texto }: o texto diz o que foi comparado, também quando passa. */
export function conferirCache(base, atual){
  const antes = new Set(base.assets), depois = new Set(atual.assets);
  const entrou = [...depois].filter(a => !antes.has(a));
  const saiu = [...antes].filter(a => !depois.has(a));
  const mudou = [entrou.length ? `entrou ${entrou.join(', ')}` : '', saiu.length ? `saiu ${saiu.join(', ')}` : '']
    .filter(Boolean).join('; ');
  const resumo = `CACHE obras-v${base.versao} → obras-v${atual.versao}, ${mudou ? `ASSETS mudou (${mudou})` : 'ASSETS igual'}`;
  if(atual.versao < base.versao){
    return { ok: false, texto: `${resumo}: o CACHE desceu. Ele só sobe, mesmo num revert: use obras-v${base.versao + 1}.` };
  }
  if(mudou && atual.versao === base.versao){
    return { ok: false, texto: `${resumo}: o CACHE não subiu. Suba para obras-v${base.versao + 1}.` };
  }
  return { ok: true, texto: `${resumo}: em dia.` };
}

/* realpath dos dois lados: no macOS o tmpdir() passa por symlink (/var → /private/var), e o
   import.meta.url já vem resolvido. */
if(process.argv[1] && realpathSync(process.argv[1]) === fileURLToPath(import.meta.url)){
  const ref = process.argv[2];
  if(!ref || ref.startsWith('-')){
    console.error('uso: node scripts/cache-do-sw.mjs <commit ou ramo da base>');
    process.exit(2);
  }
  try{
    // git e sw.js da mesma raiz: a do repositório onde este script mora.
    const base = lerSw(execFileSync('git', ['show', `${ref}:sw.js`], { cwd: RAIZ, encoding: 'utf8' }));
    const atual = lerSw(readFileSync(join(RAIZ, 'sw.js'), 'utf8'));
    const { ok, texto } = conferirCache(base, atual);
    if(ok){
      console.log(`sw.js contra ${ref}: ${texto}`);
    }else{
      console.error(`sw.js contra ${ref}: ${texto}`);
      process.exit(1);
    }
  }catch(e){
    console.error(e.message);
    process.exit(1);
  }
}

/* Manutenção do SDK local. Os arquivos resultantes são versionados;
   servir/publicar o app não depende de npm nem deste comando. */
import {build} from 'esbuild';
import {mkdir, writeFile} from 'node:fs/promises';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const versao=require('firebase/package.json').version;
await mkdir('vendor/firebase',{recursive:true});
const result=await build({
  entryPoints:{'firebase-app':'firebase/app','firebase-auth':'firebase/auth','firebase-firestore':'firebase/firestore'},
  bundle:true, splitting:true, format:'esm', platform:'browser', target:'es2022',
  outdir:'vendor/firebase', chunkNames:'shared-[hash]', minify:true, legalComments:'eof',
  write:false, metafile:true,
});
for(const file of result.outputFiles) await writeFile(file.path,file.contents);
const arquivos=result.outputFiles.map(f=>'./vendor/firebase/'+f.path.split(/[/\\]/).pop()).sort();
await writeFile('vendor/firebase/assets.json',JSON.stringify(arquivos,null,2)+'\n');
// LICENSE Apache-2.0 está versionada junto da distribuição.
await writeFile('vendor/firebase/README.md',`# Firebase ${versao}\n\nSDK oficial, distribuição ESM local gerada por npm run vendor:firebase.\nArquivos versionados; nenhuma etapa de build no deploy.\nLicença Apache-2.0 em LICENSE; avisos adicionais nos módulos.\n`);

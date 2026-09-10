import {build} from 'esbuild';
import {mkdir, copyFile, writeFile} from 'node:fs/promises';
await mkdir('vendor/sentry', {recursive:true});
await build({stdin:{contents:'export {init, captureEvent, flush, defaultStackParser} from "@sentry/browser";',resolveDir:process.cwd()},bundle:true,format:'iife',globalName:'CusttaSentrySDK',platform:'browser',target:'es2022',minify:true,legalComments:'eof',outfile:'vendor/sentry/sentry.js'});
await copyFile('node_modules/@sentry/browser/LICENSE','vendor/sentry/LICENSE');
await writeFile('vendor/sentry/README.md','# Sentry Browser SDK\n\nDistribuição local MIT, gerada por `npm run vendor:sentry`. Versão fixada no package-lock.json. Sem CDN ou build no deploy.\n');

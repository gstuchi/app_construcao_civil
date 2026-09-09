/* Uso: node scripts/purga-cpf.mjs --project ID [--apply]
   FIREBASE_SERVICE_ACCOUNT ou Application Default Credentials.
   Por padrão apenas conta perfis com CPF; nunca imprime valores pessoais. */
import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getFirestore, FieldPath, FieldValue } from 'firebase-admin/firestore';
const args = process.argv.slice(2);
const projectId = args[args.indexOf('--project') + 1];
if(!args.includes('--project') || !projectId || projectId.startsWith('--')){
  throw new Error('Informe --project ID explicitamente. Use --apply somente após revisar o dry-run.');
}
const cred = process.env.FIREBASE_SERVICE_ACCOUNT;
initializeApp({ projectId, credential:cred ? cert(JSON.parse(cred)) : applicationDefault() });
const db = getFirestore();
const aplicar = args.includes('--apply');
let ultimo = null, encontrados = 0, removidos = 0;
for(;;){
  let query = db.collection('perfis').orderBy(FieldPath.documentId()).limit(200);
  if(ultimo) query = query.startAfter(ultimo);
  const pagina = await query.get();
  if(pagina.empty) break;
  const lote = db.batch(); let quantidade = 0;
  for(const perfil of pagina.docs){
    if(Object.hasOwn(perfil.data(), 'cpf')){
      encontrados++; quantidade++;
      if(aplicar) lote.update(perfil.ref, { cpf:FieldValue.delete() });
    }
  }
  if(aplicar && quantidade){ await lote.commit(); removidos += quantidade; }
  ultimo = pagina.docs.at(-1);
}
console.log(JSON.stringify({ projeto:projectId, modo:aplicar ? 'aplicar' : 'dry-run', encontrados, removidos }));

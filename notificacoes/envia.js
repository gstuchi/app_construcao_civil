'use strict';
/* Cron (GitHub Actions, 9h e 18h de Brasília): pra cada usuário com inscrição
   em push/{uid}, lê dados/{uid}, monta o resumo e envia via Web Push. Inscrição
   morta (404/410) é removida. Falha num aparelho não derruba o resto.
   PERIODO ('manha'|'noite') vem do workflow e muda o conteúdo da mensagem. */

const admin = require('firebase-admin');
const webpush = require('web-push');
const { montaResumo, endpointPushValido } = require('./resumo.js');

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)),
});
const db = admin.firestore();

webpush.setVapidDetails(
  process.env.VAPID_SUBJECT,
  process.env.VAPID_PUBLIC,
  process.env.VAPID_PRIVATE
);

// data de hoje no fuso do usuário (cron roda em UTC; en-CA formata YYYY-MM-DD)
const hojeISO = new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Sao_Paulo' })
  .format(new Date());

// qualquer valor inesperado cai em 'noite', que é o resumo completo
const periodo = process.env.PERIODO === 'manha' ? 'manha' : 'noite';

async function main(){
  const pushDocs = await db.collection('push').get();
  console.log(pushDocs.size + ' usuario(s) com push; hoje = ' + hojeISO
    + '; periodo = ' + periodo);

  for(const pdoc of pushDocs.docs){
    const uid = pdoc.id;
    const subs = (pdoc.data() || {}).subs || {};
    const chaves = Object.keys(subs);
    if(!chaves.length) continue;

    const snap = await db.doc('dados/' + uid).get();
    const resumo = montaResumo(snap.data(), hojeISO, periodo);
    if(!resumo){ console.log(uid + ': nada a dizer'); continue; }

    const payload = JSON.stringify(resumo);
    for(const k of chaves){
      const s = subs[k];
      if(!s || !endpointPushValido(s.endpoint)){
        await pdoc.ref.update(
          new admin.firestore.FieldPath('subs', k),
          admin.firestore.FieldValue.delete(),
        );
        console.warn(uid + '/' + k + ': endpoint inválido, removido');
        continue;
      }
      try{
        await webpush.sendNotification({ endpoint: s.endpoint, keys: s.keys }, payload);
        console.log(uid + '/' + k + ': enviado');
      }catch(err){
        if(err.statusCode === 404 || err.statusCode === 410){
          await pdoc.ref.update(
            new admin.firestore.FieldPath('subs', k),
            admin.firestore.FieldValue.delete(),
          );
          console.log(uid + '/' + k + ': inscricao morta, removida');
        }else{
          console.error(uid + '/' + k + ': falha ' + (err.statusCode || err.message));
        }
      }
    }
  }
}

main().then(() => process.exit(0)).catch(err => { console.error(err); process.exit(1); });

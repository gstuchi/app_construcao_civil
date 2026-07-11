'use strict';
/* Cron diário (GitHub Actions): pra cada usuário com inscrição em push/{uid},
   lê dados/{uid}, monta o resumo e envia via Web Push. Inscrição morta
   (404/410) é removida. Falha num aparelho não derruba o resto. */

const admin = require('firebase-admin');
const webpush = require('web-push');
const { montaResumo } = require('./resumo.js');

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

async function main(){
  const pushDocs = await db.collection('push').get();
  console.log(pushDocs.size + ' usuario(s) com push; hoje = ' + hojeISO);

  for(const pdoc of pushDocs.docs){
    const uid = pdoc.id;
    const subs = (pdoc.data() || {}).subs || {};
    const chaves = Object.keys(subs);
    if(!chaves.length) continue;

    const snap = await db.doc('dados/' + uid).get();
    const resumo = montaResumo(snap.data(), hojeISO);
    if(!resumo){ console.log(uid + ': nada a dizer'); continue; }

    const payload = JSON.stringify(resumo);
    for(const k of chaves){
      const s = subs[k];
      try{
        await webpush.sendNotification({ endpoint: s.endpoint, keys: s.keys }, payload);
        console.log(uid + '/' + k + ': enviado');
      }catch(err){
        if(err.statusCode === 404 || err.statusCode === 410){
          await pdoc.ref.update({ ['subs.' + k]: admin.firestore.FieldValue.delete() });
          console.log(uid + '/' + k + ': inscricao morta, removida');
        }else{
          console.error(uid + '/' + k + ': falha ' + (err.statusCode || err.message));
        }
      }
    }
  }
}

main().then(() => process.exit(0)).catch(err => { console.error(err); process.exit(1); });

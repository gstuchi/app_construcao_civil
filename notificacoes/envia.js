'use strict';
/* CLI do cron (GitHub Actions, 9h e 18h de Brasília). A lógica vive em enviar.js.
   PERIODO ('manha'|'noite') vem do workflow e muda o conteúdo da mensagem. */
const webpush = require('web-push');
const { enviaTodos } = require('./enviar.js');
const { depsAdmin } = require('./admin.js');

webpush.setVapidDetails(process.env.VAPID_SUBJECT, process.env.VAPID_PUBLIC, process.env.VAPID_PRIVATE);

// qualquer valor inesperado cai em 'noite', que é o resumo completo
const periodo = process.env.PERIODO === 'manha' ? 'manha' : 'noite';

enviaTodos({
  ...depsAdmin(process.env.FIREBASE_SERVICE_ACCOUNT), webpush,
  periodo, agora: new Date(),
  log: { info: m => console.log(m), warn: m => console.warn(m), error: m => console.error(m) },
}).then(r => { console.log(JSON.stringify(r)); process.exit(0); })
  .catch(err => { console.error(err); process.exit(1); });

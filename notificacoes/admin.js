'use strict';
/* Dependências do Admin SDK para o envio (cron do GitHub Actions e Vercel Cron).
   O firebase-admin 14 tirou a API em namespace (admin.credential, admin.firestore()):
   só existem os módulos firebase-admin/app, /firestore e /messaging. */
const { initializeApp, getApps, cert } = require('firebase-admin/app');
const { getFirestore, FieldPath, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

function depsAdmin(contaServico){
  if(!getApps().length) initializeApp({ credential: cert(JSON.parse(contaServico)) });
  return { db: getFirestore(), messaging: getMessaging(), FieldPath, FieldValue };
}

module.exports = { depsAdmin };

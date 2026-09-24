'use strict';
/* O cron quebrou em silêncio de 26/08 a 23/09: firebase-admin 14 tirou
   admin.credential/admin.firestore() e o script morria antes de enviar.
   Este teste monta as dependências de verdade, com uma conta de serviço falsa. */
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { generateKeyPairSync } = require('node:crypto');
const { depsAdmin } = require('../notificacoes/admin.js');

const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const contaFalsa = JSON.stringify({
  type: 'service_account', project_id: 'custta-teste', client_email: 'teste@custta-teste.iam.gserviceaccount.com',
  private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }),
});

test('depsAdmin monta db, messaging, FieldPath e FieldValue sem rede', ()=>{
  const d = depsAdmin(contaFalsa);
  assert.equal(typeof d.db.collection, 'function');
  assert.equal(typeof d.messaging.send, 'function');
  assert.equal(typeof d.FieldPath.documentId, 'function');
  assert.equal(typeof d.FieldValue.delete, 'function');
});
test('depsAdmin pode ser chamado de novo (instância quente da Vercel)', ()=>{
  assert.doesNotThrow(()=>depsAdmin(contaFalsa));
});

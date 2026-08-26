/* Testes das rules do Firestore (firestore.rules).
   Rodar com o emulador em volta:
     npm run test:rules
   ou:
     firebase emulators:exec --only firestore "node --test tests/rules.test.mjs"

   Cada teste prova uma fronteira que, se cair, vaza dado de um usuário pro outro
   ou deixa o cliente escrever campo que só o servidor pode escrever. */
import { test, before, after, beforeEach, describe } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, deleteDoc, collection, getDocs, updateDoc,
} from 'firebase/firestore';

const ANA  = { uid: 'ana',  email: 'ana@exemplo.com' };
const BENTO = { uid: 'bento', email: 'bento@exemplo.com' };

/* Blob válido mínimo, no formato que app.js realmente escreve (empty() em app.js:33). */
const blobOk = (extra = {}) => ({
  obras: [],
  config: { taxaMensal: 1, topicosCustom: [] },
  ...extra,
});

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'custta-rules-test',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => { await env?.cleanup(); });

beforeEach(async () => { await env.clearFirestore(); });

/* Semeia contornando as rules, pra testar leitura/atualização de docs que já existem. */
const semeia = fn => env.withSecurityRulesDisabled(ctx => fn(ctx.firestore()));

const comoAna   = () => env.authenticatedContext(ANA.uid,   { email: ANA.email }).firestore();
const comoBento = () => env.authenticatedContext(BENTO.uid, { email: BENTO.email }).firestore();
const deslogado = () => env.unauthenticatedContext().firestore();

describe('dados/{uid} — isolamento por usuário', () => {
  test('Ana lê o próprio documento', async () => {
    await semeia(db => setDoc(doc(db, 'dados', ANA.uid), blobOk()));
    await assertSucceeds(getDoc(doc(comoAna(), 'dados', ANA.uid)));
  });

  test('Ana NÃO lê o documento do Bento', async () => {
    await semeia(db => setDoc(doc(db, 'dados', BENTO.uid), blobOk()));
    await assertFails(getDoc(doc(comoAna(), 'dados', BENTO.uid)));
  });

  test('Ana NÃO escreve no documento do Bento', async () => {
    await assertFails(setDoc(doc(comoAna(), 'dados', BENTO.uid), blobOk()));
  });

  test('deslogado não lê nem escreve', async () => {
    await semeia(db => setDoc(doc(db, 'dados', ANA.uid), blobOk()));
    await assertFails(getDoc(doc(deslogado(), 'dados', ANA.uid)));
    await assertFails(setDoc(doc(deslogado(), 'dados', ANA.uid), blobOk()));
  });

  test('ninguém lista a coleção inteira', async () => {
    await assertFails(getDocs(collection(comoAna(), 'dados')));
  });

  test('Ana apaga o próprio documento (exclusão de conta)', async () => {
    await semeia(db => setDoc(doc(db, 'dados', ANA.uid), blobOk()));
    await assertSucceeds(deleteDoc(doc(comoAna(), 'dados', ANA.uid)));
  });
});

describe('dados/{uid} — forma do blob', () => {
  test('blob válido é aceito', async () => {
    await assertSucceeds(setDoc(doc(comoAna(), 'dados', ANA.uid), blobOk()));
  });

  test('chave desconhecida na raiz é rejeitada', async () => {
    await assertFails(setDoc(doc(comoAna(), 'dados', ANA.uid), blobOk({ admin: true })));
  });

  test('chave desconhecida em config é rejeitada', async () => {
    await assertFails(setDoc(doc(comoAna(), 'dados', ANA.uid), {
      obras: [], config: { taxaMensal: 1, topicosCustom: [], plano: 'pro' },
    }));
  });

  test('taxaMensal acima de 20 é rejeitada', async () => {
    await assertFails(setDoc(doc(comoAna(), 'dados', ANA.uid), {
      obras: [], config: { taxaMensal: 99, topicosCustom: [] },
    }));
  });

  test('taxaMensal zero ou negativa é rejeitada', async () => {
    await assertFails(setDoc(doc(comoAna(), 'dados', ANA.uid), {
      obras: [], config: { taxaMensal: 0, topicosCustom: [] },
    }));
  });

  test('taxaMensal que não é número é rejeitada', async () => {
    await assertFails(setDoc(doc(comoAna(), 'dados', ANA.uid), {
      obras: [], config: { taxaMensal: '1', topicosCustom: [] },
    }));
  });

  test('obras que não é lista é rejeitada', async () => {
    await assertFails(setDoc(doc(comoAna(), 'dados', ANA.uid), {
      obras: { um: 1 }, config: { taxaMensal: 1, topicosCustom: [] },
    }));
  });

  test('mais de 300 obras é rejeitado', async () => {
    await assertFails(setDoc(doc(comoAna(), 'dados', ANA.uid), {
      obras: Array.from({ length: 301 }, (_, i) => ({ id: String(i) })),
      config: { taxaMensal: 1, topicosCustom: [] },
    }));
  });

  test('mais de 50 tópicos customizados é rejeitado', async () => {
    await assertFails(setDoc(doc(comoAna(), 'dados', ANA.uid), {
      obras: [],
      config: { taxaMensal: 1, topicosCustom: Array.from({ length: 51 }, (_, i) => ({ id: String(i) })) },
    }));
  });
});

describe('perfis/{uid} — CPF e plano', () => {
  test('cadastro sem CPF é aceito', async () => {
    await assertSucceeds(setDoc(doc(comoAna(), 'perfis', ANA.uid), {
      email: ANA.email, criado: '2026-08-19T00:00:00.000Z',
    }));
  });

  test('cadastro COM CPF é rejeitado', async () => {
    await assertFails(setDoc(doc(comoAna(), 'perfis', ANA.uid), {
      email: ANA.email, criado: '2026-08-19T00:00:00.000Z', cpf: '12345678909',
    }));
  });

  test('e-mail diferente do token é rejeitado', async () => {
    await assertFails(setDoc(doc(comoAna(), 'perfis', ANA.uid), {
      email: BENTO.email, criado: '2026-08-19T00:00:00.000Z',
    }));
  });

  test('fuso horário é aceito no cadastro', async () => {
    await assertSucceeds(setDoc(doc(comoAna(), 'perfis', ANA.uid), {
      email: ANA.email, criado: '2026-08-19T00:00:00.000Z', tz: 'America/Sao_Paulo',
    }));
  });

  test('cliente NÃO grava plano', async () => {
    await semeia(db => setDoc(doc(db, 'perfis', ANA.uid), {
      email: ANA.email, criado: '2026-08-19T00:00:00.000Z',
    }));
    await assertFails(updateDoc(doc(comoAna(), 'perfis', ANA.uid), { plano: 'pro' }));
  });

  test('cliente atualiza o próprio fuso horário', async () => {
    await semeia(db => setDoc(doc(db, 'perfis', ANA.uid), {
      email: ANA.email, criado: '2026-08-19T00:00:00.000Z',
    }));
    await assertSucceeds(updateDoc(doc(comoAna(), 'perfis', ANA.uid), { tz: 'America/Manaus' }));
  });

  test('cliente NÃO troca e-mail do perfil por valor diferente do token', async () => {
    await semeia(db => setDoc(doc(db, 'perfis', ANA.uid), {
      email: ANA.email, criado: '2026-08-19T00:00:00.000Z',
    }));
    await assertFails(updateDoc(doc(comoAna(), 'perfis', ANA.uid), { email: BENTO.email }));
  });

  test('cliente NÃO grava fuso horário com tipo inválido', async () => {
    await semeia(db => setDoc(doc(db, 'perfis', ANA.uid), {
      email: ANA.email, criado: '2026-08-19T00:00:00.000Z',
    }));
    await assertFails(updateDoc(doc(comoAna(), 'perfis', ANA.uid), { tz: { admin: true } }));
  });

  test('update num perfil que não existe é negado sem erro de avaliação', async () => {
    await assertFails(updateDoc(doc(comoAna(), 'perfis', ANA.uid), { tz: 'America/Manaus' }));
  });

  test('Ana não lê o perfil do Bento', async () => {
    await semeia(db => setDoc(doc(db, 'perfis', BENTO.uid), {
      email: BENTO.email, criado: '2026-08-19T00:00:00.000Z',
    }));
    await assertFails(getDoc(doc(comoAna(), 'perfis', BENTO.uid)));
  });
});

describe('push/{uid} — inscrições e tokens', () => {
  test('grava a própria inscrição web push', async () => {
    await assertSucceeds(setDoc(doc(comoAna(), 'push', ANA.uid), {
      subs: { chave1: { endpoint: 'https://exemplo/1' } },
    }, { merge: true }));
  });

  test('grava token FCM', async () => {
    await assertSucceeds(setDoc(doc(comoAna(), 'push', ANA.uid), {
      tokens: { aparelho1: 'token-abc' },
    }, { merge: true }));
  });

  test('chave desconhecida é rejeitada', async () => {
    await assertFails(setDoc(doc(comoAna(), 'push', ANA.uid), {
      subs: {}, admin: true,
    }, { merge: true }));
  });

  test('mais de 10 inscrições é rejeitado', async () => {
    const subs = {};
    for (let i = 0; i < 11; i++) subs['c' + i] = { endpoint: 'https://exemplo/' + i };
    await assertFails(setDoc(doc(comoAna(), 'push', ANA.uid), { subs }, { merge: true }));
  });

  test('subs que não é mapa é rejeitado', async () => {
    await assertFails(setDoc(doc(comoAna(), 'push', ANA.uid), { subs: 'nada disso' }));
  });

  test('Ana não escreve na inscrição do Bento', async () => {
    await assertFails(setDoc(doc(comoAna(), 'push', BENTO.uid), {
      subs: { chave1: { endpoint: 'https://exemplo/1' } },
    }, { merge: true }));
  });
});

describe('resto do banco', () => {
  test('coleção desconhecida é negada mesmo pro dono', async () => {
    await assertFails(setDoc(doc(comoAna(), 'qualquer', ANA.uid), { x: 1 }));
    await assertFails(getDoc(doc(comoAna(), 'qualquer', ANA.uid)));
  });

  test('Bento também não alcança nada da Ana', async () => {
    await semeia(db => setDoc(doc(db, 'dados', ANA.uid), blobOk()));
    await assertFails(getDoc(doc(comoBento(), 'dados', ANA.uid)));
  });
});

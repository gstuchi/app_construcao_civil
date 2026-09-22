#!/usr/bin/env node
/* Cria (ou repovoa) a conta de demonstração que a revisão da App Store exige.
   O Custta inteiro fica atrás de login, e a Guideline 2.1 reprova app que o
   revisor não consegue abrir. A conta precisa chegar cheia: obra vazia e empty
   state bonito não mostram o produto.

   Os dados são os mesmos das capturas da loja (scripts/dados-demo.mjs): 3 obras
   em fases diferentes, 69 gastos, compras parceladas no cartão e afazeres.

   Uso:
     node scripts/conta-demo.mjs                              # emulador (padrão, não toca em nada real)
     node scripts/conta-demo.mjs --producao --senha 'SENHA'   # projeto real
     node scripts/conta-demo.mjs --email outro@exemplo.com    # troca o e-mail

   No emulador nada é preciso além do próprio emulador rodando. Em produção,
   FIREBASE_SERVICE_ACCOUNT precisa ter o JSON da conta de serviço — a mesma
   variável que o cron de push já usa — e a senha precisa vir por --senha ou
   CONTA_DEMO_SENHA, porque este repositório é público e senha real não pode
   ter valor padrão no código.

   O script é idempotente: rodar de novo na mesma conta só repõe os dados. */
'use strict';
import { pathToFileURL } from 'node:url';
import { dadosDemo } from './dados-demo.mjs';

export const EMAIL_PADRAO = 'revisao.custta@gmail.com';
export const PROJETO = 'app-construcao-civil';

/* O documento tem o formato exato que as rules aceitam em `dados/{uid}`: só
   obras, config e _atualizado. O Admin SDK pula as rules, então a conferência
   precisa acontecer aqui — um campo a mais passaria agora e quebraria a
   primeira gravação que o app fizesse por cima. Função pura, coberta por
   tests/conta-demo.test.mjs. */
export function documentoDados(agora = Date.now()){
  const { obras, config } = dadosDemo();
  return { obras, config, _atualizado: agora };
}

/* `perfis` aceita só email, criado e tz. `plano` fica de fora de propósito:
   nenhum cliente grava esse campo, é o que reserva espaço pra cobrar depois. */
export function documentoPerfil(email, agora = new Date()){
  return { email, criado: agora.toISOString(), tz: 'America/Sao_Paulo' };
}

/* Este repositório é público. Senha de verdade não pode ter valor padrão aqui:
   qualquer um leria e entraria na conta que a Apple está revisando. A senha do
   emulador é fixa de propósito — é descartável e nunca sai desta máquina —, mas
   em produção ela precisa vir de fora, por --senha ou CONTA_DEMO_SENHA. */
export const SENHA_EMULADOR = 'emulador-local';

export function lerArgs(argv, env = process.env){
  const valor = nome => {
    const i = argv.indexOf('--' + nome);
    return i >= 0 ? (argv[i + 1] ?? '') : null;
  };
  const producao = argv.includes('--producao');
  const senha = valor('senha') || env.CONTA_DEMO_SENHA || (producao ? '' : SENHA_EMULADOR);
  return { producao, email: valor('email') || EMAIL_PADRAO, senha };
}

/* Cria o usuário, ou reaproveita o que já existe repondo a senha — ela precisa
   bater com a que está escrita no App Store Connect. */
async function garantirUsuario(auth, { email, senha }){
  try {
    const u = await auth.getUserByEmail(email);
    await auth.updateUser(u.uid, { password: senha, emailVerified: true, disabled: false });
    console.log(`usuário já existia, senha reposta (uid ${u.uid})`);
    return u.uid;
  } catch (err) {
    if(err.code !== 'auth/user-not-found') throw err;
    const u = await auth.createUser({ email, password: senha, emailVerified: true });
    console.log(`usuário criado (uid ${u.uid})`);
    return u.uid;
  }
}

async function principal(opcoes){
  /* Subpaths modulares em vez do namespace default: em ESM o default do
     firebase-admin não expõe auth()/firestore(). */
  const { initializeApp, cert } = await import('firebase-admin/app');
  const { getAuth } = await import('firebase-admin/auth');
  const { getFirestore } = await import('firebase-admin/firestore');

  if(!opcoes.producao){
    process.env.FIRESTORE_EMULATOR_HOST ||= '127.0.0.1:8080';
    process.env.FIREBASE_AUTH_EMULATOR_HOST ||= '127.0.0.1:9099';
    initializeApp({ projectId: PROJETO });
    console.log(`emulador: firestore ${process.env.FIRESTORE_EMULATOR_HOST}, auth ${process.env.FIREBASE_AUTH_EMULATOR_HOST}`);
  } else {
    /* Um FIRESTORE_EMULATOR_HOST esquecido no ambiente faria o --producao
       escrever no emulador em silêncio, e a conta nunca apareceria para o
       revisor. Melhor parar do que mentir que gravou. */
    if(process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST){
      throw new Error('--producao com FIRESTORE_EMULATOR_HOST/FIREBASE_AUTH_EMULATOR_HOST no ambiente. Limpe as duas e rode de novo.');
    }
    if(!process.env.FIREBASE_SERVICE_ACCOUNT){
      throw new Error('--producao exige FIREBASE_SERVICE_ACCOUNT com o JSON da conta de serviço.');
    }
    /* Sem isto a senha viria de um padrão no código, e este repositório é
       público — a conta que a Apple revisa ficaria aberta para qualquer um. */
    if(!opcoes.senha){
      throw new Error('--producao exige a senha por --senha ou CONTA_DEMO_SENHA. O repositório é público: nenhuma senha real pode ter valor padrão no código.');
    }
    initializeApp({ credential: cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)) });
    console.log(`PRODUÇÃO: projeto ${PROJETO}, conta ${opcoes.email}`);
  }

  const uid = await garantirUsuario(getAuth(), opcoes);
  const db = getFirestore();

  const dados = documentoDados();
  await db.doc(`dados/${uid}`).set(dados);
  console.log(`dados/${uid}: ${dados.obras.length} obras, ${dados.obras.reduce((s, o) => s + o.gastos.length, 0)} gastos`);

  await db.doc(`perfis/${uid}`).set(documentoPerfil(opcoes.email));
  console.log(`perfis/${uid}: pronto`);

  console.log('');
  console.log('Para colar em App Store Connect → Informações da versão → Login obrigatório:');
  console.log(`  E-mail: ${opcoes.email}`);
  /* A senha de produção veio de quem rodou o comando, que já a conhece.
     Reimprimi-la só a jogaria no histórico do shell e no log do terminal. */
  console.log(opcoes.producao ? '  Senha:  a que você passou em --senha / CONTA_DEMO_SENHA'
                              : `  Senha:  ${opcoes.senha}`);
  if(!opcoes.producao) console.log('\n(isto rodou no EMULADOR — para valer, rode com --producao)');
}

const executadoDireto = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if(executadoDireto){
  principal(lerArgs(process.argv.slice(2)))
    .then(() => process.exit(0))
    .catch(err => { console.error(err.message || err); process.exit(1); });
}

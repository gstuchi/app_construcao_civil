/* Nuvem (Firebase): auth + Firestore. Único arquivo que fala com o Firebase.
   Expõe window.CLOUD pros scripts clássicos (auth.js, app.js).
   As chaves abaixo são públicas; a segurança vem das rules do Firestore. */
import { initializeApp } from 'https://www.gstatic.com/firebasejs/12.18.0/firebase-app.js';
import {
  getAuth, onAuthStateChanged, createUserWithEmailAndPassword,
  signInWithEmailAndPassword, sendPasswordResetEmail, signOut,
} from 'https://www.gstatic.com/firebasejs/12.18.0/firebase-auth.js';
import {
  initializeFirestore, persistentLocalCache, persistentMultipleTabManager,
  doc, setDoc, onSnapshot, serverTimestamp, deleteField,
} from 'https://www.gstatic.com/firebasejs/12.18.0/firebase-firestore.js';

const firebaseConfig = {
  apiKey: 'AIzaSyBqhDDa8IpXuXNq2kI2-NzzpjAGPCLNTKU',
  authDomain: 'app-construcao-civil.firebaseapp.com',
  projectId: 'app-construcao-civil',
  storageBucket: 'app-construcao-civil.firebasestorage.app',
  messagingSenderId: '111188093030',
  appId: '1:111188093030:web:da78b67181554d30f8a5a7',
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = initializeFirestore(app, {
  localCache: persistentLocalCache({ tabManager: persistentMultipleTabManager() }),
});

let currentUser = null, currentSession = null, authGeracao = 0, saindoSessao = null;
const authCbs = [];
let readyResolve;
const ready = new Promise(r => { readyResolve = r; });
function notificaAuth(ouvinte, user, geracao){
  if(geracao <= ouvinte.ultimaGeracao) return;
  ouvinte.ultimaGeracao = geracao;
  const chama = () => ouvinte.cb(user);
  ouvinte.fila = ouvinte.fila.then(chama, chama);
  ouvinte.fila.catch(()=>{});
}

onAuthStateChanged(auth, u => {
  const anterior = currentSession;
  const proximo = u ? { uid: u.uid, email: u.email } : null;
  authGeracao++;
  currentSession = proximo
    ? Object.freeze({ uid: proximo.uid, geracao: authGeracao })
    : null;
  saindoSessao = null; // transição terminou; próxima sessão pode criar sua própria fila
  if(anterior){
    descartaPendencia(anterior);
    terminaEspera('reject', erroTrocaConta(),
      { uid: anterior.uid, geracao: anterior.geracao, lote: null });
  }
  currentUser = proximo;
  readyResolve();
  authCbs.forEach(ouvinte => notificaAuth(ouvinte, currentUser, authGeracao));
});

/* ---------- fila de escrita ----------
   Um documento só, sobrescrito inteiro: não há merge a fazer, então a fila é
   sempre "o último blob vence". Estados publicados em 'cloud-estado':
   ocioso · salvando · repetindo · offline · erro.
   A classificação de erro e o backoff moram em calc.js porque são puros. */
let saveTimer = null, retryTimer = null, pendingBlob = null, pendingUid = null;
let pendingGeracao = null, pendingLote = null, proximoLote = 0;
let tentativa = 0, emVoo = false, emVooUid = null, emVooGeracao = null, emVooLote = null;
let estadoAtual = 'ocioso';
const espera = []; // {uid, geracao, lote, resolve, reject}; lote null espera logout

const calc = () => window.OBRA_CALC;
const offline = () => navigator.onLine === false;

function setEstado(novo, code, origem){
  estadoAtual = novo;
  window.dispatchEvent(new CustomEvent('cloud-estado', {
    detail: { estado: novo, code: code || null, tentativa, origem: origem || 'escrita' },
  }));
}
function terminaEspera(metodo, arg, filtro){
  for(let i=espera.length-1;i>=0;i--){
    if(filtro && Object.keys(filtro).some(chave => espera[i][chave] !== filtro[chave])) continue;
    const [f] = espera.splice(i, 1);
    f[metodo](arg);
  }
}
function erroTrocaConta(){
  const err = new Error('A conta mudou antes da sincronização.');
  err.code = 'auth-changed';
  return err;
}
function erroDescarte(){
  const err = new Error('A sincronização pendente foi descartada no logout.');
  err.code = 'discarded';
  return err;
}
function mesmaSessao(a, b){
  return !!a && !!b && a.uid === b.uid && a.geracao === b.geracao;
}
function sessaoTemTrabalho(sessao){
  return (pendingBlob && mesmaSessao({ uid: pendingUid, geracao: pendingGeracao }, sessao))
    || (emVoo && mesmaSessao({ uid: emVooUid, geracao: emVooGeracao }, sessao));
}
function descartaPendencia(sessao){
  if(!mesmaSessao({ uid: pendingUid, geracao: pendingGeracao }, sessao)) return;
  const uid = pendingUid;
  const geracao = pendingGeracao, lote = pendingLote;
  clearTimeout(saveTimer); clearTimeout(retryTimer); retryTimer = null;
  pendingBlob = null; pendingUid = null; pendingGeracao = null; pendingLote = null;
  tentativa = 0;
  terminaEspera('reject', erroTrocaConta(), { uid, geracao, lote });
  setEstado('ocioso');
}
function agendaRetry(ms){
  clearTimeout(retryTimer);
  retryTimer = setTimeout(()=>{ retryTimer = null; flushSave(); }, ms);
}

function flushSave(){
  if(!pendingBlob || !currentUser || emVoo) return;
  const sessaoPendente = { uid: pendingUid, geracao: pendingGeracao };
  if(!mesmaSessao(sessaoPendente, currentSession)){
    descartaPendencia(sessaoPendente);
    return;
  }
  // sem rede o setDoc ficaria pendurado sem resolver; o evento 'online' destrava
  if(offline()){ setEstado('offline'); return; }

  const blob = pendingBlob, uid = pendingUid, geracao = pendingGeracao, lote = pendingLote;
  pendingBlob = null; pendingUid = null; pendingGeracao = null; pendingLote = null;
  emVoo = true; emVooUid = uid; emVooGeracao = geracao; emVooLote = lote;
  setEstado(tentativa ? 'repetindo' : 'salvando');
  setDoc(doc(db, 'dados', uid), { ...blob, _atualizado: serverTimestamp() })
    .then(()=>{
      emVoo = false; emVooUid = null; emVooGeracao = null; emVooLote = null; tentativa = 0;
      terminaEspera('resolve', undefined, { uid, geracao, lote });
      if(pendingBlob
        && mesmaSessao({ uid: pendingUid, geracao: pendingGeracao }, { uid, geracao }))
        return flushSave();
      if(pendingBlob) return flushSave(); // entrou blob novo enquanto este subia
      terminaEspera('resolve', undefined, { uid, geracao, lote: null });
      // A confirmação pertence ao lote capturado. Depois de qualquer await, uma
      // nova geração (inclusive do mesmo uid) já é dona do estado global da UI.
      if(!mesmaSessao({ uid, geracao }, currentSession)) return;
      setEstado('ocioso');
    })
    .catch(err=>{
      emVoo = false; emVooUid = null; emVooGeracao = null; emVooLote = null;
      if(!mesmaSessao({ uid, geracao }, currentSession)){
        terminaEspera('reject', erroTrocaConta(), { uid, geracao, lote });
        if(pendingBlob) return flushSave();
        return;
      }
      // Se entrou estado completo mais novo, ele substitui o lote que falhou;
      // seus waiters passam a aguardar essa mesma confirmação, sem ficar órfãos.
      if(pendingBlob && mesmaSessao({ uid: pendingUid, geracao: pendingGeracao }, { uid, geracao })){
        espera.forEach(f => {
          if(f.uid === uid && f.geracao === geracao && f.lote === lote)
            f.lote = pendingLote;
        });
      }else{
        pendingBlob = blob;
        pendingUid = uid;
        pendingGeracao = geracao;
        pendingLote = lote;
      }
      const code = (err && err.code) || 'desconhecido';
      window.dispatchEvent(new CustomEvent('cloud-erro', { detail: { code } }));

      if(calc().erroEhTerminal(err)){
        // tentar de novo não resolve: para o backoff, segura o dado e espera ação
        tentativa = 0;
        setEstado('erro', code);
        terminaEspera('reject', err, { uid, geracao });
        return;
      }
      const ms = calc().proximoBackoff(tentativa++);
      setEstado(offline() ? 'offline' : 'repetindo', code);
      agendaRetry(ms);
    });
}

/* Rede voltou: não adianta esperar os 16s do backoff. Rede caiu: a pill precisa
   dizer isso mesmo sem escrita pendente. Erro terminal não é apagado por nenhum
   dos dois — só some quando alguém tenta de novo. */
window.addEventListener('online', ()=>{
  if(estadoAtual === 'erro') return;
  if(pendingBlob){ tentativa = 0; agendaRetry(0); }
  else setEstado('ocioso');
});
window.addEventListener('offline', ()=>{
  if(estadoAtual !== 'erro') setEstado('offline');
});

window.CLOUD = {
  ready,
  user: () => currentUser,
  sessao: () => currentSession,
  sessaoAtiva: sessao => mesmaSessao(sessao, currentSession)
    && !!currentUser && !mesmaSessao(saindoSessao, sessao),
  onAuth(cb){
    const ouvinte = { cb, ultimaGeracao: 0, fila: Promise.resolve() };
    authCbs.push(ouvinte);
    ready.then(() => notificaAuth(ouvinte, currentUser, authGeracao));
  },

  /* perfis/{uid} guarda só o mínimo. Nada de CPF: o app nunca leu de volta,
     e dado pessoal que não se usa é só responsabilidade sob a LGPD.
     As rules rejeitam qualquer chave fora de email/criado/tz. */
  async signup(email, senha){
    const cred = await createUserWithEmailAndPassword(auth, email, senha);
    await setDoc(doc(db, 'perfis', cred.user.uid),
      { email, criado: new Date().toISOString() });
  },
  login: (email, senha) => signInWithEmailAndPassword(auth, email, senha).then(()=>{}),

  /* Sair descartava em silêncio o que ainda não tinha subido. Agora tenta subir
     primeiro e, se não conseguir, devolve code 'pendente' pra auth.js perguntar.
     Só sai de verdade com {forcar:true}. */
  async logout(sessaoEsperada, opcoes){
    if(sessaoEsperada !== currentSession) throw erroTrocaConta();
    const uidAtual = currentUser && currentUser.uid;
    const sessaoAtual = sessaoEsperada;
    const forcar = !!(opcoes && opcoes.forcar);
    const temTrabalho = () => sessaoTemTrabalho(sessaoAtual);
    while(temTrabalho() && !forcar){
      clearTimeout(saveTimer); clearTimeout(retryTimer); retryTimer = null;
      tentativa = 0;
      let esperaLogout;
      const conclusao = new Promise((resolve, reject)=>{
        esperaLogout = { uid: uidAtual, geracao: sessaoAtual && sessaoAtual.geracao,
          lote: null, resolve, reject };
        espera.push(esperaLogout);
      });
      conclusao.catch(()=>{});
      if(pendingBlob && !emVoo) flushSave();
      const subiu = await Promise.race([
        conclusao.then(()=>true, ()=>false),
        new Promise(r => setTimeout(()=>r(false), 5000)),
      ]);
      if(sessaoAtual !== currentSession){
        const i = espera.indexOf(esperaLogout);
        if(i >= 0) espera.splice(i, 1);
        throw erroTrocaConta();
      }
      if(!subiu){
        const i = espera.indexOf(esperaLogout);
        if(i >= 0) espera.splice(i, 1);
        const err = new Error('Tem lançamento que ainda não subiu.');
        err.code = 'pendente';
        throw err;
      }
    }
    // Fecha atomicamente a entrada da fila. Uma mutação disparada por callback
    // de promise durante o logout precisa falhar explícito, nunca sumir como salva.
    saindoSessao = sessaoAtual;
    clearTimeout(saveTimer); clearTimeout(retryTimer); retryTimer = null;
    const geracaoPendente = pendingGeracao, lotePendente = pendingLote;
    pendingBlob = null; pendingUid = null; pendingGeracao = null; pendingLote = null;
    tentativa = 0;
    if(geracaoPendente != null)
      terminaEspera(forcar ? 'reject' : 'resolve', forcar ? erroDescarte() : undefined,
        { uid: uidAtual, geracao: geracaoPendente, lote: lotePendente });
    terminaEspera('resolve', undefined,
      { uid: uidAtual, geracao: sessaoAtual && sessaoAtual.geracao, lote: null });
    setEstado('ocioso');
    if(sessaoAtual !== currentSession){
      saindoSessao = null;
      throw erroTrocaConta();
    }
    try{ return await signOut(auth); }
    catch(err){ saindoSessao = null; throw err; }
  },
  resetSenha: email => sendPasswordResetEmail(auth, email),

  estado: () => estadoAtual,
  temPendencia: () => !!pendingBlob,

  /* Botão "Tentar de novo" da pill, e o flush do logout. */
  tentarDeNovo(){
    if(!pendingBlob) return Promise.resolve();
    tentativa = 0;
    clearTimeout(saveTimer); clearTimeout(retryTimer); retryTimer = null;
    const p = new Promise((resolve, reject)=>espera.push({ uid: pendingUid,
      geracao: pendingGeracao, lote: pendingLote, resolve, reject }));
    p.catch(()=>{}); // quem chamar decide se trata; sem isto vira unhandledrejection
    flushSave();
    return p;
  },

  watchDados(sessao, cb){
    if(!mesmaSessao(sessao, currentSession)) return () => {};
    return onSnapshot(doc(db, 'dados', sessao.uid),
      snap => {
        if(!mesmaSessao(sessao, currentSession)) return;
        const d = snap.data();
        if(d) delete d._atualizado;
        cb(d || null, { fromCache: snap.metadata.fromCache,
                        pendingWrites: snap.metadata.hasPendingWrites,
                        localDirty: !!sessaoTemTrabalho(sessao) });
      },
      /* Sem este callback, uma rule errada pararia a chegada de dados sem
         sintoma nenhum na tela — risco criado pela própria fronteira de segurança. */
      err => {
        if(mesmaSessao(sessao, currentSession))
          setEstado('erro', (err && err.code) || 'desconhecido', 'leitura');
      });
  },
  /* Devolve promise que resolve quando o servidor confirmou. Offline com cache
     persistente ela fica pendente de propósito: quem chama corre contra um
     timer e avisa "salvo no aparelho" (ver salvarComAviso em app.js). */
  saveDados(blob, sessao){
    if(!sessao || sessao !== currentSession || !currentUser || sessao.uid !== currentUser.uid){
      const rejeitada = Promise.reject(erroTrocaConta());
      rejeitada.catch(()=>{});
      return rejeitada;
    }
    if(mesmaSessao(saindoSessao, sessao)){
      const err = new Error('A conta está saindo; o lançamento não entrou na fila.');
      err.code = 'auth-signing-out';
      const rejeitada = Promise.reject(err);
      rejeitada.catch(()=>{});
      return rejeitada;
    }
    if(pendingBlob && !mesmaSessao({ uid: pendingUid, geracao: pendingGeracao }, sessao))
      descartaPendencia({ uid: pendingUid, geracao: pendingGeracao });
    pendingBlob = JSON.parse(JSON.stringify(blob));
    pendingUid = currentUser && currentUser.uid;
    pendingGeracao = sessao.geracao;
    const loteAnterior = pendingLote;
    pendingLote = ++proximoLote;
    if(loteAnterior != null)
      espera.forEach(f => {
        if(f.uid === pendingUid && f.geracao === pendingGeracao && f.lote === loteAnterior)
          f.lote = pendingLote;
      });

    if(estadoAtual === 'erro') tentativa = 0; // gesto novo do usuário, backoff limpo
    clearTimeout(saveTimer); clearTimeout(retryTimer); retryTimer = null;
    const p = new Promise((resolve, reject)=>espera.push({ uid: pendingUid,
      geracao: pendingGeracao, lote: pendingLote, resolve, reject }));
    p.catch(()=>{});
    setEstado(offline() ? 'offline' : 'salvando');
    saveTimer = setTimeout(flushSave, 300);
    return p;
  },
  /* Inscrição de push por aparelho. Doc separado de dados/{uid} de propósito:
     saveDados reescreve o blob inteiro e apagaria a inscrição do outro aparelho. */
  savePushSub(chave, sub, sessao){
    if(!mesmaSessao(sessao, currentSession)) return Promise.reject(erroTrocaConta());
    return setDoc(doc(db, 'push', sessao.uid), { subs: { [chave]: sub } }, { merge: true });
  },
  removePushSub(chave, sessao){
    if(!mesmaSessao(sessao, currentSession)) return Promise.reject(erroTrocaConta());
    return setDoc(doc(db, 'push', sessao.uid), { subs: { [chave]: deleteField() } }, { merge: true });
  },
};
window.dispatchEvent(new Event('cloud-pronto'));

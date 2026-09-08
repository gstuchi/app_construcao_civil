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
  doc, setDoc, onSnapshot, serverTimestamp, deleteField, waitForPendingWrites,
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

let currentUser = null;
const authCbs = [];
let readyResolve;
const ready = new Promise(r => { readyResolve = r; });

/* ---------- fila de escrita ----------
   Um documento só, sobrescrito inteiro: não há merge a fazer, então a fila é
   sempre "o último blob vence". Estados publicados em 'cloud-estado':
   ocioso · salvando · repetindo · offline · erro.
   A classificação de erro e o backoff moram em calc.js porque são puros. */
let retryTimer = null, pendingBlob = null, dirty = false;
let tentativa = 0, emVoo = false, estadoAtual = 'ocioso';
let versaoEscrita = 0;
let saindo = false, pendenciaCache = false;
const espera = []; // {resolve, reject} das chamadas de saveDados ainda sem resposta do servidor

const calc = () => window.OBRA_CALC;
const offline = () => navigator.onLine === false;

function setEstado(novo, code, origem){
  estadoAtual = novo;
  window.dispatchEvent(new CustomEvent('cloud-estado', {
    detail: { estado: novo, code: code || null, tentativa, origem: origem || 'escrita' },
  }));
}
function terminaEspera(metodo, arg){
  espera.splice(0).forEach(f => f[metodo](arg));
}
function agendaRetry(ms){
  clearTimeout(retryTimer);
  retryTimer = setTimeout(()=>{ retryTimer = null; flushSave(); }, ms);
}

function flushSave(){
  if(!pendingBlob || !currentUser) return;

  const blob = pendingBlob; pendingBlob = null; emVoo = true;
  const versao = ++versaoEscrita;
  setEstado(offline() ? 'offline' : tentativa ? 'repetindo' : 'salvando');
  setDoc(doc(db, 'dados', currentUser.uid), { ...blob, _atualizado: serverTimestamp() })
    .then(()=>{
      if(versao !== versaoEscrita) return;
      emVoo = false; tentativa = 0;
      if(pendingBlob) return flushSave(); // entrou blob novo enquanto este subia
      dirty = false;
      setEstado('ocioso');
      terminaEspera('resolve');
    })
    .catch(err=>{
      if(versao !== versaoEscrita) return;
      emVoo = false;
      // guarda o blob pra próxima tentativa E avisa a UI: falha calada fazia o
      // usuário achar que estava salvo (ver 'cloud-erro' em app.js)
      pendingBlob = pendingBlob || blob;
      const code = (err && err.code) || 'desconhecido';
      window.dispatchEvent(new CustomEvent('cloud-erro', { detail: { code } }));

      if(calc().erroEhTerminal(err)){
        // tentar de novo não resolve: para o backoff, segura o dado e espera ação
        tentativa = 0;
        setEstado('erro', code);
        terminaEspera('reject', err);
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
  else setEstado(emVoo || pendenciaCache ? 'salvando' : 'ocioso');
});
window.addEventListener('offline', ()=>{
  if(estadoAtual !== 'erro') setEstado('offline');
});

onAuthStateChanged(auth, u => {
  if(currentUser && currentUser.uid !== (u && u.uid)){
    versaoEscrita++;
    clearTimeout(retryTimer);
    pendingBlob = null; dirty = false; emVoo = false; tentativa = 0;
    pendenciaCache = false;
    terminaEspera('reject', Object.assign(new Error('Sessão alterada.'), { code: 'cancelled' }));
    setEstado(offline() ? 'offline' : 'ocioso');
  }
  currentUser = u ? { uid: u.uid, email: u.email } : null;
  readyResolve();
  authCbs.forEach(cb => cb(currentUser));
});

window.CLOUD = {
  ready,
  user: () => currentUser,
  onAuth(cb){ authCbs.push(cb); ready.then(()=>cb(currentUser)); },

  /* perfis/{uid} guarda só o mínimo. Nada de CPF: o app nunca leu de volta,
     e dado pessoal que não se usa é só responsabilidade sob a LGPD.
     As rules rejeitam qualquer chave fora de email/criado/tz. */
  async signup(email, senha){
    const cred = await createUserWithEmailAndPassword(auth, email, senha);
    await setDoc(doc(db, 'perfis', cred.user.uid),
      { email, criado: new Date().toISOString() });
  },
  login: (email, senha) => signInWithEmailAndPassword(auth, email, senha).then(()=>{}),

  /* Não descarta a fila persistente: aguarda também escritas de sessões
     anteriores. O timeout mantém a conta aberta para reconectar e tentar sair. */
  async logout(opcoes){
    if(saindo) throw Object.assign(new Error('Saída já em andamento.'), { code: 'pendente' });
    saindo = true;
    const uid = currentUser && currentUser.uid;
    let limite;
    try{
      if(offline()) throw Object.assign(new Error('Conecte à internet antes de sair.'), { code: 'pendente' });
      const subiu = await Promise.race([
        Promise.all([window.CLOUD.tentarDeNovo(), waitForPendingWrites(db)]).then(()=>true, ()=>false),
        new Promise(r => { limite = setTimeout(()=>r(false), 5000); }),
      ]);
      if(!subiu) throw Object.assign(new Error('Tem lançamento que ainda não subiu.'), { code: 'pendente' });
      if(!currentUser || currentUser.uid !== uid)
        throw Object.assign(new Error('Sessão alterada durante a saída.'), { code: 'cancelled' });
      if(opcoes && opcoes.antesDeSair) await opcoes.antesDeSair();
      if(!currentUser || currentUser.uid !== uid)
        throw Object.assign(new Error('Sessão alterada durante a saída.'), { code: 'cancelled' });
      await signOut(auth);
      clearTimeout(retryTimer); retryTimer = null;
      pendingBlob = null; dirty = false; tentativa = 0; emVoo = false; pendenciaCache = false;
      versaoEscrita++;
      terminaEspera('reject', Object.assign(new Error('Sessão encerrada.'), { code: 'cancelled' }));
      setEstado('ocioso');
    } finally {
      clearTimeout(limite);
      saindo = false;
    }
  },
  resetSenha: email => sendPasswordResetEmail(auth, email),

  estado: () => estadoAtual,
  temPendencia: () => !!pendingBlob || emVoo || pendenciaCache,

  /* Botão "Tentar de novo" da pill, e o flush do logout. */
  tentarDeNovo(){
    if(!pendingBlob && !emVoo) return Promise.resolve();
    tentativa = 0;
    clearTimeout(retryTimer); retryTimer = null;
    const p = new Promise((resolve, reject)=>espera.push({ resolve, reject }));
    p.catch(()=>{}); // quem chamar decide se trata; sem isto vira unhandledrejection
    flushSave();
    return p;
  },

  watchDados(cb){
    if(!currentUser) return () => {};
    const uid = currentUser.uid;
    return onSnapshot(doc(db, 'dados', uid), { includeMetadataChanges: true },
      snap => {
        if(!currentUser || currentUser.uid !== uid) return;
        pendenciaCache = snap.metadata.hasPendingWrites;
        if(!dirty && estadoAtual !== 'erro')
          setEstado(offline() ? 'offline' : pendenciaCache ? 'salvando' : 'ocioso');
        const d = snap.data();
        if(d) delete d._atualizado;
        cb(d || null, { fromCache: snap.metadata.fromCache,
                        pendingWrites: snap.metadata.hasPendingWrites,
                        localDirty: dirty });
      },
      /* Sem este callback, uma rule errada pararia a chegada de dados sem
         sintoma nenhum na tela — risco criado pela própria fronteira de segurança. */
      err => {
        if(currentUser && currentUser.uid === uid)
          setEstado('erro', (err && err.code) || 'desconhecido', 'leitura');
      });
  },
  /* A promise confirma o servidor, não a mera entrega ao cache do SDK. */
  saveDados(blob){
    if(!currentUser || saindo){
      const p = Promise.reject(Object.assign(new Error('Sessão indisponível para salvar.'), { code: 'cancelled' }));
      p.catch(()=>{});
      return p;
    }
    pendingBlob = JSON.parse(JSON.stringify(blob));
    dirty = true;
    if(estadoAtual === 'erro') tentativa = 0; // gesto novo do usuário, backoff limpo
    clearTimeout(retryTimer); retryTimer = null;
    const p = new Promise((resolve, reject)=>espera.push({ resolve, reject }));
    p.catch(()=>{});
    setEstado(offline() ? 'offline' : 'salvando');
    // Entrega cada versão imediatamente ao SDK, inclusive offline. A fila
    // persistente do Firestore mantém a ordem e sobrevive ao fechamento do app.
    flushSave();
    return p;
  },
  /* Inscrição de push por aparelho. Doc separado de dados/{uid} de propósito:
     saveDados reescreve o blob inteiro e apagaria a inscrição do outro aparelho. */
  savePushSub(chave, sub){
    if(!currentUser) return Promise.resolve();
    return setDoc(doc(db, 'push', currentUser.uid), { subs: { [chave]: sub } }, { merge: true });
  },
  removePushSub(chave){
    if(!currentUser) return Promise.resolve();
    return setDoc(doc(db, 'push', currentUser.uid), { subs: { [chave]: deleteField() } }, { merge: true });
  },
};
window.dispatchEvent(new Event('cloud-pronto'));

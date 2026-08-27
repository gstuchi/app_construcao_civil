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

let currentUser = null;
const authCbs = [];
let readyResolve;
const ready = new Promise(r => { readyResolve = r; });

onAuthStateChanged(auth, u => {
  currentUser = u ? { uid: u.uid, email: u.email } : null;
  readyResolve();
  authCbs.forEach(cb => cb(currentUser));
});

/* ---------- fila de escrita ----------
   Um documento só, sobrescrito inteiro: não há merge a fazer, então a fila é
   sempre "o último blob vence". Estados publicados em 'cloud-estado':
   ocioso · salvando · repetindo · offline · erro.
   A classificação de erro e o backoff moram em calc.js porque são puros. */
let saveTimer = null, retryTimer = null, pendingBlob = null, dirty = false;
let tentativa = 0, emVoo = false, estadoAtual = 'ocioso';
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
  if(!pendingBlob || !currentUser || emVoo) return;
  // sem rede o setDoc ficaria pendurado sem resolver; o evento 'online' destrava
  if(offline()){ setEstado('offline'); return; }

  const blob = pendingBlob; pendingBlob = null; emVoo = true;
  setEstado(tentativa ? 'repetindo' : 'salvando');
  setDoc(doc(db, 'dados', currentUser.uid), { ...blob, _atualizado: serverTimestamp() })
    .then(()=>{
      emVoo = false; tentativa = 0;
      if(pendingBlob) return flushSave(); // entrou blob novo enquanto este subia
      dirty = false;
      setEstado('ocioso');
      terminaEspera('resolve');
    })
    .catch(err=>{
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
  else setEstado('ocioso');
});
window.addEventListener('offline', ()=>{
  if(estadoAtual !== 'erro') setEstado('offline');
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

  /* Sair descartava em silêncio o que ainda não tinha subido. Agora tenta subir
     primeiro e, se não conseguir, devolve code 'pendente' pra auth.js perguntar.
     Só sai de verdade com {forcar:true}. */
  async logout(opcoes){
    if(pendingBlob && !(opcoes && opcoes.forcar)){
      clearTimeout(saveTimer); clearTimeout(retryTimer); retryTimer = null;
      tentativa = 0;
      const subiu = await Promise.race([
        window.CLOUD.tentarDeNovo().then(()=>true, ()=>false),
        new Promise(r => setTimeout(()=>r(false), 5000)),
      ]);
      if(!subiu){
        const err = new Error('Tem lançamento que ainda não subiu.');
        err.code = 'pendente';
        throw err;
      }
    }
    clearTimeout(saveTimer); clearTimeout(retryTimer); retryTimer = null;
    pendingBlob = null; dirty = false; tentativa = 0; emVoo = false;
    terminaEspera('resolve');
    setEstado('ocioso');
    return signOut(auth);
  },
  resetSenha: email => sendPasswordResetEmail(auth, email),

  estado: () => estadoAtual,
  temPendencia: () => !!pendingBlob,

  /* Botão "Tentar de novo" da pill, e o flush do logout. */
  tentarDeNovo(){
    if(!pendingBlob) return Promise.resolve();
    tentativa = 0;
    clearTimeout(saveTimer); clearTimeout(retryTimer); retryTimer = null;
    const p = new Promise((resolve, reject)=>espera.push({ resolve, reject }));
    p.catch(()=>{}); // quem chamar decide se trata; sem isto vira unhandledrejection
    flushSave();
    return p;
  },

  watchDados(cb){
    if(!currentUser) return () => {};
    return onSnapshot(doc(db, 'dados', currentUser.uid),
      snap => {
        const d = snap.data();
        if(d) delete d._atualizado;
        cb(d || null, { fromCache: snap.metadata.fromCache,
                        pendingWrites: snap.metadata.hasPendingWrites,
                        localDirty: dirty });
      },
      /* Sem este callback, uma rule errada pararia a chegada de dados sem
         sintoma nenhum na tela — risco criado pela própria fronteira de segurança. */
      err => setEstado('erro', (err && err.code) || 'desconhecido', 'leitura'));
  },
  /* Devolve promise que resolve quando o servidor confirmou. Offline com cache
     persistente ela fica pendente de propósito: quem chama corre contra um
     timer e avisa "salvo no aparelho" (ver salvarComAviso em app.js). */
  saveDados(blob){
    pendingBlob = JSON.parse(JSON.stringify(blob));
    dirty = true;
    if(estadoAtual === 'erro') tentativa = 0; // gesto novo do usuário, backoff limpo
    clearTimeout(saveTimer); clearTimeout(retryTimer); retryTimer = null;
    const p = new Promise((resolve, reject)=>espera.push({ resolve, reject }));
    p.catch(()=>{});
    setEstado(offline() ? 'offline' : 'salvando');
    saveTimer = setTimeout(flushSave, 300);
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

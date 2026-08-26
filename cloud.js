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

let saveTimer = null, pendingBlob = null, dirty = false;
function flushSave(){
  if(!pendingBlob || !currentUser) return;
  const blob = pendingBlob; pendingBlob = null;
  setDoc(doc(db, 'dados', currentUser.uid), { ...blob, _atualizado: serverTimestamp() })
    .then(()=>{ if(!pendingBlob) dirty = false; })
    .catch(err=>{
      // guarda o blob pra próxima tentativa E avisa a UI: falha calada fazia o
      // usuário achar que estava salvo (ver 'cloud-erro' em app.js)
      pendingBlob = pendingBlob || blob;
      window.dispatchEvent(new CustomEvent('cloud-erro', { detail: { code: (err && err.code) || 'desconhecido' } }));
    });
}

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
  logout: () => { pendingBlob = null; dirty = false; return signOut(auth); },
  resetSenha: email => sendPasswordResetEmail(auth, email),

  watchDados(cb){
    if(!currentUser) return () => {};
    return onSnapshot(doc(db, 'dados', currentUser.uid),
      snap => {
        const d = snap.data();
        if(d) delete d._atualizado;
        cb(d || null, { fromCache: snap.metadata.fromCache,
                        pendingWrites: snap.metadata.hasPendingWrites,
                        localDirty: dirty });
      });
  },
  saveDados(blob){
    pendingBlob = JSON.parse(JSON.stringify(blob));
    dirty = true;
    clearTimeout(saveTimer);
    saveTimer = setTimeout(flushSave, 300);
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

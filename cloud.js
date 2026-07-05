/* Nuvem (Firebase): auth + Firestore. Único arquivo que fala com o Firebase.
   Expõe window.CLOUD pros scripts clássicos (auth.js, app.js).
   As chaves abaixo são públicas; a segurança vem das rules do Firestore. */
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js';
import {
  getAuth, onAuthStateChanged, createUserWithEmailAndPassword,
  signInWithEmailAndPassword, sendPasswordResetEmail, signOut,
} from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js';
import {
  initializeFirestore, persistentLocalCache, persistentMultipleTabManager,
  doc, setDoc, getDoc, onSnapshot, serverTimestamp,
} from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js';

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

let saveTimer = null, pendingBlob = null;
function flushSave(){
  if(!pendingBlob || !currentUser) return;
  const blob = pendingBlob; pendingBlob = null;
  setDoc(doc(db, 'dados', currentUser.uid),
    { ...blob, _atualizado: serverTimestamp() }).catch(()=>{ pendingBlob = pendingBlob || blob; });
}

window.CLOUD = {
  ready,
  user: () => currentUser,
  onAuth(cb){ authCbs.push(cb); ready.then(()=>cb(currentUser)); },

  async signup(email, senha, cpf){
    const cred = await createUserWithEmailAndPassword(auth, email, senha);
    await setDoc(doc(db, 'perfis', cred.user.uid),
      { email, cpf, criado: new Date().toISOString() });
  },
  login: (email, senha) => signInWithEmailAndPassword(auth, email, senha).then(()=>{}),
  logout: () => { pendingBlob = null; return signOut(auth); },
  resetSenha: email => sendPasswordResetEmail(auth, email),

  watchDados(cb){
    if(!currentUser) return () => {};
    return onSnapshot(doc(db, 'dados', currentUser.uid),
      snap => {
        const d = snap.data();
        if(d) delete d._atualizado;
        cb(d || null, { fromCache: snap.metadata.fromCache,
                        pendingWrites: snap.metadata.hasPendingWrites });
      });
  },
  saveDados(blob){
    pendingBlob = JSON.parse(JSON.stringify(blob));
    clearTimeout(saveTimer);
    saveTimer = setTimeout(flushSave, 300);
  },
  async importarSeVazio(blob){
    if(!currentUser) return false;
    const snap = await getDoc(doc(db, 'dados', currentUser.uid));
    const d = snap.data();
    if(d && d.obras && d.obras.length) return false;
    await setDoc(doc(db, 'dados', currentUser.uid),
      { ...blob, _atualizado: serverTimestamp() });
    return true;
  },
};
window.dispatchEvent(new Event('cloud-pronto'));

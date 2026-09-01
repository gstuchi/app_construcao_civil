/* Duplê do SDK do Firebase pros testes da fila de escrita do cloud.js.
   Só o suficiente pro cloud.js importar e rodar sem rede. */

export const __ctrl = {
  setDocChamadas: [],
  respostas: [],          // fila de 'ok' ou {code}; vazia = 'ok'
  signOutChamado: 0,
  authCb: null,
  snapshotErroCb: null,
  snapshots: [],
};

export function initializeApp(){ return { nome: 'stub' }; }
export function getAuth(){ return { nome: 'auth-stub' }; }
export function onAuthStateChanged(_auth, cb){
  __ctrl.authCb = cb;
  cb({ uid: 'u-teste', email: 'teste@exemplo.com' });
  return () => {};
}
export function createUserWithEmailAndPassword(){ return Promise.resolve({ user: { uid: 'u-teste' } }); }
export function signInWithEmailAndPassword(){ return Promise.resolve({ user: { uid: 'u-teste' } }); }
export function sendPasswordResetEmail(){ return Promise.resolve(); }
export function signOut(){ __ctrl.signOutChamado++; return Promise.resolve(); }

export function initializeFirestore(){ return { nome: 'db-stub' }; }
export function persistentLocalCache(){ return {}; }
export function persistentMultipleTabManager(){ return {}; }
export function doc(_db, col, id){ return { path: col + '/' + id }; }
export function serverTimestamp(){ return '@ts'; }
export function deleteField(){ return '@del'; }
export function onSnapshot(ref, cb, errCb){
  const watch = { ref, cb, errCb, ativo: true };
  __ctrl.snapshots.push(watch);
  __ctrl.snapshotErroCb = errCb;
  return () => { watch.ativo = false; };
}

export function setDoc(ref, dados){
  __ctrl.setDocChamadas.push({ ref, dados });
  const r = __ctrl.respostas.shift();
  if(!r || r === 'ok') return Promise.resolve();
  if(r instanceof Promise) return r;
  return Promise.reject(Object.assign(new Error(r.code), { code: r.code }));
}

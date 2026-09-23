/* Duplê do SDK do Firebase pros testes da fila de escrita do cloud.js.
   Só o suficiente pro cloud.js importar e rodar sem rede. */

export const __ctrl = {
  setDocChamadas: [],
  respostas: [],          // fila de 'ok' ou {code}; vazia = 'ok'
  signOutChamado: 0,
  authCb: null,
  snapshotErroCb: null,
  snapshotCb: null,
  pendentesSDK: Promise.resolve(),
  token: Promise.resolve('token-teste'),
  passos: [], falhas: {},
  perfil: null,
};

export function initializeApp(){ return { nome: 'stub' }; }
export function getAuth(){ return { nome: 'auth-stub', currentUser:{ uid:'u-teste', email:'teste@exemplo.com' } }; }
export function getIdToken(){ return __ctrl.token; }
export const EmailAuthProvider = { credential:(email,senha)=>({email,senha}) };
function passo(nome){ __ctrl.passos.push(nome); return __ctrl.falhas[nome] ? Promise.reject(__ctrl.falhas[nome]) : Promise.resolve(); }
export function reauthenticateWithCredential(){ return passo('reauth'); }
export function updatePassword(){ return passo('senha'); }
export function deleteUser(){ return passo('deleteUser'); }
export function sendEmailVerification(){ __ctrl.aoVerificar?.(); return passo('verificacao'); }
export function reload(u){ if(__ctrl.verificado && u) u.emailVerified = true; return Promise.resolve(); }
export function terminate(){ return passo('terminate'); }
export function clearIndexedDbPersistence(){ return passo('clear'); }
export function writeBatch(){ return { delete(ref){ __ctrl.passos.push('delete:'+ref.path); }, commit:()=>passo('commit') }; }
export function onAuthStateChanged(_auth, cb){
  __ctrl.authCb = cb;
  cb({ uid: 'u-teste', email: 'teste@exemplo.com' });
  return () => {};
}
export function createUserWithEmailAndPassword(){ return Promise.resolve({ user: { uid: 'u-teste' } }); }
export function signInWithEmailAndPassword(){ return Promise.resolve({ user: { uid: 'u-teste' } }); }
export function sendPasswordResetEmail(){ return Promise.resolve(); }
export function signOut(){ __ctrl.signOutChamado++; return passo('signOut'); }

export function initializeFirestore(){ return { nome: 'db-stub' }; }
export function persistentLocalCache(){ return {}; }
export function persistentMultipleTabManager(){ __ctrl.tabManager = 'multiple'; return {}; }
export function persistentSingleTabManager(){ __ctrl.tabManager = 'single'; return {}; }
export function doc(_db, col, id){ return { path: col + '/' + id }; }
export function serverTimestamp(){ return '@ts'; }
export function deleteField(){ return '@del'; }
export function onSnapshot(_ref, _opcoes, cb, errCb){ __ctrl.snapshotCb = cb; __ctrl.snapshotErroCb = errCb; return () => {}; }
export function waitForPendingWrites(){ return __ctrl.pendentesSDK; }

export function setDoc(ref, dados){
  __ctrl.setDocChamadas.push({ ref, dados });
  const r = __ctrl.respostas.shift();
  if(r && typeof r.then === 'function') return r;
  if(!r || r === 'ok') return Promise.resolve();
  return Promise.reject(Object.assign(new Error(r.code), { code: r.code }));
}

export function getDoc(ref){
  __ctrl.passos.push('get:'+ref.path);
  if(__ctrl.falhas.get) return Promise.reject(__ctrl.falhas.get);
  const dados = __ctrl.perfil;
  return Promise.resolve({ exists:()=>dados!==null, data:()=>dados });
}
export function updateDoc(ref, dados){
  __ctrl.passos.push('update:'+ref.path);
  __ctrl.updateDocChamadas = [...(__ctrl.updateDocChamadas||[]), { ref, dados }];
  return __ctrl.falhas.update ? Promise.reject(__ctrl.falhas.update) : Promise.resolve();
}

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
  credenciais: [],        // credenciais passadas a signInWithCredential/reauthenticateWithCredential
  revogados: [],          // tokens passados a revokeAccessToken
  perfisAtualizados: [],  // argumentos de updateProfile
  popups: [],             // provedores passados a signInWithPopup/reauthenticateWithPopup
  resultadoLogin: null,   // o que signInWithCredential devolve
  resultadoPopup: null,   // o que signInWithPopup/reauthenticateWithPopup devolvem
  perfilCache: null,     // conteúdo de perfis/{uid} no cache local; null = não está no cache
};

export function initializeApp(config){ __ctrl.config = config; return { nome: 'stub' }; }
export function getAuth(){ return { nome: 'auth-stub', currentUser:{ uid:'u-teste', email:'teste@exemplo.com' } }; }
export function getIdToken(){ return __ctrl.token; }
export const EmailAuthProvider = { credential:(email,senha)=>({email,senha}) };
function passo(nome){ __ctrl.passos.push(nome); return __ctrl.falhas[nome] ? Promise.reject(__ctrl.falhas[nome]) : Promise.resolve(); }
export function reauthenticateWithCredential(_u, cred){
  __ctrl.credenciais.push(cred);
  const p = cred && cred.providerId;
  return passo(p === 'apple.com' ? 'reauthApple' : p === 'google.com' ? 'reauthGoogle' : 'reauth');
}
export class GoogleAuthProvider{
  constructor(){ this.providerId = 'google.com'; }
  setCustomParameters(p){ this.parametros = p; }
  static credential(idToken){ return { providerId:'google.com', idToken }; }
}
export class OAuthProvider{
  constructor(providerId){ this.providerId = providerId; this.escopos = []; }
  addScope(s){ this.escopos.push(s); return this; }
  setCustomParameters(p){ this.parametros = p; return this; }
  credential({ idToken, rawNonce }){ return { providerId:this.providerId, idToken, rawNonce }; }
  static credentialFromResult(r){ return (r && r.credencial) || null; }
}
export function signInWithPopup(_a, provedor){ __ctrl.popups.push(provedor); return passo('popup').then(()=>__ctrl.resultadoPopup); }
export function reauthenticateWithPopup(_u, provedor){ __ctrl.popups.push(provedor); return passo('reauthPopup').then(()=>__ctrl.resultadoPopup); }
export function signInWithCredential(_a, cred){ __ctrl.credenciais.push(cred); return passo('credencial').then(()=>__ctrl.resultadoLogin); }
export function revokeAccessToken(_a, token){ __ctrl.revogados.push(token); return passo('revogar'); }
export function updateProfile(_u, dados){ __ctrl.perfisAtualizados.push(dados); return passo('updateProfile'); }
export function signInWithRedirect(){ return passo('redirect'); }
export function getRedirectResult(){
  return __ctrl.falhas.redirectResult ? Promise.reject(__ctrl.falhas.redirectResult) : Promise.resolve(null);
}
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
export function getDocFromServer(ref){
  __ctrl.passos.push('getServer:'+ref.path);
  if(__ctrl.falhas.getServer) return Promise.reject(__ctrl.falhas.getServer);
  const dados = __ctrl.perfil;
  return Promise.resolve({ exists:()=>dados!==null, data:()=>dados });
}
/* Como o SDK: documento fora do cache rejeita (não responde 'não existe'). */
export function getDocFromCache(ref){
  __ctrl.passos.push('getCache:'+ref.path);
  if(__ctrl.falhas.getCache) return Promise.reject(__ctrl.falhas.getCache);
  const dados = __ctrl.perfilCache;
  if(dados === null) return Promise.reject(Object.assign(new Error('Failed to get document from cache.'), { code:'unavailable' }));
  return Promise.resolve({ exists:()=>true, data:()=>dados });
}

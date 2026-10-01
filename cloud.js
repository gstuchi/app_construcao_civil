/* Nuvem (Firebase): auth + Firestore. Único arquivo que fala com o Firebase.
   Expõe window.CLOUD pros scripts clássicos (auth.js, app.js).
   As chaves abaixo são públicas; a segurança vem das rules do Firestore. */
import { initializeApp } from './vendor/firebase/firebase-app.js';
import {
  getAuth, onAuthStateChanged, createUserWithEmailAndPassword,
  signInWithEmailAndPassword, sendPasswordResetEmail, signOut, getIdToken,
  EmailAuthProvider, reauthenticateWithCredential, updatePassword, deleteUser,
  sendEmailVerification, reload,
  GoogleAuthProvider, signInWithPopup, signInWithRedirect, getRedirectResult, reauthenticateWithPopup,
  OAuthProvider, signInWithCredential, revokeAccessToken, updateProfile,
} from './vendor/firebase/firebase-auth.js';
import {
  initializeFirestore, persistentLocalCache, persistentMultipleTabManager, persistentSingleTabManager,
  doc, setDoc, getDoc, getDocFromCache, getDocFromServer, updateDoc, onSnapshot, serverTimestamp, deleteField, waitForPendingWrites,
  writeBatch, terminate, clearIndexedDbPersistence,
} from './vendor/firebase/firebase-firestore.js';

const firebaseConfig = {
  apiKey: 'AIzaSyBqhDDa8IpXuXNq2kI2-NzzpjAGPCLNTKU',
  /* Em custta.com.br o handler do login com Google vem do próprio domínio (a
     Vercel repassa /__/auth ao Firebase). Com firebaseapp.com o Safari, que
     isola armazenamento de terceiros, perde a volta do redirect. */
  authDomain: globalThis.location?.hostname === 'custta.com.br' ? 'custta.com.br' : 'app-construcao-civil.firebaseapp.com',
  projectId: 'app-construcao-civil',
  storageBucket: 'app-construcao-civil.firebasestorage.app',
  messagingSenderId: '111188093030',
  appId: '1:111188093030:web:da78b67181554d30f8a5a7',
};

/* Client OAuth web do projeto. É público: vai na URL de todo login do Google na
   web. O plugin nativo do Google exige o client web, e o Firebase aceita o
   idToken porque o client é do mesmo projeto (111188093030). */
const GOOGLE_CLIENT_ID_WEB = '111188093030-76cph7rdbibirr8l61jn72r3i3f92e8u.apps.googleusercontent.com';

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
/* Qual botão mandou para o redirect: o erro na volta diz "Apple" ou "Google". */
const CHAVE_REDIRECT = 'custta-redirect';
function lembraRedirect(provedor){ try{ sessionStorage.setItem(CHAVE_REDIRECT, provedor); }catch{} }
function provedorDoRedirect(){
  try{
    const p = sessionStorage.getItem(CHAVE_REDIRECT);
    sessionStorage.removeItem(CHAVE_REDIRECT);
    return p === 'apple.com' ? 'apple.com' : 'google.com';
  }catch{ return 'google.com'; }
}
/* Volta do signInWithRedirect (PWA instalado / popup bloqueado). O usuário
   chega pelo onAuthStateChanged; aqui interessa o erro, pra tela de login, e o
   nome que a Apple manda só no primeiro login. */
getRedirectResult(auth).then(r=>{ provedorDoRedirect(); return guardaNomeApple(r); }, err=>{
  window.dispatchEvent(new CustomEvent('cloud-social-erro', { detail:{ code:(err && err.code) || 'desconhecido', provedor:provedorDoRedirect() } }));
});
function provedorGoogle(){
  const p = new GoogleAuthProvider();
  p.setCustomParameters({ prompt:'select_account' });
  return p;
}
function provedorApple(){
  const p = new OAuthProvider('apple.com');
  p.addScope('email'); p.addScope('name');
  p.setCustomParameters({ locale:'pt_BR' });
  return p;
}
/* Nonce do login nativo: 32 bytes aleatórios em hex. A Apple assina o SHA-256
   dele (nativo.js) e o Firebase confere com este valor cru. */
function nonceAleatorio(){
  const b = new Uint8Array(32); crypto.getRandomValues(b);
  return Array.from(b, x=>x.toString(16).padStart(2,'0')).join('');
}
async function credencialAppleNativa(){
  const rawNonce = nonceAleatorio();
  const r = await window.OBRA_NATIVO.entrarApple({ rawNonce });
  if(!r || !r.idToken) throw Object.assign(new Error('A Apple não devolveu a credencial.'), { code:'auth/invalid-credential' });
  return {
    credencial: new OAuthProvider('apple.com').credential({ idToken:r.idToken, rawNonce }),
    codigo: r.authorizationCode || '',
    nome: [r.givenName, r.familyName].filter(Boolean).join(' ').trim(),
  };
}
/* Google no app: a folha nativa devolve o idToken e o SDK JavaScript entra com
   ele. O Firebase reconhece a conta pelo sub, o mesmo da web: mesmo uid. */
async function credencialGoogleNativa(){
  const r = await window.OBRA_NATIVO.entrarGoogle({ clientId: GOOGLE_CLIENT_ID_WEB });
  if(!r || !r.idToken) throw Object.assign(new Error('O Google não devolveu a credencial.'), { code:'auth/invalid-credential' });
  return GoogleAuthProvider.credential(r.idToken);
}
/* A Apple só manda o nome no primeiro login. No displayName ele chega ao "Falta
   pouco" (nomeExibicao) sem a tela pedir de novo. Melhor esforço: falhar aqui
   não desfaz o login. Na abertura (volta do redirect) currentUser pode ainda não
   existir; o try cobre. */
async function gravaNome(u, nome){
  if(!u || u.displayName || !nome) return;
  try{
    await updateProfile(u, { displayName:nome });
    if(currentUser && currentUser.uid === u.uid) currentUser.nomeExibicao = nome;
  }catch{}
}
/* Web: o Firebase costuma guardar o nome sozinho; quando não guarda, ele vem só
   na resposta desta vez (firstName/lastName). */
function guardaNomeApple(resultado){
  const r = resultado && resultado._tokenResponse;
  if(!r || r.providerId !== 'apple.com') return;
  return gravaNome(resultado.user, [r.firstName, r.lastName].filter(Boolean).join(' ').trim());
}
/* PWA instalado no iPhone: o popup abre fora do app e não volta. */
function pwaInstalado(){
  try{ return !!(globalThis.matchMedia?.('(display-mode: standalone)').matches || globalThis.navigator?.standalone); }
  catch{ return false; }
}
// Cada aba mantém uma trava compartilhada. Saída/exclusão exigem exclusividade:
// outra aba não pode escrever entre o flush e a limpeza do IndexedDB.
let liberaAba = null, travaAba = null;
async function registrarAba(){
  if(!navigator.locks) return;
  let pronta;
  const iniciou = new Promise(r=>{ pronta=r; });
  travaAba = navigator.locks.request('custta-conta-' + firebaseConfig.projectId, {mode:'shared'}, ()=>{
    pronta(); return new Promise(r=>{ liberaAba=r; });
  });
  await iniciou;
}
await registrarAba();
async function contaExclusiva(acao){
  if(!navigator.locks){
    if(typeof document !== 'undefined') throw Object.assign(new Error('Atualize o navegador para gerenciar a conta.'), {code:'navegador'});
    return acao(); // ambiente de testes sem navegador
  }
  liberaAba(); await travaAba;
  try{
    return await navigator.locks.request('custta-conta-' + firebaseConfig.projectId, {ifAvailable:true}, async trava=>{
      if(!trava) throw Object.assign(new Error('Feche outras abas do Custta antes de continuar.'), {code:'outra-aba'});
      return acao();
    });
  }finally{ await registrarAba(); }
}
/* WKWebView não tem abas: o gerenciador multi-aba só acrescenta coordenação inútil
   e depende de APIs que o iOS pode suspender em segundo plano. */
const nativo = !!window.OBRA_NATIVO?.ehNativo();
const db = initializeFirestore(app, {
  localCache: persistentLocalCache({ tabManager: nativo ? persistentSingleTabManager({}) : persistentMultipleTabManager() }),
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
const leituras = new Set();
let verificacao = null, ultimaVerificacao = 0;
const SESSAO_INVALIDA = new Set(['auth/invalid-refresh-token', 'auth/user-disabled',
  'auth/user-token-expired', 'auth/user-not-found', 'auth/invalid-user-token']);

function verificarSessao(forcar = false){
  if(!currentUser || !auth.currentUser || offline()) return Promise.resolve(false);
  const uid = currentUser.uid;
  if(verificacao && verificacao.uid === uid) return verificacao.promise;
  if(!forcar && Date.now() - ultimaVerificacao < 60000) return Promise.resolve(true);
  ultimaVerificacao = Date.now();
  const consulta = { uid };
  consulta.promise = getIdToken(auth.currentUser, true).then(()=>true, async err=>{
    // Ausência de rede nunca encerra a conta. Credencial invalidada precisa
    // provocar onAuth(null), inclusive quando o SDK não faz isso sozinho.
    if(currentUser && currentUser.uid === uid && SESSAO_INVALIDA.has(err.code)) await signOut(auth);
    return false;
  }).finally(()=>{ if(verificacao === consulta) verificacao = null; });
  consulta.promise.catch(()=>{});
  verificacao = consulta;
  return consulta.promise;
}

const calc = () => window.OBRA_CALC;
const offline = () => navigator.onLine === false;
const fusoAtual = () => Intl.DateTimeFormat().resolvedOptions().timeZone || 'America/Sao_Paulo';

function setEstado(novo, code, origem){
  const falhou = [...leituras].find(l=>l.erro);
  if(novo !== 'erro' && falhou){ novo = 'erro'; code = falhou.erro.code; origem = 'leitura'; }
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
  // A validação participa da mesma fila: confirmação de uma versão anterior
  // nunca pode esconder a rejeição da edição atual.
  let escrita;
  try{
    if(!calc().blobCabe(blob)) throw Object.assign(new Error('Limite de dados excedido.'), { code: 'limite' });
    escrita = setDoc(doc(db, 'dados', currentUser.uid), { ...blob, _atualizado: serverTimestamp() });
  } catch(err){ escrita = Promise.reject(err); }
  escrita
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
      const terminal = code === 'limite' || calc().erroEhTerminal(err);
      if(code === 'unauthenticated') verificarSessao(true);
      window.dispatchEvent(new CustomEvent('cloud-erro', { detail: { code, terminal } }));

      if(terminal){
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
  verificarSessao();
  if(estadoAtual === 'erro') return;
  if(pendingBlob){ tentativa = 0; agendaRetry(0); }
  else setEstado(emVoo || pendenciaCache ? 'salvando' : 'ocioso');
});
window.addEventListener('offline', ()=>{
  if(estadoAtual !== 'erro') setEstado('offline');
});

const CHAVE_LIMPEZA = 'custta-limpar-cache';
let cacheBloqueado = false, limpezaEmCurso = null;
function marcaCache(on){
  // Se não pudermos guardar a recuperação, não iniciar saída destrutiva.
  if(typeof localStorage === 'undefined') return;
  if(on) localStorage.setItem(CHAVE_LIMPEZA, '1');
  else localStorage.removeItem(CHAVE_LIMPEZA);
}
function temMarcaCache(){
  try{ return typeof localStorage !== 'undefined' && localStorage.getItem(CHAVE_LIMPEZA) === '1'; }
  catch{ return false; }
}
function avisaCache(){
  cacheBloqueado = true;
  window.dispatchEvent(new Event('cloud-cache-bloqueado'));
}
// Antes de qualquer leitura: retoma uma limpeza interrompida pelo fechamento.
const inicioCache = temMarcaCache()
  ? clearIndexedDbPersistence(db).then(()=>marcaCache(false)).catch(()=>avisaCache())
  : Promise.resolve();
async function limparCache(){
  if(limpezaEmCurso) return limpezaEmCurso;
  cacheBloqueado = true;
  limpezaEmCurso = (async()=>{
    [...leituras].forEach(l=>l.parar());
    await terminate(db);
    await clearIndexedDbPersistence(db);
    marcaCache(false);
    if(window.location) window.location.reload();
  })().catch(err=>{ avisaCache(); throw err; })
    .finally(()=>{ limpezaEmCurso = null; });
  return limpezaEmCurso;
}
window.addEventListener('focus', ()=>verificarSessao());
if(typeof document !== 'undefined') document.addEventListener('visibilitychange', ()=>{
  if(document.visibilityState === 'visible') verificarSessao();
});

onAuthStateChanged(auth, async u => {
  await inicioCache;
  if(currentUser && currentUser.uid !== (u && u.uid)){
    [...leituras].forEach(l=>l.parar());
    versaoEscrita++;
    clearTimeout(retryTimer);
    pendingBlob = null; dirty = false; emVoo = false; tentativa = 0;
    pendenciaCache = false;
    ultimaVerificacao = 0;
    terminaEspera('reject', Object.assign(new Error('Sessão alterada.'), { code: 'cancelled' }));
    setEstado(offline() ? 'offline' : 'ocioso');
  }
  const provedores = u ? (u.providerData || []).map(p=>p.providerId) : [];
  currentUser = u ? { uid: u.uid, email: u.email, emailVerificado:!!u.emailVerified, provedores,
    // sem providerData (conta antiga/duplê) vale o fluxo com senha de sempre
    temSenha: !provedores.length || provedores.includes('password'),
    nomeExibicao: u.displayName || '' } : null;
  readyResolve();
  authCbs.forEach(cb => cb(currentUser));
  if(!u && temMarcaCache() && !saindo) limparCache().catch(()=>{});
});

function usuarioOnline(){
  if(offline()) throw Object.assign(new Error('Conecte à internet para continuar.'), { code:'offline' });
  if(cacheBloqueado || !auth.currentUser) throw Object.assign(new Error('Entre novamente.'), { code:'cancelled' });
  return auth.currentUser;
}
/* Conta sem senha confirma no provedor dela; com Google e Apple, Apple primeiro
   (é o que funciona também no app). Devolve a prova da Apple pra revogação. */
function provedorDaConta(){
  if(currentUser?.temSenha !== false) return 'password';
  return currentUser.provedores.includes('apple.com') ? 'apple.com' : 'google.com';
}
async function reautenticar(senha){
  const u = usuarioOnline();
  const provedor = provedorDaConta();
  let prova = null;
  if(provedor === 'apple.com'){
    if(nativo){
      const { credencial, codigo } = await credencialAppleNativa();
      await reauthenticateWithCredential(u, credencial);
      prova = { codigo };
    }else{
      const r = await reauthenticateWithPopup(u, provedorApple());
      prova = { accessToken: OAuthProvider.credentialFromResult(r)?.accessToken || '' };
    }
  }
  else if(provedor === 'google.com'){
    if(nativo) await reauthenticateWithCredential(u, await credencialGoogleNativa());
    else await reauthenticateWithPopup(u, provedorGoogle());
  }
  else await reauthenticateWithCredential(u, EmailAuthProvider.credential(u.email, senha));
  if(auth.currentUser?.uid !== u.uid) throw Object.assign(new Error('Sessão alterada.'), { code:'cancelled' });
  return { u, prova };
}
/* A Apple exige revogar o token ao apagar a conta (Guideline 5.1.1(v)). Na web o
   popup devolve access token, que o SDK revoga; no app a Apple devolve
   authorizationCode, que só o endpoint REST aceita (tokenType CODE, o mesmo pedido
   do SDK nativo do Firebase). Falha aqui não segura a exclusão: fica no diagnóstico. */
const LIMITE_REVOGAR_MS = 10000; /* AbortSignal.timeout não existe no iOS 15 */
async function revogarApple(u, prova){
  if(!prova) return;
  const ctl = new AbortController();
  const timer = setTimeout(()=>ctl.abort(), LIMITE_REVOGAR_MS);
  try{
    if(prova.accessToken){ await revokeAccessToken(auth, prova.accessToken); return; }
    if(!prova.codigo) throw new Error('Apple sem token para revogar');
    const resp = await fetch('https://identitytoolkit.googleapis.com/v2/accounts:revokeToken?key=' + firebaseConfig.apiKey, {
      method:'POST', headers:{ 'Content-Type':'application/json' }, signal: ctl.signal,
      body: JSON.stringify({ providerId:'apple.com', tokenType:'CODE', token:prova.codigo, idToken: await getIdToken(u) }),
    });
    if(!resp.ok) throw new Error('revokeToken HTTP ' + resp.status);
  }catch(err){
    try{ window.OBRA_DIAG?.registra('apple-revogar', (err && err.message) || String(err), err && err.stack); }catch{}
  }finally{ clearTimeout(timer); }
}
/* Depois de sair (ou apagar a conta) no app, o SDK do Google esquece a sessão que
   guarda no aparelho. Sem await: a limpeza recarrega a página e não pode esperar
   o SDK; sairGoogle nunca rejeita. Na web e em OBRA_NATIVO antigo não faz nada. */
function esquecerGoogle(){
  if(nativo) window.OBRA_NATIVO?.sairGoogle?.();
}
async function aguardarFila(){
  let timer;
  try{
    const ok = await Promise.race([
      Promise.all([window.CLOUD.tentarDeNovo(), waitForPendingWrites(db)]).then(()=>true),
      new Promise(r=>{ timer=setTimeout(()=>r(false),5000); })
    ]);
    if(!ok) throw Object.assign(new Error('Aguarde a sincronização antes de continuar.'), { code:'pendente' });
  }finally{ clearTimeout(timer); }
}

window.CLOUD = {
  ready,
  cacheBloqueado:()=>cacheBloqueado,
  limparCache,
  user: () => currentUser,
  onAuth(cb){ authCbs.push(cb); ready.then(()=>cb(currentUser)); },

  /* perfis/{uid} guarda só o mínimo. Nada de CPF: o app nunca leu de volta,
     e dado pessoal que não se usa é só responsabilidade sob a LGPD.
     O perfil (nome, sobrenome, origem) chega já normalizado por OBRA_CADASTRO;
     as rules são a fronteira e rejeitam qualquer chave fora da lista. */
  async signup(email, senha, perfil = {}){
    if(cacheBloqueado) throw Object.assign(new Error('Limpe os dados locais antes de entrar.'), { code:'cache' });
    const cred = await createUserWithEmailAndPassword(auth, email, senha);
    await setDoc(doc(db, 'perfis', cred.user.uid),
      { email:cred.user.email ?? email, criado: new Date().toISOString(), tz:fusoAtual(), ...perfil });
    // onAuthStateChanged (e o watchDados que ele liga) pode disparar o primeiro
    // renderAjustes() antes deste setDoc terminar, deixando o cache de Ajustes
    // (por uid) preso em "sem nome". Avisa que o perfil mudou pra ele reler.
    window.dispatchEvent(new Event('perfil-alterado'));
    /* Só o link clicado prova que o e-mail existe. Falha no envio (limite do
       Firebase, rede) não desfaz a conta: o aviso no topo oferece reenviar. */
    try{ auth.languageCode = 'pt-BR'; await sendEmailVerification(cred.user); }catch{}
  },
  async lerPerfil(){
    const u = auth.currentUser;
    if(!u) return null;
    try{
      const snap = await getDoc(doc(db, 'perfis', u.uid));
      if(!snap.exists()) return null;
      const { nome, sobrenome } = snap.data();
      const r = {};
      if(typeof nome === 'string' && nome) r.nome = nome;
      if(typeof sobrenome === 'string' && sobrenome) r.sobrenome = sobrenome;
      return r;
    }catch{ return null; }
  },
  async salvarNome(nome, sobrenome){
    const u = usuarioOnline();
    const ref = doc(db, 'perfis', u.uid);
    const snap = await getDoc(ref);
    // email: u.email cura perfis legados salvos com o e-mail digitado (antes de
    // d2402db) — as rules exigem email == request.auth.token.email pra atualizar.
    if(snap.exists()){
      await updateDoc(ref, { email: u.email, nome, sobrenome: sobrenome ? sobrenome : deleteField() });
    }else{
      // Sem doc: cadastro cujo setDoc falhou depois do createUser (rede caiu, ou
      // conta antiga). Recria com o mínimo que o signup grava.
      await setDoc(ref, { email: u.email, criado: new Date().toISOString(), tz: fusoAtual(), nome, ...(sobrenome ? { sobrenome } : {}) });
    }
  },
  login: (email, senha) => cacheBloqueado
    ? Promise.reject(Object.assign(new Error('Limpe os dados locais antes de entrar.'), { code:'cache' }))
    : signInWithEmailAndPassword(auth, email, senha).then(()=>{}),
  async entrarGoogle(){
    if(cacheBloqueado) throw Object.assign(new Error('Limpe os dados locais antes de entrar.'), { code:'cache' });
    auth.languageCode = 'pt-BR';
    if(nativo){ await signInWithCredential(auth, await credencialGoogleNativa()); return; }
    if(pwaInstalado()){ lembraRedirect('google.com'); return signInWithRedirect(auth, provedorGoogle()); }
    try{ await signInWithPopup(auth, provedorGoogle()); }
    catch(err){
      if(err?.code === 'auth/popup-blocked'){ lembraRedirect('google.com'); return signInWithRedirect(auth, provedorGoogle()); }
      throw err;
    }
  },
  async entrarApple(){
    if(cacheBloqueado) throw Object.assign(new Error('Limpe os dados locais antes de entrar.'), { code:'cache' });
    auth.languageCode = 'pt-BR';
    if(nativo){
      const { credencial, nome } = await credencialAppleNativa();
      const r = await signInWithCredential(auth, credencial);
      await gravaNome(r?.user, nome);
      return;
    }
    if(pwaInstalado()){ lembraRedirect('apple.com'); return signInWithRedirect(auth, provedorApple()); }
    try{ await guardaNomeApple(await signInWithPopup(auth, provedorApple())); }
    catch(err){
      if(err?.code === 'auth/popup-blocked'){ lembraRedirect('apple.com'); return signInWithRedirect(auth, provedorApple()); }
      throw err;
    }
  },
  /* Só conta Google ou Apple: o cadastro por e-mail já grava o perfil. Perfil no cache
     basta (e não segura a tela de login a cada abertura com rede ruim); cache
     vazio não prova que o documento não existe, então aí pergunta ao servidor.
     Qualquer falha do servidor responde "não pendente": travar quem está sem
     rede é pior que perder a origem. O uid vem de auth.currentUser (o SDK) e os
     provedores de currentUser, o mesmo retrato que auth.js consultou. */
  async perfilPendente(){
    const u = auth.currentUser;
    if(!u || !currentUser?.provedores.some(p=>p === 'google.com' || p === 'apple.com')) return false;
    const ref = doc(db, 'perfis', u.uid);
    try{ if((await getDocFromCache(ref)).exists()) return false; }catch{}
    try{ return !(await getDocFromServer(ref)).exists(); }
    catch{ return false; }
  },
  async completarPerfil(perfil){
    const u = usuarioOnline();
    await setDoc(doc(db, 'perfis', u.uid), { email: u.email, criado: new Date().toISOString(), tz: fusoAtual(), ...perfil });
    window.dispatchEvent(new Event('perfil-alterado'));
  },
  async enviarVerificacao(){
    const u = usuarioOnline();
    await reload(u);
    if(auth.currentUser?.uid !== u.uid) throw Object.assign(new Error('Sessão alterada.'), { code:'cancelled' });
    if(u.emailVerified){
      currentUser.emailVerificado = true;
      window.dispatchEvent(new Event('cloud-conta'));
      return false;
    }
    auth.languageCode = 'pt-BR';
    await sendEmailVerification(u);
    return true;
  },
  /* Relê o usuário no servidor para saber se o link já foi clicado.
     Nunca rejeita: offline ou erro só mantém o estado atual. */
  async conferirVerificacao(){
    try{
      const u = usuarioOnline();
      await reload(u);
      if(auth.currentUser?.uid !== u.uid || !currentUser) return false;
      if(u.emailVerified && !currentUser.emailVerificado){
        currentUser.emailVerificado = true;
        window.dispatchEvent(new Event('cloud-conta'));
      }
      return !!u.emailVerified;
    }catch{ return false; }
  },
  async trocarSenha(atual, nova){
    const regra = window.OBRA_CADASTRO.validaSenha(nova, auth.currentUser?.email);
    if(!regra.ok) throw Object.assign(new Error(regra.erro), { code:'auth/weak-password' });
    const { u } = await reautenticar(atual);
    await updatePassword(u, nova);
  },
  async apagarConta(senha, confirmacao, opcoes){
    if(confirmacao !== 'APAGAR') throw Object.assign(new Error('Digite APAGAR para confirmar.'), { code:'confirmacao' });
    if(saindo) throw Object.assign(new Error('Operação em andamento.'), { code:'pendente' });
    const u = usuarioOnline();
    saindo = true;
    let dadosApagados = false;
    try{
      /* Conta sem senha (Google ou Apple): a confirmação precisa sair ainda no
         gesto do usuário. Depois dos awaits da trava entre abas o Safari bloqueia
         o popup. reautenticar confere o uid, e o corpo da trava confere de novo
         antes do batch. */
      const semSenha = currentUser?.temSenha === false;
      let prova = null;
      if(semSenha){ ({ prova } = await reautenticar()); opcoes?.aoConfirmar?.(); }
      return await contaExclusiva(async()=>{
        if(!semSenha) await reautenticar(senha);
        await aguardarFila();
        if(offline() || auth.currentUser?.uid !== u.uid) throw Object.assign(new Error('Conexão ou sessão alterada.'), { code:'cancelled' });
        // Desativa a inscrição antes do batch: removePushSub não pode recriar push depois dele.
        if(opcoes?.antesDeApagar) await opcoes.antesDeApagar();
        if(offline() || auth.currentUser?.uid !== u.uid) throw Object.assign(new Error('Conexão ou sessão alterada.'), { code:'cancelled' });
        const lote = writeBatch(db);
        for(const colecao of ['dados','perfis','push']) lote.delete(doc(db, colecao, u.uid));
        await lote.commit();
        dadosApagados = true;
        marcaCache(true);
        await revogarApple(u, prova);
        try{ await deleteUser(u); }catch(err){ marcaCache(false); throw err; }
        esquecerGoogle();
        await limparCache();
        });
    }catch(err){
      if(dadosApagados && auth.currentUser?.uid === u.uid){
        err.dadosApagados = true;
      }
      throw err;
    }finally{ saindo = false; }
  },

  /* Não descarta a fila persistente: aguarda também escritas de sessões
     anteriores. O timeout mantém a conta aberta para reconectar e tentar sair. */
  async logout(opcoes){
    if(saindo) throw Object.assign(new Error('Saída já em andamento.'), { code: 'pendente' });
    saindo = true;
    const uid = currentUser && currentUser.uid;
    let limite;
    try{
      return await contaExclusiva(async()=>{
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
        marcaCache(true);
        try{ await signOut(auth); }catch(err){ marcaCache(false); throw err; }
        esquecerGoogle();
        clearTimeout(retryTimer); retryTimer = null;
        pendingBlob = null; dirty = false; tentativa = 0; emVoo = false; pendenciaCache = false;
        versaoEscrita++;
        terminaEspera('reject', Object.assign(new Error('Sessão encerrada.'), { code: 'cancelled' }));
        setEstado('ocioso');
        await limparCache();
        });
    } finally {
      clearTimeout(limite);
      saindo = false;
    }
  },
  resetSenha: email => sendPasswordResetEmail(auth, email),
  verificarSessao,

  estado: () => estadoAtual,
  temPendencia: () => !!pendingBlob || emVoo || pendenciaCache,

  /* Botão "Tentar de novo" da pill, e o flush do logout. */
  tentarDeNovo(){
    const reabertas = [...leituras].filter(l=>l.erro).map(l=>l.reiniciar());
    if(!pendingBlob && !emVoo){
      const leitura = Promise.all(reabertas);
      leitura.catch(()=>{});
      return leitura;
    }
    tentativa = 0;
    clearTimeout(retryTimer); retryTimer = null;
    const p = new Promise((resolve, reject)=>espera.push({ resolve, reject }));
    p.catch(()=>{}); // quem chamar decide se trata; sem isto vira unhandledrejection
    flushSave();
    const resultado = Promise.all([p, ...reabertas]);
    resultado.catch(()=>{});
    return resultado;
  },

  watchDados(cb){
    if(!currentUser || cacheBloqueado) return () => {};
    const uid = currentUser.uid;
    let cancelar = ()=>{}, revisao = 0, resolveLeitura, rejectLeitura;
    const leitura = { erro: null, parar, reiniciar };
    leituras.add(leitura);
    function parar(){
      revisao++; cancelar(); leituras.delete(leitura);
      if(rejectLeitura) rejectLeitura(Object.assign(new Error('Leitura encerrada.'), { code: 'cancelled' }));
    }
    function reiniciar(){
      cancelar();
      if(rejectLeitura) rejectLeitura(Object.assign(new Error('Leitura substituída.'), { code: 'cancelled' }));
      const atual = ++revisao;
      const pronta = new Promise((resolve,reject)=>{ resolveLeitura=resolve; rejectLeitura=reject; });
      pronta.catch(()=>{});
      cancelar = onSnapshot(doc(db, 'dados', uid), { includeMetadataChanges: true },
      snap => {
        if(atual !== revisao || !currentUser || currentUser.uid !== uid) return;
        if(!snap.metadata.fromCache){
          const recuperou = !!leitura.erro;
          leitura.erro = null;
          resolveLeitura(); rejectLeitura = null;
          if(recuperou && !dirty) setEstado(offline() ? 'offline' : 'ocioso');
        }
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
        if(atual === revisao && currentUser && currentUser.uid === uid){
          leitura.erro = err;
          rejectLeitura?.(err); rejectLeitura = null;
          setEstado('erro', (err && err.code) || 'desconhecido', 'leitura');
        }
      });
      return pronta;
    }
    reiniciar();
    return parar;
  },
  /* A promise confirma o servidor, não a mera entrega ao cache do SDK. */
  saveDados(blob){
    if(!currentUser || saindo || cacheBloqueado){
      window.dispatchEvent(new CustomEvent('cloud-erro', { detail:{ code:'cancelled', terminal:true } }));
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
  /* Token FCM do app iOS. Mesmo documento, campo separado: web e nativo convivem. */
  savePushToken(chave, dados){
    if(!currentUser) return Promise.resolve();
    return setDoc(doc(db, 'push', currentUser.uid), { tokens: { [chave]: dados } }, { merge: true });
  },
  removePushToken(chave){
    if(!currentUser) return Promise.resolve();
    return setDoc(doc(db, 'push', currentUser.uid), { tokens: { [chave]: deleteField() } }, { merge: true });
  },
};
window.dispatchEvent(new Event('cloud-pronto'));

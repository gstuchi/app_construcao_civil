/* Nuvem (Firebase): auth + Firestore. Único arquivo que fala com o Firebase.
   Expõe window.CLOUD pros scripts clássicos (auth.js, app.js).
   As chaves abaixo são públicas; a segurança vem das rules do Firestore. */
import { initializeApp } from './vendor/firebase/firebase-app.js';
import {
  getAuth, onAuthStateChanged, createUserWithEmailAndPassword,
  signInWithEmailAndPassword, sendPasswordResetEmail, signOut, getIdToken,
  EmailAuthProvider, reauthenticateWithCredential, updatePassword, deleteUser,
  sendEmailVerification, reload,
} from './vendor/firebase/firebase-auth.js';
import {
  initializeFirestore, persistentLocalCache, persistentMultipleTabManager, persistentSingleTabManager,
  doc, setDoc, getDoc, updateDoc, onSnapshot, serverTimestamp, deleteField, waitForPendingWrites,
  writeBatch, terminate, clearIndexedDbPersistence,
} from './vendor/firebase/firebase-firestore.js';

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
  currentUser = u ? { uid: u.uid, email: u.email, emailVerificado:!!u.emailVerified } : null;
  readyResolve();
  authCbs.forEach(cb => cb(currentUser));
  if(!u && temMarcaCache() && !saindo) limparCache().catch(()=>{});
});

function usuarioOnline(){
  if(offline()) throw Object.assign(new Error('Conecte à internet para continuar.'), { code:'offline' });
  if(cacheBloqueado || !auth.currentUser) throw Object.assign(new Error('Entre novamente.'), { code:'cancelled' });
  return auth.currentUser;
}
async function reautenticar(senha){
  const u = usuarioOnline();
  await reauthenticateWithCredential(u, EmailAuthProvider.credential(u.email, senha));
  if(auth.currentUser?.uid !== u.uid) throw Object.assign(new Error('Sessão alterada.'), { code:'cancelled' });
  return u;
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
      { email:cred.user.email ?? email, criado: new Date().toISOString(), tz:Intl.DateTimeFormat().resolvedOptions().timeZone || 'America/Sao_Paulo', ...perfil });
    // onAuthStateChanged (e o watchDados que ele liga) pode disparar o primeiro
    // renderAjustes() antes deste setDoc terminar, deixando o cache de Ajustes
    // (por uid) preso em "sem nome". Avisa que o perfil mudou pra ele reler.
    window.dispatchEvent(new Event('perfil-alterado'));
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
    const u = auth.currentUser;
    if(!u) throw Object.assign(new Error('Entre na conta.'), { code:'offline' });
    await updateDoc(doc(db, 'perfis', u.uid), { nome, sobrenome: sobrenome ? sobrenome : deleteField() });
  },
  login: (email, senha) => cacheBloqueado
    ? Promise.reject(Object.assign(new Error('Limpe os dados locais antes de entrar.'), { code:'cache' }))
    : signInWithEmailAndPassword(auth, email, senha).then(()=>{}),
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
  async trocarSenha(atual, nova){
    const regra = window.OBRA_CADASTRO.validaSenha(nova, auth.currentUser?.email);
    if(!regra.ok) throw Object.assign(new Error(regra.erro), { code:'auth/weak-password' });
    const u = await reautenticar(atual);
    await updatePassword(u, nova);
  },
  async apagarConta(senha, confirmacao, opcoes){
    if(confirmacao !== 'APAGAR') throw Object.assign(new Error('Digite APAGAR para confirmar.'), { code:'confirmacao' });
    if(saindo) throw Object.assign(new Error('Operação em andamento.'), { code:'pendente' });
    const u = usuarioOnline();
    saindo = true;
    let dadosApagados = false;
    try{
      return await contaExclusiva(async()=>{
        await reautenticar(senha);
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
        try{ await deleteUser(u); }catch(err){ marcaCache(false); throw err; }
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

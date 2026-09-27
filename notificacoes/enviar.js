'use strict';
/* Resumo diário para todos os aparelhos: Web Push (subs) e FCM (tokens do app iOS).
   Dependências injetadas: roda igual no GitHub Actions, na Vercel e nos testes.
   Inscrição/token morto é removido; falha num aparelho não derruba o resto. */
const { montaResumo, endpointPushValido, estadoOrcamento } = require('./resumo.js');
const { hojeNoFuso } = require('./fuso.js');

const TOKEN_MORTO = new Set(['messaging/registration-token-not-registered', 'messaging/invalid-registration-token', 'messaging/invalid-argument']);

/* Compara a memória de avisos sem depender da ordem das chaves. */
function mesmoEstado(a, b){
  const lista = o => Object.keys(o || {}).sort().map(k => k + '=' + o[k]).join('|');
  return lista(a) === lista(b);
}

async function enviaTodos({ db, webpush, messaging, FieldPath, FieldValue, periodo, agora, log }){
  const r = { enviados: 0, removidos: 0 };
  const remove = async(pdoc, campo, chave, motivo) => {
    await pdoc.ref.update(new FieldPath(campo, chave), FieldValue.delete());
    r.removidos++;
    log.warn(pdoc.id + '/' + chave + ': ' + motivo + ', removido');
  };
  const pushDocs = await db.collection('push').get();
  log.info(pushDocs.size + ' usuario(s) com push; hoje = ' + hojeNoFuso(null, agora) + '; periodo = ' + periodo);

  for(const pdoc of pushDocs.docs){
    const uid = pdoc.id;
    const doc = pdoc.data() || {};
    const subs = doc.subs || {}, tokens = doc.tokens || {};
    if(!Object.keys(subs).length && !Object.keys(tokens).length) continue;

    const snap = await db.doc('dados/' + uid).get();
    const perfil = await db.doc('perfis/' + uid).get();
    const dados = snap.data();
    const pdados = perfil.data() || {};
    /* Memória dos avisos de orçamento (regra em resumo.js). Só com perfil
       existente: update nunca cria documento, e sem memória não há aviso
       (silêncio é melhor que repetir todo dia). */
    const temPerfil = perfil.exists === true;
    const memoria = pdados.avisosOrcamento;
    const anterior = temPerfil ? (memoria && typeof memoria === 'object' && !Array.isArray(memoria) ? memoria : {}) : null;
    const estado = temPerfil ? estadoOrcamento(dados) : null;
    const gravaMemoria = async()=>{
      if(!estado || mesmoEstado(estado, anterior)) return;
      try{ await perfil.ref.update({ avisosOrcamento: estado }); }
      catch(err){ log.error(uid + ': falha ao gravar avisos de orçamento ' + (err.code || err.message)); }
    };
    const resumo = montaResumo(dados, hojeNoFuso(pdados.tz, agora), periodo, anterior);
    if(!resumo){ await gravaMemoria(); log.info(uid + ': nada a dizer'); continue; }

    let entregues = 0;
    const payload = JSON.stringify(resumo);
    for(const [k, s] of Object.entries(subs)){
      if(!s || !endpointPushValido(s.endpoint)){ await remove(pdoc, 'subs', k, 'endpoint inválido'); continue; }
      try{
        await webpush.sendNotification({ endpoint: s.endpoint, keys: s.keys }, payload);
        r.enviados++; entregues++; log.info(uid + '/' + k + ': enviado');
      }catch(err){
        if(err.statusCode === 404 || err.statusCode === 410) await remove(pdoc, 'subs', k, 'inscricao morta');
        else log.error(uid + '/' + k + ': falha ' + (err.statusCode || err.message));
      }
    }

    for(const [k, t] of Object.entries(tokens)){
      const token = typeof t === 'string' ? t : t && t.token;
      if(!token){ await remove(pdoc, 'tokens', k, 'token inválido'); continue; }
      try{
        await messaging.send({
          token,
          notification: { title: resumo.titulo, body: resumo.corpo },
          data: resumo.obraId ? { obraId: resumo.obraId } : {},
          apns: { payload: { aps: { sound: 'default' } } },
        });
        r.enviados++; entregues++; log.info(uid + '/' + k + ': enviado (fcm)');
      }catch(err){
        if(TOKEN_MORTO.has(err.code)) await remove(pdoc, 'tokens', k, 'token morto');
        else log.error(uid + '/' + k + ': falha fcm ' + (err.code || err.message));
      }
    }
    if(entregues > 0) await gravaMemoria();
  }
  return r;
}

module.exports = { enviaTodos };

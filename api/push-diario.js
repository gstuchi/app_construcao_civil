'use strict';
/* Vercel Cron do resumo diário. Inerte até existir CRON_SECRET na Vercel:
   enquanto isso o GitHub Actions continua sendo o único disparo (ver notificacoes/README.md). */
const { timingSafeEqual } = require('node:crypto');

function carregarPadrao(){
  const webpush = require('web-push');
  const { enviaTodos } = require('../notificacoes/enviar.js');
  const { depsAdmin } = require('../notificacoes/admin.js');
  webpush.setVapidDetails(process.env.VAPID_SUBJECT, process.env.VAPID_PUBLIC, process.env.VAPID_PRIVATE);
  return { enviaTodos, deps: { ...depsAdmin(process.env.FIREBASE_SERVICE_ACCOUNT), webpush } };
}

function segredoConfere(recebido, esperado){
  const a = Buffer.from(String(recebido || '')), b = Buffer.from('Bearer ' + esperado);
  return a.length === b.length && timingSafeEqual(a, b);
}

function criarHandler(carregar = carregarPadrao, env = process.env){
  return async function handler(req, res){
    if(!env.CRON_SECRET) return res.status(503).json({ erro: 'cron desativado' });
    if(!segredoConfere(req.headers.authorization, env.CRON_SECRET)) return res.status(401).json({ erro: 'nao autorizado' });
    const periodo = req.query && req.query.periodo === 'manha' ? 'manha' : 'noite';
    try{
      const { enviaTodos, deps } = carregar();
      const r = await enviaTodos({ ...deps, periodo, agora: new Date(), log: console });
      return res.status(200).json(r);
    }catch(err){
      console.error(err);
      return res.status(500).json({ erro: 'falha no envio' });
    }
  };
}

module.exports = criarHandler();
module.exports.criarHandler = criarHandler;

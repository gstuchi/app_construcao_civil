'use strict';
/* Resumo das notificações push. Função pura: recebe o blob `dados` do
   Firestore, a data ISO de hoje (fuso America/Sao_Paulo) e o período do
   disparo, e devolve { titulo, corpo } ou null quando não há nada a dizer
   (aí não se envia).

   Período: 'manha' (9h) ou 'noite' (18h, o padrão). A única diferença é o
   lembrete de lançar — às 9h o dia ainda não aconteceu, então a pergunta
   seria idêntica toda manhã e o usuário acabaria desligando o push. */

const BRL = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

function endpointPushValido(endpoint){
  try{
    const u = new URL(endpoint);
    if(u.protocol !== 'https:' || u.username || u.password || (u.port && u.port !== '443')) return false;
    const h = u.hostname.toLowerCase();
    return h === 'fcm.googleapis.com'
      || h === 'web.push.apple.com'
      || h === 'push.services.mozilla.com'
      || h.endsWith('.push.services.mozilla.com')
      || h.endsWith('.notify.windows.com');
  }catch(err){
    return false;
  }
}

function montaResumo(dados, hojeISO, periodo){
  if(!dados || !Array.isArray(dados.obras) || !dados.obras.length) return null;
  const obras = dados.obras.filter(o => o && typeof o === 'object');
  const linhas = [];

  // afazeres não riscados, somando todas as obras (campo é opcional por obra)
  const pend = obras.reduce((s, o) => {
    const afazeres = Array.isArray(o.afazeres) ? o.afazeres : [];
    return s + afazeres.filter(a => a && typeof a === 'object' && !a.feito).length;
  }, 0);
  if(pend > 0) linhas.push(pend === 1 ? '1 afazer pendente' : pend + ' afazeres pendentes');

  // parcelas: só dia 1 — gastos com data dentro do mês corrente ainda não vencidos
  if(hojeISO.slice(8) === '01'){
    const mes = hojeISO.slice(0, 7);
    let qtd = 0, total = 0;
    for(const o of obras) for(const g of (Array.isArray(o.gastos) ? o.gastos : [])){
      if(g && typeof g.data === 'string' && g.data.slice(0, 7) === mes && g.data >= hojeISO){
        qtd++; total += Number(g.valor) || 0;
      }
    }
    if(qtd > 0) linhas.push((qtd === 1 ? '1 parcela vence' : qtd + ' parcelas vencem')
      + ' este mês (' + BRL.format(total) + ')');
  }

  // lembrete de lançar: só à noite, com obra em andamento e nada lançado hoje
  if(periodo !== 'manha'){
    const emObra = obras.some(o => o.fase === 'construcao');
    const lancouHoje = obras.some(o => (Array.isArray(o.gastos) ? o.gastos : [])
      .some(g => g && g.data === hojeISO));
    if(emObra && !lancouHoje) linhas.push('Lançou os gastos de hoje?');
  }

  if(!linhas.length) return null;
  return { titulo: 'Custta', corpo: linhas.join('\n') };
}

module.exports = { montaResumo, endpointPushValido };

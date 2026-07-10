'use strict';
/* Resumo diário das notificações push. Função pura: recebe o blob `dados`
   do Firestore e a data ISO de hoje (fuso America/Sao_Paulo) e devolve
   { titulo, corpo } ou null quando não há nada a dizer (aí não se envia). */

const BRL = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

function montaResumo(dados, hojeISO){
  if(!dados || !Array.isArray(dados.obras) || !dados.obras.length) return null;
  const obras = dados.obras;
  const linhas = [];

  // afazeres não riscados, somando todas as obras (campo é opcional por obra)
  const pend = obras.reduce((s, o) => s + (o.afazeres || []).filter(a => !a.feito).length, 0);
  if(pend > 0) linhas.push(pend === 1 ? '1 afazer pendente' : pend + ' afazeres pendentes');

  // parcelas: só dia 1 — gastos com data dentro do mês corrente ainda não vencidos
  if(hojeISO.slice(8) === '01'){
    const mes = hojeISO.slice(0, 7);
    let qtd = 0, total = 0;
    for(const o of obras) for(const g of (o.gastos || [])){
      if(g.data.slice(0, 7) === mes && g.data >= hojeISO){ qtd++; total += g.valor; }
    }
    if(qtd > 0) linhas.push((qtd === 1 ? '1 parcela vence' : qtd + ' parcelas vencem')
      + ' este mês (' + BRL.format(total) + ')');
  }

  // lembrete de lançar: só se há obra em andamento e nada foi lançado com data de hoje
  const emObra = obras.some(o => o.fase === 'construcao');
  const lancouHoje = obras.some(o => (o.gastos || []).some(g => g.data === hojeISO));
  if(emObra && !lancouHoje) linhas.push('Lançou os gastos de hoje?');

  if(!linhas.length) return null;
  return { titulo: 'Minhas Obras', corpo: linhas.join('\n') };
}

module.exports = { montaResumo };

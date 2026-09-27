'use strict';
/* Resumo das notificações push. Função pura: recebe o blob `dados` do
   Firestore, a data ISO de hoje (fuso America/Sao_Paulo), o período do
   disparo e a memória de orçamento (4º parâmetro), e devolve
   { titulo, corpo } ou null quando não há nada a dizer (aí não se envia).

   Período: 'manha' (9h) ou 'noite' (18h, o padrão). A única diferença é o
   lembrete de lançar — às 9h o dia ainda não aconteceu, então a pergunta
   seria idêntica toda manhã e o usuário acabaria desligando o push.

   `anterior` (4º parâmetro): memória de níveis de orçamento do último push
   (perfis/{uid}.avisosOrcamento, gravada pelo enviar.js). Ausente ou `null`
   = sem avisos de orçamento neste resumo. */

const BRL = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
const OBRA_CALC = require('../calc.js');
const { normaliza } = require('../dados.js');

/* ---- avisos de orçamento ----
   Regra de não repetir: cada item (obra × total, obra × tópico) tem nível
   ok < perto < passou. Só avisa quando o nível atual é MAIOR que o último
   avisado (memória em perfis/{uid}.avisosOrcamento, gravada pelo enviar.js).
   Mesmo nível → silêncio; descida → a memória desce e uma nova subida avisa. */
const NIVEL = { ok:0, perto:1, passou:2 };
const rank = v => typeof v === 'string' && Object.prototype.hasOwnProperty.call(NIVEL, v) ? NIVEL[v] : 0;
const MAX_FRASES_ORC = 3;

/* "R$ 8 mil", "R$ 1,5 mil", "R$ 1,25 mi" — cabe na notificação */
function curto(n){
  const a = Math.round(Math.abs(n) * 100) / 100;
  const fmt = (v, casas) => {
    const s = v.toFixed(casas).replace('.', ',');
    return s.includes(',') ? s.replace(/0+$/, '').replace(/,$/, '') : s;
  };
  if(a >= 1e6) return 'R$ ' + fmt(a / 1e6, a >= 1e7 ? 1 : 2) + ' mi';
  if(a >= 1000) return 'R$ ' + fmt(a / 1000, a >= 10000 ? 0 : 1) + ' mil';
  return 'R$ ' + a.toFixed(2).replace('.', ','); // espaço comum: BRL.format usa NBSP
}

function itensOrcamento(dados){
  const d = normaliza(dados);
  const nomes = Object.fromEntries([...OBRA_CALC.TOPICOS, ...d.config.topicosCustom].map(t => [t.id, t.nm]));
  const comOrc = d.obras.filter(o => o.fase !== 'vendida')
    .map(o => [o, OBRA_CALC.orcamentoObra(o)]).filter(([, r]) => r);
  const variasObras = comOrc.length > 1;
  const itens = [];
  for(const [o, r] of comOrc){
    itens.push({ chave:o.id + '|total', obraId:o.id, nivel:r.nivel, pct:r.pct, sobra:r.sobra, sujeito:o.nome, alvo:'orçamento' });
    for(const t of r.topicos){
      const nome = nomes[t.id] || t.id;
      itens.push({ chave:o.id + '|t:' + t.id, obraId:o.id, nivel:t.nivel, pct:t.pct, sobra:t.sobra,
        sujeito: variasObras ? nome + ' (' + o.nome + ')' : nome, alvo:'previsto' });
    }
  }
  return itens;
}

function estadoOrcamento(dados){
  const estado = {};
  for(const i of itensOrcamento(dados)) if(i.nivel !== 'ok') estado[i.chave] = i.nivel;
  return estado;
}

function avisosOrcamento(dados, anterior){
  if(!anterior || typeof anterior !== 'object') return { linhas:[], obraIds:[] };
  const novos = itensOrcamento(dados).filter(i => NIVEL[i.nivel] > rank(anterior[i.chave]));
  novos.sort((a, b) => NIVEL[b.nivel] - NIVEL[a.nivel]); // passou primeiro, se o limite cortar
  const linhas = novos.slice(0, MAX_FRASES_ORC).map(i => i.nivel === 'passou'
    ? i.sujeito + ' passou ' + curto(-i.sobra) + ' do ' + i.alvo
    : i.sujeito + ' chegou a ' + i.pct + '% do ' + i.alvo);
  const resto = novos.length - linhas.length;
  if(resto > 0) linhas.push(resto === 1 ? '+ 1 aviso de orçamento' : '+ ' + resto + ' avisos de orçamento');
  return { linhas, obraIds:[...new Set(novos.map(i => i.obraId))] };
}

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

function montaResumo(dados, hojeISO, periodo, anterior){
  if(!dados || !Array.isArray(dados.obras) || !dados.obras.length) return null;
  const obras = dados.obras.filter(o => o && typeof o === 'object');
  const linhas = [];
  const origem = new Set(); // obras que geraram alguma linha — uma só vira atalho no toque

  // avisos de orçamento primeiro: são a notícia mais importante do dia
  const orc = avisosOrcamento(dados, anterior);
  linhas.push(...orc.linhas);
  orc.obraIds.forEach(id => origem.add(id));

  // afazeres não riscados, somando todas as obras (campo é opcional por obra)
  const pend = obras.reduce((s, o) => {
    const afazeres = Array.isArray(o.afazeres) ? o.afazeres : [];
    const n = afazeres.filter(a => a && typeof a === 'object' && !a.feito).length;
    if(n) origem.add(o.id);
    return s + n;
  }, 0);
  if(pend > 0) linhas.push(pend === 1 ? '1 afazer pendente' : pend + ' afazeres pendentes');

  // parcelas: só dia 1 — gastos com data dentro do mês corrente ainda não vencidos
  if(hojeISO.slice(8) === '01'){
    const mes = hojeISO.slice(0, 7);
    let qtd = 0, total = 0;
    for(const o of obras) for(const g of (Array.isArray(o.gastos) ? o.gastos : [])){
      if(g && typeof g.data === 'string' && g.data.slice(0, 7) === mes && g.data >= hojeISO){
        qtd++; total += Number(g.valor) || 0; origem.add(o.id);
      }
    }
    if(qtd > 0) linhas.push((qtd === 1 ? '1 parcela vence' : qtd + ' parcelas vencem')
      + ' este mês (' + BRL.format(total) + ')');
  }

  // lembrete de lançar: só à noite, com obra em andamento e nada lançado hoje
  if(periodo !== 'manha'){
    const emObra = obras.filter(o => o.fase === 'construcao');
    const lancouHoje = obras.some(o => (Array.isArray(o.gastos) ? o.gastos : [])
      .some(g => g && g.data === hojeISO));
    if(emObra.length && !lancouHoje){
      linhas.push('Lançou os gastos de hoje?');
      emObra.forEach(o => origem.add(o.id));
    }
  }

  if(!linhas.length) return null;
  const resumo = { titulo: 'Custta', corpo: linhas.join('\n') };
  const [unica] = origem;
  if(origem.size === 1 && typeof unica === 'string') resumo.obraId = unica;
  return resumo;
}

module.exports = { montaResumo, endpointPushValido, estadoOrcamento, avisosOrcamento };

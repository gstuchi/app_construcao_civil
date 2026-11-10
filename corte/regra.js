'use strict';
/* Decisão pura do corte de gastos: recebe fatos, devolve o que fazer. Nada aqui toca rede,
   disco ou relógio. Limiares valem sobre custo = costAmount − base, em centavos, para a
   conta em reais não errar na fronteira (64,07 − 4,07 dá 59,99999999999999). */

const LIMITE_API = 6000; // R$ 60,00: desliga a API do Firestore
const LIMITE_COBRANCA = 10000; // R$ 100,00: tira a cobrança
const ESPERA_FALHA_MS = 6 * 60 * 60 * 1000; // falha de desligar que persiste tanto vira corte da cobrança

/* Mensagem que nunca vai dar certo: registra e não relança, para o Pub/Sub não repetir à toa. */
class MensagemIlegivel extends Error {}

const centavos = reais => Math.round(reais * 100);

function estadoNormal(lido){
  return { orcamentos: {}, primeiraFalha: null, apiDesligadaEm: null, cobrancaTiradaEm: null, ...(lido || {}) };
}

/* O início do período é o dia 1 num fuso qualquer (Pacífico, em geral): em UTC cai entre a véspera
   e o dia 1. Somar 15 h leva todos eles para dentro do mês certo. */
function intervaloDe(inicio){
  const t = Date.parse(inicio);
  return Number.isNaN(t) ? null : new Date(t + 15 * 3600 * 1000).toISOString().slice(0, 7);
}

function interpretarOrcamento(c){
  const intervalo = typeof c.costIntervalStart === 'string' ? intervaloDe(c.costIntervalStart) : null;
  if(typeof c.budgetDisplayName !== 'string' || !Number.isFinite(c.costAmount) || typeof c.currencyCode !== 'string' || !intervalo)
    throw new MensagemIlegivel('orçamento com campo faltando ou inválido');
  return { tipo: 'orcamento', nome: c.budgetDisplayName, custo: c.costAmount, moeda: c.currencyCode, intervalo };
}

function interpretarIncidente(inc){
  if(!inc || typeof inc.policy_name !== 'string' || typeof inc.state !== 'string')
    throw new MensagemIlegivel('incidente sem policy_name ou state');
  return { tipo: 'incidente', politica: inc.policy_name, estado: inc.state };
}

/* evento é o CloudEvent do Pub/Sub: data.message.data traz o JSON em base64. */
function interpretar(evento){
  const bruto = evento && evento.data && evento.data.message && evento.data.message.data;
  if(typeof bruto !== 'string' || !bruto) throw new MensagemIlegivel('mensagem sem dados');
  let corpo;
  try{
    corpo = JSON.parse(Buffer.from(bruto, 'base64').toString('utf8'));
  }catch{
    throw new MensagemIlegivel('dados que não são JSON');
  }
  if(corpo && typeof corpo === 'object' && !Array.isArray(corpo)){
    if(corpo.incident !== undefined) return interpretarIncidente(corpo.incident);
    if(corpo.budgetDisplayName !== undefined) return interpretarOrcamento(corpo);
  }
  throw new MensagemIlegivel('formato desconhecido');
}

/* Guarda a mensagem no estado. Devolve o mesmo objeto quando nada muda (nada a regravar).
   velha: true é o mês que já passou; custoCentavos é o custo que vale para os limiares.
   Virar o mês do projeto limpa a primeiraFalha: falha velha não pode encurtar as 6 horas
   do mês novo, porque o passo seguinte é irreversível. */
function aplicarOrcamento(estado, msg, papel){
  const atual = estado.orcamentos[msg.nome];
  if(atual && msg.intervalo < atual.intervalo) return { estado, velha: true };
  const virou = Boolean(atual) && msg.intervalo > atual.intervalo;
  const registro = !atual || virou ? { intervalo: msg.intervalo, base: 0, maiorCusto: 0 } : atual;
  const custoCentavos = centavos(msg.custo) - centavos(registro.base);
  const maiorCusto = Math.max(registro.maiorCusto, msg.custo);
  if(atual && !virou && maiorCusto === atual.maiorCusto) return { estado, custoCentavos };
  const novo = { ...estado, orcamentos: { ...estado.orcamentos, [msg.nome]: { ...registro, maiorCusto } } };
  if(virou && papel === 'projeto') novo.primeiraFalha = null;
  return { estado: novo, custoCentavos };
}

/* 'projeto' é o orçamento do projeto; 'fora' é o de todos os serviços menos o Firestore. */
function papelDoOrcamento(nome, config){
  if(nome === config.orcamentoProjeto) return 'projeto';
  if(nome === config.orcamentoFora) return 'fora';
  return null;
}

function decidirOrcamento(papel, custoCentavos){
  if(papel === 'fora') return custoCentavos >= LIMITE_COBRANCA ? 'tirar-cobranca' : 'nada';
  return custoCentavos >= LIMITE_API ? 'desligar-api' : 'nada';
}

/* A cobrança só sai pelo orçamento do projeto quando a API não ficou desligada: é o que o
   chamador prova (services.get) antes de perguntar. Aqui, o custo e o tempo da falha. */
function deveTirarCobrancaPorFalha(custoCentavos, primeiraFalha, agoraMs){
  return custoCentavos >= LIMITE_COBRANCA && Boolean(primeiraFalha) && agoraMs - Date.parse(primeiraFalha) >= ESPERA_FALHA_MS;
}

/* Os três registros devolvem o mesmo objeto quando nada muda: não há o que regravar. */
function registrarFalha(estado, agora){
  return estado.primeiraFalha ? estado : { ...estado, primeiraFalha: agora };
}

/* API confirmada desligada encerra a falha: a contagem só anda enquanto o estado real é ligada. */
function registrarApiDesligada(estado, agora){
  if(estado.apiDesligadaEm && !estado.primeiraFalha) return estado;
  return { ...estado, apiDesligadaEm: estado.apiDesligadaEm || agora, primeiraFalha: null };
}

function registrarCobrancaTirada(estado, agora){
  return estado.cobrancaTiradaEm ? estado : { ...estado, cobrancaTiradaEm: agora };
}

module.exports = {
  LIMITE_API, LIMITE_COBRANCA, ESPERA_FALHA_MS, MensagemIlegivel,
  estadoNormal, intervaloDe, interpretar, aplicarOrcamento, papelDoOrcamento, decidirOrcamento,
  deveTirarCobrancaPorFalha, registrarFalha, registrarApiDesligada, registrarCobrancaTirada,
};

'use strict';
/* Corte de gastos do Custta (Blindagem 4): Cloud Run function em projeto próprio que recebe do
   Pub/Sub os orçamentos e o alerta de leituras e age sobre o projeto de produção. A decisão é de
   regra.js; quem fala com o Google é google.js. Aqui só a ordem das coisas. */
const regra = require('./regra.js');

const FRAMEWORK = '@google-cloud/functions-framework';
const VOLTAS_CONFIRMA = 6;
const ESPERA_CONFIRMA_MS = 10000;

/* Dependências de corte/ só carregam quando a função roda: o teste da raiz não as instala. */
function carregarPadrao(env){
  const { GoogleAuth } = require('google-auth-library');
  const { criarGoogle } = require('./google.js');
  const cliente = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/cloud-platform'] });
  return criarGoogle({ cliente, projeto: env.PROJETO_ALVO, bucket: env.BUCKET_ESTADO });
}

function criarManipulador({
  carregar = carregarPadrao, env = process.env, agora = () => new Date(),
  escrever = linha => console.log(linha), esperar = ms => new Promise(r => setTimeout(r, ms)),
} = {}){
  const config = {
    armadoApi: env.ARMADO_API === 'true',
    armadoCobranca: env.ARMADO_COBRANCA === 'true',
    orcamentoProjeto: env.ORCAMENTO_PROJETO,
    orcamentoFora: env.ORCAMENTO_FORA_FIRESTORE,
    politica: env.POLITICA_ALERTA,
  };
  let memo = null;
  const google = () => (memo = memo || carregar(env));
  const logar = (severity, marca, message, extra) => escrever(JSON.stringify({ severity, message, marca, ...extra }));
  const acao = (message, extra) => logar('ALERT', 'corte-acao', message, extra);

  /* Depois do erro basta uma leitura: o pedido não foi aceito, nada vai mudar. Depois do sucesso,
     dá tempo à operação. Sem nenhuma leitura boa não há prova de nada: relança sem contar falha. */
  async function confirmarDesligada(voltas){
    let erroLeitura = null, viuLigada = false;
    for(let i = 0; i < voltas; i++){
      if(i > 0) await esperar(ESPERA_CONFIRMA_MS);
      try{
        if(await google().estadoDaApi() === 'DISABLED') return true;
        viuLigada = true;
      }catch(e){
        erroLeitura = e;
      }
    }
    if(!viuLigada) throw erroLeitura;
    return false;
  }

  /* O estado.json só é tocado depois do Google, para o bucket fora do ar não segurar o alerta. */
  async function desligarApi(contexto, iso){
    const g = google();
    if(await g.estadoDaApi() === 'DISABLED'){
      await g.atualizarEstado(e => regra.registrarApiDesligada(e, iso));
      return { fez: 'API já estava desligada' };
    }
    if(!config.armadoApi){
      acao('faria desligar a API do Firestore (ARMADO_API=false)', { acao: 'faria-desligar-api', ...contexto });
      return { fez: 'faria desligar a API' };
    }
    let erroDesligar = null;
    try{
      await g.desligarApi();
    }catch(e){
      erroDesligar = e;
    }
    /* Vale o estado real, nunca o código de erro: FAILED_PRECONDITION tanto pode ser "já desligada"
       quanto "tem serviço dependente". */
    if(await confirmarDesligada(erroDesligar ? 1 : VOLTAS_CONFIRMA)){
      await g.atualizarEstado(e => regra.registrarApiDesligada(e, iso));
      acao('API do Firestore desligada', { acao: 'desligar-api', ...contexto });
      return { fez: 'desligou a API' };
    }
    const estado = await g.atualizarEstado(e => regra.registrarFalha(e, iso));
    return {
      fez: 'não conseguiu desligar a API', falhou: true, estado,
      erro: erroDesligar || new Error('a API do Firestore continuou ligada depois do pedido de desligar'),
    };
  }

  /* resolvido: a produção parou de gastar, nada a repetir. */
  async function tirarCobranca(contexto, iso, motivo){
    const g = google();
    if(!await g.cobrancaLigada()){
      await g.atualizarEstado(e => regra.registrarCobrancaTirada(e, iso));
      return { fez: 'cobrança já estava tirada', resolvido: true };
    }
    if(!config.armadoCobranca){
      acao(`faria tirar a cobrança do projeto (ARMADO_COBRANCA=false): ${motivo}`, { acao: 'faria-tirar-cobranca', ...contexto });
      return { fez: 'faria tirar a cobrança', resolvido: false };
    }
    await g.tirarCobranca();
    await g.atualizarEstado(e => regra.registrarCobrancaTirada(e, iso));
    acao(`cobrança do projeto tirada: ${motivo}`, { acao: 'tirar-cobranca', ...contexto });
    return { fez: 'tirou a cobrança', resolvido: true };
  }

  async function tratarOrcamento(msg, passagem, instante){
    passagem.orcamento = msg.nome;
    const papel = regra.papelDoOrcamento(msg.nome, config);
    if(!papel){
      passagem.fez = 'ignorou orçamento desconhecido';
      logar('ERROR', 'corte-erro', `orçamento desconhecido: ${msg.nome}`, { orcamento: msg.nome });
      return;
    }
    if(msg.moeda !== 'BRL'){
      passagem.fez = 'só alarme: moeda diferente de BRL';
      logar('ALERT', 'corte-erro', `moeda diferente de BRL: ${msg.moeda}`, { orcamento: msg.nome, moeda: msg.moeda });
      return;
    }
    /* maiorCusto grava antes de agir: se a ação falhar, o religar ainda enxerga o custo. */
    let aplicado;
    await google().atualizarEstado(e => {
      aplicado = regra.aplicarOrcamento(e, msg, papel);
      return aplicado.estado;
    });
    if(aplicado.velha){
      passagem.fez = 'ignorou mês velho';
      return;
    }
    passagem.custo = aplicado.custoCentavos / 100;
    const contexto = { orcamento: msg.nome, custo: passagem.custo };
    const decisao = regra.decidirOrcamento(papel, aplicado.custoCentavos);
    if(decisao === 'nada') return;
    if(decisao === 'tirar-cobranca'){
      passagem.fez = (await tirarCobranca(contexto, instante.toISOString(), 'gasto fora do Firestore passou de R$ 100')).fez;
      return;
    }
    const r = await desligarApi(contexto, instante.toISOString());
    passagem.fez = r.fez;
    if(!r.falhou) return;
    if(regra.deveTirarCobrancaPorFalha(aplicado.custoCentavos, r.estado.primeiraFalha, instante.getTime())){
      const corte = await tirarCobranca(contexto, instante.toISOString(), 'a API não desligou em 6 horas de falha');
      passagem.fez = corte.fez;
      if(corte.resolvido) return;
    }
    throw r.erro;
  }

  async function tratarIncidente(msg, passagem, instante){
    passagem.politica = msg.politica;
    if(msg.estado !== 'open' || msg.politica !== config.politica) return;
    const r = await desligarApi({ politica: msg.politica }, instante.toISOString());
    passagem.fez = r.fez;
    if(r.falhou) throw r.erro;
  }

  return async function receber(evento){
    const passagem = { tipo: 'ilegivel', orcamento: null, custo: null, fez: 'nada' };
    try{
      let msg;
      try{
        msg = regra.interpretar(evento);
      }catch(e){
        if(!(e instanceof regra.MensagemIlegivel)) throw e;
        passagem.fez = 'ignorou mensagem ilegível';
        logar('ERROR', 'corte-erro', `mensagem ilegível: ${e.message}`, {});
        return;
      }
      passagem.tipo = msg.tipo;
      if(msg.tipo === 'incidente') await tratarIncidente(msg, passagem, agora());
      else await tratarOrcamento(msg, passagem, agora());
    }catch(e){
      /* Só a mensagem: o erro da biblioteca carrega a configuração do pedido, com o token. */
      logar('ERROR', 'corte-erro', `falha no corte: ${e.message}`, { orcamento: passagem.orcamento, custo: passagem.custo, fez: passagem.fez });
      throw e;
    }finally{
      logar('INFO', 'corte-passagem', 'mensagem recebida', passagem);
    }
  };
}

function registrarFuncao(framework, env = process.env){
  framework.cloudEvent('receber', criarManipulador({ env }));
}

/* Quem carrega este arquivo em produção é o próprio Functions Framework, que então existe.
   Sem ele instalado (teste da raiz), não há onde registrar. */
function frameworkInstalado(){
  try{
    require.resolve(FRAMEWORK);
    return true;
  }catch{
    return false;
  }
}
if(frameworkInstalado()) registrarFuncao(require(FRAMEWORK));

module.exports = { criarManipulador, registrarFuncao, carregarPadrao };

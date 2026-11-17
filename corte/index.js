'use strict';
/* Corte de gastos do Custta (Blindagem 4): Cloud Run function em projeto próprio que recebe do
   Pub/Sub os orçamentos e o alerta de leituras e age sobre o projeto de produção. A decisão é de
   regra.js; quem fala com o Google é google.js. Aqui só a ordem das coisas. */
const regra = require('./regra.js');

const FRAMEWORK = '@google-cloud/functions-framework';
const VOLTAS_CONFIRMA = 6;
const ESPERA_CONFIRMA_MS = 10000;
/* Prazo do modo oficial-alerta. A conferência da cobrança para de esperar 150 s depois da chegada da
   mensagem. Com cada pedido no prazo de 30 s do google.js, ela termina antes de 190 s (uma espera de
   10 s e uma leitura depois da última olhada no relógio), e a reserva pede o services.get e o
   disable antes de 220 s: o disable sai dentro dos 300 s do implantar.sh. Sem o teto, leituras
   lentas da cobrança comeriam o prazo antes da reserva, a cada repetição do Pub/Sub. */
const TETO_COBRANCA_MS = 150000;

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
    modo: regra.modoDoCorte(env.MODO_CORTE),
  };
  let memo = null;
  const google = () => (memo = memo || carregar(env));
  const logar = (severity, marca, message, extra) => escrever(JSON.stringify({ severity, message, marca, ...extra }));
  const acao = (message, extra) => logar('ALERT', 'corte-acao', message, extra);
  /* O corte pelo alerta diz na mensagem qual condição abriu; o do orçamento não tem condição. A
     reserva do modo oficial-alerta diz que é reserva e por quê, para o e-mail apontar a volta certa. */
  const pela = contexto => (contexto.condicao ? `: ${contexto.condicao}` : '');
  const naReserva = contexto => (contexto.reserva ? ` na reserva da cobrança (${contexto.reserva})` : '');

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
      acao(`faria desligar a API do Firestore${naReserva(contexto)} (ARMADO_API=false)${pela(contexto)}`, { acao: 'faria-desligar-api', ...contexto });
      return { fez: 'faria desligar a API', desarmada: true };
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
      acao(`API do Firestore desligada${naReserva(contexto)}${pela(contexto)}`, { acao: 'desligar-api', ...contexto });
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

  /* Como confirmarDesligada, para a cobrança: billingEnabled falso confirma. Leitura que falha não
     confirma; no modo oficial-alerta, sem confirmação entra a reserva. Para de esperar no teto. */
  async function confirmarCobrancaTirada(inicioMs){
    let viuLigada = false, erroLeitura = null;
    for(let i = 0; i < VOLTAS_CONFIRMA; i++){
      if(i > 0){
        if(agora().getTime() - inicioMs >= TETO_COBRANCA_MS) break;
        await esperar(ESPERA_CONFIRMA_MS);
      }
      try{
        if(!await google().cobrancaLigada()) return { tirada: true };
        viuLigada = true;
      }catch(e){
        erroLeitura = e;
      }
    }
    return { tirada: false, viuLigada, erroLeitura };
  }

  /* Modo oficial-alerta: a cobrança sai primeiro, e a API é a reserva. Com ARMADO_COBRANCA=false só
     registra, mesmo com a API armada: armar pela metade não pode virar a B calada. A reserva que
     desliga a API, ou que a acha já desligada, para o gasto; desarmada ou com falha, relança, para
     o Pub/Sub repetir. */
  async function tirarCobrancaComReserva(contexto, iso, motivo){
    const g = google();
    /* Leitura que falha antes do pedido: desarmada, relança sem tocar em nada; armada, tenta tirar e
       confere, como se estivesse ligada (pedir de novo, já tirada, não muda nada). */
    let ligada;
    try{
      ligada = await g.cobrancaLigada();
    }catch(e){
      if(!config.armadoCobranca) throw e;
      ligada = null;
    }
    if(ligada === false){
      await g.atualizarEstado(e => regra.registrarCobrancaConfirmada(e, iso));
      return { fez: 'cobrança já estava tirada' };
    }
    if(!config.armadoCobranca){
      acao(`faria tirar a cobrança do projeto (ARMADO_COBRANCA=false): ${motivo}`, { acao: 'faria-tirar-cobranca', ...contexto });
      return { fez: 'faria tirar a cobrança' };
    }
    let erroTirar = null;
    try{
      await g.tirarCobranca();
    }catch(e){
      erroTirar = e;
    }
    /* Vale o estado real, e depois do erro a conferência é inteira, não uma leitura só como no
       desligarApi: outra execução pode estar tirando a cobrança agora (o 2º open de um ataque), e uma
       reserva por engano derruba o app que este modo quer manter no gratuito. */
    const conferida = await confirmarCobrancaTirada(Date.parse(iso));
    if(conferida.tirada){
      /* O aviso sai antes de gravar: com o bucket fora, a repetição acha a cobrança já tirada e só
         registraria, e o "o corte agiu" nunca sairia. */
      acao(`cobrança do projeto tirada: ${motivo}`, { acao: 'tirar-cobranca', ...contexto });
      await g.atualizarEstado(e => regra.registrarCobrancaConfirmada(e, iso));
      return { fez: 'tirou a cobrança' };
    }
    const porque = erroTirar ? `erro ao tirar a cobrança: ${erroTirar.message}`
      : conferida.viuLigada ? 'a cobrança continuou ligada depois do pedido de tirar'
        : `a cobrança não pôde ser conferida depois do pedido de tirar: ${conferida.erroLeitura.message}`;
    const r = await desligarApi({ ...contexto, reserva: porque }, iso);
    const fez = `reserva: ${r.fez}`;
    if(r.falhou) return { fez, falhou: true, erro: r.erro };
    if(r.desarmada) return { fez, falhou: true, erro: erroTirar || new Error(porque) };
    return { fez };
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
    const decisao = regra.decidirOrcamento(papel, aplicado.custoCentavos, config.modo);
    if(decisao === 'nada') return;
    if(decisao === 'tirar-cobranca'){
      if(papel === 'projeto' && config.modo === 'oficial-alerta'){
        const r = await tirarCobrancaComReserva(contexto, instante.toISOString(), 'modo oficial-alerta: gasto do projeto chegou a R$ 60');
        passagem.fez = r.fez;
        if(r.falhou) throw r.erro;
        return;
      }
      const motivo = papel === 'fora' ? 'gasto fora do Firestore passou de R$ 100' : 'modo oficial: gasto do projeto chegou a R$ 60';
      passagem.fez = (await tirarCobranca(contexto, instante.toISOString(), motivo)).fez;
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
    const incidente = { politica: msg.politica, condicao: msg.condicao, valorObservado: msg.valorObservado, limiar: msg.limiar };
    Object.assign(passagem, incidente);
    if(msg.estado !== 'open') return;
    /* O canal é só do alerta de leituras: política com outro nome é configuração errada, e calar
       aqui desligaria o caminho rápido do corte sem ninguém saber. */
    if(msg.politica !== config.politica){
      passagem.fez = 'ignorou política desconhecida';
      logar('ERROR', 'corte-erro', `alerta de política desconhecida: ${msg.politica}`, { politica: msg.politica });
      return;
    }
    if(config.modo === 'oficial'){
      passagem.fez = 'só registrou o alerta: o modo oficial não age nele';
      return;
    }
    if(config.modo === 'oficial-alerta'){
      const r = await tirarCobrancaComReserva(incidente, instante.toISOString(), `alerta de leituras aberto${pela(incidente)}`);
      passagem.fez = r.fez;
      if(r.falhou) throw r.erro;
      return;
    }
    const r = await desligarApi(incidente, instante.toISOString());
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
      if(!config.modo){
        passagem.fez = 'não agiu: MODO_CORTE desconhecido';
        logar('ALERT', 'corte-erro', `MODO_CORTE desconhecido: ${env.MODO_CORTE}`, {});
        return;
      }
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

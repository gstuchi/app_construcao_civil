'use strict';
/* Adaptador REST das APIs do Google, sem decisão nenhuma. `cliente` é o GoogleAuth da
   google-auth-library (nos testes, um falso): request({ url, method, data, ... }). */
const { estadoNormal } = require('./regra.js');

const SERVICO = 'firestore.googleapis.com';
const TEMPO_LIMITE_MS = 30000;

/* Outra execução regravou o estado entre a leitura e a gravação (HTTP 412). */
class ConflitoDeEstado extends Error {}

const statusDe = erro => (erro && erro.response ? erro.response.status : undefined);

function criarGoogle({ cliente, projeto, bucket, objeto = 'estado.json' }){
  const urlApi = `https://serviceusage.googleapis.com/v1/projects/${projeto}/services/${SERVICO}`;
  const urlCobranca = `https://cloudbilling.googleapis.com/v1/projects/${projeto}/billingInfo`;
  const urlObjeto = `https://storage.googleapis.com/storage/v1/b/${bucket}/o/${encodeURIComponent(objeto)}`;
  const urlUpload = `https://storage.googleapis.com/upload/storage/v1/b/${bucket}/o?uploadType=media&name=${encodeURIComponent(objeto)}&ifGenerationMatch=`;
  const pedir = opcoes => cliente.request({ timeout: TEMPO_LIMITE_MS, ...opcoes });

  /* A geração vem antes do conteúdo: se o objeto mudar entre as duas leituras, a gravação
     condicionada recusa (412). Na ordem inversa, gravaria por cima de conteúdo que não leu. */
  async function lerEstado(){
    let meta;
    try{
      meta = await pedir({ url: `${urlObjeto}?fields=generation` });
    }catch(e){
      if(statusDe(e) === 404) return { estado: estadoNormal(null), geracao: '0' };
      throw e;
    }
    const conteudo = await pedir({ url: `${urlObjeto}?alt=media`, responseType: 'text' });
    return { estado: estadoNormal(JSON.parse(conteudo.data)), geracao: meta.data.generation };
  }

  async function gravarEstado(estado, geracao){
    try{
      await pedir({ url: urlUpload + geracao, method: 'POST', headers: { 'Content-Type': 'application/json' }, data: JSON.stringify(estado) });
    }catch(e){
      if(statusDe(e) === 412) throw new ConflitoDeEstado('estado.json mudou durante a gravação');
      throw e;
    }
  }

  return {
    async estadoDaApi(){
      return (await pedir({ url: urlApi })).data.state;
    },
    /* O Operation devolvido não interessa: quem prova o desligamento é o services.get. */
    async desligarApi(){
      await pedir({ url: `${urlApi}:disable`, method: 'POST', data: { disableDependentServices: false, checkIfServiceHasUsage: 'SKIP' } });
    },
    async cobrancaLigada(){
      return (await pedir({ url: urlCobranca })).data.billingEnabled === true;
    },
    async tirarCobranca(){
      await pedir({ url: urlCobranca, method: 'PUT', data: { billingAccountName: '' } });
    },
    /* Ler, transformar e regravar com ifGenerationMatch; conflito tenta uma vez de novo.
       transformar devolve o mesmo objeto quando não há o que regravar. */
    async atualizarEstado(transformar){
      for(let tentativa = 1; ; tentativa++){
        const { estado, geracao } = await lerEstado();
        const novo = transformar(estado);
        if(novo === estado) return estado;
        try{
          await gravarEstado(novo, geracao);
          return novo;
        }catch(e){
          if(!(e instanceof ConflitoDeEstado) || tentativa >= 2) throw e;
        }
      }
    },
  };
}

module.exports = { criarGoogle, ConflitoDeEstado };

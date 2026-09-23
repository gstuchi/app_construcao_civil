/* Regras do cadastro: senha, nome e "como conheceu".
   Puro, sem DOM — usado por auth.js, ui-confirm.js e cloud.js, e testado em node.
   As firestore.rules repetem os limites de tamanho e a lista de origens: mudou aqui, muda lá. */
(function(root){
  'use strict';
  const LIMITES_PERFIL = Object.freeze({nome:60, sobrenome:80, origemDetalhe:80});
  const ORIGENS = Object.freeze([
    {id:'instagram', nome:'Instagram'},
    {id:'indicacao', nome:'Indicação de alguém', detalhe:'Quem indicou? (opcional)'},
    {id:'google',    nome:'Pesquisa no Google'},
    {id:'tiktok',    nome:'TikTok'},
    {id:'youtube',   nome:'YouTube'},
    {id:'outro',     nome:'Outro', detalhe:'Onde? (opcional)'},
  ]);
  /* Lista curta de propósito: pega o óbvio que passaria nas outras regras. */
  const COMUNS = new Set(['senha123','senha1234','12345678a','123456789a','a12345678','abc12345','abcd1234',
    'qwerty123','password1','password123','custta123','obra1234','mudar123','brasil123','admin123']);
  const REGRAS_SENHA = Object.freeze([
    {id:'tamanho', texto:'8 caracteres ou mais'},
    {id:'letra',   texto:'Uma letra'},
    {id:'numero',  texto:'Um número'},
    {id:'email',   texto:'Diferente do e-mail'},
    {id:'comum',   texto:'Não é uma senha óbvia'},
  ]);
  const ERROS_SENHA = {tamanho:'Use pelo menos 8 caracteres.', letra:'Inclua pelo menos uma letra.',
    numero:'Inclua pelo menos um número.', email:'A senha não pode ser igual ao e-mail.',
    comum:'Essa senha é muito comum. Escolha outra.'};
  const str = v => typeof v === 'string' ? v : '';
  const limpa = v => str(v).trim().replace(/\s+/g,' ');

  function validaSenha(senha, email){
    const s = str(senha), chave = s.trim().toLowerCase(), e = str(email).trim().toLowerCase();
    const passa = {
      tamanho: s.length >= 8,
      letra:   /\p{L}/u.test(s),
      numero:  /\d/.test(s),
      email:   !(e && chave === e),
      comum:   !COMUNS.has(chave),
    };
    const regras = REGRAS_SENHA.map(r=>({...r, ok:passa[r.id]}));
    const falha = regras.find(r=>!r.ok);
    if(falha) return {ok:false, regras, erro:ERROS_SENHA[falha.id]};
    if(s.length > 128) return {ok:false, regras, erro:'Use no máximo 128 caracteres.'};
    return {ok:true, regras, erro:''};
  }

  const falhou = (campo, erro) => ({ok:false, campo, erro, perfil:null});
  function normalizaNome(d){
    const o = d && typeof d === 'object' ? d : {};
    const nome = limpa(o.nome), sobrenome = limpa(o.sobrenome);
    if(!nome) return falhou('nome','Digite seu nome.');
    if(nome.length < 2) return falhou('nome','O nome precisa de pelo menos 2 letras.');
    if(nome.length > LIMITES_PERFIL.nome) return falhou('nome','Use no máximo 60 caracteres no nome.');
    if(sobrenome.length > LIMITES_PERFIL.sobrenome) return falhou('sobrenome','Use no máximo 80 caracteres no sobrenome.');
    const perfil = {nome};
    if(sobrenome) perfil.sobrenome = sobrenome;
    return {ok:true, campo:'', erro:'', perfil};
  }
  function normalizaPerfil(d){
    const o = d && typeof d === 'object' ? d : {};
    const base = normalizaNome(o);
    if(!base.ok) return base;
    const origem = ORIGENS.find(x=>x.id === o.origem);
    if(!origem) return falhou('origem','Conte como conheceu o Custta.');
    const perfil = {...base.perfil, origem:origem.id};
    if(origem.detalhe){
      const detalhe = limpa(o.origemDetalhe);
      if(detalhe.length > LIMITES_PERFIL.origemDetalhe) return falhou('origemDetalhe','Use no máximo 80 caracteres.');
      if(detalhe) perfil.origemDetalhe = detalhe;
    }
    return {ok:true, campo:'', erro:'', perfil};
  }

  const api = {REGRAS_SENHA, validaSenha, ORIGENS, LIMITES_PERFIL, normalizaPerfil, normalizaNome};
  if(typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.OBRA_CADASTRO = api;
})(typeof window !== 'undefined' ? window : globalThis);

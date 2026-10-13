/* Validação do documento compartilhado entre versões web e nativas.
   Campos desconhecidos são preservados; entradas inválidas não chegam à UI.
   Limites de texto se aplicam à edição, nunca truncam registros existentes. */
(function(root){
  'use strict';
  const LIMITES = Object.freeze({nome:120, descricao:500, topico:80, afazer:500});
  const objeto = v => v !== null && typeof v === 'object' && !Array.isArray(v);
  const texto = v => typeof v === 'string' ? v : typeof v === 'number' && Number.isFinite(v) ? String(v) : '';
  const numero = v => (typeof v === 'number' || typeof v === 'string' && v.trim() !== '') && Number.isFinite(Number(v)) ? Number(v) : null;
  const positivo = v => numero(v) !== null && numero(v) >= 0 ? numero(v) : null;
  const data = v => {
    if(typeof v !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(v)) return false;
    const d = new Date(v+'T00:00:00Z');
    return Number.isFinite(d.getTime()) && d.toISOString().slice(0,10) === v;
  };
  const lista = (v, fn) => Array.isArray(v) ? v.filter(objeto).map(fn).filter(Boolean) : [];
  /* Orçamento previsto (opcional): só o total, ou valor por tópico. Inválido ou
     vazio some — a obra sem orçamento fica exatamente como era, sem chave nova. */
  const MAX_TOPICOS_ORC = 100;
  function orcamento(v){
    if(!objeto(v)) return null;
    const maior = x => numero(x) !== null && numero(x) > 0 ? numero(x) : null;
    if(v.modo === 'topicos'){
      const origem = objeto(v.topicos) ? v.topicos : {};
      const topicos = {};
      for(const [id, valor] of Object.entries(origem)){
        if(Object.keys(topicos).length >= MAX_TOPICOS_ORC) break;
        if(id.trim() && id.length <= LIMITES.topico && maior(valor) !== null) topicos[id] = maior(valor);
      }
      if(!Object.keys(topicos).length) return null;
      const r = {...v, modo:'topicos', topicos};
      delete r.total;
      return r;
    }
    const total = maior(v.total);
    if(total === null) return null;
    const r = {...v, modo:'total', total};
    delete r.topicos;
    return r;
  }
  function gasto(g){
    if(!texto(g.id) || !data(g.data) || positivo(g.valor) === null) return null;
    const r = {...g, id:texto(g.id), data:g.data, valor:positivo(g.valor), topico:texto(g.topico)||'outros', descricao:texto(g.descricao), pagamento:texto(g.pagamento)||'pix'};
    if(g.grupoId || g.parcela){
      if(objeto(g.parcela) && Number.isInteger(numero(g.parcela.n)) && Number.isInteger(numero(g.parcela.de)) && numero(g.parcela.n)>0 && numero(g.parcela.de)>=numero(g.parcela.n)){
        r.grupoId=texto(g.grupoId); r.parcela={...g.parcela,n:numero(g.parcela.n),de:numero(g.parcela.de)};
      }else{ delete r.grupoId; delete r.parcela; }
    }
    return r;
  }
  function obra(o){
    if(!texto(o.id) || !data(o.dataInicio)) return null;
    const venda = objeto(o.venda) && data(o.venda.data) && positivo(o.venda.valor)!==null ? {...o.venda,valor:positivo(o.venda.valor)} : null;
    const r = {...o, id:texto(o.id), nome:texto(o.nome)||'Obra sem nome',
      fase:['construcao','pronta','vendida'].includes(o.fase) && (o.fase!=='vendida'||venda) ? o.fase : 'construcao',
      venda, valorEstimadoVenda:positivo(o.valorEstimadoVenda), areaM2:positivo(o.areaM2),
      gastos:lista(o.gastos,gasto), afazeres:lista(o.afazeres,a=>texto(a.id)?{...a,id:texto(a.id),texto:texto(a.texto),feito:a.feito===true}:null)};
    const orc = orcamento(o.orcamento);
    if(orc) r.orcamento = orc; else delete r.orcamento;
    return r;
  }
  function normaliza(d){
    const origem=objeto(d)?d:{}, config=objeto(origem.config)?origem.config:{};
    const taxa=numero(config.taxaMensal);
    return {...origem, obras:lista(origem.obras,obra), config:{...config,
      taxaMensal:taxa>0&&taxa<=20?taxa:1,
      topicosCustom:lista(config.topicosCustom,t=>texto(t.id)&&texto(t.nm)?{...t,id:texto(t.id),nm:texto(t.nm),ic:texto(t.ic)||'etiqueta'}:null)}};
  }
  /* ---- o que o formulário do gasto grava (app.js formGasto) ----
     O calc.js carrega antes deste arquivo no navegador; no Node vem pelo require. */
  const calc = () => root.OBRA_CALC || require('./calc.js');
  /* "Salvar" do gasto, na ordem do formulário. entrada: {valor, topico, descricao, data, pagamento, parcelas,
     juros} como a tela leu (valor em reais, descrição aparada, parcelas inteiras e juros pelo lerTaxaCartao);
     editado: o gasto em edição ou null; hoje: AAAA-MM-DD. Erro: {erro:'valor'} (a tela volta ao valor),
     {erro:'descricao', mensagem} ou {erro:'cartao', mensagem}. Certo: {valor, data, parcelas, cartao}, com o
     valor que vai para o documento (no cartão, o total com juros) e a data (no cartão, o primeiro vencimento). */
  function conferirGasto(entrada, editado, hoje){
    const valor=entrada.valor;
    if(!Number.isFinite(valor) || valor<=0) return {erro:'valor'};
    if(entrada.descricao.length>LIMITES.descricao) return {erro:'descricao', mensagem:`Use até ${LIMITES.descricao} caracteres.`};
    const data=entrada.data || (editado ? editado.data : hoje);
    const parcelas=!(editado && editado.grupoId) && entrada.pagamento==='cartao' ? entrada.parcelas||1 : 1;
    const cartao=!editado && entrada.pagamento==='cartao' ? calc().parcelamentoCartao(valor, entrada.parcelas, entrada.juros, data) : null;
    if(!editado && entrada.pagamento==='cartao' && !cartao) return {erro:'cartao', mensagem:'Confira valor, parcelas, data e taxa de juros'};
    return {valor:cartao ? cartao.totalCompra : valor, data, parcelas, cartao};
  }
  /* Os gastos de um lançamento novo: no cartão parcelado, um por parcela, com o mesmo grupoId (o primeiro id
     pedido) e parcela {n, de}; no cartão, as condições da compra em jurosCartao; senão, um gasto só. */
  function gastosLancados(entrada, conferido, novoId){
    const c=conferido.cartao;
    const dadosCartao=c ? {jurosCartao:{taxaMensal:c.taxaMensal, valorCompra:c.valorCompra, nParcelas:c.nParcelas,
      totalCompra:c.totalCompra, jurosCompra:c.jurosCompra}} : {};
    if(conferido.parcelas>1){
      const grupoId=novoId();
      return c.parcelas.map((p,i)=>({id:novoId(), valor:p.valor, topico:entrada.topico, descricao:entrada.descricao,
        data:p.data, pagamento:'cartao', grupoId, parcela:{n:i+1, de:conferido.parcelas}, ...dadosCartao}));
    }
    return [{id:novoId(), valor:conferido.valor, topico:entrada.topico, descricao:entrada.descricao, data:conferido.data,
      pagamento:entrada.pagamento, ...dadosCartao}];
  }
  /* O gasto editado: valor, tópico, descrição e data; o pagamento só fora de uma compra parcelada; fora do
     cartão, sem jurosCartao. Os outros campos, inclusive os que o app não conhece, ficam como estavam. */
  function gastoEditado(gasto, entrada, conferido){
    const g={...gasto, valor:conferido.valor, topico:entrada.topico, descricao:entrada.descricao, data:conferido.data};
    if(!gasto.grupoId) g.pagamento=entrada.pagamento;
    if(entrada.pagamento!=='cartao') delete g.jurosCartao;
    return g;
  }
  /* ---- o que os formulários da obra gravam (app.js formNovaObra, formEditarObra e formVenda) ---- */
  /* Teto de obras por conta, o mesmo das firestore.rules (d.obras.size() <= 300). Com ele cheio, "Nova obra" avisa em
     vez de abrir: a obra a mais faria toda gravação seguinte ser recusada até apagar uma. */
  const LIMITE_OBRAS = 300;
  function avisoLimiteDeObras(quantidade){
    return quantidade>=LIMITE_OBRAS ? {titulo:`Limite de ${LIMITE_OBRAS} obras`, texto:'Apague uma obra antiga para criar outra.'} : null;
  }
  /* "Criar obra" e "Salvar" da obra, na ordem do formulário. campos: {nome (aparado), dataInicio, valorEstimadoVenda,
     areaM2, orcamento}, com os valores lidos pelo parseNum (0 quando vazios). Erro: {erro:'nome'} (vazio: a tela volta
     ao nome), {erro:'nome', mensagem} ou, só na obra nova, {erro:'area', mensagem}; certo: null. */
  function conferirObra(campos, nova){
    if(!campos.nome) return {erro:'nome'};
    if(campos.nome.length>LIMITES.nome) return {erro:'nome', mensagem:`Use até ${LIMITES.nome} caracteres.`};
    if(nova && !(campos.areaM2>0)) return {erro:'area', mensagem:'Informe área construída maior que zero.'};
    return null;
  }
  /* A obra nova: em construção e sem gastos; valor estimado e orçamento total só quando maiores que zero. */
  function obraNova(campos, id, hoje){
    const o={id, nome:campos.nome, fase:'construcao', dataInicio:campos.dataInicio||hoje,
      valorEstimadoVenda:campos.valorEstimadoVenda>0?campos.valorEstimadoVenda:null, areaM2:campos.areaM2, gastos:[]};
    if(campos.orcamento>0) o.orcamento={modo:'total', total:campos.orcamento};
    return o;
  }
  /* A obra editada: nome, início (vazio fica o antigo), valor estimado e área (zero ou vazio viram null). O resto fica. */
  function obraEditada(obra, campos){
    return {...obra, nome:campos.nome, dataInicio:campos.dataInicio||obra.dataInicio,
      valorEstimadoVenda:campos.valorEstimadoVenda>0?campos.valorEstimadoVenda:null, areaM2:campos.areaM2>0?campos.areaM2:null};
  }
  /* "Confirmar venda": valor maior que zero e data entre o início da obra e hoje. Erro: {erro:'valor'} (a tela volta ao
     valor) ou {erro:'data', mensagem}; certo: null. */
  function conferirVenda(valor, data, dataInicio, hoje){
    if(valor<=0) return {erro:'valor'};
    const C=calc();
    if(!C.dataIgualOuDepois(data, dataInicio) || !C.dataIgualOuDepois(hoje, data))
      return {erro:'data', mensagem:'Data da venda precisa ficar entre o início da obra e hoje'};
    return null;
  }
  const api={normaliza,LIMITES,conferirGasto,gastosLancados,gastoEditado,LIMITE_OBRAS,avisoLimiteDeObras,conferirObra,obraNova,obraEditada,conferirVenda};
  if(typeof module !== 'undefined' && module.exports) module.exports=api;
  else root.OBRA_DADOS=api;
})(typeof window !== 'undefined' ? window : globalThis);

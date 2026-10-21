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
    /* o cartão lê a data crua, como a prévia do formulário (atualizarCartao): a data vazia não vira hoje, é recusada */
    const cartao=!editado && entrada.pagamento==='cartao' ? calc().parcelamentoCartao(valor, entrada.parcelas, entrada.juros, entrada.data) : null;
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
  /* ---- o que a folha do orçamento grava (app.js formOrcamento) ----
     "Salvar", só o modo ativo. antigo: o orçamento da obra no momento do Salvar (não o da abertura da folha); modo: 'total' ou
     'topicos'; total: o total lido pelo parseNum; valores: {idDoTópico: valor lido} de todas as linhas da folha. No total, só
     maior que zero; por tópico, só os valores maiores que zero. O que a folha não mostra fica: os campos desconhecidos do orçamento
     e, por tópico, o previsto de tópico sem linha na folha (tópico próprio apagado). Nada a gravar: null, e a chave sai da obra.
     Não corta em 100 tópicos como a leitura: o corte escolhe pela ordem de inserção, que o Firestore do app não guarda. */
  function orcamentoGravado(antigo, modo, total, valores){
    const resto = {};
    if(objeto(antigo)) for(const [k, v] of Object.entries(antigo)) if(!['modo', 'total', 'topicos'].includes(k)) resto[k] = v;
    if(modo === 'total') return total > 0 ? {...resto, modo:'total', total} : null;
    const topicos = {};
    for(const [id, v] of Object.entries(valores)) if(v > 0) topicos[id] = v;
    if(!Object.keys(topicos).length) return null;
    const antes = objeto(antigo) && objeto(antigo.topicos) ? antigo.topicos : {};
    for(const [id, v] of Object.entries(antes)) if(!Object.prototype.hasOwnProperty.call(valores, id)) topicos[id] = v;
    return {...resto, modo:'topicos', topicos};
  }
  /* ---- afazeres (app.js addAfazer e afazerRow) ----
     "Adicionar": o texto aparado; vazio não faz nada; até LIMITES.afazer unidades. O novo entra no começo da lista, pendente.
     Marcar e desmarcar trocam o feito e levam o afazer ao começo: com a lista mostrada em pendentes e depois feitos, cada grupo
     na ordem da lista (calc.js afazeresEmOrdem), o recém-marcado fica no alto dos feitos e o desmarcado volta ao alto dos
     pendentes. Apagar não pergunta. Os campos desconhecidos de cada afazer ficam. Lista ausente conta como vazia; id que sumiu
     (apagado em outro aparelho) devolve null: nada a gravar. */
  function conferirAfazer(texto){
    const t = texto.trim();
    if(!t) return {erro:'vazio'};
    if(t.length>LIMITES.afazer) return {erro:'afazer', mensagem:`Use até ${LIMITES.afazer} caracteres.`};
    return {texto:t};
  }
  const afazeresDaLista = l => Array.isArray(l) ? l : [];
  function afazeresComNovo(lista, texto, id){
    return [{id, texto, feito:false}, ...afazeresDaLista(lista)];
  }
  function afazeresAlternado(lista, id){
    const l = afazeresDaLista(lista), i = l.findIndex(a => a.id === id);
    if(i < 0) return null;
    return [{...l[i], feito:l[i].feito !== true}, ...l.slice(0, i), ...l.slice(i + 1)];
  }
  function afazeresSem(lista, id){
    const l = afazeresDaLista(lista);
    return l.some(a => a.id === id) ? l.filter(a => a.id !== id) : null;
  }
  const api={normaliza,LIMITES,conferirGasto,gastosLancados,gastoEditado,LIMITE_OBRAS,avisoLimiteDeObras,conferirObra,obraNova,obraEditada,conferirVenda,orcamentoGravado,conferirAfazer,afazeresComNovo,afazeresAlternado,afazeresSem};
  if(typeof module !== 'undefined' && module.exports) module.exports=api;
  else root.OBRA_DADOS=api;
})(typeof window !== 'undefined' ? window : globalThis);

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
    return {...o, id:texto(o.id), nome:texto(o.nome)||'Obra sem nome',
      fase:['construcao','pronta','vendida'].includes(o.fase) && (o.fase!=='vendida'||venda) ? o.fase : 'construcao',
      venda, valorEstimadoVenda:positivo(o.valorEstimadoVenda), areaM2:positivo(o.areaM2),
      gastos:lista(o.gastos,gasto), afazeres:lista(o.afazeres,a=>texto(a.id)?{...a,id:texto(a.id),texto:texto(a.texto),feito:a.feito===true}:null)};
  }
  function normaliza(d){
    const origem=objeto(d)?d:{}, config=objeto(origem.config)?origem.config:{};
    const taxa=numero(config.taxaMensal);
    return {...origem, obras:lista(origem.obras,obra), config:{...config,
      taxaMensal:taxa>0&&taxa<=20?taxa:1,
      topicosCustom:lista(config.topicosCustom,t=>texto(t.id)&&texto(t.nm)?{...t,id:texto(t.id),nm:texto(t.nm),ic:texto(t.ic)||'etiqueta'}:null)}};
  }
  const api={normaliza,LIMITES};
  if(typeof module !== 'undefined' && module.exports) module.exports=api;
  else root.OBRA_DADOS=api;
})(typeof window !== 'undefined' ? window : globalThis);

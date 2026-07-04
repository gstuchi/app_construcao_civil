/* Cálculos puros de obra — sem DOM. Carregado no browser (global OBRA_CALC)
   e nos testes em Node (module.exports). */
'use strict';
(function(root){
  const DIAS_MES = 30.44;
  const MS_DIA = 86400000;

  function diasEntre(deISO, ateISO){
    const de = new Date(deISO + 'T00:00:00');
    const ate = new Date(ateISO + 'T00:00:00');
    return Math.max(0, Math.round((ate - de) / MS_DIA));
  }
  function corrigido(valor, dataISO, ateISO, taxaPct){
    return valor * Math.pow(1 + taxaPct / 100, diasEntre(dataISO, ateISO) / DIAS_MES);
  }
  function fimCorrecao(obra, hojeISO){
    return (obra.venda && obra.venda.data) || hojeISO;
  }
  function totalBruto(obra){
    return obra.gastos.reduce((s, g) => s + g.valor, 0);
  }
  function totalCorrigido(obra, taxaPct, hojeISO){
    const fim = fimCorrecao(obra, hojeISO);
    return obra.gastos.reduce((s, g) => s + corrigido(g.valor, g.data, fim, taxaPct), 0);
  }
  function lucroVenda(obra, taxaPct){
    if(!obra.venda) return null;
    return {
      bruto:   obra.venda.valor - totalBruto(obra),
      vsBanco: obra.venda.valor - totalCorrigido(obra, taxaPct, obra.venda.data),
    };
  }
  function mesesDeObra(obra, hojeISO){
    return diasEntre(obra.dataInicio, fimCorrecao(obra, hojeISO)) / DIAS_MES;
  }

  /* % ao mês composto equivalente: quanto o dinheiro "rendeu" por mês
     ao transformar custoBruto em venda ao longo de N meses. */
  function taxaEquivalenteMensal(venda, custoBruto, meses){
    if(venda <= 0 || custoBruto <= 0 || meses <= 0) return null;
    return (Math.pow(venda / custoBruto, 1 / meses) - 1) * 100;
  }

  const api = { DIAS_MES, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, taxaEquivalenteMensal };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.OBRA_CALC = api;
})(this);

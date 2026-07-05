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

  /* Soma meses a uma data ISO; dia inexistente clampa no último dia do mês
     (31/01 + 1 mês = 28 ou 29/02). */
  function addMesesClampado(dataISO, meses){
    const [y, m, d] = dataISO.split('-').map(Number);
    const tot = (m - 1) + meses;
    const ano = y + Math.floor(tot / 12);
    const mes = tot % 12; // 0-based
    const ultimo = new Date(ano, mes + 1, 0).getDate();
    const dia = Math.min(d, ultimo);
    return ano + '-' + String(mes + 1).padStart(2, '0') + '-' + String(dia).padStart(2, '0');
  }

  /* Divide total em n parcelas mensais a partir de dataISO.
     Conta em centavos; a diferença de arredondamento fica na última. */
  function gerarParcelas(total, n, dataISO){
    const cents = Math.round(total * 100);
    const base = Math.floor(cents / n);
    return Array.from({length: n}, (_, i) => ({
      valor: (i === n - 1 ? cents - base * (n - 1) : base) / 100,
      data: addMesesClampado(dataISO, i),
    }));
  }

  const api = { DIAS_MES, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, taxaEquivalenteMensal, addMesesClampado, gerarParcelas };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.OBRA_CALC = api;
})(this);

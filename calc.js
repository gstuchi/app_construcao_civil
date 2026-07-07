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

  /* Conta da venda numa base de custo (bruto OU corrigido):
     lucro em R$, % sobre o custo, % sobre a venda, % ao mês composto. */
  function resumoVenda(venda, custo, meses){
    if(venda <= 0 || custo <= 0)
      return { lucro:null, pctCusto:null, pctVenda:null, taxaMes:null };
    return {
      lucro: venda - custo,
      pctCusto: (venda / custo - 1) * 100,
      pctVenda: (venda - custo) / venda * 100,
      taxaMes: taxaEquivalenteMensal(venda, custo, meses),
    };
  }

  /* Série mensal acumulada da obra (pro gráfico de evolução):
     um ponto por mês-calendário, do 1º gasto até o fim da correção
     (hoje ou a venda), cortando no fim de cada mês. Máx 24 últimos. */
  function serieEvolucao(obra, taxaPct, hojeISO){
    if(!obra.gastos.length) return [];
    const fim = fimCorrecao(obra, hojeISO);
    const gs = [...obra.gastos].sort((a, b) => a.data.localeCompare(b.data));
    const ini = gs[0].data.slice(0, 7);
    const ultimo = fim.slice(0, 7) > ini ? fim.slice(0, 7) : ini;
    const meses = [];
    let [y, m] = ini.split('-').map(Number);
    for(let guard = 0; guard < 600; guard++){
      const key = y + '-' + String(m).padStart(2, '0');
      meses.push(key);
      if(key === ultimo) break;
      m++; if(m > 12){ m = 1; y++; }
    }
    return meses.map(mes => {
      const ultimoDia = new Date(Number(mes.slice(0, 4)), Number(mes.slice(5, 7)), 0).getDate();
      let corte = mes + '-' + String(ultimoDia).padStart(2, '0');
      if(corte > fim) corte = fim;
      const ate = gs.filter(g => g.data <= corte);
      return {
        mes,
        bruto: ate.reduce((s, g) => s + g.valor, 0),
        corrigido: ate.reduce((s, g) => s + corrigido(g.valor, g.data, corte, taxaPct), 0),
      };
    }).slice(-24);
  }

  /* Série agregada de todas as obras: união dos meses; cada obra contribui
     com o acumulado dela no corte do mês (vendida fica congelada). */
  function serieEvolucaoAgregada(obras, taxaPct, hojeISO){
    const series = obras.map(o => serieEvolucao(o, taxaPct, hojeISO)).filter(s => s.length);
    if(!series.length) return [];
    const meses = [...new Set(series.flat().map(p => p.mes))].sort();
    return meses.map(mes => {
      let bruto = 0, corr = 0;
      series.forEach(s => {
        let p = null;
        for(const q of s){ if(q.mes <= mes) p = q; else break; }
        if(p){ bruto += p.bruto; corr += p.corrigido; }
      });
      return { mes, bruto, corrigido: corr };
    }).slice(-24);
  }

  /* Gastos com vencimento nos próximos `dias` (parcelas a vencer). */
  function aPagar(obras, hojeISO, dias = 30){
    const fim = new Date(hojeISO + 'T00:00:00');
    fim.setDate(fim.getDate() + dias);
    const limISO = fim.toISOString().slice(0, 10);
    let total = 0, qtd = 0;
    obras.forEach(o => o.gastos.forEach(g => {
      if(g.data > hojeISO && g.data <= limISO){ total += g.valor; qtd++; }
    }));
    return { total, qtd };
  }

  /* Últimos n gastos de todas as obras (data desc, desempate por id). */
  function gastosRecentes(obras, n = 5){
    return obras
      .flatMap(o => o.gastos.map(g => ({ obraId: o.id, obraNome: o.nome, gasto: g })))
      .sort((a, b) => (b.gasto.data + b.gasto.id).localeCompare(a.gasto.data + a.gasto.id))
      .slice(0, n);
  }

  function precoPorM2(valor, areaM2){
    return (valor > 0 && areaM2 > 0) ? valor / areaM2 : null;
  }

  /* Busca dos lançamentos: texto (descrição OU nome do tópico, sem acento)
     e/ou mês ('2026-06'). Filtros combinam em E. */
  function semAcento(s){
    return (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
  }
  function filtraGastos(gastos, topicosMap, f){
    const texto = semAcento(f && f.texto);
    const mes = (f && f.mes) || '';
    return gastos.filter(g => {
      if(mes && g.data.slice(0, 7) !== mes) return false;
      if(!texto) return true;
      const top = topicosMap[g.topico];
      return semAcento(g.descricao).includes(texto)
          || semAcento(top ? top.nm : g.topico).includes(texto);
    });
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

  /* ---- dinheiro digitado (máscara dos campos R$) ---- */
  /* Formata enquanto digita: só dígitos e 1 vírgula; milhar com pontos. */
  function fmtDigitado(v){
    v = (v == null ? '' : String(v)).replace(/[^\d,]/g, '');
    const i = v.indexOf(',');
    let int = (i < 0 ? v : v.slice(0, i)).replace(/^0+(?=\d)/, '');
    const cent = i < 0 ? null : v.slice(i + 1).replace(/,/g, '').slice(0, 2);
    if(!int && cent === null) return '';
    int = (int || '0').replace(/\B(?=(\d{3})+(?!\d))/g, '.');
    return cent === null ? int : int + ',' + cent;
  }
  /* No blur: completa os centavos (2.000.000 -> 2.000.000,00). */
  function fmtCompleto(v){
    v = fmtDigitado(v);
    if(!v) return '';
    const [int, cent = ''] = v.split(',');
    return int + ',' + (cent + '00').slice(0, 2);
  }
  /* Número salvo -> texto do campo já formatado. */
  function numParaCampo(n){
    return (n == null || n === '') ? '' : fmtCompleto(String(n).replace('.', ','));
  }
  /* Texto de campo -> número. Com vírgula, pontos são milhar; sem vírgula,
     remove só pontos em posição de milhar (o campo ao vivo do simulador),
     preservando decimais tipo "1.5" na taxa. */
  function parseNum(v){
    if(typeof v === 'number') return v;
    v = (v || '').toString().trim().replace(/[^\d,.-]/g, '');
    if(v.includes(',')) v = v.replace(/\./g, '').replace(',', '.');
    else v = v.replace(/\.(?=\d{3}(\.|$))/g, '');
    const n = parseFloat(v); return isNaN(n) ? 0 : n;
  }

  const api = { DIAS_MES, diasEntre, corrigido, totalBruto, totalCorrigido, lucroVenda, mesesDeObra, taxaEquivalenteMensal, resumoVenda, serieEvolucao, serieEvolucaoAgregada, aPagar, gastosRecentes, precoPorM2, filtraGastos, semAcento, addMesesClampado, gerarParcelas, fmtDigitado, fmtCompleto, numParaCampo, parseNum };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.OBRA_CALC = api;
})(this);

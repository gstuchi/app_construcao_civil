/* Exportação: share sheet nativo no app iOS; Web Share ou download na web. */
'use strict';
(function(root){
  function celula(valor){
    let texto = String(valor ?? '');
    // Evita executar conteúdo digitado pelo usuário como fórmula em planilhas.
    if(/^[\s\u0000-\u001f]*[=+@-]/.test(texto)) texto = "'" + texto;
    return '"' + texto.replace(/"/g, '""') + '"';
  }
  function csv(dados){
    const linhas = [['Obra','Fase','Data','Descrição','Tópico','Pagamento','Valor','Parcela','Total de parcelas']];
    for(const obra of dados.obras || []) for(const gasto of obra.gastos || []){
      const topico = (dados.config?.topicosCustom || []).find(t=>t.id === gasto.topico);
      linhas.push([obra.nome, obra.fase, gasto.data, gasto.descricao, topico?.nm || gasto.topico,
        gasto.pagamento, Number.isFinite(gasto.valor) ? gasto.valor.toFixed(2).replace('.', ',') : '',
        gasto.parcela?.n, gasto.parcela?.de]);
    }
    return '\uFEFF' + linhas.map(l=>l.map(celula).join(';')).join('\r\n') + '\r\n';
  }
  /* Recorte de uma obra só, com a config junto (os tópicos próprios dão nome às linhas). */
  function dadosDaObra(dados, obraId){
    return { obras:(dados.obras || []).filter(o=>o.id === obraId), config:dados.config };
  }
  function json(dados){
    return JSON.stringify({ formato:'custta', versao:1, exportadoEm:new Date().toISOString(), dados }, null, 2);
  }
  async function exportar(dados, formato, raiz = root){
    if(!['json','csv'].includes(formato)) throw new Error('Formato não suportado.');
    const texto = formato === 'json' ? json(dados) : csv(dados);
    const nome = 'custta-' + new Date().toISOString().slice(0,10) + '.' + formato;
    const tipo = formato === 'json' ? 'application/json' : 'text/csv;charset=utf-8';
    const nativo = raiz && raiz.OBRA_NATIVO;
    if(nativo && nativo.ehNativo()){
      const r = await nativo.compartilharArquivo({ nome, texto, tipo, titulo:'Dados do Custta' });
      if(r) return;
    }
    const arquivo = new File([texto], nome, { type:tipo });
    if(navigator.canShare?.({ files:[arquivo] })){
      await navigator.share({ files:[arquivo], title:'Dados do Custta' });
      return;
    }
    const url = URL.createObjectURL(arquivo);
    const a = document.createElement('a'); a.href = url; a.download = nome;
    document.body.append(a); a.click(); a.remove();
    setTimeout(()=>URL.revokeObjectURL(url), 60000);
  }
  const api = { csv, json, exportar, dadosDaObra };
  if(typeof module !== 'undefined') module.exports = api;
  if(root) root.OBRA_SHARE = api;
})(typeof window !== 'undefined' ? window : null);

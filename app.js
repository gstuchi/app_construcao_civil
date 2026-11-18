/* Custta — controle de custos por obra. PWA offline-first, vanilla JS.
   Dados no Firestore por usuário (cloud.js); localStorage guarda preferências deste aparelho. */
'use strict';

/* ---------- estado ---------- */

const TOPICOS = OBRA_CALC.TOPICOS; // calc.js: o push (Node) usa a mesma lista
const PIE = ['--c1','--c2','--c3','--c4','--c5','--c6','--c7','--c8'];
const FASES = {
  construcao: {nm:'Em construção',    ic:'guindaste', cls:'pend'},
  pronta:     {nm:'Pronta · à venda', ic:'casa',      cls:'blue'},
  vendida:    {nm:'Vendida',          ic:'check',     cls:'ok'},
};

const empty = () => ({obras:[], config:{taxaMensal:1, topicosCustom:[]}});
let db = empty();
/* Nome vem de perfis/{uid}; lido uma vez por conta e relido quando o dialog salva. */
const perfilAjustes = { uid:null, dados:null };
let obraAberta = null;   // id da obra no detalhe
let filtroTexto = '', filtroMes = ''; // busca dos lançamentos (só memória)
let tab = 'inicio';
let unwatch = null;

const normaliza = OBRA_DADOS.normaliza;
function textoValido(valor, tipo, campo){
  if(valor.length <= OBRA_DADOS.LIMITES[tipo]) return true;
  toast(`Use até ${OBRA_DADOS.LIMITES[tipo]} caracteres.`, "erro");
  campo.focus(); return false;
}
/* O blob inteiro vai num documento só, e documento do Firestore para em 1MB.
   Sem esta guarda a escrita falhava calada: a tela mostrava o gasto novo e o
   dado sumia no próximo carregamento. */
function save(){
  const tamanho = OBRA_CALC.tamanhoBlob(db);
  if(tamanho >= OBRA_CALC.AVISO_BLOB && tamanho <= OBRA_CALC.LIMITE_BLOB && !avisouTamanho){
    avisouTamanho = true;
    toast('Seus dados estão próximos do limite de armazenamento.', 'erro');
  }
  if(tamanho < OBRA_CALC.AVISO_BLOB) avisouTamanho = false;
  return CLOUD.saveDados(db);
}
let avisouTamanho = false;

/* Confirmação honesta: "sucesso" só depois do servidor confirmar. Se em 600ms
   ele não respondeu, informa espera sem prometer persistência pelo tempo decorrido.
   O erro tem dono próprio: 'cloud-erro' e a pill de sincronização. */
function salvarComAviso(msgOk){
  const p = save();
  let respondeu = false;
  const avisoLocal = setTimeout(()=>{
    if(!respondeu) toast('Aguardando sincronização — mantenha o app aberto até confirmar');
  }, 600);
  const fim = ()=>{ respondeu = true; clearTimeout(avisoLocal); };
  p.then(()=>{ fim(); toast(msgOk); }, fim);
  return p;
}
const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2,6);

const topicos = () => [...TOPICOS, ...db.config.topicosCustom];
const TOP_MAP = () => Object.fromEntries(topicos().map(t=>[t.id,t]));
const nomeTopico = id => (TOP_MAP()[id] || {nm:id}).nm; // tópico próprio apagado cai no id
const taxa = () => db.config.taxaMensal;

/* ---------- helpers ---------- */
/* Moeda, meses e canon moram no calc.js (puros; o app nativo confere a cópia dele pelos vetores). */
const { money, moneyShort, moneyCurto, fmtMeses, canon } = OBRA_CALC;
const MESAB = ['jan','fev','mar','abr','mai','jun','jul','ago','set','out','nov','dez'];
const todayISO = () => OBRA_CALC.dataLocalISO();
const fmtData = iso => { const [y,m,d] = iso.split('-'); return escapeHtml(`${d}/${m}/${y.slice(2)}`); };
const parseNum = OBRA_CALC.parseNum;
/* máscara de dinheiro: formata ao digitar, completa centavos ao sair */
function maskMoney(sel){
  const inp = typeof sel==='string' ? $(sel) : sel;
  if(!inp) return;
  inp.addEventListener('input', ()=>{ inp.value = OBRA_CALC.fmtDigitado(inp.value); });
  inp.addEventListener('blur',  ()=>{ inp.value = OBRA_CALC.fmtCompleto(inp.value); });
}
const $ = s => document.querySelector(s);
const el = (tag,cls,html)=>{ const e=document.createElement(tag); if(cls)e.className=cls; if(html!=null)e.innerHTML=html; return e; };
// String() antes do replace: campo numérico do blob (areaM2, valor) também passa por aqui
function escapeHtml(s){ return (s==null||s===false ? '' : String(s)).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function emptyBlock(icon,msg){ return `<div class="empty"><div class="big">${icon}</div><p>${msg}</p></div>`; }
// KPIs de milhao estouram a largura do card (overflow:hidden corta o numero).
// Reduz a fonte do numero so o quanto precisar pra caber; grande quando cabe.
function fitNums(scope){
  (scope||document).querySelectorAll('.k-num').forEach(n=>{
    n.style.whiteSpace = 'nowrap';
    n.style.fontSize = '';                 // volta pro tamanho base do CSS
    let fs = parseFloat(getComputedStyle(n).fontSize);
    let guard = 40;
    while(n.scrollWidth > n.clientWidth && fs > 13 && guard-- > 0){
      fs -= 0.5; n.style.fontSize = fs + 'px';
    }
  });
}
const obraById = id => db.obras.find(o=>o.id===id);

/* ===== Identidade da etapa 4: números em mono =====
   "R$" e centavos menores na linha do número (mockup custta-mockups/nativo/etapa4, parte 1).
   O texto vem do money()/moneyCurto() do calc.js: o número é o mesmo, só muda a roupa. */
function dinheiroHtml(v){
  const corpo = money(Math.abs(v || 0)).replace(/^R\$\s*/, '');
  const [int, cent] = corpo.split(',');
  return `<span class="num">${v < 0 ? '−' : ''}<span class="moeda">R$</span>${int}${cent ? `<span class="cent">,${cent}</span>` : ''}</span>`;
}
function dinheiroCurtoHtml(v){
  const corpo = moneyCurto(Math.abs(v || 0)).replace(/^R\$\s*/, '');
  return `<span class="num">${v < 0 ? '−' : ''}<span class="moeda">R$</span>${corpo}</span>`;
}
/* Pedaços do anel e da barra empilhada: os 6 maiores tópicos em cor e o resto em "Outros",
   cinza. O tópico fixo "Outros" sempre entra no pedaço cinza (regra do spec da etapa 4). */
const CORES_TOPICO = ['--g1','--g2','--g3','--g4','--g5','--g6'];
function pedacosTopicos(o){
  const todos = OBRA_CALC.gastoPorTopico(o).filter(t => t.bruto > 0);
  const total = todos.reduce((s, t) => s + t.bruto, 0);
  const coloridos = todos.filter(t => t.id !== 'outros').slice(0, CORES_TOPICO.length);
  const resto = todos.filter(t => !coloridos.includes(t));
  const pedacos = coloridos.map((t, i) => ({ id:t.id, nm:nomeTopico(t.id), bruto:t.bruto, pct:t.pct, cor:CORES_TOPICO[i], ids:[t.id] }));
  if(resto.length){
    const bruto = resto.reduce((s, t) => s + t.bruto, 0);
    pedacos.push({ id:'__outros', nm:'Outros', bruto, pct: total ? Math.round(bruto / total * 100) : 0, cor:'--g-outros', ids:resto.map(t => t.id), outros:true });
  }
  return { pedacos, total, todos, corDe: id => (pedacos.find(p => p.ids.includes(id)) || {}).cor || '--g-outros' };
}
const pctTexto = (bruto, total) => { const p = total ? bruto / total * 100 : 0; return p > 0 && p < 1 ? '<1%' : Math.round(p) + '%'; };

/* ---------- navegação ---------- */
/* iOS mata o app em segundo plano e o WKWebView recarrega do zero: lembra onde
   o usuário estava. Preferência por aparelho, não é dado de obra. */
const ESTADO_KEY = 'custta-estado';
let estadoRestaurado = false;
function lembraEstado(){
  if(!estadoRestaurado) return; // antes de restaurar, o boot não pode sobrescrever o salvo
  try{ localStorage.setItem(ESTADO_KEY, JSON.stringify({ tab, obraAberta })); }
  catch(e){ registraErro('estado', e && e.message); }
}
function restauraEstado(){
  if(estadoRestaurado) return;
  estadoRestaurado = true;
  let salvo = null;
  try{ salvo = JSON.parse(localStorage.getItem(ESTADO_KEY) || 'null'); }catch(e){ salvo = null; }
  /* sem estado salvo (1ª visita): sem isto o + de Obras nascia escondido — o showView
     que liga o dataset do + só roda ao trocar de tela, nunca no primeiro carregamento */
  if(!salvo || typeof salvo.tab !== 'string' || !document.getElementById('v-' + salvo.tab)){ showView('inicio'); renderAll(); return; }
  if(salvo.obraAberta && obraById(salvo.obraAberta)){
    openObra(salvo.obraAberta);
    if(salvo.tab === 'relatorio'){ showView('relatorio'); renderRelatorio(); }
    else if(salvo.tab === 'graficos'){ showView('graficos'); renderGraficos(); }
  }else if(!['obra', 'relatorio', 'graficos'].includes(salvo.tab)){
    showView(salvo.tab); renderAll();
  }else{
    showView('inicio'); renderAll();
  }
}
/* Direção da troca de tela, para a transição do celular (styles.css, body[data-nav]):
   a aba Obras é uma pilha (Obras › obra › relatório/gráficos): descer desliza da
   direita, subir desliza de volta; trocar de aba é só um fade, como no iOS. */
const PILHA_OBRAS = ['inicio', 'obra', 'relatorio', 'graficos'];
const nivelNav = x => x==='obra' ? 1 : (x==='relatorio'||x==='graficos') ? 2 : 0;
function direcaoNav(de, para){
  if(PILHA_OBRAS.includes(de) !== PILHA_OBRAS.includes(para)) return 'aba';
  return nivelNav(para) > nivelNav(de) ? 'push' : nivelNav(para) < nivelNav(de) ? 'pop' : 'aba';
}
function showView(v){
  const nav = direcaoNav(tab, v);
  /* o título grande não sai de cena (só troca o texto): tirar o atributo e recalcular o
     estilo dele faz a animação recomeçar a cada tela, junto com a da seção */
  delete document.body.dataset.nav;
  void getComputedStyle($('#tituloGrande')).animationName;
  document.body.dataset.nav = nav;
  tab = v;
  document.querySelectorAll('section.view').forEach(s=>s.classList.remove('active'));
  $('#v-'+v).classList.add('active');
  /* a aba Obras segue acesa dentro da obra, do relatório e dos gráficos: na barra de abas (iOS)
     e na lateral do desktop (macOS) */
  const aba = PILHA_OBRAS.includes(v) ? 'inicio' : v;
  document.querySelectorAll('aside.side button[data-tab]').forEach(x=>x.classList.toggle('on',x.dataset.tab===aba));
  document.querySelectorAll('nav.tabs button[data-tab]').forEach(x=>x.classList.toggle('on',x.dataset.tab===aba));
  $('nav.tabs').dataset.aba = String(['inicio','simula','ajustes'].indexOf(aba)); // lente desliza até a aba
  /* botão +: ao lado da cápsula de abas no celular, cria obra (Obras) ou lança gasto (obra);
     no desktop só aparece na obra — lá o "+ Nova obra" do conteúdo continua (styles.css) */
  const acao = v==='obra' ? 'gasto' : v==='inicio' ? 'obra' : '';
  const fab = $('#fab');
  fab.dataset.acao = acao;
  fab.classList.toggle('hidden', !acao);
  fab.setAttribute('aria-label', acao==='obra' ? 'Nova obra' : 'Lançar gasto');
  document.body.classList.toggle('com-fab', !!acao); // respiro: o + não cobre o fim da página
  window.scrollTo({top:0});
  atualizaTitulo();
  lembraEstado();
}
/* Barra de navegação do celular (padrão iOS): título grande no começo do conteúdo,
   título pequeno na barra quando o grande sai da vista, "‹ Obras" nas telas empilhadas.
   No desktop os três ficam escondidos e o header continua com a logo. */
const TITULOS = { inicio:'Obras', simula:'Vale a pena?', ajustes:'Ajustes', relatorio:'Relatório', graficos:'Gráficos' };
function atualizaTitulo(){
  const t = tab==='obra' ? (obraById(obraAberta)?.nome || 'Obra') : (TITULOS[tab] || '');
  $('#tituloGrande').textContent = t; // nome de obra é texto do usuário: textContent, nunca innerHTML
  $('#navTitulo').textContent = t;
  const volta = ['obra','relatorio','graficos'].includes(tab);
  $('#navVoltar').hidden = !volta;
  const destino = tab==='obra' ? 'Obras' : 'Obra';
  $('#navVoltarTexto').textContent = destino;
  $('#navVoltar').setAttribute('aria-label', `Voltar para ${destino}`);
}
/* o voltar mora na barra; quem sabe voltar continua sendo o .back de cada tela (escondido no celular) */
$('#navVoltar').onclick = ()=> document.querySelector('section.view.active .back')?.click();
/* Título grande passou para baixo da barra → barra ganha material e mostra o título pequeno.
   A margem é a altura real da barra (44px + área segura, que muda de aparelho para aparelho
   e na rotação): com número fixo, no iPhone com entalhe o título subia até o relógio antes
   de a barra ganhar fundo. */
if('IntersectionObserver' in window){
  let io = null, alturaBarra = -1;
  const observaTitulo = ()=>{
    const h = Math.round($('header.top').getBoundingClientRect().height);
    if(h === alturaBarra) return;
    alturaBarra = h;
    if(io) io.disconnect();
    io = new IntersectionObserver(([e])=>$('header.top').classList.toggle('colapsada', !e.isIntersecting),
      { rootMargin: `-${h}px 0px 0px 0px` });
    io.observe($('#tituloGrande'));
  };
  observaTitulo();
  addEventListener('resize', observaTitulo);
}
atualizaTitulo();
document.querySelectorAll('button[data-tab]').forEach(b=>{
  b.onclick = ()=>{ estadoRestaurado = true; /* gesto do usuário vence a restauração */ obraAberta=null; showView(b.dataset.tab); renderAll(); };
});
$('#btnVoltar').onclick = ()=>{ estadoRestaurado = true; /* gesto do usuário vence a restauração */ obraAberta=null; showView('inicio'); renderAll(); };
function openObra(id){ obraAberta=id; evoSel=-1; mesSel=-1; filtroTexto=''; filtroMes=''; showView('obra'); renderObra(); }

/* ---------- render ---------- */
function renderAll(){
  renderInicio();
  renderAjustes();
  renderSimula();
  if(obraAberta) renderObra();
}

/* ===== INÍCIO (lista de obras; o dashboard vive no detalhe) ===== */
function renderInicio(){
  const hoje = todayISO();

  const arr = [...db.obras].sort((a,b)=>
    ((a.fase==='vendida')-(b.fase==='vendida')) || b.dataInicio.localeCompare(a.dataInicio));
  $('#obraCount').textContent = arr.length ? `${arr.length} obra${arr.length>1?'s':''}` : '';
  const list = $('#obrasList');
  list.innerHTML = arr.length ? '' : dadosCarregados
    ? emptyBlock(ICON('guindaste'),'Nenhuma obra ainda.<br>Toque no + pra criar a primeira obra.')
    : emptyBlock(ICON('guindaste'),'Carregando suas obras…');
  arr.forEach(o=>{
    const f = FASES[o.fase];
    const li = el('li');
    li.style.cursor = 'pointer';
    const orc = OBRA_CALC.orcamentoObra(o);
    const orcLinha = orc ? `<div class="orc-mini">${barraOrcHtml(orc.pct, orc.nivel, 'mini')}<span${orc.nivel === 'passou' ? ' class="orc-mini-alerta"' : ''}>${orc.nivel === 'passou' ? `${orc.pct}% · passou ${moneyCurto(-orc.sobra)}` : `${orc.pct}% do orçamento`}</span></div>` : '';
    li.innerHTML = `
      <div class="av ic-brand">${ICON(f.ic)}</div>
      <div class="li-main">
        <div class="t">${escapeHtml(o.nome)}</div>
        <div class="s"><span class="tag ${f.cls}">${f.nm}</span> <span class="obra-tempo">· ${fmtMeses(OBRA_CALC.mesesDeObra(o,hoje))}</span></div>
        ${orcLinha}
      </div>
      <div class="li-val">${moneyShort(OBRA_CALC.totalBruto(o))}</div>
      <span class="chevron" aria-hidden="true">›</span>`;
    li.onclick = ()=>openObra(o.id);
    list.appendChild(li);
  });
  pintaBarrasOrc(list);

  drawComp(arr.filter(o=>OBRA_CALC.totalBruto(o)>0), hoje);
}

function drawComp(arr, hoje){
  const panel = $('#panelComp');
  if(arr.length < 2){ panel.classList.add('hidden'); return; }
  panel.classList.remove('hidden');
  const rows = arr.map(o=>({
    nm: o.nome,
    b: OBRA_CALC.totalBruto(o),
    c: OBRA_CALC.totalCorrigido(o, taxa(), hoje),
  }));
  const max = Math.max(...rows.map(r=>r.c), 1);
  $('#compBars').innerHTML = rows.map(r=>`
    <div class="hbar">
      <div class="hbar-nm">${escapeHtml(r.nm)}</div>
      <div class="hbar-track">
        <i class="hb-corr"></i>
        <i class="hb-bruto"></i>
      </div>
      <div class="hbar-vl">${moneyShort(r.b)} gasto · ${moneyShort(r.c)} corrigido</div>
    </div>`).join('');
  $('#compBars').querySelectorAll('.hbar').forEach((bar,i)=>{
    bar.querySelector('.hb-corr').style.width = (rows[i].c/max*100).toFixed(1)+'%';
    bar.querySelector('.hb-bruto').style.width = (rows[i].b/max*100).toFixed(1)+'%';
  });
}

/* ===== ORÇAMENTO previsto × real =====
   Um número por vez: o card mostra gasto de previsto, barra e sobra; o detalhe
   fica na lista por tópico. Verde-marca abaixo de 90%, âmbar daí pra cima.
   Os textos e a largura da barra vêm do calc.js (o app nativo usa os mesmos). */
function barraOrcHtml(pct, nivel, extra){
  return `<div class="orc-barra${extra ? ' ' + extra : ''}${nivel === 'ok' ? '' : ' alerta'}" aria-hidden="true"><i data-pct="${OBRA_CALC.larguraBarraOrc(pct)}"></i></div>`;
}
/* largura via CSSOM: a CSP proíbe atributo style no HTML */
function pintaBarrasOrc(escopo){
  escopo.querySelectorAll('.orc-barra i[data-pct]').forEach(i => { i.style.width = i.dataset.pct + '%'; });
}
/* cor e peso dos pedaços (barra empilhada, legenda) via CSSOM: a CSP proíbe style no HTML */
function pintaCores(escopo){
  escopo.querySelectorAll('[data-cor]').forEach(e => { e.style.setProperty('--cor', `var(${e.dataset.cor})`); });
  escopo.querySelectorAll('[data-peso]').forEach(e => { e.style.flexGrow = e.dataset.peso; });
}
function fraseTopicoHtml(t){
  const f = OBRA_CALC.fraseTopicoOrc(t);
  return f ? `<div class="orc-frase${f.alerta ? ' alerta' : ''}">${f.texto}</div>` : '';
}
/* Bloco do orçamento na obra (identidade da etapa 4): pílula, sobra, barra, "% usado de…",
   aviso dos tópicos que passaram e o que está fora. Por tópico, o detalhe abre numa folha. */
function orcamentoHtml(o, orc, pecas){
  const rodape = OBRA_CALC.rodapeOrc(orc);
  const passaram = pecas.porTopico ? orc.topicos.filter(t => t.nivel === 'passou').length : 0;
  return `
    <button type="button" class="kpi kpi-link orc-card" id="oOrc" aria-label="Orçamento: ${rodape.usado} usado, ${rodape.rotulo} ${rodape.valor}">
      <div class="k-top"><span class="k-nome">Orçamento</span>
        <span class="orc-pill${orc.nivel === 'ok' ? '' : ' alerta'}">${OBRA_CALC.ORC_PILULA[orc.nivel]}</span></div>
      <div class="orc-sobra"><span class="orc-sobra-rot">${rodape.rotulo}</span> <span class="k-num medio">${dinheiroHtml(Math.abs(orc.sobra))}</span></div>
      <div class="orc-linha-barra">${barraOrcHtml(orc.pct, orc.nivel)}<span class="chev" aria-hidden="true">›</span></div>
      <div class="k-obs">${rodape.usado} usado de ${money(orc.previsto)}</div>
      ${passaram ? `<div class="aviso">${ICON('alerta')} ${passaram} tópico${passaram > 1 ? 's passaram' : ' passou'} do previsto</div>` : ''}
      ${orc.foraTotal ? `<div class="k-obs">${moneyCurto(orc.foraTotal)} fora do orçamento</div>` : ''}
    </button>`;
}
/* Folha do orçamento por tópico: a lista que morava dentro da obra. */
function sheetOrcamento(obraId){
  const o = obraById(obraId); if(!o) return;
  const orc = OBRA_CALC.orcamentoObra(o), pecas = OBRA_CALC.pecasOrcamento(o);
  if(!orc){ closeSheet(); return; }
  if(!pecas.porTopico){ formOrcamento(o.id); return; }
  const linhas = orc.topicos.map(t => {
    const valores = OBRA_CALC.linhaTopicoOrc(t);
    const miolo = `
      <div class="orc-linha"><span class="orc-nome">${escapeHtml(nomeTopico(t.id))}</span>
        <span class="orc-val"><b>${valores.gasto}</b> / ${valores.previsto}</span></div>
      ${barraOrcHtml(t.pct, t.nivel, 'fina')}${fraseTopicoHtml(t)}`;
    return pecas.tocaveis.includes(t.id)
      ? `<li class="orc-item"><button type="button" class="orc-item-conteudo" data-top="${escapeHtml(t.id)}">${miolo}</button></li>`
      : `<li class="orc-item"><div class="orc-item-conteudo">${miolo}</div></li>`;
  }).join('');
  const fora = orc.fora.length ? `
    <li class="orc-item orc-fora">
      <div class="orc-linha"><span class="orc-nome">Fora do orçamento</span><span class="orc-val"><b>${moneyCurto(orc.foraTotal)}</b></span></div>
      <div class="orc-frase">${escapeHtml(orc.fora.map(f => nomeTopico(f.id)).join(', '))}</div>
    </li>` : '';
  const rodape = OBRA_CALC.rodapeOrc(orc);
  openSheet(`
    <div class="top-head">${ICON('alvo')}<h3>Orçamento por tópico</h3></div>
    <div class="top-resumo"><div class="sub">${rodape.usado} usado · ${rodape.rotulo} ${rodape.valor}</div>
      <b>${money(orc.gasto)}</b><div class="corr">de ${money(orc.previsto)} previstos</div></div>
    <ul class="orc-lista">${linhas}${fora}</ul>
    <div class="sheet-actions"><button class="btn ghost" id="orcFechar">Fechar</button>
      <button class="btn primary" id="oOrcEditar">${ICON('alvo')} Editar orçamento</button></div>`);
  pintaBarrasOrc($('#sheet'));
  $('#sheet').querySelectorAll('.orc-item-conteudo[data-top]').forEach(btn => { btn.onclick = () => sheetTopico(o.id, btn.dataset.top); });
  $('#orcFechar').onclick = closeSheet;
  $('#oOrcEditar').onclick = () => formOrcamento(o.id);
}

/* ===== DETALHE DA OBRA ===== */
function renderObra(){
  const o = obraById(obraAberta);
  if(!o){ obraAberta=null; showView('inicio'); return; }
  const hoje = todayISO();
  const f = FASES[o.fase];
  const bruto = OBRA_CALC.totalBruto(o);
  const corr  = OBRA_CALC.totalCorrigido(o, taxa(), hoje);
  const lucro = OBRA_CALC.lucroVenda(o, taxa());
  const orc = OBRA_CALC.orcamentoObra(o);
  const pecasOrc = OBRA_CALC.pecasOrcamento(o);

  const head = `
    <div class="panel obra-head">
      <h2 class="layout-32"><span class="layout-33">${ICON(f.ic)} ${escapeHtml(o.nome)}</span>
        <button class="layout-34 li-del" id="oEdit" title="Editar obra" aria-label="Editar obra">${ICON('lapis')}</button></h2>
      <div class="layout-35 obra-meta">
        <span class="tag ${f.cls}">${f.nm}</span><span class="obra-sep"> · </span><span class="obra-desde">começou em ${fmtData(o.dataInicio)} · ${fmtMeses(OBRA_CALC.mesesDeObra(o,hoje))}</span>
      </div>
    </div>`;

  /* Um bloco sólido por tela (identidade da etapa 4): o Total gasto; na obra vendida com lucro,
     o lucro da venda (decisão 4 do mockup, A). Abaixo, um assunto por bloco de vidro. */
  const venc = OBRA_CALC.aPagar([o], hoje);
  const ppm2 = OBRA_CALC.precoPorM2(o.valorEstimadoVenda, o.areaM2);
  const qtd = o.gastos.length;
  const chipQtd = qtd ? `${qtd} lançamento${qtd>1?'s':''}` : 'sem gastos';
  const vendidaComLucro = o.fase==='vendida' && lucro && lucro.bruto >= 0;
  const solido = vendidaComLucro ? `
      <div class="kpi solido">
        <div class="k-top"><span class="k-nome">Lucro da venda</span><span class="chip2 tinta">Vendida em ${fmtData(o.venda.data)}</span></div>
        <div class="k-num gigante">${dinheiroHtml(lucro.bruto)}</div>
        <div class="k-obs">venda de ${money(o.venda.valor)} · ${lucro.vsBanco>=0?'+':'−'}${moneyCurto(Math.abs(lucro.vsBanco))} acima do banco</div>
      </div>` : `
      <div class="kpi solido">
        <div class="k-top"><span class="k-nome">Total gasto</span><span class="chip2 tinta">${chipQtd}</span></div>
        <div class="k-num gigante">${dinheiroHtml(bruto)}</div>
        <div class="k-obs">bruto, sem correção</div>
      </div>`;
  const blocoTotal = vendidaComLucro ? `
      <div class="kpi">
        <div class="k-top"><span class="k-nome">Total gasto</span><span class="chip2 green">${chipQtd}</span></div>
        <div class="k-num medio">${dinheiroHtml(bruto)}</div>
        <div class="k-obs">bruto, sem correção</div>
      </div>` : '';
  let kpiVenda = '';
  if(o.fase==='vendida' && lucro && !vendidaComLucro){
    kpiVenda = `
      <div class="kpi">
        <div class="k-top"><span class="k-nome">Venda</span><span class="chip2 amber">Vendida em ${fmtData(o.venda.data)}</span></div>
        <div class="k-num medio">${dinheiroHtml(o.venda.valor)}</div>
        <div class="k-obs ambar">prejuízo de ${moneyCurto(Math.abs(lucro.bruto))} · ${moneyCurto(Math.abs(lucro.vsBanco))} abaixo do banco</div>
      </div>`;
  } else if(o.fase!=='vendida' && o.valorEstimadoVenda){
    kpiVenda = `
      <div class="kpi">
        <div class="k-top"><span class="k-nome">Venda estimada</span><span class="chip2 green">estimativa</span></div>
        <div class="k-num medio">${dinheiroHtml(o.valorEstimadoVenda)}</div>
        <div class="k-obs">${ppm2 ? `${moneyShort(ppm2)}/m² · ${escapeHtml(String(o.areaM2).replace('.',','))} m² · ` : ''}margem ${o.valorEstimadoVenda-corr>=0?'':'−'}${moneyCurto(Math.abs(o.valorEstimadoVenda-corr))} sobre o corrigido</div>
      </div>`;
  }
  const resumo = `
    <div class="kpis">
      ${solido}
      ${pecasOrc.cartao ? orcamentoHtml(o, orc, pecasOrc) : ''}
      ${blocoTotal}
      <div class="kpi">
        <div class="k-top"><span class="k-nome">Corrigido pelo banco</span></div>
        <div class="k-num medio" id="oCorr">${dinheiroHtml(corr)}</div>
        <div class="k-obs">Correção até ${o.venda?'a venda':'hoje'}: +${money(corr-bruto)}</div>
      </div>
      ${o.fase==='vendida' ? '' : `
      <button type="button" class="kpi kpi-link" id="oAPagar">
        <div class="k-top"><span class="k-nome">A pagar · 30 dias</span>
          <span class="chip2 amber">${venc.qtd ? venc.qtd+' vencimento'+(venc.qtd>1?'s':'') : 'nada em 30 dias'}</span></div>
        <div class="k-linha"><div class="k-num medio">${dinheiroHtml(venc.total)}</div><span class="chev" aria-hidden="true">›</span></div>
        <div class="k-obs">Parcelas e gastos futuros</div>
      </button>`}
      ${kpiVenda}
    </div>`;

  let acoes = '<div class="obra-actions">';
  if(o.fase==='construcao') acoes += `<button class="btn primary" id="oPronta">${ICON('casa')} Marcar como pronta</button>`;
  if(o.fase==='pronta') acoes += `
    <button class="btn primary" id="oVender">${ICON('acordo')} Registrar venda</button>
    <button class="btn ghost" id="oVoltarConstr">${ICON('voltar')} Voltar pra construção</button>`;
  if(o.fase==='vendida') acoes += `<button class="btn ghost" id="oDesfazer">${ICON('voltar')} Desfazer venda</button>`;
  if(pecasOrc.definir) acoes += `<button class="btn ghost" id="oOrcDefinir">${ICON('alvo')} Definir orçamento</button>`;
  if(o.gastos.length) acoes += `
    <button class="btn ghost porta" id="oGraf">${ICON('calculadora')} Ver gráficos</button>
    <button class="btn ghost porta" id="oRel">${ICON('documento')} Relatório</button>`;
  acoes += '</div>';

  const afazeres = `
    <div class="panel"><h2>Afazeres <span class="muted" id="afzCount"></span></h2>
      <div class="filter-row">
        <input id="afzInput" maxlength="500" placeholder="Ex: pagar pedreiro, buscar tinta" autocomplete="off">
        <button class="btn primary afz-add" id="afzAdd" aria-label="Adicionar afazer" title="Adicionar">+</button>
      </div>
      <ul class="list" id="oAfazeres"></ul>
    </div>`;

  /* Gastos por tópico: barra empilhada (6 maiores + Outros) e a legenda dos 4 maiores; o bloco
     inteiro é a porta para os Gráficos (o anel animado e as séries moram lá). */
  const tp = pedacosTopicos(o);
  const graficos = tp.total > 0 ? `
    <button type="button" class="panel pilha-bloco" id="oTopicos" aria-label="Gastos por tópico: ver gráficos">
      <h2><span>Gastos por tópico</span><span class="muted">${tp.todos.length} tópico${tp.todos.length>1?'s':''} <span class="chev" aria-hidden="true">›</span></span></h2>
      <div class="pilha-placa"><div class="pilha" id="oPilha">${tp.pedacos.map(p=>`<i data-cor="${p.cor}" data-peso="${p.bruto}"></i>`).join('')}</div></div>
      <div class="leg-mini">${tp.pedacos.slice(0,4).map(p=>`<div><span class="pt" data-cor="${p.cor}"></span><span class="nm">${escapeHtml(p.nm)}</span><span class="pc">${pctTexto(p.bruto, tp.total)}</span></div>`).join('')}
        ${tp.todos.length > 4 ? `<div class="mais-t">e mais ${tp.todos.length-4} tópico${tp.todos.length-4>1?'s':''}</div>` : ''}</div>
    </button>` : '';

  // o mês escolhido fica na lista mesmo sem gasto: o filtro que vale nunca some do <select>
  const mesesDoFiltro = OBRA_CALC.mesesDoFiltro(o.gastos, filtroMes);
  // no celular a busca divide a linha com o mês: a dica curta do iOS cabe inteira (a longa era cortada)
  const dicaBusca = matchMedia('(max-width:899px)').matches ? 'Buscar' : 'Pesquisar gasto ou tópico';
  const lanc = `
    <div class="panel"><h2>Lançamentos <span class="muted" id="lanCount"></span></h2>
      <div class="filter-row">
        <label class="busca"><span class="busca-ic" aria-hidden="true">${ICON('lupa')}</span>
          <input id="fBusca" placeholder="${dicaBusca}" aria-label="Pesquisar gasto ou tópico" autocomplete="off" value="${escapeHtml(filtroTexto)}"></label>
        <select id="fMes"><option value="">Todos os meses</option>
          ${mesesDoFiltro.map(({mes:m})=>`<option value="${escapeHtml(m)}"${m===filtroMes?' selected':''}>${MESAB[+m.slice(5)-1]}/${escapeHtml(m.slice(2,4))}</option>`).join('')}
        </select>
      </div>
      <ul class="list" id="oGastos"></ul>
    </div>`;

  $('#obraBody').innerHTML = head + resumo + acoes + afazeres + graficos + lanc;
  fitNums($('#obraBody'));
  pintaBarrasOrc($('#obraBody'));
  pintaCores($('#obraBody'));
  $('#fBusca').addEventListener('input', ()=>{ filtroTexto = $('#fBusca').value; renderGastosFiltrados(obraById(obraAberta)); });
  $('#fMes').onchange = ()=>{ filtroMes = $('#fMes').value; renderGastosFiltrados(obraById(obraAberta)); };
  renderGastosFiltrados(o);

  renderAfazeres(o);
  const addAfazer = ()=>{
    const inp = $('#afzInput'); const c = OBRA_DADOS.conferirAfazer(inp.value);
    if(c.erro === 'vazio'){ inp.focus(); return; }
    if(c.erro){ toast(c.mensagem, 'erro'); inp.focus(); return; }
    const oo = obraById(obraAberta); if(!oo) return;
    oo.afazeres = OBRA_DADOS.afazeresComNovo(oo.afazeres, c.texto, uid());
    save(); inp.value = ''; renderAfazeres(oo); inp.focus();
  };
  $('#afzAdd').onclick = addAfazer;
  $('#afzInput').addEventListener('keydown', e=>{ if(e.key==='Enter'){ e.preventDefault(); addAfazer(); } });

  $('#oEdit').onclick = ()=>formEditarObra(o);
  const on = (id,fn)=>{ const b=$(id); if(b) b.onclick=fn; };
  on('#oRel',          ()=>{ showView('relatorio'); renderRelatorio(); });
  on('#oGraf',         ()=>{ showView('graficos'); renderGraficos(); });
  on('#oAPagar',       ()=>sheetAPagar(o.id));
  on('#oTopicos',      ()=>{ showView('graficos'); renderGraficos(); });
  on('#oOrc',          ()=>sheetOrcamento(o.id));
  on('#oPronta',       ()=>mudarFase(o.id,'pronta'));
  on('#oVender',       ()=>formVenda(o));
  on('#oVoltarConstr', ()=>mudarFase(o.id,'construcao'));
  on('#oDesfazer',     async()=>{ if(await OBRA_CONFIRM.perguntar('Desfazer a venda? A obra volta pra “Pronta”.', { confirmar:'Desfazer venda' })){ const oo=obraById(o.id); if(!oo) return; delete oo.venda; oo.fase='pronta'; save(); renderAll(); } });
  on('#oOrcDefinir',   ()=>formOrcamento(o.id));
  atualizaTitulo(); // obra renomeada (aqui ou em outro aparelho) atualiza o título da barra
}

function renderAfazeres(o){
  const list = $('#oAfazeres'); if(!list) return;
  const items = o.afazeres || [];
  $('#afzCount').textContent = OBRA_CALC.contadorDeAfazeres(items);
  list.innerHTML = '';
  if(!items.length){ list.innerHTML = emptyBlock(ICON('check'),'Nenhum afazer.<br>Anote o que falta na obra.'); return; }
  OBRA_CALC.afazeresEmOrdem(items).forEach(a=>list.appendChild(afazerRow(o, a)));
}

function afazerRow(o, a){
  const li = el('li', a.feito ? 'afz-done' : '');
  // marcar e desmarcar levam o afazer ao começo da lista (dados.js afazeresAlternado)
  const toggle = ()=>{
    const oo = obraById(o.id); if(!oo) return;
    const nova = OBRA_DADOS.afazeresAlternado(oo.afazeres, a.id); if(!nova) return;
    oo.afazeres = nova; save(); renderAfazeres(oo);
  };
  const check = el('button','afz-check', ICON('check'));
  check.setAttribute('aria-label', a.feito ? 'Desmarcar afazer' : 'Marcar feito');
  check.onclick = toggle;
  const main = el('div','li-main', `<div class="t">${escapeHtml(a.texto)}</div>`);
  main.style.cursor = 'pointer';
  main.onclick = toggle;
  const del = el('button','li-del','×');
  del.setAttribute('aria-label','Apagar afazer');
  del.onclick = ()=>{
    const oo = obraById(o.id); if(!oo) return;
    const nova = OBRA_DADOS.afazeresSem(oo.afazeres, a.id);
    if(nova){ oo.afazeres = nova; save(); }
    renderAfazeres(oo);
  };
  li.append(check, main, del);
  return li;
}

/* topicos: o gastoPorTopico do calc.js ({id, bruto, pct}, na ordem do donut) */
/* Gráfico de evolução: área suave do acumulado corrigido + linha do bruto.
   Toque num mês mostra os valores no topo (sem tooltip flutuante).
   Cores validadas p/ daltonismo (dataviz): --chart-gasto × --chart-rec. */
let evoSel = -1; // mês selecionado (índice); -1 = último
/* margem esquerda que caiba o rótulo mais largo do eixo (~0.58em por caractere) */
function margemEixo(max, H){
  const fs = H > 200 ? 11 : 9;
  const larg = Math.max(...[0.25,0.5,0.75,1].map(f => moneyShort(max*f).length));
  return Math.ceil(10 + larg * fs * 0.58);
}
function smoothPath(pts){
  if(pts.length < 2) return pts.length ? `M${pts[0].x} ${pts[0].y} L${pts[0].x+1} ${pts[0].y}` : '';
  let d = `M${pts[0].x} ${pts[0].y}`;
  for(let i = 0; i < pts.length - 1; i++){
    const p0 = pts[i-1] || pts[i], p1 = pts[i], p2 = pts[i+1], p3 = pts[i+2] || p2;
    d += ` C${(p1.x+(p2.x-p0.x)/6).toFixed(1)} ${(p1.y+(p2.y-p0.y)/6).toFixed(1)}`
       + ` ${(p2.x-(p3.x-p1.x)/6).toFixed(1)} ${(p2.y-(p3.y-p1.y)/6).toFixed(1)}`
       + ` ${p2.x} ${p2.y}`;
  }
  return d;
}
function evoChartHtml(o, opts = {}){
  const suf = opts.sufixo || '';
  const titulo = opts.titulo || 'Evolução da obra';
  const hoje = todayISO();
  const serie = opts.serie || OBRA_CALC.serieEvolucao(o, taxa(), hoje);
  if(!serie.length) return `<div class="panel"><h2>${titulo}</h2>${emptyBlock(ICON('calendario'),'Sem gastos ainda.')}</div>`;
  const W = 360, H = opts.H || 170, R = 6, T = 12, B = 22;
  const so1 = serie.length === 1;               // 1 mês só: linha reta atravessada
  const s = so1 ? [serie[0], serie[0]] : serie;
  const max = Math.max(...s.map(p => p.corrigido)) * 1.08 || 1;
  const L = margemEixo(max, H);
  const x = i => L + (W-L-R) * i / (s.length-1);
  const y = v => T + (H-T-B) * (1 - v/max);
  const pc = s.map((p,i) => ({x:+x(i).toFixed(1), y:+y(p.corrigido).toFixed(1)}));
  const pb = s.map((p,i) => ({x:+x(i).toFixed(1), y:+y(p.bruto).toFixed(1)}));
  const grade = [0.25,0.5,0.75,1].map(f => {
    const gy = y(max*f).toFixed(1);
    return `<line x1="${L}" y1="${gy}" x2="${W-R}" y2="${gy}" class="grade"/>
            <text x="${L-4}" y="${+gy+3}" text-anchor="end">${moneyShort(max*f)}</text>`;
  }).join('');
  const passo = Math.ceil(serie.length / 7); // no máx ~7 rótulos de mês
  const rotulos = so1
    ? `<text x="${((L+W-R)/2).toFixed(1)}" y="${H-6}" text-anchor="middle">${MESAB[+serie[0].mes.slice(5)-1]}</text>`
    : serie.map((p,i) => (i % passo && i !== serie.length-1) ? '' :
        `<text x="${x(i).toFixed(1)}" y="${H-6}" text-anchor="middle">${MESAB[+p.mes.slice(5)-1]}</text>`).join('');
  const cols = serie.map((p,i) => {
    const x0 = so1 ? L : (i ? (x(i-1)+x(i))/2 : L);
    const x1 = so1 ? W-R : (i < serie.length-1 ? (x(i)+x(i+1))/2 : W-R);
    return `<rect class="evo-col" data-i="${i}" x="${x0.toFixed(1)}" y="${T}" width="${(x1-x0).toFixed(1)}" height="${H-T-B}" fill="transparent"/>`;
  }).join('');
  const sel = evoSel >= 0 && evoSel < serie.length ? evoSel : serie.length-1;
  const mx = so1 ? (L+W-R)/2 : pb[sel].x;
  const marca = `<line x1="${mx}" y1="${T}" x2="${mx}" y2="${H-B}" class="guia"/>
                 <circle cx="${mx}" cy="${pc[sel].y}" r="4" class="ponto-banco"/>
                 <circle cx="${mx}" cy="${pb[sel].y}" r="4.5" class="ponto-gasto"/>`;
  // parcelas a vencer ficam fora da linha (ela para em hoje ou na venda): avisa quanto
  const fim = o.venda ? o.venda.data : hoje;
  const fora = o.gastos.filter(g => g.data > fim).reduce((t, g) => t + g.valor, 0);
  return `
    <div class="panel"><h2>${titulo}</h2>
      <div class="leitura" id="evoVal${suf}"></div>
      <svg class="evo-svg${H>200?' evo-big':''}" viewBox="0 0 ${W} ${H}" width="100%" id="evoSvg${suf}" role="img" aria-label="Evolução do gasto e do corrigido pelo banco, mês a mês">
        <defs><linearGradient id="evoGrad${suf}" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" class="area-ini"/><stop offset="100%" class="area-fim"/>
        </linearGradient></defs>
        ${grade}
        <path d="${smoothPath(pb)} L ${W-R} ${H-B} L ${L} ${H-B} Z" fill="url(#evoGrad${suf})" stroke="none"/>
        <path d="${smoothPath(pc)}" fill="none" class="linha-banco"/>
        <path d="${smoothPath(pb)}" fill="none" class="linha-gasto"/>
        ${marca}${rotulos}${cols}
      </svg>
      <div class="evo-leg">
        <span><i class="cheia"></i>Gasto</span>
        <span><i class="trac"></i>Corrigido pelo banco</span>
      </div>
      ${fora > 0 ? `<div class="nota-fora">Fora do gráfico: ${moneyCurto(fora)} em parcelas a vencer.</div>` : ''}
    </div>`;
}
function bindEvoChart(o, suf = '', rerender = renderGraficos, serieOpt = null){
  const svg = $('#evoSvg' + suf);
  if(!svg) return;
  const serie = serieOpt || OBRA_CALC.serieEvolucao(o, taxa(), todayISO());
  const mostra = i => {
    const p = serie[i]; if(!p) return;
    const [yy, mm] = p.mes.split('-');
    $('#evoVal' + suf).innerHTML =
      `<div class="rot">${MESAB[+mm-1]}/${yy.slice(2)}</div>
       <div class="sub">gasto ${dinheiroCurtoHtml(p.bruto)} · no banco já seria ${dinheiroCurtoHtml(p.corrigido)}</div>`;
  };
  svg.querySelectorAll('.evo-col').forEach(r => r.onclick = () => { evoSel = +r.dataset.i; rerender(); });
  mostra(evoSel >= 0 && evoSel < serie.length ? evoSel : serie.length-1);
}

/* Gasto por mês: barras finas do bruto por mês-calendário. O mês escolhido acende no destaque
   (padrão: este mês); as parcelas a vencer ficam hachuradas. Média, maior e meses embaixo,
   contados do 1º gasto até este mês, sem as parcelas a vencer. */
let mesSel = -1; // mês selecionado (índice); -1 = este mês
function mesPadrao(serie){
  const agora = todayISO().slice(0, 7);
  const i = serie.findIndex(p => p.mes === agora);
  if(i >= 0) return i;
  const passados = serie.map((p, k) => p.mes <= agora ? k : -1).filter(k => k >= 0);
  return passados.length ? passados[passados.length - 1] : 0;
}
function mesChartHtml(o, opts = {}){
  const suf = opts.sufixo || '';
  const serie = OBRA_CALC.serieMensal(o.gastos);
  if(!serie.length) return ''; // sem gastos o evo já mostra o vazio; não duplica
  const W = 360, H = opts.H || 170, R = 6, T = 12, B = 22;
  const max = Math.max(...serie.map(p => p.total)) * 1.08 || 1;
  const L = margemEixo(max, H);
  const y = v => T + (H-T-B) * (1 - v/max);
  const slot = (W-L-R) / serie.length;
  const bw = Math.max(3, Math.min(16, slot * 0.5));
  const grade = [0.25,0.5,0.75,1].map(f => {
    const gy = y(max*f).toFixed(1);
    return `<line x1="${L}" y1="${gy}" x2="${W-R}" y2="${gy}" class="grade"/>
            <text x="${L-4}" y="${+gy+3}" text-anchor="end">${moneyShort(max*f)}</text>`;
  }).join('');
  const sel = mesSel >= 0 && mesSel < serie.length ? mesSel : mesPadrao(serie);
  const passo = Math.ceil(serie.length / 7);
  const base = H - B;
  const agora = todayISO().slice(0, 7);
  const barra = (x0, yTopo) => {
    const r = Math.min(bw/2, Math.max(0, base - yTopo));
    return `M${x0.toFixed(1)} ${base} V${(yTopo+r).toFixed(1)} Q${x0.toFixed(1)} ${yTopo.toFixed(1)} ${(x0+r).toFixed(1)} ${yTopo.toFixed(1)}`
         + ` H${(x0+bw-r).toFixed(1)} Q${(x0+bw).toFixed(1)} ${yTopo.toFixed(1)} ${(x0+bw).toFixed(1)} ${(yTopo+r).toFixed(1)} V${base} Z`;
  };
  const partes = serie.map((p,i) => {
    const cx = L + slot*i + slot/2, x0 = cx - bw/2;
    const rot = (i !== sel && (i % passo || Math.abs(i - sel) < Math.max(2, passo * .6))) ? '' :
      `<text x="${cx.toFixed(1)}" y="${H-6}" text-anchor="middle" class="eixo-x${i===sel?' sel':''}" data-i="${i}">${MESAB[+p.mes.slice(5)-1]}</text>`;
    const futuro = p.mes > agora;
    const vis = p.total > 0
      ? `<path class="mes-bar${futuro?' futuro':''}${i===sel?' on':''}" data-i="${i}" d="${barra(x0, y(p.total))}"/>`
      : `<rect x="${x0.toFixed(1)}" y="${base-1.5}" width="${bw.toFixed(1)}" height="1.5" rx=".75" class="mes-zero"/>`;
    return `${vis}<rect class="mes-col" data-i="${i}" x="${(L+slot*i).toFixed(1)}" y="${T}" width="${slot.toFixed(1)}" height="${H-T-B}" fill="transparent"/>${rot}`;
  }).join('');
  const ate = serie.filter(p => p.mes <= agora);
  const media = ate.length ? ate.reduce((t,p)=>t+p.total,0) / ate.length : 0;
  const maior = ate.length ? Math.max(...ate.map(p=>p.total)) : 0;
  const temFuturo = serie.some(p => p.mes > agora && p.total > 0);
  return `
    <div class="panel"><h2>Gasto por mês</h2>
      <div class="leitura" id="mesVal${suf}"></div>
      <svg class="evo-svg${H>200?' evo-big':''}" viewBox="0 0 ${W} ${H}" width="100%" id="mesSvg${suf}" role="img" aria-label="Gasto bruto por mês">
        <defs><pattern id="hach${suf}" width="4" height="4" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="1.5" height="4" class="hach"/></pattern></defs>
        ${grade}
        <line x1="${L}" y1="${base}" x2="${W-R}" y2="${base}" class="eixo"/>
        ${partes}
      </svg>
      ${temFuturo ? `<div class="evo-leg"><span><i class="bar"></i>Pago</span><span><i class="hach-i"></i>A vencer</span></div>` : ''}
      <div class="stats">
        <div><div class="rot">Média por mês</div>${dinheiroCurtoHtml(media)}</div>
        <div><div class="rot">Maior mês</div>${dinheiroCurtoHtml(maior)}</div>
        <div><div class="rot">Meses</div><span class="num">${ate.length}</span></div>
      </div>
    </div>`;
}
function bindMesChart(o, suf = ''){
  const svg = $('#mesSvg' + suf);
  if(!svg) return;
  const serie = OBRA_CALC.serieMensal(o.gastos);
  const agora = todayISO().slice(0, 7);
  const mostra = i => {
    const p = serie[i]; if(!p) return;
    const [yy, mm] = p.mes.split('-');
    $('#mesVal' + suf).innerHTML = `<div class="rot">${MESAB[+mm-1]}/${yy.slice(2)}${p.mes > agora ? ' · a vencer' : p.mes === agora ? ' · este mês' : ''}</div>
      <div class="sub">${dinheiroHtml(p.total)}</div>`;
  };
  // tocar ou arrastar: o mês mais perto do dedo é o escolhido; a seleção fica ao soltar
  const escolhe = i => {
    if(i === mesSel || !serie[i]) return;
    mesSel = i;
    svg.querySelectorAll('.mes-bar').forEach(b => b.classList.toggle('on', +b.dataset.i === mesSel));
    mostra(mesSel);
  };
  const cols = [...svg.querySelectorAll('.mes-col')];
  const peloX = clientX => {
    let melhor = 0, dist = Infinity;
    cols.forEach(c => { const r = c.getBoundingClientRect(); const d = Math.abs(r.left + r.width/2 - clientX); if(d < dist){ dist = d; melhor = +c.dataset.i; } });
    return melhor;
  };
  svg.addEventListener('pointerdown', e => { escolhe(peloX(e.clientX)); });
  svg.addEventListener('pointermove', e => { if(e.buttons || e.pointerType === 'touch') escolhe(peloX(e.clientX)); });
  mostra(mesSel >= 0 && mesSel < serie.length ? mesSel : mesPadrao(serie));
}

/* repinta só a lista de lançamentos + contador (não perde o foco do teclado) */
function renderGastosFiltrados(o){
  if(!o) return;
  const list = $('#oGastos');
  const filtro = { texto: filtroTexto, mes: filtroMes };
  const filtrados = OBRA_CALC.filtraGastos(o.gastos, TOP_MAP(), filtro);
  $('#lanCount').textContent = OBRA_CALC.contadorLancamentos(o.gastos.length, filtrados.length, filtro);
  list.innerHTML = '';
  if(!o.gastos.length){ list.innerHTML = emptyBlock(ICON('recibo'),'Nenhum gasto lançado.<br>Toque no + pra lançar o primeiro.'); return; }
  if(!filtrados.length){ list.innerHTML = emptyBlock(ICON('recibo'),'Nada encontrado com esse filtro.'); return; }
  [...filtrados].sort((a,b)=>(b.data+b.id).localeCompare(a.data+a.id))
    .forEach(g=>list.appendChild(gastoRow(o,g)));
}

/* opts.voltar: pra quem abre a linha de dentro de outra folha (a do tópico) e
   quer voltar pra ela depois de editar/excluir, em vez de fechar tudo. */
function gastoRow(o, g, opts){
  const voltar = (opts && opts.voltar) || null;
  const fechar = voltar || closeSheet;
  const t = TOP_MAP()[g.topico] || {nm:g.topico||'Outros', ic:'etiqueta'};
  const li = el('li','gasto-row');
  const suf = g.parcela ? ` (${escapeHtml(g.parcela.n)}/${escapeHtml(g.parcela.de)})` : '';
  const futura = g.data > todayISO(); // ISO ordena lexicograficamente
  const pIc = g.pagamento==='cartao' ? ICON('cartao')+' ' : g.pagamento==='pix' ? ICON('raio')+' ' : '';
  li.innerHTML = `
    <div class="av ic-brand">${ICON(t.ic)}</div>
    <div class="li-main">
      <div class="t">${escapeHtml(g.descricao || t.nm)}${suf}</div>
      <div class="s gasto-meta"><span>${pIc}${escapeHtml(t.nm)}</span><span class="gasto-data">${fmtData(g.data)}</span>${futura?' <span class="tag pend">a vencer</span>':''}</div>
    </div>
    <div class="li-val">${dinheiroHtml(g.valor)}</div>`;
  li.querySelector('.li-main').style.cursor = 'pointer';
  li.querySelector('.li-main').onclick = ()=>formGasto(o.id, g, undefined, voltar);
  const del = el('button','li-del','×');
  del.setAttribute('aria-label','Apagar gasto');
  del.onclick = async()=>{
    const oo = obraById(o.id); if(!oo) return;
    if(!g.grupoId){
      // exclusão simples usa diálogo curto, não abre folha: nada a fechar, só voltar
      if(await OBRA_CONFIRM.perguntar('Excluir este gasto?', { confirmar:'Excluir' })){
        const atual = obraById(o.id); if(!atual) return;
        atual.gastos = atual.gastos.filter(x=>x.id!==g.id); save(); renderAll();
        if(voltar) voltar();
      }
      return;
    }
    const irmas = oo.gastos.filter(x=>x.grupoId===g.grupoId);
    openSheet(`
      <h3>Excluir parcela ${escapeHtml(g.parcela.n)}/${escapeHtml(g.parcela.de)}</h3>
      <p class="muted-note">Esta parcela faz parte de uma compra em ${escapeHtml(g.parcela.de)}x no cartão.</p>
      <div class="layout-40 sheet-actions">
        <button class="layout-19 btn primary" id="dUma">Excluir só esta parcela</button>
        <button class="layout-41 btn ghost" id="dTodas">Excluir a compra toda (${irmas.length} parcela${irmas.length>1?'s':''})</button>
        <button class="layout-19 btn ghost" id="dCancel">Cancelar</button>
      </div>`);
    $('#dCancel').onclick = fechar;
    // relê a obra no toque: um snapshot com a folha aberta troca os objetos do db, e a exclusão iria para uma cópia velha
    $('#dUma').onclick = ()=>{ const atual = obraById(o.id); if(atual){ atual.gastos = atual.gastos.filter(x=>x.id!==g.id); save(); renderAll(); } fechar(); };
    $('#dTodas').onclick = ()=>{ const atual = obraById(o.id); if(atual){ atual.gastos = atual.gastos.filter(x=>x.grupoId!==g.grupoId); save(); renderAll(); } fechar(); };
  };
  li.appendChild(del);
  return li;
}

/* ===== FASES E VENDA ===== */
/* handlers sempre re-resolvem a obra por id na hora do clique: o snapshot da
   nuvem pode ter trocado os objetos de db desde o render */
function mudarFase(id, f){ const o=obraById(id); if(!o) return; o.fase = f; save(); renderAll(); }

function formVenda(o){
  openSheet(`
    <h3>Registrar venda — ${escapeHtml(o.nome)}</h3>
    <div class="field big"><div class="money"><b>R$</b><input id="fVal" inputmode="decimal" placeholder="0,00" autocomplete="off"></div></div>
    <div class="field"><label>Data da venda</label><input id="fData" type="date" min="${escapeHtml(o.dataInicio)}" max="${todayISO()}" value="${todayISO()}"></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Confirmar venda</button>
    </div>`);
  maskMoney('#fVal');
  $('#fVal').focus();
  $('#cCancel').onclick = closeSheet;
  $('#cSave').onclick = ()=>{
    const valor = parseNum($('#fVal').value);
    const data = $('#fData').value;
    const erro = OBRA_DADOS.conferirVenda(valor, data, o.dataInicio, todayISO());
    if(erro?.erro==='valor'){ $('#fVal').focus(); return; }
    if(erro?.erro==='data'){ toast(erro.mensagem); $('#fData').focus(); return; }
    const oo = obraById(o.id); if(!oo) return;
    oo.venda = { valor, data };
    oo.fase = 'vendida';
    save(); closeSheet(); renderAll();
  };
}

function formEditarObra(o){
  openSheet(`
    <h3>Editar obra</h3>
    <div class="field"><label>Nome</label><input id="fNome" maxlength="120" value="${escapeHtml(o.nome)}" autocomplete="off"></div>
    <div class="field"><label>Começou em</label><input id="fData" type="date" value="${escapeHtml(o.dataInicio)}"></div>
    <div class="field"><label>Valor estimado de venda (opcional)</label>
      <div class="money"><b>R$</b><input id="fEst" inputmode="decimal" placeholder="0,00" value="${o.valorEstimadoVenda?OBRA_CALC.numParaCampo(o.valorEstimadoVenda):''}" autocomplete="off"></div></div>
    <div class="field"><label>Área construída em m² (opcional)</label>
      <input id="fArea" inputmode="decimal" placeholder="Ex: 320" value="${escapeHtml(String(o.areaM2||'').replace('.',','))}" autocomplete="off"></div>
    <div class="sheet-actions">
      <button class="layout-42 btn ghost" id="cDel">Apagar obra</button>
      <button class="btn primary" id="cSave">Salvar</button>
    </div>`);
  maskMoney('#fEst');
  $('#cSave').onclick = ()=>{
    const campos = { nome:$('#fNome').value.trim(), dataInicio:$('#fData').value,
      valorEstimadoVenda:parseNum($('#fEst').value), areaM2:parseNum($('#fArea').value) };
    const erro = OBRA_DADOS.conferirObra(campos, false);
    if(erro){ if(erro.mensagem) toast(erro.mensagem, "erro"); $('#fNome').focus(); return; }
    const i = db.obras.findIndex(x=>x.id===o.id); if(i<0) return;
    db.obras[i] = OBRA_DADOS.obraEditada(db.obras[i], campos);
    save(); closeSheet(); renderAll();
  };
  $('#cDel').onclick = async()=>{
    const n = o.gastos.length;
    if(await OBRA_CONFIRM.perguntar(`Apagar “${o.nome}”?` + (n?` Os ${n} lançamento(s) dela serão perdidos.`:''), { confirmar:'Apagar obra' })){
      db.obras = db.obras.filter(x=>x.id!==o.id);
      obraAberta = null;
      save(); closeSheet(); showView('inicio'); renderAll();
    }
  };
}

/* ===== GASTO (novo/editar) ===== */
/* aoFechar: quem abriu o form de dentro de outra folha passa como voltar pra
   ela no Salvar/Cancelar. Sem isso, fecha a folha — comportamento de sempre. */
function formGasto(obraId, gasto, valorInicial, aoFechar){
  const fechar = aoFechar || closeSheet;
  const abertas = db.obras.filter(o=>o.fase!=='vendida');
  if(!abertas.length && !gasto){ formNovaObra(); return; }
  const isEdit = !!gasto;
  // na edição a obra é fixa (a que está aberta); na criação pode escolher
  const oFix = isEdit ? obraById(obraAberta) : (obraId ? obraById(obraId) : null);

  const selObra = oFix
    ? `<div class="field"><label>Obra</label><input value="${escapeHtml(oFix.nome)}" disabled></div>`
    : `<div class="field"><label>Obra</label><select id="fObra">
        ${abertas.map(o=>`<option value="${escapeHtml(o.id)}">${escapeHtml(o.nome)}</option>`).join('')}
       </select></div>`;

  // parcela de compra parcelada: pagamento/parcelas fixos, edita só esta parcela
  const isParcela = isEdit && !!gasto.grupoId;
  const pagtoHtml = isParcela
    ? `<p class="muted-note">${ICON('cartao')} Parcela ${escapeHtml(gasto.parcela.n)}/${escapeHtml(gasto.parcela.de)} de uma compra no cartão — a edição vale só pra esta parcela.</p>`
    : `<div class="field"><label>Pagamento</label><div class="chips" id="fPagto"></div></div>
       <div class="field hidden" id="fParcWrap"><label>Parcelas</label>
         <select id="fParc">${Array.from({length:36},(_,i)=>`<option value="${i+1}">${i+1}x</option>`).join('')}</select>
         <label for="fJuros">Taxa de juros (% ao mês)</label>
         <input id="fJuros" inputmode="decimal" value="0" placeholder="Ex: 2,5" autocomplete="off" aria-describedby="cartaoAjuda cartaoResumo">
         <p class="muted-note" id="cartaoAjuda">0 = sem juros. Informe o valor da compra sem juros. Parcelas mensais fixas, com primeiro pagamento após um mês. A data abaixo é o primeiro vencimento.</p>
         <p class="muted-note" id="cartaoResumo" role="status" aria-live="polite"></p>
       </div>`;

  /* no novo gasto o valor já veio da tela de teclado: vira botão pra reabrir ela,
     e o #fVal fica escondido só pra manter o resto do form igual. Na edição segue
     campo normal, que é um fluxo raro e não sofre com o teclado do iOS. */
  const valHtml = isEdit
    ? `<div class="field big"><div class="money"><b>R$</b><input id="fVal" inputmode="decimal" placeholder="0,00"
        value="${OBRA_CALC.numParaCampo(gasto.valor)}" autocomplete="off"></div></div>`
    : `<button type="button" class="valor-btn" id="cValor">Valor
        <span class="valor-btn-num">R$ <b>0,00</b></span></button>
       <input type="hidden" id="fVal" value="${OBRA_CALC.numParaCampo(valorInicial||'')}">`;

  openSheet(`
    <h3>${isEdit?'Editar gasto':'Novo gasto'}</h3>
    ${valHtml}
    ${selObra}
    <div class="field"><label>Tópico</label>
      <div class="chips" id="fChips"></div></div>
    ${pagtoHtml}
    ${isEdit && gasto.jurosCartao ? `<p class="muted-note">Condições originais da compra: ${escapeHtml(String(gasto.jurosCartao.taxaMensal).replace('.',','))}% ao mês · ${escapeHtml(String(gasto.jurosCartao.nParcelas))}x · juros ${money(gasto.jurosCartao.jurosCompra)} · total ${money(gasto.jurosCartao.totalCompra)}. O valor editável já inclui juros; não serão aplicados novamente.</p>`:''}
    <div class="field"><label for="fDesc">Descrição (opcional)</label>
      <div class="desc-wrap"><input id="fDesc" maxlength="500" placeholder="Ex: 50 sacos de cimento" value="${isEdit?escapeHtml(gasto.descricao||''):''}"
        autocomplete="off" role="combobox" aria-autocomplete="list" aria-expanded="false" aria-controls="descSugestoes">
        <div class="desc-sugestoes" id="descSugestoes" role="listbox"></div></div></div>
    <div class="field"><label id="fDataLabel" for="fData">Data</label><input id="fData" type="date" value="${isEdit?escapeHtml(gasto.data):todayISO()}"></div>
    <p class="dup-warning hidden" id="dupWarning" role="alert"></p>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Salvar</button>
    </div>`);

  const pedirValor = ()=>{
    TECLADO.abrir({
      valorInicial: parseNum($('#fVal').value),
      onConfirm: v => { $('#fVal').value = OBRA_CALC.numParaCampo(v); pintarValor(); atualizarCartao(); }
    });
  };
  const pintarValor = ()=>{
    $('#cValor').querySelector('b').textContent =
      TECLADO.fmtCentavos(TECLADO.reaisParaCentavos(parseNum($('#fVal').value)));
  };
  if(isEdit) maskMoney('#fVal');
  else { pintarValor(); $('#cValor').onclick = pedirValor; }

  let top = isEdit ? gasto.topico : topicos()[0].id;
  const chips = $('#fChips');
  let duplicadoConfirmado = '';
  const limpaDuplicado = ()=>{
    duplicadoConfirmado='';
    $('#dupWarning').classList.add('hidden');
    $('#cSave').textContent='Salvar';
  };
  const pintarSugestoes = ()=>{
    const lista=$('#descSugestoes'), campo=$('#fDesc');
    const obraIdAtual=oFix ? oFix.id : ($('#fObra')?.value||'');
    const sugestoes=OBRA_CALC.sugestoesDescricao(db.obras,obraIdAtual,top,campo.value,isEdit?gasto.id:null);
    lista.innerHTML='';
    sugestoes.forEach(s=>{
      const b=el('button','desc-sugestao'); b.type='button'; b.setAttribute('role','option');
      const nome=el('span'); nome.textContent=s.texto;
      const contexto=el('small'); contexto.textContent=s.mesmoTopico?'mesmo tópico':`${s.vezes}× usado`;
      b.append(nome,contexto);
      b.onclick=()=>{ campo.value=s.texto; lista.classList.remove('show'); campo.setAttribute('aria-expanded','false'); limpaDuplicado(); campo.focus(); };
      lista.appendChild(b);
    });
    lista.classList.toggle('show',sugestoes.length>0);
    campo.setAttribute('aria-expanded',String(sugestoes.length>0));
  };
  $('#fDesc').addEventListener('input',()=>{ limpaDuplicado(); pintarSugestoes(); });
  $('#fDesc').addEventListener('focus',pintarSugestoes);
  $('#fDesc').addEventListener('blur',()=>{
    const lista=$('#descSugestoes'), campo=$('#fDesc');
    setTimeout(()=>{ lista.classList.remove('show'); campo.setAttribute('aria-expanded','false'); },150);
  });
  $('#fData').addEventListener('input',limpaDuplicado);
  if($('#fObra')) $('#fObra').addEventListener('change',()=>{ limpaDuplicado(); pintarSugestoes(); });
  const paint = ()=>{
    chips.innerHTML = '';
    topicos().forEach(t=>{
      const ch = el('button','chip'+(t.id===top?' on':''),ICON(t.ic)+' '+escapeHtml(t.nm));
      ch.type = 'button';
      ch.setAttribute('aria-pressed',String(t.id===top));
      ch.onclick = ()=>{
        top=t.id; limpaDuplicado(); paint();
        $('#descSugestoes').classList.remove('show'); $('#fDesc').setAttribute('aria-expanded','false');
        [...chips.children].find(b=>b.getAttribute('aria-pressed')==='true')?.focus({preventScroll:true});
      };
      chips.appendChild(ch);
    });
  };
  paint();

  let pagto = isEdit ? (gasto.pagamento || 'pix') : 'pix';
  const datasPagamento={pix:$('#fData').value,cartao:OBRA_CALC.addMesesClampado($('#fData').value,1)};
  const calcularCartao=()=>OBRA_CALC.parcelamentoCartao(parseNum($('#fVal').value),Number($('#fParc')?.value),
    OBRA_CALC.lerTaxaCartao($('#fJuros')?.value),$('#fData').value);
  const atualizarCartao=()=>{
    if(isEdit) return;
    $('#fDataLabel').textContent=pagto==='cartao'?'Primeiro vencimento':'Data';
    const r=calcularCartao();
    $('#cartaoResumo').textContent=r
      ? `${r.nParcelas}x de ${money(r.parcelas[0].valor)}${r.parcelas.at(-1).valor!==r.parcelas[0].valor?` (última: ${money(r.parcelas.at(-1).valor)})`:''} · Juros do cartão: ${money(r.jurosCompra)} · Total: ${money(r.totalCompra)}`
      : 'Informe valor, parcelas, data válida e taxa entre 0 e 100% ao mês.';
  };
  if(!isEdit){
    $('#fJuros').addEventListener('input',()=>{limpaDuplicado();atualizarCartao();});
    $('#fParc').addEventListener('change',()=>{limpaDuplicado();atualizarCartao();});
    $('#fData').addEventListener('input',atualizarCartao);
  }
  if(!isParcela){
    const pchips = $('#fPagto');
    const paintPagto = ()=>{
      pchips.innerHTML = '';
      [['pix',ICON('raio')+' Pix'],['cartao',ICON('cartao')+' Cartão']].forEach(([id,nm])=>{
        const ch = el('button','chip'+(id===pagto?' on':''),nm);
        ch.type = 'button';
        ch.onclick = ()=>{
          if(!isEdit && id!==pagto){
            datasPagamento[pagto]=$('#fData').value;
            $('#fData').value=datasPagamento[id];
          }
          pagto=id; limpaDuplicado(); paintPagto();
        };
        pchips.appendChild(ch);
      });
      // parcelar só faz sentido no cartão e ao criar
      $('#fParcWrap').classList.toggle('hidden', pagto!=='cartao' || isEdit);
      atualizarCartao();
    };
    paintPagto();
  }

  if(isEdit) $('#fVal').focus();
  $('#cCancel').onclick = fechar;
  $('#cSave').onclick = ()=>{
    // regras puras no dados.js e no calc.js, as mesmas que o app nativo confere pelos vetores
    const entrada = { valor:parseNum($('#fVal').value), topico:top, descricao:$('#fDesc').value.trim(), data:$('#fData').value,
      pagamento:pagto, parcelas:parseInt($('#fParc')?.value,10)||1, juros:OBRA_CALC.lerTaxaCartao($('#fJuros')?.value) };
    const r = OBRA_DADOS.conferirGasto(entrada, isEdit ? gasto : null, todayISO());
    if(r.erro==='valor'){ if(isEdit) $('#fVal').focus(); else pedirValor(); return; }
    if(r.erro==='descricao'){ toast(r.mensagem, "erro"); $('#fDesc').focus(); return; }
    const o = obraById(oFix ? oFix.id : $('#fObra').value);
    if(!o) return;
    if(r.erro==='cartao'){ toast(r.mensagem); $('#fJuros').focus(); return; }
    const assinatura=[o.id,top,OBRA_CALC.normalizaDescricao(entrada.descricao),Math.round(r.valor*100),r.data,r.parcelas,r.cartao?.taxaMensal].join('|');
    const pareceDuplicado=OBRA_CALC.gastoRepetido(o, entrada.descricao, r.valor, r.data, isEdit ? gasto.id : null);
    if(pareceDuplicado && duplicadoConfirmado!==assinatura){
      duplicadoConfirmado=assinatura;
      $('#dupWarning').textContent='Este gasto parece já lançado: mesma descrição, valor e data. Confira ou toque novamente para salvar mesmo assim.';
      $('#dupWarning').classList.remove('hidden');
      $('#cSave').textContent='Salvar mesmo assim';
      return;
    }
    if(isEdit){
      const i = o.gastos.findIndex(x=>x.id===gasto.id); if(i<0) return;
      o.gastos[i] = OBRA_DADOS.gastoEditado(o.gastos[i], entrada, r);
    } else {
      o.gastos.push(...OBRA_DADOS.gastosLancados(entrada, r, uid));
    }
    salvarComAviso(isEdit ? 'Gasto atualizado' : 'Gasto lançado com sucesso')
      .then(()=>OBRA_NATIVO.vibrar(), ()=>{}); // vibra só com o servidor confirmando
    renderAll(); fechar();
  };
}

/* ===== RELATÓRIO BRUTO × CORRIGIDO ===== */
$('#btnRelVoltar').onclick = ()=>{ if(obraAberta) openObra(obraAberta); else { showView('inicio'); renderAll(); } };
$('#btnGrafVoltar').onclick = ()=>{ if(obraAberta) openObra(obraAberta); else { showView('inicio'); renderAll(); } };

/* donut + legenda largura cheia (nome completo, % e valor) — reusado
   pela tela Gráficos e pelo dashboard do início. topicos: o gastoPorTopico do calc.js */
/* window.print() falha calado no WKWebView: no app o botão compartilha a planilha. */
function ligarImprimir(botao){
  if(!OBRA_NATIVO.ehNativo()){ botao.onclick = ()=>window.print(); return; }
  botao.innerHTML = `${ICON('documento')} Compartilhar planilha`;
  botao.onclick = async()=>{
    // a tela é de uma obra: a planilha também
    try{ await OBRA_SHARE.exportar(OBRA_SHARE.dadosDaObra(db, obraAberta), 'csv'); }
    catch(err){ toast('Não foi possível compartilhar. Tente novamente.', 'erro'); }
  };
}

/* ===== GRÁFICOS DA OBRA (identidade da etapa 4; mockup parte 1) =====
   Anel com os 6 maiores tópicos + "Outros" em cinza, pontas redondas que montam uma na outra,
   entrada girando (cada pedaço sai do topo e assenta) e toque que mostra o tópico no meio.
   Abaixo, a evolução (gasto cheio, corrigido tracejado) e o gasto por mês com o mês aceso. */
let anelSel = null;           // id do pedaço escolhido no anel (null = total)
let anelAnimou = null;        // obra cuja entrada do anel já rodou (só anima ao abrir)
function anelHtml(tp){
  const S = 240, c = S/2, R = 100, E = 26;            // caixa, centro, raio e espessura
  const C = 2*Math.PI*R, piso = 10;                   // piso de 10 pt de arco por pedaço
  const n = tp.pedacos.length;
  let lens = tp.pedacos.map(p => Math.max(piso, p.bruto / tp.total * C));
  const excesso = lens.reduce((a,b)=>a+b,0) - C;      // o que o piso somou sai do maior
  if(excesso > 0){ const i = lens.indexOf(Math.max(...lens)); lens[i] -= excesso; }
  let ini = 0;
  const pecas = tp.pedacos.map((p, i) => {
    const len = lens[i], a0 = ini; ini += len;
    const graus = a0 / C * 360;
    const vis = n === 1 ? C : Math.max(.01, len);
    // ponta inicial: aro do tom do fundo atrás da cabeça redonda (a emenda com o anterior)
    const ang = (graus - 90) * Math.PI / 180, hx = (c + R*Math.cos(ang)).toFixed(2), hy = (c + R*Math.sin(ang)).toFixed(2);
    return `<g class="peca" data-i="${i}" data-de="${(-graus).toFixed(2)}" data-cor="${p.cor}">
      ${n > 1 ? `<circle class="seg-sep" cx="${hx}" cy="${hy}" r="${E/2 + 2.5}"/>` : ''}
      <circle class="seg" cx="${c}" cy="${c}" r="${R}" fill="none" stroke-width="${E}" stroke-linecap="${n>1?'round':'butt'}"
        stroke-dasharray="${vis.toFixed(2)} ${(C - vis + 1).toFixed(2)}" stroke-dashoffset="${(-a0).toFixed(2)}" transform="rotate(-90 ${c} ${c})"/>
      <circle class="alvo" cx="${c}" cy="${c}" r="${R}" fill="none" stroke="transparent" stroke-width="${E+16}"
        stroke-dasharray="${len.toFixed(2)} ${(C-len).toFixed(2)}" stroke-dashoffset="${(-a0).toFixed(2)}" transform="rotate(-90 ${c} ${c})"/>
    </g>`;
  }).join('');
  // a cabeça do 1º pedaço volta por cima do último (o anel fecha sem degrau)
  const p0 = tp.pedacos[0];
  const fecho = n > 1 ? `<g class="peca fecho" data-i="0" data-de="0" data-cor="${p0.cor}"><circle class="seg-sep" cx="${c}" cy="${c - R}" r="${E/2 + 2.5}"/>
      <circle class="seg" cx="${c}" cy="${c}" r="${R}" fill="none" stroke-width="${E}" stroke-linecap="round" stroke-dasharray=".01 ${C}" transform="rotate(-90 ${c} ${c})"/></g>` : '';
  return `<div class="anel-caixa" id="anel">
      <svg viewBox="0 0 ${S} ${S}" width="${S}" height="${S}" role="img" aria-label="Gastos por tópico">
        <circle class="trilho" cx="${c}" cy="${c}" r="${R}" fill="none" stroke-width="${E + 8}"/>
        ${pecas}${fecho}
      </svg>
      <div class="centro" id="anelCentro" aria-live="polite"></div>
    </div>`;
}
function anelCentro(tp){
  const p = tp.pedacos.find(x => x.id === anelSel);
  const caixa = $('#anel'); if(!caixa) return;
  caixa.classList.toggle('escolhido', !!p);
  caixa.querySelectorAll('.peca').forEach(g => g.classList.toggle('on', !!p && tp.pedacos[+g.dataset.i] === p));
  $('#grafBody').querySelectorAll('.leg-lista [data-pedaco]').forEach(l => l.classList.toggle('on', !!p && l.dataset.pedaco === p.id));
  $('#anelCentro').innerHTML = p
    ? `<span class="cr">${escapeHtml(p.outros ? `Outros · ${p.ids.length} tópico${p.ids.length>1?'s':''}` : p.nm)}</span>
       <span class="cv">${dinheiroCurtoHtml(p.bruto)}</span>
       <span class="cp">${pctTexto(p.bruto, tp.total)} do total</span>
       ${p.outros ? '' : `<button type="button" class="cl" id="anelVer">Ver gastos ›</button>`}`
    : `<span class="cr">total gasto</span><span class="cv">${dinheiroCurtoHtml(tp.total)}</span>
       <span class="cp">${tp.todos.length} tópico${tp.todos.length>1?'s':''}</span>`;
  const ver = $('#anelVer');
  if(ver) ver.onclick = () => sheetTopico(obraAberta, p.id);
}
function renderGraficos(){
  const o = obraById(obraAberta);
  if(!o){ showView('inicio'); renderAll(); return; }
  const tp = pedacosTopicos(o);
  if(anelSel && !tp.pedacos.some(p => p.id === anelSel)) anelSel = null;
  const corDe = tp.corDe;
  const linha = t => `<div data-top="${escapeHtml(t.id)}" data-pedaco="${tp.pedacos.find(p=>p.ids.includes(t.id))?.id || ''}" role="button" tabindex="0">
      <span class="pt" data-cor="${corDe(t.id)}"></span><span class="nm">${escapeHtml(nomeTopico(t.id))}</span>
      <span class="pc">${pctTexto(t.bruto, tp.total)}</span><span class="vl">${dinheiroHtml(t.bruto).replace(/<span class="cent">.*?<\/span>/,'')}</span><span class="chev" aria-hidden="true">›</span></div>`;
  const outros = tp.pedacos.find(p => p.outros);
  const coloridos = tp.todos.filter(t => !outros || !outros.ids.includes(t.id));
  const cinzas = outros ? tp.todos.filter(t => outros.ids.includes(t.id)) : [];
  const blocoAnel = tp.total > 0 ? `
    <div class="panel graf-bloco">
      <h2><span>Gastos por tópico</span><span class="muted">${tp.todos.length} tópico${tp.todos.length>1?'s':''}</span></h2>
      ${anelHtml(tp)}
      <div class="leg-lista">${coloridos.map(linha).join('')}
        ${cinzas.length ? `<div class="outros-sep">Outros · ${cinzas.length} tópico${cinzas.length>1?'s':''}</div>${cinzas.map(linha).join('')}` : ''}</div>
    </div>` : `<div class="panel">${emptyBlock(ICON('recibo'),'Sem gastos ainda.')}</div>`;

  $('#grafBody').innerHTML = `
    <div class="graf-meta"><span class="subtit">${escapeHtml(o.nome)}</span></div>
    ${blocoAnel}
    ${evoChartHtml(o, { sufixo:'G', H:220 })}
    ${mesChartHtml(o, { sufixo:'G', H:200 })}
    <button class="layout-43 btn primary no-print" id="grafPrint">${ICON('impressora')} Imprimir / salvar PDF</button>`;
  pintaCores($('#grafBody'));
  const caixa = $('#anel');
  if(caixa){
    const anima = anelAnimou !== o.id && !matchMedia('(prefers-reduced-motion: reduce)').matches;
    anelAnimou = o.id;
    const cs = getComputedStyle(document.documentElement);
    const rgb = v => { const h = cs.getPropertyValue(v).trim().replace('#',''); return [0,2,4].map(k => parseInt(h.slice(k,k+2),16)); };
    const fundo = rgb('--anel-apagado');
    caixa.querySelectorAll('.peca').forEach(g => {
      const c = rgb(g.dataset.cor);
      g.style.setProperty('--cor-apagada', `rgb(${c.map((x,k) => Math.round(x*.26 + fundo[k]*.74)).join(',')})`);
      g.style.setProperty('--de', g.dataset.de + 'deg');
      g.style.setProperty('--atraso', (+g.dataset.i * 0.1) + 's');
      g.onclick = () => { const p = tp.pedacos[+g.dataset.i]; anelSel = anelSel === p.id ? null : p.id; anelCentro(tp); };
    });
    if(anima){ caixa.classList.add('anima'); setTimeout(() => caixa.classList.remove('anima'), 1200 + tp.pedacos.length * 100 + 50); }
    anelCentro(tp);
  }
  $('#grafBody').querySelectorAll('.leg-lista [data-top]').forEach(l => {
    const abre = () => sheetTopico(o.id, l.dataset.top);
    l.onclick = abre;
    l.onkeydown = e => { if(e.key === 'Enter' || e.key === ' '){ e.preventDefault(); abre(); } };
  });
  bindEvoChart(o, 'G', renderGraficos);
  bindMesChart(o, 'G');
  ligarImprimir($('#grafPrint'));
}

/* Folha do "A pagar": os vencimentos dos próximos 30 dias (calc.js aPagar). Editar e
   excluir saem daqui pelo próprio gastoRow e voltam para ela. */
function sheetAPagar(obraId){
  const o = obraById(obraId);
  if(!o){ closeSheet(); return; }
  const venc = OBRA_CALC.aPagar([o], todayISO());
  openSheet(`<h3>A pagar · próximos 30 dias</h3>
    <div class="top-resumo"><b>${money(venc.total)}</b>
      <div class="sub">${OBRA_CALC.textoVencimentos(venc.qtd)}</div></div>
    <ul class="list" id="aPagarGastos"></ul>
    ${venc.qtd?'': '<p class="muted-note">Nenhum gasto previsto para esse período.</p>'}
    <div class="sheet-actions"><button class="btn ghost" id="aPagarFechar">Fechar</button></div>`);
  venc.itens.forEach(({gasto})=>$('#aPagarGastos').appendChild(gastoRow(o,gasto,{voltar:()=>sheetAPagar(obraId)})));
  $('#aPagarFechar').onclick = closeSheet;
}

/* Folha com só os gastos de um tópico — o "de onde saiu esse pedaço do donut".
   Só leitura sobre db; editar/excluir sai daqui pelo próprio gastoRow. */
function sheetTopico(obraId, topicoId){
  const o = obraById(obraId);
  if(!o) return;
  const gs = o.gastos.filter(g=>g.topico===topicoId);
  if(!gs.length){ closeSheet(); return; } // último gasto do tópico foi excluído

  const t = TOP_MAP()[topicoId] || {nm:topicoId, ic:'etiqueta'};
  // o % usa o arredondamento da legenda do donut, senão o número muda ao abrir
  const r = OBRA_CALC.resumoTopico(o, topicoId, todayISO(), taxa());

  openSheet(`
    <div class="top-head">${ICON(t.ic)}<h3>${escapeHtml(t.nm)}</h3></div>
    <div class="top-resumo">
      <div class="sub">${r.qtd} gasto${r.qtd>1?'s':''} · ${r.pct}% da obra</div>
      <b>${money(r.bruto)}</b>
      <div class="corr">corrigido: ${money(r.corrigido)}</div>
    </div>
    <ul class="list" id="topGastos"></ul>
    <div class="sheet-actions"><button class="btn ghost" id="topFechar">Fechar</button></div>`);

  /* renderAll não repinta Gráficos, então editar/excluir daqui deixaria o donut
     atrás com o número velho. Repinta antes de remontar a folha. */
  const voltar = ()=>{
    if(tab==='graficos') renderGraficos();
    sheetTopico(obraId, topicoId);
  };
  const list = $('#topGastos');
  [...gs].sort((a,b)=>(b.data+b.id).localeCompare(a.data+a.id))
    .forEach(g=>list.appendChild(gastoRow(o, g, { voltar })));
  $('#topFechar').onclick = closeSheet;
}

/* ===== RELATÓRIO (identidade da etapa 4; mockup parte 2, Relatório A) =====
   O total da obra no bloco sólido, um bloco de vidro por tópico que abre e fecha com os gastos
   (bruto e corrigido de cada um) e o fim com a venda e a margem. "Selecionar" põe um marcador em
   cada gasto e em cada tópico (todos, parte ou nenhum) e a barra de soma embaixo; a lupa filtra
   por descrição ou tópico (calc.js filtraGastos) e o resumo dos achados toma o lugar do sólido.
   As contas são do calc.js (relatorioObra, fimRelatorio, somaSelecao), as mesmas do app nativo. */
/* % do total com uma casa, como no mockup (38,0%); abaixo de 0,1% vira "<0,1%" */
function pctRelatorio(v, total){
  const p = total ? v / total * 100 : 0;
  if(p > 0 && p < 0.1) return '<0,1%';
  return p.toLocaleString('pt-BR', { minimumFractionDigits:1, maximumFractionDigits:1 }) + '%';
}
const relPlural = (n, um, varios) => `${n} ${n === 1 ? um : varios}`;
/* marcador redondo de 44px: o input fica por cima, transparente (teclado, leitor de tela e clique);
   a bola desenhada é irmã dele */
const relBolaHtml = `<span class="rel-bola" aria-hidden="true">${ICON('check')}<i class="rel-traco"></i></span>`;
function relGastoHtml(item, nomeTopico){
  const g = item.gasto;
  const desc = (g.descricao || nomeTopico) + (g.parcela ? ` (${g.parcela.n}/${g.parcela.de})` : '');
  return `<li><label class="rel-gasto" data-gasto="${escapeHtml(g.id)}">
      <span class="rel-marca no-print"><input class="rel-check" type="checkbox" data-gasto="${escapeHtml(g.id)}" aria-label="Selecionar ${escapeHtml(desc)}">${relBolaHtml}</span>
      <span class="rel-corpo">
        <span class="rel-l1"><span class="rel-desc">${escapeHtml(desc)}</span><span class="rel-v">${dinheiroHtml(g.valor)}</span></span>
        <span class="rel-l2"><span class="rel-data">${fmtData(g.data)}</span><span class="rel-corr">corrigido ${dinheiroHtml(item.corrigido)}</span></span>
      </span>
    </label></li>`;
}
function renderRelatorio(){
  const o = obraById(obraAberta);
  if(!o){ showView('inicio'); renderAll(); return; }
  const hoje = todayISO();
  const tx = taxa();
  const map = TOP_MAP();
  const corDe = pedacosTopicos(o).corDe; // a mesma cor do anel dos Gráficos

  // grupos, gastos com o corrigido e totais: calc.js relatorioObra (o app nativo usa o mesmo)
  const rel = OBRA_CALC.relatorioObra(o, hoje, tx);
  const totB = rel.totalBruto;
  const totC = rel.totalCorrigido;
  const itens = new Map();
  rel.grupos.forEach(gr => gr.itens.forEach(it => itens.set(it.gasto.id, it)));
  const nomeDe = id => (map[id] || {nm:id}).nm;

  // estado da tela: vale enquanto ela está aberta (entrar de novo começa tudo fechado)
  const est = { abertos:new Set(), selecionando:false, marcados:new Set(), busca:'' };
  const achados = () => {
    const txt = est.busca.trim();
    return txt ? new Set(OBRA_CALC.filtraGastos(o.gastos, map, { texto:txt }).map(g => g.id)) : null;
  };

  const f = FASES[o.fase];
  const corrAte = o.venda ? 'Corrigido até a venda' : 'Corrigido pelo banco';
  const meta = `
    <div class="panel rel-meta" id="relMeta">
      <span class="chip2 ${o.fase === 'construcao' ? 'amber' : 'green'}">${f.nm}</span>
      <p>começou em ${fmtData(o.dataInicio)} · ${fmtMeses(OBRA_CALC.mesesDeObra(o, hoje))}</p>
      <p>${escapeHtml(OBRA_CALC.linhaCorrecao(o, hoje, tx))}</p>
    </div>`;

  // venda e lucro, ou venda estimada e margem, ou nada: calc.js fimRelatorio. Prejuízo em âmbar.
  const fimRel = OBRA_CALC.fimRelatorio(o, hoje, tx);
  const linhaFim = (rot, v, sinal) => `<div class="rel-fim-linha"><span class="rel-fim-rot">${rot}</span>
      <span class="rel-fim-v${sinal ? (v >= 0 ? ' pos' : ' neg') : ''}">${dinheiroHtml(v)}</span></div>`;
  let fim = '';
  if(fimRel && fimRel.tipo === 'venda'){
    fim = linhaFim(`Venda em ${fmtData(fimRel.data)}`, fimRel.valor)
        + linhaFim('Lucro bruto (venda − gasto)', fimRel.lucroBruto, true)
        + linhaFim('Acima do banco (venda − corrigido)', fimRel.acimaDoBanco, true);
  } else if(fimRel){
    fim = linhaFim('Venda estimada', fimRel.valor)
        + linhaFim('Margem estimada (estimado − corrigido)', fimRel.margem, true);
  }

  $('#relBody').innerHTML = `
    <h2 class="rel-impresso">Relatório — ${escapeHtml(o.nome)}</h2>
    <div class="rel-barra">
      <span class="subtit">${escapeHtml(o.nome)}</span>
      <div class="rel-acoes no-print">
        <button type="button" class="rel-redondo" id="relLupa" aria-label="Buscar gasto ou tópico" aria-expanded="false" aria-controls="relBusca">${ICON('lupa')}<span class="rel-x" aria-hidden="true">×</span></button>
        <button type="button" class="rel-pilula" id="relSelecionar" aria-pressed="false">Selecionar</button>
      </div>
    </div>
    <div class="rel-busca no-print" id="relBusca" hidden>
      <span class="rel-busca-ic" aria-hidden="true">${ICON('lupa')}</span>
      <input type="search" id="relBuscaCampo" placeholder="Buscar gasto ou tópico" aria-label="Buscar gasto ou tópico" autocomplete="off" enterkeyhint="search" maxlength="100">
    </div>
    ${meta}
    <div id="relTopo"></div>
    <div id="relLista"></div>
    ${fim ? `<div class="panel rel-fim" id="relFim">${fim}</div>` : ''}
    <button class="layout-44 btn primary no-print" id="relPrint">${ICON('impressora')} Imprimir / salvar PDF</button>
    <div class="kpi rel-soma no-print hidden" id="relSelected" role="status" aria-live="polite"></div>`;

  /* topo: o Total da obra no sólido; durante a busca, o resumo dos achados no lugar dele */
  const pintaTopo = vis => {
    let html;
    if(!vis){
      html = `<div class="kpi solido rel-total">
        <div class="k-top"><span class="k-nome">Total da obra</span><span class="chip2 tinta">${relPlural(o.gastos.length, 'gasto', 'gastos')}</span></div>
        <div class="k-num gigante">${dinheiroHtml(totB)}</div>
        <div class="rel-total-linha"><span>${corrAte}</span>${dinheiroHtml(totC)}</div>
        <div class="rel-total-linha"><span>Correção</span>${dinheiroHtml(totC - totB).replace('<span class="num">', '<span class="num">+')}</div>
      </div>`;
    } else if(!vis.size){
      html = `<div class="panel rel-nada" role="status">
        <p>Nada encontrado com esse filtro.</p>
        <button type="button" class="btn ghost" id="relLimpar">Limpar a busca</button>
      </div>`;
    } else {
      const s = OBRA_CALC.somaSelecao([...vis].map(id => itens.get(id)).filter(Boolean), totB);
      html = `<div class="kpi solido rel-total" role="status" aria-live="polite">
        <div class="k-top"><span class="k-nome">Achados</span><span class="chip2 tinta">${vis.size} de ${o.gastos.length} gastos</span></div>
        <div class="k-num gigante">${dinheiroHtml(s.bruto)}</div>
        <div class="rel-total-linha"><span>${corrAte}</span>${dinheiroHtml(s.corrigido)}</div>
        <div class="rel-total-linha"><span>Parte do total</span><span class="num">${s.parte}</span></div>
        ${est.selecionando ? `<button type="button" class="rel-marcar-todos" id="relMarcarAchados">Marcar os ${vis.size} achados</button>` : ''}
      </div>`;
    }
    $('#relTopo').innerHTML = html;
    const limpar = $('#relLimpar');
    if(limpar) limpar.onclick = () => { $('#relBuscaCampo').value = ''; est.busca = ''; pinta(); $('#relBuscaCampo').focus(); };
    const marcarTodos = $('#relMarcarAchados');
    if(marcarTodos) marcarTodos.onclick = () => { vis.forEach(id => est.marcados.add(id)); atualizaMarcas(); };
  };

  /* um bloco por tópico, do maior para o menor bruto; na busca, só os tópicos com achados,
     abertos e somando só os achados */
  const pintaLista = vis => {
    const blocos = rel.grupos.map((gr, i) => {
      const its = vis ? gr.itens.filter(it => vis.has(it.gasto.id)) : gr.itens;
      if(!its.length) return '';
      const nm = nomeDe(gr.topico);
      const bruto = vis ? its.reduce((s, it) => s + it.gasto.valor, 0) : gr.bruto;
      const corr = vis ? its.reduce((s, it) => s + it.corrigido, 0) : gr.corrigido;
      const qtd = vis ? `${its.length} de ${relPlural(gr.itens.length, 'gasto', 'gastos')}` : relPlural(gr.itens.length, 'gasto', 'gastos');
      const aberto = vis ? true : est.abertos.has(gr.topico);
      return `<div class="panel rel-top${aberto ? ' aberto' : ''}" data-top="${escapeHtml(gr.topico)}">
        <div class="rel-top-cab">
          <label class="rel-marca no-print"><input class="rel-check-top" type="checkbox" data-top="${escapeHtml(gr.topico)}" aria-label="Marcar os gastos de ${escapeHtml(nm)}">${relBolaHtml}</label>
          <button type="button" class="rel-abre" aria-expanded="${aberto}" aria-controls="relG${i}"
            aria-label="${escapeHtml(nm)}, ${money(bruto)}, corrigido ${money(corr)}, ${qtd}">
            <span class="rel-l1"><span class="rel-nm">${escapeHtml(nm)}</span><span class="rel-v">${dinheiroHtml(bruto)}</span></span>
            <span class="rel-l2"><span class="rel-info"><i class="pt" data-cor="${corDe(gr.topico)}"></i>${qtd} · ${pctRelatorio(bruto, totB)}</span><span class="rel-corr">corrigido ${dinheiroHtml(corr)}</span></span>
            <span class="rel-qtd-marcada" aria-hidden="true"></span>
            <span class="chev" aria-hidden="true">›</span>
          </button>
        </div>
        <ul class="rel-gastos" id="relG${i}"${aberto ? '' : ' hidden'}>${its.map(it => relGastoHtml(it, nm)).join('')}</ul>
      </div>`;
    }).join('');
    $('#relLista').innerHTML = blocos || (vis ? '' : `<div class="panel">${emptyBlock(ICON('recibo'), 'Sem gastos ainda.')}</div>`);
    pintaCores($('#relLista'));
    $('#relLista').querySelectorAll('.rel-abre').forEach(b => b.onclick = () => {
      const bloco = b.closest('.rel-top');
      const abre = !bloco.classList.contains('aberto');
      bloco.classList.toggle('aberto', abre);
      b.setAttribute('aria-expanded', String(abre));
      bloco.querySelector('.rel-gastos').hidden = !abre;
      if(!vis){ if(abre) est.abertos.add(bloco.dataset.top); else est.abertos.delete(bloco.dataset.top); }
    });
    $('#relLista').querySelectorAll('.rel-check').forEach(c => c.onchange = () => {
      if(c.checked) est.marcados.add(c.dataset.gasto); else est.marcados.delete(c.dataset.gasto);
      atualizaMarcas();
    });
    // o do tópico marca ou desmarca todos os gastos dele que estão à vista
    $('#relLista').querySelectorAll('.rel-check-top').forEach(c => c.onchange = () => {
      c.closest('.rel-top').querySelectorAll('.rel-check').forEach(g => {
        if(c.checked) est.marcados.add(g.dataset.gasto); else est.marcados.delete(g.dataset.gasto);
      });
      atualizaMarcas();
    });
  };

  /* marcadores (gasto e tópico com 3 estados), "N marcados" no tópico e a barra de soma */
  const atualizaMarcas = () => {
    const corpo = $('#relBody');
    corpo.classList.toggle('rel-selecionando', est.selecionando);
    corpo.querySelectorAll('.rel-check,.rel-check-top').forEach(c => { c.disabled = !est.selecionando; });
    corpo.querySelectorAll('.rel-check').forEach(c => {
      c.checked = est.marcados.has(c.dataset.gasto);
      c.closest('.rel-gasto').classList.toggle('marcado', c.checked);
    });
    corpo.querySelectorAll('.rel-top').forEach(b => {
      const cs = [...b.querySelectorAll('.rel-check')];
      const n = cs.filter(c => c.checked).length;
      const top = b.querySelector('.rel-check-top');
      top.checked = n > 0 && n === cs.length;
      top.indeterminate = n > 0 && n < cs.length;
      b.querySelector('.rel-qtd-marcada').textContent = est.selecionando && n ? relPlural(n, 'marcado', 'marcados') : '';
    });
    const barra = $('#relSelected');
    barra.classList.toggle('hidden', !est.selecionando);
    if(!est.selecionando){ barra.innerHTML = ''; return; }
    const vistos = [...corpo.querySelectorAll('.rel-check')].map(c => c.dataset.gasto);
    const marcadosVistos = vistos.filter(id => est.marcados.has(id));
    const fora = est.marcados.size - marcadosVistos.length;
    const avisoFora = fora > 0 ? `<p class="rel-soma-fora">e mais ${relPlural(fora, 'marcado', 'marcados')} fora da busca</p>` : '';
    if(!marcadosVistos.length){
      barra.innerHTML = `<p class="rel-soma-vazia"><b>Nenhum gasto marcado</b> · Toque nos gastos para somar.</p>${avisoFora}`;
      return;
    }
    const soma = OBRA_CALC.somaSelecao(marcadosVistos.map(id => itens.get(id)).filter(Boolean), totB);
    barra.innerHTML = `<div class="rel-soma-grade">
        <div><span class="rel-soma-rot" id="relSelQtd">${soma.quantos}</span><span class="rel-soma-v" id="relSelBruto">${dinheiroHtml(soma.bruto)}</span></div>
        <div><span class="rel-soma-rot">corrigido</span><span class="rel-soma-v" id="relSelCorr">${dinheiroHtml(soma.corrigido)}</span></div>
        <div><span class="rel-soma-rot">do total</span><span class="rel-soma-v num" id="relSelPct">${soma.parte}</span></div>
      </div>${avisoFora}`;
  };

  const pinta = () => {
    const vis = achados();
    // a meta e o fim saem durante a busca: os achados sobem e o fim não se mistura com eles
    $('#relMeta').classList.toggle('hidden', !!vis);
    if($('#relFim')) $('#relFim').classList.toggle('hidden', !!vis);
    pintaTopo(vis);
    pintaLista(vis);
    atualizaMarcas();
  };

  $('#relSelecionar').onclick = () => {
    est.selecionando = !est.selecionando;
    if(!est.selecionando) est.marcados.clear();
    const b = $('#relSelecionar');
    b.textContent = est.selecionando ? 'OK' : 'Selecionar';
    b.setAttribute('aria-pressed', String(est.selecionando));
    b.classList.toggle('on', est.selecionando);
    pintaTopo(achados());
    atualizaMarcas();
  };
  $('#relLupa').onclick = () => {
    const caixa = $('#relBusca'), lupa = $('#relLupa');
    const abre = caixa.hidden;
    caixa.hidden = !abre;
    lupa.setAttribute('aria-expanded', String(abre));
    lupa.setAttribute('aria-label', abre ? 'Fechar a busca' : 'Buscar gasto ou tópico');
    lupa.classList.toggle('on', abre);
    if(abre) $('#relBuscaCampo').focus();
    else if(est.busca){ $('#relBuscaCampo').value = ''; est.busca = ''; pinta(); }
  };
  $('#relBuscaCampo').oninput = e => { est.busca = e.target.value; pinta(); };
  $('#relBuscaCampo').onkeydown = e => { if(e.key === 'Escape'){ e.preventDefault(); $('#relLupa').click(); $('#relLupa').focus(); } };

  pinta();
  // o PDF é sempre o relatório inteiro: imprimir com a busca ativa limpa a busca antes
  // (registrado antes do onclick do ligarImprimir, roda primeiro)
  $('#relPrint').addEventListener('click', () => { if(est.busca){ $('#relBuscaCampo').value = ''; est.busca = ''; pinta(); } });
  ligarImprimir($('#relPrint'));
}

/* ===== SERÁ QUE VALE A PENA? ===== */
function renderSimula(){
  const sel = $('#simObra');
  // as obras e a escolhida: calc.js obrasSimulador (o app nativo usa o mesmo)
  const { elegiveis, escolhida } = OBRA_CALC.obrasSimulador(db.obras, sel.value);
  sel.innerHTML = elegiveis.length
    ? elegiveis.map(o=>`<option value="${escapeHtml(o.id)}">${escapeHtml(o.nome)}</option>`).join('')
    : '<option value="">— crie uma obra com gastos —</option>';
  if(escolhida) sel.value = escolhida;
  simulaCompute();
}

function simulaCompute(){
  const out = $('#simOut');
  const o = obraById($('#simObra').value);
  if(!o){ out.innerHTML = ''; return; }

  const vInp = $('#simValor');
  // enquanto a pessoa não digitou, o preço acompanha a venda estimada da obra escolhida (vazio sem estimada)
  if(!vInp.dataset.touched) vInp.value = OBRA_CALC.numParaCampo(OBRA_CALC.precoInicialSimulador(o));
  /* A conta e os textos: calc.js contaSimulador e textosSimulador (o app nativo usa os mesmos). Os meses param em 120 na
     conta, mesmo digitados além do teto do campo. A obra com menos de 1 mês fica sem taxa (o % ao mês explodiria), e a TIR
     passa da taxa do banco exatamente quando a venda passa do corrigido. */
  const conta = OBRA_CALC.contaSimulador(o, parseNum(vInp.value), parseInt($('#simMeses').value,10) || 0, todayISO(), taxa());
  if(!conta){
    out.innerHTML = `<div class="panel"><p class="muted-note">Digite o preço de venda pra ver a conta.</p></div>`;
    return;
  }
  const t = OBRA_CALC.textosSimulador(conta, taxa(), o.areaM2);
  const cor = s => s ? ` class="${s === 'negativo' ? 'neg' : 'pos'}"` : '';

  out.innerHTML = `
    <div class="card saldo big ${conta.vale?'':'saldo-abaixo'}">
      <div class="k-label"><span class="k-ic">${ICON(conta.vale?'check':'alerta')}</span> ${t.veredito}</div>
      <div class="layout-45 k-val">${t.taxa}</div>
      <div class="k-sub">${escapeHtml(t.detalhes.join(' · '))}</div>
    </div>
    <div class="panel">
      <h2 class="layout-28">${ICON('documento')} Relatório da simulação</h2>
      <div class="rep-scroll"><table class="rep-table rep-sim">
        <thead><tr><th></th><th>Pelo bruto</th><th>Pelo corrigido</th></tr></thead>
        <tbody>
          ${t.tabela.map(l => `<tr${l.destaque ? ' class="rep-total"' : ''}><td>${escapeHtml(l.rotulo)}</td><td${cor(l.sinalBruto)}>${l.bruto}</td><td${cor(l.sinalCorrigido)}>${l.corrigido}</td></tr>`).join('\n          ')}
        </tbody>
      </table></div>
    </div>`;
}
$('#simObra').onchange = simulaCompute;
maskMoney('#simValor'); // antes do listener de cálculo: reformata, depois calcula
$('#simValor').addEventListener('input', ()=>{ $('#simValor').dataset.touched='1'; simulaCompute(); });
$('#simMeses').addEventListener('input', simulaCompute);

/* ===== TEMA (claro/escuro) — preferência por aparelho, não sincroniza ===== */
const TEMA_KEY = 'mo_tema';
const temaClaro = () => document.documentElement.getAttribute('data-theme') === 'light';
function aplicaTema(claro){
  if(claro) document.documentElement.setAttribute('data-theme','light');
  else document.documentElement.removeAttribute('data-theme');
  try{ localStorage.setItem(TEMA_KEY, claro ? 'claro' : 'escuro'); }catch(e){ registraErro('tema', e && e.message); }
  const meta = document.querySelector('meta[name="theme-color"]');
  if(meta) meta.content = getComputedStyle(document.documentElement).getPropertyValue('--bg').trim();
  OBRA_NATIVO.barraStatus(temaClaro());
  renderAll(); // gráficos leem cor via getComputedStyle — precisam redesenhar
}

/* ===== NOTIFICAÇÕES PUSH — inscrição por aparelho, resumo diário via cron ===== */
const NOTIF_NOTA_PADRAO = 'Afazeres pendentes, parcelas do mês e lembrete de lançar gastos. '
  + 'Chega mesmo com o app fechado. Vale neste aparelho.';

/* Convite após login: uma resposta encerra os convites nesta conta/aparelho.
   A ativação continua disponível em Ajustes. Datas antigas também contam como resposta. */
const notifInvite=$('#notifInvite');
const convitesRespondidos=new Set();
let conviteNotifUid=null;
const chaveConviteNotif=uid=>`custta-notif-convite-${uid}`;
function esconderConviteNotif(){ notifInvite?.classList.add('hidden'); }
async function atualizarConviteNotif(user){
  esconderConviteNotif();
  conviteNotifUid=user?.uid||null;
  if(!user || !OBRA_PUSH.suportado()) return;
  try{
    if(await OBRA_PUSH.permissao()!=='default') return;
    if(await OBRA_PUSH.inscrito()) return;
    if(convitesRespondidos.has(user.uid) || localStorage.getItem(chaveConviteNotif(user.uid))!==null) return;
    if(conviteNotifUid===user.uid) notifInvite.classList.remove('hidden');
  }catch(err){ registraErro('push-convite',err.message,err.stack); }
}
function encerrarConviteNotif(){
  if(conviteNotifUid) convitesRespondidos.add(conviteNotifUid);
  try{ if(conviteNotifUid) localStorage.setItem(chaveConviteNotif(conviteNotifUid),'respondido'); }
  catch(err){ registraErro('push-convite',err.message,err.stack); }
  esconderConviteNotif();
}
$('#notifDepois').onclick=encerrarConviteNotif;
$('#notifAtivar').onclick=async()=>{
  const b=$('#notifAtivar'); b.disabled=true;
  encerrarConviteNotif();
  try{
    const ok=await OBRA_PUSH.ativar();
    esconderConviteNotif();
    toast(ok?'Notificações ativadas neste aparelho':'Permissão não concedida.',ok?undefined:'erro');
  }catch(err){ toast('Não deu pra ativar agora. Tente novamente.', 'erro'); }
  finally{ b.disabled=false; }
};

window.addEventListener('cloud-conta', ()=>renderAjustes());
/* ===== AJUSTES ===== */
function pintaNome(){
  const d = perfilAjustes.dados, nome = [d?.nome, d?.sobrenome].filter(Boolean).join(' ');
  $('#ajNome').textContent = nome;
  $('#ajNome').classList.toggle('hidden', !nome);
  $('#ajNomeEditar').textContent = nome ? 'Editar nome' : 'Adicionar nome';
}
async function carregaPerfilAjustes(conta, forcar){
  if(!conta){ perfilAjustes.uid=null; perfilAjustes.dados=null; pintaNome(); return; }
  if(perfilAjustes.uid === conta.uid && !forcar){ pintaNome(); return; }
  perfilAjustes.uid = conta.uid;
  let dados = null;
  try{ dados = (await window.CLOUD?.lerPerfil?.()) ?? null; }catch{ dados = null; }
  if(perfilAjustes.uid !== conta.uid) return; // trocou de conta no meio
  perfilAjustes.dados = dados; pintaNome();
}
window.addEventListener('perfil-alterado', ()=>carregaPerfilAjustes(window.CLOUD?.user(), true));
/* Aviso fixo enquanto o e-mail não for confirmado: e-mail errado só aparece
   quando a pessoa esquece a senha e o link de redefinição não chega. */
function renderAvisoEmail(conta){
  const pendente = !!conta && !conta.emailVerificado && conta.temSenha !== false;
  $('#avisoEmail').classList.toggle('hidden', !pendente);
  if(!pendente) return;
  $('#avisoEmailTexto').textContent = `Enviamos um link para ${conta.email}. Abra o e-mail e toque no link para proteger sua conta.`;
  $('#avisoEmailReenviar').onclick = async()=>{
    const b = $('#avisoEmailReenviar'); b.disabled = true;
    try{
      const enviado = await CLOUD.enviarVerificacao();
      $('#avisoEmailMsg').textContent = enviado ? 'Link reenviado. Confira também a caixa de spam.' : 'E-mail já confirmado.';
    }catch(err){
      $('#avisoEmailMsg').textContent = err.code === 'offline' ? 'Conecte à internet para reenviar.'
        : err.code === 'auth/too-many-requests' ? 'Muitos envios seguidos. Aguarde alguns minutos.'
        : 'Não foi possível reenviar agora. Tente novamente.';
    }finally{ b.disabled = false; }
  };
  $('#avisoEmailJa').onclick = async()=>{
    const b = $('#avisoEmailJa'); b.disabled = true;
    try{
      if(!(await CLOUD.conferirVerificacao()))
        $('#avisoEmailMsg').textContent = navigator.onLine === false ? 'Conecte à internet para conferir.'
          : 'Ainda não recebemos a confirmação. Toque no link do e-mail e tente de novo.';
    }finally{ b.disabled = false; }
  };
}
/* Quem confirma pelo app de e-mail volta pro Custta: confere sozinho. */
document.addEventListener('visibilitychange', ()=>{
  const conta = window.CLOUD?.user();
  if(document.visibilityState === 'visible' && conta && !conta.emailVerificado) window.CLOUD.conferirVerificacao?.();
});
function renderAjustes(){
  const conta = window.CLOUD?.user();
  renderAvisoEmail(conta);
  $('#ajEmail').textContent = conta?.email || '';
  $('#ajVerificacao').classList.toggle('hidden', !conta || conta.emailVerificado);
  $('#ajNomeEditar').onclick = ()=>OBRA_CONTA.abrir('nome', perfilAjustes.dados);
  carregaPerfilAjustes(conta);
  $('#ajSenha').onclick = ()=>OBRA_CONTA.abrir('senha');
  // Conta só Google não tem senha pra trocar.
  $('#ajSenha').classList.toggle('hidden', conta?.temSenha === false);
  $('#ajApagar').onclick = ()=>OBRA_CONTA.abrir('apagar');
  $('#ajVerificar').onclick = async()=>{
    const b = $('#ajVerificar'); b.disabled = true;
    try{
      const enviado = await CLOUD.enviarVerificacao();
      $('#ajVerificarMsg').textContent = enviado ? 'E-mail enviado. Confira também a caixa de spam.' : 'E-mail já confirmado.';
    }catch(err){ $('#ajVerificarMsg').textContent = err.code === 'offline' ? 'Conecte à internet para enviar.' : 'Não foi possível enviar agora. Aguarde e tente novamente.'; }
    finally{ b.disabled = false; }
  };
  for(const formato of ['json', 'csv']){
    const botao = document.getElementById(formato === 'json' ? 'ajJson' : 'ajCsv');
    botao.onclick = async()=>{
      try{ await OBRA_SHARE.exportar(db, formato); }
      catch(err){ if(err.name !== 'AbortError') toast('Não foi possível exportar. Tente novamente.', 'erro'); }
    };
  }
  const tg = $('#ajTema');
  if(tg){
    const claro = temaClaro();
    tg.setAttribute('aria-checked', String(claro));
    tg.setAttribute('aria-label', claro ? 'Modo escuro' : 'Modo claro');
    tg.querySelector('.bola').innerHTML = ICON(claro ? 'sol' : 'lua');
    tg.onclick = () => aplicaTema(!temaClaro());
  }

  const tgN = $('#ajNotif');
  if(tgN){
    if(!OBRA_PUSH.suportado()){
      /* iPhone no Safari (fora do app instalado) não expõe a API de push —
         em vez de esconder o painel, ensina o caminho */
      tgN.disabled = true;
      tgN.style.opacity = '.4';
      $('#ajNotifNota').textContent = OBRA_NATIVO.ehNativo()
        ? 'Notificações indisponíveis neste aparelho no momento.'
        : 'Pra receber notificações no iPhone: abra no Safari, '
          + 'toque em Compartilhar e "Adicionar à Tela de Início". Depois abra o app pelo '
          + 'ícone novo e ative aqui. Precisa de iOS 16.4 ou mais novo.';
    }else{
      Promise.all([OBRA_PUSH.inscrito(), OBRA_PUSH.permissao()]).then(([inscrito, perm]) => {
        const on = inscrito && perm === 'granted';
        tgN.classList.toggle('on', on);
        tgN.setAttribute('aria-checked', String(on));
      }).catch(err => registraErro('push-estado', err && err.message, err && err.stack));
      tgN.onclick = async () => {
        const nota = $('#ajNotifNota');
        nota.textContent = NOTIF_NOTA_PADRAO;
        try{
          if(await OBRA_PUSH.inscrito()){
            await OBRA_PUSH.desativar();
          }else{
            const ok = await OBRA_PUSH.ativar();
            if(!ok) nota.textContent = OBRA_NATIVO.ehNativo()
              ? 'Permissão negada. Libere em Ajustes do iPhone › Custta › Notificações e tente de novo.'
              : 'Permissão negada. Libere as notificações nas configurações do navegador e tente de novo.';
          }
        }catch(err){
          nota.textContent = 'Não deu pra ativar agora. Tente de novo.';
        }
        renderAjustes();
      };
    }
  }

  const inp = $('#ajTaxa');
  if(document.activeElement !== inp)
    inp.value = String(db.config.taxaMensal).replace('.',',');
  inp.onchange = ()=>{
    // antes de ver os dados nada muda: a gravação seria recusada e o servidor desfaria a tela
    if(!dadosCarregados){ inp.value = String(db.config.taxaMensal).replace('.',','); avisaNaoCarregado(); return; }
    const v = parseNum(inp.value);
    if(!(v>0 && v<=20)){
      toast('Informe uma taxa maior que 0 e até 20% ao mês.', 'erro');
      inp.value = String(db.config.taxaMensal).replace('.',',');
      return;
    }
    db.config.taxaMensal = v;
    inp.value = String(db.config.taxaMensal).replace('.',',');
    save(); renderAll();
  };

  const ul = $('#ajTopicos');
  ul.innerHTML = db.config.topicosCustom.length ? '' : emptyBlock(ICON('etiqueta'),'Nenhum tópico próprio ainda.');
  db.config.topicosCustom.forEach(t=>{
    const li = el('li');
    li.innerHTML = `<div class="av ic-brand">${ICON('etiqueta')}</div>
      <div class="li-main"><div class="t">${escapeHtml(t.nm)}</div></div>`;
    const del = el('button','li-del','×');
    del.setAttribute('aria-label','Apagar tópico');
    del.onclick = async()=>{
      if(!dadosCarregados){ avisaNaoCarregado(); return; }
      const emUso = db.obras.some(o=>o.gastos.some(g=>g.topico===t.id));
      if(emUso){ await OBRA_CONFIRM.avisar('Este tópico tem gastos lançados. Mova ou apague os gastos antes.'); return; }
      const noOrcamento = db.obras.some(o=>o.orcamento && o.orcamento.modo==='topicos' && o.orcamento.topicos && o.orcamento.topicos[t.id]>0);
      if(noOrcamento){ await OBRA_CONFIRM.avisar('Este tópico está no orçamento de uma obra. Tire o valor dele no orçamento antes de apagar.'); return; }
      if(await OBRA_CONFIRM.perguntar(`Remover o tópico “${t.nm}”?`, { confirmar:'Remover' })){
        db.config.topicosCustom = db.config.topicosCustom.filter(x=>x.id!==t.id);
        save(); renderAll();
      }
    };
    li.appendChild(del);
    ul.appendChild(li);
  });

  $('#ajAddTopico').onclick = ()=>{
    if(!dadosCarregados){ avisaNaoCarregado(); return; } // o nome digitado fica no campo
    const nm = $('#ajNovoTopico').value.trim();
    if(!nm){ $('#ajNovoTopico').focus(); return; }
    if(!textoValido(nm, 'topico', $('#ajNovoTopico'))) return;
    db.config.topicosCustom.push({ id:'c_'+uid(), nm, ic:'etiqueta' });
    $('#ajNovoTopico').value = '';
    save(); renderAll();
  };

  $('#ajSair').onclick = ()=>$('#btnSair').click();
}

/* ---------- modal / formulários ---------- */
const backdrop = $('#backdrop'), sheet = $('#sheet');

/* iPhone: abrir o teclado NÃO encolhe a viewport de elementos fixed, então o sheet
   continua com a altura da tela cheia e metade dele fica atrás do teclado.
   visualViewport dá a área realmente visível; o CSS usa --vvh/--vvtop. */
const vv = window.visualViewport;
let sheetScrollY=null;
let focusSheetTimer;
function manterCampoVisivel(){
  const campo=document.activeElement;
  if(!backdrop.classList.contains('show') || !sheet.contains(campo) || !campo.matches('input,select,textarea')) return;
  const caixa=sheet.getBoundingClientRect(), alvo=campo.getBoundingClientRect();
  const rodape=sheet.querySelector('.sheet-actions');
  const limite=rodape ? Math.min(caixa.bottom-16,rodape.getBoundingClientRect().top-12) : caixa.bottom-16;
  if(alvo.bottom>limite) sheet.scrollTop+=alvo.bottom-limite;
  else if(alvo.top<caixa.top+16) sheet.scrollTop-=caixa.top+16-alvo.top;
}
function syncViewport(){
  if(!vv) return;
  const r = document.documentElement.style;
  r.setProperty('--vvh', vv.height + 'px');
  r.setProperty('--vvtop', vv.offsetTop + 'px');
  clearTimeout(focusSheetTimer);
  focusSheetTimer=setTimeout(manterCampoVisivel,80);
}
if(vv){
  vv.addEventListener('resize', syncViewport);
  vv.addEventListener('scroll', syncViewport);
  syncViewport();
}

/* Saída da sheet pelo mesmo caminho da entrada: o estado (show, sheet-open, rolagem) muda na
   hora; só a pintura dura a mola (classe .saindo, sem cliques). Abrir outra sheet no meio
   cancela a saída — a nova assume a partir de onde a velha estava. */
let saidaTimer = null;
function terminaSaida(){
  clearTimeout(saidaTimer); saidaTimer = null;
  backdrop.classList.remove('saindo');
}
/* Sheet que passa de 88% da altura da janela vira folha cheia (encosta nas bordas, fundo
   sólido), como o detent grande do iOS; volta a flutuar só abaixo de 84%, para não oscilar
   quando a própria troca de forma muda a altura. Mede pela janela, não pelo visualViewport:
   o teclado abrindo não pode trocar a forma da sheet enquanto se digita. Roda duas vezes:
   síncrona no openSheet (mede o conteúdo inicial) e um quadro depois (requestAnimationFrame),
   quando o ResizeObserver dispara por causa de conteúdo que ainda estava carregando. */
function medeSheet(){
  if(!backdrop.classList.contains('show')) return;
  const r = sheet.scrollHeight / window.innerHeight;
  if(r > 0.88) backdrop.classList.add('cheia');
  else if(r < 0.84) backdrop.classList.remove('cheia');
}
/* medeSheet muda classe (cheia) dentro do próprio callback do observer; mexer no DOM ali dentro,
   com vários filhos observados de uma vez, faz o Chrome avisar "loop completed with undelivered
   notifications" (a mudança de largura da folha cheia reabre a rodada de medição). Adiar pro
   próximo quadro tira a mutação de dentro do próprio ciclo de entrega do ResizeObserver. */
const observaSheet = 'ResizeObserver' in window ? new ResizeObserver(() => requestAnimationFrame(medeSheet)) : null;
addEventListener('resize', medeSheet);

function openSheet(html){
  terminaSaida();
  if(sheetScrollY===null){
    sheetScrollY=window.scrollY;
    document.documentElement.style.setProperty('--sheet-scroll-top',`${-sheetScrollY}px`);
  }
  sheet.innerHTML = html;
  backdrop.classList.remove('cheia');
  backdrop.classList.add('show');
  document.body.classList.add('sheet-open');
  sheet.scrollTop = 0;
  syncViewport();
  medeSheet();
  if(observaSheet){ observaSheet.disconnect(); for(const filho of sheet.children) observaSheet.observe(filho); }
}
function closeSheet(){
  clearTimeout(focusSheetTimer);
  if(sheet.contains(document.activeElement)) document.activeElement.blur();
  const estavaAberta = backdrop.classList.contains('show');
  backdrop.classList.remove('show');
  document.body.classList.remove('sheet-open');
  if(observaSheet) observaSheet.disconnect();
  if(estavaAberta){
    const dur = (parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--mola-dur')) || 0) * 1000;
    terminaSaida();
    if(dur > 0){ backdrop.classList.add('saindo'); saidaTimer = setTimeout(terminaSaida, dur + 50); }
  }
  if(sheetScrollY!==null){
    const posicao=sheetScrollY; sheetScrollY=null;
    document.documentElement.style.removeProperty('--sheet-scroll-top');
    window.scrollTo(0,posicao);
  }
}

/* Ajusta somente o scroll interno necessário, sem centralizar o campo nem
   deslocar horizontalmente a página quando o teclado altera a viewport. */
sheet.addEventListener('focusin', ()=>{
  clearTimeout(focusSheetTimer);
  focusSheetTimer=setTimeout(manterCampoVisivel,80);
});

/* toast de feedback rápido pós-ação (ex: gasto lançado) */
const toastWrap = $('#toastWrap');
function toast(msg, tipo){
  const t = el('div', 'toast' + (tipo === 'erro' ? ' erro' : ''));
  t.innerHTML = `${ICON(tipo === 'erro' ? 'alerta' : 'check')}<span></span>`;
  t.querySelector('span').textContent = msg;
  toastWrap.appendChild(t);
  setTimeout(()=>{
    t.classList.add('out');
    t.addEventListener('animationend', ()=>t.remove(), {once:true});
  }, 2200);
}
backdrop.onclick = e=>{ if(e.target===backdrop) closeSheet(); };
document.addEventListener('keydown', e=>{ if(e.key==='Escape' && backdrop.classList.contains('show')) closeSheet(); });

/* Folha do orçamento: só o total, ou valor por tópico (fixos e próprios).
   O que o Salvar grava vem do dados.js (orcamentoGravado): só o modo ativo, o que a folha
   não mostra fica, e salvar tudo vazio tira o orçamento da obra. */
function formOrcamento(obraId){
  const o = obraById(obraId);
  if(!o) return;
  const atual = o.orcamento || null;
  let modo = atual && atual.modo === 'topicos' ? 'topicos' : 'total';
  const valTop = (atual && atual.modo === 'topicos' && atual.topicos) || {};
  const campos = topicos().map(t => `
      <label class="orc-campo"><span>${escapeHtml(t.nm)}</span>
        <input data-top="${escapeHtml(t.id)}" inputmode="decimal" placeholder="sem valor" autocomplete="off" value="${valTop[t.id] ? OBRA_CALC.numParaCampo(valTop[t.id]) : ''}"></label>`).join('');
  openSheet(`
    <h3>Orçamento da obra</h3>
    <div class="seg" role="group" aria-label="Tipo de orçamento">
      <button type="button" data-modo="total">Só o total</button>
      <button type="button" data-modo="topicos">Por tópico</button>
    </div>
    <div class="field" id="orcTotalWrap"><label for="orcTotal">Orçamento total</label>
      <div class="money"><b>R$</b><input id="orcTotal" inputmode="decimal" placeholder="0,00" autocomplete="off" value="${atual && atual.modo === 'total' ? OBRA_CALC.numParaCampo(atual.total) : ''}"></div></div>
    <div id="orcTopWrap">
      <div class="orc-campos">${campos}</div>
      <div class="orc-soma"><span>Total</span><b id="orcSoma" aria-live="polite"></b></div>
      <p class="orc-dica">Tópico sem valor não entra na comparação.</p>
    </div>
    ${atual ? '<button type="button" class="btn ghost orc-tirar" id="orcTirar">Tirar orçamento</button>' : ''}
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Salvar</button>
    </div>`);
  const entradas = [...sheet.querySelectorAll('#orcTopWrap input[data-top]')];
  const numerosDaFolha = () => entradas.map(i => parseNum(i.value));
  const pintaSoma = () => {
    $('#orcSoma').textContent = money(OBRA_CALC.somaTopicosOrc(numerosDaFolha()));
  };
  const aplicaModo = m => {
    modo = m;
    sheet.querySelectorAll('.seg button').forEach(b => {
      const on = b.dataset.modo === m;
      b.classList.toggle('on', on);
      b.setAttribute('aria-pressed', String(on));
    });
    $('#orcTotalWrap').classList.toggle('hidden', m !== 'total');
    $('#orcTopWrap').classList.toggle('hidden', m !== 'topicos');
    // "só o total" com o campo vazio ganha a soma dos tópicos (salvar ainda grava só o modo ativo)
    if(m === 'total') $('#orcTotal').value = OBRA_CALC.totalPreenchidoOrc($('#orcTotal').value, numerosDaFolha());
  };
  sheet.querySelectorAll('.seg button').forEach(b => { b.onclick = () => aplicaModo(b.dataset.modo); });
  maskMoney('#orcTotal');
  entradas.forEach(i => { maskMoney(i); i.addEventListener('input', pintaSoma); });
  aplicaModo(modo);
  pintaSoma();
  // relê a obra no toque: um snapshot com a folha aberta troca os objetos do db
  const aplica = gravar => {
    const oo = obraById(obraId);
    if(oo){ const novo = gravar(oo.orcamento); if(novo) oo.orcamento = novo; else delete oo.orcamento; save(); }
    closeSheet(); renderAll();
  };
  $('#cCancel').onclick = closeSheet;
  $('#cSave').onclick = () => {
    const total = parseNum($('#orcTotal').value);
    const valores = {};
    entradas.forEach(i => { valores[i.dataset.top] = parseNum(i.value); });
    aplica(antigo => OBRA_DADOS.orcamentoGravado(antigo, modo, total, valores));
  };
  const tirar = $('#orcTirar');
  if(tirar) tirar.onclick = async () => {
    if(await OBRA_CONFIRM.perguntar('Tirar o orçamento desta obra? Os gastos continuam como estão.', { confirmar:'Tirar orçamento' })) aplica(() => null);
  };
}

function formNovaObra(){
  if(!dadosCarregados){ avisaNaoCarregado(); return; }
  // todas as entradas passam por aqui (+, "+ Nova obra" e o + sem obra aberta): a 301ª obra as rules recusam
  const limite = OBRA_DADOS.avisoLimiteDeObras(db.obras.length);
  if(limite){ OBRA_CONFIRM.avisar(`${limite.titulo}. ${limite.texto}`); return; }
  openSheet(`
    <h3>Nova obra</h3>
    <div class="field"><label>Nome da obra</label><input id="fNome" maxlength="120" placeholder="Ex: Casa Alphaville" autocomplete="off"></div>
    <div class="field"><label>Começou em</label><input id="fData" type="date" value="${todayISO()}"></div>
    <div class="field"><label>Valor estimado de venda (opcional)</label><div class="money"><b>R$</b><input id="fEst" inputmode="decimal" placeholder="0,00" autocomplete="off"></div></div>
    <div class="field"><label for="fOrc">Orçamento total (opcional)</label><div class="money"><b>R$</b><input id="fOrc" inputmode="decimal" placeholder="0,00" autocomplete="off"></div></div>
    <div class="field"><label for="fArea">Área construída em m²</label><input id="fArea" inputmode="decimal" placeholder="Ex: 320" autocomplete="off" required aria-describedby="fAreaErro">
      <span class="field-error hidden" id="fAreaErro">Informe área construída maior que zero.</span></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Criar obra</button>
    </div>`);
  maskMoney('#fEst');
  maskMoney('#fOrc');
  /* No toque o foco abre o teclado na hora e o sheet encolhe até o teclado: só os
     primeiros campos aparecem e a Área (obrigatória) fica escondida. Lá o sheet abre
     inteiro, sem campo selecionado; com teclado físico o nome já vem em foco. */
  if(!matchMedia('(pointer:coarse)').matches) $('#fNome').focus();
  $('#fArea').addEventListener('input',()=>{
    $('#fAreaErro').classList.add('hidden');
    $('#fArea').removeAttribute('aria-invalid');
  });
  $('#cCancel').onclick = closeSheet;
  $('#cSave').onclick = ()=>{
    const campos = { nome:$('#fNome').value.trim(), dataInicio:$('#fData').value, valorEstimadoVenda:parseNum($('#fEst').value),
      areaM2:parseNum($('#fArea').value), orcamento:parseNum($('#fOrc').value) };
    const erro = OBRA_DADOS.conferirObra(campos, true);
    if(erro?.erro==='nome'){ if(erro.mensagem) toast(erro.mensagem, "erro"); $('#fNome').focus(); return; }
    if(erro?.erro==='area'){
      $('#fAreaErro').textContent = erro.mensagem;
      $('#fAreaErro').classList.remove('hidden');
      $('#fArea').setAttribute('aria-invalid','true');
      $('#fArea').focus();
      return;
    }
    const o = OBRA_DADOS.obraNova(campos, uid(), todayISO());
    db.obras.push(o); save(); closeSheet(); renderAll(); openObra(o.id);
  };
}
$('#btnNovaObra').onclick = formNovaObra;

/* FAB: lançar gasto (ou criar 1ª obra) */
$('#fab').onclick = ()=>{
  if($('#fab').dataset.acao==='obra'){ formNovaObra(); return; }
  const abertas = db.obras.filter(o=>o.fase!=='vendida');
  if(!abertas.length){ formNovaObra(); return; }
  const atual = obraAberta && obraById(obraAberta);
  const oid = atual && atual.fase!=='vendida' ? obraAberta : null;
  // valor primeiro: teclado do app, depois o resto do form
  TECLADO.abrir({ valorInicial: 0, onConfirm: v => formGasto(oid, null, v) });
};

/* ---------- instalar PWA ---------- */
let deferredPrompt = null;
window.addEventListener('beforeinstallprompt',e=>{ e.preventDefault(); if(OBRA_NATIVO.ehNativo()) return; deferredPrompt=e; $('#installHint').classList.remove('hidden'); });
$('#installBtn').onclick = async()=>{
  if(!deferredPrompt) return;
  deferredPrompt.prompt(); await deferredPrompt.userChoice; deferredPrompt=null;
  $('#installHint').classList.add('hidden');
};
window.addEventListener('appinstalled',()=>$('#installHint').classList.add('hidden'));

/* Aberturas que dependem dos dados reais (toque em notificação, restauração de estado)
   e a criação de obra só acontecem depois de ver os dados da conta: snapshot do
   servidor, ou do cache com o documento. Antes disso db está vazio, e num aparelho
   novo sem rede o cache vazio não prova que a conta não tem obra. */
let dadosCarregados = false;
/* Com rede, o primeiro snapshot só está demorando (o SDK só entrega o cache vazio
   depois de se declarar offline); sem rede, é preciso conectar. */
function avisaNaoCarregado(){
  toast(navigator.onLine === false
    ? 'Conecte à internet para carregar suas obras antes de lançar.'
    : 'Carregando suas obras, tente em instantes.', 'erro');
}
let obraDaNotificacao; // undefined = nada pendente; null = abrir Início
function depoisDoPrimeiroSnapshot(){
  if(!dadosCarregados) return;
  if(obraDaNotificacao !== undefined){
    estadoRestaurado = true; // notificação vence a restauração
    const id = obraDaNotificacao; obraDaNotificacao = undefined;
    if(id && obraById(id)) openObra(id);
    else { obraAberta = null; showView('inicio'); renderAll(); }
    return;
  }
  restauraEstado();
}
OBRA_PUSH.aoAbrirNotificacao(id => { obraDaNotificacao = id; depoisDoPrimeiroSnapshot(); });

/* ---------- go: espera auth e liga o tempo real ---------- */
function bootCloud(){
  let tokenFcmSincronizado = false; // uma vez por login — não a cada snapshot
  CLOUD.onAuth(user=>{
    if(unwatch){ unwatch(); unwatch=null; }
    if(!user){
      dadosCarregados = false;
      tokenFcmSincronizado = false;
      try{ localStorage.removeItem(ESTADO_KEY); }catch(e){}
      estadoRestaurado = false;
      obraDaNotificacao = undefined; // notificação de outra conta não pode abrir obra desta
      conviteNotifUid=null; esconderConviteNotif();
      closeSheet(); sheet.textContent = '';
      db = empty(); obraAberta = null; showView('inicio'); renderAll(); return;
    }
    atualizarConviteNotif(user);
    renderAvisoEmail(user); // conta nova tem blob vazio = db inicial, e o watchDados não re-renderiza

    /* Aqui existia uma migração dos dados antigos de localStorage pra nuvem.
       Removida: ela varria as chaves obras_data_v1* de QUALQUER pessoa que já
       tivesse usado este navegador e copiava pra conta logada no momento —
       num aparelho compartilhado, isso levava as obras de um pro outro. */

    dadosCarregados = false; // a conta que entrou ainda não teve os dados vistos
    unwatch = CLOUD.watchDados((blob, meta)=>{
      if(meta.localDirty) return; // preserva edições desta sessão; restaura cache após reabrir
      /* meta.copia: o que só estava na memória quando o cliente do Firestore morreu
         (cloud.js). Na primeira leitura da conta volta para a tela e para a fila do SDK. */
      const novo = normaliza(meta.copia || blob);
      /* A mesma regra do saveDados no cloud.js: cache sem documento não é dado visto.
         Depois de visto não volta atrás (conta nova que ouviu "não existe" e perdeu a rede). */
      const carregou = !dadosCarregados && (!meta.fromCache || blob !== null);
      if(carregou) dadosCarregados = true;
      // conteúdo igual: não troca os objetos (Firestore devolve chaves em ordem diferente)
      if(canon(novo) !== canon(db)){
        db = novo;
        if(obraAberta && !novo.obras.some(o=>o.id===obraAberta)){ obraAberta=null; showView('inicio'); }
        renderAll();
      }else if(carregou) renderInicio(); // conta nova: o "não existe" do servidor não muda o db, mas a lista sai do "Carregando…"
      if(meta.copia){
        save();
        toast('O app recarregou para salvar seus últimos lançamentos.');
      }
      if(!tokenFcmSincronizado){
        tokenFcmSincronizado = true;
        OBRA_PUSH.sincronizarToken?.(); // no-op na web; nativo troca o token se o FCM já rotacionou o antigo
      }
      depoisDoPrimeiroSnapshot();
    });
  });
}
/* Escrita que falhou na nuvem tem que aparecer pro usuário — uma vez a cada
   30s, senão uma queda de rede vira chuva de toast. */
let ultimoAvisoErro = 0;
function avisoRaro(msg){
  const agora = Date.now();
  if(agora - ultimoAvisoErro < 30000) return;
  ultimoAvisoErro = agora;
  toast(msg, 'erro');
}
window.addEventListener('cloud-erro', e=>{
  const { code, terminal } = e.detail;
  // recusa local antes de ver os dados: nada foi para a fila, o gesto precisa de resposta
  if(code === 'nao-carregado'){ avisaNaoCarregado(); return; }
  /* Cliente do Firestore morto e a recarga automática já gasta: o lançamento está na
     cópia, que fechar o app apaga. toast(), não avisoRaro: a cada lançamento a tela responde. */
  if(code === 'cliente-morto'){
    toast('Seus últimos lançamentos ainda não foram para a nuvem. Toque em “Não salvou” para enviar. Não feche o app antes.', 'erro');
    return;
  }
  const msg = code === 'limite'
    ? 'Não salvou: limite de dados atingido. Reduza os dados e tente novamente.'
    : terminal
      ? 'Não salvou na nuvem. Confira sua conexão e conta; toque no aviso para tentar novamente.'
      : 'Sem salvar na nuvem agora — vamos tentar de novo sozinhos.';
  if(terminal) toast(msg, 'erro'); else avisoRaro(msg);
});

/* ---------- pill de sincronização ----------
   Fica invisível no caso normal. A fila de escrita mora em cloud.js; aqui só
   pinta o estado que ela publica. */
const syncPill = $('#syncPill');
const SYNC_VISUAL = {
  salvando:  { rotulo: 'Salvando…',   marca: '<span class="spin"></span>' },
  repetindo: { rotulo: 'Salvando…',   marca: '<span class="spin"></span>' },
  offline:   { rotulo: 'Sem conexão', marca: '<span class="ponto"></span>' },
  erro:      { rotulo: 'Não salvou',  marca: '<span class="ponto"></span>' },
};
function renderSync(estado, origem){
  if(!syncPill) return;
  const v = SYNC_VISUAL[estado];
  syncPill.classList.toggle('hidden', !v);
  syncPill.classList.toggle('erro', estado === 'erro');
  if(!v) return;
  /* Cliente do Firestore morto com lançamento esperando: tentar de novo não adianta,
     só recarregar. Decide pelo CLOUD, não pelo evento: online e offline repintam sem
     code nem origem. */
  const morto = estado === 'erro' && !!window.CLOUD?.clienteMorto?.();
  syncPill.innerHTML = `${v.marca}<span class="rotulo"></span>`;
  syncPill.querySelector('.rotulo').textContent = estado === 'erro' && origem === 'leitura' && !morto ? 'Não sincronizou' : v.rotulo;
  syncPill.title = morto
    ? 'Seus últimos lançamentos ainda não foram para a nuvem. Toque para enviar.'
    : estado === 'erro'
      ? 'Não foi possível sincronizar. Toque para tentar de novo.'
      : v.rotulo;
  syncPill.onclick = morto
    ? ()=>{ if(!CLOUD.recarregar()) toast('Não deu para guardar seus últimos lançamentos neste aparelho. Anote-os antes de fechar o app.', 'erro'); }
    : estado === 'erro'
      ? ()=>{ toast('Tentando de novo…'); CLOUD.tentarDeNovo(); }
      : null;
}
window.addEventListener('cloud-estado', e=>{
  const { estado, origem, code } = e.detail;
  renderSync(estado, origem);
  if(estado === 'erro' && origem === 'leitura')
    avisoRaro('Não consegui ler seus dados da nuvem agora (' + code + ').');
});
/* Rede caindo com nada pendente também precisa aparecer: cloud.js publica o
   estado, mas o primeiro paint acontece antes de qualquer evento. */
window.addEventListener('offline', ()=>renderSync(window.CLOUD ? CLOUD.estado() : 'offline'));
window.addEventListener('online',  ()=>renderSync(window.CLOUD ? CLOUD.estado() : 'ocioso'));

/* ---------- rede de segurança de erro ----------
   Anel local complementa Sentry; falhas do monitoramento não afetam o app. */
const DIAG_MAX = 20;
const diag = [];
function registraErro(origem, msg, stack){
  if(origem !== 'window' && origem !== 'promise') window.CUSTTA_MONITOR?.capture(origem, msg, stack);
  diag.push({ hora: new Date().toISOString(), origem, msg: String(msg || ''), stack: String(stack || '') });
  if(diag.length > DIAG_MAX) diag.shift();
  console.error('[custta]', origem, msg);
}
window.OBRA_DIAG = { erros: () => diag.slice(), registra: registraErro };
(window.OBRA_ERROS_INICIAIS || []).forEach(e=>registraErro(e.origem, e.msg, e.stack));
delete window.OBRA_ERROS_INICIAIS;
/* "Feche e abra" apaga o que ainda não chegou à fila do SDK: com lançamento em risco o
   aviso genérico não sai, qualquer que seja o erro; a pílula diz o que fazer. */
function avisoDeErro(){
  if(window.CLOUD?.dadoEmRisco?.()) return;
  avisoRaro('Algo deu errado aqui dentro. Se atrapalhar, feche e abra o app.');
}
window.addEventListener('error', e=>{
  registraErro('window', e.message, e.error && e.error.stack);
  avisoDeErro();
});
window.addEventListener('unhandledrejection', e=>{
  const r = e.reason;
  registraErro('promise', (r && (r.message || r.code)) || r, r && r.stack);
  avisoDeErro();
});

function ligaSync(){ renderSync(CLOUD.estado()); }
if(window.CLOUD){ bootCloud(); ligaSync(); }
else window.addEventListener('cloud-pronto', ()=>{ bootCloud(); ligaSync(); });

/* ---------- app nativo: barra de status, splash e segundo plano ---------- */
if(OBRA_NATIVO.ehNativo()){
  OBRA_NATIVO.barraStatus(temaClaro());
  const esconder = ()=>OBRA_NATIVO.esconderSplash();
  if(window.CLOUD) CLOUD.ready.then(esconder, esconder);
  else window.addEventListener('cloud-pronto', ()=>CLOUD.ready.then(esconder, esconder), { once:true });
  setTimeout(esconder, 8000); // teto: primeira abertura sem rede não pode prender no splash
  // iOS pode matar o app em segundo plano: entrega ao SDK o que estiver pendente
  OBRA_NATIVO.aoSegundoPlano(()=>{ if(window.CLOUD) CLOUD.tentarDeNovo().catch(()=>{}); });

  /* Atualização só pela App Store: avisa quando a produção declara versão maior. */
  const VERSAO_DISPENSADA = 'custta-versao-dispensada';
  fetch('https://app-construcao-civil.vercel.app/versao.json', { cache:'no-store' })
    .then(r => r.ok ? r.json() : null)
    .then(v => {
      if(!v || !v.loja || !/^itms-apps:\/\//.test(v.loja)) return;
      if(!OBRA_CALC.versaoMaior(v.versao, window.APP_VERSAO)) return;
      let dispensada = null; try{ dispensada = localStorage.getItem(VERSAO_DISPENSADA); }catch(e){}
      if(dispensada === v.versao) return;
      $('#ajVersaoLoja').href = v.loja;
      $('#ajVersao').classList.remove('hidden');
      $('#ajVersaoFechar').onclick = ()=>{
        try{ localStorage.setItem(VERSAO_DISPENSADA, v.versao); }catch(e){}
        $('#ajVersao').classList.add('hidden');
      };
    })
    .catch(()=>{}); // offline: sem aviso, sem erro
}

renderAll(); // primeiro paint (vazio) enquanto a nuvem responde

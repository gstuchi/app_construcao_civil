/* Minhas Obras — controle de custos por obra. PWA offline, localStorage, vanilla JS. */
'use strict';

/* ---------- estado ---------- */

const TOPICOS = [
  {id:'terreno',    nm:'Terreno',       ic:'🗺️'},
  {id:'projeto',    nm:'Projeto/Docs',  ic:'📐'},
  {id:'fundacao',   nm:'Fundação',      ic:'⛏️'},
  {id:'estrutura',  nm:'Estrutura',     ic:'🏗️'},
  {id:'alvenaria',  nm:'Alvenaria',     ic:'🧱'},
  {id:'telhado',    nm:'Telhado',       ic:'🏠'},
  {id:'eletrica',   nm:'Elétrica',      ic:'⚡'},
  {id:'hidraulica', nm:'Hidráulica',    ic:'🚿'},
  {id:'esquadrias', nm:'Esquadrias',    ic:'🚪'},
  {id:'revest',     nm:'Revestimentos', ic:'🪨'},
  {id:'pintura',    nm:'Pintura',       ic:'🎨'},
  {id:'paisagismo', nm:'Paisagismo',    ic:'🌳'},
  {id:'maoobra',    nm:'Mão de obra',   ic:'👷'},
  {id:'outros',     nm:'Outros',        ic:'📦'},
];
const PIE = ['--c1','--c2','--c3','--c4','--c5','--c6','--c7','--c8'];
const FASES = {
  construcao: {nm:'Em construção',    ic:'🏗️', cls:'pend'},
  pronta:     {nm:'Pronta · à venda', ic:'🏠', cls:'blue'},
  vendida:    {nm:'Vendida',          ic:'✅', cls:'ok'},
};

const empty = () => ({obras:[], config:{taxaMensal:1, topicosCustom:[]}});
let db = empty();
let obraAberta = null;   // id da obra no detalhe
let tab = 'inicio';
let unwatch = null;

function normaliza(d){
  return d && typeof d==='object'
    ? {...empty(), ...d, config:{...empty().config, ...(d.config||{})}}
    : empty();
}
function save(){ CLOUD.saveDados(db); }
const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2,6);

const topicos = () => [...TOPICOS, ...db.config.topicosCustom];
const TOP_MAP = () => Object.fromEntries(topicos().map(t=>[t.id,t]));
const taxa = () => db.config.taxaMensal;

/* ---------- helpers ---------- */
const BRL = new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'});
const money = n => BRL.format(n||0);
const moneyShort = n => {
  const a = Math.abs(n), s = n<0 ? '-' : '';
  if(a>=1e6)  return s+'R$ '+(a/1e6).toFixed(a>=1e7?1:2).replace('.',',')+' mi';
  if(a>=1000) return s+'R$ '+(a/1000).toFixed(a>=10000?0:1).replace('.',',')+' mil';
  return money(n);
};
const MESAB = ['jan','fev','mar','abr','mai','jun','jul','ago','set','out','nov','dez'];
const todayISO = () => new Date().toISOString().slice(0,10);
const fmtData = iso => { const [y,m,d] = iso.split('-'); return `${d}/${m}/${y.slice(2)}`; };
const parseNum = v => {
  if(typeof v==='number') return v;
  v = (v||'').toString().trim().replace(/[^\d,.-]/g,'');
  if(v.includes(',')) v = v.replace(/\./g,'').replace(',','.');
  const n = parseFloat(v); return isNaN(n) ? 0 : n;
};
const $ = s => document.querySelector(s);
const el = (tag,cls,html)=>{ const e=document.createElement(tag); if(cls)e.className=cls; if(html!=null)e.innerHTML=html; return e; };
function escapeHtml(s){ return (s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function emptyBlock(icon,msg){ return `<div class="empty"><div class="big">${icon}</div><p>${msg}</p></div>`; }
function fmtMeses(m){
  if(m < 1) return 'começando';
  const r = Math.round(m);
  return r + (r===1 ? ' mês' : ' meses');
}
const obraById = id => db.obras.find(o=>o.id===id);

/* ---------- navegação ---------- */
function showView(v){
  tab = v;
  document.querySelectorAll('section.view').forEach(s=>s.classList.remove('active'));
  $('#v-'+v).classList.add('active');
  document.querySelectorAll('button[data-tab]').forEach(x=>x.classList.toggle('on',x.dataset.tab===v));
  window.scrollTo({top:0});
}
document.querySelectorAll('button[data-tab]').forEach(b=>{
  b.onclick = ()=>{ obraAberta=null; showView(b.dataset.tab); renderAll(); };
});
$('#btnVoltar').onclick = ()=>{ obraAberta=null; showView('inicio'); renderAll(); };
function openObra(id){ obraAberta=id; showView('obra'); renderObra(); }

/* ---------- render ---------- */
function renderAll(){
  renderInicio();
  renderAjustes();
  renderSimula();
  if(obraAberta) renderObra();
}

/* ===== INÍCIO ===== */
function renderInicio(){
  const hoje = todayISO();
  const abertas = db.obras.filter(o=>o.fase!=='vendida');
  const bruto = abertas.reduce((s,o)=>s+OBRA_CALC.totalBruto(o),0);
  const corr  = abertas.reduce((s,o)=>s+OBRA_CALC.totalCorrigido(o,taxa(),hoje),0);
  $('#kTotalBruto').textContent = money(bruto);
  $('#kTotalCorr').textContent = money(corr);
  $('#kTotalSub').textContent = abertas.length
    ? `Juros embutidos: +${money(corr-bruto)} · ${abertas.length} obra${abertas.length>1?'s':''} em andamento`
    : 'Nenhuma obra em andamento';

  const arr = [...db.obras].sort((a,b)=>
    ((a.fase==='vendida')-(b.fase==='vendida')) || b.dataInicio.localeCompare(a.dataInicio));
  $('#obraCount').textContent = arr.length ? `${arr.length} obra${arr.length>1?'s':''}` : '';
  const list = $('#obrasList');
  list.innerHTML = arr.length ? '' : emptyBlock('🏗️','Nenhuma obra ainda.<br>Toque em “+ Nova obra” pra começar.');
  arr.forEach(o=>{
    const f = FASES[o.fase];
    const li = el('li');
    li.style.cursor = 'pointer';
    li.innerHTML = `
      <div class="av ic-brand">${f.ic}</div>
      <div class="li-main">
        <div class="t">${escapeHtml(o.nome)}</div>
        <div class="s"><span class="tag ${f.cls}">${f.nm}</span> · ${fmtMeses(OBRA_CALC.mesesDeObra(o,hoje))}</div>
      </div>
      <div class="li-val">${moneyShort(OBRA_CALC.totalBruto(o))}</div>`;
    li.onclick = ()=>openObra(o.id);
    list.appendChild(li);
  });

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
        <i class="hb-corr"  style="width:${(r.c/max*100).toFixed(1)}%"></i>
        <i class="hb-bruto" style="width:${(r.b/max*100).toFixed(1)}%"></i>
      </div>
      <div class="hbar-vl">${moneyShort(r.b)} gasto · ${moneyShort(r.c)} corrigido</div>
    </div>`).join('');
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

  let head = `
    <div class="panel">
      <h2 style="font-size:19px">${f.ic} ${escapeHtml(o.nome)}
        <button class="li-del" id="oEdit" title="Editar obra" style="font-size:15px">✏️</button></h2>
      <div style="font-size:13.5px;color:var(--muted)">
        <span class="tag ${f.cls}">${f.nm}</span> ·
        começou em ${fmtData(o.dataInicio)} · ${fmtMeses(OBRA_CALC.mesesDeObra(o,hoje))}
      </div>
    </div>`;

  let resumo = `
    <div class="cards">
      <div class="card saldo big">
        <div class="k-label"><span class="k-ic">💸</span> Total gasto</div>
        <div class="duo">
          <div class="d-cell"><div class="d-lbl">Bruto</div><div class="d-val">${money(bruto)}</div></div>
          <div class="d-cell"><div class="d-lbl">Corrigido pelo banco</div><div class="d-val" id="oCorr">${money(corr)}</div></div>
        </div>
        <div class="k-sub">Juros embutidos até ${o.venda?'a venda':'hoje'}: +${money(corr-bruto)}</div>
      </div>`;
  if(o.fase==='vendida' && lucro){
    resumo += `
      <div class="card">
        <div class="k-label"><span class="k-ic ic-green">↑</span> Lucro da venda</div>
        <div class="k-val sm ${lucro.bruto>=0?'pos':'neg'}">${money(lucro.bruto)}</div>
      </div>
      <div class="card">
        <div class="k-label"><span class="k-ic ic-blue">🏦</span> Acima do banco</div>
        <div class="k-val sm ${lucro.vsBanco>=0?'pos':'neg'}">${money(lucro.vsBanco)}</div>
      </div>
      <div class="card big">
        <div class="k-label"><span class="k-ic ic-brand">🤝</span> Vendida em ${fmtData(o.venda.data)}</div>
        <div class="k-val sm">${money(o.venda.valor)}</div>
      </div>`;
  } else if(o.valorEstimadoVenda){
    resumo += `
      <div class="card">
        <div class="k-label"><span class="k-ic ic-brand">🎯</span> Venda estimada</div>
        <div class="k-val sm">${moneyShort(o.valorEstimadoVenda)}</div>
      </div>
      <div class="card">
        <div class="k-label"><span class="k-ic ic-green">↑</span> Margem estimada</div>
        <div class="k-val sm ${o.valorEstimadoVenda-corr>=0?'pos':'neg'}">${moneyShort(o.valorEstimadoVenda-corr)}</div>
      </div>`;
  }
  resumo += `</div>`;

  let acoes = '<div class="obra-actions">';
  if(o.fase==='construcao') acoes += `<button class="btn primary" id="oPronta">🏠 Marcar como pronta</button>`;
  if(o.fase==='pronta') acoes += `
    <button class="btn primary" id="oVender">🤝 Registrar venda</button>
    <button class="btn ghost" id="oVoltarConstr">↩ Voltar pra construção</button>`;
  if(o.fase==='vendida') acoes += `<button class="btn ghost" id="oDesfazer">↩ Desfazer venda</button>`;
  if(o.gastos.length) acoes += `<button class="btn ghost" id="oRel">📄 Relatório</button>`;
  acoes += '</div>';

  const byTop = {};
  o.gastos.forEach(g=>{ byTop[g.topico]=(byTop[g.topico]||0)+g.valor; });
  const entries = Object.entries(byTop).sort((a,b)=>b[1]-a[1]);

  const graficos = `
    <div class="panel"><h2>Gastos por tópico</h2>
      <div class="donut-wrap">
        <div class="donut">
          <svg viewBox="0 0 36 36" width="132" height="132" id="oDonut"></svg>
          <div class="center"><small>Total</small><b id="oDonutTotal"></b></div>
        </div>
        <div class="legend" id="oDonutLeg"></div>
      </div>
    </div>
    <div class="panel"><h2>Gasto mês a mês</h2>${mbarsHtml(o)}</div>`;

  const lanc = `
    <div class="panel"><h2>Lançamentos <span class="muted">${o.gastos.length||''}</span></h2>
      <ul class="list" id="oGastos"></ul>
    </div>`;

  $('#obraBody').innerHTML = head + resumo + acoes + graficos + lanc;

  drawDonutObra(entries, bruto);
  const list = $('#oGastos');
  list.innerHTML = o.gastos.length ? '' : emptyBlock('🧾','Nenhum gasto lançado.<br>Toque no + pra lançar o primeiro.');
  [...o.gastos].sort((a,b)=>(b.data+b.id).localeCompare(a.data+a.id))
    .forEach(g=>list.appendChild(gastoRow(o,g)));

  $('#oEdit').onclick = ()=>formEditarObra(o);
  const on = (id,fn)=>{ const b=$(id); if(b) b.onclick=fn; };
  on('#oRel',          ()=>{ showView('relatorio'); renderRelatorio(); });
  on('#oPronta',       ()=>mudarFase(o,'pronta'));
  on('#oVender',       ()=>formVenda(o));
  on('#oVoltarConstr', ()=>mudarFase(o,'construcao'));
  on('#oDesfazer',     ()=>{ if(confirm('Desfazer a venda? A obra volta pra “Pronta”.')){ delete o.venda; o.fase='pronta'; save(); renderAll(); } });
}

function drawDonutObra(entries, total){
  const svg = $('#oDonut'), leg = $('#oDonutLeg');
  $('#oDonutTotal').textContent = moneyShort(total);
  if(!total){ svg.innerHTML=''; leg.innerHTML = `<div class="empty" style="padding:10px"><p>Sem gastos ainda</p></div>`; return; }
  const cs = getComputedStyle(document.documentElement);
  const R = 15.915, C = 2*Math.PI*R;
  let off = 0, paths = '';
  entries.forEach(([id,val],i)=>{
    const len = val/total*C;
    const color = cs.getPropertyValue(PIE[i%PIE.length]).trim();
    paths += `<circle cx="18" cy="18" r="${R}" fill="none" stroke="${color}" stroke-width="4.4"
      stroke-dasharray="${len} ${C-len}" stroke-dashoffset="${-off}" transform="rotate(-90 18 18)"></circle>`;
    off += len;
  });
  svg.innerHTML = paths;
  leg.innerHTML = '';
  const map = TOP_MAP();
  entries.slice(0,7).forEach(([id,val],i)=>{
    const t = map[id] || {nm:id, ic:'🏷️'};
    const color = cs.getPropertyValue(PIE[i%PIE.length]).trim();
    leg.appendChild(el('div','row',
      `<span class="dot" style="background:${color}"></span>
       <span class="nm">${t.ic} ${t.nm}</span>
       <span class="vl">${Math.round(val/total*100)}% · ${moneyShort(val)}</span>`));
  });
}

function mbarsHtml(o){
  const by = {};
  o.gastos.forEach(g=>{ const k=g.data.slice(0,7); by[k]=(by[k]||0)+g.valor; });
  const keys = Object.keys(by).sort().slice(-12);
  if(!keys.length) return emptyBlock('📅','Sem gastos ainda.');
  const max = Math.max(...keys.map(k=>by[k]));
  return '<div class="mbars">' + keys.map(k=>{
    const m = +k.split('-')[1];
    return `<div class="mb">
      <b>${moneyShort(by[k])}</b>
      <i style="height:${Math.max(3, by[k]/max*100).toFixed(0)}%"></i>
      <span>${MESAB[m-1]}</span></div>`;
  }).join('') + '</div>';
}

function gastoRow(o, g){
  const t = TOP_MAP()[g.topico] || {nm:g.topico||'Outros', ic:'🏷️'};
  const li = el('li');
  const suf = g.parcela ? ` (${g.parcela.n}/${g.parcela.de})` : '';
  const futura = g.data > todayISO(); // ISO ordena lexicograficamente
  const pIc = g.pagamento==='cartao' ? '💳 ' : g.pagamento==='pix' ? '⚡ ' : '';
  li.innerHTML = `
    <div class="av ic-brand">${t.ic}</div>
    <div class="li-main">
      <div class="t">${escapeHtml(g.descricao || t.nm)}${suf}</div>
      <div class="s">${pIc}${t.nm} · ${fmtData(g.data)}${futura?' <span class="tag pend">a vencer</span>':''}</div>
    </div>
    <div class="li-val neg">−${money(g.valor)}</div>`;
  li.querySelector('.li-main').style.cursor = 'pointer';
  li.querySelector('.li-main').onclick = ()=>formGasto(o.id, g);
  const del = el('button','li-del','×');
  del.onclick = ()=>{
    if(!g.grupoId){
      if(confirm('Excluir este gasto?')){ o.gastos = o.gastos.filter(x=>x.id!==g.id); save(); renderAll(); }
      return;
    }
    const irmas = o.gastos.filter(x=>x.grupoId===g.grupoId);
    openSheet(`
      <h3>Excluir parcela ${g.parcela.n}/${g.parcela.de}</h3>
      <p class="muted-note">Esta parcela faz parte de uma compra em ${g.parcela.de}x no cartão.</p>
      <div class="sheet-actions" style="flex-direction:column">
        <button class="btn primary" id="dUma" style="width:100%">Excluir só esta parcela</button>
        <button class="btn ghost" id="dTodas" style="width:100%;color:var(--red)">Excluir a compra toda (${irmas.length} parcela${irmas.length>1?'s':''})</button>
        <button class="btn ghost" id="dCancel" style="width:100%">Cancelar</button>
      </div>`);
    $('#dCancel').onclick = closeSheet;
    $('#dUma').onclick = ()=>{ o.gastos = o.gastos.filter(x=>x.id!==g.id); save(); closeSheet(); renderAll(); };
    $('#dTodas').onclick = ()=>{ o.gastos = o.gastos.filter(x=>x.grupoId!==g.grupoId); save(); closeSheet(); renderAll(); };
  };
  li.appendChild(del);
  return li;
}

/* ===== FASES E VENDA ===== */
function mudarFase(o, f){ o.fase = f; save(); renderAll(); }

function formVenda(o){
  openSheet(`
    <h3>Registrar venda — ${escapeHtml(o.nome)}</h3>
    <div class="field big"><input id="fVal" inputmode="decimal" placeholder="R$ 0,00" autocomplete="off"></div>
    <div class="field"><label>Data da venda</label><input id="fData" type="date" value="${todayISO()}"></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Confirmar venda</button>
    </div>`);
  $('#fVal').focus();
  $('#cCancel').onclick = closeSheet;
  $('#cSave').onclick = ()=>{
    const valor = parseNum($('#fVal').value);
    if(valor<=0){ $('#fVal').focus(); return; }
    o.venda = { valor, data: $('#fData').value || todayISO() };
    o.fase = 'vendida';
    save(); closeSheet(); renderAll();
  };
}

function formEditarObra(o){
  openSheet(`
    <h3>Editar obra</h3>
    <div class="field"><label>Nome</label><input id="fNome" value="${escapeHtml(o.nome)}" autocomplete="off"></div>
    <div class="field"><label>Começou em</label><input id="fData" type="date" value="${o.dataInicio}"></div>
    <div class="field"><label>Valor estimado de venda (opcional)</label>
      <input id="fEst" inputmode="decimal" value="${o.valorEstimadoVenda||''}" autocomplete="off"></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cDel" style="color:var(--red)">Apagar obra</button>
      <button class="btn primary" id="cSave">Salvar</button>
    </div>`);
  $('#cSave').onclick = ()=>{
    const nome = $('#fNome').value.trim();
    if(!nome){ $('#fNome').focus(); return; }
    o.nome = nome;
    o.dataInicio = $('#fData').value || o.dataInicio;
    const est = parseNum($('#fEst').value);
    o.valorEstimadoVenda = est>0 ? est : null;
    save(); closeSheet(); renderAll();
  };
  $('#cDel').onclick = ()=>{
    const n = o.gastos.length;
    if(confirm(`Apagar “${o.nome}”?` + (n?` Os ${n} lançamento(s) dela serão perdidos.`:''))){
      db.obras = db.obras.filter(x=>x.id!==o.id);
      obraAberta = null;
      save(); closeSheet(); showView('inicio'); renderAll();
    }
  };
}

/* ===== GASTO (novo/editar) ===== */
function formGasto(obraId, gasto){
  const abertas = db.obras.filter(o=>o.fase!=='vendida');
  if(!abertas.length && !gasto){ formNovaObra(); return; }
  const isEdit = !!gasto;
  // na edição a obra é fixa (a que está aberta); na criação pode escolher
  const oFix = isEdit ? obraById(obraAberta) : (obraId ? obraById(obraId) : null);

  const selObra = oFix
    ? `<div class="field"><label>Obra</label><input value="${escapeHtml(oFix.nome)}" disabled></div>`
    : `<div class="field"><label>Obra</label><select id="fObra">
        ${abertas.map(o=>`<option value="${o.id}">${escapeHtml(o.nome)}</option>`).join('')}
       </select></div>`;

  // parcela de compra parcelada: pagamento/parcelas fixos, edita só esta parcela
  const isParcela = isEdit && !!gasto.grupoId;
  const pagtoHtml = isParcela
    ? `<p class="muted-note">💳 Parcela ${gasto.parcela.n}/${gasto.parcela.de} de uma compra no cartão — a edição vale só pra esta parcela.</p>`
    : `<div class="field"><label>Pagamento</label><div class="chips" id="fPagto"></div></div>
       <div class="field hidden" id="fParcWrap"><label>Parcelas</label>
         <select id="fParc">${Array.from({length:36},(_,i)=>`<option value="${i+1}">${i+1}x${i?'':' (à vista)'}</option>`).join('')}</select>
       </div>`;

  openSheet(`
    <h3>${isEdit?'Editar gasto':'Novo gasto'}</h3>
    <div class="field big"><input id="fVal" inputmode="decimal" placeholder="R$ 0,00"
      value="${isEdit?String(gasto.valor).replace('.',','):''}" autocomplete="off"></div>
    ${selObra}
    <div class="field"><label>Tópico</label><div class="chips" id="fChips"></div></div>
    ${pagtoHtml}
    <div class="field"><label>Descrição (opcional)</label>
      <input id="fDesc" placeholder="Ex: 50 sacos de cimento" value="${isEdit?escapeHtml(gasto.descricao||''):''}" autocomplete="off"></div>
    <div class="field"><label>Data</label><input id="fData" type="date" value="${isEdit?gasto.data:todayISO()}"></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Salvar</button>
    </div>`);

  let top = isEdit ? gasto.topico : topicos()[0].id;
  const chips = $('#fChips');
  const paint = ()=>{
    chips.innerHTML = '';
    topicos().forEach(t=>{
      const ch = el('button','chip'+(t.id===top?' on':''),`${t.ic} ${t.nm}`);
      ch.type = 'button';
      ch.onclick = ()=>{ top=t.id; paint(); };
      chips.appendChild(ch);
    });
  };
  paint();

  let pagto = isEdit ? (gasto.pagamento || 'pix') : 'pix';
  if(!isParcela){
    const pchips = $('#fPagto');
    const paintPagto = ()=>{
      pchips.innerHTML = '';
      [['pix','⚡ Pix'],['cartao','💳 Cartão']].forEach(([id,nm])=>{
        const ch = el('button','chip'+(id===pagto?' on':''),nm);
        ch.type = 'button';
        ch.onclick = ()=>{ pagto=id; paintPagto(); };
        pchips.appendChild(ch);
      });
      // parcelar só faz sentido no cartão e ao criar
      $('#fParcWrap').classList.toggle('hidden', pagto!=='cartao' || isEdit);
    };
    paintPagto();
  }

  $('#fVal').focus();
  $('#cCancel').onclick = closeSheet;
  $('#cSave').onclick = ()=>{
    const valor = parseNum($('#fVal').value);
    if(valor<=0){ $('#fVal').focus(); return; }
    const o = oFix || obraById($('#fObra').value);
    if(!o) return;
    if(isEdit){
      gasto.valor = valor; gasto.topico = top;
      gasto.descricao = $('#fDesc').value.trim();
      gasto.data = $('#fData').value || gasto.data;
      if(!isParcela) gasto.pagamento = pagto;
    } else {
      const nParc = pagto==='cartao' ? parseInt($('#fParc').value,10)||1 : 1;
      const data0 = $('#fData').value || todayISO();
      const desc = $('#fDesc').value.trim();
      if(nParc > 1){
        const grupoId = uid();
        OBRA_CALC.gerarParcelas(valor, nParc, data0).forEach((p,i)=>{
          o.gastos.push({ id:uid(), valor:p.valor, topico:top, descricao:desc,
            data:p.data, pagamento:'cartao', grupoId, parcela:{n:i+1, de:nParc} });
        });
      } else {
        o.gastos.push({ id:uid(), valor, topico:top, descricao:desc, data:data0, pagamento:pagto });
      }
    }
    save(); closeSheet(); renderAll();
  };
}

/* ===== RELATÓRIO BRUTO × CORRIGIDO ===== */
$('#btnRelVoltar').onclick = ()=>{ if(obraAberta) openObra(obraAberta); else { showView('inicio'); renderAll(); } };

function renderRelatorio(){
  const o = obraById(obraAberta);
  if(!o){ showView('inicio'); renderAll(); return; }
  const hoje = todayISO();
  const fim = (o.venda && o.venda.data) || hoje;
  const tx = taxa();
  const map = TOP_MAP();

  const byTop = {};
  o.gastos.forEach(g=>{ (byTop[g.topico] = byTop[g.topico] || []).push(g); });
  const groups = Object.entries(byTop).map(([id,gs])=>({
    id,
    gs: [...gs].sort((a,b)=>a.data.localeCompare(b.data)),
    bruto: gs.reduce((s,g)=>s+g.valor,0),
    corr:  gs.reduce((s,g)=>s+OBRA_CALC.corrigido(g.valor,g.data,fim,tx),0),
  })).sort((a,b)=>b.bruto-a.bruto);

  const totB = OBRA_CALC.totalBruto(o);
  const totC = OBRA_CALC.totalCorrigido(o, tx, hoje);
  const lucro = OBRA_CALC.lucroVenda(o, tx);

  let rows = '';
  groups.forEach(gr=>{
    const t = map[gr.id] || {nm:gr.id, ic:'🏷️'};
    rows += `<tr class="rt-top"><td>${t.ic} ${t.nm}</td><td></td>
      <td>${money(gr.bruto)}</td><td>${money(gr.corr)}</td><td>+${money(gr.corr-gr.bruto)}</td></tr>`;
    gr.gs.forEach(g=>{
      const c = OBRA_CALC.corrigido(g.valor, g.data, fim, tx);
      rows += `<tr><td class="rt-desc">&nbsp;&nbsp;${escapeHtml(g.descricao||t.nm)}</td><td>${fmtData(g.data)}</td>
        <td>${money(g.valor)}</td><td>${money(c)}</td><td>+${money(c-g.valor)}</td></tr>`;
    });
  });

  let venda = '';
  if(o.venda && lucro){
    venda = `
      <tr class="rep-total"><td>🤝 Venda em ${fmtData(o.venda.data)}</td><td></td><td colspan="3">${money(o.venda.valor)}</td></tr>
      <tr><td>Lucro bruto (venda − gasto)</td><td></td><td colspan="3" class="${lucro.bruto>=0?'pos':'neg'}">${money(lucro.bruto)}</td></tr>
      <tr><td>Acima do banco (venda − corrigido)</td><td></td><td colspan="3" class="${lucro.vsBanco>=0?'pos':'neg'}">${money(lucro.vsBanco)}</td></tr>`;
  } else if(o.valorEstimadoVenda){
    venda = `
      <tr class="rep-total"><td>🎯 Venda estimada</td><td></td><td colspan="3">${money(o.valorEstimadoVenda)}</td></tr>
      <tr><td>Margem estimada (estimado − corrigido)</td><td></td><td colspan="3" class="${o.valorEstimadoVenda-totC>=0?'pos':'neg'}">${money(o.valorEstimadoVenda-totC)}</td></tr>`;
  }

  $('#relBody').innerHTML = `
    <div class="panel">
      <h2>📄 Relatório — ${escapeHtml(o.nome)}</h2>
      <div class="rep-head">
        ${FASES[o.fase].nm} · começou em ${fmtData(o.dataInicio)} · ${fmtMeses(OBRA_CALC.mesesDeObra(o,hoje))}<br>
        Correção de ${String(tx).replace('.',',')}% ao mês, da data de cada gasto até ${o.venda?'a venda ('+fmtData(o.venda.data)+')':'hoje ('+fmtData(hoje)+')'}.
      </div>
      <div class="rep-scroll">
        <table class="rep-table">
          <thead><tr><th>Tópico / gasto</th><th>Data</th><th>Bruto</th><th>Corrigido</th><th>Juros</th></tr></thead>
          <tbody>
            ${rows}
            <tr class="rep-total"><td>TOTAL</td><td></td><td>${money(totB)}</td><td>${money(totC)}</td><td>+${money(totC-totB)}</td></tr>
            ${venda}
          </tbody>
        </table>
      </div>
      <button class="btn primary no-print" id="relPrint" style="width:100%;margin-top:14px">🖨️ Imprimir / salvar PDF</button>
    </div>`;
  $('#relPrint').onclick = ()=>window.print();
}

/* ===== SERÁ QUE VALE A PENA? ===== */
function renderSimula(){
  const sel = $('#simObra');
  const cands = db.obras.filter(o=>o.fase!=='vendida' && o.gastos.length);
  const cur = sel.value;
  sel.innerHTML = cands.length
    ? cands.map(o=>`<option value="${o.id}">${escapeHtml(o.nome)}</option>`).join('')
    : '<option value="">— crie uma obra com gastos —</option>';
  if(cands.some(o=>o.id===cur)) sel.value = cur;
  simulaCompute();
}

function simulaCompute(){
  const out = $('#simOut');
  const o = obraById($('#simObra').value);
  if(!o){ out.innerHTML = ''; return; }

  const vInp = $('#simValor');
  if(!vInp.value && o.valorEstimadoVenda && !vInp.dataset.touched) vInp.value = o.valorEstimadoVenda;
  const venda = parseNum(vInp.value);
  const meses = Math.max(0, parseInt($('#simMeses').value,10) || 0);

  const alvo = new Date(); alvo.setMonth(alvo.getMonth()+meses);
  const alvoISO = alvo.toISOString().slice(0,10);
  const bruto = OBRA_CALC.totalBruto(o);
  const corr  = OBRA_CALC.totalCorrigido(o, taxa(), alvoISO);

  if(venda<=0){
    out.innerHTML = `<div class="panel"><p class="muted-note">Digite o preço de venda pra ver a conta.</p></div>`;
    return;
  }
  const mesesTot = Math.max(1, OBRA_CALC.mesesDeObra(o, alvoISO));
  const rate = OBRA_CALC.taxaEquivalenteMensal(venda, bruto, mesesTot);
  const bate = venda > corr;
  const mult = (rate!=null && taxa()>0) ? rate/taxa() : 0;
  const quando = meses===0 ? 'vendendo hoje' : `vendendo daqui a ${meses} ${meses===1?'mês':'meses'}`;

  out.innerHTML = `
    <div class="card saldo big" style="${bate?'':'background:linear-gradient(140deg,#8a2438,#4a1a2a);border-color:rgba(255,120,140,.35);box-shadow:0 8px 32px rgba(220,60,90,.25)'}">
      <div class="k-label"><span class="k-ic">${bate?'✅':'⚠️'}</span> ${bate?'Vale a pena':'Rende menos que o banco'}</div>
      <div class="k-val" style="font-size:30px">${rate!=null ? rate.toFixed(2).replace('.',',')+'% ao mês' : '—'}</div>
      <div class="k-sub">${quando} · banco paga ${String(taxa()).replace('.',',')}%${rate!=null && mult>=1 ? ' · rende '+mult.toFixed(1).replace('.',',')+'× o banco' : ''}</div>
    </div>
    <div class="cards">
      <div class="card">
        <div class="k-label"><span class="k-ic ic-green">↑</span> Lucro bruto</div>
        <div class="k-val sm ${venda-bruto>=0?'pos':'neg'}">${moneyShort(venda-bruto)}</div>
      </div>
      <div class="card">
        <div class="k-label"><span class="k-ic ic-blue">🏦</span> Acima do banco</div>
        <div class="k-val sm ${venda-corr>=0?'pos':'neg'}">${moneyShort(venda-corr)}</div>
      </div>
      <div class="card big">
        <div class="k-label"><span class="k-ic ic-brand">🧮</span> Custo até lá</div>
        <div class="k-val sm">${money(bruto)} bruto · ${money(corr)} corrigido</div>
      </div>
    </div>`;
}
$('#simObra').onchange = simulaCompute;
$('#simValor').addEventListener('input', ()=>{ $('#simValor').dataset.touched='1'; simulaCompute(); });
$('#simMeses').addEventListener('input', simulaCompute);

/* ===== AJUSTES ===== */
function renderAjustes(){
  const inp = $('#ajTaxa');
  if(document.activeElement !== inp)
    inp.value = String(db.config.taxaMensal).replace('.',',');
  inp.onchange = ()=>{
    const v = parseNum(inp.value);
    db.config.taxaMensal = (v>0 && v<=20) ? v : 1;
    inp.value = String(db.config.taxaMensal).replace('.',',');
    save(); renderAll();
  };

  const ul = $('#ajTopicos');
  ul.innerHTML = db.config.topicosCustom.length ? '' : emptyBlock('🏷️','Nenhum tópico próprio ainda.');
  db.config.topicosCustom.forEach(t=>{
    const li = el('li');
    li.innerHTML = `<div class="av ic-brand">🏷️</div>
      <div class="li-main"><div class="t">${escapeHtml(t.nm)}</div></div>`;
    const del = el('button','li-del','×');
    del.onclick = ()=>{
      const emUso = db.obras.some(o=>o.gastos.some(g=>g.topico===t.id));
      if(emUso){ alert('Este tópico tem gastos lançados. Mova ou apague os gastos antes.'); return; }
      if(confirm(`Remover o tópico “${t.nm}”?`)){
        db.config.topicosCustom = db.config.topicosCustom.filter(x=>x.id!==t.id);
        save(); renderAll();
      }
    };
    li.appendChild(del);
    ul.appendChild(li);
  });

  $('#ajAddTopico').onclick = ()=>{
    const nm = $('#ajNovoTopico').value.trim();
    if(!nm){ $('#ajNovoTopico').focus(); return; }
    db.config.topicosCustom.push({ id:'c_'+uid(), nm, ic:'🏷️' });
    $('#ajNovoTopico').value = '';
    save(); renderAll();
  };

  $('#ajSair').onclick = ()=>$('#btnSair').click();
}

/* ---------- modal / formulários ---------- */
const backdrop = $('#backdrop'), sheet = $('#sheet');
function openSheet(html){ sheet.innerHTML = html; backdrop.classList.add('show'); }
function closeSheet(){ backdrop.classList.remove('show'); }
backdrop.onclick = e=>{ if(e.target===backdrop) closeSheet(); };

function formNovaObra(){
  openSheet(`
    <h3>Nova obra</h3>
    <div class="field"><label>Nome da obra</label><input id="fNome" placeholder="Ex: Casa Alphaville" autocomplete="off"></div>
    <div class="field"><label>Começou em</label><input id="fData" type="date" value="${todayISO()}"></div>
    <div class="field"><label>Valor estimado de venda (opcional)</label><input id="fEst" inputmode="decimal" placeholder="R$ 0,00" autocomplete="off"></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Criar obra</button>
    </div>`);
  $('#fNome').focus();
  $('#cCancel').onclick = closeSheet;
  $('#cSave').onclick = ()=>{
    const nome = $('#fNome').value.trim();
    if(!nome){ $('#fNome').focus(); return; }
    const est = parseNum($('#fEst').value);
    const o = {
      id: uid(), nome, fase: 'construcao',
      dataInicio: $('#fData').value || todayISO(),
      valorEstimadoVenda: est > 0 ? est : null,
      gastos: [],
    };
    db.obras.push(o); save(); closeSheet(); renderAll(); openObra(o.id);
  };
}
$('#btnNovaObra').onclick = formNovaObra;

/* FAB: lançar gasto (ou criar 1ª obra) */
$('#fab').onclick = ()=>{
  const abertas = db.obras.filter(o=>o.fase!=='vendida');
  if(!abertas.length){ formNovaObra(); return; }
  const atual = obraAberta && obraById(obraAberta);
  formGasto(atual && atual.fase!=='vendida' ? obraAberta : null, null);
};

/* ---------- instalar PWA ---------- */
let deferredPrompt = null;
window.addEventListener('beforeinstallprompt',e=>{ e.preventDefault(); deferredPrompt=e; $('#installHint').classList.remove('hidden'); });
$('#installBtn').onclick = async()=>{
  if(!deferredPrompt) return;
  deferredPrompt.prompt(); await deferredPrompt.userChoice; deferredPrompt=null;
  $('#installHint').classList.add('hidden');
};
window.addEventListener('appinstalled',()=>$('#installHint').classList.add('hidden'));

/* ---------- go: espera auth e liga o tempo real ---------- */
function bootCloud(){
  CLOUD.onAuth(user=>{
    if(unwatch){ unwatch(); unwatch=null; }
    if(!user){ db = empty(); obraAberta = null; showView('inicio'); renderAll(); return; }

    // dados antigos deste aparelho (era localStorage por CPF)
    const flagKey = 'obras_migrado_v1::' + user.uid;
    if(!localStorage.getItem(flagKey)){
      const legada = Object.keys(localStorage).filter(k=>k.startsWith('obras_data_v1'))
        .map(k=>{ try{ return JSON.parse(localStorage.getItem(k)); }catch{ return null; } })
        .find(d=>d && d.obras && d.obras.length);
      if(legada){
        CLOUD.importarSeVazio(normaliza(legada)).then(ok=>{
          localStorage.setItem(flagKey,'1');
          if(ok) alert('Encontramos obras salvas neste aparelho e importamos pra sua conta na nuvem. ✅');
        });
      } else {
        localStorage.setItem(flagKey,'1');
      }
    }

    unwatch = CLOUD.watchDados((blob, meta)=>{
      if(meta.pendingWrites) return;      // eco da própria escrita
      db = normaliza(blob);
      renderAll();
    });
  });
}
if(window.CLOUD) bootCloud();
else window.addEventListener('cloud-pronto', bootCloud);
renderAll(); // primeiro paint (vazio) enquanto a nuvem responde

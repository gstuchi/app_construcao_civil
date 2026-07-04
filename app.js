/* Minhas Obras — controle de custos por obra. PWA offline, localStorage, vanilla JS. */
'use strict';

/* ---------- estado ---------- */
const SESSION_CPF = localStorage.getItem('finance_session_v1');
const KEY = SESSION_CPF ? 'obras_data_v1::' + SESSION_CPF : 'obras_data_v1';

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
let db = load();
let obraAberta = null;   // id da obra no detalhe
let tab = 'inicio';

function load(){
  try{
    const d = JSON.parse(localStorage.getItem(KEY));
    return d && typeof d==='object'
      ? {...empty(), ...d, config:{...empty().config, ...(d.config||{})}}
      : empty();
  }catch{ return empty(); }
}
function save(){ localStorage.setItem(KEY, JSON.stringify(db)); }
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
  if(obraAberta) renderObra();
}

/* ===== INÍCIO ===== */
function renderInicio(){
  const hoje = todayISO();
  const abertas = db.obras.filter(o=>o.fase!=='vendida');
  const bruto = abertas.reduce((s,o)=>s+OBRA_CALC.totalBruto(o),0);
  const corr  = abertas.reduce((s,o)=>s+OBRA_CALC.totalCorrigido(o,taxa(),hoje),0);
  $('#kTotal').textContent = money(bruto);
  $('#kTotalSub').textContent = abertas.length
    ? `Corrigido: ${money(corr)} · ${abertas.length} obra${abertas.length>1?'s':''} em andamento`
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
        <div class="k-val">${money(bruto)}</div>
        <div class="k-sub">Corrigido pelo banco: ${money(corr)}</div>
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
  li.innerHTML = `
    <div class="av ic-brand">${t.ic}</div>
    <div class="li-main">
      <div class="t">${escapeHtml(g.descricao || t.nm)}</div>
      <div class="s">${t.nm} · ${fmtData(g.data)}</div>
    </div>
    <div class="li-val neg">−${money(g.valor)}</div>`;
  li.querySelector('.li-main').style.cursor = 'pointer';
  li.querySelector('.li-main').onclick = ()=>formGasto(o.id, g);
  const del = el('button','li-del','×');
  del.onclick = ()=>{ if(confirm('Excluir este gasto?')){ o.gastos = o.gastos.filter(x=>x.id!==g.id); save(); renderAll(); } };
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

  openSheet(`
    <h3>${isEdit?'Editar gasto':'Novo gasto'}</h3>
    <div class="field big"><input id="fVal" inputmode="decimal" placeholder="R$ 0,00"
      value="${isEdit?String(gasto.valor).replace('.',','):''}" autocomplete="off"></div>
    ${selObra}
    <div class="field"><label>Tópico</label><div class="chips" id="fChips"></div></div>
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
    } else {
      o.gastos.push({ id:uid(), valor, topico:top,
        descricao:$('#fDesc').value.trim(), data:$('#fData').value || todayISO() });
    }
    save(); closeSheet(); renderAll();
  };
}

/* stub preenchido na Task 6 */
function renderAjustes(){}

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

/* ---------- go ---------- */
renderAll();

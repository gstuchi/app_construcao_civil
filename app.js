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

/* stubs preenchidos nas próximas tasks */
function renderObra(){}
function renderAjustes(){}
function formGasto(obraId, gasto){}

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

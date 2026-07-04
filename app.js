/* Minhas Finanças — PWA offline, dados no localStorage. Vanilla JS. */
'use strict';

/* ---------- estado ---------- */
// dados separados por usuário logado (CPF); sem sessão usa a chave antiga
const SESSION_CPF = localStorage.getItem('finance_session_v1');
const KEY = SESSION_CPF ? 'finance_data_v1::' + SESSION_CPF : 'finance_data_v1';
// migra dados criados antes do login existir pro primeiro usuário que entrar
if (SESSION_CPF && !localStorage.getItem(KEY) && localStorage.getItem('finance_data_v1')) {
  localStorage.setItem(KEY, localStorage.getItem('finance_data_v1'));
  localStorage.removeItem('finance_data_v1');
}
const CATS = [
  {id:'mercado',   nm:'Mercado',      ic:'🛒'},
  {id:'contas',    nm:'Contas/Casa',  ic:'🏠'},
  {id:'transporte',nm:'Transporte',   ic:'⛽'},
  {id:'saude',     nm:'Saúde',        ic:'💊'},
  {id:'lazer',     nm:'Lazer',        ic:'🎉'},
  {id:'educacao',  nm:'Educação',     ic:'📚'},
  {id:'salario',   nm:'Salário',      ic:'💼'},
  {id:'outros',    nm:'Outros',       ic:'📦'},
];
const CAT_MAP = Object.fromEntries(CATS.map(c=>[c.id,c]));
const PIE = ['--c1','--c2','--c3','--c4','--c5','--c6','--c7','--c8'];

const empty = () => ({transacoes:[], contas:[], vendas:[], investimentos:[]});
let db = load();
let cursor = new Date(); cursor.setDate(1);   // mês selecionado
let tab = 'inicio';

function load(){
  try{ const d = JSON.parse(localStorage.getItem(KEY)); return d && typeof d==='object' ? {...empty(),...d} : empty(); }
  catch{ return empty(); }
}
function save(){ localStorage.setItem(KEY, JSON.stringify(db)); }
const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2,6);

/* ---------- helpers ---------- */
const BRL = new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'});
const money = n => BRL.format(n||0);
const moneyShort = n => {
  const a=Math.abs(n);
  if(a>=1000) return (n<0?'-':'')+'R$ '+(a/1000).toFixed(a>=10000?0:1).replace('.',',')+'k';
  return money(n);
};
const MES = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
const ymKey = d => d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0');
const parseYm = s => { const [y,m]=s.split('-'); return new Date(+y,+m-1,1); };
const inMonth = (dateStr, d) => (dateStr||'').slice(0,7) === ymKey(d);
const todayISO = () => new Date().toISOString().slice(0,10);
const fmtDay = iso => { const [y,m,dd]=iso.split('-'); return `${dd}/${m}`; };
const parseNum = v => {
  if(typeof v==='number') return v;
  v=(v||'').toString().trim().replace(/[^\d,.-]/g,'');
  if(v.includes(',')) v=v.replace(/\./g,'').replace(',','.');
  const n=parseFloat(v); return isNaN(n)?0:n;
};
const $ = s => document.querySelector(s);
const el = (tag,cls,html)=>{ const e=document.createElement(tag); if(cls)e.className=cls; if(html!=null)e.innerHTML=html; return e; };

function emptyBlock(icon,msg){
  return `<div class="empty"><div class="big">${icon}</div><p>${msg}</p></div>`;
}

/* variação % vs mês anterior; invert=true quando subir é ruim (despesas) */
function deltaHtml(cur, prev, invert){
  if(prev<=0) return '';
  const p=(cur-prev)/prev*100;
  if(!isFinite(p)) return '';
  const up=p>=0.5, down=p<=-0.5;
  const cls=(!up&&!down)?'flat':((up!==!!invert)?'up':'down');
  const arrow=up?'▲':down?'▼':'•';
  return `<div class="k-delta ${cls}">${arrow} ${Math.abs(p).toFixed(0)}% vs mês anterior</div>`;
}

/* ---------- render principal ---------- */
function render(){
  $('#mLabel').textContent = `${MES[cursor.getMonth()]} ${cursor.getFullYear()}`;
  renderInicio();
  renderLancamentos();
  renderContas();
  renderNegocio();
  renderInvest();
}

/* ===== INÍCIO ===== */
function monthTx(){ return db.transacoes.filter(t=>inMonth(t.data,cursor)); }

function renderInicio(){
  const tx = monthTx();
  const rec  = tx.filter(t=>t.tipo==='receita').reduce((s,t)=>s+t.valor,0);
  const desp = tx.filter(t=>t.tipo==='despesa').reduce((s,t)=>s+t.valor,0);
  const saldo = rec-desp;
  const contasPend = db.contas.filter(c=>!c.pago).reduce((s,c)=>s+c.valor,0);
  const investido  = db.investimentos.reduce((s,i)=>s+(i.atual||i.aplicado),0);

  // mês anterior, pros deltas
  const pd = new Date(cursor); pd.setMonth(pd.getMonth()-1);
  const ptx = db.transacoes.filter(t=>inMonth(t.data,pd));
  const pRec  = ptx.filter(t=>t.tipo==='receita').reduce((s,t)=>s+t.valor,0);
  const pDesp = ptx.filter(t=>t.tipo==='despesa').reduce((s,t)=>s+t.valor,0);

  $('#kSaldo').textContent = money(saldo);
  $('#kSaldo').className = 'k-val';
  $('#kSaldoSub').textContent = saldo>=0 ? 'Você fechou no positivo 🎉' : 'Atenção: gastou mais que ganhou';
  $('#kRec').textContent = money(rec);
  $('#kDesp').textContent = money(desp);
  $('#kRecDelta').innerHTML = deltaHtml(rec, pRec, false);
  $('#kDespDelta').innerHTML = deltaHtml(desp, pDesp, true);
  $('#kContas').textContent = money(contasPend);
  $('#kInvest').textContent = money(investido);

  // donut despesas por categoria
  $('#donutMonth').textContent = MES[cursor.getMonth()].slice(0,3).toLowerCase();
  const byCat = {};
  tx.filter(t=>t.tipo==='despesa').forEach(t=>{ byCat[t.categoria]=(byCat[t.categoria]||0)+t.valor; });
  const entries = Object.entries(byCat).sort((a,b)=>b[1]-a[1]);
  drawDonut(entries, desp);

  // área receitas × despesas
  drawArea();

  // recentes
  const recent = [...db.transacoes].sort((a,b)=>(b.data+b.id).localeCompare(a.data+a.id)).slice(0,6);
  const list = $('#recentList');
  list.innerHTML = recent.length ? '' : emptyBlock('🌱','Nenhum lançamento ainda.<br>Toque no + pra começar.');
  recent.forEach(t=>list.appendChild(txRow(t)));
}

function drawDonut(entries, total){
  const svg = $('#donutSvg');
  $('#donutTotal').textContent = moneyShort(total);
  if(!total){ svg.innerHTML=''; $('#donutLegend').innerHTML = `<div class="empty" style="padding:10px"><p>Sem despesas no mês</p></div>`; return; }
  const cs = getComputedStyle(document.documentElement);
  let off=0, paths='';
  const R=15.915, C=2*Math.PI*R;
  entries.forEach(([cat,val],i)=>{
    const frac=val/total, len=frac*C;
    const color=cs.getPropertyValue(PIE[i%PIE.length]).trim();
    paths += `<circle cx="18" cy="18" r="${R}" fill="none" stroke="${color}" stroke-width="4.4"
      stroke-dasharray="${len} ${C-len}" stroke-dashoffset="${-off}" transform="rotate(-90 18 18)"
      stroke-linecap="butt"></circle>`;
    off+=len;
  });
  svg.innerHTML = paths;
  const leg = $('#donutLegend'); leg.innerHTML='';
  entries.slice(0,6).forEach(([cat,val],i)=>{
    const c=CAT_MAP[cat]||{nm:cat,ic:'📦'};
    const color=cs.getPropertyValue(PIE[i%PIE.length]).trim();
    const pct=Math.round(val/total*100);
    leg.appendChild(el('div','row',
      `<span class="dot" style="background:${color}"></span>
       <span class="nm">${c.ic} ${c.nm}</span>
       <span class="vl">${pct}% · ${moneyShort(val)}</span>`));
  });
}

/* gráfico de área — receitas × despesas, seletor 3m/6m/12m, tooltip com crosshair */
let areaRange = 6;
let areaData = [];

function drawArea(){
  const wrap = $('#areaWrap');
  const w = Math.max(280, wrap.clientWidth || 300), h = 215;
  const padL = 46, padR = 12, padT = 12, padB = 26;
  const cs = getComputedStyle(document.documentElement);
  const cRec = cs.getPropertyValue('--chart-rec').trim();
  const cDesp = cs.getPropertyValue('--chart-desp').trim();
  const cGrid = cs.getPropertyValue('--border').trim();
  const cMut = cs.getPropertyValue('--muted').trim();

  const months=[];
  for(let i=areaRange-1;i>=0;i--){ const d=new Date(cursor); d.setMonth(d.getMonth()-i); months.push(d); }
  areaData = months.map(d=>{
    const tx=db.transacoes.filter(t=>inMonth(t.data,d));
    return { d,
      rec: tx.filter(t=>t.tipo==='receita').reduce((s,t)=>s+t.valor,0),
      desp:tx.filter(t=>t.tipo==='despesa').reduce((s,t)=>s+t.valor,0) };
  });
  const n=areaData.length;
  const max=Math.max(100,...areaData.flatMap(x=>[x.rec,x.desp]))*1.08;
  const X=i=>padL+(w-padL-padR)*(n===1?0.5:i/(n-1));
  const Y=v=>padT+(h-padT-padB)*(1-v/max);

  const line=k=>areaData.map((x,i)=>`${i?'L':'M'}${X(i).toFixed(1)},${Y(x[k]).toFixed(1)}`).join('');
  const area=k=>`${line(k)}L${X(n-1).toFixed(1)},${Y(0)}L${X(0).toFixed(1)},${Y(0)}Z`;

  // grade horizontal recessiva (3 linhas) + rótulos de valor
  let grid='';
  for(const f of [0.33,0.66,1]){
    const v=max*f, y=Y(v).toFixed(1);
    grid+=`<line x1="${padL}" y1="${y}" x2="${w-padR}" y2="${y}" stroke="${cGrid}" stroke-dasharray="3 5" stroke-width="1"/>
      <text x="${padL-7}" y="${+y+4}" text-anchor="end" font-size="10.5" fill="${cMut}">${moneyShort(v)}</text>`;
  }
  // rótulos de mês (pula alguns no 12m pra não amontoar)
  let xlbl='';
  const step=n>8?2:1;
  areaData.forEach((x,i)=>{
    if(i%step) return;
    xlbl+=`<text x="${X(i).toFixed(1)}" y="${h-7}" text-anchor="middle" font-size="10.5" fill="${cMut}">${MES[x.d.getMonth()].slice(0,3)}</text>`;
  });

  wrap.querySelector('svg')?.remove();
  const svg=document.createElementNS('http://www.w3.org/2000/svg','svg');
  svg.setAttribute('viewBox',`0 0 ${w} ${h}`);
  svg.setAttribute('height',h);
  svg.innerHTML=`
    ${grid}
    <path d="${area('rec')}"  fill="${cRec}"  opacity="0.13"/>
    <path d="${area('desp')}" fill="${cDesp}" opacity="0.13"/>
    <path d="${line('rec')}"  fill="none" stroke="${cRec}"  stroke-width="2" stroke-linejoin="round"/>
    <path d="${line('desp')}" fill="none" stroke="${cDesp}" stroke-width="2" stroke-linejoin="round"/>
    <line id="axCross" y1="${padT}" y2="${h-padB}" stroke="${cMut}" stroke-width="1" opacity="0"/>
    <circle id="axDotR" r="4" fill="${cRec}"  stroke="#111a2e" stroke-width="2" opacity="0"/>
    <circle id="axDotD" r="4" fill="${cDesp}" stroke="#111a2e" stroke-width="2" opacity="0"/>
    ${xlbl}`;
  wrap.appendChild(svg);

  // hover / toque: mês mais próximo → crosshair + tooltip
  const tip=$('#areaTip');
  const show=cx=>{
    const rect=svg.getBoundingClientRect();
    const px=(cx-rect.left)*(w/rect.width);
    let bi=0,bd=1e9;
    for(let i=0;i<n;i++){ const d=Math.abs(X(i)-px); if(d<bd){bd=d;bi=i;} }
    const x=X(bi), m=areaData[bi];
    svg.querySelector('#axCross').setAttribute('x1',x); svg.querySelector('#axCross').setAttribute('x2',x);
    svg.querySelector('#axCross').setAttribute('opacity','.55');
    const dR=svg.querySelector('#axDotR'), dD=svg.querySelector('#axDotD');
    dR.setAttribute('cx',x); dR.setAttribute('cy',Y(m.rec));  dR.setAttribute('opacity','1');
    dD.setAttribute('cx',x); dD.setAttribute('cy',Y(m.desp)); dD.setAttribute('opacity','1');
    tip.innerHTML=`<div style="color:var(--muted);margin-bottom:3px">${MES[m.d.getMonth()]} ${m.d.getFullYear()}</div>
      <div class="tr"><span class="dot" style="background:${cRec}"></span>Receitas <b style="margin-left:auto;padding-left:10px">${money(m.rec)}</b></div>
      <div class="tr"><span class="dot" style="background:${cDesp}"></span>Despesas <b style="margin-left:auto;padding-left:10px">${money(m.desp)}</b></div>`;
    tip.style.opacity='1';
    const tw=tip.offsetWidth, sx=x*(rect.width/w);
    tip.style.left=Math.min(Math.max(4,sx-tw/2),rect.width-tw-4)+'px';
    tip.style.top='2px';
  };
  const hide=()=>{ tip.style.opacity='0';
    ['axCross','axDotR','axDotD'].forEach(id=>svg.querySelector('#'+id).setAttribute('opacity','0')); };
  svg.addEventListener('pointermove',e=>show(e.clientX),{passive:true});
  svg.addEventListener('pointerdown',e=>show(e.clientX),{passive:true});
  svg.addEventListener('pointerleave',hide);
}

$('#rangeSeg').querySelectorAll('button').forEach(b=>b.onclick=()=>{
  areaRange=+b.dataset.r;
  $('#rangeSeg').querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===b));
  drawArea();
});
let rszT=null;
window.addEventListener('resize',()=>{ clearTimeout(rszT); rszT=setTimeout(drawArea,150); });

function txRow(t){
  const c=CAT_MAP[t.categoria]||{nm:t.categoria||'Outros',ic:'📦'};
  const isRec=t.tipo==='receita';
  const li=el('li');
  li.innerHTML=`
    <div class="av ${isRec?'ic-green':'ic-red'}">${isRec?'💰':c.ic}</div>
    <div class="li-main">
      <div class="t">${escapeHtml(t.descricao||c.nm)}</div>
      <div class="s">${c.nm} · ${fmtDay(t.data)}</div>
    </div>
    <div class="li-val ${isRec?'pos':'neg'}">${isRec?'+':'−'}${money(t.valor)}</div>`;
  const del=el('button','li-del','×');
  del.onclick=()=>{ if(confirm('Excluir este lançamento?')){ db.transacoes=db.transacoes.filter(x=>x.id!==t.id); save(); render(); } };
  li.appendChild(del);
  return li;
}

/* ===== LANÇAMENTOS ===== */
function renderLancamentos(){
  const tx = monthTx().sort((a,b)=>(b.data+b.id).localeCompare(a.data+a.id));
  $('#lancCount').textContent = tx.length ? `${tx.length} item(s)` : '';
  const list=$('#lancList');
  list.innerHTML = tx.length ? '' : emptyBlock('📋','Nenhum lançamento neste mês.');
  tx.forEach(t=>list.appendChild(txRow(t)));
}

/* ===== CONTAS ===== */
function renderContas(){
  const pend = db.contas.filter(c=>!c.pago).reduce((s,c)=>s+c.valor,0);
  const pagoMes = db.contas.filter(c=>c.pago && inMonth(c.vencimento,cursor)).reduce((s,c)=>s+c.valor,0);
  $('#kContasPend').textContent=money(pend);
  $('#kContasPago').textContent=money(pagoMes);

  const list=$('#contasList');
  const arr=[...db.contas].sort((a,b)=>(a.pago-b.pago)||a.vencimento.localeCompare(b.vencimento));
  list.innerHTML = arr.length ? '' : emptyBlock('🧾','Nenhuma conta cadastrada.<br>Toque no + pra adicionar.');
  const hoje=todayISO();
  arr.forEach(c=>{
    const late = !c.pago && c.vencimento < hoje;
    const li=el('li');
    li.innerHTML=`
      <div class="av ${c.pago?'ic-green':late?'ic-red':'ic-amber'}">${c.pago?'✓':'🧾'}</div>
      <div class="li-main">
        <div class="t">${escapeHtml(c.nome)}</div>
        <div class="s">Vence ${fmtDay(c.vencimento)} ·
          <span class="tag ${c.pago?'ok':late?'late':'pend'}">${c.pago?'Pago':late?'Vencida':'Pendente'}</span></div>
      </div>
      <div class="li-val">${money(c.valor)}</div>`;
    const pay=el('button','li-del',c.pago?'↩':'✓');
    pay.title=c.pago?'Marcar como não pago':'Marcar como pago';
    pay.style.color=c.pago?'var(--muted)':'var(--green)';
    pay.onclick=()=>{ c.pago=!c.pago; save(); render(); };
    const del=el('button','li-del','×');
    del.onclick=()=>{ if(confirm('Excluir esta conta?')){ db.contas=db.contas.filter(x=>x.id!==c.id); save(); render(); } };
    li.append(pay,del);
    list.appendChild(li);
  });
}

/* ===== NEGÓCIO ===== */
function renderNegocio(){
  const mes=db.vendas.filter(v=>inMonth(v.data,cursor));
  const totalMes=mes.reduce((s,v)=>s+v.valor,0);
  const totalGeral=db.vendas.reduce((s,v)=>s+v.valor,0);
  const pd=new Date(cursor); pd.setMonth(pd.getMonth()-1);
  const pTotal=db.vendas.filter(v=>inMonth(v.data,pd)).reduce((s,v)=>s+v.valor,0);
  $('#kFatMes').textContent=money(totalMes);
  $('#kFatQtd').textContent=`${mes.length} venda${mes.length===1?'':'s'}`;
  $('#kFatDelta').innerHTML=deltaHtml(totalMes,pTotal,false);
  $('#kTicket').textContent=money(mes.length?totalMes/mes.length:0);
  $('#kFatTotal').textContent=money(totalGeral);

  const list=$('#vendasList');
  const arr=[...mes].sort((a,b)=>(b.data+b.id).localeCompare(a.data+a.id));
  list.innerHTML=arr.length?'':emptyBlock('🏪','Nenhuma venda neste mês.');
  arr.forEach(v=>{
    const li=el('li');
    li.innerHTML=`
      <div class="av ic-brand">🏪</div>
      <div class="li-main"><div class="t">${escapeHtml(v.descricao||'Venda')}</div><div class="s">${fmtDay(v.data)}</div></div>
      <div class="li-val pos">+${money(v.valor)}</div>`;
    const del=el('button','li-del','×');
    del.onclick=()=>{ if(confirm('Excluir esta venda?')){ db.vendas=db.vendas.filter(x=>x.id!==v.id); save(); render(); } };
    li.appendChild(del);
    list.appendChild(li);
  });
}

/* ===== INVESTIMENTOS ===== */
function renderInvest(){
  const aplicado=db.investimentos.reduce((s,i)=>s+i.aplicado,0);
  const atual=db.investimentos.reduce((s,i)=>s+(i.atual||i.aplicado),0);
  const ganho=atual-aplicado;
  const pct=aplicado?(ganho/aplicado*100):0;
  $('#kPatr').textContent=money(atual);
  $('#kRend').textContent=`Rendimento ${ganho>=0?'+':''}${pct.toFixed(1).replace('.',',')}%`;
  $('#kAplicado').textContent=money(aplicado);
  $('#kGanho').textContent=money(ganho);
  $('#kGanho').className='k-val sm '+(ganho>=0?'pos':'neg');

  const list=$('#investList');
  list.innerHTML=db.investimentos.length?'':emptyBlock('📈','Nenhum investimento.<br>Toque no + pra adicionar.');
  [...db.investimentos].sort((a,b)=>(b.atual||b.aplicado)-(a.atual||a.aplicado)).forEach(i=>{
    const g=(i.atual||i.aplicado)-i.aplicado;
    const p=i.aplicado?(g/i.aplicado*100):0;
    const li=el('li');
    li.innerHTML=`
      <div class="av ic-blue">📈</div>
      <div class="li-main"><div class="t">${escapeHtml(i.nome)}</div>
        <div class="s">${i.tipo||'Investimento'} · <span class="${g>=0?'pos':'neg'}">${g>=0?'+':''}${p.toFixed(1).replace('.',',')}%</span></div></div>
      <div class="li-val">${money(i.atual||i.aplicado)}</div>`;
    const del=el('button','li-del','×');
    del.onclick=()=>{ if(confirm('Excluir este investimento?')){ db.investimentos=db.investimentos.filter(x=>x.id!==i.id); save(); render(); } };
    li.appendChild(del);
    list.appendChild(li);
  });
}

/* ---------- navegação ---------- */
// navegação: tabs mobile + sidebar desktop compartilham data-tab
const tabBtns=document.querySelectorAll('button[data-tab]');
tabBtns.forEach(b=>{
  b.onclick=()=>{
    tab=b.dataset.tab;
    tabBtns.forEach(x=>x.classList.toggle('on',x.dataset.tab===tab));
    document.querySelectorAll('section.view').forEach(s=>s.classList.remove('active'));
    $('#v-'+tab).classList.add('active');
    if(tab==='inicio') drawArea();   // largura muda entre layouts; redesenha
    window.scrollTo({top:0,behavior:'smooth'});
  };
});
$('#mPrev').onclick=()=>{ cursor.setMonth(cursor.getMonth()-1); render(); };
$('#mNext').onclick=()=>{ cursor.setMonth(cursor.getMonth()+1); render(); };

/* ---------- modal / formulários ---------- */
const backdrop=$('#backdrop'), sheet=$('#sheet');
function openSheet(html){ sheet.innerHTML=html; backdrop.classList.add('show'); }
function closeSheet(){ backdrop.classList.remove('show'); }
backdrop.onclick=e=>{ if(e.target===backdrop) closeSheet(); };

$('#fab').onclick=()=>{
  // abre formulário conforme a aba atual
  if(tab==='contas') formConta();
  else if(tab==='negocio') formVenda();
  else if(tab==='invest') formInvest();
  else formTransacao();
};

function formTransacao(){
  let tipo='despesa';
  openSheet(`
    <h3>Novo lançamento</h3>
    <div class="seg" id="segTipo">
      <button data-k="despesa" class="on">↓ Despesa</button>
      <button data-k="receita">↑ Receita</button>
    </div>
    <div class="field big"><input id="fVal" inputmode="decimal" placeholder="R$ 0,00" autocomplete="off"></div>
    <div class="field"><label>Descrição</label><input id="fDesc" placeholder="Ex: Mercado do mês" autocomplete="off"></div>
    <div class="field" id="catField"><label>Categoria</label><div class="chips" id="fChips"></div></div>
    <div class="field"><label>Data</label><input id="fData" type="date" value="${todayISO()}"></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Salvar</button>
    </div>`);
  let cat='mercado';
  const chips=$('#fChips');
  const paint=()=>{ chips.innerHTML=''; CATS.forEach(c=>{
    const ch=el('button','chip'+(c.id===cat?' on':''),`${c.ic} ${c.nm}`);
    ch.type='button'; ch.onclick=()=>{ cat=c.id; paint(); }; chips.appendChild(ch);
  }); };
  paint();
  $('#segTipo').querySelectorAll('button').forEach(b=>b.onclick=()=>{
    tipo=b.dataset.k;
    $('#segTipo').querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===b));
    $('#catField').classList.toggle('hidden',tipo==='receita');
    if(tipo==='receita'){ cat='salario'; }
  });
  $('#fVal').focus();
  $('#cCancel').onclick=closeSheet;
  $('#cSave').onclick=()=>{
    const valor=parseNum($('#fVal').value);
    if(valor<=0){ $('#fVal').focus(); return; }
    db.transacoes.push({id:uid(),tipo,valor,categoria:tipo==='receita'?'salario':cat,descricao:$('#fDesc').value.trim(),data:$('#fData').value||todayISO()});
    save(); closeSheet(); render();
  };
}

function formConta(){
  openSheet(`
    <h3>Nova conta a pagar</h3>
    <div class="field big"><input id="fVal" inputmode="decimal" placeholder="R$ 0,00" autocomplete="off"></div>
    <div class="field"><label>Nome da conta</label><input id="fNome" placeholder="Ex: Luz, Água, Internet" autocomplete="off"></div>
    <div class="field"><label>Vencimento</label><input id="fVenc" type="date" value="${todayISO()}"></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Salvar</button>
    </div>`);
  $('#fVal').focus();
  $('#cCancel').onclick=closeSheet;
  $('#cSave').onclick=()=>{
    const valor=parseNum($('#fVal').value), nome=$('#fNome').value.trim();
    if(valor<=0||!nome){ if(!nome)$('#fNome').focus(); else $('#fVal').focus(); return; }
    db.contas.push({id:uid(),nome,valor,vencimento:$('#fVenc').value||todayISO(),pago:false});
    save(); closeSheet(); render();
  };
}

function formVenda(){
  openSheet(`
    <h3>Nova venda</h3>
    <div class="field big"><input id="fVal" inputmode="decimal" placeholder="R$ 0,00" autocomplete="off"></div>
    <div class="field"><label>Descrição (opcional)</label><input id="fDesc" placeholder="Ex: Venda balcão" autocomplete="off"></div>
    <div class="field"><label>Data</label><input id="fData" type="date" value="${todayISO()}"></div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Salvar</button>
    </div>`);
  $('#fVal').focus();
  $('#cCancel').onclick=closeSheet;
  $('#cSave').onclick=()=>{
    const valor=parseNum($('#fVal').value);
    if(valor<=0){ $('#fVal').focus(); return; }
    db.vendas.push({id:uid(),valor,descricao:$('#fDesc').value.trim(),data:$('#fData').value||todayISO()});
    save(); closeSheet(); render();
  };
}

function formInvest(){
  openSheet(`
    <h3>Novo investimento</h3>
    <div class="field"><label>Nome</label><input id="fNome" placeholder="Ex: Tesouro Selic, CDB Banco X" autocomplete="off"></div>
    <div class="field"><label>Tipo</label>
      <select id="fTipo">
        <option>Renda fixa</option><option>Ações</option><option>Fundo</option>
        <option>Poupança</option><option>Cripto</option><option>Outro</option>
      </select></div>
    <div class="row2">
      <div class="field"><label>Valor aplicado</label><input id="fApl" inputmode="decimal" placeholder="R$ 0,00"></div>
      <div class="field"><label>Valor atual</label><input id="fAtu" inputmode="decimal" placeholder="opcional"></div>
    </div>
    <div class="sheet-actions">
      <button class="btn ghost" id="cCancel">Cancelar</button>
      <button class="btn primary" id="cSave">Salvar</button>
    </div>`);
  $('#fNome').focus();
  $('#cCancel').onclick=closeSheet;
  $('#cSave').onclick=()=>{
    const nome=$('#fNome').value.trim(), aplicado=parseNum($('#fApl').value);
    const atualRaw=$('#fAtu').value.trim(); const atual=atualRaw?parseNum(atualRaw):aplicado;
    if(!nome||aplicado<=0){ if(!nome)$('#fNome').focus(); else $('#fApl').focus(); return; }
    db.investimentos.push({id:uid(),nome,tipo:$('#fTipo').value,aplicado,atual});
    save(); closeSheet(); render();
  };
}

function escapeHtml(s){ return (s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

/* ---------- instalar PWA ---------- */
let deferredPrompt=null;
window.addEventListener('beforeinstallprompt',e=>{ e.preventDefault(); deferredPrompt=e; $('#installHint').classList.remove('hidden'); });
$('#installBtn').onclick=async()=>{
  if(!deferredPrompt) return;
  deferredPrompt.prompt(); await deferredPrompt.userChoice; deferredPrompt=null;
  $('#installHint').classList.add('hidden');
};
window.addEventListener('appinstalled',()=>$('#installHint').classList.add('hidden'));

/* ---------- go ---------- */
render();

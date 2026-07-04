/* Tela de entrada — cadastro (e-mail, CPF, senha) e login (CPF + senha).
   Contas locais (localStorage). Senha guardada como hash+salt, nunca em texto puro.
   Efeito visual: card 3D que desentorta ao rolar (recriação vanilla do ContainerScroll). */
'use strict';
(function(){
  const USERS_KEY   = 'finance_users_v1';
  const SESSION_KEY = 'finance_session_v1';
  const $ = s => document.querySelector(s);

  const loadUsers = () => { try{ return JSON.parse(localStorage.getItem(USERS_KEY)) || []; }catch{ return []; } };
  const saveUsers = u => localStorage.setItem(USERS_KEY, JSON.stringify(u));
  const session   = () => localStorage.getItem(SESSION_KEY);

  /* ---------- CPF ---------- */
  const onlyDigits = s => (s||'').replace(/\D/g,'');
  function maskCPF(v){
    v = onlyDigits(v).slice(0,11);
    if(v.length>9) return v.replace(/(\d{3})(\d{3})(\d{3})(\d{0,2})/,'$1.$2.$3-$4');
    if(v.length>6) return v.replace(/(\d{3})(\d{3})(\d{0,3})/,'$1.$2.$3');
    if(v.length>3) return v.replace(/(\d{3})(\d{0,3})/,'$1.$2');
    return v;
  }
  function validCPF(cpf){
    cpf = onlyDigits(cpf);
    if(cpf.length!==11 || /^(\d)\1{10}$/.test(cpf)) return false;
    for(const n of [9,10]){
      let s=0;
      for(let i=0;i<n;i++) s += +cpf[i]*(n+1-i);
      if(((s*10)%11)%10 !== +cpf[n]) return false;
    }
    return true;
  }

  /* ---------- hash de senha ---------- */
  async function sha256hex(str){
    const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(str));
    return [...new Uint8Array(buf)].map(b=>b.toString(16).padStart(2,'0')).join('');
  }
  // fallback quando crypto.subtle não existe (http sem ser localhost)
  function fallbackHash(str){
    let h1=0xdeadbeef, h2=0x41c6ce57;
    for(let i=0;i<str.length;i++){
      const c=str.charCodeAt(i);
      h1=Math.imul(h1^c,2654435761); h2=Math.imul(h2^c,1597334677);
    }
    h1=Math.imul(h1^(h1>>>16),2246822507)^Math.imul(h2^(h2>>>13),3266489909);
    h2=Math.imul(h2^(h2>>>16),2246822507)^Math.imul(h1^(h1>>>13),3266489909);
    return (h2>>>0).toString(16).padStart(8,'0')+(h1>>>0).toString(16).padStart(8,'0');
  }
  async function hashSenha(salt,senha){
    const str = salt+'::'+senha;
    if(window.crypto && crypto.subtle){ try{ return await sha256hex(str); }catch{} }
    return 'fb_'+fallbackHash(str);
  }
  function newSalt(){
    const a=new Uint8Array(16); crypto.getRandomValues(a);
    return [...a].map(b=>b.toString(16).padStart(2,'0')).join('');
  }

  /* ---------- estado inicial ---------- */
  const auth=$('#auth'), sair=$('#btnSair');
  function locked(on){
    auth.classList.toggle('hidden',!on);
    document.body.classList.toggle('locked',on);
    sair.classList.toggle('hidden',on);
  }
  const doSair=()=>{
    if(confirm('Sair da conta?')){ localStorage.removeItem(SESSION_KEY); location.reload(); }
  };
  sair.onclick=doSair;
  const sairSide=$('#btnSairSide'); if(sairSide) sairSide.onclick=doSair;

  const users=loadUsers();
  const logged = session() && users.some(u=>u.cpf===session());
  if(!logged && session()) localStorage.removeItem(SESSION_KEY);
  locked(!logged);
  if(logged) return;   // já autenticado — nada mais a fazer

  /* ---------- efeito scroll 3D (ContainerScroll vanilla) ---------- */
  const scroller=$('#authScroll'), card=$('#authCard'), title=$('#authTitle');
  let boost=false;
  const isMobile=()=>window.innerWidth<=768;
  function apply(){
    const vh=scroller.clientHeight||window.innerHeight;
    let p=Math.min(1,scroller.scrollTop/(vh*0.5));
    if(boost)p=1;
    const rot=20*(1-p);
    const [s0,s1]=isMobile()?[0.85,1]:[1.05,1];
    card.style.transform=`rotateX(${rot}deg) scale(${s0+(s1-s0)*p})`;
    title.style.transform=`translateY(${-80*p}px)`;
    title.style.opacity=String(1-0.35*p);
    $('#authHint').style.opacity=String(1-p*1.6);
  }
  scroller.addEventListener('scroll',apply,{passive:true});
  window.addEventListener('resize',apply);
  card.addEventListener('focusin',()=>{ if(!boost){ boost=true; card.classList.add('boost'); title.classList.add('boost'); apply(); } });
  apply();

  /* ---------- tabs ---------- */
  $('#authTabs').querySelectorAll('button').forEach(b=>b.onclick=()=>{
    $('#authTabs').querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===b));
    $('#fLogin').classList.toggle('hidden',b.dataset.k!=='login');
    $('#fCad').classList.toggle('hidden',b.dataset.k!=='cad');
    $('#lMsg').textContent=''; $('#cMsg').textContent='';
  });

  /* ---------- máscaras e olho ---------- */
  ['lCpf','cCpf'].forEach(id=>{
    const i=document.getElementById(id);
    i.addEventListener('input',()=>{ i.value=maskCPF(i.value); });
  });
  document.querySelectorAll('.pw-eye').forEach(b=>b.onclick=()=>{
    const i=document.getElementById(b.dataset.eye);
    i.type = i.type==='password' ? 'text' : 'password';
    b.textContent = i.type==='password' ? '👁' : '🙈';
  });

  function entrar(cpf){
    localStorage.setItem(SESSION_KEY,cpf);
    location.reload();
  }

  /* ---------- login ---------- */
  $('#fLogin').addEventListener('submit',async e=>{
    e.preventDefault();
    const msg=$('#lMsg'); msg.textContent='';
    const cpf=onlyDigits($('#lCpf').value), senha=$('#lSenha').value;
    if(cpf.length!==11){ msg.textContent='Digite o CPF completo.'; return; }
    if(!senha){ msg.textContent='Digite a senha.'; return; }
    const u=loadUsers().find(x=>x.cpf===cpf);
    if(!u){ msg.textContent='CPF não cadastrado. Toque em "Criar conta".'; return; }
    const h=await hashSenha(u.salt,senha);
    if(h!==u.hash){ msg.textContent='Senha incorreta.'; return; }
    entrar(cpf);
  });

  /* ---------- cadastro ---------- */
  $('#fCad').addEventListener('submit',async e=>{
    e.preventDefault();
    const msg=$('#cMsg'); msg.textContent='';
    const email=$('#cEmail').value.trim(), cpf=onlyDigits($('#cCpf').value), senha=$('#cSenha').value;
    if(!/^\S+@\S+\.\S+$/.test(email)){ msg.textContent='E-mail inválido.'; return; }
    if(!validCPF(cpf)){ msg.textContent='CPF inválido. Confira os números.'; return; }
    if(senha.length<4){ msg.textContent='Senha precisa de pelo menos 4 caracteres.'; return; }
    const us=loadUsers();
    if(us.some(x=>x.cpf===cpf)){ msg.textContent='Este CPF já tem conta. Use "Entrar".'; return; }
    const salt=newSalt();
    us.push({email,cpf,salt,hash:await hashSenha(salt,senha),criado:new Date().toISOString()});
    saveUsers(us);
    entrar(cpf);
  });

})();

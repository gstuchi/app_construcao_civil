/* Tela de entrada — Firebase (e-mail + senha via window.CLOUD).
   CPF vira dado de perfil (validado no cadastro).
   Efeito visual: card 3D que desentorta ao rolar (recriação vanilla do ContainerScroll). */
'use strict';
(function(){
  const $ = s => document.querySelector(s);

  /* ---------- CPF (máscara + validação) ---------- */
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

  /* ---------- trava/destrava ---------- */
  const auth=$('#auth'), sair=$('#btnSair');
  function locked(on){
    auth.classList.toggle('hidden',!on);
    document.body.classList.toggle('locked',on);
    sair.classList.toggle('hidden',on);
    if(on){ mostrarAba('login'); $('#lSenha').value=''; $('#cSenha').value=''; }
  }
  locked(true); // começa travado até o CLOUD dizer quem é

  const doSair=()=>{ if(confirm('Sair da conta?')) CLOUD.logout(); };
  sair.onclick=doSair;
  const sairSide=$('#btnSairSide'); if(sairSide) sairSide.onclick=doSair;

  if(window.CLOUD) CLOUD.onAuth(u => locked(!u));
  else window.addEventListener('cloud-pronto', ()=>CLOUD.onAuth(u => locked(!u)));

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
  function mostrarAba(k){
    $('#authTabs').querySelectorAll('button').forEach(x=>x.classList.toggle('on',x.dataset.k===k));
    $('#fLogin').classList.toggle('hidden',k!=='login');
    $('#fCad').classList.toggle('hidden',k!=='cad');
    $('#lMsg').textContent=''; $('#cMsg').textContent='';
  }
  $('#authTabs').querySelectorAll('button').forEach(b=>b.onclick=()=>mostrarAba(b.dataset.k));

  /* ---------- máscara CPF (cadastro) e olho ---------- */
  const cCpf=document.getElementById('cCpf');
  cCpf.addEventListener('input',()=>{ cCpf.value=maskCPF(cCpf.value); });
  document.querySelectorAll('.pw-eye').forEach(b=>b.onclick=()=>{
    const i=document.getElementById(b.dataset.eye);
    i.type = i.type==='password' ? 'text' : 'password';
    b.innerHTML = ICON(i.type==='password' ? 'olho' : 'olhoFechado');
  });

  /* ---------- erros do Firebase em português ---------- */
  function msgErro(e){
    const c = (e && e.code) || '';
    if(c.includes('invalid-credential') || c.includes('wrong-password') || c.includes('user-not-found'))
      return 'E-mail ou senha incorretos.';
    if(c.includes('email-already-in-use')) return 'Este e-mail já tem conta. Use "Entrar".';
    if(c.includes('invalid-email'))        return 'E-mail inválido.';
    if(c.includes('weak-password'))        return 'Senha fraca: use pelo menos 6 caracteres.';
    if(c.includes('too-many-requests'))    return 'Muitas tentativas. Espere um pouco.';
    if(c.includes('network-request-failed')) return 'Sem internet. Conecte pra entrar.';
    return 'Não deu certo. Tente de novo.';
  }

  /* botão em estado "trabalhando": desabilita e troca o texto até a promise resolver
     (sem isso o login parece travado nos ~3s que o Firebase leva pra responder) */
  async function comLoading(btn, texto, fn){
    const original = btn.textContent;
    btn.disabled = true; btn.textContent = texto;
    try{ await fn(); }
    finally{ btn.disabled = false; btn.textContent = original; }
  }

  /* ---------- login ---------- */
  $('#fLogin').addEventListener('submit',async e=>{
    e.preventDefault();
    const msg=$('#lMsg'); msg.textContent='';
    const email=$('#lEmail').value.trim(), senha=$('#lSenha').value;
    if(!/^\S+@\S+\.\S+$/.test(email)){ msg.textContent='Digite seu e-mail.'; return; }
    if(!senha){ msg.textContent='Digite a senha.'; return; }
    await comLoading(e.target.querySelector('button[type=submit]'), 'Entrando…', async()=>{
      try{ await CLOUD.login(email, senha); }
      catch(err){ msg.textContent=msgErro(err); }
    });
  });

  /* ---------- esqueci minha senha ---------- */
  $('#lEsqueci').onclick=async()=>{
    const msg=$('#lMsg'); msg.textContent='';
    const email=$('#lEmail').value.trim();
    if(!/^\S+@\S+\.\S+$/.test(email)){ msg.textContent='Digite seu e-mail no campo acima primeiro.'; return; }
    try{ await CLOUD.resetSenha(email); msg.textContent='Enviamos um link de redefinição pro seu e-mail.'; }
    catch(err){ msg.textContent=msgErro(err); }
  };

  /* ---------- cadastro ---------- */
  $('#fCad').addEventListener('submit',async e=>{
    e.preventDefault();
    const msg=$('#cMsg'); msg.textContent='';
    const email=$('#cEmail').value.trim(), cpf=onlyDigits($('#cCpf').value), senha=$('#cSenha').value;
    if(!/^\S+@\S+\.\S+$/.test(email)){ msg.textContent='E-mail inválido.'; return; }
    if(!validCPF(cpf)){ msg.textContent='CPF inválido. Confira os números.'; return; }
    if(senha.length<6){ msg.textContent='Senha precisa de pelo menos 6 caracteres.'; return; }
    await comLoading(e.target.querySelector('button[type=submit]'), 'Criando conta…', async()=>{
      try{ await CLOUD.signup(email, senha, cpf); }
      catch(err){ msg.textContent=msgErro(err); }
    });
  });
})();

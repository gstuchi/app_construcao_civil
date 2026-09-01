/* Tela de entrada — Firebase (e-mail + senha via window.CLOUD).
   Efeito visual: card 3D que desentorta ao rolar (recriação vanilla do ContainerScroll). */
'use strict';
(function(){
  const $ = s => document.querySelector(s);

  /* ---------- trava/destrava ---------- */
  const auth=$('#auth'), sair=$('#btnSair');
  function locked(on){
    auth.classList.toggle('hidden',!on);
    document.body.classList.toggle('locked',on);
    sair.classList.toggle('hidden',on);
    if(on){ mostrarAba('login'); $('#lSenha').value=''; $('#cSenha').value=''; }
  }
  locked(true); // começa travado até o CLOUD dizer quem é

  /* Cancela o push ANTES do signOut: removePushSub precisa do usuário ainda logado.
     Sem isso a inscrição fica órfã no aparelho e quem entrar depois recebe
     notificação montada com os dados de quem saiu. */
  let saindoDeProposito = false; // separa "ele apertou Sair" de "a sessão caiu"
  const doSair=async()=>{
    if(!confirm('Sair da conta?')) return;
    const sessao = CLOUD.sessao();
    saindoDeProposito = true;
    let entrouNaDecisao = false;
    try{
      if(!window.OBRA_PUSH || typeof window.OBRA_PUSH.duranteSaida !== 'function')
        throw new Error('cleanup push indisponível');
      await window.OBRA_PUSH.duranteSaida(sessao, async resultadoPush => {
        entrouNaDecisao = true;
        if(!resultadoPush || resultadoPush.seguro !== true)
          throw new Error('cleanup push sem confirmação');
        /* Sair com lançamento ainda não subido descartava o trabalho em silêncio.
           CLOUD.logout tenta subir primeiro e recusa com code 'pendente' se não der. */
        try{ await CLOUD.logout(sessao); }
        catch(err){
          if(err && err.code === 'pendente'){
            if(!confirm('Tem lançamento que ainda não subiu pra nuvem. Sair mesmo assim descarta esse lançamento. Sair?')){
              saindoDeProposito = false;
              return;
            }
            try{ await CLOUD.logout(sessao, { forcar:true }); }
            catch(erroForcado){
              if(erroForcado && erroForcado.code === 'auth-changed'){
                saindoDeProposito = false;
                return;
              }
              saindoDeProposito = false;
              throw erroForcado;
            }
          } else if(err && err.code === 'auth-changed'){
            // A sessão já mudou enquanto o clique aguardava; evento DOM não deve
            // produzir uma rejeição não tratada nem atingir a conta seguinte.
            saindoDeProposito = false;
            return;
          } else { saindoDeProposito = false; throw err; }
        }
      });
    }catch(err){
      saindoDeProposito = false;
      if(entrouNaDecisao){
        console.warn('não deu pra sair da conta:', err);
        alert('Não deu pra sair da conta agora. Tente de novo.');
        return;
      }
      console.warn('não deu pra cancelar o push no logout:', err);
      alert('Não foi seguro sair: não consegui desligar as notificações deste aparelho. Tente de novo.');
    }
  };
  sair.onclick=doSair;
  const sairSide=$('#btnSairSide'); if(sairSide) sairSide.onclick=doSair;

  /* Cair da sessão no meio do uso é raro (o refresh token não vence sozinho, e
     ficar offline não desloga) — acontece quando a conta é apagada/desativada,
     a senha muda em outro aparelho, ou o token é revogado. Sem esta distinção,
     a tela de login aparecia do nada e o usuário não sabia o que tinha havido. */
  let jaLogou = false;
  function aoTrocarUsuario(u){
    if(u){ jaLogou = true; locked(false); return; }
    const expirou = jaLogou && !saindoDeProposito;
    jaLogou = false; saindoDeProposito = false;
    locked(true); // limpa #lMsg, então a mensagem vem depois
    if(expirou) $('#lMsg').textContent = 'Sua sessão expirou por segurança. Entre de novo pra continuar.';
  }
  if(window.CLOUD) CLOUD.onAuth(aoTrocarUsuario);
  else window.addEventListener('cloud-pronto', ()=>CLOUD.onAuth(aoTrocarUsuario));

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

  /* ---------- olho de mostrar senha ---------- */
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
    const email=$('#cEmail').value.trim(), senha=$('#cSenha').value;
    if(!/^\S+@\S+\.\S+$/.test(email)){ msg.textContent='E-mail inválido.'; return; }
    if(senha.length<6){ msg.textContent='Senha precisa de pelo menos 6 caracteres.'; return; }
    await comLoading(e.target.querySelector('button[type=submit]'), 'Criando conta…', async()=>{
      try{ await CLOUD.signup(email, senha); }
      catch(err){ msg.textContent=msgErro(err); }
    });
  });
})();

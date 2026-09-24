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
    if(on){ mostrarAba('login'); limpaSenhas(); }
  }
  locked(true); // começa travado até o CLOUD dizer quem é

  /* Cancela o push ANTES do signOut: removePushSub precisa do usuário ainda logado.
     Sem isso a inscrição fica órfã no aparelho e quem entrar depois recebe
     notificação montada com os dados de quem saiu. */
  let saindoDeProposito = false; // separa "ele apertou Sair" de "a sessão caiu"
  const doSair=async()=>{
    if(saindoDeProposito) return;
    if(!(await OBRA_CONFIRM.perguntar('Sair da conta?', { confirmar:'Sair' }))) return;
    saindoDeProposito = true;
    document.body.inert = true; // não permite editar enquanto a saída aguarda a fila
    try{ await CLOUD.logout({ antesDeSair: async()=>{
      if(window.OBRA_PUSH) await window.OBRA_PUSH.desativa();
    } }); }
    catch(err){
      saindoDeProposito = false;
      if(err?.code === 'outra-aba'){
        toast('Feche outras abas do Custta antes de sair.', 'erro');
      } else if(err?.code === 'navegador'){
        toast('Atualize seu navegador para sair com segurança.', 'erro');
      } else if(err && err.code === 'pendente'){
        toast('Conecte à internet e aguarde a sincronização antes de sair.', 'erro');
      } else { toast('Não foi possível sair com segurança. Tente novamente.', 'erro'); }
    } finally { document.body.inert = false; }
  };
  sair.onclick=doSair;
  const sairSide=$('#btnSairSide'); if(sairSide) sairSide.onclick=doSair;

  /* Cair da sessão no meio do uso é raro (o refresh token não vence sozinho, e
     ficar offline não desloga) — acontece quando a conta é apagada/desativada,
     a senha muda em outro aparelho, ou o token é revogado. Sem esta distinção,
     a tela de login aparecia do nada e o usuário não sabia o que tinha havido. */
  /* Conta Google entra sem perfil: fica na tela de entrada até completar.
     `checagem` descarta a resposta se o usuário trocou durante a leitura. */
  let jaLogou = false, checagem = 0, erroGoogle = '';
  async function aoTrocarUsuario(u){
    const minha = ++checagem;
    if(u){
      jaLogou = true; erroGoogle = ''; // entrou: erro de tentativa anterior não volta na próxima tela de login
      if(u.provedores?.includes('google.com') && await CLOUD.perfilPendente()){
        if(minha === checagem) mostrarPerfil(u);
        return;
      }
      if(minha === checagem) locked(false);
      return;
    }
    const expirou = jaLogou && !saindoDeProposito;
    jaLogou = false; saindoDeProposito = false;
    locked(true); // limpa #lMsg, então a mensagem vem depois
    if(expirou) $('#lMsg').textContent = 'Sua sessão expirou por segurança. Entre de novo pra continuar.';
    else if(erroGoogle){ $('#lMsg').textContent = erroGoogle; }
    erroGoogle = '';
  }
  function mostrarPerfil(u){
    $('#authTabs').classList.add('hidden'); $('#authGoogle').classList.add('hidden');
    $('#fLogin').classList.add('hidden'); $('#fCad').classList.add('hidden');
    $('#fPerfil').classList.remove('hidden');
    const {nome, sobrenome} = OBRA_CADASTRO.nomeDoGoogle(u.nomeExibicao);
    $('#pNome').value = nome; $('#pSobrenome').value = sobrenome; $('#pMsg').textContent = '';
    $('#pOrigem').focus();
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
    $('#authTabs').classList.remove('hidden');
    $('#authGoogle').classList.toggle('hidden', !!window.OBRA_NATIVO?.ehNativo());
    $('#fPerfil').classList.add('hidden');
    $('#authTabs').querySelectorAll('button').forEach(x=>x.classList.toggle('on',x.dataset.k===k));
    $('#fLogin').classList.toggle('hidden',k!=='login');
    $('#fCad').classList.toggle('hidden',k!=='cad');
    $('#lMsg').textContent=''; $('#cMsg').textContent=''; $('#pMsg').textContent='';
  }
  /* Zera o erro do Google no clique, não em mostrarAba: locked(true) a chama
     antes de o onAuth(null) reescrever a mensagem que chegou do redirect. */
  $('#authTabs').querySelectorAll('button').forEach(b=>b.onclick=()=>{ erroGoogle = ''; mostrarAba(b.dataset.k); });

  /* ---------- olho de mostrar senha ---------- */
  document.querySelectorAll('.pw-eye').forEach(b=>b.onclick=()=>{
    const i=document.getElementById(b.dataset.eye);
    i.type = i.type==='password' ? 'text' : 'password';
    b.innerHTML = ICON(i.type==='password' ? 'olho' : 'olhoFechado');
  });

  /* ---------- checklist de senha (também usado no Trocar senha, via OBRA_CHECKLIST) ---------- */
  const CHECKLIST = {
    montar(ul){
      ul.innerHTML = OBRA_CADASTRO.REGRAS_SENHA
        .map(r=>`<li data-regra="${r.id}">${r.texto}</li>`).join('');
    },
    atualizar(ul, senha, email){
      const {regras} = OBRA_CADASTRO.validaSenha(senha, email);
      for(const r of regras) ul.querySelector(`[data-regra="${r.id}"]`)?.classList.toggle('ok', r.ok);
    },
  };
  window.OBRA_CHECKLIST = CHECKLIST;
  const regrasCad = $('#cRegras');
  CHECKLIST.montar(regrasCad);
  const atualizaRegras = ()=>CHECKLIST.atualizar(regrasCad, $('#cSenha').value, $('#cEmail').value);
  $('#cSenha').addEventListener('input', atualizaRegras);
  $('#cEmail').addEventListener('input', atualizaRegras);

  /* ---------- como conheceu (cadastro e "Falta pouco") ---------- */
  function montaOrigem(sel, wrap, label, detalhe){
    for(const o of OBRA_CADASTRO.ORIGENS){
      const op = document.createElement('option'); op.value = o.id; op.textContent = o.nome; sel.append(op);
    }
    sel.addEventListener('change', ()=>{
      const o = OBRA_CADASTRO.ORIGENS.find(x=>x.id===sel.value);
      wrap.classList.toggle('hidden', !o?.detalhe);
      label.textContent = o?.detalhe || '';
      if(!o?.detalhe) detalhe.value = '';
    });
  }
  montaOrigem($('#cOrigem'), $('#cDetalheWrap'), $('#cDetalheLabel'), $('#cDetalhe'));
  montaOrigem($('#pOrigem'), $('#pDetalheWrap'), $('#pDetalheLabel'), $('#pDetalhe'));

  /* ---------- erros do Firebase em português ---------- */
  function msgErro(e){
    const c = (e && e.code) || '';
    if(c.includes('invalid-credential') || c.includes('wrong-password') || c.includes('user-not-found'))
      return 'E-mail ou senha incorretos.';
    if(c.includes('email-already-in-use')) return 'Este e-mail já tem conta. Use "Entrar".';
    if(c.includes('invalid-email'))        return 'E-mail inválido.';
    if(c.includes('weak-password'))        return 'Senha fraca: use 8 caracteres ou mais, com letra e número.';
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
  const CAMPO_ID = {nome:'cNome', sobrenome:'cSobrenome', origem:'cOrigem', origemDetalhe:'cDetalhe'};
  function marca(id, msg, msgId='cMsg'){
    const msgEl=$('#'+msgId); msgEl.textContent=msg;
    const el=document.getElementById(id); el.setAttribute('aria-invalid','true'); el.focus();
  }
  $('#fCad').addEventListener('input', e=>e.target.removeAttribute?.('aria-invalid'));
  $('#fCad').addEventListener('change', e=>e.target.removeAttribute?.('aria-invalid'));
  $('#fCad').addEventListener('submit',async e=>{
    e.preventDefault();
    const msg=$('#cMsg'); msg.textContent='';
    const perfil = OBRA_CADASTRO.normalizaPerfil({
      nome:$('#cNome').value, sobrenome:$('#cSobrenome').value,
      origem:$('#cOrigem').value, origemDetalhe:$('#cDetalhe').value,
    });
    const email=$('#cEmail').value.trim(), senha=$('#cSenha').value, senha2=$('#cSenha2').value;
    if(!perfil.ok && (perfil.campo==='nome' || perfil.campo==='sobrenome')) return marca(CAMPO_ID[perfil.campo], perfil.erro);
    if(!/^\S+@\S+\.\S+$/.test(email)) return marca('cEmail','E-mail inválido.');
    const regra = OBRA_CADASTRO.validaSenha(senha, email);
    if(!regra.ok) return marca('cSenha', regra.erro);
    if(senha2 !== senha) return marca('cSenha2','As senhas não são iguais.');
    if(!perfil.ok) return marca(CAMPO_ID[perfil.campo], perfil.erro);
    await comLoading(e.target.querySelector('button[type=submit]'), 'Criando conta…', async()=>{
      try{ await CLOUD.signup(email, senha, perfil.perfil); }
      catch(err){ msg.textContent=msgErro(err); }
    });
  });

  /* ---------- Google ---------- */
  const btnGoogle = $('#btnGoogle');
  btnGoogle.onclick = async()=>{
    const msg = $('#fCad').classList.contains('hidden') ? $('#lMsg') : $('#cMsg');
    msg.textContent = ''; erroGoogle = '';
    const texto = $('#btnGoogleTexto');
    btnGoogle.disabled = true; texto.textContent = 'Abrindo o Google…';
    try{ await CLOUD.entrarGoogle(); }
    catch(err){ msg.textContent = err?.code === 'cache' ? 'Limpe os dados locais antes de entrar.' : OBRA_CADASTRO.mensagemErroGoogle(err?.code); }
    finally{ btnGoogle.disabled = false; texto.textContent = 'Continuar com Google'; }
  };
  /* Erro na volta do redirect. Pode chegar antes do onAuth(null), que limpa
     #lMsg: guarda pra reescrever depois. */
  window.addEventListener('cloud-google-erro', e=>{
    erroGoogle = OBRA_CADASTRO.mensagemErroGoogle(e.detail?.code);
    $('#lMsg').textContent = erroGoogle;
  });

  /* ---------- Falta pouco (conta Google sem perfil) ---------- */
  const CAMPO_PERFIL = {nome:'pNome', sobrenome:'pSobrenome', origem:'pOrigem', origemDetalhe:'pDetalhe'};
  $('#fPerfil').addEventListener('input', e=>e.target.removeAttribute?.('aria-invalid'));
  $('#fPerfil').addEventListener('change', e=>e.target.removeAttribute?.('aria-invalid'));
  $('#fPerfil').addEventListener('submit', async e=>{
    e.preventDefault();
    const msg = $('#pMsg'); msg.textContent = '';
    const r = OBRA_CADASTRO.normalizaPerfil({
      nome:$('#pNome').value, sobrenome:$('#pSobrenome').value,
      origem:$('#pOrigem').value, origemDetalhe:$('#pDetalhe').value,
    });
    if(!r.ok) return marca(CAMPO_PERFIL[r.campo], r.erro, 'pMsg');
    await comLoading(e.target.querySelector('button[type=submit]'), 'Salvando…', async()=>{
      try{ await CLOUD.completarPerfil(r.perfil); locked(false); }
      catch(err){
        /* Outra aba já gravou o perfil: o setDoc virou update e as rules recusam.
           Se o perfil existe, não há nada pendente — segue pro app. */
        if(err?.code === 'permission-denied' && !(await CLOUD.perfilPendente())){ locked(false); return; }
        msg.textContent = err?.code === 'offline' ? 'Conecte à internet para continuar.' : 'Não deu certo salvar. Tente de novo.';
      }
    });
  });
  $('#pOutra').onclick = async()=>{
    saindoDeProposito = true;
    try{ await CLOUD.logout(); }
    catch{ saindoDeProposito = false; $('#pMsg').textContent = 'Não foi possível trocar de conta agora. Tente de novo.'; }
  };

  function limpaSenhas(){
    for(const id of ['lSenha','cSenha','cSenha2']) document.getElementById(id).value='';
    const ul=document.getElementById('cRegras'); if(ul && ul.children.length) CHECKLIST.atualizar(ul,'','');
  }
})();

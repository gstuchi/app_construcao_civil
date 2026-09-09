/* Formulários de conta: dialog nativo contém foco e não depende de confirm(). */
'use strict';
(function(){
  let aberto = null;
  function mensagem(err){
    if(err.code === 'outra-aba') return 'Feche outras abas do Custta e tente novamente.';
    if(err.code === 'navegador') return 'Atualize seu navegador para gerenciar a conta.';
    if(err.dadosApagados) return 'Os dados foram apagados, mas a conta ainda existe. Digite sua senha e tente apagar novamente.';
    if(['offline','pendente'].includes(err.code)) return 'Conecte à internet e aguarde a sincronização para continuar.';
    if(['auth/invalid-credential','auth/wrong-password'].includes(err.code)) return 'Senha atual incorreta.';
    if(err.code === 'auth/weak-password') return 'A nova senha precisa de pelo menos 6 caracteres.';
    if(err.code === 'auth/too-many-requests') return 'Muitas tentativas. Aguarde antes de tentar novamente.';
    if(err.code === 'auth/network-request-failed') return 'Falha na conexão. Tente novamente quando a internet voltar.';
    return 'Não foi possível concluir. Tente novamente.';
  }
  function abrir(tipo){
    if(aberto) return;
    const apagar = tipo === 'apagar';
    const dialogo = document.createElement('dialog');
    dialogo.className = 'conta-dialog';
    dialogo.setAttribute('aria-labelledby','contaTitulo');
    dialogo.innerHTML = `<form id="contaForm">
      <h2 id="contaTitulo">${apagar ? 'Apagar conta' : 'Trocar senha'}</h2>
      <p>${apagar ? 'Isso apaga sua conta, obras, gastos e notificações. Não pode ser desfeito. Exporte seus dados antes de continuar.' : 'Confirme sua senha atual e escolha uma nova senha.'}</p>
      <div class="field"><label for="contaSenha">Senha atual</label><input id="contaSenha" type="password" autocomplete="current-password" required></div>
      <div class="field"><label for="contaConfirmacao">${apagar ? 'Digite APAGAR para confirmar' : 'Nova senha (mínimo 6 caracteres)'}</label>
        <input id="contaConfirmacao" type="${apagar ? 'text' : 'password'}" autocomplete="${apagar ? 'off' : 'new-password'}" required ${apagar ? '' : 'minlength="6"'}></div>
      <p id="contaMensagem" role="status" aria-live="polite"></p>
      <div class="sheet-actions"><button type="button" class="btn ghost" id="contaCancelar">Cancelar</button>
      <button type="submit" class="btn" id="contaEnviar">${apagar ? 'Apagar minha conta' : 'Salvar senha'}</button></div>
    </form>`;
    let trabalhando = false;
    function fechar(){ dialogo.close(); dialogo.remove(); aberto = null; }
    aberto = { fechar };
    document.body.append(dialogo); dialogo.showModal();
    dialogo.querySelector('#contaSenha').focus();
    dialogo.addEventListener('cancel', e=>{ if(trabalhando) e.preventDefault(); });
    dialogo.addEventListener('close', ()=>{ dialogo.remove(); aberto = null; });
    dialogo.querySelector('#contaCancelar').onclick = fechar;
    dialogo.querySelector('form').onsubmit = async e=>{
      e.preventDefault(); if(trabalhando) return;
      const senha = dialogo.querySelector('#contaSenha');
      const confirmacao = dialogo.querySelector('#contaConfirmacao');
      const msg = dialogo.querySelector('#contaMensagem');
      if(apagar && confirmacao.value !== 'APAGAR'){ msg.textContent = 'Digite APAGAR exatamente como aparece acima.'; return; }
      trabalhando = true;
      const atual = senha.value, nova = confirmacao.value;
      senha.value = ''; if(!apagar) confirmacao.value = '';
      dialogo.querySelectorAll('input,button').forEach(el=>el.disabled=true);
      msg.textContent = apagar ? 'Apagando conta. Aguarde…' : 'Salvando senha…';
      try{
        if(apagar) await CLOUD.apagarConta(atual, nova, { antesDeApagar:()=>window.OBRA_PUSH?.desativa() });
        else await CLOUD.trocarSenha(atual, nova);
        fechar(); if(!apagar) toast('Senha alterada.');
      }catch(err){ msg.textContent = mensagem(err); }
      finally{
        trabalhando = false;
        dialogo.querySelectorAll('input,button').forEach(el=>el.disabled=false);
      }
    };
  }
  function mostrarCache(){
    aberto?.fechar();
    if(document.getElementById('cacheDialog')) return;
    const d = document.createElement('dialog'); d.id='cacheDialog'; d.className='conta-dialog';
    d.innerHTML='<h2>Finalizar saída</h2><p>Feche outras abas do Custta para apagar os dados deste aparelho antes de entrar novamente.</p><p role="status"></p><button class="btn">Tentar limpar novamente</button>';
    d.addEventListener('cancel',e=>e.preventDefault());
    document.body.append(d); d.showModal();
    d.querySelector('button').onclick=async()=>{
      const b=d.querySelector('button'); b.disabled=true;
      try{ await CLOUD.limparCache(); }
      catch{ d.querySelector('[role=status]').textContent='Ainda não foi possível limpar. Feche outras abas e tente novamente.'; }
      finally{ b.disabled=false; }
    };
  }
  window.addEventListener('cloud-cache-bloqueado',mostrarCache);
  window.addEventListener('cloud-pronto',()=>{ if(CLOUD.cacheBloqueado()) mostrarCache(); });
  window.OBRA_CONTA = { abrir };
})();

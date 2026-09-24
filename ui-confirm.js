/* Formulários de conta: dialog nativo contém foco e não depende de confirm(). */
'use strict';
(function(){
  let aberto = null;
  function mensagem(err){
    if(err.code === 'outra-aba') return 'Feche outras abas do Custta e tente novamente.';
    if(err.code === 'navegador') return 'Atualize seu navegador para gerenciar a conta.';
    if(err.dadosApagados) return CLOUD.user()?.temSenha === false
      ? 'Os dados foram apagados, mas a conta ainda existe. Tente apagar novamente.'
      : 'Os dados foram apagados, mas a conta ainda existe. Digite sua senha e tente apagar novamente.';
    if(['offline','pendente'].includes(err.code)) return 'Conecte à internet e aguarde a sincronização para continuar.';
    if(['auth/invalid-credential','auth/wrong-password'].includes(err.code)) return 'Senha atual incorreta.';
    if(err.code === 'auth/weak-password') return err.message || 'Senha fraca: use 8 caracteres ou mais, com letra e número.';
    if(err.code === 'auth/too-many-requests') return 'Muitas tentativas. Aguarde antes de tentar novamente.';
    if(err.code === 'auth/network-request-failed') return 'Falha na conexão. Tente novamente quando a internet voltar.';
    if(['auth/popup-closed-by-user','auth/cancelled-popup-request','auth/user-cancelled'].includes(err.code)) return 'Confirmação com o Google cancelada.';
    if(err.code === 'auth/popup-blocked') return 'O navegador bloqueou a janela do Google. Permita pop-ups e tente de novo.';
    if(err.code === 'auth/user-mismatch') return 'Entre com a mesma conta Google desta conta.';
    return 'Não foi possível concluir. Tente novamente.';
  }
  /* Boilerplate comum dos dialogs de conta: criação, guard `aberto`, foco inicial,
     cancelamento bloqueado enquanto trabalha, campos desabilitados durante o envio
     assíncrono e reabilitados no finally. `validar` roda antes de travar a tela e
     pode abortar (retornando false, já com a mensagem escrita); `executar` recebe
     o que `validar` devolveu e só precisa da chamada ao CLOUD (mais fechar/toast). */
  function montaDialogo(html, { preencher, foco, validar, executar }){
    const dialogo = document.createElement('dialog');
    dialogo.className = 'conta-dialog';
    dialogo.setAttribute('aria-labelledby','contaTitulo');
    dialogo.innerHTML = html;
    if(preencher) preencher(dialogo);
    let trabalhando = false;
    function fechar(){ dialogo.close(); dialogo.remove(); aberto = null; }
    aberto = { fechar };
    document.body.append(dialogo); dialogo.showModal();
    dialogo.querySelector(foco)?.focus();
    dialogo.addEventListener('cancel', e=>{ if(trabalhando) e.preventDefault(); });
    dialogo.addEventListener('close', ()=>{ dialogo.remove(); aberto = null; });
    dialogo.querySelector('#contaCancelar').onclick = fechar;
    dialogo.querySelector('form').onsubmit = async e=>{
      e.preventDefault(); if(trabalhando) return;
      const msg = dialogo.querySelector('#contaMensagem');
      const dado = validar(dialogo, msg);
      if(dado === false) return;
      trabalhando = true;
      dialogo.querySelectorAll('input,button').forEach(el=>el.disabled=true);
      try{ await executar(dado, { dialogo, msg, fechar }); }
      catch(err){ msg.textContent = mensagem(err); }
      finally{
        trabalhando = false;
        dialogo.querySelectorAll('input,button').forEach(el=>el.disabled=false);
      }
    };
    return dialogo;
  }
  function abrir(tipo, dados){
    if(aberto) return;
    if(tipo === 'nome') return abrirNome(dados);
    const apagar = tipo === 'apagar';
    const semSenha = apagar && CLOUD.user()?.temSenha === false;
    const html = `<form id="contaForm">
      <h2 id="contaTitulo">${apagar ? 'Apagar conta' : 'Trocar senha'}</h2>
      <p>${apagar ? 'Isso apaga sua conta, obras, gastos e notificações. Não pode ser desfeito. Exporte seus dados antes de continuar.' + (semSenha ? ' Para confirmar, você vai entrar com o Google de novo.' : '') : 'Confirme sua senha atual e escolha uma nova senha.'}</p>
      ${semSenha ? '' : '<div class="field"><label for="contaSenha">Senha atual</label><input id="contaSenha" type="password" autocomplete="current-password" required></div>'}
      ${apagar
        ? `<div class="field"><label for="contaConfirmacao">Digite APAGAR para confirmar</label>
             <input id="contaConfirmacao" type="text" autocomplete="off" required></div>`
        : `<div class="field"><label for="contaConfirmacao">Nova senha</label>
             <input id="contaConfirmacao" type="password" autocomplete="new-password" maxlength="128" required aria-describedby="contaRegras"
               passwordrules="minlength: 8; required: digit; required: lower, upper;">
             <ul class="senha-regras" id="contaRegras" aria-live="polite"></ul></div>
           <div class="field"><label for="contaNova2">Repetir nova senha</label>
             <input id="contaNova2" type="password" autocomplete="new-password" maxlength="128" required></div>`}
      <p id="contaMensagem" role="status" aria-live="polite"></p>
      <div class="sheet-actions"><button type="button" class="btn ghost" id="contaCancelar">Cancelar</button>
      <button type="submit" class="btn" id="contaEnviar">${apagar ? 'Apagar minha conta' : 'Salvar senha'}</button></div>
    </form>`;
    const dialogo = montaDialogo(html, {
      foco: semSenha ? '#contaConfirmacao' : '#contaSenha',
      validar(dlg, msg){
        const senha = dlg.querySelector('#contaSenha');
        const confirmacao = dlg.querySelector('#contaConfirmacao');
        if(apagar && confirmacao.value !== 'APAGAR'){ msg.textContent = 'Digite APAGAR exatamente como aparece acima.'; return false; }
        if(!apagar){
          const regra = OBRA_CADASTRO.validaSenha(confirmacao.value, CLOUD.user()?.email);
          if(!regra.ok){ msg.textContent = regra.erro; return false; }
          if(dlg.querySelector('#contaNova2').value !== confirmacao.value){ msg.textContent = 'As senhas novas não são iguais.'; return false; }
        }
        const atual = senha ? senha.value : '', nova = confirmacao.value;
        if(senha) senha.value = ''; if(!apagar){ confirmacao.value = ''; dlg.querySelector('#contaNova2').value = ''; }
        return { atual, nova };
      },
      async executar({ atual, nova }, { msg, fechar }){
        msg.textContent = apagar ? 'Apagando conta. Aguarde…' : 'Salvando senha…';
        if(apagar) await CLOUD.apagarConta(atual, nova, { antesDeApagar:()=>window.OBRA_PUSH?.desativa() });
        else await CLOUD.trocarSenha(atual, nova);
        fechar(); if(!apagar) toast('Senha alterada.');
      },
    });
    if(!apagar){
      const ul = dialogo.querySelector('#contaRegras'), nova = dialogo.querySelector('#contaConfirmacao');
      OBRA_CHECKLIST.montar(ul);
      nova.addEventListener('input', ()=>OBRA_CHECKLIST.atualizar(ul, nova.value, CLOUD.user()?.email));
    }
  }
  function abrirNome(dados){
    const html = `<form>
      <h2 id="contaTitulo">Seu nome</h2>
      <div class="field"><label for="contaNome">Nome</label><input id="contaNome" type="text" autocomplete="given-name" maxlength="60" required></div>
      <div class="field"><label for="contaSobrenome">Sobrenome <span class="opcional">(opcional)</span></label><input id="contaSobrenome" type="text" autocomplete="family-name" maxlength="80"></div>
      <p id="contaMensagem" role="status" aria-live="polite"></p>
      <div class="sheet-actions"><button type="button" class="btn ghost" id="contaCancelar">Cancelar</button>
      <button type="submit" class="btn" id="contaEnviar">Salvar</button></div>
    </form>`;
    montaDialogo(html, {
      preencher(dlg){
        dlg.querySelector('#contaNome').value = dados?.nome || '';
        dlg.querySelector('#contaSobrenome').value = dados?.sobrenome || '';
      },
      foco: '#contaNome',
      validar(dlg, msg){
        const r = OBRA_CADASTRO.normalizaNome({ nome:dlg.querySelector('#contaNome').value, sobrenome:dlg.querySelector('#contaSobrenome').value });
        if(!r.ok){ msg.textContent = r.erro; dlg.querySelector(r.campo==='nome'?'#contaNome':'#contaSobrenome').focus(); return false; }
        return r.perfil;
      },
      async executar(perfil, { msg, fechar }){
        msg.textContent = 'Salvando…';
        await CLOUD.salvarNome(perfil.nome, perfil.sobrenome || '');
        fechar(); toast('Nome salvo.');
        window.dispatchEvent(new Event('perfil-alterado'));
      },
    });
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

  /* confirm()/alert() viram no-op silencioso no WKWebView sem WKUIDelegate.
     Mensagem entra por textContent: nome de obra e tópico são texto do usuário. */
  function dialogoSimples(msg, { confirmar, cancelar }){
    return new Promise(resolve=>{
      const d = document.createElement('dialog');
      d.className = 'conta-dialog confirma-dialog';
      const p = document.createElement('p'); p.className = 'confirma-msg'; p.textContent = msg;
      const acoes = document.createElement('div'); acoes.className = 'sheet-actions';
      const botao = (texto, classe, acao)=>{
        const b = document.createElement('button'); b.type = 'button'; b.className = classe;
        b.dataset.acao = acao; b.textContent = texto; acoes.append(b); return b;
      };
      const bCancelar = cancelar ? botao(cancelar, 'btn ghost', 'cancelar') : null;
      const bConfirmar = botao(confirmar, 'btn primary', 'confirmar');
      let resposta = false;
      d.append(p, acoes);
      d.addEventListener('close', ()=>{ d.remove(); resolve(resposta); }, { once:true });
      if(bCancelar) bCancelar.onclick = ()=>d.close();
      bConfirmar.onclick = ()=>{ resposta = true; d.close(); };
      document.body.append(d); d.showModal();
      (bCancelar || bConfirmar).focus(); // ação destrutiva nunca é o foco inicial
    });
  }
  window.OBRA_CONFIRM = {
    perguntar: (msg, { confirmar = 'Confirmar', cancelar = 'Cancelar' } = {}) => dialogoSimples(msg, { confirmar, cancelar }),
    avisar: msg => dialogoSimples(msg, { confirmar:'Entendi', cancelar:null }).then(()=>{}),
  };
})();

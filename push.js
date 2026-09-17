/* Notificações por aparelho. Web: Web Push (VAPID) pelo service worker.
   app.js e auth.js só conhecem esta interface. */
'use strict';
(function(root){
  const VAPID_PUBLICA = 'BEZVfZrOAgzNMnSS4Hpt-PKwchrfEaW5igUoXdZILQqBWdeC9D2RTp_-JfrTagRU4eK2FM0zC3U0GXYS2LUwiyk';

  function b64ToU8(b64){
    const pad = '='.repeat((4 - b64.length % 4) % 4);
    const raw = atob((b64 + pad).replace(/-/g, '+').replace(/_/g, '/'));
    return Uint8Array.from(raw, c => c.charCodeAt(0));
  }
  /* hash curto do endpoint/token — vira nome de campo no Firestore (sem . nem /) */
  function hashEndpoint(s){
    let h = 5381;
    for(let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) >>> 0;
    return h.toString(36);
  }

  function criarWeb(win){
    const nav = win.navigator || {};
    const suportado = () => 'serviceWorker' in nav && 'PushManager' in win && 'Notification' in win;
    async function atual(){
      const reg = await nav.serviceWorker.getRegistration();
      return reg?.pushManager ? reg.pushManager.getSubscription() : null;
    }
    async function ativar(){
      const perm = await win.Notification.requestPermission();
      if(perm !== 'granted') return false;
      const reg = await nav.serviceWorker.getRegistration();
      if(!reg?.active) throw new Error('Aguarde a preparação do aplicativo e tente novamente.');
      const sub = await reg.pushManager.subscribe({ userVisibleOnly:true, applicationServerKey:b64ToU8(VAPID_PUBLICA) });
      const j = sub.toJSON();
      try{
        await win.CLOUD.savePushSub(hashEndpoint(sub.endpoint), { endpoint:j.endpoint, keys:j.keys, criado:new Date().toISOString() });
      }catch(err){
        await sub.unsubscribe().catch(e => win.OBRA_DIAG?.registra('push-limpeza', e.message, e.stack));
        throw err;
      }
      return true;
    }
    async function desativar(){
      const sub = await atual();
      if(!sub) return;
      const chave = hashEndpoint(sub.endpoint);
      await sub.unsubscribe();
      await win.CLOUD.removePushSub(chave);
    }
    return {
      suportado,
      permissao: async() => win.Notification.permission,
      inscrito: async() => !!(await atual()),
      ativar, desativar,
      /* auth.js chama isto antes do logout — a inscrição precisa morrer junto com a sessão. */
      desativa: () => suportado() ? desativar() : Promise.resolve(),
      aoAbrirNotificacao(){},
    };
  }

  function criar(win){ return criarWeb(win); }

  if(typeof module !== 'undefined') module.exports = { criar, hashEndpoint, b64ToU8, VAPID_PUBLICA };
  if(root) root.OBRA_PUSH = criar(root);
})(typeof window !== 'undefined' ? window : null);

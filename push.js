/* Notificações por aparelho. Web: Web Push (VAPID) pelo service worker. App iOS: FCM.
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
      /* Clique na notificação: app fechado abre ./#obra=<id>; aberto recebe postMessage do SW. */
      aoAbrirNotificacao(fn){
        const m = /^#obra=([\w-]+)$/.exec((win.location && win.location.hash) || '');
        if(m){
          win.history.replaceState(null, '', win.location.pathname + win.location.search);
          fn(m[1]);
        }
        nav.serviceWorker?.addEventListener('message', e => {
          if(e.data && e.data.tipo === 'abrir-obra') fn(e.data.obraId || null);
        });
      },
    };
  }

  /* App iOS: FCM pelo @capacitor-firebase/messaging. O token vai para push/{uid}.tokens;
     a chave fica neste aparelho para o logout conseguir apagar só o próprio token. */
  const CHAVE_TOKEN = 'custta-push-token';
  function criarNativo(win){
    const fcm = () => win.OBRA_NATIVO.plugin('FirebaseMessaging');
    const lerChave = () => { try{ return win.localStorage.getItem(CHAVE_TOKEN); }catch(e){ return null; } };
    async function permissao(){
      const { receive } = await fcm().checkPermissions();
      return receive === 'granted' ? 'granted' : receive === 'denied' ? 'denied' : 'default';
    }
    async function ativar(){
      const { receive } = await fcm().requestPermissions();
      if(receive !== 'granted') return false;
      const { token } = await fcm().getToken();
      const chave = hashEndpoint(token);
      try{
        await win.CLOUD.savePushToken(chave, { token, plataforma:'ios', criado:new Date().toISOString() });
      }catch(err){
        await fcm().deleteToken().catch(e => win.OBRA_DIAG?.registra('push-limpeza', e.message, e.stack));
        throw err;
      }
      try{ win.localStorage.setItem(CHAVE_TOKEN, chave); }catch(e){ win.OBRA_DIAG?.registra('push-token', e.message); }
      return true;
    }
    async function desativar(){
      const chave = lerChave();
      if(!chave) return;
      await fcm().deleteToken();
      await win.CLOUD.removePushToken(chave);
      try{ win.localStorage.removeItem(CHAVE_TOKEN); }catch(e){ /* sem storage não há o que limpar */ }
    }
    return {
      suportado: () => !!fcm(),
      permissao,
      inscrito: async() => !!lerChave(),
      ativar, desativar,
      desativa: () => fcm() ? desativar() : Promise.resolve(),
      aoAbrirNotificacao(fn){
        fcm()?.addListener('notificationActionPerformed', ev => fn(ev?.notification?.data?.obraId || null));
      },
    };
  }

  function criar(win){
    return win && win.OBRA_NATIVO && win.OBRA_NATIVO.ehNativo() ? criarNativo(win) : criarWeb(win);
  }

  if(typeof module !== 'undefined') module.exports = { criar, hashEndpoint, b64ToU8, VAPID_PUBLICA };
  if(root) root.OBRA_PUSH = criar(root);
})(typeof window !== 'undefined' ? window : null);

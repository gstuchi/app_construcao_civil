/* Diagnóstico remoto restrito: nenhuma mensagem livre ou dado de conta sai do app. */
(function(root){
  'use strict';
  const origins = new Set(['window','promise','tema','pwa']);
  const types = new Set(['Error','TypeError','ReferenceError','SyntaxError','RangeError','URIError','EvalError']);
  const files = new Set(['app.js','auth.js','cloud.js','dados.js','calc.js','share.js','ui-confirm.js','pwa.js','tema.js','teclado.js','icons.js','splash.js','splash-pre.js','globe.js','sentry.js']);
  function sanitize(event){
    const values=(event.exception?.values || []).slice(-1).map(value=>({
      type:types.has(value.type)?value.type:'Error',
      value:'Falha técnica no aplicativo',
      stacktrace:{frames:(value.stacktrace?.frames || []).filter(f=>{
        try{return new URL(f.filename).origin===root.location.origin && files.has(new URL(f.filename).pathname.slice(1));}catch{return false;}
      }).slice(-30).map(f=>({filename:root.location.origin+new URL(f.filename).pathname,lineno:Number.isSafeInteger(f.lineno)?f.lineno:undefined,colno:Number.isSafeInteger(f.colno)?f.colno:undefined,in_app:true}))}
    }));
    for(const value of values) if(!value.stacktrace.frames.length) delete value.stacktrace;
    if(!values.length) return null;
    return {event_id:event.event_id,timestamp:event.timestamp,platform:'javascript',level:'error',
      release:root.CUSTTA_SENTRY_CONFIG?.release,environment:root.CUSTTA_SENTRY_CONFIG?.environment,
      user:{ip_address:'0.0.0.0'},exception:{values},tags:{origem:origins.has(event.tags?.origem)?event.tags.origem:'window'}};
  }
  const sdk=root.CusttaSentrySDK, config=root.CUSTTA_SENTRY_CONFIG;
  let active=false, count=0;
  const seen=new Map();
  function capture(origin, message, stack){
    if(!active || !origins.has(origin) || count>=20) return;
    try{
      const frames=sdk.defaultStackParser(String(stack || ''));
      const event=sanitize({exception:{values:[{type:String(message || '').split(':')[0],stacktrace:{frames}}]},tags:{origem:origin}});
      const key=JSON.stringify(event.exception)+origin, now=Date.now();
      if(seen.has(key) && now-seen.get(key)<60000) return;
      seen.set(key,now);count++;
      sdk.captureEvent(event);
    }catch{ /* Monitoramento nunca interrompe uso do app. */ }
  }
  try{
    if(config?.dsn && sdk){
      const dsn=new URL(config.dsn);
      if(dsn.protocol!=='https:' || !/^o\d+\.ingest(?:\.[a-z]+)?\.sentry\.io$/.test(dsn.hostname)) throw Error('DSN inválido');
      sdk.init({dsn:config.dsn,release:config.release,environment:config.environment,
        defaultIntegrations:false,integrations:[],sendDefaultPii:false,sendClientReports:false,
        autoSessionTracking:false,sampleRate:1,maxBreadcrumbs:0,beforeSend:sanitize});
      active=true;
    }
  }catch{ /* Configuração ausente/inválida mantém diagnóstico local. */ }
  root.CUSTTA_MONITOR={capture,sanitize,active:()=>active,flush:()=>active?sdk.flush(2000):Promise.resolve(false)};
  root.addEventListener('error',e=>capture('window',e.error?.name || 'Error',e.error?.stack));
  root.addEventListener('unhandledrejection',e=>capture('promise',e.reason?.name || 'Error',e.reason?.stack));
})(window);

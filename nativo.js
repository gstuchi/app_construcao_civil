/* Ponte única com o Capacitor. Na web tudo é neutro e quem chama segue o
   caminho de sempre; nenhum outro arquivo deve tocar window.Capacitor. */
'use strict';
(function(root){
  function criar(win){
    const cap = () => win && win.Capacitor;
    function ehNativo(){
      try{ return !!(cap() && cap().isNativePlatform && cap().isNativePlatform()); }
      catch(e){ return false; }
    }
    const plugin = nome => ehNativo() ? ((cap().Plugins && cap().Plugins[nome]) || null) : null;
    function registra(origem, err){
      try{ win.OBRA_DIAG?.registra('nativo-' + origem, (err && err.message) || String(err), err && err.stack); }
      catch(e){ /* diagnóstico nunca derruba o app */ }
    }
    async function chama(nome, metodo, args, origem){
      const p = plugin(nome);
      if(!p) return null;
      try{ const r = await p[metodo](args); return r === undefined ? true : r; }
      catch(err){ registra(origem, err); return null; }
    }
    async function compartilharArquivo({ nome, texto, tipo, titulo }){
      const fs = plugin('Filesystem'), share = plugin('Share');
      if(!fs || !share) return null;
      try{
        const { uri } = await fs.writeFile({ path:nome, data:texto, directory:'CACHE', encoding:'utf8', recursive:true });
        await share.share({ title:titulo, files:[uri] });
        return true;
      }catch(err){
        if(/cancel/i.test((err && err.message) || '')) return true; // fechou o share sheet
        registra('share', err);
        throw err;
      }
    }
    function aoSegundoPlano(fn){
      const app = plugin('App');
      if(!app) return;
      try{ app.addListener('appStateChange', estado => { if(estado && !estado.isActive) fn(); }); }
      catch(err){ registra('app', err); }
    }
    return {
      ehNativo, plugin, compartilharArquivo, aoSegundoPlano,
      vibrar: () => chama('Haptics', 'impact', { style:'LIGHT' }, 'haptics'),
      // DARK = texto claro, para fundo escuro
      barraStatus: claro => chama('StatusBar', 'setStyle', { style: claro ? 'LIGHT' : 'DARK' }, 'statusbar'),
      esconderSplash: () => chama('SplashScreen', 'hide', undefined, 'splash'),
    };
  }
  if(typeof module !== 'undefined') module.exports = { criar };
  if(root) root.OBRA_NATIVO = criar(root);
})(typeof window !== 'undefined' ? window : null);

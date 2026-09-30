/* Ponte única com o Capacitor. Na web tudo é neutro e quem chama segue o
   caminho de sempre; nenhum outro arquivo deve tocar window.Capacitor. */
'use strict';
(function(root){
  /* SHA-256 em hex, sem depender de crypto.subtle (só existe em contexto seguro;
     o WKWebView do Capacitor deveria ser, mas o login não pode depender disso). */
  const K = [0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2];
  const hex = bytes => Array.from(bytes, b => b.toString(16).padStart(2, '0')).join('');
  function sha256Puro(texto){
    const bytes = Array.from(new TextEncoder().encode(String(texto)));
    const bits = bytes.length * 8;
    bytes.push(0x80);
    while(bytes.length % 64 !== 56) bytes.push(0);
    bytes.push(0, 0, 0, 0, (bits >>> 24) & 255, (bits >>> 16) & 255, (bits >>> 8) & 255, bits & 255);
    const H = [0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19];
    const w = new Array(64);
    const rotr = (x, n) => (x >>> n) | (x << (32 - n));
    for(let i = 0; i < bytes.length; i += 64){
      for(let t = 0; t < 16; t++) w[t] = (bytes[i+4*t] << 24) | (bytes[i+4*t+1] << 16) | (bytes[i+4*t+2] << 8) | bytes[i+4*t+3];
      for(let t = 16; t < 64; t++){
        const s0 = rotr(w[t-15], 7) ^ rotr(w[t-15], 18) ^ (w[t-15] >>> 3);
        const s1 = rotr(w[t-2], 17) ^ rotr(w[t-2], 19) ^ (w[t-2] >>> 10);
        w[t] = (w[t-16] + s0 + w[t-7] + s1) | 0;
      }
      let [a, b, c, d, e, f, g, h] = H;
      for(let t = 0; t < 64; t++){
        const t1 = (h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + K[t] + w[t]) | 0;
        const t2 = ((rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c))) | 0;
        h = g; g = f; f = e; e = (d + t1) | 0; d = c; c = b; b = a; a = (t1 + t2) | 0;
      }
      H[0] = (H[0] + a) | 0; H[1] = (H[1] + b) | 0; H[2] = (H[2] + c) | 0; H[3] = (H[3] + d) | 0;
      H[4] = (H[4] + e) | 0; H[5] = (H[5] + f) | 0; H[6] = (H[6] + g) | 0; H[7] = (H[7] + h) | 0;
    }
    return H.map(x => (x >>> 0).toString(16).padStart(8, '0')).join('');
  }
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
    async function sha256Hex(texto){
      const subtle = win && win.crypto && win.crypto.subtle;
      if(subtle){
        try{ return hex(new Uint8Array(await subtle.digest('SHA-256', new TextEncoder().encode(String(texto))))); }
        catch(e){ /* cai na implementação pura */ }
      }
      return sha256Puro(texto);
    }
    /* Sign in with Apple nativo. A Apple assina o SHA-256 do nonce; o Firebase
       confere com o nonce cru, que fica com quem chamou. Diferente de `chama`,
       propaga o erro: quem entra precisa separar desistência de falha. */
    async function entrarApple({ rawNonce } = {}){
      const p = plugin('AppleSignIn');
      if(!p) return null;
      try{ return await p.signIn({ scopes:['EMAIL', 'FULL_NAME'], nonce: await sha256Hex(rawNonce) }); }
      catch(err){
        const code = err && err.code;
        if(code === 'SIGN_IN_CANCELED' || String(code) === '1001')
          throw Object.assign(new Error('Login com a Apple cancelado.'), { code:'auth/user-cancelled' });
        registra('apple', err);
        throw err;
      }
    }
    function aoSegundoPlano(fn){
      const app = plugin('App');
      if(!app) return;
      try{ app.addListener('appStateChange', estado => { if(estado && !estado.isActive) fn(); }); }
      catch(err){ registra('app', err); }
    }
    /* marca <html class="nativo"> (Capacitor) ou <html class="standalone"> (PWA instalado,
       display-mode:standalone ou navigator.standalone do iOS) — Tasks 2 e 4 leem essas classes. */
    function marcarAmbiente(doc){
      const cl = doc && doc.documentElement && doc.documentElement.classList;
      if(!cl) return;
      if(ehNativo()){ cl.add('nativo'); return; }
      const mm = q => { try{ return !!(win.matchMedia && win.matchMedia(q).matches); }catch(e){ return false; } };
      if(mm('(display-mode: standalone)') || (win.navigator && win.navigator.standalone === true)) cl.add('standalone');
    }
    return {
      ehNativo, plugin, compartilharArquivo, aoSegundoPlano, marcarAmbiente, entrarApple,
      vibrar: () => chama('Haptics', 'impact', { style:'LIGHT' }, 'haptics'),
      // DARK = texto claro, para fundo escuro
      barraStatus: claro => chama('StatusBar', 'setStyle', { style: claro ? 'LIGHT' : 'DARK' }, 'statusbar'),
      esconderSplash: () => chama('SplashScreen', 'hide', undefined, 'splash'),
    };
  }
  if(typeof module !== 'undefined') module.exports = { criar, sha256Puro };
  if(root) root.OBRA_NATIVO = criar(root);
  if(root && root.document) root.OBRA_NATIVO.marcarAmbiente(root.document);
})(typeof window !== 'undefined' ? window : null);

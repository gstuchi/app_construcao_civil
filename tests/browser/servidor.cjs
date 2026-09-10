/* Servidor estático zero-dep pra dirigir o app com Playwright. */
const http = require('http'), fs = require('fs'), path = require('path');
const RAIZ = path.resolve(__dirname, '..', '..');
const headers=Object.fromEntries(require('../../vercel.json').headers[0].headers.map(h=>[h.key,h.value]));
// Apenas emuladores locais recebem exceção HTTP/WS; produção mantém HTTPS.
if(process.env.CUSTTA_EMULADORES === '1') headers['Content-Security-Policy']=headers['Content-Security-Policy'].replace("connect-src 'self'", "connect-src 'self' http://127.0.0.1:8080 http://127.0.0.1:9099 ws://127.0.0.1:8080").replace('; upgrade-insecure-requests','');
const TIPOS = { '.html':'text/html', '.js':'text/javascript', '.json':'application/json',
  '.svg':'image/svg+xml', '.png':'image/png', '.woff2':'font/woff2', '.css':'text/css' };

http.createServer((req, res) => {
  let rel = decodeURIComponent(req.url.split('?')[0]);
  if(rel === '/') rel = '/index.html';
  // Suítes nunca enviam diagnóstico ao projeto real. Teste manual explícito
  // substitui esta resposta via Playwright quando autorizado com --send-real.
  if(rel === '/sentry-config.js'){
    res.writeHead(200,{...headers,'content-type':'text/javascript'});
    res.end('window.CUSTTA_SENTRY_CONFIG={dsn:""};');return;
  }
  const arq = path.join(RAIZ, rel);
  if(!arq.startsWith(RAIZ)){ res.writeHead(403).end(); return; }
  fs.readFile(arq, (err, buf) => {
    if(err){ res.writeHead(404).end('nao achei'); return; }
    res.writeHead(200, { ...headers, 'content-type': TIPOS[path.extname(arq)] || 'application/octet-stream' });
    res.end(buf);
  });
}).listen(8123, () => console.log('servindo em http://localhost:8123'));

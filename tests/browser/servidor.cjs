/* Servidor estático zero-dep pra dirigir o app com Playwright. */
const http = require('http'), fs = require('fs'), path = require('path');
const RAIZ = path.resolve(__dirname, '..', '..');
const TIPOS = { '.html':'text/html', '.js':'text/javascript', '.json':'application/json',
  '.svg':'image/svg+xml', '.png':'image/png', '.woff2':'font/woff2', '.css':'text/css' };

http.createServer((req, res) => {
  let rel = decodeURIComponent(req.url.split('?')[0]);
  if(rel === '/') rel = '/index.html';
  const arq = path.join(RAIZ, rel);
  if(!arq.startsWith(RAIZ)){ res.writeHead(403).end(); return; }
  fs.readFile(arq, (err, buf) => {
    if(err){ res.writeHead(404).end('nao achei'); return; }
    res.writeHead(200, { 'content-type': TIPOS[path.extname(arq)] || 'application/octet-stream' });
    res.end(buf);
  });
}).listen(8123, () => console.log('servindo em http://localhost:8123'));

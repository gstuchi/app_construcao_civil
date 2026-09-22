/* Service worker — network-first. Online sempre pega a versão nova; o cache
   é só o retrato pra funcionar offline. Bump CACHE ao mudar arquivos. */
const CACHE = 'obras-v50';
const ASSETS = ['./vendor/sentry/sentry.js', './sentry-config.js', './sentry.js', './vendor/firebase/firebase-app.js', './vendor/firebase/firebase-auth.js', './vendor/firebase/firebase-firestore.js', './vendor/firebase/shared-VONABDH2.js', './styles.css', './privacidade.css', './dados.js', './cadastro.js', './', './index.html', './app.js', './push.js', './share.js', './ui-confirm.js', './privacidade.html', './auth.js', './globe.js', './calc.js', './cloud.js', './icons.js', './splash.js', './splash-pre.js', './teclado.js', './tema.js', './nativo.js', './pwa.js', './manifest.json', './apple-touch-icon.png', './icon-192.png', './icon-512.png', './fontes/hanken-grotesk-800.woff2'];

self.addEventListener('install', e => {
  // {cache:'reload'} garante que o precache pega os arquivos frescos, não o cache HTTP do browser
  e.waitUntil(
    caches.open(CACHE).then(c => Promise.all(
      ASSETS.map(u => fetch(new Request(u, { cache: 'reload' })).then(r => c.put(u, r)).catch(() => {}))
    )).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  if (!e.request.url.startsWith(self.location.origin)) return; // Firebase/CDN direto na rede
  // network-first: tenta a rede (versão atual), guarda uma cópia e cai no cache só se offline
  e.respondWith(
    fetch(e.request).then(res => {
      if(!res.ok) return res; // não troca cache funcional por 404/500 temporário
      const copy = res.clone();
      caches.open(CACHE).then(c => c.put(e.request, copy)).catch(() => {});
      return res;
    }).catch(() => caches.match(e.request).then(hit => hit || caches.match('./index.html')))
  );
});

/* Push: o cron diário manda { titulo, corpo, obraId? } via Web Push. */
self.addEventListener('push', e => {
  let d = {};
  try{ d = e.data.json(); }catch(err){}
  e.waitUntil(self.registration.showNotification(d.titulo || 'Custta', {
    body: d.corpo || '',
    icon: './icon-192.png',
    badge: './icon-192.png',
    data: { obraId: typeof d.obraId === 'string' ? d.obraId : null },
  }));
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  const obraId = e.notification.data && e.notification.data.obraId;
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(ws => {
      // prioriza uma aba do app (./ ou ./index.html); privacidade.html ou outra
      // página aberta não serve pra receber o postMessage de abrir obra
      const app = ws.find(w => 'focus' in w && /\/(index\.html)?$/.test(new URL(w.url).pathname));
      if(app){
        if(obraId) app.postMessage({ tipo: 'abrir-obra', obraId });
        return app.focus();
      }
      return clients.openWindow(obraId ? './#obra=' + encodeURIComponent(obraId) : './');
    })
  );
});

/* Service worker — network-first. Online sempre pega a versão nova; o cache
   é só o retrato pra funcionar offline. Bump CACHE ao mudar arquivos. */
const CACHE = 'obras-v21';
const ASSETS = ['./', './index.html', './app.js', './auth.js', './globe.js', './calc.js', './cloud.js', './icons.js', './splash.js', './manifest.json', './icon.svg'];

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
      const copy = res.clone();
      caches.open(CACHE).then(c => c.put(e.request, copy)).catch(() => {});
      return res;
    }).catch(() => caches.match(e.request).then(hit => hit || caches.match('./index.html')))
  );
});

/* Push: o cron diário (GitHub Actions) manda { titulo, corpo } via Web Push. */
self.addEventListener('push', e => {
  let d = {};
  try{ d = e.data.json(); }catch(err){}
  e.waitUntil(self.registration.showNotification(d.titulo || 'Minhas Obras', {
    body: d.corpo || '',
    icon: './icon-192.png',
    badge: './icon-192.png',
  }));
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(ws => {
      for(const w of ws){ if('focus' in w) return w.focus(); }
      return clients.openWindow('./');
    })
  );
});

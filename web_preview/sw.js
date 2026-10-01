// MycoTrack Pro - Service Worker (Safari iOS & Android Universal Compatibility)
const CACHE_NAME = 'mycotrack-cache-v2';
const STATIC_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './icon.svg',
  './icon-192.png',
  './icon-512.png',
  './apple-touch-icon.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[MycoTrack SW] Caching app shell assets');
      return cache.addAll(STATIC_ASSETS).catch(e => console.warn('Cache addAll note:', e));
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            console.log('[MycoTrack SW] Purging obsolete cache:', key);
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Network-First with Cache Fallback - STRICTLY for same-origin GET requests
self.addEventListener('fetch', (event) => {
  // Only intercept same-origin requests (never cross-origin like Google APIs, CDNs, GitHub)
  if (!event.request.url.startsWith(self.location.origin) || event.request.method !== 'GET') {
    return;
  }

  // Never intercept APK downloads, Firestore REST or external redirects
  if (event.request.url.includes('/MycoTrackPro.apk') ||
      event.request.url.includes('firestore.googleapis.com')) {
    return;
  }

  event.respondWith(
    fetch(event.request)
      .then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200) {
          const responseClone = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseClone);
          });
        }
        return networkResponse;
      })
      .catch(async () => {
        // Safe fallback - NEVER return undefined to respondWith (crashes Safari WebKit)
        const cached = await caches.match(event.request);
        if (cached) return cached;
        if (event.request.mode === 'navigate') {
          const indexCached = await caches.match('./index.html');
          if (indexCached) return indexCached;
        }
        return new Response('Network offline', { status: 503, statusText: 'Service Unavailable' });
      })
  );
});

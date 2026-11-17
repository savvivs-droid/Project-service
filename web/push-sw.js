// Service worker для push-уведомлений веб-версии (см. web/push.js).
// Показывает уведомление и по нажатию открывает/поднимает приложение.

self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});

function appUrl() {
  // Область этого worker'а — <приложение>/push/, само приложение уровнем выше.
  return new URL('../', self.registration.scope).href;
}

self.addEventListener('push', function (event) {
  var data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (e) {
    data = { body: event.data ? event.data.text() : '' };
  }
  event.waitUntil(
    self.registration.showNotification(data.title || 'FixMyGastro', {
      body: data.body || '',
      icon: new URL('../icons/Icon-192.png', self.registration.scope).href,
      badge: new URL('../icons/Icon-192.png', self.registration.scope).href,
      tag: data.requestId ? data.type + '-' + data.requestId : undefined,
      data: { url: appUrl() },
    })
  );
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var url = (event.notification.data && event.notification.data.url) || appUrl();
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (windows) {
      for (var i = 0; i < windows.length; i++) {
        if (windows[i].url.indexOf(url) === 0 && 'focus' in windows[i]) {
          return windows[i].focus();
        }
      }
      return self.clients.openWindow(url);
    })
  );
});

// Web Push для веб-версии FixMyGastro. Вызывается из Dart
// (lib/services/web_push_bridge_web.dart) через window.fmgPush.
//
// Service worker с обработкой push живёт в отдельной области (scope
// "push/"), чтобы не пересекаться с flutter_service_worker.js, который
// при каждой загрузке снимает себя, чтобы не мешал кэш.
(function () {
  var SW_URL = 'push-sw.js';
  var SW_SCOPE = 'push/';

  function isIos() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) ||
      (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  }

  function isStandalone() {
    return window.navigator.standalone === true ||
      (window.matchMedia && window.matchMedia('(display-mode: standalone)').matches);
  }

  function isSupported() {
    return 'serviceWorker' in navigator && 'PushManager' in window &&
      'Notification' in window;
  }

  function urlBase64ToUint8Array(base64String) {
    var padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    var base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    var raw = atob(base64);
    var output = new Uint8Array(raw.length);
    for (var i = 0; i < raw.length; i++) output[i] = raw.charCodeAt(i);
    return output;
  }

  // navigator.serviceWorker.ready тут не подходит — страница не входит в
  // область "push/", поэтому ждём активации регистрации сами.
  function waitForActive(registration) {
    if (registration.active) return Promise.resolve(registration);
    var worker = registration.installing || registration.waiting;
    return new Promise(function (resolve, reject) {
      if (!worker) return reject(new Error('no service worker'));
      worker.addEventListener('statechange', function () {
        if (worker.state === 'activated') resolve(registration);
        if (worker.state === 'redundant') reject(new Error('service worker redundant'));
      });
    });
  }

  function register() {
    return navigator.serviceWorker
      .register(SW_URL, { scope: SW_SCOPE })
      .then(waitForActive);
  }

  // Нажатие на уведомление: данные приходят либо в адресе (?fmg_push=…,
  // приложение запущено нажатием), либо сообщением от service worker
  // (приложение уже было открыто). Dart забирает их через takeTap/onTap.
  var pendingTap = null;
  var tapListener = null;

  function deliverTap(data) {
    var json = JSON.stringify(data || {});
    if (tapListener) {
      tapListener(json);
    } else {
      pendingTap = json;
    }
  }

  try {
    var params = new URLSearchParams(window.location.search);
    var fromUrl = params.get('fmg_push');
    if (fromUrl) {
      pendingTap = fromUrl;
      params.delete('fmg_push');
      var query = params.toString();
      window.history.replaceState(null, '',
        window.location.pathname + (query ? '?' + query : '') + window.location.hash);
    }
  } catch (e) {}

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.addEventListener('message', function (event) {
      if (event.data && event.data.fmgPushTap) deliverTap(event.data.fmgPushTap);
    });
    if (navigator.serviceWorker.startMessages) navigator.serviceWorker.startMessages();
  }

  window.fmgPush = {
    takeTap: function () {
      var json = pendingTap;
      pendingTap = null;
      return json;
    },

    onTap: function (callback) {
      tapListener = callback;
    },

    // 'unsupported' | 'needs-install' | 'default' | 'granted' | 'denied'
    status: function () {
      if (!isSupported()) {
        return isIos() && !isStandalone() ? 'needs-install' : 'unsupported';
      }
      return Notification.permission;
    },

    // Спрашивает разрешение (только по нажатию кнопки — иначе iPhone
    // откажет) и возвращает подписку как JSON-строку, либо null.
    subscribe: function (vapidPublicKey) {
      if (!isSupported()) return Promise.resolve(null);
      return Notification.requestPermission().then(function (permission) {
        if (permission !== 'granted') return null;
        return register().then(function (registration) {
          return registration.pushManager.getSubscription().then(function (existing) {
            return existing || registration.pushManager.subscribe({
              userVisibleOnly: true,
              applicationServerKey: urlBase64ToUint8Array(vapidPublicKey),
            });
          });
        }).then(function (subscription) {
          return subscription ? JSON.stringify(subscription) : null;
        });
      }).catch(function (error) {
        console.warn('Web push subscribe failed', error);
        return null;
      });
    },

    // Уже выданная подписка (разрешение было дано раньше) — без запроса.
    currentSubscription: function () {
      if (!isSupported() || Notification.permission !== 'granted') {
        return Promise.resolve(null);
      }
      return register().then(function (registration) {
        return registration.pushManager.getSubscription();
      }).then(function (subscription) {
        return subscription ? JSON.stringify(subscription) : null;
      }).catch(function (error) {
        console.warn('Web push lookup failed', error);
        return null;
      });
    },
  };
})();

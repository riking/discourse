export default {
  name: 'register-service-worker',
  after: 'message-bus',
  initialize: function (container) {
    if (!navigator) {
      return;
    }
    if (!navigator.serviceWorker) {
      return;
    }

    const messageBus = container.lookup('message-bus:main'),
      siteSettings = container.lookup('site-settings:main'),
      user = container.lookup('current-user:main');

    if (!user) {
      // TODO some other way to clear variables on logout?
      navigator.serviceWorker.getRegistration().then(function(reg) {
        if (reg) {
          reg.unregister();
        }
      });
      return;
    }

    // TODO default Discourse.BaseUri to ''
    const url = Discourse.BaseUri === '/' ? Discourse.BaseUri + '/worker.js' : '/worker.js';
    const self = this;
    const regPromise = navigator.serviceWorker.register(url, {
      scope: Discourse.BaseUri || '/'
    });

    if (siteSettings.long_polling_base_url !== '/') {
      // too bad you don't get message bus multiplexing
      console.info('Real-time update multiplexing is disabled due to long_polling_base_url being on a different domain.');
      // so sad
    } else {
      regPromise.then(function(reg) {
        if (reg.active) {
          self.sendMessageBusSettings(messageBus);
        }
      });
    }
  },

  sendMessageBusSettings(messageBus) {
    const data = {
      alwaysLongPoll: messageBus.alwaysLongPoll,
      callbackInterval: messageBus.callbackInterval,
      backgroundCallbackInterval: messageBus.backgroundCallbackInterval,
      baseUrl: messageBus.baseUrl,
      enableLongPolling: messageBus.enableLongPolling,
      // shared_session_key: $('meta[name=shared_session_key]').attr('content'),
    };

    Discourse.ajax(`${messageBus.baseUrl}message-bus/settings.json`, {
      type: 'POST',
      data: data
    }).then(() => console.log('message-bus working')).catch((err) => {
      console.error("MessageBus serviceworker failed:", err);
    });
  }
}

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
      siteSettings = container.lookup('site-settings:main');

    const url = Discourse.WorkerUrl;
    const self = this;
    const regPromise = navigator.serviceWorker.register(url, {
      scope: Discourse.BaseUri
    });

    if (siteSettings.long_polling_base_url !== '/') {
      let mbScriptUrl;
      mbScriptUrl = `${siteSettings.long_polling_base_url}message-bus/worker.js`;

      // TODO - DOMException: Failed to register a ServiceWorker: The origin of the provided scriptURL does not match the current origin
      navigator.serviceWorker.register(mbScriptUrl, {
        scope: `${siteSettings.long_polling_base_url}message-bus/`
      }).then(function(reg) {
        if (reg.active) {
          self.sendMessageBusSettings(messageBus);
        }
      }).catch(function(err) {
        console.error(err);
      });
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
      shared_session_key: $('meta[name=shared_session_key]').attr('content')
    };

    Discourse.ajax(`${messageBus.baseUrl}message-bus/settings.json`, {
      type: 'POST',
      data: data
    }).then(() => console.log('message-bus working')).catch((err) => {
      console.error("MessageBus serviceworker failed:", err);
    });
  }
}

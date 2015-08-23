export default {
  name: 'register-service-worker',
  initialize: function () {
    if (!navigator) {
      return;
    }
    if (!navigator.serviceWorker) {
      return;
    }
    const url = Discourse.WorkerUrl;
    navigator.serviceWorker.register(url, {
      scope: '/'
    }).then(function(reg) {
      // reg: ServiceWorkerRegistration https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration
      debugger;
      Discourse.set('serviceWorkerRegistration', reg);
      Em.Logger.info("Registered service worker");
    });
  }
}

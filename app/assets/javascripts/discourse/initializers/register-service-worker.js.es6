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
      scope: Discourse.BaseUri
    }).then(function(reg) {
      // reg: ServiceWorkerRegistration https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration

      // if we ever need the registration, stash it from here
    });
  }
}

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

    window.addEventListener('message', function(event) {
      if (typeof event.data === "object") {
        if (event.data.type === 'serviceWorkerUpdated') {
          console.log(event.origin);
          console.log(event.data);
          console.log(event.source === navigator.serviceWorker.controller);
          debugger;
        }
      }
    });
  }
}

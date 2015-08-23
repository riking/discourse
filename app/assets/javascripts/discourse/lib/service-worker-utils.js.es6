
let haveWorker = null;
function checkServiceWorker() {
  if (!navigator || !navigator.serviceWorker || !navigator.serviceWorker.controller) {
    return Em.RSVP.resolve(false);
  }

  if (haveWorker !== null) {
    return Em.RSVP.resolve(haveWorker);
  }
  const self = this;
  return Discourse.ajax("/srv/worker-test", {cache: true}).then(function(result) {
    // result is either true or false
    haveWorker = result;
    if (haveWorker) {
      Em.Logger.info("Have a functioning ServiceWorker.");
    } else {
      Em.Logger.warn("There's a controlling ServiceWorker, but it doesn't seem to work right!");
    }
    return result;
  });
}

export { checkServiceWorker }

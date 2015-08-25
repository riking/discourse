"use strict";

function refreshAllSiteData() {
  return utils.resolve();
  //return async.allPromises(
  //  [
  //    utils.djfetch('/site/settings.json').then(function(json) {
  //      self.Discourse.SiteSettings = json;
  //    }),
  //    utils.djfetch('/site.json').then(function(json) {
  //      self.Discourse.Groups = json.groups;
  //      self.Discourse.Categories = json.categories;
  //    }),
  //    utils.djfetch('/site/custom_html.json').then(function(json) {
  //      self.Discourse.CustomHTML = json;
  //    }),
  //    utils.djfetch('/site/banner.json').then(function(json) {
  //      self.Discourse.Banner = json;
  //    }),
  //    utils.djfetch('/site/emoji.json').then(function(json) {
  //      self.Discourse.CustomEmoji = json;
  //    }),
  //  ]
  //);
}

self.addEventListener('install', function(evt) {
  console.log('installing');
  self.Discourse = {};
  self.MessageBusRegex = /^\/message-bus\/([0-9a-f]{32})\/poll\??$/;

  evt.waitUntil(async.allPromises(
    [
      refreshAllSiteData(),
    ]
  ).then(function() {console.log('Installed')}));
});

self.addEventListener('activate', function(evt) {
  console.log('Activating');
});

self.addEventListener('fetch', function(evt) {
  // evt.request
  // bodyUsed: false
  // context: "internal"
  // credentials: "same-origin"
  // headers: {}
  // method: "GET"
  // mode: "no-cors"
  // referrer: ""
  // url: "https://discourse.example.com/"
  const request = evt.request,
    url = request.url,
    uri = utils.parseUri(url),
    uriHost = uri.authority;
  const locHost = self.location.host;

  let path;

  if (locHost === uriHost) {
    if (uri.path.substring(0, self.BaseUri.length) !== self.BaseUri) {
      return;
    }
    path = uri.path.substring(self.BaseUri.length);
  } else {
    return;
  }

  if (path === '/srv/worker-test') {
    console.log("Got request for worker-test");
    return evt.respondWith(new Response("true"));
  } else if (self.MessageBusRegex.test(path)) {
    console.log("Captured message-bus request");
    const match = self.MessageBusRegex.exec(path);

    evt.respondWith(
      mbus.intercept(request)
    );
    debugger;
    // TODO
  }
});

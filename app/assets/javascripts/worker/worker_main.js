"use strict";

const async = self.async,
  utils = self.utils;

function refreshAllSiteData() {
  return async.allPromises(
    [
      utils.djfetch('/site/settings.json').then(function(json) {
        self.Discourse.SiteSettings = json;
      }),
      utils.djfetch('/site.json').then(function(json) {
        self.Discourse.Groups = json.groups;
        self.Discourse.Categories = json.categories;
      }),
      utils.djfetch('/site/custom_html.json').then(function(json) {
        self.Discourse.CustomHTML = json;
      }),
      utils.djfetch('/site/banner.json').then(function(json) {
        self.Discourse.Banner = json;
      }),
      utils.djfetch('/site/emoji.json').then(function(json) {
        self.Discourse.CustomEmoji = json;
      }),
    ]
  );
}

self.addEventListener('install', function(evt) {
  console.log('Installing...');

  const promises = [
    refreshAllSiteData(),
  ];

  if (Discourse.Environment === "development") {
    //promises.push(self.skipWaiting()); // turn on in prod?
  }
  evt.waitUntil(async.allPromises(promises).then(() => console.log('Installed.')));
});

self.addEventListener('activate', function(evt) {
  console.log('Activating...');

  const promises = [
  ];

  if (Discourse.Environment === "development") {
    // TODO does this do anything
    //promises.push(self.clients.claim()); // turn on in prod?
  }
  evt.waitUntil(async.allPromises(promises).then(() => console.log('New ServiceWorker activated.')));
});

self.addEventListener('fetch', function(evt) {
  // evt.request
  // bodyUsed: false
  // context: "internal"
  // credentials: "same-origin"
  // headers: {}
  // integrity: ""
  // method: "GET"
  // mode: "no-cors"
  // referrer: "https://discourse.example.com"
  // url: "https://discourse.example.com/stylesheets/desktop-abcde1236873de.css"
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
    console.log("Got /srv/worker-test");
    return evt.respondWith(new Response("true"));
  } else if (path === '/message-bus/settings.json') {
    console.log('Got /message-bus/settings (???)');
  }
});

"use strict";

function refreshAllSiteData() {
  if (!self.ENABLE_PARTIAL_PRELOAD) {
    return utils.resolve();
  }
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

function createPreloadData() {
  if (!self.ENABLE_PARTIAL_PRELOAD) {
    return utils.reject('not enabled');
  }

}

self.addEventListener('install', function(evt) {
  console.log('installing');
  if (self.CDN.length > 0) {
    self.HaveCDN = true;
    const cdnUri = utils.parseUri(self.CDN);
    self.CDNHost = cdnUri.authority;
  }
  self.Discourse = {};
  self.ENABLE_PARTIAL_PRELOAD = false;

  evt.waitUntil(async.allPromises(
    [
      refreshAllSiteData(),
    ]
  ));
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
  } else if (self.HaveCDN && self.CDNHost === uriHost) {
    // todo
    return;
  } else {
    return;
  }

  if (path === '/srv/worker-test') {
    console.log("Got request for worker-test");
    return evt.respondWith(new Response("true"));
  } else if (path === '/__sv_preload_data.js') {
    evt.respondWith(createPreloadData());
  } else if (/^\/message-bus\/[0-9a-f]{32}\/poll\??^/.test(path)) {
    console.log("Captured message-bus request");
    // TODO
  } else if (self.ENABLE_PARTIAL_PRELOAD &&
      request.method === "GET" &&
      !/\.json$/.test(path) &&
      !request.headers.has('X-Requested-With') &&
      true) {

    const newRequest = new Request(request);
    newRequest.headers.set('Discourse-Skip-Preload', 1); // version 1
    evt.respondWith(fetch(newRequest).then(function (response) {
      if (response.headers.get('Discourse-Skip-Preload-Ack')) {
        return response.text().then(function (responseText) {
          return responseText.replace('###SkipPreload###', "<script src='" + self.BaseUri + "/__sv_preload_data.js'>");
        }).then(function (editedText) {
          return new Response(editedText);
        });
      } else {
        return response;
      }
    }));
  }
});

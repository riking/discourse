
self.addEventListener('install', function(evt) {

});

self.addEventListener('activate', function(evt) {

});

self.addEventListener('fetch', function(evt) {
  const url = evt.request.url;
  console.log("Handling request for", url);

  if (url === "/srv/worker-test") {
    evt.respondWith(new Response("true"));
  } else if (url) {

  }
});

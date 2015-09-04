"use strict";

const backlog = {};
const pendingClients = [];

function intercept(request) {
  return request.json().then(function(jsonBody) {

  });
}

self.addEventListener('fetch', function(evt) {

});

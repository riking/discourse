"use strict";
// parseUri 1.2.2
// (c) Steven Levithan <stevenlevithan.com>
// MIT License
const PARSE_URI_REGEX = /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/;
const PARSE_URI_DATA = {
  key: ["source","protocol","authority","userInfo","user","password","host","port","relative","path","directory","file","query","anchor"],
  q:   {
    name:   "queryKey",
    parser: /(?:^|&)([^&=]*)=?([^&]*)/g
  }};
function parseUri(str) {
  var m  = PARSE_URI_REGEX.exec(str),
    o = PARSE_URI_DATA,
    uri = {},
    i   = 14;
  while (i--) uri[o.key[i]] = m[i] || "";
  uri[o.q.name] = {};
  uri[o.key[12]].replace(o.q.parser, function ($0, $1, $2) {
    if ($1) uri[o.q.name][$1] = $2;
  });
  return uri;
};
// --

function dfetch(url, opts) {
  opts = opts || {};
  opts.credentials = 'include';
  opts.headers = opts.headers || new Headers();
  opts.headers.append('X-Requested-With', 'XMLHttpRequest')
  return fetch(self.BaseUri + url, opts);
}
function djfetch(url, opts) {
  return dfetch(url, opts).then(function(response) { return response.json(); });
}

function cloneHeaders(old) {
  const nhead = new Headers();
  old.forEach(function(k, v) {
    nhead.append(k, v);
  });
  return nhead;
}

function resolve(val) {
  return new Promise(function(resolve) {
    resolve(val);
  });
}

function reject(val) {
  return new Promise(function(_, reject) {
    reject(val);
  });
}

self.utils = {
  parseUri, dfetch, djfetch, cloneHeaders, resolve, reject
};

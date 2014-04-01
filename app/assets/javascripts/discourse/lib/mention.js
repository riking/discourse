/**
  Helps us determine whether someone has been mentioned by looking up their username.

  @class Mention
  @namespace Discourse
  @module Discourse
**/
Discourse.Mention = (function() {
  var localCache = {};

  var cache = function(name, valid) {
    localCache[name] = valid;
  };

  var lookupCache = function(name) {
    return localCache[name];
  };

  /**
    Check if a name is a username on this site.

    TODO this is a Zalgo API (http://blog.izs.me/post/59142742143/designing-apis-for-asynchrony)

    @param name username
    @param callback function to execute
    @returns {boolean} if the callback was not executed immediately
  **/
  var lookup = function(name, callback) {
    var cached = lookupCache(name);
    if (cached === true || cached === false) {
      callback(cached);
      return false;
    } else {
      // TODO catch method
      // please do that AFTER fixing the Zalgo problem
      Discourse.ajax("/users/is_local_username", { data: { username: name } }).then(function(r) {
        cache(name, r.valid);
        callback(r.valid);
      });
      return true;
    }
  };

  var load = function(e) {
    var $elem = $(e);
    if ($elem.data('mention-tested')) return;
    var username = $elem.text();
    username = username.substr(1);
    var loading = lookup(username, function(valid) {
      if (valid) {
        $elem.replaceWith("<a href='" + Discourse.getURL("/users/") + (username.toLowerCase()) + "' class='mention'>@" + username + "</a>");
      } else {
        $elem.removeClass('mention-loading').addClass('mention-tested');
      }
    });
    if (loading) {
      return $elem.addClass('mention-loading');
    }
    return undefined;
  };

  return { load: load, lookup: lookup, lookupCache: lookupCache };
})();



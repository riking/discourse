
Discourse.ExplorerQuery = Discourse.Model.extend({

  save: function() {
    
  }
});

Discourse.ExplorerQuery.reopenClass({
  findAll: function() {
    return Discourse.ajax('/explorer/list.json').then(function(queries) {
      return queries.map(function(q) { Discourse.ExplorerQuery.create(q); });
    });
  },

  find: function(id) {
    return Discourse.ajax('/explorer/show/' + id + '.json').then(function(json) {
      return Discourse.ExplorerQuery.create(json);
    });
  }
});
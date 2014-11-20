
Discourse.ExplorerQuery = Discourse.Model.extend({

  save: function() {
    return Discourse.ajax('/explorer/save/' + this.get('id'), { type: "POST", data: {
      name: this.get('name'),
      query: this.get('query'),
      params: this.get('param_list'),

    }});
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
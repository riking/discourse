//import ExplorerQueryParam from 'discourse/models/explorer_query_param' // TODO ES6

const ExplorerQuery = Discourse.Model.extend({
  deleted: false,

  paramsMap: function() {
    let map = {};
    this.get('params').forEach(function(param) {
      map[param.get('name')] = param.get('value');
    });
    return map;
  }.property('params.@each.value'),

  paramsJson: function() {
    return this.get('params').map(function(param) {
      return param.getProperties('name', 'default_value', 'type', 'public_edit');
    });
  }.property('params.@each.name', 'params.@each.default_value', 'params.@each.type', 'params.@each.public_edit'),

  setParamNames(names) {
    const ExplorerQueryParam = Discourse.ExplorerQueryParam; // TODO ES6

    const existingParams = this.get('params'),
      existingParamNames = existingParams.map(function(p) { return p.name; });

    var namesToAdd = names.slice(0).filter(function(n) { return existingParamNames.indexOf(n) === -1; });

    let newParams = existingParams.reject(function(p) {
      return names.indexOf(p.name) === -1;
    });
    namesToAdd.forEach(function(name) {
      newParams.push(ExplorerQueryParam.createNew(name));
    });
    newParams = newParams.sortBy('name');

    this.set('params', newParams);
  },

  save() {
    return Discourse.ajax('/explorer/' + this.get('id'), { type: "PUT", data: {
        name: this.get('name'),
        query: this.get('query'),
        description: this.get('description'),
        params: this.get('paramsJson'),
        params_empty: this.get('params.length') === 0,
        public_view: this.get('public_view'),
        public_run: this.get('public_run')
      }
    }).then(function(resp) {
      return resp;
    });
  },

  trash() {
    const self = this;
    return Discourse.ajax('/explorer/' + this.get('id'), { type: "DELETE" }).then(function() {
      self.set('deleted', true);
    });
  },

  recover() {
    const self = this;
    return Discourse.ajax('/explorer/' + this.get('id') + '/recover', { type: "PUT" }).then(function() {
      self.set('deleted', false);
    });
  },

  parse() {
    const sql = this.get('query');
    const paramRegex = /(:?):([a-z][a-z_]*)/gi;
    var result;
    let paramNames = [];

    while ( (result = paramRegex.exec(sql)) ) {
      // Skip typecasts
      if (!result[1]) {
        paramNames.push(result[2]);
      }
    }

    // Sort & unique
    paramNames = paramNames.sort().filter(function(el, i, a) {
      return (i === a.indexOf(el));
    });

    this.setParamNames(paramNames);

    return Em.RSVP.resolve();
  },

  run(opts) {
    var args = this.get('paramsMap');
    return Discourse.ajax('/explorer/' + this.get('id') + "/run", { type: "POST", data: {
      params: args,
      explain: !!opts.explain
    }});
  }
});

ExplorerQuery.reopenClass({
  createFromJson(json) {
    const ExplorerQueryParam = Discourse.ExplorerQueryParam; // TODO ES6
    const paramJsonArr = json.params;
    delete json.params;

    let eq = ExplorerQuery.create(json);
    if (paramJsonArr) {
      eq.set('params', paramJsonArr.map(function(paramJson) {
        return ExplorerQueryParam.createFromJson(paramJson);
      }));
      eq.get('params').forEach(function(p) {
        p.reset();
      });
    }
    return eq;
  },

  findAll: function() {
    return Discourse.ajax('/explorer.json').then(function(queries) {
      return queries.map(function(q) { return Discourse.ExplorerQuery.createFromJson(q); });
    });
  },

  find: function(id) {
    return Discourse.ajax('/explorer/' + id + '.json').then(function(json) {
      return Discourse.ExplorerQuery.createFromJson(json.explorer_query);
    });
  }
});

export default ExplorerQuery;

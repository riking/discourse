//import ExplorerQueryParam from 'discourse/models/explorer_query_param' // TODO ES6

const ExplorerQuery = Discourse.Model.extend({

  paramsMap: function() {
    let map = {};
    this.get('params').forEach(function(param) {
      map[param.get('name')] = param.get('value');
    });
    return map;
  }.property('params.@each.value'),

  paramsJson: function() {
    return this.get('params').map(function(param) {
      return param.getProperties('name', 'default_value', 'type');
    });
  }.property('params.@each.name', 'params.@each.default_value', 'params.@each.type'),

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
    console.log('saving');
    return Discourse.ajax('/explorer/save/' + this.get('id'), { type: "POST", data: {
        name: this.get('name'),
        query: this.get('query'),
        description: this.get('description'),
        params: this.get('paramsJson'),
        public_view: this.get('public_view'),
        public_run: this.get('public_run')
      }
    }).then(function(resp) {
      console.log('saved');
      return resp;
    });
  },

  parse() {
    const sql = this.get('query');
    const paramRegex = /:([a-z_]+)/gi;
    var result;
    let paramNames = [];

    while ( (result = paramRegex.exec(sql)) ) {
      paramNames.push(result[1]);
    }

    this.setParamNames(paramNames);

    return Em.RSVP.resolve();
  },

  run(opts) {
    var args = this.get('paramsMap');
    return Discourse.ajax('/explorer/run/' + this.get('id'), { type: "POST", data: {
      params: args,
      explain: opts.explain
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
    }
    return eq;
  },

  findAll: function() {
    return Discourse.ajax('/explorer/list.json').then(function(queries) {
      return queries.map(function(q) { return Discourse.ExplorerQuery.createFromJson(q); });
    });
  },

  find: function(id) {
    return Discourse.ajax('/explorer/show/' + id + '.json').then(function(json) {
      return Discourse.ExplorerQuery.createFromJson(json.explorer_query);
    });
  }
});

export default ExplorerQuery;

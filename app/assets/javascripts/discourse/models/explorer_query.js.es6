
const ExplorerQueryParam = Discourse.Model.extend({

});

ExplorerQueryParam.reopenClass({
  createNew(name) {
    return {name: name, value: "", def: "", type: "string"};
  }
});

const ExplorerQuery = Discourse.Model.extend({

  params: [{name: "user_id", value: "35568", def: "$CURRENTUSERID"}, {name: "backfill", value: "false", def: "false"}],

  setParamNames(names) {
    const existingParams = this.get('params'),
      existingParamNames = existingParams.map(function(p) { return p.name; });

    var namesToAdd = names.slice(0).filter(function(n) { return existingParamNames.indexOf(n) === -1; });
    //var namesToRemove = existingParamNames.filter(function(n) { return names.indexOf(n) === -1; });

    let newParams = existingParams.filter(function(p) {
      return names.indexOf(p.name) === -1;
    });
    namesToAdd.forEach(function(name) {
      newParams.push(ExplorerQueryParam.createNew(name));
    });

    this.set('params', newParams);
  },

  save() {
    return Discourse.ajax('/explorer/save/' + this.get('id'), { type: "POST", data: {
        name: this.get('name'),
        query: this.get('query'),
        params: this.get('params')
      }
    });
  },

  parse() {
    return Discourse.ajax('/explorer/parse.json', { data: { sql: this.get('query')}}).then(function(json) {
      console.log(json);
      return json;
    }).catch(function(xhr) {
      if (xhr.responseJSON) {
        if (xhr.responseJSON.success === false) {
          console.log(xhr.responseJSON);
          return xhr.responseJSON;
        }
      }
      throw xhr;
    });
  }
});

ExplorerQuery.reopenClass({
  findAll: function() {
    return Discourse.ajax('/explorer/list.json').then(function(queries) {
      return queries.map(function(q) { return Discourse.ExplorerQuery.create(q); });
    });
  },

  find: function(id) {
    return Discourse.ajax('/explorer/show/' + id + '.json').then(function(json) {
      return Discourse.ExplorerQuery.create(json.explorer_query);
    });
  }
});

export default ExplorerQuery;

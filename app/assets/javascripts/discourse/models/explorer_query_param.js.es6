
function tryParseJson(j) {
  try {
    JSON.parse(j);
    return true;
  } catch (e) {
    return false;
  }
}

const ExplorerQueryParam = Discourse.Model.extend({
  _init: function() {
    this.reset();
  }.on('init'),

  type: Em.computed.alias('param_type'),

  isComputedValueClass: function() {
    return ExplorerQueryParam.computedValues[this.get('value')] ? "computed" : "";
  }.property('value'),

  computedValue: function() {
    const value = this.get('value');
    if (ExplorerQueryParam.computedValues[value]) {
      return ExplorerQueryParam.computedValues[value]();
    } else {
      return value;
    }
  }.property('value'),

  validate(value) {
    if (value === undefined) {
      value = this.get('value');
    }
    if (ExplorerQueryParam.computedValues[value]) {
      value = ExplorerQueryParam.computedValues[value]();
    }

    switch (this.get('type')) {
      case "string":
        return !Em.isEmpty(value);
      case "integer":
        const int = parseInt(value, 10);
        return /^\d+$/.test(value) && int === (int | 0);
      case "int_list":
        // a number, optionally followed by more numbers separated by commas that are optionally separated by spaces
        const regex = /\d+(\s*,\s*\d+)*/;
        return regex.test(value);
      case "string_list":
        return !Em.isEmpty(value);
      case "json":
        return tryParse(value);
      default:
        console.warn("Bad query parameter validation type:", this.get('type'));
        return false;
    }
  },

  validateIfLocked(value) {
    if (this.get('public_edit')) {
      return true;
    }
    return this.validate(value);
  },

  reset() {
    this.set('value', this.get('default_value'));
  },

  cant_edit: function() {
    if (this.get('public_edit')) {
      return false;
    }
    return !Discourse.User.currentProp('admin');
  }.property('public_edit')
});

ExplorerQueryParam.reopenClass({
  // NB: logic duplicated on server/client
  // server side: app/models/explorer_query_parameter.rb
  availableTypes: ['string', 'integer', 'int_list', 'string_list', 'json'],
  computedValues: {
    '$current_user_id': function() {
      return Discourse.User.currentProp('id');
    },
    '$current_user_name': function() {
      return Discourse.User.currentProp('username');
    },
    '$visible_categories': function() {
      return Discourse.Site.currentProp('categories').map(function (c) {
        return c.id;
      }).join(',');
    }
  },

  createNew(name) {
    return ExplorerQueryParam.create({name: name, default_value: "", type: "string", public_edit: true});
  },
  createFromJson(json) {
    return ExplorerQueryParam.create(json);
  }
});

export default ExplorerQueryParam;

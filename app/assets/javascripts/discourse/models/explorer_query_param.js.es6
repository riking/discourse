const ExplorerQueryParam = Discourse.Model.extend({
  _init: function() {
    this.reset();
  }.on('init'),

  type: Em.computed.alias('param_type'),

  validate(value) {
    if (value === undefined) {
      value = this.get('value');
    }

    switch (this.get('type')) {
      case "string":
        return !Em.isEmpty(value);
      case "current_user_id":
      case "integer":
        const int = parseInt(value, 10);
        return /^\d+$/.test(value) && int === (int | 0);
      case "visible_categories":
      case "int_list":
        // a number, optionally followed by more numbers separated by commas that are optionally separated by spaces
        const regex = /\d+(\s*,\s*\d+)*/;
        return regex.test(value);
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
    switch (this.get('type')) {
      case "string":
      case "integer":
      case "int_list":
      default:
        return this.set('value', this.get('default_value'));
      case "current_user_id":
        return this.set('value', Discourse.User.currentProp('id'));
      case "visible_categories":
        return this.set('value', Discourse.Site.currentProp('categories').map(function (c) {
          return c.id;
        }).join(','));
    }
  },

  cant_edit: function() {
    if (this.get('public_edit')) {
      return false;
    }
    return !Discourse.User.currentProp('admin');
  }.property('public_edit')
});

ExplorerQueryParam.reopenClass({
  availableTypes: ['string', 'integer', 'int_list', 'current_user_id', 'visible_categories'],

  createNew(name) {
    return ExplorerQueryParam.create({name: name, default_value: "", type: "string", public_edit: true});
  },
  createFromJson(json) {
    return ExplorerQueryParam.create(json);
  }
});

export default ExplorerQueryParam;

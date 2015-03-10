
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
      case "integer":
        const int = parseInt(value, 10);
        return /^\d+$/.test(value) && int === (int | 0);
      case "int_list":
        // a number, optionally followed by more numbers separated by commas that are optionally separated by spaces
        const regex = /\d+(\s*,\s*\d+)*/;
        return regex.test(value);
      default:
        console.warn("Bad query parameter validation type:", this.get('type'));
        return false;
    }
  },

  reset() {
    this.set('value', this.get('default_value'));
  }
});

ExplorerQueryParam.reopenClass({
  createNew(name) {
    return ExplorerQueryParam.create({name: name, default_value: "", type: "string"});
  },
  createFromJson(json) {
    return ExplorerQueryParam.create(json);
  }
});

export default ExplorerQueryParam;

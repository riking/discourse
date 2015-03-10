
const ExplorerQueryParam = Discourse.Model.extend({
  _init: function() {
    this.reset();
  }.on('init'),

  validate(value) {
    if (value === undefined) {
      value = this.get('value');
    }

    switch (this.get('type')) {
      case "string":
        return !Em.isEmpty(value);
      case "integer":
        const int = parseInt(value, 10);
        return int === (int | 0);
      case "int_list":
        // a number, optionally followed by more numbers separated by commas that are optionally separated by spaces
        const regex = /\d+(\s*,\s*\d+)*/;
        return regex.test(value);
      default:
        console.warn("Bad query parameter validation type");
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
    let eq = ExplorerQueryParam.create(json);
    if (!eq.get('type')) {
      eq.set('type', 'string');
    }
    return eq;
  }
});

export default ExplorerQueryParam;

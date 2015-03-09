
const ExplorerQueryParam = Discourse.Model.extend({
  _init: function() {
    this.reset();
  }.on('init'),

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

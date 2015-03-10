
const QueryRowContentComponent = Ember.Component.extend({
  tagName: "tr",

  render(buffer) {
    const row = this.get('row');
    this.get('cols').forEach(function(col) {
      buffer.push("<td data-column-name=" + Handlebars.Utils.escapeExpression(col) + ">");
      // TODO swap renderers
      buffer.push(Handlebars.Utils.escapeExpression(row[col]));
      buffer.push("</td>");
    });
  }
});

export default QueryRowContentComponent;

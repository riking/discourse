
const defaultRender = function(buffer, content) {
  buffer.push(Handlebars.Utils.escapeExpression(content));
};

const QueryRowContentComponent = Ember.Component.extend({
  tagName: "tr",

  render(buffer) {
    const row = this.get('row');
    this.get('colRenders').forEach(function(colRender) {
      buffer.push("<td data-column-name=" + Handlebars.Utils.escapeExpression(colRender.name) + ">");
      colRender.render(buffer, row[colRender.name], defaultRender);
      buffer.push("</td>");
    });
  }
});

export default QueryRowContentComponent;

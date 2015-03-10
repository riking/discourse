var ColumnHandlers = [];
var defaultFallback = function(buffer, content, defaultRender) { defaultRender(buffer, content); };

const QueryResultComponent = Ember.Component.extend({
  layoutName: 'explorer-query-result',

  rows: Em.computed.alias('content.rows'),
  columns: Em.computed.alias('content.columns'),
  params: Em.computed.alias('content.params'),
  explainText: Em.computed.alias('content.explain'),

  hasExplain: Em.computed.notEmpty('content.explain'),
  noParams: Em.computed.empty('params'),
  colCount: function() {
    return this.get('content.columns').length;
  }.property('content.columns.length'),

  parameterAry: function() {
    let arr = [];
    const params = this.get('params');
    for (var key in params) {
      if (params.hasOwnProperty(key)) {
        arr.push({key: key, value: params[key]});
      }
    }
    return arr;
  }.property('params.@each'),

  columnHandlers: function() {
    return this.get('columns').map(function(colName) {
      let handler = defaultFallback;

      ColumnHandlers.forEach(function(handlerInfo) {
        if (handlerInfo.regex.test(colName)) {
          handler = handlerInfo.render;
        }
      });

      return {
        name: colName,
        render: handler
      };
    });
  }.property('columns.@each'),

  parent: function() { return this; }.property()

});

ColumnHandlers.push({ regex: /user_id/, render: function(buffer, content, defaultRender) {
  if (!/^\d+$/.test(content)) {
    return defaultRender(buffer, content);
  }
  buffer.push("<a href='/users/by-id/");
  buffer.push(content);
  buffer.push("'>User #");
  buffer.push(content);
  buffer.push("</a>");
}});
ColumnHandlers.push({ regex: /post_id/, render: function(buffer, content, defaultRender) {
  if (!/^\d+$/.test(content)) {
    return defaultRender(buffer, content);
  }
  buffer.push("<a href='/p/");
  buffer.push(content);
  buffer.push("'>Post #");
  buffer.push(content);
  buffer.push("</a>");
}});
ColumnHandlers.push({ regex: /badge_id/, render: function(buffer, content, defaultRender) {
  if (!/^\d+$/.test(content)) {
    return defaultRender(buffer, content);
  }
  buffer.push("<a href='/badges/");
  buffer.push(content);
  buffer.push("/-'>Badge #");
  buffer.push(content);
  buffer.push("</a>");
}});
ColumnHandlers.push({ regex: /topic_id/, render: function(buffer, content, defaultRender) {
  if (!/^\d+$/.test(content)) {
    return defaultRender(buffer, content);
  }
  buffer.push("<a href='/t/");
  buffer.push(content);
  buffer.push("/from-link'>Topic #");
  buffer.push(content);
  buffer.push("</a>");
}});

export default QueryResultComponent;

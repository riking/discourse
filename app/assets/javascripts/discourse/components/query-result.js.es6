/**
  This view handles rendering of the data explorer query results

  @class QueryResultView
  @extends Discourse.View
  @namespace Discourse
  @module Discourse
**/
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
  }.property('params.@each')

});

QueryResultComponent.reopenClass({
  columnNameMatchers: [],
  columnTransformers: [],

  /**
   * Register a function to render columns with particular names.
   *
   * renderer is a function that takes (buffer, rowValue, colName, context).
   *
   * @param regex
   * @param renderer
   */
  registerColumnHandler(regex, renderer) {
    this.columnNameMatchers.push({ regex: regex, cb: renderer });
  },

  /**
   * Register a function to transform the content of every row of columns with particular names.
   *
   * transformer is a function that takes (rows, matchedColName,
   * @param regex
   * @param transformer
   */
  registerColumnTransformer(regex, transformer){

  }
});

export default QueryResultComponent;

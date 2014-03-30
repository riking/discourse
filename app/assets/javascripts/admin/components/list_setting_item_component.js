/**
  One item in a ListSetting.

  @param parent is the ListSettingComponent.

  @class Discourse.ListSettingItemComponent
  @extends Ember.Component, Ember.TextSupport
  @namespace Discourse
  @module Discourse
 **/
Discourse.ListSettingItemComponent = Ember.Component.extend(Ember.TextSupport, {
  classNames: ['ember-text-field'],
  tagName: "input",
  attributeBindings: ['type', 'value', 'size', 'pattern'],

  _initialize: function() {
    // _parentView is the #each
    this.set('value', this.get('_parentView.content'));
    this.set('index', this.get('_parentView.contentIndex'));
    // parent is the ListSettingComponent
    this.get('parent').get('children')[this.get('index')] = this;
    this.on("focusOut", this.get('parent').uncacheValue);
  }.on('init'),

  _elementValueDidChange: function() {
    this._super();
    this.get('parent').setItemValue(this.get('index'), this.get('value'));
  }
});

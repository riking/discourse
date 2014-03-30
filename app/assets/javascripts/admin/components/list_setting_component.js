/**
  Provide a nice GUI for a pipe-delimited list in the site settings.

  @param settingValue is a reference to SiteSetting.value.

  @class Discourse.ListSettingComponent
  @extends Ember.Component
  @namespace Discourse
  @module Discourse
 **/
Discourse.ListSettingComponent = Ember.Component.extend({
  layoutName: 'components/list-setting',

  init: function() {
    this._super();
    this.on("focusOut", this.uncacheValue);
    this.set('children', []);
  },

  canAddNew: true,

  readValues: function() {
    return this.get('settingValue').split('|');
  }.property('settingValue'),

  uncacheValue: function() {
    var oldValue = this.get('settingValue'),
        newValue = this.get('settingValueCached');

    if (newValue !== undefined && newValue !== oldValue) {
      this.set('settingValue', newValue);
    }
  },

  setItemValue: function(index, item) {
    var values = this.get('readValues');
    values[index] = item;

    // Remove blank items
    values = values.filter(function(s) { return s !== ''; });

    this.set('settingValueCached', values.join('|'));
    this.set('canAddNew', true);
  },

  actions: {
    addNewItem: function() {
      this.set('canAddNew', false);
      this.set('settingValue', this.get('settingValue') + '|');
      this.set('settingValueCached', this.get('settingValue'));

      var self = this;
      Em.run.schedule('afterRender', function() {
        var children = self.get('children');
        $(children[children.length - 1].get('element')).focus();
      });
    }
  }
});

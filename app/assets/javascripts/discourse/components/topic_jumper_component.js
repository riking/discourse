/**
  The topic jumper that shows when you click on the progress bar.

  @class TopicJumperComponent
  @extends Ember.Component
  @namespace Discourse
  @module Discourse
**/

Discourse.TopicJumperComponent = Ember.Component.extend({
  jumperHidden: Em.computed.not('topic.jumperActive'),

  init: function() {
    this._super();
  },

  click: function(e) {
    var $target = $(e.target),
        postNumber = $target.data("post-number");

    if (postNumber === undefined) {
      // click was over more than just one slice - no action
      return;
    }
    this.updateSelected(postNumber, true);
  },

  updateSelected: function(num, isActive) {
    if (this.get('selected-number') === num && isActive) {
      return Discourse.URL.routeTo(this.get('topic.model').urlForPostNumber(num));
    }
    this.set('selected-number', num);
    this.set('textValue', num.toString());
  },

  actions: {
    pressEnter: function() {
      var numValue = parseInt(this.get('textValue'), 10);
      if (numValue > 0) {
        this.updateSelected(numValue, true);
      }
    }
  },

  textObserver: function() {
    var numValue = parseInt(this.get('textValue'), 10);
    if (numValue > 0) {
      this.updateSelected(numValue, false);
    }
  }.observes('textValue'),

  currentObserver: function() {
    this.set('current-number', this.get('topic.bottomVisiblePost.post_number'));
  }.observes('topic.bottomVisiblePost')
});

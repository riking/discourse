/**
  All of the items on the timeline.

  @class TimelineCollectionComponent
  @extends Ember.Component
  @namespace Discourse
  @module Discourse
**/

Discourse.TimelineCollectionComponent = Ember.Component.extend({

  init: function() {
    this._super();
    Discourse.ScreenTrack.current().listen(this, this.markRead);
  },

  focusWatcher: function() {
    if (this.get('topic.jumperActive')) {
      setTimeout(function() {
        $("#topic-jumper .center input").focus();
      }, 0);
    }
  }.observes('topic.jumperActive'),

  markRead: function(post_number) {
    var models = this.get('models'),
        self = this;

    // every() is a hack for a short-circuit
    models.every(function(item) {
      // if (isPost(item))
      if (item.post_number === post_number && !item.read) {
        item.read = true;
        self.rerender();
        return false;
      }
      return true;
    });
  },

  arrowWatcher: function() {
    this.rerender();
  }.observes('jumper.current-number', 'jumper.selected-number'),

  render: function(buffer) {
    var models = this.get('models'),
        total = this.get('topic.model.weight_total'),
        self = this;

    models.forEach(function(item) {
      // if (isPost(item))
      self.renderPost(item, buffer, total);
      // else if (isGap(item))
      // renderGap();
    });
  },

  renderPost: function(model, buffer, total) {
    var weight = model.weight,
        percent = 100.0 * weight / total;

    buffer.push("<div class='timeline-item ");
    if (model.read) {
      buffer.push("read ");
    }
    if (model.post_number === this.get('jumper.current-number')) {
      buffer.push("current ");
    }
    if (model.post_number === this.get('jumper.selected-number')) {
      buffer.push("selected ");
    }
    buffer.push("' ");
    buffer.push("data-post-number='");
    buffer.push(model.post_number);
    buffer.push("' ");
    buffer.push("style='width: calc(");
    buffer.push(percent);
    buffer.push("% - 1px);' ></div>");
  }

});

Discourse.NotificationsController = Ember.ArrayController.extend(Discourse.HasCurrentUser, {
  itemController: "notification",

  error: function() {
    return this.get('content') === false;
  }.property('content')
});

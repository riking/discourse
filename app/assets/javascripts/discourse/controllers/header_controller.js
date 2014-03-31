/**
  This controller supports actions on the site header

  @class HeaderController
  @extends Discourse.Controller
  @namespace Discourse
  @module Discourse
**/
Discourse.HeaderController = Discourse.Controller.extend({
  topic: null,
  showExtraInfo: null,
  notifications: null,
  error: true,

  showStarButton: function() {
    return Discourse.User.current() && !this.get('topic.isPrivateMessage');
  }.property('topic.isPrivateMessage'),

  actions: {
    toggleStar: function() {
      var topic = this.get('topic');
      if (topic) topic.toggleStar();
      return false;
    },

    showNotifications: function(headerView) {
      var self = this,
          $userNotifications = $("#user-notifications");


      if ($userNotifications.closest('li').hasClass('active')) {
        // close dropdown
        headerView.showDropdown($userNotifications);
        return;
      }

      Discourse.ajax("/notifications").then(function(result) {
        console.log(result);
        self.set("notifications", result);
        self.set("currentUser.unread_notifications", 0);
        headerView.showDropdown($userNotifications);
      }, function() {
        // display error text
        self.set("notifications", false);
        headerView.showDropdown($userNotifications);
      });
    },

    jumpToTopPost: function () {
      var topic = this.get('topic');
      if (topic) {
        Discourse.URL.routeTo(topic.get('firstPostUrl'));
      }
    }
  }

});



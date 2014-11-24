/**
  This controller supports the interface for granting and revoking badges from
  individual users.

  @class AdminUserBadgesController
  @extends Ember.ArrayController
  @namespace Discourse
  @module Discourse
**/
export default Ember.ArrayController.extend({
  needs: ["adminUser"],
  user: Em.computed.alias('controllers.adminUser'),
  sortProperties: ['granted_at'],
  sortAscending: false,
  postId: null,
  error: null,

  badgesById: function() {
    var idMap = {};
    this.get('badges').forEach(function(badge) {
      idMap[badge.get('id')] = badge;
    });
    return idMap;
  }.property('badges.@each'),

  /**
    Array of badges that have not been granted to this user.

    @property grantableBadges
    @type {Boolean}
  **/
  grantableBadges: function() {
    var granted = {};
    this.get('model').forEach(function(userBadge) {
      granted[userBadge.get('badge_id')] = true;
    });

    var badges = [];
    this.get('badges').forEach(function(badge) {
      if (badge.get('multiple_grant') || !granted[badge.get('id')]) {
        badges.push(badge);
      }
    });

    return badges;
  }.property('badges.@each', 'model.@each'),

  postIdRequired: function() {
    var badge = this.get('badgesById')[this.get('selectedBadgeId')];
    return badge.get('target_posts');
  }.property('badgesById', 'selectedBadgeId'),

  postIdDisabled: Em.computed.not('postIdRequired'),

  submitDisabled: function() {
    if (!this.get('selectedBadgeId')) return true;

    if (this.get('postIdRequired')) {
      return !this.canParsePostId(this.get('postId'));
    }
    return false;
  }.property('selectedBadgeId', 'postIdRequired', 'postId'),

  /**
   * Check if the given string is in the correct format (a postId or a topic and post number).
   * @param str user-given string to check
   */
  canParsePostId: function(str) {
    var match = /(\d+)(\/(\d+))?/.exec(str);
    return !!match;
  },

  /**
    Whether there are any badges that can be granted.

    @property noBadges
    @type {Boolean}
  **/
  noBadges: Em.computed.empty('grantableBadges'),

  actions: {

    /**
      Grant the selected badge to the user.

      @method grantBadge
      @param {Integer} badgeId id of the badge we want to grant.
    **/
    grantBadge: function(badgeId) {
      var self = this,
        postId = (this.get('postIdRequired')) ? this.get('postId') : null;
      self.set('error', null);
      Discourse.UserBadge.grant(badgeId, this.get('user.username'), postId).then(function(userBadge) {
        self.pushObject(userBadge);
        Ember.run.next(function() {
          // Update the selected badge ID after the combobox has re-rendered.
          if (!self.get('badgesById')[badgeId].get('multiple_grant')) {
            var newSelectedBadge = self.get('grantableBadges')[0];
            if (newSelectedBadge) {
              self.set('selectedBadgeId', newSelectedBadge.get('id'));
              self.set('postId', null);
            }
          }
        });
      }, function(ex) {
        if (ex.responseJSON) {
          // magic string
          if (ex.responseJSON.errors[0] === "bad_post_id") {
            self.set('error', I18n.t('admin.badges.bad_post_number'));
          } else {
            self.set('error', ex.responseJSON.errors);
          }
        } else {
          // Failure
          bootbox.alert(I18n.t('generic_error'));
        }
      });
    },

    /**
      Revoke the selected userBadge.

      @method revokeBadge
      @param {Discourse.UserBadge} userBadge the `Discourse.UserBadge` instance that needs to be revoked.
    **/
    revokeBadge: function(userBadge) {
      var self = this;
      return bootbox.confirm(I18n.t("admin.badges.revoke_confirm"), I18n.t("no_value"), I18n.t("yes_value"), function(result) {
        if (result) {
          userBadge.revoke().then(function() {
            self.get('model').removeObject(userBadge);
          });
        }
      });
    }

  }
});

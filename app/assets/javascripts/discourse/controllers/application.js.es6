export default Ember.Controller.extend({
  styleCategory: null,

  canSignUp: function() {
    return !Discourse.SiteSettings.invite_only &&
           Discourse.SiteSettings.allow_new_registrations &&
           !Discourse.SiteSettings.enable_sso;
  }.property('siteSettings.invite_only', 'siteSettings.allow_new_registrations', 'siteSettings.enable_sso'),

  loginRequired: function() {
    return Discourse.SiteSettings.login_required && !Discourse.User.current();
  }.property('siteSettings.login_required')

});

export default Ember.ArrayController.extend(Discourse.HasCurrentUser, {
  showBadgesLink: Discourse.computed.setting('enable_badges'),
  showAdminLinks: Em.computed.alias('currentUser.staff'),
  flaggedPostsCount: Em.computed.alias("currentUser.site_flagged_posts_count"),

  faqUrl: function() {
    return this.get('siteSettings.faq_url') || Discourse.getURL('/faq');
  }.property('siteSettings.faq_url'),

  badgesUrl: Discourse.getURL('/badges'),

  showKeyboardShortcuts: function(){
    return !Discourse.Mobile.mobileView && !this.capabilities.touch;
  }.property(),

  showMobileToggle: function(){
    return Discourse.Mobile.mobileView || (this.get('siteSettings.enable_mobile_theme') && this.capabilities.touch);
  }.property('siteSettings.enable_mobile_theme'),

  mobileViewLinkTextKey: function() {
    return Discourse.Mobile.mobileView ? "desktop_view" : "mobile_view";
  }.property(),

  categories: function() {
    var hideUncategorized = !this.get('siteSettings.allow_uncategorized_topics'),
        showSubcatList = this.get('siteSettings.show_subcategory_list'),
        isStaff = Discourse.User.currentProp('staff');
    return Discourse.Category.list().reject(function(c) {
      if (showSubcatList && c.get('parent_category_id')) { return true; }
      if (hideUncategorized && c.get('isUncategorizedCategory') && !isStaff) { return true; }
      return false;
    });
  }.property('siteSettings.allow_uncategorized_topics', 'siteSettings.show_subcategory_list'),

  actions: {
    keyboardShortcuts: function(){
      Discourse.__container__.lookup('controller:application').send('showKeyboardShortcutsHelp');
    },
    toggleMobileView: function() {
      Discourse.Mobile.toggleMobileView();
    }
  }
});

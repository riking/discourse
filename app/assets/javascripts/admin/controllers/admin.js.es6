import DiscourseController from 'discourse/controllers/controller';

export default DiscourseController.extend({
  showBadges: Em.computed.and('currentUser.admin', 'siteSettings.enable_badges')
});

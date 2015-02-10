export default Discourse.ModalBodyView.extend({
  templateName: 'modal/show-error',
  title: function() {
    return I18n.t('errors.header.' + this.get('controller.model.description'));
  }.property('controller.model.description')
});

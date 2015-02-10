import ModalFunctionality from 'discourse/mixins/modal-functionality';
import ObjectController from 'discourse/controllers/object';

// This controller handles displaying of raw email
export default ObjectController.extend(ModalFunctionality, {
  flashMessage: null,

  xhr: Em.computed.alias('model.xhr'),

  onShow: function() {
    this.set('controllers.modal.modalClass', 'modal-show-error');
  },

  hasResponse: function() {
    return !!this.get('xhr').responseJSON;
  }.property('xhr'),

  hasStatusCode: function() {
    return this.get('xhr').status >= 400;
  }.property('xhr'),

  hasErrorJson: function() {
    return this.get('hasResponse') && !!this.get('xhr').responseJSON.errors;
  }.property('xhr'),

  errorsArray: function() {
    if (this.get('hasErrorJson')) {
      return this.get('xhr').responseJSON.errors;
    }
  }.property('xhr'),

  statusCode: function() {
    return this.get('xhr').status;
  }.property('xhr')

});

import DiscourseController from 'discourse/controllers/controller';

export default DiscourseController.extend({

  canCreate: function() {
    return Discourse.User.currentProp('admin');
  }.property(),

  actions: {
    create() {
      if (Em.isBlank(this.get('newQueryName'))) {
        return;
      }
      const self = this;
      Discourse.ajax('/explorer', {type: "POST", data: {
        name: this.get('newQueryName')
      }}).then(function(response) {
        self.transitionToRoute("/explorer/" + response.explorer_query.id);
      }).catch(function(xhr) {
        // TODO ERROR HANDLING
        console.error(xhr);
      });
    }
  }

});

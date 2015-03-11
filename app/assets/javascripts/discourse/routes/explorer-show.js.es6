import ShowFooter from "discourse/mixins/show-footer";

export default Discourse.Route.extend(ShowFooter, {

  model: function(params) {
    return Discourse.ExplorerQuery.find(params.id);
  },

  setupController: function(controller, model, transition) {
    this._super(controller, model, transition);
    controller.setProperties({
      editControlsHidden: true,
      dirtyParse: false,
      dirtySave: false,
      queryResult: null
    });
    if (model.get('last_result')) {
      controller.set('queryResult', model.get('last_result'));
      controller.set('showResult', true);
      model.set('last_result', null);
    }
  },

  titleToken: function() {
    return I18n.t('explorer.title');
  }
});

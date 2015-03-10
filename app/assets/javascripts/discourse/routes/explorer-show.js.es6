import ShowFooter from "discourse/mixins/show-footer";

export default Discourse.Route.extend(ShowFooter, {
  queryParams: {
    resultId: {replace: true}
  },

  model: function(params) {
    return Discourse.ExplorerQuery.find(params.id, {resultId: params.resultId});
  },

  setupController: function(controller, model, transition) {
    this._super(controller, model, transition);
    controller.setProperties({
      editControlsHidden: true,
      dirtyParse: false,
      dirtySave: false,
      queryResult: null
    });
  },

  titleToken: function() {
    return I18n.t('explorer.title');
  }
});

import ShowFooter from "discourse/mixins/show-footer";

export default Discourse.Route.extend(ShowFooter, {
  queryParams: {
    resultId: {replace: true}
  },

  model: function(params) {
    return Discourse.ExplorerQuery.find(params.id, {resultId: params.resultId});
  },

  setupController: function(controller, model) {
    controller.setProperties({
      editControlsHidden: true,
      dirtyParse: false,
      dirtySave: false
    });
  },

  titleToken: function() {
    return I18n.t('explorer.title');
  }
});

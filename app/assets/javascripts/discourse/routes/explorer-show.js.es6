import ShowFooter from "discourse/mixins/show-footer";

export default Discourse.Route.extend(ShowFooter, {
  model: function(params) {
    return Discourse.ExplorerQuery.find(params.id);
  },

  titleToken: function() {
    return I18n.t('explorer.title');
  }
});

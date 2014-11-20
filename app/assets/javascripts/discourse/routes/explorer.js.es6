import ShowFooter from "discourse/mixins/show-footer";

export default Discourse.Route.extend(ShowFooter, {
  model: function() {
    return Discourse.ExplorerQuery.findAll();
  },

  titleToken: function() {
    return I18n.t('explorer.title');
  }
});

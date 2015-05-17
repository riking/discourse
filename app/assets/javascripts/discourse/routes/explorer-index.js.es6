import ShowFooter from "discourse/mixins/show-footer";

export default Discourse.Route.extend(ShowFooter, {
  model() {
    return Discourse.ExplorerQuery.findAll();
  },

  titleToken() {
    return I18n.t('explorer.title');
  }
});

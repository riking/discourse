import ShowFooter from "discourse/mixins/show-footer";

export default Discourse.Route.extend(ShowFooter, {
  model: function() {
    if (PreloadStore.get('explorer_index')) {
      return PreloadStore.getAndRemove('explorer_index').then(function(json) {
        return Discourse.Badge.createFromJson(json);
      });
    } else {
      return Discourse.Badge.findAll({onlyListable: true});
    }
  },

  titleToken: function() {
    return I18n.t('explorer.title');
  }
});

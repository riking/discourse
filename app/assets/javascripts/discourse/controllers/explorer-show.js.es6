import DiscourseController from 'discourse/controllers/controller';

export default DiscourseController.extend({
  _init: function() {
    this.setProperties({
      dirtyParse: false,
      dirtySave: false,
      parseGood: false
    });
  }.on('init'),

  query: Em.computed.alias('model'),

  actions: {
    parse() {
      const self = this;
      this.setProperties({
        loading: true,
        hasErrors: false,
        dirtyParse: true
      });

      this.get('model').parse().then(function(res) {
        self.set('loading', false);
        console.log(res);

        if (res.success) {
          self.setProperties({
            dirtyParse: false,
            hasErrors: false,
            parseGood: true
          });
          // TODO

          self.get('query').setParamNames(res.params);

        } else {
          self.setProperties({
            dirtyParse: true,
            hasErrors: true,
            parseGood: false,
            error_message: res.error_message,
            error_loc: res.error_loc
          });
        }

      }).catch(function(xhr) {
        // ERROR HANDLING
        self.set('loading', false);

      });
    }
  },

  markDirty: function() {
    this.set('dirtyParse', true);
    this.set('dirtySave', true);
  }.observes('query.query'),

  error_context: function() {
    const queryText = this.get('query.query');
    const errorLoc = this.get('error_loc');
    let sliceStart = errorLoc - 10, sliceEnd = errorLoc + 10;

    if (sliceStart < 0) sliceStart = 0;
    if (sliceEnd >= queryText.length) sliceEnd = queryText.length;

    let slice = queryText.substring(sliceStart, sliceEnd);

    return "Context: " + Handlebars.Utils.escapeExpression(slice);
  }.property('error_loc', 'hasErrors'),

  // UI disable triggers

  edit_disabled: function() {
    return !this.get('query.can_edit');
  }.property('query.can_edit'),

  parse_disabled: function() {
    return !(this.get('dirtyParse') && this.get('query.can_edit'));
  }.property('query.can_edit', 'dirtyParse'),

  run_disabled: function() {
    return !this.get('query.can_run') || this.get('dirtyParse') || this.get('hasErrors');
  }.property('query.can_run', 'dirtyParse', 'hasErrors'),

  save_disabled: function() {
    if (!this.get('query.can_edit')) return true; // cannot edit -> cannot save
    if (this.get('dirtyParse')) return true; // haven't parsed -> cannot save
    if (!Em.isEmpty(this.get('parseErrors'))) return true; // parse errors -> cannot save
    return false;
  }.property('query.can_edit', 'dirtySave', 'parseErrors')
});

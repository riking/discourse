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
      this.set('loading', true);

      this.get('model').parse().then(function() {
        self.set('dirtyParse', false);
      }).catch(function(xhr) {
        // TODO ERROR HANDLING
      }).finally(function() {
        self.set('loading', false);
      });
    },

    save() {
      const self = this;
      this.set('loading', true);

      this.get('model').save().then(function() {
        self.set('dirtySave', false);
      }).catch(function(xhr) {
        // TODO ERROR HANDLING
      }).finally(function() {
        self.set('loading', false);
      });
    },

    run() {
      const self = this;
      this.set('loadingResult', true);

      this.get('model').run().then(function() {
        self.set('dirtySave', false);
      }).catch(function(xhr) {
        // TODO ERROR HANDLING
      }).finally(function() {
        self.set('loadingResult', false);
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
    if (errorLoc === -1) {
      return "";
    }
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
    return !this.get('query.can_run') || this.get('dirtySave');
  }.property('query.can_run', 'dirtySave'),

  save_disabled: function() {
    if (!this.get('query.can_edit')) return true; // cannot edit -> cannot save
    if (this.get('dirtyParse')) return true; // haven't parsed -> cannot save
    if (this.get('dirtySave')) return false; // haven't saved -> need to save
    return true;
  }.property('query.can_edit', 'dirtySave', 'dirtyParse')
});

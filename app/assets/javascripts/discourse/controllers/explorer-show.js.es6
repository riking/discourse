import DiscourseController from 'discourse/controllers/controller';

export default DiscourseController.extend({
  _init: function() {
    this.set('editControlsHidden', true);
    // Mark query as clean, we just got it from the server
    const self = this;
    Em.run.next(function() {
      self.setProperties({
        dirtyParse: false,
        dirtySave: false
      });
    });
  }.on('init'),

  query: Em.computed.alias('model'),

  actions: {
    showEdit() {
      this.toggleProperty('editControlsHidden');
    },

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

      this.get('model').save().then(function(result) {
        self.set('dirtySave', false);
        //self.get('model').updateFromJson(result);
      }).catch(function(xhr) {
        // TODO ERROR HANDLING
      }).finally(function() {
        self.set('loading', false);
      });
    },

    run() {
      const self = this;
      this.set('loadingResult', true);

      this.get('model').run().then(function(result) {
        console.log(result);
      }).catch(function(xhr) {
        // TODO ERROR HANDLING
      }).finally(function() {
        self.set('loadingResult', false);
      });
    }
  },

  dirty1: function() {
    this.set('dirtyParse', true);
    this.set('dirtySave', true);
  }.observes('query.query'),

  dirty2: function() {
    this.set('dirtySave', true);
  }.observes('query.public_run', 'query.public_view'),

  // UI disable triggers

  any_params: function() {
    return this.get('query.params.length') > 0;
  }.property('query.params.@each'),

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

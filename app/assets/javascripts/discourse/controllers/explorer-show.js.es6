import DiscourseController from 'discourse/controllers/controller';

export default DiscourseController.extend({
  _init: function() {
    this.set('editControlsHidden', !Discourse.User.currentProp('admin'));
    // Mark query as clean, we just got it from the server
    const self = this;
    Em.run.next(function() {
      self.setProperties({
        dirtyParse: false,
        dirtySave: false
      });
    });
  }.on('init'),

  opt_explain: false,
  notransform: false,

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
        console.error(xhr);
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
        console.error(xhr);
      }).finally(function() {
        self.set('loading', false);
      });
    },

    run() {
      const self = this;
      this.set('loadingResult', true);
      this.set('showResult', true);
      self.set('errorResult', false);

      this.get('model').run({explain: this.get('opt_explain')}).then(function(result) {
        if (result.success) {
          console.log(result);
          result.opts = self.getProperties('opt_explain', 'notransform');
          self.set('queryResult', result);
        } else {
          self.set('errorResult', result);
        }

      }).catch(function(xhr) {
        // TODO ERROR HANDLING
        console.error(xhr);
        self.set('loadingResult', false);
        self.set('errorResult', {"class": "NetworkError", message: xhr.status});
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
    if (!this.get('query.can_run')) return true;
    if (this.get('dirtySave')) return true;
    if (!this.get('any_params')) return false;
    return !this.get('query.params').every(function (p) {
      return !Em.isEmpty(p.get('value'));
    });

  }.property('query.can_run', 'dirtySave', 'query.params.@each.value'),

  save_disabled: function() {
    if (!this.get('query.can_edit')) return true; // cannot edit -> cannot save
    if (this.get('dirtyParse')) return true; // haven't parsed -> cannot save
    if (this.get('dirtySave')) return false; // haven't saved -> need to save
    return true;
  }.property('query.can_edit', 'dirtySave', 'dirtyParse')
});

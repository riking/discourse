var ApplicationRoute = Discourse.Route.extend({

  siteTitle: Discourse.computed.setting('title'),

  actions: {
    _collectTitleTokens: function(tokens) {
      tokens.push(this.get('siteTitle'));
      Discourse.set('_docTitle', tokens.join(' - '));
    },

    showTopicEntrance: function(data) {
      this.controllerFor('topic-entrance').send('show', data);
    },

    composePrivateMessage: function(user) {
      var self = this;
      this.transitionTo('userActivity', user).then(function () {
        self.controllerFor('user-activity').send('composePrivateMessage', user);
      });
    },

    error: function(err, transition) {
      if (err.status === 404) {
        // 404
        this.intermediateTransitionTo('unknown');
        return;
      }

      var exceptionController = this.controllerFor('exception'),
          errorString = err.toString(),
          stack = err.stack;

      // If we have a stack call `toString` on it. It gives us a better
      // stack trace since `console.error` uses the stack track of this
      // error callback rather than the original error.
      if (stack) { errorString = stack.toString(); }

      if (err.statusText) { errorString = err.statusText; }

      var c = window.console;
      if (c && c.error) {
        c.error(errorString);
      }
      exceptionController.setProperties({ lastTransition: transition, thrown: err });

      this.intermediateTransitionTo('exception');
    },

    showLogin: function() {
      if (this.site.get("isReadOnly")) {
        bootbox.alert(I18n.t("read_only_mode.login_disabled"));
      } else {
        this.handleShowLogin();
      }
    },

    showCreateAccount: function() {
      if (this.site.get("isReadOnly")) {
        bootbox.alert(I18n.t("read_only_mode.login_disabled"));
      } else {
        this.handleShowCreateAccount();
      }
    },

    showError: function(xhr, desc) {
      Discourse.Route.showModal(this, 'show-error', {xhr: xhr, description: desc || 'generic'});
    },

    autoLogin: function(modal, onFail){
      var methods = Em.get('Discourse.LoginMethod.all');
      if (!Discourse.SiteSettings.enable_local_logins &&
          methods.length === 1) {
            Discourse.Route.showModal(this, modal);
            this.controllerFor('login').send('externalLogin', methods[0]);
      } else {
        onFail();
      }
    },

    showForgotPassword: function() {
      Discourse.Route.showModal(this, 'forgotPassword');
    },

    showNotActivated: function(props) {
      Discourse.Route.showModal(this, 'notActivated');
      this.controllerFor('notActivated').setProperties(props);
    },

    showUploadSelector: function(composerView) {
      Discourse.Route.showModal(this, 'uploadSelector');
      this.controllerFor('upload-selector').setProperties({ composerView: composerView });
    },

    showKeyboardShortcutsHelp: function() {
      Discourse.Route.showModal(this, 'keyboardShortcutsHelp');
    },

    showSearchHelp: function() {
      var self = this;

      // TODO: @EvitTrout how do we get a loading indicator here?
      Discourse.ajax("/static/search_help.html", { dataType: 'html' }).then(function(html){
        Discourse.Route.showModal(self, 'searchHelp', html);
      });

    },


    /**
      Close the current modal, and destroy its state.

      @method closeModal
    **/
    closeModal: function() {
      this.render('hide-modal', {into: 'modal', outlet: 'modalBody'});
    },

    /**
      Hide the modal, but keep it with all its state so that it can be shown again later.
      This is useful if you want to prompt for confirmation. hideModal, ask "Are you sure?",
      user clicks "No", showModal. If user clicks "Yes", be sure to call closeModal.

      @method hideModal
    **/
    hideModal: function() {
      $('#discourse-modal').modal('hide');
    },

    /**
      Show the modal. Useful after calling hideModal.

      @method showModal
    **/
    showModal: function() {
      $('#discourse-modal').modal('show');
    },

    editCategory: function(category) {
      var self = this;

      Discourse.Category.reloadById(category.get('id')).then(function (c) {
        self.site.updateCategory(c);
        Discourse.Route.showModal(self, 'editCategory', c);
        self.controllerFor('editCategory').set('selectedTab', 'general');
      });
    },

    /**
      Deletes a user and all posts and topics created by that user.

      @method deleteSpammer
    **/
    deleteSpammer: function (user) {
      this.send('closeModal');
      user.deleteAsSpammer(function() { window.location.reload(); });
    },

    checkEmail: function (user) {
      user.checkEmail();
    }
  },

  activate: function() {
    this._super();
    Em.run.next(function() {
      // Support for callbacks once the application has activated
      ApplicationRoute.trigger('activate');
    });
  },

  handleShowLogin: function() {
    var self = this;

    if(Discourse.SiteSettings.enable_sso) {
      var returnPath = encodeURIComponent(window.location.pathname);
      window.location = Discourse.getURL('/session/sso?return_path=' + returnPath);
    } else {
      this.send('autoLogin', 'login', function(){
        Discourse.Route.showModal(self, 'login');
        self.controllerFor('login').resetForm();
      });
    }
  },

  handleShowCreateAccount: function() {
    var self = this;

    self.send('autoLogin', 'createAccount', function(){
      Discourse.Route.showModal(self, 'createAccount');
    });
  }
});

RSVP.EventTarget.mixin(ApplicationRoute);
export default ApplicationRoute;

//  Subscribe to "logout" change events via the Message Bus
export default {
  name: "logout",
  after: "message-bus",

  initialize: function (container) {
    const messageBus = container.lookup('message-bus:main');
    const appRoute = container.lookup('route:application');
    const sendAction = appRoute.send.bind(appRoute);

    if (!messageBus) { return; }
    const callback = () => sendAction('logout', true);

    messageBus.subscribe("/logout", () => {
      bootbox.dialog(I18n.t("logout"), {label: I18n.t("refresh"), callback}, {onEscape: callback, backdrop: 'static'});
      setTimeout(() => {
        bootbox.hideAll();
        callback();
      }, 5000 + 5000 * Math.random());
    });
  }
};

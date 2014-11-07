export default {
    name: "site-settings",
    after: "message-bus",

    initialize: function (container) {
        var settings = container.lookup("site-settings:main")

        if (!Discourse.MessageBus) { return; }

        Discourse.MessageBus.subscribe("/client_site_settings", function (change) {
            settings.set(change.name, change.value);
        });
    }
};

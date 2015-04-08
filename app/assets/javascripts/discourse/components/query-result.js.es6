var ColumnHandlers = [];
var AssistedHandlers = {};
const Escape = Handlebars.Utils.escapeExpression;

import avatarTemplate from 'discourse/lib/avatar-template';
import { categoryLinkHTML } from 'discourse/helpers/category-link';

var defaultFallback = function(buffer, content, defaultRender) { defaultRender(buffer, content); };

function isoYMD(date) {
  return date.getUTCFullYear() + "-" + date.getUTCMonth() + "-" + date.getUTCDate();
}

const QueryResultComponent = Ember.Component.extend({
  layoutName: 'explorer-query-result',

  rows: Em.computed.alias('content.rows'),
  columns: Em.computed.alias('content.columns'),
  params: Em.computed.alias('content.params'),
  explainText: Em.computed.alias('content.explain'),
  meta: Em.computed.alias('content.meta'),

  hasExplain: Em.computed.notEmpty('content.explain'),
  noParams: Em.computed.empty('params'),
  colCount: function() {
    return this.get('content.columns').length;
  }.property('content.columns.length'),

  downloadName: function() {
    return this.get('meta.name') + "@" + window.location.host + "-" + isoYMD(new Date()) + ".json";
  }.property(),

  parameterAry: function() {
    let arr = [];
    const params = this.get('params');
    for (var key in params) {
      if (params.hasOwnProperty(key)) {
        arr.push({key: key, value: params[key]});
      }
    }
    return arr;
  }.property('params.@each'),

  columnHandlers: function() {
    const self = this;
    if (self.get('opts.notransform')) {
      return this.get('columns').map(function(colName) {
        return {
          name: colName,
          displayName: colName,
          render: defaultFallback
        };
      });
    }
    return this.get('columns').map(function(colName) {
      let handler = defaultFallback;

      if (/\$/.test(colName)) {
        var match = /(\w+)\$(\w*)/.exec(colName);
        if (match[1] && self.get('content.relations')[match[1]] && AssistedHandlers[match[1]]) {
          return {
            name: colName,
            displayName: match[2] || match[1],
            render: AssistedHandlers[match[1]]
          };
        } else if (match[1] == '') {
          // Return as "$column" for no special handling
          return {
            name: colName,
            displayName: match[2] || match[1],
            render: defaultFallback
          }
        }
      } else {
        ColumnHandlers.forEach(function(handlerInfo) {
          if (handlerInfo.regex.test(colName)) {
            handler = handlerInfo.render;
          }
        });
      }

      return {
        name: colName,
        displayName: colName,
        render: handler
      };
    });
  }.property('columns.@each'),

  _clickDownloadButton: function() {
    const self = this;
    const $button = this.$().find("#result-download");
    // .once not .on
    $button.one('mouseover', function(e) {
      const a = e.target;
      let resultString = "data:text/plain;base64,";
      var jsonString = JSON.stringify(self.get('content'));
      resultString += btoa(jsonString);

      a.href = resultString;
    });
  }.on('didInsertElement'),

  parent: function() { return this; }.property()

});

/**
 * ColumnHandler callback arguments:
 *  buffer: rendering buffer
 *  content: content of the query result cell
 *  defaultRender: call this wth (buffer, content) to fall back
 *  extra: the entire response
 */

ColumnHandlers.push({ regex: /user_id/, render: function(buffer, content, defaultRender) {
  if (!/^\d+$/.test(content)) {
    return defaultRender(buffer, content);
  }
  buffer.push("<a href='/users/by-id/");
  buffer.push(content);
  buffer.push("'>User #");
  buffer.push(content);
  buffer.push("</a>");
}});
ColumnHandlers.push({ regex: /post_id/, render: function(buffer, content, defaultRender) {
  if (!/^\d+$/.test(content)) {
    return defaultRender(buffer, content);
  }
  buffer.push("<a href='/p/");
  buffer.push(content);
  buffer.push("'>Post #");
  buffer.push(content);
  buffer.push("</a>");
}});
ColumnHandlers.push({ regex: /badge_id/, render: function(buffer, content, defaultRender) {
  if (!/^\d+$/.test(content)) {
    return defaultRender(buffer, content);
  }
  buffer.push("<a href='/badges/");
  buffer.push(content);
  buffer.push("/-'>Badge #");
  buffer.push(content);
  buffer.push("</a>");
}});
ColumnHandlers.push({ regex: /topic_id/, render: function(buffer, content, defaultRender) {
  if (!/^\d+$/.test(content)) {
    return defaultRender(buffer, content);
  }
  buffer.push("<a href='/t/");
  buffer.push(content);
  buffer.push("/from-link'>Topic #");
  buffer.push(content);
  buffer.push("</a>");
}});

AssistedHandlers['reltime'] = function(buffer, content, defaultRender) {
  const parsedDate = new Date(content);
  if (!parsedDate.getTime()) {
    return defaultRender(buffer, content);
  }

  buffer.push(Discourse.Formatter.relativeAge(parsedDate, {format: 'medium'}));
};

AssistedHandlers['category'] = function(buffer, content, defaultRender) {
  const contentId = parseInt(content, 10);
  if (isNaN(contentId)) {
    return defaultRender(buffer, content);
  }
  const category = Discourse.Category.findById(contentId);
  if (!category) {
    return defaultRender(buffer, content);
  }

  const opts = {
    link: true,
    allowUncategorized: true
  };
  buffer.push(categoryLinkHTML(category, opts));
};

/**
 * Helper to wrap the handler in a function that fetches the object out of the response.
 *
 * @param name the part of the column name before the $
 * @param callback Function(buffer, object [, defaultRender])
 */
function registerRelationAssistedHandler(name, callback) {
  AssistedHandlers[name] = function(buffer, content, defaultRender, response) {
    const contentId = parseInt(content, 10);
    if (isNaN(contentId)) {
      return defaultRender(buffer, content);
    }
    const relationObject = response.relations[name].find(function(relObj) {
      return relObj.id === contentId;
    });
    if (!relationObject) {
      Em.Logger.warn("Couldn't find " + name + " with id " + contentId + " in query response");
      return defaultRender(buffer, content);
    }

    callback(buffer, relationObject, defaultRender);
  }
}

registerRelationAssistedHandler('user', function(buffer, obj) {
  buffer.push("<a href='/users/");
  buffer.push(obj.username);
  buffer.push("'>");
  buffer.push(Discourse.Utilities.avatarImg({
    size: "small",
    avatarTemplate: avatarTemplate(obj.username, obj.uploaded_avatar_id)
  }));
  buffer.push(" ");
  buffer.push(obj.username);
  buffer.push("</a>");
});

registerRelationAssistedHandler('badge', function(buffer, obj) {
  // TODO It would be nice to be able to invoke the {{user-badge}} helper from here.
  // Looks like that would need a ContainerView

  /*
   <span id="ember2197" class="ember-view">
   <a id="ember2201" class="ember-view" href="/badges/9/autobiographer">
   <span id="ember2221" class="ember-view user-badge badge-type-bronze" data-badge-name="Autobiographer" title="Filled user profile information">
   <i class="fa fa-certificate"></i>
   Autobiographer
   </span></a></span>
   */

  if (true) {
    buffer.push('<span><a href="/badges/');
    buffer.push(obj.id + '/' + Escape(obj.name));
    buffer.push('"><span data-badge-name="');
    buffer.push(Escape(obj.name));
    buffer.push('" class="user-badge badge-type-');
    buffer.push(Escape(obj.badge_type.toLowerCase()));
    buffer.push('" title="');
    buffer.push(Escape(obj.description));
    buffer.push('">');
    // icon-or-image
    if (obj.icon.indexOf('fa-') === 0) {
      buffer.push(" <i class='fa " + obj.icon + "'></i> ");
    } else {
      buffer.push(" <img src='" + obj.icon + "'> ");
    }
    buffer.push(Escape(obj.name));
    buffer.push("</span></a></span>");
  }
});

registerRelationAssistedHandler('post', function(buffer, obj) {
  /*
   <aside class="quote" data-post="35" data-topic="117">
   <div class="title" style="cursor: pointer;">
   <div class="quote-controls">
   <i class="fa fa-chevron-down" title="expand/collapse"></i>
   <a href="/t/usability-on-the-cheap-and-easy/117/35" title="go to the quoted post" class="back"></a>
   </div>
   <img width="20" height="20" src="/user_avatar/localhost/riking/40/75.png" class="avatar">riking:</div>
   <blockquote>$EXCERPT</blockquote>
   </aside>
   */
  buffer.push("<aside class='quote' data-post='" + obj.post_number + "' data-topic='" + obj.topic_id + "'>");
  buffer.push('<div class="title" style="cursor: pointer;">' +
              '<div class="quote-controls">' +
              '<i class="fa" title="expand/collapse"></i>');
  buffer.push('<a href="');
  buffer.push("/t/" + obj.slug + "/" + obj.topic_id + "/" + obj.post_number);
  buffer.push('" title="go to the post" class="quote-other-topic"></a>');
  buffer.push('</div>');
  buffer.push(Discourse.Utilities.avatarImg({
    size: "small",
    avatarTemplate: avatarTemplate(obj.username, obj.uploaded_avatar_id)
  }));
  buffer.push(obj.username + ":");
  buffer.push('</div>' +
              '<blockquote>');
  buffer.push(obj.excerpt);
  buffer.push('</blockquote></aside>');
});

export default QueryResultComponent;

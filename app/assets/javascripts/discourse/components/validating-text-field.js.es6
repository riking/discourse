import TextField from 'discourse/components/text-field';

/**
 * A TextField that validates its contents when the value is changed.
 */
export default TextField.extend({
  classNameBindings: ['valid:valid:invalid', 'extraClass'],

  valid: function() {
    const object = this.get('validationObject');
    return object[this.get("checkMethod")].call(object, this.get('value'))
  }.property('value')
});

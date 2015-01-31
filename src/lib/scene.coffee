Backbone = require('backbone')
_        = require('underscore')

class Scene extends Backbone.View
  render: ->
    @$el.append @elem

  # Method which simply prevents events from bubbling
  preventDefault: (e) ->
    e.preventDefault()

  # Remove event handlers and hide this view's elem
  hide: (duration = 500, callback) ->
    @undelegateEvents()

    @elem.addClass 'out'

    _.delay =>
      @elem.removeClass 'in'
      @elem.removeClass 'out'

      if typeof callback == "function" then callback()
    , duration
      
  # Re-delegate event handlers and show the view's elem
  show: (duration = 500, callback) ->
    @delegateEvents()

    @elem.addClass 'in'

    if typeof callback == "function"
      _.delay callback, duration

module.exports = Scene

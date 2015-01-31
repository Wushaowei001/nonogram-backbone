$         = require('../vendor/zepto')
_         = require('underscore')
ENV       = require('../lib/env')
Scene     = require('../lib/scene')
DialogBox = require('../lib/dialog-box')
template  = require('../templates/difficulty-select')

class DifficultySelectScene extends Scene
  events: ->
    if ENV.mobile
      'touchend .back': 'back'
      'touchend .select': 'select'
    else
      'click .back': 'back'
      'click .select': 'select'

  initialize: ->
    @elem = $(template())
    @render()

  # Difficulty choice
  select: (e) ->
    e.preventDefault()
    button = $(e.target)
    button = button.parents('.button') unless button.data('difficulty')

    # Prevent multiple clicks
    @undelegateEvents()

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'levelSelect', { difficulty: button.data('difficulty') }

  # Go back to title
  back: (e) ->
    e.preventDefault()

    # Prevent multiple clicks
    @undelegateEvents()

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'title'

  # Re-delegate event handlers and show the view's elem
  show: (duration = 500, callback) ->
    @trigger 'music:play', 'bgm-tutorial'

    # Call "super"
    super duration, callback

module.exports = DifficultySelectScene

$ = require('jquery')
_ = require('underscore')
Scene = require('../classes/scene')
ENV = require('../utilities/env')
template = require('../templates/difficulty-select')
DialogBox = require('../classes/dialog-box')

class DifficultySelectScene extends Scene
  events: ->
    if ENV.mobile
      events =
        'touchend .back': 'back' 
        'touchend .easy': 'select'
        'touchend .medium': 'select'
        'touchend .hard': 'select'
        'touchend .random': 'select'
    else
      events =
        'click .back': 'back'
        'click .easy': 'select'
        'click .medium': 'select'
        'click .hard': 'select'
        'click .random': 'select'

  initialize: ->
    @elem = $(template())
    
    # Hide IAP by default
    # $('.restore', @elem).hide()

    @render()

  # Difficulty choice
  select: (e) ->
    e.preventDefault()
    button = $(e.target)

    # Prevent multiple clicks
    @undelegateEvents()

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'level', { difficulty: button.data 'difficulty' }

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
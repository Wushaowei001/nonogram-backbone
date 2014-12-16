$ = require('../vendor/zepto')
Scene = require('../classes/scene')
ENV = require('../utilities/env')
template = require('../templates/title.html')

class TitleScene extends Scene
  events: ->
    if ENV.mobile
      events =
        'touchend .start': 'start' 
        'touchend .tutorial': 'tutorial' 
        'touchend .about': 'about'
    else
      events =
        'click .start': 'start' 
        'click .tutorial': 'tutorial' 
        'click .about': 'about'

  initialize: ->
    @elem = $(template())
    @render()

  start: (e) ->
    e.preventDefault()
    @undelegateEvents()
    
    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'difficulty'

  tutorial: (e) ->
    e.preventDefault()
    @undelegateEvents()

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'game', { difficulty: 'easy', level: 0, tutorial: true }

  about: (e) ->
    e.preventDefault()
    @undelegateEvents()

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'about'

  show: (duration = 500, callback) ->
    super duration, callback

    @trigger 'music:play', 'bgm-one'
  
module.exports = TitleScene

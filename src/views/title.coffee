# define [
# 'jquery'
# 'backbone'
# 'cs!utilities/env'
# 'cs!classes/scene'
# 'text!templates/title.html'
# ], ($, Backbone, env, Scene, template) ->

$ = require('jquery')
Scene = require('../classes/scene')
ENV = require('../utilities/env')
template = require('../templates/title.html')

class TitleScene extends Scene
  events: ->
    # Determine whether touchscreen or desktop
    if ENV.mobile
      events =
        'touchstart .start': 'start' 
        'touchstart .tutorial': 'tutorial' 
        'touchstart .about': 'about'
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

    # Play some music
    # track = if Math.random() < 0.5 then 'one' else 'two'
    @trigger 'music:play', 'bgm-one'
  
module.exports = TitleScene
$         = require('../vendor/zepto')
_         = require('underscore')
ENV       = require('../lib/env')
Scene     = require('../lib/scene')
DialogBox = require('../lib/dialog-box')
template  = require('../templates/about')

class AboutScene extends Scene
  events: ->
    if ENV.mobile
      'touchend .back': 'back' 
      'touchend .reset': 'reset'
      'touchend .sfx': 'toggleSfx'
      'touchend .music': 'toggleMusic'
      'touchend .feedback': 'feedback'
    else
      'click .back': 'back'
      'click .reset': 'reset'
      'click .sfx': 'toggleSfx'
      'click .music': 'toggleMusic'
      'click .feedback': 'feedback'

  initialize: ->
    @elem = $(template())
    @render()

    # Update the text on these toggle buttons
    if localStorage.getBoolean('playMusic')
      @$('.button.music span', @elem).html 'Music ON'
    else
      @$('.button.music span', @elem).html 'Music OFF'
    
    if localStorage.getBoolean('playSfx')
      @$('.button.sfx span', @elem).html 'Sound ON'
    else
      @$('.button.sfx span', @elem).html 'Sound OFF'

  back: (e) ->
    e.preventDefault()

    # Prevent multiple clicks
    @undelegateEvents()
    
    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'title'

  # Toggle the preference to play SFX
  toggleSfx: (e) ->
    e.preventDefault()

    @trigger 'sfx:play', 'button'

    preference = localStorage.getBoolean('playSfx')
    preference = !preference
    localStorage.setItem('playSfx', preference)

    if preference
      @$('.button.sfx span', @elem).html 'Sound ON'
    else
      @$('.button.sfx span', @elem).html 'Sound OFF'

  # Toggle the preference to play music
  toggleMusic: (e) ->
    e.preventDefault()

    @trigger 'sfx:play', 'button'

    preference = localStorage.getBoolean('playMusic')
    preference = !preference
    localStorage.setItem('playMusic', preference)

    if preference
      @$('.button.music span', @elem).html 'Music ON'
      @trigger 'music:play', 'bgm-one'
    else
      @$('.button.music span', @elem).html 'Music OFF'
      @trigger 'music:stop'

  feedback: (e) ->
    e.preventDefault()
    # window.location.href = "mailto:info@ganbarugames.com"
    window.open "http://ganbarugames.com", "feedback"

  reset: (e) ->
    e.preventDefault()
    @trigger 'sfx:play', 'button'
    
    new DialogBox
      el: @elem
      parent: @
      title: 'Erase saved data?'
      buttons: [
        { 
          text: 'Yes'
          callback: => 
            stats = 
              beginner: {}
              easy: {}
              medium: {}
              hard: {}
              random: {}

            complete =
              beginner: 0 
              easy: 0
              medium: 0
              hard: 0
              random: 0

            lastViewedLevel = 
              beginner: 0
              easy: 0
              medium: 0
              hard: 0
              random: 0

            localStorage.setObject 'stats', stats
            localStorage.setObject 'complete', complete
            localStorage.setObject 'lastViewedLevel', lastViewedLevel
        },
        {
          text: 'No'
        }
      ]

module.exports = AboutScene

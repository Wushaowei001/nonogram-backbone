###
AboutScene
- Shows credits and lets user reset data
###
# define [
#   'jquery'
#   'underscore'
#   'backbone'
#   'cs!utilities/env'
#   'cs!classes/scene'
#   'cs!classes/dialog-box'
#   'text!templates/about.html'
# ], ($, _, Backbone, env, Scene, DialogBox, template) ->

$ = require('jquery')
_ = require('underscore')
Scene = require('../classes/scene')
ENV = require('../utilities/env')
template = require('../templates/about')
DialogBox = require('../classes/dialog-box')

class AboutScene extends Scene
  events: ->
    # Determine whether touchscreen or desktop
    if ENV.mobile
      events =
        'touchstart .back': 'back' 
        'touchstart .reset': 'reset'
        'touchstart .sfx': 'toggleSfx'
        'touchstart .music': 'toggleMusic'
        'touchstart .feedback': 'feedback'
    else
      events =
        'click .back': 'back'
        'click .reset': 'reset'
        'click .sfx': 'toggleSfx'
        'click .music': 'toggleMusic'
        'click .feedback': 'feedback'

  initialize: ->
    @elem = $(template())
    @render()

    # Update the text on these toggle buttons
    if localStorage.getItem('playMusic') == "true"
      @$('.button.music span', @elem).html 'Music ON'
    else
      @$('.button.music span', @elem).html 'Music OFF'
    
    if localStorage.getItem('playSfx') == "true"
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

    preference = localStorage.getItem('playSfx') == "true"  # This casts the string that is stored in localStorage into a boolean
    preference = !preference
    localStorage.setItem 'playSfx', preference

    if preference == true
      @$('.button.sfx span', @elem).html 'Sound ON'
    else
      @$('.button.sfx span', @elem).html 'Sound OFF'

  # Toggle the preference to play music
  toggleMusic: (e) ->
    e.preventDefault()

    @trigger 'sfx:play', 'button'

    preference = localStorage.getItem('playMusic') == "true"  # This casts the string that is stored in localStorage into a boolean
    preference = !preference
    localStorage.setItem 'playMusic', preference

    if preference == true
      @$('.button.music span', @elem).html 'Music ON'
      @trigger 'music:play', 'one'
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
      title: 'Erase saved data?'
      buttons: [
        { 
          text: 'Yes'
          callback: => 
            stats = 
              easy: {}
              medium: {}
              hard: {}
              random: {}

            complete = 
              easy: 0
              medium: 0
              hard: 0
              random: 0

            lastViewedLevel = 
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
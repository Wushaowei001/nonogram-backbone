$ = require('../vendor/zepto')
_ = require('underscore')
Scene = require('../classes/scene')
ENV = require('../utilities/env')
template = require('../templates/level-select')
levels = require('../data/levels')

class LevelSelectScene extends Scene
  events: ->
    if ENV.mobile
      events =
        'touchend .back': 'back' 
        'touchend .previous': 'previous'
        'touchend .next': 'next'
        'touchend .play': 'play'
    else
      events =
        'click .back': 'back' 
        'click .previous': 'previous'
        'click .next': 'next'
        'click .play': 'play'

  current: 0
  difficulty: 'easy'
  stats: {}

  initialize: ->
    @elem = $(template())
    @render()

  previous: (e) ->
    e.preventDefault()

    if @current > 0
      @current--

      # Handle dimming prev/next buttons
      if @current == 0 then @$('.previous').addClass 'disabled'
      if @current == levels[@difficulty].length - 2 then @$('.next').removeClass 'disabled'

      @trigger 'sfx:play', 'button'

      @showPreview levels[@difficulty][@current]

  next: (e) ->
    e.preventDefault()

    if @current < levels[@difficulty].length - 1
      @current++

      # Handle dimming prev/next buttons
      if @current == levels[@difficulty].length - 1 then @$('.next').addClass 'disabled'
      if @current == 1 then @$('.previous').removeClass 'disabled'

      @trigger 'sfx:play', 'button'

      @showPreview levels[@difficulty][@current]

  play: (e) ->
    e.preventDefault()
    
    # Prevent multiple clicks
    @undelegateEvents()

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'game', { difficulty: @difficulty, level: @current }


  back: (e) ->
    e.preventDefault()

    # Prevent multiple clicks
    @undelegateEvents()
    
    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'difficulty'

  # Parse through a level object and display on a table
  showPreview: (level) ->
    pad = (number, length) ->
      string = String(number)
      string = '0' + string while string.length < length
      return string

    if @stats[@current]?.time     
      minutes = pad Math.floor(@stats[@current].time / 60), 2
      seconds = pad @stats[@current].time % 60, 2
      time = "#{minutes}:#{seconds}"
    else
      time = '--:--'

    attempts = if @stats[@current]?.attempts then @stats[@current].attempts else "0"
    
    @$('.attempts').html "Attempts: #{attempts}"
    @$('.best-time').html "Best Time: #{time}"

    # If level is completed, show preview, title, etc.
    if time != '--:--'
      @$('.level-number').html "#{@difficulty.charAt(0).toUpperCase() + @difficulty.slice(1)} ##{@current + 1}: #{level.title}"

      # Show a preview of the completed level
      # This will show the previously completed random puzzle
      if level.clues.length > 0
        @$('.preview .complete').show()
        @$('.preview .incomplete').hide()

        # Clear out previous preview
        @$('.preview .complete div').removeClass('filled')

        for clue, index in level.clues
          if clue is 1
            @$('.preview .complete div').eq(index).addClass('filled')

    else
      @$('.level-number').html "#{@difficulty.charAt(0).toUpperCase() + @difficulty.slice(1)} ##{@current + 1}: ????"
      @$('.preview .complete').hide()
      @$('.preview .incomplete').show()

    # Animate into place
    # preview = @$('.preview')

    # preview.css
    #   'left': -@elem.width()

    # preview.animate
    #   'left': 0
    # , 500, 'cubic-bezier(0.5, -0.5, 0.5, 1.5)'


  resize: (width, height, orientation) ->
    preview = @$('.preview')

    # TODO: Is it possible to get rid of this hardcoded nonsense? I don't think so
    if orientation is 'landscape'
      width = width * 0.4
      preview.width(Math.round(width / 10) * 10)
      preview.height(preview.width())
    else
      width = width * 0.6
      preview.width(Math.round(width / 10) * 10)
      preview.height(preview.width())

  hide: (duration = 500, callback) ->
    super duration, callback

    # Store the last viewed level for this difficulty
    lastViewedLevel = localStorage.getObject('lastViewedLevel')
    lastViewedLevel[@difficulty] = @current
    localStorage.setObject 'lastViewedLevel', lastViewedLevel

    # Hide the level preview after transition is complete
    _.delay =>
      @$('.preview .complete').hide()
      @$('.preview .incomplete').show()
    , duration

  # Re-delegate event handlers and show the view's elem
  show: (duration = 500, callback) ->
    super duration, callback
    
    # Re-enable buttons
    @$('.previous').addClass 'disabled'
    if @current > 0 then @$('.previous').removeClass 'disabled'
    if @current < levels[@difficulty].length - 1 then @$('.next').removeClass 'disabled'

    # Handle bizarre condition where this property isn't being set
    if !@difficulty then @difficulty = "easy"
    
    # Update level stats based on localStorage
    @stats = localStorage.getObject('stats')[@difficulty]

    # Determine the last viewed level for this difficulty
    @current = localStorage.getObject('lastViewedLevel')[@difficulty]

    # Re-populate the preview window
    @showPreview levels[@difficulty][@current]

    @trigger 'music:play', 'bgm-tutorial'

module.exports = LevelSelectScene
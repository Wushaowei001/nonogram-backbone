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
        'touchend canvas': 'select'
    else
      events =
        'click .back': 'back' 
        'click .previous': 'previous'
        'click .next': 'next'
        'click .play': 'play'
        'click canvas': 'select'

  current: 0
  page: 0
  perPage: 9
  difficulty: 'easy'
  stats: {}

  initialize: ->
    @elem = $(template())
    @render()

    @totalPages = Math.ceil(levels[@difficulty].length / @perPage)

  previous: (e) ->
    e.preventDefault()

    if @page > 0
      @page -= 1

      # Handle dimming prev/next buttons
      @$('.previous').addClass 'disabled' if @page is 0
      @$('.next').removeClass 'disabled' if @page is @totalPages - 2

      @trigger 'sfx:play', 'button'

      @drawPreviews()
      @current = @page * @perPage
      @highlightPreview()

  next: (e) ->
    e.preventDefault()

    if @page < @totalPages - 1
      @page += 1

      # Handle dimming prev/next buttons
      @$('.next').addClass 'disabled' if @page is @totalPages - 1
      @$('.previous').removeClass 'disabled' if @page is 1

      @trigger 'sfx:play', 'button'

      @drawPreviews()
      @current = @page * @perPage
      @highlightPreview()

  play: (e) ->
    e.preventDefault()
    
    @undelegateEvents() # Prevent multiple clicks

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'game', { difficulty: @difficulty, level: @current }


  back: (e) ->
    e.preventDefault()

    @undelegateEvents() # Prevent multiple clicks
    
    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'difficulty'

  showLevelInfo: ->
    # TODO move this elsewhere
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

    levelData = levels[@difficulty][@current]

    # If level is completed, show preview, title, etc.
    if time != '--:--'
      @$('.level-number').html "#{@difficulty.charAt(0).toUpperCase() + @difficulty.slice(1)} ##{@current + 1}: #{levelData.title}"
    else
      @$('.level-number').html "#{@difficulty.charAt(0).toUpperCase() + @difficulty.slice(1)} ##{@current + 1}: ????"
      @$('.preview .complete').hide()
      @$('.preview .incomplete').show()

  drawPreviews: ->
    i = 0
    while (i < @perPage)
      canvas = @$('.preview canvas').eq(i)
      pixelSize = Math.floor(canvas.width() / 10)
      context = canvas[0].getContext('2d')
      context.clearRect(0, 0, canvas.width(), canvas.height())

      levelData = levels[@difficulty][@page * @perPage + i]

      if levelData is undefined
        canvas.hide()
      else
        canvas.show()
        for clue, index in levelData.clues
            if clue is 1
              x = index % 10
              y = Math.floor(index / 10)
              context.fillRect(x * pixelSize, y * pixelSize, pixelSize, pixelSize)
      i += 1

  select: (event) ->
    @current = @page * @perPage + $(event.target).index()
    @highlightPreview()

  highlightPreview: ->
    index = @current - @page * @perPage
    preview = @$('canvas').eq(index)
    preview.siblings().removeClass 'selected'
    preview.addClass 'selected'
    @showLevelInfo()

  resize: (width, height, orientation) ->
    preview = @$('.preview')

    # TODO: Get rid of this hardcoded nonsense
    if orientation is 'landscape'
      width = width * 0.4
      preview.width(Math.round(width / 10) * 10)
      preview.height(preview.width())
    else
      width = width * 0.6
      preview.width(Math.round(width / 10) * 10)
      preview.height(preview.width())

    # Make each canvas a multiple of 10, so 10x10 grids can
    # be drawn without artifacts caused by antialiasing
    @$('canvas').each (index, object) ->
      canvas = $(object)
      canvas.attr('width', Math.floor(canvas.width() / 10) * 10)
      canvas.attr('height', Math.floor(canvas.height() / 10) * 10)

    @drawPreviews()

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
    @drawPreviews()
    @highlightPreview()

    @trigger 'music:play', 'bgm-tutorial'

module.exports = LevelSelectScene

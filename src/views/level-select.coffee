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

  selectedLevel: 0
  page: 0
  perPage: 9
  difficulty: 'easy'
  stats: {}

  initialize: ->
    @elem = $(template())
    @render()

    @totalPages = Math.ceil(levels[@difficulty].length / @perPage) - 1 # 0-based index
    @onscreen = @$('.preview .onscreen canvas')
    @offscreen = @$('.preview .offscreen canvas')

  previous: (e) ->
    e.preventDefault()

    if @page > 0
      @page -= 1

      # Handle dimming prev/next buttons
      @$('.previous').addClass 'disabled' if @page is 0
      @$('.next').removeClass 'disabled' if @page is @totalPages - 1

      @trigger 'sfx:play', 'button'

      @drawPreviews()
      @selectedLevel = @page * @perPage
      @highlightPreview()

  next: (e) ->
    e.preventDefault()

    if @page < @totalPages
      @page += 1

      # Handle dimming prev/next buttons
      @$('.next').addClass 'disabled' if @page is @totalPages
      @$('.previous').removeClass 'disabled' if @page is 1

      @trigger 'sfx:play', 'button'

      @drawPreviews()
      @selectedLevel = @page * @perPage
      @highlightPreview()

  play: (e) ->
    e.preventDefault()
    
    @undelegateEvents() # Prevent multiple clicks

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'game', { difficulty: @difficulty, level: @selectedLevel }


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

    if @stats[@selectedLevel]?.time     
      minutes = pad Math.floor(@stats[@selectedLevel].time / 60), 2
      seconds = pad @stats[@selectedLevel].time % 60, 2
      time = "#{minutes}:#{seconds}"
    else
      time = '--:--'

    attempts = @stats[@selectedLevel]?.attempts || "0"
    
    @$('.attempts').html "Attempts: #{attempts}"
    @$('.best-time').html "Best Time: #{time}"

    levelData = levels[@difficulty][@selectedLevel]

    # If level is completed, show preview, title, etc.
    if time != '--:--'
      @$('.level-number').html "#{@difficulty.charAt(0).toUpperCase() + @difficulty.slice(1)} ##{@selectedLevel + 1}: #{levelData.title}"
    else
      @$('.level-number').html "#{@difficulty.charAt(0).toUpperCase() + @difficulty.slice(1)} ##{@selectedLevel + 1}: ????"

  drawPreviews: ->
    # Move existing previews off
    @onscreen.each (i, element) =>
      canvas = $(element)

      _.delay ->
        # Turn transitions back on for smooth animation
        canvas.css('transition', 'transform 0.75s cubic-bezier(.5,-0.5,.5,1.5)')

        # Move offscreen
        canvas.css('transform', "translateX(-#{@width}px)")
      , i * 100

    # Move new previews on
    @offscreen.each (i, element) =>
      canvas = $(element)
      context = canvas[0].getContext('2d')
      context.clearRect(0, 0, canvas.width(), canvas.height())

      index = @page * @perPage + i
      levelData = levels[@difficulty][index]

      if levelData is undefined
        canvas.hide()
      else
        gridSize = Math.sqrt(levelData.clues.length)
        pixelSize = Math.floor(canvas.width() / gridSize)

        canvas.show()

        # Turn off transitions so canvas moves instantly
        canvas.css('transition', 'transform 0s linear')

        # Move offscreen
        canvas.css('transform', "translateX(#{@width}px)")

        _.delay ->
          # Turn transitions back on for smooth animation
          canvas.css('transition', 'transform 0.75s cubic-bezier(.5,-0.5,.5,1.5)')

          # Move onscreen
          canvas.css('transform', 'translateX(0)')
        , i * 100

        clues = if @stats[index]?.time 
                  levelData.clues
                else
                  levels.incomplete.clues

        for clue, index in clues
            if clue is 1
              x = index % gridSize
              y = Math.floor(index / gridSize)
              context.fillRect(x * pixelSize, y * pixelSize, pixelSize, pixelSize)
      i += 1

    # Swap groups
    tmp = @onscreen
    @onscreen = @offscreen
    @offscreen = tmp

  select: (event) ->
    @selectedLevel = @page * @perPage + $(event.target).index()
    @highlightPreview()

  highlightPreview: ->
    canvases = @$('.preview canvas')
    index = @selectedLevel - @page * @perPage
    selected = canvases.eq(index)
    canvases.removeClass 'selected'
    selected.addClass 'selected'
    @showLevelInfo()

  resize: (width, height, orientation) ->
    # Make each canvas a multiple of 10, so 10x10 grids can
    # be drawn without artifacts caused by antialiasing
    @$('.preview canvas').each (index, object) ->
      canvas = $(object)
      canvas.attr('width', Math.floor(canvas.width() / 10) * 10)
      canvas.attr('height', Math.floor(canvas.height() / 10) * 10)

    # Re-draw previews, since resetting width/height on a canvas erases it
    @drawPreviews()

    @width = width
    @height = height

  hide: (duration = 500, callback) ->
    super duration, callback

    # Store the last viewed level for this difficulty
    lastViewedLevel = localStorage.getObject('lastViewedLevel')
    lastViewedLevel[@difficulty] = @selectedLevel
    localStorage.setObject 'lastViewedLevel', lastViewedLevel

  # Re-delegate event handlers and show the view's elem
  show: (duration = 500, callback) ->
    super duration, callback
    
    # Re-enable buttons
    @$('.previous').addClass 'disabled'
    if @selectedLevel > 0 then @$('.previous').removeClass 'disabled'
    if @selectedLevel < levels[@difficulty].length - 1 then @$('.next').removeClass 'disabled'

    # Handle bizarre condition where this property isn't being set
    if !@difficulty then @difficulty = "easy"
    
    # Update level stats based on localStorage
    @stats = localStorage.getObject('stats')[@difficulty]

    # Determine the last viewed level for this difficulty
    @selectedLevel = localStorage.getObject('lastViewedLevel')[@difficulty]

    @offscreen.css
      transition: 'transform 0s linear',
      transform: "translateX(-#{@width}px)"

    # Re-populate the preview window
    @drawPreviews()
    @highlightPreview()

    @trigger 'music:play', 'bgm-tutorial'

module.exports = LevelSelectScene

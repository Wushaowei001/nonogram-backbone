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

    @canvases = @$('.preview .group:first-child canvas')
    @altCanvases = @$('.preview .group:last-child canvas')

  previous: (e) ->
    e.preventDefault()

    if @page > 0
      @page -= 1

      # Handle dimming prev/next buttons
      @$('.previous').addClass 'disabled' if @page is 0
      @$('.next').removeClass 'disabled' if @page is @totalPages - 1

      @trigger 'sfx:play', 'button'

      @animateThumbnails("-")

  next: (e) ->
    e.preventDefault()

    if @page < @totalPages
      @page += 1

      # Handle dimming prev/next buttons
      @$('.next').addClass 'disabled' if @page is @totalPages
      @$('.previous').removeClass 'disabled' if @page is 1

      @trigger 'sfx:play', 'button'

      @animateThumbnails()

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

  animateThumbnails: (direction = "") ->
    opposite = if direction == "-" then "" else "-"

    # Move existing thumbnails off
    @canvases.parent('.group').css('z-index': 0)
    @canvases.each (i, element) =>
      canvas = $(element)

      _.delay =>
        canvas.animate({
          transform: "translateX(#{direction}#{@width}px)"
        }, "fast", "ease-in-out")
      , i * 100

    # switch thumbnail groups
    tmp = @canvases
    @canvases = @altCanvases
    @altCanvases = tmp

    # Draw on 'em
    @drawThumbnails()

    # Move new thumbnails on
    @canvases.parent('.group').css('z-index': 1)
    @canvases.each (i, element) =>
      canvas = $(element)

      # Start offscreen
      canvas.animate({
        transform: "translateX(#{opposite}#{@width}px)"
      }, 0)

      _.delay ->
        canvas.animate({
          transform: "translateX(0)"
        }, "fast", "ease-in-out")
      , i * 100 + 250

    @selectedLevel = @page * @perPage
    @highlightThumbnail()

  drawThumbnails: ->
    @canvases.each (i, element) =>
      canvas = $(element)
      context = canvas[0].getContext('2d')
      context.clearRect(0, 0, canvas.width(), canvas.height())

      index = @page * @perPage + i
      levelData = levels[@difficulty][index]

      if levelData is undefined
        canvas.hide()
      else
        canvas.show()
        clues = if @stats[index]?.time
                  levelData.clues
                else
                  levels.incomplete.clues

        gridSize = Math.sqrt(levelData.clues.length)
        canvasSize = Math.floor(canvas.width() / 10) * 10
        pixelSize = Math.floor(canvasSize / gridSize)

        # Make each canvas an even multiple, so grids can
        # be drawn without artifacts caused by antialiasing
        canvas.attr('width', canvasSize)
        canvas.attr('height', canvasSize)

        for clue, index in clues
            if clue is 1
              x = index % gridSize
              y = Math.floor(index / gridSize)
              context.fillRect(x * pixelSize, y * pixelSize, pixelSize, pixelSize)

  select: (event) ->
    selected = @page * @perPage + $(event.target).index()
    return if @selectedLevel == selected
    @selectedLevel = selected
    @highlightThumbnail()

  highlightThumbnail: ->
    index = @selectedLevel - @page * @perPage
    selected = @canvases.eq(index)
    @canvases.removeClass 'selected'
    selected.addClass 'selected'
    @showLevelInfo()

  resize: (width, height, orientation) ->
    # Re-draw thumbnails, since resetting width/height on a canvas erases it
    @drawThumbnails()

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

    @totalPages = Math.ceil(levels[@difficulty].length / @perPage) - 1 # 0-based index
    # Determine the last viewed level for this difficulty
    @selectedLevel = localStorage.getObject('lastViewedLevel')[@difficulty] || 0
    @page = Math.floor(@selectedLevel / @perPage)

    # disable/enable buttons
    @$('.previous, .next').addClass 'disabled'
    if @page > 0 then @$('.previous').removeClass 'disabled'
    if @page < @totalPages then @$('.next').removeClass 'disabled'

    # Update level stats based on localStorage
    @stats = localStorage.getObject('stats')[@difficulty]

    # Move alt canvases off-screen
    @altCanvases.animate({ transform: "translateX(-#{@width}px)" }, 0)

    # Ensure on-screen group is clickable
    @altCanvases.parent('.group').css('z-index': 0)
    @canvases.parent('.group').css('z-index': 1)

    @drawThumbnails()
    @highlightThumbnail()

    @trigger 'music:play', 'bgm-tutorial'

module.exports = LevelSelectScene

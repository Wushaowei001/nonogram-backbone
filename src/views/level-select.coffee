$        = require('../vendor/zepto')
_        = require('underscore')
ENV      = require('../lib/env')
Scene    = require('../lib/scene')
template = require('../templates/level-select')
levels   = require('../data/levels')

class LevelSelectScene extends Scene
  events: ->
    if ENV.mobile
      'touchend .back': 'back'
      'touchend .previous': 'previous'
      'touchend .next': 'next'
      'touchend .play': 'play'
      'touchstart canvas': 'select'
    else
      'click .back': 'back'
      'click .previous': 'previous'
      'click .next': 'next'
      'click .play': 'play'
      'click canvas': 'select'

  selectedLevel: 0
  page: 0
  difficulty: 'easy'
  stats: {}
  PER_PAGE: 9
  THUMBNAIL_DELAY: 50
  PAGE_DELAY: 150

  initialize: ->
    @elem = $(template())
    @render()

    @canvases = @$('.preview .group:first-child canvas')
    @altCanvases = @$('.preview .group:last-child canvas')

  previous: (e) ->
    if @page > 0
      @page -= 1

      @trigger 'sfx:play', 'button'
      @enableOrDisablePagingButtons()
      @animateThumbnails("-")

  next: (e) ->
    if @page < @totalPages
      @page += 1

      @trigger 'sfx:play', 'button'
      @enableOrDisablePagingButtons()
      @animateThumbnails()

  play: (e) ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'game',
      { difficulty: @difficulty, level: @selectedLevel }

  back: (e) ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'difficultySelect'

  enableOrDisablePagingButtons: ->
    @$('.next').removeClass 'disabled'
    @$('.previous').removeClass 'disabled'

    @$('.next').addClass 'disabled' if @page is @totalPages
    @$('.previous').addClass 'disabled' if @page is 0

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

    # Store as "last viewed level"
    lastViewedLevel = localStorage.getObject('lastViewedLevel')
    lastViewedLevel[@difficulty] = @selectedLevel
    localStorage.setObject 'lastViewedLevel', lastViewedLevel

  animateThumbnails: (direction = "") ->
    opposite = if direction == "-" then "" else "-"
    offscreenWidth = @width * 1.5

    # Move existing thumbnails off
    @canvases.parent('.group').css('z-index': 0)
    @canvases.each (i, element) =>
      canvas = $(element)
      delayTime = if direction is "-"
        i * @THUMBNAIL_DELAY
      else
        (@PER_PAGE * @THUMBNAIL_DELAY) - (i * @THUMBNAIL_DELAY)

      _.delay ->
        canvas.animate({
          "-webkit-transform": "translateX(#{direction}#{offscreenWidth}px)" # Bug with Zepto/Safari
          transform: "translateX(#{direction}#{offscreenWidth}px)"
        }, "fast", "ease-in-out")
      , delayTime

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
      delayTime = if direction is "-"
        i * @THUMBNAIL_DELAY + @PAGE_DELAY
      else
        (@PER_PAGE * @THUMBNAIL_DELAY) - (i * @THUMBNAIL_DELAY) + @PAGE_DELAY

      # Start offscreen
      canvas.animate({
        "-webkit-transform": "translateX(#{opposite}#{offscreenWidth}px)" # Bug with Zepto/Safari
        transform: "translateX(#{opposite}#{offscreenWidth}px)"
      }, 0)

      _.delay ->
        canvas.animate({
          "-webkit-transform": "translateX(0)" # Bug with Zepto/Safari
          transform: "translateX(0)"
        }, "fast", "ease-in-out")
      , delayTime

    @selectedLevel = @page * @PER_PAGE
    @highlightThumbnail()

  drawThumbnails: ->
    @canvases.each (i, element) =>
      canvas = $(element)
      context = canvas[0].getContext('2d')
      context.clearRect(0, 0, canvas.width(), canvas.height())

      index = @page * @PER_PAGE + i
      levelData = levels[@difficulty][index]

      if levelData is undefined
        canvas.hide()
      else
        canvas.show()
        clues = if @stats[index]?.time
                  levelData.clues
                else
                  levels.incomplete.clues

        gridSize = Math.sqrt(clues.length)
        canvasSize = Math.floor(canvas.width() / gridSize) * gridSize
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
    selected = @page * @PER_PAGE + $(event.target).index()
    return if @selectedLevel == selected
    @trigger 'sfx:play', 'button'
    @selectedLevel = selected
    @highlightThumbnail(animate = true)

  highlightThumbnail: (animate = false) ->
    index = @selectedLevel - @page * @PER_PAGE
    selected = @canvases.eq(index)
    @canvases.removeClass('selected')
    selected.addClass('selected')
    selected.animate('pulse', 'fast', 'cubic-bezier(.0,.0,.5,1.5)') if animate
    @showLevelInfo()

  resize: (width, height, orientation) ->
    # Re-draw thumbnails, since resetting width/height on a canvas erases it
    @drawThumbnails()

    @width = width
    @height = height

    offscreenWidth = @width * 1.5
    @altCanvases.animate({ transform: "translateX(-#{offscreenWidth}px)" }, 0)

  hide: (duration = 500, callback) ->
    super duration, callback

  show: (duration = 500, callback) ->
    super duration, callback

    @totalPages = Math.ceil(levels[@difficulty].length / @PER_PAGE) - 1 # 0-based index

    # Determine the last viewed level for this difficulty
    @selectedLevel = localStorage.getObject('lastViewedLevel')[@difficulty] || 0
    @page = Math.floor(@selectedLevel / @PER_PAGE)

    @enableOrDisablePagingButtons()

    # Update level stats based on localStorage
    @stats = localStorage.getObject('stats')[@difficulty] || {}

    # Move alt canvases off-screen
    offscreenWidth = @width * 1.5
    @altCanvases.animate({ transform: "translateX(-#{offscreenWidth}px)" }, 0)

    # Ensure on-screen group is clickable
    @altCanvases.parent('.group').css('z-index': 0)
    @canvases.parent('.group').css('z-index': 1)

    @drawThumbnails()
    @highlightThumbnail()

    @trigger 'music:play', 'bgm-tutorial'

module.exports = LevelSelectScene

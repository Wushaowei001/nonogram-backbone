$        = require('../vendor/zepto')
_        = require('underscore')
ENV      = require('../lib/env')
Scene    = require('../lib/scene')
template = require('../templates/puzzle-select')
puzzleData  = require('../data/puzzles')

class PuzzleSelectScene extends Scene
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

  selected: 0
  page: 0
  difficulty: 'beginner'
  stats: {}
  PER_PAGE: 9
  THUMBNAIL_DELAY: 50
  PAGE_DELAY: 150

  initialize: ->
    @elem = $(template())
    @render()

    @canvases = $('.preview .group:first-child canvas', @elem)
    @altCanvases = $('.preview .group:last-child canvas', @elem)

    @puzzles = puzzleData

  previous: ->
    return unless @page > 0
    @trigger 'sfx:play', 'button'
    @page -= 1
    @enableOrDisablePagingButtons()
    @animateThumbnails("-")

  next:  ->
    return unless @page < @totalPages
    @trigger 'sfx:play', 'button'
    @page += 1
    @enableOrDisablePagingButtons()
    @animateThumbnails()

  play: ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'game',
      { difficulty: @difficulty, puzzle: @selected }

  back: ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'difficultySelect'

  enableOrDisablePagingButtons: ->
    $('.next', @elem).removeClass 'disabled'
    $('.previous', @elem).removeClass 'disabled'

    $('.next', @elem).addClass 'disabled' if @page is @totalPages
    $('.previous', @elem).addClass 'disabled' if @page is 0

  showPuzzleInfo: ->
    # TODO move this elsewhere
    pad = (number, length) ->
      string = String(number)
      string = '0' + string while string.length < length
      return string

    String::capitalize = ->
      @.charAt(0).toUpperCase() + @.slice(1)

    if @stats[@selected]?.time
      minutes = pad Math.floor(@stats[@selected].time / 60), 2
      seconds = pad @stats[@selected].time % 60, 2
      time = "#{minutes}:#{seconds}"
    else
      time = '--:--'

    attempts = @stats[@selected]?.attempts || "0"

    @elem.find('.attempts').html "Attempts: #{attempts}"
    @elem.find('.best-time').html "Best Time: #{time}"

    puzzle = @puzzles[@difficulty][@selected]

    # If puzzle is completed, show preview, title, etc.
    if time != '--:--'
      @elem.find('.puzzle-number').html "#{@difficulty.capitalize()} ##{@selected + 1}: #{puzzle.title}"
    else
      @elem.find('.puzzle-number').html "#{@difficulty.capitalize()} ##{@selected + 1}: ????"

    # Store as "last viewed puzzle"
    lastViewedPuzzle = localStorage.getObject('lastViewedPuzzle')
    lastViewedPuzzle[@difficulty] = @selected
    localStorage.setObject 'lastViewedPuzzle', lastViewedPuzzle

  animateThumbnails: (direction = "") ->
    opposite = if direction == "-" then "" else "-"
    offscreenWidth = @width * 1.5

    # Move existing thumbnails off
    @canvases.parent('.group').css('z-index': 0)
    @canvases.forEach (element, i) =>
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
    @canvases.forEach (element, i) =>
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

    @selected = @page * @PER_PAGE
    @highlightThumbnail()

  drawThumbnails: ->
    @canvases.forEach (element, i) =>
      canvas = $(element)
      context = canvas[0].getContext('2d')
      context.clearRect(0, 0, canvas.width(), canvas.height())

      index = @page * @PER_PAGE + i
      puzzle = @puzzles[@difficulty][index]

      if puzzle is undefined
        canvas.hide()
      else
        canvas.show()

        # Always show user-created puzzles and completed puzzles
        # TODO a better check here to see if thumbnail should be shown
        if @difficulty == 'user' || @stats[index]?.time
          clues = puzzle.clues
        else
          clues =  @puzzles.incomplete.clues

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
    return if @selected == selected
    @trigger 'sfx:play', 'button'
    @selected = selected
    @highlightThumbnail(animate = true)

  highlightThumbnail: (animate = false) ->
    index = @selected - @page * @PER_PAGE
    selected = @canvases.eq(index)
    @canvases.removeClass('selected')
    selected.addClass('selected')
    selected.animate('pulse', 'fast', 'cubic-bezier(.0,.0,.5,1.5)') if animate
    @showPuzzleInfo()

  resize: (width, height, orientation) ->
    # Re-draw thumbnails, since resetting width/height on a canvas erases it
    @drawThumbnails()

    @width = width
    @height = height

    offscreenWidth = @width * 1.5
    @altCanvases.animate({
      "-webkit-transform": "translateX(-#{offscreenWidth}px)" # Bug with Zepto/Safari
      transform: "translateX(-#{offscreenWidth}px)"
    }, 0)

  show: (duration = 500, callback) ->
    super duration, callback

    # 0-based index
    @totalPages = Math.ceil(@puzzles[@difficulty].length / @PER_PAGE) - 1

    # Determine the last viewed puzzle for this difficulty
    @selected = localStorage.getObject('lastViewedPuzzle')[@difficulty] || 0
    @page = Math.floor(@selected / @PER_PAGE)

    @enableOrDisablePagingButtons()

    # Update puzzle stats based on localStorage
    @stats = localStorage.getObject('stats')[@difficulty] || {}

    # Move alt canvases off-screen
    offscreenWidth = @width * 1.5
    @altCanvases.animate({ 
      "-webkit-transform": "translateX(-#{offscreenWidth}px)" # Bug with Zepto/Safari
      transform: "translateX(-#{offscreenWidth}px)"
    }, 0)

    # Ensure on-screen group is clickable
    @altCanvases.parent('.group').css('z-index': 0)
    @canvases.parent('.group').css('z-index': 1)

    @drawThumbnails()
    @highlightThumbnail()

    @trigger 'music:play', 'bgm-tutorial'

module.exports = PuzzleSelectScene

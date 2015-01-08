_         = require('underscore')
$         = require('../vendor/zepto')
Scene     = require('../classes/scene')
DialogBox = require('../classes/dialog-box')
Input     = require('../utilities/input')
ENV       = require('../utilities/env')
template  = require('../templates/editor')

class EditorScene extends Scene
  events: ->
    if ENV.mobile
      'touchend .save': 'save'
      'touchend .quit': 'quit'
      'touchend .undo': 'undo'
      'touchend .undo': 'help'
      'touchend .larger': 'makeGridLarger'
      'touchend .smaller': 'makeGridSmaller'
      'touchstart': 'onPointStart'
      'touchmove': 'onPointMove'
      'touchend': 'onPointEnd'
    else
      'click .save': 'save'
      'click .quit': 'quit'
      'click .undo': 'undo'
      'click .undo': 'help'
      'click .larger': 'makeGridLarger'
      'click .smaller': 'makeGridSmaller'
      'mousedown': 'onPointStart'
      'mouseup': 'onPointEnd'

  MAX_CELL_COUNT: 10
  MIN_CELL_COUNT: 5
  GRID_SIZE_RATIO: 0.97
  cellCount: 10

  initialize: ->
    _.bindAll(@, 'onPointStart', 'onPointMove', 'onPointEnd')

    # View is initialized hidden
    @elem = $(template())
    @render()

  # Append the view's elem to the DOM
  render: ->
    @$el.append(@elem)

    # Get some references to DOM elements that we need later
    @grid = @elem.find('.grid')

  quit: (e) ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'title'

  save: (e) ->
    @trigger 'sfx:play', 'button'

    # TODO: Determine a way to give the puzzle a title, so as to store
    # by key, rather than a dumb array
    userLevels = localStorage.getObject('userLevels') || []

    cells = @grid.children('div').slice(0, Math.pow(@cellCount, 2))
    levelData = _(cells).map (cell) ->
      return if $(cell).hasClass('filled') then 1 else 0

    userLevels.push(levelData)
    localStorage.setObject('userLevels', userLevels)

  makeGridLarger: (e) ->
    if @cellCount < @MAX_CELL_COUNT
      @trigger 'sfx:play', 'button'
      @cellCount += 1
      @resizeGrid()
      @enableOrDisableGridResizeButtons()

  makeGridSmaller: (e) ->
    if @cellCount > @MIN_CELL_COUNT
      @trigger 'sfx:play', 'button'
      @cellCount -= 1
      @resizeGrid()
      @enableOrDisableGridResizeButtons()

  enableOrDisableGridResizeButtons: ->
    if @MIN_CELL_COUNT < @cellCount < @MAX_CELL_COUNT
      @$('.larger').removeClass 'disabled'
      @$('.smaller').removeClass 'disabled'
    else
      @$('.larger').addClass 'disabled' if @cellCount is @MAX_CELL_COUNT
      @$('.smaller').addClass 'disabled' if @cellCount is @MIN_CELL_COUNT

  resizeGrid: ->
    smallestDimension = if @orientation is 'landscape' then @height else @width
    maxGridSize = Math.round(smallestDimension * @GRID_SIZE_RATIO / 10) * 10

    @cellSize = maxGridSize / 10
    @grid.width(@cellCount * @cellSize)
    @grid.height(@cellCount * @cellSize)

    if @orientation is 'landscape'
      horizontalMargin = (@height - @grid.width() - 10) / 2
      verticalMargin = (maxGridSize - @grid.height()) / 2
    else if @orientation is 'portrait'
      verticalMargin = (@width - @grid.height() - 10) / 2
      horizontalMargin = (maxGridSize - @grid.width()) / 2

    @grid.css
      margin: "#{horizontalMargin}px #{verticalMargin}px"

    # TODO: Can the rest of this method be optimized?
    @grid.children('div').css
      width: @cellSize
      height: @cellSize

    @grid.children('div').each (index, element) =>
      if index < Math.pow(@cellCount, 2)
        $(element).show()
      else
        $(element).hide()

  onPointStart: (e) ->
    e.preventDefault()

    # Determine if event was caused by mouse or finger
    if e.type == 'mousedown' then @elem.on 'mousemove', @onPointMove

    position = Input.normalize(e)

    row = Math.floor((position.y - @grid.offset().top) / @cellSize)
    col = Math.floor((position.x - @grid.offset().left) / @cellSize)

    if 0 <= row < @MAX_CELL_COUNT and 0 <= col < @MAX_CELL_COUNT
      @previousRow = row
      @previousCol = col
      @fillBlock(row, col)

  # Triggered on mousemove or touchmove
  onPointMove: (e) ->
    e.preventDefault()

    position = Input.normalize e

    row = Math.floor((position.y - @grid.offset().top) / @cellSize)
    col = Math.floor((position.x - @grid.offset().left) / @cellSize)

    if 0 <= row < @MAX_CELL_COUNT and 0 <= col < @MAX_CELL_COUNT
      @fillBlock(row, col) if row != @previousRow or col != @previousCol

      @previousRow = row
      @previousCol = col

  # Triggered on mouseup or touchend
  onPointEnd: (e) ->
    e.preventDefault()

    # Determine if event was caused by mouse or finger
    if e.type == 'mouseup' then @elem.off 'mousemove', @onPointMove

    @previousRow = @previousCol = null

  fillBlock: (row, col) ->
    index = row * @cellCount + col
    block = @grid.find('div').eq(index)

    if block.hasClass('filled') is true
      @trigger 'sfx:play', 'mark'
      block.removeClass 'filled'
    else
      @trigger 'sfx:play', 'mark'
      block.addClass 'filled'

  resize: (width, height, orientation) ->
    @width = width
    @height = height
    @orientation = orientation
    @resizeGrid()

  show: (duration = 500, callback) ->
    super duration, callback
    @enableOrDisableGridResizeButtons()

module.exports = EditorScene

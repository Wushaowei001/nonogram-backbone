$ = require('../vendor/zepto')
_ = require('underscore')
Scene = require('../classes/scene')
ENV = require('../utilities/env')
template = require('../templates/editor')
DialogBox = require('../classes/dialog-box')
Input = require('../utilities/input')

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

  MAX_GRID_SIZE: 10
  MIN_GRID_SIZE: 5
  gridSize: 10

  initialize: ->
    _.bindAll(@, 'onPointStart', 'onPointMove', 'onPointEnd')

    # View is initialized hidden
    @elem = $(template())
    @render()

  # Append the view's elem to the DOM
  render: ->
    @$el.append @elem

    # Get some references to DOM elements that we need later
    @grid = @elem.find('.grid')

  quit: (e) ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'title'

  # max: 10 squares
  makeGridLarger: (e) ->
    if @gridSize < @MAX_GRID_SIZE
      @trigger 'sfx:play', 'button'
      @gridSize += 1
      @resizeGrid()

  # min: 5 squares
  makeGridSmaller: (e) ->
    if @gridSize > @MIN_GRID_SIZE
      @trigger 'sfx:play', 'button'
      @gridSize -= 1
      @resizeGrid()

  resizeGrid: ->
    @grid.width(@gridSize * @blockSize)
    @grid.height(@gridSize * @blockSize)
    @grid.children('div').each (index, element) =>
      if index < Math.pow(@gridSize, 2)
        $(element).show()
      else
        $(element).hide()

  onPointStart: (e) ->
    e.preventDefault()

    # Determine if event was caused by mouse or finger
    if e.type == 'mousedown' then @elem.on 'mousemove', @onPointMove

    position = Input.normalize(e)

    row = Math.floor((position.y - @grid.offset().top) / @blockSize)
    col = Math.floor((position.x - @grid.offset().left) / @blockSize)

    if 0 <= row <= 9 and 0 <= col <= 9
      @previousRow = row
      @previousCol = col
      @fillBlock(row, col)

  # Triggered on mousemove or touchmove
  onPointMove: (e) ->
    e.preventDefault()

    position = Input.normalize e

    row = Math.floor((position.y - @grid.offset().top) / @blockSize)
    col = Math.floor((position.x - @grid.offset().left) / @blockSize)

    # Only recognize movement if within grid bounds
    if 0 <= row < @MAX_GRID_SIZE and 0 <= col < @MAX_GRID_SIZE
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
    index = row * @gridSize + col
    block = @grid.find('div').eq(index)

    if block.hasClass('filled') is true
      @trigger 'sfx:play', 'mark'
      block.removeClass 'filled'
    else
      @trigger 'sfx:play', 'mark'
      block.addClass 'filled'

  resize: (width, height, orientation) ->
    # TODO: lots of duplication here, refactor!
    # TODO: rename @gridSize; it's the # of cells in the grid, whereas
    # @blockSize is an actual pixel size
    if orientation is 'landscape'
      maxGridSize = Math.round(height * 0.97 / 10) * 10   # Make sure grid background size is 97% of viewport
      @blockSize = maxGridSize / 10
      @grid.width(@gridSize * @blockSize)
      @grid.height(@gridSize * @blockSize)

      # Add some margin to the grid, so it appears centered
      horizontalMargin = (height - @grid.width() - 10) / 2
      verticalMargin = (maxGridSize - @grid.height()) / 2

    else if orientation is 'portrait'
      maxGridSize = Math.round(width * 0.97 / 10) * 10  # grid size is 97% of viewport
      @blockSize = maxGridSize / 10
      @grid.width(@gridSize * @blockSize)
      @grid.height(@gridSize * @blockSize)

      # Add some margin to the grid, so it appears centered
      verticalMargin = (width - @grid.height() - 10) / 2
      horizontalMargin = (maxGridSize - @grid.width()) / 2
      
    @grid.css
      margin: "#{horizontalMargin}px #{verticalMargin}px"

    @grid.children('div').css
      width: @blockSize
      height: @blockSize

module.exports = EditorScene

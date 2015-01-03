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
    # Ensure 'this' has correct context
    #_.bindAll @, 'onPointStart', 'onPointMove', 'onPointEnd', 'fillBlock', 'checkCompleted', 'win', 'pause', 'changePoint', 'updateTimer', 'showTutorial', 'resize', 'hide', 'show'
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
    if 0 <= row <= 9 and 0 <= col <= 9
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
    index = row * 10 + col

    block = @grid.find('div').eq(index)

    if block.hasClass('filled') is true
      @trigger 'sfx:play', 'mark'
      block.removeClass 'filled'
    else
      @trigger 'sfx:play', 'mark'
      block.addClass 'filled'

  resize: (width, height, orientation) ->
    if orientation is 'landscape'
      gridWidth = Math.round(height * 0.97 / 10) * 10   # Make sure grid background size is 97% of viewport
      @grid.width gridWidth
      @grid.height gridWidth

      # Add some margin to the grid, so it appears centered
      margin = (height - gridWidth - 10) / 2
      @grid.css
        'margin': "#{margin}px 0"

    else if orientation is 'portrait'
      gridWidth = Math.round(width * 0.97 / 10) * 10  # grid size is 97% of viewport
      @grid.width gridWidth
      @grid.height gridWidth

      # Add some margin to the grid, so it appears centered
      margin = (width - gridWidth - 10) / 2
      @grid.css
        'margin': "0 #{margin}px"

    @blockSize = gridWidth / 10

module.exports = EditorScene

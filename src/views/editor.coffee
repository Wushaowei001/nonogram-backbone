_         = require('underscore')
$         = require('../vendor/zepto')
Scene     = require('../lib/scene')
DialogBox = require('../lib/dialog-box')
Input     = require('../lib/input')
ENV       = require('../lib/env')
template  = require('../templates/editor')

class EditorScene extends Scene
  events: ->
    if ENV.mobile
      'touchend .save': 'save'
      'touchend .quit': 'quit'
      'touchend .undo': 'undo'
      'touchend .redo': 'redo'
      'touchend .larger': 'makeGridLarger'
      'touchend .smaller': 'makeGridSmaller'
      'touchstart': 'onPointStart'
      'touchmove': 'onPointMove'
      'touchend': 'onPointEnd'
    else
      'click .save': 'save'
      'click .quit': 'quit'
      'click .undo': 'undo'
      'click .redo': 'redo'
      'click .larger': 'makeGridLarger'
      'click .smaller': 'makeGridSmaller'
      'mousedown': 'onPointStart'
      'mouseup': 'onPointEnd'

  MAX_CELL_COUNT: 10
  MIN_CELL_COUNT: 5
  GRID_SIZE_RATIO: 0.97
  cellCount: 10
  undoList: []
  redoList: []

  initialize: ->
    _.bindAll(@, 'onPointMove')
    @elem = $(template())
    @render()

  # Append the view's elem to the DOM
  render: ->
    @$el.append(@elem)

    # Get some references to DOM elements that we need later
    @grid = @elem.find('.grid')

  quit: (e) ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger('sfx:play', 'button')
    @trigger('scene:change', 'title')

  save: (e) ->
    @trigger('sfx:play', 'button')
    @ignoreInput = true

    new DialogBox
      el: @elem
      parent: @
      title: 'Save Level'
      html: """<input type="text" id="level-name" placeholder="Enter name here" value="">"""
      buttons: [
        {
          text: 'Save'
          callback: =>
            name = @$('#level-name').val()

            @ignoreInput = false
            # TODO: Determine a way to give the puzzle a title, so as to store
            # by key, rather than a dumb array
            # TODO: Think about re-organizing levels to be stored in an object,
            # rather than an array
            userLevels = localStorage.getObject('userLevels') || []

            cells = @grid.children('div').slice(0, Math.pow(@cellCount, 2))
            data = _(cells).map (cell) ->
              return if $(cell).hasClass('filled') then 1 else 0

            userLevels.push({ title: name, clues: data })
            console.log { title: name, clues: data }
            localStorage.setObject('userLevels', userLevels)
        },
        { 
          text: 'Cancel'
          callback: =>
            @ignoreInput = false
        }
      ]

  makeGridLarger: (e) ->
    if @cellCount < @MAX_CELL_COUNT
      @trigger 'sfx:play', 'button'
      @cellCount += 1
      @grid.children('div').removeClass('filled')
      @resizeGrid()
      @enableOrDisableGridResizeButtons()

  makeGridSmaller: (e) ->
    if @cellCount > @MIN_CELL_COUNT
      @trigger 'sfx:play', 'button'
      @cellCount -= 1
      @grid.children('div').removeClass('filled')
      @resizeGrid()
      @enableOrDisableGridResizeButtons()

  enableOrDisableGridResizeButtons: ->
    if @MIN_CELL_COUNT < @cellCount < @MAX_CELL_COUNT
      @$('.larger').removeClass('disabled')
      @$('.smaller').removeClass('disabled')
    else
      @$('.larger').addClass('disabled') if @cellCount is @MAX_CELL_COUNT
      @$('.smaller').addClass('disabled') if @cellCount is @MIN_CELL_COUNT

  resizeGrid: ->
    smallestDimension = if @orientation is 'landscape' then @height else @width
    maxGridSize = Math.round(smallestDimension * @GRID_SIZE_RATIO / 10) * 10
    borderWidth = parseInt(@grid.css('border-width'), 10) * 2
    @cellSize = maxGridSize / 10
    gridSize = @cellCount * @cellSize

    @grid.width(gridSize)
    @grid.height(gridSize)

    if @orientation is 'landscape'
      horizontalMargin = (@height - gridSize - borderWidth) / 2
      verticalMargin = (maxGridSize - gridSize) / 2
    else if @orientation is 'portrait'
      verticalMargin = (@width - gridSize - borderWidth) / 2
      horizontalMargin = (maxGridSize - gridSize) / 2

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
    return if @ignoreInput

    # Determine if event was caused by mouse or finger
    if e.type is 'mousedown' then @elem.on('mousemove', @onPointMove)

    position = Input.normalize(e)

    row = Math.floor((position.y - @grid.offset().top) / @cellSize)
    col = Math.floor((position.x - @grid.offset().left) / @cellSize)

    if 0 <= row < @MAX_CELL_COUNT and 0 <= col < @MAX_CELL_COUNT
      @previousRow = row
      @previousCol = col
      @fillBlock(row, col)

  # Triggered on mousemove or touchmove
  onPointMove: (e) ->
    return if @ignoreInput

    position = Input.normalize e

    row = Math.floor((position.y - @grid.offset().top) / @cellSize)
    col = Math.floor((position.x - @grid.offset().left) / @cellSize)

    if 0 <= row < @MAX_CELL_COUNT and 0 <= col < @MAX_CELL_COUNT
      @fillBlock(row, col) if row != @previousRow or col != @previousCol

      @previousRow = row
      @previousCol = col

  # Triggered on mouseup or touchend
  onPointEnd: (e) ->
    return if @ignoreInput

    # Determine if event was caused by mouse or finger
    if e.type is 'mouseup' then @elem.off('mousemove', @onPointMove)

    @previousRow = @previousCol = null

  fillBlock: (row, col) ->
    index = row * @cellCount + col
    block = @grid.find('div').eq(index)

    @trigger('sfx:play', 'mark')

    if block.hasClass('filled') is true
      block.removeClass('filled')
    else
      block.addClass('filled')
      block.animate('pulse', 'fast', 'ease-in-out')

  resize: (width, height, orientation) ->
    @width = width
    @height = height
    @orientation = orientation
    @resizeGrid()

  show: (duration = 500, callback) ->
    super duration, callback
    @enableOrDisableGridResizeButtons()

module.exports = EditorScene

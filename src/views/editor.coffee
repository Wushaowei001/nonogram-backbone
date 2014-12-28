$ = require('../vendor/zepto')
_ = require('underscore')
Scene = require('../classes/scene')
ENV = require('../utilities/env')
template = require('../templates/editor')
DialogBox = require('../classes/dialog-box')

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

  initialize: ->
    @elem = $(template())
    @render()

  initialize: ->
    # Ensure 'this' has correct context
    _.bindAll @, 'onPointStart', 'onPointMove', 'onPointEnd', 'doPoint', 'checkCompleted', 'win', 'pause', 'changePoint', 'updateTimer', 'showTutorial', 'resize', 'hide', 'show'

    # View is initialized hidden
    @elem = $(template())
    @render()

  # Append the view's elem to the DOM
  render: ->
    @$el.append @elem

    # Get some references to DOM elements that we need later
    @grid = @$('.grid')

    # Get size of grid blocks - round to nearest whole number to prevent weirdness w/ decimals
    @blockSize = Math.round @grid.width() / 10

  quit: (e) ->
    e.preventDefault()
    @undelegateEvents() # Prevent multiple clicks

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'title'

  # max: 10 squares
  makeGridLarger: (e) ->
    e.preventDefault()
    @trigger 'sfx:play', 'button'

  # min: 5 squares
  makeGridSmaller: (e) ->
    e.preventDefault()
    @trigger 'sfx:play', 'button'

  onPointStart: (e) ->
    e.preventDefault()

    # Determine if event was caused by mouse or finger
    if e.type == 'mousedown' then @elem.on 'mousemove', @onPointMove

    position = Input.normalize e

    row = Math.floor((position.y - @grid.offset().top) / @blockSize)
    col = Math.floor((position.x - @grid.offset().left) / @blockSize)

    # Only recognize movement if within grid bounds
    if 0 <= row <= 9 and 0 <= col <= 9
      @previousRow = row
      @previousCol = col
      @doPoint(row, col) 

  # Triggered on mousemove or touchmove
  onPointMove: (e) ->
    e.preventDefault()

    position = Input.normalize e

    row = Math.floor((position.y - @grid.offset().top) / @blockSize)
    col = Math.floor((position.x - @grid.offset().left) / @blockSize)

    # Only recognize movement if within grid bounds
    if 0 <= row <= 9 and 0 <= col <= 9
      @doPoint(row, col) if row != @previousRow or col != @previousCol

      @previousRow = row
      @previousCol = col

  # Triggered on mouseup or touchend
  onPointEnd: (e) ->
    e.preventDefault()

    # Determine if event was caused by mouse or finger
    if e.type == 'mouseup' then @elem.off 'mousemove', @onPointMove

    @previousRow = @previousCol = null

  doPoint: (row, col) ->
    index = row * 10 + col

    block = @grid.find('div').eq(index)

    if block.hasClass('filled') is true
      @trigger 'sfx:play', 'mark'
      block.removeClass 'filled'
    else
      @trigger 'sfx:play', 'mark'
      block.addClass 'filled'

module.exports = EditorScene

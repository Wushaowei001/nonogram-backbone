$            = require('../vendor/zepto')
_            = require('underscore')
ENV          = require('../lib/env')
Scene        = require('../lib/scene')
FloatingText = require('../lib/floating-text')
DialogBox    = require('../lib/dialog-box')
Input        = require('../lib/input')
template     = require('../templates/game')
levels       = require('../data/levels')

class GameScene extends Scene
  events: ->
    if ENV.mobile
      'touchend .pause': 'pause'
      'touchend .mark': 'changeAction'
      'touchend .fill': 'changeAction'
      'touchstart': 'onActionStart'
      'touchmove': 'onActionMove'
      'touchend': 'onActionEnd'
    else
      'click .pause': 'pause'
      'click .mark': 'changeAction'
      'click .fill': 'changeAction'
      'mousedown': 'onActionStart'
      'mouseup': 'onActionEnd'

  GRID_SIZE_RATIO: 0.75
  GRID_BACKGROUND_SIZE_RATIO: 0.97

  difficulty: "beginner"
  level: 0

  timerId: null
  seconds: 0

  clues: []
  grid: null
  action: "mark"
  actionLock: "none"
  hits: 0
  totalHits: 0
  misses: 0

  blockSize: 0
  startRow: -1
  startCol: -1
  previousRow: -1
  previousCol: -1
  ignoreInput: false

  # For dealing w/ tutorial
  tutorial: false
  tutorialStep: 0
  hint: null

  initialize: ->
    _.bindAll(@, 'updateTimer', 'onActionMove')

    @elem = $(template())
    @render()

  # Append the view's elem to the DOM
  render: ->
    @$el.append(@elem)

    # Get some references to DOM elements that we need later
    @grid = @elem.find('.grid')
    @gridBackground = @elem.find('.grid-background')

  # Triggered on mousedown or touchstart
  onActionStart: (e) ->
    return if @ignoreInput

    # Determine if event was caused by mouse or finger
    if e.type == 'mousedown' then @elem.on 'mousemove', @onActionMove

    position = Input.normalize e

    row = Math.floor((position.y - @grid.offset().top) / @cellSize)
    col = Math.floor((position.x - @grid.offset().left) / @cellSize)

    if 0 <= row < @cellCount and 0 <= col < @cellCount
      # Determine the row/col
      @startRow = @previousRow = row
      @startCol = @previousCol = col

      # Highlight the clue row/column of the touched cell
      @$('.vertical.clue').eq(col).addClass 'highlight'
      @$('.horizontal.clue').eq(row).addClass 'highlight'

      # Try to mark or fill
      @doAction row, col

  # Triggered on mousemove or touchmove
  onActionMove: (e) ->
    return if @ignoreInput
    return if @startRow is -1 or @startCol is -1

    # Get user input
    position = Input.normalize e

    # Determine the row/col
    row = Math.floor((position.y - @grid.offset().top) / @cellSize)
    col = Math.floor((position.x - @grid.offset().left) / @cellSize)

    if 0 <= row < @cellCount and 0 <= col < @cellCount
      if row != @previousRow or col != @previousCol
        # Update highlighted clue cells
        verticalClues = @$('.vertical.clue')
        verticalClues.eq(@previousCol).removeClass('highlight')
        verticalClues.eq(col).addClass('highlight')

        horizontalClues = @$('.horizontal.clue')
        horizontalClues.eq(@previousRow).removeClass('highlight')
        horizontalClues.eq(row).addClass('highlight')

        # Try to mark or fill
        @doAction(row, col)

      # Reset the "previous" values
      @previousRow = row
      @previousCol = col

  # Triggered on mouseup or touchend
  onActionEnd: (e) ->
    return if @ignoreInput

    # Determine if event was caused by mouse or finger
    if e.type == 'mouseup' then @elem.off 'mousemove', @onActionMove

    # Hide the clue highlights
    @$('.vertical.clue').eq(@previousCol).removeClass('highlight')
    @$('.horizontal.clue').eq(@previousRow).removeClass('highlight')

    # Unset the "mark lock" -- If user starts marking blocks, only allow
    # marking for the duration of that touch, so that they don't accidentally
    # un-mark a block
    @actionLock = "none"

    # Clear out previous touch data
    @startRow = @startCol = @previousRow = @previousCol = -1

  # Try to either mark or fill a grid cell
  doAction: (row, col) ->
    index = row * @cellCount + col

    block = @grid.find('.blank').eq(index)

    valid = @clues[index] == 1

    if @action is 'fill'
      if block.hasClass('filled') is true or block.hasClass('marked')
        # Do nothing
        @trigger('sfx:play', 'invalid')
      else if valid
        block.addClass('filled')
        block.animate('pulse', 'fast', 'ease-in-out')

        # Check whether or not to dim clues in a row/col
        @checkCompleted(row, col)

        @hits += 1
        $('.complete .percentage', @elem).html Math.round(@hits / @totalHits * 100)
        @win() if @hits is @totalHits

        @trigger 'sfx:play', 'fill'
      else
        @trigger 'sfx:play', 'error'
        @misses++

        if @misses is 1
          @seconds += 59  # Add an extra minute to the elapsed time
        else if @misses is 2
          @seconds += 119 # Add an extra two minutes to the elapsed time
        else if @misses is 3
          @seconds += 239 # Add an extra four minutes to the elapsed time
        else
          @seconds += 479 # Add an extra eight minutes to the elapsed time

        # Try to display a status message
        new FloatingText
          text: 'Oops!'
          el: @elem
          position:
            x: block.offset().left
            y: block.offset().top

        # Instantly call the update method - this method adds 1 second,
        # which is why the previous values are -1 second
        @updateTimer()

        # Try to have some visual indication that you made a wrong move
        @trigger 'vfx:play', 'shake'

    else if @action is 'mark'
      # Mark if block is empty
      if block.hasClass('marked') == false and block.hasClass('filled') == false and @actionLock != "remove"
        block.addClass('marked')
        @actionLock = "mark"
        @trigger 'sfx:play', 'mark'
      # Remove mark if already marked
      else if block.hasClass('marked') == true and block.hasClass('filled') == false and @actionLock != "mark"
        block.removeClass('marked')
        @actionLock = "remove"
        @trigger 'sfx:play', 'mark'
      # Play a "click" noise if block is filled
      else
        @trigger 'sfx:play', 'invalid'

  # Determine whether or not to "dim" the clues for a particular row/column
  checkCompleted: (row, col) ->
    columnTotal = 0
    rowTotal = 0
    completedColumnTotal = 0
    completedRowTotal = 0

    blocks = @grid.find('.blank')

    for i in [0 ... @cellCount]
      rowIndex = row * @cellCount + i
      columnIndex = i * @cellCount + col

      if blocks.eq(rowIndex).hasClass('filled')
        completedRowTotal += 1
      if blocks.eq(columnIndex).hasClass('filled')
        completedColumnTotal += 1

      if @clues[rowIndex] is 1 then rowTotal += 1
      if @clues[columnIndex] is 1 then columnTotal += 1

    if rowTotal is completedRowTotal
      @$('.horizontal.clue', @elem).eq(row).addClass('complete')
    if columnTotal is completedColumnTotal
      @$('.vertical.clue', @elem).eq(col).addClass('complete')

  # Actions when player solves the puzzle
  win: ->
    @ignoreInput = true

    # Ensure this event handler is removed, even if user doesn't "unclick"
    @elem.off 'mousemove', @onActionMove

    @trigger 'music:stop'
    @trigger 'sfx:play', 'win'

    window.clearInterval @timerId

    if not @tutorial
      stats = localStorage.getObject 'stats'

      # If level hasn't been completed before...
      if not stats[@difficulty][@level].time
        stats[@difficulty][@level].time = @seconds
        complete = localStorage.getObject 'complete'
        complete[@difficulty]++
        localStorage.setObject 'complete', complete
      else if stats[@difficulty][@level].time > @seconds
        stats[@difficulty][@level].time = @seconds

      localStorage.setObject 'stats', stats
    else
      # Reset the tutorial
      @tutorialStep = 0

    new DialogBox
      parent: @
      el: @elem
      title: 'Puzzle solved!'
      message: levels[@difficulty][@level].title
      buttons: [
        {
          text: 'OK'
          callback: =>
            @ignoreInput = false
            if @tutorial
              @trigger 'scene:change', 'title'
            else
              @trigger 'scene:change', 'levelSelect', { difficulty: @difficulty }
        }
      ]

  # Go back to the level select screen
  pause: (e) ->
    return if @ignoreInput

    @ignoreInput = true

    @trigger 'sfx:play', 'button'

    window.clearInterval @timerId

    new DialogBox
      parent: @
      el: @elem
      title: 'Paused'
      buttons: [
        {
          text: 'Play'
          callback: =>
            @ignoreInput = false
            @timerId = window.setInterval @updateTimer, 1000
        }, {
          text: 'Quit'
          callback: =>
            @ignoreInput = false
            if @tutorial
              # Reset the tutorial
              @tutorialStep = 0

              # Go back to title
              @trigger 'scene:change', 'title'
            else
              @trigger 'scene:change', 'levelSelect', { difficulty: @difficulty }
        }
      ]

  # Change the current user action
  changeAction: (e) ->
    target = $(e.target)

    # User is probably actually clicking an element inside the button
    unless target.hasClass('button') then target = target.parents('.button')
    return if target.hasClass('active')

    @trigger('sfx:play', 'button')

    @elem.find(".button.#{@action}").removeClass('active')

    if target.hasClass('mark')
      @action = 'mark'
      target.addClass('active')
    else
      @action = 'fill'
      target.addClass('active')


  # Update timer elem
  updateTimer: ->
    @seconds++

    pad = (number, length) ->
      string = String(number)
      string = '0' + string while string.length < length
      return string

    minutes = pad Math.floor(@seconds / 60), 2
    seconds = pad @seconds % 60, 2

    @$('.timer .minutes').html(minutes)
    @$('.timer .seconds').html(seconds)

    # Update steps in tutorial here if necessary
    if @tutorial
      success = false
      blocks = @grid.find('.blank')

      # Check if user placed the correct rect
      switch @tutorialStep
        when 4
          # Ensure first column is filled correctly
          stepCompleted = true
          for i in [0, 5, 10, 15, 20]
            if blocks.eq(i).hasClass('filled') is false then stepCompleted = false
          success = stepCompleted
        when 8
          # Ensure 3rd column is filled correctly
          stepCompleted = true
          for i in [2, 12, 22]
            if blocks.eq(i).hasClass('filled') is false then stepCompleted = false
          success = stepCompleted
        when 11
          # Ensure 3rd column is marked correctly
          stepCompleted = true
          for i in [7, 17]
            if blocks.eq(i).hasClass('marked') is false then stepCompleted = false
          success = stepCompleted
        when 12
          # Ensure 4th column is filled correctly
          stepCompleted = true
          for i in [3, 13, 18, 23]
            if blocks.eq(i).hasClass('filled') is false then stepCompleted = false
          success = stepCompleted
        when 13
          # Ensure 5th column is all marked
          stepCompleted = true
          for i in [4, 9, 14, 19, 24]
            if blocks.eq(i).hasClass('marked') is false then stepCompleted = false
          success = stepCompleted
        when 15
          # Ensure 1st row is filled correctly
          stepCompleted = true
          for i in [0...4]
            if blocks.eq(i).hasClass('filled') is false then stepCompleted = false
          success = stepCompleted
        when 16
          # Ensure rest of squares marked correctly
          stepCompleted = true
          for i in [6, 7, 8, 11, 16, 17]
            if blocks.eq(i).hasClass('marked') is false then stepCompleted = false
          success = stepCompleted

      if success
        @tutorialStep += 1
        @showTutorial()


  showTutorial: ->
    @ignoreInput = true

    # Different text based on input type
    actionWord = if ENV.mobile then "tap" else "click"
    capitalActionWord = if ENV.mobile then "Tap" else "Click"

    text = [
      "Welcome to Nonogram Madness! Nonograms are logic puzzles that reveal an image when solved.", 
      "Solve each puzzle using the numeric clues on the top and left of the grid.",
      "Each number represents squares in the grid that are \"filled\" in a row or column.",
      "Clues with multiple numbers mean a gap of one (or more) between filled squares.",
      "Look at the first column. The clue is \"5\". Tap \"fill\" then tap all 5 squares.",
      # Action - 4
      "The second column is harder. We don't know where the two single filled squares are.",
      "Skip difficult rows or columns and come back to them later.",
      "Look at the third column. The clue is \"1 1 1\". There's a gap between each filled square.",
      "Make sure the \"fill\" button is selected, then fill in three squares with a gap between each.",
      # Action - 8
      "You can use the \"mark\" action to protect blocks that are supposed to be empty.",
      "Erase a marked square by selecting it again.",
      "#{capitalActionWord} \"mark\" and mark the empty squares so you don't accidentally try to fill them in later.",
      # Action - 11
      "Check out the fourth column. The clue is \"1 3\". Fill one square, leave a gap, then fill three more.",
      # Action - 12
      "The fifth column is empty. \"Mark\" all those squares to show they don't need to be filled in.",
      # Action - 13
      "Next, look at the horizontal clues. The first row has four sequential filled squares.",
      "Fill in the only open square in this row to complete it.",
      # Action - 15
      "The second, third, and fourth rows are already complete. Mark all the open squares in them.",
      # Action - 16
      "I think you've got the hang of it. Finish the rest of the puzzle yourself!"
    ]

    blocks = @grid.find('.blank')

    # Remove previous hints
    blocks.removeClass('hint')

    # Show hint overlays here
    switch @tutorialStep
      when 4
        for i in [0, 5, 10, 15, 20]
          blocks.eq(i).addClass('hint')
      when 8
        for i in [2, 12, 22]
          blocks.eq(i).addClass('hint')
      when 11
        for i in [7, 17]
          blocks.eq(i).addClass('hint')
      when 12
        for i in [3, 13, 18, 23]
          blocks.eq(i).addClass('hint')
      when 13
        for i in [4, 9, 14, 19, 24]
          blocks.eq(i).addClass('hint')
      when 15
        for i in [0...4]
          blocks.eq(i).addClass('hint')
      when 16
        for i in [6, 8, 11, 16]
          blocks.eq(i).addClass('hint')

    new DialogBox
      parent: @
      el: @elem
      title: text[@tutorialStep]
      buttons: [{
        text: 'OK'
        callback: =>
          @ignoreInput = false

          # These steps indicate where the player has to take action
          if [4, 8, 11, 12, 13, 15, 16].indexOf(@tutorialStep) == -1 and @tutorialStep < text.length - 1
            @tutorialStep += 1
            @showTutorial()
      }]

  resize: (width, height, orientation) ->
    @width = width
    @height = height
    @orientation = orientation
    @resizeGrid()

  resizeGrid: ->
    smallestDimension = if @orientation is 'landscape' then @height else @width
    maxGridBackgroundSize = Math.round(smallestDimension *
                                        @GRID_BACKGROUND_SIZE_RATIO)
    maxGridSize = Math.round(maxGridBackgroundSize * @GRID_SIZE_RATIO / 10) * 10
    remainingSize = maxGridBackgroundSize - maxGridSize
    borderWidth = parseInt(@gridBackground.css('border-width'), 10) * 2
    @cellSize = maxGridSize / 10

    # Hide/show elements
    visibleIndex = Math.pow(@cellCount, 2)
    @grid.children('div').each (i, cell) ->
      $(cell).show() if i < visibleIndex
      $(cell).hide() if i >= visibleIndex

    @$('.horizontal.clue', @gridBackground).each (i, cell) =>
      $(cell).show() if i < @cellCount
      $(cell).hide() if i >= @cellCount

    @$('.vertical.clue', @gridBackground).each (i, cell) =>
      $(cell).show() if i < @cellCount
      $(cell).hide() if i >= @cellCount

    @grid.css
      width: @cellCount * @cellSize
      height: @cellCount * @cellSize

    gridBackgroundSize = @grid.width() + remainingSize
    @gridBackground.width(gridBackgroundSize)
    @gridBackground.height(gridBackgroundSize)

    if @orientation is 'landscape'
      horizontalMargin = (@height - gridBackgroundSize - borderWidth) / 2
      verticalMargin = (maxGridBackgroundSize - gridBackgroundSize) / 2
    else if @orientation is 'portrait'
      verticalMargin = (@width - gridBackgroundSize - borderWidth) / 2
      horizontalMargin = (maxGridBackgroundSize - gridBackgroundSize) / 2

    @gridBackground.css
      margin: "#{horizontalMargin}px #{verticalMargin}px"

    @$('.vertical.clue', @gridBackground).css
      width: @cellSize
      height: remainingSize

    @$('.horizontal.clue', @gridBackground).css
      width: remainingSize
      height: @cellSize

    @$('.minimap', @gridBackground).css
      width: remainingSize
      height: remainingSize

    @grid.children('div').css
      width: @cellSize
      height: @cellSize

    # Resize the icons on the game buttons to ensure correct aspect ratio
    iconWidth = Math.round(@$('.actions.mark').height() * 0.5)
    @$('.actions .icon').css
      width: iconWidth
      height: iconWidth

  # Remove event handlers and hide this view's elem
  hide: (duration = 500, callback) ->
    super duration, callback

    # Do all this stuff after transition offscreen
    _.delay =>
      # Make sure tutorial is hidden
      @tutorial = false

      # Reset timer
      window.clearInterval @timerId
      @seconds = 0
      $('.timer .minutes', @elem).html "00"
      $('.timer .seconds', @elem).html "00"

      # Reset percentage
      $('.complete .percentage', @elem).html "0"

      # Reset grid
      $('.grid div.blank', @elem).removeClass 'marked filled hint'

      # Reset clues
      $('.clue', @elem).removeClass 'highlight complete pinch'

      # Reset buttons
      @action = "mark"
      @actionLock = "none"
      $(".button.fill", @elem).removeClass 'active'
      $(".button.mark", @elem).addClass 'active'

      # Reset game progress
      @hits = 0
      @totalHits = 0
      @misses = 0
    , duration

  # Re-delegate event handlers and show the view's elem
  show: (duration = 500, callback) ->
    super duration, callback

    # Start timer
    @timerId = setInterval @updateTimer, 1000

    # Play some music
    track = if Math.random() < 0.5 then 'bgm-one' else 'bgm-two'
    @trigger 'music:play', track

    if @tutorial is true
      _.delay =>
        @showTutorial()
      , duration
    else
      # Record attempts
      stats = localStorage.getObject 'stats'

      if not stats[@difficulty][@level]
        stats[@difficulty][@level] = { attempts: 1 }
      else
        stats[@difficulty][@level].attempts++

      localStorage.setObject 'stats', stats

    # Grab clues out of data structure
    @clues = levels[@difficulty][@level].clues

    # Generate clues for random levels
    if @difficulty is "random"
      @clues = []
      switch @level
        when 0 then percentage = 0.68
        when 1 then percentage = 0.62
        when 2 then percentage = 0.55

      while @clues.length < 100
        random = if Math.random() < percentage then 1 else 0
        @clues.push random

    @cellCount = Math.sqrt(@clues.length)

    # Load level/parse clues
    for i in [0 ... @cellCount]
      horizontalClue = ''
      verticalClue = ''
      horizontalCounter = 0
      verticalCounter = 0
      previousVertical = false
      previousHorizontal = false

      # Create horizontal clues
      for j in [0 ... @cellCount]
        index = i * @cellCount + j
        if @clues[index] is 1
          horizontalCounter++
          @totalHits++
          previousHorizontal = true
        else if previousHorizontal
          horizontalClue += "#{horizontalCounter} "
          horizontalCounter = 0
          previousHorizontal = false

      # Create vertical clues
      for j in [0 ... @cellCount]
        index = j * @cellCount + i
        if @clues[index] is 1
          verticalCounter++
          previousVertical = true
        else if previousVertical
          verticalClue += "#{verticalCounter}<br>"
          verticalCounter = 0
          previousVertical = false

      # Check for condition when a row or column ends with filled blocks
      if previousHorizontal then horizontalClue += "#{horizontalCounter}"
      if previousVertical then verticalClue += "#{verticalCounter}<br>"

      if horizontalClue == '' then horizontalClue = '0'
      if verticalClue == '' then verticalClue = '0<br>'

      match = verticalClue.match(/<br>/g)
      length = if match? then match.length else 0

      # Determine if there are 5 clues in col, which means the font size needs to be stepped down
      # if length >= 4 then @$('.vertical.clue', @elem).eq(i).addClass 'pinch'

      # Add some manual padding for vertical clues so they are bottom aligned
      if length < 5
        for [length .. 4]
          verticalClue = "<br>#{verticalClue}"

      @$('.horizontal.clue', @elem).eq(i).html(horizontalClue)
      @$('.vertical.clue', @elem).eq(i).html(verticalClue)

      @resizeGrid()

module.exports = GameScene

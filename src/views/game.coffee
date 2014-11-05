###
GameScene
- Contains the main game logic
###
# define [
#   'jquery'
#   'underscore'
#   'backbone'
#   'data/levels'
#   'cs!utilities/env'
#   'cs!utilities/cgrect'
#   'cs!utilities/input'
#   'cs!classes/scene'
#   'cs!classes/dialog-box'
#   'cs!classes/floating-text'
#   'text!templates/game.html'
# ], ($, _, Backbone, levels, env, CGRect, Input, Scene, DialogBox, FloatingText, template) ->

$ = require('jquery')
_ = require('underscore')
Scene = require('../classes/scene')
ENV = require('../utilities/env')
template = require('../templates/game')

class GameScene extends Scene
  events: ->
    # Determine whether touchscreen or desktop
    if ENV.mobile
      events = 
        'touchstart .pause': 'pause'
        'touchstart .mark': 'changeAction'
        'touchstart .fill': 'changeAction'
        'touchstart': 'onActionStart'
        'touchmove': 'onActionMove'
        'touchend': 'onActionEnd'
    else 
      events = 
        'click .pause': 'pause'
        'click .mark': 'changeAction'
        'click .fill': 'changeAction'
        'mousedown': 'onActionStart'
        'mouseup': 'onActionEnd'

  difficulty: "easy"
  level: 0
  
  # Timer junk
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
  lockedRow: -1
  lockedCol: -1
  ignoreInput: false

  # For dealing w/ tutorial
  tutorial: false
  tutorialStep: 0
  hint: null

  initialize: ->
    # Ensure 'this' has correct context
    _.bindAll @, 'render', 'onActionStart', 'onActionMove', 'onActionEnd', 'doAction', 'checkCompleted', 'win', 'pause', 'changeAction', 'updateTimer', 'showTutorial', 'resize', 'hide', 'show'

    # View is initialized hidden
    @elem = $(template())
    @render()

  # Append the view's elem to the DOM
  render: ->
    @$el.append @elem

    # Get some references to DOM elements that we need later
    @grid = @$('.grid')
    @gridBackground = @$('.grid-background')

    # Get size of grid blocks - round to nearest whole number to prevent weirdness w/ decimals
    @blockSize = Math.round @grid.width() / 10

  # Triggered on mousedown or touchstart
  onActionStart: (e) ->
    e.preventDefault()
    if @ignoreInput then return

    # Determine if event was caused by mouse or finger
    if e.type == 'mousedown' then @elem.on 'mousemove', @onActionMove

    position = Input.normalize e

    row = Math.floor((position.y - @grid.offset().top) / @blockSize)
    col = Math.floor((position.x - @grid.offset().left) / @blockSize)

    # Only recognize movement if within grid bounds
    if 0 <= row <= 9 and 0 <= col <= 9
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
    e.preventDefault()
    if @ignoreInput then return
    if @startRow is -1 or @startCol is -1 then return

    # Get user input
    position = Input.normalize e

    # Determine the row/col
    row = Math.floor((position.y - @grid.offset().top) / @blockSize)
    col = Math.floor((position.x - @grid.offset().left) / @blockSize)

    # Only recognize movement if within grid bounds
    if 0 <= row <= 9 and 0 <= col <= 9

      # Enforce locking the user to a particular row/column for touch input
      if @lockedRow == -1 and @lockedCol == -1 and ENV.mobile
        if @previousRow != row
          @lockedCol = col
        else if @previousCol != col
          @lockedRow = row

      if @lockedRow != -1
        row = @lockedRow

      if @lockedCol != -1
        col = @lockedCol

      if row != @previousRow or col != @previousCol
        # Update highlighted clue cells
        verticalClues = @$('.vertical.clue')
        verticalClues.eq(@previousCol).removeClass('highlight')
        verticalClues.eq(col).addClass('highlight')

        horizontalClues = @$('.horizontal.clue')
        horizontalClues.eq(@previousRow).removeClass('highlight')
        horizontalClues.eq(row).addClass('highlight')

        # Try to mark or fill
        @doAction row, col

      # Reset the "previous" values
      @previousRow = row
      @previousCol = col

  # Triggered on mouseup or touchend
  onActionEnd: (e) ->
    e.preventDefault()
    if @ignoreInput then return

    # Determine if event was caused by mouse or finger
    if e.type == 'mouseup' then @elem.off 'mousemove', @onActionMove

    # Hide the clue highlights
    @$('.vertical.clue').eq(@previousCol).removeClass('highlight')
    @$('.horizontal.clue').eq(@previousRow).removeClass('highlight')

    # Unset the "mark lock" -- If user starts marking blocks, only allow marking for the duration of that touch, so that they don't accidentally un-mark a block
    @actionLock = "none"

    # Clear out previous touch data
    @startRow = @startCol = @previousRow = @previousCol = @lockedRow = @lockedCol = -1

  # Try to either mark or fill a grid cell
  doAction: (row, col) ->
    index = row * 10 + col

    # Determine if block is empty, filled, or marked
    block = @grid.find('.blank').eq(index)

    valid = @clues[index] == 1

    if @action is 'fill'
      if block.hasClass('filled') is true
        # Play a "click" noise if block is already filled
        @trigger 'sfx:play', 'invalid'
      else if valid
        # Do a bunch of crap when a successful move is made
        block.addClass 'filled'

        @hits++

        $('.complete .percentage', @elem).html Math.round(@hits / @totalHits * 100)
        
        # Check whether or not to dim clues in a row/col
        @checkCompleted row, col

        # Check if player has won
        if @hits == @totalHits then @win()
        
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
          'text': 'Oops!'
          'el': @elem
          'position':
            'x': block.offset().left
            'y': block.offset().top

        # Instantly call the update method - this method adds 1 second, which is why the previous values are -1 second
        @updateTimer()

        # Try to have some visual indication that you made a wrong move
        @trigger 'vfx:play', 'shake'

    else if @action is 'mark'
      # Mark if block is empty
      if block.hasClass('marked') == false and block.hasClass('filled') == false and @actionLock != "remove"
        block.addClass 'marked'
        @actionLock = "mark"
        @trigger 'sfx:play', 'mark'
      # Remove mark if already marked
      else if block.hasClass('marked') == true and block.hasClass('filled') == false and @actionLock != "mark"
        block.removeClass 'marked'
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

    for i in [0..9]
      rowIndex = row * 10 + i
      columnIndex = i * 10 + col

      if blocks.eq(rowIndex).hasClass('filled') then completedRowTotal++
      if blocks.eq(columnIndex).hasClass('filled') then completedColumnTotal++

      if @clues[rowIndex] is 1 then rowTotal++
      if @clues[columnIndex] is 1 then columnTotal++

    if rowTotal == completedRowTotal then @$('.horizontal.clue', @elem).eq(row).addClass('complete')
    if columnTotal == completedColumnTotal then @$('.vertical.clue', @elem).eq(col).addClass('complete')

  # Actions when player solves the puzzle
  win: () ->
    @ignoreInput = true

    # Ensure this event handler is removed, even if user doesn't "unclick"
    @elem.off 'mousemove', @onActionMove

    # Stop music
    @trigger 'music:stop'

    # Play jingle
    @trigger 'sfx:play', 'win'

    # Stop the timer
    window.clearInterval @timerIdId

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
      el: @elem
      title: 'Puzzle solved!'
      buttons: [
        { 
          text: 'OK'
          callback: => 
            @ignoreInput = false
            if @tutorial
              @trigger 'scene:change', 'title'
            else
              @trigger 'scene:change', 'level', { difficulty: @difficulty }
        }
      ]

  # Go back to the level select screen
  pause: (e) ->
    e?.preventDefault()
    
    # Handle a case when this "pause" method is called when user puts app into background
    if @ignoreInput is true then return

    @ignoreInput = true

    @trigger 'sfx:play', 'button'

    window.clearInterval @timerId

    new DialogBox
      el: @elem
      title: 'Paused'
      buttons: [
        {
          text: 'Resume'
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
              @trigger 'scene:change', 'level', { difficulty: @difficulty }
        }
      ]

  # Change the current user action
  changeAction: (e) ->
    e.preventDefault()
    target = $(e.target)

    @trigger 'sfx:play', 'button'

    # User is probably actually clicking a span inside the button
    if target.is 'span' then target = target.parents '.button'

    # Remove highlight from previous button
    @$(".button.#{@action}", @elem).removeClass 'highlight'

    if target.hasClass 'mark'
      @action = 'mark'
      target.addClass 'highlight'
    else
      @action = 'fill'
      target.addClass 'highlight'
    

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
          # Make sure first column is filled
          stepCompleted = true
          for i in [0..9]
            if blocks.eq(i * 10).hasClass('filled') is false then stepCompleted = false
          success = stepCompleted
        when 5
          # Make sure last row is filled
          stepCompleted = true
          for i in [91..99]
            if blocks.eq(i).hasClass('filled') is false then stepCompleted = false
          success = stepCompleted
        when 8
          # Make sure first row/last column are marked
          stepCompleted = true
          for i in [1..9]
            if blocks.eq(i).hasClass('marked') is false then stepCompleted = false
          for i in [0..8]
            if blocks.eq(i * 10 + 9).hasClass('marked') is false then stepCompleted = false
          success = stepCompleted
        when 10
          stepCompleted = true
          for i in [1..9]
            if blocks.eq(i * 10 + 1).hasClass('filled') is false then stepCompleted = false
          success = stepCompleted

      if success
        @tutorialStep++
        @showTutorial()
            

  showTutorial: ->
    @ignoreInput = true

    # Different text based on input type
    actionWord = if ENV.mobile then "tap" else "click"
    capitalActionWord = if ENV.mobile then "Tap" else "Click"

    text = [
      "Welcome to Nonogram Madness! Nonograms are logic puzzles that reveal an image when solved." # 0
      "Solve each puzzle using the numeric clues on the top and left of the grid." # 1
      "Each number represents squares in the grid that are \"filled\" in a row or column." # 2
      "Clues with multiple numbers represent a gap between filled squares." # 3
      "Look at the first column. The clue is \"10\". #{capitalActionWord} the \"fill\" button then #{actionWord} all 10 squares." # 4
      # Action
      "Check out the last row. Its clue is also \"10\". #{capitalActionWord} all 10 squares in the bottom row." # 5
      # Action
      "Notice that when you complete a row or column, its clues dim slightly, so you know you're done." # 6
      "You can also mark squares that you know are blank, then focus on other areas of the puzzle." #7
      "#{capitalActionWord} the \"mark\" button and mark the row and column that are complete." #8
      # Action
      "You can now logically solve the rest of the rows and columns." #9
      "Column #2 has 9 filled blocks, and the first block is empty. Go ahead and fill this column." #10
      # Action
      "I think you've got the hang of it. Try to finish the rest of the puzzle yourself!" # 11
    ]

    blocks = @grid.find('.blank')

    # Remove previous hints
    blocks.removeClass('hint')

    # Show hint overlays here
    switch @tutorialStep
      when 4
        for i in [0..9]
          blocks.eq(i * 10).addClass 'hint'
      when 5
        for i in [91..99]
          blocks.eq(i).addClass 'hint'
      when 8
        for i in [1..9]
          blocks.eq(i).addClass 'hint'
        for i in [0..8]
          blocks.eq(i * 10 + 9).addClass 'hint'
      when 10
        for i in [1..9]
          blocks.eq(i * 10 + 1).addClass 'hint'

    new DialogBox
      el: @elem
      title: text[@tutorialStep]
      buttons: [{ 
        text: 'OK'
        callback: =>
          @ignoreInput = false

          # These steps indicate where the player has to take action
          if [ 4, 5, 8, 10 ].indexOf(@tutorialStep) == -1 and @tutorialStep < text.length - 1
            @tutorialStep++
            @showTutorial()
      }]

  resize: (width, height, orientation) ->
    borderSize = 10

    # Use Math.floor here to ensure the grid doesn't round up to be larger than width/height of container
    if orientation is 'landscape'
      gridBackgroundWidth = Math.round(height * 0.95)   # Make sure grid background size is 95% of viewport
      @gridBackground.width gridBackgroundWidth
      @gridBackground.height gridBackgroundWidth

      # Add some margin to the grid, so it appears centered
      margin = (height - gridBackgroundWidth - 10) / 2
      @gridBackground.css
        'margin': "#{margin}px 0"

    else if orientation is 'portrait'
      gridBackgroundWidth = Math.round(width * 0.95)  # grid size is 95% of viewport
      @gridBackground.width gridBackgroundWidth
      @gridBackground.height gridBackgroundWidth

      # Add some margin to the grid, so it appears centered
      margin = (width - gridBackgroundWidth - 10) / 2
      @gridBackground.css
        'margin': "0 #{margin}px"

    # Set dimensions of actual grid inside the container
    gridWidth = Math.round(gridBackgroundWidth * 0.75 / 10) * 10  # Make sure grid size is 66% of background, and is a multiple of 10
    @grid.width gridWidth
    @grid.height gridWidth

    @blockSize = gridWidth / 10

    $('.vertical.clue', @gridBackground).css
      "width": gridWidth / 10
      "height": gridBackgroundWidth - gridWidth

    $('.horizontal.clue', @gridBackground).css
      "width": gridBackgroundWidth - gridWidth
      "height": gridWidth / 10

    $('.minimap', @gridBackground).css
      "width": gridBackgroundWidth - gridWidth
      "height": gridBackgroundWidth - gridWidth

    $('.blank', @grid).css
      "width": gridWidth / 10
      "height": gridWidth / 10

    # Resize the icons on the game buttons to ensure correct aspect ratio
    iconWidth = Math.round($('.actions.mark').height() * 0.5)
    $('.actions .icon').width(iconWidth).height(iconWidth)

  # Remove event handlers and hide this view's elem
  hide: (duration = 500, callback) ->
    # Call "super"
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
      $(".button.fill", @elem).removeClass 'highlight'
      $(".button.mark", @elem).addClass 'highlight'

      # Reset game progress
      @hits = 0
      @totalHits = 0
      @misses = 0
    , duration

  # Re-delegate event handlers and show the view's elem
  show: (duration = 500, callback) ->
    # Call "super"
    super duration, callback

    # Start timer
    @timerId = setInterval @updateTimer, 1000

    # Play some music
    track = if Math.random() < 0.5 then 'one' else 'two'
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

    # Handle the random levels
    if @difficulty is "random"
      @clues = []
      switch @level
        when 0 then percentage = 0.68
        when 1 then percentage = 0.62
        when 2 then percentage = 0.55

      while @clues.length < 100
        random = if Math.random() < percentage then 1 else 0
        @clues.push random

    # Handle loading the tutorial
    if @tutorial
      @clues = levels.easy[0].clues

    # Load level/parse clues
    for i in [0..9]
      horizontalClue = ""
      verticalClue = ""
      horizontalCounter = 0
      verticalCounter = 0
      previousVertical = false
      previousHorizontal = false

      # Create horizontal clues
      for j in [0..9]
        index = i * 10 + j
        if @clues[index] is 1
          horizontalCounter++
          @totalHits++
          previousHorizontal = true
        else if previousHorizontal
          horizontalClue += "#{horizontalCounter} "
          horizontalCounter = 0
          previousHorizontal = false

      # Create vertical clues
      for j in [0..9]
        index = j * 10 + i
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

      if horizontalClue == "" then horizontalClue = "0"
      if verticalClue == "" then verticalClue = "0<br>"

      match = verticalClue.match(/<br>/g)
      length = if match? then match.length else 0
      
      # Determine if there are 5 clues in col, which means the font size needs to be stepped down
      if length >= 4 then @$('.vertical.clue', @elem).eq(i).addClass 'pinch'

      # Add some manual padding for vertical clues so they are bottom aligned
      if length < 4
        for [length..3]
          verticalClue = "<br>#{verticalClue}"


      @$('.horizontal.clue', @elem).eq(i).html(horizontalClue)
      @$('.vertical.clue', @elem).eq(i).html(verticalClue)

    # DEBUG - mark the correct answers
    # for clue, index in @clues
    #   if clue is 1 then @$('.grid .blank').eq(index).addClass('marked')

module.exports = GameScene
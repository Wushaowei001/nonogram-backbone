$        = require('../vendor/zepto')
_        = require('underscore')
ENV      = require('../lib/env')
template = require('../templates/user-puzzle-select')
PuzzleSelectScene = require('./puzzle-select')

class UserPuzzleSelectScene extends PuzzleSelectScene
  events: ->
    if ENV.mobile
      'touchend .back': 'back'
      'touchend .previous': 'previous'
      'touchend .next': 'next'
      'touchend .create': 'create'
      'touchend .edit': 'edit'
      'touchend .remove': 'remove'
      'touchend .share': 'share'
      'touchstart canvas': 'select'
    else
      'click .back': 'back'
      'click .previous': 'previous'
      'click .next': 'next'
      'click .create': 'create'
      'click .edit': 'edit'
      'click .play': 'play'
      'click .remove': 'remove'
      'click .share': 'share'
      'click canvas': 'select'

  difficulty: 'user'

  initialize: ->
    @elem = $(template())
    @render()

    @canvases = $('.preview .group:first-child canvas', @elem)
    @altCanvases = $('.preview .group:last-child canvas', @elem)

    @puzzles = { user: localStorage.getObject('userPuzzles') }

  back: ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger('sfx:play', 'button')
    @trigger('scene:change', 'title')

  create: ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger('sfx:play', 'button')
    @trigger('scene:change', 'editor')

  play: ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'game',
      { difficulty: @difficulty, puzzle: @selected, previousScene: 'userPuzzleSelect' }

  edit: ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger('sfx:play', 'button')
    @trigger('scene:change', 'editor', { puzzle: @selected })

  remove: ->
    console.log 'remove'
    # Show "are you sure?" dialog

  share: ->
    console.log 'share'

  showPuzzleInfo: ->
    # Store as "last viewed puzzle"
    lastViewedPuzzle = localStorage.getObject('lastViewedPuzzle')
    lastViewedPuzzle[@difficulty] = @selected
    localStorage.setObject('lastViewedPuzzle', lastViewedPuzzle)

    puzzle = @puzzles[@difficulty][@selected]
    @elem.find('.title').html "##{@selected + 1}: #{puzzle.title}"

  show: (duration = 500, callback) ->
    super duration, callback

    # Reload into memory
    @puzzles = { user: localStorage.getObject('userPuzzles') }

module.exports = UserPuzzleSelectScene

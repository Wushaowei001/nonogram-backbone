$        = require('../vendor/zepto')
_        = require('underscore')
ENV      = require('../lib/env')
template = require('../templates/user-puzzle-select')
puzzles  = { user: localStorage.getObject('userPuzzles') || [] }

class UserPuzzleSelectScene extends PuzzleSelectScene
  events: ->
    if ENV.mobile
      'touchend .back': 'back'
      'touchend .previous': 'previous'
      'touchend .next': 'next'
      'touchend .edit': 'edit'
      'touchend .delete': 'delete'
      'touchend .share': 'share'
      'touchstart canvas': 'select'
    else
      'click .back': 'back'
      'click .previous': 'previous'
      'click .next': 'next'
      'click .edit': 'edit'
      'click .remove': 'remove'
      'click .remove': 'remove'
      'click .share': 'share'
      'click canvas': 'select'

  difficulty: 'user'

  play: ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger 'sfx:play', 'button'
    @trigger 'scene:change', 'game',
      { difficulty: @difficulty, puzzle: @selected }

  back: ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger('sfx:play', 'button')
    @trigger('scene:change', 'title')

  edit: ->
    @undelegateEvents() # Prevent multiple clicks

    @trigger('sfx:play', 'button')
    @trigger 'scene:change', 'editor',
      { difficulty: @difficulty, puzzle: @selected }

  remove: ->
    console.log 'remove'
    # Show "are you sure?" dialog

  share: ->
    console.log 'share'

  showPuzzleInfo: ->
    data = puzzles[@difficulty][@selected]

    # Store as "last viewed puzzle"
    lastViewedPuzzle = localStorage.getObject('lastViewedPuzzle')
    lastViewedPuzzle[@difficulty] = @selected
    localStorage.setObject('lastViewedPuzzle', lastViewedPuzzle)

module.exports = UserPuzzleSelectScene

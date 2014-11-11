$ = require('./vendor/zepto')
_ = require('underscore')
Backbone = require('backbone')
Backbone.$ = $
Sona = require('sona')
TitleScene = require('./views/title')
GameScene = require('./views/game')
AboutScene = require('./views/about')
LevelSelectScene = require('./views/level-select')
DifficultySelectScene = require('./views/difficulty-select')
ENV = require('./utilities/env')

# Extend local storage
Storage.prototype.setObject = (key, value) ->
  @setItem key, JSON.stringify value

Storage.prototype.getObject = (key) ->
  value = @getItem key
  return value and JSON.parse value

Storage.prototype.getBoolean = (key) ->
  value = @getItem(key)
  value == "true"

# Extend Backbone
Backbone.View.prototype.close = ->
  @elem.remove()
  @undelegateEvents()

  if typeof @onClose == "function"
    @onClose()

# Define app obj
class App extends Backbone.View
  el: null
  activeScene: null

  initialize: ->
    # Ensure 'this' context is always correct
    _.bindAll @, 'playSfx', 'playMusic', 'stopMusic', 'playVfx', 'changeScene', 'resize', 'initializeDefaults'

    # Ensure that user data is initialized to defaults
    @initializeDefaults()

    # Create all game views here
    @el = $('#nonograms')
    @scenes =
      title: new TitleScene { el: @el }
      game: new GameScene { el: @el }
      about: new AboutScene { el: @el }
      levelSelect: new LevelSelectScene { el: @el }
      difficultySelect: new DifficultySelectScene { el: @el }

    # Differentiate between views that have platform-specific IAP code
    # if ENV.cordova and ENV.android
    #   @difficultyScene = new DifficultySelectAndroidScene { el: @el }
    # else if ENV.cordova and ENV.ios
    #   @difficultyScene = new DifficultySelectIOSScene { el: @el }
    # else

    # Bind various handlers on each view, and initially hide
    for name, scene of @scenes
      scene.on 'scene:change', @changeScene
      scene.on 'sfx:play', @playSfx
      scene.on 'music:play', @playMusic
      scene.on 'music:stop', @stopMusic
      scene.on 'vfx:play', @playVfx
      scene.hide 0

    # Set active scene
    @activeScene = @scenes.levelSelect

    # Add an additional class to game container if "installed" on iOS homescreen - currently unused
    if window.navigator.standalone then @el.addClass 'standalone'

    # This handles desktop resize events as well as orientation changes
    $(window).on 'resize', @resize

    # Prevent content from dragging around
    if ENV.mobile
      $('body').on 'touchmove', (e) ->
        e.preventDefault()
      $('body').on 'gesturestart', (e) ->
        e.preventDefault()
      $('body').on 'gesturechange', (e) ->
        e.preventDefault()
      $('body').on 'gestureend', (e) ->
        e.preventDefault()

    # Handle being moved to the background in Cordova builds
    if ENV.cordova
      document.addEventListener "pause", =>
        if typeof @activeScene.pause is "function" then @activeScene.pause()
        @stopMusic()
        @pausedMusic = @currentMusic
      , false

      # Handle resuming from background
      document.addEventListener "resume", =>
        @playMusic @pausedMusic
      , false

    @sona = new Sona([
        { url: 'assets/sounds/button.mp3', id: 'button' }
        { url: 'assets/sounds/error.mp3', id: 'error' }
        { url: 'assets/sounds/invalid.mp3', id: 'invalid' }
        { url: 'assets/sounds/fill.mp3', id: 'fill' }
        { url: 'assets/sounds/mark.mp3', id: 'mark' }
        { url: 'assets/sounds/win.mp3', id: 'win' }
        { url: 'assets/music/1.mp3', id: 'bgm-one' }
        { url: 'assets/music/2.mp3', id: 'bgm-two' }
        { url: 'assets/music/tutorial.mp3', id: 'bgm-tutorial' }
    ])

    @sona.load =>
      @resize() # Do an initial resize of the content area to ensure a 2:3 ratio
      navigator.splashscreen.hide() if ENV.cordova # Manually remove the Cordova splash screen; prevent a white flash while UIWebView is initialized
      @activeScene.show()

  # Callback to play a sound effect
  playSfx: (id) ->
    return unless localStorage.getBoolean('playSfx')

    @sona.play(id)

  # Callback to play music
  playMusic: (id) ->
    return unless localStorage.getBoolean('playMusic')

    # Do nothing if the same track is currently being played
    return if @currentMusic == id
    
    # Play the same track that was previously playing if no arg is passed
    if not id and @currentMusic then id = @currentMusic

    @sona.stop(@currentMusic) if @currentMusic
    
    @sona.loop(id)
    @currentMusic = id

  # Stop music!
  stopMusic: ->
    return if not @currentMusic

    @sona.stop(@currentMusic)

    @currentMusic = null

  # Does some sort of visual effect on the whole screen (flash, shake, etc.)
  playVfx: (type) ->
    @el.addClass type
    _.delay =>
      @el.removeClass type
    , 250

  # Handle hiding/showing the active scene
  changeScene: (scene, options) ->
    @activeScene.hide()

    switch scene
      when 'title' then @activeScene = @scenes.title
      when 'about' then @activeScene = @scenes.about
      when 'difficulty' then @activeScene = @scenes.difficultySelect
      when 'level' 
        @levelScene.difficulty = options.difficulty
        @activeScene = @scenes.levelSelect
      when 'game' 
        # Set the game's diff & level props from the passed "options" arg
        @gameScene.difficulty = options.difficulty
        @gameScene.level = options.level
        @gameScene.tutorial = options.tutorial
        @activeScene = @scenes.game
      else
        console.log "Error! Scene not defined in switch statement" 
        @activeScene = @titleScene

    @activeScene.show()

  resize: ->
    # Attempt to force a 2:3 aspect ratio, so that the percentage-based CSS layout is consistant
    width = @el.width()
    height = @el.height()

    # This obj will be used to store how much padding is needed for each scene's container
    padding = 
      width: 0
      height: 0

    if width > height
      @el.removeClass('portrait').addClass('landscape')
      orientation = 'landscape'
    else 
      @el.removeClass('landscape').addClass('portrait')
      orientation = 'portrait'

    # Landscape
    # example, 1280 x 800 - correct 2:3 ratio is 1200 x 800
    # example, 1024 x 768 - correct 2:3 ratio is 1024 x 682

    # Aspect ratio to enforce
    ratio = 3 / 2

    # Tweet: Started writing some commented-out psuedocode, but it turned out to be CoffeeScript, so I uncommented it.
    if orientation is 'landscape'
      if width / ratio > height     # Too wide; add padding to width
        newWidth = height * ratio
        padding.width = width - newWidth
        width = newWidth
      else if width / ratio < height  # Too high; add padding to height
        newHeight = width / ratio
        padding.height = height - newHeight
        height = newHeight
      $('body').css { 'font-size': "#{width * 0.1302}%" }   # Dynamically update the font size - 0.1302% font size per pixel in width

    else if orientation is 'portrait'
      if height / ratio > width     # Too high; add padding to height
        newHeight = width * ratio
        padding.height = height - newHeight
        height = newHeight
      else if height / ratio < width  # Too wide, add padding to width
        newWidth = height / ratio
        padding.width = width - newWidth
        width = newWidth
      $('body').css { 'font-size': "#{height * 0.1302}%" }  # Dynamically update the font size - 0.1302% font size per pixel in height

    # Add the calculated padding to each scene <div>
    @el.find('.scene .container').css
      width: width
      height: height
      padding: "#{padding.height / 2}px #{padding.width / 2}px"

    # Call a "resize" method on other views that have elements that need to have their position manually calculated
    for name, scene of @scenes
      scene.resize(width, height, orientation) if typeof scene.resize == 'function'

  # Make sure that any data stored in localStorage is initialized to a default (read: expected) value
  initializeDefaults: ->
    # Obj that stores # of tries, best time, etc.
    if localStorage.getObject('stats') == null
      stats = 
        easy: {}
        medium: {}
        hard: {}
        random: {}
      localStorage.setObject 'stats', stats

    # Obj that stores # of completed levels per difficulty
    if localStorage.getObject('complete') == null
      complete = 
        easy: 0
        medium: 0
        hard: 0
        random: 0
      localStorage.setObject 'complete', complete

    # Obj that stores the most recently viewed level in a difficulty
    if localStorage.getObject('lastViewedLevel') == null
      lastViewedLevel = 
        easy: 0
        medium: 0
        hard: 0
        random: 0
      localStorage.setObject 'lastViewedLevel', lastViewedLevel

    # Array that contains purchased IAP product IDs
    if localStorage.getObject('purchased') == null
      localStorage.setObject 'purchased', []

    # Whether to play music/SFX
    if localStorage.getItem('playMusic') == null
      localStorage.setItem 'playMusic', "true"

    if localStorage.getItem('playSfx') == null
      localStorage.setItem 'playSfx', "true"

# Wait until "deviceready" event is fired, if necessary (Cordova only)
if ENV.cordova
  document.addEventListener "deviceready", ->
    window.app = new App
  , false
else
  $ ->
    window.app = new App

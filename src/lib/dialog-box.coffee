### USAGE
new DialogBox
  title: 'string'
  message: 'string'
  buttons: [
    {
      text: 'OK'
      callback: ->
        console.log 'u cliked me bro'
    }
  ]
###

$        = require('../vendor/zepto')
_        = require('underscore')
Backbone = require('backbone')
ENV      = require('../lib/env')

class DialogBox extends Backbone.View
  animationTime: 300
  callbackCompleted: false

  # Dynamically size buttons in this modal; can't use percentages since the
  # height of the containing <div> changes based on length of content
  BUTTON_SIZE:
    landscape:
      width: 0.2
      height: 0.13
    portrait:
      width: 0.3
      height: 0.07

  events: ->
    if ENV.mobile
      'touchend .button': 'onAction'
    else
      'click .button': 'onAction'

  initialize: (options) ->
    @options = options

    if @options.animationTime? then @animationTime = @options.animationTime

    _.bindAll(@, 'resize')
    $(window).on('resize', @resize)

    # Create HTML contents here
    html = ''

    html += "<h3>#{@options.title}</h3>" if @options.title

    html += "<p>#{@options.message}</p>" if @options.message

    # Allow injection of raw HTML
    html += @options.html if @options.html

    for button in @options.buttons
      html += """
      <div class="button" data-action="#{button.text.toLowerCase()}">
        <div class="bevel">
          <span class="text">#{button.text}</span>
        </div>
      </div>"""

    template = """
          <div class="dialog-box">
            #{html}
          </div>"""

    @overlay = $('<div class="overlay"></div>')

    @elem = $(template)
    @render()

  render: ->
    @$el.append(@elem)
    @elem.after(@overlay)

    @resizeButtons()

    # Dynamically position dialog box
    @elem.css
      left: (@$el.width() - @elem.width()) / 2
      top: -@elem.height()

    # animate box & overlay into place
    @elem.animate
      translateY: ((@$el.height() + @elem.height()) / 2) + 'px'
      opacity: 1
    , @animationTime
    @overlay.animate
      opacity: 0.7
    , @animationTime

  # Determine which button was clicked, call the appropriate callback,
  # and close the dialog box view
  onAction: (e) ->
    e.preventDefault()

    # Allow button to only be clicked once
    return if @callbackCompleted is true
    @callbackCompleted = true

    button = $(e.target)
    button = button.parents('.button') unless button.data('action')
    buttonAction = button.data('action')

    # window.sounds['button']?.play()

    # Look for clicked callback
    for button in @options.buttons
      if button.text.toLowerCase() is buttonAction and typeof button.callback is 'function'
        _.delay(button.callback, @animationTime)

    # animate box & overlay into place
    @elem.animate
      translateY: "-#{@elem.height()}px"
      opacity: 0
    , @animationTime

    @overlay.animate
      opacity: 0
    , @animationTime

    # Remove all this nonsense
    _.delay =>
      @overlay.remove()
      @close()
    , @animationTime

  # Remove the resize event listener
  onClose: ->
    $(window).off 'resize', @resize

  resizeButtons: ->
    parentWidth = @$el.width()
    parentHeight = @$el.height()

    orientation = if parentWidth > parentHeight
      'landscape'
    else
      'portrait'

    @elem.find('.button').css
      width: @BUTTON_SIZE[orientation].width * parentWidth
      height: @BUTTON_SIZE[orientation].height * parentHeight

  # Update position of dialog box when orientation changes
  resize: (e) ->
    @elem.css
      left: (@$el.width() - @elem.width()) / 2

    # animate box into new position
    @elem.animate
      translateY: ((@$el.height() + @elem.height()) / 2) + 'px'
    , @animationTime

    @resizeButtons()

module.exports = DialogBox

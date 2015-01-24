###
pass args object like this
{
  title: "string"
  message: "string"
  buttons: [
    {
      text: 'OK'
      callback: ->
        dostuf()
    }
  ]
}
###

$ = require('../vendor/zepto')
_ = require('underscore')
Backbone = require('backbone')
ENV = require('../utilities/env')

class DialogBox extends Backbone.View
  animationTime: 300
  doCallback: true

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
    @$el.append @elem
    @elem.after @overlay

    # Dynamically position dialog box
    @elem.css
      left: (@$el.width() - @elem.width()) / 2
      top: -@elem.height()
      height: "#{@elem.height()}px"

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
    return if @doCallback is false
    @doCallback = false

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
      translateY: -@elem.height() + 'px'
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

  # Update position of dialog box when orientation changes
  resize: (e) ->
    @elem.css
      left: (@$el.width() - @elem.width()) / 2

    # animate box into new position
    @elem.animate
      translateY: ((@$el.height() + @elem.height()) / 2) + 'px'
    , @animationTime

module.exports = DialogBox

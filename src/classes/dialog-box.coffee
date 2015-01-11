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
      events =
        'touchend .button': 'onAction'
    else
      events =
        'click .button': 'onAction'

  initialize: (options) ->
    @options = options

    if @options.animationTime? then @animationTime = @options.animationTime

    _.bindAll(@, 'resize')
    $(window).on('resize', @resize)

    # Create HTML contents here
    html = ''

    if @options.title
      html += "<h3>#{@options.title}</h3>"

    if @options.message
      html += "<p>#{@options.message}</p>"

    # Allow injection of raw HTML
    if @options.html
      html += @options.html

    for button in @options.buttons
      html += """
      <div class="button" data-action="#{button.text.toLowerCase()}">
        <span data-action="#{button.text.toLowerCase()}">#{button.text}</span>
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
    if !@doCallback then return
    @doCallback = false

    buttonAction = $(e.target).attr 'data-action'

    # window.sounds['button']?.play()

    # Search through the buttons array, looking for the callback associated w/ the clicked button
    for button in @options.buttons
      if button.text.toLowerCase() is buttonAction and typeof button.callback is "function"
        _.delay button.callback, @animationTime

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

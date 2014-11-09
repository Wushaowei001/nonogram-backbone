$ = require('../vendor/zepto')
_ = require('underscore')

class FloatingText
  constructor: (options) ->
    options = _.defaults options,
      text: 'Message!'
      speed: 1000
      el: $('body')
      position:
        x: 0
        y: 0

    html = """
        <div class="floating-text">
          #{options.text}
        </div>
        """

    @elem = $(html)

    # Add element to DOM
    options.el.append @elem

    # Dynamically position text
    @elem.css
      left: options.position.x - @elem.width() / 2
      top: options.position.y - @elem.height() / 2

    # Animate text off screen, remove when done
    @elem.animate 
      'translateY': (-@elem.height() / 4) + 'px'
      'opacity': 0
    , options.speed, 'ease-in-out', =>
      @elem.remove()

module.exports = FloatingText

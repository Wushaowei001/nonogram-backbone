###
DifficultySelectScene
	- Lets user choose difficulty of levels
###
define [
	'jquery'
	'backbone'
	'cs!utilities/env'
	'cs!classes/scene'
	'cs!classes/dialog-box'
	'text!templates/difficulty-select.html'
], ($, Backbone, env, Scene, DialogBox, template) ->
	class DifficultySelectScene extends Scene
		events: ->
			# Determine whether touchscreen or desktop
			if env.mobile
				events =
					'touchstart .back': 'back' 
					'touchstart .easy': 'select'
					'touchstart .medium': 'select'
					'touchstart .hard': 'select'
					'touchstart .random': 'select'
			else
				events =
					'click .back': 'back'
					'click .easy': 'select'
					'click .medium': 'select'
					'click .hard': 'select'
					'click .random': 'select'

		initialize: ->
			@elem = $(template)
			
			# Hide IAP nonsense
			$('.restore', @elem).hide()

			@render()

		# Difficulty choice
		select: (e) ->
			e.preventDefault()
			button = $(e.target)

			# Prevent multiple clicks
			@undelegateEvents()

			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'level', { difficulty: button.data 'difficulty' }

		# Go back to title
		back: (e) ->
			e.preventDefault()

			# Prevent multiple clicks
			@undelegateEvents()

			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'title'

		# Re-delegate event handlers and show the view's elem
		show: (duration = 500, callback) ->
			@trigger 'music:play', 'tutorial'

			# Call "super"
			super duration, callback
###
DifficultySelectAndroidScene
	- Lets user choose difficulty of levels
	- Android-specific code for IAP pushed in here
###
define [
	'jquery'
	'underscore'
	'backbone'
	'cs!utilities/env'
	'cs!classes/scene'
	'cs!classes/dialog-box'
	'text!templates/difficulty-select.html'
], ($, _, Backbone, env, Scene, DialogBox, template) ->
	class DifficultySelectAndroidScene extends Scene
		events:
			'touchstart .back': 'back' 
			'touchstart .restore': 'restore'
			'touchstart .easy': 'select'
			'touchstart .medium': 'select'
			'touchstart .hard': 'select'
			'touchstart .random': 'select'

		initialize: ->
			@elem = $(template)

			if window.inappbilling?
				# Init plugin
				window.inappbilling.init()

				# Callbacks for IAP
				@callbacks = {}

				@callbacks.purchased = (productId) =>
					console.log productId

					# Store the product ID the player just bought
					purchased = localStorage.getObject 'purchased'
					purchased.push productId
					localStorage.setObject 'purchased', purchased

					# Update the link so they can play those levels
					$('.medium span, .hard span, .random span', @elem).data 'purchased', 'yes'
					$('.restore', @elem).hide()

					# Show a "success" message
					new DialogBox
						el: @elem
						title: 'Your purchase was successful!'
						buttons: [{ text: 'OK' }]

				@callbacks.restored = (productId) =>
					if productId
						$('.medium span, .hard span, .random span', @elem).data 'purchased', 'yes'
						$('.restore', @elem).hide()

						# Store the product ID the player just bought
						purchased = localStorage.getObject 'purchased'
						purchased.push productId
						localStorage.setObject 'purchased', purchased

						message = 'Level packs restored!'
					else
						message = 'No purchases found.'

					# Show a message
					new DialogBox
						el: @elem
						title: message
						buttons: [{ text: 'OK' }]

				@callbacks.failed = =>
					# Show some sort of error message
					new DialogBox
						el: @elem
						title: "Sorry, there was some sort of problem."
						buttons: [{ text: 'OK' }]

				# Allow users to access IAP, otherwise hide the "restore" button because this isn't the IAP version
				@updatePurchaseStatus()
				
			else
				# No IAP plugin, allow player to play all levels
				$('.medium span, .hard span, .random span', @elem).data 'purchased', 'yes'
				$('.restore', @elem).hide()

			@render()

		# Re-enable buttons for IAP-enabled versions of the app
		updatePurchaseStatus: ->
			# If IAP version, get previously purchased level paks
			purchased = localStorage.getObject 'purchased'

			if purchased.length is 0
				$('.medium span, .hard span, .random span', @elem).data 'purchased', 'no'
			else
				$('.restore', @elem).hide()

		# Restore past purchases
		restore: (e) ->
			e.preventDefault()

			@trigger 'sfx:play', 'button'

			window.inappbilling.getOwnItems @callbacks.restored, @callbacks.failed
				
		# Difficulty choice
		select: (e) ->
			e.preventDefault()

			@trigger 'sfx:play', 'button'

			button = $(e.target)

			if button.data('purchased') is 'yes'
				# Prevent multiple clicks
				@undelegateEvents()
				@trigger 'scene:change', 'level', { difficulty: button.data 'difficulty' }
			else
				new DialogBox
					el: @elem
					title: 'Unlock medium, hard, and random puzzles?'
					buttons: [
						{ 
							text: 'Yes'
							callback: => 
								@buy()
						},
						{
							text: 'No'
						}
					]
		
		# Buy the product!
		buy: (e) ->
			@trigger 'sfx:play', 'button'

			productId = "com.ganbarugames.nonogramjs.levelpak"

			# DEBUG
			# productId = 'android.test.purchased'

			# Prompt user to buy
			window.inappbilling.purchase @callbacks.purchased, @callbacks.failed, productId

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

			# Call prototype
			super duration, callback
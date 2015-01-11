# Now
[ ] Break SFX/Music code out into a "sound controller" singleton/object
[ ] Break scene transition out into a "scene controller" singleton/object
[ ] Change scene transition to be code based - allow for an extra parameter, "forward" or "back", which dictates the direction the transition occurs
[X] Make puzzle grid closer to 100% width
[ ] Add config file to specify path to assets, etc.
[X] Add CSS compression
[X] Add sourcemaps
[ ] Add support for levels smaller than 10x10
[X] Animate level previews on/off screen
[X] Make @canvases have high z-index when shown on level select scene
[ ] Create some "beginner" difficulty levels
[ ] Make disabled button not have an "active" state - i.e. nothing happens when you click it,
    but it still looks like it gets pressed
[X] In level select stage, create an "enableOrDisableButtons" method, so can disable
    buttons while page flip animation is working, then re-enable each button easily
[ ] Don't allow "fill" attempts on blocks that have been marked :/
[ ] Give grid cells a size based on overall view width, not CSS, so container can shrink
	and grid cells can remain the same size
[ ] Level editor

# Future

[ ] "Share" feature -- append base64 encoded level data at end of URL, point to ganbarugames.com
[ ] Add router to allow players to directly access a puzzle

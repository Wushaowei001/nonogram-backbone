# Now
[X] Give grid cells a size based on overall view width, not CSS, so container can shrink
	and grid cells can remain the same size
[X] Level editor
[X] Make puzzle grid closer to 100% width
[X] Add CSS compression
[X] Add sourcemaps
[X] Add support for levels smaller than 10x10
[X] Animate level previews on/off screen
[X] Make @canvases have high z-index when shown on level select scene
[X] In level select stage, create an "enableOrDisableButtons" method, so can disable
    buttons while page flip animation is working, then re-enable each button easily
[X] Create some "beginner" difficulty levels
[ ] Break SFX/Music code out into a "sound controller" singleton/object
[ ] Break scene transition out into a "scene controller" singleton/object
[ ] Change scene transition to be code based - allow for an extra parameter, "forward" or "back", which dictates the direction the transition occurs
[ ] Add config file to specify path to assets, etc.
[x] Make disabled button not have an "active" state - i.e. nothing happens when you click it,
    but it still looks like it gets pressed

# Future

[ ] "Share" feature -- append base64 encoded level data at end of URL, point to ganbarugames.com
[ ] Add router to allow players to directly access a shared puzzle
[ ] Investigate app cache to allow offline access
[ ] Add thumbnail and level name for post-win modal
[ ] Re-work landscape layout

# Roadmap for v1 App Store release
[ ] Verify layout correctness on iPhone 5
  [ ] Button borders are too thick (create < 320px media query?)
  [ ] Puzzle grid is offset too far to the left
  [ ] Button line height is too high (switch to percentage-based?)
[ ] Hide editor button on homepage
[ ] Add sound effect to modal buttons
[x] Don't allow "fill" attempts on blocks that have been marked :/
[ ] Change to 30min limit which counts down
[ ] Review each puzzle to ensure no cheap "guesswork" puzzles
  [ ] Beginner
  [ ] Easy
  [ ] Medium
  [ ] Hard
[ ] Redistribute puzzles across difficulties to balance numbers out
[ ] Get Cordova build running
  [ ] Create iOS project
  [ ] Create gulp task to copy built files over
[ ] Create Acorn file for 1024x1024 app icon
[ ] Write JS interface for IAP plugin
[ ] Create demo video
[ ] Screenshots for various iOS devices
  [ ] iPhone 4S
  [ ] iPhone 5
  [ ] iPhone 6
  [ ] iPhone 6+
  [ ] iPad
  [ ] iPad 2x

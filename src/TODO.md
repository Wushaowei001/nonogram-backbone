# Now
[x] Break SFX/Music code out into a "sound controller" singleton/object
[x] Change level select highlight tween to be code-based to allow it to be disabled
    when pages are flipped
[x] Add landscape layout for About page
[x] Make modal buttons same height as normal buttons
[x] Add underscore template for modal box
[x] Ensure thumbnail previews are offscreen after an orientation change
[x] Ensure "mark" & "fill" button handlers correctly keep the button pressed
[x] Make width/spacing for pause button and info windows consistant
[x] Make text in pause button vertical
[x] Allow "bump" animation when marking to happen cross-level
[x] Save currently selected level across game sessions
[ ] Fix tutorial
[x] Re-work "game.html" landscape layout
[x] Add preview for completed "random-"difficulty levels

# Future

[ ] "Share" feature -- append base64 encoded level data at end of URL, point to ganbarugames.com
[ ] Add router to allow players to directly access puzzles
[ ] Investigate app cache to allow offline access
[ ] Add "% complete" to difficulty select
[ ] Add thumbnail to post-win modal
[x] Add level name to post-win modal
[ ] Change scene transition to be code based - allow for an extra parameter, "forward" or "back", which dictates the direction the transition occurs

# Roadmap for v1 App Store release
[x] Verify layout correctness on iPhone 5
  [X] Button borders are too thick (create < 320px media query?)
  [x] Puzzle grid is offset too far to the left
  [X] Button line height is too high (switch to percentage-based?)
[ ] Check layout on all versions of iPhone/iPad hardware
[x] Hide editor button on homepage
[x] Add sound effect to modal buttons
[X] Don't allow "fill" attempts on blocks that have been marked :/
[X] Change to 30min limit which counts down
[ ] Review each puzzle to ensure no cheap "guesswork" puzzles
  [x] Beginner
  [ ] Easy
  [ ] Medium
  [ ] Hard
[ ] Create some more beginner level puzzles - take some of the cheap ones
    and re-work them w/ a smaller grid
[ ] Redistribute puzzles across difficulties to balance numbers out
[ ] Add an app store rating "feedback" button
[x] Get Cordova build running
  [x] Create iOS project
  [x] Create gulp task to copy built files over
[x] Create Acorn file for 1024x1024 app icon
[ ] Create test IAP users
[ ] Write JS interface for IAP plugin
[ ] Create demo video
[ ] Screenshots for various iOS devices
  [ ] iPhone 4S
  [ ] iPhone 5
  [ ] iPhone 6
  [ ] iPhone 6+
  [ ] iPad
  [ ] iPad 2x

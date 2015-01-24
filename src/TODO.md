# Now
[ ] Break SFX/Music code out into a "sound controller" singleton/object
[ ] Change level select highlight tween to be code-based to allow it to be disabled
    when pages are flipped
[ ] Fix tutorial
[ ] Re-work landscape layout
[x] Add landscape layout for About page
[ ] Add underscore template for modal box

# Future

[ ] "Share" feature -- append base64 encoded level data at end of URL, point to ganbarugames.com
[ ] Add router to allow players to directly access a shared puzzle
[ ] Investigate app cache to allow offline access
[ ] Add thumbnail and level name for post-win modal
[ ] Break scene transition out into a "scene controller" singleton/object
[ ] Change scene transition to be code based - allow for an extra parameter, "forward" or "back", which dictates the direction the transition occurs

# Roadmap for v1 App Store release
[ ] Verify layout correctness on iPhone 5
  [ ] Button borders are too thick (create < 320px media query?)
  [x] Puzzle grid is offset too far to the left
  [X] Button line height is too high (switch to percentage-based?)
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

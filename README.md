# Snacks (working name)

A menu-bar app that offers a one-to-three-minute exercise snack after about 30 minutes at the Mac.
It replaces Stretch Reminder (2025); the old Xcode project is in the git history.

- **When**: after 30 minutes of use it waits for a pause (4 s with no typing or mouse). Never while
  the microphone is in use (a call) or the front app fills the screen. Five minutes away from the
  Mac counts as a break and starts the count again; sleep doesn't count as use.
- **Not now**: never in the five minutes before or during a calendar event, while a Focus is on,
  in quiet hours (7pm to 7am) or after 10 cards in a day. Change those with
  `defaults write com.simonwisdom.snacks quietFrom -int 19` (also `quietUntil`, `dailyCap`).
- **Good moments**: the end of a meeting is a natural break, so a snack due within 10 minutes shows
  then. Coming back from 20 minutes or more away between 11:30 and 3pm counts as lunch: a brisk walk
  follows after 10 minutes of use, since moving soon after a meal does the most good.
- **Mix**: snacks run one to three minutes. Every third one in a day gets you out of breath
  (stairs, fast march, star jumps), the rest are strength and mobility.
- **Asks first**: a small dark card at the top centre, just under the menu bar, says "A short pause"
  with the move and its length, then **+5**, **+15** and **Begin**. It floats over other windows
  without taking keyboard focus. **+5** or **+15** puts the snack off by that many minutes of use.
- **Then fills the screen**: **Begin** opens the snack full screen, over everything, in a calm look
  after Endel's: deep night blue, faint rings that breathe slowly, a thin looping figure, what to do,
  a fine ring that fills as time runs and the time left. It closes itself when time's up ("done. back to it.")
  and hands focus back to the app you were in. **another move** (→), **not for me** (turns that move
  off) and **stop** (esc) sit at the bottom. Both are left out of screen shares and recordings.
  With Reduce Motion on, the rings and the figure hold still. Buttons have VoiceOver labels.
- **Menu**: time left, Snack now, Pause for an hour, Edit moves…, Turn moves back on (when some are
  off), Share this week… (one sentence on the last seven days, to send to someone), Open at login, Quit.
- **Moves**: `~/Library/Application Support/Snacks/moves.md`, written from the seed on first run:
  `# Title` entries split by `---`, with `seconds:`, `kind:` (`vigorous` or `walk`) and `figure:`
  lines (squat, calf, wallpush, march, lunge, jacks, armcircle, reach, twist, neck, chest).
  Moves turned off are listed in `off.txt` beside it.
- **Log**: `log.jsonl` beside it records each card shown, started, done, stopped, later or swapped.

## Build and check

- `bin/build` makes `build/Snacks.app` (ad-hoc signed). To install: copy it to /Applications and
  open it once with `--open-at-login`. It asks for Calendar and Focus access on first launch.
- `swift test` runs the timing and moves-file tests.
- `Snacks --snapshot out.png` draws the cards and every figure (buttons show as yellow blocks there:
  the renderer can't draw native controls).
- `Snacks --demo` shows the small card at launch, `--demo-full` the full-screen snack; both visible to screenshots.

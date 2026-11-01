# Snacks

A macOS menu-bar app that offers a one-to-three-minute exercise snack after about 30 minutes at the Mac.

![A snack in progress: arm circles, with a countdown ring and the time left](docs/snack.png)

## How it works

- **When**: after 30 minutes of use it waits for a pause (4 seconds with no typing or mouse). Never while
  the microphone is in use (a call) or the front app is full screen. Five minutes away from the Mac counts
  as a break and starts the count again; sleep doesn't count as use.
- **Not now**: never in the five minutes before or during a calendar event, while a Focus is on, in quiet
  hours (7pm to 7am) or after 10 cards in a day.
- **Good moments**: the end of a meeting is a natural break, so a snack due within 10 minutes shows then.
  Coming back from 20 minutes or more away between 11:30 and 3pm counts as lunch: a brisk walk follows
  after 10 minutes of use.
- **Mix**: every third snack in a day gets you out of breath (stairs, fast march, star jumps); the rest are
  strength and mobility.
- **Asks first**: a small dark card under the menu bar says "A short pause" with the move and its length,
  then **+5**, **+15** and **Begin**. It floats over other windows without taking keyboard focus. **+5** or
  **+15** puts the snack off by that many minutes of use.
- **Then fills the screen**: **Begin** opens the snack full screen: slowly breathing rings, a looping
  figure, what to do, a ring that fills as time runs and the time left. It closes itself when time's up
  and hands focus back to the app you were in. **another move** (→), **not for me** (turns that move off)
  and **stop** (esc) sit at the bottom. Both windows are left out of screen shares and recordings.
- **Accessibility**: with Reduce Motion on, the rings and the figure hold still. Buttons have VoiceOver
  labels and keyboard shortcuts.
- **Menu**: time left, Snack now, Pause for an hour, Edit moves…, Turn moves back on, Share this week…
  (one sentence on the last seven days), Open at login, Quit.

## Install

Needs macOS 13 or later and Xcode (or the Swift command-line tools).

```sh
git clone https://github.com/simonwisdom/snacks.git
cd snacks
bin/build
cp -R build/Snacks.app /Applications/
open /Applications/Snacks.app --args --open-at-login
```

`bin/build` makes an ad-hoc signed `build/Snacks.app`. On first launch it asks for Calendar and Focus
access; both are optional.

## Settings

Quiet hours and the daily cap have no menu of their own:

```sh
defaults write com.simonwisdom.snacks quietFrom -int 19   # hour quiet hours start
defaults write com.simonwisdom.snacks quietUntil -int 7   # hour they end
defaults write com.simonwisdom.snacks dailyCap -int 10    # most cards in a day
```

## Your own moves

Moves live in `~/Library/Application Support/Snacks/moves.md`, written on first run. **Edit moves…** in the
menu opens it. Each move is a `# Title`, a few settings lines and what to do, split by `---`:

```markdown
# squats
seconds: 45
figure: squat

Feet shoulder-width apart. Sit back as if into a chair, chest up, then stand. Ten to fifteen.

---
```

- `seconds:` how long it runs.
- `kind:` `vigorous` (out of breath) or `walk`; leave it out for strength and mobility.
- `figure:` one of squat, calf, wallpush, march, lunge, jacks, armcircle, reach, twist, neck, chest.

Moves turned off with **not for me** are listed in `off.txt` beside it. `log.jsonl` records each card
shown, started, done, stopped, put off or swapped. Nothing leaves your Mac.

## Development

- `swift test` runs the timing and moves-file tests (`Sources/SnackCore`).
- `xcrun swift-format format -i -r Sources Tests Package.swift` formats the code; `.swift-format` holds
  the settings.
- `Snacks --snapshot out.png` draws the cards and every figure to an image.
- `Snacks --demo` shows the small card at launch, `--demo-full` the full-screen snack.

## Licence

[MIT](LICENSE)

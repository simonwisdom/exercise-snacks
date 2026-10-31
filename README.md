# Snacks (working name)

A menu-bar app that offers a one-minute exercise snack after about 30 minutes at the Mac.
It replaces Stretch Reminder (2025); the old Xcode project is in the git history.

- **When**: after 30 minutes of use it waits for a pause (4 s with no typing or mouse). Never while
  the microphone is in use (a call) or the front app fills the screen. Five minutes away from the
  Mac counts as a break and starts the count again; sleep doesn't count as use.
- **The card**: bottom right, over other windows, without taking keyboard focus. A looping figure
  does the move. **Start** runs a countdown and closes the card; **Later** comes back after 10 more
  minutes of use; **Another** swaps the move. Left out of screen shares and recordings.
- **Menu**: time left, Snack now, Pause for an hour, Edit moves…, Open at login, Quit.
- **Moves**: `~/Library/Application Support/Snacks/moves.md`, written from the seed on first run:
  `# Title` entries split by `---`, with `seconds:` and `figure:` lines (squat, calf, wallpush,
  march, lunge, jacks, armcircle, reach, twist, neck, chest).
- **Log**: `log.jsonl` beside it records each card shown, started, done, stopped, later or swapped.

## Build and check

- `bin/build` makes `build/Snacks.app` (ad-hoc signed).
- `swift test` runs the timing and moves-file tests.
- `Snacks --snapshot out.png` draws the cards and every figure (buttons show as yellow blocks there:
  the renderer can't draw native controls).
- `Snacks --demo` shows a card at launch, visible to screenshots.

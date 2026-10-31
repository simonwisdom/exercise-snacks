# Snacks (working name)

A menu-bar app that offers a one-minute exercise snack after about 30 minutes at the Mac.
It replaces Stretch Reminder (2025); the old Xcode project is in the git history.

- **When**: after 30 minutes of use it waits for a pause (4 s with no typing or mouse). Never while
  the microphone is in use (a call) or the front app fills the screen. Five minutes away from the
  Mac counts as a break and starts the count again; sleep doesn't count as use.
- **Asks first**: a small card at the top centre, just under the menu bar, says "Snack time?" with
  the move and its length, and **Later** or **Yes**. It floats over other windows without taking
  keyboard focus. **Later** comes back after 10 more minutes of use.
- **Then fills the screen**: **Yes** opens the snack full screen, over everything: a big looping
  figure, what to do, and a countdown ring. It closes itself when time's up ("Done. Back to it.")
  and hands focus back to the app you were in. **Stop** (or esc) and **Another move** sit at the
  bottom. Both are left out of screen shares and recordings.
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
- `Snacks --demo` shows the small card at launch, `--demo-full` the full-screen snack; both visible to screenshots.

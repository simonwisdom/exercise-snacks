# Snacks

Swift package, macOS 13+. Timing rules and the moves-file parser live in `Sources/SnackCore` and have
tests (`swift test`); the AppKit/SwiftUI app is `Sources/Snacks`. Build with `bin/build`. See
README.md for behaviour. Check visual changes with `--snapshot` (figures) and `--demo` plus
`screencapture -l <window id>` (the real card).

Format with `xcrun swift-format format -i -r Sources Tests Package.swift` before committing; `xcrun swift-format lint -r Sources Tests Package.swift` should print nothing.

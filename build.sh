#!/bin/bash

echo "Building Stretch Reminder App..."

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: This app can only be built on macOS"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode command line tools are required"
    echo "Install with: xcode-select --install"
    exit 1
fi

cd StretchReminder

echo "Checking Swift syntax..."
if swiftc -typecheck StretchReminder/StretchReminderApp.swift StretchReminder/ContentView.swift StretchReminder/Models/Exercise.swift StretchReminder/Services/ExerciseDatabase.swift StretchReminder/Services/ReminderTimer.swift; then
    echo "✅ Swift syntax check passed"
else
    echo "❌ Swift syntax errors found"
    exit 1
fi

echo "To build and run the app:"
echo "1. Open StretchReminder/StretchReminder.xcodeproj in Xcode"
echo "2. Select Product > Run (Cmd+R)"
echo "3. The app will appear in your menu bar with a stretching icon"

echo ""
echo "App Features:"
echo "- 30-minute exercise reminders"
echo "- 17 desk-friendly exercises"
echo "- Pause/resume timer"
echo "- Manual exercise trigger"
echo "- Native macOS notifications (when permitted)"
echo ""
echo "⚠️  Notification Note:"
echo "Due to macOS security, notifications may not work in debug builds."
echo "The app will still function with visual reminders in the menubar."
echo "For full notification support, the app needs proper code signing."
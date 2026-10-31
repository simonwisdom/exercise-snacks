# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Stretch Reminder** - A native macOS menubar application that reminds users to take exercise breaks every 30 minutes. Built with Swift and SwiftUI.

## Build Commands

```bash
# Open project in Xcode
open StretchReminder/StretchReminder.xcodeproj

# Build from command line (requires Xcode Command Line Tools)
xcodebuild -project StretchReminder/StretchReminder.xcodeproj -scheme StretchReminder -configuration Debug build

# Build for release
xcodebuild -project StretchReminder/StretchReminder.xcodeproj -scheme StretchReminder -configuration Release build
```

## Development Setup

- **Requirements**: macOS 13.0+, Xcode 15.0+
- **Target Platform**: macOS (native menubar app)
- **Language**: Swift 5.0
- **Framework**: SwiftUI
- **Architecture**: MVVM pattern

## Project Structure

```
StretchReminder/
├── StretchReminder/
│   ├── StretchReminderApp.swift          # Main app entry point with MenuBarExtra
│   ├── ContentView.swift                 # Main menubar dropdown UI
│   ├── Views/
│   │   └── AnimatedExerciseIcon.swift    # Animated SF Symbol exercise icons
│   ├── Models/
│   │   └── Exercise.swift                # Exercise data model with visual properties
│   ├── Services/
│   │   ├── ExerciseDatabase.swift        # Exercise collection with SF Symbol mapping
│   │   └── ReminderTimer.swift           # Timer logic and notifications
│   ├── Assets.xcassets/                  # App icons and assets
│   └── StretchReminder.entitlements      # App sandbox permissions
```

## Key Components

- **MenuBarExtra**: Modern SwiftUI approach for menubar integration (macOS 13.0+)
- **ReminderTimer**: Manages 30-minute intervals and notifications
- **ExerciseDatabase**: Contains 17 desk-friendly exercises across 6 categories
- **Exercise Categories**: Neck, Shoulders, Back, Arms, Wrists, Legs

## Features

- 30-minute reminder intervals (customizable)
- 17 office-friendly exercises with animated visual demonstrations
- Native macOS notifications with proper permission handling
- Pause/resume timer functionality
- Random exercise selection
- Clean menubar integration
- Notification status indicator and settings access
- Color-coded exercise categories with SF Symbol animations
- Accessibility support with VoiceOver descriptions

## First Run Setup

1. When first launched, the app will request notification permissions
2. If notifications are denied, the app will show a warning and "Enable Notifications" button
3. The button opens System Preferences → Notifications to manually enable permissions
4. App functions fully without notifications but reminders are visual-only

## Configuration

- Claude Code settings: `.claude/settings.local.json`
- App bundle ID: `com.stretchreminder.app`
- LSUIElement: YES (background-only app)
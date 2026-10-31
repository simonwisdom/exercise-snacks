# Stretch Reminder - macOS Menubar App

A native macOS menubar application that reminds you to take exercise breaks every 30 minutes.

## Features
- 🕐 30-minute stretch reminders
- 💪 17 desk-friendly exercises with animated demonstrations
- 🎨 Color-coded exercise categories with SF Symbol animations
- 🔔 Native macOS notifications (when permitted)
- ⏸️ Pause/resume timer
- 🎯 Random exercise selection
- 🖥️ Clean menubar integration
- ♿ Accessibility support with VoiceOver descriptions

## Quick Start
1. Open `StretchReminder/StretchReminder.xcodeproj` in Xcode
2. Press Cmd+R to build and run
3. App appears in menubar with walking figure icon
4. Click icon to access controls and exercises

## Notification Setup
**Important**: Due to macOS security restrictions, notification permissions may not work properly in debug builds.

### For Development:
- The app will request notification permissions on first launch
- If denied, notifications will be disabled but the app continues working
- Visual reminders still appear in the menubar dropdown

### For Distribution:
- App needs to be properly code-signed with valid Developer ID
- Notifications will work normally after proper signing and distribution

### Manual Setup:
If notifications aren't working:
1. Go to System Preferences > Notifications
2. Find "StretchReminder" in the list
3. Enable "Allow Notifications"

## Exercise Categories
Each category has its own color theme and animated SF Symbol demonstrations:

- **Neck** (Blue): Side stretches, forward leans, rotations
- **Shoulders** (Green): Rolls, cross-body stretches, overhead reaches  
- **Back** (Purple): Spinal twists, upper back stretches, cat-cow movements
- **Arms** (Orange): Tricep stretches, arm circles
- **Wrists** (Red): Flexor stretches, circles, prayer stretches
- **Legs** (Teal): Calf raises, ankle circles, hip flexor stretches

## Visual Demonstrations
- **Pulse animations** for static stretch positions
- **Rotation animations** for circular movements
- **Bounce animations** for repetitive exercises
- **Slide animations** for stretching motions
- **Wave animations** for flowing movements

## Controls
- **Do Exercise Now**: Trigger immediate exercise popup
- **Pause/Resume Timer**: Control the 30-minute countdown
- **Enable Notifications**: Opens system preferences (if needed)
- **Quit**: Close the application

## Technical Details
- Built with Swift 5.0 + SwiftUI
- Requires macOS 13.0+
- Uses MenuBarExtra for native menubar integration
- MVVM architecture with Combine for reactive updates
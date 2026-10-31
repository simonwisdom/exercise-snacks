import SwiftUI

@main
struct StretchReminderApp: App {
    @StateObject private var reminderTimer = ReminderTimer()
    
    var body: some Scene {
        MenuBarExtra("Stretch Reminder", systemImage: "figure.walk") {
            ContentView()
                .environmentObject(reminderTimer)
        }
        .menuBarExtraStyle(.window)
    }
}
import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var reminderTimer: ReminderTimer
    @State private var showingExercise = false
    @State private var currentExercise: Exercise?
    @State private var exerciseWindow: NSWindow?
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Text("Stretch Reminder")
                    .font(.headline)
                
                Text(timeUntilNextReminder)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !reminderTimer.notificationsEnabled {
                    Text("⚠️ Notifications disabled")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Divider()
            
            VStack(spacing: 8) {
                Button("Do Exercise Now") {
                    currentExercise = ExerciseDatabase.shared.getRandomExercise()
                    showExerciseWindow()
                }
                .buttonStyle(.borderedProminent)
                
                Button(reminderTimer.isPaused ? "Resume Timer" : "Pause Timer") {
                    if reminderTimer.isPaused {
                        reminderTimer.resume()
                    } else {
                        reminderTimer.pause()
                    }
                }
                .buttonStyle(.bordered)
                
                if !reminderTimer.notificationsEnabled {
                    Button("Enable Notifications") {
                        reminderTimer.requestNotifications()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            openNotificationSettings()
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
        .padding()
        .frame(width: 200)
        .onReceive(reminderTimer.shouldShowReminder) { _ in
            currentExercise = ExerciseDatabase.shared.getRandomExercise()
            showExerciseWindow()
        }
    }
    
    private var timeUntilNextReminder: String {
        let minutes = reminderTimer.minutesUntilNextReminder
        if reminderTimer.isPaused {
            return "Timer paused"
        } else if minutes == 0 {
            return "Time to stretch!"
        } else {
            return "Next reminder in \(minutes) min"
        }
    }
    
    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func showExerciseWindow() {
        guard let exercise = currentExercise else { return }
        
        // Close existing window if any
        exerciseWindow?.close()
        
        // Create new window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Time to Stretch!"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        // Create SwiftUI view
        let exerciseView = ExerciseView(exercise: exercise) {
            window.close()
        }
        
        window.contentView = NSHostingView(rootView: exerciseView)
        window.makeKeyAndOrderFront(nil)
        
        exerciseWindow = window
    }
}

struct ExerciseView: View {
    let exercise: Exercise
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated exercise icon
            AnimatedExerciseIcon(exercise: exercise)
            
            Text(exercise.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(exercise.category.color)
            
            // Category badge
            HStack {
                Text(exercise.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(exercise.category.color.opacity(0.2))
                    .foregroundColor(exercise.category.color)
                    .clipShape(Capsule())
                
                Spacer()
                
                Text("Duration: \(exercise.duration)s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                Text(exercise.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Done") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(exercise.category.color)
        }
        .padding(20)
        .frame(minWidth: 400, maxWidth: 450, minHeight: 350, maxHeight: 500)
        .background(exercise.category.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
        .environmentObject(ReminderTimer())
}

#Preview("Exercise View") {
    ExerciseView(
        exercise: Exercise(
            name: "Neck Side Stretch",
            description: "Gently tilt your head to one side, bringing your ear toward your shoulder. Hold for 15 seconds, then repeat on the other side.",
            duration: 30,
            category: .neck,
            symbolName: "arrow.left.and.right",
            animationType: .slide
        ),
        onDismiss: {}
    )
}
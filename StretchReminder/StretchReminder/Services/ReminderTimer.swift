import Foundation
import Combine
import UserNotifications

class ReminderTimer: ObservableObject {
    @Published var isPaused: Bool = false
    @Published var minutesUntilNextReminder: Int = 30
    @Published var notificationsEnabled: Bool = false
    
    let shouldShowReminder = PassthroughSubject<Void, Never>()
    
    private var timer: Timer?
    private let reminderInterval: TimeInterval = 30 * 60 // 30 minutes in seconds
    private var remainingTime: TimeInterval
    
    init() {
        self.remainingTime = reminderInterval
        checkNotificationStatus()
        requestNotificationPermission()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error)")
                    self.notificationsEnabled = false
                } else if granted {
                    print("Notification permissions granted")
                    self.notificationsEnabled = true
                } else {
                    print("Notification permissions denied by user")
                    self.notificationsEnabled = false
                }
            }
        }
        
        // Also check current status
        checkNotificationStatus()
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            if !self.isPaused {
                self.remainingTime -= 60
                self.minutesUntilNextReminder = max(0, Int(self.remainingTime / 60))
                
                if self.remainingTime <= 0 {
                    self.triggerReminder()
                    self.resetTimer()
                }
            }
        }
    }
    
    private func triggerReminder() {
        shouldShowReminder.send()
        sendNotification()
    }
    
    private func sendNotification() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("Notifications not authorized")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Time to Stretch!"
            content.body = "Take a quick break and do a stretch exercise."
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Notification error: \(error)")
                } else {
                    print("Notification sent successfully")
                }
            }
        }
    }
    
    private func resetTimer() {
        remainingTime = reminderInterval
        minutesUntilNextReminder = Int(reminderInterval / 60)
    }
    
    func pause() {
        isPaused = true
    }
    
    func resume() {
        isPaused = false
    }
    
    func skipToNext() {
        resetTimer()
        triggerReminder()
    }
    
    func requestNotifications() {
        requestNotificationPermission()
    }
}
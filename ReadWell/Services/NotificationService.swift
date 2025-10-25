import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            isAuthorized = granted
            
            if granted {
                await scheduleDefaultReminders()
            }
        } catch {
            print("Notification authorization error: \(error)")
            isAuthorized = false
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Schedule daily reminder for check-in
    func scheduleDailyReminder(at time: Date) async {
        guard isAuthorized else { return }
        
        // Remove existing daily reminders
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["daily_checkin"]
        )
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let content = UNMutableNotificationContent()
        content.title = "ReadWell Daily Check-in"
        content.body = "Ready for your 5-minute reflection? 🌟"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "daily_checkin",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error scheduling daily reminder: \(error)")
        }
    }
    
    
    // Schedule streak encouragement
    func scheduleStreakEncouragement(currentStreak: Int) async {
        guard isAuthorized else { return }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["streak_encouragement"]
        )
        
        // Schedule for tomorrow if user hasn't checked in
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let reminderTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: tomorrow)
        
        guard let reminderTime = reminderTime else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: reminderTime.timeIntervalSinceNow,
            repeats: false
        )
        
        let messages = [
            "Don't break your \(currentStreak)-day streak! 🔥",
            "Keep the momentum going - \(currentStreak) days strong! 💪",
            "Your \(currentStreak)-day journey continues... ✨"
        ]
        
        let content = UNMutableNotificationContent()
        content.title = "Streak Reminder"
        content.body = messages.randomElement() ?? "Time for your daily check-in!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "streak_encouragement",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error scheduling streak encouragement: \(error)")
        }
    }
    
    // Schedule weekly review reminder
    func scheduleWeeklyReviewReminder() async {
        guard isAuthorized else { return }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["weekly_review"]
        )
        
        // Schedule for Sunday evening
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let content = UNMutableNotificationContent()
        content.title = "Weekly Review Ready"
        content.body = "See your week's patterns and plan ahead 📊"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "weekly_review",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error scheduling weekly review: \(error)")
        }
    }
    
    private func scheduleDefaultReminders() async {
        // Schedule default daily reminder for 9:30 PM
        let defaultTime = Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: Date()) ?? Date()
        await scheduleDailyReminder(at: defaultTime)
        
        // Schedule weekly review reminder
        await scheduleWeeklyReviewReminder()
    }
    
    
    // Clear all notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

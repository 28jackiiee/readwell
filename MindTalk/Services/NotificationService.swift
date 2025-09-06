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
        content.title = "MindTalk Daily Check-in"
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
    
    // Schedule action reminders
    func scheduleActionReminders(for actions: [Action]) async {
        guard isAuthorized else { return }
        
        // Remove existing action reminders
        let actionIds = actions.compactMap { action in
            action.objectID.uriRepresentation().absoluteString
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: actionIds
        )
        
        for action in actions {
            await scheduleActionReminder(for: action)
        }
    }
    
    private func scheduleActionReminder(for action: Action) async {
        guard let title = action.title,
              let dueTime = action.dueTime else { return }
        
        let notificationTime = parseActionTime(dueTime)
        let calendar = Calendar.current
        
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: notificationTime)
        dateComponents.minute = calendar.component(.minute, from: notificationTime)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let content = UNMutableNotificationContent()
        content.title = "Action Reminder"
        content.body = "Time to: \(title)"
        content.sound = .default
        content.categoryIdentifier = "ACTION_REMINDER"
        
        let request = UNNotificationRequest(
            identifier: action.objectID.uriRepresentation().absoluteString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error scheduling action reminder: \(error)")
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
    
    private func parseActionTime(_ timeString: String) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        switch timeString.lowercased() {
        case "morning":
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today
        case "afternoon":
            return calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today) ?? today
        case "evening":
            return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? today
        case "night":
            return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today) ?? today
        default:
            // Default to 2 hours from now
            return calendar.date(byAdding: .hour, value: 2, to: today) ?? today
        }
    }
    
    // Clear all notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

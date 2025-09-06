import Foundation
import SwiftUI

struct AppConstants {
    // App Configuration
    static let appName = "MindTalk"
    static let appVersion = "1.0"
    static let sessionDuration: TimeInterval = 300 // 5 minutes
    static let reflectionDuration: TimeInterval = 60 // 1 minute
    
    // Session Configuration
    static let promptIntervals: [TimeInterval] = [90, 180, 270] // 1.5, 3, 4.5 minutes
    static let maxSummaryBullets = 6
    static let maxActions = 3
    static let maxEmotions = 3
    
    // Streak Configuration
    static let streakGracePeriod: TimeInterval = 12 * 60 * 60 // 12 hours
    static let weeklyReviewDay = 1 // Sunday
    
    // Colors
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        static let emotionColors: [String: Color] = [
            "yellow": .yellow,
            "orange": .orange,
            "blue": .blue,
            "purple": .purple,
            "gray": .gray,
            "red": .red,
            "green": .green,
            "cyan": .cyan,
            "brown": .brown
        ]
    }
    
    // Audio
    struct Audio {
        static let chimeSound: UInt32 = 1016
        static let successSound: UInt32 = 1001
        static let warningSound: UInt32 = 1002
    }
    
    // Prompts
    struct Prompts {
        static let checkInPrompts = [
            "What actually mattered today?",
            "If tomorrow went well, what changed?",
            "One tiny thing you'll do in 24 hours?"
        ]
        
        static let intents = ["school", "health", "relationships", "free talk"]
        static let intentEmojis = ["📚", "💪", "❤️", "💭"]
        
        static let reflectionPrompts = [
            "What helped you succeed?",
            "What got in the way?",
            "What would you do differently?",
            "What are you grateful for today?"
        ]
    }
    
    // Notifications
    struct Notifications {
        static let dailyCheckInIdentifier = "daily_checkin"
        static let streakReminderIdentifier = "streak_reminder"
        static let weeklyReviewIdentifier = "weekly_review"
        static let actionReminderPrefix = "action_"
    }
    
    // PDF Export
    struct PDF {
        static let defaultFilename = "MindTalk_Report"
        static let pageMargin: CGFloat = 40
        static let lineSpacing: CGFloat = 18
    }
    
    // UserDefaults Keys
    struct UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredReminderTime = "preferredReminderTime"
        static let enabledNotifications = "enabledNotifications"
        static let lastAppVersion = "lastAppVersion"
    }
}

// MARK: - Extensions
extension Color {
    static func emotion(_ colorName: String) -> Color {
        return AppConstants.Colors.emotionColors[colorName] ?? .gray
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func dayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    func shortDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}

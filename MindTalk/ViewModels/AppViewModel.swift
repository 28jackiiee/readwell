import SwiftUI
import CoreData
import Foundation

enum AppView {
    case start
    case guidedTalk
    case summary
    case reflection
    case weeklyReview
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var currentView: AppView = .start
    @Published var currentSession: CheckInSession?
    @Published var userSettings: UserSettings?
    
    private var viewContext: NSManagedObjectContext?
    
    func initializeApp(context: NSManagedObjectContext) {
        self.viewContext = context
        loadUserSettings()
        checkForPendingReflection()
    }
    
    private func loadUserSettings() {
        guard let context = viewContext else { return }
        
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try context.fetch(request)
            if let existingSettings = settings.first {
                userSettings = existingSettings
            } else {
                // Create default settings
                let newSettings = UserSettings(context: context)
                newSettings.isNotificationsEnabled = true
                newSettings.currentStreak = 0
                newSettings.longestStreak = 0
                userSettings = newSettings
                try context.save()
            }
        } catch {
            print("Error loading user settings: \(error)")
        }
    }
    
    private func checkForPendingReflection() {
        guard let settings = userSettings,
              let lastCheckIn = settings.lastCheckInDate else {
            currentView = .start
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // If last check-in was yesterday, show reflection view
        if calendar.isDate(lastCheckIn, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today) ?? today) {
            currentView = .reflection
        } else {
            currentView = .start
        }
    }
    
    func startNewSession() {
        guard let context = viewContext else { return }
        
        let newSession = CheckInSession(context: context)
        newSession.date = Date()
        currentSession = newSession
        currentView = .guidedTalk
    }
    
    func completeSession() {
        guard let context = viewContext,
              let session = currentSession else { return }
        
        do {
            try context.save()
            updateStreak()
            currentView = .summary
        } catch {
            print("Error saving session: \(error)")
        }
    }
    
    private func updateStreak() {
        guard let settings = userSettings else { return }
        
        let today = Date()
        let calendar = Calendar.current
        
        if let lastCheckIn = settings.lastCheckInDate {
            let daysBetween = calendar.dateComponents([.day], from: lastCheckIn, to: today).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day - increment streak
                settings.currentStreak += 1
            } else if daysBetween > 1 {
                // Missed days - reset streak
                settings.currentStreak = 1
            }
            // Same day check-ins don't change streak
        } else {
            // First check-in ever
            settings.currentStreak = 1
        }
        
        // Update longest streak
        if settings.currentStreak > settings.longestStreak {
            settings.longestStreak = settings.currentStreak
        }
        
        settings.lastCheckInDate = today
        
        do {
            try viewContext?.save()
        } catch {
            print("Error updating streak: \(error)")
        }
    }
    
    func goToStart() {
        currentSession = nil
        currentView = .start
    }
    
    func showWeeklyReview() {
        currentView = .weeklyReview
    }
}

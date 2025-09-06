import SwiftUI
import CoreData
import Foundation

enum AppView {
    case start
    case guidedTalk
    case summary
    case reflection
    case weeklyReview
    case calendar
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var currentView: AppView = .start
    @Published var currentSession: CheckInSession?
    @Published var userSettings: UserSettings?
    @Published var isProcessingAI = false
    @Published var aiProcessingError: String = ""
    
    private var viewContext: NSManagedObjectContext?
    private let openAIService = OpenAIService()
    
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
        
        // Save the basic session first
        do {
            try context.save()
            updateStreak()
        } catch {
            print("Error saving session: \(error)")
            return
        }
        
        // Process with AI if we have a transcript
        if let transcript = session.transcript, !transcript.isEmpty {
            Task {
                await processSessionWithAI(session: session, transcript: transcript)
                currentView = .summary
            }
        } else {
            currentView = .summary
        }
    }
    
    private func processSessionWithAI(session: CheckInSession, transcript: String) async {
        isProcessingAI = true
        aiProcessingError = ""
        
        let energyLevel = Int(session.energyLevel)
        let intent = session.intent ?? "general"
        
        if let analysis = await openAIService.analyzeSession(
            transcript: transcript,
            energyLevel: energyLevel,
            intent: intent
        ) {
            await updateSessionWithAnalysis(session: session, analysis: analysis)
        } else {
            aiProcessingError = openAIService.lastError
        }
        
        isProcessingAI = false
    }
    
    private func updateSessionWithAnalysis(session: CheckInSession, analysis: SessionAnalysis) async {
        guard let context = viewContext else { return }
        
        // Update session with AI analysis
        session.summary = analysis.summary
        session.coreTheme = analysis.coreTheme
        
        // Create emotion entities
        for emotionData in analysis.emotions {
            let emotion = Emotion(context: context)
            emotion.name = emotionData.name
            emotion.intensity = emotionData.intensity
            emotion.color = emotionData.color
            emotion.session = session
        }
        
        // Create action entities
        for actionData in analysis.actions {
            let action = Action(context: context)
            action.title = actionData.title
            action.category = actionData.category
            action.dueTime = actionData.dueTime
            action.isSpecific = actionData.isSpecific
            action.isMeasurable = actionData.isMeasurable
            action.isAchievable = actionData.isAchievable
            action.isRelevant = actionData.isRelevant
            action.isTimeBound = actionData.isTimeBound
            action.isCompleted = false
            action.session = session
        }
        
        // Save the processed session
        do {
            try context.save()
            print("💾 Session processed with AI analysis successfully")
        } catch {
            print("Error saving processed session: \(error)")
            aiProcessingError = "Failed to save AI analysis: \(error.localizedDescription)"
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
    
    func showCalendar() {
        currentView = .calendar
    }
}

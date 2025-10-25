import SwiftUI
import CoreData
import Foundation

enum AppView {
    case authentication
    case studentLogin
    case teacherDashboard
    case textLibrary
    case reading
    case selfReadingPractice
    case comprehensionCheck
    case studentProgress
    case settings
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var currentView: AppView = .authentication
    @Published var currentStudent: Student?
    @Published var currentTeacher: Teacher?
    @Published var currentUser: AuthenticatedUser?
    @Published var currentText: ReadingText?
    @Published var currentReadingSession: ReadingSession?
    @Published var isTeacherMode = false
    @Published var selectedStudents: [Student] = []
    
    var viewContext: NSManagedObjectContext?
    private let openAIAPIKey: String
    
    init() {
        // Try multiple sources for API key
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            print("🔑 Found API key in environment variable")
            self.openAIAPIKey = envKey
        } else if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
            print("📄 Found Config.plist at path: \(path)")
            if let plist = NSDictionary(contentsOfFile: path) {
                print("📋 Loaded plist contents: \(plist)")
                if let apiKey = plist["OPENAI_API_KEY"] as? String {
                    print("🔑 Found API key in Config.plist: \(apiKey.prefix(10))...")
                    self.openAIAPIKey = apiKey
                } else {
                    print("❌ OPENAI_API_KEY not found in plist or not a string")
                    self.openAIAPIKey = ""
                }
            } else {
                print("❌ Failed to load plist from path")
                self.openAIAPIKey = ""
            }
        } else {
            print("❌ Config.plist not found in bundle")
            self.openAIAPIKey = ""
        }
        
        print("🔧 Final API key configured: \(openAIAPIKey.isEmpty ? "NO" : "YES")")
    }
    
    func initializeApp(context: NSManagedObjectContext) {
        self.viewContext = context
        // Add sample texts if none exist
        SampleDataHelper.addSampleTexts(context: context)
    }
    
    // MARK: - Authentication
    
    func authenticateUser(_ user: AuthenticatedUser) {
        currentUser = user
        
        if user.role == .teacher {
            // Load teacher entity - try by email (username) first
            if let context = viewContext {
                let request: NSFetchRequest<Teacher> = Teacher.fetchRequest()
                request.predicate = NSPredicate(format: "username == %@", user.email)
                request.fetchLimit = 1
                
                if let teacher = try? context.fetch(request).first {
                    currentTeacher = teacher
                    isTeacherMode = true
                    currentView = .teacherDashboard
                } else {
                    // Try by UUID if email doesn't match
                    if let uuid = UUID(uuidString: user.id) {
                        let uuidRequest: NSFetchRequest<Teacher> = Teacher.fetchRequest()
                        uuidRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                        uuidRequest.fetchLimit = 1
                        
                        if let teacher = try? context.fetch(uuidRequest).first {
                            currentTeacher = teacher
                            isTeacherMode = true
                            currentView = .teacherDashboard
                        }
                    }
                }
            }
        } else {
            // Load student entity - try by email (username) first
            if let context = viewContext {
                let request: NSFetchRequest<Student> = Student.fetchRequest()
                request.predicate = NSPredicate(format: "username == %@", user.email)
                request.fetchLimit = 1
                
                if let student = try? context.fetch(request).first {
                    currentStudent = student
                    isTeacherMode = false
                    currentView = .textLibrary
                } else {
                    // Try by UUID if email doesn't match
                    if let uuid = UUID(uuidString: user.id) {
                        let uuidRequest: NSFetchRequest<Student> = Student.fetchRequest()
                        uuidRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                        uuidRequest.fetchLimit = 1
                        
                        if let student = try? context.fetch(uuidRequest).first {
                            currentStudent = student
                            isTeacherMode = false
                            currentView = .textLibrary
                        }
                    }
                }
            }
        }
    }
    
    func logout() {
        currentUser = nil
        currentStudent = nil
        currentTeacher = nil
        currentText = nil
        currentReadingSession = nil
        isTeacherMode = false
        currentView = .authentication
    }
    
    // MARK: - Student Management
    
    func loginStudent(student: Student) {
        currentStudent = student
        currentView = .textLibrary
    }
    
    func logoutStudent() {
        logout()
    }
    
    func getAllStudents() -> [Student] {
        guard let context = viewContext else { return [] }
        
        let request: NSFetchRequest<Student> = Student.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Student.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching students: \(error)")
            return []
        }
    }
    
    func createStudent(name: String, gradeLevel: Int16, preferredLanguage: String, secondLanguage: String?) {
        guard let context = viewContext else { return }
        
        let student = Student(context: context)
        student.id = UUID()
        student.name = name
        student.gradeLevel = gradeLevel
        student.preferredLanguage = preferredLanguage
        student.secondLanguage = secondLanguage
        student.useDyslexiaFont = true
        student.fontSize = 20
        student.lineSpacing = 1.8
        student.backgroundColor = "beige"
        student.createdDate = Date()
        
        do {
            try context.save()
            print("✅ Created student: \(name)")
        } catch {
            print("Error creating student: \(error)")
        }
    }
    
    // MARK: - Text Management
    
    func getAllTexts(forGradeLevel gradeLevel: Int16? = nil) -> [ReadingText] {
        guard let context = viewContext else { return [] }
        
        let request: NSFetchRequest<ReadingText> = ReadingText.fetchRequest()
        
        if let grade = gradeLevel {
            request.predicate = NSPredicate(format: "gradeLevel == %d", grade)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingText.dateAdded, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching texts: \(error)")
            return []
        }
    }
    
    func selectText(_ text: ReadingText) {
        currentText = text
        startReadingSession()
    }
    
    // MARK: - Reading Session Management
    
    func startReadingSession() {
        guard let context = viewContext,
              let student = currentStudent,
              let text = currentText else { return }
        
        let session = ReadingSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.duration = 0.0  // Initialize required duration field
        session.student = student
        session.text = text
        session.readingSpeed = 1.0
        session.usedTTS = false
        session.usedTranslation = false
        session.completedReading = false
        
        currentReadingSession = session
        
        do {
            try context.save()
            currentView = .reading
        } catch {
            print("Error starting reading session: \(error)")
        }
    }
    
    func completeReading() {
        guard let session = currentReadingSession else { return }
        
        session.endDate = Date()
        session.completedReading = true
        
        if let start = session.startDate, let end = session.endDate {
            session.duration = end.timeIntervalSince(start)
        }
        
        do {
            try viewContext?.save()
            currentView = .selfReadingPractice
        } catch {
            print("Error completing reading: \(error)")
        }
    }
    
    func submitComprehensionAnswers(answers: [(question: ComprehensionQuestion, answer: String)]) {
        guard let context = viewContext,
              let student = currentStudent,
              let session = currentReadingSession else { return }
        
        var correctCount = 0
        
        for (question, answer) in answers {
            let studentAnswer = StudentAnswer(context: context)
            studentAnswer.id = UUID()
            studentAnswer.answer = answer
            studentAnswer.isCorrect = (answer == question.correctAnswer)
            studentAnswer.timestamp = Date()
            studentAnswer.attemptNumber = 1
            studentAnswer.question = question
            studentAnswer.student = student
            
            if studentAnswer.isCorrect {
                correctCount += 1
            }
        }
        
        let score = answers.isEmpty ? 0.0 : Double(correctCount) / Double(answers.count) * 100.0
        session.comprehensionScore = score
        
        do {
            try context.save()
            currentView = .studentProgress
        } catch {
            print("Error submitting comprehension answers: \(error)")
        }
    }
    
    // MARK: - Teacher Dashboard
    
    func switchToTeacherMode() {
        isTeacherMode = true
        currentView = .teacherDashboard
    }
    
    func switchToStudentMode() {
        isTeacherMode = false
        currentView = .authentication
    }
    
    func getStudentProgress(for student: Student) -> [ReadingSession] {
        guard let context = viewContext else { return [] }
        
        let request: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
        request.predicate = NSPredicate(format: "student == %@", student)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingSession.startDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching student progress: \(error)")
            return []
        }
    }
    
    func getAverageComprehensionScore(for student: Student) -> Double {
        let sessions = getStudentProgress(for: student)
        let scoresArray = sessions.compactMap { session -> Double? in
            guard session.comprehensionScore ?? 0 > 0 else { return nil }
            return session.comprehensionScore
        }
        
        guard !scoresArray.isEmpty else { return 0 }
        return scoresArray.reduce(0, +) / Double(scoresArray.count)
    }
    
    // MARK: - Navigation
    
    func goToTextLibrary() {
        currentView = .textLibrary
    }
    
    func goToSettings() {
        currentView = .settings
    }
    
    func goBack() {
        // Smart navigation based on current view
        switch currentView {
        case .reading:
            currentView = .textLibrary
        case .selfReadingPractice:
            currentView = .reading
        case .comprehensionCheck:
            currentView = .textLibrary
        case .studentProgress:
            currentView = .textLibrary
        case .textLibrary:
            if isTeacherMode {
                currentView = .teacherDashboard
            } else {
                logout()
            }
        case .settings:
            currentView = isTeacherMode ? .teacherDashboard : .textLibrary
        case .teacherDashboard:
            logout()
        default:
            logout()
        }
    }
}

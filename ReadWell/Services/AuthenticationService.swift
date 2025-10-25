import Foundation
import CoreData
import CryptoKit

enum UserRole: String {
    case student = "student"
    case teacher = "teacher"
}

struct AuthenticatedUser {
    let id: UUID
    let name: String
    let username: String
    let role: UserRole
}

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: AuthenticatedUser?
    @Published var isAuthenticated = false
    @Published var authError: String = ""
    
    private var viewContext: NSManagedObjectContext?
    
    func setContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // MARK: - Sign Up
    
    func signUp(username: String, password: String, name: String, role: UserRole, gradeLevel: Int16? = nil, schoolName: String? = nil) -> Bool {
        guard let context = viewContext else {
            authError = "Database not available"
            return false
        }
        
        // Validate inputs
        guard !username.isEmpty, !password.isEmpty, !name.isEmpty else {
            authError = "All fields are required"
            return false
        }
        
        guard username.count >= 3 else {
            authError = "Username must be at least 3 characters"
            return false
        }
        
        guard password.count >= 4 else {
            authError = "Password must be at least 4 characters"
            return false
        }
        
        // Check if username already exists
        if isUsernameTaken(username, role: role) {
            authError = "Username already taken"
            return false
        }
        
        // Hash password
        let passwordHash = hashPassword(password)
        
        // Create user based on role
        switch role {
        case .student:
            let student = Student(context: context)
            student.id = UUID()
            student.name = name
            student.username = username
            student.passwordHash = passwordHash
            student.gradeLevel = gradeLevel ?? 3
            student.preferredLanguage = "en"
            student.useDyslexiaFont = true
            student.fontSize = 20
            student.lineSpacing = 1.8
            student.backgroundColor = "beige"
            student.createdDate = Date()
            
        case .teacher:
            let teacher = Teacher(context: context)
            teacher.id = UUID()
            teacher.name = name
            teacher.username = username
            teacher.passwordHash = passwordHash
            teacher.schoolName = schoolName
            teacher.createdDate = Date()
        }
        
        do {
            try context.save()
            authError = ""
            return true
        } catch {
            authError = "Failed to create account: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Sign In
    
    func signIn(username: String, password: String) -> Bool {
        guard let context = viewContext else {
            authError = "Database not available"
            return false
        }
        
        let passwordHash = hashPassword(password)
        
        // Try to find student first
        if let student = findStudent(username: username, passwordHash: passwordHash) {
            currentUser = AuthenticatedUser(
                id: student.id!,
                name: student.name ?? "Student",
                username: username,
                role: .student
            )
            isAuthenticated = true
            authError = ""
            return true
        }
        
        // Try to find teacher
        if let teacher = findTeacher(username: username, passwordHash: passwordHash) {
            currentUser = AuthenticatedUser(
                id: teacher.id!,
                name: teacher.name ?? "Teacher",
                username: username,
                role: .teacher
            )
            isAuthenticated = true
            authError = ""
            return true
        }
        
        authError = "Invalid username or password"
        return false
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        authError = ""
    }
    
    // MARK: - Helper Methods
    
    private func isUsernameTaken(_ username: String, role: UserRole) -> Bool {
        guard let context = viewContext else { return false }
        
        switch role {
        case .student:
            let request: NSFetchRequest<Student> = Student.fetchRequest()
            request.predicate = NSPredicate(format: "username == %@", username)
            return (try? context.count(for: request)) ?? 0 > 0
            
        case .teacher:
            let request: NSFetchRequest<Teacher> = Teacher.fetchRequest()
            request.predicate = NSPredicate(format: "username == %@", username)
            return (try? context.count(for: request)) ?? 0 > 0
        }
    }
    
    private func findStudent(username: String, passwordHash: String) -> Student? {
        guard let context = viewContext else { return nil }
        
        let request: NSFetchRequest<Student> = Student.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@ AND passwordHash == %@", username, passwordHash)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    private func findTeacher(username: String, passwordHash: String) -> Teacher? {
        guard let context = viewContext else { return nil }
        
        let request: NSFetchRequest<Teacher> = Teacher.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@ AND passwordHash == %@", username, passwordHash)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Get User Entity
    
    func getStudentEntity(for userId: UUID) -> Student? {
        guard let context = viewContext else { return nil }
        
        let request: NSFetchRequest<Student> = Student.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    func getTeacherEntity(for userId: UUID) -> Teacher? {
        guard let context = viewContext else { return nil }
        
        let request: NSFetchRequest<Teacher> = Teacher.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
}


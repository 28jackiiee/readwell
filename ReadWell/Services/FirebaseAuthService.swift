import Foundation
import FirebaseAuth
import FirebaseFirestore
import CoreData

enum UserRole: String, Codable {
    case student = "student"
    case teacher = "teacher"
}

struct AuthenticatedUser: Codable {
    let id: String
    let name: String
    let email: String
    let role: UserRole
    var gradeLevel: Int16?
    var schoolName: String?
}

@MainActor
class FirebaseAuthService: ObservableObject {
    @Published var currentUser: AuthenticatedUser?
    @Published var isAuthenticated = false
    @Published var authError: String = ""
    @Published var isLoading = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var viewContext: NSManagedObjectContext?
    
    // Teacher PIN storage (using UserDefaults for simplicity, could use Firestore)
    private let teacherPINKey = "teacherPIN"
    private let defaultTeacherPIN = "1234"
    
    init() {
        // Check if there's a currently signed-in user
        if let firebaseUser = auth.currentUser {
            Task {
                await loadUserData(for: firebaseUser)
            }
        }
    }
    
    func setContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, name: String, role: UserRole, gradeLevel: Int16? = nil, schoolName: String? = nil) async -> Bool {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            authError = "All fields are required"
            return false
        }
        
        guard password.count >= 6 else {
            authError = "Password must be at least 6 characters"
            return false
        }
        
        isLoading = true
        authError = ""
        
        do {
            // Create Firebase Auth user
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Create user profile in Firestore
            let userData: [String: Any] = [
                "id": result.user.uid,
                "name": name,
                "email": email,
                "role": role.rawValue,
                "gradeLevel": gradeLevel ?? 0,
                "schoolName": schoolName ?? "",
                "createdDate": Timestamp(date: Date())
            ]
            
            try await db.collection("users").document(result.user.uid).setData(userData)
            
            // Create local Core Data entity
            await createLocalUser(uid: result.user.uid, name: name, email: email, role: role, gradeLevel: gradeLevel, schoolName: schoolName)
            
            // Set current user
            currentUser = AuthenticatedUser(
                id: result.user.uid,
                name: name,
                email: email,
                role: role,
                gradeLevel: gradeLevel,
                schoolName: schoolName
            )
            isAuthenticated = true
            isLoading = false
            return true
            
        } catch let error as NSError {
            isLoading = false
            if let errorCode = AuthErrorCode.Code(rawValue: error.code) {
                switch errorCode {
                case .emailAlreadyInUse:
                    authError = "Email already in use"
                case .invalidEmail:
                    authError = "Invalid email address"
                case .weakPassword:
                    authError = "Password is too weak"
                case .networkError:
                    authError = "Network error. Please check your connection"
                default:
                    authError = "Failed to create account: \(error.localizedDescription)"
                }
            } else {
                authError = "Failed to create account: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async -> Bool {
        guard !email.isEmpty, !password.isEmpty else {
            authError = "Email and password are required"
            return false
        }
        
        isLoading = true
        authError = ""
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            await loadUserData(for: result.user)
            isLoading = false
            return true
            
        } catch let error as NSError {
            isLoading = false
            if let errorCode = AuthErrorCode.Code(rawValue: error.code) {
                switch errorCode {
                case .wrongPassword, .userNotFound:
                    authError = "Invalid email or password"
                case .invalidEmail:
                    authError = "Invalid email address"
                case .userDisabled:
                    authError = "This account has been disabled"
                case .networkError:
                    authError = "Network error. Please check your connection"
                default:
                    authError = "Failed to sign in: \(error.localizedDescription)"
                }
            } else {
                authError = "Failed to sign in: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try auth.signOut()
            currentUser = nil
            isAuthenticated = false
            authError = ""
        } catch {
            authError = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async -> Bool {
        guard !email.isEmpty else {
            authError = "Email is required"
            return false
        }
        
        do {
            try await auth.sendPasswordReset(withEmail: email)
            return true
        } catch {
            authError = "Failed to send reset email: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Teacher PIN Authentication
    
    func authenticateTeacherWithPIN(_ pin: String) -> Bool {
        let storedPIN = UserDefaults.standard.string(forKey: teacherPINKey) ?? defaultTeacherPIN
        
        if pin == storedPIN {
            authError = ""
            return true
        } else {
            authError = "Incorrect PIN. Please try again."
            return false
        }
    }
    
    func setTeacherPIN(_ newPIN: String) -> Bool {
        guard newPIN.count == 4, newPIN.allSatisfy({ $0.isNumber }) else {
            authError = "PIN must be 4 digits"
            return false
        }
        
        UserDefaults.standard.set(newPIN, forKey: teacherPINKey)
        return true
    }
    
    func changeTeacherPIN(currentPIN: String, newPIN: String) -> Bool {
        guard authenticateTeacherWithPIN(currentPIN) else {
            authError = "Current PIN is incorrect"
            return false
        }
        
        return setTeacherPIN(newPIN)
    }
    
    func isDefaultPIN() -> Bool {
        let storedPIN = UserDefaults.standard.string(forKey: teacherPINKey)
        return storedPIN == nil || storedPIN == defaultTeacherPIN
    }
    
    // MARK: - Helper Methods
    
    private func loadUserData(for firebaseUser: User) async {
        do {
            let document = try await db.collection("users").document(firebaseUser.uid).getDocument()
            
            guard let data = document.data() else {
                authError = "User data not found"
                return
            }
            
            let name = data["name"] as? String ?? ""
            let email = data["email"] as? String ?? firebaseUser.email ?? ""
            let roleString = data["role"] as? String ?? "student"
            let role = UserRole(rawValue: roleString) ?? .student
            let gradeLevel = data["gradeLevel"] as? Int16
            let schoolName = data["schoolName"] as? String
            
            currentUser = AuthenticatedUser(
                id: firebaseUser.uid,
                name: name,
                email: email,
                role: role,
                gradeLevel: gradeLevel,
                schoolName: schoolName
            )
            isAuthenticated = true
            
            // Sync with local Core Data
            await syncWithLocalDatabase(uid: firebaseUser.uid, name: name, email: email, role: role, gradeLevel: gradeLevel, schoolName: schoolName)
            
        } catch {
            authError = "Failed to load user data: \(error.localizedDescription)"
        }
    }
    
    private func createLocalUser(uid: String, name: String, email: String, role: UserRole, gradeLevel: Int16?, schoolName: String?) async {
        guard let context = viewContext else { return }
        
        // Create user based on role in Core Data for backwards compatibility
        switch role {
        case .student:
            let student = Student(context: context)
            student.id = UUID(uuidString: uid) ?? UUID()
            student.name = name
            student.username = email
            student.passwordHash = "" // Not used with Firebase
            student.gradeLevel = gradeLevel ?? 3
            student.preferredLanguage = "en"
            student.useDyslexiaFont = true
            student.fontSize = 20
            student.lineSpacing = 1.8
            student.backgroundColor = "beige"
            student.createdDate = Date()
            
        case .teacher:
            let teacher = Teacher(context: context)
            teacher.id = UUID(uuidString: uid) ?? UUID()
            teacher.name = name
            teacher.username = email
            teacher.passwordHash = "" // Not used with Firebase
            teacher.schoolName = schoolName
            teacher.createdDate = Date()
        }
        
        do {
            try context.save()
        } catch {
            print("Error creating local user: \(error)")
        }
    }
    
    private func syncWithLocalDatabase(uid: String, name: String, email: String, role: UserRole, gradeLevel: Int16?, schoolName: String?) async {
        guard let context = viewContext else { return }
        
        let uuid = UUID(uuidString: uid) ?? UUID()
        
        // Check if user already exists in Core Data
        switch role {
        case .student:
            let request: NSFetchRequest<Student> = Student.fetchRequest()
            request.predicate = NSPredicate(format: "username == %@", email)
            
            if let existing = try? context.fetch(request).first {
                // Update existing
                existing.name = name
                existing.gradeLevel = gradeLevel ?? existing.gradeLevel
            } else {
                // Create new
                await createLocalUser(uid: uid, name: name, email: email, role: role, gradeLevel: gradeLevel, schoolName: schoolName)
            }
            
        case .teacher:
            let request: NSFetchRequest<Teacher> = Teacher.fetchRequest()
            request.predicate = NSPredicate(format: "username == %@", email)
            
            if let existing = try? context.fetch(request).first {
                // Update existing
                existing.name = name
                existing.schoolName = schoolName ?? existing.schoolName
            } else {
                // Create new
                await createLocalUser(uid: uid, name: name, email: email, role: role, gradeLevel: gradeLevel, schoolName: schoolName)
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error syncing with local database: \(error)")
        }
    }
    
    // MARK: - Get User Entity (for backwards compatibility)
    
    func getStudentEntity(for userId: String) -> Student? {
        guard let context = viewContext else { return nil }
        
        let request: NSFetchRequest<Student> = Student.fetchRequest()
        // Try to match by UUID first, then by email
        if let uuid = UUID(uuidString: userId) {
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "username == %@", currentUser?.email ?? "")
        }
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    func getTeacherEntity(for userId: String) -> Teacher? {
        guard let context = viewContext else { return nil }
        
        let request: NSFetchRequest<Teacher> = Teacher.fetchRequest()
        // Try to match by UUID first, then by email
        if let uuid = UUID(uuidString: userId) {
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "username == %@", currentUser?.email ?? "")
        }
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
}


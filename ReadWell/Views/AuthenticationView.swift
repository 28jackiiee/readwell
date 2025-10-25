import SwiftUI
import CoreData

enum AuthTab {
    case signIn
    case signUp
}

struct AuthenticationView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var authService = FirebaseAuthService()
    
    @State private var selectedTab: AuthTab = .signIn
    @State private var isLoading = false
    
    // Sign In fields
    @State private var signInEmail = ""
    @State private var signInPassword = ""
    @State private var showSignInPassword = false
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var showResetSuccess = false
    
    // Sign Up fields
    @State private var signUpEmail = ""
    @State private var signUpPassword = ""
    @State private var signUpConfirmPassword = ""
    @State private var signUpName = ""
    @State private var selectedRole: UserRole = .student
    @State private var studentGradeLevel: Int16 = 3
    @State private var teacherSchoolName = ""
    @State private var showSignUpPassword = false
    @State private var showSignUpConfirmPassword = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header with animation
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .blur(radius: 1)
                            
                            Image(systemName: "book.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        
                        Text("ReadWell")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Text("Your Reading Companion")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 60)
                    
                    // Modern Tab Selector
                    ModernTabSelector(selectedTab: $selectedTab, authService: authService)
                        .frame(maxWidth: 450)
                        .padding(.horizontal)
                    
                    // Content with transition
                    ZStack {
                        if selectedTab == .signIn {
                            SignInView(
                                email: $signInEmail,
                                password: $signInPassword,
                                showPassword: $showSignInPassword,
                                authService: authService,
                                isLoading: $isLoading,
                                showForgotPassword: $showForgotPassword,
                                onSignIn: handleSignIn
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                        } else {
                            SignUpView(
                                email: $signUpEmail,
                                password: $signUpPassword,
                                confirmPassword: $signUpConfirmPassword,
                                name: $signUpName,
                                selectedRole: $selectedRole,
                                studentGradeLevel: $studentGradeLevel,
                                teacherSchoolName: $teacherSchoolName,
                                showPassword: $showSignUpPassword,
                                showConfirmPassword: $showSignUpConfirmPassword,
                                authService: authService,
                                isLoading: $isLoading,
                                onSignUp: handleSignUp
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedTab)
            
            // Forgot Password overlay
            if showForgotPassword {
                ForgotPasswordOverlay(
                    isPresented: $showForgotPassword,
                    resetEmail: $resetEmail,
                    showSuccess: $showResetSuccess,
                    authService: authService
                )
            }
            
            // Success message
            if showResetSuccess {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("Password reset email sent!")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.9))
                            .shadow(radius: 10)
                    )
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showResetSuccess = false
                        }
                    }
                }
            }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            authService.setContext(viewContext)
        }
    }
    
    private func handleSignIn() {
        Task {
            isLoading = true
            if await authService.signIn(email: signInEmail, password: signInPassword) {
                appViewModel.authenticateUser(authService.currentUser!)
                // Clear fields
                signInEmail = ""
                signInPassword = ""
            }
            isLoading = false
        }
    }
    
    private func handleSignUp() {
        // Validate
        guard signUpPassword == signUpConfirmPassword else {
            authService.authError = "Passwords don't match"
            return
        }
        
        Task {
            isLoading = true
            
            let gradeLevel = selectedRole == .student ? studentGradeLevel : nil
            let schoolName = selectedRole == .teacher ? teacherSchoolName : nil
            
            if await authService.signUp(
                email: signUpEmail,
                password: signUpPassword,
                name: signUpName,
                role: selectedRole,
                gradeLevel: gradeLevel,
                schoolName: schoolName
            ) {
                appViewModel.authenticateUser(authService.currentUser!)
                
                // Clear fields
                signUpEmail = ""
                signUpPassword = ""
                signUpConfirmPassword = ""
                signUpName = ""
                selectedRole = .student
                studentGradeLevel = 3
                teacherSchoolName = ""
            }
            isLoading = false
        }
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.4, blue: 0.9),
                Color(red: 0.5, green: 0.3, blue: 0.8),
                Color(red: 0.3, green: 0.5, blue: 0.9)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Modern Tab Selector

struct ModernTabSelector: View {
    @Binding var selectedTab: AuthTab
    @ObservedObject var authService: FirebaseAuthService
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            TabOptionButton(
                title: "Sign In",
                icon: "arrow.right.circle.fill",
                isSelected: selectedTab == .signIn,
                namespace: animation
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = .signIn
                    authService.authError = ""
                }
            }
            
            TabOptionButton(
                title: "Sign Up",
                icon: "person.badge.plus.fill",
                isSelected: selectedTab == .signUp,
                namespace: animation
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = .signUp
                    authService.authError = ""
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct TabOptionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(isSelected ? Color(red: 0.2, green: 0.4, blue: 0.9) : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .matchedGeometryEffect(id: "TAB", in: namespace)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                }
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Sign In View

struct SignInView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var showPassword: Bool
    @ObservedObject var authService: FirebaseAuthService
    @Binding var isLoading: Bool
    @Binding var showForgotPassword: Bool
    let onSignIn: () -> Void
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                // Email Field
                ModernTextField(
                    icon: "envelope.fill",
                    placeholder: "Email",
                    text: $email,
                    isSecure: false,
                    showPassword: .constant(false)
                )
                .focused($focusedField, equals: .email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.emailAddress)
                
                // Password Field
                ModernTextField(
                    icon: "lock.fill",
                    placeholder: "Password",
                    text: $password,
                    isSecure: true,
                    showPassword: $showPassword
                )
                .focused($focusedField, equals: .password)
                .textContentType(.password)
                
                // Forgot Password Link
                Button(action: {
                    showForgotPassword = true
                }) {
                    Text("Forgot Password?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, -8)
            }
            
            // Error message
            if !authService.authError.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                    Text(authService.authError)
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.8))
                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Sign In Button
            Button(action: {
                focusedField = nil
                onSignIn()
            }) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                        Text("Sign In")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: canSignIn ? [Color(red: 0.2, green: 0.4, blue: 0.9), Color(red: 0.3, green: 0.5, blue: 0.95)] : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: canSignIn ? Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.5) : .clear, radius: 12, x: 0, y: 6)
                )
            }
            .disabled(!canSignIn || isLoading)
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .frame(maxWidth: 450)
        .padding(.horizontal, 24)
    }
    
    private var canSignIn: Bool {
        !email.isEmpty && !password.isEmpty
    }
}

// MARK: - Sign Up View

struct SignUpView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var name: String
    @Binding var selectedRole: UserRole
    @Binding var studentGradeLevel: Int16
    @Binding var teacherSchoolName: String
    @Binding var showPassword: Bool
    @Binding var showConfirmPassword: Bool
    @ObservedObject var authService: FirebaseAuthService
    @Binding var isLoading: Bool
    let onSignUp: () -> Void
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password, confirmPassword, schoolName
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                // Role Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("I am a...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        ModernRoleCard(
                            title: "Student",
                            icon: "person.fill",
                            isSelected: selectedRole == .student
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedRole = .student
                            }
                        }
                        
                        ModernRoleCard(
                            title: "Teacher",
                            icon: "person.badge.key.fill",
                            isSelected: selectedRole == .teacher
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedRole = .teacher
                            }
                        }
                    }
                }
                
                // Name Field
                ModernTextField(
                    icon: "person.text.rectangle.fill",
                    placeholder: "Full Name",
                    text: $name,
                    isSecure: false,
                    showPassword: .constant(false)
                )
                .focused($focusedField, equals: .name)
                .textContentType(.name)
                
                // Email Field
                ModernTextField(
                    icon: "envelope.fill",
                    placeholder: "Email",
                    text: $email,
                    isSecure: false,
                    showPassword: .constant(false)
                )
                .focused($focusedField, equals: .email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.emailAddress)
                
                // Password Field
                VStack(spacing: 8) {
                    ModernTextField(
                        icon: "lock.fill",
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        showPassword: $showPassword
                    )
                    .focused($focusedField, equals: .password)
                    .textContentType(.newPassword)
                    
                    // Password Strength Indicator
                    if !password.isEmpty {
                        PasswordStrengthIndicator(password: password)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // Confirm Password Field
                ModernTextField(
                    icon: "lock.shield.fill",
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    isSecure: true,
                    showPassword: $showConfirmPassword
                )
                .focused($focusedField, equals: .confirmPassword)
                .textContentType(.newPassword)
                .overlay(
                    HStack {
                        Spacer()
                        if !confirmPassword.isEmpty {
                            Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(password == confirmPassword ? .green : .red)
                                .padding(.trailing, 52)
                        }
                    }
                )
                
                // Role-specific fields
                if selectedRole == .student {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "graduationcap.fill")
                                .foregroundColor(.white.opacity(0.9))
                            Text("Grade Level: \(studentGradeLevel)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Picker("Grade", selection: $studentGradeLevel) {
                            ForEach(1..<13, id: \.self) { grade in
                                Text("Grade \(grade)").tag(Int16(grade))
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.95))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    ModernTextField(
                        icon: "building.2.fill",
                        placeholder: "School Name (Optional)",
                        text: $teacherSchoolName,
                        isSecure: false,
                        showPassword: .constant(false)
                    )
                    .focused($focusedField, equals: .schoolName)
                }
            }
            
            // Error message
            if !authService.authError.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                    Text(authService.authError)
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.8))
                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Sign Up Button
            Button(action: {
                focusedField = nil
                onSignUp()
            }) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 20))
                        Text("Create Account")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: canSignUp ? [Color(red: 0.5, green: 0.3, blue: 0.8), Color(red: 0.6, green: 0.4, blue: 0.9)] : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: canSignUp ? Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.5) : .clear, radius: 12, x: 0, y: 6)
                )
            }
            .disabled(!canSignUp || isLoading)
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .frame(maxWidth: 450)
        .padding(.horizontal, 24)
    }
    
    private var canSignUp: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        !confirmPassword.isEmpty && 
        !name.isEmpty &&
        password == confirmPassword
    }
}

// MARK: - Modern Role Card

struct ModernRoleCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [Color.white.opacity(0.3), Color.white.opacity(0.1)] : [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.white.opacity(0.6) : Color.white.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: isSelected ? .white.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Modern Text Field

struct ModernTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    @Binding var showPassword: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            if isSecure && !showPassword {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .font(.system(size: 17))
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .font(.system(size: 17))
            }
            
            if isSecure {
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Password Strength Indicator

struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        let length = password.count
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumbers = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
        var score = 0
        if length >= 8 { score += 1 }
        if length >= 12 { score += 1 }
        if hasUppercase { score += 1 }
        if hasLowercase { score += 1 }
        if hasNumbers { score += 1 }
        if hasSpecial { score += 1 }
        
        if score <= 2 { return .weak }
        if score <= 4 { return .medium }
        return .strong
    }
    
    private enum PasswordStrength {
        case weak, medium, strong
        
        var color: Color {
            switch self {
            case .weak: return .red
            case .medium: return .orange
            case .strong: return .green
            }
        }
        
        var text: String {
            switch self {
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
        
        var progress: CGFloat {
            switch self {
            case .weak: return 0.33
            case .medium: return 0.66
            case .strong: return 1.0
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Password Strength:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(strength.text)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(strength.color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(strength.color)
                        .frame(width: geometry.size.width * strength.progress, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: strength.progress)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Forgot Password Overlay

struct ForgotPasswordOverlay: View {
    @Binding var isPresented: Bool
    @Binding var resetEmail: String
    @Binding var showSuccess: Bool
    @ObservedObject var authService: FirebaseAuthService
    
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.9))
                    
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your email address and we'll send you a link to reset your password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Email", text: $resetEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                }
                
                if !authService.authError.isEmpty {
                    Text(authService.authError)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
                
                HStack(spacing: 16) {
                    Button(action: {
                        isPresented = false
                        authService.authError = ""
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                    
                    Button(action: sendResetEmail) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Send Reset Link")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(resetEmail.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(resetEmail.isEmpty || isLoading)
                }
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
            .frame(maxWidth: 400)
            .padding()
        }
    }
    
    private func sendResetEmail() {
        Task {
            isLoading = true
            if await authService.resetPassword(email: resetEmail) {
                isPresented = false
                resetEmail = ""
                showSuccess = true
                authService.authError = ""
            }
            isLoading = false
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AppViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


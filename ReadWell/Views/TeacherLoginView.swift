import SwiftUI

struct TeacherLoginView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var authService = FirebaseAuthService()
    
    @State private var pin = ""
    @State private var showSetupPIN = false
    @State private var showChangePIN = false
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var currentPIN = ""
    @State private var setupError = ""
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Animated gradient with purple theme
            AnimatedPurpleGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Back button with modern styling
                HStack {
                    Button(action: {
                        appViewModel.switchToStudentMode()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 20))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // Header with modern design
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 1)
                        
                        Image(systemName: "person.badge.key.fill")
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
                    
                    Text("Teacher Login")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    if authService.isDefaultPIN() {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                            Text("Default PIN: 1234")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.yellow.opacity(0.2))
                        )
                    }
                }
                
                // PIN Entry
                VStack(spacing: 24) {
                    // PIN Display
                    HStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { index in
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                    )
                                    .frame(width: 60, height: 70)
                                
                                if index < pin.count {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 16, height: 16)
                                } else {
                                    Text("•")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    
                    if !authService.authError.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                            Text(authService.authError)
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.8))
                                .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Number pad
                    NumberPadView(pin: $pin)
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
                .frame(maxWidth: 400)
                .padding(.horizontal, 24)
                .onChange(of: pin) { newValue in
                    // Limit to 4 digits
                    if newValue.count > 4 {
                        pin = String(newValue.prefix(4))
                    }
                    // Auto-submit when 4 digits entered
                    if pin.count == 4 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            authenticateTeacher()
                        }
                    }
                }
                
                // Change PIN button
                if !authService.isDefaultPIN() {
                    Button(action: {
                        showChangePIN = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Change PIN")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                } else {
                    Button(action: {
                        showSetupPIN = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Set Custom PIN")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.yellow.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                Spacer()
            }
            
            // Setup PIN sheet
            if showSetupPIN {
                SetupPINOverlay(
                    isPresented: $showSetupPIN,
                    authService: authService
                )
            }
            
            // Change PIN sheet
            if showChangePIN {
                ChangePINOverlay(
                    isPresented: $showChangePIN,
                    authService: authService
                )
            }
        }
        .navigationBarHidden(true)
    }
    
    private func authenticateTeacher() {
        if authService.authenticateTeacherWithPIN(pin) {
            appViewModel.switchToTeacherMode()
        } else {
            // Shake animation could be added here
            pin = ""
        }
    }
}

// MARK: - Number Pad View

struct NumberPadView: View {
    @Binding var pin: String
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(1...9, id: \.self) { number in
                NumberButton(number: "\(number)") {
                    if pin.count < 4 {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            pin += "\(number)"
                        }
                    }
                }
            }
            
            // Bottom row: empty, 0, backspace
            Color.clear
                .frame(height: 70)
            
            NumberButton(number: "0") {
                if pin.count < 4 {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        pin += "0"
                    }
                }
            }
            
            Button(action: {
                if !pin.isEmpty {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        pin.removeLast()
                    }
                }
            }) {
                Image(systemName: "delete.left.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 70, height: 70)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal)
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Setup PIN Overlay

struct SetupPINOverlay: View {
    @Binding var isPresented: Bool
    @ObservedObject var authService: FirebaseAuthService
    
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var error = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Set Custom PIN")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Choose a 4-digit PIN for teacher access")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    SecureField("New PIN", text: $newPIN)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .onChange(of: newPIN) { newValue in
                            if newValue.count > 4 {
                                newPIN = String(newValue.prefix(4))
                            }
                        }
                    
                    SecureField("Confirm PIN", text: $confirmPIN)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .onChange(of: confirmPIN) { newValue in
                            if newValue.count > 4 {
                                confirmPIN = String(newValue.prefix(4))
                            }
                        }
                }
                
                if !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
                
                HStack(spacing: 16) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                    
                    Button(action: setupPIN) {
                        Text("Set PIN")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidPIN ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!isValidPIN)
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
    
    private var isValidPIN: Bool {
        newPIN.count == 4 && confirmPIN.count == 4 && newPIN == confirmPIN
    }
    
    private func setupPIN() {
        if newPIN != confirmPIN {
            error = "PINs don't match"
            return
        }
        
        if authService.setTeacherPIN(newPIN) {
            isPresented = false
        } else {
            error = authService.authError
        }
    }
}

// MARK: - Change PIN Overlay

struct ChangePINOverlay: View {
    @Binding var isPresented: Bool
    @ObservedObject var authService: FirebaseAuthService
    
    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var error = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Change PIN")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    SecureField("Current PIN", text: $currentPIN)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .onChange(of: currentPIN) { newValue in
                            if newValue.count > 4 {
                                currentPIN = String(newValue.prefix(4))
                            }
                        }
                    
                    SecureField("New PIN", text: $newPIN)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .onChange(of: newPIN) { newValue in
                            if newValue.count > 4 {
                                newPIN = String(newValue.prefix(4))
                            }
                        }
                    
                    SecureField("Confirm New PIN", text: $confirmPIN)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .onChange(of: confirmPIN) { newValue in
                            if newValue.count > 4 {
                                confirmPIN = String(newValue.prefix(4))
                            }
                        }
                }
                
                if !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
                
                HStack(spacing: 16) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                    
                    Button(action: changePIN) {
                        Text("Change PIN")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidInput ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!isValidInput)
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
    
    private var isValidInput: Bool {
        currentPIN.count == 4 && newPIN.count == 4 && confirmPIN.count == 4 && newPIN == confirmPIN
    }
    
    private func changePIN() {
        if newPIN != confirmPIN {
            error = "New PINs don't match"
            return
        }
        
        if authService.changeTeacherPIN(currentPIN: currentPIN, newPIN: newPIN) {
            isPresented = false
        } else {
            error = authService.authError
        }
    }
}

// MARK: - Animated Purple Gradient Background

struct AnimatedPurpleGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.5, green: 0.3, blue: 0.8),
                Color(red: 0.3, green: 0.4, blue: 0.9),
                Color(red: 0.6, green: 0.35, blue: 0.85)
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

#Preview {
    TeacherLoginView()
        .environmentObject(AppViewModel())
}


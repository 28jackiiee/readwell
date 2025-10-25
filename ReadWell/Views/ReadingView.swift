import SwiftUI
import AVFoundation

struct ReadingView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var ttsService = TextToSpeechService()
    
    @State private var fontSize: CGFloat = 20
    @State private var lineSpacing: CGFloat = 1.8
    @State private var backgroundColor: Color = .beigeBackground
    @State private var showSettings = false
    @State private var animatePlay = false
    
    private let colorOptions = [
        ColorOption(color: .beigeBackground, name: "Beige"),
        ColorOption(color: .creamBackground, name: "Cream"),
        ColorOption(color: .white, name: "White"),
        ColorOption(color: .lightBlueBackground, name: "Blue")
    ]
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [backgroundColor, backgroundColor.opacity(0.9)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                topBar
                
                // Reading Progress Card
                if ttsService.isSpeaking {
                    progressCard
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Main Reading Area
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let text = appViewModel.currentText {
                            // Title with enhanced styling
                            Text(text.title ?? "")
                                .font(.system(size: fontSize + 8, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.bottom, 8)
                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            
                            Divider()
                                .padding(.bottom, 12)
                            
                            // Main Text Content with card background
                            Text(text.content ?? "")
                                .font(.system(size: fontSize, weight: .regular, design: .default))
                                .lineSpacing(lineSpacing * fontSize)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.85))
                            .shadow(color: .black.opacity(0.08), radius: 15, y: 5)
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .padding(.bottom, 100) // Extra padding for bottom controls
                }
                
                Spacer()
            }
            
            // Bottom Control Bar - Always visible
            VStack {
                Spacer()
                bottomControls
            }
            
            // Settings Overlay
            if showSettings {
                settingsOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            // Ensure audio stops when view disappears
            ttsService.stop()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSettings)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: ttsService.isSpeaking)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: 16) {
            // Back Button with enhanced design
            Button(action: {
                ttsService.stop()
                appViewModel.goBack()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            
            Spacer()
            
            // Title indicator
            Text("Read Aloud Practice")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary.opacity(0.8))
            
            Spacer()
            
            // Settings Button with enhanced design
            Button(action: { 
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showSettings.toggle()
                }
            }) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.98))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        )
    }
    
    // MARK: - Progress Card
    
    private var progressCard: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text("Reading aloud...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(ttsService.getProgress() * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.15))
                    )
            }
            
            // Enhanced progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(ttsService.getProgress()))
                        .animation(.linear(duration: 0.3), value: ttsService.getProgress())
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 3)
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 0) {
            // Control Panel
            HStack(spacing: 20) {
                // Main Play/Pause Button - Large and prominent
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        animatePlay.toggle()
                    }
                    
                    if ttsService.isSpeaking {
                        ttsService.pause()
                    } else {
                        if let text = appViewModel.currentText?.content {
                            ttsService.speak(text: text, language: "en-US")
                            if let session = appViewModel.currentReadingSession {
                                session.usedTTS = true
                                try? appViewModel.viewContext?.save()
                            }
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .shadow(color: .blue.opacity(0.4), radius: 10, y: 5)
                        
                        Image(systemName: ttsService.isSpeaking ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(animatePlay ? 1.1 : 1.0)
                    }
                }
                
                // Speed Control Card
                VStack(spacing: 8) {
                    Text("Speed")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 10) {
                        Button(action: { 
                            ttsService.adjustSpeed(rate: max(0.1, ttsService.speechRate - 0.1))
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                        }
                        
                        Text(String(format: "%.1f×", ttsService.speechRate))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 50)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        
                        Button(action: { 
                            ttsService.adjustSpeed(rate: min(1.0, ttsService.speechRate + 0.1))
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                )
                
                Spacer()
                
                // Done Reading Button - Enhanced
                Button(action: {
                    ttsService.stop()
                    appViewModel.completeReading()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.98))
                .shadow(color: .black.opacity(0.12), radius: 15, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Settings Overlay
    
    private var settingsOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showSettings = false
                    }
                }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "textformat")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Text("Reading Settings")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showSettings = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .padding(.bottom, 24)
                
                // Settings Content
                VStack(spacing: 28) {
                    // Font Size
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "textformat.size")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Font Size")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(Int(fontSize)) pt")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.1))
                                )
                        }
                        
                        Slider(value: $fontSize, in: 14...32, step: 2)
                            .tint(.blue)
                            .padding(.horizontal, 4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.05))
                    )
                    
                    // Line Spacing
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Line Spacing")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(String(format: "%.1fx", lineSpacing))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.1))
                                )
                        }
                        
                        Slider(value: $lineSpacing, in: 1.0...3.0, step: 0.2)
                            .tint(.blue)
                            .padding(.horizontal, 4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.05))
                    )
                    
                    // Background Color
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "paintpalette")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Background Color")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        HStack(spacing: 20) {
                            ForEach(colorOptions) { option in
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Circle()
                                                .stroke(backgroundColor == option.color ? Color.blue : Color.gray.opacity(0.2), lineWidth: backgroundColor == option.color ? 4 : 2)
                                        )
                                        .shadow(color: backgroundColor == option.color ? Color.blue.opacity(0.3) : Color.clear, radius: 8, y: 2)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                backgroundColor = option.color
                                            }
                                        }
                                    
                                    Text(option.name)
                                        .font(.system(size: 12, weight: backgroundColor == option.color ? .semibold : .regular))
                                        .foregroundColor(backgroundColor == option.color ? .blue : .secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.05))
                    )
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showSettings = false
                        }
                    }) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    
                    Button(action: {
                        saveSettings()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showSettings = false
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                            Text("Save")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                    }
                }
                .padding(.top, 24)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 30, y: 10)
            )
            .frame(maxWidth: 450)
            .padding(24)
        }
    }
    
    // MARK: - Helper Functions
    
    private func saveSettings() {
        guard let student = appViewModel.currentStudent else { return }
        
        student.fontSize = Int16(fontSize)
        student.lineSpacing = lineSpacing
        
        // Save background color as string
        if backgroundColor == .beigeBackground {
            student.backgroundColor = "beige"
        } else if backgroundColor == .creamBackground {
            student.backgroundColor = "cream"
        } else if backgroundColor == .white {
            student.backgroundColor = "white"
        } else {
            student.backgroundColor = "lightBlue"
        }
        
        try? appViewModel.viewContext?.save()
    }
}

// MARK: - Color Extensions

extension Color {
    static let beigeBackground = Color(red: 0.96, green: 0.94, blue: 0.88)
    static let creamBackground = Color(red: 1.0, green: 0.99, blue: 0.95)
    static let lightBlueBackground = Color(red: 0.95, green: 0.97, blue: 1.0)
}

// MARK: - Helper Structs

struct ColorOption: Identifiable {
    let id = UUID()
    let color: Color
    let name: String
}

#Preview {
    ReadingView()
        .environmentObject(AppViewModel())
}


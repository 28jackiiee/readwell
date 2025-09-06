import SwiftUI
import AVFoundation

struct GuidedTalkView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var timeRemaining: TimeInterval = 300 // 5 minutes
    @State private var currentPromptIndex = 0
    @State private var showPrompt = false
    @State private var timer: Timer?
    @State private var promptTimer: Timer?
    
    private let prompts = [
        "What actually mattered today?",
        "If tomorrow went well, what changed?",
        "One tiny thing you'll do in 24 hours?"
    ]
    
    private let promptTimes: [TimeInterval] = [90, 180, 270] // When to show each prompt
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with timer
            VStack(spacing: 10) {
                Text("Daily Check-in")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Circular progress timer
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(1 - (timeRemaining / 300)))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)
                    
                    VStack {
                        Text(timeString(from: timeRemaining))
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 20)
            
            // Current prompt (when active)
            if showPrompt && currentPromptIndex < prompts.count {
                VStack(spacing: 15) {
                    Text("💭")
                        .font(.system(size: 40))
                    
                    Text(prompts[currentPromptIndex])
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    // Auto-hide prompt after 10 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        withAnimation {
                            showPrompt = false
                        }
                    }
                }
            }
            
            Spacer()
            
            // Live captions area
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if speechService.transcript.isEmpty {
                        Text("Start speaking... I'm listening 👂")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Text(speechService.transcript)
                            .font(.body)
                            .opacity(Double(speechService.currentWordConfidence))
                            .animation(.easeInOut(duration: 0.3), value: speechService.currentWordConfidence)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(maxHeight: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
            .padding(.horizontal)
            
            Spacer()
            
            // Recording indicator and controls
            VStack(spacing: 20) {
                // Recording status
                if speechService.isRecording {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: speechService.isRecording)
                        
                        Text("Recording...")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                } else {
                    Text("Tap to continue or finish")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Control buttons
                HStack(spacing: 30) {
                    Button(action: {
                        finishSession()
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            Text("Finish")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Main record/pause button
                    Button(action: {
                        toggleRecording()
                    }) {
                        Circle()
                            .fill(speechService.isRecording ? Color.red : Color.blue)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: speechService.isRecording ? "pause.fill" : "mic.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Button(action: {
                        // Handle settings or help
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: "questionmark.circle")
                                .font(.title)
                                .foregroundColor(.gray)
                            Text("Help")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(.bottom, 50)
        }
        .onAppear {
            startSession()
        }
        .onDisappear {
            stopSession()
        }
    }
    
    private func startSession() {
        // Start the main timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                checkForPrompts()
            } else {
                finishSession()
            }
        }
        
        // Start recording
        if speechService.isAuthorized {
            toggleRecording()
        }
    }
    
    private func stopSession() {
        timer?.invalidate()
        promptTimer?.invalidate()
        speechService.stopRecording()
    }
    
    private func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            do {
                try speechService.startRecording()
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
    }
    
    private func checkForPrompts() {
        let elapsed = 300 - timeRemaining
        
        for (index, promptTime) in promptTimes.enumerated() {
            if elapsed >= promptTime && currentPromptIndex == index && !showPrompt {
                showPrompt(at: index)
                break
            }
        }
    }
    
    private func showPrompt(at index: Int) {
        currentPromptIndex = index
        withAnimation(.easeInOut(duration: 0.5)) {
            showPrompt = true
        }
        
        // Play gentle chime (if available)
        AudioServicesPlaySystemSound(1016)
    }
    
    private func finishSession() {
        stopSession()
        
        // Save transcript to current session
        appViewModel.currentSession?.transcript = speechService.transcript
        appViewModel.currentSession?.duration = 300 - timeRemaining
        
        appViewModel.completeSession()
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    GuidedTalkView()
        .environmentObject(AppViewModel())
}

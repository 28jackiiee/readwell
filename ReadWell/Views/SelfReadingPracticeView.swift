import SwiftUI
import Speech

struct SelfReadingPracticeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var speechService = SpeechRecognitionService()
    
    @State private var wordMatches: [WordMatch] = []
    @State private var currentWordIndex = 0
    @State private var showInstructions = true
    @State private var practiceComplete = false
    @State private var showDebugInfo = true  // Show transcript for debugging
    
    private var textWords: [String] {
        guard let content = appViewModel.currentText?.content else { return [] }
        return content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
    }
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [Color.beigeBackground, Color.beigeBackground.opacity(0.9)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                topBar
                
                if showInstructions {
                    // Instructions overlay
                    instructionsView
                } else if practiceComplete {
                    // Completion view
                    completionView
                } else {
                    // Main reading practice area
                    VStack(spacing: 0) {
                        // Progress bar
                        progressBar
                        
                        // Text display with color coding
                        ScrollView {
                            textDisplayView
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                                .padding(.bottom, 100) // Extra padding for bottom controls
                        }
                        
                        Spacer()
                    }
                    
                    // Recording controls - Always at bottom
                    VStack {
                        Spacer()
                        recordingControls
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            initializeWordMatches()
            // Request authorization if not already authorized
            if !speechService.isAuthorized {
                speechService.requestAuthorization()
            }
        }
        .onDisappear {
            if speechService.isRecording {
                speechService.stopRecording()
            }
        }
        .onChange(of: speechService.transcript) { oldValue, newValue in
            print("🔄 Transcript changed from '\(oldValue)' to '\(newValue)'")
            if !newValue.isEmpty {
                updateWordMatches(transcript: newValue)
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: 16) {
            // Back Button with enhanced design
            Button(action: {
                if speechService.isRecording {
                    speechService.stopRecording()
                }
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
            
            Text("Read Aloud Practice")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary.opacity(0.8))
            
            Spacer()
            
            // Invisible spacer for balance
            Color.clear
                .frame(width: 80)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.98))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        )
    }
    
    // MARK: - Instructions View
    
    private var instructionsView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 16) {
                Text("Read the Text Aloud")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 16) {
                    InstructionRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        text: "Words you read correctly will turn green"
                    )
                    
                    InstructionRow(
                        icon: "xmark.circle.fill",
                        color: .red,
                        text: "Words you read incorrectly will turn red"
                    )
                    
                    InstructionRow(
                        icon: "mic.fill",
                        color: .blue,
                        text: "Tap the play button to start reading"
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.08), radius: 15, y: 5)
                )
            }
            .padding(.horizontal, 30)
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showInstructions = false
                }
            }) {
                HStack(spacing: 10) {
                    Text("Start Practice")
                        .font(.system(size: 18, weight: .semibold))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.85)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        let matchedWords = wordMatches.filter { $0.status != .unmatched }.count
        let progress = textWords.isEmpty ? 0.0 : Double(matchedWords) / Double(textWords.count)
        
        return VStack(spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text("\(matchedWords) of \(textWords.count) words read")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
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
                        .frame(width: geometry.size.width * CGFloat(progress))
                        .animation(.linear(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
        )
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    // MARK: - Text Display View
    
    private var textDisplayView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let title = appViewModel.currentText?.title {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                
                Divider()
                    .padding(.bottom, 8)
            }
            
            // Display text with color coding
            createColorCodedText()
                .lineSpacing(12)
            
            // Show current transcript for debugging
            if showDebugInfo && !speechService.transcript.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("You said:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if speechService.isRecording {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("Recording")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Text(speechService.transcript)
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.08))
                        )
                    
                    // Show match statistics
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("\(wordMatches.filter { $0.status == .correct }.count) correct")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("\(wordMatches.filter { $0.status == .incorrect }.count) incorrect")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 12)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.08), radius: 15, y: 5)
        )
    }
    
    private func createColorCodedText() -> Text {
        var result = Text("")
        
        for match in wordMatches {
            let color = colorForStatus(match.status)
            let weight: Font.Weight = match.status == .unmatched ? .regular : .bold
            
            result = result + Text(match.word + " ")
                .foregroundColor(color)
                .fontWeight(weight)
                .font(.system(size: 22))
        }
        
        return result
    }
    
    private func colorForStatus(_ status: WordMatchStatus) -> Color {
        switch status {
        case .correct:
            return .green
        case .incorrect:
            return .red
        case .unmatched:
            return .primary
        }
    }
    
    // MARK: - Recording Controls
    
    private var recordingControls: some View {
        VStack(spacing: 0) {
            // Microphone status indicator
            if speechService.isRecording {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .opacity(0.8)
                    
                    Text("Listening...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(.bottom, 16)
            }
            
            HStack(spacing: 24) {
                // Microphone button - Large and prominent
                Button(action: {
                    toggleRecording()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: speechService.isRecording ? [Color.red, Color.red.opacity(0.8)] : [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: (speechService.isRecording ? Color.red : Color.blue).opacity(0.4), radius: 12, y: 6)
                        
                        Image(systemName: speechService.isRecording ? "stop.fill" : "play.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(!speechService.isAuthorized)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(speechService.isRecording ? "Stop Recording" : "Start Reading")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(speechService.isRecording ? "Tap to stop" : "Tap to begin")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Finish button - Enhanced
                Button(action: {
                    if speechService.isRecording {
                        speechService.stopRecording()
                    }
                    withAnimation {
                        practiceComplete = true
                    }
                }) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.85)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                                .shadow(color: .green.opacity(0.4), radius: 10, y: 5)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Finish")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            
            // Authorization message
            if !speechService.isAuthorized {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Please enable microphone and speech recognition in Settings")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .multilineTextAlignment(.center)
            }
        }
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.98))
                .shadow(color: .black.opacity(0.12), radius: 15, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        let correctCount = wordMatches.filter { $0.status == .correct }.count
        let incorrectCount = wordMatches.filter { $0.status == .incorrect }.count
        let totalRead = correctCount + incorrectCount
        let accuracy = totalRead > 0 ? Double(correctCount) / Double(totalRead) * 100 : 0
        
        return VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Great Job!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                StatRow(label: "Words Read", value: "\(totalRead) / \(textWords.count)")
                StatRow(label: "Correct", value: "\(correctCount)", color: .green)
                StatRow(label: "Needs Practice", value: "\(incorrectCount)", color: .orange)
                if totalRead > 0 {
                    StatRow(label: "Accuracy", value: String(format: "%.1f%%", accuracy), color: .blue)
                }
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            .padding(.horizontal, 40)
            
            VStack(spacing: 16) {
                Button(action: {
                    saveReadingData(correctCount: correctCount, incorrectCount: incorrectCount)
                    appViewModel.currentView = .comprehensionCheck
                }) {
                    Text("Continue to Comprehension")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    // Retry - reset all matches
                    initializeWordMatches()
                    speechService.clearTranscript()
                    withAnimation {
                        practiceComplete = false
                    }
                }) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions
    
    private func initializeWordMatches() {
        wordMatches = textWords.map { WordMatch(word: $0, status: .unmatched) }
        currentWordIndex = 0
        print("📚 Initialized \(wordMatches.count) words for tracking")
        print("📖 First few words: \(textWords.prefix(10).joined(separator: ", "))")
    }
    
    private func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            do {
                try speechService.startRecording()
            } catch {
                print("Error starting recording: \(error)")
            }
        }
    }
    
    private func updateWordMatches(transcript: String) {
        // Clean up the transcript
        let spokenWords = transcript.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
        
        print("🎤 Transcript: '\(transcript)'")
        print("📝 Spoken words: \(spokenWords)")
        print("📖 Text words count: \(textWords.count)")
        
        // Reset all matches that haven't been confirmed yet
        // Only reset if we have new spoken words
        guard !spokenWords.isEmpty else { return }
        
        // Match spoken words with text words using a sliding window approach
        var spokenIndex = 0
        var textIndex = 0
        
        while textIndex < textWords.count && spokenIndex < spokenWords.count {
            let textWord = textWords[textIndex].lowercased()
            let spokenWord = spokenWords[spokenIndex]
            
            print("🔍 Comparing text[\(textIndex)]='\(textWord)' with spoken[\(spokenIndex)]='\(spokenWord)'")
            
            // Check for exact or similar match
            if textWord == spokenWord {
                print("✅ Exact match!")
                wordMatches[textIndex].status = .correct
                textIndex += 1
                spokenIndex += 1
            } else if isSimilarWord(textWord, spokenWord) {
                print("✅ Similar match!")
                wordMatches[textIndex].status = .correct
                textIndex += 1
                spokenIndex += 1
            } else {
                // Look ahead in spoken words to see if we can find the text word
                var foundAhead = false
                for lookAhead in (spokenIndex + 1)..<min(spokenIndex + 3, spokenWords.count) {
                    if textWord == spokenWords[lookAhead] || isSimilarWord(textWord, spokenWords[lookAhead]) {
                        print("⚠️ Found match ahead at spoken[\(lookAhead)]")
                        // Mark current text word as skipped/incorrect
                        wordMatches[textIndex].status = .incorrect
                        foundAhead = true
                        break
                    }
                }
                
                if foundAhead {
                    // Move to next text word, but don't advance spoken index
                    textIndex += 1
                } else {
                    // Look ahead in text words to see if spoken word matches later
                    var foundLater = false
                    for lookAhead in (textIndex + 1)..<min(textIndex + 3, textWords.count) {
                        if textWords[lookAhead].lowercased() == spokenWord || isSimilarWord(textWords[lookAhead].lowercased(), spokenWord) {
                            print("⚠️ Spoken word matches text[\(lookAhead)]")
                            foundLater = true
                            break
                        }
                    }
                    
                    if foundLater {
                        // Student skipped this word
                        print("❌ Word skipped/incorrect")
                        wordMatches[textIndex].status = .incorrect
                        textIndex += 1
                    } else {
                        // Mispronounced or wrong word
                        print("❌ No match - marking incorrect")
                        wordMatches[textIndex].status = .incorrect
                        textIndex += 1
                        spokenIndex += 1
                    }
                }
            }
        }
        
        print("📊 Match status updated. Correct: \(wordMatches.filter { $0.status == .correct }.count), Incorrect: \(wordMatches.filter { $0.status == .incorrect }.count)")
    }
    
    private func isSimilarWord(_ word1: String, _ word2: String) -> Bool {
        // Check for common variations and similar words
        // Use a more lenient threshold for better matching
        let threshold = 0.7
        let distance = levenshteinDistance(word1, word2)
        let maxLength = max(word1.count, word2.count)
        
        guard maxLength > 0 else { return false }
        
        let similarity = 1.0 - (Double(distance) / Double(maxLength))
        let isSimilar = similarity >= threshold
        
        if isSimilar {
            print("🔄 Similar words: '\(word1)' ≈ '\(word2)' (similarity: \(String(format: "%.2f", similarity)))")
        }
        
        return isSimilar
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let str1Array = Array(str1)
        let str2Array = Array(str2)
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: str2Array.count + 1), count: str1Array.count + 1)
        
        for i in 0...str1Array.count {
            matrix[i][0] = i
        }
        
        for j in 0...str2Array.count {
            matrix[0][j] = j
        }
        
        for i in 1...str1Array.count {
            for j in 1...str2Array.count {
                if str1Array[i-1] == str2Array[j-1] {
                    matrix[i][j] = matrix[i-1][j-1]
                } else {
                    matrix[i][j] = min(
                        matrix[i-1][j] + 1,      // deletion
                        matrix[i][j-1] + 1,      // insertion
                        matrix[i-1][j-1] + 1     // substitution
                    )
                }
            }
        }
        
        return matrix[str1Array.count][str2Array.count]
    }
    
    private func saveReadingData(correctCount: Int, incorrectCount: Int) {
        guard let session = appViewModel.currentReadingSession else { return }
        
        // Store oral reading data
        session.oralReadingAccuracy = Double(correctCount) / Double(max(1, correctCount + incorrectCount)) * 100.0
        session.wordsReadCorrectly = Int16(correctCount)
        session.wordsReadIncorrectly = Int16(incorrectCount)
        
        do {
            try appViewModel.viewContext?.save()
        } catch {
            print("Error saving reading data: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct InstructionRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Data Models

struct WordMatch {
    let word: String
    var status: WordMatchStatus
}

enum WordMatchStatus {
    case unmatched
    case correct
    case incorrect
}

#Preview {
    SelfReadingPracticeView()
        .environmentObject(AppViewModel())
}


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
    @State private var animateRecord = false
    
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
                gradient: Gradient(colors: [
                    Color(red: 0.96, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.96, blue: 0.94)
                ]),
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
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if practiceComplete {
                    // Completion view
                    completionView
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Main reading practice area
                    VStack(spacing: 0) {
                        // Progress bar
                        progressBar
                        
                        // Text display with color coding
                        ScrollView {
                            textDisplayView
                                .padding(20)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Recording controls - Always visible when not in instructions or completion
            if !showInstructions && !practiceComplete {
                VStack {
                    Spacer()
                    recordingControls
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showInstructions)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: practiceComplete)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: speechService.isRecording)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: 16) {
            // Back Button
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
            
            // Title with icon
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
                Text("Read Aloud Practice")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
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
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 90))
                    .foregroundColor(.blue)
                    .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
            }
            
            VStack(spacing: 16) {
                Text("Read the Text Aloud")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Your reading will be tracked as you speak")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            
            VStack(spacing: 16) {
                InstructionRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    text: "Correct words turn green"
                )
                
                InstructionRow(
                    icon: "exclamationmark.circle.fill",
                    color: .orange,
                    text: "Incorrect words turn orange"
                )
                
                InstructionRow(
                    icon: "mic.fill",
                    color: .blue,
                    text: "Tap microphone to start/stop"
                )
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 15, y: 5)
            )
            .padding(.horizontal, 30)
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showInstructions = false
                }
            }) {
                HStack(spacing: 10) {
                    Text("Start Practice")
                        .font(.system(size: 19, weight: .bold))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 22))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.4), radius: 15, y: 8)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        let matchedWords = wordMatches.filter { $0.status != .unmatched }.count
        let progress = textWords.isEmpty ? 0.0 : Double(matchedWords) / Double(textWords.count)
        let correctWords = wordMatches.filter { $0.status == .correct }.count
        let incorrectWords = wordMatches.filter { $0.status == .incorrect }.count
        
        return VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progress))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 8)
            
            // Stats
            HStack {
                Image(systemName: "text.word.spacing")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                
                Text("\(matchedWords) of \(textWords.count) words read")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("\(correctWords)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("\(incorrectWords)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - Text Display View
    
    private var textDisplayView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let title = appViewModel.currentText?.title {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                
                Divider()
                    .padding(.bottom, 8)
            }
            
            // Display text with color coding
            createColorCodedText()
                .lineSpacing(12)
            
            // Show current transcript for debugging
            if showDebugInfo && !speechService.transcript.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "waveform")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        
                        Text("Live Transcript")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if speechService.isRecording {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("Recording")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                    }
                    
                    Text(speechService.transcript)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.08))
                        )
                }
                .padding(.top, 12)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.08), radius: 15, y: 5)
        )
        .padding(.bottom, 120) // Extra padding for fixed bottom controls
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
            return .orange
        case .unmatched:
            return .primary
        }
    }
    
    // MARK: - Recording Controls
    
    private var recordingControls: some View {
        VStack(spacing: 0) {
            // Control Panel
            HStack(spacing: 20) {
                // Main Microphone Button - Large and prominent
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        animateRecord.toggle()
                    }
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
                            .frame(width: 70, height: 70)
                            .shadow(color: (speechService.isRecording ? Color.red : Color.blue).opacity(0.4), radius: 10, y: 5)
                        
                        Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(animateRecord ? 1.1 : 1.0)
                    }
                }
                .disabled(!speechService.isAuthorized)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(speechService.isRecording ? "Recording..." : "Start Reading")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if speechService.isRecording {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("Listening to you speak")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Tap to begin")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Finish Button - Enhanced
                Button(action: {
                    if speechService.isRecording {
                        speechService.stopRecording()
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        practiceComplete = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("Finish")
                            .font(.system(size: 17, weight: .semibold))
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
            
            // Authorization message
            if !speechService.isAuthorized {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    
                    Text("Please enable microphone and speech recognition in Settings")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
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
        
        return VStack(spacing: 32) {
            Spacer()
            
            // Success Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 90))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
            }
            
            VStack(spacing: 12) {
                Text("Great Job!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("You've completed the reading practice")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            // Stats Cards
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ReadingStatCard(
                        icon: "text.word.spacing",
                        color: .blue,
                        value: "\(totalRead)/\(textWords.count)",
                        label: "Words Read"
                    )
                    
                    ReadingStatCard(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        value: "\(correctCount)",
                        label: "Correct"
                    )
                }
                
                HStack(spacing: 16) {
                    ReadingStatCard(
                        icon: "exclamationmark.circle.fill",
                        color: .orange,
                        value: "\(incorrectCount)",
                        label: "To Practice"
                    )
                    
                    if totalRead > 0 {
                        ReadingStatCard(
                            icon: "chart.line.uptrend.xyaxis",
                            color: .purple,
                            value: String(format: "%.0f%%", accuracy),
                            label: "Accuracy"
                        )
                    }
                }
            }
            .padding(.horizontal, 30)
            
            VStack(spacing: 12) {
                // Continue Button
                Button(action: {
                    saveReadingData(correctCount: correctCount, incorrectCount: incorrectCount)
                    appViewModel.currentView = .comprehensionCheck
                }) {
                    HStack(spacing: 10) {
                        Text("Continue to Comprehension")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.4), radius: 15, y: 8)
                }
                
                // Try Again Button
                Button(action: {
                    // Retry - reset all matches
                    initializeWordMatches()
                    speechService.clearTranscript()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        practiceComplete = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                        Text("Try Again")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    )
                }
            }
            .padding(.horizontal, 30)
            
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
                .font(.system(size: 15))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct ReadingStatCard: View {
    let icon: String
    let color: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        )
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


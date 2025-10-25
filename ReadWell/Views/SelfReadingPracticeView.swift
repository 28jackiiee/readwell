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
            Color.beigeBackground.ignoresSafeArea()
            
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
                    VStack(spacing: 20) {
                        // Progress bar
                        progressBar
                        
                        // Text display with color coding
                        ScrollView {
                            textDisplayView
                                .padding()
                        }
                        
                        // Recording controls
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
        HStack {
            Button(action: {
                if speechService.isRecording {
                    speechService.stopRecording()
                }
                appViewModel.goBack()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding()
            }
            
            Text("Read Aloud Practice")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color.white.opacity(0.95))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    // MARK: - Instructions View
    
    private var instructionsView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Read the Text Aloud")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
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
                        text: "Tap the microphone to start reading"
                    )
                }
                .padding()
                .background(Color.white.opacity(0.7))
                .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            
            Button(action: {
                withAnimation {
                    showInstructions = false
                }
            }) {
                Text("Start Practice")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        let matchedWords = wordMatches.filter { $0.status != .unmatched }.count
        let progress = textWords.isEmpty ? 0.0 : Double(matchedWords) / Double(textWords.count)
        
        return VStack(spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 8)
            
            Text("\(matchedWords) of \(textWords.count) words read")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    // MARK: - Text Display View
    
    private var textDisplayView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let title = appViewModel.currentText?.title {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
            }
            
            // Display text with color coding
            createColorCodedText()
                .lineSpacing(10)
            
            // Show current transcript for debugging
            if showDebugInfo && !speechService.transcript.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("You said:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if speechService.isRecording {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("Recording")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Text(speechService.transcript)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    // Show match statistics
                    HStack {
                        Label("\(wordMatches.filter { $0.status == .correct }.count) correct", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        
                        Label("\(wordMatches.filter { $0.status == .incorrect }.count) incorrect", systemImage: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
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
        VStack(spacing: 16) {
            // Microphone status indicator
            if speechService.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .opacity(0.8)
                    
                    Text("Listening...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 30) {
                // Microphone button
                Button(action: {
                    toggleRecording()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: speechService.isRecording ? "mic.fill" : "mic.slash.fill")
                            .font(.system(size: 44))
                            .foregroundColor(speechService.isRecording ? .red : .blue)
                        
                        Text(speechService.isRecording ? "Stop" : "Start Reading")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!speechService.isAuthorized)
                
                // Finish button
                Button(action: {
                    if speechService.isRecording {
                        speechService.stopRecording()
                    }
                    withAnimation {
                        practiceComplete = true
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.green)
                        
                        Text("Finish")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Authorization message
            if !speechService.isAuthorized {
                Text("Please enable microphone and speech recognition in Settings")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.95))
        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
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


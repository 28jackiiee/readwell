import Speech
import AVFoundation
import Foundation

@MainActor
class SpeechRecognitionService: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var isAuthorized = false
    @Published var currentWordConfidence: Float = 0.0
    @Published var lastError: String = ""
    @Published var debugInfo: String = ""
    
    // Backup transcript to prevent loss
    private var backupTranscript = ""
    // Session transcript to maintain across pause/resume cycles
    private var sessionTranscript = ""
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        requestAuthorization()
        validateSpeechRecognizer()
    }
    
    private func validateSpeechRecognizer() {
        guard let recognizer = speechRecognizer else {
            debugInfo = "Speech recognizer failed to initialize"
            return
        }
        
        if !recognizer.isAvailable {
            debugInfo = "Speech recognizer not available (check internet)"
        } else {
            debugInfo = "Speech recognizer ready"
        }
        
        // Check if the locale is supported
        if recognizer.locale.identifier != "en-US" {
            debugInfo = "Locale mismatch: \(recognizer.locale.identifier)"
        }
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.isAuthorized = true
                case .denied, .restricted, .notDetermined:
                    self.isAuthorized = false
                @unknown default:
                    self.isAuthorized = false
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            DispatchQueue.main.async {
                // Handle microphone permission
            }
        }
    }
    
    func startRecording() throws {
        lastError = ""
        debugInfo = "Starting recording..."
        
        // Check if speech recognizer is available
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            lastError = "Speech recognizer not available"
            debugInfo = "Speech recognizer unavailable"
            throw RecognitionError.recognitionRequestFailed
        }
        
        // When resuming, keep the session transcript and build upon it
        if !sessionTranscript.isEmpty {
            debugInfo = "Resuming recording with existing transcript"
        }
        
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            debugInfo = "Audio session configured"
        } catch {
            lastError = "Audio session error: \(error.localizedDescription)"
            debugInfo = "Audio session failed"
            throw error
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            lastError = "Recognition request creation failed"
            debugInfo = "Request creation failed"
            throw RecognitionError.recognitionRequestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        debugInfo = "Recognition request created"
        
        // Create audio input node
        let inputNode = audioEngine.inputNode
        
        // Create recognition task
        debugInfo = "Creating recognition task..."
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            lastError = "Speech recognizer not available"
            debugInfo = "Speech recognizer unavailable for recognition"
            throw RecognitionError.recognitionRequestFailed
        }
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Recognition error: \(error.localizedDescription)")
                    print("📝 Transcript at error time: '\(self.transcript)'")
                    self.lastError = "Recognition error: \(error.localizedDescription)"
                    self.debugInfo = "Recognition failed"
                    // Don't clear transcript on error - keep what we have
                    return
                }
                
                if let result = result {
                    let newTranscript = result.bestTranscription.formattedString
                    
                    // Build the full transcript: session + current segment
                    let fullTranscript = self.sessionTranscript.isEmpty ? newTranscript : self.sessionTranscript + " " + newTranscript
                    
                    // Only update transcript if we have meaningful content or it's longer than current
                    if !fullTranscript.isEmpty || fullTranscript.count >= self.transcript.count {
                        print("🔄 Updating transcript from '\(self.transcript)' to '\(fullTranscript)'")
                        self.transcript = fullTranscript
                        // Back up non-empty transcripts
                        if !fullTranscript.isEmpty {
                            self.backupTranscript = fullTranscript
                        }
                    } else {
                        print("🚫 Ignoring empty/shorter transcript update. Keeping: '\(self.transcript)'")
                        // If we're getting empty updates but have a backup, restore it
                        if !self.backupTranscript.isEmpty && self.transcript.isEmpty {
                            print("🔄 Restoring from backup: '\(self.backupTranscript)'")
                            self.transcript = self.backupTranscript
                        }
                    }
                    
                    self.debugInfo = "Recognizing... (\(result.bestTranscription.segments.count) segments)"
                    
                    // Calculate average confidence for live captions
                    let segments = result.bestTranscription.segments
                    if !segments.isEmpty {
                        let totalConfidence = segments.map { $0.confidence }.reduce(0, +)
                        self.currentWordConfidence = totalConfidence / Float(segments.count)
                    }
                    
                    if result.isFinal {
                        self.debugInfo = "Recognition complete"
                        print("✅ Final result received. Transcript: '\(self.transcript)'")
                    }
                } else {
                    print("⚠️ No result received in callback")
                    self.debugInfo = "No result received"
                }
                
                if result?.isFinal == true {
                    // Don't automatically stop recording on final result
                    // Let the user control when to stop
                    self.debugInfo = "Recognition finalized"
                }
            }
        }
        
        guard recognitionTask != nil else {
            lastError = "Failed to create recognition task"
            debugInfo = "Recognition task creation failed"
            throw RecognitionError.recognitionRequestFailed
        }
        
        debugInfo = "Recognition task created successfully"
        
        // Configure audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        debugInfo = "Installing audio tap..."
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
            // Update debug info to show we're receiving audio
            DispatchQueue.main.async {
                self.debugInfo = "Receiving audio data..."
            }
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            debugInfo = "Audio engine started"
        } catch {
            lastError = "Audio engine start failed: \(error.localizedDescription)"
            debugInfo = "Audio engine failed"
            throw RecognitionError.audioEngineFailed
        }
    }
    
    func pauseRecording() {
        print("⏸️ Pausing recording. Current transcript: '\(transcript)'")
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Cancel the task but preserve the transcript
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Save current transcript to session transcript
        sessionTranscript = transcript
        
        isRecording = false
        
        print("⏸️ Paused recording. Session transcript saved: '\(sessionTranscript)'")
        print("📏 Session transcript length: \(sessionTranscript.count)")
    }
    
    func stopRecording() {
        print("🛑 Starting to stop recording. Current transcript: '\(transcript)'")
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Cancel the task but don't let it clear our transcript
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        
        print("🛑 Stopped recording. Final transcript: '\(transcript)'")
        print("📏 Final transcript length: \(transcript.count)")
    }
    
    func clearTranscript() {
        transcript = ""
        backupTranscript = ""
        sessionTranscript = ""
        currentWordConfidence = 0.0
        lastError = ""
        debugInfo = ""
    }
    
    // Get the best available transcript (either current, backup, or session)
    func getBestTranscript() -> String {
        let bestTranscript = !transcript.isEmpty ? transcript : (!backupTranscript.isEmpty ? backupTranscript : sessionTranscript)
        print("📋 Getting best transcript: '\(bestTranscript)'")
        print("📋 Current: '\(transcript)', Backup: '\(backupTranscript)', Session: '\(sessionTranscript)'")
        return bestTranscript
    }
}

enum RecognitionError: Error {
    case recognitionRequestFailed
    case audioEngineFailed
}

extension RecognitionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .recognitionRequestFailed:
            return "Speech recognition request failed"
        case .audioEngineFailed:
            return "Audio engine failed to start"
        }
    }
}

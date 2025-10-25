import AVFoundation
import SwiftUI
import CryptoKit

@MainActor
class TextToSpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    @Published var isSpeaking = false
    @Published var currentWordRange: NSRange?
    @Published var speechRate: Float = 0.5 // Default moderate speed
    @Published var currentSentenceIndex: Int = 0
    
    private let synthesizer = AVSpeechSynthesizer()
    private var sentences: [String] = []
    private var fullText: String = ""
    private var currentUtterance: AVSpeechUtterance?
    private let elevenAPIKey: String
    private var audioPlayer: AVAudioPlayer?
    private var useElevenLabs = true
    private var scheduledWork: DispatchWorkItem?
    private var progressTimer: Timer?
    
    // ElevenLabs default voice ID (Rachel - natural, friendly voice)
    private let defaultVoiceId = "21m00Tcm4TlvDq8ikWAM"
    
    // Cache directory for TTS audio files
    private let cacheDirectory: URL
    
    override init() {
        // Set up cache directory
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.cacheDirectory = documentsDirectory.appendingPathComponent("TTSCache", isDirectory: true)
        
        // Load ElevenLabs API key from Config.plist
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let apiKey = plist["ELEVEN_API_KEY"] as? String, !apiKey.isEmpty {
            print("🔑 Found ElevenLabs API key in Config.plist: \(apiKey.prefix(10))...")
            self.elevenAPIKey = apiKey
            self.useElevenLabs = true
        } else {
            print("⚠️ ELEVEN_API_KEY not found in Config.plist, falling back to native TTS")
            self.elevenAPIKey = ""
            self.useElevenLabs = false
        }
        
        super.init()
        synthesizer.delegate = self
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
                print("📁 Created TTS cache directory at: \(cacheDirectory.path)")
            } catch {
                print("❌ Failed to create cache directory: \(error)")
            }
        } else {
            print("📁 Using existing TTS cache directory at: \(cacheDirectory.path)")
        }
    }
    
    deinit {
        // Clean up when service is deallocated
        scheduledWork?.cancel()
        progressTimer?.invalidate()
        audioPlayer?.stop()
        audioPlayer?.delegate = nil
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Public Methods
    
    func speak(text: String, language: String = "en-US") {
        fullText = text
        sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        currentSentenceIndex = 0
        
        if useElevenLabs {
            print("🎤 Using ElevenLabs TTS - Playing entire passage as one clip")
            speakEntireTextWithElevenLabs(language: language)
        } else {
            print("🎤 Using native iOS TTS")
            speakNextSentence(language: language)
        }
    }
    
    func pause() {
        if isSpeaking {
            if useElevenLabs, let player = audioPlayer {
                player.pause()
                // Pause the timer but don't invalidate it
                progressTimer?.invalidate()
                progressTimer = nil
            } else {
                synthesizer.pauseSpeaking(at: .word)
            }
            isSpeaking = false
        }
    }
    
    func resume() {
        if !isSpeaking {
            if useElevenLabs, let player = audioPlayer {
                player.play()
                // Restart the timer
                startProgressTimer()
            } else {
                synthesizer.continueSpeaking()
            }
            isSpeaking = true
        }
    }
    
    func stop() {
        print("🛑 Stopping TTS playback")
        
        // Cancel any scheduled work
        scheduledWork?.cancel()
        scheduledWork = nil
        
        // Stop progress timer
        progressTimer?.invalidate()
        progressTimer = nil
        
        if useElevenLabs {
            audioPlayer?.stop()
            audioPlayer?.delegate = nil
            audioPlayer = nil
        } else {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        isSpeaking = false
        currentWordRange = nil
        currentSentenceIndex = 0
    }
    
    func adjustSpeed(rate: Float) {
        // Rate: 0.0 (slowest) to 1.0 (fastest)
        // AVSpeechUtteranceDefaultSpeechRate = 0.5
        speechRate = max(0.1, min(1.0, rate))
        
        // If currently speaking, restart with new rate
        if isSpeaking {
            let wasAt = currentSentenceIndex
            stop()
            currentSentenceIndex = wasAt
            speakNextSentence()
        }
    }
    
    func skipToSentence(index: Int) {
        guard index >= 0 && index < sentences.count else { return }
        stop()
        currentSentenceIndex = index
        speakNextSentence()
    }
    
    // MARK: - Cache Methods
    
    private func cacheKey(for text: String) -> String {
        // Generate a hash of the text to use as cache key
        let data = Data(text.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func cachedAudioURL(for text: String) -> URL {
        let key = cacheKey(for: text)
        return cacheDirectory.appendingPathComponent("\(key).mp3")
    }
    
    private func getCachedAudio(for text: String) -> Data? {
        let url = cachedAudioURL(for: text)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("📦 Using cached audio for text: \(text.prefix(50))... (\(data.count) bytes)")
            return data
        } catch {
            print("⚠️ Failed to read cached audio: \(error)")
            return nil
        }
    }
    
    private func saveToCache(audio: Data, for text: String) {
        let url = cachedAudioURL(for: text)
        
        do {
            try audio.write(to: url)
            print("💾 Saved audio to cache: \(url.lastPathComponent) (\(audio.count) bytes)")
        } catch {
            print("⚠️ Failed to save audio to cache: \(error)")
        }
    }
    
    func clearCache() {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
            print("🗑️ Cleared TTS cache (\(files.count) files)")
        } catch {
            print("⚠️ Failed to clear cache: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func speakEntireTextWithElevenLabs(language: String = "en-US") {
        guard !elevenAPIKey.isEmpty else {
            print("❌ No ElevenLabs API key available")
            useElevenLabs = false
            speakNextSentence(language: language)
            return
        }
        
        guard !fullText.isEmpty else {
            print("❌ No text to speak")
            return
        }
        
        Task {
            do {
                print("📝 Generating audio for entire passage (\(fullText.count) characters)...")
                let audioData = try await fetchElevenLabsAudio(text: fullText)
                try await playAudio(data: audioData, isFullPassage: true)
            } catch {
                print("❌ ElevenLabs TTS error: \(error). Falling back to native TTS.")
                useElevenLabs = false
                speakNextSentence(language: language)
            }
        }
    }
    
    private func speakWithElevenLabs(language: String = "en-US") {
        guard !elevenAPIKey.isEmpty else {
            print("❌ No ElevenLabs API key available")
            useElevenLabs = false
            speakNextSentence(language: language)
            return
        }
        
        guard currentSentenceIndex < sentences.count else {
            isSpeaking = false
            return
        }
        
        let textToSpeak = sentences[currentSentenceIndex]
        
        Task {
            do {
                let audioData = try await fetchElevenLabsAudio(text: textToSpeak)
                try await playAudio(data: audioData, isFullPassage: false)
            } catch {
                print("❌ ElevenLabs TTS error: \(error). Falling back to native TTS.")
                useElevenLabs = false
                speakNextSentence(language: language)
            }
        }
    }
    
    private func fetchElevenLabsAudio(text: String) async throws -> Data {
        // Check cache first
        if let cachedData = getCachedAudio(for: text) {
            return cachedData
        }
        
        // If not in cache, fetch from API
        let urlString = "https://api.elevenlabs.io/v1/text-to-speech/\(defaultVoiceId)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "TextToSpeechService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(elevenAPIKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🌐 Fetching audio from ElevenLabs API for text: \(text.prefix(50))...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TextToSpeechService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ ElevenLabs API error (\(httpResponse.statusCode)): \(errorMessage)")
            throw NSError(domain: "TextToSpeechService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        print("✅ Received audio data from API: \(data.count) bytes")
        
        // Save to cache for future use
        saveToCache(audio: data, for: text)
        
        return data
    }
    
    private func playAudio(data: Data, isFullPassage: Bool = false) async throws {
        try await MainActor.run {
            do {
                // Configure audio session for playback
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer?.delegate = self
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
                self.isSpeaking = true
                
                if isFullPassage {
                    print("🔊 Playing entire passage (duration: \(self.audioPlayer?.duration ?? 0)s)")
                    // Mark that we're at the last "sentence" for progress tracking
                    self.currentSentenceIndex = self.sentences.count - 1
                    
                    // Start timer to update progress
                    self.startProgressTimer()
                } else {
                    print("🔊 Playing ElevenLabs audio (duration: \(self.audioPlayer?.duration ?? 0)s)")
                }
                
                // Audio player delegate will handle completion
            } catch {
                print("❌ Error playing audio: \(error)")
                throw error
            }
        }
    }
    
    private func startProgressTimer() {
        // Update progress every 0.1 seconds for smooth animation
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                // Just trigger a refresh by accessing the published property
                self?.objectWillChange.send()
            }
        }
    }
    
    private func speakNextSentence(language: String = "en-US") {
        guard currentSentenceIndex < sentences.count else {
            // Finished reading all sentences
            isSpeaking = false
            currentWordRange = nil
            return
        }
        
        let sentence = sentences[currentSentenceIndex]
        let utterance = AVSpeechUtterance(string: sentence)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = speechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        currentUtterance = utterance
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.currentSentenceIndex += 1
            self.speakNextSentence()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.currentWordRange = characterRange
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentWordRange = nil
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            print("🎵 Audio finished playing")
            // Cancel any scheduled work since audio finished naturally
            self.scheduledWork?.cancel()
            self.scheduledWork = nil
            
            // Stop progress timer
            self.progressTimer?.invalidate()
            self.progressTimer = nil
            
            // When audio finishes, mark as complete
            self.isSpeaking = false
            self.audioPlayer = nil
            print("✅ Finished reading passage")
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            print("❌ Audio player decode error: \(error?.localizedDescription ?? "unknown")")
            self.isSpeaking = false
            self.audioPlayer = nil
        }
    }
    
    // MARK: - Helpers
    
    func getCurrentSentence() -> String? {
        guard currentSentenceIndex < sentences.count else { return nil }
        return sentences[currentSentenceIndex]
    }
    
    func getProgress() -> Double {
        if useElevenLabs {
            // For ElevenLabs, use audio player's current time
            guard let player = audioPlayer, player.duration > 0 else { return 0 }
            return player.currentTime / player.duration
        } else {
            // For native TTS, use sentence progress
            guard !sentences.isEmpty else { return 0 }
            return Double(currentSentenceIndex) / Double(sentences.count)
        }
    }
}


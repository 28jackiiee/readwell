import Foundation
import NaturalLanguage

class NLPService {
    static let shared = NLPService()
    
    private init() {}
    
    // Extract summary bullets from transcript
    func generateSummary(from transcript: String) -> [String] {
        let sentences = extractSentences(from: transcript)
        let keyPhrases = extractKeyPhrases(from: sentences)
        
        // Limit to 3-6 bullets
        let maxBullets = min(6, max(3, keyPhrases.count))
        return Array(keyPhrases.prefix(maxBullets))
    }
    
    // Detect emotions and their intensity
    func detectEmotions(from transcript: String) -> [(emotion: String, intensity: Double, color: String)] {
        let emotionWords = analyzeEmotionalContent(transcript)
        
        var emotions: [(emotion: String, intensity: Double, color: String)] = []
        
        // Map detected emotions to our emotion set
        let emotionMap: [String: (name: String, color: String)] = [
            "happy": ("Happy", "yellow"),
            "joy": ("Happy", "yellow"),
            "excited": ("Excited", "orange"),
            "calm": ("Calm", "blue"),
            "peaceful": ("Calm", "blue"),
            "anxious": ("Anxious", "purple"),
            "worried": ("Anxious", "purple"),
            "sad": ("Sad", "gray"),
            "frustrated": ("Frustrated", "red"),
            "angry": ("Frustrated", "red"),
            "grateful": ("Grateful", "green"),
            "thankful": ("Grateful", "green"),
            "confident": ("Confident", "cyan"),
            "proud": ("Confident", "cyan"),
            "tired": ("Tired", "brown"),
            "exhausted": ("Tired", "brown")
        ]
        
        for (word, intensity) in emotionWords {
            if let mapping = emotionMap[word.lowercased()] {
                emotions.append((emotion: mapping.name, intensity: intensity, color: mapping.color))
            }
        }
        
        // Remove duplicates and sort by intensity
        let uniqueEmotions = Dictionary(grouping: emotions, by: { $0.emotion })
            .compactMapValues { emotionGroup in
                emotionGroup.max(by: { $0.intensity < $1.intensity })
            }
            .values
            .sorted { $0.intensity > $1.intensity }
        
        // Return top 2-3 emotions
        return Array(uniqueEmotions.prefix(3))
    }
    
    // Extract actionable items using SMART criteria
    func extractActions(from transcript: String) -> [String] {
        let sentences = extractSentences(from: transcript)
        var actions: [String] = []
        
        // Look for action indicators
        let actionPatterns = [
            "I will", "I'll", "I should", "I need to", "I want to",
            "tomorrow I", "next I", "plan to", "going to",
            "will do", "will try", "will start"
        ]
        
        for sentence in sentences {
            for pattern in actionPatterns {
                if sentence.lowercased().contains(pattern.lowercased()) {
                    let cleanedAction = cleanAction(sentence)
                    if isValidAction(cleanedAction) {
                        actions.append(cleanedAction)
                    }
                }
            }
        }
        
        // If no explicit actions found, generate from intent
        if actions.isEmpty {
            actions = generateDefaultActions(from: transcript)
        }
        
        // Ensure exactly 3 actions
        while actions.count < 3 {
            actions.append("Reflect on today's experiences")
        }
        
        return Array(actions.prefix(3))
    }
    
    // Generate core theme from transcript
    func extractCoreTheme(from transcript: String) -> String {
        let words = transcript.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "i", "you", "he", "she", "it", "we", "they", "am", "is", "are", "was", "were", "be", "been", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should"])
        
        let significantWords = words
            .map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
            .filter { !stopWords.contains($0) && $0.count > 2 }
        
        let wordFrequency = Dictionary(grouping: significantWords, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        let topWords = Array(wordFrequency.prefix(3)).map { $0.key }
        
        if topWords.count >= 2 {
            return "Focus on \(topWords[0]) and \(topWords[1])"
        } else if topWords.count == 1 {
            return "Thoughts about \(topWords[0])"
        } else {
            return "Personal reflection and growth"
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func extractSentences(from text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let sentence = String(text[tokenRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if sentence.count > 10 { // Filter out very short sentences
                sentences.append(sentence)
            }
            return true
        }
        
        return sentences
    }
    
    private func extractKeyPhrases(from sentences: [String]) -> [String] {
        var keyPhrases: [String] = []
        
        for sentence in sentences {
            // Look for sentences with important indicators
            let importanceIndicators = [
                "important", "matter", "significant", "realize", "learned",
                "feel", "felt", "think", "believe", "understand",
                "accomplish", "achieve", "complete", "finish", "succeed"
            ]
            
            for indicator in importanceIndicators {
                if sentence.lowercased().contains(indicator) {
                    let cleanedPhrase = sentence.trimmingCharacters(in: .punctuationCharacters)
                    if cleanedPhrase.count <= 100 { // Keep phrases concise
                        keyPhrases.append(cleanedPhrase)
                    }
                    break
                }
            }
        }
        
        // If not enough key phrases, add representative sentences
        if keyPhrases.count < 3 {
            let additionalSentences = sentences
                .filter { $0.count > 20 && $0.count <= 100 }
                .prefix(6 - keyPhrases.count)
            
            keyPhrases.append(contentsOf: additionalSentences)
        }
        
        return keyPhrases
    }
    
    private func analyzeEmotionalContent(_ text: String) -> [(String, Double)] {
        let emotionKeywords: [String: [String]] = [
            "happy": ["happy", "joy", "joyful", "pleased", "content", "cheerful", "excited"],
            "sad": ["sad", "upset", "down", "depressed", "melancholy", "disappointed"],
            "anxious": ["anxious", "worried", "nervous", "stressed", "concerned", "uneasy"],
            "calm": ["calm", "peaceful", "relaxed", "serene", "tranquil", "centered"],
            "frustrated": ["frustrated", "annoyed", "angry", "irritated", "upset"],
            "grateful": ["grateful", "thankful", "blessed", "appreciative"],
            "confident": ["confident", "proud", "accomplished", "successful", "strong"],
            "tired": ["tired", "exhausted", "drained", "weary", "fatigued"]
        ]
        
        var emotionScores: [String: Double] = [:]
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        for (emotion, keywords) in emotionKeywords {
            var score: Double = 0
            for keyword in keywords {
                let count = words.filter { $0.contains(keyword) }.count
                score += Double(count)
            }
            if score > 0 {
                emotionScores[emotion] = min(10.0, score * 2.0) // Scale to 0-10
            }
        }
        
        return emotionScores.map { ($0.key, $0.value) }
    }
    
    private func cleanAction(_ sentence: String) -> String {
        // Remove personal pronouns and clean up the action
        var cleaned = sentence
            .replacingOccurrences(of: "I will", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "I'll", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "I should", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "I need to", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "I want to", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Capitalize first letter
        if !cleaned.isEmpty {
            cleaned = cleaned.prefix(1).uppercased() + cleaned.dropFirst()
        }
        
        return cleaned
    }
    
    private func isValidAction(_ action: String) -> Bool {
        return action.count > 5 && action.count < 100
    }
    
    private func generateDefaultActions(from transcript: String) -> [String] {
        // Generate contextual actions based on content
        let defaultActions = [
            "Take 5 minutes to reflect on today",
            "Do one small thing for self-care",
            "Connect with someone important to you"
        ]
        
        return defaultActions
    }
}

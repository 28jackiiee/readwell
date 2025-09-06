import Foundation

// MARK: - Structured Output Models
struct SessionAnalysis: Codable {
    let summary: String
    let coreTheme: String
    let emotions: [EmotionAnalysis]
    let actions: [ActionItem]
    let insights: [String]
}

struct EmotionAnalysis: Codable {
    let name: String
    let intensity: Double // 0-10 scale
    let color: String // hex color code
}

struct ActionItem: Codable {
    let title: String
    let category: String // "health", "relationships", "work", "personal", "general"
    let dueTime: String // "today", "this_week", "this_month"
    let isSpecific: Bool
    let isMeasurable: Bool
    let isAchievable: Bool
    let isRelevant: Bool
    let isTimeBound: Bool
}

// MARK: - OpenAI API Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let responseFormat: ResponseFormat
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case responseFormat = "response_format"
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct ResponseFormat: Codable {
    let type: String
    let jsonSchema: JSONSchema
    
    enum CodingKeys: String, CodingKey {
        case type
        case jsonSchema = "json_schema"
    }
}

struct JSONSchema: Codable {
    let name: String
    let strict: Bool
    let schema: SchemaDefinition
}

struct SchemaDefinition: Codable {
    let type: String
    let properties: [String: PropertyDefinition]
    let required: [String]
    let additionalProperties: Bool
    
    enum CodingKeys: String, CodingKey {
        case type, properties, required
        case additionalProperties = "additionalProperties"
    }
}

struct PropertyDefinition: Codable {
    let type: String
    let description: String?
    let items: PropertyDefinition?
    let properties: [String: PropertyDefinition]?
    let required: [String]?
    let minimum: Double?
    let maximum: Double?
    let additionalProperties: Bool?
    
    enum CodingKeys: String, CodingKey {
        case type, description, items, properties, required, minimum, maximum
        case additionalProperties = "additionalProperties"
    }
}

struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?
}

struct Choice: Codable {
    let index: Int
    let message: OpenAIMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - OpenAI Service
@MainActor
class OpenAIService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    @Published var isProcessing = false
    @Published var lastError: String = ""
    
    init() {
        // Try multiple sources for API key
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            self.apiKey = envKey
        } else if let path = Bundle.main.path(forResource: ".env", ofType: nil),
                  let content = try? String(contentsOfFile: path),
                  let apiKey = content.components(separatedBy: .newlines)
                    .first(where: { $0.hasPrefix("OPENAI_API_KEY=") })?
                    .replacingOccurrences(of: "OPENAI_API_KEY=", with: "") {
            self.apiKey = apiKey
        } else if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let apiKey = plist["OPENAI_API_KEY"] as? String {
            self.apiKey = apiKey
        } else {
            // For development, you can hardcode here temporarily
            self.apiKey = ""
            self.lastError = "OpenAI API key not found. Add to environment, .env file, or Config.plist"
        }
    }
    
    func analyzeSession(transcript: String, energyLevel: Int, intent: String) async -> SessionAnalysis? {
        guard !apiKey.isEmpty else {
            lastError = "OpenAI API key not configured"
            return nil
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let request = createAnalysisRequest(transcript: transcript, energyLevel: energyLevel, intent: intent)
            let response = try await performRequest(request)
            
            if let choice = response.choices.first,
               let analysisData = choice.message.content.data(using: .utf8) {
                let analysis = try JSONDecoder().decode(SessionAnalysis.self, from: analysisData)
                return analysis
            } else {
                lastError = "No response from OpenAI"
                return nil
            }
        } catch {
            lastError = "Error analyzing session: \(error.localizedDescription)"
            print("OpenAI Error: \(error)")
            return nil
        }
    }
    
    private func createAnalysisRequest(transcript: String, energyLevel: Int, intent: String) -> OpenAIRequest {
        let systemPrompt = """
        You are a compassionate AI therapist and life coach. Analyze the user's daily check-in transcript and provide structured insights.
        
        Based on the transcript, provide:
        1. A concise, empathetic summary (2-3 sentences)
        2. The core theme or pattern you notice
        3. Emotions detected with intensity (0-10) and appropriate colors
        4. Actionable items using SMART goal principles
        5. Brief insights or observations
        
        Be supportive, non-judgmental, and focus on growth and self-awareness.
        """
        
        let userPrompt = """
        Here's my daily check-in:
        
        Energy Level: \(energyLevel)/10
        Focus Area: \(intent)
        
        Transcript:
        \(transcript)
        
        Please analyze this and provide structured insights to help me understand my thoughts and feelings better.
        """
        
        return OpenAIRequest(
            model: "gpt-4o-2024-08-06",
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: userPrompt)
            ],
            responseFormat: createResponseFormat(),
            temperature: 0.7,
            maxTokens: 2000
        )
    }
    
    private func createResponseFormat() -> ResponseFormat {
        return ResponseFormat(
            type: "json_schema",
            jsonSchema: JSONSchema(
                name: "session_analysis",
                strict: true,
                schema: SchemaDefinition(
                    type: "object",
                    properties: [
                        "summary": PropertyDefinition(
                            type: "string",
                            description: "A concise, empathetic summary of the session",
                            items: nil,
                            properties: nil,
                            required: nil,
                            minimum: nil,
                            maximum: nil,
                            additionalProperties: nil
                        ),
                        "coreTheme": PropertyDefinition(
                            type: "string",
                            description: "The main theme or pattern identified",
                            items: nil,
                            properties: nil,
                            required: nil,
                            minimum: nil,
                            maximum: nil,
                            additionalProperties: nil
                        ),
                        "emotions": PropertyDefinition(
                            type: "array",
                            description: "Detected emotions with intensity and colors",
                            items: PropertyDefinition(
                                type: "object",
                                description: nil,
                                items: nil,
                                properties: [
                                    "name": PropertyDefinition(type: "string", description: "Emotion name", items: nil, properties: nil, required: nil, minimum: nil, maximum: nil, additionalProperties: nil),
                                    "intensity": PropertyDefinition(type: "number", description: "Intensity 0-10", items: nil, properties: nil, required: nil, minimum: 0, maximum: 10, additionalProperties: nil),
                                    "color": PropertyDefinition(type: "string", description: "Hex color code", items: nil, properties: nil, required: nil, minimum: nil, maximum: nil, additionalProperties: nil)
                                ],
                                required: ["name", "intensity", "color"],
                                minimum: nil,
                                maximum: nil,
                                additionalProperties: false
                            ),
                            properties: nil,
                            required: nil,
                            minimum: nil,
                            maximum: nil,
                            additionalProperties: nil
                        ),
                        "actions": PropertyDefinition(
                            type: "array",
                            description: "Actionable items following SMART principles",
                            items: PropertyDefinition(
                                type: "object",
                                description: nil,
                                items: nil,
                                properties: [
                                    "title": PropertyDefinition(type: "string", description: "Action title", items: nil, properties: nil, required: nil, minimum: nil, maximum: nil, additionalProperties: nil),
                                    "category": PropertyDefinition(type: "string", description: "Category: health, relationships, work, personal, general", items: nil, properties: nil, required: nil, minimum: nil, maximum: nil, additionalProperties: nil),
                                    "dueTime": PropertyDefinition(type: "string", description: "Due time: today, this_week, this_month", items: nil, properties: nil, required: nil, minimum: nil, maximum: nil, additionalProperties: nil),
                                    "isSpecific": PropertyDefinition(type: "boolean", description: "Is the action specific?", items: nil, properties: nil, required: nil, minimum: nil, maximum: nil, additionalProperties: nil),
                                    "isMeasurable": PropertyDefinition(type: "boolean", description: "Is the action measurable?", items: nil, properties: nil, required: nil, minimum: nil, maximum: nil, additionalProperties: nil),
                                    "isAchievable": PropertyDefinition(type: "boolean", description: "Is the action achievable?", items: nil, properties: nil, required: nil, minimum: nil, maximum: nil, additionalProperties: nil),
                                    "isRelevant": PropertyDefinition(type: "boolean", description: "Is the action relevant?", items: nil, properties: nil, required: nil, minimum: nil, maximum: nil, additionalProperties: nil),
                                    "isTimeBound": PropertyDefinition(type: "boolean", description: "Is the action time-bound?", items: nil, properties: nil, required: nil, minimum: nil, maximum: nil, additionalProperties: nil)
                                ],
                                required: ["title", "category", "dueTime", "isSpecific", "isMeasurable", "isAchievable", "isRelevant", "isTimeBound"],
                                minimum: nil,
                                maximum: nil,
                                additionalProperties: false
                            ),
                            properties: nil,
                            required: nil,
                            minimum: nil,
                            maximum: nil,
                            additionalProperties: nil
                        ),
                        "insights": PropertyDefinition(
                            type: "array",
                            description: "Brief insights or observations",
                            items: PropertyDefinition(
                                type: "string",
                                description: "Individual insight",
                                items: nil,
                                properties: nil,
                                required: nil,
                                minimum: nil,
                                maximum: nil,
                                additionalProperties: nil
                            ),
                            properties: nil,
                            required: nil,
                            minimum: nil,
                            maximum: nil,
                            additionalProperties: nil
                        )
                    ],
                    required: ["summary", "coreTheme", "emotions", "actions", "insights"],
                    additionalProperties: false
                )
            )
        )
    }
    
    private func performRequest(_ request: OpenAIRequest) async throws -> OpenAIResponse {
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        return try JSONDecoder().decode(OpenAIResponse.self, from: data)
    }
}

enum OpenAIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid OpenAI API URL"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .apiError(let statusCode, let message):
            return "OpenAI API error (\(statusCode)): \(message)"
        }
    }
}

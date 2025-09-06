import SwiftUI
import CoreData

struct SummaryView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isProcessing = true
    @State private var summaryBullets: [String] = []
    @State private var detectedEmotions: [(emotion: String, intensity: Double, color: String)] = []
    @State private var generatedActions: [String] = []
    @State private var coreTheme = ""
    @State private var showingActionReminders = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Session Complete!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Here's what I learned from your check-in")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                if isProcessing {
                    // Processing indicator
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Processing your session...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 100)
                } else {
                    // Summary content
                    VStack(spacing: 20) {
                        // Core theme
                        SummaryCard(title: "Core Theme", icon: "lightbulb.fill", color: .orange) {
                            Text(coreTheme)
                                .font(.body)
                                .italic()
                        }
                        
                        // Summary bullets
                        SummaryCard(title: "Key Points", icon: "list.bullet", color: .blue) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(summaryBullets, id: \.self) { bullet in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 6)
                                        
                                        Text(bullet)
                                            .font(.body)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        // Emotions
                        SummaryCard(title: "Emotions", icon: "heart.fill", color: .pink) {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                                ForEach(detectedEmotions, id: \.emotion) { emotion in
                                    VStack(spacing: 5) {
                                        Text(emotionEmoji(for: emotion.emotion))
                                            .font(.title2)
                                        
                                        Text(emotion.emotion)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        
                                        // Intensity bar
                                        HStack(spacing: 2) {
                                            ForEach(0..<10) { index in
                                                Rectangle()
                                                    .fill(index < Int(emotion.intensity) ? 
                                                          Color(emotion.color) : 
                                                          Color.gray.opacity(0.3))
                                                    .frame(width: 3, height: 8)
                                            }
                                        }
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(emotion.color).opacity(0.1))
                                    )
                                }
                            }
                        }
                        
                        // Actions
                        SummaryCard(title: "3 Tiny Actions", icon: "target", color: .green) {
                            VStack(spacing: 12) {
                                ForEach(Array(generatedActions.enumerated()), id: \.offset) { index, action in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.green.opacity(0.2))
                                                .frame(width: 30, height: 30)
                                            
                                            Text("\(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                        }
                                        
                                        Text(action)
                                            .font(.body)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        // Action buttons
                        VStack(spacing: 15) {
                            Button(action: {
                                showingActionReminders = true
                            }) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                    Text("Add to Today")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                appViewModel.goToStart()
                            }) {
                                Text("Back to Home")
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            processSession()
        }
        .sheet(isPresented: $showingActionReminders) {
            ActionReminderSheet(actions: generatedActions)
        }
    }
    
    private func processSession() {
        guard let session = appViewModel.currentSession,
              let transcript = session.transcript,
              !transcript.isEmpty else {
            isProcessing = false
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let nlpService = NLPService.shared
            
            // Process transcript
            let summary = nlpService.generateSummary(from: transcript)
            let emotions = nlpService.detectEmotions(from: transcript)
            let actions = nlpService.extractActions(from: transcript)
            let theme = nlpService.extractCoreTheme(from: transcript)
            
            DispatchQueue.main.async {
                // Update session with processed data
                session.summary = summary.joined(separator: "; ")
                session.coreTheme = theme
                
                // Create emotion entities
                for emotionData in emotions {
                    let emotion = Emotion(context: viewContext)
                    emotion.name = emotionData.emotion
                    emotion.intensity = emotionData.intensity
                    emotion.color = emotionData.color
                    emotion.session = session
                }
                
                // Create action entities
                for actionText in actions {
                    let action = Action(context: viewContext)
                    action.title = actionText
                    action.dueTime = "today"
                    action.category = session.intent ?? "general"
                    action.session = session
                }
                
                // Save to Core Data
                do {
                    try viewContext.save()
                } catch {
                    print("Error saving processed session: \(error)")
                }
                
                // Update UI
                summaryBullets = summary
                detectedEmotions = emotions
                generatedActions = actions
                coreTheme = theme
                isProcessing = false
            }
        }
    }
    
    private func emotionEmoji(for emotion: String) -> String {
        switch emotion.lowercased() {
        case "happy": return "😊"
        case "excited": return "🤩"
        case "calm": return "😌"
        case "anxious": return "😰"
        case "sad": return "😢"
        case "frustrated": return "😤"
        case "grateful": return "🙏"
        case "confident": return "💪"
        case "tired": return "😴"
        default: return "😐"
        }
    }
}

struct SummaryCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct ActionReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let actions: [String]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Set Reminders")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 15) {
                    ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                        HStack {
                            Text(action)
                                .font(.body)
                            Spacer()
                            Button("Remind me") {
                                // TODO: Set local notification
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
                .padding()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SummaryView()
        .environmentObject(AppViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

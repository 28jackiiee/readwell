import SwiftUI

struct StartView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var energyLevel: Double = 5
    @State private var selectedIntent: String = "free talk"
    
    private let intents = ["school", "health", "relationships", "free talk"]
    private let intentEmojis = ["📚", "💪", "❤️", "💭"]
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                Text("MindTalk")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Daily Check-in")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
            
            Spacer()
            
            // Energy Level Slider
            VStack(spacing: 20) {
                Text("How's your energy today?")
                    .font(.headline)
                
                VStack {
                    HStack {
                        Text("😴")
                            .font(.title2)
                        Slider(value: $energyLevel, in: 0...10, step: 1)
                        Text("⚡")
                            .font(.title2)
                    }
                    
                    Text("\(Int(energyLevel))/10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            // Intent Selection
            VStack(spacing: 20) {
                Text("What's on your mind?")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    ForEach(Array(intents.enumerated()), id: \.offset) { index, intent in
                        Button(action: {
                            selectedIntent = intent
                        }) {
                            VStack(spacing: 8) {
                                Text(intentEmojis[index])
                                    .font(.system(size: 30))
                                Text(intent.capitalized)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(height: 80)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedIntent == intent ? 
                                          Color.blue.opacity(0.2) : 
                                          Color.gray.opacity(0.1))
                                    .stroke(selectedIntent == intent ? 
                                           Color.blue : 
                                           Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Streak Display
            if let settings = appViewModel.userSettings {
                VStack(spacing: 5) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(settings.currentStreak) day streak")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    if settings.longestStreak > settings.currentStreak {
                        Text("Best: \(settings.longestStreak) days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            
            // Start Button
            Button(action: {
                appViewModel.currentSession?.energyLevel = Int16(energyLevel)
                appViewModel.currentSession?.intent = selectedIntent
                appViewModel.startNewSession()
            }) {
                HStack {
                    Image(systemName: "mic.fill")
                        .font(.title3)
                    Text("Start 5-min Check-in")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color.blue.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    StartView()
        .environmentObject(AppViewModel())
}

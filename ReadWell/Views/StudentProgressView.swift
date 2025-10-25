import SwiftUI
import CoreData

struct StudentProgressView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var sessions: [ReadingSession] = []
    @State private var averageScore: Double = 0
    
    var body: some View {
        ZStack {
            Color.beigeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats cards
                        statsSection
                        
                        // Recent sessions
                        recentSessionsSection
                        
                        // Continue button
                        Button(action: {
                            appViewModel.goToTextLibrary()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                                Text("Continue Reading")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadProgress()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button(action: {
                appViewModel.goToTextLibrary()
            }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding()
            }
            
            Spacer()
            
            Text("Your Progress")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
                .padding()
        }
        .background(Color.white.opacity(0.95))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("Great work, \(appViewModel.currentStudent?.name ?? "Student")!")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)
            
            HStack(spacing: 16) {
                // Total readings
                StatCard(
                    icon: "book.fill",
                    value: "\(sessions.count)",
                    label: "Stories Read",
                    color: .blue
                )
                
                // Average score
                StatCard(
                    icon: "star.fill",
                    value: String(format: "%.0f%%", averageScore),
                    label: "Avg Score",
                    color: averageScore >= 80 ? .green : (averageScore >= 60 ? .orange : .red)
                )
            }
            .padding(.horizontal)
            
            // Most recent score
            if let lastSession = sessions.first,
               lastSession.comprehensionScore > 0 {
                let score = lastSession.comprehensionScore
                HStack(spacing: 12) {
                    Image(systemName: score >= 80 ? "trophy.fill" : "hand.thumbsup.fill")
                        .font(.title2)
                        .foregroundColor(score >= 80 ? .yellow : .orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Session Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.0f%%", score))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    if score >= 80 {
                        Text("Excellent!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    } else if score >= 60 {
                        Text("Good job!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    } else {
                        Text("Keep practicing!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Recent Sessions Section
    
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Reading Sessions")
                .font(.headline)
                .padding(.horizontal)
            
            if sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No reading sessions yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    ForEach(sessions.prefix(5), id: \.id) { session in
                        SessionRow(session: session)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadProgress() {
        guard let student = appViewModel.currentStudent else { return }
        
        sessions = appViewModel.getStudentProgress(for: student)
        averageScore = appViewModel.getAverageComprehensionScore(for: student)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: ReadingSession
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(scoreColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "book.fill")
                        .foregroundColor(scoreColor)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.text?.title ?? "Reading Session")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Score
            if session.comprehensionScore > 0 {
                let score = session.comprehensionScore
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f%%", score))
                        .font(.headline)
                        .foregroundColor(scoreColor)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < starCount ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3)
    }
    
    private var scoreColor: Color {
        let score = session.comprehensionScore
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
    
    private var starCount: Int {
        let score = session.comprehensionScore
        if score >= 90 { return 5 }
        if score >= 75 { return 4 }
        if score >= 60 { return 3 }
        if score >= 40 { return 2 }
        if score >= 20 { return 1 }
        return 0
    }
    
    private var formattedDate: String {
        guard let date = session.startDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    StudentProgressView()
        .environmentObject(AppViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


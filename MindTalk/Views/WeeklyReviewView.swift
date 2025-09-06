import SwiftUI
import CoreData
import Charts

struct WeeklyReviewView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var weeklyData: [(date: Date, mood: Double, completed: Int)] = []
    @State private var topThemes: [String] = []
    @State private var completionPercentage: Double = 0
    @State private var nextWeekFocus = ""
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Text("📊")
                            .font(.system(size: 40))
                        
                        Text("Weekly Review")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Your progress this week")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    if isLoading {
                        ProgressView("Analyzing your week...")
                            .padding()
                    } else {
                        // Mood trend chart
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Mood Trends")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if #available(iOS 16.0, *) {
                                Chart(weeklyData, id: \.date) { dataPoint in
                                    LineMark(
                                        x: .value("Day", dataPoint.date, unit: .day),
                                        y: .value("Mood", dataPoint.mood)
                                    )
                                    .foregroundStyle(Color.blue)
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                    
                                    PointMark(
                                        x: .value("Day", dataPoint.date, unit: .day),
                                        y: .value("Mood", dataPoint.mood)
                                    )
                                    .foregroundStyle(Color.blue)
                                    .symbolSize(50)
                                }
                                .frame(height: 200)
                                .chartYScale(domain: 0...10)
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day)) { _ in
                                        AxisGridLine()
                                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { _ in
                                        AxisGridLine()
                                        AxisValueLabel()
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(radius: 2)
                                )
                            } else {
                                // Fallback for iOS 15
                                MoodSparkline(data: weeklyData)
                                    .frame(height: 200)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.systemBackground))
                                            .shadow(radius: 2)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action completion chart
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Action Completion")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 15) {
                                // Overall percentage
                                HStack {
                                    Text("\(Int(completionPercentage))%")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                    
                                    Text("of actions completed")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                                
                                // Daily completion bars
                                VStack(spacing: 8) {
                                    ForEach(weeklyData, id: \.date) { dataPoint in
                                        HStack {
                                            Text(dayOfWeek(dataPoint.date))
                                                .font(.caption)
                                                .frame(width: 30, alignment: .leading)
                                            
                                            ProgressView(value: Double(dataPoint.completed), total: 3)
                                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                                .frame(height: 8)
                                            
                                            Text("\(dataPoint.completed)/3")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .frame(width: 30)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 2)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Top themes
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Top Themes")
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                                ForEach(topThemes, id: \.self) { theme in
                                    Text(theme)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(Color.blue.opacity(0.1))
                                        )
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 2)
                        )
                        .padding(.horizontal)
                        
                        // Next week focus
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Suggested Focus for Next Week")
                                .font(.headline)
                            
                            Text(nextWeekFocus)
                                .font(.body)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange.opacity(0.1))
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 2)
                        )
                        .padding(.horizontal)
                        
                        // Export and continue buttons
                        VStack(spacing: 15) {
                            Button(action: {
                                // TODO: Export PDF
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export PDF Report")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                appViewModel.goToStart()
                            }) {
                                Text("Continue Journey")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            generateWeeklyReview()
        }
    }
    
    private func generateWeeklyReview() {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? today
        
        // Fetch this week's sessions
        let request: NSFetchRequest<CheckInSession> = CheckInSession.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@",
                                      weekStart as NSDate, weekEnd as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CheckInSession.date, ascending: true)]
        
        do {
            let sessions = try viewContext.fetch(request)
            processWeeklyData(sessions)
        } catch {
            print("Error fetching weekly sessions: \(error)")
        }
        
        isLoading = false
    }
    
    private func processWeeklyData(_ sessions: [CheckInSession]) {
        var dailyData: [(date: Date, mood: Double, completed: Int)] = []
        var themes: [String] = []
        var totalActions = 0
        var completedActions = 0
        
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        // Create data for each day of the week
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
            let daySession = sessions.first { calendar.isDate($0.date!, inSameDayAs: date) }
            
            var avgMood: Double = 5.0
            var dailyCompleted = 0
            
            if let session = daySession {
                // Calculate average mood from emotions
                if let emotions = session.emotions?.allObjects as? [Emotion], !emotions.isEmpty {
                    avgMood = emotions.map { $0.intensity }.reduce(0, +) / Double(emotions.count)
                }
                
                // Count completed actions
                if let actions = session.actions?.allObjects as? [Action] {
                    dailyCompleted = actions.filter { $0.isCompleted }.count
                    totalActions += actions.count
                    completedActions += dailyCompleted
                }
                
                // Collect themes
                if let theme = session.coreTheme, !theme.isEmpty {
                    themes.append(theme)
                }
            }
            
            dailyData.append((date: date, mood: avgMood, completed: dailyCompleted))
        }
        
        weeklyData = dailyData
        completionPercentage = totalActions > 0 ? Double(completedActions) / Double(totalActions) * 100 : 0
        
        // Process top themes
        let themeWords = themes.flatMap { $0.components(separatedBy: .whitespacesAndNewlines) }
            .filter { $0.count > 3 }
            .map { $0.lowercased() }
        
        let themeCounts = Dictionary(grouping: themeWords, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        topThemes = Array(themeCounts.prefix(6)).map { $0.key.capitalized }
        
        // Generate next week focus
        generateNextWeekFocus(completionRate: completionPercentage, topThemes: topThemes)
    }
    
    private func generateNextWeekFocus(completionRate: Double, topThemes: [String]) {
        if completionRate >= 80 {
            nextWeekFocus = "You're doing great! Consider setting slightly more challenging goals or exploring new areas of growth."
        } else if completionRate >= 60 {
            nextWeekFocus = "Good progress! Focus on consistency and identify what helps you complete your actions successfully."
        } else if completionRate >= 40 {
            nextWeekFocus = "Room for improvement. Try smaller, more achievable actions and establish better daily routines."
        } else {
            nextWeekFocus = "Let's reset with simpler goals. Focus on building the habit first, then gradually increase complexity."
        }
        
        if !topThemes.isEmpty {
            nextWeekFocus += " Continue exploring themes around \(topThemes.prefix(2).joined(separator: " and "))."
        }
    }
    
    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// Fallback sparkline view for iOS 15
struct MoodSparkline: View {
    let data: [(date: Date, mood: Double, completed: Int)]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(data.count - 1)
                
                for (index, point) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height - (CGFloat(point.mood) / 10.0 * height)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 3)
            
            // Add points
            ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                let x = CGFloat(index) * (geometry.size.width / CGFloat(data.count - 1))
                let y = geometry.size.height - (CGFloat(point.mood) / 10.0 * geometry.size.height)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .position(x: x, y: y)
            }
        }
    }
}

#Preview {
    WeeklyReviewView()
        .environmentObject(AppViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

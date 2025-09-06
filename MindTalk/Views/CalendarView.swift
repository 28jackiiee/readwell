import SwiftUI
import CoreData

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var sessions: [CheckInSession] = []
    @State private var showingSessionDetail = false
    @State private var selectedSession: CheckInSession?
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with month navigation
                monthHeader
                
                // Calendar grid
                calendarGrid
                
                // Selected date info
                if let session = sessionForDate(selectedDate) {
                    selectedDateInfo(session: session)
                } else {
                    noSessionInfo
                }
                
                Spacer()
            }
            .navigationTitle("Check-in Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        withAnimation {
                            currentMonth = Date()
                            selectedDate = Date()
                        }
                    }
                }
            }
            .onAppear {
                loadSessions()
            }
            .onChange(of: currentMonth) { _ in
                loadSessions()
            }
            .sheet(isPresented: $showingSessionDetail) {
                if let session = selectedSession {
                    SessionDetailView(session: session)
                }
            }
        }
    }
    
    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: currentMonth))
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
            // Day headers
            ForEach(dayHeaders, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(height: 30)
            }
            
            // Calendar days
            ForEach(daysInMonth, id: \.self) { date in
                CalendarDayView(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(date),
                    hasSession: sessionForDate(date) != nil,
                    sessionMood: sessionMoodForDate(date),
                    isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                )
                .onTapGesture {
                    selectedDate = date
                    if let session = sessionForDate(date) {
                        selectedSession = session
                        showingSessionDetail = true
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func selectedDateInfo(session: CheckInSession) -> some View {
        VStack(spacing: 15) {
            Divider()
            
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    
                    Text("Check-in completed")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(selectedDate.timeString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let theme = session.coreTheme, !theme.isEmpty {
                    HStack {
                        Text("Theme:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(theme)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                
                // Action completion summary
                if let actions = session.actions?.allObjects as? [Action], !actions.isEmpty {
                    let completedActions = actions.filter { $0.isCompleted }
                    
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                        
                        Text("\(completedActions.count)/\(actions.count) actions completed")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                
                Button("View Details") {
                    selectedSession = session
                    showingSessionDetail = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
        }
    }
    
    private var noSessionInfo: some View {
        VStack(spacing: 15) {
            Divider()
            
            VStack(spacing: 10) {
                Image(systemName: "calendar.badge.plus")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("No check-in on \(selectedDate.shortDateString())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if calendar.isDateInToday(selectedDate) {
                    Button("Start Today's Check-in") {
                        appViewModel.goToStart()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Properties
    
    private var dayHeaders: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end) else {
            return []
        }
        
        var dates: [Date] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate <= monthLastWeek.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    // MARK: - Helper Methods
    
    private func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func loadSessions() {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return }
        
        let request: NSFetchRequest<CheckInSession> = CheckInSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            monthInterval.start as NSDate,
            monthInterval.end as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CheckInSession.date, ascending: true)]
        
        do {
            sessions = try viewContext.fetch(request)
        } catch {
            print("Error loading calendar sessions: \(error)")
            sessions = []
        }
    }
    
    private func sessionForDate(_ date: Date) -> CheckInSession? {
        return sessions.first { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: date)
        }
    }
    
    private func sessionMoodForDate(_ date: Date) -> Double? {
        guard let session = sessionForDate(date),
              let emotions = session.emotions?.allObjects as? [Emotion],
              !emotions.isEmpty else {
            return nil
        }
        
        return emotions.map { $0.intensity }.reduce(0, +) / Double(emotions.count)
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasSession: Bool
    let sessionMood: Double?
    let isCurrentMonth: Bool
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var moodColor: Color {
        guard let mood = sessionMood else { return .clear }
        
        switch mood {
        case 0..<3:
            return .red.opacity(0.7)
        case 3..<5:
            return .orange.opacity(0.7)
        case 5..<7:
            return .yellow.opacity(0.7)
        case 7..<9:
            return .green.opacity(0.7)
        default:
            return .blue.opacity(0.7)
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
            
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                
                // Session indicator
                Circle()
                    .fill(hasSession ? moodColor : Color.clear)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .stroke(hasSession ? Color.white : Color.clear, lineWidth: 1)
                    )
            }
        }
        .frame(height: 44)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue.opacity(0.2)
        } else if isToday {
            return .blue.opacity(0.1)
        } else {
            return .clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue.opacity(0.5)
        } else {
            return .clear
        }
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else if isSelected || isToday {
            return .blue
        } else {
            return .primary
        }
    }
}

struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let session: CheckInSession
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date and time
                    VStack(alignment: .leading, spacing: 5) {
                        Text(session.date?.shortDateString() ?? "Unknown Date")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(session.date?.timeString() ?? "Unknown Time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Core theme
                    if let theme = session.coreTheme, !theme.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Core Theme")
                                .font(.headline)
                            
                            Text(theme)
                                .font(.body)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Emotions
                    if let emotions = session.emotions?.allObjects as? [Emotion], !emotions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Emotions")
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                                ForEach(emotions.sorted(by: { $0.intensity > $1.intensity }), id: \.objectID) { emotion in
                                    VStack(spacing: 4) {
                                        Text(emotion.name ?? "Unknown")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text(String(format: "%.1f/10", emotion.intensity))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        ProgressView(value: emotion.intensity / 10.0)
                                            .progressViewStyle(LinearProgressViewStyle(tint: Color.emotion(emotion.color ?? "gray")))
                                    }
                                    .padding(8)
                                    .background(Color.emotion(emotion.color ?? "gray").opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Actions
                    if let actions = session.actions?.allObjects as? [Action], !actions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Actions")
                                .font(.headline)
                            
                            ForEach(actions, id: \.objectID) { action in
                                HStack(spacing: 12) {
                                    Image(systemName: action.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(action.isCompleted ? .green : .gray)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(action.title ?? "Unknown Action")
                                            .font(.body)
                                            .strikethrough(action.isCompleted)
                                        
                                        if let dueTime = action.dueTime {
                                            Text("Due: \(dueTime)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(action.isCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Summary
                    if let summary = session.summary, !summary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Summary")
                                .font(.headline)
                            
                            Text(summary)
                                .font(.body)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(AppViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

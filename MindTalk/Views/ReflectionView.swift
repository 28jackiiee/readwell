import SwiftUI
import CoreData

struct ReflectionView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var previousActions: [Action] = []
    @State private var actionStates: [String: Bool] = [:]
    @State private var reflectionText = ""
    @State private var showReflectionInput = false
    @State private var completedCount = 0
    
    var body: some View {
        VStack(spacing: 25) {
            // Header
            VStack(spacing: 10) {
                Text("🌅")
                    .font(.system(size: 50))
                
                Text("Good Morning!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("How did yesterday go?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Previous day's actions
            VStack(spacing: 20) {
                Text("Did you complete these actions?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 15) {
                    ForEach(previousActions, id: \.objectID) { action in
                        ActionCheckRow(
                            action: action,
                            isCompleted: actionStates[action.objectID.uriRepresentation().absoluteString] ?? false
                        ) { isCompleted in
                            let key = action.objectID.uriRepresentation().absoluteString
                            actionStates[key] = isCompleted
                            action.isCompleted = isCompleted
                            updateCompletedCount()
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Progress indicator
            if !previousActions.isEmpty {
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                        Text("\(completedCount) of \(previousActions.count) completed")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: Double(completedCount), total: Double(previousActions.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 8)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Reflection prompt
            if completedCount > 0 || !previousActions.isEmpty {
                Button(action: {
                    showReflectionInput = true
                }) {
                    HStack {
                        Image(systemName: "bubble.left.fill")
                        Text(completedCount > 0 ? "Quick reflection on what helped" : "What got in the way?")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            // Continue button
            Button(action: {
                saveReflectionAndContinue()
            }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Start Today's Check-in")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
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
                gradient: Gradient(colors: [Color.orange.opacity(0.1), Color(.systemBackground)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            loadPreviousActions()
        }
        .sheet(isPresented: $showReflectionInput) {
            ReflectionInputSheet(
                reflectionText: $reflectionText,
                completedCount: completedCount,
                totalCount: previousActions.count
            )
        }
    }
    
    private func loadPreviousActions() {
        guard let settings = appViewModel.userSettings,
              let lastCheckIn = settings.lastCheckInDate else { return }
        
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        // Fetch actions from yesterday's session
        let request: NSFetchRequest<CheckInSession> = CheckInSession.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                      calendar.startOfDay(for: yesterday) as NSDate,
                                      calendar.startOfDay(for: Date()) as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CheckInSession.date, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let sessions = try viewContext.fetch(request)
            if let lastSession = sessions.first,
               let actions = lastSession.actions?.allObjects as? [Action] {
                previousActions = actions.sorted { ($0.title ?? "") < ($1.title ?? "") }
                updateCompletedCount()
            }
        } catch {
            print("Error loading previous actions: \(error)")
        }
    }
    
    private func updateCompletedCount() {
        completedCount = previousActions.filter { $0.isCompleted }.count
    }
    
    private func saveReflectionAndContinue() {
        // Save any changes to action completion
        do {
            try viewContext.save()
        } catch {
            print("Error saving action states: \(error)")
        }
        
        // Update streak based on completion
        updateStreakBasedOnCompletion()
        
        // Continue to today's check-in
        appViewModel.goToStart()
    }
    
    private func updateStreakBasedOnCompletion() {
        guard let settings = appViewModel.userSettings else { return }
        
        // If user completed at least 1 action, maintain/boost streak
        if completedCount > 0 {
            // Streak logic is already handled in AppViewModel.updateStreak()
            // This reflection just confirms the quality of the streak
            print("Streak maintained with \(completedCount) completed actions")
        } else if !previousActions.isEmpty {
            // If they had actions but completed none, give a gentle nudge but don't break streak
            print("No actions completed, but streak continues")
        }
    }
}

struct ActionCheckRow: View {
    let action: Action
    let isCompleted: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: {
                onToggle(!isCompleted)
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(action.title ?? "")
                    .font(.body)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
                if let dueTime = action.dueTime {
                    Text(dueTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                .stroke(isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
}

struct ReflectionInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var reflectionText: String
    let completedCount: Int
    let totalCount: Int
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Text(completedCount > 0 ? "What helped you succeed?" : "What got in the way?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("This helps me learn your patterns")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                TextEditor(text: $reflectionText)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 120)
                
                Spacer()
                
                Button("Save Reflection") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Quick Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ReflectionView()
        .environmentObject(AppViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

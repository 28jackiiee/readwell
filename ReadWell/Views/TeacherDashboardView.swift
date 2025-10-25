import SwiftUI
import CoreData

struct TeacherDashboardView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var students: [Student] = []
    @State private var selectedStudent: Student?
    @State private var showStudentDetail = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Overview stats
                        overviewSection
                        
                        // Student list
                        studentsSection
                    }
                    .padding()
                }
            }
            
            // Student detail sheet
            if showStudentDetail, let student = selectedStudent {
                StudentDetailView(student: student, isPresented: $showStudentDetail)
                    .environmentObject(appViewModel)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadStudents()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Teacher Dashboard")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(students.count) students")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {
                appViewModel.logout()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
            }
        }
        .padding()
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                OverviewCard(
                    icon: "person.3.fill",
                    value: "\(students.count)",
                    label: "Total Students",
                    color: .blue
                )
                
                OverviewCard(
                    icon: "book.fill",
                    value: "\(totalReadings)",
                    label: "Total Readings",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                OverviewCard(
                    icon: "chart.bar.fill",
                    value: String(format: "%.0f%%", classAverage),
                    label: "Class Average",
                    color: classAverage >= 75 ? .green : .orange
                )
                
                OverviewCard(
                    icon: "star.fill",
                    value: "\(topPerformers)",
                    label: "Top Performers",
                    color: .yellow
                )
            }
        }
    }
    
    // MARK: - Students Section
    
    private var studentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Students")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if students.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("No students yet")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Students can add themselves from the login screen")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    ForEach(students, id: \.id) { student in
                        TeacherStudentCard(student: student, appViewModel: appViewModel) {
                            selectedStudent = student
                            showStudentDetail = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalReadings: Int {
        students.reduce(0) { sum, student in
            sum + appViewModel.getStudentProgress(for: student).count
        }
    }
    
    private var classAverage: Double {
        guard !students.isEmpty else { return 0 }
        let total = students.reduce(0.0) { sum, student in
            sum + appViewModel.getAverageComprehensionScore(for: student)
        }
        return total / Double(students.count)
    }
    
    private var topPerformers: Int {
        students.filter { student in
            appViewModel.getAverageComprehensionScore(for: student) >= 85
        }.count
    }
    
    // MARK: - Helper Functions
    
    private func loadStudents() {
        students = appViewModel.getAllStudents()
    }
}

// MARK: - Overview Card

struct OverviewCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Teacher Student Card

struct TeacherStudentCard: View {
    let student: Student
    let appViewModel: AppViewModel
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(student.name?.prefix(1) ?? "?"))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(student.name ?? "Student")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Grade \(student.gradeLevel)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.0f%%", appViewModel.getAverageComprehensionScore(for: student)))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                    
                    Text("\(appViewModel.getStudentProgress(for: student).count) readings")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var scoreColor: Color {
        let score = appViewModel.getAverageComprehensionScore(for: student)
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

// MARK: - Student Detail View

struct StudentDetailView: View {
    let student: Student
    @Binding var isPresented: Bool
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var sessions: [ReadingSession] = []
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(student.name ?? "Student")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Student info
                        VStack(spacing: 12) {
                            HStack {
                                InfoLabel(title: "Grade", value: "\(student.gradeLevel)")
                                InfoLabel(title: "Language", value: student.preferredLanguage ?? "en")
                            }
                            
                            HStack {
                                InfoLabel(title: "Readings", value: "\(sessions.count)")
                                InfoLabel(title: "Avg Score", value: String(format: "%.0f%%", avgScore))
                            }
                        }
                        .padding()
                        
                        // Recent sessions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Sessions")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(sessions.prefix(10), id: \.id) { session in
                                SessionRow(session: session)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color.gray.opacity(0.1))
            }
            .frame(maxWidth: 500, maxHeight: 600)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding()
        }
        .onAppear {
            loadSessions()
        }
    }
    
    private var avgScore: Double {
        appViewModel.getAverageComprehensionScore(for: student)
    }
    
    private func loadSessions() {
        sessions = appViewModel.getStudentProgress(for: student)
    }
}

struct InfoLabel: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 3)
    }
}

#Preview {
    TeacherDashboardView()
        .environmentObject(AppViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


import SwiftUI
import CoreData

struct StudentLoginView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var students: [Student] = []
    @State private var showAddStudent = false
    @State private var newStudentName = ""
    @State private var newStudentGrade: Int16 = 3
    @State private var newStudentLanguage = "en"
    @State private var newStudentSecondLanguage = "es"
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header with modern design
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 1)
                        
                        Image(systemName: "book.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    
                    Text("ReadWell")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("Select Your Profile")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 50)
                
                // Student selection
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(students, id: \.id) { student in
                            StudentCard(student: student) {
                                appViewModel.loginStudent(student: student)
                            }
                        }
                        
                        // Add student button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showAddStudent = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                
                                Text("Add New Student")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 24)
                }
                .frame(maxHeight: 400)
                
                // Teacher login button
                NavigationLink(destination: TeacherLoginView().environmentObject(appViewModel)) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.key.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Teacher Login")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.bottom, 30)
            }
            
            // Add student sheet
            if showAddStudent {
                addStudentOverlay
            }
        }
        .onAppear {
            loadStudents()
        }
    }
    
    // MARK: - Add Student Overlay
    
    private var addStudentOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showAddStudent = false
                }
            
            VStack(spacing: 24) {
                Text("Add New Student")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Student Name")
                        .font(.headline)
                    
                    TextField("Enter name", text: $newStudentName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Grade Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Grade Level: \(newStudentGrade)")
                        .font(.headline)
                    
                    Picker("Grade", selection: $newStudentGrade) {
                        ForEach(1..<13, id: \.self) { grade in
                            Text("Grade \(grade)").tag(Int16(grade))
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 100)
                }
                
                // Primary Language
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Language")
                        .font(.headline)
                    
                    Picker("Language", selection: $newStudentLanguage) {
                        Text("English").tag("en")
                        Text("Spanish").tag("es")
                        Text("French").tag("fr")
                        Text("Mandarin").tag("zh")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        showAddStudent = false
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        createNewStudent()
                    }) {
                        Text("Add Student")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(newStudentName.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(newStudentName.isEmpty)
                }
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
            .frame(maxWidth: 400)
            .padding()
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadStudents() {
        students = appViewModel.getAllStudents()
    }
    
    private func createNewStudent() {
        appViewModel.createStudent(
            name: newStudentName,
            gradeLevel: newStudentGrade,
            preferredLanguage: newStudentLanguage,
            secondLanguage: newStudentSecondLanguage
        )
        
        newStudentName = ""
        newStudentGrade = 3
        showAddStudent = false
        loadStudents()
    }
}

// MARK: - Student Card

struct StudentCard: View {
    let student: Student
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Modern Avatar with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 0.5, blue: 0.95).opacity(0.8), Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    Text(String(student.name?.prefix(1).uppercased() ?? "?"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(student.name ?? "Student")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 14))
                        Text("Grade \(student.gradeLevel)")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    StudentLoginView()
        .environmentObject(AppViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


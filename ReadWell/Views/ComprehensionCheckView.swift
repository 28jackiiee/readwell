import SwiftUI
import CoreData

struct ComprehensionCheckView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: String = ""
    @State private var answers: [(question: ComprehensionQuestion, answer: String)] = []
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var questions: [ComprehensionQuestion] = []
    @State private var lastAnsweredQuestion: ComprehensionQuestion?
    @State private var animateSubmit = false
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.96, blue: 1.0),
                    Color(red: 0.98, green: 0.96, blue: 0.94)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Progress
                if !questions.isEmpty {
                    progressBar
                }
                
                if questions.isEmpty {
                    // No questions available
                    emptyStateView
                } else if currentQuestionIndex < questions.count {
                    // Question view
                    questionView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    // All done - submit
                    completionView
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
            }
            
            // Result overlay
            if showResult {
                resultOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadQuestions()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentQuestionIndex)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showResult)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 16) {
            // Back Button
            Button(action: {
                appViewModel.goBack()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            
            Spacer()
            
            // Title with icon
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text("Comprehension Check")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.98))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        )
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<questions.count, id: \.self) { index in
                    ZStack {
                        Capsule()
                            .fill(index < currentQuestionIndex ? Color.green : (index == currentQuestionIndex ? Color.blue : Color.gray.opacity(0.2)))
                            .frame(height: 8)
                        
                        if index < currentQuestionIndex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentQuestionIndex)
                }
            }
            .padding(.horizontal, 20)
            
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                
                Text("Question \(min(currentQuestionIndex + 1, questions.count)) of \(questions.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(Double(currentQuestionIndex) / Double(questions.count) * 100))% Complete")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            }
            
            Text("Great job reading!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text("No comprehension questions available for this text.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                appViewModel.goToTextLibrary()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 18))
                    Text("Back to Library")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.top, 12)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Question View
    
    private var questionView: some View {
        let question = questions[currentQuestionIndex]
        let options = (question.options ?? "").components(separatedBy: ",")
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Question Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        
                        Text("Question")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Text(question.question ?? "")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.08), radius: 15, y: 5)
                )
                
                // Answer options label
                HStack {
                    Image(systemName: "list.bullet.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                    
                    Text("Choose your answer:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 4)
                
                // Answer options
                VStack(spacing: 14) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        AnswerButton(
                            text: option,
                            index: index,
                            isSelected: selectedAnswer == option,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedAnswer = option
                                }
                            }
                        )
                    }
                }
                
                // Submit button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        animateSubmit.toggle()
                    }
                    submitAnswer(question: question, answer: selectedAnswer)
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                        Text("Submit Answer")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Group {
                            if selectedAnswer.isEmpty {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.4))
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
                            }
                        }
                    )
                    .scaleEffect(animateSubmit ? 1.05 : 1.0)
                }
                .disabled(selectedAnswer.isEmpty)
                .padding(.top, 8)
            }
            .padding(20)
        }
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 90))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
            }
            
            VStack(spacing: 12) {
                Text("All Questions Answered!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Great job completing all \(answers.count) questions!")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            
            // Stats Card
            HStack(spacing: 20) {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                    
                    Text("\(answers.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Answered")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                )
                
                VStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.orange)
                    
                    Text("100%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Complete")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                )
            }
            .padding(.horizontal, 30)
            
            // Finish Button
            Button(action: {
                appViewModel.submitComprehensionAnswers(answers: answers)
            }) {
                HStack(spacing: 10) {
                    Text("See Your Results")
                        .font(.system(size: 19, weight: .bold))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 22))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.4), radius: 15, y: 8)
            }
            .padding(.horizontal, 30)
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Result Overlay
    
    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismissal by tap
                }
            
            VStack(spacing: 0) {
                // Icon and Title
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        (isCorrect ? Color.green : Color.orange).opacity(0.2),
                                        (isCorrect ? Color.green : Color.orange).opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(isCorrect ? .green : .orange)
                            .shadow(color: isCorrect ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), radius: 10, y: 5)
                    }
                    
                    VStack(spacing: 8) {
                        Text(isCorrect ? "Correct!" : "Not quite right")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if isCorrect {
                            Text("Great job! Keep it up!")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 32)
                
                // Explanation (if incorrect)
                if !isCorrect, let question = lastAnsweredQuestion {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.orange)
                            
                            Text("The correct answer:")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        Text(question.correctAnswer ?? "")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.15))
                            )
                        
                        if let explanation = question.explanation, !explanation.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                    
                                    Text("Explanation:")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(explanation)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.05))
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                
                // Continue Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showResult = false
                        selectedAnswer = ""
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 30, y: 15)
            )
            .frame(maxWidth: 460)
            .padding(24)
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadQuestions() {
        guard let text = appViewModel.currentText else { return }
        
        let request: NSFetchRequest<ComprehensionQuestion> = ComprehensionQuestion.fetchRequest()
        request.predicate = NSPredicate(format: "text == %@", text)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ComprehensionQuestion.orderIndex, ascending: true)]
        
        do {
            questions = try viewContext.fetch(request)
        } catch {
            print("Error loading questions: \(error)")
        }
    }
    
    private func submitAnswer(question: ComprehensionQuestion, answer: String) {
        // Check if correct
        isCorrect = (answer == question.correctAnswer)
        
        // Store the question we just answered for the result overlay
        lastAnsweredQuestion = question
        
        // Save answer
        answers.append((question: question, answer: answer))
        
        // Show result
        showResult = true
        
        // Move to next question after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + (isCorrect ? 1.5 : 3.0)) {
            currentQuestionIndex += 1
            showResult = false
            selectedAnswer = ""
            lastAnsweredQuestion = nil
        }
    }
}

// MARK: - Answer Button

struct AnswerButton: View {
    let text: String
    let index: Int
    let isSelected: Bool
    let action: () -> Void
    
    private let letters = ["A", "B", "C", "D", "E", "F"]
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Letter indicator
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.15)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Text(letters[min(index, letters.count - 1)])
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                Text(text)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.9)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color.white]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.25), lineWidth: isSelected ? 2.5 : 1.5)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.04), radius: isSelected ? 10 : 5, y: isSelected ? 4 : 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ComprehensionCheckView()
        .environmentObject(AppViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


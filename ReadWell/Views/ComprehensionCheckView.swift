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
    
    var body: some View {
        ZStack {
            Color.beigeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Progress
                progressBar
                
                if questions.isEmpty {
                    // No questions available
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("Great job reading!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("No comprehension questions available for this text.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            appViewModel.goToTextLibrary()
                        }) {
                            Text("Back to Library")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                } else if currentQuestionIndex < questions.count {
                    // Question view
                    questionView
                } else {
                    // All done - submit
                    completionView
                }
                
                Spacer()
            }
            
            // Result overlay
            if showResult {
                resultOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadQuestions()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button(action: {
                appViewModel.goBack()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding()
            }
            
            Text("Comprehension Check")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color.white.opacity(0.95))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<questions.count, id: \.self) { index in
                    Capsule()
                        .fill(index < currentQuestionIndex ? Color.green : (index == currentQuestionIndex ? Color.blue : Color.gray.opacity(0.3)))
                        .frame(height: 6)
                }
            }
            .padding(.horizontal)
            
            Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Question View
    
    private var questionView: some View {
        let question = questions[currentQuestionIndex]
        let options = (question.options ?? "").components(separatedBy: ",")
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Question text
                Text(question.question ?? "")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                
                // Answer options
                VStack(spacing: 16) {
                    ForEach(options, id: \.self) { option in
                        AnswerButton(
                            text: option,
                            isSelected: selectedAnswer == option,
                            action: {
                                selectedAnswer = option
                            }
                        )
                    }
                }
                
                // Submit button
                Button(action: {
                    submitAnswer(question: question, answer: selectedAnswer)
                }) {
                    Text("Submit Answer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedAnswer.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(selectedAnswer.isEmpty)
                .padding(.top, 20)
            }
            .padding()
        }
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("All Questions Answered!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You answered \(answers.count) questions.")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button(action: {
                appViewModel.submitComprehensionAnswers(answers: answers)
            }) {
                Text("See Your Results")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    // MARK: - Result Overlay
    
    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(isCorrect ? .green : .orange)
                
                Text(isCorrect ? "Correct!" : "Not quite right")
                    .font(.title)
                    .fontWeight(.bold)
                
                if !isCorrect, let question = lastAnsweredQuestion {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("The correct answer is:")
                            .font(.headline)
                        
                        Text(question.correctAnswer ?? "")
                            .font(.body)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        
                        if let explanation = question.explanation, !explanation.isEmpty {
                            Text(explanation)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    showResult = false
                    selectedAnswer = ""
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
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
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ComprehensionCheckView()
        .environmentObject(AppViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


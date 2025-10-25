import SwiftUI
import CoreData

struct TextLibraryView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var texts: [ReadingText] = []
    @State private var selectedGradeFilter: Int16? = nil
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            Color.beigeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Filter bar
                filterBar
                
                // Text grid
                if filteredTexts.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filteredTexts, id: \.id) { text in
                                TextCard(text: text) {
                                    appViewModel.selectText(text)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadTexts()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    appViewModel.logoutStudent()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Hi, \(appViewModel.currentStudent?.name ?? "Student")!")
                        .font(.headline)
                    
                    Text("Grade \(appViewModel.currentStudent?.gradeLevel ?? 3)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(appViewModel.currentStudent?.name?.prefix(1) ?? "?"))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            .padding()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search for a story...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .background(Color.white.opacity(0.95))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    isSelected: selectedGradeFilter == nil
                ) {
                    selectedGradeFilter = nil
                }
                
                ForEach([1, 2, 3, 4, 5, 6], id: \.self) { grade in
                    FilterChip(
                        title: "Grade \(grade)",
                        isSelected: selectedGradeFilter == Int16(grade)
                    ) {
                        selectedGradeFilter = Int16(grade)
                    }
                }
            }
            .padding()
        }
        .background(Color.white.opacity(0.5))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No texts available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Ask your teacher to add reading materials")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var filteredTexts: [ReadingText] {
        var filtered = texts
        
        // Filter by grade
        if let grade = selectedGradeFilter {
            filtered = filtered.filter { $0.gradeLevel == grade }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            filtered = filtered.filter {
                ($0.title ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.content ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    // MARK: - Helper Functions
    
    private func loadTexts() {
        texts = appViewModel.getAllTexts()
    }
}

// MARK: - Text Card

struct TextCard: View {
    let text: ReadingText
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Grade badge
                HStack {
                    Text("Grade \(text.gradeLevel)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    if let category = text.category, !category.isEmpty {
                        Text(category)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Title
                Text(text.title ?? "Untitled")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Excerpt
                Text(text.content ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Read button
                HStack {
                    Image(systemName: "book.fill")
                        .font(.caption)
                    Text("Start Reading")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.blue)
            }
            .padding()
            .frame(height: 180)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TextLibraryView()
        .environmentObject(AppViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


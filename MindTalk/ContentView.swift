import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                switch appViewModel.currentView {
                case .start:
                    StartView()
                        .environmentObject(appViewModel)
                case .guidedTalk:
                    GuidedTalkView()
                        .environmentObject(appViewModel)
                case .summary:
                    SummaryView()
                        .environmentObject(appViewModel)
                case .reflection:
                    ReflectionView()
                        .environmentObject(appViewModel)
                case .weeklyReview:
                    WeeklyReviewView()
                        .environmentObject(appViewModel)
                case .calendar:
                    CalendarView()
                        .environmentObject(appViewModel)
                }
            }
        }
        .onAppear {
            appViewModel.initializeApp(context: viewContext)
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

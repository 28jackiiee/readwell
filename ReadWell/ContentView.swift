import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some View {
        Group {
            switch appViewModel.currentView {
            case .authentication:
                AuthenticationView()
                    .environmentObject(appViewModel)
                    .environment(\.managedObjectContext, viewContext)
                
            case .studentLogin:
                NavigationView {
                    StudentLoginView()
                        .environmentObject(appViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                
            case .teacherDashboard:
                TeacherDashboardView()
                    .environmentObject(appViewModel)
                    .environment(\.managedObjectContext, viewContext)
                
            case .textLibrary:
                TextLibraryView()
                    .environmentObject(appViewModel)
                    .environment(\.managedObjectContext, viewContext)
                
            case .reading:
                ReadingView()
                    .environmentObject(appViewModel)
                    .environment(\.managedObjectContext, viewContext)
                
            case .selfReadingPractice:
                SelfReadingPracticeView()
                    .environmentObject(appViewModel)
                    .environment(\.managedObjectContext, viewContext)
                
            case .comprehensionCheck:
                ComprehensionCheckView()
                    .environmentObject(appViewModel)
                    .environment(\.managedObjectContext, viewContext)
                
            case .studentProgress:
                StudentProgressView()
                    .environmentObject(appViewModel)
                    .environment(\.managedObjectContext, viewContext)
                
            case .settings:
                Text("Settings")
                    .font(.title)
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

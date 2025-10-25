import SwiftUI
import FirebaseCore

@main
struct ReadWellApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

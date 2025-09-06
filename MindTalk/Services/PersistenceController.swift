import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleSession = CheckInSession(context: viewContext)
        sampleSession.date = Date()
        sampleSession.transcript = "Today was a good day. I felt productive and accomplished my goals."
        sampleSession.summary = "Productive day with goal achievement"
        sampleSession.energyLevel = 8
        sampleSession.intent = "productivity"
        sampleSession.coreTheme = "Achievement and progress"
        
        let sampleEmotion = Emotion(context: viewContext)
        sampleEmotion.name = "Happy"
        sampleEmotion.intensity = 7.5
        sampleEmotion.color = "yellow"
        sampleEmotion.session = sampleSession
        
        let sampleAction = Action(context: viewContext)
        sampleAction.title = "Call mom for 10 minutes"
        sampleAction.dueTime = "evening"
        sampleAction.category = "relationships"
        sampleAction.session = sampleSession
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

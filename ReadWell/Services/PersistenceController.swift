import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample student
        let student = Student(context: viewContext)
        student.id = UUID()
        student.name = "Alex Johnson"
        student.gradeLevel = 4
        student.preferredLanguage = "en"
        student.secondLanguage = "es"
        student.useDyslexiaFont = true
        student.fontSize = 20
        student.lineSpacing = 1.8
        student.backgroundColor = "beige"
        student.createdDate = Date()
        
        // Create sample reading text
        let text = ReadingText(context: viewContext)
        text.id = UUID()
        text.title = "The Helpful Dolphin"
        text.content = """
        Once upon a time, there was a friendly dolphin named Splash. Splash lived in the ocean with many fish friends. One day, a small fish got caught in a net. Splash saw the fish struggling and knew he had to help. He used his strong nose to push the net until it opened. The little fish swam free! All the fish thanked Splash for being so brave and kind.
        """
        text.gradeLevel = 3
        text.language = "en"
        text.translationLanguage = "es"
        text.translatedContent = """
        Había una vez un delfín amigable llamado Splash. Splash vivía en el océano con muchos amigos peces. Un día, un pez pequeño quedó atrapado en una red. Splash vio al pez luchando y supo que tenía que ayudar. Usó su nariz fuerte para empujar la red hasta que se abrió. ¡El pez pequeño nadó libre! Todos los peces agradecieron a Splash por ser tan valiente y amable.
        """
        text.category = "Fiction"
        text.dateAdded = Date()
        
        // Create sample comprehension questions
        let q1 = ComprehensionQuestion(context: viewContext)
        q1.id = UUID()
        q1.question = "What is the dolphin's name?"
        q1.questionType = "multipleChoice"
        q1.options = "Splash,Flipper,Bubbles,Wave"
        q1.correctAnswer = "Splash"
        q1.explanation = "The story tells us the dolphin's name is Splash."
        q1.orderIndex = 0
        q1.text = text
        
        let q2 = ComprehensionQuestion(context: viewContext)
        q2.id = UUID()
        q2.question = "What problem did the small fish have?"
        q2.questionType = "multipleChoice"
        q2.options = "It was hungry,It was lost,It was caught in a net,It was scared"
        q2.correctAnswer = "It was caught in a net"
        q2.explanation = "The story says a small fish got caught in a net."
        q2.orderIndex = 1
        q2.text = text
        
        let q3 = ComprehensionQuestion(context: viewContext)
        q3.id = UUID()
        q3.question = "How did Splash help the fish?"
        q3.questionType = "multipleChoice"
        q3.options = "He called for help,He cut the net,He pushed the net with his nose,He gave the fish food"
        q3.correctAnswer = "He pushed the net with his nose"
        q3.explanation = "Splash used his strong nose to push the net until it opened."
        q3.orderIndex = 2
        q3.text = text
        
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
    
    /// Clears all data from the database
    func clearDatabase() {
        let context = container.viewContext
        
        // List of all entities to clear
        let entityNames = [
            "StudentAnswer",
            "ReadingSession",
            "ComprehensionQuestion",
            "ReadingText",
            "Student",
            "Teacher",
            "TeacherSettings"
        ]
        
        // Delete all objects for each entity
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            
            do {
                let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
                
                // Merge changes into the view context
                if let objectIDs = result?.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                }
                
                print("✅ Cleared \(entityName)")
            } catch {
                print("❌ Error clearing \(entityName): \(error.localizedDescription)")
            }
        }
        
        // Save the context
        save()
        print("🗑️ Database cleared successfully!")
    }
}

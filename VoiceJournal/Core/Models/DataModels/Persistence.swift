//
//  Persistence.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 6/16/24.
//

import CoreData

struct Persistence {
    static let shared = Persistence()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Register the transformers
       ValueTransformer.setValueTransformer(EmotionsTransformer(), forName: NSValueTransformerName("EmotionsTransformer"))
       ValueTransformer.setValueTransformer(EmotionColorsTransformer(), forName: NSValueTransformerName("EmotionColorsTransformer"))
      
        container = NSPersistentContainer(name: "VoiceJournal")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

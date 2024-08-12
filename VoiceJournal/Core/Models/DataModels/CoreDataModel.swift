//
//  CoreDataModel.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 6/9/24.
//

import Foundation
import CoreData
import CloudKit
import Combine
import SwiftUI


class CoreDataModel: NSObject, ObservableObject {
    // Share CoreDataModel to 
    static let shared = CoreDataModel()

    // Initialization
    init(inMemory: Bool = false) {
        let container = NSPersistentCloudKitContainer(name: "VoiceJournal")

        // Assign your CloudKit container options
        let containerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.VoiceJournalContainer")
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            fatalError("No Descriptions found")
        }
        storeDescription.cloudKitContainerOptions = containerOptions
        
        if inMemory {
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
        }

        self.persistentContainer = container
        super.init()
        
        // Register custom transformers
        ValueTransformer.setValueTransformer(EmotionsTransformer(), forName: NSValueTransformerName("EmotionsTransformer"))
        ValueTransformer.setValueTransformer(EmotionColorsTransformer(), forName: NSValueTransformerName("EmotionColorsTransformer"))
        
        // Enable remote notifications for CloudKit
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(persistentStoreRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator
        )

        persistentContainer.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                // Enable CloudKit syncing options
                self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
                self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            }
        }
        setupFetchedResultsController()
    }
    
    // Container and Controller
    let persistentContainer: NSPersistentCloudKitContainer
    lazy var viewContext: NSManagedObjectContext = {
        let container = persistentContainer
        let context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return context
    }()
    
    private var fetchedResultsController: NSFetchedResultsController<Journal>!

    private func setupFetchedResultsController() {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<Journal> = Journal.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch journals: \(error)")
        }
    }
    
    // MARK: - Save and store data
    
    // Save changes
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                syncToCloudKit()
                print("Changes saved to Core Data")
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func syncToCloudKit() {
        do {
            try persistentContainer.viewContext.setQueryGenerationFrom(.current)
            try persistentContainer.viewContext.save()
            print("Successfully synced to CloudKit")
        } catch {
            print("Failed to sync to CloudKit: \(error)")
        }
    }
    
    // Complete partial journal
    func completeJournal(partialJournal: Journal) {
        let fetchRequest: NSFetchRequest<Journal> = Journal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "audioFileName == %@", partialJournal.audioFileName!)

        do {
            let journals = try viewContext.fetch(fetchRequest)
            if let journal = journals.first {
                // Update existing journal with emotions, colors, etc.
                journal.emotions = partialJournal.emotions
                journal.emotionColors = partialJournal.emotionColors // Assuming these properties are added to Journal entity
                // Add other updates as needed

                try viewContext.save()
                print("Journal updated successfully")
            } else {
                // Handle case where journal doesn't exist
                print("No journal found for audio file name \(partialJournal.audioFileName!)")
            }
        } catch {
            print("Failed to update journal: \(error.localizedDescription)")
        }
    }
    
    // Function to provide viewContext
    func getViewContext() -> NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // Add journal to Core Data
    func addJournal(audioFileName: String, date: Date, duration: Double, isBookmarked: Bool, journalDescription: String, name: String, emotions: [String], emotionColors: [Color]) {
        let context = persistentContainer.viewContext
        let newJournal = Journal(context: context)
        newJournal.audioFileName = audioFileName
        newJournal.date = date
        newJournal.duration = duration
        newJournal.isBookmarked = isBookmarked
        newJournal.journalDescription = journalDescription
        newJournal.name = name
        
        // Convert emotions to NSArray and save
        let nsEmotions = emotions as NSArray
        newJournal.emotions = nsEmotions
        
        // Convert emotionColors to NSArray and save
        let nsEmotionColors = emotionColors.map { UIColor($0) } as NSArray
        newJournal.emotionColors = nsEmotionColors
        
        do {
            try context.save()
            print("Journal added to Core Data successfully")
            // Call function to add Journal to Cloud Kit
            addJournalToCloudKit(audioFileName: audioFileName, date: date, duration: duration, isBookmarked: isBookmarked, journalDescription: journalDescription, name: name, emotions: emotions, emotionColors: emotionColors.map { UIColor($0) })

        } catch {
            print("Failed to save journal: \(error)")
        }
    }
    
    // Add Journal to CloudKit
    func addJournalToCloudKit(audioFileName: String, date: Date, duration: Double, isBookmarked: Bool, journalDescription: String, name: String, emotions: [String], emotionColors: [UIColor]) {
        let record = CKRecord(recordType: "Journal")
        record["audioFileName"] = audioFileName as NSString
        record["date"] = date as NSDate
        record["duration"] = duration as NSNumber
        record["isBookmarked"] = isBookmarked as NSNumber
        record["journalDescription"] = journalDescription as NSString
        record["name"] = name as NSString
        // Store emotions as NSArray
        record["emotions"] = emotions as NSArray
        // Convert UIColor to hex strings and store them as NSArray
        record["emotionColors"] = emotionColors.map { $0.toHexString() } as NSArray

        let database = CKContainer(identifier: "iCloud.VoiceJournalContainer").privateCloudDatabase
        database.save(record) { record, error in
            if let error = error {
                print("Error saving record to CloudKit: \(error.localizedDescription)")
            } else {
                print("Record saved to CloudKit successfully.")
            }
        }
    }
    
    // MARK: - Dummy Data
    // Create dummy data for testing
    func populateDummyData() {
        let context = persistentContainer.viewContext
        
        // Example data
        let sampleJournals: [(String, Date, Double, Bool, String, String, [String], [Color])] = [
            ("sample.m4a", Date(), 30.0, false, "Meeting notes", "Daily Standup Notes", ["joy", "happiness"], [.blue, .green]),
            ("sample.m4a", Date().addingTimeInterval(-86400), 45.0, true, "Personal thoughts", "Morning Meditation", ["calm", "neutral"], [.gray, .white]),
            ("sample.m4a", Date().addingTimeInterval(-259200), 15.0, false, "Project update", "Sprint Planning", ["sadness", "anger"], [.red, .orange]),
            ("sample.m4a", Date().addingTimeInterval(-777600), 60.0, true, "Hobby time", "Guitar Practice", ["joy", "happiness"], [.yellow, .purple])
        ]

        for (audioFileName, date, duration, isBookmarked, journalDescription, name, emotions, emotionColors) in sampleJournals {
            let newJournal = Journal(context: context)
            newJournal.audioFileName = audioFileName
            newJournal.date = date
            newJournal.duration = duration
            newJournal.isBookmarked = isBookmarked
            newJournal.journalDescription = journalDescription
            newJournal.name = name
            
            // Convert emotions to NSArray (for Core Data storage)
            let nsEmotions = emotions as NSArray
            newJournal.emotions = nsEmotions
            
            // Convert emotionColors to NSArray (for Core Data storage)
            let nsEmotionColors = emotionColors.map { UIColor($0) } as NSArray
            newJournal.emotionColors = nsEmotionColors
        }

        do {
            try context.save()
            print("Dummy data populated successfully")
            // Call addJournalToCloudKit
            for journal in sampleJournals {
                addJournalToCloudKit(audioFileName: journal.0, date: journal.1, duration: journal.2, isBookmarked: journal.3, journalDescription: journal.4, name: journal.5, emotions: journal.6, emotionColors: journal.7.map { UIColor($0) })
            }
        } catch {
            print("Failed to save dummy data: \(error)")
        }
    }
    
    // MARK: - Notification
    @objc
    private func persistentStoreRemoteChange(_ notification: Notification) {
        print("Persistent store remote change detected.")
        // Handle remote changes from CloudKit here
        self.setupFetchedResultsController()
    }
}

extension CoreDataModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        objectWillChange.send()
    }
}

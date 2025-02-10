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
    // Shared instance
    static let shared = CoreDataModel()
    
    // Persistent container
    let persistentContainer: NSPersistentCloudKitContainer
    
    // Initialization
    init(inMemory: Bool = false) {
        // Use NSPersistentCloudKitContainer (if you want to temporarily disable CloudKit,
        // you could switch to NSPersistentContainer instead)
        let container = NSPersistentCloudKitContainer(name: "VoiceJournal")
        
        // Assign CloudKit container options
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
        
        // Register for persistent store remote change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(persistentStoreRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator
        )
        
        // Load persistent stores
        persistentContainer.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
                self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            }
        }
        
        setupFetchedResultsController()
    }
    
    // Lazy viewContext property
    lazy var viewContext: NSManagedObjectContext = {
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    // Fetched Results Controller
    private var fetchedResultsController: NSFetchedResultsController<Journal>!
    
    private func setupFetchedResultsController() {
        let request: NSFetchRequest<Journal> = Journal.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: viewContext,
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
    
    // MARK: - Save and Store Data
    
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
    
    func completeJournal(for audioFileURL: URL, withTranscription transcription: String) {
        let request: NSFetchRequest<Journal> = Journal.fetchRequest()
        request.predicate = NSPredicate(format: "audioFileName == %@", audioFileURL.lastPathComponent)
        
        do {
            let journals = try viewContext.fetch(request)
            if let journal = journals.first {
                journal.audioTranscription = transcription
                try viewContext.save()
                print("Journal updated with transcription.")
            } else {
                print("No journal found for audio file name \(audioFileURL.lastPathComponent)")
            }
        } catch {
            print("Failed to update journal: \(error.localizedDescription)")
        }
    }
    
    func getViewContext() -> NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func addJournal(audioFileName: String, date: Date, duration: Double, isBookmarked: Bool, journalDescription: String, name: String) {
        let context = persistentContainer.viewContext
        let newJournal = Journal(context: context)
        newJournal.audioFileName = audioFileName
        newJournal.date = date
        newJournal.duration = duration
        newJournal.isBookmarked = isBookmarked
        newJournal.journalDescription = journalDescription
        newJournal.name = name
        
        do {
            try context.save()
            print("Journal added to Core Data successfully")
            addJournalToCloudKit(audioFileName: audioFileName, date: date, duration: duration, isBookmarked: isBookmarked, journalDescription: journalDescription, name: name)
        } catch {
            print("Failed to save journal: \(error)")
        }
    }
    
    func addJournalToCloudKit(audioFileName: String, date: Date, duration: Double, isBookmarked: Bool, journalDescription: String, name: String) {
        let record = CKRecord(recordType: "Journal")
        record["audioFileName"] = audioFileName as NSString
        record["date"] = date as NSDate
        record["duration"] = duration as NSNumber
        record["isBookmarked"] = isBookmarked as NSNumber
        record["journalDescription"] = journalDescription as NSString
        record["name"] = name as NSString
        
        let database = CKContainer(identifier: "iCloud.VoiceJournalContainer").privateCloudDatabase
        database.save(record) { record, error in
            if let error = error {
                print("Error saving record to CloudKit: \(error.localizedDescription)")
            } else {
                print("Record saved to CloudKit successfully.")
            }
        }
    }
    
    func populateDummyData() {
        let context = persistentContainer.viewContext
        let sampleJournals: [(String, Date, Double, Bool, String, String)] = [
            ("sample.m4a", Date(), 30.0, false, "Meeting notes", "Daily Standup Notes"),
            ("sample.m4a", Date().addingTimeInterval(-86400), 45.0, true, "Personal thoughts", "Morning Meditation"),
            ("sample.m4a", Date().addingTimeInterval(-259200), 15.0, false, "Project update", "Sprint Planning"),
            ("sample.m4a", Date().addingTimeInterval(-777600), 60.0, true, "Hobby time", "Guitar Practice")
        ]
        
        for (audioFileName, date, duration, isBookmarked, journalDescription, name) in sampleJournals {
            let newJournal = Journal(context: context)
            newJournal.audioFileName = audioFileName
            newJournal.date = date
            newJournal.duration = duration
            newJournal.isBookmarked = isBookmarked
            newJournal.journalDescription = journalDescription
            newJournal.name = name
        }
        
        do {
            try context.save()
            print("Dummy data populated successfully")
            for journal in sampleJournals {
                addJournalToCloudKit(audioFileName: journal.0, date: journal.1, duration: journal.2, isBookmarked: journal.3, journalDescription: journal.4, name: journal.5)
            }
        } catch {
            print("Failed to save dummy data: \(error)")
        }
    }
    
    @objc func persistentStoreRemoteChange(_ notification: Notification) {
        print("Persistent store remote change detected.")
        setupFetchedResultsController()
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension CoreDataModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        objectWillChange.send()
    }
}

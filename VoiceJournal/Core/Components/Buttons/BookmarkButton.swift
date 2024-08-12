//
//  BookmarkButton.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 6/10/24.
//

import SwiftUI
import CoreData

struct BookmarkButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var journal: Journal
    
    private func saveContext() {
        do {
            guard viewContext.hasChanges else {
                return
            }
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error saving context: \(nsError), \(nsError.userInfo)")
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    var body: some View {
        Button {
            journal.isBookmarked.toggle()
            saveContext()
        } label: {
            Label("Toggle Bookmark", systemImage: journal.isBookmarked ? "heart.fill" : "heart")
                .labelStyle(.iconOnly)
                .foregroundStyle(journal.isBookmarked ? Color("AccentColor") : Color("SoftContrastColor"))
        }
    }
}

struct BookmarkButton_Previews: PreviewProvider {
    static var previews: some View {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let journal = Journal(context: context)
        journal.isBookmarked = true
        
        return BookmarkButton(journal: journal)
            .environment(\.managedObjectContext, context)
    }
}

//
//  JournalRow.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 6/9/24.
//

import SwiftUI
import CoreData

struct JournalRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var journal: Journal
    @State private var isShowingDeleteConfirmation = false

    private var formattedDate: String {
        guard let journalDate = journal.date else { return "" }
        return FormatterUtils.shared.formatDate(journalDate)
    }
    
    private var formattedDuration: String {
        return FormatterUtils.shared.formatDuration(journal.duration)
    }
    
    private func deleteJournal() {
        withAnimation {
            viewContext.delete(journal)
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete journal: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleBookmark() {
        withAnimation {
            journal.isBookmarked.toggle()
            do {
                try viewContext.save()
            } catch {
                print("Failed to toggle bookmark: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                if let journalName = journal.name, journalName.count > 30 {
                    let trimmedText = journalName.prefix(30)
                    
                    if let lastIndex = trimmedText.lastIndex(of: " ") {
                        let truncatedString = trimmedText[..<lastIndex] + "..."
                        Text(String(truncatedString))
                    } else {
                        Text(trimmedText + "...")
                    }
                } else {
                    Text(journal.name ?? "Untitled Journal")
                }
                Spacer()
            }
            .font(.title3)

            HStack {
                if journal.isBookmarked {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Color("AccentColor"))
                }
                Text(formattedDate)
                Spacer()
                Text(formattedDuration)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .swipeActions {
            Button(role: .destructive) {
                deleteJournal()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                toggleBookmark()
            } label: {
                Label("Bookmark", systemImage: journal.isBookmarked ? "heart.slash.fill" : "heart.fill")
            }
            .tint(journal.isBookmarked ? Color("SoftContrastColor") : Color("AccentColor"))
        }
    }
}

#if DEBUG
struct JournalRow_Previews: PreviewProvider {
    static var previews: some View {
        let coreDataModel = CoreDataModel()
        let context = coreDataModel.persistentContainer.viewContext
        
        // Populate dummy data
        coreDataModel.populateDummyData()
        
        // Fetch a sample journal entry for preview
        let fetchRequest: NSFetchRequest<Journal> = Journal.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let sampleJournals = try context.fetch(fetchRequest)
                if sampleJournals.count >= 3 {
                    let sampleJournal = sampleJournals[2]
                    return AnyView(
                        JournalRow(journal: sampleJournal)
                            .environment(\.managedObjectContext, context)
                    )
            } else {
                return AnyView(Text("Not enough sample journals available"))
            }
        } catch {
            return AnyView(Text("Failed to fetch sample journals: \(error)"))
        }
    }
}
#endif

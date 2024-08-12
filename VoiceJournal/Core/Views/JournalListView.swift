//
//  JournalListView.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 6/9/24.
//

import SwiftUI
import CoreData

struct JournalListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showBookmarkedOnly = false
    @State private var searchText = ""
    @State private var selectedJournal: Journal?
    
    // Use @FetchRequest to automatically fetch and listen for changes
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Journal.date, ascending: false)],
        animation: .default
    ) private var allJournals: FetchedResults<Journal>
    
    // Filtered journals based on the toggle state
    private var filteredJournals: [Journal] {
        if searchText.isEmpty {
            // If search text is empty, show all journals or filtered by bookmarks
            if showBookmarkedOnly {
                return allJournals.filter { $0.isBookmarked }
            } else {
                return Array(allJournals)
            }
        } else {
            // Filter by search text and bookmarks
            return allJournals.filter { journal in
                let title = journal.name ?? ""
                let description = journal.journalDescription ?? ""
                let searchTextLowercased = searchText.lowercased()
                
                let matchesTitle = title.localizedCaseInsensitiveContains(searchTextLowercased)
                let matchesDescription = description.localizedCaseInsensitiveContains(searchTextLowercased)
                
                return (matchesTitle || matchesDescription) &&
                       (showBookmarkedOnly ? journal.isBookmarked : true)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    SearchBar(searchText: $searchText)
                        .padding()

                    List {
                        ForEach(filteredJournals, id: \.self) { journal in
                            Button(action: {
                                selectedJournal = journal
                            }) {
                                JournalRow(journal: journal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(.inset)
                    .animation(.default, value: showBookmarkedOnly)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        RecordButton(buttonSize: 80, viewContext: viewContext)
                    }
                }
            }
            .navigationTitle("Journals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: showBookmarkedOnly ? "heart.fill" : "heart")
                        .foregroundColor(.accentColor)
                        .onTapGesture {
                            showBookmarkedOnly.toggle()
                        }
                }
            }
        }
        .sheet(item: $selectedJournal) { journal in
            JournalView(journal: journal)
        }
    }
}

// MARK: - Previews
struct JournalListView_Previews: PreviewProvider {
    static var previews: some View {
        let coreDataModel = CoreDataModel.preview
        
        return JournalListView()
            .environment(\.managedObjectContext, coreDataModel.getViewContext())
    }
}

// Add this extension to provide a preview container
extension CoreDataModel {
    static var preview: CoreDataModel {
        let model = CoreDataModel(inMemory: true)
        model.populateDummyData()
        return model
    }
}

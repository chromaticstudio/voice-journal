//
//  JournalView.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 6/9/24.
//

import SwiftUI
import AVFoundation
import CoreData

struct JournalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var journal: Journal
    @State private var title = ""
    @State private var description = ""
    
    private func getAudioURL(for fileName: String) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsDirectory?.appendingPathComponent(fileName)
    }
    
    private var formattedDate: String {
        guard let journalDate = journal.date else { return "" }
        return FormatterUtils.shared.formatDayDate(journalDate)
    }
    
    private var formattedDuration: String {
        return FormatterUtils.shared.formatDuration(journal.duration)
    }

    var body: some View {        
        VStack {
            VStack {
                ZStack(alignment: .bottomLeading) {
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            
                            TextField("Name this entry", text: $title, onCommit: {
                                journal.name = title
                                try? viewContext.save()
                            })
                            .font(.system(size: min(geometry.size.width, 30)))
                            .fontWeight(.heavy)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                        }
                    }
                    .padding()
                }
                .frame(height: 300)
                
                VStack (alignment: .leading, spacing: 20) {
                    HStack (spacing: 5) {
                        Image(systemName: "calendar")
                        Text(formattedDate)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack (alignment: .leading) {
                        if (journal.audioTranscription != nil) {
                            Text(journal.audioTranscription ?? "")
                        } else {
                            HStack (spacing: 10) {
                                Text("Preparing transcription")
                                    .foregroundColor(.gray)
                                ProgressView()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("InputFillColor"))
                            .cornerRadius(10)
                        }
                    }
                    
                    TextField("Write a brief description", text: $description, onCommit: {
                        journal.journalDescription = description
                        try? viewContext.save()
                    })
                }
                .padding()
                
                Spacer()

                VStack {
                    if let audioFileName = journal.audioFileName, let audioURL = getAudioURL(for: audioFileName) {
                        Playback(audioURL: audioURL, journal: journal)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            title = journal.name ?? "Untitled Journal"
            description = journal.journalDescription ?? ""
        }
    }
}


#if DEBUG
struct JournalView_Previews: PreviewProvider {
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
                    let sampleJournal = sampleJournals[0]
                    return AnyView(
                        JournalView(journal: sampleJournal)
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

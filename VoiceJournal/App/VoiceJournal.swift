//
//  VoiceJournal.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 6/9/24.
//

import SwiftUI
import Firebase

@main
struct VoiceJournalApp: App {
    @StateObject var viewModel = AuthViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let coreDataModel = CoreDataModel.shared
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environment(\.managedObjectContext, coreDataModel.getViewContext())
        }
    }
}

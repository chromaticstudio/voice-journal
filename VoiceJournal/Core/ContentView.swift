//
//  ContentView.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 6/9/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        Group {
            if viewModel.userSession != nil {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                    JournalListView()
                        .tabItem {
                            Label("Journals", systemImage: "book")
                        }
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person")
                        }
                   
                    // Only show DevToolsView in debug builds.
                    #if DEBUG
                    DevToolsView()
                        .tabItem {
                            Label("Dev Tools", systemImage: "wrench")
                        }
                    #endif
                }
                .accentColor(Color("AccentColor"))
            } else {
                LoginView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = User(id: UUID().uuidString, fullname: "Anthony Mistretta", email: "anthony@chromatic.so")
        
        let mockViewModel = AuthViewModel()
        mockViewModel.currentUser = mockUser
        
        return ContentView()
            .environmentObject(mockViewModel)
    }
}

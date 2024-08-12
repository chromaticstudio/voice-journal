//
//  HomeView.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/10/24.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        if let user = viewModel.currentUser {
            VStack (alignment: .leading) {
                Spacer()
                
                VStack (alignment: .leading, spacing: 20) {
                    VStack (alignment: .leading) {
                        Text("👋 Welcome to Voice Journal,")
                            .foregroundStyle(Color.secondary)
                        Text("\(user.firstname)")
                    }
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    
                    Text("Take a moment to reflect on a recent experience that brought you joy.")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.secondary)
                    
                    HStack {
                        Spacer()
                        RecordButton(buttonSize: 80, viewContext: viewContext)
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let coreDataModel = CoreDataModel.preview
        let mockUser = User(id: UUID().uuidString, fullname: "Anthony Mistretta", email: "anthony@chromatic.so")
        
        let mockViewModel = AuthViewModel()
        mockViewModel.currentUser = mockUser
        
        return HomeView()
            .environment(\.managedObjectContext, coreDataModel.getViewContext())
            .environmentObject(mockViewModel)
    }
}

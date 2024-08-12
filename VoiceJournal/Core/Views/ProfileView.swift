//
//  ProfileView.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/12/24.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        if let user = viewModel.currentUser {
            NavigationStack {
                VStack {
                    List {
                        Section {
                            HStack (spacing: 20) {
                                Text(user.initials)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .frame(width: 80, height: 80)
                                    .background(Circle().foregroundColor(Color("AccentColor")))
                                
                                VStack (alignment: .leading) {
                                    Text(user.fullname)
                                        .fontWeight(.semibold)
                                    Text(user.email)
                                        .font(.subheadline)
                                        .accentColor(.secondary)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        Section ("General") {
                            Button {
                                viewModel.signOut()
                            } label: {
                                SettingsRow(title: "Sign Out",
                                                imageName: "power",
                                                tintColor: Color.red)
                            }
                        }
                    }
                    .listStyle(.inset)
                    
                    Spacer()
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .padding()
                }
                .navigationTitle("Account")
            }
        }
    }
    
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = User(id: UUID().uuidString, fullname: "Anthony Mistretta", email: "anthony@chromatic.so")
        
        let mockViewModel = AuthViewModel()
        mockViewModel.currentUser = mockUser
        
        return ProfileView()
            .environmentObject(mockViewModel)
    }
}

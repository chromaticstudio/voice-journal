//
//  SignUpView.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/12/24.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    @State private var email = ""
    @State private var fullname = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack (alignment: .leading, spacing: 20) {
                // Form
                InputView(text: $fullname,
                          title: "Name",
                          placeholder: "Full Name",
                          image: "person")
                
                InputView(text: $email,
                          title: "Email",
                          placeholder: "name@email.com",
                          image: "envelope")
                .autocapitalization(.none)
                
                InputView(text: $password,
                          title: "Password",
                          placeholder: "password",
                          image: "lock",
                          isSecureField: true)
                .autocapitalization(.none)
                
                // Sign Up Button
                PrimaryButton(text: "Save",
                              imageName: "arrow.right",
                              action: {
                                    Task {
                                        try await viewModel.signUp(withEmail: email,
                                                                   password: password,
                                                                   fullname: fullname)
                                    }
                                })
                .disabled(!formIsValid)
                .background(formIsValid ? Color("AccentColor") : Color("SoftContrastColor"))
                .cornerRadius(10)
                .padding(.top)
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
                            
                // Already have an account?
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("Already have an account? Login")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Signup")
            .padding()
        }
    }
}

//MARK: - AuthenticationFormProtocol
extension SignUpView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty
        && email.contains("@")
        && !password.isEmpty
        && password.count > 5
        && !fullname.isEmpty
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        return SignUpView()
    }
}

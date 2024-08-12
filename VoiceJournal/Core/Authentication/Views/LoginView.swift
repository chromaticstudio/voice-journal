//
//  LoginView.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/12/24.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack (alignment: .leading, spacing: 20) {
                // Form
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

                // Sign In Button
                PrimaryButton(text: "Submit",
                                  imageName: "arrow.right",
                                  action: {
                                        Task {
                                            try await viewModel.signIn(withEmail: email, password: password)
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
                
                // Don't have an account?
                HStack {
                    Spacer()
                    NavigationLink {
                        SignUpView()
                            .navigationBarBackButtonHidden()
                    } label: {
                        Text("Don't have an account? Sign up")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Login")
            .padding()
        }
    }
}

//MARK: - AuthenticationFormProtocol
extension LoginView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty
        && email.contains("@")
        && !password.isEmpty
        && password.count > 5
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        return LoginView()
    }
}

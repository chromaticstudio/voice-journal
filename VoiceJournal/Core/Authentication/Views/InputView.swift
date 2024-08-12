//
//  InputView.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/12/24.
//

import SwiftUI

struct InputView: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    let image: String?
    var isSecureField = false
    
    var body: some View {
        VStack (alignment: .leading, spacing: 10) {
            Text(title)
                .fontWeight(.semibold)
                .font(.footnote)
            
            HStack (spacing: 10) {
                Image(systemName: image ?? "")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundColor(.gray)
                VStack {
                    if isSecureField {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .frame(minHeight: 48)
            }
            .padding(.horizontal)
            .background(Color("SoftContrastColor"))
            .cornerRadius(10)
        }
    }
}

struct InputView_Previews: PreviewProvider {
    static var previews: some View {
        return InputView(text: .constant("anthony@chromatic.so"), title: "Email", placeholder: "name@email.com", image: "lock", isSecureField: false)
    }
}

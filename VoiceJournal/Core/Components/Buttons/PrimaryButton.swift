//
//  PrimaryButtonView.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/12/24.
//

import SwiftUI

struct PrimaryButton: View {
    let text: String
    let imageName: String
    let action: () -> Void
    
    var body: some View {
        Button (action: action) {
            HStack {
                Text(text)
                Image(systemName: imageName)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(Color("SoftContrastColor"))
        .cornerRadius(10)
        .foregroundColor(.primary)
    }
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryButton(text: "Submit", imageName: "arrow.right", action: {
            print("Button tapped")
        })
    }
}

//
//  DevToolsView.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 2/8/25.
//

import SwiftUI

struct DevToolsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                PrimaryButton(text: "Tap Me", imageName: "arrow.right", action: {
                    print("Button tapped")
                })
            }
            .padding()
            .navigationTitle("Developer Tools")
        }
    }
}

struct DevToolsView_Previews: PreviewProvider {
    static var previews: some View {
        DevToolsView()
    }
}

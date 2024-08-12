//
//  SettingsRow.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/12/24.
//

import SwiftUI

struct SettingsRow: View {
    let title: String
    let text: String?
    let imageName: String
    let tintColor: Color
    
    init(title: String, text: String? = nil, imageName: String, tintColor: Color = .primary) {
        self.title = title
        self.text = text
        self.imageName = imageName
        self.tintColor = tintColor
    }
    
    var body: some View {
        HStack {
            Image(systemName: imageName)
            Text(title)
            Spacer()
            if let text = text {
                Text(text)
            }
        }
        .foregroundColor(tintColor)
    }
}

struct SettingsRow_Previews: PreviewProvider {
    static var previews: some View {
        SettingsRow(title: "Settings", imageName: "gear")
    }
}

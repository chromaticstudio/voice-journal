//
//  MoodRingCircle.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/16/24.
//

import SwiftUI

struct MoodRingCircle: View {
    @State var ringSize = 100.0
    
    var body: some View {
        Image("gradient")
            .resizable()
            .scaledToFill()
            .frame(width: ringSize, height: ringSize)
            .clipShape(Circle())
    }
}

struct MoodRingCircle_Previews: PreviewProvider {
    static var previews: some View {
        MoodRingCircle(ringSize: 200.0)
    }
}

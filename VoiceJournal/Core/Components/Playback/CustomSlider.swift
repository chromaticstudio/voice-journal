//
//  CustomSlider.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/9/24.
//

import SwiftUI

struct CustomSlider: View {
    @Binding var currentTime: TimeInterval
    @StateObject var playerManager: PlayerManager
    
    var body: some View {
        VStack {
            Slider(value: $currentTime, in: 0...(playerManager.player?.duration ?? 0)) { isScrubbing in
               if isScrubbing {
                   playerManager.player?.currentTime = currentTime
               }
            }
            .accentColor(Color("SoftContrastColor"))
            .background(
                Capsule() // Background
                    .fill(Color.clear) // Gray background with opacity
                    .frame(height: 8) // Adjust the height of the slider track
            )
            .gesture(DragGesture(minimumDistance: 0)
               .onChanged({ value in
                   let translation = value.translation.width
                   currentTime = min(max(0, currentTime + translation / UIScreen.main.bounds.width * (playerManager.player?.duration ?? 0)), playerManager.player?.duration ?? 0)
                   playerManager.player?.currentTime = currentTime
               })
               .onEnded({ _ in
                   playerManager.player?.currentTime = currentTime
               })
           )
       }
    }
}

struct CustomSlider_Previews: PreviewProvider {
    static var previews: some View {
        let playerManager = PlayerManager()
        return CustomSlider(currentTime: .constant(0), playerManager: playerManager)
    }
}

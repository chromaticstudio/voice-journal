//
//  SoundwaveLogo.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/14/24.
//

import SwiftUI

struct SoundwaveLogo: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.blue)
                
                // Soundwave lines
                Group {
                    SoundwaveLine(offset: 0, amplitude: 0.3, phase: 0)
                        .stroke(Color.white, lineWidth: 5)

                    SoundwaveLine(offset: 30, amplitude: 0.5, phase: 0.3)
                        .stroke(Color.white, lineWidth: 5)

                    SoundwaveLine(offset: 60, amplitude: 0.7, phase: 0.6)
                        .stroke(Color.white, lineWidth: 5)

                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct SoundwaveLine: Shape {
    var offset: CGFloat
    var amplitude: CGFloat
    var phase: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let step = 5
        let centerY = rect.midY
        let height = rect.height * amplitude
        
        path.move(to: CGPoint(x: 0, y: centerY))
        
        for angle in stride(from: 0, through: 360, by: step) {
            let x = rect.width / 360 * CGFloat(angle)
            let y = centerY + sin((CGFloat(angle) + offset) * .pi / 180 + phase) * height
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

struct SoundwaveLogo_Previews: PreviewProvider {
    static var previews: some View {
        SoundwaveLogo()
            .frame(width: 100, height: 100)
    }
}

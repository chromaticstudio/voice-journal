//
//  Playback.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 6/11/24.
//

import SwiftUI
import AVFoundation

class PlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var currentTime: TimeInterval = 0
    @Published var isPlaying = false
    @Published var playbackSpeed: Float = 1.0
    var player: AVAudioPlayer?

    // Setup Player
    func setupPlayer(with url: URL) {
        if let player = try? AVAudioPlayer(contentsOf: url) {
            self.player = player
            player.delegate = self
            player.prepareToPlay()
        }
    }

    // Play function
    func play() {
        self.player?.enableRate = true
        player?.rate = playbackSpeed
        player?.play()
        isPlaying = true
        startUpdatingCurrentTime()
    }

    // Stop playing
    func stop() {
        player?.stop()
        isPlaying = false
        stopUpdatingCurrentTime()
    }

    // Update current time
    func startUpdatingCurrentTime() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if self.isPlaying {
                self.currentTime = self.player?.currentTime ?? 0
            } else {
                timer.invalidate()
            }
        }
    }

    func stopUpdatingCurrentTime() {
        // Additional logic to stop the timer can be added if needed
    }

    // Reset when playback concludes
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        player.currentTime = 0
    }
}

struct Playback: View {
    @StateObject private var playerManager = PlayerManager()
    @State private var isPopoverPresented = false
    let audioURL: URL
    let journal: Journal
    
    private var formattedTime: String {
        return FormatterUtils.shared.formattedTime(from: playerManager.currentTime)
    }
    
    private var formattedDuration: String {
        return FormatterUtils.shared.formatDuration(journal.duration)
    }
    
    var body: some View {
        VStack {
            VStack {
                CustomSlider(currentTime: $playerManager.currentTime, playerManager: playerManager)
                
                HStack {
                    Text(formattedTime)
                    Spacer()
                    Text(formattedDuration)
                }
                .font(.subheadline)
            }
            
            ZStack {
                BookmarkButton(journal: journal)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: {
                    if playerManager.isPlaying {
                        playerManager.stop()
                    } else {
                        playerManager.play()
                    }
                }) {
                    Image(systemName: playerManager.isPlaying ? "pause" : "play.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color.primary)
                        .frame(width: 20.0, height: 20.0)
                }
                .frame(width: 70.0, height: 70.0)
                .background(
                    Circle()
                        .fill(Color("SoftContrastColor"))
                )
                
                Menu {
                    Button("2x") {
                        playerManager.playbackSpeed = 2.0
                    }
                    Button("1.8x") {
                        playerManager.playbackSpeed = 1.8
                    }
                    Button("1.5x") {
                        playerManager.playbackSpeed = 1.5
                    }
                    Button("1.3x") {
                        playerManager.playbackSpeed = 1.3
                    }
                    Button("1x") {
                        playerManager.playbackSpeed = 1.0
                    }
                } label: {
                        VStack {
                            Text("\(String(format: "%.1f", playerManager.playbackSpeed))x")
                                .foregroundColor(Color.primary)
                        }
                        .font(.subheadline)
                        .padding(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
                .onChange(of: playerManager.playbackSpeed) { newSpeed, oldSpeed in
                    playerManager.player?.rate = newSpeed
                    if playerManager.isPlaying {
                        playerManager.play()
                    }
                }
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onAppear {
            playerManager.setupPlayer(with: audioURL)
        }
        .onDisappear {
            playerManager.stop()
        }
    }
}

struct Playback_Previews: PreviewProvider {
    static var previews: some View {
        let audioURL = Bundle.main.url(forResource: "sample", withExtension: "m4a") ?? URL(fileURLWithPath: "")
        
        // Create a dummy Journal object for preview
        let dummyJournal = Journal(context: CoreDataModel().persistentContainer.viewContext)
        dummyJournal.name = "Sample Journal"
        dummyJournal.journalDescription = "This is a sample journal entry."
        dummyJournal.duration = 180
        dummyJournal.audioFileName = "sample.m4a"
        
        return AnyView(
            Playback(audioURL: audioURL, journal: dummyJournal)
                .environment(\.managedObjectContext, CoreDataModel().persistentContainer.viewContext)
                .previewLayout(.sizeThatFits)
        )
    }
}

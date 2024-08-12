//
//  RecordView.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/8/24.
//

import SwiftUI
import CoreData

struct RecordView: View {
    @ObservedObject var recordingModel: RecordingModel
    @Environment(\.presentationMode) var presentationMode
    @State private var recordingFailed = false
    @State private var animate = false

    private func dismiss() {
       presentationMode.wrappedValue.dismiss()
    }
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            animate = true
        }
    }
    
    private func stopAnimation() {
        withAnimation {
            animate = false
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text(recordingModel.isRecording ? "Recording" : "Preparing to record")
                    .font(.title)
                    .fontWeight(.medium)
            }
            .padding(30)
            Spacer()
            
            ZStack {
                // Circle for Ripple Effect
                Circle()
                    .fill(Color("AccentColor").opacity(0.2))
                    .frame(width: 150, height: 150)
                    .scaleEffect(animate ? 1.75 : 1)
                    .opacity(animate ? 0 : 1)

                Button(action: {
                    recordingModel.stopRecording()
                    dismiss()
                }) {
                    Image(systemName: recordingModel.isRecording ? "stop.fill" : "mic.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color("AccentColor"))
                        .frame(width: 50, height: 50)
                        .colorInvert()
                }
                .frame(width: 150, height: 150)
                .background(Color.primary)
                    .colorInvert()
                .clipShape(Circle())
                .overlay(
                    Circle()
                      .stroke(Color("AccentColor"), lineWidth: 2)
                )
                .alert(isPresented: $recordingFailed) {
                    Alert(title: Text("Recording Failed"), message: Text("Please enable microphone access in Settings."), dismissButton: .default(Text("OK")))
                }
            }
            .padding(100)
            .onAppear {
                recordingModel.configureAudioSession()
            }
            .onChange(of: recordingModel.isRecording) {
                if recordingModel.isRecording {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }
        }
        .onDisappear {
            stopAnimation()
        }
    }
}

struct RecordView_Previews: PreviewProvider {
    static var previews: some View {
        let coreDataModel = CoreDataModel()
        return RecordView(recordingModel: RecordingModel(viewContext: coreDataModel.viewContext))
    }
}

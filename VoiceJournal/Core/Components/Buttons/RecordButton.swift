    //
    //  RecordButton.swift
    //  VoiceJournal
    //
    //  Created by Anthony Mistretta on 6/10/24.
    //

    import SwiftUI
    import CoreData

    struct RecordButton: View {
        @ObservedObject var recordingModel: RecordingModel
        @Environment(\.managedObjectContext) private var viewContext
        @State private var showingSheet = false
        @State private var recordingFailed = false
        let buttonSize: CGFloat
        
        init(buttonSize: CGFloat, viewContext: NSManagedObjectContext) {
            self.buttonSize = buttonSize
            _recordingModel = ObservedObject(wrappedValue: RecordingModel(viewContext: viewContext))
        }
    
        var body: some View {
            Button(action: {
                showingSheet = true
            }) {
                Image(systemName: "mic.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color.white)
                    .frame(width: buttonSize/3, height: buttonSize/3)
            }
            .frame(width: buttonSize, height: buttonSize)
            .background(Color("AccentColor"))
            .clipShape(Circle())
            .overlay(
                Circle()
                  .stroke(Color("AccentColor"), lineWidth: 2)
            )
            .padding()
            .alert(isPresented: $recordingFailed) {
                Alert(title: Text("Recording Failed"), message: Text("Please enable microphone access in Settings."), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showingSheet) {
                RecordView(recordingModel: recordingModel)
                    .onDisappear {
                        if recordingModel.isRecording {
                            recordingModel.stopRecording()
                        }
                    }
            }
        }
    }

    struct RecordButton_Previews: PreviewProvider {
        static var previews: some View {
            let coreDataModel = CoreDataModel()
            return RecordButton(buttonSize: 120, viewContext: coreDataModel.viewContext)
        }
    }

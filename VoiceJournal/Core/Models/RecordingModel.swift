//
//  RecordingModel.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/8/24.
//

import SwiftUI
import AVFoundation
import CoreData
import Speech
import NaturalLanguage

class RecordingModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var recordingFailed = false
    @Published var transcriptionText: String = ""
    
    private var viewContext: NSManagedObjectContext
    private var audioEngine: AVAudioEngine
    private var audioRecorder: AVAudioRecorder?
    private var audioInputNode: AVAudioInputNode
    private var audioFileURL: URL?
    
    private var recognitionTask: SFSpeechRecognitionTask?  // Keep a reference to prevent deallocation
    private var bufferSize: AVAudioFrameCount = 4096
    private var format: AVAudioFormat
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        self.audioEngine = AVAudioEngine()
        self.audioInputNode = audioEngine.inputNode
        self.format = audioInputNode.inputFormat(forBus: 0)
        super.init()
    }
    
    // MARK: - Permissions
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission() { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func requestSpeechRecognitionAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Configuration
    
    func configureAudioSession() {
        requestMicrophonePermission { [weak self] micGranted in
            guard let self = self else { return }
            if micGranted {
                self.requestSpeechRecognitionAuthorization { speechGranted in
                    if speechGranted {
                        self.startRecordingSession()
                    } else {
                        print("Speech recognition permission denied. Transcription unavailable.")
                        self.recordingFailed = true
                    }
                }
            } else {
                print("Microphone permission denied. Recording unavailable.")
                self.recordingFailed = true
            }
        }
    }
    
    // MARK: - Start / Stop Recording
    
    private func startRecordingSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
            self.audioFileURL = self.getUniqueAudioFileURL()
            
            guard let audioFileURL = self.audioFileURL else {
                print("Error: Failed to create audio file URL.")
                self.recordingFailed = true
                return
            }
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            self.audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            self.audioRecorder?.delegate = self
            self.audioRecorder?.prepareToRecord()
            self.audioRecorder?.record()
            
            self.audioEngine.prepare()
            try self.audioEngine.start()
            
            self.isRecording = true
            print("Audio recording started.")
        } catch {
            self.recordingFailed = true
            print("Failed to set up audio recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        isRecording = false
        self.audioRecorder?.stop()
        self.audioRecorder = nil
        print("Audio recording stopped.")
    }
    
    // MARK: - Process Audio
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag, let audioFileURL = self.audioFileURL {
            print("Audio recorder stopped successfully")
            // Save recording data without transcription (if needed)
            saveRecordingData(audioURL: audioFileURL)
            
            // Start transcription in background
            DispatchQueue.global(qos: .background).async {
                self.transcribeAudio(url: audioFileURL) { transcription in
                    DispatchQueue.main.async {
                        if let transcription = transcription {
                            self.transcriptionText = transcription
                            self.updateJournal(audioFileURL: audioFileURL, transcription: transcription)
                        }
                    }
                }
            }
        } else {
            print("Recording failed")
        }
    }
    
    private func transcribeAudio(url: URL, completion: @escaping (String?) -> Void) {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            print("Speech recognizer is not available for the specified locale.")
            completion(nil)
            return
        }
        
        if !recognizer.isAvailable {
            print("Speech recognizer is not available at the moment.")
            completion(nil)
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        self.recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                print("Transcription error: \(error.localizedDescription)")
                self.recognitionTask = nil
                completion(nil)
            } else if let result = result {
                print("Intermediate transcription result: \(result.bestTranscription.formattedString)")
                if result.isFinal {
                    print("Final transcription: \(result.bestTranscription.formattedString)")
                    self.recognitionTask = nil
                    completion(result.bestTranscription.formattedString)
                }
            }
        }
    }
    
    // MARK: - Save and Update Journal
    
    func saveRecordingData(audioURL: URL, transcription: String? = nil) {
        let newJournal = Journal(context: viewContext)
        newJournal.audioFileName = audioURL.lastPathComponent
        newJournal.date = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d/MM/yy"
        newJournal.name = "New Journal: \(dateFormatter.string(from: newJournal.date!))"
        
        newJournal.audioTranscription = transcription
        
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            newJournal.duration = audioPlayer.duration
        } catch {
            print("Failed to retrieve audio duration: \(error.localizedDescription)")
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save new journal: \(error.localizedDescription)")
        }
    }
    
    private func updateJournal(audioFileURL: URL, transcription: String) {
        let fetchRequest: NSFetchRequest<Journal> = Journal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "audioFileName == %@", audioFileURL.lastPathComponent)
        do {
            let journals = try viewContext.fetch(fetchRequest)
            if let journal = journals.first {
                journal.audioTranscription = transcription
                try viewContext.save()
                print("Journal updated with transcription.")
            } else {
                print("No journal found for audio file name \(audioFileURL.lastPathComponent)")
            }
        } catch {
            print("Failed to update journal: \(error.localizedDescription)")
        }
    }
    
    // MARK: - AV Audio Recorder Error
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Audio recording error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper for Unique File URL
    
    private func getUniqueAudioFileURL() -> URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found.")
            return nil
        }
        
        let audioFilename = "recording_\(Date().timeIntervalSince1970).m4a"
        let audioURL = documentsPath.appendingPathComponent(audioFilename)
        print("File URL: \(audioURL)")
        return audioURL
    }
}
